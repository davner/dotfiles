---
description: Fan out comment-auditor agents over a scope and present one numbered comment triage for approval
argument-hint: <package or directory>
---

Audit every code comment in $ARGUMENTS against the deletion criterion the
comment-auditor agent carries. Known pitfall, and the reason this is a
fan-out of readers rather than a search: pattern-matching cannot judge
comments - a previous grep-based hook declared a package clean while 55
comments were false. Every comment must be read against its code.

1. **Measure the scope first.** Count comment-bearing lines per subdirectory
   of $ARGUMENTS (a grep for the languages' comment markers is enough here -
   it is sizing the work, not judging it).
2. **Split into 2-4 balanced sub-scopes** by those counts, every file in
   exactly one sub-scope.
3. **Fan out comment-auditor agents, one per sub-scope, in parallel** (a
   single message with one Agent call each). The agent's own definition
   carries the criterion and the row contract; each prompt names the
   sub-scope as absolute paths and requires the triage rows in that format
   plus the total audited.
4. **Merge into ONE numbered triage table.** Delete and rewrite items are
   numbered first, so the user approves by number; keeps are summarized, not
   enumerated. Check that the merged rows account for every agent's reported
   total - a mismatch is a coverage gap to reconcile before presenting.
5. **Present the table and STOP.** No edits until the user approves items by
   number. Skipped and rejected items stay in the record as skipped, not
   silently dropped.
6. **After approval**, route the approved items to senior-dev, locating each
   comment by its text, not its line number, since lines drift between audit
   and edit. Then re-run the project's own test, lint, and typecheck gates.
