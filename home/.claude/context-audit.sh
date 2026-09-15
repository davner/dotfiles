#!/usr/bin/env bash
# Measures Claude context files against the size caps that matter: a context
# file loads into every session, so every line it grows costs every future
# session. Prints one table and an exit code, and changes nothing - what to cut
# is a judgment call, so findings go to the user, never back to the model
# mid-task, which is why there is deliberately no --hook mode.
#
# A .md file inside a directory named `agents` is judged as an agent
# definition and gets the agent caps; everything else gets the context caps.
# An agent file whose opening `---` fence never closes is counted whole as
# body, since without a closing fence it has no frontmatter.
#
#   context-audit.sh <file>...  audit exactly the named files. A file that does
#                               not exist is an error on stderr and exit 2.
#   context-audit.sh            audit the current repo's context files:
#                               CLAUDE.md and AGENTS.md at the repo root (the
#                               current directory outside a git repo), plus any
#                               paths or globs listed one per line in
#                               <root>/.claude/context-audit - blank lines and
#                               `#` comments ignored. Absent config means
#                               root-only, which is how a multiproject repo
#                               scopes the audit. Globs may use `**`; on a
#                               bash without globstar such a line is an error
#                               (exit 2), never a shallow match.
#   context-audit.sh --agents   audit every $HOME/.claude/agents/*.md.
#
# Exit 0 when everything is under its cap, 1 when anything is over.
set -uo pipefail

# code.claude.com/docs/en/memory says to target under 200 lines per CLAUDE.md
# file and caps its own MEMORY.md at 200 lines / 25KB. The byte cap exists
# because unwrapped long lines dodge a pure line count.
CONTEXT_MAX_LINES=200
CONTEXT_MAX_BYTES=25600
# An agent body loads only when the agent runs, so it is laxer than a context
# file. The description loads into every parent session for routing - Claude
# Code warns when all descriptions together pass 15,000 tokens - so it gets a
# much smaller cap of its own.
AGENT_BODY_MAX_LINES=400
AGENT_DESC_MAX_CHARS=500

rows_file=()
rows_lines=()
rows_bytes=()
rows_cap=()
rows_verdict=()
over=0

add_row() { # display lines bytes cap verdict
  rows_file+=("$1")
  rows_lines+=("$2")
  rows_bytes+=("$3")
  rows_cap+=("$4")
  rows_verdict+=("$5")
  if [ "$5" = over ]; then over=1; fi
}

audit_context() { # display path
  local lines bytes verdict
  # awk counts a final line with no newline, which `wc -l` misses - and that
  # off-by-one lands exactly on the cap boundary this tool enforces.
  lines=$(awk 'END { print NR }' "$2")
  bytes=$(($(wc -c <"$2")))
  verdict=ok
  if [ "$lines" -gt "$CONTEXT_MAX_LINES" ] || [ "$bytes" -gt "$CONTEXT_MAX_BYTES" ]; then
    verdict=over
  fi
  add_row "$1" "$lines" "$bytes" "${CONTEXT_MAX_LINES}L/${CONTEXT_MAX_BYTES}B" "$verdict"
}

