---
description: Run the ticket loop - spec gate, resident writer in a worktree, cold review rounds, the branch as the deliverable
argument-hint: new <task> | start <id> | status [id] | accept <id>
---

Run the ticket loop on $ARGUMENTS. The lead (this session) drives it. Nothing
here ever pushes, merges to main, files or moves anything on GitHub or
Shortcut, or deletes a branch - each of those waits for the user's explicit
word, every time. The main working tree is never touched; all work happens in
the ticket's worktree.

Conventions: the user supplies the ticket code (e.g. `sc-1234`) from Shortcut.
id = `<code>-<slug>`, branch = id, worktree = `.tickets/<id>/tree/`, ticket
file = `.tickets/<id>/ticket.md`. Absolute paths in every agent prompt,
because gitignored files do not appear inside a worktree. Commit scope = the
code. Check `.tickets/` is in the repo's .gitignore at the start of every
ticket, not only the first, and name the change in the summary when you add
it: the entry can be reverted between tickets, and without it a stray
`git add .` stages a live worktree. Never run `git clean -dfx` in the main
tree while a ticket is in flight - it deletes them. Ticket frontmatter: id,
title, code, branch, worktree, status, round, created; sections `## Spec`,
`## Reports` (the writer's), `## Verdicts`, `## Handoff`. Status: OPEN ->
IN_PROGRESS -> DONE -> (REWORK -> IN_PROGRESS)* -> READY -> CLOSED, ESCALATED
reachable from any REWORK. The writer owns IN_PROGRESS -> DONE; the lead owns
every other transition.

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
codegen), `writer`, `tests`, `review` (one row per reviewer, named in `agent`),
`handoff`. The columns are fixed and append-only: reordering one or inserting
another makes every row written before it unreadable, and comparison across
tickets is the only reason the file exists. It lives under `.tickets/`, so it is
never committed.

Optimising this loop later: read `.tickets/timings.tsv` first and say which row
totals drove the change - the loop is not to be tuned on a hunch. What each
finding licenses:

- `review` rows dominate, and rounds after the first are most of that - scope
  rounds >= 2 to `git diff` since the previous round's tip instead of the whole
  diff, keeping the full diff for round 1.
- One reviewer's rows dominate the others - re-run only the reviewers that
  found something, plus `code-reviewer`, and re-run a passed reviewer only when
  the fix touched files in its domain.
- `setup` dominates - move install and codegen into a `WorktreeCreate` hook so
  a cold worktree is off the critical path.
- `approval` dominates - the spec gate is working as designed and the loop is
  not what is slow. Change nothing here.

1. **new <task>** - consult `researcher`/`architect` first only when the
   design turns on an unknown or has more than one plausible shape. Write the
   spec: a paste-ready Shortcut **Title** and **Description**, then goal,
   contracts, files expected to change, tests required, out of scope. Present
   it and STOP. The user files it in Shortcut; their reply with the ticket
   code is the approval.

2. **start <id>** - create the ticket file (status OPEN), then
   `git worktree add .tickets/<id>/tree -b <id> main`. Boot `senior-dev` in
   the background, model opus, its prompt carrying the spec inline, the
   absolute worktree and ticket-file paths, the branch, the ticket code, and
   the repo's install and codegen sequence, since a new worktree starts
   without any of the gitignored artifacts a build needs. Status IN_PROGRESS.
   Recovery after a restart or lost writer: the ticket
   file plus `git log main..<id>` is the whole state - boot a cold writer
   into the existing worktree with the spec, the verdicts to date, and that
   log. Mid-ticket, spawn `researcher` and relay its report whenever the
   writer hits something the repo cannot answer - whether an approach is
   possible, how a library actually behaves, or whether a dependency it is
   about to take is still maintained. The writer idles while it runs. Reading
   a tool's own docs is what that check would otherwise degrade into, and a
   README never says the project was abandoned.

3. **On DONE** - if the spec changes behavior, first send `test-writer` into
   the worktree to author the new coverage and commit it to the branch. The
   worktree has one writer at a time: the resident writer idles while
   test-writer, debugger, or docs-writer works there. Then spawn the review
   round in parallel, each agent given the spec inline, the worktree path,
   and `git diff main...<id>` as scope:
   - `code-reviewer`, model overridden to the session's top model - every
     round, cold.
   - `comment-auditor` on the diff's files - every round. Rows on comments
     the diff introduced or changed join the must-fix list; rows on
     pre-existing comments are reported to the user and left alone.
   - When the diff warrants: `migration-safety` (any migration - mandatory),
     `ui-verifier` + `a11y-auditor` (frontend). The lead starts one instance
     of the app from the worktree and hands both agents that URL and the time
     it was observed; two agents each starting their own collide on the port,
     and the loser either fails to bind or reads the winner's build.
     `debugger` and `docs-writer` on their own triggers, sequential like
     test-writer.
   Record each verdict verbatim under `## Verdicts` with the round number.

4. **Verdict** - ACCEPT is APPROVE with every score >= 90 and no Blocking
   finding anywhere. Anything else is REWORK: relay Blocking + Should-fix +
   the comment rows to the same resident writer and bump `round`. After 3
   failed rounds: status ESCALATED, present the full history, stop.

5. **On ACCEPT** - ask the writer for handoff: fetch, rebase onto
   `origin/main` in its worktree, re-run the suite. A conflicted rebase
   re-enters review.
   Then status READY: record the branch tip and suite result under
   `## Handoff` and report to the user - the branch is the deliverable, and
   push, PR, merge, and deletion all wait for their word.

6. **accept <id>** (user-triggered) - retire the writer,
   `git worktree remove .tickets/<id>/tree` (`--force` only for leftover
   build artifacts), status CLOSED. The branch stays: it holds unmerged work.

7. **status [id]** - one table from ticket frontmatter; anything live (a
   running writer, a branch tip) is stamped with when it was observed.
