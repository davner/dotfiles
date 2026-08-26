---
name: primereact-v10
description: PrimeReact v10 component reference, API lookup, and version guardrails. Use whenever a project imports from `primereact/*`, lists primereact in package.json, or the user mentions PrimeReact, PrimeFaces, PrimeFlex, PrimeIcons, PassThrough/`pt`, or v10 components like DataTable, Dropdown, Calendar, OverlayPanel, TabView, InputSwitch, or `pi pi-*` icons. Load this even for requests that look trivial, such as adding one input or changing one prop, because PrimeReact v11 renamed or removed most of the library and is commercially licensed, which makes recalled knowledge of "current" PrimeReact actively wrong in a v10 project.
allowed-tools: Bash(node -p *), Bash(bash *pr10.sh*), Bash(ls -d *), Bash(curl -sS *)
---

# PrimeReact v10

## What is actually installed here

```json
!`node -p "const fs=require('fs'),pa=require('path');let d=process.cwd(),r=null;while(d!=='/'){if(fs.existsSync(pa.join(d,'node_modules/primereact'))){r=pa.join(d,'node_modules/primereact');break}d=pa.dirname(d)}const j=f=>{try{return JSON.parse(fs.readFileSync(f,'utf8'))}catch(e){return{}}};const app=r?j(pa.join(r,'../../package.json')):{};const dep={...(app.dependencies||{}),...(app.devDependencies||{})};JSON.stringify(r?{installed:j(pa.join(r,'package.json')).version||null,declared:dep.primereact||null,react:dep.react||null,primeicons:dep.primeicons||null}:{installed:null,note:'no primereact resolved from '+process.cwd()},null,2)" 2>/dev/null || echo '{"installed":null,"note":"node unavailable or errored"}'`
```

Read `installed` before doing anything else. It is the real version on disk, which
beats the version anyone believes is in use.

- **`installed` starts with `10.`** - this skill applies. Proceed.
- **`installed` starts with `11.` or higher** - this skill does NOT apply. Say so
  and stop using it; its component names are wrong for that project.
- **`installed` is `null`** - dependencies may not be installed, or you are not in
  the project directory. Ask before assuming a version; do not guess from memory.

## Never propose upgrading to v11

PrimeReact relicensed at v11. This is verifiable from the published packages:
`primereact@10.9.8` declares `MIT`, and `primereact@11.x` declares
`SEE LICENSE IN LICENSE.md`, whose text reads "This package is part of PrimeUI, a
family of commercial UI libraries" and "A valid license key is required to use
this software." The free Community tier requires meeting all of: under $1M annual
revenue, fewer than 5 developers, fewer than 10 employees, under $3M outside
funding.

**10.9.8 is the last MIT release.** A team on v10 is very often there on purpose.
Suggesting an upgrade proposes attaching a license obligation and a per-developer
cost to their company, so do not raise it as a fix, a modernization, or an aside.
If a user explicitly asks about upgrading, tell them about the license first.

## Where the truth lives

Work down this list. Stop at the first source that answers the question.

**1. The installed type declarations.** `node_modules/primereact/<component>/<component>.d.ts`
is version-exact by construction, because it is the copy the project compiles
against. Every prop carries JSDoc and `@defaultValue`. Use the bundled script
rather than reading whole files, since DataTable alone is 2069 lines:

The script lives in this skill's directory, and your working directory is the
user's project, so resolve it once per session and reuse the variable. A bare
`scripts/pr10.sh` will not be found.

```bash
PR10=$(ls -d ~/.claude/skills/primereact-v10/scripts/pr10.sh \
             .claude/skills/primereact-v10/scripts/pr10.sh 2>/dev/null | head -1)

bash "$PR10" version              # what is installed, and where
bash "$PR10" list                 # all 116 shipped modules
bash "$PR10" find switch          # locate a module by partial name
bash "$PR10" props InputSwitch    # the Props interface, with JSDoc
bash "$PR10" prop Button severity # one prop, its doc and its default
bash "$PR10" events DataTable     # only the callback props
bash "$PR10" raw Calendar         # path, when you need to read it directly
```

Run these from inside the project, since the script walks up from the working
directory to find `node_modules/primereact`. If `$PR10` comes back empty the skill
is installed somewhere else; read `node_modules/primereact/<component>/<component>.d.ts`
directly instead.

**2. The v10 documentation site**, for usage shape and accessibility requirements
that types cannot express. Component pages are `https://v10.primereact.org/<module>/`
with stable `#import`, `#basic`, and `#accessibility` anchors, plus global pages at
`/theming/`, `/passthrough/`, `/configuration/`, and `/guides/accessibility/`.

