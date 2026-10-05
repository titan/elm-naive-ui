# color-picker-pins.md — Phase 1 pin table (pins-first, derived BEFORE reading the port)

Test lane `test(color-picker)`. This doc was produced **before** opening
`src/NUI/ColorPicker.elm` or `src/NUI/Internal/Color.elm` (two-phase order honoured).

## Ground truth & method

- Seemly **ground truth** = `tools/node_modules/seemly@0.3.10/lib/color/{convert,index,colors}.js`
  (verified `package.json` `"version": "0.3.10"`). Every value below was produced by running the
  **real** module via `node -e 'require("/home/titan/Works/elm/elm-naive-ui/tools/node_modules/seemly/lib/color/index.js")'`
  — not from memory.
- Local pure logic ground truth = upstream `/home/titan/Works/elm/naive-ui/src/color-picker/src/`
  (`utils.ts`, `ColorInputUnit.tsx`, `Pallete.tsx`, `HueSlider.tsx`, `AlphaSlider.tsx`, the panel
  tree in `ColorPicker.tsx`, `styles/index.cssr.ts`).
- **Citation base** = `tools/node_modules/seemly/lib/color/` for seemly, upstream `src/color-picker/src/`
  for the rest (paths written in full only when needed).
- Float-trap avoidance: pins that would need exact float equality are **serialized through a `t*String`
  serializer** (canonical `", "` separators, 2-dp alpha), which is exact string equality.

### Ground-truth source lines (for citation convenience)
- `convert.js`: `hsl2hsv` L11-16, `hsv2hsl` L22-27, `hsv2rgb` L33-38, `rgb2hsv` L44-51, `rgb2hsl` L57-63, `hsl2rgb` L69-74.
- `index.js` regexes L17-27; `hsla` L39-55, `hsva` L61-77, `rgba` L88-146; `roundAlpha` L176-183, `roundDeg` L185-192, `roundChannel` L194-201, `roundPercent` L203-210; `toRgbString` L212, `toRgbaString` L216-223, `toHsvString` L225, `toHsvaString` L228-234, `toHslString` L236, `toHslaString` L239-245, `toHexaString` L251-281, `toHexString` L287-311.
- `colors.js`: 148-entry lowercase map; `red:'#F00'`, `fuchsia:'#F0F'`, `transparent:'#0000'`, `purple:'#800080'`.
- `utils.ts`: `deriveDefaultValue` :23, `getModeFromValue` :44, `getWCAGContrast` :58, `rgb2luminance` :87, `normalizeHue` :99, `normalizeAlpha` :104, `convert` table :109-170, `convertColor` :172-199.
- `ColorInputUnit.tsx`: `normalizeRgbUnit` :6, `normalizeHueUnit` :14, `normalizeSlvUnit` :22, `normalizeHexaUnit` :30, `normalizeAlphaUnit` :39, `getInputString` :73.
- `Pallete.tsx` :44-53; `HueSlider.tsx` :40-49; `AlphaSlider.tsx` :42-49.
- `ColorPicker.tsx`: `handleUpdateDisplayedMode` :238-250, `cssVarsRef` :546-576, `renderPanel` :586-728.

---

## 1. Conversions (seemly `convert.js`) — 6 fns

Inputs chosen so outputs are **exactly representable** (integers / exact binary floats). Mid-value
cases are pinned **through a serializer string** to dodge float-equality traps.

