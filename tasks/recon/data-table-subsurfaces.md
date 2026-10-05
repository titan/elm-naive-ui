# naive-ui data-table SUB-SURFACES recon (v2.45.3)

Recon by explorer session-1790390059115184-25, persisted verbatim by orchestrator.
Sources: `/tmp/next-upstream/data-table/`.

## 1. SELECTION
- **Mechanism:** `use-check.ts` derives checked/indeterminate key sets from a `treemate` `getCheckedKeys(sourceKeys, {cascade, allowNotLoaded})` call over `treeMateRef`, with a controlled/uncontrolled merge (`checkedRowKeys` prop vs `uncontrolledCheckedRowKeysRef`). Single mode (`selectionColumn.multiple === false`) short-circuits to `sourceKeys.slice(0,1)` + empty indeterminate set (use-check.ts:27-31). Header "some/all" state is computed only over the **current page**: `countOfCurrentPageCheckedRowsRef` / `countOfCurrentPageDisabledRowsRef` → `someRowsCheckedRef` (checked>0 && checked < len-disabled, OR any indeterminate row) and `allRowsCheckedRef` (checked>0 && checked == len-disabled) (use-check.ts:57-84). `doCheckAll/doUncheckAll` iterate `paginatedDataRef` (or all `treeNodes` when `checkWholeTable=true` from the selection menu) and always cascade. `doCheck/doUncheck/doUpdateCheckedRowKeys` are gated on `props.loading`.
- **Components:** `NCheckbox` (BodyCheckbox.tsx:5, Header.tsx:14 — header uses `privateInsideTable`), `NRadio` (BodyRadio.tsx:5, shared `name={componentId}` for radio group semantics), `NDropdown` + `NBaseIcon` + `ChevronDownIcon` (SelectionMenu.tsx:4-6).
- **DOM:**
  - Header selection th: `NCheckbox` + optional `<SelectionMenu>` inside the th (Header.tsx:236-246); SelectionMenu renders `NBaseIcon` with class `n-data-table-check-extra` wrapping `ChevronDownIcon` (SelectionMenu.tsx:129-138).
  - Body cell: `RenderSafeCheckbox`/`RenderSafeRadio` mounted inside `td` when `column.type === 'selection'` and not a summary row (Body.tsx:959-998).
  - th gets `n-data-table-th--selection` (Header.tsx:338); td gets `n-data-table-td--selection` (Body.tsx:921).
- **Props/state:** `checkedRowKeys`/`defaultCheckedRowKeys`, `cascade`, `allowCheckingNotLoaded`, `onUpdate:checkedRowKeys`/`onCheckedRowKeysChange`, column `options` (selection menu items: `'all' | 'none' | {label,key,onSelect}`), `multiple` on column, `loading` gate. Note: **no `max-count` dropdown exists** — SelectionMenu options come from `selectionColumn.options` only (DataTable.tsx:281-284).
- **Runtime vs renderable:** key sets and some/all are pure computed (renderable); check/uncheck emits + `loading` gate are runtime behavior.

## 2. EXPAND
- **Mechanism:** `use-expand.ts` finds the `type === 'expand'` column, reads `renderExpand`/`expandable`, and merges `expandedRowKeys` (controlled) with `uncontrolledExpandedRowKeysRef` via `useMergedState`; `defaultExpandAll` seeds either all expandable rows or `getNonLeafKeys()`. `stickyExpandedRows` is a separate toRef. Body tiles an extra `isExpandedRow` row-info entry after each expanded parent (Body.tsx:687-705, key `${rowInfo.key}-expand`), and `handleUpdateExpanded` toggles keys (Body.tsx:292-305).
- **Components:** `NBaseIcon`, `NBaseLoading`, `NIconSwitchTransition`, `ChevronRightIcon` (ExpandTrigger.tsx:4-6).
- **DOM:**
  - `ExpandTrigger` renders `<div class="n-data-table-expand-trigger [n-data-table-expand-trigger--expanded]">` inside the expand-type `td` (Body.tsx:946, ExpandTrigger.tsx:37-44). A second trigger is rendered for the expanded content row when `renderExpand` exists (Body.tsx:991).
  - Expanded row: `<tr class="n-data-table-tr n-data-table-tr--expanded">` with a single `<td colspan={colCount}>` (Body.tsx:759-769); parent tr also gets `n-data-table-tr--expanded` (Body.tsx:1045).
  - `stickyExpandedRows` wraps content in `<div class="n-data-table-expand" style="width:<bodyWidth>px">` (Body.tsx:771-779).
  - td gets `n-data-table-td--expand` (Body.tsx:923).
