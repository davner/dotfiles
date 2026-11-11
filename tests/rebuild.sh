#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "rebuild.sh"
fixture_users
while read -r u; do
  attr="${u//./-}"
  run env -u SUDO_USER "$DIR/rebuild.sh" --user "$u"
  eq "rebuild.sh --user $u exits 0" "0" "$RUN_RC"
  eq "rebuild.sh --user $u builds #$attr" \
    "darwin-rebuild switch --flake $DIR#$attr" "$SUDO_ARGS"
  eq "rebuild.sh --user $u runs darwin-rebuild only through sudo" "" "$DR_ARGS"
done <<<"$listed"

run env -u SUDO_USER "$DIR/rebuild.sh" --user "$first" --build
eq "--build exits 0" "0" "$RUN_RC"
eq "--build builds instead of switching" \
  "build --flake $DIR#${first//./-}" "$DR_ARGS"
eq "--build never asks for sudo" "" "$SUDO_ARGS"
run env -u SUDO_USER "$DIR/rebuild.sh" -b --user "$first"
eq "-b is the same as --build" "build --flake $DIR#${first//./-}" "$DR_ARGS"

run env -u SUDO_USER "$DIR/rebuild.sh" --user "$first"
eq "rebuild.sh points ~/.dotfiles at this checkout" "$DIR" "$(readlink "$FAKEHOME/.dotfiles")"

run env "SUDO_USER=$first" "$DIR/rebuild.sh"
eq "rebuild.sh under sudo uses SUDO_USER, not root" \
  "darwin-rebuild switch --flake $DIR#${first//./-}" "$SUDO_ARGS"

me="$(id -un)"
if "$DIR/users.sh" has "$me" 2>/dev/null; then
  run env -u SUDO_USER "$DIR/rebuild.sh"
  eq "rebuild.sh with no arguments builds the current user" \
    "darwin-rebuild switch --flake $DIR#${me//./-}" "$SUDO_ARGS"
else
  skip "no-argument default ($me is not in the users attrset)"
fi

run env -u SUDO_USER "$DIR/rebuild.sh" --user no-such-user
eq "unlisted user fails before building" "1" "$RUN_RC"
eq "unlisted user never reaches sudo" "" "$SUDO_ARGS"
contains "unlisted user error lists the valid names" "$RUN_ERR" "$first"

run env -u SUDO_USER "$DIR/rebuild.sh" --nonsense
eq "unknown flag exits 2" "2" "$RUN_RC"
eq "unknown flag never reaches sudo" "" "$SUDO_ARGS"

run env -u SUDO_USER "$DIR/rebuild.sh" --user
if [ "$RUN_RC" -ne 0 ]; then ok "--user with no value fails"; else bad "--user with no value fails" "exited 0"; fi
eq "--user with no value never reaches sudo" "" "$SUDO_ARGS"

finish