| # | Call | Expected exact output | Source |
|---|---|---|---|
| 1.1 | `hsl2hsv(0, 100, 50)` | `[0, 100, 100]` | convert.js hsl2hsv |
| 1.2 | `hsl2hsv(0, 0, 100)` | `[0, 0, 100]` | node -e |
| 1.3 | `hsl2hsv(0, 0, 0)` | `[0, 0, 0]` | node -e |
| 1.4 | `hsl2hsv(120, 100, 50)` | `[120, 100, 100]` | node -e |
| 1.5 | `hsl2hsv(210, 50, 50)` | `[210, 66.66666666666667, 75]` → serialize `toHsvString` = `hsv(210, 67%, 75%)` | node -e |
| 1.6 | `hsv2hsl(0, 100, 100)` | `[0, 100, 50]` | convert.js hsv2hsl |
| 1.7 | `hsv2hsl(0, 0, 0)` | `[0, 0, 0]` | node -e |
| 1.8 | `hsv2hsl(120, 100, 50)` | `[120, 100, 25]` | node -e |
| 1.9 | `hsv2hsl(210, 50, 50)` | `[210, 33.33333333333333, 37.5]` → `toHslString` = `hsl(210, 33%, 38%)` | node -e |
| 1.10 | `hsv2rgb(0, 0, 100)` | `[255, 255, 255]` ⚠️ **not** `[255,0,0]` (v=100,s=0 ⇒ white) | node -e |
| 1.11 | `hsv2rgb(0, 100, 100)` | `[255, 0, 0]` | convert.js hsv2rgb |
| 1.12 | `hsv2rgb(60, 100, 100)` | `[255, 255, 0]` | node -e |
| 1.13 | `hsv2rgb(120, 100, 100)` | `[0, 255, 0]` | node -e |
| 1.14 | `hsv2rgb(180, 100, 100)` | `[0, 255, 255]` | node -e |
| 1.15 | `hsv2rgb(240, 100, 100)` | `[0, 0, 255]` | node -e |
| 1.16 | `hsv2rgb(300, 100, 100)` | `[255, 0, 255]` | node -e |
| 1.17 | `hsv2rgb(0, 50, 50)` | `[127.5, 63.75, 63.75]` (exact binary) | node -e |
| 1.18 | `hsv2rgb(210, 50, 50)` | `[63.75, 95.625, 127.5]` (exact binary) | node -e |
| 1.19 | `rgb2hsv(255, 0, 0)` | `[0, 100, 100]` | convert.js rgb2hsv |
| 1.20 | `rgb2hsv(0, 255, 0)` | `[120, 100, 100]` | node -e |
| 1.21 | `rgb2hsv(0, 0, 255)` | `[240, 100, 100]` | node -e |
| 1.22 | `rgb2hsv(255, 255, 0)` | `[60, 100, 100]` | node -e |
| 1.23 | `rgb2hsv(0, 0, 0)` | `[0, 0, 0]` | node -e |
| 1.24 | `rgb2hsv(255, 255, 255)` | `[0, 0, 100]` | node -e |
| 1.25 | `rgb2hsv(128, 64, 32)` | `[20, 75, 50.19607843137255]` → `toHsvString` = `hsv(20, 75%, 50%)` | node -e |
| 1.26 | `rgb2hsl(255, 0, 0)` | `[0, 100, 50]` | convert.js rgb2hsl |
| 1.27 | `rgb2hsl(0, 255, 0)` | `[120, 100, 50]` | node -e |
| 1.28 | `rgb2hsl(0, 0, 255)` | `[240, 100, 50]` | node -e |
| 1.29 | `rgb2hsl(0, 0, 0)` | `[0, 0, 0]` | node -e |
| 1.30 | `rgb2hsl(255, 255, 255)` | `[0, 0, 100]` | node -e |
| 1.31 | `rgb2hsl(128, 64, 32)` | `[20, 60, 31.372549019607842]` → `toHslString` = `hsl(20, 60%, 31%)` | node -e |
| 1.32 | `hsl2rgb(0, 100, 50)` | `[255, 0, 0]` | convert.js hsl2rgb |
| 1.33 | `hsl2rgb(120, 100, 50)` | `[0, 255, 0]` | node -e |
| 1.34 | `hsl2rgb(240, 100, 50)` | `[0, 0, 255]` | node -e |
| 1.35 | `hsl2rgb(0, 0, 50)` | `[127.5, 127.5, 127.5]` (exact binary) | node -e |
| 1.36 | `hsl2rgb(0, 0, 0)` | `[0, 0, 0]` | node -e |
| 1.37 | `hsl2rgb(0, 0, 100)` | `[255, 255, 255]` | node -e |
| 1.38 | `hsl2rgb(210, 50, 50)` | `[63.75, 127.5, 191.25]` (exact binary) | node -e |

> The port may expose these as `hsv2rgb : Float -> Float -> Float -> ( Float, Float, Float )`-style
> tuples or 4-element records that *parse* a colour string. Phase 2 records the exact Elm signature;
> the **numbers above are the invariants** regardless of shape.

---

## 2. Parsers — `rgba` / `hsla` / `hsva` (seemly `index.js`)

Exact regex tolerance confirmed by node -e: leading `\s*` and trailing `\s*` around tokens, `,`
separators with optional surrounding spaces, `%` only on hsl/hsv S/L/V groups, **no sign** allowed in
any `float` group (so negative numbers ⇒ whole-string regex miss ⇒ fall-through), hue has **no `deg`**.

### 2a. `rgba(color)` (try-order: `#RRGGBB`→`rgb()`→`rgba()`→`#RGB`→`#RRGGBBAA`→`#RGBA`→named→`hsl/hsla`→`hsv/hsva`→throw)

