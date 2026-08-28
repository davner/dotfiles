{ config, pkgs, user, cfg, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  # Which address git commits as, per machine. Same name either way; only the
  # address changes. A user record without one fails the build on purpose:
  # committing work from the wrong address is the whole thing this exists to
  # prevent, and a silent default would do exactly that.
  gitEmail =
    cfg.email or (throw
      "home.nix: no git email for \"${user}\". Add one to flake.nix's users.");
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
    # Shell functions live in a real .zsh file, not in this string. The guard
    # is not paranoia: the file arrives by out-of-store symlink, so a checkout
    # that has moved leaves a dangling link, and an unguarded source would
    # print an error on every new shell.
    initContent = ''
      bindkey '^f' autosuggest-accept
      [ -r ~/.config/zsh/functions.zsh ] && source ~/.config/zsh/functions.zsh
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
  # the shell functions the generated ~/.zshrc sources at the end of its init.
  home.file.".config/zsh/functions.zsh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/zsh/functions.zsh";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  # settings.json points at this by path, so it has to land in ~/.claude too.
  home.file.".claude/statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/statusline.sh";
  # likewise the naming script: the cc function and a SessionStart hook both
  # call it, so it has to be on disk at a path neither one has to guess.
  home.file.".claude/session-name.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/session-name.sh";
  # a PostToolUse hook, so settings.json reaches it by path the same way. it
  # runs inside subagents too, which is where the code actually gets written.
  home.file.".claude/comment-audit.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/comment-audit.sh";
  # the subagent roster. one file per agent, claude picks them up by name.
  home.file.".claude/agents".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/agents";
  # Skills are linked one at a time, never as the whole `skills/` directory:
  # ~/.claude/skills also holds the hand-installed ones, and a directory-level
  # link would displace every one of them.
  home.file.".claude/skills/primereact-v10".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/skills/primereact-v10";
  home.file.".claude/skills/tailwind-v4".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/skills/tailwind-v4";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}