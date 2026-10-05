# B2 wiring recon — repo touchpoints (in-context, orchestrator; explorer lane burned on repeat-call guard)

## Verdict: batch-2 prep = NO-OP
`css/naive-ui.css` already carries every batch-2 selector (batch-1 prep extracted the whole
component cssr): `n-data-table-sorter` (+`--asc`/`--desc` icon rotations + active color) at
~7763-7782, th `--sorting`/`--sortable` (+`__ellipsis` shrink + hover) at ~7755-7761, td
`--sorting` at ~7855, `n-data-table__pagination` (margin/flex/flex-end) at ~7910, RTL
variants ~8027-8030. No new root class → `tools/verify/check-dom.mjs` target untouched
(`'.n-data-table': true` at :148). Theme: the 47-var set already includes `--n-sorter-size`
and `--n-pagination-margin` (see `cssVars` in DataTable.elm). Document the no-op in the feat
commit message (dialog-service precedent).

## NUI.Pagination (src/NUI/Pagination.elm, 927 L) — API needed for wiring
- `view : Theme -> Options msg -> List (Element msg) -> Element msg` — the children arg IS
  the prefix slot (`n-pagination-prefix`, rendered only when non-empty).
- `Options msg`: `currentPage:Int, itemCount:Maybe Int, pageCount:Maybe Int, pageSize:Maybe Int,
  pageSlot:Int(9), pageSizes:[PageSizeNumber 10], showQuickJumper:False, showQuickJumpDropdown:True,
  disabled:False, simple:False, size:Medium (NUI.Types.Size), rtl:False, jumperValue:"",
  onJumperInput:Nothing, suffix:Nothing, onUpdatePage:Nothing, onUpdatePageSize:Nothing,
  attributes:[]`. `PageSizeOption = PageSizeNumber Int | PageSizeOption {label,value}`
  (entries drive `getDefaultPageSize`; **size picker omitted** — NSelect unported, documented gap).
- `getDefaultPageSize : { defaultPageSize : Maybe Int, pageSizes : List PageSizeOption } -> Int`
  (Just defaultPageSize → it; else first pageSizes number/value; else 10) — ported behavior-
  for-behavior; data-table's merged page size = caller `pageSize ?? getDefaultPageSize {Nothing, pageSizes}`.
- `pageCount` / `pageItems` pure helpers exposed. `itemCount` has priority over `pageCount`.
- **No `defaultPage`/`defaultPageSize` fields** (caller-owned state house pattern) — the
  data-table divergence note: upstream honors `pagination.defaultPage/defaultPageSize` seeds;
  Elm callers seed their model and pass `currentPage`/`pageSize` explicitly.

## NUI.DataTable (src/NUI/DataTable.elm, 709 L) — batch-1 shape
- Exposes: `Align(..), Column, Options, Size(..), columnDefaults, cssVars, defaults, view`.
- Section banners: `-- VIEW` (after defaults), `-- HELPERS`, `-- THEME`.
- `Column row msg`: key/title/view/align/titleAlign/width/minWidth/maxWidth/className.
- `Options row msg`: columns/data/rowKey/size/bordered/bottomBordered/singleLine/singleColumn/
  striped/rowClassName/rowAttributes/showHeader/rtl/attributes.
- Render chain: `view` → root column (rootClasses + cssVars) → wrapper el → base-table el →
  `scrollbarNode` (NUI.Scrollbar w/ `extraClasses ["n-data-table-base-table-body"]`,
  `contentStyle "min-width: 100%"`) → `tableNode` (colgroup + theadNode + tbodyNode);
  empty el sibling after table when `opts.data == []` (**batch-2: switch to paginatedData**).
- `thNode (col, isLast)` / `tdNode opts rowIndex row (col, isLastCol)` class orders per
  batch-1 (base/--last/className for th; base/className/align/--last-col/--last-row for td)
  — batch-2 inserts per upstream arrays (see b2-upstream §B).
- Helpers in place to reuse: `lastFlags`, `maybeClass`, `stylePart`, `stylePairs`,
  `rawStyleAttr`, `orElse`, `alignName`, `pxfy`, `embedChild`.
- `isLastRow` computed from `List.length opts.data` inside tdNode — **must become paginated length**.

