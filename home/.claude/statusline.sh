#!/usr/bin/env bash
# The Claude Code status line: model, context window, and how much of the
# 5-hour and weekly rate limits is gone.
#
#   Opus 5 · ctx 8% · 5h 24% (2h00m) · wk 41% (3d)
#
# Claude Code pipes one JSON object in on stdin; the fields are documented at
# https://code.claude.com/docs/en/statusline. Almost all of them are optional:
# rate_limits appears only on a claude.ai subscription and only after the
# session's first API response, either window can be absent on its own, and the
# context percentages are null until the first API call and again after
# /compact. So every segment is printed only once its value has shown up, and
# the line degrades to just the model name.
#
# There is no per-model breakdown in this payload. It carries the current
# model and two account-wide windows, nothing per model, so a Fable-versus-Opus
# split is not something a status line can show. /usage has that.
set -uo pipefail # no -e: a status line that exits early renders as nothing

command -v jq >/dev/null 2>&1 || exit 0

# \x1f rather than a tab: bash collapses runs of whitespace when splitting, so
# one absent middle value would silently shift every later field.
SEP=$'\x1f'
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
