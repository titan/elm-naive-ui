# AREA 1 — time-picker + AREA 2 — date-picker stylesheet (recon lane: recon-time)

Source: naive-ui v2.45.3, mounted at `/home/titan/Works/elm/naive-ui`.

## (a) TimePicker trigger DOM + cssVars

**Trigger DOM** (`TimePicker.tsx:1030–1086`): root `div.n-time-picker` (class `:1035`, gets `triggerThemeClass`, `style=triggerCssVars`) → `VBinder` → `VTarget` → **NInput** (`:1043`, `passivelyActivated`, `internalDeactivateOnEnter`, `internalForceFocus={mergedShow}`, `attrSize = format.length+4` `:380`, `textDecoration='line-through'` when `isValueInvalid`). Icon slot (`:1058–1070`): `clearable ? 'clear-icon-placeholder' : 'suffix'` slot → `NBaseIcon.n-time-picker-icon` wrapping `TimeIcon` (slot `icon` overrides). Panel in `VFollower` (`:1073`, `teleportDisabled` when `adjustedTo===tdkey`, `containerClass=namespace`, `placement` default `'bottom-start'`) wrapped in `<Transition name="fade-in-scale-up-transition" appear={isMounted}>` (`:1079`), with `clickoutside` directive (capture) `:1020`. Panel receives `class={themeClass} style={cssVars}`.

**Trigger cssVars** (`:853–863`, order): `--n-icon-color-override` (iconColor), `--n-icon-color-disabled-override` (iconColorDisabled), `--n-bezier` (cubicBezierEaseInOut). Theme class handle name `'time-picker-trigger'` (`:871`).

**Panel cssVars** (`:882–907`, exact order):
`--n-bezier` (cubicBezierEaseInOut), `--n-border-radius` (borderRadius), `--n-item-color-hover` (itemColorHover), `--n-item-font-size` (itemFontSize), `--n-item-height` (itemHeight), `--n-item-opacity-disabled` (itemOpacityDisabled), `--n-item-text-color` (itemTextColor), `--n-item-text-color-active` (itemTextColorActive), `--n-item-width` (itemWidth), `--n-panel-action-padding` (panelActionPadding), `--n-panel-box-shadow` (panelBoxShadow), `--n-panel-color` (panelColor), `--n-panel-divider-color` (panelDividerColor), `--n-item-border-radius` (itemBorderRadius). Theme class name `'time-picker'` (`:910`).

**light.ts self()** (`styles/light.ts:13–35`): spread `...commonVars` first, then `panelColor: popoverColor`, `panelBoxShadow: boxShadow2`, `panelDividerColor: dividerColor`, `itemTextColor: textColor2`, `itemTextColorActive: primaryColor`, `itemColorHover: hoverColor`, `itemOpacityDisabled: opacityDisabled`, `itemBorderRadius: borderRadius`, `borderRadius`, `iconColor`, `iconColorDisabled`.
**_common.ts** (`styles/_common.ts`): `itemFontSize: '12px'`, `itemHeight: '36px'`, `itemWidth: '52px'`, `panelActionPadding: '8px 0'`.
**Peers** (`light.ts:43–47`): `Scrollbar: scrollbarLight, Button: buttonLight, Input: inputLight`. **dark.ts** reuses light `self` verbatim (peer-only darkening).

## (b) Panel DOM byte tree

`Panel.tsx:206–378` render:
```
div.n-time-picker-panel (tabindex=0, onFocusin/onFocusout/onKeydown)   :208
└ div.n-time-picker-cols                                              :214
  ├ [showHour] div.n-time-picker-col[--invalid][--transition-disabled] :216 (class order: base, invalid, transition-disabled)
  │   └ NScrollbar → [PanelCol(items), div.n-time-picker-col__padding] :224–236
  ├ [showMinute] same (class order: base, transition-disabled, invalid) :240
  ├ [showSecond] same (class order: base, invalid, transition-disabled) :268
  └ [use12Hours] same (class order: base, invalid, transition-disabled) :296
├ [actions?.length] div.n-time-picker-actions                          :328
│   ├ [includes('clear')]   NButton size=tiny → clearText              :330
│   ├ [includes('now')]     NButton size=tiny → nowText                :339
│   └ [includes('confirm')] NButton size=tiny type=primary
│        class .n-time-picker-actions__confirm, disabled={isValueInvalid} :348
└ NBaseFocusDetector (onFocus=onFocusDetectorFocus)                    :366
```
Actions default `['now','confirm']` (`:23`). No extra transitions inside Panel — the fade-in-scale-up is applied by parent's `<Transition>`; cssr also calls `fadeInScaleUpTransition()` inside `.n-time-picker-panel` (`styles/index.cssr.ts:41`).