- **Props/state:** `expandedRowKeys`/`defaultExpandedRowKeys`/`defaultExpandAll`, `onUpdate:expandedRowKeys`, column `renderExpand` (required, dev-warned), `expandable`, `renderExpandIcon`, `stickyExpandedRows`, `loadingKeySet` (per-row async expand loading → `NBaseLoading` inside trigger).
- **Runtime vs renderable:** state is renderable; the icon swap is `NIconSwitchTransition` + cssr `cM('expanded')` rotate(90deg) (index.cssr.ts:156-166) — **no collapse/height transition on the expanded row itself**; rows just appear.

## 3. SORT
- **Mechanism:** `use-sorter.ts` keeps `SortState | SortState[] | null` (`{columnKey, sorter, order: 'ascend'|'descend'|false}`). Controlled mode activates if any column sets `sortOrder` to `'ascend'|'descend'|false`; multiple-sort columns are keyed by `sorter.multiple` (number priority) and sorted by descending priority before applying compare fns (use-sorter.ts:126-148). `createNextSorter` (utils.ts:164) cycles the order; `getFlagOfOrder` maps ascend→1, descend→-1 (utils.ts:66-72). Default sorter fn handles null/number/string.
- **Components:** `NBaseIcon` + `ArrowDownIcon` (SortButton.tsx:6-7), `RenderSorter` (pure render-prop wrapper, RenderSorter.ts). `useConfig` for `renderSorter` global override.
- **DOM (th):**
  - Sort button: `<span class="n-data-table-sorter [n-data-table-sorter--asc|--desc]">` appended after the title inside `n-data-table-th__title-wrapper` (Header.tsx:273, SortButton.tsx:76-84).
  - Active th class: `n-data-table-th--sorting` via `isColumnSorting` (Header.tsx:330); also `--sortable` (Header.tsx:336). Body td gets `n-data-table-td--sorting` (Body.tsx:915).
- **Props/state:** column `sorter` (fn | `'default'` | `{compare, multiple}`), `defaultSortOrder`, `sortOrder` (controlled), `renderSorter`, `renderSorterIcon`, `customNextSortOrder`, `onUpdate:sorter`/`onSorterChange`, imperative `sort()`/`clearSorter()`.
- **Runtime vs renderable:** sorting the array is computed; click→`deriveNextSorter` is interaction. cssr: `--sorting` bg (index.cssr.ts:278, 415), `--sortable` cursor+ellipsis shrink (281-289), sorter icon rotation `cM('desc'|'asc'|'asc, desc')` (304-317).

