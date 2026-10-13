# Playful Programming Terraform demo

The standalone companion to **From Git commits to Terraform**, for
[Playful Programming Sacramento](https://www.meetup.com/the-sacramento-javascript-meetup/).
Run four application shapes against Floci, a local AWS emulator:
**no AWS account, no real credentials, and no cloud bill**.

This repository contains the improved slide deck, runnable stacks, and their
supporting tools. It starts with fresh Git history and contains no Terraform
state, emulator data, generated keys, talk-idea projects, or archived decks.

## Start here

```bash
make doctor       # read-only prerequisite check
make prepare      # download demo images + start Floci; leave running during the story
make preflight    # verify the local-only AWS configuration
make site         # static HTML/CSS/JS: S3 + CloudFront
make lambda       # Node API: Lambda + DynamoDB
make rails        # Rails upload app: Postgres + S3, deployed with Kamal
make tanstack     # TanStack Start: Lambda SSR + S3 assets + CloudFront
```

Run commands from the repository root. Each app target initializes its own
Terraform directory and prints how to reach the result. The static and TanStack
sites use `http://<distribution-id>.cloudfront.localhost:4566/` in a browser;
Rails is at `http://127.0.0.1:3020/`. Lambda prints a local function URL.
Downloads happen on first use, so prepare images and dependencies before going
offline. `make warm` runs all four app demos ahead of a presentation; it leaves
the shared-ownership exercise unapplied so `make order` can still demonstrate
its expected failure.

Run one checkout of these demos at a time. The original teaching repository and
this extract use the same host ports and some Kamal container names. Stop the
other checkout's services before running these demos.

### Prepare while the talk starts

Run `make prepare` from the opening URL/QR slide and leave that terminal running
while the deployment story plays. It pulls Floci, starts the emulator, and pulls
the demos' Lambda, Postgres, Node, and Rails runtime/base images, including the
registry, proxy, builder, and EC2 image. It does not run Terraform or deploy apps.
Pulls show progress and stop on the first failure; rerun the command after fixing
the problem. Already-downloaded image layers are reused.

`make up` remains the quick command for starting only Floci. Preparation downloads
several images and can take time depending on connection speed and existing
caches. Terraform providers, npm packages, gems, system packages, and build layers
can still download on first use; BuildKit has its own cache. This is not a complete
offline setup. Host tools still need to be installed separately; `make doctor`
reports missing prerequisites.

## Requirements

| Requirement | Used by |
|---|---|
| Docker, running, with Compose v2 | Every stack |
| Terraform 1.5 or later, `make`, and `curl` | Every stack |
| AWS CLI | Static-site deployment and `make verify` |
| Ruby 4.0.5, Bundler, Docker Buildx, SSH tools, and OpenSSL | `make rails` |
| Node and npm | Optional: TanStack builds in `node:24-slim` when absent |
| Python 3 | Rebuilding the HTML slides |
| Node and npm | Rebuilding the PowerPoint slides |

The Rails app pins Ruby 4.0.5; Ruby on the laptop runs Kamal, while the app itself
runs in a container. `make rails-docker` is an optional tools-container route
with no host Ruby requirement. Its host-networking behavior was tested on
colima; Docker Desktop and other platforms remain unverified.

The original demos were tested on macOS with Apple Silicon. Linux and Intel are
untested; use WSL2 on Windows. The Rails builder and Terraform AMI/instance
configuration target arm64. An x86 port needs matching builder and instance
architecture choices, not just a different Ruby installation.

Free ports: 4566, 7001–7010, 3020, 3443, 2222, and 5555. Floci's stack-3 EC2
stand-in also publishes 2200, 30000, and 30001 while it exists. The Compose
project name is explicitly fixed to `playful-programming-terraform-demo`, so
Kamal's additional network works even when the clone directory is renamed.

See [FLOCI-SETUP.md](docs/FLOCI-SETUP.md) for Docker/Compose and local setup
troubleshooting. Image and package downloads need internet access initially.

## Contents

```text
docs/
  slides.md             improved main presentation; edit this
  slides.html           generated browser deck
  slides.pptx           generated PowerPoint deck
  slides.template.html  shared browser style and navigation
  SLIDE_DECKS.md        timing budget and build instructions
  FINDINGS.md           measured emulator limitations
  FLOCI-SETUP.md        local setup and troubleshooting
stacks/
  01-static-site/       private S3 bucket and CloudFront
  02-lambda/            Node function API and DynamoDB
  03-rails/             Terraform, Rails app, Kamal host, optional tools image
  04-tanstack/          TanStack Start and Lambda/S3/CloudFront infrastructure
  05-shared-ownership/
    01-broken/          intentionally invalid cross-state IDs
    02-fixed/           shared network layer and tag lookups
scripts/                safety, prerequisites, builds, and Floci probes
Makefile                runnable commands
docker-compose.yml      Floci and persistent local data
```

## Shared-ownership exercise

The last part of the deck needs these additional stacks. They live under
`stacks/05-shared-ownership/` so the full talk can run from this repository.

```bash
make broken    # expected apply failure after partial resource creation
make order     # expected plan failure when the shared network is absent
make fixed     # network first, then pipeline and portal
make psql      # inspect the ownership exercise's real Postgres database
```

**The broken Terraform is deliberate. Do not fix its hardcoded IDs.**
`make broken` shows `InvalidVpcID.NotFound`; `make order` shows a missing-VPC
lookup. The recipes capture those expected Terraform failures so the teaching
messages can still print. `make order` refuses if the fixed network already
exists; prepare an empty ownership exercise before presenting that beat.

The production story used VPC peering. Floci does not support peering, so the
local failure uses a security group with another stack's hardcoded VPC ID.
The correctly ordered version gives the shared networks one owner and looks
them up by tag. This proves rebuildability and ordering, not cross-VPC routing.

## Slides

Open [docs/slides.html](docs/slides.html) in a browser, or use the committed
PowerPoint file. Arrow keys navigate; `N` toggles speaker notes. Rebuild after
editing the Markdown source:

```bash
make slides    # HTML only, Python 3
make pptx      # HTML and PowerPoint; installs pinned npm dependencies once
```

The deck has 47 slides. Budget approximately 50–60
minutes before Q&A, pending rehearsal. [SLIDE_DECKS.md](docs/SLIDE_DECKS.md)
contains a 54-minute section budget. The deployment-only deck and all dated
backups remain in the original working repository.

## How this stays off real AWS

Preserve all of these protections:

1. Every `provider.tf` pins service endpoints to `http://localhost:4566`.
2. Every AWS provider uses inline `access_key = "test"` and
   `secret_key = "test"`, which override real credential sources.
3. Make recipes scrub inherited AWS profiles and session tokens, export test
   keys, and run `scripts/preflight.sh` before the app demos.
4. The Makefile exports `AWS_ENDPOINT_URL` for the Terraform provider, including
   services missing from its explicit endpoint list.

For AWS CLI commands, use `./scripts/awslocal`, which passes `--endpoint-url`
explicitly. Older AWS CLI releases silently ignore the `AWS_ENDPOINT_URL`
environment variable. `AWS_PROFILE=anything make preflight` should report that
the inherited profile was scrubbed.

The AWS provider settings are already complete; `.env.example` contains only
optional placeholder values, and no `.env` file is required. State, database
passwords, IAM keys, generated SSH keys, and `SECRET_KEY_BASE` are local runtime
artifacts. Git ignores them; never copy them from the original repository.

## Cleanup and subsequent runs

```bash
make stop-rails      # stop the app/proxy/host while keeping state and data
make start-rails     # resume the most recent deployed Rails image
make rails REDEPLOY=1 # deploy current source instead of resuming an old image
make rails-psql      # inspect the Rails database
make clean-site     # destroy only the static-site stack
make clean-lambda   # destroy only the function API
make clean-rails    # remove Kamal's app/host, then destroy stack 3
make clean-tanstack # destroy only the full-stack demo
make clean          # destroy all app and ownership stacks
make down           # stop Floci
make nuke           # destroy stacks, stop Floci, delete emulator data
```

`make clean` keeps Terraform state if a destroy fails. It removes provider
caches after a successful destroy, so do not run it immediately before an
offline presentation. Floci data is in `.floci-data/`; do not transfer it or
Terraform state to a different machine.

## Emulator limitations and provenance

The policies and network configuration express the intended AWS architecture;
Floci does not enforce every setting. Important limits include bucket/IAM
enforcement, security groups, VPC peering, and POST/query forwarding through
CloudFront. [FINDINGS.md](docs/FINDINGS.md) preserves the original dated
measurements; it does not claim this extract has been deployed end to end.

Teaching comments retain production-source references from the original
repository. Keep this repository private until client/project naming and
publication clearance are resolved.
