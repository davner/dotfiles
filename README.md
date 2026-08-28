# dotfiles

[nix-darwin](https://github.com/nix-darwin/nix-darwin) +
[home-manager](https://github.com/nix-community/home-manager) configuration for
my Macs: macOS settings, Homebrew casks, CLI packages, zsh, and the dotfiles
themselves.

One branch serves every machine. The configuration is keyed by macOS username,
so moving between the work Mac and the personal one needs no edit and leaves
nothing to undo.

## Commands

Start here: clone anywhere and run bootstrap. The clone's location never
matters, because bootstrap symlinks the checkout to `~/.dotfiles` itself. On a
Mac fresh enough to lack git, the clone is the first `git` command macOS sees
and it prompts to install the Xcode Command Line Tools; accept, then clone.

```sh
git clone https://github.com/davner/dotfiles.git
cd dotfiles
./bootstrap.sh
```

| Command | When | sudo |
| --- | --- | --- |
| `./bootstrap.sh` | Once, on a Mac that has never run this | yes |
| `./rebuild.sh` | After any change to this repo | yes |
| `./rebuild.sh --build` | To check a change builds, and preview what it would change | no |
| `./test.sh` | Before committing | no |

`bootstrap.sh` and `rebuild.sh` default to whoever runs them, and both take:

| Flag | Does |
| --- | --- |
| `--user NAME` | Build NAME's configuration instead of the current user's |
| `--help` | Print the script's options |

`test.sh` takes only `--fast`, covered under [Tests](#tests).

A switch prints what it changed, and `--build` prints what a switch *would*
change, as a closure diff:

```
this rebuild changed:
shellcheck: 0.11.0 added, 58.5 MiB
neovim: 0.11.2 -> 0.11.4
```

## Usernames

`flake.nix` maps each macOS username it can build for to what differs on that
machine, one configuration each. `./users.sh list` prints them. On a Mac whose
username is not listed, `./bootstrap.sh` offers to add it - an addition, so the
other machines keep working.

| macOS username | Flake attribute | git commits as | system |
| --- | --- | --- | --- |
| `danavner` | `#danavner` | `ldpavner@gmail.com` | `aarch64-darwin` |
| `dan.avner` | `#dan-avner` | `dan.avner@noirlab.edu` | `aarch64-darwin` |

The name on a commit is `Dan Avner` either way; only the address follows the
machine. Adding a Mac is one edit, in `flake.nix`, and `./bootstrap.sh` makes
it for you - it appends the username with an empty record. Fill in the address
before the first rebuild: a record without one fails the build rather than
quietly committing from the wrong one.

Forking this? The same mechanism adopts you: `./bootstrap.sh` offers to add
your username, and the build then stops until you fill in `email` on your
record in `flake.nix`. Change `user.name` in `home.nix` too, or your commits
will say Dan Avner. After that it is pruning: the packages in `home.nix` and
the casks in `configuration.nix` are one person's taste.

Dots become dashes in the attribute name. That is not cosmetic:
`darwin-rebuild` splits its `--flake …#attr` argument on `.`, so a literal
dotted attribute can never resolve. The scripts handle the substitution.

## Layout

| Path | Owns |
| --- | --- |
| `flake.nix` | Pinned inputs, the per-user records, one configuration per user, the dev shell |
| `configuration.nix` | System scope: macOS defaults, Homebrew, the primary user |
| `home.nix` | User scope: packages, zsh, starship, git, gh, and which dotfiles get linked |
| `home/` | The real dotfiles, symlinked into `$HOME` so they stay editable in place |
| `home/AGENTS.md` | Global coding-agent instructions, linked to `~/.claude/CLAUDE.md` and friends |
| `home/.claude/agents/` | The subagent roster, one file per agent; linked to `~/.claude/agents/`, where Claude Code picks them up by name |
| `AGENTS.md` | Notes for agents working *on this repo*. A different file from the one above |
| `home/.claude/*.sh` | Statusline, session naming, and the comment-audit hook |
| `users.sh` | The only thing that parses the per-user records |
| `test.sh` | The checks below |
| `cliff.toml` | How `CHANGELOG.md` is generated |

Dotfiles under `home/` are linked, not copied: editing
`~/.config/wezterm/wezterm.lua` edits the file in this repo, with no rebuild in
between.

## Agents

`home/.claude/agents/` is a roster of subagents, one file each, that Claude Code
picks up by name. Most cannot edit files: they report findings, and a writer
applies them. They run in every project, not just this one.

| Agent | Does | Edits files |
| --- | --- | --- |
| `architect` | Designs a change before code exists: files, contracts, rejected options | no |
| `plan-reviewer` | Checks that plan against the actual codebase | no |
| `senior-dev` | Primary writer. Builds features, applies every reviewer's fixes | yes |
| `test-writer` | Writes tests in whatever framework the project already uses | yes |
| `debugger` | Reproduces a failure first, then fixes the cause | yes |
| `docs-writer` | Makes docs match the code, running every example it touches | yes |
| `code-reviewer` | Correctness bugs, error paths, drift from the repo's conventions | no |
| `migration-safety` | Runs a migration forward and back before it meets real data | no |
| `ui-verifier` | Loads the app in a real browser and reports what renders | no |
| `a11y-auditor` | Audits a running UI against WCAG, by keyboard and screen reader | no |
| `review-triage` | Turns an external PR review into a plan, checking each claim | no |
| `doc-auditor` | Finds plans, TODOs and READMEs that stopped being true | no |
| `fresh-eyes` | Uses the product cold and scores how far a stranger gets | no |
| `researcher` | Answers what the repo cannot, with citations | no |
| `git-workflow` | Staging, commit messages, branches. Git only, never code | no |

Two things shape how they behave. `home/AGENTS.md` is loaded into all of them,
so the guardrails there apply everywhere and no agent file repeats them. And
`comment-audit.sh` runs as a hook after every write, flagging comments that
narrate the edit history instead of the reason.

Works without nix: copy `home/.claude/agents/` to `~/.claude/agents/`. Before
editing the files, read the bullets in the root `AGENTS.md` on why their
`memory` and `skills` frontmatter fields are deliberately absent.

## Tests

| Command | Runs |
| --- | --- |
| `./test.sh` | Everything, including the flake evaluations |
| `./test.sh --fast` | Shell-level checks only, a few seconds |
| `nix develop --command ./test.sh` | Everything, plus shellcheck, actionlint and git-cliff |

No sudo, no rebuild, and no writes outside a temp directory: the build scripts
run against a stub `sudo` and a throwaway `$HOME`, so what they *would* have run
is asserted rather than executed. Run bare, `./test.sh` skips whichever linter is
not on `PATH`; the dev shell supplies all three at the versions `flake.lock` pins.

## CI

| Workflow | Trigger | Runs |
| --- | --- | --- |
| `test.yml` | Every push and PR | `./test.sh --fast` in the dev shell, so shellcheck, actionlint and git-cliff all run |
| `changelog.yml` | Every push to `main` | Regenerates `CHANGELOG.md` and commits it if it moved |
| `weekly.yml` | Mondays 14:00 UTC, or on demand | Full `./test.sh`, `nix flake check`, and a real build of every configuration |
| `update.yml` | Mondays 15:00 UTC, or on demand | `nix flake update`, then opens a PR if the inputs moved and everything still builds |

The weekly build is what notices a package disappearing out from under a locked
input, which no amount of shell testing can see. Activation is the one thing CI
cannot check: it needs a Mac with these usernames on it.

## Troubleshooting

| Message | Meaning | Fix |
| --- | --- | --- |
| `primary user 'X' does not exist, aborting activation` | Building another machine's configuration | `./rebuild.sh` with no `--user` |
| `flake.nix has no configuration for "X"` | This Mac's username has no record in `flake.nix` | `./bootstrap.sh`, which offers to add it |
| `home.nix: no git email for "X"` | `./bootstrap.sh` added the username but cannot know the address | Fill in `email` on that user's record in `flake.nix` |
| `Existing file '…' would be clobbered` | A real dotfile sits where a managed one goes | Normally handled: it is moved to `….backup`. If the message names a `.backup`, an older one is still there - read it, then delete it |
| `nix: command not found` under sudo, during bootstrap | sudo resets `PATH` to a secure default | Open a new terminal so Determinate can put nix on `PATH`, then re-run |
| `$HOME … is not owned by you, falling back to '/var/root'` | nix running under sudo | Harmless |
| `Git tree … has uncommitted changes` | Building from a dirty checkout | Harmless, and correct: the build uses the working tree, not the last commit |
| A rebuild made things worse | | `darwin-rebuild --list-generations`, then `sudo darwin-rebuild --switch-to-generation N` |

## Changelog

[`CHANGELOG.md`](CHANGELOG.md) is generated from the commit history by
[git-cliff](https://git-cliff.org) and is never edited by hand. It is grouped by
the day each change landed rather than by release, because this repo has no
releases to group by. `changelog.yml`
regenerates it on every push to `main` and commits it back, so there is nothing
to remember - which does mean a `git pull` before the next session, because
that bot commit lands on `main`.

It cannot be a local hook: git-cliff reads committed history, so at
pre-commit time the commit being written does not exist yet and the changelog
would always be one commit behind.

To regenerate by hand anyway:

```sh
nix develop --command git-cliff -o CHANGELOG.md
```

Entries are commit subjects verbatim, and commits follow
[Conventional Commits](https://www.conventionalcommits.org), which is what makes
the grouping work. A carelessly written subject line is a carelessly written
public changelog entry.
