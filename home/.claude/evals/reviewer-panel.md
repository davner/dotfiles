# Seeded-defect eval for the reviewer panel

Answers two questions the timings TSV cannot: does each reviewer catch real
defects, and do the cheap model pins (sonnet/haiku) catch what opus would?
The method is Jesse Vincent's Superpowers regression test (5 trials per
variant, compare quality) applied per reviewer. Run it rarely - after a model
pin change, after a new Claude model generation, or on suspicion - not on a
schedule; each full pass costs roughly 10 subagent runs per reviewer.

## Procedure

1. Pick a real, already-merged diff of 100-300 lines from a project the
   reviewers normally see. Merged means the answer key is not polluted by
   genuine unknown defects.
2. Seed 5 known defects drawn from real past bugs, matched to the reviewer
   under test. Write the answer key (file, line, defect) before any run.
3. For each reviewer: 5 trials at its pinned model, 5 at opus, using the
   same prompt shape the ticket loop sends (spec inline, worktree path, diff
   scope). Fresh subagent per trial.
4. Score each trial: seeded defects caught, and false findings - findings
   not in the key that you judge non-gating under the correctness-only rule.
5. Append rows to `results.tsv` beside this file:
   `date  reviewer  model  trial  caught  of  false_findings  diff_ref`

## Defect types per reviewer

| Reviewer | Seed with |
|---|---|
| code-reviewer | logic inversion, off-by-one, swallowed error path, wrong variable reuse |
| migration-safety | irreversible step, missing down-migration, lock on a hot table |
| ui-verifier | wrong state after interaction, broken layout at one viewport, missing label, contrast failure, keyboard trap |
| comment-auditor | changelog comment, attribution, restated-code comment |

## Decision rules

| Result | Action |
|---|---|
| Cheap pin within 1 caught defect of opus (median of 5) | Pin stays |
| Cheap pin 2+ behind opus | Raise that one pin; re-run to confirm |
| A reviewer catches nothing the rest of the panel missed | Candidate to drop from the default panel; decide per its domain risk |
| False findings above ~2 per run | Tighten that reviewer's prompt against the correctness-only rule before touching its model |
