# time-picker + date-picker — finalized pins (tests) — derived from the upstream bytes

Every expectation below was derived from the mirrored upstream bytes BEFORE reading the
port output in `src/NUI/{TimePicker,DatePicker}.elm` / `src/NUI/Internal/DateTime.elm` /
`src/NUI/Input.elm`. Source roots (mount `/home/titan/Works/elm/naive-ui`, v2.45.3):

- `src/time-picker/src/{utils.ts,Panel.tsx,PanelCol.tsx,TimePicker.tsx}`
- `src/date-picker/src/{panel/*,utils.ts,DatePicker.tsx,use-*.ts}`
- `src/locales/common/enUS.ts`
- `src/input/src/Input.tsx` (§pair) + `styles/input.cssr.ts`
- date-fns ground truth (fixed UTC timestamps), computed with `TZ=UTC node`.
- DOM/cssVars orders cross-checked against `tasks/recon/date-picker-{1..6}-*.md`.

`startDay`/`firstDayOfWeek` convention: naive 0=Mon … 6=Sun (enUS `firstDayOfWeek: 6`);
date-fns `getDay` 0=Sun … 6=Sat. `dateArray` passes `firstDayOfWeek` straight in as its
`startDay` param; the grid's effective first weekday column is `(startDay+1)%7` in date-fns
terms — so enUS (6) makes the first cell a **Sunday** (derivation: utils.ts `dateArray`
:351-418, `getDay(lastMonthIterator) !== startDay` loop; verified 2024-05-01 → first cell
2024-04-28 Sunday).

## Timestamps (fixed, UTC) — `TZ=UTC node` verified

| alias | ms | civil (UTC) |
| --- | --- | --- |
| `TS_A` | 1715297600000 | 2024-05-09T23:33:20Z |
| `TS_B` | 1704067200000 | 2024-01-01T00:00:00Z |
| `MAY_ANCHOR` | 1714521600000 | 2024-05-01T00:00:00Z |
| `RANGE_END` | 1715385600000 | 2024-05-11T00:00:00Z |
| `MAY_28` | 1714262400000 | 2024-04-28T00:00:00Z |
| `JUN_08` | 1717804800000 | 2024-06-08T00:00:00Z |
| `MAY_20` | 1716163200000 | 2024-05-20T00:00:00Z |
| `MAY_05` | 1714867200000 | 2024-05-05T00:00:00Z (Sunday) |
| `MAY_09_DAY` | 1715212800000 | 2024-05-09T00:00:00Z |
| `APR_01` | 1711929600000 | 2024-04-01T00:00:00Z (Q2 start) |
| `MAR_29` | 1711670400000 | 2024-03-29T00:00:00Z |
| `FEB_29` | 1709164800000 | 2024-02-29T00:00:00Z |
| `JAN_31` | 1706659200000 | 2024-01-31T00:00:00Z |
| `Y1999` | 915148800000 | 1999-01-01T00:00:00Z |
| `D2004_31` | 1104451200000 | 2004-12-31T00:00:00Z |
| `EPOCH_T` | 84800000 | 1970-01-01T23:33:20Z |

**Re-derivation note (brief error):** the brief labelled `1715300000000` as
`2024-05-09T23:33:20Z`. Ground truth: `1715297600000 = 2024-05-09T23:33:20Z`; the brief's
`1715300000000` is `2024-05-10T00:13:20Z` (+40 min). Since the brief's *label* (P1, P3's
"cell 2024-05-09 selected", P7's "`'23:33:20'`") is self-consistent on the civil value and
only the raw ms disagrees, **`TS_A` = 1715297600000 is the anchor used throughout.** Any pin
below quoted by the brief with `1715300000000` for a "2024-05-09" expectation is tested with
`TS_A`.

---

## P1 — engine `format` (DateTime formatter) — date-fns v2 token ground truth

Tokens `<ts> → expected` (zone UTC). Derivation: date-fns `format`; enUS locale.

