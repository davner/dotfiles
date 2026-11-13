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

section "a flake that adds a skill and excludes two"
if full_only && require nix; then
  fixture_consumer "dotfiles.git.email = \"fixture@example.org\";
    home-manager.users.\"$CONSUMER_USER\".dotfiles.skills = {
      extra.fixture-extra = ./fixture-extra;
      exclude = [ \"grilling\" \"humanizer\" ];
    };"
  mkdir -p "$CONSUMER/fixture-extra"
  printf -- '---\nname: fixture-extra\n---\n' >"$CONSUMER/fixture-extra/SKILL.md"
  skill_links='f: builtins.concatStringsSep "\n" (builtins.filter (n: builtins.match "\\.(claude|agents)/skills/[^/]+" n != null) (builtins.attrNames f))'
  consumer_home home.file --apply "$skill_links"
  if [ "$EV_RC" -eq 0 ]; then
    links="$EV_OUT"
    contains "the extra skill is linked into .claude/skills" "$links" ".claude/skills/fixture-extra"
    contains "and into .agents/skills" "$links" ".agents/skills/fixture-extra"
    # Read through Nix, since lazy trees can leave the store path unmaterialised on disk.
    # shellcheck disable=SC2016  # the ${} is Nix interpolation, not shell
    consumer_home 'home.file.".claude/skills/fixture-extra".source' --apply 'p: builtins.readFile "${p}/SKILL.md"'
    contains "from the folder the consumer named" "$EV_OUT$EV_MSG" "name: fixture-extra"
    if grep -qE '^\.claude/skills/grilling$' <<<"$links"; then
      bad "the excluded core skill is not linked" "$links"
    else
      ok "the excluded core skill is not linked"
    fi
    if grep -qE '^\.(claude|agents)/skills/humanizer$' <<<"$links"; then
      bad "the excluded third-party skill is linked in neither folder" "$links"
    else
      ok "the excluded third-party skill is linked in neither folder"
    fi
    contains "the skills it kept are still linked" "$links" ".claude/skills/tdd"
  else
    bad "its skill links evaluate" "$EV_MSG"
  fi
fi

section "a flake that excludes a skill the core does not have"
if full_only && require nix; then
  fixture_consumer "dotfiles.git.email = \"fixture@example.org\";
    home-manager.users.\"$CONSUMER_USER\".dotfiles.skills.exclude = [ \"no-such-skill\" ];"
  consumer_home home.file --apply 'f: builtins.concatStringsSep "\n" (builtins.attrNames f)'
  if [ "$EV_RC" -eq 0 ]; then
    bad "it fails instead of ignoring the name" "evaluated"
  else
    ok "it fails instead of ignoring the name"
  fi
  contains "with a message that names the skill and the option" "$EV_MSG" \
    'dotfiles.skills.exclude names "no-such-skill"'
fi

finish
