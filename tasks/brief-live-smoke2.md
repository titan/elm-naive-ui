# Brief — LIVE smoke round 2: Controls / Motion / Pickers scratch

You are in a git worktree of `/home/titan/Works/elm/elm-naive-ui` (branch off
master @ 4c325a2). Goal: write a **standalone jsdom interaction smoke** for the
live showcase page's Controls, Motion and Pickers families, as a **/tmp scratch
script**. You do NOT edit any repo file and you do NOT commit. Deliverable =
a passing scratch script + a short report.

This repeats a proven pattern: the Overlays family's smoke started as a lane
scratch (`/tmp/live-overlays-smoke.mjs`, since promoted into
`tests/inspect.mjs` as the `LIVE/OVR:` phase — READ `tests/inspect.mjs`
from the comment `--- Live · Overlays — interaction phase ---` to the end;
your scratch reuses its exact idiom: boot JSDOM on the showcase page, dispatch
real DOM events, sleep 30ms between steps, push `{name, ok, detail}` checks,
print PASS/FAIL lines, exit non-zero on any failure).

## Setup (worktree quirks — read once, do once)

```bash
# jsdom is .gitignore'd — worktrees don't inherit it. Copy it:
cp -r /home/titan/Works/elm/elm-naive-ui/tests/node_modules tests/

# build the showcase page (ELM_HOME is shared and already populated):
cd examples && ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=index.html
# TRAP: elm make progress is \r-overwritten garbage — judge by EXIT CODE ($?).
```

Your scratch lives at `/tmp/live-smoke2-probe.mjs` and takes the page path as
`process.argv[2]` (no default). Resolve jsdom the same way inspect.mjs does
(candidates: `tests/node_modules/jsdom/lib/api.js` relative to the worktree —
hardcode via argv[3] or an env var if simpler, just document it in the header
comment). Boot options: `runScripts: 'dangerously', pretendToBeVisual: true,
resources: 'usable'` + a silencing VirtualConsole (copy inspect.mjs). Sleep
700ms after boot before first assertion. The 30/20ms sleeps are load-bearing
(Elm batches patches on rAF; jsdom's pretendToBeVisual clock needs a tick) —
do not tidy them away.

## What you drive — read these first

- `examples/src/Live/Controls.elm`, `examples/src/Live/Motion.elm`,
  `examples/src/Live/Pickers.elm` — the update loops you exercise.
- The port modules they delegate to (semantics come FROM these, derive
  expectations from code, never guess): `src/NUI/InputNumber.elm`
  (`inputUpdate`, `deriveValueFromDisplayedValue`, `displayedValueInvalid`,
  `contextOf`), `src/NUI/Carousel.elm` (`prev/next/to/wheel/dotKeyAction`,
  `dragStart/dragMove/dragEnd`, `indexChange`), `src/NUI/DatePicker.elm`
  (`dualDateClick`, `dualHover`, `sanitizeValue`, `defaultActions`),
  `src/NUI/Log.elm` (`scrollEvents`, `wheelEvents`).
- Helper for locating the demo controls: LIVE/OVR's `nearestPreceding`
  (querySelectorAll + compareDocumentPosition filter, take the LAST match
  before the cell) — the demoRow places controls before the cell.

## Scenario groups (required; assertion counts are targets ±20%)

### LIVE/CTL — Controls family (prefix `LIVE/CTL: `)

Caption texts live in `Live/Controls.elm` (`numberCaption`, otpCaption etc. —
quote formats from there, e.g. InputNumber caption is exactly
`value: <v|—> · buffer: <raw|—> · valid|invalid`).

1. **Button**: `#live-button-counter` click ×2 → label "Pressed 2 times";
   `#live-button-reset` → "Pressed 0 times".
2. **Input**: type into `#live-input-controlled`'s `<input>` (set .value +
   dispatch input event, bubbles) → caption `value: "hi" · focus: no`; focus
   event → `focus: yes`; clear icon click (`.n-base-close` inside the input)
   → `value: ""`.
3. **InputNumber** (the core — ~10 asserts): `#live-input-number-stepper`,
   commit button `#live-input-number-commit`. Initial caption
   `value: 3 · buffer: — · valid`. Then: type `4` → `value: 4 · buffer: 4 ·
   valid` (updateValueOnInput live-sync). Type `2x` (garbage) → buffer `2x`,
   value unchanged, `invalid`. Commit while invalid → NOTHING changes
   (InvalidValue → model). Type `5` → valid. Click the stepper's own +/−
   buttons (discover classes in the rendered DOM / `InputNumber.elm` view) →
   value steps by 1, buffer cleared to `—`. Type `50` (out of range, max 10) →
   assert what `inputUpdate` actually does (read the port; likely keeps value,
   buffer 50, invalid). Commit valid out-of-range → deriveValueFromDisplayed
   clamps? READ the port and assert its real behavior. Also assert the
   `<input>`'s own .value mirrors the buffer.
4. **Switch**: `#live-switch-toggle` click → caption `on`, again → `off`.
5. **Checkbox**: `#live-checkbox-item-1` click → caption `checked: 1/3`;
   `#live-checkbox-master` click → `checked: 3/3`; one item off → caption
   shows `master indeterminate`.
6. **Radio**: click the `gz` radio inside `#live-radio-group` → caption
   `picked: gz`.
7. **Rate**: `#live-rate-hover-plus` ×2 → `hovered: 1`; `#live-rate` click the
   3rd star (discover DOM; onSelect commits float) → `committed: 3`;
   `#live-rate-hover-clear` → `hovered: —`.
8. **Slider single**: `#live-slider-plus` → caption `41 (41%)`;
   `#live-slider-minus` ×2 → `39 (39%)`.
