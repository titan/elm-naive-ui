# B3 upstream recon — selection + expand (in-context, orchestrator; explorer lane
# died on the repeat-call guard again — stale cross-session counter, search_code refused)

Upstream: naive-ui v2.45.3, mirror /tmp/next-upstream/data-table. All quotes are exact bytes.
Cross-checked against tasks/recon/data-table-subsurfaces.md §1/§2 (consistent).

## 1. Surface map (new classes/attrs/elements, byte-exact)
- `n-data-table-th--selection` — selection th modifier, class-array position BETWEEN
  `--sortable` and `--last` (Header.tsx:332-340; `--filterable` sits between sortable and
  selection upstream — b5).
- `n-data-table-td--selection` / `n-data-table-td--expand` — td modifiers, position BETWEEN
  the align class and `--last-col` (Body.tsx:920-927).
- `n-data-table-tr--expanded` — on the EXPANDED extra tr AND on the PARENT tr when its key
  ∈ merged expanded set (Body.tsx:759-761, 1043-1046; parent class order: base → `--summary`
  → `--striped` → `--expanded` → rowClassName → props.class; css has NO selector for it —
  class is emitted unstyled).
- `n-data-table-expand-trigger` + `--expanded` (ExpandTrigger.tsx:37-44), css rotate(90deg).
- `n-data-table-check-extra` — SelectionMenu trigger icon class (SelectionMenu.tsx:129-138).
- `n-data-table-expand` — sticky wrapper div `style={width: bodyWidthPx}` (Body.tsx:771-779).
- `n-checkbox--inside-table` — via NCheckbox `privateInsideTable` (Checkbox.tsx:350-362,
  class order base → `--rtl` → `--checked` → `--disabled` → `--indeterminate` →
  `--inside-table` → `--show-label`). Rule already in css/naive-ui.css:1466
  (`.nui-root.nui-root .n-checkbox.n-checkbox--inside-table .n-checkbox-box`). NO theme-var
  effect — pure class. THIS CLOSES the plan risk-table item.
- `n-data-table-expand-placeholder` — TREE-data only (leaf indent filler, Body.tsx:940-947);
  flat b3 never emits it.
- data-col-key sentinels: `__n_selection__` / `__n_expand__` (utils.ts getColKey:49-55) —
  used by th/td/colgroup col identity everywhere col.key would go.
- Icons (both `viewBox="0 0 16 16" fill="none" xmlns`, path `fill="currentColor"`, wrapped
  in `<i class="n-base-icon">` per NBaseIcon/Icon.tsx:32-33):
  - ChevronRight (ExpandTrigger): path d = EXACTLY `NUI.Dropdown.chevronRightPath`
    (verified byte-identical, Dropdown.elm:513).
  - ChevronDown (SelectionMenu): d = `M3.14645 5.64645C3.34171 5.45118 3.65829 5.45118
    3.85355 5.64645L8 9.79289L12.1464 5.64645C12.3417 5.45118 12.6583 5.45118 12.8536
    5.64645C13.0488 5.84171 13.0488 6.15829 12.8536 6.35355L8.35355 10.8536C8.15829
    11.0488 7.84171 11.0488 7.64645 10.8536L3.14645 6.35355C2.95118 6.15829 2.95118
    5.84171 3.14645 5.64645Z` (ChevronDown.tsx).

## 2. use-check.ts (215 L) — algorithm, ordered
- sourceKeys = controlled `checkedRowKeys` ?? uncontrolled (default `[]`).
- multiple===false (selection column): `{checkedKeys: sourceKeys.slice(0, 1),
  indeterminateKeys: []}` — NO treemate pass, order preserved, bogus keys survive display?
  (slice of source; set.has() row check makes only matching rows checked).
- else treemate `getCheckedKeys(sourceKeys, {cascade: props.cascade (DEFAULT TRUE),
  allowNotLoaded: allowCheckingNotLoaded (default false)})`. FLAT-DATA DERIVATION (treemate
  source NOT in the checkout — node_modules absent): every row is a leaf → indeterminate
  ALWAYS []; checkedKeys = data-order filter of sourceKeys' members (tree-walk collection
  drops unknown keys, reorders to data order). Pins derive from THIS rule; if a gate pin
  disagrees, re-derive before touching the port.
