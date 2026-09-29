module NUI.Internal.DateTime exposing
    ( Civil
    , DateItem
    , Granularity(..)
    , MonthItem
    , QuarterItem
    , ValueTs(..)
    , YearItem
    , addDays
    , addMonthsClamped
    , addYearsClamped
    , civilFromDays
    , dateArray
    , daysFromCivil
    , daysInMonth
    , extractRangeDefaultTime
    , firstDayOfWeekToDateFns
    , format
    , getDefaultTime
    , matchDate
    , monthArray
    , pluckValueFromRange
    , quarterArray
    , quarterOf
    , setFields
    , startOfDay
    , startOfMonth
    , startOfQuarter
    , startOfSecond
    , startOfWeek
    , startOfWeekOn
    , startOfYear
    , strictParse
    , toCivil
    , toPosix
    , toTimeFields
    , weekNumber
    , weekYear
    , weekday
    , yearArray
    )

{-| The pure date/time engine behind `NUI.DatePicker` and `NUI.TimePicker` —
a port of Naive UI's `date-picker/src/utils.ts` plus the subset of date-fns v2
it depends on (format/parse token subset, `addMonths`/`set*`, `startOf*`,
`getWeek`/`getWeekYear`).

This module is **unexposed internal API**. It imports only `elm/core` and
`elm/time`; every timestamp is an `Int` of milliseconds. Civil interpretation
is always explicit: the zone-taking functions (`toCivil`, `toPosix`, `startOf*`,
`setFields`, `weekNumber`, …) build a local civil value from the caller's
`Time.Zone`, while the zone-less builders (`dateArray`, `monthArray`,
`quarterArray`, `yearArray`, `matchDate`) interpret their `Int` timestamps as
**UTC**.

    import NUI.Internal.DateTime as DT

    DT.format "yyyy-MM-dd" Time.utc (DT.toPosix Time.utc { year = 2024, month = 3, day = 15 } DT.midnight)
    --> "2024-03-15"


## Deviations from upstream (documented on purpose)

  - **Zone-less builders read UTC.** The pinned signatures of `dateArray`,
    `monthArray`, `quarterArray`, `yearArray` and `matchDate` take no
    `Time.Zone`, so their timestamps are interpreted in `Time.utc`. Under UTC
    they match date-fns exactly; the DatePicker layer is expected to hand them
    civil-day timestamps (i.e. `daysFromCivil`-based midnights) rather than
    zone-local instants. The zone-taking helpers cover everything else.
  - **`strictParse` reference date is the Unix epoch.** Upstream parses with a
    `referenceDate` of "now"; this module has no `now` argument, so missing
    fields are filled from `1970-01-01T00:00:00.000` interpreted in the given
    zone. The field-set matters only when the pattern omits that field.
  - **`format` / `strictParse` support a pinned token subset.** `yy yyyy (y+)`,
    `YYYY (Y+)`, `M MM MMM MMMM MMMMM` (and `L` stand-alone), `d dd`, `eee eeee
    eeeeee eeeeee-e` (local day of week, `E`/`e`/`c`), `H HH h hh K k`, `m mm
    s ss`, `Q qqq` (and `q`), `w`, `a`, plus `'…'` quoted literals and the `''`
    escape. Any other letters pass through verbatim (they are treated as
    literals) — upstream would format some of them and reject the rest during
    parsing.
  - **`addDays` is day-number arithmetic** (`addDays n dayNumber == dayNumber +
    n`); use `daysFromCivil` / `civilFromDays` to move between `Civil` and day
    numbers. There is no ts-level `addDays` (ts arithmetic always goes through a
    zone).
  - **Item records carry `type_`, not `type`.** Elm reserves the keyword `type`,
    so `MonthItem` / `QuarterItem` / `YearItem` expose the upstream discriminator
    as a `String` field named `type_` (`"month"` / `"quarter"` / `"year"`).
    `DateItem` has no discriminator (it is always a date).
  - **`DateItem.dateObject` is a `Civil`** (`{ year, month, day }`); upstream's
    `dateObject.date` is the `day` field here.
  - **Function-form `DefaultTime` is punted.** `extractRangeDefaultTime` takes
    two literal `'HH:mm:ss'` strings (one per range side) instead of upstream's
    `(timestamp, position, value)` extractor callback. A blank string means
    "no default time".
  - **Week numbering is `firstWeekContainsDate = 1`** everywhere
    (`weekNumber`, `weekYear`, and the `w` / `YYYY` format tokens), matching the
    en-US date-fns locale default (`{ weekStartsOn: 0, firstWeekContainsDate: 1
    }`), with `weekStartsOn = 0` for the two format tokens `[oracle S2]`.
    `dateArray`'s week-span matching uses its own `startDay` as `weekStartsOn`.

-}

import Time


{-| A calendar date. `month` is 1–12 (upstream `DateItem.dateObject` is
0-based; this port is not).
-}
type alias Civil =
    { year : Int
    , month : Int
    , day : Int
    }


{-| The granularity `matchDate` compares at.
-}
type Granularity
    = DateGran
    | MonthGran
    | YearGran
    | QuarterGran
    | WeekGran


{-| A picker value — upstream `Value` (`number | [number, number] | null`).
-}
type ValueTs
    = NoValue
    | SingleTs Int
    | RangeTs Int Int


{-| One day cell — upstream `DateItem`. `ts` is the cell's local midnight.
-}
type alias DateItem =
    { dateObject : Civil
    , inCurrentMonth : Bool
    , isCurrentDate : Bool
    , inSpan : Bool
    , startOfSpan : Bool
    , endOfSpan : Bool
    , selected : Bool
    , inSelectedWeek : Bool
    , ts : Int
    }


{-| One month cell — upstream `MonthItem` (the `type` field is `type_`).
-}
type alias MonthItem =
    { type_ : String
    , dateObject : { year : Int, month : Int }
    , ts : Int
    , isCurrent : Bool
    , selected : Bool
    , monthFormat : String
    }


{-| One quarter cell — upstream `QuarterItem`.
-}
type alias QuarterItem =
    { type_ : String
    , dateObject : { year : Int, quarter : Int }
    , ts : Int
    , isCurrent : Bool
    , selected : Bool
    , quarterFormat : String
    }


{-| One year cell — upstream `YearItem`.
-}
type alias YearItem =
    { type_ : String
    , dateObject : { year : Int }
    , ts : Int
    , isCurrent : Bool
    , selected : Bool
    , yearFormat : String
    }



-- INTERNAL LOCAL (civil date + wall-clock time, no zone attached)


