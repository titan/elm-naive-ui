# BRIEF — recon: Calendar/Heatmap date-math dedup map onto Internal/DateTime — write tasks/recon/dedup-1.md

Workspace: /home/titan/Works/elm/elm-naive-ui @ `b8549b5`. READ-ONLY recon; produce ONE doc: /home/titan/Works/elm/elm-naive-ui/tasks/recon/dedup-1.md.

Goal: a helper-by-helper migration map for `refactor(calendar,heatmap): date math onto Internal/DateTime` — STRICT behavior preservation (the existing pins + identical gate counts are the acceptance proof; zero test edits will be allowed in the refactor).

## Inputs
- Port: src/NUI/Calendar.elm (670 L — date helpers at :412-592 incl. `daysFromCivil :442`, `civilFromDays :472`, `addDays :522`, `weekday :529`, `daysInMonth :534`, `panelOf :544`, `addMonthsPanel :551`, grid `prevMonthDays :412` / `monthDays :421` / `nextMonthDays :427`, `toCell :399`, `monthName :562`, `weekdayName :569`, `formatFullDate :578`, `enUS :116` Locale), src/NUI/Heatmap.elm (1171 L — `toCivil :1055`, `civilKey :793`, `gapDay :602`, `completeDataGaps :557`, `stepMonth :761`, `colMonth :774`, `weekStartOn :1038`, `createSparseMatrix :658`), src/NUI/Internal/DateTime.elm (2227 L — the engine; find its civil math / toPosix-toCivil / addDays-addMonthsClamped / weekday / daysInMonth / dateArray / format / week fns and their exact signatures).
- Test coverage: tests/src/Main.elm + tests/inspect.mjs — which of the above helpers' behavior is currently pinned (search for calendar/heatmap test sections) and which are NOT pinned.

## Output format — for EVERY date-math helper in Calendar + Heatmap (not CSS/view fns), one row:
`name : line | signature | engine counterpart : line | verdict | proof`
Verdicts:
- **MIGRATE** — semantics provably identical: cite both bodies (algorithms match — e.g. both are the Howard Hinnant days-from-civil algorithm) AND representative I/O equality (compute 2-3 edge cases via `elm repl`-style reasoning or node: e.g. `daysFromCivil {2024,2,29}`, `weekday` for a known date, month-grid first cell for May 2024 with each startDay convention).
- **ADAPT** — close but signature/shape differs (e.g. Calendar's `Date` type vs engine's `Civil`, `Time.Zone` threading, `addMonths` vs engine's day-clamped variant — CHECK clamping semantics: Calendar `addMonthsPanel` vs engine `addMonthsClamped` on Jan 31 → Feb 29); migrate via a thin local wrapper, wrapper named + documented in the row.
- **KEEP** — genuinely different semantics that must not change (e.g. Heatmap's `weekStartOn` normalization vs engine's `firstDayOfWeekToDateFns` transform; Calendar locale label tables); one-line justification.

## Critical semantic checks (do not skip)
1. Calendar `Date` type definition + `daysFromCivil`/`civilFromDays` vs engine equivalents — byte-compare the algorithm bodies.
2. Month-grid semantics: Calendar `prevMonthDays/monthDays/nextMonthDays` composition vs engine `dateArray` (strip? leading-trailing counts? startDay convention — Calendar enUS locale first day vs engine's `firstDayOfWeekToDateFns 6 = 0`). If identical outputs, MIGRATE the grid to `dateArray`; if shapes differ (e.g. Calendar needs the `Date` list not item records), ADAPT.
3. Clamping: engine `addMonths*` day-clamp vs Calendar `addMonthsPanel` / `daysInMonth` behavior at month ends.
4. Heatmap `toCivil` vs engine `toCivil` (zone handling identical?), `gapDay`/`completeDataGaps` day-stepping vs engine `addDays`.
5. Engine week fns use fwcd=1/wso=0 (oracle-fixed) — if Calendar/Heatmap use ANY week numbering, verify theirs is plain weekday math (no week-number semantics) so no fwcd interaction.
6. Import/exposure: engine is in the check-exposure INTERNAL list (unexposed from NUI) — confirm intra-source-tree import `import NUI.Internal.DateTime as DT` from Calendar/Heatmap compiles and passes gate 3 (cite how DatePicker imports it).
7. Pin coverage table: helpers covered / uncovered by current pins (matters for refactor risk ranking — uncovered+rewritten = highest risk; uncovered+re-pointed = low).

End the doc with: (a) ranked migration order (lowest-risk first), (b) expected net line delta, (c) any helper where you recommend AGAINST migrating. Tool hygiene: repeat-call guard kills sessions — batch reads, vary queries.