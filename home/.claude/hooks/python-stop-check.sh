#!/usr/bin/env bash
# Stop hook in settings.base.json: exit 2 sends Claude back to fix what it
# changed. Read-only, because the owner's own edits show in git status too.
set -uo pipefail

payload=$(cat)
# True once this hook has sent Claude back, so an unfixable finding cannot loop.
[[ $(jq -r '.stop_hook_active // false' <<<"$payload") == true ]] && exit 0
cwd=$(jq -r '.cwd // empty' <<<"$payload")
root=$(git -C "${cwd:-$PWD}" rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

self=${BASH_SOURCE[0]}
while [[ -L $self ]]; do
  link=$(readlink "$self")
  [[ $link == /* ]] || link=$(dirname "$self")/$link
  self=$link
done
# shellcheck source=/dev/null
source "$(dirname "$self")/python-tools.sh" || exit 0

files=() olds=() untracked=()
while IFS= read -r -d '' entry; do
  status=${entry:0:2} path=${entry:3}
  old=""
  # A rename or copy carries its old path as the next NUL-separated field.
  [[ $status == *[RC]* ]] && IFS= read -r -d '' old
  [[ $status == *D* ]] && continue
  case $path in
    *.py | *.pyi) ;;
    *) continue ;;
  esac
  [[ -f $path ]] || continue
  files+=("$path") olds+=("$old") untracked+=("$([[ $status == '??' ]] && echo 1)")
done < <(git status --porcelain -z --untracked-files=all)
[[ ${#files[@]} -gt 0 ]] || exit 0

ruff=() ty=()
while IFS= read -r word; do ruff+=("$word"); done < <(tool_cmd ruff "$root")
while IFS= read -r word; do ty+=("$word"); done < <(tool_cmd ty "$root")

added_lines() { # path, old path, untracked -> the lines this change adds
  if [[ -n $3 ]]; then
    cat -- "$1"
    return
  fi
  local paths=("$1") diff=(diff --no-color --no-ext-diff -U0 --src-prefix=a/ --dst-prefix=b/)
  [[ -z $2 ]] || paths+=("$2")
  { git "${diff[@]}" -- "${paths[@]}"; git "${diff[@]}" --cached -- "${paths[@]}"; } |
    grep -v -e '^+++ b/' -e '^+++ /dev/null' | grep '^+' | cut -c2-
}

blanket_suppressions() { # stdin lines -> the ones with a suppression that names no code
  local line
  shopt -s nocasematch
  while IFS= read -r line; do
    if [[ $line =~ \#[[:space:]]*noqa && ! $line =~ \#[[:space:]]*noqa[[:space:]]*:[[:space:]]*[a-z]+[0-9]+ ]] ||
      [[ $line =~ \#[[:space:]]*type:[[:space:]]*ignore && ! $line =~ \#[[:space:]]*type:[[:space:]]*ignore[[:space:]]*\[ ]]; then
      printf '%s\n' "$line"
    fi
  done
  shopt -u nocasematch
}

report=""
for i in "${!files[@]}"; do
  f=${files[i]} part="" ruff_on=false ty_on=false
  tool_on ruff "$root/$f" && ruff_on=true
  tool_on ty "$root/$f" && ty_on=true
  if [[ ${#ruff[@]} -gt 0 && $ruff_on == true ]]; then
    if ! out=$("${ruff[@]}" check --no-fix --force-exclude -- "$f" 2>&1); then
      part+=$(printf '%s\nFix: %s check --fix %q' "$out" "${ruff[*]}" "$f")$'\n'
    fi
    if ! out=$("${ruff[@]}" format --check --force-exclude -- "$f" 2>&1); then
      part+=$(printf '%s\nFix: %s format %q' "$out" "${ruff[*]}" "$f")$'\n'
    fi
  fi
  if [[ ${#ty[@]} -gt 0 && $ty_on == true ]]; then
    if ! out=$("${ty[@]}" check -- "$f" 2>&1); then
      part+=$(printf '%s\nFix: fix the type error, then rerun: %s check %q' "$out" "${ty[*]}" "$f")$'\n'
    fi
  fi
  if [[ $ruff_on == true || $ty_on == true ]]; then
    found=$(added_lines "$f" "${olds[i]}" "${untracked[i]}" | blanket_suppressions)
    if [[ -n $found ]]; then
      part+=$(printf 'Blanket suppression added:\n%s\nFix: fix the finding, or name it with # noqa: <code> or # type: ignore[<code>]' "$found")$'\n'
    fi
  fi
  [[ -z $part ]] || report+="$f:"$'\n'"$part"
done

[[ -z $report ]] && exit 0
{
  printf 'Python checks failed on files changed in this repo:\n%s' "$report"
  printf 'Fix each finding. Do not silence one with a blanket # noqa or # type: ignore.\n'
} >&2
exit 2
