# elm-naive-ui — batch todo (older closed trails below)

## Live/* oracle audit round — CLOSED (1 commit, oracle lane + in-context fix)
- [x] oracle — `tasks/recon/live-oracle.md` (oracle lane, worktree-less: read-only
      specialist, report lands directly in untracked tasks/; brief
      tasks/brief-live-oracle.md). Verdict: the showcase is HONEST as a port
      showcase — every port helper that exists is used (stepValue,
      inputUpdate, singleDateClick/dualDateClick, scrollEvents, provider
      queue transforms…), no channel wired to a dead update, all
      subscriptions gated, overlays start closed as the smoke asserts.
      S×1 · D×9 · R×7; all 78 LIVE/OVR checks traced to real update branches.
- [x] fix — `1f8502d` (S1: Live/Nav TabClose reassigned activeTab
      unconditionally → closing a BACKGROUND tab moved the selection
      (upstream addable.demo.vue guards `name === value`); guard added,
      activeAfterClose unchanged. + [oracle D] docstring one-liners across
      all six modules; 2 of the 9 D findings were already documented
      in-module. Gate 8/8 — **4255/4255, 0 failures**, counts identical.)
- TRAP learned: elm-format reflows the docstring bullet lists — run
      `elm-format --yes examples/src/Live/` BEFORE the gate (step 8 fails
      on the first edit otherwise).
- R notes worth keeping: R5 ranks the next LIVE smoke promotion candidates
      (Controls/InputNumber buffer/commit/invalid loop → Motion/Carousel
      arrows/dots/wheel, drag needs the 20ms tick → Pickers/DatePicker
      daterange two-click); R1 the six families' pure-update seam (no Cmd
      anywhere) is the family contract — don't let a fixer "just add a Cmd";
      R2 pick the clamp recipe when either page-size demo is next touched.

## Live smoke promotion — CLOSED (1 commit, lane + orchestrator review)
- [x] `4aee081` (test(live/overlays): the Overlays lane's 78-assertion jsdom
      interaction smoke — a /tmp scratch that drove the compiled showcase app
      with real DOM events — is now a STANDING gate phase. inspect.mjs boots a
      SECOND jsdom instance around examples/index.html (Browser.element app,
      overlays start closed) after the static phases and before the report;
      helpers ovl-scoped, scenario bodies verbatim incl. the load-bearing
      30/20ms rAF sleeps; ok() → domChecks entries named `LIVE/OVR:`; whole
      phase try/caught into a failed `LIVE/OVR driver error` check (never a
      silent skip); missing examples page exits 1 loudly with the build
      command. run.sh builds the examples page between tests build and
      assertions so standalone runs never pin a stale artifact. Gate 8/8 —
      **4255/4255, 0 failures** (4177 standing + 78 live; the repo's
      "+ 2522 DOM" phrasing is PARALLEL to the 4177, not additive — the
      printed total went 4177 → 4255). Lane scratch /tmp/live-overlays-smoke.mjs
      re-verified 78/78 on six-family master BEFORE promotion; first spawn
      died at the known ZhipuAI stub, fresh respawn clean.)

## LIVE interactive showcase (real update loops for every channel-bearing component) — CLOSED (7 commits, 6 parallel lanes)

