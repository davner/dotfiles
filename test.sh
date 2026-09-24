#!/usr/bin/env bash
# Checks the things in this repo that fail silently, fail only on the other
# machine, or fail an hour into an activation: the username -> flake attribute
# mapping, the users attrset parsing, the two scripts' guard rails, and the
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
  home/.claude/statusline.sh home/.claude/session-name.sh
  home/.claude/comment-audit.sh home/.claude/guard-bash.sh
  home/.claude/context-audit.sh)

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
section "ticket loop"
# The timings file is append-only and compared across tickets, so its columns
# are a contract: reordering one silently invalidates every row already
# written. Pinning the header here makes changing it a deliberate act.
TICKET_MD="$DIR/home/.claude/commands/ticket.md"
TIMINGS_HEADER="$(printf 'ticket\tphase\tround\tagent\tstarted\tended\tseconds')"
if grep -qF "$TIMINGS_HEADER" "$TICKET_MD"; then
  ok "the timings header is the agreed columns, tab separated"
else
  bad "the timings header is the agreed columns, tab separated" \
    "ticket.md no longer documents: $TIMINGS_HEADER"
fi
missing=""
for phase in spec approval setup writer tests review handoff; do
  grep -qF "\`$phase\`" "$TICKET_MD" || missing="$missing $phase"
done
if [ -z "$missing" ]; then
  ok "every timing phase is named in ticket.md"
else
  bad "every timing phase is named in ticket.md" "undocumented:$missing"
fi
# The lead starts one app and hands out the URL, so no agent races another
# for the port - a lost race reads as a defect in the branch.
if grep -q 'never race to' "$TICKET_MD"; then
  ok "the lead hands the review round one app instance"
else
  bad "the lead hands the review round one app instance" \
    "ticket.md no longer says the lead starts the app and shares its URL"
fi

# --------------------------------------------------------------------------
section "draft-ticket skill"
# The skill drafts text a human pastes. The moment it can file a ticket it
# stops being safe to run unattended, and that boundary lives only in the
# prose - so pin the sentence that states it.
DRAFT_MD="$DIR/home/.claude/skills/draft-ticket/SKILL.md"
if grep -qF 'Nothing here files, edits, or moves a ticket.' "$DRAFT_MD"; then
  ok "draft-ticket still says it never files a ticket"
else
  bad "draft-ticket still says it never files a ticket" \
    "SKILL.md dropped the boundary that keeps it a drafting tool"
fi
# Both halves of "tied into the ticket loop, callable on its own": the loop has
# to name the skill, and the skill has to say what it does when called alone.
if grep -qF 'draft-ticket' "$TICKET_MD"; then
  ok "the ticket loop's spec step uses the skill"
else
  bad "the ticket loop's spec step uses the skill" \
    "ticket.md no longer routes its Title and Description through draft-ticket"
fi
if grep -qF 'Called on its own, the skill ends at section 6' "$DRAFT_MD"; then
  ok "draft-ticket still stops at the draft when called alone"
else
  bad "draft-ticket still stops at the draft when called alone" \
    "SKILL.md no longer says a standalone call starts no ticket loop"
fi

# --------------------------------------------------------------------------
section "bash guard hook"
# The rules this enforces are absolute in home/AGENTS.md, which is exactly why
# they are a hook: a prompt is advice and a hook is a decision. The allow cases
# matter more than the block cases - a guard that blocks ordinary work is one
# that gets switched off.
GUARD="$DIR/home/.claude/guard-bash.sh"
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
git add home/.claude/guard-bash.sh
git add ./src/foo.ts
git add -u home/AGENTS.md
git status --short
git log --oneline -5
git push origin main
git clean -fd
git commit -m "fix: a real message"
echo "git add ."
nix develop --command ./test.sh
CASES
  if [ -z "$allowed" ]; then
    ok "ordinary work is not blocked"
  else
    bad "ordinary work is not blocked" "$allowed"
  fi
fi
if grep -q 'guard-bash.sh' "$DIR/home/.claude/settings.base.json"; then
  ok "settings.base.json registers it on PreToolUse"
else
  bad "settings.base.json registers it on PreToolUse" "the hook would never fire"
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
fi
if grep -q 'mkOutOfStoreSymlink.*\.claude/settings\.json' "$DIR/home.nix"; then
  bad "home.nix does not link settings.json" \
    "a link there sends every /config write back into this repo"
else
  ok "home.nix does not link settings.json"
fi
if grep -q 'settings\.base\.json' "$DIR/home.nix"; then
  ok "home.nix installs settings.base.json"