**PanelCol DOM** (`PanelCol.tsx:25–46`): for each `Item` → `div.n-time-picker-col__item` with `key={label}`, `data-active=""` attr when active (null otherwise), classes: `__item`, `__item--active` (if active), `__item--disabled` (if disabled); `onClick` only when `onItemClick && !disabled`; content = `label` text.

## (c) utils.ts pure helpers (line refs)

- `time` const (`:4–176`): `amHours` (00–11), `pmHours` (12,01–11), `hours` (00–23), `minutes`/`seconds` (00–59), `period: ['AM','PM']` — all 2-char zero-padded strings.
- `getFixValue(value)` `:178` — `` `00${value}`.slice(-2) ``.
- `getTimeUnits(defaultValue, stepOrList, isHourWithAmPm?)` `:184–232` — 3 modes: array list (am filters <12, pm filters ≥12 mapped `v===12?12:v-12`), number step (modulo filter + pm remap), undefined (pass-through with am/pm filter/remap). All output via `getFixValue`.
- `isTimeInStep(value, type, stepOrList)` `:234–246` — undefined→true, number→modulo, array→includes.
- `findSimilarTime(value, type, stepOrList)` `:248–277` — nearest value in `getTimeUnits` list (ties → lower bound); throws `time-picker` error if list empty.
- `getAmPm(value)` `:279` — `getHours(value) < 12 ? 'am' : 'pm'`.
- Note: `maybe-is-array` is not here; `MaybeArray` type comes from `_utils` (`:1`). TimePicker.tsx has local `validateUnits(value, max)` (`:72–83`) for hours/minutes/seconds prop validators.

## (d) Props surface (`timePickerProps`, `TimePicker.tsx:85–174`)

theme props, `to` (useAdjustedTo.propTo), `bordered` (undefined default), `actions: Array<'clear'|'now'|'confirm'|null>`, `defaultValue: number|null` (null), `defaultFormattedValue: String`, `placeholder`, `placement: 'bottom-start'`, `value: number|null`, **`format: 'HH:mm:ss'`** (`:112`), `valueFormat: String`, `formattedValue: string|null`, `isHourDisabled`/`isMinuteDisabled`/`isSecondDisabled` (types in `interface.ts:43–51`: `(hour)`, `(minute, hour|null)`, `(second, minute|null, hour|null)`), `size: TimePickerSize`, `inputReadonly`, `clearable`, `status`, `onUpdate:value`/`onUpdateValue` (`OnUpdateValue = (value: number|null, formattedValue: string|null) => void`, `interface.ts:30–33`), `onUpdate:show`/`onUpdateShow`, `onUpdate:formattedValue`/`onUpdateFormattedValue` (`(string|null, number|null)`), `onBlur`, `onConfirm`, `onClear`, `onFocus`, `timeZone: String` (IANA, uses `formatInTimeZone` `:276`), `showIcon: true`, `disabled` (undefined), `show` (undefined), `hours`/`minutes`/`seconds: MaybeArray<number>` (validators ≤23/≤59), `use12Hours: Boolean`, `stateful: true` (private), `onChange` (deprecated). **No `defaultTime` prop on TimePicker** — `defaultTime` lives on date-picker (`use-panel-common.ts:36`).

Behavior notes: `hourInFormat = /H|h|K|k/.test(format)`, `minuteInFormat = format.includes('m')`, `secondInFormat = format.includes('s')` (`:336–344`) → drive `showHour/showMinute/showSecond`. `mergedAttrSize = format.length + 4` (`:380`). Value parsing via `strictParse` from `date-picker/src/utils` (`:70, :248, :727`). `scrollTimer` (`:657`) scrolls each col's scrollbar to `querySelector('[data-active]').offsetTop`. Watch on `mergedShow` restores `memorizedValue` if invalid (`:801`). `handleNowClick` (`:764`) snaps to `findSimilarTime` per unit.

