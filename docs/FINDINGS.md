# What Floci actually does

Probed against **Floci 2.0.1** on 2026-09-09, macOS (Apple Silicon), Docker 29.7.2,
Terraform 1.5.7. Re-run `make verify` before the talk — this is a young project and
these results will move.

**Re-probed 2026-09-12** on a clean machine (Docker 29.5.2 via colima, Terraform
1.5.7, AWS provider 5.100.0): `make verify` → **9 passed, 2 failed**, identical
results. Peering still `UnsupportedOperation`. Setup steps and the traps found
while installing from scratch are in [FLOCI-SETUP.md](FLOCI-SETUP.md).

## Verified working ✅

| Capability | Notes |
|---|---|
| `aws_vpc`, `aws_subnet`, `aws_security_group`, `aws_route_table` | Instant (<1s) |
| Tag filtering — `describe-vpcs --filters Name=tag:Name,Values=…` | **Works.** This is what the `02-fixed` data-source approach depends on. |
| `aws_db_instance` | **Real Postgres.** Spawns `postgres:15.17-alpine`, honors `engine_version`. ~90s to create. |
| RDS connectivity | `psql` confirmed: `PostgreSQL 15.17 on aarch64-unknown-linux-musl` |
| Terraform AWS provider | Works with the `endpoints` block + `skip_*` flags (see `provider.tf`) |
| IAM, S3, ECR | Enabled per the service registry |

### App-stack probes (2026-09-12)

Probed for the stacks-first restructure (the four app stacks in this repository) against the
same Floci 2.0.1 container, via `./scripts/awslocal`. **CLI-level only — none of
this has been through Terraform yet.** Each stack still needs its own apply.

