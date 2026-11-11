#!/usr/bin/env bash
# The direnv extension loads one .envrc per window; metals.javaHome is the per-folder escape.
set -uo pipefail

usage() {
  echo "usage: metals-java-home <folder | .code-workspace>..." >&2
  exit 2
}
[ $# -gt 0 ] || usage

folders=()
for arg in "$@"; do
  case "$arg" in
  *.code-workspace)
    [ -f "$arg" ] || { echo "metals-java-home: $arg: no such file" >&2; exit 1; }
    base="$(cd "$(dirname "$arg")" && pwd -P)"
    if ! paths="$(jq -r '.folders[].path' "$arg" 2>/dev/null)"; then
      echo "metals-java-home: $arg is not plain JSON, skipped" >&2
      continue
    fi
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      case "$p" in /*) folders+=("$p") ;; *) folders+=("$base/$p") ;; esac
    done <<<"$paths"
    ;;
  *) folders+=("$arg") ;;
  esac
done

status=0
for dir in "${folders[@]}"; do
  [ -d "$dir" ] || { echo "metals-java-home: $dir: no such folder" >&2; status=1; continue; }
  dir="$(cd "$dir" && pwd -P)"
  name="$(basename "$dir")"
  [ -f "$dir/.envrc" ] || { echo "$name: no .envrc, skipped"; continue; }
  jh="$(direnv exec "$dir" printenv JAVA_HOME 2>/dev/null)"
  if [ -z "$jh" ] || [ ! -d "$jh" ]; then
    echo "$name: its direnv sets no JAVA_HOME, skipped"
    continue
  fi
  settings="$dir/.vscode/settings.json"
  # A tracked file would publish this machine's /nix/store path to the team.
  if git -C "$dir" ls-files --error-unmatch .vscode/settings.json >/dev/null 2>&1; then
    echo "metals-java-home: $name: .vscode/settings.json is tracked by git, skipped" >&2
    status=1
    continue
  fi
  mkdir -p "$dir/.vscode"
  [ -f "$settings" ] || printf '{}\n' >"$settings"
  if ! merged="$(jq --arg jh "$jh" '. + {"metals.javaHome": $jh}' "$settings" 2>/dev/null)"; then
    echo "metals-java-home: $name: .vscode/settings.json is not plain JSON, skipped" >&2
    status=1
    continue
  fi
  printf '%s\n' "$merged" >"$settings"
  echo "$name: metals.javaHome = $jh"
done
exit "$status"