else
  bad "home.nix installs settings.base.json" "nothing would put the durable keys on a new machine"
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
targets="$(sed -nE 's|.*mkOutOfStoreSymlink "\$\{dotfiles\}/([^"]+)".*|\1|p' "$DIR/home.nix" | sort -u)"
if [ -z "$targets" ]; then
  bad "found mkOutOfStoreSymlink targets in home.nix" "the sed found nothing - did home.nix change shape?"
else
  while read -r t; do
    if [ -e "$DIR/$t" ]; then ok "$t exists"; else bad "$t exists" "home.nix links to a path this repo does not have"; fi
  done <<<"$targets"
fi

# --------------------------------------------------------------------------
section "comment audit hook"
# It runs on every Write, Edit and MultiEdit in every session, so a break lands
# everywhere at once and a false positive teaches everyone to ignore it. Both
# failure modes are silent - settings.base.json invokes it behind `[ ! -x ... ] ||`,
# so losing the executable bit disables the whole thing without a word.
AUDIT="$DIR/home/.claude/comment-audit.sh"
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
  audit_case "a four-line comment run is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two\n// three\n// four"}}'
  audit_case "a three-line comment run is not flagged" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two\n// three"}}'
  audit_case "a blank line ends a run" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"// one\n// two\n\n// three\n// four"}}'
  audit_case "a block comment run is flagged" 2 \
    '{"tool_input":{"file_path":"a.ts","content":"/* one\n * two\n * three\n * four\n */"}}'
  audit_case "a four-line python docstring is not a comment run" 0 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"\nalpha\nbeta\ngamma\ndelta\n\"\"\""}}'
  # A fence that opens and closes on one line must leave the tracker where it
  # found it, or every line after it is misread for the rest of the file.
  audit_case "a one-line docstring does not swallow the run count" 2 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# one\n# two\n# three\n# four"}}'
  audit_case "a one-line docstring does not swallow the patterns" 2 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# formerly a generator"}}'
  audit_case "a one-line docstring leaves a short run short" 0 \
    '{"tool_input":{"file_path":"a.py","content":"\"\"\"One-liner.\"\"\"\n# one\n# two\n# three"}}'
  audit_case "a run of pragma lines is not flagged" 0 \
    '{"tool_input":{"file_path":"a.sh","content":"#!/usr/bin/env bash\n# shellcheck disable=SC2086\n# shellcheck disable=SC2001\n# shellcheck disable=SC2002"}}'
  audit_case "a shebang does not pad a three-line run" 0 \
    '{"tool_input":{"file_path":"a.sh","content":"#!/usr/bin/env bash\n# one\n# two\n# three"}}'
  audit_case "a trailing comment on each line is not a run" 0 \
    '{"tool_input":{"file_path":"a.ts","content":"const a=1; // one\nconst b=2; // two\nconst c=3; // three\nconst d=4; // four"}}'
  # A hook that dies on an unexpected payload takes the session's write with it.
  audit_case "malformed input exits quietly" 0 'not json at all'
fi

# The hook is inert unless settings.base.json still registers it on the write tools.
if grep -q 'comment-audit.sh' "$DIR/home/.claude/settings.base.json" &&
  grep -q 'Write|Edit|MultiEdit' "$DIR/home/.claude/settings.base.json"; then
  ok "settings.base.json registers the hook on Write|Edit|MultiEdit"
else
  bad "settings.base.json registers the hook on Write|Edit|MultiEdit" \
    "the script exists but nothing calls it"
fi

# --------------------------------------------------------------------------
section "context audit"
# It only reports, so its failure mode is a wrong number quietly steering a
# trim decision: a miscounted body, a cap applied to the wrong kind of file,
# or a config glob silently matching nothing.
CTX="$DIR/home/.claude/context-audit.sh"
CTXWORK="$WORK/ctx"
mkdir -p "$CTXWORK/agents" "$CTXWORK/scoped/.claude" "$CTXWORK/scoped/docs" \
  "$CTXWORK/rootonly/docs" "$CTXWORK/deepglob/.claude" "$CTXWORK/deepglob/docs/a/b"

printf '# small\n' >"$CTXWORK/small.md"
seq 1 201 >"$CTXWORK/long.md"
# 150 lines of 200 chars: past the byte cap while comfortably under the line
# cap, which is exactly the case the byte half exists for.
awk 'BEGIN { s = sprintf("%200s", "x"); for (i = 0; i < 150; i++) print s }' >"$CTXWORK/wide.md"
{
  printf -- '---\nname: big\ndescription: fits\n---\n'
  seq 1 401
} >"$CTXWORK/agents/big.md"
{
  printf -- '---\nname: chatty\ndescription: >\n'
  for _ in $(seq 1 30); do printf '  twenty characters..\n'; done
  printf -- '---\nbody\n'
} >"$CTXWORK/agents/chatty.md"

