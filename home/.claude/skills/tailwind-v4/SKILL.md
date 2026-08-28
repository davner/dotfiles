---
name: tailwind-v4
description: Tailwind CSS v4 utility lookup, CSS-first theming, and version guardrails. Use whenever a project depends on tailwindcss v4, imports `tailwindcss` from CSS, or has an `@theme`, `@utility`, `@apply`, or `@custom-variant` rule - and for any CSS or class-name work in such a project, including writing markup with utility classes, editing a stylesheet, theming, dark mode, responsive or container queries, and build setup with Vite, PostCSS, or the CLI. Load this even for requests that look trivial, such as adding one class or changing one color, because v4 replaced the JavaScript config with CSS, renamed or removed a large part of the v3 class surface, and silently generates nothing for v3 syntax rather than failing, which makes recalled knowledge of "Tailwind" wrong in ways no build error reports.
allowed-tools: Bash(node *tw4.mjs*), Bash(node -e *), Bash(ls -d *), Bash(curl -sS *)
---

# Tailwind CSS v4

## What is actually installed here

```json
!`node -e "const fs=require('fs'),pa=require('path');const up=(n)=>{let d=process.cwd();for(;;){const p=pa.join(d,'node_modules',n);if(fs.existsSync(p))return p;const q=pa.dirname(d);if(q===d)return null;d=q}};const v=(p)=>{try{return JSON.parse(fs.readFileSync(pa.join(p,'package.json'),'utf8')).version}catch(e){return null}};const tw=up('tailwindcss');if(!tw){console.log(JSON.stringify({installed:null,note:'no tailwindcss resolved from '+process.cwd()},null,2));process.exit(0)}const ver=v(tw);const integ={};for(const n of ['@tailwindcss/vite','@tailwindcss/postcss','@tailwindcss/cli','@tailwindcss/webpack','@tailwindcss/typography','@tailwindcss/forms']){const d=up(n);if(d)integ[n]=v(d)}const cfg=['tailwind.config.js','tailwind.config.cjs','tailwind.config.mjs','tailwind.config.ts'].filter(f=>fs.existsSync(pa.join(process.cwd(),f)));console.log(JSON.stringify({installed:ver,major:parseInt(ver,10),integrations:integ,legacyJsConfig:cfg},null,2))" 2>/dev/null || echo '{"installed":null,"note":"node unavailable or errored"}'`
```

Read `installed` before doing anything else. It is the version on disk, which beats
the version anyone believes is in use.

- **`major` is `4`** - this skill applies. Proceed, but read
  [version-floors.md](references/version-floors.md) before using anything added
  after 4.0: a v4.0 project silently generates nothing for a 4.1 utility.
- **`major` is `3`** - this skill does NOT apply. Say so and stop using it. Almost
  every rule below is wrong for v3, starting with the config file.
- **`installed` is `null`** - dependencies may not be installed, or you are not in
  the project directory. Ask before assuming a version; do not guess from memory.
