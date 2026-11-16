#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "bootstrap.sh"
run "$DIR/bootstrap.sh"
eq "bootstrap.sh exits 0" "0" "$RUN_RC"
eq "bootstrap.sh builds #danavner from the flake directly" \
  "$STUB/nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake $DIR#danavner" \
  "$SUDO_ARGS"
eq "bootstrap.sh points ~/.dotfiles at this checkout" "$DIR" "$(readlink "$FAKEHOME/.dotfiles")"

run "$DIR/bootstrap.sh" --nonsense
eq "bootstrap.sh unknown flag exits 2" "2" "$RUN_RC"
eq "bootstrap.sh unknown flag never reaches sudo" "" "$SUDO_ARGS"

finish