## (e) Panel embeddability

- `Panel` is **NOT exported** from `src/time-picker/index.ts` (only `NTimePicker`, theme types). It's an internal module (`./Panel`), but the date-picker does **not** use it directly.
- date-picker `datetime.tsx:71–86` / `datetimerange.tsx:78–95,110–127` render the **whole `NTimePicker`** (trigger + follower) inside `.n-date-panel-header`, with: `format={this.timePickerFormat}` (from `use-panel-common.ts:29`, prop `timePickerFormat: String` `props.ts:72`, forwarded `DatePicker.tsx:1005`), `showIcon={false}`, `to={false}` (panel renders inline, no teleport), `stateful={false}`, `theme={mergedTheme.peers.TimePicker}` + `themeOverrides`, `value`, `isHour/Minute/SecondDisabled`, `onUpdateValue` handler; datetimerange spreads `timePickerProps[0]`/`[1]` (array form = per-picker props); datetime spreads `timePickerProps` only when non-array. `size={this.timePickerSize}`.
- So for the Elm port: the "embedded time panel" is a full TimePicker with `to=false, showIcon=false, stateful=false` — its popover renders in place. Panel cssr `margin: 4px 0` (`index.cssr.ts:37`) is what spaces it.

## time-picker cssr rule tree (`src/time-picker/src/styles/index.cssr.ts:18–140`)

Vars header comment `:4–17` lists 16 `--n-*` (icon overrides + panel vars).
- `cB('time-picker')` `:18` — `z-index:auto; position:relative` → `cB('time-picker-icon')` `:22` color icon-color-override, transition color .3s bezier; `cM('disabled')` `:27` → icon color disabled-override.
- `cB('time-picker-panel')` `:33` — transition box-shadow/bg .3s, outline none, font-size item-font-size, border-radius, margin 4px 0, min-width 104px, overflow hidden, bg panel-color, box-shadow panel-box-shadow → `fadeInScaleUpTransition()` `:41`; `cB('time-picker-actions')` `:42` padding panel-action-padding, flex space-evenly; `cB('time-picker-cols')` `:48` height item-height*6, flex, border-bottom 1px panel-divider-color; `cB('time-picker-col')` `:54` flex-grow 1, min-width item-width, height item-height*6, column → `cM('transition-disabled')` `:62` item & ::before transition none; `cE('padding')` `:66` height item-height*5; `&:first-child` `:69` min-width item-width+4px, item::before left 4px; `cE('item')` `:74` cursor pointer, item-height, flex center, transition color/bg/opacity/text-decoration-color .3s, bg transparent, text-decoration-color transparent, color item-text-color, z-index 0, padding-top 4px, position relative → `&::before` `:93` content "", bg transition, z-index -1, absolute inset left 0 right 4px top 4px bottom 0, border-radius item-border-radius; `cNotM('disabled')` `:103` `&:hover::before` bg item-color-hover; `cM('active')` `:108` color item-text-color-active, ::before bg item-color-hover; `cM('disabled')` `:116` opacity item-opacity-disabled, cursor not-allowed; `cM('invalid')` `:121` on col → item `cM('active')` `:123` text-decoration line-through, text-decoration-color item-text-color-active.

---

# AREA 2 — date-picker stylesheet

## (f) `src/date-picker/src/styles/index.cssr.ts` rule tree (550 L)

