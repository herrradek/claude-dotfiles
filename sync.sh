#!/usr/bin/env bash
# Claude Dotfiles Sync
# =====================
#
# TWO-WAY: collects files FROM ~/.claude into this repo (for committing)
# and also installs files FROM this repo TO ~/.claude (for new machines).
#
# Usage:
#   ./sync.sh collect   — copy from ~/.claude into repo (after making changes)
#   ./sync.sh install   — copy from repo into ~/.claude (fresh machine)
#   ./sync.sh           — same as collect

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mode="${1:-collect}"

case "$mode" in
  collect)
    echo "==> Collecting from ~/.claude into repo..."

    # Rules
    mkdir -p "$REPO_DIR/rules/common"
    cp "$CLAUDE_DIR/rules/common/"*.md "$REPO_DIR/rules/common/" 2>/dev/null || true

    mkdir -p "$REPO_DIR/rules/web"
    cp "$CLAUDE_DIR/rules/web/"*.md "$REPO_DIR/rules/web/" 2>/dev/null || true

    # Learned skills
    mkdir -p "$REPO_DIR/skills/learned"
    cp "$CLAUDE_DIR/skills/learned/"*.md "$REPO_DIR/skills/learned/" 2>/dev/null || true

    # Settings
    cp "$CLAUDE_DIR/settings.json" "$REPO_DIR/settings.json" 2>/dev/null || true

    # AGENTS.md (user-defined agents)
    cp "$CLAUDE_DIR/AGENTS.md" "$REPO_DIR/AGENTS.md" 2>/dev/null || true

    # README
    cp "$REPO_DIR/README.md" "$REPO_DIR/README.md" 2>/dev/null || true

    # Wrapper scripts (from free-claude-code)
    mkdir -p "$REPO_DIR/scripts"
    cp "$REPO_DIR/scripts/"*.sh "$REPO_DIR/scripts/" 2>/dev/null || true

    echo "==> Done. Files staged in $REPO_DIR"
    echo "    Review with: git diff"
    echo "    Commit with: git add -A && git commit -m 'update dotfiles'"
    ;;
  install)
    echo "==> Installing to ~/.claude from repo..."

    mkdir -p "$CLAUDE_DIR/rules/common"
    mkdir -p "$CLAUDE_DIR/rules/web"
    mkdir -p "$CLAUDE_DIR/skills/learned"

    cp "$REPO_DIR/rules/common/"*.md "$CLAUDE_DIR/rules/common/" 2>/dev/null || true
    cp "$REPO_DIR/rules/web/"*.md "$CLAUDE_DIR/rules/web/" 2>/dev/null || true
    cp "$REPO_DIR/skills/learned/"*.md "$CLAUDE_DIR/skills/learned/" 2>/dev/null || true
    cp "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json" 2>/dev/null || true
    cp "$REPO_DIR/AGENTS.md" "$CLAUDE_DIR/AGENTS.md" 2>/dev/null || true

    # Symlink wrapper scripts into ~/.local/bin
    if [ -d "$REPO_DIR/scripts" ]; then
        mkdir -p "$HOME/.local/bin"
        for f in "$REPO_DIR/scripts"/claude-*; do
            [ -f "$f" ] && ln -sf "$f" "$HOME/.local/bin/$(basename "$f")"
        done
        echo "==> Symlinked wrapper scripts to ~/.local/bin"
    fi

    echo "==> Done. Files installed to ~/.claude"
    echo "    Start a new Claude session to pick them up."
    ;;
  *)
    echo "Usage: $0 [collect|install]"
    exit 1
    ;;
esac
