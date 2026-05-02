# Model Tier Routing via Environment Variables

**Extracted:** 2026-05-02
**Context:** Overriding proxy model assignments per-session using environment variables instead of editing .env files.

## Problem

The `free-claude-code` proxy supports model tier routing (`MODEL_OPUS`, `MODEL_SONNET`, `MODEL_HAIKU`, `MODEL`) in `.env`. But editing `.env` to temporarily switch models is tedious and error-prone — especially when comparing different models.

## Solution

Set the model tier vars as environment variables when launching Claude Code. These take precedence over `.env` values. Wrap in shell scripts for named presets.

### Pattern

```bash
# Override just Opus tier for a heavy reasoning session
MODEL_OPUS="nvidia_nim/moonshotai/kimi-k2.5" \
    ANTHROPIC_BASE_URL="http://localhost:8082" \
    ANTHROPIC_AUTH_TOKEN="freecc" \
    claude

# Or create a script that forces all tiers to one model:
#!/usr/bin/env bash
unset ANTHROPIC_API_KEY
ANTHROPIC_BASE_URL="http://localhost:8082" ANTHROPIC_AUTH_TOKEN="freecc" \
    MODEL_OPUS="nvidia_nim/openai/gpt-oss-120b" \
    MODEL_SONNET="nvidia_nim/openai/gpt-oss-120b" \
    MODEL_HAIKU="nvidia_nim/openai/gpt-oss-120b" \
    MODEL="nvidia_nim/openai/gpt-oss-120b" \
    claude "$@"
```

### Available Tiers

| Variable | Purpose |
|---|---|
| `MODEL_OPUS` | Heavy reasoning (complex refactoring, architecture) |
| `MODEL_SONNET` | Default tier (general coding) |
| `MODEL_HAIKU` | Fast/cheap tier (simple edits, quick questions) |
| `MODEL` | Fallback when no tier-specific var is set |

## When to Use

- Comparing different models without editing config files
- Creating shareable scripts with hardcoded model choices
- Temporary per-session override of default tier routing
