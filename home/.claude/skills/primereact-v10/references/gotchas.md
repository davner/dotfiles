# Verified runtime surprises

Provenance: read from `primereact@10.9.8` source on 2026-08-26, at the cited
files and lines. Statements here were read from source (and in two cases executed
in Node), not observed in a running React app.

These are the cases where the types compile, the documentation stays quiet, and
the runtime does something else. DataTable has enough of them to warrant its own
file: see [datatable.md](datatable.md).

## PrimeReact v10 never warns you about anything

Across the entire package, including bundles: **`console.warn` appears 0 times and
`console.error` appears 0 times.** There is no development-mode warning mechanism,
no `NODE_ENV` gate, no `invariant` helper. Every `console.log` occurrence in the
tree is inside a comment or a JSDoc example.

The practical consequence is that "PrimeReact will warn you if you forget X" is
never true, and any explanation that relies on it is invented. Silence means
nothing.

It does **throw** in a few places, so it is not entirely mute: date and time
parsing in Calendar, an invalid `mode` on ProgressBar, and an invalid
`stateStorage` on Splitter and TreeTable all throw.

## VirtualScroller renders exactly one row unless you set `itemSize`

`itemSize` defaults to `0` and is optional in the props type. The viewport
calculation is:

```js
Math.ceil(_contentSize / (_itemSize || _contentSize))   // virtualscroller.esm.js:403
```

With `itemSize === 0` the divisor falls back to `_contentSize`, so the result is
`Math.ceil(n/n)` which is `1`. Both `<VirtualScroller items={x} />` and
`<DataTable virtualScrollerOptions={{}} />` type-check and silently render a single
row. Always pass `itemSize`.

## `PrimeReactProvider value` is read once and never again

Every config field inside the provider is a `useState` seeded from `props.value`.
`useState` ignores its argument on every render after the first, and nothing in
the provider reads `props.value` afterwards. So this does nothing after mount:

```tsx
// the theme never changes
<PrimeReactProvider value={{ ripple: isRipple }}>
```

To change configuration at runtime, use the setters the context exposes beside
every field:

```tsx
const { setLocale, setRipple } = useContext(PrimeReactContext);
setLocale('es');
```

For swapping themes there is `changeTheme(currentTheme, newTheme, linkElementId,
callback)`, which rewrites the `href` on an existing `<link id="...">` by string
replacement. It **throws** `Error("Element with id ... not found.")` if that link
element does not exist, so the `<link>` has to be in the document already.

## `addLocale` fails silently on primelocale JSON

```js
locales[locale] = { ...locales.en, ...options };   // api.esm.js:510-515
```

The only validation is a prototype-pollution guard on the locale *name*. The
payload is never checked. primelocale ships each locale wrapped in a top-level key,
so passing the file contents directly produces a locale object where every real key
still holds its English value plus one junk key:

```tsx
import es from 'primelocale/es.json';

addLocale('es', es);       // wrong - silently 100% English
addLocale('es', es.es);    // correct
```

Nothing throws and nothing warns; lookups find the object, find English values, and
return them.

## `appendTo={document.body}` breaks SSR, but not for the reason usually given

PrimeReact's own handling is SSR-safe: `Portal` is guarded by a mounted flag set in
an effect, returns `null` during server render, and only then falls back to
`document.body`. The breakage comes from **your own JSX**, because
`appendTo={document.body}` evaluates `document` while React renders your component
on the server, before PrimeReact ever sees the value.

```tsx
<Dialog appendTo={document.body} />        // crashes during SSR
<Dialog appendTo={() => document.body} />  // correct - deferred to the client
<Dialog />                                 // also fine; the guarded fallback is document.body
```

`appendTo` accepts a function, the string `'self'` (render in place, no portal), an
`HTMLElement`, or nothing. It does **not** accept `'document'`, `'window'`, or a
ref object, even though a similar internal helper does.

## Every module carries `'use client'`

Every PrimeReact v10 component file begins with `'use client'`. In the Next.js App
Router, none of them can be imported into a server component. A page that renders
any PrimeReact component needs a client boundary.

## Subpath imports do not work under native Node ESM

The root `package.json` has **no `exports` field** and no top-level `types`.
Subpath resolution relies on 164 per-directory `package.json` files, which is
directory-style resolution that bundlers understand and native Node ESM does not.

| Consumer | Works |
| --- | --- |
| Vite, webpack, Rollup, Next bundler | Yes |
| Jest with default resolution | Yes |
| Native Node ESM (plain `.mjs`, unbundled Node SSR) | **No** - `ERR_UNSUPPORTED_DIR_IMPORT` |
| TypeScript `moduleResolution: node16` / `nodenext` | Problematic; use `node` or `bundler` |

Because there is no root `types` field, TypeScript finds declarations only through
the per-directory `types` entry on subpath imports, which is another reason to
import `primereact/button` rather than `primereact`.

## The CSS is already inside a cascade layer, and you cannot rename it

77 component modules emit their styles wrapped in `@layer primereact { ... }`. The
`cssLayer` configuration option that exists in newer PrimeReact **does not exist in
v10** - it appears zero times in the source. There is no way to opt out or rename
the layer.

This matters for override specificity, especially with Tailwind, because unlayered
CSS beats layered CSS regardless of specificity. See [theming.md](theming.md).

The CSP-related knobs that do exist are `nonce` (sets `nonce` on dynamically
generated `<style>` elements) and `styleContainer` (inserts them somewhere other
than `document.head`, e.g. a shadow root). Both go on `PrimeReactProvider`'s value.

## The deprecated global is still a live fallback

Components resolve configuration as `context && context.X || PrimeReact.X`, falling
back to a deprecated module-level singleton. Because that is `||` rather than `??`,
a legitimately falsy context value can fall through to the global. Setting
`nonce: ''` or, at some call sites, `autoZIndex: false` does not reliably win. Use
the context setters and avoid relying on falsy config values.
