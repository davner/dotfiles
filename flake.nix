{
  description = "dotfiles";

  inputs = {
    # Use `github:NixOS/nixpkgs/nixpkgs-26.05-darwin` to use Nixpkgs 26.05.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # Use `github:nix-darwin/nix-darwin/nix-darwin-26.05` to use Nixpkgs 26.05.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs }:
    let
      # Every macOS username this repo can build for. This is a list, not a
      # single value, so one checkout serves the work machine and the personal
      # machine at once - switching between them is a matter of which entry
      # gets built, not an edit to this file that has to be undone later.
      # bootstrap.sh and rebuild.sh pick the entry matching whoever runs them.
      users = [
        "danavner"
        "dan.avner"
      ]; # end users - bootstrap.sh appends new usernames above this line

      # darwin-rebuild splits its flake attribute on ".", so a username
      # containing a dot cannot be an attribute name: `#darwinConfigurations
      # .dan.avner.system` would be read as four path segments. Dots become
      # dashes, and both scripts apply the same substitution when they choose
      # which configuration to build.
      attrFor = user: builtins.replaceStrings [ "." ] [ "-" ] user;

      # configuration.nix builds for aarch64-darwin, but the dev shell is
      # useful on either Mac.
      forEachDarwin = f: builtins.listToAttrs (
        map (system: { name = system; value = f nixpkgs.legacyPackages.${system}; })
          [ "aarch64-darwin" "x86_64-darwin" ]
      );

      mkDarwin = user: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user; };
            home-manager.users.${user} = import ./home.nix;
            # A dotfile that already exists and that this config also manages
            # gets moved to <name>.backup rather than failing the activation.
            # Nothing is ever overwritten in place. If the activation later
            # complains that the .backup itself would be clobbered, that means
            # an older backup is still sitting there: read it, then delete it.
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    in
    {
      # One configuration per username, e.g. `#danavner` and `#dan-avner`.
      darwinConfigurations = builtins.listToAttrs (
        map (user: { name = attrFor user; value = mkDarwin user; }) users
      );

      # What ./test.sh lints with and what regenerates CHANGELOG.md, pinned by
      # flake.lock so CI and this machine agree. `nix develop --command
      # ./test.sh` skips nothing.
      devShells = forEachDarwin (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [ pkgs.shellcheck pkgs.actionlint pkgs.git-cliff ];
        };
      });
    };
}
