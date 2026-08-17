#!/usr/bin/env bash
# Checks the things in this repo that fail silently, fail only on the other
# machine, or fail an hour into an activation: the username -> flake attribute
# mapping, the users list parsing, the two scripts' guard rails, and the
# out-of-store symlink targets.
#
# Nothing here needs sudo and nothing here touches the real machine. The
# scripts run against a stub `sudo` on PATH and a throwaway $HOME, so the
# command they would have run is asserted instead of executed.
#
# usage: ./test.sh [--fast]
#   --fast skips the nix evaluations, which are the slow half.
set -uo pipefail # deliberately no -e: every check runs, then the count decides

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
FAST=""
[ "${1-}" = "--fast" ] && FAST=1

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STUB="$WORK/stub"
FAKEHOME="$WORK/home"
mkdir -p "$STUB" "$FAKEHOME"

# Records what it was asked to run instead of running it, so the happy path of
# both scripts is observable without a password or a rebuild.
cat >"$STUB/sudo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$(dirname "$0")/sudo-args"
EOF
# --build calls darwin-rebuild directly, with no sudo in front of it, so that
# path needs its own witness.
cat >"$STUB/darwin-rebuild" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$(dirname "$0")/darwin-rebuild-args"
EOF
# bootstrap.sh resolves nix's absolute path to hand to sudo, so it has to find
# something. Never actually executed: the stub sudo does not exec its argument.
cat >"$STUB/nix" <<'EOF'
#!/usr/bin/env bash
echo "test stub nix, should not run: $*" >&2
exit 1
EOF
chmod +x "$STUB/sudo" "$STUB/nix" "$STUB/darwin-rebuild"

pass=0
fail=0
skipped=0
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; Z=$'\033[0m'; else G=""; R=""; Y=""; Z=""; fi

ok() { printf '  %sok%s    %s\n' "$G" "$Z" "$1"; pass=$((pass + 1)); }
bad() {
  printf '  %sFAIL%s  %s\n' "$R" "$Z" "$1"
  shift
  for line in "$@"; do printf '        %s\n' "$line"; done
  fail=$((fail + 1))
}
skip() { printf '  %sskip%s  %s\n' "$Y" "$Z" "$1"; skipped=$((skipped + 1)); }
section() { printf '\n%s\n' "$1"; }

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

# BSD stat bare, GNU stat inside `nix develop` (stdenv puts coreutils first).
# Decided once by flavour rather than by trying both: GNU `stat -f` prints
# filesystem information before failing, so a fallback would concatenate onto
# that output rather than replace it.
if stat --version >/dev/null 2>&1; then
  filemode() { stat -c %a "$1"; }
else
  filemode() { stat -f %Lp "$1"; }
fi

RUN_OUT=""
RUN_ERR=""
RUN_RC=0
SUDO_ARGS=""
DR_ARGS=""
run() { # run a repo script with the stubs in place; never touches real $HOME
  rm -f "$STUB/sudo-args" "$STUB/darwin-rebuild-args"
  RUN_RC=0
  RUN_OUT="$(HOME="$FAKEHOME" PATH="$STUB:$PATH" "$@" 2>"$WORK/stderr" </dev/null)" || RUN_RC=$?
  RUN_ERR="$(cat "$WORK/stderr")"
  SUDO_ARGS="$(cat "$STUB/sudo-args" 2>/dev/null)"
  DR_ARGS="$(cat "$STUB/darwin-rebuild-args" 2>/dev/null)"
}

SCRIPTS=(bootstrap.sh rebuild.sh users.sh test.sh
  home/.claude/statusline.sh home/.claude/session-name.sh)

# --------------------------------------------------------------------------
section "syntax and lint"
for s in "${SCRIPTS[@]}"; do
  if err="$(bash -n "$DIR/$s" 2>&1)"; then ok "bash -n $s"; else bad "bash -n $s" "$err"; fi
  if [ -x "$DIR/$s" ]; then ok "$s is executable"; else bad "$s is executable" "chmod +x $s"; fi