## Icon house pattern
Per-component SVG bytes inside `Html.i [HA.class "n-base-icon"]` (Alert.elm:321-330,
BackTop.elm:129-133 precedents). ArrowDown SVG source bytes captured from the full checkout
`src/_internal/icons/ArrowDown.tsx`: `svg viewBox="0 0 28 28" version="1.1"
xmlns="http://www.w3.org/2000/svg"` > `g stroke="none" stroke-width="1" fill-rule="evenodd"`
> `g fill-rule="nonzero"` > path `d="M23.7916,15.2664 C24.0788,14.9679 24.0696,14.4931
23.7711,14.206 C23.4726,13.9188 22.9978,13.928 22.7106,14.2265 L14.7511,22.5007
L14.7511,3.74792 C14.7511,3.33371 14.4153,2.99792 14.0011,2.99792 C13.5869,2.99792
13.2511,3.33371 13.2511,3.74793 L13.2511,22.4998 L5.29259,14.2265 C5.00543,13.928
4.53064,13.9188 4.23213,14.206 C3.93361,14.4931 3.9244,14.9679 4.21157,15.2664
L13.2809,24.6944 C13.6743,25.1034 14.3289,25.1034 14.7223,24.6944 L23.7916,15.2664 Z"`.

## Anchors (line numbers as of 5674b23)
- examples/src/Main.elm (4661 L): `dataTableSection` at **4506** (uses `dtD`/`colD` locals,
  `person name age address` fixtures, nameCol/ageCol/addressCol); `paginationSection` at 973
  (`Pagination.view theme { pgD | ... } []` pattern); sections static (`Element msg`, no Msg).
- tests/src/Main.elm (11081 L): DtRow fixtures at **4732** (John Brown/Jim Green/Joe Black —
  the upstream spec rows), `dtNameCol` at ~4757; data-table eq pins at **9140-9169** (tail of
  `checks`, before `]` + `-- VIEW`); live wrappers `live-data-table-*` at **11062-11077**.
- tests/inspect.mjs (9301 L): dt helpers at **9134-9140** (`dtRoot/dtTable/dtThs/dtTrs/dtTds/
  dtScrollbar`), probe block **9145+** (before `// --- report`).
- tests/inspect.mjs quirks that apply: `nClassesStr` filters to n-* (order pins);
  `fullClasses` for `.pop()` phase probes only.

## Design decisions locked (from upstream bytes)
- `SortOrder = Ascend | Descend | NoSort`; `Sorter row` variants map `'default'`/fn/
  `{multiple,compare?}`/`true`; `SortState row = {columnKey, order, sorter}`.
- `deriveNextSorter` bases on the MERGED list (use-sorter.ts:180), result stored uncontrolled.
- Options gains: `sortStates`, `onSorterChange (List SortState -> msg)`, `remote`,
  `paginateSinglePage (True)`, `pagination : Maybe (NUI.Pagination.Options msg)`,
  `paginationPrefix : List (Element msg)` (upstream prefix is a pagination-object render-prop;
  Elm's Pagination models prefix as view children → separate field), `onUpdatePage`,
  `onUpdatePageSize` (single handler channel — upstream fires pagination-object + table-level
  + deprecated channels; document).
- Column gains: `sorter : Maybe (Sorter row)`, `defaultSortOrder : SortOrder (NoSort)`,
  `sortOrder : Maybe SortOrder` (Just = controlled marker).
- th onClick attached iff sortable && onSorterChange set (upstream attaches for all basic
  columns and no-ops; listener presence is not a DOM byte).
- `renderSorter`/`renderSorterIcon`/`customNextSortOrder` not modelled (render-prop
  customization) — accepted-edge docstring.
- Default-sorter null/number/string triage via `SortValue = SortNumber Float | SortString
  String | SortNull` accessor (`row[columnKey]` realization); `String.compare` (ordinal)
  stands in for `localeCompare` — accepted-edge note (Elm has no ICU).
- Pipeline: `filteredData` = identity alias (batch-5 seam), `sortedData`, `paginatedData`,
  `boundedPage`, `mergedPageSize`, `mergedItemCount`, `showPagination`, `mergedPagination`
  all pure + exposed for eq pins.
