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
      # Every macOS username this repo can build for. This is an attrset, not a
      # single value, so one checkout serves the work machine and the personal
      # machine at once - switching between them is a matter of which entry
      # gets built, not an edit to this file that has to be undone later.
      # bootstrap.sh and rebuild.sh pick the entry matching whoever runs them.
      #
      # A record holds only what genuinely differs from one machine to the
      # next, so it does not turn into the place every new option gets parked:
      # anything the machines agree on belongs in configuration.nix or home.nix
      # where it is stated once. Note that weekly.yml and update.yml build
      # every entry on macos-latest, which is arm64 - an x86_64-darwin record
      # would fail CI with no builder available.
      users = {
        "danavner"  = { email = "ldpavner@gmail.com";    system = "aarch64-darwin"; };
        "dan.avner" = { email = "dan.avner@noirlab.edu"; system = "aarch64-darwin"; };
      }; # end users - bootstrap.sh appends new usernames above this line

      # darwin-rebuild splits its flake attribute on ".", so a username
      # containing a dot cannot be an attribute name: `#darwinConfigurations
      # .dan.avner.system` would be read as four path segments. Dots become
      # dashes, and both scripts apply the same substitution when they choose
      # which configuration to build.
      attrFor = user: builtins.replaceStrings [ "." ] [ "-" ] user;

      # Every configured machine is aarch64-darwin today, but the dev shell is
      # useful on either Mac.
      forEachDarwin = f: builtins.listToAttrs (
        map (system: { name = system; value = f nixpkgs.legacyPackages.${system}; })
          [ "aarch64-darwin" "x86_64-darwin" ]
      );

      # A record's fields are optional, which is what lets `users.sh add` write
      # an empty one and lets the missing-email throw be the thing that speaks.
      # That same tolerance would swallow a typo: `sytem = "x86_64-darwin"` is
      # not an error, it is an ignored key and a silent aarch64 build. So the
      # keys are checked even though the values are not.
      knownFields = [ "email" "system" ];
      checkRecord = user: record:
        let
          unknown = builtins.filter (k: !(builtins.elem k knownFields))
            (builtins.attrNames record);
        in
        if unknown == [ ] then record
        else throw ''
          flake.nix: user "${user}" has unknown field(s): ${builtins.concatStringsSep ", " unknown}.
          A record holds only ${builtins.concatStringsSep " and " knownFields}. Check the spelling.'';

      # Both scopes get the username and its record: configuration.nix needs
      # the platform, home.nix needs the git address.
      mkDarwin = user: let cfg = checkRecord user users.${user}; in nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user cfg; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user cfg; };
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
        map (user: { name = attrFor user; value = mkDarwin user; })
          (builtins.attrNames users)
      );

      # What ./test.sh lints with and what regenerates CHANGELOG.md, pinned by
      # flake.lock so CI and this machine agree. `nix develop --command
      # ./test.sh` skips nothing.
      devShells = forEachDarwin (pkgs: {
        default = pkgs.mkShellNoCC {
          # jq is what home/.claude/comment-audit.sh parses its payload with,
          # and test.sh skips those checks without it. macOS has shipped jq at
          # /usr/bin/jq since Sequoia and CI runners carry one, so the tests
          # pass either way - but neither is this flake's to promise.
          packages = [ pkgs.shellcheck pkgs.actionlint pkgs.git-cliff pkgs.jq ];
        };
      });
    };
}
