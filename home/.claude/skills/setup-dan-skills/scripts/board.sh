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

half_built() { # reason, template url -> stops board.sh, saying how to start over
  echo "board.sh: $1. A re-run reuses the template as it is, so delete the project at $2 and re-run board.sh." >&2
  exit 1
}

set_status_options() { # project number, project url
  local field
  field=$(gh project field-list "$1" --owner @me --format json |
    jq -r '.fields[] | select(.name == "Status") | .id')
  [[ -n $field ]] || half_built "project $1 has no Status field" "$2"
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

# Shared, since every view goes on the one template create_views builds: its
# number, owner login, URL, and field IDs by name as JSON.
view_project="" view_login="" view_url="" view_ids=""

field_id() { # field name -> its ID on the template
  jq -r --arg n "$1" '.[$n]' <<<"$view_ids"
}

create_view() { # name, layout, filter, [--group-by FIELD], [--columns-by FIELD], visible field...
  local name=$1 args=(-f name="$1" -f layout="$2" -f filter="$3") grouping=""
  shift 3
  while (($#)); do
    case $1 in
      --group-by) grouping="group_by[]=$(field_id "$2")"; shift ;;
      --columns-by) grouping="vertical_group_by[]=$(field_id "$2")"; shift ;;
      *) args+=(-F "visible_fields[]=$(field_id "$1")") ;;
    esac
    shift
  done
  [[ -z $grouping ]] || args+=(-F "$grouping")
  gh api "users/$view_login/projectsV2/$view_project/views" --method POST "${args[@]}" >/dev/null ||
    half_built "creating the $name view failed" "$view_url"
}

create_views() { # project number, project url
  local field
  view_project=$1 view_url=$2 view_login=${2#*/users/}
  view_login=${view_login%%/*}
  view_ids=$(gh api "users/$view_login/projectsV2/$1/fields" --jq 'map({(.name): .id}) | add // {}')
  # Checked before any view exists, since a re-run reuses the template as it is.
  for field in Title Status Labels "Linked pull requests" "Parent issue" "Sub-issues progress"; do
    jq -e --arg n "$field" 'has($n)' <<<"$view_ids" >/dev/null ||
      half_built "project $1 has no $field field" "$2"
  done
  create_view Board board "is:issue -label:spec" --columns-by Status \
    Title Labels "Linked pull requests" "Parent issue"
  create_view "Agent queue" table "is:issue is:open status:Ready label:ready-for-agent -is:blocked -label:spec" \
    Title Labels "Parent issue"
  create_view Specs table "label:spec" Title Status "Sub-issues progress"
  create_view "Tickets by parent" table "is:open has:parent-issue" --group-by "Parent issue" \
    Title Status "Linked pull requests"
}

steps=()
found=$(find_project "$TEMPLATE_TITLE")
if [[ -z $found ]]; then
  created=$(gh project create --owner @me --title "$TEMPLATE_TITLE" --format json)
  found=$(jq -r '"\(.number) \(.url)"' <<<"$created")
  set_status_options "${found%% *}" "${found#* }"
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
