# color-picker-1-upstream.md — naive-ui v2.45.3 `ColorPicker` upstream map

Read-only recon. Upstream: `/home/titan/Works/elm/naive-ui` (naive-ui v2.45.3).
**Citation base** = `src/color-picker/src/` unless the path is written out in full. Line counts
verified by `wc -l` (ColorPicker.tsx 839, utils.ts 200, index.cssr.ts 243, etc.).

> **Seemly note.** naive-ui's color math is *not* local — it imports `seemly@^0.3.10`
> (`package.json:92`). `node_modules/` is **absent** from this tree, so §4.1–4.3 record the
> extracted behaviour of the **published `seemly@0.3.10`** (`lib/color/{convert,index,colors}.js`,
> fetched from the npm registry; also `lib/dom/get-precise-event-target.js`). These are the
> authoritative bytes for the eq-pin targets. Any Elm colour primitive must reproduce them exactly.

---

## 1. File inventory

### 1.1 `src/color-picker/` (this component)

| File | Lines | Role |
| --- | --- | --- |
| `index.ts` | 3 | public re-export of `NColorPicker`, `colorPickerProps`, types |
| `src/ColorPicker.tsx` | 839 | root component: props, state, conversions, panel render, binder/trigger mount |
| `src/ColorPickerTrigger.tsx` | 70 | default trigger (`div.n-color-picker`) with checkboard + value label |
| `src/Pallete.tsx` | 117 | 2-D S/V pick square (mouse drag) |
| `src/HueSlider.tsx` | 115 | hue rail (mouse drag) |
| `src/AlphaSlider.tsx` | 131 | alpha rail (mouse drag, shows checkboard) |
| `src/ColorPreview.tsx` | 63 | circular preview + hidden native `<input type="color">` |
| `src/ColorInput.tsx` | 156 | mode label + numeric unit inputs (wraps `NInputGroup`) |
| `src/ColorInputUnit.tsx` | 166 | one `NInput` unit + per-label normalization |
| `src/ColorPickerSwatches.tsx` | 129 | preset swatch grid |
| `src/context.ts` | 12 | injection key (theme + slots + renderLabel) |
| `src/interface.ts` | 9 | callback/`RenderLabel` types |
| `src/public-types.ts` | 1 | `ColorPickerSize = 'small'\|'medium'\|'large'` |
| `src/utils.ts` | 200 | **all local pure colour logic** (derivation, mode detect, WCAG, normalize, convert table) |
| `src/styles/index.cssr.ts` | 243 | cssr rules + the component's own var declarations |
| `styles/light.ts` | 66 | `self()` theme vars + `createTheme` (peers Input/Button) |
| `styles/dark.ts` | 17 | dark theme (same `self`, `commonDark`, dark peers) |
| `styles/index.ts` | 7 | theme re-exports |
| `demos/enUS/*` | 10 demos + entry | enUS demos |
| `demos/zhCN/*` | 11 demos + entry | zhCN demos (adds `close-debug.vue`) |
| `tests/ColorPicker.spec.tsx` | 286 | DOM behaviour tests |
| `tests/server.spec.tsx` | 20 | SSR smoke test |

No other `src/color-picker` sub-directories exist beyond `src/styles/` and `demos/`.
`floor()` (`utils.ts:95`) is exported but **unused** inside the component — dead export.

---

## 2. Public API

### 2.1 Props (`colorPickerProps`, `ColorPicker.tsx:88-138`; `...useTheme.props` adds
`theme`/`themeOverrides`)

