#!/usr/bin/env sh
# paro bootstrap: download the prebuilt paro binary and run the installer.
#
# Usage:
#   curl -fsSL https://dots.paroslab.io/install | sh -s -- --profile lite
#   curl -fsSL https://github.com/christopher-paro/paro/releases/latest/download/boot.sh | sh -s -- --profile lite
#   sh boot.sh --dry-run [--profile <name>]
#   sh boot.sh --local /path/to/paro/repo --profile lite    # skip download; use local repo
#
# Profiles:
#   full  (default) — install everything; uses PRIVATE repo + GitHub token
#   lite            — container/minimal; uses PUBLIC repo; NO token needed
#   work            — full + .work overlay; uses PRIVATE repo + token
set -eu

# Public tokenless channel (containers)
PUBLIC_REPO="christopher-paro/paro"
PUBLIC_BASE="https://github.com/${PUBLIC_REPO}/releases/latest/download"
# Private channel (full + work)
PRIVATE_REPO="christopher-paro/.paro"
PRIVATE_API="https://api.github.com/repos/${PRIVATE_REPO}/releases/latest"

BINDIR="${HOME}/.local/bin"
LITE_REPO_DIR="${HOME}/.local/share/paro-lite"

PROFILE="full"
DRY_RUN=0
LOCAL_DIR=""

while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY_RUN=1 ;;
		--profile) shift; PROFILE="${1:-full}" ;;
		--profile=*) PROFILE="${1#--profile=}" ;;
		--local) shift; LOCAL_DIR="${1:-}" ;;
		--local=*) LOCAL_DIR="${1#--local=}" ;;
		-h|--help)
			sed -n '1,15p' "$0" | sed 's/^# \{0,1\}//'
			exit 0 ;;
		*) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
	esac
	shift || true
done

case "$PROFILE" in
	full|lite|work) ;;
	*) printf 'unknown profile: %s (have: full|lite|work)\n' "$PROFILE" >&2; exit 2 ;;
esac

say() { printf '==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# 1. OS/arch detection
os="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$(uname -m)" in
	x86_64|amd64) arch="amd64" ;;
	arm64|aarch64) arch="arm64" ;;
	*) die "unsupported arch: $(uname -m)" ;;
esac
say "platform: ${os}/${arch}  profile: ${PROFILE}"

# 2. deps
command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar  >/dev/null 2>&1 || die "tar is required"
# git is only needed for the full/work private-clone fallback and for full-repo mode.
[ "$PROFILE" = "lite" ] || command -v git >/dev/null 2>&1 || die "git is required for $PROFILE profile"

# 3. Local mode (testing): skip all downloads
if [ -n "$LOCAL_DIR" ]; then
	[ -d "$LOCAL_DIR" ] || die "--local dir does not exist: $LOCAL_DIR"
	[ -x "$LOCAL_DIR" ] || die "--local dir not accessible: $LOCAL_DIR"
	say "local mode: $LOCAL_DIR"
	if [ "$DRY_RUN" -eq 1 ]; then
		say "would build paro from ${LOCAL_DIR}/cmd/paro"
		say "would exec: paro install --profile ${PROFILE} --yes --repo ${LOCAL_DIR}"
		exit 0
	fi
	if [ -x "${LOCAL_DIR}/paro" ]; then
		BIN="${LOCAL_DIR}/paro"
	elif command -v go >/dev/null 2>&1; then
		say "building paro from source"
		( cd "$LOCAL_DIR" && go build -o /tmp/paro ./cmd/paro )
		BIN=/tmp/paro
	else
		die "no prebuilt paro at ${LOCAL_DIR}/paro and no 'go' to build from source"
	fi
	exec "$BIN" install --profile "$PROFILE" --yes --repo "$LOCAL_DIR"
fi

asset_bin="paro_${os}_${arch}.tar.gz"

# 4. Profile-specific bootstrap
if [ "$PROFILE" = "lite" ]; then
	# Public, tokenless path.
	if [ "$DRY_RUN" -eq 1 ]; then
		say "would download ${PUBLIC_BASE}/${asset_bin}"
		say "would download ${PUBLIC_BASE}/paro-lite.tar.gz"
		say "would install paro to ${BINDIR}/paro"
		say "would extract lite bundle to ${LITE_REPO_DIR}"
		say "would exec: paro install --profile lite --yes --repo ${LITE_REPO_DIR}"
		exit 0
	fi
	tmp="$(mktemp -d)"
	say "downloading paro binary (no auth)"
	curl -fsSL "${PUBLIC_BASE}/${asset_bin}" -o "$tmp/$asset_bin"
	tar -xzf "$tmp/$asset_bin" -C "$tmp"
	mkdir -p "$BINDIR"
	mv "$tmp/paro" "$BINDIR/paro"
	chmod +x "$BINDIR/paro"
	say "downloading paro-lite config bundle"
	curl -fsSL "${PUBLIC_BASE}/paro-lite.tar.gz" -o "$tmp/paro-lite.tar.gz"
	mkdir -p "$LITE_REPO_DIR"
	tar -xzf "$tmp/paro-lite.tar.gz" -C "$LITE_REPO_DIR"
	say "installed paro to ${BINDIR}/paro"
	case ":$PATH:" in
		*":$BINDIR:"*) ;;
		*) say "note: add ${BINDIR} to your PATH" ;;
	esac
	exec "$BINDIR/paro" install --profile lite --yes --repo "$LITE_REPO_DIR"
fi

# 5. full/work: private repo + token
token=""
if command -v gh >/dev/null 2>&1; then
	token="$(gh auth token 2>/dev/null || true)"
fi
if [ -z "$token" ] && [ "$DRY_RUN" -eq 0 ]; then
	printf 'GitHub token (repo scope, for PRIVATE release download): '
	stty -echo 2>/dev/null || true
	read -r token
	stty echo 2>/dev/null || true
	printf '\n'
fi

if [ "$DRY_RUN" -eq 1 ]; then
	say "would download ${asset_bin} from ${PRIVATE_API}"
	say "would install paro to ${BINDIR}/paro"
	say "would exec: paro install --profile ${PROFILE}"
	exit 0
fi

say "resolving latest private release"
asset_url="$(curl -fsSL -H "Authorization: Bearer ${token}" "$PRIVATE_API" \
	| grep -o "https://[^\"]*${asset_bin}" | head -n1 || true)"
if [ -z "$asset_url" ]; then
	say "release asset not found; falling back to clone + install.sh"
	dest="${HOME}/dev/personal/.paro"
	if [ ! -d "$dest/.git" ]; then
		git clone "git@github.com:${PRIVATE_REPO}.git" "$dest"
	fi
	exec sh "$dest/install.sh"
fi

tmp="$(mktemp -d)"
say "downloading ${asset_bin}"
curl -fsSL -H "Authorization: Bearer ${token}" -H "Accept: application/octet-stream" \
	"$asset_url" -o "$tmp/$asset_bin"
tar -xzf "$tmp/$asset_bin" -C "$tmp"
mkdir -p "$BINDIR"
mv "$tmp/paro" "$BINDIR/paro"
chmod +x "$BINDIR/paro"
say "installed paro to ${BINDIR}/paro"

case ":$PATH:" in
	*":$BINDIR:"*) ;;
	*) say "note: add ${BINDIR} to your PATH" ;;
esac

exec "$BINDIR/paro" install --profile "$PROFILE"
