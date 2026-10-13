#!/usr/bin/env bash
# Builds stacks/04-tanstack/app into .output/ (server/ and public/), which Terraform
# then zips and uploads.
#
#   scripts/build-tanstack.sh [auto|host|docker]
#
#   auto    (default) Node on this machine if it has node and npm, otherwise a
#           container. So Docker alone is enough to run stack 4.
#   host    npm on this machine.
#   docker  a throwaway node container; nothing is installed on your machine.
#
# Run through `make tanstack` or `make tanstack-build`; `TS_BUILD=docker` picks a mode.
# A failed build fails this script (the old Makefile line ended in `|| true`).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/stacks/04-tanstack/app"
IMAGE="${TS_IMAGE:-node:24-slim}"   # a major tag: it floats to the latest 24.x
NAME=sacjs-tanstack-build
MODE="${1:-auto}"

[ -d "$APP" ] || { echo "no such directory: $APP" >&2; exit 1; }

if [ "$MODE" = auto ]; then
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then MODE=host; else MODE=docker; fi
fi
echo "═══ stacks/04-tanstack — build ($MODE) ═══"

# Show only the lines worth reading; pipefail still fails the script if the build did.
filter() { grep -E 'preset|index\.mjs|rror' || true; }

case "$MODE" in
  host)
    cd "$APP"
    [ -d node_modules ] || npm ci --silent
    npm run build 2>&1 | filter
    ;;
  docker)
    command -v docker >/dev/null 2>&1 || { echo "docker is not installed or not on PATH" >&2; exit 1; }
    docker image inspect "$IMAGE" >/dev/null 2>&1 || docker pull -q "$IMAGE" >/dev/null
    trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true' EXIT
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    docker run -d --name "$NAME" -w /app "$IMAGE" sleep 900 >/dev/null
    # Files go in and out with docker cp, not a bind mount: colima shares only your home
    # folder with its VM, so a mount from anywhere else arrives empty.
    # macOS tar would also pack extended attributes (com.apple.provenance), which the
    # daemon cannot restore ("lsetxattr ... operation not supported"). Leave them out.
    COPYFILE_DISABLE=1 tar --no-xattrs -C "$APP" --exclude=node_modules --exclude=.output -cf - . 2>/dev/null \
      | docker cp - "$NAME":/app
    docker exec "$NAME" sh -c 'npm ci --silent && npm run build' 2>&1 | filter
    # Replace the old output only now that the build succeeded, so no stale
    # fingerprinted asset gets uploaded next to the new ones.
    rm -rf "$APP/.output"
    docker cp "$NAME":/app/.output "$APP/.output"
    ;;
  *)
    echo "usage: $0 [auto|host|docker]" >&2; exit 2
    ;;
esac

[ -f "$APP/.output/server/index.mjs" ] || { echo "build finished but .output/server/index.mjs is missing" >&2; exit 1; }
echo "built: $(find "$APP/.output/public" -type f | wc -l | tr -d ' ') asset file(s) + .output/server/index.mjs"
