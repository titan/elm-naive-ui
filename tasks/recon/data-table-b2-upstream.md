# B2 upstream recon — SORT + PAGINATION (explorer session-1790425292284212-33, verbatim)

Sources read once each, in order: `interface.ts`, `use-sorter.ts`, `use-table-data.ts`, `SortButton.tsx`, `RenderSorter.ts`, `Header.tsx`, `Body.tsx`, `DataTable.tsx`, `styles/index.cssr.ts`, `tests/DataTable.spec.tsx` + exception read `src/utils.ts` (essential: `createNextSorter`, `getFlagOfOrder`, `isColumnSortable/Soring`). All paths under `/tmp/next-upstream/data-table/`.

## A. Sort state model

### Types (`src/interface.ts`)
- `SortOrder = 'ascend' | 'descend' | false` (comment: "for compat may add null").
- `SortOrderFlag = 1 | -1 | 0`.
- `CompareFn<T> = (row1: T, row2: T) => number`.
- `Sorter<T> = CompareFn<T> | SorterMultiple<T>` where `SorterMultiple<T> = { multiple: number; compare?: CompareFn<T> | 'default' }`.
- Column field: `sorter?: boolean | Sorter<T> | 'default'` on `TableBaseColumn`.
- Also on column: `defaultSortOrder?: SortOrder`, `sortOrder?: SortOrder` (controlled), `customNextSortOrder?: (order: SortOrder) => SortOrder`, `renderSorter?: RenderSorter`, `renderSorterIcon?: RenderSorterIcon` where `RenderSorter = (props: { order: SortOrder }) => VNodeChild`.
- `SortState = { columnKey: ColumnKey; order: SortOrder; sorter: Sorter | boolean | 'default' }`. Comment semantics: `Sorter` => sync data + functional sorter; `'default'` => sync data + default sorter; `true` => async data; `false` => show nothing.
- `OnUpdateSorter = (sortState: SortState & SortState[] & null) => void` ("`null` only occurs when clearSorter is called").

### Default sorter fn (`src/use-sorter.ts` `getDefaultSorterFn(columnKey)`)
Returns `(row1, row2)` comparing `row[columnKey]`:
1. `value1 == null`: `value2 == null ? 0 : -1`.
2. `value2 == null`: `1`.
3. both `number`: `value1 - value2`.
4. both `string`: `value1.localeCompare(value2)`.
5. else `0`.

### `getSortFunction(sorter, columnKey)` resolution
- `sorter === undefined | 'default' | ({compare:'default'})` (and `columnKey` truthy) → `getDefaultSorterFn(columnKey)`.
- `typeof sorter === 'function'` → that fn.
- object with `compare` fn (≠'default') → `sorter.compare`.
- else → `false` (no compare; sorter state still tracked but inert in sorting).

### Multiple priority (`getMultiplePriority`)
- `typeof sorter === 'object' && typeof sorter.multiple === 'number'` → `sorter.multiple`; else `false`.

### Multi-column priority computation (`sortedDataRef`)
- `activeSorters = mergedSortState.slice().sort((a,b) => (getMultiplePriority(b.sorter)||0) - (getMultiplePriority(a.sorter)||0))` — higher `multiple` number first (descending priority).
- Sort over `filteredDataRef.slice()` with `some()`: first sorter state with `compareFn && order` producing non-zero wins; result `* getFlagOfOrder(order)` (`'ascend'→1`, `'descend'→-1`, else `0`).
- No active sorters → returns `filteredDataRef.value` unchanged.

### Merged sort state (`mergedSortStateRef`, use-sorter.ts)
- Controlled detection: columns with `type !== 'selection' && sorter !== undefined && (sortOrder === 'ascend' | 'descend' | false)`.
- If any controlled column has `sortOrder !== false` → state = those columns mapped to `{columnKey, order: column.sortOrder, sorter: column.sorter}` (in column order).
- Else if ANY column is in controlled mode (even all `false`) → `[]` (uncontrolled ignored).
- Else uncontrolled: `uncontrolledSortStateRef` (array → as-is; single → `[x]`; null → `[]`).
- Initialization: for each `dataRelatedCols` with `sorter !== undefined`, push `{columnKey, sorter, order: column.defaultSortOrder ?? false}` into `defaultSortState` (via `updateSortStatesByNewSortState`: replace by `columnKey` if present else push).

