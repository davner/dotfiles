#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "comment audit hook"
# It runs on every write in every session, behind `[ ! -x ... ] ||`, so a break or
# a lost executable bit is silent, and a false positive teaches everyone to ignore it.
AUDIT="$DIR/home/.claude/hooks/comment-audit.sh"
if require jq; then
  # name, expected exit, payload. 0 is quiet, 2 is a finding on stderr.
  audit_case() { hook "$AUDIT" "$3"; want_exit "$1" "$2" "$rc"; }
  audit_case "a comment giving a reason is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// one control, so the labels cannot drift"}}'
  audit_case "history narration is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// used to be a loop"}}'
  audit_case "an attribution stamp is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// tuned here (Dan, 2026-08-12)"}}'
  audit_case "a bare date in a source file is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// added 2026-08-12"}}'
  audit_case "a month-name date is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// as of March 2026 the cap is 50"}}'
  audit_case "a month-name date in a test file is allowed" 0 \
    '{"tool_input":{"file_path":"a.test.ts","content":"// fixture week of May 2026"}}'
  audit_case "a bare month abbreviation is not a date" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// Mar is the marker column"}}'
  audit_case "the adverb previously is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// previously handled by the queue"}}'
  audit_case "the adjective previous is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// carries the previous night forward"}}'
  audit_case "renamed from is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// renamed from getUser"}}'
  audit_case "domain moved from is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// rows moved from the queue land here"}}'
  audit_case "session talk as requested is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// kept both branches as requested"}}'
  audit_case "session talk per the plan is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// per the plan this stays sync"}}'
  audit_case "a protocol spec reference is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// retries per the spec, RFC 7231"}}'
  # The one documented carve-out: an assertion beside a fixture date fails
  # loudly when it drifts, so the date is allowed to be named there.
  audit_case "a fixture date in a test file is allowed" 0 \
    '{"tool_input":{"file_path":"a.test.ts","content":"// fixture 2026-08-12"}}'
  audit_case "a history phrase outside a comment is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"const s = 1; // fine"}}'
  audit_case "a non-source file is ignored" 0 \
    '{"tool_input":{"file_path":"notes.md","content":"used to be a loop"}}'
  audit_case "a payload with no file_path is ignored" 0 \
    '{"tool_input":{"content":"// used to be a loop"}}'
  audit_case "Edit new_string is read" 2 \
    '{"tool_input":{"file_path":"a.ts","new_string":"// no longer needed"}}'
  audit_case "MultiEdit edits[] are read" 2 \
    '{"tool_input":{"file_path":"a.ts","edits":[{"new_string":"// formerly async"}]}}'
  audit_case "a python docstring is read as documentation" 2 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"\nformerly a generator\n\"\"\""}}'
  # Length is its own fault: the patterns above catch what a comment says, and
  # nothing there catches a block that simply runs on.
  audit_case "a three-line comment run is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two\n// three"}}'
  audit_case "a two-line comment run is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two"}}'
  audit_case "a blank line ends a run" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two\n\n// three\n// four"}}'
  audit_case "a block comment run is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"/* one\n * two\n * three\n */"}}'
  audit_case "a four-line python docstring is not a comment run" 0 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"\nalpha\nbeta\ngamma\ndelta\n\"\"\""}}'
  # A fence that opens and closes on one line must leave the tracker where it
  # found it, or every line after it is misread for the rest of the file.
  audit_case "a one-line docstring does not swallow the run count" 2 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# one\n# two\n# three"}}'
  audit_case "a one-line docstring does not swallow the patterns" 2 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# formerly a generator"}}'
  audit_case "a one-line docstring leaves a short run short" 0 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# one\n# two"}}'
  audit_case "a run of pragma lines is not flagged" 0 \
    '{"tool_input":{"file_path":"a.sh","content":"#!/usr/bin/env bash\n# shellcheck disable=SC2086\n# shellcheck disable=SC2001\n# shellcheck disable=SC2002"}}'
  audit_case "a shebang does not pad a two-line run" 0 \
    '{"tool_input":{"file_path":"a.sh","content":"#!/usr/bin/env bash\n# one\n# two"}}'
  audit_case "a trailing comment on each line is not a run" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"const a=1; // one\nconst b=2; // two\nconst c=3; // three\nconst d=4; // four"}}'
  # A hook that dies on an unexpected payload takes the session's write with it.
  audit_case "malformed input exits quietly" 0 'not json at all'
  # Linked into ~/.claude through the store, so the phrase list is found beside the real file.
  mkdir -p "$WORK/audit-link/store" "$WORK/audit-link/home" "$WORK/audit-alone"
  ln -s "$AUDIT" "$WORK/audit-link/store/comment-audit.sh"
  ln -s ../store/comment-audit.sh "$WORK/audit-link/home/comment-audit.sh"
  eq "an audit reached through two links still reads the phrase list" "2" \
    "$(printf '%s' '{"tool_input":{"file_path":"a.ts","content":"// per the plan"}}' |
      "$WORK/audit-link/home/comment-audit.sh" >/dev/null 2>&1; echo $?)"
  cp "$AUDIT" "$WORK/audit-alone/comment-audit.sh"
  eq "an audit without ai-credit.sh fails without nudging" "1" \
    "$(printf '%s' '{"tool_input":{"file_path":"a.ts","content":"// per the plan"}}' |
      "$WORK/audit-alone/comment-audit.sh" >/dev/null 2>&1; echo $?)"

  # The cap is only credible if the repo it ships from meets it, so every hook
  # script is replayed as the full-file Write it would arrive as.
  unaudited=""
  for s in "$DIR"/home/.claude/hooks/*.sh "$DIR"/home/.claude/local-skills.sh; do
    out=$(jq -Rs --arg p "$s" '{tool_input:{file_path:$p,content:.}}' "$s" |
      "$AUDIT" 2>&1 >/dev/null) && continue
    unaudited="$unaudited
    $(basename "$s"):
$out"
  done
  if [ -z "$unaudited" ]; then
    ok "the repo's own hook scripts pass the comment audit"
  else
    bad "the repo's own hook scripts pass the comment audit" "$unaudited"
  fi
fi

finish
