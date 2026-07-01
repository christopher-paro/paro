#!/usr/bin/env sh
# paro bootstrap: download the prebuilt paro binary and run the installer.
#
# Usage:
#   curl -fsSL https://github.com/christopher-paro/paro/releases/latest/download/boot.sh | sh
#   curl -fsSL <url>/boot.sh | sh -s -- --profile lite
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

# 2. deps — auto-install curl / tar / git / gh via the platform package manager
#    when missing. `full` and `work` also want gh so we can grab a token for the
#    private release without prompting; `lite` skips gh entirely.
_detect_pm() {
	case "$os" in
		darwin) command -v brew >/dev/null 2>&1 && echo brew ;;
		linux)
			if   command -v apt-get >/dev/null 2>&1; then echo apt
			elif command -v dnf     >/dev/null 2>&1; then echo dnf
			elif command -v pacman  >/dev/null 2>&1; then echo pacman
			fi ;;
	esac
}
_pm="$(_detect_pm)"

_sudo=""
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
	_sudo="sudo"
fi

# Map a tool name to the correct package name for the current PM.
_pkg_name() {
	tool="$1"
	case "${_pm}:${tool}" in
		apt:gh|dnf:gh|pacman:gh|brew:gh) echo gh ;;
		apt:git) echo git ;;
		apt:curl) echo curl ;;
		apt:tar) echo tar ;;
		dnf:*|pacman:*|brew:*) echo "$tool" ;;
		*) echo "$tool" ;;
	esac
}

_install_pkg() {
	tool="$1"
	pkg="$(_pkg_name "$tool")"
	if [ -z "$_pm" ]; then
		die "$tool is required but no supported package manager found (need apt/dnf/pacman/brew)"
	fi
	say "installing $tool via $_pm"
	case "$_pm" in
		apt)    $_sudo apt-get update -qq && $_sudo apt-get install -y "$pkg" ;;
		dnf)    $_sudo dnf install -y "$pkg" ;;
		pacman) $_sudo pacman -S --needed --noconfirm "$pkg" ;;
		brew)
			if ! command -v brew >/dev/null 2>&1; then
				say "installing Homebrew (macOS)"
				/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
			fi
			brew install "$pkg" ;;
	esac
}

_ensure_tool() {
	tool="$1"
	if command -v "$tool" >/dev/null 2>&1; then return 0; fi
	# On Debian/Ubuntu, `gh` needs the GitHub apt source. Install via the
	# upstream one-liner instead of assuming the distro packages it.
	if [ "$tool" = "gh" ] && [ "$_pm" = "apt" ]; then
		say "installing gh from the official GitHub CLI apt source"
		(
			set -e
			$_sudo mkdir -p -m 755 /etc/apt/keyrings
			curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
				| $_sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
			$_sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
			echo "deb [arch=$(dpkg --print-architecture 2>/dev/null || echo amd64) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
				| $_sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
			$_sudo apt-get update -qq
			$_sudo apt-get install -y gh
		) && return 0
	fi
	_install_pkg "$tool"
}

_ensure_tool curl
_ensure_tool tar
if [ "$PROFILE" != "lite" ]; then
	_ensure_tool git
	_ensure_tool gh
fi

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
	# gh present but not authed — kick off the interactive login flow.
	if [ -z "$token" ] && [ "$DRY_RUN" -eq 0 ]; then
		say "gh is not authenticated; running 'gh auth login' interactively"
		say "(choose 'GitHub.com', pick SSH or HTTPS, and complete the browser flow)"
		gh auth login || die "gh auth login failed; rerun boot.sh after resolving"
		token="$(gh auth token 2>/dev/null || true)"
	fi
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
