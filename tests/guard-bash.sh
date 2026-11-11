#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "bash guard hook"
# A prompt is advice and a hook is a decision. The allow cases matter more than
# the block cases: a guard that blocks ordinary work gets switched off.
GUARD="$DIR/home/.claude/hooks/guard-bash.sh"
require jq || finish
if [ ! -x "$GUARD" ]; then
  bad "guard-bash.sh is executable" "$GUARD"
  finish
fi
# Exit 2 is the only code that blocks a PreToolUse call; 0 lets it through.
guard() { hook "$GUARD" "$(bash_payload "$1")"; echo "$rc"; }
# A push is judged against the repo it runs in, so these carry a cwd.
guard_in() { hook "$GUARD" "$(bash_payload "$2" "$1")"; echo "$rc"; }

expect_exit "the absolute rules are blocked" 2 bash_payload "$GUARD" <<'CASES'
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

# A credit is judged in the message being committed, by whatever route it arrives.
# None may hinge on the word Claude: keys fold case and a model name has no brand.
expect_exit_blocks "" 2 bash_payload "$GUARD" <<'CASES'
--- an AI trailer in a commit message is blocked
git commit -m "feat: x

Co-Authored-By: Claude <n@a.com>"
--- a lowercase trailer key is blocked
git commit -m "feat: x

co-authored-by: Claude <n@anthropic.com>"
--- a model number with a vendor address is blocked
git commit -m "feat: x

Co-Authored-By: Opus 5 <noreply@anthropic.com>"
--- another vendor's agent is blocked
git commit -m "feat: x

Co-Authored-By: Cursor Agent <agent@cursor.sh>"
--- copilot is blocked
git commit -m "feat: x

Co-Authored-By: Copilot <copilot@github.com>"
CASES

# Widening that match costs false positives. A human co-author is legitimate,
# and a DCO sign-off is a human's attestation, so `-s` stays usable.
expect_exit_blocks "" 0 bash_payload "$GUARD" <<'CASES'
--- a human co-author passes
git commit -m "feat: x

Co-Authored-By: Jane Doe <jane@example.com>"
--- a DCO sign-off by a human named Cody passes
git commit -s -m "feat: x

Signed-off-by: Cody Smith <cody@example.com>"
CASES
eq "a plain signed-off commit passes" "0" "$(guard 'git commit -s -m "fix: x"')"

# Every vendor word that is also a given name comes out of the name list; the
# vendor's handle and the shape of a bot address catch those agents instead.
expect_exit_blocks "" 0 bash_payload "$GUARD" <<'CASES'
--- a human surnamed Cursor passes
git commit -m "feat: x

Co-Authored-By: Jane Cursor <jane@example.com>"
--- a human named Devin passes
git commit -m "feat: x

Co-Authored-By: Devin Parker <devin@example.com>"
CASES
# The last has no brand word anywhere, so only the bot-address pattern can fire.
expect_exit_blocks "" 2 bash_payload "$GUARD" <<'CASES'
--- the devin bot trailer is blocked
git commit -m "feat: x

Co-Authored-By: Devin <158243242+devin-ai-integration[bot]@users.noreply.github.com>"
--- another vendor's bot address is blocked
git commit -m "feat: x

Co-Authored-By: Copilot <12345+copilot-swe-agent[bot]@users.noreply.github.com>"
--- a bot address with no brand word is blocked
git commit -m "feat: x

Co-Authored-By: Some Bot <99+some-random-agent[bot]@users.noreply.github.com>"
CASES
# Read as a bracket expression instead of two literals, `[bot]` would match the
# `t` of "agent" and block the second.
expect_exit_blocks "" 0 bash_payload "$GUARD" <<'CASES'
--- an ordinary github noreply passes
git commit -m "feat: x

Co-Authored-By: Jane Doe <9876+janedoe@users.noreply.github.com>"
--- the same handle without [bot] passes
git commit -m "feat: x

Co-Authored-By: Some One <99+some-random-agent@users.noreply.github.com>"
CASES

