# Issue tracker: <Shortcut | Jira>, paste-ready

Work for this repo is tracked in <Shortcut | Jira>. The agent never creates, edits, or closes anything there: it writes specs and tickets as local markdown, then hands them over on a page the user copies from. The user files them and closes them.

## Locations

- Scratch folder: `<scratch>` (specs and tickets; <gitignored | committed>)
- One feature per directory: `<scratch>/<feature-slug>/`
- The spec is `<scratch>/<feature-slug>/spec.md`
- Tickets are one file per ticket at `<scratch>/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file

## When a skill says "publish to the issue tracker"

1. Write the spec or ticket files under `<scratch>/<feature-slug>/`, creating the directory if needed. A ticket's blocking edges are a `Blocked by:` line naming ticket numbers and titles; a triage label is a `Status:` line near the top of the file.
2. Publish one paste-ready page with the harness's page-publishing tool (in Claude Code, the Artifact tool); where there is none, write a local HTML file and give its path. The page holds one section per spec or ticket, in dependency order, each with a Copy button that copies that item's raw markdown: a title line, then the body, with `Blocked by` spelled out as text so the user can set the links by hand.
3. Tell the user the files are written and the page is up. Filing is theirs.

## Tracker IDs

- <Shortcut: stories look like `sc-1234`. | Jira: issues look like `<KEY>-123`, project key `<KEY>`.>
- When the user reports the ID an item was filed under, add a `Tracker: <id>` line near the top of its file, so commit messages that cite the ID lead back to it.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. Given a tracker ID instead, find the file whose `Tracker:` line matches it. Given neither, ask for the path.

## When a skill says "close" or "resolve" a ticket

Set `Status: done` in the file and name the tracker ID in the report, so the user can close it in <Shortcut | Jira>.
