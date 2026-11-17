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
# A body on stdin is part of the call, so it is logged after the args.
[[ $args != *"--input -"* ]] || args+=" $(jq -cS .)"
printf '%s\n' "$args" >>"$root/calls"
if [ -n "${GH_FAIL-}" ] && [[ $args == *"$GH_FAIL"* ]]; then
  echo "HTTP 403: Upgrade to GitHub Pro or make this repository public to enable this feature." >&2
  exit 1
fi
canned="$root/canned/$1-${2//\//_}"
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

# --- repo settings ---
section "repo settings"
RS="$SDS/repo-settings.sh"
gh_reset
gh_can repo-view '{"nameWithOwner":"davner/demo","defaultBranchRef":{"name":"main"}}'
writes() { grep -v '^repo view' <<<"$CALLS"; }

gh_run "$RS" --dry-run --check test
eq "a dry run exits 0, writes nothing and prints the three writes" "0  3" "$RC $(writes) $(grep -c '^gh ' <<<"$OUT")"

# The printout is what the user approves and may paste, so a check name with a
# quote in it must come back out of the shell unchanged.
gh_run "$RS" --dry-run --check "it's ok"
put="$(grep -- '--method PUT' <<<"$OUT")"
replayed="$(eval "set -- ${put#gh }" && printf '%s\n' "$@" | grep contexts)"
eq "a dry run's printout replays a quoted check name intact" \
  "required_status_checks[contexts][]=it's ok" "$replayed"

gh_run "$RS" --check test --check 'towncrier check'
eq "a real run exits 0 and makes the writes the dry run prints, quietly" "0|repo edit|api PATCH|api PUT|" \
  "$RC|$(writes | awk '{print $1, ($2 == "--method" ? $3 : $2)}' | paste -sd'|' -)|$OUT"
contains "the protection requires every named check" "$(writes | tail -n 1)" \
  "contexts][]=test -f required_status_checks[contexts][]=towncrier check"

gh_run "$RS" --dry-run
eq "no --check exits 2 and calls gh for nothing" "2 " "$RC $CALLS"
contains "and says why" "$ERR" "auto-merge with no required check merges untested work"

GH_FAIL="--method PATCH" gh_run "$RS" --check test
eq "a failing gh exits 1 and nothing after it runs" "1 2" "$RC $(writes | wc -l | tr -d ' ')"
contains "and GitHub's error reaches stderr" "$ERR" "HTTP 403"

# --- labels ---
section "label setup script"
LABELS="$SDS/labels.sh"
LABELS_DEFAULTS='["bug","documentation","duplicate","enhancement","good first issue","help wanted","invalid","question","wontfix"]'
LABELS_SET="breaking chore dependencies docs feat fix goal needs-info needs-triage perf ready-for-agent ready-for-human refactor spec test todo wontfix"
labels_repo() { # label names as a JSON array -> a fake repo holding those labels, with nothing labelled
  gh_reset
  rm -f "$GH/repo/towncrier.toml"
  gh_can repo-view '{"nameWithOwner":"owner/repo"}'
  gh_can label-list "$(jq '[.[] | {name: .}]' <<<"$1")"
  gh_can issue-list '[]'
  gh_can pr-list '[]'
}
created() { calls_to label create | awk '{print $3}' | sort | xargs; }
renamed() { calls_to label edit | awk '{print $3 ">" $NF}' | xargs; }
deleted() { calls_to label delete | sed -E 's/^label delete (.*) -R .*/\1/' | sort | paste -sd, -; }

labels_repo "$LABELS_DEFAULTS"
gh_run "$LABELS"
eq "a fresh repo: labels.sh exits 0 and creates the label set" "0 $LABELS_SET" "$RC $(created)"
eq "a fresh repo: the overlapping defaults are renamed" "bug>fix enhancement>feat documentation>docs" "$(renamed)"
eq "a fresh repo: the unused defaults are deleted" "duplicate,good first issue,help wanted,invalid,question" "$(deleted)"

labels_repo "$(jq -R 'split(" ")' <<<"$LABELS_SET")"
gh_run "$LABELS"
eq "a re-run: nothing is renamed or deleted" "" "$(renamed)$(deleted)"
eq "a re-run: only the set is written, again" "$LABELS_SET" "$(created)"
eq "a re-run: every write is --force, so it changes nothing" "" "$(calls_to label create | grep -v -- '--force$')"

labels_repo "$LABELS_DEFAULTS"
touch "$GH/repo/towncrier.toml"
gh_run "$LABELS"
eq "a towncrier repo also gets skip-changelog" "$(xargs -n1 <<<"$LABELS_SET skip-changelog" | sort | xargs)" "$(created)"

for carrier in issue pr; do
  labels_repo "$LABELS_DEFAULTS"
  gh_can "$carrier-list" '[{"number":7}]'
  gh_run "$LABELS"
  eq "a default a $carrier carries is kept" "" "$(deleted)"
  contains "and the kept label is reported" "$OUT" "kept question: an issue or PR carries it"
done

labels_repo '["bug","fix"]'
gh_run "$LABELS"
eq "bug beside an existing fix is kept, and reported" "kept bug: fix already exists" "$(renamed)$(grep '^kept' <<<"$OUT")"

missing=""
label_table="$(sed -n '/^### The labels$/,/^### /p' "$DIR/docs/workflow.md" | grep '^| ')"
for name in $LABELS_SET skip-changelog; do
  grep -Fq -- "\`$name\`" "$SDS/../issue-tracker-github.md" || missing+=" template:$name"
  grep -Fq -- "\`$name\`" <<<"$label_table" || missing+=" workflow.md:$name"
done
eq "the tracker template and docs/workflow.md name every label in the set" "" "$missing"


# --- board ---
section "setup-dan-skills board"
BOARD="$SDS/board.sh"
TEMPLATE_URL="https://github.com/users/me/projects/7"
FIELDS='[{"id":101,"name":"Title"},{"id":103,"name":"Status"},{"id":104,"name":"Labels"},{"id":105,"name":"Linked pull requests"},
  {"id":106,"name":"Parent issue"},{"id":107,"name":"Sub-issues progress"},{"id":108,"name":"Priority"}]'