Header comment `:4–53` lists all `--n-*` vars (bezier, icon overrides, panel, header, calendar, action, item, scroll-item, arrow groups).
- `cB('date-picker')` `:55` — `position:relative; z-index:auto` → `cB('date-picker-icon')` `:59` + `cB('icon')` `:63` color icon-color-override, transition color .3s; `cM('disabled')` `:67` both icons → disabled-override.
- `cB('date-panel')` `:76` — `width:fit-content; outline:none; margin:4px 0; display:grid; grid-template-columns:0fr; border-radius:panel-border-radius; bg panel-color; color panel-text-color; user-select:none` →
  - `fadeInScaleUpTransition()` `:91`
  - `cM('shadow')` `:92` box-shadow panel-box-shadow
  - `cB('date-panel-calendar')` `:95` padding calendar-left-padding, grid 1fr, gridArea left-calendar → `cM('end')` `:102` padding calendar-right-padding, gridArea right-calendar
  - `cB('date-panel-month-calendar')` `:108` flex, gridArea left-calendar → `cE('picker-col')` `:111` min-width scroll-item-width, height scroll-item-height*6 → `&:first-child` `:116` min-width +4px, item::before left 4px; `cE('padding')` `:124` height *5; `cE('picker-col-item')` `:128` (mirror of time-picker col item: ::before inset, `cNotM('disabled')` hover::before item-color-hover + `cM('selected')` color item-color-active + ::before bg item-color-hover `:150`; `cM('disabled')` `:156` color item-text-color-disabled, `selected` ::before bg item-color-disabled)
  - `cM('date')` `:172` gridTemplateAreas `"left-calendar"/"footer"/"action"`; `cM('week')` `:178` same areas; `cM('daterange')` `:184` `"left-calendar divider right-calendar"/"footer footer footer"/"action action action"`; `cM('datetime')` `:190` `"header"/"left-calendar"/"footer"/"action"`; `cM('datetimerange')` `:196` `"header header header"/"left-calendar divider right-calendar"/"footer footer footer"/"action action action"`; `cM('month')` `:203` same as date
  - `cB('date-panel-footer')` `:209` gridArea footer; `cB('date-panel-actions')` `:212` gridArea action; `cB('date-panel-header')` `:215` gridArea header
  - `cB('date-panel-header')` `:218` box-sizing border-box, width 100%, flex space-between, padding panel-header-padding, border-bottom 1px panel-header-divider-color → `c('>')` `:226` `*:not(:last-child)` margin-right 10px; `*` flex:1 width:0; `cB('time-picker')` z-index 1
  - `cB('date-panel-month')` `:238` grid template-columns calendar-title-grid-template-columns, padding calendar-title-padding, height calendar-title-height → `cE('prev, next, fast-prev, fast-next')` `:246` line-height 0, cursor pointer, arrow-size box, color arrow-color; `cE('month-year')` `:253` user-select none, flex-grow 1, relative → `cE('text')` `:258` font-size/line-height calendar-title-font-size, font-weight calendar-title-font-weight, padding 6px 8px, center, color calendar-title-text-color, bg transition .3s, border-radius panel-border-radius → `cM('active')` `:269` + `&:hover` `:272` bg calendar-title-color-hover
  - `cB('date-panel-weekdays')` `:278` grid repeat(7, item-cell-width) × repeat(1, item-cell-height), margin-bottom 4px, border-bottom 1px calendar-days-divider-color → `cE('day')` `:288` nowrap, line-height 15px, width item-size, center, font-size calendar-days-font-size, color item-text-color
  - `cB('date-panel-dates')` `:301` grid repeat(7, item-cell-width) × repeat(6, item-cell-height) →
    - `cB('date-panel-date')` `:310` relative, item-size box, line-height item-size, font-size item-font-size, border-radius item-border-radius, z-index 0, cursor pointer, transition bg/color .2s →
      - `cE('trigger')` `:325` absolute centered cell-sized hit area
      - `cM('current')` `:332` → `cE('sup')` `:333` 4px dot top-right, bg item-color-active
      - `&::after` `:346` content "", z-index -1, full inset, border-radius inherit, bg transition .3s
      - `cM('covered, start, end')` `:356` `cNotM('excluded')` → `&::before` `:358` z-index -2, horizontal cell-width band bg item-color-included; `&:nth-child(7n+1)::before` `:368` left radii; `&:nth-child(7n+7)::before` `:373` right radii
      - `cM('selected')` `:379` color item-text-color-active → `&::after` bg item-color-active; `cM('start')` `:385` ::before left 50%; `cM('end')` `:390` ::before right 50%; `cE('sup')` `:395` bg panel-color
      - `cM('excluded')` `:400` color item-text-color-disabled → `selected` ::after bg item-color-disabled
      - `cM('disabled')` `:408` cursor not-allowed, color item-text-color-disabled → `covered` ::before bg item-color-disabled; `selected` ::before+::after bg item-color-disabled
      - `cM('week-hovered')` `:425` ::before bg item-color-included + 7n+1/7n+7 radii
      - `cM('week-selected')` `:439` color item-text-color-active, ::before bg item-color-active + 7n radii
  - `cNotM('week')` `:458` → dates→date `cNotM('disabled')`→`cNotM('selected')` `&:hover` bg item-color-hover
  - `cM('week')` `:470` → date `&::before` `:473` z-index -2 cell-width band, transition bg .3s (no bg set; week states set it)
  - `cE('vertical-divider')` `:487` gridArea divider, 1px wide, bg calendar-divider-color
  - `cB('date-panel-footer')` `:493` border-top 1px panel-action-divider-color, padding panel-extra-footer-padding
  - `cB('date-panel-actions')` `:498` flex:1, padding panel-action-padding, flex space-between, border-top 1px panel-action-divider-color → `cE('prefix, suffix')` `:506` flex, margin-bottom -8px; `suffix` `:510` align-self flex-end; `prefix` `:513` flex-wrap wrap; `cB('button')` `:516` margin-bottom 8px, `&:not(:last-child)` margin-right 8px
