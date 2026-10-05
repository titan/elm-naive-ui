# naive-ui data-table CORE recon (v2.45.3) — port ground truth

Recon by explorer session-1790390059119937-26, persisted verbatim by orchestrator.
Sources: `/tmp/next-upstream/data-table/` (mirror, identical bytes to `/home/titan/Works/elm/naive-ui/src/data-table/`).

---

## (a) DOM tree for a BASIC data-table (no selection/sort/filter/expand/summary)

Assumptions for "basic": default `size=medium`, no `maxHeight`/`flexHeight` (so `headerInBody=true`), rows present, `bordered`/`singleLine` shown as conditions. `clsPrefix` = `n` (default).

```
div.n-data-table[ style=--n-* inline vars ]            DataTable.tsx:493-510
 │  class order (byte order of the class array):
 │    1. "n-data-table"                       (always)
 │    2. "n-data-table--rtl"                  (iff rtlEnabled)
 │    3. themeClass                           (iff inlineThemeDisabled, e.g. "n-data-table--m--write" style hash class)
 │    4. "n-data-table--bordered"             (iff mergedBordered: props.bordered ?? configProvider.bordered ?? true)
 │    5. "n-data-table--bottom-bordered"      (iff mergedBottomBordered: false when bordered; else props.bottomBordered ?? true)  DataTable.tsx:98-107
 │    6. "n-data-table--single-line"          (iff singleLine, DEFAULT true)   interface.ts:96-98
 │    7. "n-data-table--single-column"        (iff singleColumn, default false)
 │    8. "n-data-table--loading"              (iff loading)
 │    9. "n-data-table--flex-height"          (iff flexHeight)
 │   10. "n-data-table--empty"                (iff paginatedData.length === 0)  DataTable.tsx:148
 ├─ div.n-data-table-wrapper                  DataTable.tsx:513   (always; flex-grow:1, flex column, relative, top radius, line-height)
 │   └─ div.n-data-table-base-table           MainTable.tsx:107    (always; ref selfElRef)
 │       │   ⚠ may imperatively gain "n-data-table-base-table--transition-disabled" via classList.add/remove (MainTable.tsx:79-87) — not a render-time class
 │       └─ (headerInBody ⇒ no separate header div; thead lives inside body table)
 │       └─ NScrollbar  ⇒ wrapper div.n-data-table-base-table-body   (class attr passed to scrollbar, merges with its own "n-scrollbar"; Scrollbar.tsx:868-875 mergeProps($attrs…class))
 │           │   style: bodyStyle {maxHeight,minHeight} only when !empty (Body.tsx:577)
 │           │   scrollable = explicitlyScrollable || xScrollable (Body.tsx:575)
 │           ├─ div.n-scrollbar-container      (only when scrollbar is "scrollable"; Body.tsx:581 container fn ⇒ virtual only; else scrollbar renders its own container)
 │           │   style may carry '--n-scrollbar-current-width' iff internalExposeWidthCssVar = xScrollable && empty (Body.tsx:587, Scrollbar.tsx:897-899)
 │           │   └─ div.n-scrollbar-content    (style contentStyle: {minWidth: formatLength(scrollX) || '100%'; width:'100%' if scrollX}  Body.tsx:538-542)
 │           │       └─ table.n-data-table-table          Body.tsx:1066-1071
 │           │           │   style: { tableLayout: mergedTableLayout }   ← NO width/minWidth on body table (Body.tsx ~1068-1070)
 │           │           ├─ colgroup (no class)          Body.tsx:1071-1075
 │           │           │   └─ col per leaf column, style = col.style (width/minWidth/maxWidth from column def)
 │           │           ├─ thead.n-data-table-thead  [data-n-id="<componentId>"]   Header.tsx:443-447 (discrete=false path, Body.tsx:1075)
 │           │           │   └─ tr.n-data-table-tr     (one per header row)   Header.tsx:450
 │           │           │       └─ th.n-data-table-th  [data-col-key="<key>"]  Header.tsx:275-317
 │           │           │           class order:
 │           │           │             1. "n-data-table-th"                (always)
 │           │           │             2. "n-data-table-th--fixed-left|right"  (iff key in fixedColumnLeftMap/RightMap)
 │           │           │             3. object block:
 │           │           │                --sorting    (iff column currently sorting)      [sub-surface]
 │           │           │                --filterable (iff isColumnFilterable)           [sub-surface]
 │           │           │                --sortable   (iff isColumnSortable)             [sub-surface]
 │           │           │                --selection  (iff type==='selection')  → never for basic
 │           │           │                --last       (iff isLast: colIndex+colSpan===totalRowSpan)
 │           │           │             4. column.className (user, may be undefined)
 │           │           │           style: { width: pxfy(column.width), textAlign: titleAlign||align, height: undefined } + left/right fixed offsets
 │           │           │           colspan=rowItem.colSpan, rowspan=rowItem.rowSpan
 │           │           │           └─ div.n-data-table-th__title-wrapper   Header.tsx:252
 │           │           │               └─ div.n-data-table-th__title       Header.tsx:253
 │           │           │                   ├─ [div.n-data-table-th__ellipsis]  (iff ellipsis===true || ellipsis w/o tooltip) Header.tsx:255
 │           │           │                   │    …else NEllipsis component (object ellipsis) or raw title
 │           │           │                   └─ (SortButton only if sortable — sub-surface)
 │           │           │               (FilterButton/ResizeButton siblings only if filterable/resizable — sub-surfaces)
 │           │           └─ tbody.n-data-table-tbody  [data-n-id="<componentId>"]   Body.tsx:1077-1080 (omitted entirely when empty)
 │           │               └─ tr.n-data-table-tr   Body.tsx:1038-1048
 │           │                   class order:
 │           │                     1. "n-data-table-tr"                        (always)
 │           │                     2. "n-data-table-tr--summary"              (iff isSummary)
 │           │                     3. "n-data-table-tr--striped"               (iff striped && index%2===1 && !summary)  Body.tsx paginatedDataAndInfo
 │           │                     4. "n-data-table-tr--expanded"             (iff row key in expandedRowKeys)
 │           │                     5. mergedRowClassName (string prop as-is, or rowClassName(row,index) result, '' if none)  utils.ts:115-123
 │           │                     6. rowProps(row,index)?.class
 │           │                   └─ td.n-data-table-td  [data-col-key="<key>"]  Body.tsx:895-927
 │           │                       class order:
 │           │                         1. "n-data-table-td"                    (always — present even unstyled)
 │           │                         2. column.className
 │           │                         3. resolvedCellProps?.class  (column.cellProps(row,i))
 │           │                         4. "n-data-table-td--summary"           (iff summary row)
 │           │                         5. "n-data-table-td--hover"             (cross-row hover logic; null for normal rows w/o rowSpan>1)
 │           │                         6. "n-data-table-td--sorting"           (sub-surface)
 │           │                         7. "n-data-table-td--fixed-left|right"  (iff column.fixed)
 │           │                         8. "n-data-table-td--{align}-align"     (iff column.align set — note: align ALSO sets inline text-align; class is redundant but emitted)
 │           │                         9. "n-data-table-td--selection"         (never basic)
 │           │                        10. "n-data-table-td--expand"            (never basic)
 │           │                        11. "n-data-table-td--last-col"          (iff colIndex+colSpan === cols.length)
 │           │                        12. "n-data-table-td--last-row"          (iff displayedRowIndex+rowSpan === rowCount)
 │           │                       style: { textAlign: align||undefined, width: pxfy(width) } + left/right offsets + '--indent-offset': '' ALWAYS PRESENT (the value is filled only for tree children; the declaration ships on every td) + cellProps.style
 │           │                       colspan/rowspan attrs (rowspan omitted only in virtual mode)
 │           │                       └─ cell content (Cell.tsx):
 │           │                            - column.render(row,i) if present, else lodash get(row,key) (or renderCell hook)
 │           │                            - ellipsis===true ⇒ span.n-data-table-td__ellipsis wrapper (Cell.tsx:85)
 │           │                            - ellipsis object ⇒ NEllipsis / NPerformantEllipsis (ellipsisComponent==='performant-ellipsis')
 ├─ div.n-data-table__pagination  (iff mergedShowPagination)   DataTable.tsx:515   ← note DOUBLE underscore `__` (cE) amid single-hyphen siblings
 │   └─ NPagination (theme/peer overrides from mergedTheme)
 └─ div.n-data-table-loading-wrapper  (inside Transition "fade-in-scale-up-transition", iff loading)  DataTable.tsx:528
     └─ NBaseLoading (strokeWidth 20, spinProps spread) or #loading slot
```