| Prop | Type | Default | Line | Trigger-only / Panel-only / Both |
| --- | --- | --- | --- | --- |
| `value` | `string \| null` | `undefined` (uncontrolled) | 93 | **both** (trigger label + panel body) |
| `show` | `boolean \| undefined` | `undefined` | 94-97 | both (gates panel mount) |
| `defaultShow` | `boolean` | `false` | 98 | uncontrolled seed for `show` |
| `defaultValue` | `string \| null` | derived (see 4.4) | 99 | uncontrolled seed for `value` |
| `modes` | `ColorPickerMode[]` = `('rgb'\|'hex'\|'hsl'\|'hsv')[]` | `['rgb','hex','hsl']` | 100-104 | both (mode label + serialization) |
| `placement` | `FollowerPlacement` (12 values) | `'bottom-start'` | 105-108 | panel placement |
| `to` | `string \| HTMLElement \| boolean` | `undefined` → `'body'` | 109 | panel teleport target |
| `showAlpha` | `boolean` | `true` | 110-113 | **panel** (alpha rail/units/serialization) |
| `showPreview` | `boolean` | `false` | 114 | **panel** |
| `swatches` | `string[]` | `undefined` | 115 | **panel** |
| `disabled` | `boolean \| undefined` | `undefined` | 116-119 | **trigger** (class + click gate; merged with form) |
| `actions` | `('confirm'\|'clear')[] \| null` | `null` | 120-123 | **panel** (action row) |
| `internalActions` | `ReadonlyArray<'redo'\|'undo'>` | — | 124 | **panel** (undo/redo row) |
| `size` | `ColorPickerSize` | resolved → `'medium'` | 125 | **trigger** height/font; panel font is size-independent |
| `renderLabel` | `(color: string\|null) => VNodeChild` | `undefined` | 126 | **trigger** label |
| `onComplete` | `(value: string) => void` | `undefined` | 127 | both (commit after drag / input) |
| `onConfirm` | `(value: string) => void` | `undefined` | 128 | panel (confirm button) |
| `onClear` | `() => void` | `undefined` | 129 | panel (clear button) |
| `onUpdate:show` \| `onUpdateShow` | `MaybeArray<(b:boolean)=>void>` | — | 130-135 | both |
| `onUpdate:value` \| `onUpdateValue` | `MaybeArray<(v:string\|null)=>void>` | — | 136-137 | both |

Controlled/uncontrolled pairs: **`value`↔`defaultValue`** and **`show`↔`defaultShow`**
(`useMergedState`, `ColorPicker.tsx:203-207, 218-224`). There is **no** `default-*` for
swatches/modes.

### 2.2 Slots (`ColorPickerSlots`, `ColorPicker.tsx:141-152`)

| Slot | Params | Used by |
| --- | --- | --- |
| `trigger` | `{ value, onClick, ref }` | replaces default trigger; receives merged attrs/ref/onClick (render `~line 800`) |
| `label` | `(color: string \| null)` | trigger label; preferred over `renderLabel` (`ColorPickerTrigger.tsx:34`) |
| `action` | `()` | panel: replaces the whole action row (incl. internalActions) |
| `default` | `()` | **declared but never read** in render (unused) |

### 2.3 Emits — all dispatched through `call(...)` (arrays allowed)

`onUpdate:value`/`onUpdateValue` (every change: drag **and** input), `onComplete` (commit after
mouse-up or after input `nextTick`), `onConfirm`, `onClear`, `onUpdate:show`/`onUpdateShow`.
Form integration fires `nTriggerFormChange`/`nTriggerFormInput` in `doUpdateValue` and
`handleComplete` (`ColorPicker.tsx:446-447, 471-473`).

---

## 3. Component tree & mount model

### 3.1 Mount model (`ColorPicker.tsx` render, `~766-838`)

```
VBinder
├─ VTarget → trigger slot OR <ColorPickerTrigger {...triggerProps}>   // triggerProps = merged $attrs + ref + value + style:cssVars + class:themeClass
└─ VFollower (placement, show=mergedShow, containerClass=namespace,
             teleportDisabled = adjustedTo===tdkey, to=adjustedTo)
   └─ Transition name="fade-in-scale-up-transition" appear=isMounted
      └─ show ? withDirectives(<renderPanel/>, [ [clickoutside, handleClickOutside, undefined, {capture:true}] ]) : null
```

`to`/`adjustedTo` = `useAdjustedTo(props)` (`_utils/composable/use-adjusted-to.ts:23`):
`false`→teleport disabled ("stay in place"), `true`/undefined→`document.fullscreenElement || 'body'`;
if absent inside Modal/Drawer/Popover/SelectMenu it inherits that body. Default ends up `'body'`.

- **No `focusDetector` sentinel**, **no focus trap**, **no arrow-key navigation**. Panel close is
  driven purely by `clickoutside` in **capture** phase (`handleClickOutside`, `ColorPicker.tsx:745-759`)
  which ignores clicks whose `getPreciseEventTarget` is inside the trigger el (`triggerRef`).
- `onDragstart` on the panel calls `e.preventDefault()` (`renderPanel`, ~`598`).
- Native drag: each slider/palette registers `on('mousemove'|'mouseup', document, …)` on
  `mousedown` and removes on `mouseup` (`Pallete.tsx:37-58`, `HueSlider.tsx:33-53`,
  `AlphaSlider.tsx:35-53`) — i.e. plain document-level mouse events, no Pointer Events.

