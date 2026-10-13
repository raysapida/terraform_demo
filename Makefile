SHELL := /bin/bash
.DEFAULT_GOAL := help

FLOCI_NET := playful-programming-terraform-demo_default
PG_IMAGE  := postgres:15.17-alpine
TF        := terraform

# Runtime/base images used by the four app demos. Floci itself comes from Compose.
# Pulling these warms Docker's image cache; it does not install host tools or
# Terraform/npm/gem dependencies, and BuildKit maintains a separate build cache.
PREPARE_IMAGES := public.ecr.aws/lambda/nodejs:22 $(PG_IMAGE) node:24-slim \
                  ruby:4.0.5-slim docker:29-cli registry:3 \
                  basecamp/kamal-proxy:v0.9.2 moby/buildkit:buildx-stable-1 \
                  public.ecr.aws/docker/library/ubuntu:24.04 docker/dockerfile:1

# Layer 3: scrub any inherited AWS identity for every recipe in this file, so a
# shell with `export AWS_PROFILE=fit` can't leak into a terraform run.
unexport AWS_PROFILE
unexport AWS_DEFAULT_PROFILE
unexport AWS_SESSION_TOKEN
unexport AWS_SECURITY_TOKEN
export AWS_ACCESS_KEY_ID     := test
export AWS_SECRET_ACCESS_KEY := test
export AWS_DEFAULT_REGION    := us-east-1
# Layer 4: the AWS provider honours AWS_ENDPOINT_URL for EVERY service at once
# (provider >= 5.31), including ones Floci does not implement — so a resource for
# an unsupported service gets a local "unknown operation" instead of a baffling
# AuthFailure from Amazon. Belt to the endpoints block's braces.
export AWS_ENDPOINT_URL      := http://localhost:4566
export TF_VAR_db_password ?= demo_password_not_a_real_secret

.PHONY: help doctor prepare up down rails-full stop-rails start-rails destroy-dir clean-site clean-rails clean-lambda clean-tanstack tools-image rails-docker rails-teardown warm verify preflight slides pptx site rails rails-psql lambda tanstack tanstack-build broken fixed order psql clean nuke

STACKS := stacks/01-static-site/terraform stacks/02-lambda/terraform stacks/03-rails/terraform stacks/04-tanstack/terraform

help:
	@echo "Playful Programming deployment demo"
	@echo
	@echo "  make doctor    Check this machine has what the stacks need (read-only)"
	@echo "  make prepare   Download demo images + start Floci (attendees: run this first)"
	@echo "  make up        Start Floci only (quick subsequent start)"
	@echo "  make preflight Prove nothing here can reach real AWS"
	@echo "  make verify  Probe what this Floci build actually supports"
	@echo "  make warm    Pre-pull images and prepare all four app demos"
	@echo
	@echo "  make slides  Rebuild docs/slides.html from docs/slides.md"
	@echo "  make pptx    Rebuild docs/slides.html AND docs/slides.pptx from docs/slides.md"
	@echo "  make site    Stack 1 — private S3 bucket + CloudFront. Deploys site/."
	@echo "  make lambda  Stack 2 — Lambda + DynamoDB + function URL. POSTs and GETs a message."
	@echo "  make rails   Stack 3 — VPC + RDS Postgres + S3. Deploys the Rails app with Kamal."
	@echo "  make stop-rails | start-rails  Stop stack 3's containers without destroying it, and bring them back in seconds"
	@echo "  make rails-docker  Stack 3 with no Ruby on this machine: runs make rails in a tools container (opt-in, tested on colima only)"
	@echo "  make rails-psql  Connect to stack 3's Postgres"
	@echo "  make tanstack-build  Stack 4's build only: Node if you have it, else a container (TS_BUILD=host|docker)"
	@echo "  make tanstack Stack 4 — TanStack Start: SSR in Lambda, assets in S3, CloudFront in front."
	@echo
	@echo "  make broken  Act III part 1 — hardcoded cross-state IDs. Fails."
	@echo "  make order   Apply a consumer before its network: expected plan-time failure"
	@echo "  make fixed   Act III part 2 — network layer + data sources. Works."
	@echo "  make psql    Connect to the Terraform-provisioned Postgres"
	@echo
	@echo "  make clean-site | clean-lambda | clean-rails | clean-tanstack   Tear down one stack"
	@echo "  make clean   Destroy all Terraform state"
	@echo "  make nuke    clean + stop Floci + delete its data"

