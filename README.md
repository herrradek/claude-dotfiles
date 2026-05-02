# Claude Dotfiles

Portable Claude Code configuration — rules, learned skills, settings.

Syncs across machines via GitHub. Intended for your personal `~/.claude` directory
(not plugin-managed agent files which auto-install).

## What's Tracked

| Path | Contents |
|---|---|
| `rules/common/` | Coding style, testing, security, git workflow, etc. |
| `rules/web/` | Web/frontend-specific rules |
| `skills/learned/` | Patterns extracted via `/learn` |
| `settings.json` | Plugin toggles, view mode, model preference |
| `AGENTS.md` | Custom agent definitions |

## Setup on a New Machine

```bash
# 1. Clone
git clone https://github.com/YOUR_USER/claude-dotfiles.git ~/claude-dotfiles

# 2. Install to ~/.claude
~/claude-dotfiles/sync.sh install
```

## After Making Changes (any machine)

```bash
cd ~/claude-dotfiles
./sync.sh collect
git add -A
git commit -m "update claude config"
git push
```

## Pull Latest to Another Machine

```bash
cd ~/claude-dotfiles
git pull
./sync.sh install
```

## Manual Bootstrap (No Git)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/claude-dotfiles/main/sync.sh | bash -s install
```

## Prerequisites

- Claude Code CLI installed
- `rsync` or basic `cp` (default)

## What's NOT Tracked

- Plugin-managed agents (auto-installed by marketplace)
- Session history and memory
- API keys and secrets
- Cache and temporary files
