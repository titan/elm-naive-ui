# Implementation Plan — NUI.TimePicker + NUI.DatePicker (naive-ui v2.45.3 → Elm)

Status: IN PROGRESS · Workspace `/home/titan/Works/elm/elm-naive-ui` @ `05e2ce1`
(branch `master`; untracked `tasks/` by design — do NOT `git add -A`).
Gate: `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` (3464/3464 assertions,
2083 DOM checks, 8/8 gates — post-tree-select baseline).

## Overview

Port the last big selection-family surface as ONE batch, TWO feat commits:
TimePicker (~1.7k upstream L: TimePicker.tsx 1086 + Panel 378 + PanelCol 46 +
utils 279 + cssr/light) then DatePicker (~6k upstream L: root 1216 + 7 panels +
panelHeader + use-calendar/use-dual-calendar/use-panel-common + utils 554 +
validation-utils 225 + config). Trail: prep → feat(time-picker) →
feat(date-picker) → test → fix/oracle. Recon: `tasks/recon/date-picker-{1..6}-*.md`
(1=time-picker+stylesheets, 2=single panels, 3=root, 4=range/datetime,
5=Elm side+enUS locale, 6=Input.tsx pair/focus bytes).

## Architecture decisions

- **Caller-owned show, view+panel split** (Select/TreeSelect precedent, no
  VBinder/VFollower): `TimePicker.view theme opts` = bare `div.n-time-picker`
  > Input (new focus seams) ; `TimePicker.panel theme opts` = the
  `div.n-time-picker-panel` cols tree. `DatePicker.view` = `div.n-date-picker`
  > Input (single) or Input pair (range); `DatePicker.panel theme opts` =
  `div.n-date-panel--{type}` tree. Popover positioning/clickoutside/Escape =
  caller. `transition : Maybe I.TransitionPhase` on panel roots
  (fade-in-scale-up, TreeSelect idiom). focusDetector sentinel last child
  (copy the per-component idiom).
- **Elm-model state lifted into Options** (upstream internal refs): DatePicker
  panel takes caller-owned `calendarValue : Maybe Int` (+ `onUpdateCalendarValue`),
  range adds `endCalendarValue`; datetime header time pickers take
  `timePickerShow : Bool` (+ per-side for datetimerange) and the panelHeader
  quick-jump takes `monthPanelShow : Bool`. Upstream `panel` prop collapses
  away (the Elm `panel` fn IS the bare panel); `--shadow` renders when the
  standalone variant is used (option `shadow : Bool = True`, embedded
  header TimePicker / quick-jump pass False upstream via to=false — mirror
  what the recon bytes show).
- **Value model**: TimePicker `Value = Maybe Int` (ms ts).
  DatePicker `Value = Single (Maybe Int) | Range (Maybe (Int,Int))`
  (SelectMenu collapse precedent). Channels (upstream names):
  `onUpdateValue` (commit; upstream doUpdate=true), `onUpdatePendingValue`
  (preview; doUpdate=false — shortcuts hover, follower-mode month clicks),
  `onUpdateShow`, `onUpdateFormattedValue` (derived internally via
  valueFormat), `onClear`, `onConfirm`, `onFocus`/`onBlur`,
  `onNext/Prev/Month/Year` fire via calendar nav.
- **Zone/now are caller-supplied** (`zone : Time.Zone`, `now : Time.Posix` —
  Heatmap precedent). `timeZone` IANA prop PUNTED (documented).
- **Date engine — new unexposed `src/NUI/Internal/DateTime.elm`** (pure; the
  Calendar/Heatmap math is duplicated, we add the shared one): Hinnant civil
  math (adapted from Calendar.elm :442-543), ts↔Posix via elm/time,
  granularity ops (startOfDay/Month/Year/Quarter/Second, addMonthsClamped,
  addDays, setFields, matchDate :351-418 grid, monthArray/quarterArray/
  yearArray, ISO week (YYYY-w + weekItem), strictParse round-trip :480,
  format tokenizer subset: yy yyyy M MM MMM MMMM d dd H HH h K k m mm s ss
  Q qqq eee eeee eeeeee w YYYY + 'quoted literals'; built-in English month/
  weekday names per date-fns; enUS defaults pinned in recon 5 §9),
  getDefaultTime/extractRangeDefaultTime (:496-548), pluckValueFromRange.
