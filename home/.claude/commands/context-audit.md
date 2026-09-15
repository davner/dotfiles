---
description: Audit Claude context files against their size caps, then trim only what the user approves file by file
argument-hint: [file ...] | --agents
---

Run `~/.claude/context-audit.sh` with $ARGUMENTS passed through: file paths
audit exactly those files, `--agents` audits the agent definitions in
`~/.claude/agents/`, and no arguments audits this repo's context files (the
script's header documents how `<root>/.claude/context-audit` scopes that).
Show the user the table exactly as printed, in a fenced block.

If every row is `ok`, say so and stop.

For each file marked `over`, ask the user - one file at a time - whether they
want it trimmed. Never touch a file without that per-file yes; a file the user
skips stays as it is, with no further argument. Trimming means pruning content
against one criterion: **would removing this cause Claude to make mistakes?**
Cut what fails that test - stale entries, restated codebase facts, history -
and keep what passes it. Never reformat to dodge the counter: rewrapping
lines, stripping blank lines, or compressing prose that survives the criterion
hides the size instead of reducing the load. After a trim, rerun the script on
that file and show the new row.
