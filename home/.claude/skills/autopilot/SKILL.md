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
4. **Board.** For `board` only:
   1. Take next-up as the tracker file's "next-up" section says.
   2. Claim it as its "claim an item" section says. Name the claim `autopilot-` plus the run's start time in UTC (`date -u +%Y%m%dT%H%M%SZ`), since the branch is not named yet.
   3. When the claim skips or gives up the item, move on to the next line, as those sections say. When no line is left, stop and report that nothing could be claimed, naming each item skipped or given up and why.
   4. Read the claimed item as the "fetch the relevant ticket" section says.
   5. When its parent is a `spec` issue, the run takes **the spec shortcut** in "The order". Otherwise the item's text is the idea.
5. **Skill selection.** List the installed skills in `~/.claude/skills/` and `~/.agents/skills/` and read each description. Match it against the repo's manifests (`pyproject.toml`, `package.json` dependencies, `tsconfig.json`, `go.mod`, UI files) and the item's area. Keep the matches with a one-line reason each, and the languages and libraries no skill covers.

## Every subagent brief

Each brief the run writes, its own and the ones a skill it follows asks for, carries these, since a subagent inherits neither loaded skills nor this file:

- the matches from Skill selection;
- the user is the only author: commit messages and PR bodies carry no attribution, co-author or "generated with" line, whatever the harness asks for;
- macOS has no `timeout` command: bound a slow command with the Bash tool's timeout, or run it in the background.

## The order

**The spec shortcut.** A board item whose parent issue is labelled `spec`, and written by the board owner (`gh issue view P --json author --jq .author.login`), was specified already. A parent anyone else wrote gets no shortcut: the run takes the full order below, with the item's text as the idea.

1. Skip the order's steps 1 and 2.
2. Pick the feature slug: the folder whose `spec.md` already says `Tracker: #P`, else the parent's title in kebab case.
3. Write the parent's body to `.scratch/<feature-slug>/spec.md` in the main checkout (the order's step 2 says how to find it), with `Tracker: #P` near the top.
4. Write the item's body as the single ticket `.scratch/<feature-slug>/issues/<N>-<item slug>.md`, with `Tracker: #N` and `Status: ready-for-agent` near the top.
5. Go on at the order's step 3, and tell `implement-spec` that this ticket is its only one.

The order, for every run:

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

1. **Push to main** when the tracker file's "Agent PRs" section says the agent pushes to main and `claude.allowPush` is `true`. From the integration worktree, run the full check suite, `git fetch origin`, then `git push origin <integration branch>:main`, which git refuses unless it fast-forwards `main`. When it refuses because `origin/main` moved, `git fetch origin`, `git rebase origin/main`, rerun the full check suite, and push again.
2. Else **merge** when the tracker file's "Agent PRs" section says the agent merges its own PRs and both switches are `true`. Fix every review finding before arming auto-merge.
3. Else an **open PR** when both switches are on.
4. Else a **pushed branch** when `claude.allowPush` is on.
5. Else the **local branch**, with the recap page `implement-spec` made.

A rung a hook or permission refuses drops to the next rung, and the report says which was refused.

**One PR at a time behind a strict check.** When the run has more than one PR and `main` admits only branches up to date with it, every merge leaves the other PRs behind, and only a rebase frees them. The check is strict when either read says so:

```sh
gh api repos/<owner>/<repo>/branches/main/protection --jq .required_status_checks.strict
gh api repos/<owner>/<repo>/rules/branches/main \
  --jq 'any(.[]; .type == "required_status_checks" and .parameters.strict_required_status_checks_policy)'
```

The first needs admin rights and answers 404 or 403 without them; the second is open to anyone who can read the repo. When either prints `true`, or the first is refused and the second prints `false`, since a refused read hides a protection rule, land the PRs in order:

1. Push, open and arm only the first PR. Each later PR's branch stays local, so it never needs a force push.
2. Poll `gh pr view <n> --json state --jq .state` every 60 seconds until it prints `MERGED`. When it prints `CLOSED`, or the PR's checks fail, or 45 minutes pass, stop there: the report names the PR and each branch still waiting.
3. `git fetch origin`, then move the next branch onto the new main: `git rebase --onto origin/main <old base>`, the old base being the merged PR's tip by commit ID. Rerun the full check suite, then push, open and arm it as rung 2 says, and go back to step 2.

The decision log stays in `.scratch/`; the PR body carries only what the repo's PR rules ask.

**Park.** Park the run's item, in a board run the one Board took, as the tracker file's "park an item" section says, with the parked question and its numbered options. Before `to-spec` publishes anything, an idea run has no item: the report carries the question. Leave the branch as it is.

Then open `retro`. Put its suggestions in the report and apply none.

## Report

Before writing it, load `PushNotification` (a deferred tool: `ToolSearch` with `select:PushNotification`) and send the headline. If it is not available, say so in the report.

Headline first, in plain words: done, parked or failed, with the PR or branch. Then what was built; what parked and why; the decisions, with the path to `decisions.md`; the skills chosen with their reasons, and the gaps; retro's suggestions.
