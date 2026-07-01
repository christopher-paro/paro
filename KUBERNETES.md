# Kubernetes hosting

`https://dots.paro.sh` is hosted from the personal Kubernetes cluster.

The GitOps app lives in the ops repo at:

```text
~/dev/personal/ops/apps/paro
```

## Install URL

```sh
curl -fsSL https://dots.paro.sh/install | sh -s -- --profile lite
```

Routes are GitOps-managed from `~/dev/personal/ops/apps/paro/deploy`.

The Kubernetes deployment includes a tiny release-sync sidecar that polls the public GitHub releases API about every 10 minutes and writes generated `/versions.json` and `/commands.txt` files. That means the browser version tabs and `curl https://dots.paro.sh` command sheet pick up newly published public releases without editing the static HTML each time.

## Routes

- `/` — clean install/documentation home page in browsers; terminal clients such as `curl` receive the plain text command sheet.
- `/commands.txt` — explicit terminal-friendly command sheet.
- `/versions.json` — generated release metadata used by the homepage version tabs.
- `/install` — serves `boot.sh` directly for `curl | sh`.
- `/boot.sh` — same installer script checked into this repo and copied into the Kubernetes ConfigMap.
- `/latest/<asset>` — redirects to the current GitHub release asset.
- `/releases/latest/download/<asset>` — GitHub-compatible latest asset redirect.
- `/gh` — redirects to the public GitHub repo.

The binary and tarball artifacts still live in GitHub Releases. Kubernetes hosts the stable personal-domain entrypoint and bootstrap script.

## Smoke checks

```sh
curl -fsSI https://dots.paro.sh/
curl -fsSL https://dots.paro.sh/
curl -fsSL https://dots.paro.sh/versions.json
curl -fsSL https://dots.paro.sh/install | sh -s -- --dry-run --profile lite
curl -fsSI https://dots.paro.sh/latest/checksums.txt
```
