#!/usr/bin/env bash
# Measures Claude context files against size caps, since each one loads into
# every session. No --hook mode: what to cut is the user's call, not a model's.
set -uo pipefail

# code.claude.com/docs/en/memory targets under 200 lines per CLAUDE.md; the byte
# cap exists because unwrapped long lines dodge a pure line count.
CONTEXT_MAX_LINES=200
CONTEXT_MAX_BYTES=25600
# An agent body loads only when the agent runs, but its description loads into
# every parent session for routing, so the description gets a far smaller cap.
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
  # A description is either inline or a `>` folded block of indented lines; its
  # row reports chars in the bytes column, against a cap of its own.
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
      # An opening fence that never closes is not frontmatter, so a malformed
      # file can only over-report, never slip under the cap with a body of zero.
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
    # Probed once so a `**` line fails loudly instead of matching one level deep:
    # nullglob would stick in the expansion subshell while globstar never set.
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
      # unquoted, and from the repo root so the display paths are root-relative.
      # shellcheck disable=SC2086
      while IFS= read -r m; do
        [ -n "$m" ] || continue
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