done
if command -v shellcheck >/dev/null 2>&1; then
  for s in "${SCRIPTS[@]}"; do
    if err="$(shellcheck "$DIR/$s" 2>&1)"; then ok "shellcheck $s"; else bad "shellcheck $s" "$err"; fi
  done
else
  skip "shellcheck (nix develop --command ./test.sh installs it)"
fi
# Catches a broken workflow before a push finds out, and shellchecks the
# `run:` blocks that CI would otherwise only fail on inside the runner.
if command -v actionlint >/dev/null 2>&1; then
  if err="$(cd "$DIR" && actionlint 2>&1)"; then ok "actionlint"; else bad "actionlint" "$err"; fi
else
  skip "actionlint (nix develop --command ./test.sh installs it)"
fi
# A broken template would otherwise only surface the next time someone
# regenerated the changelog, which is rarely the same day it broke.
if command -v git-cliff >/dev/null 2>&1; then
  if err="$(cd "$DIR" && git-cliff 2>&1 >/dev/null)"; then
    ok "cliff.toml and its template render"
  else
    bad "cliff.toml and its template render" "$err"
  fi
else
  skip "git-cliff (nix develop --command ./test.sh installs it)"
fi

# --------------------------------------------------------------------------
section "users list"
markers="$(grep -cF '# end users' "$DIR/flake.nix")"
eq "flake.nix has exactly one '# end users' marker" "1" "$markers"

listed="$("$DIR/users.sh" list 2>"$WORK/stderr")"
if [ -n "$listed" ]; then
  ok "users.sh list returns usernames"
else
  bad "users.sh list returns usernames" "$(cat "$WORK/stderr")"
fi
eq "no duplicate usernames" "$(printf '%s\n' "$listed" | sort -u | wc -l | tr -d ' ')" \
  "$(printf '%s\n' "$listed" | wc -l | tr -d ' ')"

bogus="$(printf '%s\n' "$listed" | grep -vE '^[A-Za-z0-9._-]+$')"
eq "every username is attribute-safe once dots are dashed" "" "$bogus"

first="$(printf '%s\n' "$listed" | head -n1)"
if "$DIR/users.sh" has "$first"; then
  ok "users.sh has \"$first\""
else
  bad "users.sh has \"$first\"" "expected exit 0"
fi
if "$DIR/users.sh" has definitely-not-a-real-user 2>/dev/null; then
  bad "users.sh rejects an unlisted name" "expected non-zero exit"
else
  ok "users.sh rejects an unlisted name"
fi

# --------------------------------------------------------------------------
section "users.sh add (on a copy, never the real flake.nix)"
COPY="$WORK/flake.nix"
cp "$DIR/flake.nix" "$COPY"
chmod 644 "$COPY"

run "$DIR/users.sh" add "new.user" "$COPY"
eq "add exits 0" "0" "$RUN_RC"
eq "add appends after the existing entries" "$listed
new.user" "$("$DIR/users.sh" list "$COPY")"
eq "add leaves the file mode alone" "644" "$(filemode "$COPY")"

sum_before="$(shasum "$COPY" | cut -d' ' -f1)"
run "$DIR/users.sh" add "new.user" "$COPY"
eq "adding the same name twice changes nothing" "$sum_before" "$(shasum "$COPY" | cut -d' ' -f1)"

run "$DIR/users.sh" add 'bad name"' "$COPY"
eq "add refuses a name that would break the Nix string" "1" "$RUN_RC"
eq "refused add left the file alone" "$sum_before" "$(shasum "$COPY" | cut -d' ' -f1)"

NOMARK="$WORK/nomarker.nix"
grep -vF '# end users' "$COPY" >"$NOMARK"
run "$DIR/users.sh" add "someone" "$NOMARK"
eq "add refuses when the marker is gone" "1" "$RUN_RC"
contains "add says why it refused" "$RUN_ERR" "nowhere to append"

