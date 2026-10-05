# naive-ui v2.45.3 DatePicker SINGLE panels — byte-fidelity map (recon lane: recon-single)

## 1. panelHeader.tsx (157 L)

Props (:8–35): `mergedClsPrefix`, `value: Number`, `monthBeforeYear` (req), `monthYearSeparator` (req), `fastYearSelect`, `fastMonthSelect`, `calendarMonth` (req, String), `calendarYear` (req, String), `onUpdateValue: (value:number)=>void` (req).

Setup (:36–73): `triggerRef`, `monthPanelRef`, `showRef`; `toggleShow` (:39), `handleSelectYear` (:42 — only toggles if `fastYearSelect`), `handleSelectMonth` (:47 — only if `fastMonthSelect`), `handleClickOutside` (:52 — closes unless target inside `triggerRef`, uses `getPreciseEventTarget`), `handleHeaderClick` (:60 — always `toggleShow`).

**There is NO prev/next/fast icons here** — those live in date.tsx/month.tsx. panelHeader is only the month-year text + quick-jump popover.

DOM tree (render :74–156):
```
div.{cls}-date-panel-month__month-year   ref=triggerRef          (:76)
 └ VBinder
    ├ VTarget
    │  └ div.{cls}-date-panel-month__text                        (:88)
    │      class array: [text, show && '{cls}-date-panel-month__text--active']  (:89-92)
    │      onClick=handleHeaderClick                             (:93)
    │      children = monthBeforeYear
    │        ? [calendarMonth, monthYearSeparator, calendarYear]  (:95-99)
    │        : [calendarYear, monthYearSeparator, calendarMonth]  (:100-104)
    └ VFollower show=this.show teleportDisabled                  (:108)
       └ Transition name="fade-in-scale-up-transition" appear     (:110)
          └ show ? MonthPanel (w/ clickoutside directive) : null
```
MonthPanel quick-jump props (:117–135): `onUpdateValue` (raw, no doUpdate flag), `onSelectYear=handleSelectYear`, `onSelectMonth=handleSelectMonth`, `actions=[]`, `calendarHeaderMonthYearSeparator=monthYearSeparator`, `type="month"`, `key="month"`, `useAsQuickJump`, `value=this.value`. clickoutside directive opts `{capture: true}` (:138–141).

CSS (styles/index.cssr.ts): `month-year` :271 (`user-select:none; flex-grow:1; position:relative`), `text` :278 (`padding:6px 8px; text-align:center; cursor:pointer; transition: background-color .3s var(--n-bezier); border-radius: var(--n-panel-border-radius)`), `text--active` :290 + `&:hover` :293 → `background-color: var(--n-calendar-title-color-hover)`.

## 2. use-calendar.ts (588 L)

- `useCalendarProps` :45–54 — spreads `usePanelCommonProps`, adds `defaultCalendarStartTime: Number`, `actions` default `['now','clear','confirm']`.
- `useCalendar(props, type)` :56; injects `datePickerInjectionKey` :65–80 (validation refs, locale, firstDayOfWeek, slots, year/month/quarter formats, yearRange).
- `mergedDateFormatRef` :88 (props.dateFormat || locale.dateFormat), `mergedDayFormatRef` :91.
- **State:** `dateInputValueRef` :94 (formatted input string; '' if value null/array), `calendarValueRef` :99 (display anchor = `props.defaultCalendarStartTime ?? Date.now()` when value null/array, else value), `yearVlRef` :104, `yearScrollbarRef` :107, `monthScrollbarRef` :110, `nowRef` :113 (`Date.now()` snapshot).
- **Arrays (computed):**
  - `dateArrayRef` :114–123 → `dateArray(calendarValue, props.value, now, firstDayOfWeek ?? locale.firstDayOfWeek, strip=false, weekMode=type==='week')`.
  - `monthArrayRef` :124–133 → `monthArray(calendarValue, value|null, now, {monthFormat})` (12 items of anchor year; utils.ts:420–433).
  - `yearArrayRef` :134–144 → `yearArray(value|null, now, {yearFormat}, yearRangeRef)` (utils.ts:461–476; `range[1]-range[0]` items from `startOfYear(setYear(new Date(), range[0]))`).
  - `quarterArrayRef` :145–155 (4 items).
