# Over the core's inputs, so `self` is the core whichever flake imports it.
{ self, ... }:
{ config, lib, ... }:

let
  cfg = config.dotfiles;
  user = cfg.user.name;
in
{
  imports = [
    {
      options.dotfiles = {
        user.name = lib.mkOption {
          type = lib.types.str;
          description = "The macOS username this machine is built for.";
        };
        # Null, so the home module's default is the one missing-email message.
        git.email = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "The address git commits as. The build fails without one.";
        };
        # Defaulted because pkgs needs it before the missing-email throw can speak.
        system = lib.mkOption {
          type = lib.types.str;
          default = "aarch64-darwin";
          description = "The platform this machine is built for.";
        };
      };
    }
  ];

  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = cfg.system;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # mkMerge, not imports: imports would move the home module later in merge order,
  # and the reordered lists would change the personal Macs' builds.
  home-manager.users.${user} = lib.mkMerge [
    self.homeModules.default
    {
      dotfiles.user.name = user;
      dotfiles.git.email = lib.mkIf (cfg.git.email != null) cfg.git.email;
    }
  ];
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
    onActivation.autoUpdate = true;
    onActivation.upgrade = true; # autoUpdate only refreshes metadata; this bumps what is installed
    # Activation runs as root, so nothing from the interactive shell's
    # environment is in scope here. These have to be set explicitly.
    onActivation.extraEnv = {
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_ENV_HINTS = "1";
    };
    brews = [
      "openmotif"
    ];
    casks = [
      "wezterm"
      "claude-code@latest"
    ];
  };
}
