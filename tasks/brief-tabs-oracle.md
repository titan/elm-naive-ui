# BRIEF — oracle byte-fidelity audit: NUI.Tabs — Task 2 (READ-ONLY, findings only, no edits)

Role: skeptical independent auditor. Compare the Elm port against naive-ui v2.45.3
byte-for-byte and semantically. Produce a findings report at
/home/titan/Works/elm/elm-naive-ui/tasks/recon/tabs-oracle.md — severity
**S** (spec violation: fix required) or **D** (divergence: document, no fix) —
each with: upstream file:line, port file:line, expected vs actual, and a minimal
fix sketch for S items. Do NOT edit any file. Do NOT re-derive whole files;
audit the targets below plus your own sampling. Keep the report under 300 lines.

Port (Elm): /home/titan/Works/elm/elm-naive-ui @ `20de030` (+README-only docs
commit on top; ignore README) — src/NUI/Tabs.elm (1195 L, view @587, cssVars
@192-238, docstring Divergences block @17-50), src/NUI/Theme/Tabs.elm
(generated, 298 L), examples/src/Main.elm tabsSection @2146, tests/src/Main.elm
-- TABS -- block @2843+, tools/verify/check-dom.mjs:89.
Upstream (read-only mount): /home/titan/Works/elm/naive-ui/src/tabs/ — Tabs.tsx
(1379 L), Tab.tsx, TabsButton.tsx, TabPane.tsx, interface.ts,
src/styles/index.cssr.ts + rtl.cssr.ts, styles/{light,dark,_common}.ts.
Your existing map: tasks/recon/tabs-1-upstream.md (DOM/class/var inventory with
file:line for everything) + tasks/recon/tabs-2-elm.md §6 (port's claimed stance).
AUDIT AGAINST THE BYTES, not against the recon docs — the recon may itself err.

## Mandated audit targets

R1. **Root/nav class algebra.** Root: `n-tabs` + `n-tabs--{type}-type` +
   `{size}-size` + `--flex` iff justify && !card && !segment + `--{placement}`
   (segment forces top, Tabs.tsx:1095) + `--rtl` iff rtl (1099-1107). Nav:
   `n-tabs-nav--{type}-type` + `--{resolvedPlacement}` + `n-tabs-nav`
   (1110-1120). Check every branch of the port's class builder, including
   justify-with-card (must NOT emit flex) and justify-with-segment.
R2. **Nav structure tree.** prefix/suffix emission (1125/1251), scroll wrapper
   vs y-scroll by placement (1202-1221), scroll-padding elements around the
   wrapper (1013-1021, 1066-1071 — rendered with width 0 when tabsPadding=0 or
   skipped? decide what upstream bytes do and what the port does),
   `n-tabs-pad` iff card (1091), `n-tabs-bar` iff !card (1072-1074),
   tab-pad per Tab (index>0 && !justify in {space-between,space-around,
   space-evenly,center,start,end}, Tab.tsx:106-109 + Tabs.tsx:1008-1011).
R3. **Tab anatomy.** wrapper>pad>tab nesting, data-name attr, modifier classes
   order (--active/--disabled/--closable/--addable, Tab.tsx:118-122),
   `__label` span, addable label = height-placeholder + add icon (136-143),
   close button iff mergedClosable && type=card (153-159), mergedClosable rule
   (43-50: add-tab ⇒ false; else tab.closable ?? tabs.closable). Verify the
   port's add-tab button shape (name "__addable", Tabs.tsx:1338-1350) and
   that disabled tabs do not activate but still render data-disabled.
R4. **cssVars.** Exact 32-key set AND emission order vs Tabs.tsx:878-909;
   every createKey selection (size/type keys) vs _common.ts:1-58 +
   light.ts:28-63 mapping: barColor=primaryColor, paneTextColor=textColor2,
   colorSegment=tabColor, tabColorSegment=baseColor, tabBorderRadius=
   borderRadius, close* from common, fontWeightStrong; dark overrides
   colorSegment/tabColorSegment=inputColor (dark.ts:12-18) — does the port's
   Theme path reproduce dark correctly? Also verify tabFontSizeCard is NOT
   emitted (upstream never emits it).
R5. **Pane emission.** displayDirective semantics vs filterMapTabPanes
   (1287-1336): ShowIf → only the active pane node; Show → all pane nodes with
   inactive `display:none` (v-show ⇒ inline style, NOT a class); show:lazy
   documented-not-ported. animated wrapper markup iff animated && placement
   top|bottom (1257-1274). Pane node = `n-tab-pane` + paneClass + paneStyle
   (TabPane.tsx:73-82). Check the port renders NOTHING pane-shaped when there
   are no panes (showPane gate, 1001) — or does the port always render panes?
R6. **Segment body.** rail/capsule/dummy-tab tree (1135-1142), tab-wrapper
   no-pad at index 0 + pad at index>0 (1165-1175), placement forced top on
   BOTH root and nav, no bar/pad/scroll-wrapper/justify.
R7. **Events/attrs.** onChange/onClose/onAdd wiring; trigger Click → onClick,
   Hover → onMouseEnter (Tab.tsx:125); close stopPropagation divergence
   (documented stance, judge D vs S); attrs on the right node (tab div, not
   label span); Elm hover on the tab div vs upstream on the same element.
R8. **Theme/generated-CSS sanity.** NUI.Theme.Tabs vars vs light.ts + _common
   (spot-check 8-10 values incl. all tabPadding/tabGap keyed entries);
   css/naive-ui.css actually contains the tabs rules incl. rtl + segment +
   scroll-button selectors (manifest entry tools/manifest.mjs:274-277).
   Judge whether check-dom's single `'.n-tabs': true` probe is enough or the
   gate needs the stronger probes from tabs-2 §4 (test additions → list as
   findings if gaps are real).
R9. **Sampling.** defaults record vs tabsProps defaults (type=bar, size=
   medium, placement=top, trigger=click, tabsPadding=0, animated=false,
   closable=false, addable=false — Tabs.tsx:76-125); deprecated props
   (labelSize/activeName/onActiveNameChange) truly absent; every claim in the
   port's docstring Divergences block (17-50) is TRUE and COMPLETE (a missing
   divergence = S or D finding); examples tabsSection (Main.elm:2146) renders
   canonical demo variants; existing eq pins in tests/src/Main.elm @2843+ —
   any pin that ENCODES a wrong expectation (vs upstream bytes) = S with the
   corrected pin value.

Tool hygiene: the repeat-call guard KILLS sessions issuing identical repeated
tool calls — batch reads, vary queries, never re-read a file the same way twice.

## Output
tasks/recon/tabs-oracle.md with: S list (ranked by user-visible impact, fix
sketch each), D list (one-line justification each), and a one-line verdict per
R1-R9. No edits to any file outside tasks/recon/tabs-oracle.md.