**Empty state** (Body.tsx:544-569, sibling of `table` inside `.n-scrollbar-content` when table empty):
```
div.n-data-table-empty [ + "n-data-table-empty--hide" iff loading ]
  style = bodyStyle + (xScrollable ? "position: sticky; left: 0; width: var(--n-scrollbar-current-width);" : none)
  content = #empty slot → configProvider renderEmpty → default <NEmpty theme=peers.Empty>
```
Special case Body.tsx:597-604: when `empty && !showHeader && (explicitlyScrollable||xScrollable)` the empty node is returned *alone* (no table) as scroll-sync placeholder.

**Header placement rule** (MainTable.tsx:105): `headerInBody = maxHeight===undefined && !flexHeight`. Basic table ⇒ header rendered *inside* body's `<table>` (`showHeader=true`, TableHeader with `discrete=false` returns bare `<thead>`; Header.tsx:455-459). Only when maxHeight/flexHeight set does a separate `div.n-data-table-base-table-header > table` exist above (Header.tsx:460-478).

**colgroup policy**: every table (header & body) gets `<colgroup>` with one `<col key=col.key style=col.style>` per leaf column; `col.style = { width, minWidth: minWidth||width, maxWidth }` from `createCustomWidthStyle` (utils.ts:95-113); selection/expand default width 40 (utils.ts:18-19). Group columns (`children`) get `width: undefined`.