### 3.2 Panel tree (`renderPanel`, `ColorPicker.tsx:586-728`)

```
div.n-color-picker-panel [themeClass] style=cssVars (onDragstart preventDefault)
├─ div.n-color-picker-control
│  ├─ Pallete → div.n-color-picker-pallete
│  │            ├─ div.n-color-picker-pallete__layer                       (bg: linear-gradient(90deg, white, hsl(H,100%,50%)))
│  │            ├─ div.n-color-picker-pallete__layer.n-color-picker-pallete__layer--shadowed (bg: linear-gradient(180deg, rgba(0,0,0,0%), rgba(0,0,0,100%)))
│  │            └─ div.n-color-picker-handle (if rgba) → …handle__fill (bg rgb(R,G,B))   // left/bottom = calc(S% - 6px), calc(V% - 6px); 12px, radius 6px
│  ├─ div.n-color-picker-preview
│  │  ├─ div.n-color-picker-preview__sliders
│  │  │  ├─ HueSlider → div.n-color-picker-slider (fixed GRADIENT rail) → handle (left calc((H%)/359*100 - 6px))
│  │  │  └─ AlphaSlider? (showAlpha) → div.n-color-picker-slider → checkboard + __image (linear-gradient rgba(R,G,B,0)→rgba(R,G,B,1)) + handle
│  │  └─ ColorPreview? (showPreview) → div.n-color-picker-preview__preview → span.n-color-picker-preview__fill + input.n-color-picker-preview__input[type=color]
│  ├─ ColorInput → div.n-color-picker-input
│  │  ├─ div.n-color-picker-input__mode  (text = MODE.toUpperCase() + (showAlpha?'A':''))
│  │  └─ NInputGroup → div.n-input-group → NInput unit(s) (size small, placeholder=label, padding '0 4px')
│  └─ ColorPickerSwatches? (swatches?.length) → div.n-color-picker-swatches → per swatch div.n-color-picker-swatch[tabindex=0] → div.n-color-picker-swatch__fill
├─ div.n-color-picker-action? (actions?.length)  → NButton (confirm?) + NButton (clear?)   // clear disabled when !value
└─ div.n-color-picker-action? (slots.action | internalActions) → custom slot OR NButton(undo)+NButton(redo)
```

Both `actions` and `internalActions`/`action`-slot produce **separate** `.n-color-picker-action`
rows (two rows when both present).

- **Modes**: single colour value only. **No gradient** colour support (all `gradient` mentions are
  CSS backgrounds — `HueSlider.tsx:11`, `index.cssr.ts`). Alpha is optional via `showAlpha`.
  Swatches and 3 sizes exist.
- **Internal reactive state** (`ColorPicker.tsx:322-324`): `displayedHueRef=0`,
  `displayedAlphaRef=1`, `displayedSvRef=[0,0]`.
- **Derived colour arrays**: `hsvaRef`/`rgbaRef`/`hslaRef` (`259-309`) each switch on
  `valueModeRef = getModeFromValue(value)` and convert between spaces via seemly.
  ⚠️ If `getModeFromValue` returns `null` (e.g. `value='red'`), the `switch` matches nothing →
  **all three return `undefined`** (not `null`); the panel then renders no handle / empty trigger
  label. Only the 4 mode strings are supported inputs.
- **Resync rule** (`watchEffect`, `531-545`): when the value changed from a non-cursor source, the
  displayed H/α/SV snap to `hsvaRef`; a `'cursor'` update sets `upcomingValue` and is *not*
  overridden (uncontrolled-mode support). `upcomingValue` resets to `null` each run.
- **Displayed-mode cycling** (`handleUpdateDisplayedMode`, `238-250`): on mode-label click, advance
  to the next entry of `modes` (cyclic); if current mode isn't in `modes`, fall back to `'rgb'`.
- **Undo/redo** (`482-499`, `518-523`): stack seeded `[value]`; `handleComplete(pushStack)` splices
  the stack; `watch(mergedShow)` resets stack to `[value]` and index 0 when the panel closes
  (`524-530`). `undoable = index>=1`; `redoable = stack.length>1 && index<stack.length-1`.

### 3.3 Trigger tree (`ColorPickerTrigger.tsx:31-66`)

