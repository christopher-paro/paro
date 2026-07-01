# dots / paro

Tokenless install channel for [paro](https://github.com/christopher-paro/.paro) dotfiles.

## Install

Preferred personal-domain entrypoint:

```sh
curl -fsSL https://dots.paroslab.io/install | sh -s -- --profile lite
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

No GitHub authentication required for the `lite` profile.

## Commands

Quick command sheet from any terminal:

```sh
curl -fsSL https://dots.paroslab.io
```

```sh
# Lite/public profile
curl -fsSL https://dots.paroslab.io/install | sh -s -- --profile lite

# Full/private profile, prompts for or discovers a GitHub token
curl -fsSL https://dots.paroslab.io/install | sh

# Work overlay
curl -fsSL https://dots.paroslab.io/install | sh -s -- --profile work

# Dry run
curl -fsSL https://dots.paroslab.io/install | sh -s -- --dry-run --profile lite

# Local testing
sh boot.sh --local /path/to/paro/repo --profile lite
```

## Versioned installs

```sh
curl -fsSL https://github.com/christopher-paro/paro/releases/download/v0.1.0/boot.sh | sh -s -- --profile lite
```

The website at `https://dots.paroslab.io` includes a version tab so older releases can keep their install command and docs visible as more releases are published.

## Domain hosting

`dots.paroslab.io` is hosted from the personal Kubernetes cluster through the ops GitOps repo.

See [KUBERNETES.md](./KUBERNETES.md).

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