STATUS_FIELD='{"fields":[{"id":"PVTSSF_status","name":"Status","type":"ProjectV2SingleSelectField"}],"totalCount":1}'
gh_reset
gh_can project-create '{"number":7,"id":"PVT_t","title":"dan-skills template","url":"'"$TEMPLATE_URL"'"}'
gh_can project-copy '{"number":8,"id":"PVT_b","title":"me/app","url":"https://github.com/users/me/projects/8"}'
gh_can project-field-list "$STATUS_FIELD"
gh_can api-users_me_projectsV2_7_fields "$FIELDS"
gh_can api-graphql '{"data":{"user":{"projectV2":{"views":{"nodes":[{"id":"PVTV_board","name":"Board"},{"id":"PVTV_one","name":"View 1"}]}}}}}'
board_scopes() { gh_can auth-status "$(printf 'github.com\n  - Token scopes: %s' "$1")"; }
board_scopes "'gist', 'project', 'read:org', 'repo'"
projects() { # number=title[=closed]... -> those projects as gh lists them
  printf '%s\n' "$@" | jq -R -s '[split("\n")[] | select(. != "") | split("=") | {number: (.[0] | tonumber),
    title: .[1], closed: (.[2] == "true"), url: "https://github.com/users/me/projects/\(.[0])"}]'
}
board_linked() { gh_can repo-view "{\"nameWithOwner\":\"me/app\",\"projectsV2\":{\"Nodes\":$(projects "$@")}}"; }
board_run() { # each existing project as number=title... -> runs board.sh, as gh_run
  gh_can project-list "{\"projects\":$(projects "$@")}"
  gh_run "$BOARD"
}
board_line() { grep '^board=' <<<"$OUT"; }
board_linked

board_scopes "'gist', 'read:project', 'repo'"
board_run
eq "without the project scope, board.sh exits 1 before touching any project" "1 auth status" "$RC $CALLS"
contains "and says how to add it" "$ERR" "gh auth refresh -s project"
board_scopes "'gist', 'project', 'read:org', 'repo'"

board_run
eq "with no projects, board.sh exits 0 and prints the new board" "0 board=8" "$RC $(board_line)"
called "it gives the template's Status the five columns in order" \
  'updateProjectV2Field.*"Backlog".*"Ready".*"In progress".*"In review".*"Done"'
views() { grep '^api users/me/projectsV2/7/views ' <<<"$CALLS" | sed 's/^.* --input - //'; }
eq "it creates the five views on the template" "Board|Agent queue|Needs attention|Goals and specs|Tickets by parent" \
  "$(views | jq -r .name | paste -sd'|' -)"
called "it deletes the default View 1" 'viewId=PVTV_one .*deleteProjectV2View'
not_called "and no other view" 'viewId=PVTV_board'
eq "it prints both workflows pages" "$TEMPLATE_URL/workflows|https://github.com/users/me/projects/8/workflows" \
  "$(grep '/workflows$' <<<"$OUT" | paste -sd'|' -)"
eq "and the workflows to turn on: 7 on the template, 8 on the board" 15 "$(grep -c '^- ' <<<"$OUT")"

# An agent reads the queue through next-up, a human through the view, so the two
# must pick the same items.
queue_view="$(views | jq -r 'select(.name == "Agent queue") | .filter')"
next_up="$(sed -n '/^## When a skill says "next-up"$/,/^## /p' "$SDS/../issue-tracker-github.md")"
eq "the Agent queue view filter equals the tracker template's next-up query" \
  "$(sed -nE "s/^ *--query '(.*)'.*/\1/p" <<<"$next_up")" "$queue_view"
