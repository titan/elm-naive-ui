module NUI.DatePicker exposing (CalendarSide(..), ClickTarget, DateAction(..), DateDisabledArg(..), DefaultTime(..), DetailType(..), FormattedValue(..), Options, PanelType(..), RangePos(..), ShortcutPhase(..), ShortcutValue(..), TimeSlot(..), Value(..), colItemClick, defaultActions, defaultOptions, dualDateClick, dualHover, isRangeType, panel, placeholders, quickMonthClick, rangeShortcutEffect, sanitizeValue, singleDateClick, singleNow, singleShortcutEffect, view)

{-| Naive UI's `DatePicker` — one `NUI.Input` trigger (single or pair) plus a
caller-mounted panel covering every upstream panel type (`date`, `week`,
`datetime`, `daterange`, `datetimerange`, `month`, `year`, `quarter`,
`monthrange`, `yearrange`, `quarterrange`).

    import NUI.DatePicker as DatePicker

    DatePicker.view theme
        { DatePicker.defaultOptions
            | value = DatePicker.Single (Just model.ts)
            , onUpdateValue = Just SetValue
        }

    -- the body is a separate element — mount it yourself when `show`
    DatePicker.panel theme
        { DatePicker.defaultOptions | value = DatePicker.Single (Just model.ts) }

Essential contract: `show`, closing, positioning and form context are
caller-owned (the panel never emits `onUpdateShow`). Purely-value
interactions commit through `onUpdateValue` / `onUpdatePendingValue`;
side-effectful ones (dual clicks / hovers, month-range items, the quick
jump, the nav arrows) emit the narrow raw channel — `onDateClick` /
`onDateEnter` / `onMonthItemClick` / `onUpdateCalendarValue` — which the
exported pure helpers (`dualDateClick`, `dualHover`, `colItemClick`,
`quickMonthClick`) compose, their `close` flag saying when the panel
closes. One message per event: a commit emits `onUpdateValue` when set,
else `onUpdateFormattedValue`.

Trigger/panel DOM shapes and porting notes live in the comment block below
the module doc.

@docs CalendarSide, ClickTarget, DateAction, DateDisabledArg, DefaultTime, DetailType, FormattedValue, Options, PanelType, RangePos, ShortcutPhase, ShortcutValue, TimeSlot, Value, colItemClick, defaultActions, defaultOptions, dualDateClick, dualHover, isRangeType, panel, placeholders, quickMonthClick, rangeShortcutEffect, sanitizeValue, singleDateClick, singleNow, singleShortcutEffect, view

-}

{- DOM shapes and porting notes for `NUI.DatePicker` — moved verbatim out of the
      module docstring (docs.json must stay under elm publish's 768kb limit);
      plain comments do not enter the published API docs.

   Trigger (`view`) DOM:

       div.n-date-picker [--disabled] [--range]
         style = 3 trigger vars → --n-bezier, --n-icon-color-override,
                 --n-icon-color-disabled-override
         └─ NUI.Input.view with the picker seams on:
            single → the date glyph rides `suffix` (not clearable) or
                     `clear-icon-placeholder` (clearable) inside
                     `i.n-base-icon.n-date-picker-icon`;
            range  → pair mode, `separatorNode` = the `separator` string or the
                     `To` glyph, and the pair suffix = the `Date` glyph.

   Panel (`panel`) DOM — `div.n-date-panel` + `--{date|week|month|datetime|
   daterange|datetimerange}` + `--shadow`, `tabindex 0`, the 43 panel vars in
   upstream declaration order, the per-type tree and the inert focus detector last.

   Channel rule for interactions (the `NUI.TimePicker` convention):

     - **purely-value** (single-panel cell click, embedded time-picker change) →
       the panel computes the value and emits `onUpdateValue` (commit) or
       `onUpdatePendingValue` (preview);
     - **side-effectful** (dual date click / hover, month-range item click, the
       quick-jump header, nav arrows) → the panel emits the narrow raw channel
       (`onDateClick` / `onDateEnter` / `onMonthItemClick` / `onUpdateCalendarValue`)
       and the caller composes with the exported pure helpers (`dualDateClick`,
       `dualHover`, `colItemClick`, `quickMonthClick`).

   `show`, closing and positioning stay caller-owned: the panel never emits
   `onUpdateShow` (a DOM event carries one message, and the value travels on
   `onUpdateValue`); the exported pure helpers return a `close` flag telling the
   caller when closing is due (`singleDateClick`, `dualDateClick`).

   **Punts (caller-owned runtime, the port-wide convention).**

     - `VirtualList` windowing → the year column renders the full `yearArray`
       inside `NUI.Scrollbar` (the `NUI.TreeSelect` precedent).
     - `justifyColumnsScrollState` / scroll anchoring → `NUI.Scrollbar` has no
       `scrollTo`; the initial scroll position is caller-owned (the panel still
       emits `onUpdateCalendarValue` for the nav arrows and the quick jump).
     - `disableTransitionOneTick` (the one-tick `[data-n-date].transition-disabled`
       toggle, `use-panel-common.ts:116-130`) is a DOM-timing effect with no static
       equivalent; its cssr rule ships from the prep commit.
     - The IANA `timeZone` prop → `zone : Time.Zone` (caller supplied, `Time.utc`
       by default), exactly like `NUI.TimePicker`.
     - Function-form `DefaultTime` / `Shortcuts` and `ranges`-as-functions →
       static (`DefaultTime` carries literal `'HH:mm:ss'` strings; `ranges` is a
       `List`).
     - Keyboard arrow navigation (`getDerivedTimeFromKeyboardEvent`, `utils.ts:33`)
       is dead upstream (`DatePicker.tsx:472` is commented out).
     - Form-item context, `to` / `placement` / clickoutside / Enter-Escape
       activation / programmatic focus: caller-owned (no ports in house style).
     - `onNextMonth` / `onPrevMonth` / `onNextYear` / `onPrevYear` notification
       props → the nav arrows emit `onUpdateCalendarValue` with the computed
       anchor (the caller sees every change; the redundant per-arrow callbacks are
       not carried).
     - The panel's `footer` slot has no Elm counterpart; the header's quick-jump
       `MonthPanel` renders inline when `monthPanelShow` (no `VFollower`), and the
       datetime panels' embedded time pickers render their bodies inline after the
       trigger (no teleport).
     - A single Elm message cannot carry both the value and the formatted value:
       a commit emits `onUpdateValue` when set, else `onUpdateFormattedValue`
       (`NUI.TimePicker` precedent).
     - Multi-effect interactions emit ONE message: the panel's `clear` button
       emits `onClear` when set (else a committed empty value); cell clicks emit
       the value and the caller closes when the pure helper's `close` says so.
     - `[oracle D]` **R3 — date-input envelope.** The embedded date `NInput`s
       hardcode `"yyyy-MM-dd"`; upstream uses `props.dateFormat ||
       locale.dateFormat`. Matches the en-US default; no `dateFormat` option
       surface — punted.
     - `[oracle D]` **R4 — `timePickerProps` passthrough.** The embedded time
       pickers use fixed props (`embeddedTimeOptions`); upstream spreads
       `timePickerProps` (object) / `[0]`/`[1]` (array) per slot
       (`datetime.tsx:63-76`, `datetimerange.tsx:74-122`). Needs a per-slot
       options override surface — punted.

   **Upstream-faithful oddities kept on purpose.**

     - `uniCalendarValidation.isTimeInvalid` reads `second = time.getMinutes()`
       (`validation-utils.ts:55`) — the datetime panel's time-invalid check uses
       the minute in place of the second.
     - `month.tsx:83-92` passes `{ type: 'month', year, month: quarter }` as the
       disabled detail of a quarter cell (the discriminator is `'month'` and the
       quarter rides the `month` field).
     - A `daterange` / `datetimerange` confirm button is disabled while `selecting`
       (`daterange.tsx` `isRangeInvalid || isSelecting`).
     - `monthrange` / `quarterrange` sanitize with `startOfDay` upstream
       (`use-dual-calendar.ts:561-571`).
     - Several emitted classes have no upstream cssr rule and are `ALLOW`-listed in
       `tools/verify/check-classes.mjs`: `n-date-picker--range`,
       `n-date-panel-calendar--start`, `n-date-panel__divider`,
       `n-date-panel-date-input`,
       `n-date-panel-month-calendar__picker-col-item--current`,
       `n-date-panel-quarter-calendar__padding`.
     - `[oracle D]` **R1 — week format tokens.** `w` / `YYYY` use
       `weekStartsOn = 0`, correct: upstream never threads `firstDayOfWeek` into
       `format` (v2.45.3, date-fns v4 en-US = `{ weekStartsOn: 0,
       firstWeekContainsDate: 1 }`). The real week defect is S2 (fwcd 4→1).
     - `[oracle D]` **R2 — pair date-icon slot.** The pair suffix honors the
       caller's `iconNode` (`dateGlyphNode`), whereas upstream pair mode renders a
       fixed `DateIcon` and ignores the `date-icon` slot (`DatePicker.tsx`
       :1124-1135) — an upstream bug the port supersets; DOM-identical when the
       slot is unset.
     - `[oracle D]` **R5 — quick-jump routing.** `onQuickMonthSelect` (side-less)
       is an additive channel that wins when set; when unset the panel emits
       `onUpdateCalendarValue side anchor`, matching upstream's per-side
       `onUpdateValue` routing — faithful when unused.
     - `[oracle D]` **R8-minor — textDecoration asymmetry.** The single trigger
       binds `textDecoration = Nothing` when the value is valid, whereas upstream
       always binds it (`''` / `line-through`), so a valid single input may omit an
       empty inline `style`. Zero visual impact.
-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import NUI.Button as Button
import NUI.Input as Input
import NUI.Internal as I
import NUI.Internal.DateTime as DT
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.DatePicker as DPTheme
import NUI.TimePicker as TimePicker
import NUI.Types as T
import Svg
import Time



-- TYPES ------------------------------------------------------------------------


{-| Upstream's eleven `type` values.
-}
type PanelType
    = Date
    | Datetime
    | Daterange
    | Datetimerange
    | Month
    | Year
    | Quarter
    | Monthrange
    | Yearrange
    | Quarterrange
    | Week


{-| Upstream `Value` (`number | [number, number] | null`).
-}
type Value
    = Single (Maybe Int)
    | Range (Maybe ( Int, Int ))


{-| Upstream `FormattedValue` (`string | [string, string] | null`).
-}
type FormattedValue
    = SingleF (Maybe String)
    | RangeF (Maybe ( String, String ))


{-| Upstream's panel `actions`.
-}
type DateAction
    = Clear
    | Now
    | Confirm


{-| Upstream `Shortcuts[string]` restricted to literal scalars / pairs.
-}
type ShortcutValue
    = ShortcutSingle Int
    | ShortcutRange ( Int, Int )


{-| Upstream `DefaultTime` restricted to the literal forms.
-}
type DefaultTime
    = DefaultSingle String
    | DefaultRange ( Maybe String, Maybe String )


{-| The discriminator of upstream `IsSingleDateDisabledDetail`.
-}
type DetailType
    = InputDetail
    | DateDetail
    | MonthDetail
    | YearDetail
    | QuarterDetail


{-| Which side of a range.
-}
type RangePos
    = RangeStart
    | RangeEnd


{-| Upstream `IsSingleDateDisabled | IsRangeDateDisabled`, collapsed into one
union: a single-panel detail object, or the range `(ts, 'start'|'end', value)`
shape.
-}
type DateDisabledArg
    = SingleDetail { type_ : DetailType, year : Int, month : Int, date : Int }
    | RangeDetail RangePos (Maybe ( Int, Int ))


{-| Which calendar of a dual panel (start / end).
-}
type CalendarSide
    = CalStart
    | CalEnd


{-| Which embedded time picker of a datetime-range panel.
-}
type TimeSlot
    = TimeStart
    | TimeEnd


{-| Preview vs commit phase of a shortcut hover / click pair.
-}
type ShortcutPhase
    = ShortcutPreview
    | ShortcutDone


{-| A clicked cell, normalized across granularities. `ts` is the cell's own
timestamp; the civil fields are what the click sets on the base value
(`use-calendar.ts:384-391`).
-}
type alias ClickTarget =
    { ts : Int
    , year : Int
    , month : Int
    , day : Int
    , quarter : Int
    }


{-| Every knob — upstream's props, slots and panel state on one record (the
`NUI.TimePicker` convention). Runtime behaviour (show, positioning,
activation, keyboard, clickoutside) is caller-owned — see the module
docstring.
-}
type alias Options msg =
    { value : Value
    , text : Maybe String
    , rangeText : Maybe ( String, String )
    , show : Bool
    , type_ : PanelType
    , format : Maybe String
    , valueFormat : Maybe String
    , separator : Maybe String
    , placeholder : Maybe String
    , startPlaceholder : Maybe String
    , endPlaceholder : Maybe String
    , size : T.Size
    , bordered : Bool
    , clearable : Bool
    , disabled : Bool
    , status : Maybe Input.Status
    , inputReadonly : Bool
    , actions : Maybe (List DateAction)
    , shortcuts : List ( String, ShortcutValue )
    , ranges : List ( String, ( Int, Int ) )
    , isDateDisabled : Maybe (Int -> DateDisabledArg -> Bool)
    , isTimeDisabled : Maybe (Int -> { isHourDisabled : Int -> Bool, isMinuteDisabled : Int -> Maybe Int -> Bool, isSecondDisabled : Int -> Maybe Int -> Maybe Int -> Bool })
    , timePickerFormat : Maybe String
    , defaultTime : Maybe DefaultTime
    , firstDayOfWeek : Maybe Int
    , calendarDayFormat : Maybe String
    , calendarHeaderYearFormat : Maybe String
    , calendarHeaderMonthFormat : Maybe String
    , calendarHeaderMonthYearSeparator : String
    , calendarHeaderMonthBeforeYear : Maybe Bool
    , monthFormat : String
    , yearFormat : String
    , quarterFormat : String
    , yearRange : ( Int, Int )
    , closeOnSelect : Bool
    , updateValueOnClose : Bool
    , bindCalendarMonths : Bool
    , defaultCalendarStartTime : Maybe Int
    , defaultCalendarEndTime : Maybe Int
    , zone : Time.Zone
    , now : Time.Posix
    , transition : Maybe I.TransitionPhase
    , iconNode : Maybe (Element msg)
    , calendarValue : Maybe Int
    , startCalendarValue : Maybe Int
    , endCalendarValue : Maybe Int
    , selecting : Bool
    , timePickerShow : Bool
    , timePickerStartShow : Bool
    , timePickerEndShow : Bool
    , monthPanelShow : Bool
    , hoveredWeek : Maybe Int
    , onInput : Maybe (String -> msg)
    , onPairInput : Maybe (( String, String ) -> Input.PairSource -> msg)
    , onUpdateValue : Maybe (Value -> msg)
    , onUpdatePendingValue : Maybe (Value -> msg)
    , onUpdateFormattedValue : Maybe (FormattedValue -> msg)
    , onUpdateShow : Maybe (Bool -> msg)
    , onClear : Maybe msg
    , onConfirm : Maybe msg
    , onFocus : Maybe msg
    , onBlur : Maybe msg
    , onDateClick : Maybe (Int -> msg)
    , onDateEnter : Maybe (Int -> msg)
    , onMonthItemClick : Maybe (Int -> RangePos -> msg)
    , onQuickMonthSelect : Maybe (Int -> msg)
    , onUpdateCalendarValue : Maybe (CalendarSide -> Int -> msg)
    , onUpdateTimePickerShow : Maybe (TimeSlot -> Bool -> msg)
    , onUpdateMonthPanelShow : Maybe (Bool -> msg)
    , onSelecting : Maybe (Bool -> msg)
    }


{-| Naive UI's defaults with the en-US locale inlined (the port ships no locale
layer): `date` / `daterange` → `'yyyy-MM-dd'`, `datetime` / `datetimerange` →
`'yyyy-MM-dd HH:mm:ss'`, `year` / `yearrange` → `'yyyy'`, `month` /
`monthrange` → `'yyyy-MM'`, `quarter` / `quarterrange` → `'yyyy-qqq'`, `week` →
`'YYYY-w'`; `monthFormat 'MMM'`, `yearFormat 'yyyy'`, `quarterFormat
'yyyy-qqq'`, `yearRange (1901, 2100)`, `firstDayOfWeek 6` (Sunday),
`calendarHeaderMonthBeforeYear True`, `timePickerFormat 'HH:mm:ss'`.
-}
defaultOptions : Options msg
defaultOptions =
    { value = Single Nothing
    , text = Nothing
    , rangeText = Nothing
    , show = False
    , type_ = Date
    , format = Nothing
    , valueFormat = Nothing
    , separator = Nothing
    , placeholder = Nothing
    , startPlaceholder = Nothing
    , endPlaceholder = Nothing
    , size = T.Medium
    , bordered = True
    , clearable = False
    , disabled = False
    , status = Nothing
    , inputReadonly = False
    , actions = Nothing
    , shortcuts = []
    , ranges = []
    , isDateDisabled = Nothing
    , isTimeDisabled = Nothing
    , timePickerFormat = Just "HH:mm:ss"
    , defaultTime = Nothing
    , firstDayOfWeek = Just 6
    , calendarDayFormat = Nothing
    , calendarHeaderYearFormat = Nothing
    , calendarHeaderMonthFormat = Nothing
    , calendarHeaderMonthYearSeparator = " "
    , calendarHeaderMonthBeforeYear = Nothing
    , monthFormat = "MMM"
    , yearFormat = "yyyy"
    , quarterFormat = "yyyy-qqq"
    , yearRange = ( 1901, 2100 )
    , closeOnSelect = False
    , updateValueOnClose = False
    , bindCalendarMonths = False
    , defaultCalendarStartTime = Nothing
    , defaultCalendarEndTime = Nothing
    , zone = Time.utc
    , now = Time.millisToPosix 0
    , transition = Nothing
    , iconNode = Nothing
    , calendarValue = Nothing
    , startCalendarValue = Nothing
    , endCalendarValue = Nothing
    , selecting = False
    , timePickerShow = False
    , timePickerStartShow = False
    , timePickerEndShow = False
    , monthPanelShow = False
    , hoveredWeek = Nothing
    , onInput = Nothing
    , onPairInput = Nothing
    , onUpdateValue = Nothing
    , onUpdatePendingValue = Nothing
    , onUpdateFormattedValue = Nothing
    , onUpdateShow = Nothing
    , onClear = Nothing
    , onConfirm = Nothing
    , onFocus = Nothing
    , onBlur = Nothing
    , onDateClick = Nothing
    , onDateEnter = Nothing
    , onMonthItemClick = Nothing
    , onQuickMonthSelect = Nothing
    , onUpdateCalendarValue = Nothing
    , onUpdateTimePickerShow = Nothing
    , onUpdateMonthPanelShow = Nothing
    , onSelecting = Nothing
    }



