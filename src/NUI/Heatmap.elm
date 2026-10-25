module NUI.Heatmap exposing (ColorTheme(..), DayRect, HeatmapDataItem, MonthLabel, Options, Size(..), calcColorByValue, completeDataGaps, createDayRect, createLoadingMatrix, createSparseMatrix, cssVarsFor, dataMonthLabels, defaults, loadingMonthLabels, view)

{-| Naive UI's `Heatmap`, rebuilt on elm-ui: a GitHub-style contribution
calendar. Real `<table>` markup with week labels down the side, month labels
across the top, one rect per day coloured by `value / maxValue`, and a footer
with the less/more colour indicator.

    import NUI.Heatmap exposing (defaults)

    NUI.Heatmap.view theme
        { defaults
            | data =
                [ { timestamp = Time.millisToPosix 1735689600000, value = Just 3 }
                , { timestamp = Time.millisToPosix 1736121600000, value = Just 7 }
                ]
            , zone = Time.utc
            , now = Time.millisToPosix 1735689600000
        }
        []

**The caller-owned contract.** Upstream reads the wall clock (`new Date()`)
in three places; this library is pure, so the caller owns time:

  - `zone` — every date computation (week alignment, gap filling, month
    grouping) is local-timezone; pass the same zone you render with.
  - `now` — only feeds `createLoadingMatrix`'s dead timestamps; it never
    reaches the DOM.

**Locale** replaces upstream's `useLocale('Heatmap')` + date-fns locale:
`weekdayLabels` (7 strings, 0 = Sunday … 6 = Saturday, rotated by the week
start; rows 1/3/5 visible), `monthLabels` (12 strings, 1–12), and
`indicatorLessText` / `indicatorMoreText` (upstream enUS: `"less"` /
`"more"`). `firstDayOfWeek` keeps Naive UI's own convention (0 = Monday …
6 = Sunday, like `NUI.Calendar`); the date-fns shift is applied internally.

**Pure core.** The upstream `src/heatmap/src/utils` functions are exposed
for reuse and testing: `calcColorByValue`, `completeDataGaps`,
`createDayRect`, `createSparseMatrix`, `createLoadingMatrix`, plus
`dataMonthLabels` / `loadingMonthLabels`. `view` uses exactly these.

**Slots.** `footer` (rendered inside the inner `.n-heatmap__footer` wrapper,
only when present) and `indicator` (replaces the whole colour indicator
block; the default renders only when `showColorIndicator` is set).

(The divergence enumeration — tooltip, undefined-vs-null, keying, quirks —
lives in the plain comment right below: internal port notes, deliberately
kept out of the published docs.)

@docs ColorTheme, DayRect, HeatmapDataItem, MonthLabel, Options, Size, calcColorByValue, completeDataGaps, createDayRect, createLoadingMatrix, createSparseMatrix, cssVarsFor, dataMonthLabels, defaults, loadingMonthLabels, view

-}

{- INTERNAL PORT NOTES — moved out of the module doc (plain comments do not
      enter docs.json; the published docs must stay under the package-size
      limit). Nothing here changes the public contract summarised above.

   **Divergences from upstream** (everything else is a faithful port):

     - **Tooltip is not ported.** Upstream wraps each rect in `n-tooltip` when
       the `tooltip` prop is set; tooltips are outside this library's contract,
       so the caller owns hover UX. Rects render exactly upstream's trigger
       `div.n-heatmap-rect` (with the inline `--n-rect-color`).
     - **`undefined` vs `null` values collapse.** Upstream's
       `value?: number | null` lets `{ value: undefined }` (which renders a rect
       in the _minimum_ colour — `calcColorByValue` treats it like `≤ 0`, but the
       render checks `!== null`) differ from `{ value: null }` (which renders
       `.n-heatmap__empty-cell`). Elm's `Maybe Float` has one `Nothing`, so
       missing values always render the empty cell — one rect _emptier_ than
       upstream for `undefined`-valued data.
     - **The empty-data guard moved inside `completeDataGaps`.** Upstream's util
       crashes on `[]` (`sortedData[0]` of nothing) and `Heatmap.tsx` guards at
       the call site; here the util returns `[]` itself.
     - **Day keys are civil-day numbers, not epoch-millis.** Upstream keys its
       data map by `startOfDay(ts).getTime()`; this port keys by the calendar
       day index in `zone`. The two agree unless the zone's UTC offset changes
       mid-range (a DST-style zone), which `Time.customZone` cannot express and
       no caller supplies — and under such a change the civil-day keys behave
       more sensibly than epoch-millis. Review-confirmed unreachable divergence.
     - **The loading animation is static.** Upstream mounts a runtime stylesheet
       with a color-hashed class (`heatmap-loading-<hash>`) plus keyframes; the
       port ships the same animation verbatim on the existing `--loading`
       modifier (`tools/bridge.css`), so no hashed class is emitted.
     - **`xGap` / `yGap` are visually swapped** — upstream's
       `border-spacing: var(--n-y-gap) var(--n-x-gap)` swaps the axes relative to
       the prop names. Kept verbatim (do not "fix").
     - Quirks kept on purpose: month labels spanning fewer than 3 columns are
       dropped (`weekCount >= 3`); duplicate timestamps are last-wins (JS `Map`
       construction over the sorted data); `value <= 0`, `null`, or
       `maxValue == 0` all paint `colors[0]`; bucketing is `ceil`, not `floor`;
       the loading matrix is a dead 7×53 grid (`timestamp = now`, `value = 0`,
       `color = '#000000'`); `maxValue` always comes from `data`, even while the
       matrix shows `loadingData` (so a loading matrix without `data` paints
       every rect `colors[0]`); and `loadingData = Just []` counts as _present_
       (a JS `[]` is truthy), which yields the loading matrix but **data**-derived
       month labels, while `Nothing` yields the 12 fixed loading labels.

-}

