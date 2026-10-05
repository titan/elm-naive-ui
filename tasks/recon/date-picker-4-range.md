# naive-ui v2.45.3 date-picker RANGE + DATETIME panels — byte-fidelity map (recon lane: recon-range)

Paths relative to `/home/titan/Works/elm/naive-ui/src/date-picker/src/`. All line refs are exact. `use-calendar.ts`, `use-panel-common.ts`, `panelHeader.tsx`, `validation-utils.ts`, `utils.ts` pure helpers, `date.tsx`, `month.tsx`, cssr/themes/trigger are **already mapped elsewhere** — referenced only where a range/datetime file wires into them.

---

## 6. `config.ts` (15 L)

```
:2   export const MONTH_ITEM_HEIGHT = 40        // TODO: make height customizable
:4-14 type DatePickerType = 'date'|'datetime'|'daterange'|'datetimerange'|'month'|'year'|'quarter'|'monthrange'|'quarterrange'|'yearrange'|'week'
```
`MONTH_ITEM_HEIGHT` consumed by: `monthrange.tsx:143,214` (VirtualList itemSize), `use-dual-calendar.ts:758,777` (justifyColumnsScrollState elSize), `use-calendar.ts:530,539`, `month.tsx:172`.

---

## 1. `datetime.tsx` (277 L) — single datetime panel

`name: 'DateTimePanel'`, `props: useCalendarProps`, `setup → useCalendar(props, 'datetime')` (:22-28). All handlers/state come from `useCalendar` (mapped elsewhere); this file is pure render.

### Root (:36-48)
```
div[ref=selfRef, tabindex=0, onKeydown=handlePanelKeyDown, onFocus=handlePanelFocus]
  class: [ `${c}-date-panel`,
           `${c}-date-panel--datetime`,
           !this.panel && `${c}-date-panel--shadow`,
           this.themeClass ]
```

### Date-panel header (:49-77) — `div.${c}-date-panel-header`
Two children, **no** `PanelHeader` here (the date input + NTimePicker replace the month/year header; the month/year header is in the calendar body below):
1. **NInput** (:50-62) `class=${c}-date-panel-date-input`
   - `value={this.dateInputValue}` (from useCalendar `dateInputValueRef`)
   - `theme=mergedTheme.peers.Input`, `themeOverrides=peerOverrides.Input`, `stateful={false}`, `size={this.timePickerSize}`, `readonly={this.inputReadonly}`
   - `textDecoration={this.isDateInvalid ? 'line-through' : ''}`
   - `placeholder={this.locale.selectDate}`
   - `onBlur={this.handleDateInputBlur}` (`use-calendar.ts:268`), `onUpdateValue={this.handleDateInput}` (`use-calendar.ts:238`)
2. **NTimePicker** (:63-76)
   - `size={this.timePickerSize}`, `placeholder={this.locale.selectTime}`, `format={this.timePickerFormat}`
   - `{...(Array.isArray(timePickerProps) ? undefined : timePickerProps)}` — **if timePickerProps is an array it is dropped entirely** for single datetime
   - `showIcon={false}`, `to={false}`, `theme=peers.TimePicker`, `themeOverrides=peerOverrides.TimePicker`
   - `value={Array.isArray(this.value) ? null : this.value}`
   - `isHourDisabled/isMinuteDisabled/isSecondDisabled` ← single validators
   - `onUpdateValue={this.handleTimePickerChange}` (`use-calendar.ts:500-504` → `panelCommon.doUpdateValue(value, props.panel)`), `stateful={false}`

### Calendar body (:78-141) `div.${c}-date-panel-calendar`
- `div.${c}-date-panel-month` (:79-117) — 4 arrows + PanelHeader, order:
  - `div.${c}-date-panel-month__fast-prev` onClick=prevYear → slot `prev-year`/`<FastBackwardIcon/>`
  - `div.${c}-date-panel-month__prev` onClick=prevMonth → slot `prev-month`/`<BackwardIcon/>`
  - `<PanelHeader>` (:93-104): `fastYearSelect, fastMonthSelect, monthYearSeparator=calendarHeaderMonthYearSeparator, monthBeforeYear=calendarMonthBeforeYear, value=calendarValue, onUpdateValue=onUpdateCalendarValue, mergedClsPrefix, calendarMonth, calendarYear`
  - `div.${c}-date-panel-month__next` onClick=nextMonth → `<ForwardIcon/>`
  - `div.${c}-date-panel-month__fast-next` onClick=nextYear → `<FastForwardIcon/>`
- `div.${c}-date-panel-weekdays` (:118-127) → N × `div.${c}-date-panel-weekdays__day` (key=weekday)
- `div.${c}-date-panel-dates` (:128-141) → 42 × date cell (see below)

### Date cell (:130-139) — ordered class array
```
div[data-n-date, key=i, onClick=()=>handleDateClick(dateItem)]
  class: [ `${c}-date-panel-date`,
           { `${c}-date-panel-date--current`:   dateItem.isCurrentDate,
             `${c}-date-panel-date--selected`:  dateItem.selected,
             `${c}-date-panel-date--excluded`:  !dateItem.inCurrentMonth,
             `${c}-date-panel-date--disabled`:  this.mergedIsDateDisabled(dateItem.ts,
                 { type:'date', year:dateObject.year, month:dateObject.month, date:dateObject.date }) } ]
  children: div.${c}-date-panel-date__trigger, {dateItem.dateObject.date},
            isCurrentDate ? div.${c}-date-panel-date__sup : null
```
Note: single datetime passes a **detail object** to `mergedIsDateDisabled` (single-date shape) — contrast with range (passes bare `ts`).

