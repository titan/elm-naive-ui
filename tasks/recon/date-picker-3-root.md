# DatePicker ROOT Recon — naive-ui v2.45.3 (byte-fidelity map) (recon lane: recon-root)

## 1. Trigger Render (`DatePicker.tsx`)

### Outer div (`:1088-1099`)
- `ref="triggerElRef"`, `class=[clsPrefix-date-picker, disabled→`-date-picker--disabled`, isRange→`-date-picker--range`, triggerThemeClass]`
- `style = triggerCssVars` (3 vars, see §3), `onKeydown = handleKeydown` (Escape → `closeCalendar({returnFocus:true})`, `:463-472`)
- Wraps `VBinder > [VTarget, VFollower]` (`:1100-1216`)

### shared `commonInputProps` (`:1069-1082`, spread into BOTH NInput branches)
`bordered: mergedBordered` (config `mergedBorderedRef`, `:101`), `size: mergedSize` (form-item chain, `:112-126`), `passivelyActivated: true`, `disabled: mergedDisabled`, `readonly: inputReadonly || mergedDisabled`, `clearable` (raw prop), `onClear: handleClear`, `onClick: handleTriggerClick`, `onKeydown: handleInputKeydown`, `onActivate: handleInputActivate`, `onDeactivate: handleInputDeactivate`, `onFocus: handleInputFocus`, `onBlur: handleInputBlur`

### Pair branch (`:1096-1143`, `isRange` = type ∈ {daterange, datetimerange, monthrange, quarterrange, yearrange}, `:210-216`)
- `ref="inputInstRef"`, `status={mergedStatus}`, `value={[displayStartTime, displayEndTime]}` (the display strings), `placeholder=[localizedStartPlaceholder, localizedEndPlaceholder]`, `textDecoration=[isStartValueInvalid?'line-through':'', isEndValueInvalid?'line-through':'']`, `pair`, `onUpdateValue: handleRangeUpdateValue` (source 0|1|'clear'), `theme: mergedTheme.peers.Input`, `themeOverrides: mergedTheme.peerOverrides.Input`, `internalForceFocus: mergedShow`, `internalDeactivateOnEnter`, + commonInputProps
- **separator slot** (`:1113-1123`): `separator` prop string if set, else `resolveSlot($slots.separator, → NBaseIcon(clsPrefix, class=clsPrefix-date-picker-icon) > ToIcon)`
- **clearable ? 'clear-icon-placeholder' : 'suffix' slot** (`:1124-1135`): `NBaseIcon(class=`${clsPrefix}-date-picker-icon`) > DateIcon` (pair branch does NOT wrap in resolveSlot of date-icon — the slot content is fixed icon; slot `date-icon` is only resolved in single branch)

### Single branch (`:1145-1178`)
- `ref="inputInstRef"`, `status={mergedStatus}`, `value={displayTime}`, `placeholder={localizedPlacehoder}` (typo in source), `textDecoration={isValueInvalid && !isRange ? 'line-through' : ''}` (isRange always false here), `onUpdateValue: handleSingleUpdateValue`, same theme/themeOverrides/internalForceFocus/internalDeactivateOnEnter + commonInputProps
- **clearable ? 'clear-icon-placeholder' : 'suffix' slot** (`:1157-1170`): `NBaseIcon > resolveSlot($slots['date-icon'], → DateIcon)` (note: slot resolved at icon-inner level here, unlike pair branch)

### `n-date-picker__input` semantics
- No class `n-date-picker__input` exists anywhere in `src/` (grep empty). Display value = `displayTime/displayStartTime/displayEndTime` = `singleInputValueRef/rangeStartInputValueRef/rangeEndInputValueRef`, derived from **pendingValue** by `deriveInputState()` (`:545-577`) using `mergedFormatRef` (display format). Actual model value = `mergedValueRef` (committed); `pendingValueRef` mirrors it on close (`watch(mergedShowRef)` `:725-733`) and is what the panel edits. Input typing (`handleSingleUpdateValue` `:597-618`, `handleRangeUpdateValue` `:619-661`) `strictParse`s against `mergedFormatRef`; invalid → keep raw text in display refs; empty string → value null. Range clamps: end<start collapses to the edited side (source 0 → end=start, else start=end, `:646-653`).
- `disabled/size/status/bordered` map: `mergedDisabledRef/mergedSizeRef/mergedStatusRef` from `useFormItem` (`:117-128`), `mergedBorderedRef` from `useConfig` (`:101`) — all forwarded straight to NInput props.

