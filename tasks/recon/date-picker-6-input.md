# naive-ui v2.45.3 Input.tsx trigger bytes — pair/activation map (recon lane: recon-input)

Paths: `src/input/src/Input.tsx` (1488 L), `src/input/src/styles/input.cssr.ts` (391 L). NOTE: cssr lives at `src/input/src/styles/`, not `src/_input/`.

## 1. Pair mode DOM (render :1395–1465)
Root `div.n-input` (ordered classes :1125–1143): `n-input`, `n-input--{size}-size`, themeClass, [`n-input--{status}-status`], then cond map: `--rtl`, `--disabled`, `--textarea`, `--resizable`, `--autosize`, `--round`, **`--pair` :1134**, **`--focus` :1135** (=`this.mergedFocus`), **`--stateful` :1136**. Attrs: `tabindex=0` iff `!disabled && passivelyActivated && !activated` (:1140–1143), style=cssVars.

Pair tree (children order):
1. `div.n-input-wrapper` (:1148) — [prefix slot → `div.n-input__prefix`] + `div.n-input__input` → `input.n-input__input-el` (inputElRef, :1233–1288): `value=mergedValue[0]` if array else full, `placeholder=mergedPlaceholder[0]`, `size={this.attrSize}` (:1288), `style=[textDecorationStyle[0], inputProps.style]`, tabindex -1 iff `passivelyActivated && !activated`. Placeholder div `n-input__placeholder`><span> (showPlaceholder1 :256). Suffix block **skipped when pair** (`!this.pair &&` :1316).
2. `span.n-input__separator` (:1397) — `resolveSlot($slots.separator, () => [this.separator])` (string prop `separator` :96 or slot).
3. `div.n-input-wrapper` (2nd, :1403) — `div.n-input__input` → `input.n-input__input-el` (inputEl2Ref :1406–1438): NO `inputProps` spread, NO `size` attr, NO autofocus, `value=mergedValue[1]`, `placeholder=mergedPlaceholder[1]`, `style=textDecorationStyle[1]`, tabindex -1 iff passively&&!activated. Placeholder2 (`showPlaceholder2Ref` :268). Then pair-only suffix: `resolveWrappedSlot($slots.suffix)` renders `div.n-input__suffix` only if `clearable || children` (:1441–1463) containing [NBaseClear (only if `clearable`; `icon`→`clear-icon` slot, `placeholder`→`clear-icon-placeholder` slot), `children` (suffix slot)]. No loading/count/eye in pair suffix.
4. `div.n-input__border` + `div.n-input__state-border` if bordered (:1467–1473).

Pair values: `value`/`defaultValue` accept `[string,string]` (:80–83); `mergedPlaceholder` :243–255 (pair: array→as-is, undefined→['',''], string→[s,s]). `handleInput` pair branch builds `[v0,v1]` with `source: 0|1`; `clearValue` pair→`['','']` with `source:'clear'` (:645–652). Per-input focus tracked via `handleInputFocus(e, index)` :585–600 (index 0/1/2=textarea → `currentFocusedInputRef`). Autosize mirror only when `!pair && autosize` (:825). No count text in pair (WordCount only non-pair suffix / textarea).

## 2. Activation/focus classes
- `mergedFocusRef = useMemo(() => props.internalForceFocus || focusedRef.value)` :283–285. → `n-input--focus` root class :1135. **No `--active`/`--hover` classes exist** — hover is pure CSS `:hover` (cssr :270), active is only `activatedRef` state (tabindex/Enter gating), no class.
- `focusedRef`: set true in `handleInputFocus` :587 and `dealWithEvent('focus')` :618 (only if `relatedTarget` not an inner el/wrapper); set false in `dealWithEvent('blur')` :623. `handleWrapperFocus/Blur` :607–618 fire only when `passivelyActivated`, and also set `focusedRef`.
- `activatedRef`: true in `handleInputFocus` :588 (+`doActivate` :589); false in `handleInputBlur` :580 when `relatedTarget` not inputEl/inputEl2/textareaEl, and in `handleWrapperKeydownEsc` :759 (also refocuses wrapper). `doDeactivate` fires in `handleInputBlur` only if `relatedTarget === wrapperElRef` :576–578.
- `passivelyActivated` gates: wrapper `tabindex=0` :1141, inner inputs `tabindex=-1` :1203/:1273/:1410, `focus()` method focuses wrapper :771, Enter (`handleWrapperKeydownEnter` :747–763): if activated → deactivate when `internalDeactivateOnEnter` :752 (via Esc path); if not activated → `preventDefault` + focus inputEl/textareaEl. Esc :758 always deactivates when passivelyActivated. `activate()` method :795 focuses inputEl directly.
- `internalForceFocus` (:154): only feeds `mergedFocus` (visual focus class) — used by pickers while panel open.

## 3. textDecoration (:134, private)
`textDecorationStyleRef` :323–337 → array of `{textDecoration: v}` (string→[s], array→mapped). Lands as inline **style on each input/textarea el**: `textDecorationStyle[0]` :1208 (input1), pair input2 `style=textDecorationStyle[1]` :1434, textarea `[0]` :1269. Not on root.

