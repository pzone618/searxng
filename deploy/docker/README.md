# Deploy SearXNG on Docker Desktop (macOS)

Builds the image from this checkout (`container/Dockerfile`) and runs it with
Valkey via Docker Compose. See also <https://docs.searxng.org/admin/installation-docker.html>.

Requirements: Docker Desktop running (buildx and compose are bundled).

```sh
./deploy/docker/deploy.sh      # build + start, http://localhost:8080
```

The script uses the `desktop-linux` context and Docker Desktop's own CLI/credential
helper, so it works even if `docker` in `PATH` points elsewhere (e.g. OrbStack).
Override with `DOCKER_CONTEXT=<name>`.

## Configuration

On first start the container writes `deploy/docker/core-config/settings.yml`
(random `secret_key`; git-ignored, never commit it). To allow the JSON API keep `html`
in the list, since `formats` replaces the default `[html]` instead of merging:

```yaml
use_default_settings: true
search:
  formats:
    - html
    - json
```

Then `docker restart searxng-core`.

## Troubleshooting

- **Image pulls or builds hang / very slow**: Docker Desktop may route through a slow
  proxy (Settings → Resources → Proxies). Disable it, or load a prebuilt image from
  another engine: `docker --context orbstack save searxng/searxng:local valkey/valkey:9-alpine | docker --context desktop-linux load`,
  then `docker compose up -d` in this directory.
- **`docker-credential-desktop` not found**: the `docker` in `PATH` is not Docker
  Desktop's; use `deploy.sh` or add `/Applications/Docker.app/Contents/Resources/bin` to `PATH`.
- **Engine `CAPTCHA`** (e.g. duckduckgo): upstream rate limiting; other engines still answer.
- Smoke test: `curl 'localhost:8080/search?q=test&format=json'`.