-- PURE ALGEBRA (upstream semantics; used by the panel AND by callers) ----------


{-| Upstream `mergedActionsRef` (`DatePicker.tsx:277-348`): `clear` first (iff
`clearable`), then the per-type tail.
-}
defaultActions : PanelType -> Bool -> List DateAction
defaultActions type_ clearable =
    let
        base =
            if clearable then
                [ Clear ]

            else
                []
    in
    case type_ of
        Date ->
            base ++ [ Now ]

        Week ->
            base ++ [ Now ]

        Datetime ->
            base ++ [ Now, Confirm ]

        Daterange ->
            base ++ [ Confirm ]

        Datetimerange ->
            base ++ [ Confirm ]

        Month ->
            base ++ [ Now, Confirm ]

        Year ->
            base ++ [ Now ]

        Quarter ->
            base ++ [ Now, Confirm ]

        Monthrange ->
            base ++ [ Confirm ]

        Yearrange ->
            base ++ [ Confirm ]

        Quarterrange ->
            base ++ [ Confirm ]


{-| Upstream `isRangeRef` (`DatePicker.tsx:210-216`).
-}
isRangeType : PanelType -> Bool
isRangeType type_ =
    List.member type_ [ Daterange, Datetimerange, Monthrange, Yearrange, Quarterrange ]


