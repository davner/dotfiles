#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_TITLE="dan-skills template"

# Quoted, so read:project, which cannot create boards, does not count.
auth=$(gh auth status 2>&1) || true
if [[ $auth != *"'project'"* ]]; then
  echo "board.sh: gh lacks the project scope; run: gh auth refresh -s project" >&2
  exit 1
fi

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)

find_project() { # title -> "number url" of the user's project with that title, or nothing
  gh project list --owner @me --limit 1000 --format json |
    jq -r --arg t "$1" '.projects[] | select(.title == $t) | "\(.number) \(.url)"' | head -n 1
}

set_status_options() { # project number
  local field
  field=$(gh project field-list "$1" --owner @me --format json |
    jq -r '.fields[] | select(.name == "Status") | .id')
  [[ -n $field ]] || { echo "board.sh: project $1 has no Status field" >&2; exit 1; }
  # A new project's Status holds Todo, In Progress, Done; this replaces them wholesale.
  gh api graphql -F fieldId="$field" -f query='
    mutation($fieldId: ID!) {
      updateProjectV2Field(input: {fieldId: $fieldId, singleSelectOptions: [
        {name: "Backlog", color: GRAY, description: ""},
        {name: "Ready", color: BLUE, description: ""},
        {name: "In progress", color: YELLOW, description: ""},
        {name: "In review", color: PURPLE, description: ""},
        {name: "Done", color: GREEN, description: ""}
      ]}) { projectV2Field { ... on ProjectV2SingleSelectField { id } } }
    }' >/dev/null
}

steps=()
found=$(find_project "$TEMPLATE_TITLE")
if [[ -z $found ]]; then
  created=$(gh project create --owner @me --title "$TEMPLATE_TITLE" --format json)
  found=$(jq -r '"\(.number) \(.url)"' <<<"$created")
  set_status_options "${found%% *}"
  gh project mark-template "${found%% *}" >/dev/null
  steps+=("" "Template created. Turn on these built-in workflows at:" "${found#* }/workflows"
    "- Item closed: set Status to Done"
    "- Pull request merged: set Status to Done"
    "- Auto-close issue: on, for Status Done"
    "- Auto-archive items: Done items after 14 days"
    "- Item added to project: set Status to Backlog")
fi
template=${found%% *}

found=$(find_project "$repo")
if [[ -z $found ]]; then
  copied=$(gh project copy "$template" --source-owner @me --target-owner @me --title "$repo" --format json)
  found=$(jq -r '"\(.number) \(.url)"' <<<"$copied")
  gh project link "${found%% *}" --owner @me >/dev/null
  steps+=("" "Board created. Turn on Auto-add to project for $repo with the filter is:issue is:open at:"
    "${found#* }/workflows")
fi
board=${found%% *}
url=${found#* }

printf 'template=%s\nboard=%s\nurl=%s\n' "$template" "$board" "$url"
((${#steps[@]} == 0)) || printf '%s\n' "${steps[@]}"
