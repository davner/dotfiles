# Homebrew upgrades on every rebuild

`homebrew.onActivation.upgrade = true` sits beside `autoUpdate` because `autoUpdate` only refreshes Homebrew's metadata: without `upgrade`, an installed cask stays at the version it landed on, which is how Claude Code's cask fell behind while nagging about a newer release. Rebuilds are slower for it.

## Consequences

- The cask is `claude-code@latest`, which tracks the npm release; plain `claude-code` is the stable channel and lags. The two conflict, so a hand-installed copy of the other fails activation before `zap` can remove it: uninstall it by hand.
- An installed version below npm usually means the cask has not published yet. Compare `brew info --cask claude-code@latest` with `npm view @anthropic-ai/claude-code version` before chasing it.
- `~/.claude.json` may report `installMethod: native` from an old hand-install under `~/.local/share/claude/versions`; PATH resolves to the cask binary, so those builds are dead weight.