### Footer + actions (:142-275)
- `div.${c}-date-panel-footer` only if `datePickerSlots.footer` (:143-147)
- `div.${c}-date-panel-actions` if `actions?.length || shortcuts` (:148-273):
  - `div.${c}-date-panel-actions__prefix` — shortcuts loop; **skips `Array.isArray(shortcut)`** (single only renders scalar/function shortcuts); `NxButton size=tiny`, `onMouseenter=handleSingleShortcutMouseenter`, `onClick=handleSingleShortcutClick`, `onMouseleave=handleShortcutMouseleave`
  - `div.${c}-date-panel-actions__suffix` — three conditional `NButton size=tiny`:
    - `clear` → `resolveSlotWithTypedProps(datePickerSlots.clear, {onClear: clearSelectedDateTime, text: locale.clear})` default NButton onClick=clearSelectedDateTime
    - `now` → `resolveSlotWithTypedProps(datePickerSlots.now, {onNow: handleNowClick, text: locale.now})` default NButton onClick=handleNowClick
    - `confirm` → `resolveSlotWithTypedProps(datePickerSlots.confirm, {onConfirm: handleConfirmClick, disabled: isDateInvalid, text: locale.confirm})` default `NButton type=primary disabled=isDateInvalid onClick=handleConfirmClick`
- `NBaseFocusDetector onFocus=handleFocusDetectorFocus` (:274)

---

## 2. `use-dual-calendar.ts` (951 L) — the dual state machine

### Props (:33-42) `useDualCalendarProps`
```
...usePanelCommonProps,
defaultCalendarStartTime: Number,
defaultCalendarEndTime: Number,
bindCalendarMonths: Boolean,
actions: { type: Array<string>, default: () => ['clear','confirm'] }
```
`useDualCalendar(props, type)` where `type ∈ 'daterange'|'datetimerange'|'monthrange'|'quarterrange'|'yearrange'` (:43-48).

### Injected validation refs (:49-90)
Pulls `isDateDisabledRef, isStart/EndHourDisabledRef, isStart/EndMinuteDisabledRef, isStart/EndSecondDisabledRef, isStartDateInvalidRef, isEndDateInvalidRef, isStartTimeInvalidRef, isEndTimeInvalidRef, isStartValueInvalidRef, isEndValueInvalidRef, isRangeInvalidRef, localeRef, rangesRef, closeOnSelectRef, updateValueOnCloseRef, firstDayOfWeekRef, datePickerSlots, monthFormatRef, yearFormatRef, quarterFormatRef, yearRangeRef` from `datePickerInjectionKey` (:63-83). Bundled into `validation` object (:84-97) → spread into return.

### Refs (:98-116)
`startDatesElRef, endDatesElRef, startYearScrollbarRef, endYearScrollbarRef, startYearVlRef, endYearVlRef, startMonthScrollbarRef, endMonthScrollbarRef` (:99-106).

### Calendar datetime state (:107-118)
- `defaultCalendarStartTime = props.defaultCalendarStartTime ?? (value[0] if number else Date.now())` (:107-111)
- `startCalendarDateTimeRef = ref(defaultCalendarStartTime)` (:112)
- `endCalendarDateTimeRef = ref(props.defaultCalendarEndTime ?? (value[1] if number else getTime(addMonths(defaultCalendarStartTime,1))))` (:113-118)
- `adjustCalendarTimes(true)` called immediately (:119)
- `nowRef = ref(Date.now())` (:120), `isSelectingRef = ref(false)` (:121), `memorizedStartDateTimeRef = ref(0)` (:122)

### Display strings (:124-143)
- `mergedDateFormatRef = props.dateFormat || localeRef.dateFormat` (:124-126)
- `mergedDayFormatRef = props.calendarDayFormat || localeRef.dayFormat` (:128-130)
- `startDateInput = ref(value ? format(value[0], mergedDateFormat, dateFnsOptions) : '')` (:132-139) — exposed as **`startDateDisplayString`**
- `endDateInputRef = ref(value ? format(value[1],…) : '')` (:140-147) — exposed as **`endDateInput`**