# A credit counts when it is in the message being committed, and nowhere else.
# Each of these is a false positive the gate produced when it read the command.
expect_exit_blocks "a credit outside the message does not block" 0 bash_payload "$GUARD" <<'CASES'
--- a comment mentioning a trailer, with no commit
# note: never add Co-Authored-By: Claude <n@a.com> to a message
echo hi
--- a comment mentioning a trailer beside a commit
# note: Co-Authored-By: Claude <n@a.com>
git commit -m "fix: short"
--- another command's heredoc beside a commit
cat > /tmp/d.txt <<'END'
Co-Authored-By: Claude <n@a.com>
END
git commit -m "fix: short"
--- an unrelated command beside a commit
echo "Co-Authored-By: Claude <n@a.com>" && git commit -m "fix: short"
--- a session trailer in a comment beside a commit
# Claude-Session: https://x
git commit -m "fix: short"
--- an emoji outside the message beside a commit
echo "🤖" && git commit -m "fix: short"
CASES

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
expect_exit "a message this cannot read is not blocked" 0 bash_payload "$GUARD" <<CASES
git commit
git commit --amend --no-edit
git commit -F $WORK/no-such-message.txt
CASES
# A deliberate, accepted limit: the payload arrives on stdin from another
# statement, and a filter between the two makes it undecidable without running.
piped_credit=$'echo "fix: x\n\nCo-Authored-By: Claude <n@a.com>" | git commit -F -'
eq "a credit piped to -F - is a known miss" "0" "$(guard "$piped_credit")"

expect_exit "ordinary subjects naming claude pass" 0 bash_payload "$GUARD" <<'CASES'
git commit -m "feat(claude): add a draft-ticket skill"
git commit -m "fix: stop the claude-code cask lagging"
git commit -m "docs: link the anthropic docs page"
CASES

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

# shellcheck disable=SC2329  # passed by name to expect_exit or hook
meta_payload() { bash_payload "git commit -m 'fix: x' -m '$1'"; }
expect_exit "a body line about the session is blocked" 2 meta_payload "$GUARD" <<'CASES'
Kept both branches as requested.
Per the plan this stays synchronous.
Addresses the review finding on nulls.
Folds in the Review Feedback on nulls.
Also renames the helper.
CASES
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
# `git commit` is the commit. Each of these is a false positive of reading more.
expect_exit_blocks "only the statement that commits is judged" 0 bash_payload "$GUARD" <<'CASES'
--- the next line's flags are not a body
git commit -m "fix: valid short subject"
foo -m one -m two -m three -m four
--- another command's heredoc body is not tokens
printf x > /tmp/d.txt <<'END'
git commit -m "fix: x" -m "one" -m "two" -m "three" -m "four"
END
--- a shell comment is not a command
# example: git commit -m "fix: x" -m "one" -m "two" -m "three" -m "four"
echo hi
CASES

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
expect_exit "a message the hook cannot read is allowed" 0 bash_payload "$GUARD" <<CASES
git commit --amend --no-edit
git commit --amend
git commit
git commit -a
git commit -F -
git commit -F $WORK/not-a-file.txt
echo "git commit -m This commit is fine"
CASES

# A stock macOS /bin/bash is 3.2, where an empty array expanded under `set -u`
# aborts the whole script and the guard silently passes everything.
if [ -x /bin/bash ] && ! /bin/bash -c 'echo "${BASH_VERSINFO[0]}"' | grep -qx 5; then
  # shellcheck disable=SC2329  # passed by name to expect_exit or hook
  old_guard() { /bin/bash "$GUARD"; }
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    hook "$GUARD" "$(bash_payload "$c")"
    here=$rc
    hook old_guard "$(bash_payload "$c")"
    eq "nothing in the guard needs a bash newer than /bin/bash: $c" "$here" "$rc"
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
else
  skip "guard-bash.sh under an older /bin/bash (this one is bash 5)"
fi

expect_exit "ordinary work is not blocked" 0 bash_payload "$GUARD" <<'CASES'
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

# Each hides its command from a reader that splits on separators alone: behind
# an assignment, inside a subshell or substitution, or after a wrapper.
expect_exit "a rule sees past quotes, subshells and wrappers" 2 bash_payload "$GUARD" <<'CASES'
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

expect_exit "a command named in text is not run" 0 bash_payload "$GUARD" <<'CASES'
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
# shellcheck disable=SC2329  # passed by name to expect_exit or hook
opted_payload() { bash_payload "$1" "$PUSHES/opted"; }
expect_exit "a force push is blocked even in an opted-in repo" 2 opted_payload "$GUARD" <<'CASES'
git push --force origin main
git push --force-with-lease
git push -f
git push -uf origin main
git push origin +main
git -C . push --force
CASES
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

finish
