#!/usr/bin/env bash
# Takes a fresh Mac from nothing to a built nix-darwin config. Run this once;
# after it finishes, ./rebuild.sh handles every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
  cat <<'EOF'
Takes a fresh Mac from nothing to a built nix-darwin config. Run this once.
After it finishes, use ./rebuild.sh for every later change.

usage: ./bootstrap.sh [--user USERNAME]
  --user NAME  build a configuration other than the current user's. Defaults
               to whoever runs this.
EOF
}

# Resolve the target user before any sudo call: sudo rewrites $USER to root,
# so the real interactive user has to be captured first. SUDO_USER covers the
# case where this script itself was invoked with sudo.
TARGET_USER="${SUDO_USER:-$(id -un)}"
while [ $# -gt 0 ]; do
  case "$1" in
    -u | --user)
      TARGET_USER="${2:?--user needs a username}"
      shift 2
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
# Same substitution flake.nix makes: darwin-rebuild splits its flake attribute
# on ".", so a username with a dot in it is keyed with dashes instead.
TARGET_ATTR="${TARGET_USER//./-}"

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or the build will fail to find them.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: make sure flake.nix knows this username"
# The usernames live in a list, so a new machine is an addition rather than a
# swap. Nothing already in the list is touched.
if "$DIR/users.sh" has "$TARGET_USER"; then
  echo "    flake.nix already builds for \"$TARGET_USER\", nothing to do."
else
  echo "    flake.nix has no configuration for \"$TARGET_USER\" yet."
  read -r -p "    Add \"$TARGET_USER\" to the users list in flake.nix? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    "$DIR/users.sh" add "$TARGET_USER"
    echo "    Added. Review the change with: git diff flake.nix"
  else
    echo "    Skipped. Add \"$TARGET_USER\" to the users list in flake.nix,"
    echo "    or re-run with --user for a username that is already listed."
    exit 1
  fi
fi

echo "==> Step 4: first darwin-rebuild switch for \"$TARGET_USER\""
# darwin-rebuild doesn't exist yet on a fresh machine, so run it straight
# from the flake this once. After this, rebuild.sh works normally.
# This fetches the darwin-rebuild tool from the nix-darwin-26.05 release branch,
# not the exact flake.lock revision. The system config it applies is still pinned
# by this repo's flake.lock.
# sudo resets PATH to a secure default that excludes /nix/.../bin, so a
# freshly installed `nix` would not be found under sudo even though it's
# on PATH here. Resolve the absolute path first and invoke that instead.
NIX_BIN="$(command -v nix)"
sudo "$NIX_BIN" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake "$DIR#$TARGET_ATTR"
# If this still fails with "nix: command not found", open a new terminal
# (Determinate adds nix to new shells' PATH) and re-run ./bootstrap.sh.

echo "==> Done. Use ./rebuild.sh for future changes."