## 4. FILTER
- **Mechanism:** `FilterButton` wraps everything in an **`NPopover`** (trigger=click, placement=bottom, `style={{padding:0}}`, plus user `filterIconPopoverProps`) — not NDropdown (FilterButton.tsx:129-141). Trigger slot: custom `RenderFilter` (if `renderFilter` provided) or `<div class="n-data-table-filter [n-data-table-filter--active][n-data-table-filter--show]" data-data-table-filter>` with `FilterIcon`/`renderFilterIcon`. Default slot: `renderFilterMenu` or `NDataTableFilterMenu`. Menu edits a `temporalValueRef`, commits on Confirm, resets on Clear; `paginationBehaviorOnFilter==='first'` resets page to 1 (FilterButton.tsx:95-99).
- **Components:** `NPopover` (FilterButton.tsx:10), `NScrollbar`, `NButton` ×2 (clear/confirm), `NCheckboxGroup`+`NCheckbox`, `NRadioGroup`+`NRadio` (FilterMenu.tsx:6-11), `NBaseIcon`+`FilterIcon`.
- **DOM:**
  - th: `<div class="n-data-table-filter ...">` absolutely positioned right (Header.tsx:277-281; cssr index.cssr.ts:349-356).
  - Popover content: `<div class="n-data-table-filter-menu [n-data-table-filter-menu--rtl]">` → `NScrollbar` → `n-data-table-filter-menu__group` (checkbox/radio group) → `n-data-table-filter-menu__action` with two `NButton`s (FilterMenu.tsx:145-213).
  - th classes: `n-data-table-th--filterable` (Header.tsx:334), active-filter visual via `--active` on the filter div (cssr 372-375).
- **Props/state:** column `filter` (fn|'default'), `filterOptions`, `filterMultiple`, `filterOptionValue(s)`/`defaultFilterOptionValue(s)` (controlled/uncontrolled merge in use-table-data.ts:82-98), `filterMode: 'and'|'or'`, `renderFilter`, `renderFilterIcon`, `renderFilterMenu`, `filterIconPopoverProps`, `paginationBehaviorOnFilter`, `onUpdate:filters`.
- **Runtime vs renderable:** popover show/hide + temporal value are runtime; filter state itself renderable. Menu css vars injected: `--n-action-padding`, `--n-action-button-margin`, `--n-action-divider-color` (DataTable.tsx:286-295 → FilterMenu style).

## 5. PAGINATION + TABLE-DATA
- **Mechanism (use-table-data.ts, 456 lines):** pipeline is `treeMateRef` (createTreeMate over `props.data`, with `getDisabled` from selection column) → `filteredDataRef` (per-column filter traversal, default filter = `String(row[col]).indexOf(value)` substring, `and`/`or` modes) → `sortedDataRef` (via useSorter) → `paginatedDataRef` = `sortedData.slice((page-1)*pageSize, +pageSize)` unless `remote` (then raw `treeNodes`) or no pagination (use-table-data.ts:244-252). Page/pageSize merge controlled (`pagination.page/pageSize`) and uncontrolled refs; `boundedMergedCurrentPageRef` clamps to `[1, ceil(filtered.length/pageSize)]` when not remote (use-table-data.ts:216-226). `mergedPaginationRef` builds a full `PaginationProps` object, stripping deprecated handlers and re-emitting through `mergedOnUpdatePage`/`mergedPageSize` (use-table-data.ts:303-331). Also exports `rawPaginatedDataRef`, `rawSortedDataRef`, `mergedItemCountRef` (remote→`pagination.itemCount`, else `filteredData.length`), imperative `filter/filters/clearFilter(s)/page/sort/clearSorter`, `hoverKeyRef`, `selectionColumnRef`, `childTriggerColIndexRef`, `onUnstableColumnResize`.
- **Mount point:** **NPagination is NOT inside MainTable** — it mounts in `DataTable.tsx` root, after the wrapper: `<div class="n-data-table__pagination"><NPagination theme/... disabled={loading} {...mergedPagination} /></div>` (DataTable.tsx:514-523), gated by `mergedShowPaginationRef` (no pagination prop → false; `paginateSinglePage` → true; else pageCount>1) (DataTable.tsx:454-466). cssr `cE('pagination')` = margin + flex-end (index.cssr.ts:449-453).
- **Components:** `NPagination` (DataTable.tsx:29).
- **State:** `pagination` prop object (`page`, `pageSize`, `pageCount`, `itemCount`, `defaultPage`, `defaultPageSize`, `showSizePicker`, …), `remote`, `paginateSinglePage`, `onUpdate:page/pageSize`, `onUpdate:filters`.
- **Runtime vs renderable:** pagination slice + clamping computed; page change emits + `scrollMainTableBodyToTop` on page watch (use-scroll.ts:264) is runtime.