- **`legacyJsConfig` is non-empty** - a `tailwind.config.js` is present. In v4 that
  file does nothing unless a stylesheet names it with `@config`. See
  [the silent failures](#the-four-silent-failures) below.

## Verify the class, do not recall it

Tailwind ships no CLI that answers "does this class exist"; the compiler is
reachable only through a Node API. This skill bundles the script that asks it.

The script lives in this skill's directory and your working directory is the
user's project, so resolve it once per session and reuse the variable.

```bash
TW4=$(ls -d ~/.claude/skills/tailwind-v4/scripts/tw4.mjs \
            .claude/skills/tailwind-v4/scripts/tw4.mjs 2>/dev/null | head -1)

node "$TW4" version                      # installed version, integrations, entry CSS
node "$TW4" check flex bg-brand card-pad # does each class exist here? exit 1 if not
node "$TW4" css text-shadow-lg           # the CSS a class compiles to
node "$TW4" variants                     # every variant this project can use
node "$TW4" search '^mask-'              # find classes by pattern
node "$TW4" theme '^--color-brand'       # resolved theme variables
```

`check` answers against **this project's** stylesheet, so a custom `@theme` color,
a project `@utility`, and a project `@custom-variant` all resolve. It exits 1 if
any candidate is not a utility, so it works in a conditional. Run it before
writing an unfamiliar class, and always for anything in the rename tables.

If `$TW4` comes back empty the skill is installed elsewhere; fall back to the docs
below rather than guessing.

## The four silent failures

v4 does not error on v3 input. It compiles, exits 0, and produces the wrong thing.
These four are the reason this skill exists, and all four are verified against
tailwindcss 4.3.3:

**1. `@tailwind base/components/utilities` produces an empty stylesheet.** Not a
warning, not an error - a 66-byte file containing only the license comment. The
entire framework vanishes and the build succeeds. v4 imports as regular CSS:

```css
@import "tailwindcss";
```

**2. `tailwind.config.js` is ignored unless a stylesheet names it.** A v3 project
whose config carries the whole design system builds clean and drops all of it. If
the injected `legacyJsConfig` above is non-empty, check the entry CSS for
`@config` before touching anything:

```css
@config "../../tailwind.config.js";   /* compatibility, not the v4 way */
```

The v4 way is `@theme` in CSS. See [theme.md](references/theme.md).
`corePlugins`, `safelist`, and `separator` are not supported through `@config` at
all - safelist with `@source inline(…)` instead.

**3. `bg-[--brand]` compiles to `background-color: --brand`,** which is not a
value and does nothing. v4 changed the CSS-variable shorthand from square
brackets to parentheses. `bg-(--brand)` is the one that emits `var(--brand)`.
The same trap applies to every utility, and there is no diagnostic.

**4. A custom class in `@layer utilities` loses every variant.** In v3 that block
registered a real utility. In v4 it emits the bare rule and nothing else, so
`hover:zorble` and `md:zorble` generate no CSS while `zorble` still works - which
is what makes it hard to spot. Use `@utility`:

```css
/* v3: hover:zorble and md:zorble silently produce nothing */
@layer utilities { .zorble { outline-offset: 7px; } }

/* v4: all variants generated */
@utility zorble { outline-offset: 7px; }
```

## Where the truth lives

Work down this list. Stop at the first source that answers the question.

**1. `node "$TW4" check` / `css`.** Version-exact by construction, because it
compiles against the project's own installed Tailwind and its own stylesheet. Use
it for any question of the form "does this exist" or "what does this emit".

**2. The installed package's CSS.** `node_modules/tailwindcss/theme.css` is the
default theme - every `--color-*`, `--breakpoint-*`, `--spacing`, `--radius-*`,
`--shadow-*` and so on, as shipped. `preflight.css` is the base reset.
`index.css` shows the layer order the framework establishes. Read these rather
than recalling default values.

**3. The reference files in this skill**, for the v3-to-v4 delta and the traps
that neither the types nor a build error will tell you.

**4. The documentation site**, at `https://tailwindcss.com/docs/<page>`, for usage
shape. It documents the **latest** v4 only - there is no per-version docs site, so
a page may describe a utility your installed version does not have. Confirm with
`check` before using anything the page introduces. There is no `llms.txt`
(`/llms.txt` returns 404), so read pages individually. The docs source is MDX at
`github.com/tailwindlabs/tailwindcss.com` under `src/docs/`, which is easier to
read than the rendered HTML.

## Rules that prevent the common failures

**Never write a `tailwind.config.js` for a v4 project.** Theme customization is
CSS. Adding a color means adding a variable in the right namespace, and the
utility comes with it:

```css
@import "tailwindcss";

@theme {
  --color-brand: oklch(0.7 0.2 200);   /* creates bg-brand, text-brand, border-brand, … */
  --breakpoint-3xl: 120rem;            /* creates the 3xl:* variant */
  --font-display: "Satoshi", sans-serif;
}
```

The namespace decides which utilities appear. Full table in
[theme.md](references/theme.md).

**Check the class name before writing it.** v4 renamed the shadow, radius and blur
scales by shifting every step, so `shadow-sm` in v4 is v3's `shadow` and looks
visibly different from v3's `shadow-sm` (now `shadow-xs`). `outline-none` changed
meaning rather than disappearing. Full tables in
[version-delta.md](references/version-delta.md); the ones that bite hardest:

| If you are about to write | v4 wants | Why it matters |
| --- | --- | --- |
| `shadow-sm`, `rounded-sm`, `blur-sm` meaning the v3 value | `shadow-xs`, `rounded-xs`, `blur-xs` | compiles fine, renders bigger |
| `outline-none` meaning "invisible but focusable" | `outline-hidden` | `outline-none` now really removes the outline |
| `ring` meaning a 3px ring | `ring-3` | `ring` is 1px in v4 |
| `bg-gradient-to-r` | `bg-linear-to-r` | old name still works, emits different interpolation |
| `bg-opacity-50`, `text-opacity-50` | `bg-black/50`, `text-black/50` | the `*-opacity-*` utilities are gone |
| `!flex` | `flex!` | old position still works but is deprecated |
| `bg-[--brand]` | `bg-(--brand)` | silent no-op, see above |
| `grid-cols-[max-content,auto]` | `grid-cols-[max-content_auto]` | comma is no longer read as a space |

**Colors default to `currentColor`, not gray.** `border`, `divide-*` and `ring`
inherit the text color in v4 rather than defaulting to `gray-200` / `blue-500`.
A bare `border` that looked right in v3 will follow the text color here, so name
the color: `border border-gray-200`.

**Stacked variants read left to right.** v3 applied them right to left. `*:first:pt-0`
in v4 is v3's `first:*:pt-0`. Only order-sensitive stacks are affected.

**Class names must appear whole in the source.** Tailwind scans files as plain
text and never evaluates them, so `bg-${color}-600` generates nothing. Map props
to complete class names. To force a class that never appears literally, use
`@source inline("…")` - the v4 replacement for `safelist`.

**Dark mode by class is a variant override, not a config key.** There is no
`darkMode: 'class'`:

```css
@custom-variant dark (&:where(.dark, .dark *));
```

**`@apply` in a Vue/Svelte/Astro `<style>` block or a CSS module needs
`@reference`.** Those files are compiled separately and cannot see your theme, so
`@apply text-brand` fails there. Add `@reference "../../app.css";` at the top of
the block, or just use `var(--color-brand)` and skip `@apply` entirely.

**Do not add Sass, Less, or Stylus.** v4 is the preprocessor: it bundles
`@import`, flattens nesting through Lightning CSS, and adds vendor prefixes. It is
not designed to run through another preprocessor.

**Do not propose upgrading a v3 project without saying what it costs.** v4 requires
Safari 16.4+, Chrome 111+, Firefox 128+ and depends on `@property` and
`color-mix()`, so it does not degrade - it breaks on older browsers. A project on
v3.4 may be there on purpose. v3 is still maintained (3.4.19 shipped 2025-12-10).

## Picking the setup

| Build tool | Package | Wiring |
| --- | --- | --- |
| Vite | `@tailwindcss/vite` | `plugins: [tailwindcss()]` in `vite.config` - preferred over PostCSS |
| PostCSS | `@tailwindcss/postcss` | the only plugin needed; drop `postcss-import` and `autoprefixer` |
| CLI | `@tailwindcss/cli` | `npx @tailwindcss/cli -i in.css -o out.css` |
| Webpack | `@tailwindcss/webpack` | added in 4.2.0 |

In every case the stylesheet is `@import "tailwindcss";` and there is no
`content` array - source detection is automatic, minus `.gitignore`d paths,
`node_modules`, and binary and CSS files. Details and framework specifics in
[setup.md](references/setup.md).

## Workflow

1. **Read the injected version above.** Confirm `major` is 4, and note
   `legacyJsConfig`.
2. **Read the project's entry CSS** before editing anything. It carries the theme,
   the custom variants, and the custom utilities that this project's classes
   depend on. `node "$TW4" version` reports the path it found.
3. **Match the project's existing conventions.** Look at how sibling components
   name things and follow that rather than introducing a second pattern.
4. **Verify every unfamiliar class** with `node "$TW4" check` before writing it,
   and every class in the rename tables regardless of familiarity.
5. **Check the version floor** in [version-floors.md](references/version-floors.md)
   for anything newer than 4.0.
6. **Confirm the result compiles** by running the project's own build, not by
   reading the class list.

## Reference files

- [version-delta.md](references/version-delta.md) - everything v3 to v4: removed,
  renamed, and changed-behavior utilities, with what still silently works
- [theme.md](references/theme.md) - `@theme`, the namespace table, overriding and
  disabling defaults, and the shipped default values
- [directives.md](references/directives.md) - every `@` directive and build-time
  function, including the functional `@utility` value syntax
- [variants.md](references/variants.md) - the full variant list, stacking order,
  custom variants, dark mode, container queries
- [version-floors.md](references/version-floors.md) - which v4 minor added which
  utility, variant and directive
- [setup.md](references/setup.md) - install and wiring per build tool, and
  migrating a v3 config to CSS
- [gotchas.md](references/gotchas.md) - verified surprises that produce no error
