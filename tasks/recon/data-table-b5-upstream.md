# b5 recon — filter (upstream ground truth)

Mirror: `/tmp/next-upstream/data-table` (refreshed this session from
`/home/titan/Works/elm/naive-ui/src/data-table`). Upstream v2.45.3.
Path map for the oracle round: **FilterButton/FilterMenu live in
`src/HeaderButton/` (NOT TableParts/)** — `src/data-table/src/HeaderButton/
FilterButton.tsx` (194 L) + `FilterMenu.tsx` (221 L) + `RenderFilter.ts` (23 L);
pipeline in `src/data-table/src/use-table-data.ts` (:84–:230); gate util
`isColumnFilterable` + `shouldUseArrayInSingleMode` in `src/data-table/src/
utils.ts`; th seam in `src/data-table/src/TableParts/Header.tsx` (:276, :334);
css in `src/data-table/src/styles/index.cssr.ts` (:242 filterable padding,
:349 filter button, :549 filter menu); interface types `src/data-table/src/
interface.ts` (:124 default `current`, :220–:231, :294–:310, :473–:480,
:500–:544); spec `tests/DataTable.spec.tsx` (:278–:380, :616–:631).

## 1. Column surface (interface.ts :294–:310)

    filter?: 'default' | boolean | Filter<T>     // Filter = (value, row) => boolean
    filterOptions?: FilterOption[]                // { label: string, value: FilterOptionValue }
    filterOptionValues?: FilterOptionValue[] | null  // CONTROLLED (multiple)
    filterOptionValue?: FilterOptionValue | null     // CONTROLLED (single)
    filterMode?: 'or' | 'and'                     // default 'or' (implicit)
    defaultFilterOptionValues?: FilterOptionValue[] | null
    defaultFilterOptionValue?: FilterOptionValue | null
    filterMultiple?: boolean                      // effective `!== false` → default TRUE
    renderFilter? / renderFilterIcon? / renderFilterMenu?   // render props

`filter: false`/unset + `filter: true` (async) + `'default'` + fn are the four
shapes; `isColumnFilterable` = `!!column.filter && (!!column.filterOptions
|| !!column.renderFilterMenu)` (utils.ts) — **`filterOptions: []` is truthy in
JS** → explicit empty array still renders the button (empty menu, action bar
only). No kind gate: `isColumnFilterable` checks only `'children' in column`
(group cols — b6); a selection/expand column with filter fields set would pass
(unreachable via TS, runtime-faithful). The th content branch (Header.tsx
:276) renders FilterButton in the NON-selection branch only (selection returns
early) — i.e. normal AND expand columns.

`FilterOptionValue` = `string | number` (interface.ts :229 area) — port is
String-keyed throughout (RowKey precedent); number collapse documented.

## 2. State: mergedFilterState (use-table-data.ts :91–:116)

Controlled columns = dataRelatedCols with `filterOptionValues !== undefined
|| filterOptionValue !== undefined`; for those (selection/expand skipped):

    filterOptionValues === undefined ? (filterOptionValue ?? null) : filterOptionValues

`mergedFilterState = Object.assign(shallowClone(uncontrolledFilterState),
controlledFilterState)` — uncontrolled key order preserved, controlled keys
overwritten in place or appended in column walk order. `FilterState =
Record<string, FilterOptionValue[] | FilterOptionValue | null | undefined>` —
**a key set to `null` (cleared single) is a PRESENT entry**, and the whole
merged map is what the confirm emit carries (createFilterState copies it) —
the port needs a `FilterNull` value variant, not key absence.

Init walk (use-table-data.ts :198–:212, only columns with truthy `filter`):

    filterMultiple            → defaultFilterOptionValues || []
    else defaultFilterOptionValues !== undefined
                              → defaultFilterOptionValues === null ? [] : defaultFilterOptionValues
    else                      → defaultFilterOptionValue ?? null

(null ≡ [] in BOTH branches → port `Maybe (List String)` with `Just []`
covering {null, []}; `defaultFilterOptionValue` undefined ≡ null → port
`Maybe String`.)

## 3. Pipeline: filteredData (use-table-data.ts :118–:190)

columnEntries = basic columns only (skip `type: selection/expand` and
`children` — group). Per row, per column IN ORDER:

    v = state[key]; if (v == null) continue; if (!isArray(v)) v = [v]; if (!v.length) continue
    filter = column.filter === 'default' ? defaultSubstring : column.filter
    if (typeof filter !== 'function') continue      // 'default'/fn pass; `true` (async) skips
    filterMode === 'and' ? (v.some(x => !filter(x, row)) → exclude row)
                         : (v.some(x => filter(x, row)) → continue; else exclude)

