# Project notes for agents

Run `./test.sh` before proposing a commit. It needs no sudo and touches nothing
outside a temp directory, so there is no reason to skip it. `--fast` drops the
flake evaluations when only the shell scripts changed, and `nix develop
--command ./test.sh` adds shellcheck and actionlint - run it that way when you
touched a shell script or a workflow, since bare it silently skips both.

`.github/workflows/test.yml` runs the fast half on every push; `weekly.yml`
runs the full suite plus a real `nix build` of every configuration on Mondays.
Anything slow belongs in weekly.yml, not in the push path.

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "zap"` in `configuration.nix` is intentional. It forces the good habit of declaring every Homebrew package in the Nix config instead of installing things ad-hoc, which keeps the machine reproducible. Do not soften it to `uninstall` or `none`.
- `homebrew.onActivation.upgrade = true` alongside it is also intentional, and the pair is easy to get wrong. `autoUpdate` only refreshes Homebrew's metadata; without `upgrade`, an already-installed cask is left at whatever version it landed on and a rebuild never moves it. That is how the `claude-code` cask sat at an old version while Claude Code nagged about a newer one on every launch. Do not drop it because rebuilds got slower.
- `flake.nix` exposes one `darwinConfigurations` entry per username in its `users` attrset, and `bootstrap.sh`/`rebuild.sh` select the one matching whoever runs them. Do not collapse this back to a single `user = "..."` value that a script rewrites in place: that swap dirtied `flake.nix` on every switch between the work and personal machine, and whichever value got committed broke activation on the other one. Entries are additive; adding a machine must not remove an existing username. Each username maps to a record of what differs per machine - the git address and the platform - so a new Mac is one edit in one file rather than a username here and an address somewhere else.
- `users.sh` is the only thing that parses that attrset, and it holds `flake.nix` to a shape: one quoted username per line, each opening an attrset record, terminated by the `# end users` marker it appends above. Reformatting the attrset onto one line or dropping the marker breaks both scripts, which is why `test.sh` asserts the shape. `users.sh add` writes an empty record, since it runs before nix is known to work and cannot fill one in; every field it leaves out has to stay optional at the point it is read, which is why `configuration.nix` defaults `hostPlatform` rather than indexing `cfg.system` directly. Without that default the missing-email error is replaced by a module-system stack trace, and the trace is what a fresh Mac would see. `users.sh` also deliberately uses nothing but bash, sed and awk - `bootstrap.sh` calls it on a machine where nix was installed seconds ago and may not work yet.
- Dots in a username become dashes in its flake attribute (`dan.avner` -> `#dan-avner`). This is not cosmetic. `darwin-rebuild` splits its `--flake ...#attr` argument on `.` and then appends `.system`, so a literal dotted attribute is parsed as several path segments and can never resolve. Any code that maps a username to a flake attribute has to apply the same substitution.
- `home-manager.backupFileExtension = "backup"` in `flake.nix` is intentional. A pre-existing dotfile that this config also manages is moved aside instead of failing the activation, and nothing is overwritten in place. Do not reach for `force = true` on the file options instead: it silently destroys whatever was there. When activation reports that a `.backup` would itself be clobbered, an older backup is still on disk - read it and delete it.
- `home/.claude/settings.json` is tracked and its changes always get committed. `~/.claude/settings.json` is a `mkOutOfStoreSymlink` back into this working tree, so changing the model, effort level, or theme with `/config` writes straight into the repo and dirties it mid-session. That is expected, not an accident - commit the change rather than reverting it, because this file is where a fresh Mac gets its model, statusline, hooks, and `skipDangerousModePermissionPrompt`. Do not try to split the volatile keys out into a user-level `settings.local.json`: no such file exists. Claude Code reads `settings.local.json` at the project level only, and the user tier is `~/.claude/settings.json` and nothing else.
- `CHANGELOG.md` is generated from the commit history by `git-cliff` using `cliff.toml`. Never hand-edit it, and never hand-write an entry into it. Do not regenerate it as part of a change either: `changelog.yml` does that on every push to `main`, so a regenerated file in a feature branch only creates a conflict with the bot commit. Because entries come straight from commit subjects, a vague subject line is a vague changelog entry - that is now a second reason to write them carefully. The commit it pushes also lands on `origin/main` while your own work is still unpushed, so a plain `git pull` records a merge whose entire content is a changelog regeneration. Pull with `git pull --rebase`, or `--ff-only` and rebase by hand, so `Merge remote-tracking branch 'origin/main'` never enters the history for this.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.
- Skills written in this repo live in `home/.claude/skills/<name>/` and are linked into `~/.claude/skills/` **one entry per skill**, never as the whole `skills/` directory. That directory also holds the hand-installed third-party skills, and a directory-level symlink would displace all of them. Adding a skill is therefore a new `home.file.".claude/skills/<name>"` line in `home.nix`; `test.sh` derives its symlink-target checks from that file by sed, so a typo becomes a failing test rather than a dangling link. This is the only category of skill the rebuild manages - the `npx skills add` ones are still hand-installed, per "Installing the skills" below.
- Subagents in `home/.claude/agents/` deliberately omit the `memory` frontmatter field. Enabling it auto-enables the Read, Write, and Edit tools, which would silently break the read-only boundary that every agent carrying `disallowedTools: Write, Edit, NotebookEdit` depends on - eight of the thirteen, as of writing. Do not re-enumerate them here; the list has already gone stale once. It also drops an `agent-memory/` directory into every repo they run in. Turn it on per-agent only for ones that can write anyway.
- Those agents also deliberately omit the `skills` frontmatter field, even where a skill is obviously relevant. Skills here are hand-installed with `npx skills add` and are absent on a fresh machine, so preloading one would make the agent depend on a step the Nix rebuild does not perform. The prompts invoke skills at runtime instead, which degrades gracefully.
- Agent prompts must stay stack-agnostic. These are user-level agents that load in every project, so they discover a repo's framework, test runner, and conventions rather than assuming a stack. They also must not restate the rules in `home/AGENTS.md`: that file is loaded into every custom subagent already.

