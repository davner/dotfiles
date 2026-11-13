#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets CONSUMER and EV_*
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "a flake that imports the core's modules"
if full_only && require nix; then
  fixture_consumer 'dotfiles.git.email = "fixture@example.org";'
  consumer_home programs.git.settings.user.email
  if [ "$EV_RC" -eq 0 ]; then
    eq "it commits as the email it set" "fixture@example.org" "$EV_OUT"
  else
    bad "it commits as the email it set" "$EV_MSG"
  fi
fi

section "a flake that imports the core's modules and sets no email"
if full_only && require nix; then
  fixture_consumer ''
  consumer_home programs.git.settings.user.email
  if [ "$EV_RC" -eq 0 ]; then
    bad "it refuses to guess an address" "evaluated to \"$EV_OUT\""
  else
    ok "it refuses to guess an address"
  fi
  eq "in one line that names the user and the option" \
    "no git email for \"$CONSUMER_USER\". Set dotfiles.git.email; this repo's own Macs take it from flake.nix's users." \
    "$EV_MSG"
fi

section "a flake that imports the core's modules and sets an empty email"
if full_only && require nix; then
  fixture_consumer 'dotfiles.git.email = "";'
  consumer_home programs.git.settings.user.email
  if [ "$EV_RC" -eq 0 ]; then
    bad "it treats the empty address as missing" "evaluated to \"$EV_OUT\""
  else
    ok "it treats the empty address as missing"
  fi
  eq "with the same one-line message" \
    "no git email for \"$CONSUMER_USER\". Set dotfiles.git.email; this repo's own Macs take it from flake.nix's users." \
    "$EV_MSG"
fi

finish