- `weekdaysRef` :151–159: `dateArray.slice(0,7)` formatted with `mergedDayFormat` + `dateFnsOptions` — **weekday order follows the dateArray head, i.e. weekStartsOn ordering** (first cell = startDay).
- `calendarMonthRef` :160–167 (format calendarValue w/ `calendarHeaderMonthFormat || locale.monthFormat`), `calendarYearRef` :168–175, `calendarMonthBeforeYearRef` :176–181 (`props.calendarHeaderMonthBeforeYear ?? locale.monthBeforeYear`).
- watch(calendarValue) :182–189 — `disableTransitionOneTick()` on month change for date/datetime.
- watch(props.value) :190–203 — syncs `dateInputValueRef` + `calendarValueRef` when scalar, clears input otherwise.
- `sanitizeValue(value)` :205–226 — datetime→startOfSecond, month→startOfMonth, year→startOfYear, quarter→startOfQuarter, week→`startOfWeek` with `weekStartsOn = ((firstDayOfWeek ?? locale.firstDayOfWeek) + 1) % 7)` (:215–219), default→startOfDay. Returns `getTime(...)`.
- `mergedIsDateDisabled(ts, detail)` :227–235.
- `handleDateInput(value)` :236–261 — `strictParse`; valid → `doUpdateValue(sanitizeValue(...), props.panel)`; invalid → keep raw input string.
- `handleDateInputBlur()` :262–288 — same but `doUpdateValue(..., false)`; invalid → `deriveDateInputValue()`.
- `clearSelectedDateTime()` :289–292 — clears input + `handleClearClick`.
- `handleNowClick()` :293–311 — `doUpdateValue(sanitizeValue(Date.now()), true)`, `calendarValue=now`, `doClose(true)`; if `props.panel && type in (month|quarter|year)` → `disableTransitionOneTick()` + `justifyColumnsScrollState(now)`.
- `hoveredWeekRef` :312; `handleDateMouseEnter` :313–319 (week type only), `isWeekHovered` :320–326.
- **`handleDateClick(dateItem)`** :327–402:
  1. bail if `mergedIsDateDisabled` (:328–357, detail shape per item.type date/month/year/quarter).
  2. base = `props.value` scalar else `Date.now()` (:358–363).
  3. datetime + `defaultTime` non-array: `extractSingleDefaultTime` (fn) or `getDefaultTime` → `set(newValue, time)` (:364–383).
  4. `set(newValue, dateObject)` (quarter → `setQuarter(setYear(...))`) (:384–391).
  5. `doUpdateValue(sanitizeValue(newValue), props.panel || type in ('date','week','year'))` (:392–395).
  6. switch (:396–402): date/week → `doClose()`; year → optional `disableTransitionOneTick` + `doClose()`; month/quarter → `disableTransitionOneTick()` + `justifyColumnsScrollState(newValue)` (no close).
