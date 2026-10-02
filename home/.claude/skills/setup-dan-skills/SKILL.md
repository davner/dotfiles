---
name: setup-dan-skills
description: "Configure this repo for the planning and review skills: which tracker (Shortcut or Jira) and where specs, tickets, the TODO list, the glossary, and ADRs are saved. Run once per repo before /to-spec, /to-tickets, /implement-spec, or code-review."
disable-model-invocation: true
---

# Setup Dan's Skills

Write the per-repo configuration that `to-spec`, `to-tickets`, `implement-spec`, `code-review`, `grilling`, and `pr` read: a short `## Agent skills` block in the repo's `CLAUDE.md`, whose tracker line names the tracker and the scratch folder, and `docs/agents/domain.md`.

## 1. Look around

Read what already exists before asking anything:

- `CLAUDE.md` and `AGENTS.md` at the repo root, and whether either already has an `## Agent skills` block
- `docs/agents/`: a previous run of this skill. An old `docs/agents/issue-tracker.md` holds a tracker and a folder to carry into the tracker line.
- `.scratch/`, `docs/specs/`, or another folder of spec and ticket markdown
- a glossary (`GLOSSARY.md`, `docs/GLOSSARY.md`) and an ADR folder (`docs/adr/`, `docs/decisions/`)
- `.gitignore`

## 2. Ask, one question at a time

Lead each question with the recommended answer so a one-word reply accepts it. Something found in step 1 beats the default: propose what the repo already uses.

1. **Tracker**: Shortcut (recommended), story IDs like `sc-1234`; or Jira, then ask for the project key (`KEY-123`).
2. **Scratch folder** for specs, tickets, and the TODO list: `.scratch/` (recommended), gitignored so working notes stay out of commits; or a committed folder such as `docs/specs/` when the team reviews specs in PRs.
3. **Glossary**: `GLOSSARY.md` at the repo root (recommended), or a path the user names.
4. **ADRs**: `docs/adr/` (recommended), or a folder the user names.

## 3. Show the drafts

Fill in [domain.md](domain.md) with the answers, draft the `## Agent skills` block below, and show both. Apply the user's edits before writing.

```markdown
## Agent skills

- Tracker: <Shortcut (`sc-1234`) | Jira (`KEY-123`)>, paste-ready; specs, tickets, and the TODO list in `<folder>`.
- Domain docs: glossary at `<path>`, ADRs in `<folder>`. See `docs/agents/domain.md`.
```

## 4. Write

- `docs/agents/domain.md`, from the filled-in template
- the `## Agent skills` block into `CLAUDE.md`; when only `AGENTS.md` exists, into that; when neither exists, ask which to create. An existing block is updated in place.
- the scratch folder into `.gitignore`, only when the user chose to ignore it
- remove an old `docs/agents/issue-tracker.md`, once its tracker and folder are in the tracker line

Setup is done when the block and `docs/agents/domain.md` are written and the user has seen the final block. Tell them the files can be edited directly later, and that re-running this skill is for switching trackers or moving a folder.

## 5. UI projects

When the repo has a user interface, offer `/impeccable init` when it has no `PRODUCT.md`, `/impeccable document` when it has UI code but no `DESIGN.md`, and `/impeccable hooks on` for the design detector after UI edits. Each is an offer the user accepts or skips.