- Header state (CURRENT PAGE ONLY, over paginatedDataRef):
  countChecked = Σ paginated rows (!disabled && checkedSet.has(key));
  countDisabled = Σ paginated rows disabled;
  someRowsChecked = (0 < countChecked < length−countDisabled) || any paginated key ∈
  indeterminateSet (flat: never);
  allRowsChecked = countChecked ≠ 0 && countChecked = length−countDisabled;
  headerCheckboxDisabled = paginatedData.length === 0.
  (disabled from selectionColumn `disabled(row)` — SINGLE arg, interface.ts:317.)
- doUpdateCheckedRowKeys(keys, row?, action): rows = keys.map(k => getNode(k).rawNode)
  (resolved over ALL data); fires 3 channels with (keys, rows, {row, action}); sets
  uncontrolled. Port: ONE channel `onUpdateCheckedRowKeys : Maybe (List String -> List row
  -> CheckAction-ish -> msg)` — b2 one-channel precedent; document.
- doCheck(rowKey, single=false, rowInfo): `loading` gate (b4 prop — no-op until then);
  single → emit (Array? slice(0,1) : [rowKey]) — REPLACES, no merge; else emit
  treemate.check(key, merged).checkedKeys (flat: Set-union order = merged order then
  appended new keys; uncheck preserves order minus key).
- doUncheck(rowKey, rowInfo): treemate.uncheck → merged − key(s).
- doCheckAll(checkWholeTable=false): column-null + loading gates; keys =
  (wholeTable ? ALL treeNodes : paginatedData).filter(!disabled).map(key); emit
  treemate.check(keys, merged, {cascade:true}).checkedKeys, row=undefined,
  action='checkAll'. NOTE cascade FORCED true ("always cascade, to emit correct row keys").
- doUncheckAll: symmetric, action='uncheckAll'.
- Click handlers:
  - Header checkbox (Header.tsx:115-122): allRowsChecked ? doUncheckAll() : doCheckAll()
    — NO arg → current page only.
  - Body checkbox (Body.tsx:227-270): shiftKey && lastSelectedKey≠'' → range
    [min(last,cur)..max] over paginatedData (disabled filtered), checked ? doCheck(keys)
    : doUncheck(keys); else checked ? doCheck(key) : doUncheck(key). lastSelectedKey is
    component-instance mutable, init '' — CALLER-OWNED state in the port.
  - Body radio (Body.tsx:272-279): doCheck(key, single=true) — replace with [key]; a
    checked radio cannot be unchecked (no uncheck path in single mode).

## 3. use-expand.ts (83 L)
- renderExpand/expandable read from the FIRST `type==='expand'` column (dev-warn when
  renderExpand missing — caller error, port: nothing to render).
- NO auto-inserted expand column — the caller DECLARES `{type:'expand'}` in columns.
- merged expanded keys: controlled `expandedRowKeys` ?? uncontrolled (defaultExpandedRowKeys;
  `defaultExpandAll` seeds ALL expandable keys — flat: all rows passing expandable, else all).
- doUpdateExpandedRowKeys fires 2 channels + sets uncontrolled.
- toggle (Body.tsx:292-305): loadingKeySet guard (tree-async only — flat: never set);
  index∈merged → splice out; else push (tree branch with onLoad async — OUT of flat scope).
  Port: pure toggle in/out preserving order.

## 4. DOM trees
### Selection th (Header.tsx:233-249, 316-355)
- th attrs: SAME as basic th (colspan/rowspan 1, data-col-key=`__n_selection__`, style from
  column width/align), class chain with `--selection` inserted; onClick ABSENT
  (gate `type !== 'selection' && type !== 'expand'`, :345).
- Content when `multiple !== false`: FRAGMENT [ NCheckbox(privateInsideTable,
  checked=allRowsChecked, indeterminate=someRowsChecked, disabled=headerCheckboxDisabled,
  onUpdateChecked=headerToggle) , checkOptions ? <SelectionMenu/> : null ] — NO
  title-wrapper divs. `multiple === false` → th content is NULL (empty th).
### Selection td (Body.tsx:951-974)
- td attrs same as basic (style carries text-align/width + `--indent-offset:` seed,
  data-col-key=`__n_selection__`), class chain with `--selection`; content:
  multiple===false ? RenderSafeRadio : RenderSafeCheckbox — NO wrapper element.
