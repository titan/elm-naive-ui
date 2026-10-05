# data-table b6 recon — group headers / summary / merge cells

Upstream: naive-ui v2.45.3 `/home/titan/Works/elm/naive-ui/src/data-table/src/`.
Files: `use-group-header.ts` (group math), `TableParts/Header.tsx` (thead),
`TableParts/Body.tsx` (summary merge + span grid + td/tr), `TableParts/Cell.tsx`
(summary cell content), `interface.ts` (types), `utils.ts`, `styles/index.cssr.ts`.
Spec pin sources: `/tmp/next-upstream/data-table/tests/DataTable.spec.tsx` :847
(summary), :1113 (rowSpan/colSpan), :1360–1430 (children/group), :1011
(summary+rowProps smoke), :1500–1519 (expand colspan), :1543–1556 (colgroup bytes).
(No HeaderButton trap this batch — nothing b6 lives outside `src/data-table/src/`.)

## 1. Types (interface.ts)

- `TableColumnGroup<T>` (:267–278): `{ title?: string|fn, type?: never, key: ColumnKey,
  children: Array<TableBaseColumn<T>>, resizable?, filterOptions?: never } &
  CommonColumnInfo` — group cols carry CommonColumnInfo (fixed/width/minWidth/
  maxWidth/className/align/titleAlign/ellipsis…) but NO sorter/filter/titleColSpan.
- `TableBaseColumn` += `titleColSpan?: number` (:278), `colSpan?: (rowData, rowIndex)
  => number` / `rowSpan?: (…)` (:310–311). Selection/expand columns: `colSpan?: never;
  rowSpan?: never` (:327–328).
- `summary: CreateSummary<T>` (:61), `summaryPlacement: { default 'bottom' }` (:120).
- `CreateSummary<T> = (pageData: T[]) => SummaryRowData | SummaryRowData[]` (:563);
  `SummaryCell { value?: VNodeChild, colSpan?: number, rowSpan?: number }` (:567);
  `SummaryRowData = Record<string, SummaryCell>` (:572) — keyed by COLUMN KEY.
- `'children' in column` is the group gate EVERYWHERE (key presence, NOT length).

## 2. use-group-header.ts — getRowsAndCols (port verbatim)

Pass 1 `ensureMaxDepth(columns, depth)` (pre-order DFS):
- group (children present) → recurse only.
- leaf → `cols.push({ key: getColKey(col), style: createCustomWidthStyle(col,
  resizedWidth=undefined), column, index: currentLeafIndex++ , width: …})`
  (width field is virtual-only — ignore); `totalRowSpan += 1`;
  `hasEllipsis ||= !!column.ellipsis`; `dataRelatedCols.push(col)`.
- `rows[depth]` created lazily when depth > maxDepth (so depths with only group
  nodes still exist).

Pass 2 `ensureColLayout(columns, depth)` (state: currentLeafIndex reset to 0,
`hideUntilIndex = 0` per CALL LEVEL — it is a local of each recursion):
- leaf with `currentLeafIndex < hideUntilIndex` → `currentLeafIndex += 1; return`
  (cell swallowed by an earlier titleColSpan th; NO rowItem).
- leaf: `colSpan = titleColSpan ?? 1`; `if (colSpan > 1) hideUntilIndex =
  currentLeafIndex + colSpan`; `isLast = currentLeafIndex + colSpan ===
  totalRowSpan`; `rowSpan = maxDepth - depth + 1`; push rowItem; `currentLeafIndex
  += 1`.