### Click-cycle logic
- **Not in SortButton** — SortButton is display-only. Clicks go through `Header.tsx` `handleColHeaderClick(e, column)`:
  - early-return if `happensIn(e, 'dataTableFilter')` or `happensIn(e, 'dataTableResizable')`;
  - `if (!isColumnSortable(column)) return` (`isColumnSortable`: `'children' in column → false; return !!column.sorter`);
  - `activeSorter = mergedSortStateRef.find(state => state.columnKey === column.key) || null`;
  - `nextSorter = createNextSorter(column, activeSorter)` → `deriveNextSorter(nextSorter)`.
- `createNextSorter(column, currentSortState)` (`src/utils.ts`):
  - `column.sorter === undefined` → `null`.
  - `currentSortState === null || columnKey mismatch` → `{ columnKey, sorter: column.sorter, order: getNextOrderOf(false) }`.
  - else → `{ ...currentSortState, order: (customNextSortOrder || getNextOrderOf)(currentSortState.order) }`.
- `getNextOrderOf(order)`: `!order → 'descend'`; `'descend' → 'ascend'`; else (`'ascend'`) → `false`. **So first click = `'descend'`** (from `getNextOrderOf(false)`), cycle: `false → descend → ascend → false`.
- `deriveNextSorter` → `getUpdatedSorterState` (**confirmed bytes, use-sorter.ts:178-198**: `currentSortState = mergedSortStateRef.value.slice()` — the MERGED list is the base, not the uncontrolled ref):
  - if new state has multiple priority ≠ false: keep only multi-sorter states in `currentSortState`, upsert new one (`updateSortStatesByNewSortState` — findIndex by columnKey, replace if ≥0 else push), return array.
  - single sorter → return just that state (replaces whole state).
  - `null` → `null`.
- `doUpdateSorter` calls, in order: `props['onUpdate:sorter']`, `props.onUpdateSorter`, `props.onSorterChange` (deprecated), then sets `uncontrolledSortStateRef.value = sortState`.
- API `sort(columnKey, order = 'ascend')`: empty key → `clearSorter()`; finds non-selection/expand column by key, requires `columnToSort?.sorter`, then `deriveNextSorter({columnKey, sorter, order})`. `clearSorter()` → `doUpdateSorter(null)`.

## B. Sort DOM bytes

### SortButton (`HeaderButton/SortButton.tsx`, name `'SortIcon'`) — full template confirmed
- `sortStateRef = mergedSortState.find(state => state.columnKey === column.key)`; `active = sortState !== undefined`; `mergedSortOrder = active ? sortState.order : false`.
- `mergedRenderSorter = mergedComponentPropsRef?.value?.DataTable?.renderSorter || column.renderSorter`.
- If `mergedRenderSorter` → `<RenderSorter render={...} order={mergedSortOrder} />` (replaces the WHOLE span — no n-data-table-sorter classes).
- Else template:
```
<span class={[`${cls}-data-table-sorter`,
  mergedSortOrder === 'ascend' && `${cls}-data-table-sorter--asc`,
  mergedSortOrder === 'descend' && `${cls}-data-table-sorter--desc`]}>
  {renderSorterIcon ? renderSorterIcon({order}) : <NBaseIcon clsPrefix={cls}><ArrowDownIcon/></NBaseIcon>}
</span>
```
- Class bytes: `n-data-table-sorter`, `n-data-table-sorter--asc`, `n-data-table-sorter--desc` (falsy entries dropped by Vue class array). Icon: `NBaseIcon` wrapping `ArrowDownIcon` (renders `n-base-icon`). No aria/title attrs anywhere in sorter DOM.
- Placement: inside `div.n-data-table-th__title-wrapper`, AFTER the title div: `{isColumnSortable(column) ? <SortButton column={column}/> : null}` (Header.tsx:271-273).

### th classes (`TableParts/Header.tsx` renderRow, class array confirmed :326-347)
```
class={[ `${cls}-data-table-th`,
  (leftFixed||rightFixed) && `--fixed-{left|right}`,        // batch 4
  { [`${cls}-data-table-th--sorting`]:   isColumnSorting(column, mergedSortState),
    [`${cls}-data-table-th--filterable`]: isColumnFilterable(column),   // batch 5
    [`${cls}-data-table-th--sortable`]:  isColumnSortable(column),
    [`${cls}-data-table-th--selection`]: column.type==='selection',     // batch 3
    [`${cls}-data-table-th--last`]:      isLast },
  column.className ]}
```
→ batch-2 th order: base → `--sorting` → `--sortable` → `--last` → className.
- `isColumnSorting(column, mergedSortState)` = `mergedSortState.find(state => state.columnKey === column.key && state.order) !== undefined` (truthy order only).
- Attrs order: `style`, `colspan`, `rowspan`, `data-col-key`, `class`, then `onClick` (attached when `type!=='selection' && type!=='expand' && !('children' in column)`; handler itself no-ops unless sortable).

