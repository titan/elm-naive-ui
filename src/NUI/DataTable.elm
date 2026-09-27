module NUI.DataTable exposing
    ( Align(..)
    , CheckAction(..)
    , CheckEmit
    , Column
    , ColumnChild(..)
    , ColumnEllipsis(..)
    , ColumnKind(..)
    , Filter(..)
    , FilterMenuOptions
    , FilterMode(..)
    , FilterOption
    , FilterValue(..)
    , FixedSide(..)
    , Options
    , PaginationBehavior(..)
    , SelectionOption(..)
    , Size(..)
    , SortOrder(..)
    , SortState
    , SortValue(..)
    , Sorter(..)
    , SorterCompare(..)
    , SummaryCell
    , SummaryPlacement(..)
    , TableLayout(..)
    , allRowsChecked
    , boundedPage
    , checkedKeysAfterCheck
    , checkedKeysAfterCheckAll
    , checkedKeysAfterRowClick
    , checkedKeysAfterUncheck
    , checkedKeysAfterUncheckAll
    , columnDefaults
    , createNextSorter
    , cssVars
    , defaultExpandAllKeys
    , defaultFilterStates
    , defaultSortStates
    , defaults
    , deriveNextSorter
    , filterMenu
    , filterMenuDefaults
    , filteredData
    , filtersAfterChange
    , fixedColumnLeftMap
    , fixedColumnRightMap
    , getMultiplePriority
    , getSortFunction
    , headerCheckboxDisabled
    , headerRows
    , isColumnFilterable
    , isColumnSorting
    , isSortable
    , leafColumns
    , mergedCheckedRowKeys
    , mergedFilterStates
    , mergedItemCount
    , mergedPageSize
    , mergedPaginationOpts
    , mergedSortStates
    , nextSortOrder
    , paginatedData
    , shouldUseArrayInSingleMode
    , showPagination
    , someRowsChecked
    , sortValueCompare
    , sortedData
    , toggleExpandedRowKey
    , view
    )

{-| Naive UI's `DataTable` (`n-data-table`), the advanced data table —
rebuilt on elm-ui.

    import NUI.DataTable exposing (columnDefaults, defaults)

    NUI.DataTable.view theme
        { defaults
            | rowKey = .id
            , columns =
                [ { columnDefaults | key = "name", title = "Name", view = .name >> Element.text }
                , { columnDefaults
                    | key = "age"
                    , title = "Age"
                    , view = .age >> String.fromInt >> Element.text
                    , width = Just 120
                  }
                ]
            , data = rows
        }

(Record updates bind `defaults` to a local first — see `NUI.Button`.)

DOM (batch-4 — three body shapes; `headerInBody = maxHeight unset &&
!flexHeight`, the scrollbar wraps unless the merged layout is `fixed`
with no explicit scroll props):

    div.n-data-table [--rtl] [--bordered] [--bottom-bordered] [--single-line]
                     [--single-column] [--loading] [--flex-height] [--empty]
      style = the 47 `--n-*` vars
      ├─ div.n-data-table-wrapper
      │  └─ div.n-data-table-base-table
      │     ├─ basic (no maxHeight/flexHeight, scrollable):
      │     │  └─ div.n-data-table-base-table-body (the `n-scrollbar` root)
      │     │     └─ div.n-scrollbar-container > div.n-scrollbar-content
      │     │        ├─ table.n-data-table-table [inline table-layout:{merged}]
      │     │        │  ├─ colgroup > col (style width/min-width/max-width — always;
      │     │        │  │   selection/expand cols default the width pair to 40px)
      │     │        │  ├─ thead.n-data-table-thead[data-n-id] (iff showHeader)
      │     │        │  │  └─ tr.n-data-table-tr (ONE PER HEADER ROW —
      │     │        │  │     grouped columns stack) > th[colspan rowspan]
      │     │        │  │     [data-col-key] [--fixed-left|right] [--sorting]
      │     │        │  │     [--filterable] [--sortable] [--selection] [--last]
      │     │        │  │     style: [left/right fixed offset] width [text-align]
      │     │        │  │     ├─ basic/group col: div.n-data-table-th__title-wrapper
      │     │        │  │     │   (title div [> th__ellipsis | NEllipsis] + sorter
      │     │        │  │     │    span iff sortable — never on a group th)
      │     │        │  │     ├─ div.n-data-table-filter [--active] [--show]
      │     │        │  │     │   [data-data-table-filter] > i.n-base-icon >
      │     │        │  │     │   FilterIcon svg            (iff filterable)
      │     │        │  │     └─ selection col (multiple): NCheckbox
      │     │        │  │         [+ i.n-data-table-check-extra iff column options]
      │     │        │  └─ tbody.n-data-table-tbody[data-n-id]             (iff rows)
      │     │        │     └─ tr.n-data-table-tr [--summary] [--striped]
      │     │        │        [--expanded] > td[colspan rowspan][data-col-key]
      │     │        │          [--summary] [--sorting] [--fixed-left|right]
      │     │        │          [--{align}-align] [--selection|--expand]
      │     │        │          [--last-col] [--last-row]
      │     │        │          style: [text-align] [width] [left/right offset]
      │     │        │          --indent-offset:
      │     │        └─ div.n-data-table-empty[--hide] [style bodyStyle +
      │     │           sticky string iff xScrollable] > NEmpty        (iff empty)
      │     ├─ split (maxHeight/flexHeight): div.n-data-table-base-table-header
      │     │  > table [style min-width?+table-layout:fixed] > colgroup + thead,
      │     │  then the body scrollbar WITHOUT the inline thead (its slot
      │     │  renders ONLY the empty div when empty — no table)
      │     └─ bare (merged layout fixed, no scrollX/maxHeight/flexHeight —
      │        `tableLayout = TableFixed` or any ellipsis column): the table
      │        [table-layout:fixed] + empty div directly, NO scrollbar wrapper
      └─ div.n-data-table__pagination > NPagination + the prefix slot   (iff pagination shown)
      └─ div.n-data-table-loading-wrapper > the NBaseLoading chain     (iff loading)

Cell content is `Element msg`, embedded through `Element.layoutWith`
(`display: contents`, the `NUI.Table` precedent); the scroll area is
`NUI.Scrollbar.view`, the empty state `NUI.Empty.view` and the pager
`NUI.Pagination.view`.

Divergences (documented):

  - **Batch-6 scope.** Group headers (`children`), summary rows
    (`summary` + `summaryPlacement`) and merge cells (`colSpan` /
    `rowSpan` / `titleColSpan` + the `cordToPass` skip grid) ship here —
    the two-pass `headerRows` walk, the leaf-flatten of every data-side
    column pipeline, the summary prepend / append around the expand
    tiling and the span math / skip grid of the body cells — on top of
    batch-5's filter, batch-4's scroll / layout, batch-3's selection /
    expand, batch-2's sort / pagination and the b1 core. Resizable
    columns, virtual scroll and tree data (`children` on ROWS / cascade /
    async `onLoad`) remain upcoming batches; the port models flat data
    only.
  - **`rowClassName` / `rowAttributes` are skipped on summary rows.**
    Upstream invokes both with `(summaryRecord, -1)` on every row — the
    summary payload included; the port's `row ->` signatures cannot carry
    the assoc-list summary record, so summary rows take neither (the
    `--summary` tr class still lands; DOM-identical unless a caller's
    fn keyed off the summary row).
  - **Summary rows never tile.** Upstream's expand tiling would run over
    a summary entry whose `__n_summary__${i}` key a caller authored into
    `expandedRowKeys` (the tiling gates read the summary RECORD —
    `renderExpand(record, -1)`); the port's tiling needs a data row and
    skips summary entries outright — an inherited edge only a caller
    authoring Vue-internal keys reaches. The `--expanded` tr class
    likewise never lands on a summary row in the port (same key-lookup
    gap).
  - **The cross-row `--hover` coordination is not ported.** Upstream's
    `cordKey` / `hoverKey` maps (a merged td highlights its whole area on
    hover) are runtime mouse state — a static render never mounts them,
    so the `td--hover` class is unreachable here (the tr-hover cssr is
    unaffected; documented, DOM-identical at rest).
  - **Group nesting is permissive.** Upstream types `children` as base
    columns only — a selection / expand / further-group column under a
    group is a TS error; the port's flat record accepts it and walks the
    leaves (`leafColumns` finds nested special columns; upstream's
    `selectionColumnRef` short-circuits at the first group, so a
    selection column AFTER a group is silently ignored upstream but
    found here). Group columns carry their `fixed` / `width` / `align` /
    `className` / ellipsis through the same th seams (CommonColumnInfo
    upstream), and a `Just []` children list is a group with an empty
    row — `colspan=0`, byte-faithful. Related: **`children` rides a
    `ColumnChild` wrapper** — Elm forbids a record alias referencing
    itself, so the child list is `List (ColumnChild row msg)` (a
    one-token unwrap per child, the recursion carrier of the
    `NUI.Tree`-style wrapper with the flat-record update ergonomics
    kept).
  - **The summary return collapses single-vs-array.** Upstream's
    `CreateSummary` returns a row object or an array of them (distinct
    keys `__n_summary__` / `__n_summary__${i}`, Vue-internal — never a
    DOM byte); the port's fn returns a list and the single object is the
    one-element list.
  - **Fixed GROUP columns flatten to leaves.** Upstream's fixed maps
    register the fixed group's own key and auto-fix its descendants
    through map membership (their ths take `--fixed-left` + offsets off
    the group's `fixed` alone); the port's leaf walk keys only columns
    marked `fixed` THEMSELVES — a fixed group whose children carry no
    own `fixed` renders unfixed. Flat column lists are unaffected
    (membership ⟺ `column.fixed`).
  - **Render-prop sorter customizations are not modelled.** Upstream's
    `renderSorter` / `renderSorterIcon` (per-column and the global
    `DataTable.renderSorter` component prop) and `customNextSortOrder` have
    no Elm surface: the sort button always renders the base icon span and
    the click cycle is fixed `false → descend → ascend`.
  - **Render-prop filter customizations are not modelled.** Upstream's
    `renderFilter` / `renderFilterIcon` / `renderFilterMenu` (per-column
    and the global `DataTable.renderFilter` component prop) and the
    `filterIconPopoverProps` popover spread have no Elm surface:
    `isColumnFilterable` reads `filter` × `filterOptions` only (upstream's
    third leg is `|| !!column.renderFilterMenu`) and the trigger always
    renders the base filter icon.
  - **The filter popover is trigger + caller runtime.** Upstream wraps
    the trigger in `NPopover` (`trigger="click"`, `placement="bottom"`,
    `style padding: 0`); the port renders the at-rest trigger — `--active`
    from the merged state, `--show` from `filterMenuShown`, the click
    firing `onFilterTriggerClick` — and the menu body is the exported
    `filterMenu` over the caller's `NUI.Popover` (the selection-menu
    precedent). The menu-local temporal value is caller-owned too:
    checkbox checks push / splice it, radios set it (`onChange`), the
    confirm commits `filtersAfterChange opts column value` through
    `onUpdateFilters` and the clear commits the cleared payload
    (`[]` in multiple / array-single mode, else `null`).
  - **One filter channel + caller-applied page reset.** Upstream's
    `doUpdateFilters` fires three handlers
    (`onUpdate:filters` / `onUpdateFilters` / deprecated `onFiltersChange`)
    with `(filterState, sourceColumn)`, and `FilterButton`'s change handler
    then resets the page on `paginationBehaviorOnFilter === 'first'`;
    the port carries `onUpdateFilters` (the next whole state + the source
    column key) and the flag, the caller applying the reset through
    `onUpdatePage`. The imperative `filter()` / `filters()` /
    `clearFilter()` / `clearFilters()` surface is the caller writing
    `filterStates` (`filtersAfterChange` is `createFilterState` over the
    merged state — upstream's confirm emit carries the whole merged map,
    controlled parts included).
  - **Filter `null` collapses.** `filterOptionValues: null` ≡ `Just []`
    (both skip filtering and read inactive — upstream's `null` entry and
    its empty array agree downstream); `defaultFilterOptionValues: null`
    ≡ `[]` ≡ `Just []` (both seed the empty array). `filterOptionValue`'s
    undefined / null split IS modelled — `Nothing` is the uncontrolled
    column, `Just Nothing` upstream's controlled `null`.
  - **`filterMultiple` is a `Bool`, not upstream's tri-state.** The menu /
    trigger read upstream `filterMultiple !== false` (default multiple,
    FilterButton.tsx :41), but the uncontrolled seed walk branches on
    TRUTHINESS (`if (column.filterMultiple)` — `undefined` takes the
    single branch, use-table-data.ts :198); the port's `Bool` (default
    `True` ≡ `!== false`) collapses `undefined` onto `true`, so the seed
    walk takes the multiple branch. Every cell coincides downstream (a
    `null` and an `[]` seed agree everywhere) except `filterMultiple`
    unset + `defaultFilterOptionValue` set (`defaultFilterOptionValues`
    unset): upstream seeds the scalar (an `--active` trigger with no
    checked boxes), the port seeds `[]` — a contradictory configuration
    (a single-mode default on a multiple-mode column) the `Bool` cannot
    express.
  - **Menu labels and option values are port-typed.** `clearLabel` /
    `confirmLabel` are caller-supplied (`filterMenuDefaults` carries the
    enUS bytes `'Clear'` / `'Confirm'` — upstream injects locale data),
    `FilterOption.value` is `String` (upstream `string | number`, the
    `RowKey` collapse), and the radio group `name` (`String(columnKey)`)
    lands nowhere — the radio port renders no `<input>` (the `BodyRadio`
    precedent).
  - **One checked-rows channel, one expanded-rows channel.** Upstream's
    `doUpdateCheckedRowKeys` fires three handlers (`onUpdate:checkedRowKeys`,
    `onUpdateCheckedRowKeys`, deprecated `onCheckedRowKeysChange`) with
    `(keys, rows, { row, action })`, and `doUpdateExpandedRowKeys` two; the
    port carries `onUpdateCheckedRowKeys` (the full payload, `CheckEmit`)
    and `onUpdateExpandedRowKeys` (keys only) — `emitRows` drops keys that
    resolve to no row, where upstream pushes `undefined` holes (reachable
    only with caller-authored bogus keys).
  - **`checkedRowKeys` / `expandedRowKeys` are single caller-owned fields.**
    Upstream's controlled-prop / uncontrolled-internal split collapses:
    the caller seeds their model (`defaultCheckedRowKeys`,
    `defaultExpandedRowKeys`, or `defaultExpandAllKeys` for the flat-data
    reading of `defaultExpandAll` — which seeds nothing without an
    `expandable` fn, an upstream truthiness quirk kept byte-faithful) and
    passes the current list; the pure `checkedKeysAfter*` helpers are the
    `doCheck` / `doUncheck` / `doCheckAll` / `doUncheckAll` transforms,
    following the flat-data treemate derivation (check = display state then
    appended new keys; uncheck = display state minus the keys; display
    merge = data-order members of the source list, `multiple = False`
    slicing to the first key). Indeterminate keys are always `[]` on flat
    data, so body checkboxes pass `indeterminate = False`.
  - **`lastSelectedKey` is caller-owned** (upstream keeps it as component-
    instance mutable state, init `''`): pass the clicked row's key back
    through `Options.lastSelectedKey` — the emit payload's `row` carries it
    — and `checkedKeysAfterRowClick` runs the shift-click range algorithm
    (current-page rows, `disabled` filtered) over `paginatedData`.
  - **The selection menu is trigger-icon + caller runtime.** Upstream
    wraps the `i.n-data-table-check-extra` chevron-down trigger in an
    `NDropdown`; the port renders the at-rest trigger icon only (its click
    fires `onCheckExtraClick`) — the menu body, positioning and the
    `'_n_all__'` / `'_n_none__'` whole-table actions are the caller's
    `NUI.Dropdown` runtime over `checkedKeysAfterCheckAll` /
    `checkedKeysAfterUncheckAll` with `wholeTable = True`; custom options
    keep their own `onSelect` over the page rows. The menu labels are
    locale data upstream (enUS `'Select all in the table'` / `'Unselect all
    in the table'`) — caller-supplied here.
  - **`stickyExpandedRows` needs a measured width.** Upstream reads the
    body's `ResizeObserver` width; the port takes the caller-measured
    `Options.bodyWidth` (`Nothing` renders the sticky wrapper without the
    inline width, as upstream does before its first measurement).
  - **`renderExpandIcon` replaces the chevron inside the expand trigger**
    (upstream's table-level renderable slot); the custom icon and the
    `renderExpand` content ride the same `display: contents` embed wrapper
    as cell content, and the raw-SVG default trigger does not. Upstream's
    expand-trigger `onMousedown` `preventDefault` has no Elm surface
    without a no-op `msg` and leaves no DOM byte — text-selection dragging
    from the trigger differs.
  - **Body radios inherit the radio port's no-input edge.** Upstream's
    `BodyRadio` passes `name = componentId` onto the inner
    `<input class="n-radio-input">`; the `NUI.Radio` port renders no input,
    so the name lands nowhere (DOM otherwise equal), and clicking an
    already-checked radio fires nothing either way (upstream's change event
    never fires; the port gates `onChange` on `checked`).
  - **`loading` gates stay caller-side.** Upstream's `doCheck` / `doUncheck`
    / `doCheckAll` / `doUncheckAll` return early while `props.loading`; the
    port's pure `checkedKeysAfter*` helpers do not (the caller simply does
    not apply them while loading). The DOM surface IS batch-4: the root
    `--loading` class, the `n-data-table-empty--hide` empty dimmer, the
    force-disabled pager and the `n-data-table-loading-wrapper` overlay
    with the `NBaseLoading` chain.
  - **Selection/expand columns are flat-record fields, not variant types.**
    `Column.kind` discriminates; upstream's TS `never` fields become
    ignored-if-set with one byte-verified asymmetry: the controlled-sorter
    filter gates `kind /= KindSelection` only (upstream gates
    `type !== 'selection'`, use-sorter.ts:112), so a sorter on an expand
    column behaves like a normal column's and `defaultSortStates` seeds
    either kind — both unreachable upstream. The `--sorting` class
    comparison stays on the raw `key` (upstream `isColumnSorting`), which
    selection/expand columns never match upstream (`key` undefined there).
  - **The selection/expand `<col>` width pair defaults to 40px**
    (`getStringColWidth`'s `SELECTION_COL_WIDTH` / `EXPAND_COL_WIDTH`
    fallbacks) while the th/td inline `width` keeps upstream's bare
    `pxfy(column.width)` — `undefined` and dropped when unset. The
    `data-col-key` identity is the `__n_selection__` / `__n_expand__`
    sentinel (`getColKey`), not the caller key.
  - **One sorter-change channel.** Upstream's `doUpdateSorter` fires
    `'onUpdate:sorter'`, then `onUpdateSorter`, then the deprecated
    `onSorterChange`, and the component exposes imperative
    `sort(columnKey, order)` / `clearSorter()` methods; the port carries
    `onSorterChange` only — the imperative surface is the caller applying
    the exposed pure `createNextSorter` / `deriveNextSorter` (empty key
    ≙ `clearSorter`).
  - **`column.cellProps` is not modelled.** Upstream's
    `CommonColumnInfo.cellProps` resolves per-cell class / style / attrs
    onto every td of the column (`resolvedCellProps`); the field is
    absent — extend `Column` when a batch needs it.
  - **`upsertSortState` replaces every same-key state.** Upstream's
    `updateSortStatesByNewSortState` replaces the FIRST matching index
    only; reachable only with caller-authored duplicate keys in
    `sortStates` / columns (`defaultSortStates` / `deriveNextSorter`
    never produce duplicates).
  - **`getSortFunction` omits upstream's truthy-`columnKey` gate** on the
    default-sorter branch (`columnKey &&`): a `""`-keyed `SorterDefault`
    column diverges (upstream ties through `row['']` being undefined;
    the port sorts by the accessor) — pathological.
  - **An ordinal `compare` stands in for `localeCompare`** in the default
    sorter (`sortValueCompare`) — Elm has no `String.compare` / ICU
    collation, so string ordering is by code point.
  - **One page / page-size handler channel.** Upstream fires the pagination
    object's own handlers, then the table-level `onUpdate:page` /
    `onUpdate:pageSize`, then the deprecated `onChange` / `onPageSizeChange`,
    then writes uncontrolled refs; Elm carries the table-level
    `onUpdatePage` / `onUpdatePageSize` only, and `mergedPaginationOpts`
    replaces the pagination record's own handlers with them. Upstream also
    force-disables the pager while `loading` — the override is in force
    since the loading batch (upstream's `disabled={loading}` rides AHEAD
    of the pagination spread, so an explicit `disabled: false` key in the
    caller's pagination object would override IT — a distinction the
    port's `Bool` field cannot express, and every expressible caller
    state renders the same either way).
  - **`pagination.defaultPage` / `defaultPageSize` seeds are caller-owned.**
    `NUI.Pagination` has no such fields, so callers seed their model and
    pass `currentPage` / `pageSize` explicitly; the pagination prefix
    (upstream: a render-prop on the pagination object) rides
    `paginationPrefix` into the pager's prefix slot.
  - **The sort click handler only attaches to a th when the column is
    sortable and `onSorterChange` is set.** Upstream attaches the listener
    to every basic-column th and no-ops inside it — listener presence is
    not a DOM byte, so this is a compile-time guard, not a port change.
  - **JS sort is stable by spec**; `List.sortWith`'s tie order is an
    implementation detail — if a pinned tie order ever disagrees, re-derive
    from the upstream bytes.
  - **`data-n-id` is the constant `"1"`.** Upstream stamps a random seemly
    component id on thead/tbody; it only keys the fixed-column ACTIVE-shadow
    cssr (`[data-n-id] [data-col-key]::after/before`), which mounts at
    runtime only when the scroll position activates a column — unreachable
    in a pure render, so the shadow strips never mount (the static
    `cM('fixed-left')` sticky / z-index / geometry rules DO ship, and the
    `--n-box-shadow-*` vars stay on the root). Upstream's
    `--transition-disabled` imperative toggling is the same story — added
    post-mount, removed on first measure; the initial render carries
    neither.
  - **`tableLayout` merges per upstream** (`mergedTableLayoutRef`):
    `fixed` when `flexHeight` / `maxHeight` / any ellipsis column (virtual
    scroll is the fourth upstream trigger — out of scope), else the
    caller's `tableLayout`. A `fixed` merged layout with no scrollX /
    maxHeight / flexHeight makes the body NScrollbar render the slot BARE
    (no `n-scrollbar` wrapper, no `n-data-table-base-table-body` class,
    the bodyStyle dropped) — byte-faithful to upstream's
    `if (!scrollable) return slot`.
  - **`title` is a plain `String`** until the header-render batch (upstream
    also accepts a render function returning VNodes).
  - **`rowAttributes` land verbatim after the row's `class` attribute.**
    Upstream merges `rowProps(row, index).class` into the row's class list;
    Elm attributes are opaque, and a caller `Html.Attributes.class` would
    replace the whole `className` (Elm properties are last-wins), so prefer
    `rowClassName` for classes.
  - **Scrollbar-content children ride elm-ui layout wrappers.** The table
    and the empty node reach `.n-scrollbar-content` as
    `display: contents` wrapper divs (the `NUI.Scrollbar` child-embedding
    shape shared with the menu consumers), not as flat children — the
    first raw `<table>` consumer. Verified equivalent: no cssr rule on
    either side uses a direct-child combinator past the content div, and
    the `--empty` height chain targets the content div itself.
  - **`Column.width` / `scrollX` / `maxHeight` / `minHeight` are
    `Maybe Int` (px).** Upstream accepts `number | string` (`'10%'`);
    a string form arrives if a batch needs it. The port's `showHeader` is
    an extension — upstream has NO `show-header` prop (the header always
    renders, inline or discrete); the port gates both headers on it.
    Upstream's `scrollbarProps` (attr passthrough onto the body
    NScrollbar) has no surface — extend `NUI.Scrollbar.Options` if a
    batch needs it.
  - **`formatLength`'s zero special-case is not reproduced on the scroll /
    layout length seams.** Upstream formats the body fallthrough style
    (`max-height` / `min-height`), the scrollbar content `min-width` +
    `width:100%`, the discrete header's `min-width` and the `<col>` width
    pair through `_utils`'s `formatLength`, whose `0` input renders the
    bare `'0'` — every non-zero number is `Npx`, exactly like the port's
    `pxfy`. A caller-set `Just 0` on those seams therefore renders `0px`
    (CSS-equivalent), reachable only with that degenerate input; the
    th / td inline `width` and the fixed-column offsets go through
    seemly's `pxfy` upstream, where `0` really is `'0px'` (the port
    matches, pinned). Same family: upstream guards the content
    `width:100%` with `if (scrollX)` (a truthiness check), so `scrollX =
    0` drops it where the port keeps it.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events
