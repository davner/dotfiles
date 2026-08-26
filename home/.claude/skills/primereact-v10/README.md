# primereact-v10

An Agent Skill that makes an LLM reliably correct in **PrimeReact v10** codebases.

PrimeReact v11 renamed or removed most of the library and moved to a commercial
license. That makes a model's recollection of "current" PrimeReact actively wrong in
a v10 project: only **54 of 116** v10 module paths still exist in v11. This skill
pins the agent to what v10 actually ships, using the copy installed in the project
as the source of truth.

## What it does

| Problem | What the skill does |
| --- | --- |
| Model writes `primereact/datepicker`, which does not exist in v10 | Ships the full v10-versus-v11 name delta and tells the agent to verify module names before importing |
| Model suggests upgrading to v11 | Documents that v10.9.8 is the last MIT release and v11 requires a paid license key |
| Model guesses props | Bundles a script that reads props and defaults out of the project's own `node_modules` `.d.ts` |
| `onChange={e => set(e.value)}` silently sets `null` on a Checkbox | Documents every component's real event payload, read from the runtime source |
| Model omits accessible names | Documents the per-component labelling contract, including the components where `aria-label` must go in a props bag |
| Model can't reach the docs | The v10 docs site 403s normal fetch tooling; the skill supplies a working invocation and bundles 1,536 offline examples |

## Install

Copy or clone the directory to one of:

| Scope | Path |
| --- | --- |
| Personal, all projects | `~/.claude/skills/primereact-v10/` |
| One project | `<repo>/.claude/skills/primereact-v10/` |

```sh
git clone <this-repo> ~/.claude/skills/primereact-v10
```

Claude Code discovers it automatically. If you manage dotfiles with home-manager,
link the individual skill directory rather than `~/.claude/skills/` as a whole, or
the link will displace any other skills installed there. Invoke it with `/primereact-v10`, or let it
trigger on its own when a project imports from `primereact/*`.

Requires `node` on PATH for the version-detection block, and `bash` for the lookup
script. Neither needs to be installed globally beyond what a React project already
has.

## Layout

```
SKILL.md                     router, hard rules, workflow  (205 lines)
scripts/pr10.sh              read the API out of node_modules
references/
  version-delta.md           what v11 renamed and removed
  components.md              full inventory by category, with doc URLs
  events.md                  every onChange payload, verified at the call site
  datatable.md               DataTable, Column, and its three silent failures
  theming.md                 themes, config, PassThrough, Tailwind layers
  accessibility.md           per-component labelling requirements
  gotchas.md                 verified runtime surprises
examples/                    1,536 snippets from the v10 showcase (MIT, see NOTICE)
evals/                       test prompts and assertions
```

## Using the lookup script directly

The script walks up from your working directory to find `node_modules/primereact`,
so run it from inside the project and give it an absolute path.

```sh
cd ~/my-app
PR10=~/.claude/skills/primereact-v10/scripts/pr10.sh

bash "$PR10" version                 # what is actually installed
bash "$PR10" list                    # all 116 shipped modules
bash "$PR10" find switch             # locate a module by partial name
bash "$PR10" props InputSwitch       # Props interface with JSDoc
bash "$PR10" prop Button severity    # one prop and its default
bash "$PR10" events DataTable        # callbacks only
```

Every subcommand exits 0 even when nothing is found, because a non-zero exit inside
a `SKILL.md` injection block aborts the whole skill invocation.

## How the facts were established

Everything in the reference files was verified against primary sources rather than
recalled:

- **Version delta** - diffing the published npm tarballs of `primereact@10.9.8` and
  `primereact@11.1.0`.
- **Licensing** - the `license` field of each published package and the verbatim
  text of v11's `LICENSE.md`.
- **Event payloads and runtime behavior** - reading the object literal passed to
  each callback in the shipped `.esm.js`, with file and line recorded.
- **Accessibility** - the `#accessibility` section of all 94 v10 component doc
  pages plus `/guides/accessibility/`.
- **Examples** - extracted from the archived repo at tag `10.9.8` with a Babel
  parser, then checked byte-for-byte against what the live docs site serves (89 of
  89 blocks matched exactly).

Statements were read from source rather than observed in a running React app. The
reference files mark anything inferred rather than verified, and the probable v11
rename mappings are explicitly labelled as inference, since no public migration
guide exists.

## What the evals actually showed

`evals/RESULTS.md` records the measurements, including a methodology error that
invalidated the first round. The short version, so this README does not overclaim:

On a clean comparison the skill used **31% fewer tokens and 33% less wall clock**
to reach an equivalent answer. It did **not** improve correctness on the tasks
tested, because a capable model with the package installed and network access
derived the same facts on its own in 19 to 22 tool calls.

The value is therefore a lower floor and a lower cost, not a higher ceiling: the
baseline succeeded because it chose to investigate, and nothing forces that
choice. The conditions where the skill should matter most, and which remain
untested, are a smaller model, no network access, no `node_modules` yet, or a
request small enough that no one would think to check.

## Licensing

The skill itself is MIT; see `LICENSE`.

The contents of `examples/` are extracted from
[primefaces/primereact](https://github.com/primefaces/primereact) at tag `10.9.8`
and remain under PrimeTek's MIT license. `NOTICE` reproduces that license in full,
as MIT requires. The archived upstream README states that "Existing MIT versions
remain MIT, forever."

`components/templates/` from that repository is a **paid** product and is
deliberately not included.