doctor:
	@./scripts/doctor.sh

# Attendee setup: start this at the opening slide and leave it running while
# the deployment story plays. No Terraform apply or Kamal deployment happens.
prepare:
	@echo "═══ Download Floci and start the local emulator ═══"
	docker compose pull
	@$(MAKE) --no-print-directory up
	@set -e; for image in $(PREPARE_IMAGES); do \
		echo "═══ Download $$image ═══"; \
		docker pull "$$image"; \
	done
	@echo "Images downloaded. Leave Floci running and follow the stack demos."
	@echo "Terraform providers, app dependencies, and builds can still download files on first use."

up:
	docker compose up -d
	@echo -n "waiting for floci"
	@until curl -sf http://localhost:4566/ >/dev/null 2>&1; do echo -n "."; sleep 1; done
	@echo " ready."

down:
	docker compose down

# Prepare the four app demos before presenting. Do not pre-apply the ownership
# network: make order deliberately needs that network to be absent.
warm: up preflight
	docker pull $(PG_IMAGE)
	docker pull public.ecr.aws/lambda/nodejs:22
	docker pull node:24-slim
	@$(MAKE) --no-print-directory site lambda rails tanstack
	@echo "Warm. The four app demos are ready; the ownership exercise is untouched."

verify: up
	@./scripts/verify-floci.sh

preflight:
	@ORIG_AWS_PROFILE="$(shell echo $$AWS_PROFILE)" \
	 ORIG_AWS_ACCESS_KEY_ID="$(shell echo $$AWS_ACCESS_KEY_ID)" \
	 ./scripts/preflight.sh

# ── Slides ────────────────────────────────────────────────────────────────────
# docs/slides.md is the source you edit. docs/slides.html and docs/slides.pptx are
# generated from it: never edit them by hand, because the next build overwrites them.
slides:
	@python3 scripts/build-slides.py

# The PowerPoint needs Node. The first run installs the pinned pptxgenjs into
# scripts/pptx/node_modules, which needs the network once.
pptx: slides
	@[ -d scripts/pptx/node_modules ] || (cd scripts/pptx && npm ci --silent)
	@python3 scripts/pptx/extract_ir.py scripts/pptx/.build/ir.json
	@cd scripts/pptx && node build.js .build/ir.json ../../docs/slides.pptx

# ── Stack 1: static site ──────────────────────────────────────────────────────
# Two axes in two commands: `terraform apply` provisions the bucket and the CDN,
# `aws s3 sync` deploys the files, reading the bucket name from terraform output.
#
# Curl checks the AWS-style hostname using --resolve. For the browser, Floci
# also serves <id>.cloudfront.localhost:4566 without an /etc/hosts entry.
SITE := stacks/01-static-site
site: up preflight
	@echo "═══ $(SITE) — provision ═══"
	@cd $(SITE)/terraform && $(TF) init -no-color >/dev/null && $(TF) apply -auto-approve -no-color | tail -5
	@echo
	@echo "═══ $(SITE) — deploy ═══"
	@./scripts/awslocal s3 sync $(SITE)/site "s3://$$(cd $(SITE)/terraform && $(TF) output -raw bucket_name)" --delete --no-progress
	@echo
	@DISTRIBUTION_ID=$$(cd $(SITE)/terraform && $(TF) output -raw distribution_id); \
	 HOST=$$DISTRIBUTION_ID.cloudfront.net; \
	 echo "═══ GET http://$$HOST:4566/ ═══"; \
	 curl -s --resolve "$$HOST:4566:127.0.0.1" -o /dev/null -w "HTTP %{http_code}, %{size_download} bytes\n" "http://$$HOST:4566/"; \
	 echo; \
	 echo "curl --resolve $$HOST:4566:127.0.0.1 http://$$HOST:4566/"; \
	 echo; \
	 echo "Open in your browser: http://$$DISTRIBUTION_ID.cloudfront.localhost:4566/"; \
	 echo "No /etc/hosts changes needed."