| # | Input | Expected exact output | Source |
|---|---|---|---|
| 2.1 | `"#AABBCC"` | `[170, 187, 204, 1]` | index.js rgba / node -e |
| 2.2 | `"#abc"` | `[170, 187, 204, 1]` (short expands) | node -e |
| 2.3 | `"#ABCD"` | `[170, 187, 204, 0.87]` (a = roundAlpha(0xDD/255)) | node -e |
| 2.4 | `"#AABBCCDD"` | `[170, 187, 204, 0.87]` | node -e |
| 2.5 | `"#aabbccdd"` | `[170, 187, 204, 0.87]` (case-insensitive hex) | node -e |
| 2.6 | `"#000"` | `[0, 0, 0, 1]` | node -e |
| 2.7 | `"#0000"` | `[0, 0, 0, 0]` | node -e |
| 2.8 | `"#fffF"` | `[255, 255, 255, 1]` | node -e |
| 2.9 | `"rgb(0, 0, 0)"` | `[0, 0, 0, 1]` | node -e |
| 2.10 | `"rgb(255,0,128)"` | `[255, 0, 128, 1]` (no inner spaces ok) | node -e |
| 2.11 | `"rgb( 1 , 2 , 3 )"` | `[1, 2, 3, 1]` (inner spaces ok) | node -e |
| 2.12 | `"rgb(1.9, 2.9, 3.9)"` | `[2, 3, 4, 1]` (roundChannel rounds) | node -e |
| 2.13 | `"rgb(300,0,0)"` | `[255, 0, 0, 1]` (roundChannel clamps to 255) | node -e |
| 2.14 | `"rgba(0, 0, 0, 0.5)"` | `[0, 0, 0, 0.5]` | node -e |
| 2.15 | `"rgba(255, 255, 255, 0.333)"` | `[255, 255, 255, 0.33]` (roundAlpha 2-dp) | node -e |
| 2.16 | `"rgba(208, 48, 80, 1)"` | `[208, 48, 80, 1]` | node -e |
| 2.17 | `"rgba(1,2,3,2)"` | `[1, 2, 3, 1]` (roundAlpha clamps >1→1) | node -e |
| 2.18 | `"rgba(1,2,3,-1)"` | **THROW** (float group forbids `-`) | node -e |
| 2.19 | `"hsl(0, 100%, 50%)"` | `[255, 0, 0, 1]` (via hsl2rgb) | node -e |
| 2.20 | `"hsl(120, 100%, 50%)"` | `[0, 255, 0, 1]` | node -e |
| 2.21 | `"hsl( 30 , 50% , 50% )"` | `[191.25, 127.5, 63.75, 1]` (exact binary) | node -e |
| 2.22 | `"hsl(360, 100%, 50%)"` | `[255, 0, 0, 1]` (roundDeg(360)=0) | node -e |
| 2.23 | `"hsla(0, 100%, 50%, 0.5)"` | `[255, 0, 0, 0.5]` | node -e |
| 2.24 | `"hsla(210, 50%, 50%, 0.25)"` | `[63.75, 127.5, 191.25, 0.25]` | node -e |
| 2.25 | `"hsv(0, 100%, 100%)"` | `[255, 0, 0, 1]` | node -e |
| 2.26 | `"hsv(210, 50%, 50%)"` | `[63.75, 95.625, 127.5, 1]` | node -e |
| 2.27 | `"hsva(210, 50%, 50%, 0.5)"` | `[63.75, 95.625, 127.5, 0.5]` | node -e |
| 2.28 | `"red"` | `[255, 0, 0, 1]` (named map → `#F00`) | node -e |
| 2.29 | `"transparent"` | `[0, 0, 0, 0]` (map `#0000`) | node -e |
| 2.30 | `"fuchsia"` | `[255, 0, 255, 1]` | node -e |
| 2.31 | `"purple"` | `[128, 0, 128, 1]` | node -e |
| 2.32 | `"black"` | `[0, 0, 0, 1]` | node -e |
| 2.33 | `"RED"` | **THROW** (map keys are lowercase) | node -e |
| 2.34 | `"Red"` | **THROW** | node -e |
| 2.35 | `"Fuchsia"` | **THROW** | node -e |
| 2.36 | `"  red  "` | **THROW** (named lookup is exact — no trim) | node -e |
| 2.37 | `"red "` | **THROW** (trailing space breaks named lookup) | node -e |
| 2.38 | `"red  x"` | **THROW** | node -e |
| 2.39 | `"#GGG"` | **THROW** (G not hex) | node -e |
| 2.40 | `"#AB"` | **THROW** (only 3/4/6/8 hex lengths) | node -e |
| 2.41 | `"rgb(1,2)"` | **THROW** (arity mismatch) | node -e |
| 2.42 | `"hsl(1,2)"` | **THROW** | node -e |
| 2.43 | `""` | **THROW** | node -e |

### 2b. `hsla(color)` (hslaRegex, else hslRegex with α=1, else throw)

| # | Input | Expected exact output | Source |
|---|---|---|---|
| 2.44 | `"hsl(0, 100%, 50%)"` | `[0, 100, 50, 1]` | index.js hsla |
| 2.45 | `"hsla(0, 100%, 50%, 0.5)"` | `[0, 100, 50, 0.5]` | node -e |
| 2.46 | `"hsl(360, 100%, 50%)"` | `[0, 100, 50, 1]` (roundDeg(360)=0) | node -e |
| 2.47 | `"hsla(210, 50%, 50%, 0.333)"` | `[210, 50, 50, 0.33]` | node -e |
| 2.48 | `"hsl( 30 , 50% , 50% )"` | `[30, 50, 50, 1]` | node -e |
| 2.49 | `"#AABBCC"` (rgba-only) | **THROW** in `hsla` | index.js hsla try-order |

### 2c. `hsva(color)` (hsvaRegex, else hsvRegex with α=1, else throw)

| # | Input | Expected exact output | Source |
|---|---|---|---|
| 2.50 | `"hsv(0, 100%, 100%)"` | `[0, 100, 100, 1]` | index.js hsva |
| 2.51 | `"hsva(0, 100%, 100%, 0.5)"` | `[0, 100, 100, 0.5]` | node -e |
| 2.52 | `"hsv(360, 100%, 50%)"` | `[0, 100, 50, 1]` | node -e |
| 2.53 | `"hsv( 210 , 50% , 50% )"` | `[210, 50, 50, 1]` | node -e |

> Port mapping note (to confirm Phase 2): the port almost certainly returns `Maybe (Float,Float,Float,Float)`
> (or a `Result`) — invalid inputs map to `Nothing`/`Err`. The **values above are the invariants**; the
> wrapped shape is pinned once the module is read.

---

## 3. Rounders + serializers (seemly `index.js`)

### 3a. Rounders

| # | Call | Expected exact output | Source |
|---|---|---|---|
| 3.1 | `roundDeg(360)` | `0` (wraps!) | index.js roundDeg |
| 3.2 | `roundDeg(359.4)` | `359` | node -e |
| 3.3 | `roundDeg(359.5)` | `0` (rounds to 360 then wraps) | node -e |
| 3.4 | `roundDeg(-5)` | `0` | node -e |
| 3.5 | `roundDeg(720)` | `0` | node -e |
| 3.6 | `roundChannel(255.9)` | `255` | node -e |
| 3.7 | `roundChannel(300)` | `255` | node -e |
| 3.8 | `roundChannel(-3)` | `0` | node -e |
| 3.9 | `roundPercent(100.4)` | `100` | node -e |
| 3.10 | `roundPercent(101)` | `100` | node -e |
| 3.11 | `roundAlpha(0.333)` | `0.33` (2-dp) | index.js roundAlpha |
| 3.12 | `roundAlpha(0.5)` | `0.5` | node -e |
| 3.13 | `roundAlpha(1.5)` | `1` | node -e |
| 3.14 | `roundAlpha(-0.1)` | `0` | node -e |