| Capability | Result |
|---|---|
| DynamoDB `CreateTable` (on-demand), `PutItem` / `GetItem` | ✅ Instant |
| Lambda `nodejs22.x` create + invoke | ✅ Pulls `public.ecr.aws/lambda/nodejs:22` (**618MB**) on first invoke — pre-pull before going offline |
| Lambda → DynamoDB with **no endpoint config in the handler** | ✅ Floci injects `AWS_ENDPOINT_URL=http://localhost.floci.io:4566` into the function, and the AWS SDK v3 bundled in the runtime honours it |
| Lambda function URL (`auth-type NONE`) | ✅ `http://<id>.lambda-url.us-east-1.localhost:4566/` serves the handler from the host |
| API Gateway v2 HTTP API quick-create (`--target`) | ❌ Creates the API but no `$default` stage; no invoke URL routes to it. Use a function URL instead |
| S3 presigned `PUT` (SigV4, path-style) | ✅ 200, object readable afterwards |
| S3 → Lambda `ObjectCreated` notification | ✅ Fires (the handler's side effect appeared); CloudWatch Logs showed no events for it |
| S3 static website hosting | ✅ `http://<bucket>.s3-website-us-east-1.localhost:4566/` serves `index.html` |
| CloudFront distribution with S3 origin | ✅ Created as `Deployed` instantly, and **serves content**: `Host: <id>.cloudfront.net` against `localhost:4566` proxies to the origin (an unknown ID does not). Delete requires disabling first, as in real AWS |
| CloudFront origin access control | ✅ Created; enforcement untested |

**Through Terraform — stack 1 (`stacks/01-static-site`), 2026-09-12:**

| Finding | Detail |
|---|---|
| **AWS provider 5.100.0 panics** on `aws_cloudfront_distribution` | Floci omits `DefaultCacheBehavior.TrustedSigners` from the response; 5.x dereferences it unguarded (`distribution.go:1673`). Each crashed apply **orphans a distribution** in Floci. Provider **6.64.0** has the nil check and works — that stack pins `~> 6.0`. All 99 endpoint keys still validate on 6.x |
| Permanent plan drift on the distribution | `tags_all` (Floci doesn't store distribution tags) and `default_cache_behavior.cached_methods` (returned empty). An apply does not clear it. Suppressed with a commented `ignore_changes` |
| `AllowedMethods` returned duplicated | Sent `GET, HEAD`; `GetDistributionConfig` returns `Quantity: 4, [GET, HEAD, GET, HEAD]`. No visible effect in Terraform |
| Timings | Apply ~31s for the distribution (provider polls for `Deployed`), destroy ~60s (provider disables, waits, deletes). `make site` from scratch: 51s |
| **S3 policy enforcement is off by default** | With stock settings, the public access block and bucket policy are stored but not evaluated: anonymous `GET` on a blocked bucket → 200, CloudFront with no bucket policy → 200 |
| …and works when enabled | On a throwaway container with `FLOCI_SERVICES_S3_ENFORCE_AUTH=true` + `FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true`: anonymous → **403**, CDN without policy → **403**, CDN with the OAC `AWS:SourceArn` policy → **200**. Tested against stack 2 below: IAM enforcement has a DynamoDB resource-matching bug, so `docker-compose.yml` still runs with both off |

**Through Terraform — stack 3 (`stacks/03-rails`), 2026-09-12:**

| Finding | Detail |
|---|---|
| All 17 resources apply on provider 6.64.0 | VPC, IGW, route table + association, 3 subnets, 2 SGs (one referencing the other), DB subnet group, `random_password`, RDS, S3 bucket + public access block, IAM user, access key, user policy. Second plan: no changes. Destroy: clean |
| Timings | Apply 1m44s cold (RDS 93s of it); `make rails` from a destroyed stack including image build: 1m57s |
| RDS endpoint | `db_host` output is Floci's container IP (`172.18.0.2`), port `7001`. Reachable from any container on the Compose network |
| **Security groups and `publicly_accessible = false` are not enforced** | The DB SG admits 5432 only from the app SG. The app container belongs to no SG and connects anyway; so does `psql` from a throwaway container. Consistent with Floci's docs (SGs are metadata) |
| IAM access key | `aws_iam_access_key` returns an `AKIA…` ID and a secret; ActiveStorage uploads/downloads with it work. With enforcement off this proves only that the key is *accepted*, not that the bucket-scoped policy is *applied* |
| S3 from an app container | `endpoint: http://floci:4566` (Compose network alias) + `force_path_style: true`. Uploaded objects are visible via `awslocal s3 ls` under their ActiveStorage keys |

**Kamal deploy (stack 3), 2026-09-12**, Kamal 2.12.0, Docker 29.5.2 on colima:

| Finding | Detail |
|---|---|
| ~~EC2 can't host Kamal~~ (corrected 2026-10-12) | The earlier row came from Floci's docs ("the Docker socket is **not** available inside instances") and was never tested. Probed with Terraform: see **EC2 instances** below. Docker *can* run inside a Floci instance, with extra steps; Kamal still targets the stand-in host, because those steps are not wired up |
| Stand-in host works | `docker:29-cli` + openssh-server, Docker socket mounted, SSH on `127.0.0.1:2222`. `kamal setup` succeeds against it unmodified |
| Local registry | `registry.server: localhost:5555` → Kamal runs `registry:3` on the laptop and an SSH tunnel to the host. No `docker login` at all |
| Two networks on the app container | `servers.web.options.network` adds a second `--network` next to Kamal's hardcoded `--network kamal`; Docker 29 accepts both. The app reaches RDS at `terraform output db_host` and S3 at `floci:4566` |
| kamal-proxy ports | `proxy.run.http_port: 3020`, `https_port: 3443`, `bind_ips: [127.0.0.1]` avoid needing root for 80 and the port 443 your Caddy already uses |
| Timings | `make rails` from nothing: 3m50s with an empty build cache (`kamal setup` 115s); 2m12s when the BuildKit container's cache survived (`kamal setup` 22s). Warm `kamal deploy`: **9.8–11.2s** |
| `docker buildx rm` leaves the BuildKit container | For the SSH-context builder, `buildx rm` unregisters it but `buildx_buildkit_<name>0` keeps running (with its cache). `make clean` removes it explicitly |
| Zero downtime | `/up` polled every 0.25s during a `kamal deploy` with a view change: 47 of 47 requests returned 200 |
| `builder.remote` + a local registry ignores `ssh.config`/`ssh.keys` | Kamal's registry tunnel for a remote builder is opened with only the user and port parsed from the `remote:` URI (`cli/build.rb`, `remote_builder_ssh_options`). An SSH alias defined outside `~/.ssh/config` fails (`getaddrinfo`), and keys must come from ssh-agent or default key files. `make rails` uses `ssh://root@127.0.0.1:2222` and a throwaway ssh-agent holding the demo key. `~/.ssh/known_hosts` verified unchanged afterwards |
| `builder.remote` alone still builds locally | When `arch` matches the laptop, Kamal builds locally unless `local: false` is also set |
| Docker's remote builder uses the system `ssh` | `docker -H ssh://…` runs `ssh … docker system dial-stdio` from `PATH`, reading only `~/.ssh/config`. `stacks/03-rails/host/bin/ssh` wraps it with `-F` and the demo config; `make rails` puts it first on `PATH` |
| Builder names | Local builder is always `kamal-local-registry-<driver>` (shared by every local-registry Kamal project); the registry container is always `kamal-docker-registry`; the network always `kamal`. Only a remote builder's name varies, from its URI: here `kamal-remote-ssh---root-127-0-0-1-2222-local-registry` |

**EC2 instances, 2026-10-12** (Floci on colima, provider 6.68.0, stack 3's
`aws_instance.app`):

| Finding | Detail |
|---|---|
| `aws_instance` applies | `t4g.small` from `data.aws_ami` (Canonical, `ubuntu-noble-24.04-arm64-server-*` resolves to `ami-ubuntu2404-arm64`), with `aws_key_pair`, public subnet and SG. Running in about 10 s. `public_ip` is the VPC address (`10.20.1.10`), not a public one |
| Backed by a real container | `public.ecr.aws/docker/library/ubuntu:24.04`, on the VPC's network and Floci's Compose network. SSH is published on host port 2200; the SG's 80 and 443 are forwarded to 30000 and 30001. **All three bind 0.0.0.0**, so they are reachable from the local network (SSH is key-only) |
| Key pair works | The demo key logs in as **root** on port 2200. `ubuntu` and `ec2-user` are refused |
| `user_data` runs | `curl -fsSL https://get.docker.com \| sh` installed docker-ce 29.9 at first boot |
| Docker inside: works with `vfs` | No systemd, so `dockerd` does not start on its own. Started by hand it initializes, but the default overlayfs storage fails (`failed to mount … overlay … invalid argument`). With `dockerd --storage-driver=vfs`, `docker run alpine` and a published nginx (HTTP 200) work. The container has full capabilities |
| Kamal against the instance (spike, 2026-10-12) | See **Kamal into the EC2 instance** below. Kamal deploys and Rails passes its health check inside the instance, but requests from the laptop never reach it. Kamal still targets the stand-in host |

**Kamal into the EC2 instance, 2026-10-12** (timeboxed spike; scratch Kamal config
passed with `-c`, nothing in the repo changed):

| Step | Result |
|---|---|
| Docker in the instance | `dockerd --storage-driver=vfs` started over SSH. No systemd, so `user_data` alone does not start it |
| Kamal over SSH | `ssh.port: 2200`, root, the demo key. Works. A separate ssh_config with no `Port` line was needed, because the stand-in's config pins 127.0.0.1 to 2222 |
| Build and registry | Built on the stand-in builder, pushed to `localhost:5555`, pulled into the instance through Kamal's SSH tunnel. Works |
| `kamal-proxy` on :80 | **Blocked by Floci.** Its metadata-service emulation holds `169.254.169.254:80` inside the instance, so binding `0.0.0.0:80` fails (`address already in use`). `proxy.run.bind_ips: [<instance VPC address>]` works around it; that address changes with every instance |
| App reaches RDS and S3 | `db_host` is an IP (Floci's, `172.18.0.2:7001`), so the database needs no DNS. The S3 endpoint's `floci` name needs `options: add-host: floci:<ip>` |
| Health check | Failed at first: the first attempt's `kamal-proxy` was created without a network attachment (after the port clash) and later runs reused it, so it could not resolve the app container. After `docker rm -f kamal-proxy`, "First web container is healthy" in 38 s |
| Inside the instance | `curl http://<instance VPC address>/up` returns **200** through kamal-proxy to Rails |
| From the laptop | **Fails.** Floci forwards host :30000 with socat to `<instance VPC address>:80`, but its forwarder container cannot reach the port Docker publishes inside the instance, with either the nft or the legacy iptables backend. Not resolved |
| Cost | First `kamal setup` 11.5 min; `vfs` keeps full copies of every layer, 3.7 GB inside the instance. Too slow to run live |

Next attempt, if any: how Floci's forwarder reaches published ports inside an
instance (Docker's userland proxy, or the instance's FORWARD and NAT rules). Even if
it works, the setup time rules it out for a live demo.



Not Floci, but cost time: `rails new` on Rails 8.1.3.1 resolved `json` 3.0.2,
whose keyword-only `JSON.parse` raises `ArgumentError` inside ActiveSupport's
session-cookie decryption, so every request carrying a session returns 500.
Pinned `json ~> 2.21` in `stacks/03-rails/app/Gemfile`.

**Through Terraform — stack 2 (`stacks/02-lambda`), 2026-09-12:**

| Finding | Detail |
|---|---|
| All 9 resources apply on provider 6.64.0 + archive 2.8.1 | DynamoDB table, CloudWatch log group, IAM role + 2 inline policies, `nodejs22.x` function from an `archive_file` zip, function URL, and both `aws_lambda_permission` statements (`function_url_auth_type = NONE`, `invoked_via_function_url = true`). Second plan: no changes |
| Timings | Apply 21s; `make lambda` from a destroyed stack including first invoke: 31s (runtime image already cached) |
| Redeploy on code change | Editing `function/index.mjs` changes `source_code_hash`; plan shows the function updated in place |
| Function URL | Output is `http://<id>.lambda-url.us-east-1.localhost:4566/`; `*.localhost` resolves without `/etc/hosts`. The ID is derived from the function name, so it is stable across destroy/apply. The URL always says port **4566**, even when Floci is published on another host port |
| Unhandled handler errors | Function URL returns **HTTP 200** with the error JSON and stack trace as the body. Real AWS returns 502. The handler catches errors and returns 500 so both behave the same |
| **IAM enforcement: DynamoDB resource matching is broken** | On a throwaway Floci with `FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true`, the function's role allowing `dynamodb:PutItem`/`Scan` on `arn:aws:dynamodb:us-east-1:000000000000:table/sacjs-lambda-messages` is **denied**. Floci's log: `IAM enforcement DENY: … action=dynamodb:PutItem resource=arn:aws:dynamodb:us-east-1:000000000000:table/*`. It evaluates every call against `table/*` rather than the table named in the request, so only policies with `Resource` = `table/*` or `*` pass. Worth reporting upstream |
| …action matching does work | With `Resource = table/*` and only `dynamodb:PutItem`: POST → 201, GET → `AccessDeniedException … dynamodb:Scan`. Missing *actions* are denied correctly; *resource scoping* can't be demonstrated |
| Lambda credentials | The function receives `ASIA…` temporary keys; enforcement attributes them to the execution role (the wildcard policy on that role took effect) |

**Through Terraform — stack 4 (`stacks/04-tanstack`), 2026-09-12:**

| Finding | Detail |
|---|---|
| All 15 resources apply | S3 bucket, public access block, 3 `aws_s3_object`s, OAC, bucket policy; IAM role, logs policy, log group, `nodejs22.x` function (512 MB) from Nitro's `.output/server`, function URL, 2 permissions; one CloudFront distribution with an S3 origin and a custom (function URL) origin |
| Timings | Apply 45s cold (distribution 30s); `make tanstack` from a destroyed stack including `vite build`: 52s |
| **CloudFront refuses loopback custom origins by default** | The function URL origin returned **502**; Floci logged `CloudFront custom origin fetch failed for host <id>.lambda-url.us-east-1.localhost: UnknownHostException`. Floci rejects origins resolving to loopback/private addresses (SSRF protection). Fixed with `FLOCI_SERVICES_CLOUDFRONT_ALLOWED_PRIVATE_ORIGIN_HOSTS=<exact host>` in `docker-compose.yml`. The `.localhost` form needs no DNS; `.localhost.floci.io` also works but depends on public DNS |
| Function URL host is stable | Same host for the same function name across destroy/apply and across separate Floci containers, which is what makes pinning it in compose workable. Not an obvious MD5 of the name |
| **POST not proxied to custom origins** | `405`. Documented: only GET/HEAD/OPTIONS are routed |
| **Query string dropped** | `GET /p?a=1&b=two` through CloudFront reaches the function as `/p` with an empty query, with either `ForwardedValues.QueryString = true` or the `AllViewer` origin request policy. Direct to the function URL it arrives intact. Undocumented |
| Path routing works | `/assets/*` ordered behaviour → S3 with OAC, default → function. Assets served with the content types set on the objects |
| More distribution drift | Custom origin `origin_keepalive_timeout`, `origin_read_timeout` and `origin_ssl_protocols` return 0/empty, so `origin` (a set) is ignored whole. A function with no `environment` block returns an empty one; setting `NODE_ENV` avoids that drift |
| Browser check | Page load through CloudFront: HTML + 3 assets, all 200, no server-function calls during hydration, no console errors |
| Floci restart with a compose change | `docker compose up -d` recreated the container; hybrid storage kept every stack's resources. The stack 3 RDS container restarted and kept its data; stacks 1–3 all passed their checks afterwards |

**Container networking trap.** `localhost.floci.io` resolves publicly to
`127.0.0.1`. Inside containers *Floci spawns* (Lambda) it resolves to Floci's
container; inside **any other container** on the Compose network — e.g. the
Rails app — it resolves to the container itself, and connections are refused.
A container that talks to Floci needs `extra_hosts: localhost.floci.io:<floci ip>`
or should use the `floci` network alias. Offline, the host browser also needs an
`/etc/hosts` entry, since the public DNS record is unavailable.

## Verified NOT working ❌

| Operation | Error |
|---|---|
| `CreateVpcPeeringConnection` | `UnsupportedOperation` |
| `AcceptVpcPeeringConnection` | `UnsupportedOperation` |
| `DescribeVpcPeeringConnections` | `UnsupportedOperation` |

**This is the single most important finding for the talk.** VPC peering — the exact
subject of Act III — is not emulated. The demo is designed around that constraint;
see [The peering problem](#the-peering-problem) below.

## Services Floci does not implement

Probed 2026-09-12 against 2.0.1, 36 services tested directly. An unimplemented
service returns `UnknownOperationException` — which is the *safe* failure mode:
obviously local, obviously not your account.

| Category | Not implemented |
|---|---|
| Databases / analytics | `timestream-write`, `timestream-query`, `keyspaces`, `dax`, `emr-containers`, `kinesisvideo` |
| Storage / transfer | `fsx`, `storagegateway`, `datasync`, `glacier` |
| Networking | `globalaccelerator`, `directconnect`, `appmesh` |
| Security posture | `shield`, `securityhub`, `macie2`, `accessanalyzer` |
| Dev tooling / CI | `codecommit`, `codeartifact`, `amplify`, `apprunner`, `imagebuilder`, `xray` |
| ML | `sagemaker`, `polly`, `translate` |
| Other | `outposts`, `workspaces`, `appflow`, `support` |

**No core IaC primitive is missing.** `ec2`, `vpc`, `rds`, `s3`, `iam`, `lambda`,
`ecs`, `eks`, `elb`/`elbv2`, `route53`, `cloudformation`, `autoscaling`, `acm`,
`cloudfront`, `secretsmanager`, `kms`, `efs`, `ecr` all work. The gaps cluster in
managed dev tooling, ML, specialty storage/networking, and security-posture
services — none of which this talk needs. It does have `cloudtrail`, `config`,
`organizations`, `controltower`, `ram`, `lakeformation` and `guardduty`.

**`floci services` undercounts — probe, don't read.** Three services answer
requests without appearing in the list of 100:

| Not listed | Reality |
|---|---|
| `sts` | Works — `get-caller-identity` returns account `000000000000` |
| `opensearch` | Works; listed only under the legacy name `es` |
| `sesv2` | Works; listed only as `email` |

Untested, genuinely unknown: `qldb`, `vpc-lattice`, `inspector2`, `detective`,
`redshift-data`, `mediaconvert`, `pinpoint`, `budgets`, `health`,
`route53domains`, `lex`, `personalize`, `forecast`.

### Two kinds of gap, and the dangerous one isn't Floci's

1. **Floci doesn't implement it** → `UnknownOperationException`. Harmless.
2. **Floci implements it but the provider isn't pointed at it** → the request
   goes to **real AWS** and fails with an `AuthFailure` that reads as a mystery.

Category 2 used to cover `autoscaling`, `acm`, `apigatewayv2`, `servicediscovery`,
`states`, `athena`, `glue`, `cloudtrail`, `resource-explorer-2` and `redshift` —
all supported by Floci, none pinned. Fixed 2026-09-12: every `provider.tf` now
pins **99 endpoint keys** (generated from `floci services` intersected with the
provider's 303 valid keys), and the Makefile exports `AWS_ENDPOINT_URL`, which the
provider honours for every service at once from v5.31. Verified: `terraform plan`
for an *unpinned* service (`aws_autoscaling_groups`) resolves to
`http://localhost:4566` with zero connection attempts to AWS.

## Gotchas that cost real time

**1. `AWS_ENDPOINT_URL` needs aws-cli ≥ 2.13.** Older CLIs (2.5.x ships on plenty
of machines) silently ignore it and talk to **real AWS**. The symptom is a
confusing `AuthFailure` — which is the *good* outcome, because the bad outcome is
credentials that happen to work. Always pass `--endpoint-url` explicitly, which is
what `scripts/awslocal` does.

**2. RDS endpoints are on Floci's Docker network, not localhost.** The endpoint
output is `172.20.0.2:7001` — Floci's own container IP, proxying to the spawned
Postgres. To reach it from the host you need the port published; `docker-compose.yml`
maps `7001-7010` (not 7000 — macOS AirPlay Receiver binds 7000). Note that
`floci start` from the CLI publishes **only** 4566, so the host route silently
fails if you start Floci that way instead of `make up`. To reach it from another
container, join the Compose network — which is what `make psql` does.

**3. RDS creation takes ~90 seconds.** Fine for a demo, too slow to do live at the
top of a talk. Pre-warm before you present — `make warm`.

**4. `docker compose` may not exist even with Docker installed.** `make up` needs
the Compose v2 plugin. Homebrew's `docker` formula ships without it, installs it
to a directory Docker doesn't search, and stale Docker Desktop symlinks in
`~/.docker/cli-plugins/` shadow it. Symptom: `unknown shorthand flag: 'd' in -d`.
Fix in [FLOCI-SETUP.md](FLOCI-SETUP.md) Trap 6.

**5. `make clean` breaks an offline demo.** It deletes `.terraform.lock.hcl` and
`.terraform/`, and there is no plugin cache configured, so the next
`terraform init` must reach `registry.terraform.io`. Do not clean right before
presenting in airplane mode.

**6. `floci doctor` reports a false failure on colima.** `docker.socket` checks
the host path `/var/run/docker.sock`, which colima doesn't create, and advises
opening Docker Desktop. Docker-backed services work regardless.

**7. Account ID is `000000000000`.** Convenient: it matches the redaction convention
used in the talk slides, so screenshots need no editing.

## The peering problem

Act III of the talk is about two Terraform states hardcoding IDs across a state
boundary, using VPC peering as the vehicle. Floci can't create peering connections,
so the demo can't reproduce it literally.

**This turned out not to matter, and arguably improved the demo.** The bug being
demonstrated is not "peering is misconfigured" — it's **"a config hardcodes an ID
that another state file owns."** That failure is fully reproducible without peering:

- `stacks/05-shared-ownership/01-broken/` hardcodes real-looking IDs from another account. `terraform apply`
  fails with `InvalidVpcID.NotFound`. This is *exactly* what happens when you clone
  a repo with cross-state hardcoded IDs into a fresh account — which is the actual
  bug in FitScale, stated plainly.
- `stacks/05-shared-ownership/02-fixed/` replaces the hardcoded IDs with tag-based data sources and a shared
  `network/` layer. Applying the stacks out of order produces a real, live ordering
  error; applying them in order works.

The real peering shape is kept as commented code the audience can read —
`stacks/05-shared-ownership/01-broken/portal/main.tf:10` for the hardcoded `pcx-` reference and
`stacks/05-shared-ownership/02-fixed/network/main.tf:71-77` for where the connection would live in the fixed
layout — with the emulator limitation noted on the slide. (There is no
`peering.tf.disabled` file; an earlier draft of this doc said there was.)
That limitation is itself a decent 30-second beat: **emulators have edges, and
finding them is part of the job.**

## Not yet probed

- `terraform_remote_state` against a Floci S3 backend
- ECS / ELBv2, both listed in the service registry
- **Cross-VPC isolation on this machine.** The demo's failure half assumes two
  VPCs cannot reach each other. Verified as a Floci design claim, not yet tested
  end-to-end on colima — and OrbStack/Docker Desktop are documented to differ.
- **A full offline run** with the network off, after a `make warm`.
