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
code. First use in a repo: add `.tickets/` to its .gitignore and name that
change in the summary. Never run `git clean -dfx` in the main tree while a
ticket is in flight - it deletes live worktrees. Ticket frontmatter: id,
title, code, branch, worktree, status, round, created; sections `## Spec`,
`## Reports` (the writer's), `## Verdicts`, `## Handoff`. Status: OPEN ->
IN_PROGRESS -> DONE -> (REWORK -> IN_PROGRESS)* -> READY -> CLOSED, ESCALATED
reachable from any REWORK. The writer owns IN_PROGRESS -> DONE; the lead owns
every other transition.

1. **new <task>** - consult `researcher`/`architect` first only when the
   design turns on an unknown or has more than one plausible shape. Write the
   spec: a paste-ready Shortcut **Title** and **Description**, then goal,
   contracts, files expected to change, tests required, out of scope. Present
   it and STOP. The user files it in Shortcut; their reply with the ticket
   code is the approval.

2. **start <id>** - create the ticket file (status OPEN), then
   `git worktree add .tickets/<id>/tree -b <id> main`. Boot `senior-dev` in
   the background, model opus, its prompt carrying the spec inline, the
   absolute worktree and ticket-file paths, the branch, and the ticket code.
   Status IN_PROGRESS. Recovery after a restart or lost writer: the ticket
   file plus `git log main..<id>` is the whole state - boot a cold writer
   into the existing worktree with the spec, the verdicts to date, and that
   log.

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
     `ui-verifier` + `a11y-auditor` (frontend - they start the app from the
     worktree). `debugger` and `docs-writer` on their own triggers,
     sequential like test-writer.
   Record each verdict verbatim under `## Verdicts` with the round number.

4. **Verdict** - ACCEPT is APPROVE with every score >= 90 and no Blocking
   finding anywhere. Anything else is REWORK: relay Blocking + Should-fix +
   the comment rows to the same resident writer and bump `round`. After 3
   failed rounds: status ESCALATED, present the full history, stop.

5. **On ACCEPT** - ask the writer for handoff: rebase onto current main in
   its worktree, re-run the suite. A conflicted rebase re-enters review.
   Then status READY: record the branch tip and suite result under
   `## Handoff` and report to the user - the branch is the deliverable, and
   push, PR, merge, and deletion all wait for their word.

6. **accept <id>** (user-triggered) - retire the writer,
   `git worktree remove .tickets/<id>/tree` (`--force` only for leftover
   build artifacts), status CLOSED. The branch stays: it holds unmerged work.

7. **status [id]** - one table from ticket frontmatter; anything live (a
   running writer, a branch tip) is stamped with when it was observed.
