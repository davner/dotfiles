#!/usr/bin/env bash
# Puts back the skills no flake input can carry: the ones kept in ~/Vault, and
# impeccable. home.nix runs this on every rebuild, after its own links are laid.
set -u

skills="$HOME/.claude/skills"
vault_skills="$HOME/Vault/.skills"
mkdir -p "$skills"

warn() { printf 'local-skills: %s\n' "$1" >&2; }

# A vault skill renamed or deleted would otherwise leave a link to nothing.
for link in "$skills"/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "$vault_skills"/*) [ -e "$link" ] || rm -f "$link" ;;
  esac
done

if [ -d "$vault_skills" ]; then
  for src in "$vault_skills"/*/; do
    src="${src%/}"
    [ -f "$src/SKILL.md" ] || continue
    name="${src##*/}"
    dest="$skills/$name"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then continue; fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      warn "$dest already exists, so the vault's $name is not linked"
      continue
    fi
    ln -s "$src" "$dest"
  done
fi

# --no-hooks because the settings merge would drop them; settings.base.json
# carries impeccable's hooks instead.
if [ ! -f "$skills/impeccable/SKILL.md" ]; then
  if ! (cd "$HOME" && npx -y impeccable install --global -y --no-hooks </dev/null); then
    warn "impeccable did not install; run ./rebuild.sh again once online"
  fi
fi