- **`handleQuickMonthClick(dateItem, updatePanelValue)`** :403–422 — base = value||now; month→`setMonth`, else `setYear`; `updatePanelValue(newValue)` (caller passes `(v)=>props.onUpdateValue(v,false)`), then `justifyColumnsScrollState(newValue)`.
- `onUpdateCalendarValue(value)` :423–425 — sets `calendarValueRef` (used by panelHeader).
- `deriveDateInputValue(time?)` :426–444 — '' if null/array else format.
- `handleConfirmClick()` :445–451 — bail if `isDateInvalid||isTimeInvalid`; `doConfirm()`; `closeCalendar()` (:452–456 — `doClose()` only if `props.active`).
- `nextYear/prevYear/nextMonth/prevMonth` :457–473 — `addYears/addMonths(±1)` on calendarValue + optional `onNextYear/...` callbacks.
- `virtualListContainer/Content` :475–483 (yearVl listElRef/itemsElRef), `handleVirtualListScroll` :485–487 (yearScrollbar.sync()).
- `handleTimePickerChange(value)` :488–491 — `doUpdateValue(value, props.panel)`.
- `handleSingleShortcutMouseenter` :492–498 — `cachePendingValue()` + `doUpdateValue(getShortcutValue, false)` (only scalar shortcuts).
- `handleSingleShortcutClick` :499–506 — `doUpdateValue(v, props.panel)`, `clearPendingValue()`, `handleConfirmClick()`.
- **`justifyColumnsScrollState(value?)`** :507–524 — monthScrollbar `scrollTo({top: monthIndex*MONTH_ITEM_HEIGHT})` (MONTH_ITEM_HEIGHT=40, config.ts:2; index = value??mergedValue??now → `getMonth`); yearVl `scrollTo({top: (yearIndex)*MONTH_ITEM_HEIGHT})` where `yearIndex = getYear(...) - yearRange[0]`.
- Return :526–586 (all of the above + `dateArray/monthArray/yearArray/quarterArray`, `calendarYear/calendarMonth/weekdays/calendarMonthBeforeYear`, `calendarValue`, `onUpdateCalendarValue`, `dateInputValue`, `datePickerSlots`, `handleQuickMonthClick`, `justifyColumnsScrollState`, `...validation`, `...panelCommon`).

**Item data model (utils.ts):** `DateItem` :97–112 (`type:'date'`, `dateObject{date,month,year}`, `inCurrentMonth`, `isCurrentDate`, `inSpan`, `startOfSpan`, `endOfSpan`, `selected`, `inSelectedWeek`, `ts`). `dateItem()` :165–204: `selected` = matchDate(valueTs scalar or either tuple end, 'date') :184–189; `inCurrentMonth=isSameMonth(time,monthTs)` :198; `isCurrentDate=matchDate(currentTs,time,'date')` :199. `weekItem()` :231–278: `inSelectedWeek` :255–260, `selected:false`. `dateOrWeekItem()` :149–162 dispatches. **`dateArray()` utils.ts:351–418**: prev padding unshifts from `addDays(startOfMonth(monthTs),-1)` backward while `getDay(lastMonthIterator) !== startDay` (plus a `protectLastMonthDateIsShownFlag` ensuring ≥1 prev cell when `strip=false`) :359–378; then all current-month days :379–390; then pad forward to `endIndex` = 42 when `strip=false` (28/35/42 when strip) :391–409. So **single date panel always renders 42 cells, 6 rows**.

## 3. date.tsx (249 L) — type `'date' | 'week'`

setup :39–51 (DEV warn if `actions` includes 'confirm' :41–48). Render:

