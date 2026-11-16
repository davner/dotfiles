#!/usr/bin/env bash
# Gives the GitHub repo in the working directory a project board, copied from
# the user's "dan-skills template" project, creating the template and its views
# first if missing.
# Safe to re-run: an existing template or board is reused, never changed. The
# board is the open project linked to the repo, else the one titled owner/name.
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

repo_json=$(gh repo view --json nameWithOwner,projectsV2)
repo=$(jq -r .nameWithOwner <<<"$repo_json")

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

add_priority_field() { # project number, project url
  gh project field-create "$1" --owner @me --name Priority --data-type SINGLE_SELECT \
    --single-select-options P1,P2,P3 >/dev/null || half_built "creating the Priority field failed" "$2"
}

# Shared, since every view goes on the one template create_views builds: its
# number, owner login, URL, and field IDs by name as JSON.
view_project="" view_login="" view_url="" view_ids=""

create_view() { # name, layout, filter, [--group-by FIELD | --columns-by FIELD], visible field...
  local name=$1 layout=$2 filter=$3 group_key="" group="" fields=()
  shift 3
  while (($#)); do
    case $1 in
      --group-by) group_key=group_by group=$2; shift ;;
      --columns-by) group_key=vertical_group_by group=$2; shift ;;
      *) fields+=("$1") ;;
    esac
    shift
  done
  jq -n --arg name "$name" --arg layout "$layout" --arg filter "$filter" --arg key "$group_key" \
    --arg group "$group" --argjson ids "$view_ids" '
    {name: $name, layout: $layout, filter: $filter, visible_fields: [$ARGS.positional[] | $ids[.]],
      sort_by: [[$ids.Priority, "asc"]]} + (if $key == "" then {} else {($key): [$ids[$group]]} end)' \
    --args "${fields[@]}" |
    gh api "users/$view_login/projectsV2/$view_project/views" --method POST --input - >/dev/null ||
    half_built "creating the $name view failed" "$view_url"
}

create_views() { # project number, project url
  local field
  view_project=$1 view_url=$2 view_login=${2#*/users/}
  view_login=${view_login%%/*}
  view_ids=$(gh api "users/$view_login/projectsV2/$1/fields" --jq 'map({(.name): .id}) | add // {}')
  # Checked before any view exists, since a re-run reuses the template as it is.
  for field in Title Status Labels "Linked pull requests" "Parent issue" "Sub-issues progress" Priority; do
    jq -e --arg n "$field" 'has($n)' <<<"$view_ids" >/dev/null ||
      half_built "project $1 has no $field field" "$2"
  done
  create_view Board board "is:issue -label:goal,spec" --columns-by Status \
    Title Labels "Linked pull requests" "Parent issue" Priority
  create_view "Agent queue" table "is:issue is:open status:Ready label:ready-for-agent -is:blocked -label:goal,spec" \
    Title Labels "Parent issue" Priority
  create_view "Needs attention" table "is:open label:needs-info,needs-triage" Title Labels Status Priority
  create_view "Goals and specs" table "label:goal,spec" --group-by Status \
    Title Status "Sub-issues progress" Priority
  create_view "Tickets by parent" table "is:open has:parent-issue" --group-by "Parent issue" \
    Title Status "Linked pull requests" Priority
}

delete_default_view() { # -> deletes the template's "View 1", or says to delete it by hand
  local id
  # shellcheck disable=SC2016  # $login, $number and $viewId are GraphQL variables
  id=$(gh api graphql -f login="$view_login" -F number="$view_project" -f query='
    query($login: String!, $number: Int!) {
      user(login: $login) { projectV2(number: $number) { views(first: 20) { nodes { id name } } } }
    }' --jq '(.data.user.projectV2.views.nodes // [])[] | select(.name == "View 1") | .id' | head -n 1) &&
    { [[ -z $id ]] || gh api graphql -f viewId="$id" -f query='
    mutation($viewId: ID!) { deleteProjectV2View(input: {viewId: $viewId}) { clientMutationId } }' >/dev/null; } ||
    steps+=("" "Delete the view named View 1 at:" "$view_url")
}

steps=()
workflows=("- Item closed: set Status to Done"
  "- Pull request merged: set Status to Done"
  "- Auto-close issue: on, for Status Done"
  "- Auto-archive items: on, filter is:issue is:closed updated:<@today-2w"
  "- Item added to project: set Status to Backlog"
  "- Auto-add sub-issues to project: on"
  "- Pull request linked to issue: set Status to In review")
template_new=""
found=$(find_project "$TEMPLATE_TITLE")
if [[ -z $found ]]; then
  created=$(gh project create --owner @me --title "$TEMPLATE_TITLE" --format json)
  found=$(jq -r '"\(.number) \(.url)"' <<<"$created")
  set_status_options "${found%% *}" "${found#* }"
  add_priority_field "${found%% *}" "${found#* }"
  create_views "${found%% *}" "${found#* }"
  template_new=1
  steps+=("" "Template created. Turn on these built-in workflows at:" "${found#* }/workflows" "${workflows[@]}")
  delete_default_view
fi
template=${found%% *}

# The owner may rename the board, so its link to the repo outranks its title.
found=$(jq -r --arg t "$TEMPLATE_TITLE" '.projectsV2.Nodes // [] | map(select(.closed | not) | select(.title != $t))
  | first // empty | "\(.number) \(.url)"' <<<"$repo_json")
[[ -n $found ]] || found=$(find_project "$repo")
if [[ -z $found ]]; then
  copied=$(gh project copy "$template" --source-owner @me --target-owner @me --title "$repo" --format json)
  found=$(jq -r '"\(.number) \(.url)"' <<<"$copied")
  gh project link "${found%% *}" --owner "${repo%%/*}" --repo "${repo#*/}" >/dev/null
  # A copy takes only the workflows the template already had on, and a new template has none yet.
  if [[ -n $template_new ]]; then
    steps+=("" "Board created. Turn on these built-in workflows at:" "${found#* }/workflows" "${workflows[@]}"
      "- Auto-add to project: $repo, filter is:issue is:open")
  else
    steps+=("" "Board created. Turn on Auto-add to project for $repo with the filter is:issue is:open at:"
      "${found#* }/workflows")
  fi
fi
board=${found%% *}
url=${found#* }

printf 'template=%s\nboard=%s\nurl=%s\n' "$template" "$board" "$url"
((${#steps[@]} == 0)) || printf '%s\n' "${steps[@]}"
