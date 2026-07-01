# Kubernetes hosting

`https://paro.paroslab.io` is hosted from the personal Kubernetes cluster, not Cloudflare Pages.

The GitOps app lives in the ops repo at:

```text
~/dev/personal/ops/apps/paro
```

## Install URL

```sh
curl -fsSL https://paro.paroslab.io/install | sh -s -- --profile lite
```

## Routes

- `/` — small landing page with the install command.
- `/install` — serves `boot.sh` directly for `curl | sh`.
- `/boot.sh` — same installer script checked into this repo and copied into the Kubernetes ConfigMap.
- `/latest/<asset>` — redirects to the current GitHub release asset.
- `/releases/latest/download/<asset>` — GitHub-compatible latest asset redirect.

The binary and tarball artifacts still live in GitHub Releases. Kubernetes hosts the stable personal-domain entrypoint and bootstrap script.

## Smoke checks

```sh
curl -fsSI https://paro.paroslab.io/
curl -fsSL https://paro.paroslab.io/install | sh -s -- --dry-run --profile lite
curl -fsSI https://paro.paroslab.io/latest/checksums.txt
```
