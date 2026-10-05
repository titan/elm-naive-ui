# data-table b4 recon — scroll/layout (upstream ground truth)

Upstream: naive-ui v2.45.3, `src/data-table/src/` (+ `_internal/scrollbar`,
`_internal/loading`). All line refs from that checkout. Spec:
`tests/DataTable.spec.tsx` (:188 loading, :212 flex-height, :740 scroll-x,
:911 table-layout, :1147 ellipsis, :1230–1330 empty-state matrix).

## 1. Props surface (interface.ts)

- `maxHeight: string | number` (:50), `minHeight` (DataTable.tsx :297 toRef), 
  `scrollX` (:76), `flexHeight` (:119), `loading: Boolean` (:66), `tableLayout:
  'auto'|'fixed'` default `'auto'` (:102), `spinProps: DataTableSpinProps`
  (:134 = SharedSpinProps = {strokeWidth, stroke, scale, radius}).
- Port model (px-only, the `Column.width` precedent): `Maybe Int` for
  maxHeight/minHeight/scrollX; `loading : Bool`; `flexHeight : Bool`;
  `tableLayout : TableLayout` default `TableAuto`; Button-style per-field
  `spinStrokeWidth/spinRadius : Maybe Int`, `spinScale : Maybe Float`,
  `spinStroke : Maybe String` over the sw-20/r-100/scale-1 baseline.

## 2. Scroll flags (use-scroll.ts :30-56, :191 DataTable.tsx)

- `explicitlyScrollable = scrollX !== undefined || maxHeight !== undefined
  || flexHeight`  (minHeight does NOT count)
