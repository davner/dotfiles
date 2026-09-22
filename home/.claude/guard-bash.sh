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

# The message spans lines, so the whole command is searched - case-insensitively,
# since git reads trailer keys that way, and only where the name sits on the same
# line as an attribution key, because this repo's subjects say "claude" constantly.

# Brands only: `cody`, `cursor`, `codex` and `devin` are all names a human
# contributor can carry, and AI_DOMAIN still catches those agents.
AI_NAME='(claude|anthropic|copilot|chatgpt|openai|gpt-[0-9]|gemini|codeium|windsurf|aider|codewhisperer|sourcegraph)'
# The name is not enough: a trailer reading "Opus 5 <noreply@anthropic.com>"
# credits a model without naming a brand, so the vendor domain is checked too.
AI_DOMAIN='@(anthropic|openai|cursor|cognition|codeium|sourcegraph)\.(com|ai|sh)'
# Signed-off-by is deliberately absent: a DCO sign-off is a human's legal
# attestation, never how a model credits itself, and this gate has no override.
AI_KEY='(co-authored-by|assisted-by|generated[[:space:]]+(with|by))'
ai_credit=0
shopt -s nocasematch
nl=$'\n'
if [[ $cmd =~ ${AI_KEY}[^${nl}]*(${AI_NAME}|${AI_DOMAIN}) ]] ||
  [[ $cmd =~ (claude-session|🤖) ]]; then
  ai_credit=1
fi
shopt -u nocasematch

if [[ $cmd =~ (^|[^[:alnum:]])git[[:space:]]+commit([[:space:]]|$) ]] && [[ $ai_credit -eq 1 ]]; then
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
