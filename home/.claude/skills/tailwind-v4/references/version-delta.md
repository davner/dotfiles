# What changed from v3 to v4

Everything here is verified against tailwindcss 4.3.3 by compiling the class and
reading what came out. Where the published upgrade guide and the installed
compiler disagree, both are stated.

## Removed: these generate nothing

The opacity utilities are genuinely gone. Writing one produces no rule and no
error, so the element keeps whatever opacity it had.

| Gone | Use instead |
| --- | --- |
| `bg-opacity-*` | `bg-black/50` |
| `text-opacity-*` | `text-black/50` |
| `border-opacity-*` | `border-black/50` |
| `divide-opacity-*` | `divide-black/50` |
| `ring-opacity-*` | `ring-black/50` |
| `placeholder-opacity-*` | `placeholder-black/50` |

## Still works, but deprecated

The upgrade guide lists these under "removed deprecated utilities". In 4.3.3 they
still compile. Do not write them in new code, but do not treat one you find as a
build error either.

| Deprecated name | Canonical name | 4.3.3 behavior |
| --- | --- | --- |
| `flex-shrink-*` | `shrink-*` | compiles, same output |
| `flex-grow-*` | `grow-*` | compiles, same output |
| `overflow-ellipsis` | `text-ellipsis` | compiles, same output |
| `decoration-slice` | `box-decoration-slice` | compiles, same output |
| `decoration-clone` | `box-decoration-clone` | compiles, same output |
| `bg-gradient-to-*` | `bg-linear-to-*` | compiles, but see below |
| `max-w-screen-*` | `max-w-(--breakpoint-*)` | compiles, reads `--breakpoint-*` |
| `!flex` (leading `!`) | `flex!` (trailing `!`) | compiles, same output |

`bg-gradient-to-r` and `bg-linear-to-r` are not identical. The old name emits
`--tw-gradient-position: to right in oklab`, the new one emits `to right` and
wraps the interpolation in an `@supports` guard. Mixing them in one project gives
two different gradient renderings.

## Renamed: the scales all shifted by one step

This is the change most likely to ship a visual regression, because every name
still exists and still compiles - it just means something bigger than it did.

| v3 | v4 | Note |
| --- | --- | --- |
| `shadow-sm` | `shadow-xs` | |
| `shadow` | `shadow-sm` | bare `shadow` still compiles, frozen at the v3 value |
| `drop-shadow-sm` | `drop-shadow-xs` | |
| `drop-shadow` | `drop-shadow-sm` | |
| `blur-sm` | `blur-xs` | |
| `blur` | `blur-sm` | bare `blur` still compiles, frozen at `blur(8px)` |
| `rounded-sm` | `rounded-xs` | |
| `rounded` | `rounded-sm` | bare `rounded` still compiles, frozen at `0.25rem` |
| `outline-none` | `outline-hidden` | `outline-none` was reused, see below |
| `ring` | `ring-3` | `ring` still compiles, now 1px |

**The bare names do not read your theme.** `rounded` emits a literal
`border-radius: 0.25rem`, while `rounded-sm` emits `var(--radius-sm)`. Customizing
`--radius-sm` moves `rounded-sm` and leaves `rounded` behind. The same holds for
bare `shadow` and bare `blur`. Treat the bare names as frozen v3 compatibility
aliases, not as part of the scale.

**`outline-none` changed meaning rather than disappearing.** In v3 it set an
invisible outline that still showed in forced-colors mode. In v4 that behavior is
`outline-hidden`, and `outline-none` now genuinely sets `outline-style: none`.
A v3 `focus:outline-none` carried over unchanged still compiles and now removes
the focus indicator outright, which is an accessibility regression no tool
reports. Change it to `focus:outline-hidden` unless removal is what you want.

## Changed defaults