## 6. FIXED COLUMNS/HEADER + SCROLL
- **Mechanism (use-scroll.ts, 316 lines):** builds `fixedColumnLeftMapRef`/`fixedColumnRightMapRef` = per-fixed-column `{start,end}` px offsets accumulated by traversing `column.fixed==='left'` (left→right) and `'right'` (right→left), recursing into `children` groups (use-scroll.ts:63-104). Header/body x-scroll sync: `handleTableHeaderScroll`/`handleTableBodyScroll` schedule `syncScrollState('head'|'body')` via `beforeNextFrameOnce` (seemly), copying `scrollLeft` between the two elements with a `scrollPartRef` echo-guard and `lastScrollLeft` memory; `syncScrollState('layout')` re-applies stored offset after virtual-list remount/empty toggle (use-scroll.ts:180-245). `deriveActiveLeft/RightFixedColumn(+Children)` compute `leftActiveFixedColKeyRef` etc. — the "active" fixed column whose edge shadow shows, derived from `lastScrollLeft` vs map starts. `xScrollableRef` = `scrollX` set OR basic auto-layout overflow; `explicitlyScrollableRef` = `scrollX`/`maxHeight`/`flexHeight`.
- **DOM/styles:**
  - Body: `td` inline `style={{ left: pxfy(fixedColumnLeftMap[colKey]?.start), right: pxfy(fixedColumnRightMap[colKey]?.start) }}` (Body.tsx:896-897) + class `n-data-table-td--fixed-left|right` (Body.tsx:918).
  - Header: `th` inline `style={{ left: pxfy(fixedColumnLeftMap[key]?.start), right: pxfy(...) }}` (Header.tsx:311-312) + `n-data-table-th--fixed-left|right` (Header.tsx:326).
  - cssr `fixedColumnStyle` (index.cssr.ts:609-640): `cM('fixed-left') { left:0; position:sticky; z-index:2; ::after 36px shadow }`, `cM('fixed-right') { right:0; position:sticky; z-index:1; ::before 36px shadow }`.
  - Scroll container: `NScrollbar` with `class="n-data-table-base-table-body"` (Body.tsx:572-580), `scrollable={explicitlyScrollable || xScrollable}`, `contentStyle.minWidth = scrollX || '100%'` (Body.tsx:538-542); header is a separate `table.n-data-table-thead` (Header.tsx:443) inside `div.n-data-table-base-table` (MainTable.tsx:107).
  - `MainTable.tsx:79-87` toggles `n-data-table-base-table--transition-disabled` around fixed-state changes.
- **Runtime vs renderable:** scroll sync, active-fixed derivation, page-change scroll-to-top, `virtualScroll`/empty watchers are all pure runtime (DOM scroll listeners + rAF). The left/right offsets are renderable inline styles.

