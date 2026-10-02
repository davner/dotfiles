---
name: setup-dan-skills
description: "Configure this repo for the planning and review skills: which tracker (Shortcut or Jira) and where specs, tickets, the TODO list, the glossary, and ADRs are saved. Run once per repo before /to-spec, /to-tickets, /implement-spec, or code-review."
disable-model-invocation: true
---

# Setup Dan's Skills

Write the per-repo configuration that `to-spec`, `to-tickets`, `implement-spec`, and `code-review` read: the tracker file, `docs/agents/domain.md`, and a short `## Agent skills` block in the repo's `CLAUDE.md`. The glossary and ADRs are team knowledge and always live in the repo; the tracker is the user's own workflow, so in a repo shared with a team it stays out of the repo.

## 1. Look around

Read what already exists before asking anything:

- `CLAUDE.md` and `AGENTS.md` at the repo root, and whether either already has an `## Agent skills` block
- `docs/agents/`: a previous run of this skill
- `.scratch/`, `docs/specs/`, or another folder of spec and ticket markdown
- a glossary (`GLOSSARY.md`, `docs/GLOSSARY.md`) and an ADR folder (`docs/adr/`, `docs/decisions/`)
- `.gitignore`, and `.git/info/exclude` in the main checkout
- `~/.claude/repos/<repo>/issue-tracker.md`: a personal tracker file from a previous run

## 2. Ask, one question at a time

Lead each question with the recommended answer so a one-word reply accepts it. Something found in step 1 beats the default: propose what the repo already uses.

1. **Shared**: is this repo shared with a team? Yes when other people commit to it (recommended when `git log` shows other authors); no for the user's own repos.
2. **Tracker**: Shortcut (recommended), story IDs like `sc-1234`; or Jira, then ask for the project key (`KEY-123`).
3. **Scratch folder** for specs, tickets, and the TODO list: `.scratch/` (recommended), gitignored so working notes stay out of commits; or a committed folder such as `docs/specs/` when the team reviews specs in PRs.
4. **Glossary**: `GLOSSARY.md` at the repo root (recommended), or a path the user names.
5. **ADRs**: `docs/adr/` (recommended), or a folder the user names.

## 3. Show the drafts

Fill in [issue-tracker.md](issue-tracker.md) and [domain.md](domain.md) with the answers, draft the `## Agent skills` block below, and show all three. Apply the user's edits before writing.

```markdown
## Agent skills

- Tracker: <Shortcut | Jira KEY>, paste-ready; specs, tickets, and the TODO list in `<folder>`. See `docs/agents/issue-tracker.md`.
- Domain docs: glossary at `<path>`, ADRs in `<folder>`. See `docs/agents/domain.md`.
```

## 4. Write

- `docs/agents/domain.md`, from the filled-in template
- the tracker file, from the filled-in template: own repo, `docs/agents/issue-tracker.md`; shared repo, `~/.claude/repos/<repo>/issue-tracker.md` (the path rule is in the user's global `AGENTS.md`), so every worktree finds it and the team never sees it
- the `## Agent skills` block into `CLAUDE.md`; when only `AGENTS.md` exists, into that; when neither exists, ask which to create. An existing block is updated in place. A shared repo's block leaves out the Tracker line.
- the scratch folder, when the user chose to ignore it: own repo, into `.gitignore`; shared repo, into the main checkout's `.git/info/exclude` (`git rev-parse --git-path info/exclude`), which every worktree shares and nobody else sees, unless the team's `.gitignore` already covers it
- shared repo with an earlier run: remove a committed `docs/agents/issue-tracker.md` and the block's Tracker line, after moving the file to its personal path, and tell the user that removal is a commit to make

Setup is done when the tracker file, `domain.md`, and the block are written and the user has seen the final block. Tell them the files can be edited directly later, and that re-running this skill is for switching trackers or moving a folder.

## 5. UI projects

When the repo has a user interface, offer `/impeccable init` when it has no `PRODUCT.md`, `/impeccable document` when it has UI code but no `DESIGN.md`, and `/impeccable hooks on` for the design detector after UI edits. Each is an offer the user accepts or skips.
