#!/usr/bin/env bash
# PreToolUse hook on Bash in settings.base.json: exit 2 is the only code that
# blocks a tool call, and the reason on stderr is what the model reads back.
set -uo pipefail

payload=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$payload")
[[ -n $cmd ]] || exit 0
here=$(jq -r '.cwd // empty' <<<"$payload")

# Followed to the real file, so an edit to the files beside it is live without a rebuild.
self=${BASH_SOURCE[0]}
while [[ -L $self ]]; do
  link=$(readlink "$self")
  [[ $link == /* ]] || link=$(dirname "$self")/$link
  self=$link
done
PARSE=$(dirname "$self")/shell-parse.sh
CREDIT=$(dirname "$self")/ai-credit.sh
for need in "$PARSE" "$CREDIT"; do
  [[ -x $need ]] && continue
  echo "guard-bash.sh: $need is missing, so no command is being checked" >&2
  exit 1
done
# shellcheck source=/dev/null
source "$CREDIT"

unescape() { # parser text -> REPLY
  REPLY=$1
  [[ $REPLY != *\\* ]] || printf -v REPLY '%b' "$REPLY"
}

resolve_dir() { # base, word -> absolute directory, or fail when it cannot be known
  local base=$1 d=$2
  case $d in
    \~) d=$HOME ;;
    \~/*) d=$HOME/${d#\~/} ;;
  esac
  [[ -n $d && $d != - && $d != *'$'* && $d != *'`'* ]] || return 1
  if [[ $d != /* ]]; then
    [[ -n $base ]] || return 1
    d=$base/$d
  fi
  printf '%s' "$d"
}

# The repo's own config, not the global one, so opting in is a per-repo act.
push_allowed() { # directory -> success when that repo has opted in to pushes
  [[ -n $1 && -d $1 ]] || return 1
  [[ $(git -C "$1" config --local --get claude.allowPush 2>/dev/null) == true ]]
}

# A cd inside a subshell is undone when it closes, so each one is kept against
# its scope and a statement sees only its own scope's and its parents'.
SCOPE_KEYS=()
SCOPE_DIRS=()
dir_for() { # scope -> DIR
  local s=$1 k
  while :; do
    for ((k = ${#SCOPE_KEYS[@]} - 1; k >= 0; k--)); do
      if [[ ${SCOPE_KEYS[k]} == "$s" ]]; then
        DIR=${SCOPE_DIRS[k]}
        return
      fi
    done
    [[ -n $s ]] || break
    if [[ $s == */* ]]; then s=${s%/*}; else s=""; fi
  done
  DIR=$here
}

# A wrapper runs the command after it unchanged, so `sudo git push --force` is
# the force push it wraps; one that changes directory leaves the repo unknown.
command_words() { # W -> CW, the words that run once wrappers are dropped; DIR_LOST
  local i=0 n=${#W[@]}
  CW=()
  DIR_LOST=""
  while ((i < n)); do
    case ${W[i]} in
      env)
        i=$((i + 1))
        while ((i < n)); do
          case ${W[i]} in
            -u | --unset) i=$((i + 2)) ;;
            -C | --chdir) DIR_LOST=1 i=$((i + 2)) ;;
            -C* | --chdir=*) DIR_LOST=1 i=$((i + 1)) ;;
            -* | [A-Za-z_]*=*) i=$((i + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      sudo | doas)
        i=$((i + 1))
        while ((i < n)); do
          case ${W[i]} in
            --)
              i=$((i + 1))
              break
              ;;
            -D | --chdir) DIR_LOST=1 i=$((i + 2)) ;;
            -D* | --chdir=*) DIR_LOST=1 i=$((i + 1)) ;;
            --*=*) i=$((i + 1)) ;;
            --user | --group | --host | --prompt | --close-from | --role | --type | --other-user | --chroot | --command-timeout)
              i=$((i + 2))
              ;;
            --*) i=$((i + 1)) ;;
            -*[ugpCrtTURh]) i=$((i + 2)) ;;
            -* | [A-Za-z_]*=*) i=$((i + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      command)
        i=$((i + 1))
        while ((i < n)); do
          case ${W[i]} in
            -v | -V) return ;;
            -*) i=$((i + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      exec | nohup | builtin | time | nice | timeout)
        local wrapper=${W[i]}
        i=$((i + 1))
        while ((i < n)); do
          case $wrapper:${W[i]} in
            exec:-a | nice:-n | timeout:-s | timeout:-k | timeout:--signal | timeout:--kill-after) i=$((i + 2)) ;;
            *:-*) i=$((i + 1)) ;;
            *) break ;;
          esac
        done
        [[ $wrapper != timeout ]] || i=$((i + 1))
        ;;
      *) break ;;
    esac
  done
  ((i < n)) && CW=("${W[@]:i}")
  return 0
}

has_arg() { # ERE -> success when some argument after the subcommand is all of it
  local a
  for a in ${ARGS[@]+"${ARGS[@]}"}; do
    [[ $a =~ ^($1)$ ]] && return 0
  done
  return 1
}

judge_statement() { # scope -> reason, msg_reason, for the statement in W and BODY
  local scope=$1 repo sub="" i n j out
  ((${#W[@]} > 0)) || return 0
  command_words
  n=${#CW[@]}
  ((n > 0)) || return 0
  dir_for "$scope"
  repo=$DIR
  [[ -z $DIR_LOST ]] || repo=""

  # Followed so a push is checked against the repo it runs in; a `cd` this
  # cannot resolve leaves the directory unknown, and an unknown one never pushes.
  if [[ ${CW[0]} == cd ]]; then
    i=1
    while ((i < n)) && [[ ${CW[i]} == -[LPe@]* || ${CW[i]} == -- ]]; do i=$((i + 1)); done
    if ((i >= n)); then
      repo=$HOME
    else
      repo=$(resolve_dir "$repo" "${CW[i]}") || repo=""
    fi
    SCOPE_KEYS+=("$scope")
    SCOPE_DIRS+=("$repo")
    return 0
  fi

  # Global options go before the subcommand, so they are peeled off here and
  # every rule below can match `git <subcommand>` whatever preceded it.
  ARGS=()
  if [[ ${CW[0]} == git || ${CW[0]} == */git ]]; then
    i=1
    while ((i < n)); do
      case ${CW[i]} in
        -C)
          repo=$(resolve_dir "$repo" "${CW[i + 1]-}") || repo=""
          i=$((i + 2))
          ;;
        --git-dir | --work-tree)
          repo=""
          i=$((i + 2))
          ;;
        --git-dir=* | --work-tree=*)
          repo=""
          i=$((i + 1))
          ;;
        -c) i=$((i + 2)) ;;
        -*) i=$((i + 1)) ;;
        *) break ;;
      esac
    done
    sub=${CW[i]-}
    ((i + 1 < n)) && ARGS=("${CW[@]:i+1}")
  fi

  if [[ $sub == add ]] && has_arg '\.|-A|--all|:/'; then
    reason="git add with a wildcard stages whatever else is in the tree - a