# ── Stack 3: Rails + Postgres + S3, deployed by Kamal ─────────────────────────
# Provision (~2 min cold, RDS is most of it), start the stand-in host that
# Kamal SSHes into, then deploy. `kamal setup` the first time (boots kamal-proxy
# and the local registry), `kamal deploy` after that. Every setting comes from
# terraform output via config/deploy.yml and .kamal/secrets.
RAILS := stacks/03-rails
KAMAL := cd $(RAILS)/app && env -u DOCKER_BUILDKIT PATH="$(CURDIR)/$(RAILS)/host/bin:$$PATH" bundle exec kamal
# If the stack's containers were only stopped (make stop-rails), `make rails` starts
# them again in a few seconds instead of re-running Terraform and `kamal setup`
# (about 25 s). It starts the OLD code, so after changing the app run
# `make rails REDEPLOY=1`. With the containers running, it redeploys as before.
rails: up preflight
	@NEWEST=$$(docker ps -a --filter name=^sacjs-rails-web --format '{{.Names}}' | head -1); \
	 if [ -z "$(REDEPLOY)" ] && [ -n "$$NEWEST" ] && [ "$$(docker inspect -f '{{.State.Running}}' $$NEWEST)" = false ]; then \
		$(MAKE) --no-print-directory start-rails; \
	 else \
		$(MAKE) --no-print-directory rails-full; \
	 fi

rails-full:
	@# The deploy key first: Terraform's aws_key_pair reads its public half.
	@mkdir -p $(RAILS)/host/state/hostkeys
	@[ -f $(RAILS)/host/state/id_ed25519 ] || ssh-keygen -q -t ed25519 -N "" -C sacjs-kamal-demo -f $(RAILS)/host/state/id_ed25519
	@echo "═══ $(RAILS) — provision ═══"
	@cd $(RAILS)/terraform && $(TF) init -no-color >/dev/null && $(TF) apply -auto-approve -no-color | grep -E '^(Apply complete|[a-z0-9_]+ = )'
	@echo
	@echo "═══ $(RAILS) — host (stand-in for EC2) ═══"
	@[ -f $(RAILS)/host/state/secret_key_base ] || openssl rand -hex 64 > $(RAILS)/host/state/secret_key_base
	@sed "s|@STATE@|$(CURDIR)/$(RAILS)/host/state|g" $(RAILS)/host/ssh_config.template > $(RAILS)/host/state/ssh_config
	@cd $(RAILS)/app && bundle check >/dev/null || bundle install --quiet
	@docker compose -f $(RAILS)/host/compose.yml up -d --build --quiet-build --quiet-pull 2>&1 | grep -E 'Started|Running|rror' || true
	@echo
	@if docker ps --format '{{.Names}}' | grep -qx kamal-proxy; then CMD=deploy; else CMD=setup; fi; \
	 echo "═══ kamal $$CMD ═══  (full log: $(RAILS)/host/state/kamal.log)"; \
	 eval "$$(ssh-agent -s)" >/dev/null; trap 'ssh-agent -k >/dev/null' EXIT; \
	 ssh-add -q $(RAILS)/host/state/id_ed25519; \
	 if ($(KAMAL) $$CMD) > $(RAILS)/host/state/kamal.log 2>&1; then \
		grep -E 'healthy|Finished all' $(RAILS)/host/state/kamal.log | tail -2; \
	 else \
		tail -25 $(RAILS)/host/state/kamal.log; exit 1; \
	 fi
	@echo
	@echo "  http://127.0.0.1:3020/"

