# Brief: test(color-picker) — pins-first eq pins + DOM probes

You are the test lane for the ColorPicker batch in `/home/titan/Works/elm/elm-naive-ui`
(branch master; the feat commit exposing `NUI.ColorPicker` has already landed — ask
`git log --oneline -3` to confirm). Work DIRECTLY in that directory.
**DO NOT run `git add`/`git commit`/`git stash` — the orchestrator commits.**

## Phase 1 — derive pins BEFORE reading the port (mandatory order)
Ground truth (READ-ONLY):
- `tools/node_modules/seemly@0.3.10/lib/color/{convert,index,colors}.js` — run cases through
  the REAL code with `node -e` (require the lib by absolute path). This is the exact version
  naive-ui v2.45.3 pins.
- Upstream `/home/titan/Works/elm/naive-ui/src/color-picker/src/{utils.ts,ColorInputUnit.tsx,
  ColorPicker.tsx,ColorPickerTrigger.tsx}` and `styles/index.cssr.ts` — for utils fns, panel
  tree expectations, cssVars order, trigger tree.
FORBIDDEN until Phase 1 doc is complete: reading `src/NUI/ColorPicker.elm`,
`src/NUI/Internal/Color.elm`, or any tests/* edits.

Deliverable: `tasks/recon/color-picker-pins.md` — a pin TABLE (input → expected exact output,
each row citing the ground-truth source: seemly file / utils.ts:line / node -e output):
1. Conversions: for each of the 6 seemly conversions, pick inputs whose outputs are EXACTLY
   representable floats (halves/quarters/integers) — e.g. hsv2rgb(0,0,100)→[255,0,0],
   rgb2hsv(255,0,0)→[0,100,100], plus at least one non-trivial mid-value case per fn pinned
   THROUGH a serializer string (avoids float-equality traps).
2. Parsers rgba/hsla/hsva: ≥12 cases across: `#RGB`/`#RGBA`/`#RRGGBB`/`#RRGGBBAA`, rgb()/rgba()
   with decimals + inner spaces, hsl()/hsla()/hsv()/hsva() with %, named colours ('red',
   'transparent', 'Fuchsia' case-sensitivity — check the map keys!), leading/trailing spaces,
   INVALID inputs (what EXACTLY happens: 'rgb(300,0,0)'? 'hsl(1,2)'? '#GGG'? 'red ' trailing
   space? — record the truth; in the port invalid likely maps to a Result/Maybe — pin the
   port-mapped shape once you read it, keeping the underlying values from Phase 1).
3. Rounders + serializers: roundDeg(360)→0 vs normalizeHue(360)→359 divergence row; roundAlpha
   2-dp; toHexaString('#RGB' input), toHexString('#RRGGBBAA' input), string-input throwers.
4. utils.ts fns: deriveDefaultValue (4 modes × showAlpha), getModeFromValue (incl. ' #abc'
   leading-space true case, 'rgba(...)'→rgb, 'red'→null), getWCAGContrast (a=1 dark/light
   boundary cases + one blended alpha case with default contrastColor), convertColor + convert
   table spot-checks (hex→hsv with alpha, hsv→hex, same-mode passthrough, invalid→null).
5. Unit normalizers: normalizeRgbUnit('255.9')→255, (' 7 ')→7, ('-3')→? (parseInt('-3') passes
   regex → max(0,-3)=0 — verify!), ('1e2'→false), hue 360 ok / 361→360, slv 100/101,
   alpha '200%'→? (verify clamp-100 truth), hexa lengths 4/5/7/9 ok, ('#ABC') ok, ('#AB')→false.
6. Slider geometry: svFromPoint/hueFromPoint/alphaFromPoint for 3 rects each incl. the -6px
   handle offset edge (x left of rail → hue 0; x beyond → 359; alpha→1).
7. nextDisplayedMode cycling: modes=['rgb','hex','hsl'] from each + a mode-not-in-list fallback.
8. DOM expectations table (from upstream trees §3.2/3.3/5.1): trigger class list + 10-var
   ORDER (exact string sequence), panel tree shape (control > pallete layers+handle, preview
   sliders, input mode+group, swatches grid, action rows), --disabled, WCAG label colour cases,
   handle calc() strings.

## Phase 2 — write the tests (NOW you may read the port)
- eq pins in `tests/src/Main.elm` under a `-- COLOR-PICKER` banner (pattern: `-- DATE-PICKER /
  TIME-PICKER FIXTURES` area, `eq` helper at :218, `checks` list :6273). ONLY exposed
  `NUI.ColorPicker.*` fns (the feat exposes: getModeFromValue, convertColor,
  deriveDefaultValue, normalizeHue, normalizeAlpha, getWCAGContrast, unit normalizers, slider
  geometry fns, nextDisplayedMode — confirm exact names by reading the module). If a Phase-1
  pin targets an unexposed internal, route it through a DOM probe or drop it with a note.
- DOM probes in `tests/inspect.mjs` (`dEq`/`dTrue`/`nClassesStr`/`varOrder`/`countVars`/
  `styleAt` helpers) + `#live-color-picker*` fixtures rendered in `tests/src/Main.elm`
  `liveNodes` (pattern: `#live-date-picker`, `#live-date-panel-*`). Cover: trigger classes+vars
  (order!), disabled modifier, panel tree (pallete layers/handle calc strings, mode label text,
  input-group presence, swatch grid children, action buttons + separate rows), WCAG label
  colour, sizes → height/fontSize var picks.
- Run `ELM_HOME=/tmp/elm-home bash tests/run.sh` (foreground). Baseline BEFORE your edits:
  3571 assertions + 2160 DOM, 0 failures. Record your after-counts.
- ZERO fixes to port modules. If a pin FAILS against the port, do not adjust the pin to match
  the port and do not fix the port — record it in the pins doc under "FAILURES" with the exact
  mismatch; the orchestrator routes it to the fix lane.

## Hard constraints
- No `git` mutations. No npm. No backgrounded commands. Never repeat an identical tool call.
- Edit ONLY: tests/src/Main.elm, tests/inspect.mjs, tasks/recon/color-picker-pins.md.
- Keep the two-phase order honest — the pins doc must exist before you open the port modules.
- Reply with: pins-doc path, # eq pins added, # DOM probes added, final counts (assertions/DOM/
  failures), and the FAILURES list (empty if none).