type alias Local =
    { year : Int
    , month : Int
    , day : Int
    , hours : Int
    , minutes : Int
    , seconds : Int
    , ms : Int
    }


{-| Midnight, for the time record `toPosix` takes.
-}
midnight : { hours : Int, minutes : Int, seconds : Int, ms : Int }
midnight =
    { hours = 0, minutes = 0, seconds = 0, ms = 0 }


civilOfLocal : Local -> Civil
civilOfLocal l =
    { year = l.year, month = l.month, day = l.day }


withCivil : Civil -> Local -> Local
withCivil c l =
    { l | year = c.year, month = c.month, day = c.day }


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


floorDiv : Int -> Int -> Int
floorDiv a b =
    (a - modBy b a) // b


toLocalAt : Time.Zone -> Int -> Local
toLocalAt zone ts =
    let
        posix =
            Time.millisToPosix ts
    in
    { year = Time.toYear zone posix
    , month = monthToInt (Time.toMonth zone posix)
    , day = Time.toDay zone posix
    , hours = Time.toHour zone posix
    , minutes = Time.toMinute zone posix
    , seconds = Time.toSecond zone posix
    , ms = Time.toMillis zone posix
    }


{-| A local wall-clock reading as if it were UTC — the seed of `localToTs`.
-}
msOfLocal : Local -> Int
msOfLocal l =
    (daysFromCivil (civilOfLocal l) * 86400 + l.hours * 3600 + l.minutes * 60 + l.seconds) * 1000 + l.ms


{-| Civil-in-zone → instant, by fixed-point iteration on the zone offset (the
`NUI.Heatmap.converge` idiom, at millisecond resolution).
-}
localToTs : Time.Zone -> Local -> Int
localToTs zone local =
    let
        target =
            msOfLocal local

        step guess =
            target + (guess - msOfLocal (toLocalAt zone guess))

        iterate n guess =
            if n <= 0 then
                guess

            else
                iterate (n - 1) (step guess)
    in
    iterate 3 target



