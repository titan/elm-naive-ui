# BRIEF — fix(time-picker, date-picker): oracle fidelity round — Task 5 close-out

Workspace: /home/titan/Works/elm/elm-naive-ui @ `5b897f2` (gate 8/8, 3562/3562 assertions + 2155 DOM). Commit directly, explicit paths only, `tasks/` untracked. Upstream at /home/titan/Works/elm/naive-ui (date-picker panel files under src/date-picker/src/panel/; date-fns@4.1.0 ground truth via `TZ=UTC node -e` with the format tables from the oracle report).

Read first: /home/titan/Works/elm/elm-naive-ui/tasks/recon/date-picker-oracle.md (the full audit — findings below reference it).

## Fix S1 — zone-consistent grid (oracle report §S1)
The panels build their grids from UTC-interpreted anchors (`DateTime.dateArray` etc. read ts via `toCivil Time.utc`, DateTime.elm:816, matchDate :680-700) while clicks/sanitize/display use `opts.zone` (DatePicker.elm :634-667, :1047, :1949+). Any `zone ≠ Time.utc` highlights and emits the wrong civil day.
Implement the oracle's minimal sketch (preferred, keeps the pinned engine API stable): a private `gridTs : Time.Zone -> Int -> Int` in DatePicker.elm — `gridTs zone raw = toPosix Time.utc (toCivil zone raw) {midnight fields}` — applied to `calendarAnchor`, `toValueTs`/`sideValueTs`, and the `now` comparisons feeding `dateItems`/`yearItems`/`monthOrQuarterItems`, so the grid civil days equal the caller's local civil days while the builders stay internally UTC. (If some helper makes this awkward, the alternative from the report — zone-aware `*In` engine variants with the pinned forms as wrappers — is acceptable; keep the 72 existing pins compiling unchanged.)
Verify: with `zone = Time.customZone 480 []`, value = local 2024-03-15 midnight, the 15th cell is `selected` (not the 14th), and clicking the 15th emits a ts whose local civil day is the 15th. Same for `isCurrentDate` with a local-noon `now`.

## Fix S2 — firstWeekContainsDate 4→1 (oracle report §S2)
- `DateTime.elm` `startOfWeekYearDay` (:754-756): anchor Jan 1 instead of Jan 4. Thread through `weekNumber`/`weekYear` (:766-796) and the `w`/`YYYY` renderers (:1281-1291) — confirm no other fwcd=4 constant remains (grep `Jan`-anchoring / `4`).
- Mirror in the parse setters `applyWeek`/`applyWeekYear` (:2058-2100+).
- Ground truth (date-fns@4.1.0 enUS, weekStartsOn 0, fwcd 1): `2004-12-31 → "2005-1"`, `2005-01-01 → "2005-1"`, `2005-01-02 → "2005-2"`, `2004-01-01 → "2004-1"`.

## Re-pin + new pins (tests)
- Re-derive and UPDATE the S2-affected pins in tests/src/Main.elm AND tasks/recon/date-picker-pins.md (mark re-derivations with a `[oracle S2]` note): the `YYYY-w` cases above; the independent `weekNumber 1 → 53 / weekYear 1 → 2004` pins become `weekNumber(2004-01-01) = 1 / weekYear = 2004` under fwcd=1 — recompute every week pin against node date-fns before editing.
- ADD new S1 pins: a `Time.customZone 480` fixture asserting the selected-cell day + click round-trip + isCurrentDate (3-5 eq pins) — derived FIRST from the oracle report's concrete failure, then verified.
- DOM probe count stays as-is unless you add fixtures.

## Document D findings (no code change beyond docstrings)
Extend module docstrings (TimePicker.elm / DatePicker.elm) where not already present, one line each, tagged `[oracle D]`:
- R1: `w`/`YYYY` weekStartsOn=0 is correct — upstream never threads firstDayOfWeek into format (v2.45.3, date-fns v4).
- R2: pair suffix honors iconNode where upstream ignores the date-icon slot in pair mode (upstream bug; port superset).
- R3: date-input envelope hardcoded 'yyyy-MM-dd' (upstream dateFormat||locale.dateFormat) — punt.
- R4: timePickerProps passthrough absent — punt.
- R5: onQuickMonthSelect side-less additive channel; default routing faithful.
- R8-minor: textDecoration Nothing-vs-'' cosmetic asymmetry (single trigger).
- TimePicker actions order: caller list order vs upstream fixed clear→now→confirm.

## Validation + commit
elm-format touched files; `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` 8/8 green with counts ≥ current (3562 + your new pins). Commit `fix(time-picker,date-picker): oracle fidelity round — S1 zone grid, S2 firstWeekContainsDate, D documented` — expected paths: src/NUI/DatePicker.elm src/NUI/Internal/DateTime.elm tests/src/Main.elm (+ TimePicker.elm only if docstring touched; + tests/inspect.mjs only if you added DOM fixtures).

Tool hygiene: repeat-call guard kills sessions — batch reads, vary queries, never re-run an identical command back-to-back. Report: commit hash, gate counts, list of re-pinned + new pins, files touched.
