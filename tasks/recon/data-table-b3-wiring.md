# B3 wiring recon — repo touchpoints (in-context, orchestrator; b2 fallback pattern)

## Verdict: batch-3 prep = NO-OP
`css/naive-ui.css` already carries every batch-3 selector (batch-1 prep extracted the whole
component cssr, confirmed by grep): `n-data-table-th--selection`, `n-data-table-td--selection`,
`n-data-table-expand`, `n-data-table-expand-placeholder`, `n-data-table-expand-trigger`,
`n-data-table-expand-trigger--expanded` (42 combined selector matches). NOTE: NO
`n-data-table-tr--expanded` selector exists in the css — expanded-row tr classes must be
re-derived from Body.tsx bytes (upstream may not style them, or uses another name).
No new root class → `tools/verify/check-dom.mjs` target untouched (`'.n-data-table': true` :148).
Theme: the 47-var set in `src/NUI/Theme/DataTable.elm` (Vars/vars only, NO peers record,
196 L) is selection/expand-agnostic. Document the no-op in the feat commit (dialog/b2 precedent).
manifest entry `'data-table'` (tools/manifest.mjs:491) already extracts whole-component cssr.

## NUI.DataTable (src/NUI/DataTable.elm, 1517 L) — seams batch 3 touches
Structure (line numbers at recon time): `Column` :269 / `columnDefaults` :288 /
`Options` :319 / `defaults` :345 / `view` :383 / `rootClasses` :415 / `paginationNode` :432 /
`scrollbarNode` :450 / `tableNode` :479 / `colNode` :506 / `theadNode` :545 / `thNode` :575 /
`thStyleAttr` :621 / `sortClickAttr` :638 / `sortButtonNode` :665 / `tbodyNode` :711 /
`trNode` :731 / `tdNode` :786 / `tdStyleAttr` :825 / `embedChild` :843 / sort pipeline :861-1352
(`mergedSortStates` :998, `defaultSortStates` :949, `deriveNextSorter` :1091) / helpers :1353+.

- `Options row msg` ALREADY carries `rowKey : row -> String` (b1) — selection/expand keying is
  wired for free. b3 adds: checkedRowKeys / expandedRowKeys / onUpdateCheckedRowKeys /
  onUpdateExpandedRowKeys (+ multiple / selection-menu options / renderExpand — exact upstream
  prop set pending upstream recon of interface.ts).
- `Column row msg` is a FLAT record (key/title/view/align/…/sorter/defaultSortOrder/sortOrder).
  b3 adds the column-type discriminator (upstream `type: 'selection' | 'expand'`) — flat-field
  (`kind : ColumnKind` + selection/expand option fields) vs variant-type decision rides the
  upstream interface bytes; flat-field keeps b1/b2 pins compiling unchanged.
- `thNode` (575): class chain base→`--sorting`→`--sortable`→`--last`→className over
  `title-wrapper > title (+ sortButtonNode)`. Selection th = separate branch (no
  title-wrapper; BodyCheckbox/SelectionMenu inside — DOM bytes pending upstream recon).
