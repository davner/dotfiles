#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "pr provenance check"
# The pr page shows this script's verdict as proof of authorship, so a false
# CLEAN is the one outcome that must never happen.
PROV="$DIR/home/.claude/skills/pr/scripts/provenance.sh"
PREPO="$WORK/prov"
git init -q "$PREPO"
pv_commit() { # message, [author name], [author email] -> new HEAD
  local tree
  tree=$(git -C "$PREPO" mktree </dev/null)
  local parent=()
  git -C "$PREPO" rev-parse -q --verify HEAD >/dev/null && parent=(-p HEAD)
  GIT_AUTHOR_NAME="${2:-Dan}" GIT_AUTHOR_EMAIL="${3:-d@example.com}" \
    GIT_COMMITTER_NAME=Dan GIT_COMMITTER_EMAIL=d@example.com \
    git -C "$PREPO" commit-tree "$tree" ${parent[@]+"${parent[@]}"} -m "$1" |
    xargs git -C "$PREPO" update-ref HEAD
}
pv() { (cd "$PREPO" && "$PROV" "$@" >/dev/null 2>&1); echo $?; }
pv_commit "chore: base"
pv_base=$(git -C "$PREPO" rev-parse HEAD)
pv_commit "feat: one"
eq "a human-only range is clean" 0 "$(pv "$pv_base")"
eq "an empty range is unverified, not clean" 2 "$(pv HEAD)"
eq "a missing body is unverified, not clean" 2 "$(pv "$pv_base" --body "$WORK/none.md")"
printf 'Fixes it.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n' >"$WORK/body.md"
eq "a body with the harness footer is flagged" 1 "$(pv "$pv_base" --body "$WORK/body.md")"
pv_commit "docs: say why claude reads this" Dan
eq "prose naming a model is not a credit" 0 "$(pv "$pv_base")"
pv_commit "fix: two

Co-Authored-By: Opus 5 <noreply@anthropic.com>"
eq "a co-author trailer with a vendor domain is flagged" 1 "$(pv "$pv_base")"
pv_base=$(git -C "$PREPO" rev-parse HEAD)
pv_commit "chore: bump" "dependabot[bot]" "49699333+dependabot[bot]@users.noreply.github.com"
eq "a bot author is flagged" 1 "$(pv "$pv_base")"
pv_base=$(git -C "$PREPO" rev-parse HEAD)
pv_commit "feat: three" Claude claude@anthropic.com
eq "an AI author is flagged" 1 "$(pv "$pv_base")"
# A copy with no ai-credit.sh beside it or in ~/.claude has nothing to judge by.
mkdir -p "$WORK/prov-lone" "$WORK/prov-home"
cp "$PROV" "$WORK/prov-lone/provenance.sh"
eq "a missing ai-credit.sh is unverified, not clean" 2 \
  "$(cd "$PREPO" && HOME="$WORK/prov-home" "$WORK/prov-lone/provenance.sh" "$pv_base" >/dev/null 2>&1; echo $?)"

finish
