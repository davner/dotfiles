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
- `flake.nix` exposes one `darwinConfigurations` entry per username in its `users` list, and `bootstrap.sh`/`rebuild.sh` select the one matching whoever runs them. Do not collapse this back to a single `user = "..."` value that a script rewrites in place: that swap dirtied `flake.nix` on every switch between the work and personal machine, and whichever value got committed broke activation on the other one. Entries are additive; adding a machine must not remove an existing username.
- `users.sh` is the only thing that parses that list, and it holds `flake.nix` to a shape: one quoted username per line, terminated by the `# end users` marker it appends above. Reformatting the list onto one line or dropping the marker breaks both scripts, which is why `test.sh` asserts the shape. `users.sh` also deliberately uses nothing but bash, sed and awk - `bootstrap.sh` calls it on a machine where nix was installed seconds ago and may not work yet.
- Dots in a username become dashes in its flake attribute (`dan.avner` -> `#dan-avner`). This is not cosmetic. `darwin-rebuild` splits its `--flake ...#attr` argument on `.` and then appends `.system`, so a literal dotted attribute is parsed as several path segments and can never resolve. Any code that maps a username to a flake attribute has to apply the same substitution.
- `home-manager.backupFileExtension = "backup"` in `flake.nix` is intentional. A pre-existing dotfile that this config also manages is moved aside instead of failing the activation, and nothing is overwritten in place. Do not reach for `force = true` on the file options instead: it silently destroys whatever was there. When activation reports that a `.backup` would itself be clobbered, an older backup is still on disk - read it and delete it.
- `CHANGELOG.md` is generated from the commit history by `git-cliff` using `cliff.toml`. Never hand-edit it, and never hand-write an entry into it. Regenerating it is not a manual edit: after committing a unit of work, run `nix develop --command git-cliff -o CHANGELOG.md` and commit the result. Because entries come straight from commit subjects, a vague subject line is a vague changelog entry - that is now a second reason to write them carefully.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.
- Subagents in `home/.claude/agents/` deliberately omit the `memory` frontmatter field. Enabling it auto-enables the Read, Write, and Edit tools, which would silently break the read-only boundary that `code-reviewer`, `architect`, and `ui-verifier` depend on. It also drops an `agent-memory/` directory into every repo they run in. Turn it on per-agent only for ones that can write anyway.
- Those agents also deliberately omit the `skills` frontmatter field, even where a skill is obviously relevant. Skills here are hand-installed with `npx skills add` and are absent on a fresh machine, so preloading one would make the agent depend on a step the Nix rebuild does not perform. The prompts invoke skills at runtime instead, which degrades gracefully.
- Agent prompts must stay stack-agnostic. These are user-level agents that load in every project, so they discover a repo's framework, test runner, and conventions rather than assuming a stack. They also must not restate the rules in `home/AGENTS.md`: that file is loaded into every custom subagent already.

## Maintaining this file

- Keep this file for knowledge useful to almost every future agent session in this project.
- Do not repeat what the codebase already shows; point to the authoritative file or command instead.
- Prefer rewriting or pruning existing entries over appending new ones.
- When updating this file, preserve this bar for all agents and keep entries concise.