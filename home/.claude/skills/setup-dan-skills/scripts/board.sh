#!/usr/bin/env bash
# Gives the GitHub repo in the working directory a project board, copied from
# the user's "dan-skills template" project, creating the template and its views
# first if missing.
# Safe to re-run: an existing template or board is reused, never changed.
# Prints template=, board= and url= lines, then any manual steps on GitHub.

# usage: board.sh
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
  # shellcheck disable=SC2016  # $fieldId is a GraphQL variable, not a shell one
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

create_view() { # project number, login, field IDs by name as JSON, view name, layout, filter, field...
  # A field is a visible field's name, or group_by=NAME or vertical_group_by=NAME.
  local project=$1 login=$2 ids=$3 args=(-f name="$4" -f layout="$5" -f filter="$6") field key id
  shift 6
  for field in "$@"; do
    key=visible_fields
    [[ $field != *=* ]] || { key=${field%%=*}; field=${field#*=}; }
    id=$(jq -r --arg n "$field" '.[$n]' <<<"$ids")
    args+=(-F "${key}[]=$id")
  done
  gh api "users/$login/projectsV2/$project/views" --method POST "${args[@]}" >/dev/null
}

create_views() { # project number, project url
  local login=${2#*/users/} ids field
  login=${login%%/*}
  ids=$(gh api "users/$login/projectsV2/$1/fields" --jq 'map({(.name): .id}) | add // {}')
  # Checked before any view exists, since a re-run reuses the template as it is.
  for field in Title Status Labels "Linked pull requests" "Parent issue" "Sub-issues progress"; do
    jq -e --arg n "$field" 'has($n)' <<<"$ids" >/dev/null ||
      { echo "board.sh: project $1 has no $field field" >&2; exit 1; }
  done
  create_view "$1" "$login" "$ids" Board board "is:issue -label:spec" \
    Title Labels "Linked pull requests" "Parent issue" vertical_group_by=Status
  create_view "$1" "$login" "$ids" "Agent queue" table \
    "is:open status:Ready label:ready-for-agent -is:blocked -label:spec" Title Labels "Parent issue"
  create_view "$1" "$login" "$ids" Specs table "label:spec" Title Status "Sub-issues progress"
  create_view "$1" "$login" "$ids" "Tickets by parent" table "is:open has:parent-issue" \
    Title Status "Linked pull requests" "group_by=Parent issue"
}

steps=()
found=$(find_project "$TEMPLATE_TITLE")
if [[ -z $found ]]; then
  created=$(gh project create --owner @me --title "$TEMPLATE_TITLE" --format json)
  found=$(jq -r '"\(.number) \(.url)"' <<<"$created")
  set_status_options "${found%% *}"
  create_views "${found%% *}" "${found#* }"
  steps+=("" "Template created. Turn on these built-in workflows at:" "${found#* }/workflows"
    "- Item closed: set Status to Done"
    "- Pull request merged: set Status to Done"
    "- Auto-close issue: on, for Status Done"
    "- Auto-archive items: Done items after 14 days"
    "- Item added to project: set Status to Backlog"
    "- Auto-add sub-issues to project: on"
    "- Pull request linked to issue: set Status to In review")
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
