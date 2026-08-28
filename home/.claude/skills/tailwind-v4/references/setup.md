# Setup and migration

## Pick the integration

| Build tool | Install | Wiring |
| --- | --- | --- |
| Vite | `tailwindcss @tailwindcss/vite` | `plugins: [tailwindcss()]` |
| PostCSS | `tailwindcss @tailwindcss/postcss` | `plugins: { "@tailwindcss/postcss": {} }` |
| CLI | `tailwindcss @tailwindcss/cli` | `npx @tailwindcss/cli -i in.css -o out.css --watch` |
| Webpack | `tailwindcss @tailwindcss/webpack` | 4.2.0 or newer |
| Browser / prototype | `@tailwindcss/browser` | script tag, not for production |

On Vite, prefer the Vite plugin over PostCSS. It is faster and is what the
framework guides use.

In every case the stylesheet is one line:

```css
@import "tailwindcss";
```

### Vite

```ts
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss()],
});
```

### PostCSS

```js
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

Delete `postcss-import` and `autoprefixer`. v4 bundles imports and adds prefixes
itself, and leaving them in causes double processing.

## No content array

Source detection is automatic. Tailwind scans the project and skips:

- anything matched by `.gitignore`
- `node_modules`
- binary files
- CSS files
- package manager lock files

Add back what it misses with `@source`, set the root with
`@import "tailwindcss" source("../src");`, and turn detection off entirely with
`source(none)` when you want to register everything explicitly.

Since 4.1.0, `node_modules` is ignored by default even when not gitignored, so a
Tailwind-using dependency needs an explicit `@source`.

## Migrating a v3 project

`npx @tailwindcss/upgrade` does most of it. It needs Node 20 or newer. Run it on
a branch and read the diff; it edits template files as well as CSS.

What it cannot do is decide whether you should migrate at all. v4 requires
**Safari 16.4+, Chrome 111+, Firefox 128+** and depends on `@property` and
`color-mix()` for core behavior. There is no graceful degradation. If the project
supports older browsers, staying on v3.4 is correct, and v3 is still maintained.

### By hand

1. **Swap the dependency** for the right integration package above.
2. **Replace the directives.**
   ```css
   /* v3 */
   @tailwind base;
   @tailwind components;
   @tailwind utilities;

   /* v4 */
   @import "tailwindcss";
   ```
   Skipping this step produces a stylesheet containing only a license comment,
   with a successful exit code.
3. **Move the theme into CSS.** Each `theme.extend` key becomes a variable in the
   matching namespace:

   | v3 config | v4 CSS |
   | --- | --- |
   | `theme.extend.colors.brand` | `--color-brand` |
   | `theme.extend.fontFamily.display` | `--font-display` |
   | `theme.extend.screens['3xl']` | `--breakpoint-3xl` |
   | `theme.extend.borderRadius.card` | `--radius-card` |
   | `theme.extend.spacing` | usually nothing: any step works from `--spacing` |
   | `darkMode: 'class'` | `@custom-variant dark (&:where(.dark, .dark *));` |
   | `safelist` | `@source inline("…")` |
   | `content` | delete it, or `@source` |
   | `corePlugins` | no equivalent |
   | `prefix: 'tw-'` | `@import "tailwindcss" prefix(tw);` |

4. **Convert custom classes** from `@layer utilities` / `@layer components` to
   `@utility`. In `@layer`, variants silently stop working.
5. **Convert plugins.** First-party plugins load with
   `@plugin "@tailwindcss/typography";`. A plugin with no v4 support needs
   `@config` pointing at a config that registers it.
6. **Fix the class names** in templates, per
   [version-delta.md](version-delta.md). The scale renames are the ones that
   change appearance without changing whether the build succeeds.
7. **Delete `tailwind.config.js`** once nothing needs it. Leaving it is the trap:
   it looks authoritative and is being ignored.

### Half-migrated is a supported state

`@config` and `@plugin` merge with `@theme` and `@utility`, and CSS wins where
they overlap. Moving one namespace at a time is fine. What is not fine is
leaving a config file with no `@config` and assuming it applies.

## Framework notes

Framework guides live at `tailwindcss.com/docs/installation/framework-guides`,
covering Next.js, Nuxt, SvelteKit, React Router, Astro, Laravel, Rails, Phoenix,
Angular, SolidJS, Qwik, Ember, Gatsby, Meteor, Parcel, Rspack, Symfony,
AdonisJS and TanStack Start.

Two recurring cases:

- **Vue, Svelte, Astro `<style>` blocks and CSS modules** compile separately and
  cannot see your theme. `@apply` there needs `@reference "…"` naming your entry
  stylesheet. See [directives.md](directives.md).
- **Fonts injected as CSS variables**, which is every `next/font` setup, need
  `@theme inline` so the utility embeds the value rather than a reference that
  resolves in the wrong scope. See [theme.md](theme.md).

## No preprocessors

v4 is not designed to run with Sass, Less or Stylus, and that includes
`<style lang="scss">` blocks. It already bundles imports, flattens nesting via
Lightning CSS, and adds vendor prefixes. Adding a preprocessor on top is the
supported-configuration cliff, not a performance question.