- BodyCheckbox.tsx: NCheckbox privateInsideTable, disabled=tmNode.disabled
  (= selectionColumn.disabled(row)), indeterminate=indSet.has(key), checked=chkSet.has(key),
  onUpdateChecked=(checked,e)=>handleCheckboxUpdateChecked(tmNode, checked, e.shiftKey).
- BodyRadio.tsx: NRadio name={componentId} (= `createId()` counter, first instance "1" —
  same value as the b1 `data-n-id "1"` decision), disabled, checked=chkSet.has(key),
  onUpdateChecked=()=>handleRadioUpdateChecked(tmNode). Upstream `name` lands on the inner
  `<input class="n-radio-input">` (Radio.tsx:126-128) — OUR Radio port renders NO input
  (radio-batch accepted edge) → data-table INHERITS the edge, document (DOM otherwise equal).
### Expand td (Body.tsx:975-990)
- Content: `!expandable || expandable(rowData)` ? ExpandTrigger : null (td + `--expand`
  class ALWAYS present, even when trigger suppressed — spec pins 5 `td--expand` with
  expandable on 1/5 rows). ExpandTrigger onClick → toggle(key). No wrapper element.
### ExpandTrigger (ExpandTrigger.tsx:37-74)
```
div.n-data-table-expand-trigger[.n-data-table-expand-trigger--expanded]
  onClick=toggle; onmousedown=preventDefault
  └─ i.n-base-icon
       └─ svg[viewBox="0 0 16 16" fill="none" xmlns="..."] > path[d=chevronRightPath,
          fill="currentColor"]
```
  (NIconSwitchTransition at rest = child only; `loading`/NBaseLoading and `renderExpandIcon`
  slots exist upstream — loading is tree-async (out), renderExpandIcon is a table-level
  renderable slot: model as Maybe or defer, feat decision.)
### Expanded extra row (Body.tsx:756-784)
```
tr.n-data-table-tr.n-data-table-tr--expanded
  └─ td.n-data-table-td.n-data-table-td--last-col[.n-data-table-td--last-row
       iff displayedRowIndex+1 === rowCount]  colspan=colCount
       └─ stickyExpandedRows
          ? div.n-data-table-expand[style="width:{bodyWidthPx}px"] > renderExpand(row, index)
          : renderExpand(row, index)
```
  NO data-col-key / style / `--indent-offset` on this td; colspan = leaf column count.
  renderExpand receives the PARENT row and the parent's paginated index.
- Tiling (Body.tsx:686-705): after pagination, per displayed row — if `renderExpand &&
  expandedSet.has(key) && (!expandable || expandable(row))` push an `{isExpandedRow}`
  entry AFTER the parent; rowCount/last-row math over the TILED list; parent tr
  `--expanded` = expandedSet.has(rowKey) — NOT gated by expandable (byte-faithful quirk:
  an unexpandable row whose key is in the set gets the class but no child row).
### SelectionMenu (SelectionMenu.tsx)
- Rendered in the selection th IFF `checkOptions` (column `options`) non-empty.
- Trigger (default slot): `i.n-base-icon.n-data-table-check-extra` > ChevronDown svg.
- Menu: NDropdown options = options.map: 'all' → {label: locale.checkTableAll, key:
  '_n_all__'}, 'none' → {label: locale.uncheckTableAll, key: '_n_none__'}, objects pass
  through. enUS bytes: 'Select all in the table' / 'Unselect all in the table'
  (locales/common/enUS.ts:55-56).
- onSelect(key): '_n_all__' → doCheckAll(true) WHOLE TABLE; '_n_none__' → doUncheckAll(true);
  else custom option with key → option.onSelect(rawPaginatedData) (page rows payload).
- OUR NUI.Dropdown renders the MENU BODY only (popover house pattern) → at-rest table DOM =
  the trigger icon; open/close + positioning is CALLER RUNTIME (like other popover
  surfaces). Port: expose options as data + the all/none action channel in Options; menu
  body via NUI.Dropdown by the caller.

## 5. API additions (upstream interface.ts:77-165, 259-366)
- TableProps: defaultCheckedRowKeys=[] , checkedRowKeys?, defaultExpandedRowKeys=[],
  defaultExpandAll=false, expandedRowKeys?, stickyExpandedRows=false,
  allowCheckingNotLoaded=false, cascade=true, renderExpandIcon? (table-level),
  onUpdate×(3 checked channels / 2 expanded channels) — port one channel each (b2 precedent).