**Divergence row (documented `[oracle D]`):** `roundDeg(360)` → `0` but `normalizeHue(360)` (utils.ts §4)
→ `359`. The port keeps both (they serve different call sites). Pin both.

### 3b. Serializers (exact `", "` separators; 2-dp α; hex uppercase)

| # | Call | Expected exact output | Source |
|---|---|---|---|
| 3.15 | `toRgbString([255,0,0])` | `"rgb(255, 0, 0)"` | index.js toRgbString |
| 3.16 | `toRgbString([63.75,95.625,127.5])` | `"rgb(64, 96, 128)"` | node -e |
| 3.17 | `toRgbaString([255,0,0,0.333])` | `"rgba(255, 0, 0, 0.33)"` | node -e |
| 3.18 | `toRgbaString([255,0,0])` (len 3) | `"rgba(255, 0, 0, 1)"` | index.js toRgbaString |
| 3.19 | `toRgbaString([63.75,95.625,127.5,0.5])` | `"rgba(64, 96, 128, 0.5)"` | node -e |
| 3.20 | `toHsvString([210,66.66666666666667,75])` | `"hsv(210, 67%, 75%)"` | node -e |
| 3.21 | `toHsvaString([210,66.66666666666667,75,0.5])` | `"hsva(210, 67%, 75%, 0.5)"` | node -e |
| 3.22 | `toHsvaString([0,0,0])` (len 3) | `"hsva(0, 0%, 0%, 1)"` | node -e |
| 3.23 | `toHslString([0,100,50])` | `"hsl(0, 100%, 50%)"` | node -e |
| 3.24 | `toHslaString([0,100,50,0.5])` | `"hsla(0, 100%, 50%, 0.5)"` | node -e |
| 3.25 | `toHslaString([0,100,50])` (len 3) | `"hsla(0, 100%, 50%, 1)"` | node -e |
| 3.26 | `toHexString([255,0,0])` | `"#FF0000"` | node -e |
| 3.27 | `toHexString([170,187,204])` | `"#AABBCC"` | node -e |
| 3.28 | `toHexaString([255,0,0,0.5])` | `"#FF000080"` (α=0.5→roundChannel(127.5)=128) | node -e |
| 3.29 | `toHexaString([255,0,0])` (len 3) | `"#FF0000FF"` | node -e |
| 3.30 | `toHexaString([0,0,0,1])` | `"#000000FF"` | node -e |

### 3c. String-input serializer variants

| # | Call | Expected exact output | Source |
|---|---|---|---|
| 3.31 | `toHexString("#AABBCC")` | `"#AABBCC"` | node -e |
| 3.32 | `toHexString("#AABBCCDD")` | `"#AABBCC"` (slice 0..7) | node -e |
| 3.33 | `toHexString("#ABC")` | `"#AABBCC"` (expand) | node -e |
| 3.34 | `toHexString("#ABCD")` | `"#AABBCC"` (from sHexa) | node -e |
| 3.35 | `toHexaString("#AABBCC")` | `"#AABBCCFF"` | node -e |
| 3.36 | `toHexaString("#AABBCCDD")` | `"#AABBCCDD"` | node -e |
| 3.37 | `toHexaString("#ABC")` | `"#AABBCCFF"` | node -e |
| 3.38 | `toHexaString("#ABCD")` | `"#AABBCCDD"` | node -e |
| 3.39 | `toHexString("red")` | **THROW** (hex strings only) | node -e |
| 3.40 | `toHexaString("rgb(1,2,3)")` | **THROW** | node -e |

---

## 4. `utils.ts` local fns

### 4a. `deriveDefaultValue(modes, showAlpha)` (utils.ts:23)

| # | Input | Expected exact output | Source |
|---|---|---|---|
| 4.1 | `(['hex'], true)` | `"#000000FF"` | utils.ts:23 |
| 4.2 | `(['hex'], false)` | `"#000000"` | node -e |
| 4.3 | `(['rgb'], true)` | `"rgba(0, 0, 0, 1)"` | node -e |
| 4.4 | `(['rgb'], false)` | `"rgb(0, 0, 0)"` | node -e |
| 4.5 | `(['hsl'], true)` | `"hsla(0, 0%, 0%, 1)"` | node -e |
| 4.6 | `(['hsl'], false)` | `"hsl(0, 0%, 0%)"` | node -e |
| 4.7 | `(['hsv'], true)` | `"hsva(0, 0%, 0%, 1)"` | node -e |
| 4.8 | `(['hsv'], false)` | `"hsv(0, 0%, 0%)"` | node -e |
| 4.9 | `(['bogus'], true)` | `"#000000"` (invalid-mode fallback, showAlpha ignored) | node -e |
| 4.10 | `(['hex','rgb'], true)` | `"#000000FF"` (only `modes[0]` matters) | node -e |

### 4b. `getModeFromValue(color)` (utils.ts:44)

