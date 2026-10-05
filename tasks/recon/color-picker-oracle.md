# color-picker-oracle.md — ColorPicker fidelity audit (read-only)

Oracle audit of the `ColorPicker` batch against upstream ground truth.
Workspace `/home/titan/Works/elm/elm-naive-ui` @ `934a455`
(`baffd42` prep / `0145e28` feat / `f6b9b37` test / `934a455` refactor).
Upstream = `/home/titan/Works/elm/naive-ui` @ v2.45.3 (`src/color-picker/src/…` unless
written out in full). Seemly bytes = `tools/node_modules/seemly@0.3.10/lib/color/*`
(verified 0.3.10). No port file was modified; no git mutation.

**Method.** Every claim below was checked against the actual upstream/seemly bytes, not
against the recon summaries. Engine equality was checked line-for-line against
`seemly/lib/color/{convert,index,colors}.js`; the named table was diffed programmatically
against `colors.js` (149/149 exact, 0 missing / 0 extra / 0 mismatched); the Elm float
kernel (`elm/core@1.0.5 Elm/Kernel/String.js`) was read to confirm
`String.fromFloat == JS String(number)` and `String.toFloat == +s` (so `.5`, `255.`,
`""` behave exactly like JS `Number`). The lane's pins (111 `eq` + 35 DOM) were
spot-checked (~20) by recomputation and are honest; DOM probes assert upstream-cited
values, not port outputs.

## Verdict summary

- **Engine (`src/NUI/Internal/Color.elm`) — R (right), with no S findings.** All 6
  conversions, all 4 parser regexes + try-order + capture indices, all 4 rounders, all 8
  serializers, the 12-cell convert table, `deriveDefaultValue`/`getModeFromValue`/
  `getWCAGContrast`/`normalizeHue`/`normalizeAlpha`, the unit normalizers, and the drag
  geometry reproduce seemly/`utils.ts` byte-for-byte. The named-colour table is exact.
- **Trigger/panel DOM — R apart from the items below.** Tree shape, class order, attr
  gating, the 10-var order on both surfaces, the `calc(...)` strings, the WCAG label
  colour, mode-label text, unit labels, swatch `__fill` verbatim, and the two action rows
  all match upstream.
- **Gate wiring — R.** `check-dom` targets both carry vars; no `check-classes` ALLOW entry
  needed (every emitted class has a cssr rule — verified against `css/naive-ui.css`);
  `NUI.Internal.Color` in the INTERNAL set; `NUI.ColorPicker` + `NUI.Theme.ColorPicker`
  exposed; README row; examples render both surfaces.
- **S count: 2** (one feature gap, one style gap). Both are undocumented divergences.
- **D count: 12 confirmed (D1–D12) + 5 engine notes (correct) + 6 recommended additions.**

---

## S findings (ranked by impact)

### S1 — `action` slot (the 2nd action row) has no port counterpart — FEATURE GAP
- **Port:** `src/NUI/ColorPicker.elm:215-237` (`Options` has `internalActions` but no
  action-slot field), `:511-524` (`panel` renders `actionsRow ++ internalActionsRow`),
  `:1084-1098` (`internalActionsRow`).
- **Upstream:** `ColorPicker.tsx:695-701` — `slots.action ? <div.n-color-picker-action>{slots.action()}</div>
  : internalActions ? <div.n-color-picker-action>…undo/redo…</div> : null`;
  `ColorPickerSlots.action` declared at `ColorPicker.tsx:145`.
- **What's wrong:** the port exposes the `internalActions` branch but not the `slots.action`
  branch. Upstream's second action row is a caller-provided node that *also suppresses* the
  internalActions row when present. A caller cannot inject a custom `.n-color-picker-action`
  row inside the panel — the panel builds the whole subtree, so building it externally is not
  equivalent (wrong DOM position / not wrapped in `.n-color-picker-action`).
- **Fix:** add `actionSlot : Maybe (Element msg)` to `Options`+`defaultOptions`; in `panel`
  render `opts.actionSlot |> Maybe.map (\n -> [ div.n-color-picker-action [ n ] ]) |>
  Maybe.withDefault (internalActionsRow theme opts)`. House precedent already exists:
  `DatePicker.actionsSlot` (`src/NUI/DatePicker.elm:2381`). (Alternatively document it as an
  intentional omission — but nothing in the docstring mentions it.)

