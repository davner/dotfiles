{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  # https://nix-darwin.github.io/nix-darwin/manual/
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = false; # auto-hide the menu bar
      AppleShowAllExtensions = true;
      AppleEnableMouseSwipeNavigateWithScrolls = true;  # swipe to go back/forward in browsers
      AppleEnableSwipeNavigateWithScrolls = true;       # swipe to go back/forward in browsers
      AppleShowScrollBars = "Always";  # always show scroll bars
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticDashSubstitutionEnabled = false;
      NSWindowShouldDragOnGesture = true;  # allow dragging windows with trackpad
      "com.apple.swipescrolldirection" = false;  # natural scrolling
      AppleWindowTabbingMode = "always";  # prefer tabs over new windows
    };
    WindowManager.AutoHide = true;
    WindowManager.AppWindowGroupingBehavior = true;
    dock.autohide = true;
    dock.orientation = "bottom";
    dock.minimize-to-application = true;
    dock.show-recents = false;
    dock.wvous-br-corner = 10;  # bottom right corner: put display to sleep
    dock.wvous-bl-corner = 4;  # bottom left corner: show desktop
    dock.wvous-tr-corner = 12;  # top right corner: notification center
    dock.wvous-tl-corner = 2;  # top left corner: mission control
    finder.FXRemoveOldTrashItems = true;  # empty trash automatically after 30 days
    finder.ShowStatusBar = true;          # show status bar
    finder.FXPreferredViewStyle = "clmv";  # column view
    finder.CreateDesktop = false;          # clean desktop
    finder.AppleShowAllFiles = true;       # show hidden files
    finder.ShowPathbar = true;             # show path bar
    finder._FXEnableColumnAutoSizing = true;  # auto-size columns
    finder._FXSortFoldersFirst = true;          # sort folders first
    finder._FXSortFoldersFirstOnDesktop = true;  # sort folders first on desktop

    trackpad.Clicking = true;              # tap to click
    controlcenter.BatteryShowPercentage = true;  # show battery percentage
    iCal."TimeZone support enabled" = true;  # enable time zone support in calendar
    screencapture.include-date = true;  # include date in screenshot file name

  };
  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;  # autoUpdate only refreshes metadata; this bumps what is installed
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
    ];
    casks = [
      "wezterm"
      "claude-code"
      "miniforge"
    ];
  };
}