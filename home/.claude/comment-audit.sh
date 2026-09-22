#!/usr/bin/env bash
# PostToolUse hook on Write|Edit|MultiEdit in settings.base.json. Exit 2 here is
# a nudge rather than a block, since the write already happened, and it reads
# only the text the tool just wrote so it never flags a comment it did not author.
set -uo pipefail

payload=$(cat)

path=$(jq -r '.tool_input.file_path // empty' <<<"$payload")
[[ -n $path ]] || exit 0

case $path in
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.css | *.scss | *.graphql | *.py | *.go | *.rs | *.java | *.sh | *.nix) ;;
  *) exit 0 ;;
esac

# Write carries `content`, Edit carries `new_string`, MultiEdit an array of them.
written=$(jq -r '
  [ .tool_input.content?, .tool_input.new_string?, (.tool_input.edits // [])[]?.new_string? ]
  | map(select(. != null)) | join("\n")
' <<<"$payload")
[[ -n $written ]] || exit 0

# A fixture date in a test is guarded by the assertion beside it, so it is
# allowed to name one.
case $path in
  *.test.* | *.spec.* | *_test.* | */tests/* | */test/*) in_test=1 ;;
  *) in_test=0 ;;
esac

# Only these two carry documentation in a `"""` fence. Tracking it anywhere else
# turns a string that merely contains one into the rest of the file.
case $path in
  *.graphql | *.py) fenced=1 ;;
  *) fenced=0 ;;
esac

# Deliberately narrow, because a net that fires on domain prose gets ignored:
# bare "previous" and "old" describe runtime state, their adverb forms never do,
# and the move and rename patterns keep their extra words for the same reason.
history_re='used to|no longer|formerly|superseded|(was|were) (removed|replaced|renamed)|this replaced|earlier (revision|version)|first (version|pass)|stopped being|went stale|previously|originally|refactored|renamed from|moved here from|instead of the old|until [0-9]{4}-[0-9]{2}-[0-9]{2}'
# "per the spec" stays unmatched - an RFC is a legitimate present-tense referent.
session_re='as requested|as discussed|as instructed|per (the )?(plan|ticket|review|feedback)|review feedback|addresses the (review|finding)'
# Doubled backslash: `awk -v` resolves escapes before the regex is compiled.
stamp_re='\\([A-Z][a-z]+, [0-9]{4}-[0-9]{2}-[0-9]{2}'
# Month names require the year beside them, so "Mar" the abbreviation and "May"
# the modal never hit on their own.
date_re='[0-9]{4}-[0-9]{2}-[0-9]{2}|(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\\.? (19|20)[0-9][0-9]'
# Machine-read directives exist for the tooling, not the reader, so they are
# invisible to the run length rather than counted against it.
pragma_re='^#!|shellcheck[[:space:]]+disable|eslint-disable|@ts-expect-error|prettier-ignore|^[[:space:]]*///[[:space:]]*<reference'
RUN_MAX=3

# One pass, because the fence tracker is the thing both faults depend on and a
# second copy of it is a second place to forget. The prefix says which fault.
audit=$(
  awk -v hist="$history_re" -v sess="$session_re" -v stamp="$stamp_re" -v date="$date_re" \
    -v pragma="$pragma_re" -v in_test="$in_test" -v fenced="$fenced" -v max="$RUN_MAX" '
    # A GraphQL or Python docstring is documentation too, and carries no marker
    # on its body lines - so track the fence rather than looking for one, per
    # occurrence, since `"""One-liner."""` opens and closes on the one line.
    function fences(s,   c, i) {
      c = 0
      while ((i = index(s, "\"\"\"")) > 0) { c++; s = substr(s, i + 3) }
      return c
    }
    function flush() {
      if (run > max) {
        sub(/^[[:space:]]+/, "", first)
        print "R  " run " lines starting: " first
      }
      run = 0
    }
    fenced && /"""/ { if (fences($0) % 2) in_doc = !in_doc; text = $0 }
    {
      line = $0
      comment = (in_doc == 0 && line ~ /^[[:space:]]*(\/\/|#|\/\*|\*)/)
      # A pragma is invisible to a run: it neither counts nor breaks one.
      if (comment && line !~ pragma) {
        if (run++ == 0) first = line
      } else if (!comment) {
        flush()
      }

      if (text == "") {
        if (in_doc || line ~ /^[[:space:]]*(\/\/|#|\/\*|\*)/) {
          text = line
        }
        else if (match(line, /\/\/.*$/)) {
          text = substr(line, RSTART)
        }
      }
      if (text != "") {
        if (text ~ hist || text ~ sess || text ~ stamp || (in_test == 0 && text ~ date)) {
          sub(/^[[:space:]]+/, "", line)
          print "F  " line
        }
        text = ""
      }
    }
    END { flush() }
  ' <<<"$written"
)
findings=$(grep '^F' <<<"$audit" | cut -c2-)
runs=$(grep '^R' <<<"$audit" | cut -c2-)

[[ -n $findings || -n $runs ]] || exit 0

{
  if [[ -n $findings ]]; then
    echo "Comment audit: the text just written to $path narrates the edit history"
    echo "or the session that produced it."
    echo "$findings"
    echo
    echo "A comment says why the code is what it is - never what it used to be, who"
    echo "decided it, when, or what the current task wanted. The audience is a stranger"
    echo "reading the code, not a party to this conversation. The reason survives in"
    echo "the present tense; rewrite these that way, or delete them if nothing is left."
  fi
  if [[ -n $runs ]]; then
    [[ -n $findings ]] && echo
    echo "Comment audit: the text just written to $path carries a comment block longer"
    echo "than $RUN_MAX lines."
    echo "$runs"
    echo
    echo "Zero comments is the default and one tight sentence is the cap. A block this"
    echo "long is prose the code should be carrying: keep the constraint a reader"
    echo "cannot see and cut the rest, or move each reason down to the line it explains."
  fi
} >&2

exit 2