```
div.n-color-picker [.n-color-picker--disabled]  (onClick unless disabled)   // + merged $attrs (style/cssVars/themeClass)
└─ div.n-color-picker__fill
   ├─ div.n-color-picker-checkboard
   ├─ div (absolute) style backgroundColor = hsla ? toHslaString(hsla) : ''
   └─ div.n-color-picker__value? (value && hsla)  color = getWCAGContrast(hsla) ? 'white' : 'black'
```

`renderLabel = slots.label || renderLabelRef.value` (`ColorPickerTrigger.tsx:34`); label text falls
back to raw `value`.

### 3.4 Size resolution

`formItem.mergedSize` (`ColorPicker.tsx:163-187`): `props.size` → else FormItem size → else
config `mergedComponentProps.ColorPicker.size` → else `'medium'`. Disabled = `props.disabled` OR
form disabled.

---

## 4. Pure functions (the important part)

### 4.1 seemly conversion primitives — `seemly@0.3.10 lib/color/convert.js` (exact)

All take/return **unrounded floats** (clamping happens only at serialization).

```
hsl2hsv(h,s,l): s/=100; l/=100; const v = s*min(l,1-l)+l;  return [h, v ? (2-(2*l)/v)*100 : 0, v*100]
hsv2hsl(h,s,v): s/=100; v/=100; const l = v-(v*s)/2; const m = min(l,1-l); return [h, m ? ((v-l)/m)*100 : 0, l*100]
hsv2rgb(h,s,v): s/=100; v/=100; f=(n,k=(n+h/60)%6)=>v-v*s*max(min(k,4-k,1),0); return [f(5)*255, f(3)*255, f(1)*255]
rgb2hsv(r,g,b): r,g,b /=255; v=max; c=v-min; h=c&&(v==r?(g-b)/c : v==g?2+(b-r)/c : 4+(r-g)/c);
                return [60*(h<0?h+6:h), v?(c/v)*100:0, v*100]
rgb2hsl(r,g,b): r,g,b /=255; v=max; c=v-min; f=1-abs(2v-c-1); h = same ternary;
                return [60*(h<0?h+6:h), f?(c/f)*100:0, (2v-c)*50]
hsl2rgb(h,s,l): s/=100; l/=100; a=s*min(l,1-l); f=(n,k=(n+h/30)%12)=>l-a*max(min(k-3,9-k,1),-1);
                return [f(0)*255, f(8)*255, f(4)*255]
```

(`%` is JS remainder → can be negative for the `k` defaults; ranges are only ever entered with
non-negative inputs in practice.)

### 4.2 seemly parsing — `lib/color/index.js` (regex constants at top)

```
prefix='^\s*'; suffix='\s*$'
percent='\s*((\.\d+)|(\d+(\.\d*)?))%\s*'      // 4 capture groups (whole, .d+, \d+(\.\d*)?, \.\d*)
float  ='\s*((\.\d+)|(\d+(\.\d*)?))\s*'        // 4 groups
hex='([0-9A-Fa-f])'; dhex='([0-9A-Fa-f]{2})'
hsl  =^…hsl\s*\(  FLOAT , PERCENT , PERCENT                \)…$
hsla =^…hsla\s*\( FLOAT , PERCENT , PERCENT , FLOAT        \)…$
hsv  =^…hsv\s*\(  FLOAT , PERCENT , PERCENT                \)…$
hsva =^…hsva\s*\( FLOAT , PERCENT , PERCENT , FLOAT        \)…$
rgb  =^…rgb\s*\(  FLOAT , FLOAT , FLOAT                    \)…$
rgba =^…rgba\s*\( FLOAT , FLOAT , FLOAT , FLOAT            \)…$
sHex =^…# HEX HEX HEX …$                  hex =^…# dHEX dHEX dHEX …$
sHexa=^…# HEX HEX HEX HEX …$              hexa=^…# dHEX dHEX dHEX dHEX …$
```

