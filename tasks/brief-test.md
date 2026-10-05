# BRIEF — test(time-picker, date-picker) — Task 4, PINS-FIRST

Workspace: /home/titan/Works/elm/elm-naive-ui (HEAD `15c39b8`; gate 8/8 green, baseline 3464/3464 assertions + 2083 DOM probes). Commit directly, explicit paths only, `tasks/` untracked.

## PHASE A — pins doc FIRST (do this BEFORE reading any port module output)
Write /home/titan/Works/elm/elm-naive-ui/tasks/recon/date-picker-pins.md, P1..Pn, each pin = id + one-line expectation + DERIVATION (upstream file:line or date-fns ground truth). Derive expectations ONLY from:
- /home/titan/Works/elm/naive-ui/src/time-picker/src/{utils.ts,Panel.tsx,PanelCol.tsx,TimePicker.tsx} (paths directly under src/time-picker/src/)
- /home/titan/Works/elm/naive-ui/src/date-picker/src/panel/* + utils.ts + DatePicker.tsx (panel files under src/date-picker/src/panel/)
- /home/titan/Works/elm/naive-ui/src/locales/common/enUS.ts (locale defaults)
- date-fns v2 ground truth for fixed UTC timestamps (compute via node if needed: `node -e` with the format/parse tables below, or derive by hand from calendar math — the engine lane verified against date-fns docs cases incl. getWeek 53/2004)
- recon docs tasks/recon/date-picker-{1..6}-*.md for DOM/cssVars orders.
In Phase A you may NOT open src/NUI/TimePicker.elm, src/NUI/DatePicker.elm, src/NUI/Internal/DateTime.elm, src/NUI/Input.elm.

Pin coverage (minimum):
- P1 engine format: fixed ts (use 1715300000000 = 2024-05-09T23:33:20Z, and 1704067200000 = 2024-01-01T00:00:00Z) × tokens yyyy-MM-dd, yyyy-MM-dd HH:mm:ss, MMM, eeeeee, yyyy-qqq (Q2 cases), yy, H vs HH padding, quoted literal ("yyyy-'Q'Q" if supported → else 'Q'+quarter), YYYY-w for 2024-01-01 (ISO week 1 of 2024) and the 2004/53 documented edge.
- P2 strictParse: round-trip accepts '2024-05-09' @ yyyy-MM-dd; rejects '2024-02-30'; rejects '2024-5-9' (round-trip mismatch); accepts '23:33:20' @ HH:mm:ss → ts of that time on epoch-day-in-zone; rejects '23:33:20' @ HH:mm (no seconds token).
- P3 dateArray: month anchor 2024-05-01 (ts 1714521600000), valueTs single 1715300000000, nowTs same, startDay 6 (enUS Sunday-first), strip False → exactly 42 items; first cell = 2024-04-28 (Sunday); last = 2024-06-08; flags: cell 2024-05-09 selected True, 2024-05-08/10 selected False; weekMode variant: inSelectedWeek for the 7 cells of the selected week (startOfWeek-adjusted).
- P4 span flags (dual): valueTs RangeTs (1714521600000, 1715385600000) → 2024-05-01 startOfSpan, 2024-05-11 endOfSpan, 2024-05-02..05-10 inSpan, strict-exclusive (start/end cells inSpan False).
- P5 monthArray/quarterArray/yearArray: 12 items for anchor year, monthFormat 'MMM' labels Jan..Dec; quarter 4 items Q1..Q4 (qqq); yearArray (1901,2100) → 200 items, first 1901 selected flag logic for valueTs 1999.
- P6 civil math: setFields Feb-29 clamp (2024-02-29 set month→3 = 2024-03-29? NO — date-fns setMonth keeps day clamped: 2024-02-29 +setMonth 3 → 2024-03-29; verify your expectation against date-fns set semantics!), addMonthsClamped 2024-01-31 +1 → 2024-02-29, weekNumber(2024-01-01)=1, firstDayOfWeekToDateFns 6 = 0.
- P7 TimePicker pure: formatValue 'HH:mm:ss' 1715300000000 = '23:33:20'; parseInput round-trip; snapNow with StepUnits 15 on minutes: 23:33 → 23:30 (ties→lower); OnlyUnits [0,12] hours: 23→12; use12Hours pm mapping 13→1 in item labels is panel-DOM (skip pure).
- P8 defaultActions table: Date→[Now], Date+clearable→[Clear,Now], Datetime→[Now,Confirm], Daterange→[Confirm], Datetimerange+clearable→[Clear,Confirm], Month→[Now,Confirm], Year→[Now], Quarter→[Now,Confirm], Monthrange→[Confirm], Week→[Now] (all with clearable=False unless stated).
- P9 sanitizeValue: Datetime→startOfSecond, Month→startOfMonth, Year→startOfYear, Quarter→startOfQuarter, Week→startOfWeek(Sunday for fdw 6), Date→startOfDay, Daterange→startOfDay, Monthrange→startOfMonth, Datetimerange→startOfSecond (fixed ts 1715300000000, zone UTC → exact ms values).
- P10 singleDateClick: base value + clicked 2024-05-20 ts → {value, close} for Date (close True), Month (close False), Datetime with DefaultSingle "03:04:05" → time applied 03:04:05.
- P11 dualDateClick/dualHover/colItemClick: first click t → Range [t,t] selecting True; second click → selecting False (+ closeOnSelect×updateValueOnClose matrix: daterange+closeOnSelect → confirm/close); dualHover reversed → normalized [min,max]; colItemClick start>end collapse both directions.
- P12 cssVars orders: TimePicker trigger 3 vars exact order; TimePicker panel 14 vars exact order; DatePicker trigger 3 vars; DatePicker panel 43 vars exact order (from recon-1 §a + recon-3 §3).
- P13 DOM classes: time-picker panel col classes (--invalid when unit disabled, item --active/--disabled + data-active attr); date-panel root class array order per type incl. monthrange reusing --daterange; daterange cell class order (--excluded/--current/--selected/--covered/--start/--end/--disabled); datetimerange header 4 controls order; actions suffix buttons per type (Clear/Now/Confirm; confirm primary+disabled when invalid/selecting).
- P14 Input seams: pair tree (wrapper1[input1+placeholder, no suffix] > span.n-input__separator > wrapper2[input2+placeholder+suffix]) + --pair/--focus classes; attrSize on input1 only; textDecoration inline on both inputs.

## PHASE B — write the tests (now read the port modules)
Wire Phase-A pins into the existing harnesses, matching house style exactly (read how tree-select/transfer tests are written first):
- Eq pins → tests/src/Main.elm `checks` list (Check record, `eq` helper; render via existing probe/live node idioms).
- DOM probes → tests/inspect.mjs `domChecks` (dTrue; query #live-*/#probe-* nodes the Elm test app renders; nClassesStr filters n-* classes; assert inline --n-* vars in order).
- You will need small render fixtures in tests/src/Main.elm (fixed zone Time.utc, fixed now ts, fixed values) exposing TimePicker.view/panel, DatePicker.view/panel per type into #live-* nodes. Follow the existing naming conventions.
- Expect mismatches between pins and port behavior: investigate the derivation first; if the PORT is wrong, fix the port minimally (you own src/NUI/* in this commit); if your PIN was wrong, correct the pin doc with the re-derivation note. Log every resolution in the commit message body.
- elm-format; `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` 8/8 green with the NEW counts.
- Commit `test(time-picker,date-picker): eq pins + DOM probes from the upstream bytes` — paths: tests/src/Main.elm tests/inspect.mjs (only if domChecks edited) src/NUI/*.elm (only if port fixes were needed).

Tool hygiene: repeat-call guard kills sessions issuing identical repeated calls — batch reads, vary queries, never re-run an identical command back-to-back. Report: pin count (eq/DOM), any port fixes made, final gate counts, commit hash.
