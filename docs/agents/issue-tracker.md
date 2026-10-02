# Issue tracker: Shortcut, paste-ready

Work for this repo is tracked in Shortcut. The agent never creates, edits, or closes anything there: it writes specs and tickets as local markdown for the agents' own use, and when the work is done hands over one ticket per PR on a page the user copies from. The user files those and closes them.

## Locations

- Scratch folder: `.scratch/` (specs, tickets, and the TODO list; gitignored)
- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Tickets are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- The TODO list is `.scratch/TODO.md`

## When a skill says "publish to the issue tracker"

1. Write the spec or ticket files under `.scratch/<feature-slug>/`, creating the directory if needed. A ticket's blocking edges are a `Blocked by:` line naming ticket numbers and titles; a triage label is a `Status:` line near the top of the file.
2. The spec and the per-ticket files stay local: they are the agents' reference and work plan, not what the user files. Tell the user so.
3. What the user files is one ticket per PR, handed over when the work is done: one paste-ready page made with the harness's page-publishing tool (in Claude Code, the Artifact tool), or a local HTML file where there is none. The page holds one section per PR ticket, each with a Copy button that copies its raw markdown: a title line, then the body, with `Blocked by` spelled out as text so the user can set the links by hand. Filing is theirs.

## When a skill says "add to the TODO list"

Work that surfaces mid-session but belongs to no current spec goes at the bottom of `.scratch/TODO.md`, created with a `# TODO` heading if missing. Append only: never rewrite, reorder, or delete another entry. Each entry carries what a fresh session needs to pick it up:

```markdown
- [ ] **<short title>** - added YYYY-MM-DD
  - From: <the session or spec it came out of>
  - Why: <the problem, in a sentence or two>
  - Known: <decisions already made; files, ADRs, or tickets involved>
  - Next: <the first step, and the skill to start with>
```

When a session starts work on an item, name it to the user. When its work is done, tick it and date it: `- [x] **<title>** - added YYYY-MM-DD, done YYYY-MM-DD`. When the user drops it, tick it with `dropped YYYY-MM-DD: <reason>`.

## Tracker IDs

- Shortcut: stories look like `sc-1234`.
- When the user reports the ID an item was filed under, add a `Tracker: <id>` line near the top of its file, so commit messages that cite the ID lead back to it.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. Given a tracker ID instead, find the file whose `Tracker:` line matches it. Given neither, ask for the path.

## When a skill says "close" or "resolve" a ticket

Set `Status: done` in the file, tick any TODO item that named this work, and name the tracker ID in the report, so the user can close it in Shortcut.
