# Troubleshooting

Error messages a setup or a rebuild can print, and how to fix each one.

| Message | Fix |
| --- | --- |
| `primary user 'X' does not exist` | You built another machine's config: run `./rebuild.sh` with no `--user` |
| `flake.nix has no configuration for "X"` | Run `./bootstrap.sh`, which offers to add the username |
| `home.nix: no git email for "X"` | Fill in `email` on that record in `flake.nix` |
| `Existing file '…' would be clobbered` | An older `.backup` is still there: read it, then delete it ([ADR 0006](adr/0006-home-manager-backups.md)) |
| `nix: command not found` during bootstrap | Open a new terminal, then re-run |
| WezTerm says it cannot load `Hack Nerd Font` | Log out and back in: macOS scans `~/Library/Fonts/HomeManager` only at the start of a session, and bootstrap created it mid-session |
| A rebuild made things worse | `darwin-rebuild --list-generations`, then `sudo darwin-rebuild --switch-to-generation N` |

On a Mac set up before the third-party skills became flake inputs, the first
rebuild can stop on `Existing file ... would be clobbered` for a skill. Clear
the old copies as [Installing the skills](../AGENTS.md#installing-the-skills)
shows, then rebuild.

## The changelog

`CHANGELOG.md` is generated from commit subjects on `main`
([ADR 0008](adr/0008-changelog-generated-by-git-cliff.md)). To rebuild it by
hand:

```sh
nix develop --command git-cliff -o CHANGELOG.md
```
