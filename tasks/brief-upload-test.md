# BRIEF — test(upload): pins-first eq pins + DOM probes

Prep (`1806499`) and feat (see `git log --oneline -3`, message starts `feat(upload):`) are
committed. You write the TEST batch. Work in `/home/titan/Works/elm/elm-naive-ui` (master).

## Pins-first discipline (NON-NEGOTIABLE)

`tasks/recon/upload-pins.md` was derived from the upstream bytes BEFORE the port existed.
Your job: transcribe those expectations into tests, re-deriving anything the pins doc marked
"re-derive at pin time" (upload-pins §B rows 13-14, §G button medium default values) from the
UPSTREAM bytes (/tmp/next-upstream/upload/**), never from the port's output. If a pin and the
port disagree: FIRST re-derive from bytes; a RED that survives re-derivation is a PORT BUG —
fix the port (that's expected and fine; count fixes in your report). A pin that was wrong →
correct the pins doc + pin.

## Read first

1. `tasks/recon/upload-pins.md` — THE expectations (§A cssVars, §B/C/D/E pure helpers,
   §F button gates, §G button overrides, §H DOM probes, §I fixtures).
2. `tasks/recon/upload-1-upstream.md` §3-§8 (DOM trees, gates, traps) — ground truth.
3. `src/NUI/Upload.elm` (the landed port) + `src/NUI/Theme/Upload.elm` — the API you pin.
4. Test exemplars: `tests/src/Main.elm` transfer block (eq pins + fixtures + live views —
   search `transferLiveOpts`, `live-transfer`), color-picker block (newest style);
   `tests/inspect.mjs` transfer probe block (just before `// --- report`).

## Scope — files you may touch (nothing else)

- `tests/src/Main.elm` — upload eq pins at the checks tail (after the transfer/color-picker
  blocks); fixtures `uploadOptions`/`uploadFiles`/`uploadLiveOpts` after the transfer fixtures;
  live views `live-upload*` right after `live-transfer*`/color-picker views (ids per pins §I).
- `tests/inspect.mjs` — upload DOM probe block after the transfer block, BEFORE `// --- report`.
- `tasks/recon/upload-pins.md` — corrections only where a pin was factually wrong (mark with
  `CORRECTED:` prefix on the line).

## House test rules

- tests/ has its OWN elm.json — build via `cd tests && bash run.sh` (or `./run.sh`), not repo root.
- eq pins: `Expect.equal` on pure helpers + `cssVarsFor theme` (compare the EXACT 16-pair list,
  pins §A; use `NUI.Theme.Common.light`-derived theme like existing blocks do).
- DOM probes: replicate existing block style — `#live-upload*` nodes from tests/index.html,
  querySelector chains, `nClassesStr` for class ORDER pins, `dEq` is `===` (join('|') arrays
  first), `hasAttribute('style') === false` for style absence, never exact textContent equality
  inside styled cells.
- Probe block placement is LOAD-BEARING: after helper const definitions, before `// --- report`
  (temporal-dead-zone otherwise).
- Pin the icon d-bytes (pins §H16 lists which icons per branch — full strings in upload-1 §7).
- Cover every §H probe 1-20 unless it duplicates another (note skips in the report).
- `cd tests && npx elm-format --yes src/Main.elm` + `npx elm-format --yes inspect.mjs`?? NO —
  inspect.mjs is JS: never format it; format only Main.elm. Repo-root modules untouched.
- Gate: `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` → 8/8; baseline grows: 3719 assertions +
  2271 DOM → report your new totals (expect roughly +60-110 assertions, +30-60 DOM checks).
- COMMIT (explicit paths only): `git add tests/src/Main.elm tests/inspect.mjs
  tasks/../tasks/recon/upload-pins.md 2>/dev/null || true` — NO: tasks/ stays UNTRACKED, add
  ONLY `tests/src/Main.elm tests/inspect.mjs`. Message via `git commit -F -` heredoc:
  test(upload): NN eq pins + NN DOM probes from the upstream bytes (pins-first)
  (+ body lines: pins total, RED→fix count with each fix described in one line, new gate totals.)

## Tool hygiene

Never repeat an identical tool call back-to-back (vary ranges/args). Prefer targeted
search_code/sed ranges over full-file re-reads.

## Report

1. Commit hash; pins written (eq/DOM counts); REDs found and their resolution (port-fix vs
   pin-corrected, one line each).
2. Gate tail quote (assertions/DOM/failures).
3. Any §H probe skipped + why.
