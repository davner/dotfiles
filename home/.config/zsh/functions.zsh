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
