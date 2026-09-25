---
description: Run the ticket loop - spec gate, resident writer in a worktree, cold review rounds, the branch as the deliverable
argument-hint: new <task> | start <id> | status [id] | close <id...>
---

Run the ticket loop on $ARGUMENTS. The lead (this session) drives it. Nothing
here ever pushes, merges to main, files or moves anything on GitHub or
Shortcut, or deletes a branch - each of those waits for the user's explicit
word, every time. The main working tree is never touched; all work happens in
the ticket's worktree.

Conventions: the user supplies the ticket code (e.g. `sc-1234`) from Shortcut.
id = `<code>-<slug>`, branch = id, worktree = `.tickets/<id>/tree/`, ticket
file = `.tickets/<id>.md` - at the top level of `.tickets/`, outside the
`<id>/` folder, so deleting a ticket's worktree folder never takes the spec
and reports with it. Absolute paths in every agent prompt,
because gitignored files do not appear inside a worktree. Commit scope = the
code. Check `.tickets/` is in the repo's .gitignore at the start of every
ticket, not only the first, and name the change in the summary when you add
it: the entry can be reverted between tickets, and without it a stray
`git add .` stages a live worktree. Never run `git clean -dfx` in the main
tree while a ticket is in flight - it deletes them. Ticket frontmatter: id,
title, code, branch, base (the branch it was cut from - `main` or a parent
ticket's branch), worktree, port (its dev-server port, empty when the project
has no server), server_pid (empty when no server runs), status, round,
created, phase_started (the running phase's start, empty between phases);
sections `## Spec`, `## Reports` (the writer's), `## Verdicts`,
`## Handoff`. Status: OPEN -> IN_PROGRESS -> DONE -> (REWORK -> IN_PROGRESS)*
-> READY -> CLOSED, ESCALATED reachable from any REWORK. The writer owns
IN_PROGRESS -> DONE; the lead owns every other transition.

Worktrees: a ticket worktree lives inside the main checkout, so it is not the
isolated tree it looks like. Anything that finds its configuration by walking
upward - a bundler resolving path aliases, a linter or formatter locating its
config, a package manager looking for a workspace root - walks out of the
worktree root and into the main tree. A main tree that is uninstalled,
mid-refactor, or holding a stale generated file therefore produces failures
inside the worktree that read exactly like defects in the branch. Keeping the
main tree in a working state while a ticket is in flight is the fix; the
baseline run is how you tell the two apart before spending a round on it.
Gitignored files do not exist in a new worktree either, so a build's
prerequisites - installed dependencies, generated code, local environment
files - are absent there until something creates them.

Output to the user: anything meant to be pasted elsewhere, the Shortcut title
and description most of all, goes inside a fenced block as raw markdown, since
rendering it in the terminal is what destroys the source that gets pasted. Any
issue or PR named anywhere in the loop's output is a markdown link to it, never
a bare number, because a bare number is not clickable and does not say which
repo it belongs to.

Timings: the lead appends one tab-separated row to `.tickets/timings.tsv` as
each phase ends, creating the file with this header when it is absent:

```
ticket	phase	round	agent	started	ended	seconds
```

Timestamps are `date -u +%Y-%m-%dT%H:%M:%SZ`. `round` is `0` outside a round,
`agent` is `-` where none applies. Phases: `spec` (the lead writing it),
`approval` (waiting on the user's ticket code), `setup` (worktree, install,
codegen), `writer` (including the design options and the user's pick),
`tests`, `review` (one row per reviewer, named in `agent`), `handoff`,
`rework-after-ready` (any change after READY), `squash` (folding a branch's
commits before its PR), `cleanup` (close-out). The columns are fixed and
append-only: reordering one or inserting another makes every row written
before it unreadable, and comparison across tickets is the only reason the
file exists. It lives under `.tickets/`, so it is never committed.

A phase is not finished until its row is appended: write the row in the same
action that reports the phase's end, not from memory later, because a gap in
the file reads as a fast phase and steers the tuning below toward the wrong
fix. When a phase starts, set `phase_started` in the ticket frontmatter to the
start timestamp (for `review`, the round's shared start); clear it when the
row lands. The ticket file is the recovery state, so a rebooted lead inherits
the running phase's start instead of inventing one.

Optimising this loop later: read `.tickets/timings.tsv` first and say which row
totals drove the change - the loop is not to be tuned on a hunch. What each
finding licenses:

- `setup` dominates - move install and codegen into a `WorktreeCreate` hook so
  a cold worktree is off the critical path.
- `approval` dominates - the spec gate is working as designed and the loop is
  not what is slow. Change nothing here.

1. **new <task>** - consult `researcher`/`architect` first only when the
   design turns on an unknown or has more than one plausible shape; for
   reader-visible behavior, draft-ticket's prior-art research always runs.
   Write the spec: the `draft-ticket` skill produces the paste-ready Shortcut
   **Title** and **Description** and the sidebar-field recommendations, then
   this loop adds the engineering half - goal, contracts, files expected to
   change, tests required, out of scope. Tests required are built from the
   acceptance criteria: each criterion is a required case cited by its
   position in the list (the first is 1), then each state under "What the
   reader sees", followed by the cases a human-facing ticket leaves out -
   failure paths, edge inputs. The criteria are the floor, not the test
   plan. Present it and STOP. The user files it in Shortcut; their reply with
   the ticket code is the approval.

2. **start <id>** - create the ticket file (status OPEN), then
   `git worktree add .tickets/<id>/tree -b <id> <base>`. When several tickets
   are approved together, the lead fixes their order at approval: a ticket
   that uses another's work takes that ticket's branch as `base`, and tickets
   called parallel must not change the same file. When the project's
   CLAUDE.md or README names a command that serves it, assign the worktree a
   free dev-server port (check nothing listens on it) and record it;
   otherwise `port` and `server_pid` stay empty. Any server the lead starts
   for the ticket gets its pid recorded in `server_pid`. Boot
   `senior-dev` in the background, model opus, its prompt carrying the spec
   inline, the absolute worktree and ticket-file paths, the branch, the ticket
   code, and the repo's install and codegen sequence, since a new worktree
   starts without any of the gitignored artifacts a build needs. Status
   IN_PROGRESS. Recovery after a restart or lost writer: the ticket
   file plus `git log <base>..<id>` is the whole state - boot a cold writer
   into the existing worktree with the spec, the verdicts to date, and that
   log. Mid-ticket, spawn `researcher` and relay its report whenever the
   writer hits something the repo cannot answer - whether an approach is
   possible, how a library actually behaves, or whether a dependency it is
   about to take is still maintained. The writer idles while it runs. Reading
   a tool's own docs is what that check would otherwise degrade into, and a
   README never says the project was abandoned.

3. **On DONE** - a DONE claim carries its verification: the repo's own gates
   (tests, lint, build) run green in the worktree, with the output shown. A
   red or unrun gate bounces straight back to the writer without spawning
   any reviewer - review judgment is never spent on defects a test run
   catches free. For a reader-visible change on a ticket with a `port` (one
   without skips straight to test-writer), the lead starts the app on it
   (recording `server_pid`), the writer shows two or three options on that
   URL through the `impeccable` skill, never starting its own server, and
   the user picks one before test-writer starts, so tests are written
   against the chosen design. Then, if the spec changes behavior,
   send `test-writer` into the worktree, with the spec inline, to author the
   new coverage and commit it to the branch. The worktree has one writer at a
   time: the resident writer idles while test-writer, debugger, or
   docs-writer works there. Then run the review round, each agent given the
   spec inline and the worktree path. Round 1 opens with `code-reviewer`
   alone as a smoke gate: any Blocking finding goes straight to REWORK and
   the rest of the panel never spawns, because it would be reviewing a tip
   about to change. Only a gate pass (no Blocking finding) fans the rest of
   the round out in parallel; rounds after the first are parallel from the
   start, since the code is stable enough by then that serializing only
   spends wall clock.
   Round 1 reviews `git diff <base>...<id>` in full; record the branch tip with
   the round's verdicts, and rounds after the first review only the diff
   since the previous round's recorded tip - the earlier code already passed,
   so re-reading it buys nothing. On rounds after the first, re-run only the
   reviewers that found something, plus `code-reviewer` always; a reviewer
   that passed re-runs only when the rework touched files in its domain.
   - `code-reviewer` - every round, cold.
   - No comment reviewer: the write hook audits comment discipline on the
     writer's own edits, deterministically, and hooks fire inside subagents.
     Do not spawn `comment-auditor` here - it is the legacy-sweep tool for
     `/comment-audit`, not a round gate.
   - When the diff warrants: `migration-safety` (any migration - mandatory),
     `ui-verifier` (frontend - its verdict covers rendering and WCAG). The
     lead starts one instance of the app from the worktree on its `port`,
     or reuses the one from the options step, and hands the agent that URL
     and the time it was observed, so agents never race to bind the same
     port.
     `debugger` and `docs-writer` on their own triggers, sequential like
     test-writer.
   Record each verdict verbatim under `## Verdicts` with the round number.

4. **Verdict** - ACCEPT is APPROVE with every score >= 90 and no Blocking
   finding anywhere. Anything else is REWORK: relay Blocking + Should-fix
   to the same resident writer and bump `round`. After 3
   failed rounds: status ESCALATED, present the full history, stop.

5. **On ACCEPT** - when the branch holds several commits for one
   capability, the lead may fold them into one, keeping a
   `<branch>-pre-squash` backup branch, timed as `squash`; folding rewrites
   history, so it waits for the user's word like every rewrite. Then ask the
   writer for handoff: fetch, rebase onto `base` in its worktree
   (`origin/main` when `base` is main, else the parent ticket's branch after
   its own handoff), re-run the suite. A conflicted rebase re-enters review.
   Then status READY: record the branch tip and suite result under
   `## Handoff` and report to the user - the branch is the deliverable, and
   push, PR, merge, and deletion all wait for their word.

6. **close <id...>** (only on the user's word, after the PRs merge) - list
   what will go, then: stop the dev servers recorded in each ticket file,
   retire each ticket's writer, `git worktree remove .tickets/<id>/tree`
   (`--force` only for leftover build artifacts), delete the now-empty
   `.tickets/<id>/` folder, and delete the local branch plus any backup
   branches the loop made. A branch is deleted only when GitHub shows its PR
   merged (`gh pr view <branch> --json state`), because a squash-merged
   branch never looks merged to git. Status CLOSED. The ticket file stays -
   `.tickets/<id>.md` is the record of what was built and why.

7. **status [id]** - one table from ticket frontmatter; anything live (a
   running writer, a branch tip) is stamped with when it was observed.
