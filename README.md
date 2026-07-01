# paro

Tokenless install channel for [paro](https://github.com/christopher-paro/.paro) dotfiles.

## Install

Preferred personal-domain entrypoint, once the Cloudflare Pages custom domain is attached:

```sh
curl -fsSL https://paro.paroslab.io/install | sh -s -- --profile lite
```

GitHub Releases fallback:

```sh
curl -fsSL https://github.com/christopher-paro/paro/releases/latest/download/boot.sh | sh -s -- --profile lite
```

Installs:

- `paro` CLI binary (`~/.local/bin/paro`)
- neovim + ripgrep + fd + fzf + bat + eza
- `~/.config/nvim` (the real config, via the `.lite` overlay)
- `~/.config/paro-keymaps/` (fish abbrevs + tmux binds safe for containers)

No GitHub authentication required.

## Cloudflare hosting

This repo is designed to be connected directly to Cloudflare Pages and served at `paro.paroslab.io`.

See [CLOUDFLARE.md](./CLOUDFLARE.md).

## Everything else

For the full dotfiles set (Claude Code + Codex + Gemini + OpenCode configs, tmux orchestrator, desktop configs, work overlay), see the private repo `christopher-paro/.paro`.

## Releases

Assets are mirrored automatically from the private repo on each tag by a GitHub Actions workflow. Each release includes:

- `paro_<os>_<arch>.tar.gz` — prebuilt binary
- `paro-lite.tar.gz` — the lite config bundle (nvim + keymaps)
- `boot.sh` — this same script (as an asset for pinning specific versions)
- `checksums.txt`

## Verify

```sh
curl -fsSLO https://github.com/christopher-paro/paro/releases/latest/download/checksums.txt
sha256sum -c checksums.txt --ignore-missing
```