Note that `/accessibility/` (without `/guides/`) returns HTTP 200 and is an empty
shell with no content, so it passes a link check while telling you nothing. The
real guide is at `/guides/accessibility/`.

The site returns **403 to normal fetch tooling** and 200 to a browser user-agent,
so read it with curl and do not conclude the docs are unreachable:

```bash
curl -sS -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 \
(KHTML, like Gecko) Chrome/126.0 Safari/537.36" -L "https://v10.primereact.org/dropdown/"
```

Never cite `www.primereact.org` or `primereact.dev`. Both now serve v11. This
matters more than it looks: the JSDoc inside the v10 `.d.ts` files links to
`https://www.primereact.org/<component>/`, so following a link you read in the
types lands you on v11 documentation for a v10 component.

**3. The bundled examples**, for usage shape without a network round trip.
`examples/<module>/<section>.typescript.tsx` is a complete, self-contained
component; `<section>.basic.jsx` is the bare JSX fragment. These are extracted from
the v10 showcase at tag 10.9.8 and verified byte-identical to what the docs site
serves, so they are the same code without the fetch.

These are files in this skill's directory; read them with the Read tool rather
than a shell command, since your working directory is the project.

`examples/_broken.json` lists 17 snippets that do not parse. Those are upstream
defects that the docs site serves verbatim, so do not copy them.

**4. The reference files in this skill**, for the traps none of the above state.
These exist because the types compile and the docs stay quiet while the runtime
does something else.

## Rules that prevent the common failures

**Check the module name before importing it.** v11 renamed or removed most of the
library, so more than half of what a model recalls does not exist here. Only 54 of
116 v10 module paths survive into v11. If you are about to write `datepicker`,
`select`, `popover`, `tabs`, `toggleswitch`, `drawer`, `inputpassword`,
`inputtags`, or `textarea`, stop: none of those exist in v10. The v10 names are
`calendar`, `dropdown`, `overlaypanel`, `tabview`, `inputswitch`, `sidebar`,
`password`, `chips`, and `inputtextarea`. Full tables in
[version-delta.md](references/version-delta.md).

**Read the event payload before wiring `onChange`.** PrimeReact does not follow the
DOM convention, the shape differs per component, and the declarations hide it
behind `extends FormEvent` so the types will not save you. Three that catch people:

- **Checkbox** puts the static `value` prop in `e.value` (defaulting to `null`) and
  the new state in `e.checked`. `onChange={e => setAgreed(e.value)}` type-checks
  and silently sets `null`. Use `e.checked`.
- **InputSwitch and ToggleButton have no `e.checked` at all**, despite taking a
  `checked` prop. The new state is `e.value`. Copying a Checkbox handler onto an
  InputSwitch silently writes `undefined`.
- **RadioButton is the opposite of Checkbox**: `e.value` is the option's value,
  which is what a radio group wants, and `e.checked` is always `true`.

Never generalize one component's payload to its neighbor. Check
[events.md](references/events.md), which lists every component's payload with the
one correct expression.

**Do not import `primereact/resources/primereact.min.css`.** In v10 that file is
153 bytes containing only a deprecation comment: "The primereact[.min].css has
been deprecated. In order not to break existing projects, it is currently included
in the build as an empty file." Most tutorials online still tell you to import it.
What you actually need is a theme, and optionally `primeicons`. See
[theming.md](references/theming.md).

**`primeicons` is optional.** It is not a dependency or peer dependency of
primereact. v10 ships inline SVG icon components, so `pi pi-*` class names only
work if the project separately installs and imports `primeicons`. Check the
injected context above before using a `pi pi-*` string.

**DataTable is composed of `<Column>` children in v10.** Any DataTable snippet you
recall that configures columns through a prop rather than children is v11 and does
not apply. DataTable also decides between controlled and uncontrolled behavior
based on which handlers you pass, which has a specific silent-failure mode covered
in [datatable.md](references/datatable.md).

**Accessibility is a per-component contract.** Many v10 components render an inner
input that has no accessible name unless you supply one, and the docs state the
requirement per component. See [accessibility.md](references/accessibility.md)
before shipping a form or a dialog.

## Picking a component

