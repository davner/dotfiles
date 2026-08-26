# Theming, configuration, and PassThrough

Provenance: read from `primereact@10.9.8` source and from the v10 documentation
pages `/theming/`, `/configuration/`, `/passthrough/`, and `/guides/csslayer/`,
on 2026-08-26.

## Setup: two imports, not three

Nearly every tutorial online tells you to import three CSS files. In v10 one of
them is dead:

```tsx
import 'primereact/resources/themes/lara-light-cyan/theme.css';  // required
import 'primeicons/primeicons.css';                              // only if you use pi pi-* icons
import 'primereact/resources/primereact.min.css';                // DELETE THIS
```

The third file is 153 bytes and contains only a comment: "The primereact[.min].css
has been deprecated. In order not to break existing projects, it is currently
included in the build as an empty file." Importing it does nothing.

`primeicons` is a **separate package** and is not a dependency or peer dependency
of primereact. v10 ships 47 inline SVG icon components and no component defaults to
a class-based icon, so you only need `primeicons` if you write `pi pi-*` strings or
use the `PrimeIcons` enum yourself. Icon components import as
`primereact/icons/<name>`, for example
`import { CheckIcon } from 'primereact/icons/check'`.

Import order among the CSS files does not matter.

## Themes

56 themes ship in the package at `primereact/resources/themes/<name>/theme.css`.
Families: `lara-` (light and dark in 9 accents, the v10 default look), `bootstrap4-`,
`md-` and `mdc-` (Material), `saga-`, `arya-`, `vela-`, `soho-`, `viva-`, `mira`,
`nano`, `nova`, `luna-`, `rhea`, `fluent-light`, `tailwind-light`.

Run `ls node_modules/primereact/resources/themes` for the exact list in the
installed copy.

**Switching themes at runtime** uses `changeTheme` from the context:

```tsx
const { changeTheme } = useContext(PrimeReactContext);
changeTheme('lara-light-cyan', 'lara-dark-cyan', 'theme-link', () => {});
```

It rewrites the `href` on an existing `<link id="theme-link">` by string
replacement, so that element has to already be in the document. It **throws**
`Error("Element with id ... not found.")` otherwise.

Scaling the whole UI is done with the root font size, since the themes are rem
based:

```css
html { font-size: 14px; }
```

## Configuration is read once, at mount

`PrimeReactProvider` seeds every option into `useState`. Nothing re-reads
`props.value` afterwards, so changing the object does nothing after the first
render. This is the single most common configuration mistake.

```tsx
// does not work after mount
<PrimeReactProvider value={{ ripple: enabled }}>

// works
const { setRipple } = useContext(PrimeReactContext);
setRipple(enabled);
```

Available options, verified from `api/api.d.ts`:

| Option | Notes |
| --- | --- |
| `ripple` | off by default in v10 |
| `inputStyle` | `'outlined'` or `'filled'` |
| `locale` | see below; drives accessible names |
| `appendTo` | default portal target for overlays |
| `styleContainer` | where dynamic `<style>` elements go, e.g. a shadow root |
| `nonce` | CSP nonce for dynamically generated styles |
| `cssTransition` | `false` disables all animation globally |
| `autoZIndex`, `zIndex` | defaults: modal 1100, overlay 1000, menu 1000, tooltip 1100, toast 1200 |
| `hideOverlaysOnDocumentScrolling` | needs `overflow` on `document.body` |
| `nullSortOrder`, `filterMatchModeOptions` | data component defaults |
| `pt`, `ptOptions` | global PassThrough |
| `unstyled` | unstyled mode |

Every one has a matching `setX` on the context.

**There is no `cssLayer` option in v10.** It appears zero times in the source; it
belongs to a later version. The CSP-related knobs are `nonce` and `styleContainer`.

## Locale

Locale precedence is: the component's own `locale` prop, then the provider's
`context.locale`, then the global `locale()`, then the browser. **Once a
`PrimeReactProvider` is mounted, calling the global `locale()` alone has no
effect**, which is a common source of "my translations do nothing".

`addLocale` silently fails on primelocale JSON because those files wrap the locale
in a top-level key:

```tsx
import es from 'primelocale/es.json';
addLocale('es', es);      // wrong - silently stays English
addLocale('es', es.es);   // correct
```

The locale carries 41 `aria.*` keys that supply default accessible names for
built-in controls. Not translating them leaves every close button, paginator
control, and Calendar navigation label in English. See
[accessibility.md](accessibility.md).

## Cascade layers, and why your overrides lose

v10 wraps component CSS in `@layer primereact` in 77 modules. This is hardcoded and
cannot be renamed or disabled. Because **unlayered CSS always beats layered CSS
regardless of specificity**, plain custom CSS wins by default, which is usually what
you want.

The problem is Tailwind. Tailwind utilities are also layered, so the ordering has to
be declared. The official v10 fix, verbatim from `/guides/csslayer/`:

```css
@layer tailwind-base, primereact, tailwind-utilities;

@layer tailwind-base {
    @tailwind base;
}

@layer tailwind-utilities {
    @tailwind components;
    @tailwind utilities;
}
```

This puts Tailwind's reset before PrimeReact and Tailwind's utilities after it, so
`className="mt-4"` on a PrimeReact component wins. Without it, PrimeReact's own
styles override your utilities and the usual reaction is to reach for `!important`,
which is the wrong fix.

Tailwind 4 emits real layers of its own, so the ordering differs. Check
`/guides/csslayer/` for the current form rather than assuming the Tailwind 3 recipe
transfers.

## PassThrough (`pt`)

`pt` is the escape hatch for reaching internal DOM nodes that expose no prop. Every
component documents its PT section names on its doc page, and each key takes either
an object of attributes or a function of `(options) => attributes`.

```tsx
<InputSwitch
  checked={checked}
  onChange={(e) => setChecked(e.value)}
  pt={{ slider: { className: 'my-switch-slider' } }}
/>
```

This is also the documented way to add ARIA where no prop exists. The canonical
case is Chart, whose `<canvas>` is invisible to screen readers:

```tsx
<Chart type="line" data={data}
       pt={{ canvas: { role: 'img', 'aria-label': 'Revenue by month' } }} />
```

`pt` can also be set globally on the provider, and `ptOptions` controls whether
global and local PT merge. Note that the Chart PT example on the v10 docs site is
malformed JSX; the form above is the correct one.
