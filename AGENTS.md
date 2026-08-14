# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "zap"` in `configuration.nix` is intentional. It forces the good habit of declaring every Homebrew package in the Nix config instead of installing things ad-hoc, which keeps the machine reproducible. Do not soften it to `uninstall` or `none`.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.
- Subagents in `home/.claude/agents/` deliberately omit the `memory` frontmatter field. Enabling it auto-enables the Read, Write, and Edit tools, which would silently break the read-only boundary that `code-reviewer`, `architect`, and `ui-verifier` depend on. It also drops an `agent-memory/` directory into every repo they run in. Turn it on per-agent only for ones that can write anyway.
- Those agents also deliberately omit the `skills` frontmatter field, even where a skill is obviously relevant. Skills here are hand-installed with `npx skills add` and are absent on a fresh machine, so preloading one would make the agent depend on a step the Nix rebuild does not perform. The prompts invoke skills at runtime instead, which degrades gracefully.
- Agent prompts must stay stack-agnostic. These are user-level agents that load in every project, so they discover a repo's framework, test runner, and conventions rather than assuming a stack. They also must not restate the rules in `home/AGENTS.md`: that file is loaded into every custom subagent already.

## Maintaining this file

- Keep this file for knowledge useful to almost every future agent session in this project.
- Do not repeat what the codebase already shows; point to the authoritative file or command instead.
- Prefer rewriting or pruning existing entries over appending new ones.
- When updating this file, preserve this bar for all agents and keep entries concise.