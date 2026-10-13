# Agent guidance

This is a local teaching demo for Playful Programming, not production software.
The improved presentation in `docs/slides.md` is its main narrative.

## Preserve the teaching failures

`stacks/05-shared-ownership/01-broken/` is intentionally broken. Its hardcoded
cross-state VPC IDs must keep producing `InvalidVpcID.NotFound`. Do not repair
them. `make order` must show a plan-time missing-network error when the shared
network is absent; it refuses to run if that network already exists.

The fixed exercise is `stacks/05-shared-ownership/02-fixed/`. Its network layer
owns both VPCs and is applied before the pipeline and portal stacks.

## Keep every AWS safety layer

- Preserve provider endpoints pointing at localhost and inline test credentials.
- Preserve the Makefile's AWS profile/session-token scrubbing and test keys.
- Preserve preflight dependencies and the global Terraform endpoint override.
- Use `scripts/awslocal`, never an AWS CLI command without an explicit endpoint.
- Add any new service to the provider endpoint blocks.

## Intentional emulator accommodations

`make prepare` downloads images and starts Floci for attendees. Keep it free of
Terraform apply and Kamal deployments; the shared-ownership failure needs its
network absent. `make up` stays a quick Floci-only start.

- Static-site provider stays on `~> 6.0`; 5.100.0 panics on Floci CloudFront.
- Keep both Lambda function-URL permissions, even though Floci accepts one.
- Keep the DynamoDB policy scoped to its table, despite Floci's enforcement bug.
- Keep the Rails JSON compatibility pin and local plain-HTTP production settings.
- Run Kamal with `make rails`; the SSH wrapper and temporary ssh-agent are required.
- Kamal targets `stacks/03-rails/host/`, while Terraform also describes an EC2 host.
- The extra Rails network must match the explicitly named root Compose project.
- Keep the exact TanStack Lambda-origin allowlist in `docker-compose.yml`.
- Keep the full-stack app free of client-side server-function calls; Floci's
  CloudFront does not forward them correctly.
- Preserve documented Floci drift workarounds and the commented peering reference.

## Slides and validation

`docs/slides.md` is the only slide source. Edit it and run `make pptx` to rebuild
both committed exports. Never edit generated HTML/PowerPoint directly. Resolve
all export errors and check overflow warnings. Diagrams use the existing native
SVG shape subset documented in the source header.

Use `terraform fmt` for Terraform. Preserve teaching comments. Add statements to
`docs/FINDINGS.md` only after measurement, with a date. For a static check, use
`make doctor`, shell syntax checks, Compose config validation, slide builds, and
Terraform validation after initialization. Do not destroy or modify another
checkout's running demo merely to verify this one.

## Repository scope and provenance

Keep only the main deck, runnable stacks, support scripts, and operational docs.
Do not add talk-idea projects, archived decks, copied Terraform state, credentials,
SSH keys, or installed dependencies. This extract has fresh Git history.
Production-source comments retain client/project names; keep the repository
private until that provenance has been cleared for publication.

Commit messages and PR descriptions have no agent attribution or generated-by
trailers. End at the last line of actual content.
