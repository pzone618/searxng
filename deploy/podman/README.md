# Deploy SearXNG on Podman (macOS)

Builds the image from this checkout (`container/Dockerfile`) and runs it with
Valkey via `podman-compose`. See also <https://docs.searxng.org/admin/installation-docker.html>.

Requirements: `brew install podman podman-compose`, then `podman machine init && podman machine start`
(2 GiB VM memory is the default; raise it with `podman machine set --memory 4096` if the build runs out of memory).

```sh
./deploy/podman/deploy.sh      # build + start, http://localhost:8080
```

## Configuration

On first start the container writes `deploy/podman/core-config/settings.yml`
(random `secret_key`; git-ignored, never commit it). To allow the JSON API keep `html`
in the list, since `formats` replaces the default `[html]` instead of merging:

```yaml
use_default_settings: true
search:
  formats:
    - html
    - json
```

Then `podman restart searxng-core`.

## Troubleshooting

- **Image pulls or builds hang**: `podman machine start` copies the host's
  `HTTP(S)_PROXY` into the VM. If the proxy is slow, restart the machine without it:
  `env -u HTTP_PROXY -u HTTPS_PROXY podman machine stop && env -u HTTP_PROXY -u HTTPS_PROXY podman machine start`.
- **Offline / slow registry**: load a prebuilt image instead, e.g.
  `docker save searxng/searxng:local | podman load`, then
  `podman tag docker.io/searxng/searxng:local localhost/searxng/searxng:local` and `podman-compose up -d` in this directory.
- **Engine `CAPTCHA`** (e.g. duckduckgo): upstream rate limiting; other engines still answer.
- Smoke test: `curl 'localhost:8080/search?q=test&format=json'`.
