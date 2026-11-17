#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "rebuild.sh"
run "$DIR/rebuild.sh"
eq "rebuild.sh exits 0" "0" "$RUN_RC"
eq "rebuild.sh builds #danavner" "darwin-rebuild switch --flake $DIR#danavner" "$SUDO_ARGS"
eq "rebuild.sh runs darwin-rebuild only through sudo" "" "$DR_ARGS"
eq "rebuild.sh points ~/.dotfiles at this checkout" "$DIR" "$(readlink "$FAKEHOME/.dotfiles")"

run "$DIR/rebuild.sh" --build
eq "--build exits 0" "0" "$RUN_RC"
eq "--build builds instead of switching" "build --flake $DIR#danavner" "$DR_ARGS"
eq "--build never asks for sudo" "" "$SUDO_ARGS"
run "$DIR/rebuild.sh" -b
eq "-b is the same as --build" "build --flake $DIR#danavner" "$DR_ARGS"

run "$DIR/rebuild.sh" --nonsense
eq "unknown flag exits 2" "2" "$RUN_RC"
eq "unknown flag never reaches sudo" "" "$SUDO_ARGS"

finish