### S2 — `A`-unit `flex-grow: 1.25` inline style is not ported — STYLE GAP
- **Port:** `src/NUI/ColorPicker.elm:831-845` (`unitInputs` builds every `NInput` with
  `{ size, placeholder, value, onInput }` and no per-unit style).
- **Upstream:** `ColorInputUnit.tsx:162` — `style={this.label === 'A' ? 'flex-grow: 1.25;' : ''}`.
- **What's wrong:** the alpha numeric input is not widened 1.25× (visible spacing difference).
  The docstring's D9 covers only the sibling `builtinThemeOverrides` `padding: 0 4px`
  (`ColorInputUnit.tsx:58-60`); the `flex-grow` `style` prop is a *different* seam and is
  not mentioned anywhere.
- **Fix:** give `NUI.Input` a small inline-style seam (or an `attrStyle` option) and pass
  `flex-grow:1.25` for the `A` unit, or extend D9 to cover it.

*(Both S findings are "the port simply omits an upstream feature"; neither is a mis-ported
computation. No S finding in the engine.)*

---

## D findings

### Confirm the 12 component divergences (docstring `src/NUI/ColorPicker.elm:57-131`)
| # | Claim | Upstream cite | Verdict |
|---|---|---|---|
| D1 | clickoutside-capture → focus-detector sentinel | `ColorPicker.tsx:745-759` (`handleClickOutside`), panel has **no** tabindex/sentinel | **Correct.** Panel root also adds `tabindex 0` (`:518`) — see D15 below. |
| D2 | named swatches via static 149-table, not canvas | `ColorPickerSwatches.tsx:20-26` | **Correct.** Table diffed exact vs `colors.js`. |
| D3 | undo/redo stack caller-owned | `ColorPicker.tsx:322-324` (`undoStackRef`/`valueIndexRef`), `:524-529` (reset-on-close `watch`) | **Correct.** |
| D4 | `normalizeHue` 360→359 vs `roundDeg` 360→0 | `utils.ts:99-102` vs `seemly index.js:210-217` | **Correct.** Both ported (`Color.elm:1165-1175` / `:423-435`). |
| D5 | cssr header comment lists 9 vars, omits `--n-border` | `index.cssr.ts:4-13` (comment) vs `:546-576` (`cssVarsRef` emits 10) | **Correct.** |
| D6 | `slots.default` declared, never read | `ColorPicker.tsx:143` | **Correct.** |
| D7 | no pointer-drag wiring; pure geometry exported | `Pallete.tsx:34-52`, `HueSlider.tsx:36-60`, `AlphaSlider.tsx:35-58` | **Correct.** |
| D8 | unit inputs commit on input, not change | `ColorInputUnit.tsx:86-141` (`handleInputChange` on `change`) | **Correct.** |
| D9 | unit `padding: 0 4px` unreachable | `ColorInputUnit.tsx:46-48, 157` (`builtinThemeOverrides`) | **Correct but incomplete** — see S2 (flex-grow missing). |
| D10 | panel `ondragstart` preventDefault not ported | `ColorPicker.tsx:599-601` | **Correct.** |
| D11 | swatch Enter-key select not ported | `ColorPickerSwatches.tsx:93-97` | **Correct.** |
| D12 | upstream `onComplete` has no port option | `ColorPicker.tsx` `handleComplete` | **Correct.** |

### Confirm the engine docstring notes (`src/NUI/Internal/Color.elm:50-73`)
Correct as written: `normalizeHue` 359 vs `roundDeg` 0; `floor` dead export dropped
(`utils.ts:95`); `toHex{,a}String(string)` overloads dropped (`seemly index.js:270-322` —
no naive-ui call site, all call sites use the array form); named-colour static table.

### Recommended docstring additions (currently undocumented)
These are minor/observable divergences the docstring does not mention. Per the brief's rule
(undocumented divergence ⇒ S until documented) they are flagged here as documentation gaps,
ranked below S1/S2 because they are either convention-conforming or steady-state-equivalent:

- **D13 — displayed state is `value`-derived, not a separate ref group.** Port derives
  hue/alpha/SV from the parsed `value` each render (`palette` `:556-560`, `hueSlider`
  `:635-638`, `alphaSlider` `:684-700`); upstream keeps `displayedHueRef`/`displayedAlphaRef`/
  `displayedSvRef` (`ColorPicker.tsx:322-324`) resynced to `hsvaRef` on value change
  (`:531-545`). Identical in steady state; during a drag the caller owns it (D7). Worth one line.
