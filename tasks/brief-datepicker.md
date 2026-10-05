# BRIEF — feat(date-picker) — Task 3 of the batch

Workspace: /home/titan/Works/elm/elm-naive-ui (branch master; HEAD `5166b12` = feat(time-picker) landed with Input focus seams + NUI.TimePicker; gate green 3464/3464 + 2083 DOM). Commit directly (no worktree), explicit git add paths only, `tasks/` stays untracked.

READ FIRST:
1. tasks/recon/date-picker-3-root.md   — trigger DOM (§1 single/pair branches), panel switch (§2), cssVars 43-var order (§3), value pipeline + props + actions-default table (§§4-5), show lifecycle (§6).
2. tasks/recon/date-picker-2-single.md — panelHeader, use-calendar (click/now/quick-jump flows), date.tsx + month.tsx DOM trees, use-panel-common.
3. tasks/recon/date-picker-4-range.md  — use-dual-calendar state machine, daterange/datetimerange/monthrange DOM, handleColItemClick, shortcuts, span flags.
4. tasks/recon/date-picker-1-time.md   — §f date-picker cssr rule tree (grid areas per type), §g/§h theme; §e embedded-TimePicker conventions.
5. tasks/recon/date-picker-6-input.md  — §1 pair-mode DOM bytes + §2 activation.
6. tasks/recon/date-picker-5-elm.md    — §9 enUS locale defaults + conventions.
7. src/NUI/TimePicker.elm (HEAD) — CONVENTION TEMPLATE: how the sibling picker consumes Input seams, themes ({mode, common} record — theme modules consumed directly), cssVars emission, focusDetector, transition option, docstring punt style. Mirror it.
8. src/NUI/Internal/DateTime.elm — the pure date-time engine (delivered by the engine lane; pinned shape in tasks/brief-engine.md). READ ITS ACTUAL EXPORT LIST and use it; if a helper you need is missing or mis-shaped, extend the module ADDITIVELY (you own it in this commit).

CURRENT STATE: engine file present at src/NUI/Internal/DateTime.elm (uncommitted, from the engine lane — verify with `ls`; if absent, stop and report). Everything else clean at 5166b12.

## Deliverable 1 — src/NUI/Input.elm PAIR seam (additive, default-off; recon-6 §1)
- `--pair` root class + pair tree: `div.n-input-wrapper` [prefix slot if you add one] > `div.n-input__input` > input1 (`value` = pair[0], `placeholder` = pairPlaceholder[0], `size` attr = attrSize, inline text-decoration = pairTextDecoration[0], `tabindex -1` iff passivelyActivated && !activated) + placeholder div `n-input__placeholder`><span>; NO suffix block in wrapper1 when pair.
- `span.n-input__separator` between wrappers (separator node option; upstream default = nothing when unset).
- 2nd `div.n-input-wrapper` > `div.n-input__input` > input2 (pair[1], placeholder[1], text-decoration[1]; NO size attr) + placeholder2; then pair-only suffix `div.n-input__suffix` rendered iff clearable || suffixNode, containing the clear control iff clearable (existing clear implementation) + suffixNode.
- New options: `pairValue : Maybe (String, String)` (Nothing = not pair mode), `pairPlaceholder : Maybe (String, String)`, `pairTextDecoration : Maybe (String, String)`, `separatorNode : Maybe (Element msg)`, `onPairInput : Maybe (( String, String ) -> PairSource -> msg)` with `type PairSource = PairFirst | PairSecond | PairClear` (clear → `("","")` + PairClear; typing in input N emits the full pair with that side updated).
- Border/state-border unchanged. Standalone single-input bytes must stay identical (gate pins).

## Deliverable 2 — src/NUI/DatePicker.elm (new; expect ~1800-2200 L)
Docstring head: ported surface + punts (VirtualList windowing → full year list; justifyColumnsScrollState/scroll anchoring — Scrollbar has no scrollTo; disableTransitionOneTick one-tick toggle (cssr rule still ships via prep); IANA timeZone → Time.Zone caller-supplied; DefaultTime/Shortcuts fn-forms → static; keyboard arrow nav (upstream-dead); form-item context → direct options; onNext/PrevMonth/Year notification events punted — nav emits onUpdateCalendarValue).

