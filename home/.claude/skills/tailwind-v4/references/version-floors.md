# Which v4 version added what

v4 is not one target. A utility added in 4.1 generates no CSS in a 4.0 project,
with no error, so the class sits in the markup doing nothing. The docs site
documents the latest v4 only and does not say when anything arrived, which is why
this file exists.

Check `installed` from the injected block at the top of the skill, then confirm
with `node "$TW4" check <class>`, which compiles against the version on disk and
is the final word.

Compiled from the tailwindcss CHANGELOG, stable releases only.

## Needs 4.3.0 or newer

| Feature | Notes |
| --- | --- |
| `tab-*` | `tab-size`; note this collides with the name most examples use for a custom `@utility` |
| `zoom-*` | reads the `--zoom-*` namespace |
| `scrollbar-auto`, `scrollbar-thin`, `scrollbar-none` | `scrollbar-width` |
| `scrollbar-thumb-*`, `scrollbar-track-*` | `scrollbar-color` |
| `scrollbar-gutter-*` | |
| `@container-size` | |
| `@variant hover:focus { … }` | stacked variants inside `@variant` |
| `@variant hover, focus { … }` | compound variants inside `@variant` |
| `--default(…)` inside `--value(…)` / `--modifier(…)` | default for a bare functional utility |

## Needs 4.2.0 or newer

| Feature | Notes |
| --- | --- |
| `mauve`, `olive`, `mist`, `taupe` colors | added to the default palette |
| `inline-*`, `min-inline-*`, `max-inline-*` | `inline-size` and its bounds |
| `block-*`, `min-block-*`, `max-block-*` | `block-size` and its bounds |
| `pbs-*`, `pbe-*` | `padding-block-start` / `-end` |
| `mbs-*`, `mbe-*` | `margin-block-start` / `-end` |
| `scroll-pbs-*`, `scroll-pbe-*`, `scroll-mbs-*`, `scroll-mbe-*` | logical scroll padding and margin |
| `border-bs-*`, `border-be-*` | `border-block-start` / `-end` |
| `inset-s-*`, `inset-e-*`, `inset-bs-*`, `inset-be-*` | logical inset; **deprecates `start-*` and `end-*`** |
| `font-features-*` | `font-feature-settings` |
| `@tailwindcss/webpack` | webpack integration package |

## Needs 4.1.0 or newer

The largest batch. Anything here written into a 4.0 project is dead markup.

| Feature | Notes |
| --- | --- |
| `text-shadow-*` | including `text-shadow-<color>` and `/<alpha>` |
| `mask-*` | the whole masking family |
| `drop-shadow-<color>` | colored drop shadows |
| `shadow-*/<alpha>`, `inset-shadow-*/<alpha>`, `drop-shadow-*/<alpha>` | shadow opacity modifiers |
| `bg-position-*`, `bg-size-*` | arbitrary background position and size |
| `wrap-anywhere`, `wrap-break-word`, `wrap-normal` | `overflow-wrap` |
| `items-baseline-last`, `self-baseline-last` | |
| safe alignment utilities | `justify-center-safe` and friends |
| `details-content` variant | |
| `inverted-colors` variant | |
| `noscript` variant | |
| `user-valid`, `user-invalid` variants | |
| `pointer-none`, `pointer-coarse`, `pointer-fine` variants | |
| `any-pointer-none`, `any-pointer-coarse`, `any-pointer-fine` variants | |
| `@source inline(…)`, `@source not inline(…)` | the safelist replacement |
| `@source not "…"` | exclude a path |

4.1.0 also changed scanning: `node_modules` is ignored by default and must be
opted back in with `@source`.

## Needs a 4.0 patch

| Feature | Floor |
| --- | --- |
| `h-lh`, `min-h-lh`, `max-h-lh` | 4.1.5 |
| `col-<number>`, `row-<number>` | 4.0.10 |
| `@theme static` | 4.0.5 |
| `:open` included in the `open` variant | 4.0.1 |

`max-w-auto` and `max-h-auto` were removed in 4.0.10 for generating invalid CSS.

## Present since 4.0.0

Container queries without a plugin, `not-*`, `starting` (`@starting-style`), 3D
transform utilities, `color-scheme`, `field-sizing`, `inert`, the OKLCH P3 color
palette, dynamic spacing values without a configured scale, and composable
variants generally.

## Deprecated within v4

| Deprecated | Since | Use |
| --- | --- | --- |
| `start-*`, `end-*` | 4.2.0 | `inset-s-*`, `inset-e-*` |
| `bg-{left,right}-{top,bottom}` | 4.1.0 | `bg-{top,bottom}-{left,right}` |
| `object-{left,right}-{top,bottom}` | 4.1.0 | `object-{top,bottom}-{left,right}` |

## Upgrading within v4

`@tailwindcss/upgrade` handles v4-to-v4 moves since 4.1.5, not just v3 to v4. It
needs Node 20 or newer. Run it on a branch and read the diff.