## Installing the skills

`home/AGENTS.md` names the skills every machine should have and points here for
the install steps, so this section is read on demand from any project - keep the
heading name stable. The third-party skills are not managed by `home.nix`; a
rebuild neither installs nor removes them. Every one but `impeccable` is
installed with `npx skills add`, which writes to `~/.agents/skills/` and symlinks
into `~/.claude/skills/`. `impeccable` has its own installer and lands as a real
directory under `~/.claude/skills/` with no `~/.agents/` entry at all, so check
both locations before deciding a skill is missing. On a fresh machine:

```sh
npx skills add shadcn-ui/ui -g -y -s shadcn -s migrate-radix-to-base
npx skills add blader/humanizer -g -y -s humanizer
npx skills add kunchenguid/chrome-devtools-axi -g -y -s chrome-devtools-axi
npx skills add kunchenguid/gh-axi -g -y -s gh-axi
npx skills add kunchenguid/lavish-axi -g -y -s lavish
npx impeccable install   # when prompted for location, choose "global"
```

`-s` does not take a comma-separated list; repeat the flag per skill. Ignore the
`PromptScript does not support global skill installation` warnings, which come
from an unrelated agent target. `npx skills update -g` upgrades everything but
`impeccable`; that one upgrades with `npx impeccable update`, and `npx
impeccable check` says whether you are behind.

## Maintaining this file

- Keep this file for knowledge useful to almost every future agent session in this project.
- Do not repeat what the codebase already shows; point to the authoritative file or command instead.
- Prefer rewriting or pruning existing entries over appending new ones.
- When updating this file, preserve this bar for all agents and keep entries concise.