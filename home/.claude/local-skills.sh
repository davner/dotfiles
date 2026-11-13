#!/usr/bin/env bash
# Installs impeccable, which no flake input can carry: it downloads an engine
# and writes agents into its own folder. home.nix runs this on every rebuild.
set -u

skills="$HOME/.claude/skills"
mkdir -p "$skills"

warn() { printf 'local-skills: %s\n' "$1" >&2; }

# --no-hooks because the settings merge would drop them; settings.base.json
# carries impeccable's hooks instead.
if [ ! -f "$skills/impeccable/SKILL.md" ]; then
  if ! (cd "$HOME" && npx -y impeccable install --global -y --no-hooks </dev/null); then
    warn "impeccable did not install; run ./rebuild.sh again once online"
  fi
fi
