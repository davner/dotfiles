#!/usr/bin/env bash
# Rebuild and switch to this repo's nix-darwin config. Run --help for options.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
  cat <<'EOF'
Rebuild and switch to this repo's nix-darwin config.

usage: ./rebuild.sh [--build]
  --build      build only. No sudo and no change to this Mac: it prints what a
               switch would add, remove and resize, then stops.
EOF
}

ACTION="switch"
while [ $# -gt 0 ]; do
  case "$1" in
    -b | --build)
      ACTION="build"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles.
ln -sfn "$DIR" ~/.dotfiles

CURRENT=""
[ -e /run/current-system ] && CURRENT="$(readlink /run/current-system)"

# The question every rebuild leaves behind: what actually changed? Prints
# nothing when the two closures are identical, so a no-op rebuild stays quiet.
show_diff() { # label store-path
  local out
  [ -n "$CURRENT" ] && [ -n "$2" ] || return 0
  out="$(nix store diff-closures "$CURRENT" "$2" 2>/dev/null)" || return 0
  [ -n "$out" ] || return 0
  printf '\n%s\n%s\n' "$1" "$out"
}

if [ "$ACTION" = "build" ]; then
  # ./result lands in the repo, where .gitignore already covers it.
  cd "$DIR"
  darwin-rebuild build --flake "$DIR#danavner"
  if [ -e "$DIR/result" ]; then
    show_diff "a switch would change:" "$(readlink "$DIR/result")"
  fi
else
  sudo darwin-rebuild switch --flake "$DIR#danavner"
  show_diff "this rebuild changed:" "$(readlink /run/current-system)"
fi
