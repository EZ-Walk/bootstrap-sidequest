#!/usr/bin/env bash
# install.sh — fresh-Mac bootstrap: brew, git, node, python, tailscale, claude code.
#
# Usage (fresh machine — no brew, no git, nothing):
#   curl -fsSL https://raw.githubusercontent.com/EZ-Walk/bootstrap-sidequest/main/install.sh | bash
#
# Idempotent. Safe to re-run. No personal config — just dev tools.

set -euo pipefail

# Reattach stdin to the terminal so sudo prompts work when invoked as
# `curl ... | bash` (stdin is the curl pipe, not a TTY). Without this,
# every sudo stage silently fails and the script continues with the
# affected stages no-op'd.
if [[ ! -t 0 ]] && [[ -e /dev/tty ]]; then
  exec </dev/tty
fi

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

# --- 6. Tailscale system daemon -------------------------------------------
# The formula installs the binary but does NOT register tailscaled with
# launchd. Without this, the unsandboxed daemon never runs and `tailscale
# up` would talk to whichever (sandboxed) daemon happens to be active —
# breaking `--ssh`. Idempotent: the installer no-ops if already present.
if have tailscaled; then
  if ! sudo launchctl print system/com.tailscale.tailscaled >/dev/null 2>&1; then
    log "Installing tailscaled as a system daemon…"
    sudo tailscaled install-system-daemon
  fi
fi

# --- 7. Headless power management (pmset) ---------------------------------
# Designed for always-on, unattended Macs. Prevents every sleep mode,
# enables wake-on-LAN, keeps TCP connections alive. `caffeinate` is NOT
# sufficient — it only suppresses sleep while a process is running, and
# does not survive a reboot or terminal exit.
log "Setting headless power management…"
sudo pmset -a sleep 0
sudo pmset -a disablesleep 1     # overrides lid-close sleep on laptops
sudo pmset -a displaysleep 0
sudo pmset -a disksleep 0
sudo pmset -a womp 1             # wake on magic packet (LAN)
sudo pmset -a powernap 0
sudo pmset -a hibernatemode 0
sudo pmset -a autopoweroff 0
sudo pmset -a standby 0
sudo pmset -a tcpkeepalive 1

# --- 8. Done ---------------------------------------------------------------
cat <<EOF

──────────────────────────────────────────────────────────────────────────────
  Bootstrap complete. Installed:
──────────────────────────────────────────────────────────────────────────────

    • Homebrew, git, gh, curl, wget
    • Node.js (LTS) + npm
    • Python 3.12 + uv
    • Tailscale CLI + unsandboxed tailscaled daemon
    • Claude Code
    • Headless pmset profile (never-sleep, wake-on-LAN)

  Open a new terminal (or run \`source ~/.zprofile\`), then:

    1. gh auth login                                  # authenticate GitHub
    2. sudo tailscale up --ssh --accept-routes        # join tailnet + enable SSH
    3. claude                                         # start Claude Code

──────────────────────────────────────────────────────────────────────────────
EOF