| id | ts | pattern | expectation |
| --- | --- | --- | --- |
| P1.1 | `TS_A` | `yyyy-MM-dd` | `2024-05-09` |
| P1.2 | `TS_A` | `yyyy-MM-dd HH:mm:ss` | `2024-05-09 23:33:20` |
| P1.3 | `TS_A` | `MMM` | `May` |
| P1.4 | `TS_A` | `eeeeee` | `Th` (date-fns short weekday, enUS) |
| P1.5 | `TS_A` | `yyyy-qqq` | `2024-Q2` (quarter 2; enUS `qqq`→`Q2`) |
| P1.6 | `TS_A` | `yy` | `24` |
| P1.7 | `TS_A` | `H` | `23` (no pad) |
| P1.8 | `TS_A` | `HH` | `23` (pad, already 2-digit) |
| P1.9 | `TS_A` | `yyyy-'Q'Q` | `2024-Q2` (quoted literal `Q`, then quarter `2`) |
| P1.10 | `TS_B` | `yyyy-MM-dd` | `2024-01-01` |
| P1.11 | `TS_B` | `yyyy-MM-dd HH:mm:ss` | `2024-01-01 00:00:00` |
| P1.12 | `TS_B` | `MMM` | `Jan` |
| P1.13 | `TS_B` | `eeeeee` | `Mo` |
| P1.14 | `TS_B` | `H` | `0` (no pad) |
| P1.15 | `TS_B` | `HH` | `00` (padded) |
| P1.16 | `TS_B` | `yyyy-qqq` | `2024-Q1` |
| P1.17 | `TS_B` | `YYYY-w` | `2024-1` |
| P1.18 | `D2004_31` | `YYYY-w` | `2004-53` |

`yyyy-qqq` is the enUS `quarterFormat` (enUS.ts :33); `YYYY-w` is the `weekFormat`
(enUS.ts :34).

**Re-derivation note (`YYYY-w`, P1.17/P1.18):** the brief says "ISO week 1 of 2024" and "the
2004/53 documented edge". date-fns `Y`/`w` are the *local* week-numbering year/week
(`weekStartsOn` + `firstWeekContainsDate`), which for `D2004_31` yields `2005-1`, NOT
`2004-53`. **ISO ground truth** (`TZ=UTC node`, ISO weekStartsOn=1/firstWeek=4):
`2024-01-01`→`[2024,1]`; `2004-12-31`→`[2004,53]`. P1.17/P1.18 pin the **ISO** reading
(the brief's intent, and the engine lane's "getWeek 53/2004" doc case). **Phase B must
reconcile against the port**: if the port implements date-fns' *local* rule, P1.18 flips to
`2005-1` (documented re-derivation), else keep `2004-53`.

## P2 — `strictParse` (parse + round-trip `format(result)===input`) — utils.ts :480-494

| id | input | pattern | expectation |
| --- | --- | --- | --- |
| P2.1 | `2024-05-09` | `yyyy-MM-dd` | valid → ts `MAY_09_DAY` (1715212800000) |
| P2.2 | `2024-02-30` | `yyyy-MM-dd` | **invalid** (date-fns `parse` → Invalid Date) |
| P2.3 | `2024-5-9` | `yyyy-MM-dd` | **invalid** (parse ok, round-trip `2024-05-09` ≠ `2024-5-9`) |
| P2.4 | `23:33:20` | `HH:mm:ss` | valid → ts `EPOCH_T` (84800000) with backup = epoch |
| P2.5 | `23:33:20` | `HH:mm` | **invalid** (round-trip `HH:mm`→`23:33` ≠ input) |

Backup for P2.4 is the epoch (`1970-01-01T00:00:00Z`), so parse fills y/m/d from it.
Derivation: utils.ts `strictParse` (:480) `format(result, pattern, option) === string`.

## P3 — `dateArray` single grid — utils.ts :351-418

Anchor `MAY_ANCHOR` (2024-05-01), `valueTs` = `TS_A`, `nowTs` = `TS_A`, `startDay` = 6,
`strip` = False, `weekMode` = False:

