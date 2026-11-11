#!/usr/bin/env bash
# Names a Claude Code session after its repo, so remote control lists "dotfiles"
# rather than whatever the first prompt said.
set -uo pipefail # no -e: a hook that dies mid-way still has to print its JSON

command -v jq >/dev/null 2>&1 || exit 0

hook=""
[ "${1-}" = "--hook" ] && hook=1 && shift

if [ -n "$hook" ]; then
  cwd="$(jq -r '.cwd // empty' 2>/dev/null)"
else
  cwd="${1-}"
fi
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"

repo() { # directory -> its repo root, or the directory itself
  git -C "$1" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$1"
}

root="$(repo "$cwd")"
base="$(basename "$root")"
case "$base" in "" | / | .) exit 0 ;; esac

# The hook runs as a child of the claude process it is naming, so $PPID is the
# session asking - the one registry entry that must not count against itself.
self=""
[ -n "$hook" ] && self="$PPID"

# Checking the process name as well as the pid keeps a recycled pid from holding
# a number for a session that has ended.
taken=""
for f in "$HOME"/.claude/sessions/*.json; do
  [ -f "$f" ] || continue
  IFS=$'\t' read -r pid dir name < <(jq -r '[.pid, .cwd, .name // ""] | @tsv' "$f" 2>/dev/null)
  [ -n "${name:-}" ] || continue
  [ "$pid" != "$self" ] || continue
  [ "$pid" -gt 0 ] 2>/dev/null || continue
  kill -0 "$pid" 2>/dev/null || continue
  case "$(ps -o comm= -p "$pid" 2>/dev/null)" in *claude*) ;; *) continue ;; esac
  [ -d "$dir" ] && [ "$(repo "$dir")" = "$root" ] || continue
  taken="$taken$name"$'\n'
done

# The suffix is a slot rather than a count, so closing a session hands its
# number back to the next one that opens.
name="$base"
n=1
while printf '%s' "$taken" | grep -qxF "$name"; do
  n=$((n + 1))
  name="$base-$n"
  [ "$n" -lt 100 ] || break
done

if [ -n "$hook" ]; then
  # SessionStart output shape: https://code.claude.com/docs/en/hooks
  jq -n --arg name "$name" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", sessionTitle: $name}}'
else
  printf '%s\n' "$name"
fi
