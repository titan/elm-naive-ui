# Brief: feat(color-picker) — NUI.Internal.Color engine + NUI.ColorPicker component

You are the implementation lane for the ColorPicker batch in `/home/titan/Works/elm/elm-naive-ui`
(branch master, HEAD `baffd42` — prep already landed: manifest + generated theme + CSS + elm.json
exposure of `NUI.Theme.ColorPicker`). Work DIRECTLY in that directory. **DO NOT run `git commit`,
`git add`, `git stash`, or any mutating git command — the orchestrator reviews, gates, and commits.**

## Required reading BEFORE writing code (in order)
1. `tasks/recon/color-picker-1-upstream.md` — the upstream map (API, panel tree, ALL pure math
   with exact bytes, theme vars, port-fit, 5 flagged divergences). §4 is your spec.
2. `tasks/recon/color-picker-2-elm.md` — the elm-side integration map (DatePicker pattern cites,
   tooling checklist §2, examples §3, tests §4, existing color code §5, risks R1-R10 §8).
3. `src/NUI/DatePicker.elm` — the overlay pattern model (view/triggerVars/panel/panelVars/
   focusDetectorNode/embedHtml; cites in recon-2 §1/§9).
4. Ground truth for colour math: `tools/node_modules/seemly@0.3.10/lib/color/{convert,index,colors}.js`
   (exactly the version naive-ui v2.45.3 pins). Derive every formula from THESE bytes, not memory.
   `src/NUI/Internal/DateTime.elm` docstring = the style contract for an internal engine module.

## Deliverables (all in ONE working-tree change set)

### A. `src/NUI/Internal/Color.elm` — pure engine (unexposed, like NUI.Internal.DateTime)
- Seemly conversions §4.1 (hsl2hsv, hsv2hsl, hsv2rgb, rgb2hsv, rgb2hsl, hsl2rgb — exact float math).
- Seemly parsers §4.2: `hsla`, `hsva`, `rgba` with the EXACT regexes (incl. `\s*` tolerance,
  percent groups) and rgba try-order (`#RRGGBB`→`rgb()`→`rgba()`→`#RGB`→`#RRGGBBAA`→`#RGBA`→
  named-colour map→`hsl/hsla`→`hsv/hsva`→throw). Port the **148-entry named table** from
  `tools/node_modules/seemly/lib/color/colors.js` verbatim (transparent→'#0000' etc.).
- Seemly rounders + serializers §4.3 (roundChannel/roundPercent/roundDeg/roundAlpha,
  toRgb/Rgba/Hsv/Hsva/Hsl/Hsla/Hex/HexaString — `", "` separators, 2-dp alpha, hex uppercase).
- utils.ts §4.4: deriveDefaultValue, getModeFromValue, getWCAGContrast + rgb2luminance,
  normalizeHue (clamps 360→**359** — keep upstream divergence vs roundDeg), normalizeAlpha,
  convertColor + the 12-cell convert table. SKIP `floor` (dead export upstream) — say so in a
  docstring line.
- ColorInputUnit normalizers §4.5 (regexes exact; normalizeAlphaUnit clamps to 100 — keep).
- Slider drag geometry §4.6 as pure fns of (rect, pointer): svFromPoint, hueFromPoint,
  alphaFromPoint (HANDLE_SIZE 12, RADIUS 6; hue = normalizeHue(((x-left-6)/(width-12))*360)).
- No ports, no Dict/String.reverse hacks needed; floats via Elm Basics only. Module docstring
  states the seemly@0.3.10 ground truth + the intentional divergences.