- `xScrollable = scrollX !== undefined || (!explicitlyScrollable &&
  mergedTableLayout === 'auto')` — **a basic auto-layout table is
  x-scrollable** (spec's own comment at :1232: "auto layout empty tables
  are treated as x-scrollable"). The b1–b3 port never set `xScrollable` —
  latent gap, fixed in b4 (fit-content content style + x-rail + sticky
  empty).
- `mergedTableLayout = 'fixed'` if `virtualScroll || flexHeight ||
  maxHeight !== undefined || hasEllipsis` else `props.tableLayout`
  (DataTable.tsx :191). `hasEllipsis` = any column (header walk,
  use-group-header :79 `!!column.ellipsis` — drives BOTH th and td).
- `headerInBody = maxHeight === undefined && !flexHeight` (MainTable.tsx
  render) — split mode = own `<TableHeader>` + `<TableBody showHeader={false}>`
  inside `div.n-data-table-base-table`.
- bodyStyle = `{maxHeight: formatLength(maxHeight), minHeight:
  formatLength(minHeight)}` (MainTable.tsx :43) — fallthrough style on the
  scrollbar root (iff `!empty`) AND on the empty div.
- formatLength bytes: number → `Npx` (`0` → `'0'`); pure-number string →
  `Npx`; other strings pass through; undefined → declaration dropped.

## 3. NScrollbar composition (Body.tsx :538-604, _internal Scrollbar.tsx)

- `<NScrollbar scrollable={explicitlyScrollable || xScrollable}
  class="n-data-table-base-table-body" style={!empty && bodyStyle}
  contentStyle=… xScrollable={xScrollable} horizontalRailStyle={{zIndex:3}}
  verticalRailStyle={{zIndex:3}} theme=…>`.
- contentStyle = `{minWidth: formatLength(scrollX) || '100%'}` then
  `if (scrollX) contentStyle.width = '100%'` → bytes
  `min-width:1800px;width:100%` / `min-width:100%`.
- **`if (!scrollable) return $slots.default?.()`** (Scrollbar.tsx :824) —
  when merged layout is `fixed` AND no scrollX/maxHeight/flexHeight
  (reachable via `tableLayout: 'fixed'` or any ellipsis column): the slot
  renders BARE — no `n-scrollbar` wrapper, no container/content divs, no
  rails, and the fallthrough `class`/`style` attrs VANISH (no
  `n-data-table-base-table-body` anywhere).
- Wrapper shape when scrollable: `div.n-scrollbar[role=none]` >
  `div.n-scrollbar-container[role=none]` > `div.n-scrollbar-content
  [role=none][style=width:fit-content?+contentStyle]` + y-rail always +
  x-rail iff xScrollable. Rails: `data-scrollbar-rail` + `aria-hidden`,
  style `z-index:3` (both) in the table context; bars only when shown
  (at-rest: none). `internalExposeWidthCssVar` container var:
  `containerWidthRef = ref(null)` → `pxfy(null)` → declaration dropped
  (never renders statically).
- Port: `NUI.Scrollbar` gains `rootStyle` (merged into the root style attr
  AFTER the cssVars — Vue's own-then-fallthrough order) and
  `xRailStyle`/`yRailStyle : Maybe String` (raw `style` attr on the rail
  divs). Bare branch renders children directly at the DataTable level.

## 4. Body render (Body.tsx :538-660, :1062-1101)

- Slot content precedence: `if (empty && !showHeader && (explicitlyScrollable
  || xScrollable)) return createEmptyNode()` — **split + scrollable + empty
  renders ONLY the empty div** (split is scrollable by construction:
  maxHeight/flexHeight/scrollX all set explicitlyScrollable). Else the
  fragment: `<table class="n-data-table-table" style={{tableLayout:
  mergedTableLayout}}>` colgroup + thead (iff showHeader) + tbody (iff
  !empty) `</table>` + `empty ? createEmptyNode() : null`.
- Body table style = ONLY `table-layout:{merged}` (no minWidth — that rides
  the scrollbar contentStyle).
- Empty node: `div[class=n-data-table-empty (+ --hide iff loading)]
  style=[bodyStyle, xScrollable ? 'position: sticky; left: 0; width:
  var(--n-scrollbar-current-width);' : undefined]` (the sticky string is an
  upstream LITERAL — spaces after colons, trailing `;`; bodyStyle-object
  entries merge before it) > NEmpty.

## 5. Discrete header (Header.tsx :451-470)

- `div.n-data-table-base-table-header` > `table.n-data-table-table
  style={minWidth: formatLength(scrollX) (dropped when unset),
  tableLayout: merged}` (minWidth FIRST, then tableLayout) > colgroup >
  `thead.n-data-table-thead[data-n-id]` (same thead node as inline mode;
  `discrete={false}` path renders the bare thead only).

## 6. Fixed columns (use-scroll.ts :58-112, Header.tsx :296-330, Body.tsx :873-915)

- `leftFixedColumns = columns.filter(fixed === 'left')`, right likewise.
- `fixedColumnLeftMap`: DFS over left-fixed cols; leaf `start` = running
  width before it, `end` = start + `getNumberColWidth(col) || 0`;
  `getNumberColWidth`: selection/expand default 40 when width unset else
  depx(width); group col → 0 (b6); normal → width number or 0. Port: Int
  widths, `orElse col.width (Just 40)` on the special kinds.
- `fixedColumnRightMap`: same walk REVERSED (start = widths of FOLLOWING
  right-fixed cols).
- th style array `[{left: pxfy(leftMap[key]?.start), right:
  pxfy(rightMap[key]?.start)}, {width, textAlign: titleAlign||align,
  height: headerHeightPx (undefined → dropped)}]` → bytes
  `left:40px;width:100px` — offsets BEFORE width (td is the reverse).
  th class: base, `--fixed-left|right` (`leftFixed = key in leftMap`),
  sorting/filterable/sortable/selection/last, className.
- td style array `[{textAlign: align||undefined, width}, {left, right},
  {'--indent-offset': ''}, resolvedCellProps?.style || '']` → bytes
  `text-align:left;width:100px;left:40px;--indent-offset:` — offsets
  BETWEEN width and the indent var. td class: base, className, (summary,
  hover), `--sorting`, `--fixed-{column.fixed}` (reads `column.fixed`
  DIRECTLY, not the map), `--{align}-align`, selection/expand/last-col/
  last-row.
- Sticky/z-index for fixed cells comes from the STATIC cssr
  (`cM('fixed-left')`: left:0, position:sticky, z-index:2 + `::after`
  36px shadow strip; fixed-right mirrored z-index:1 + `::before`) — already
  extracted (css/naive-ui.css :7870+). The ACTIVE shadow
  (`[data-n-id][data-col-key]::after {box-shadow: var(--n-box-shadow-*)}`
  mounts at runtime only when scroll position activates a column —
  scroll-state, unreachable in a pure render; vars `--n-box-shadow-*`
  stay on the root. **Accepted edge, document.**

## 7. Ellipsis (Header.tsx :229-268, Cell.tsx :45-90)

- th: `ellipsis === true || (ellipsis && !ellipsis.tooltip)` →
  `div.n-data-table-th__ellipsis` wrapping the title (inside the title
  div, before the sorter span); object-with-tooltip → `NEllipsis` in
  place of the title text.
- td: `typeof ellipsis === 'object'` → NEllipsis (ALWAYS, tooltip or
  not); `ellipsis === true` → `span.n-data-table-td__ellipsis`. Asymmetry
  is upstream's — keep byte-faithful.
- Port: `Column.ellipsis : Maybe ColumnEllipsis` with
  `EllipsisPlain`/`EllipsisOpts NUI.Ellipsis.Options`; NEllipsis form rides
  the port's `NUI.Ellipsis` (its `p`-root / no-tooltip gaps are the
  Ellipsis module's documented surface).
- hasEllipsis flips mergedTableLayout to `fixed` (§2) which flips the body
  to the BARE branch (§3) unless scrollX/maxHeight/flexHeight set.

## 8. Loading (DataTable.tsx render :488-543)

- Root class array gains `--loading` (after `--single-column`, before
  `--flex-height` → before `--empty`; order: bordered, bottom-bordered,
  single-line, single-column, loading, flex-height, empty).
- After `__pagination`: `<Transition name="fade-in-scale-up-transition">`
  → at-rest initial render = plain `div.n-data-table-loading-wrapper` >
  NBaseLoading `strokeWidth={20}` + spinProps spread (per-field override;
  Button.tsx :648 precedent, ported as per-field Maybes).
- NBaseLoading chain: `div.n-base-loading[role=img][aria-label=loading] >
  div.n-base-loading__transition-wrapper > div.n-base-loading__container >
  svg.n-base-loading__icon` (Button.elm :874-890 chain + Loading.spinner).
- Pager: `disabled={loading}` override on NPagination (b2 docstring
  promised this for the loading batch).
- Empty div gets `--hide` while loading (§4). The pure `checkedKeysAfter*`
  helpers' upstream `loading` early-returns stay caller-side (the caller
  just does not apply while loading — document).
- `cM('loading')` css sets `--n-opacity-loading` on th/td text — static,
  already extracted.

## 9. Empty-state matrix (spec :1230-1330 — pin source)

| props | discrete header | sticky empty | scrollbar wrapper |
|---|---|---|---|
| (none, auto) | no | YES (xScrollable basic) | yes |
| ellipsis | no | no | **BARE** |
| table-layout=fixed | no | no | **BARE** |
| scroll-x | no | yes | yes |
| max-height | YES | no | yes |
| flex-height | YES | no | yes |
| min-height | no | yes (+min-height byte) | yes |
| ellipsis+max-height | YES | no | yes |
| ellipsis+scroll-x | no | yes | yes |
| scroll-x+max-height | YES | yes | yes |
| ellipsis+scroll-x+max-height | YES | yes | yes |

(split+empty renders ONLY the empty div in the slot — no table; the
discrete header keeps the thead table.)

## 10. Transition-disabled (MainTable.tsx watchEffect)

`--transition-disabled` is added post-mount while fixed columns exist and
the body is unmeasured, removed via setTimeout after first measure —
purely imperative, initial render carries nothing. Accepted edge,
document (plan already lists it out-of-scope).

## 11. prep verdict

NO-OP: every b4 selector (fixed-left/right th+td, th/td__ellipsis,
empty--hide, loading-wrapper, base-table-header, transition-disabled,
base-loading) is already in the b1 cssr pull (css/naive-ui.css :128-176,
:7870+); no new root class → no check-dom change; the 47-var set already
carries the loading/shadow vars. check-classes: all new classes covered.
Document in the feat commit (the b2/b3 precedent).
