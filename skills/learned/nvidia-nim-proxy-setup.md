# NVIDIA NIM Proxy Setup for Claude Code

**Extracted:** 2026-05-02
**Context:** Setting up the `free-claude-code` proxy to route Claude Code traffic through NVIDIA's free NIM API at build.nvidia.com.

## Problem

Claude Code speaks the Anthropic Messages API protocol. NVIDIA NIM (and many other providers) speak the OpenAI chat-completions protocol. A translation layer is needed to use non-Anthropic backends with Claude Code CLI.

## Solution

Use the `free-claude-code` proxy (github.com/Alishahryar1/free-claude-code) — an ASGI server built with FastAPI/uvicorn that translates between Anthropic Messages API and OpenAI-compatible APIs.

### Setup Steps

```bash
# 1. Clone
git clone https://github.com/Alishahryar1/free-claude-code.git
cd free-claude-code

# 2. Install deps
uv sync

# 3. Configure .env
cp .env.example .env
# Edit: set NVIDIA_NIM_API_KEY, MODEL, ANTHROPIC_AUTH_TOKEN

# 4. Start proxy
uv run uvicorn server:app --host 0.0.0.0 --port 8082 --timeout-graceful-shutdown 5

# 5. Connect Claude Code (separate terminal)
ANTHROPIC_BASE_URL=http://localhost:8082 ANTHROPIC_AUTH_TOKEN=freecc claude
```

### Key Configuration

The proxy uses `ANTHROPIC_AUTH_TOKEN` as its own auth mechanism (sent as `x-api-key` header by Claude Code). The actual backend API key (e.g., `NVIDIA_NIM_API_KEY`) lives only in `.env` — never sent to Claude Code.

### Model Tier Routing

The proxy maps Claude Code's model tiers to backend models via env vars:

```
MODEL_OPUS="nvidia_nim/qwen/qwen3.5-397b-a17b"   # Heavy reasoning
MODEL_SONNET="nvidia_nim/qwen/qwen3.5-397b-a17b"   # Default
MODEL_HAIKU="nvidia_nim/qwen/qwen3.5-397b-a17b"    # Fast/cheap
MODEL="nvidia_nim/qwen/qwen3.5-397b-a17b"          # Fallback
```

Each tier can route to a different provider or model.

## When to Use

- You want to use Claude Code CLI with NVIDIA's free API tier
- You need to route Claude Code through any OpenAI-compatible backend
- You want per-tier model routing (Opus/Sonnet/Haiku → different providers)
