# TreeSelect — upstream + wiring recon (single batch)

Upstream v2.45.3 at `/home/titan/Works/elm/naive-ui/src/tree-select/`
(1129 L TreeSelect.tsx + 28 L utils.ts + 130 L interface.ts + 58 L
styles/index.cssr.ts + 61 L styles/light.ts + 17 L dark.ts + 19 L rtl.ts
peer-only). Mirror to `/tmp/next-upstream/tree-select/` before editing.

The port = the `NUI.Select` / `NUI.Cascader` composition precedent: a
`view` (trigger, `NUI.BaseSelection`) + a caller-mounted `menu` body (the
`.n-tree-select-menu` carrying an embedded `NUI.Tree`), all runtime
(show/positioning/keyboard/clickoutside) caller-owned. `NUI.Tree` already
exposes the whole treemate surface (pattern/filter/showIrrelevantNodes/
checkStrategy/cascade/cancelable/pendingKey/renderLabel/… and pure
`check`/`uncheck`/`toggleExpand`/`toggleSelect`/`getCheckedKeys`/
`getNonLeafKeys`/`flatten`/`filterTree`); it needs FOUR additive internal
seams (below), all defaulting to today's bytes.

## Render surface (TreeSelect.tsx render, :911-1129)

1. Root `div.n-tree-select` — BARE (no vars, no modifiers; `z-index:auto;
   outline:none; width:100%; position:relative` from the stylesheet).
   Contains ONLY the trigger in the port (the VFollower body is the
   separate `menu`).
2. Trigger = NInternalSelection → `NUI.BaseSelection.view` with:
   `status`, `focused`, `selectedOption`→selectedLabel / `selectedOptions`
   →tags (+numeric maxTagCount slice → ellipsisTag), `size`, `bordered`,
   `placeholder`(mergedPlaceholder), `disabled`, `active`(=mergedShow),
   `loading`, `multiple`, `showArrow=true`, `filterable`, `clearable`,
   `pattern`, arrow slot passthrough, `onPatternInput`/`onClear`/
   `onDeleteOption`(→onDeleteTag)/click/keydown handlers. Trigger
   derivation lives in TreeSelect (the `NUI.Select` `baseSelectionOptions`
   precedent; Select's `fallbackOption` dance does NOT apply — a missing
   node simply drops, no value-as-label fallback: `selectedOptionRef`
   returns null when `treeMate.getNode` misses).