### Derived computeds (:149-256)
- `selectingPhaseRef = isSelectingRef ? 'end' : 'start'` (:149-153)
- `startDateArrayRef = dateArray(startCalendarDateTimeRef.value, props.value, nowRef, firstDayOfWeek ?? locale.firstDayOfWeek)` (:154-161) — **passes full `[start,end]` value** so span flags compute
- `endDateArrayRef = dateArray(endCalendarDateTimeRef.value, props.value, …)` (:162-169)
- `weekdaysRef = startDateArrayRef.slice(0,7).map(ts→format(ts, mergedDayFormat,…))` (:170-178) — **start array drives weekday labels for both panels**
- `startCalendarMonthRef/endCalendarMonthRef` (:179-195) format with `props.calendarHeaderMonthFormat || locale.monthFormat`
- `startCalendarYearRef/endCalendarYearRef` (:196-212) format with `props.calendarHeaderYearFormat || locale.yearFormat`
- `startTimeValueRef = Array.isArray(value) ? value[0] : null` (:213-219) → exposed `startTimeValue`
- `endTimeValueRef = Array.isArray(value) ? value[1] : null` (:220-226) → exposed `endTimeValue`
- `shortcutsRef = props.shortcuts || rangesRef.value` (:227-230) → exposed `shortcuts`
- `startYearArrayRef = yearArray(pluckValueFromRange(value,'start'), nowRef, {yearFormat}, yearRangeRef)` (:231-239); `endYearArrayRef` same for 'end' (:240-248)
- `startQuarterArrayRef = quarterArray(startValue ?? Date.now(), startValue, nowRef, {quarterFormat})` (:249-254); `endQuarterArrayRef` (:255-260)
- `startMonthArrayRef = monthArray(startValue ?? Date.now(), startValue, nowRef, {monthFormat})` (:261-266); `endMonthArrayRef` (:267-272)
- `calendarMonthBeforeYearRef = props.calendarHeaderMonthBeforeYear ?? locale.monthBeforeYear` (:273-277)

### Value watcher (:278-301)
`watch(computed(()=>props.value))`: if array → format both into `startDateInput`/`endDateInputRef`; if `!isSelectingRef` call `syncCalendarTimeWithValue(value)`; else (null) clear both strings.

### handleCalendarChange (:302-313)
`function handleCalendarChange(value, oldValue)`: for `daterange`/`datetimerange` only, if year or month changed → `panelCommon.disableTransitionOneTick()`. Wired to `watch(startCalendarDateTimeRef)` + `watch(endCalendarDateTimeRef)` (:314-315).

### adjustCalendarTimes + nav (:316-372)
- `adjustCalendarTimes(byStartCalendarTime)`: `startTime=startOfMonth(startCal)`, `endTime=startOfMonth(endCal)`; if `props.bindCalendarMonths || startTime>=endTime` → if `byStartCalendarTime` set `endCal=addMonths(startTime,1)` else set `startCal=addMonths(endTime,-1)` (:317-330)
- `startCalendarNextYear/PrevYear/NextMonth/PrevMonth` (:331-357): addMonths ±12/±1 to startCal then `adjustCalendarTimes(true)`
- `endCalendarNextYear/PrevYear/NextMonth/PrevMonth` (:358-372): addMonths to endCal then `adjustCalendarTimes(false)`
- `onUpdateStartCalendarValue(v)` (:373-376) set startCal + adjust(true); `onUpdateEndCalendarValue(v)` (:378-381) set endCal + adjust(false)

### mergedIsDateDisabled (dual detail shape) (:383-411)
`function mergedIsDateDisabled(ts): boolean` — **takes bare `ts`, no detail object** (contrast datetime single).
- no `isDateDisabled` → false
- `!Array.isArray(props.value)` → `isDateDisabled(ts, 'start', null)`
- `selectingPhaseRef==='start'` (not yet selecting) → `(ts,'start',null)`
- else (selecting): `memorizedStartDateTime = memorizedStartDateTimeRef.value`; if `ts < memorizedStartDateTime` → `(ts,'start',[memorized,memorized])` else → `(ts,'end',[memorized,memorized])`

`IsRangeDateDisabled = (timestamp, position:'start'|'end', value:[number,number]|null)=>boolean` (interface.ts:182-186).

### syncCalendarTimeWithValue (:412-424)
`[startMoment,endMoment]` → `startCal=startMoment`; if `startOfMonth(endMoment)<=startOfMonth(startMoment)` → `endCal=startOfMonth(addMonths(startMoment,1))` else `endCal=startOfMonth(endMoment)`.

### handleDateClick (start→end→complete) (:426-451)
```
if (!isSelectingRef):
  isSelectingRef=true; memorizedStartDateTimeRef=dateItem.ts
  changeStartEndTime(dateItem.ts, dateItem.ts, 'done')          // degenerate [t,t]
else:
  isSelectingRef=false
  if (props.panel && Array.isArray(value)):
    changeStartEndTime(value[0], value[1], 'done')              // commit existing pending
  else:
    if (closeOnSelectRef && type==='daterange'):                 // :437 branch
      if (updateValueOnCloseRef) closeCalendar()                 // defer to close
      else handleConfirmClick()                                  // confirm + close
```
Note: second click does **not** re-commit the clicked date — the value was already updated live via `changeStartEndTime` during mouseenter/first-click. `closeOnSelect` only fires for `daterange` (not datetimerange).

### handleDateMouseEnter (:452-468)
Only when `isSelectingRef`. If `mergedIsDateDisabled(ts)` return. If `ts>=memorizedStart` → `changeStartEndTime(memorizedStart, ts,'wipPreview')` else `changeStartEndTime(ts, memorizedStart,'wipPreview')` (handles **reversed** hover → normalizes to `[min,max]`).

### handleConfirmClick / closeCalendar (:469-481)
- `handleConfirmClick`: if `isRangeInvalidRef` return; `panelCommon.doConfirm()`; `closeCalendar()`
- `closeCalendar`: `isSelectingRef=false`; if `props.active` → `panelCommon.doClose()`