if command -v nix-instantiate >/dev/null 2>&1; then
  if err="$(nix-instantiate --parse "$COPY" 2>&1 >/dev/null)"; then
    ok "flake.nix still parses as Nix after two adds"
  else
    bad "flake.nix still parses as Nix after two adds" "$err"
  fi
else
  skip "post-add Nix parse (nix-instantiate not found)"
fi

# --------------------------------------------------------------------------
section "rebuild.sh"
while read -r u; do
  attr="${u//./-}"
  run env -u SUDO_USER "$DIR/rebuild.sh" --user "$u"
  eq "rebuild.sh --user $u exits 0" "0" "$RUN_RC"
  eq "rebuild.sh --user $u builds #$attr" \
    "darwin-rebuild switch --flake $DIR#$attr" "$SUDO_ARGS"
  eq "rebuild.sh --user $u runs darwin-rebuild only through sudo" "" "$DR_ARGS"
done <<<"$listed"

run env -u SUDO_USER "$DIR/rebuild.sh" --user "$first" --build
eq "--build exits 0" "0" "$RUN_RC"
eq "--build builds instead of switching" \
  "build --flake $DIR#${first//./-}" "$DR_ARGS"
eq "--build never asks for sudo" "" "$SUDO_ARGS"
run env -u SUDO_USER "$DIR/rebuild.sh" -b --user "$first"
eq "-b is the same as --build" "build --flake $DIR#${first//./-}" "$DR_ARGS"

run env -u SUDO_USER "$DIR/rebuild.sh" --user "$first"
eq "rebuild.sh points ~/.dotfiles at this checkout" "$DIR" "$(readlink "$FAKEHOME/.dotfiles")"

run env "SUDO_USER=$first" "$DIR/rebuild.sh"
eq "rebuild.sh under sudo uses SUDO_USER, not root" \
  "darwin-rebuild switch --flake $DIR#${first//./-}" "$SUDO_ARGS"

me="$(id -un)"
if "$DIR/users.sh" has "$me" 2>/dev/null; then
  run env -u SUDO_USER "$DIR/rebuild.sh"
  eq "rebuild.sh with no arguments builds the current user" \
    "darwin-rebuild switch --flake $DIR#${me//./-}" "$SUDO_ARGS"
else
  skip "no-argument default ($me is not in the users list)"
fi

run env -u SUDO_USER "$DIR/rebuild.sh" --user no-such-user
eq "unlisted user fails before building" "1" "$RUN_RC"
eq "unlisted user never reaches sudo" "" "$SUDO_ARGS"
contains "unlisted user error lists the valid names" "$RUN_ERR" "$first"

run env -u SUDO_USER "$DIR/rebuild.sh" --nonsense
eq "unknown flag exits 2" "2" "$RUN_RC"
eq "unknown flag never reaches sudo" "" "$SUDO_ARGS"

run env -u SUDO_USER "$DIR/rebuild.sh" --user
if [ "$RUN_RC" -ne 0 ]; then ok "--user with no value fails"; else bad "--user with no value fails" "exited 0"; fi
eq "--user with no value never reaches sudo" "" "$SUDO_ARGS"

# --------------------------------------------------------------------------
section "--help"
# Every script's, not just one: these printed their own source with a line
# range until a line moved and one of them started leaking `set -euo pipefail`
# into its help text.
for s in bootstrap.sh rebuild.sh users.sh; do
  run env -u SUDO_USER "$DIR/$s" --help
  eq "$s --help exits 0" "0" "$RUN_RC"
  contains "$s --help prints usage" "$RUN_OUT" "usage:"
  case "$RUN_OUT" in
    *'set -e'* | *'#!/'* | *$'\n#'*)
      bad "$s --help prints prose, not source" "leaked a line of the script itself"
      ;;
    *) ok "$s --help prints prose, not source" ;;
  esac
  eq "$s --help never reaches sudo" "" "$SUDO_ARGS"
