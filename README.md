# bootstrap-sidequest

Headless-friendly fresh-Mac bootstrap. One curl, sudo prompts work, never sleeps.

```bash
curl -fsSL https://raw.githubusercontent.com/EZ-Walk/bootstrap-sidequest/main/install.sh | bash
```

## What it installs

- **Homebrew** — package manager
- **git, gh, curl, wget** — basics
- **Node.js (LTS) + npm**
- **Python 3.12 + uv** — modern Python tooling
- **Tailscale CLI + `tailscaled` (unsandboxed)** — registered as a system daemon so `tailscale up --ssh` actually works
- **Claude Code** — Anthropic's CLI
- **Headless `pmset` profile** — never sleeps, wake-on-LAN on, lid-close sleep disabled, TCP keepalive on

## Why not the Tailscale GUI cask?

The macOS Tailscale GUI (from the App Store or `brew install --cask tailscale`) is sandboxed
and **cannot host the Tailscale SSH server**. `tailscale up --ssh` silently no-ops against it.
For a headless / always-on Mac, the formula + system daemon path is the only one that works.

## What it does *not* install

No dotfiles, no SSH keys, no per-machine identity, no agent config. Generic baseline only.
For a personalized machine config, layer your own repo on top after this finishes.

## Manual steps after

1. Open a new terminal (or `source ~/.zprofile`) so `PATH` picks up brew-installed tools
2. `gh auth login` — authenticate GitHub
3. `sudo tailscale up --ssh --accept-routes` — join the tailnet and enable Tailscale SSH
4. `claude` — start Claude Code

## Idempotent

Safe to re-run. Each stage checks current state and skips if satisfied.
sudo prompts work under `curl | bash` because the script reattaches stdin to `/dev/tty`.
