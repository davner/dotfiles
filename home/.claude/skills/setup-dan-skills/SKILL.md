---
name: setup-dan-skills
description: "Configure this repo for the planning and review skills: which tracker (GitHub, Shortcut or Jira) and where specs, tickets, the TODO list, the glossary, and ADRs are saved. Run once per repo before /to-spec, /to-tickets, /implement-spec, /autopilot, or code-review."
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
- `git remote get-url origin`: whether the repo is on github.com
- `.github/workflows/`: the CI workflows and their job names
- tags (`git tag`) and an existing changelog tool's config (git-cliff, release-please, semantic-release, towncrier)

## 2. Ask, one question at a time

Lead each question with the recommended answer so a one-word reply accepts it. Something found in step 1 beats the default: propose what the repo already uses.

1. **Shared**: is this repo shared with a team? Yes when other people commit to it (recommended when `git log` shows other authors); no for the user's own repos.
2. **Tracker**: GitHub, offered only when the repo is not shared (recommended then, when `origin` is on github.com), issues `#123` on a board per repo; Shortcut (recommended otherwise), story IDs like `sc-1234`; or Jira, then ask for the project key (`KEY-123`).
3. **Scratch folder** for specs and tickets, and the TODO list outside GitHub: `.scratch/` (recommended), gitignored so working notes stay out of commits; or a committed folder such as `docs/specs/` when the team reviews specs in PRs.
4. **Glossary**: `GLOSSARY.md` at the repo root (recommended), or a path the user names.
5. **ADRs**: `docs/adr/` (recommended), or a folder the user names.

For GitHub only, three more:

6. **Agent PRs**: do agents open PRs here? Yes (recommended), or no to leave pushes and PRs to the user.
7. **Agent merges**, after a yes to 6: do agents merge their own PRs once CI passes? No (recommended), the user merges; or yes, squash auto-merge behind the required checks. With no workflow under `.github/workflows/`, skip the question and note that auto-merge needs CI, so the user merges.
8. **Releases**: does this repo ship releases? Yes (recommended when it has tags) sets up towncrier; no sets up no changelog and leaves an existing tool alone.

## 3. GitHub setup

For a GitHub tracker only. Run each script from the repo root, by its path in this skill's folder; each reads the repo from `gh repo view`. Put every link the user opens on its own line.

1. **Labels.** Run `scripts/labels.sh` and relay what it renamed, kept, and deleted.
2. **Board.** Run `scripts/board.sh`. When it stops on the missing project scope, hand the user `gh auth refresh -s project`, wait for them to say they ran it, and run it again. Its `board=` and `url=` lines fill the tracker file's board number and URL, and the owner is the login in that URL. Relay every line after `url=`: they are manual steps on GitHub's workflows pages, which have no API.
3. **Switches**, after a yes to 6. Hand the user these to run inside the repo, since an agent may not set them:

   ```sh
   cc-push on
   git config claude.allowPrs true
   ```

   Wait for them to say they ran them, then check that `git config --get claude.allowPush` and `git config --get claude.allowPrs` each print `true`. Until both do, the tracker file records agents opening no PRs.
4. **Changelog**, after a yes to 8. Offer the towncrier templates as [changelog/README.md](changelog/README.md) lays them out, filling its placeholders. When step 1 found another changelog tool, offer the switch first and name the files it would replace. Writing them is the user's call, and committing them is a commit for the user to make.
5. **Repo settings**, after a yes to 7 and both switches `true`. Pass each CI job the default branch should require as `--check`, plus the changelog check `changelog/README.md` names when the user took the templates. Show the output of `scripts/repo-settings.sh --dry-run --check <name>...`, and run the same command without `--dry-run` only after the user's OK. When GitHub refuses a setting, relay its error and record agents not merging.

## 4. Show the drafts

Fill in the tracker template with the answers: [issue-tracker-github.md](issue-tracker-github.md) for GitHub, keeping its release lines only after a yes to 8, else [issue-tracker.md](issue-tracker.md). Fill in [domain.md](domain.md), draft the `## Agent skills` block below, and show all three. Apply the user's edits before writing.

```markdown
## Agent skills

- Tracker: <Shortcut | Jira KEY>, paste-ready; specs, tickets, and the TODO list in `<folder>`. See `docs/agents/issue-tracker.md`.
- Domain docs: glossary at `<path>`, ADRs in `<folder>`. See `docs/agents/domain.md`.
```

For GitHub, the Tracker line names the board:

```markdown
- Tracker: GitHub issues on the board at <board url>; specs and tickets in `<folder>`. See `docs/agents/issue-tracker.md`.
```

## 5. Write

- `docs/agents/domain.md`, from the filled-in template
- the tracker file, from the filled-in template: own repo, `docs/agents/issue-tracker.md`; shared repo, `~/.claude/repos/<repo>/issue-tracker.md` (the path rule is in the user's global `AGENTS.md`), so every worktree finds it and the team never sees it
- the `## Agent skills` block into `CLAUDE.md`; when only `AGENTS.md` exists, into that; when neither exists, ask which to create. An existing block is updated in place. A shared repo's block leaves out the Tracker line.
- the scratch folder, when the user chose to ignore it: own repo, into `.gitignore`; shared repo, into the main checkout's `.git/info/exclude` (`git rev-parse --git-path info/exclude`), which every worktree shares and nobody else sees, unless the team's `.gitignore` already covers it
- shared repo with an earlier run: remove a committed `docs/agents/issue-tracker.md` and the block's Tracker line, after moving the file to its personal path, and tell the user that removal is a commit to make

Setup is done when the tracker file, `domain.md`, and the block are written and the user has seen the final block. Tell them the files can be edited directly later, and that re-running this skill is for switching trackers or moving a folder.

## 6. UI projects

When the repo has a user interface, offer `/impeccable init` when it has no `PRODUCT.md`, `/impeccable document` when it has UI code but no `DESIGN.md`, and, in the user's own repos only, `/impeccable hooks on` for the design detector after UI edits; in a shared repo the hook is already on by default and `hooks on` would write a shared `.impeccable/config.json`. Each is an offer the user accepts or skips.
