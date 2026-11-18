#!/usr/bin/env bash
# PostToolUse hook on Write|Edit|MultiEdit in settings.base.json: exit 2 is a
# nudge rather than a block, since the write already happened.
set -uo pipefail

payload=$(cat)
path=$(jq -r '.tool_input.file_path // empty' <<<"$payload")
case $path in
  *.py | *.pyi) ;;
  *) exit 0 ;;
esac
if [[ $path != /* ]]; then
  cwd=$(jq -r '.cwd // empty' <<<"$payload")
  [[ -n $cwd ]] || exit 0
  path=$cwd/$path
fi
[[ -f $path ]] || exit 0

# Followed to the real file, so the helper beside it is live without a rebuild.
self=${BASH_SOURCE[0]}
while [[ -L $self ]]; do
  link=$(readlink "$self")
  [[ $link == /* ]] || link=$(dirname "$self")/$link
  self=$link
done
# shellcheck source=/dev/null
source "$(dirname "$self")/python-tools.sh" || exit 0

root=$(git -C "$(dirname "$path")" rev-parse --show-toplevel 2>/dev/null) || exit 0
tool_on ruff "$path" || exit 0
ruff=()
while IFS= read -r word; do ruff+=("$word"); done < <(tool_cmd ruff "$root")
[[ ${#ruff[@]} -gt 0 ]] || exit 0

cd "$root" || exit 0
# Fix before format, as ruff's docs order them: a fix can leave code that needs
# formatting. The last check reports line numbers of the file as it now stands.
"${ruff[@]}" check --fix --force-exclude "$path" >/dev/null 2>&1
"${ruff[@]}" format --force-exclude "$path" >/dev/null 2>&1
if ! report=$("${ruff[@]}" check --no-fix --force-exclude "$path" 2>&1); then
  {
    printf 'ruff still reports lint errors in %s after formatting and safe fixes:\n%s\n' "$path" "$report"
    printf 'Fix them, then rerun: %s check --fix %q\n' "${ruff[*]}" "$path"
  } >&2
  exit 2
fi
exit 0