### Clear button
NInput's own clear (clearable) → `onClear: handleClear` (`:479-483`): `doUpdateShow(false)`, `inputInstRef.deactivate()`, `doClear()` (fires `props.onClear`).

## 2. Panel switch (`renderPanel`, `:1003-1040`)
| type | panel | extra props |
|---|---|---|
| `datetime` | `DatetimePanel` | `defaultCalendarStartTime` |
| `daterange` | `DaterangePanel` | `defaultCalendarStartTime/EndTime`, `bindCalendarMonths` |
| `datetimerange` | `DatetimerangePanel` | same as daterange |
| `month`/`year`/`quarter` | `MonthPanel` (`type` prop, `key=type`) | — |
| `monthrange`/`yearrange`/`quarterrange` | `MonthRangePanel` (`type` prop) | — |
| `date`/`week`/default | `DatePanel` (`type` prop) | `defaultCalendarStartTime` |

- `isRange` (`:210-216`): the 5 range types above. `hasTime` is not a root concept — panel selection encodes it (datetime/datetimerange panels carry TimePicker).
- `panel: Boolean` prop → render returns `renderPanel()` bare (`:1041-1043`), no trigger/binder.
- `commonPanelProps` (`:978-1002`): onUpdateValue/onTabOut/onClose/onClear/onKeydown/onConfirm handlers, `ref: panelInstRef`, `value: pendingValue`, `active: mergedShow`, `actions`, `shortcuts`, `style: cssVars`, `defaultTime`, `themeClass`, `panel`, `inputReadonly: inputReadonly || mergedDisabled`, `onRender`, onNext/Prev Month/Year, `timePickerFormat`, `dateFormat`, `fastYearSelect`, `fastMonthSelect`, `calendarDayFormat`, `calendarHeaderYearFormat`, `calendarHeaderMonthFormat`, `calendarHeaderMonthYearSeparator`, `calendarHeaderMonthBeforeYear`.

## 3. cssVars on root

**triggerCssVars** (`:774-781`, applied to outer div `:1093`):
1. `--n-bezier` ← common.cubicBezierEaseInOut
2. `--n-icon-color-override` ← self.iconColor
3. `--n-icon-color-disabled-override` ← self.iconColorDisabled

