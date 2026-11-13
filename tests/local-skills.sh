#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "local skills"
# Runs on every rebuild against the real ~/.claude/skills.
LOCAL="$DIR/home/.claude/local-skills.sh"
LHOME="$WORK/local-home"
LSTUB="$WORK/local-stub"
mkdir -p "$LSTUB" "$LHOME/.claude/skills" "$LHOME/Vault/.skills/vault-a"
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

local_run
eq "local-skills.sh exits 0" "0" "$LOCAL_RC"
eq "a missing impeccable is installed from ~, globally, without hooks" \
  "$LHOME|-y impeccable install --global -y --no-hooks" "$(cat "$LSTUB/npx-calls")"
# Work-only: the private layer links the vault skills.
if [ -e "$LHOME/.claude/skills/vault-a" ]; then
  bad "a vault skill is left to the work layer" "the core linked it"
else
  ok "a vault skill is left to the work layer"
fi

local_run
eq "a second run exits 0" "0" "$LOCAL_RC"
eq "a second run does not reinstall impeccable" "1" "$(wc -l <"$LSTUB/npx-calls" | tr -d ' ')"

rm -rf "$LHOME/.claude/skills/impeccable"
local_run NPX_FAIL=1
eq "an install that fails does not fail the rebuild" "0" "$LOCAL_RC"
contains "and says to rebuild again" "$LOCAL_ERR" "impeccable did not install"

if grep -q 'home\.activation\.localSkills' "$DIR/home.nix" && grep -q 'local-skills\.sh' "$DIR/home.nix"; then
  ok "home.nix runs local-skills.sh on rebuild"
else
  bad "home.nix runs local-skills.sh on rebuild" "nothing would put impeccable on a new machine"
fi

finish
