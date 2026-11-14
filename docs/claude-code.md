# Claude Code setup

Every skill, hook and rule this repo installs for Claude Code, with what each one does.

The settings that tell Claude Code when to run them are merged from [`settings.base.json`](../home/.claude/settings.base.json) on every rebuild ([ADR 0007](adr/0007-claude-settings-merge-not-link.md)).

## Skills

Each folder under [`home/.claude/skills/`](../home/.claude/skills/) is linked into `~/.claude/skills/` on its own. `./test.sh` fails when a folder has no row here, or a row has no folder.

| Stage | Skill | What it does |
| --- | --- | --- |
| Setup | [`setup-dan-skills`](../home/.claude/skills/setup-dan-skills/SKILL.md) | Configures a repo once: tracker (GitHub, Shortcut or Jira) and where docs go |
| Align | [`grill-me`](../home/.claude/skills/grill-me/SKILL.md) | Interviews you until a plan has no open questions |
| Align | [`grill-with-docs`](../home/.claude/skills/grill-with-docs/SKILL.md) | The same, recording the glossary and ADRs as it goes |
| Align | [`grilling`](../home/.claude/skills/grilling/SKILL.md) | The interview engine behind both |
| Design | [`prototype`](../home/.claude/skills/prototype/SKILL.md) | Throwaway variants to answer "what should this look like?" |
| Design | [`domain-modeling`](../home/.claude/skills/domain-modeling/SKILL.md) | Keeps the glossary and ADRs |
| Design | [`codebase-design`](../home/.claude/skills/codebase-design/SKILL.md) | Vocabulary for small interfaces over deep modules |
| Design | [`improve-codebase-architecture`](../home/.claude/skills/improve-codebase-architecture/SKILL.md) | Finds modules worth simplifying, as a visual report |
| Design | [`making-clipart-gifs`](../home/.claude/skills/making-clipart-gifs/SKILL.md) | Original 90s 3D clip-art GIFs: render, shrink to 200 px, check against measured specs |
| Plan | [`to-spec`](../home/.claude/skills/to-spec/SKILL.md) | Writes the spec, paste-ready |
| Plan | [`to-tickets`](../home/.claude/skills/to-tickets/SKILL.md) | Splits it into thin tickets with their order, paste-ready or filed as GitHub issues |
| Build | [`autopilot`](../home/.claude/skills/autopilot/SKILL.md) | Runs the whole flow, idea or board item to reviewed code, with nobody watching |
| Build | [`implement`](../home/.claude/skills/implement/SKILL.md) | Builds one ticket or a small change |
| Build | [`implement-spec`](../home/.claude/skills/implement-spec/SKILL.md) | Builds a whole spec, tickets in parallel |
| Build | [`tdd`](../home/.claude/skills/tdd/SKILL.md) | Test first, one slice at a time |
| Build | [`diagnosing-bugs`](../home/.claude/skills/diagnosing-bugs/SKILL.md) | Reproduce, narrow down, fix, and guard a hard bug |
| Review | [`code-review`](../home/.claude/skills/code-review/SKILL.md) | Standards and spec, checked separately |
| Review | [`pr`](../home/.claude/skills/pr/SKILL.md) | Writes the PR title and body with the ticket ID, plus before/after screenshots to drag in and proof that no AI is credited, on a Copy page; you open the PR |
| Review | [`retro`](../home/.claude/skills/retro/SKILL.md) | What to change in the setup after a session |
| Help | [`handoff`](../home/.claude/skills/handoff/SKILL.md) | Writes a summary so a fresh session can pick up the work |
| Help | [`research`](../home/.claude/skills/research/SKILL.md) | Answers a question from primary sources, saved as markdown |
| Help | [`teach`](../home/.claude/skills/teach/SKILL.md) | Teaches a concept over several sessions |
| Help | [`writing-for-agents`](../home/.claude/skills/writing-for-agents/SKILL.md) | How to write skills and agent rules files |
| Stack | [`primereact-v10`](../home/.claude/skills/primereact-v10/SKILL.md) | PrimeReact v10 reference |
| Stack | [`tailwind-v4`](../home/.claude/skills/tailwind-v4/SKILL.md) | Tailwind CSS v4 reference |

`vault-*` skills and `synced` may also sit in `~/.claude/skills/` on a work Mac. They come from the private work layer, `~/.dotfiles-work`, and its own rebuild, so they are not listed here.

## Third-party skills

These are pinned in `flake.lock`, linked into both `~/.claude/skills/` and `~/.agents/skills/`, and bumped by the weekly update PR ([ADR 0009](adr/0009-third-party-skills-are-pinned-flake-inputs.md)).

