#!/usr/bin/env bash
# Rebuild and switch to this repo's nix-darwin config. Run --help for options.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
  cat <<'EOF'
Rebuild and switch to this repo's nix-darwin config.

usage: ./rebuild.sh [--user USERNAME] [--build]
  --user NAME  build a configuration other than the current user's. Defaults
               to whoever runs this.
  --build      build only. No sudo and no change to this Mac: it prints what a
               switch would add, remove and resize, then stops.
EOF
}

# Resolve the user before sudo runs, since sudo rewrites $USER to root.
# SUDO_USER covers `sudo ./rebuild.sh`.
TARGET_USER="${SUDO_USER:-$(id -un)}"
ACTION="switch"
while [ $# -gt 0 ]; do
  case "$1" in
    -u | --user)
      TARGET_USER="${2:?--user needs a username}"
      shift 2
      ;;
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

# Fail here rather than 90 seconds into a build that ends in
# "primary user does not exist" at activation time.
if ! "$DIR/users.sh" has "$TARGET_USER"; then
  echo "flake.nix has no configuration for \"$TARGET_USER\"." >&2
  echo "Add it to the users attrset in flake.nix (./bootstrap.sh offers to)," >&2
  echo "or pass --user with one of these:" >&2
  "$DIR/users.sh" list | sed 's/^/  /' >&2
  exit 1
fi

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

# Dots are not legal in a flake attribute path, so they are dashes there.
ATTR="${TARGET_USER//./-}"

if [ "$ACTION" = "build" ]; then
  # ./result lands in the repo, where .gitignore already covers it.
  cd "$DIR"
  darwin-rebuild build --flake "$DIR#$ATTR"
  if [ -e "$DIR/result" ]; then
    show_diff "a switch would change:" "$(readlink "$DIR/result")"
  fi
else
  sudo darwin-rebuild switch --flake "$DIR#$ATTR"
  show_diff "this rebuild changed:" "$(readlink /run/current-system)"
fi
