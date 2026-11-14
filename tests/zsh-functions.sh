#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "the cc function"
# cc has to hand the name to claude as two words. It is run, not grepped for
# --name: the string was there even when claude got the one word "--name myrepo".
FN="$DIR/home/.config/zsh/functions.zsh"
# Its own check, because tests/lint.sh lints only *.sh files.
if err="$(zsh -n "$FN" 2>&1)"; then ok "zsh -n functions.zsh"; else bad "zsh -n functions.zsh" "$err"; fi

fixture_stub
# Prints its arguments one per line, so a name that arrived as one word
# containing a space is visibly different from two words.
cat >"$STUB/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
EOF
chmod +x "$STUB/claude"
# Without a naming script that answers, the name is empty and the --name
# assertion below would pass while asserting nothing.
fixture_sthome
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

# $FAKEHOME has no session-name.sh, so the name is empty, and the array has to
# vanish rather than leave claude a bare --name or an empty string after it.
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
# A skill name follows a space or starts the line; a path like
# docs/workflow.md would otherwise read as the skill /workflow.
for name in $(printf '%s\n' "$FLOW_OUT" | grep -oE '(^|[[:space:]])/[a-z][a-z-]+' | sed 's/^[[:space:]]*//' | sort -u); do
  [ -f "$DIR/home/.claude/skills${name}/SKILL.md" ] || FLOW_MISSING="$FLOW_MISSING $name"
done
if [ -z "$FLOW_MISSING" ]; then
  ok "every skill cc-flow names exists"
else
  bad "every skill cc-flow names exists" "no such skill:$FLOW_MISSING"
fi
contains "cc-flow lists autopilot" "$FLOW_OUT" "/autopilot"
# The pointer is how a forgotten step gets looked up, so it must name a page
# that exists.
if [[ $FLOW_OUT == *docs/workflow.md* && -f "$DIR/docs/workflow.md" ]]; then
  ok "cc-flow points at docs/workflow.md, which exists"
else
  bad "cc-flow points at docs/workflow.md, which exists" \
    "named: $(printf '%s\n' "$FLOW_OUT" | grep -o 'full version: [^)]*')"
fi
# Piped output is what `cc-flow | less` sees; escape codes there print as junk.
case "$FLOW_OUT" in
  *$'\e'*) bad "cc-flow prints no color into a pipe" "found an escape code" ;;
  *) ok "cc-flow prints no color into a pipe" ;;
esac

# The only tie from the generated ~/.zshrc to functions.zsh; the -r guard keeps a
# dangling symlink from printing an error in every new shell.
if grep -qF '[ -r ~/.config/zsh/functions.zsh ] && source' "$DIR/home.nix"; then
  ok "home.nix sources functions.zsh, and guards it"
else
  bad "home.nix sources functions.zsh, and guards it" \
    "nothing in ~/.zshrc would load the function"
fi

finish
