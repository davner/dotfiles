---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets in code."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-dan-skills`.

The goal is the entire spec implemented on a single **integration branch**, with every ticket resolved the way the issue tracker closes work.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

## Steps

Tickets that touch a user interface are built through `impeccable` and checked once on desktop and on mobile in Chrome device emulation.

1. Read the spec and tickets to understand the task graph.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch. If the issue tracker closes work through PRs, or the user asks for one, open a draft PR once the first ticket lands in step 5 (a branch with no commits ahead of main can't open one), marked as closing the spec and tickets.

4. Use **implementer subagents** to implement each ticket, each in its own worktree on its own branch. Each implementer subagent:
   - confirms its worktree is based on the integration branch before starting, and recreates its branch from the integration tip if not;
   - calls the Skill tool with `tdd` to build the ticket, starting from the ticket's **First red test** and pasting that red run into its report (a ticket whose First red test is `none` names the existing check it kept green instead);
   - leaves linear commits on its own branch and reports done. Integrating is the orchestrator's job.

5. Once an **implementer subagent** completes, bring its commits onto the integration branch yourself: `git merge --ff-only` when its branch sits on the integration tip, otherwise `git cherry-pick` its own commits. History stays linear. Re-run the checks on the integration tip before moving on.

6. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency.

7. Once all tickets are complete, call the Skill tool with `code-review` on the integration branch. Fix all issues raised by the code review in a single **implementer subagent**.

8. Publish the **recap page**: every file the branch touched, grouped by purpose, each with a plain-words line on why it changed, and below that one paste-ready ticket per PR the tickets were grouped into, each with a Copy button. The tickets are what the user files; the spec and the work items stay local.

9. If a draft PR exists, mark it ready for review. Otherwise, resolve each ticket the way the issue tracker closes work, and report the integration branch.

10. Clean up all **implementer subagent** worktrees.
