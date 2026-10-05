# tabs-oracle.md — byte-fidelity audit, NUI.Tabs vs naive-ui v2.45.3

Read-only oracle audit of the *existing* `NUI.Tabs` port (the earlier tabs batch skipped
the fidelity round). No file edited. Port @ `20de030`; upstream = `/home/titan/Works/elm/naive-ui`
v2.45.3. Every claim below cites upstream bytes and port bytes directly (the recon docs were
treated as untrusted).

Port surfaces audited: `src/NUI/Tabs.elm` (1195 L; `view` @587, `cssVars` @192-238, docstring
@17-55), `src/NUI/Theme/Tabs.elm` (298 L), `tests/src/Main.elm` (pins @8711-8780, live renders
@12946-12986), `tests/inspect.mjs` (DOM block @3665-3905), `tools/verify/check-dom.mjs:89`,
`tools/manifest.mjs:274-277`, `examples/src/Main.elm:2146-2169`, `css/naive-ui.css`.

Headline: the port is high-fidelity. R1-R6, R8 largely match the upstream bytes; the cssVars
set (32 keys, order, every `createKey` selection, dark theme) and the nav/segment/pane trees are
correct. Two low-impact spec deviations (S1, S2) plus documentation gaps (D items).

---

## S — spec violations (fix required), ranked by user-visible impact

### S1. `Card` + `justifyContent ∈ {space-between, space-around, space-evenly}` drops the tab pad
- Upstream `Tabs.tsx:1031-1037`: `internalLeftPadded = index !== 0 && (!mergedJustifyContent ||
  mergedJustifyContent === 'center' || 'start' || 'end')`, where
  `mergedJustifyContent = !isCard && !isSegment && this.justifyContent` (`Tabs.tsx:1004`).
  For **card**, `mergedJustifyContent` is always falsy ⇒ `!mergedJustifyContent` is `true` ⇒ the
  `n-tabs-tab-pad` element is emitted for every tab with `index > 0`, regardless of `justifyContent`.
- Port `src/NUI/Tabs.elm:908-925` (`leftPadded`) tests the **raw** `justifyContent`:
  `index /= 0 && (justifyContent == Nothing || == JustifyCenter || JustifyStart || JustifyEnd)`.
  With `type_ = Card` and `justifyContent = Just JustifySpaceBetween` (or Around/Evenly) this
  returns `False`.
- Expected vs actual: upstream renders `<div class="n-tabs-tab-pad">` (width `--n-tab-gap`, i.e.
  the 4px card gap — `index.cssr.ts:382-387`, `:476`) between card tabs; the port renders none, so
  card tabs touch. Trigger is an unusual combo (card ignores `justifyContent`), so impact is narrow.
- Minimal fix: gate the "no pad" branch on the *resolved* justify, not the raw field:
  ```elm
  else
      index /= 0
          && (not (justifiedForClass opts)
                  || opts.justifyContent == Just JustifyCenter
                  || opts.justifyContent == Just JustifyStart
                  || opts.justifyContent == Just JustifyEnd)
  ```
  (`justifiedForClass`, `src/NUI/Tabs.elm:671-677`, already equals upstream `mergedJustifyContent`.)
- Wire a pin/DOM probe: card + `justifyContent` truthy ⇒ `n-tabs-tab-pad` count = tabs-1.

### S2. Add tab does not receive `tabClass`, contradicting its own docstring
- Upstream `Tab.tsx:122`: the add tab uses `addTabClass` (a separate prop); normal tabs use
  `tabClass`. The port deliberately reuses `tabClass` for the add tab — the docstring states exactly
  that: `src/NUI/Tabs.elm:50-52` "The add tab inherits `tabClass` / `tabStyle` (upstream's separate
  `addTabClass` / `addTabStyle` props are not ported …)".
- Port `addTabNode` (`src/NUI/Tabs.elm:1041-1061`) applies `tabStyleAttr opts` but **not**
  `extraClass opts.tabClass`: the class list is the literal `"n-tabs-tab n-tabs-tab--addable"`.
- Expected vs actual: with `addable = True`, `tabClass = Just "x"`, upstream-consistent behaviour
  (as documented by the port) ⇒ the add tab carries `x`; actual ⇒ it does not. So the documented
  contract is unmet: styling/targeting the add tab via `tabClass` silently fails.
- Minimal fix (matches the docstring): append `++ extraClass opts.tabClass` to the add-tab div's
  class list, parallel to `tabClasses` (`:947-956`). Alternative: tighten the docstring to "inherits
  `tabStyle` only" — pick one so code and doc agree.

---

## D — divergences (document, no fix)

- **D1 — add tab ignores `trigger`.** `onAddAttr` (`src/NUI/Tabs.elm:1072-1080`) always wires
  `onClick`. Upstream: the add tab is a `Tab`, so activation follows `trigger` (`Tab.tsx:124`); with
  `trigger = Hover` it adds on `mouseenter`. One-liner: with hover trigger the add tab fires on click.