9. **Slider range**: `#live-range-lo-plus`, `#live-range-hi-minus` → caption
   `21 – 59`.
10. **InputOtp**: type into `#live-input-otp` first cell (dispatch input with
    a digit; the port advances focus itself or not — assert the caption count
    `1/6 entered`), `#live-input-otp-mask` toggle, `#live-input-otp-reset` →
    `0/6 entered`.

### LIVE/MOT — Motion family (prefix `LIVE/MOT: `)

**First action of the group: turn autoplay OFF** — click the `.n-switch` in
the same demoRow as `#live-carousel-auto` (nearestPreceding) — otherwise the
3s `Time.every` clock keeps advancing the carousel under you. The caption
format: `slide <n> / 4 · real <r>[ · paused][ · moved <a> → <b>]` — after
~2s of prior phases autoplay may already have ticked, so PARSE the current
`slide n` from the caption and assert DELTAS, not absolutes (loop is on:
n advances mod 4).

1. Caption sanity: matches `/slide \d+ \/ 4 · real \d+/`.
2. Right arrow click (discover `.n-carousel` arrow classes in the rendered
   DOM) → `moved` announce appears; slide number = parsed+1 (mod 4, 1-based).
3. Left arrow → moves back.
4. Dot click (2nd dot; discover dots DOM) → slide 2.
5. Wheel: dispatch a WheelEvent deltaY>0 on the carousel root (mousewheel=True
   is on; find where the port attaches the listener) → advances; deltaY<0 →
   back.
6. Hover pause: mouseenter on root → caption gains `· paused`; mouseleave →
   gone. (Do NOT turn autoplay back on.)
7. **Drag** (`#live-carousel-drag`): mousedown on the track (the port routes
   root mousedown through the `onTouchStart` channel — verify in
   `Carousel.elm`; dispatch MouseEvent mousedown with clientX) → move
   document-level mousemove ×3 with shrinking clientX (Browser.Events
   listens on document — dispatch on `liveDoc` body/document) → caption gains
   `· dragging` and `drag offset` shows a non-zero delta — then `mouseup` on
   document → `dragging` gone. The 20ms DragTick clock needs ≥1 tick between
   move and up for a flick decision; assert END state only (caption flags +
   offset string present), not the intermediate translate.
8. **Log**: `#live-log`. Click "Scroll up 120 px" (button label, find via
   nearestPreceding `.n-button` text) → caption gains `loading older…` +
   `.n-log-loader` appears (discover class); sleep 700ms → 600ms flush appends
   6 lines (caption `18 lines`, `scrollTop` caption unchanged 0). "Scroll
   down 120 px" ×2 → `loading newer…` → flush → 24 lines. Then dispatch a
   WheelEvent on the log element itself (HE.on "wheel" with deltaY) → same
   RequireMore path fires.

### LIVE/PICK — Pickers family, DatePicker daterange (prefix `LIVE/PICK: `)

`#live-daterange` is the trigger (an Input pair); `#live-daterange-panel`
holds the INLINE `DatePicker.panel`, rendered only while `dpRangeShow`. The
chip caption `dpRangeText_` prints RAW MILLISECONDS: initial
`1715299200000 → 1716163200000` (May 10–20 2024; `dpNow` = May 15 2024, the
panel opens on May 2024).

1. Initial: chip = `1715299200000 → 1716163200000`, no `#live-daterange-panel`.
2. Click the trigger's input → panel mounts (`.n-date-panel-daterange` or
   similar — discover).
3. Click a day cell (`.n-date-panel-date`-ish; pick by textContent day number
   in the left month grid) → chip becomes `<tsA> → …` and gains
   `· selecting` (READ `dualDateClick` for what the second slot becomes when
   selecting starts; assert the real shape).
4. Hover a later day (mouseenter on the cell — dualHover) → chip second ts
   tracks the hovered day.
5. Click that later day → selecting ends (`closeOnSelect = False` — panel
   STAYS open; chip shows the pair, no `· selecting`).
6. Click Confirm (panel footer action buttons — `defaultActions Daterange
   True` renders confirm/clear) → panel unmounts; chip pair unchanged (same
   day-granularity ts).
7. Reopen, click Clear (the trigger's clear icon — clearable) → chip `unset`,
   panel closed.

## Contract for the scratch

- One file, `/tmp/live-smoke2-probe.mjs`, runnable as:
  `node /tmp/live-smoke2-probe.mjs <path-to-examples/index.html> <path-to-tests-dir>`
  (second arg for jsdom resolution — your call, document it in the header).
- Print `PASS/FAIL <name>` per check (names prefixed `LIVE/CTL:` /
  `LIVE/MOT:` / `LIVE/PICK:`), a final count line, exit 1 on any failure.
- Scenario bodies must be verbatim-promotable: no console-only debugging left
  in, assertions as data, sleeps as written.
- Each family group wrapped in try/catch → a failed
  `<PREFIX> driver error` check (never a silent skip) — same as LIVE/OVR.
- ZERO repo-file edits. If a scenario seems impossible (event not reachable in
  jsdom), leave it OUT and say so explicitly in the report with the reason —
  an honest smaller smoke beats a faked assertion.

## Verify before reporting

1. `node /tmp/live-smoke2-probe.mjs <worktree>/examples/index.html …` → all
   PASS, exit 0. Run it TWICE (state-leftover / timing sanity).
2. `git status` in the worktree must be clean (no repo edits, no commits).

## Report back (final message)

- The scratch path + exact invocation line.
- Assertion inventory per group (names + pass counts).
- Any scenario you dropped and why. Any DOM fact you had to discover that the
  promotion should know (exact class names, caption formats that differed from
  this brief).
