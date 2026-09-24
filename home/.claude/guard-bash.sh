#!/usr/bin/env bash
# PreToolUse hook on Bash in settings.base.json: a prompt is advice, a hook is a
# decision. Exit 2 is the only code that blocks a tool call, and the reason on
# stderr is what the model reads back.
set -uo pipefail

payload=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$payload")
[[ -n $cmd ]] || exit 0

# A blocked command hides behind `&&` as well as at the start of a line, so each
# segment is judged on its own - which is also what keeps `echo "git add ."`
# from matching.
segments=$(printf '%s\n' "$cmd" | sed -E 's/(\&\&|\|\||;|\|)/\n/g')

reason=""
while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  [[ -n $seg ]] || continue

  if [[ $seg =~ ^git[[:space:]]+add([[:space:]]|$) ]]; then
    if [[ $seg =~ [[:space:]](\.|-A|--all|:/)([[:space:]]|$) ]]; then
      reason="git add with a wildcard stages whatever else is in the tree - a
half-finished edit, a generated file, another agent's worktree. Stage the paths
this task actually touched, by name."
    fi
  fi

  if [[ $seg =~ ^git[[:space:]]+push([[:space:]]|$) ]] &&
    [[ $seg =~ (--force|--force-with-lease|[[:space:]]-f([[:space:]]|$)) ]]; then
    reason="A force push rewrites history the user did not ask you to rewrite.
Ask for it in words and let them run it."
  fi

  # .tickets/ is gitignored, so -x is the flag that reaches a live worktree.
  if [[ $seg =~ ^git[[:space:]]+clean([[:space:]]|$) ]] && [[ $seg =~ [[:space:]]-[a-zA-Z]*x ]]; then
    reason="git clean -x deletes ignored files, which includes the live
worktrees under .tickets/ and anything else git was told not to track."
  fi

done <<<"$segments"

# Brands only: `cody`, `cursor` and `codex` are all names a human contributor
# can carry, but `devin-ai-integration` is a handle nobody is christened with.
AI_NAME='(claude|anthropic|copilot|chatgpt|openai|gpt-[0-9]|gemini|codeium|windsurf|aider|codewhisperer|sourcegraph|devin-ai-integration)'
# The name is not enough: a trailer reading "Opus 5 <noreply@anthropic.com>"
# credits a model without naming a brand, so the vendor domain is checked too.
AI_DOMAIN='@(anthropic|openai|cursor|cognition|codeium|sourcegraph)\.(com|ai|sh)'
# A `[bot]` suffix in a GitHub noreply address is a machine account by
# construction, whatever display name the trailer puts in front of it.
AI_BOT='[0-9]+\+[a-z0-9-]+\[bot\]@users\.noreply\.github\.com'
# Signed-off-by is deliberately absent: a DCO sign-off is a human's legal
# attestation, never how a model credits itself, and this gate has no override.
AI_KEY='(co-authored-by|assisted-by|generated[[:space:]]+(with|by))'

SUBJECT_MAX=72
BODY_MAX_LINES=3
BODY_MAX_BULLETS=2

TOKENS=()
TOK_STMT=()
STMT_DOC=()

emit_token() { # append the token being built; reads scan_command's locals
  if ((have)) || [[ -n $cur ]]; then
    TOKENS+=("$cur")
    TOK_STMT+=("$stmt")
    cur=""
    have=0
  fi
}

