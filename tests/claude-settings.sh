#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "claude user settings"
# /config, /model and /effort write ~/.claude/settings.json, so it is merged in, not
# linked: a link routes those writes into this working tree.
if [ -f "$BASE" ]; then ok "settings.base.json exists"; else bad "settings.base.json exists" "$BASE"; fi
if require jq; then
  if err="$(jq -e . "$BASE" 2>&1 >/dev/null)"; then
    ok "settings.base.json is valid JSON"
  else
    bad "settings.base.json is valid JSON" "$err"
  fi
  # Base wins the merge, so any of these three here is reverted on every
  # rebuild - the same fight, just losing in the other direction.
  volatile="$(jq -r '[paths(scalars) | .[0]] | unique | map(select(. == "model" or . == "effortLevel" or . == "theme")) | join(" ")' "$BASE")"
  if [ -z "$volatile" ]; then
    ok "settings.base.json claims none of model, effortLevel, theme"
  else
    bad "settings.base.json claims none of model, effortLevel, theme" \
      "these would be reverted on every rebuild: $volatile"
  fi
  # Work-only: the private layer adds the obsidian plugin through a settings fragment.
  if jq -e '(.extraKnownMarketplaces // {} | has("obsidian-skills"))
      or (.enabledPlugins // {} | has("obsidian@obsidian-skills"))' "$BASE" >/dev/null 2>&1; then
    bad "settings.base.json declares no obsidian plugin" \
      "extraKnownMarketplaces.obsidian-skills or enabledPlugins.obsidian@obsidian-skills is still there"
  else
    ok "settings.base.json declares no obsidian plugin"
  fi
  # A hook on the wrong event or matcher never fires, and nothing says so. The
  # gate must match Skill, its only evidence of a load; "-" is no matcher.
  rows=0
  while read -r ev matcher script; do
    [ -n "$ev" ] || continue
    rows=$((rows + 1))
    if jq -e --arg ev "$ev" --arg m "$matcher" --arg s "$script" '
        if $ev == "statusLine" then [.statusLine.command]
        else [.hooks[$ev][]? | select((.matcher // "-") == $m) | .hooks[]?.command] end
        | map(select(contains($s))) | length == 1' "$BASE" >/dev/null 2>&1; then
      ok "settings.base.json runs $script on $ev ($matcher)"
    else
      bad "settings.base.json runs $script on $ev ($matcher)" "want exactly one such command"
    fi
  done <<'HOOKS'
SessionStart  -                               ~/.claude/hooks/session-name.sh --hook
SessionStart  -                               skills/impeccable/scripts/impeccable
PreToolUse    Bash                            $HOME/.claude/hooks/guard-bash.sh
PreToolUse    Skill|Write|Edit|MultiEdit|Bash $HOME/.claude/hooks/skill-gate.sh
PostToolUse   Write|Edit|MultiEdit            $HOME/.claude/hooks/comment-audit.sh
PostToolUse   Edit|Write                      skills/impeccable/scripts/impeccable
Stop          -                               skills/impeccable/scripts/impeccable
statusLine    -                               ~/.claude/hooks/statusline.sh
HOOKS
  eq "the table above covers every command settings.base.json runs" "$rows" \
    "$(jq '[.. | objects | .command? // empty] | length' "$BASE")"
  # A soft fence: Claude's read-only GitHub token is the hard limit, and these
  # rules only make Claude work around them on purpose to reach the owner's.
  while read -r rule; do
    [ -n "$rule" ] || continue
    if jq -e --arg r "$rule" '.permissions.deny // [] | index($r) != null' "$BASE" >/dev/null 2>&1; then
      ok "settings.base.json denies $rule"
    else
      bad "settings.base.json denies $rule" "missing from permissions.deny"
    fi
  done <<'DENY'
Bash(git push *--force*)
Bash(git push -f *)
Bash(git push * -f)
Bash(git push * -f *)
Bash(git push * +*)
Bash(gh pr merge *)
Bash(gh repo delete *)
Read(~/.ssh/**)
Bash(security find-*)
Bash(gh auth token *)
Bash(unset *GH_TOKEN*)
Bash(env *GH_TOKEN*)
DENY
  # Claude Code's documented matching; a rule that also catches everyday git
  # or gh work would just get switched off.
  denied_by() {
    local cmd="$1" rule pat
    while IFS= read -r rule; do
      pat="${rule#Bash(}"
      [ "$pat" != "$rule" ] || continue
      pat="${pat%)}"
      # shellcheck disable=SC2053  # $pat is a glob on purpose
      if [[ $cmd == $pat ]]; then printf '%s\n' "$rule"; return; fi
      if [[ $pat == *' *' && ${pat%' *'} != *'*'* && $cmd == "${pat%' *'}" ]]; then
        printf '%s\n' "$rule"; return
      fi
    done < <(jq -r '.permissions.deny // [] | .[]' "$BASE")
  }
  while IFS='|' read -r want cmd; do
    [ -n "$want" ] || continue
    got="$(denied_by "$cmd")"
    if [ "$want" = deny ] && [ -n "$got" ]; then
      ok "denied: $cmd"
    elif [ "$want" = allow ] && [ -z "$got" ]; then
      ok "not denied: $cmd"
    elif [ "$want" = deny ]; then
      bad "denied: $cmd" "no deny rule matches"
    else
      bad "not denied: $cmd" "matched by $got"
    fi
  done <<'CMDS'
deny|git push --force
deny|git push --force origin main
deny|git push origin main --force-with-lease
deny|git push -f
deny|git push -f origin main
deny|git push origin main -f
deny|git push origin -f main
deny|git push origin +main
deny|gh pr merge
deny|gh pr merge 12 --squash
deny|gh repo delete davner/x --yes
deny|security find-generic-password -s claude-gh-token -w
deny|security find-internet-password -s github.com
deny|gh auth token
deny|gh auth token --hostname github.com
deny|unset GH_TOKEN
deny|unset FOO GH_TOKEN
deny|env -u GH_TOKEN gh pr create
deny|env --unset=GH_TOKEN gh pr list
allow|git push
allow|git push origin main
allow|git push -u origin feature-flag
allow|git push origin fix-f
allow|git push --set-upstream origin my-branch
allow|git push --tags
allow|git status
allow|gh pr view 12
allow|gh pr list
allow|gh pr checks
allow|gh pr create --fill
allow|gh repo view
allow|gh auth status
allow|security list-keychains
allow|security add-generic-password -s claude-gh-token -w
allow|env
allow|unset FOO
CMDS
fi
if grep -q 'mkOutOfStoreSymlink.*\.claude/settings\.json' "$DIR/home.nix"; then
  bad "home.nix does not link settings.json" \
    "a link there sends every /config write back into this repo"
else
  ok "home.nix does not link settings.json"
fi
# The merge itself is tested in tests/json-merge.sh; this is the one call site.
# shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
if grep -q 'jsonMerge} --drop-link\(${claudeFragmentArgs}\)\? deep "${dotfiles}/home/\.claude/settings\.base\.json"' "$DIR/home.nix"; then
  ok "home.nix merges settings.base.json, failing on invalid JSON"
else
  bad "home.nix merges settings.base.json, failing on invalid JSON" \
    "want --drop-link deep and no --skip-invalid: a broken settings.json must stop the rebuild"
fi

# shellcheck disable=SC2154  # lib.sh sets CONSUMER
fragments_eval() { # -> sets EV_RC, EV_OUT (each fragment the merge step folds in, as a JSON array), EV_MSG
  local script drv f
  EV_RC=0
  EV_OUT=""
  script="$(nix eval --json --no-write-lock-file --override-input core "git+file://$DIR" \
    "$CONSUMER#darwinConfigurations.fixture.config.home-manager.users.\"$CONSUMER_USER\".home.activation.claudeSettings.data" \
    --apply 'data: { inherit data; drvs = builtins.attrNames (builtins.getContext data); }' 2>"$WORK/stderr")" || EV_RC=$?
  EV_MSG="$(grep -E '^ *error: .' "$WORK/stderr" | tail -n 1 | sed 's/^ *error: //')"
  [ "$EV_RC" -eq 0 ] || return
  # Built so the files the script names exist to be read.
  while IFS= read -r drv; do
    nix build --no-link "$drv^out" 2>"$WORK/stderr" || { EV_RC=1; EV_MSG="$(tail -n 1 "$WORK/stderr")"; return; }
  done < <(jq -r '.drvs[] | select(endswith("-claude-settings-fragment.json.drv"))' <<<"$script")
  while IFS= read -r f; do
    EV_OUT="$EV_OUT$(cat "$f")"
  done < <(jq -r '.data | [scan("--extend ([^ ]+)")[0]] | .[]' <<<"$script")
  EV_OUT="$(jq -cs . <<<"$EV_OUT")"
}

section "a flake that imports the core's modules and adds Claude settings fragments"
if full_only && require nix jq; then
  fixture_consumer '
    dotfiles.git.email = "fixture@example.org";
    home-manager.users."'"$CONSUMER_USER"'".dotfiles.claude.settingsFragments = [
      { enabledPlugins."p@m" = true; }
      { permissions.deny = [ "Bash(wget *)" ]; }
    ];'
  fragments_eval
  if [ "$EV_RC" -eq 0 ]; then
    eq "the merge step folds in each fragment, in order" \
      '[{"enabledPlugins":{"p@m":true}},{"permissions":{"deny":["Bash(wget *)"]}}]' "$EV_OUT"
  else
    bad "the merge step folds in each fragment, in order" "$EV_MSG"
  fi
fi

section "a flake that imports the core's modules and adds a fragment claiming /config's keys"
if full_only && require nix jq; then
  fixture_consumer '
    dotfiles.git.email = "fixture@example.org";
    home-manager.users."'"$CONSUMER_USER"'".dotfiles.claude.settingsFragments = [
      { enabledPlugins."p@m" = true; }
      { theme = "dark"; model = "opus"; }
    ];'
  fragments_eval
  if [ "$EV_RC" -eq 0 ]; then
    bad "it is refused at build time" "evaluated to $EV_OUT"
  else
    ok "it is refused at build time"
  fi
  eq "in one line that names the keys and why" \
    "a Claude settings fragment sets model, theme; /config owns those, and the merge would revert them on every rebuild (ADR 0007)." \
    "$EV_MSG"
fi

finish
