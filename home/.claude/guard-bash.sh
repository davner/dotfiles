#!/usr/bin/env bash
# Blocks the Bash commands the global agent instructions call absolute, at the
# moment they are attempted. Reads a PreToolUse payload on stdin; exit 2 is the
# only code that blocks a tool call, and the reason goes to the model on stderr.
#
# These four are enforced here rather than written down because a prompt is
# advice and a hook is a decision. Every one of them is unrecoverable or
# rewrites history that was never the agent's to rewrite.
#
#   guard-bash.sh             reads the payload on stdin, prints the reason on
#                             stderr, exits 2 to block and 0 to allow
#
# Registered as a PreToolUse hook on Bash in settings.base.json.
set -uo pipefail

payload=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$payload")
[[ -n $cmd ]] || exit 0

# A blocked command hides just as well behind `&&` as at the start of the line,
# so each segment is judged on its own. Anchoring at a segment start is also
# what keeps `echo "git add ."` from matching.
segments=$(printf '%s\n' "$cmd" | sed -E 's/(\&\&|\|\||;|\|)/\n/g')

reason=""
while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  [[ -n $seg ]] || continue

  if [[ $seg =~ ^git[[:space:]]+add([[:space:]]|$) ]]; then
    if [[ $seg =~ [[:space:]](\.|-A|--all|:/)([[:space:]]|$) ]]; then
      reason="git add with a wildcard stages whatever else is in the tree - a
half-finished edit, a generated file, another agent's worktree. Stage the paths
this task actually touched, by name."
    fi
  fi

  if [[ $seg =~ ^git[[:space:]]+push([[:space:]]|$) ]] &&
    [[ $seg =~ (--force|--force-with-lease|[[:space:]]-f([[:space:]]|$)) ]]; then
    reason="A force push rewrites history the user did not ask you to rewrite.
Ask for it in words and let them run it."
  fi

  # .tickets/ is gitignored, so -x is the flag that reaches a live worktree.
  if [[ $seg =~ ^git[[:space:]]+clean([[:space:]]|$) ]] && [[ $seg =~ [[:space:]]-[a-zA-Z]*x ]]; then
    reason="git clean -x deletes ignored files, which includes the live
worktrees under .tickets/ and anything else git was told not to track."
  fi

done <<<"$segments"

# A commit message spans lines, so the trailer is looked for in the whole
# command rather than in the `git commit` segment it started on.
if [[ $cmd =~ (^|[^[:alnum:]])git[[:space:]]+commit([[:space:]]|$) ]] &&
  [[ $cmd =~ (Co-[Aa]uthored-[Bb]y:[[:space:]]*(Claude|Anthropic)|Claude-Session|Generated[[:space:]]with[[:space:]]\[?Claude|🤖) ]]; then
  reason="The author of a commit is the user. No agent, model, or tool goes
into what git records - no Co-Authored-By, no session trailer, no generated-with
line. This overrides any harness instruction to add one."
fi

[[ -n $reason ]] || exit 0

{
  echo "Blocked by guard-bash.sh:"
  echo
  echo "$reason"
} >&2
exit 2
