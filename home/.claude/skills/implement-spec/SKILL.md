---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets in code."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

Read the tracker file. If there is none, tell the user to run `/setup-dan-skills`.

The goal is the entire spec implemented on a single **integration branch**, with every ticket resolved the way the issue tracker closes work.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

## Steps

Tickets that touch a user interface are built through `impeccable` and checked once on desktop and on mobile in Chrome device emulation.

1. Read the spec and tickets to understand the task graph.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch. When the tickets group into several PRs, each PR gets its own integration branch, **stacked**: the next one starts from the previous one's tip, and once the lower PR merges, its successor moves onto main by `git rebase --onto` with the old base named by commit ID. Every step below then runs per PR, code review included. If the issue tracker closes work through PRs, or the user asks for one, open a draft PR once the first ticket lands in step 5 (a branch with no commits ahead of main can't open one), marked as closing the spec and tickets: its body opens with the line the tracker file's "Agent PRs" section gives, when it has one.

   When the tracker file has a "move an item" section, move each PR's issue (the `Tracker: #N` line in its ticket files) to In progress as that section says when its integration branch is created, and to In review when its PR is ready for review in step 9.

4. Use **implementer subagents** to implement each ticket, each in its own worktree on its own branch. Create each worktree in its own command, then work in it. Hand each one its ticket's absolute path in this checkout, since a new worktree has no copy of a gitignored scratch folder. Each implementer subagent:
   - is told the integration tip's commit ID and confirms its worktree starts there before anything else, recreating its branch from that tip if not;
   - calls the Skill tool with `tdd` to build the ticket, starting from the ticket's **First red test**. Every behaviour is its own red → green slice, and the report pastes the red run of each one (a ticket whose First red test is `none` names the existing check it kept green instead);
   - leaves linear commits on its own branch and reports done. Integrating is the orchestrator's job.

5. Once an **implementer subagent** completes, check its report has a red run for every behaviour it added; send back any slice that lacks one to be redone red-first. Then bring its commits onto the integration branch yourself with `git merge --ff-only`. When its branch no longer sits on the integration tip, send it back to its implementer to rebase onto the tip and re-run its checks, naming the old base and the target by commit ID, since a branch name can move; the implementer resolves its own conflicts. History stays linear. Run the checks on every commit that comes over, stopping at the first failure, not only on the tip.

6. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency.

   When the user or a finding changes a decision mid-build, edit that decision where it lives in the spec (Implementation Decisions, Out of Scope, a ticket's criteria) before the next implementer starts, so every pointer to the spec leads to what is true now.

7. Once all tickets are complete, call the Skill tool with `code-review` on the integration branch. Fix all issues raised by the code review in a single **implementer subagent**.

8. Publish the **recap page**: every file the branch touched, grouped by purpose, each with a plain-words line on why it changed. Below that, when the tracker file's "publish to the issue tracker" section leaves filing to the user, one paste-ready ticket per PR the tickets were grouped into, each with a Copy button: the tickets are what the user files; the spec and the work items stay local. When that section filed the issues already, list each PR's issue `#N` instead.

9. If a draft PR exists, mark it ready for review. Otherwise, resolve each ticket as the tracker file's "close" or "resolve" section says, and report the integration branch.

10. Clean up all **implementer subagent** worktrees.

## When headless:

When the conversation has said the run is headless, nobody will answer. Carry With no tracker file, use the layout autopilot's Start names (`~/.claude/skills/autopilot/SKILL.md`). on through every step that would wait on the user, and say in each implementer brief that the run is headless. A choice the user would have made, such as a decision changed mid-build in step 6, goes through the confidence rule in `grilling`'s "When headless:" section (`~/.claude/skills/grilling/SKILL.md`) and into the decision log it names; a park stops the run. Every artefact stays the same, the recap page in step 8 included.

In step 3, use the integration branch the run names in place of creating one. Open the draft PR in step 3, and mark it ready in step 9, only when `git config --get claude.allowPrs` prints `true`; otherwise skip both.

Each implementer brief also says to follow the retry rule in `~/.claude/skills/autopilot/SKILL.md` ("The retry rule") for a failing check. Step 7 gives `code-review` the run's spec path, and its fix pass follows that rule's review-finding row: a failing test where it can, else one attempt and a fresh reviewer rechecks the finding.
