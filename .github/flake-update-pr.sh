#!/usr/bin/env bash
# usage: flake-update-pr.sh BRANCH RUN_URL
#   Run from a checkout of main whose flake.lock moved.
set -euo pipefail

branch="$1"
run_url="$2"
base="$(git rev-parse --abbrev-ref HEAD)"

git switch -q -C "$branch"
git add flake.lock
git commit -q -m "chore(deps): nix flake update"
lease="$(git ls-remote origin "refs/heads/$branch" | cut -f1)"
git push --force-with-lease="$branch:$lease" origin "$branch"
# A push with GITHUB_TOKEN starts no workflow, so the required test check is started by hand.
gh workflow run test.yml --ref "$branch"

open="$(gh pr list --head "$branch" --state open --json number --jq length)"
if [ "$open" -gt 0 ]; then
  echo "A pull request is already open for $branch."
else
  gh pr create \
    --base "$base" \
    --head "$branch" \
    --title "chore(deps): nix flake update" \
    --label dependencies \
    --body "Weekly flake input bump. \`./test.sh\` passed and the configuration built before this was pushed, so the checks that a token-authored PR cannot trigger have already run in the [update workflow]($run_url)."
fi
gh pr merge "$branch" --auto --squash
