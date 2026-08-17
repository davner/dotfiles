{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  # Which address git commits as, per machine. Same name either way; only the
  # address changes. A username missing from this map fails the build on
  # purpose: committing work from the wrong address is the whole thing this
  # map exists to prevent, and a silent default would do exactly that.
  gitEmails = {
    "danavner" = "ldpavner@gmail.com";
    "dan.avner" = "dan.avner@noirlab.edu";
  };
  gitEmail =
    gitEmails.${user} or (throw
      "home.nix: no git email for \"${user}\". Add one to gitEmails.");
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    shellcheck  # ./test.sh lints with it, and it is worth having on PATH anyway
    nodejs
    pnpm
    uv
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "code";

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept

      # A session named after its repo, so remote control lists "dotfiles"
      # rather than a summary of whatever the first prompt said. A second
      # session in the same repo becomes dotfiles-2. Anything passed to cc
      # still reaches claude, including a --name of your own: the last one
      # on the line wins.
      cc() {
        local name; local -a flag
        name="$(~/.claude/session-name.sh)"
        # An array, not ''${name:+--name "$name"}: zsh does not split an
        # expansion into words, so that form would hand claude one argument
        # reading "--name dotfiles" and it would reject it.
        [[ -n $name ]] && flag=(--name "$name")
        claude --dangerously-skip-permissions --remote-control "''${flag[@]}" "$@"
      }
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Dan Avner";
      user.email = gitEmail;
      init.defaultBranch = "main";
      push.autoSetupRemote = "true";
    };
    lfs.enable = true;
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      aliases.co = "pr checkout";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  # settings.json points at this by path, so it has to land in ~/.claude too.
  home.file.".claude/statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/statusline.sh";
  # likewise the naming script: the cc function and a SessionStart hook both
  # call it, so it has to be on disk at a path neither one has to guess.
  home.file.".claude/session-name.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/session-name.sh";
  # the subagent roster. one file per agent, claude picks them up by name.
  home.file.".claude/agents".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/agents";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}