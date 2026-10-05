# recon/dedup-1 — Calendar + Heatmap date math onto `NUI.Internal.DateTime`

Workspace: `/home/titan/Works/elm/elm-naive-ui` @ `b8549b5`. **Read-only recon.**
Target refactor: `refactor(calendar,heatmap): date math onto Internal/DateTime`,
STRICT behavior preservation — the existing pins + identical gate counts are the
acceptance proof, **zero test edits allowed**.

Sources byte-read: `src/NUI/Calendar.elm` (670 L), `src/NUI/Heatmap.elm` (1171 L),
`src/NUI/Internal/DateTime.elm` (2227 L), upstream `src/date-picker/src/utils.ts`
+ `src/calendar/src/Calendar.tsx` (mounted at `/home/titan/Works/elm/naive-ui`).

---

## 0. Bottom line

- **Byte-identical civil math exists in three places** (Calendar, Heatmap,
  DateTime). The Hinnant `days_from_civil` / `civil_from_days` bodies are the
  same algorithm; Calendar/Heatmap use bare `//`, DateTime uses `floorDiv`
  (`(a - modBy b a) // b`). These agree for **every reachable year (y ≥ 1)**;
  they only diverge for negative years, which no caller can produce. → the leaf
  math is safe to **MIGRATE/re-point**.
- **One genuine trap:** `Calendar.grid` must **NOT** be repointed to
  `DT.dateArray`. Upstream `Calendar.tsx:179` calls `dateArray(…, strip = true)`,
  where the leading-prev-month loop uses `protect = !strip = false`.
  `DT.dateArray` **hardcodes `protect = True`** (it is only ever called with
  `strip = False` — `DatePicker.elm:1846/1991`). For a display month that begins
  on the configured `startDay` (enUS = 6 → a Sunday-start month) Calendar yields
  **0** leading days while `DT.dateArray strip=true` yields **7**. Different grid,
  extra week row. See Check 2.
- Everything else in Calendar's and Heatmap's *structural* helpers
  (`completeDataGaps`, `gapDay`, `createDayRect`, the sparse/loading matrix,
  locale tables, panel arithmetic) has **no engine counterpart** → KEEP, and only
  the *leaf* civil-day calls get re-pointed.
- Recommended net: **≈ −120 … −160 source lines**, two `import NUI.Internal.DateTime as DT`
  lines, **no test changes, no exposure change**. Full order in §5.

---

## 1. Calendar helper map (`src/NUI/Calendar.elm`)