**table element**: `border-collapse: separate; border-spacing: 0; width: 100%; tabular-nums` via CSS (index.cssr.ts `cB('data-table-table')`); `table-layout` set as *inline style* = `mergedTableLayout` = `'fixed'` if virtualScroll|flexHeight|maxHeight|hasEllipsis, else prop `tableLayout` default `'auto'` (DataTable.tsx:191-204, interface.ts:104-108).

**Where `--n-*` vars land**: ALL on the ROOT `div.n-data-table` only (DataTable.tsx:509 `style={this.cssVars}`). Inner elements consume via `var()`; the root also defines derived aliases `--n-merged-th-color` etc. in CSS (index.cssr.ts cB('data-table') block) which modal/popover contexts re-point (insideModal/insidePopover blocks at bottom of cssr). Exception: `--n-scrollbar-current-width` on `.n-scrollbar-container` (scrollbar), and `--indent-offset` set on td style inline.

---

## (b) `--n-*` var list with exact derivation

Emitted in `cssVarsRef` (DataTable.tsx:343-445), in this byte order:

| var | derivation (light.ts `self()` unless noted) |
|---|---|
| `--n-font-size` | `self.fontSize{Small\|Medium\|Large}` ← common passthrough `fontSizeSmall/Medium/Large` (light.ts:41-43; common: '14px'/'14px'/'15px') chosen by mergedSize via `createKey('fontSize', size)` |
| `--n-th-padding` | `self.thPadding{Small\|Medium\|Large}` ← `_common.ts` literals '8px'/'12px'/'12px' |
| `--n-td-padding` | `self.tdPadding{Small\|Medium\|Large}` ← `_common.ts` literals '8px'/'12px'/'12px' |
| `--n-bezier` | `common.cubicBezierEaseInOut` ('cubic-bezier(.4, 0, .2, 1)') |
| `--n-border-radius` | `common.borderRadius` ('3px') — passed through self (light.ts:39) |
| `--n-line-height` | `common.lineHeight` ('1.6') — light.ts:38 |
| `--n-border-color` | `composite(common.cardColor, common.dividerColor)` |
| `--n-border-color-modal` | `composite(common.modalColor, common.dividerColor)` |
| `--n-border-color-popover` | `composite(common.popoverColor, common.dividerColor)` |
| `--n-th-color` | `composite(common.cardColor, common.tableHeaderColor)` |
| `--n-th-color-hover` | `composite(composite(cardColor, tableHeaderColor), tableColorHover)` |
| `--n-th-color-modal` | `composite(modalColor, tableHeaderColor)` |
| `--n-th-color-hover-modal` | `composite(composite(modalColor, tableHeaderColor), tableColorHover)` |
| `--n-th-color-popover` | `composite(popoverColor, tableHeaderColor)` |
| `--n-th-color-hover-popover` | `composite(composite(popoverColor, tableHeaderColor), tableColorHover)` |
| `--n-td-color` | `common.cardColor` |
| `--n-td-color-hover` | `composite(cardColor, tableColorHover)` |
| `--n-td-color-modal` | `common.modalColor` |
| `--n-td-color-hover-modal` | `composite(modalColor, tableColorHover)` |
| `--n-td-color-popover` | `common.popoverColor` |
| `--n-td-color-hover-popover` | `composite(popoverColor, tableColorHover)` |
| `--n-th-text-color` | `common.textColor1` |
| `--n-td-text-color` | `common.textColor2` |
| `--n-th-font-weight` | `common.fontWeightStrong` ('500') |
| `--n-th-button-color-hover` | `common.tableColorHover` |
| `--n-th-icon-color` | `common.iconColor` |
| `--n-th-icon-color-active` | `common.primaryColor` |
| `--n-filter-size` | `_common.ts` literal '15px' |
| `--n-pagination-margin` | `_common.ts` literal '12px 0 0 0' |
| `--n-empty-padding` | `_common.ts` literal '48px 0' |
| `--n-box-shadow-before` | literal `'inset -12px 0 8px -12px rgba(0, 0, 0, .18)'` (dark: `.36`, dark.ts:31-32) |
| `--n-box-shadow-after` | literal `'inset 12px 0 8px -12px rgba(0, 0, 0, .18)'` (dark: `.36`) |
| `--n-sorter-size` | `_common.ts` '15px' |
| `--n-resizable-container-size` | `_common.ts` '8px' |
| `--n-resizable-size` | `_common.ts` '2px' |
| `--n-loading-size` | `common.heightSmall` ('28px') |
| `--n-loading-color` | `common.primaryColor` |
| `--n-opacity-loading` | `common.opacityDisabled` (light: '0.5') |
| `--n-td-color-striped` | `composite(cardColor, tableColorStriped)` |
| `--n-td-color-striped-modal` | `composite(modalColor, tableColorStriped)` |
| `--n-td-color-striped-popover` | `composite(popoverColor, tableColorStriped)` |
| `--n-td-color-sorting` | `composite(cardColor, tableColorHover)` (same expr as tdColorHover) |
| `--n-td-color-sorting-modal` | `composite(modalColor, tableColorHover)` |
| `--n-td-color-sorting-popover` | `composite(popoverColor, tableColorHover)` |
| `--n-th-color-sorting` | `composite(composite(cardColor, tableHeaderColor), tableColorHover)` (same as thColorHover) |
| `--n-th-color-sorting-modal` | `composite(composite(modalColor, tableHeaderColor), tableColorHover)` |
| `--n-th-color-sorting-popover` | `composite(composite(popoverColor, tableHeaderColor), tableColorHover)` |

