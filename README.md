<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/banner-dark.svg">
  <img src="docs/assets/banner-light.svg" alt="dotfiles: nix-darwin, home-manager and Claude Code for my Mac" width="100%">
</picture>

One repo sets up my personal Mac: macOS settings, Homebrew apps, CLI tools,
zsh, and a Claude Code setup of global rules, skills and hooks. It runs on
[nix-darwin](https://github.com/nix-darwin/nix-darwin) and
[home-manager](https://github.com/nix-community/home-manager), and builds one
configuration, `#danavner`.

This is my personal setup. Copy whatever helps, but I do not take
contributions.

## Set up the Mac

```sh
git clone https://github.com/davner/dotfiles.git
cd dotfiles
./bootstrap.sh
```

On a Mac without git, the clone first asks you to install the Xcode Command
Line Tools.

| Command | When | sudo |
| --- | --- | --- |
| `./bootstrap.sh` | Once, on a fresh install | yes |
| `./rebuild.sh` | After changing this repo | yes |
| `./rebuild.sh --build` | Check a change builds, without applying it | no |
| `./test.sh` | Before committing | no |

## What you get

| Part | What it brings |
| --- | --- |
| Apps and tools | WezTerm, Claude Code, and CLI tools such as ripgrep, fd, fzf, jq, lazygit, neovim and uv |
| Shell | zsh with a starship prompt, direnv, and short aliases such as `add`, `m` and `cc` |
| macOS settings | Dark mode, a Dock that hides, Finder in column view, fast key repeat and hot corners |
| Claude Code | Skills for a workflow from idea to merged work, and [hooks](#hooks) that guard git and check the code Claude writes |

Every package, app and setting is listed in [What you get](docs/installed.md).

## Hooks

Hooks run on their own, in every repo, once the Mac is set up.

| Hook | When | What it does | Turn it off in one repo |
| --- | --- | --- | --- |
| `guard-bash.sh` | Before every shell command | Blocks risky git, a push or PR the repo has not allowed, and commit messages that credit an AI | No per-repo switch. To allow more: `cc-push on` for a plain push, `git config --local claude.allowPrs true` for PRs, and `git config --local claude.allowForcePush true` plus `cc-push on` for `--force-with-lease` |
| `skill-gate.sh` | Before Skill, Write, Edit, MultiEdit and Bash | Blocks a TypeScript write until the agent has loaded `typescript-style-guide` | No per-repo switch |
| `comment-audit.sh` | After every file write | Flags code comments that tell history or refer to the session | No per-repo switch |
| `ruff-after-edit.sh` | After a write to a `.py` or `.pyi` file | Runs `ruff check --fix`, then `ruff format`, on that file, and reports the lint errors left | `git config --local claude.ruff false` |
| `python-stop-check.sh` | When Claude stops | Checks the changed Python files with ruff and ty without changing them, and flags a blanket `# noqa` or `# type: ignore` | `git config --local claude.ruff false` and `git config --local claude.ty false` |
| `session-name.sh` | Session start | Names the session after its repo | No per-repo switch |
| impeccable's `hook` | Session start, after Edit or Write, and on stop | Checks UI files for design anti-patterns | `/impeccable hooks off` (writes `.impeccable/config.json`; keep it out of commits in a shared repo) |
| `statusline.sh` (status line) | Always | Shows model, context used and rate limits | No per-repo switch |

The two Python hooks run only where the repo configures the tool. Ruff counts
`ruff.toml`, `.ruff.toml` or a `[tool.ruff]` table in `pyproject.toml`; ty
counts `ty.toml` or `[tool.ty]`. To turn one on in a repo without config, set
it to `true`, for example `git config --local claude.ruff true`. `claude.ruff`
covers both hooks. Each hook uses the repo's `.venv` first, then `PATH`, then
`uvx`, and does nothing when it finds none.

[Claude Code setup](docs/claude-code.md#hooks) has the details of each hook.

## How it fits together

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/architecture-dark.svg">
  <img src="docs/assets/architecture-light.svg" alt="This repo's flake.nix, configuration.nix, home.nix and home/ folder feed nix-darwin, Homebrew and home-manager, which write macOS settings, Homebrew apps, files in $HOME and ~/.claude" width="100%">
</picture>

Files under `home/` are linked into `$HOME`, so an edit to one takes effect at
once. Adding or removing a linked file needs `./rebuild.sh`.

## Everyday commands

| Command | What it does |
| --- | --- |
| `cc` | Starts Claude Code with permission prompts skipped and remote control on, the session named after the repo |
| `cc-flow` | Prints the Claude workflow as a table: which skill to run at each step |
| `cc-push` | Lets agents run a plain `git push` in this repo, or stops them |
| `./test.sh --fast` | Runs the tests without the Nix evaluations |

## Docs

- [The Claude workflow](docs/workflow.md): from an idea to merged work, one
  skill per step, or `/autopilot` with nobody watching.
- [Claude Code setup](docs/claude-code.md): every skill, hook and rule.
- [What you get](docs/installed.md): packages, apps, shell setup and macOS
  settings.
- [Troubleshooting](docs/troubleshooting.md): error messages and their fixes.
- [All docs](docs/README.md): the index, with the repo layout, tests and CI,
  and every decision record.

Notes for agents working on this repo are in [AGENTS.md](AGENTS.md), including
[how the skills get installed](AGENTS.md#installing-the-skills).