| name : line | signature | engine counterpart : line | verdict | proof / wrapper |
|---|---|---|---|---|
| `toCell` :399 | `Options msg -> Date -> Cell` | — | **KEEP** | view-layer flag computation; `Date == Civil` shape but flags (`selected`/`isCurrentDate`) are compared as civil records against `opts`, not engine ts. |
| `grid` :368 | `Options msg -> List Cell` | `DT.dateArray` :813 | **KEEP** (⚠ do NOT migrate) | strip/prev-loop + shape + UTC-anchor divergence — Check 2. Re-point its *leaves* only (`addDays`, `monthDays`). |
| `prevMonthDays` :412 | `Date -> Int -> List Date` | `DT.dateArray` prev loop :825-833 | **KEEP** | Calendar has no `protect`; upstream strip=true `protect=false`. Byte-for-byte matches upstream, **not** `DT.dateArray`. |
| `monthDays` :421 | `Date -> List Date` | `DT.daysInMonth` :414 | **ADAPT** | `List.range 1 (DT.daysInMonth d.year d.month)`. |
| `nextMonthDays` :427 | `Date -> Int -> List Date` | `DT.dateArray` next pad :862-866 | **KEEP** | trivial `count`-bounded walk; identical to `dateArray`'s next loop but not worth a shared surface. |
| `daysFromCivil` :442 | `Date -> Int` | `DT.daysFromCivil` :313 | **MIGRATE** | identical Hinnant body; only `y // 400` vs `floorDiv y 400`, equal for y≥1. I/O: `{2024,2,29}→19782`, `{1970,1,1}→0` (both). |
| `civilFromDays` :472 | `Int -> Date` | `DT.civilFromDays` :343 | **MIGRATE** | identical inverse (`days // 146097` vs `floorDiv`); `19782→{2024,2,29}`. |
| `addDays` :522 | `Date -> Int -> Date` | `DT.addDays` :394 (`Int -> Int -> Int`) | **ADAPT** | wrapper: `addDays d n = DT.civilFromDays (DT.addDays n (DT.daysFromCivil d))`. |
| `weekday` :529 | `Date -> Int` | `DT.weekday` :402 | **MIGRATE** | both `modBy 7 (daysFromCivil + 4)`. `{1970,1,1}→4` (Thu). |
| `daysInMonth` :534 | `Date -> Int` | `DT.daysInMonth` :414 (`Int -> Int -> Int`) | **ADAPT** | wrapper: `daysInMonth d = DT.daysInMonth d.year d.month`. |
| `panelOf` :544 | `Date -> Panel` | — | **KEEP** | pure record projection `{year, month}`; no engine analogue. |
| `addMonthsPanel` :551 | `Panel -> Int -> Panel` | `DT.addMonthsClamped` :432 | **KEEP** *(opt. ADAPT — rec. against)* | month-only add, no day ⇒ no clamp. Formula `total=year*12+month-1+n` is the same but the wrapper via `addMonthsClamped {…, day=1}` adds indirection for zero dedup value. Check 3. |
| `monthName` :562 | `Int -> String` | — | **KEEP** | locale label table (`enUS.monthNames`). |
| `weekdayName` :569 | `Locale -> Date -> String` | — | **KEEP** | uses `weekday` (→ `DT.weekday` after migration) + locale table. |
| `formatFullDate` :578 | `Date -> String` | `DT.format` :1106 | **KEEP** | 3-field zero-pad; `DT.format "yyyy-MM-dd"` needs a ts + zone and is heavier. Label-only, no math to dedup. |
| `enUS` :116 | `Locale` | — | **KEEP** | upstream `enUS` locale (firstDayOfWeek = 6, month/weekday names, `title`). |
| `monthToInt` (none) | — | `DT.monthToInt` (private) | **n/a** | Calendar has no `monthToInt`. |

---

## 2. Heatmap helper map (`src/NUI/Heatmap.elm`)

