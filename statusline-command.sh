#!/usr/bin/env bash
# Claude Code statusline — "usage meters" style
#   <Model> | Context NN% | Session NN% (HH:MM) | Week NN% (Ddd HH:MM) | Tokens: N.NNM ($N.NN)
#   Context: amber >=40%, red + KOMPAKTUUUUUUUJ >=50%
#
# Data sources (from the JSON piped in on stdin — see Claude Code statusline docs):
#   .model.display_name                        -> model name
#   .context_window.used_percentage             -> "Context"
#   .rate_limits.five_hour.used_percentage       -> "Session" (5h subscription window)
#   .rate_limits.five_hour.resets_at             -> "(HH:MM)" reset time after Session
#   .rate_limits.seven_day.used_percentage       -> "Week" (7d subscription window)
#   .rate_limits.seven_day.resets_at             -> "(Ddd HH:MM)" reset day/time after Week
#   .context_window.total_input_tokens/total_output_tokens -> cumulative session tokens
#   .cost.total_cost_usd                         -> "($N.NN)" after tokens
#
# The cost is computed by Claude Code itself at API list prices; on a
# subscription it is an API-equivalent estimate, not an actual bill.
# rate_limits.* segments are only present for Claude.ai subscribers after the
# first API response of the session; they're simply omitted otherwise.
#
# Performance: one jq call parses everything (incl. reset time formatting);
# the rest is bash builtins, so each refresh spawns a single child process.

export LC_ALL=C  # printf %.Nf must parse/print a dot, whatever the system locale
input=$(cat)

eval "$(printf '%s' "$input" | jq -r '
  @sh "model=\(.model.display_name // "Claude")",
  @sh "ctx_used=\(.context_window.used_percentage // "")",
  @sh "five_pct=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "five_reset=\(.rate_limits.five_hour.resets_at // empty
        | if type == "number" then . else (sub("\\.[0-9]+"; "") | fromdateiso8601? // empty) end
        | floor | localtime | strftime("%H:%M"))",
  @sh "week_pct=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "week_reset=\(.rate_limits.seven_day.resets_at // empty
        | if type == "number" then . else (sub("\\.[0-9]+"; "") | fromdateiso8601? // empty) end
        | floor | localtime | strftime("%a %H:%M"))",
  @sh "total_tok=\((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))",
  @sh "cost=\(.cost.total_cost_usd // "")"
' 2>/dev/null)"

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

segments=("${BOLD}${model:-Claude}${RESET}")

if [ -n "$ctx_used" ]; then
  ctx_seg="Context $(render_pct "$ctx_used" "$CTX_WARN" "$CTX_CRIT" "$AMBER")"
  [ "$(printf '%.0f' "$ctx_used")" -ge "$CTX_CRIT" ] && ctx_seg+=" ${BOLD}${RED}KOMPAKTUUUUUUUJ${RESET}"
  segments+=("$ctx_seg")
fi
if [ -n "$five_pct" ]; then
  five_seg="Session $(render_pct "$five_pct" 50 80)"
  [ -n "$five_reset" ] && five_seg+=" ${DIM}(${five_reset})${RESET}"
  segments+=("$five_seg")
fi
if [ -n "$week_pct" ]; then
  week_seg="Week $(render_pct "$week_pct" 50 80)"
  [ -n "$week_reset" ] && week_seg+=" ${DIM}(${week_reset})${RESET}"
  segments+=("$week_seg")
fi

if [ "${total_tok:-0}" -gt 0 ]; then
  tok_seg="Tokens: $(printf '%d.%02d' $(( total_tok / 1000000 )) $(( total_tok % 1000000 / 10000 )))M"
  [ -n "$cost" ] && tok_seg+=" ($(printf '$%.2f' "$cost"))"
  segments+=("${DIM}${tok_seg}${RESET}")
fi

out=""
for seg in "${segments[@]}"; do
  if [ -z "$out" ]; then out="$seg"; else out="$out │ $seg"; fi
done

printf '%b\n' "$out"
