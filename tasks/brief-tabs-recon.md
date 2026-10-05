# BRIEF — recon: NUI.Tabs port — write tasks/recon/tabs-1-upstream.md + tasks/recon/tabs-2-elm.md

Workspace: /home/titan/Works/elm/elm-naive-ui @ `20de030` (branch master). READ-ONLY
recon; produce exactly TWO docs:
- /home/titan/Works/elm/elm-naive-ui/tasks/recon/tabs-1-upstream.md
- /home/titan/Works/elm/elm-naive-ui/tasks/recon/tabs-2-elm.md

Goal: full map for a `feat(tabs)` port of naive-ui v2.45.3 Tabs into NUI.Tabs,
following the house conventions (see docs/ARCHITECTURE.md + recent exemplars
src/NUI/TimePicker.elm, src/NUI/DatePicker.elm, and inline-composite exemplars
src/NUI/Collapse.elm / src/NUI/Menu.elm — Tabs has NO overlay, it is an inline
composite: nav row + pane area rendered together).

Upstream (read-only mount): /home/titan/Works/elm/naive-ui/src/tabs/
- src/Tabs.tsx (1379 L; tabsProps :70-127), src/Tab.tsx (165 L),
  src/TabsButton.tsx (98 L), src/TabPane.tsx (83 L), src/interface.ts (51 L),
  src/public-types.ts, src/styles/index.cssr.ts (+ rtl.cssr.ts),
  styles/_common.ts, styles/light.ts, styles/dark.ts (note the split:
  cssr under src/tabs/src/styles/, theme under src/tabs/styles/ — manifest
  entry pattern: cssr 'tabs/src/styles/index.cssr.ts', theme
  'tabs/styles/light.ts'; check how tools/manifest.mjs handles rtl — mirror
  whatever neighbors do, do NOT invent).
Also read demo props usage under /home/titan/Works/elm/naive-ui/src/tabs/demos
for which prop combos are canonical (segment demos, justify, placement).

## tabs-1-upstream.md — upstream map (byte-read, cite file:line)
1. **Props table**: every tabsProps entry (Tabs.tsx:70-127) + deprecated ones
   (labelSize, activeName, onActiveNameChange — mark DEPRECATED, port = skip)
   + TabPane props (displayDirective? disabled? tab slot) + what Tab.tsx and
   TabsButton.tsx render (class inventories incl. `.n-tabs-tab` anatomy:
   __label/__close/pad elements, --disabled/--active modifiers).
2. **DOM inventory**: exact class tree for one n-tabs instance: `.n-tabs
   .n-tabs--{type}` (bar|line|card|segment) + `.n-tabs--{placement}` (top|
   right|bottom|left|start|end) + padding/size modifiers, nav scroll
   structure (.n-tabs-nav, .n-tabs-nav-scroll-wrapper, .n-tabs-nav__prefix/
   __suffix, .n-tabs-wrapper, .n-tabs-pad, .n-tabs-tab-pad), pane area
   (.n-tabs-pane-wrapper, .n-tabs-pane, --active), segment extras
   (.n-tabs-rail? .n-tabs-caps? — find actual segment classes), add button,
   scroll buttons (.n-tabs-nav__fast-forward/__fast-backward?), resize
   sentinel. For EACH class: which cssr rule(s) style it + the `--n-*` vars
   consumed (from index.cssr.ts + light.ts/_common.ts, exact var list).
3. **Type/variant interaction**: what changes between bar/line/card/segment
   (bar element vs rail, pane borders, tab paddings, justify handling);
   placement rotation (left/right — flex-direction changes, bar side);
   size small/medium/large deltas; animated effects (bar transition CSS,
   pane-wrapper translateX) — cite the cssr keyframes/transition rules.
4. **JS-runtime behaviours** (list, mark STATIC-PORT implications): bar width/
   position measured from DOM (barWidth prop override), scroll buttons
   visibility from overflow measurement, centerActiveTab scrolling,
   trigger=hover activation, beforeLeave async guard, add/close handlers,
   syncBarPosition inst method. For each: propose static-render stance
   (caller-owned: prop-provided / inert-but-rendered / omitted) consistent
   with README "Notes / limitations" and how TimePicker/DatePicker handled
   the analogous cases (view/menu split docs).
5. **Class/cssr gotchas for the gates**: classes emitted by TSX that have NO
   cssr rule (→ future check-classes.mjs ALLOW entries — cite the upstream
   line emitting them), and cssr rules whose selectors the static port will
   never emit (fine, class coverage checks emitted ⊆ css).

## tabs-2-elm.md — Elm design map (mirror TimePicker/DatePicker doc style)
1. **Module shape**: NUI/Tabs.elm — Settings record (field-for-field from
   props table, Elm-typed: TabsType/Placement/JustifyContent enums → where do
   they live? NUI.Types vs local — check precedent: Select/Cascader put
   shared enums in NUI.Types, component-local ones local; recommend), Pane
   record (name : String, label : Element msg, closable/disabled : Bool,
   content : Element msg — map TabPane slots), Msg set (ActivateTab String |
   CloseTab String | AddTab — caller-owned state like Select's onSelect),
   view : Theme -> Settings -> List Pane -> Element msg (+ paneWrapper attrs?).
   No overlay → NO menu/panel split, NO focusDetector, NO transition phase —
   confirm this against how Collapse/Menu are shaped (cite their signatures).
2. **Internal bridge usage**: how NUI.Internal class/--n-* helpers apply
   (cite exact helper names used by DatePicker for var attachment + class
   list emission), theme var exposure path (NUI.Theme.Tabs? check how
   generated theme modules expose per-component vars — e.g. NUI.Theme's
   time-picker vars entry), and the generated-CSS consumption of
   .nui-root.nui-root scoping.
3. **Examples plan**: examples/src/Main.elm section — which demo variants to
   render (line, card, bar, segment ×2 placements minimum, justify, closable
   + addable, sizes, disabled pane) mirroring the DatePicker examples block
   structure; each becomes a check-dom.mjs target.
4. **check-dom/check-classes targets**: concrete probe list (per demo:
   expected class tree + key --n-* values from light.ts defaults) and any
   predicted ALLOW entries (from tabs-1 §5).
5. **Test pins candidates**: pure helpers worth pinning eq-style in
   tests/src/Main.elm (enum → class-string mapping, justify → CSS value,
   placement → modifier class, settings→attr list builders) + DOM probes for
   tests/inspect.mjs. Note: pins must be derived from upstream BYTES before
   any port module is read (pins-first protocol, tasks/brief-test.md) — this
   section only LISTS candidates + upstream byte sources.
6. **Risk list**: anything where static rendering loses fidelity (bar
   animation, pane transitions, scroll), with the house stance cited.

Tool hygiene: the repeat-call guard KILLS sessions issuing identical
repeated tool calls — batch reads, vary queries, never re-read a file with
the same query twice. Keep both docs dense (tables over prose), cite
file:line for every claim. End tabs-2 with a proposed commit sequence
(prep/feat/test/fix) sized like the time-picker batch.