`hsla(color)`  → `hslaRegex` first, else `hslRegex` (α=1), else **throw**; fields
`[roundDeg(i[1]), roundPercent(i[5]), roundPercent(i[9]), roundAlpha(i[13])]`.
`hsva(color)` identical with hsv.
`rgba(color)` try-order:
`hex(#RRGGBB)`→`rgb(...)`→`rgba(...)`→`sHex(#RGB)`→`hexa(#RRGGBBAA)`→`sHexa(#RGBA)`→
**named-colour map** (148 entries incl. `transparent:'#0000'`, `red:'#F00'`; `lib/color/colors.js`)
→ `hsl/hsla` → `hsv/hsva` → else **throw**.
- `#RRGGBB` → α=1. `#RRGGBBAA` → α=`roundAlpha(0xAA/255)`. Short `#RGB`/`#RGBA` expand.
- Named colours recurse through `rgba()`. `parseHex` = `parseInt(v,16)`; short hex duplicates each nibble.
- No `%` allowed in rgb()/rgba() channels; hue has no `deg` suffix; only `,`+optional-space separators.

### 4.3 seemly rounding + serialization — `lib/color/index.js` (exact)

```
roundChannel(v): v=Math.round(Number(v)); v>255→255; v<0→0; else v        // 0..255
roundPercent(v): v=Math.round(Number(v)); v>100→100; v<0→0; else v        // 0..100
roundDeg(v)    : v=Math.round(Number(v)); v>=360→0;  v<0→0;  else v        // wraps 360→0 (NOT 359)
roundAlpha(v)  : v=Math.round(Number(v)*100)/100; v>1→1; v<0→0; else v     // 0..1, 2-dp
toRgbString  [r,g,b]        => `rgb(${roundChannel(r)}, ${roundChannel(g)}, ${roundChannel(b)})`
toRgbaString base            => 3 in base ? `rgba(${rc(r)}, ${rc(g)}, ${rc(b)}, ${roundAlpha(base[3])})` : `rgba(…, …, …, 1)`
toHsvString  [h,s,v]        => `hsv(${roundDeg(h)}, ${roundPercent(s)}%, ${roundPercent(v)}%)`
toHsvaString base            => 3 in base ? `hsva(${roundDeg(h)}, ${roundPercent(s)}%, ${roundPercent(v)}%, ${roundAlpha(base[3])})` : `hsva(…, …%, …%, 1)`
toHslString  [h,s,l]        => `hsl(${roundDeg(h)}, ${roundPercent(s)}%, ${roundPercent(l)}%)`
toHslaString base            => 3 in base ? `hsla(${roundDeg(h)}, ${roundPercent(s)}%, ${roundPercent(l)}%, ${roundAlpha(base[3])})` : `hsla(…, …%, …%, 1)`
toHexString(array)          => `#` + first 3 × roundChannel(x).toString(16).toUpperCase().padStart(2,'0')
toHexaString(array)         => toHexString-like + α: base.length===3 ? 'FF' : roundChannel(base[3]*255).toString(16).padStart(2,'0').toUpperCase()
```
`toHexString(string)` / `toHexaString(string)` accept **hex strings only** (hexRegex/hexaRegex/sHex/
sHexa; `#RRGGBB`→append `FF` for Hexa; `#RRGGBBAA`→slice(0,7) for Hex) and throw otherwise.
Separators everywhere are `", "`; alpha is emitted un-percented (`roundAlpha`).

`getPreciseEventTarget(event) = event.composedPath()[0] || null` (`lib/dom/get-precise-event-target.js`).

### 4.4 local pure logic — `utils.ts`

| Fn | Line | Exact behaviour (eq-pin targets) |
| --- | --- | --- |
| `deriveDefaultValue(modes, showAlpha)` | 23 | `modes[0]`: `hex`→`showAlpha?'#000000FF':'#000000'`; `rgb`→`'rgba(0, 0, 0, 1)'`/`'rgb(0, 0, 0)'`; `hsl`→`'hsla(0, 0%, 0%, 1)'`/`'hsl(0, 0%, 0%)'`; `hsv`→`'hsva(0, 0%, 0%, 1)'`/`'hsv(0, 0%, 0%)'`; otherwise (invalid mode) `'#000000'` |
| `getModeFromValue(color)` | 44 | `null`→`null`; `/^ *#/`→`'hex'` (leading ws allowed, trailing not); `includes('rgb')`→`'rgb'`; `includes('hsl')`→`'hsl'`; `includes('hsv')`→`'hsv'`; else `null`. Order matters: `rgba→rgb`, `hsla→hsl`, `hsva→hsv`. |
| `getWCAGContrast(hsla, contrastColor=[255,255,255], level='AA')` | 58 | `[r,g,b,a]=rgba(toHslaString(hsla))`; if `a===1`: contrast = `(max(L1,L2)+.05)/(min(L1,L2)+.05) >= (AA?4.5:7)`. else blend each channel `round(r*a + cc*(1-a))`, compare vs `contrastColor`. |
| `rgb2luminance(rgb)` (internal) | 87 | per ch: `c/=255; c = c<=0.03928 ? c/12.92 : ((c+0.055)/1.055)**2.4`; `0.2126*cr+0.7152*cg+0.0722*cb` |
| `floor(color[])` | 95 | `map(Math.floor)` — **unused** |
| `normalizeHue(hue)` | 99 | `hue=Math.round(hue); >=360→359; <0→0`. ⚠️ clamps to **359**, differs from seemly `roundDeg` (360→0) |
| `normalizeAlpha(alpha)` | 104 | `alpha=Math.round(alpha*100)/100; >1→1; <0→0` |
| `convert` table | 109-170 | `convert[orig][target](value)` for each ordered pair of the 4 modes; every target is a `to*String` round-trip via `rgba`/`hsla`/`hsva`. |
| `convertColor(value, mode, originalMode?)` | 172-199 | `originalMode ??= getModeFromValue(value)`; `null`→`null`; if `originalMode===mode` return value unchanged; else `convert[originalMode][mode](value)`. |

