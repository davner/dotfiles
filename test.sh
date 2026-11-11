#!/usr/bin/env bash
# Checks the things in this repo that fail silently, fail only on the other
# machine, or fail an hour into an activation: the username -> flake attribute
# mapping, the users attrset parsing, the rebuild and bootstrap scripts, the
# Claude hooks, the settings merges, and the out-of-store symlink targets.
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

# From git, so a new script is linted without anyone listing it. Untracked
# files count too: the flake would miss them, but a typo in one should not.
SCRIPTS=()
while IFS= read -r s; do SCRIPTS+=("$s"); done < <(cd "$DIR" && git ls-files -co --exclude-standard '*.sh')

# --------------------------------------------------------------------------
section "syntax and lint"
[ "${#SCRIPTS[@]}" -gt 0 ] || bad "git lists the shell scripts" "git ls-files found no *.sh in $DIR"
have_shellcheck=""
command -v shellcheck >/dev/null 2>&1 && have_shellcheck=1
for s in "${SCRIPTS[@]}"; do
  # zsh syntax is not bash syntax, and shellcheck does not read zsh at all.
  case "$(head -n 1 "$DIR/$s")" in
    *zsh*)
      if err="$(zsh -n "$DIR/$s" 2>&1)"; then ok "zsh -n $s"; else bad "zsh -n $s" "$err"; fi
      continue
      ;;
  esac
  if err="$(bash -n "$DIR/$s" 2>&1)"; then ok "bash -n $s"; else bad "bash -n $s" "$err"; fi
  if [ -z "$have_shellcheck" ]; then continue; fi
  if err="$(shellcheck "$DIR/$s" 2>&1)"; then ok "shellcheck $s"; else bad "shellcheck $s" "$err"; fi
done
[ -n "$have_shellcheck" ] || skip "shellcheck (nix develop --command ./test.sh installs it)"
# Catches a broken workflow before a push finds out, and shellchecks the
# `run:` blocks that CI would otherwise only fail on inside the runner.
if command -v actionlint >/dev/null 2>&1; then
  if err="$(cd "$DIR" && actionlint 2>&1)"; then ok "actionlint"; else bad "actionlint" "$err"; fi
else
  skip "actionlint (nix develop --command ./test.sh installs it)"
fi
# users.sh parses flake.nix by shape, so a reformat is exactly the change that
# could break it silently. Gating the format keeps that shape from drifting one
# hand edit at a time.
if command -v nixfmt >/dev/null 2>&1; then
  if err="$(cd "$DIR" && git ls-files -z '*.nix' | xargs -0 nixfmt --check 2>&1)"; then
    ok "nixfmt"
  else
    bad "nixfmt" "$err (run: nix fmt)"
  fi
else
  skip "nixfmt (nix develop --command ./test.sh installs it)"
fi

# --------------------------------------------------------------------------
section "shell parser"
# Both Bash hooks read a command through this, so a case it gets wrong is a
# rule in each of them that fires on plain text or misses a real command.
PARSER="$DIR/home/.claude/hooks/shell-parse.sh"
parses() { # name, command, expected records
  eq "parses $1" "$3" "$(printf '%s' "$2" | "$PARSER" 2>&1)"
}
# shellcheck disable=SC2016  # unexpanded text is what is under test
{
  parses "quotes and an escaped space" 'echo "a b" '\''c;d'\'' e\ f' $'w echo\nw a b\nw c;d\nw e f\ne'
  parses "escaped separators as words" 'echo a\;b \&\& c' $'w echo\nw a;b\nw &&\nw c\ne'
  parses "escapes inside double quotes" 'echo "a\"b\$c\d"' $'w echo\nw a"b$c\\\\d\ne'
  parses "pipes, &&, ||, ; and newlines" $'a | b && c || d; e\nf' $'w a\ne\nw b\ne\nw c\ne\nw d\ne\nw e\ne\nw f\ne'
  parses "assignments before the first word only" 'A=1 B="x y" cmd C=2' $'a A=1\na B=x y\nw cmd\nw C=2\ne'
  parses "a quoted assignment as a word" '"A=1" cmd' $'w A=1\nw cmd\ne'
  parses "redirects" 'cmd >out 2>>err <in 2>&1 &>all >|clob' $'w cmd\n> out\n> err\n< in\n> all\n> clob\ne'
  parses "a redirect glued to the word before it" 'echo x>a.ts' $'w echo\nw x\n> a.ts\ne'
  parses "a quoted heredoc as data" $'cat <<\'EOF\' >f\nline $x; git add .\nEOF\nnext' \
    $'w cat\n> f\nh line $x; git add .\\n\ne\nw next\ne'
  parses "a double-quoted heredoc delimiter" $'cat <<"EOF"\na\nEOF' $'w cat\nh a\\n\ne'
  parses "a bare heredoc delimiter" $'cat <<EOF\na\nEOF' $'w cat\nh a\\n\ne'
  parses "<<- stripping tabs" $'cat <<-EOF\n\tone\n\tEOF\nnext' $'w cat\nh one\\n\ne\nw next\ne'
  parses "two heredocs, each on its statement" $'cat <<A; cat <<B\na\nA\nb\nB' $'w cat\nh a\\n\ne\nw cat\nh b\\n\ne'
  parses "a delimiter as a substring" $'cat <<END\nENDING\nEND' $'w cat\nh ENDING\\n\ne'
  parses "a here-string" 'cat <<<"hi there"' $'w cat\nh hi there\\n\ne'
  parses "a subshell" '(cd x && git push); y' $'w cd\nw x\ne 1\nw git\nw push\ne 1\nw y\ne'
  parses "\$( ) inside double quotes" 'echo "$(git status)" done' \
    $'w echo\nw $(git status)\nw done\ne\nw git\nw status\ne 1'
  parses "backticks" 'echo `date`' $'w echo\nw `date`\ne\nw date\ne 1'
  parses "nested \$( )" 'a $(b $(c))' $'w a\nw $(b $(c))\ne\nw b\nw $(c)\ne 1\nw c\ne 1/2'
  parses "process substitution" 'diff <(a) >(b)' $'w diff\nw <(a)\nw >(b)\ne\nw a\ne 1\nw b\ne 2'
  parses "braces and reserved words" '{ git add .; } && if a; then b; fi' \
    $'w git\nw add\nw .\ne\nw a\ne\nw b\ne'
  parses "a function body" 'f() { g; }' $'w f\ne\nw g\ne'
  parses "a comment" 'echo a # git add .' $'w echo\nw a\ne'
  parses "arithmetic and parameter expansion" 'echo $((1+2)) ${a//;/,}' $'w echo\nw $((1+2))\nw ${a//;/,}\ne'
  parses "a heredoc inside \$( )" $'git commit -m "$(cat <<\'EOF\'\nfix: x\nEOF\n)"' \
    $'w git\nw commit\nw -m\nw $(cat <<\'EOF\'\\nfix: x\\nEOF\\n)\ne\nw cat\nh fix: x\\n\ne 1'
  parses "a newline inside quotes" $'echo "a\nb"' $'w echo\nw a\\nb\ne'
  parses "a backslash" "echo 'a\\b'" $'w echo\nw a\\\\b\ne'
  parses "a line continuation" $'echo a \\\nb' $'w echo\nw a\nw b\ne'
  parses "an empty command" '' ''
}

# --------------------------------------------------------------------------
section "ai credit module"
# guard-bash.sh, provenance.sh and comment-audit.sh all judge by this one file,
# so its cases live here and each caller's section tests only how it reads them.
CREDIT="$DIR/home/.claude/hooks/ai-credit.sh"
credit_check() { # function, text with \n escapes -> its exit status
  local t
  printf -v t '%b' "$2"
  # shellcheck source=/dev/null
  (source "$CREDIT" && "$1" "$t")
  echo $?
}
credit_table() { # name, function; cases as `want|text` on stdin
  local want text got miss=""
  while IFS='|' read -r want text; do
    [ -n "$text" ] || continue
    got=$(credit_check "$2" "$text")
    [ "$got" = "$want" ] || miss="$miss
    expected $want, got $got: $text"
  done
  if [ -z "$miss" ]; then ok "$1"; else bad "$1" "$miss"; fi
}

# 0 credits a tool, 1 does not. A key counts only at a line start, with the
# name on its line or the first non-blank one after.
credit_table "credits_tool decides what credits a tool" credits_tool <<'CASES'
0|feat: x\n\nCo-Authored-By: Claude <n@a.com>
0|feat: x\n\nco-authored-by: Claude <n@anthropic.com>
0|feat: x\n\nCo-Authored-By: Opus 5 <noreply@anthropic.com>
0|feat: x\n\nCo-Authored-By: Cursor Agent <agent@cursor.sh>
0|feat: x\n\nCo-Authored-By: Copilot <copilot@github.com>
0|feat: x\n\nCo-Authored-By: Devin <158243242+devin-ai-integration[bot]@users.noreply.github.com>
0|feat: x\n\nCo-Authored-By: Copilot <12345+copilot-swe-agent[bot]@users.noreply.github.com>
0|feat: x\n\nCo-Authored-By: Some Bot <99+some-random-agent[bot]@users.noreply.github.com>
0|feat: x\n\nAssisted-by: ChatGPT
0|feat: x\n\nGenerated by Gemini
0|fix: x\n\nClaude-Session: https://x
0|fix: x\n\n🤖 Generated with Claude Code
0|fix: x\n\nCo-Authored-By:\nClaude <noreply@anthropic.com>
0|fix: x\n\nCo-Authored-By:\n\n\n\nClaude <noreply@anthropic.com>
0|  Co-Authored-By: Claude <n@a.com>
1|feat: x\n\nCo-Authored-By: Jane Doe <jane@example.com>
1|feat: x\n\nSigned-off-by: Cody Smith <cody@example.com>
1|feat: x\n\nCo-Authored-By: Jane Cursor <jane@example.com>
1|feat: x\n\nCo-Authored-By: Devin Parker <devin@example.com>
1|feat: x\n\nCo-Authored-By: Jane Doe <9876+janedoe@users.noreply.github.com>
1|feat: x\n\nCo-Authored-By: Some One <99+some-random-agent@users.noreply.github.com>
1|fix(guard-bash): close the co-authored-by line-break bypass\n\nClaude split trailer test showed a credit spanning two lines slipped through\nheaders that were only checked on one line.
1|fix: rename co-authored-by check to attribution_reason\n\nClaude early draft flagged this differently, so the message now reads MSG_TRAILERS too.
1|fix(guard-bash): anchor the co-authored-by key to its line start\n\nClaude Code writes this repo, so the credit rule and the subject vocabulary collide.
1|fix: x\n\nThe rule ignores a co-authored-by: Claude <n@a.com> buried in a sentence.
1|fix: x\n\nCo-authored-by trailers are what this rule reads.\nThe line between carries content of its own.\nClaude is mentioned only here.
1|feat(claude): add a draft-ticket skill
1|fix: stop the claude-code cask lagging
1|docs: link the anthropic docs page
CASES

# 0 is an agent, model, or bot. A brand counts only as a whole word.
credit_table "is_tool decides who is a tool" is_tool <<'CASES'
0|Claude <claude@anthropic.com>
0|Opus 5 <noreply@anthropic.com>
0|dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>
0|GPT-5 <bot@example.com>
1|Dan <d@example.com>
1|Jane Cursor <jane@example.com>
1|Devin Parker <devin@example.com>
1|Claudette Moreau <c@example.com>
1|Jane Doe <9876+janedoe@users.noreply.github.com>
CASES

meta_check() { [[ $1 =~ $SESSION_META ]]; }
# Matched as written here; guard-bash.sh adds case folding for commit messages.
credit_table "SESSION_META names session talk and nothing else" meta_check <<'CASES'
0|kept both branches as requested
0|as discussed with the team
0|as instructed
0|per the plan this stays sync
0|addresses the review finding on nulls
0|folds in the review feedback
1|retries per the spec, RFC 7231
1|one request per second
1|the plan runs nightly
1|open one worktree per ticket
1|cap comments per reviewer
1|per the reviewers' count
CASES

# --------------------------------------------------------------------------
section "bash guard hook"
# The rules this enforces are absolute in home/AGENTS.md, which is exactly why
# they are a hook: a prompt is advice and a hook is a decision. The allow cases
# matter more than the block cases - a guard that blocks ordinary work is one
# that gets switched off.
GUARD="$DIR/home/.claude/hooks/guard-bash.sh"
if ! command -v jq >/dev/null 2>&1; then
  skip "guard-bash.sh (jq not found)"
