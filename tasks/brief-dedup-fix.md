# BRIEF — refactor(calendar,heatmap): date math onto Internal/DateTime

Workspace: /home/titan/Works/elm/elm-naive-ui @ `b8549b5`. Follow tasks/recon/dedup-1.md EXACTLY — it is the spec for this refactor (helper-by-helper MIGRATE/ADAPT/KEEP, §5 ranked order, §7 do-not-migrate list).

## Acceptance (non-negotiable)
- STRICT behavior preservation: **zero edits** to tests/src/Main.elm, tests/inspect.mjs, tools/verify/*.
- Final gate `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` 8/8 with counts EXACTLY **3568/3568 assertions + 2160 DOM** — identical numbers are the proof.
- elm-format clean.

## Scope — execute §5 steps 1-11 in order (leaf re-points + thin wrappers ONLY)
1. Heatmap `weekStartOn` → `DT.firstDayOfWeekToDateFns` (byte-identical).
2. Heatmap `daysFromCivil` → `DT.daysFromCivil`.
3-5. Calendar `daysFromCivil`, `civilFromDays`, `weekday` → engine (byte-identical Hinnant bodies).
6. Calendar `daysInMonth` → wrapper `DT.daysInMonth d.year d.month`; `monthDays` re-points to the wrapper.
7. Calendar `addDays` → wrapper `DT.civilFromDays (DT.addDays n (DT.daysFromCivil d))`.
8. Heatmap `toCivil` → wrapper `DT.toCivil z (Time.posixToMillis ts)`; delete local `monthToInt`.
9. Heatmap `dayNumber` → wrapper `DT.daysFromCivil (DT.toCivil …)`.
10. Heatmap `weekdayOfDay` → wrapper `DT.weekday (DT.civilFromDays dn)`.
11. Heatmap `posixOfDay` → wrapper `DT.toPosix z (DT.civilFromDays d) <zero time-of-day>`; delete `converge`. ⚠ ESCAPE HATCH: the UTC exact-ms pin (Main.elm:8211 — dayNumber × 86400000) must stay green. If `DT.toPosix` with a zero time-of-day cannot reproduce exact millis under `Time.utc` after honest effort, REVERT step 11 to KEEP (`posixOfDay`/`converge` untouched) and note it — do NOT touch the pin, do NOT approximate.
Both files gain `import NUI.Internal.DateTime as DT` (see DatePicker.elm:170 for the pattern — gate 3 allows it, recon Check 6).
Run the FULL gate after steps 5, 8, and 11 (the risky checkpoints) and before commit; intermediate failures = investigate, never re-pin.

## Do NOT touch (recon §7 — violations fail this brief)
`Calendar.grid` / `prevMonthDays` / `nextMonthDays` (strip=true semantics; `DT.dateArray` hardcodes protect=True — repointing corrupts months that start on `startDay`), `addMonthsPanel`, `formatFullDate`, `toCell`, `panelOf`, `enUS`/`monthName`/`weekdayName`; ALL Heatmap structural helpers (`completeDataGaps`, `gapDay`, `createDayRect`, `createSparseMatrix`, `createLoadingMatrix`, `stepMonth`, `colMonth`, `civilKey`, `calcColorByValue`). No engine-side changes either (DateTime.elm stays @ its current bytes) — wrappers compose ONLY from already-public DT functions.

## Commit
One commit: `refactor(calendar,heatmap): date math onto Internal/DateTime` — expected paths src/NUI/Calendar.elm src/NUI/Heatmap.elm only. Body: net line delta, the steps executed, any escape-hatch fallback (step 11), and a pointer to tasks/recon/dedup-1.md.

Tool hygiene: repeat-call guard kills sessions — batch reads, vary queries, never re-run an identical command back-to-back. Report: commit hash, gate counts, per-file delta, step-11 outcome.