audit_agent() { # display path
  local body chars bytes verdict
  # Body is everything after the closing frontmatter fence (the whole file when
  # there is no frontmatter). The description value is either on the
  # `description:` line or a `>` folded block of indented lines, which is all
  # the roster actually uses; the description row reports chars in the bytes
  # column, against its own cap.
  read -r body chars < <(awk '
    NR == 1 && /^---[[:space:]]*$/ { infm = 1; next }
    infm && /^---[[:space:]]*$/ { infm = 0; next }
    infm {
      if (indesc) {
        if ($0 ~ /^[[:space:]]/) {
          line = $0
          sub(/^[[:space:]]+/, "", line)
          desc = desc (desc == "" ? "" : " ") line
          next
        }
        indesc = 0
      }
      if ($0 ~ /^description:/) {
        val = $0
        sub(/^description:[[:space:]]*/, "", val)
        if (val == "" || val ~ /^[>|][+-]?$/) indesc = 1
        else desc = val
      }
      next
    }
    { body++ }
    END {
      # An opening fence that never closes is not frontmatter: the whole file
      # counts as body, so a malformed file can only over-report, never slip
      # under the cap with a body of zero.
      if (infm) { body = NR; desc = "" }
      print body + 0, length(desc)
    }
  ' "$2")
  bytes=$(($(wc -c <"$2")))
  verdict=ok
  if [ "$body" -gt "$AGENT_BODY_MAX_LINES" ]; then verdict=over; fi
  add_row "$1 (body)" "$body" "$bytes" "${AGENT_BODY_MAX_LINES}L" "$verdict"
  verdict=ok
  if [ "$chars" -gt "$AGENT_DESC_MAX_CHARS" ]; then verdict=over; fi
  add_row "$1 (description)" "-" "$chars" "${AGENT_DESC_MAX_CHARS}C" "$verdict"
}

audit_one() { # display path
  # The bare pattern is for relative invocations like `agents/foo.md`, which
  # `*/agents/*.md` alone would misfile under the context caps.
  case $2 in
    */agents/*.md | agents/*.md) audit_agent "$1" "$2" ;;
    *) audit_context "$1" "$2" ;;
  esac
}

if [ "${1-}" = "--agents" ]; then
  shopt -s nullglob
  found=""
  for f in "$HOME"/.claude/agents/*.md; do
    found=1
    audit_one "$f" "$f"
  done
  shopt -u nullglob
  if [ -z "$found" ]; then
    echo "context-audit: nothing under $HOME/.claude/agents to audit" >&2
    exit 0
  fi
elif [ $# -gt 0 ]; then
  for f in "$@"; do
    if [ ! -f "$f" ]; then
      echo "context-audit: no such file: $f" >&2
      exit 2
    fi
  done
  for f in "$@"; do
    audit_one "$f" "$f"
  done
else
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
  seen=""
  for f in CLAUDE.md AGENTS.md; do
    if [ -f "$root/$f" ]; then
      seen="$seen $root/$f "
      audit_one "$f" "$root/$f"
    fi
  done
  cfg="$root/.claude/context-audit"
  if [ -f "$cfg" ]; then
    # Probed once so a `**` line fails loudly instead of matching one level
    # deep: on a bash without globstar, nullglob would stick in the expansion
    # subshell while globstar silently failed to set.
    globstar_ok=1
    (shopt -s globstar) 2>/dev/null || globstar_ok=""
    while IFS= read -r pat || [ -n "$pat" ]; do
      pat="${pat#"${pat%%[![:space:]]*}"}"
      pat="${pat%"${pat##*[![:space:]]}"}"
      case $pat in '' | '#'*) continue ;; esac
      if [ -z "$globstar_ok" ]; then
        case $pat in
          *'**'*)
            echo "context-audit: '**' in $cfg needs a bash with globstar: $pat" >&2
            exit 2
            ;;
        esac
      fi
      # Each config line is a glob; expanding it is the point, so it stays
      # unquoted. Expanded from the repo root so the paths are root-relative.
      # shellcheck disable=SC2086
      while IFS= read -r m; do
        [ -n "$m" ] || continue
        # A glob that re-matches an already-audited file must not add a row.
        case $seen in *" $root/$m "*) continue ;; esac
        seen="$seen $root/$m "
        audit_one "$m" "$root/$m"
      done < <(
        cd "$root" || exit
        shopt -s nullglob globstar 2>/dev/null
        for g in $pat; do
          if [ -f "$g" ]; then printf '%s\n' "$g"; fi
        done
      )
    done <"$cfg"
  fi
  if [ ${#rows_file[@]} -eq 0 ]; then
    echo "context-audit: no context files at $root to audit" >&2
    exit 0
  fi
fi

w1=4
w2=5
w3=5
w4=3
for i in "${!rows_file[@]}"; do
  if [ "${#rows_file[$i]}" -gt "$w1" ]; then w1=${#rows_file[$i]}; fi
  if [ "${#rows_lines[$i]}" -gt "$w2" ]; then w2=${#rows_lines[$i]}; fi
  if [ "${#rows_bytes[$i]}" -gt "$w3" ]; then w3=${#rows_bytes[$i]}; fi
  if [ "${#rows_cap[$i]}" -gt "$w4" ]; then w4=${#rows_cap[$i]}; fi
done
printf '%-*s  %*s  %*s  %-*s  %s\n' "$w1" file "$w2" lines "$w3" bytes "$w4" cap verdict
for i in "${!rows_file[@]}"; do
  printf '%-*s  %*s  %*s  %-*s  %s\n' \
    "$w1" "${rows_file[$i]}" "$w2" "${rows_lines[$i]}" "$w3" "${rows_bytes[$i]}" \
    "$w4" "${rows_cap[$i]}" "${rows_verdict[$i]}"
done

exit "$over"
