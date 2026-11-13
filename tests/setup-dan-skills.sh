#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SDS="$DIR/home/.claude/skills/setup-dan-skills/scripts"

# --- repo settings (ticket 03): fake gh and helpers; ticket 05 merges them ---
section "repo settings"
RS="$SDS/repo-settings.sh"
if [ -x "$RS" ]; then ok "repo-settings.sh is executable"; else bad "repo-settings.sh is executable" "$RS"; fi
RS_STUB="$WORK/rs-stub"
mkdir -p "$RS_STUB"
# Records each call and answers `repo view` the way --jq would leave it. A call
# containing $RS_GH_FAIL fails with GitHub's kind of error text.
cat >"$RS_STUB/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$(dirname "$0")/gh-calls"
if [ -n "${RS_GH_FAIL-}" ] && [[ "$*" == *"$RS_GH_FAIL"* ]]; then
  echo "HTTP 403: Upgrade to GitHub Pro or make this repository public to enable this feature." >&2
  exit 1
fi
case "$1 $2" in
  "repo view") echo "davner/demo main" ;;
  api*) echo '{"url":"https://api.github.com/repos/davner/demo"}' ;;
esac
EOF
chmod +x "$RS_STUB/gh"
rs_run() { # args... -> sets RS_OUT, RS_ERR, RS_RC, RS_CALLS, RS_WRITES
  rm -f "$RS_STUB/gh-calls"
  RS_RC=0
  RS_OUT="$(PATH="$RS_STUB:$PATH" "$RS" "$@" 2>"$WORK/rs-stderr" </dev/null)" || RS_RC=$?
  RS_ERR="$(cat "$WORK/rs-stderr")"
  RS_CALLS="$(cat "$RS_STUB/gh-calls" 2>/dev/null)"
  RS_WRITES="$(grep -v '^repo view' "$RS_STUB/gh-calls" 2>/dev/null)"
}

rs_run --dry-run --check test
want_exit "a dry run exits 0" 0 "$RS_RC"
eq "a dry run makes no write call" "" "$RS_WRITES"
contains "a dry run prints the repo edit" "$RS_OUT" "gh repo edit davner/demo"
contains "a dry run prints the protection PUT" "$RS_OUT" \
  "gh api --method PUT repos/davner/demo/branches/main/protection"
contains "a dry run's PUT names the check" "$RS_OUT" "'required_status_checks[contexts][]=test'"

# The printout is what the user approves and may paste, so a check name with a
# quote in it must come back out of the shell unchanged.
rs_run --dry-run --check "it's ok"
put="$(printf '%s\n' "$RS_OUT" | grep -- '--method PUT')"
replayed="$(eval "set -- ${put#gh }" && printf '%s\n' "$@" | grep contexts)"
eq "a dry run's printout replays a quoted check name intact" \
  "required_status_checks[contexts][]=it's ok" "$replayed"

rs_run --check test --check 'towncrier check'
want_exit "a real run exits 0" 0 "$RS_RC"
eq "a real run makes the three writes, in order" "$(
  cat <<'CALLS'
repo edit davner/demo --enable-auto-merge --delete-branch-on-merge --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
api --method PATCH repos/davner/demo -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK
api --method PUT repos/davner/demo/branches/main/protection -F required_status_checks[strict]=true -f required_status_checks[contexts][]=test -f required_status_checks[contexts][]=towncrier check -F enforce_admins=false -F required_pull_request_reviews[required_approving_review_count]=0 -F restrictions=null -F required_linear_history=true -F allow_force_pushes=false -F allow_deletions=false
CALLS
)" "$RS_WRITES"
eq "a real run keeps GitHub's JSON replies off stdout" "" "$RS_OUT"

rs_run --dry-run
want_exit "no --check exits 2" 2 "$RS_RC"
contains "and says why" "$RS_ERR" "auto-merge with no required check merges untested work"
eq "and calls gh for nothing" "" "$RS_CALLS"
rs_run --check
want_exit "--check with no name exits 2" 2 "$RS_RC"

RS_GH_FAIL="--method PATCH" rs_run --check test
want_exit "a failing gh exits non-zero" 1 "$RS_RC"
contains "and GitHub's error reaches stderr" "$RS_ERR" "HTTP 403: Upgrade to GitHub Pro"
eq "and nothing after it runs" "2" "$(printf '%s\n' "$RS_WRITES" | wc -l | tr -d ' ')"

RS_GH_FAIL="repo view" rs_run --dry-run --check test
want_exit "a repo gh cannot read exits non-zero" 1 "$RS_RC"
eq "and prints no commands" "" "$RS_OUT"
# --- end repo settings ---

