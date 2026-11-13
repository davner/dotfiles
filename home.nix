# Over the core's inputs, so the skill folders come from the core's lock whichever flake imports it.
inputs:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = config.dotfiles.user.name;
  dotfiles = config.dotfiles.checkout;

  jsonMerge = "env PATH=${pkgs.jq}/bin:$PATH ${pkgs.bash}/bin/bash ${./home/json-merge.sh}";
  vscodeUser = "$HOME/Library/Application Support/Code/User";
  # Empty with no fragments, so the merge line and the personal Macs' builds stay as they were.
  claudeFragmentArgs = lib.concatMapStrings (
    f: " --extend ${pkgs.writeText "claude-settings-fragment.json" (builtins.toJSON f)}"
  ) config.dotfiles.claude.settingsFragments;

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

  # Per entry, never the folder, so a file added by hand on the home side
  # stays out of this repo.
  linkEach =
    dir: dst: keep:
    lib.mapAttrs' (
      name: _:
      lib.nameValuePair "${dst}/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${dir}/${name}";
      }
    ) (lib.filterAttrs keep (builtins.readDir (./. + "/${dir}")));
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
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

  # lucuma-odb and lucuma-core get Java and sbt only from their flakes.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Dan Avner";
      user.email = config.dotfiles.git.email;
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
  # A consumer's settingsFragments fold into the base first and may only add to
  # it: a fragment that replaced an array would drop the base's entries, deny rules included.
  home.activation.claudeSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    run ${jsonMerge} --drop-link${claudeFragmentArgs} deep "${dotfiles}/home/.claude/settings.base.json" "$HOME/.claude/settings.json"
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
  # Run by hand after opening a multi-root Scala workspace or bumping a flake's JDK.
  home.file.".local/bin/metals-java-home".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/vscode/metals-java-home.sh";
  # The vault skills and impeccable live outside this repo, so no home.file can
  # carry them. After linkGeneration, so a clash with a home.file link warns instead.
  home.activation.localSkills = config.lib.dag.entryAfter [
    "linkGeneration"
  ] "run env PATH=${pkgs.nodejs}/bin:$PATH ${pkgs.bash}/bin/bash ${./home/.claude/local-skills.sh}";
  # A module, because a computed home.file cannot share this attrset with home.file."x".
  imports = [
    {
      options.dotfiles = {
        user.name = lib.mkOption {
          type = lib.types.str;
          description = "The macOS username this home belongs to.";
        };
        # No silent default: committing from the wrong address is what this prevents.
        git.email =
          let
            missing = throw "no git email for \"${user}\". Set dotfiles.git.email; this repo's own Macs take it from flake.nix's users.";
          in
          lib.mkOption {
            type = lib.types.str;
            default = missing;
            defaultText = lib.literalMD "none; the build fails without one";
            # An empty address is a missing one that got past the type check.
            apply = email: if email == "" then missing else email;
            description = "The address git commits as.";
          };
        # A string, not a path: a path literal would be copied into the store,
        # and the links would stop being live.
        checkout = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.dotfiles";
          defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.dotfiles"'';
          description = "Where this core is checked out. Its live links and settings merges read from here.";
        };
        claude.settingsFragments = lib.mkOption {
          type = lib.types.listOf (lib.types.attrsOf (pkgs.formats.json { }).type);
          default = [ ];
          # Same rule as settings.base.json: the merge wins, so these would undo /config on every rebuild.
          apply = map (
            fragment:
            let
              claimed = lib.intersectLists [ "model" "effortLevel" "theme" ] (builtins.attrNames fragment);
            in
            if claimed == [ ] then
              fragment
            else
              throw "a Claude settings fragment sets ${lib.concatStringsSep ", " claimed}; /config owns those, and the merge would revert them on every rebuild (ADR 0007)."
          );
          description = "JSON objects folded into Claude's settings after settings.base.json, in order. A fragment may add keys and extend the base's arrays, never replace an array or object the base sets.";
        };
      };
    }
    {
      home.file = lib.mergeAttrsList [
        # impeccable's installer and local-skills.sh also write into ~/.claude/skills.
        (linkEach "home/.claude/skills" ".claude/skills" (
          name: type: type == "directory" && !lib.elem name config.dotfiles.skills.exclude
        ))
        # settings.base.json and the cc function reach these by path.
        (linkEach "home/.claude/hooks" ".claude/hooks" (_: type: type == "regular"))
        (linkEach "home/.claude/rules" ".claude/rules" (
          name: type: type == "regular" && lib.hasSuffix ".md" name
        ))
      ];
    }
    # Also into ~/.agents/skills, the shared folder other agents read.
    {
      options.dotfiles.skills.extra = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        description = "Skills to link beside the core's, by name to folder; the name must match the SKILL.md's.";
      };
      options.dotfiles.skills.exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        # A typo would otherwise leave the skill linked with nothing to say so.
        apply =
          names:
          let
            known =
              lib.attrNames (
                lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./home/.claude/skills)
              )
              ++ lib.attrNames thirdPartySkills;
            unknown = lib.subtractLists known names;
          in
          if unknown == [ ] then
            names
          else
            throw "dotfiles.skills.exclude names ${
              lib.concatMapStringsSep ", " (n: "\"${n}\"") unknown
            }, which is neither a core nor a third-party skill.";
        description = "Core or third-party skills not to link, by name.";
      };
      # Two definitions, not one merged attrset, so an extra that reuses a core name is a conflict, not a silent swap.
      config.home.file = lib.mkMerge (
        map
          (lib.concatMapAttrs (
            name: src: {
              ".claude/skills/${name}".source = src;
              ".agents/skills/${name}".source = src;
            }
          ))
          [
            (removeAttrs thirdPartySkills config.dotfiles.skills.exclude)
            config.dotfiles.skills.extra
          ]
      );
    }
  ];

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
