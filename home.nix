{
  config,
  lib,
  pkgs,
  user,
  cfg,
  inputs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  # Merges the durable half of Claude Code's user settings into whatever is
  # already at ~/.claude/settings.json. Base wins on the keys it names, so a
  # hook or statusline change reaches every machine on the next rebuild; every
  # other key survives untouched, which is what lets /config keep ownership of
  # model, effortLevel and theme without a write reaching this repo. Adding one
  # of those three to settings.base.json would revert it on every rebuild.
  claudeSettingsMerge = pkgs.writeShellScript "claude-settings-merge" ''
    set -eu
    target="$HOME/.claude/settings.json"
    base="${dotfiles}/home/.claude/settings.base.json"
    if [ ! -f "$base" ]; then
      echo "claude-settings-merge: $base is missing" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$target")"
    # A leftover link from when this file was linked into the repo. Writes
    # through it land in the working tree, which is what this replaces.
    if [ -L "$target" ]; then rm -f "$target"; fi
    if [ ! -f "$target" ]; then printf '%s\n' '{}' >"$target"; fi
    merged="$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$target" "$base")"
    printf '%s\n' "$merged" >"$target"
  '';

  # Same merge as Claude's, so a toggle made in the VS Code UI survives a rebuild.
  vscodeSettingsMerge = pkgs.writeShellScript "vscode-settings-merge" ''
    set -eu
    user="$HOME/Library/Application Support/Code/User"
    src="${dotfiles}/home/vscode"
    mkdir -p "$user"
    for f in settings keybindings; do
      [ -f "$user/$f.json" ] || printf '%s\n' "$([ $f = settings ] && echo '{}' || echo '[]')" >"$user/$f.json"
    done
    # VS Code allows comments in these files and jq does not, so a hand-commented file is left alone.
    if merged="$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$user/settings.json" "$src/settings.base.json" 2>/dev/null)"; then
      printf '%s\n' "$merged" >"$user/settings.json"
    else
      echo "vscode-settings-merge: settings.json is not plain JSON, skipped" >&2
    fi
    if merged="$(${pkgs.jq}/bin/jq -s '.[0] + [.[1][] as $b | select(.[0] | all(.key != $b.key or .command != $b.command or .when != $b.when)) | $b]' "$user/keybindings.json" "$src/keybindings.base.json" 2>/dev/null)"; then
      printf '%s\n' "$merged" >"$user/keybindings.json"
    else
      echo "vscode-settings-merge: keybindings.json is not plain JSON, skipped" >&2
    fi
  '';

  # Which address git commits as, per machine. Same name either way; only the
  # address changes. A user record without one fails the build on purpose:
  # committing work from the wrong address is the whole thing this exists to
  # prevent, and a silent default would do exactly that.
  gitEmail =
    cfg.email or (throw "home.nix: no git email for \"${user}\". Add one to flake.nix's users.");

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
  # the download aliases and the tone helper one of them shells out to by path,
  # linked as a directory so the two cannot drift apart.
  home.file.".config/yt-dlp".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/yt-dlp";
  # ~/.claude/settings.json is deliberately NOT linked here. It is the only
  # user-scope file Claude Code reads, and /config, /model and /effort all
  # persist into it, so a link would route every mid-session preference change
  # into this repo. settings.base.json carries the durable half instead, merged
  # in by an activation step rather than linked.
  home.activation.claudeSettings = config.lib.dag.entryAfter [
    "writeBoundary"
  ] "run ${claudeSettingsMerge}";
  home.activation.vscodeSettings = config.lib.dag.entryAfter [
    "writeBoundary"
  ] "run ${vscodeSettingsMerge}";
  home.activation.vscodeExtensions =
    config.lib.dag.entryAfter
      [
        "vscodeSettings"
      ]
      "run env PATH=${pkgs.jq}/bin:$PATH ${pkgs.bash}/bin/bash ${./home/vscode/extensions.sh} ${./home/vscode/extensions.json}";
  # Run by hand after opening a multi-root Scala workspace or bumping a flake's JDK.
  home.file.".local/bin/metals-java-home".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/vscode/metals-java-home.sh";
  # settings.base.json points at this by path, so it has to land in ~/.claude too.
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
  # a PreToolUse hook on Bash, reached by path the same way. it blocks rather
  # than nudges, so it has to exist before the tool call it judges.
  home.file.".claude/guard-bash.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/guard-bash.sh";
  # A PreToolUse hook on Skill and the write tools, reached by path the same way.
  # It must see the Skill call too, since that is the only evidence of a load.
  home.file.".claude/skill-gate.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/skill-gate.sh";
  # Linked per file, so a rule added by hand to ~/.claude/rules stays out of this repo.
  home.file.".claude/rules/typescript.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/rules/typescript.md";
  home.file.".claude/rules/python.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/rules/python.md";
  # The vault skills and impeccable live outside this repo, so no home.file can
  # carry them. After linkGeneration, so a clash with a link above warns instead.
  home.activation.localSkills = config.lib.dag.entryAfter [
    "linkGeneration"
  ] "run env PATH=${pkgs.nodejs}/bin:$PATH ${pkgs.bash}/bin/bash ${./home/.claude/local-skills.sh}";
  # One link per skill, never the folder: impeccable's installer also writes there.
  # A module each, because a computed home.file cannot share this attrset with home.file."x".
  imports = [
    {
      home.file = lib.mapAttrs' (
        name: _:
        lib.nameValuePair ".claude/skills/${name}" {
          source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/skills/${name}";
        }
      ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./home/.claude/skills));
    }
    # Also into ~/.agents/skills, the shared folder other agents read.
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