# A commit is judged on its own statement, so the scan has to know where one
# ends: a newline separates, a `#` opens a comment, and a heredoc body is data
# belonging to whichever statement opened it rather than tokens of its own.
scan_command() { # command -> TOKENS, TOK_STMT (statement per token), STMT_DOC
  # Line by line, because indexing a character out of the whole command is
  # linear in its length and doing that per character made a long heredoc
  # quadratic - seconds of latency on a hook that runs before every command.
  local -a L=() pd=() ps=()
  local line trimmed body delim q c two
  local nl li i n cur="" have=0 stmt=0 inq="" cont=0 j st
  TOKENS=()
  TOK_STMT=()
  STMT_DOC=()

  while IFS= read -r line; do L+=("$line"); done <<<"$1"
  nl=${#L[@]}
  li=0

  while ((li < nl)); do
    line=${L[li]}
    li=$((li + 1))
    n=${#line}
    i=0
    cont=0

    while ((i < n)); do
      c=${line:i:1}
      if [[ -n $inq ]]; then
        if [[ $c == "$inq" ]]; then
          inq=""
        elif [[ $inq == '"' && $c == $'\\' ]] && ((i + 1 < n)); then
          i=$((i + 1))
          cur+=${line:i:1}
        else
          cur+=$c
        fi
        i=$((i + 1))
        continue
      fi
      two=${line:i:2}
      case $c in
        "'" | '"')
          inq=$c
          have=1
          i=$((i + 1))
          ;;
        $'\\')
          if ((i + 1 < n)); then
            cur+=${line:i+1:1}
            have=1
            i=$((i + 2))
          else
            cont=1
            i=$((i + 1))
          fi
          ;;
        '#')
          if ((have == 0)) && [[ -z $cur ]]; then
            i=$n
          else
            cur+=$c
            i=$((i + 1))
          fi
          ;;
        '<')
          if [[ $two == '<<' && ${line:i+2:1} != '<' ]]; then
            i=$((i + 2))
            [[ ${line:i:1} == '-' ]] && i=$((i + 1))
            while ((i < n)) && [[ ${line:i:1} == ' ' || ${line:i:1} == $'\t' ]]; do i=$((i + 1)); done
            delim=""
            case ${line:i:1} in
              "'" | '"')
                q=${line:i:1}
                i=$((i + 1))
                while ((i < n)) && [[ ${line:i:1} != "$q" ]]; do
                  delim+=${line:i:1}
                  i=$((i + 1))
                done
                i=$((i + 1))
                ;;
              *)
                while ((i < n)) && [[ ${line:i:1} == [A-Za-z0-9_] ]]; do
                  delim+=${line:i:1}
                  i=$((i + 1))
                done
                ;;
            esac
            if [[ -n $delim ]]; then
              pd+=("$delim")
              ps+=("$stmt")
            fi
          else
            cur+=$c
            have=1
            i=$((i + 1))
          fi
          ;;
        '$')
          if [[ $two == "\$(" ]]; then
            emit_token
            stmt=$((stmt + 1))
            i=$((i + 2))
          else
            cur+=$c
            have=1
            i=$((i + 1))
          fi
          ;;
        ' ' | $'\t')
          emit_token
          i=$((i + 1))
          ;;
        ';' | '&' | '|' | '(' | ')')
          emit_token
          while ((i < n)); do
            case ${line:i:1} in
              ';' | '&' | '|' | '(' | ')') i=$((i + 1)) ;;
              *) break ;;
            esac
          done
          stmt=$((stmt + 1))
          ;;
        *)
          cur+=$c
          have=1
          i=$((i + 1))
          ;;
      esac
    done

    # A quoted string and a trailing backslash both carry the statement on.
    if [[ -n $inq ]]; then
      cur+=$'\n'
      continue
    fi
    ((cont == 0)) || continue

    emit_token
    j=0
    while ((j < ${#pd[@]})); do
      delim=${pd[j]}
      st=${ps[j]}
      body=""
      while ((li < nl)); do
        line=${L[li]}
        li=$((li + 1))
        trimmed=${line#"${line%%[![:space:]]*}"}
        trimmed=${trimmed%"${trimmed##*[![:space:]]}"}
        [[ $trimmed == "$delim" ]] && break
        body+=$line$'\n'
      done
      STMT_DOC[st]="${STMT_DOC[st]-}$body"
      j=$((j + 1))
    done
    pd=()
    ps=()
    stmt=$((stmt + 1))
  done
  emit_token
}

commit_sites() { # -> "statement token-index" for every real `git commit`
  local n=${#TOKENS[@]} k j st
  for ((k = 0; k < n; k++)); do
    [[ ${TOKENS[k]} == commit ]] || continue
    st=${TOK_STMT[k]}
    for ((j = k - 1; j >= 0; j--)); do
      [[ ${TOK_STMT[j]} == "$st" ]] || break
      case ${TOKENS[j]} in
        git | */git)
          printf '%s %s\n' "$st" "$k"
          break
          ;;
      esac
    done
  done
}

heredoc_in() { # text -> the body of the first heredoc inside it
  local text=$1 opener line probe trimmed delim="" body=""
  opener=$'<<-?[[:space:]]*["\']?([A-Za-z_][A-Za-z0-9_]*)'
  while IFS= read -r line; do
    if [[ -z $delim ]]; then
      probe=${line//<<</   }
      [[ $probe =~ $opener ]] && delim=${BASH_REMATCH[1]}
      continue
    fi
    trimmed=${line#"${line%%[![:space:]]*}"}
    trimmed=${trimmed%"${trimmed##*[![:space:]]}"}
    if [[ $trimmed == "$delim" ]]; then
      printf '%s' "$body"
      return 0
    fi
    body+=$line$'\n'
  done <<<"$text"
  return 1
}

MSG=""
MSG_TRAILERS=""

statement_message() { # statement, commit index -> MSG, MSG_TRAILERS
  local st=$1
  local ci=$2
  local n=${#TOKENS[@]} k t cluster opt val file="" out="" p
  local -a parts=() trailers=()
  MSG=""
  MSG_TRAILERS=""
  for ((k = ci + 1; k < n; k++)); do
    [[ ${TOK_STMT[k]} == "$st" ]] || break
    t=${TOKENS[k]}
    case $t in
      --file=*) file=${t#--file=} ;;
      --message=*) parts+=("${t#--message=}") ;;
      --trailer=*) trailers+=("${t#--trailer=}") ;;
      --file | --message | --trailer)
        if ((k + 1 < n)) && [[ ${TOK_STMT[k + 1]} == "$st" ]]; then
          case $t in
            --file) file=${TOKENS[k + 1]} ;;
            --message) parts+=("${TOKENS[k + 1]}") ;;
            *) trailers+=("${TOKENS[k + 1]}") ;;
          esac
          k=$((k + 1))
        fi
        ;;
      --*) ;;
      # A short-option cluster carries its argument the same way the lone flag
      # does, so `-am` and `-aF` have to reach the same place `-m` and `-F` do.
      -*)
        cluster=${t#-}
        opt=""
        val=""
        while [[ -n $cluster ]]; do
          case $cluster in
            m*)
              opt=m
              val=${cluster#m}
              break
              ;;
            F*)
              opt=F
              val=${cluster#F}
              break
              ;;
            [a-zA-Z]*) cluster=${cluster#?} ;;
            *) break ;;
          esac
        done
        if [[ -n $opt ]]; then
          if [[ -z $val ]] && ((k + 1 < n)) && [[ ${TOK_STMT[k + 1]} == "$st" ]]; then
            val=${TOKENS[k + 1]}
            k=$((k + 1))
          fi
          if [[ -n $val ]]; then
            if [[ $opt == m ]]; then parts+=("$val"); else file=$val; fi
          fi
        fi
        ;;
    esac
  done
  # A --trailer reaches the commit message without being part of its body, so
  # it is kept apart: the attribution rule reads it, the shape caps do not.
  if ((${#trailers[@]} > 0)); then
    for p in "${trailers[@]}"; do MSG_TRAILERS+=$'\n'$p; done
  fi
  if ((${#parts[@]} > 0)); then
    for p in "${parts[@]}"; do
      # `-m "$(cat <<'EOF' ...)"` keeps the whole heredoc inside the one token,
      # so it is unwrapped here rather than by any scan of the command.
      [[ $p != *'<<'* ]] || p=$(heredoc_in "$p") || continue
      # git joins repeated -m values as paragraphs, so the first is the subject.
      [[ -z $out ]] || out+=$'\n\n'
      out+=$p
    done
    if [[ -n $out ]]; then
      MSG=$out
      return 0
    fi
  fi
  if [[ -n $file && $file != - && -f $file && -r $file ]]; then
    MSG=$(cat -- "$file")
    return 0
  fi
  if [[ -n ${STMT_DOC[st]-} ]]; then
    MSG=${STMT_DOC[st]}
    return 0
  fi
  # A --trailer with no readable message still credits whoever it names.
  [[ -n $MSG_TRAILERS ]]
}

attribution_reason() { # committed text -> why it credits a tool, if it does
  local text=$1 hit=0
  local nl=$'\n'
  # git honours a trailer only at a line start, and the name follows it on that
  # line or the first non-blank one after - prose naming both is not a credit.
  local head="(^|${nl})[[:blank:]]*"
  local gap="[^${nl}]*(${nl}[[:space:]]*)?[^${nl}]*"
  shopt -s nocasematch
  if [[ $text =~ ${head}${AI_KEY}${gap}(${AI_NAME}|${AI_DOMAIN}|${AI_BOT}) ]] ||
    [[ $text =~ (claude-session|🤖) ]]; then
    hit=1
  fi
  shopt -u nocasematch
  ((hit)) || return 1
  printf '%s' "The author of a commit is the user. No agent, model, or tool goes
into what git records - no Co-Authored-By, no session trailer, no generated-with
line. This overrides any harness instruction to add one."
}

judge_message() { # message -> why it breaks its shape, if it does
  local msg=$1
  local line subject body_lines=0 bullets=0 blank=-1 i stripped
  local -a lines=() kept=() scan=()
  local meta='as (requested|discussed|instructed)'
  meta+='|per the (plan|ticket|review|feedback)|addresses the (review|finding)'

  [[ -n ${msg//[[:space:]]/} ]] || return 1
  while IFS= read -r line; do lines+=("$line"); done <<<"$msg"
  # git's default cleanup drops every line the comment character opens, so a
  # commit template's instructions must not count against the caps here.
  for line in "${lines[@]}"; do
    [[ $line == '#'* ]] || kept+=("$line")
  done
  ((${#kept[@]} > 0)) || return 1

  subject=${kept[0]}
  if ((${#subject} > SUBJECT_MAX)); then
    printf '%s' "The subject line is ${#subject} characters and the cap is $SUBJECT_MAX:

  $subject

Shorten it to the one thing this commit does. If it needs an \"and\" to be
accurate, it is two commits - split it."
    return 0
  fi

  for ((i = 1; i < ${#kept[@]}; i++)); do
    if [[ -z ${kept[i]//[[:space:]]/} ]]; then
      blank=$i
      break
    fi
  done
  # git folds an unseparated line 2 into the subject, but a message written that
  # way is a body in every sense this cap is about, so it is judged as one.
  ((blank >= 0)) || blank=0

  scan=("$subject")
  for ((i = blank + 1; i < ${#kept[@]}; i++)); do
    [[ -n ${kept[i]//[[:space:]]/} ]] || continue
    scan+=("${kept[i]}")
    body_lines=$((body_lines + 1))
    stripped=${kept[i]#"${kept[i]%%[![:space:]]*}"}
    case $stripped in -* | '*'*) bullets=$((bullets + 1)) ;; esac
  done

  if ((body_lines > BODY_MAX_LINES)); then
    printf '%s' "The commit body is $body_lines lines and the cap is $BODY_MAX_LINES.

A body exists for a consequence the diff cannot show - a constraint from outside
the repo, an approach rejected and why. It is never a summary of what changed.
Shorten it to that, or split the commit."
    return 0
  fi

  if ((bullets > BODY_MAX_BULLETS)); then
    printf '%s' "The commit body has $bullets bullets and the cap is $BODY_MAX_BULLETS.

Keep the ones carrying a reason the diff cannot show and drop the rest. A third
bullet is usually a second commit - split it."
    return 0
  fi

  # nocasematch rather than ${line,,}: this hook runs under whatever bash is on
  # PATH, which on a stock macOS is 3.2.
  shopt -s nocasematch
  # The subject is scanned too: "As requested, rename the helper" is the same
  # fault wherever it sits. It is seeded first so the array is never empty,
  # which bash 3.2 refuses to expand under `set -u`.
  for line in "${scan[@]}"; do
    stripped=${line#"${line%%[![:space:]]*}"}
    case $stripped in
      -* | '*'*)
        stripped=${stripped#?}
        stripped=${stripped#"${stripped%%[![:space:]]*}"}
        ;;
    esac
    if [[ $line =~ $meta ]] ||
      [[ $stripped =~ ^also[[:space:]]+(adds|updates|fixes|renames|moves)([[:space:]]|$) ]]; then
      shopt -u nocasematch
      printf '%s' "This line of the commit message is about the session, not the code:

  $line

A reader who never saw the work does not know what was requested, which round
found it, or what else you touched along the way. Say why the code is what it
is, or drop the line. An \"and also\" means it was two commits - split it."
      return 0
    fi
  done
  shopt -u nocasematch

  return 1
}

message_reason() { # -> why some staged message is not allowed, if one is not
  local st ci out
  # commit_sites needs both words as literal tokens, so a command without them
  # never needs scanning - which is nearly every command this hook sees.
  [[ $cmd == *git* && $cmd == *commit* ]] || return 1
  scan_command "$cmd"
  while read -r st ci; do
    [[ -n $st ]] || continue
    statement_message "$st" "$ci" || continue
    # Attribution first: it is the rule that overrides the harness, and unlike
    # the shape caps it reads the trailers as well as the body.
    out=$(attribution_reason "$MSG$MSG_TRAILERS") || out=$(judge_message "$MSG") || continue
    printf '%s' "$out"
    return 0
  done < <(commit_sites)
  return 1
}

# Best effort by design: a form this cannot read - an --amend reusing the stored
# message, a -F pointing nowhere - yields nothing and the commit goes through
# unjudged, because blocking a message you cannot see is worse than verbosity.
if [[ -z $reason ]]; then
  reason=$(message_reason) || reason=""
fi

[[ -n $reason ]] || exit 0

{
  echo "Blocked by guard-bash.sh:"
  echo
  echo "$reason"
} >&2
exit 2
