# Deploy SearXNG on OrbStack

Builds the image from this checkout (`container/Dockerfile`) and runs it with
Valkey via Docker Compose. See also <https://docs.searxng.org/admin/installation-docker.html>.

```sh
./deploy/orbstack/deploy.sh      # build + start, http://localhost:8080
```

## Configuration

On first start the container writes `deploy/orbstack/core-config/settings.yml`
(with a random `secret_key`; git-ignored, never commit it). To allow the JSON API:

```yaml
use_default_settings: true
search:
  formats:
    - html   # keep html, otherwise the web UI returns 403
    - json
```

`formats` is a list and replaces the default (`[html]`) instead of merging.
Then `docker restart searxng-core`. Set `SEARXNG_CONTACT_URL` in the compose
`environment` to enable engines such as openstreetmap/wikidata.

## Troubleshooting

- **Image pulls hang**: OrbStack's `network_proxy: auto` may reuse a broken host
  proxy. Try `orbctl config set network_proxy none`, then `orbctl restart docker`.
- **Engine `CAPTCHA`** (e.g. duckduckgo): upstream rate limiting; other engines
  still answer.
- Smoke test: `curl 'localhost:8080/search?q=test&format=json'`.