done

run env -u SUDO_USER "$DIR/users.sh"
eq "users.sh with no command exits 2" "2" "$RUN_RC"
contains "users.sh with no command explains itself" "$RUN_ERR" "usage:"

# --------------------------------------------------------------------------
section "bootstrap.sh"
run env -u SUDO_USER "$DIR/bootstrap.sh" --user "$first"
eq "bootstrap.sh --user $first exits 0" "0" "$RUN_RC"
eq "bootstrap.sh builds #${first//./-} from the flake directly" \
  "$STUB/nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake $DIR#${first//./-}" \
  "$SUDO_ARGS"
contains "bootstrap.sh skips a username already in the list" "$RUN_OUT" "nothing to do"

sum_flake="$(shasum "$DIR/flake.nix" | cut -d' ' -f1)"
run env -u SUDO_USER "$DIR/bootstrap.sh" --user brand-new-user
eq "declining the prompt exits 1" "1" "$RUN_RC"
eq "declining the prompt leaves flake.nix untouched" "$sum_flake" \
  "$(shasum "$DIR/flake.nix" | cut -d' ' -f1)"
eq "declining the prompt never reaches sudo" "" "$SUDO_ARGS"

run env -u SUDO_USER "$DIR/bootstrap.sh" --nonsense
eq "bootstrap.sh unknown flag exits 2" "2" "$RUN_RC"
eq "bootstrap.sh unknown flag never reaches sudo" "" "$SUDO_ARGS"

