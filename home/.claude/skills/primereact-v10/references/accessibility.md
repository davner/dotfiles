# Accessibility in v10

Provenance: extracted from the `#accessibility` section of all 94 v10 component
doc pages and from `https://v10.primereact.org/guides/accessibility/`, fetched
2026-08-26.

Note the URL. `https://v10.primereact.org/accessibility/` returns HTTP 200 and is
an **empty shell with no content**, so it passes a link check while telling you
nothing. The real guide is at `/guides/accessibility/`.

## What v10 actually promises

Nothing, formally. The guide says PrimeReact "aim[s] [for] high level of WCAG
compliancy in the near future" and that the conformance work "has been completed
for PrimeVue and PrimeNG and [is] currently being ported to PrimeReact to be
finalized in Q4 2023." There is no claimed WCAG level, no VPAT, and no audit.

Treat v10 as giving you accessible primitives, not a conformance guarantee. The
components handle roles, keyboard interaction, and focus management. **Supplying
the accessible name is almost always your job**, and that is the part most
frequently omitted.

Three components where the docs state outright that v10 is not accessible, and
which should not be recommended without telling the user:

| Component | What the docs say |
| --- | --- |
| ColorPicker | "currently component is not compatible with screen readers" - keyboard works |
| OrganizationChart | "does not provide high level of screen reader support" (table-based) |
| Editor | no PrimeReact implementation; inherits whatever Quill provides |

## The house pattern: hidden native input, not ARIA roles

PrimeReact's stated technique is to render a real native control, hide it with the
class `p-hidden-accessible`, and drive the visuals from its focus and keyboard
events. Checkbox, RadioButton, InputSwitch, and Rating all work this way.

The practical consequence is the `inputId` prop. Because the real input is
internal, a plain `id` lands on the wrapper `div` and a `<label htmlFor>` pointing
at it does nothing. You have to target the inner input.

## Labelling, by component

### Needs `inputId` plus a `<label htmlFor>`

The rendered input is internal, so `id` will not work.

```tsx
<label htmlFor="agree">Remember me</label>
<Checkbox inputId="agree" checked={v} onChange={(e) => setV(e.checked)} />
```

Applies to: **AutoComplete, Calendar, Checkbox, Chips, InputNumber, InputSwitch,
Mention, RadioButton**.

InputNumber is a special case: the docs require `id` and `inputId` to be different,
because it renders both a wrapper and an input.

```tsx
<label htmlFor="input-price">Price</label>
<InputNumber id="span-price" inputId="input-price" />
```

RadioButton needs one `inputId` and one label per radio, not per group.

### Renders a real input, so plain `id` works

**InputText, InputTextarea, InputMask, Password**.

```tsx
<label htmlFor="firstname">First name</label>
<InputText id="firstname" />
```

InputOtp delegates to InputText internally; label the group with
`aria-labelledby` pointing at your own element.

### No `<label htmlFor>` path exists, so `aria-label` is the only option

These render a `div` with a widget role and have **no accessible name at all** by
default:

| Component | Role | Pass |
| --- | --- | --- |
| Dropdown, MultiSelect, CascadeSelect, TreeSelect | `combobox` | `aria-label` or `aria-labelledby` |
| Listbox | `listbox` | same |
| Tree | `tree` | same |
| Slider, Knob | `slider` | same |
| ProgressBar, ProgressSpinner | `progressbar` | same |
| MeterGroup | `meter` | **`aria-labelledby` only** - the docs offer no `aria-label` here |
| TriStateCheckbox | `checkbox` | same; state text comes from the locale `aria` keys |
| MultiStateCheckbox | `checkbox` | same, **plus `optionLabel`** or the live region announces the raw option value |
| Terminal | log | same |
| SpeedDial | `button` + `menu` | same |
| Toolbar | `toolbar` | same |
| Avatar | none | `role="img"` + `aria-label`, or leave it decorative |

**ToggleButton** needs a label that does **not** change with state. The docs are
explicit: the component swaps its visible label between `onLabel` and `offLabel`,
so an accessible name derived from that would change under the user. Pass a stable
`aria-label`.

### The label goes in a props bag, not on the component

This is the group most often got wrong, because passing `aria-label` directly looks
right and silently does nothing useful.

| Component | Prop that carries the ARIA attributes |
| --- | --- |
| OrderList | `listProps` |
| PickList | `sourceListProps` **and** `targetListProps` - two lists, two names |
| SplitButton | `menuButtonProps` (docs: the dropdown button "requires an explicit definition"), plus `buttonProps` if the main button has no `label` |
| DataTable, TreeTable | `tableProps` |
| Dropdown / MultiSelect / CascadeSelect / Listbox / TreeSelect **with `filter`** | `filterInputProps` - the filter box is a separate unnamed input |
| Inplace | `displayProps` |
| Accordion tab with a node `header` | `headerProps` |
| Panel / Fieldset, toggleable with a node header | `toggleButtonProps` |
| Menubar (mobile hamburger) | `buttonProps` |
| Chart | `pt={{ canvas: { role: 'img', 'aria-label': '...' } }}` - a `<canvas>` is invisible to readers |