{-| Upstream per-panel `sanitizeValue`, in `Time.utc` (the exported form; the
panel applies the caller's zone internally). The dual panels' tail is
upstream's: `datetimerange` → `startOfSecond`, `monthrange` → `startOfMonth`,
everything else → `startOfDay` (so `yearrange` / `quarterrange` keep
`startOfDay`, `use-dual-calendar.ts:561-571`).
-}
sanitizeValue : PanelType -> Int -> Int
sanitizeValue =
    sanitizeValueIn Time.utc


sanitizeValueIn : Time.Zone -> PanelType -> Int -> Int
sanitizeValueIn zone type_ ts =
    case type_ of
        Datetime ->
            DT.startOfSecond zone ts

        Datetimerange ->
            DT.startOfSecond zone ts

        Month ->
            DT.startOfMonth zone ts

        Monthrange ->
            DT.startOfMonth zone ts

        Year ->
            DT.startOfYear zone ts

        Quarter ->
            DT.startOfQuarter zone ts

        Week ->
            DT.startOfWeek zone ts

        Date ->
            DT.startOfDay zone ts

        Daterange ->
            DT.startOfDay zone ts

        Yearrange ->
            DT.startOfDay zone ts

        Quarterrange ->
            DT.startOfDay zone ts


{-| The en-US start / end placeholder pair (`locales/common/enUS.ts`
`DatePicker`). Single-panel types carry no range placeholder (empty strings).
-}
placeholders : PanelType -> { start : String, end : String }
placeholders type_ =
    case type_ of
        Daterange ->
            { start = "Start Date", end = "End Date" }

        Datetimerange ->
            { start = "Start Date and Time", end = "End Date and Time" }

        Monthrange ->
            { start = "Start Month", end = "End Month" }

        _ ->
            { start = "", end = "" }


{-| The merged display format (`DatePicker.tsx:143-163`), with the en-US locale
values inlined.
-}
mergedFormat : Options msg -> String
mergedFormat opts =
    case opts.format of
        Just f ->
            f

        Nothing ->
            case opts.type_ of
                Date ->
                    "yyyy-MM-dd"

                Daterange ->
                    "yyyy-MM-dd"

                Datetime ->
                    "yyyy-MM-dd HH:mm:ss"

                Datetimerange ->
                    "yyyy-MM-dd HH:mm:ss"

                Year ->
                    "yyyy"

                Yearrange ->
                    "yyyy"

                Month ->
                    "yyyy-MM"

                Monthrange ->
                    "yyyy-MM"

                Quarter ->
                    "yyyy-qqq"

                Quarterrange ->
                    "yyyy-qqq"

                Week ->
                    "YYYY-w"


{-| Upstream `use-calendar.handleDateClick` (`:327-402`) as a pure function:
the new value plus whether the panel should close.
-}
singleDateClick :
    { type_ : PanelType
    , value : Value
    , target : ClickTarget
    , isDisabled : Bool
    , defaultTime : Maybe DefaultTime
    , now : Int
    , zone : Time.Zone
    }
    -> { value : Value, close : Bool }
singleDateClick cfg =
    if cfg.isDisabled then
        { value = cfg.value, close = False }

    else
        let
            base =
                case cfg.value of
                    Single (Just ts) ->
                        ts

                    _ ->
                        cfg.now

            withDefault =
                if cfg.type_ == Datetime then
                    case cfg.defaultTime of
                        Just (DefaultSingle s) ->
                            case DT.getDefaultTime (Just s) of
                                Just t ->
                                    DT.setFields cfg.zone
                                        base
                                        { noFields | hours = Just t.hours, minutes = Just t.minutes, seconds = Just t.seconds }

                                Nothing ->
                                    base

                        _ ->
                            base

                else
                    base

            newValue =
                case cfg.type_ of
                    Quarter ->
                        DT.setFields cfg.zone
                            withDefault
                            { noFields | year = Just cfg.target.year, quarter = Just cfg.target.quarter }

                    Year ->
                        DT.setFields cfg.zone withDefault { noFields | year = Just cfg.target.year }

                    Month ->
                        DT.setFields cfg.zone
                            withDefault
                            { noFields | year = Just cfg.target.year, month = Just cfg.target.month }

                    _ ->
                        DT.setFields cfg.zone
                            withDefault
                            { noFields | year = Just cfg.target.year, month = Just cfg.target.month, day = Just cfg.target.day }
        in
        { value = Single (Just (sanitizeValueIn cfg.zone cfg.type_ newValue))
        , close = List.member cfg.type_ [ Date, Week, Year ]
        }


{-| Upstream `use-dual-calendar.handleDateClick` (`:426-451`). The flags come
from the options; `closeOnSelect` / `updateValueOnClose` fire only for
`daterange`, and a pair value in hand short-circuits to "stop selecting"
(upstream's `props.panel && Array.isArray(value)` branch — the port's `panel`
is inherently panel mode).
-}
dualDateClick :
    { value : Value
    , selecting : Bool
    , type_ : PanelType
    , closeOnSelect : Bool
    , updateValueOnClose : Bool
    }
    -> Int
    -> { value : Value, selecting : Bool, close : Bool, confirm : Bool }
dualDateClick cfg ts =
    if not cfg.selecting then
        { value = Range (Just ( ts, ts )), selecting = True, close = False, confirm = False }

    else
        case cfg.value of
            Range (Just ( a, b )) ->
                { value = Range (Just ( a, b )), selecting = False, close = False, confirm = False }

            _ ->
                if cfg.closeOnSelect && cfg.type_ == Daterange then
                    { value = cfg.value
                    , selecting = False
                    , close = True
                    , confirm = not cfg.updateValueOnClose
                    }

                else
                    { value = cfg.value, selecting = False, close = False, confirm = False }


{-| Upstream `use-dual-calendar.handleDateMouseEnter` (`:452-468`): the reversed
hover normalizes to `[min, max]`. `memorizedStart` is upstream's
`memorizedStartDateTimeRef`; `Nothing` falls back to `value[0]`.
-}
dualHover :
    { value : Value, selecting : Bool, memorizedStart : Maybe Int, disabled : Bool }
    -> Int
    -> Maybe Value
dualHover cfg ts =
    if not cfg.selecting || cfg.disabled then
        Nothing

    else
        case ( cfg.memorizedStart, cfg.value ) of
            ( Just memo, _ ) ->
                if ts >= memo then
                    Just (Range (Just ( memo, ts )))

                else
                    Just (Range (Just ( ts, memo )))

            ( Nothing, Range (Just ( a, _ )) ) ->
                if ts >= a then
                    Just (Range (Just ( a, ts )))

                else
                    Just (Range (Just ( ts, a )))

            _ ->
                Nothing


{-| Upstream `handleColItemClick` (`use-dual-calendar.ts:797-867`) with
`justifyColumnsScrollState` punted: the (already month-adjusted) item timestamp
in, the next range value out.
-}
colItemClick : PanelType -> Value -> Int -> RangePos -> Value
colItemClick type_ value itemTs pos =
    let
        partial =
            sanitizeValueIn Time.utc type_ itemTs
    in
    case value of
        Range (Just ( a, b )) ->
            case pos of
                RangeStart ->
                    if partial > b then
                        Range (Just ( partial, partial ))

                    else
                        Range (Just ( partial, b ))

                RangeEnd ->
                    if a > partial then
                        Range (Just ( partial, partial ))

                    else
                        Range (Just ( a, partial ))

        _ ->
            Range (Just ( partial, partial ))


{-| Upstream `handleQuickMonthClick` (`use-calendar.ts:403-422`): set the month
(on a month cell) or the year (on a year cell) onto the base anchor.
-}
quickMonthClick :
    { value : Value, now : Int, zone : Time.Zone }
    -> { isMonth : Bool, month : Int, year : Int }
    -> Int
quickMonthClick cfg target =
    let
        base =
            case cfg.value of
                Single (Just ts) ->
                    ts

                _ ->
                    cfg.now
    in
    if target.isMonth then
        DT.setFields cfg.zone base { noFields | month = Just target.month }

    else
        DT.setFields cfg.zone base { noFields | year = Just target.year }


{-| Upstream `use-calendar.handleNowClick` (`:293-311`) as a pure function.
-}
singleNow : { type_ : PanelType, now : Int, zone : Time.Zone } -> { value : Value, close : Bool }
singleNow cfg =
    { value = Single (Just (sanitizeValueIn cfg.zone cfg.type_ cfg.now))
    , close = True
    }


{-| Upstream `handleSingleShortcutMouseenter` / `Click` (`:492-506`): a scalar
shortcut previews on hover and commits + closes on click. `ShortcutRange`
renders nothing in a single panel.
-}
singleShortcutEffect : ShortcutPhase -> ShortcutValue -> Maybe { value : Value, commit : Bool, close : Bool }
singleShortcutEffect phase shortcut =
    case shortcut of
        ShortcutSingle ts ->
            case phase of
                ShortcutPreview ->
                    Just { value = Single (Just ts), commit = False, close = False }

                ShortcutDone ->
                    Just { value = Single (Just ts), commit = True, close = True }

        ShortcutRange _ ->
            Nothing


{-| Upstream `handleRangeShortcutMouseenter` / `Click` (`:726-745`).
`ShortcutSingle` renders nothing in a range panel.
-}
rangeShortcutEffect : ShortcutPhase -> ShortcutValue -> Maybe { value : Value, commit : Bool, close : Bool }
rangeShortcutEffect phase shortcut =
    case shortcut of
        ShortcutRange ( a, b ) ->
            case phase of
                ShortcutPreview ->
                    Just { value = Range (Just ( a, b )), commit = False, close = False }

                ShortcutDone ->
                    Just { value = Range (Just ( a, b )), commit = True, close = True }

        ShortcutSingle _ ->
            Nothing



-- VIEW (trigger) ---------------------------------------------------------------


{-| The trigger — `div.n-date-picker` (3 trigger vars) over the single or pair
`NUI.Input`.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.html <|
        Html.div
            [ HA.class (String.join " " (triggerClasses opts))
            , HA.attribute "style" (I.renderVars (triggerVars theme))
            ]
            (triggerBody theme opts)


triggerClasses : Options msg -> List String
triggerClasses opts =
    [ "n-date-picker" ]
        ++ I.classIf opts.disabled "n-date-picker--disabled"
        ++ I.classIf (isRangeType opts.type_) "n-date-picker--range"


triggerVars : Theme -> List ( String, String )
triggerVars theme =
    let
        v =
            DPTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-icon-color-override", v.iconColor )
    , ( "--n-icon-color-disabled-override", v.iconColorDisabled )
    ]


triggerBody : Theme -> Options msg -> List (Html msg)
triggerBody theme opts =
    if isRangeType opts.type_ then
        [ embedHtml (Input.view theme (rangeInputOptions opts)) ]

    else
        [ embedHtml (Input.view theme (singleInputOptions opts)) ]


singleInputOptions : Options msg -> Input.Options msg
singleInputOptions opts =
    let
        d =
            Input.defaults

        glyph =
            dateGlyphNode opts
    in
    { d
        | value = displayText opts
        , onInput = opts.onInput
        , placeholder = Just (localizedPlaceholder opts)
        , size = opts.size
        , status = opts.status
        , disabled = opts.disabled
        , readonly = opts.inputReadonly || opts.disabled
        , clearable = opts.clearable
        , bordered = opts.bordered
        , stateful = True
        , passivelyActivated = True
        , internalForceFocus = opts.show
        , textDecoration =
            if isValueInvalid opts then
                Just "line-through"

            else
                Nothing
        , onFocus = opts.onFocus
        , onBlur = opts.onBlur
        , suffix =
            if opts.clearable then
                Nothing

            else
                Just glyph
        , clearIconPlaceholder =
            if opts.clearable then
                Just glyph

            else
                Nothing
    }


rangeInputOptions : Options msg -> Input.Options msg
rangeInputOptions opts =
    let
        d =
            Input.defaults

        ph =
            placeholders opts.type_

        glyph =
            dateGlyphNode opts

        ( a, b ) =
            displayRange opts
    in
    { d
        | value = ""
        , pairValue = Just ( a, b )
        , pairPlaceholder =
            Just
                ( Maybe.withDefault ph.start opts.startPlaceholder
                , Maybe.withDefault ph.end opts.endPlaceholder
                )
        , pairTextDecoration =
            Just
                ( plainDecoration (isStartValueInvalid opts)
                , plainDecoration (isEndValueInvalid opts)
                )
        , separatorNode = Just (separatorNode opts)
        , suffix =
            if opts.clearable then
                Nothing

            else
                Just glyph
        , clearIconPlaceholder =
            if opts.clearable then
                Just glyph

            else
                Nothing
        , size = opts.size
        , status = opts.status
        , disabled = opts.disabled
        , readonly = opts.inputReadonly || opts.disabled
        , clearable = opts.clearable
        , bordered = opts.bordered
        , stateful = True
        , passivelyActivated = True
        , internalForceFocus = opts.show
        , onPairInput = opts.onPairInput
        , onFocus = opts.onFocus
        , onBlur = opts.onBlur
    }


invalidDecoration : Bool -> Maybe String
invalidDecoration invalid =
    if invalid then
        Just "line-through"

    else
        Nothing


{-| The pair form: a plain string per side (the empty string drops in
`NUI.Input`).
-}
plainDecoration : Bool -> String
plainDecoration invalid =
    if invalid then
        "line-through"

    else
        ""


{-| The `i.n-base-icon.n-date-picker-icon` date glyph (the caller's `iconNode`
over `DateIcon`).
-}
dateGlyphNode : Options msg -> Element msg
dateGlyphNode opts =
    Element.html <|
        Html.i [ HA.class "n-base-icon n-date-picker-icon" ]
            [ case opts.iconNode of
                Just el ->
                    embedHtml el

                Nothing ->
                    dateSvg
            ]


{-| The range separator — the `separator` string if set, else the `To` glyph in
`i.n-base-icon.n-date-picker-icon` (`DatePicker.tsx:1113-1123`).
-}
separatorNode : Options msg -> Element msg
separatorNode opts =
    case opts.separator of
        Just s ->
            Element.text s

        Nothing ->
            Element.html <|
                Html.i [ HA.class "n-base-icon n-date-picker-icon" ] [ toSvg ]


displayText : Options msg -> String
displayText opts =
    case opts.text of
        Just t ->
            t

        Nothing ->
            case opts.value of
                Single (Just ts) ->
                    DT.format (mergedFormat opts) opts.zone ts

                _ ->
                    ""


displayRange : Options msg -> ( String, String )
displayRange opts =
    case opts.rangeText of
        Just pair ->
            pair

        Nothing ->
            case opts.value of
                Range (Just ( a, b )) ->
                    ( DT.format (mergedFormat opts) opts.zone a
                    , DT.format (mergedFormat opts) opts.zone b
                    )

                _ ->
                    ( "", "" )


localizedPlaceholder : Options msg -> String
localizedPlaceholder opts =
    case opts.placeholder of
        Just p ->
            p

        Nothing ->
            case opts.type_ of
                Date ->
                    "Select Date"

                Datetime ->
                    "Select Date and Time"

                Month ->
                    "Select Month"

                Year ->
                    "Select Year"

                Quarter ->
                    "Select Quarter"

                Week ->
                    "Select Week"

                _ ->
                    ""



-- PANEL ------------------------------------------------------------------------


{-| The panel body. Mount it in your own follower-positioned wrapper.
-}
panel : Theme -> Options msg -> Element msg
panel theme opts =
    panelWith theme opts Nothing


{-| `quickJump` marks the header's inline month panel (`useAsQuickJump`), whose
cell clicks navigate a calendar anchor instead of picking a value.
-}
panelWith : Theme -> Options msg -> Maybe CalendarSide -> Element msg
panelWith theme opts quickJump =
    Element.html <|
        Html.div
            [ HA.class (String.join " " (panelClasses opts))
            , HA.tabindex 0
            , HA.attribute "style" (I.renderVars (panelVars theme opts))
            ]
            (bodyFor theme opts quickJump
                ++ actionsSlot theme opts
                ++ [ focusDetectorNode ]
            )


panelClasses : Options msg -> List String
panelClasses opts =
    [ "n-date-panel"
    , "n-date-panel--" ++ panelTypeClass opts.type_
    , "n-date-panel--shadow"
    ]
        ++ (case opts.transition of
                Just phase ->
                    [ I.transitionClass "fade-in-scale-up-transition" phase ]

                Nothing ->
                    []
           )


{-| `month.tsx:98` hardcodes `--month` for the whole month/year/quarter panel;
`monthrange.tsx:94` reuses `--daterange` (`DatePicker.tsx:1030-1039`).
-}
panelTypeClass : PanelType -> String
panelTypeClass type_ =
    case type_ of
        Date ->
            "date"

        Week ->
            "week"

        Datetime ->
            "datetime"

        Daterange ->
            "daterange"

        Datetimerange ->
            "datetimerange"

        Month ->
            "month"

        Year ->
            "month"

        Quarter ->
            "month"

        Monthrange ->
            "daterange"

        Yearrange ->
            "daterange"

        Quarterrange ->
            "daterange"


{-| The 43 panel vars (`DatePicker.tsx:833-920`, declaration order).
-}
panelVars : Theme -> Options msg -> List ( String, String )
panelVars theme opts =
    let
        v =
            DPTheme.vars theme

        ( leftPad, rightPad ) =
            calendarPadding v opts.type_
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-panel-border-radius", v.panelBorderRadius )
    , ( "--n-panel-color", v.panelColor )
    , ( "--n-panel-box-shadow", v.panelBoxShadow )
    , ( "--n-panel-text-color", v.panelTextColor )
    , ( "--n-panel-header-padding", v.panelHeaderPadding )
    , ( "--n-panel-header-divider-color", v.panelHeaderDividerColor )
    , ( "--n-calendar-left-padding", leftPad )
    , ( "--n-calendar-right-padding", rightPad )
    , ( "--n-calendar-title-color-hover", v.calendarTitleColorHover )
    , ( "--n-calendar-title-height", v.calendarTitleHeight )
    , ( "--n-calendar-title-padding", v.calendarTitlePadding )
    , ( "--n-calendar-title-font-size", v.calendarTitleFontSize )
    , ( "--n-calendar-title-font-weight", v.calendarTitleFontWeight )
    , ( "--n-calendar-title-text-color", v.calendarTitleTextColor )
    , ( "--n-calendar-title-grid-template-columns", v.calendarTitleGridTempateColumns )
    , ( "--n-calendar-days-height", v.calendarDaysHeight )
    , ( "--n-calendar-days-divider-color", v.calendarDaysDividerColor )
    , ( "--n-calendar-days-font-size", v.calendarDaysFontSize )
    , ( "--n-calendar-days-text-color", v.calendarDaysTextColor )
    , ( "--n-calendar-divider-color", v.calendarDividerColor )
    , ( "--n-panel-action-padding", v.panelActionPadding )
    , ( "--n-panel-extra-footer-padding", v.panelExtraFooterPadding )
    , ( "--n-panel-action-divider-color", v.panelActionDividerColor )
    , ( "--n-item-font-size", v.itemFontSize )
    , ( "--n-item-border-radius", v.itemBorderRadius )
    , ( "--n-item-size", v.itemSize )
    , ( "--n-item-cell-width", v.itemCellWidth )
    , ( "--n-item-cell-height", v.itemCellHeight )
    , ( "--n-item-text-color", v.itemTextColor )
    , ( "--n-item-color-included", v.itemColorIncluded )
    , ( "--n-item-color-disabled", v.itemColorDisabled )
    , ( "--n-item-color-hover", v.itemColorHover )
    , ( "--n-item-color-active", v.itemColorActive )
    , ( "--n-item-text-color-disabled", v.itemTextColorDisabled )
    , ( "--n-item-text-color-active", v.itemTextColorActive )
    , ( "--n-scroll-item-width", v.scrollItemWidth )
    , ( "--n-scroll-item-height", v.scrollItemHeight )
    , ( "--n-scroll-item-border-radius", v.scrollItemBorderRadius )
    , ( "--n-arrow-size", v.arrowSize )
    , ( "--n-arrow-color", v.arrowColor )
    , ( "--n-icon-color", v.iconColor )
    , ( "--n-icon-color-disabled", v.iconColorDisabled )
    ]


