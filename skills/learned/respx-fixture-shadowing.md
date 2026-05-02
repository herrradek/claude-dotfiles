# respx Fixture Name Collision

**Extracted:** 2026-05-02
**Context:** Using `respx` with pytest to mock HTTP calls in async tests

## Problem

When using `respx` to mock HTTP requests in pytest, naming your fixture `respx_mock` causes silent test failures. The `respx` pytest plugin registers its own internal fixture under the exact name `respx_mock`, so any user fixture with the same name shadows (overrides) the plugin's fixture. The mock simply never works — requests go unmocked and tests fail with real HTTP errors or timeouts.

The error message doesn't tell you this. You'll see connection errors or timeouts with no hint about the fixture collision.

## Root Cause

`respx` registers its fixture via pytest entry points — it effectively does:

```python
@pytest.fixture
def respx_mock():
    ...
```

This is loaded by the plugin system before user fixtures. When you define a fixture with the same name, it overrides the plugin's version.

## Solution

**Rename your fixture** to something unique — never use `respx_mock` as a parameter name. If you need a fixture that wraps `respx_mock`, use a different name and call `respx_mock` internally:

```python
import respx


# WRONG — shadows the plugin's internal fixture
async def test_something(respx_mock):          # ← BUG
    respx_mock.get("https://api.example.com").respond(200, json={"ok": True})


# CORRECT — use any other name
async def test_something(respx):               # ← OK
    respx.get("https://api.example.com").respond(200, json={"ok": True})


# Also OK — custom fixture wrapping respx_mock under a different name
@pytest.fixture
def nvimock(respx_mock):
    """NVIDIA API mock. Wraps respx_mock internally."""
    yield respx_mock


async def test_nvidia(nvimock):
    nvimock.post("https://integrate.api.nvidia.com/...").respond(...)
```

## Detection

If your `respx`-based mock silently doesn't work:
1. Check if any fixture or test parameter is named `respx_mock`
2. Rename it to something else (e.g., just `respx`)
3. If that fixes it, you hit this collision

## When to Use

- Any time you write a pytest test using `respx` for HTTP mocking
- When debugging a `respx` mock that appears to be ignored
- When creating a custom fixture that wraps `respx`
