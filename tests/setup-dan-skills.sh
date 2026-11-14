#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SDS="$DIR/home/.claude/skills/setup-dan-skills/scripts"

# The fake gh replays canned answers through jq, as real gh's --jq does.
require jq || finish

# --- one fake gh for every script ---
GH="$WORK/gh"
mkdir -p "$GH/bin" "$GH/repo"
# A failing call is logged first, so a test can see it was the last one made.
cat >"$GH/bin/gh" <<'EOF'
#!/usr/bin/env bash
root="$(dirname "$0")/.."
args="$*"
args="${args//$'\n'/ }"
printf '%s\n' "$args" >>"$root/calls"
if [ -n "${GH_FAIL-}" ] && [[ $args == *"$GH_FAIL"* ]]; then
  echo "HTTP 403: Upgrade to GitHub Pro or make this repository public to enable this feature." >&2
  exit 1
fi
canned="$root/canned/$1-$2"
[ -f "$canned" ] || canned="$root/canned/$1"
[ -f "$canned" ] || exit 0
filter=""
while [ $# -gt 0 ]; do
  case "$1" in --jq | -q) filter="$2"; shift 2 ;; *) shift ;; esac
done
if [ -n "$filter" ]; then jq -r "$filter" "$canned"; else cat "$canned"; fi
EOF
chmod +x "$GH/bin/gh"

gh_reset() { # forget every canned answer and call
  rm -rf "$GH/canned" "$GH/calls"
  mkdir -p "$GH/canned"
}
gh_can() { # subcommand-action, answer -> gh answers that call with it
  printf '%s\n' "$2" >"$GH/canned/$1"
}
gh_run() { # script, args... -> sets OUT, ERR, RC, CALLS; GH_FAIL in the env makes matching calls fail
  rm -f "$GH/calls"
  RC=0
  OUT="$(cd "$GH/repo" && PATH="$GH/bin:$PATH" "$@" 2>"$WORK/gh-stderr" </dev/null)" || RC=$?
  ERR="$(cat "$WORK/gh-stderr")"
  CALLS="$(cat "$GH/calls" 2>/dev/null)"
}
calls_to() { # subcommand, action -> the logged calls to it, one per line
  grep "^$1 $2 " <<<"$CALLS"
}
called() { # name, pattern -> ok when a logged call matches the extended regex
  if grep -Eq -- "$2" <<<"$CALLS"; then ok "$1"; else bad "$1" "no gh call matches: $2" "calls: ${CALLS//$'\n'/ | }"; fi
}
not_called() { # name, pattern -> ok when no logged call matches the extended regex
  if grep -Eq -- "$2" <<<"$CALLS"; then bad "$1" "a gh call matches: $2" "calls: ${CALLS//$'\n'/ | }"; else ok "$1"; fi
}
executable() { # script name -> ok when the skill can run it by path
  if [ -x "$SDS/$1" ]; then ok "$1 is executable"; else bad "$1 is executable" "the skill runs it by path"; fi
}

# --- repo settings ---
section "repo settings"
RS="$SDS/repo-settings.sh"
executable repo-settings.sh
gh_reset
gh_can repo-view '{"nameWithOwner":"davner/demo","defaultBranchRef":{"name":"main"}}'
gh_can api '{"url":"https://api.github.com/repos/davner/demo"}'
writes() { grep -v '^repo view' <<<"$CALLS"; }

gh_run "$RS" --dry-run --check test
want_exit "a dry run exits 0" 0 "$RC"
eq "a dry run makes no write call" "" "$(writes)"
contains "a dry run prints the repo edit" "$OUT" "gh repo edit davner/demo"
contains "a dry run prints the protection PUT" "$OUT" \
  "gh api --method PUT repos/davner/demo/branches/main/protection"
contains "a dry run's PUT names the check" "$OUT" "'required_status_checks[contexts][]=test'"

# The printout is what the user approves and may paste, so a check name with a
# quote in it must come back out of the shell unchanged.
gh_run "$RS" --dry-run --check "it's ok"
put="$(printf '%s\n' "$OUT" | grep -- '--method PUT')"
replayed="$(eval "set -- ${put#gh }" && printf '%s\n' "$@" | grep contexts)"
eq "a dry run's printout replays a quoted check name intact" \
  "required_status_checks[contexts][]=it's ok" "$replayed"

gh_run "$RS" --check test --check 'towncrier check'
want_exit "a real run exits 0" 0 "$RC"
eq "a real run makes the three writes, in order" "$(
  cat <<'CALLS'
repo edit davner/demo --enable-auto-merge --delete-branch-on-merge --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
api --method PATCH repos/davner/demo -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK
api --method PUT repos/davner/demo/branches/main/protection -F required_status_checks[strict]=true -f required_status_checks[contexts][]=test -f required_status_checks[contexts][]=towncrier check -F enforce_admins=false -F required_pull_request_reviews[required_approving_review_count]=0 -F restrictions=null -F required_linear_history=true -F allow_force_pushes=false -F allow_deletions=false
CALLS
)" "$(writes)"
eq "a real run keeps GitHub's JSON replies off stdout" "" "$OUT"

