# tailwind-v4

An Agent Skill that keeps Claude correct in Tailwind CSS v4 codebases.

## Why it exists

v4 replaced the JavaScript config with CSS, renamed a large part of the class
surface, and changed the meaning of several class names that still compile. None
of that produces an error. A model working from recalled "Tailwind" knowledge
writes v3, the build exits 0, and the result is an empty stylesheet, an ignored
design system, or a declaration that parses and does nothing.

The four failures the skill leads with, all reproduced against 4.3.3:

| Input | What happens |
| --- | --- |
| `@tailwind base/components/utilities` | 66-byte stylesheet, exit 0 |
| `tailwind.config.js` with no `@config` | the whole theme is ignored, no diagnostic |
| `bg-[--brand]` | emits `background-color: --brand`, an invalid value |
| `.foo` in `@layer utilities` | bare class works, every variant silently missing |

## What it does

- **Guards the version.** Reports the installed `tailwindcss` at load time and
  refuses to apply below v4, since almost every rule in it is wrong for v3.
- **Verifies instead of recalling.** `scripts/tw4.mjs` compiles a candidate class
  against the project's own installed Tailwind *and its own stylesheet*, so a
  project `@theme` color, `@utility` and `@custom-variant` all resolve. Tailwind
  ships no CLI for this; the compiler is reachable only through a Node API.
- **Carries the version floors.** v4 is four minors wide. A `text-shadow-*` class
  needs 4.1, `zoom-*` needs 4.3, and in an older project each generates nothing.

## Layout

| Path | Contents |
| --- | --- |
| `SKILL.md` | version guard, the four silent failures, the rules, the workflow |
| `scripts/tw4.mjs` | `version`, `check`, `css`, `variants`, `search`, `theme` |
| `references/version-delta.md` | v3 to v4: removed, renamed, changed behavior |
| `references/theme.md` | `@theme`, namespaces, defaults, `inline` and `static` |
| `references/directives.md` | every directive and build-time function |
| `references/variants.md` | the full variant list, stacking order, dark mode |
| `references/version-floors.md` | which v4 minor added which feature |
| `references/setup.md` | wiring per build tool, and migrating a v3 config |
| `references/gotchas.md` | verified failures that report nothing |

## The script

```sh
node scripts/tw4.mjs version                    # installed version, integrations, entry CSS
node scripts/tw4.mjs check flex bg-brand        # exit 1 if any is not a utility
node scripts/tw4.mjs css text-shadow-lg         # the CSS it compiles to
node scripts/tw4.mjs variants                   # every variant available here
node scripts/tw4.mjs search '^mask-'            # find classes by pattern
node scripts/tw4.mjs theme '^--color-'          # resolved theme variables
```

It walks up from the working directory to find `node_modules/tailwindcss`, so run
it inside the project or pass `--cwd`. `--css` points it at a specific entry
stylesheet when the guess is wrong. On a v3 project it reports the version and
declines; with no Tailwind resolved it says so and exits 2.

## Sources

Every factual claim was checked against tailwindcss 4.3.3 rather than recalled:
the shipped `theme.css` and `preflight.css`, the compiler's own
`candidatesToCss`, real CLI builds for the silent-failure cases, and the
CHANGELOG for the version floors. The prose docs come from the MDX sources at
`github.com/tailwindlabs/tailwindcss.com`. There is no `llms.txt` and no MCP
server for Tailwind; `tailwindcss.com/llms.txt` returns 404.

Where the published upgrade guide and the installed compiler disagree, the skill
records both. `overflow-ellipsis`, `decoration-slice` and `decoration-clone` are
listed as removed and still compile in 4.3.3.