- **D14 — peer theme overrides not plumbed.** Upstream passes `mergedTheme.peers.Input` /
  `peers.Button` (`ColorInputUnit.tsx:155-156`; `ColorPicker.tsx` action buttons) to the
  embedded components; the port uses `NUI.Theme.Input`/`NUI.Theme.Button` directly
  (`ColorPicker.elm:831-845`, `:1035-1082`). House precedent (DatePicker) behaves the same.
- **D15 — panel root carries `tabindex="0"`.** `ColorPicker.elm:518` adds it; upstream
  `renderPanel` (`ColorPicker.tsx:586-608`) has no tabindex. House overlay convention
  (`DatePicker.elm:1145`). Pairs with D1's focus detector.
- **D16 — trigger colour layer omits the empty `background-color`.** Port emits only the
  positioning style when the value is mode-less (`ColorPicker.elm:461-476`); upstream always
  emits `backgroundColor: hsla ? toHslaString(hsla) : ''` (`ColorPickerTrigger.tsx:47-55`).
  Visual no-op; the attribute string differs.
- **D17 — `getWCAGContrast` only the defaults are exposed.** Upstream signature carries
  `contrastColor = [255,255,255]` and `level = 'AA'` (`utils.ts:58-61`); the port hardcodes
  both (`Color.elm:1112-1135`). Only the trigger call site uses the defaults.
- **D18 — `deriveDefaultValue`'s `__DEV__` warn dropped** (`utils.ts:38-39`). No-op outside dev.

---

## R verdicts per checklist item

**1. Trigger DOM — R.** `div.n-color-picker[--disabled]` (`ColorPicker.elm:422-445`) vs
`ColorPickerTrigger.tsx:31-66`: class set order (`--disabled` only when disabled), click
gated on `disabled`, `__fill` → `[checkboard, unclassed absolute colour layer, __value]`,
`__value` only when `value && hsla`, label colour `getWCAGContrast ? white : black`,
label text `renderLabel(value) || value`. Only D16 (empty-bg attr) differs.

**2. Panel DOM — R + S1/S2.** Full tree vs `renderPanel` (`ColorPicker.tsx:586-728`):
control = pallete + preview(hue rail + optional alpha rail + optional ColorPreview) +
colorInput + optional swatches; then the actions row and the internalActions row (two
separate `.n-color-picker-action` rows — confirmed by the DOM probe: `2|Confirm|Clear|Undo|Redo`).
Palette = two `__layer` divs (2nd `--shadowed`) + handle with `left/bottom calc(S%/V% - 6px)`
and `__fill rgb(R, G, B)`; hue rail gradient const exact, handle `calc((H%) / 359 * 100 - 6px)`;
alpha rail `__image` `linear-gradient(to right, rgba(R,G,B,0) 0%, rgba(R,G,B,1) 100%)`,
handle `calc(α*100% - 6px)`; ColorPreview `span.__fill` + `input[type=color]`; `__mode` text
`MODE.upper + (showAlpha?'A':'')`, `cursor:pointer` iff `modes.length>1`; `NInputGroup` of
small units (labels R/G/B/A … or single HEX); swatch grid with `tabindex 0` + `__fill`
verbatim; focusDetector last; `tabindex 0`; no `ondragstart` (D10). Sizes: size variance
rides only the vars (no prop-keyed nodes) — small→`--n-height:28px`/`--n-font-size:14px`,
large→`40px`/`15px`, exact vs `styles/light.ts`. Gaps: S1 (action slot), S2 (A-unit flex-grow).

**3. cssVars — R.** `styleVars` (`ColorPicker.elm:364-382`) emits the 10 names in the exact
`cssVarsRef` order (`ColorPicker.tsx:546-576`): `bezier, text-color, color, panel-font-size,
font-size, box-shadow, border, border-radius, height, divider-color`, on **both** trigger and
panel; `--n-font-size`/`--n-height` via the size case (`:394-420`) ≈ `createKey`; values read
from `NUI.Theme.ColorPicker.vars` (13-key self, dark = common swap only — verified against
`tools/generated/color-picker.json` and `Theme/ColorPicker.elm`). (`T.Tiny`→Small is a
house pick; upstream `ColorPickerSize` has no tiny.) D5/D15 noted.

