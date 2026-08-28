# Directives and functions

Everything v4 exposes to your CSS. Run `node "$TW4" version` first: the
compatibility directives at the bottom mean a project can be half-migrated, and
which half matters.

## Core directives

| Directive | Purpose |
| --- | --- |
| `@import "tailwindcss";` | pull in the framework; replaces all three `@tailwind` directives |
| `@theme { … }` | define design tokens that generate utilities |
| `@source "…";` | register files the automatic scanner misses |
| `@utility name { … }` | define a custom utility that supports variants |
| `@variant name { … }` | apply a Tailwind variant inside your own CSS |
| `@custom-variant name (…);` | define a new variant |
| `@apply …;` | inline existing utilities into a custom rule |
| `@reference "…";` | make theme, utilities and variants visible to a separately compiled file |

### `@import`

```css
@import "tailwindcss";
@import "tailwindcss" prefix(tw);          /* every class becomes tw:… */
@import "tailwindcss" source("../src");    /* set the scan root */
@import "tailwindcss" source(none);        /* scan nothing automatically */
```

Tailwind bundles imports itself; `postcss-import` is not needed and should be
removed.

### `@utility`

The replacement for v3's `@layer utilities` and `@layer components`. Use it for
every custom class that should work with variants.

```css
@utility tab-4 {
  tab-size: 4;
}
```

Custom utilities are sorted by how many properties they declare, so a
component-shaped utility can be overridden by a single-property utility without
any `!important` juggling:

```css
@utility btn {
  border-radius: 0.5rem;
  padding: 0.5rem 1rem;
  background-color: ButtonFace;
}
```

`class="btn rounded-none"` then wins on the radius, which is what you want and
what `@layer components` could not do.

### Functional `@utility`

A trailing `-*` makes the utility take an argument, resolved by `--value()`.

```css
@utility tab-* {
  tab-size: --value(--tab-size-*);      /* matches theme keys: tab-2, tab-github */
}

@utility tab-* {
  tab-size: --value(integer);           /* bare values: tab-1, tab-76 */
}

@utility tab-* {
  tab-size: --value("inherit", "initial");  /* literals: tab-inherit */
}

@utility tab-* {
  tab-size: --value([integer]);         /* arbitrary: tab-[76] */
}
```

Bare value types: `number`, `integer`, `ratio`, `percentage`.

Arbitrary value types: `absolute-size`, `angle`, `bg-size`, `color`,
`family-name`, `generic-name`, `image`, `integer`, `length`, `line-width`,
`number`, `percentage`, `position`, `ratio`, `relative-size`, `url`, `vector`, `*`.

Support all three at once by listing them; declarations that fail to resolve are
dropped from the output:

```css
@utility tab-* {
  tab-size: --value(--tab-size-*, integer, [integer]);
}
```

Use separate declarations when the forms need different treatment:

```css
@utility opacity-* {
  opacity: --value([percentage]);
  opacity: calc(--value(integer) * 1%);
  opacity: --value(--opacity-*);
}
```

`--modifier()` reads the part after a `/`, and `--default()` inside `--value()`
supplies a value for the bare form. `--default()` requires 4.3.0.

### `@custom-variant` and `@variant`

`@custom-variant` defines; `@variant` uses.

```css
@custom-variant dark (&:where(.dark, .dark *));
@custom-variant theme-midnight (&:where([data-theme="midnight"] *));

.my-element {
  background: white;
  @variant dark { background: black; }
}
```

Stacked and compound forms inside `@variant` (`@variant hover:focus { … }`,
`@variant hover, focus { … }`) require 4.3.0.

### `@source`

```css
@source "../node_modules/@acme/ui";         /* scan something normally ignored */
@source not "../src/legacy";                /* skip a directory      (4.1.0+) */
@source inline("underline");                /* safelist              (4.1.0+) */
@source inline("{hover:,focus:,}underline");        /* with variants */
@source inline("bg-red-{50,{100..900..100},950}");  /* brace expanded */
@source not inline("bg-red-500");                   /* force-exclude */
```

`@source inline()` is the v4 safelist. The v3 `safelist` key does not work, not
even through `@config`.

Scanning skips `.gitignore`d paths, `node_modules`, binary files, CSS files, and
lock files. `@source` overrides that. Since 4.1.0, a `@source` naming a file
extension or a path inside `node_modules` ignores `.gitignore`.

### `@reference`

A Vue, Svelte or Astro `<style>` block, and every CSS module, is compiled
separately and cannot see your theme. `@apply text-brand` there fails.

```html
<style>
  @reference "../../app.css";
  h1 { @apply text-2xl font-bold text-brand; }
</style>
```

Point it at your real entry stylesheet, not at `tailwindcss`, unless the project
has no customization at all. Referencing a file re-parses it for every block that
does so, which is why using `var(--color-brand)` directly is faster and usually
better.

## Build-time functions

| Function | Purpose |
| --- | --- |
| `--alpha(<color> / <pct>)` | `color-mix(in oklab, <color> <pct>, transparent)` |
| `--spacing(<n>)` | `calc(var(--spacing) * <n>)` |
| `theme(--var-name)` | deprecated; only still needed inside media queries |

```css
.my-element {
  color: --alpha(var(--color-lime-300) / 50%);
  margin: --spacing(4);
}

@media (width >= theme(--breakpoint-xl)) { … }
```

`--spacing()` also works inside arbitrary values:
`py-[calc(--spacing(4)-1px)]`.

Prefer plain `var(--color-red-500)` over `theme(colors.red.500)`. The v3 dot-path
form is gone; `theme()` now takes the variable name.

## Compatibility directives

These exist to ease migration. Reaching for one is a decision to stay on the v3
model for that piece.

| Directive | Purpose |
| --- | --- |
| `@config "…";` | load a legacy `tailwind.config.js` |
| `@plugin "…";` | load a legacy JavaScript plugin |

```css
@config "../../tailwind.config.js";
@plugin "@tailwindcss/typography";
```

Neither is auto-detected. A `tailwind.config.js` with no `@config` pointing at it
is inert. `corePlugins`, `safelist` and `separator` are ignored even when the
config is loaded. CSS-side definitions merge with, and take precedence over,
anything from a config, preset or plugin, so migrating one namespace at a time
works.

`@import`, `@reference`, `@plugin` and `@config` all support Node subpath imports
(`@reference "#app.css";` against an `imports` map in `package.json`) under the
CLI, Vite and PostCSS.
