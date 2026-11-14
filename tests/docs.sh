#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "installed page"
PAGE="$DIR/docs/installed.md"
# The page is how a human learns what lands on the machine, and nothing else
# notices when a package is added without a line there.
packages="$(awk '/home\.packages = with pkgs; \[/{f=1; next} f && /^ *\];/{exit} f' "$DIR/home.nix" |
  sed -E 's/#.*//; s/^ +//; s/ +$//' | grep -v '^$')"
casks="$(awk '/^ *(brews|casks) = \[/{f=1; next} f && /^ *\];/{f=0} f' "$DIR/configuration.nix" |
  sed -nE 's/^ *"([^"]+)".*/\1/p')"
unnamed() { # names -> those the page does not name in backticks
  local n
  for n in $1; do grep -qF "\`$n\`" "$PAGE" 2>/dev/null || printf '%s ' "$n"; done
}
inventory() { # check name, what the list holds, names
  local missing
  if [ -z "$3" ]; then
    bad "$1" "read no $2 from the Nix files; has their layout changed?"
    return
  fi
  missing="$(unnamed "$3")"
  if [ -z "$missing" ]; then
    ok "$1"
  else
    bad "$1" "not in docs/installed.md as \`name\`: $missing"
  fi
}
inventory "docs/installed.md names every package" "home.packages" "$packages"
inventory "docs/installed.md names every brew and cask" "brews or casks" "$casks"

finish