import NUI.Button
import NUI.Checkbox
import NUI.Dropdown
import NUI.Ellipsis
import NUI.Empty
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Pagination
import NUI.Radio
import NUI.Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.DataTable as DataTableTheme
import NUI.Types as T
import Svg


{-| Upstream `DataTableSize` — `'small' | 'medium' | 'large'`; like upstream
it emits no class and only keys the font-size / th-padding / td-padding
variables (`mergedSizeRef` defaults medium).
-}
type Size
    = Small
    | Medium
    | Large


{-| Upstream `CommonColumnInfo.align` — `'left' | 'center' | 'right'`. Sets the
inline `text-align` on the cells (and the header unless `titleAlign`
overrides it) and, redundantly, the `n-data-table-td--{align}-align` class.
-}
type Align
    = AlignLeft
    | AlignCenter
    | AlignRight


{-| Upstream `fixed: 'left' | 'right'` on a column — the sticky-column
surface (`use-scroll.ts`'s fixed maps drive the inline `left` / `right`
offsets and the `--fixed-left` / `--fixed-right` classes; the shadow
strips ride the static cssr `cM('fixed-left')` rules).
-}
type FixedSide
    = FixedLeft
    | FixedRight


{-| Upstream `tableLayout: 'auto' | 'fixed'` (default `'auto'`) — the
base layout, overridden to `fixed` by `flexHeight` / `maxHeight` / any
ellipsis column (`mergedTableLayoutRef`, DataTable.tsx :191).
-}
type TableLayout
    = TableAuto
    | TableFixed


{-| Upstream `Column.ellipsis` — `true` (the plain wrappers) or the
`EllipsisProps` object (the `NEllipsis` component form). The port splits
by RENDER target, not by tooltip-ness: `EllipsisPlain` is upstream's
`true` AND the th's object-without-Tooltip case (both render the same
plain wrapper div); `EllipsisOpts` is the `NEllipsis` form — the th's
object-with-tooltip and the td's object (tooltip or not — the td/th
asymmetry is upstream's, Cell.tsx :59 vs Header.tsx :254). The port's
`NUI.Ellipsis` has no tooltip surface — that gap is the Ellipsis
module's documented edge, inherited here.
-}
type ColumnEllipsis msg
    = EllipsisPlain
    | EllipsisOpts (NUI.Ellipsis.Options msg)