elif [ ! -x "$GUARD" ]; then
  bad "guard-bash.sh is executable" "$GUARD"
else
  # Exit 2 is the only code that blocks a PreToolUse call; 0 lets it through.
  guard() { printf '{"tool_name":"Bash","tool_input":{"command":%s}}' \
    "$(printf '%s' "$1" | jq -Rs .)" | "$GUARD" >/dev/null 2>&1; echo $?; }

  blocked=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(guard "$c")" = "2" ] || blocked="$blocked
    let through: $c"
  done <<'CASES'
git add .
git add -A
git add --all
cd src && git add .
git push --force origin main
git push --force-with-lease
git push -f
git clean -dfx
git clean -xfd
git reset --hard
git reset --hard HEAD~1
git -C src reset --hard
git clean -fd
git clean -f
git clean --force
git branch -D topic
git branch --delete --force topic
git branch -d -f topic
git checkout .
git checkout -- .
git restore .
git restore -- .
git config claude.allowPush true
git config --unset claude.allowPush
cc-push
cc-push on
cc-push off
cd /tmp && cc-push
gh pr create --title "feat: x" --body "y"
gh pr new
gh pr merge 12 --squash
gh-axi pr create --title "feat: x"
gh-axi pr merge 12
npx -y gh-axi pr create --title "feat: x"
npx gh-axi pr merge 12 --squash
git merge topic
git merge --no-ff topic
git merge --no-edit resource-backend-schema
git -C ../integration merge topic
git pull
git pull origin main
git pull --no-rebase
git pull --rebase=false
git pull --rebase=no
CASES
  if [ -z "$blocked" ]; then
    ok "the absolute rules are blocked"
  else
    bad "the absolute rules are blocked" "$blocked"
  fi

  # An AI credit is judged in the message being committed, never in the command
  # text around it, so every route the message arrives by gets a case below.
  trailer='git commit -m "feat: x

Co-Authored-By: Claude <n@a.com>"'
  eq "an AI trailer in a commit message is blocked" "2" "$(guard "$trailer")"

  # An AI credit is not always spelled "Claude": git reads trailer keys
  # case-insensitively, a model number is a name with no brand in it, and other
  # vendors sign the same way. Each of these is a model in what git records, so
  # none of them may depend on the word Claude to be caught. Each payload spans
  # lines, so each is its own variable - the loop above reads line by line.
  lower_key='git commit -m "feat: x

co-authored-by: Claude <n@anthropic.com>"'
  eq "a lowercase trailer key is blocked" "2" "$(guard "$lower_key")"

  model_name='git commit -m "feat: x

Co-Authored-By: Opus 5 <noreply@anthropic.com>"'
  eq "a model number with a vendor address is blocked" "2" "$(guard "$model_name")"

  other_vendor='git commit -m "feat: x

Co-Authored-By: Cursor Agent <agent@cursor.sh>"'
  eq "another vendor's agent is blocked" "2" "$(guard "$other_vendor")"

  copilot='git commit -m "feat: x

Co-Authored-By: Copilot <copilot@github.com>"'
  eq "copilot is blocked" "2" "$(guard "$copilot")"

  # The cost of widening that match is false positives, and a guard that blocks
  # ordinary work is one that gets switched off. A human co-author is
  # legitimate, and this repo's own subjects say "claude" without crediting it.
  human='git commit -m "feat: x

Co-Authored-By: Jane Doe <jane@example.com>"'
  eq "a human co-author passes" "0" "$(guard "$human")"

  # A DCO sign-off is a human's legal attestation, never how a model credits
  # itself, so the key is out of the match entirely and `-s` stays usable.
  dco='git commit -s -m "feat: x

Signed-off-by: Cody Smith <cody@example.com>"'
  eq "a DCO sign-off by a human named Cody passes" "0" "$(guard "$dco")"
  eq "a plain signed-off commit passes" "0" "$(guard 'git commit -s -m "fix: x"')"

  # Every vendor word that is also a given name comes out of the name list; the
  # vendor domain still catches those agents when they credit themselves.
  named_cursor='git commit -m "feat: x

Co-Authored-By: Jane Cursor <jane@example.com>"'
  eq "a human surnamed Cursor passes" "0" "$(guard "$named_cursor")"
  named_devin='git commit -m "feat: x

Co-Authored-By: Devin Parker <devin@example.com>"'
  eq "a human named Devin passes" "0" "$(guard "$named_devin")"

  # Which is why the agent is matched by its handle and by the shape of a bot
  # address instead, neither of which a human contributor carries.
  devin_bot='git commit -m "feat: x

Co-Authored-By: Devin <158243242+devin-ai-integration[bot]@users.noreply.github.com>"'
  eq "the devin bot trailer is blocked" "2" "$(guard "$devin_bot")"
  swe_bot='git commit -m "feat: x

Co-Authored-By: Copilot <12345+copilot-swe-agent[bot]@users.noreply.github.com>"'
  eq "another vendor's bot address is blocked" "2" "$(guard "$swe_bot")"
  # No brand word anywhere, so only the bot-address pattern can fire.
  bare_bot='git commit -m "feat: x

Co-Authored-By: Some Bot <99+some-random-agent[bot]@users.noreply.github.com>"'
  eq "a bot address with no brand word is blocked" "2" "$(guard "$bare_bot")"
  human_noreply='git commit -m "feat: x

Co-Authored-By: Jane Doe <9876+janedoe@users.noreply.github.com>"'
  eq "an ordinary github noreply passes" "0" "$(guard "$human_noreply")"
  # The same address without the suffix. Read as a bracket expression instead of
  # two literals, `[bot]` would match the `t` of "agent" and block this.
  not_a_bot='git commit -m "feat: x

Co-Authored-By: Some One <99+some-random-agent@users.noreply.github.com>"'
  eq "the same handle without [bot] passes" "0" "$(guard "$not_a_bot")"

  # A credit counts when it is in the message being committed, and nowhere else.
  # Each of these is a false positive the gate produced when it read the command.
  mentioned=""
  attr_bare=$'# note: never add Co-Authored-By: Claude <n@a.com> to a message\necho hi'
  [ "$(guard "$attr_bare")" = "0" ] || mentioned="$mentioned
    a comment mentioning a trailer blocked a command that does not commit"
  attr_comment=$'# note: Co-Authored-By: Claude <n@a.com>\ngit commit -m "fix: short"'
  [ "$(guard "$attr_comment")" = "0" ] || mentioned="$mentioned
    a comment mentioning a trailer blocked the commit beside it"
  attr_doc=$'cat > /tmp/d.txt <<\'END\'\nCo-Authored-By: Claude <n@a.com>\nEND\ngit commit -m "fix: short"'
  [ "$(guard "$attr_doc")" = "0" ] || mentioned="$mentioned
    another command's heredoc blocked the commit beside it"
  attr_echo='echo "Co-Authored-By: Claude <n@a.com>" && git commit -m "fix: short"'
  [ "$(guard "$attr_echo")" = "0" ] || mentioned="$mentioned
    an unrelated command blocked the commit beside it"
  attr_sess=$'# Claude-Session: https://x\ngit commit -m "fix: short"'
  [ "$(guard "$attr_sess")" = "0" ] || mentioned="$mentioned
    a session trailer in a comment blocked the commit beside it"
  attr_emoji='echo "🤖" && git commit -m "fix: short"'
  [ "$(guard "$attr_emoji")" = "0" ] || mentioned="$mentioned
    an emoji outside the message blocked the commit beside it"
  if [ -z "$mentioned" ]; then
    ok "a credit outside the message does not block"
  else
    bad "a credit outside the message does not block" "$mentioned"
  fi

  # ...and it counts by whichever route the message reaches the commit.
  attr_heredoc=$'git commit -F - <<\'MSG\'\nfix: x\n\nCo-Authored-By: Claude <n@a.com>\nMSG'
  eq "a credit arriving by heredoc is blocked" "2" "$(guard "$attr_heredoc")"
  printf 'fix: x\n\nCo-Authored-By: Claude <n@a.com>\n' >"$WORK/attr-msg.txt"
  eq "a credit arriving by -F file is blocked" "2" \
    "$(guard "git commit -F $WORK/attr-msg.txt")"
  eq "a credit in a later -m is blocked" "2" \
    "$(guard 'git commit -m "fix: x" -m "Co-Authored-By: Claude <n@a.com>"')"
  eq "a credit in an amended message is blocked" "2" \
    "$(guard 'git commit --amend -m "fix: x" -m "Co-Authored-By: Claude <n@a.com>"')"
  eq "a session trailer in the message is blocked" "2" \
    "$(guard 'git commit -m "fix: x" -m "Claude-Session: https://x"')"
  eq "the robot emoji in the message is blocked" "2" \
    "$(guard 'git commit -m "fix: x" -m "🤖 Generated with Claude Code"')"
  # git puts a --trailer into the committed message without it being in the
  # body, so the attribution rule reads it and the shape caps do not.
  eq "a credit passed with --trailer is blocked" "2" \
    "$(guard 'git commit -m "fix: x" --trailer "Co-Authored-By: Claude <n@a.com>"')"
  eq "a credit passed with --trailer= is blocked" "2" \
    "$(guard 'git commit -m "fix: x" --trailer="Claude-Session: https://x"')"
  eq "a human --trailer passes" "0" \
    "$(guard 'git commit -m "fix: x" --trailer "Reviewed-by: Jane <j@example.com>"')"
  eq "a --trailer does not consume a body line" "0" \
    "$(guard 'git commit -m "fix: x" -m "one
two
three" --trailer "Reviewed-by: Jane"')"
  eq "a --trailer does not consume a bullet" "0" \
    "$(guard 'git commit -m "fix: x" -m "- one
- two" --trailer "Reviewed-by: Jane"')"

  # Splitting the key from the name is still a credit: git joins paragraphs with
  # a blank line, so neither a line break nor a flag boundary hides one.
  split_body='git commit -m "fix: x

Co-Authored-By:
Claude <noreply@anthropic.com>"'
  eq "a credit split across a line break is blocked" "2" "$(guard "$split_body")"
  eq "a credit split across two -m flags is blocked" "2" \
    "$(guard 'git commit -m "fix: x" -m "Co-Authored-By:" -m "Claude <noreply@anthropic.com>"')"
  eq "a credit split across two --trailer flags is blocked" "2" \
    "$(guard 'git commit -m "fix: x" --trailer "Co-Authored-By:" --trailer "Claude <noreply@anthropic.com>"')"
  eq "a credit split across two --trailer= flags is blocked" "2" \
    "$(guard 'git commit -m "fix: x" --trailer="Co-Authored-By:" --trailer="Claude <noreply@anthropic.com>"')"
  printf 'fix: x\n\nCo-Authored-By:\n' >"$WORK/split-key.txt"
  eq "a --trailer completing a -F file's key is blocked" "2" \
    "$(guard "git commit -F $WORK/split-key.txt --trailer \"Claude <noreply@anthropic.com>\"")"
  # An empty -m adds a second blank line that git's cleanup collapses, so the
  # gap has to be counted in non-blank lines rather than in newlines.
  eq "an empty -m between key and name does not hide it" "2" \
    "$(guard 'git commit -m "fix: x" -m "Co-Authored-By:" -m "" -m "Claude <noreply@anthropic.com>"')"

  # git honours a trailer only at a line start, so a key buried in a sentence
  # opens nothing. These are commits this repo has to stay able to write.
  fp_split='git commit -m "fix(guard-bash): close the co-authored-by line-break bypass" -m "Claude split trailer test showed a credit spanning two lines slipped through
headers that were only checked on one line."'
  eq "a key mid-subject over a Claude body passes" "0" "$(guard "$fp_split")"
  fp_rename='git commit -m "fix: rename co-authored-by check to attribution_reason" -m "Claude early draft flagged this differently, so the message now reads MSG_TRAILERS too."'
  eq "a key mid-subject over a one-line body passes" "0" "$(guard "$fp_rename")"
  # Subject, one blank line, body: the commonest shape there is, and the one the
  # gap reaches across, so the anchor is all that keeps it out.
  common='git commit -m "fix(guard-bash): anchor the co-authored-by key to its line start" -m "Claude Code writes this repo, so the credit rule and the subject vocabulary collide."'
  eq "subject with a key, one blank line, then a body, passes" "0" "$(guard "$common")"
  eq "a key buried mid-sentence opens no credit" "0" \
    "$(guard 'git commit -m "fix: x" -m "The rule ignores a co-authored-by: Claude <n@a.com> buried in a sentence."')"
  # And with the key at a line start, the one-hop gap is what draws the line.
  prose='git commit -m "fix: x" -m "Co-authored-by trailers are what this rule reads.