- `c('[data-n-date].transition-disabled')` `:536` transition none !important → `&::before, &::after` transition none !important

## (g) `date-picker/styles/light.ts` self() — exact order with values (`:18–59`)

Spread `...commonVars` first, then:
| var | value |
|---|---|
| itemFontSize | fontSize |
| calendarDaysFontSize | fontSize |
| calendarTitleFontSize | fontSize |
| itemTextColor | textColor2 |
| itemTextColorDisabled | textColorDisabled |
| itemTextColorActive | popoverColor |
| itemTextColorCurrent | primaryColor |
| itemColorIncluded | changeColor(primaryColor, {alpha: 0.1}) |
| itemColorHover | hoverColor |
| itemColorDisabled | hoverColor |
| itemColorActive | primaryColor |
| itemBorderRadius | borderRadiusSmall |
| panelColor | popoverColor |
| panelTextColor | textColor2 |
| arrowColor | iconColor |
| calendarTitleTextColor | textColor1 |
| calendarTitleColorHover | hoverColor |
| calendarDaysTextColor | textColor2 |
| panelHeaderDividerColor | dividerColor |
| calendarDaysDividerColor | dividerColor |
| calendarDividerColor | dividerColor |
| panelActionDividerColor | dividerColor |
| panelBoxShadow | boxShadow2 |
| panelBorderRadius | borderRadius |
| calendarTitleFontWeight | fontWeightStrong |
| scrollItemBorderRadius | borderRadius |
| iconColor | iconColor |
| iconColorDisabled | iconColorDisabled |

**_common.ts** (spreads first): `itemSize '24px'`, `itemCellWidth '38px'`, `itemCellHeight '32px'`, `scrollItemWidth '80px'`, `scrollItemHeight '40px'`, `panelExtraFooterPadding '8px 12px'`, `panelActionPadding '8px 12px'`, `calendarTitlePadding '0'`, `calendarTitleHeight '28px'`, `arrowSize '14px'`, `panelHeaderPadding '8px 12px'`, `calendarDaysHeight '32px'`, `calendarTitleGridTempateColumns '28px 28px 1fr 28px 28px'` (note upstream typo "Tempate"), then 22 `calendarLeftPadding*`/`calendarRightPadding*` per panel type (date/week/daterange: `'6px 12px 4px 12px'`; datetime/datetimerange: `'4px 12px'`; month/year/quarter/monthrange/quarterrange/yearrange: `'0'`; right week: `'0'`).

**dark.ts** (`:13–28`): peers dark, `self` = light self + overrides: `itemColorDisabled = composite(popoverColor, hoverColor)`, `itemColorIncluded = changeColor(primaryColor, {alpha: 0.15})`, `itemColorHover = composite(popoverColor, hoverColor)`.

## (h) Peers (`light.ts:62–67`)

`Input: inputLight, Button: buttonLight, TimePicker: timePickerLight, Scrollbar: scrollbarLight` (dark.ts mirrors with dark variants `:13–18`). TimePicker peer is what datetime panels consume via `mergedTheme.peers.TimePicker`.
