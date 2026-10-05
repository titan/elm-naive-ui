# Recon: test/gate hooks constraining the "Live → Sections" interactivity refactor

Scope: read-only survey of every hook that will break if `examples/src/Live/*.elm` demos
move into `examples/src/Sections/*.elm` and the `Live · *` sections are deleted.

**Headline finding (read this first):** `tests/inspect.mjs` has **two independent jsdom
instances**. The `#live-*` id namespace is used by BOTH, and they are **disjoint**:

| Instance | Document | Line range | Ids | Count |
|---|---|---|---|---|
| **#1 (static)** | `tests/index.html` (built from `tests/src/Main.elm`) | 1 – 11921 | `#live-*` = **static fixture ids** | 676 unique |
| **#2 (live)** | `examples/index.html` (built from `examples/src/Main.elm`) | 11922 – 12547 | `#live-*` = **Live/* demo ids** | 39 unique |

`comm` of the two id sets against `examples/src/**.elm` shows **zero overlap**: every
static-phase `#live-*` id is declared in `tests/src/Main.elm` (691 `HA.id "live-…"`
sites), and every live-phase `#live-*` id is declared in `examples/src/Live/*.elm`.
**Do not "clean up" the id prefix** — renaming `live-*` → something else in either
surface is safe only if done in lockstep with `tests/inspect.mjs`, and the static set
(676 ids / ~1800 references) is far larger than the live set (39 ids / ~120 refs).

---

## 1. `tests/inspect.mjs` (12 567 lines) — the primary risk

### 1.1 Phase structure and error isolation