| id | expectation |
| --- | --- |
| P3.1 | exactly **42** items |
| P3.2 | first cell `ts` = `MAY_28` (2024-04-28, Sunday) |
| P3.3 | last cell `ts` = `JUN_08` (2024-06-08) |
| P3.4 | cell `2024-05-09` (`MAY_09_DAY`) `.selected` = True |
| P3.5 | cells `2024-05-08` / `2024-05-10` `.selected` = False |
| P3.6 | `.inCurrentMonth` True iff month == 5 & year == 2024 (34 cells: 04-28..04-30 False, 05-01..05-31 True, 06-01..06-08 False) |
| P3.7 | `.isCurrentDate` True only for the `2024-05-09` cell |

`weekMode` variant (same anchor/value/now/startDay): `.selected` is **False for every cell**;
`.inSelectedWeek` = True for the 7 cells of the selected week = `startOfWeek(TS_A,
weekStartsOn = (6+1)%7 = 0)` (Sun 2024-05-05) ⇒ cells `2024-05-05 .. 2024-05-11` inclusive
(ts `MAY_05`=1714867200000 … 1715385600000). Derivation: utils.ts `weekItem` (:231-278)
`selected:false`, `inSelectedWeek = matchDate(value,'week',fdw)`; `makeWeekMatcher`
`weekStartsOn = transformNaiveFirstDayOfWeekToDateFns(fdw)`.

## P4 — span flags (dual `dateArray` with a `[start,end]` valueTs) — utils.ts `dateItem` :167-204

`valueTs = [MAY_ANCHOR, RANGE_END]` = (2024-05-01, 2024-05-11):

| id | expectation |
| --- | --- |
| P4.1 | `2024-05-01` cell `.startOfSpan` = True, `.inSpan` = False |
| P4.2 | `2024-05-11` cell `.endOfSpan` = True, `.inSpan` = False |
| P4.3 | `2024-05-02 .. 2024-05-10` `.inSpan` = True (strict exclusive: `v0 < t < v1`) |
| P4.4 | `2024-05-01` and `2024-05-11` both `.selected` = True; `2024-05-02..10` `.selected` = False |

## P5 — month/quarter/year arrays — utils.ts :420-478

| id | expectation |
| --- | --- |
| P5.1 | `monthArray(anchor=MAY_ANCHOR, ...)` → **12** items; `month` 0..11; labels (`MMM`) `Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec` |
| P5.2 | `monthArray` `ts[0]` = `TS_B` (2024-01-01T00:00Z = startOfYear anchor) |
| P5.3 | `quarterArray(anchor=MAY_ANCHOR, ...)` → **4** items; `quarter` 1..4; labels (`qqq`) `Q1,Q2,Q3,Q4` |
| P5.4 | `quarterArray` `ts[0]` = `TS_B`; `ts[1]` = `APR_01` (Q2 = 2024-04-01T00:00Z) |
| P5.5 | `yearArray(range=[1901,2100])` → **199** items (`range[1]-range[0]`, exclusive end); first `year` 1901, `ts[0]` = startOfYear(1901), last `year` = 2099 |
| P5.6 | `yearArray` with `valueTs = Y1999` → exactly the `1999` item `.selected` = True |

**Re-derivation note (P5.5):** the brief says "200 items". Upstream `yearArray` (:461-476)
loops `for (i = 0; i < range[1] - range[0]; i++)` over `startOfYear(setYear(new Date(),
range[0]))` ⇒ `2100-1901 = 199` items (years 1901..2099, **exclusive end**; recon-3 §4
"`yearArray` `yearRange[0]..[1]` exclusive end"). Pin = **199**. Phase B reconciles with the
port.

## P6 — civil math — date-fns `set`/`addMonths` ground truth + `transformNaiveFirstDayOfWeekToDateFns`