| # | Input | Expected exact output | Source |
|---|---|---|---|
| 4.11 | `null` | `null` | utils.ts:44 |
| 4.12 | `"#abc"` | `"hex"` | node -e |
| 4.13 | `"  #abc"` (leading spaces) | `"hex"` (`/^ *#/`) | node -e |
| 4.14 | `"#abc "` (trailing space) | `"hex"` (regex-anchored only at start) | node -e |
| 4.15 | `"rgba(1,2,3,1)"` | `"rgb"` | node -e |
| 4.16 | `"rgb(1,2,3)"` | `"rgb"` | node -e |
| 4.17 | `"hsla(1,2%,3%,1)"` | `"hsl"` | node -e |
| 4.18 | `"hsv(1,2%,3%)"` | `"hsv"` | node -e |
| 4.19 | `"red"` | `null` (no mode keyword) | node -e |
| 4.20 | `"xrgbx"` | `"rgb"` (`includes`, not anchored) | node -e |

### 4c. `normalizeHue` (utils.ts:99) & `normalizeAlpha` (utils.ts:104)

| # | Call | Expected exact output | Source |
|---|---|---|---|
| 4.21 | `normalizeHue(360)` | `359` ⚠️ (clamps, differs from `roundDeg`) | utils.ts:99 |
| 4.22 | `normalizeHue(359.5)` | `359` | node -e |
| 4.23 | `normalizeHue(361)` | `359` | node -e |
| 4.24 | `normalizeHue(-5)` | `0` | node -e |
| 4.25 | `normalizeHue(180)` | `180` | node -e |
| 4.26 | `normalizeAlpha(1.5)` | `1` | utils.ts:104 |
| 4.27 | `normalizeAlpha(0.333)` | `0.33` | node -e |
| 4.28 | `normalizeAlpha(0.999)` | `1` (round to 1.00) | node -e |
| 4.29 | `normalizeAlpha(-0.5)` | `0` | node -e |

### 4d. `getWCAGContrast(hsla, contrastColor=[255,255,255], level='AA')` (utils.ts:58)

`false` means "dark text (black) on this background"; `true` means "white text".

| # | Call (hsla array) | Expected exact output | Source |
|---|---|---|---|
| 4.30 | `[0, 0, 100, 1]` (white bg) | `false` | node -e |
| 4.31 | `[0, 0, 0, 1]` (black bg) | `true` | node -e |
| 4.32 | `[0, 0, 50, 1]` (mid gray) | `false` | node -e |
| 4.33 | `[0, 0, 25, 1]` (dark gray) | `true` | node -e |
| 4.34 | `[0, 100, 50, 1]` (red, a=1) | `false` (contrast ≈ 4.0 < 4.5) | node -e |
| 4.35 | `[240, 100, 25, 1]` (navy) | `true` | node -e |
| 4.36 | `[0, 0, 0, 0]` (a=0 blend → white-ish) | `false` | node -e |
| 4.37 | `[0, 0, 0, 0.8]` (blended alpha path) | `true` | node -e |
| 4.38 | `[0, 0, 0, 0.5]` (blended alpha path) | `false` | node -e |
| 4.39 | `[0, 0, 100, 1]`, contrastColor `[0,0,0]` | `true` (black on white) | node -e |
| 4.40 | `[0, 0, 100, 0.5]`, contrastColor `[0,0,0]` | `true` | node -e |

### 4e. `convertColor(value, mode, originalMode?)` + `convert` table spot-checks (utils.ts:109-199)

| # | Call | Expected exact output | Source |
|---|---|---|---|
| 4.41 | `convertColor("#FF000080","hsv")` | `"hsva(0, 100%, 100%, 0.5)"` | node -e |
| 4.42 | `convertColor("#FF000080","rgb")` | `"rgba(255, 0, 0, 0.5)"` | node -e |
| 4.43 | `convertColor("#FF000080","hsl")` | `"hsla(0, 100%, 50%, 0.5)"` | node -e |
| 4.44 | `convertColor("hsv(210, 50%, 50%)","hex")` | `"#406080FF"` | node -e |
| 4.45 | `convertColor("rgba(208, 48, 80, 1)","hsv")` | `"hsva(348, 77%, 82%, 1)"` | node -e |
| 4.46 | `convertColor("rgba(208, 48, 80, 1)","hex")` | `"#D03050FF"` | node -e |
| 4.47 | `convertColor("hsl(0, 100%, 50%)","rgb")` | `"rgba(255, 0, 0, 1)"` | node -e |
| 4.48 | `convertColor("hsl(210, 50%, 50%)","hsv")` | `"hsva(210, 67%, 75%, 1)"` | node -e |
| 4.49 | `convertColor("hsv(210, 50%, 50%)","hsl")` | `"hsla(210, 33%, 38%, 1)"` | node -e |
| 4.50 | `convertColor("#abc","hex")` (same-mode passthrough) | `"#abc"` (verbatim, unchanged) | utils.ts:172-199 |
| 4.51 | `convertColor("rgb(1, 2, 3)","rgb")` | `"rgb(1, 2, 3)"` (verbatim) | node -e |
| 4.52 | `convertColor("red","hex")` (invalid original → null) | `null` | node -e |

---

## 5. Unit normalizers (`ColorInputUnit.tsx:6-45`)

Regex (`R`): `/^\d{1,3}\.?\d*$/` on `value.trim()`; `parseInt` truncates; outputs `number | false`.

