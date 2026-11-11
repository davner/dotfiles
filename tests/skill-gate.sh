#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "skill gate hook"
# The pass cases matter as much as the blocks: a gate that stops reading
# TypeScript, or locks out a machine without the skill, gets switched off.
GATE="$DIR/home/.claude/hooks/skill-gate.sh"
if require jq; then
  GATE_HOME="$WORK/gate-home"
  # Linked the way home.nix links a pinned skill: a symlink into the store.
  mkdir -p "$WORK/gate-store/typescript-style-guide" "$GATE_HOME/.claude/skills"
  touch "$WORK/gate-store/typescript-style-guide/SKILL.md"
  ln -s "$WORK/gate-store/typescript-style-guide" "$GATE_HOME/.claude/skills/typescript-style-guide"
  export CLAUDE_SKILL_GATE_STATE="$WORK/gate-state"
  gate_payload() { # agent (empty for the main agent), tool name, tool_input JSON
    local p a
    p="$(tool_payload "$2" "$3")"
    p=${p#\{}
    if [ -n "$1" ]; then json_str a "$1"; a=",\"agent_id\":$a,\"agent_type\":\"general-purpose\""; fi
    printf '{"session_id":"s1",%s%s}' "${p%\}}" "${a-}"
  }
  # shellcheck disable=SC2329  # passed by name to expect_exit and hook
  gate_hook() { HOME="$GATE_HOME" "$GATE"; }
  gate() { hook gate_hook "$(gate_payload "$@")"; echo "$rc"; }
  eq "a .ts Edit before the skill loads is blocked" "2" \
    "$(gate "" Edit '{"file_path":"/p/a.ts","old_string":"a","new_string":"b"}')"
  eq "the Skill call itself passes" "0" "$(gate "" Skill '{"skill":"typescript-style-guide"}')"
  eq "a .ts Edit after the skill loads passes" "0" \
    "$(gate "" Edit '{"file_path":"/p/a.ts","old_string":"a","new_string":"b"}')"
  eq "the main agent's load does not count for a subagent" "2" \
    "$(gate agent-a Write '{"file_path":"/p/a.ts","content":"x"}')"
  gate agent-a Skill '{"skill":"typescript-style-guide"}' >/dev/null
  eq "a subagent's own load lets its write through" "0" \
    "$(gate agent-a Write '{"file_path":"/p/a.ts","content":"x"}')"
  eq "another subagent's load does not count" "2" \
    "$(gate agent-b MultiEdit '{"file_path":"/p/a.ts","edits":[]}')"
  for prefixed in home:typescript-style-guide some-plugin:typescript-style-guide; do
    gate "agent-$prefixed" Skill "{\"skill\":\"$prefixed\"}" >/dev/null
    eq "a load named $prefixed counts" "0" \
      "$(gate "agent-$prefixed" Write '{"file_path":"/p/a.ts","content":"x"}')"
  done
  for ext in tsx mts cts d.ts; do
    eq "a .$ext write is gated" "2" "$(gate agent-b Write "{\"file_path\":\"/p/a.$ext\",\"content\":\"x\"}")"
  done
  for f in a.js a.tsx.md notes.txt a.ts.orig; do
    eq "a write to $f passes" "0" "$(gate agent-b Write "{\"file_path\":\"/p/$f\",\"content\":\"x\"}")"
  done
  bare_home="$WORK/gate-bare-home"
  mkdir -p "$bare_home"
  eq "a machine without the skill installed is not locked out" "0" \
    "$(printf '%s' '{"session_id":"s2","tool_name":"Write","tool_input":{"file_path":"/p/a.ts","content":"x"}}' |
      HOME="$bare_home" "$GATE" >/dev/null 2>&1; echo $?)"
  eq "a payload that is not JSON passes" "0" "$(printf 'not json' | HOME="$GATE_HOME" "$GATE" >/dev/null 2>&1; echo $?)"
  eq "an empty payload passes" "0" "$(HOME="$GATE_HOME" "$GATE" </dev/null >/dev/null 2>&1; echo $?)"
  msg="$(printf '%s' '{"session_id":"s9","tool_name":"Edit","tool_input":{"file_path":"/p/a.ts"}}' |
    HOME="$GATE_HOME" "$GATE" 2>&1 >/dev/null)"
  contains "the block names the exact Skill call" "$msg" 'Skill tool with skill: "typescript-style-guide"'

  # agent-c never loads the skill, so every case below is judged cold.
  bash_gate_payload() { local c; json_str c "$1"; gate_payload agent-c Bash "{\"command\":$c}"; }
  bash_gate() { hook gate_hook "$(bash_gate_payload "$1")"; echo "$rc"; }
  expect_exit "a Bash write to a TypeScript file is blocked" 2 bash_gate_payload gate_hook <<'CASES'
