#!/usr/bin/env bash
# The Claude Code status line. Almost every field of its stdin payload is
# optional: https://code.claude.com/docs/en/statusline
set -uo pipefail # no -e: a status line that exits early renders as nothing

command -v jq >/dev/null 2>&1 || exit 0

# \x1f rather than a tab: bash collapses runs of whitespace when splitting, so
# one absent middle value would silently shift every later field.
SEP=$'\x1f'
# Two account-wide windows and nothing per model, so a per-model split is not
# something a status line can show; /usage has that.
IFS="$SEP" read -r model ctx five five_at seven seven_at fast <<EOF
$(jq -r --arg sep "$SEP" '
  def pct: if . == null then "" else (round | tostring) end;
  [ .model.display_name // "?",
    (.context_window.used_percentage | pct),
    (.rate_limits.five_hour.used_percentage | pct),
    (.rate_limits.five_hour.resets_at // "" | tostring),
    (.rate_limits.seven_day.used_percentage | pct),
    (.rate_limits.seven_day.resets_at // "" | tostring),
    (if .fast_mode then "fast" else "" end)
  ] | join($sep)' 2>/dev/null)
EOF
[ -n "${model:-}" ] || exit 0

DIM=$'\033[2m'
RESET=$'\033[0m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'

tint() { # percentage -> the colour to print it in
  if [ "$1" -ge 80 ]; then
    printf '%s' "$RED"
  elif [ "$1" -ge 50 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

left_until() { # epoch seconds -> "2h05m", "3d", or nothing if it has passed
  local left=$(($1 - $(date +%s)))
  [ "$left" -gt 0 ] || return 0
  if [ "$left" -ge 86400 ]; then
    printf '%dd' "$((left / 86400))"
  elif [ "$left" -ge 3600 ]; then
    printf '%dh%02dm' "$((left / 3600))" "$((left % 3600 / 60))"
  else
    printf '%dm' "$((left / 60))"
  fi
}

segment() { # label, percentage, reset epoch (may be empty)
  local when=""
  [ -n "$3" ] && when="$(left_until "$3")"
  [ -n "$when" ] && when=" ${DIM}($when)${RESET}"
  printf '%s%s%s %s%s%%%s%s' "$DIM" "$1" "$RESET" "$(tint "$2")" "$2" "$RESET" "$when"
}

line="$model"
[ -n "$fast" ] && line="$line ${DIM}fast${RESET}"
[ -n "$ctx" ] && line="$line ${DIM}·${RESET} $(segment ctx "$ctx" "")"
[ -n "$five" ] && line="$line ${DIM}·${RESET} $(segment 5h "$five" "$five_at")"
[ -n "$seven" ] && line="$line ${DIM}·${RESET} $(segment wk "$seven" "$seven_at")"

printf '%s\n' "$line"