- group: save `cached = currentLeafIndex`; recurse children; `colSpan = Σ
  children.colSpan` (from the WeakMap — i.e. Σ of child rowItems' colSpans);
  `isLast = cached + colSpan === totalRowSpan`; `rowSpan = 1`; push rowItem at
  `rows[depth]` AFTER recursion (post-order — this fixes intra-depth ordering).

Edge: `children: []` → key present ⇒ group branch: colSpan 0, no leaves added to
cols; th renders colspan="0". Byte-faithful.

Spec walk (columns = [name(w100), age(w100, children=[test1,test2])]):
rows[0] = [name{colSpan1,rowSpan2,isLast=false}, age{colSpan2,rowSpan1,isLast=TRUE}],
rows[1] = [test1{1,1,false}, test2{1,1,TRUE}]; cols = [name,test1,test2];
totalRowSpan 3; maxDepth 1. Matches spec pins :1394–1417 exactly.

## 3. Header.tsx

- thead: `<thead class=n-data-table-thead data-n-id>` → `rows.map(row => <tr
  class=n-data-table-tr>{renderRow(row)}</tr>)` — header tr has NO modifiers.
- th (non-virtual): attrs order `style, colspan={colSpan}, rowspan={rowSpan},
  data-col-key={getColKey(col)}` — colspan/rowspan ALWAYS present (every th, incl.
  spans of 1). style array: fixed left/right offsets FIRST, then
  `{width: pxfy(col.width), textAlign: titleAlign || align, height: undefined}`.
- th class order: `n-data-table-th` → `--fixed-left|right` (leaf fixed maps) →
  object-keys order `--sorting`, `--filterable`, `--sortable`, `--selection`,
  `--last` (isLast from RowItem) → `column.className` LAST.
- click handler: only when NOT selection/expand AND NOT `'children' in column`
  (plus existing sorter/onSorterChange gates). Group th never clicks.
- Content: selection branch unchanged (multiple !== false → checkbox + extra);
  everything else (incl. GROUP) → `div.th__title-wrapper > div.th__title` +
  ellipsis forms + SortButton/FilterButton gated by `isColumnSortable/
  isColumnFilterable` — both return FALSE for children-present columns
  (utils.ts: `if ('children' in column) return false`). So group th = bare title
  wrapper, no buttons.
- colgroup (Header discrete + Body inline + VirtualListItemWrapper — only the
  first two matter): `cols.map(col => <col key style={col.style}>)` — LEAVES
  only; `col.style` = createCustomWidthStyle = `{width: getStringColWidth(col),
  minWidth: formatLength(minWidth) || width, maxWidth: formatLength(maxWidth)}`
  (all-undefined ⇒ no style attr). Group cols never in colgroup.

## 4. Body.tsx — summary + merge

Data assembly (order matters):
1. `mergedPaginationData` (tree flatten n/a — tree deferred in port).
2. summary: `summaryRows = summary(rawPaginatedData)` — arg is the PAGED rows
   (pre-summary). Array → per-row `{isSummaryRow, key: __n_summary__${i},
   tmNode.rawNode: row, index: -1}`; single object → one row key `__n_summary__`.
   placement 'top' → PREPEND, else APPEND (default bottom).
3. Expand tiling AFTER summary merge (summary rows can't tile in the port — no
   `row` for renderExpand; upstream would tile if a caller put `__n_summary__`
   in expandedRowKeys — inherited-edge doc).
4. `rowCount = displayedData.length` (post-tiling, incl. summary); `colCount =
   cols.length` (leaves); `actualRowIndex = rowInfo.index` (summary ⇒ −1).
5. `empty = paginatedData.length === 0` (:216) — empty data + summary ⇒ NO
   tbody at all (summary unrendered). Port's existing `paginatedData opts == []`
   gate already matches.

Row render (normal/summary rows):
- `isSummary = 'isSummaryRow' in rowInfo`; `striped = !isSummary && rowInfo.striped`
  (parity class suppressed on summary rows).
- `rowProps`/`rowClassName` upstream ARE invoked on summary rows with
  `(summaryRecord, -1)` — port CANNOT (no `row` value) ⇒ divergence: skipped on
  summary rows. Document.
- tr class order: `n-data-table-tr` → `--summary` → `--striped` → `--expanded` →
  rowClassName → props.class.
- Cells iterate LEAF cols (`colIndex = col.index`).

Span math per cell:
- `mergedColSpan = isSummary ? (rawNode[colKey]?.colSpan || 1) : (colSpan ?
  colSpan(rowData, actualRowIndex) : 1)` — note `|| 1`: summary 0/undefined → 1;
  data-fn result 0 is KEPT. Same for rowSpan.
- `isLastCol = colIndex + mergedColSpan === colCount`; `isLastRow =
  displayedRowIndex + mergedRowSpan === rowCount`; `isCrossRowTd =
  mergedRowSpan > 1`.
- **Skip grid** (structural — MUST port): `cordToPass : Record<rowIndex, colIndex[]>`.
  Before rendering a cell: if `colIndex ∈ cordToPass[displayedRowIndex]` → splice
  it and render NOTHING (no td). After computing spans, if `mergedColSpan > 1 ||
  isCrossRowTd`: for i in [displayedRowIndex, displayedRowIndex+mergedRowSpan),
  j in [colIndex, colIndex+mergedColSpan), skip (i==displayedRowIndex &&
  j==colIndex): push j into cordToPass[i].
- cordKey/hoverKey/r rowIndexToKey (cross-row `--hover` coordination) = runtime
  mouse state — NOT ported (accepted edge; static DOM unaffected). Document.
- td attrs: `colspan={mergedColSpan}` `rowspan={mergedRowSpan}` ALWAYS (both,
  every td); `data-col-key` always. Style array: `{textAlign: align||undefined,
  width: pxfy(width)}` → fixed left/right offsets → `--indent-offset:` empty
  (tree deferred ⇒ summary indent-0/expand-placeholder branch unreachable;
  inherited-edge doc).
- td class order: `n-data-table-td` → `column.className` → [--hover skipped] →
  `--summary` (isSummary) → `--sorting` → `--fixed-left|right` →
  `--{align}-align` → `--selection` → `--expand` → `--last-col` (isLastCol) →
  `--last-row` (isLastRow).
- Cell content: selection kind + isSummary → NOTHING; expand kind + isSummary →
  NOTHING; basic + isSummary → Cell.tsx summary path: `(row[key] as
  SummaryCell)?.value` (missing key ⇒ empty td) — value still passes through the
  SAME ellipsis wrapping as normal cells (Cell.tsx renders value then wraps).
  Non-summary cells unchanged (`view`).

Expand-row td (`isExpandedRow` branch, b3): colspan = `colCount` — now LEAF
count. `--last-col` always; `--last-row` iff displayedRowIndex+1 === rowCount.

## 5. cssr (styles/index.cssr.ts)

All b6 selectors were in the b1 cssr pull (grep `css/naive-ui.css`:
8 hits for td--summary|tr--summary|last-col|last-row): `tr:not(--summary):hover`,
`td--last-row` (border + ::after/::before), `td--summary` (bg th-color),
`td--hover`, `td__ellipsis--last`, `td--last-col`, `bottom-bordered →
td--last-row`. ⇒ **prep expected NO-OP** (verify with grep, document in feat).

## 6. Port seam map (src/NUI/DataTable.elm, ~3.7k post-b5)

API (Column record + columnDefaults — flat-record precedent, add 4 fields):
- `children : Maybe (List (Column row msg))` — Nothing = key absent (leaf);
  `Just []` = present-empty edge (§2). NEVER nest selection/expand/group under a
  group (TS forbids; port walks them as leaves — permissiveness divergence, doc).
- `titleColSpan : Maybe Int`, `colSpan : Maybe (row -> Int -> Int)`,
  `rowSpan : Maybe (row -> Int -> Int)` (fn args = (row, actualRowIndex);
  absent ⇒ 1; fn result 0 kept).
- Options += `summary : Maybe (List row -> List (List (String, SummaryCell msg)))`
  (arg = `paginatedData opts`; upstream single-object ≙ one-element list — key
  naming is Vue-internal, DOM-identical) and `summaryPlacement : SummaryPlacement`
  (`SummaryTop | SummaryBottom`, default Bottom).
- `type alias SummaryCell msg = { value : Maybe (Element msg), colSpan : Maybe
  Int, rowSpan : Maybe Int }`; lookup by colKey via assoc list (filterStates
  precedent).

New pure section `-- GROUP / SUMMARY / MERGE --` between FILTER MENU (:2833–3072)
and SELECTION (:3072):
- `leafColumns : List (Column row msg) -> List (Column row msg)` — §2 pass-1
  leaf walk (children-present ⇒ recurse; `Just []` contributes nothing and is
  NOT a leaf).
- `headerRows : List (Column row msg) -> List (List (HeaderCell row msg))` —
  §2 two-pass port. `HeaderCell = { column, colIndex, colSpan, rowSpan, isLast }`.
  Thread (rows-per-depth, currentLeafIndex, hideUntilIndex, totalRowSpan,
  maxDepth); per-level `hideUntilIndex` is call-local (recursive arg, not global).
- Export both (eq-pin targets, b4 fixedColumnLeftMap precedent) + SummaryPlacement
  (+ ctors) + SummaryCell type.

`opts.columns` walkers → `leafColumns opts.columns` (ALL data-related walks;
group cols are inert by construction but children must be reached):
:1034/:1151 colgroup · :1035/:1144/:2436 mergedSortStates · :1228 thead (→
headerRows) · :1372/:1734 fixedColumnLeft/RightMap · :1605 body cells · :1815
expanded td colspan (→ `List.length (leafColumns …)`) · :2476 filterable cols ·
:2756 filter pipeline · :3081 selectionColumnOf · :3347 expandColumnOf · :3426
anyEllipsis.

View rework:
- `theadNode` :1221 — `headerRows opts.columns |> List.map (\row -> tr
  [n-data-table-tr] (List.map (thNode …) row))`; thNode takes the HeaderCell:
  colspan/rowspan attrs from item (NOT constant 1), `--last` = item.isLast,
  click gate += children-absent; group th flows through existing title-wrapper
  branch (sortable/filterable false via utils gates — add children-present ⇒
  False to `isSortable`/`isColumnFilterable`).
- `displayedRows` — prepend/append summary DisplayedRows (isSummaryRow +
  summaryRow payload + paginatedIndex −1) BEFORE expand tiling; `parentTrNode`
  gates `--striped` off + skips rowClassName/rowAttributes on summary rows
  (divergence §4); tr gains `--summary` right after the base class.
- Cell loop → indexed leaf cols + §4 span math + cordToPass threading
  (Dict Int (List Int) fold across rows, splice-on-hit) + `--summary`/`--last-col`/
  `--last-row` per formulas + summary content branches (selection/expand ⇒ empty;
  basic ⇒ assoc value, SAME ellipsis wrap as `view`).
- Docstrings: module :148 scope note, Column/Options docs, tdNode/thNode docs;
  divergence bullets (rowClassName/rowAttrs on summary rows; hover/cordKey
  skipped; summary-can't-tile edge; nested-special-column permissiveness;
  summary single-vs-array collapse).

Examples: `examples/src/Main.elm` `dataTableSection` :4506 — add 3 demos
mirroring spec fixtures: group (name/age>test1,test2), summary (Σ45 both cells,
colSpan1/rowSpan2 + colSpan2/rowSpan1), merge (rowIndex0 ⇒ colspan3/rowspan2).
No new root class ⇒ check-dom target unchanged; manifest untouched (prep NO-OP).

## 7. Test zones (Task 26)

- eq pins: `tests/src/Main.elm` — append AFTER the b5 filter block (checks tail):
  headerRows walks (spec group fixture ⇒ the §2 matrix + isLast flags; titleColSpan
  swallow case; `Just []` edge), leafColumns, fixedColumnLeftMap with a grouped
  column set. **TRAP: the 7 exhaustive dt Column literals must gain the 4 new
  fields** (`children = Nothing, titleColSpan = Nothing, colSpan = Nothing,
  rowSpan = Nothing`) — they list every field, not record-update.
- DOM pins: `tests/inspect.mjs` — dt helpers :9134–9146; b6 probes append at the
  dt block tail BEFORE `// --- report` (after the b5 menu block); fixtures
  (dtGroupCols/dtSummaryOpts/dtMergeCol/dtMergeOpts…) before `dtSelCol`. Pin from
  spec bytes: summary :847 (data-col-key/colspan/rowspan/textContent 45, ×2 cells,
  tr--summary present, NO tfoot), merge :1113 (first tbody td colspan3 rowspan2;
  row 1 single td; 5 trs), group :1360 (thead spans ×4, `--last` on age+test2
  ths, colgroup = 3 cols, group th style width:100px, leaf cols of group have NO
  style attr when widthless), expand+merge colspan = leaf count. Expectations from
  upstream bytes ONLY (pins-first).
- Gate: `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` 8/8; elm-format every
  touched module (`npx elm-format --yes` from repo root for src, from `tests/`
  for test modules).
