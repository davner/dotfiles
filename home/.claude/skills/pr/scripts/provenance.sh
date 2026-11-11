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

# Through the skill's link to the repo first, so an edit there is live without a rebuild.
here=$(cd "$(dirname "$0")" && pwd -P)
credit=""
for c in "$here/../../../hooks/ai-credit.sh" "$HOME/.claude/hooks/ai-credit.sh"; do
  [[ -r $c ]] && { credit=$c; break; }
done
[[ -n $credit ]] || { echo "UNVERIFIED: ai-credit.sh not found, no patterns to check against" >&2; exit 2; }
# shellcheck source=/dev/null
source "$credit"
declare -F credits_tool is_tool >/dev/null ||
  { echo "UNVERIFIED: $credit defines no credits_tool or is_tool" >&2; exit 2; }

if [[ -z $base ]]; then
  base=$(git merge-base origin/main HEAD 2>/dev/null) ||
    { echo "UNVERIFIED: no merge-base with origin/main; pass BASE" >&2; exit 2; }
fi
git rev-parse --verify --quiet "$base^{commit}" >/dev/null ||
  { echo "UNVERIFIED: $base is not a commit" >&2; exit 2; }

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
