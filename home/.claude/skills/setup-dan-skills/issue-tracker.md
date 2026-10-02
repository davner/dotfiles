# Issue tracker: <Shortcut | Jira>, paste-ready

Work for this repo is tracked in <Shortcut | Jira>. The agent never creates, edits, or closes anything there: it writes specs and tickets as local markdown for the agents' own use, and when the work is done hands over one ticket per PR on a page the user copies from. The user files those and closes them.

## Locations

- Scratch folder: `<scratch>` (specs and tickets; <gitignored | committed>)
- One feature per directory: `<scratch>/<feature-slug>/`
- The spec is `<scratch>/<feature-slug>/spec.md`
- Tickets are one file per ticket at `<scratch>/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file

## When a skill says "publish to the issue tracker"

1. Write the spec or ticket files under `<scratch>/<feature-slug>/`, creating the directory if needed. A ticket's blocking edges are a `Blocked by:` line naming ticket numbers and titles; a triage label is a `Status:` line near the top of the file.
2. The spec and the per-ticket files stay local: they are the agents' reference and work plan, not what the user files. Tell the user so.
3. What the user files is one ticket per PR, handed over when the work is done: one paste-ready page made with the harness's page-publishing tool (in Claude Code, the Artifact tool), or a local HTML file where there is none. The page holds one section per PR ticket, each with a Copy button that copies its raw markdown: a title line, then the body, with `Blocked by` spelled out as text so the user can set the links by hand. Filing is theirs.

## Tracker IDs

- <Shortcut: stories look like `sc-1234`. | Jira: issues look like `<KEY>-123`, project key `<KEY>`.>
- When the user reports the ID an item was filed under, add a `Tracker: <id>` line near the top of its file, so commit messages that cite the ID lead back to it.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. Given a tracker ID instead, find the file whose `Tracker:` line matches it. Given neither, ask for the path.

## When a skill says "close" or "resolve" a ticket

Set `Status: done` in the file and name the tracker ID in the report, so the user can close it in <Shortcut | Jira>.