**4. Engine math vs seemly bytes — R.** 6 conversions exact incl. `hsl2rgb`/`hsv2rgb`
`Math.min(k,…)` order and `%`; 4 parser regexes exact (`prefix/suffix/percent/float/hex/dhex`),
try-order exact (`hex→rgb→rgba→sHex→hexa→sHexa→named→hsl/hsla→hsv/hsva`), capture indices
exact (`i[1],i[5],i[9],i[13]`); rounders exact (`roundDeg 360→0`, `roundChannel`/`roundPercent`
clamp, `roundAlpha` 2-dp); serializers exact (`", "`, hex uppercase, `hexa` alpha default FF);
149-entry named table **byte-identical**. `floatModBy` (floored) ≡ JS `%` (truncated) because
the invariant holds — `h` only ever enters via `roundDeg` (0–359) or is carried unchanged, so
`n + h/60 ∈ [1, 11)` and `n + h/30 ∈ [0, 20)`; the only callers are `hsv2rgb`/`hsl2rgb`,
reached from `rgba`/`hsva`/`convert` (all parsed). `getInputString` reproduced at
`channelToStr` (`:894-906`: HEX verbatim via `hexValueStr`, `A`→`floor(a*100)%`, else
`floor`) and `hexValueStr` (`:908-919`) for the HEX unit.

**5. `utils.ts` semantics — R.** `deriveDefaultValue` (`Color.elm:1043-1071`), `getModeFromValue`
(`:1081-1104` incl. `/^ *#/` then substring order), `getWCAGContrast` (`:1112-1135`: a==1
luminance path vs alpha-blend path, 4.5 threshold, default `contrastColor` white),
`normalizeHue(359)` vs `roundDeg(0)` correctly separated, `convertColor` + 12-cell table
(`convert :1194-1248`, `convertColor :1250-1268`) each cell's exact `to*String` + alpha
threading — all match `utils.ts:23-199`.

**6. Defaults — R (caller-owned).** modes `[Rgb,Hex,Hsl]`, `showAlpha True`, `showPreview
False`, size `Medium` = upstream defaults. `placement`/`to` = caller-owned (documented as
"positioning caller-owned"). `defaultValue` derivation = the pure `deriveDefaultValue`
(exposed); the caller seeds `value`. Swatch normalization = `normalizeColor`/`normalizeOutput`
(`:966-1012`) exact. Undo/redo reset-on-close = caller-owned (D3). See D13 (displayed state)
and D13-adjacent note: `defaultOptions.displayedMode = Rgb` (`:249`) — matches upstream's
computed default *only when `value` is unset*; when the caller sets `value` without
`displayedMode`, upstream would derive the mode from the value (`ColorPicker.tsx:234-236`) —
worth a docs line.

**7. The 12 divergences — D1–D12 confirmed; 4 engine notes confirmed; 6 additions (D13–D18).**
The two S findings are upstream behaviours wholly absent from the list.

**8. Gate wiring — R.** `check-dom.mjs:170-171` = `.n-color-picker:true` +
`.n-color-picker-panel:true` (both carry vars). No `n-color-picker*` entry in
`check-classes.mjs` ALLOW (all 25 emitted classes have a rule in `css/naive-ui.css` — the
extract is the whole `index.cssr.ts`). `NUI.Internal.Color` in `check-exposure.mjs:22`;
`NUI.ColorPicker` + `NUI.Theme.ColorPicker` in `elm.json`; README row at `README.md:90`;
manifest `color-picker` entry with the load-bearing kebab key; examples render both `view`
and `panel` (`examples/src/Main.elm:5217-5280`).

**9. Pins honesty — R.** 111 `eq` (only the public `NUI.ColorPicker.*` surface) + 35 DOM
probes; recomputation of the parser/convert/geometry/serializer pins against seemly and the
upstream expressions all matched (e.g. `"#AABBCCDD"→hsva(210,17%,80%,0.87)`, `"hsv(210,50%,50%)"
→#406080FF`, `"hsla(210,50%,50%,0.5)"→#40608080`, `hueFromPoint 100→180`, `alphaFromPoint 97→0.52`).
The hsv2rgb(0,0,100)→white correction is right. No circular pins found (DOM expectations
quote upstream strings such as `rgb(255, 0, 0)`, `calc(100% - 6px)`, `0.2785515320334262`=100/359).

---

## Bottom line

Engine and gate wiring are faithful (R). **2 S findings** — S1 (missing `action` slot, a
real API gap) and S2 (missing `A`-unit `flex-grow:1.25`). **12 D confirmed** (D1–D12), engine
notes confirmed, **6 recommended additions** (D13–D18). None are engine/computation bugs; the
pins are honest and complete for the surface they cover.