calendarPadding : DPTheme.Vars -> PanelType -> ( String, String )
calendarPadding v type_ =
    case type_ of
        Date ->
            ( v.calendarLeftPaddingDate, v.calendarRightPaddingDate )

        Datetime ->
            ( v.calendarLeftPaddingDatetime, v.calendarRightPaddingDatetime )

        Daterange ->
            ( v.calendarLeftPaddingDaterange, v.calendarRightPaddingDaterange )

        Datetimerange ->
            ( v.calendarLeftPaddingDatetimerange, v.calendarRightPaddingDatetimerange )

        Month ->
            ( v.calendarLeftPaddingMonth, v.calendarRightPaddingMonth )

        Year ->
            ( v.calendarLeftPaddingYear, v.calendarRightPaddingYear )

        Quarter ->
            ( v.calendarLeftPaddingQuarter, v.calendarRightPaddingQuarter )

        Monthrange ->
            ( v.calendarLeftPaddingMonthrange, v.calendarRightPaddingMonthrange )

        Quarterrange ->
            ( v.calendarLeftPaddingQuarterrange, v.calendarRightPaddingQuarterrange )

        Yearrange ->
            ( v.calendarLeftPaddingYearrange, v.calendarRightPaddingYearrange )

        Week ->
            ( v.calendarLeftPaddingWeek, v.calendarRightPaddingWeek )


focusDetectorNode : Html msg
focusDetectorNode =
    Html.div [ HA.attribute "style" "width:0;height:0", HA.tabindex 0 ] []



-- PANEL BODIES -----------------------------------------------------------------


bodyFor : Theme -> Options msg -> Maybe CalendarSide -> List (Html msg)
bodyFor theme opts quickJump =
    case opts.type_ of
        Date ->
            calendarBody theme opts

        Week ->
            calendarBody theme opts

        Datetime ->
            datetimeHeader theme opts ++ calendarBody theme opts

        Daterange ->
            dualRangeBody theme opts

        Datetimerange ->
            datetimerangeHeader theme opts ++ dualRangeBody theme opts

        Month ->
            monthCalendarBody theme opts quickJump

        Year ->
            monthCalendarBody theme opts quickJump

        Quarter ->
            monthCalendarBody theme opts quickJump

        Monthrange ->
            monthRangeBody theme opts

        Yearrange ->
            monthRangeBody theme opts

        Quarterrange ->
            monthRangeBody theme opts


{-| The single `div.n-date-panel-calendar` (date / week / datetime).
-}
calendarBody : Theme -> Options msg -> List (Html msg)
calendarBody theme opts =
    [ Html.div [ HA.class "n-date-panel-calendar" ]
        (Html.div [ HA.class "n-date-panel-month" ] (monthNav theme opts CalStart (singleCalendarValue opts))
            :: [ weekdaysNode opts CalStart
               , Html.div [ HA.class "n-date-panel-dates" ]
                    (List.map (dateCell opts { side = CalStart, rangeMode = False, suppressDisabled = False }) (dateItems opts CalStart))
               ]
        )
    ]


{-| The dual `div.n-date-panel-calendar--start` / `--end` pair.
-}
dualRangeBody : Theme -> Options msg -> List (Html msg)
dualRangeBody theme opts =
    [ rangeCalendar theme opts CalStart
    , Html.div [ HA.class "n-date-panel__vertical-divider" ] []
    , rangeCalendar theme opts CalEnd
    ]


rangeCalendar : Theme -> Options msg -> CalendarSide -> Html msg
rangeCalendar theme opts side =
    Html.div
        [ HA.class
            ("n-date-panel-calendar n-date-panel-calendar--"
                ++ (if side == CalStart then
                        "start"

                    else
                        "end"
                   )
            )
        ]
        (Html.div [ HA.class "n-date-panel-month" ] (monthNav theme opts side (rangeCalendarValue opts side))
            :: [ weekdaysNode opts side
               , Html.div [ HA.class "n-date-panel__divider" ] []
               , Html.div [ HA.class "n-date-panel-dates" ]
                    (List.map
                        (dateCell opts
                            { side = side
                            , rangeMode = True
                            , suppressDisabled = opts.type_ == Datetimerange
                            }
                        )
                        (dateItems opts side)
                    )
               ]
        )


weekdaysNode : Options msg -> CalendarSide -> Html msg
weekdaysNode opts side =
    Html.div [ HA.class "n-date-panel-weekdays" ]
        (List.map
            (\label -> Html.div [ HA.class "n-date-panel-weekdays__day" ] [ Html.text label ])
            (weekdayLabels opts side)
        )