| id | expectation |
| --- | --- |
| P6.1 | `addMonthsClamped(JAN_31, 1)` → `FEB_29` (date-fns `addMonths(2024-01-31,1)` clamps day to 29) |
| P6.2 | set month→3 (0-indexed 2 = March) on `FEB_29` keeps the day → `MAR_29` (March has 31 days, day 29 exists) |
| P6.3 | set month→2 (0-indexed 1 = Feb) on `JAN_31` clamps → `FEB_29` (date-fns `setMonth` keeps day clamped) |
| P6.4 | week number of `TS_B` (2024-01-01) = **1** |
| P6.5 | `transformNaiveFirstDayOfWeekToDateFns 6` = **0** ((6+1)%7) |

**Note (P6.1/P6.2/P6.3):** exact function names (`addMonthsClamped`, civil `set`) are the
port's; the *behaviour* is pinned to date-fns semantics. Phase B maps them to the port API.

## P7 — TimePicker pure helpers — utils.ts `getTimeUnits`/`findSimilarTime`/`isTimeInStep`

| id | expectation |
| --- | --- |
| P7.1 | `formatValue('HH:mm:ss', TS_A)` = `23:33:20` |
| P7.2 | `parseInput('23:33:20', 'HH:mm:ss')` round-trips back to a ts whose `HH:mm:ss` = `23:33:20` |
| P7.3 | minute snap, `StepUnits 15`: `findSimilarTime(33,'minutes',15)` = **30** (nearest; ties→lower: 45-33=12 > 33-30=3) |
| P7.4 | hour snap, `OnlyUnits [0,12]`: `findSimilarTime(23,'hours',[0,12])` = **12** (`list=[0,12]`, no upper bound → lower bound 12) |
| P7.5 | `getTimeUnits(hours, 15)` = `00,15,30,45` (modulo filter) |
| P7.6 | `getTimeUnits(hours, [0,12])` (array list) = `['00','12']` |

Panel-DOM (deferred to P13): the 12-hour `pm` label remap `13 → '01'` (`getTimeUnits` pm
branch maps `v===12?12:v-12` then `getFixValue`).

## P8 — default actions table — DatePicker.tsx `mergedActionsRef` :277-348

`actions === null → []`; explicit → as-is; else `clearable?['clear']:[]` then per type:

| id | type | clearable | expectation |
| --- | --- | --- | --- |
| P8.1 | date | False | `[Now]` |
| P8.2 | date | True | `[Clear, Now]` |
| P8.3 | datetime | False | `[Now, Confirm]` |
| P8.4 | daterange | False | `[Confirm]` |
| P8.5 | datetimerange | True | `[Clear, Confirm]` |
| P8.6 | month | False | `[Now, Confirm]` |
| P8.7 | year | False | `[Now]` |
| P8.8 | quarter | False | `[Now, Confirm]` |
| P8.9 | monthrange | False | `[Confirm]` |
| P8.10 | week | False | `[Now]` |

(`'now'` never appears for any range type; time-picker panel `actions` default is
`['now','confirm']` — Panel.tsx :23.)

## P9 — `sanitizeValue` — use-calendar.ts :205-226 / use-dual-calendar.ts :561-571

Input ts `TS_A` (2024-05-09T23:33:20Z), zone UTC → exact ms:

| id | type | expectation |
| --- | --- | --- |
| P9.1 | datetime | `startOfSecond` → 1715297600000 (unchanged) |
| P9.2 | month | `startOfMonth` → 1714521600000 |
| P9.3 | year | `startOfYear` → 1704067200000 |
| P9.4 | quarter | `startOfQuarter` → 1711929600000 |
| P9.5 | week | `startOfWeek`, `weekStartsOn = (6+1)%7 = 0` (Sun) → 1714867200000 |
| P9.6 | date | `startOfDay` → 1715212800000 |
| P9.7 | daterange | `startOfDay` → 1715212800000 |
| P9.8 | monthrange | `startOfMonth` → 1714521600000 |
| P9.9 | datetimerange | `startOfSecond` → 1715297600000 |

## P10 — `handleDateClick` single — use-calendar.ts :327-402