- **D2 — close button `aria-disabled`.** Port emits `aria-disabled="true"` only when disabled
  (`src/NUI/Tabs.elm:1004-1022`); `NBaseClose` always emits `aria-disabled` (renders `"false"` when
  enabled, `Close.tsx:40`). Accessibility-attr only.
- **D3 — icon SVG byte drift (visually identical).** `closePath` (`:1176-1179`) drops the trailing
  zero-area `L2.14644661,2.14644661 L2.08859116,2.2156945` of `Close.tsx:13`, and omits
  `version`/`xmlns`/the outer `<g stroke="none" …>`; `addIconSvg` (`:1181+`) omits
  `width="512" height="512"` from `Add.tsx:8-9`. Harmless: `.n-base-icon svg { width/height:1em }`
  (`_internal/icon/src/styles/index.cssr.ts:12-15`, shipped at `css/naive-ui.css:121`).
- **D4 — placement `start`/`end` not ported.** `Placement = Top | Bottom | Left | Right`
  (`src/NUI/Tabs.elm:104`) has no start/end; upstream resolves them via RTL (`Tabs.tsx:171-180`,
  `mergedPlacementRef`). A caller must pre-resolve. Also unlisted in the docstring (see D9).
- **D5 — `addTabFixed` not modeled.** The port always renders the add tab inside the scroll wrapper
  (`addNode`, `:872-887`). Upstream pins it outside the overflow area once measured
  (`Tabs.tsx:666-704`, `:972`, branch at `:1244`). Measurement-driven; undocumented (D9).
- **D6 — VXScroll / VResizeObserver omitted (documented).** Top/bottom render
  `n-tabs-nav-scroll-wrapper > n-tabs-nav-scroll-content` directly (`nonSegmentNav`, `:736-749`);
  upstream wraps in `VXScroll` (`Tabs.tsx:1202-1213`). Left/right keep `n-tabs-nav-y-scroll`
  (correct, `:1215-1221`). If vueuc's `VXScroll` renders an intermediate scroll element, the tree is
  one node shallower and horizontal scrolling is lost — the documented "VXScroll omitted" stance.
- **D7 — close does not `stopPropagation` (documented).** `closeClick` (`:1029-1037`) vs
  `Tab.tsx:58-63`; a card tab that is both closable and activatable fires `onClose` and `onChange`.
  Correctly listed in the docstring (`:48-49`).
- **D8 — example variants incomplete.** `examples/src/Main.elm:2146-2169` covers Bar/Line/Card/
  Segment/Sizes/Placement/Show but not justify/addable/prefix-suffix/rtl/hover. Those variants exist
  only in the test-options set (`tests/src/Main.elm:2910-2962`) and thus only get `tests/inspect.mjs`
  coverage, not the `check-dom` example page.
- **D9 — docstring Divergences block is TRUE but incomplete.** `src/NUI/Tabs.elm:17-55` omits: the
  missing placement `start`/`end` (D4), `addTabFixed` (D5), and uncontrolled/`defaultValue`
  seeding (upstream seeds the first pane's name when uncontrolled, `Tabs.tsx:215-223`; the port is
  fully caller-owned — stated only indirectly at `:30`). Add one line each.
- **D10 — recon correction (not a code finding).** `tabs-2-elm.md` §4/§6 assert the only Tabs DOM
  probe is `check-dom.mjs`'s `'.n-tabs': true` (`:89`) and propose "stronger probes". This is false:
  `tests/inspect.mjs:3665-3905` already carries ~35 Tabs DOM assertions (root/nav class algebra,
  scroll-wrapper nesting, y-scroll by placement, tab/pad counts, bar-vs-card, segment rail tree,
  rtl/justify/disabled classes, close button + disabled close, addable placeholder/icon, prefix/
  suffix, ShowIf vs Show pane counts, `display:none` on inactive, tab/pane class+style, card
  `n-tabs-pad`). Genuine remaining gaps only: the `n-tabs-nav--segment-type` class is emitted
  (`:682-693`) but never asserted, and there is no computed-CSS/cascade assertion for the tabs block
  (`check-dom` checks only the root bridge + var count).

---

## Verdicts

- **R1 root/nav class algebra — OK.** Order and every branch match `Tabs.tsx:1095-1120`: `n-tabs` +
  `--{type}-type` + `--{size}-size` + `--flex` iff `justifiedForClass` + `--{resolvedPlacement}` +
  `--rtl`; nav = `n-tabs-nav--{type}-type` + `n-tabs-nav--{resolvedPlacement}` + `n-tabs-nav`.
  Segment forces `top` on both root and nav (`resolvedPlacement`, `:660-668`). justify-with-card and
  justify-with-segment correctly emit **no** `--flex` (`justifiedForClass`, `:671-677` = `Tabs.tsx:1004`).