# Stack 3 without Ruby, Bundler, Terraform or the SSH tools on this machine: the same
# `make rails`, run inside an image that has them (stacks/03-rails/tools). Needs only
# Docker. Three settings make the unchanged recipe work from inside a container:
#   - the Docker socket, so it drives this machine's daemon (Kamal's containers are
#     siblings of Floci's, as they are without the container);
#   - the repo mounted at the SAME path, because the daemon resolves volume paths on
#     the host, and the recipe passes it absolute ones;
#   - host networking, so 127.0.0.1:4566 (Floci) and 127.0.0.1:2222 (the stand-in
#     host) mean the same thing inside as outside. On Docker Desktop this may not
#     hold (untested). Override the socket path with DOCKER_SOCK=...
# Two more settings keep it from fighting the host route in the same checkout:
#   - TF_DATA_DIR gives the container its own Terraform plugin folder. The container
#     downloads Linux providers; without this they land in .terraform, where a macOS
#     `terraform` on the host cannot use them and `make clean` fails silently.
#   - a named volume keeps the installed gems between runs. The container is
#     throwaway, so without it a later `make clean` finds no kamal to run.
DOCKER_SOCK ?= /var/run/docker.sock
TOOLS_IMAGE := sacjs-rails-tools
TOOLS_GEMS  := sacjs-rails-gems
TOOLS_RUN    = docker run --rm --network host -v $(DOCKER_SOCK):/var/run/docker.sock \
               -v "$(CURDIR):$(CURDIR)" -w "$(CURDIR)" -v $(TOOLS_GEMS):/usr/local/bundle \
               -e HOME=/root -e TF_DATA_DIR=.terraform-docker $(TOOLS_IMAGE)

# Cached after the first build (about a minute, 1.1 GB), so this is quick afterwards.
tools-image:
	@docker build -q -t $(TOOLS_IMAGE) $(RAILS)/tools >/dev/null

rails-docker: tools-image
	@$(TOOLS_RUN) make rails

# Stop stack 3's containers without destroying anything: the app, kamal-proxy and the
# stand-in host. The database (a Floci container), Terraform state and the images stay,
# so `make rails` (or start-rails) brings it back in seconds. The shared registry and
# the builder are left alone: other Kamal projects on this daemon may use them.
STACK2_CONTAINERS = sacjs-kamal-host kamal-proxy
stop-rails:
	@for c in $$(docker ps --format '{{.Names}}' | grep '^sacjs-rails-web'; echo $(STACK2_CONTAINERS)); do \
		docker ps --format '{{.Names}}' | grep -qx $$c && { docker stop $$c >/dev/null && echo "stopped $$c"; } || true; \
	done
	@echo "stack 3 stopped. 'make rails' or 'make start-rails' brings it back."

# Start them again, host first, then the proxy, then the newest app container (Kamal
# keeps stopped containers from earlier releases; they stay stopped), and wait for /up.
start-rails:
	@if [ -z "$$(docker ps -aq --filter name=^sacjs-rails-web)" ]; then \
		echo "no stack 3 app container to start. Run 'make rails' to deploy it."; exit 1; \
	 fi
	@T=$$(date +%s); \
	 for c in $(STACK2_CONTAINERS); do docker start $$c >/dev/null 2>&1 || { echo "could not start $$c; run 'make rails REDEPLOY=1'"; exit 1; }; done; \
	 docker start $$(docker ps -a --filter name=^sacjs-rails-web --format '{{.Names}}' | head -1) >/dev/null; \
	 for i in $$(seq 1 60); do \
		[ "$$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 http://127.0.0.1:3020/up)" = 200 ] && { echo "stack 3 is back after $$(( $$(date +%s) - T )) s: http://127.0.0.1:3020/"; exit 0; }; \
		sleep 0.5; \
	 done; echo "started, but /up did not answer in 30 s; run 'make rails REDEPLOY=1'"; exit 1

# Proves the rows are in the Terraform-provisioned database, not in the app.
rails-psql:
	@cd $(RAILS)/terraform && \
	docker run --rm -it --network $(FLOCI_NET) -e PGPASSWORD="$$($(TF) output -raw db_password)" \
		$(PG_IMAGE) psql -h "$$($(TF) output -raw db_host)" -p "$$($(TF) output -raw db_port)" \
		-U "$$($(TF) output -raw db_user)" -d "$$($(TF) output -raw db_name)"