### changeStartDateTime / changeEndDateTime (:482-513)
- `changeStartDateTime(time)`: coerce to number; if `value===null` → `doUpdateValue([time,time], props.panel)`; if array → `doUpdateValue([time, Math.max(value[1],time)], props.panel)`
- `changeEndDateTime(time)`: if null → `[time,time]`; if array → `doUpdateValue([Math.min(value[0],time), time], props.panel)`

### changeStartEndTime (source semantics) (:514-560)
`changeStartEndTime(startTime, endTime, source: 'shortcutPreview'|'wipPreview'|'done'|'shortcutDone')`:
- coerce startTime to number
- **defaultTime application only when `source` NOT `shortcutPreview`/`shortcutDone`** and `type==='datetimerange'` (:522-552):
  - `defaultTime` is **function** → `startDefaultTime = extractRangeDefaultTime(startTime, defaultTime,'start',[startTime,endTime])`, `endDefaultTime = extractRangeDefaultTime(endTime, defaultTime,'end',[startTime,endTime])`
  - `defaultTime` is **array** → `startDefaultTime=getDefaultTime(defaultTime[0])`, `endDefaultTime=getDefaultTime(defaultTime[1])`
  - else (scalar) → `startDefaultTime=getDefaultTime(defaultTime)`, `endDefaultTime=startDefaultTime`
  - if present → `startTime=set(startTime,startDefaultTime)`, `endTime=set(endTime,endDefaultTime)`
- `panelCommon.doUpdateValue([startTime,endTime], props.panel && (source==='done'||source==='shortcutDone'))` (:556-559) — **doUpdate flag is true only for done/shortcutDone when in panel mode**; previews and non-panel writes pass `false` (pending only)

### sanitizeValue (:561-571)
- `datetimerange` → `startOfSecond(datetime)`
- `monthrange` → `startOfMonth(datetime)`
- else (daterange) → `startOfDay(datetime)`

### Date input handlers (:572-693)
- `handleStartDateInput(value)` (:572-601): `strictParse(value, mergedDateFormat, new Date(), dateFnsOptions)`; if valid: `props.value===null` → `set(new Date(),{year,month,date})` else `set(props.value[0],{…})`; `changeStartDateTime(sanitizeValue(getTime(newValue)))`; invalid → `startDateInput.value=value`
- `handleEndDateInput(value)` (:602-631): mirror, `set(props.value[1],…)`, `changeEndDateTime(sanitizeValue(…))`; invalid → `endDateInputRef.value=value`
- `handleStartDateInputBlur` (:632-659): re-parse; valid → same set/changeStartDateTime but `doUpdateValue` via changeStartDateTime; invalid → `refreshDisplayDateString()`
- `handleEndDateInputBlur` (:660-693): mirror with `changeEndDateTime`

### refreshDisplayDateString (:694-715)
- `value===null || !Array.isArray(value)` → `startDateInput=''`, `endDateInputRef=''`, return
- `times ??= value`; `startDateInput = format(times[0], mergedDateFormatRef, dateFnsOptions)`; `endDateInputRef = format(times[1], …)` (:706-714)

### Time picker changes (:716-725)
- `handleStartTimePickerChange(value: number|null)`: `if value===null return`; `changeStartDateTime(value)`. **doUpdate flag = `props.panel`** (true in panel mode, false as follower).
- `handleEndTimePickerChange(value)`: `if null return`; `changeEndDateTime(value)`. Same flag.
- Neither goes through `changeStartEndTime` (no defaultTime application).

### Range shortcuts (:726-745)
- `handleRangeShortcutMouseenter(shortcut)` (:726-733): `panelCommon.cachePendingValue()` (saves `props.value`, `cached=true`); `shortcutValue = panelCommon.getShortcutValue(shortcut)` (calls it if function); `if !Array.isArray(shortcutValue) return`; `changeStartEndTime(shortcutValue[0], shortcutValue[1], 'shortcutPreview')` → `doUpdateValue([s,e], props.panel && false)` = pending-only preview.
- `handleRangeShortcutClick(shortcut)` (:734-743): `getShortcutValue`; `if !Array.isArray return`; `changeStartEndTime(…, 'shortcutDone')` → `doUpdateValue([s,e], props.panel && true)`; `panelCommon.clearPendingValue()` (drop cache); `handleConfirmClick()` (:469-474: bail if `isRangeInvalidRef`; `panelCommon.doConfirm()`; `closeCalendar()` → `isSelectingRef=false`, `doClose()` if active).
- `handleShortcutMouseleave = restorePendingValue` (use-panel-common:193) reverts preview.

### justifyColumnsScrollState (dual) (:746-796)
Overloads `(value?: [number,number], type?: 'start'|'end')`; `mergedValue = value ?? props.value`.
- `value===undefined || type==='start'` (:751-768):
  - `startMonthScrollbarRef.scrollTo({debounce:false, index: monthIndex, elSize: MONTH_ITEM_HEIGHT})` — `monthIndex = Array.isArray(mergedValue) ? getMonth(mergedValue[0]) : getMonth(Date.now())` (:752-760)
  - `startYearVlRef.scrollTo({index: yearIndex, debounce:false})` — `yearIndex = (Array.isArray(mergedValue) ? getYear(mergedValue[0]) : getYear(Date.now())) - yearRangeRef.value[0]` (:761-768)
