# Qwen Model Selection for Coding (Early 2026)

**Extracted:** 2026-05-02
**Context:** Evaluating Qwen models available on NVIDIA NIM for Claude Code proxy usage — determining the best model for coding tasks.

## Problem

Multiple Qwen models are available on NVIDIA NIM. Choosing the wrong one means sacrificing quality, speed, or both. Need a clear ranking based on coding benchmarks and architecture.

## Solution

### Ranking (best to worst for coding)

| Rank | Model | Active Params | Why |
|---|---|---|---|
| 1 | **Qwen3.5-397B-A17B** | 17B | Flagship — best SWE-Bench, LiveCodeBench, multimodal, same modern MoE architecture as 122B but bigger |
| 2 | **Qwen3.5-122B-A10B** | 10B | Best value — nearly matches 397B on coding, much faster/cheaper, multimodal |
| 3 | **Qwen3-Coder-480B-A35B** | 35B | Old dedicated coder — 3.5 family surpassed it despite having more active params. Not multimodal |
| 4 | **Qwen2.5-Coder-32B** | 32B (dense) | Outdated — skip entirely |

### Key Insight

The **Qwen3.5 family** (Feb 2026) with MoE + Hybrid Attention (Gated DeltaNet) architecture outperforms the older **Qwen3-Coder-480B** (Jul 2025) on most coding benchmarks, despite having fewer active parameters. The 3.5 models are also multimodal (vision + text). The 480B coder's advantage was agentic/repo-scale coding (SWE-Bench Pro SEAL), but the 3.5 models now match or exceed it even there.

### Benchmark Scores (approximate)

| Benchmark | 3.5-397B | 3.5-122B | Coder-480B |
|---|---|---|---|
| SWE-Bench Verified | ~72-75% | 66-72% | 67-70% |
| LiveCodeBench | ~80% | ~79% | ~62% |
| SciCode | — | 42% | 36% |
| Terminal-Bench Hard | — | 31% | 19% |

## When to Use

- Picking a Qwen model for a coding task on NVIDIA NIM
- Defaulting to Qwen3.5-397B for best quality, Qwen3.5-122B for best speed/quality tradeoff
- Avoiding Qwen2.5-Coder-32B and Qwen3-Coder-480B unless specific needs warrant them
