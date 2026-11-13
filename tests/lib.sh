#!/usr/bin/env bash
# Sourced by every tests/*.sh. ./test.sh runs each file in a bash of its own,
# so state reaches a file only through what this defines.
# shellcheck disable=SC2034  # the fixtures here are read by the files that source this
set -uo pipefail # deliberately no -e: every check runs, then the count decides

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FAST="${TEST_FAST-}"
TEST_FILE="tests/${0##*/}"
SECTION="$TEST_FILE"

WORK="$(mktemp -d)"
STUB="$WORK/stub"
FAKEHOME="$WORK/home"
BASE="$DIR/home/.claude/settings.base.json"

pass=0
fail=0
skipped=0
finished=""
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; Z=$'\033[0m'; else G=""; R=""; Y=""; Z=""; fi

# The runner reads this file to tell a file that ran to its end from one that died.
lib_exit() {
  [ -z "${TEST_RESULT-}" ] ||
    printf '%s %s %s %s\n' "$pass" "$fail" "$skipped" "${finished:-died}" >"$TEST_RESULT"
  rm -rf "$WORK"
}
trap lib_exit EXIT

finish() {
  finished=ended
  [ -n "${TEST_RESULT-}" ] || printf '\n%d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skipped"
  [ "$fail" -eq 0 ]
  exit
}

ok() { printf '  %sok%s    %s\n' "$G" "$Z" "$1"; pass=$((pass + 1)); }
bad() {
  printf '  %sFAIL%s  %s\n' "$R" "$Z" "$1"
  [ -z "${TEST_RESULT-}" ] || printf '%s\n' "$1" >>"$TEST_RESULT.fails"
  shift
  for line in "$@"; do printf '        %s\n' "$line"; done
  fail=$((fail + 1))
}
skip() { printf '  %sskip%s  %s\n' "$Y" "$Z" "$1"; skipped=$((skipped + 1)); }
section() { printf '\n%s\n' "$1"; SECTION="$1"; }

eq() { # name expected actual
  if [ "$2" = "$3" ]; then
    ok "$1"
  else
    bad "$1" "expected: ${2//$'\n'/ | }" "actual:   ${3//$'\n'/ | }"
  fi
}
contains() { # name haystack needle
  case "$2" in
    *"$3"*) ok "$1" ;;
    *) bad "$1" "expected to contain: $3" "actual: ${2//$'\n'/ | }" ;;
  esac
}
want_exit() { # name wanted actual
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "wanted exit $2, got $3"; fi
}

require() { # cmd... -> 0 when each is on PATH, else a skip naming the section
  local c missing=""
  for c in "$@"; do command -v "$c" >/dev/null 2>&1 || missing="$missing $c"; done
  [ -z "$missing" ] && return 0
  skip "$SECTION (needs$missing)"
  return 1
}
full_only() {
  [ -z "$FAST" ] && return 0
  skip "$SECTION (--fast)"
  return 1
}

# BSD stat bare, GNU stat inside `nix develop`. Decided by flavour, because GNU
# `stat -f` prints filesystem information before failing.
filemode() {
  if stat --version >/dev/null 2>&1; then stat -c %a "$1"; else stat -f %Lp "$1"; fi
}

fixture_stub() { # creates $STUB, a PATH dir of witnesses, and $FAKEHOME
  [ ! -d "$STUB" ] || return 0
  mkdir -p "$STUB" "$FAKEHOME"
  # Records what it was asked to run instead of running it, so the happy path of
  # both scripts is observable without a password or a rebuild.
  cat >"$STUB/sudo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$(dirname "$0")/sudo-args"
EOF
  # --build calls darwin-rebuild with no sudo in front of it, so it needs its own witness.
  cat >"$STUB/darwin-rebuild" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$(dirname "$0")/darwin-rebuild-args"
EOF
  # bootstrap.sh resolves nix's path to hand to sudo; the stub sudo never execs it.
  cat >"$STUB/nix" <<'EOF'
#!/usr/bin/env bash
echo "test stub nix, should not run: $*" >&2
exit 1
EOF
  chmod +x "$STUB/sudo" "$STUB/nix" "$STUB/darwin-rebuild"
}

RUN_OUT=""
RUN_ERR=""
RUN_RC=0
SUDO_ARGS=""
DR_ARGS=""
run() { # run a repo script with the stubs in place; never touches real $HOME
  fixture_stub
  rm -f "$STUB/sudo-args" "$STUB/darwin-rebuild-args"
  RUN_RC=0
  RUN_OUT="$(HOME="$FAKEHOME" PATH="$STUB:$PATH" "$@" 2>"$WORK/stderr" </dev/null)" || RUN_RC=$?
  RUN_ERR="$(cat "$WORK/stderr")"
  SUDO_ARGS="$(cat "$STUB/sudo-args" 2>/dev/null)"
  DR_ARGS="$(cat "$STUB/darwin-rebuild-args" 2>/dev/null)"
}