Base value 0/null + clicked `MAY_20` (2024-05-20):

| id | expectation |
| --- | --- |
| P10.1 | date → value `MAY_20`; `close` = **True** (`doClose()` for `date`/`week`) |
| P10.2 | month → value `MAY_20` (startOfMonth=2024-05-01T00:00Z = 1714521600000); `close` = **False** (month/quarter stay open) |
| P10.3 | datetime + `defaultTime "03:04:05"` → time applied: `03:04:05` on 2024-05-20 → ts 1716174245000 |

## P11 — dual clicks / hover / col-item — use-dual-calendar.ts :426-560, :797-867

| id | expectation |
| --- | --- |
| P11.1 | `dualDateClick` 1st click `t` → value `[t,t]`, `selecting` = **True** |
| P11.2 | `dualDateClick` 2nd click → `selecting` = **False** |
| P11.3 | `dualHover` reversed (`memorizedStart > hover`) → normalized `[min,max]` |
| P11.4 | daterange `closeOnSelect` true + `updateValueOnClose` → confirm/close on complete; else `handleConfirmClick` |
| P11.5 | `colItemClick` start>end collapse both directions (`yearrange`/`monthrange` value normalize) |

1st click sets `memorizedStartDateTime = t`, `changeStartEndTime(t,t,'done')` (degenerate
`[t,t]`); 2nd completes. `handleDateMouseEnter` normalizes reversed hover.

## P12 — cssVars orders

### TimePicker trigger (3) — TimePicker.tsx :853-863
`--n-icon-color-override, --n-icon-color-disabled-override, --n-bezier`.

### TimePicker panel (14) — TimePicker.tsx :882-907
`--n-bezier, --n-border-radius, --n-item-color-hover, --n-item-font-size, --n-item-height,
--n-item-opacity-disabled, --n-item-text-color, --n-item-text-color-active, --n-item-width,
--n-panel-action-padding, --n-panel-box-shadow, --n-panel-color, --n-panel-divider-color,
--n-item-border-radius`.

### DatePicker trigger (3) — DatePicker.tsx :774-781
`--n-bezier, --n-icon-color-override, --n-icon-color-disabled-override`.

### DatePicker panel (43) — DatePicker.tsx :797-925
1 `--n-bezier`, 2 `--n-panel-border-radius`, 3 `--n-panel-color`, 4 `--n-panel-box-shadow`,
5 `--n-panel-text-color`, 6 `--n-panel-header-padding`, 7 `--n-panel-header-divider-color`,
8 `--n-calendar-left-padding`, 9 `--n-calendar-right-padding`,
10 `--n-calendar-title-color-hover`, 11 `--n-calendar-title-height`,
12 `--n-calendar-title-padding`, 13 `--n-calendar-title-font-size`,
14 `--n-calendar-title-font-weight`, 15 `--n-calendar-title-text-color`,
16 `--n-calendar-title-grid-template-columns`, 17 `--n-calendar-days-height`,
18 `--n-calendar-days-divider-color`, 19 `--n-calendar-days-font-size`,
20 `--n-calendar-days-text-color`, 21 `--n-calendar-divider-color`,
22 `--n-panel-action-padding`, 23 `--n-panel-extra-footer-padding`,
24 `--n-panel-action-divider-color`, 25 `--n-item-font-size`, 26 `--n-item-border-radius`,
27 `--n-item-size`, 28 `--n-item-cell-width`, 29 `--n-item-cell-height`,
30 `--n-item-text-color`, 31 `--n-item-color-included`, 32 `--n-item-color-disabled`,
33 `--n-item-color-hover`, 34 `--n-item-color-active`, 35 `--n-item-text-color-disabled`,
36 `--n-item-text-color-active`, 37 `--n-scroll-item-width`, 38 `--n-scroll-item-height`,
39 `--n-scroll-item-border-radius`, 40 `--n-arrow-size`, 41 `--n-arrow-color`,
42 `--n-icon-color`, 43 `--n-icon-color-disabled`.

