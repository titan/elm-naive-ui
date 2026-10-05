# Brief: ColorPicker upstream recon (read-only) — naive-ui v2.45.3

You are a recon lane for the elm-naive-ui port project. Upstream reference tree (READ-ONLY):
`/home/titan/Works/elm/naive-ui` (naive-ui v2.45.3). Main workspace (do not touch tracked files):
`/home/titan/Works/elm/elm-naive-ui`.

## Task
Study the ENTIRE upstream ColorPicker surface and write ONE file:
`/home/titan/Works/elm/elm-naive-ui/tasks/recon/color-picker-1-upstream.md`

Cite every claim as `path:line` relative to `src/color-picker/src/` (house convention; the
panel/composables may live in subdirectories — inventory them all). Also check
`src/color-picker/styles/` (or wherever its cssr/theme styles live) and any shared mixins it uses.

## Required sections (in this order)

1. **File inventory** — every file under src/color-picker with line counts and one-line role.
2. **Public API** — every prop: name, type, default, controlled/uncontrolled pairs (`value` vs
   `default-value`, `show` vs `default-show` if any), `on-update:value` etc. Every emit/event.
   Every slot. Mark which props are panel-only vs trigger-only vs both.
3. **Component tree & mount model** — trigger vs panel split, how the panel is mounted
   (popover/v-binder/teleport?), focus handling, keyboard interaction, internal state machine
   (what re-renders on what). Note the color-picker's modes: single color, gradient? sizes?
   swatches/preset colors? alpha channel? Confirm from code, not memory.
4. **Pure functions (THE IMPORTANT PART)** — every piece of pure color math: conversions
   (hex↔rgb↔hsv↔hsl, with/without alpha), parsing of user input strings, clamping/rounding
   rules, value serialization formats (what exact string does `value` hold in each mode/format:
   hex8? rgba()? gradient string?), contrast/derived-color helpers if any. For each: exact
   signature, exact formula/rounding behavior, edge cases (0/360 hue wrap, alpha=0, invalid
   input, `#RGB` short hex, whitespace tolerance). These become Elm eq-pin targets, so
   precision matters more than prose. If the math lives in a util file shared with other
   components (e.g. `seemly` usage), say exactly which functions come from which import and
   record seemly's exact behavior for the ones used (check node_modules if present).
5. **Theme/cssr vars** — exact generated CSS var names in order, dark-theme overrides, any
   cssr rules keyed off props (size modes etc.).
6. **Examples inventory** — every demo file with a one-line description of what it shows.
7. **Port-fit assessment** — which parts map to pure Elm helpers, which are DOM-bound
   (canvas eyedropper? native input elements? drag listeners?), and the recommended
   view/panel split for the port (house rule: caller-owned show/positioning, `view` trigger +
   `panel` body, `focusDetector` sentinel, `transition : Maybe phase` — see how DatePicker
   did it if you need a reference, but do NOT read elm workspace modules beyond that).

## Hard constraints
- READ-ONLY on both trees except writing the single output file under `tasks/recon/`.
- NO `git` commands that mutate anything. NO commits. NO builds. NO npm installs.
- Tool hygiene: never issue the same tool call twice; if a read fails once, note it and move on.
- Do not paste entire upstream files into the doc — extract and cite.
- Finish with the doc written, then reply with a ≤10-line summary + the doc path.
