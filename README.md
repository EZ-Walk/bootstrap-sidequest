# bootstrap-sidequest

Fresh-Mac bootstrap. One curl, no auth.

```bash
curl -fsSL https://raw.githubusercontent.com/EZ-Walk/bootstrap-sidequest/main/install.sh | bash
```

## What it installs

- **Homebrew** — package manager
- **git, gh, curl, wget** — basics
- **Node.js (LTS) + npm**
- **Python 3.12 + uv** — modern Python tooling
- **Tailscale** — mesh VPN (GUI app)
- **Claude Code** — Anthropic's CLI

## What it does *not* install

No dotfiles, no SSH keys, no per-machine identity, no agent config. Generic baseline only.
For a personalized machine config, layer your own repo on top after this finishes.

## Manual steps after

1. Open a new terminal (or `source ~/.zprofile`) so `PATH` picks up brew-installed tools
2. `gh auth login` — authenticate GitHub
3. Launch Tailscale.app, sign in
4. `claude` — start Claude Code

## Idempotent

Safe to re-run. Each stage checks current state and skips if satisfied.
