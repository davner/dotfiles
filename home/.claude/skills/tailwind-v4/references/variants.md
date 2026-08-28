# Variants

The complete built-in set as of 4.3.3, 88 variants before any project adds its
own. Run `node "$TW4" variants` to print what a specific project has, which is
the only way to see its `@custom-variant` additions and extra breakpoints.

## Stacking order changed in v4

v3 applied stacked variants right to left; v4 applies them left to right, to read
like CSS. Both orders still compile, to different selectors, so nothing warns you:

| Class | Selector in 4.3.3 | Means |
| --- | --- | --- |
| `*:first:pt-0` | `:is(.… > *):first-child` | the first child |
| `first:*:pt-0` | `:is(.…:first-child > *)` | every child of a first-child element |

v3's `first:*:pt-0` is v4's `*:first:pt-0`. Only order-sensitive stacks are
affected, which in practice means the child variants `*` and `**`, and plugin
variants like `prose-headings`.

## The full list

**Structural**: `*` (direct children), `**` (all descendants)

**Pseudo-elements**: `before`, `after`, `first-letter`, `first-line`, `marker`,
`selection`, `file`, `placeholder`, `backdrop`, `details-content`

**Position among siblings**: `first`, `last`, `only`, `odd`, `even`,
`first-of-type`, `last-of-type`, `only-of-type`, `empty`, and the functional
`nth-*`, `nth-last-*`, `nth-of-type-*`, `nth-last-of-type-*`

**Interaction**: `hover`, `focus`, `focus-within`, `focus-visible`, `active`,
`visited`, `target`

**Form and element state**: `disabled`, `enabled`, `checked`, `indeterminate`,
`default`, `required`, `optional`, `valid`, `invalid`, `user-valid`,
`user-invalid`, `in-range`, `out-of-range`, `read-only`, `placeholder-shown`,
`autofill`, `open`, `inert`

**Relational**: `group-*`, `peer-*`, `has-*`, `in-*`, `not-*`

**Attribute**: `aria-*`, `data-*`, `supports-*`

**Breakpoints**: `sm`, `md`, `lg`, `xl`, `2xl`, plus `min-*` and `max-*`, and any
`--breakpoint-*` the project defines

**Container queries**: `@sm` … `@7xl` via `@`, plus `@min-*` and `@max-*`

**Media and environment**: `dark`, `print`, `portrait`, `landscape`, `ltr`, `rtl`,
`motion-safe`, `motion-reduce`, `contrast-more`, `contrast-less`, `forced-colors`,
`inverted-colors`, `noscript`, `starting`

**Pointer**: `pointer-none`, `pointer-coarse`, `pointer-fine`,
`any-pointer-none`, `any-pointer-coarse`, `any-pointer-fine`

Several of these arrived after 4.0. Check
[version-floors.md](version-floors.md) before using `details-content`,
`inverted-colors`, `noscript`, `user-valid`, `user-invalid`, or any `pointer-*`.

## `hover` is gated behind a media query

v4 compiles `hover:` to `@media (hover: hover) { … }`, so it never fires on a
touch device. If a UI depends on tap-to-hover, override it:

```css
@custom-variant hover (&:hover);
```

Prefer treating hover as an enhancement instead.

## Dark mode

The default `dark` variant follows `prefers-color-scheme`. There is no
`darkMode: 'class'` key; you override the variant.

```css
@custom-variant dark (&:where(.dark, .dark *));                  /* class */
@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));  /* attribute */
```

The `:where()` wrapper keeps specificity at zero so `dark:` utilities stay as
easy to override as their light counterparts. Do not drop it.

## Container queries

Built in, no plugin. `@container` marks the element; `@sm:` and friends query the
nearest marked ancestor. The sizes come from the `--container-*` namespace, which
is also what `max-w-*` reads.

```html
<div class="@container">
  <div class="flex flex-col @md:flex-row">…</div>
</div>
```

Named containers use `@container/name` and `@md/name:`. `@max-md:` is the upper
bound, and the two combine for a range.

## Custom variants

```css
@custom-variant theme-midnight (&:where([data-theme="midnight"] *));
```

Gives `theme-midnight:bg-black`. The `&` is the element the utility is on. Use
`:where()` to keep specificity flat unless you specifically want the weight.

## `not-*`, `in-*`, `has-*`

`not-*` negates a variant, a selector, or a media or feature query:
`not-hover:opacity-50`, `not-supports-[display:grid]:block`.

`in-*` styles based on an ancestor without needing `group` on it:
`in-focus:underline` applies when any ancestor has focus.

`has-*` is the CSS `:has()`: `has-checked:bg-indigo-50`.

`group-*` and `peer-*` still need the `group` or `peer` class on the other
element, and both accept an optional name (`group/item`, `group-hover/item:`).
