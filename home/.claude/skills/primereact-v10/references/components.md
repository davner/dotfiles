# The complete v10 inventory

Provenance: categories and doc paths taken from the v10 documentation navigation
(94 pages, all verified HTTP 200) on 2026-08-26; module names verified against the
packaged directory listing of `primereact@10.9.8`.

Doc URL for any row is `https://v10.primereact.org/<path>/`. Declarations are at
`node_modules/primereact/<module>/<module>.d.ts`. Bundled examples for a component
are at `examples/<module>/`.

There is **no DragDrop category** in v10, and no `sitemap.xml` or `llms.txt`.

## Form (31)

AutoComplete `autocomplete`, Calendar `calendar`, CascadeSelect `cascadeselect`,
Checkbox `checkbox`, Chips `chips`, ColorPicker `colorpicker`, Dropdown `dropdown`,
Editor `editor`, FloatLabel `floatlabel`, IconField `iconfield`, InputGroup
`inputgroup`, InputMask `inputmask`, InputNumber `inputnumber`, InputOtp `inputotp`,
InputSwitch `inputswitch`, InputText `inputtext`, InputTextarea `inputtextarea`,
KeyFilter `keyfilter`, Knob `knob`, Listbox `listbox`, Mention `mention`,
MultiSelect `multiselect`, MultiStateCheckbox `multistatecheckbox`, Password
`password`, RadioButton `radiobutton`, Rating `rating`, SelectButton `selectbutton`,
Slider `slider`, ToggleButton `togglebutton`, TreeSelect `treeselect`,
TriStateCheckbox `tristatecheckbox`.

## Button (3)

Button `button`, SpeedDial `speeddial` (doc label "Speed Dial"), SplitButton
`splitbutton`.

## Data (11)

DataTable `datatable`, DataView `dataview`, DataScroller `datascroller`, OrderList
`orderlist`, OrganizationChart `organizationchart` (doc label "Org Chart"),
Paginator `paginator`, PickList `picklist`, Timeline `timeline`, Tree `tree`,
TreeTable `treetable`, VirtualScroller `virtualscroller`.

## Panel (11)

Accordion `accordion`, Card `card`, DeferredContent `deferredcontent` (doc label
"Deferred"), Divider `divider`, Fieldset `fieldset`, Panel `panel`, ScrollPanel
`scrollpanel`, Splitter `splitter`, Stepper `stepper`, TabView `tabview`, Toolbar
`toolbar`.

## Overlay (6)

ConfirmDialog `confirmdialog`, ConfirmPopup `confirmpopup`, Dialog `dialog`,
OverlayPanel `overlaypanel`, Sidebar `sidebar`, Tooltip `tooltip`.

## File (1)

FileUpload `fileupload` (doc label "Upload", doc path `/fileupload/`).

## Menu (10)

Breadcrumb `breadcrumb`, ContextMenu `contextmenu`, Dock `dock`, MegaMenu
`megamenu`, Menu `menu`, Menubar `menubar`, PanelMenu `panelmenu`, Steps `steps`,
TabMenu `tabmenu`, TieredMenu `tieredmenu`.

## Chart (1)

Chart `chart` (doc label "Chart.js"). Wraps Chart.js, which is a peer install.

## Messages (3)

Message `message`, Messages `messages`, Toast `toast`.

## Media (3)

Carousel `carousel`, Galleria `galleria`, Image `image`.

## Misc (14)

Avatar `avatar`, Badge `badge`, BlockUI `blockui`, Chip `chip`, Inplace `inplace`,
MeterGroup `metergroup`, ProgressBar `progressbar`, ProgressSpinner
`progressspinner`, Ripple `ripple`, ScrollTop `scrolltop`, Skeleton `skeleton`,
StyleClass `styleclass`, Tag `tag`, Terminal `terminal`.

## Sub-components with no page of their own

These are real, public, and importable. They are documented inside their parent's
page, so a missing doc page does not mean a missing component.

| Module | Documented on |
| --- | --- |
| `avatargroup` | `/avatar/` |
| `buttongroup` | `/button/` |
| `column`, `columngroup`, `row` | `/datatable/`, `/treetable/` |
| `inputicon` | `/iconfield/` |
| `stepperpanel` | `/stepper/` |
| `terminalservice` | `/terminal/` |

`inputgroup` and `inputgroupaddon` ship as modules and have a doc page, but note
that `inputgroupaddon` has no separate page.

## Ships in the package but has no doc page at all

**`slidemenu`** is a real component that ships in `primereact@10.9.8`, but the v10
documentation site dropped it entirely - it is not in the nav and
`/slidemenu/` 404s. Read its API from the declarations
(`pr10.sh props SlideMenu`) and its examples from `examples/slidemenu/` if present.

## Internal and type-only modules

Not components; do not try to render them. `api`, `componentbase`, `csstransition`,
`hooks` (documented per hook at `/hooks/<hookname>/`, not `/hooks/`), `iconbase`,
`menuitem`, `overlayservice`, `passthrough` (the concept has a page at
`/passthrough/`), `selectitem`, `treenode`, `utils`, `core`, `focustrap`, `portal`.

`focustrap` and `portal` are real and usable, they simply have no doc page.

## Global documentation pages

| Page | Covers |
| --- | --- |
| `/theming/` | themes, theme switching, scaling |
| `/passthrough/` | the `pt` API |
| `/configuration/` | `PrimeReactProvider` options |
| `/locale/` | locale API (renders the same content as `/configuration/`) |
| `/guides/accessibility/` | the real accessibility guide |
| `/guides/csslayer/` | cascade layer and Tailwind ordering |
| `/unstyled/` | unstyled mode |
| `/tailwind/` | Tailwind integration |
| `/colors/`, `/customicons/` | palette and custom icons |

Do not link `/accessibility/` without `/guides/`: it returns 200 and is empty.

## Getting the real API

`$PR10` is the resolver defined in [SKILL.md](../SKILL.md); a bare relative path
will not resolve, because your working directory is the project.

```bash
bash "$PR10" list              # all 116 shipped modules
bash "$PR10" props DataTable   # props with JSDoc and defaults
bash "$PR10" events Calendar   # callbacks only
```

Bundled examples live in `examples/<module>/<section>.basic.jsx` (a bare JSX
fragment, not compilable alone) and `<section>.typescript.tsx` (a complete
component). `examples/_broken.json` lists 17 snippets that do not parse; those are
upstream defects served verbatim on the docs site, so do not copy them.