{-| The date cell. The class ORDER differs between the single panels
(`date.tsx:132-151`) and the range panels (`daterange.tsx:99-121`).
-}
dateCell : Options msg -> { side : CalendarSide, rangeMode : Bool, suppressDisabled : Bool } -> DT.DateItem -> Html msg
dateCell opts cfg item =
    let
        disabled =
            if cfg.rangeMode then
                dualDisabled opts item.ts

            else
                singleDisabled opts item

        suppressed =
            cfg.suppressDisabled && disabled

        classes =
            if cfg.rangeMode then
                [ "n-date-panel-date" ]
                    ++ I.classIf (not item.inCurrentMonth) "n-date-panel-date--excluded"
                    ++ I.classIf item.isCurrentDate "n-date-panel-date--current"
                    ++ I.classIf item.selected "n-date-panel-date--selected"
                    ++ I.classIf item.inSpan "n-date-panel-date--covered"
                    ++ I.classIf item.startOfSpan "n-date-panel-date--start"
                    ++ I.classIf item.endOfSpan "n-date-panel-date--end"
                    ++ I.classIf disabled "n-date-panel-date--disabled"

            else
                [ "n-date-panel-date" ]
                    ++ I.classIf item.isCurrentDate "n-date-panel-date--current"
                    ++ I.classIf item.selected "n-date-panel-date--selected"
                    ++ I.classIf (not item.inCurrentMonth) "n-date-panel-date--excluded"
                    ++ I.classIf disabled "n-date-panel-date--disabled"
                    ++ I.classIf (opts.type_ == Week && opts.hoveredWeek == Just item.ts) "n-date-panel-date--week-hovered"
                    ++ I.classIf item.inSelectedWeek "n-date-panel-date--week-selected"

        handlers =
            if cfg.rangeMode then
                if suppressed then
                    []

                else
                    onMouseEnterAttr (Maybe.map (\f -> f item.ts) opts.onDateEnter)
                        ++ onClickAttr (Maybe.map (\f -> f item.ts) opts.onDateClick)

            else
                singleCellHandlers opts item
    in
    Html.div
        ([ HA.attribute "data-n-date" "true"
         , HA.class (String.join " " classes)
         ]
            ++ handlers
        )
        (Html.div [ HA.class "n-date-panel-date__trigger" ] []
            :: Html.text (String.fromInt item.dateObject.day)
            :: (if item.isCurrentDate then
                    [ Html.div [ HA.class "n-date-panel-date__sup" ] [] ]

                else
                    []
               )
        )


singleDisabled : Options msg -> DT.DateItem -> Bool
singleDisabled opts item =
    case opts.isDateDisabled of
        Just pred ->
            pred item.ts
                (SingleDetail
                    { type_ = DateDetail
                    , year = item.dateObject.year
                    , month = item.dateObject.month
                    , date = item.dateObject.day
                    }
                )

        Nothing ->
            False


{-| Upstream `use-dual-calendar.mergedIsDateDisabled` (`:383-411`) — a bare
timestamp with the range detail. The memorized start falls back to `value[0]`
(upstream keeps it in a ref; the port documents the approximation).
-}
dualDisabled : Options msg -> Int -> Bool
dualDisabled opts ts =
    case opts.isDateDisabled of
        Nothing ->
            False

        Just pred ->
            case opts.value of
                Range (Just ( a, _ )) ->
                    if not opts.selecting then
                        pred ts (RangeDetail RangeStart Nothing)

                    else if ts < a then
                        pred ts (RangeDetail RangeStart (Just ( a, a )))

                    else
                        pred ts (RangeDetail RangeEnd (Just ( a, a )))

                _ ->
                    pred ts (RangeDetail RangeStart Nothing)


{-| A single-panel cell: the click/enter handlers are always attached
(`date.tsx:152-157`) and the disabled check lives inside `singleDateClick`.
-}
singleCellHandlers : Options msg -> DT.DateItem -> List (Html.Attribute msg)
singleCellHandlers opts item =
    let
        value =
            singleDateClickMessage opts item

        click =
            case opts.onUpdateValue of
                Just f ->
                    Just (f value)

                Nothing ->
                    Maybe.map (\f -> f value) opts.onUpdatePendingValue

        enter =
            if opts.type_ == Week then
                Maybe.map (\f -> f item.ts) opts.onDateEnter

            else
                Nothing
    in
    onClickAttr click ++ onMouseEnterAttr enter


singleDateClickMessage : Options msg -> DT.DateItem -> Value
singleDateClickMessage opts item =
    singleDateClick
        { type_ = opts.type_
        , value = opts.value
        , target =
            { ts = item.ts
            , year = item.dateObject.year
            , month = item.dateObject.month
            , day = item.dateObject.day
            , quarter = (item.dateObject.month - 1) // 3 + 1
            }
        , isDisabled = singleDisabled opts item
        , defaultTime = opts.defaultTime
        , now = Time.posixToMillis opts.now
        , zone = opts.zone
        }
        |> .value



-- MONTH / YEAR / QUARTER PANELS -------------------------------------------------


monthCalendarBody : Theme -> Options msg -> Maybe CalendarSide -> List (Html msg)
monthCalendarBody theme opts quickJump =
    [ Html.div [ HA.class "n-date-panel-month-calendar" ]
        (yearColumn theme opts CalStart quickJump
            ++ monthColumn theme opts CalStart quickJump
        )
    ]


monthRangeBody : Theme -> Options msg -> List (Html msg)
monthRangeBody theme opts =
    [ Html.div [ HA.class "n-date-panel-calendar n-date-panel-calendar--start" ]
        [ Html.div [ HA.class "n-date-panel-month-calendar" ]
            (yearColumn theme opts CalStart Nothing ++ monthColumn theme opts CalStart Nothing)
        ]
    , Html.div [ HA.class "n-date-panel__vertical-divider" ] []
    , Html.div [ HA.class "n-date-panel-calendar n-date-panel-calendar--end" ]
        [ Html.div [ HA.class "n-date-panel-month-calendar" ]
            (yearColumn theme opts CalEnd Nothing ++ monthColumn theme opts CalEnd Nothing)
        ]
    ]


yearColumn : Theme -> Options msg -> CalendarSide -> Maybe CalendarSide -> List (Html msg)
yearColumn theme opts side quickJump =
    [ Html.div [ HA.class "n-date-panel-month-calendar__picker-col" ]
        [ scrollCol theme
            []
            (List.map (pickerItem opts side quickJump True) (yearItems opts side))
        ]
    ]


{-| The month / quarter column — only for `month` / `quarter` / `monthrange` /
`quarterrange`.
-}
monthColumn : Theme -> Options msg -> CalendarSide -> Maybe CalendarSide -> List (Html msg)
monthColumn theme opts side quickJump =
    if List.member opts.type_ [ Month, Quarter, Monthrange, Quarterrange ] then
        [ Html.div [ HA.class "n-date-panel-month-calendar__picker-col" ]
            [ scrollCol theme
                []
                (List.map (pickerItem opts side quickJump False) (monthOrQuarterItems opts side)
                    ++ [ Html.div
                            [ HA.class
                                ("n-date-panel-"
                                    ++ (if opts.type_ == Quarter || opts.type_ == Quarterrange then
                                            "quarter"

                                        else
                                            "month"
                                       )
                                    ++ "-calendar__padding"
                                )
                            ]
                            []
                       ]
                )
            ]
        ]

    else
        []


scrollCol : Theme -> List String -> List (Html msg) -> Html msg
scrollCol theme extraClasses items =
    let
        d =
            Scrollbar.defaults
    in
    embedHtml <|
        Scrollbar.view theme
            { d
                | extraClasses = extraClasses
                , yRailStyle = Just "z-index:1"
                , xRailStyle = Just "z-index:1"
            }
            (List.map Element.html items)


pickerItem : Options msg -> CalendarSide -> Maybe CalendarSide -> Bool -> PickerCell -> Html msg
pickerItem opts side quickJump isYear cell =
    let
        disabled =
            quickJump == Nothing && pickerDisabled opts isYear cell

        handlers =
            if disabled then
                []

            else
                pickerHandlers opts side quickJump isYear cell
    in
    Html.div
        ([ HA.attribute "data-n-date" "true"
         , HA.class
            (String.join " "
                ([ "n-date-panel-month-calendar__picker-col-item" ]
                    ++ I.classIf cell.isCurrent "n-date-panel-month-calendar__picker-col-item--current"
                    ++ I.classIf cell.selected "n-date-panel-month-calendar__picker-col-item--selected"
                    ++ I.classIf disabled "n-date-panel-month-calendar__picker-col-item--disabled"
                )
            )
         ]
            ++ handlers
        )
        [ Html.text cell.label ]


pickerHandlers : Options msg -> CalendarSide -> Maybe CalendarSide -> Bool -> PickerCell -> List (Html.Attribute msg)
pickerHandlers opts side quickJump isYear cell =
    case quickJump of
        Just qs ->
            onClickAttr (Maybe.map (\f -> f qs (quickAnchor opts cell)) (calendarChannel opts))

        Nothing ->
            if List.member opts.type_ [ Month, Year, Quarter ] then
                onClickAttr (pickerCellMsg opts isYear cell)

            else
                onClickAttr (Maybe.map (\f -> f (colItemTs opts side isYear cell) (sidePos side)) opts.onMonthItemClick)


sidePos : CalendarSide -> RangePos
sidePos side =
    if side == CalStart then
        RangeStart

    else
        RangeEnd


pickerCellMsg : Options msg -> Bool -> PickerCell -> Maybe msg
pickerCellMsg opts isYear cell =
    let
        value =
            pickerSingleValue opts isYear cell
    in
    case opts.onUpdateValue of
        Just f ->
            Just (f value)

        Nothing ->
            Maybe.map (\f -> f value) opts.onUpdatePendingValue


pickerDisabled : Options msg -> Bool -> PickerCell -> Bool
pickerDisabled opts isYear cell =
    case opts.isDateDisabled of
        Just pred ->
            pred cell.ts (SingleDetail (upstreamDetail isYear cell))

        Nothing ->
            False


{-| `month.tsx:83-92` — year → `{type:'year', year}`; month →
`{type:'month', year, month}`; quarter → `{type:'month', year, month:quarter}`
(the upstream discriminator bug, kept faithfully).
-}
upstreamDetail : Bool -> PickerCell -> { type_ : DetailType, year : Int, month : Int, date : Int }
upstreamDetail isYear cell =
    if isYear then
        { type_ = YearDetail, year = cell.year, month = 0, date = 0 }

    else if cell.quarter > 0 then
        { type_ = MonthDetail, year = cell.year, month = cell.quarter, date = 0 }

    else
        { type_ = MonthDetail, year = cell.year, month = cell.month, date = 0 }