half-finished edit, a generated file, another agent's worktree. Stage the paths
this task actually touched, by name."
  fi

  if [[ $sub == push ]]; then
    # A `+` on a refspec forces that one ref exactly as --force forces them all.
    if has_arg '--force.*|-[a-zA-Z]*f[a-zA-Z]*|\+.+'; then
      reason="A force push rewrites history the user did not ask you to rewrite.
Ask for it in words and let them run it."
    elif ! push_allowed "$repo"; then
      reason="git push is off unless the repo has opted in, and this one has not:

  ${repo:-(no directory could be worked out from the command)}

Push only when the user asked for it. The user opts a repo in once by running
\`git config claude.allowPush true\` inside it; until they do, hand them the
push command to run themselves."
    fi
  fi

  # Setting the opt-in is left to the user, or this rule would unlock itself.
  if [[ $sub == config ]] && ! has_arg '--get|--get-all|get'; then
    shopt -s nocasematch
    for out in ${ARGS[@]+"${ARGS[@]}"}; do
      [[ $out == *claude.allowpush* ]] || continue
      reason="claude.allowPush is the user's switch for letting agents push from a
repo, so an agent never sets or clears it. Ask the user to run the git config
command themselves."
    done
    shopt -u nocasematch
  fi
  # The same switch behind the user's zsh function, which agent shells load too.
  if [[ ${CW[0]} == cc-push && ${CW[1]-} != status ]]; then
    reason="cc-push flips the user's switch for letting agents push from a
repo, so an agent never runs it. \`cc-push status\` only reads it; ask the
user to flip it themselves."
  fi

  # Opening or merging a PR puts work in front of other people, so it stays the user's act.
  j=0
  if [[ ${CW[0]} == npx ]]; then
    j=1
    [[ ${CW[1]-} != -y && ${CW[1]-} != --yes ]] || j=2
  fi
  if { [[ ${CW[0]} == gh && ${CW[1]-} == pr ]] && [[ ${CW[2]-} =~ ^(create|new|merge)$ ]]; } ||
    { [[ ${CW[j]-} == gh-axi && ${CW[j + 1]-} == pr ]] && [[ ${CW[j + 2]-} =~ ^(create|merge)$ ]]; }; then
    reason="Opening or merging a pull request is the user's call, in every repo.
Write the PR title and body on a page with a Copy button and hand them over;
the user opens and merges it themselves."
  fi

  if [[ $sub == reset ]] && has_arg '--hard'; then
    reason="git reset --hard throws away every uncommitted change in the tree,
including edits the user or another agent is making right now, and git keeps no
copy. Name the paths to restore, or ask the user to run it."
  fi

  if [[ $sub == merge ]] && ! has_arg '--ff-only|--squash|--abort|--continue|--quit'; then
    reason="The user keeps history linear: no merge commits on any branch. Bring
work over with \`git merge --ff-only\` when the branch sits on the tip, or
\`git cherry-pick\` its commits when it does not."
  fi

  if [[ $sub == pull ]] && ! has_arg '--rebase(=(true|merges|interactive|i))?|-r|--ff-only'; then
    reason="A plain git pull can create a merge commit, and the user keeps history
linear. Use \`git pull --rebase\` or \`git pull --ff-only\`."
  fi

  if [[ $sub == clean ]] && has_arg '-[a-zA-Z]*f.*|--force'; then
    reason="git clean -f deletes untracked files, which git has never seen and
cannot bring back - a new file not yet added is gone for good. Remove the files
you created by name, or ask the user to run it."
  fi

  # Working notes such as .scratch/ are gitignored, so -x is the flag that reaches them.
  if [[ $sub == clean ]] && has_arg '-[a-zA-Z]*x.*'; then
    reason="git clean -x deletes ignored files, which includes specs and tickets
under .scratch/, local env files, and anything else git was told not to track."
  fi

  if [[ $sub == branch ]] &&
    { has_arg '-[a-zA-Z]*D.*' ||
      { has_arg '(-[a-zA-Z]*d|--delete).*' && has_arg '(-[a-zA-Z]*f|--force).*'; }; }; then
    reason="git branch -D deletes a branch even when its commits are merged
nowhere else, and they are then reachable only through the reflog. Use
git branch -d, which refuses unless the work is safe, or ask the user."
  fi

  # --staged alone only unstages, so it loses nothing and stays allowed.
  if [[ $sub == checkout || $sub == restore ]] && has_arg '\.|\./|:/' &&
    ! { [[ $sub == restore ]] && has_arg '--staged|-S' && ! has_arg '--worktree|-W'; }; then
    reason="Checking out or restoring the whole tree discards every uncommitted
edit in it, including ones the user or another agent is making right now. Name
the paths this task changed and restore only those."
  fi

  if [[ $sub == commit && -z $msg_reason ]] && statement_message; then
    # Attribution first: it is the rule that overrides the harness, and unlike
    # the shape caps it reads the trailers as well as the body.
    out=$(attribution_reason "$MSG$MSG_TRAILERS") || out=$(judge_message "$MSG") || out=""
    msg_reason=$out
  fi
  return 0
}

SUBJECT_MAX=72
BODY_MAX_LINES=3
BODY_MAX_BULLETS=2

first_body() { # command -> the first heredoc body inside it
  local rec
  while IFS= read -r rec; do
    [[ ${rec:0:1} == h ]] || continue
    unescape "${rec:2}"
    printf '%s' "$REPLY"
    return 0
  done < <("$PARSE" <<<"$1")
  return 1
}

MSG=""
MSG_TRAILERS=""

statement_message() { # ARGS after `commit`, BODY -> MSG, MSG_TRAILERS
  local n=${#ARGS[@]} k t cluster opt val file="" out="" p
  local -a parts=() trailers=()
  MSG=""
  MSG_TRAILERS=""
  for ((k = 0; k < n; k++)); do
    t=${ARGS[k]}
    case $t in
      --file=*) file=${t#--file=} ;;
      --message=*) parts+=("${t#--message=}") ;;
      --trailer=*) trailers+=("${t#--trailer=}") ;;
      --file | --message | --trailer)
        if ((k + 1 < n)); then
          case $t in
            --file) file=${ARGS[k + 1]} ;;
            --message) parts+=("${ARGS[k + 1]}") ;;
            *) trailers+=("${ARGS[k + 1]}") ;;
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
          if [[ -z $val ]] && ((k + 1 < n)); then
            val=${ARGS[k + 1]}
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
      # `-m "$(cat <<'EOF' ...)"` keeps the source of its substitution, heredoc
      # and all, so the parser reads that source again for the body.
      [[ $p != *'<<'* ]] || p=$(first_body "$p") || continue
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
  if [[ -n $BODY ]]; then
    MSG=$BODY
    return 0
  fi
  # A --trailer with no readable message still credits whoever it names.
  [[ -n $MSG_TRAILERS ]]
}

attribution_reason() { # committed text -> why it credits a tool, if it does
  credits_tool "$1" || return 1
  printf '%s' "The author of a commit is the user. No agent, model, or tool goes
into what git records - no Co-Authored-By, no session trailer, no generated-with
line. This overrides any harness instruction to add one."
}

judge_message() { # message -> why it breaks its shape, if it does
  local msg=$1
  local line subject body_lines=0 bullets=0 blank=-1 i stripped
  local -a lines=() kept=() scan=()

  # A glob test, not ${msg//[[:space:]]/}: that substitution is quadratic, and a
  # long message would outrun the hook's timeout and pass unjudged.
  [[ $msg == *[![:space:]]* ]] || return 1
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
    if [[ ${kept[i]} != *[![:space:]]* ]]; then
      blank=$i
      break
    fi
  done
  # git folds an unseparated line 2 into the subject, but a message written that
  # way is a body in every sense this cap is about, so it is judged as one.
  ((blank >= 0)) || blank=0

  # Seeded with the subject, which the meta list scans too, and which keeps the
  # array non-empty - bash 3.2 refuses to expand an empty one under `set -u`.
  scan=("$subject")
  for ((i = blank + 1; i < ${#kept[@]}; i++)); do
    [[ ${kept[i]} == *[![:space:]]* ]] || continue
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
  for line in "${scan[@]}"; do
    stripped=${line#"${line%%[![:space:]]*}"}
    case $stripped in
      -* | '*'*)
        stripped=${stripped#?}
        stripped=${stripped#"${stripped%%[![:space:]]*}"}
        ;;
    esac
    if [[ $line =~ $SESSION_META ]] ||
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

# Best effort by design: a message this cannot read - an --amend reusing the
# stored one, a -F pointing nowhere - goes through unjudged rather than blocked.
reason=""
msg_reason=""
W=()
BODY=""
while IFS= read -r rec; do
  unescape "${rec:2}"
  case ${rec:0:1} in
    w) W+=("$REPLY") ;;
    h) BODY+=$REPLY ;;
    e)
      judge_statement "$REPLY"
      W=()
      BODY=""
      ;;
  esac
done < <("$PARSE" <<<"$cmd")
[[ -n $reason ]] || reason=$msg_reason

[[ -n $reason ]] || exit 0

{
  echo "Blocked by guard-bash.sh:"
  echo
  echo "$reason"
} >&2
exit 2