| Need | v10 component | Module |
| --- | --- | --- |
| Text input | `InputText` | `primereact/inputtext` |
| Multi-line text | `InputTextarea` | `primereact/inputtextarea` |
| Number, currency, spinner | `InputNumber` | `primereact/inputnumber` |
| Password with strength meter | `Password` | `primereact/password` |
| Masked input | `InputMask` | `primereact/inputmask` |
| One-time code | `InputOtp` | `primereact/inputotp` |
| Single select | `Dropdown` | `primereact/dropdown` |
| Multi select | `MultiSelect` | `primereact/multiselect` |
| Typeahead | `AutoComplete` | `primereact/autocomplete` |
| Nested select | `CascadeSelect` | `primereact/cascadeselect` |
| Select from a tree | `TreeSelect` | `primereact/treeselect` |
| Always-visible list | `ListBox` | `primereact/listbox` |
| On/off toggle | `InputSwitch` | `primereact/inputswitch` |
| Checkbox, radio | `Checkbox`, `RadioButton` | `primereact/checkbox`, `/radiobutton` |
| Segmented choice | `SelectButton` | `primereact/selectbutton` |
| Tag entry | `Chips` | `primereact/chips` |
| Date and time | `Calendar` | `primereact/calendar` |
| Color | `ColorPicker` | `primereact/colorpicker` |
| Slider, dial, stars | `Slider`, `Knob`, `Rating` | `primereact/slider`, `/knob`, `/rating` |
| Rich text | `Editor` | `primereact/editor` |
| Table with paging and sorting | `DataTable` + `Column` | `primereact/datatable`, `/column` |
| Hierarchical table | `TreeTable` | `primereact/treetable` |
| Card or list layout of records | `DataView` | `primereact/dataview` |
| Tree | `Tree` | `primereact/tree` |
| Reorder or transfer lists | `OrderList`, `PickList` | `primereact/orderlist`, `/picklist` |
| Charts | `Chart` (wraps Chart.js) | `primereact/chart` |
| Modal | `Dialog` | `primereact/dialog` |
| Confirm | `ConfirmDialog`, `ConfirmPopup` | `primereact/confirmdialog`, `/confirmpopup` |
| Edge overlay panel | `Sidebar` (NOT `Drawer`) | `primereact/sidebar` |
| Anchored floating panel | `OverlayPanel` | `primereact/overlaypanel` |
| Tooltip | `Tooltip` | `primereact/tooltip` |
| Tabs | `TabView` + `TabPanel` | `primereact/tabview` |
| Accordion | `Accordion` + `AccordionTab` | `primereact/accordion` |
| Collapsible panel | `Panel`, `Fieldset` | `primereact/panel`, `/fieldset` |
| Wizard | `Steps`, `Stepper` | `primereact/steps`, `/stepper` |
| Menus | `Menu`, `Menubar`, `TieredMenu`, `ContextMenu`, `MegaMenu`, `PanelMenu`, `SlideMenu` | `primereact/<name>` |
| Toast notifications | `Toast` | `primereact/toast` |
| Inline messages | `Message`, `Messages` | `primereact/message`, `/messages` |
| Upload | `FileUpload` | `primereact/fileupload` |
| Loading | `ProgressBar`, `ProgressSpinner`, `Skeleton`, `BlockUI` | `primereact/<name>` |
| Large lists | `VirtualScroller` | `primereact/virtualscroller` |

Run `bash "$PR10" list` for the complete set, and see
[components.md](references/components.md) for the full inventory grouped the way
the documentation groups it.

## Workflow

1. **Read the injected version above.** Confirm it is 10.x before continuing.
2. **Confirm the component exists** with `pr10.sh find <name>` rather than
   trusting recall, especially for anything in the rename table.
3. **Read the real props** with `pr10.sh props <component>` before writing them.
   Guessing a prop name is the most common way to produce code that compiles in
   the editor and fails at runtime.
4. **Read the event payload** in [events.md](references/events.md) before writing
   any `onChange`, `onSelect`, or `onPage` handler.
5. **Check the accessibility contract** for the component in
   [accessibility.md](references/accessibility.md).
6. **Match the project's existing conventions.** Look at how sibling components in
   the repo import themes, structure forms, and handle state, and follow that
   rather than introducing a second pattern.
7. **Verify against the docs** at `v10.primereact.org` when usage shape is unclear,
   using the curl invocation above.

## Reference files

- [version-delta.md](references/version-delta.md) - what v11 renamed and removed,
  the v11-only names to never write, and why the v10 pin is deliberate
- [components.md](references/components.md) - the full v10 inventory by category,
  with doc URLs and declaration paths
- [events.md](references/events.md) - the `onChange` payload taxonomy, verified at
  each component's payload construction site
- [datatable.md](references/datatable.md) - DataTable, Column, paging, sorting,
  filtering, selection, and the controlled-state failure mode
- [theming.md](references/theming.md) - theme imports, `PrimeReactProvider`,
  PassThrough (`pt`), CSS layer ordering with Tailwind
- [accessibility.md](references/accessibility.md) - per-component requirements and
  the global guide
- [gotchas.md](references/gotchas.md) - verified runtime surprises that the types
  and docs do not tell you
