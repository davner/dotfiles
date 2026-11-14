#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "a test run leaves the caller's repo alone"
# git exports GIT_DIR to `rebase --exec` in a linked worktree, and a pre-commit
# hook inherits it too; a module that makes fixture commits then writes them
# into whatever repo is running the suite.
probe="$WORK/probe"
git init -q "$probe"
git -C "$probe" -c user.name=t -c user.email=t@t commit -q --allow-empty -m probe
before="$(git -C "$probe" rev-parse HEAD)"
GIT_DIR="$probe/.git" GIT_WORK_TREE="$probe" TEST_RESULT="" \
  bash "$DIR/tests/provenance.sh" >/dev/null 2>&1
eq "the caller's HEAD stays put" "$before" "$(git -C "$probe" rev-parse HEAD)"
eq "the caller's index stays empty" "" "$(git -C "$probe" diff --cached --name-only)"
eq "the caller stays a non-bare repo" "false" "$(git -C "$probe" config core.bare)"

finish
