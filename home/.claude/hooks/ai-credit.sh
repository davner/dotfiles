#!/usr/bin/env bash
# Sourced by guard-bash.sh, comment-audit.sh and the pr skill's provenance.sh, so
# a commit, a PR and a code comment are all judged by one list.

# Brands only: `cody`, `cursor` and `codex` are all names a human contributor
# can carry, but `devin-ai-integration` is a handle nobody is christened with.
AI_NAME='(claude|anthropic|copilot|chatgpt|openai|gpt-[0-9]|gemini|codeium|windsurf|aider|codewhisperer|sourcegraph|devin-ai-integration)'
# The name is not enough: a trailer reading "Opus 5 <noreply@anthropic.com>"
# credits a model without naming a brand, so the vendor domain is checked too.
AI_DOMAIN='@(anthropic|openai|cursor|cognition|codeium|sourcegraph)\.(com|ai|sh)'
# A `[bot]` suffix in a GitHub noreply address is a machine account by
# construction, whatever display name the trailer puts in front of it.
AI_BOT='[0-9]+\+[a-z0-9-]+\[bot\]@users\.noreply\.github\.com'
# Signed-off-by is deliberately absent: a DCO sign-off is a human's legal
# attestation, never how a model credits itself, and this gate has no override.
AI_KEY='(co-authored-by|assisted-by|generated[[:space:]]+(with|by))'

# Session talk, not code talk. "per the spec" and a bare "per" stay unmatched:
# an RFC is a real referent, and "one worktree per ticket" an ordinary sentence.
# shellcheck disable=SC2034
SESSION_META='as requested|as discussed|as instructed|per the (plan|ticket|review|feedback)([^[:alnum:]_]|$)|review feedback|addresses the (review|finding)'

credits_tool() { # text -> success when it credits an agent, model, or bot
  local nl=$'\n' hit=1 was=0
  # git honours a trailer only at a line start, and the name follows it on that
  # line or the first non-blank one after - prose naming both is not a credit.
  local head="(^|${nl})[[:blank:]]*" gap="[^${nl}]*(${nl}[[:space:]]*)?[^${nl}]*"
  shopt -q nocasematch && was=1
  shopt -s nocasematch
  if [[ $1 =~ ${head}${AI_KEY}${gap}(${AI_NAME}|${AI_DOMAIN}|${AI_BOT}) || $1 =~ (claude-session|🤖) ]]; then
    hit=0
  fi
  ((was)) || shopt -u nocasematch
  return $hit
}

is_tool() { # "name <email>" -> success when it is an agent, model, or bot
  local hit=1 was=0
  shopt -q nocasematch && was=1
  shopt -s nocasematch
  if [[ $1 =~ (^|[^a-z])${AI_NAME}([^a-z]|$) || $1 =~ $AI_DOMAIN || $1 =~ $AI_BOT ]]; then
    hit=0
  fi
  ((was)) || shopt -u nocasematch
  return $hit
}