out="$("$CTX" "$CTXWORK/small.md" 2>/dev/null)"
rc=$?
eq "a file under both caps exits 0" "0" "$rc"
contains "the passing file is reported ok" "$out" "ok"

out="$("$CTX" "$CTXWORK/small.md" "$CTXWORK/long.md" 2>/dev/null)"
rc=$?
eq "a file over 200 lines exits 1" "1" "$rc"
contains "the long file is reported over" "$out" "over"

out="$("$CTX" "$CTXWORK/wide.md" 2>/dev/null)"
rc=$?
eq "short lines past 25600 bytes exit 1" "1" "$rc"

# A missing final newline is invisible in an editor, so an off-by-one here is
# a silent pass exactly on the boundary the tool enforces.
{
  seq 1 200
  printf 'no trailing newline'
} >"$CTXWORK/noeol.md"
out="$("$CTX" "$CTXWORK/noeol.md" 2>/dev/null)"
rc=$?
eq "an over-cap file with no trailing newline exits 1" "1" "$rc"
contains "the unterminated last line is counted" "$out" "201"

out="$("$CTX" "$CTXWORK/agents/big.md" 2>/dev/null)"
rc=$?
eq "an agent body over 400 lines exits 1" "1" "$rc"
contains "the agent body row carries the agent cap" "$out" "400L"

out="$("$CTX" "$CTXWORK/agents/chatty.md" 2>/dev/null)"
rc=$?
eq "an agent description over 500 chars exits 1" "1" "$rc"
contains "the over verdict lands on the description row" \
  "$(printf '%s\n' "$out" | grep '(description)')" "over"

# An opening fence that never closes counts the whole file as body, so a
# malformed agent file can never report a body of zero and slip under the cap.
{
  printf -- '---\nname: unclosed\n'
  seq 1 401
} >"$CTXWORK/agents/unclosed.md"
out="$("$CTX" "$CTXWORK/agents/unclosed.md" 2>/dev/null)"
rc=$?
eq "an unclosed frontmatter fence counts the whole file as body" "1" "$rc"

# The agent caps must also apply when the path is bare-relative, with no
# leading directory in front of agents/.
out="$(cd "$CTXWORK" && "$CTX" agents/big.md 2>/dev/null)"
rc=$?
eq "a bare relative agents/ path gets the agent caps" "1" "$rc"
contains "the relative path's row carries the agent cap" "$out" "400L"

printf '# root\n' >"$CTXWORK/scoped/CLAUDE.md"
seq 1 201 >"$CTXWORK/scoped/docs/nested.md"
printf '# scoped in\ndocs/*.md\nCLAUDE.md\n' >"$CTXWORK/scoped/.claude/context-audit"
out="$(cd "$CTXWORK/scoped" && "$CTX" 2>/dev/null)"
rc=$?
eq "a config glob pulls a nested file in" "1" "$rc"
contains "the nested file appears in the table" "$out" "nested.md"
eq "a config line re-matching the root file adds no second row" \
  "1" "$(printf '%s\n' "$out" | grep -c 'CLAUDE.md')"

# The test relies on the bash on PATH having globstar; without it the script
# refuses the `**` line rather than matching it one level deep.
printf '# deep\ndocs/**/*.md\n' >"$CTXWORK/deepglob/.claude/context-audit"
printf '# root\n' >"$CTXWORK/deepglob/CLAUDE.md"
seq 1 201 >"$CTXWORK/deepglob/docs/a/b/deep.md"
out="$(cd "$CTXWORK/deepglob" && "$CTX" 2>/dev/null)"
rc=$?
eq "a ** config glob reaches a deeply nested file" "1" "$rc"
contains "the deep file appears in the table" "$out" "docs/a/b/deep.md"

printf '# root\n' >"$CTXWORK/rootonly/CLAUDE.md"
seq 1 201 >"$CTXWORK/rootonly/docs/nested.md"
out="$(cd "$CTXWORK/rootonly" && "$CTX" 2>/dev/null)"
rc=$?
eq "absent config audits the root only" "0" "$rc"
case "$out" in
  *nested.md*) bad "absent config leaves nested files alone" "nested.md was audited with no config listing it" ;;
  *) ok "absent config leaves nested files alone" ;;
esac

"$CTX" "$CTXWORK/absent.md" >/dev/null 2>"$WORK/ctx-stderr"
rc=$?
eq "a nonexistent named file exits 2" "2" "$rc"
contains "the missing file is named on stderr" "$(cat "$WORK/ctx-stderr")" "absent.md"