-- CIVIL-DAY ARITHMETIC (Howard Hinnant's proleptic Gregorian)


{-| Days since 1970-01-01.
-}
daysFromCivil : Civil -> Int
daysFromCivil d =
    let
        y =
            if d.month <= 2 then
                d.year - 1

            else
                d.year

        era =
            floorDiv y 400

        yoe =
            y - era * 400

        mp =
            modBy 12 (d.month + 9)

        doy =
            (153 * mp + 2) // 5 + d.day - 1

        doe =
            yoe * 365 + yoe // 4 - yoe // 100 + doy
    in
    era * 146097 + doe - 719468


{-| Inverse of `daysFromCivil`.
-}
civilFromDays : Int -> Civil
civilFromDays z =
    let
        days =
            z + 719468

        era =
            floorDiv days 146097

        doe =
            days - era * 146097

        yoe =
            (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365

        y =
            yoe + era * 400

        doy =
            doe - (365 * yoe + yoe // 4 - yoe // 100)

        mp =
            (5 * doy + 2) // 153

        day =
            doy - (153 * mp + 2) // 5 + 1

        month =
            mp
                + (if mp < 10 then
                    3

                   else
                    -9
                  )
    in
    { year =
        y
            + (if month <= 2 then
                1

               else
                0
              )
    , month = month
    , day = day
    }


{-| Day-number arithmetic: `addDays n dayNumber == dayNumber + n`.
-}
addDays : Int -> Int -> Int
addDays amount dayNumber =
    dayNumber + amount


{-| Weekday of a civil day in date-fns `getDay` numbering (0 = Sunday … 6 =
Saturday; 1970-01-01 was a Thursday).
-}
weekday : Civil -> Int
weekday c =
    weekdayOfDay (daysFromCivil c)


weekdayOfDay : Int -> Int
weekdayOfDay dayNumber =
    modBy 7 (dayNumber + 4)


{-| Number of days in a month.
-}
daysInMonth : Int -> Int -> Int
daysInMonth year month =
    let
        first =
            daysFromCivil { year = year, month = month, day = 1 }

        next =
            if month == 12 then
                daysFromCivil { year = year + 1, month = 1, day = 1 }

            else
                daysFromCivil { year = year, month = month + 1, day = 1 }
    in
    next - first


{-| date-fns `addMonths`: the day-of-month clamps to the shorter month.
-}
addMonthsClamped : Int -> Civil -> Civil
addMonthsClamped amount c =
    let
        total =
            c.year * 12 + (c.month - 1) + amount

        y2 =
            floorDiv total 12

        m2 =
            modBy 12 total + 1

        dim =
            daysInMonth y2 m2
    in
    { year = y2, month = m2, day = min c.day dim }


{-| date-fns `addYears` is `addMonths(date, amount * 12)`.
-}
addYearsClamped : Int -> Civil -> Civil
addYearsClamped amount c =
    addMonthsClamped (amount * 12) c



-- ZONE CONVERSION (public)


{-| The civil date of an instant in `zone`.
-}
toCivil : Time.Zone -> Int -> Civil
toCivil zone ts =
    civilOfLocal (toLocalAt zone ts)


{-| The wall-clock time-of-day of an instant in `zone`.
-}
toTimeFields : Time.Zone -> Int -> { hours : Int, minutes : Int, seconds : Int, ms : Int }
toTimeFields zone ts =
    let
        l =
            toLocalAt zone ts
    in
    { hours = l.hours, minutes = l.minutes, seconds = l.seconds, ms = l.ms }


{-| A civil date + time-of-day in `zone` as an instant.
-}
toPosix : Time.Zone -> Civil -> { hours : Int, minutes : Int, seconds : Int, ms : Int } -> Int
toPosix zone civil time =
    localToTs zone
        { year = civil.year
        , month = civil.month
        , day = civil.day
        , hours = time.hours
        , minutes = time.minutes
        , seconds = time.seconds
        , ms = time.ms
        }


{-| date-fns `startOfDay`.
-}
startOfDay : Time.Zone -> Int -> Int
startOfDay zone ts =
    toPosix zone (toCivil zone ts) midnight


{-| date-fns `startOfMonth`.
-}
startOfMonth : Time.Zone -> Int -> Int
startOfMonth zone ts =
    toPosix zone
        (let
            c =
                toCivil zone ts
         in
         { c | day = 1 }
        )
        midnight


{-| date-fns `startOfYear`.
-}
startOfYear : Time.Zone -> Int -> Int
startOfYear zone ts =
    toPosix zone
        (let
            c =
                toCivil zone ts
         in
         { c | month = 1, day = 1 }
        )
        midnight


{-| date-fns `startOfQuarter`.
-}
startOfQuarter : Time.Zone -> Int -> Int
startOfQuarter zone ts =
    let
        c =
            toCivil zone ts
    in
    toPosix zone { c | month = (c.month - 1) // 3 * 3 + 1, day = 1 } midnight


{-| date-fns `startOfSecond`.
-}
startOfSecond : Time.Zone -> Int -> Int
startOfSecond zone ts =
    localToTs zone
        (let
            l =
                toLocalAt zone ts
         in
         { l | ms = 0 }
        )


{-| date-fns `getQuarter` (1–4).
-}
quarterOf : Time.Zone -> Int -> Int
quarterOf zone ts =
    (toCivil zone ts).month - 1 |> (\m -> m // 3 + 1)


{-| date-fns `set` with `quarter` added, applied in date-fns priority order
(year 130 → quarter 120 → month 110 → day 90 → hours 70 → minutes 60 → seconds
50). Feb 29 clamps when the month moves; a lone year change overflows like
native `setFullYear` (via the day-number round-trip).
-}
setFields :
    Time.Zone
    -> Int
    ->
        { year : Maybe Int
        , month : Maybe Int
        , day : Maybe Int
        , hours : Maybe Int
        , minutes : Maybe Int
        , seconds : Maybe Int
        , quarter : Maybe Int
        }
    -> Int
setFields zone ts fields =
    let
        l0 =
            toLocalAt zone ts

        l1 =
            case fields.year of
                Just y ->
                    { l0 | year = y }

                Nothing ->
                    l0

        l2 =
            normalizeDay l1

        l3 =
            case fields.quarter of
                Just q ->
                    let
                        oldQ =
                            (l2.month - 1) // 3 + 1
                    in
                    setMonthLocal (l2.month + (q - oldQ) * 3) l2

                Nothing ->
                    l2

        l4 =
            case fields.month of
                Just m ->
                    setMonthLocal m l3

                Nothing ->
                    l3

        l5 =
            case fields.day of
                Just d ->
                    normalizeDay { l4 | day = d }

                Nothing ->
                    l4

        l6 =
            case fields.hours of
                Just h ->
                    { l5 | hours = h }

                Nothing ->
                    l5

        l7 =
            case fields.minutes of
                Just m ->
                    { l6 | minutes = m }

                Nothing ->
                    l6

        l8 =
            case fields.seconds of
                Just s ->
                    { l7 | seconds = s }

                Nothing ->
                    l7
    in
    localToTs zone l8


{-| Normalize a day-of-month overflow through the day-number round-trip (native
`setDate`/`setFullYear` overflow).
-}
normalizeDay : Local -> Local
normalizeDay l =
    withCivil (civilFromDays (daysFromCivil (civilOfLocal l))) l


{-| date-fns `setMonth` — the day clamps to the target month.
-}
setMonthLocal : Int -> Local -> Local
setMonthLocal month l =
    let
        total =
            l.year * 12 + (month - 1)

        y2 =
            floorDiv total 12

        m2 =
            modBy 12 total + 1
    in
    { l | year = y2, month = m2, day = min l.day (daysInMonth y2 m2) }



-- GRANULARITY


{-| date-fns `isSame*` for the given granularity. Timestamps are read in
`Time.utc` (see the module docs); `WeekGran` uses `weekStartsOn = 0`.
-}
matchDate : Granularity -> Int -> Int -> Bool
matchDate gran a b =
    case gran of
        DateGran ->
            toCivil Time.utc a == toCivil Time.utc b

        MonthGran ->
            sameMonthUtc a b

        YearGran ->
            (toCivil Time.utc a).year == (toCivil Time.utc b).year

        QuarterGran ->
            sameMonthUtcQuarters a b

        WeekGran ->
            isSameWeekWith 0 a b


sameMonthUtc : Int -> Int -> Bool
sameMonthUtc a b =
    let
        ca =
            toCivil Time.utc a

        cb =
            toCivil Time.utc b
    in
    ca.year == cb.year && ca.month == cb.month


sameMonthUtcQuarters : Int -> Int -> Bool
sameMonthUtcQuarters a b =
    let
        ca =
            toCivil Time.utc a

        cb =
            toCivil Time.utc b
    in
    (ca.year == cb.year) && ((ca.month - 1) // 3 == (cb.month - 1) // 3)


{-| Upstream `transformNaiveFirstDayOfWeekToDateFns`: Naive UI numbering
(0 = Monday … 6 = Sunday) to date-fns numbering (0 = Sunday … 6 = Saturday).
-}
firstDayOfWeekToDateFns : Int -> Int
firstDayOfWeekToDateFns firstDayOfWeek =
    modBy 7 (firstDayOfWeek + 1)


{-| date-fns `startOfWeek` with an explicit `weekStartsOn` (0 = Sunday).
-}
startOfWeekOn : Int -> Time.Zone -> Int -> Int
startOfWeekOn weekStartsOn zone ts =
    let
        dn =
            daysFromCivil (toCivil zone ts)
    in
    toPosix zone (civilFromDays (startOfWeekDay weekStartsOn dn)) midnight


{-| date-fns `startOfWeek` (`weekStartsOn = 0`).
-}
startOfWeek : Time.Zone -> Int -> Int
startOfWeek zone =
    startOfWeekOn 0 zone


startOfWeekDay : Int -> Int -> Int
startOfWeekDay weekStartsOn dayNumber =
    dayNumber - modBy 7 (weekdayOfDay dayNumber - weekStartsOn)


startOfWeekYearDay : Int -> Int -> Int
startOfWeekYearDay weekStartsOn year =
    startOfWeekDay weekStartsOn (daysFromCivil { year = year, month = 1, day = 1 })


isSameWeekWith : Int -> Int -> Int -> Bool
isSameWeekWith weekStartsOn a b =
    startOfWeekOn weekStartsOn Time.utc a == startOfWeekOn weekStartsOn Time.utc b


{-| date-fns `getWeekYear` with `firstWeekContainsDate = 1`.
-}
weekYear : Int -> Time.Zone -> Int -> Int
weekYear weekStartsOn zone ts =
    let
        dn =
            daysFromCivil (toCivil zone ts)

        year =
            (toCivil zone ts).year
    in
    if dn >= startOfWeekYearDay weekStartsOn (year + 1) then
        year + 1

    else if dn >= startOfWeekYearDay weekStartsOn year then
        year

    else
        year - 1


{-| date-fns `getWeek` with `firstWeekContainsDate = 1`.
-}
weekNumber : Int -> Time.Zone -> Int -> Int
weekNumber weekStartsOn zone ts =
    let
        dn =
            daysFromCivil (toCivil zone ts)

        wy =
            weekYear weekStartsOn zone ts
    in
    (startOfWeekDay weekStartsOn dn - startOfWeekYearDay weekStartsOn wy) // 7 + 1



-- GRID BUILDERS (upstream dateArray / monthArray / quarterArray / yearArray)
-- Timestamps are read in Time.utc — see the module docs.


{-| Upstream `dateArray(monthTs, valueTs, nowTs, startDay, strip, weekMode)`.
`startDay` is Naive UI's `firstDayOfWeek` (0 = Monday … 6 = Sunday) — passed
through unchanged, exactly as upstream compares it against date-fns `getDay`,
so the grid's first cell lands on the day _after_ `startDay` (the loop stops one
day into the week, giving `enUS`'s `6` a Sunday-start grid). `strip = False`
always yields 42 cells. Week-span matching transforms `startDay` with
`firstDayOfWeekToDateFns`. Built in `Time.utc`.
-}
dateArray : Int -> ValueTs -> Int -> Int -> Bool -> Bool -> List DateItem
dateArray monthTs valueTs nowTs startDay strip weekMode =
    let
        anchor =
            toCivil Time.utc monthTs

        displayMonth =
            anchor.month

        firstDn =
            daysFromCivil { year = anchor.year, month = anchor.month, day = 1 }

        collectPrev dn protect =
            if not protect && weekdayOfDay dn == startDay then
                []

            else
                dn :: collectPrev (dn - 1) False

        prev =
            List.reverse (collectPrev (firstDn - 1) True)

        collectCurrent dn =
            if (civilFromDays dn).month == displayMonth then
                dn :: collectCurrent (dn + 1)

            else
                []

        current =
            collectCurrent firstDn

        shown =
            List.length prev + List.length current

        endIndex =
            if strip then
                if shown <= 28 then
                    28

                else if shown <= 35 then
                    35

                else
                    42

            else
                42

        nextStart =
            firstDn + List.length current

        next =
            List.range nextStart (nextStart + (endIndex - shown) - 1)
    in
    List.map (toDateItem anchor valueTs nowTs startDay weekMode) (prev ++ current ++ next)


toDateItem : Civil -> ValueTs -> Int -> Int -> Bool -> Int -> DateItem
toDateItem anchor valueTs nowTs startDay weekMode dn =
    let
        civil =
            civilFromDays dn

        ts =
            toPosix Time.utc civil midnight

        flags =
            buildFlags weekMode startDay valueTs ts
    in
    { dateObject = civil
    , inCurrentMonth = civil.year == anchor.year && civil.month == anchor.month
    , isCurrentDate = matchDate DateGran nowTs ts
    , inSpan = flags.inSpan
    , startOfSpan = flags.startOfSpan
    , endOfSpan = flags.endOfSpan
    , selected = flags.selected
    , inSelectedWeek = flags.inSelectedWeek
    , ts = ts
    }


type alias Flags =
    { inSpan : Bool
    , startOfSpan : Bool
    , endOfSpan : Bool
    , selected : Bool
    , inSelectedWeek : Bool
    }


buildFlags : Bool -> Int -> ValueTs -> Int -> Flags
buildFlags weekMode startDay valueTs ts =
    let
        match =
            if weekMode then
                isSameWeekWith (firstDayOfWeekToDateFns startDay)

            else
                matchDate DateGran
    in
    case valueTs of
        NoValue ->
            { inSpan = False, startOfSpan = False, endOfSpan = False, selected = False, inSelectedWeek = False }

        SingleTs v ->
            if weekMode then
                { inSpan = False, startOfSpan = False, endOfSpan = False, selected = False, inSelectedWeek = match v ts }

            else
                { inSpan = False, startOfSpan = False, endOfSpan = False, selected = match v ts, inSelectedWeek = False }

        RangeTs a b ->
            let
                inSpan =
                    a < ts && ts < b
            in
            if weekMode then
                { inSpan = inSpan, startOfSpan = match a ts, endOfSpan = match b ts, selected = False, inSelectedWeek = match a ts || match b ts }

            else
                { inSpan = inSpan, startOfSpan = match a ts, endOfSpan = match b ts, selected = match a ts || match b ts, inSelectedWeek = False }


selectsAny : (Int -> Int -> Bool) -> ValueTs -> Int -> Bool
selectsAny match valueTs ts =
    case valueTs of
        NoValue ->
            False

        SingleTs v ->
            match v ts

        RangeTs a b ->
            match a ts || match b ts


{-| Upstream `monthArray(yearAnchorTs, valueTs, nowTs, { monthFormat })` — 12
months of the anchor's year, built in `Time.utc`.
-}
monthArray : Int -> ValueTs -> Int -> { monthFormat : String } -> List MonthItem
monthArray yearAnchorTs valueTs nowTs opts =
    let
        y0 =
            (toCivil Time.utc yearAnchorTs).year

        build i =
            let
                civil =
                    addMonthsClamped i { year = y0, month = 1, day = 1 }

                ts =
                    toPosix Time.utc civil midnight
            in
            { type_ = "month"
            , dateObject = { year = civil.year, month = civil.month }
            , ts = ts
            , isCurrent = matchDate MonthGran nowTs ts
            , selected = selectsAny (matchDate MonthGran) valueTs ts
            , monthFormat = opts.monthFormat
            }
    in
    List.range 0 11 |> List.map build


{-| Upstream `quarterArray(yearAnchorTs, valueTs, nowTs, { quarterFormat })` —
4 quarters of the anchor's year.
-}
quarterArray : Int -> ValueTs -> Int -> { quarterFormat : String } -> List QuarterItem
quarterArray yearAnchorTs valueTs nowTs opts =
    let
        y0 =
            (toCivil Time.utc yearAnchorTs).year

        build i =
            let
                civil =
                    addMonthsClamped (i * 3) { year = y0, month = 1, day = 1 }

                ts =
                    toPosix Time.utc civil midnight
            in
            { type_ = "quarter"
            , dateObject = { year = civil.year, quarter = i + 1 }
            , ts = ts
            , isCurrent = matchDate QuarterGran nowTs ts
            , selected = selectsAny (matchDate QuarterGran) valueTs ts
            , quarterFormat = opts.quarterFormat
            }
    in
    List.range 0 3 |> List.map build


{-| Upstream `yearArray(valueTs, nowTs, { yearFormat }, yearRange)` —
`yearRange[1] - yearRange[0]` years starting at `yearRange[0]`.
-}
yearArray : ValueTs -> Int -> { yearFormat : String } -> ( Int, Int ) -> List YearItem
yearArray valueTs nowTs opts ( from, to ) =
    List.range from (to - 1)
        |> List.map
            (\y ->
                let
                    ts =
                        toPosix Time.utc { year = y, month = 1, day = 1 } midnight
                in
                { type_ = "year"
                , dateObject = { year = y }
                , ts = ts
                , isCurrent = matchDate YearGran nowTs ts
                , selected = selectsAny (matchDate YearGran) valueTs ts
                , yearFormat = opts.yearFormat
                }
            )



-- DEFAULT TIME / VALUE HELPERS


{-| Upstream `getDefaultTime` — split an `'HH:mm:ss'` string. `Nothing` in,
`Nothing` out; a malformed string is `Nothing`.
-}
getDefaultTime : Maybe String -> Maybe { hours : Int, minutes : Int, seconds : Int }
getDefaultTime maybeStr =
    case maybeStr of
        Nothing ->
            Nothing

        Just str ->
            case String.split ":" str of
                [ h, m, s ] ->
                    Maybe.map3
                        (\hh mm ss -> { hours = hh, minutes = mm, seconds = ss })
                        (String.toInt (String.trim h))
                        (String.toInt (String.trim m))
                        (String.toInt (String.trim s))

                _ ->
                    Nothing


{-| Upstream `extractRangeDefaultTime`, with the function-form extractor punted
for two literal `'HH:mm:ss'` strings (blank means "no default time").
-}
extractRangeDefaultTime :
    String
    -> String
    ->
        { start : Maybe { hours : Int, minutes : Int, seconds : Int }
        , end : Maybe { hours : Int, minutes : Int, seconds : Int }
        }
extractRangeDefaultTime startStr endStr =
    { start = getDefaultTime (nonBlank startStr)
    , end = getDefaultTime (nonBlank endStr)
    }


nonBlank : String -> Maybe String
nonBlank s =
    if String.trim s == "" then
        Nothing

    else
        Just s


{-| Upstream `pluckValueFromRange`: 0 = start, 1 = end. A scalar value (or a
different index) is `Nothing`.
-}
pluckValueFromRange : ValueTs -> Int -> Maybe Int
pluckValueFromRange valueTs index =
    case valueTs of
        RangeTs a b ->
            if index == 0 then
                Just a

            else if index == 1 then
                Just b

            else
                Nothing

        _ ->
            Nothing



-- FORMAT


{-| date-fns `format` for the pinned token subset (see the module docs). Week
tokens use `weekStartsOn = 0` / `firstWeekContainsDate = 1`.
-}
format : String -> Time.Zone -> Int -> String
format pattern zone ts =
    let
        local =
            toLocalAt zone ts
    in
    tokenize pattern
        |> List.map (renderToken zone local ts)
        |> String.concat


type Token
    = TokLiteral String
    | TokYear String
    | TokWeekYear String
    | TokQuarter String
    | TokMonth String
    | TokWeek String
    | TokDay String
    | TokDayOfWeek String
    | TokPeriod String
    | TokHour Char String
    | TokMinute String
    | TokSecond String


tokenize : String -> List Token
tokenize str =
    tokenizeHelp (String.toList str)


tokenizeHelp : List Char -> List Token
tokenizeHelp chars =
    case chars of
        [] ->
            []

        '\'' :: '\'' :: rest ->
            TokLiteral "'" :: tokenizeHelp rest

        '\'' :: rest ->
            let
                ( lit, remaining ) =
                    readQuoted rest
            in
            TokLiteral lit :: tokenizeHelp remaining

        c :: rest ->
            if Char.isAlpha c then
                let
                    ( run, remaining ) =
                        spanSame c rest
                in
                classify c (String.fromList run) :: tokenizeHelp remaining

            else
                TokLiteral (String.fromChar c) :: tokenizeHelp rest


spanSame : Char -> List Char -> ( List Char, List Char )
spanSame c chars =
    let
        run =
            c :: takeWhile (\x -> x == c) chars
    in
    ( run, List.drop (List.length run - 1) chars )


readQuoted : List Char -> ( String, List Char )
readQuoted chars =
    case chars of
        [] ->
            ( "", [] )

        '\'' :: '\'' :: rest ->
            let
                ( lit, remaining ) =
                    readQuoted rest
            in
            ( "'" ++ lit, remaining )

        '\'' :: rest ->
            ( "", rest )

        ch :: rest ->
            let
                ( lit, remaining ) =
                    readQuoted rest
            in
            ( String.fromChar ch ++ lit, remaining )


takeWhile : (a -> Bool) -> List a -> List a
takeWhile pred list =
    case list of
        [] ->
            []

        x :: xs ->
            if pred x then
                x :: takeWhile pred xs

            else
                []


classify : Char -> String -> Token
classify c run =
    case c of
        'y' ->
            TokYear run

        'Y' ->
            TokWeekYear run

        'Q' ->
            TokQuarter run

        'q' ->
            TokQuarter run

        'M' ->
            TokMonth run

        'L' ->
            TokMonth run

        'w' ->
            TokWeek run

        'd' ->
            TokDay run

        'E' ->
            TokDayOfWeek run

        'e' ->
            TokDayOfWeek run

        'c' ->
            TokDayOfWeek run

        'a' ->
            TokPeriod run

        'h' ->
            TokHour c run

        'H' ->
            TokHour c run

        'K' ->
            TokHour c run

        'k' ->
            TokHour c run

        'm' ->
            TokMinute run

        's' ->
            TokSecond run

        _ ->
            TokLiteral run


renderToken : Time.Zone -> Local -> Int -> Token -> String
renderToken zone local ts tok =
    case tok of
        TokLiteral lit ->
            lit

        TokYear t ->
            renderYear local.year t

        TokWeekYear t ->
            renderWeekYear (weekYear 0 zone ts) t

        TokQuarter t ->
            renderQuarter (quarterOf zone ts) t

        TokMonth t ->
            renderMonth local.month t

        TokWeek t ->
            padTo (String.length t) (weekNumber 0 zone ts)

        TokDay t ->
            renderDay local.day t

        TokDayOfWeek t ->
            renderDayOfWeek (weekday (civilOfLocal local)) t

        TokPeriod t ->
            renderPeriod local.hours t

        TokHour c t ->
            renderHour c local.hours t

        TokMinute t ->
            padTo (String.length t) local.minutes

        TokSecond t ->
            padTo (String.length t) local.seconds


renderYear : Int -> String -> String
renderYear year t =
    if t == "yy" then
        padTo 2 (modBy 100 year)

    else
        padTo (String.length t) year


renderWeekYear : Int -> String -> String
renderWeekYear wy t =
    if t == "YY" then
        padTo 2 (modBy 100 wy)

    else
        padTo (String.length t) wy


renderQuarter : Int -> String -> String
renderQuarter q t =
    case t of
        "Q" ->
            String.fromInt q

        "q" ->
            String.fromInt q

        "QQ" ->
            padTo 2 q

        "qq" ->
            padTo 2 q

        "QQQQ" ->
            renderQuarterWide q

        "qqqq" ->
            renderQuarterWide q

        "QQQQQ" ->
            String.fromInt q

        "qqqqq" ->
            String.fromInt q

        _ ->
            "Q" ++ String.fromInt q


renderQuarterWide : Int -> String
renderQuarterWide q =
    indexOr "" [ "1st quarter", "2nd quarter", "3rd quarter", "4th quarter" ] (q - 1)


renderMonth : Int -> String -> String
renderMonth month t =
    case t of
        "M" ->
            String.fromInt month

        "MM" ->
            padTo 2 month

        "MMM" ->
            indexOr "" monthAbbrev (month - 1)

        "MMMM" ->
            indexOr "" monthWide (month - 1)

        "MMMMM" ->
            indexOr "" monthNarrow (month - 1)

        _ ->
            indexOr "" monthWide (month - 1)


renderDay : Int -> String -> String
renderDay day t =
    case t of
        "d" ->
            String.fromInt day

        _ ->
            padTo (String.length t) day


renderDayOfWeek : Int -> String -> String
renderDayOfWeek dow t =
    case String.length t of
        3 ->
            indexOr "" weekdayAbbrev dow

        4 ->
            indexOr "" weekdayWide dow

        5 ->
            indexOr "" weekdayNarrow dow

        6 ->
            indexOr "" weekdayShort dow

        _ ->
            let
                local =
                    modBy 7 (dow + 1)
            in
            padTo (String.length t)
                (if local == 0 then
                    7

                 else
                    local
                )


renderPeriod : Int -> String -> String
renderPeriod hours t =
    let
        pm =
            hours >= 12
    in
    case t of
        "a" ->
            if pm then
                "PM"

            else
                "AM"

        "aa" ->
            if pm then
                "PM"

            else
                "AM"

        "aaa" ->
            if pm then
                "pm"

            else
                "am"

        "aaaaa" ->
            if pm then
                "p"

            else
                "a"

        _ ->
            if pm then
                "p.m."

            else
                "a.m."


renderHour : Char -> Int -> String -> String
renderHour c hours t =
    case c of
        'h' ->
            let
                h =
                    modBy 12 hours
            in
            padTo (String.length t)
                (if h == 0 then
                    12

                 else
                    h
                )

        'K' ->
            padTo (String.length t) (modBy 12 hours)

        'k' ->
            padTo (String.length t)
                (if hours == 0 then
                    24

                 else
                    hours
                )

        _ ->
            padTo (String.length t) hours


padTo : Int -> Int -> String
padTo width n =
    let
        sign =
            if n < 0 then
                "-"

            else
                ""
    in
    sign ++ String.padLeft width '0' (String.fromInt (abs n))


indexOr : String -> List String -> Int -> String
indexOr fallback list i =
    List.drop i list |> List.head |> Maybe.withDefault fallback


monthAbbrev : List String
monthAbbrev =
    [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]


monthWide : List String
monthWide =
    [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ]


monthNarrow : List String
monthNarrow =
    [ "J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D" ]


weekdayAbbrev : List String
weekdayAbbrev =
    [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ]


weekdayWide : List String
weekdayWide =
    [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" ]


weekdayNarrow : List String
weekdayNarrow =
    [ "S", "M", "T", "W", "T", "F", "S" ]


weekdayShort : List String
weekdayShort =
    [ "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" ]



-- STRICT PARSE (date-fns parse subset + round-trip format equality)


{-| Parse `input` against `pattern` (in `zone`) and accept only when
re-formatting the result reproduces `input` byte for byte — upstream
`strictParse`. Missing fields come from the epoch reference (see the module
docs).
-}
strictParse : String -> String -> Time.Zone -> Maybe Int
strictParse input pattern zone =
    case matchAll (tokenize pattern) input [] of
        Nothing ->
            Nothing

        Just ( setters, rest ) ->
            if String.trim rest /= "" then
                Nothing

            else
                let
                    local =
                        applySetters (toLocalAt zone 0) setters

                    ts =
                        localToTs zone local
                in
                if format pattern zone ts == input then
                    Just ts

                else
                    Nothing


type Setter
    = SYear Int Bool
    | SWeekYear Int Bool
    | SQuarter Int
    | SMonth Int
    | SWeek Int
    | SDate Int
    | SWeekday Int
    | SAmPm Bool
    | SHour Char Int
    | SMinute Int
    | SSecond Int


matchAll : List Token -> String -> List Setter -> Maybe ( List Setter, String )
matchAll tokens remaining acc =
    case tokens of
        [] ->
            Just ( List.reverse acc, remaining )

        tok :: rest ->
            case matchToken tok remaining of
                Nothing ->
                    Nothing

                Just ( newSetters, remaining2 ) ->
                    matchAll rest remaining2 (List.reverse newSetters ++ acc)


matchToken : Token -> String -> Maybe ( List Setter, String )
matchToken tok str =
    case tok of
        TokLiteral lit ->
            if String.startsWith lit str then
                Just ( [], String.dropLeft (String.length lit) str )

            else
                Nothing

        TokYear t ->
            matchDigits (yearWidth t) str
                |> Maybe.map (\( v, rest ) -> ( [ SYear v (t == "yy") ], rest ))

        TokWeekYear t ->
            matchDigits (yearWidth t) str
                |> Maybe.map (\( v, rest ) -> ( [ SWeekYear v (t == "YY") ], rest ))

        TokQuarter t ->
            matchQuarter t str

        TokMonth t ->
            if numericMonthToken t then
                matchDigits 2 str
                    |> Maybe.map (\( v, rest ) -> ( [ SMonth v ], rest ))

            else
                matchNamed (monthNameLists t) (\i -> [ SMonth (i + 1) ]) str

        TokWeek t ->
            matchDigits (numWidth t) str
                |> Maybe.map (\( v, rest ) -> ( [ SWeek v ], rest ))

        TokDay t ->
            matchDigits (numWidth t) str
                |> Maybe.map (\( v, rest ) -> ( [ SDate v ], rest ))

        TokDayOfWeek t ->
            matchWeekday t str

        TokPeriod _ ->
            matchPeriod str

        TokHour c t ->
            matchDigits (numWidth t) str
                |> Maybe.map (\( v, rest ) -> ( [ SHour c v ], rest ))

        TokMinute t ->
            matchDigits (numWidth t) str
                |> Maybe.map (\( v, rest ) -> ( [ SMinute v ], rest ))

        TokSecond t ->
            matchDigits (numWidth t) str
                |> Maybe.map (\( v, rest ) -> ( [ SSecond v ], rest ))


yearWidth : String -> Int
yearWidth t =
    if t == "y" || t == "Y" then
        4

    else
        String.length t


numWidth : String -> Int
numWidth t =
    if String.length t == 1 then
        2

    else
        String.length t


numericMonthToken : String -> Bool
numericMonthToken t =
    t == "M" || t == "MM" || t == "L" || t == "LL"


monthNameLists : String -> List (List String)
monthNameLists t =
    case t of
        "MMM" ->
            [ monthAbbrev, monthNarrow ]

        "LLL" ->
            [ monthAbbrev, monthNarrow ]

        "MMMMM" ->
            [ monthNarrow ]

        "LLLLL" ->
            [ monthNarrow ]

        _ ->
            [ monthWide, monthAbbrev, monthNarrow ]


matchDigits : Int -> String -> Maybe ( Int, String )
matchDigits n str =
    let
        chars =
            String.toList str

        run =
            takeWhile Char.isDigit (List.take n chars)
    in
    if List.isEmpty run then
        Nothing

    else
        String.toInt (String.fromList run)
            |> Maybe.map (\v -> ( v, String.fromList (List.drop (List.length run) chars) ))


readWord : String -> Maybe ( String, String )
readWord str =
    let
        chars =
            String.toList str

        run =
            takeWhile Char.isAlpha chars
    in
    if List.isEmpty run then
        Nothing

    else
        Just ( String.fromList run, String.fromList (List.drop (List.length run) chars) )


matchNamed : List (List String) -> (Int -> List Setter) -> String -> Maybe ( List Setter, String )
matchNamed lists toSetters str =
    case readWord str of
        Nothing ->
            Nothing

        Just ( word, rest ) ->
            case firstMatch lists word of
                Just i ->
                    Just ( toSetters i, rest )

                Nothing ->
                    Nothing


firstMatch : List (List String) -> String -> Maybe Int
firstMatch lists word =
    case lists of
        [] ->
            Nothing

        names :: rest ->
            case findName names word of
                Just i ->
                    Just i

                Nothing ->
                    firstMatch rest word


findName : List String -> String -> Maybe Int
findName names word =
    if word == "" then
        Nothing

    else
        case List.filter (\( _, nm ) -> nm == word) (List.indexedMap Tuple.pair names) of
            ( i, _ ) :: _ ->
                Just i

            [] ->
                case List.filter (\( _, nm ) -> String.startsWith word nm) (List.indexedMap Tuple.pair names) of
                    [ ( i, _ ) ] ->
                        Just i

                    _ ->
                        Nothing


matchQuarter : String -> String -> Maybe ( List Setter, String )
matchQuarter t str =
    if t == "Q" || t == "q" || t == "QQ" || t == "qq" then
        matchDigits 2 str
            |> Maybe.map (\( v, rest ) -> ( [ SQuarter v ], rest ))

    else if t == "QQQ" || t == "qqq" then
        case String.uncons str of
            Just ( 'Q', rest ) ->
                matchDigits 1 rest
                    |> Maybe.map (\( v, rest2 ) -> ( [ SQuarter v ], rest2 ))

            _ ->
                Nothing

    else
        Nothing


matchWeekday : String -> String -> Maybe ( List Setter, String )
matchWeekday t str =
    case String.length t of
        3 ->
            matchNamed [ weekdayAbbrev ] (\i -> [ SWeekday i ]) str

        4 ->
            matchNamed [ weekdayWide ] (\i -> [ SWeekday i ]) str

        5 ->
            matchNamed [ weekdayNarrow ] (\i -> [ SWeekday i ]) str

        6 ->
            matchNamed [ weekdayShort ] (\i -> [ SWeekday i ]) str

        _ ->
            matchDigits 2 str
                |> Maybe.map (\( v, rest ) -> ( [ SWeekday (modBy 7 (v - 1)) ], rest ))


matchPeriod : String -> Maybe ( List Setter, String )
matchPeriod str =
    matchPeriodPrefixes
        [ ( "a.m.", False )
        , ( "p.m.", True )
        , ( "AM", False )
        , ( "PM", True )
        , ( "am", False )
        , ( "pm", True )
        , ( "a", False )
        , ( "p", True )
        ]
        str


matchPeriodPrefixes : List ( String, Bool ) -> String -> Maybe ( List Setter, String )
matchPeriodPrefixes prefixes str =
    case prefixes of
        [] ->
            Nothing

        ( prefix, isPm ) :: rest ->
            if String.startsWith prefix str then
                Just ( [ SAmPm isPm ], String.dropLeft (String.length prefix) str )

            else
                matchPeriodPrefixes rest str


applySetters : Local -> List Setter -> Local
applySetters ref setters =
    let
        s1 =
            List.foldl applyYear ref (List.filterMap pickYear setters)

        s2 =
            List.foldl applyWeekYear s1 (List.filterMap pickWeekYear setters)

        s3 =
            List.foldl applyQuarter s2 (List.filterMap pickQuarter setters)

        s4 =
            List.foldl applyMonth s3 (List.filterMap pickMonth setters)

        s5 =
            List.foldl applyWeek s4 (List.filterMap pickWeek setters)

        s6 =
            List.foldl applyDate s5 (List.filterMap pickDate setters)

        s7 =
            List.foldl applyWeekday s6 (List.filterMap pickWeekday setters)

        s8 =
            List.foldl applyAmPm s7 (List.filterMap pickAmPm setters)

        s9 =
            List.foldl applyHour s8 (List.filterMap pickHour setters)
    in
    List.foldl applyMinute s9 (List.filterMap pickMinute setters)
        |> (\s10 ->
                List.foldl applySecond s10 (List.filterMap pickSecond setters)
           )


pickYear : Setter -> Maybe ( Int, Bool )
pickYear s =
    case s of
        SYear y twoDigit ->
            Just ( y, twoDigit )

        _ ->
            Nothing


pickWeekYear : Setter -> Maybe ( Int, Bool )
pickWeekYear s =
    case s of
        SWeekYear y twoDigit ->
            Just ( y, twoDigit )

        _ ->
            Nothing


pickQuarter : Setter -> Maybe Int
pickQuarter s =
    case s of
        SQuarter q ->
            Just q

        _ ->
            Nothing


pickMonth : Setter -> Maybe Int
pickMonth s =
    case s of
        SMonth m ->
            Just m

        _ ->
            Nothing


pickWeek : Setter -> Maybe Int
pickWeek s =
    case s of
        SWeek w ->
            Just w

        _ ->
            Nothing


pickDate : Setter -> Maybe Int
pickDate s =
    case s of
        SDate d ->
            Just d

        _ ->
            Nothing


pickWeekday : Setter -> Maybe Int
pickWeekday s =
    case s of
        SWeekday d ->
            Just d

        _ ->
            Nothing


pickAmPm : Setter -> Maybe Bool
pickAmPm s =
    case s of
        SAmPm pm ->
            Just pm

        _ ->
            Nothing


pickHour : Setter -> Maybe ( Char, Int )
pickHour s =
    case s of
        SHour c v ->
            Just ( c, v )

        _ ->
            Nothing


pickMinute : Setter -> Maybe Int
pickMinute s =
    case s of
        SMinute m ->
            Just m

        _ ->
            Nothing


pickSecond : Setter -> Maybe Int
pickSecond s =
    case s of
        SSecond v ->
            Just v

        _ ->
            Nothing


{-| date-fns `YearParser.set` — resets to Jan 1, 00:00.
-}
applyYear : ( Int, Bool ) -> Local -> Local
applyYear ( value, twoDigit ) local =
    let
        year =
            if twoDigit then
                normalizeTwoDigitYear value local.year

            else
                value
    in
    { year = year, month = 1, day = 1, hours = 0, minutes = 0, seconds = 0, ms = 0 }


{-| date-fns `LocalWeekYearParser.set` — start of the week-year's first week.
-}
applyWeekYear : ( Int, Bool ) -> Local -> Local
applyWeekYear ( value, twoDigit ) local =
    let
        currentWy =
            weekYear 0 Time.utc (msOfLocal local)

        year =
            if twoDigit then
                normalizeTwoDigitYear value currentWy

            else
                value

        base =
            { year = year, month = 1, day = 1, hours = 0, minutes = 0, seconds = 0, ms = 0 }

        startDn =
            startOfWeekDay 0 (daysFromCivil (civilOfLocal base))
    in
    withCivil (civilFromDays startDn) base


{-| date-fns `QuarterParser.set`.
-}
applyQuarter : Int -> Local -> Local
applyQuarter q local =
    { local | month = (q - 1) * 3 + 1, day = 1, hours = 0, minutes = 0, seconds = 0, ms = 0 }


{-| date-fns `MonthParser.set`.
-}
applyMonth : Int -> Local -> Local
applyMonth m local =
    { local | month = m, day = 1, hours = 0, minutes = 0, seconds = 0, ms = 0 }


{-| date-fns `LocalWeekParser.set` — `startOfWeek(setWeek(date, value))`.
-}
applyWeek : Int -> Local -> Local
applyWeek w local =
    let
        dn =
            daysFromCivil (civilOfLocal local)

        currentWeek =
            weekNumber 0 Time.utc (msOfLocal local)

        diff =
            currentWeek - w

        startDn =
            startOfWeekDay 0 (dn - diff * 7)
    in
    withCivil (civilFromDays startDn) { local | hours = 0, minutes = 0, seconds = 0, ms = 0 }


{-| date-fns `DateParser.set`.
-}
applyDate : Int -> Local -> Local
applyDate d local =
    normalizeDay { local | day = d, hours = 0, minutes = 0, seconds = 0, ms = 0 }


{-| date-fns `DayParser.set` — the day of the current week (`weekStartsOn = 0`).
-}
applyWeekday : Int -> Local -> Local
applyWeekday dow local =
    let
        dn =
            daysFromCivil (civilOfLocal local)

        target =
            startOfWeekDay 0 dn + dow
    in
    withCivil (civilFromDays target) local


{-| date-fns `AMPMParser.set`.
-}
applyAmPm : Bool -> Local -> Local
applyAmPm isPm local =
    { local
        | hours =
            if isPm then
                12

            else
                0
        , minutes = 0
        , seconds = 0
        , ms = 0
    }


{-| date-fns hour parsers, dispatched by token letter.
-}
applyHour : ( Char, Int ) -> Local -> Local
applyHour ( c, value ) local =
    case c of
        'h' ->
            applyMeridiem12 value local

        'K' ->
            if local.hours >= 12 && value < 12 then
                { local | hours = value + 12, minutes = 0, seconds = 0, ms = 0 }

            else
                { local | hours = value, minutes = 0, seconds = 0, ms = 0 }

        'k' ->
            let
                h =
                    if value == 24 then
                        0

                    else
                        value
            in
            if local.hours >= 12 && h < 12 then
                { local | hours = h + 12, minutes = 0, seconds = 0, ms = 0 }

            else
                { local | hours = h, minutes = 0, seconds = 0, ms = 0 }

        _ ->
            { local | hours = value, minutes = 0, seconds = 0, ms = 0 }


applyMeridiem12 : Int -> Local -> Local
applyMeridiem12 value local =
    if local.hours >= 12 && value < 12 then
        { local | hours = value + 12, minutes = 0, seconds = 0, ms = 0 }

    else if local.hours < 12 && value == 12 then
        { local | hours = 0, minutes = 0, seconds = 0, ms = 0 }

    else
        { local | hours = value, minutes = 0, seconds = 0, ms = 0 }


applyMinute : Int -> Local -> Local
applyMinute m local =
    { local | minutes = m }


applySecond : Int -> Local -> Local
applySecond s local =
    { local | seconds = s }


{-| date-fns `normalizeTwoDigitYear`.
-}
normalizeTwoDigitYear : Int -> Int -> Int
normalizeTwoDigitYear twoDigitYear currentYear =
    let
        isCommonEra =
            currentYear > 0

        absCurrentYear =
            if isCommonEra then
                currentYear

            else
                1 - currentYear
    in
    if absCurrentYear <= 50 then
        if twoDigitYear == 0 then
            100

        else
            twoDigitYear

    else
        let
            rangeEnd =
                absCurrentYear + 50

            rangeEndCentury =
                rangeEnd // 100 * 100

            isPreviousCentury =
                modBy 100 rangeEnd <= twoDigitYear

            result =
                twoDigitYear
                    + rangeEndCentury
                    - (if isPreviousCentury then
                        100

                       else
                        0
                      )
        in
        if isCommonEra then
            result

        else
            1 - result
