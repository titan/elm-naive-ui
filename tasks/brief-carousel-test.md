# BRIEF — test(carousel): pins-first eq pins + DOM probes

Prep (`b6c123e`) and feat (see `git log --oneline -3`, message starts `feat(carousel):`) are
committed. You write the TEST batch. Work in `/home/titan/Works/elm/elm-naive-ui` (master).

## Pins-first discipline (NON-NEGOTIABLE)

`tasks/recon/carousel-pins.md` was derived from the upstream bytes BEFORE the port existed.
Your job: transcribe those expectations into tests, re-deriving anything marked `[FLAG …]`
or `[!]` (pins §A5 drag-to-clone, §A6 defaultIndex seed) from the UPSTREAM bytes
(/home/titan/Works/elm/naive-ui/src/carousel/**), never from the port's output. If a pin and
the port disagree: FIRST re-derive from bytes; a RED that survives re-derivation is a PORT
BUG — fix the port (expected and fine; count fixes in your report). A pin that was wrong →
correct the pins doc line with a `CORRECTED:` prefix.

## Read first

1. `tasks/recon/carousel-pins.md` — THE expectations: §A worked derivations (A1-A6 — the
   exact numbers), §E eq pins (20 groups), §D DOM probes (14 groups), §T traps.
2. `tasks/recon/carousel-1-upstream.md` §2-§5 — ground truth (DOM byte-map §3, cssr §5).
3. `src/NUI/Carousel.elm` (the landed port) — the API you pin. If a name differs from
   carousel-2 §1-§3 (e.g. the exact Options/State field or function names), pin the LANDED
   API and note the mapping in your report.
4. Test exemplars: `tests/src/Main.elm` upload block (search `uploadOptions`,
   `live-upload` — newest style: fixtures + eq checks + live views) and the color-picker
   block; `tests/inspect.mjs` upload probe block (just before `// --- report`).

## Scope — files you may touch (nothing else)

- `tests/src/Main.elm` — carousel eq pins at the checks tail (after the upload block);
  fixtures (options/state/env builders per pins §A numbers) after the upload fixtures;
  live views `live-carousel*` after the upload live views (ids per §D; each fixture feeds
  perViewSize {1000,400} via the port's resize fn so the DOM shows deterministic px).
- `tests/inspect.mjs` — carousel DOM probe block after the upload block, BEFORE
  `// --- report`.
- `tasks/recon/carousel-pins.md` — corrections only (CORRECTED: prefix).

## House test rules

- tests/ has its OWN elm.json — build via `cd tests && bash run.sh`, not repo root.
- eq pins: `eq name expected actual` on the pure helpers (resolveSpeed/clampValue/
  getDisplayIndex/getRealIndex/getPrevIndex/getNextIndex/getDisplayTotalView/duplicateWrap/
  envOf fields/to-prev-next pipelines/transitionEnd/dragEnd branches/wheel/dotKeyAction/
  indexChange/autoplayEnabled) per pins §E 1-20. Float comparisons via the existing
  float-tolerant helpers if the port returns Floats (see nanEq/maybeFloatEq precedents).
- State-machine pins (§E 12-15, 17): thread the state through the port's actual functions
  and assert the END state fields (displayIndex/inTransition/previousTranslate/
  expectedDirection) — the numbers are in §A2/A5.
- DOM probes (§D 1-14): `#live-carousel*` nodes; `nClassesStr` for class ORDER pins
  (root order incl. the DOUBLE --vertical occurrence — assert on the raw class ATTRIBUTE
  string, not classList); style attr `includes` for translate/margin/width pins; d-string
  byte equality for both arrow paths; `aria-hidden`/`aria-selected` string values;
  data-index real-space values; the usercontrol wrapper divs (classless, display:none).
- Probe block placement is LOAD-BEARING: after helper consts, before `// --- report`.
- `cd tests && npx elm-format --yes src/Main.elm`; inspect.mjs is JS — never format it.
- Gate: `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` → 8/8; baseline 3838 assertions + 2336
  DOM data-total grows — report your new totals (expect roughly +90-130 assertions, +45-70
  DOM checks).
- COMMIT (explicit paths only): `git add tests/src/Main.elm tests/inspect.mjs` — tasks/
  stays UNTRACKED. Message:
  test(carousel): NN eq pins + NN DOM probes from the upstream bytes (pins-first)
  (+ body: pins totals, RED→fix count one line each, new gate totals.)

## Tool hygiene

Never repeat an identical tool call back-to-back (vary ranges/args). Prefer targeted
search_code/sed ranges over full-file re-reads. If `cd tests && bash run.sh` fails on a JS
throw in your probe block, fix the probe (null-guard the querySelector) before re-running —
three identical failing shell calls in a row can abort this session.

## Report

1. Commit hash; pins written (eq/DOM counts); REDs found and their resolution (port-fix vs
   pin-corrected, one line each).
2. Gate tail quote (assertions/DOM/failures).
3. Any §E/§D pin skipped + why; the landed-API-vs-carousel-2 name mapping if any.