### B. `src/NUI/ColorPicker.elm` — public component (DatePicker overlay shape)
- `Options msg` record + `defaultOptions` mirroring the 18-prop API §2.1 (value, show→caller
  state means: no `show` option needed — panel is caller-mounted; carry defaultValue derivation
  as a pure helper instead). Caller-owned runtime: `onUpdateValue`, `onComplete`, `onConfirm`,
  `onClear`, `onUpdateShow`, `transition : Maybe I.TransitionPhase`, `disabled`, `size : T.Size`,
  `modes`, `showAlpha`, `showPreview`, `swatches`, `actions`, `internalActions` (+ caller-side
  `undoable`/`redoable` Bools + `onUndo`/`onRedo` msgs — upstream's stack is runtime state),
  `renderLabel : Maybe (String -> Element msg)`, label/trigger custom-node options following
  DatePicker's option idioms (see how DatePicker does label/slot knobs).
- `view : Theme -> Options msg -> Element msg` — trigger tree §3.3: `div.n-color-picker`
  [`--disabled`] > `__fill` > checkboard div + absolute colour layer (bg = hsla string or "") +
  `__value` label (colour white/black via getWCAGContrast). Carries the 10 `--n-*` vars in the
  EXACT declaration order §5.1 (bezier, textColor, color, panelFontSize, fontSize<size>,
  boxShadow, border, borderRadius, height<size>, dividerColor) + click msg unless disabled.
- `panel : Theme -> Options msg -> Element msg` — panel tree §3.2: `div.n-color-picker-panel`
  (+ `I.transitionClass "fade-in-scale-up-transition"` when Just) > `__control` > [Pallete
  (two gradient `__layer` divs + `--shadowed` + handle `__fill` at calc(% - 6px)), `__preview`
  (`__sliders` > HueSlider rail + optional AlphaSlider w/ checkboard + `__image` gradient,
  optional ColorPreview 30×30 `__preview`+`__fill` + hidden `input[type=color]`), ColorInput
  (`__input` > `__mode` label "RGB(A)"-style + `NUI.Input.group` of small `NUI.Input`s),
  optional Swatches grid], then optional `.n-color-picker-action` row(s) (actions confirm/clear
  via `NUI.Button`; internalActions undo/redo row is a SEPARATE action div), then
  `focusDetectorNode` sentinel LAST (house convention — upstream uses clickoutside-capture
  instead; that mapping is a documented divergence). Panel carries the same 10 vars. `tabindex 0`
  on the panel if DatePicker does — mirror DatePicker.
- Expose pure helpers publicly (eq-pin surface, DatePicker precedent): getModeFromValue,
  convertColor, deriveDefaultValue, normalizeHue, normalizeAlpha, getWCAGContrast, the 5 unit
  normalizers, the 3 slider-geometry fns, and a `nextDisplayedMode : List Mode -> Mode -> Mode`
  (cyclic advance, 'rgb' fallback — §3.2 handleUpdateDisplayedMode).
- Embed `NUI.Input`/`NUI.Button` via the `embedHtml` idiom (recon-2 §1.8). Theme peers: read
  `NUI.Theme.Input`/`NUI.Theme.Button` vars like DatePicker does (R7) — no new plumbing.
- NO changes to `src/NUI/Input.elm` (recon-2 §7 decision: no new seams). If a styling detail is
  unreachable (e.g. unit input `padding 0 4px`), document it as `[oracle D]` in the docstring —
  do not invent seams.
- Module docstring: component mapping summary + `[oracle D]` lines (format like
  `src/NUI/DatePicker.elm:115-156`) for: (1) clickoutside-capture→focusDetector mapping,
  (2) named-colour swatch resolution via static 148-table instead of canvas (system colours
  unresolvable), (3) undo/redo stack is caller-owned, (4) normalizeHue 359 clamp kept,
  (5) cssr header comment omits --n-border (we emit all 10), (6) upstream `slots.default`
  declared-unused — not ported, (7) any you discover.

### C. Wiring
- `tools/verify/check-exposure.mjs`: add `'NUI.Internal.Color'` to the INTERNAL set (next to
  `'NUI.Internal.DateTime'`).
- `tools/verify/check-dom.mjs`: add `'.n-color-picker': true` and `'.n-color-picker-panel': true`
  (both carry the 10-var set, R10).
- `examples/src/Main.elm`: `colorPickerSection` after `datePickerSection` (recon-2 §3), with
  live fixtures rendering trigger AND a mounted panel (so check-dom sees both), covering: basic,
  showAlpha=false+actions confirm, sizes ×3, disabled, modes=['hex'], swatches, actions clear,
  showPreview, custom trigger. Mirror upstream demos §6 minus form/close-debug.
- `README.md`: row `| \`NUI.ColorPicker\` | ✅ |` between NUI.Cascader and NUI.DatePicker
  (recon-2 §6).
- `tools/verify/check-classes.mjs`: ALLOW ONLY if a class is emitted with no cssr rule — cite
  upstream file:line in a comment. Expect NONE needed (checkboard/pallete/sliders are styled).

## Verification you must run (foreground; ELM_HOME=/tmp/elm-home)
1. `node tools/verify/check-classes.mjs` (from repo root)
2. `node tools/verify/check-theme.mjs`
3. `node tools/verify/check-exposure.mjs`
4. `elm make --output=/dev/null`
5. `cd examples && elm make src/Main.elm --output=index.html` then `node tools/verify/check-dom.mjs examples/index.html` (from root)
6. `bash tests/run.sh` must STILL pass 3571/3571 + 2160 (you add NO tests — that's a later lane)
7. `elm-format` your new/edited files (elm-format --validate src examples tests must stay clean;
  run `elm-format src/NUI/Internal/Color.elm src/NUI/ColorPicker.elm examples/src/Main.elm` to fix)

## Hard constraints
- NEVER `git add`/`git commit`/`git stash` — leave everything in the working tree.
- No new files beyond: src/NUI/Internal/Color.elm, src/NUI/ColorPicker.elm. Edits only to:
  check-exposure.mjs, check-dom.mjs, examples/src/Main.elm, README.md, (check-classes.mjs only
  if a justified ALLOW is needed). NOTHING else — especially not Input.elm, Theme files, css/,
  generated/, tests/.
- No npm installs. No background/nohup commands (they die silently in this sandbox).
- Tool hygiene: never repeat an identical tool call; a failed command → read the error, fix, retry differently.
- Upstream tree `/home/titan/Works/elm/naive-ui` is READ-ONLY reference.
- Keep `tasks/` untouched.
- Reply at the end with: files changed + line counts, gate steps you ran with results, and any
  `[oracle D]` divergences you documented (numbered list).