| name : line | signature | engine counterpart : line | verdict | proof / wrapper |
|---|---|---|---|---|
| `toCivil` :1055 | `Time.Zone -> Time.Posix -> Civil` | `DT.toCivil` :463 (`Time.Zone -> Int -> Civil`) | **ADAPT** | wrapper: `toCivil z ts = DT.toCivil z (Time.posixToMillis ts)`. Identical zone reads (`Time.toYear/toMonth/toDay`) — Check 4. |
| `monthToInt` :1063 | `Time.Month -> Int` | `DT.monthToInt` (private) | **delete** | only used by `toCivil`; folds away once `toCivil` is a wrapper. |
| `daysFromCivil` :1105 | `Civil -> Int` | `DT.daysFromCivil` :313 | **MIGRATE** | same identical-body proof as Calendar (§1). |
| `dayNumber` :1137 | `Time.Zone -> Time.Posix -> Int` | `DT.daysFromCivil (DT.toCivil …)` | **ADAPT** | wrapper: `dayNumber z ts = DT.daysFromCivil (DT.toCivil z (Time.posixToMillis ts))`. (or expose a `dayNumber` on DT.) |
| `weekdayOfDay` :1145 | `Int -> Int` | `DT.weekdayOfDay` :409 (private) | **ADAPT** | wrapper: `weekdayOfDay dn = DT.weekday (DT.civilFromDays dn)`, or expose `DT.weekdayOfDay`. |
| `posixOfDay` :1156 | `Time.Zone -> Int -> Time.Posix` | `DT.toPosix` :481 (+ `civilFromDays`) | **ADAPT** *(opt.)* | wrapper: `DT.toPosix z (DT.civilFromDays d) zeroTime` reuses the engine's fixed-point `localToTs`. Engine docstring calls it "the NUI.Heatmap.converge idiom". Only the civil day is ever read back — Check 4. |
| `converge` :1161 | `Time.Zone -> Int -> Int -> Int -> Int` | `DT.toPosix` :481 | **delete** | subsumed by the `posixOfDay` wrapper. |
| `civilKey` :793 | `Time.Zone -> Time.Posix -> (Int, Int)` | — | **KEEP** | projection `(c.year, c.month)`; re-points `toCivil`. |
| `gapDay` :602 | `Zone -> Dict Int Item -> Int -> Int -> Int -> Item` | — | **KEEP** | builds gap items (`posixOfDay` + `Just 0`/`Nothing`); no engine analogue. |
| `completeDataGaps` :557 | `Zone -> List Item -> Int -> Bool -> List Item` | — | **KEEP** | upstream's day-span fill; uses `dayNumber`/`weekdayOfDay`/`posixOfDay` + `Dict`. Re-point leaves only. |
| `createDayRect` :624 | `Zone -> Item -> Posix -> Int -> List String -> Float -> DayRect` | — | **KEEP** | positioning + `calcColorByValue`; re-points `dayNumber`/`weekdayOfDay`. |
| `createSparseMatrix` :658 | `Int -> List a -> (a->Int) -> (a->Int) -> List (List (Maybe a))` | — | **KEEP** | pure list/Dict; zero date math. |
| `createLoadingMatrix` :700 | `Time.Posix -> Int -> List (List DayRect)` | — | **KEEP** | pure 7×53 dead grid; zero date math. |
| `stepMonth` :761 | `((Int,Int),Int) -> Dict …` | — | **KEEP** | month-group accumulator. |
| `colMonth` :774 | `Zone -> List (List (Maybe DayRect)) -> Int -> Maybe ((Int,Int),Int)` | — | **KEEP** | uses `civilKey`; grouping logic is Heatmap-specific. |
| `weekStartOn` :1038 | `Int -> Int` | `DT.firstDayOfWeekToDateFns` :727 | **MIGRATE** | **byte-identical**: `(n+1) |> modBy 7` ⇔ `modBy 7 (n+1)`. Check 5. |
| `calcColorByValue` :512 | `List String -> Maybe Float -> Float -> String` | — | **KEEP** | colour bucketing, no date math. |

---

## 3. Seven critical checks

### 1. `Date` / `Civil` + `daysFromCivil` / `civilFromDays` — byte-compare ✅
Calendar `type alias Date = { year, month, day }` (Calendar.elm:85) and
`DT.Civil` (DateTime.elm:109) are the **same record shape** — a `Date` is
structurally a `Civil`, so migrations re-point/alias rather than convert fields.

Algorithm bodies are identical line-for-line except the two floor divisions:

| step | Calendar (`//`) | DateTime (`floorDiv`) |
|---|---|---|
| `era` | `y // 400` | `floorDiv y 400` |
| `civilFromDays.era` | `days // 146097` | `floorDiv days 146097` |

All other operators (`modBy`, `//4`, `//100`, `//153`, `//1460`, `//36524`,
`//146096`) are the same expression in both. `floorDiv a b = (a - modBy b a) // b`
differs from `a // b` **only for `a < 0`**. Reachable `y ≥ 1` (year) and
`days = z + 719468 > 0` (modern z) ⇒ **identical for the entire reachable
domain**. Representative I/O (Node sim, ephemeral): `{2024,2,29}→19782`,
`{1970,1,1}→0`; `civilFromDays 19782 → {2024,2,29}`; `weekday {1970,1,1} → 4`.

### 2. Month-grid semantics — ⚠ **do not migrate the grid**
Upstream ground truth (`/home/titan/Works/elm/naive-ui`):

