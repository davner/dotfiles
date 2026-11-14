#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "flake evaluation"
if full_only && require nix; then
  fixture_users
  attrs="$(nix eval --json "$DIR#darwinConfigurations" --apply builtins.attrNames 2>"$WORK/stderr" \
    | tr -d '[]" ' | tr ',' '\n' | sort)"
  if [ -z "$attrs" ]; then
    bad "darwinConfigurations evaluates" "$(cat "$WORK/stderr")"
  else
    eq "one configuration per listed username, and nothing else" \
      "$(printf '%s\n' "$listed" | tr '.' '-' | sort)" "$attrs"
  fi

  while read -r u; do
    attr="${u//./-}"
    got="$(nix eval --raw "$DIR#darwinConfigurations.$attr.config" --apply \
      "c: builtins.concatStringsSep \"\\n\" [
         c.system.primaryUser
         c.users.users.\"$u\".home
         c.home-manager.backupFileExtension
         c.home-manager.users.\"$u\".home.username
         c.home-manager.users.\"$u\".home.homeDirectory
       ]" 2>"$WORK/stderr")"
    if [ -z "$got" ]; then
      bad "#$attr evaluates" "$(grep -v '^warning:' "$WORK/stderr" | head -5)"
    else
      eq "#$attr is wired to $u end to end" "$u
/Users/$u
backup
$u
/Users/$u" "$got"
    fi

    # home.nix throws for a user record with no address in it, so this failing
    # means a machine was added to the users attrset and left without an email.
    email="$(nix eval --raw \
      "$DIR#darwinConfigurations.$attr.config.home-manager.users.\"$u\".programs.git.settings.user.email" \
      2>"$WORK/stderr")"
    case "$email" in
      *@*.*) ok "#$attr commits as $email" ;;
      *) bad "#$attr has a git address" "$(grep -v '^warning:' "$WORK/stderr" | head -3)" ;;
    esac
    # A consumer flake defines it, and a second definition here would be a
    # home-manager conflict.
    has_mjh="$(nix eval --json \
      "$DIR#darwinConfigurations.$attr.config.home-manager.users.\"$u\".home.file" \
      --apply 'f: f ? ".local/bin/metals-java-home"' 2>"$WORK/stderr")"
    eq "#$attr links no metals-java-home" "false" "$has_mjh"
  done <<<"$listed"

  section "a record users.sh add wrote, before anyone fills it in"
  # bootstrap.sh switches against an empty record; configuration.nix defaults
  # hostPlatform so the missing-address throw is not buried under a stack trace.
  fixture_copy
  "$DIR/users.sh" add new.user "$COPY" >/dev/null 2>&1
  FLAKECOPY="$WORK/flakecopy"
  # home.nix reads these folders at eval time; every other home/ path is a string.
  mkdir -p "$FLAKECOPY/home/.claude/skills" "$FLAKECOPY/home/.claude/hooks" "$FLAKECOPY/home/.claude/rules"
  cp "$COPY" "$FLAKECOPY/flake.nix"
  cp "$DIR/flake.lock" "$DIR/configuration.nix" "$DIR/home.nix" "$FLAKECOPY/"

  ev() { # attribute path -> nix eval it, with stderr captured
    EV_RC=0
    EV_OUT="$(nix eval --raw --no-write-lock-file "$FLAKECOPY#$1" 2>"$WORK/stderr")" || EV_RC=$?
    EV_ERR="$(grep -v '^warning:' "$WORK/stderr")"
  }

  ev 'darwinConfigurations.new-user.config.nixpkgs.hostPlatform.system'
  eq "an empty record still picks a platform" "aarch64-darwin" "$EV_OUT"

  ev 'darwinConfigurations.new-user.config.home-manager.users."new.user".programs.git.settings.user.email'
  if [ "$EV_RC" -eq 0 ]; then
    bad "an empty record refuses to guess an address" "evaluated to \"$EV_OUT\""
  else
    ok "an empty record refuses to guess an address"
  fi
  contains "and says whose address is missing" "$EV_ERR" 'no git email for "new.user"'
  contains "and says where to put it" "$EV_ERR" "flake.nix's users"

  # Optional fields let an empty record reach the throw above, so a misspelled
  # `sytem` would silently build for the wrong platform unless it is rejected.
  sed 's/system = "aarch64-darwin"/sytem = "aarch64-darwin"/' "$COPY" \
    >"$FLAKECOPY/flake.nix"
  ev 'darwinConfigurations.danavner.config.nixpkgs.hostPlatform.system'
  if [ "$EV_RC" -eq 0 ]; then
    bad "a misspelled field is rejected, not ignored" \
      "sytem was accepted and the platform silently became \"$EV_OUT\""
  else
    ok "a misspelled field is rejected, not ignored"
  fi
  contains "and names the field that is wrong" "$EV_ERR" "sytem"
  contains "and names the user it is wrong on" "$EV_ERR" '"danavner"'
  cp "$COPY" "$FLAKECOPY/flake.nix"

  section "homebrew activation"
  # Asserts the brew bundle line and Brewfile that activation runs, not the
  # options behind them, since a harmless-looking option can change either.
  first_attr="$(printf '%s\n' "$listed" | head -n1 | tr '.' '-')"
  brewcmd="$(nix eval --raw \
    "$DIR#darwinConfigurations.$first_attr.config.system.activationScripts.homebrew.text" \
    2>"$WORK/stderr" | grep 'brew bundle')"
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
  fi

  brewfile="$(nix eval --raw \
    "$DIR#darwinConfigurations.$first_attr.config.homebrew.brewfile" 2>"$WORK/stderr")"
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