- **Input.elm additive seams** (Button.attributes precedent; default-off,
  standalone-input bytes regression-pinned): `internalForceFocus` (renders
  n-input--focus), `textDecoration`, `attrSize`, `onFocus`/`onBlur`
  attributes, and PAIR mode (`pairValue : Maybe (String,String)` +
  `pairPlaceholder`, `separator : Maybe (Element msg)`, renders
  n-input--pair / n-input__input-el ×2 / n-input__separator + onUpdateValue
  with source). Exact DOM per `tasks/recon/date-picker-6-input.md`.
- **TimePicker trigger** = Input + focus seams + Time glyph (inline
  `Svg.node`, Calendar.chevronLeft idiom; 7 glyphs ported across the two
  modules: Time, Date, To, Backward, Forward, FastBackward, FastForward —
  none exist yet).
- **Embedded datetime TimePicker** (recon 1 §e): DatePicker.panel's header
  renders TimePicker trigger + inline cols (to=false/showIcon=false/
  stateful=false bytes) driven by the lifted `timePickerShow` option.
- **Click algebra as pure helpers** (tree-select precedent): single
  handleDateClick/quick-jump, dual handleDateClick (start→end→complete +
  closeOnSelect :437 branch), handleColItemClick (reversed-normalize +
  otherPartsChanged), changeStartEndTime (defaultTime + source flag),
  sanitizeValue per type, mergedIsDateDisabled detail shapes (single obj vs
  dual bare-ts), actions derivation table (recon 3 §5), justifyColumnsScrollState
  PUNTED (Scrollbar has no scrollTo — document; cssr bytes unaffected).
- **Punts** (documented in module docstrings + recon): VirtualList windowing
  (full year list 1901–2100, Cascader/TreeSelect precedent),
  disableTransitionOneTick (one-tick DOM toggle; cssr rule still ships),
  programmatic scroll anchoring, IANA timeZone, keyboard arrow nav
  (upstream-dead code), DefaultTime/Shortcuts FUNCTION forms (static strings/
  values only), form-item context (size/status direct options).
- **Theme**: manifest entries `time-picker` + `date-picker` (order after
  tree-select), extract → `NUI.Theme.{TimePicker,DatePicker}` (exposed in
  prep; component modules exposed in their feat commits), rtl.ts peers-only
  where upstream. Peers: TimePicker {Scrollbar, Button, Input};
  DatePicker {Input, Button, TimePicker, Scrollbar}.
- **enUS defaults baked** (recon 5 §9): monthFormat 'MMM', dayFormat
  'eeeeee', quarterFormat 'yyyy-qqq', weekFormat 'YYYY-w', monthBeforeYear
  True, firstDayOfWeek 6 (naive 0=Mon numbering; transform (x+1)%7),
  placeholders/Select Time|Date texts; locale overridable via Options
  (Calendar.Locale precedent).

## Trail

1. prep — manifest ×2 + `npm run extract` + elm.json exposes the GENERATED
   theme modules only; gate green (tree-select 85a8a0c precedent: check-dom
   targets + component exposure move to feat)
2. feat(time-picker) — `src/NUI/TimePicker.elm` (~700 L) + Input seams
   (focus control + textDecoration + attrSize) + Time glyph + time format
   mini-engine + examples timePickerSection + README row
3. feat(date-picker) — `src/NUI/Internal/DateTime.elm` (engine, ~600 L) +
   `src/NUI/DatePicker.elm` (~2000 L: view/pair trigger, 9 panel types,
   panelHeader quick-jump, algebra) + Input pair seam + 6 glyphs + examples
   datePickerSection + README row + check-dom targets for both panels
4. test — pins-first (recon docs BEFORE reading port output): eq pins
   (engine: format/strictParse/dateArray/ISO week; algebra: click flows,
   actions table, sanitize) + DOM probes (trigger DOM per branch, panel DOM
   per type, cssVars order, class arrays). Written in-context or fixer with
   strict tool-hygiene (tester specialist is guard-dead ×2 — do NOT use).
5. fix — oracle byte-fidelity audit (absolute path map from recon doc tails;
   S→fix, D→document)

## Verification

Gate after every commit. Baseline to beat: 3464 assertions + 2083 DOM.
Oracle gets the 6 recon docs + the pins file as the path map.