- `src/calendar/src/Calendar.tsx:179` → `dateArray(monthTs, value, now, localeRef.firstDayOfWeek, /*strip*/ true)`.
- `src/date-picker/src/panel/use-calendar.ts:114` and `use-dual-calendar.ts:154/162` → `strip = false` (the single/dual date panel).
- `utils.ts:366` → `let protectLastMonthDateIsShownFlag = !strip`, and the leading loop is `while (getDay(it) !== startDay || protectFlag)`.

| | strip | prev-loop when month starts on `startDay` |
|---|---|---|
| upstream Calendar | true | **0** leading days (protect = false) |
| `Calendar.prevMonthDays` | (true) | **0** — matches upstream ✅ |
| `DT.dateArray` | true | **7** — hardcodes `collectPrev … True` (DateTime.elm:833) |
| `DT.dateArray` (actual callers) | false | matches upstream (protect = !strip = true) |

Node sim over 2020-2030 (startDay = 6, enUS) found **18 months** where
Calendar-prev ≠ `DT.dateArray`-prev — e.g. 2024-09 (Sep 1 2024 is a Sunday):
Calendar = 0, `DT.dateArray` = 7. So `DT.dateArray` is faithful **only for
`strip = false`**; it is a latent trap for Calendar's strip=true grid.

Other shape facts: `DT.dateArray` returns `DateItem` records (with `ts`,
`inSpan`, …) built in `Time.utc`, while `Calendar.grid` needs bare `Date`s and is
pure civil. **Verdict: KEEP the grid composition; re-point only `addDays`,
`monthDays` (→`daysInMonth`) leaves.** If a future task wants the grid on the
engine, first change `DT.dateArray` to thread `strip` into the protect flag
(`collectPrev (firstDn-1) (not strip)`) and re-pin DatePicker (its `strip=false`
path is unaffected) — then a thin `DateItem → Cell` adapter becomes viable.

Current DOM fixtures do **not** hit this edge: `#live-calendar` = 2026-07 (starts
Wed), `#live-calendar-6wk` = 2026-08 (starts Sat) → the green gate would not catch
a bad repoint.

### 3. Clamping — no conflict ✅
Calendar never adds months to a `Date` with a real day: `addDays` is day-number
arithmetic, and `addMonthsPanel` operates on a `Panel` (`{year, month}`, day is
implicit 1). `DT.addMonthsClamped` clamps `day = min day (daysInMonth …)`; feeding
it `day = 1` (the only way to emulate `addMonthsPanel`) is a **no-op clamp**
(`min 1 dim = 1`). `Calendar.daysInMonth` (last-day − first-day) and
`DT.daysInMonth` (next-month-first − first) are the same value. ⇒ no clamp
semantics are ever exercised by Calendar; ADAPT via wrapper is safe.

### 4. Heatmap `toCivil` / gap stepping — identical ✅
`Heatmap.toCivil z posix = { Time.toYear z posix, monthToInt (Time.toMonth z posix), Time.toDay z posix }`
vs `DT.toCivil z ms = civilOfLocal (toLocalAt z ms)` where `toLocalAt` reads the
**same** three fields from `Time.millisToPosix ms`. Zone handling identical; only
Posix-vs-Int input differs. `completeDataGaps`/`gapDay` step by **day numbers**
(`firstDay ± offset`, `List.range`), the same unit as `DT.addDays`
(`addDays n dayNumber = dayNumber + n`); `posixOfDay`'s fixed-point `converge`
returns some instant in the local day — only its civil day is read back
(`dayNumber`, `civilKey`). Under `Time.utc` both `posixOfDay` and a
`DT.toPosix`-based wrapper yield exactly `dayNumber * 86_400_000` (the pinned
"first timestamp = week-start midnight" case, Main.elm:8211). No exact-timestamp
pin exists for the `customZone −300` case (Main.elm:8226 pins **values** only).

