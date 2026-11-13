#!/usr/bin/env bash
# Sets the repo in the working directory up for squash auto-merge behind CI.

# usage: repo-settings.sh [--dry-run] --check NAME [--check NAME...]
#   --dry-run prints each gh command that writes instead of running it.
#   --check names a status check the default branch requires; repeat for more.
set -euo pipefail

usage() { sed -n '4,6s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

dry=""
checks=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry=1 ;;
    --check)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "repo-settings.sh: --check needs a check name" >&2
        exit 2
      fi
      checks+=("$2")
      shift
      ;;
    -h | --help) usage; exit 0 ;;
    *) echo "repo-settings.sh: unknown argument $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
if [ "${#checks[@]}" -eq 0 ]; then
  echo "repo-settings.sh: name at least one --check: auto-merge with no required check merges untested work" >&2
  exit 2
fi

# Quotes only what the shell would split or expand, so the printout reads
# plainly and still pastes.
shell_word() {
  local q="'\\''"
  case "$1" in
    *[!A-Za-z0-9_./:=@%+,-]* | "") printf "'%s'" "${1//\'/$q}" ;;
    *) printf '%s' "$1" ;;
  esac
}
write() {
  if [ -z "$dry" ]; then
    "$@" >/dev/null
    return
  fi
  local first=1 arg
  for arg in "$@"; do
    [ -n "$first" ] || printf ' '
    first=""
    shell_word "$arg"
  done
  printf '\n'
}

view="$(gh repo view --json nameWithOwner,defaultBranchRef --jq '.nameWithOwner + " " + .defaultBranchRef.name')"
read -r repo branch <<<"$view"

write gh repo edit "$repo" --enable-auto-merge --delete-branch-on-merge \
  --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
write gh api --method PATCH "repos/$repo" \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK
protect=(gh api --method PUT "repos/$repo/branches/$branch/protection"
  -F 'required_status_checks[strict]=true')
for c in "${checks[@]}"; do protect+=(-f "required_status_checks[contexts][]=$c"); done
protect+=(-F enforce_admins=false
  -F 'required_pull_request_reviews[required_approving_review_count]=0'
  -F restrictions=null -F required_linear_history=true
  -F allow_force_pushes=false -F allow_deletions=false)
write "${protect[@]}"
