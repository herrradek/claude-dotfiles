# Multi-Backend Claude Code Wrapper Scripts

**Extracted:** 2026-05-02
**Context:** Setting up wrapper scripts to switch Claude Code between NVIDIA NIM proxy, DeepSeek, and native Anthropic backends via different shell commands.

## Problem

Claude Code's API backend is controlled by environment variables (`ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_API_KEY`). Switching between backends (e.g., NVIDIA free tier vs DeepSeek vs paid Anthropic) requires manually setting/unsetting env vars or editing config files — friction that makes you stick to one backend.

## Solution

Create individual shell scripts per backend, each self-contained with its own env vars. Symlink them into `~/.local/bin` so they're on PATH as regular commands.

### Pattern

```bash
#!/usr/bin/env bash
# One-line description
# Usage: claude-backendname [args...]

unset ANTHROPIC_API_KEY
ANTHROPIC_BASE_URL="<backend-url>" \
    [OTHER_VARS="..."] \
    claude "$@"
```

For proxy-based backends (like NVIDIA NIM), add auto-start logic:

```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-start proxy if not running
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/v1/models 2>/dev/null | grep -q "422\|200"; then
    echo "Starting proxy..."
    nohup uv run uvicorn server:app --host 0.0.0.0 --port 8082 --timeout-graceful-shutdown 5 \
        > /tmp/proxy.log 2>&1 &
    for i in {1..15}; do
        sleep 1
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/v1/models 2>/dev/null | grep -q "422\|200"; then
            break
        fi
    done
fi

unset ANTHROPIC_API_KEY
ANTHROPIC_BASE_URL="http://localhost:8082" ANTHROPIC_AUTH_TOKEN="freecc" claude "$@"
```

### Example

```
~/.local/bin/claude-nvidia       → NVIDIA proxy (reads model from .env)
~/.local/bin/claude-deepseek     → DeepSeek Anthropic endpoint
~/.local/bin/claude-direct        → Native Anthropic (paid)
~/.local/bin/claude-proxy-stop    → Stop the proxy server
```

## When to Use

- You have multiple API backends for Claude Code
- You want to switch backends by typing a different command name
- You're using a local proxy that needs to be running before Claude Code starts
