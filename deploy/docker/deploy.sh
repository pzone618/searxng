#!/usr/bin/env bash
# Build the local image and (re)start SearXNG on Docker Desktop.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

# Use Docker Desktop explicitly (the `docker` in PATH may point to OrbStack).
export DOCKER_CONTEXT="${DOCKER_CONTEXT:-desktop-linux}"
# Prefer Docker Desktop's own CLI and credential helper.
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

command -v docker >/dev/null || { echo "docker not found" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker ($DOCKER_CONTEXT) is not running: start Docker Desktop" >&2; exit 1; }
docker buildx version >/dev/null 2>&1 || { echo "docker buildx is required (BuildKit)" >&2; exit 1; }

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