## P13 — DOM classes

### P13.a TimePicker panel col classes — Panel.tsx :216/:240/:268/:296
- hour col: `n-time-picker-col` [ + `--invalid` if `isHourInvalid` ] [ + `--transition-disabled` if `transitionDisabled` ]
- minute col: `n-time-picker-col` [ + `--transition-disabled` ] [ + `--invalid` ] (order differs!)
- second col: `n-time-picker-col` [ + `--invalid` ] [ + `--transition-disabled` ]
- amPm col (use12Hours): `n-time-picker-col` [ + `--invalid` ] [ + `--transition-disabled` ]
- each col's item (`PanelCol.tsx` :25-46): `n-time-picker-col__item` [ + `--active` ] [ + `--disabled` ];
  `data-active=""` attr present when active (absent otherwise).

### P13.b date-panel root class array order — date.tsx :67-72 / month.tsx :139-151 / etc.
`n-date-panel`, `n-date-panel--{type}` (month.tsx always `--month`, monthrange reuses
`--daterange`), `n-date-panel--shadow` (only when `panel=False`), themeClass.
Range types: `--daterange` / `--datetimerange`. Datetime: `--datetime`.

### P13.c daterange date-cell class order — daterange.tsx (recon-4 §3)
`n-date-panel-date` then, in this key order, only the true ones: `--excluded`,
`--current`, `--selected`, `--covered`, `--start`, `--end`, `--disabled`.
Single date cell (date.tsx :132-151) order: `--current`, `--selected`, `--excluded`,
`--disabled`, `--week-hovered`, `--week-selected`.
Datetime cell (datetime.tsx) order: `--current`, `--selected`, `--excluded`, `--disabled`.

### P13.d datetimerange header 4 controls order — datetimerange.tsx :60-135
`NInput(start)`, `NTimePicker(start)`, `NInput(end)`, `NTimePicker(end)` inside
`n-date-panel-header`.

### P13.e actions suffix buttons per type — date.tsx / month.tsx / daterange.tsx / datetimerange.tsx
- date/week: `[Clear?, Now]`
- datetime: `[Clear?, Now, Confirm]`
- month/quarter: `[Clear?, Now, Confirm]`
- year: `[Clear?, Now]`
- daterange/datetimerange/monthrange/quarterrange/yearrange: `[Clear?, Confirm]`
`Confirm` is `type=primary` and `disabled` when the value is invalid; range confirm also
`disabled` while `isSelecting`.

## P14 — Input pair seams — Input.tsx :1395-1465 (pair), :1125-1143 (classes)

Root class order: `n-input`, `n-input--{size}-size`, themeClass, [`n-input--{status}-status`],
then conditional: `--rtl`, `--disabled`, `--textarea`, `--resizable`, `--autosize`, `--round`,
`--pair`, `--focus`, `--stateful`.

Pair tree (children order):
1. `div.n-input-wrapper` → [`div.n-input__prefix`?] + `div.n-input__input` → `input.n-input__input-el`
   (`value[0]`, `placeholder[0]`, `size={attrSize}` **input1 only**, `style=[textDecoration[0]]`).
   Suffix block **skipped** when pair.
2. `span.n-input__separator`
3. `div.n-input-wrapper` → `div.n-input__input` → `input.n-input__input-el`
   (`value[1]`, `placeholder[1]`, **no** size, `style=[textDecoration[1]]`),
   then pair-only `div.n-input__suffix` (only when `clearable || children`) containing
   `NBaseClear` (iff clearable) + suffix children.

- `--pair` and `--focus` (`= internalForceFocus || focused`) ride the root.
- `attrSize` (`size` attr) is on **input1 only**.
- `textDecoration` is an inline `style` on each input (input1 `[0]`, pair input2 `[1]`) —
  NOT on the root.

---

## Phase-B reconciliation log (filled in while wiring tests)

All 72 eq pins and 26 DOM probes matched the port on first run — **no port
changes were needed**. The two brief expectations that the derivation
overrode are recorded here:

- **P1.18 (`YYYY-w` @ 2004-12-31).** Brief expected the ISO `2004-53`. As
  first landed the port's `format` week tokens used `firstWeekContainsDate = 4`
  with `weekStartsOn = 0` → **`2004-52`** (wrong vs upstream).
  **`[oracle S2]` re-derivation (date-fns@4.1.0 enUS, `weekStartsOn 0`, `fwcd
  1`):** upstream default is `firstWeekContainsDate = 1` → `2004-12-31 =
  "2005-1"`. The port now anchors week 1 on Jan 1, so P1.18 is `2005-1`
  (plus `2005-01-01 → 2005-1`, `2005-01-02 → 2005-2`, `2004-01-01 → 2004-1`).
  The old "getWeek 53/2004" ISO edge was an artefact of `fwcd=4`; P6.4b/c are
  re-derived to `weekNumber(2004-01-01) = 1` / `weekYear(2004-01-01) = 2004`
  (`[oracle S2]`), with P6.4d covering the `fwcd=1` rollover
  (`2004-12-31 → week 1 / year 2005`). `2024-01-01 → week 1` (P1.17 `2024-1`,
  P6.4a) is unchanged.
- **P5.5 (`yearArray`).** Brief said "200 items"; upstream `yearArray` loops
  `i < range[1] - range[0]` (exclusive end) → **199** items (1901..2099). Pin
  = 199 (matches the port).

Port fixes: **none**. `src/NUI/*` was not touched by this commit.

---

## Oracle round (oracle2, DeepSeek) — S1/S2 applied

Ground truth re-run with `date-fns@4.1.0` (`TZ=UTC`):

  - `format 'YYYY-w'` (enUS, `weekStartsOn 0`, `fwcd 1`, `useAdditionalWeekYearTokens`):
    `2004-12-31 → "2005-1"`, `2005-01-01 → "2005-1"`, `2005-01-02 →
    "2005-2"`, `2004-01-01 → "2004-1"`, `2024-01-01 → "2024-1"`.
  - `getWeek`/`getWeekYear` (`ws 1`, `fwcd 1`): `2004-01-01 → (1, 2004)`,
    `2004-12-31 → (1, 2005)`, `2024-01-01 → (1, 2024)`.

**`[oracle S2]` — firstWeekContainsDate 4→1.** `DateTime.startOfWeekYearDay`
now anchors Jan 1 (was Jan 4); `applyWeekYear`'s `base` day likewise. This
threads through `weekNumber` / `weekYear` and the `w` / `YYYY` renderers. All
S2-affected pins re-derived above (P1.18 rewritten as the four-case boundary
pin; P6.4b/c moved to the 2004-01-01 anchor; P6.4d added for the rollover).

**`[oracle S1]` — zone-consistent grid.** The panel now maps the grid anchor,
the value and `now` onto the UTC midnight of the same *civil* day in
`opts.zone` (`DatePicker.gridTs`), so a `zone ≠ Time.utc` caller highlights and
emits the local civil day. New pins (UTC+8, `Time.customZone 480 []`):

  - `dpZoneValue` = local 2024-03-15 00:00 = `1710432000000`;
    `dpZoneNow` = local 2024-03-21 00:30 = `1710952200000`.
  - **S1.1** 15th cell (`1710460800000`) selected, 14th (`1710374400000`) not.
  - **S1.2** exactly one selected cell = `1710460800000`.
  - **S1.3** `isCurrentDate` follows the local day: the 21st cell
    (`1710979200000`), count 1 (not the UTC 20th).
  - **S1.4** `singleDateClick` on the 15th cell → ts whose local civil day is
    `(2024, 3, 15)`.
  - DOM probe `#live-date-panel-zone`: selected cell text `15`, current `21`.

D findings (R1–R5, R8-minor, TimePicker actions order) are documented as
`[oracle D]` lines in the `NUI.DatePicker` / `NUI.TimePicker` docstrings.