The line between carries content of its own.
Claude is mentioned only here."'
  eq "a line-start key and a model two lines apart passes" "0" "$(guard "$prose")"

  # A message this cannot read is a commit that goes through, credit rule and
  # all: blocking what you cannot see is worse than the credit slipping past.
  unreadable=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(guard "$c")" = "0" ] || unreadable="$unreadable
    blocked: $c"
  done <<CASES
git commit
git commit --amend --no-edit
git commit -F $WORK/no-such-message.txt
CASES
  if [ -z "$unreadable" ]; then
    ok "a message this cannot read is not blocked"
  else
    bad "a message this cannot read is not blocked" "$unreadable"
  fi
  # A deliberate, accepted limit: the payload arrives on stdin from another
  # statement, and a filter between the two makes it undecidable without running.
  piped_credit=$'echo "fix: x\n\nCo-Authored-By: Claude <n@a.com>" | git commit -F -'
  eq "a credit piped to -F - is a known miss" "0" "$(guard "$piped_credit")"

  human_allowed=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(guard "$c")" = "2" ] && human_allowed="$human_allowed
    blocked: $c"
  done <<'CASES'
git commit -m "feat(claude): add a draft-ticket skill"
git commit -m "fix: stop the claude-code cask lagging"
git commit -m "docs: link the anthropic docs page"
CASES
  if [ -z "$human_allowed" ]; then
    ok "ordinary subjects naming claude pass"
  else
    bad "ordinary subjects naming claude pass" "$human_allowed"
  fi

  # The message-shape cap has to read the message out of the command first, so
  # each carrier form gets a case of its own.
  long_subject="feat(scope): a subject that keeps going and going and going and going past the cap"
  eq "a subject over 72 characters is blocked" "2" \
    "$(guard "git commit -m \"$long_subject\"")"
  eq "a subject at 72 characters is allowed" "0" \
    "$(guard "git commit -m \"${long_subject:0:72}\"")"

  body5='git commit -m "fix: x" -m "one
two
three
four
five"'
  eq "a body over three lines is blocked" "2" "$(guard "$body5")"
  body3='git commit -m "fix: x" -m "one
two
three"'
  eq "a three-line body is allowed" "0" "$(guard "$body3")"
  bullets3='git commit -m "fix: x" -m "- one
- two
- three"'
  eq "a third bullet is blocked" "2" "$(guard "$bullets3")"
  eq "two bullets are allowed" "0" \
    "$(guard 'git commit -m "fix: x" -m "- one
- two"')"
  eq "repeated -m values are read as subject and body" "2" \
    "$(guard "git commit -m 'fix: x' -m one -m two -m three -m four")"

  meta=""
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    [ "$(guard "git commit -m 'fix: x' -m '$m'")" = "2" ] || meta="$meta
    let through: $m"
  done <<'CASES'
Kept both branches as requested.
Per the plan this stays synchronous.
Addresses the review finding on nulls.
Folds in the Review Feedback on nulls.
Also renames the helper.
CASES
  if [ -z "$meta" ]; then
    ok "a body line about the session is blocked"
  else
    bad "a body line about the session is blocked" "$meta"
  fi
  # A commit body legitimately describes a behavior change in these words,
  # unlike a code comment, so the comment-audit patterns stop short of here.
  eq "a behavior change described as 'no longer' is allowed" "0" \
    "$(guard "git commit -m 'fix: x' -m 'The cache no longer invalidates on write.'")"
  # The meta list stops where honest engineering prose starts: both of these say
  # something the diff cannot, which is exactly what a body is for.
  eq "a consequence phrased as 'this change' is allowed" "0" \
    "$(guard "git commit -m 'fix: x' -m 'Without this change the cache never invalidates.'")"
  eq "an architecture note using 'alongside the' is allowed" "0" \
    "$(guard "git commit -m 'fix: x' -m 'Runs alongside the existing awk pass to avoid a second scan.'")"
  # The verbose commit this cap exists to stop is usually written without the
  # blank line, so line 2 onward is a body whether or not git would fold it in.
  noblank='git commit -m "Refactor auth flow
Also updates the token cache
Adds new validation
Removes old code path
Bumps version numbers"'
  eq "an unseparated message past the cap is blocked" "2" "$(guard "$noblank")"
  short_noblank='git commit -m "fix: x
The cap is the log wrap, not a preference."'
  eq "an unseparated message within the cap is allowed" "0" "$(guard "$short_noblank")"
  eq "the subject is scanned for the meta list too" "2" \
    "$(guard "git commit -m 'As requested, rename the helper function'")"

  heredoc_long=$(cat <<'CMD'
git commit -F - <<'MSG'
fix: x

one
two
three
four
MSG
CMD
  )
  eq "a heredoc body over three lines is blocked" "2" "$(guard "$heredoc_long")"
  heredoc_ok=$(cat <<'CMD'
git commit -F - <<'MSG'
fix: tighten the cap

The cap is git's own log wrap, not a preference.
MSG
CMD
  )
  eq "a heredoc message within the caps is allowed" "0" "$(guard "$heredoc_ok")"
  # The hook has a 5 s timeout, and a commit whose message outruns it goes through unjudged.
  huge=$'git commit -F - <<\'MSG\'\nfix: x\n\n'
  for i in $(seq 5000); do huge="$huge line $i of a body far past the cap"$'\n'; done
  huge="${huge}Co-Authored-By: Claude <n@a.com>"$'\nMSG'
  start=$SECONDS
  eq "a 5000-line heredoc message is judged" "2" "$(guard "$huge")"
  if ((SECONDS - start <= 2)); then
    ok "a 5000-line heredoc message is judged within 2 s"
  else
    bad "a 5000-line heredoc message is judged within 2 s" "took $((SECONDS - start)) s"
  fi
  cat_subst=$(cat <<'CMD'
git commit -m "$(cat <<'EOF'
feat(scope): a subject that keeps going and going and going and going past the cap

body
EOF
)"
CMD
  )
  eq "a -m \$(cat <<EOF) subject is read" "2" "$(guard "$cat_subst")"
  # A command is a sequence of statements, and only the one that invokes
  # `git commit` is the commit. Everything here is a false positive the gate
  # produced when it searched the whole command instead of one statement.
  not_ours=""
  next_line=$'git commit -m "fix: valid short subject"\nfoo -m one -m two -m three -m four'
  [ "$(guard "$next_line")" = "0" ] || not_ours="$not_ours
    the next line's flags became a body"
  other_doc=$'printf x > /tmp/d.txt <<\'END\'\ngit commit -m "fix: x" -m "one" -m "two" -m "three" -m "four"\nEND'
  [ "$(guard "$other_doc")" = "0" ] || not_ours="$not_ours
    another command's heredoc body was read as tokens"
  commented=$'# example: git commit -m "fix: x" -m "one" -m "two" -m "three" -m "four"\necho hi'
  [ "$(guard "$commented")" = "0" ] || not_ours="$not_ours
    a shell comment was read as a command"
  if [ -z "$not_ours" ]; then
    ok "only the statement that commits is judged"
  else
    bad "only the statement that commits is judged" "$not_ours"
  fi

  # And the flip side: a statement that does commit is judged wherever it sits.
  eq "a commit inside \$(...) is judged" "2" \
    "$(guard "echo \$(git commit -m 'As requested, rename the helper')")"
  eq "a commit after an unrelated statement is judged" "2" \
    "$(guard "cd /tmp && git commit -m 'As requested, rename the helper'")"
  eq "the second of two commits is judged" "2" \
    "$(guard "git commit -m 'fix: ok' && git commit -m 'As requested, rename it'")"
  eq "two compliant commits both pass" "0" \
    "$(guard "git commit -m 'fix: one' && git commit -m 'fix: two'")"

  # The delimiter may be quoted or bare, and only a line that is the delimiter
  # ends the body - a line merely containing the word does not.
  bare_delim=$'git commit -F - <<MSG\nfix: x\n\none\ntwo\nthree\nfour\nMSG'
  eq "an unquoted heredoc delimiter is read" "2" "$(guard "$bare_delim")"
  dq_delim=$'git commit -F - <<"MSG"\nfix: x\n\none\ntwo\nthree\nfour\nMSG'
  eq "a double-quoted heredoc delimiter is read" "2" "$(guard "$dq_delim")"
  substr_delim=$'git commit -F - <<\'END\'\nfix: x\n\nENDING is not END\nand nor is this\nnor this\nnor this\nEND'
  eq "the delimiter as a substring does not end the body" "2" "$(guard "$substr_delim")"

  # A heredoc that belongs to something else in the same command is not the
  # commit message, whichever side of the commit it sits on.
  before=$(cat <<'CMD'
cat >/tmp/x <<'EOF'
one
two
three
four
EOF
git commit -m 'fix: short'
CMD
  )
  eq "a heredoc before the commit is not the message" "0" "$(guard "$before")"
  after=$(cat <<'CMD'
git commit -m 'fix: short' && cat >/tmp/x <<'EOF'
one
two
three
four
EOF
CMD
  )
  eq "a heredoc after the commit is not the message" "0" "$(guard "$after")"

  printf 'feat: x\n\n- also adds a loader\n' >"$WORK/commit-msg.txt"
  eq "a -F file message is read" "2" "$(guard "git commit -F $WORK/commit-msg.txt")"
  # A short-option cluster carries its argument the same way the lone flag does.
  eq "-F fused into a short cluster is read" "2" \
    "$(guard "git commit -aF $WORK/commit-msg.txt")"
  eq "-F fused onto its path is read" "2" \
    "$(guard "git commit -aF$WORK/commit-msg.txt")"
  printf 'fix: x\n\n# Please enter the commit message\n# a\n# b\n# c\n# d\n' \
    >"$WORK/commit-tpl.txt"
  eq "a commit template's comment block does not count" "0" \
    "$(guard "git commit --file $WORK/commit-tpl.txt")"

  # A message this cannot read is not a message it may block: an --amend reusing
  # the stored text, a -F pointing nowhere, an editor commit.
  unread=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(guard "$c")" = "0" ] || unread="$unread
    blocked: $c"
  done <<CASES
git commit --amend --no-edit
git commit --amend
git commit
git commit -a
git commit -F -
git commit -F $WORK/not-a-file.txt
echo "git commit -m This commit is fine"
CASES
  if [ -z "$unread" ]; then
    ok "a message the hook cannot read is allowed"
  else
    bad "a message the hook cannot read is allowed" "$unread"
  fi

  # The hook runs under whatever bash is on PATH, and a stock macOS /bin/bash is
  # 3.2 - where an empty array expanded under `set -u` aborts the whole script
  # and the guard silently passes everything.
  if [ -x /bin/bash ] && ! /bin/bash -c 'echo "${BASH_VERSINFO[0]}"' | grep -qx 5; then
    old_bash=""
    while IFS= read -r c; do
      [ -n "$c" ] || continue
      payload="$(printf '{"tool_name":"Bash","tool_input":{"command":%s}}' \
        "$(printf '%s' "$c" | jq -Rs .)")"
      here="$(printf '%s' "$payload" | "$GUARD" >/dev/null 2>&1; echo $?)"
      there="$(printf '%s' "$payload" | /bin/bash "$GUARD" >/dev/null 2>&1; echo $?)"
      [ "$here" = "$there" ] || old_bash="$old_bash
    $c: exit $here here, exit $there under /bin/bash"
    done <<'CASES'
git commit -m "fix: a real message"
git commit -m "As requested, rename the helper function"
git commit -m "fix: x" -m "one"
git commit --amend --no-edit
git add .
git -C "a b" push
cd /tmp && git reset --hard
git restore --staged .
CASES
    if [ -z "$old_bash" ]; then
      ok "nothing in the guard needs a bash newer than /bin/bash"
    else
      bad "nothing in the guard needs a bash newer than /bin/bash" "$old_bash"
    fi
  else
    skip "guard-bash.sh under an older /bin/bash (this one is bash 5)"
  fi

  allowed=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(guard "$c")" = "0" ] || allowed="$allowed
    blocked: $c"
  done <<'CASES'