### 5. Week numbering — none used ✅
Neither `Calendar.elm` nor `Heatmap.elm` references `weekNumber`/`weekYear`/`w`/
`YYYY`. Their week logic is plain weekday arithmetic (`weekday`, `weekdayOfDay`,
`weekStartOn`) → **no `firstWeekContainsDate` interaction**. The only
naive→date-fns transform, `weekStartOn`, is **byte-identical** to
`DT.firstDayOfWeekToDateFns` (`(n+1) |> modBy 7`).

### 6. Import / exposure — compiles, no exposure change ✅
`NUI.Internal.DateTime` is in the INTERNAL allow-list
(`tools/verify/check-exposure.mjs:21`), and `NUI.DatePicker` already imports it
intra-source-tree as `import NUI.Internal.DateTime as DT` (`DatePicker.elm:170`)
— gate 8/8 green. Calendar/Heatmap can import identically. check-exposure only
asserts that every **non-INTERNAL** `src/` module is re-exported from the `NUI`
root; adding importers introduces no new modules, so exposure is unchanged.

### 7. Pin coverage — see §4. Risk = unpinned ∧ rewritten.

### Engine exposure gaps (what the wrappers must work around)
`DT` exposes: `daysFromCivil`, `civilFromDays`, `weekday`, `daysInMonth`,
`addDays`, `addMonthsClamped`, `addYearsClamped`, `toCivil`, `toPosix`,
`firstDayOfWeekToDateFns`, `format`, `dateArray`, `startOf*`, `matchDate`, … .
**Not exposed** (so wrappers compose from public fns, or DT grows a small export):
`weekdayOfDay`, `dayNumber`, `midnight` (time-of-day record), `monthToInt`,
`localToTs`. Every wrapper in §1/§2 uses only public DT functions — no exposure
change is strictly required.

---

## 4. Pin coverage (refactor-risk ranking input)

| helper | direct `eq` pin? | indirect pin (view/DOM or via pinned helper) | risk if rewritten |
|---|---|---|---|
| Calendar `daysFromCivil`/`civilFromDays` | no (unexposed) | ✅ DOM grid dates, `panelOf`, `addMonthsPanel` | low (byte-identical) |
| Calendar `weekday` | no | ✅ DOM weekday names, `#live-calendar-6wk` | low |
| Calendar `daysInMonth` | no | ✅ DOM cell counts (28/35/42) | low–med |
| Calendar `addDays` | no | ✅ DOM grid | low |
| Calendar `grid`/`prev`/`next` | no | ✅ DOM cell count + first-cell date | **med** (edge unpinned — Check 2) |
| Calendar `panelOf`/`addMonthsPanel`/`todayPanel` | ✅ Main.elm:7472-7482 | — | low |
| Calendar `cssVarsFor` | ✅ Main.elm:6564 | — | n/a |
| Heatmap `completeDataGaps` | ✅ Main.elm:8202-8231 (9 pins) | — | low |
| Heatmap `createDayRect` | ✅ Main.elm:8232-8249 | — | low |
| Heatmap `createSparseMatrix` | ✅ Main.elm:8250-8264 | — | n/a (no math) |
| Heatmap `createLoadingMatrix` | ✅ Main.elm:8265-8277 | — | n/a |
| Heatmap `dataMonthLabels`/`loadingMonthLabels` | ✅ Main.elm:8283-8309 | ✅ DOM month cells | low |
| Heatmap `toCivil`/`daysFromCivil`/`dayNumber`/`weekdayOfDay` | no | ✅ via `completeDataGaps`/`createDayRect`/`dataMonthLabels` | low |
| Heatmap `posixOfDay`/`converge` | no | ✅ UTC exact-ms pin (Main.elm:8211) | low–med (exact-ms) |
| Heatmap `weekStartOn` | no | ✅ `createDayRect`/`createLoadingMatrix` rowIndex pins + DOM | low |
| Heatmap `civilKey`/`colMonth`/`stepMonth` | no | ✅ `dataMonthLabels` pins + DOM colspans | low |