`convertColor` used by `ColorPickerSwatches.tsx:87` and `ColorPreview.tsx:35`; `getWCAGContrast`
by `ColorPickerTrigger.tsx:59`.

### 4.5 input-unit normalizers — `ColorInputUnit.tsx` (all local, DOM-independent)

```
normalizeRgbUnit(v)  : /^\d{1,3}\.?\d*$/.test(v.trim()) ? max(0,min(parseInt(v),255)) : false
normalizeHueUnit(v)  : same regex            ? max(0,min(parseInt(v),360)) : false     // 0..360 inclusive
normalizeSlvUnit(v)  : same regex            ? max(0,min(parseInt(v),100)) : false
normalizeHexaUnit(v) : /^#[0-9a-fA-F]+$/.test(v.trim()) && [4,5,7,9].includes(v.trim().length)
normalizeAlphaUnit(v): /^\d{1,3}\.?\d*%$/.test(v.trim()) ? max(0,min(parseInt(v)/100,100)) : false
```
Notes: `parseInt` truncates decimals; regex allows up to 3 integer digits. `normalizeAlphaUnit`
upper-clamps to **100** (not 1) → e.g. `'200%'` yields `2` (serializer then clamps). `getInputString`
(`73-85`): `HEX`→value verbatim; `A`→`${Math.floor(value*100)}%`; else `String(Math.floor(value))`.

### 4.6 slider drag math (pure given geometry) — local

```
Pallete.handleMouseMove  (Pallete.tsx:44-53):  newV=(bottom-clientY)/height; newS=(clientX-left)/width;
    S=100*clamp01(newS); V=100*clamp01(newV);  onUpdateSV(S,V)
HueSlider.handleMouseMove (HueSlider.tsx:40-49): hue = normalizeHue(((clientX-left-6)/(width-12))*360)
AlphaSlider.handleMouseMove(AlphaSlider.tsx:42-49): α = normalizeAlpha((clientX-left)/(width-12))
```
`HANDLE_SIZE=12`, `RADIUS=6` in all three. `HueSlider` rail gradient (fixed, `HueSlider.tsx:11`):
`linear-gradient(90deg,red,#ff0 16.66%,#0f0 33.33%,#0ff 50%,#00f 66.66%,#f0f 83.33%,red)`.
Handle left = `calc((H%) / 359 * 100 - 6px)` (hue), `calc(α*100% - 6px)` (alpha),
`calc(S% - 6px)`/`calc(V% - 6px)` (palette).

### 4.7 swatch normalization — `ColorPickerSwatches.tsx`

- `normalizeColor(color, mode)` (`9-17`): if `mode==='hsv'` → `toRgbaString([...hsv2rgb(hsva(color))])`;
  else return the original string (named colours kept verbatim → browser resolves via CSS).
- `getHexFromName(color)` (`20-26`): **DOM** — `document.createElement('canvas').getContext('2d')`,
  `ctx.fillStyle=color`, return `ctx.fillStyle`; fallback `'#000000'`.
- `normalizeOutput(parsed)` (`67-88`): if swatch had **no** mode → treat as `hex`; if `/^[a-zA-Z]+$/`
  use `getHexFromName`, else warn + `'#000000'`. If swatch-mode === panel mode return verbatim; else
  `convertColor(value, panelMode, swatchMode)`.
