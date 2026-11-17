# Troubleshooting

Error messages a setup or a rebuild can print, and how to fix each one.

| Message | Fix |
| --- | --- |
| `Existing file '…' would be clobbered` | An older `.backup` is still there: read it, then delete it ([ADR 0006](adr/0006-home-manager-backups.md)) |
| `Unable to install <app> app. mas installation failed.` | `brew bundle` auto-updated and lost PATH, so it cannot find `mas`. Keep `onActivation.autoUpdate` off; the update runs as its own step ([ADR 0002](adr/0002-homebrew-upgrade-on-activation.md)) |
| `nix: command not found` during bootstrap | Open a new terminal, then re-run |
| WezTerm says it cannot load `Hack Nerd Font` | Log out and back in: macOS scans `~/Library/Fonts/HomeManager` only at the start of a session, and bootstrap created it mid-session |
| A rebuild made things worse | `darwin-rebuild --list-generations`, then `sudo darwin-rebuild --switch-to-generation N` |
