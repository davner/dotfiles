#!/usr/bin/env bash
# Add-only and never fatal: a rebuild must not hinge on the marketplace.
set -uo pipefail

LIST="${1:?usage: extensions.sh <extensions.json>}"
CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
STORAGE="$HOME/Library/Application Support/Code/User/globalStorage/storage.json"

if [ ! -x "$CODE" ]; then
  echo "vscode-extensions: VS Code is not installed, skipping" >&2
  exit 0
fi

for profile in $(jq -r 'keys[]' "$LIST"); do
  flag=()
  if [ "$profile" != "Default" ]; then
    # The CLI would create it without Default's shared settings.
    if ! jq -e --arg p "$profile" '.userDataProfiles[]? | select(.name == $p)' "$STORAGE" >/dev/null 2>&1; then
      echo "vscode-extensions: no '$profile' profile; create it in VS Code sharing Default's settings" >&2
      continue
    fi
    flag=(--profile "$profile")
  fi
  have="$("$CODE" "${flag[@]}" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  for ext in $(jq -r --arg p "$profile" '.[$p][]' "$LIST"); do
    if ! grep -qx "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')" <<<"$have"; then
      echo "vscode-extensions: installing $ext into $profile"
      "$CODE" "${flag[@]}" --install-extension "$ext" >/dev/null 2>&1 ||
        echo "vscode-extensions: failed to install $ext into $profile" >&2
    fi
  done
done
exit 0