gh_run "$RS" --dry-run
want_exit "no --check exits 2" 2 "$RC"
contains "and says why" "$ERR" "auto-merge with no required check merges untested work"
eq "and calls gh for nothing" "" "$CALLS"
gh_run "$RS" --check
want_exit "--check with no name exits 2" 2 "$RC"

GH_FAIL="--method PATCH" gh_run "$RS" --check test
want_exit "a failing gh exits non-zero" 1 "$RC"
contains "and GitHub's error reaches stderr" "$ERR" "HTTP 403: Upgrade to GitHub Pro"
eq "and nothing after it runs" "2" "$(writes | wc -l | tr -d ' ')"

GH_FAIL="repo view" gh_run "$RS" --dry-run --check test
want_exit "a repo gh cannot read exits non-zero" 1 "$RC"
eq "and prints no commands" "" "$OUT"

# --- labels ---
section "label setup script"
LABELS="$SDS/labels.sh"
LABELS_DEFAULTS='["bug","documentation","duplicate","enhancement","good first issue","help wanted","invalid","question","wontfix"]'
labels_repo() { # label names as a JSON array -> a fake repo holding those labels, with nothing labelled
  gh_reset
  gh_can repo-view '{"nameWithOwner":"owner/repo"}'
  gh_can label-list "$(jq '[.[] | {name: .}]' <<<"$1")"
  gh_can issue-list '[]'
  gh_can pr-list '[]'
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

labels_repo "$LABELS_DEFAULTS"
gh_run "$LABELS"
eq "a fresh repo: labels.sh exits 0" "0" "$RC"
eq "a fresh repo: every label in the set is created" "$LABELS_SET" \
  "$(calls_to label create | awk '{print $3}' | sort)"
eq "a fresh repo: every create is --force" "" \
  "$(calls_to label create | grep -v -- '--force')"
contains "a fresh repo: bug is renamed to fix" "$(calls_to label edit)" "label edit bug -R owner/repo --name fix"
eq "a fresh repo: the three overlapping defaults are renamed" "label edit bug -R owner/repo --name fix
label edit enhancement -R owner/repo --name feat
label edit documentation -R owner/repo --name docs" "$(calls_to label edit)"
eq "a fresh repo: the four unused defaults are deleted" "label delete good first issue -R owner/repo --yes
label delete help wanted -R owner/repo --yes
label delete question -R owner/repo --yes
label delete invalid -R owner/repo --yes" "$(calls_to label delete)"
eq "a fresh repo: each delete is checked against issues and PRs in every state" "8" \
  "$(grep -cE '^(issue|pr) list .*--state all' <<<"$CALLS")"

labels_repo "$LABELS_DEFAULTS"
gh_can issue-list '[{"number":7}]'
gh_run "$LABELS"
eq "a default an issue carries: labels.sh exits 0" "0" "$RC"
eq "a default an issue carries: it is kept" "" "$(calls_to label delete)"
contains "a default an issue carries: the kept label is reported" "$OUT" "kept question: an issue or PR carries it"

labels_repo "$LABELS_DEFAULTS"
gh_can pr-list '[{"number":8}]'
gh_run "$LABELS"
eq "a default a PR carries: it is kept" "" "$(calls_to label delete)"

labels_repo "$(jq -R . <<<"$LABELS_SET" | jq -s .)"
gh_run "$LABELS"
eq "a re-run: labels.sh exits 0" "0" "$RC"
eq "a re-run: nothing is renamed" "" "$(calls_to label edit)"
eq "a re-run: nothing is deleted" "" "$(calls_to label delete)"
eq "a re-run: the set is written again with --force" "17" \
  "$(calls_to label create | grep -c -- '--force')"

labels_repo '["bug","fix"]'
gh_run "$LABELS"
eq "bug beside an existing fix: bug is not renamed" "" "$(calls_to label edit)"
contains "bug beside an existing fix: it is reported" "$OUT" "kept bug: fix already exists"

missing=""
while read -r name; do
  grep -Fq -- "\`$name\`" "$SDS/../issue-tracker-github.md" || missing+=" $name"
done <<<"$LABELS_SET"
eq "the GitHub tracker template names every label in the set" "" "$missing"

for failing in "repo view" "label list" "label edit" "issue list" "pr list" "label delete" "label create"; do
  labels_repo "$LABELS_DEFAULTS"
  GH_FAIL="$failing" gh_run "$LABELS"
  want_exit "a failing gh $failing stops labels.sh non-zero" 1 "$RC"
  eq "a failing gh $failing is the last call made" "$failing" \
    "$(tail -n 1 <<<"$CALLS" | awk '{print $1, $2}')"
done

# --- board ---
section "setup-dan-skills board"
BOARD="$SDS/board.sh"
gh_reset
gh_can repo-view '{"nameWithOwner":"me/app"}'
gh_can project-create '{"number":7,"id":"PVT_t","title":"dan-skills template","url":"https://github.com/users/me/projects/7"}'
gh_can project-copy '{"number":8,"id":"PVT_b","title":"me/app","url":"https://github.com/users/me/projects/8"}'
gh_can project-field-list '{"fields":[{"id":"PVTF_title","name":"Title","type":"ProjectV2Field"},{"id":"PVTSSF_status","name":"Status","type":"ProjectV2SingleSelectField","options":[{"id":"a","name":"Todo"},{"id":"b","name":"In Progress"},{"id":"c","name":"Done"}]}],"totalCount":2}'
gh_can api '{"data":{}}'
board_scopes() { # scope list as gh prints it -> gh auth status reports those scopes
  gh_can auth-status "$(printf 'github.com\n  - Token scopes: %s' "$1")"
}
board_run() { # each existing project as number=title... -> runs board.sh, as gh_run
  gh_can project-list "$(printf '%s\n' "$@" | jq -R -s '{projects: [split("\n")[] | select(. != "") | split("=") |
    {number: (.[0] | tonumber), title: .[1], url: "https://github.com/users/me/projects/\(.[0])"}], totalCount: 0}')"
  gh_run "$BOARD"
}
board_scopes "'gist', 'project', 'read:org', 'repo'"

