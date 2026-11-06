#!/usr/bin/env bash
# PreToolUse hook in settings.base.json: exit 2 blocks the call and stderr is
# what the model reads back, so the message has to name the call that unblocks it.
set -uo pipefail

STATE=${CLAUDE_SKILL_GATE_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/claude-skill-gate}

# path regex, then the skill a write to a matching path needs first
RULES='\.(ts|tsx|mts|cts)$ typescript-style-guide'

required_skill() { # path -> the skill it needs, or nothing
  local re skill
  while read -r re skill; do
    [[ $1 =~ $re ]] && { printf '%s' "$skill"; return; }
  done <<<"$RULES"
}

# One shell word, quoted or bare, so a quoted path with a space stays whole.
WORD="(\"[^\"]*\"|'[^']*'|[^[:space:]\"'<>|;&]+)"

unquote() {
  local s=$1
  case $s in
    \"*\") s=${s#\"} s=${s%\"} ;;
    \'*\') s=${s#\'} s=${s%\'} ;;
  esac
  printf '%s' "$s"
}

words() { # text -> one shell word per line, unquoted
  local rest=$1
  while [[ $rest =~ ^[[:space:]]*$WORD(.*)$ ]]; do
    unquote "${BASH_REMATCH[1]}"
    echo
    rest=${BASH_REMATCH[2]}
  done
}

# Only the forms that write: a redirect target, a `tee` argument, or any
# argument of an in-place sed or perl. Reading a file never matches.
bash_targets() { # command -> the paths it writes, one per line
  local cmd=$1 rest seg w inplace
  rest=$cmd
  while [[ $rest =~ (^|[[:space:][:digit:]&])\>\>?\|?[[:space:]]*$WORD(.*)$ ]]; do
    unquote "${BASH_REMATCH[2]}"
    echo
    rest=${BASH_REMATCH[3]}
  done
  while IFS= read -r seg; do
    [[ $seg =~ ^[[:space:]]*([^[:space:]]+) ]] || continue
    case ${BASH_REMATCH[1]} in
      tee) words "$seg" | tail -n +2 ;;
      sed | gsed | perl)
        inplace=""
        while IFS= read -r w; do
          [[ $w == --in-place* || $w =~ ^-[a-zA-Z]*i ]] && inplace=1
        done < <(words "$seg")
        [[ -n $inplace ]] && words "$seg" | tail -n +2
        ;;
    esac
  done < <(printf '%s\n' "$cmd" | sed -E 's/(\&\&|\|\||;|\|)/\n/g')
}

payload=$(cat)
fields=$(jq -r '[.tool_name // "", .session_id // "", .agent_id // "main",
  .tool_input.skill // "", .tool_input.file_path // ""] | join("\u001f")' <<<"$payload" 2>/dev/null) || exit 0
IFS=$'\x1f' read -r tool session agent skill path <<<"$fields"
[[ -n $session ]] || exit 0

# A subagent's load must not unlock its siblings or the main agent, so the
# marker is keyed by the pair rather than the session alone.
marker_dir="$STATE/${session//\//_}/${agent//\//_}"

case $tool in
  Skill)
    [[ -n $skill && $skill != */* ]] || exit 0
    mkdir -p "$marker_dir" 2>/dev/null && : >"$marker_dir/$skill"
    exit 0
    ;;
  Bash) targets=$(bash_targets "$(jq -r '.tool_input.command // empty' <<<"$payload")") ;;
  *) targets=$path ;;
esac

while IFS= read -r target; do
  need=$(required_skill "$target")
  [[ -n $need ]] || continue
  # Without the skill on disk the Skill call cannot succeed, so blocking would
  # lock the machine out of TypeScript entirely.
  [[ -f $HOME/.claude/skills/$need/SKILL.md ]] || continue
  [[ -e $marker_dir/$need ]] && continue

  cat >&2 <<EOF
Blocked: $target needs the $need skill loaded first, and this agent has not loaded it.
Call the Skill tool with skill: "$need", then retry this same call.
Where the repo's own conventions differ from the skill, the repo wins.
EOF
  exit 2
done <<<"$targets"
exit 0
