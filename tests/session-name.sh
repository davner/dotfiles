#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "session name"
# Called bare by the cc function and with --hook by Claude Code. A throwaway
# $HOME holds a fabricated registry, so real open sessions never change the answer.
SN="$DIR/home/.claude/hooks/session-name.sh"
fixture_sthome
REPO="$WORK/repos/myrepo"
OTHER="$WORK/repos/elsewhere"
mkdir -p "$REPO/src/deep" "$OTHER" "$WORK/loose dir"
git -C "$REPO" init -q 2>/dev/null
git -C "$OTHER" init -q 2>/dev/null

name_in() { # cwd -> the name cc would pass to claude --name
  HOME="$STHOME" "$SN" "$1" 2>/dev/null
}
peer() { # pid, cwd, name -> a registry entry for a session that is running
  printf '{"pid":%s,"cwd":"%s","name":"%s"}' "$1" "$2" "$3" \
    >"$STHOME/.claude/sessions/$1.json"
}

if require jq; then
  eq "a session in a repo is named after it" "myrepo" "$(name_in "$REPO")"
  eq "a session below the root is named after the root too" \
    "myrepo" "$(name_in "$REPO/src/deep")"
  eq "outside a repo it falls back to the directory" \
    "loose dir" "$(name_in "$WORK/loose dir")"

  # A live pid named like claude holds its number: ps reports the launch path, so
  # sleep via a symlink counts. A copy would die: its signature does not survive.
  mkdir -p "$WORK/fake"
  ln -sf /bin/sleep "$WORK/fake/claude"
  "$WORK/fake/claude" 120 &
  faker=$!
  peer "$faker" "$REPO" "myrepo"
  eq "a second session in the same repo is numbered" "myrepo-2" "$(name_in "$REPO")"
  "$WORK/fake/claude" 120 &
  faker2=$!
  peer "$faker2" "$REPO" "myrepo-2"
  eq "and a third one takes the next number" "myrepo-3" "$(name_in "$REPO")"
  kill "$faker2" 2>/dev/null
  wait "$faker2" 2>/dev/null
  rm -f "$STHOME/.claude/sessions/$faker2.json"

  peer 999999 "$REPO" "myrepo-9"
  eq "a session that has exited frees its number" "myrepo-2" "$(name_in "$REPO")"
  rm -f "$STHOME/.claude/sessions/999999.json"

  "$WORK/fake/claude" 120 &
  neighbour=$!
  peer "$neighbour" "$OTHER" "myrepo"
  eq "a live session in another repo does not take the number" \
    "myrepo-2" "$(name_in "$REPO")"
  kill "$neighbour" 2>/dev/null
  wait "$neighbour" 2>/dev/null

  kill "$faker" 2>/dev/null
  wait "$faker" 2>/dev/null
  eq "the number is freed when that session ends" "myrepo" "$(name_in "$REPO")"

  # --hook is the same answer wrapped in the JSON Claude Code reads back.
  sn_out="$(printf '{"cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$REPO" \
    | HOME="$STHOME" "$SN" --hook 2>/dev/null)"
  eq "--hook sets the session title to that name" "myrepo" \
    "$(printf '%s' "$sn_out" | jq -r '.hookSpecificOutput.sessionTitle // ""')"
  eq "--hook says which event it is answering" "SessionStart" \
    "$(printf '%s' "$sn_out" | jq -r '.hookSpecificOutput.hookEventName // ""')"

  sn_rc=0
  sn_out="$(printf 'not json at all' | HOME="$STHOME" "$SN" --hook 2>/dev/null)" || sn_rc=$?
  eq "garbage in exits 0" "0" "$sn_rc"
  if printf '%s' "$sn_out" | jq -e '.hookSpecificOutput.sessionTitle' >/dev/null 2>&1; then
    ok "garbage in still emits a title"
  else
    bad "garbage in still emits a title" "output was: $sn_out"
  fi
fi

finish
