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

# Heredoc bodies are skipped as data. awk, since a per-character bash loop
# over a long heredoc would outrun the hook's 5 s timeout.
# shellcheck disable=SC2016
TOKENIZE='
function flush(   name) {
  if (!inword) return
  if (!redir && !nwords && cur ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
    name = cur; sub(/=.*/, "", name)
    sub(/^[^=]*=/, "", cur); vars[name] = cur
  } else if (redir != 2) {
    # `f=src/a.ts && echo x > "$f"` is the one indirection a hook can see through.
    if (cur ~ /^\$\{?[A-Za-z_][A-Za-z0-9_]*\}?$/) { name = cur; gsub(/[${}]/, "", name); cur = vars[name] }
    print (redir ? "r " : "w ") cur
    if (!redir) nwords++
  }
  cur = ""; inword = 0; redir = 0
}
function end() { flush(); redir = 0; nwords = 0; print "e" }
function fd_number() { if (inword && cur ~ /^[0-9]+$/) { cur = ""; inword = 0 } }
function heredoc(   d, s, c) {
  s = 0
  if (substr(line, i, 1) == "-") { s = 1; i++ }
  while (substr(line, i, 1) ~ /[ \t]/) i++
  d = ""
  while (i <= n) {
    c = substr(line, i, 1)
    if (c ~ /[ \t;|&<>()]/) break
    if (c == "\047" || c == "\"") {
      i++
      while (i <= n && substr(line, i, 1) != c) { d = d substr(line, i, 1); i++ }
    } else if (c == "\\") {
      i++; d = d substr(line, i, 1)
    } else d = d c
    i++
  }
  delim[++nd] = d; strip[nd] = s
}
BEGIN { hd = 1 }
body {
  l = $0
  if (strip[hd]) sub(/^\t+/, "", l)
  if (l == delim[hd] && ++hd > nd) { body = 0; nd = 0; hd = 1 }
  next
}
{
  line = $0; n = length(line); i = 1; cont = 0
  while (i <= n) {
    c = substr(line, i, 1)
    if (q == "\047") { if (c == q) q = ""; else cur = cur c; i++; continue }
    if (q == "\"") {
      if (c == "\\" && index("$`\"\\", substr(line, i + 1, 1))) { cur = cur substr(line, i + 1, 1); i += 2; continue }
      if (c == q) q = ""; else cur = cur c
      i++; continue
    }
    if (c == "\\") {
      if (i == n) cont = 1; else { cur = cur substr(line, i + 1, 1); inword = 1 }
      i += 2; continue
    }
    if (c == "\047" || c == "\"") { q = c; inword = 1; i++; continue }
    if (c == " " || c == "\t") { flush(); i++; continue }
    if (c == "#" && !inword) break
    if (c == "&" && substr(line, i + 1, 1) == ">") { flush(); i++; continue }
    if (c ~ /[;|&()]/) { end(); i++; continue }
    if (c == ">") {
      fd_number(); flush(); i++
      if (substr(line, i, 1) ~ /[>|]/) i++
      if (substr(line, i, 1) == "&") {
        i++
        if (substr(line, i, 1) ~ /[0-9-]/) { while (substr(line, i, 1) ~ /[0-9-]/) i++; continue }
      }
      redir = 1; continue
    }
    if (c == "<") {
      fd_number(); flush(); i++
      if (substr(line, i, 2) == "<<") { i += 2; redir = 2; continue }
      if (substr(line, i, 1) == "<") { i++; heredoc(); continue }
      redir = 2; continue
    }
    cur = cur c; inword = 1; i++
  }
  if (q) { cur = cur " "; next }
  if (cont) next
  end()
  if (nd >= hd) body = 1
}
END { end() }'

# The destination is the last operand, or a folder that each source lands in
# under its own name; the sources are only read.
copy_destinations() { # cp/mv/install words -> the paths they write, one per line
  local w cmd=$1 dir="" take="" dirs_only="" opts=1 args=() i last
  shift
  for w; do
    if [[ -n $take ]]; then [[ $take == t ]] && dir=$w; take=""; continue; fi
    if [[ -n $opts ]]; then
      case $w in
        --) opts=""; continue ;;
        -t) take=t; continue ;;
        --target-directory=*) dir=${w#*=}; continue ;;
        -m | -o | -g) [[ $cmd == *install ]] && take=x; continue ;;
        -d) [[ $cmd == *install ]] && dirs_only=1; continue ;;
        -*) continue ;;
      esac
    fi
    args+=("$w")
  done
  [[ -z $dirs_only && ${#args[@]} -gt 0 ]] || return 0
  if [[ -z $dir ]]; then
    ((${#args[@]} > 1)) || return 0
    last=$((${#args[@]} - 1))
    if [[ ${args[last]} != */ ]]; then
      printf '%s\n' "${args[last]}"
      return 0
    fi
    dir=${args[last]}
    unset 'args[last]'
  fi
  for i in "${args[@]}"; do printf '%s\n' "${dir%/}/${i##*/}"; done
}

# Only the forms that write: a `tee` argument, any argument of an in-place sed
# or perl, or a copy's destination. Reading never matches.
command_writes() { # one simple command's words -> the paths it writes
  local w
  case $1 in
    tee) shift; printf '%s\n' "$@" ;;
    sed | gsed | perl)
      for w; do
        if [[ $w == --in-place* || $w =~ ^-[a-zA-Z]*i ]]; then
          shift
          printf '%s\n' "$@"
          return
        fi
      done
      ;;
    cp | gcp | mv | gmv | install | ginstall) copy_destinations "$@" ;;
  esac
}

write_words() { # command -> every word in a write position, one per line
  local kind w words=()
  while IFS= read -r w; do
    kind=${w%% *} w=${w#* }
    case $kind in
      r) printf '%s\n' "$w" ;;
      w) words+=("$w") ;;
      e)
        ((${#words[@]} == 0)) || command_writes "${words[@]}"
        words=()
        ;;
    esac
  done < <(awk "$TOKENIZE" <<<"$1") # w <word>, r <redirect target>, e at a command's end
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
    # A plugin or directory-scoped copy is named `<prefix>:<skill>`.
    skill=${skill##*:}
    [[ -n $skill && $skill != */* ]] || exit 0
    mkdir -p "$marker_dir" 2>/dev/null && : >"$marker_dir/$skill"
    exit 0
    ;;
  Bash) targets=$(write_words "$(jq -r '.tool_input.command // empty' <<<"$payload")") ;;
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