git add home/.claude/hooks/guard-bash.sh
git add ./src/foo.ts
git add -u home/AGENTS.md
git status --short
git log --oneline -5
git reset HEAD home/AGENTS.md
git clean -n
git branch -d topic
git restore home/AGENTS.md
git checkout -- home/AGENTS.md
git restore --staged .
git config --get claude.allowPush
cc-push status
gh pr view 12
gh pr list --state open
gh pr checks 12
npx -y gh-axi pr view 42 --comments
git commit -m "fix: a real message"
echo "git add ."
git merge --ff-only topic
git -C ../integration merge --ff-only topic
git merge --squash topic
git merge --abort
git merge --continue
git merge-base --is-ancestor main HEAD
git pull --rebase
git pull -r origin main
git pull --ff-only
git pull --rebase=merges
git cherry-pick 1a2b3c4
nix develop --command ./test.sh
CASES
  if [ -z "$allowed" ]; then
    ok "ordinary work is not blocked"
  else
    bad "ordinary work is not blocked" "$allowed"
  fi

  # Each hides its command from a reader that splits on separators alone: behind
  # an assignment, inside a subshell or substitution, or after a wrapper.
  hidden=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(guard "$c")" = "2" ] || hidden="$hidden
    let through: $c"
  done <<'CASES'
FOO=1 git push --force
(git add .)
$(git reset --hard)
echo "$(git reset --hard)"
echo `git reset --hard`
x=$(git add .)
cat <(git add .)
sudo git add .
sudo -u root git push --force
env git add .
env -i PATH=/x git add .
command git add .
exec git add .
time git reset --hard
nohup git clean -fd
/usr/bin/git add .
{ git add .; }
if true; then git add .; fi
! git add .
(cd /tmp && git reset --hard)
true && git add . # a trailing comment
CASES
  if [ -z "$hidden" ]; then
    ok "a rule sees past quotes, subshells and wrappers"
  else
    bad "a rule sees past quotes, subshells and wrappers" "$hidden"
  fi

  as_text=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(guard "$c")" = "0" ] || as_text="$as_text
    blocked: $c"
  done <<'CASES'
echo "note; git reset --hard x"
echo 'git add .'
echo git add .
git commit -m "note: git add . and git reset --hard"
printf '%s' "git push --force"
# git add .
git log --grep 'reset --hard'
command -v git
echo "a; git add ." | cat
CASES
  if [ -z "$as_text" ]; then
    ok "a command named in text is not run"
  else
    bad "a command named in text is not run" "$as_text"
  fi
  heredoc_text=$'cat <<\'EOF\' > notes.md\ngit add .\ngit reset --hard\nEOF'
  eq "a heredoc body naming a blocked command passes" "0" "$(guard "$heredoc_text")"
  # The hooks are linked into ~/.claude through the store, so the parser has to
  # be found beside the real file at the end of that chain.
  mkdir -p "$WORK/guard-link/store" "$WORK/guard-link/home"
  ln -s "$GUARD" "$WORK/guard-link/store/guard-bash.sh"
  ln -s ../store/guard-bash.sh "$WORK/guard-link/home/guard-bash.sh"
  eq "a guard reached through two links still finds the parser" "2" \
    "$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git add ."}}' |
      "$WORK/guard-link/home/guard-bash.sh" >/dev/null 2>&1; echo $?)"
  mkdir -p "$WORK/guard-alone"
  cp "$GUARD" "$WORK/guard-alone/guard-bash.sh"
  lone_err="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git add ."}}' |
    "$WORK/guard-alone/guard-bash.sh" 2>&1 >/dev/null)"
  lone_rc=$?
  eq "a guard without its parser fails without blocking" "1" "$lone_rc"
  contains "a guard without its parser says so" "$lone_err" "shell-parse.sh is missing"
  cp "$DIR/home/.claude/hooks/shell-parse.sh" "$WORK/guard-alone/shell-parse.sh"
  lone_err="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git add ."}}' |
    "$WORK/guard-alone/guard-bash.sh" 2>&1 >/dev/null)"
  lone_rc=$?
  eq "a guard without ai-credit.sh fails without blocking" "1" "$lone_rc"
  contains "a guard without ai-credit.sh says so" "$lone_err" "ai-credit.sh is missing"

  # A push is judged against the repo it runs in, so these carry a cwd and
  # real repos: one opted in, one not, and a directory that is no repo at all.
  guard_in() { printf '{"tool_name":"Bash","tool_input":{"command":%s},"cwd":%s}' \
    "$(printf '%s' "$2" | jq -Rs .)" "$(printf '%s' "$1" | jq -Rs .)" |
    "$GUARD" >/dev/null 2>&1; echo $?; }
  PUSHES="$WORK/pushes"
  mkdir -p "$PUSHES/norepo" "$PUSHES/with space"
  git init -q "$PUSHES/opted" && git -C "$PUSHES/opted" config claude.allowPush true
  git init -q "$PUSHES/closed"
  git init -q "$PUSHES/with space/opted" &&
    git -C "$PUSHES/with space/opted" config claude.allowPush true
  eq "push from a repo that has not opted in is blocked" "2" \
    "$(guard_in "$PUSHES/closed" 'git push origin main')"
  eq "push from an opted-in repo is allowed" "0" \
    "$(guard_in "$PUSHES/opted" 'git push origin main')"
  eq "push outside any repo is blocked" "2" "$(guard_in "$PUSHES/norepo" 'git push')"
  eq "push with no cwd in the payload is blocked" "2" "$(guard 'git push')"
  eq "-C names the repo, not the cwd (opted in)" "0" \
    "$(guard_in "$PUSHES/closed" "git -C $PUSHES/opted push")"
  eq "-C names the repo, not the cwd (closed)" "2" \
    "$(guard_in "$PUSHES/opted" "git -C $PUSHES/closed push")"
  eq "a relative -C resolves against the cwd" "0" "$(guard_in "$PUSHES" 'git -C opted push')"
  eq "a quoted -C with a space resolves" "0" \
    "$(guard_in "$PUSHES" 'git -C "with space/opted" push')"
  eq "cd into an opted-in repo, then push, is allowed" "0" \
    "$(guard_in "$PUSHES" 'cd opted && git push')"
  eq "cd into a closed repo, then push, is blocked" "2" \
    "$(guard_in "$PUSHES/opted" "cd $PUSHES/closed && git push")"
  eq "the last cd wins" "2" "$(guard_in "$PUSHES" 'cd opted && cd ../closed && git push')"
  # shellcheck disable=SC2016  # the unexpanded variable is the case under test
  eq "a cd this cannot resolve blocks the push" "2" \
    "$(guard_in "$PUSHES/opted" 'cd "$SOMEWHERE" && git push')"
  eq "--git-dir hides the repo, so the push is blocked" "2" \
    "$(guard_in "$PUSHES/opted" 'git --git-dir=../closed/.git push')"
  forced=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(guard_in "$PUSHES/opted" "$c")" = "2" ] || forced="$forced
    let through: $c"
  done <<'CASES'
git push --force origin main
git push --force-with-lease
git push -f
git push -uf origin main
git push origin +main
git -C . push --force
CASES
  if [ -z "$forced" ]; then
    ok "a force push is blocked even in an opted-in repo"
  else
    bad "a force push is blocked even in an opted-in repo" "$forced"
  fi
  # A subshell's cd ends with the subshell, so it moves only the pushes inside it.
  eq "cd and push inside one subshell is allowed" "0" \
    "$(guard_in "$PUSHES/closed" "(cd $PUSHES/opted && git push)")"
  eq "a cd inside a subshell does not carry out of it" "2" \
    "$(guard_in "$PUSHES/closed" "(cd $PUSHES/opted) && git push")"
  eq "a cd inside \$( ) does not carry out of it" "2" \
    "$(guard_in "$PUSHES/closed" "echo \$(cd $PUSHES/opted) && git push")"
  eq "a cd inside braces carries on" "0" \
    "$(guard_in "$PUSHES/closed" "{ cd $PUSHES/opted; } && git push")"
  eq "a wrapper that changes directory blocks the push" "2" \
    "$(guard_in "$PUSHES/opted" 'sudo -D /tmp git push')"
fi

# --------------------------------------------------------------------------
section "claude user settings"
# /config, /model and /effort all persist into ~/.claude/settings.json, the one
# user-scope file Claude Code reads. The whole reason it is merged in at
# activation rather than symlinked is that a link routes those writes into this
# working tree. Both halves of that are asserted here, because reintroducing
# either one is a one-line change that nothing else notices.
BASE="$DIR/home/.claude/settings.base.json"
if [ -f "$BASE" ]; then ok "settings.base.json exists"; else bad "settings.base.json exists" "$BASE"; fi
if ! command -v jq >/dev/null 2>&1; then
  skip "settings.base.json checks (jq not found)"
