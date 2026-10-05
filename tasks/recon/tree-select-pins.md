# TreeSelect — pins (derived from upstream bytes BEFORE the port)

Derivation doc — where these slip, the BYTES win (re-derive before
touching the port; a RED that survives byte re-derivation is a port bug).
Upstream: `TreeSelect.tsx :816-845` (vars), `:911-1129` (render),
`Tree.tsx :1774-1778` (tree classes), `:1855-1885` (internalScrollable
branch), `:1749-1753` (renderEmpty replace). Light common: borderRadius
`3px`, heightMedium `34px`, textColor2 `rgb(51, 54, 57)`, dividerColor
`rgb(239, 239, 245)`, popoverColor `#fff`, boxShadow2 `0 3px 6px -4px
rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px
rgba(0, 0, 0, .05)`, cubicBezierEaseInOut `cubic-bezier(.4, 0, .2, 1)`
(Common.elm :121).

## P1 — menu vars (11, cssVarsRef order, light)

`--n-menu-box-shadow:0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0
rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05);--n-menu-border-
radius:3px;--n-menu-color:#fff;--n-menu-height:calc(34px * 7.6);--n-bezier:
cubic-bezier(.4, 0, .2, 1);--n-action-padding:8px 12px;--n-action-text-
color:rgb(51, 54, 57);--n-action-divider-color:rgb(239, 239, 245);--n-
header-padding:8px 12px;--n-header-text-color:rgb(51, 54, 57);--n-header-
divider-color:rgb(239, 239, 245)` — `renderVars` form (`k:v` joined `;`,
no spaces, no trailing). menuHeight = `calc(${heightMedium} * 7.6)` with
heightMedium=`34px` → **`calc(34px * 7.6)`** (space around `*`, upstream
template literal). menuPadding `4px` is NOT among them (flows to the
tree's scrollbar contentStyle instead).

## P2 — trigger root

`div.n-tree-select` — NO style attribute, NO extra classes; exactly one
child = the `.n-base-selection` tree (BaseSelection bytes, pinned there).
Bare: `hasAttribute('style') === false`.

## P3 — trigger derivation (light, BaseSelection input side)

- single + value `Just "rubber"` + node exists, !showPath → selectedLabel
  `Just "Rubber"`, tags [], showClear per BaseSelection gate
  (`clearable && !disabled && (hover||active) && selected`).
- single + value whose node MISSES (options changed) → selectedLabel
  `Nothing` (NO fallback-to-value label — Select's fallbackOption does
  not exist here).
- single + showPath, path [Outfield, Rubber], separator default → label
  `Outfield / Rubber`; custom separator `" - "` → `Outfield - Rubber`.
- multiple + value [a, b] non-cascade checkable All → tags in
  getCheckedKeys(value,{checkStrategy, cascade:mergedCascade,
  allowNotLoaded}) ORDER, misses dropped. numeric maxTagCount 1 of 3 tags
  → tags[0] + ellipsisTag = Just 2 (Select sliceTags precedent).
- placeholder default `'Please Select'`; `pattern` passthrough byte-for-
  byte into the filter input.

## P4 — menu root

`div.n-tree-select-menu`, `tabindex="0"` (always), style = P1 vars,
classes exactly `n-tree-select-menu` (+ caller transition class via
`I.transitionClass "fade-in-scale-up-transition"` phase, + caller
`attributes`). Child order: [header?] tree-or-empty [action?]
focusDetector — resolveWrappedSlot emits NOTHING when slot absent.

## P5 — header / action slots

Present → `div.n-tree-select-menu__header` with attribute
`data-header="true"` — upstream writes the attr BARE in JSX
(:1012-1015, :1096-1104) and a bare JSX attr compiles to `{true}`, which
`setAttribute` stringifies to `"true"` (the transfer oracle S2 rule:
`aria-hidden` ⇒ `"true"`; `""` is WRONG). Pin
`getAttribute('data-header') === 'true'`. Action →
`div.n-tree-select-menu__action` + `data-action="true"`. NOTE: the older
`NUI.SelectMenu`/`NUI.Cascader` lanes render `""` and only probe
PRESENCE — pre-S2 latent edge, out of this trail's scope (flag in the
plan, don't touch).

## P6 — the embedded tree (non-empty case)

Scrollbar root classes EXACT order: `n-scrollbar` own classes FIRST
(NUI.Scrollbar bytes), then `n-tree`, `n-tree--block-node`,
`n-tree--block-line` (blockLine always on from tree-select), +
`n-tree--checkable` iff checkable, + `n-tree--ellipsis` iff ellipsis (no
option today — Tree.Options has no ellipsis field? if absent, never). NO
`tabindex` on the scrollbar root (internalFocusable=false), NO `n-tree--
rtl` unless rtl. Style attr = Tree's 18 own vars (Tree trail pinned the
list; re-derive only the merged ORDER: scrollbar vars? NO — NxScrollbar
takes `style=cssVars` = the TREE vars only; scrollbar's own vars are NOT
inlined here — VERIFY against NUI.Scrollbar.Options behavior at probe
time; upstream passes only tree cssVars). Structure:

    .n-scrollbar > .n-scrollbar-container > .n-scrollbar-content
      (style="padding:4px") > div (no attrs) > .n-tree-node-wrapper*

