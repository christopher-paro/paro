# Kubernetes hosting

`https://dots.paroslab.io` is hosted from the personal Kubernetes cluster.

The GitOps app lives in the ops repo at:

```text
~/dev/personal/ops/apps/paro
```

## Install URL

```sh
curl -fsSL https://dots.paroslab.io/install | sh -s -- --profile lite
```

## Routes

- `/` — clean install/documentation home page in browsers; terminal clients such as `curl` receive the plain text command sheet.
- `/commands.txt` — explicit terminal-friendly command sheet.
- `/install` — serves `boot.sh` directly for `curl | sh`.
- `/boot.sh` — same installer script checked into this repo and copied into the Kubernetes ConfigMap.
- `/latest/<asset>` — redirects to the current GitHub release asset.
- `/releases/latest/download/<asset>` — GitHub-compatible latest asset redirect.
- `/gh` — redirects to the public GitHub repo.

The binary and tarball artifacts still live in GitHub Releases. Kubernetes hosts the stable personal-domain entrypoint and bootstrap script.

## Smoke checks

```sh
curl -fsSI https://dots.paroslab.io/
curl -fsSL https://dots.paroslab.io/
curl -fsSL https://dots.paroslab.io/install | sh -s -- --dry-run --profile lite
curl -fsSI https://dots.paroslab.io/latest/checksums.txt
```