- `tdNode` (786): class chain base→className→`--sorting`→align→`--last-col`→`--last-row`,
  `data-col-key`, style `--indent-offset:` seed, colspan/rowspan constant 1. Selection td /
  expand td = branches; expanded-row tr = sibling `tr` after each data row (insertion seam:
  `tbodyNode`'s `List.indexedMap (trNode …)` — needs concatMap-style expansion).
- `mergedSortStates` :998 FIRST TASK: upstream `use-sorter.ts` L108-112 gates
  `column.type !== 'selection' && column.sorter !== undefined && (sortOrder ascend|descend|false)`.
  Our port: add `type /= SelectionColumn` to the controlled filter. NOTE the asymmetry:
  upstream `sort()` (L231) gates BOTH `!== 'selection' && !== 'expand'` — that is the
  imperative `table.sort()` API, NOT modeled in b2 (click path only); document.
- `defaultSortStates` :949: upstream init (use-sorter.ts L93+) has NO type gate — TS types
  make `sorter` unreachable on selection/expand columns. Keep our port ungated (upstream
  shape), document the flat-record divergence (a selection column with a sorter set would
  seed a sort state — unreachable upstream).

## Peer component surfaces
- `NUI.Checkbox` (src/NUI/Checkbox.elm, 260 L): `Options msg` = size/checked/indeterminate/
  disabled/focusable/onCheck(Bool->msg)/rtl. `view : Theme -> Options -> List(Element) ->
  Element` derives `CheckboxTheme.vars theme` INTERNALLY and passes the whole Vars record to
  `cssVars : Theme -> Size -> CheckboxTheme.Vars -> List (String,String)`. → privateInsideTable
  candidate designs: (a) `privateInsideTable : Bool` field mirroring upstream prop, (b) a
  `Maybe Vars` override. PICK FROM UPSTREAM Checkbox.tsx BYTES (what exactly the prop changes
  — pending upstream recon; the plan risk-table item).
- `NUI.Radio` (src/NUI/Radio.elm, 420 L): single `view : Theme -> Options msg -> List
  (Element msg) -> Element msg`, `Options msg` = size/checked/disabled/label/onChange/rtl —
  **NO `name` field**. If upstream BodyRadio passes `name` (attrs), b3 feat adds the field
  (or an attributes seam) to Radio.
- `NUI.Dropdown` (src/NUI/Dropdown.elm, 750 L): full surface ready for SelectionMenu —
  `type Option msg = Leaf GroupOption DividerOption RenderOption`, `Options msg` :169,
  `view : Theme -> Options -> List (Option msg) -> Element msg` :239, MenuFlags/active infra.
- `NUI.Pagination` — already wired (b2).

## Pin zones (b3 appends)
- `tests/src/Main.elm`: eq pins at the tail of `checks` (b2 block last: `] ++ msWalkChecks ++
  [ …pagination pins… ]`); live-* wrappers at the tail of the view list — b2 tail is
  `live-data-table-pag-hidden` (:11812), b3 wrappers append after it.
- `tests/inspect.mjs`: dt helpers :9134-9140 (`dtRoot/dtTable/dtThs/dtTrs/dtTds/dtScrollbar`),
  dt probe block :9143 → `// --- report`; b3 probes append at the block tail.
  Remember: `nClassesStr` filters to n-*; `fullClasses` starts with elm-ui layout classes.

## Files to touch (slider-modeled checklist, feat commit)
1. `src/NUI/DataTable.elm` — Column kind + selection/expand options, Options additions,
   selectionThNode/selectionTdNode/expandTdNode branches, expanded-row tr emission,
   use-check/use-expand pure pipeline (checkedRowKeys algebra, expandedRowKeys),
   mergedSortStates selection gate, module divergence notes.
2. `src/NUI/Checkbox.elm` — privateInsideTable equivalent (design pending upstream bytes).
3. `src/NUI/Radio.elm` — `name` attr if BodyRadio needs it (pending upstream bytes).
4. `examples/src/Main.elm` (single-file catalog; data-table section ~:4510, b1/b2 demos
   + divergence blurb at :4559 — b3 extends the section), `tests/src/Main.elm`,
   `tests/inspect.mjs` (test commit).
5. NO manifest/check-dom/css/theme touches (prep no-op).

## Open items — RESOLVED by the in-context upstream recon (see data-table-b3-upstream.md)
- selection th/td + expand td/expanded-tr DOM trees + class bytes: §4 (th `--selection`
  BETWEEN `--sortable`/`--last`; td `--selection`/`--expand` BETWEEN align and `--last-col`).
- use-check algorithm: §2 (flat-data derivation; header state current-page only).
- use-expand: §3 (no auto column; pure toggle; caller declares the expand column).
- SelectionMenu: §4 (trigger icon at-rest; menu body = caller runtime per Dropdown house pattern).
- privateInsideTable: **pure class effect** `n-checkbox--inside-table` (css:1466) —
  Checkbox.Options gains a Bool; NO theme/var story. Plan risk-table item CLOSED.
- BodyRadio `name`: lands on inner `<input class="n-radio-input">` upstream; our Radio
  port renders no input (radio-batch accepted edge) → inherited edge, document.
- data-col-key sentinels `__n_selection__`/`__n_expand__` (utils.ts getColKey) — th/td/
  colgroup identity.
- spec walk-test bytes: §6 (4 blocks).
- Expanded tr: `n-data-table-tr n-data-table-tr--expanded` + single td (base + ALWAYS
  `--last-col` + cond `--last-row` over TILED rows, colspan=colCount, no data-col-key/style).

## Still-open feat decisions (upstream recon §8)
Column-kind shape, Checkbox shift-click callback, stickyExpandedRows width story,
renderExpandIcon slot, one-channel emits, caller-owned lastSelectedKey.