| # | Fn | Input | Expected exact output | Source |
|---|---|---|---|---|
| 5.1 | `normalizeRgbUnit` | `"255.9"` | `255` | ColorInputUnit.tsx:6 |
| 5.2 | `normalizeRgbUnit` | `" 7 "` | `7` (trim + parseInt) | node -e |
| 5.3 | `normalizeRgbUnit` | `"-3"` | **`false`** ⚠️ (minus fails regex — the brief's suspicion was WRONG; `parseInt('-3')` never runs) | node -e |
| 5.4 | `normalizeRgbUnit` | `"1e2"` | `false` | node -e |
| 5.5 | `normalizeRgbUnit` | `"999"` | `255` (clamp) | node -e |
| 5.6 | `normalizeHueUnit` | `"360"` | `360` (hue allows 360 inclusive) | ColorInputUnit.tsx:14 |
| 5.7 | `normalizeHueUnit` | `"361"` | `360` (clamp) | node -e |
| 5.8 | `normalizeHueUnit` | `"359.9"` | `359` | node -e |
| 5.9 | `normalizeHueUnit` | `"-1"` | `false` | node -e |
| 5.10 | `normalizeSlvUnit` | `"100"` | `100` | ColorInputUnit.tsx:22 |
| 5.11 | `normalizeSlvUnit` | `"101"` | `100` | node -e |
| 5.12 | `normalizeSlvUnit` | `"50.5"` | `50` | node -e |
| 5.13 | `normalizeSlvUnit` | `"-5"` | `false` | node -e |
| 5.14 | `normalizeHexaUnit` | `"#ABC"` | `true` | ColorInputUnit.tsx:30 |
| 5.15 | `normalizeHexaUnit` | `"#ABCD"` | `true` | node -e |
| 5.16 | `normalizeHexaUnit` | `"#AABBCC"` | `true` | node -e |
| 5.17 | `normalizeHexaUnit` | `"#AABBCCDD"` | `true` | node -e |
| 5.18 | `normalizeHexaUnit` | `"#AB"` | `false` (len 3 not allowed) | node -e |
| 5.19 | `normalizeHexaUnit` | `"#ABCDE"` | `false` (len 6 not allowed) | node -e |
| 5.20 | `normalizeHexaUnit` | `"#GGG"` | `false` | node -e |
| 5.21 | `normalizeHexaUnit` | `" #ABC "` | `true` (trim) | node -e |
| 5.22 | `normalizeAlphaUnit` | `"100%"` | `1` (parseInt/i100) | ColorInputUnit.tsx:39 |
| 5.23 | `normalizeAlphaUnit` | `"200%"` | **`2`** ⚠️ (clamps to **100** not 1 → 2; serializer would later clamp) | node -e |
| 5.24 | `normalizeAlphaUnit` | `"50.5%"` | `0.5` | node -e |
| 5.25 | `normalizeAlphaUnit` | `"0%"` | `0` | node -e |
| 5.26 | `normalizeAlphaUnit` | `"-1%"` | `false` | node -e |
| 5.27 | `normalizeAlphaUnit` | `"50"` (no `%`) | `false` | node -e |
| 5.28 | `normalizeAlphaUnit` | `"1000%"` | `10` | node -e |

> Port shapes: the normalizers likely return `Maybe Float` (invalid → `Nothing`) or a
> `Result`-style. Phase 2 records the exact Elm encoding; the **values/clamp behaviour above are the invariants**.
> `normalizeHexaUnit` returns `Bool`.

---

## 6. Slider drag geometry (pure given a rect)

Constants: `HANDLE_SIZE = 12`, `RADIUS = 6`. Rect = `{left,width,height,bottom}`; pointer `{x,y}`.

| # | Fn | Rect | Pointer | Expected exact output | Source |
|---|---|---|---|---|---|
| 6.1 | `svFromPoint` | `{left:0,width:200,height:180,bottom:180}` | `{x:0,y:0}` | `(S=0, V=100)` | Pallete.tsx:44-53 |
| 6.2 | `svFromPoint` | same | `{x:200,y:180}` | `(100, 0)` | node -e |
| 6.3 | `svFromPoint` | `{left:10,width:200,height:180,bottom:190}` | `{x:110,y:100}` | `(50, 50)` | node -e |
| 6.4 | `svFromPoint` | `{left:0,width:200,height:180,bottom:180}` | `{x:999,y:-999}` | `(100, 100)` (clamped) | node -e |
| 6.5 | `svFromPoint` | same | `{x:-5,y:999}` | `(0, 0)` (clamped) | node -e |
| 6.6 | `hueFromPoint` | `{left:0,width:200}` | `{x:0}` | `0` (x left of rail-inner → clamp 0) | HueSlider.tsx:40-49 |
| 6.7 | `hueFromPoint` | same | `{x:999}` | `359` (clamped) | node -e |
| 6.8 | `hueFromPoint` | same | `{x:100}` | `180` | node -e |
| 6.9 | `hueFromPoint` | same | `{x:200}` | `359` | node -e |
| 6.10 | `hueFromPoint` | same | `{x:6}` (minus RADIUS) | `0` | node -e |
| 6.11 | `alphaFromPoint` | `{left:0,width:200}` | `{x:0}` | `0` | AlphaSlider.tsx:42-49 |
| 6.12 | `alphaFromPoint` | same | `{x:999}` | `1` (clamped) | node -e |
| 6.13 | `alphaFromPoint` | same | `{x:97}` | `0.52` (round 2-dp) | node -e |

> Formula refs (exact): `svFromPoint: S=100*clamp01((x-left)/width), V=100*clamp01((bottom-y)/height)`;
> `hueFromPoint: normalizeHue(((x-left-6)/(width-12))*360)`; `alphaFromPoint: normalizeAlpha((x-left)/(width-12))`.

---

## 7. `nextDisplayedMode` (cyclic advance; `handleUpdateDisplayedMode` ColorPicker.tsx:238-250)

Rule: index of `mode` in `modes`; if found → `modes[(i+1) % length]`; else `'rgb'` (NOT `modes[0]`).

| # | `modes` | `mode` | Expected exact output | Source |
|---|---|---|---|---|
| 7.1 | `['rgb','hex','hsl']` | `'rgb'` | `'hex'` | ColorPicker.tsx:238-250 |
| 7.2 | same | `'hex'` | `'hsl'` | node -e |
| 7.3 | same | `'hsl'` | `'rgb'` (wraps) | node -e |
| 7.4 | same | `'hsv'` (not in list) | `'rgb'` (fallback) | node -e |
| 7.5 | `['hex']` | `'hex'` (single) | `'hex'` (self) | node -e |
| 7.6 | `[]` | `'rgb'` (empty) | `'rgb'` (fallback) | node -e |

---

## 8. DOM expectations (from upstream trees §3.2/3.3/5.1)

### 8a. Trigger tree (`ColorPickerTrigger.tsx:31-66`)

```
div.n-color-picker [.n-color-picker--disabled]   style = 10 cssVars; onClick unless disabled
└─ div.n-color-picker__fill
   ├─ div.n-color-picker-checkboard
   ├─ div (absolute; backgroundColor = hsla ? toHslaString(hsla) : '')   // NO class
   └─ div.n-color-picker__value   (only when value && hsla)
         style color = getWCAGContrast(hsla) ? 'white' : 'black'
         text = renderLabel(value) || value
```

- Class order on trigger root: `n-color-picker` then `n-color-picker--disabled` when disabled.
- `--disabled` present ⟺ `disabled`; when present the click handler is absent (`onClick=undefined`).

### 8b. 10-var ORDER — `cssVarsRef` (ColorPicker.tsx:546-576), EXACT string sequence

```
--n-bezier, --n-text-color, --n-color, --n-panel-font-size, --n-font-size,
--n-box-shadow, --n-border, --n-border-radius, --n-height, --n-divider-color
```

- Applied to **BOTH** trigger root and panel root (`check-dom` targets `.n-color-picker:true` **and**
  `.n-color-picker-panel:true`).
- `--n-font-size` = `fontSize<Size>`; `--n-height` = `height<Size>` (Trigger bind; panel font size is
  size-independent via `--n-panel-font-size`). `--n-border` is emitted despite the cssr header comment
  omitting it (documented `[oracle D]`).
- Sizes → var picks: `small`→`heightSmall`/`fontSizeSmall`; `medium`→`heightMedium`/`fontSizeMedium`;
  `large`→`heightLarge`/`fontSizeLarge`.

### 8c. Panel tree (`renderPanel` ColorPicker.tsx:586-728)

```
div.n-color-picker-panel   style = 10 cssVars; onDragstart preventDefault; + fade-in-scale-up-transition class when Just phase
└─ div.n-color-picker-control
   ├─ div.n-color-picker-pallete
   │  ├─ div.n-color-picker-pallete__layer                       bg linear-gradient(90deg, white, hsl(H,100%,50%))
   │  ├─ div.n-color-picker-pallete__layer.n-color-picker-pallete__layer--shadowed   bg linear-gradient(180deg, rgba(0,0,0,0%), rgba(0,0,0,100%))
   │  └─ div.n-color-picker-handle (when rgba)                   left calc(S% - 6px) bottom calc(V% - 6px)
   │     └─ div.n-color-picker-handle__fill                       bg rgb(R, G, B)
   ├─ div.n-color-picker-preview
   │  ├─ div.n-color-picker-preview__sliders
   │  │  ├─ div.n-color-picker-slider   (HueSlider)  rail gradient const; handle left calc((H%) / 359 * 100 - 6px)
   │  │  │  └─ div.n-color-picker-handle > div.n-color-picker-handle__fill  bg hsl(H, 100%, 50%)
   │  │  └─ div.n-color-picker-slider?  (AlphaSlider, when showAlpha)  checkboard + div.n-color-picker-slider__image + handle left calc(α*100% - 6px)
   │  └─ div.n-color-picker-preview__preview?  (when showPreview)
   │     ├─ span.n-color-picker-preview__fill   bg color || '#000000'
   │     └─ input.n-color-picker-preview__input[type=color]  value=color
   ├─ div.n-color-picker-input
   │  ├─ div.n-color-picker-input__mode   text = MODE.toUpperCase() + (showAlpha?'A':'')   cursor pointer iff modes.length>1
   │  └─ div.n-input-group   (NInputGroup)  children = small NInput unit(s)  (hex → 1 "HEX" unit; else one per char of mode+(showAlpha?'a':''))
   └─ div.n-color-picker-swatches?  (when swatches?.length)
      └─ div.n-color-picker-swatch[tabindex=0]  (per swatch)
         └─ div.n-color-picker-swatch__fill   background = legalValue
div.n-color-picker-action?  (when actions?.length)   flex, border-top 1px solid var(--n-divider-color), justify-content flex-end
   ├─ NButton(confirm)   when actions.includes('confirm')
   └─ NButton(clear)     when actions.includes('clear'); disabled when !value
div.n-color-picker-action?  (separate row; slots.action OR internalActions present)
   └─ NButton(undo) + NButton(redo)   OR custom slot node
```

### 8d. Panel/trigger handle `calc()` strings (exact)

| Element | `left`/`bottom` | Source |
|---|---|---|
| panel pallete handle | `left: calc(S% - 6px)`, `bottom: calc(V% - 6px)` | Pallete.tsx render |
| hue slider handle | `left: calc((H%) / 359 * 100 - 6px)` | HueSlider.tsx render |
| alpha slider handle | `left: calc(α*100% - 6px)` | AlphaSlider.tsx render |

### 8e. WCAG label-colour cases (trigger `__value`)

| colour value | `getWCAGContrast` | `__value` style color |
|---|---|---|
| `#000000` (black) | `true` | `white` |
| `#ffffff` (white) | `false` | `black` |
| `#ff0000` (red) | `false` | `black` |
| `rgba(0,0,0,0.5)` | `false` | `black` |

### 8f. Mode-label text

| mode | showAlpha | `__mode` text |
|---|---|---|
| `rgb` | true | `RGBA` |
| `rgb` | false | `RGB` |
| `hex` | true | `HEXA` |
| `hsl` | false | `HSL` |
| `hsv` | true | `HSVA` |

### 8g. cssr class inventory (upstream `styles/index.cssr.ts`)

Styled BEM roots/elems: `n-color-picker-panel`, `n-color-picker-checkboard`,
`n-color-picker-slider`(+`__image`), `n-color-picker-handle`(+`__fill`),
`n-color-picker-pallete`(+`__layer`,`__layer--shadowed`), `n-color-picker-preview`(+`__sliders`,`__preview`,`__fill`,`__input`),
`n-color-picker-input`(+`__mode`), `n-color-picker-control`, `n-color-picker-action`,
`n-color-picker`(+`--disabled`,`__value`,`__fill`), `n-color-picker-swatches`, `n-color-picker-swatch`(+`__fill`).
`check-classes` ALLOW expected: **NONE** needed (all emitted classes have a cssr rule).

---

## Port-mapped shapes (Phase 2 — port read AFTER this doc was written)

Read `src/NUI/ColorPicker.elm` + `src/NUI/Internal/Color.elm` only after the table above was
complete. The public module exposes exactly the eq-pin surface the brief named:

| Public (eq-pinned) | Elm signature |
|---|---|
| `convertColor` | `String -> Mode -> Maybe Mode -> Maybe String` |
| `deriveDefaultValue` | `List Mode -> Bool -> String` |
| `getModeFromValue` | `Maybe String -> Maybe Mode` |
| `getWCAGContrast` | `HSLA -> Bool` (`HSLA = { h, s, l, a }`) |
| `normalizeHue` | `Float -> Int` |
| `normalizeAlpha` | `Float -> Float` |
| `normalizeRgbUnit` / `normalizeHueUnit` / `normalizeSlvUnit` | `String -> Maybe Int` |
| `normalizeHexaUnit` | `String -> Bool` |
| `normalizeAlphaUnit` | `String -> Maybe Float` |
| `svFromPoint` | `{ width, height, left, bottom } -> { x, y } -> { s, v }` |
| `hueFromPoint` | `{ width, left } -> Float -> Int` |
| `alphaFromPoint` | `{ width, left } -> Float -> Float` |
| `nextDisplayedMode` | `List Mode -> Mode -> Mode` |

Invalid parses map to `Nothing` (the engine's `rgba`/`hsla`/`hsva` return `Result String _`;
`convertColor`/the normalizers collapse with `Result.toMaybe`). The seemly throws in §2/§3c and the
`toHex{,a}String(string)` overloads are **unexposed internals**.

### Coverage decision (brief rule: eq-pin only `NUI.ColorPicker.*`)

Eq pins use **only** the public surface above (111 pins). The engine is therefore exercised
transitively:

  - `convertColor` reaches **all 6 conversions** (hsl→rgb / hsl→hsv / hsv→hex+rgb / hsv→hsl /
    hex→hsl / hex→hsv), all 4 parsers (hex/rgb/rgba/hsl/hsla/hsv/hsva/named), and the serializers
    (`toHexaString`, `toRgbaString`, `toHslaString`, `toHsvaString`) — so §1, §2 and the §3
    serializers are covered *through* the public API rather than dropped.
  - §3 direct rounder/raw-conversion pins that have **no** public doorway and get **dropped
    with a note** per the brief: raw unrounded `*2*` outputs, `roundChannel`/`roundPercent`/
    `roundAlpha` standalone, and the `toHexString(string)` / `toHexaString(string)` overloads
    (`hexStringToHex`/`hexStringToHexa`). The `roundDeg(360)→0` vs `normalizeHue(360)→359`
    divergence *is* covered via `convertColor "hsl(360, 100%, 50%)"`.
  - §8 DOM expectations are covered by the 35 DOM probes below.

**Correction to the brief's Phase-1 example:** `hsv2rgb(0, 0, 100)` is `[255, 255, 255]` (white),
**not** `[255, 0, 0]` — the brief's illustrative pair was wrong; the table above records the real
value (still exercised via `convertColor "hsv(0, 0%, 100%)"`).

### Tests written (Phase 2)

- `tests/src/Main.elm`: import `NUI.ColorPicker as ColorPicker`; **111** `eq` pins under a
  `-- COLOR-PICKER` banner before the `checks` list close.
- `tests/inspect.mjs`: **35** DOM probes (`dEq`/`dTrue` via `nClassesStr`/`varOrder`/`countVars`/
  `styleAt`/`fullClasses`) inserted before `// --- report ---`, driven by 8 `#live-color-picker*`
  fixtures in `tests/src/Main.elm` `liveNodes` (trigger basic/dark/disabled/small/large + panel
  comprehensive/noalpha/transition).
- `elm-format --validate tests/src/Main.elm` clean.

## FAILURES

**None.** `ELM_HOME=/tmp/elm-home bash tests/run.sh` → **3717 assertions — 3717 passed, 0 failed**
(`#results data-total=2271 data-failures=0`). Baseline was 3571 (Elm 2160 + DOM 1411); +111 eq pins
+ 35 DOM probes = 3717. Every Phase-1 expectation reproduced by the port; no `normalizeHue`,
`getWCAGContrast`, `convertColor`, normalizer, geometry or DOM divergence found.