**cssVarsRef** (`:797-925`, applied to panel via `commonPanelProps.style`), in emission order:
1. `--n-bezier` ← cubicBezierEaseInOut
2. `--n-panel-border-radius` ← panelBorderRadius (borderRadius)
3. `--n-panel-color` ← panelColor (popoverColor)
4. `--n-panel-box-shadow` ← panelBoxShadow (boxShadow2)
5. `--n-panel-text-color` ← panelTextColor (textColor2)
6. `--n-panel-header-padding` ← panelHeaderPadding (`'8px 12px'`, _common.ts:12)
7. `--n-panel-header-divider-color` ← panelHeaderDividerColor (dividerColor)
8. `--n-calendar-left-padding` ← `calendarLeftPadding{Type}` (createKey, _common.ts:16-26 per type)
9. `--n-calendar-right-padding` ← `calendarRightPadding{Type}` (_common.ts:27-37)
10. `--n-calendar-title-color-hover` ← calendarTitleColorHover (hoverColor)
11. `--n-calendar-title-height` ← '28px'
12. `--n-calendar-title-padding` ← '0'
13. `--n-calendar-title-font-size` ← calendarTitleFontSize (fontSize)
14. `--n-calendar-title-font-weight` ← calendarTitleFontWeight (fontWeightStrong)
15. `--n-calendar-title-text-color` ← calendarTitleTextColor (textColor1)
16. `--n-calendar-title-grid-template-columns` ← calendarTitleGridTempateColumns ('28px 28px 1fr 28px 28px')
17. `--n-calendar-days-height` ← '32px'
18. `--n-calendar-days-divider-color` ← calendarDaysDividerColor (dividerColor)
19. `--n-calendar-days-font-size` ← calendarDaysFontSize (fontSize)
20. `--n-calendar-days-text-color` ← calendarDaysTextColor (textColor2)
21. `--n-calendar-divider-color` ← calendarDividerColor (dividerColor)
22. `--n-panel-action-padding` ← '8px 12px'
23. `--n-panel-extra-footer-padding` ← '8px 12px'
24. `--n-panel-action-divider-color` ← panelActionDividerColor (dividerColor)
25. `--n-item-font-size` ← itemFontSize (fontSize)
26. `--n-item-border-radius` ← itemBorderRadius (borderRadiusSmall)
27. `--n-item-size` ← '24px'
28. `--n-item-cell-width` ← '38px'
29. `--n-item-cell-height` ← '32px'
30. `--n-item-text-color` ← itemTextColor (textColor2)
31. `--n-item-color-included` ← itemColorIncluded (changeColor(primaryColor,{alpha:0.1}))
32. `--n-item-color-disabled` ← itemColorDisabled (hoverColor)
33. `--n-item-color-hover` ← itemColorHover (hoverColor)
34. `--n-item-color-active` ← itemColorActive (primaryColor)
35. `--n-item-text-color-disabled` ← itemTextColorDisabled (textColorDisabled)
36. `--n-item-text-color-active` ← itemTextColorActive (popoverColor)
37. `--n-scroll-item-width` ← '80px'
38. `--n-scroll-item-height` ← '40px'
39. `--n-scroll-item-border-radius` ← scrollItemBorderRadius (borderRadius)
40. `--n-arrow-size` ← '14px'
41. `--n-arrow-color` ← arrowColor (iconColor)
42. `--n-icon-color` ← iconColor
43. `--n-icon-color-disabled` ← iconColorDisabled

(self() = `styles/light.ts:18-58`; numeric literals from `styles/_common.ts`. `itemTextColorCurrent: primaryColor` exists in theme but is NOT in cssVars. `inlineThemeDisabled` → cssVars undefined, `useThemeClass('date-picker', type, ...)` `:926-935`; trigger variant `useThemeClass('date-picker-trigger', ...)` `:782-789`.)

## 4. Value/derivation surface

**interface.ts type aliases**
- `Value = number | [number, number]` (`:20`)
- `FormattedValue = string | [string, string]` (`:26`)
- `DefaultTime` (`:22-25`): `string | [string?, string?] | fn(ts)→string | fn(ts,'start'|'end',value)→string`
- `Shortcuts` (`:38-45`): `Record<string, number | fn→number>` or `[number,number]`-valued (incl. readonly/fn)
- `OnUpdateValue`/`OnConfirm` (`:47-55`) — (value, formattedValue) pairs; `OnUpdateFormattedValue` (`:57-65`) — (formatted, timestamp); `OnPanelUpdateValue` (`:79-83`) — (value, doUpdate); `OnClose` (`:88`) — `(disableUpdateOnClose) => void`
- `IsDateDisabled` = single `(ts, detail{type:'date'|'month'|'year'|'quarter'|'input'})` or range `(ts, 'start'|'end', value)` (`:153-177`); `IsTimeDisabled` → `TimeValidator{isHourDisabled,isMinuteDisabled,isSecondDisabled}` (`:179-195`); `DatePickerGetDefaultTime`/`DatePickerGetRangeDefaultTime` (`:197-203`); `FirstDayOfWeek = 0..6` where **0 = Monday** (`:123-124`)

