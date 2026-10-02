#!/usr/bin/env bash
# Exit 2 means unverified, never clean: a check that cannot run must not pass.
set -uo pipefail

base="" body=""
while (($#)); do
  case $1 in
    --body) body=${2-}; shift 2 || { echo "--body needs a file" >&2; exit 2; } ;;
    *) base=$1; shift ;;
  esac
done

# Read guard-bash.sh's patterns rather than copying them, so the two never drift.
here=$(cd "$(dirname "$0")" && pwd -P)
guard=""
for g in "$here/../../../guard-bash.sh" "$HOME/.claude/guard-bash.sh"; do
  [[ -r $g ]] && { guard=$g; break; }
done
[[ -n $guard ]] || { echo "UNVERIFIED: guard-bash.sh not found, no patterns to check against" >&2; exit 2; }
pattern() { sed -n "s/^$1='\(.*\)'\$/\1/p" "$guard" | head -1; }
AI_NAME=$(pattern AI_NAME) AI_DOMAIN=$(pattern AI_DOMAIN) AI_BOT=$(pattern AI_BOT) AI_KEY=$(pattern AI_KEY)
for v in AI_NAME AI_DOMAIN AI_BOT AI_KEY; do
  [[ -n ${!v} ]] || { echo "UNVERIFIED: $v is missing from $guard" >&2; exit 2; }
done

if [[ -z $base ]]; then
  base=$(git merge-base origin/main HEAD 2>/dev/null) ||
    { echo "UNVERIFIED: no merge-base with origin/main; pass BASE" >&2; exit 2; }
fi
git rev-parse --verify --quiet "$base^{commit}" >/dev/null ||
  { echo "UNVERIFIED: $base is not a commit" >&2; exit 2; }

nl=$'\n'
credits_tool() { # text -> 0 when it credits a tool; same rule as guard-bash.sh
  local head="(^|${nl})[[:blank:]]*" gap="[^${nl}]*(${nl}[[:space:]]*)?[^${nl}]*" hit=1
  shopt -s nocasematch
  if [[ $1 =~ ${head}${AI_KEY}${gap}(${AI_NAME}|${AI_DOMAIN}|${AI_BOT}) ]] ||
    [[ $1 =~ (claude-session|🤖) ]]; then hit=0; fi
  shopt -u nocasematch
  return $hit
}
is_tool() { # "name <email>" -> 0 when it is an agent, model, or bot
  local hit=1
  shopt -s nocasematch
  if [[ $1 =~ (^|[^a-z])${AI_NAME}([^a-z]|$) || $1 =~ $AI_DOMAIN || $1 =~ $AI_BOT ]]; then hit=0; fi
  shopt -u nocasematch
  return $hit
}

shas=$(git rev-list --reverse "$base..HEAD")
[[ -n $shas ]] || { echo "UNVERIFIED: no commits in $base..HEAD" >&2; exit 2; }

flagged=0 n=0
printf 'range\t%s..%s\n' "$(git rev-parse --short "$base")" "$(git rev-parse --short HEAD)"
printf 'sha\tauthor\tcommitter\ttrailers\tverdict\n'
for sha in $shas; do
  n=$((n + 1))
  author=$(git show -s --format='%an <%ae>' "$sha")
  committer=$(git show -s --format='%cn <%ce>' "$sha")
  msg=$(git show -s --format='%B' "$sha")
  trailers=$(git show -s --format='%(trailers:only,unfold,separator=%x3B )' "$sha")
  why=""
  is_tool "$author" && why+="author is a tool; "
  is_tool "$committer" && why+="committer is a tool; "
  credits_tool "$msg" && why+="message credits a tool; "
  why=${why%; }
  [[ -n $why ]] && flagged=$((flagged + 1))
  printf '%s\t%s\t%s\t%s\t%s\n' "$(git rev-parse --short "$sha")" "$author" "$committer" \
    "${trailers:-none}" "${why:-clean}"
done

if [[ -n $body ]]; then
  [[ -r $body ]] || { echo "UNVERIFIED: cannot read body $body" >&2; exit 2; }
  if credits_tool "$(cat -- "$body")"; then
    flagged=$((flagged + 1))
    printf 'body\t%s\tcredits a tool\n' "$body"
  else
    printf 'body\t%s\tclean\n' "$body"
  fi
fi

if ((flagged)); then
  printf 'FLAGGED: %d of %d commits or body credit a tool\n' "$flagged" "$n"
  exit 1
fi
printf 'CLEAN: %d commits, no agent, model, or bot as author, committer, or credit\n' "$n"
