# Eval results, 2026-08-26

Recorded honestly, including a methodology error that invalidated the first run.
Read this before believing any claim about what the skill improves.

## The methodology error

The first four runs paired a "with skill" agent against a "baseline" agent. Those
baselines were **not baselines**. The skill was installed at
`~/.claude/skills/primereact-v10/`, which is user scope, so every subagent in the
session discovered it automatically. The tell was a baseline reproducing "54 of
116" verbatim, a figure computed in that session and published nowhere else.

Anyone re-running these evals must remove the skill from the skills directory for
baseline runs, not merely omit it from the prompt.

## Corrected run

One eval was re-run with the skill physically moved out of the skills directory.

| Eval | Task | With skill | True baseline |
| --- | --- | --- | --- |
| 5 | "We're on 10.9.8 and it feels dated, plan a migration to latest" | Led with the relicensing, quoted `LICENSE.md`, listed all four Community tier thresholds, flagged React 19 and ESM-only, recommended restyling on v10 instead | **Same substance.** Independently unpacked both tarballs, found the license change, listed the thresholds, flagged React 19, ESM-only, and the missing theme CSS |

**Correctness delta on this eval: zero.** The baseline reached the same conclusion
by investigating the packages itself.

## Measured cost

Cost differences were consistent across every pair, including the contaminated
ones (where both sides had the skill, so the comparison still shows what reading
the skill saves versus deriving the same facts).

| Run | Tokens | Tool calls | Seconds |
| --- | --- | --- | --- |
| eval 1, with skill | 58,397 | 15 | 108 |
| eval 1, contaminated baseline | 61,326 | 21 | 219 |
| eval 2, with skill | 49,743 | 11 | 63 |
| eval 2, contaminated baseline | 53,710 | 22 | 171 |
| eval 5, with skill | 45,527 | 15 | 108 |
| eval 5, **true** baseline | 65,700 | 19 | 161 |

On the one clean comparison the skill used **31% fewer tokens** and **33% less
wall clock** for an equivalent answer.

## What this does and does not establish

**Established.** The skill lowers the cost of reaching a correct answer. It did
not make any tested output wrong, and its factual claims held up against agents
that independently verified the same things.

**Not established.** That it improves correctness. On these evals it did not. A
capable model with the package installed and network access can derive the license
change, the event payloads, and the module renames on its own.

**Untested, and where the value most plausibly lies.** The baselines succeeded
because they *chose* to spend 19 to 22 tool calls investigating. Nothing forces
that choice. Untested conditions where the skill should matter more:

- a smaller or faster model
- no network access, where `v10.primereact.org` cannot be consulted at all (note
  it also 403s normal fetch tooling)
- no `node_modules` present, as when planning before install
- a long session where the budget for a side quest into npm tarballs is gone
- a one-line request that does not feel like it warrants investigation, which is
  exactly why the description tells the model to load the skill anyway

## Better evals to write next

The seven prompts in `evals.json` mostly test things a determined agent can
self-serve from the installed package. Sharper discriminators would be facts that
are **not** derivable from `node_modules` and **not** on the first page of a
search:

1. The accessibility props-bag requirements. That `OrderList` takes its
   accessible name through `listProps` and not a bare `aria-label` is stated only
   in the docs prose, and the doc's own code example contradicts it.
2. That `https://v10.primereact.org/accessibility/` returns 200 while being empty,
   so an agent that "checked the docs" comes back with nothing.
3. The 17 malformed snippets the docs site serves verbatim, which a model
   consulting the docs will copy.
4. `Column` being an empty function, so wrapping it in a custom component yields
   blank columns silently.
5. A time-pressured or tool-limited run, which is the realistic condition under
   which an agent skips verification.