# --------------------------------------------------------------------------
section "out-of-store symlink targets"
# mkOutOfStoreSymlink does not check its target, so a typo here is a dangling
# symlink in $HOME that no build or activation ever complains about.
targets="$(sed -nE 's|.*mkOutOfStoreSymlink "\$\{dotfiles\}/([^"]+)".*|\1|p' "$DIR/home.nix" | sort -u)"
if [ -z "$targets" ]; then
  bad "found mkOutOfStoreSymlink targets in home.nix" "the sed found nothing - did home.nix change shape?"
else
  while read -r t; do
    if [ -e "$DIR/$t" ]; then ok "$t exists"; else bad "$t exists" "home.nix links to a path this repo does not have"; fi
  done <<<"$targets"
fi

# --------------------------------------------------------------------------
section "status line"
# Claude Code renders whatever this prints, so a crash costs the whole line.
# Most of the payload is optional, and the interesting cases are the ones where
# a field has not arrived yet.
SL="$DIR/home/.claude/statusline.sh"
plain() { sed $'s/\x1b\\[[0-9;]*m//g'; }
NOW="$(date +%s)"

# Every window below is deliberately offset past its boundary instead of landing
# on it, and the offset is drift tolerance rather than an arbitrary number. The
# script reads the clock after this line runs and floors what is left, so an
# exact 259200 (3d) or 900 (15m) renders as 2d or 14m the moment one second has
# passed. That is a real second on a loaded CI runner, not a theoretical one.
# Round these off and the suite starts failing a few times a week.
sl_out="$(printf '{"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":8},"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":%d},"seven_day":{"used_percentage":41.2,"resets_at":%d}}}' \
  "$((NOW + 7230))" "$((NOW + 259200 + 3600))" | "$SL" | plain)"
eq "a full payload renders every segment" \
  "Opus 5 · ctx 8% · 5h 24% (2h00m) · wk 41% (3d)" "$sl_out"

sl_out="$(printf '{"model":{"display_name":"Opus 5"},"fast_mode":true,"context_window":{"used_percentage":82},"rate_limits":{"five_hour":{"used_percentage":91,"resets_at":%d}}}' \
  "$((NOW + 900 + 30))" | "$SL")"
contains "a spent limit is coloured red" "$sl_out" $'\033[31m'
contains "fast mode is visible" "$(printf '%s' "$sl_out" | plain)" "fast"
contains "an absent weekly window is skipped, not blanked" \
  "$(printf '%s' "$sl_out" | plain)" "Opus 5 fast · ctx 82% · 5h 91% (15m)"

sl_out="$(printf '{"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":8}}' | "$SL" | plain)"
eq "no rate limits yet degrades to model and context" "Opus 5 · ctx 8%" "$sl_out"

sl_out="$(printf '{"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":null}}' | "$SL" | plain)"
eq "a null percentage degrades to the model alone" "Opus 5" "$sl_out"

sl_rc=0
sl_out="$(printf 'not json at all' | "$SL" 2>/dev/null)" || sl_rc=$?
eq "garbage in exits 0" "0" "$sl_rc"
eq "garbage in prints nothing" "" "$sl_out"

# shellcheck disable=SC2088  # the tilde is the literal text being searched for
if grep -qF '~/.claude/statusline.sh' "$DIR/home/.claude/settings.json"; then
  ok "settings.json points at the status line"
else
  bad "settings.json points at the status line" "statusLine.command does not reference it"
fi
if grep -qF '.claude/statusline.sh' "$DIR/home.nix"; then
  ok "home.nix links the status line into ~/.claude"
else
  bad "home.nix links the status line into ~/.claude" "settings.json would point at a missing file"
fi

# --------------------------------------------------------------------------
section "session name"
# The script that names a session after its repo, called two ways: bare by the
# cc function, and with --hook by Claude Code itself. Every case runs against a
# throwaway $HOME holding a fabricated session registry, so nothing here depends
# on which real sessions happen to be open while the suite runs.
SN="$DIR/home/.claude/session-name.sh"
STHOME="$WORK/name-home"
REPO="$WORK/repos/myrepo"
OTHER="$WORK/repos/elsewhere"
mkdir -p "$STHOME/.claude/sessions" "$REPO/src/deep" "$OTHER" "$WORK/loose dir"
git -C "$REPO" init -q 2>/dev/null
git -C "$OTHER" init -q 2>/dev/null

name_in() { # cwd -> the name cc would pass to claude --name
  HOME="$STHOME" "$SN" "$1" 2>/dev/null
}
peer() { # pid, cwd, name -> a registry entry for a session that is running
  printf '{"pid":%s,"cwd":"%s","name":"%s"}' "$1" "$2" "$3" \
    >"$STHOME/.claude/sessions/$1.json"
}

if ! command -v jq >/dev/null 2>&1; then
  skip "session name (jq not found)"
else
  eq "a session in a repo is named after it" "myrepo" "$(name_in "$REPO")"
  eq "a session below the root is named after the root too" \
    "myrepo" "$(name_in "$REPO/src/deep")"
  eq "outside a repo it falls back to the directory" \
    "loose dir" "$(name_in "$WORK/loose dir")"

  # A pid still running under a name containing "claude" is what the script
  # counts as a session holding its number. sleep under another name is one: ps
  # reports the path it was launched through. A symlink rather than a copy,
  # because macOS kills a copied system binary a second in - its signature does
  # not survive the copy.
  mkdir -p "$WORK/fake"
  ln -sf /bin/sleep "$WORK/fake/claude"
  "$WORK/fake/claude" 120 &
  faker=$!
  peer "$faker" "$REPO" "myrepo"
  eq "a second session in the same repo is numbered" "myrepo-2" "$(name_in "$REPO")"
  "$WORK/fake/claude" 120 &
  faker2=$!
  peer "$faker2" "$REPO" "myrepo-2"
  eq "and a third one takes the next number" "myrepo-3" "$(name_in "$REPO")"
  kill "$faker2" 2>/dev/null
  wait "$faker2" 2>/dev/null
  rm -f "$STHOME/.claude/sessions/$faker2.json"

  peer 999999 "$REPO" "myrepo-9"
  eq "a session that has exited frees its number" "myrepo-2" "$(name_in "$REPO")"
  rm -f "$STHOME/.claude/sessions/999999.json"

  "$WORK/fake/claude" 120 &
  neighbour=$!
  peer "$neighbour" "$OTHER" "myrepo"
  eq "a live session in another repo does not take the number" \
    "myrepo-2" "$(name_in "$REPO")"
  kill "$neighbour" 2>/dev/null
  wait "$neighbour" 2>/dev/null

  kill "$faker" 2>/dev/null
  wait "$faker" 2>/dev/null
  eq "the number is freed when that session ends" "myrepo" "$(name_in "$REPO")"

  # --hook is the same answer wrapped in the JSON Claude Code reads back.
  sn_out="$(printf '{"cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$REPO" \
    | HOME="$STHOME" "$SN" --hook 2>/dev/null)"
  eq "--hook sets the session title to that name" "myrepo" \
    "$(printf '%s' "$sn_out" | jq -r '.hookSpecificOutput.sessionTitle // ""')"
  eq "--hook says which event it is answering" "SessionStart" \
    "$(printf '%s' "$sn_out" | jq -r '.hookSpecificOutput.hookEventName // ""')"

  sn_rc=0
  sn_out="$(printf 'not json at all' | HOME="$STHOME" "$SN" --hook 2>/dev/null)" || sn_rc=$?
  eq "garbage in exits 0" "0" "$sn_rc"
  if printf '%s' "$sn_out" | jq -e '.hookSpecificOutput.sessionTitle' >/dev/null 2>&1; then
    ok "garbage in still emits a title"
  else
    bad "garbage in still emits a title" "output was: $sn_out"
  fi
fi

# shellcheck disable=SC2088  # the tilde is the literal text being searched for
if grep -qF '~/.claude/session-name.sh --hook' "$DIR/home/.claude/settings.json"; then
  ok "settings.json runs it on SessionStart"
else
  bad "settings.json runs it on SessionStart" "no SessionStart hook references it"
fi
if grep -qF '.claude/session-name.sh' "$DIR/home.nix"; then
  ok "home.nix links it into ~/.claude"
else
  bad "home.nix links it into ~/.claude" "settings.json would point at a missing file"
fi
# The whole point of the exercise: cc has to hand the name to claude.
cc_body="$(sed -n '/^      cc() {/,/^      }/p' "$DIR/home.nix")"
contains "cc asks for a name" "$cc_body" "session-name.sh"
contains "cc passes it to claude --name" "$cc_body" "--name"
contains "cc still skips permissions and turns on remote control" "$cc_body" \
  "--dangerously-skip-permissions --remote-control"

# --------------------------------------------------------------------------
section "flake evaluation"
if [ -n "$FAST" ]; then
  skip "nix evaluations (--fast)"
elif ! command -v nix >/dev/null 2>&1; then
  skip "nix evaluations (nix not found)"
else
  attrs="$(nix eval --json "$DIR#darwinConfigurations" --apply builtins.attrNames 2>"$WORK/stderr" \
    | tr -d '[]" ' | tr ',' '\n' | sort)"
  if [ -z "$attrs" ]; then
    bad "darwinConfigurations evaluates" "$(cat "$WORK/stderr")"
  else
    eq "one configuration per listed username, and nothing else" \
      "$(printf '%s\n' "$listed" | tr '.' '-' | sort)" "$attrs"
  fi

  while read -r u; do
    attr="${u//./-}"
    got="$(nix eval --raw "$DIR#darwinConfigurations.$attr.config" --apply \
      "c: builtins.concatStringsSep \"\\n\" [
         c.system.primaryUser
         c.users.users.\"$u\".home
         c.home-manager.backupFileExtension
         c.home-manager.users.\"$u\".home.username
         c.home-manager.users.\"$u\".home.homeDirectory
       ]" 2>"$WORK/stderr")"
    if [ -z "$got" ]; then
      bad "#$attr evaluates" "$(grep -v '^warning:' "$WORK/stderr" | head -5)"
    else
      eq "#$attr is wired to $u end to end" "$u