else
  if err="$(jq -e . "$BASE" 2>&1 >/dev/null)"; then
    ok "settings.base.json is valid JSON"
  else
    bad "settings.base.json is valid JSON" "$err"
  fi
  # Base wins the merge, so any of these three here is reverted on every
  # rebuild - the same fight, just losing in the other direction.
  volatile="$(jq -r '[paths(scalars) | .[0]] | unique | map(select(. == "model" or . == "effortLevel" or . == "theme")) | join(" ")' "$BASE")"
  if [ -z "$volatile" ]; then
    ok "settings.base.json claims none of model, effortLevel, theme"
  else
    bad "settings.base.json claims none of model, effortLevel, theme" \
      "these would be reverted on every rebuild: $volatile"
  fi
  # Nothing in home.nix installs the obsidian skills; Claude Code does, from these keys.
  if jq -e '.extraKnownMarketplaces["obsidian-skills"].autoUpdate == true
      and .enabledPlugins["obsidian@obsidian-skills"] == true' "$BASE" >/dev/null 2>&1; then
    ok "settings.base.json declares and enables the obsidian plugin"
  else
    bad "settings.base.json declares and enables the obsidian plugin" \
      "want extraKnownMarketplaces.obsidian-skills.autoUpdate and enabledPlugins.obsidian@obsidian-skills both true"
  fi
  # A hook on the wrong event or matcher never fires, and nothing says so. The
  # gate must match Skill, its only evidence of a load; "-" is no matcher.
  rows=0
  while read -r ev matcher script; do
    [ -n "$ev" ] || continue
    rows=$((rows + 1))
    if jq -e --arg ev "$ev" --arg m "$matcher" --arg s "$script" '
        if $ev == "statusLine" then [.statusLine.command]
        else [.hooks[$ev][]? | select((.matcher // "-") == $m) | .hooks[]?.command] end
        | map(select(contains($s))) | length == 1' "$BASE" >/dev/null 2>&1; then
      ok "settings.base.json runs $script on $ev ($matcher)"
    else
      bad "settings.base.json runs $script on $ev ($matcher)" "want exactly one such command"
    fi
  done <<'HOOKS'
SessionStart  -                               ~/.claude/hooks/session-name.sh --hook
SessionStart  -                               skills/impeccable/scripts/impeccable
PreToolUse    Bash                            $HOME/.claude/hooks/guard-bash.sh
PreToolUse    Skill|Write|Edit|MultiEdit|Bash $HOME/.claude/hooks/skill-gate.sh
PostToolUse   Write|Edit|MultiEdit            $HOME/.claude/hooks/comment-audit.sh
PostToolUse   Edit|Write                      skills/impeccable/scripts/impeccable
Stop          -                               skills/impeccable/scripts/impeccable
statusLine    -                               ~/.claude/hooks/statusline.sh
HOOKS
  eq "the table above covers every command settings.base.json runs" "$rows" \
    "$(jq '[.. | objects | .command? // empty] | length' "$BASE")"
fi
if grep -q 'mkOutOfStoreSymlink.*\.claude/settings\.json' "$DIR/home.nix"; then
  bad "home.nix does not link settings.json" \
    "a link there sends every /config write back into this repo"
else
  ok "home.nix does not link settings.json"
fi
# The merge itself is tested under "json merge"; this is the one call site.
# shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
if grep -q 'jsonMerge} --drop-link deep "${dotfiles}/home/\.claude/settings\.base\.json"' "$DIR/home.nix"; then
  ok "home.nix merges settings.base.json, failing on invalid JSON"
else
  bad "home.nix merges settings.base.json, failing on invalid JSON" \
    "want --drop-link deep and no --skip-invalid: a broken settings.json must stop the rebuild"
fi

# --------------------------------------------------------------------------
section "vscode user settings"
VS="$DIR/home/vscode"
if ! command -v jq >/dev/null 2>&1; then
  skip "home/vscode checks (jq not found)"
else
  for f in settings.base.json keybindings.base.json extensions.json; do
    if err="$(jq -e . "$VS/$f" 2>&1 >/dev/null)"; then ok "$f is valid JSON"; else bad "$f is valid JSON" "$err"; fi
  done
  # The merge appends keybindings and deep-merges settings, so the wrong shape fails at activation instead.
  if jq -e 'type == "object"' "$VS/settings.base.json" >/dev/null 2>&1 &&
    jq -e 'type == "array"' "$VS/keybindings.base.json" >/dev/null 2>&1; then
    ok "settings base is an object and keybindings base an array"
  else
    bad "settings base is an object and keybindings base an array" "home.nix merges them as deep and append-unique"
  fi
  if jq -e 'has("Default") and all(.[]; type == "array" and all(.[]; test("^[a-z0-9-]+\\.[a-z0-9-]+$"; "i")))' "$VS/extensions.json" >/dev/null 2>&1; then
    ok "extensions.json maps profiles to publisher.name ids"
  else
    bad "extensions.json maps profiles to publisher.name ids" "want {\"Default\": [\"pub.ext\", ...], ...}"
  fi
fi
if grep -q 'mkOutOfStoreSymlink.*Code/User' "$DIR/home.nix"; then
  bad "home.nix does not link VS Code's settings" "a link sends every settings-UI toggle back into this repo"
else
  ok "home.nix does not link VS Code's settings"
fi
# shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
if grep -q 'jsonMerge} --skip-invalid deep "${dotfiles}/home/vscode/settings\.base\.json"' "$DIR/home.nix" &&
  grep -q 'jsonMerge} --skip-invalid append-unique key,command,when "${dotfiles}/home/vscode/keybindings\.base\.json"' "$DIR/home.nix"; then
  ok "home.nix merges VS Code's settings and keybindings, skipping commented files"
else
  bad "home.nix merges VS Code's settings and keybindings, skipping commented files" \
    "want --skip-invalid deep for settings and --skip-invalid append-unique key,command,when for keybindings"
fi

# --------------------------------------------------------------------------
section "json merge"
JM="$DIR/home/json-merge.sh"
if ! command -v jq >/dev/null 2>&1; then
  skip "json-merge.sh (jq not found)"
else
  JW="$WORK/jm"
  mkdir -p "$JW"
  jm() { # args -> sets JM_RC and JM_ERR
    JM_ERR="$("$JM" "$@" 2>&1 >/dev/null)"
    JM_RC=$?
  }
  printf '%s\n' '{"a": 1, "n": {"x": 1, "y": 1}, "hooks": [1, 2]}' >"$JW/obj.base.json"
  printf '%s\n' '[{"key": "k", "command": "c", "when": "w"}, {"key": "k2", "command": "c2"}]' >"$JW/arr.base.json"

  jm deep "$JW/obj.base.json" "$JW/new/settings.json"
  if [ "$JM_RC" = 0 ] && jq -e '. == {"a": 1, "n": {"x": 1, "y": 1}, "hooks": [1, 2]}' "$JW/new/settings.json" >/dev/null 2>&1; then
    ok "deep: a missing target and its folder are created from the base"
  else
    bad "deep: a missing target and its folder are created from the base" "rc=$JM_RC" "$JM_ERR"
  fi
  jm append-unique key,command,when "$JW/arr.base.json" "$JW/new/keybindings.json"
  eq "append-unique: a missing target starts as an empty array" "2" "$(jq length "$JW/new/keybindings.json" 2>&1)"

  printf '%s\n' '{"a": 0, "mine": true, "n": {"x": 0, "z": 1}, "hooks": [9, 9, 9]}' >"$JW/s.json"
  jm deep "$JW/obj.base.json" "$JW/s.json"
  eq "deep: base wins a conflicting key and the target's other keys survive" \
    '1 true' "$(jq -r '"\(.a) \(.mine)"' "$JW/s.json")"
  eq "deep: nested objects merge key by key" '{"x":1,"y":1,"z":1}' "$(jq -cS .n "$JW/s.json")"
  eq "deep: base replaces an array outright" '[1,2]' "$(jq -c .hooks "$JW/s.json")"

  printf '%s\n' '{"real": true}' >"$JW/linked-to.json"
  ln -s "$JW/linked-to.json" "$JW/l1.json"
  ln -s "$JW/linked-to.json" "$JW/l2.json"
  jm --drop-link deep "$JW/obj.base.json" "$JW/l1.json"
  if [ ! -L "$JW/l1.json" ] && jq -e '.real and .a == 1' "$JW/l1.json" >/dev/null 2>&1 &&
    [ "$(cat "$JW/linked-to.json")" = '{"real": true}' ]; then
    ok "--drop-link: a leftover link becomes a real file that keeps what it pointed at"
  else
    bad "--drop-link: a leftover link becomes a real file that keeps what it pointed at" "$(cat "$JW/l1.json")"
  fi
  ln -s "$JW/gone.json" "$JW/l3.json"
  jm --drop-link deep "$JW/obj.base.json" "$JW/l3.json"
  if [ "$JM_RC" = 0 ] && [ ! -L "$JW/l3.json" ] && jq -e '.a == 1' "$JW/l3.json" >/dev/null 2>&1; then
    ok "--drop-link: a dangling link becomes a file built from the base"
  else
    bad "--drop-link: a dangling link becomes a file built from the base" "rc=$JM_RC" "$JM_ERR"
  fi
  jm deep "$JW/obj.base.json" "$JW/l2.json"
  if [ -L "$JW/l2.json" ] && jq -e '.real and .a == 1' "$JW/linked-to.json" >/dev/null 2>&1; then
    ok "without --drop-link a linked target is merged through the link"
  else
    bad "without --drop-link a linked target is merged through the link"
  fi

  printf '{} // mine\n' >"$JW/bad.json"
  jm deep "$JW/obj.base.json" "$JW/bad.json"
  if [ "$JM_RC" = 1 ] && [ "$(cat "$JW/bad.json")" = "{} // mine" ]; then
    ok "invalid JSON fails by default and leaves the file alone"
  else
    bad "invalid JSON fails by default and leaves the file alone" "rc=$JM_RC"
  fi
  contains "and the failure names the file" "$JM_ERR" "$JW/bad.json"
  jm --skip-invalid deep "$JW/obj.base.json" "$JW/bad.json"
  if [ "$JM_RC" = 0 ] && [ "$(cat "$JW/bad.json")" = "{} // mine" ]; then
    ok "--skip-invalid exits 0 and leaves the file alone"
  else
    bad "--skip-invalid exits 0 and leaves the file alone" "rc=$JM_RC"
  fi
  contains "and says it skipped" "$JM_ERR" "skipped"
  jm deep "$JW/no-such-base.json" "$JW/s2.json"
  if [ "$JM_RC" = 1 ] && [ ! -e "$JW/s2.json" ]; then
    ok "a missing base fails before touching the target"
  else
    bad "a missing base fails before touching the target" "rc=$JM_RC"
  fi

  printf '%s\n' '[{"key": "k", "command": "c", "when": "w", "args": "mine"}, {"key": "k", "command": "c", "when": "other"}]' >"$JW/kb.json"
  jm append-unique key,command,when "$JW/arr.base.json" "$JW/kb.json"
  eq "append-unique: an entry matching on every key is not added again" \
    "1" "$(jq '[.[] | select(.key == "k" and .when == "w")] | length' "$JW/kb.json")"
  eq "append-unique: the target's own version of it is kept" "mine" "$(jq -r '.[0].args' "$JW/kb.json")"
  eq "append-unique: an entry that differs only in when is kept" \
    "1" "$(jq '[.[] | select(.when == "other")] | length' "$JW/kb.json")"
  eq "append-unique: a base entry with no when is appended" "k2" "$(jq -r '.[-1].key' "$JW/kb.json")"
  before="$(cat "$JW/kb.json")"
  jm append-unique key,command,when "$JW/arr.base.json" "$JW/kb.json"
  eq "append-unique: a second run changes nothing" "$before" "$(cat "$JW/kb.json")"

  # A write that fails partway, as on a full disk, must leave the old file whole.
  jq -n '[range(400)] | map({key: "k\(.)", value: "padding padding padding"}) | from_entries' >"$JW/big.base.json"
  printf '%s\n' '{"mine": true}' >"$JW/full.json"
  (
    trap '' XFSZ
    ulimit -f 4
    "$JM" deep "$JW/big.base.json" "$JW/full.json"
  ) >/dev/null 2>&1
  full_rc=$?
  if [ "$full_rc" != 0 ] && [ "$(cat "$JW/full.json")" = '{"mine": true}' ]; then
    ok "a failed write fails and leaves the target as it was"
  else
    bad "a failed write fails and leaves the target as it was" "rc=$full_rc" "$(head -c 80 "$JW/full.json")"
  fi
  leftovers="$(find "$JW" -name '.json-merge.*')"
  eq "and leaves no temp file behind" "" "$leftovers"
  jm deep "$JW/obj.base.json" "$JW/l2.json"
  eq "a linked target is still a link after a rename-based write" "link" "$([ -L "$JW/l2.json" ] && echo link)"

  printf '%s\n' '[{"key": "d", "command": "c"}, {"key": "d", "command": "c"}]' >"$JW/dup.base.json"
  printf '%s\n' '[]' >"$JW/dup.json"
  jm append-unique key,command,when "$JW/dup.base.json" "$JW/dup.json"
  eq "append-unique: an entry repeated in the base is added once" "1" "$(jq length "$JW/dup.json")"

  for args in "" "deep" "deep $JW/obj.base.json" "append-unique $JW/arr.base.json $JW/x.json" "--bogus deep a b" "shallow a b"; do
    # shellcheck disable=SC2086 # each case is deliberately split into words
    jm $args
    eq "usage error exits 2: json-merge.sh ${args//$JW\//}" "2" "$JM_RC"
  done
fi

# --------------------------------------------------------------------------
section "metals-java-home"
MJH="$DIR/home/vscode/metals-java-home.sh"
if ! command -v jq >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  skip "metals-java-home (needs jq and git)"
else
  MW="$WORK/mjh"
  mkdir -p "$MW/stub" "$MW/jdk" "$MW/ws/a/.vscode" "$MW/ws/b" "$MW/ws/nojava" "$MW/ws/tracked/.vscode" "$MW/ws/commented/.vscode"
  # Stands in for direnv: a folder's JAVA_HOME is whatever its .fake-java-home names.
  cat >"$MW/stub/direnv" <<'EOF'
#!/usr/bin/env bash
[ "$1" = exec ] && [ -f "$2/.fake-java-home" ] && cat "$2/.fake-java-home"
exit 0
EOF
  chmod +x "$MW/stub/direnv"
  for d in a nojava tracked commented; do touch "$MW/ws/$d/.envrc"; done
  for d in a tracked commented; do printf '%s' "$MW/jdk" >"$MW/ws/$d/.fake-java-home"; done
  printf '{"files.watcherExclude": {"**/target/**": true}}\n' >"$MW/ws/a/.vscode/settings.json"
  printf '{} // mine\n' >"$MW/ws/commented/.vscode/settings.json"
  printf '{}\n' >"$MW/ws/tracked/.vscode/settings.json"
  git -C "$MW/ws/tracked" init -q && git -C "$MW/ws/tracked" add .vscode/settings.json
  printf '{"folders": [{"path": "a"}, {"path": "b"}, {"path": "nojava"}]}\n' >"$MW/ws/x.code-workspace"
  run_mjh() { PATH="$MW/stub:$PATH" "$MJH" "$@" >"$MW/out" 2>&1; }

  run_mjh "$MW/ws/x.code-workspace"
  rc=$?
  run_mjh "$MW/ws/x.code-workspace"
  if [ "$rc" = 0 ] && jq -e --arg jh "$MW/jdk" '."metals.javaHome" == $jh and ."files.watcherExclude"."**/target/**" == true and length == 2' "$MW/ws/a/.vscode/settings.json" >/dev/null 2>&1; then
    ok "metals-java-home sets javaHome from a workspace file, keeps other keys, and reruns cleanly"
  else
    bad "metals-java-home sets javaHome from a workspace file, keeps other keys, and reruns cleanly" "rc=$rc" "$(cat "$MW/out")"
  fi
  if [ ! -e "$MW/ws/b/.vscode" ] && [ ! -e "$MW/ws/nojava/.vscode" ]; then
    ok "metals-java-home leaves folders without .envrc or JAVA_HOME alone"
  else
    bad "metals-java-home leaves folders without .envrc or JAVA_HOME alone"
  fi
  run_mjh "$MW/ws/tracked"
  rc=$?
  if [ "$rc" != 0 ] && [ "$(cat "$MW/ws/tracked/.vscode/settings.json")" = "{}" ]; then
    ok "metals-java-home refuses a git-tracked settings.json"
  else
    bad "metals-java-home refuses a git-tracked settings.json" "a nix store path would reach the team"
  fi
  run_mjh "$MW/ws/commented"
  rc=$?
  if [ "$rc" != 0 ] && [ "$(cat "$MW/ws/commented/.vscode/settings.json")" = "{} // mine" ]; then
    ok "metals-java-home skips a hand-commented settings.json"
  else
    bad "metals-java-home skips a hand-commented settings.json"
  fi
  if run_mjh; then bad "metals-java-home with no arguments fails"; else ok "metals-java-home with no arguments fails"; fi
fi
if grep -q 'mkOutOfStoreSymlink.*metals-java-home.sh' "$DIR/home.nix"; then
  ok "home.nix puts metals-java-home on PATH"
else
  bad "home.nix puts metals-java-home on PATH"
fi

# --------------------------------------------------------------------------
section "changelog"
# CHANGELOG.md is generated by a workflow and read weeks later, so a template
# that drops, duplicates or reorders commits has no other moment where it
# fails. These assert shapes the template has to hold rather than a snapshot of
# the history, so an ordinary commit never means editing this section.
if ! command -v git-cliff >/dev/null 2>&1; then
  skip "git-cliff (nix develop --command ./test.sh installs it)"
else
  CL="$WORK/CHANGELOG.md"
  if err="$(cd "$DIR" && git-cliff -o "$CL" 2>&1 >/dev/null)"; then
    ok "cliff.toml and its template render"
  else
    bad "cliff.toml and its template render" "$err"
  fi

  headings="$(grep '^## ' "$CL")"
  eq "one heading per date" \
    "$(printf '%s\n' "$headings" | sort -u | wc -l | tr -d ' ')" \
    "$(printf '%s\n' "$headings" | wc -l | tr -d ' ')"

  # ISO dates sort lexically, so the header's "newest first" is checkable.
  if [ "$(printf '%s\n' "$headings" | sort -r)" = "$headings" ]; then
    ok "dates run newest first"
  else
    bad "dates run newest first" "$(printf '%s' "$headings" | tr '\n' ' ')"
  fi

  # Matched by sha rather than by subject, because a commit is free to talk
  # about merging, or about regenerating the changelog, without being one.
  leaked=""
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    grep -qF "$sha" "$CL" && leaked="$leaked ${sha:0:7}"
  done < <(cd "$DIR" && git log --merges --format='%H')
  if [ -z "$leaked" ]; then
    ok "merge commits stay out"
  else
    bad "merge commits stay out" "reached the changelog:$leaked"
  fi

  leaked=""
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    grep -qF "$sha" "$CL" && leaked="$leaked ${sha:0:7}"
  done < <(cd "$DIR" && git log --format='%H%x09%s' |
    awk -F'\t' '$2 == "docs: regenerate the changelog" {print $1}')
  if [ -z "$leaked" ]; then
    ok "the changelog bot's own commits stay out"
  else
    bad "the changelog bot's own commits stay out" "reached the changelog:$leaked"
  fi

  # The other half of that skip: wide enough to catch the bot, never wide
  # enough to swallow a real commit that happens to be about the changelog.
  expected="$(cd "$DIR" && git log --no-merges --format='%H%x09%s' |
    awk -F'\t' '$2 != "docs: regenerate the changelog" {print $1}')"
  missing=""
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    grep -qF "$sha" "$CL" || missing="$missing ${sha:0:7}"
  done <<<"$expected"
  if [ -z "$missing" ]; then
    ok "every other commit reaches the changelog"
  else
    bad "every other commit reaches the changelog" "missing:$missing"
  fi

  eq "one entry per commit" \
    "$(printf '%s\n' "$expected" | grep -c .)" \
    "$(grep -c '^- \*\*' "$CL")"

  # An unconventional subject hands the template the whole message, which
  # breaks the entry across a paragraph and leaves its link on a line alone.
  if orphan="$(grep -n 'commit/' "$CL" | grep -v '^[0-9]*:- \*\*')"; then
    bad "every entry is one line" "$orphan"
  else
    ok "every entry is one line"
  fi
fi

# --------------------------------------------------------------------------
section "users attrset"
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
  skip "no-argument default ($me is not in the users attrset)"
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
for s in bootstrap.sh rebuild.sh users.sh home/.claude/hooks/shell-parse.sh; do
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
contains "bootstrap.sh skips a username already configured" "$RUN_OUT" "nothing to do"

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
# Templated targets are left to the evaluated "links from the repo" check below.
targets="$(sed -nE 's|.*mkOutOfStoreSymlink "\$\{dotfiles\}/([^"$]+)".*|\1|p' "$DIR/home.nix" | sort -u)"
if [ -z "$targets" ]; then
  bad "found mkOutOfStoreSymlink targets in home.nix" "the sed found nothing - did home.nix change shape?"
else
  while read -r t; do
    if [ -e "$DIR/$t" ]; then ok "$t exists"; else bad "$t exists" "home.nix links to a path this repo does not have"; fi
  done <<<"$targets"
fi

# --------------------------------------------------------------------------
section "links from the repo"
# A flake sees only tracked files and mkOutOfStoreSymlink never checks its
# target, so a missed `git add` or a wrong path is a silently broken link.
entries() { # repo folder, find tests -> the names in it, sorted
  local d=$1
  shift
  find "$DIR/$d" -mindepth 1 -maxdepth 1 "$@" -exec basename {} \; | sort
}
link_target() { # links, user, home.file key -> the repo path it links to
  awk -F'\t' -v k="$3" -v p="ln -s /Users/$2/.dotfiles/" -v e=' $out' \
    '$1 == k && index($2, p) == 1 && substr($2, length($2) - length(e) + 1) == e {
      print substr($2, length(p) + 1, length($2) - length(p) - length(e)) }' <<<"$1"
}
linked_each() { # links, user, repo folder, home folder, names on disk
  local name missing="" extra why=()
  while read -r name; do
    [ -n "$name" ] || continue
    [ "$(link_target "$1" "$2" "$4/$name")" = "$3/$name" ] || missing="$missing $name"
  done <<<"$5"
  extra="$(awk -F'\t' -v d="$4/" 'index($1, d) == 1 { n = substr($1, length(d) + 1); if (n !~ /\//) print n }' <<<"$1" |
    grep -vxF -f <(printf '%s\n' "$5") | tr '\n' ' ')"
  [ -z "$missing" ] || why+=("not linked to its repo path:$missing - a flake sees only tracked files, git add it")
  [ -z "${extra// /}" ] || why+=("linked but not on disk: $extra")
  if [ "${#why[@]}" -eq 0 ]; then
    ok "$2: each entry of $3 is linked into ~/$4"
  else
    bad "$2: each entry of $3 is linked into ~/$4" "${why[@]}"
  fi
}
if [ -n "$FAST" ]; then
  skip "home.nix links what settings.base.json runs, and each hook, rule and skill (--fast)"
elif ! command -v nix >/dev/null 2>&1; then
  skip "home.nix links what settings.base.json runs, and each hook, rule and skill (nix not found)"
elif ! command -v jq >/dev/null 2>&1; then
  skip "home.nix links what settings.base.json runs, and each hook, rule and skill (jq not found)"
else
  # impeccable's paths are under skills/, where its own installer puts them.
  # shellcheck disable=SC2016  # the $HOME is the literal text being matched
  settings_runs="$(jq -r '.. | objects | .command? // empty' "$BASE" |
    grep -oE '(~|\$HOME|\$\{HOME\})/\.claude/[A-Za-z0-9._/-]+' |
    sed -E 's#^(~|\$HOME|\$\{HOME\})/##' | grep -v '^\.claude/skills/' | sort -u)"
  [ -n "$settings_runs" ] ||
    bad "found the ~/.claude paths settings.base.json runs" "none matched - did the commands change shape?"
  hooks_on_disk="$(entries home/.claude/hooks -type f)"
  rules_on_disk="$(entries home/.claude/rules -type f -name '*.md')"
  skills_on_disk="$(entries home/.claude/skills -type d)"
  while read -r u; do
    [ -n "$u" ] || continue
    # shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
    links="$(nix eval --raw "$DIR#darwinConfigurations.${u//./-}.config.home-manager.users.\"$u\".home.file" \
      --apply 'f: builtins.concatStringsSep "\n" (builtins.concatMap (n:
        let s = f.${n}.source; in
        if builtins.substring 0 8 n == ".claude/" && builtins.isAttrs s && s ? buildCommand
        then [ "${n}\t${s.buildCommand}" ] else [ ]) (builtins.attrNames f))' \
      2>"$WORK/stderr")"
    if [ -z "$links" ]; then
      bad "$u: home.file evaluates" "$(grep -v '^warning:' "$WORK/stderr" | head -5)"
      continue
    fi
    broken=""
    while read -r p; do
      [ -n "$p" ] || continue
      rel="$(link_target "$links" "$u" "$p")"
      if [ -z "$rel" ]; then
        broken="$broken ~/$p(no out-of-store link into ~/.dotfiles)"
      elif [ ! -f "$DIR/$rel" ] || [ ! -x "$DIR/$rel" ]; then
        broken="$broken ~/$p($rel is not an executable file)"
      elif ! git -C "$DIR" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
        broken="$broken ~/$p($rel is untracked)"
      fi
    done <<<"$settings_runs"
    if [ -z "$broken" ]; then
      ok "$u: everything settings.base.json runs is linked to an executable tracked file"
    else
      bad "$u: everything settings.base.json runs is linked to an executable tracked file" "$broken"
    fi
    linked_each "$links" "$u" home/.claude/hooks .claude/hooks "$hooks_on_disk"
    linked_each "$links" "$u" home/.claude/rules .claude/rules "$rules_on_disk"
    linked_each "$links" "$u" home/.claude/skills .claude/skills "$skills_on_disk"
  done <<<"$listed"