defaultSubstring (createDefaultFilter :121): `(v, row) => !!~String(row[key]).indexOf(String(v))`
— port needs the `row -> String` accessor (SorterDefault/SortValue precedent).
Sort runs over filteredData; pagination slices sortedData — both already
wired in the port (b2), only `filteredData` flips from identity to real.

## 4. Emit + page reset (FilterButton.tsx :74–:95, use-table-data :351–:368)

    handleFilterChange(value):
      next = { ...mergedFilterState, [key]: value }        // createFilterState over MERGED
      doUpdateFilters(next, column)                        // fires onUpdateFilters ×3 channels
                                                           // + uncontrolledFilterState = next
      if (paginationBehaviorOnFilter === 'first') doUpdatePage(1)

`paginationBehaviorOnFilter` default **'current'** (interface.ts :124–:127).
Imperative `filter()/filters()/clearFilter()/clearFilters()` (use-table-data
:411–:427) replace/blank the UNCONTROLLED state only. Port: pure
`filtersAfterChange` + caller-owned `filterStates` + one
`onUpdateFilters (state, sourceColumnKey)` channel; the page reset on
`PaginationFirst` is the caller's (lastSelectedKey precedent — flag carried,
applied caller-side).

## 5. Trigger DOM (FilterButton.tsx render; NO own th padding change)

Popover: `trigger="click"`, `placement="bottom"`, `style={{padding: 0}}` on
the popover body, `{...filterIconPopoverProps}` spread (runtime, caller).
Trigger (renderFilter/renderFilterIcon NOT given — port models neither):

    <div data-data-table-filter
         class="n-data-table-filter [--active] [--show]">     // object key order: active, show
      <NBaseIcon><FilterIcon/></NBaseIcon>                    // i.n-base-icon (sorter precedent)
    </div>

`--active` = mergedFilterValue is a non-empty array or non-null scalar;
`--show` = the popover's local `showPopover` ref. mergedFilterValue for a
MISSING key: multiple → `[]`, single → `null` (FilterButton :48–:58). Click
toggles the popover runtime (port: `onFilterTriggerClick key`, `--show` from
`filterMenuShown` keys — caller-owned show state, check-extra precedent).

FilterIcon bytes (`_internal/icons/Filter.tsx`): svg `viewBox="0 0 28 28"
version="1.1" xmlns="http://www.w3.org/2000/svg"` > g[stroke=none
stroke-width=1 fill-rule=evenodd] > g[fill-rule=nonzero] > path d="M17,19
C17.5522847,19 18,19.4477153 18,20 C18,20.5522847 17.5522847,21 17,21 L11,21
C10.4477153,21 10,20.5522847 10,20 C10,19.4477153 10.4477153,19 11,19 L17,19 Z
M21,13 C21.5522847,13 22,13.4477153 22,14 C22,14.5522847 21.5522847,15 21,15
L7,15 C6.44771525,15 6,14.5522847 6,14 C6,13.4477153 6.44771525,13 7,13 L21,13
Z M24,7 C24.5522847,7 25,7.44771525 25,8 C25,8.55228475 24.5522847,9 24,9 L4,9
C3.44771525,9 3,8.55228475 3,8 C3,7.44771525 3.44771525,7 4,7 L24,7 Z".

## 6. Menu DOM (FilterMenu.tsx; popover body → caller-owned NUI.Popover)

    <NPopover style padding:0>                              // caller runtime
      <div class="n-data-table-filter-menu [--rtl]"          // style: 3 --n-action-* vars
        style="--n-action-padding:8px 12px;--n-action-button-margin:0 8px 0 0;
               --n-action-divider-color:<dividerColor>"      // filterMenuCssVars, DataTable.tsx :286
        <NScrollbar>                                         // max-height 240px rides CSS
          multiple ? NCheckboxGroup value=arr-or-null class=n-data-table-filter-menu__group
                     (root: <div class="n-checkbox-group n-data-table-filter-menu__group"
                       role="group"> — own class then fallthrough, NO vars)
                   : NRadioGroup name=String(column.key) class=__group
                     (root: <div class="n-radio-group n-data-table-filter-menu__group"
                       style=radio-group cssVars> — name lands on inputs only)
          per option: NCheckbox/NRadio value=option.value, label child
        </NScrollbar>
        <div class="n-data-table-filter-menu__action">
          <NButton size="tiny">Clear</NButton>               // locale.clear
          <NButton size="tiny" type="primary">Confirm</NButton>  // locale.confirm
        </div>

