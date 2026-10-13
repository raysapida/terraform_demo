#!/usr/bin/env bash
# Reports whether this machine is ready to run the demo stacks. Read-only: it starts
# nothing, pulls nothing and changes nothing.
#
#   ✓ ready   ! works but check it   ✗ missing or too old   · optional / info
#
# Exits 1 if anything a stack needs is missing (✗), 0 otherwise (! is advisory).
# Run it with `make doctor`.
set -uo pipefail
cd "$(dirname "$0")/.."

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; DIM=$'\033[2m'; OFF=$'\033[0m'
bad=0; warn=0
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$OFF" "$1"; }
no()   { printf '  %s✗%s %s\n' "$RED" "$OFF" "$1"; bad=$((bad+1)); }
meh()  { printf '  %s!%s %s\n' "$YELLOW" "$OFF" "$1"; warn=$((warn+1)); }
info() { printf '  %s·%s %s\n' "$DIM" "$OFF" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
# version_ge A B: is A >= B?
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }
ver() { grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1; }

echo "Doctor — is this machine ready for the demo?"
echo
echo "Needed for every stack"

# Docker, running
if ! have docker; then
  no "docker not found. Install Docker (or colima plus the docker CLI)"
elif ! docker info >/dev/null 2>&1; then
  no "docker is installed but not reachable. Start Docker Desktop or colima"
else
  v=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
  ok "docker running (server $v)"
  if docker compose version >/dev/null 2>&1; then
    ok "docker compose v2 ($(docker compose version --short 2>/dev/null))"
  else
    no "docker compose v2 missing. 'docker compose version' must work (see the README)"
  fi
  mem=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
  info "docker has $((mem / 1024 / 1024 / 1024)) GB of memory to give containers (RDS, Lambda and builds run inside it)"
  if [ "$(uname)" = Darwin ] && have colima; then
    info "colima shares only your home folder with its VM, so keep the repo under it"
  fi
fi

# Terraform
if have terraform; then
  tv=$(terraform version 2>/dev/null | head -1 | ver)
  if version_ge "${tv:-0}" 1.5; then ok "terraform $tv"; else no "terraform $tv is older than 1.5"; fi
else
  no "terraform not found (1.5 or later)"
fi

have make && ok "make" || no "make not found"
have curl && ok "curl" || no "curl not found"

# Disk and architecture
free_kb=$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
if [ -n "${free_kb:-}" ]; then
  gb=$((free_kb / 1024 / 1024))
  if [ "$gb" -ge 10 ]; then ok "$gb GB free on the disk holding your home folder"
  else meh "only $gb GB free; the images alone are about 2 GB and builds need more room (rough guess)"; fi
fi
arch=$(uname -m)
info "this machine is $arch"

echo
echo "Stack 1: static site (make site)"
if have aws; then ok "aws cli $(aws --version 2>&1 | ver) (used only through scripts/awslocal)"
else no "aws cli not found. 'make site' runs aws s3 sync"; fi

echo
echo "Stack 2: Lambda (make lambda)"
info "nothing beyond the core list"

echo
echo "Stack 3: Rails with Kamal (make rails)"
want=$(cat stacks/03-rails/app/.ruby-version 2>/dev/null | sed 's/^ruby-//')
if have ruby; then
  rv=$(ruby -e 'print RUBY_VERSION' 2>/dev/null)
  if [ "$rv" = "$want" ]; then ok "ruby $rv"
  else meh "ruby $rv, but the app pins $want. rbenv/asdf users: run it from stacks/03-rails/app. It may still work"; fi
else
  no "ruby not found (needs $want). Optional: skip stack 3 and just watch"
fi
if have bundle; then ok "bundler $(bundle -v 2>/dev/null | ver)"; else no "bundler not found"; fi
if docker buildx version >/dev/null 2>&1; then ok "docker buildx $(docker buildx version 2>/dev/null | ver)"
else no "docker buildx missing; Kamal builds with it"; fi
for t in ssh ssh-agent ssh-keygen openssl; do have "$t" || no "$t not found"; done
if grep -q '^  arch: arm64' stacks/03-rails/app/config/deploy.yml 2>/dev/null; then
  case "$arch" in
    arm64|aarch64) ok "builder arch arm64 matches this machine" ;;
    *) meh "deploy.yml sets builder arch: arm64 but this machine is $arch. Change it to amd64 (untested)" ;;
  esac
fi

echo
echo "Stack 4: TanStack Start (make tanstack)"
if have node && have npm; then ok "node $(node -v) will build it; docker is the fallback"
else ok "no node here, so the build runs in a node:24-slim container"; fi

echo
echo "Ports that must be free (4566 may be Floci already)"
busy() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }
for p in 3020 3443 2222 5555 2200 30000 30001 7001 7002 7003 7004 7005 7006 7007 7008 7009 7010; do
  busy "$p" && { who=$(lsof -nP -iTCP:"$p" -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1}'); meh "port $p is in use${who:+ by $who}"; }
done
if busy 4566; then
  if curl -sf --max-time 3 http://localhost:4566/ >/dev/null 2>&1; then ok "4566 answers (Floci is probably already running)"
  else meh "port 4566 is in use. Floci needs it"; fi
else ok "4566 is free"
fi

echo
echo "Images already on this machine (the rest are pulled on first use)"
if ! docker info >/dev/null 2>&1; then info "skipped: docker is not reachable"; else
for img in floci/floci:latest public.ecr.aws/lambda/nodejs:22 postgres:15.17-alpine node:24-slim; do
  if docker image inspect "$img" >/dev/null 2>&1; then
    printf '  %s✓%s %s %s(cached)%s\n' "$GREEN" "$OFF" "$img" "$DIM" "$OFF"
  else
    info "$img (will be pulled)"
  fi
done
fi

echo
if [ "$bad" -gt 0 ]; then
  printf '%s%d thing(s) missing%s, %d to check. Fix the ✗ lines for the stacks you want to run.\n' "$RED" "$bad" "$OFF" "$warn"
  exit 1
fi
printf '%sReady.%s %d thing(s) to check.\n' "$GREEN" "$OFF" "$warn"