# --------------------------------------------------------------------------
section "agent roster"
# Claude Code routes by the `name` in the frontmatter, not by the filename, so a
# typo there is an agent nothing can reach and no build ever complains about.
AGENTS_DIR="$DIR/home/.claude/agents"
mismatched=""
undescribed=""
for f in "$AGENTS_DIR"/*.md; do
  a="$(basename "$f" .md)"
  n="$(sed -nE 's/^name: (.+)$/\1/p' "$f" | head -1)"
  [ "$n" = "$a" ] || mismatched="$mismatched $a(name:$n)"
  grep -q '^description: >' "$f" || undescribed="$undescribed $a"
done
if [ -z "$mismatched" ]; then
  ok "every agent's name matches its filename"
else
  bad "every agent's name matches its filename" "$mismatched"
fi
if [ -z "$undescribed" ]; then
  ok "every agent has a description block"
else
  bad "every agent has a description block" "no description: >:$undescribed"
fi

# The README table is how a human learns the roster exists. It is only useful
# while it still lists what is on disk, and nothing else notices when it slips.
on_disk="$(basename -s .md "$AGENTS_DIR"/*.md | sort)"
# The backticks are literal markdown in the table, and sed needs \1 unexpanded,
# so single quotes are exactly right here.
# shellcheck disable=SC2016
in_readme="$(sed -n '/^## Agents/,/^## Tests/p' "$DIR/README.md" |
  sed -nE 's/^\| `([a-z0-9-]+)` \|.*/\1/p' | sort)"
missing="$(comm -23 <(echo "$on_disk") <(echo "$in_readme") | tr '\n' ' ')"
phantom="$(comm -13 <(echo "$on_disk") <(echo "$in_readme") | tr '\n' ' ')"
if [ -z "${missing// /}" ]; then
  ok "README documents every agent"
else
  bad "README documents every agent" "on disk but not in the table: $missing"
fi
if [ -z "${phantom// /}" ]; then
  ok "the README agent table has no phantom rows"
else
  bad "the README agent table has no phantom rows" "in the table but not on disk: $phantom"
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
if grep -qF '~/.claude/statusline.sh' "$DIR/home/.claude/settings.base.json"; then
  ok "settings.base.json points at the status line"
else
  bad "settings.base.json points at the status line" "statusLine.command does not reference it"
fi
if grep -qF '.claude/statusline.sh' "$DIR/home.nix"; then
  ok "home.nix links the status line into ~/.claude"
else
  bad "home.nix links the status line into ~/.claude" "settings.base.json would point at a missing file"
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
if grep -qF '~/.claude/session-name.sh --hook' "$DIR/home/.claude/settings.base.json"; then
  ok "settings.base.json runs it on SessionStart"
else
  bad "settings.base.json runs it on SessionStart" "no SessionStart hook references it"
fi
if grep -qF '.claude/session-name.sh' "$DIR/home.nix"; then
  ok "home.nix links it into ~/.claude"
else
  bad "home.nix links it into ~/.claude" "settings.base.json would point at a missing file"
fi
# --------------------------------------------------------------------------
section "the cc function"
# The whole point of the exercise: cc has to hand the name to claude, as two
# words. Run it, rather than grep it for "--name" - the string was always there
# even when the array reached claude as the single argument "--name myrepo",
# which is exactly the bug the comment inside the function warns about.
FN="$DIR/home/.config/zsh/functions.zsh"
# Its own check, because it cannot join SCRIPTS: bash -n and shellcheck both
# reject zsh array syntax.
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
cat >"$STHOME/.claude/session-name.sh" <<'EOF'
#!/usr/bin/env bash
echo myrepo
EOF
chmod +x "$STHOME/.claude/session-name.sh"

cc_argv() { # $HOME to run under -> the argv claude was called with
  HOME="$1" PATH="$STUB:$PATH" zsh -c "source '$FN'; cc --foo" 2>/dev/null
}
eq "cc passes the name to claude as two words" "--dangerously-skip-permissions
--remote-control
--name
myrepo
--foo" "$(cc_argv "$STHOME")"

# $FAKEHOME has no ~/.claude/session-name.sh, so the name comes back empty.
# The array has to vanish entirely rather than leave claude a bare --name or an
# empty string after it.
eq "no name means no --name, not an empty one" "--dangerously-skip-permissions
--remote-control
--foo" "$(cc_argv "$FAKEHOME")"

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
    # The README documents which address goes with which machine, which is
    # only useful while it still matches the configuration it describes.
    if grep -qF "$email" "$DIR/README.md"; then
      ok "README lists $u's address"
    else
      bad "README lists $u's address" "$email is configured but not documented"
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
  #
  # Evaluated from a copy holding nothing but the four files a darwin
  # configuration needs. home.nix names paths under home/ only inside
  # mkOutOfStoreSymlink strings, which are strings at eval time, so they do not
  # have to be there.
  FLAKECOPY="$WORK/flakecopy"
  mkdir -p "$FLAKECOPY"
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