## 7. RESIZABLE
- **Mechanism:** `use-resizable.ts` is a tiny `Record<ColumnKey, number>` width store (`getResizableWidth`/`doUpdateResizableWidth`/`clearResizableWidth`, guarded by `isColumnResizable`). `ResizeButton` renders a bare `<span data-data-table-resizable class="n-data-table-resize-button [n-data-table-resize-button--active]">` and drives window-level `mousemove/mouseup` via `evtd` `on/off`, emitting `displacementX` (ResizeButton.tsx:60-77). Header wires `handleColumnResizeStart/Resize/End` (Header.tsx:143-…, 283-291), measuring actual width from `cellElsRef` `getBoundingClientRect` (Header.tsx:111-114) and clamping via `clampValueFollowCSSRules` + `onUnstableColumnResize`.
- **Components:** none (no naive-ui peer) — `evtd` only.
- **DOM:** `<span>` absolutely positioned in th, cssr `width: var(--n-resizable-container-size); position:absolute; top/right/bottom; cursor:col-resize` (index.cssr.ts:318-324); width flows into `createCustomWidthStyle` → `width/minWidth/maxWidth` inline style on `col`/`th` (utils.ts:95-105, use-group-header.ts ColItem.style).
- **State:** `resizableWidthsRef`, column `resizable`/`minWidth`/`maxWidth`, `onUpdate:resizableWidth`-style flow via `doUpdateResizableWidth`, `onUnstableColumnResize`.
- **Runtime:** drag listeners are runtime; resulting widths are renderable inline styles.

## 8. GROUP HEADER
- **Mechanism (use-group-header.ts):** `getRowsAndCols` walks `columns` twice. First pass (`ensureMaxDepth`) flattens leaves into `cols` (with width style, leaf index, default `width:128` for horizontal virtual scroll) and records `maxDepth`, `totalRowSpan`, `hasEllipsis`, `dataRelatedCols`. Second pass (`ensureColLayout`) builds `rows[depth]` of `RowItem {colSpan,rowSpan,column,colIndex,isLast}`: non-leaf th's `colSpan` = sum of children spans (colSpan>1 forbidden on non-leaf), leaf `rowSpan = maxDepth - depth + 1`, `titleColSpan` lets a leaf span >1 and hides covered leaves via `hideUntilIndex` (use-group-header.ts:66-135).
- **DOM:** `<thead class="n-data-table-thead">` → one `<tr class="n-data-table-tr">` per row (Header.tsx:443-448) → `th` with `colspan`/`rowspan` attributes (Header.tsx:320-321) + `data-col-key`. Leaf cells carry `n-data-table-th--last` when `isLast`.
- **State:** purely derived from `columns`; `hasEllipsisRef`/`dataRelatedColsRef` feed other subsystems.
- **Renderable:** yes, entirely computed structure.

## 9. SUMMARY + MERGE CELL
- **Mechanism:** `summary` prop (`CreateSummary = (pageData) => SummaryRowData | SummaryRowData[]`, interface.ts:563-565). Body calls `summary(rawPaginatedData)` and injects synthetic row-info entries `isSummaryRow: true, key: '__n_summary__'` (or `__n_summary__${i}` for arrays), positioned per `summaryPlacement: 'top'|'bottom'` (Body.tsx:647-677). Summary rows are ordinary `<tr>`s in **tbody — there is no `tfoot`** anywhere in the source.
- **DOM/classes:** `td` gets `n-data-table-td--summary` (Body.tsx:909); `tr` gets `n-data-table-tr--summary` (cssr `cM('summary')` gives `background-color: var(--n-merged-th-color)` index.cssr.ts:409-411, and `cNotM('summary')` excludes summary rows from hover bg, index.cssr.ts:219-225).
- **Merge cell:** `Cell.tsx` reads `SummaryCell {value, colSpan, rowSpan}` → `mergedColSpan`/`mergedRowSpan` (Body.tsx:827-836, summary path reads `row[colKey]?.colSpan || 1`); normal rows use column `colSpan`/`rowSpan` render fns. Cross-row tds maintain a `cordKey`/`cordToPass` hover-coordinate grid so `td--hover` propagates across merged spans (Body.tsx:839-864, 910-914). `colspan={mergedColSpan}` `rowspan={isVirtual ? undefined : mergedRowSpan}` (Body.tsx:902-903).
- **Components:** none extra (Cell renders value directly; `isSummary` skips `render`).
- **State:** renderable; `summaryPlacementRef` provided via injection (DataTable.tsx:303).