| Phase | try/catch | Lines | Error sink | Prefix on failures |
|---|---|---|---|---|
| Static DOM assertions (instance #1) | **none** (top-level, unguarded) | 1 – 11921 | throws → process dies with stack | `DOM: …` |
| Live · Overlays (instance #2) | `try {` 11979 / `} catch` 12187 | 11922 – 12191 | `domChecks.push({name:'LIVE/OVR driver error', ok:false, detail:stack})` | `LIVE/OVR: …` |
| Live 2 · Controls | `try {` 12250 / `} catch` 12377 | 12193 – 12379 | `LIVE/CTL driver error` | `LIVE/CTL: …` |
| Live 2 · Motion | `try {` 12381 / `} catch` 12467 | 12381 – 12469 | `LIVE/MOT driver error` | `LIVE/MOT: …` |
| Live 2 · Pickers | `try {` 12471 / `} catch` 12545 | 12471 – 12547 | `LIVE/PICK driver error` | `LIVE/PICK: …` |

- **The four live phases are independent** — a throw in one is caught and recorded as a
  single failed check; the next phase still runs. But **within a phase, one throw kills
  the rest of that phase** (all subsequent assertions in the phase are silently skipped,
  surfaced only as the one `… driver error` line). Keep the per-phase order stable.
- **The static phase is NOT guarded.** Any `querySelector` returning `null` that is then
  dereferenced (e.g. `dtThs('live-data-table-sort-desc')[0].firstElementChild` at 9353)
  throws at top level and aborts the whole run before the live phases are even booted.
- Reporting: 12549 – 12567 — all checks (`elmChecks` + `domChecks`) printed, exit 1 if
  any failure. `#results` `data-total`/`data-failures` come from `tests/src/Main.elm`
  (13333–13334) and are printed but **not** compared.

### 1.2 Live-phase DOM ids (instance #2) — 39 ids, all owned by `examples/src/Live/*`

Every one of these must survive the move (they can move to `Sections/*`, but the id
string must stay). Grouped by family with the assertions they gate:

**Overlays phase (11979 – 12191)** — helper `ovlLiveOk` (11961) pushes `LIVE/OVR: …`.

| id | lines | asserts |
|---|---|---|
| `#live-dropdown-click` | 11985 – 11996 | host exists; `.n-dropdown-menu` absent initially; `#live-dropdown-menu.n-dropdown-menu` mounts on trigger click; leaf click `Edit` closes; body text contains `onSelect → 'edit'` |
| `#live-dropdown-hover` | 12001 – 12008 | `.n-dropdown-menu` absent initially; `mouseenter` opens; `mouseleave` closes |
| `#live-popover` | 12012 – 12028 | `.n-popover` absent initially; `Show` opens `.n-popover.n-popover-shared` + `.n-popover__header`; footer `Close` unmounts; `nearestPreceding('.n-switch')` pins it; `Close` cannot unmount while pinned; unpin releases |
| `#live-tooltip-region` | 12032 – 12039 | `.n-tooltip` absent initially; `mouseenter` mounts `.n-tooltip.n-popover-shared`; `mouseleave` unmounts |
| `#live-popconfirm` | 12044 – 12057 | `.n-popconfirm__panel` opens on `Delete project…`; `Cancel` closes + body text `negative — kept`; `Confirm` closes + `positive — deleted` |
| `#live-modal` | 12061 – 12083 | `.n-modal-container` absent initially; `#live-modal-tree.n-modal-container` + `.n-card.n-modal` mount on `Open modal`; `Ticks while open: 0` → `2`; `.n-modal-body-wrapper` click closes (mask) + `closed via mask click`; `.n-card .n-base-close` closes + `closed via the header ✕ (onClose)` |
| `#live-modal-tree` | 12065 | the modal container root id (nested inside `#live-modal`) |
| `#live-drawer` | 12087 – 12105 | `.n-drawer-container` absent initially; `.n-radio` labelled `left` (global lookup!) + `Open drawer` → `.n-drawer.n-drawer--left-placement` + `.n-drawer-mask`; mask click closes + `closed via onMaskClick`; `.n-drawer .n-base-close` closes + `closed via the header ✕ (onClose)` |
| `#live-dialog` | 12109 – 12125 | `.n-modal-container` absent initially; `.n-dialog.n-modal` mounts; `Not yet` → `onNegativeClick → cancelled`; `Submit` → `onPositiveClick → submitted`; `.n-dialog .n-base-close` → `onClose → dismissed` |
| `#live-message-queue` | 12129 – 12151 | 0 `.n-message` initially; 3× `info`/`success` → 3 queued + `Deploy finished` visible; 3 `button.n-base-close`; first close stamps `.fade-in-height-expand-transition-leave-from` (still mounted); second close splices to 2; `clear` ×2 → 0 |
| `#live-notification-queue` | 12155 – 12162 | `info` ×4 → 4 `.n-notification` (3 settled + 1 evicted) + `.notification-transition-leave-from` + `Build queued` visible |
| `#live-loading-bar` | 12167 – 12184 | no `.n-loading-bar-container` idle; `start` → `.n-loading-bar--starting` with `transition` in style; `kick` → `max-width:80` and no `transition: none`; `finish` → `--finishing` + `.fade-in-transition-leave-from/leave-active`; `start`+`error` → `--error` |

**Controls phase (12250 – 12377)** — helper `s2Ok('LIVE/CTL')` (12243).

| id | lines | asserts |
|---|---|---|
| `#live-button-counter` | 12255 – 12259 | text `Pressed 0 times` → 2 clicks → `Pressed 2 times` |
| `#live-button-reset` | 12261 | click → `Pressed 0 times` |
| `#live-input-controlled` | 12265 – 12274 | inner `<input>`; typing `hi` → caption `value: "hi" · focus: no`; focus → `focus: yes`; `.n-base-clear__clear[data-clear]` (via `inputEl.closest('.n-input')`) → `value: ""` |
| `#live-input-number-stepper` | 12277 – 12308 | caption `value: 3 · buffer: — · valid`; input mirrors buffer; `2x` → invalid; `#live-input-number-commit` no-op while invalid; `5` re-validates; `.n-input__suffix .n-button` ×2 = `[minus, add]`; add → 6; minus → 5; `50` → clamp to 10 on commit; add at max is disabled |
| `#live-input-number-commit` | 12289, 12303 | commit button |
| `#live-switch-toggle` | 12310 – 12316 | `.n-switch` inside; row text `off` → `on` → `off` |
| `#live-checkbox-master` | 12319 – 12326 | row text `checked: 1/3 · master indeterminate` → `2/3` → `3/3` (no `·`) → `2/3` |
| `#live-checkbox-item-1` | 12321, 12325 | **built as `("live-checkbox-item-" ++ String.fromInt index)`** in `Live/Controls.elm:653` — the literal `live-checkbox-item-1` never appears in Elm |
| `#live-radio-group` | 12329 – 12334 | `.n-radio` with text `Guangzhou`; row text `picked: —` → `picked: gz` |
| `#live-rate` | 12336 – 12347 | row text `hovered: — · committed: —`; `.n-rate__item`[2] click → `committed: 3`; `#live-rate-hover-plus` ×2 → `hovered: 1`; `#live-rate-hover-clear` → `hovered: —` |
| `#live-rate-hover-plus`, `#live-rate-hover-clear` | 12339, 12346 | hover stepper buttons |
| `#live-slider-plus`, `#live-slider-minus` | 12350 – 12355 | row text `40 (40%)` → `41` → `39` |
| `#live-range-lo-plus`, `#live-range-hi-minus` | 12359 – 12363 | row text `20 – 60` → `21 – 60` → `21 – 59` |
| `#live-input-otp` | 12368 | `input` ×6 |
| `#live-input-otp-reset`, `#live-input-otp-mask` | 12367, 12373 | row text `0/6 entered`; mask → `input.type === 'password'`; reset → `0/6` |

**Motion phase (12381 – 12469)** — helper `s2Ok('LIVE/MOT')`.

| id | lines | asserts |
|---|---|---|
| `#live-carousel-auto` | 12385 – 12428 | `nearestPreceding('.n-switch')` toggles autoplay OFF first (load-bearing order!); caption regex `slide \d+ / 4 · real \d+`; `.n-carousel__arrow` ×2 = `[backward, forward]`; forward → slide+1 (mod 4) + `· moved a → b`; `.n-carousel__dot` ×4; dot[1] → slide 2; wheel `deltaX ±40` → next/prev (needs `|d| ≥ 10`, first-nonzero axis); `mouseenter` → `· paused`, `mouseleave` removes it |
| `#live-carousel-auto .n-carousel__slides` | 12405, 12412, 12417, 12420, 12424 | `transitionend` dispatched here to clear `inTransition` (jsdom never fires it) |
| `#live-carousel-drag` | 12431 – 12443 | `mousedown` on it, `mousemove`/`mouseup` on **`liveDoc`** at fixed coords (400,100)→(220,100); caption `drag offset … · dragging` mid-gesture, `drag offset 0 px` after |
| `#live-log` | 12445 – 12465 | caption `scrollTop 0 px · 12 lines`; `.n-log-loader` absent idle; `nearestPreceding('.n-button')` for `Scroll up 120 px` / `Scroll down 120 px`; `· loading older…` → 600ms flush → `scrollTop 0 px · 18 lines`; second `Scroll down 120 px` → `· loading newer…` → `scrollTop 210 px · 24 lines`; wheel `deltaY -300` → `30 lines` |

**Pickers phase (12471 – 12547)** — helper `s2Ok('LIVE/PICK')`.

| id | lines | asserts |
|---|---|---|
| `#live-daterange` | 12476 – 12491 | `input` ×2; chip regex `^(unset|\d{13} → \d{13})( · selecting)?$` (shortest match wins); `.n-base-clear__clear[data-clear]` present over a value, hidden when empty |
| `#live-daterange-panel` | 12486 – 12522 | `.n-date-panel.n-date-panel--daterange`; `.n-date-panel-calendar` ×2; day cells (`.n-date-panel-date` minus `--excluded`) by **text content** `12`/`18`; hover preview; `· selecting` suffix; `.n-date-panel-actions .n-button` = `Clear,Confirm`; Confirm closes; pair-input 2 focus reopens |
| `#live-datepicker` | 12526 | `input` |
| `#live-datepicker-panel` | 12529 – 12544 | `.n-date-panel.n-date-panel--date`; day `12` click → caption `committed: 1715472000000`; closes on select; actions `Clear,Now`; Clear → `committed: unset` + closes |

### 1.3 Locality / containment assertions (the "where can a demo block move" constraints)

These are the hooks that break if a demo block's internal layout changes or if the
caption/controls stop being siblings of the component inside one row.

**A. `nearestPreceding` (11973 – 11977)** — the big one.

```js
const nearestPreceding = (selector, filter, cell) =>
  [...liveDoc.querySelectorAll(selector)]
    .filter((el) => (filter ? filter(el) : true))
    .filter((el) => el.compareDocumentPosition(cell) & liveWindow.Node.DOCUMENT_POSITION_FOLLOWING)
    .pop()
```

Comment at 11970 – 11972: *"the live demoRow places its controls right BEFORE the cell
in document order — the nearest preceding match is the live one (the static sections
render far earlier in the page)"*.

**This is the single most fragile hook.** It resolves a control by **document order
relative to the demo cell**, taking the LAST match that precedes the cell. Constraints:
1. The control must appear **before** the cell in document order.
2. It must be the **last** such match before the cell — i.e. no other matching element
   may sit between the control and the cell.
3. **After the refactor the static Sections will ALSO contain `.n-button` / `.n-switch`
   elements.** If a static demo with a `.n-switch` or a `.n-button` with the same label
   is rendered *after* the stateful demo in the page, `nearestPreceding` still works
   (it only looks backwards). But if a static `.n-switch`/matching `.n-button` is
   rendered **between** the control and the cell, the wrong element is clicked.

   Call sites: 12020 (`nearestPreceding('.n-switch', null, host)` — Popover pin switch),
   12133 (`nearestPreceding('.n-button', label, cell)` — Message `info`/`success`/`clear`),
   12157 (Notification `info`), 12170 (LoadingBar `start`/`kick`/`finish`/`error`),
   12388 (`nearestPreceding('.n-switch', null, car)` — Carousel autoplay),
   12450 (`nearestPreceding('.n-button', label, logEl)` — Log `Scroll up 120 px` /
   `Scroll down 120 px`).

   **Safest refactor rule:** keep each stateful demo's controls immediately before its
   cell inside the same `demoRow`, and keep button labels unique page-wide (they already
   are: `Open menu ▾`, `Show`, `Close`, `info`, `success`, `clear`, `start`, `kick`,
   `finish`, `error`, `Scroll up 120 px`, `Scroll down 120 px`, `tick`, `Open modal`,
   `Open drawer`, `Open dialog`, `Not yet`, `Submit`, `Delete project…`, `Cancel`,
   `Confirm`, `Hover me`, `Reset`, `Mask`, `+1`, `−1`, `lo +`, `hi −`).

**B. `s2RowText` (12225)** — `s2Norm(host.parentElement.textContent)`.

> *"the caption is the row's other child"* — the caption must remain a **sibling of the
> host inside the same parent**, and the parent's `textContent` must contain **only** the
> host + caption (any extra sibling text pollutes the match).

Call sites: Switch (12312–12316), Checkbox (12320–12326), Radio (12331–12334),
Rate (12336), Slider single (12350), Slider range (12359), InputOtp (12367).
Note `s2RowText(...).trim()` is used for exact equality on Switch (`'off'`/`'on'`) —
so the parent must contain **nothing but** the switch + the caption.

**C. `s2LeafText` (12218 – 12223)** — deepest `div`/`span` with `children.length === 0`
whose **normalized** textContent matches a regex. Captions render as leaf `Element.text`
divs. Call sites: Input caption (12268–12274), InputNumber caption (12279), Carousel
caption (12390), drag caption (12433), Log caption (12446), single DatePicker chip
(12536). **Constraint:** the caption must stay a leaf text node — wrapping it in another
element that also has text breaks "deepest leaf" matching; adding another leaf with the
same shape elsewhere on the page makes `hits[0]` (document order) win, so **the first
matching leaf in the document must be the right one**.

**D. `ovlBodyText` (11965)** — `liveDoc.body.textContent.includes(...)`. **Global** —
any caption text anywhere on the page satisfies it. Strings asserted:
`onSelect → 'edit'` (11994), `negative — kept` (12051), `positive — deleted` (12055),
`closed via mask click` (12075), `closed via the header ✕ (onClose)` (12081, 12103),
`closed via onMaskClick` (12097), `onNegativeClick → cancelled` (12116),
`onPositiveClick → submitted` (12119), `onClose → dismissed` (12123).
**Risk:** if the same caption string appears in a *static* demo elsewhere on the page,
the assertion passes even when the live one is broken (false green). Keep these caption
strings unique, or scope them to the cell.

**E. `findOvlBtn(label, root)` (11967 – 11968)** — `[...(root || liveDoc).querySelectorAll('.n-button')].find(b => b.textContent.trim() === label)`.
When `root` is omitted (12015 `Show`, 12064/12076/12080 `Open modal`, 12092/12098
`Open drawer`, 12112/12117/12120 `Open dialog`) it searches the **whole document** and
takes the **first** match. **After the refactor, static Sections will contain `.n-button`
elements too** — if any static button's trimmed text equals `Show` / `Open modal` /
`Open drawer` / `Open dialog`, the click lands on the wrong button. Keep those labels
unique page-wide.

**F. Scoped-cell queries** — `cell.querySelector(...)` where `cell` is the demo host:
`#live-modal` (12061–12083), `#live-drawer` (12087–12105), `#live-dialog` (12109–12125),
`#live-message-queue` (12129–12151), `#live-notification-queue` (12155–12162),
`#live-loading-bar` (12167–12184), `#live-dropdown-click` (11985–11996),
`#live-dropdown-hover` (12001–12008), `#live-popover` (12012–12028),
`#live-tooltip-region` (12032–12039), `#live-popconfirm` (12044–12057).
**Constraint:** the overlay body (`.n-modal-container`, `.n-drawer`, `.n-dropdown-menu`,
`.n-popover`, `.n-tooltip`, `.n-popconfirm__panel`, `.n-message`, `.n-notification`,
`.n-loading-bar-container`) must be a **descendant of the host id element**. If the
refactor renders the overlay at the top level of the family section (outside the host),
every one of these breaks.

**G. Global singletons looked up outside any host:**
- 12090 `[...liveDoc.querySelectorAll('.n-radio')].find(r => r.textContent.trim() === 'left')` —
  the Drawer placement radio. **Any other `.n-radio` labelled `left` earlier in the
  document wins.**
- 12267 `inputEl.closest('.n-input').querySelector('.n-base-clear__clear[data-clear]')` —
  containment inside `.n-input` required.
- 12282 `stepper.querySelectorAll('.n-input__suffix .n-button')` must be exactly 2,
  order `[minus, add]`.
- 12343 `s2qa('#live-rate .n-rate__item')[2]` — index 2 = the 3rd star.
- 12399 `s2qa('#live-carousel-auto .n-carousel__arrow')` must be exactly 2, order
  `[backward, forward]`.
- 12410 `s2qa('#live-carousel-auto .n-carousel__dot')` must be exactly 4.
- 12435–12440 `s2Mouse(liveDoc, 'mousemove'/'mouseup', …)` — the drag listeners are on
  **document level**; the fixed coordinates (400,100)→(220,100) assume jsdom's zero
  layout, so they are effectively "event shape" only. Do not move the drag listeners off
  `document`.
- 12499 `s2qa('#live-daterange-panel .n-date-panel-calendar')` must be exactly 2.
- 12514/12540 `.n-date-panel-actions .n-button` labels joined must equal `Clear,Confirm`
  / include `Clear` and `Now` — **order-sensitive** for the daterange case.

**H. Static-phase locality hooks (instance #1) — same class of constraint, different doc.**
These constrain the *static* fixtures in `tests/src/Main.elm`, not `examples/`, but they
show the pattern the refactor must not accidentally copy into the examples page:
- 4109 `rail.contains(bars[0])` (Scrollbar)
- 4291/4298 `popArrowWrapper.lastElementChild`, `popRoot.lastElementChild === popArrowWrapper`
- 4337/4353 `popScBar.parentElement === popSc`
- 4418/4508 `host.firstElementChild === root`
- 4528 `tipRoot.lastElementChild === tipArrowWrapper`
- 4727–4731 `ddLeafPrefix/Label/Suffix.parentElement === ddLeafBody`
- 5068–5069 `ddArrowWrapper.parentElement === ddArrow`, `ddArrow.lastElementChild === ddArrowWrapper`
- 5314–5318 `mCustomScroll.closest('.n-scrollbar')`, `.contains()`, `parentElement` style
- 5374–5375 `mCustomContent.firstElementChild.getAttribute('id') === 'modal-custom-content'`
- 5640/5688 `drDefaultContainer.children[0] === drDefaultMask`, `drDefaultHost.parentElement === drDefaultContainer`
- 5767 `drTrigger.parentElement.children[0] === drTrigger`
- 5791–5816 drawer wrapper/parent/`:scope > .n-scrollbar` relations
- 5943 `drClose.closest('.n-drawer-header')`
- 6319–6320 `title.firstElementChild.classList.contains('n-dialog__icon')`
- 6703 `[...slot.parentElement.classList]`
- 6774–6775 `pcBody(...).firstElementChild.classList.contains('n-popconfirm__icon')`
- 7091 `hs[0].compareDocumentPosition(g) & 4` (SelectMenu group header precedes grouped option)
- 7481–7482 `ph.previousElementSibling === tags`, `!tags.contains(ph)` (BaseSelection placeholder is a SIBLING after the tags div)
- 7841–7842 `kids.findIndex(...)` order (AutoComplete clear before loading)
- 8269 `row.querySelector(':scope > div:not([class])')` (Tree dropMark)
- 8504 watermark container `children[0]` / `children[last]` order
- 8527 `header.closest('.n-menu-item-content')`
- 8603/8616 `:scope > .n-menu-item > …` nesting
- 9353–9354 `dtThs(...)[0].firstElementChild.firstElementChild`
- 9426 `dtRoot(id).querySelectorAll(':scope > div')`
- 9441 `.lastElementChild`
- 9491–9492 `kids.findIndex(...)` order (DataTable wrapper before pagination)
- 10439 `trFirstItem.firstElementChild` class order
- 11088 `cpRoot(...).querySelector('.n-color-picker__fill > div:nth-child(2)')` — **nth-child**
- 11418–11421 `upFileList(...).lastElementChild`
- 11471–11473 `kids[0]`, `bar.classList`
- 11513 `kids[0].tagName === 'SPAN'`, `kids[kids.length-1]`
- 11723 `c.children.length === 1 && c.children[0].classList.contains('n-carousel__slide')`
- 11789 `root.children[0] === cfLineNums(...)`, `root.children[1] === cfPreCode(...)`

### 1.4 Section ordering / nav / sidebar assertions

**There are NONE in `tests/inspect.mjs`.** No `navlink-*`, no `sec-*`, no section-count
assertion. `navlink-` and `sec-` exist only in `examples/src/Main.elm` (441, 544) and
`examples/src/Showcase.elm` (115, 153).

The ordering constraint lives in **Elm**, not in the test:
- `examples/src/Main.elm:566-568` doc comment: *"The ordered body — EXACTLY `navGroups`
  order … The order is load-bearing for navigation: keep the two lists in sync when
  adding a section (93 entries, 1:1 — every section has exactly one sidebar entry)."*
- `navGroups` (201 – 325) ends with the `( "Live", [ "Live · Controls", … "Live · Motion" ] )`
  group at 315 – 323. `navSectionIds` (327 – 331) derives the scrollspy ids from it.
- `body` (566 – 700) ends with the six `section "Live · …"` splices at 682 – 699.
- `scrollSidebar` (425 – 443) reads `navlink-<sectionId>` and `nui-sidebar`;
  `elemY` (446 – 449) is `Browser.Dom.getElement` — a missing id is a `Task.onError`
  fallback (`spySample` 155 – 161 → `1/0`), so a deleted section id degrades the
  scrollspy silently rather than failing a test.

**Consequence of the refactor:** deleting the six `Live · *` entries from `navGroups`
(315 – 323) and the six `section "Live · …"` splices (682 – 699) is **not covered by any
automated gate** — but leaving them out of sync (one list updated, the other not) is only
caught by a human looking at the page. Update both lists in the same edit.

### 1.5 How the live phases are booted (11922 – 11978)

- 11934 `const liveHtmlPath = process.argv[3] || path.join(here, '..', 'examples', 'index.html')`
- 11935 – 11939: if missing → `console.error` + `process.exit(1)` with
  *"build it first: cd examples && elm make src/Main.elm --output=index.html"*
- 11940 – 11946: `new JSDOM(..., { runScripts: 'dangerously', pretendToBeVisual: true, resources: 'usable' })`
- 11979 `await ovlSleep(700)` — the boot settle. **Load-bearing.**
- All `ovlSleep(20|30|50)` and the two `ovlSleep(800)` (12457, 12463) are load-bearing
  (Elm batches patches on rAF; jsdom's `pretendToBeVisual` clock needs a tick). The
  comments at 11928–11931 and 12207–12208 say **do not tidy them away**.

### 1.6 Assertion counts (for regression diffing)

| Phase | Assertions |
|---|---|
| static `dEq` | 984 |
| static `dTrue` | 656 |
| static `dClass` | 16 |
| static `svgNsPin` | 8 |
| `ovlLiveOk` (OVR) | 78 |
| `ctl` (CTL) | 56 |
| `mot` (MOT) | 29 |
| `pick` (PICK) | 25 |

The OVR phase is documented as *"11 scenarios / 78 assertions"* (11926) and round 2 as
*"98 assertions"* (12195 = 56+29+25 = 110 call sites, some shared helpers). If the
refactor changes these counts, that is expected — but a **drop** means assertions were
silently skipped.

---

## 2. `tools/verify/check-dom.mjs` (220 lines)

**What it does:** loads `examples/index.html` in jsdom (line 17 default,
`process.argv[2]` override), waits 700ms (line 181), then for each of the **103 entries**
in the `targets` map (lines 20 – 176) does exactly one `window.document.querySelector(sel)`
(line 187) and asserts:

1. the element **exists** (line 188 – 191) → `MISSING` + failure;
2. `getComputedStyle(el).flexBasis === 'auto'` (line 196, 200) — the elm-ui bridge works;
3. if `needsVars` is true, `el.getAttribute('style')` contains `--n-` (line 197, 200).

Exit 1 if any failure (line 219).

**Critical property: it uses `querySelector` (FIRST match only), never `querySelectorAll`,
never `textContent`, never `nth-child`/`:scope`/`children`/`parentElement`/`closest`.**
(grep confirms: 1 `querySelector`, 0 occurrences of `textContent|nth-|:scope|children|
parentElement|closest`.)

**What can break when a static demo becomes stateful:**

| Risk | Detail |
|---|---|
| **A component root disappears from the DOM** | If a stateful demo renders the component conditionally (`if model.open then … else Element.none`) and the *only* instance of that root class was in that demo, `querySelector` returns `null` → `MISSING`. **Rule: every selector in `targets` must have at least one instance rendered at `init`, unconditionally.** |
| **The first match changes identity** | `querySelector` takes the first in document order. Moving a demo earlier/later in the page changes *which* element is checked. Since the check only asserts `flexBasis` + `--n-*` presence, this is benign **unless** the new first match is a different size/variant whose root legitimately carries no `--n-*` (e.g. if a bare `.n-select` (needsVars=false) became the first `.n-base-selection` (needsVars=true) match — not possible here, different classes, but the pattern matters). |
| **Inline style must keep `--n-`** | The var check is `inline.includes('--n-')` on the **attribute**, not computed style. If the refactor renders a themed root through a path that drops the inline `cssVars` style, it fails. |
| **`flex-basis: auto`** | Comes from `tools/bridge.css` rules 1 (`.nui-root.nui-root [class^="n-"]`). Any root that loses its `n-*` class prefix breaks this. |

**The 103 selectors** (all class-based, no ids): `.n-button`, `.n-input`, `.n-input-otp`,
`.n-card`, `.n-calendar`, `.n-tag`, `.n-alert`, `.n-checkbox`, `.n-switch`, `.n-radio`,
`.n-divider`, `.n-dynamic-tags`, `.n-text`, `.n-h1`, `.n-avatar`, `.n-avatar-group`,
`.n-button-group`, `.n-space`, `.n-badge`, `.n-empty`, `.n-progress`, `.n-result`,
`.n-skeleton`, `.n-spin-container`, `.n-gradient-text`, `.n-statistic`, `.n-breadcrumb`,
`.n-timeline`, `.n-thing`, `.n-marquee`, `.n-list`, `.n-page-header-wrapper`, `.n-affix`,
`.n-split`, `.n-steps`, `.n-ellipsis`, `.n-back-top`, `.n-qr-code`, `.n-collapse`,
`.n-rate`, `.n-float-button`, `.n-pagination`, `.n-input-number`, `.n-layout`,
`.n-layout-header`, `.n-layout-footer`, `.n-layout-sider`, `.n-flex`, `.n-grid`,
`.n-float-button-group`, `.n-icon`, `.n-icon-wrapper`, `.n-heatmap`, `.n-highlight`,
`.n-dynamic-input`, `.n-loading-bar-container`, `.n-loading-bar`, `.n-descriptions`,
`.n-tabs`, `.n-scrollbar`, `.n-popover`, `.n-popconfirm`, `.n-popselect-menu`,
`.n-select`, `.n-cascader`, `.n-cascader-menu`, `.n-tree`, `.n-table`,
`.n-base-selection`, `.n-select-menu`, `.n-auto-complete`, `.n-auto-complete-menu`,
`.n-mention`, `.n-mention-menu`, `.n-tooltip`, `.n-dropdown`, `.n-modal-container`,
`.n-message-wrapper`, `.n-notification-wrapper`, `.n-watermark-container`,
`.n-watermark`, `.n-menu`, `.n-slider`, `.n-image`, `.n-image-preview-container`,
`.n-data-table`, `.n-anchor`, `.n-transfer`, `.n-tree-select`, `.n-tree-select-menu`,
`.n-time-picker`, `.n-time-picker-panel`, `.n-date-picker`, `.n-date-panel`,
`.n-color-picker`, `.n-color-picker-panel`, `.n-upload`, `.n-carousel`, `.n-code`,
`.n-log`.

**Overlay roots are the fragile ones.** `.n-modal-container`, `.n-popover`,
`.n-popconfirm`, `.n-tooltip`, `.n-dropdown`, `.n-message-wrapper`,
`.n-notification-wrapper`, `.n-loading-bar` are only rendered when open/queued. Today
they are all covered by the **static** sections (which render them open from init). If
the refactor makes any of those demos start closed and no *other* demo renders that root
at init, `check-dom` reports `MISSING`. **Keep at least one always-open instance of each
of those roots.**

---

## 3. `check-classes.mjs`, `check-theme.mjs`, `check-exposure.mjs` — do they read `examples/`?

| File | Reads `examples/`? | Evidence |
|---|---|---|
| `tools/verify/check-classes.mjs` | **No** | line 11 `fs.readFileSync(path.join(root, 'css', 'naive-ui.css'))`; line 143 `fs.readFileSync(path.join(srcDir, f))` where `srcDir` is `src/NUI` |
| `tools/verify/check-theme.mjs` | **No** | line 54 `readFileSync(path.join(themeDir, 'Common.elm'))`, line 83–84 `tools/generated/*.json` + `src/NUI/Theme/*.elm` |
| `tools/verify/check-exposure.mjs` | **No** | line 38 `JSON.parse(fs.readFileSync(path.join(root, 'elm.json')))` — the **library** manifest, and it walks `src/` only |

None of them touch `examples/`. The refactor cannot break them (unless it edits `src/`).

---

## 4. `tools/bridge.css` and `css/naive-ui.css` — Live-scoped rules?

**None.** grep for `sc-sec|demoRow|demoBox|nui-root|nui-sidebar|navlink|sec-`:
- `tools/bridge.css` — only `.nui-root`-scoped rules (6 rules: flex-basis, line-height,
  white-space, flex-shrink, select-menu font-size, heatmap keyframes). Nothing scoped to
  `.sc-sec`, `demoRow`, `demoBox`, or any Live layout.
- `css/naive-ui.css` — 9 717 lines of `.nui-root.nui-root …` upstream-extracted rules.
  Nothing Live-scoped.

The **only** page-chrome CSS is in Elm: `examples/src/Showcase.elm:87-107` `chromeCss`:
```
html{scroll-behavior:smooth}
.sc-sec{scroll-margin-top:78px}
.n-drawer-container{height:100% !important}
```
plus the inline styles baked into `demoRow` (169 – 199: card border/radius/background,
`overflow-x:auto;padding:20px` body, `border-top` footer bar) and `demoBox`
(214 – 228: `position:relative;transform:translate(0,0);overflow:hidden`).

**The `.n-drawer-container{height:100% !important}` rule is load-bearing for the Drawer
demo** (comment at 91 – 95: elm-ui's `.s.e > .hc{height:auto}` defeats the drawer
container's stretch inside demo hosts). If the Drawer demo moves to a `Sections/*` module
that renders it in a different host shape, this rule may need re-tuning — but it is
global, not Live-scoped, so a straight move is fine.

---

## 5. `examples/src/Main.elm` + `Showcase.elm` — current Live wiring

### 5.1 `Main.elm` (700 lines)

| Concern | Lines | Content |
|---|---|---|
| imports | 31 – 36 | `import Live.Controls / Live.Data / Live.Motion / Live.Nav / Live.Overlays / Live.Pickers` |
| `Model` | 56 – 65 | `controls : Live.Controls.Model`, `pickers : Live.Pickers.Model`, `overlays : Live.Overlays.Model`, `nav : Live.Nav.Model`, `data : Live.Data.Model`, `motion : Live.Motion.Model`, + `spyYs`/`spyVp`/`prevActive` |
| `init` | 68 – 78 | six `Live.*.init` + spy fields |
| `Msg` | 82 – 95 | `ControlsMsg Live.Controls.Msg` \| `PickersMsg` \| `OverlaysMsg` \| `NavMsg` \| `DataMsg` \| `MotionMsg` \| `SpyRequest` \| `SpyY` \| `SpyVp` \| `NoOp` |
| `update` | 97 – 142 | 101 Controls (no Cmd), 103 – 109 **Pickers returns `( Model, Cmd Msg )`** → `Cmd.map PickersMsg pickersCmd`, 110 Overlays (no Cmd), 113 Nav, 116 Data, 119 Motion, 121 – 142 spy |
| `subscriptions` | 169 – 180 | six `Sub.map XMsg (Live.X.subscriptions model.x)` + `Time.every 350 (\_ -> SpyRequest)` |
| `main` | 183 – 196 | `Browser.element`, `init` also batches `List.map spySample navSectionIds` |
| `navGroups` | 201 – 325 | 6 families + the `( "Live", [ "Live · Controls", "Live · Pickers", "Live · Overlays", "Live · Nav", "Live · Data", "Live · Motion" ] )` group at **315 – 323** |
| `navSectionIds` | 327 – 331 | `navGroups |> List.concatMap Tuple.second |> List.map sectionId` |
| `page` / `content` | 348 – 372 / 559 – 576 | `hero :: (Css.element :: chromeCss :: body model)` |
| `sidebar` / `navGroup` / `navItem` | 493 – 557 | `navItem` emits `HA.id ("navlink-" ++ id)` at **544** |
| `scrollSidebar` | 425 – 443 | reads `elemY ("navlink-" ++ id)` at **441** and `nui-sidebar` |
| `body` | 566 – 700 | 87 static `xxxSection` calls (570 – 680) then the six Live splices at **682 – 699** |

The six splices (verbatim shape):
```elm
    , section "Live · Controls"
        "A real update loop: Button, Input, InputNumber, Switch, Checkbox, Radio, Rate, Slider, InputOtp — state in the model, every channel one Msg."
        [ Element.map ControlsMsg (Live.Controls.view theme model.controls) ]
    -- … Pickers (685-687), Overlays (688-690), Nav (691-693), Data (694-696), Motion (697-699)
```

### 5.2 `Showcase.elm` (311 lines)

| Export | Lines | Notes |
|---|---|---|
| `theme` / `purple` / `darkTheme` | 55 – 65 | shared theme set |
| `chromeCss` | 87 – 107 | the only page-chrome CSS (see §4) |
| `sectionId` | 114 – 135 | title → `"sec-" ++ dashed` (alnum lowercased, non-alnum → `-`, collapsed) |
| `section` | 148 – 162 | `Element.column` with `HA.id (sectionId title)` + `HA.class "sc-sec"`, `Typo.h3` title, ≤720px desc, then `examples` |
| `demoRow` | 169 – 199 | bordered card: `wrappedRow` body (`overflow-x:auto;padding:20px`) + `footerBar label` (uppercase, 11px) |
| `demoBox` | 214 – 228 | bounded preview box for fixed/absolute demos |
| `fillWidth` / `capitalize` / `chip` | 231 – 253 | helpers |
| `starIcon` / `codeHljs` / `fakeKatex` / `fakeKatexDisplay` | 260 – 311 | cross-family fixtures |

**`section` is polymorphic in `msg`** (`section : String -> String -> List (Element msg) -> Element msg`),
so a stateful family section can be spliced with `Element.map XMsg (…)` exactly as the
Live splices do today — no Showcase change needed.

### 5.3 The six `Live/*` modules (shape to replicate per family)

| Module | Lines | `Model` | `init` | `Msg` | `update` | `subscriptions` | `view` | Cmd? |
|---|---|---|---|---|---|---|---|---|
| `Live/Controls.elm` | 735 | 45 | 71 | 102 | 136 (`Msg -> Model -> Model`) | 294 | 303 | no |
| `Live/Data.elm` | 1574 | 63 | 101 | 144 | 201 | 498 | 507 | no |
| `Live/Motion.elm` | 1048 | 63 | 91 | 130 | 173 | 397 (`Browser.Events`, `Time`) | 436 | no |
| `Live/Nav.elm` | 777 | 64 | 119 | 142 | 165 | 324 | 388 | no |
| `Live/Overlays.elm` | 1120 | 66 | 95 | 139 | 181 | 1118 | 550 | no |
| `Live/Pickers.elm` | 1812 | 70 | 111 | 157 | 212 (`Msg -> Model -> ( Model, Cmd Msg )`) | 534 (`Browser.Dom`, `Browser.Events`) | 832 | **yes** |

`Live/Pickers.elm` is the only one returning a `Cmd` — `Main.update` 103 – 109 is the
only `Cmd.map` splice. If Pickers' demos move into `Sections/Pickers.elm`, that module
must expose `update : Msg -> Model -> ( Model, Cmd Msg )` and `Main` must keep the
`Cmd.map` (or the Cmd must be dropped, which would break the DatePicker focus task).

`Live/Overlays.elm` view helpers that encode the demo scaffolding the tests depend on:
- `relHost : String -> Popover.Placement -> List (Element msg) -> Element msg` (928) —
  relative host stacking trigger + popover body, carries the demo id.
- `overlayCell : String -> Element msg -> Element msg` (943) — the mount-body cell
  (carries the demo id; the overlay renders inside it).
- demoRow labels (554 – 811) are the 11 OVR scenarios.

---

## 6. Other references to `Live` / `examples/src/Live/` outside `examples/`

| Location | Reference | Action needed |
|---|---|---|
| `tests/inspect.mjs:11922` | `// --- Live · Overlays — interaction phase ---` | comment only |
| `tests/inspect.mjs:12020-12208` | comments naming `Live/Pickers.elm`, `Input.elm` | comment only — update if the module is deleted |
| `tests/inspect.mjs:12193-12208` | `// --- Live round 2 — Controls / Motion / Pickers interaction phase ---` + the port-gap note *"documented in Input.elm and Live/Pickers.elm"* | comment only |
| `tests/inspect.mjs:12252, 12383, 12473` | `console.log('Live 2 / Controls' \| 'Motion' \| 'Pickers')` | cosmetic output |
| `tests/run.sh:6-7, 25-26` | *"Also builds the live showcase page (examples/index.html) that inspect.mjs's Live · Overlays interaction phase drives in a second jsdom instance"* + the `cd ../examples && elm make src/Main.elm` build | **keep** — the build step is required regardless of where the demos live |
| `scripts/verify.sh:53-57` | `bust_stale_elm_stuff "$here/examples"`, `elm make src/Main.elm --output=index.html`, `node tools/verify/check-dom.mjs examples/index.html` | **keep** — path is `examples/`, not `examples/src/Live/` |
| `docs/ARCHITECTURE.md:142` | `tests/run.sh — DOM + theme assertions over theme maths, cssVars, and live DOM output` | comment only |
| `examples/README.md:14` | *"The page is a static `Html.Html msg` (no model); all examples are inert visuals."* | **STALE** — already wrong today (Main is a `Browser.element` with a model). Update as part of the refactor. |
| `README.md:193`, `docs/ARCHITECTURE.md:150` | `cd examples && elm make src/Main.elm --output=index.html` | keep |
| `examples/src/Sections/Controls.elm:10-12` | doc comment *"the rendered DOM must stay byte-identical (the check-dom gate reads this surface)"* | **This comment is now misleading** — `check-dom` reads `examples/index.html`, so the Sections surface IS the gate. Keep the invariant. |
| `examples/src/Live/{Controls,Data,Nav,Pickers}.elm` header comments | `Oracle-round divergences (tasks/recon/live-oracle.md)` | `tasks/` is out of scope per the brief, but these are dangling doc links once `Live/` is deleted |

**Nothing in `tools/`, `css/`, `src/`, `tests/src/` references `examples/src/Live/`.**
The only code-level coupling is `tests/inspect.mjs`'s live-phase id + locality hooks.

---

## 7. Refactor checklist (derived constraints)

1. **Keep all 39 live-phase `#live-*` ids** (§1.2) — they may move to `Sections/*` but the
   strings must not change. `live-checkbox-item-1` is generated
   (`"live-checkbox-item-" ++ String.fromInt index`).
2. **Keep each stateful demo's controls immediately before its cell inside one `demoRow`**
   — `nearestPreceding` (11973) depends on document order.
3. **Keep captions as siblings of the host inside the same parent, with nothing else in
   that parent** — `s2RowText` (12225) reads `host.parentElement.textContent`.
4. **Keep captions as leaf `Element.text` divs** — `s2LeafText` (12218) picks the deepest
   leaf; and the **first** document-order match wins, so caption text must be unique
   page-wide (or at least the stateful one must come first).
5. **Keep button labels unique page-wide** — `findOvlBtn` with no root (11967) takes the
   first `.n-button` with that trimmed text in the whole document. `Show`, `Open modal`,
   `Open drawer`, `Open dialog`, `Close`, `info`, `success`, `clear`, `start`, `kick`,
   `finish`, `error`, `tick`, `Not yet`, `Submit`, `Cancel`, `Confirm`, `Delete project…`,
   `Reset`, `Mask`, `+1`, `−1`, `lo +`, `hi −`, `Scroll up 120 px`, `Scroll down 120 px`.
6. **Keep overlay bodies inside their host id element** — every OVR assertion is
   `cell.querySelector('.n-modal-container' | '.n-drawer' | …)`.
7. **Keep at least one always-rendered instance of every `check-dom` root** (§2) —
   especially `.n-modal-container`, `.n-popover`, `.n-popconfirm`, `.n-tooltip`,
   `.n-dropdown`, `.n-message-wrapper`, `.n-notification-wrapper`, `.n-loading-bar`.
8. **Keep the Drawer placement radio labelled exactly `left`** and ensure no other
   `.n-radio` with that text precedes it (12090).
9. **Keep `.n-carousel__arrow` ×2 in `[backward, forward]` order and `.n-carousel__dot`
   ×4** for `#live-carousel-auto`; keep the drag listeners on document level.
10. **Keep `.n-input__suffix .n-button` ×2 in `[minus, add]` order** for
    `#live-input-number-stepper`.
11. **Keep `.n-date-panel-actions .n-button` labels in `[Clear, Confirm]` order** for the
    daterange panel and include `Clear` + `Now` for the single panel.
12. **Update `navGroups` (Main.elm 315 – 323) and `body` (Main.elm 682 – 699) in the same
    edit** — no test enforces the 1:1 correspondence.
13. **`Live/Pickers.elm` is the only Cmd-returning family** — if its demos move, keep the
    `Cmd.map PickersMsg` splice (Main.elm 103 – 109) or the DatePicker focus task dies.
14. **Do not shorten the rAF sleeps** in the live phases (20/30/50/700/800ms) — documented
    load-bearing at 11928 – 11931 and 12207 – 12208.
15. **The static phase (lines 1 – 11921) is unguarded** — a `null` deref there aborts the
    run before the live phases boot. If the refactor touches `tests/src/Main.elm`, run
    `node tests/inspect.mjs` early and often.
16. **`examples/README.md:14` is already stale** ("static Html msg, no model") — fix it
    while you are in there.
