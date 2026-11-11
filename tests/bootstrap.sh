#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "bootstrap.sh"
fixture_users
run env -u SUDO_USER "$DIR/bootstrap.sh" --user "$first"
eq "bootstrap.sh --user $first exits 0" "0" "$RUN_RC"
eq "bootstrap.sh builds #${first//./-} from the flake directly" \
  "$STUB/nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake $DIR#${first//./-}" \
  "$SUDO_ARGS"
contains "bootstrap.sh skips a username already configured" "$RUN_OUT" "nothing to do"

sum_flake="$(shasum "$DIR/flake.nix" | cut -d' ' -f1)"
run env -u SUDO_USER "$DIR/bootstrap.sh" --user brand-new-user
eq "declining the prompt exits 1" "1" "$RUN_RC"
eq "declining the prompt leaves flake.nix untouched" "$sum_flake" \
  "$(shasum "$DIR/flake.nix" | cut -d' ' -f1)"
eq "declining the prompt never reaches sudo" "" "$SUDO_ARGS"

run env -u SUDO_USER "$DIR/bootstrap.sh" --nonsense
eq "bootstrap.sh unknown flag exits 2" "2" "$RUN_RC"
eq "bootstrap.sh unknown flag never reaches sudo" "" "$SUDO_ARGS"

finish
