# ORACLE AUDIT — DatePicker/TimePicker port @ `5b897f2` vs naive-ui v2.45.3 (oracle2, DeepSeek)

READ-ONLY. Upstream tree `/home/titan/Works/elm/naive-ui`; port `/home/titan/Works/elm/elm-naive-ui`. date-fns ground truth run locally with `date-fns@4.1.0` (the version naive-ui 2.45.3 pins, `package.json:86`) under `TZ=UTC`.

### Critical upstream fact (reframes R1)
naive-ui's `dateFnsOptionsRef` contains **no `weekStartsOn`**. The panel copy is `{ locale }` only (`use-panel-common.ts:72-76`); the root copy is `{ locale, useAdditionalWeekYearTokens: true }` (`DatePicker.tsx:134-139`). `firstDayOfWeek` is threaded into formatting **nowhere** — `transformNaiveFirstDayOfWeekToDateFns` feeds *only* `makeWeekMatcher` (`utils.ts:64`), i.e. week *span matching*, not `format`/`strictParse`. So the port's hardcoded `weekStartsOn = 0` for the `w`/`YYYY` tokens is **correct** (enUS date-fns options = `{weekStartsOn:0, firstWeekContainsDate:1}`). The real week defect is `firstWeekContainsDate` (R7b).

---

## S — fix required (ranked by user-visible impact)

### S1 · Zone-less grid vs zone-aware clicks/formatters → wrong day for any non-UTC `zone`  (R6)
- Upstream is self-consistent: the whole picker is one zone (the JS env). The port splits it.
- **Grid = UTC.** `dateArray` reads the anchor with `toCivil Time.utc` (`DateTime.elm:816`); every cell is a UTC midnight; `matchDate` compares in `Time.utc` (`DateTime.elm:680-700`); `toDateItem` builds `selected/inSpan/startOfSpan/endOfSpan/isCurrentDate` from those UTC values.
- **Click / sanitize / display = `opts.zone`.** `singleDateClick` → `DT.setFields cfg.zone` + `sanitizeValueIn cfg.zone` (`DatePicker.elm:634-667`); `displayText`/`displayRange` → `DT.format (mergedFormat opts) opts.zone ts` (`DatePicker.elm:1047,1062-1063`); `singleCalendarValue`/`rangeCalendarValue` pass the raw caller instant as the grid anchor (`DatePicker.elm:1949-1959,1965+`).
- **Concrete same-zone failure.** `zone = UTC+8 (Asia/Shanghai)`, caller stores `value = Single (toPosix zone {2024,3,15} midnight)` = `2024-03-14T16:00Z`:
  - grid anchor read UTC → the cell whose `ts = 2024-03-15T00:00Z` is `dateObject {2024,3,15}` but `selected = matchDate DateGran (…T16:00Z) (…T00:00Z)` → equal only for **2024-03-14** → the **14th highlights, not the 15th**;
  - clicking the "15" cell emits `2024-03-14T16:00Z`; fed back as `value`, the grid keeps highlighting the 14th → the selection can never land on the clicked day for east-of-UTC zones. `isCurrentDate` (vs `opts.now`) shifts identically.
- Divergence appears only when `zone ≠ Time.utc` (the default) — the port's whole test suite is UTC, so it is untested. A same-zone caller still sees wrong flags ⇒ **S**, not D.
- **Minimal fix sketch.** Feed the grid UTC-internally-consistent *and* aligned to the caller's local civil day: derive a grid value/anchor `gridTs zone raw = DT.toPosix Time.utc (DT.toCivil zone raw) DT.midnight` and pass `gridTs opts.zone …` for `calendarAnchor`/`toValueTs`/`sideValueTs` and the `now` comparison in `dateItems`/`yearItems`/`monthOrQuarterItems`. (Alternative: add `dateArrayIn : Time.Zone -> …`/`matchDateIn : Time.Zone -> …` and thread `opts.zone`, keeping the pinned UTC forms as default wrappers.) Re-pin with a non-UTC zone.

### S2 · Week numbering uses `firstWeekContainsDate = 4` instead of the locale's `1`  (R7b, and the true content of R1)
- Upstream `format(date,'YYYY-w',{locale,useAdditionalWeekYearTokens:true})` → date-fns `Y`/`w` use `locale.options.firstWeekContainsDate` = **1** (verified: `date-fns@4.1.0` enUS `options {"weekStartsOn":0,"firstWeekContainsDate":1}`). Ground truth:
  - `2004-12-31 → "2005-1"`, `2005-01-01 → "2005-1"`, `2005-01-02 → "2005-2"`, `2004-01-01 → "2004-1"`.
- Port: `startOfWeekYearDay` anchors on **Jan 4** (`DateTime.elm:754-756`), and `weekYear`/`weekNumber` (`DateTime.elm:766-796`) plus the `w`/`YYYY` renderers (`renderToken`, `DateTime.elm:1281-1291`) inherit fwcd=4. Same input → **`2004-52`**. So the pinned expectation the brief quotes (`2004-52`) is the *wrong* value; the port diverges from upstream for the last ≈ week of each year (and the first).
- Reachable via `type='week'`: `displayText`/`toFormatted` use `mergedFormat` = `"YYYY-w"` (`DatePicker.elm:597-598,1047,2744-2747`), and `strictParse` round-trips against the same engine. (Not reachable for other types.)
- **Minimal fix sketch.** Change the week-1 anchor to `firstWeekContainsDate = 1`: `startOfWeekYearDay ws year = startOfWeekDay ws (daysFromCivil { year = year, month = 1, day = 1 })` (Jan 1, not Jan 4). This alone reproduces all four ground-truth rows above (checked by hand against the existing `weekNumber`/`weekYear` bodies). Mirror in the parse setters `applyWeek`/`applyWeekYear` (`DateTime.elm:2058-2100+`) and re-pin.

