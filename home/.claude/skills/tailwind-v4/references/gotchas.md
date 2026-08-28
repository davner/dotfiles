# Verified surprises

Each entry was reproduced against tailwindcss 4.3.3 by compiling the input and
reading the output. They share one property: **nothing reports them**. The build
exits 0 and the CSS is wrong or absent.

## The build succeeds and the stylesheet is empty

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Output: 66 bytes, containing only
`/*! tailwindcss v4.3.3 | MIT License | https://tailwindcss.com */`. Exit code 0.

This is the single most destructive v3 leftover, and the symptom people report is
"Tailwind isn't working" rather than anything pointing at the directives.

## The design system is ignored and nothing says so

A `tailwind.config.js` with a full `theme.extend` block, and a stylesheet that
does not name it, compiles to zero custom rules. Verified: a config defining
`colors.squid` plus markup using `bg-squid` produced no `.bg-squid` rule and no
diagnostic.

v4 does not auto-detect a JS config. Either port the theme to `@theme`, or add
`@config "../../tailwind.config.js";`.

## `bg-[--brand]` compiles to nothing usable

| Written | Emitted |
| --- | --- |
| `bg-[--brand]` | `background-color: --brand` |
| `bg-(--brand)` | `background-color: var(--brand)` |

The first is a syntactically valid declaration with an invalid value, so it
parses, ships, and does nothing. Applies to every utility, not just `bg-*`.

## `grid-cols-[max-content,auto]` produces invalid track syntax

| Written | Emitted |
| --- | --- |
| `grid-cols-[max-content,auto]` | `grid-template-columns: max-content,auto` |
| `grid-cols-[max-content_auto]` | `grid-template-columns: max-content auto` |

v3 rewrote commas to spaces in `grid-*` and `object-*` arbitrary values for v2
compatibility. v4 does not. Use underscores.

## A custom utility in `@layer utilities` loses every variant

```css
@layer utilities { .zorble { outline-offset: 7px; } }
```

Generates `.zorble` and nothing else. `hover:zorble` and `md:zorble` produce no
CSS. The bare class working is what hides it.

```css
@utility zorble { outline-offset: 7px; }
```

Generates `.zorble`, `.hover\:zorble:hover`, and `.md\:zorble`.

## Bare scale utilities are frozen and ignore your theme

| Class | Emits |
| --- | --- |
| `rounded` | `border-radius: 0.25rem` (a literal) |
| `rounded-sm` | `border-radius: var(--radius-sm)` |
| `blur` | `--tw-blur: blur(8px)` (a literal) |
| `blur-sm` | `--tw-blur: blur(var(--blur-sm))` |

Customizing `--radius-sm` moves `rounded-sm` and leaves `rounded` behind. The
bare names are v3 compatibility aliases, not scale members. Never mix
`rounded` and `rounded-sm` in one design expecting them to track together.

## `focus:outline-none` now removes the focus ring

In v3 `outline-none` set a transparent outline that remained visible in
forced-colors mode. In v4 that is `outline-hidden`, and `outline-none` sets
`outline-style: none` for real.

A v3 codebase migrated without touching class names keeps every
`focus:outline-none` and loses the forced-colors focus indicator. This is an
accessibility regression that no build step, linter or type checker reports.

## Stacked variant order silently changed meaning

Both compile, to different selectors:

| Class | Selector |
| --- | --- |
| `*:first:pt-0` | `:is(.… > *):first-child` |
| `first:*:pt-0` | `:is(.…:first-child > *)` |

v3 read right to left, v4 reads left to right. A v3 `first:*:pt-0` carried over
now styles every child of a first-child element instead of the first child.

## `space-y-*` has zero specificity

4.3.3 compiles `space-y-4` to
`:where(.space-y-4 > :not(:last-child)) { margin-block-start: …; margin-block-end: … }`.

Two consequences. The `:where()` means any competing rule wins, including ones
that lost in v3. And it targets all-but-last rather than all-but-first, using
logical properties, so writing-mode and existing child margins behave
differently. If it fights you, use `flex`/`grid` with `gap`.

## `hover:` never fires on touch devices

v4 wraps it in `@media (hover: hover)`. A tap-to-reveal UI that worked in v3
stops. Override with `@custom-variant hover (&:hover);` if the design genuinely
depends on it.

## Borders and rings inherit the text color

v3 preflight set an explicit `border-color: theme(colors.gray.200)`. v4 preflight
resets with `border: 0 solid` and names no color, so the CSS initial value
`currentColor` applies. `ring` likewise compiles to
`var(--tw-ring-color, currentcolor)` at 1px, where v3 gave `blue-500` at 3px.

A bare `border` therefore follows the text color, and both look plausible enough
in review to reach production. Name the color: `border border-gray-200`.

## `@apply` fails in component style blocks

A Vue, Svelte or Astro `<style>` block, and any CSS module, is compiled as a
separate stylesheet with no view of your theme. `@apply text-brand` there errors
or resolves to nothing depending on the setup. Add `@reference "…/app.css";` at
the top of the block, or use `var(--color-brand)` and skip `@apply`.

## `@theme` referencing another variable resolves in the wrong scope

```css
@theme { --font-sans: var(--font-inter); }     /* wrong */
@theme inline { --font-sans: var(--font-inter); }  /* right */
```

Without `inline`, `var(--font-sans)` resolves where `--font-sans` was declared,
usually `:root`, and a font variable injected further down the tree does not
exist there. The text falls back to the generic family with no error. This hits
every `next/font` integration.

## Dynamic class names generate nothing

Tailwind scans source files as plain text and never evaluates them.

```jsx
<div className={`bg-${color}-600`} />        {/* generates nothing */}
```

Map props to whole class names instead. For a class that genuinely never appears
literally, `@source inline("…")` is the safelist.

## `tab-*` became a built-in utility in 4.3.0

Most `@utility` examples in the wild, including Tailwind's own documentation, use
`tab-4` as the sample name. On 4.3.0 and newer that collides with the real
`tab-size` utility, and the output contains both rules. Pick a different name for
a custom utility.

## The upgrade guide's removed list is not accurate for current v4

It lists `overflow-ellipsis`, `decoration-slice` and `decoration-clone` as
removed. In 4.3.3 all three still compile. The `*-opacity-*` utilities in the
same table genuinely are gone. Do not write the deprecated names, but do not
treat one you find in a codebase as a build error.