**utils.ts pure helpers**
- `getDerivedTimeFromKeyboardEvent` (`:33`) — arrow keys ±1/±7 days (currently dead code in DatePicker `:472`)
- `matcherMap` (`:53`) + `makeWeekMatcher` (`:60`) + `transformNaiveFirstDayOfWeekToDateFns` (`:69`) — naive 0=Mon → date-fns 0=Sun via `(d+1)%7`
- `matchDate` (`:75-93`) — date/month/year/quarter/week granularity equality
- `dateItem` (`:167`) — DateItem with inSpan/startOfSpan/endOfSpan/selected/inCurrentMonth/isCurrentDate; `weekItem` (`:236`) — same but `inSelectedWeek`, `selected:false`; `dateOrWeekItem` (`:149`) dispatch
- `monthItem`/`yearItem`/`quarterItem` (`:279/302/324`) — selected via matchDate
- `getMonthString`/`getYearString`/`getQuarterString` (`:209/218/227`) — format via date-fns with locale
- `dateArray` (`:351`) — month grid: pads back to `startDay`, forward to 28/35/42 (strip) or 42; `monthArray` (`:420`) 12; `quarterArray` (`:438`) 4; `yearArray` (`:461`) `yearRange[0]..[1]` exclusive end
- `strictParse` (`:480`) — parse then round-trip `format(result)===string` else `Invalid Date`
- `extractSingleDefaultTime` (`:496`)/`extractRangeDefaultTime` (`:511`) → `getDefaultTime` (`:528`) — `'HH:mm:ss'` split into `{hours,minutes,seconds}`
- `pluckValueFromRange` (`:549`) — value[0]/value[1] or null

**validation-utils.ts**
- `uniCalendarValidation` (`:10-77`) — date/datetime: `timePickerValidatorRef` from `isTimeDisabled(value)`, `isHour/Minute/SecondDisabledRef`, `isDateInvalidRef` (isDateDisabled with `{type:'input'}`), `isTimeInvalidRef` (datetime only; note upstream bug: `second = time.getMinutes()` `:55`), `isDateTimeInvalidRef`, `isValueInvalidRef` (type date→date invalid; datetime→both)
- `dualCalendarValidation` (`:79-225`) — daterange/datetimerange: start/end hour/minute/second validators, `isStartDate/EndDateInvalidRef` (isDateDisabled ts,position,value), `isStartTime/EndTimeInvalidRef` (datetimerange only), `isStart/EndValueInvalidRef`, `isRangeInvalidRef`
- Root runs both against **pendingValue** (`:735-736`) and provides them via `datePickerInjectionKey` (`:737-763`).

**DatePicker.tsx value pipeline**
- `mergedFormatRef` (`:143-163`) — prop `format` else locale per type (dateFormat/dateTimeFormat/yearTypeFormat/monthTypeFormat/quarterFormat/weekFormat)
- `mergedValueFormatRef` (`:164-166`) — `valueFormat ?? mergedFormat`
- `getTimestampValue` (`:168-190`) — formatted→ts via strictParse; `getFormattedValue` (`:349-366`) — ts→formatted via date-fns format
- `uncontrolledValueRef` init (`:192-198`) — `defaultFormattedValue` (parsed) else `defaultValue` else null; `controlledValueRef` (`:199-206`) — `formattedValue` prop parsed, else `value` prop; `useMergedState` (`:207-210`)
- `pendingValueRef` (`:213-217`) — panel working copy; `doUpdateValue` (`:383-412`) — order: `doConfirm?` → `onUpdateValue` → `onUpdate:value` → `onChange`(deprecated) → set uncontrolled → `doUpdateFormattedValue` (onUpdate:formattedValue + onUpdateFormattedValue) → form nTriggerFormChange/Input
- `handlePanelUpdateValue` (`:512-521`) — doUpdate? commit : pending only; `handlePanelConfirm` (`:522-531`) — commits a copy of pending with doConfirm:true
- shortcuts: passed to panel as `shortcuts` prop; resolved in `use-panel-common.getShortcutValue` (`:157-163`) — fn() or literal

