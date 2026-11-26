#!/usr/bin/env bash
# Build the local image and (re)start SearXNG on Podman (macOS: podman machine).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

command -v podman >/dev/null || { echo "podman not found" >&2; exit 1; }
podman info >/dev/null 2>&1 || { echo "podman not reachable: run 'podman machine start'" >&2; exit 1; }
command -v podman-compose >/dev/null || { echo "podman-compose not found: brew install podman-compose" >&2; exit 1; }

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

podman build --format=docker -f container/Dockerfile -t localhost/searxng/searxng:local \
  --build-arg VERSION="$TAG" --build-arg VCS_URL="$URL" \
  --build-arg VCS_REVISION="$(git rev-parse HEAD)" .

cd "$HERE"
podman-compose up -d
echo "SearXNG: http://localhost:${SEARXNG_PORT:-8080}"