Temporal value = menu-local ref init props.value; checkbox toggle =
CheckboxGroup toggleCheckbox (copy array; check PUSH at end if absent; uncheck
splice FIRST index — click order, not option order); radio = direct value.
`shouldUseArrayInSingleMode` (utils.ts :107–:113) =
`filterOptionValues !== undefined || (filterOptionValue === undefined &&
defaultFilterOptionValues !== undefined)`.

    radioGroupValue: arrayMode ? ((nonEmptyArray && [0]) || null)
                              : (nonArray ? value : null)
    checkboxGroupValue: isArray ? value : null
    handleChange(v): multiple && isArray → v; arrayMode && !isArray → [v]; else → v
    confirm → doChange(temporal) + close; clear → doChange(multiple||arrayMode ? [] : null) + close

enUS bytes (locales/common/enUS.ts :54–:59): `confirm: 'Confirm'`,
`clear: 'Clear'` — caller-supplied in the port (b3 selection-menu precedent).

## 7. th seam (Header.tsx :276–:341)

FilterButton renders AFTER `div.n-data-table-th__title-wrapper` (sibling,
before ResizeButton — resizable deferred). th class object order:
`n-data-table-th` + fixed + `--sorting` + **`--filterable`** + `--sortable` +
`--selection` + `--last` + className (insert between sorting and sortable).
CSS: `--filterable` → `padding-right: 36px`; `--filterable--sortable` →
`padding-right: calc(var(--n-th-padding) + 36px)` (styles/index.cssr.ts :242).
`--n-filter-size: 15px` + action vars already in the port theme
(Theme/DataTable.elm :90/:93–:95) and `--n-filter-size` already emitted
(DataTable.elm :3004). **All filter CSS selectors already extracted into
css/naive-ui.css (14 hits) → prep = NO-OP** (b2/b3 pattern; document in feat).

## 8. Spec ground truth (tests/DataTable.spec.tsx)

:297 address filter `row.address.includes(value)`; :349 `filter({address:
'London'})` → filtered ['Jim Green','Joe Black'], page 1 (pageSize?) shows
['Jim Green']; :365 + `sort('age','descend')` same rows; :616 `filter({address:
['Sidney','New York']})` (or-mode array) → scores [[98,98],[66,60],[89,70]].
The imperative-API tests map to port eq pins over `filteredData`/
`filtersAfterChange` with caller-owned states.

## 9. Port design decisions (feat plan)

- Column gains (after `sortOrder`): `filter : Maybe (Filter row)`
  (`FilterDefault (row -> String)` | `FilterCustom (String -> row -> Bool)` |
  `FilterAsync`; Nothing ≙ false/unset), `filterOptions : Maybe (List
  FilterOption)` (Just [] ≙ explicit empty array — button still renders),
  `filterOptionValues : Maybe (List String)` (Nothing ≙ undefined; null ≡
  Just [] documented), `filterOptionValue : Maybe (Maybe String)` (Nothing ≙
  undefined = uncontrolled; Just Nothing ≙ null), `filterMode : FilterMode`
  (FilterOr default), `defaultFilterOptionValues : Maybe (List String)`,
  `defaultFilterOptionValue : Maybe String`, `filterMultiple : Bool` (True).
- `FilterValue = FilterNull | FilterOne String | FilterMany (List String)`.
- Options gains: `filterStates : List (String, FilterValue)` (seed
  `defaultFilterStates`), `onUpdateFilters : Maybe (List (String,
  FilterValue) -> String -> msg)` (state + source key; replaces 3 channels),
  `filterMenuShown : List String` (--show), `onFilterTriggerClick : Maybe
  (String -> msg)`, `paginationBehaviorOnFilter : PaginationBehavior`
  (PaginationCurrent default).
- Exports: defaultFilterStates, mergedFilterStates, filtersAfterChange,
  isColumnFilterable, shouldUseArrayInSingleMode, filterMenu (the body: root
  raw Html via Element.html → Element for NUI.Popover children; embedChild
  scrollbar/group/buttons — display:contents seam family), FilterMenuOptions
  {multiple, options, radioGroupName, arraySingleMode, value, rtl, onChange,
  onConfirm, onClear, clearLabel, confirmLabel} + defaults.
- NUI.Radio.GroupOptions gains `attributes : List (Element.Attribute msg)`
  (fallthrough-class seam — `__group` on the radio-group root; group cssVars
  stay inside NUI.Radio). Checkbox group = raw div (class + role) — upstream
  root has NO vars.
- Trigger/filter button/th/filterable wired in DataTable.elm view; examples
  section gains a filterable-column demo + copy update ("filter ships in a
  later batch" is now stale); check-dom: NO new root class (trigger is th
  DOM; menu is caller-side).