Highest risk = **grid composition** (structural, edge unpinned). Everything else
is either byte-identical or has direct/strong indirect coverage.

---

## 5. Ranked migration order (lowest risk first)

1. `Heatmap.weekStartOn` → `DT.firstDayOfWeekToDateFns` — byte-identical, 1 line.
2. `Heatmap.daysFromCivil` → `DT.daysFromCivil` — byte-identical (Check 1).
3. `Calendar.daysFromCivil` → `DT.daysFromCivil` — byte-identical.
4. `Calendar.civilFromDays` → `DT.civilFromDays` — byte-identical.
5. `Calendar.weekday` → `DT.weekday` — byte-identical.
6. `Calendar.daysInMonth` → wrapper over `DT.daysInMonth`; `monthDays` rides along.
7. `Calendar.addDays` → wrapper over `DT.addDays`.
8. `Heatmap.toCivil` → wrapper over `DT.toCivil`; delete `monthToInt`.
9. `Heatmap.dayNumber` → wrapper (`DT.daysFromCivil ∘ DT.toCivil`).
10. `Heatmap.weekdayOfDay` → wrapper (`DT.weekday ∘ DT.civilFromDays`).
11. `Heatmap.posixOfDay` → wrapper over `DT.toPosix`; delete `converge` (⚠ verify the exact-ms pin §3.4 first).

Each step is independently gated; run the full gate after each and expect the
counts to be **identical** (no re-pin).

---

## 6. Expected net line delta

| module | removed (dup civil math) | added (wrappers + import) | net |
|---|---|---|---|
| Calendar | `daysFromCivil` ~20, `civilFromDays` ~34, `addDays` 3, `weekday` 3, `daysInMonth` 9 ≈ **69** | aliases/wrappers ~7 + docstrings | **≈ −60** |
| Heatmap | `daysFromCivil` ~19, `toCivil` 6, `monthToInt` 28, `dayNumber` 4, `weekdayOfDay` 3, `posixOfDay`+`converge` ~20 ≈ **80** | wrappers ~9 | **≈ −70** |
| **total** | | | **≈ −120 … −160 source lines** |

No test files, no `check-dom`/`ALLOW` lists, no `.elm` exposure lists change.

---

## 7. Recommend AGAINST migrating

- **`Calendar.grid` / `prevMonthDays` / `nextMonthDays` → `DT.dateArray`.**
  `DT.dateArray` hardcodes the `strip = false` protect flag; Calendar's grid is
  upstream `strip = true`. Repointing changes the leading-day count for any
  month starting on `startDay` (Check 2) and would need a `DateItem → Cell`
  adapter plus UTC→civil re-anchoring. KEEP; re-point leaves only.
- **`Calendar.addMonthsPanel` → `DT.addMonthsClamped`.** Works (day=1 no-op
  clamp) but is pure modular arithmetic with no civil-day math to dedup;
  wrapping adds indirection for zero line saving. KEEP.
- **`Calendar.formatFullDate` → `DT.format`.** Needs a ts + zone for a label
  that is a 3-field zero-pad; no math duplicated. KEEP.
- **Heatmap structural helpers** (`completeDataGaps`, `gapDay`, `createDayRect`,
  `createSparseMatrix`, `createLoadingMatrix`, `stepMonth`, `colMonth`,
  `civilKey`) — no engine counterpart; keep and re-point `toCivil` only.
- **`Calendar.enUS`, `monthName`, `weekdayName`; `toCell`, `panelOf`** — locale
  tables and view-layer/panel projections, nothing to dedup.

---

## 8. Tool hygiene note

Recon done in one pass: batched reads, `search_code` for line numbers/exposure,
and a throwaway `/tmp/sim.mjs` Node simulation for the Check-1 I/O proofs and the
Check-2 divergence table. The repeat-call guard fired once on a re-read of
`DateTime.elm` — results were recovered via targeted `search_code` around
`weekNumber`/`dateArray`/`startOfWeek*`. No workspace files were modified.
