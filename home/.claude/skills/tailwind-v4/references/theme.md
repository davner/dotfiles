# Theming in v4

There is no `tailwind.config.js`. The design system is CSS variables inside
`@theme`, and each namespace generates a family of utilities.

## The rule that explains everything

A theme variable in a recognized namespace *creates the utility*. Defining
`--color-brand` is what makes `bg-brand`, `text-brand`, `border-brand`,
`ring-brand`, `fill-brand` and the rest exist. Nothing else is needed.

```css
@import "tailwindcss";

@theme {
  --color-brand: oklch(0.7 0.2 200);
  --font-display: "Satoshi", sans-serif;
  --breakpoint-3xl: 120rem;
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);
}
```

That yields `bg-brand`, `font-display`, the `3xl:*` variant, and `ease-snappy`.

`@theme` must be top level. It cannot be nested inside a selector or a media
query. Use `:root` for a plain CSS variable that should *not* produce a utility;
use `@theme` when you want the utility.

## Namespaces

| Namespace | What it generates |
| --- | --- |
| `--color-*` | every color utility: `bg-*`, `text-*`, `border-*`, `ring-*`, `fill-*`, `stroke-*`, `shadow-*`, `accent-*`, … |
| `--font-*` | font family utilities like `font-sans` |
| `--text-*` | font size utilities like `text-xl` |
| `--font-weight-*` | font weight utilities like `font-bold` |
| `--tracking-*` | letter spacing utilities like `tracking-wide` |
| `--leading-*` | line height utilities like `leading-tight` |
| `--tab-size-*` | tab size utilities like `tab-github` |
| `--breakpoint-*` | responsive variants like `sm:*` |
| `--container-*` | container query variants like `@sm:*`, and `max-w-md` |
| `--spacing-*` | spacing and sizing: `px-4`, `max-h-16`, and many more |
| `--radius-*` | `rounded-sm` and friends |
| `--shadow-*` | `shadow-md` |
| `--inset-shadow-*` | `inset-shadow-xs` |
| `--drop-shadow-*` | `drop-shadow-md` |
| `--text-shadow-*` | `text-shadow-lg` (4.1.0+) |
| `--blur-*` | `blur-md` |
| `--perspective-*` | `perspective-near` |
| `--zoom-*` | `zoom-compact` (4.3.0+) |
| `--aspect-*` | `aspect-video` |
| `--ease-*` | `ease-out` |
| `--animate-*` | `animate-spin` |

Run `node "$TW4" theme` to print what a specific project actually resolves,
including its own additions.

## Shipped defaults worth knowing

Read `node_modules/tailwindcss/theme.css` for the full set rather than recalling
values. As shipped in 4.3.3:

| Variable | Value |
| --- | --- |
| `--spacing` | `0.25rem` (the single unit every `p-*`, `m-*`, `w-*` step multiplies) |
| `--breakpoint-sm` | `40rem` |
| `--breakpoint-md` | `48rem` |
| `--breakpoint-lg` | `64rem` |
| `--breakpoint-xl` | `80rem` |
| `--breakpoint-2xl` | `96rem` |
| `--radius-xs` … `--radius-4xl` | `0.125rem`, `0.25rem`, `0.375rem`, `0.5rem`, `0.75rem`, `1rem`, `1.5rem`, `2rem` |

Colors are OKLCH, not hex or RGB. The families shipped in 4.3.3 are: `red`,
`orange`, `amber`, `yellow`, `lime`, `green`, `emerald`, `teal`, `cyan`, `sky`,
`blue`, `indigo`, `violet`, `purple`, `fuchsia`, `pink`, `rose`, `slate`, `gray`,
`zinc`, `neutral`, `stone`, plus `mauve`, `olive`, `mist` and `taupe` added in
4.2.0, and `black` / `white`. Each numbered family runs 50 through 950.

Because `--spacing` is a single multiplier, arbitrary steps work without
configuration: `p-13` and `mt-0.5` resolve to `calc(var(--spacing) * 13)` and
`calc(var(--spacing) * 0.5)`. There is no spacing scale to extend.

## Overriding and removing

Redefine to override:

```css
@theme {
  --breakpoint-sm: 30rem;
}
```

Wipe one namespace and supply your own, so no default survives:

```css
@theme {
  --color-*: initial;
  --color-white: #fff;
  --color-midnight: #121063;
}
```

Wipe the entire default theme:

```css
@theme {
  --*: initial;
  --spacing: 4px;
  --color-lagoon: oklch(0.72 0.11 221.19);
}
```

After `--color-*: initial`, `bg-red-500` no longer exists. That is the point, but
it means every existing class using a default color stops generating CSS with no
error. Grep before doing it.

## Three modifiers on `@theme`

| Form | Effect | Use when |
| --- | --- | --- |
| `@theme { … }` | normal | almost always |
| `@theme inline { … }` | utilities embed the value, not the `var()` reference | the variable points at another variable |
| `@theme static { … }` | emit every variable even if unused | something outside Tailwind reads the variables |

`inline` matters more than it looks. Writing `--font-sans: var(--font-inter)`
without it makes `font-sans` resolve `--font-inter` at the point `--font-sans` was
declared, which is usually `:root`, where a font variable injected deeper in the
tree does not exist yet. The text then falls back silently. Any theme variable
that references another variable, which includes every `next/font` and
`@fontsource` setup, wants `@theme inline`.

## Keyframes

Define them inside `@theme` next to the `--animate-*` variable, and they are
emitted only when the animation is used:

```css
@theme {
  --animate-fade-in: fade-in 0.3s ease-out;

  @keyframes fade-in {
    from { opacity: 0; }
    to   { opacity: 1; }
  }
}
```

A `@keyframes` defined outside `@theme` is always emitted.

## Reading theme values elsewhere

There is no `resolveConfig()`. The values are CSS variables at runtime:

```js
const shadow = getComputedStyle(document.documentElement).getPropertyValue('--shadow-xl')
```

In CSS, use the variable directly rather than the deprecated `theme()` function.
The one place `theme()` is still needed is a media query, where CSS variables are
not allowed, and it takes the variable name rather than v3's dot path:

```css
@media (width >= theme(--breakpoint-xl)) { … }
```

## Sharing a theme

A theme is a CSS file, so sharing it is an import:

```css
@import "tailwindcss";
@import "../../packages/brand/theme.css";
```
