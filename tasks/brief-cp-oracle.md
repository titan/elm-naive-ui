# Brief: ColorPicker oracle audit (read-only fidelity review)

You are the oracle for the elm-naive-ui ColorPicker batch. READ-ONLY audit: compare the port
against upstream ground truth and render a verdict. Workspace: `/home/titan/Works/elm/elm-naive-ui`
(master @ `934a455`; commits baffd42 prep / 0145e28 feat / f6b9b37 test / 934a455 refactor).
Upstream reference (read-only): `/home/titan/Works/elm/naive-ui` (naive-ui v2.45.3).
Seemly ground truth: `/home/titan/Works/elm/elm-naive-ui/tools/node_modules/seemly` @ 0.3.10
(exactly the version naive-ui pins).

## Prior art to read first
- `tasks/recon/color-picker-1-upstream.md` (the upstream map — challenge it if wrong)
- `tasks/recon/color-picker-2-elm.md` (integration map + risks R1-R10)
- `tasks/recon/color-picker-pins.md` (pin table; lane reported ZERO failures)
- The port: `src/NUI/ColorPicker.elm`, `src/NUI/Internal/Color.elm`, the color-picker blocks
  in `examples/src/Main.elm`, `tests/src/Main.elm` (`-- COLOR-PICKER`), `tests/inspect.mjs`,
  `tools/verify/check-dom.mjs` (targets), `css/naive-ui.css` (n-color-picker block vs upstream
  `src/color-picker/src/styles/index.cssr.ts`).

## Audit checklist (verdict per item: S = should fix, D = documented divergence, R = right)
1. **Trigger DOM**: `div.n-color-picker[--disabled] > __fill > [checkboard, colour layer
   (bg unset vs hsla string), __value (WCAG white/black)]` vs `ColorPickerTrigger.tsx:31-66`.
   Missing/extra attrs, wrong conditional gates (label only when value && hsla-derived?).
2. **Panel DOM**: full tree vs `renderPanel` (ColorPicker.tsx:586-728): control > pallete
   (2 layers, --shadowed, handle+__fill, calc offsets −6px), preview sliders (hue rail gradient
   const exact, alpha __image gradient rgba(R,G,B,0)→(R,G,B,1), handle calc strings), optional
   ColorPreview + hidden input[type=color], __mode label text (`MODE.toUpperCase() + (showAlpha
   ? 'A' : '')`), NInputGroup unit count/labels per mode, swatch grid (tabindex, __fill bg),
   TWO separate action rows (actions vs internalActions/slot), focusDetector last, tabindex,
   ondragstart. Sizes: which nodes exist per size/mode/alpha flags.
3. **cssVars**: the 10 names + DECLARATION ORDER on BOTH trigger and panel vs
   `cssVarsRef` (ColorPicker.tsx:546-576); size-keyed height/fontSize via createKey; values
   wired to `NUI.Theme.ColorPicker.vars` (13-key self; dark = common swap only).
4. **Engine math vs seemly bytes**: all 6 conversions, the 4 parser regexes + try-order +
   named-table (149 entries — spot-check ≥10 incl. transparent/red/white/fuchsia/rebeccapurple,
   case sensitivity), rounders (roundChannel/Percent/Deg(360→0)/Alpha(2dp)), serializers
   (separators ", ", hex uppercase, hexa FF default). Also: floatModBy vs JS `%` (floored vs
   truncated — is the non-negative-input invariant actually guaranteed by every caller?),
   `getInputString` (ColorInputUnit.tsx:73-85: HEX verbatim / A `${floor(a*100)}%` / floor int)
   — is it ported correctly wherever unit display strings are built?
5. **utils.ts semantics**: deriveDefaultValue, getModeFromValue (`/^ *#/`, substring probes,
   order), getWCAGContrast (a==1 luminance path vs alpha-blend path, 4.5 threshold, default
   contrastColor [255,255,255]), normalizeHue(359) vs roundDeg(0) divergence correctly placed,
   convertColor + 12-cell table (each cell's exact to*String target + alpha threading).
6. **Defaults**: modes [rgb,hex,hsl], showAlpha true, showPreview false, size medium,
   placement bottom-start (caller-owned — documented?), defaultValue derivation, swatch
   normalization (`normalizeColor` hsv→rgba conversion, `normalizeOutput` hex-default +
   name-path), undo/redo reset-on-close semantics — each either ported, caller-owned, or D.
7. **The 12 documented divergences** in `src/NUI/ColorPicker.elm`'s docstring + 2 engine notes:
   is each CORRECTLY characterized (right upstream line, right claim)? Any UPSTREAM behaviour
   MISSING from the list entirely (undocumented divergence = S-class until documented)?
8. **Gate wiring**: check-dom `.n-color-picker`/`.n-color-picker-panel` true (both carry vars);
   no check-classes ALLOW (verify every emitted class really has a cssr rule); INTERNAL set
   entry; README row; examples fixtures render both surfaces.
9. **Pins honesty** (spot-check ~15 pins incl. the hsv2rgb(0,0,100)→white correction): do the
   expected values match ground truth (run `node -e` against seemly where applicable)? Any pin
   that looks derived from the port rather than upstream (circular)?

## Output
Write `tasks/recon/color-picker-oracle.md`: numbered S findings (each: exact port file:line,
exact upstream cite, what's wrong, what the fix is), D findings (confirm/adjust each docstring
line), R verdicts summarized per checklist item. If S findings exist, rank by impact. Do NOT
edit any port file — this is read-only. No git mutations. No builds needed (jsdom probes already
exist; you may run `ELM_HOME=/tmp/elm-home bash tests/run.sh` read-only if useful — it writes
only elm-stuff/index artifacts). Tool hygiene: never repeat an identical tool call.
Reply with: S count (list one-liners), D count, and the doc path.
