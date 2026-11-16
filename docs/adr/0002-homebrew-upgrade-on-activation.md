# Homebrew upgrades on every rebuild

`homebrew.onActivation.upgrade = true` sits beside a `brew update` step because the update only refreshes Homebrew's metadata: without `upgrade`, an installed cask stays at the version it landed on, which is how Claude Code's cask fell behind while nagging about a newer release. Rebuilds are slower for it.

## Consequences

- The cask is `claude-code@latest`, which tracks the npm release; plain `claude-code` is the stable channel and lags. The two conflict, so a hand-installed copy of the other fails activation before `zap` can remove it: uninstall it by hand.
- An installed version below npm usually means the cask has not published yet. Compare `brew info --cask claude-code@latest` with `npm view @anthropic-ai/claude-code version` before chasing it.
- `~/.claude.json` may report `installMethod: native` from an old hand-install under `~/.local/share/claude/versions`; PATH resolves to the cask binary, so those builds are dead weight.
- The update is a step of its own in `configuration.nix`, run as the user between nix-homebrew's prefix setup and `brew bundle`, and `onActivation.autoUpdate` is off. With auto-update on, `brew bundle` updates first and then re-runs nix-homebrew's `brew` wrapper, which resets PATH to a fixed list without `/opt/homebrew/bin`; bundle then cannot find `mas` and fails every `masApps` entry with `mas installation failed`. Once the wrapper keeps `HOMEBREW_PATH` on a re-run, the step can go and `autoUpdate` can come back. A failed update, such as offline, only warns.
