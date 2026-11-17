{
  config,
  inputs,
  lib,
  ...
}:

let
  user = "danavner";
in
{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.users.${user} = ./home.nix;
  # A clashing dotfile moves to <name>.backup; an older .backup in the way must be read and deleted.
  home-manager.backupFileExtension = "backup";

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  # https://nix-darwin.github.io/nix-darwin/manual/
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2; # fast key repeat
      InitialKeyRepeat = 15; # short delay before repeat
      _HIHideMenuBar = false; # keep the menu bar always visible
      AppleShowAllExtensions = true;
      AppleEnableMouseSwipeNavigateWithScrolls = true; # swipe to go back/forward in browsers
      AppleEnableSwipeNavigateWithScrolls = true; # swipe to go back/forward in browsers
      AppleShowScrollBars = "Always"; # always show scroll bars
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticDashSubstitutionEnabled = false;
      NSWindowShouldDragOnGesture = true; # allow dragging windows with trackpad
      "com.apple.swipescrolldirection" = false; # natural scrolling off
      AppleWindowTabbingMode = "always"; # prefer tabs over new windows
    };
    WindowManager.AutoHide = true;
    WindowManager.AppWindowGroupingBehavior = true;
    dock.autohide = true;
    dock.orientation = "bottom";
    dock.minimize-to-application = true;
    dock.show-recents = false;
    dock.wvous-br-corner = 10; # bottom right corner: put display to sleep
    dock.wvous-bl-corner = 4; # bottom left corner: show desktop
    dock.wvous-tr-corner = 12; # top right corner: notification center
    dock.wvous-tl-corner = 2; # top left corner: mission control
    finder.FXRemoveOldTrashItems = true; # empty trash automatically after 30 days
    finder.ShowStatusBar = true; # show status bar
    finder.FXPreferredViewStyle = "clmv"; # column view
    finder.CreateDesktop = false; # clean desktop
    finder.AppleShowAllFiles = true; # show hidden files
    finder.ShowPathbar = true; # show path bar
    finder._FXEnableColumnAutoSizing = true; # auto-size columns
    finder._FXSortFoldersFirst = true; # sort folders first
    finder._FXSortFoldersFirstOnDesktop = true; # sort folders first on desktop

    trackpad.Clicking = true; # tap to click
    controlcenter.BatteryShowPercentage = true; # show battery percentage
    iCal."TimeZone support enabled" = true; # enable time zone support in calendar
    screencapture.include-date = true; # include date in screenshot file name

  };
  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap"; # remove anything not listed here
    # Auto-update re-runs nix-homebrew's wrapper, which loses PATH, so bundle cannot find mas.
    onActivation.autoUpdate = false;
    onActivation.upgrade = true; # the update only refreshes metadata; this bumps what is installed
    # Activation runs as root, so nothing from the interactive shell's
    # environment is in scope here. These have to be set explicitly.
    onActivation.extraEnv = {
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_ENV_HINTS = "1";
    };
    brews = [
      "openmotif"
      "mas" # installs masApps; listed so zap does not remove it
    ];
    casks = [
      "wezterm"
      "claude-code@latest"
      "visual-studio-code"
      "google-chrome"
      "obsidian"
      "docker-desktop"
      "xquartz" # the X11 server openmotif draws through
      "spotify"
      "discord"
      "zoom"
      "chatgpt"
      "vlc"
      "the-unarchiver"
      "appcleaner"
    ];
    # By App Store ID. Cleanup uninstalls any App Store app not listed here.
    masApps = {
      "Magnet" = 441258766;
      "Amphetamine" = 937984704;
      "Slack" = 803453959;
      "Tailscale" = 1475387142;
      "uBlock Origin Lite" = 6745342698;
      "Hover for Safari" = 1540705431;
      "Vinegar" = 1591303229;
      "Keynote" = 409183694;
      "Xcode" = 497799835;
      "Apple Configurator" = 1037126344;
    };
  };
  # Between nix-homebrew's prefix setup (mkBefore) and bundle; offline it only warns.
  system.activationScripts.homebrew.text = lib.mkOrder 750 ''
    if [ -f "${config.homebrew.prefix}/bin/brew" ]; then
      echo >&2 "Homebrew update..."
      sudo --user=${user} --set-home env ${
        lib.concatStringsSep " " (
          lib.mapAttrsToList (n: v: "${n}=${lib.escapeShellArg v}") config.homebrew.onActivation.extraEnv
        )
      } "${config.homebrew.prefix}/bin/brew" update \
        || echo >&2 "warning: brew update failed; upgrading against the metadata already on disk"
    fi
  '';
}
