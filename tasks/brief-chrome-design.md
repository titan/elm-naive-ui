# Brief — Showcase chrome redesign (examples/src only)

## Goal
The showcase page (`examples/src/Main.elm` + `Sections/*` + `Showcase.elm`) renders
every component correctly but LOOKS bad. A live-browser visual audit found the
problems below. Redesign the page chrome so it reads like the naive-ui docs site
(https://www.naui-ui-style reference: top title bar, sticky left sidebar with
section links, content column, each demo inside a bordered "demo card" example
area) while keeping every gate constraint.

## Verdict from the audit (what to fix)
1. **Fixed-position demos cover the whole page.** The Affix demo's green
   "Affixed" button is `position: fixed` at top-left and sits ON the h1 on every
   scroll position; the Anchor demo's link list is also pinned and overlaps the
   hero text and content in every viewport. Upstream docs render these inside a
   BOUNDED BOX (a bordered, `position: relative`, fixed-height container with its
   own scroll where needed). Give every fixed/absolute demo such a container so
   its overlay geometry stays inside the box.
2. **Always-open static overlay demos float unanchored.** The static Popover
   demo card and Popconfirm cards render in-flow with no visible trigger near
   them; the Modal/Drawer/Dialog static demos have similar issues. Put static
   overlay demos inside a labelled, bordered, relative-positioned preview box
   (min-height so the panel fits) so they read as "static preview" demos.
3. **Drawer top/bottom placements collapse to 0-width slivers.** Root cause
   (measured): `.n-drawer-container` is `position:absolute; left:0; right:0`
   and stretches over its PARENT — but the demo wraps it in a width-content
   elm-ui element ~2px wide, so `width:100%` drawers resolve to 0. Fix in the
   DEMO (not the library): wrap each drawer demo in a bordered relative box
   with explicit width (~ the column width) and height (~160-220px) so the
   container stretches correctly. Do NOT change src/NUI/Drawer.elm.
4. **Horizontal overflow (606px on 1440 viewport).** Widest offenders measured:
   - `.n-log` demo: a `spacing-12-12 s e` column ~1534px wide (long code lines,
     intrinsic width, elm-ui flex children have no auto min-width:0) containing
     a width-fill 120px scrollbar box → right edge 1826.
   - Two `wrappedRow`s ~1534px that cannot wrap (fixed-width children, e.g. the
     slider row whose label text "Mousedown on the track, move, release —"
     measures 1275px).
   - A `.n-divider__line--right` reaching right:2046.
   - Wide tables/demos generally.
   Fix pattern: every demo card body gets `Element.width Element.fill` +
   `Element.width (Element.maximum <content-col-width> Element.fill)` on wide
   intrinsic content, or put wide demos in a horizontally-scrollable box
   (`Element.scrollbarX`-style via Element.htmlAttribute overflow-x:auto) so
   they stop stretching the page. After your pass,
   `document.documentElement.scrollWidth <= clientWidth` must hold at 1440.
5. **Page layout wastes the viewport**: one 880px column on 1440 leaves ~300px
   dead margins each side, 96k px tall, no navigation. Build docs-style chrome:
   a sticky sidebar listing the sections (grouped by the 8 family modules +
   Live families), smooth-scroll anchor links to section ids; content column
   ~ 900-1100px. Keep the page header (title + tagline) — it can become a top
   bar.
6. Minor demo polish (fix if cheap): RTL alert shrinks to content width and the
   bidi text renders with the leading period detached; the Badge "5" value sits
   half outside its tag; the Menu demo items render as bare text without a
   visible menu container.

## Hard constraints (gate — verify.sh must stay 8/8)
- **Do not touch**: `src/` (library), `tests/`, `tools/`. ONLY `examples/src/`
  (+ `examples/elm.json` if a dep is truly needed — avoid).
- **These 34 ids must keep existing on the examples page with their demo DOM
  and wiring unchanged** (the LIVE gate phases query them by id on the built
  page): live-button-counter live-button-reset live-carousel-auto
  live-carousel-drag live-checkbox-master live-datepicker-panel live-daterange
  live-daterange-panel live-dialog live-drawer live-dropdown-click
  live-dropdown-hover live-input-controlled live-input-number-commit
  live-input-number-stepper live-input-otp-mask live-input-otp-reset
  live-loading-bar live-log live-message-queue live-modal
  live-notification-queue live-popconfirm live-popover live-radio-group
  live-range-hi-minus live-range-lo-plus live-rate live-rate-hover-clear
  live-rate-hover-plus live-slider-minus live-slider-plus live-switch-toggle
  live-tooltip-region
- **Do not edit the `Live/*` module demo internals** (their ids/behavior are
  pinned). Wrapping their `section` blocks in Main.elm chrome is fine — the
  `section` helper call sites in Main.elm may be reorganized.
- **Every component root in every section must keep rendering** (check-dom
  walks the built page for ~100 `.n-*` roots). Wrapping demos in new
  containers is fine; deleting/renaming component instances is not.
- The overlays in the LIVE demos start closed by design — do not "fix" that.
- After editing: `elm-format --yes examples/src/` (step 8 of the gate fails on
  unformatted files). Compile check:
  `cd examples && ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=index.html`
  (judge by EXIT CODE; progress uses \r overwrites).
- Do NOT run the full verify.sh (orchestrator gates after merge).

## Visual iteration loop (use it — this is a visual task)
Your worktree has the repo. Build + serve + screenshot YOUR build:
```
cd examples && ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=index.html
setsid nohup python3 -m http.server 8972 --bind 0.0.0.0 >/tmp/serve-chrome.log 2>&1 &
agent-browser --session chromelane set viewport 1440 900
agent-browser --session chromelane open http://127.0.0.1:8972/index.html
agent-browser --session chromelane screenshot /tmp/chrome-check.png
```
Scroll to several depths (`agent-browser --session chromelane scroll down N`),
screenshot each; check: no fixed-layer overlap outside its box, no horizontal
scrollbar, drawers visible, sidebar nav highlights. Kill the server when done
(`pkill -f "http.server 8972"`).

## Deliverable
Commits on your branch (worktree), message prefix `showcase(chrome):`. One
focused commit or a couple is fine. Report: what changed per file, the final
screenshot check results (overlap gone / h-overflow 0 at 1440), anything you
deliberately left. Do not run verify.sh; do not merge to master.
