#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "vscode user settings"
VS="$DIR/home/vscode"
if require jq; then
  for f in settings.base.json keybindings.base.json extensions.json; do
    if err="$(jq -e . "$VS/$f" 2>&1 >/dev/null)"; then ok "$f is valid JSON"; else bad "$f is valid JSON" "$err"; fi
  done
  # The merge appends keybindings and deep-merges settings, so the wrong shape fails at activation instead.
  if jq -e 'type == "object"' "$VS/settings.base.json" >/dev/null 2>&1 &&
    jq -e 'type == "array"' "$VS/keybindings.base.json" >/dev/null 2>&1; then
    ok "settings base is an object and keybindings base an array"
  else
    bad "settings base is an object and keybindings base an array" "home.nix merges them as deep and append-unique"
  fi
  if jq -e 'has("Default") and all(.[]; type == "array" and all(.[]; test("^[a-z0-9-]+\\.[a-z0-9-]+$"; "i")))' "$VS/extensions.json" >/dev/null 2>&1; then
    ok "extensions.json maps profiles to publisher.name ids"
  else
    bad "extensions.json maps profiles to publisher.name ids" "want {\"Default\": [\"pub.ext\", ...], ...}"
  fi
fi
if grep -q 'mkOutOfStoreSymlink.*Code/User' "$DIR/home.nix"; then
  bad "home.nix does not link VS Code's settings" "a link sends every settings-UI toggle back into this repo"
else
  ok "home.nix does not link VS Code's settings"
fi
# shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
if grep -q 'jsonMerge} --skip-invalid deep "${dotfiles}/home/vscode/settings\.base\.json"' "$DIR/home.nix" &&
  grep -q 'jsonMerge} --skip-invalid append-unique key,command,when "${dotfiles}/home/vscode/keybindings\.base\.json"' "$DIR/home.nix"; then
  ok "home.nix merges VS Code's settings and keybindings, skipping commented files"
else
  bad "home.nix merges VS Code's settings and keybindings, skipping commented files" \
    "want --skip-invalid deep for settings and --skip-invalid append-unique key,command,when for keybindings"
fi

finish