Not on root (filter menu only, DataTable.tsx:283-291): `--n-action-padding`='8px 12px', `--n-action-button-margin`='0 8px 0 0', `--n-action-divider-color`=common.dividerColor.

Key common values (light): cardColor/modalColor/popoverColor = '#fff' (neutral*), tableHeaderColor='rgb(250,250,252)', tableColorHover='rgba(0,0,100,0.03)', tableColorStriped='rgba(0,0,100,0.02)', dividerColor='rgb(239,239,245)', textColor1='rgb(31,34,37)', textColor2='rgb(51,54,57)', primaryColor='#18a058'.

---

## (c) Basic-table props surface & class toggles

Props (interface.ts:32-165): `columns` (default []), `data` (default []), `size?: 'small'|'medium'|'large'` (default undefined→'medium', DataTable.tsx:91-97 — affects only cssVars padding/fontSize selection, **no class**), `bordered?: boolean|undefined` (default undefined→configProvider→true → `--bordered` + forces `--bottom-bordered` off), `bottomBordered?` (→ `--bottom-bordered`), `singleLine` default **true** (→ `--single-line`; cssr uses `cNotM('single-line')` so column borders appear only when singleLine=false), `singleColumn` (→ `--single-column`), `striped` (no root class; sets `--striped` on odd rows → `.n-data-table-tr--striped` + td bg), `rowClassName: string|fn` (appended to tr class), `rowProps: fn` (class/style spread onto tr), `rowKey`, `loading` (→ `--loading`, wrapper opacity, loading-wrapper node), `flexHeight` (→ `--flex-height` + header split), `maxHeight`/`minHeight` (header split + bodyStyle, no class), `scrollX` (contentStyle minWidth/width, xScrollable), `tableLayout` default 'auto' (inline style on table), `pagination`/`paginateSinglePage` (→ `__pagination` node), `summary`/`summaryPlacement`, `indent` default 16, `spinProps`, `scrollbarProps`, `renderCell`, `virtualScroll*`, `headerHeight`/`minRowHeight` default 28, `childrenKey`='children', `cascade` true, `summaryPlacement`='bottom', `paginationBehaviorOnFilter`='current'.

