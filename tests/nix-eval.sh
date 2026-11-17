#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "flake evaluation"
if full_only && require nix; then
  attrs="$(nix eval --json "$DIR#darwinConfigurations" --apply builtins.attrNames 2>"$WORK/stderr")"
  eq "one configuration, #danavner" '["danavner"]' "$attrs"

  got="$(nix eval --raw "$DIR#darwinConfigurations.danavner.config" --apply \
    'c: builtins.concatStringsSep "\n" [
       c.system.primaryUser
       c.users.users.danavner.home
       c.home-manager.backupFileExtension
       c.home-manager.users.danavner.home.username
       c.home-manager.users.danavner.home.homeDirectory
       c.home-manager.users.danavner.programs.git.settings.user.email
     ]' 2>"$WORK/stderr")"
  if [ -z "$got" ]; then
    bad "#danavner evaluates" "$(grep -v '^warning:' "$WORK/stderr" | head -5)"
  else
    eq "#danavner is wired to danavner end to end" "danavner
/Users/danavner
backup
danavner
/Users/danavner
ldpavner@gmail.com" "$got"
  fi

  section "homebrew activation"
  # Asserts the brew bundle line and Brewfile that activation runs, not the
  # options behind them, since a harmless-looking option can change either.
  brewscript="$(nix eval --raw \
    "$DIR#darwinConfigurations.danavner.config.system.activationScripts.homebrew.text" \
    2>"$WORK/stderr")"
  brewcmd="$(printf '%s\n' "$brewscript" | grep 'brew bundle')"
  # Auto-update re-runs nix-homebrew's wrapper, which loses PATH, so bundle cannot find mas.
  order="$(printf '%s\n' "$brewscript" |
    grep -oE 'setting up Homebrew prefixes|/bin/brew" update|brew bundle' | awk '!seen[$0]++' | tr '\n' '|')"
  if [ "$order" = 'setting up Homebrew prefixes|/bin/brew" update|brew bundle|' ]; then
    ok "brew update runs after the prefix setup and before brew bundle"
  else
    bad "brew update runs after the prefix setup and before brew bundle" "got: $order"
  fi
  if [ -z "$brewcmd" ]; then
    bad "the activation script runs brew bundle" "$(grep -v '^warning:' "$WORK/stderr" | head -3)"
  else
    contains "cleanup=zap reaches brew as --zap --force-cleanup" "$brewcmd" "--zap --force-cleanup"
    # cleanup=zap emits --force-cleanup, which is fine; a bare --force stops brew
    # adding --adopt, which turns every cask install into an overwrite.
    if printf '%s' "$brewcmd" | grep -qE ' --force($| )'; then
      bad "no bare --force (it would suppress --adopt)" "$brewcmd"
    else
      ok "no bare --force (it would suppress --adopt)"
    fi
    contains "HOMEBREW_NO_* is set, since activation does not inherit the shell" \
      "$brewcmd" "HOMEBREW_NO_ANALYTICS=1"
    contains "brew bundle does not auto-update" "$brewcmd" "HOMEBREW_NO_AUTO_UPDATE=1"
  fi

  brewfile="$(nix eval --raw \
    "$DIR#darwinConfigurations.danavner.config.homebrew.brewfile" 2>"$WORK/stderr")"
  if [ -z "$brewfile" ]; then
    bad "the Brewfile evaluates" "$(grep -v '^warning:' "$WORK/stderr" | head -3)"
  else
    # greedy makes upgrade reach an auto_updates cask; neither of these updates
    # itself, so greedy here would only race their own updaters.
    for c in wezterm claude-code@latest; do
      if printf '%s' "$brewfile" | grep -qE "cask \"$c\".*greedy"; then
        bad "$c is not greedy" "greedy on a cask that does not self-update races its own updater"
      else
        ok "$c is not greedy"
      fi
    done
  fi
fi

finish
