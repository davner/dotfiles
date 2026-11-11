#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "status line"
# Claude Code renders whatever this prints, so a crash costs the whole line, and
# the interesting cases are fields that have not arrived yet.
SL="$DIR/home/.claude/hooks/statusline.sh"
plain() { sed $'s/\x1b\\[[0-9;]*m//g'; }
NOW="$(date +%s)"

# Each window sits past its boundary on purpose: the script floors what is left
# after its own clock read, so an exact 3d renders as 2d once a second passes.
sl_out="$(printf '{"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":8},"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":%d},"seven_day":{"used_percentage":41.2,"resets_at":%d}}}' \
  "$((NOW + 7230))" "$((NOW + 259200 + 3600))" | "$SL" | plain)"
eq "a full payload renders every segment" \
  "Opus 5 · ctx 8% · 5h 24% (2h00m) · wk 41% (3d)" "$sl_out"

sl_out="$(printf '{"model":{"display_name":"Opus 5"},"fast_mode":true,"context_window":{"used_percentage":82},"rate_limits":{"five_hour":{"used_percentage":91,"resets_at":%d}}}' \
  "$((NOW + 900 + 30))" | "$SL")"
contains "a spent limit is coloured red" "$sl_out" $'\033[31m'
contains "fast mode is visible" "$(printf '%s' "$sl_out" | plain)" "fast"
contains "an absent weekly window is skipped, not blanked" \
  "$(printf '%s' "$sl_out" | plain)" "Opus 5 fast · ctx 82% · 5h 91% (15m)"

sl_out="$(printf '{"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":8}}' | "$SL" | plain)"
eq "no rate limits yet degrades to model and context" "Opus 5 · ctx 8%" "$sl_out"

sl_out="$(printf '{"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":null}}' | "$SL" | plain)"
eq "a null percentage degrades to the model alone" "Opus 5" "$sl_out"

sl_rc=0
sl_out="$(printf 'not json at all' | "$SL" 2>/dev/null)" || sl_rc=$?
eq "garbage in exits 0" "0" "$sl_rc"
eq "garbage in prints nothing" "" "$sl_out"

finish
