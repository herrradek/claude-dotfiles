# Proxy Auto-Start in Wrapper Scripts

**Extracted:** 2026-05-02
**Context:** Building wrapper scripts that automatically start a local proxy server before launching Claude Code, without requiring the user to manage separate terminal windows.

## Problem

Proxy-based Claude Code setups require the proxy to be running before Claude Code starts. Forgetting to start the proxy leads to connection errors. Managing a separate terminal window for the proxy is friction.

## Solution

Embed proxy lifecycle management into the wrapper script:

1. **Health check** — probe the proxy endpoint before proceeding
2. **Auto-start** — launch the proxy in background with `nohup` if not running
3. **Wait loop** — poll until the proxy is ready (with timeout)
4. **Launch** — start Claude Code with the proxy URL

### Pattern

```bash
#!/usr/bin/env bash

# Auto-start proxy if not already running
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/v1/models 2>/dev/null | grep -q "422\|200"; then
    echo "Starting proxy..."
    nohup uv run uvicorn server:app --host 0.0.0.0 --port 8082 --timeout-graceful-shutdown 5 \
        > /tmp/proxy.log 2>&1 &
    # Wait up to 15 seconds for proxy to be ready
    for i in {1..15}; do
        sleep 1
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/v1/models 2>/dev/null | grep -q "422\|200"; then
            break
        fi
    done
fi

# Launch Claude Code
unset ANTHROPIC_API_KEY
ANTHROPIC_BASE_URL="http://localhost:8082" ANTHROPIC_AUTH_TOKEN="freecc" claude "$@"
```

### Companion: Stop Script

```bash
#!/usr/bin/env bash
PID=$(pgrep -f "uvicorn.*server.*8082" | head -1)
if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null
else
    echo "No proxy running on port 8082."
fi
```

### Symlink to PATH

```bash
ln -sf /path/to/script.sh ~/.local/bin/claude-myname
```

## When to Use

- Writing wrapper scripts that depend on a local server
- You don't want to manage separate terminal windows for background processes
- You want scripts to be idempotent (run multiple times safely)
