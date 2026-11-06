# Third-party skills are pinned flake inputs

Each third-party skill's source repo is a `flake = false` input in `flake.nix`, pinned by `flake.lock`. `home.nix` maps each skill name to its folder inside an input and links it into both `~/.claude/skills/<name>` and `~/.agents/skills/<name>`, the shared folder `npx skills` also wrote for other agents. The weekly `update.yml` bumps the inputs in a PR that runs the tests and a full build, so the skills stay current through review instead of never updating. `npx skills add` was retired: its installs were hand-run from a code block, missing on a fresh Mac, and four of six were behind upstream when this was decided.

Plugins that a marketplace ships are declared in `settings.base.json` instead (`extraKnownMarketplaces` with `"autoUpdate": true`, plus `enabledPlugins`), so Claude Code installs and updates them itself. obsidian is the one today.

## Consequences

- A skill's link name must equal the `name` in its `SKILL.md`. `test.sh` (full mode) checks every third-party link in both folders, for every configuration, so an upstream move or rename fails CI instead of leaving a dangling link.
- A new skill from an already-pinned repo is one line in `home.nix`; a new repo is also one input in `flake.nix` and `nix flake lock`.
- The skills are read-only store paths. A skill that writes into its own folder or installs hooks does not fit: impeccable stays on its own installer.
- Base wins on `enabledPlugins` entries it names, so a plugin disabled through `/plugin` comes back on the next rebuild. Disable it by removing it from the base file.