- Value changes call `doUpdateValue(color,'input')` (`ColorPicker.tsx:667-669`); swatch Enter key
  also selects (`94-97`).

### 4.8 value serialization per mode (what `value` holds)

| mode | showAlpha=true | showAlpha=false |
| --- | --- | --- |
| `hex` | `#RRGGBBAA` | `#RRGGBB` |
| `rgb` | `rgba(r, g, b, a)` | `rgb(r, g, b)` |
| `hsl` | `hsla(h, s%, l%, a)` | `hsl(h, s%, l%)` |
| `hsv` | `hsva(h, s%, v%, a)` | `hsv(h, s%, v%)` |

(h/s/l/v rounded to ints; a = 2-dp `roundAlpha`; separators `", "`.)

---

## 5. Theme / cssr vars

### 5.1 Component var object — `cssVarsRef` (`ColorPicker.tsx:546-576`), **declaration order**

```
--n-bezier  (common.cubicBezierEaseInOut)   --n-text-color (self.textColor)
--n-color   (self.color)                    --n-panel-font-size (self.panelFontSize)
--n-font-size (self.fontSize<Size>)         --n-box-shadow (self.boxShadow)
--n-border  (self.border)                   --n-border-radius (self.borderRadius)
--n-height  (self.height<Size>)             --n-divider-color (self.dividerColor)
```
`<Size>` pick via `createKey('height'|'fontSize', mergedSize)` → `heightSmall|Medium|Large`,
`fontSizeSmall|Medium|Large`. `--n-font-size` binds the **trigger** (`index.cssr.ts:160`
`font-size: var(--n-font-size)`); `--n-panel-font-size` binds the **panel**
(`index.cssr.ts:17`). `useThemeClass('color-picker', mergedSizeRef.value[0], …)` supplies the
inline-theme class when `inlineThemeDisabled`. Vars are applied to **both** trigger (`style`) and
panel (`style`).

⚠️ The cssr header comment (`index.cssr.ts:5-13`) lists only **9** vars — it **omits `--n-border`**
(actual object emits 10). If a checker compares the comment, note the drift.

### 5.2 Theme `self` — `styles/light.ts:10-45` (key order, 13 keys)

```
panelFontSize = vars.fontSize      boxShadow = vars.boxShadow2   color = vars.popoverColor
textColor = vars.textColor2        borderRadius = vars.borderRadius
border = `1px solid ${vars.borderColor}`
heightSmall/heightMedium/heightLarge, fontSizeSmall/fontSizeMedium/fontSizeLarge, dividerColor
```
`createTheme({ name:'ColorPicker', common:commonLight, peers:{Input:inputLight, Button:buttonLight}, self })`
(`light.ts:49-64`). **Dark** (`styles/dark.ts:6-16`) reuses the same `self`, `commonDark`, peers
`inputDark`/`buttonDark` — **no var-value overrides**, only common/peer swaps.

### 5.3 cssr rules (`styles/index.cssr.ts`)

Panel: `margin: 4px 0; width: 240px; font-size: var(--n-panel-font-size); border-radius/box-shadow`
+ `fadeInScaleUpTransition()` + nested `n-input{text-align:center}`. Checkboard pseudo-bg
(`&::after`) 12px grid; in the trigger it becomes `--n-block-size: calc((var(--n-height) - 8px)/3)`.
Sliders `margin-bottom:8px` + `&::after` inset shadow; palette `height:180px; cursor:crosshair`;
handle `box-shadow 0 0 2px rgba(0,0,0,.45)`; preview 30×30 circular; input `__mode width:72px`;
control `padding:12px`; action `border-top:1px solid var(--n-divider-color); justify-content:flex-end`.
Swatches `display:grid; grid-template-columns:repeat(auto-fill, 18px); grid-gap:8px`. No prop-keyed
rules (no size/mode selectors — all size variance is via the vars above).

---

## 6. Examples inventory (`demos/enUS/`; zhCN identical text + `close-debug.vue`)

