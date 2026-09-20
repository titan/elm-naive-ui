module NUI.Calendar exposing
    ( Date
    , Locale
    , Options
    , Panel
    , addMonthsPanel
    , cssVarsFor
    , defaults
    , enUS
    , panelOf
    , todayPanel
    , view
    )

{-| Naive UI's `Calendar`, rebuilt on elm-ui.

    NUI.Calendar.view theme
        { NUI.Calendar.defaults
            | panel = { year = 2026, month = 7 }
            , now = { year = 2026, month = 7, day = 15 }
            , value = Just { year = 2026, month = 7, day = 20 }
        }

The element carries the `.n-calendar` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS. The header buttons are real
`NUI.Button`s in an `NUI.ButtonGroup` (small, like upstream), and the month grid
reproduces the `dateArray` layout from Naive UI's date-picker (`strip` mode):
whole display month, previous-month days in front, next-month days padded to
28 / 35 / 42 cells.

**Caller-owned runtime.** Upstream keeps the displayed month (`monthTs`), the
selected value and "now" in Vue refs; this library is pure, so all three are
options and every state change is a message you wire yourself:

  - `panel` — the displayed month. The prev / today / next header buttons emit
    `onPanelChange` with the **target** panel (upstream mutates `monthTs` itself
    and then fires `onPanelChange`); set `panel` from the payload to follow.
    The today button only emits when the panel would actually change, exactly
    like upstream's `oldYear !== newYear || oldMonth !== newMonth` guard.
  - `value` / `onUpdateValue` — the selected date. Clicking a cell emits the
    clicked `Date`; disabled cells emit nothing. Upstream additionally fires
    `onPanelChange` when an other-month cell is clicked (it moves the panel to
    that month) — a single Elm message cannot fire both, so apply that panel
    change in your `onUpdateValue` handler when the date's month differs from
    `panel`.
  - `now` — the reference date for the `--current` cell and the today button.
    `defaults` cannot know it; always set `panel` and `now`.

**Locale** replaces upstream's `useLocale('DatePicker')` + date-fns locale:
weekday names (the first grid row's `format(ts, 'EEE')` labels), month names,
the header title formatter and `firstDayOfWeek` (Naive UI convention: 0 is
Monday … 6 is Sunday; `enUS` is 6, so weeks start on Sunday). The grid walks
backwards through the previous month until the day **before** the configured
first day — a byte-for-byte port of `dateArray`'s `getDay` loop.

**Slots.** Upstream's `header` slot is a plain `Maybe (Element msg)` (it cannot
react to the panel), and the default cell slot is `cell : Maybe (Date -> …)`
(receives the cell's date; upstream passes `{ year, month (1-based), date }`).

Two deliberate divergences, both invisible in the browser: upstream's
`DateItem.month` is 0-based while `Date` here is 1-based; and upstream also
emits `n-calendar-cell--not-allowed` next to `--disabled`, a marker class no
CSS rule targets (both are emitted here; `--disabled` carries the styles).

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Button as Button
import NUI.ButtonGroup as ButtonGroup
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Calendar as CalendarTheme
import NUI.Types as T


{-| A calendar day. `month` is 1–12 (upstream's `DateItem` is 0-based). Pure
data — no time, no timezone.
-}
type alias Date =
    { year : Int
    , month : Int
    , day : Int
    }


{-| A displayed month — upstream's `monthTs` (a start-of-month timestamp).
`month` is 1–12.
-}
type alias Panel =
    { year : Int
    , month : Int
    }


{-| Replaces upstream's `useLocale('DatePicker')` and its date-fns locale.
-}
type alias Locale =
    { firstDayOfWeek : Int
    , monthNames : List String
    , weekdayNames : List String
    , today : String
    , title : Panel -> String
    }


{-| Naive UI's `enUS` locale: full month names, abbreviated weekday names
(`format(ts, 'EEE')`), month-before-year title, "Today", weeks starting Sunday
(`firstDayOfWeek = 6`).
-}
enUS : Locale
enUS =
    { firstDayOfWeek = 6
    , monthNames =
        [ "January"
        , "February"
        , "March"
        , "April"
        , "May"
        , "June"
        , "July"
        , "August"
        , "September"
        , "October"
        , "November"
        , "December"
        ]
    , weekdayNames = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ]
    , today = "Today"
    , title = \{ year, month } -> monthName month ++ " " ++ String.fromInt year
    }


type alias Options msg =
    { panel : Panel
    , now : Date
    , value : Maybe Date
    , locale : Locale
    , isDateDisabled : Maybe (Date -> Bool)
    , header : Maybe (Element msg)
    , cell : Maybe (Date -> List (Element msg))
    , onUpdateValue : Maybe (Date -> msg)
    , onPanelChange : Maybe (Panel -> msg)
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { panel = { year = 1970, month = 1 }
    , now = { year = 1970, month = 1, day = 1 }
    , value = Nothing
    , locale = enUS
    , isDateDisabled = Nothing
    , header = Nothing
    , cell = Nothing
    , onUpdateValue = Nothing
    , onPanelChange = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> Element msg
view theme opts =
    Element.column
        ([ I.classes [ "n-calendar" ]
         , I.cssVars (cssVarsFor theme)
         ]
            ++ opts.attributes
        )
        [ headerEl theme opts
        , Element.row
            [ I.classes [ "n-calendar-dates" ] ]
            (List.indexedMap (cellEl opts) (grid opts))
        ]


headerEl : Theme -> Options msg -> Element msg
headerEl theme opts =
    let
        titleContent =
            case opts.header of
                Just h ->
                    h

                Nothing ->
                    Element.text (opts.locale.title opts.panel)
    in
    Element.row
        [ I.classes [ "n-calendar-header" ] ]
        [ Element.el [ I.classes [ "n-calendar-header__title" ] ] titleContent
        , Element.row
            [ I.classes [ "n-calendar-header__extra" ] ]
            [ ButtonGroup.view theme
                ButtonGroup.defaults
                [ prevButton theme opts
                , todayButton theme opts
                , nextButton theme opts
                ]
            ]
        ]


prevButton : Theme -> Options msg -> Element msg
prevButton theme opts =
    let
        base =
            Button.defaults
    in
    Button.view theme
        { base
            | size = T.Small
            , icon = Just (calendarIcon "n-calendar-prev-btn" chevronLeftSvg)
            , onPress = panelMsg opts (addMonthsPanel opts.panel -1)
        }
        []


nextButton : Theme -> Options msg -> Element msg
nextButton theme opts =
    let
        base =
            Button.defaults
    in
    Button.view theme
        { base
            | size = T.Small
            , icon = Just (calendarIcon "n-calendar-next-btn" chevronRightSvg)
            , onPress = panelMsg opts (addMonthsPanel opts.panel 1)
        }
        []


todayButton : Theme -> Options msg -> Element msg
todayButton theme opts =
    let
        base =
            Button.defaults

        -- upstream fires onPanelChange only when the panel actually changes
        onPress =
            Maybe.andThen (panelMsg opts) (todayPanel opts)
    in
    Button.view theme
        { base
            | size = T.Small
            , onPress = onPress
        }
        [ Element.text opts.locale.today ]


{-| The panel the Today button jumps to — `Just` the month of `now`, or
`Nothing` when the panel already shows it. Upstream fires `onPanelChange` only
when the panel actually changes (`oldYear !== newYear || oldMonth !== newMonth`).
-}
todayPanel : Options msg -> Maybe Panel
todayPanel opts =
    let
        nowPanel =
            panelOf opts.now
    in
    if nowPanel /= opts.panel then
        Just nowPanel

    else
        Nothing


panelMsg : Options msg -> Panel -> Maybe msg
panelMsg opts target =
    Maybe.map (\toMsg -> toMsg target) opts.onPanelChange


{-| A cell of the month grid, rendered as `.n-calendar-cell`.
-}
cellEl : Options msg -> Int -> Cell -> Element msg
cellEl opts index cell =
    let
        disabled =
            Maybe.map (\isDisabled -> isDisabled cell.date) opts.isDateDisabled
                |> Maybe.withDefault False

        notInCurrentMonth =
            not cell.inCurrentMonth

        classes =
            [ "n-calendar-cell" ]
                ++ I.classIf disabled "n-calendar-cell--disabled"
                ++ I.classIf disabled "n-calendar-cell--not-allowed"
                ++ I.classIf notInCurrentMonth "n-calendar-cell--other-month"
                ++ I.classIf cell.isCurrentDate "n-calendar-cell--current"
                ++ I.classIf cell.selected "n-calendar-cell--selected"

        click : List (Element.Attribute msg)
        click =
            if disabled then
                []

            else
                case opts.onUpdateValue of
                    Just toMsg ->
                        [ Events.onClick (toMsg cell.date) ]

                    Nothing ->
                        []

        fullDate =
            formatFullDate cell.date

        dateNode =
            Element.el
                [ I.classes [ "n-calendar-date__date" ]
                , Element.htmlAttribute (HA.attribute "title" fullDate)
                ]
                (Element.text (String.fromInt cell.date.day))

        dayNode =
            Element.el
                [ I.classes [ "n-calendar-date__day" ]
                , Element.htmlAttribute (HA.attribute "title" fullDate)
                ]
                (Element.text (weekdayName opts.locale cell.date))

        slotContent =
            case opts.cell of
                Just render ->
                    render cell.date

                Nothing ->
                    []
    in
    Element.column
        (I.classes classes :: click)
        (Element.row
            [ I.classes [ "n-calendar-date" ] ]
            (dateNode
                :: (if index < 7 then
                        [ dayNode ]

                    else
                        []
                   )
            )
            :: slotContent
            ++ [ Element.el [ I.classes [ "n-calendar-cell__bar" ] ] Element.none ]
        )



-- MONTH GRID (upstream: dateArray(monthTs, value, now, firstDayOfWeek, strip = true))


{-| One day of the grid — upstream's `DateItem` (only the fields Calendar uses).
-}
type alias Cell =
    { date : Date
    , inCurrentMonth : Bool
    , isCurrentDate : Bool
    , selected : Bool
    }


grid : Options msg -> List Cell
grid opts =
    let
        first =
            { year = opts.panel.year, month = opts.panel.month, day = 1 }

        prevDays =
            prevMonthDays (addDays first -1) opts.locale.firstDayOfWeek

        currentDays =
            monthDays first

        shown =
            List.length prevDays + List.length currentDays

        endIndex =
            if shown <= 28 then
                28

            else if shown <= 35 then
                35

            else
                42

        nextDays =
            nextMonthDays (addDays first (List.length currentDays)) (endIndex - shown)
    in
    List.map (toCell opts) (prevDays ++ currentDays ++ nextDays)


toCell : Options msg -> Date -> Cell
toCell opts date =
    { date = date
    , inCurrentMonth = date.year == opts.panel.year && date.month == opts.panel.month
    , isCurrentDate = date == opts.now
    , selected = opts.value == Just date
    }


{-| Days of the previous month to show, earliest first. Upstream unshifts while
`getDay(iterator) !== startDay`, so the loop stops one day _after_ the configured
first day of the week — with `enUS` (6) the grid starts on Sunday.
-}
prevMonthDays : Date -> Int -> List Date
prevMonthDays iterator startDay =
    if weekday iterator == startDay then
        []

    else
        prevMonthDays (addDays iterator -1) startDay ++ [ iterator ]


monthDays : Date -> List Date
monthDays first =
    List.range 1 (daysInMonth first)
        |> List.map (\day -> { first | day = day })


nextMonthDays : Date -> Int -> List Date
nextMonthDays iterator count =
    if count <= 0 then
        []

    else
        iterator :: nextMonthDays (addDays iterator 1) (count - 1)



-- DATE MATH (internal, no dependencies: proleptic-Gregorian civil-day arithmetic)


{-| Days since 1970-01-01 (Howard Hinnant's `days_from_civil`).
-}
daysFromCivil : Date -> Int
daysFromCivil d =
    let
        y =
            if d.month <= 2 then
                d.year - 1

            else
                d.year

        era =
            y // 400

        yearOfEra =
            y - era * 400

        monthPrime =
            modBy 12 (d.month + 9)

        dayOfYear =
            (153 * monthPrime + 2) // 5 + d.day - 1

        dayOfEra =
            yearOfEra * 365 + yearOfEra // 4 - yearOfEra // 100 + dayOfYear
    in
    era * 146097 + dayOfEra - 719468


{-| Inverse of `daysFromCivil` (`civil_from_days`).
-}
civilFromDays : Int -> Date
civilFromDays z =
    let
        days =
            z + 719468

        era =
            days // 146097

        dayOfEra =
            days - era * 146097

        yearOfEra =
            (dayOfEra - dayOfEra // 1460 + dayOfEra // 36524 - dayOfEra // 146096)
                // 365

        year =
            yearOfEra + era * 400

        dayOfYear =
            dayOfEra - (365 * yearOfEra + yearOfEra // 4 - yearOfEra // 100)

        monthPrime =
            (5 * dayOfYear + 2) // 153

        day =
            dayOfYear - (153 * monthPrime + 2) // 5 + 1

        month =
            monthPrime
                + (if monthPrime < 10 then
                    3

                   else
                    -9
                  )
    in
    { year =
        year
            + (if month <= 2 then
                1

               else
                0
              )
    , month = month
    , day = day
    }


addDays : Date -> Int -> Date
addDays date n =
    civilFromDays (daysFromCivil date + n)


{-| Weekday in date-fns `getDay` numbering: 0 is Sunday … 6 is Saturday.
-}
weekday : Date -> Int
weekday date =
    modBy 7 (daysFromCivil date + 4)


daysInMonth : Date -> Int
daysInMonth date =
    let
        next =
            addMonthsPanel (panelOf date) 1
    in
    daysFromCivil { year = next.year, month = next.month, day = 1 }
        - daysFromCivil { year = date.year, month = date.month, day = 1 }


panelOf : Date -> Panel
panelOf date =
    { year = date.year, month = date.month }


{-| `addMonths` on a start-of-month panel (no day clamping needed).
-}
addMonthsPanel : Panel -> Int -> Panel
addMonthsPanel panel n =
    let
        total =
            panel.year * 12 + (panel.month - 1) + n
    in
    { year = total // 12
    , month = modBy 12 total + 1
    }


monthName : Int -> String
monthName month =
    List.drop (modBy 12 (month - 1)) enUS.monthNames
        |> List.head
        |> Maybe.withDefault ""


weekdayName : Locale -> Date -> String
weekdayName locale date =
    List.drop (weekday date) locale.weekdayNames
        |> List.head
        |> Maybe.withDefault ""


{-| Upstream's `format(ts, 'yyyy-MM-dd')` (the cells' `title`).
-}
formatFullDate : Date -> String
formatFullDate d =
    String.padLeft 4 '0' (String.fromInt d.year)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt d.month)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt d.day)



-- ICONS (Naive UI renders these through NBaseIcon: an `<i class="n-base-icon">`)


{-| The header arrows — upstream's `NBaseIcon` with the extra calendar class
(same chevrons as `NUI.Collapse`).
-}
calendarIcon : String -> Html.Html msg -> Element msg
calendarIcon extraClass svg =
    Element.html
        (Html.i [ HA.class (String.join " " [ "n-base-icon", extraClass ]) ] [ svg ])


chevronLeftSvg : Html.Html msg
chevronLeftSvg =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Html.node "path"
            [ HA.attribute "d" chevronLeftPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


chevronLeftPath : String
chevronLeftPath =
    "M10.3536 3.14645C10.5488 3.34171 10.5488 3.65829 10.3536 3.85355L6.20711 8L10.3536 12.1464C10.5488 12.3417 10.5488 12.6583 10.3536 12.8536C10.1583 13.0488 9.84171 13.0488 9.64645 12.8536L5.14645 8.35355C4.95118 8.15829 4.95118 7.84171 5.14645 7.64645L9.64645 3.14645C9.84171 2.95118 10.1583 2.95118 10.3536 3.14645Z"


chevronRightSvg : Html.Html msg
chevronRightSvg =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Html.node "path"
            [ HA.attribute "d" chevronRightPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


chevronRightPath : String
chevronRightPath =
    "M5.64645 3.14645C5.45118 3.34171 5.45118 3.65829 5.64645 3.85355L9.79289 8L5.64645 12.1464C5.45118 12.3417 5.45118 12.6583 5.64645 12.8536C5.84171 13.0488 6.15829 13.0488 6.35355 12.8536L10.8536 8.35355C11.0488 8.15829 11.0488 7.84171 10.8536 7.64645L6.35355 3.14645C6.15829 2.95118 5.84171 2.95118 5.64645 3.14645Z"


{-| The raw `--n-*` custom properties a calendar attaches (they do not depend on
the options). `view` uses exactly this list.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            CalendarTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-border-color-modal", v.borderColorModal )
    , ( "--n-border-color-popover", v.borderColorPopover )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-text-color", v.textColor )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-title-font-size", v.titleFontSize )
    , ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-day-text-color", v.dayTextColor )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-date-color-current", v.dateColorCurrent )
    , ( "--n-date-text-color-current", v.dateTextColorCurrent )
    , ( "--n-cell-color", v.cellColor )
    , ( "--n-cell-color-modal", v.cellColorModal )
    , ( "--n-cell-color-popover", v.cellColorPopover )
    , ( "--n-cell-color-hover", v.cellColorHover )
    , ( "--n-cell-color-hover-modal", v.cellColorHoverModal )
    , ( "--n-cell-color-hover-popover", v.cellColorHoverPopover )
    , ( "--n-bar-color", v.barColor )
    ]
