# Floci setup — from zero to a working local AWS

A copy-pasteable setup path for following the Playful Programming deployment talk on your own
machine. Everything below was run end-to-end on a clean machine; timings and
version numbers are what actually happened, not estimates.

**Verified on:** macOS (Darwin 25.6.0), Apple Silicon, 2026-09-10.
Floci CLI 0.2.1 · Floci server 2.0.1 (`floci-always-free`) · Docker 29.5.2 via colima.

Linux and Windows paths are **not** verified here — see [Not yet verified](#not-yet-verified).

---

## 0. Prerequisites — check these first

The single most important line in this document:

```bash
aws --version    # MUST be >= 2.13
```

**If your AWS CLI is older than 2.13, the official Floci quickstart will silently
send your commands to real AWS.** Details in [Trap 1](#trap-1-an-old-aws-cli-talks-to-real-aws).
This is not hypothetical — it happened on the machine this guide was written on,
which had 2.2.33 from 2021.

| Tool | Needed | Notes |
|---|---|---|
| AWS CLI | **>= 2.13** | `AWS_ENDPOINT_URL` support landed in 2.13 |
| Docker runtime | any | colima, Docker Desktop, OrbStack, Podman |
| Terraform | >= 1.5 | only if running the demo stacks |
| Docker Compose | v2 plugin | `docker compose version` must work — see [Trap 6](#trap-6-docker-compose-is-missing-on-homebrew-docker) |

Upgrade the AWS CLI if needed:

```bash
brew install awscli        # Apple Silicon native
```

> If you previously installed the AWS CLI from Amazon's `.pkg`, it lives in
> `/usr/local/bin/aws` and the Homebrew one lands in `/opt/homebrew/bin/aws`.
> Both stay on disk. Confirm which one wins:
> ```bash
> which -a aws && aws --version
> ```

---

## 1. Install the Floci CLI

```bash
brew install floci-io/floci/floci
```

Took **24s**. Installs `floci` 0.2.1.

Homebrew now enforces *tap trust* on third-party taps, so expect a trust prompt
or banner the first time.

<details>
<summary>Alternatives (install script, Windows)</summary>

```bash
# macOS / Linux — installs to /usr/local/bin, will prompt for sudo
curl -fsSL https://floci.io/install.sh | sh

# Windows
irm https://floci.io/install.ps1 | iex
```

The install script verifies a SHA-256 checksum **only if `sha256sum` is on your
PATH**, and silently skips verification if it isn't. Recent macOS ships
`/sbin/sha256sum`, so it does run there; older macOS has only `shasum -a 256`
and would skip the check. Homebrew avoids both the sudo prompt and this
ambiguity — prefer it.

</details>

---

## 2. Start a Docker runtime

Floci is a container, and its Docker-backed services (RDS, ECS, Lambda, EC2)
spawn more containers. You need a running daemon.

```bash
colima start --cpu 4 --memory 8 --disk 60
```

Took **42s**. The defaults (2 CPU / 2GB) are too small once RDS and ECS
containers start.

Why colima for a talk: no GUI, no licence. Docker Desktop requires a paid
subscription at companies above Docker's size threshold, which matters if your
audience is following along on work laptops. Docker Desktop and OrbStack work
equally well if you already have them.

---

## 3. Start Floci

```bash
floci start
```

Took **44s** including a **556MB** first-time image pull. Subsequent starts skip
the pull.

Confirm:

```bash
floci status
floci services     # 100 services enabled
```

> **Following the talk repo instead?** Use `make up`, not `floci start`. The repo
> runs Floci from `docker-compose.yml` so the demo is reproducible: it names the
> container `playful-programming-floci`, publishes the `7001-7010` RDS range, mounts
> `./.floci-data` for persistence, and sets `FLOCI_STORAGE_MODE: hybrid`. The
> scripts depend on all four. The two methods both bind port 4566, so stop one
> before starting the other (`floci stop`).
>
> The `floci` CLI is not required to run the demo at all — install it for
> `doctor`, `env`, and `services` when exploring your own setup.

---

## 4. Configure your AWS tooling

**Recommended: an isolated, demo-only config that cannot see your real
credentials.**

This is deliberately not the official `eval $(floci env)` quickstart. See
[Trap 1](#trap-1-an-old-aws-cli-talks-to-real-aws) and
[Trap 2](#trap-2-floci-env-depends-on-public-dns) for why.

```bash
mkdir -p ~/floci-demo-aws
cat > ~/floci-demo-aws/config <<'EOF'
[default]
region = us-east-1
output = json
endpoint_url = http://localhost:4566
s3 =
  addressing_style = path
EOF
cat > ~/floci-demo-aws/credentials <<'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF
```

Then, **in each demo shell**:

```bash
export AWS_CONFIG_FILE=~/floci-demo-aws/config
export AWS_SHARED_CREDENTIALS_FILE=~/floci-demo-aws/credentials
unset AWS_PROFILE AWS_ENDPOINT_URL
```

Those two exports point the AWS SDK at a credentials file containing nothing but
fake keys. Your real `~/.aws/credentials` becomes unreadable to every AWS CLI,
SDK, and Terraform process in that shell.

**This is the point.** Floci does not intercept anything — it is just an HTTP
server on `localhost:4566`. Every tool must be individually pointed at it, and
anything misconfigured reaches real AWS using whatever credentials it can find.
That default is fail-*open*. The config above makes it fail-*closed*: a
misconfigured command gets an auth error instead of touching production.

Verify:

```bash
aws sts get-caller-identity     # answered by Floci, not AWS
aws s3 mb s3://my-bucket
aws s3 ls
```

---

## 5. Check your environment

```bash
floci doctor
```

Every failure prints a `Fix:` line. Two caveats — see
[Trap 3](#trap-3-doctor-misreports-the-docker-socket-on-colima) and
[Trap 5](#trap-5-doctor---fix-does-not-fix-this).

---

## Traps

### Trap 1: an old AWS CLI talks to real AWS

The documented quickstart is:

```bash
eval $(floci env)      # sets AWS_ENDPOINT_URL
aws s3 mb s3://my-bucket
```

`AWS_ENDPOINT_URL` was only honored from **AWS CLI 2.13**. On 2.2.33 the
variable is set and then **ignored**. Verified with `aws s3 ls --debug`:

```
url: 'https://s3.us-east-1.amazonaws.com/'
Authorization: AWS4-HMAC-SHA256 Credential=test/20260910/us-east-1/s3/aws4_request
Starting new HTTPS connection (1): s3.us-east-1.amazonaws.com:443
"GET / HTTP/1.1" 403 None
```

The request left the machine and hit production AWS. It failed only because the
credentials were fake. **Had a valid `[default]` profile been picked up instead,
it would have succeeded against a real account.**

Mitigations, in order of strength:
1. Use the isolated config in [step 4](#4-configure-your-aws-tooling) — fail-closed.
2. Upgrade to AWS CLI >= 2.13.
3. Pass `--endpoint-url http://localhost:4566` explicitly on every command.

### Trap 2: `floci env` depends on public DNS

```console
$ floci env
export AWS_ENDPOINT_URL='http://localhost.floci.io:4566'
```

`localhost.floci.io` is a **public wildcard DNS record** resolving to 127.0.0.1.
It exists so S3 virtual-hosted-style requests (`bucket.localhost.floci.io`)
resolve. It is not in `/etc/hosts`.

```console
$ dig +short my-bucket.localhost.floci.io
127.0.0.1
```

The traffic never leaves your machine, but **the name lookup does**. On a
conference network, or on a laptop in airplane mode with a cold DNS cache, this
breaks.

Use plain `localhost:4566` with `addressing_style = path` instead — as the
config in step 4 does. Path-style needs no wildcard DNS and no network at all.

### Trap 3: `doctor` misreports the Docker socket on colima

```
✗ docker.socket   /var/run/docker.sock not found or not accessible
                  Fix: Open Docker Desktop — the socket is created when Docker Desktop is running
```

**This is a false negative under colima, and the advice is wrong.** `doctor`
checks the *host* path; colima runs Docker in a VM and creates no host socket.
Inside the VM the socket exists and mounts into containers normally:

```console
$ colima ssh -- ls -l /var/run/docker.sock
srw-rw---- 1 root docker 0 /var/run/docker.sock
```

Docker-backed services work regardless. Confirmed by creating an RDS instance,
which returned `"DBInstanceStatus": "available"` in 36s.

Ignore this failure if you are on colima and Docker-backed services work.

### Trap 4: `floci start` does not publish the RDS port range

Floci reports an RDS endpoint like `172.17.0.2:7001`. Floci proxies its spawned
RDS containers on **7001 and up**, but `floci start` publishes only 4566 — so
that endpoint is unreachable from your host shell on macOS, under colima *or*
Docker Desktop (Docker runs in a VM; container IPs are not routed to the host).

```console
$ docker ps
floci   floci/floci:latest   0.0.0.0:4566->4566/tcp      ← 7001+ not published
$ nc -z -w5 localhost 7001
CLOSED
```

**Fix: run Floci from a compose file and publish the range.**

```yaml
services:
  floci:
    image: floci/floci:latest
    container_name: playful-programming-floci
    ports:
      - "4566:4566"
      - "7001-7010:7001-7010"   # Floci proxies spawned RDS containers here
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./.floci-data:/app/data
    environment:
      FLOCI_STORAGE_MODE: hybrid
```

Start at **7001, not 7000** — macOS AirPlay Receiver binds 7000.

With that published, `psql -h localhost -p 7001` works from the host.

**Or connect from inside a container**, which works either way:

```bash
docker run --rm -e PGPASSWORD=demopass123 postgres:16.3-alpine \
  psql -h 172.17.0.2 -p 7001 -U demo -d postgres -c 'select version();'
```

```
PostgreSQL 16.3 on aarch64-unknown-linux-musl ...
```

Genuine PostgreSQL. Two notes:

- **Use the port Floci reports (7001), not 5432.** The `5432/tcp` shown for the
  spawned container is a stale `EXPOSE` label from the base image; 5432 is refused.
- In real AWS an RDS instance in a private subnet is not reachable from your
  laptop either — you reach it from inside the VPC. So the container route is the
  faithful one, and it does not depend on a published port range.

This repo's `make psql` (`Makefile:100`) uses the container route deliberately,
resolving the IP with `docker inspect` and the port from Terraform output, so it
works whether or not the range is published.

### Trap 5: `doctor --fix` does not fix this

`doctor` advertises `Run with --fix to auto-resolve fixable issues`, and warns
that `~/.aws/config` is missing `s3.addressing_style = path`. Running
`floci doctor --fix` **left the file unmodified** — same mtime, no
`addressing_style` line added. Apply that setting yourself; step 4 does.

---

### Trap 6: `docker compose` is missing on Homebrew Docker

If you run Floci from a compose file (which this repo does), `docker compose`
has to work. On a Mac using colima or the Homebrew `docker` CLI it often doesn't:

```console
$ make up
docker compose up -d
unknown shorthand flag: 'd' in -d
```

or

```console
$ docker compose version
docker: unknown command: docker compose
```

Two independent causes, and you may have both:

**1. Homebrew's `docker` formula ships without Compose.** It's a separate
formula, and Homebrew installs it to `/opt/homebrew/lib/docker/cli-plugins`,
which is **not** on Docker's plugin search path (Docker looks in
`~/.docker/cli-plugins` and `/usr/local/lib/docker/cli-plugins`). So installing
it is not enough:

```bash
brew install docker-compose
ln -sf /opt/homebrew/lib/docker/cli-plugins/docker-compose \
       ~/.docker/cli-plugins/docker-compose
```

**2. Stale Docker Desktop symlinks shadow it.** If Docker Desktop was ever
installed on the machine — or the home directory was migrated from one that had
it — `~/.docker/cli-plugins/` keeps dangling symlinks into
`/Applications/Docker.app`, which take precedence over everything else. Clear the
broken ones:

```bash
for f in ~/.docker/cli-plugins/*; do [ -e "$f" ] || rm "$f"; done
```

Removing them is *not* sufficient on its own — cause 1 still applies, so do the
symlink step too. Verify:

```console
$ docker compose version
Docker Compose version 5.1.4
```

## A word on credentials

Before presenting or screen-sharing any of this:

```bash
grep -n "aws_access_key_id" ~/.aws/config ~/.aws/credentials 2>/dev/null | sed 's/=.*/= <REDACTED>/'
```

Long-lived `AKIA...` keys sitting in those files are the thing that turns a
misconfigured endpoint from a harmless 403 into a real incident. The isolated
config in step 4 keeps them out of reach of the demo, but rotating unused keys
is the real fix.

---

## Worth reporting upstream

Issues found during this setup pass, with suggested fixes. All are reproducible
on the environment named at the top of this document. Filed against
[floci-io/floci-cli](https://github.com/floci-io/floci-cli).

### 1. `doctor` should check the AWS CLI version — highest priority

**This is the only finding here that can cost someone real money.** Every other
issue is confusing; this one is silent and reaches production.

`floci env` prints `AWS_ENDPOINT_URL`, which AWS CLI versions below 2.13 ignore
entirely. The user follows the documented quickstart, sees no error, and their
commands go to their real AWS account under whatever credentials
`~/.aws/credentials` provides. Nothing in the CLI warns them.

Observed on AWS CLI 2.2.33 — `aws s3 ls --debug` after `eval $(floci env)`:

```
url: 'https://s3.us-east-1.amazonaws.com/'
Starting new HTTPS connection (1): s3.us-east-1.amazonaws.com:443
"GET / HTTP/1.1" 403 None
```

It failed only because the credentials happened to be the placeholder `test`.
With a valid `[default]` profile present — common on any work laptop — the same
command succeeds against a real account.

Suggested fixes, in order:

- Add an `aws.cli.version` check to `floci doctor` that fails below 2.13.
- Have `floci env` detect the installed CLI version and emit a loud comment, or
  refuse to print `AWS_ENDPOINT_URL`, when it is too old to honour it.
- At minimum, state the 2.13 requirement in the README quickstart.

The `doctor` check is the strongest of these, because `doctor` is what users are
told to run when something looks wrong.

### 2. `doctor`'s Docker socket check ignores `DOCKER_HOST` and Docker contexts

`docker.socket` hard-codes `/var/run/docker.sock` and fails on any VM-based or
rootless runtime that does not create that host path — colima, Podman, remote
contexts. The fix text then gives advice that cannot help:

```
✗ docker.socket   /var/run/docker.sock not found or not accessible
                  Fix: Open Docker Desktop — the socket is created when Docker Desktop is running
```

This is a false negative: Docker-backed services work fine, because the mount is
resolved inside the VM where the socket does exist. Verified by creating an RDS
instance that reached `"available"` and served real PostgreSQL 16.3.

The CLI documents a `DOCKER_HOST` → `DOCKER_SOCK` → OS-default resolution order
elsewhere; `doctor` appears not to use it. Suggested fix: resolve the socket the
same way the rest of the CLI does, and make the remediation text conditional on
the detected runtime rather than naming Docker Desktop unconditionally.

### 3. `doctor --fix` does not apply the fix it advertises

`doctor` prints `Run with --fix to auto-resolve fixable issues` and reports that
`~/.aws/config` lacks `s3.addressing_style = path`. Running `floci doctor --fix`
left the file unmodified — same mtime, no `addressing_style` line added. Either
apply the change or drop it from the list of fixable issues.

### 4. `floci env` introduces a DNS dependency that `localhost` would not

`floci env` emits `AWS_ENDPOINT_URL='http://localhost.floci.io:4566'`. The
wildcard record exists so S3 virtual-hosted-style requests resolve, which is a
reasonable default — but it makes the emulator depend on public DNS, which is
surprising for a tool whose selling point is working without a cloud account.
It breaks on offline machines, on captive-portal conference wifi, and anywhere
the domain is filtered.

Suggested fix: offer a documented flag (`floci env --path-style`, say) that emits
plain `localhost:4566` and reminds the user to set `addressing_style = path`, and
note the DNS dependency in the docs.

## Teardown

```bash
floci stop          # stop the emulator (add --rm to remove the container)
colima stop         # stop the Docker VM
```

Removing everything:

```bash
brew uninstall floci
docker rmi floci/floci:latest
rm -rf ~/floci-demo-aws
```

---

## Verified

- [x] **Terraform never touches real AWS.** `TF_LOG=DEBUG terraform plan` in
      `stacks/05-shared-ownership/01-broken/portal` (provider v5.100.0) dialed exactly one host:

      http.url=http://localhost:4566/

      Zero connection attempts to AWS. `Plan: 5 to add, 0 to change, 0 to destroy.`

      Two strings in the debug log look alarming and are not: `ec2.amazonaws.com`
      appears only as an XML namespace inside Floci's *response bodies*
      (`xmlns="http://ec2.amazonaws.com/doc/2016-11-15/"`), and
      `registry.terraform.io` only as the provider's address
      (`tf_provider_addr=`). Grep for `http.url=` to see real requests.

- [x] **Docker-backed services work under colima**, despite `doctor`'s
      `docker.socket` failure. RDS returned `"available"` in 36s and serves real
      PostgreSQL 16.3. See [Trap 3](#trap-3-doctor-misreports-the-docker-socket-on-colima).

- [x] **RDS is reachable — from a container, not the host.**
      See [Trap 4](#trap-4-you-cannot-reach-rds-from-your-host-shell-on-macos).

## Not yet verified

Honest gaps — do not present these as working:

- [ ] **`terraform apply`.** Only `plan` has been run. Plan is read-only; apply
      exercises create paths (VPC peering especially) that plan does not.
- [ ] **Services absent from the `endpoints {}` block** — `autoscaling`, `acm`,
      `apigatewayv2`, `servicediscovery`, `states`, `athena`, `glue`,
      `cloudtrail`, `resourceexplorer2`, `redshift`. These would route to real
      AWS and fail on the placeholder credentials.
- [ ] **Linux and Windows**, and Docker Desktop / OrbStack / Podman runtimes.
      Note that Trap 4 is macOS-specific — on Linux, container IPs *are* routable
      from the host, so the demo behaves differently there.
- [ ] **Fully offline operation** (airplane mode), end to end. The evidence is
      encouraging — the only host dialed during `plan` was `localhost:4566` — but
      `terraform init` must be run beforehand to cache providers, and this has
      not been tested with the network actually switched off.