### td `--sorting` (`TableParts/Body.tsx` :907-929, class array confirmed)
```
class={[ `${cls}-data-table-td`, column.className, resolvedCellProps?.class,
  isSummary && `--summary`,                                  // batch 6
  hoverKey !== null && cord...includes(hoverKey) && `--hover`,  // runtime
  isColumnSorting(column, mergedSortState) && `${cls}-data-table-td--sorting`,
  column.fixed && `--fixed-${fixed}`,                        // batch 4
  column.align && `${cls}-data-table-td--${align}-align`,
  type==='selection' && `--selection`,                       // batch 3
  type==='expand' && `--expand`,                             // batch 3
  isLastCol && `--last-col`, isLastRow && `--last-row` ]}
```
→ batch-2 td order: base → className → `--sorting` → `--{align}-align` → `--last-col` → `--last-row`. Applies to **every row's td of the actively sorted column(s)** (whole-column highlight).

## C. Pagination

### Tree placement (`DataTable.tsx` render, confirmed :500-523)
Root `div.n-data-table` children in order:
1. `div.n-data-table-wrapper` > `<MainTable/>`
2. `{mergedShowPagination ? <div class="n-data-table__pagination"><NPagination theme disabled={this.loading} {...mergedPagination}/></div> : null}` — the wrapper div carries ONLY the class (no attrs/style); `disabled={loading}` sits BEFORE the spread → a caller `disabled` key in the pagination object wins; with no `loading` prop the caller's flows.
3. `Transition fade-in-scale-up` > loading wrapper (batch 4).
- **No slot forwarding**: the `<NPagination>` usage passes no slots; a prefix reaches it as a PROP on the pagination object (naive-ui Pagination accepts `prefix` as a render-prop).

### `mergedShowPaginationRef` (confirmed :454-466)
- `!props.pagination` → `false` (pagination prop `[Object, Boolean]`, default `false`).
- `props.paginateSinglePage` (default `true`) → `true`.
- else read `mergedPagination`: `pageCount !== undefined → pageCount > 1`; else `itemCount && pageSize && itemCount > pageSize` (truthy short-circuit — itemCount 0 → false).