| Skill | From | What it does |
| --- | --- | --- |
| `gh-axi` | [kunchenguid/gh-axi](https://github.com/kunchenguid/gh-axi) | GitHub through the `gh-axi` CLI |
| `chrome-devtools-axi` | [kunchenguid/chrome-devtools-axi](https://github.com/kunchenguid/chrome-devtools-axi) | Drives a real Chrome |
| `lavish` | [kunchenguid/lavish-axi](https://github.com/kunchenguid/lavish-axi) | Turns a response into an HTML page you can annotate |
| `humanizer` | [blader/humanizer](https://github.com/blader/humanizer) | Rewrites AI-sounding prose |
| `shadcn`, `migrate-radix-to-base` | [shadcn-ui/ui](https://github.com/shadcn-ui/ui) | shadcn/ui components; Radix to Base UI migration |
| `typescript-style-guide` | [mkosir/typescript-style-guide](https://github.com/mkosir/typescript-style-guide) | TypeScript conventions |
| `modern-python` | [trailofbits/skills](https://github.com/trailofbits/skills) | Python project tooling: uv, ruff, ty, PEP 723 scripts |
| `python-anti-patterns` | [wshobson/agents](https://github.com/wshobson/agents) | A checklist of Python mistakes to catch before finishing a change |

License notices for these are in [`THIRD-PARTY-NOTICES.md`](../home/.claude/skills/THIRD-PARTY-NOTICES.md).

## impeccable

`impeccable` is the one skill no flake input can carry. It downloads an engine and writes agents, and a read-only Nix store path cannot hold either. So every rebuild runs [`local-skills.sh`](../home/.claude/local-skills.sh), which installs it into both skill folders when it is missing. Its hooks are in `settings.base.json` (see the table below). [Installing the skills](../AGENTS.md#installing-the-skills) in `AGENTS.md` covers updating it and clearing old copies.

## Hooks

Every file in [`home/.claude/hooks/`](../home/.claude/hooks/) is linked into `~/.claude/hooks/` on its own. `settings.base.json` says when each one runs.

| When | Script | Does |
| --- | --- | --- |
| Before every shell command | `guard-bash.sh` | Blocks risky git (`add .`, `reset --hard`, `clean -f`, `branch -D`, `checkout .`, force push, plain push unless the repo opted in with `cc-push on`), opening or merging a PR with `gh` or `gh-axi` unless the repo opted in with `git config claude.allowPrs true`, and commit messages that credit an AI or break the one-line shape |
| Before Skill, Write, Edit, MultiEdit and Bash | `skill-gate.sh` | Blocks a write to a TypeScript file until that agent has loaded `typescript-style-guide`; the rule `~/.claude/rules/typescript.md` asks for the skill as soon as a TypeScript file is read. It misses `touch`, `dd of=`, writes from inside python or node, and `cp a.ts dir` without a trailing slash |
| After every file write | `comment-audit.sh` | Flags code comments that tell history or refer to the session |
| Session start | `session-name.sh` | Names the session after its repo |
| Session start, after Edit or Write, and on stop | impeccable's own `scripts/impeccable hook` | Checks UI files for design anti-patterns; does nothing until impeccable is installed |
| Always | `statusline.sh` | Shows model, context used, and rate limits |

### How the hooks read a command

`guard-bash.sh` and `skill-gate.sh` read a command through one parser,
`shell-parse.sh` (`--help` lists its output). Text in quotes, a heredoc body or
a comment never counts as a command. A command inside `( )`, `$( )`, backticks
or `{ }` still counts, and `guard-bash.sh` also judges git behind `VAR=x`,
`env`, `sudo`, `command`, `exec`, `nohup`, `time`, `nice` and `timeout`. Each
hook follows its `~/.claude/hooks` link back to the repo and runs the parser
that sits beside it.

`ai-credit.sh` is the one place that decides what credits an AI tool and which
phrases narrate the session. `guard-bash.sh`, `comment-audit.sh` and the `pr`
skill's `provenance.sh` all source it; the hooks find it beside their real file
the same way, and `provenance.sh` falls back to its `~/.claude/hooks` link.

## Rules

A rule is a short file Claude Code loads when it reads a file whose path matches the rule's `paths`. Each file in [`home/.claude/rules/`](../home/.claude/rules/) is linked into `~/.claude/rules/` on its own.

| Rule | Loads for | Asks for |
| --- | --- | --- |
| [`typescript.md`](../home/.claude/rules/typescript.md) | `.ts`, `.tsx`, `.mts`, `.cts` files | `typescript-style-guide` before any TypeScript change, in every agent, subagents included |
| [`python.md`](../home/.claude/rules/python.md) | `.py`, `.pyi` files | `python-anti-patterns` before any Python change, `modern-python` for tooling, and ty for type checks |

In both, the repo's own conventions win over the skill.