# ---- labels.sh: fake gh and helpers (ticket 01; ticket 05 merges the helpers) ----
section "label setup script"
LABELS="$DIR/home/.claude/skills/setup-dan-skills/scripts/labels.sh"
LGH="$WORK/labels-gh"
mkdir -p "$LGH/bin" "$LGH/repo"
# Logs every call, then replays canned/<subcommand>-<action>.json through --jq as
# real gh would. GH_FAIL names subcommands that fail, as "label-create".
cat >"$LGH/bin/gh" <<'EOF'
#!/usr/bin/env bash
root="$(dirname "$0")/.."
printf '%s\n' "$*" >>"$root/calls"
key="$1-$2"
case " ${GH_FAIL-} " in *" $key "*) echo "gh: $key failed" >&2; exit 1 ;; esac
json="$root/canned/$key.json"
[ -f "$json" ] || exit 0
filter=""
while [ $# -gt 0 ]; do
  case "$1" in --jq | -q) filter="$2"; shift 2 ;; *) shift ;; esac
done
if [ -n "$filter" ]; then jq -r "$filter" "$json"; else cat "$json"; fi
EOF
chmod +x "$LGH/bin/gh"

LABELS_DEFAULTS='["bug","documentation","duplicate","enhancement","good first issue","help wanted","invalid","question","wontfix"]'
labels_repo() { # label names as a JSON array -> a fake repo holding those labels, with nothing labelled
  rm -rf "$LGH/canned" "$LGH/calls"
  mkdir -p "$LGH/canned"
  echo '{"nameWithOwner":"owner/repo"}' >"$LGH/canned/repo-view.json"
  jq '[.[] | {name: .}]' <<<"$1" >"$LGH/canned/label-list.json"
  echo '[]' >"$LGH/canned/issue-list.json"
  echo '[]' >"$LGH/canned/pr-list.json"
}
labels_run() { # extra env assignments -> sets LABELS_RC, LABELS_OUT, LABELS_CALLS
  LABELS_RC=0
  LABELS_OUT="$(cd "$LGH/repo" && env PATH="$LGH/bin:$PATH" "$@" "$LABELS" 2>&1 </dev/null)" || LABELS_RC=$?
  LABELS_CALLS="$(cat "$LGH/calls" 2>/dev/null)"
}
labels_calls() { # gh subcommand and action -> the logged calls to it, one per line
  grep "^$1 $2 " <<<"$LABELS_CALLS"
}

LABELS_SET="breaking
chore
dependencies
docs
duplicate
feat
fix
needs-info
needs-triage
perf
ready-for-agent
ready-for-human
refactor
skip-changelog
test
todo
wontfix"

if require jq; then
  labels_repo "$LABELS_DEFAULTS"
  labels_run
  eq "a fresh repo: labels.sh exits 0" "0" "$LABELS_RC"
  eq "a fresh repo: every label in the set is created" "$LABELS_SET" \
    "$(labels_calls label create | awk '{print $3}' | sort)"
  eq "a fresh repo: every create is --force" "" \
    "$(labels_calls label create | grep -v -- '--force')"
  contains "a fresh repo: bug is renamed to fix" "$(labels_calls label edit)" "label edit bug -R owner/repo --name fix"
  eq "a fresh repo: the three overlapping defaults are renamed" "label edit bug -R owner/repo --name fix
label edit enhancement -R owner/repo --name feat
label edit documentation -R owner/repo --name docs" "$(labels_calls label edit)"
  eq "a fresh repo: the four unused defaults are deleted" "label delete good first issue -R owner/repo --yes
label delete help wanted -R owner/repo --yes
label delete question -R owner/repo --yes
label delete invalid -R owner/repo --yes" "$(labels_calls label delete)"
  eq "a fresh repo: each delete is checked against issues and PRs in every state" "8" \
    "$(grep -E '^(issue|pr) list .*--state all' <<<"$LABELS_CALLS" | wc -l | tr -d ' ')"

  labels_repo "$LABELS_DEFAULTS"
  echo '[{"number":7}]' >"$LGH/canned/issue-list.json"
  labels_run
  eq "a default an issue carries: labels.sh exits 0" "0" "$LABELS_RC"
  eq "a default an issue carries: it is kept" "" "$(labels_calls label delete)"
  contains "a default an issue carries: the kept label is reported" "$LABELS_OUT" "kept question: an issue or PR carries it"

  labels_repo "$LABELS_DEFAULTS"
  echo '[{"number":8}]' >"$LGH/canned/pr-list.json"
  labels_run
  eq "a default a PR carries: it is kept" "" "$(labels_calls label delete)"
fi
# ---- end labels.sh block ----

finish