Root modifiers toggled (DataTable.tsx:494-508): `--bordered`, `--bottom-bordered`, `--single-line`, `--single-column`, `--loading`, `--flex-height`, `--empty`, `--rtl`, themeClass.

Column core types (interface.ts): `TableColumns = Array<TableColumnGroup|TableBaseColumn|TableSelectionColumn|TableExpandColumn>`; basic column = `TableBaseColumn` {title?, titleColSpan?, type?: never, key, render?, colSpan?/rowSpan? fns, sorter/filter/resizable fields, …} ∩ `CommonColumnInfo` {fixed?, width?, minWidth?, maxWidth?, className?, align?, titleAlign?, ellipsis?, ellipsisComponent?, allowExport?, cellProps?}. Selection = `type:'selection'`, expand = `type:'expand'` + `renderExpand` (keys synthesized `__n_selection__`/`__n_expand__`, utils.ts:49-55). Summary: `CreateSummary<T> = (pageData)=>SummaryRowData|SummaryRowData[]`, `SummaryRowData = Record<string, SummaryCell>`, `SummaryCell={value?,colSpan?,rowSpan?}` (interface.ts:546-552).

---

## (d) cssVars attachment & conditional computation

- Attached **only to root** `div.n-data-table` (DataTable.tsx:509), *unless* `inlineThemeDisabled` — then `cssVars` is `undefined` (DataTable.tsx:480-482) and vars are baked into a hashed `themeClass` via `useThemeClass('data-table', size[0], cssVarsRef, props)` (DataTable.tsx:446-453); `onRender?.()` called before render (DataTable.tsx:491).
- Size-conditional: `--n-font-size`, `--n-th-padding`, `--n-td-padding` are selected per mergedSize via `createKey('fontSize'|'thPadding'|'tdPadding', size)` (DataTable.tsx:391-393).
- Scrollbar-conditional (not in cssVarsRef): `--n-scrollbar-current-width` on `.n-scrollbar-container`, enabled only when `internalExposeWidthCssVar = xScrollable && empty` (Body.tsx:587) — consumed by the empty node's sticky width.
- `--n-box-shadow-before/after` are emitted in root vars but applied by a **dynamically mounted per-instance cssr style** keyed `[data-n-id="<id>"] [data-col-key="<key>"]::before/after` for fixed columns (Body.tsx:307-360) — scroll sub-surface.

---

## (e) Load-bearing quirks (byte-fidelity MUST-NOTs)