- **R2 nav structure tree — OK** (one documented omission D6). prefix/suffix emitted iff present;
  `n-tabs-nav-scroll-wrapper` always, `n-tabs-nav-y-scroll` only for left/right; both
  `n-tabs-scroll-padding` elements rendered with `0px` iff not justified (leave side `width` for
  top/bottom, `height` for left/right — `leftPadding`/`rightPadding` `:830-855` = `Tabs.tsx:1012-1021`
  / `:1066-1071`); `n-tabs-pad` iff card; `n-tabs-bar` iff `!card`; `n-tabs-tab-pad` per `leftPadded`
  — **except** S1.
- **R3 tab anatomy — OK** (S2 aside). `tab-wrapper > pad > tab[data-name][data-disabled]`, modifier
  order active/disabled/closable(+addable) then `tabClass`, `__label` span, addable label =
  height-placeholder(`&nbsp;`) + add icon, close iff `mergedClosable && card`; `mergedClosable` =
  `tab.closable ?? opts.closable` (`:970-973` = `Tab.tsx:43-50`); add tab `data-name="__addable"`;
  disabled tabs render `data-disabled` and do not activate.
- **R4 cssVars — OK.** Exactly the 32 keys of `Tabs.tsx:878-909`, same order (pinned at
  `tests/src/Main.elm:8729-8731`). Every `createKey` selection matches: `panePadding{Size}`,
  `tabPadding{Size}{Type}`, `tabPaddingVertical{Size}{Type}`, `tabGap{Size}{Type}`,
  `tabGap{Size}{Type}Vertical`, `tabTextColor[Active|Hover|Disabled]{Type}`, `tabFontSize{Size}`.
  `paddingSide` (`:540-586`) reproduces seemly `getPadding` for 1-4 tokens. Dark path is correct:
  `NUI.Theme.Tabs.vars` switches on `theme.mode` and dark overrides only
  `colorSegment`/`tabColorSegment → inputColor` (`src/NUI/Theme/Tabs.elm:105-110,265,291` = `dark.ts:12-18`).
  `tabFontSizeCard` is defined in the theme but, like upstream, never emitted.
- **R5 pane emission — OK.** `ShowIf` → only the active pane node; `Show` → all pane nodes with
  inactive `display:none` inline (`paneStyleAttr`, `:1128-1148` = `filterMapTabPanes`,
  `Tabs.tsx:1307-1320`); `show:lazy` documented-not-ported; `animated` wrapper iff
  `animated && resolvedPlacement ∈ {top,bottom}` (`:1100-1118` = `Tabs.tsx:1257-1274`); pane =
  `n-tab-pane` + `paneClass` + `paneStyle`. The port always renders panes because it models the
  `n-tab-pane`-children API (`showPane = true`); with an empty tab list both upstream and port emit
  no pane nodes.
- **R6 segment body — OK.** `n-tabs-rail > n-tabs-capsule > n-tabs-wrapper > n-tabs-tab` dummy then
  the tab wrappers, pad at `index > 0` only, placement forced `top` on root+nav, no bar/pad/
  scroll-wrapper/justify (`segmentRail`/`navContent`, `:714-735` = `Tabs.tsx:1131-1179`).
- **R7 events/attrs — OK** (D1, D7 aside). `onChange`/`onClose`/`onAdd` wired; Click→`onClick`,
  Hover→`onMouseEnter`; attrs on the tab div, not the label span; hover bound to the same element as
  upstream (`Tab.tsx:124-125`).
- **R8 theme / generated CSS sanity — OK** (D10 aside). Spot-checked `NUI.Theme.Tabs` against
  `_common.ts`/`light.ts` incl. every `tabPadding*`/`tabGap*` keyed entry and `panePadding*` — exact.
  `css/naive-ui.css` contains the tabs block incl. RTL, segment and scroll-button selectors (all
  emitted classes present; `manifest.mjs:274-277` ships both `index.cssr.ts` and `rtl.cssr.ts`).
  The gate is stronger than the recon claimed (D10).
- **R9 sampling — OK** (S2, D4/D5/D9 aside). `defaults` (`:161-190`) matches `Tabs.tsx:70-126`
  (type bar, size medium, placement top, trigger click, ShowIf, tabsPadding 0, animated/closable/
  addable false). Deprecated `labelSize`/`activeName`/`onActiveNameChange` truly absent. Every
  evaluated pin (`tests/src/Main.elm:8711-8780`) matches the upstream bytes — no pin encodes a wrong
  expectation. The docstring block is TRUE (except S2) and incomplete (D9).

## Bottom line
Fix S1 (one-line `leftPadded` gate) and resolve S2 (add `tabClass` to the add tab, or narrow the
docstring). Everything else is a document-only divergence. No high-impact user-visible breakage found:
the class trees, cssVars math (light+dark), and pane semantics reproduce naive-ui v2.45.3.