| File | Shows |
| --- | --- |
| `basic.demo.vue` | bare `<n-color-picker/>` |
| `alpha.demo.vue` | `:show-alpha="false"` + `:actions="['confirm']"` + `@confirm` |
| `size.demo.vue` | small / medium / large in a vertical Space |
| `disabled.demo.vue` | `disabled` |
| `modes.demo.vue` | `:modes="['hex']"` (single mode) |
| `actions.demo.vue` | `:actions="['clear']"` |
| `form.demo.vue` | inside `n-form`/`n-form-item` with a `change` rule |
| `swatches.demo.vue` | 5 swatches incl. `rgba(208, 48, 80, 1)` |
| `trigger.demo.vue` | `#trigger` slot ×3 (button, dot, text) via `@vicons/ionicons5` `ColorWand` |
| `native.demo.vue` | `:show-preview="true"` (native `<input type=color>`) |
| `zhCN/close-debug.demo.vue` | picker + a `@mousedown.stop` button (clickoutside regression) |

---

## 7. Port-fit assessment

### 7.1 → pure Elm helpers (eq-pin, no DOM)

- **All of seemly** §4.1–4.3: `hsl2hsv/hsv2hsl/hsv2rgb/rgb2hsv/rgb2hsl/hsl2rgb`, the 4 parsers
  (`hsla/hsva/rgba` incl. **named-colour table** — 148 entries in `lib/color/colors.js`), the 4
  rounders, and the 8 `to*String` serializers. These are the highest-value pins; reproduce the
  regexes, rounding and `", "` spacing literally.
- `utils.ts` §4.4: `deriveDefaultValue`, `getModeFromValue`, `getWCAGContrast`+`rgb2luminance`,
  `normalizeHue` (clamp 359), `normalizeAlpha`, `convertColor` + the 12-cell convert table.
- `ColorInputUnit` §4.5 normalizers (note `normalizeAlphaUnit` clamps to 100, `parseInt` truncation).
- Slider math §4.6 as pure functions of `(rect, pointer)` so they are testable without a browser.
- Swatch legality §4.7 except `getHexFromName`.

### 7.2 → DOM-bound (not pure / needs caller or a decision)

- `getHexFromName` — `canvas.getContext('2d').fillStyle`. Elm cannot read canvas. Options:
  (a) port seemly's 148-name → hex table and resolve names in Elm (best fidelity for `swatch='black'`);
  (b) treat bare names as invalid → `'#000000'`. **Decision needed**; upstream's DOM path also
  normalizes *system* colours, which a static table cannot. Recommend (a) + document the divergence.
- Native `<input type="color">` (`ColorPreview`) and the drag listeners — DOM-only.
- `NInputGroup`/`NInput` reuse for the numeric units.

### 7.3 Recommended view / panel split (house rule)

Trigger + body, caller-owned show/positioning:
- **`view` (trigger)** → `div.n-color-picker` with `--disabled` modifier, `__fill`
  (checkboard + colour overlay + `__value` label coloured by WCAG), carrying the 10 `--n-*` vars and
  the merged attrs; click is a caller message (`onClick → set show`).
- **`panel` (body)** → `div.n-color-picker-panel` + `.n-color-picker-control` subtree
  (Pallete, preview sliders, optional ColorPreview, ColorInput, optional swatches) + optional
  action row(s). Mirror `NUI.DatePicker.view` / `NUI.DatePicker.panel` (`src/NUI/DatePicker.elm`:
  `view` = trigger, `panel` = `div.n-date-panel`).
- **No split** for Swatches / Input units (inline composites).
- ⚠️ **Fidelity divergence to flag**: upstream has **no `focusDetector` sentinel** and **no keyboard
  navigation**; it closes via `clickoutside` (capture). The house overlay convention wants a
  focusDetector sentinel last child. Decide whether to (a) mirror upstream exactly, or (b) add the
  sentinel per convention — this is an `[oracle D]`-class decision, not obvious from upstream.

### 7.4 Not currently ported

No `src/NUI/ColorPicker.elm`, no `src/NUI/Theme/ColorPicker.elm`, no README row, no manifest entry
(verified: `README.md`, `tools/manifest.mjs` have no ColorPicker). Colour math has **no** existing
Elm home — expect a new pure module (e.g. `NUI.Internal.Color`) plus the component + theme.

### 7.5 Potential oracle-D notes (documented divergences to carry)

- `normalizeHue` clamps 360→**359**, whereas seemly `roundDeg` wraps 360→0 (used in serializers).
- cssr var comment omits `--n-border`.
- `getModeFromValue` only detects 4 modes; a named/`rgba`-less value yields `undefined` arrays.
- `normalizeAlphaUnit` upper-clamps to 100 (not 1).
- `slots.default` declared but unused.