echo 'export {}' > src/a.ts
printf x >>src/a.tsx
cat <<'EOF' > "src/b c.ts"
cd web && echo x > a.mts
echo x | tee src/a.ts
echo x | tee -a /p/a.cts >/dev/null
sed -i '' 's/a/b/' src/a.ts
sed -i.bak -e 's/a/b/' src/a.ts
gsed --in-place 's/a/b/' src/a.tsx
perl -pi -e 's/a/b/' src/a.ts
f=src/a.ts && printf x >> "$f"
out="src/b c.tsx"; echo x | tee "${out}"
cp tmp.txt src/a.ts
mv x src/b.tsx
cp -f a b.mts
cd web && install -m 644 gen.out src/c.cts
cp -R tpl/a.ts src/
cp -t /tmp src/a.ts
echo x>src/a.ts
printf x>>"src/b.tsx"
cmd 2>src/c.ts
sed -i 's/a;b/c/' src/a.ts
perl -i -pe 's/a|b/c/' src/a.ts
sed -i "s/a&&b/c/" src/a.tsx
CASES

  expect_exit "reading TypeScript through Bash passes" 0 bash_gate_payload gate_hook <<'CASES'
cat src/a.ts
grep -rn useState src/a.tsx
sed -n '1,20p' src/a.ts
head src/a.ts > /tmp/out.txt
npx tsc --noEmit src/a.ts 2>&1 | tail
perl -ne 'print if /x/' src/a.ts
echo x > notes.md
ls src/*.ts
out=/tmp/x.txt; echo x > "$out"
echo x > "$TARGET"
cp src/a.ts /tmp/x
mv src/old.ts.bak /tmp/
install -d src/types
grep '>' src/a.ts
echo x>/dev/null
echo 'x >src/a.ts'
git commit -m "a=>b in src/a.ts"
CASES
  expect_exit "a write inside a subshell or a compound command is blocked" 2 bash_gate_payload gate_hook <<'CASES'
echo "$(cp a src/a.ts)"
x=`tee src/a.ts`
(cd web && sed -i 's/a/b/' src/a.ts)
if cp a src/b.tsx; then :; fi
{ mv a src/c.mts; }
CASES
  # A heredoc body is data, so an apostrophe in it must not open a quote that
  # hides the command after it, and its text must not read as a command.
  eq "a write after a heredoc with an apostrophe is blocked" "2" \
    "$(bash_gate $'cat <<\'EOF\' > notes.txt\ndon\'t\nEOF\nsed -i \'s/a/b/\' src/a.ts')"
  eq "a heredoc body that mentions a write passes" "0" \
    "$(bash_gate $'cat <<-EOF > notes.txt\n\techo x > src/a.ts\n\tEOF\necho done')"
  # The hook has a 5 s timeout, and a hook that times out lets the call through.
  big=$'cat <<\'EOF\' > notes.txt\n'
  for i in $(seq 400); do big="$big line $i: don't; a | b && c > d \"q\" sed -i s/a/b/ src/a.ts"$'\n'; done
  big="${big}EOF"
  start=$SECONDS
  eq "a 400-line heredoc passes" "0" "$(bash_gate "$big")"
  if ((SECONDS - start <= 2)); then
    ok "a 400-line heredoc is judged within 2 s"
  else
    bad "a 400-line heredoc is judged within 2 s" "took $((SECONDS - start)) s"
  fi
fi
# The rule loads the skill before the gate has to fire; it only loads for a
# path its frontmatter names, so each extension the gate covers must be there.
TS_RULE="$DIR/home/.claude/rules/typescript.md"
rule_paths="$(sed -n '/^---$/,/^---$/p' "$TS_RULE" 2>/dev/null | grep -E '^[[:space:]]*-')"
for ext in ts tsx mts cts; do
  case "$rule_paths" in
    *"{ts,tsx,mts,cts}"* | *"*.$ext\""*) ok "the TypeScript rule's paths cover .$ext" ;;
    *) bad "the TypeScript rule's paths cover .$ext" "paths: ${rule_paths:-none}" ;;
  esac
done
contains "the TypeScript rule names the skill" "$(cat "$TS_RULE" 2>/dev/null)" "typescript-style-guide"
# No gate backs this one, so a rule that stops loading is the whole failure.
PY_RULE="$DIR/home/.claude/rules/python.md"
contains "the Python rule's paths cover .py and .pyi" "$(sed -n '/^---$/,/^---$/p' "$PY_RULE" 2>/dev/null)" '**/*.{py,pyi}'
for s in python-anti-patterns modern-python; do
  contains "the Python rule names $s" "$(cat "$PY_RULE" 2>/dev/null)" "$s"
done
contains "the Python rule type checks with ty" "$(cat "$PY_RULE" 2>/dev/null)" "ty check"

finish