# ── Stack 2: Lambda + DynamoDB ────────────────────────────────────────────────
# No deploy step of its own: the archive provider zips function/ and apply
# uploads it. Then one POST and one GET against the function URL.
# The first invoke on a machine pulls public.ecr.aws/lambda/nodejs:22 (618MB).
LAMBDA := stacks/02-lambda
lambda: up preflight
	@echo "═══ $(LAMBDA) — provision + deploy ═══"
	@cd $(LAMBDA)/terraform && $(TF) init -no-color >/dev/null && $(TF) apply -auto-approve -no-color | grep -E '^(Apply complete|[a-z0-9_]+ = )'
	@echo
	@# Each request is printed as the curl command you can copy and run yourself.
	@URL=$$(cd $(LAMBDA)/terraform && $(TF) output -raw function_url); \
	 MSG="hello from make lambda at $$(date +%T)"; \
	 echo "═══ POST ═══"; \
	 echo "\$$ curl -X POST -H 'content-type: application/json' -d '{\"message\": \"$$MSG\"}' $$URL"; \
	 curl -s -X POST -H 'content-type: application/json' -d "{\"message\": \"$$MSG\"}" "$$URL"; \
	 echo; echo; \
	 echo "═══ GET ═══"; \
	 echo "\$$ curl $$URL"; \
	 curl -s "$$URL"; echo; echo; \
	 echo "\$$ ./scripts/awslocal logs tail /aws/lambda/sacjs-lambda --since 5m --format short   # the function's logs"

# ── Stack 4: TanStack Start, serverless ───────────────────────────────────────
# Build first: Terraform zips app/.output/server and uploads app/.output/public,
# so both must exist at plan time. The build runs on this machine if it has Node,
# and in a node:24-slim container if not, so Docker alone is enough. Force one with
# `make tanstack TS_BUILD=host` or `TS_BUILD=docker`. Either way it needs the network
# (npm ci, and the image pull), so do it before going offline.
TANSTACK := stacks/04-tanstack
TS_BUILD ?= auto
tanstack-build:
	@./scripts/build-tanstack.sh $(TS_BUILD)