{-| Upstream `SortOrder` — `'ascend' | 'descend' | false` (`NoSort` is the
`false`; upstream's comment notes `null` may be added for compat). Drives
the sorter icon's `--asc` / `--desc` flags and the comparator's sign.
-}
type SortOrder
    = Ascend
    | Descend
    | NoSort


{-| The realization of upstream's `row[columnKey]` for the default sorter —
the three shapes `getDefaultSorterFn` distinguishes: `null`, number, string
(Elm columns have no `row[columnKey]`, so the caller supplies the accessor).
-}
type SortValue
    = SortNumber Float
    | SortString String
    | SortNull


{-| The `compare` field of upstream's `SorterMultiple` — `'default'`
(`CompareDefault`, over the `SortValue` accessor) or an explicit compare fn
(`CompareBy`); an absent `compare` is modelled by `Nothing` at the
`SorterMultiple` site.
-}
type SorterCompare row
    = CompareDefault (row -> SortValue)
    | CompareBy (row -> row -> Basics.Order)


{-| Upstream `Column.sorter` (`Sorter<T> | boolean | 'default'`):
`SorterDefault` is `sorter: 'default'`, `SorterBy` a plain compare fn,
`SorterMultiple` the `{ multiple, compare? }` object, `SorterAsync`
`sorter: true` (async/remote sorting — the state is tracked and rendered,
the data is the caller's). Upstream's `false` / `undefined` (show nothing)
is the plain `Column.sorter = Nothing`.
-}
type Sorter row
    = SorterDefault (row -> SortValue)
    | SorterBy (row -> row -> Basics.Order)
    | SorterMultiple Int (Maybe (SorterCompare row))
    | SorterAsync


{-| Upstream `Column.filter` (`'default' | boolean | Filter<T>`):
`FilterDefault` is `filter: 'default'` (the substring default filter over
the caller-supplied `row[columnKey]` accessor — the `SortValue`
precedent), `FilterCustom` a plain `(value, row) => boolean`, `FilterAsync`
`filter: true` (async / remote filtering — the button renders, the data is
the caller's). Upstream's `false` / `undefined` is the plain
`Column.filter = Nothing`.
-}
type Filter row
    = FilterDefault (row -> String)
    | FilterCustom (String -> row -> Bool)
    | FilterAsync


{-| Upstream `Column.filterMode` — `'or' | 'and'` (default `'or'`).
-}
type FilterMode
    = FilterOr
    | FilterAnd


{-| One entry of `Column.filterOptions` — upstream `FilterOption`
(`{ label, value }`); `value` is the port's `String` (upstream `string |
number`, the `RowKey` collapse).
-}
type alias FilterOption =
    { label : String
    , value : String
    }


{-| One column's live filter value — upstream `FilterState`'s
`FilterOptionValue[] | FilterOptionValue | null` (a `null` key is a
PRESENT entry — the cleared single state — not key absence).
-}
type FilterValue
    = FilterMany (List String)
    | FilterOne String
    | FilterNull


{-| Upstream `paginationBehaviorOnFilter` — `'current' | 'first'` (default
`'current'`): `'first'` resets the page to 1 when a filter commits. The
flag is caller data (the `lastSelectedKey` precedent) — the port's filter
emit fires before any page change (as upstream's `doUpdateFilters` does)
and the caller applies the reset through `onUpdatePage`.
-}
type PaginationBehavior
    = PaginationCurrent
    | PaginationFirst


{-| Upstream `SortState` — one column's live sort: its key, its order and
the sorter it was seeded from. Upstream also lets the state's `sorter` be
`false` / `true` / `'default'`; the show-nothing `false` has no state here
(it is `Column.sorter = Nothing` before it ever becomes one).
-}
type alias SortState row =
    { columnKey : String
    , order : SortOrder
    , sorter : Sorter row
    }


{-| Upstream's column `type` discriminator — a basic column (`type:
undefined`, `KindNormal`, the only kind with a `view` cell body), the
selection column (`KindSelection`, checkbox / radio cells) and the expand
column (`KindExpand`, the expand-trigger cell plus per-row `renderExpand`
content). Upstream types these as three interfaces whose shared fields ride
`CommonColumnInfo`; the port keeps one flat record (see the divergence
notes on the TS `never` fields).
-}
type ColumnKind
    = KindNormal
    | KindSelection
    | KindExpand


{-| One entry of the selection column's `options` — the extra menu behind
the header's `n-data-table-check-extra` trigger. `SelectionAll` /
`SelectionNone` are upstream's `'all'` / `'none'` (whole-table check /
uncheck — the menu LABELS are locale data, enUS `'Select all in the table'`
/ `'Unselect all in the table'`, caller-supplied); a custom option passes
through with its `onSelect` over the page rows. The port renders the
at-rest trigger iff the list is non-empty — the open menu is the caller's
`NUI.Dropdown` runtime (see the divergence notes).
-}
type SelectionOption row msg
    = SelectionAll
    | SelectionNone
    | SelectionCustom { label : String, key : String, onSelect : List row -> msg }


{-| The `action` of a checked-rows emit — upstream's
`'check' | 'uncheck' | 'checkAll' | 'uncheckAll'` payload field.
-}
type CheckAction
    = Check
    | Uncheck
    | CheckAll
    | UncheckAll


{-| The third emit argument — upstream's `{ row, action }` payload: the row
the interaction started from (`Nothing` for the header's check-all /
uncheck-all) and the action. `row` also carries the clicked key for the
caller-owned `lastSelectedKey`.
-}
type alias CheckEmit row =
    { row : Maybe row
    , action : CheckAction
    }


{-| Upstream `summaryPlacement` — `'top' | 'bottom'` (default `'bottom'`):
whether the summary rows prepend or append the body's data rows.
-}
type SummaryPlacement
    = SummaryTop
    | SummaryBottom


{-| One entry of a summary row — upstream `SummaryCell`
(`{ value?, colSpan?, rowSpan? }`): `value` is the cell body (a missing
key renders an empty td), `colSpan` / `rowSpan` the summary-side spans
(0 / undefined both read 1 — upstream's `|| 1` fix for #1276, unlike the
data-side `colSpan` / `rowSpan` fns whose 0 results are kept).
-}
type alias SummaryCell msg =
    { value : Maybe (Element msg)
    , colSpan : Maybe Int
    , rowSpan : Maybe Int
    }


{-| The group-child carrier — Elm forbids a record alias referencing
itself, so `Column.children` cannot directly hold
`List (Column row msg)`; each child column rides this one-token wrapper
(the minimal form of the `NUI.Tree` `TreeOption` precedent — wrapping
ONLY the recursion keeps the flat `Column` record and its
`{ columnDefaults | … }` update ergonomics intact; see the divergence
notes).
-}
type ColumnChild row msg
    = ColumnChild (Column row msg)


{-| One column — upstream's `TableBaseColumn` (`type: undefined`):
`key` sources the `data-col-key` attribute, `view` renders the cell body
(upstream `render`, falling back to `row[key]`). The width fields feed the
`<col>` / `<th>` / `<td>` styles exactly like upstream's
`createCustomWidthStyle` (a set `width` also backs an unset `minWidth` on
the `<col>` only). `className` lands on both the `th` and every `td` of
the column, after the base class. The sorter fields: `sorter` opts the
column into sorting (`isColumnSortable`), `defaultSortOrder` seeds the
initial uncontrolled state (`NoSort` ≙ upstream's `false`), `sortOrder`
marks the column controlled — its `Just` value (a `NoSort` included) wins
over the uncontrolled list.

The filter fields: `filter` opts the column into filtering
(`isColumnFilterable` — with `filterOptions` set; `Just []` keeps the
button, upstream's empty array is truthy), `filterMultiple` (default on)
switches the menu's checkbox / radio mode, `filterMode` the or / and
walk, the `filterOption*` pair the CONTROLLED state (overriding
`filterStates` in `mergedFilterStates` — a `Just Nothing` single value is
upstream's `null`), and the `defaultFilterOption*` pair the uncontrolled
seed (`defaultFilterStates`).

`kind` / `multiple` / `disabled` / `options` are the selection column's
fields and `renderExpand` / `expandable` the expand column's (upstream
`TableSelectionColumn` / `TableExpandColumn`) — ignored on the other
kinds; a `KindSelection` / `KindExpand` column takes its width, align and
class fields through the same `<col>` / th / td paths as a basic column
(see the divergence notes for the 40px col default and the `never`
fields).

The group / merge surface: `children` present (`Just`, even `Just []` —
upstream's `'children' in column` key-presence gate) makes the column a
GROUP header — each child rides the `ColumnChild` wrapper (Elm forbids
the recursive record alias — see its doc) — and the group's own `view` /
`sorter` / `filter` fields go inert (the header walks render its children
as the leaves and the group th as a bare title); upstream types children
as base columns only, so nesting selection / expand / further group
columns under one is caller error the port walks permissively (see the
divergence notes). `titleColSpan` spans
a leaf th across the next `n` header cells (swallowing their ths);
`colSpan` / `rowSpan` are the merge-cell fns — args `(row,
actualRowIndex)` (the paginated index; −1 is unreachable for data rows),
absent reads 1 and a fn result of 0 is KEPT (upstream renders the
collapsed cell; the summary side differs — see `SummaryCell`).

-}
type alias Column row msg =
    { key : String
    , title : String
    , view : row -> Element msg
    , align : Maybe Align
    , titleAlign : Maybe Align
    , width : Maybe Int
    , minWidth : Maybe Int
    , maxWidth : Maybe Int
    , className : Maybe String
    , sorter : Maybe (Sorter row)
    , defaultSortOrder : SortOrder
    , sortOrder : Maybe SortOrder
    , filter : Maybe (Filter row)
    , filterOptions : Maybe (List FilterOption)
    , filterOptionValues : Maybe (List String)
    , filterOptionValue : Maybe (Maybe String)
    , filterMode : FilterMode
    , defaultFilterOptionValues : Maybe (List String)
    , defaultFilterOptionValue : Maybe String
    , filterMultiple : Bool
    , kind : ColumnKind
    , multiple : Bool
    , disabled : Maybe (row -> Bool)
    , options : List (SelectionOption row msg)
    , renderExpand : Maybe (row -> Int -> Element msg)
    , expandable : Maybe (row -> Bool)
    , fixed : Maybe FixedSide
    , ellipsis : Maybe (ColumnEllipsis msg)
    , children : Maybe (List (ColumnChild row msg))
    , titleColSpan : Maybe Int
    , colSpan : Maybe (row -> Int -> Int)
    , rowSpan : Maybe (row -> Int -> Int)
    }


{-| The column placeholders — `key` / `title` / `view` are the caller's to
set (the keyless rest is `Nothing` / `NoSort`).
-}
columnDefaults : Column row msg
columnDefaults =
    { key = ""
    , title = ""
    , view = \_ -> Element.none
    , align = Nothing
    , titleAlign = Nothing
    , width = Nothing
    , minWidth = Nothing
    , maxWidth = Nothing
    , className = Nothing
    , sorter = Nothing
    , defaultSortOrder = NoSort
    , sortOrder = Nothing
    , filter = Nothing
    , filterOptions = Nothing
    , filterOptionValues = Nothing
    , filterOptionValue = Nothing
    , filterMode = FilterOr
    , defaultFilterOptionValues = Nothing
    , defaultFilterOptionValue = Nothing
    , filterMultiple = True
    , kind = KindNormal
    , multiple = True
    , disabled = Nothing
    , options = []
    , renderExpand = Nothing
    , expandable = Nothing
    , fixed = Nothing
    , ellipsis = Nothing
    , children = Nothing
    , titleColSpan = Nothing
    , colSpan = Nothing
    , rowSpan = Nothing
    }


{-| The data-table options (upstream `dataTableProps`):
`bordered`, `bottomBordered` and `singleLine` default `True` (upstream's
booleans). `bottomBordered` is emitted only when `bordered` is off —
upstream `mergedBottomBordered` (the wrapper border wins when bordered).
`--single-line` keeps upstream's inverted CSS semantics: `True` means _no_
vertical cell borders (`cNotM('single-line')` rules add them). The sort /
pagination surface: `sortStates` is the uncontrolled sort state (seed it
with `defaultSortStates`), `onSorterChange` the click channel (without it
the sortable headers render but never fire), `remote` hands the data and
the page window to the caller, `pagination` carries the
`NUI.Pagination.Options` object merged per upstream, `paginationPrefix`
its prefix slot, and `onUpdatePage` / `onUpdatePageSize` the table-level
handlers that replace the object's own (see the divergence notes).

The filter surface: `filterStates` is the caller-owned uncontrolled
filter state (seed it with `defaultFilterStates`), `onUpdateFilters` the
commit channel — the next whole state over the merged map
(`filtersAfterChange`) plus the source column key; `filterMenuShown` the
open-menu keys (the trigger's `--show`), `onFilterTriggerClick` the
trigger click (the popover runtime is the caller's), and
`paginationBehaviorOnFilter` the page-reset flag (`PaginationFirst`
resets to page 1 on commit — caller-applied).

The selection / expand surface: `checkedRowKeys` is the caller-owned
checked-keys state (the display merge runs over it — see
`mergedCheckedRowKeys`), `onUpdateCheckedRowKeys` the single emit channel,
`lastSelectedKey` the caller-owned shift-click anchor; `expandedRowKeys`
the caller-owned expanded-keys state with `onUpdateExpandedRowKeys` its
toggle channel; `stickyExpandedRows` + `bodyWidth` the sticky expanded
wrapper; `renderExpandIcon` the table-level expand-trigger icon slot; and
`onCheckExtraClick` the click seam on the selection menu's trigger icon
(the open menu is the caller's `NUI.Dropdown` runtime).

The scroll / layout surface: `loading` (the root `--loading` class, the
`--hide` empty dimmer, the force-disabled pager and the
`n-data-table-loading-wrapper` overlay — the `spin*` fields the per-field
`spinProps` spread over the sw-20 / r-100 / scale-1 baseline), `maxHeight`
/ `minHeight` (the body fallthrough style) and `flexHeight` (the root
`--flex-height` class) — `maxHeight` / `flexHeight` split the header into
its own discrete table — `scrollX` (the scrollbar content `min-width` +
`width:100%` and the discrete header's `min-width`), and `tableLayout`
(the base layout under the `fixed` overrides — see the divergence notes).

The summary surface (b6): `summary` receives the PAGED rows and returns
the summary rows, each an assoc list of `(columnKey, SummaryCell)` —
upstream's single-object return is the one-element list (the row keys
are Vue-internal, never DOM) — and `summaryPlacement` prepends
(`SummaryTop`) or appends (`SummaryBottom`, the default) them around the
data rows, before the expand tiling.

-}
type alias Options row msg =
    { columns : List (Column row msg)
    , data : List row
    , rowKey : row -> String
    , size : Size
    , bordered : Bool
    , bottomBordered : Bool
    , singleLine : Bool
    , singleColumn : Bool
    , striped : Bool
    , rowClassName : Maybe (row -> Int -> String)
    , rowAttributes : Maybe (row -> Int -> List (Html.Attribute msg))
    , showHeader : Bool
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    , sortStates : List (SortState row)
    , onSorterChange : Maybe (List (SortState row) -> msg)
    , remote : Bool
    , paginateSinglePage : Bool
    , pagination : Maybe (NUI.Pagination.Options msg)
    , paginationPrefix : List (Element msg)
    , onUpdatePage : Maybe (Int -> msg)
    , onUpdatePageSize : Maybe (Int -> msg)
    , filterStates : List ( String, FilterValue )
    , onUpdateFilters : Maybe (List ( String, FilterValue ) -> String -> msg)
    , filterMenuShown : List String
    , onFilterTriggerClick : Maybe (String -> msg)
    , paginationBehaviorOnFilter : PaginationBehavior
    , checkedRowKeys : List String
    , onUpdateCheckedRowKeys : Maybe (List String -> List row -> CheckEmit row -> msg)
    , lastSelectedKey : String
    , expandedRowKeys : List String
    , onUpdateExpandedRowKeys : Maybe (List String -> msg)
    , stickyExpandedRows : Bool
    , bodyWidth : Maybe Int
    , renderExpandIcon : Maybe (Bool -> row -> Element msg)
    , onCheckExtraClick : Maybe msg
    , loading : Bool
    , maxHeight : Maybe Int
    , minHeight : Maybe Int
    , flexHeight : Bool
    , scrollX : Maybe Int
    , tableLayout : TableLayout
    , spinStrokeWidth : Maybe Int
    , spinRadius : Maybe Int
    , spinScale : Maybe Float
    , spinStroke : Maybe String
    , summary : Maybe (List row -> List (List ( String, SummaryCell msg )))
    , summaryPlacement : SummaryPlacement
    }


defaults : Options row msg
defaults =
    { columns = []
    , data = []
    , rowKey = \_ -> ""
    , size = Medium
    , bordered = True
    , bottomBordered = True
    , singleLine = True
    , singleColumn = False
    , striped = False
    , rowClassName = Nothing
    , rowAttributes = Nothing
    , showHeader = True
    , rtl = False
    , attributes = []
    , sortStates = []
    , onSorterChange = Nothing
    , remote = False
    , paginateSinglePage = True
    , pagination = Nothing
    , paginationPrefix = []
    , onUpdatePage = Nothing
    , onUpdatePageSize = Nothing
    , filterStates = []
    , onUpdateFilters = Nothing
    , filterMenuShown = []
    , onFilterTriggerClick = Nothing
    , paginationBehaviorOnFilter = PaginationCurrent
    , checkedRowKeys = []
    , onUpdateCheckedRowKeys = Nothing
    , lastSelectedKey = ""
    , expandedRowKeys = []
    , onUpdateExpandedRowKeys = Nothing
    , stickyExpandedRows = False
    , bodyWidth = Nothing
    , renderExpandIcon = Nothing
    , onCheckExtraClick = Nothing
    , loading = False
    , maxHeight = Nothing
    , minHeight = Nothing
    , flexHeight = False
    , scrollX = Nothing
    , tableLayout = TableAuto
    , spinStrokeWidth = Nothing
    , spinRadius = Nothing
    , spinScale = Nothing
    , spinStroke = Nothing
    , summary = Nothing
    , summaryPlacement = SummaryBottom
    }



-- VIEW -------------------------------------------------------------------------


{-| The data table — the `n-data-table` root carrying the modifier classes
(`DataTable.tsx` render's class array, minus the inline-theme
`themeClass`) and the 47-var inline set, over the wrapper → base-table →
body chain, the pagination node after the wrapper and the loading
wrapper after that (`mergedShowPagination` / the `loading` transition's
at-rest render).
-}
view : Theme -> Options row msg -> Element msg
view theme opts =
    let
        empty =
            paginatedData opts == []

        bottomBordered =
            if opts.bordered then
                False

            else
                opts.bottomBordered
    in
    Element.column
        ([ I.classes (rootClasses opts bottomBordered empty)
         , I.cssVars (cssVars theme opts.size)
         ]
            ++ opts.attributes
        )
        [ Element.el [ I.classes [ "n-data-table-wrapper" ] ]
            (baseTableNode theme opts)
        , paginationNode theme opts
        , loadingNode opts
        ]


{-| The root's class list — `n-data-table` plus the modifiers in upstream's
class-array order, each only when truthy. `--empty` keys off the paginated
data (upstream `mergedEmpty`: paginated data length 0) and
`--bottom-bordered` is forced off while `--bordered` is on.
-}
rootClasses : Options row msg -> Bool -> Bool -> List String
rootClasses opts bottomBordered empty =
    [ "n-data-table" ]
        ++ I.classIf opts.rtl "n-data-table--rtl"
        ++ I.classIf opts.bordered "n-data-table--bordered"
        ++ I.classIf bottomBordered "n-data-table--bottom-bordered"
        ++ I.classIf opts.singleLine "n-data-table--single-line"
        ++ I.classIf opts.singleColumn "n-data-table--single-column"
        ++ I.classIf opts.loading "n-data-table--loading"
        ++ I.classIf opts.flexHeight "n-data-table--flex-height"
        ++ I.classIf empty "n-data-table--empty"


{-| The pagination node (`DataTable.tsx` render): a sibling AFTER the
wrapper — the bare `div.n-data-table__pagination` carrying only the class,
over the merged pager. Upstream force-disables the pager while `loading`
(`disabled={loading}` overrides the merged pagination object); the prefix
slot rides `paginationPrefix` (upstream: a render-prop on the pagination
object).
-}
paginationNode : Theme -> Options row msg -> Element msg
paginationNode theme opts =
    if showPagination opts then
        let
            merged =
                mergedPaginationOpts opts

            pager =
                if opts.loading then
                    { merged | disabled = True }

                else
                    merged
        in
        Element.el [ I.classes [ "n-data-table__pagination" ] ]
            (NUI.Pagination.view theme pager opts.paginationPrefix)

    else
        Element.none


{-| The loading overlay (`DataTable.tsx` render tail): upstream wraps the
wrapper in `<Transition name="fade-in-scale-up-transition">` — its
at-rest initial render is the plain `div.n-data-table-loading-wrapper`
over the `NBaseLoading` chain (`strokeWidth 20` baseline, the `spin*`
fields the per-field `spinProps` spread — the `NUI.Button` loading
precedent). Nothing at all while not loading (the Transition renders its
null child).
-}
loadingNode : Options row msg -> Element msg
loadingNode opts =
    if opts.loading then
        Element.html
            (Html.div [ HA.class "n-data-table-loading-wrapper" ]
                [ Html.div
                    [ HA.class "n-base-loading"
                    , HA.attribute "role" "img"
                    , HA.attribute "aria-label" "loading"
                    ]
                    [ Html.div [ HA.class "n-base-loading__transition-wrapper" ]
                        [ Html.div [ HA.class "n-base-loading__container" ]
                            [ Loading.spinner
                                { strokeWidth = toFloat (Maybe.withDefault 20 opts.spinStrokeWidth)
                                , radius = toFloat (Maybe.withDefault 100 opts.spinRadius)
                                , scale = Maybe.withDefault 1 opts.spinScale
                                , stroke = opts.spinStroke
                                }
                            ]
                        ]
                    ]
                ]
            )

    else
        Element.none


{-| The base-table region (`MainTable.tsx` render): the
`div.n-data-table-base-table` over either the single body scrollbar
(`headerInBody` — no maxHeight / flexHeight) or the discrete header div
plus the header-less body, or — when the body is not scrollable at all
(`mergedTableLayout` fixed via `tableLayout` / an ellipsis column with no
scrollX / maxHeight / flexHeight) — the bare slot children straight under
the div (upstream's `NScrollbar` `scrollable = false` renders the slot
bare and DROPS its fallthrough class / style: no `n-scrollbar` wrapper,
no `n-data-table-base-table-body`). The port's `showHeader` extension
gates the discrete header too (upstream has no `show-header` prop — the
header always renders, inline or discrete).
-}
baseTableNode : Theme -> Options row msg -> Element msg
baseTableNode theme opts =
    let
        split =
            not (headerInBodyOf opts)

        header =
            if split && opts.showHeader then
                [ discreteHeaderNode theme opts ]

            else
                []

        body =
            if scrollableOf opts then
                [ scrollbarNode theme opts ]

            else
                tableNode theme opts :: emptyNodes theme opts
    in
    Element.column [ I.classes [ "n-data-table-base-table" ] ]
        (header ++ body)


{-| The discrete header (`Header.tsx` `discrete = true`): the
`div.n-data-table-base-table-header` over its own table — style
`min-width` first (only with `scrollX`), then the merged `table-layout`
(`fixed` by construction in split mode) — colgroup and the same inline
thead node. Upstream's `onScroll` sync handler leaves no DOM byte.
-}
discreteHeaderNode : Theme -> Options row msg -> Element msg
discreteHeaderNode theme opts =
    Element.html
        (Html.div [ HA.class "n-data-table-base-table-header" ]
            [ Html.table
                ([ HA.class "n-data-table-table" ]
                    ++ rawStyleAttr (headerTableStyleOf opts)
                )
                (Html.colgroup [] (List.map colNode (leafColumns opts.columns))
                    :: theadNode theme opts (mergedSortStates opts.columns opts.sortStates)
                )
            ]
        )


{-| The scroll area — upstream's body `NScrollbar` with the
`n-data-table-base-table-body` fallthrough class on its root, the
`bodyStyle` fallthrough style (dropped while empty — upstream
`style={!empty ? bodyStyle : undefined}`), `xScrollable` per the scroll
flags (the basic auto-layout table IS x-scrollable — the content
`width:fit-content` + the x-rail), both rails carrying the table's
`z-index:3` rail styles, and `contentStyle` per `scrollX`
(`min-width:100%` without it). Children: split + empty renders ONLY the
empty node (upstream `Body.tsx` :599-604 — no table in the slot);
otherwise the table (inline thead iff `headerInBody`), then the empty
node after it.
-}
scrollbarNode : Theme -> Options row msg -> Element msg
scrollbarNode theme opts =
    let
        sb =
            NUI.Scrollbar.defaults

        empty =
            paginatedData opts == []
    in
    NUI.Scrollbar.view theme
        { sb
            | extraClasses = [ "n-data-table-base-table-body" ]
            , xScrollable = xScrollableOf opts
            , contentStyle = Just (contentStyleOf opts)
            , rootStyle =
                if empty then
                    Nothing

                else
                    bodyStyleOf opts
            , yRailStyle = Just "z-index:3"
            , xRailStyle = Just "z-index:3"
        }
        (if empty && not (headerInBodyOf opts) then
            emptyNodes theme opts

         else
            tableNode theme opts :: emptyNodes theme opts
        )


{-| The empty state nodes — `[ div.n-data-table-empty [--hide] > NEmpty ]`
iff the paginated data is empty, else `[]` (upstream
`{this.empty ? createEmptyNode() : null}`). The div's style merges the
`bodyStyle` object entries (no-space form) with upstream's verbatim
sticky string when the body is x-scrollable.
-}
emptyNodes : Theme -> Options row msg -> List (Element msg)
emptyNodes theme opts =
    if paginatedData opts == [] then
        [ Element.el
            ([ I.classes
                ([ "n-data-table-empty" ]
                    ++ I.classIf opts.loading "n-data-table-empty--hide"
                )
             ]
                ++ emptyStyleAttr opts
            )
            (NUI.Empty.view theme NUI.Empty.defaults [])
        ]

    else
        []


{-| The empty div's style — `Body.tsx` `createEmptyNode`'s
`[bodyStyle, xScrollable ? 'position: sticky; left: 0; width:
var(--n-scrollbar-current-width);' : undefined]`: the object entries
first (no-space form), then the upstream string verbatim (authored with
spaces and its trailing `;`), joined by `;`.
-}
emptyStyleAttr : Options row msg -> List (Element.Attribute msg)
emptyStyleAttr opts =
    let
        parts =
            List.filterMap identity
                [ bodyStyleOf opts
                , if xScrollableOf opts then
                    Just "position: sticky; left: 0; width: var(--n-scrollbar-current-width);"

                  else
                    Nothing
                ]
    in
    if List.isEmpty parts then
        []

    else
        [ Element.htmlAttribute (HA.attribute "style" (String.join ";" parts)) ]


{-| The body's single `<table>` (`Body.tsx` :1063): class + the inline
merged `table-layout` (no `width`/`minWidth` — the scrollbar content's
`min-width` carries it; the DISCRETE header's table takes the
`min-width`), then colgroup, thead (iff `headerInBody` and the port's
`showHeader`), tbody (iff paginated rows non-empty).
-}
tableNode : Theme -> Options row msg -> Element msg
tableNode theme opts =
    let
        merged =
            mergedSortStates opts.columns opts.sortStates
    in
    Element.html
        (Html.table
            [ HA.class "n-data-table-table"
            , HA.attribute "style" ("table-layout:" ++ layoutName (mergedTableLayoutOf opts))
            ]
            ([ Html.colgroup [] (List.map colNode (leafColumns opts.columns)) ]
                ++ (if headerInBodyOf opts && opts.showHeader then
                        theadNode theme opts merged

                    else
                        []
                   )
                ++ tbodyNode theme opts merged
            )
        )


{-| The colgroup — always rendered, even with no data. One `<col>` per
column whose style is built only from the set width fields, upstream
`createCustomWidthStyle`: `width`, then `min-width` (falling back to
`width`), then `max-width`. All absent → no style attribute (Vue drops the
empty object). The vnode `key` is not a DOM attribute.
-}
colNode : Column row msg -> Html.Html msg
colNode col =
    Html.col
        (case colStyle col of
            Just style ->
                [ HA.attribute "style" style ]

            Nothing ->
                []
        )
        []


{-| `createCustomWidthStyle` (upstream `utils.ts`), byte form without
spaces — `width:{n}px;min-width:{n}px;max-width:{n}px` from the set fields,
`min-width` falling back to `width` when unset. The width source is
`getStringColWidth`: a selection / expand column defaults to upstream's
`SELECTION_COL_WIDTH` / `EXPAND_COL_WIDTH` (40) when the caller set no
width (the th / td inline styles keep the bare `column.width` — see the
divergence notes).
-}
colStyle : Column row msg -> Maybe String
colStyle col =
    let
        width =
            case col.kind of
                KindNormal ->
                    col.width

                _ ->
                    orElse col.width (Just 40)

        parts =
            List.filterMap identity
                [ stylePart "width" (Maybe.map pxfy width)
                , stylePart "min-width" (Maybe.map pxfy (orElse col.minWidth width))
                , stylePart "max-width" (Maybe.map pxfy col.maxWidth)
                ]
    in
    if parts == [] then
        Nothing

    else
        Just (String.join ";" parts)


{-| The `<thead>` — upstream `TableHeader` with `discrete={false}` (the
header-in-body path): the bare thead with `data-n-id`, one `tr` with only
its base class PER HEADER ROW (`getRowsAndCols`' rows — one row on flat
columns, one per group level otherwise), one `th` per row cell (the
per-kind content and sort wiring per `thNode`). The discrete path wraps
this same thead (see `discreteHeaderNode`).
-}
theadNode : Theme -> Options row msg -> List (SortState row) -> List (Html.Html msg)
theadNode theme opts merged =
    [ Html.thead
        [ HA.class "n-data-table-thead"
        , HA.attribute "data-n-id" "1"
        ]
        (List.map
            (\row ->
                Html.tr [ HA.class "n-data-table-tr" ]
                    (List.map (thNode theme opts merged) row)
            )
            (headerRows opts.columns)
        )
    ]


{-| One header cell — `Header.tsx`'s th over its `RowItem`: base class,
then `--fixed-left` / `--fixed-right` (iff the column is fixed), then
`--sorting` (iff a state names this key with a truthy order), then
`--sortable` (iff the column carries a sorter), then `--selection` (iff
the column IS the selection column), then `--last` (the RowItem's
`isLast` flag — the span-aware last formula, not the list tail), then
`column.className`; the always-present `data-col-key` (`getColKey`: the
`__n_selection__` / `__n_expand__` sentinel on the special kinds, the
caller key on a basic column); the style built only from the set fields —
`left` / `right` (the fixed-offset maps) FIRST, then `width`, then
`text-align` from `titleAlign || align` (upstream's style-array order;
the body-path `height` stays `undefined`). `colspan` / `rowspan` render
the RowItem's spans (EVERY th carries them, spans of 1 included — a
group th spans its children's total, a leaf th under groups spans the
remaining depth, a `titleColSpan` leaf spans the swallowed cells);
attribute order matches upstream (`style`, spans, `data-col-key`,
`class`, then the sort click handler — last, and only on a basic column
with a sorter and `onSorterChange` set; the selection/expand kinds AND
children-present columns gate the listener off, `Header.tsx`'s `type !==
'selection' && type !== 'expand' && !('children' in column)` click guard
— the group gate rides `isSortable` returning false). The content
branches per kind: a selection column with `multiple` renders the header
checkbox (plus the selection-menu trigger iff the FIRST selection column
carries options) and one with `multiple = False` renders nothing (an
empty th); every other kind — GROUP columns included — renders the title
wrapper: title div (the bare title, the `th__ellipsis` wrapper or the
`NEllipsis` form), then the sorter span when the column is sortable
(never on a group — `isColumnSortable`'s children gate).
-}
thNode :
    Theme
    -> Options row msg
    -> List (SortState row)
    -> HeaderCell row msg
    -> Html.Html msg
thNode theme opts merged item =
    let
        col =
            item.column

        sortable =
            isSortable col

        currentState =
            List.filter (\state -> state.columnKey == col.key) merged
                |> List.head

        order =
            currentState
                |> Maybe.map .order
                |> Maybe.withDefault NoSort
    in
    Html.th
        (thStyleAttr opts col
            ++ [ HA.colspan item.colSpan
               , HA.rowspan item.rowSpan
               , HA.attribute "data-col-key" (colKeyOf col)
               , HA.class
                    (String.join " "
                        ([ "n-data-table-th" ]
                            ++ fixedClassesOf "n-data-table-th" col
                            ++ I.classIf (isColumnSorting col merged) "n-data-table-th--sorting"
                            ++ I.classIf (isColumnFilterable col) "n-data-table-th--filterable"
                            ++ I.classIf sortable "n-data-table-th--sortable"
                            ++ I.classIf (col.kind == KindSelection) "n-data-table-th--selection"
                            ++ I.classIf item.isLast "n-data-table-th--last"
                            ++ maybeClass col.className
                        )
                    )
               ]
            ++ (if col.kind == KindNormal then
                    sortClickAttr opts merged col currentState

                else
                    []
               )
        )
        (case col.kind of
            KindSelection ->
                if col.multiple then
                    embedChild (headerCheckboxNode theme opts) :: checkExtraNodes opts

                else
                    []

            _ ->
                [ Html.div [ HA.class "n-data-table-th__title-wrapper" ]
                    ([ Html.div [ HA.class "n-data-table-th__title" ]
                        (thTitleContent theme col)
                     ]
                        ++ (if sortable then
                                [ sortButtonNode order ]

                            else
                                []
                           )
                    )
                ]
                    ++ (if isColumnFilterable col then
                            [ filterButtonNode opts col ]

                        else
                            []
                       )
        )


{-| The title div's content — the bare title text, the
`th__ellipsis` wrapper (plain ellipsis), or the `NEllipsis` form (the
port's `NUI.Ellipsis` through the embed seam).
-}
thTitleContent : Theme -> Column row msg -> List (Html.Html msg)
thTitleContent theme col =
    case col.ellipsis of
        Just EllipsisPlain ->
            [ Html.div [ HA.class "n-data-table-th__ellipsis" ]
                [ Html.text col.title ]
            ]

        Just (EllipsisOpts ellipsisOpts) ->
            [ embedChild (NUI.Ellipsis.view theme ellipsisOpts [ Element.text col.title ]) ]

        Nothing ->
            [ Html.text col.title ]


{-| The th's fixed-column classes — `--fixed-left` / `--fixed-right`
right after the base class (upstream `leftFixed = key in
fixedColumnLeftMap` — on flat columns, membership ⟺ `column.fixed`).
-}
fixedClassesOf : String -> Column row msg -> List String
fixedClassesOf base col =
    case col.fixed of
        Just FixedLeft ->
            [ base ++ "--fixed-left" ]

        Just FixedRight ->
            [ base ++ "--fixed-right" ]

        Nothing ->
            []


thStyleAttr : Options row msg -> Column row msg -> List (Html.Attribute msg)
thStyleAttr opts col =
    rawStyleAttr
        (stylePairs
            [ ( "left", fixedOffsetOf (fixedColumnLeftMap opts.columns) (colKeyOf col) )
            , ( "right", fixedOffsetOf (fixedColumnRightMap opts.columns) (colKeyOf col) )
            , ( "width", Maybe.map pxfy col.width )
            , ( "text-align", Maybe.map alignName (orElse col.titleAlign col.align) )
            ]
        )


{-| The th's sort click handler (`Header.tsx` `handleColHeaderClick`, minus
the filter/resizable `happensIn` guards — later batches): the
`deriveNextSorter` of the merged base and the column's next state, fed to
`onSorterChange`. Only present on a BASIC column that is sortable and
whose caller wired the channel (upstream attaches the listener to every
basic-column th and no-ops inside; the selection/expand kinds gate the
listener off entirely).
-}
sortClickAttr :
    Options row msg
    -> List (SortState row)
    -> Column row msg
    -> Maybe (SortState row)
    -> List (Html.Attribute msg)
sortClickAttr opts merged col current =
    if isSortable col && col.kind == KindNormal then
        case opts.onSorterChange of
            Just onSorterChange ->
                [ Html.Events.onClick
                    (onSorterChange (deriveNextSorter merged (createNextSorter col current)))
                ]

            Nothing ->
                []

    else
        []


{-| The sorter span (`SortButton.tsx`, name `SortIcon`): base class plus
`--asc` / `--desc` for the merged order of the column, wrapping the
`n-base-icon` arrow-down glyph. Upstream renders a `renderSorter` prop in
place of the whole span when given — not modelled (see the module
divergences).
-}
sortButtonNode : SortOrder -> Html.Html msg
sortButtonNode order =
    Html.span
        [ HA.class
            (String.join " "
                ([ "n-data-table-sorter" ]
                    ++ I.classIf (order == Ascend) "n-data-table-sorter--asc"
                    ++ I.classIf (order == Descend) "n-data-table-sorter--desc"
                )
            )
        ]
        [ Html.i [ HA.class "n-base-icon" ] [ arrowDownIcon ] ]


{-| The arrow-down glyph (upstream `ArrowDownIcon` under `NBaseIcon`) — the
per-component SVG pattern of `NUI.Alert`'s icons (`Svg.node` +
`HA.attribute`).
-}
arrowDownIcon : Html.Html msg
arrowDownIcon =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 28 28"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Svg.node "path" [ HA.attribute "d" arrowDownPath ] [] ]
            ]
        ]


{-| The filter trigger (`FilterButton.tsx`'s popover trigger, minus the
popover runtime — see the divergence notes): the `n-data-table-filter`
div carrying `data-data-table-filter` and the `--active` / `--show` mods
(upstream's object key order — a non-empty array or a non-null scalar is
active; `--show` mirrors the caller-owned `filterMenuShown`), wrapping
the `n-base-icon` filter glyph. The click fires `onFilterTriggerClick`
with the column key — the popover (the `filterMenu` body over
`NUI.Popover`) is the caller's runtime, the selection-menu precedent.
A merged MISSING key reads upstream's `undefined` → `[]` / `null`, both
inactive — same as `FilterMany []` / `FilterNull`.
-}
filterButtonNode : Options row msg -> Column row msg -> Html.Html msg
filterButtonNode opts col =
    let
        active =
            case filterValueOf (mergedFilterStates opts) col.key of
                Just (FilterMany (x :: _)) ->
                    True

                Just (FilterOne _) ->
                    True

                _ ->
                    False

        shown =
            List.member col.key opts.filterMenuShown
    in
    Html.div
        ([ HA.attribute "data-data-table-filter" ""
         , HA.class
            (String.join " "
                ([ "n-data-table-filter" ]
                    ++ I.classIf active "n-data-table-filter--active"
                    ++ I.classIf shown "n-data-table-filter--show"
                )
            )
         ]
            ++ (case opts.onFilterTriggerClick of
                    Just handler ->
                        [ Html.Events.onClick (handler col.key) ]

                    Nothing ->
                        []
               )
        )
        [ Html.i [ HA.class "n-base-icon" ] [ filterIcon ] ]


{-| The filter glyph (upstream `FilterIcon` under `NBaseIcon`) — the
`arrowDownIcon` pattern.
-}
filterIcon : Html.Html msg
filterIcon =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 28 28"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Svg.node "path" [ HA.attribute "d" filterPath ] [] ]
            ]
        ]


{-| The upstream `Filter` glyph bytes (`_internal/icons/Filter.tsx`).
-}
filterPath : String
filterPath =
    "M17,19 C17.5522847,19 18,19.4477153 18,20 C18,20.5522847 17.5522847,21 17,21 L11,21 C10.4477153,21 10,20.5522847 10,20 C10,19.4477153 10.4477153,19 11,19 L17,19 Z M21,13 C21.5522847,13 22,13.4477153 22,14 C22,14.5522847 21.5522847,15 21,15 L7,15 C6.44771525,15 6,14.5522847 6,14 C6,13.4477153 6.44771525,13 7,13 L21,13 Z M24,7 C24.5522847,7 25,7.44771525 25,8 C25,8.55228475 24.5522847,9 24,9 L4,9 C3.44771525,9 3,8.55228475 3,8 C3,7.44771525 3.44771525,7 4,7 L24,7 Z"


arrowDownPath : String
arrowDownPath =
    "M23.7916,15.2664 C24.0788,14.9679 24.0696,14.4931 23.7711,14.206 C23.4726,13.9188 22.9978,13.928 22.7106,14.2265 L14.7511,22.5007 L14.7511,3.74792 C14.7511,3.33371 14.4153,2.99792 14.0011,2.99792 C13.5869,2.99792 13.2511,3.33371 13.2511,3.74793 L13.2511,22.4998 L5.29259,14.2265 C5.00543,13.928 4.53064,13.9188 4.23213,14.206 C3.93361,14.4931 3.9244,14.9679 4.21157,15.2664 L13.2809,24.6944 C13.6743,25.1034 14.3289,25.1034 14.7223,24.6944 L23.7916,15.2664 Z"


{-| The `<tbody>` — omitted entirely while the paginated data is empty
(upstream `{!this.empty ? <tbody>… : null}`; summary rows alone do NOT
save it — the empty gate reads the paginated data); attribute order
matches upstream (`data-n-id` first here, `class` first on the thead).
The rows are the TILED display list (`displayedRows`): summary rows
prepended / appended per `summaryPlacement`, then each expanded parent
row followed by its extra expanded row, so the last-row math runs over
the tiled entries while striped / rowClassName / `renderExpand` indices
stay the paginated ones (`Body.tsx`'s `displayedData` /
`RowRenderInfo`). The `cordToPass` skip grid (upstream's
`Record<rowIndex, colIndex[]>`) threads through the row fold — a
merge cell registers every coordinate it covers, and a later row whose
coordinate is registered renders NO td there (the swallowed slot).
-}
tbodyNode : Theme -> Options row msg -> List (SortState row) -> List (Html.Html msg)
tbodyNode theme opts merged =
    if paginatedData opts == [] then
        []

    else
        let
            displayed =
                displayedRows opts

            rowCount =
                List.length displayed

            colCount =
                List.length (leafColumns opts.columns)

            step :
                ( Int, DisplayedRow row msg )
                -> ( List (Html.Html msg), List ( Int, List Int ) )
                -> ( List (Html.Html msg), List ( Int, List Int ) )
            step ( displayedIndex, dr ) ( accRows, cordToPass ) =
                if dr.isExpandedRow then
                    case dr.row of
                        -- expanded rows always carry a data row (the
                        -- tiling only ever splits data rows; summary
                        -- rows never tile — see the divergence notes)
                        Just row ->
                            ( expandedTrNode opts row dr.paginatedIndex displayedIndex rowCount :: accRows
                            , cordToPass
                            )

                        Nothing ->
                            ( accRows, cordToPass )

                else
                    let
                        ( row, cordToPassNext ) =
                            parentTrNode theme opts merged displayedIndex rowCount colCount dr cordToPass
                    in
                    ( row :: accRows, cordToPassNext )

            ( rows, _ ) =
                List.foldl step ( [], [] ) (List.indexedMap Tuple.pair displayed)
        in
        [ Html.tbody
            [ HA.attribute "data-n-id" "1"
            , HA.class "n-data-table-tbody"
            ]
            (List.reverse rows)
        ]


{-| One paginated or summary row of the tiled list — `Body.tsx`'s
`renderRow` for a normal row: base class, then `--summary` (a summary
row), then `--striped` (iff `striped && index % 2 === 1` — the parity
index runs over the PAGINATED rows and is SUPPRESSED on summary rows),
then `--expanded` (iff the row's key is in the expanded set — NOT gated
by `expandable`, a byte-faithful upstream quirk: an unexpandable row
whose key is in the set gets the class but no child row; summary rows
never match — their `__n_summary__` keys are Vue-internal), then the
`rowClassName(row, index)` result when non-empty, then the caller's
`rowAttributes` verbatim (see the `rowAttributes` divergence note).
`rowClassName` / `rowAttributes` are SKIPPED on summary rows — upstream
invokes them with `(summaryRecord, -1)`, a value the port's `row ->`
signature cannot carry (documented divergence). The cells fold over the
indexed LEAF columns threading the `cordToPass` skip grid (upstream
iterates `cols` with `colIndex = col.index`): a registered coordinate
splices and renders nothing, else the span math registers the covered
coordinates and renders the td.
-}
parentTrNode :
    Theme
    -> Options row msg
    -> List (SortState row)
    -> Int
    -> Int
    -> Int
    -> DisplayedRow row msg
    -> List ( Int, List Int )
    -> ( Html.Html msg, List ( Int, List Int ) )
parentTrNode theme opts merged displayedIndex rowCount colCount dr cordToPass =
    let
        expanded =
            case dr.row of
                Just row ->
                    List.member (opts.rowKey row) opts.expandedRowKeys

                Nothing ->
                    False

        cellStep :
            ( Int, Column row msg )
            -> ( List (Html.Html msg), List ( Int, List Int ) )
            -> ( List (Html.Html msg), List ( Int, List Int ) )
        cellStep ( colIndex, col ) ( accCells, cord ) =
            case takeCord cord displayedIndex colIndex of
                Just cordSkipped ->
                    ( accCells, cordSkipped )

                Nothing ->
                    let
                        ( cell, cordNext ) =
                            tdNode theme opts merged displayedIndex rowCount colCount dr ( colIndex, col ) cord
                    in
                    ( cell :: accCells, cordNext )

        ( cells, cordOut ) =
            List.foldl
                cellStep
                ( [], cordToPass )
                (List.indexedMap Tuple.pair (leafColumns opts.columns))
    in
    ( Html.tr
        ([ HA.class
            (String.join " "
                ([ "n-data-table-tr" ]
                    ++ I.classIf dr.isSummaryRow "n-data-table-tr--summary"
                    ++ I.classIf
                        (not dr.isSummaryRow && opts.striped && modBy 2 dr.paginatedIndex == 1)
                        "n-data-table-tr--striped"
                    ++ I.classIf (not dr.isSummaryRow && expanded) "n-data-table-tr--expanded"
                    ++ rowClassNameOf opts dr
                )
            )
         ]
            ++ rowAttrsOf opts dr
        )
        (List.reverse cells)
    , cordOut
    )


{-| The `cordToPass` read — upstream's `if (displayedRowIndex in
cordToPass)` splice: a registered `(rowIndex, colIndex)` coordinate
removes its FIRST occurrence (the splice) and renders nothing; a row
with other registered coordinates, or a row absent from the grid,
renders normally (`Nothing` — no mutation).
-}
takeCord : List ( Int, List Int ) -> Int -> Int -> Maybe (List ( Int, List Int ))
takeCord cord rowIndex colIndex =
    case List.filter (\( r, _ ) -> r == rowIndex) cord of
        ( _, cols ) :: _ ->
            case indexOf (\c -> c == colIndex) cols of
                Just i ->
                    Just (upsertCord cord rowIndex (List.take i cols ++ List.drop (i + 1) cols))

                Nothing ->
                    Nothing

        [] ->
            Nothing


{-| The `cordToPass` write — `cordToPass[i] = [j]` else `.push(j)`:
append the coordinate to its row's list, creating the row entry at the
tail when absent (upstream key-insertion order; only the membership and
splice semantics are ever read).
-}
upsertCord : List ( Int, List Int ) -> Int -> List Int -> List ( Int, List Int )
upsertCord cord rowIndex cols =
    if List.any (\( r, _ ) -> r == rowIndex) cord then
        List.map
            (\( r, cs ) ->
                if r == rowIndex then
                    ( r, cols )

                else
                    ( r, cs )
            )
            cord

    else
        cord ++ [ ( rowIndex, cols ) ]


{-| The merge-cell registration — upstream's double loop: for every row
`i` in `[displayedRowIndex, displayedRowIndex + mergedRowSpan)` and
every column `j` in `[colIndex, colIndex + mergedColSpan)`, skipping the
cell's own coordinate, push `j` into `cordToPass[i]` (run only when a
span exceeds 1).
-}
registerCord : List ( Int, List Int ) -> Int -> Int -> Int -> Int -> List ( Int, List Int )
registerCord cord rowIndex colIndex mergedColSpan mergedRowSpan =
    List.foldl
        (\i cordI ->
            List.foldl
                (\j cordJ ->
                    if i == rowIndex && j == colIndex then
                        cordJ

                    else
                        case List.filter (\( r, _ ) -> r == i) cordJ of
                            ( _, js ) :: _ ->
                                upsertCord cordJ i (js ++ [ j ])

                            [] ->
                                upsertCord cordJ i [ j ]
                )
                cordI
                (List.range colIndex (colIndex + mergedColSpan - 1))
        )
        cord
        (List.range rowIndex (rowIndex + mergedRowSpan - 1))


{-| `createRowClassName` — the `rowClassName(row, index)` result when
non-empty, SKIPPED on summary rows (the port has no summary `row` value —
upstream passes `(summaryRecord, -1)`; documented divergence).
-}
rowClassNameOf : Options row msg -> DisplayedRow row msg -> List String
rowClassNameOf opts dr =
    case ( dr.isSummaryRow, opts.rowClassName, dr.row ) of
        ( False, Just f, Just row ) ->
            let
                cls =
                    f row dr.paginatedIndex
            in
            if cls == "" then
                []

            else
                [ cls ]

        _ ->
            []


{-| The caller's `rowAttributes` verbatim — likewise skipped on summary
rows (see `rowClassNameOf`).
-}
rowAttrsOf : Options row msg -> DisplayedRow row msg -> List (Html.Attribute msg)
rowAttrsOf opts dr =
    case ( dr.isSummaryRow, opts.rowAttributes, dr.row ) of
        ( False, Just f, Just row ) ->
            f row dr.paginatedIndex

        _ ->
            []


{-| One body cell — `Body.tsx`'s td over a LEAF column (the body iterates
`cols`, `colIndex = col.index`): class order is base → `column.className`
→ `--summary` (a summary row) → `--sorting` (iff a state names this key
with a truthy order — the whole-column highlight) → `--fixed-left` /
`--fixed-right` (iff the column is fixed) → `--{align}-align` (iff align
set — redundant with the inline `text-align`, upstream emits both) →
`--selection` / `--expand` (the cell's column kind) → `--last-col` →
`--last-row`; `--last-col` / `--last-row` are the SPAN-AWARE formulas
(`colIndex + mergedColSpan === colCount`, `displayedRowIndex +
mergedRowSpan === rowCount` — a merged cell carries the flags of the
area it closes, not of its own list slot); the always-present
`data-col-key` (the `__n_selection__` / `__n_expand__` sentinel on the
special kinds); the style always carries the empty `--indent-offset:`
declaration after `text-align`/`width`/the `left`/`right` fixed offsets
(upstream's style-array order: the offsets sit between `width` and the
indent var), with `colspan`/`rowspan` the MERGED spans (both attrs on
every td). The span math per `Body.tsx`: a summary cell reads its
`SummaryCell.colSpan` / `rowSpan` through the `|| 1` collapse (0 /
undefined both render 1, the #1276 fix), a data cell its column's
`colSpan(row, actualRowIndex)` / `rowSpan(…)` fns with absent reading 1
and a fn result of 0 KEPT (the collapsed cell); a span over 1 (either
axis) registers the covered coordinates in `cordToPass` (the returned
grid) — a later cell whose coordinate is registered never renders. The
cell body branches per kind: a selection column renders the body
checkbox (or the body radio on `multiple = False`) — NOTHING on a
summary row; an expand column the expand trigger (suppressed — an empty
td — unless `!expandable || expandable(row)` over the cell's OWN column —
upstream `Body.tsx` reads `column.expandable`, not the first expand
column's) — NOTHING on a summary row; a basic column renders the
caller's element — on a summary row the `SummaryCell.value` looked up by
column key (a missing key renders an empty td) — bare, wrapped in the
`span.n-data-table-td__ellipsis` (plain ellipsis) or the `NEllipsis`
form (the `NUI.Ellipsis` embed) — the SAME wrap for summary values
(`Cell.tsx` wraps after the summary branch) — all through `layoutWith`.
-}
tdNode :
    Theme
    -> Options row msg
    -> List (SortState row)
    -> Int
    -> Int
    -> Int
    -> DisplayedRow row msg
    -> ( Int, Column row msg )
    -> List ( Int, List Int )
    -> ( Html.Html msg, List ( Int, List Int ) )
tdNode theme opts merged displayedIndex rowCount colCount dr ( colIndex, col ) cord =
    let
        actualRowIndex =
            dr.paginatedIndex

        summaryCell =
            summaryCellOf dr.summaryRow (colKeyOf col)

        mergedColSpan =
            if dr.isSummaryRow then
                orOne (Maybe.andThen .colSpan summaryCell)

            else
                Maybe.withDefault 1 (Maybe.map2 (\row f -> f row actualRowIndex) dr.row col.colSpan)

        mergedRowSpan =
            if dr.isSummaryRow then
                orOne (Maybe.andThen .rowSpan summaryCell)

            else
                Maybe.withDefault 1 (Maybe.map2 (\row f -> f row actualRowIndex) dr.row col.rowSpan)

        isLastCol =
            colIndex + mergedColSpan == colCount

        isLastRow =
            displayedIndex + mergedRowSpan == rowCount

        cordNext =
            if mergedColSpan > 1 || mergedRowSpan > 1 then
                registerCord cord displayedIndex colIndex mergedColSpan mergedRowSpan

            else
                cord
    in
    ( Html.td
        (tdStyleAttr opts col
            ++ [ HA.colspan mergedColSpan
               , HA.rowspan mergedRowSpan
               , HA.attribute "data-col-key" (colKeyOf col)
               , HA.class
                    (String.join " "
                        ([ "n-data-table-td" ]
                            ++ maybeClass col.className
                            ++ I.classIf dr.isSummaryRow "n-data-table-td--summary"
                            ++ I.classIf (isColumnSorting col merged) "n-data-table-td--sorting"
                            ++ fixedClassesOf "n-data-table-td" col
                            ++ (case col.align of
                                    Just align ->
                                        [ "n-data-table-td--" ++ alignName align ++ "-align" ]

                                    Nothing ->
                                        []
                               )
                            ++ I.classIf (col.kind == KindSelection) "n-data-table-td--selection"
                            ++ I.classIf (col.kind == KindExpand) "n-data-table-td--expand"
                            ++ I.classIf isLastCol "n-data-table-td--last-col"
                            ++ I.classIf isLastRow "n-data-table-td--last-row"
                        )
                    )
               ]
        )
        (case col.kind of
            KindSelection ->
                if dr.isSummaryRow then
                    []

                else
                    case dr.row of
                        Just row ->
                            if col.multiple then
                                [ embedChild (bodyCheckboxNode theme opts row) ]

                            else
                                [ embedChild (bodyRadioNode theme opts row) ]

                        Nothing ->
                            []

            KindExpand ->
                if dr.isSummaryRow then
                    []

                else
                    case dr.row of
                        Just row ->
                            if cellExpandable col row then
                                [ expandTriggerNode opts row ]

                            else
                                []

                        Nothing ->
                            []

            KindNormal ->
                let
                    cell =
                        if dr.isSummaryRow then
                            Maybe.andThen .value summaryCell
                                |> Maybe.withDefault Element.none

                        else
                            Maybe.map col.view dr.row
                                |> Maybe.withDefault Element.none
                in
                case col.ellipsis of
                    Just EllipsisPlain ->
                        [ Html.span [ HA.class "n-data-table-td__ellipsis" ]
                            [ embedChild cell ]
                        ]

                    Just (EllipsisOpts ellipsisOpts) ->
                        [ embedChild (NUI.Ellipsis.view theme ellipsisOpts [ cell ]) ]

                    Nothing ->
                        [ embedChild cell ]
        )
    , cordNext
    )


{-| Upstream's `rawNode[colKey]?.colSpan || 1` (the #1276 fix) — the
summary-side span collapse: undefined AND 0 both read 1 (the data-side
fns differ — their 0 results are kept).
-}
orOne : Maybe Int -> Int
orOne maybe =
    case maybe of
        Just 0 ->
            1

        Just n ->
            n

        Nothing ->
            1


{-| The summary row's entry for a column key — upstream's
`row[key] as SummaryCell` (a missing key reads undefined — an empty td).
-}
summaryCellOf : Maybe (List ( String, SummaryCell msg )) -> String -> Maybe (SummaryCell msg)
summaryCellOf summaryRow colKey =
    summaryRow
        |> Maybe.andThen (List.filter (\( k, _ ) -> k == colKey) >> List.head)
        |> Maybe.map Tuple.second


tdStyleAttr : Options row msg -> Column row msg -> List (Html.Attribute msg)
tdStyleAttr opts col =
    let
        parts =
            List.filterMap identity
                [ stylePart "text-align" (Maybe.map alignName col.align)
                , stylePart "width" (Maybe.map pxfy col.width)
                , stylePart "left" (fixedOffsetOf (fixedColumnLeftMap opts.columns) (colKeyOf col))
                , stylePart "right" (fixedOffsetOf (fixedColumnRightMap opts.columns) (colKeyOf col))
                ]
    in
    [ HA.attribute "style" (String.join ";" (parts ++ [ "--indent-offset:" ])) ]


{-| There is no public `Element` → `Html`, so a caller's element is
embedded through `Element.layoutWith` (the `NUI.Table` /
`NUI.Descriptions` precedent). The wrapper carries `display: contents` plus
`font`/`color: inherit`; `noStaticStyleSheet` keeps elm-ui's static
stylesheet from re-clobbering the bridge.
-}
embedChild : Element msg -> Html.Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child



-- SELECTION & EXPAND CELLS -------------------------------------------------------


{-| One tiled display entry — upstream's `RowRenderInfo` for the flat-data
batch: the data row (a `Maybe` — summary rows carry NONE), the summary
payload (a summary row's assoc list, `Nothing` on data rows), its
PAGINATED index (striped / rowClassName / `renderExpand` indices; −1 on
summary rows) and whether this entry is the extra expanded row. A
summary entry is `row = Nothing, summaryRow = Just …, paginatedIndex =
-1, isSummaryRow = True` — upstream's `{ isSummaryRow, key:`**n\_summary**${i}`, index: -1 }` (the keys are Vue-internal, never DOM).
-}
type alias DisplayedRow row msg =
    { row : Maybe row
    , summaryRow : Maybe (List ( String, SummaryCell msg ))
    , paginatedIndex : Int
    , isSummaryRow : Bool
    , isExpandedRow : Bool
    }


{-| The tiling walk (`Body.tsx`): the summary rows prepend / append the
paginated data per `summaryPlacement` FIRST (upstream merges them into
`mergedData` before the tiling — a summary row never tiles in the port:
there is no `row` for the tiling gates to read, an inherited edge a
caller only reaches by authoring `__n_summary__` keys into
`expandedRowKeys`; documented divergence), then every data row whose key
is in the expanded set — with a `renderExpand` present and the row
passing `expandable` — is followed by an extra expanded-row entry;
`rowCount` / last-row math run over the tiled list.
-}
displayedRows : Options row msg -> List (DisplayedRow row msg)
displayedRows opts =
    let
        summaryRows =
            case opts.summary of
                Just summary ->
                    List.map
                        (\entries -> DisplayedRow Nothing (Just entries) -1 True False)
                        (summary (paginatedData opts))

                Nothing ->
                    []

        dataRows =
            paginatedData opts
                |> List.indexedMap
                    (\index row ->
                        let
                            isExpanded =
                                renderExpandOf opts
                                    /= Nothing
                                    && List.member (opts.rowKey row) opts.expandedRowKeys
                                    && expandableRow opts row
                        in
                        if isExpanded then
                            [ DisplayedRow (Just row) Nothing index False False
                            , DisplayedRow (Just row) Nothing index False True
                            ]

                        else
                            [ DisplayedRow (Just row) Nothing index False False ]
                    )
                |> List.concat
    in
    case opts.summaryPlacement of
        SummaryTop ->
            summaryRows ++ dataRows

        SummaryBottom ->
            dataRows ++ summaryRows


{-| The extra expanded row (`Body.tsx`'s `renderRow` isExpandedRow branch):
the bare `tr.n-data-table-tr.n-data-table-tr--expanded` over ONE td —
base + always `--last-col` + conditionally `--last-row` over the tiled
rows, `colspan` = the LEAF column count (`cols.length`), no
`data-col-key` / style / spans —
carrying `renderExpand(row, paginatedIndex)`, wrapped in the sticky
`div.n-data-table-expand[style="width:{n}px"]` iff `stickyExpandedRows`
(with `bodyWidth` measured — upstream renders the bare wrapper until its
first measurement).
-}
expandedTrNode : Options row msg -> row -> Int -> Int -> Int -> Html.Html msg
expandedTrNode opts row paginatedIndex displayedIndex displayedCount =
    Html.tr
        [ HA.class "n-data-table-tr n-data-table-tr--expanded" ]
        [ Html.td
            [ HA.class
                (String.join " "
                    ([ "n-data-table-td", "n-data-table-td--last-col" ]
                        ++ I.classIf (displayedIndex + 1 == displayedCount) "n-data-table-td--last-row"
                    )
                )
            , HA.colspan (List.length (leafColumns opts.columns))
            ]
            (case renderExpandOf opts of
                Just renderExpand ->
                    [ case opts.stickyExpandedRows of
                        True ->
                            Html.div
                                ([ HA.class "n-data-table-expand" ]
                                    ++ (case opts.bodyWidth of
                                            Just width ->
                                                [ HA.attribute "style" ("width:" ++ pxfy width) ]

                                            Nothing ->
                                                []
                                       )
                                )
                                [ embedChild (renderExpand row paginatedIndex) ]

                        False ->
                            embedChild (renderExpand row paginatedIndex)
                    ]

                Nothing ->
                    []
            )
        ]


{-| `getColKey` (upstream `utils.ts`) — the column identity for
`data-col-key` (and the `<col>` `key`): the sentinel on the special kinds,
the caller key on a basic column.
-}
colKeyOf : Column row msg -> String
colKeyOf col =
    case col.kind of
        KindSelection ->
            "__n_selection__"

        KindExpand ->
            "__n_expand__"

        KindNormal ->
            col.key


{-| `!expandable || expandable(rowData)` — whether an expand-cell
renders its trigger under the FIRST expand column's `expandable`
(upstream `expandableRef`) — the TILING gate. The CELL gate reads its own
column's (`cellExpandable`, upstream `Body.tsx` `column.expandable`); the
two differ only with multiple expand columns.
-}
expandableRow : Options row msg -> row -> Bool
expandableRow opts row =
    case expandableOf opts of
        Just expandable ->
            expandable row

        Nothing ->
            True


{-| The expand cell's own-column `!expandable || expandable(rowData)` —
upstream reads `column.expandable` on the CELL's column (Body.tsx), not
the first expand column's (that one gates the tiling walk).
-}
cellExpandable : Column row msg -> row -> Bool
cellExpandable col row =
    case col.expandable of
        Just expandable ->
            expandable row

        Nothing ->
            True


{-| The expand trigger (`ExpandTrigger.tsx` at rest — the tree-async
loading branch and its `NBaseLoading` are out of flat scope): the div
with `--expanded` for the merged set, the click firing the
`toggleExpandedRowKey` splice through `onUpdateExpandedRowKeys` (wired
only when the channel is set — listener presence is not a DOM byte), over
the `n-base-icon` chevron-right glyph or the table-level
`renderExpandIcon` slot (which rides the embed wrapper — see the
divergence notes). Upstream's `onMousedown` `preventDefault` has no Elm
surface without a no-op `msg` and no DOM byte.
-}
expandTriggerNode : Options row msg -> row -> Html.Html msg
expandTriggerNode opts row =
    let
        expanded =
            List.member (opts.rowKey row) opts.expandedRowKeys
    in
    Html.div
        ([ HA.class
            (String.join " "
                ([ "n-data-table-expand-trigger" ]
                    ++ I.classIf expanded "n-data-table-expand-trigger--expanded"
                )
            )
         ]
            ++ (case opts.onUpdateExpandedRowKeys of
                    Just onUpdate ->
                        [ Html.Events.onClick
                            (onUpdate (toggleExpandedRowKey (opts.rowKey row) opts.expandedRowKeys))
                        ]

                    Nothing ->
                        []
               )
        )
        [ case opts.renderExpandIcon of
            Just renderIcon ->
                embedChild (renderIcon expanded row)

            Nothing ->
                Html.i [ HA.class "n-base-icon" ] [ chevronRightIcon ]
        ]


{-| The `viewBox="0 0 16 16"` chevron-right glyph (`_internal/icons/
ChevronRight.tsx` under `NBaseIcon`) — the byte-identical constant the
Dropdown port already carries.
-}
chevronRightIcon : Html.Html msg
chevronRightIcon =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" NUI.Dropdown.chevronRightPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


{-| The selection menu's at-rest trigger (`SelectionMenu.tsx`): the
`NBaseIcon` fallthrough classes (own class first, fallthrough second) and
the chevron-down glyph; the click fires `onCheckExtraClick` for the
caller's `NUI.Dropdown` runtime (the open menu is not table DOM — see the
divergence notes).
-}
checkExtraNodes : Options row msg -> List (Html.Html msg)
checkExtraNodes opts =
    if checkOptionsOf opts == [] then
        []

    else
        [ Html.i
            ([ HA.class "n-base-icon n-data-table-check-extra" ]
                ++ (case opts.onCheckExtraClick of
                        Just msg ->
                            [ Html.Events.onClick msg ]

                        Nothing ->
                            []
                   )
            )
            [ chevronDownIcon ]
        ]


chevronDownIcon : Html.Html msg
chevronDownIcon =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" chevronDownPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


{-| The upstream `ChevronDown` glyph bytes (`_internal/icons/
ChevronDown.tsx`).
-}
chevronDownPath : String
chevronDownPath =
    "M3.14645 5.64645C3.34171 5.45118 3.65829 5.45118 3.85355 5.64645L8 9.79289L12.1464 5.64645C12.3417 5.45118 12.6583 5.45118 12.8536 5.64645C13.0488 5.84171 13.0488 6.15829 12.8536 6.35355L8.35355 10.8536C8.15829 11.0488 7.84171 11.0488 7.64645 10.8536L3.14645 6.35355C2.95118 6.15829 2.95118 5.84171 3.14645 5.64645Z"



-- CHECKED / EXPANDED CELLS -------------------------------------------------------


{-| The selection th's header checkbox (`Header.tsx` — no label, so no
`--show-label`): `privateInsideTable`, the header state over the current
page, and the toggle `handleCheckboxUpdateChecked` — allRowsChecked ?
uncheck-all : check-all, current page only, `row = Nothing` (the
checkbox's own `checked` / shift state are ignored, as upstream).
-}
headerCheckboxNode : Theme -> Options row msg -> Element msg
headerCheckboxNode theme opts =
    let
        cb =
            NUI.Checkbox.defaults
    in
    NUI.Checkbox.view theme
        { cb
            | privateInsideTable = True
            , checked = allRowsChecked opts
            , indeterminate = someRowsChecked opts
            , disabled = headerCheckboxDisabled opts
            , onCheckEvent =
                Maybe.map (\onUpdate _ _ -> headerCheckMsg opts onUpdate) opts.onUpdateCheckedRowKeys
        }
        []


headerCheckMsg : Options row msg -> (List String -> List row -> CheckEmit row -> msg) -> msg
headerCheckMsg opts onUpdate =
    if allRowsChecked opts then
        let
            keys =
                checkedKeysAfterUncheckAll opts False
        in
        onUpdate keys (emitRows opts keys) { row = Nothing, action = UncheckAll }

    else
        let
            keys =
                checkedKeysAfterCheckAll opts False
        in
        onUpdate keys (emitRows opts keys) { row = Nothing, action = CheckAll }


{-| The selection td's body checkbox (`BodyCheckbox.tsx`):
`privateInsideTable`, the row's `disabled(row)`, the display-set checked
state, indeterminate always `False` on flat data, and the shift-click
`handleCheckboxUpdateChecked` algorithm through `onCheckEvent` (checked,
shiftKey) — `lastSelectedKey` is the caller-owned anchor in `Options`.
-}
bodyCheckboxNode : Theme -> Options row msg -> row -> Element msg
bodyCheckboxNode theme opts row =
    let
        cb =
            NUI.Checkbox.defaults
    in
    NUI.Checkbox.view theme
        { cb
            | privateInsideTable = True
            , disabled = rowDisabled opts row
            , checked = List.member (opts.rowKey row) (mergedCheckedRowKeys opts)
            , indeterminate = False
            , onCheckEvent =
                Maybe.map (bodyCheckMsg opts row) opts.onUpdateCheckedRowKeys
        }
        []


bodyCheckMsg : Options row msg -> row -> (List String -> List row -> CheckEmit row -> msg) -> Bool -> Bool -> msg
bodyCheckMsg opts row onUpdate checked shiftKey =
    let
        keys =
            checkedKeysAfterRowClick opts (opts.rowKey row) checked shiftKey
    in
    onUpdate keys
        (emitRows opts keys)
        { row = Just row
        , action =
            if checked then
                Check

            else
                Uncheck
        }


{-| The selection td's body radio (`BodyRadio.tsx`): the row's
`disabled(row)` and display-set checked state over the replace-mode
`doCheck(key, single = true)` — a checked radio fires nothing (the port's
`onChange` gate matches upstream's change-event no-op). Upstream's
`name = componentId` lands on the inner `<input>` the radio port does
not render — the inherited no-input edge.
-}
bodyRadioNode : Theme -> Options row msg -> row -> Element msg
bodyRadioNode theme opts row =
    let
        rd =
            NUI.Radio.defaults
    in
    NUI.Radio.view theme
        { rd
            | disabled = rowDisabled opts row
            , checked = List.member (opts.rowKey row) (mergedCheckedRowKeys opts)
            , onChange =
                Maybe.map
                    (\onUpdate ->
                        onUpdate [ opts.rowKey row ] [ row ] { row = Just row, action = Check }
                    )
                    opts.onUpdateCheckedRowKeys
        }
        []



-- SORT -------------------------------------------------------------------------


{-| `getDefaultSorterFn`'s compare (upstream `use-sorter.ts`): null/null
ties, a lone null sorts first, number × number and string × string compare,
anything else ties (upstream `0`). Upstream compares strings with
`localeCompare`; Elm has no ICU collation, so an ordinal `compare` (strings
are `comparable`) stands in — the accepted divergence for non-ASCII
payloads.
-}
sortValueCompare : SortValue -> SortValue -> Basics.Order
sortValueCompare value1 value2 =
    case ( value1, value2 ) of
        ( SortNull, SortNull ) ->
            EQ

        ( SortNull, _ ) ->
            LT

        ( _, SortNull ) ->
            GT

        ( SortNumber number1, SortNumber number2 ) ->
            compare number1 number2

        ( SortString string1, SortString string2 ) ->
            compare string1 string2

        _ ->
            EQ


{-| `getSortFunction` (upstream `use-sorter.ts`) — resolves a sorter to its
compare fn: `'default'` (`SorterDefault`, and a multiple's
`compare: 'default'`) becomes `sortValueCompare` over the accessor, an
explicit fn passes through, a `{ multiple }` without a `compare` and the
async `true` sorter resolve to nothing — the state is still tracked (it
still drives `--sorting` and the sorter icon) but never orders rows.
-}
getSortFunction : Sorter row -> Maybe (row -> row -> Basics.Order)
getSortFunction sorter =
    case sorter of
        SorterDefault accessor ->
            Just (\row1 row2 -> sortValueCompare (accessor row1) (accessor row2))

        SorterBy compareFn ->
            Just compareFn

        SorterMultiple _ maybeCompare ->
            case maybeCompare of
                Just (CompareDefault accessor) ->
                    Just (\row1 row2 -> sortValueCompare (accessor row1) (accessor row2))

                Just (CompareBy compareFn) ->
                    Just compareFn

                Nothing ->
                    Nothing

        SorterAsync ->
            Nothing


{-| `getMultiplePriority` (upstream `use-sorter.ts`) — `Just` the
`multiple` number of a `SorterMultiple`, `Nothing` for every other shape
(upstream's `false`).
-}
getMultiplePriority : Sorter row -> Maybe Int
getMultiplePriority sorter =
    case sorter of
        SorterMultiple multiple _ ->
            Just multiple

        _ ->
            Nothing


{-| `isColumnSortable` (upstream `utils.ts`) — a childless column with a
sorter; the `'children' in column` gate makes every group header
unsortable (its th renders the bare title wrapper, no button, no click).
-}
isSortable : Column row msg -> Bool
isSortable col =
    col.children == Nothing && col.sorter /= Nothing


{-| `isColumnSorting` (upstream `utils.ts`) — some sort state names this
column's key with a truthy order (`Ascend` / `Descend`).
-}
isColumnSorting : Column row msg -> List (SortState row) -> Bool
isColumnSorting col states =
    List.any (\state -> state.columnKey == col.key && state.order /= NoSort) states


{-| The initial uncontrolled state (upstream `defaultSortState`): every
column with a sorter seeds `{ columnKey, sorter, order = defaultSortOrder }`
into the state, upserted by key (`updateSortStatesByNewSortState` — replaced
at the key's index, else appended), in column order.
-}
defaultSortStates : List (Column row msg) -> List (SortState row)
defaultSortStates columns =
    List.foldl
        (\col acc ->
            case col.sorter of
                Nothing ->
                    acc

                Just sorter ->
                    upsertSortState
                        { columnKey = col.key
                        , order = col.defaultSortOrder
                        , sorter = sorter
                        }
                        acc
        )
        []
        (leafColumns columns)


{-| `updateSortStatesByNewSortState` (upstream `use-sorter.ts`) — replace
the state at its `columnKey`'s index, else append it.
-}
upsertSortState : SortState row -> List (SortState row) -> List (SortState row)
upsertSortState state states =
    if List.any (\existing -> existing.columnKey == state.columnKey) states then
        List.map
            (\existing ->
                if existing.columnKey == state.columnKey then
                    state

                else
                    existing
            )
            states

    else
        states ++ [ state ]


{-| `mergedSortStateRef` (upstream `use-sorter.ts`) — the effective state:
a column with a sorter and a `sortOrder` is controlled; if any controlled
column actually sorts (order ≠ `NoSort`), the state is the controlled
columns with a non-`NoSort` order mapped to `{ columnKey, order, sorter }`
in column order (a controlled `NoSort` column contributes nothing but still
suppresses the uncontrolled list); if some column is controlled but none
sorts, the state is `[]`; otherwise the uncontrolled list passes through
as-is. The controlled filter gates `kind /= KindSelection` — upstream's
`column.type !== 'selection'`, and ONLY that (the expand kind is not
gated; its sorter is unreachable upstream, see the divergence notes).
-}
mergedSortStates : List (Column row msg) -> List (SortState row) -> List (SortState row)
mergedSortStates columns uncontrolled =
    let
        dataRelatedCols =
            leafColumns columns

        controlled =
            List.filter
                (\col -> col.kind /= KindSelection && col.sorter /= Nothing && col.sortOrder /= Nothing)
                dataRelatedCols

        activeStates =
            List.filterMap
                (\col ->
                    case ( col.sortOrder, col.sorter ) of
                        ( Just order, Just sorter ) ->
                            if order /= NoSort then
                                Just
                                    { columnKey = col.key
                                    , order = order
                                    , sorter = sorter
                                    }

                            else
                                Nothing

                        _ ->
                            Nothing
                )
                controlled
    in
    if List.any (\col -> col.sortOrder /= Just NoSort) controlled then
        activeStates

    else if controlled /= [] then
        []

    else
        uncontrolled


{-| `getNextOrderOf` (upstream `utils.ts`) — the click cycle
`false → descend → ascend → false`, so a column's first click sorts
descending.
-}
nextSortOrder : SortOrder -> SortOrder
nextSortOrder order =
    case order of
        NoSort ->
            Descend

        Descend ->
            Ascend

        Ascend ->
            NoSort


{-| `createNextSorter` (upstream `utils.ts`) — the state a click on `col`
produces: nothing when the column has no sorter, a fresh descending state
when there is no current state (or it names another key), else the current
state with its order advanced through the cycle.
-}
createNextSorter : Column row msg -> Maybe (SortState row) -> Maybe (SortState row)
createNextSorter col current =
    case col.sorter of
        Nothing ->
            Nothing

        Just sorter ->
            case current of
                Nothing ->
                    Just
                        { columnKey = col.key
                        , order = Descend
                        , sorter = sorter
                        }

                Just state ->
                    if state.columnKey /= col.key then
                        Just
                            { columnKey = col.key
                            , order = Descend
                            , sorter = sorter
                            }

                    else
                        Just { state | order = nextSortOrder state.order }


{-| `deriveNextSorter` → `getUpdatedSorterState` (upstream
`use-sorter.ts:180` — note the base is the MERGED state, not the caller's
uncontrolled list): a multiple sorter keeps only the base's
multiple-priority states and upserts the new one among them; a single
sorter replaces the whole state; nothing clears it.
-}
deriveNextSorter : List (SortState row) -> Maybe (SortState row) -> List (SortState row)
deriveNextSorter base next =
    case next of
        Nothing ->
            []

        Just state ->
            case getMultiplePriority state.sorter of
                Just _ ->
                    base
                        |> List.filter (\existing -> getMultiplePriority existing.sorter /= Nothing)
                        |> upsertSortState state

                Nothing ->
                    [ state ]


{-| The `some()` walk of `sortedDataRef`'s comparator (upstream
`use-sorter.ts:148-178`, ported exactly): the first active state that has a
compare fn and a truthy order and actually distinguishes the rows wins,
inverted when the order is `Descend` (`getFlagOfOrder`: ascend `1`,
descend `-1`); a state without a fn (or with `NoSort`) never distinguishes,
so ties fall through to the next state, and a full tie is `EQ`.
-}
compareRows : List (SortState row) -> row -> row -> Basics.Order
compareRows activeSorters row1 row2 =
    case activeSorters of
        [] ->
            EQ

        { sorter, order } :: rest ->
            if order /= NoSort then
                case getSortFunction sorter of
                    Just compareFn ->
                        case compareFn row1 row2 of
                            EQ ->
                                compareRows rest row1 row2

                            result ->
                                applyOrderFlag order result

                    Nothing ->
                        compareRows rest row1 row2

            else
                compareRows rest row1 row2


{-| `getFlagOfOrder` (upstream `utils.ts`) — the comparator sign: ascend
keeps the result, descend inverts it (`false` never reaches here — a
`NoSort` state does not distinguish).
-}
applyOrderFlag : SortOrder -> Basics.Order -> Basics.Order
applyOrderFlag order result =
    case order of
        Descend ->
            case result of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT

        _ ->
            result


{-| `sortedDataRef` (upstream `use-sorter.ts`) — the filtered data sorted
by the merged state: no state at all passes the data through untouched;
otherwise the states are ordered by multiple priority descending (missing
priorities count `0`; JS sort is stable, so ties keep merged order) and
the rows fold through `compareRows`.
-}
sortedData : Options row msg -> List row
sortedData opts =
    case mergedSortStates opts.columns opts.sortStates of
        [] ->
            filteredData opts

        merged ->
            List.sortWith
                (compareRows (byPriorityDesc merged))
                (filteredData opts)


byPriorityDesc : List (SortState row) -> List (SortState row)
byPriorityDesc states =
    List.sortBy
        (\state -> negate (Maybe.withDefault 0 (getMultiplePriority state.sorter)))
        states



-- PAGINATION --------------------------------------------------------------------


{-| `filteredDataRef` (upstream `use-table-data.ts` :118) — the row walk
over the merged filter state, basic columns only (selection / expand
columns never enter `columnEntries`): a `null` value or an empty array
skips the column (a missing key reads `undefined`, upstream's `== null`),
a non-array wraps into a one-element array; `FilterAsync` skips (upstream's
`typeof filter !== 'function'`); `'default'` runs the substring default
filter (`!!~String(row[key]).indexOf(String(value))`) and a custom fn the
caller's; `filterMode = 'and'` excludes a row failing ANY active value,
`'or'` (the default) keeps a row matching ANY — all per column, in column
order, over the pre-sort rows (the b2 pipeline reads this instead of the
raw data now).
-}
filteredData : Options row msg -> List row
filteredData opts =
    let
        states =
            mergedFilterStates opts

        basicColumns =
            List.filter (\col -> col.kind == KindNormal) (leafColumns opts.columns)

        columnPasses col row =
            case activeFilterValues states col of
                [] ->
                    True

                active ->
                    let
                        apply match =
                            case col.filterMode of
                                FilterAnd ->
                                    not (List.any (\value -> not (match value)) active)

                                FilterOr ->
                                    List.any match active
                    in
                    case col.filter of
                        Just (FilterDefault accessor) ->
                            apply (\value -> String.contains value (accessor row))

                        Just (FilterCustom match) ->
                            apply (\value -> match value row)

                        _ ->
                            True
    in
    List.filter (\row -> List.all (\col -> columnPasses col row) basicColumns) opts.data


{-| The column's active filter values — the merged value unwrapped the
walk's way (`== null` skips, a non-array wraps, an empty array skips);
`Nothing`-filter columns still resolve their values (the walk checks
`typeof filter` only AFTER the array gates, so an async column with a
live value contributes nothing — `activeFilterValues` callers that need
the un-gated value read the state directly).
-}
activeFilterValues : List ( String, FilterValue ) -> Column row msg -> List String
activeFilterValues states col =
    case filterValueOf states col.key of
        Just (FilterMany (x :: xs)) ->
            x :: xs

        Just (FilterOne value) ->
            [ value ]

        _ ->
            []


{-| `mergedPageSizeRef` (upstream `use-table-data.ts`) — the pagination
object's `pageSize`, else `getDefaultPageSize` over its `pageSizes`
(`NUI.Pagination` has no `defaultPageSize` field — see the divergence
notes).
-}
mergedPageSize : Options row msg -> Int
mergedPageSize opts =
    let
        base =
            paginationBase opts
    in
    Maybe.withDefault
        (NUI.Pagination.getDefaultPageSize
            { defaultPageSize = Nothing
            , pageSizes = base.pageSizes
            }
        )
        base.pageSize


{-| `mergedItemCountRef` (upstream `use-table-data.ts`) — remote defers to
the pagination object's `itemCount` (possibly nothing); local counts the
filtered data.
-}
mergedItemCount : Options row msg -> Maybe Int
mergedItemCount opts =
    if opts.remote then
        paginationBase opts |> .itemCount

    else
        Just (List.length (filteredData opts))


{-| `boundedMergedCurrentPageRef` (upstream `use-table-data.ts`) — remote
passes the page through; local clamps it into
`[1, ceil(length / pageSize)]`.
-}
boundedPage : Options row msg -> Int
boundedPage opts =
    if opts.remote then
        paginationBase opts |> .currentPage

    else
        let
            lastPage =
                ceiling (toFloat (List.length (filteredData opts)) / toFloat (mergedPageSize opts))
        in
        max 1 (min lastPage (paginationBase opts |> .currentPage))


{-| The pagination-object base — `NUI.Pagination.defaults` when the caller
passed none (only reachable for the merge helpers; `paginatedData` /
`showPagination` short-circuit on `opts.pagination == Nothing` first, like
upstream's `!props.pagination` guards).
-}
paginationBase : Options row msg -> NUI.Pagination.Options msg
paginationBase opts =
    Maybe.withDefault NUI.Pagination.defaults opts.pagination


{-| `mergedPaginationRef` (upstream `use-table-data.ts:303-331`) — the
caller's pagination object with the derived overrides: the bounded page,
the merged page size, the merged item count, the pageCount blanked
whenever the item count is set (upstream `undefined`), and the table-level
page/page-size handlers replacing the object's own (the single-channel
divergence).
-}
mergedPaginationOpts : Options row msg -> NUI.Pagination.Options msg
mergedPaginationOpts opts =
    let
        base =
            paginationBase opts
    in
    { base
        | currentPage = boundedPage opts
        , pageSize = Just (mergedPageSize opts)
        , itemCount = mergedItemCount opts
        , pageCount =
            if mergedItemCount opts == Nothing then
                base.pageCount

            else
                Nothing
        , onUpdatePage = opts.onUpdatePage
        , onUpdatePageSize = opts.onUpdatePageSize
    }


{-| `paginatedDataRef` (upstream `use-table-data.ts`) — remote hands the
raw data to the caller (the server paginates); no pagination object means
the sorted data as-is; otherwise the sorted data's window from
`(page - 1) * pageSize`, `pageSize` rows deep.
-}
paginatedData : Options row msg -> List row
paginatedData opts =
    if opts.remote then
        opts.data

    else
        case opts.pagination of
            Nothing ->
                sortedData opts

            Just _ ->
                let
                    pageSize =
                        mergedPageSize opts
                in
                List.take pageSize
                    (List.drop ((boundedPage opts - 1) * pageSize) (sortedData opts))


{-| `mergedShowPaginationRef` (upstream `DataTable.tsx:454-466`) — no
pagination object means no node; `paginateSinglePage` (upstream default
`true`) shows it anyway; otherwise read the MERGED pagination: a pageCount
shows iff it exceeds 1 (the merge blanks it whenever itemCount is set),
else `itemCount && pageSize && itemCount > pageSize` (upstream's truthy
short-circuit is subsumed — a 0 item count never exceeds the page size).
-}
showPagination : Options row msg -> Bool
showPagination opts =
    case opts.pagination of
        Nothing ->
            False

        Just _ ->
            if opts.paginateSinglePage then
                True

            else
                let
                    merged =
                        mergedPaginationOpts opts
                in
                case merged.pageCount of
                    Just count ->
                        count > 1

                    Nothing ->
                        case ( merged.itemCount, merged.pageSize ) of
                            ( Just itemCount, Just pageSize ) ->
                                itemCount > pageSize

                            _ ->
                                False



-- FILTER -------------------------------------------------------------------------


{-| The uncontrolled filter state's seed — upstream's initialize walk
(`use-table-data.ts` :198) over every column with a truthy `filter`, in
column order: `filterMultiple` → `defaultFilterOptionValues || []` (null
and `[]` both land `[]`); a single column with `defaultFilterOptionValues`
set keeps them (upstream's single-mode compatibility branch — the array
stays an array); otherwise `defaultFilterOptionValue ?? null` (the
`FilterNull` — a present cleared key, byte-faithful to upstream's `??
null`). Upstream branches on `filterMultiple` TRUTHINESS — an
`undefined` field takes the single branch where the menu reads multiple;
the port's `Bool` collapses that cell (see the divergence notes).
-}
defaultFilterStates : List (Column row msg) -> List ( String, FilterValue )
defaultFilterStates columns =
    List.filterMap
        (\col ->
            case col.filter of
                Nothing ->
                    Nothing

                Just _ ->
                    if col.filterMultiple then
                        Just ( col.key, FilterMany (Maybe.withDefault [] col.defaultFilterOptionValues) )

                    else
                        case col.defaultFilterOptionValues of
                            Just values ->
                                Just ( col.key, FilterMany values )

                            Nothing ->
                                Just
                                    ( col.key
                                    , case col.defaultFilterOptionValue of
                                        Just value ->
                                            FilterOne value

                                        Nothing ->
                                            FilterNull
                                    )
        )
        (leafColumns columns)


{-| `mergedFilterStateRef` (upstream `use-table-data.ts` :91) — the
caller-owned uncontrolled state (`filterStates`) overlaid with the
controlled columns (`filterOptionValues` set, or `filterOptionValue` set
— a `Just Nothing` single value is upstream's `null`, `Nothing` its
`undefined`): uncontrolled order preserved, controlled keys replaced in
place or appended in column walk order (`Object.assign` key semantics).
Selection / expand columns never overlay (upstream's `type` guard — their
`never` fields would still count as "controlled" upstream).
-}
mergedFilterStates : Options row msg -> List ( String, FilterValue )
mergedFilterStates opts =
    let
        controlled =
            List.filterMap
                (\col ->
                    if col.kind /= KindNormal then
                        Nothing

                    else
                        case ( col.filterOptionValues, col.filterOptionValue ) of
                            ( Just values, _ ) ->
                                Just ( col.key, FilterMany values )

                            ( Nothing, Just single ) ->
                                Just
                                    ( col.key
                                    , case single of
                                        Just value ->
                                            FilterOne value

                                        Nothing ->
                                            FilterNull
                                    )

                            ( Nothing, Nothing ) ->
                                Nothing
                )
                (leafColumns opts.columns)
    in
    List.foldl
        (\entry acc -> upsertFilterState acc entry)
        opts.filterStates
        controlled


{-| `createFilterState` over the MERGED state (upstream `FilterButton.tsx`
:21 + :81) — the whole next uncontrolled state a confirm / clear commit
emits: the merged map with this column's key set (replaced in place or
appended — `Object.assign` semantics again).
-}
filtersAfterChange : Options row msg -> Column row msg -> FilterValue -> List ( String, FilterValue )
filtersAfterChange opts col value =
    upsertFilterState (mergedFilterStates opts) ( col.key, value )


{-| `isColumnFilterable` (upstream `utils.ts`) — a childless column with a
truthy `filter` AND `filterOptions` set (`filterOptions = Just []` keeps
the button: upstream's empty array is truthy). Upstream's third leg
`|| !!column.renderFilterMenu` has no port surface (render props, the
sorter precedent — see the divergence notes); the `'children' in
column` gate makes every group header unfilterable (a bare title th).
-}
isColumnFilterable : Column row msg -> Bool
isColumnFilterable col =
    col.children == Nothing && (col.filter /= Nothing && col.filterOptions /= Nothing)


{-| `shouldUseArrayInSingleMode` (upstream `utils.ts` :107) — the
single-mode compatibility flag: a controlled `filterOptionValues`, or
`defaultFilterOptionValues` without a controlled single value (the
radio-value read and the clear payload of the menu follow it).
-}
shouldUseArrayInSingleMode : Column row msg -> Bool
shouldUseArrayInSingleMode col =
    (col.filterOptionValues /= Nothing)
        || (col.filterOptionValue == Nothing && col.defaultFilterOptionValues /= Nothing)


{-| One `FilterState` entry set — `Object.assign` key semantics: an
existing key replaced in place, a new key appended.
-}
upsertFilterState : List ( String, FilterValue ) -> ( String, FilterValue ) -> List ( String, FilterValue )
upsertFilterState states ( key, value ) =
    if List.any (\( k, _ ) -> k == key) states then
        List.map
            (\( k, v ) ->
                if k == key then
                    ( k, value )

                else
                    ( k, v )
            )
            states

    else
        states ++ [ ( key, value ) ]


{-| The merged state's entry for a key — `Nothing` is upstream's missing
key (a `null` entry is `Just FilterNull`, not absence).
-}
filterValueOf : List ( String, FilterValue ) -> String -> Maybe FilterValue
filterValueOf states key =
    List.filter (\( k, _ ) -> k == key) states
        |> List.head
        |> Maybe.map Tuple.second



-- FILTER MENU -------------------------------------------------------------------


{-| The filter menu body's options (upstream `FilterMenu.tsx` props, plus
the caller-owned seams): `multiple` is the column's `filterMultiple`,
`options` its `filterOptions`, `radioGroupName` upstream's
`String(column.key)` (carried for parity — the port's radios render no
`<input>`, so the name lands nowhere, the `BodyRadio` precedent),
`arraySingleMode` the column's `shouldUseArrayInSingleMode` (the radio
value read AND the clear payload follow it), `value` the menu-local
temporal value (caller-owned — seed the merged value, update on
`onChange`), and the labels the locale data upstream injects (`clear` /
`confirm` — the defaults are the enUS bytes `'Clear'` / `'Confirm'`, the
selection-menu caller-supplied precedent).
-}
type alias FilterMenuOptions msg =
    { multiple : Bool
    , options : List FilterOption
    , radioGroupName : String
    , arraySingleMode : Bool
    , value : FilterValue
    , rtl : Bool
    , onChange : Maybe (FilterValue -> msg)
    , onConfirm : Maybe (FilterValue -> msg)
    , onClear : Maybe (FilterValue -> msg)
    , clearLabel : String
    , confirmLabel : String
    }


{-| The defaults — `multiple` on (upstream `filterMultiple !== false`),
an empty multiple value, the enUS labels, everything else off / empty.
-}
filterMenuDefaults : FilterMenuOptions msg
filterMenuDefaults =
    { multiple = True
    , options = []
    , radioGroupName = ""
    , arraySingleMode = False
    , value = FilterMany []
    , rtl = False
    , onChange = Nothing
    , onConfirm = Nothing
    , onClear = Nothing
    , clearLabel = "Clear"
    , confirmLabel = "Confirm"
    }


{-| The filter menu body (`FilterMenu.tsx` render) — the element for the
caller's popover (upstream `FilterButton`'s `NPopover` with
`trigger="click"`, `placement="bottom"` and `style padding: 0`; the
port composes `NUI.Popover` over it — see the divergence notes): the
`n-data-table-filter-menu` root carrying the three `--n-action-*` vars
(upstream `filterMenuCssVars`), the `NScrollbar`-wrapped group
(checkboxes when `multiple`, else radios — the group element carries
the `__group` fallthrough class) and the `__action` bar (a tiny clear
button, then a tiny primary confirm). The scrollbar, the group and the
buttons are `Element`s embedded through the `display: contents` seam.
-}
filterMenu : Theme -> FilterMenuOptions msg -> Element msg
filterMenu theme opts =
    let
        v =
            DataTableTheme.vars theme

        btn =
            NUI.Button.defaults
    in
    Element.html
        (Html.div
            [ HA.class
                (String.join " "
                    ([ "n-data-table-filter-menu" ]
                        ++ I.classIf opts.rtl "n-data-table-filter-menu--rtl"
                    )
                )
            , HA.attribute "style"
                (I.renderVars
                    [ ( "--n-action-padding", v.actionPadding )
                    , ( "--n-action-button-margin", v.actionButtonMargin )
                    , ( "--n-action-divider-color", v.actionDividerColor )
                    ]
                )
            ]
            [ embedChild (filterMenuScrollbar theme opts)
            , Html.div [ HA.class "n-data-table-filter-menu__action" ]
                [ embedChild
                    (NUI.Button.view theme
                        { btn
                            | size = T.Tiny
                            , onPress = Maybe.map (\f -> f (filterMenuClearedValue opts)) opts.onClear
                        }
                        [ Element.text opts.clearLabel ]
                    )
                , embedChild
                    (NUI.Button.view theme
                        { btn
                            | kind = T.Primary
                            , size = T.Tiny
                            , onPress = Maybe.map (\f -> f opts.value) opts.onConfirm
                        }
                        [ Element.text opts.confirmLabel ]
                    )
                ]
            ]
        )


{-| The menu's `NScrollbar` — plain defaults; the `max-height: 240px`
rides the `.n-data-table-filter-menu .n-scrollbar` ancestor selector.
-}
filterMenuScrollbar : Theme -> FilterMenuOptions msg -> Element msg
filterMenuScrollbar theme opts =
    NUI.Scrollbar.view theme
        NUI.Scrollbar.defaults
        [ if opts.multiple then
            filterMenuCheckboxGroup theme opts

          else
            filterMenuRadioGroup theme opts
        ]


{-| The multiple group — upstream `NCheckboxGroup` with the `__group`
fallthrough class (`<div class="n-checkbox-group
n-data-table-filter-menu__group" role="group">` — no vars of its own);
the checkboxes toggle the temporal value the way upstream's
toggleCheckbox does: a check PUSHES at the end if absent, an uncheck
splices the FIRST occurrence (click order, not option order).
-}
filterMenuCheckboxGroup : Theme -> FilterMenuOptions msg -> Element msg
filterMenuCheckboxGroup theme opts =
    let
        values =
            case opts.value of
                FilterMany xs ->
                    xs

                _ ->
                    []

        toggled value next =
            if next then
                FilterMany
                    (if List.member value values then
                        values

                     else
                        values ++ [ value ]
                    )

            else
                FilterMany
                    (case indexOf (\x -> x == value) values of
                        Just index ->
                            List.take index values ++ List.drop (index + 1) values

                        Nothing ->
                            values
                    )
    in
    Element.html
        (Html.div
            [ HA.class "n-checkbox-group n-data-table-filter-menu__group"
            , HA.attribute "role" "group"
            ]
            (List.map
                (\option ->
                    let
                        cb =
                            NUI.Checkbox.defaults
                    in
                    embedChild
                        (NUI.Checkbox.view theme
                            { cb
                                | checked = List.member option.value values
                                , onCheck = Maybe.map (\f next -> f (toggled option.value next)) opts.onChange
                            }
                            [ Element.text option.label ]
                        )
                )
                opts.options
            )
        )


{-| The single group — upstream `NRadioGroup` with the `__group`
fallthrough class; the value read is upstream `radioGroupValue` (an
array-single mode reads a non-empty array's head, else the scalar; a
null / array mismatch reads `Nothing`) and the change wraps the scalar
into an array in the compat mode (`handleChange`'s branch).
-}
filterMenuRadioGroup : Theme -> FilterMenuOptions msg -> Element msg
filterMenuRadioGroup theme opts =
    let
        radioValue =
            case ( opts.arraySingleMode, opts.value ) of
                ( True, FilterMany (x :: _) ) ->
                    Just x

                ( False, FilterOne value ) ->
                    Just value

                _ ->
                    Nothing

        change value =
            if opts.arraySingleMode then
                FilterMany [ value ]

            else
                FilterOne value

        rg =
            NUI.Radio.groupDefaults
    in
    NUI.Radio.group theme
        { rg
            | value = radioValue
            , onChange = Maybe.map (\f value -> f (change value)) opts.onChange
            , attributes = [ I.classes [ "n-data-table-filter-menu__group" ] ]
        }
        (List.map (\option -> NUI.Radio.choice option.value option.label) opts.options)


{-| The clear button's committed value — `handleClearClick`'s payload:
`[]` when multiple or array-in-single mode, else `null`.
-}
filterMenuClearedValue : FilterMenuOptions msg -> FilterValue
filterMenuClearedValue opts =
    if opts.multiple || opts.arraySingleMode then
        FilterMany []

    else
        FilterNull



-- GROUP / SUMMARY / MERGE -------------------------------------------------------


{-| One header cell of the group-header walk — upstream `RowItem`
(`use-group-header.ts`): the column, its leaf index, its `colSpan` /
`rowSpan` (rendered on EVERY th, spans of 1 included) and its `isLast`
flag (the `--last` class).
-}
type alias HeaderCell row msg =
    { column : Column row msg
    , colIndex : Int
    , colSpan : Int
    , rowSpan : Int
    , isLast : Bool
    }


{-| Pass 1 of `getRowsAndCols` (`use-group-header.ts`) minus the
virtual-scroll `ColItem` build — the leaf walk: a `children`-present
column recurses (its own record never yields — `Just []` contributes
nothing and is NOT a leaf), a childless column IS the leaf. This drives
every data-related column walk (colgroup, sort / filter pipelines,
selection / expand lookup, the body cells); group columns are inert by
construction.
-}
leafColumns : List (Column row msg) -> List (Column row msg)
leafColumns columns =
    List.concatMap
        (\col ->
            case childColumns col of
                Just children ->
                    leafColumns children

                Nothing ->
                    [ col ]
        )
        columns


{-| Unwrap `children` — `Nothing` on a childless column (the group gate
stays key-presence: `Just []` unwraps to `[]`, a group with no leaves).
-}
childColumns : Column row msg -> Maybe (List (Column row msg))
childColumns col =
    Maybe.map (List.map (\(ColumnChild child) -> child)) col.children


{-| `getRowsAndCols` pass-2 — the header-row layout, both passes verbatim:
pass 1 (`maxDepthOf` + `leafColumns`) fixes the leaf count
(`totalRowSpan`), the deepest group depth and the per-depth row lists;
pass 2 walks with a thread of the running `currentLeafIndex` and a
`hideUntilIndex` local to EACH recursion level (an argument here — it
does not leak across sibling subtrees):

  - a leaf under `hideUntilIndex` is swallowed by an earlier
    `titleColSpan` th — the index advances, no cell, nothing rendered;
  - a leaf otherwise takes `titleColSpan ?? 1`, sets `hideUntilIndex` to
    `index + colSpan` when the span exceeds 1, and lands `rowSpan =
    maxDepth - depth + 1` with `isLast = index + colSpan == totalRowSpan`;
  - a group saves the entry index, recurses with a FRESH
    `hideUntilIndex` (post-order — its cell lands after its children's,
    fixing intra-depth order), sums its direct children's cells'
    `colSpan` (a `Just []` group sums 0 — the th renders `colspan=0`,
    byte-faithful) and lands `rowSpan = 1` with
    `isLast = savedIndex + colSpan == totalRowSpan`.

The rows come back depth-bucketed in push order — `rows[depth]` exists
for every depth pass 1 entered, empty ones included (the `Just []`
edge's phantom row).

-}
headerRows : List (Column row msg) -> List (List (HeaderCell row msg))
headerRows columns =
    let
        totalRowSpan =
            List.length (leafColumns columns)

        maxDepth =
            maxDepthOf columns

        walk :
            List (Column row msg)
            -> Int
            -> Int
            -> Int
            -> WalkState row msg
        walk cols depth leafIndex hideUntil =
            case cols of
                [] ->
                    WalkState leafIndex hideUntil 0 []

                col :: rest ->
                    case childColumns col of
                        Just children ->
                            let
                                cached =
                                    leafIndex

                                afterChildren =
                                    walk children (depth + 1) leafIndex 0

                                isLast =
                                    cached + afterChildren.ownColSpans == totalRowSpan

                                cell =
                                    HeaderCell col cached afterChildren.ownColSpans 1 isLast

                                afterRest =
                                    walk rest depth afterChildren.leafIndex hideUntil
                            in
                            WalkState afterRest.leafIndex
                                afterRest.hideUntil
                                (afterChildren.ownColSpans + afterRest.ownColSpans)
                                (afterChildren.emitted ++ (( depth, cell ) :: afterRest.emitted))

                        Nothing ->
                            if leafIndex < hideUntil then
                                walk rest depth (leafIndex + 1) hideUntil

                            else
                                let
                                    colSpan =
                                        Maybe.withDefault 1 col.titleColSpan

                                    hideUntilNext =
                                        if colSpan > 1 then
                                            leafIndex + colSpan

                                        else
                                            hideUntil

                                    isLast =
                                        leafIndex + colSpan == totalRowSpan

                                    cell =
                                        HeaderCell col leafIndex colSpan (maxDepth - depth + 1) isLast

                                    afterRest =
                                        walk rest depth (leafIndex + 1) hideUntilNext
                                in
                                WalkState afterRest.leafIndex
                                    afterRest.hideUntil
                                    (colSpan + afterRest.ownColSpans)
                                    (( depth, cell ) :: afterRest.emitted)

        final =
            walk columns 0 0 0
    in
    List.range 0 maxDepth
        |> List.map
            (\depth ->
                List.filterMap
                    (\( d, cell ) ->
                        if d == depth then
                            Just cell

                        else
                            Nothing
                    )
                    final.emitted
            )


{-| The pass-2 walk state — the running `leafIndex`, the level-local
`hideUntil`, the sum of the colSpans pushed at THIS walk's depth (the
group parent's `colSpan` source) and the depth-tagged cells in push
order.
-}
type alias WalkState row msg =
    { leafIndex : Int
    , hideUntil : Int
    , ownColSpans : Int
    , emitted : List ( Int, HeaderCell row msg )
    }


{-| Pass 1's `maxDepth` — the deepest depth the walk ENTERS: a
`children`-present column recurses to `depth + 1` whatever its children
(`Just []` still bumps the depth — its row exists, empty), a leaf adds
nothing. Drives the leaf `rowSpan = maxDepth - depth + 1`.
-}
maxDepthOf : List (Column row msg) -> Int
maxDepthOf columns =
    List.foldl
        (\col acc ->
            case childColumns col of
                Just children ->
                    max (1 + maxDepthOf children) acc

                Nothing ->
                    acc
        )
        0
        columns



-- SELECTION ---------------------------------------------------------------------


{-| `selectionColumnRef` (upstream `use-table-data.ts`) — the FIRST
selection column (depth-first through groups upstream; the flat list
order here), or nothing.
-}
selectionColumn : Options row msg -> Maybe (Column row msg)
selectionColumn opts =
    List.filter (\col -> col.kind == KindSelection) (leafColumns opts.columns)
        |> List.head


{-| `checkOptionsRef` — the first selection column's `options` (the header
menu renders off this list, whatever selection column's th it is).
-}
checkOptionsOf : Options row msg -> List (SelectionOption row msg)
checkOptionsOf opts =
    selectionColumn opts
        |> Maybe.map .options
        |> Maybe.withDefault []


{-| treeMate's `getDisabled` — the first selection column's `disabled(row)`
(single arg, upstream `TableSelectionColumn.disabled`), `False` when
absent: the row-level gate behind the body checkboxes / radios, the
header math and the check-all key walks.
-}
rowDisabled : Options row msg -> row -> Bool
rowDisabled opts row =
    selectionColumn opts
        |> Maybe.andThen .disabled
        |> Maybe.map (\disabled -> disabled row)
        |> Maybe.withDefault False


{-| The selection mode — `multiple === false` on the FIRST selection
column (`True` when there is none, upstream's `?.multiple === false`).
-}
multipleOf : Options row msg -> Bool
multipleOf opts =
    selectionColumn opts
        |> Maybe.map .multiple
        |> Maybe.withDefault True


{-| `mergedCheckState.checkedKeys` (upstream `use-check.ts`) — the DISPLAY
keys: `multiple = False` slices the source to its first key (no treemate
pass, order preserved — a bogus head key survives here until a click
replaces the list); otherwise the flat-data treemate `getCheckedKeys`
derivation — every data row, in data order, whose key is a member of the
source list (the tree-walk collection drops unknown keys and reorders).
The indeterminate half is always `[]` on flat data (every row a leaf).
-}
mergedCheckedRowKeys : Options row msg -> List String
mergedCheckedRowKeys opts =
    if multipleOf opts then
        List.filter (\row -> List.member (opts.rowKey row) opts.checkedRowKeys) opts.data
            |> List.map opts.rowKey

    else
        List.take 1 opts.checkedRowKeys


{-| `countOfCurrentPageCheckedRowsRef` — current-page rows (over the
paginated data) that are neither `disabled` nor outside the display set.
-}
countCurrentPageChecked : Options row msg -> Int
countCurrentPageChecked opts =
    List.filter
        (\row -> not (rowDisabled opts row) && List.member (opts.rowKey row) (mergedCheckedRowKeys opts))
        (paginatedData opts)
        |> List.length


{-| `countOfCurrentPageDisabledRowsRef` — current-page rows failing the
selection column's `disabled`.
-}
countCurrentPageDisabled : Options row msg -> Int
countCurrentPageDisabled opts =
    List.filter (rowDisabled opts) (paginatedData opts)
        |> List.length


{-| `someRowsCheckedRef` — the header checkbox's indeterminate state: some
but not all of the current page's enabled rows checked, or any current-
page key in the indeterminate set (never, on flat data).
-}
someRowsChecked : Options row msg -> Bool
someRowsChecked opts =
    let
        rows =
            paginatedData opts

        checked =
            countCurrentPageChecked opts

        enabled =
            List.length rows - countCurrentPageDisabled opts
    in
    -- the second disjunct — any current-page key in the indeterminate
    -- set — never fires on flat data (the set is always [])
    checked > 0 && checked < enabled


{-| `allRowsCheckedRef` — the header checkbox's checked state: at least one
current-page enabled row checked, and all of them.
-}
allRowsChecked : Options row msg -> Bool
allRowsChecked opts =
    let
        checked =
            countCurrentPageChecked opts

        enabled =
            List.length (paginatedData opts) - countCurrentPageDisabled opts
    in
    checked /= 0 && checked == enabled


{-| `headerCheckboxDisabledRef` — no current-page rows.
-}
headerCheckboxDisabled : Options row msg -> Bool
headerCheckboxDisabled opts =
    paginatedData opts == []


{-| The flat-data treemate `check` derivation — the emit base is the
DISPLAY state; the new keys append (in the given order) when not already
present: merged order, then appended new keys.
-}
checkUnion : List String -> List String -> List String
checkUnion current new =
    current ++ List.filter (\key -> not (List.member key current)) new


{-| The flat-data treemate `uncheck` derivation — the display state minus
the removed keys, order preserved.
-}
uncheckDiff : List String -> List String -> List String
uncheckDiff current remove =
    List.filter (\key -> not (List.member key remove)) current


{-| `doCheck(rowKey)` — the non-single branch: `treemate.check` over the
display state (the `loading` early return is the loading batch).
-}
checkedKeysAfterCheck : Options row msg -> List String -> List String
checkedKeysAfterCheck opts keys =
    checkUnion (mergedCheckedRowKeys opts) keys


{-| `doUncheck(rowKey)` — `treemate.uncheck` over the display state.
-}
checkedKeysAfterUncheck : Options row msg -> List String -> List String
checkedKeysAfterUncheck opts keys =
    uncheckDiff (mergedCheckedRowKeys opts) keys


{-| `doCheckAll(checkWholeTable)` — the selection-column gate then the
not-disabled keys of the whole table or the current page (`treeNodes` /
`paginatedData`), unioned into the display state (`cascade` is forced
upstream "to emit correct row keys" — flat, the plain union reads the
same). No selection column returns the display state unchanged.
-}
checkedKeysAfterCheckAll : Options row msg -> Bool -> List String
checkedKeysAfterCheckAll opts wholeTable =
    if selectionColumn opts == Nothing then
        mergedCheckedRowKeys opts

    else
        let
            keys =
                (if wholeTable then
                    opts.data

                 else
                    paginatedData opts
                )
                    |> List.filter (not << rowDisabled opts)
                    |> List.map opts.rowKey
        in
        checkUnion (mergedCheckedRowKeys opts) keys


{-| `doUncheckAll(checkWholeTable)` — the symmetric diff.
-}
checkedKeysAfterUncheckAll : Options row msg -> Bool -> List String
checkedKeysAfterUncheckAll opts wholeTable =
    if selectionColumn opts == Nothing then
        mergedCheckedRowKeys opts

    else
        let
            keys =
                (if wholeTable then
                    opts.data

                 else
                    paginatedData opts
                )
                    |> List.filter (not << rowDisabled opts)
                    |> List.map opts.rowKey
        in
        uncheckDiff (mergedCheckedRowKeys opts) keys


{-| `handleCheckboxUpdateChecked` (upstream `Body.tsx`) — the body
checkbox's click transform over the display state: with `shiftKey` and a
`lastSelectedKey` that resolves on the current page, the range
`[min(last, cur) .. max(last, cur)]` of paginated rows (`disabled`
filtered) checked or unchecked together; else the single key. `checked`
is the checkbox's NEXT state (the port's `onCheckEvent` first arg).
-}
checkedKeysAfterRowClick : Options row msg -> String -> Bool -> Bool -> List String
checkedKeysAfterRowClick opts rowKey checked shiftKey =
    let
        rows =
            paginatedData opts

        rangeKeys start end =
            rows
                |> List.drop start
                |> List.take (end - start + 1)
                |> List.filter (not << rowDisabled opts)
                |> List.map opts.rowKey

        apply keys =
            if checked then
                checkUnion (mergedCheckedRowKeys opts) keys

            else
                uncheckDiff (mergedCheckedRowKeys opts) keys
    in
    case ( shiftKey, indexOf (\row -> opts.rowKey row == rowKey) rows, indexOf (\row -> opts.rowKey row == opts.lastSelectedKey) rows ) of
        ( True, Just current, Just last ) ->
            apply (rangeKeys (min last current) (max last current))

        _ ->
            apply [ rowKey ]


indexOf : (a -> Bool) -> List a -> Maybe Int
indexOf pred xs =
    List.indexedMap Tuple.pair xs
        |> List.filter (\( _, x ) -> pred x)
        |> List.head
        |> Maybe.map Tuple.first


{-| The emit payload's `rows` — `keys.map(getNode.rawNode)` over ALL the
data; keys that resolve to no row drop their entry where upstream pushes
an `undefined` hole (caller-authored bogus keys only — see the
divergence notes).
-}
emitRows : Options row msg -> List String -> List row
emitRows opts keys =
    List.filterMap
        (\key ->
            List.filter (\row -> opts.rowKey row == key) opts.data
                |> List.head
        )
        keys



-- EXPAND -------------------------------------------------------------------------


{-| `renderExpandRef` / `expandableRef` (upstream `use-expand.ts`) — read
off the FIRST expand column (the caller DECLARES the `{type: 'expand'}`
column; there is no auto-insert).
-}
expandColumn : Options row msg -> Maybe (Column row msg)
expandColumn opts =
    expandColumnOf opts.columns


expandColumnOf : List (Column row msg) -> Maybe (Column row msg)
expandColumnOf columns =
    List.filter (\col -> col.kind == KindExpand) (leafColumns columns)
        |> List.head


renderExpandOf : Options row msg -> Maybe (row -> Int -> Element msg)
renderExpandOf opts =
    expandColumn opts
        |> Maybe.andThen .renderExpand


expandableOf : Options row msg -> Maybe (row -> Bool)
expandableOf opts =
    expandColumn opts
        |> Maybe.andThen .expandable


{-| `handleUpdateExpanded`'s key splice (upstream `Body.tsx`, flat data):
the key out at its FIRST index (upstream `indexOf` + `splice(index, 1)` —
all occurrences go only with caller-authored duplicate keys), else
appended — order preserved.
-}
toggleExpandedRowKey : String -> List String -> List String
toggleExpandedRowKey key keys =
    case indexOf (\k -> k == key) keys of
        Just index ->
            List.take index keys ++ List.drop (index + 1) keys

        Nothing ->
            keys ++ [ key ]


{-| The `defaultExpandAll` seed (upstream `use-expand.ts`) — flat-data
reading, off the FIRST expand column: with a `renderExpand` present, the
keys of the data rows passing its `expandable` (an absent `expandable`
fails the optional chain and seeds NOTHING — an upstream truthiness quirk
kept byte-faithful); without one, `getNonLeafKeys` — `[]` on flat data
(the walk never runs even with an `expandable` set).
-}
defaultExpandAllKeys : List (Column row msg) -> List row -> (row -> String) -> List String
defaultExpandAllKeys columns data rowKey =
    let
        expandCol =
            expandColumnOf columns
    in
    case expandCol |> Maybe.andThen .renderExpand of
        Just _ ->
            expandCol
                |> Maybe.andThen .expandable
                |> Maybe.map (\expandable -> List.filter expandable data |> List.map rowKey)
                |> Maybe.withDefault []

        Nothing ->
            []



-- SCROLL / LAYOUT ----------------------------------------------------------------


{-| `explicitlyScrollableRef` (upstream `use-scroll.ts` :33) — `scrollX`,
`maxHeight` or `flexHeight` set (`minHeight` does NOT count; neither does
an ellipsis-driven fixed layout).
-}
explicitlyScrollableOf : Options row msg -> Bool
explicitlyScrollableOf opts =
    opts.scrollX /= Nothing || opts.maxHeight /= Nothing || opts.flexHeight


{-| `hasEllipsisRef` (upstream `use-group-header.ts` :79) — any column
declares `ellipsis` (the header walk covers the td surface too — one
flag drives both).
-}
hasEllipsisOf : Options row msg -> Bool
hasEllipsisOf opts =
    List.any (\col -> col.ellipsis /= Nothing) (leafColumns opts.columns)


{-| `mergedTableLayoutRef` (upstream `DataTable.tsx` :191) — `fixed` when
`flexHeight` / `maxHeight` / any ellipsis column (virtual scroll is the
fourth upstream trigger — out of scope), else the caller's `tableLayout`.
-}
mergedTableLayoutOf : Options row msg -> TableLayout
mergedTableLayoutOf opts =
    if opts.flexHeight || opts.maxHeight /= Nothing || hasEllipsisOf opts then
        TableFixed

    else
        opts.tableLayout


{-| `xScrollableRef` (upstream `use-scroll.ts` :39) — `scrollX` set, or
the basic-auto-layout fallback (not explicitly scrollable and the merged
layout still `auto`; the spec's own comment: "auto layout empty tables
are treated as x-scrollable").
-}
xScrollableOf : Options row msg -> Bool
xScrollableOf opts =
    opts.scrollX
        /= Nothing
        || (not (explicitlyScrollableOf opts) && mergedTableLayoutOf opts == TableAuto)


{-| The body scrollbar's `scrollable` prop — upstream
`explicitlyScrollable || xScrollable`; `false` makes the internal
`NScrollbar` render the slot BARE (no wrapper, no rails, the fallthrough
class / style dropped).
-}
scrollableOf : Options row msg -> Bool
scrollableOf opts =
    explicitlyScrollableOf opts || xScrollableOf opts


{-| `headerInBody` (upstream `MainTable.tsx` render) — `maxHeight` unset
and no `flexHeight`: the header renders inside the body's single table;
otherwise it splits into the discrete header div.
-}
headerInBodyOf : Options row msg -> Bool
headerInBodyOf opts =
    opts.maxHeight == Nothing && not opts.flexHeight


layoutName : TableLayout -> String
layoutName layout =
    case layout of
        TableAuto ->
            "auto"

        TableFixed ->
            "fixed"


{-| `getNumberColWidth` (upstream `utils.ts` :20) — the numeric width of a
column for the fixed-offset walk: selection / expand columns default 40
(`SELECTION_COL_WIDTH` / `EXPAND_COL_WIDTH`) when unset, a group column
carries none (b6), an unset width is 0.
-}
numberColWidth : Column row msg -> Int
numberColWidth col =
    case col.kind of
        KindNormal ->
            Maybe.withDefault 0 col.width

        _ ->
            Maybe.withDefault 40 col.width


{-| `fixedColumnLeftMap` (upstream `use-scroll.ts` :64) — the left-fixed
columns in order, each keyed with its `start` offset (the summed widths
of the preceding left-fixed columns; group children flatten — the walk
is over the LEAF columns, so a nested `fixed` column found under a
group offsets like any other). Upstream also tracks `end` — only
`?.start` is ever read by the cell styles. Upstream's traverse registers
the fixed GROUP's own key too (its th takes the class + offset); the
port's leaf walk drops it, and upstream auto-fixes a fixed group's
children through map membership where the port reads the column's own
`fixed` — the documented group-fixed divergence.
-}
fixedColumnLeftMap : List (Column row msg) -> List ( String, Int )
fixedColumnLeftMap columns =
    let
        walk acc left cols =
            case cols of
                [] ->
                    List.reverse acc

                col :: rest ->
                    walk (( colKeyOf col, left ) :: acc) (left + numberColWidth col) rest
    in
    walk [] 0 (List.filter (\col -> col.fixed == Just FixedLeft) (leafColumns columns))


{-| `fixedColumnRightMap` (upstream `use-scroll.ts` :81) — the right-fixed
columns REVERSED, each keyed with its `start` offset (the summed widths
of the FOLLOWING right-fixed columns; the same leaf flatten as
`fixedColumnLeftMap`).
-}
fixedColumnRightMap : List (Column row msg) -> List ( String, Int )
fixedColumnRightMap columns =
    let
        walk acc right cols =
            case cols of
                [] ->
                    List.reverse acc

                col :: rest ->
                    walk (( colKeyOf col, right ) :: acc) (right + numberColWidth col) rest
    in
    walk [] 0 (List.reverse (List.filter (\col -> col.fixed == Just FixedRight) (leafColumns columns)))


{-| The map lookup — `fixedColumnLeftMap[colKey]?.start`, `Nothing` for
non-fixed columns (the dropped declaration).
-}
fixedOffsetOf : List ( String, Int ) -> String -> Maybe String
fixedOffsetOf map key =
    List.filter (\( k, _ ) -> k == key) map
        |> List.head
        |> Maybe.map (\( _, start ) -> String.fromInt start ++ "px")


{-| The body fallthrough style (`MainTable.tsx` :43) —
`{maxHeight: formatLength(maxHeight), minHeight: formatLength(minHeight)}`
in the no-space object form; `Nothing` when neither is set (the dropped
attribute).
-}
bodyStyleOf : Options row msg -> Maybe String
bodyStyleOf opts =
    stylePairs
        [ ( "max-height", Maybe.map pxfy opts.maxHeight )
        , ( "min-height", Maybe.map pxfy opts.minHeight )
        ]


{-| The scrollbar `contentStyle` (`Body.tsx` :538) —
`minWidth: formatLength(scrollX) || '100%'`, plus `width: '100%'` when
`scrollX` is set (authored-string spacing on this seam — the b1 pin byte).
-}
contentStyleOf : Options row msg -> String
contentStyleOf opts =
    case opts.scrollX of
        Just width ->
            "min-width: " ++ pxfy width ++ "; width: 100%"

        Nothing ->
            "min-width: 100%"


{-| The discrete header table's style (`Header.tsx` :459) —
`{minWidth: formatLength(scrollX), tableLayout: merged}` in the no-space
object form; `min-width` drops without `scrollX`.
-}
headerTableStyleOf : Options row msg -> Maybe String
headerTableStyleOf opts =
    stylePairs
        [ ( "min-width", Maybe.map pxfy opts.scrollX )
        , ( "table-layout", Just (layoutName (mergedTableLayoutOf opts)) )
        ]



-- HELPERS ----------------------------------------------------------------------


maybeClass : Maybe String -> List String
maybeClass maybe =
    case maybe of
        Just c ->
            [ c ]

        Nothing ->
            []


{-| `stylePart k (Just v)` is `Just "k:v"`; `Nothing` entries are dropped by
`List.filterMap`, matching Vue's style normalization (falsy/undefined
values render no declaration).
-}
stylePart : String -> Maybe String -> Maybe String
stylePart key maybeValue =
    Maybe.map (\value -> key ++ ":" ++ value) maybeValue


{-| The set declarations joined Vue-style (`k:v` with `;` separators, no
trailing semicolon), or `Nothing` when there is nothing to declare — an
empty style object renders no `style` attribute.
-}
stylePairs : List ( String, Maybe String ) -> Maybe String
stylePairs pairs =
    let
        parts =
            List.filterMap (\( k, mv ) -> stylePart k mv) pairs
    in
    if parts == [] then
        Nothing

    else
        Just (String.join ";" parts)


rawStyleAttr : Maybe String -> List (Html.Attribute msg)
rawStyleAttr maybeStyle =
    case maybeStyle of
        Just style ->
            [ HA.attribute "style" style ]

        Nothing ->
            []


orElse : Maybe a -> Maybe a -> Maybe a
orElse first second =
    case first of
        Just value ->
            Just value

        Nothing ->
            second


alignName : Align -> String
alignName align =
    case align of
        AlignLeft ->
            "left"

        AlignCenter ->
            "center"

        AlignRight ->
            "right"


pxfy : Int -> String
pxfy n =
    String.fromInt n ++ "px"



-- THEME ------------------------------------------------------------------------


{-| The root's inline `--n-*` set — upstream `cssVarsRef` (`DataTable.tsx`),
byte-for-byte declaration order. The three size-keyed vars resolve through
`createKey('fontSize'|'thPadding'|'tdPadding', mergedSize)`; everything
else reads the theme module directly (the composite colours are baked
literals there). The filter-menu-only `--n-action-*` vars are not on the
root upstream either.
-}
cssVars : Theme -> Size -> List ( String, String )
cssVars theme size =
    let
        v =
            DataTableTheme.vars theme
    in
    [ ( "--n-font-size", keyed .fontSizeSmall .fontSizeMedium .fontSizeLarge v size )
    , ( "--n-th-padding", keyed .thPaddingSmall .thPaddingMedium .thPaddingLarge v size )
    , ( "--n-td-padding", keyed .tdPaddingSmall .tdPaddingMedium .tdPaddingLarge v size )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-border-color-modal", v.borderColorModal )
    , ( "--n-border-color-popover", v.borderColorPopover )
    , ( "--n-th-color", v.thColor )
    , ( "--n-th-color-hover", v.thColorHover )
    , ( "--n-th-color-modal", v.thColorModal )
    , ( "--n-th-color-hover-modal", v.thColorHoverModal )
    , ( "--n-th-color-popover", v.thColorPopover )
    , ( "--n-th-color-hover-popover", v.thColorHoverPopover )
    , ( "--n-td-color", v.tdColor )
    , ( "--n-td-color-hover", v.tdColorHover )
    , ( "--n-td-color-modal", v.tdColorModal )
    , ( "--n-td-color-hover-modal", v.tdColorHoverModal )
    , ( "--n-td-color-popover", v.tdColorPopover )
    , ( "--n-td-color-hover-popover", v.tdColorHoverPopover )
    , ( "--n-th-text-color", v.thTextColor )
    , ( "--n-td-text-color", v.tdTextColor )
    , ( "--n-th-font-weight", v.thFontWeight )
    , ( "--n-th-button-color-hover", v.thButtonColorHover )
    , ( "--n-th-icon-color", v.thIconColor )
    , ( "--n-th-icon-color-active", v.thIconColorActive )
    , ( "--n-filter-size", v.filterSize )
    , ( "--n-pagination-margin", v.paginationMargin )
    , ( "--n-empty-padding", v.emptyPadding )
    , ( "--n-box-shadow-before", v.boxShadowBefore )
    , ( "--n-box-shadow-after", v.boxShadowAfter )
    , ( "--n-sorter-size", v.sorterSize )
    , ( "--n-resizable-container-size", v.resizableContainerSize )
    , ( "--n-resizable-size", v.resizableSize )
    , ( "--n-loading-size", v.loadingSize )
    , ( "--n-loading-color", v.loadingColor )
    , ( "--n-opacity-loading", v.opacityLoading )
    , ( "--n-td-color-striped", v.tdColorStriped )
    , ( "--n-td-color-striped-modal", v.tdColorStripedModal )
    , ( "--n-td-color-striped-popover", v.tdColorStripedPopover )
    , ( "--n-td-color-sorting", v.tdColorSorting )
    , ( "--n-td-color-sorting-modal", v.tdColorSortingModal )
    , ( "--n-td-color-sorting-popover", v.tdColorSortingPopover )
    , ( "--n-th-color-sorting", v.thColorSorting )
    , ( "--n-th-color-sorting-modal", v.thColorSortingModal )
    , ( "--n-th-color-sorting-popover", v.thColorSortingPopover )
    ]


keyed :
    (DataTableTheme.Vars -> String)
    -> (DataTableTheme.Vars -> String)
    -> (DataTableTheme.Vars -> String)
    -> DataTableTheme.Vars
    -> Size
    -> String
keyed small medium large v size =
    case size of
        Small ->
            small v

        Medium ->
            medium v

        Large ->
            large v
