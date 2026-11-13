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

section "a flake that imports the core's modules with the core checked out elsewhere"
if full_only && require nix; then
  checkout="/Volumes/src/core"
  fixture_consumer "dotfiles.git.email = \"fixture@example.org\";
    home-manager.users.\"$CONSUMER_USER\".dotfiles.checkout = \"$checkout\";"
  # shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
  consumer_home home.file --apply 'f: builtins.concatStringsSep "\n" (builtins.concatMap (n:
    let s = f.${n}.source; in
    if builtins.isAttrs s && s ? buildCommand && builtins.substring 0 6 s.buildCommand == "ln -s "
    then [ s.buildCommand ] else [ ]) (builtins.attrNames f))'
  if [ "$EV_RC" -ne 0 ] || [ -z "$EV_OUT" ]; then
    bad "its live links evaluate" "${EV_MSG:-no out-of-store links found}"
  else
    stray=""
    while read -r cmd; do
      target="${cmd#ln -s }"
      target="${target% \$out}"
      rel="${target#"$checkout"/}"
      if [ "$rel" = "$target" ]; then
        stray="$stray $target"
      elif [ ! -e "$DIR/$rel" ]; then
        stray="$stray $target(no $rel in the core)"
      fi
    done <<<"$EV_OUT"
    if [ -z "$stray" ]; then
      ok "every live link resolves under the checkout it set"
    else
      bad "every live link resolves under the checkout it set" "$stray"
    fi
  fi
  consumer_home home.activation.claudeSettings.data
  contains "Claude's settings merge reads the base from that checkout" \
    "$EV_OUT" "$checkout/home/.claude/settings.base.json"
fi

finish
