#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "local skills"
# Runs on every rebuild against the real ~/.claude/skills, so the cases that
# matter most are the ones where it must leave a thing alone.
LOCAL="$DIR/home/.claude/local-skills.sh"
LHOME="$WORK/local-home"
LSTUB="$WORK/local-stub"
mkdir -p "$LSTUB" "$LHOME/.claude/skills" "$LHOME/Vault/.skills/vault-a" "$LHOME/Vault/.skills/not-a-skill" "$WORK/elsewhere"
touch "$LHOME/Vault/.skills/vault-a/SKILL.md"
# Records the call and lays down what a real install would, without the network.
cat >"$LSTUB/npx" <<'EOF'
#!/usr/bin/env bash
printf '%s|%s\n' "$PWD" "$*" >>"$(dirname "$0")/npx-calls"
[ -n "${NPX_FAIL-}" ] && exit 1
mkdir -p "$HOME/.claude/skills/impeccable" && touch "$HOME/.claude/skills/impeccable/SKILL.md"
EOF
chmod +x "$LSTUB/npx"
local_run() { # extra env assignments -> sets LOCAL_RC and LOCAL_ERR
  LOCAL_ERR="$(env HOME="$LHOME" PATH="$LSTUB:$PATH" "$@" "$LOCAL" 2>&1 >/dev/null)"
  LOCAL_RC=$?
}
ln -s "$LHOME/Vault/.skills/gone" "$LHOME/.claude/skills/gone"
ln -s "$WORK/elsewhere/missing" "$LHOME/.claude/skills/not-ours"
mkdir -p "$LHOME/Vault/.skills/taken" "$LHOME/.claude/skills/taken"
touch "$LHOME/Vault/.skills/taken/SKILL.md"

local_run
eq "local-skills.sh exits 0" "0" "$LOCAL_RC"
eq "a vault skill is linked" "$LHOME/Vault/.skills/vault-a" "$(readlink "$LHOME/.claude/skills/vault-a")"
if [ -e "$LHOME/.claude/skills/not-a-skill" ]; then
  bad "a vault folder without SKILL.md is not linked" "it was"
else
  ok "a vault folder without SKILL.md is not linked"
fi
if [ -L "$LHOME/.claude/skills/gone" ]; then
  bad "a link to a deleted vault skill is removed" "still there"
else
  ok "a link to a deleted vault skill is removed"
fi
if [ -L "$LHOME/.claude/skills/not-ours" ]; then
  ok "a broken link that is not the vault's is left alone"
else
  bad "a broken link that is not the vault's is left alone" "it was removed"
fi
if [ -L "$LHOME/.claude/skills/taken" ]; then
  bad "an existing folder is never replaced by a vault link" "it was replaced"
else
  ok "an existing folder is never replaced by a vault link"
fi
contains "and the clash is reported" "$LOCAL_ERR" "vault's taken is not linked"
eq "a missing impeccable is installed from ~, globally, without hooks" \
  "$LHOME|-y impeccable install --global -y --no-hooks" "$(cat "$LSTUB/npx-calls")"

local_run
eq "a second run exits 0" "0" "$LOCAL_RC"
eq "a second run does not reinstall impeccable" "1" "$(wc -l <"$LSTUB/npx-calls" | tr -d ' ')"
eq "a second run keeps the vault link" "$LHOME/Vault/.skills/vault-a" "$(readlink "$LHOME/.claude/skills/vault-a")"

rm -rf "$LHOME/.claude/skills/impeccable" "$LHOME/Vault"
local_run NPX_FAIL=1
eq "an install that fails does not fail the rebuild" "0" "$LOCAL_RC"
contains "and says to rebuild again" "$LOCAL_ERR" "impeccable did not install"
if [ -L "$LHOME/.claude/skills/vault-a" ]; then
  bad "with no vault, its old links are removed" "vault-a is still linked"
else
  ok "with no vault, its old links are removed"
fi

if grep -q 'home\.activation\.localSkills' "$DIR/home.nix" && grep -q 'local-skills\.sh' "$DIR/home.nix"; then
  ok "home.nix runs local-skills.sh on rebuild"
else
  bad "home.nix runs local-skills.sh on rebuild" "nothing would put the vault skills or impeccable on a new machine"
fi

finish