## 5. props.ts full list (defaults pinned)
`to` (useAdjustedTo.propTo), `bordered: undefined`, `clearable: false`, `fastYearSelect: false`, `fastMonthSelect: false`, `updateValueOnClose: false`, `calendarDayFormat`, `calendarHeaderYearFormat`, `calendarHeaderMonthFormat`, `calendarHeaderMonthYearSeparator: ' '`, `calendarHeaderMonthBeforeYear: undefined`, `defaultValue`, `defaultFormattedValue`, `defaultTime`, `disabled: undefined`, `placement: 'bottom-start'`, `value`, `formattedValue`, `size`, **`type: 'date'`**, `valueFormat`, `separator`, `placeholder`, `startPlaceholder`, `endPlaceholder`, `format`, `dateFormat`, `timePickerFormat`, `actions: undefined` (Array|`null`), `shortcuts`, `isDateDisabled`, `isTimeDisabled`, `show: undefined`, `panel: false`, `ranges`, `firstDayOfWeek`, `inputReadonly: false`, **`closeOnSelect: false`**, `status`, `timePickerProps` (obj or [obj,obj]), `onClear`, `onConfirm`, `defaultCalendarStartTime`, `defaultCalendarEndTime`, `bindCalendarMonths: false`, **`monthFormat: 'M'`**, **`yearFormat: 'y'`**, **`quarterFormat: '\\'Q\\'Q'`**, **`yearRange: [1901, 2100]`**, `onUpdate:show`/`onUpdateShow`, `onUpdate:formattedValue`/`onUpdateFormattedValue`, `onUpdate:value`/`onUpdateValue`, `onFocus`, `onBlur`, `onNextMonth`, `onPrevMonth`, `onNextYear`, `onPrevYear`, `onChange` (deprecated), + `useTheme.props` (`theme`, `themeOverrides`, `builtinThemeOverrides`, `abstract`…).

**Derived actions default** (`mergedActionsRef` `:277-348`): `actions===null`→`[]`; explicit→as-is; else `clearable?['clear']:[]` then: date/week→`+['now']`; datetime→`+['now','confirm']`; daterange/datetimerange→`+['confirm']`; month→`+['now','confirm']`; year→`+['now']`; quarter→`+['now','confirm']`; monthrange/yearrange/quarterrange→`+['confirm']`; else warn.

**closeOnSelect semantics** (Boolean prop, default false — no per-type default): consumed ONLY in `use-dual-calendar.ts:437` — on completing a range selection, `if (closeOnSelect && type==='daterange')`: `updateValueOnClose? closeCalendar() : handleConfirmClick()`. Single-panel types close on select unconditionally (`use-calendar.ts:394-415`: date/week→doClose; year→doClose; month/quarter→stay open). `updateValueOnClose` also in `closeCalendar` (`:703-717`): `type!=='date' && updateValueOnClose && !disableUpdateOnClose` → `handlePanelConfirm()` on close.

## 6. Show/panel-open lifecycle
**Caller-owned runtime (prop-driven):** `show` (controlled via `useMergedState(controlledShowRef, uncontrolledShowRef)` `:132-134`), `onUpdate:show`/`onUpdateShow` (`doUpdateShow` `:444-451`), `to`/`placement` (VFollower `:1180-1186`: `containerClass=namespace`, `teleportDisabled = adjustedTo===useAdjustedTo.tdkey`), `panel` (bare mode), `disabled`.
**Root-owned runtime:** clickoutside directive on panel (`vdirs clickoutside`, capture:true, `:1194-1199`; `handleClickOutside` `:493-501` — closes unless target inside triggerElRef), Escape keydown on trigger div (`:463-472`) and input (`:474-478` marks effect performed only), input activate/deactivate (`:578-595` — activate→openCalendar, deactivate/blur→deriveInputState + closeCalendar(returnFocus:false); blur skips if relatedTarget inside panelInstRef.$el), trigger click (`:663-670` — ignores when happensIn 'clear'), `openCalendar`/`closeCalendar` (`:685-717`, disabled/mergedShow guards; returnFocus→inputInstRef.focus()), Transition `fade-in-scale-up-transition` appear=isMounted (`:1187-1207`), panel render null when `!mergedShow`.
**Derived:** `mergedShowRef`, `pendingValue` (reset to mergedValue on close `:725-733`), display strings (`deriveInputState` watch `:719-723` + init `:724`), `isRange`, localized placeholders (`:223-276`), `actions`, validation refs, exposed `DatePickerInst.focus/blur` (`:765-772`).