{-| The single month/year/quarter panel's cell click value
(`use-calendar.ts:384-395`).
-}
pickerSingleValue : Options msg -> Bool -> PickerCell -> Value
pickerSingleValue opts isYear cell =
    let
        base =
            case opts.value of
                Single (Just ts) ->
                    ts

                _ ->
                    Time.posixToMillis opts.now

        target =
            if isYear then
                { ts = cell.ts, year = cell.year, month = 1, day = 1, quarter = 1 }

            else if cell.quarter > 0 then
                { ts = cell.ts, year = cell.year, month = cell.quarter * 3 - 2, day = 1, quarter = cell.quarter }

            else
                { ts = cell.ts, year = cell.year, month = cell.month, day = 1, quarter = (cell.month - 1) // 3 + 1 }
    in
    singleDateClick
        { type_ = opts.type_
        , value = Single (Just base)
        , target = target
        , isDisabled = pickerDisabled opts isYear cell
        , defaultTime = opts.defaultTime
        , now = Time.posixToMillis opts.now
        , zone = opts.zone
        }
        |> .value


{-| The quick-jump panel's cell click — the new calendar anchor
(`panelHeader.tsx:120` → `use-calendar.ts:403-422`).
-}
quickAnchor : Options msg -> PickerCell -> Int
quickAnchor opts cell =
    quickMonthClick
        { value = opts.value, now = Time.posixToMillis opts.now, zone = opts.zone }
        { isMonth = cell.quarter == 0 && cell.month > 0
        , month = cell.month
        , year = cell.year
        }


{-| Upstream `use-dual-calendar.ts:802-820` — a year cell in `monthrange` /
`quarterrange` takes the month from the current value's side.
-}
colItemTs : Options msg -> CalendarSide -> Bool -> PickerCell -> Int
colItemTs opts side isYear cell =
    if isYear && opts.type_ /= Yearrange then
        DT.setFields opts.zone cell.ts { noFields | month = Just (sideMonth opts side) }

    else
        cell.ts


sideMonth : Options msg -> CalendarSide -> Int
sideMonth opts side =
    let
        ts =
            case opts.value of
                Range (Just ( a, b )) ->
                    if side == CalStart then
                        a

                    else
                        b

                _ ->
                    Time.posixToMillis opts.now
    in
    if opts.type_ == Quarterrange then
        DT.toCivil opts.zone (DT.startOfQuarter opts.zone ts) |> .month

    else
        DT.toCivil opts.zone ts |> .month



-- ITEMS ------------------------------------------------------------------------


type alias PickerCell =
    { ts : Int
    , label : String
    , isCurrent : Bool
    , selected : Bool
    , year : Int
    , month : Int
    , quarter : Int
    }


dateItems : Options msg -> CalendarSide -> List DT.DateItem
dateItems opts side =
    DT.dateArray (gridTs opts.zone (calendarAnchor opts side))
        (gridValueTs opts.zone (toValueTs opts.value))
        (gridTs opts.zone (Time.posixToMillis opts.now))
        (Maybe.withDefault 6 opts.firstDayOfWeek)
        False
        (opts.type_ == Week)


yearItems : Options msg -> CalendarSide -> List PickerCell
yearItems opts side =
    DT.yearArray (gridValueTs opts.zone (sideValueTs opts side))
        (gridTs opts.zone (Time.posixToMillis opts.now))
        { yearFormat = opts.yearFormat }
        opts.yearRange
        |> List.map
            (\item ->
                { ts = item.ts
                , label = DT.format opts.yearFormat Time.utc item.ts
                , isCurrent = item.isCurrent
                , selected = item.selected
                , year = item.dateObject.year
                , month = 0
                , quarter = 0
                }
            )


monthOrQuarterItems : Options msg -> CalendarSide -> List PickerCell
monthOrQuarterItems opts side =
    if opts.type_ == Quarter || opts.type_ == Quarterrange then
        DT.quarterArray (gridTs opts.zone (calendarAnchor opts side))
            (gridValueTs opts.zone (sideValueTs opts side))
            (gridTs opts.zone (Time.posixToMillis opts.now))
            { quarterFormat = opts.quarterFormat }
            |> List.map
                (\item ->
                    { ts = item.ts
                    , label = quarterLabel opts item.dateObject.quarter
                    , isCurrent = item.isCurrent
                    , selected = item.selected
                    , year = item.dateObject.year
                    , month = 0
                    , quarter = item.dateObject.quarter
                    }
                )

    else
        DT.monthArray (gridTs opts.zone (calendarAnchor opts side))
            (gridValueTs opts.zone (sideValueTs opts side))
            (gridTs opts.zone (Time.posixToMillis opts.now))
            { monthFormat = opts.monthFormat }
            |> List.map
                (\item ->
                    { ts = item.ts
                    , label = monthLabel opts item.dateObject.month
                    , isCurrent = item.isCurrent
                    , selected = item.selected
                    , year = item.dateObject.year
                    , month = item.dateObject.month
                    , quarter = 0
                    }
                )


{-| Upstream builds these labels from a synthetic `Date(2000, …)` rather than
the item timestamp (`utils.ts:206-228`); mirror that so the token offsets agree.
-}
monthLabel : Options msg -> Int -> String
monthLabel opts month =
    DT.format opts.monthFormat Time.utc (DT.toPosix Time.utc { year = 2000, month = month, day = 1 } zeroTime)


quarterLabel : Options msg -> Int -> String
quarterLabel opts quarter =
    DT.format opts.quarterFormat Time.utc (DT.toPosix Time.utc { year = 2000, month = quarter * 3 - 1, day = 1 } zeroTime)


toValueTs : Value -> DT.ValueTs
toValueTs value =
    case value of
        Single (Just ts) ->
            DT.SingleTs ts

        Range (Just ( a, b )) ->
            DT.RangeTs a b

        _ ->
            DT.NoValue


{-| The per-side value for the month / quarter / year arrays
(`use-dual-calendar.ts:231-272`).
-}
sideValueTs : Options msg -> CalendarSide -> DT.ValueTs
sideValueTs opts side =
    case opts.value of
        Range (Just ( a, b )) ->
            DT.SingleTs
                (if side == CalStart then
                    a

                 else
                    b
                )

        Range Nothing ->
            DT.NoValue

        Single ts ->
            case ts of
                Just v ->
                    DT.SingleTs v

                Nothing ->
                    DT.NoValue


{-| The grid builders (`dateArray` / `monthArray` / …) read their timestamps in
`Time.utc` (see `NUI.Internal.DateTime`), but clicks, sanitize and the display
formatters work in `opts.zone`. Map a caller instant onto the UTC midnight of
the same **civil** day in `opts.zone`, so the grid's civil days equal the
caller's local civil days while the builders stay internally UTC `[oracle S1]`.
-}
gridTs : Time.Zone -> Int -> Int
gridTs zone raw =
    DT.toPosix Time.utc (DT.toCivil zone raw) zeroTime


{-| `gridTs` lifted over a `DT.ValueTs` (single or range).
-}
gridValueTs : Time.Zone -> DT.ValueTs -> DT.ValueTs
gridValueTs zone v =
    case v of
        DT.NoValue ->
            DT.NoValue

        DT.SingleTs ts ->
            DT.SingleTs (gridTs zone ts)

        DT.RangeTs a b ->
            DT.RangeTs (gridTs zone a) (gridTs zone b)


weekdayLabels : Options msg -> CalendarSide -> List String
weekdayLabels opts side =
    DT.dateArray (gridTs opts.zone (calendarAnchor opts side))
        (gridValueTs opts.zone (toValueTs opts.value))
        (gridTs opts.zone (Time.posixToMillis opts.now))
        (Maybe.withDefault 6 opts.firstDayOfWeek)
        False
        (opts.type_ == Week)
        |> List.take 7
        |> List.map (\item -> DT.format (Maybe.withDefault "eeeeee" opts.calendarDayFormat) Time.utc item.ts)



-- CALENDAR ANCHORS -------------------------------------------------------------


singleCalendarValue : Options msg -> Int
singleCalendarValue opts =
    Maybe.withDefault
        (case opts.value of
            Single (Just ts) ->
                ts

            _ ->
                Maybe.withDefault (Time.posixToMillis opts.now) opts.defaultCalendarStartTime
        )
        opts.calendarValue


{-| The dual anchors with the upstream `adjustCalendarTimes` fallback
(`use-dual-calendar.ts:107-119, 316-330`).
-}
rangeCalendarValue : Options msg -> CalendarSide -> Int
rangeCalendarValue opts side =
    let
        start =
            Maybe.withDefault
                (case opts.defaultCalendarStartTime of
                    Just t ->
                        t

                    Nothing ->
                        case opts.value of
                            Range (Just ( a, _ )) ->
                                a

                            _ ->
                                Time.posixToMillis opts.now
                )
                opts.startCalendarValue

        endRaw =
            case opts.endCalendarValue of
                Just e ->
                    e

                Nothing ->
                    case opts.defaultCalendarEndTime of
                        Just e ->
                            e

                        Nothing ->
                            case opts.value of
                                Range (Just ( _, b )) ->
                                    b

                                _ ->
                                    addMonth opts start

        adjusted =
            if opts.bindCalendarMonths || DT.startOfMonth opts.zone start >= DT.startOfMonth opts.zone endRaw then
                addMonth opts (DT.startOfMonth opts.zone start)

            else
                endRaw
    in
    if side == CalStart then
        start

    else
        adjusted


calendarAnchor : Options msg -> CalendarSide -> Int
calendarAnchor opts side =
    if isRangeType opts.type_ then
        rangeCalendarValue opts side

    else
        singleCalendarValue opts


addMonth : Options msg -> Int -> Int
addMonth opts ts =
    let
        civil =
            DT.toCivil opts.zone ts
    in
    DT.setFields opts.zone ts { noFields | month = Just (civil.month + 1) }



-- MONTH NAV + HEADER -----------------------------------------------------------


monthNav : Theme -> Options msg -> CalendarSide -> Int -> List (Html msg)
monthNav theme opts side anchor =
    [ navArrow opts side (YearStep -1) anchor "n-date-panel-month__fast-prev" fastBackwardSvg
    , navArrow opts side (MonthStep -1) anchor "n-date-panel-month__prev" backwardSvg
    , panelHeaderNode theme opts side anchor
    , navArrow opts side (MonthStep 1) anchor "n-date-panel-month__next" forwardSvg
    , navArrow opts side (YearStep 1) anchor "n-date-panel-month__fast-next" fastForwardSvg
    ]


type NavStep
    = MonthStep Int
    | YearStep Int


navArrow : Options msg -> CalendarSide -> NavStep -> Int -> String -> Html msg -> Html msg
navArrow opts side step anchor cls glyph =
    Html.div
        ([ HA.class cls ] ++ onClickAttr (Maybe.map (\f -> f side (stepAnchor opts anchor step)) (calendarChannel opts)))
        [ glyph ]


stepAnchor : Options msg -> Int -> NavStep -> Int
stepAnchor opts anchor step =
    let
        civil =
            DT.toCivil opts.zone anchor
    in
    case step of
        MonthStep n ->
            DT.setFields opts.zone anchor { noFields | month = Just (civil.month + n) }

        YearStep n ->
            DT.setFields opts.zone anchor { noFields | year = Just (civil.year + n) }


{-| `onQuickMonthSelect` (side-less) wins when set; otherwise the
side-carrying `onUpdateCalendarValue` (`DatePicker.tsx:782-789`).
-}
calendarChannel : Options msg -> Maybe (CalendarSide -> Int -> msg)
calendarChannel opts =
    case ( opts.onQuickMonthSelect, opts.onUpdateCalendarValue ) of
        ( Just f, _ ) ->
            Just (\_ v -> f v)

        ( Nothing, Just g ) ->
            Just g

        _ ->
            Nothing


panelHeaderNode : Theme -> Options msg -> CalendarSide -> Int -> Html msg
panelHeaderNode theme opts side anchor =
    let
        monthText =
            DT.format (Maybe.withDefault "MMM" opts.calendarHeaderMonthFormat) opts.zone anchor

        yearText =
            DT.format (Maybe.withDefault "yyyy" opts.calendarHeaderYearFormat) opts.zone anchor

        sep =
            opts.calendarHeaderMonthYearSeparator

        before =
            Maybe.withDefault True opts.calendarHeaderMonthBeforeYear

        textNode =
            Html.div
                ((HA.class
                    (String.join " "
                        ("n-date-panel-month__text"
                            :: I.classIf opts.monthPanelShow "n-date-panel-month__text--active"
                        )
                    )
                    :: []
                 )
                    ++ onClickAttr (Maybe.map (\f -> f (not opts.monthPanelShow)) opts.onUpdateMonthPanelShow)
                )
                (if before then
                    [ Html.text monthText, Html.text sep, Html.text yearText ]

                 else
                    [ Html.text yearText, Html.text sep, Html.text monthText ]
                )

        quick =
            if opts.monthPanelShow then
                [ embedHtml
                    (panelWith theme
                        (quickJumpOptions opts anchor)
                        (Just side)
                    )
                ]

            else
                []
    in
    Html.div [ HA.class "n-date-panel-month__month-year" ] (textNode :: quick)


{-| The header's inline month panel (`panelHeader.tsx:117-135`): `type = month`,
`actions = []`, `useAsQuickJump` on. Its cells route through the raw calendar
channel (`quickJump = Just side` in `panelWith`), never the value channels.
-}
quickJumpOptions : Options msg -> Int -> Options msg
quickJumpOptions opts anchor =
    { opts
        | type_ = Month
        , actions = Just []
        , value = Single (Just anchor)
        , calendarValue = Just anchor
        , monthPanelShow = False
        , shortcuts = []
        , onUpdateValue = Nothing
        , onUpdatePendingValue = Nothing
        , onUpdateFormattedValue = Nothing
    }



-- DATETIME HEADERS -------------------------------------------------------------


datetimeHeader : Theme -> Options msg -> List (Html msg)
datetimeHeader theme opts =
    [ Html.div [ HA.class "n-date-panel-header" ]
        ([ dateInputNode theme opts opts.value (isDateInvalidSingle opts)
         , embedHtml (TimePicker.view theme (embeddedTimeOptions opts TimeStart))
         ]
            ++ timePanelIf theme opts opts.timePickerShow TimeStart
        )
    ]


datetimerangeHeader : Theme -> Options msg -> List (Html msg)
datetimerangeHeader theme opts =
    [ Html.div [ HA.class "n-date-panel-header" ]
        ([ dateInputNode theme opts (Single (Maybe.map Tuple.first (rangeOf opts))) (isStartValueInvalid opts)
         , embedHtml (TimePicker.view theme (embeddedTimeOptions opts TimeStart))
         ]
            ++ timePanelIf theme opts opts.timePickerStartShow TimeStart
            ++ [ dateInputNode theme opts (Single (Maybe.map Tuple.second (rangeOf opts))) (isEndValueInvalid opts)
               , embedHtml (TimePicker.view theme (embeddedTimeOptions opts TimeEnd))
               ]
            ++ timePanelIf theme opts opts.timePickerEndShow TimeEnd
        )
    ]


rangeOf : Options msg -> Maybe ( Int, Int )
rangeOf opts =
    case opts.value of
        Range r ->
            r

        _ ->
            Nothing


{-| The embedded `div.n-date-panel-date-input` NInput
(`datetime.tsx:50-62`). The display format is the en-US `dateFormat`
(`'yyyy-MM-dd'`); the port carries no separate `dateFormat` option.
-}
dateInputNode : Theme -> Options msg -> Value -> Bool -> Html msg
dateInputNode theme opts value invalid =
    let
        d =
            Input.defaults
    in
    embedHtml <|
        Input.view theme
            { d
                | value =
                    case value of
                        Single (Just ts) ->
                            DT.format "yyyy-MM-dd" opts.zone ts

                        Range (Just ( a, _ )) ->
                            DT.format "yyyy-MM-dd" opts.zone a

                        _ ->
                            ""
                , onInput = opts.onInput
                , placeholder = Just "Select Date"
                , size = T.Small
                , readonly = opts.inputReadonly
                , stateful = False
                , textDecoration = invalidDecoration invalid
                , extraRootClasses = [ "n-date-panel-date-input" ]
            }


{-| The embedded `NUI.TimePicker` body, rendered inline after the trigger when
the caller's show flag is set (the port's caller-mounted convention).
-}
timePanelIf : Theme -> Options msg -> Bool -> TimeSlot -> List (Html msg)
timePanelIf theme opts shown slot =
    if shown then
        [ embedHtml (TimePicker.panel theme (embeddedTimeOptions opts slot)) ]

    else
        []


