---
name: autopilot
description: "Run the new-work flow, idea or board item to reviewed code, with nobody watching."
argument-hint: "<idea | board>"
disable-model-invocation: true
---

Take `$ARGUMENTS` from idea to reviewed code with nobody watching: free text is the idea; the word `board` takes the next board item. Typing `/autopilot` approves this run's subagents: about 10 build and research agents in all, plus the voters `grilling` allows. One item per run.

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
3. **Board.** For `board`, read the tracker file and run its next-up command. With none named, take the oldest open item labelled `ready-for-agent` (for a paste-ready tracker, the oldest ticket file with `Status: ready-for-agent`). With no item, stop and report that. Move the item as the tracker file says: In progress, or nothing for a paste-ready tracker. The item's text is the idea.
4. **Skill selection.** List the installed skills in `~/.claude/skills/` and `~/.agents/skills/` and read each description. Match it against the repo's manifests (`pyproject.toml`, `package.json` dependencies, `tsconfig.json`, `go.mod`, UI files) and the item's area. Keep the matches with a one-line reason each, and the languages and libraries no skill covers. Name the matches in every subagent brief, since subagents do not inherit loaded skills.

## The order

1. Grill: `grill-with-docs` when the repo has domain docs (a glossary, an ADR folder, or a tracker or domain file that names them), else `grill-me`.
2. `to-spec`, then `to-tickets`. `.scratch/` paths resolve to the main checkout: `dirname "$(git rev-parse --path-format=absolute --git-common-dir)"`.
3. **Integration worktree.** Now the feature slug is known. `git fetch origin`, then `git worktree add -b autopilot/<feature-slug> <main checkout>/.claude/worktrees/autopilot-<feature-slug> origin/main`, with the main checkout's absolute path. When `git check-ignore -q .claude/worktrees/x` fails, add `.claude/worktrees/` to the main checkout's `.git/info/exclude` (`git rev-parse --git-path info/exclude`).
4. `implement-spec` in that worktree, told that `autopilot/<feature-slug>` is its integration branch. Its step 7 is the run's one code review, given the run's spec path.

A park at any step ends the run at **Park** below.

## The retry rule

Count attempts per failing check, keyed by the check and its first error line, across the run. The evidence is in `~/.dotfiles/docs/research/agent-retry-limits.md`.

- **Lint, type errors, tests.** The tool's auto-fix first. Attempt 1 in this context with the full output. Attempt 2 here only if attempt 1 changed the failure. Attempt 3 in a fresh subagent given the task, the check command, the current output and one line per failed attempt, never the transcript. Then park.
- **Red CI.** Reproduce it locally, then the rule above. If it does not reproduce, rerun once; then park.
- **Review finding.** Turn it into a failing test where you can, then the first rule. Otherwise one attempt; a fresh reviewer rechecks that finding, and it parks if it stands.

## Finish

Go as far as the repo allows. The switches are `git config --get claude.allowPush` and `claude.allowPrs`, which `guard-bash.sh` enforces.

1. **Merge** when the tracker file says the agent merges its own PRs and both switches are `true`. Fix every review finding before arming auto-merge.
2. Else an **open PR** when both switches are on.
3. Else a **pushed branch** when `claude.allowPush` is on.
4. Else the **local branch**, with the recap page `implement-spec` made.

A rung a hook or permission refuses drops to the next rung, and the report says which was refused.

The PR body says nothing about the decision log.

**Park.** Move the item to "Needs info" (a `Status: needs-info` line for a paste-ready tracker) and write the parked question and its options on it. Before `to-spec` publishes anything, an idea run has no item: the report carries the question. Leave the branch as it is.

Then open `retro`. Put its suggestions in the report and apply none.

## Report

Before writing it, load `PushNotification` (a deferred tool: `ToolSearch` with `select:PushNotification`) and send the headline. If it is not available, say so in the report.

Headline first, in plain words: done, parked or failed, with the PR or branch. Then what was built; what parked and why; the decisions, with the path to `decisions.md`; the skills chosen with their reasons, and the gaps; retro's suggestions. End with two short lists: what you verified, and what you took on trust.