```
div ref=selfRef tabindex=0                                        (:62-74)
  class: ['{cls}-date-panel', '{cls}-date-panel--{type}',          (:67-72)
          !panel && '{cls}-date-panel--shadow', themeClass]
  onFocus=handlePanelFocus onKeydown=handlePanelKeyDown            (:73-74)
  style: cssVars (inherited attr from DatePicker commonPanelProps, DatePicker.tsx:994)
└ div.{cls}-date-panel-calendar                                   (:76)
   └ div.{cls}-date-panel-month                                   (:77)
      ├ div.{cls}-date-panel-month__fast-prev  onClick=prevYear    (:78-83)
      │    slot 'prev-year' | <FastBackwardIcon/>                  (:82)
      ├ div.{cls}-date-panel-month__prev  onClick=prevMonth        (:84-89)
      │    slot 'prev-month' | <BackwardIcon/>                     (:88)
      ├ <PanelHeader fastYearSelect fastMonthSelect                (:90-101)
      │    monthYearSeparator=calendarHeaderMonthYearSeparator
      │    monthBeforeYear=calendarMonthBeforeYear
      │    value=calendarValue onUpdateValue=onUpdateCalendarValue
      │    mergedClsPrefix calendarMonth calendarYear />
      ├ div.{cls}-date-panel-month__next  onClick=nextMonth        (:102-107)
      │    slot 'next-month' | <ForwardIcon/>                      (:106)
      ├ div.{cls}-date-panel-month__fast-next  onClick=nextYear    (:108-113)
      │    slot 'next-year' | <FastFastForwardIcon/> → FastForwardIcon (:112)
   ├ div.{cls}-date-panel-weekdays                                (:115)
   │   └ ×7 div.{cls}-date-panel-weekdays__day  key=weekday text   (:117-123)
   └ div.{cls}-date-panel-dates                                   (:125)
       └ ×42 div data-n-date key=i                                (:127-131)
            class: ['{cls}-date-panel-date', {                    (:132-151)
              __date--current      : dateItem.isCurrentDate        (:133-134)
              __date--selected     : dateItem.selected             (:135-136)
              __date--excluded     : !dateItem.inCurrentMonth      (:137-138)
              __date--disabled     : mergedIsDateDisabled(ts,{type:'date',year,month,date}) (:139-145)
              __date--week-hovered : isWeekHovered(dateItem)       (:146-147)
              __date--week-selected: dateItem.inSelectedWeek       (:148-149)
            }]
            onClick=handleDateClick  onMouseenter=handleDateMouseEnter (:152-157)
            ├ div.{cls}-date-panel-date__trigger  (empty)          (:159)
            ├ {dateItem.dateObject.date}  (bare number text)       (:160)
            └ isCurrentDate ? div.{cls}-date-panel-date__sup : null (:161-163)
{datePickerSlots.footer ? div.{cls}-date-panel-footer > footer() : null}  (:166-170)
{actions?.length || shortcuts ?                                  (:171)
 div.{cls}-date-panel-actions
  ├ div.{cls}-date-panel-actions__prefix                          (:173)
  │   shortcuts keys → NxButton size="tiny"                       (:175-190)
  │     onMouseenter=handleSingleShortcutMouseenter
  │     onClick=handleSingleShortcutClick
  │     onMouseleave=handleShortcutMouseleave
  │     (Array.isArray(shortcut) → null, :178)
  └ div.{cls}-date-panel-actions__suffix                          (:193)
      ├ actions includes 'clear' → slot 'clear'({onClear,text}) | NButton theme=mergedTheme.peers.Button themeOverrides size="tiny" onClick=handleClearClick > locale.clear  (:194-214)
      ├ actions includes 'now' → slot 'now'({onNow,text}) | NButton ... onClick=handleNowClick > locale.now  (:215-235)
      └ comment: no confirm button for date type                   (:236)
}
<NBaseFocusDetector onFocus=handleFocusDetectorFocus/>             (:239)
```
Note: `this.$slots.clear/now` (:196, :217) — date.tsx reads component slots; month.tsx reads `datePickerSlots`. No `--daterange` here. Week mode adds `--week` root class and CSS `week` variant (cssr :490–504).

## 4. month.tsx (314 L) — type `'month'|'year'|'quarter'`, `useAsQuickJump` flag (:32)