board_run
want_exit "with no projects, board.sh exits 0" 0 "$RC"
called "it creates the template" '^project create .*--title dan-skills template'
called "it copies the template to the repo's title" '^project copy 7 .*--title me/app'
called "it links the board to the repo" '^project link 8 '
contains "it prints the board number" "$OUT" $'\nboard=8\n'
called "it replaces the Status field of the new template" '^api graphql .*fieldId=PVTSSF_status'
called "with Backlog, Ready, In progress, In review, Done in order" \
  '^api graphql .*updateProjectV2Field.*"Backlog".*"Ready".*"In progress".*"In review".*"Done"'
# GitHub has templates for organizations only, and copy works on any project.
not_called "it leaves the template unmarked" '^project mark-template'
contains "it prints the template's workflows page" "$OUT" $'\nhttps://github.com/users/me/projects/7/workflows\n'
for wf in "Item closed: set Status to Done" "Pull request merged: set Status to Done" \
  "Auto-close issue: on" "Auto-archive items: Done items after 14 days" "Item added to project: set Status to Backlog"; do
  contains "it lists the template workflow '$wf'" "$OUT" "$wf"
done
contains "it prints the board's workflows page" "$OUT" $'\nhttps://github.com/users/me/projects/8/workflows'
contains "it prints the auto-add filter" "$OUT" "is:issue is:open"

board_run "3=dan-skills template" "4=me/other"
want_exit "with the template and no board, board.sh exits 0" 0 "$RC"
not_called "it creates nothing" '^project create'
not_called "it leaves the template's Status alone" '^api graphql'
called "it copies the existing template" '^project copy 3 .*--title me/app'
called "and links the copy" '^project link 8 '
eq "it prints the numbers, the URL and only the auto-add step" "template=3
board=8
url=https://github.com/users/me/projects/8

Board created. Turn on Auto-add to project for me/app with the filter is:issue is:open at:
https://github.com/users/me/projects/8/workflows" "$OUT"

board_run "3=dan-skills template" "5=me/app"
want_exit "with the template and the board, board.sh exits 0" 0 "$RC"
not_called "it creates, copies or links nothing" '^(project (create|copy|link)|api graphql)'
eq "it prints the numbers and the URL, and no manual steps" "template=3
board=5
url=https://github.com/users/me/projects/5" "$OUT"

board_scopes "'gist', 'read:org', 'repo'"
board_run
want_exit "without the project scope, board.sh exits 1" 1 "$RC"
contains "and tells the user how to add it" "$ERR" "gh auth refresh -s project"
not_called "before touching any project" '^(project|api) '
board_scopes "'gist', 'project', 'read:org', 'repo'"

for step in "project list" "project copy" "project link"; do
  GH_FAIL="$step" board_run "3=dan-skills template"
  want_exit "a failing gh $step stops board.sh" 1 "$RC"
  eq "and prints no board line" "" "$(grep '^board=' <<<"$OUT")"
done

GH_FAIL="api graphql" board_run
want_exit "a failing gh api graphql stops board.sh" 1 "$RC"
eq "a failing gh api graphql is the last call made" "api graphql" \
  "$(tail -n 1 <<<"$CALLS" | awk '{print $1, $2}')"
eq "and prints no board line" "" "$(grep '^board=' <<<"$OUT")"

gh_can project-field-list '{"fields":[{"id":"PVTF_title","name":"Title","type":"ProjectV2Field"}],"totalCount":1}'
board_run
want_exit "a new template with no Status field stops board.sh" 1 "$RC"
contains "and names the missing field" "$ERR" "has no Status field"
not_called "before replacing any field or copying" '^(api graphql|project copy)'
eq "and prints no board line" "" "$(grep '^board=' <<<"$OUT")"
executable board.sh
executable labels.sh

finish
