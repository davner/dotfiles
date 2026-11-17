#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FU="$DIR/.github/flake-update-pr.sh"
BRANCH=flake-update
RUN_URL="https://github.com/o/r/actions/runs/1"

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=bot GIT_AUTHOR_EMAIL=bot@example.com
export GIT_COMMITTER_NAME=bot GIT_COMMITTER_EMAIL=bot@example.com

FAKE="$WORK/fake"
mkdir -p "$FAKE/bin"
cat >"$FAKE/bin/gh" <<'EOF'
#!/usr/bin/env bash
root="$(dirname "$0")/.."
printf '%s\n' "$*" >>"$root/calls"
canned="$root/canned/$1-$2"
[ -f "$canned" ] || exit 0
filter=""
while [ $# -gt 0 ]; do
  case "$1" in --jq | -q) filter="$2"; shift 2 ;; *) shift ;; esac
done
if [ -n "$filter" ]; then jq -r "$filter" "$canned"; else cat "$canned"; fi
EOF
chmod +x "$FAKE/bin/gh"

ORIGIN="$WORK/origin.git"
CLONE="$WORK/clone"
fixture() { # -> a bare origin with main, and a single-branch clone of it whose lock moved
  rm -rf "$ORIGIN" "$CLONE" "$WORK/seed" "$FAKE/canned" "$FAKE/calls"
  mkdir -p "$FAKE/canned"
  printf '%s\n' '[]' >"$FAKE/canned/pr-list"
  git init -q --bare -b main "$ORIGIN"
  git init -q -b main "$WORK/seed"
  echo '{"lock":1}' >"$WORK/seed/flake.lock"
  git -C "$WORK/seed" add flake.lock
  git -C "$WORK/seed" commit -q -m "chore: seed"
  git -C "$WORK/seed" push -q "$ORIGIN" HEAD:main
  # actions/checkout fetches only the ref it checks out.
  git clone -q --single-branch --branch main "$ORIGIN" "$CLONE"
  echo '{"lock":2}' >"$CLONE/flake.lock"
}
fu_run() { # -> sets OUT, RC, CALLS after running the script in the clone
  rm -f "$FAKE/calls"
  RC=0
  OUT="$(cd "$CLONE" && PATH="${FU_PATH-}$FAKE/bin:$PATH" "$FU" "$BRANCH" "$RUN_URL" 2>&1 </dev/null)" || RC=$?
  CALLS="$(cat "$FAKE/calls" 2>/dev/null)"
}
remote_lock() { git -C "$ORIGIN" show "$BRANCH:flake.lock" 2>/dev/null; }
called() { # name, extended regex -> ok when a recorded gh call matches
  if grep -Eq -- "$2" <<<"$CALLS"; then ok "$1"; else bad "$1" "no gh call matches: $2" "calls: ${CALLS//$'\n'/ | }" "out: $OUT"; fi
}

section "no flake-update branch on origin"
if require jq; then
  fixture
  fu_run
  want_exit "the script succeeds" 0 "$RC"
  eq "the branch on origin carries the moved lock" '{"lock":2}' "$(remote_lock)"
  called "a PR is opened with the dependencies label" "^pr create .*--label dependencies"
  called "squash auto-merge is armed" "^pr merge $BRANCH --auto --squash$"
  called "test.yml is started on the branch" "^workflow run test.yml --ref $BRANCH$"
  eq "the commit message is one Conventional Commit subject line" \
    "chore(deps): nix flake update" "$(git -C "$ORIGIN" log -1 --format=%B "$BRANCH" | sed '/^$/d')"
fi

section "flake-update branch and its PR already open"
if require jq; then
  fixture
  git -C "$WORK/seed" switch -q -c stale
  echo '{"lock":"last week"}' >"$WORK/seed/flake.lock"
  git -C "$WORK/seed" commit -q -am "chore(deps): nix flake update"
  git -C "$WORK/seed" push -q "$ORIGIN" "stale:$BRANCH"
  printf '%s\n' '[{"number":7}]' >"$FAKE/canned/pr-list"
  fu_run
  want_exit "the script succeeds" 0 "$RC"
  eq "the branch on origin carries this run's lock" '{"lock":2}' "$(remote_lock)"
  eq "the branch is rebuilt on main, not on last week's commit" \
    "$(git -C "$ORIGIN" rev-parse main)" "$(git -C "$ORIGIN" rev-parse "$BRANCH^")"
  if grep -q '^pr create' <<<"$CALLS"; then bad "no second PR is opened" "calls: ${CALLS//$'\n'/ | }"; else ok "no second PR is opened"; fi
  called "squash auto-merge is armed" "^pr merge $BRANCH --auto --squash$"
  called "test.yml is started on the branch" "^workflow run test.yml --ref $BRANCH$"
fi

section "the remote branch moves after the script read it"
if require jq; then
  fixture
  git -C "$WORK/seed" switch -q -c handfix
  echo '{"lock":"hand fix"}' >"$WORK/seed/flake.lock"
  git -C "$WORK/seed" commit -q -am "fix: pin an input by hand"
  # Lands the hand fix on origin just before the script's push, after its ls-remote.
  REAL_GIT="$(command -v git)"
  mkdir -p "$WORK/racer"
  cat >"$WORK/racer/git" <<RACER
#!/usr/bin/env bash
[ "\$1" != push ] || "$REAL_GIT" -C "$WORK/seed" push -q "$ORIGIN" "handfix:$BRANCH"
exec "$REAL_GIT" "\$@"
RACER
  chmod +x "$WORK/racer/git"
  FU_PATH="$WORK/racer:" fu_run
  if [ "$RC" -ne 0 ]; then ok "the script fails"; else bad "the script fails" "out: $OUT"; fi
  eq "the hand fix stays on origin" '{"lock":"hand fix"}' "$(remote_lock)"
  eq "no gh call follows the refused push" "" "$CALLS"
fi

finish