Pinned core API (adapt helper names to the engine's real exports where needed):
```elm
type PanelType = Date | Datetime | Daterange | Datetimerange | Month | Year | Quarter | Monthrange | Yearrange | Quarterrange | Week
type Value = Single (Maybe Int) | Range (Maybe ( Int, Int ))
type FormattedValue = SingleF (Maybe String) | RangeF (Maybe (String, String))
type DateAction = Clear | Now | Confirm
type ShortcutValue = ShortcutSingle Int | ShortcutRange ( Int, Int )
type DefaultTime = DefaultSingle String | DefaultRange ( Maybe String, Maybe String )
type DetailType = InputDetail | DateDetail | MonthDetail | YearDetail | QuarterDetail
type DateDisabledArg = SingleDetail { type_ : DetailType, year : Int, month : Int, date : Int } | RangeDetail RangePos (Maybe (Int, Int))
type RangePos = RangeStart | RangeEnd
type CalendarSide = CalStart | CalEnd
type TimeSlot = TimeStart | TimeEnd
type alias Options msg = { ... }   -- fields below
defaultOptions : Options msg
view : Theme -> Options msg -> Element msg     -- div.n-date-picker (+--disabled, +--range iff range type) + triggerThemeClass + 3 triggerCssVars + Input single/pair per recon-3 §1
panel : Theme -> Options msg -> Element msg    -- div.n-date-panel + --{type} class + --shadow + tabindex 0 + 43 cssVars exact order + transition + per-type tree + focusDetector last child
-- pure algebra exports (upstream semantics, used by panel AND callers):
defaultActions : PanelType -> Bool -> List DateAction      -- mergedActionsRef table (recon-3 §5)
sanitizeValue : PanelType -> Int -> Int                   -- via engine startOf*; week uses weekStartsOn transform
placeholders : PanelType -> { start : String, end : String }  -- enUS table (recon-5 §9)
isRangeType : PanelType -> Bool
singleDateClick : ... -> { value : Value, close : Bool }   -- use-calendar :327-402 (defaultTime application, doClose per type)
dualDateClick : { value : Value, selecting : Bool } -> Int -> { value : Value, selecting : Bool, close : Bool, confirm : Bool }  -- use-dual-calendar :426-451 incl. closeOnSelect/updateValueOnClose branch (flags read from Options)
dualHover : { value : Value, selecting : Bool } -> Int -> Maybe Value        -- :452-468 wipPreview reversed-normalize
colItemClick : PanelType -> Value -> Int -> RangePos -> Value               -- :797-867 reversed-normalize + otherPartsChanged (justify punted)
quickMonthClick : ...                                       -- handleQuickMonthClick :403-422
singleNow : Options msg-ish -> { value : Value, close : Bool }
rangeShortcutEffect / singleShortcutEffect                  -- :492-506 / :726-745 preview/click pair semantics
```
Options fields (defaults in parens): value : Value (Single Nothing), text : Maybe String + rangeText : Maybe (String,String) (raw trigger text overrides), show : Bool (False), type_ : PanelType (Date), format : Maybe String (Nothing → per-type enUS default), valueFormat : Maybe String, separator : Maybe String, placeholder/startPlaceholder/endPlaceholder : Maybe String, size, bordered (True), clearable (False), disabled (False), status : Maybe Status, inputReadonly (False), actions : Maybe (List DateAction) (Nothing → defaultActions), shortcuts : List (String, ShortcutValue) ([]), ranges : List (String, (Int, Int)) ([] — fallback for shortcuts in range panels), isDateDisabled : Maybe (Int -> DateDisabledArg -> Bool), isTimeDisabled : Maybe (Int -> { isHourDisabled : Int -> Bool, isMinuteDisabled : Int -> Maybe Int -> Bool, isSecondDisabled : Int -> Maybe Int -> Maybe Int -> Bool }), timePickerFormat : Maybe String ('HH:mm:ss'), defaultTime : Maybe DefaultTime, firstDayOfWeek : Maybe Int (naive 0=Mon numbering; default 6 = Sunday), calendarDayFormat/calendarHeaderYearFormat/calendarHeaderMonthFormat : Maybe String, calendarHeaderMonthYearSeparator : String (" "), calendarHeaderMonthBeforeYear : Maybe Bool (True), monthFormat ('MMM') / yearFormat ('yyyy') / quarterFormat ('yyyy-qqq') : String, yearRange : (Int, Int) ((1901, 2100)), closeOnSelect (False), updateValueOnClose (False), bindCalendarMonths (False), defaultCalendarStartTime/EndTime : Maybe Int, zone : Time.Zone (Time.utc), now : Time.Posix (Time.millisToPosix 0 — examples pass real now), transition : Maybe TransitionPhase, iconNode : Maybe (Element msg).
LIFTED STATE options (caller-owned upstream refs): calendarValue : Maybe Int + startCalendarValue/endCalendarValue : Maybe Int, selecting : Bool, memorizedStart? (NOT needed — value[0] IS memorized while selecting; document), timePickerShow : Bool (single datetime), timePickerStartShow/timePickerEndShow : Bool (datetimerange), monthPanelShow : Bool (panelHeader quick-jump), hoveredWeek : Maybe Int (week type hover).
CHANNELS: onInput : Maybe (String -> msg), onPairInput : Maybe ((String,String) -> PairSource -> msg), onUpdateValue : Maybe (Value -> msg) (commit = upstream doUpdate true), onUpdatePendingValue : Maybe (Value -> msg) (preview), onUpdateFormattedValue : Maybe (FormattedValue -> msg) (derived via valueFormat), onUpdateShow : Maybe (Bool -> msg), onClear/onConfirm/onFocus/onBlur : Maybe msg, onDateClick : Maybe (Int -> msg), onDateEnter : Maybe (Int -> msg) (dual hover + week hover), onMonthItemClick : Maybe (Int -> RangePos -> msg) (monthrange/yearrange/quarterrange), onQuickMonthSelect : Maybe (Int -> msg) (panelHeader → new calendarValue), onUpdateCalendarValue : Maybe (CalendarSide -> Int -> msg) (nav arrows + quick-jump; arrows compute addMonths/addYears internally incl. dual adjustCalendarTimes/bindCalendarMonths sync), onUpdateTimePickerShow : Maybe (TimeSlot -> Bool -> msg), onUpdateMonthPanelShow : Maybe (Bool -> msg), onSelecting : Maybe (Bool -> msg).
RULE for multi-effect interactions (TimePicker @5166b12 convention): purely-value interactions (col item click in single panels, embedded time picker change, date input parse) → panel computes and emits onUpdateValue/onUpdatePendingValue directly; interactions with close/confirm/selecting side-effects (dual date click, now, confirm, shortcuts) → panel emits the narrow raw channel (onDateClick etc.) and the caller composes via the exported pure `xxxEffect` helpers; document each in the docstring.

Panel trees per type — follow recon-2 (§3 date/week incl. cell class order; §4 month/year/quarter with year NScrollbar col + month/quarter col + __padding), recon-4 (§3 daterange start/end calendars + __vertical-divider + __divider + span cell classes; §4 datetimerange 4-control header with disabled=isSelecting embedded TimePickers; §5 monthrange reusing --daterange root class; §1 datetime header NInput+NTimePicker), recon-2 §1 panelHeader (month-year text + embedded quick-jump MonthPanel actions=[] useAsQuickJump). Cell click/enter handlers per class flags; datetime range suppresses handlers on disabled cells (recon-4 §4). Actions suffix per type (date: clear+now; datetime: clear+now+confirm; ranges: clear+confirm + no now; month: clear+now+confirm; year: clear+now; quarter: clear+now+confirm; confirm disabled per validation incl. isSelecting for date-ranges). Shortcuts prefix buttons (NxButton tiny equivalents: NUI.Button size tiny) — single panels skip Array shortcuts (i.e. ShortcutRange in single panels renders nothing), range panels render both kinds; mouseenter/leave preview via pending channel + restore.
Validation derivations (uniCalendarValidation/dualCalendarValidation recon-3 §4): isDateInvalid/isValueInvalid (input detail), per-side invalids, isRangeInvalid; note upstream's own bug `second = time.getMinutes()` — PRESERVE byte-faithfully where the invalid-check logic mirrors it (document).
Trigger: single = Input + Date glyph (suffix/clearIconPlaceholder swap per TimePicker convention); range = Input PAIR + separatorNode = To glyph in `i.n-base-icon.n-date-picker-icon` (recon-3 §1 pair branch: separator prop string if set else ToIcon; suffix = DateIcon, pair branch does NOT resolve date-icon slot variant — mirror exactly). localizedPlacehoder typo irrelevant (we name it properly). textDecoration line-through per-side invalid.
Theme: NUI.Theme.DatePicker (generated @138f844) — consume like TimePicker consumes NUI.Theme.TimePicker. Month item labels / calendar month-year via engine format + enUS.

## Deliverable 3 — glyphs
Inline Svg.node helpers inside DatePicker.elm (Calendar.chevronLeft idiom): Date, To, Backward, Forward, FastBackward, FastForward — path data copied from /home/titan/Works/elm/naive-ui/src/_internal/icons/{Date,To,Backward,Forward,FastBackward,FastForward}.tsx.

## Deliverables 4-7
4. examples/src/Main.elm — `datePickerSection` (~10 demos: date, datetime, daterange, datetimerange, month, year, quarter, monthrange, week, shortcuts/clearable/sizes; static-mounted panels with show transitions like timePickerSection) + registration.
5. README.md — `| NUI.DatePicker | ✅ |`.
6. elm.json — expose NUI.DatePicker.
7. tools/verify/check-dom.mjs — `'.n-date-picker': false, '.n-date-panel': true` (+ check-classes ALLOW additions ONLY for markers upstream emits without a cssr rule — list each in your report with the upstream line ref proving no rule exists).

## Validation + commit
elm-format all touched files; `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` 8/8 green (baseline 3464/3464 + 2083 — do not regress Input/TimePicker pins). Commit `feat(date-picker): date-time engine + Input pair seam + all nine panel types` — paths: src/NUI/Internal/DateTime.elm src/NUI/DatePicker.elm src/NUI/Input.elm examples/src/Main.elm README.md elm.json tools/verify/check-dom.mjs tools/verify/check-classes.mjs.

Tool hygiene: repeat-call guard KILLS sessions issuing identical repeated tool calls — batch reads, vary queries, never re-run an identical command verbatim back-to-back. Report: commit hash, gate tail, files+line counts, every ALLOW/deviation with upstream line refs.