next_up_jq="$(sed -nE "s/^ *--jq '(.*)'.*/\1/p" <<<"$next_up")"
eq "next-up takes P1 first, then P2, P3, then no priority, each in board order" "#3 c|#5 e|#2 b|#4 d|#1 a|#6 f" \
  "$(jq -r "$next_up_jq" <<<'{"items":[{"content":{"number":1,"title":"a"}},
  {"priority":"P2","content":{"number":2,"title":"b"}},{"priority":"P1","content":{"number":3,"title":"c"}},
  {"priority":"P3","content":{"number":4,"title":"d"}},{"priority":"P1","content":{"number":5,"title":"e"}},
  {"content":{"number":6,"title":"f"}}],"totalCount":6}' 2>&1 | paste -sd'|' -)"

GH_FAIL="deleteProjectV2View" board_run
eq "a failing delete of View 1 leaves board.sh going, and makes it a manual step" "0 Delete the view named View 1 at:" \
  "$RC $(grep '^Delete' <<<"$OUT")"

board_run "3=dan-skills template" "4=me/other"
not_called "it leaves the template alone" '^(project create|project field-create|api )'
eq "it exits 0 and prints the board and only the auto-add step" "0|board=8|Turn on Auto-add|0" \
  "$RC|$(board_line)|$(grep -o 'Turn on Auto-add' <<<"$OUT")|$(grep -c '^- ' <<<"$OUT")"

# The owner may rename a board; the link to the repo is what makes it the board.
while IFS='|' read -r name links projects want; do
  IFS=';' read -ra L <<<"$links"
  IFS=';' read -ra P <<<"$projects"
  board_linked ${L[@]+"${L[@]}"}
  board_run "3=dan-skills template" ${P[@]+"${P[@]}"}
  eq "$name: board.sh reuses board $want, writes nothing, asks nothing" "0 board=$want 3" \
    "$RC $(board_line) $(wc -l <<<"$OUT" | tr -d ' ')"
  not_called "$name: and calls no write" '^(project (create|copy|link|field-create)|api )'
done <<'EOF'
a board titled for the repo||5=me/app|5
a renamed board linked to the repo|5=app=false|5=app|5
a closed linked project, beside an open one|6=old=true;5=app=false|6=old;5=app;9=me/app|5
only a closed project linked|6=old=true|6=old;9=me/app|9
EOF
board_linked

# A half-built template is reused as it is, so each stop says to delete it first.
HALF="A re-run reuses the template as it is, so delete the project at $TEMPLATE_URL"
while IFS='|' read -r failing template can answer hint; do
  [ -z "$can" ] || gh_can "$can" "$answer"
  if [ -n "$template" ]; then GH_FAIL="$failing" board_run "3=dan-skills template"; else GH_FAIL="$failing" board_run; fi
  eq "${failing:-$hint}: board.sh stops with no board" "1 " "$RC $(board_line)"
  contains "and says why" "$ERR" "$hint"
  gh_can project-field-list "$STATUS_FIELD"
  gh_can api-users_me_projectsV2_7_fields "$FIELDS"
done <<EOF
project list|y|||HTTP 403
project copy|y|||HTTP 403
project link|y|||HTTP 403
api graphql||||HTTP 403
field-create||||creating the Priority field failed. $HALF
projectsV2/7/views||||creating the Board view failed. $HALF
||project-field-list|{"fields":[]}|project 7 has no Status field. $HALF
||api-users_me_projectsV2_7_fields|[{"id":101,"name":"Title"},{"id":103,"name":"Status"}]|project 7 has no Labels field. $HALF
EOF

# --- issue forms ---
section "setup-dan-skills issue forms"
FORMS="$SDS/../issue-forms"
form_labels() { # form file -> its labels, one per line; a list not on one line fails the read
  local line
  line="$(grep -E '^labels:' "$1")" || return 0
  [[ $line =~ ^labels:\ *\[(.*)\]$ ]] || { echo "<labels not a one-line [list]>"; return; }
  tr ',' '\n' <<<"${BASH_REMATCH[1]}" | sed -E 's/^ *//; s/ *$//'
}
eq "the Bug form adds fix, the TODO form todo" "fix todo" "$(form_labels "$FORMS/bug.yml") $(form_labels "$FORMS/todo.yml")"
eq "the TODO form asks for From, Why, Known and Next, as the TODO body has them" "From|Why|Known|Next" \
  "$(sed -nE 's/^ +label: *(.+)$/\1/p' "$FORMS/todo.yml" | paste -sd'|' -)"
# Filing from a form must never queue work for an agent or skip the owner's triage.
queued=""
for form in "$FORMS"/*.yml; do
  while read -r label; do
    case $label in ready-for-agent | ready-for-human | needs-triage | needs-info | "<"*) queued+=" ${form##*/}:$label" ;; esac
  done < <(form_labels "$form")
done
eq "no form adds a queue or triage label" "" "$queued"
# This repo's board runs on the same forms the skill hands out.
eq "this repo's issue forms are the skill's, file for file" "" \
  "$(diff -r "$FORMS" "$DIR/.github/ISSUE_TEMPLATE" 2>&1)"

finish