## 4. attrSize (:135–138, default 20)
→ `size={this.attrSize}` on **input1 only** (:1288). Not on input2, not textarea. TimePicker: `mergedAttrSizeRef = format.length + 4` (TimePicker.tsx:414–416) → `attrSize={this.mergedAttrSize}` :961.

## 5. clear-icon-placeholder vs suffix (non-pair, :1316–1393)
Suffix `div.n-input__suffix` renders iff `suffix-children || clearable || showCount || mergedShowPasswordOn || loading!==undefined`. Order: ① `NBaseClear` (rendered iff `clearable || clear-icon-placeholder-children`; `show={showClearButton}`, `placeholder:()=>cip-children`, `icon:()=>clear-icon slot`) ② suffix children if `!internalLoadingBeforeSuffix` ③ `NBaseSuffix` (loading spinner) if `loading!==undefined` ④ suffix children if `internalLoadingBeforeSuffix` (default true) ⑤ WordCount if `showCount && type!=='textarea'` ⑥ eye if password. So **suffix slot always renders** alongside; `clear-icon-placeholder` is the placeholder content inside NBaseClear (visible when clear button hidden). `showClearButton` :287–306: false if disabled/readonly/!clearable/(!mergedFocus && !hover); pair: `!!(v0||v1) && (hover||focus)`; single: `!!value && (hover||focus)`.
TimePicker branch (:984–999): single slot key = `clearable ? 'clear-icon-placeholder' : 'suffix'` → `NBaseIcon.n-time-picker-icon` with TimeIcon (or `icon` slot). So icon hides behind clear on hover when clearable.

## 6. Emit points
`onActivate` ← `doActivate` :465–468, called in `handleInputFocus` :589. `onDeactivate` ← `doDeactivate` :460–463, called in `handleInputBlur` when `relatedTarget===wrapper` :576–578. `onFocus`/`onBlur` ← `doFocus/doBlur` :442–457 via `dealWithEvent` :603–626 (fires only on real boundary crossings). `onInputFocus/onInputBlur` :483–490 ← every inner focus/blur. `onWrapperFocus/onWrapperBlur` :495–504 ← wrapper events when passivelyActivated.

## 7. stateful=false
Only drops root class `n-input--stateful` :1136 (cssr has no `--stateful` rule in input.cssr — it's used by trigger components' cssr, e.g. picker `--trigger` styles). No DOM/behavior change in Input itself.

## 8. Existence only
`inputProps` (:105, spread on input1/textarea only) · `themeOverrides` via `useTheme` props · `allowInput`, `countGraphemes`, `renderCount`, `loading`, `internalLoadingBeforeSuffix` (:155–158).

## cssr (input.cssr.ts)
- `--pair` :210–226: `input-el, placeholder {text-align:center}`; `__separator` :212–225: `display:flex; align-items:center; transition:color .3s bezier; color:var(--n-text-color); white-space:nowrap`, nested `icon/base-icon → --n-icon-color`.
- `--focus` :273–278 (under `cNotM('disabled')`): `background:--n-color-focus`; `__state-border {border:--n-border-focus; box-shadow:--n-box-shadow-focus}`. `&:hover` :270–272: `background:--n-color-hover`, state-border `--n-border-hover`. No `--active`/`--hover` class rules.
- clear: `base-clear` under `__suffix` :318–327 (`font-size:--n-icon-size`; `__placeholder > base-icon` icon-color); NBaseClear internals (`__clear` hover/active :263–268 in base-clear's own sheet — here only the placeholder icon color). `__separator` disabled :238–242.
- `--disabled` :227–253, `--round` :100, status rules :354–387.

## TimePicker fill (only gaps)
- `attrSize`: `mergedAttrSizeRef = props.format.length + 4` (TimePicker.tsx:414) → `attrSize=` :961 on NInput.
- Suffix content branch (:984–999): `showIcon ? { [clearable ? 'clear-icon-placeholder' : 'suffix']: () => <NBaseIcon class=n-time-picker-icon>{icon slot || <TimeIcon/>}</NBaseIcon> } : null`. Key detail: when `clearable`, the clock icon is passed as the **clear placeholder** (NBaseClear placeholder), so it swaps to clear icon on hover/focus-with-value; when not clearable it's a plain suffix child. Also `textDecoration={isValueInvalid ? 'line-through' : undefined}` :965–967.

---

## Elm seam implications (orchestrator synthesis)

- Input.elm additive options (default-off, standalone bytes unchanged): `passivelyActivated`, `activated` (caller-owned), `internalForceFocus` (→ `n-input--focus` root class; NO --active/--hover classes exist upstream), `textDecoration` (inline style on input1; pair gets a pair), `attrSize` (size attr on input1 only), `onFocus`/`onBlur` (raw events on input el), pair mode: `--pair` class + wrapper(input1, no suffix) → `span.n-input__separator` → wrapper(input2 + suffix with NBaseClear iff clearable) + source-tagged pair input (0|1|'clear'; clear → `['','']`).
- Enter/Esc activation behavior + programmatic focus = caller-owned (documented punt; no ports in house style).
- TimePicker trigger: clock icon goes into `clear-icon-placeholder` when clearable (swaps to clear on hover/focus-with-value), else plain suffix.
