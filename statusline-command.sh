#!/usr/bin/env bash
# Claude Code statusline — "usage meters" style
#   <Model> | Context NN% | Session NN% | Week NN% | Tokens: N.NNM
#   Context: amber >=40%, red + KOMPAKTUUUUUUUJ >=50%
#
# Data sources (from the JSON piped in on stdin — see Claude Code statusline docs):
#   .model.display_name                        -> model name
#   .context_window.used_percentage             -> "Context"
#   .rate_limits.five_hour.used_percentage       -> "Session" (5h subscription window)
#   .rate_limits.five_hour.resets_at             -> "(HH:MM)" reset time after Session
#   .rate_limits.seven_day.used_percentage       -> "Week" (7d subscription window)
#   .context_window.total_input_tokens/total_output_tokens -> cumulative session tokens
#
# NOTE: There is no per-session USD cost field available to statusLine scripts.
# The reference screenshot's "Session total: $2.86 (8.53M tokens)" cost figure
# can't be sourced (or reliably recomputed — token pricing varies by cache
# read/write tier and model) so this script shows the token count only, no $.
# rate_limits.* segments are only present for Claude.ai subscribers after the
# first API response of the session; they're simply omitted otherwise.

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
ctx_used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty | if type == "number" then . else (sub("\\.[0-9]+"; "") | fromdateiso8601? // empty) end')
week_pct=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
in_tok=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(printf '%s' "$input" | jq -r '.context_window.total_output_tokens // 0')

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
YELLOW='\033[33m'
AMBER='\033[38;5;214m'
RED='\033[31m'

# render_pct <percent> <warn> <crit> [warn_color] -> colorized "NN%"
render_pct() {
  local pct color
  pct=$(printf '%.0f' "$1")
  if [ "$pct" -lt "$2" ]; then color="$GREEN"
  elif [ "$pct" -lt "$3" ]; then color="${4:-$YELLOW}"
  else color="$RED"
  fi
  printf '%b%s%%%b' "$color" "$pct" "$RESET"
}

CTX_WARN=40
CTX_CRIT=50

segments=("${BOLD}${model}${RESET}")

if [ -n "$ctx_used" ]; then
  ctx_seg="Context $(render_pct "$ctx_used" "$CTX_WARN" "$CTX_CRIT" "$AMBER")"
  [ "$(printf '%.0f' "$ctx_used")" -ge "$CTX_CRIT" ] && ctx_seg+=" ${BOLD}${RED}KOMPAKTUUUUUUUJ${RESET}"
  segments+=("$ctx_seg")
fi
if [ -n "$five_pct" ]; then
  five_seg="Session $(render_pct "$five_pct" 50 80)"
  [ -n "$five_reset" ] && five_seg+=" ${DIM}($(date -r "${five_reset%.*}" +%H:%M))${RESET}"
  segments+=("$five_seg")
fi
[ -n "$week_pct" ] && segments+=("Week $(render_pct "$week_pct" 50 80)")

total_tok=$(( in_tok + out_tok ))
if [ "$total_tok" -gt 0 ]; then
  tok_m=$(awk -v t="$total_tok" 'BEGIN { printf "%.2f", t / 1000000 }')
  segments+=("${DIM}Tokens: ${tok_m}M${RESET}")
fi

out=""
for seg in "${segments[@]}"; do
  if [ -z "$out" ]; then out="$seg"; else out="$out │ $seg"; fi
done

printf '%b\n' "$out"