3. Menu body (returned by the port's `menu`, caller-mounted):
   - `div.n-tree-select-menu` (+`menuProps.class`), `tabindex=0`
     (hardcoded), `style` = 11 cssVars (order below), handlers
     mousedown/keydown/focusin/focusout = caller-owned.
   - iff header slot: `div.n-tree-select-menu__header` with `data-header`
     attribute, children = slot.
   - NTree with: `blockLine`, `allowCheckingNotLoaded`, 
     `showIrrelevantNodes=false`, `animated=false`, `pattern`,
     `getChildren`(not portable — fixed record fields, Cascader note),
     `filter`(mergedFilter), `data=options`, `cancelable=multiple`,
     `defaultExpandAll`/`defaultExpandedKeys`/`indent`, `expandedKeys`,
     `checkedKeys=treeCheckedKeys`, `selectedKeys=treeSelectedKeys`,
     `checkable`, `checkStrategy`, `cascade=mergedCascade`, `leafOnly`,
     `multiple`, `showLine`, renderLabel/renderPrefix/renderSuffix/
     renderSwitcherIcon/nodeProps passthrough, `watchProps`(runtime,
     caller-owned), `virtualScroll = consistentMenuWidth && virtualScroll`
     (PUNTED — below), `overrideDefaultNodeClickBehavior` (behavior-only),
     `internalTreeSelect` `internalUnifySelectCheck` `internalScrollable`
     `internalScrollablePadding=menuPadding` `internalFocusable=false`
     `internalCheckboxFocusable=false`, `internalRenderEmpty` →
     `div.n-tree-select-menu__empty` > NEmpty (NO `n-tree__empty` class
     here — plain `NUI.Empty.defaults`, no attributes), `onLoad`
     (caller-owned), the three onUpdate* channels.
   - iff action slot: `div.n-tree-select-menu__action` with `data-action`.
   - NBaseFocusDetector → inert sentinel `div[style=width:0;height:0]
     [tabindex=0]` (the Cascader `focusDetectorNode` bytes).
   - The Transition wrapper is `fade-in-scale-up-transition` (class seam
     `I.transitionClass`, the Select menu precedent) and `onLeave` clears
     pattern (caller-owned).
   - EMPTY CASE: upstream Tree.tsx render `if (!fNodes.length &&
     internalRenderEmpty) return internalRenderEmpty()` — the `__empty`
     div REPLACES the whole tree (no `.n-scrollbar`, no `.n-tree` root at
     all; the menu div directly contains `__empty`). "fNodes empty" =
     `Tree.flatten expandedKeys (filterTree pattern …).tree == []` — i.e.
     filtered-empty shows `__empty` even when options exist.

## The tree inside the menu — DOM bytes (Tree.tsx :1855-1885)

Upstream default (`consistentMenuWidth && virtualScroll` = true) takes the
VVirtualList branch — windowing is runtime, port punts it (Cascader
precedent: "virtual only adds the `--virtual` width class; the full column
renders"; the port Tree docstring already declares "the virtual-list branch
(plain wrapper path only)"). The port pins the **internalScrollable
branch** bytes (= upstream's `consistentMenuWidth=false, virtualScroll=
false` config), full node list:

    div.n-scrollbar.n-tree.n-tree--block-node.n-tree--block-line
         [.n-tree--checkable iff checkable] [.n-tree--ellipsis iff ellipsis]
      style = Tree's 18 own vars         (tabindex ABSENT — internalFocusable
                                         false ⇒ mergedFocusable false)
      └─ div.n-scrollbar-container       (NUI.Scrollbar structure)
         └─ div.n-scrollbar-content
              style = `padding:4px`      (contentStyle = internalScrollable
                                         Padding = theme menuPadding)
              └─ div                     (the attribute-less selfElRef wrap)
                 └─ n-tree-node-wrapper rows (NUI.Tree rows as-is)

`.n-tree` rides ON the scrollbar root via class fallthrough (NxScrollbar
own root class + `class=treeClass` merge). `cB('tree', 'max-height:
var(--n-menu-height)')` — from tree-select's OWN cssr, shipped in the
manifest entry. Tree class list order (Tree.tsx :1774-1778): `n-tree`,
`--rtl`, `--checkable`, `--block-node` (`blockLine || blockNode`),
`--block-line`, `--ellipsis` — the port's existing `rootAttributes` order;
NO tabindex when `internalFocusable && not disabled` fails. The per-node
checkbox gets `focusable=false` (TreeNode.tsx :428; default true today).

## cssVars (TreeSelect.tsx :816-845) — 11, exact order

`--n-menu-box-shadow`, `--n-menu-border-radius`, `--n-menu-color`,
`--n-menu-height`, `--n-bezier`, `--n-action-padding`,
`--n-action-text-color`, `--n-action-divider-color`, `--n-header-padding`,
`--n-header-text-color`, `--n-header-divider-color`.

self() (light.ts :98-120, 11 fields): menuPadding `'4px'`, menuColor
popoverColor, menuBoxShadow boxShadow2, menuBorderRadius borderRadius,
menuHeight `calc(${heightMedium} * 7.6)`, actionDividerColor dividerColor,
actionTextColor textColor2, actionPadding `'8px 12px'`, headerDividerColor
dividerColor, headerTextColor textColor2, headerPadding `'8px 12px'`.
Peers: Tree / Empty / InternalSelection (all ported; compose live).
menuPadding is NOT in cssVars — it flows to the tree's
internalScrollablePadding.

## Derivations (setup, :195-855)

- `treeCheckedKeys` (:304-316): multiple → value if list else []; single →
  value if scalar else [].
- `treeSelectedKeys` (:317-321): `checkable ? [] : treeCheckedKeys`.
- `selectedOption` (:322-342, single): node = getNode(value); miss → null
  (NO fallback). showPath → label = path labels joined separator (default
  `' / '`), value = key, else label = node label.
- `selectedOptions` (:343-375, multiple): `getCheckedKeys(value, {
  checkStrategy, cascade: mergedCascade, allowNotLoaded })` then per key
  getNode (misses DROP), showPath join as above.
- `mergedCascade` (:282-284) = `multiple && cascade && checkable`.
- `mergedFilter` (:249-261): custom filter || `(pattern, node) =>
  !pattern.length || node[labelField].toLowerCase().includes(
  pattern.toLowerCase())`.
- `pendingNodeKey` init (:274-281): checkable → null; else last of initial
  value list (single value → null! only Array non-empty takes the last).
- `mergedCheckStrategy` (tree/src/utils.ts :8-13) = `leafOnly ? 'child' :
  checkStrategy` (leafOnly deprecated).
- `mergedPlaceholder` = placeholder || locale 'Please Select'.
- `uncontrolledExpandedKeys` (:287-291): defaultExpandAll → undefined
  (tree handles); else defaultExpandedKeys || expandedKeys.

## Click algebra — internalUnifySelectCheck is ALWAYS on (render :1064)

Upstream tree-select passes it unconditionally; all interaction flows
through `handleSelect`/`handleCheck` (Tree.tsx :1032-1130) +
`handleUpdateCheckedKeys` (TreeSelect.tsx :535-566) + `handleDeleteOption`
(:617-661) + `handleClear` (:604-616). The port models these as PURE
helpers over `(value, options, props)` (the Transfer `use-transfer-data`
precedent):

- single, any click (line or checkbox or label): value := key, meta
  action 'select' (`doUpdateCheckedKeys([key])` → `keys[0]`, closeMenu;
  cancelable=false ⇒ never unselects). Key node disabled/props disabled →
  no-op.
- multiple + checkable, checkbox or line click: checked' = tree
  check/uncheck(key, displayedCheckedKeys, {cascade: mergedCascade,
  checkStrategy: merged, allowNotLoaded}) — cascade+strategy applied at
  CHECK time; value := checked'.checkedKeys. select-click flips to
  `!(checked || indeterminate)`.
- multiple + !checkable, line click: toggleSelect — value list key in/out
  (cancelable=multiple=true).
- delete tag (multiple): base = `getCheckedKeys(value, {cascade:
  mergedCascade, allowNotLoaded})` — **NO checkStrategy here (treemate
  default 'all')** (:623-629); find key in base (not found → no-op);
  checkable → `uncheck(key, base, {checkStrategy, cascade, allowNotLoaded,
  })` → value := that (:637-649); !checkable → splice the ONE index
  (:651-657).
- clear: multiple → `[]`, single → `null` (`Value` single Nothing);
  single+filterable closes menu first (caller runtime).
- After a multiple check, `clearFilterAfterSelect` (default true) resets
  pattern — caller runtime.
- `doUpdateValue` collapse (:390-417): one channel
  `onUpdateValue : Maybe (Value -> msg)` (Transfer one-channel precedent);
  option/meta payloads are Vue-side niceties the caller reconstructs from
  value+options (document). Separate channels: `onUpdateShow : Maybe (Bool
  -> msg)`, `onUpdateExpandedKeys : Maybe (List String -> msg)`,
  `onUpdateIndeterminateKeys : Maybe (List String -> msg)`
  (:418-475).

`Value` = `SelectMenu.Value` collapse (`Single (Maybe String) | Multiple
(List String)`) — the Select precedent; keys are Strings (RowKey collapse,
Select limitation note).

## Tree.elm delta — four ADDITIVE seams (defaults = today's bytes)

1. `internalFocusable : Bool` (default True) — gates the root `tabindex 0`
   (`mergedFocusable = internalFocusable && !disabled`).
2. `internalCheckboxFocusable : Bool` (default True) — the per-node
   checkbox `focusable` (TreeNode.tsx :428).
3. `internalScrollable : Bool` (default False) +
   `internalScrollablePadding : String` (default `"0"`) — the scrollbar
   wrap branch above (classes+vars move onto the `NUI.Scrollbar` root,
   contentStyle = padding, nodes under an attribute-less inner div).
   Existing `attributes` keep landing on the root in both branches.
4. `renderEmpty : Maybe (Element msg)` (default Nothing) — whole-render
   REPLACEMENT when no visible nodes (upstream `internalRenderEmpty`;
   distinct from `empty`, which renders inside the root).

No behavior change for existing callers; the gate must stay green with
only these additions (prep commit).

## Tooling / wiring

- `tools/manifest.mjs`: entry `tree-select` after `transfer` — cssr
  `['tree-select/src/styles/index.cssr.ts']`, theme
  `'tree-select/styles/light.ts'`. rtl.ts is `c([])` peer-only (peers =
  InternalSelection/SelectMenu/Tag/Scrollbar/Tree, all in their own
  chunks) — NO own rules, no rtl.cssr entry needed (check how the
  extractor treats it; if `npm run extract` wants it listed, add
  `'tree-select/styles/rtl.ts'` — it contributes zero rules either way).
- `cd tools && npm run extract` → css/naive-ui.css + NUI/Css/Generated.elm
  + tools/generated/*.json (never hand-edit).
- `elm.json` exposed-modules += `NUI.TreeSelect` (check-exposure).
- `tools/verify/check-dom.mjs` targets: `'.n-tree-select'`,
  `'.n-tree-select-menu'` at the tail.
- check-classes ALLOW: likely nothing new (all emitted classes have rules:
  root/menu/__header/__action/__empty + scrollbar/tree families already
  shipped). Verify at test time.
- Theme module `NUI/Theme/TreeSelect.elm` is GENERATED (11 self vars).
- Tests: `tests/src/Main.elm` fixtures (`treeSelectOptions`,
  `treeSelectLive*` after the transfer fixtures), live views
  `live-tree-select*` after `live-transfer*`, eq pins at the checks tail,
  `tests/inspect.mjs` probe block just before `// --- report`.

## Not ported / caller-owned (module docstring bullets)

show/positioning/clickoutside/keyboard (Enter/Escape/ArrowDown +
`treeHandleKeydown`), `to`/`placement`/`consistentMenuWidth` (follower
width — caller wrapper), virtualScroll windowing (Cascader punt), the
`fade-in-scale-up-transition` phases (class seam), `watchProps`, `onLoad`
async (loadingKeys data), `getChildren` (fixed record fields), `renderTag`
+ `ellipsisTagPopoverProps` + responsive maxTagCount (numeric slice =
static seam, Select/Cascader precedent), IME, focus return orchestration,
`leafOnly` (deprecated — folds into checkStrategy='child'),
`overrideDefaultNodeClickBehavior` (behavior-only), `menuProps.style`
(raw `style` string — `attributes` covers attrs; document).

## Path map (subagents; ALWAYS absolute, use_worktree=false)

- Upstream: `/home/titan/Works/elm/naive-ui/src/tree-select/src/TreeSelect.tsx`
  (+ `utils.ts`, `interface.ts`, `../styles/`, `../../tree/src/Tree.tsx`
  :1020-1130 + :1740-1935, `../../tree/src/TreeNode.tsx` :360-430,
  `../../tree/src/utils.ts`)
- Port: `/home/titan/Works/elm/elm-naive-ui/src/NUI/{TreeSelect,Tree,
  BaseSelection,Select,Cascader,Scrollbar,Empty,Internal}.elm`,
  `src/NUI/Theme/TreeSelect.elm` (generated),
  `/home/titan/Works/elm/elm-naive-ui/tools/manifest.mjs`,
  `tools/verify/check-{dom,classes,theme,exposure}.mjs`,
  `/home/titan/Works/elm/elm-naive-ui/tests/src/Main.elm`,
  `/home/titan/Works/elm/elm-naive-ui/tests/inspect.mjs`
- Gate: `cd /home/titan/Works/elm/elm-naive-ui && ELM_HOME=/tmp/elm-home
  ./scripts/verify.sh`
