#!/usr/bin/env bash
# Names a Claude Code session after the repo it is running in, so remote
# control lists "nedkit" and "dotfiles" rather than three rows of whatever the
# first prompt happened to say.
#
#   dotfiles          the only session in this repo
#   dotfiles-2        a second one, opened while the first is still running
#
# Two callers, one answer:
#
#   session-name.sh [dir]     prints the name. The cc function passes it to
#                             claude --name at launch.
#   session-name.sh --hook    reads a SessionStart payload on stdin and prints
#                             the JSON that sets the session title, for sessions
#                             started as plain `claude`. Documented at
#                             https://code.claude.com/docs/en/hooks.
#
# The number is a slot rather than a count. Claude Code keeps a file per running
# session under ~/.claude/sessions/, carrying its pid, its directory and its
# name, so which numbers are in use is a question about live processes rather
# than something this script has to remember. Close the second session and the
# next one to open takes its number back.
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
# session asking the question. It is in the registry too by this point, and it
# is the one entry that must not count against itself.
self=""
[ -n "$hook" ] && self="$PPID"

# A pid still running under a name containing "claude" is a session still
# holding its number. Checking the name as well as the pid keeps a recycled pid
# from holding one for a session that ended.
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

name="$base"
n=1
while printf '%s' "$taken" | grep -qxF "$name"; do
  n=$((n + 1))
  name="$base-$n"
  [ "$n" -lt 100 ] || break
done

if [ -n "$hook" ]; then
  jq -n --arg name "$name" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", sessionTitle: $name}}'
else
  printf '%s\n' "$name"
fi