1. **Root is `display:flex; flex-direction:column; position:relative; width:100%`** (cssr cB('data-table')) — not block. `.n-data-table-wrapper` is also flex column with `flex-grow:1` and appears **twice** in the cssr file (two separate `cB('data-table-wrapper')` blocks: early for layout, later for radius/opacity/line-height) — merged output must include both.
2. **`--empty` restructures layout**: `.n-data-table-base-table` becomes `height:100%; display:flex; column` and `.n-data-table-base-table-body` + `.n-scrollbar-content` get `height:100%` (cssr cM('empty')).
3. **`table-layout` is inline style, not class**: `mergedTableLayout` = 'fixed' when virtualScroll|flexHeight|maxHeight|any column has `ellipsis`, else prop (default 'auto'). Header table additionally gets inline `minWidth: formatLength(scrollX)`; body table does NOT (it relies on `.n-scrollbar-content` minWidth).
4. **`border-collapse: separate; border-spacing: 0`** on `.n-data-table-table` — sticky/fixed columns and per-cell borders depend on it.
5. **th/td base classes always present** (`n-data-table-th`, `n-data-table-td`) even with no modifiers; `data-col-key` always present on th and td; `data-n-id` on thead and tbody (same componentId; used by dynamic fixed-shadow cssr).
6. **Class arrays are ordered**: root: base → rtl → themeClass → object-modifiers in fixed key order (bordered, bottom-bordered, single-line, single-column, loading, flex-height, empty). td: base → column.className → cellProps.class → summary → hover → sorting → fixed → align → selection → expand → last-col → last-row. Vue normalizes `false` entries away; a port must skip falsy entries without reordering.
7. **`--single-line` semantics inverted**: vertical cell borders are added by `cNotM('single-line')`; default prop is `true`, so default render has NO right borders. Demos toggle `:single-line="false"` to get dividers (border.demo.vue).
8. **`--bottom-bordered` forced off when bordered** (DataTable.tsx:98-107) — wrapper carries the border instead; `.n-data-table-td--last-row` gets its bottom border only under `cM('bottom-bordered')`.
9. **Header-in-body split**: without maxHeight/flexHeight there is exactly ONE `<table>` (thead inside tbody's table); `div.n-data-table-base-table-header` must NOT exist. With maxHeight, header is a separate div with `overflow: scroll; scrollbar-width:none` and hidden webkit scrollbars.
10. **`n-data-table__pagination` uses double underscore** (`__`) — cE selector `.n-data-table__pagination` — while `n-data-table-loading-wrapper`, `n-data-table-empty`, `n-data-table-wrapper` are single-hyphen blocks (cB).
11. **Empty node placement**: sibling of `<table>` inside `.n-scrollbar-content`; when `empty && !showHeader && scrollable` it replaces the table entirely; `--hide` (opacity:0) when loading.
12. **Striped is index-based on paginated rows** (`index % 2 === 1`), applied both to `tr--striped` and to each td bg via cssr nested rule; summary rows never striped.
13. **`--transition-disabled` class** is imperatively toggled on `.n-data-table-base-table` (MainTable.tsx:79-87) — transient, appears in DOM after mount when fixed columns exist.
14. **`text-align: start`** on th/td base (cssr) — inline `text-align` from `column.align`/`titleAlign` overrides; the `--{align}-align` td class is emitted anyway (redundant but present in byte stream).
15. **colgroup always present** (both header & body tables), `<col style>` carries width/minWidth/maxWidth; group columns emit `width: undefined`.
16. **tr hover rule** is `cNotM('summary') tr:hover` → paints tr and direct-child tds; summary rows excluded.
17. `singleLine`/`singleColumn`/`loading`/`flexHeight` are plain props with no merging — they map 1:1 to root classes; `bordered`/`bottomBordered` go through useConfig merging (`props.bordered ?? configProvider.mergedBordered ?? true`).
18. `mergedEmpty` (root `--empty`) uses **paginated** data length (DataTable.tsx:148); body's internal `empty` uses the same source (Body.tsx:216) — they agree, but pagination can make root non-empty while raw data empty only via pagination math, not otherwise.