/Users/$u
backup
$u
/Users/$u" "$got"
    fi

    # home.nix throws for a username it has no address for, so this failing
    # means a machine was added to the users list and not to gitEmails.
    email="$(nix eval --raw \
      "$DIR#darwinConfigurations.$attr.config.home-manager.users.\"$u\".programs.git.settings.user.email" \
      2>"$WORK/stderr")"
    case "$email" in
      *@*.*) ok "#$attr commits as $email" ;;
      *) bad "#$attr has a git address" "$(grep -v '^warning:' "$WORK/stderr" | head -3)" ;;
    esac
    # The README documents which address goes with which machine, which is
    # only useful while it still matches the configuration it describes.
    if grep -qF "$email" "$DIR/README.md"; then
      ok "README lists $u's address"
    else
      bad "README lists $u's address" "$email is configured but not documented"
    fi
  done <<<"$listed"

  # ------------------------------------------------------------------------
  section "homebrew activation"
  # The homebrew options compose into one `brew bundle` invocation and one
  # Brewfile, and nothing else in this suite looks at either. Both have
  # already been wrong in ways that no test noticed: `upgrade = true` silently
  # skipped a self-updating cask, and an `extraFlags = ["--force"]` that read
  # as harmless was suppressing `--adopt` on every cask install. Assert on
  # what actually gets run, not on the options that produce it.
  first_attr="$(printf '%s\n' "$listed" | head -n1 | tr '.' '-')"
  brewcmd="$(nix eval --raw \
    "$DIR#darwinConfigurations.$first_attr.config.system.activationScripts.homebrew.text" \
    2>"$WORK/stderr" | grep 'brew bundle')"
  if [ -z "$brewcmd" ]; then
    bad "the activation script runs brew bundle" "$(grep -v '^warning:' "$WORK/stderr" | head -3)"
  else
    contains "cleanup=zap reaches brew as --zap --force-cleanup" "$brewcmd" "--zap --force-cleanup"
    # --force-cleanup is fine and is what the module emits for cleanup=zap. A
    # bare --force is not: brew adds --adopt only when --force is absent, so
    # passing it turns off adoption and makes every cask install an overwrite.
    if printf '%s' "$brewcmd" | grep -qE ' --force($| )'; then
      bad "no bare --force (it would suppress --adopt)" "$brewcmd"
    else
      ok "no bare --force (it would suppress --adopt)"
    fi
    contains "HOMEBREW_NO_* is set, since activation does not inherit the shell" \
      "$brewcmd" "HOMEBREW_NO_ANALYTICS=1"
  fi

  brewfile="$(nix eval --raw \
    "$DIR#darwinConfigurations.$first_attr.config.homebrew.brewfile" 2>"$WORK/stderr")"
  if [ -z "$brewfile" ]; then
    bad "the Brewfile evaluates" "$(grep -v '^warning:' "$WORK/stderr" | head -3)"
  else
    # A cask marked auto_updates is never "outdated" to brew bundle, so
    # onActivation.upgrade skips it unless the entry is greedy. miniforge is
    # the only one of these that self-updates; greedy on the others would race
    # their updaters for no reason.
    contains "miniforge is greedy, or upgrade silently skips it" \
      "$brewfile" 'cask "miniforge", greedy: true'
    for c in wezterm claude-code; do
      if printf '%s' "$brewfile" | grep -qE "cask \"$c\".*greedy"; then
        bad "$c is not greedy" "greedy on a cask that does not self-update races its own updater"
      else
        ok "$c is not greedy"
      fi
    done
  fi
fi

# --------------------------------------------------------------------------
printf '\n%s%d passed%s, %s%d failed%s, %d skipped\n' \
  "$G" "$pass" "$Z" "$([ "$fail" -gt 0 ] && printf '%s' "$R")" "$fail" "$Z" "$skipped"
[ "$fail" -eq 0 ]