### `mergedPaginationRef` (use-table-data.ts:303-331)
Spread `...props.pagination` first, then overrides:
- Deprecated reset: `onChange/onUpdatePage/onUpdatePageSize/onPageSizeChange → undefined`.
- `'onUpdate:page': mergedOnUpdatePage`, `'onUpdate:pageSize': mergedOnUpdatePageSize` (each calls the pagination object's own handler, then table-level, then sets uncontrolled refs).
- `page: boundedMergedCurrentPageRef.value`
- `pageSize: mergedPageSizeRef.value`
- `pageCount: mergedItemCountRef === undefined ? mergedPageCountRef : undefined`
- `itemCount: mergedItemCountRef.value`
- Everything else from `props.pagination` passes through (`pageSizes`, `prefix`, …).

### Page/pageSize defaults + clamp (use-table-data.ts:89, 228-252, confirmed)
- Uncontrolled page: `ref(pagination ? pagination.defaultPage || 1 : 1)`.
- Uncontrolled pageSize: `ref(getDefaultPageSize(pagination))`.
- Merged via vooks `useMergedState(controlledRef, uncontrolledRef)`.
- **Clamp** `boundedMergedCurrentPageRef`: `props.remote ? page : Math.max(1, Math.min(Math.ceil(filteredDataRef.length / mergedPageSizeRef.value), page))`.
- `mergedPageCountRef`: `pagination.pageCount` if defined else undefined.
- `mergedItemCountRef`: remote → `pagination.itemCount` (may be undefined); local → `filteredDataRef.value.length`.
- `getDefaultPageSize` bytes (sourced from the full checkout `src/pagination/src/utils.ts`): `!paginationProps → 10`; `defaultPageSize !== undefined → defaultPageSize`; else `pageSizes?.[0]` (number → it; else `pageSizeOption?.value || 10`).

### Local vs remote
- `paginatedDataRef`: `remote` → `treeMateRef.treeNodes` (raw); `!pagination` → `sortedDataRef`; else `sortedData.slice((boundedPage-1)*pageSize, +pageSize)`.

## D. Pipeline
- `treeMateRef` → `filteredDataRef` (filter; identity placeholder until batch 5) → `sortedDataRef` → `paginatedDataRef`.
- Empty: `mergedEmptyRef = paginatedDataRef.length === 0` → root `--empty`; Body's `emptyRef` same; post-PAGINATION length drives it.

## E. CSS (styles/index.cssr.ts)
- Sorter block: `cB('data-table-sorter')` — height/width `var(--n-sorter-size)`, `margin-left: 4px`, relative, inline-flex, center, `vertical-align: -0.2em`, `color: var(--n-th-icon-color)`, `transition: color .3s var(--n-bezier)`; `cB('base-icon')` `transition: transform .3s var(--n-bezier)`; `cM('desc')` → icon `rotate(0deg)`; `cM('asc')` → icon `rotate(-180deg)`; `cM('asc, desc')` → `color: var(--n-th-icon-color-active)`.
- th: `cM('sorting')` bg `var(--n-merged-th-color-sorting)`; `cM('sortable')` cursor pointer + `cE('ellipsis')` `max-width: calc(100% - 18px)` + `&:hover` bg `var(--n-merged-th-color-hover)`.
- td: `cM('sorting')` bg `var(--n-merged-td-color-sorting)`.
- `cE('pagination')`: `margin: var(--n-pagination-margin); display: flex; justify-content: flex-end;`.
- **All these selectors already live in `css/naive-ui.css` (lines ~7703-7910 + RTL ~8027-8030) — batch-2 prep is a NO-OP.**

## F. Spec blocks (sorter + pagination only) — tests/DataTable.spec.tsx
1. **`should work with 'itemCount' without 'remote'`** — 978 rows, `pagination={page:1, pageCount:1, pageSize:10, itemCount:0, prefix}`. Asserts `.n-pagination-prefix` text `'978'` (local itemCount = filtered length overrides provided `itemCount: 0`).
2. **`should work with 'itemCount' with 'remote'`** — `remote`, `itemCount: 978`, click `.n-pagination-item)[2]` → `onUpdatePage` called; `.n-pagination-prefix` still `'978'`.
3. **`getFilteredAndSortedData and getCurrentPageData`** (pagination `{pageSize: 1}`): filter→sorted 2 rows/page 1 row; + `sort('age','descend')` orders.
4. **`should work with multiple sorter`** — columns: `age` (fn), `chinese` (`{compare,multiple:3}`, `defaultSortOrder:false`), `math` (`multiple:2`... compare), `english` (`multiple:1`), `address` (filter). Data: John Brown(32,NY,98/60/70), Jim Green(42,London,98/66/89), Joe Black(32,Sidney,98/66/89), Jim Red(32,London,88/99/89). Sequential clicks on `#chinese-title`/`#math-title`/`#english-title`/`#age-title`; expected per-column value arrays:
   - `c:d m:f e:f` → chinese `[98,98,98,88]`, math `[60,66,66,99]`, english `[70,89,89,89]`
   - `c:d m:d e:f` → `[98,98,98,88]/[66,66,60,99]/[70,89,89,89]`
   - `c:d m:d e:d` → `[98,98,98,88]/[66,66,60,99]/[89,89,70,89]` — *recon's raw note also lists `[89,89,89,70]` for the e:d step; re-derive from bytes at pin time*
   - `c:a m:d e:d` → `[88,98,98,98]/[99,66,66,60]/[89,89,89,70]`
   - `c:f m:d e:d` → same arrays as previous
   - `c:f m:a e:d` → `[98,98,98,88]/[60,66,66,99]/[70,89,89,89]`
   - `c:f m:f e:d` → `[98,98,98,88]/[66,66,99,60]/[89,89,89,70]`
   - `c:d m:f e:d` → `[98,98,98,88]/[66,60,66,99]/[89,70,89,89]`
   - `filter: Sidney+New York` → chinese `[98,98]`, math `[66,60]`, english `[89,70]`; `filter(null)`
   - `age:d` → `.age-col` `[42,32,32,32]` + chinese `[98,98,98,88]`, math `[66,60,66,99]`, english `[89,70,89,89]`
   (First click on a column = `descend`, second = `ascend`, third = `false`.)
5. **`props.columns > has correct type`** — `sorter` fn + `defaultSortOrder: 'ascend'`; mount-only.

## Porting notes / gaps
- `getDefaultPageSize` bytes sourced (see §C). Everything else quoted from source.
- First-click default `'descend'` from `createNextSorter` → `getNextOrderOf(false)`; overridable via `customNextSortOrder` (not ported — render/behavior-prop customization).
- Multi-sort click keeps only other multi-priority states and upserts; single-sorter click replaces the whole state.