embeddedTimeOptions : Options msg -> TimeSlot -> TimePicker.Options msg
embeddedTimeOptions opts slot =
    let
        d =
            TimePicker.defaultOptions
    in
    { d
        | value = timeSlotValue opts slot
        , format = Maybe.withDefault "HH:mm:ss" opts.timePickerFormat
        , size = T.Small
        , showIcon = False
        , disabled = opts.selecting && opts.type_ == Datetimerange
        , zone = opts.zone
        , now = opts.now
        , onUpdateValue =
            Maybe.map (\f -> \maybeTs -> f (timeSlotNextValue opts slot maybeTs)) (preferredChannel opts)
        , isHourDisabled = Maybe.map (\f -> f.isHourDisabled) (slotValidator opts slot)
        , isMinuteDisabled = Maybe.map (\f -> f.isMinuteDisabled) (slotValidator opts slot)
        , isSecondDisabled = Maybe.map (\f -> f.isSecondDisabled) (slotValidator opts slot)
    }


{-| The embedded picker's change target — upstream `handleTimePickerChange`
(`use-calendar.ts:488-491` → `doUpdateValue(value, props.panel)`), a
purely-value interaction, so the pending channel is the primary one.
-}
preferredChannel : Options msg -> Maybe (Value -> msg)
preferredChannel opts =
    case ( opts.onUpdatePendingValue, opts.onUpdateValue, opts.onUpdateFormattedValue ) of
        ( Just f, _, _ ) ->
            Just f

        ( Nothing, Just f, _ ) ->
            Just f

        ( Nothing, Nothing, Just f ) ->
            Just (toFormatted opts >> f)

        _ ->
            Nothing


timeSlotValue : Options msg -> TimeSlot -> Maybe Int
timeSlotValue opts slot =
    case opts.value of
        Single (Just ts) ->
            if slot == TimeStart then
                Just ts

            else
                Nothing

        Range (Just ( a, b )) ->
            if slot == TimeStart then
                Just a

            else
                Just b

        _ ->
            Nothing


timeSlotNextValue : Options msg -> TimeSlot -> Maybe Int -> Value
timeSlotNextValue opts slot maybeTs =
    case opts.value of
        Range (Just ( a, b )) ->
            if slot == TimeStart then
                Range (Just ( Maybe.withDefault a maybeTs, b ))

            else
                Range (Just ( a, Maybe.withDefault b maybeTs ))

        _ ->
            Single maybeTs


slotValidator : Options msg -> TimeSlot -> Maybe { isHourDisabled : Int -> Bool, isMinuteDisabled : Int -> Maybe Int -> Bool, isSecondDisabled : Int -> Maybe Int -> Maybe Int -> Bool }
slotValidator opts slot =
    Maybe.andThen (\ts -> Maybe.map (\f -> f ts) opts.isTimeDisabled) (timeSlotValue opts slot)



-- ACTIONS ----------------------------------------------------------------------


actionsSlot : Theme -> Options msg -> List (Html msg)
actionsSlot theme opts =
    let
        acts =
            mergedActions opts

        shortcuts =
            effectiveShortcuts opts

        visible =
            if isRangeType opts.type_ then
                List.filterMap (rangeShortcutButton theme opts) shortcuts

            else
                List.filterMap (singleShortcutButton theme opts) shortcuts
    in
    if List.isEmpty acts && List.isEmpty shortcuts then
        []

    else
        [ Html.div [ HA.class "n-date-panel-actions" ]
            [ Html.div [ HA.class "n-date-panel-actions__prefix" ] (List.map embedHtml visible)
            , Html.div [ HA.class "n-date-panel-actions__suffix" ] (List.map embedHtml (List.filterMap (suffixButton theme opts) acts))
            ]
        ]


mergedActions : Options msg -> List DateAction
mergedActions opts =
    case opts.actions of
        Just acts ->
            acts

        Nothing ->
            defaultActions opts.type_ opts.clearable


{-| Upstream `shortcuts || ranges` (`use-dual-calendar.ts:227-230`).
-}
effectiveShortcuts : Options msg -> List ( String, ShortcutValue )
effectiveShortcuts opts =
    if List.isEmpty opts.shortcuts then
        List.map (\( name, ( a, b ) ) -> ( name, ShortcutRange ( a, b ) )) opts.ranges

    else
        opts.shortcuts


singleShortcutButton : Theme -> Options msg -> ( String, ShortcutValue ) -> Maybe (Element msg)
singleShortcutButton theme opts ( name, sv ) =
    case sv of
        ShortcutSingle _ ->
            Just (shortcutButton theme opts name sv)

        ShortcutRange _ ->
            Nothing


rangeShortcutButton : Theme -> Options msg -> ( String, ShortcutValue ) -> Maybe (Element msg)
rangeShortcutButton theme opts ( name, sv ) =
    case sv of
        ShortcutRange _ ->
            Just (shortcutButton theme opts name sv)

        ShortcutSingle _ ->
            Nothing


{-| A `NxButton size="tiny"` shortcut with the preview / commit / restore pair
(`use-calendar.ts:492-506`, `use-dual-calendar.ts:726-745`).
-}
shortcutButton : Theme -> Options msg -> String -> ShortcutValue -> Element msg
shortcutButton theme opts name sv =
    let
        d =
            Button.defaults

        effect phase =
            if isRangeType opts.type_ then
                rangeShortcutEffect phase sv

            else
                singleShortcutEffect phase sv

        commitMsg =
            Maybe.andThen (\eff -> commitOf opts eff.value) (effect ShortcutDone)

        previewMsg =
            Maybe.andThen (\eff -> pendingOf opts eff.value) (effect ShortcutPreview)

        restoreMsg =
            pendingOf opts opts.value
    in
    Button.view theme
        { d
            | size = T.Tiny
            , attributes =
                elAttrs
                    (onClickAttr commitMsg
                        ++ onMouseEnterAttr previewMsg
                        ++ onMouseLeaveAttr restoreMsg
                    )
        }
        [ Element.text name ]


commitOf : Options msg -> Value -> Maybe msg
commitOf opts value =
    case opts.onUpdateValue of
        Just f ->
            Just (f value)

        Nothing ->
            Maybe.map (\f -> f (toFormatted opts value)) opts.onUpdateFormattedValue


pendingOf : Options msg -> Value -> Maybe msg
pendingOf opts value =
    Maybe.map (\f -> f value) opts.onUpdatePendingValue


suffixButton : Theme -> Options msg -> DateAction -> Maybe (Element msg)
suffixButton theme opts act =
    let
        d =
            Button.defaults
    in
    case act of
        Clear ->
            Just (clearButton theme opts)

        Now ->
            Just
                (Button.view theme
                    { d
                        | size = T.Tiny
                        , attributes = elAttrs (onClickAttr (nowMsg opts))
                    }
                    [ Element.text "Now" ]
                )

        Confirm ->
            Just
                (Button.view theme
                    { d
                        | size = T.Tiny
                        , kind = T.Primary
                        , disabled = confirmDisabled opts
                        , attributes = elAttrs (onClickAttr opts.onConfirm)
                    }
                    [ Element.text "Confirm" ]
                )


{-| Upstream `handleClearClick` (`use-panel-common.ts:108-112`) commits an
empty value, closes and fires `onClear`. One message per event: `onClear` when
set, else the committed empty value.
-}
clearButton : Theme -> Options msg -> Element msg
clearButton theme opts =
    let
        d =
            Button.defaults

        msg =
            case opts.onClear of
                Just m ->
                    Just m

                Nothing ->
                    commitOf opts (emptyValue opts.type_)
    in
    Button.view theme
        { d
            | size = T.Tiny
            , attributes = elAttrs (onClickAttr msg)
        }
        [ Element.text "Clear" ]


emptyValue : PanelType -> Value
emptyValue type_ =
    if isRangeType type_ then
        Range Nothing

    else
        Single Nothing


nowMsg : Options msg -> Maybe msg
nowMsg opts =
    if isRangeType opts.type_ then
        Nothing

    else
        commitOf opts (singleNow { type_ = opts.type_, now = Time.posixToMillis opts.now, zone = opts.zone }).value



-- VALIDATION -------------------------------------------------------------------


isDateInvalidSingle : Options msg -> Bool
isDateInvalidSingle opts =
    case ( opts.value, opts.isDateDisabled ) of
        ( Single (Just ts), Just pred ) ->
            if List.member opts.type_ [ Date, Datetime ] then
                pred ts (SingleDetail (civilDetail InputDetail opts.zone ts))

            else
                False

        _ ->
            False