- TableSelectionColumn: {type:'selection', multiple?=true, disabled?:(row)=>boolean,
  options?: DataTableSelectionOptions} (sorter/filter/colSpan/rowSpan are `never`).
- TableExpandColumn = Omit<TableSelectionColumn,'type'> & {type:'expand', title?:
  string|(col)=>VNodeChild, renderExpand:(row,index)=>VNodeChild REQUIRED,
  expandable?:(row)=>boolean}.
- DataTableSelectionOptions = Array<'all'|'none'|{label, key, onSelect:(pageData)=>void}>.
- Column key: getColKey sentinel for selection/expand (col.key meaningless for them).

## 6. Spec transcription (tests/DataTable.spec.tsx — the only walk-test ground truth)
- :961 `on-update:checked-row-keys`: cols [selection, Name/name], rows {name:0},{name:1},
  rowKey=name, onUpdateCheckedRowKeys spy. Click FIRST `.n-checkbox` (= the header's —
  header renders before body) → spy called. (Payload not asserted.)
- :1479 `renderExpand` `expandable`: cols [expand{expandable: name===0, renderExpand:
  `${name} is a good guy.`}, Name/name render `${name}-${rowIndex}`], 5 rows name 0-4,
  rowKey=name. Pins: 5× `td--expand`; first tbody td data-col-key CONTAINS `__n_expand__`,
  class CONTAINS `n-data-table-td--expand`; click trigger[0] → 6 tbody trs;
  `tbody [colspan="2"]` text CONTAINS '0 is a good guy.'.
- :1595 `column.multiple`: selection multiple:false + Name, 5 rows {name, key}=index,
  NO rowKey prop (upstream default = row.key), controlled checkedRowKeys=[4,1].
  Pins: radios[4] has `n-radio--checked`, radios[1] NOT (slice(0,1)); click radios[1] →
  radios[1] checked, radios[4] NOT.
- :1648 selection extra menu: selection options ['all','none'], 2 rows key 1/2, rowKey=key.
  Pins: `.n-data-table-check-extra` exists; Dropdown select 'all' → no error (handler
  no-ops — 'all' ≠ '_n_all__'; only proves render + handler don't throw).
- default rowKey: `row => row.key` (interface) — our Options keeps caller-owned rowKey
  (b1 house pattern).

## 7. Theme seams
- privateInsideTable: NO var changes — class-only (closes the risk-table question).
- SelectionMenu NDropdown theme peers: upstream passes
  `theme.peers.Dropdown` overrides — our Theme has no peers mechanism; NUI.Dropdown takes
  Theme directly. No DOM/var delta at defaults; document as inherited house edge.
- Checkbox/Radio inside table render with their OWN theme vars (checkbox/radio vars) —
  unchanged from the standalone ports (plus the `--inside-table` class for checkbox).

## 8. Open items / decisions for feat
1. Column kind field: flat `kind : ColumnKind`(Normal|Selection|Expand) + optional
   selection/expand fields on Column (multiple/disabled/options/renderExpand/expandable) —
   keeps b1/b2 pins compiling; TS `never` fields become "ignored-if-set" (document).
2. Checkbox shift-click range: our `onCheck : Bool -> msg` lacks the event. Options:
   (a) add `Bool -> Bool -> msg` variant field (checked, shiftKey) used by the table;
   (b) accepted-edge the shift range. Feat decision (lean (a) — expressible, byte-backed).
3. stickyExpandedRows: needs runtime-measured bodyWidth (upstream). Options: (a) port flag
   + caller-supplied width input; (b) defer with documented edge. Lean (a) as
   `stickyExpandedRows : Bool` + width from a `Maybe Int` field, else (b).
4. renderExpandIcon table-level slot: port as Maybe field or defer (lean port — renderable).
5. `loading` gates: no-op until b4 (Options lacks loading) — note in divergences.
6. lastSelectedKey: caller-owned state (like page/defaultSortOrder seeds, b2 precedent).
7. Emit key ORDER follows the treemate-derived rule in §2 (merged-order-then-appended for
   check; filtered-data-order for display merge) — if a derived pin goes RED, re-derive
   from the rule FIRST (b1/b2 lesson: expectation bytes, not port bugs).
