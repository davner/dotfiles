# DataTable in v10

Provenance: read from `primereact@10.9.8` source (`datatable/datatable.esm.js`,
`column/column.esm.js`) on 2026-08-26. Line numbers refer to that file. These are
read from source rather than observed in a running app, but the code paths are
unambiguous.

DataTable is the component most likely to be written wrong, because it has three
different reactivity rules for sibling props, and every failure mode is silent.
PrimeReact v10 never calls `console.warn` anywhere, so nothing will tell you.

## Shape: columns are children

```tsx
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';

<DataTable value={products} paginator rows={10}>
  <Column field="code" header="Code" sortable />
  <Column field="name" header="Name" sortable />
</DataTable>
```

`Column` is not a component in any meaningful sense. Its entire implementation is:

```js
var Column = function Column() {};   // column/column.esm.js:2
```

It renders nothing and exists only to carry props. DataTable harvests them with
`React.Children.toArray(props.children)` and reads each prop through
`ColumnBase.defaultProps`. Two consequences:

- **Wrapping `Column` in your own component breaks it silently.** `<MyColumn
  field="x" />` produces an element whose props do not match what DataTable looks
  for, so every field reads `undefined` and you get blank columns with no error.
  If you need to generate columns, return `Column` elements from a `.map()`, do
  not wrap them.
- **`<Column />` outside a DataTable or TreeTable renders nothing**, again with no
  error.

## The three silent failures, in the order you will hit them

### 1. `paginator` without `rows` renders an empty table

`rows` defaults to `null` and is optional in the types. The slice is:

```js
return data.slice(first, first + getRows());   // datatable.esm.js:7097-7103
```

`0 + null === 0`, so this is `data.slice(0, 0)`. You get a paginator over zero
rows, no error, no warning. **Whenever you pass `paginator`, pass `rows`.**

### 2. `selectionMode` alone does nothing

Selection is strictly controlled. There is no internal selection state in the
component at all - `selectionState` appears zero times in the source. DataTable
reads `props.selection` directly and only ever calls `props.onSelectionChange`.

```tsx
// does nothing - rows never highlight, no error
<DataTable value={rows} selectionMode="single" />

// correct
const [selected, setSelected] = useState(null);
<DataTable
  value={rows}
  selectionMode="single"
  selection={selected}
  onSelectionChange={(e) => setSelected(e.value)}
/>
```

This is the trap that catches people who learned the paging behavior first,
because paging and selection follow opposite rules in the same component.

### 3. Passing a handler makes that feature controlled, and you must write back

The switch between controlled and uncontrolled is the **handler prop**, not the
value prop:

```js
var getFirst = function () { return props.onPage ? props.first : firstState; };
var getRows  = function () { return props.onPage ? props.rows  : rowsState;  };
// datatable.esm.js:5925-5942, same pattern for onSort and onFilter
```

Internal state is written only in the uncontrolled branch. So passing `onPage`
without persisting the event back into your own state freezes pagination: clicking
page 2 fires your handler, you ignore it, and `getFirst()` keeps returning the
`props.first` you never changed.

| Handler you pass | What you must persist from the event |
| --- | --- |
| `onPage` | `e.first` **and** `e.rows` - both, or paging freezes |
| `onSort` | `e.sortField` and `e.sortOrder`, or `e.multiSortMeta` when `sortMode="multiple"` |
| `onFilter` | `e.filters` |

```tsx
const [first, setFirst] = useState(0);
const [rows, setRows] = useState(10);

<DataTable
  value={data} paginator first={first} rows={rows}
  onPage={(e) => { setFirst(e.first); setRows(e.rows); }}
/>
```

**Controlled sort and filter do not reset to page one.** The uncontrolled branches
call `setFirstState(0)` on sort and filter; the controlled branches do not, and the
event object carries the *current* `first` because it is spread in before the event
meta. If you write `e.first` back on a sort handler you will stay on page five of a
freshly sorted set. Controlled callers should set `first` to `0` themselves when
sorting or filtering.

## Three props, three different reactivity rules

This is worth stating explicitly because it is genuinely inconsistent:

| Prop | Behavior after mount |
| --- | --- |
| `rows` | syncs from props during render, when uncontrolled |
| `filters` | syncs from props via effect, **unconditionally** (even when controlled) |
| `first` | **never** syncs from props when uncontrolled |

So an uncontrolled table cannot be moved to another page by changing `first`. If
you need to drive the page from outside, go controlled and pass `onPage`.

## Other behavior worth knowing

**Filtering is debounced through `setTimeout`.** `onFilterApply` wraps the whole
apply in `setTimeout(..., props.filterDelay)`, so `onFilter` fires asynchronously
after typing. In tests this needs fake timers or `waitFor`; do not assert
synchronously after firing a change event on a filter input.

**`reset()` exists only on the ref**, not as a prop, and its prop-reseeding is
guarded by `!props.onPage` / `!props.onSort` / `!props.onFilter`. Calling
`ref.current.reset()` on a fully controlled table resets almost nothing. The
imperative handle also exposes `filter`, `exportCSV`, `restoreState`, `saveState`,
`getFilterMeta`, and `setFilterMeta`.

**Lazy mode changes the slice.** With `lazy`, `first` is forced to `0` for the
slice because you are expected to have already fetched exactly the current page.
Pass `totalRecords` so the paginator knows how many pages exist.

## Reading the real API

DataTable's declarations are 2069 lines. Do not read the whole file:

`$PR10` is the resolver defined in [SKILL.md](../SKILL.md); a bare relative path
will not resolve, because your working directory is the project.

```bash
bash "$PR10" events DataTable          # every callback
bash "$PR10" prop DataTable rows       # one prop with its default
bash "$PR10" prop DataTable selectionMode
bash "$PR10" props Column | head -60   # what Column accepts
```

Documentation, which carries the usage shapes: `https://v10.primereact.org/datatable/`
(read it with the curl user-agent invocation in `SKILL.md`; the site 403s normal
fetch tooling).
