---
name: autopilot
description: "Run the new-work flow, idea or board item to reviewed code, with nobody watching."
argument-hint: "<idea | board>"
disable-model-invocation: true
---

Take `$ARGUMENTS` from idea to reviewed code with nobody watching: free text is the idea; the word `board` takes the next board item. Typing `/autopilot` approves this run's subagents: at most about 10 build and research agents, plus up to 50 small voters. One item per run.

## Skills it opens

Before opening the first, say in the conversation: "This run is headless." Then open each step's skill file by its installed path, `~/.claude/skills/<name>/SKILL.md`, and follow it. A skill marked (headless) has a "When headless:" section that replaces its stop points, and `grilling`'s section holds the confidence rule, the research rule and the decision log the others point to.

- `grill-with-docs`
- `grill-me`
- `grilling` (headless)
- `domain-modeling` (headless)
- `to-spec` (headless)
- `to-tickets` (headless)
- `implement-spec` (headless)
- `retro`

## Start

1. **Probe.** Make and remove a temporary directory in one Bash call (`d="$(mktemp -d)" && rmdir "$d"`). If it raises a permission prompt or is refused, stop: tell the user to restart in bypass or auto mode.
2. **Tracker.** Find the tracker file. With none, use the paste-ready `.scratch/` layout `setup-dan-skills` writes by default (its `issue-tracker.md` with every recommended answer), and the report says so. For `board`, stop and report that the repo has no tracker file.
3. **Prune.** Clear what merged runs left behind, in the main checkout. Skip this step when the repo has no `origin`. Run `git fetch --prune`, then take each local branch `autopilot-*` that has landed, in either of two ways:
   - **Pushed to main**: its tip is on `origin/main` (`git merge-base --is-ancestor <branch> origin/main` exits 0) and it has moved since it was created (`git reflog show --format=%H <branch>` lists more than one line). A run that has not committed yet also sits on `origin/main`, and keeps its branch by this second test.
   - **PR merged**, when `gh` is installed and `origin` is on GitHub: its upstream is gone (`git for-each-ref --format='%(refname:short) %(upstream:track)' 'refs/heads/autopilot-*'` prints `[gone]`) and its PR is merged (`gh pr view <branch> --json state --jq .state` prints `MERGED`).

   Any other branch stays, whatever the reason. For each landed branch:
   - Its worktree, when it has one under `<main checkout>/.claude/worktrees/autopilot-*` (`git worktree list --porcelain`): remove it with `git worktree remove <path>`, never `--force`, and only when `git -C <path> status --porcelain` prints nothing and it is not this session's working directory. A worktree with uncommitted changes stays, and so does its branch.
   - The branch: `git branch -d <branch>`. A branch pushed to main first gets `git branch --set-upstream-to=origin/main <branch>`, since `-d` accepts a branch merged into its upstream and the main checkout's `HEAD` may lag `origin/main`. When it refuses, as it does for a squash-merged branch git sees as unmerged, the branch stays and the report lists it for the user to delete.

   The report names what was removed and what stayed, with why.
4. **Board.** For `board`, take the item the tracker file's "next-up" section names. With no item, stop and report that. Move the item to In progress as the tracker file's "move an item" section says. The item's text is the idea.
5. **Skill selection.** List the installed skills in `~/.claude/skills/` and `~/.agents/skills/` and read each description. Match it against the repo's manifests (`pyproject.toml`, `package.json` dependencies, `tsconfig.json`, `go.mod`, UI files) and the item's area. Keep the matches with a one-line reason each, and the languages and libraries no skill covers. Name the matches in every subagent brief, since subagents do not inherit loaded skills.

## The order

1. Grill: `grill-with-docs` when the repo has domain docs (a glossary, an ADR folder, or a tracker or domain file that names them), else `grill-me`.
2. `to-spec`, then `to-tickets`, told in a board run which item the run took, for the tracker file's publish section to reuse. `.scratch/` paths resolve to the main checkout: `dirname "$(git rev-parse --path-format=absolute --git-common-dir)"`.
3. **Integration worktree.** Now the feature slug is known. `git fetch origin`, then `git worktree add -b autopilot-<feature-slug> <main checkout>/.claude/worktrees/autopilot-<feature-slug> origin/main`, with the main checkout's absolute path. When `git check-ignore -q .claude/worktrees/x` fails, add `.claude/worktrees/` to the main checkout's `.git/info/exclude` (`git rev-parse --git-path info/exclude`).
4. `implement-spec` in that worktree, told that `autopilot-<feature-slug>` is its integration branch. Its step 7 is the run's one code review, given the run's spec path.

A park at any step ends the run at **Park** below.

## The retry rule

Count attempts per failing check, keyed by the check and its first error line, across the run. The evidence is in `~/.dotfiles/docs/research/agent-retry-limits.md`.

- **Lint, type errors, tests.** The tool's auto-fix first. Attempt 1 in this context with the full output. Attempt 2 here only if attempt 1 changed the failure. Attempt 3 in a fresh subagent given the task, the check command, the current output and one line per failed attempt, never the transcript. Then park.
- **Red CI.** Reproduce it locally, then the rule above. If it does not reproduce, rerun once; then park.
- **Review finding.** Turn it into a failing test where you can, then the first rule. Otherwise one attempt; a fresh reviewer rechecks that finding, and it parks if it stands.

## Finish

Go as far as the repo allows. The switches are `git config --get claude.allowPush` and `claude.allowPrs`, which `guard-bash.sh` enforces.

1. **Push to main** when the tracker file's "Agent PRs" section says the agent pushes to main and `claude.allowPush` is `true`. From the integration worktree, `git fetch origin`, then `git push origin <integration branch>:main`, which git refuses unless it fast-forwards `main`. When it refuses because `origin/main` moved, `git rebase origin/main`, rerun the full check suite, and push again.
2. Else **merge** when the tracker file's "Agent PRs" section says the agent merges its own PRs and both switches are `true`. Fix every review finding before arming auto-merge.
3. Else an **open PR** when both switches are on.
4. Else a **pushed branch** when `claude.allowPush` is on.
5. Else the **local branch**, with the recap page `implement-spec` made.

A rung a hook or permission refuses drops to the next rung, and the report says which was refused.

The decision log stays in `.scratch/`; the PR body carries only what the repo's PR rules ask.

**Park.** Park the run's item, in a board run the one Board took, as the tracker file's "park an item" section says, with the parked question and its numbered options. Before `to-spec` publishes anything, an idea run has no item: the report carries the question. Leave the branch as it is.

Then open `retro`. Put its suggestions in the report and apply none.

## Report

Before writing it, load `PushNotification` (a deferred tool: `ToolSearch` with `select:PushNotification`) and send the headline. If it is not available, say so in the report.

Headline first, in plain words: done, parked or failed, with the PR or branch. Then what was built; what parked and why; the decisions, with the path to `decisions.md`; the skills chosen with their reasons, and the gaps; retro's suggestions.