- `getRenderContent(item)` :37–55 → `getYearString/getMonthString/getQuarterString` (utils.ts:206–228).
- `renderItem(item, i, mergedClsPrefix)` :58–124:
```
div data-n-date key=i                                             (:64-66)
 class: ['{cls}-date-panel-month-calendar__picker-col-item',       (:67)
   isCurrent && '__picker-col-item--current',                      (:68-69)
   selected && '__picker-col-item--selected',                      (:70-71)
   !useAsQuickJump && mergedIsDateDisabled(ts, detail)             (:72-93)
     && '__picker-col-item--disabled']                             (:94)
   (detail: year→{type:'year',year}; month→{type:'month',year,month};
    quarter→{type:'month',year,month:quarter} — upstream bug preserved)
 onClick: onSelectYear?.() if year / onSelectMonth?.() if month     (:95-101)
   useAsQuickJump ? handleQuickMonthClick(item, v=>onUpdateValue(v,false))  (:102-107)
                  : handleDateClick(item)                          (:109)
 text = getRenderContent(item)                                     (:123)
```
- `onMounted` :126–128 → `justifyColumnsScrollState()` (initial scroll position).
- Render root (:139–151): same as date.tsx but `'{cls}-date-panel--month'` **always** (even for year/quarter type), `!panel && --shadow`, `themeClass`, `style` inherited.
```
div.{cls}-date-panel-month-calendar                               (:153)
 ├ NScrollbar ref=yearScrollbarRef                                (:154-163)
 │   class='{cls}-date-panel-month-calendar__picker-col'
 │   theme=peers.Scrollbar themeOverrides
 │   container=virtualListContainer content=virtualListContent
 │   horizontalRailStyle={zIndex:1} verticalRailStyle={zIndex:1}
 │   └ VirtualList ref=yearVlRef items=yearArray                  (:166-173)
 │       itemSize=MONTH_ITEM_HEIGHT(40) showScrollbar=false
 │       keyField="ts" onScroll=handleVirtualListScroll paddingBottom=4
 │       └ slot → renderItem(item,index)                          (:175-186)
 └ {type==='month'||'quarter' ?                                  (:188)
    div.{cls}-date-panel-month-calendar__picker-col               (:190-193)
     └ NScrollbar ref=monthScrollbarRef theme/themeOverrides       (:194-198)
         ├ (month? monthArray : quarterArray).map(renderItem)      (:200-203)
         └ div.{cls}-date-panel-{type}-calendar__padding           (:204-207)
            (CSS: height calc(var(--n-scroll-item-height)*5), cssr:126-128)
    : null}
{resolveWrappedSlot(datePickerSlots.footer, ...) → div.{cls}-date-panel-footer}  (:210-215)
{actions?.length || shortcuts ? div.{cls}-date-panel-actions ... : null}  (:216-306)
  prefix: same NxButton tiny shortcuts (uses datePickerSlots.clear/now/confirm)
  suffix: 'clear' NButton tiny; 'now' NButton tiny;
          'confirm' NButton tiny type="primary" disabled=isDateInvalid onClick=handleConfirmClick (:281-300)
<NBaseFocusDetector/>                                             (:308)
```

## 5. use-panel-common.ts (199 L)

- `TIME_FORMAT='HH:mm:ss'` :13. `usePanelCommonProps` :15–63 (active, dateFormat, fastYearSelect, fastMonthSelect, calendarDayFormat, calendarHeaderYearFormat, calendarHeaderMonthFormat, calendarHeaderMonthYearSeparator(req), calendarHeaderMonthBeforeYear(default undefined), timePickerFormat, value(Number|Array|null), shortcuts, defaultTime, inputReadonly, onClear, onConfirm, onClose, onTabOut, onKeydown, actions, onSelectYear, onSelectMonth, onUpdateValue(req), themeClass, onRender, panel, onNextMonth/onPrevMonth/onNextYear/onPrevYear).
- `usePanelCommon` :66: injects `datePickerInjectionKey` :68–75 (dateLocale, timePickerSize, timePickerProps, locale, mergedClsPrefix, mergedTheme); `dateFnsOptionsRef` :77–81.
- `doClear` :85; `doConfirm` :89 — `onConfirm(props.value)` (current pending value); `doUpdateValue(value, doUpdate)` :93–96 — calls `onUpdateValue(value, doUpdate)`; `doClose(disableUpdateOnClose=false)` :97–100; `doTabOut` :104.
- `handleClearClick` :108–112 — `doUpdateValue(null,true); doClose(true); doClear()`.
- `handleFocusDetectorFocus` :113–115 → doTabOut.
- `disableTransitionOneTick` :116–130 — if `active||panel`: nextTick add `.transition-disabled` to all `[data-n-date]`, force reflow (`offsetWidth`), remove.
- `handlePanelKeyDown` :132–138 (Shift+Tab on self → doTabOut), `handlePanelFocus` :139–147 (tab-out detection via relatedTarget).
- **Pending-value cache:** `cachedValue/cached` :148; `cachePendingValue` :151–154; `clearPendingValue` :155–157; `restorePendingValue` :158–163 (`doUpdateValue(cachedValue,false)` if cached); `handleShortcutMouseleave: restorePendingValue` :182.
- `getShortcutValue` :164–170 (fn → call, else literal).
- `showMonthYearPanel` ref + `handleOpenQuickSelectMonthPanel` :172–176 (toggle; used by datetime panel header).
- Return :177–196.