## 10. VIRTUAL SCROLL
- **Mechanism:** Body imports `VirtualList` from **`vueuc`** (Body.tsx:26) and `VirtualListInst` type (Body.tsx:3). When `shouldDisplayVirtualList = virtualScroll && !empty` (Body.tsx:217-219), instead of a plain `<table>` it renders `<VirtualList items={displayedData} itemSize={minRowHeight} visibleItemsTag={VirtualListItemWrapper} showScrollbar={false} onResize/onScroll>` (Body.tsx:1103-1116); `VirtualListItemWrapper` (Body.tsx:110) is a custom visible-items container that emits the `<table class="n-data-table-table">` structure. Header has a parallel path: `VVirtualList` (Header.tsx:12) with `items=[{}]`, `itemSize=headerHeight`, `visibleItemsTag=VirtualListItemWrapper` (Header.tsx:375-385) when `virtualScrollHeader` is on — non-fixed cells become absolutely-positioned `div`s (`CellComponent = getLeft && !column.fixed ? 'div' : 'th'`, Header.tsx:297, `position:absolute; left:pxfy(getLeft(colIndex))` Header.tsx:303-309) plus a hidden spacer `<th colspan=…>` (Header.tsx:418-423). Horizontal virtual (`virtualScrollX`) switches body cells to `div` too (Body.tsx:718).
- **DOM delta:** virtual mode replaces `<table>`+`<tbody>` flat rows with vueuc's itemized list (each row wrapped), `showScrollbar=false` (scrollbars come from outer `NScrollbar`), row height forced (`itemSize`, `isVirtualX && {height: virtualXRowHeight}` Body.tsx:1051), `rowspan` omitted (Body.tsx:903).
- **State:** `virtualScroll`, `virtualScrollX`, `virtualScrollHeader`, `minRowHeight`, `heightForRow`, `headerHeight` props; scroll/resize handlers (`handleVirtualListScroll/Resize` → `scrollbarInstRef.sync()`) are runtime.
- **Also:** `NScrollbar` is always the outer container (Body.tsx:572), with `container`/`content` overridden to the virtual list's elements when virtual is active (Body.tsx:581-584).

## 11. ELLIPSIS / TOOLTIP cells
- **Mechanism (Cell.tsx):** if `column.ellipsis` is truthy: object form → `NPerformantEllipsis` when `column.ellipsisComponent === 'performant-ellipsis'` (Cell.tsx:62-71), else `NEllipsis` (Cell.tsx:74-80), both spreading the ellipsis options and theme peers; `true` (non-object) → plain `<span class="n-data-table-td__ellipsis">` (Cell.tsx:85). **No `NTooltip` import exists anywhere in the data-table package** (search returned 0); tooltip behavior is whatever `NEllipsis`'s own `tooltip` option provides (Header.tsx:254 also branches: `ellipsis === true || (ellipsis && !ellipsis.tooltip)` → plain `n-data-table-th__ellipsis` div, else `NEllipsis`).
- **Components:** `NEllipsis`, `NPerformantEllipsis` (Cell.tsx:11-12, Header.tsx:15).
- **State:** renderable, purely column-config driven.

## 12. LOADING
- **Mechanism:** root `<div class="n-data-table [n-data-table--loading]">` (DataTable.tsx:504); a `Transition name="fade-in-scale-up-transition"` wraps `<div class="n-data-table-loading-wrapper">` containing `NBaseLoading` (or `slots.loading`) (DataTable.tsx:524-540). Wrapper is absolutely centered (cssr index.cssr.ts:117-127, `--n-loading-color/size`). `cM('loading')` dims `data-table-wrapper` with `opacity: var(--n-opacity-loading); pointer-events:none` (index.cssr.ts:462-467). Empty node gets `n-data-table-empty--hide` while loading (Body.tsx:548, cssr `cM('hide') opacity:0` index.cssr.ts:445-447). `NPagination` gets `disabled={loading}` (DataTable.tsx:519).
- **Components:** `NBaseLoading` (DataTable.tsx:20) — **not NSpin**.
- **State:** `loading` prop; also `loadingKeySetRef` for per-row async expand loading (DataTable.tsx:236).