fixture_users() { # sets $listed, every username in flake.nix, and $first
  listed="$("$DIR/users.sh" list 2>"$WORK/users-stderr")"
  first="${listed%%$'\n'*}"
}
fixture_copy() { # sets $COPY, a writable copy of flake.nix
  COPY="$WORK/flake.nix"
  cp "$DIR/flake.nix" "$COPY"
  chmod 644 "$COPY"
}
# The path a private layer takes: a flake of its own that imports the core's
# modules, with the core overridden to this working tree.
CONSUMER_USER="fixture.user"
fixture_consumer() { # Nix module body -> sets $CONSUMER, a flake importing both core modules
  CONSUMER="$WORK/consumer"
  mkdir -p "$CONSUMER"
  cat >"$CONSUMER/flake.nix" <<EOF
{
  inputs.core.url = "github:davner/dotfiles";
  outputs = { core, ... }: {
    darwinConfigurations.fixture = core.inputs.nix-darwin.lib.darwinSystem {
      modules = [
        core.darwinModules.default
        {
          dotfiles.user.name = "$CONSUMER_USER";
          # Already wired in by darwinModules.default; importing it again must be harmless.
          home-manager.users."$CONSUMER_USER".imports = [ core.homeModules.default ];
        }
        { $1 }
      ];
    };
  };
}
EOF
}
consumer_eval() { # attribute path under the fixture's config -> sets EV_RC, EV_OUT, EV_ERR, EV_MSG
  EV_RC=0
  EV_OUT="$(nix eval --raw --no-write-lock-file --override-input core "git+file://$DIR" \
    "$CONSUMER#darwinConfigurations.fixture.config.$1" 2>"$WORK/stderr")" || EV_RC=$?
  # The lock report for the unlocked fixture comes first; the error starts at "error:".
  EV_ERR="$(sed -n '/^error:/,$p' "$WORK/stderr")"
  # The message itself is the last "error:" line, under the stack trace.
  EV_MSG="$(grep -E '^ *error: .' <<<"$EV_ERR" | tail -n 1 | sed 's/^ *error: //')"
}
consumer_home() { # attribute path under the fixture user's home-manager config -> as consumer_eval
  consumer_eval "home-manager.users.\"$CONSUMER_USER\".$1"
}

fixture_sthome() { # sets $STHOME, a $HOME with an empty session registry
  STHOME="$WORK/name-home"
  mkdir -p "$STHOME/.claude/sessions"
}

rc=0
out=""
err=""
hook() { # script-or-function payload -> sets rc, out and err; never aborts
  printf '%s' "$2" | "$1" >"$WORK/hook-out" 2>"$WORK/hook-err"
  rc=${PIPESTATUS[1]}
  out="" err=""
  IFS= read -r -d '' out <"$WORK/hook-out"
  IFS= read -r -d '' err <"$WORK/hook-err"
}
# Built in bash because a jq per payload adds up over hundreds of table rows;
# jq still encodes long text, where bash substitution is slow, and control characters.
json_str() { # variable, text -> sets the variable to the text as a JSON string
  local json_s=$2
  if [ "${#json_s}" -gt 4096 ] || [[ ${json_s//[$'\n\t\r']/} == *[[:cntrl:]]* ]]; then
    printf -v "$1" '%s' "$(jq -n --arg s "$json_s" '$s')"
    return
  fi
  json_s=${json_s//\\/\\\\}
  json_s=${json_s//\"/\\\"}
  json_s=${json_s//$'\n'/\\n}
  json_s=${json_s//$'\t'/\\t}
  json_s=${json_s//$'\r'/\\r}
  printf -v "$1" '"%s"' "$json_s"
}
bash_payload() { # command [cwd] -> the PreToolUse payload for a Bash call
  local c d
  json_str c "$1"
  if [ $# -gt 1 ]; then
    json_str d "$2"
    printf '{"tool_name":"Bash","tool_input":{"command":%s},"cwd":%s}' "$c" "$d"
  else
    printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$c"
  fi
}
tool_payload() { # tool, tool_input as JSON -> the payload for any other tool
  local t
  json_str t "$1"
  printf '{"tool_name":%s,"tool_input":%s}' "$t" "$2"
}

expect_exit() { # name wanted builder script; cases on stdin, one per line
  local c
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    hook "$4" "$("$3" "$c" </dev/null)"
    want_exit "${1:+$1: }$c" "$2" "$rc"
  done
}
# A line starting with --- opens a case, and the rest of that line is its label.
# Unlabelled, a case is named by its first line.
expect_exit_blocks() { # name wanted builder script; cases on stdin
  local line label="" body="" open=""
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "${line#---}" != "$line" ]; then
      [ -z "$open" ] || expect_block "$1" "$2" "$3" "$4" "$label" "$body"
      label="${line#---}"
      label="${label# }"
      body=""
      open=1
    elif [ -z "$body" ]; then
      body="$line"
    else
      body="$body"$'\n'"$line"
    fi
  done
  [ -z "$open" ] || expect_block "$1" "$2" "$3" "$4" "$label" "$body"
}
expect_block() {
  local label="${5:-${6%%$'\n'*}}"
  [ -n "$6" ] || return 0
  hook "$4" "$("$3" "$6" </dev/null)"
  want_exit "${1:+$1: }$label" "$2" "$rc"
}