Per-node checkbox `focusable=false` (NO tabindex on the checkbox input;
TreeNode.tsx :428). Switcher/indent/content bytes unchanged from the Tree
trail. Pattern filter: `filterTree pattern options` tree +
`showIrrelevantNodes=false` (highlight keys painted, non-matching
branches pruned, expand-to-reveal keys are the CALLER's expandedKeys —
upstream filteredNodes auto-expands; the port Tree's filterTree returns
the reveal keys, caller merges — document).

## P7 — empty case

Options `[]` OR filtered-empty (pattern matching nothing): menu children
= [header?] `div.n-tree-select-menu__empty` [action?] detector — NO
`.n-scrollbar`, NO `.n-tree` anywhere. `__empty` children = port
`NUI.Empty.defaults` render (NO `n-tree__empty` class — that class
belongs to the standalone tree's own empty). Caller `empty` slot replaces
the NEmpty child only (the `__empty` wrapper div always renders).

## P8 — focus detector

Last child: `div` with `style="width:0;height:0"` and `tabindex="0"`
(Cascader focusDetectorNode bytes — pin style string exactly, no spaces
after colons), no class.

## P9 — click algebra (eq pins; pure helpers)

Fixture tree: `o1` (children `o1-1`, `o1-2`, leaf `o1-3` under `o1-1`),
`o2` leaf, `o3` disabled leaf, `o4` (unloaded: isLeaf False, children
Nothing). All with cascade=True, checkStrategy=All, allowNotLoaded=True
unless stated:

1. single, any node click (`o1-1`) → `Single (Just "o1-1")`; click
   `o3` (disabled) → value UNCHANGED.
2. single + checkable, checkbox click on `o1-1` → `Single (Just "o1-1")`
   (unify redirects to select — NOT a cascade check).
3. multiple + checkable + cascade, check `o1` → `Multiple ["o1","o1-1",
   "o1-2","o1-3"]`?? — treemate getCheckedKeys ORDER (document-order
   flatten — derive from the b3 flat-data order rules; the port's
   `check` helper output order IS the pin, cross-checked against
   `getCheckedKeys` of same input). Uncheck `o1-1` → `["o1"]`
   indeterminate not in value.
4. multiple + checkable + cascade + checkStrategy `child`, value =
   ["o1-1","o1-2"] → select-click `o1` (parent, checked||indeterminate
   true → flips OFF) → uncheck("o1") of the extended set → `[]`.
5. multiple + checkable, NON-cascade (mergedCascade false — e.g.
   multiple+cascade but !checkable is moot; use checkable+cascade=False):
   check `o1` → `Multiple ["o1"]` only.
6. multiple + !checkable, select `o1-1` then `o2` → `Multiple
   ["o1-1","o2"]`; re-click `o1-1` (cancelable) → `["o2"]`.
7. delete tag `o1-2` from value ["o1-1","o1-2","o1-3"] (!checkable
   multiple) → base=getCheckedKeys(value,{cascade:mergedCascade}) NO
   strategy, splice index → `["o1-1","o1-3"]`.
8. delete tag `o1-1` from value ["o1-1","o1-2"] (checkable, cascade,
   child) → base = extended (All-strategy normalize: ["o1-1","o1-2"]...),
   uncheck("o1-1", base, {child, cascade}) → derive: child-strategy
   uncheck removes leaf + collapses parents → pin `[]`.
9. delete tag whose key is NOT in base → value UNCHANGED (findIndex -1
   no-op).
10. clear: multiple → `Multiple []`; single → `Single Nothing`.
11. checkStrategy leafOnly=True behaves as `child` (mergedCheckStrategy)
    — eq pin on the helper that exposes the merge.
12. pendingKey init: checkable → Nothing; !checkable + initial value
    ["a","b"] → `Just "b"`; !checkable + single value → Nothing.
13. mergedCascade gates: cascade=True but !multiple → False; multiple+
    cascade but !checkable → False.
14. allowNotLoaded=False + value touching `o4`'s unloaded subtree:
    upstream throws SubtreeNotLoadedError; port stays total (b3 rule) —
    pin the documented total behavior (keep the allowNotLoaded=True set).

## P10 — theme module

`NUI/Theme/TreeSelect.elm` generated with EXACTLY the 11 self fields
(checked by check-theme gate); `vars theme` values = P1 sources.

## Probe plan (tests/inspect.mjs, block just before `// --- report`)

live views `live-tree-select` (single basic), `-multiple` (checkable
cascade tags), `-filterable` (pattern input + filtered tree), `-showpath`
(path labels + custom separator), `-slots` (header+action+empty-slot),
`-empty` (no options → `__empty`), `-maxtagcount` (numeric slice +
ellipsis tag), `-disabled`, `-status`. Probes: P1 style string, P2 bare
root, P4 tabindex+classes, P5 data-header/data-action `=== 'true'`, P6 class
order + padding:4px content style + checkbox no-tabindex, P7 empty
structure absence pins (`querySelector('.n-tree') === null`), P8 detector
bytes, tag label joins (P3) via textContent regex (elm-ui style junk —
never exact equality inside cells).