## 13. EMPTY
- **Mechanism:** `mergedEmptyRef = paginatedDataRef.length === 0` (DataTable.tsx:148) → root class `n-data-table--empty` (DataTable.tsx:506) which triggers cssr `cM('empty')` layout overrides (index.cssr.ts:80-114). Body renders `createEmptyNode()` — `<div class="n-data-table-empty [n-data-table-empty--hide]" ref=emptyElRef>` with `position:sticky; left:0; width:var(--n-scrollbar-current-width)` when x-scrollable (Body.tsx:544-556) — containing `slots.empty` → `NConfigProvider.renderEmpty` → **`NEmpty`** with theme peers (Body.tsx:558-564). It sits inside `NScrollbar` default slot, replacing the table when `empty && !showHeader && scrollable` (Body.tsx:597-600); virtual list is disabled when empty (Body.tsx:217-219).
- **Components:** `NEmpty` (Body.tsx:32).
- **State:** computed; renderable.

---

## Dependency surface table

| naive-ui module | used by sub-surfaces |
|---|---|
| `NCheckbox` / `NCheckboxGroup` | SELECTION (body+header), FILTER (menu, multiple mode) |
| `NRadio` / `NRadioGroup` | SELECTION (single mode, BodyRadio), FILTER (menu, single mode) |
| `NDropdown` | SELECTION (SelectionMenu only) |
| `NPopover` | FILTER (FilterButton wrapper) |
| `NScrollbar` (`_internal`) | FILTER (menu), SCROLL (body container), VIRTUAL (outer scroller) |
| `NButton` | FILTER (clear/confirm) |
| `NEllipsis` | ELLIPSIS cells + header title |
| `NPerformantEllipsis` | ELLIPSIS cells (`ellipsisComponent: 'performant-ellipsis'`) |
| `NTooltip` | **not used** (0 hits in package) |
| `NPagination` | PAGINATION (DataTable root, below wrapper) |
| `NBaseLoading` (`_internal`) | LOADING (root overlay), EXPAND (async trigger spinner) |
| `NEmpty` | EMPTY |
| `NBaseIcon` + icons (`ChevronDown/Right`, `ArrowDown`, `Filter`) | SELECTION, EXPAND, SORT, FILTER |
| `NIconSwitchTransition` (`_internal`) | EXPAND (icon swap) |
| `useConfig` (NConfigProvider `renderSorter`/`renderFilter`/`renderEmpty`) | SORT, FILTER, EMPTY |
| `vueuc` `VirtualList`/`VVirtualList` | VIRTUAL SCROLL (body + header) |
| `evtd` (`on/off`) | RESIZABLE (window drag listeners) |
| `treemate` | SELECTION (cascade keys), TABLE-DATA (tree pipeline) |

**cssr vars scoped to sub-surface classes** (index.cssr.ts): `--n-sorter-size` (291), `--n-resizable-container-size`/`--n-resizable-size` (318-324), `--n-action-padding`/`--n-action-button-margin`/`--n-action-divider-color` (filter menu, 567-576), `--n-pagination-margin` (449), `--n-empty-padding` (434), `--n-loading-size/color`, `--n-opacity-loading` (117-127, 464), `--n-th-icon-color-active` (sorter/filter active, 315/342), `--n-merged-th-color-sorting`/`--n-merged-td-color-sorting` (278/415), `--n-merged-th-color` on `td--summary` (409). **No `--merge-borders` var exists**; merged-cell borders use `--n-merged-border-color` and the `--single-column` pseudo-element trick (468-476). Selection column has no dedicated width var — width comes from `createCustomWidthStyle` inline styles or default 128px (use-group-header.ts:64).
