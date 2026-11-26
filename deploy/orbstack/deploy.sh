#!/usr/bin/env bash
# Build the local image and (re)start SearXNG on OrbStack.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
export PATH="/Applications/OrbStack.app/Contents/MacOS/xbin:$PATH"

command -v docker >/dev/null || { echo "docker not found; install OrbStack" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "OrbStack is not running: run 'orb start'" >&2; exit 1; }

# The Dockerfile uses BuildKit; expose OrbStack's bundled plugins to the CLI.
mkdir -p ~/.docker/cli-plugins
X=/Applications/OrbStack.app/Contents/MacOS/xbin
for p in docker-buildx docker-compose; do
  [ -e ~/.docker/cli-plugins/$p ] || ln -s "$X/$p" ~/.docker/cli-plugins/$p
done

cd "$ROOT"
SHA="$(git rev-parse --short=9 HEAD)"
TAG="$(date -u +%Y.%-m.%-d)-$SHA"
URL="$(git remote get-url origin 2>/dev/null || echo unknown)"

# searx/version_frozen.py is required by the Dockerfile (git-ignored).
cat > searx/version_frozen.py <<PY
# SPDX-License-Identifier: AGPL-3.0-or-later
# pylint: disable=missing-module-docstring
VERSION_STRING = "$TAG"
VERSION_TAG = "$TAG"
DOCKER_TAG = "$TAG"
GIT_URL = "$URL"
GIT_BRANCH = "$(git rev-parse --abbrev-ref HEAD)"
PY

docker buildx build --load -f container/Dockerfile -t searxng/searxng:local \
  --build-arg VERSION="$TAG" --build-arg VCS_URL="$URL" \
  --build-arg VCS_REVISION="$(git rev-parse HEAD)" .

cd "$HERE"
docker compose up -d
echo "SearXNG: http://localhost:${SEARXNG_PORT:-8080}"
