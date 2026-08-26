# Event payloads in v10

Provenance: every entry below was read from the runtime object literal passed to
the callback in the component's `.esm.js` in `primereact@10.9.8`, on 2026-08-26,
not from the type declarations.

The declarations cannot answer this question. Most components declare their event
as `extends FormEvent`, and `FormEvent` in `primereact/ts-helpers.d.ts` is:

```ts
export interface FormEvent<T = any, E = React.SyntheticEvent> {
    originalEvent?: E;
    value: Nullable<T>;
    checked?: boolean;
    stopPropagation(): void;
    preventDefault(): void;
    target: FormTarget<T>;
}
```

Both `value` and `checked` are declared for every component, `checked` is
optional, and `target` is always claimed to exist. So the compiler accepts
`e.value`, `e.checked`, and `e.target.value` on essentially any form component,
including the many where one or more of them is `undefined` at runtime. That is
why this file exists.

Useful exports from `primereact/ts-helpers` when typing your own handlers:
`Nullable<T>`, `FormEvent<T>`, `FormBooleanEvent`, `FormTarget<T>`, `Booleanish`,
`Numberish`.

## Contents

- [The short version](#the-short-version)
- [Where the intuitive guess is wrong](#where-the-intuitive-guess-is-wrong)
- [Full payload table](#full-payload-table)
- [Callbacks with no originalEvent](#callbacks-with-no-originalevent)
- [Components with no onChange](#components-with-no-onchange)

## The short version

There are five families. Knowing which one a component belongs to is most of the
battle.

| Family | How to read the value | Components |
| --- | --- | --- |
| Native passthrough | `e.target.value` | InputText, InputTextarea, Password, Mention |
| Standard PrimeReact event | `e.value` (also `e.target.value`) | InputMask, InputSwitch, ToggleButton, TriStateCheckbox, MultiStateCheckbox, Dropdown, MultiSelect, ListBox, SelectButton, TreeSelect, AutoComplete, Calendar, Chips, Rating, ColorPicker, InputNumber `onValueChange` |
| Boolean | `e.checked` | Checkbox only |
| No `target` at all | `e.value` only; `e.target.value` throws | InputNumber `onChange`, InputOtp, Slider, Knob, CascadeSelect (select path), Tree / TreeTable / DataTable `onSelectionChange`, OrderList |
| Does not fit | see below | Knob, Editor, FileUpload, PickList, Paginator, ColorPicker |

## Where the intuitive guess is wrong

These are the cases worth reading before writing the handler. Each one type-checks
while doing the wrong thing.

**Checkbox: use `e.checked`.** `e.value` and `e.target.value` both carry the static
`value` prop, which defaults to `null`. With `trueValue`/`falseValue` set,
`e.checked` holds those values rather than a boolean.

**RadioButton: use `e.value`, the exact opposite of Checkbox.** `e.value` is the
option's `value` prop, which is what a radio group needs. `e.checked` is always
`true`, because the callback only fires when a radio is being selected. Do not
"fix" a working radio handler by copying the Checkbox rule onto it.

**InputSwitch and ToggleButton have no `e.checked`.** Both take a `checked` prop,
neither reports through one. The new state is `e.value`. `e.checked` is `undefined`.

**TriStateCheckbox has no `e.checked` either**, and its `target` has no `type` and
no `checked`. Use `e.value`, which cycles `null` to `true` to `false`.

**CascadeSelect has a `target` on clear and no `target` on select.** An
`e.target.value` handler throws `TypeError` the first time someone picks an option
and works fine when they clear it. Use `e.value`.

**CascadeSelect's `e.originalEvent` is not a DOM event.** It is another PrimeReact
event object; the DOM event is at `e.originalEvent.originalEvent`. Calling
`e.originalEvent.stopPropagation()` throws.

**Slider, Knob, InputOtp, and InputNumber's `onChange` have no `target`.** Reading
`e.target.value` throws.

**InputNumber has two callbacks with different shapes.** `onChange` fires per
keystroke and carries no `target`. `onValueChange` fires on model commit and does
carry one. For form state you almost always want `onValueChange`.

**Knob passes `{ value }` and nothing else.** No `originalEvent`, no `target`, no
`stopPropagation`. `e.originalEvent.preventDefault()` throws.

**ColorPicker has no `originalEvent`**, and its `stopPropagation` and
`preventDefault` are empty no-op functions, so calling them appears to work and
does nothing.

**Dropdown, CascadeSelect, and TreeSelect set `value: undefined` when cleared**,
which flips a controlled component to uncontrolled and triggers React's
"changing a controlled input to be uncontrolled" warning. Coalesce to `null`
yourself. MultiSelect correctly clears to `[]`.

**Chips and MultiSelect use `onRemove.value` for opposite things.** In Chips it is
the single removed string; in MultiSelect it is the surviving array. Chips'
`onChange.value` is the surviving array, so within Chips alone the same key means
two different things depending on the callback.

**Calendar's `onSelect.value` is a single `Date` even in `range` and `multiple`
mode**, while `onChange.value` is the array. Driving model state from `onSelect`
breaks range selection.

**AutoComplete's `e.value` type varies by path**: a raw string while free-typing in
single mode, the option object on selection, `null` when `forceSelection` rejects
the text, and no call at all while typing in multiple mode. Handle all four.

**MultiSelect's `onSelectAll` reports `e.checked` as the current value, not the new
one.** Invert it yourself.

**OrderList uses two different key names for the same thing**: `event` from the
reorder buttons and `originalEvent` from drag and drop. Code reading
`e.originalEvent` gets `undefined` half the time.

**PickList has no `e.value`.** The payload is `{ originalEvent, source, target }`
where `target` is the target list array, so `e.target.value` is `undefined` too.

**Editor has no `onChange`.** Passing one is silently ignored, because it is not in
the component's props at all. Use `onTextChange` and read `e.htmlValue`.

**FileUpload has no `onChange`** and never uses the key `value`. `onSelect` gives
`e.files`, `onRemove` gives `e.file` singular, `onClear` is called with no
arguments, and `onValidationFail` receives a bare `File` object rather than a
wrapper.

## Full payload table

| Component | Callback | Payload | Read |
| --- | --- | --- | --- |
| InputText | `onChange` | native React `ChangeEvent` | `e.target.value` |
| InputTextarea | `onChange` | native React `ChangeEvent` | `e.target.value` |
| Password | `onChange` | native React `ChangeEvent` | `e.target.value` |
| Mention | `onChange` | native React event, passed through | `e.target.value` |
| Mention | `onSearch` | `originalEvent`, `trigger`, `query` | `e.query` |
| Mention | `onSelect` | `originalEvent`, `suggestion` | `e.suggestion` |
| Checkbox | `onChange` | `originalEvent`, `value` (static prop), `checked` (new), `target` | **`e.checked`** |
| RadioButton | `onChange` | `originalEvent`, `value` (option value), `checked` (always true), `target` | **`e.value`** |
| TriStateCheckbox | `onChange` | `originalEvent`, `value` (new), `target{name,id,value}` | `e.value` |
| MultiStateCheckbox | `onChange` | `originalEvent`, `value`, `target` | `e.value` |
| InputSwitch | `onChange` | `originalEvent`, `value`, `target` (no `checked`) | `e.value` |
| ToggleButton | `onChange` | `originalEvent`, `value`, `target` (no `checked`) | `e.value` |
| InputNumber | `onChange` | `originalEvent`, `value` - no `target` | `e.value` |
| InputNumber | `onValueChange` | `originalEvent`, `value`, `target` | `e.value` |
| InputMask | `onChange` | `originalEvent`, `value`, `target` | `e.value` |
| InputMask | `onComplete` | `originalEvent`, `value` | `e.value` |
| InputOtp | `onChange` | `originalEvent`, `value` - no `target` | `e.value` |
| Dropdown | `onChange` | `originalEvent`, `value`, `target`; `undefined` on clear | `e.value` |
| Dropdown | `onFilter` | `originalEvent` (real DOM), `filter` | `e.filter` |
| MultiSelect | `onChange` | `originalEvent`, `value` array, `selectedOption`, `target` | `e.value` |
| MultiSelect | `onRemove` | `originalEvent`, `value` = remaining array | `e.value` |
| MultiSelect | `onSelectAll` | `originalEvent`, `checked` = **current**, not new | invert `e.checked` |
| MultiSelect | `onFilter` | nested wrapper, not a DOM event | `e.filter` |
| CascadeSelect | `onChange` select | `originalEvent` (nested), `value` - **no `target`** | `e.value` |
| CascadeSelect | `onChange` clear | `originalEvent`, `value: undefined`, `target` | `e.value` |
| ListBox | `onChange` | `originalEvent`, `value`, `target` | `e.value` |
| SelectButton | `onChange` | `originalEvent`, `value` (`null` when unselecting), `target` | `e.value` |
| TreeSelect | `onChange` | `originalEvent`, `value` keys, `target` | `e.value` |
| AutoComplete | `onChange` | `originalEvent`, `value` (type varies), `target` | `e.value` |
| AutoComplete | `onSelect` / `onUnselect` | `originalEvent`, `value` = the option | `e.value` |
| AutoComplete | `completeMethod` | `originalEvent`, `query` | `e.query` |
| AutoComplete | `onClear` | raw DOM event, unwrapped | `e.target` |
| Calendar | `onChange` | `originalEvent`, `value` `Date`/`Date[]`/`null`, `target` | `e.value` |
| Calendar | `onSelect` | `originalEvent`, `value` = single `Date` always | `e.value` |
| Chips | `onChange` | `originalEvent`, `value` = full array, `target` | `e.value` |
| Chips | `onRemove` | `originalEvent`, `value` = removed string | `e.value` |
| Chips | `onAdd` | `originalEvent`, `value` = added string; return `false` to veto | `e.value` |
| ColorPicker | `onChange` | `value`, `target`; **no `originalEvent`**, no-op `preventDefault` | `e.value` |
| Slider | `onChange` / `onSlideEnd` | `originalEvent`, `value` - no `target` | `e.value` |
| Rating | `onChange` | `originalEvent`, `value` (`null` on cancel), `target` | `e.value` |
| Knob | `onChange` | `value` only | `e.value` |
| Editor | `onTextChange` | `htmlValue`, `textValue`, `delta`, `source` | `e.htmlValue` |
| Editor | `onSelectionChange` | `range`, `oldRange`, `source` | `e.range` |
| FileUpload | `onSelect` | `originalEvent`, `files` | `e.files` |
| FileUpload | `onBeforeSelect` | `originalEvent`, `files`; return `false` to veto | `e.files` |
| FileUpload | `onRemove` | `originalEvent`, `file` singular | `e.file` |
| FileUpload | `onUpload` / `onError` | `xhr`, `files` | `e.files` |
| FileUpload | `onProgress` | `originalEvent`, `progress` | `e.progress` |
| FileUpload | `onClear` | called with no arguments | n/a |
| FileUpload | `onValidationFail` | bare `File` object | the argument itself |
| Tree | `onSelectionChange` | `originalEvent`, `value` | `e.value` |
| TreeTable | `onSelectionChange` | `originalEvent`, `value` | `e.value` |
| DataTable | `onSelectionChange` | `originalEvent`, `value`, `type` | `e.value` |
| OrderList | `onChange` | `value`, plus `event` **or** `originalEvent` by path | `e.value` |
| PickList | `onChange` | `originalEvent`, `source`, `target` arrays; **no `value`** | `e.source` / `e.target` |
| Paginator | `onPageChange` | `first`, `rows`, `page`, `totalPages` | `e.page` / `e.first` |

## Callbacks with no originalEvent

Knob `onChange`, ColorPicker `onChange`, Editor `onTextChange` and
`onSelectionChange`, FileUpload `onUpload` / `onError` / `onClear` /
`onValidationFail`, Paginator `onPageChange`, Dropdown and MultiSelect `onFilter`
on the reset path, and OrderList `onChange` from the reorder buttons.

## Components with no onChange

| Component | Primary callback instead |
| --- | --- |
| Editor | `onTextChange` |
| FileUpload | `onSelect`, plus `onUpload` / `onRemove` / `onClear` |
| Tree, TreeTable, DataTable | `onSelectionChange` |
| Paginator | `onPageChange` |
| IconField, InputIcon | none; they are layout wrappers |

InputNumber has both `onChange` (per keystroke) and `onValueChange` (on commit),
and Slider has both `onChange` and `onSlideEnd`.
