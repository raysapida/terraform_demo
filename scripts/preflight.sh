#!/usr/bin/env bash
# Refuses to run Terraform if anything could reach real AWS.
#
# This is the SECOND layer. The first is in each provider.tf:
#   - an `endpoints` block pinning every service to the emulator
#   - static access_key/secret_key = "test", which in the AWS provider outrank
#     AWS_PROFILE, environment variables, and ~/.aws/credentials
#
# Two layers because this repo gets cloned onto machines with real production
# profiles configured, and the cost of being wrong is asymmetric.
set -euo pipefail

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; OFF=$'\033[0m'
fail=0

say_fail() { printf '  %s✗%s %s\n' "$RED" "$OFF" "$1"; fail=1; }
say_ok()   { printf '  %s✓%s %s\n' "$GREEN" "$OFF" "$1"; }

echo "Preflight — confirming this cannot reach real AWS:"

# 1. No AWS profile/credential env vars pointing at a real account.
# ORIG_* are passed by the Makefile, which scrubs the real vars before we run.
# Without them we'd report "clean" for an environment we merely neutralized.
if [ -n "${ORIG_AWS_PROFILE:-}" ]; then
  printf '  %s!%s AWS_PROFILE="%s" in your shell — scrubbed by the Makefile, not used\n' \
    "$YELLOW" "$OFF" "$ORIG_AWS_PROFILE"
elif [ -n "${ORIG_AWS_ACCESS_KEY_ID:-}" ] && [ "${ORIG_AWS_ACCESS_KEY_ID}" != "test" ]; then
  printf '  %s!%s A real-looking AWS_ACCESS_KEY_ID was in your shell — scrubbed, not used\n' \
    "$YELLOW" "$OFF"
fi

for var in AWS_PROFILE AWS_DEFAULT_PROFILE AWS_SESSION_TOKEN AWS_SECURITY_TOKEN; do
  if [ -n "${!var:-}" ]; then
    say_fail "$var is set (\"${!var}\") — unset it before running the demo"
  fi
done
[ $fail -eq 0 ] && say_ok "no AWS profile env vars reaching terraform"

# 2. If access keys are exported, they must be the placeholder.
if [ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ "${AWS_ACCESS_KEY_ID}" != "test" ]; then
  say_fail "AWS_ACCESS_KEY_ID is set to something other than 'test'"
else
  say_ok "no real access key exported"
fi

# 3. Floci must be up. If it isn't, Terraform would get connection-refused on
#    localhost:4566 rather than silently falling through to AWS — but a clear
#    message beats a confusing one.
if curl -sf --max-time 3 http://localhost:4566/ >/dev/null 2>&1; then
  say_ok "floci responding on :4566"
else
  say_fail "floci is not responding on :4566 — run 'make up'"
fi

# 4. Every provider.tf must carry both safety layers. Found by search, not by a
#    fixed glob: a new stack directory must not be able to skip this check.
root="$(cd "$(dirname "$0")/.." && pwd)"
while IFS= read -r f; do
  rel="${f#"$root"/}"
  if ! grep -q 'endpoints {' "$f"; then
    say_fail "$rel has no endpoints block"
  elif ! grep -qE 'access_key\s*=\s*"test"' "$f"; then
    say_fail "$rel does not pin access_key to the placeholder"
  fi
done < <(find "$root" -name provider.tf -not -path '*/.terraform/*' | sort)
[ $fail -eq 0 ] && say_ok "all provider.tf files pin endpoints + placeholder credentials"

# 5. Warn (don't block) if real profiles exist on this machine — that's the
#    situation this guard is actually protecting.
if [ -f ~/.aws/credentials ]; then
  n=$(grep -cE '^\[' ~/.aws/credentials || true)
  printf '  %s!%s %s real AWS profile(s) exist in ~/.aws/credentials — none are used by this demo\n' \
    "$YELLOW" "$OFF" "$n"
fi

echo
if [ $fail -ne 0 ]; then
  printf '%sPreflight failed. Not running Terraform.%s\n' "$RED" "$OFF"
  exit 1
fi
printf '%sPreflight passed.%s\n' "$GREEN" "$OFF"
