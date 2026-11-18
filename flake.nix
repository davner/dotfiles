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

    # Third-party skills. Not flakes, just source trees: home.nix links one
    # folder out of each, and update.yml bumps them with everything else.
    gh-axi.url = "github:kunchenguid/gh-axi";
    gh-axi.flake = false;
    chrome-devtools-axi.url = "github:kunchenguid/chrome-devtools-axi";
    chrome-devtools-axi.flake = false;
    lavish-axi.url = "github:kunchenguid/lavish-axi";
    lavish-axi.flake = false;
    humanizer.url = "github:blader/humanizer";
    humanizer.flake = false;
    shadcn-ui.url = "github:shadcn-ui/ui";
    shadcn-ui.flake = false;
    typescript-style-guide.url = "github:mkosir/typescript-style-guide";
    typescript-style-guide.flake = false;
    trailofbits-skills.url = "github:trailofbits/skills";
    trailofbits-skills.flake = false;
    wshobson-agents.url = "github:wshobson/agents";
    wshobson-agents.flake = false;
  };

  outputs =
    inputs@{
      nix-darwin,
      nix-homebrew,
      home-manager,
      nixpkgs,
      ...
    }:
    let
      # The one Mac this repo builds for. CI runs on macos-latest, which is
      # arm64, so changing this would leave update.yml without a builder.
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      darwinConfigurations.danavner = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
        ];
      };

      # What ./test.sh lints with, pinned by flake.lock so CI and this machine
      # agree. `nix develop --command
      # ./test.sh` skips nothing.
      devShells.${system}.default = pkgs.mkShellNoCC {
        # jq is what home/.claude/hooks/comment-audit.sh parses its payload with,
        # and test.sh skips those checks without it. macOS has shipped jq at
        # /usr/bin/jq since Sequoia and CI runners carry one, so the tests
        # pass either way - but neither is this flake's to promise.
        packages = [
          pkgs.shellcheck
          pkgs.actionlint
          pkgs.jq
          pkgs.nixfmt
          # The Python hooks' tests run the real tools when these are on PATH,
          # and skip those cases without them.
          pkgs.ruff
          pkgs.ty
        ];
      };

      # `nix fmt` to fix, `nixfmt --check` in test.sh to gate. nixfmt-tree
      # rather than nixfmt itself: bare nixfmt reads stdin when given no
      # arguments, so `nix fmt` with no path would format nothing and fail.
      formatter.${system} = pkgs.nixfmt-tree;
    };
}
