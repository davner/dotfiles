# Interactive shell functions. Sourced from ~/.zshrc, which home.nix generates.
# These live here rather than inside a Nix string so that they are ordinary zsh
# read by ordinary tools: `zsh -n` checks them, the test suite runs them, and
# nothing has to survive a round trip through Nix's own escaping first.

# A session named after its repo, so remote control lists "dotfiles" rather
# than a summary of whatever the first prompt said. A second session in the
# same repo becomes dotfiles-2. Anything passed to cc still reaches claude,
# including a --name of your own: the last one on the line wins.
cc() {
  local name; local -a flag
  name="$(~/.claude/session-name.sh)"
  # An array, not ${name:+--name "$name"}: zsh does not split an expansion
  # into words, so that form would hand claude one argument reading
  # "--name dotfiles" and it would reject it.
  [[ -n $name ]] && flag=(--name "$name")
  claude --dangerously-skip-permissions --remote-control "${flag[@]}" "$@"
}

# Flips whether agents may run a plain `git push` in the current repo, the
# opt-in guard-bash.sh reads. It writes the repo's local config, so it never
# follows you to another repo. `on`/`off` set it outright, `status` only reads.
cc-push() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "cc-push: not inside a git repo" >&2; return 1; }
  local now want
  now="$(git config --local --get claude.allowPush)"
  case "$1" in
    on) want=true ;;
    off) want=false ;;
    status) echo "claude.allowPush=${now:-unset} in $(git rev-parse --show-toplevel)"; return 0 ;;
    '') if [[ $now == true ]]; then want=false; else want=true; fi ;;
    *) echo "usage: cc-push [on|off|status]" >&2; return 2 ;;
  esac
  git config --local claude.allowPush "$want" &&
    echo "claude.allowPush=$want in $(git rev-parse --show-toplevel)"
}

# The ticket workflow from the README as a table, for when you forget the next
# step. Plain printf so it costs no tokens. Every /name in it is checked against
# home/.claude/skills by test.sh, so a renamed skill fails a test here too.
cc-flow() {
  local b= d= c= r=
  # Color only on a terminal, so `cc-flow | less` or a pipe gets clean text.
  if [[ -t 1 && -z $NO_COLOR ]]; then
    b=$'\e[1m' d=$'\e[2m' c=$'\e[36m' r=$'\e[0m'
  fi
  local row="  %-3s %-8s ${c}%-19s${r} %s\n"
  local note="  %-3s %-8s %-19s ${d}%s${r}\n"
  printf "\n ${b}Ticket workflow${r}  ${d}(full version: README.md, Workflow)${r}\n\n"
  printf "${b}  %-3s %-8s %-19s %s${r}\n" "#" "Stage" "Run" "What it does"
  printf "  ${d}%s${r}\n" "--- -------- ------------------- ------------------------------------------"
  printf "$row"  0 Setup   /setup-dan-skills  "Once per repo: tracker and where docs go"
  printf "$row"  1 Align   /grill-with-docs   "Interview until nothing is open; saves the"
  printf "$note" "" ""     ""                 "glossary and ADRs. /grill-me outside a repo"
  printf "$row"  2 See     /prototype         "Optional: throwaway variants, when you must"
  printf "$note" "" ""     ""                 "see it run. New screen? /handoff out first"
  printf "$row"  3 Plan    /to-spec           "Problem, solution, scope: paste as the epic"
  printf "$row"  "" ""     /to-tickets        "Thin slices with blockers: paste as stories"
  printf "$note" "" ""     ""                 "Keep 1-3 in one conversation; clear after"
  printf "$row"  4 Build   /implement         "One ticket per fresh conversation, blockers"
  printf "$note" "" ""     ""                 "first. Or /implement-spec for all at once"
  printf "$row"  5 Review  /code-review       "Checks the diff against standards and spec"
  printf "$note" "" ""     "(you try it)"     "Want changes? New ticket, back to step 3"
  printf "$row"  6 Ship    /pr                "Paste-ready PR title and body"
  printf "$row"  7 Learn   /retro             "Same session, before you clear it"
  printf "\n ${b}Shortcuts${r}\n"
  printf "  %-21s ${c}%-19s${r} %s\n" \
    "Small, clear change" /implement        "Skip 1-3, build it right away" \
    "A bug"               /diagnosing-bugs  "Reproduce, fix, then /code-review" \
    "Context too full"    /handoff          "Summary to start a fresh session" \
    "Didn't follow that"  /wait-what        "Re-explains the last message"
  printf "\n"
}
