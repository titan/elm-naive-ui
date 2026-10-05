# BRIEF — fix(tabs): oracle S1/S2 + [oracle D] docstrings + 3 DOM probes — edit files, do NOT commit

Workspace: /home/titan/Works/elm/elm-naive-ui @ `8d9ec4a` (your worktree branches from
this). Make the edits below. Do NOT `git commit` (parent gates + commits). Full audit:
tasks/recon/tabs-oracle.md (read it first). Upstream mount (read-only):
/home/titan/Works/elm/naive-ui — Tabs.tsx, Tab.tsx.

## 1. src/NUI/Tabs.elm

### S1 — `leftPadded` must gate on the RESOLVED justify, not the raw field
Current (:908-925): non-segment branch tests `opts.justifyContent == Nothing || …
JustifyCenter/Start/End`. Upstream `Tabs.tsx:1031-1037` computes
`internalLeftPadded = index !== 0 && (!mergedJustifyContent || mergedJustifyContent is
center/start/end)` where `mergedJustifyContent = !card && !segment && justifyContent`
(`Tabs.tsx:1004`) — i.e. for **Card**, justify is ignored ⇒ pad IS emitted for index>0.
Fix: the non-segment branch becomes
```elm
index
    /= 0
    && (not (justifiedForClass opts)
            || opts.justifyContent
            == Just JustifyCenter
            || opts.justifyContent
            == Just JustifyStart
            || opts.justifyContent
            == Just JustifyEnd
       )
```
(`justifiedForClass` :671-677 already equals upstream's mergedJustifyContent.) Keep the
segment branch (`index /= 0`) untouched. Update the leftPadded docstring comment if it
cites the old raw-field logic.

### S2 — add tab must carry `tabClass` (its documented contract)
`addTabNode` (:1041-1061): the add-tab div's class list is the literal
`"n-tabs-tab n-tabs-tab--addable"`. The module docstring (:50-52) promises the add tab
inherits `tabClass`. Append the class, mirroring `tabClasses` (:947-956) ordering —
base + `--addable` then the extra:
```elm
HA.class (String.join " " ([ "n-tabs-tab", "n-tabs-tab--addable" ] ++ extraClass opts.tabClass))
```
(or an equivalent that yields `n-tabs-tab n-tabs-tab--addable[ x]`). Upstream byte
reference: `Tab.tsx:118-122` (modifiers then class prop last).

### [oracle D] docstring lines (Divergences block @17-55)
Mirror `src/NUI/DatePicker.elm:115-156` format exactly:
`  - \`[oracle D]\` **Dn — title.** one-liner.` Add these, each with its upstream cite:
- **D1 — add tab ignores `trigger`.** `onAdd` is always click-wired (:1072-1080);
  upstream's add tab is a `Tab` so hover-trigger adds on mouseenter (`Tab.tsx:124`).
- **D2 — close `aria-disabled`.** Port omits it when enabled; `NBaseClose` always
  emits it (`Close.tsx:40` renders `"false"` when enabled).
- **D3 — icon SVG byte drift.** closePath drops the trailing zero-area path segment +
  outer `<g>`; add icon drops `width="512" height="512"` — visually identical (svg is
  sized 1em by the shipped `_internal/icon` rule).
- **D4 — placement `start`/`end` not ported.** Upstream resolves them via RTL
  (`Tabs.tsx:171-180`); callers pre-resolve to Left/Right.
- **D5 — `addTabFixed` not modeled.** Port always renders the add tab inside the
  scroll wrapper; upstream pins it outside once measured (`Tabs.tsx:666-704`, :1244).
- **D9 — uncontrolled seeding.** Upstream seeds the first pane's name when
  uncontrolled (`Tabs.tsx:215-223`); the port is fully caller-owned (`value` required).
Do NOT duplicate D6 (VXScroll) / D7 (stopPropagation) — already documented and
oracle-verified true.

## 2. Tests — 3 new DOM probes (S1, S2, D10-gap)

Pattern: live-render blocks in `tests/src/Main.elm` near the existing Tabs renders
(~:12946-12986; find the tabs fixtures — options set at ~:2910-2962) + assertions in
`tests/inspect.mjs` Tabs block (:3665-3905). Mirror nearby probe style exactly
(selector, classList text assertions).

1. **S1 probe**: type Card + `justifyContent = Just JustifySpaceBetween`, 3 tabs ⇒
   `.n-tabs-tab-pad` count == 2 (tabs-1) inside that fixture's root. Also assert the
   root does NOT carry `n-tabs--flex` (justify ignored for card).
2. **S2 probe**: `addable = True`, `tabClass = Just "x"`, Card ⇒ the add tab
   (`[data-name="__addable"]`) has class `x` (class list
   `n-tabs-tab n-tabs-tab--addable x`).
3. **D10 gap probe**: a Segment fixture's nav carries `n-tabs-nav--segment-type`
   (assert on the nav element's class list, not just substring of the page).

Each assertion gets a `PASS DOM: tabs …` label consistent with the existing ones, with
the upstream file:line in the label where the existing style does that.

## 3. Verify (targeted; parent runs the full gate)
- `ELM_HOME=/tmp/elm-home elm make --output=/dev/null` (library compiles)
- `cd tests && ELM_HOME=/tmp/elm-home bash run.sh` if it completes in reasonable time
  (cold builds are slow — if it exceeds ~8 min, skip and say so; do NOT kill-iterate).
- Do NOT run scripts/verify.sh (parent's job). Do NOT commit.

## Report back
Changed files + line deltas, the exact new docstring lines, the three probe labels, and
compile/test results. Tool hygiene: the repeat-call guard KILLS sessions issuing
identical repeated tool calls — batch reads, vary queries.