{-| Upstream `uniCalendarValidation.isTimeInvalidRef` (datetime only) with the
`second = time.getMinutes()` bug preserved (`validation-utils.ts:55`).
-}
isTimeInvalidSingle : Options msg -> Bool
isTimeInvalidSingle opts =
    case opts.value of
        Single (Just ts) ->
            if opts.type_ == Datetime then
                let
                    tf =
                        DT.toTimeFields opts.zone ts

                    hour =
                        tf.hours

                    minute =
                        tf.minutes
                in
                isHourDisabledOf opts ts hour
                    || isMinuteDisabledOf opts ts minute hour
                    || isSecondDisabledOf opts ts minute minute hour

            else
                False

        _ ->
            False


isValueInvalid : Options msg -> Bool
isValueInvalid opts =
    case opts.type_ of
        Date ->
            isDateInvalidSingle opts

        Datetime ->
            isDateInvalidSingle opts || isTimeInvalidSingle opts

        _ ->
            False


isStartDateInvalid : Options msg -> Bool
isStartDateInvalid opts =
    case ( opts.value, opts.isDateDisabled ) of
        ( Range (Just ( a, b )), Just pred ) ->
            if List.member opts.type_ [ Daterange, Datetimerange ] then
                pred a (RangeDetail RangeStart (Just ( a, b )))

            else
                False

        _ ->
            False


isEndDateInvalid : Options msg -> Bool
isEndDateInvalid opts =
    case ( opts.value, opts.isDateDisabled ) of
        ( Range (Just ( a, b )), Just pred ) ->
            if List.member opts.type_ [ Daterange, Datetimerange ] then
                pred b (RangeDetail RangeEnd (Just ( a, b )))

            else
                False

        _ ->
            False


isStartTimeInvalid : Options msg -> Bool
isStartTimeInvalid opts =
    case ( opts.value, opts.type_ ) of
        ( Range (Just ( a, _ )), Datetimerange ) ->
            let
                tf =
                    DT.toTimeFields opts.zone a
            in
            isHourDisabledOf opts a tf.hours
                || isMinuteDisabledOf opts a tf.minutes tf.hours
                || isSecondDisabledOf opts a tf.seconds tf.minutes tf.hours

        _ ->
            False


isEndTimeInvalid : Options msg -> Bool
isEndTimeInvalid opts =
    case ( opts.value, opts.type_ ) of
        ( Range (Just ( _, b )), Datetimerange ) ->
            let
                tf =
                    DT.toTimeFields opts.zone b
            in
            isHourDisabledOf opts b tf.hours
                || isMinuteDisabledOf opts b tf.minutes tf.hours
                || isSecondDisabledOf opts b tf.seconds tf.minutes tf.hours

        _ ->
            False


isStartValueInvalid : Options msg -> Bool
isStartValueInvalid opts =
    isStartDateInvalid opts || isStartTimeInvalid opts


isEndValueInvalid : Options msg -> Bool
isEndValueInvalid opts =
    isEndDateInvalid opts || isEndTimeInvalid opts


isRangeInvalid : Options msg -> Bool
isRangeInvalid opts =
    isStartValueInvalid opts || isEndValueInvalid opts


isHourDisabledOf : Options msg -> Int -> Int -> Bool
isHourDisabledOf opts ts hour =
    case opts.isTimeDisabled of
        Just f ->
            (f ts).isHourDisabled hour

        Nothing ->
            False


isMinuteDisabledOf : Options msg -> Int -> Int -> Int -> Bool
isMinuteDisabledOf opts ts minute hour =
    case opts.isTimeDisabled of
        Just f ->
            (f ts).isMinuteDisabled minute (Just hour)

        Nothing ->
            False


isSecondDisabledOf : Options msg -> Int -> Int -> Int -> Int -> Bool
isSecondDisabledOf opts ts second minute hour =
    case opts.isTimeDisabled of
        Just f ->
            (f ts).isSecondDisabled second (Just minute) (Just hour)

        Nothing ->
            False


confirmDisabled : Options msg -> Bool
confirmDisabled opts =
    case opts.type_ of
        Daterange ->
            isRangeInvalid opts || opts.selecting

        Datetimerange ->
            isRangeInvalid opts || opts.selecting

        Monthrange ->
            isRangeInvalid opts

        Yearrange ->
            isRangeInvalid opts

        Quarterrange ->
            isRangeInvalid opts

        Datetime ->
            isDateInvalidSingle opts

        Month ->
            isDateInvalidSingle opts

        Quarter ->
            isDateInvalidSingle opts

        _ ->
            False


civilDetail : DetailType -> Time.Zone -> Int -> { type_ : DetailType, year : Int, month : Int, date : Int }
civilDetail dt zone ts =
    let
        c =
            DT.toCivil zone ts
    in
    { type_ = dt, year = c.year, month = c.month, date = c.day }



-- MESSAGE PLUMBING -------------------------------------------------------------


toFormatted : Options msg -> Value -> FormattedValue
toFormatted opts value =
    let
        vf =
            Maybe.withDefault (mergedFormat opts) opts.valueFormat
    in
    case value of
        Single ts ->
            SingleF (Maybe.map (DT.format vf opts.zone) ts)

        Range r ->
            RangeF (Maybe.map (\( a, b ) -> ( DT.format vf opts.zone a, DT.format vf opts.zone b )) r)


onClickAttr : Maybe msg -> List (Html.Attribute msg)
onClickAttr maybeMsg =
    case maybeMsg of
        Just m ->
            [ HE.onClick m ]

        Nothing ->
            []


{-| `Html.Attribute` → elm-ui `Element.Attribute` (the `Button.attributes` seam).
-}
elAttrs : List (Html.Attribute msg) -> List (Element.Attribute msg)
elAttrs =
    List.map Element.htmlAttribute


onMouseEnterAttr : Maybe msg -> List (Html.Attribute msg)
onMouseEnterAttr maybeMsg =
    case maybeMsg of
        Just m ->
            [ HE.onMouseEnter m ]

        Nothing ->
            []


onMouseLeaveAttr : Maybe msg -> List (Html.Attribute msg)
onMouseLeaveAttr maybeMsg =
    case maybeMsg of
        Just m ->
            [ HE.onMouseLeave m ]

        Nothing ->
            []



-- GLYPHS -----------------------------------------------------------------------


dateSvg : Html msg
dateSvg =
    Svg.node "svg"
        [ HA.attribute "width" "28px"
        , HA.attribute "height" "28px"
        , HA.attribute "viewBox" "0 0 28 28"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Svg.node "path"
                    [ HA.attribute "d" "M21.75,3 C23.5449254,3 25,4.45507456 25,6.25 L25,21.75 C25,23.5449254 23.5449254,25 21.75,25 L6.25,25 C4.45507456,25 3,23.5449254 3,21.75 L3,6.25 C3,4.45507456 4.45507456,3 6.25,3 L21.75,3 Z M23.5,9.503 L4.5,9.503 L4.5,21.75 C4.5,22.7164983 5.28350169,23.5 6.25,23.5 L21.75,23.5 C22.7164983,23.5 23.5,22.7164983 23.5,21.75 L23.5,9.503 Z M21.75,4.5 L6.25,4.5 C5.28350169,4.5 4.5,5.28350169 4.5,6.25 L4.5,8.003 L23.5,8.003 L23.5,6.25 C23.5,5.28350169 22.7164983,4.5 21.75,4.5 Z" ]
                    []
                ]
            ]
        ]


toSvg : Html msg
toSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Svg.node "path" [ HA.attribute "d" toPath ] [] ]
            ]
        ]


toPath : String
toPath =
    "M11.2654,3.20511 C10.9644,2.92049 10.4897,2.93371 10.2051,3.23464 C9.92049,3.53558 9.93371,4.01027 10.2346,4.29489 L15.4737,9.25 L2.75,9.25 C2.33579,9.25 2,9.58579 2,10.0000012 C2,10.4142 2.33579,10.75 2.75,10.75 L15.476,10.75 L10.2346,15.7073 C9.93371,15.9919 9.92049,16.4666 10.2051,16.7675 C10.4897,17.0684 10.9644,17.0817 11.2654,16.797 L17.6826,10.7276 C17.8489,10.5703 17.9489,10.3702 17.9826,10.1614 C17.994,10.1094 18,10.0554 18,10.0000012 C18,9.94241 17.9935,9.88633 17.9812,9.83246 C17.9462,9.62667 17.8467,9.42976 17.6826,9.27455 L11.2654,3.20511 Z"


backwardSvg : Html msg
backwardSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M12.2674 15.793C11.9675 16.0787 11.4927 16.0672 11.2071 15.7673L6.20572 10.5168C5.9298 10.2271 5.9298 9.7719 6.20572 9.48223L11.2071 4.23177C11.4927 3.93184 11.9675 3.92031 12.2674 4.206C12.5673 4.49169 12.5789 4.96642 12.2932 5.26634L7.78458 9.99952L12.2932 14.7327C12.5789 15.0326 12.5673 15.5074 12.2674 15.793Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


forwardSvg : Html msg
forwardSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M7.73271 4.20694C8.03263 3.92125 8.50737 3.93279 8.79306 4.23271L13.7944 9.48318C14.0703 9.77285 14.0703 10.2281 13.7944 10.5178L8.79306 15.7682C8.50737 16.0681 8.03263 16.0797 7.73271 15.794C7.43279 15.5083 7.42125 15.0336 7.70694 14.7336L12.2155 10.0005L7.70694 5.26729C7.42125 4.96737 7.43279 4.49264 7.73271 4.20694Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


fastBackwardSvg : Html msg
fastBackwardSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Svg.node "path"
                    [ HA.attribute "d" "M8.73171,16.7949 C9.03264,17.0795 9.50733,17.0663 9.79196,16.7654 C10.0766,16.4644 10.0634,15.9897 9.76243,15.7051 L4.52339,10.75 L17.2471,10.75 C17.6613,10.75 17.9971,10.4142 17.9971,10 C17.9971,9.58579 17.6613,9.25 17.2471,9.25 L4.52112,9.25 L9.76243,4.29275 C10.0634,4.00812 10.0766,3.53343 9.79196,3.2325 C9.50733,2.93156 9.03264,2.91834 8.73171,3.20297 L2.31449,9.27241 C2.14819,9.4297 2.04819,9.62981 2.01448,9.8386 C2.00308,9.89058 1.99707,9.94459 1.99707,10 C1.99707,10.0576 2.00356,10.1137 2.01585,10.1675 C2.05084,10.3733 2.15039,10.5702 2.31449,10.7254 L8.73171,16.7949 Z" ]
                    []
                ]
            ]
        ]


fastForwardSvg : Html msg
fastForwardSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Svg.node "path" [ HA.attribute "d" toPath ] [] ]
            ]
        ]



-- EMBED ------------------------------------------------------------------------


{-| An `Element` inside the raw panel `Html` — the `NUI.TimePicker.embedHtml`
idiom.
-}
embedHtml : Element msg -> Html msg
embedHtml el =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        el



-- SMALL HELPERS ----------------------------------------------------------------


{-| The all-`Nothing` field record `NUI.Internal.DateTime.setFields` takes.
-}
noFields : { year : Maybe Int, month : Maybe Int, day : Maybe Int, hours : Maybe Int, minutes : Maybe Int, seconds : Maybe Int, quarter : Maybe Int }
noFields =
    { year = Nothing, month = Nothing, day = Nothing, hours = Nothing, minutes = Nothing, seconds = Nothing, quarter = Nothing }


zeroTime : { hours : Int, minutes : Int, seconds : Int, ms : Int }
zeroTime =
    { hours = 0, minutes = 0, seconds = 0, ms = 0 }
