#!/usr/bin/env bash
# install.sh — fresh-Mac bootstrap: brew, git, node, python, tailscale, claude code.
#
# Usage (fresh machine — no brew, no git, nothing):
#   curl -fsSL https://raw.githubusercontent.com/EZ-Walk/bootstrap-sidequest/main/install.sh | bash
#
# Idempotent. Safe to re-run. No personal config — just dev tools.

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/EZ-Walk/bootstrap-sidequest/main"

log()  { printf "\033[1;34m[bootstrap]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[bootstrap]\033[0m %s\n" "$*" >&2; }
die()  { printf "\033[1;31m[bootstrap]\033[0m %s\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- 0. Sanity --------------------------------------------------------------
[[ "$(uname -s)" == "Darwin" ]] || die "macOS only. Detected: $(uname -s)"
log "macOS $(sw_vers -productVersion) on $(uname -m)"

# --- 1. Xcode Command Line Tools -------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (GUI prompt will appear)…"
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

# --- 2. Homebrew ------------------------------------------------------------
if ! have brew; then
  log "Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew    ]]; then eval "$(/usr/local/bin/brew shellenv)"
else die "Homebrew installed but brew binary not found in expected paths."
fi

# --- 3. Persist brew shellenv in ~/.zprofile for future shells -------------
ZPROFILE="$HOME/.zprofile"
BREW_PREFIX="$(brew --prefix)"
BREW_LINE="eval \"\$($BREW_PREFIX/bin/brew shellenv)\""
if ! grep -qF "$BREW_LINE" "$ZPROFILE" 2>/dev/null; then
  log "Adding brew to ~/.zprofile"
  printf '\n# Homebrew\n%s\n' "$BREW_LINE" >> "$ZPROFILE"
fi

# --- 4. Brewfile (fetched from this repo) ----------------------------------
TMP_BREWFILE="$(mktemp)"
trap 'rm -f "$TMP_BREWFILE"' EXIT
log "Fetching Brewfile from $REPO_RAW/Brewfile"
curl -fsSL "$REPO_RAW/Brewfile" -o "$TMP_BREWFILE"
log "Running brew bundle…"
brew bundle --file="$TMP_BREWFILE"

# --- 5. Claude Code (via npm — node was installed by brew bundle) ----------
if ! have claude; then
  log "Installing Claude Code…"
  npm install -g @anthropic-ai/claude-code
fi

# --- 6. Done ---------------------------------------------------------------
cat <<EOF

──────────────────────────────────────────────────────────────────────────────
  Bootstrap complete. Installed:
──────────────────────────────────────────────────────────────────────────────

    • Homebrew, git, gh, curl, wget
    • Node.js (LTS) + npm
    • Python 3.12 + uv
    • Tailscale (GUI app, in /Applications)
    • Claude Code

  Open a new terminal (or run \`source ~/.zprofile\`), then:

    1. gh auth login            # authenticate GitHub
    2. open -a Tailscale        # launch Tailscale app, sign in
    3. claude                   # start Claude Code

──────────────────────────────────────────────────────────────────────────────
EOF