tanstack: up preflight
	@./scripts/build-tanstack.sh $(TS_BUILD)
	@echo
	@echo "═══ $(TANSTACK) — provision + deploy ═══"
	@cd $(TANSTACK)/terraform && $(TF) init -no-color >/dev/null && $(TF) apply -auto-approve -no-color | grep -E '^(Apply complete|[a-z0-9_]+ = )'
	@echo
	@cd $(TANSTACK)/terraform && HOST=$$($(TF) output -raw function_url_host); \
	 if ! grep -q "$$HOST" ../../../docker-compose.yml; then \
	   echo "⚠️  $$HOST is not in docker-compose.yml's CloudFront origin allowlist."; \
	   echo "    CloudFront will return 502 for pages. Update it and run 'docker compose up -d'."; \
	 fi; \
	 CF=$$($(TF) output -raw distribution_id).cloudfront.net; \
	 echo "═══ GET http://$$CF:4566/ ═══"; \
	 curl -s --resolve "$$CF:4566:127.0.0.1" -o /dev/null -w "page:  HTTP %{http_code}, %{size_download} bytes (Lambda)\n" "http://$$CF:4566/"; \
	 CSS=$$(cd ../app/.output/public && ls assets/*.css | head -1); \
	 curl -s --resolve "$$CF:4566:127.0.0.1" -o /dev/null -w "asset: HTTP %{http_code}, %{content_type} (S3)\n" "http://$$CF:4566/$$CSS"; \
	 echo; echo "curl --resolve $$CF:4566:127.0.0.1 http://$$CF:4566/"; \
	 echo; \
	 echo "Open in your browser: http://$$(echo $$CF | tr A-Z a-z | sed 's/\.net$$/.localhost/'):4566/"; \
	 echo "(site_url above is the real-AWS address; it does not resolve on the laptop.)"

# ── Act III, part 1 ───────────────────────────────────────────────────────────
# Two stacks that each hardcode an ID owned by the other's state file.
# Expected outcome: InvalidVpcID.NotFound, AFTER partially creating resources.
broken: up preflight
	@echo "═══ stacks/05-shared-ownership/01-broken/portal — apply ═══"
	@cd stacks/05-shared-ownership/01-broken/portal && $(TF) init -no-color >/dev/null && \
		($(TF) apply -auto-approve -no-color 2>&1 | tail -12) || true
	@echo
	@echo "☝️  Failed at APPLY time — after creating the VPC and subnets."
	@echo "    Terraform left this stack half-built. That's the bug."

# ── Act III, part 2 ───────────────────────────────────────────────────────────
fixed: up preflight
	@echo "═══ stacks/05-shared-ownership/02-fixed/network — the layer that owns what both stacks need ═══"
	@cd stacks/05-shared-ownership/02-fixed/network && $(TF) init -no-color >/dev/null && $(TF) apply -auto-approve -no-color | tail -6
	@echo
	@echo "═══ stacks/05-shared-ownership/02-fixed/pipeline — looks things up by tag ═══"
	@cd stacks/05-shared-ownership/02-fixed/pipeline && $(TF) init -no-color >/dev/null && $(TF) apply -auto-approve -no-color | tail -6
	@echo
	@echo "═══ stacks/05-shared-ownership/02-fixed/portal ═══"
	@cd stacks/05-shared-ownership/02-fixed/portal && $(TF) init -no-color >/dev/null && $(TF) apply -auto-approve -no-color | tail -6

# Show the out-of-order failure: a clean PLAN-time error that creates nothing.
# The contrast with `make broken` is the whole point.
# Only meaningful when the network layer does NOT exist yet — that's the whole
# point. Refuse to run otherwise rather than print a misleading success.
order: preflight
	@if [ -f stacks/05-shared-ownership/02-fixed/network/terraform.tfstate ] && \
	    grep -q '"type": "aws_vpc"' stacks/05-shared-ownership/02-fixed/network/terraform.tfstate 2>/dev/null; then \
		echo "The network layer is already applied, so the lookup will succeed"; \
		echo "and this demo shows nothing. Run 'make clean' first."; \
		exit 1; \
	fi
	@cd stacks/05-shared-ownership/02-fixed/pipeline && $(TF) init -no-color >/dev/null && \
		($(TF) plan -no-color 2>&1 | tail -8) || true
	@echo
	@echo "☝️  Failed at PLAN time. Nothing was created. It names what's missing."

# Connect via a container on Floci's network — reliable regardless of whether the
# host port range is published (see README).
psql:
	@PORT=$$(cd stacks/05-shared-ownership/02-fixed/pipeline && $(TF) output -raw rds_port); \
	HOST=$$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' playful-programming-floci); \
	echo "connecting to $$HOST:$$PORT"; \
	docker run --rm -it --network $(FLOCI_NET) -e PGPASSWORD="$$TF_VAR_db_password" \
		$(PG_IMAGE) psql -h $$HOST -p $$PORT -U pipeline_user -d pipeline_database

# Stack 3's Kamal teardown. Kamal is Ruby, so `clean` runs this on the host if it has
# Bundler and in the tools container if not (see rails-docker).
rails-teardown:
	@cd $(RAILS)/app && { bundle check >/dev/null 2>&1 || bundle install --quiet; }
	@# Stack 3's Kamal deployment: app + kamal-proxy (via kamal remove), the
	@# demo-named remote builder, then the stand-in host. The local registry
	@# container keeps Kamal's fixed name `kamal-docker-registry`, which other
	@# projects on this Docker daemon may share, so it is left in place.
	@# A stopped stack (make stop-rails) has a stopped host, which Kamal cannot reach:
	@# start it first and wait for SSH, or `kamal remove` fails silently and leaves
	@# the app and proxy containers behind.
	@if docker ps -a --format '{{.Names}}' | grep -qx sacjs-kamal-host; then \
		docker start sacjs-kamal-host >/dev/null 2>&1; \
		for i in $$(seq 1 20); do (exec 3<>/dev/tcp/127.0.0.1/2222) 2>/dev/null && break; sleep 0.5; done; \
		eval "$$(ssh-agent -s)" >/dev/null; trap 'ssh-agent -k >/dev/null' EXIT; \
		ssh-add -q $(RAILS)/host/state/id_ed25519 2>/dev/null; \
		($(KAMAL) remove -y >/dev/null 2>&1) || true; \
		docker buildx rm kamal-remote-ssh---root-127-0-0-1-2222-local-registry >/dev/null 2>&1 || true; \
		docker context rm kamal-remote-ssh---root-127-0-0-1-2222-local-registry-context >/dev/null 2>&1 || true; \
		docker rm -f buildx_buildkit_kamal-remote-ssh---root-127-0-0-1-2222-local-registry0 >/dev/null 2>&1 || true; \
		docker compose -f $(RAILS)/host/compose.yml down >/dev/null 2>&1 || true; \
	fi

# Destroy one Terraform directory (D=...) and forget its state. If the destroy fails the
# state is KEPT and a warning printed: deleting it would orphan whatever is left in
# Floci, and only `make nuke` could recover that. A directory provisioned in the tools
# container (.terraform-docker, no .terraform) is destroyed there, since each side's
# plugins only work on that side.
destroy-dir:
	@if [ -f $(D)/terraform.tfstate ]; then \
		echo "destroying $(D)"; \
		if [ ! -d $(D)/.terraform ] && [ -d $(D)/.terraform-docker ] && docker image inspect $(TOOLS_IMAGE) >/dev/null 2>&1; then \
			$(TOOLS_RUN) sh -c "cd $(D) && terraform destroy -auto-approve -no-color" >$(D)/.destroy.log 2>&1; \
		else \
			(cd $(D) && $(TF) destroy -auto-approve -no-color) >$(D)/.destroy.log 2>&1; \
		fi; \
		if [ $$? -ne 0 ]; then \
			echo "  ⚠️  destroy failed; state kept. Last lines of $(D)/.destroy.log:"; tail -5 $(D)/.destroy.log | sed 's/^/      /'; exit 1; \
		fi; \
		rm -f $(D)/.destroy.log; \
	fi
	@rm -rf $(D)/.terraform $(D)/.terraform-docker $(D)/terraform.tfstate* $(D)/.terraform.lock.hcl

# Per-stack teardown, for moving on to the next stack. Each stack has its own state and
# resource names, so the others keep running.
clean-site:
	@$(MAKE) --no-print-directory destroy-dir D=stacks/01-static-site/terraform
	@echo "stack 1 cleaned."

clean-lambda:
	@$(MAKE) --no-print-directory destroy-dir D=stacks/02-lambda/terraform
	@echo "stack 2 cleaned."

clean-tanstack:
	@$(MAKE) --no-print-directory destroy-dir D=stacks/04-tanstack/terraform
	@echo "stack 4 cleaned."

# Stack 3 was provisioned either on the host (.terraform) or in the container
# (.terraform-docker); Kamal is torn down the same way. With no Bundler on the host,
# the container is the only way. Kamal's containers are not in Terraform, so a bare
# `terraform destroy` would leave them running.
clean-rails:
	@if { [ -d $(RAILS)/terraform/.terraform-docker ] && [ ! -d $(RAILS)/terraform/.terraform ]; } || ! command -v bundle >/dev/null 2>&1; then \
		if docker image inspect $(TOOLS_IMAGE) >/dev/null 2>&1; then $(TOOLS_RUN) make rails-teardown; fi; \
	 else $(MAKE) --no-print-directory rails-teardown; fi
	@$(MAKE) --no-print-directory destroy-dir D=$(RAILS)/terraform
	@echo "stack 3 cleaned."

clean: clean-rails
	@fail=0; for d in stacks/01-static-site/terraform stacks/02-lambda/terraform stacks/04-tanstack/terraform stacks/05-shared-ownership/01-broken/portal stacks/05-shared-ownership/01-broken/pipeline stacks/05-shared-ownership/02-fixed/portal stacks/05-shared-ownership/02-fixed/pipeline stacks/05-shared-ownership/02-fixed/network; do \
		$(MAKE) --no-print-directory destroy-dir D=$$d || fail=1; \
	done; \
	if [ $$fail -ne 0 ]; then echo "clean finished with failures above."; exit 1; fi
	@echo "clean."

nuke: clean
	docker compose down -v
	rm -rf .floci-data
	@docker volume rm $(TOOLS_GEMS) >/dev/null 2>&1 || true
	@echo "nuked. next 'make up' starts from an empty account."