---

## D — document, no fix

- **R1** — `format`'s `w`/`YYYY` `weekStartsOn`: no divergence. Upstream never threads `firstDayOfWeek` into `format`; the port's `weekNumber 0`/`weekYear 0` matches enUS (see Critical fact above). *The brief's premise was wrong for v2.45.3.*
- **R2** — pair `date-icon` slot: port honors the caller's `iconNode` in the pair suffix (`dateGlyphNode` → `rangeInputOptions.suffix`/`clearIconPlaceholder`, `DatePicker.elm:940-971`); upstream pair renders a fixed `DateIcon` and ignores the slot (`DatePicker.tsx:1124-1135`). DOM-identical when `iconNode = Nothing`; surface diverges only for custom icons. (Arguably an upstream bug the port fixes.)
- **R3** — date-input envelope: hardcodes `"yyyy-MM-dd"` (`DatePicker.elm:2214,2217`); no `dateFormat` option. Upstream `mergedDateFormatRef = props.dateFormat || locale.dateFormat` (`use-dual-calendar.ts:124-126`, `use-calendar.ts:88`). Matches the enUS default; explicitly punted in the module docstring.
- **R4** — `timePickerProps` passthrough: absent; the embedded pickers use fixed props (`embeddedTimeOptions`, `DatePicker.elm:2244-2262`). Upstream spreads `timePickerProps` (object) / `[0]`/`[1]` (array) (`datetime.tsx:63-76`, `datetimerange.tsx:74-122`). Documented punt; non-trivial to add (needs a per-slot options override surface).
- **R5** — quick-jump routing: port adds a side-less `onQuickMonthSelect` that wins when set (`calendarChannel`, `DatePicker.elm:2077-2086`). When *unset* it emits `onUpdateCalendarValue side anchor`, matching upstream's per-side `onUpdateValue` (`panelHeader.tsx:117-135`). Additive convenience only; faithful when unused.
- **R8 (minor)** — Input pair seam matches recon-6 §1 exactly. One cosmetic asymmetry: the single trigger sets `textDecoration = Nothing` when valid (`DatePicker.elm:908-913`) whereas upstream always binds `textDecoration` (`''`/`line-through`, `DatePicker.tsx:1156`), so the port may omit an empty inline `style` on a valid single input. Zero visual impact; note only.
- **TimePicker actions order (minor)** — port renders `opts.actions` in the caller's list order (`actionsNode`, `TimePicker.elm:674-684`); upstream renders a fixed `clear, now, confirm` gated by membership (`Panel.tsx:328-360`). Default `[Now, Confirm]` identical; only a non-canonical caller list reorders.

---

## R1–R9 verdicts

- **R1** (weekStartsOn gap): **D** — premise inverted; upstream uses `{locale}` only, port's `weekStartsOn=0` is correct. See R7b for the real week defect.
- **R2** (pair date-icon surface): **D** — port honors `iconNode` in pair; DOM-identical when unset.
- **R3** (date-input envelope): **D** — hardcoded `yyyy-MM-dd`, no `dateFormat`; documented punt.
- **R4** (`timePickerProps`): **D** — absent; documented punt.
- **R5** (quick-jump routing): **D** — additive side-less channel; faithful (`side`) routing when unused.
- **R6** (zone-less builders): **S1** — UTC grid vs zone-aware clicks/format breaks same-zone callers for `zone ≠ UTC`.
- **R7** (test1 overrides): **(a) ✓** `yearArray = List.range from (to-1)` → 199 items for `(1901,2100)` (`DateTime.elm:1009-1010`). **(b) S2** — pinned `2004-52` encodes fwcd=4; upstream (fwcd=1) yields `2005-1`.
- **R8** (Input pair bytes): **matches** recon-6 §1 — wrapper1 = prefix + input1 (**no** suffix) → `span.n-input__separator` → wrapper2 = input2 + suffix-iff-`clearable||suffix` (`Input.elm:527-549`, `684-701`); `--pair`/`--focus`/`--stateful` root classes in order (`1065-1067`); `attrSize` input1 only (`645`); `pairTextDecoration[0]/[1]` inline (`606-609`); `tabindex -1` under `passivelyActivated && !activated` (`631-635`). Standalone single bytes unchanged. No material divergence.
- **R9** (sampling — all pass): TimePicker col class orders + item attrs + actions + 14 panelVars ✓; DatePicker 43-var order ✓; daterange cell class order + datetimerange disabled-cell suppression ✓; range panels reuse `--daterange` ✓; shortcuts filtering mirrors upstream's `Array.isArray` skips ✓; `defaultActions` all 11 types ✓; enUS defaults + panelHeader children order ✓.

## Net
Two actionable spec violations: **S1 (R6)** — reconcile the UTC grid with `opts.zone`; **S2 (R7b)** — `firstWeekContainsDate` 4→1 for `w`/`YYYY` + weekNumber/weekYear (week type, near year boundaries). Both masked by the all-UTC pins. R1–R5, R8–R9 clean or documented.
