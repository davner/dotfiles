#!/usr/bin/env bash
# usage: flake-update-pr.sh BRANCH RUN_URL LEASE, from a checkout of main whose lock moved.
#   LEASE is BRANCH's commit on origin when the run started, empty when it was absent.
set -euo pipefail

branch="$1"
run_url="$2"
lease="$3"
subject="chore(deps): nix flake update"

if [ "$(git symbolic-ref -q --short HEAD)" != main ]; then
  echo "flake-update-pr.sh: run it from a checkout of main" >&2
  exit 1
fi

git switch -q -C "$branch"
git add flake.lock
git commit -q -m "$subject"
git push --force-with-lease="$branch:$lease" origin "$branch"
# A push with GITHUB_TOKEN starts no workflow, so the required test check is started by hand.
gh workflow run test.yml --ref "$branch"

open="$(gh pr list --head "$branch" --state open --json number --jq length)"
if [ "$open" -gt 0 ]; then
  echo "A pull request is already open for $branch."
else
  gh pr create \
    --base main \
    --head "$branch" \
    --title "$subject" \
    --label dependencies \
    --body "Weekly flake input bump. \`./test.sh\` passed and the configuration built before this was pushed, so the checks that a token-authored PR cannot trigger have already run in the [update workflow]($run_url)."
fi
gh pr merge "$branch" --auto --squash