fi

# --------------------------------------------------------------------------
section "skills"
SKILLS_DIR="$DIR/home/.claude/skills"
on_disk="$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
# Third-party skills come from flake inputs, so an upstream move or rename is
# a link to nothing, or to a skill Claude knows by another name.
if [ -n "$FAST" ]; then
  skip "third-party skill links resolve in both skill folders (--fast)"
elif ! command -v nix >/dev/null 2>&1; then
  skip "third-party skill links resolve in both skill folders (nix not found)"
else
  while read -r u; do
    [ -n "$u" ] || continue
    # shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
    tp="$(nix eval --raw "$DIR#darwinConfigurations.${u//./-}.config.home-manager.users.\"$u\".home.file" \
      --apply 'f: builtins.concatStringsSep "\n" (map (n: "${n}\t${toString f.${n}.source}")
        (builtins.filter (n: builtins.match "\\.(claude|agents)/skills/[^/]+" n != null) (builtins.attrNames f)))' \
      2>"$WORK/stderr")"
    if [ -z "$tp" ]; then
      bad "$u: third-party skills evaluate" "$(grep -v '^warning:' "$WORK/stderr" | head -5)"
      continue
    fi
    claude_tp="" agents_tp="" broken=""
    while IFS=$'\t' read -r link src; do
      name="${link##*/}"
      case "$link" in
        .claude/*) grep -qxF "$name" <<<"$on_disk" && continue; claude_tp="$claude_tp $name" ;;
        .agents/*) agents_tp="$agents_tp $name" ;;
      esac
      n="$(sed -nE 's/^name: *(.+)$/\1/p' "$src/SKILL.md" 2>/dev/null | head -1)"
      [ "$n" = "$name" ] || broken="$broken $link(name:${n:-no SKILL.md})"
    done <<<"$tp"
    if [ -n "$claude_tp" ] && [ "$claude_tp" = "$agents_tp" ]; then
      ok "$u: third-party skills are linked into both skill folders"
    else
      bad "$u: third-party skills are linked into both skill folders" \
        ".claude/skills:${claude_tp:- none}" ".agents/skills:${agents_tp:- none}"
    fi
    if [ -z "$broken" ]; then
      ok "$u: every third-party link holds a SKILL.md named for it"
    else
      bad "$u: every third-party link holds a SKILL.md named for it" "$broken"
    fi
  done <<<"$listed"
fi
# Claude Code invokes a skill by the `name` in its frontmatter, not its folder.
mismatched=""
for d in $on_disk; do
  n="$(sed -nE 's/^name: *(.+)$/\1/p' "$SKILLS_DIR/$d/SKILL.md" 2>/dev/null | head -1)"
  [ "$n" = "$d" ] || mismatched="$mismatched $d(name:$n)"
done
if [ -z "$mismatched" ]; then
  ok "every skill's name matches its folder"
else
  bad "every skill's name matches its folder" "$mismatched"
fi
# The README table is how a human learns a skill exists, and nothing else
# notices when it stops matching what is on disk.
in_readme="$(sed -n '/^### Skills$/,/^### /p' "$DIR/README.md" |
  grep -oE 'home/\.claude/skills/[a-z0-9-]+/SKILL\.md' |
  sed -E 's|home/\.claude/skills/([^/]+)/SKILL\.md|\1|' | sort -u)"
missing="$(comm -23 <(echo "$on_disk") <(echo "$in_readme") | tr '\n' ' ')"
phantom="$(comm -13 <(echo "$on_disk") <(echo "$in_readme") | tr '\n' ' ')"
if [ -z "${missing// /}" ]; then
  ok "README documents every skill"
else
  bad "README documents every skill" "on disk but not in the table: $missing"
fi
if [ -z "${phantom// /}" ]; then
  ok "the README skill table has no phantom rows"
else
  bad "the README skill table has no phantom rows" "in the table but not on disk: $phantom"
fi

# --------------------------------------------------------------------------
section "local skills"
# Runs on every rebuild against the real ~/.claude/skills, so the cases that
# matter most are the ones where it must leave a thing alone.
LOCAL="$DIR/home/.claude/local-skills.sh"
LHOME="$WORK/local-home"
LSTUB="$WORK/local-stub"
mkdir -p "$LSTUB" "$LHOME/.claude/skills" "$LHOME/Vault/.skills/vault-a" "$LHOME/Vault/.skills/not-a-skill" "$WORK/elsewhere"
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
ln -s "$LHOME/Vault/.skills/gone" "$LHOME/.claude/skills/gone"
ln -s "$WORK/elsewhere/missing" "$LHOME/.claude/skills/not-ours"
mkdir -p "$LHOME/Vault/.skills/taken" "$LHOME/.claude/skills/taken"
touch "$LHOME/Vault/.skills/taken/SKILL.md"

local_run
eq "local-skills.sh exits 0" "0" "$LOCAL_RC"
eq "a vault skill is linked" "$LHOME/Vault/.skills/vault-a" "$(readlink "$LHOME/.claude/skills/vault-a")"
if [ -e "$LHOME/.claude/skills/not-a-skill" ]; then
  bad "a vault folder without SKILL.md is not linked" "it was"
else
  ok "a vault folder without SKILL.md is not linked"
fi
if [ -L "$LHOME/.claude/skills/gone" ]; then
  bad "a link to a deleted vault skill is removed" "still there"
else
  ok "a link to a deleted vault skill is removed"
fi
if [ -L "$LHOME/.claude/skills/not-ours" ]; then
  ok "a broken link that is not the vault's is left alone"
else
  bad "a broken link that is not the vault's is left alone" "it was removed"
fi
if [ -L "$LHOME/.claude/skills/taken" ]; then
  bad "an existing folder is never replaced by a vault link" "it was replaced"
else
  ok "an existing folder is never replaced by a vault link"
fi
contains "and the clash is reported" "$LOCAL_ERR" "vault's taken is not linked"
eq "a missing impeccable is installed from ~, globally, without hooks" \
  "$LHOME|-y impeccable install --global -y --no-hooks" "$(cat "$LSTUB/npx-calls")"

local_run
eq "a second run exits 0" "0" "$LOCAL_RC"
eq "a second run does not reinstall impeccable" "1" "$(wc -l <"$LSTUB/npx-calls" | tr -d ' ')"
eq "a second run keeps the vault link" "$LHOME/Vault/.skills/vault-a" "$(readlink "$LHOME/.claude/skills/vault-a")"

rm -rf "$LHOME/.claude/skills/impeccable" "$LHOME/Vault"
local_run NPX_FAIL=1
eq "an install that fails does not fail the rebuild" "0" "$LOCAL_RC"
contains "and says to rebuild again" "$LOCAL_ERR" "impeccable did not install"
if [ -L "$LHOME/.claude/skills/vault-a" ]; then
  bad "with no vault, its old links are removed" "vault-a is still linked"
else
  ok "with no vault, its old links are removed"
fi

if grep -q 'home\.activation\.localSkills' "$DIR/home.nix" && grep -q 'local-skills\.sh' "$DIR/home.nix"; then
  ok "home.nix runs local-skills.sh on rebuild"
else
  bad "home.nix runs local-skills.sh on rebuild" "nothing would put the vault skills or impeccable on a new machine"
fi

# --------------------------------------------------------------------------
section "pr provenance check"
# The pr page shows this script's verdict as proof of authorship, so a false
# CLEAN is the one outcome that must never happen.
PROV="$DIR/home/.claude/skills/pr/scripts/provenance.sh"
PREPO="$WORK/prov"
git init -q "$PREPO"
pv_commit() { # message, [author name], [author email] -> new HEAD
  local tree
  tree=$(git -C "$PREPO" mktree </dev/null)
  local parent=()
  git -C "$PREPO" rev-parse -q --verify HEAD >/dev/null && parent=(-p HEAD)
  GIT_AUTHOR_NAME="${2:-Dan}" GIT_AUTHOR_EMAIL="${3:-d@example.com}" \
    GIT_COMMITTER_NAME=Dan GIT_COMMITTER_EMAIL=d@example.com \
    git -C "$PREPO" commit-tree "$tree" ${parent[@]+"${parent[@]}"} -m "$1" |
    xargs git -C "$PREPO" update-ref HEAD
}
pv() { (cd "$PREPO" && "$PROV" "$@" >/dev/null 2>&1); echo $?; }
pv_commit "chore: base"
pv_base=$(git -C "$PREPO" rev-parse HEAD)
pv_commit "feat: one"
eq "a human-only range is clean" 0 "$(pv "$pv_base")"
eq "an empty range is unverified, not clean" 2 "$(pv HEAD)"
eq "a missing body is unverified, not clean" 2 "$(pv "$pv_base" --body "$WORK/none.md")"
printf 'Fixes it.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n' >"$WORK/body.md"
eq "a body with the harness footer is flagged" 1 "$(pv "$pv_base" --body "$WORK/body.md")"
pv_commit "docs: say why claude reads this" Dan
eq "prose naming a model is not a credit" 0 "$(pv "$pv_base")"
pv_commit "fix: two

Co-Authored-By: Opus 5 <noreply@anthropic.com>"
eq "a co-author trailer with a vendor domain is flagged" 1 "$(pv "$pv_base")"
pv_base=$(git -C "$PREPO" rev-parse HEAD)
pv_commit "chore: bump" "dependabot[bot]" "49699333+dependabot[bot]@users.noreply.github.com"
eq "a bot author is flagged" 1 "$(pv "$pv_base")"
pv_base=$(git -C "$PREPO" rev-parse HEAD)
pv_commit "feat: three" Claude claude@anthropic.com
eq "an AI author is flagged" 1 "$(pv "$pv_base")"
# A copy with no ai-credit.sh beside it or in ~/.claude has nothing to judge by.
mkdir -p "$WORK/prov-lone" "$WORK/prov-home"
cp "$PROV" "$WORK/prov-lone/provenance.sh"
eq "a missing ai-credit.sh is unverified, not clean" 2 \
  "$(cd "$PREPO" && HOME="$WORK/prov-home" "$WORK/prov-lone/provenance.sh" "$pv_base" >/dev/null 2>&1; echo $?)"

# --------------------------------------------------------------------------
section "skill gate hook"
# The pass cases matter as much as the blocks: a gate that stops reading
# TypeScript, or locks out a machine without the skill, gets switched off.
GATE="$DIR/home/.claude/hooks/skill-gate.sh"
if ! command -v jq >/dev/null 2>&1; then
  skip "skill-gate.sh (jq not found)"
else
  GATE_HOME="$WORK/gate-home"
  # Linked the way home.nix links a pinned skill: a symlink into the store.
  mkdir -p "$WORK/gate-store/typescript-style-guide" "$GATE_HOME/.claude/skills"
  touch "$WORK/gate-store/typescript-style-guide/SKILL.md"
  ln -s "$WORK/gate-store/typescript-style-guide" "$GATE_HOME/.claude/skills/typescript-style-guide"
  export CLAUDE_SKILL_GATE_STATE="$WORK/gate-state"
  # agent (empty for the main agent), tool name, tool_input JSON -> exit code
  gate() {
    jq -nc --arg a "$1" --arg t "$2" --argjson i "$3" \
      '{session_id:"s1",tool_name:$t,tool_input:$i} + (if $a == "" then {} else {agent_id:$a,agent_type:"general-purpose"} end)' |
      HOME="$GATE_HOME" "$GATE" >/dev/null 2>&1
    echo $?
  }
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
  bash_gate() { gate agent-c Bash "$(jq -nc --arg c "$1" '{command:$c}')"; }
  let_through=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(bash_gate "$c")" = "2" ] || let_through="$let_through
    let through: $c"
  done <<'CASES'
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
  if [ -z "$let_through" ]; then
    ok "a Bash write to a TypeScript file is blocked"
  else
    bad "a Bash write to a TypeScript file is blocked" "$let_through"
  fi

  stopped=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(bash_gate "$c")" = "0" ] || stopped="$stopped
    blocked: $c"
  done <<'CASES'
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
  if [ -z "$stopped" ]; then
    ok "reading TypeScript through Bash passes"
  else
    bad "reading TypeScript through Bash passes" "$stopped"
  fi
  nested=""
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$(bash_gate "$c")" = "2" ] || nested="$nested
    let through: $c"
  done <<'CASES'
echo "$(cp a src/a.ts)"
x=`tee src/a.ts`
(cd web && sed -i 's/a/b/' src/a.ts)
if cp a src/b.tsx; then :; fi
{ mv a src/c.mts; }
CASES
  if [ -z "$nested" ]; then
    ok "a write inside a subshell or a compound command is blocked"
  else
    bad "a write inside a subshell or a compound command is blocked" "$nested"
  fi
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

# --------------------------------------------------------------------------
section "comment audit hook"
# It runs on every Write, Edit and MultiEdit in every session, so a break lands
# everywhere at once and a false positive teaches everyone to ignore it. Both
# failure modes are silent - settings.base.json invokes it behind `[ ! -x ... ] ||`,
# so losing the executable bit disables the whole thing without a word.
AUDIT="$DIR/home/.claude/hooks/comment-audit.sh"
if ! command -v jq >/dev/null 2>&1; then
  skip "comment audit behaviour (needs jq; macOS ships it at /usr/bin/jq)"
else
  # name, expected exit, payload. 0 is quiet, 2 is a finding on stderr.
  audit_case() {
    printf '%s' "$3" | "$AUDIT" >/dev/null 2>&1
    got=$?
    if [ "$got" = "$2" ]; then ok "$1"; else bad "$1" "expected exit $2, got $got"; fi
  }
  audit_case "a comment giving a reason is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// one control, so the labels cannot drift"}}'
  audit_case "history narration is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// used to be a loop"}}'
  audit_case "an attribution stamp is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// tuned here (Dan, 2026-08-12)"}}'
  audit_case "a bare date in a source file is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// added 2026-08-12"}}'
  audit_case "a month-name date is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// as of March 2026 the cap is 50"}}'
  audit_case "a month-name date in a test file is allowed" 0 \
    '{"tool_input":{"file_path":"a.test.ts","content":"// fixture week of May 2026"}}'
  audit_case "a bare month abbreviation is not a date" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// Mar is the marker column"}}'
  audit_case "the adverb previously is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// previously handled by the queue"}}'
  audit_case "the adjective previous is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// carries the previous night forward"}}'
  audit_case "renamed from is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// renamed from getUser"}}'
  audit_case "domain moved from is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// rows moved from the queue land here"}}'
  audit_case "session talk as requested is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// kept both branches as requested"}}'
  audit_case "session talk per the plan is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// per the plan this stays sync"}}'
  audit_case "a protocol spec reference is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// retries per the spec, RFC 7231"}}'
  # The one documented carve-out: an assertion beside a fixture date fails
  # loudly when it drifts, so the date is allowed to be named there.
  audit_case "a fixture date in a test file is allowed" 0 \
    '{"tool_input":{"file_path":"a.test.ts","content":"// fixture 2026-08-12"}}'
  audit_case "a history phrase outside a comment is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"const s = 1; // fine"}}'
  audit_case "a non-source file is ignored" 0 \
    '{"tool_input":{"file_path":"notes.md","content":"used to be a loop"}}'
  audit_case "a payload with no file_path is ignored" 0 \
    '{"tool_input":{"content":"// used to be a loop"}}'
  audit_case "Edit new_string is read" 2 \
    '{"tool_input":{"file_path":"a.ts","new_string":"// no longer needed"}}'
  audit_case "MultiEdit edits[] are read" 2 \
    '{"tool_input":{"file_path":"a.ts","edits":[{"new_string":"// formerly async"}]}}'
  audit_case "a python docstring is read as documentation" 2 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"\nformerly a generator\n\"\"\""}}'
  # Length is its own fault: the patterns above catch what a comment says, and
  # nothing there catches a block that simply runs on.
  audit_case "a three-line comment run is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two\n// three"}}'
  audit_case "a two-line comment run is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two"}}'
  audit_case "a blank line ends a run" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two\n\n// three\n// four"}}'
  audit_case "a block comment run is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"/* one\n * two\n * three\n */"}}'
  audit_case "a four-line python docstring is not a comment run" 0 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"\nalpha\nbeta\ngamma\ndelta\n\"\"\""}}'
  # A fence that opens and closes on one line must leave the tracker where it
  # found it, or every line after it is misread for the rest of the file.
  audit_case "a one-line docstring does not swallow the run count" 2 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# one\n# two\n# three"}}'
  audit_case "a one-line docstring does not swallow the patterns" 2 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# formerly a generator"}}'
  audit_case "a one-line docstring leaves a short run short" 0 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# one\n# two"}}'
  audit_case "a run of pragma lines is not flagged" 0 \
    '{"tool_input":{"file_path":"a.sh","content":"#!/usr/bin/env bash\n# shellcheck disable=SC2086\n# shellcheck disable=SC2001\n# shellcheck disable=SC2002"}}'
  audit_case "a shebang does not pad a two-line run" 0 \
    '{"tool_input":{"file_path":"a.sh","content":"#!/usr/bin/env bash\n# one\n# two"}}'
  audit_case "a trailing comment on each line is not a run" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"const a=1; // one\nconst b=2; // two\nconst c=3; // three\nconst d=4; // four"}}'
  # A hook that dies on an unexpected payload takes the session's write with it.
  audit_case "malformed input exits quietly" 0 'not json at all'
  # Linked into ~/.claude through the store, so the phrase list is found beside the real file.
  mkdir -p "$WORK/audit-link/store" "$WORK/audit-link/home" "$WORK/audit-alone"
  ln -s "$AUDIT" "$WORK/audit-link/store/comment-audit.sh"
  ln -s ../store/comment-audit.sh "$WORK/audit-link/home/comment-audit.sh"
  eq "an audit reached through two links still reads the phrase list" "2" \
    "$(printf '%s' '{"tool_input":{"file_path":"a.ts","content":"// per the plan"}}' |
      "$WORK/audit-link/home/comment-audit.sh" >/dev/null 2>&1; echo $?)"
  cp "$AUDIT" "$WORK/audit-alone/comment-audit.sh"
  eq "an audit without ai-credit.sh fails without nudging" "1" \
    "$(printf '%s' '{"tool_input":{"file_path":"a.ts","content":"// per the plan"}}' |
      "$WORK/audit-alone/comment-audit.sh" >/dev/null 2>&1; echo $?)"

  # The cap is only credible if the repo it ships from meets it, so every hook
  # script is replayed as the full-file Write it would arrive as.
  unaudited=""
  for s in "$DIR"/home/.claude/hooks/*.sh "$DIR"/home/.claude/local-skills.sh; do
    out=$(jq -Rs --arg p "$s" '{tool_input:{file_path:$p,content:.}}' "$s" |
      "$AUDIT" 2>&1 >/dev/null) && continue
    unaudited="$unaudited
    $(basename "$s"):
$out"
  done
  if [ -z "$unaudited" ]; then
    ok "the repo's own hook scripts pass the comment audit"
  else
    bad "the repo's own hook scripts pass the comment audit" "$unaudited"
  fi
fi

# --------------------------------------------------------------------------
section "status line"
# Claude Code renders whatever this prints, so a crash costs the whole line.
# Most of the payload is optional, and the interesting cases are the ones where
# a field has not arrived yet.
SL="$DIR/home/.claude/hooks/statusline.sh"
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

# --------------------------------------------------------------------------
section "session name"
# The script that names a session after its repo, called two ways: bare by the
# cc function, and with --hook by Claude Code itself. Every case runs against a
# throwaway $HOME holding a fabricated session registry, so nothing here depends
# on which real sessions happen to be open while the suite runs.
SN="$DIR/home/.claude/hooks/session-name.sh"
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
# --------------------------------------------------------------------------
section "the cc function"
# The whole point of the exercise: cc has to hand the name to claude, as two
# words. Run it, rather than grep it for "--name" - the string was always there
# even when the array reached claude as the single argument "--name myrepo",
# which is exactly the bug the comment inside the function warns about.
FN="$DIR/home/.config/zsh/functions.zsh"
# Its own check, because SCRIPTS takes only *.sh files.
if err="$(zsh -n "$FN" 2>&1)"; then ok "zsh -n functions.zsh"; else bad "zsh -n functions.zsh" "$err"; fi

# Prints its arguments one per line, so a name that arrived as one word
# containing a space is visibly different from two words.
cat >"$STUB/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
EOF
chmod +x "$STUB/claude"
# A naming script that answers, under the throwaway $HOME built above. Without
# one, cc's command substitution fails, the name is empty and the whole --name
# assertion below would pass while asserting nothing.
mkdir -p "$STHOME/.claude/hooks"
cat >"$STHOME/.claude/hooks/session-name.sh" <<'EOF'
#!/usr/bin/env bash
echo myrepo
EOF
chmod +x "$STHOME/.claude/hooks/session-name.sh"

cc_argv() { # $HOME to run under -> the argv claude was called with
  HOME="$1" PATH="$STUB:$PATH" zsh -c "source '$FN'; cc --foo" 2>/dev/null
}
eq "cc passes the name to claude as two words" "--dangerously-skip-permissions
--remote-control
--name
myrepo
--foo" "$(cc_argv "$STHOME")"

# $FAKEHOME has no ~/.claude/hooks/session-name.sh, so the name comes back empty.
# The array has to vanish entirely rather than leave claude a bare --name or an
# empty string after it.
eq "no name means no --name, not an empty one" "--dangerously-skip-permissions
--remote-control
--foo" "$(cc_argv "$FAKEHOME")"

# cc-push writes the opt-in guard-bash.sh reads, so what it stores is what
# decides whether an agent may push: run it and read the config back.
CPREPO="$WORK/cc-push"
git init -q "$CPREPO"
cp_run() { (cd "$1" && zsh -c "source '$FN'; cc-push $2" 2>&1); }
cp_val() { git -C "$CPREPO" config --local --get claude.allowPush; }
cp_run "$CPREPO" "" >/dev/null
eq "cc-push with no argument turns an unset switch on" "true" "$(cp_val)"
cp_run "$CPREPO" "" >/dev/null
eq "cc-push with no argument flips on to off" "false" "$(cp_val)"
cp_run "$CPREPO" on >/dev/null
eq "cc-push on sets true" "true" "$(cp_val)"
cp_run "$CPREPO" off >/dev/null
eq "cc-push off sets false" "false" "$(cp_val)"
cp_run "$CPREPO" status >/dev/null
eq "cc-push status leaves the switch alone" "false" "$(cp_val)"
if cp_run "$WORK" "" >/dev/null; then
  bad "cc-push outside a repo fails" "it returned success"
else
  ok "cc-push outside a repo fails"
fi

# cc-flow is a hand-copied cheat sheet, so the drift worth catching is a skill
# renamed or removed while the table still tells you to type its old name.
FLOW_OUT="$(zsh -c "source '$FN'; cc-flow" 2>&1)"
FLOW_MISSING=""
for name in $(printf '%s\n' "$FLOW_OUT" | grep -oE '/[a-z][a-z-]+' | sort -u); do
  [ -f "$DIR/home/.claude/skills${name}/SKILL.md" ] || FLOW_MISSING="$FLOW_MISSING $name"
done
if [ -z "$FLOW_MISSING" ]; then
  ok "every skill cc-flow names exists"
else
  bad "every skill cc-flow names exists" "no such skill:$FLOW_MISSING"
fi
# Piped output is what `cc-flow | less` sees; escape codes there print as junk.
case "$FLOW_OUT" in
  *$'\e'*) bad "cc-flow prints no color into a pipe" "found an escape code" ;;
  *) ok "cc-flow prints no color into a pipe" ;;
esac

# ~/.zshrc is generated, so the only thing tying it to the file above is this
# line. The -r guard is part of the contract: the file arrives by symlink, and
# an unguarded source would print an error on every new shell if it dangled.
if grep -qF '[ -r ~/.config/zsh/functions.zsh ] && source' "$DIR/home.nix"; then
  ok "home.nix sources functions.zsh, and guards it"
else
  bad "home.nix sources functions.zsh, and guards it" \
    "nothing in ~/.zshrc would load the function"
fi

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

    # home.nix throws for a user record with no address in it, so this failing
    # means a machine was added to the users attrset and left without an email.
    email="$(nix eval --raw \
      "$DIR#darwinConfigurations.$attr.config.home-manager.users.\"$u\".programs.git.settings.user.email" \
      2>"$WORK/stderr")"
    case "$email" in
      *@*.*) ok "#$attr commits as $email" ;;
      *) bad "#$attr has a git address" "$(grep -v '^warning:' "$WORK/stderr" | head -3)" ;;
    esac
    # The README's username table is only useful while it lists every
    # configuration; it leaves the addresses out so they are not published twice.
    if grep -qF "\`#$attr\`" "$DIR/README.md"; then
      ok "README lists #$attr"
    else
      bad "README lists #$attr" "#$attr is configured but not in the README"
    fi
  done <<<"$listed"

  # ------------------------------------------------------------------------
  section "a record users.sh add wrote, before anyone fills it in"
  # This is the fresh-Mac experience: bootstrap.sh appends an empty record and
  # then runs a switch against it. That switch has to end in the one line that
  # says which address is missing. It only does so because configuration.nix
  # defaults hostPlatform - pkgs is instantiated long before home.nix runs, so
  # indexing cfg.system directly would bury the useful message under a
  # module-system stack trace and this is the test that notices.
  FLAKECOPY="$WORK/flakecopy"
  # home.nix reads these folders at eval time; every other home/ path is a string.
  mkdir -p "$FLAKECOPY/home/.claude/skills" "$FLAKECOPY/home/.claude/hooks" "$FLAKECOPY/home/.claude/rules"
  cp "$COPY" "$FLAKECOPY/flake.nix"
  cp "$DIR/flake.lock" "$DIR/configuration.nix" "$DIR/home.nix" "$FLAKECOPY/"

  ev() { # attribute path -> nix eval it, with stderr captured
    EV_RC=0
    EV_OUT="$(nix eval --raw --no-write-lock-file "$FLAKECOPY#$1" 2>"$WORK/stderr")" || EV_RC=$?
    EV_ERR="$(grep -v '^warning:' "$WORK/stderr")"
  }

  ev 'darwinConfigurations.new-user.config.nixpkgs.hostPlatform.system'
  eq "an empty record still picks a platform" "aarch64-darwin" "$EV_OUT"

  ev 'darwinConfigurations.new-user.config.home-manager.users."new.user".programs.git.settings.user.email'
  if [ "$EV_RC" -eq 0 ]; then
    bad "an empty record refuses to guess an address" "evaluated to \"$EV_OUT\""
  else
    ok "an empty record refuses to guess an address"
  fi
  contains "and says whose address is missing" "$EV_ERR" 'no git email for "new.user"'
  contains "and says where to put it" "$EV_ERR" "flake.nix's users"

  # A record's fields are optional so that an empty one survives to the throw
  # above. That tolerance is what makes a misspelled field dangerous: an
  # ignored `sytem` is not an error, it is a silent build for the wrong
  # platform, which is the one failure here that no later step would catch.
  sed 's/system = "aarch64-darwin"/sytem = "aarch64-darwin"/' "$COPY" \
    >"$FLAKECOPY/flake.nix"
  ev 'darwinConfigurations.danavner.config.nixpkgs.hostPlatform.system'
  if [ "$EV_RC" -eq 0 ]; then
    bad "a misspelled field is rejected, not ignored" \
      "sytem was accepted and the platform silently became \"$EV_OUT\""
  else
    ok "a misspelled field is rejected, not ignored"
  fi
  contains "and names the field that is wrong" "$EV_ERR" "sytem"
  contains "and names the user it is wrong on" "$EV_ERR" '"danavner"'
  cp "$COPY" "$FLAKECOPY/flake.nix"

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
    # onActivation.upgrade skips it unless the entry is greedy. Neither of
    # these self-updates, so greedy would only race their own updaters.
    for c in wezterm claude-code@latest; do
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
