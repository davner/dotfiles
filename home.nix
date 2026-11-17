{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # A string, not a path: a path literal would be copied into the store, and
  # the links would stop being live.
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  jsonMerge = "env PATH=${pkgs.jq}/bin:$PATH ${pkgs.bash}/bin/bash ${./home/json-merge.sh}";
  vscodeUser = "$HOME/Library/Application Support/Code/User";

  # Skill name -> its folder inside a pinned flake input. The name must match
  # the SKILL.md frontmatter, since Claude Code invokes a skill by that name.
  thirdPartySkills = {
    gh-axi = "${inputs.gh-axi}/skills/gh-axi";
    chrome-devtools-axi = "${inputs.chrome-devtools-axi}/skills/chrome-devtools-axi";
    lavish = "${inputs.lavish-axi}/skills/lavish";
    humanizer = "${inputs.humanizer}";
    shadcn = "${inputs.shadcn-ui}/skills/shadcn";
    migrate-radix-to-base = "${inputs.shadcn-ui}/skills/migrate-radix-to-base";
    typescript-style-guide = "${inputs.typescript-style-guide}/skills/typescript-style-guide";
    modern-python = "${inputs.trailofbits-skills}/plugins/modern-python/skills/modern-python";
    python-anti-patterns = "${inputs.wshobson-agents}/plugins/python-development/skills/python-anti-patterns";
  };

  entries = dir: keep: lib.attrNames (lib.filterAttrs keep (builtins.readDir (./. + "/${dir}")));
  coreSkills = entries "home/.claude/skills" (_: type: type == "directory");

  # Per entry, never the folder, so a file added by hand on the home side
  # stays out of this repo.
  linkEach =
    dir: dst: names:
    lib.genAttrs' names (
      name:
      lib.nameValuePair "${dst}/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${dir}/${name}";
      }
    );
in

{
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep # fast search
    fd # fast find
    fzf # fuzzy finder
    jq # json on the command line
    lazygit
    neovim
    shellcheck # ./test.sh lints with it, and it is worth having on PATH anyway
    nodejs
    pnpm
    uv
    # pulling audio and video off youtube into icloud, see .config/yt-dlp/config
    yt-dlp
    ffmpeg # yt-dlp merges, trims and converts through it
    deno # the js runtime yt-dlp runs youtube's player challenge in
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "code";
  # Where `uv tool install` puts its executables.
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true; # ghost text from history
    syntaxHighlighting.enable = true; # commands turn green when valid
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Dan Avner";
      user.email = "ldpavner@gmail.com";
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
  # the download aliases and the tone helper one of them shells out to by path,
  # linked as a directory so the two cannot drift apart.
  home.file.".config/yt-dlp".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/yt-dlp";
  # ~/.claude/settings.json is deliberately NOT linked here. It is the only
  # user-scope file Claude Code reads, and /config, /model and /effort all
  # persist into it, so a link would route every mid-session preference change
  # into this repo. settings.base.json carries the durable half instead, merged
  # in by an activation step rather than linked. Base wins on the keys it
  # names, so adding model, effortLevel or theme to it would revert /config on
  # every rebuild. A link there dates from when this file was linked, so it goes.
  home.activation.claudeSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    run ${jsonMerge} --drop-link deep "${dotfiles}/home/.claude/settings.base.json" "$HOME/.claude/settings.json"
  '';
  # VS Code allows comments in these files and jq does not, so a hand-commented file is skipped.
  home.activation.vscodeSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    run ${jsonMerge} --skip-invalid deep "${dotfiles}/home/vscode/settings.base.json" "${vscodeUser}/settings.json"
    run ${jsonMerge} --skip-invalid append-unique key,command,when "${dotfiles}/home/vscode/keybindings.base.json" "${vscodeUser}/keybindings.json"
  '';
  home.activation.vscodeExtensions =
    config.lib.dag.entryAfter
      [
        "vscodeSettings"
      ]
      "run env PATH=${pkgs.jq}/bin:$PATH ${pkgs.bash}/bin/bash ${./home/vscode/extensions.sh} ${./home/vscode/extensions.json}";
  # impeccable writes into its own folder, so no home.file can carry it.
  # After linkGeneration, so an impeccable a home.file links is seen, not reinstalled.
  home.activation.localSkills = config.lib.dag.entryAfter [
    "linkGeneration"
  ] "run env PATH=${pkgs.nodejs}/bin:$PATH ${pkgs.bash}/bin/bash ${./home/.claude/local-skills.sh}";
  # A module, because a computed home.file cannot share this attrset with home.file."x".
  imports = [
    {
      home.file = lib.mergeAttrsList [
        # impeccable's installer and local-skills.sh also write into ~/.claude/skills.
        (linkEach "home/.claude/skills" ".claude/skills" coreSkills)
        # settings.base.json and the cc function reach these by path.
        (linkEach "home/.claude/hooks" ".claude/hooks" (
          entries "home/.claude/hooks" (_: type: type == "regular")
        ))
        (linkEach "home/.claude/rules" ".claude/rules" (
          entries "home/.claude/rules" (name: type: type == "regular" && lib.hasSuffix ".md" name)
        ))
      ];
    }
    # Its own definition, so a third-party skill reusing a core name is a conflict, not a silent swap.
    {
      home.file = lib.concatMapAttrs (name: src: {
        ".claude/skills/${name}".source = src;
        ".agents/skills/${name}".source = src;
      }) thirdPartySkills;
    }
  ];

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