| What | v3 | v4 |
| --- | --- | --- |
| `border-*` / `divide-*` color | `gray-200` | `currentColor` |
| `ring` width | 3px | 1px |
| `ring` color | `blue-500` | `currentColor` |
| Placeholder color | `gray-400` | current text color at 50% opacity |
| `button` cursor | `pointer` | `default` (browser default) |
| `<dialog>` margin | centered | reset like every other element |
| `hidden` attribute | `block`/`flex` overrode it | the attribute wins |
| `hover:` | always applied | only under `@media (hover: hover)` |

To restore v3 border and ring behavior without touching markup:

```css
@layer base {
  *, ::after, ::before, ::backdrop, ::file-selector-button {
    border-color: var(--color-gray-200, currentColor);
  }
}
@theme {
  --default-ring-width: 3px;
  --default-ring-color: var(--color-blue-500);
}
```

Those two `--default-*` variables exist for compatibility only and are not
idiomatic v4.

## Changed syntax

| Concern | v3 | v4 |
| --- | --- | --- |
| CSS variable in an arbitrary value | `bg-[--brand]` | `bg-(--brand)` |
| Spaces in `grid-*` / `object-*` arbitrary values | `[max-content,auto]` | `[max-content_auto]` |
| Important | `!flex`, `hover:!flex` | `flex!`, `hover:flex!` |
| Prefix | `tw-flex`, `hover:tw-flex` | `tw:flex`, `tw:hover:flex` |
| Stacked variant order | right to left (`first:*:pt-0`) | left to right (`*:first:pt-0`) |

Both syntax changes in the first two rows compile silently to something wrong.
`bg-[--brand]` emits `background-color: --brand`, which is not a value.
`grid-cols-[max-content,auto]` emits `grid-template-columns: max-content,auto`,
which is not valid track syntax.

A prefix is declared on the import, `@import "tailwindcss" prefix(tw);`, and it is
then mandatory: with it set, plain `flex` and `bg-brand` generate nothing at all.
Theme variables are still *written* unprefixed inside `@theme`; only the generated
CSS variables carry the prefix, so `--color-brand` is emitted as `--tw-color-brand`.

## Changed selectors

`space-x-*`, `space-y-*`, `divide-x-*` and `divide-y-*` moved off the
`> :not([hidden]) ~ :not([hidden])` selector for performance. In 4.3.3 they
compile to `:where(.space-y-4 > :not(:last-child))` using logical properties
(`margin-block-start` / `margin-block-end`).

Two consequences. The `:where()` wrapper means **zero specificity**, so these are
now trivially overridden by any other rule. And the last child is targeted rather
than the first, so extra margins on children behave differently. If either bites,
move to `flex`/`grid` with `gap`.

## Removed APIs

| Gone | Replacement |
| --- | --- |
| `@tailwind base/components/utilities` | `@import "tailwindcss";` |
| Auto-loaded `tailwind.config.js` | `@theme` in CSS, or `@config "…"` to opt back in |
| `corePlugins` | nothing; it cannot be expressed in v4 |
| `safelist` | `@source inline("…")` |
| `separator` | nothing |
| `content` array | automatic detection, plus `@source` |
| `resolveConfig()` | read the generated CSS variables, or `getComputedStyle` |
| `theme(colors.red.500)` in CSS | `var(--color-red-500)` |
| `theme(screens.xl)` in a media query | `theme(--breakpoint-xl)` |
| `container` `center` / `padding` options | `@utility container { … }` |

`rotate-*`, `scale-*` and `translate-*` now compile to the individual CSS
properties rather than one `transform`. `transform-none` still exists and still
emits `transform: none`, but that no longer clears them, so `scale-150
focus:transform-none` silently stays scaled. Reset the individual property
instead: `scale-none`, `rotate-none`, `translate-none`. If a project transitions
`transition-[opacity,transform]`, those utilities no longer animate; the list has
to name the individual properties, `transition-[opacity,scale]`.

`transition` and `transition-colors` now include `outline-color`. A button with
`transition hover:outline-2 hover:outline-cyan-500` animates the color from the
default; set the outline color unconditionally to avoid it.