- [x] prep — `731b237` (main → Browser.element over six Live/* family models;
      shared chrome → examples/src/Showcase.elm exposing-import so Main's call
      sites stay untouched; 87 static sections KEPT AS-IS — they feed check-dom
      (100 roots, overlay/panel roots from always-open static instances; live
      instances may start closed); elm/browser direct dep. Gate 8/8 counts
      identical.)
- [x] Controls `cb32c2c` (697 L, lane: Button counter, Input single+pair+clear,
      InputNumber, Switch, Checkbox all+indeterminate, Radio.Group, Rate
      hover/commit, Slider single+range, InputOtp completion)
- [x] Nav `3bc19c9` (725 L, lane: Tabs live+add/close, Collapse accordion vs
      multiple, Menu expand+active, Pagination page/size/jumper, Steps wizard,
      Anchor simulated scroll, BackTop threshold, Split buttons)
- [x] Motion `b287b9a` (977 L, lane: Carousel ×2 — autoplay Time.every + arrows
      + dots + wheel + pointer drag via Browser.Events, Log scroll-load,
      Countdown ×2, NumberAnimation, Progress ×2, Spin, Skeleton, Marquee)
- [x] Data `50796b2` (1535 L, lane: DataTable selection+sort+pagination, Tree
      check/expand/select, Transfer move+filter, Calendar panel+date,
      Image→Preview full toolbar, ImageGroup gallery, Upload simulated files,
      DynamicInput/DynamicTags, Form validate+submit, Table Row.attributes seam)
- [x] Overlays `0dc9e60` (1092 L, lane; self-ran the full gate + a 78-assertion
      jsdom interaction smoke: Dropdown click+hover, Popover controlled+pin,
      Tooltip, Popconfirm, Modal mask-isolation, Drawer placements, Dialog,
      Message/Notification queues+eviction, LoadingBar phase ladder)
- [x] Pickers `6721ea1` (1407 L; FIRST lane died at stub on a ZhipuAI stream
      timeout — fresh respawn, zero salvage needed: Select single+multi,
      Popselect, Cascader drill, TreeSelect, AutoComplete filter, Mention @,
      DatePicker single via click-algebra helpers + daterange pair, TimePicker
      columns, ColorPicker full loop)
- Checkpoint: gate 8/8 with all six families integrated — 100 components 0
      failures, 4177/4177 + 2522 DOM, 0 failures. ~6,400 lines of live demos;
      lanes exercised the port's pure interaction algebra (Carousel.dragEnd,
      DatePicker.singleDateClick/dualDateClick, Log.scrollEvents, provider
      queue transforms) instead of hand-rolled semantics.
- TRAP learned: subagent worktrees can be identified by scanning
      `.nca/worktrees/*/examples/src/Live/*.elm` line counts when a lane dies
      without a commit; cherry-pick lane commits directly (shared object store).
      One spawn in six silently fell back to the ZhipuAI default path despite
      provider=deepseek — the failure mode is the known stream timeout.

## Trail outcome (for the next session)
The showcase is now a real Elm app: 87 static sections (check-dom surface) + six
Live/* interactive families covering all 53 channel-bearing components (56 demos
total). The Overlays smoke promotion is DONE (second entry). The oracle audit
round over the six Live modules is DONE (top entry). Possible follow-ups,
none queued: promoting the OTHER five lanes' smokes the same way if they ever
write any (only Overlays had one — oracle R5 ranks the candidates), splitting
static sections into modules (they still live in one 5,880-line Main.elm).

## README caller-supplied hljs/katex note — CLOSED (1 docs commit, the LAST optional item)
- [x] docs — `884b60b` (one bullet in Notes / limitations: the port ships no JS —
      caller supplies an Hljs record for Code/Log, a bound renderToString closure for
      Equation; Nothing → plain text / the literal 'no katex provided'. README is NOT
      a gate input — verify steps 1-8 cover src/examples/tests only; gate run for the
      record: 8/8 — 4177/4177 + 2522 DOM, 0 failures, counts identical @ `03886f1`.)

## InputNumber buttonThemeOverrides via Button.varOverrides — CLOSED (1 commit, no oracle — upstream bytes, seam oracle-audited in the Upload batch)
- [x] fix — `03886f1` (InputNumber.tsx:657-667 rgba-splits this component's
      iconColorDisabled into textColorTextDisabled rgb(r,g,b) + opacityDisabled
      alpha via builtinThemeOverrides; the port predated the seam and had the
      gap DOCUMENTED in its header. buttonVarOverrides emits
      --n-text-color-disabled (the var a text-variant Button maps
      textColorTextDisabled onto — NOT --n-text-color-text-disabled) +
      --n-opacity-disabled, swapped in place. Gap bullet deleted. +dark fixture
      + 4 DOM pins; 3 RED pre-fix via stash. Gate 8/8 **4177/4177 + 2522 DOM,
      0 failures**.)
- SCOPE NOTE: the optional item's "Pagination" half was a handoff conflation —
      upstream pagination has NO NButton (page items are plain divs; its
      builtinThemeOverrides targets the fast-jump Popselect height the port
      deliberately dropped, see Pagination.elm header). Nothing to migrate.
- TRAP learned: inspect.mjs's `styleAt` is a const defined at ~L2668 — blocks
      earlier in the file hit TDZ; use a local `getAttribute('style')` IIFE
      there. Dark common.opacityDisabled is already 0.38, so the dark opacity
      pin was coincident pre-fix (only 3 of 4 pins were RED witnesses).

## RawHtml svg/math foreign namespaces — CLOSED (1 commit, no oracle — kernel semantics, empirically pinned)
- [x] fix — `f842534` (browser innerHTML puts `<svg>`/`<math>` subtrees into
      SVG/MathML ns (foreign-content rules); RawHtml emitted `Html.node`
      (HTML ns) — KaTeX stretchy shapes were unknown elements no browser draws,
      the katex-mathml a11y copy was fake MathML. Fix: scope TAG-driven +
      inherited down the subtree (`openNs`; the recursive parse restores it at
      `</svg>`/`</math>`); namespaced elements render via `VirtualDom.nodeNS`
      (public in elm/virtual-dom — promoted to DIRECT dep, library + examples
      elm.json both). Integration points (foreignObject/desc/title,
      annotation-xml) deliberately unmodelled, docstring'd like the recovery
      contract. §E21 re-pinned to the svg-ns node; +§E23 4 eq pins; §D26
      +svgNsPin; +§D29 7 probes on a BYTE-REAL katex@0.16.47 output
      (naive-ui pins ^0.16.28, no upstream lockfile) for
      `c = \pm\sqrt{a^2 + b^2}` — svg+path+math namespaceURI via the live Elm
      runtime, viewBox 0 0 400000 1080 / preserveAspectRatio / d="M95,702…" /
      annotation tex / xhtml scope-exit witness; 9 pins verified RED pre-fix.
      Gate 8/8 **4173/4173 + 2522 DOM, 0 failures**.)
- TRAP learned: examples/elm.json has its OWN dep list — a new LIBRARY dep must
  be mirrored there (gate 4/8 passed, 5/8 failed with MODULE NOT FOUND until
  virtual-dom moved indirect→direct). Also: katex svg threshold is size3/4
  (size1/2 delims are font spans — `\left(\dfrac{a}{b}\right)` has NO svg);
  npm needs `--cache /tmp/npm-cache` (permissions); katex ground truth was
  generated at /tmp/katex-truth (regen: `npm i katex@^0.16.28` + renderToString).

## data-* "true" serialization sweep — CLOSED (1 commit, no oracle — the rule was already oracle-established)
- [x] fix — `d78d0d1` (upstream bare JSX attrs → `{true}` → Vue patchAttr setAttribute-coerces
      to `"true"`; the transfer S2 / TreeSelect pin rule. 16 `""` sites corrected across 10
      modules: SelectMenu header/empty/action, Cascader action, Input ×2 + BaseSelection
      clear, Collapse arrow/extra, Scrollbar rail, Tree switcher/checkbox, DatePicker
      n-date ×2, DataTable filter, FloatButton menu. 3 wrong-value pins re-pinned
      (data-clear/data-empty/data-data-table-filter had been pinning `""` as expected!),
      4 presence probes → value asserts, +5 new pins (Input `live-input-clear` +
      `live-cascader-menu-action` fixtures added to tests/src/Main.elm). Image `data-group-id`
      + TimePicker `data-active` DELIBERATELY stay `""` — upstream writes the empty string
      there (`|| ''` / `{active ? '' : null}`). Gate 8/8 **4160/4160 + 2518, 0 failures**.)
- TRAP learned: inspect.mjs fixtures live in **tests/src/Main.elm** (a wrapper el carries
  the id), NOT examples/src/Main.elm — the showcase page is check-dom's surface. A probe
  returning null against a "fixture you added" means you edited the wrong Main.elm.

## Calendar engine-grid dedup (dedup-1 §7 repoint) — CLOSED (2 commits, no oracle per the dedup precedent)
- [x] pins — `2be9293` (#live-calendar-strip fixture: Sep 2024 starts ON the enUS
      startDay → 0 leading days, 35 cells, 5-day Oct tail; 4 DOM probes, green against
      Calendar's own correct grid BEFORE any engine change)
- [x] refactor — `39ef4a8` (DT.dateArray threads `strip` into the leading-loop protect
      flag — was hardcoded True, i.e. upstream utils.ts:366 `!strip`; strip=true now
      yields 0 leading days on a startDay-aligned month, strip=false pickers unchanged;
      Calendar.grid delegates with strip=true + DateItem→Cell adapter (inCurrentMonth/
      isCurrentDate from the engine via UTC-midnight ts, selected stays civil);
      deleted prevMonthDays/monthDays/nextMonthDays + dead addDays/daysInMonth/
      daysFromCivil/civilFromDays wrappers; +8 engine eq pins both strip modes on the
      edge month + a non-edge sanity; gate **4155/4155 + 2518, 0 failures**, all
      pre-existing pins byte-identical)
- Note: the 18-month 2020-30 divergence table (dedup-1 Check 2) is now moot — both
  strip modes are engine-owned and pinned.

## Trail outcome (for the next session)
The month-grid semantics now live ONLY in NUI.Internal.DateTime.dateArray (both strip
modes); Calendar is a thin adapter (UTC-midnight ts in, Cell out). dedup-1's remaining
KEEPs stand (addMonthsPanel modular arithmetic, formatFullDate label, Heatmap structural
helpers). ALL optional items closed — the project is COMPLETE (100% naive-ui v2.45.3
user-facing coverage, gate 8/8 @ 4177/4177 + 2522 DOM, 0 failures @ `884b60b`; the
data-* sweep, RawHtml namespace fix and InputNumber buttonThemeOverrides fix landed,
see the top entries).

# NUI.Code + Equation + Log — CLOSED (6 commits, oracle-audited) — **100% COVERAGE: every naive-ui user-facing component is now ported**
- [x] premise CORRECTION — handoff/tabs-recon said "only code+equation remain"; truth was
      code + equation + **log** (329/67/37 L + cssr + theme, no README row, missed by every
      recon) + handoff's "prismjs" was wrong — it's **highlight.js** (hljs). User picked
      all three as one batch.
- [x] recon — tasks/recon/code-family-{1-upstream,2-elm,pins}.md via deepseek lane (532/456/
      227+§R L; found: Code emits **15** vars not 16 — cssr header's --n-line-number-color
      stale; equation = empty-self theme-only entry (tooltip precedent); elm/url dep needed;
      innerHTML via HA.property "claimed confirmed in jsdom")
- [x] prep — `a5af0da` (manifest ×3, equation cssr:[] + **extract-css bPrefix '.n-' fix** —
      code's hljs token rules are the ONLY cssr reading props.bPrefix, were rendering as
      `undefinedcode` selectors; **elm-name hyphen-key mapping** mono-3→mono3, hue-5-2→
      hue52; **check-theme empty-record guard** (Equation Vars = {} parses now); gate 8/8
      counts unchanged)
- [x] feat — `d6cb7e6` (lane; Code 353 L + Equation 208 L + Log 413 L + elm/url + examples
      ×3 + README ×3 + check-dom; **FLAG: elm/html kernel BLOCKS innerHTML** —
      _VirtualDom_noInnerHtmlOrFormAction remaps it; recon's jsdom "confirmation" never
      went through Elm's vdom; lane rendered strings as escaped text + flagged honestly)
- [x] fix (rawhtml) — `0293c7b` (lane; **NUI.Internal.RawHtml 480 L** pure HTML-subset
      parser — elements/attrs/entities/void/self-close/comments + total recovery; 4 render
      sites swapped; INTERNAL set; 19-case semantic harness + integration proof)
- [x] fix (reconciliation, in-context) — `4da5e4f` (branch-faithful render paths: Code
      innerHTML(highlighted)/textContent(plain) — plain code with markup stays TEXT, the
      source-viewer core case; internalNoHighlight forces plain (hljsRef undefined,
      Code.tsx:37); LogLine text-child when language UNSET vs parse-when-set incl the
      raw-fallback innerHTML quirk)
- [x] test — `00f76af` (149 eq + 82 DOM pins incl RawHtml grammar + §D27-28 branch-faithful
      probes; **tester lane died on DeepSeek API timeout at the last RED — salvaged
      in-context**; the RED = shared countVars `[a-z-]+` regex undercounting digit-bearing
      --n-mono-3/hue-* names → varOrder-based cfCountVars for the Code probe; gate
      **4141/4141 + 2508 DOM, 0 failures**)
- [x] oracle + fix — `c53ad43` (audit tasks/recon/code-family-oracle.md: **0 S** — all four
      modules byte-derive; D1 fixed internalFontSize Just 0 → theme fontSize (JS falsy,
      +2 pins); D2/R1/R4 docstring'd; R2 pins-honesty + R3 generator-literal noted here)

## Trail outcome (for the next session)
Code family COMPLETE — the port now covers EVERY naive-ui v2.45.3 user-facing component.
NUI.Code (Hljs caller-supplied record {getLanguage, highlight code language→String};
codeHtml two-gate mirror; lineNumbers RAW-code post-increment loop; 15 vars; uri decode
via Url.percentDecode w/ [D] on JS-throw). NUI.Equation (katex : Maybe (String→String)
caller-bound closure; extract = the wrapper regex + two anchored strips + 'no katex
provided' fallback; no BEM class, theme empty). NUI.Log (pure mergedLines/styleHeight/
scrollEvents/wheelEvents — wheel top STRICT ===0, scroll <=, RequireMore precedes Reach,
both ends can fire; Scrollbar+Code composition; loader w/ Loading.spinner strokeWidth 24
scale .85; loadingText default 'Loading'). **NEW PORT-WIDE PATTERN: NUI.Internal.RawHtml**
— pure machine-markup parser standing in for innerHTML (kernel-blocked); branch-faithful:
parsed ONLY where upstream uses innerHTML, Html.text where upstream uses textContent/slot
text. elm/url is now a direct library dep.

# NUI.Carousel — CLOSED (5 commits, oracle-audited) [previous batch]
- [x] recon — tasks/recon/carousel-1-upstream.md via deepseek lane (9 sections: DOM
      byte-map incl arrow d-strings, cssr 358 L rule table, theme 7-key self dark=common
      swap, 16 upstream its, 18 demos; NO rtl) + carousel-2-elm.md in-context (design:
      raw-Html render strategy — cssr owns track flex; State machine incl expectedDirection/
      previousTranslate/inTransition; Env one-stop derive; applyIndexChange watcher body
      with display→real REFLOW + loop-jump normalization; caller-owned clock/measurement/
      drag-subs/focus) + carousel-pins.md (§A A1-A6 worked numbers, §E 20 eq groups,
      §D 14 probe groups, §T traps incl -0 and style key order)
- [x] prep — `b6c123e` (manifest carousel no-rtl + extract css 224 rules + theme 7-key
      + NUI.Theme.Carousel exposure; gate 8/8 counts unchanged 3838/3838 + 2336)
- [x] feat — `7b40a44` (lane; NUI/Carousel.elm 2118 L + elm.json + examples
      carouselSection + README row + check-dom .n-carousel; NO ALLOW) + reconciliation
      fix `5f94bdf` (getLastViewTranslate gate → upstream's NARROW
      displaySlidesPerView=='auto'; pins A4 CORRECTED 900→1500 — lane had matched my
      wrong pin over the bytes and flagged it honestly)
- [x] test — `bc721dd` (lane; 88 eq pins + 55 DOM probes, ZERO REDs; A5 flick END-state
      refined: fixTranslate overwrites the clone target; gate 3981/3981 + 2424)
- [x] oracle + fix — audit tasks/recon/carousel-oracle.md (4 S / 8 D / 5 R; pins honest
      except §D10 CIRCULAR) → `36e076c` (S1 usercontrol wrapper>ITEM structure w/ vShow
      display:none on the inner slide + size-only styles; S2 dragEnd flick = Vue's ASYNC
      watcher order → END translate 0; S3 non-sequence tracks NO style attr; S4
      onSlideClick card gate wired; §D10 re-pinned + 6 new probes + 2 eq pins; gate
      **3992/3992 + 2426 DOM, 0 failures**)

## Trail outcome (for the next session)
Carousel COMPLETE: NUI.Carousel single module (2150 L) — Options (~35 fields incl Maybe
msg channels) + State (displayIndex/slideCount/perViewSize/autoSlideSizes/translate/
translateSpeed/previousTranslate/inTransition/expectedDirection/mounted/drag fields) +
Env one-stop derive + the full pure algebra (resolveSpeed/clampValue/duplicatedLogic ×6/
duplicateWrap/envOf/getTranslate/getLastViewTranslate/translateTo/fixTranslate/
applyIndexChange/toRealIndex/to/prev/next/guarded ×2/transitionEnd/dragStart/dragMove/
dragEnd/wheel/dotKeyAction/indexChange/slideInfo/autoplayEnabled/decodeDragPoint) +
view/viewDots/viewArrowGroup as ONE raw-Html tree (slides are List (Html msg); root
attrs are Html.Attribute). Rendering strategy precedent: cssr-owned-flex surfaces →
raw Html via Element.html. Caller-owned: autoplay clock, measurement (resize/
setSlideSizes), document drag subs, focus, capture-click suppression, globalDragging.
KEY derivations now encoded in tests: loop-jump display→real reflow + clone-animate +
transitionEnd snap; Vue async-watcher flush order in dragEnd's flick branch (deferred
applyIndexChange lands AFTER the sync fixTranslate — END translate = clone target);
non-sequence tracks carry no style; getLastViewTranslate narrow auto-gate (1500);
defaultIndex seeds with TRUE count (upstream setup-order quirk documented).

# NUI.Upload — CLOSED (4 commits, oracle-audited) [previous batch]
- prep `1806499` → feat `9c763cb` (NUI/Upload.elm 1590 L + Button.varOverrides seam) →
  test `dc69935` (117 eq + 65 DOM; tester lane crashed, finished in-context; 6 REDs all
  expectation-side, zero port fixes) → oracle+fix `9bf03f4` (S1 file-row class order
  with-url-before-type + circular probe re-pinned; S2 url=Just "" falsy → fileUrlTruthy;
  gate 3838/3838 + 2336 DOM 0 fail). Full audit: tasks/recon/upload-oracle.md.

# OLD TRAILS

# NUI.TimePicker + NUI.DatePicker — batch todo (mirrors tasks/plan.md)

## TimePicker + DatePicker — single batch (recon: tasks/recon/date-picker-{1..6}-*.md, pins: tasks/recon/date-picker-pins.md, audit: tasks/recon/date-picker-oracle.md)
- [x] Task 1: prep(time-picker,date-picker) — `138f844` (manifest ×2 + extract + theme exposure; landed via leftover lane from prior session, gate 8/8 verified)
- [x] Task 2: feat(time-picker) — `5166b12` (Input focus seams + TimePicker.elm 1662 L + examples + README + check-dom/ALLOW, gate 8/8)
- [x] Task 3: feat(date-picker) — `15c39b8` (Internal/DateTime.elm 2226 + DatePicker.elm 2946 + Input pair seam + examples + check-dom/ALLOW/exposure, gate 8/8)
- [x] Task 4: test — `5b897f2` (72 eq pins + 26 DOM probes, pins-first, ZERO port fixes needed; gate 8/8 @ 3562/3562 + 2155)
- [x] Task 5: fix — `b8549b5` (oracle round: S1 zone-consistent grid, S2 firstWeekContainsDate 4→1 + parse setters, 4 re-pins + 5 new zone pins + 1 DOM fixture, 7 D findings docstring'd)

## Checkpoint
- [x] gate 8/8 green — 3568/3568 assertions + 2160 DOM @ `b8549b5` (baseline 3464 + 2083 @ `05e2ce1`; batch added +104 assertions, +77 DOM)

## Trail outcome (for the next session)
Selection family COMPLETE: NUI.TimePicker (view + caller-mounted cols panel, UnitFilter,
pure formatValue/parseInput/snapNow) and NUI.DatePicker (single + pair trigger via Input
seams, all 11 panel types — date/week/datetime/month/year/quarter + daterange/datetimerange/
monthrange+yearrange+quarterrange, panelHeader quick-jump, click algebra as pure helpers:
defaultActions/sanitizeValue/singleDateClick/dualDateClick/dualHover/colItemClick/
quickMonthClick/shortcut effects). Input.elm grew two additive default-off seams: focus
control (passivelyActivated/activated/internalForceFocus/textDecoration/attrSize/onFocus/
onBlur/clearIconPlaceholder) + PAIR mode (pairValue/pairPlaceholder/pairTextDecoration/
separatorNode/onPairInput w/ PairSource). New unexposed shared engine
src/NUI/Internal/DateTime.elm (civil math, date-fns v4 format/strictParse subset,
getWeek/getWeekYear fwcd=1, dateArray/item model, defaultTime helpers) — Calendar/Heatmap
could later migrate onto it (dedup opportunity, not done).

Oracle S findings (both fixed in b8549b5, worth remembering):
- S1 grids were UTC-interpreted while clicks/format were zone-aware → non-UTC zones
  highlighted/emitted the wrong civil day. Fix: private gridTs/gridValueTs rebase anchor/
  value/now into UTC-midnight-of-local-civil-day before the builders.
- S2 week numbering used firstWeekContainsDate=4; naive-ui v2.45.3 (date-fns v4, enUS
  locale options) uses fwcd=1 with weekStartsOn=0 → year-boundary weeks were off
  (2004-12-31 formats "2005-1", NOT "2004-52"). NOTE: firstDayOfWeek is NEVER threaded
  into format/parse upstream (only into week span matching) — do not "fix" that again.

## Dedup batch (post-handoff, same session)
- [x] recon — tasks/recon/dedup-1.md (helper map MIGRATE/ADAPT/KEEP; TRAP: `DT.dateArray` hardcodes strip=false protect — Calendar grid is upstream strip=true, 18 months/2020-30 diverge, KEEP)
- [x] refactor — `20de030` (leaf re-points §5 steps 1-11 + thin wrappers only; Calendar −71 / Heatmap −74; step-11 exact-ms pin held, converge deleted; DateTime.elm untouched; gate counts EXACTLY 3568/3568 + 2160, zero test edits — independently re-verified)

## Tabs batch (CURRENT — PREMISE CORRECTED by recon: NUI.Tabs already ported 2026-09-21, `2eeef25`+`e705d4b`, fully gate-wired; README row was missing → handoff mislabeled it unported)
- [x] recon — tasks/recon/tabs-1-upstream.md + tabs-2-elm.md (also found: README stale for 10 modules; truly unported = carousel, code, color-picker, equation, upload)
- [x] Task 1: docs(readme) — `8d9ec4a` (10 rows: Tabs, Heatmap, Form, Descriptions, DynamicInput, FloatButtonGroup, Highlight, IconWrapper, LoadingBar, NumberAnimation; gate 8/8, counts unchanged)
- [x] Task 2: oracle audit — `tasks/recon/tabs-oracle.md` (2 S: leftPadded raw-justify gate, add tab missing tabClass; D1-D9 doc/divergences; R1-R9 verdicts otherwise OK; D10: recon overstated gate gaps — inspect.mjs already has ~35 tabs probes, real gap = segment nav class unasserted)
- [x] Task 3: fix(tabs) — `a224015` (S1 leftPadded gate on resolved justify, S2 add tab inherits tabClass, 6 × [oracle D] docstrings, +3 DOM probes; gate 8/8 @ 3571/3571 assertions, DOM failures=0)
- Checkpoint: batch CLOSED. 2 commits: `8d9ec4a` docs(readme) + `a224015` fix(tabs). NUI.Tabs now oracle-audited like every other component.
- Baseline: 3568/3568 assertions + 2160 DOM @ `20de030` (gate must stay 8/8; deltas recorded here)

## ColorPicker batch (CLOSED — oracle-audited like every other component)
- [x] recon — tasks/recon/color-picker-1-upstream.md + color-picker-2-elm.md (18-prop API,
  VBinder/clickoutside mount, seemly@0.3.10 = ALL the color math, 10-var order, R1-R10 risks)
- [x] Task 1: prep — `baffd42` (manifest + extract: css +193L, theme 13-key self, dark=common
  swap only; NUI.Theme.ColorPicker exposure; gate 8/8 counts unchanged)
- [x] Task 2: feat — `0145e28` (NUI.Internal.Color 1611L engine — seemly bytes + utils.ts +
  unit normalizers + drag geometry; NUI.ColorPicker 1166L view/panel split, 10 vars BOTH
  surfaces, 149-entry named table; examples + README + check-dom targets; gate 8/8;
  11 divergences docstring'd; lane's elm.json deviation endorsed — brief gap, recon-2 §2.3)
- [x] Task 3: test — `f6b9b37` (pins-first, 111 eq + 35 DOM probes, ZERO port fixes;
  3717/3717 + 2271; pins derived from LOCAL tools/node_modules/seemly@0.3.10 via node -e)
- [x] Task 3.5: refactor — `934a455` (− 70L: seemly toHex{,a}String(string) overloads dead
  in naive-ui too — module contract says "subset naive-ui depends on")
- [x] Task 4: oracle + fix — audit `tasks/recon/color-picker-oracle.md` (engine BYTE-IDENTICAL
  to seemly incl. 149/149 named table + floatModBy invariant proof; pins honest, none
  circular; S1 actionSlot gap, S2 A-unit flex-grow 1.25; D13-D18 new) → `8a5ded8`
  (S1+S2 fixed, D13-D18 docstring'd, +2 DOM probes; 3719/3719 + 0 fail)
- Baseline for next batch: **3719 assertions + 2271 DOM, 0 failures** @ `8a5ded8`
- Corrections vs recon: named table is **149** entries (recon said 148; port copied the real
  colors.js); hsv2rgb(0,0,100) = WHITE (my brief's example was wrong; pins doc records truth)

## Carried notes
- Upstream mount path quirk: date-picker panel/composables live under
  src/date-picker/src/panel/ (recon docs cite them relative to src/date-picker/src/).
- date-fns ground truth = the version naive-ui pins (v4.1.0), NOT v2 — derive pins with
  `TZ=UTC node -e` against the mounted node_modules copy (when present).
- Lane mechanics: ZhipuAI subagent path was DOWN all session (stream idle >90s deaths,
  revive falls back to broken ZhipuAI default model → HTTP 1211). Working pattern:
  file-based briefs (tasks/brief-*.md) + FRESH spawns on provider=deepseek; NEVER revive
  provider-overridden sessions (loses the override); large-payload prompts die at first
  token — keep spawn prompts one-liners pointing at brief files.
- tester specialist still guard-dead (tree-select note confirmed); pins-first two-phase
  brief worked well on a DeepSeek general agent (72 pins, zero port fixes).
- data-header/data-action `"true"` divergence — CLOSED by `d78d0d1` (see the top entry:
  the sweep covered the whole port, not just SelectMenu/Cascader).
- Deferred from data-table: unchanged.
- Next candidates: CORRECTED twice (tabs recon; color-picker batch landed) — truly
  unported user-facing surfaces are now ONLY: carousel, code, equation, upload
  (+ upload/equation are DOM/file/KaTeX-bound; carousel transition-heavy/weak
  static fit).
- Lane quirk (new): a fix lane told NOT to commit still committed to master from
  the main workspace (its git ran outside its worktree) — verify HEAD after every
  lane, and diff worktree-vs-master blob hashes before re-applying patches.
- NEW (code-family batch): **jsdom-verify ≠ Elm-verify** — a recon "confirmed in jsdom"
  for HA.property "innerHTML" was false THROUGH Elm (kernel remap). Any future
  DOM-injection assumption must be verified via a compiled Elm render, not raw jsdom.
- NEW: tests/inspect.mjs shared `countVars` regex `--n-[a-z-]+:` undercounts digit-bearing
  var names — Code probes use the local varOrder-based `cfCountVars` instead; contained
  (code is the only digit-named emitter today), fix the shared helper if a second one
  appears.
- Oracle R3 (noted, no action): NUI.Theme.Log light `--n-loader-border` is a value-
  identical literal vs upstream's `${borderColor}` — house-wide generator provenance
  pattern; oracle R2: RawHtml §E22 pin asserts the intermediate tree, DOM pins are the
  independent witnesses.
