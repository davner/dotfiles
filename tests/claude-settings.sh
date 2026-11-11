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
  # Nothing in home.nix installs the obsidian skills; Claude Code does, from these keys.
  if jq -e '.extraKnownMarketplaces["obsidian-skills"].autoUpdate == true
      and .enabledPlugins["obsidian@obsidian-skills"] == true' "$BASE" >/dev/null 2>&1; then
    ok "settings.base.json declares and enables the obsidian plugin"
  else
    bad "settings.base.json declares and enables the obsidian plugin" \
      "want extraKnownMarketplaces.obsidian-skills.autoUpdate and enabledPlugins.obsidian@obsidian-skills both true"
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
fi
if grep -q 'mkOutOfStoreSymlink.*\.claude/settings\.json' "$DIR/home.nix"; then
  bad "home.nix does not link settings.json" \
    "a link there sends every /config write back into this repo"
else
  ok "home.nix does not link settings.json"
fi
# The merge itself is tested in tests/json-merge.sh; this is the one call site.
# shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
if grep -q 'jsonMerge} --drop-link deep "${dotfiles}/home/\.claude/settings\.base\.json"' "$DIR/home.nix"; then
  ok "home.nix merges settings.base.json, failing on invalid JSON"
else
  bad "home.nix merges settings.base.json, failing on invalid JSON" \
    "want --drop-link deep and no --skip-invalid: a broken settings.json must stop the rebuild"
fi

finish
