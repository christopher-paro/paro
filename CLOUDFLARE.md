# Cloudflare Pages hosting

This public repo is ready to host as a tiny Cloudflare Pages site for a memorable install URL.

## Recommended domain

Use `paro.paroslab.io` as the custom domain.

After Pages is connected, install with:

```sh
curl -fsSL https://paro.paroslab.io/install | sh -s -- --profile lite
```

## Cloudflare setup

1. Cloudflare Dashboard → Workers & Pages → Create application → Pages → Connect to Git.
2. Select `christopher-paro/paro`.
3. Build settings:
   - Framework preset: `None`
   - Build command: empty
   - Build output directory: `/`
4. Deploy.
5. Pages project → Custom domains → add `paro.paroslab.io`.
6. Optional: also add `install.paroslab.io` as an alias if you want both hostnames.

## Routes provided by this repo

- `/` — small landing page with the install command.
- `/install` — serves `boot.sh` directly for `curl | sh`.
- `/boot.sh` — same installer script checked into this repo.
- `/latest/<asset>` — redirects to the latest GitHub release asset, for example `/latest/checksums.txt`.
- `/releases/latest/download/<asset>` — GitHub-compatible latest asset redirect.

The binary and tarball artifacts still live in GitHub Releases. Cloudflare gives you the stable personal-domain entrypoint and CDN-cached bootstrap script without duplicating release storage.

## Smoke checks

Once deployed:

```sh
curl -fsSI https://paro.paroslab.io/
curl -fsSL https://paro.paroslab.io/install | sh -s -- --dry-run --profile lite
curl -fsSI https://paro.paroslab.io/latest/checksums.txt
```