**Plumbing (DatePicker.tsx):** `handlePanelUpdateValue(value, doUpdate)` :524–532 — `doUpdate` true → `doUpdateValue(value,{doConfirm:false})` (commits + emits `update:value`), false → `doUpdatePendingValue` (pending only, :377–379). `handlePanelConfirm` :535–543 — commits pendingValue with `{doConfirm:true}`. `closeCalendar` :702–721 — closes; auto-confirm on close only when `type!=='date' && updateValueOnClose && !disableUpdateOnClose` (:711–716). On show→hide, `pendingValueRef = mergedValueRef` (:732–739).

## 6. cssVars / inline styles on panel roots

Panel root `style` = `cssVars` object passed via `commonPanelProps.style` (DatePicker.tsx:994) — i.e. the **full date-picker theme var set** from `cssVarsRef` (DatePicker.tsx:794–897), in this order:

`--n-bezier`, `--n-panel-border-radius`, `--n-panel-color`, `--n-panel-box-shadow`, `--n-panel-text-color`, `--n-panel-header-padding`, `--n-panel-header-divider-color`, `--n-calendar-left-padding`, `--n-calendar-right-padding` (per-type via `createKey('calendarLeftPadding', type)` :827–829), `--n-calendar-title-color-hover`, `--n-calendar-title-height`, `--n-calendar-title-padding`, `--n-calendar-title-font-size`, `--n-calendar-title-font-weight`, `--n-calendar-title-text-color`, `--n-calendar-title-grid-template-columns`, `--n-calendar-days-height`, `--n-calendar-days-divider-color`, `--n-calendar-days-font-size`, `--n-calendar-days-text-color`, `--n-calendar-divider-color`, `--n-panel-action-padding`, `--n-panel-extra-footer-padding`, `--n-panel-action-divider-color`, `--n-item-font-size`, `--n-item-border-radius`, `--n-item-size`, `--n-item-cell-width`, `--n-item-cell-height`, `--n-item-text-color`, `--n-item-color-included`, `--n-item-color-disabled`, `--n-item-color-hover`, `--n-item-color-active`, `--n-item-text-color-disabled`, `--n-item-text-color-active`, `--n-scroll-item-width`, `--n-scroll-item-height`, `--n-scroll-item-border-radius`, `--n-arrow-size`, `--n-arrow-color`, `--n-icon-color`, `--n-icon-color-disabled`.

Root classes in order (both panels): `n-date-panel`, `n-date-panel--{date|week|month}` (month.tsx hardcodes `--month`), `n-date-panel--shadow` (only when `!panel`), `themeClass` (from `useThemeClass('date-picker', type, cssVarsRef)` when inline theme disabled; otherwise vars are inline). `onRender?.()` called first in render (date.tsx:60, month.tsx:145). `NBaseFocusDetector` is always the **last** child. Root attrs: `ref=selfRef`, `tabindex=0`, `onFocus`, `onKeydown` only — no `data-*` on root; `data-n-date` is on each cell item.
