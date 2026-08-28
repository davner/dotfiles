#!/usr/bin/env bash
# Flags comments that narrate the edit history instead of the reason, at the
# moment they are written. Reads a PostToolUse payload on stdin; feedback goes
# back to the model on stderr with exit 2, which for PostToolUse is a nudge
# rather than a block, since the write has already happened.
#
# It inspects only the text the tool just wrote, never the whole file. Reading
# the file would flag every legacy comment in anything an agent touches, and a
# hook that fires on work you did not do is a hook you learn to ignore.
#
# The patterns are deliberately narrow. Domain prose says "the previous night"
# and "the old semester's page" about runtime state, so bare "previous" and
# "old" are not matched: this is a net for the obvious cases, not a proof, and
# its worth depends on staying quiet enough to be read.
#
#   comment-audit.sh          reads the payload on stdin, prints findings on
#                             stderr, exits 2 when it finds any and 0 otherwise
#
# Registered as a PostToolUse hook on Write|Edit|MultiEdit in settings.json.
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
# allowed to name one. Nothing else about a test comment is.
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

history_re='used to|no longer|formerly|superseded|(was|were) (removed|replaced|renamed)|this replaced|earlier (revision|version)|first (version|pass)|stopped being|went stale|until [0-9]{4}-[0-9]{2}-[0-9]{2}'
# Who decided it and when is never wanted, in a test as much as anywhere.
# Doubled backslash: `awk -v` resolves escapes before the regex is compiled.
stamp_re='\\([A-Z][a-z]+, [0-9]{4}-[0-9]{2}-[0-9]{2}'
date_re='[0-9]{4}-[0-9]{2}-[0-9]{2}'

findings=$(
  awk -v hist="$history_re" -v stamp="$stamp_re" -v date="$date_re" -v in_test="$in_test" -v fenced="$fenced" '
    # A GraphQL or Python docstring is documentation too, and carries no marker
    # on its body lines - so track the fence rather than looking for one.
    fenced && /"""/ { in_doc = !in_doc; text = $0 }
    {
      line = $0
      if (text == "") {
        # Whole-line comment: //, #, or a block-comment body line.
        if (in_doc || line ~ /^[[:space:]]*(\/\/|#|\/\*|\*)/) {
          text = line
        }
        # Trailing line comment after code.
        else if (match(line, /\/\/.*$/)) {
          text = substr(line, RSTART)
        }
      }
      if (text == "") next

      if (text ~ hist || text ~ stamp || (in_test == 0 && text ~ date)) {
        sub(/^[[:space:]]+/, "", line)
        print "  " line
      }
      text = ""
    }
  ' <<<"$written"
)

[[ -n $findings ]] || exit 0

{
  echo "Comment audit: the text just written to $path narrates the edit history."
  echo "$findings"
  echo
  echo "A comment says why the code is what it is, never what it used to be, who"
  echo "decided it, or when. The reason survives in the present tense - \"one control,"
  echo "so the aria labels cannot drift\" carries the whole lesson with no history"
  echo "attached. Rewrite these that way, or delete them if nothing is left."
} >&2

exit 2
