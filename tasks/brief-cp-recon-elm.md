# Brief: ColorPicker elm-side recon (read-only) — integration map for elm-naive-ui

You are a recon lane for the elm-naive-ui port project. Workspace (do not touch tracked files):
`/home/titan/Works/elm/elm-naive-ui` (branch master). A parallel lane is auditing upstream
naive-ui color-picker; your job is the ELM side: produce the integration map so the next
lanes can add `NUI.ColorPicker` without re-deriving house conventions.

## Task
Write ONE file: `/home/titan/Works/elm/elm-naive-ui/tasks/recon/color-picker-2-elm.md`

## What to study (cite `path:line` for every claim)

1. **The pattern model** — `src/NUI/DatePicker.elm`: document its overall architecture as the
   template for a new overlay component: Msg/Model shape, `view` (trigger) vs `panel` split,
   focusDetector sentinel, `transition : Maybe NUI.Internal.TransitionPhase`, cssVars plumbing,
   theme var lookup, size handling. Also note how `src/NUI/Internal/DateTime.elm` is structured
   (top-level pure engine module) in case color math wants a similar home
   (`src/NUI/Internal/Color.elm`?). Do NOT copy code into the doc — describe + cite.
2. **Build/tooling checklist wiring** — exactly what a new component requires, with file paths
   and line cites: `tools/manifest.mjs` entry format; `cd tools && npm run extract` (what it
   generates, where output lands); how the generated theme vars get exposed (prep commit
   pattern — find the commit or the exposure site in `src/NUI/Theme.elm` or similar);
   `tools/verify/check-dom.mjs` target format; `tools/verify/check-classes.mjs` ALLOW-list
   format and the rule for when ALLOW is legitimate.
3. **Examples wiring** — how `examples/` (or wherever demos live) adds a component section:
   file layout, how a section is registered, build command used by the gate.
4. **Test wiring** — `tests/src/Main.elm` eq-pin style (pure fn pins) and `tests/inspect.mjs`
   DOM-probe style (`#live-*` fixtures): exact patterns for adding pins + probes, how
   `tests/run.sh` runs them, where assertion counts come from.
5. **Existing color code** — search the elm tree for any pre-existing color handling
   (ColorPicker, hsv, hsl, rgb, hex parse, `seemly`, color strings) so we don't duplicate.
6. **README table** — current format of the coverage table, where the ColorPicker row goes.
7. **Input seams** — check whether ColorPicker would need any `src/NUI/Input.elm` seams
   (probably NOT — it has its own input fields; verify what DatePicker reused and note the
   difference) — flag as decision point.
8. **Risks/gaps** — anything about color-picker that does NOT fit the DatePicker overlay
   pattern (gradient mode? internal drag state? swatch editor?) and the recommended call.

## Hard constraints
- READ-ONLY except writing the single output file under `tasks/recon/`.
- NO `git` mutations, NO commits, NO builds, NO npm installs.
- Tool hygiene: never issue the same tool call twice; a failed read → note and move on.
- Finish with the doc written, then reply with a ≤10-line summary + the doc path.
