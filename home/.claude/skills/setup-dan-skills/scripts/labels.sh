#!/usr/bin/env bash
# Makes the GitHub repo in the working directory hold the agreed label set.
# Safe to re-run: every label is written with --force, so a second run changes nothing.

# usage: labels.sh
set -euo pipefail

# name|colour|description. The only copy of the set; the tracker file names the families.
LABELS=(
  "needs-triage|ededed|Waiting for the maintainer to evaluate"
  "needs-info|d876e3|Waiting on the reporter for more information"
  "ready-for-agent|0e8a16|Fully specified, an agent can pick it up"
  "ready-for-human|1d76db|Needs a human to implement"
  "wontfix|ffffff|Will not be worked on"
  "feat|a2eeef|A new feature"
  "fix|d73a4a|A bug fix"
  "docs|0075ca|Documentation only"
  "refactor|c5def5|A code change that neither fixes a bug nor adds a feature"
  "perf|fbca04|A performance improvement"
  "test|bfd4f2|Adds or corrects tests"
  "chore|cfd3d7|Build, tooling or maintenance"
  "todo|f9d0c4|A TODO item, not yet ready for work"
  "breaking|b60205|A breaking change"
  "dependencies|0366d6|Updates a dependency"
  "skip-changelog|eeeeee|Needs no changelog entry"
  "duplicate|cfd3d7|This issue or pull request already exists"
)
# GitHub defaults that mean the same as a label in the set.
RENAMES=(
  "bug|fix"
  "enhancement|feat"
  "documentation|docs"
)

repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
existing="$(gh label list -R "$repo" --limit 1000 --json name --jq '.[].name')"
has() { grep -Fxq -- "$1" <<<"$existing"; }

for pair in "${RENAMES[@]}"; do
  from="${pair%%|*}" to="${pair#*|}"
  has "$from" || continue
  if has "$to"; then
    echo "kept $from: $to already exists"
    continue
  fi
  gh label edit "$from" -R "$repo" --name "$to"
  echo "renamed $from to $to"
done

# Deleting a label strips it from everything carrying it, so one in use stays.
for name in "good first issue" "help wanted" "question" "invalid"; do
  has "$name" || continue
  issues="$(gh issue list -R "$repo" --label "$name" --state all --limit 1 --json number --jq length)"
  prs="$(gh pr list -R "$repo" --label "$name" --state all --limit 1 --json number --jq length)"
  if [ "$issues" != 0 ] || [ "$prs" != 0 ]; then
    echo "kept $name: an issue or PR carries it"
    continue
  fi
  gh label delete "$name" -R "$repo" --yes
  echo "deleted $name"
done

for entry in "${LABELS[@]}"; do
  IFS='|' read -r name colour description <<<"$entry"
  gh label create "$name" -R "$repo" --color "$colour" --description "$description" --force
done
echo "labels set on $repo"