import Dict exposing (Dict)
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Internal.DateTime as DT
import NUI.Theme exposing (Theme)
import NUI.Theme.Heatmap as HeatmapTheme
import Time


{-| One data point — upstream's `HeatmapDataItem`. `timestamp` is any instant
inside the day (upstream a millisecond number); only its calendar day in the
caller's `zone` matters. `value = Nothing` is upstream's `null`.
-}
type alias HeatmapDataItem =
    { timestamp : Time.Posix
    , value : Maybe Float
    }


{-| A positioned, coloured day — upstream's `DayRect`. `dayOfWeek` uses
date-fns numbering (0 = Sunday … 6 = Saturday); `rowIndex` is relative to the
week start, `colIndex` the calendar-week column.
-}
type alias DayRect =
    { timestamp : Time.Posix
    , value : Maybe Float
    , color : String
    , dayOfWeek : Int
    , rowIndex : Int
    , colIndex : Int
    }


{-| A rendered month label — upstream's `{ name, colSpan }`; `month` is 1–12
(the name comes from the caller's `monthLabels` list).
-}
type alias MonthLabel =
    { month : Int
    , colSpan : Int
    }


{-| Naive UI's heatmap `size` — only `small | medium | large` exist.
-}
type Size
    = Small
    | Medium
    | Large


{-| Upstream's `colorTheme` presets (`heatmapColorThemes`).
-}
type ColorTheme
    = Green
    | Blue
    | Orange
    | Purple
    | Red


{-| The heatmap options — Naive UI's props plus the caller-owned runtime
inputs: the `data` / `loadingData` item lists, the collapse of upstream's
`cursor`-style props into `fillCalendarLeading`, `firstDayOfWeek` (Naive UI
numbering), `loading`, the colour overrides (`minimumColor` /
`activeColors` / `colorTheme`), the label/indicator toggles
(`showColorIndicator` / `showWeekLabels` / `showMonthLabels`), `size`, the
`xGap` / `yGap` overrides, `rtl`, the time inputs (`zone` / `now`), the
locale strings (`indicatorLessText` / `indicatorMoreText` /
`weekdayLabels` / `monthLabels`), the `footer` / `indicator` slots, and
`attributes`.
-}
type alias Options msg =
    { data : List HeatmapDataItem
    , loadingData : Maybe (List HeatmapDataItem)
    , fillCalendarLeading : Bool
    , firstDayOfWeek : Int
    , loading : Bool
    , minimumColor : Maybe String
    , activeColors : Maybe (List String)
    , colorTheme : Maybe ColorTheme
    , showColorIndicator : Bool
    , showWeekLabels : Bool
    , showMonthLabels : Bool
    , size : Size
    , xGap : Maybe Float
    , yGap : Maybe Float
    , rtl : Bool
    , zone : Time.Zone
    , now : Time.Posix
    , indicatorLessText : String
    , indicatorMoreText : String
    , weekdayLabels : List String
    , monthLabels : List String
    , footer : Maybe (Element msg)
    , indicator : Maybe (Element msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults: no data (hence no loading matrix), no leading fill,
weeks starting Monday, not loading, the theme colours, indicator and both
label rows shown, `medium` size, no gaps, LTR, UTC at epoch, the enUS
"less"/"more" + `"Sun"…"Sat"`/`"Jan"…"Dec"` labels, no slots, no extra
attributes.
-}
defaults : Options msg
defaults =
    { data = []
    , loadingData = Nothing
    , fillCalendarLeading = False
    , firstDayOfWeek = 0
    , loading = False
    , minimumColor = Nothing
    , activeColors = Nothing
    , colorTheme = Nothing
    , showColorIndicator = True
    , showWeekLabels = True
    , showMonthLabels = True
    , size = Medium
    , xGap = Nothing
    , yGap = Nothing
    , rtl = False
    , zone = Time.utc
    , now = Time.millisToPosix 0
    , indicatorLessText = "less"
    , indicatorMoreText = "more"
    , weekdayLabels = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ]
    , monthLabels =
        [ "Jan"
        , "Feb"
        , "Mar"
        , "Apr"
        , "May"
        , "Jun"
        , "Jul"
        , "Aug"
        , "Sep"
        , "Oct"
        , "Nov"
        , "Dec"
        ]
    , footer = Nothing
    , indicator = Nothing
    , attributes = []
    }


{-| The `n-heatmap` element — the `__content` calendar table (month labels
row, 7 day rows, one `.n-heatmap-rect` per valued day, `__empty-cell`
otherwise) plus the `__footer` (optional `footer` slot, colour indicator when
`showColorIndicator`). The `children` list is unused (upstream has no default
slot).
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts _ =
    let
        ws =
            weekStartOn opts.firstDayOfWeek

        normalizedData =
            completeDataGaps opts.zone opts.data ws opts.fillCalendarLeading

        normalizedLoading =
            case opts.loadingData of
                Just loadingItems ->
                    completeDataGaps opts.zone loadingItems ws opts.fillCalendarLeading

                Nothing ->
                    []

        matrix =
            heatmapMatrix theme opts ws normalizedData normalizedLoading

        labels =
            if opts.loading && opts.loadingData == Nothing then
                loadingMonthLabels

            else
                dataMonthLabels opts.zone matrix
    in
    Element.column
        ([ I.classes ([ "n-heatmap" ] ++ I.classIf opts.rtl "n-heatmap--rtl")
         , I.cssVars (cssVarsFor theme opts)
         ]
            ++ opts.attributes
        )
        [ Element.el
            [ I.classes [ "n-heatmap__content" ] ]
            (Element.html (calendarTable opts ws labels matrix))
        , footerEl theme opts
        ]



-- MATRIX (upstream: heatmapMatrixRef)


{-| Upstream's `heatmapMatrixRef` — the loading matrix when loading without
normalized loading data, else `createSparseMatrix` over `createDayRect`s of
the final data (loading data while loading, `data` otherwise). `Nothing` in a
row marks a hole in upstream's sparse array (rendered as no `<td>` at all);
gap-filled data always produces a dense matrix.
-}
heatmapMatrix :
    Theme
    -> Options msg
    -> Int
    -> List HeatmapDataItem
    -> List HeatmapDataItem
    -> List (List (Maybe DayRect))
heatmapMatrix theme opts ws normalizedData normalizedLoading =
    if opts.loading && List.isEmpty normalizedLoading then
        List.map (List.map Just) (createLoadingMatrix opts.now ws)

    else
        let
            finalData =
                if opts.loading then
                    normalizedLoading

                else
                    normalizedData
        in
        if List.isEmpty finalData then
            []

        else
            let
                calendarStart =
                    List.head finalData
                        |> Maybe.map .timestamp
                        |> Maybe.withDefault (Time.millisToPosix 0)

                maxV =
                    maxDataValue normalizedData

                colors =
                    mergedColors theme opts

                dayRects =
                    List.map
                        (\item -> createDayRect opts.zone item calendarStart ws colors maxV)
                        finalData
            in
            createSparseMatrix 7 dayRects .rowIndex .colIndex


{-| Upstream's `maxValueRef` — always over the normalized **`data`**, never the
loading data (`maxBy` over non-null values, `0` when there are none).
-}
maxDataValue : List HeatmapDataItem -> Float
maxDataValue items =
    List.filterMap .value items
        |> List.maximum
        |> Maybe.withDefault 0


{-| Upstream's `mergedColorsRef` — the minimum colour followed by the active
colours; an explicit `activeColors` (even `Just []`, truthy upstream) beats the
`colorTheme` palette, which beats the theme's `activeColors`. A `Just ""`
minimum colour falls back to the theme's, matching upstream's `||`.
-}
mergedColors : Theme -> Options msg -> List String
mergedColors theme opts =
    let
        v =
            HeatmapTheme.vars theme

        minimumColor =
            case opts.minimumColor of
                Just color ->
                    if color == "" then
                        v.mininumColor

                    else
                        color

                Nothing ->
                    v.mininumColor

        activeColors =
            case opts.activeColors of
                Just colors ->
                    colors

                Nothing ->
                    case opts.colorTheme of
                        Just colorTheme ->
                            palettes colorTheme

                        Nothing ->
                            v.activeColors
    in
    minimumColor :: activeColors


{-| Upstream's `heatmapColorThemes` (`src/heatmap/src/theme.ts`).
-}
palettes : ColorTheme -> List String
palettes colorTheme =
    case colorTheme of
        Green ->
            [ "#c6e48b", "#7bc96f", "#239a3b", "#196127" ]

        Blue ->
            [ "#c0e7ff", "#73b3ff", "#0969da", "#0550ae" ]

        Orange ->
            [ "#fed7aa", "#fb923c", "#ea580c", "#c2410c" ]

        Purple ->
            [ "#e9d5ff", "#c084fc", "#9333ea", "#7c3aed" ]

        Red ->
            [ "#fecaca", "#f87171", "#dc2626", "#b91c1c" ]



-- CSS VARS (upstream: cssVarsRef, Heatmap.tsx:100-148)


{-| The raw `--n-*` custom properties a heatmap with these options attaches.
`view` uses exactly this list. `xGap` / `yGap` win over the size defaults when
set (a pixel count, matching `pxfy`); the size-dependent `--n-*` values follow
`createKey('<var>', size)` — including `--n-border-radius`, which reads the
per-size `borderRadiusSmall/Medium/Large`, not the bare `borderRadius`.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            HeatmapTheme.vars theme

        s =
            sizeVars v opts.size
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", s.fontSize )
    , ( "--n-font-weight", v.fontWeight )
    , ( "--n-text-color", v.textColor )
    , ( "--n-border-radius", s.borderRadius )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-loading-color-start", v.loadingColorStart )
    , ( "--n-loading-color-end", v.loadingColorEnd )
    , ( "--n-rect-size", s.rectSize )
    , ( "--n-x-gap", gapValue opts.xGap s.xGap )
    , ( "--n-y-gap", gapValue opts.yGap s.yGap )
    ]


type alias SizeVars =
    { fontSize : String
    , rectSize : String
    , borderRadius : String
    , xGap : String
    , yGap : String
    }


sizeVars : HeatmapTheme.Vars -> Size -> SizeVars
sizeVars v size =
    case size of
        Small ->
            { fontSize = v.fontSizeSmall
            , rectSize = v.rectSizeSmall
            , borderRadius = v.borderRadiusSmall
            , xGap = v.xGapSmall
            , yGap = v.yGapSmall
            }

        Medium ->
            { fontSize = v.fontSizeMedium
            , rectSize = v.rectSizeMedium
            , borderRadius = v.borderRadiusMedium
            , xGap = v.xGapMedium
            , yGap = v.yGapMedium
            }

        Large ->
            { fontSize = v.fontSizeLarge
            , rectSize = v.rectSizeLarge
            , borderRadius = v.borderRadiusLarge
            , xGap = v.xGapLarge
            , yGap = v.yGapLarge
            }


{-| Upstream's `pxfy` on an explicit gap, else the size default.
-}
gapValue : Maybe Float -> String -> String
gapValue maybeGap default =
    case maybeGap of
        Just gap ->
            String.fromFloat gap ++ "px"

        Nothing ->
            default



-- PURE CORE (upstream: src/heatmap/src/utils/index.ts — weekStartsOn is
-- date-fns numbering, 0 = Sunday … 6 = Saturday)


{-| Upstream's `calcColorByValue` — `maxValue == 0`, a `Nothing`/`≤ 0` value,
or an empty palette all yield `colors[0]`; otherwise
`colors[min(ceil(min(value / maxValue, 1) * (len - 1)), len - 1)]` — ceil
bucketing, clamped at both ends. (Upstream reads `colors[0]` of an empty list
as `undefined`; here it is `""` — unreachable through `view`, which always
prepends a minimum colour.)
-}
calcColorByValue : List String -> Maybe Float -> Float -> String
calcColorByValue colors value maxValue =
    if maxValue == 0 || value == Nothing || Maybe.withDefault 0 value <= 0 then
        colorAt colors 0

    else
        let
            number =
                Maybe.withDefault 0 value

            ratio =
                min (number / maxValue) 1

            maxLevel =
                List.length colors - 1

            level =
                min (ceiling (ratio * toFloat maxLevel)) maxLevel
        in
        colorAt colors level


colorAt : List String -> Int -> String
colorAt colors index =
    List.drop index colors
        |> List.head
        |> Maybe.withDefault ""


{-| Upstream's `completeDataGaps`, with the empty-list guard moved inside
(upstream crashes; `Heatmap.tsx` guards at the call site).

`completeDataGaps zone data weekStartsOn fillCalendarLeading` sorts `data` by
timestamp, then returns one item per calendar day from the start of the first
item's week to the end of the last item's week: original items win on their
day (duplicates last-wins), days within `[firstDate, lastDate]` (or from the
week start, with `fillCalendarLeading`) are filled with `Just 0`, and the
remaining padding days with `Nothing`. Gap-day timestamps are local midnights.

Only the calendar day of each timestamp in `zone` matters (upstream compares
`startOfDay` keys), except upstream's exact-instant `isWithinInterval` bounds
— and the one edge those could distinguish (the first/last data day itself) is
always covered by the data map, so day-granularity comparison is equivalent.

-}
completeDataGaps : Time.Zone -> List HeatmapDataItem -> Int -> Bool -> List HeatmapDataItem
completeDataGaps zone data weekStartsOn fillCalendarLeading =
    if List.isEmpty data then
        []

    else
        let
            sorted =
                List.sortBy (Time.posixToMillis << .timestamp) data

            days =
                List.map (dayNumber zone << .timestamp) sorted

            firstDay =
                List.head days
                    |> Maybe.withDefault 0

            lastDay =
                List.reverse days
                    |> List.head
                    |> Maybe.withDefault firstDay

            firstCalendarDay =
                firstDay - ((weekdayOfDay firstDay - weekStartsOn + 7) |> modBy 7)

            lastCalendarDay =
                lastDay + (6 - ((weekdayOfDay lastDay - weekStartsOn + 7) |> modBy 7))

            dataMap =
                List.foldl
                    (\item dict -> Dict.insert (dayNumber zone item.timestamp) item dict)
                    Dict.empty
                    sorted

            startDay =
                if fillCalendarLeading then
                    firstCalendarDay

                else
                    firstDay
        in
        List.range firstCalendarDay lastCalendarDay
            |> List.map (gapDay zone dataMap startDay lastDay)


gapDay : Time.Zone -> Dict Int HeatmapDataItem -> Int -> Int -> Int -> HeatmapDataItem
gapDay zone dataMap startDay lastDay day =
    case Dict.get day dataMap of
        Just item ->
            item

        Nothing ->
            { timestamp = posixOfDay zone day
            , value =
                if day >= startDay && day <= lastDay then
                    Just 0

                else
                    Nothing
            }


{-| Upstream's `createDayRect` — positions one item in the grid:
`colIndex = differenceInCalendarDays(item, calendarStartDate) // 7`,
`rowIndex = (getDay(item) - weekStartOn + 7) % 7`, colour via
`calcColorByValue`.
-}
createDayRect :
    Time.Zone
    -> HeatmapDataItem
    -> Time.Posix
    -> Int
    -> List String
    -> Float
    -> DayRect
createDayRect zone item calendarStartDate weekStartsOn colors maxValue =
    let
        day =
            dayNumber zone item.timestamp

        daysFromGridStart =
            day - dayNumber zone calendarStartDate

        dayOfWeek =
            weekdayOfDay day
    in
    { timestamp = item.timestamp
    , value = item.value
    , color = calcColorByValue colors item.value maxValue
    , dayOfWeek = dayOfWeek
    , rowIndex = (dayOfWeek - weekStartsOn + 7) |> modBy 7
    , colIndex = daysFromGridStart // 7
    }


{-| Upstream's `createSparseMatrix` — `rows` rows, each item placed at its
column index. Duplicate positions are last-wins (JS `row[col] = item`
iteration order); holes and short rows become `Nothing`, and a row's length is
its highest occupied column + 1 — exactly upstream's sparse arrays, whose
`.map` renders no `<td>` for holes.
-}
createSparseMatrix : Int -> List item -> (item -> Int) -> (item -> Int) -> List (List (Maybe item))
createSparseMatrix rows items getRowIndex getColIndex =
    let
        grouped =
            List.foldl
                (\item dict ->
                    Dict.update (getRowIndex item)
                        (\current -> Just (item :: Maybe.withDefault [] current))
                        dict
                )
                Dict.empty
                items
    in
    List.range 0 (rows - 1)
        |> List.map
            (\rowIndex ->
                let
                    rowItems =
                        Dict.get rowIndex grouped
                            |> Maybe.withDefault []
                            |> List.reverse

                    placed =
                        List.foldl
                            (\item dict -> Dict.insert (getColIndex item) item dict)
                            Dict.empty
                            rowItems
                in
                case List.maximum (Dict.keys placed) of
                    Just maxCol ->
                        List.range 0 maxCol
                            |> List.map (\col -> Dict.get col placed)

                    Nothing ->
                        []
            )


{-| Upstream's `createLoadingMatrix` — a dead 7×53 grid: every timestamp is
`now` (upstream `Date.now()`; the value never reaches the DOM), every value is
`Just 0`, every colour `#000000`.
-}
createLoadingMatrix : Time.Posix -> Int -> List (List DayRect)
createLoadingMatrix now weekStartsOn =
    List.range 0 6
        |> List.map
            (\row ->
                List.range 0 52
                    |> List.map
                        (\col ->
                            { timestamp = now
                            , value = Just 0
                            , color = "#000000"
                            , dayOfWeek = (weekStartsOn + row) |> modBy 7
                            , rowIndex = row
                            , colIndex = col
                            }
                        )
            )


{-| Upstream's `dataMonthLabelsRef` — for each column, the month of its first
non-null cell scanning down the rows; columns grouped by month, groups
spanning fewer than 3 columns dropped, one `{ month, colSpan }` per surviving
group in chronological order (`Dict` key order equals upstream's `'yyyy-MM'`
string sort for real dates).

Holes and short rows are skipped (`Nothing`); they cannot occur from
gap-filled data, and upstream would crash formatting `undefined` anyway.

-}
dataMonthLabels : Time.Zone -> List (List (Maybe DayRect)) -> List MonthLabel
dataMonthLabels zone matrix =
    case matrix of
        [] ->
            []

        firstRow :: _ ->
            if List.isEmpty firstRow then
                []

            else
                let
                    colMonths =
                        List.filterMap
                            (colMonth zone matrix)
                            (List.range 0 (List.length firstRow - 1))

                    stats =
                        List.foldl stepMonth Dict.empty colMonths
                in
                Dict.toList stats
                    |> List.filter (\( _, s ) -> s.count >= 3)
                    |> List.map (\( ( _, month ), s ) -> { month = month, colSpan = s.end - s.start + 1 })


type alias MonthStats =
    { count : Int
    , start : Int
    , end : Int
    }


stepMonth : ( ( Int, Int ), Int ) -> Dict ( Int, Int ) MonthStats -> Dict ( Int, Int ) MonthStats
stepMonth ( key, col ) dict =
    Dict.update key
        (\current ->
            let
                s =
                    Maybe.withDefault { count = 0, start = col, end = col } current
            in
            Just { s | count = s.count + 1, start = min s.start col, end = max s.end col }
        )
        dict


colMonth : Time.Zone -> List (List (Maybe DayRect)) -> Int -> Maybe ( ( Int, Int ), Int )
colMonth zone matrix col =
    case matrix of
        [] ->
            Nothing

        row :: rest ->
            case List.drop col row |> List.head of
                Just (Just cell) ->
                    if cell.value /= Nothing then
                        Just ( civilKey zone cell.timestamp, col )

                    else
                        colMonth zone rest col

                _ ->
                    colMonth zone rest col


civilKey : Time.Zone -> Time.Posix -> ( Int, Int )
civilKey zone ts =
    let
        c =
            toCivil zone ts
    in
    ( c.year, c.month )


{-| Upstream's `loadingMonthLabelsRef` — all 12 months (the name only depends
on the month; upstream's `new Date(currentYear, i, 1)` contributes nothing
else), with fixed colSpans chosen for consistent label widths; they sum to 53,
the loading matrix width.
-}
loadingMonthLabels : List MonthLabel
loadingMonthLabels =
    List.map2
        (\month colSpan -> { month = month, colSpan = colSpan })
        (List.range 1 12)
        [ 5, 4, 5, 4, 5, 4, 5, 4, 4, 5, 4, 4 ]



-- TABLE (upstream render(): a real <table>)


calendarTable : Options msg -> Int -> List MonthLabel -> List (List (Maybe DayRect)) -> Html msg
calendarTable opts ws labels matrix =
    Html.table
        [ HA.class "n-heatmap__calendar-table" ]
        (monthHeader opts labels
            ++ [ Html.tbody [] (List.map (bodyRow opts ws matrix) (List.range 0 6)) ]
        )


{-| The `<thead>` — rendered whenever `showMonthLabels` is set, even when no
label survives the `>= 3` filter (upstream renders the empty `<tr>` too).
-}
monthHeader : Options msg -> List MonthLabel -> List (Html msg)
monthHeader opts labels =
    if not opts.showMonthLabels then
        []

    else
        [ Html.thead []
            [ Html.tr []
                (weekHeaderCell opts ++ List.map (monthCell opts) labels)
            ]
        ]


weekHeaderCell : Options msg -> List (Html msg)
weekHeaderCell opts =
    if opts.showWeekLabels then
        [ Html.th [ HA.class "n-heatmap__week-header-cell" ] [] ]

    else
        []


monthCell : Options msg -> MonthLabel -> Html msg
monthCell opts label =
    Html.th
        [ HA.class "n-heatmap__month-label-cell"
        , HA.colspan label.colSpan
        ]
        [ Html.text (monthName opts.monthLabels label.month) ]


{-| One of the 7 `<tr>`s — the week label cell (odd rows carry text, even rows
stay empty, upstream's `visible`), then one cell per matrix entry. `Nothing`
holes render no `<td>` at all, exactly like upstream's sparse-`.map`.
-}
bodyRow : Options msg -> Int -> List (List (Maybe DayRect)) -> Int -> Html msg
bodyRow opts ws matrix rowIdx =
    let
        rowCells =
            List.drop rowIdx matrix
                |> List.head
                |> Maybe.withDefault []

        weekCell =
            if opts.showWeekLabels then
                [ weekLabelCell opts ws rowIdx ]

            else
                []
    in
    Html.tr [] (weekCell ++ List.filterMap (dayCell opts.loading) rowCells)


weekLabelCell : Options msg -> Int -> Int -> Html msg
weekLabelCell opts ws rowIdx =
    Html.td
        [ HA.class "n-heatmap__week-label-cell" ]
        (if modBy 2 rowIdx /= 0 then
            [ Html.text (weekdayLabel opts.weekdayLabels ws rowIdx) ]

         else
            []
        )


dayCell : Bool -> Maybe DayRect -> Maybe (Html msg)
dayCell loading cell =
    case cell of
        Nothing ->
            Nothing

        Just rect ->
            if rect.value /= Nothing then
                Just
                    (Html.td
                        [ HA.class "n-heatmap__day-cell" ]
                        [ rectDiv loading rect ]
                    )

            else
                Just
                    (Html.td
                        [ HA.class "n-heatmap__day-cell" ]
                        [ Html.div [ HA.class "n-heatmap__empty-cell" ] [] ]
                    )


{-| Upstream's `Rect` trigger node: `div.n-heatmap-rect[--loading]` with the
inline `--n-rect-color`. The tooltip wrapper is not ported (caller owns hover
UX), and the loading animation comes from the bridge's static keyframes on
`--loading` instead of upstream's color-hashed runtime class.
-}
rectDiv : Bool -> DayRect -> Html msg
rectDiv loading rect =
    Html.div
        [ HA.class (rectClass loading)
        , HA.attribute "style" ("--n-rect-color:" ++ rect.color)
        ]
        []


rectClass : Bool -> String
rectClass loading =
    String.join " " ([ "n-heatmap-rect" ] ++ I.classIf loading "n-heatmap-rect--loading")



-- FOOTER (upstream render(): outer __footer, optional inner __footer slot
-- wrapper, __indicator with the default ColorIndicator)


footerEl : Theme -> Options msg -> Element msg
footerEl theme opts =
    Element.row
        [ I.classes [ "n-heatmap__footer" ] ]
        (footerInner opts ++ [ indicatorEl theme opts ])


{-| Upstream's `resolveWrappedSlot($slots.footer, …)` — nothing when absent,
the inner `div.n-heatmap__footer` wrapper when present.
-}
footerInner : Options msg -> List (Element msg)
footerInner opts =
    case opts.footer of
        Just footerSlot ->
            [ Element.el [ I.classes [ "n-heatmap__footer" ] ] footerSlot ]

        Nothing ->
            []


indicatorEl : Theme -> Options msg -> Element msg
indicatorEl theme opts =
    Element.row
        [ I.classes [ "n-heatmap__indicator" ] ]
        (case opts.indicator of
            Just indicatorSlot ->
                [ indicatorSlot ]

            Nothing ->
                if opts.showColorIndicator then
                    [ Element.html (colorIndicator theme opts) ]

                else
                    []
        )


{-| Upstream's `HeatmapColorIndicator`: a `span.__label`, the `.__cells` row
(one `.__cell` per merged colour, inline `backgroundColor`), and the trailing
`span.__label`. Rendered as raw HTML for exact tag parity (the flex context
makes `div`/`span` interchangeable otherwise).
-}
colorIndicator : Theme -> Options msg -> Html msg
colorIndicator theme opts =
    Html.div
        [ HA.class "n-heatmap-color-indicator" ]
        [ Html.span
            [ HA.class "n-heatmap-color-indicator__label" ]
            [ Html.text opts.indicatorLessText ]
        , Html.div
            [ HA.class "n-heatmap-color-indicator__cells" ]
            (List.map colorIndicatorCell (mergedColors theme opts))
        , Html.span
            [ HA.class "n-heatmap-color-indicator__label" ]
            [ Html.text opts.indicatorMoreText ]
        ]


colorIndicatorCell : String -> Html msg
colorIndicatorCell color =
    Html.div
        [ HA.class "n-heatmap-color-indicator__cell"
        , HA.attribute "style" ("background-color:" ++ color)
        ]
        []



-- LABELS


{-| The label for table row `rowIndex` — upstream formats
`addDays(startOfWeek(new Date(), weekStartsOn), i)` with `'eee'`, which is
just the weekday `(weekStartsOn + i) % 7`, so the caller's date-fns-ordered
list rotated by the week start reproduces it without touching `now`.
-}
weekdayLabel : List String -> Int -> Int -> String
weekdayLabel labels weekStartsOn rowIndex =
    labels
        |> List.drop ((weekStartsOn + rowIndex) |> modBy 7)
        |> List.head
        |> Maybe.withDefault ""


monthName : List String -> Int -> String
monthName labels month =
    labels
        |> List.drop (month - 1)
        |> List.head
        |> Maybe.withDefault ""


{-| Upstream's `transformNaiveFirstDayOfWeekToDateFns` — Naive UI numbering
(0 = Monday … 6 = Sunday) to date-fns numbering (0 = Sunday … 6 = Saturday).
`modBy` keeps out-of-range inputs total.
-}
weekStartOn : Int -> Int
weekStartOn firstDayOfWeek =
    DT.firstDayOfWeekToDateFns firstDayOfWeek



-- DATE MATH (delegates to the shared engine, NUI.Internal.DateTime; the
-- zone-local civil day is the unit every heatmap computation works in)


type alias Civil =
    { year : Int
    , month : Int
    , day : Int
    }


{-| The civil date of an instant in `zone` (engine:
`NUI.Internal.DateTime.toCivil`).
-}
toCivil : Time.Zone -> Time.Posix -> Civil
toCivil zone ts =
    DT.toCivil zone (Time.posixToMillis ts)


{-| Days since 1970-01-01 (engine: `NUI.Internal.DateTime.daysFromCivil`).
-}
daysFromCivil : Civil -> Int
daysFromCivil d =
    DT.daysFromCivil d


{-| The local calendar day of an instant — date-fns `startOfDay` /
`differenceInCalendarDays` granularity. This is the unit every heatmap date
computation works in.
-}
dayNumber : Time.Zone -> Time.Posix -> Int
dayNumber zone ts =
    DT.daysFromCivil (DT.toCivil zone (Time.posixToMillis ts))


{-| Weekday of a calendar day in date-fns `getDay` numbering (0 = Sunday …
6 = Saturday; 1970-01-01 was a Thursday).
-}
weekdayOfDay : Int -> Int
weekdayOfDay day =
    DT.weekday (DT.civilFromDays day)


{-| Some instant inside local midnight of a calendar day — the timestamp
gap-filled items carry (upstream `eachDayOfInterval`'s local midnights). Only
the civil day it lands on is ever read back, so any instant of the day is
faithful; the engine's `toPosix` runs the same fixed-point iteration
(`localToTs`) for any real zone offset (including `Time.customZone` and DST
zones), starting from UTC midnight.
-}
posixOfDay : Time.Zone -> Int -> Time.Posix
posixOfDay zone targetDay =
    Time.millisToPosix (DT.toPosix zone (DT.civilFromDays targetDay) { hours = 0, minutes = 0, seconds = 0, ms = 0 })