```tsx
<PickList
  sourceListProps={{ 'aria-label': 'Available' }}
  targetListProps={{ 'aria-label': 'Selected' }}
  source={s} target={t} onChange={onChange}
/>
```

### You must wire the trigger yourself

The docs state these relationships are not managed for you.

**Dialog and Sidebar**: the trigger needs `aria-controls` and `aria-expanded`, and
the overlay needs a matching `id`. Dialog also needs a `header`, which is what its
`aria-labelledby` points at.

```tsx
<Button label="Show" onClick={() => setVisible(true)}
        aria-controls={visible ? 'dlg' : undefined} aria-expanded={visible} />
<Dialog id="dlg" header="Confirm" visible={visible} onHide={() => setVisible(false)}>
  ...
</Dialog>
```

**ConfirmDialog** has two modes. The imperative form wires the trigger for you if
you pass it; the controlled `visible` form does not.

```tsx
<Button label="Delete" onClick={(e) => confirmDialog({
  trigger: e.currentTarget, header: 'Confirmation',
  message: 'Proceed?', accept, reject
})} />
<ConfirmDialog />
```

**OverlayPanel and ConfirmPopup** wire the trigger but have no name of their own;
pass `aria-label`. The trigger also has to be keyboard reachable, so use a real
`<button>` or add `tabIndex`.

### The name comes from a prop you might otherwise skip

- **Button**: `aria-label` whenever it is icon-only or uses custom children, since
  `label` is the only fallback.
- **SelectButton**: give every option a `label` even when the display is icon-only.
- **Chip**: `label` becomes the name; icon-only chips need `aria-label`.
- **All menus** (Menu, Menubar, TieredMenu, ContextMenu, MegaMenu, TabMenu, Dock,
  PanelMenu): `aria-label` on the menu **and** a `label` on every item.
- **Breadcrumb, Steps**: `aria-label` on the nav.
- **Carousel, Galleria**: `aria-label`, optionally `aria-roledescription`.
- **FileUpload**: icon-only buttons need labels through `chooseOptions`,
  `uploadOptions`, `cancelOptions`.
- **DataTable/TreeTable editable cells**: the docs say plainly that editors "use
  custom templating so you need to manage aria roles and attributes manually".

## Localization is an accessibility feature here

41 `aria.*` keys in the locale supply the default `aria-label` for every built-in
control: `close`, `clear`, pagination labels, `selectRow`, `expandRow`,
`showFilterMenu`, the Calendar's `chooseDate` / `nextMonth` / `prevYear` family,
Rating's `star`/`stars`, TriStateCheckbox's `trueLabel`/`falseLabel`/`nullLabel`,
and more.

**Ship a non-English app without translating the `aria` object and every one of
those labels stays in English**, including on components that otherwise need no
work from you.

Watch the precedence: component `locale` prop, then `PrimeReactProvider`'s
`context.locale`, then the global `locale()`, then the browser. Once a
`PrimeReactProvider` is present, calling `locale()` alone is not enough.

Other config with accessibility impact: `hideOverlaysOnDocumentScrolling` (the docs
frame this explicitly as an accessibility preference), `cssTransition: false` (the
closest thing to a reduced-motion switch), and `zIndex`/`autoZIndex` (wrong
layering can bury a focused dialog).

## Broken examples on the v10 docs site

Six accessibility examples on the site are copy-paste defects. They are served
verbatim, so a model that learned from those pages will reproduce them.

| Page | Defect |
| --- | --- |
| Knob | the entire example shows `InputText`, no Knob at all |
| PickList | shows `<OrderList>`, wrong component, and wrong for OrderList too |
| OrderList | shows a bare `aria-labelledby` while the prose one sentence earlier says it must go through `listProps`. **The prose is right.** |
| MultiStateCheckbox | second line is `<TriStateCheckbox>`, wrong component |
| Chart | `pt={canvas: {...}}}` is not valid JSX. Correct: `pt={{ canvas: { ... } }}` |
| Sidebar | trigger sets `aria-controls="sbar"` but the Sidebar has `id="sidebar"`, so the relationship it demonstrates does not exist |

## Components with no requirement on you

Tooltip, Toast, Message, Messages, Image, ScrollTop, Paginator, Rating, Divider,
Ripple, Splitter, ScrollPanel, BlockUI, Timeline, DataScroller, VirtualScroller,
DataView, FloatLabel, IconField, KeyFilter, StyleClass, InputGroup.

This holds only for English. Their names come from the locale `aria` object, so a
translated app still needs that object translated.