- `value===undefined || type==='end'` (:769-792): mirror with `mergedValue[1]` → `endMonthScrollbarRef` (elSize=MONTH_ITEM_HEIGHT) + `endYearVlRef` (index minus `yearRangeRef[0]`).
- No-arg call scrolls all four to `props.value` sides.

### handleColItemClick (:797-867) — month/year/quarter range
`handleColItemClick(dateItem: MonthItem|QuarterItem|YearItem, clickType: 'start'|'end')`. **No isSelecting/memorized flow** (that's date-span only) — each click writes the full `[start,end]` immediately.
- `noCurrentValue = !Array.isArray(value)` (:800)
- `itemTs` assembly (:801-817): if `dateItem.type==='year' && type!=='yearrange'` → `set(dateItem.ts, {month: getMonth(src)}).valueOf()` where `src = type==='quarterrange' ? startOfQuarter(anchor) : anchor`, `anchor = new Date()` if noCurrentValue else `value[clickType==='start'?0:1]`; else `itemTs = dateItem.ts` (month/quarter/year items already carry correct ts)
- **noCurrentValue** (:818-827): `partialValue=sanitizeValue(itemTs)`; `nextValue=[partialValue,partialValue]`; `doUpdateValue(nextValue, props.panel)`; `justifyColumnsScrollState(nextValue,'start')`; `justifyColumnsScrollState(nextValue,'end')`; `disableTransitionOneTick()`; return
- **else** (:828-840): `nextValue=[value[0],value[1]]`, `otherPartsChanged=false`:
  - `clickType==='start'`: `nextValue[0]=sanitizeValue(itemTs)`; if `nextValue[0]>nextValue[1]` → `nextValue[1]=nextValue[0]`, `otherPartsChanged=true`
  - `clickType==='end'`: `nextValue[1]=sanitizeValue(itemTs)`; if `nextValue[0]>nextValue[1]` → `nextValue[0]=nextValue[1]`, `otherPartsChanged=true`
- `doUpdateValue(nextValue, props.panel)` (:841) — flag = `props.panel`
- tail (:842-866):
  - `monthrange`/`quarterrange`: `disableTransitionOneTick()`; `otherPartsChanged` ? justify both sides : justify `clickType` only
  - `yearrange`: `disableTransitionOneTick()`; always justify both sides

### Virtual list plumbing (:868-893)
`handleStartYearVlScroll`→`startYearScrollbarRef.sync()`, `handleEndYearVlScroll`→`endYearScrollbarRef.sync()`. `virtualListContainer(type)`→`startYearVlRef.listElRef|endYearVlRef.listElRef`. `virtualListContent(type)`→`itemsElRef`.

### Return bundle (:894-950)
Exposes all above + `ranges: rangesRef`, `calendarMonthBeforeYear`, `startCalendarMonth/Year`, `endCalendarMonth/Year`, `weekdays`, `startDateArray`, `endDateArray`, `startYearArray/startMonthArray/startQuarterArray`, `endYearArray/endMonthArray/endQuarterArray`, `isSelecting`, `handleRangeShortcutMouseenter/Click`, `...panelCommon`, `...validation`, VL/scrollbar refs (as `unknown`), `startDateDisplayString: startDateInput`, `endDateInput: endDateInputRef`, `timePickerSize`, `startTimeValue`, `endTimeValue`, `datePickerSlots`, `shortcuts`, `startCalendarDateTime`, `endCalendarDateTime`, `justifyColumnsScrollState`, `handleFocusDetectorFocus`, `handleStartTimePickerChange`, `handleEndTimePickerChange`, `handleStartDateInput/Blur`, `handleEndDateInput/Blur`, `handleStartYearVlScroll`, `handleEndYearVlScroll`, `virtualListContainer`, `virtualListContent`, `onUpdateStartCalendarValue`, `onUpdateEndCalendarValue`.

---

## 3. `daterange.tsx` (341 L) — render tree

`name:'DateRangePanel'`, `props: useDualCalendarProps`, `setup → useDualCalendar(props,'daterange')` (:21-39). DEV `watchEffect` warns if `actions` includes `'now'` (:24-33).

### Root (:48-60)
```
div[ref=selfRef, tabindex=0, onKeydown=handlePanelKeyDown, onFocus=handlePanelFocus]
  class: [ `${c}-date-panel`, `${c}-date-panel--daterange`,
           !this.panel && `${c}-date-panel--shadow`, this.themeClass ]
```

### Two calendars (start + end), separated by vertical divider
- **Start** `div[ref=startDatesElRef] class=${c}-date-panel-calendar ${c}-date-panel-calendar--start` (:61-…)
- `div.${c}-date-panel__vertical-divider` (between)
- **End** `div[ref=endDatesElRef] class=${c}-date-panel-calendar ${c}-date-panel-calendar--end`

Each calendar block (identical structure, mirrored handlers):
- `div.${c}-date-panel-month` — `__fast-prev`(startCalendarPrevYear/endCalendarPrevYear), `__prev`(PrevMonth), `<PanelHeader value={startCalendarDateTime|endCalendarDateTime} onUpdateValue={onUpdateStartCalendarValue|onUpdateEndCalendarValue} calendarMonth={startCalendarMonth|endCalendarMonth} calendarYear={…} …>`, `__next`(NextMonth), `__fast-next`(NextYear). **All 4 arrows visible on both sides.**
- `div.${c}-date-panel-weekdays` → 7 × `div.${c}-date-panel-weekdays__day` (uses `this.weekdays`, shared)
- `div.${c}-date-panel__divider` (horizontal, below weekdays)
- `div.${c}-date-panel-dates` → 42 × date cell

### Date cell (daterange) — ordered class array
```
div[data-n-date, key=i, onClick=()=>handleDateClick(dateItem), onMouseenter=()=>handleDateMouseEnter(dateItem)]
  class: [ `${c}-date-panel-date`,
           { `${c}-date-panel-date--excluded`: !dateItem.inCurrentMonth,
             `${c}-date-panel-date--current`:  dateItem.isCurrentDate,
             `${c}-date-panel-date--selected`: dateItem.selected,
             `${c}-date-panel-date--covered`:  dateItem.inSpan,
             `${c}-date-panel-date--start`:    dateItem.startOfSpan,
             `${c}-date-panel-date--end`:      dateItem.endOfSpan,
             `${c}-date-panel-date--disabled`: this.mergedIsDateDisabled(dateItem.ts) } ]
  children: div.${c}-date-panel-date__trigger, {dateItem.dateObject.date},
            isCurrentDate ? div.${c}-date-panel-date__sup : null
```
`mergedIsDateDisabled(dateItem.ts)` — **bare ts** (dual shape). Both start & end arrays use the same class logic.

### Span flag semantics (utils.ts `dateItem` :167-207, referenced)
Given `valueTs: number|[number,number]|null`:
- `inSpan = valueTs[0] < time && time < valueTs[1]` (strict, exclusive)
- `startOfSpan = matchDate(valueTs[0], time, 'date')`
- `endOfSpan = matchDate(valueTs[1], time, 'date')`
- `selected = matchDate(valueTs[0],time,'date') || matchDate(valueTs[1],time,'date')`
- **Reversed ranges**: `dateArray` receives the raw `[start,end]`; span math assumes `valueTs[0]<valueTs[1]`. Reversal is normalized upstream by `changeStartEndTime`/`handleDateMouseEnter` (always emit `[min,max]`) and `handleRangeUpdateValue` (DatePicker). `dateArray` itself does not sort.

### Footer + actions (:~275-335)
- `div.${c}-date-panel-footer` if `datePickerSlots.footer`
- `div.${c}-date-panel-actions` if `actions?.length || shortcuts`:
  - `__prefix`: shortcuts loop renders button only if `Array.isArray(shortcut) || typeof shortcut==='function'`; `NxButton size=tiny onMouseenter=handleRangeShortcutMouseenter onClick=handleRangeShortcutClick onMouseleave=handleShortcutMouseleave`
  - `__suffix`: `clear` (NButton onClick=handleClearClick) + `confirm` (NButton type=primary `disabled={isRangeInvalid || isSelecting}` onClick=handleConfirmClick). **No `now` button.** Confirm slot props `{onConfirm, disabled: isRangeInvalid||isSelecting, text}`.
- `NBaseFocusDetector onFocus=handleFocusDetectorFocus`

---

## 4. `datetimerange.tsx` (430 L)

`name:'DateTimeRangePanel'`, `setup → useDualCalendar(props,'datetimerange')` (:22-38). DEV warn for `'now'` action.

### Root (:48-59)
`class: [ ${c}-date-panel, ${c}-date-panel--datetimerange, !panel && ${c}-date-panel--shadow, themeClass ]`

### Header `div.${c}-date-panel-header` (:60-135) — FOUR controls: NInput, NTimePicker, NInput, NTimePicker
1. **Start NInput** (:61-73) `class=${c}-date-panel-date-input`, `value={this.startDateDisplayString}`, `textDecoration={isStartValueInvalid?'line-through':''}`, `placeholder=locale.selectDate`, `onBlur=handleStartDateInputBlur`, `onUpdateValue=handleStartDateInput`, `size=timePickerSize`, `stateful=false`, `readonly=inputReadonly`
2. **Start NTimePicker** (:74-91): `format=timePickerFormat`, `size=timePickerSize`, `{...(Array.isArray(timePickerProps) ? timePickerProps[0] : timePickerProps)}`, `value={this.startTimeValue}`, `to=false`, `showIcon=false`, **`disabled={this.isSelecting}`**, `isHourDisabled=isStartHourDisabled`, `isMinuteDisabled=isStartMinuteDisabled`, `isSecondDisabled=isStartSecondDisabled`, `onUpdateValue=handleStartTimePickerChange`, `stateful=false`
3. **End NInput** (:92-104) `value={this.endDateInput}`, `textDecoration={isEndValueInvalid?'line-through':''}`, `onBlur=handleEndDateInputBlur`, `onUpdateValue=handleEndDateInput`
4. **End NTimePicker** (:105-122): `{...(Array.isArray(timePickerProps) ? timePickerProps[1] : timePickerProps)}`, **`disabled={this.isSelecting}`**, `value={this.endTimeValue}`, `isHour/Minute/SecondDisabled=isEnd*`, `onUpdateValue=handleEndTimePickerChange`

**timePickerProps array handling**: `timePickerProps: TimePickerProps | [TimePickerProps, TimePickerProps]` (props.ts:87-89). Array → index 0 to start picker, index 1 to end picker. Non-array → same object to both. (Single datetime drops arrays entirely — see §1.)

**isStartValueInvalid/isEndValueInvalid wiring**: `isStartValueInvalidRef = isStartDateInvalidRef || isStartTimeInvalidRef` (validation-utils:206-208); `isEndValueInvalidRef = isEndDateInvalidRef || isEndTimeInvalidRef` (:209-211); `isRangeInvalidRef = isStartValueInvalidRef || isEndValueInvalidRef` (:212-214). Used for: NInput `textDecoration` line-through (per-side) + confirm button `disabled={isRangeInvalid || isSelecting}`.

### Two calendars (:136-…)
Identical to daterange (start/end `n-date-panel-calendar--start/--end`, month arrows + PanelHeader, weekdays, `__divider`, dates ×42) **except** the date-cell `disabled` is precomputed and gates handlers:
```
const disabled = this.mergedIsDateDisabled(dateItem.ts)
div[data-n-date, onClick={disabled?undefined:()=>handleDateClick(dateItem)},
                 onMouseenter={disabled?undefined:()=>handleDateMouseEnter(dateItem)}]
  class: [ ${c}-date-panel-date, { --excluded, --current, --selected, --covered, --start, --end, --disabled: disabled } ]
```
(datetimerange suppresses click/enter on disabled cells; daterange does not.)

### Footer + actions
Same as daterange: footer slot, actions prefix (range shortcuts), suffix clear + confirm (`disabled={isRangeInvalid||isSelecting}`), no `now`, `NBaseFocusDetector`.

---

## 5. `monthrange.tsx` (343 L) — month/year/quarter range picker

`name:'MonthRangePanel'`, `props: {...useDualCalendarProps, type: String<'monthrange'|'yearrange'|'quarterrange'> required}` (:21-28). `setup → useDualCalendar(props, props.type)` + `useLocale('DatePicker')` for `dateLocaleRef` (:29-36).

### renderItem (shared, :38-78)
`renderItem(item: YearItem|MonthItem|QuarterItem, i, mergedClsPrefix, type:'start'|'end')`:
```
div[data-n-date, key=i, onClick={disabled?undefined:()=>handleColItemClick(item, type)}]
  class: [ `${c}-date-panel-month-calendar__picker-col-item`,
           item.isCurrent  && `${c}-date-panel-month-calendar__picker-col-item--current`,
           item.selected   && `${c}-date-panel-month-calendar__picker-col-item--selected`,
           disabled        && `${c}-date-panel-month-calendar__picker-col-item--disabled` ]   // disabled=false (TODO)
  text: item.type==='month'   ? getMonthString(item.dateObject.month, item.monthFormat, dateLocale)
      : item.type==='quarter' ? getQuarterString(item.dateObject.quarter, item.quarterFormat, dateLocale)
      :                         getYearString(item.dateObject.year, item.yearFormat, dateLocale)
```
`onMounted(() => useCalendarRef.justifyColumnsScrollState())` (:79-81).

### Root (:90-102)
`class: [ ${c}-date-panel, ${c}-date-panel--daterange,  !panel && ${c}-date-panel--shadow, themeClass ]` — **reuses `--daterange` modifier** (no `--monthrange` class).

### Two `n-date-panel-calendar--start/--end` blocks, each `div.${c}-date-panel-month-calendar`
Per side (start shown; end mirrors refs/arrays):
- **Year column** `NScrollbar[ref=startYearScrollbarRef] class=${c}-date-panel-month-calendar__picker-col` (`container=()=>virtualListContainer('start')`, `content=()=>virtualListContent('start')`, `horizontalRailStyle={zIndex:1}`, `verticalRailStyle={zIndex:1}`) wrapping `VirtualList[ref=startYearVlRef] items={startYearArray} itemSize={MONTH_ITEM_HEIGHT} showScrollbar=false keyField='ts' onScroll=handleStartYearVlScroll paddingBottom={4}` → `renderItem(item,index,cls,'start')` (:113-171)
- **Month/Quarter column** (only if `type==='monthrange'||type==='quarterrange'`) `div.${c}-date-panel-month-calendar__picker-col` wrapping `NScrollbar[ref=startMonthScrollbarRef]` → `(type==='monthrange'?startMonthArray:startQuarterArray).map(renderItem)` + (monthrange only) `div.${c}-date-panel-month-calendar__padding` (:172-211)

`div.${c}-date-panel__vertical-divider` between start/end.

### Footer + actions (:275-335)
- footer via `resolveWrappedSlot(datePickerSlots.footer, …)` → `div.${c}-date-panel-footer`
- actions prefix: range shortcuts (array/function) `NxButton` with `handleRangeShortcutMouseenter/Click/Mouseleave`
- actions suffix: `clear` (**NxButton** here, not NButton) + `confirm` (NxButton type=primary `disabled={isRangeInvalid}` onClick=handleConfirmClick). **Confirm only — no `now`.** Note confirm disabled is `isRangeInvalid` only (no `isSelecting`, since no date-span selection).
- `NBaseFocusDetector onFocus=handleFocusDetectorFocus`

---

## 7. `DatePicker.tsx` — range-specific wiring (gaps filled)

### ranges prop flow
- `props.ranges: Record<string,[number,number]>` (props.ts:82) → `rangesRef: toRef(props,'ranges')` (DatePicker.tsx:752) → injected → `shortcutsRef = props.shortcuts || rangesRef` (use-dual-calendar:227-230) → exposed as `shortcuts` to panels. So `ranges` is the fallback for `shortcuts`.
- `timePickerPropsRef: toRef(props,'timePickerProps')` (:753) → injected → `panelCommon.timePickerProps` → spread into NTimePicker per §1/§4.

### bindCalendarMonths / defaultCalendarStartTime / EndTime
- Declared in `datePickerProps` (props.ts:92-94) and again in `useDualCalendarProps` (use-dual-calendar:36-38).
- Render wiring (DatePicker.tsx renderPanel):
  - `DatetimePanel` gets `defaultCalendarStartTime` only (:1020)
  - `DaterangePanel` gets `defaultCalendarStartTime`, `defaultCalendarEndTime`, `bindCalendarMonths` (:1027-1029)
  - `DatetimerangePanel` gets all three (:1036-1038)
  - `MonthRangePanel` gets `{...commonPanelProps} type` only (:1047) — **no** calendar-start/end/bind props
  - `DatePanel` gets `defaultCalendarStartTime` (:1052)
- Consumed in `useDualCalendar` (:107-119, :316-330) — see §2.

### handleRangeUpdateValue source semantics (DatePicker.tsx:635-680)
`handleRangeUpdateValue(v:[string,string], {source}:{source:0|1|'clear'})`:
- if `v[0]==='' && v[1]===''` → `doUpdateValue(null,{doConfirm:false})`, `pendingValueRef=null`, clear both range input strings, return (:639-646)
- `newStartTime=strictParse(startTime, mergedFormat, new Date(), dateFnsOptions)`, `newEndTime=strictParse(endTime,…)` (:647-659)
- if both valid: `newStartTs=getTime(newStartTime)`, `newEndTs=getTime(newEndTime)`; **if `newEndTime<newStartTs`**: `source===0` (start edited) → `newEndTs=newStartTs`; else (source 1) → `newStartTs=newEndTs` (:660-670) — normalizes reversed pair based on which input was edited
- `doUpdateValue([newStartTs,newEndTs],{doConfirm:false})`, `deriveInputState()` (:671-675)
- invalid → falls through (no state change; input keeps typed text via `deriveInputState` on pendingValue watch)

`source` is `0|1|'clear'` from the pair NInput's `onUpdateValue`. `deriveRangeInputState` (:570-588) reformats `pendingValue` into `rangeStartInputValueRef`/`rangeEndInputValueRef` (→ `displayStartTime`/`displayEndTime` on the trigger).

### datetimerange timePickerProps array
Handled entirely in `datetimerange.tsx` render (§4): `Array.isArray(timePickerProps) ? timePickerProps[0]/[1] : timePickerProps`. `DatePicker.tsx` just passes `timePickerProps` through `timePickerPropsRef` (no array splitting at the DatePicker level).

### mergedActionsRef defaults (range) (:~280-320)
`daterange`/`datetimerange`/`monthrange`/`yearrange`/`quarterrange` → `['clear'?, 'confirm']` (never `'now'`). `datetime` → `['clear'?,'now','confirm']`.

---

## Cross-file handler/state summary (dual)

| Concern | Location |
|---|---|
| `startCalendarDateTimeRef`/`endCalendarDateTimeRef` | use-dual-calendar:112-118 |
| `isSelectingRef` / `selectingPhaseRef` / `memorizedStartDateTimeRef` | :121, :149-153, :122 |
| `startDateInput`(→`startDateDisplayString`) / `endDateInputRef`(→`endDateInput`) | :132-147 |
| span flags `inSpan/startOfSpan/endOfSpan/selected` | utils.ts:173-204 |
| `dateArray` (42 cells, first-day-of-week) | utils.ts:351-418 |
| `monthArray/quarterArray/yearArray` (dual, per-side valueTs) | utils.ts:420-478 |
| `handleDateClick` (start→end→complete, closeOnSelect/updateValueOnClose) | use-dual-calendar:426-451 |
| `handleDateMouseEnter` (wipPreview, reversed normalize) | :452-468 |
| `changeStartEndTime` (source + defaultTime/extractRangeDefaultTime) | :514-560 |
| `sanitizeValue` (startOfSecond/startOfMonth/startOfDay) | :561-571 |
| `mergedIsDateDisabled` (dual detail: `(ts,'start'|'end',[mem,mem])`) | :383-411 |
| `handleColItemClick` (month/year/quarter range start/end/complete) | :797-867 |
| `justifyColumnsScrollState` (dual, MONTH_ITEM_HEIGHT) | :746-796 |
| `adjustCalendarTimes`/bindCalendarMonths sync | :316-330 |
| `handleRangeShortcutMouseenter/Click` (cachePendingValue/getShortcutValue) | :726-745 |
| `extractRangeDefaultTime`/`getDefaultTime`/`pluckValueFromRange` | utils.ts:511-554 |
