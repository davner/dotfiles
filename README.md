# dotfiles

[nix-darwin](https://github.com/nix-darwin/nix-darwin) +
[home-manager](https://github.com/nix-community/home-manager) configuration for
my Macs: macOS settings, Homebrew casks, CLI packages, zsh, and the dotfiles
themselves.

One branch serves every machine. The configuration is keyed by macOS username,
so moving between the work Mac and the personal one needs no edit and leaves
nothing to undo.

## Commands

| Command | When | sudo |
| --- | --- | --- |
| `./bootstrap.sh` | Once, on a Mac that has never run this | yes |
| `./rebuild.sh` | After any change to this repo | yes |
| `./rebuild.sh --build` | To check a change builds, and preview what it would change | no |
| `./test.sh` | Before committing | no |
| `nix develop --command git-cliff -o CHANGELOG.md` | After committing, to refresh the changelog | no |

Both build scripts default to whoever runs them. `--user NAME` builds someone
else's configuration; `--help` on either prints its options.

A switch prints what it changed, and `--build` prints what a switch *would*
change, as a closure diff:

```
this rebuild changed:
shellcheck: 0.11.0 added, 58.5 MiB
neovim: 0.11.2 -> 0.11.4
```

## Usernames

`flake.nix` lists the usernames it can build for, one configuration each.
`./users.sh list` prints them. On a Mac whose username is not listed,
`./bootstrap.sh` offers to add it - an addition, so the other machines keep
working.

| macOS username | Flake attribute | git commits as |
| --- | --- | --- |
| `danavner` | `#danavner` | `ldpavner@gmail.com` |
| `dan.avner` | `#dan-avner` | `dan.avner@noirlab.edu` |

The name on a commit is `Dan Avner` either way; only the address follows the
machine. `home.nix` holds the mapping, and a username missing from it fails the
build rather than quietly committing from the wrong address - so adding a Mac
is two edits: the username list, which `./bootstrap.sh` offers, and the address
in `home.nix`.

Dots become dashes in the attribute name. That is not cosmetic:
`darwin-rebuild` splits its `--flake …#attr` argument on `.`, so a literal
dotted attribute can never resolve. The scripts handle the substitution.

## Layout

| Path | Owns |
| --- | --- |
| `flake.nix` | Pinned inputs, the username list, one configuration per user, the dev shell |
| `configuration.nix` | System scope: macOS defaults, Homebrew, the primary user |
| `home.nix` | User scope: packages, zsh, starship, git, gh, and which dotfiles get linked |
| `home/` | The real dotfiles, symlinked into `$HOME` so they stay editable in place |
| `home/AGENTS.md` | Global coding-agent instructions, linked to `~/.claude/CLAUDE.md` and friends |
| `AGENTS.md` | Notes for agents working *on this repo*. A different file from the one above |
| `users.sh` | The only thing that parses the username list |
| `test.sh` | The checks below |
| `cliff.toml` | How `CHANGELOG.md` is generated |

Dotfiles under `home/` are linked, not copied: editing
`~/.config/wezterm/wezterm.lua` edits the file in this repo, with no rebuild in
between.

## Tests

| Command | Runs |
| --- | --- |
| `./test.sh` | Everything, including the flake evaluations |
| `./test.sh --fast` | Shell-level checks only, a few seconds |
| `nix develop --command ./test.sh` | Everything, plus shellcheck and actionlint |

No sudo, no rebuild, and no writes outside a temp directory: the build scripts
run against a stub `sudo` and a throwaway `$HOME`, so what they *would* have run
is asserted rather than executed. Run bare, `./test.sh` skips whichever linter is
not on `PATH`; the dev shell supplies both at the versions `flake.lock` pins.

## CI

| Workflow | Trigger | Runs |
| --- | --- | --- |
| `test.yml` | Every push and PR | `./test.sh --fast`, shellcheck, actionlint |
| `weekly.yml` | Mondays 14:00 UTC, or on demand | Full `./test.sh`, `nix flake check`, a real build of every configuration, and a changelog freshness check |
| `update.yml` | Mondays 15:00 UTC, or on demand | `nix flake update`, then opens a PR if the inputs moved and everything still builds |

The weekly build is what notices a package disappearing out from under a locked
input, which no amount of shell testing can see. Activation is the one thing CI
cannot check: it needs a Mac with these usernames on it.

## Troubleshooting

| Message | Meaning | Fix |
| --- | --- | --- |
| `primary user 'X' does not exist, aborting activation` | Building another machine's configuration | `./rebuild.sh` with no `--user` |
| `flake.nix has no configuration for "X"` | This Mac's username is not in the list | `./bootstrap.sh`, which offers to add it |
| `Existing file '…' would be clobbered` | A real dotfile sits where a managed one goes | Normally handled: it is moved to `….backup`. If the message names a `.backup`, an older one is still there - read it, then delete it |
| `nix: command not found` under sudo, during bootstrap | sudo resets `PATH` to a secure default | Open a new terminal so Determinate can put nix on `PATH`, then re-run |
| `$HOME … is not owned by you, falling back to '/var/root'` | nix running under sudo | Harmless |
| `Git tree … has uncommitted changes` | Building from a dirty checkout | Harmless, and correct: the build uses the working tree, not the last commit |
| A rebuild made things worse | | `darwin-rebuild --list-generations`, then `sudo darwin-rebuild --switch-to-generation N` |

## Changelog

[`CHANGELOG.md`](CHANGELOG.md) is generated from the commit history by
[git-cliff](https://git-cliff.org) and is never edited by hand. Commits follow
[Conventional Commits](https://www.conventionalcommits.org), which is what makes
the grouping work; a commit message written carelessly is a changelog entry
written carelessly.
