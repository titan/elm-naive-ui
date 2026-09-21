module Main exposing (main)

{-| Foundation test suite for elm-naive-ui.

Runs without `elm-test`: it is a self-contained Elm application that evaluates a list
of named assertions and renders one DOM node per assertion
(`[data-test="pass"|"fail"]`, `[data-name]`, `[data-detail]`) plus a `#results`
container carrying `data-total` / `data-failures`.

`tests/inspect.mjs` loads the built page in jsdom, reads the Elm-computed results,
adds a handful of DOM-level assertions (inline `--n-*` style, classes, `aria-disabled`)
and exits non-zero if anything failed.

-}

import Browser
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import NUI.Affix as Affix
import NUI.Alert as Alert
import NUI.Avatar as Avatar
import NUI.AvatarGroup as AvatarGroup
import NUI.BackTop as BackTop
import NUI.Badge as Badge
import NUI.Breadcrumb as Breadcrumb
import NUI.Button as Button
import NUI.ButtonGroup as ButtonGroup
import NUI.Calendar as Calendar
import NUI.Card as Card
import NUI.Checkbox as Checkbox
import NUI.Collapse as Collapse
import NUI.Countdown as Countdown
import NUI.Css as Css
import NUI.Descriptions as Descriptions
import NUI.DynamicInput as DynamicInput
import NUI.DynamicTags as DynamicTags
import NUI.Ellipsis as Ellipsis
import NUI.Empty as Empty
import NUI.Flex as Flex
import NUI.FloatButton as FloatButton
import NUI.FloatButtonGroup as FloatButtonGroup
import NUI.Form as Form
import NUI.GradientText as GradientText
import NUI.Grid as Grid
import NUI.Heatmap as Heatmap
import NUI.Highlight as Highlight
import NUI.Icon as Icon
import NUI.IconWrapper as IconWrapper
import NUI.Input as Input
import NUI.InputNumber as InputNumber
import NUI.InputOtp as InputOtp
import NUI.Internal as Internal
import NUI.Layout as Layout
import NUI.LayoutFooter as LayoutFooter
import NUI.LayoutHeader as LayoutHeader
import NUI.LayoutSider as LayoutSider
import NUI.List as NList
import NUI.LoadingBar as LoadingBar
import NUI.Marquee as Marquee
import NUI.NumberAnimation as NumberAnimation
import NUI.PageHeader as PageHeader
import NUI.Pagination as Pagination
import NUI.Popover as Popover
import NUI.Progress as Progress
import NUI.QrCode as QrCode
import NUI.Qrcodegen as Qrcodegen
import NUI.Radio as Radio
import NUI.Rate as Rate
import NUI.Result as Result
import NUI.Scrollbar as Scrollbar
import NUI.Skeleton as Skeleton
import NUI.Space as Space
import NUI.Spin as Spin
import NUI.Split as Split
import NUI.Statistic as Statistic
import NUI.Steps as Steps
import NUI.Tabs as Tabs
import NUI.Tag as Tag
import NUI.Theme as Theme
import NUI.Theme.Button as ButtonTheme
import NUI.Theme.Calendar as CalendarTheme
import NUI.Theme.Color as Color
import NUI.Theme.DynamicTags as DynamicTagsTheme
import NUI.Theme.FloatButtonGroup as FloatButtonGroupTheme
import NUI.Theme.Heatmap as HeatmapTheme
import NUI.Theme.Icon as IconTheme
import NUI.Theme.IconWrapper as IconWrapperTheme
import NUI.Theme.InputOtp as InputOtpTheme
import NUI.Theme.Layout as LayoutTheme
import NUI.Theme.Tag as TagTheme
import NUI.Thing as Thing
import NUI.Timeline as Timeline
import NUI.Tooltip as Tooltip
import NUI.Types as T
import Time


main : Program () () Msg
main =
    Browser.sandbox
        { init = ()
        , update = \_ model -> model
        , view = view
        }


type Msg
    = NoOp


type alias Check =
    { name : String
    , ok : Bool
    , detail : String
    }


eq : String -> a -> a -> Check
eq name expected actual =
    { name = name
    , ok = expected == actual
    , detail =
        "expected "
            ++ Debug.toString expected
            ++ ", got "
            ++ Debug.toString actual
    }


lookup : String -> List ( String, String ) -> Maybe String
lookup key vars =
    vars
        |> List.filter (\( k, _ ) -> k == key)
        |> List.head
        |> Maybe.map Tuple.second


varKeys : List ( String, String ) -> List String
varKeys vars =
    List.map Tuple.first vars


{-| NaN-tolerant equality for float assertions (Elm's `==` says NaN /= NaN).
-}
nanEq : Float -> Float -> Bool
nanEq a b =
    (Basics.isNaN a && Basics.isNaN b) || a == b


maybeFloatEq : Maybe Float -> Maybe Float -> Bool
maybeFloatEq a b =
    case ( a, b ) of
        ( Just x, Just y ) ->
            nanEq x y

        ( Nothing, Nothing ) ->
            True

        _ ->
            False


{-| `eq` for `Maybe Float`, treating NaN as equal to NaN.
-}
eqNaN : String -> Maybe Float -> Maybe Float -> Check
eqNaN name expected actual =
    { name = name
    , ok = maybeFloatEq expected actual
    , detail =
        "expected "
            ++ Debug.toString expected
            ++ ", got "
            ++ Debug.toString actual
    }


{-| A page-window item rendered as a stable label (a fast item by its kind).
-}
pageItemLabel : Pagination.PageItem -> String
pageItemLabel item =
    case item of
        Pagination.Page { label } ->
            String.fromInt label

        Pagination.FastBackward _ ->
            "fast-backward"

        Pagination.FastForward _ ->
            "fast-forward"


pageLabels : Pagination.PageItemsInfo -> List String
pageLabels info =
    List.map pageItemLabel info.items


{-| The label of the single `active` page item, if any.
-}
activeLabel : Pagination.PageItemsInfo -> Maybe Int
activeLabel info =
    info.items
        |> List.filterMap
            (\item ->
                case item of
                    Pagination.Page { label, active } ->
                        if active then
                            Just label

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.head


{-| `mayBeFastBackward` of the page item with this label.
-}
mayBeFastBackwardOf : Int -> Pagination.PageItemsInfo -> Maybe Bool
mayBeFastBackwardOf label info =
    info.items
        |> List.filterMap
            (\item ->
                case item of
                    Pagination.Page p ->
                        if p.label == label then
                            Just p.mayBeFastBackward

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.head


mayBeFastForwardOf : Int -> Pagination.PageItemsInfo -> Maybe Bool
mayBeFastForwardOf label info =
    info.items
        |> List.filterMap
            (\item ->
                case item of
                    Pagination.Page p ->
                        if p.label == label then
                            Just p.mayBeFastForward

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.head


fastBackwardOptions : Pagination.PageItemsInfo -> Maybe (List { label : String, value : Int })
fastBackwardOptions info =
    info.items
        |> List.filterMap
            (\item ->
                case item of
                    Pagination.FastBackward { options } ->
                        Just options

                    _ ->
                        Nothing
            )
        |> List.head
        |> Maybe.withDefault Nothing


fastForwardOptions : Pagination.PageItemsInfo -> Maybe (List { label : String, value : Int })
fastForwardOptions info =
    info.items
        |> List.filterMap
            (\item ->
                case item of
                    Pagination.FastForward { options } ->
                        Just options

                    _ ->
                        Nothing
            )
        |> List.head
        |> Maybe.withDefault Nothing


{-| An independent `createRange(from, to)` reimplementation for expectations.
-}
rangeOptions : Int -> Int -> List { label : String, value : Int }
rangeOptions from to =
    List.range from to |> List.map (\i -> { label = String.fromInt i, value = i })


{-| A heatmap data item at UTC midnight of `day` (days since 1970-01-01).
-}
heatmapItem : Int -> Maybe Float -> Heatmap.HeatmapDataItem
heatmapItem day value =
    { timestamp = Time.millisToPosix (day * 86400000)
    , value = value
    }


{-| A bare `DayRect` whose only meaningful fields are `timestamp`/`value` —
enough for `dataMonthLabels` (which reads nothing else).
-}
heatmapDayRect : Int -> Maybe Float -> Heatmap.DayRect
heatmapDayRect day value =
    { timestamp = Time.millisToPosix (day * 86400000)
    , value = value
    , color = ""
    , dayOfWeek = 0
    , rowIndex = 0
    , colIndex = 0
    }


heatmapValues : List Heatmap.HeatmapDataItem -> List (Maybe Float)
heatmapValues items =
    List.map .value items


{-| Mirror `view`'s non-loading matrix path: create a `DayRect` per item against
the first item as the grid start, then place them in a sparse 7-row matrix.
-}
heatmapMatrixOf :
    Time.Zone
    -> Int
    -> List String
    -> Float
    -> List Heatmap.HeatmapDataItem
    -> List (List (Maybe Heatmap.DayRect))
heatmapMatrixOf zone weekStartsOn colors maxValue items =
    case items of
        [] ->
            []

        first :: _ ->
            Heatmap.createSparseMatrix 7
                (List.map
                    (\item -> Heatmap.createDayRect zone item first.timestamp weekStartsOn colors maxValue)
                    items
                )
                .rowIndex
                .colIndex


{-| The `.tag` of each non-`Nothing` cell of a `createSparseMatrix` result.
-}
sparseTags : List (List (Maybe { a | tag : Int })) -> List (List (Maybe Int))
sparseTags =
    List.map (List.map (Maybe.map .tag))


listAt : Int -> List a -> Maybe a
listAt index list =
    List.drop index list |> List.head



-- OPTION SETS ------------------------------------------------------------------


primaryOpts : Button.Options msg
primaryOpts =
    let
        d =
            Button.defaults
    in
    { d | kind = T.Primary }


roundOpts : Button.Options msg
roundOpts =
    let
        d =
            Button.defaults
    in
    { d | round = True }


circleOpts : Button.Options msg
circleOpts =
    let
        d =
            Button.defaults
    in
    { d | circle = True }


textOpts : Button.Options msg
textOpts =
    let
        d =
            Button.defaults
    in
    { d | variant = Button.Text }


textPrimaryOpts : Button.Options msg
textPrimaryOpts =
    let
        d =
            Button.defaults
    in
    { d | variant = Button.Text, kind = T.Primary }


ghostPrimaryOpts : Button.Options msg
ghostPrimaryOpts =
    let
        d =
            Button.defaults
    in
    { d | kind = T.Primary, ghost = True }


customColorOpts : Button.Options msg
customColorOpts =
    let
        d =
            Button.defaults
    in
    { d | color = Just "#ff0000" }


strongOpts : Button.Options msg
strongOpts =
    let
        d =
            Button.defaults
    in
    { d | strong = True }


disabledRoundOpts : Button.Options msg
disabledRoundOpts =
    let
        d =
            Button.defaults
    in
    { d | disabled = True, round = True }


primaryTagOpts : Tag.Options msg
primaryTagOpts =
    let
        d =
            Tag.defaults
    in
    { d | kind = T.Primary, closable = True }


checkedTagOpts : Tag.Options msg
checkedTagOpts =
    let
        d =
            Tag.defaults
    in
    { d | kind = T.Success, checkable = True, checked = True }


disabledTagOpts : Tag.Options msg
disabledTagOpts =
    let
        d =
            Tag.defaults
    in
    { d | disabled = True, round = True }


badgeNumOpts : Badge.Options msg
badgeNumOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 20), max = Just 9 }


badgeOverflowOpts : Badge.Options msg
badgeOverflowOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 200), max = Just 99 }


badgeDotOpts : Badge.Options msg
badgeDotOpts =
    let
        d =
            Badge.defaults
    in
    { d | dot = True, type_ = Badge.Info }


emptyLiveOpts : Empty.Options msg
emptyLiveOpts =
    let
        d =
            Empty.defaults
    in
    { d | description = Just "Nothing here", size = Empty.Huge }


progressLineOpts : Progress.Options msg
progressLineOpts =
    let
        d =
            Progress.defaults
    in
    { d | percentage = 66 }


progressCircleOpts : Progress.Options msg
progressCircleOpts =
    let
        d =
            Progress.defaults
    in
    { d | type_ = Progress.Circle, percentage = 80, status = Progress.Success }


progressMultipleOpts : Progress.Options msg
progressMultipleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.MultipleCircle
        , percentages = [ 80, 70 ]
        , colors = [ Progress.Solid "#2080f0", Progress.Solid "#18a058" ]
        , railColors = [ "#2080f0", "#18a058" ]
        , strokeWidth = 10
        , circleGap = 10
    }


progressMultiplePlainOpts : Progress.Options msg
progressMultiplePlainOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.MultipleCircle
        , percentages = [ 0, 60 ]
        , strokeWidth = 10
        , circleGap = 10
    }


progressGradientLineOpts : Progress.Options msg
progressGradientLineOpts =
    let
        d =
            Progress.defaults
    in
    { d | percentage = 80, color = Just (Progress.Gradient [ "white", "pink" ]) }


progressGradientCircleOpts : Progress.Options msg
progressGradientCircleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.Circle
        , percentage = 80
        , color = Just (Progress.Gradient [ "#E3F2FD", "#2080f0" ])
    }


progressGradientMultipleOpts : Progress.Options msg
progressGradientMultipleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.MultipleCircle
        , percentages = [ 80, 70 ]
        , colors = [ Progress.Gradient [ "white", "#18a058" ], Progress.Solid "#2080f0" ]
        , railColors = [ "#18a058", "#2080f0" ]
        , strokeWidth = 10
        , circleGap = 10
    }


progressRailStyleLineOpts : Progress.Options msg
progressRailStyleLineOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | percentage = 40
        , railColor = Just "#000000"
        , railStyle = Just [ ( "background-color", "rgba(0,0,0,0.1)" ), ( "opacity", "0.5" ) ]
    }


progressRailStyleMultipleOpts : Progress.Options msg
progressRailStyleMultipleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.MultipleCircle
        , percentages = [ 80, 70 ]
        , railColors = [ "#2080f0", "#18a058" ]
        , railStyles = [ [ ( "stroke", "#ff0000" ), ( "opacity", "0.3" ) ], [ ( "opacity", "0.5" ) ] ]
        , strokeWidth = 10
        , circleGap = 10
    }


progressRailStyleCircleOpts : Progress.Options msg
progressRailStyleCircleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.Circle
        , percentage = 60
        , railStyle = Just [ ( "opacity", "0.3" ) ]
    }


avatarGroupDefaults : AvatarGroup.Options msg
avatarGroupDefaults =
    AvatarGroup.defaults


avatarGroupOpts : AvatarGroup.Options msg
avatarGroupOpts =
    { avatarGroupDefaults
        | max = Just 3
        , size = Just Avatar.Large
        , maxStyle = [ ( "color", "rgb(1, 2, 3)" ) ]
    }


avatarGroupPlainOpts : AvatarGroup.Options msg
avatarGroupPlainOpts =
    avatarGroupDefaults


avatarGroupVerticalOpts : AvatarGroup.Options msg
avatarGroupVerticalOpts =
    { avatarGroupDefaults | vertical = True, expandOnHover = True, rtl = True }


avatarGroupSlotOpts : AvatarGroup.Options msg
avatarGroupSlotOpts =
    { avatarGroupDefaults
        | max = Just 2
        , avatar =
            Just
                (\opt ->
                    Element.el
                        [ Element.htmlAttribute (HA.class "slot-avatar") ]
                        (Element.text opt.src)
                )
        , rest =
            Just
                (\opts count ->
                    Element.el
                        [ Element.htmlAttribute (HA.class "slot-rest") ]
                        (Element.text
                            ("+" ++ String.fromInt count ++ "[" ++ String.join "," (List.map .src opts) ++ "]")
                        )
                )
    }


avatarGroupFour : List AvatarGroup.AvatarGroupOption
avatarGroupFour =
    [ { src = "a.png" }
    , { src = "b.png" }
    , { src = "c.png" }
    , { src = "d.png" }
    ]


buttonGroupOpts : ButtonGroup.Options msg
buttonGroupOpts =
    ButtonGroup.defaults


buttonGroupVerticalOpts : ButtonGroup.Options msg
buttonGroupVerticalOpts =
    let
        d =
            ButtonGroup.defaults
    in
    { d | vertical = True, rtl = True }


badgeScrollUpOpts : Badge.Options msg
badgeScrollUpOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 123), previousValue = Just (Badge.Number 118) }


badgeScrollDownOpts : Badge.Options msg
badgeScrollDownOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 18), previousValue = Just (Badge.Number 23) }


badgeWaveOpts : Badge.Options msg
badgeWaveOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 5), processing = True, waveActive = True }


badgeLeaveOpts : Badge.Options msg
badgeLeaveOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 5), show = False, transition = Just Internal.LeaveActive }


spinTransitionOpts : Spin.Options msg
spinTransitionOpts =
    let
        d =
            Spin.defaults
    in
    { d | transition = Just Internal.EnterActive }


rtlAlertOpts : Alert.Options msg
rtlAlertOpts =
    let
        d =
            Alert.defaults
    in
    { d | rtl = True }


rtlButtonOpts : Button.Options msg
rtlButtonOpts =
    let
        d =
            Button.defaults
    in
    { d | rtl = True }


rtlCardOpts : Card.Options msg
rtlCardOpts =
    let
        d =
            Card.defaults
    in
    { d | rtl = True }


rtlCheckboxOpts : Checkbox.Options msg
rtlCheckboxOpts =
    let
        d =
            Checkbox.defaults
    in
    { d | rtl = True }


rtlInputOpts : Input.Options msg
rtlInputOpts =
    let
        d =
            Input.defaults
    in
    { d | rtl = True }


rtlRadioOpts : Radio.Options msg
rtlRadioOpts =
    let
        d =
            Radio.defaults
    in
    { d | rtl = True }


rtlRadioGroupOpts : Radio.GroupOptions String msg
rtlRadioGroupOpts =
    let
        d =
            Radio.groupDefaults
    in
    { d | rtl = True }


rtlSpaceOpts : Space.Options msg
rtlSpaceOpts =
    let
        d =
            Space.defaults
    in
    { d | rtl = True }


rtlTagOpts : Tag.Options msg
rtlTagOpts =
    let
        d =
            Tag.defaults
    in
    { d | rtl = True }


rtlBadgeOpts : Badge.Options msg
rtlBadgeOpts =
    let
        d =
            Badge.defaults
    in
    { d | rtl = True, value = Just (Badge.Number 5), offset = Just ( 2, 3 ) }


badgeOffsetOpts : Badge.Options msg
badgeOffsetOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 5), offset = Just ( 4, -2 ) }


resultLiveOpts : Result.Options msg
resultLiveOpts =
    let
        d =
            Result.defaults
    in
    { d | status = Result.Code404, size = Result.Huge, title = Just "404", description = Just "Page not found" }


skeletonLiveOpts : Skeleton.Options msg
skeletonLiveOpts =
    let
        d =
            Skeleton.defaults
    in
    { d | text = True, width = Just (Skeleton.Px 120), repeat = 3 }


gradientLiveOpts : GradientText.Options msg
gradientLiveOpts =
    let
        d =
            GradientText.defaults
    in
    { d | type_ = GradientText.Success }


gradientCustomOpts : GradientText.Options msg
gradientCustomOpts =
    let
        d =
            GradientText.defaults
    in
    { d | gradient = Just (GradientText.fromTo "#ffffff" "#18a058"), size = Just "20px" }


statisticLiveOpts : Statistic.Options msg
statisticLiveOpts =
    let
        d =
            Statistic.defaults
    in
    { d | label = Just "Active", value = Just "128", prefix = Just (Element.text "$") }


breadcrumbLiveOpts : Breadcrumb.Options msg
breadcrumbLiveOpts =
    Breadcrumb.defaults


breadcrumbLiveItems : List (Breadcrumb.Item msg)
breadcrumbLiveItems =
    let
        i =
            Breadcrumb.item
    in
    [ { i | href = Just "/", content = [ Element.text "Home" ] }
    , { i | href = Just "/library", content = [ Element.text "Library" ] }
    , { i | content = [ Element.text "Data" ] }
    ]


timelineLiveOpts : Timeline.Options msg
timelineLiveOpts =
    Timeline.defaults


timelineLiveItems : List (Timeline.Item msg)
timelineLiveItems =
    let
        i =
            Timeline.item
    in
    [ { i | time = Just "2023-01-01", content = [ Element.text "Created" ] }
    , { i
        | type_ = Timeline.Success
        , title = Just "Deployed"
        , time = Just "2023-01-02"
        , content = [ Element.text "Live." ]
      }
    , { i
        | lineType = Timeline.Dashed
        , color = Just "#d03050"
        , content = [ Element.text "Investigating" ]
      }
    ]


timelineLargeOpts : Timeline.Options msg
timelineLargeOpts =
    let
        d =
            Timeline.defaults
    in
    { d | size = Timeline.Large, iconSize = Just 20 }


thingLiveOpts : Thing.Options msg
thingLiveOpts =
    let
        d =
            Thing.defaults
    in
    { d
        | avatar = Just (Element.text "A")
        , title = Just "Title"
        , titleExtra = Just "Extra"
        , description = Just "Desc"
    }


marqueeLiveOpts : Marquee.Options msg
marqueeLiveOpts =
    let
        d =
            Marquee.defaults
    in
    { d | duration = 5, autoFill = True, repeat = 2 }


nlistLiveOpts : NList.Options msg
nlistLiveOpts =
    let
        d =
            NList.defaults
    in
    { d | bordered = True, hoverable = True }


nlistLiveItems : List (NList.Item msg)
nlistLiveItems =
    let
        i =
            NList.item
    in
    [ { i | content = [ Element.text "One" ] }
    , { i
        | prefix = Just (Element.text "*")
        , content = [ Element.text "Two" ]
        , suffix = Just (Element.text "!")
      }
    ]


pageHeaderLiveOpts : PageHeader.Options Msg
pageHeaderLiveOpts =
    let
        d =
            PageHeader.defaults
    in
    { d | title = Just "Title", subtitle = Just "Sub", extra = Just "Extra", onBack = Just NoOp }


affixLiveOpts : Affix.Options msg
affixLiveOpts =
    let
        d =
            Affix.defaults
    in
    { d | affixed = True, top = Just 12, position = Affix.Absolute }


countdownLiveOpts : Countdown.Options msg
countdownLiveOpts =
    let
        d =
            Countdown.defaults
    in
    { d | distance = 90000, precision = 1 }


countdownLiveOpts3 : Countdown.Options msg
countdownLiveOpts3 =
    let
        d =
            Countdown.defaults
    in
    { d | distance = 90000, precision = 3 }


splitLiveOpts : Split.Options msg
splitLiveOpts =
    let
        d =
            Split.defaults
    in
    { d | size = Split.Ratio 0.4, pane1 = [ Element.text "A" ], pane2 = [ Element.text "B" ] }


stepsLiveOpts : Steps.Options msg
stepsLiveOpts =
    let
        d =
            Steps.defaults
    in
    { d | current = Just 2 }


stepsLiveItems : List (Steps.Item msg)
stepsLiveItems =
    let
        i =
            Steps.item
    in
    [ { i | title = Just "One", description = Just "Details" }
    , { i | title = Just "Two" }
    , { i | title = Just "Three" }
    ]


ellipsisLineClampOpts : Ellipsis.Options Msg
ellipsisLineClampOpts =
    let
        d =
            Ellipsis.defaults
    in
    { d | lineClamp = Just 2, expandOnClick = True, onToggle = Just NoOp }


ellipsisExpandedOpts : Ellipsis.Options Msg
ellipsisExpandedOpts =
    let
        d =
            Ellipsis.defaults
    in
    { d | lineClamp = Just 2, expanded = True }


backTopLiveOpts : BackTop.Options Msg
backTopLiveOpts =
    let
        d =
            BackTop.defaults
    in
    { d | show = True, onClick = Just NoOp }


qrCodeLiveOpts : QrCode.Options msg
qrCodeLiveOpts =
    let
        d =
            QrCode.defaults
    in
    { d | value = "HELLO WORLD" }


qrCodeStyledOpts : QrCode.Options msg
qrCodeStyledOpts =
    let
        d =
            QrCode.defaults
    in
    { d
        | value = "https://www.naiveui.com/"
        , color = "#18a058"
        , backgroundColor = "#F5F5F5"
        , size = 140
        , errorCorrectionLevel = QrCode.H
    }


collapseLiveOpts : Collapse.Options msg
collapseLiveOpts =
    let
        d =
            Collapse.defaults
    in
    { d | expandedNames = [ "1" ] }


collapseLiveItems : List (Collapse.Item msg)
collapseLiveItems =
    let
        i =
            Collapse.item
    in
    [ { i | name = "1", title = Just "One" }
    , { i | name = "2", title = Just "Two", disabled = True }
    ]


collapseOneItem : List (Collapse.Item msg)
collapseOneItem =
    let
        i =
            Collapse.item
    in
    [ { i | name = "1", title = Just "One" } ]


collapseShowOpts : Collapse.Options msg
collapseShowOpts =
    let
        d =
            Collapse.defaults
    in
    { d | displayDirective = Collapse.ShowContent }


collapseRtlOpts : Collapse.Options msg
collapseRtlOpts =
    let
        d =
            Collapse.defaults
    in
    { d | rtl = True }


rateLiveOpts : Rate.Options msg
rateLiveOpts =
    let
        d =
            Rate.defaults
    in
    { d | value = Just 4 }


rateReadonlyOpts : Rate.Options msg
rateReadonlyOpts =
    let
        d =
            Rate.defaults
    in
    { d | value = Just 3, readonly = True }


rateHalfOpts : Rate.Options msg
rateHalfOpts =
    let
        d =
            Rate.defaults
    in
    { d | allowHalf = True, value = Just 3.5 }


floatButtonLiveOpts : FloatButton.Options msg
floatButtonLiveOpts =
    FloatButton.defaults


floatButtonSquareOpts : FloatButton.Options msg
floatButtonSquareOpts =
    let
        d =
            FloatButton.defaults
    in
    { d | shape = FloatButton.Square, type_ = FloatButton.Primary }


floatButtonMenuOpts : FloatButton.Options msg
floatButtonMenuOpts =
    let
        d =
            FloatButton.defaults
    in
    { d | menuTrigger = Just FloatButton.Click, showMenu = True, menu = [ Element.text "M" ] }


floatButtonWidthOpts : FloatButton.Options msg
floatButtonWidthOpts =
    let
        d =
            FloatButton.defaults
    in
    { d | width = FloatButton.Custom "40" }


floatButtonPercentOpts : FloatButton.Options msg
floatButtonPercentOpts =
    let
        d =
            FloatButton.defaults
    in
    { d | width = FloatButton.Custom "50%" }



-- Highlight / NumberAnimation / Icon / IconWrapper / FloatButtonGroup ------------


highlightLiveOpts : Highlight.Options msg
highlightLiveOpts =
    let
        d =
            Highlight.defaults
    in
    { d | text = "Hello world, hello again", patterns = [ "hello" ] }


highlightEscapedOpts : Highlight.Options msg
highlightEscapedOpts =
    let
        d =
            Highlight.defaults
    in
    { d
        | text = "Price: $100.99"
        , patterns = [ "$100.99" ]
        , highlightClass = Just "custom-mark"
        , highlightStyle = [ ( "color", "red" ) ]
    }


highlightEmptyOpts : Highlight.Options msg
highlightEmptyOpts =
    let
        d =
            Highlight.defaults
    in
    { d | text = "plain text", patterns = [] }


numberAnimationLiveOpts : NumberAnimation.Options msg
numberAnimationLiveOpts =
    let
        d =
            NumberAnimation.defaults
    in
    { d | from = 1234567.5, to = 1234567.5, precision = 2, showSeparator = True }


numberAnimationMidOpts : NumberAnimation.Options msg
numberAnimationMidOpts =
    let
        d =
            NumberAnimation.defaults
    in
    { d | from = 10, to = 110, duration = 1000, elapsed = 500 }


iconDepthOpts : Icon.Options msg
iconDepthOpts =
    let
        d =
            Icon.defaults
    in
    { d | depth = Just Icon.Depth2, size = Just (Icon.Px 40), color = Just "rgb(14, 122, 13)" }


iconWrapperStyledOpts : IconWrapper.Options msg
iconWrapperStyledOpts =
    let
        d =
            IconWrapper.defaults
    in
    { d
        | size = IconWrapper.Px 18
        , borderRadius = IconWrapper.Px 10
        , color = Just "red"
        , iconColor = Just "red"
    }


floatButtonGroupSquareOpts : FloatButtonGroup.Options msg
floatButtonGroupSquareOpts =
    let
        d =
            FloatButtonGroup.defaults
    in
    { d
        | shape = FloatButton.Square
        , position = FloatButton.Absolute
        , right = Just (FloatButton.Px 40)
        , bottom = Just (FloatButton.Px 40)
    }



-- Heatmap ---------------------------------------------------------------------


heatmapD : Heatmap.Options msg
heatmapD =
    Heatmap.defaults


{-| The examples page's deterministic demo data: 70 consecutive UTC midnights
starting 2024-01-01, `Just 0` every fifth day and `modBy 11 (i * 7 + 3)`
otherwise (max 10).
-}
heatmapSample : List Heatmap.HeatmapDataItem
heatmapSample =
    List.indexedMap
        (\i _ ->
            { timestamp = Time.millisToPosix (1704067200000 + i * 86400000)
            , value =
                if modBy 5 i == 0 then
                    Just 0

                else
                    Just (toFloat (modBy 11 (i * 7 + 3)))
            }
        )
        (List.repeat 70 ())


{-| `Date.now()` stand-in (2024-03-10T16:00:00Z) — only feeds the loading
matrix's dead timestamps and (through it) the derived month labels.
-}
heatmapNow : Time.Posix
heatmapNow =
    Time.millisToPosix 1710086400000


heatmapLiveOpts : Heatmap.Options msg
heatmapLiveOpts =
    { heatmapD | data = heatmapSample, now = heatmapNow }


heatmapLoadingOpts : Heatmap.Options msg
heatmapLoadingOpts =
    { heatmapD | loading = True, loadingData = Just [], now = heatmapNow }


heatmapSmallOpts : Heatmap.Options msg
heatmapSmallOpts =
    { heatmapD
        | data = heatmapSample
        , size = Heatmap.Small
        , activeColors = Just [ "#e0e7ff", "#a5b4fc", "#6366f1", "#4338ca", "#312e81" ]
        , fillCalendarLeading = True
        , now = heatmapNow
    }


{-| Starts mid-week (Wed 2024-01-03) so `fillCalendarLeading` visibly pads the
week's leading days (Mon/Tue) with value-0 rects instead of empty cells.
-}
heatmapLeadingData : List Heatmap.HeatmapDataItem
heatmapLeadingData =
    [ { timestamp = Time.millisToPosix (19725 * 86400000), value = Just 5 }
    , { timestamp = Time.millisToPosix (19731 * 86400000), value = Just 10 }
    ]


heatmapLeadingOpts : Heatmap.Options msg
heatmapLeadingOpts =
    { heatmapD | data = heatmapLeadingData, fillCalendarLeading = True, now = heatmapNow }


heatmapNoFillOpts : Heatmap.Options msg
heatmapNoFillOpts =
    { heatmapD | data = heatmapLeadingData, fillCalendarLeading = False, now = heatmapNow }



-- LOADINGBAR / DYNAMICINPUT FIXTURES -------------------------------------------


loadingBarCustomOpts : LoadingBar.Options msg
loadingBarCustomOpts =
    let
        d =
            LoadingBar.defaults
    in
    { d
        | containerClass = Just "my-container"
        , containerStyle = Just "position:relative;margin-bottom:8px;"
        , loadingBarStyle = Just { loading = "opacity:0.5", error = "opacity:0.9" }
    }


loadingBarStarting : LoadingBar.State
loadingBarStarting =
    LoadingBar.start LoadingBar.init


loadingBarKicked : LoadingBar.State
loadingBarKicked =
    LoadingBar.start LoadingBar.init |> LoadingBar.kick


loadingBarFromTo : LoadingBar.State
loadingBarFromTo =
    LoadingBar.startFromTo 20 60 LoadingBar.init


loadingBarFromToKicked : LoadingBar.State
loadingBarFromToKicked =
    LoadingBar.startFromTo 20 60 LoadingBar.init |> LoadingBar.kick


loadingBarFinishing : LoadingBar.State
loadingBarFinishing =
    LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.finish


{-| A finishing run with the leave fade in flight — upstream's guard window.
-}
loadingBarLeave : LoadingBar.State
loadingBarLeave =
    { loadingBarFinishing | phase = Just Internal.LeaveFrom }


loadingBarErroring : LoadingBar.State
loadingBarErroring =
    LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.error


{-| The empty-state Create button's disabled case: `max` reached.
-}
dynamicInputMaxedOpts : DynamicInput.InputOptions Msg
dynamicInputMaxedOpts =
    let
        d =
            DynamicInput.inputDefaults
    in
    { d | value = [ "a", "b" ], max = Just 2 }


{-| The examples' `input` preset fixture: three names with a placeholder.
-}
dynamicInputLiveOpts : DynamicInput.InputOptions Msg
dynamicInputLiveOpts =
    let
        d =
            DynamicInput.inputDefaults
    in
    { d
        | value = [ "Alice", "Bob", "Cindy" ]
        , placeholder = Just "Name"
        , onUpdateValue = Just (always NoOp)
    }


{-| The examples' `pair` preset fixture: two key / value rows.
-}
dynamicInputPairLiveOpts : DynamicInput.PairOptions Msg
dynamicInputPairLiveOpts =
    let
        d =
            DynamicInput.pairDefaults
    in
    { d
        | value = [ ( "Name", "Naive UI" ), ( "Author", "07akioni" ) ]
        , keyPlaceholder = Just "Key"
        , valuePlaceholder = Just "Value"
        , onUpdateValue = Just (always NoOp)
    }


{-| `max 3`, two entries, `showSortButton` -> remove / add / up / down per row.
-}
dynamicInputMaxSortOpts : DynamicInput.InputOptions Msg
dynamicInputMaxSortOpts =
    let
        d =
            DynamicInput.inputDefaults
    in
    { d
        | value = [ "Only", "Three" ]
        , max = Just 3
        , showSortButton = True
        , onUpdateValue = Just (always NoOp)
    }


{-| Empty value -> the block ghost dashed Create button.
-}
dynamicInputEmptyOpts : DynamicInput.InputOptions Msg
dynamicInputEmptyOpts =
    let
        d =
            DynamicInput.inputDefaults
    in
    { d | value = [], onUpdateValue = Just (always NoOp) }


{-| One entry, `min 1` -> the remove button is disabled.
-}
dynamicInputMinLiveOpts : DynamicInput.InputOptions Msg
dynamicInputMinLiveOpts =
    let
        d =
            DynamicInput.inputDefaults
    in
    { d
        | value = [ "a" ]
        , min = 1
        , onUpdateValue = Just (always NoOp)
    }


dynamicInputRtlOpts : DynamicInput.InputOptions Msg
dynamicInputRtlOpts =
    let
        d =
            DynamicInput.inputDefaults
    in
    { d
        | value = [ "a" ]
        , rtl = True
        , onUpdateValue = Just (always NoOp)
    }


dynamicInputItemStyleOpts : DynamicInput.InputOptions Msg
dynamicInputItemStyleOpts =
    let
        d =
            DynamicInput.inputDefaults
    in
    { d
        | value = [ "a" ]
        , itemClass = Just "my-item"
        , itemStyle = Just "background:red"
        , onUpdateValue = Just (always NoOp)
    }


inputOtpLiveOpts : InputOtp.Options msg
inputOtpLiveOpts =
    let
        d =
            InputOtp.defaults
    in
    { d | length = 4, value = [ "1", "2", "3", "4" ] }


inputOtpRtlBlockOpts : InputOtp.Options msg
inputOtpRtlBlockOpts =
    let
        d =
            InputOtp.defaults
    in
    { d | length = 4, rtl = True, block = True }


inputOtpMaskOpts : InputOtp.Options msg
inputOtpMaskOpts =
    let
        d =
            InputOtp.defaults
    in
    { d | length = 4, mask = True }


dynamicTagsLiveOpts : DynamicTags.Options msg
dynamicTagsLiveOpts =
    let
        d =
            DynamicTags.defaults
    in
    { d | value = [ "hello", "world" ] }


dynamicTagsInputOpts : DynamicTags.Options msg
dynamicTagsInputOpts =
    let
        d =
            DynamicTags.defaults
    in
    { d | value = [ "hello" ], showInput = True }


calendarLiveOpts : Calendar.Options msg
calendarLiveOpts =
    let
        d =
            Calendar.defaults
    in
    { d
        | panel = { year = 2026, month = 7 }
        , now = { year = 2026, month = 7, day = 15 }
        , value = Just { year = 2026, month = 7, day = 20 }
        , isDateDisabled = Just (\date -> date == { year = 2026, month = 7, day = 10 })
    }


calendarSixWeekOpts : Calendar.Options msg
calendarSixWeekOpts =
    let
        d =
            Calendar.defaults
    in
    { d | panel = { year = 2026, month = 8 }, now = { year = 2026, month = 8, day = 1 } }



-- PAGINATION OPTION SETS -------------------------------------------------------


paginationLiveOpts : Pagination.Options Msg
paginationLiveOpts =
    let
        d =
            Pagination.defaults
    in
    { d | itemCount = Just 153, currentPage = 6, pageSize = Just 10, onUpdatePage = Just (\_ -> NoOp) }


paginationSimpleOpts : Pagination.Options msg
paginationSimpleOpts =
    let
        d =
            Pagination.defaults
    in
    { d | itemCount = Just 30, currentPage = 2, pageSize = Just 10, simple = True }


paginationDisabledOpts : Pagination.Options msg
paginationDisabledOpts =
    let
        d =
            Pagination.defaults
    in
    { d | itemCount = Just 30, currentPage = 2, disabled = True }


paginationRtlOpts : Pagination.Options msg
paginationRtlOpts =
    let
        d =
            Pagination.defaults
    in
    { d | rtl = True }



-- INPUT NUMBER OPTION SETS -----------------------------------------------------


inputNumberLiveOpts : InputNumber.Options Msg
inputNumberLiveOpts =
    let
        d =
            InputNumber.defaults
    in
    { d | value = Just 5, onChange = Just (\_ -> NoOp), onInput = Just (\_ -> NoOp) }


inputNumberBothOpts : InputNumber.Options Msg
inputNumberBothOpts =
    let
        d =
            InputNumber.defaults
    in
    { d
        | value = Just 5
        , buttonPlacement = InputNumber.Both
        , onChange = Just (\_ -> NoOp)
        , onInput = Just (\_ -> NoOp)
    }


inputNumberNoButtonOpts : InputNumber.Options Msg
inputNumberNoButtonOpts =
    let
        d =
            InputNumber.defaults
    in
    { d | value = Just 5, showButton = False, onChange = Just (\_ -> NoOp), onInput = Just (\_ -> NoOp) }


inputNumberRtlOpts : InputNumber.Options Msg
inputNumberRtlOpts =
    let
        d =
            InputNumber.defaults
    in
    { d | value = Just 5, rtl = True, onChange = Just (\_ -> NoOp), onInput = Just (\_ -> NoOp) }



-- LAYOUT OPTION SETS -----------------------------------------------------------


layoutPlainOpts : Layout.Options msg
layoutPlainOpts =
    Layout.defaults


layoutSiderOpts : Layout.Options msg
layoutSiderOpts =
    let
        d =
            Layout.defaults
    in
    { d | hasSider = True }


layoutAbsoluteOpts : Layout.Options msg
layoutAbsoluteOpts =
    let
        d =
            Layout.defaults
    in
    { d | position = Layout.Absolute }


layoutEmbeddedOpts : Layout.Options msg
layoutEmbeddedOpts =
    let
        d =
            Layout.defaults
    in
    { d | embedded = True }


siderOpts : LayoutSider.Options msg
siderOpts =
    let
        d =
            LayoutSider.defaults
    in
    { d | bordered = True }


siderArrowOpts : LayoutSider.Options msg
siderArrowOpts =
    let
        d =
            LayoutSider.defaults
    in
    { d | showTrigger = LayoutSider.ArrowCircle }


siderBarOpts : LayoutSider.Options msg
siderBarOpts =
    let
        d =
            LayoutSider.defaults
    in
    { d | showTrigger = LayoutSider.Bar }


siderRightCollapsedOpts : LayoutSider.Options msg
siderRightCollapsedOpts =
    let
        d =
            LayoutSider.defaults
    in
    { d | placement = LayoutSider.Right, collapsed = True }


siderCollapsedNoContentOpts : LayoutSider.Options msg
siderCollapsedNoContentOpts =
    let
        d =
            LayoutSider.defaults
    in
    { d | collapsed = True, showCollapsedContent = False }


siderInvertedOpts : LayoutSider.Options msg
siderInvertedOpts =
    let
        d =
            LayoutSider.defaults
    in
    { d | inverted = True }


siderNoBorderOpts : LayoutSider.Options msg
siderNoBorderOpts =
    LayoutSider.defaults


layoutHeaderOpts : LayoutHeader.Options msg
layoutHeaderOpts =
    let
        d =
            LayoutHeader.defaults
    in
    { d | bordered = True }


layoutHeaderInvertedOpts : LayoutHeader.Options msg
layoutHeaderInvertedOpts =
    let
        d =
            LayoutHeader.defaults
    in
    { d | inverted = True }


layoutFooterOpts : LayoutFooter.Options msg
layoutFooterOpts =
    let
        d =
            LayoutFooter.defaults
    in
    { d | bordered = True }


layoutFooterInvertedOpts : LayoutFooter.Options msg
layoutFooterInvertedOpts =
    let
        d =
            LayoutFooter.defaults
    in
    { d | inverted = True }



-- FLEX / GRID PROBES -----------------------------------------------------------


flexDefaults : Flex.Options msg
flexDefaults =
    Flex.defaults


flexInlineOpts : Flex.Options msg
flexInlineOpts =
    { flexDefaults | inline = True }


flexVerticalOpts : Flex.Options msg
flexVerticalOpts =
    { flexDefaults | direction = Flex.Vertical }


flexReverseOpts : Flex.Options msg
flexReverseOpts =
    { flexDefaults | reverse = True }


flexReverseVerticalOpts : Flex.Options msg
flexReverseVerticalOpts =
    { flexDefaults | direction = Flex.Vertical, reverse = True }


flexAlignCenterOpts : Flex.Options msg
flexAlignCenterOpts =
    { flexDefaults | align = Just Flex.Center }


flexSpaceBetweenOpts : Flex.Options msg
flexSpaceBetweenOpts =
    { flexDefaults | justify = Flex.SpaceBetween }


flexNumberGapOpts : Flex.Options msg
flexNumberGapOpts =
    { flexDefaults | size = Flex.Number 5 }


flexNumber2GapOpts : Flex.Options msg
flexNumber2GapOpts =
    { flexDefaults | size = Flex.Number2 3 9 }


flexRtlOpts : Flex.Options msg
flexRtlOpts =
    { flexDefaults | rtl = True }


gridDefaults : Grid.Options msg
gridDefaults =
    Grid.defaults


{-| A bindable copy of `Grid.item` — record-update syntax needs a variable, not a
qualified name.
-}
gridItemBase : Grid.Item msg
gridItemBase =
    Grid.item


gridCollapseOpts : Grid.Options msg
gridCollapseOpts =
    { gridDefaults | cols = Grid.Number 12, collapsed = True, collapsedRows = 1 }


gridSuffixOpts : Grid.Options msg
gridSuffixOpts =
    { gridDefaults | collapsed = True, collapsedRows = 1 }


gridLayoutShiftOpts : Grid.Options msg
gridLayoutShiftOpts =
    { gridDefaults | layoutShiftDisabled = True, xGap = Grid.Number 16, yGap = Grid.Number 8 }


{-| `n` items each spanning 12 columns.
-}
gridHalfItems : Int -> List (Grid.Item msg)
gridHalfItems n =
    List.repeat n { gridItemBase | span = Grid.Number 12 }


{-| The grid-level `overflow` flag from `viewWithOverflow` (the pure half of the
collapse algorithm).
-}
gridOverflow : Grid.Options msg -> List (Grid.Item msg) -> Bool
gridOverflow opts items =
    Tuple.second (Grid.viewWithOverflow opts items)



-- QRCODEGEN PROBES -------------------------------------------------------------


encodedSize : String -> Qrcodegen.Ecc -> Int
encodedSize text ecc =
    case Qrcodegen.encodeText text ecc of
        Ok qr ->
            Qrcodegen.size qr

        Err _ ->
            -1


gridSquare : String -> Qrcodegen.Ecc -> Bool
gridSquare text ecc =
    case Qrcodegen.encodeText text ecc of
        Ok qr ->
            let
                size =
                    Qrcodegen.size qr

                rows =
                    Qrcodegen.getModules qr
            in
            List.length rows
                == size
                && List.all (\row -> List.length row == size) rows

        Err _ ->
            False


moduleAt : String -> Qrcodegen.Ecc -> Int -> Int -> Bool
moduleAt text ecc x y =
    case Qrcodegen.encodeText text ecc of
        Ok qr ->
            Qrcodegen.getModule qr x y

        Err _ ->
            False


isErr : Result e a -> Bool
isErr result =
    case result of
        Err _ ->
            True

        Ok _ ->
            False



-- FORM FIXTURES ----------------------------------------------------------------


{-| `validateValue` with the field name pinned to "f".
-}
fval : Maybe Form.Trigger -> List Form.Rule -> Maybe Form.Value -> List Form.Feedback
fval trigger rules value =
    Form.validateValue trigger "f" rules value


{-| `validateValue` with a caller-chosen field name.
-}
fvalAs : String -> Maybe Form.Trigger -> List Form.Rule -> Maybe Form.Value -> List Form.Feedback
fvalAs field trigger rules value =
    Form.validateValue trigger field rules value


fmsgs : List Form.Feedback -> List String
fmsgs =
    List.map .message


flevels : List Form.Feedback -> List Form.Level
flevels =
    List.map .level


{-| One `--n-*` var of a form item.
-}
fvar : Theme.Theme -> Form.ItemOptions -> String -> Maybe String
fvar theme opts key =
    lookup key (Form.cssVarsForItem theme opts)


{-| A local base for record updates (Elm only updates a variable, never a
qualified value in place).
-}
fdflt : Form.Rule
fdflt =
    Form.defaultRule


fditem : Form.ItemOptions
fditem =
    Form.itemDefaults


fdefs : Form.Options Msg
fdefs =
    Form.defaults


{-| A required rule (default `TypeString`).
-}
freq : Form.Rule
freq =
    { fdflt | required = True }


{-| A failing error-level rule with a verbatim message.
-}
ferr : String -> Form.Rule
ferr message =
    { fdflt | required = True, message = Just message }


{-| A failing warning-level rule with a verbatim message.
-}
fwarn : String -> Form.Rule
fwarn message =
    { fdflt | required = True, level = Form.WarningLevel, message = Just message }


{-| A required rule restricted to the given triggers.
-}
fstr : List Form.Trigger -> Form.Rule
fstr triggers =
    { fdflt | required = True, message = Just "t", trigger = Just triggers }


fbwd : Form.Rule
fbwd =
    fstr [ Form.OnBlur, Form.OnChange ]


formRules : Form.Rules
formRules =
    [ ( "a", [ ferr "a-req" ] ), ( "b", [ ferr "b-req" ] ), ( "c", [ ferr "c-req" ] ) ]


formValues : Form.Values
formValues =
    [ ( "a", Form.VString "x" ), ( "b", Form.VString "" ), ( "c", Form.VString "y" ) ]


{-| The 16 `--n-*` vars `cssVarsForItem` attaches, sorted.
-}
formItemVarKeys : List String
formItemVarKeys =
    [ "--n-asterisk-color"
    , "--n-bezier"
    , "--n-blank-height"
    , "--n-feedback-font-size"
    , "--n-feedback-height"
    , "--n-feedback-padding"
    , "--n-feedback-text-color"
    , "--n-feedback-text-color-error"
    , "--n-feedback-text-color-warning"
    , "--n-label-font-size"
    , "--n-label-font-weight"
    , "--n-label-height"
    , "--n-label-padding"
    , "--n-label-text-align"
    , "--n-label-text-color"
    , "--n-line-height"
    ]



-- Descriptions -----------------------------------------------------------------


ddflt : Descriptions.Options Msg
ddflt =
    Descriptions.defaults


ditem : Descriptions.Item Msg
ditem =
    Descriptions.itemDefaults


{-| A compact `shape index:colspan` per cell, so a whole layout pins as one string.
-}
dcell : Descriptions.Cell -> String
dcell c =
    (case c.shape of
        Descriptions.HeaderCell ->
            "H"

        Descriptions.ContentCell ->
            "C"

        Descriptions.CombinedCell ->
            "K"
    )
        ++ String.fromInt c.index
        ++ ":"
        ++ String.fromInt c.colspan


drows : List (List Descriptions.Cell) -> String
drows rows =
    rows |> List.map (List.map dcell >> String.join ",") |> String.join "|"


dlayout : Int -> Descriptions.Placement -> Bool -> List Int -> String
dlayout column placement bordered spans =
    drows (Descriptions.layout { column = column, labelPlacement = placement, bordered = bordered } spans)


dvar : Theme.Theme -> Descriptions.Options Msg -> String -> Maybe String
dvar theme opts key =
    lookup key (Descriptions.cssVars theme opts)


tvar : Theme.Theme -> Tabs.Options Msg -> String -> Maybe String
tvar theme opts key =
    lookup key (Tabs.cssVars theme opts)


svar : Theme.Theme -> Scrollbar.Options Msg -> String -> Maybe String
svar theme opts key =
    lookup key (Scrollbar.cssVars theme opts)


descItem : String -> Descriptions.Item Msg
descItem lbl =
    { ditem | label = Just (Element.text lbl), content = [ Element.text (lbl ++ "-c") ] }


descItems3 : List (Descriptions.Item Msg)
descItems3 =
    [ descItem "A", descItem "B", descItem "C" ]


descItems4 : List (Descriptions.Item Msg)
descItems4 =
    [ descItem "A", descItem "B", descItem "C", descItem "D" ]


descBasicItems : List (Descriptions.Item Msg)
descBasicItems =
    [ descItem "Breakfast"
    , descItem "Brunch"
    , descItem "Lunch"
    , { ditem | span = 2, label = Just (Element.text "Supper"), content = [ Element.text "Supper-c" ] }
    , descItem "Midnight Snack"
    ]


descItemStyled : List (Descriptions.Item Msg)
descItemStyled =
    [ { ditem
        | label = Just (Element.text "L")
        , labelStyle = Just "color:green"
        , contentStyle = Just "background:yellow"
        , content = [ Element.text "L-c" ]
      }
    ]


descBasicOpts : Descriptions.Options Msg
descBasicOpts =
    { ddflt | title = Just (Element.text "Description") }


descBorderedOpts : Descriptions.Options Msg
descBorderedOpts =
    { ddflt | bordered = True }


descLeftOpts : Descriptions.Options Msg
descLeftOpts =
    { ddflt | labelPlacement = Descriptions.Left }


descLeftBorderedOpts : Descriptions.Options Msg
descLeftBorderedOpts =
    { ddflt | labelPlacement = Descriptions.Left, bordered = True }


descColumnsOpts : Descriptions.Options Msg
descColumnsOpts =
    { ddflt | columns = Just 4 }


descSmallOpts : Descriptions.Options Msg
descSmallOpts =
    { ddflt | size = Descriptions.Small }


descLargeBorderedOpts : Descriptions.Options Msg
descLargeBorderedOpts =
    { ddflt | size = Descriptions.Large, bordered = True }


descSeparatorOpts : Descriptions.Options Msg
descSeparatorOpts =
    { ddflt | labelPlacement = Descriptions.Left, separator = "/" }


descEmptySeparatorOpts : Descriptions.Options Msg
descEmptySeparatorOpts =
    { ddflt | labelPlacement = Descriptions.Left, separator = "" }


descCenterOpts : Descriptions.Options Msg
descCenterOpts =
    { ddflt | labelAlign = Descriptions.AlignCenter }


descPassthroughOpts : Descriptions.Options Msg
descPassthroughOpts =
    { ddflt
        | labelClass = Just "my-label"
        , labelStyle = Just "color:red"
        , contentClass = Just "my-content"
        , contentStyle = Just "background:blue"
    }



-- TABS ------------------------------------------------------------------------


tdefault : Tabs.Options Msg
tdefault =
    let
        d =
            Tabs.defaults
    in
    { d | value = "a" }


ttabs : List (Tabs.Tab Msg)
ttabs =
    [ { name = "a", label = Element.text "A", disabled = False, closable = Nothing, content = [ Element.text "A-c" ] }
    , { name = "b", label = Element.text "B", disabled = False, closable = Nothing, content = [ Element.text "B-c" ] }
    , { name = "c", label = Element.text "C", disabled = False, closable = Nothing, content = [ Element.text "C-c" ] }
    ]


ttabsDisabled : List (Tabs.Tab Msg)
ttabsDisabled =
    [ { name = "a", label = Element.text "A", disabled = False, closable = Nothing, content = [ Element.text "A-c" ] }
    , { name = "b", label = Element.text "B", disabled = True, closable = Nothing, content = [ Element.text "B-c" ] }
    ]


tLineOpts : Tabs.Options Msg
tLineOpts =
    { tdefault | type_ = Tabs.Line }


tCardOpts : Tabs.Options Msg
tCardOpts =
    { tdefault | type_ = Tabs.Card }


tSegmentOpts : Tabs.Options Msg
tSegmentOpts =
    { tdefault | type_ = Tabs.Segment }


tSmallOpts : Tabs.Options Msg
tSmallOpts =
    { tdefault | size = Tabs.Small }


tLargeOpts : Tabs.Options Msg
tLargeOpts =
    { tdefault | size = Tabs.Large }


tBottomOpts : Tabs.Options Msg
tBottomOpts =
    { tdefault | placement = Tabs.Bottom }


tLeftOpts : Tabs.Options Msg
tLeftOpts =
    { tdefault | placement = Tabs.Left }


tRightOpts : Tabs.Options Msg
tRightOpts =
    { tdefault | placement = Tabs.Right }


tJustifyOpts : Tabs.Options Msg
tJustifyOpts =
    { tdefault | justifyContent = Just Tabs.JustifyCenter }


tClosableBarOpts : Tabs.Options Msg
tClosableBarOpts =
    { tdefault | closable = True }


tCardClosableOpts : Tabs.Options Msg
tCardClosableOpts =
    { tCardOpts | closable = True }


tAddableOpts : Tabs.Options Msg
tAddableOpts =
    { tCardOpts | addable = True }


tRtlOpts : Tabs.Options Msg
tRtlOpts =
    { tdefault | rtl = True }


tPrefixSuffixOpts : Tabs.Options Msg
tPrefixSuffixOpts =
    { tdefault | prefix = Just (Element.text "P"), suffix = Just (Element.text "S") }


tDisabledOpts : Tabs.Options Msg
tDisabledOpts =
    tdefault


tShowOpts : Tabs.Options Msg
tShowOpts =
    { tdefault | displayDirective = Tabs.Show }


tHoverOpts : Tabs.Options Msg
tHoverOpts =
    { tdefault | trigger = Tabs.Hover, onChange = Just (\_ -> NoOp) }


tStylingOpts : Tabs.Options Msg
tStylingOpts =
    { tdefault
        | tabClass = Just "my-tab"
        , tabStyle = Just "color:red"
        , paneClass = Just "my-pane"
        , paneStyle = Just "background:blue"
    }



-- SCROLLBAR -------------------------------------------------------------------


{-| The plain defaults binding (`{ Scrollbar.defaults | … }` is a parse error).
-}
sD : Scrollbar.Options Msg
sD =
    Scrollbar.defaults


sBarsOpts : Scrollbar.Options Msg
sBarsOpts =
    { sD | showYBar = True, yBarStyle = Just "height:40px;top:0" }


sXOpts : Scrollbar.Options Msg
sXOpts =
    { sD | xScrollable = True, showXBar = True, xBarStyle = Just "width:50px;left:0" }


sTopRailOpts : Scrollbar.Options Msg
sTopRailOpts =
    { sD | xScrollable = True, showXBar = True, xBarStyle = Just "width:50px", xPlacement = Scrollbar.Top }


sLeftOpts : Scrollbar.Options Msg
sLeftOpts =
    { sD | yPlacement = Scrollbar.Left }


sRtlOpts : Scrollbar.Options Msg
sRtlOpts =
    { sD | rtl = True }


sStylingOpts : Scrollbar.Options Msg
sStylingOpts =
    { sD
        | contentClass = Just "my-content"
        , contentStyle = Just "background:blue"
        , attributes = [ Element.htmlAttribute (HA.class "my-root") ]
    }


sXContentOpts : Scrollbar.Options Msg
sXContentOpts =
    { sD | xScrollable = True, contentStyle = Just "background:red" }



-- POPOVER ---------------------------------------------------------------------


{-| The plain defaults binding (`{ Popover.defaults | … }` is a parse error).
-}
pD : Popover.Options Msg
pD =
    Popover.defaults


pHeaderFooterOpts : Popover.Options Msg
pHeaderFooterOpts =
    { pD | header = Just (Element.text "Header"), footer = Just (Element.text "Footer") }


pHeaderOnlyOpts : Popover.Options Msg
pHeaderOnlyOpts =
    { pD | header = Just (Element.text "Header") }


pWidthOpts : Popover.Options Msg
pWidthOpts =
    { pD | width = Just "240px" }


pNoArrowOpts : Popover.Options Msg
pNoArrowOpts =
    { pD | showArrow = False }


pOverlapOpts : Popover.Options Msg
pOverlapOpts =
    { pD | overlap = True }


pRawOpts : Popover.Options Msg
pRawOpts =
    { pD | raw = True }


pRtlOpts : Popover.Options Msg
pRtlOpts =
    { pD | rtl = True }


pCenterArrowOpts : Popover.Options Msg
pCenterArrowOpts =
    { pD | arrowPointToCenter = True }


pScrollableOpts : Popover.Options Msg
pScrollableOpts =
    { pD | scrollable = True, contentClass = Just "my-sc" }


pScrollableHeaderOpts : Popover.Options Msg
pScrollableHeaderOpts =
    { pD | scrollable = True, header = Just (Element.text "Header") }


pTransitionOpts : Popover.Options Msg
pTransitionOpts =
    { pD | transition = Just Internal.EnterActive }


pPassthroughOpts : Popover.Options Msg
pPassthroughOpts =
    { pD
        | header = Just (Element.text "H")
        , footer = Just (Element.text "F")
        , contentClass = Just "my-content"
        , contentStyle = Just "background:blue"
        , headerClass = Just "my-header"
        , headerStyle = Just "background:green"
        , footerClass = Just "my-footer"
        , footerStyle = Just "background:yellow"
        , arrowClass = Just "my-arrow"
        , arrowStyle = Just "background:red"
        , arrowWrapperClass = Just "my-arrow-wrap"
        , arrowWrapperStyle = Just "background:black"
        , attributes = [ Element.htmlAttribute (HA.class "my-root") ]
    }


{-| The tooltip defaults (the popover's) — bound for record updates
(`{ Tooltip.defaults | … }` is a parse error).
-}
tD : Tooltip.Options Msg
tD =
    Tooltip.defaults


tNoArrowOpts : Tooltip.Options Msg
tNoArrowOpts =
    { tD | showArrow = False }


tOverlapOpts : Tooltip.Options Msg
tOverlapOpts =
    { tD | overlap = True }


{-| A caller-supplied `extraClasses` list — the port must still prepend
`n-tooltip` (upstream `internalExtraClass.concat('tooltip')`).
-}
tExtraOpts : Tooltip.Options Msg
tExtraOpts =
    { tD | extraClasses = [ "caller-class" ] }


{-| A raw CSS `width` — upstream merges it into the one style attribute
**before** the vars (`styleRef` order).
-}
tWidthOpts : Tooltip.Options Msg
tWidthOpts =
    { tD | width = Just "220px" }


{-| An enter transition phase — the tooltip body carries the popover's
`popover-transition-*` class (after the marker and the conditional modifiers).
-}
tTransitionOpts : Tooltip.Options Msg
tTransitionOpts =
    { tD | transition = Just Internal.EnterActive }


{-| The full 15-entry `--n-*` list `NUI.Tooltip.cssVars` must emit against
`Theme.default` (light): the popover's names/order, with `--n-text-color` =
common `baseColor` (`#FFF`) and `--n-color` = the pinned `rgba(38, 38, 38, 1)`.
-}
expectedTooltipLightVars : List ( String, String )
expectedTooltipLightVars =
    [ ( "--n-box-shadow", "0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)" )
    , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-bezier-ease-in", "cubic-bezier(.4, 0, 1, 1)" )
    , ( "--n-bezier-ease-out", "cubic-bezier(0, 0, .2, 1)" )
    , ( "--n-font-size", "14px" )
    , ( "--n-text-color", "#FFF" )
    , ( "--n-color", "rgba(38, 38, 38, 1)" )
    , ( "--n-divider-color", "rgb(239, 239, 245)" )
    , ( "--n-border-radius", "3px" )
    , ( "--n-arrow-height", "6px" )
    , ( "--n-arrow-offset", "10px" )
    , ( "--n-arrow-offset-vertical", "10px" )
    , ( "--n-padding", "8px 14px" )
    , ( "--n-space", "6px" )
    , ( "--n-space-arrow", "10px" )
    ]


{-| The full 15-entry list against `Theme.dark`: `--n-color` = common
`popoverColor` (`rgb(72, 72, 78)`), `--n-text-color` = common `textColor2`
(`rgba(255, 255, 255, 0.82)`), box-shadow/divider from the dark common
(dark tooltip ≡ dark popover).
-}
expectedTooltipDarkVars : List ( String, String )
expectedTooltipDarkVars =
    [ ( "--n-box-shadow", "0 3px 6px -4px rgba(0, 0, 0, .24), 0 6px 12px 0 rgba(0, 0, 0, .16), 0 9px 18px 8px rgba(0, 0, 0, .10)" )
    , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-bezier-ease-in", "cubic-bezier(.4, 0, 1, 1)" )
    , ( "--n-bezier-ease-out", "cubic-bezier(0, 0, .2, 1)" )
    , ( "--n-font-size", "14px" )
    , ( "--n-text-color", "rgba(255, 255, 255, 0.82)" )
    , ( "--n-color", "rgb(72, 72, 78)" )
    , ( "--n-divider-color", "rgba(255, 255, 255, 0.09)" )
    , ( "--n-border-radius", "3px" )
    , ( "--n-arrow-height", "6px" )
    , ( "--n-arrow-offset", "10px" )
    , ( "--n-arrow-offset-vertical", "10px" )
    , ( "--n-padding", "8px 14px" )
    , ( "--n-space", "6px" )
    , ( "--n-space-arrow", "10px" )
    ]


{-| A var list minus the two tooltip-overridden colour keys (the 13 shared).
-}
stripColorVars : List ( String, String ) -> List ( String, String )
stripColorVars =
    List.filter (\( k, _ ) -> k /= "--n-color" && k /= "--n-text-color")


{-| The full 15-entry `--n-*` list `NUI.Popover.cssVars` must emit against
`Theme.default` (light common): names, values, and order (upstream `cssVarsRef`).
-}
expectedPopoverVars : List ( String, String )
expectedPopoverVars =
    [ ( "--n-box-shadow", "0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)" )
    , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-bezier-ease-in", "cubic-bezier(.4, 0, 1, 1)" )
    , ( "--n-bezier-ease-out", "cubic-bezier(0, 0, .2, 1)" )
    , ( "--n-font-size", "14px" )
    , ( "--n-text-color", "rgb(51, 54, 57)" )
    , ( "--n-color", "#fff" )
    , ( "--n-divider-color", "rgb(239, 239, 245)" )
    , ( "--n-border-radius", "3px" )
    , ( "--n-arrow-height", "6px" )
    , ( "--n-arrow-offset", "10px" )
    , ( "--n-arrow-offset-vertical", "10px" )
    , ( "--n-padding", "8px 14px" )
    , ( "--n-space", "6px" )
    , ( "--n-space-arrow", "10px" )
    ]



-- CHECKS -----------------------------------------------------------------------


checks : List Check
checks =
    let
        light =
            Theme.default

        dark =
            Theme.dark

        common =
            light.common

        vLight =
            ButtonTheme.vars light

        vDark =
            ButtonTheme.vars dark

        customPrimary =
            Theme.setPrimary "#ff0000" light

        vCustom =
            ButtonTheme.vars customPrimary

        withFont =
            Theme.withCommon (\c -> { c | fontSize = "99px" }) light

        composed =
            Theme.withCommon (\c -> { c | lineHeight = "2" })
                (Theme.withCommon (\c -> { c | fontSize = "99px" }) light)

        filledPrimary =
            Button.cssVarsFor light primaryOpts

        filledDefault =
            Button.cssVarsFor light Button.defaults

        filledRound =
            Button.cssVarsFor light roundOpts

        filledCircle =
            Button.cssVarsFor light circleOpts

        filledText =
            Button.cssVarsFor light textOpts

        filledTextPrimary =
            Button.cssVarsFor light textPrimaryOpts

        ghostPrimary =
            Button.cssVarsFor light ghostPrimaryOpts

        customVar =
            Button.cssVarsFor light customColorOpts

        strongVar =
            Button.cssVarsFor light strongOpts

        vTagLight =
            TagTheme.vars light

        vTagDark =
            TagTheme.vars dark

        vTagCustom =
            TagTheme.vars customPrimary

        badgeD =
            Badge.defaults

        badgeDefaultVars =
            Badge.cssVarsFor light badgeD

        badgeInfoVars =
            Badge.cssVarsFor light { badgeD | type_ = Badge.Info }

        badgeSuccessVars =
            Badge.cssVarsFor light { badgeD | type_ = Badge.Success }

        badgeWarningVars =
            Badge.cssVarsFor light { badgeD | type_ = Badge.Warning }

        badgeCustomVars =
            Badge.cssVarsFor light { badgeD | color = Just "#ff0000" }

        badgeDarkVars =
            Badge.cssVarsFor dark badgeD

        emptyD =
            Empty.defaults

        emptyDefaultVars =
            Empty.cssVarsFor light emptyD

        emptyHugeVars =
            Empty.cssVarsFor light { emptyD | size = Empty.Huge }

        emptyTinyVars =
            Empty.cssVarsFor light { emptyD | size = Empty.Tiny }

        progD =
            Progress.defaults

        progDefaultVars =
            Progress.cssVarsFor light progD

        progSuccessVars =
            Progress.cssVarsFor light { progD | status = Progress.Success }

        progErrorVars =
            Progress.cssVarsFor light { progD | status = Progress.Error }

        progWarningVars =
            Progress.cssVarsFor light { progD | status = Progress.Warning }

        resultD =
            Result.defaults

        resultDefaultVars =
            Result.cssVarsFor light resultD

        result404Vars =
            Result.cssVarsFor light { resultD | status = Result.Code404 }

        resultSuccessVars =
            Result.cssVarsFor light { resultD | status = Result.Success }

        resultHugeVars =
            Result.cssVarsFor light { resultD | size = Result.Huge }

        resultSmallVars =
            Result.cssVarsFor light { resultD | size = Result.Small }

        skelD =
            Skeleton.defaults

        skelDefaultVars =
            Skeleton.cssVarsFor light skelD

        skelTextVars =
            Skeleton.cssVarsFor light { skelD | text = True, width = Just (Skeleton.Px 120) }

        skelCircleVars =
            Skeleton.cssVarsFor light { skelD | circle = True, width = Just (Skeleton.Px 40) }

        skelRoundVars =
            Skeleton.cssVarsFor light { skelD | round = True }

        skelSoftVars =
            Skeleton.cssVarsFor light { skelD | sharp = False }

        skelStaticVars =
            Skeleton.cssVarsFor light { skelD | animated = False }

        skelSizeVars =
            Skeleton.cssVarsFor light { skelD | size = Just T.Large }

        skelCustomVars =
            Skeleton.cssVarsFor light { skelD | width = Just (Skeleton.Custom "50%") }

        spinD =
            Spin.defaults

        spinDefaultVars =
            Spin.cssVarsFor light spinD

        spinSmallVars =
            Spin.cssVarsFor light { spinD | size = Spin.Small }

        spinLargeVars =
            Spin.cssVarsFor light { spinD | size = Spin.Large }

        spinNumberVars =
            Spin.cssVarsFor light { spinD | size = Spin.Number 24 }

        gtD =
            GradientText.defaults

        gtDefaultVars =
            GradientText.cssVarsFor light gtD

        gtInfoVars =
            GradientText.cssVarsFor light { gtD | type_ = GradientText.Info }

        statD =
            Statistic.defaults

        statDefaultVars =
            Statistic.cssVarsFor light statD

        bcVars =
            Breadcrumb.cssVarsFor light

        tlD =
            Timeline.defaults

        tlItemD =
            Timeline.item

        tlDefaultVars =
            Timeline.cssVarsFor light tlD tlItemD

        tlInfoVars =
            Timeline.cssVarsFor light tlD { tlItemD | type_ = Timeline.Info }

        tlLargeVars =
            Timeline.cssVarsFor light { tlD | size = Timeline.Large } tlItemD

        tlIconSizeVars =
            Timeline.cssVarsFor light { tlD | iconSize = Just 20 } tlItemD

        thingVars =
            Thing.cssVarsFor light

        marqueeVars =
            Marquee.cssVarsFor Marquee.defaults

        marqueePausedVars =
            Marquee.cssVarsFor
                { duration = 2.5, play = False, autoFill = False, repeat = 1, attributes = [] }

        nlistVars =
            NList.cssVarsFor light

        pageHeaderVars =
            PageHeader.cssVarsFor light

        splitVars =
            Split.cssVarsFor light

        stepsD =
            Steps.defaults

        stepsVars =
            Steps.cssVarsFor light stepsD Steps.Process

        stepsFinishVars =
            Steps.cssVarsFor light stepsD Steps.Finish

        stepsSmallVars =
            Steps.cssVarsFor light { stepsD | size = Steps.Small } Steps.Process

        backTopVars =
            BackTop.cssVarsFor light

        qrD =
            QrCode.defaults

        qrVars =
            QrCode.cssVarsFor light qrD

        rateD =
            Rate.defaults

        rateVars =
            Rate.cssVarsFor light rateD

        rateSmallVars =
            Rate.cssVarsFor light { rateD | size = Rate.Small }

        rateLargeVars =
            Rate.cssVarsFor light { rateD | size = Rate.Large }

        rateColorVars =
            Rate.cssVarsFor light { rateD | color = Just "#f0a020" }

        collapseVars =
            Collapse.cssVarsFor light

        floatButtonD =
            FloatButton.defaults

        floatButtonDefaultVars =
            FloatButton.cssVarsFor light floatButtonD

        floatButtonPrimaryVars =
            FloatButton.cssVarsFor light { floatButtonD | type_ = FloatButton.Primary }

        iotD =
            InputOtp.defaults

        iotVars =
            InputOtp.cssVarsFor light iotD

        iotSmallVars =
            InputOtp.cssVarsFor light { iotD | size = InputOtp.Small }

        iotLargeVars =
            InputOtp.cssVarsFor light { iotD | size = InputOtp.Large }

        iotPxVars =
            InputOtp.cssVarsFor light { iotD | gap = Just (InputOtp.Px 16) }

        iotCustomVars =
            InputOtp.cssVarsFor light { iotD | gap = Just (InputOtp.Custom "1rem") }

        iotTheme =
            InputOtpTheme.vars light

        dtVars =
            DynamicTags.cssVarsFor light

        dtTheme =
            DynamicTagsTheme.vars light

        calVars =
            Calendar.cssVarsFor light

        calTheme =
            CalendarTheme.vars light

        calDefaults : Calendar.Options ()
        calDefaults =
            Calendar.defaults

        pgD =
            Pagination.defaults

        pgDefaultVars =
            Pagination.cssVarsFor light pgD

        pgSmallVars =
            Pagination.cssVarsFor light { pgD | size = T.Small }

        pgLargeVars =
            Pagination.cssVarsFor light { pgD | size = T.Large }

        pgTinyVars =
            Pagination.cssVarsFor light { pgD | size = T.Tiny }

        pg1 =
            Pagination.pageItems { currentPage = 1, pageCount = 1, pageSlot = 9, showQuickJumpDropdown = True }

        pg2a =
            Pagination.pageItems { currentPage = 1, pageCount = 2, pageSlot = 9, showQuickJumpDropdown = True }

        pg2b =
            Pagination.pageItems { currentPage = 2, pageCount = 2, pageSlot = 9, showQuickJumpDropdown = True }

        pgMid =
            Pagination.pageItems { currentPage = 6, pageCount = 16, pageSlot = 9, showQuickJumpDropdown = True }

        pgMidNoDrop =
            Pagination.pageItems { currentPage = 6, pageCount = 16, pageSlot = 9, showQuickJumpDropdown = False }

        pgFirst =
            Pagination.pageItems { currentPage = 1, pageCount = 16, pageSlot = 9, showQuickJumpDropdown = True }

        pgLast =
            Pagination.pageItems { currentPage = 16, pageCount = 16, pageSlot = 9, showQuickJumpDropdown = True }

        pgSlot7 =
            Pagination.pageItems { currentPage = 6, pageCount = 16, pageSlot = 7, showQuickJumpDropdown = True }

        pgSlot8 =
            Pagination.pageItems { currentPage = 6, pageCount = 16, pageSlot = 8, showQuickJumpDropdown = True }

        layoutD =
            Layout.defaults

        layoutVars =
            Layout.cssVarsFor light layoutD

        layoutEmbeddedVars =
            Layout.cssVarsFor light { layoutD | embedded = True }

        layoutTheme =
            LayoutTheme.vars light

        siderD =
            LayoutSider.defaults

        siderDefaultVars =
            LayoutSider.cssVarsFor light siderD

        siderInvertedVars =
            LayoutSider.cssVarsFor light { siderD | inverted = True }

        headerD =
            LayoutHeader.defaults

        headerDefaultVars =
            LayoutHeader.cssVarsFor light headerD

        headerInvertedVars =
            LayoutHeader.cssVarsFor light { headerD | inverted = True }

        footerD =
            LayoutFooter.defaults

        footerDefaultVars =
            LayoutFooter.cssVarsFor light footerD

        footerInvertedVars =
            LayoutFooter.cssVarsFor light { footerD | inverted = True }

        inNumDefaults =
            InputNumber.defaults

        inNum5 =
            { inNumDefaults | value = Just 5 }

        inNumMaxed =
            { inNumDefaults | value = Just 10, max = Just 10 }

        inNum1 =
            { inNumDefaults | value = Just 1 }

        inNum1NoLive =
            { inNumDefaults | value = Just 1, updateValueOnInput = False }

        inNum1Prec =
            { inNumDefaults | value = Just 1, precision = Just 2 }

        inNum5Prec2 =
            { inNumDefaults | value = Just 5, precision = Just 2 }

        inNumOverflow =
            { inNumDefaults | value = Just 1.2345, precision = Just 2 }

        inNumMin3 =
            { inNumDefaults | min = Just 3 }

        inNumMinNeg5 =
            { inNumDefaults | min = Just -5 }

        inNumMaxNeg2 =
            { inNumDefaults | max = Just -2 }

        inNumMax5 =
            { inNumDefaults | max = Just 5 }

        nCtxMax =
            { min = Nothing, max = Just 10, step = 1, precision = Nothing, displayedValue = "20" }

        nCtxMin =
            { min = Just 5, max = Nothing, step = 1, precision = Nothing, displayedValue = "1" }

        nCtxPlain =
            { min = Nothing, max = Nothing, step = 1, precision = Nothing, displayedValue = "5" }

        nCtxEmpty =
            { min = Nothing, max = Nothing, step = 1, precision = Nothing, displayedValue = "" }

        nCtxNaN =
            { min = Nothing, max = Nothing, step = 1, precision = Nothing, displayedValue = "abc" }

        nCtxPrec =
            { min = Nothing, max = Nothing, step = 1, precision = Just 2, displayedValue = "1.234" }

        nCtxWip =
            { min = Nothing, max = Nothing, step = 1, precision = Nothing, displayedValue = "0." }

        nCtxStep =
            { min = Nothing, max = Nothing, step = 0.25, precision = Nothing, displayedValue = "1" }

        hlD =
            Highlight.defaults

        naD =
            NumberAnimation.defaults

        iconD =
            Icon.defaults

        iconWrapperD =
            IconWrapper.defaults

        fbGroupD =
            FloatButtonGroup.defaults

        iconDefaultVars =
            Icon.cssVarsFor light iconD

        iconDepthVars =
            Icon.cssVarsFor light { iconD | depth = Just Icon.Depth2 }

        iconDarkVars =
            Icon.cssVarsFor dark { iconD | depth = Just Icon.Depth1 }

        iconWrapperVars =
            IconWrapper.cssVarsFor light

        iconWrapperDarkVars =
            IconWrapper.cssVarsFor dark

        fbGroupVars =
            FloatButtonGroup.cssVarsFor light

        fbGroupDarkVars =
            FloatButtonGroup.cssVarsFor dark

        vIconWrapperLight =
            IconWrapperTheme.vars light

        heatmapColors4 =
            [ "#a", "#b", "#c", "#d" ]

        heatmapLoadNow =
            Time.millisToPosix 1710086400000

        heatmapData =
            [ heatmapItem 19723 (Just 5), heatmapItem 19729 (Just 3) ]

        heatmapNormUtc =
            Heatmap.completeDataGaps Time.utc heatmapData 0 False

        heatmapNormPrev =
            Heatmap.completeDataGaps (Time.customZone -300 []) heatmapData 0 False

        heatmapNormFill =
            Heatmap.completeDataGaps Time.utc heatmapData 0 True

        heatmapNormDup =
            Heatmap.completeDataGaps Time.utc [ heatmapItem 19723 (Just 1), heatmapItem 19723 (Just 2) ] 0 False

        heatmap42Matrix =
            heatmapMatrixOf Time.utc
                1
                heatmapColors4
                1
                (Heatmap.completeDataGaps Time.utc
                    (List.map (\i -> heatmapItem (19723 + i) (Just 1)) (List.range 0 41))
                    1
                    False
                )

        heatmapMonthRow =
            [ heatmapDayRect 19723 (Just 0)
            , heatmapDayRect 19730 (Just 0)
            , heatmapDayRect 19754 (Just 0)
            , heatmapDayRect 19758 (Just 0)
            , heatmapDayRect 19762 (Just 0)
            , heatmapDayRect 19783 (Just 0)
            , heatmapDayRect 19786 (Just 0)
            , heatmapDayRect 19790 (Just 0)
            ]

        heatmapHoleMatrix =
            [ [ Nothing, Nothing, Nothing, Nothing ]
            , [ Just (heatmapDayRect 19723 (Just 0))
              , Just (heatmapDayRect 19730 (Just 0))
              , Just (heatmapDayRect 19737 (Just 0))
              , Just (heatmapDayRect 19754 (Just 0))
              ]
            ]

        heatmapSparse =
            Heatmap.createSparseMatrix 7
                [ { row = 0, col = 0, tag = 1 }
                , { row = 0, col = 2, tag = 2 }
                , { row = 3, col = 1, tag = 3 }
                ]
                .row
                .col
                |> sparseTags

        heatmapSparseDup =
            Heatmap.createSparseMatrix 7
                [ { row = 0, col = 1, tag = 1 }
                , { row = 0, col = 1, tag = 2 }
                ]
                .row
                .col
                |> sparseTags

        heatmapLoading =
            Heatmap.createLoadingMatrix heatmapLoadNow 1

        heatmapRectFeb =
            Heatmap.createDayRect Time.utc
                (heatmapItem 19758 (Just 6))
                (Time.millisToPosix (19751 * 86400000))
                0
                heatmapColors4
                10

        heatmapRectWed =
            Heatmap.createDayRect Time.utc
                (heatmapItem 19753 (Just 0))
                (Time.millisToPosix (19751 * 86400000))
                0
                heatmapColors4
                10

        heatmapVarsSmall =
            Heatmap.cssVarsFor light { heatmapD | size = Heatmap.Small }

        heatmapVarsLarge =
            Heatmap.cssVarsFor light { heatmapD | size = Heatmap.Large }

        heatmapVarsGap =
            Heatmap.cssVarsFor light { heatmapD | xGap = Just 5, yGap = Just 8 }
    in
    [ -- 1. NUI.Theme -------------------------------------------------------------
      eq "Theme.default == Theme.light" True (Theme.default == Theme.light)
    , eq "Theme.dark /= Theme.default" True (Theme.dark /= Theme.default)
    , eq "Theme.default.mode == Light" Theme.Light Theme.default.mode
    , eq "Theme.dark.mode == Dark" Theme.Dark Theme.dark.mode
    , eq "light primaryColor" "#18a058" light.common.primaryColor
    , eq "dark primaryColor" "#63e2b7" dark.common.primaryColor
    , eq "light textColor2" "rgb(51, 54, 57)" light.common.textColor2
    , eq "dark baseColor" "#000" dark.common.baseColor
    , eq "withMode Dark light == dark" True (Theme.withMode Theme.Dark light == dark)
    , eq "withMode Light dark == light" True (Theme.withMode Theme.Light dark == light)
    , eq "setPrimary overrides primaryColor" "#ff0000" customPrimary.common.primaryColor
    , eq "setPrimary derives Hover" (Color.createHoverColor "#ff0000") customPrimary.common.primaryColorHover
    , eq "setPrimary derives Pressed" (Color.createPressedColor "#ff0000") customPrimary.common.primaryColorPressed
    , eq "setPrimary Suppl == Hover" customPrimary.common.primaryColorHover customPrimary.common.primaryColorSuppl
    , eq "setPrimary keeps mode" Theme.Light customPrimary.mode
    , eq "setPrimary keeps fontSize" light.common.fontSize customPrimary.common.fontSize
    , eq "withCommon applies f" "99px" withFont.common.fontSize
    , eq "withCommon keeps primaryColor" "#18a058" withFont.common.primaryColor
    , eq "withCommon keeps mode" Theme.Light withFont.mode
    , eq "withCommon composes (fontSize)" "99px" composed.common.fontSize
    , eq "withCommon composes (lineHeight)" "2" composed.common.lineHeight

    -- 2. NUI.Theme.Color (values from seemly / Naive UI) -------------------------
    , eq "createHoverColor #666666" "rgba(126, 126, 126, 1)" (Color.createHoverColor "#666666")
    , eq "createHoverColor rgb(42, 148, 125)" "rgba(76, 165, 146, 1)" (Color.createHoverColor "rgb(42, 148, 125)")
    , eq "createPressedColor #666666" "rgba(90, 90, 90, 1)" (Color.createPressedColor "#666666")
    , eq "createPressedColor rgb(42, 148, 125)" "rgba(37, 130, 110, 1)" (Color.createPressedColor "rgb(42, 148, 125)")
    , eq "parse #0f0" (Just { r = 0, g = 255, b = 0, a = 1 }) (Color.parse "#0f0")
    , eq "parse #ff8800" (Just { r = 255, g = 136, b = 0, a = 1 }) (Color.parse "#ff8800")
    , eq "parse #ABC is case-insensitive" (Just { r = 170, g = 187, b = 204, a = 1 }) (Color.parse "#ABC")
    , eq "parse rgb(42, 148, 125)" (Just { r = 42, g = 148, b = 125, a = 1 }) (Color.parse "rgb(42, 148, 125)")
    , eq "parse rgba(1, 2, 3, 0.5)" (Just { r = 1, g = 2, b = 3, a = 0.5 }) (Color.parse "rgba(1, 2, 3, 0.5)")
    , eq "parse invalid -> Nothing" Nothing (Color.parse "not-a-color")
    , eq "parse #zzz -> Nothing" Nothing (Color.parse "#zzz")
    , eq "changeColor #666666 0.5" "rgba(102, 102, 102, 0.5)" (Color.changeColor "#666666" 0.5)
    , eq "changeColor rgb(42, 148, 125) 0.5" "rgba(42, 148, 125, 0.5)" (Color.changeColor "rgb(42, 148, 125)" 0.5)
    , eq "changeColor invalid falls back" "bogus" (Color.changeColor "bogus" 0.5)
    , eq "composite: transparent overlay = base" { r = 102, g = 102, b = 102, a = 1 } (Color.composite { r = 102, g = 102, b = 102, a = 1 } { r = 0, g = 0, b = 0, a = 0 })
    , eq "composite: opaque overlay = overlay" { r = 1, g = 2, b = 3, a = 1 } (Color.composite { r = 102, g = 102, b = 102, a = 1 } { r = 1, g = 2, b = 3, a = 1 })

    -- 3. NUI.Internal (pure parts; cssVars drop + classes are checked in the DOM) --
    , eq "Internal.classIf True" [ "yes" ] (Internal.classIf True "yes")
    , eq "Internal.classIf False" [] (Internal.classIf False "no")

    -- 4. NUI.Theme.Button.vars --------------------------------------------------
    , eq "vars(light).heightMedium" "34px" vLight.heightMedium
    , eq "vars(light).paddingMedium" "0 14px" vLight.paddingMedium
    , eq "vars(light).fontSizeMedium" "14px" vLight.fontSizeMedium
    , eq "vars(light).borderRadiusMedium" "3px" vLight.borderRadiusMedium
    , eq "vars(light).color" "#0000" vLight.color
    , eq "vars(light).waveOpacity" "0.6" vLight.waveOpacity
    , eq "vars(dark).waveOpacity" "0.8" vDark.waveOpacity
    , eq "vars(light) == vars(default)" True (vLight == ButtonTheme.vars light)
    , eq "vars(dark) /= vars(light)" True (vDark /= vLight)
    , eq "vars(light).heightTiny" "22px" vLight.heightTiny
    , eq "vars(light).fontSizeTiny == fontSizeMini" "12px" vLight.fontSizeTiny
    , eq "vars(light).iconSizeSmall" "18px" vLight.iconSizeSmall
    , eq "vars(light).textColorGhostPrimary" "#18a058" vLight.textColorGhostPrimary
    , eq "vars(setPrimary #ff0000).textColorGhostPrimary" "#ff0000" vCustom.textColorGhostPrimary
    , eq "vars(setPrimary).textColorGhostHoverPrimary tracks primary" customPrimary.common.primaryColorHover vCustom.textColorGhostHoverPrimary

    -- 5. NUI.Button cssVarsFor ---------------------------------------------------
    , eq "cssVarsFor primary --n-color = primary" (Just "#18a058") (lookup "--n-color" filledPrimary)
    , eq "cssVarsFor primary --n-text-color" (Just "#FFF") (lookup "--n-text-color" filledPrimary)
    , eq "cssVarsFor primary --n-color-disabled = primary" (Just "#18a058") (lookup "--n-color-disabled" filledPrimary)
    , eq "cssVarsFor default --n-color" (Just "#0000") (lookup "--n-color" filledDefault)
    , eq "cssVarsFor round --n-border-radius == height" (lookup "--n-height" filledRound) (lookup "--n-border-radius" filledRound)
    , eq "cssVarsFor round --n-border-radius" (Just "34px") (lookup "--n-border-radius" filledRound)
    , eq "cssVarsFor circle --n-width == height" (Just "34px") (lookup "--n-width" filledCircle)
    , eq "cssVarsFor --n-opacity-disabled" (Just "0.5") (lookup "--n-opacity-disabled" filledDefault)
    , eq "cssVarsFor text --n-color" (Just "#0000") (lookup "--n-color" filledText)
    , eq "cssVarsFor text --n-border" (Just "none") (lookup "--n-border" filledText)
    , eq "cssVarsFor text --n-height (unset)" (Just "initial") (lookup "--n-height" filledText)
    , eq "cssVarsFor text primary --n-text-color" (Just "#18a058") (lookup "--n-text-color" filledTextPrimary)
    , eq "cssVarsFor ghost primary --n-text-color" (Just "#18a058") (lookup "--n-text-color" ghostPrimary)
    , eq "cssVarsFor custom color --n-color" (Just "#ff0000") (lookup "--n-color" customVar)
    , eq "cssVarsFor custom color --n-color-hover = createHoverColor" (Just (Color.createHoverColor "#ff0000")) (lookup "--n-color-hover" customVar)
    , eq "cssVarsFor strong --n-font-weight" (Just "500") (lookup "--n-font-weight" strongVar)
    , eq "cssVarsFor default --n-font-weight" (Just "400") (lookup "--n-font-weight" filledDefault)
    , eq "cssVarsFor --n-bezier = common.cubicBezierEaseInOut" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" filledDefault)
    , eq "cssVarsFor starts with --n-bezier" (Just "--n-bezier") (List.head filledPrimary |> Maybe.map Tuple.first)

    -- 6. NUI.Theme.Tag.vars -----------------------------------------------------
    , eq "tag vars(light).heightMedium == common.heightSmall" common.heightSmall vTagLight.heightMedium
    , eq "tag vars(light).heightSmall == common.heightTiny" common.heightTiny vTagLight.heightSmall
    , eq "tag vars(light).heightTiny == common.fontSizeHuge" common.fontSizeHuge vTagLight.heightTiny
    , eq "tag vars(light).heightLarge == common.heightMedium" common.heightMedium vTagLight.heightLarge
    , eq "tag vars(light).padding" "0 7px" vTagLight.padding
    , eq "tag vars(light).closeMargin" "0 0 0 4px" vTagLight.closeMargin
    , eq "tag vars(light).closeSizeMedium" "18px" vTagLight.closeSizeMedium
    , eq "tag vars(light).borderRadius == common.borderRadiusSmall" common.borderRadiusSmall vTagLight.borderRadius
    , eq "tag vars(light).opacityDisabled == common.opacityDisabled" common.opacityDisabled vTagLight.opacityDisabled
    , eq "tag vars(light).fontWeightStrong == common.fontWeightStrong" common.fontWeightStrong vTagLight.fontWeightStrong
    , eq "tag vars(light).border" "1px solid rgb(224, 224, 230)" vTagLight.border
    , eq "tag vars(light).colorBordered" "rgb(250, 250, 252)" vTagLight.colorBordered
    , eq "tag vars(light).colorPrimary" "rgba(24, 160, 88, 0.12)" vTagLight.colorPrimary
    , eq "tag vars(light).colorBorderedPrimary" "rgba(24, 160, 88, 0.1)" vTagLight.colorBorderedPrimary
    , eq "tag vars(light).textColorPrimary == common.primaryColor" common.primaryColor vTagLight.textColorPrimary
    , eq "tag vars(light).closeIconColorPrimary" "#18a058" vTagLight.closeIconColorPrimary
    , eq "tag vars(light).colorChecked == common.primaryColor" common.primaryColor vTagLight.colorChecked
    , eq "tag vars(dark) /= vars(light)" True (vTagDark /= vTagLight)
    , eq "tag vars(setPrimary).colorChecked tracks primary" "#ff0000" vTagCustom.colorChecked
    , eq "tag vars(setPrimary).colorCheckedHover == createHoverColor" (Color.createHoverColor "#ff0000") vTagCustom.colorCheckedHover
    , eq "tag vars(setPrimary) keeps padding" "0 7px" vTagCustom.padding

    -- 7. NUI.Css.css -------------------------------------------------------------
    , eq "css contains .n-button" True (String.contains ".n-button" Css.css)
    , eq "css is scoped under .nui-root.nui-root" True (String.contains ".nui-root.nui-root" Css.css)
    , eq "css contains flex-basis bridge" True (String.contains "flex-basis: auto" Css.css)
    , eq "css contains .n-text" True (String.contains ".n-text" Css.css)
    , eq "css contains button wave keyframes" True (String.contains "button-wave-spread" Css.css)
    , eq "css is non-trivial (>50k)" True (String.length Css.css > 50000)

    -- 8. NUI.Badge cssVarsFor ---------------------------------------------------
    , eq "badge cssVarsFor has 6 vars" 6 (List.length badgeDefaultVars)
    , eq "badge cssVarsFor exact --n-* names"
        [ "--n-font-size", "--n-font-family", "--n-color", "--n-ripple-color", "--n-bezier", "--n-ripple-bezier" ]
        (varKeys badgeDefaultVars)
    , eq "badge cssVarsFor starts with --n-font-size" (Just "--n-font-size") (List.head badgeDefaultVars |> Maybe.map Tuple.first)
    , eq "badge cssVarsFor --n-font-size" (Just common.fontSizeMini) (lookup "--n-font-size" badgeDefaultVars)
    , eq "badge cssVarsFor --n-font-family" (Just common.fontFamily) (lookup "--n-font-family" badgeDefaultVars)
    , eq "badge cssVarsFor --n-color (Default = error colour)" (Just "#d03050") (lookup "--n-color" badgeDefaultVars)
    , eq "badge cssVarsFor --n-ripple-color == --n-color" (lookup "--n-color" badgeDefaultVars) (lookup "--n-ripple-color" badgeDefaultVars)
    , eq "badge cssVarsFor --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" badgeDefaultVars)
    , eq "badge cssVarsFor --n-ripple-bezier = easeOut" (Just common.cubicBezierEaseOut) (lookup "--n-ripple-bezier" badgeDefaultVars)
    , eq "badge cssVarsFor Info --n-color" (Just "#2080f0") (lookup "--n-color" badgeInfoVars)
    , eq "badge cssVarsFor Success --n-color" (Just "#18a058") (lookup "--n-color" badgeSuccessVars)
    , eq "badge cssVarsFor Warning --n-color" (Just "#f0a020") (lookup "--n-color" badgeWarningVars)
    , eq "badge cssVarsFor custom color --n-color" (Just "#ff0000") (lookup "--n-color" badgeCustomVars)
    , eq "badge cssVarsFor custom color --n-ripple-color" (Just "#ff0000") (lookup "--n-ripple-color" badgeCustomVars)
    , eq "badge cssVarsFor dark --n-color" (Just "rgb(208, 58, 82)") (lookup "--n-color" badgeDarkVars)

    -- 9. NUI.Empty cssVarsFor ---------------------------------------------------
    , eq "empty cssVarsFor has 6 vars" 6 (List.length emptyDefaultVars)
    , eq "empty cssVarsFor exact --n-* names"
        [ "--n-icon-size", "--n-font-size", "--n-bezier", "--n-text-color", "--n-icon-color", "--n-extra-text-color" ]
        (varKeys emptyDefaultVars)
    , eq "empty cssVarsFor --n-icon-size (Medium)" (Just common.heightLarge) (lookup "--n-icon-size" emptyDefaultVars)
    , eq "empty cssVarsFor --n-font-size (Medium)" (Just common.fontSize) (lookup "--n-font-size" emptyDefaultVars)
    , eq "empty cssVarsFor --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" emptyDefaultVars)
    , eq "empty cssVarsFor --n-text-color" (Just common.textColorDisabled) (lookup "--n-text-color" emptyDefaultVars)
    , eq "empty cssVarsFor --n-icon-color" (Just common.textColorDisabled) (lookup "--n-icon-color" emptyDefaultVars)
    , eq "empty cssVarsFor --n-extra-text-color" (Just common.textColor2) (lookup "--n-extra-text-color" emptyDefaultVars)
    , eq "empty cssVarsFor Huge --n-icon-size" (Just "52px") (lookup "--n-icon-size" emptyHugeVars)
    , eq "empty cssVarsFor Huge --n-font-size" (Just common.fontSizeHuge) (lookup "--n-font-size" emptyHugeVars)
    , eq "empty cssVarsFor Tiny --n-icon-size" (Just common.heightSmall) (lookup "--n-icon-size" emptyTinyVars)

    -- 10. NUI.Progress cssVarsFor -----------------------------------------------
    , eq "progress cssVarsFor has 14 vars" 14 (List.length progDefaultVars)
    , eq "progress cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-fill-color"
        , "--n-font-size"
        , "--n-font-size-circle"
        , "--n-font-weight-circle"
        , "--n-icon-color"
        , "--n-icon-size-circle"
        , "--n-icon-size-line"
        , "--n-line-bg-processing"
        , "--n-rail-color"
        , "--n-rail-height"
        , "--n-text-color-circle"
        , "--n-text-color-line-inner"
        , "--n-text-color-line-outer"
        ]
        (varKeys progDefaultVars)
    , eq "progress cssVarsFor --n-fill-color (Default = info)" (Just common.infoColor) (lookup "--n-fill-color" progDefaultVars)
    , eq "progress cssVarsFor --n-icon-color (Default = info)" (Just common.infoColor) (lookup "--n-icon-color" progDefaultVars)
    , eq "progress cssVarsFor --n-rail-color" (Just common.progressRailColor) (lookup "--n-rail-color" progDefaultVars)
    , eq "progress cssVarsFor --n-rail-height" (Just "8px") (lookup "--n-rail-height" progDefaultVars)
    , eq "progress cssVarsFor --n-icon-size-line" (Just "18px") (lookup "--n-icon-size-line" progDefaultVars)
    , eq "progress cssVarsFor --n-icon-size-circle" (Just "36px") (lookup "--n-icon-size-circle" progDefaultVars)
    , eq "progress cssVarsFor --n-text-color-line-inner" (Just "rgb(255, 255, 255)") (lookup "--n-text-color-line-inner" progDefaultVars)
    , eq "progress cssVarsFor --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" progDefaultVars)
    , eq "progress cssVarsFor Success --n-fill-color" (Just common.primaryColor) (lookup "--n-fill-color" progSuccessVars)
    , eq "progress cssVarsFor Success --n-icon-color" (Just common.primaryColor) (lookup "--n-icon-color" progSuccessVars)
    , eq "progress cssVarsFor Error --n-fill-color" (Just common.errorColor) (lookup "--n-fill-color" progErrorVars)
    , eq "progress cssVarsFor Warning --n-fill-color" (Just common.warningColor) (lookup "--n-fill-color" progWarningVars)
    , eq "progress multiple-circle cssVarsFor has 14 vars" 14 (List.length (Progress.cssVarsFor light { progD | type_ = Progress.MultipleCircle }))

    -- 11. NUI.Result cssVarsFor -------------------------------------------------
    , eq "result cssVarsFor has 9 vars" 9 (List.length resultDefaultVars)
    , eq "result cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-font-size"
        , "--n-icon-size"
        , "--n-line-height"
        , "--n-text-color"
        , "--n-title-font-size"
        , "--n-title-font-weight"
        , "--n-title-text-color"
        , "--n-icon-color"
        ]
        (varKeys resultDefaultVars)
    , eq "result cssVarsFor --n-font-size (Medium)" (Just common.fontSize) (lookup "--n-font-size" resultDefaultVars)
    , eq "result cssVarsFor --n-icon-size (Medium)" (Just "80px") (lookup "--n-icon-size" resultDefaultVars)
    , eq "result cssVarsFor --n-title-font-size (Medium)" (Just "32px") (lookup "--n-title-font-size" resultDefaultVars)
    , eq "result cssVarsFor --n-title-font-weight" (Just common.fontWeightStrong) (lookup "--n-title-font-weight" resultDefaultVars)
    , eq "result cssVarsFor --n-text-color" (Just common.textColor2) (lookup "--n-text-color" resultDefaultVars)
    , eq "result cssVarsFor --n-title-text-color" (Just common.textColor1) (lookup "--n-title-text-color" resultDefaultVars)
    , eq "result cssVarsFor --n-line-height" (Just common.lineHeight) (lookup "--n-line-height" resultDefaultVars)
    , eq "result cssVarsFor Info --n-icon-color" (Just common.infoColor) (lookup "--n-icon-color" resultDefaultVars)
    , eq "result cssVarsFor Code404 --n-icon-color is empty" (Just "") (lookup "--n-icon-color" result404Vars)
    , eq "result cssVarsFor Success --n-icon-color" (Just common.primaryColor) (lookup "--n-icon-color" resultSuccessVars)
    , eq "result cssVarsFor Huge --n-icon-size" (Just "125px") (lookup "--n-icon-size" resultHugeVars)
    , eq "result cssVarsFor Huge --n-title-font-size" (Just "48px") (lookup "--n-title-font-size" resultHugeVars)
    , eq "result cssVarsFor Small --n-title-font-size" (Just "26px") (lookup "--n-title-font-size" resultSmallVars)

    -- 12. NUI.Skeleton cssVarsFor (the single inline style block) --------------
    , eq "skeleton cssVarsFor has 9 entries" 9 (List.length skelDefaultVars)
    , eq "skeleton cssVarsFor exact inline style keys"
        [ "display", "vertical-align", "border-radius", "width", "height", "animation", "--n-bezier", "--n-color-start", "--n-color-end" ]
        (varKeys skelDefaultVars)
    , eq "skeleton starts with display (plain prop first)" (Just "display") (List.head skelDefaultVars |> Maybe.map Tuple.first)
    , eq "skeleton defaults display unset" (Just "") (lookup "display" skelDefaultVars)
    , eq "skeleton defaults border-radius unset (sharp)" (Just "") (lookup "border-radius" skelDefaultVars)
    , eq "skeleton defaults --n-color-start" (Just "#eee") (lookup "--n-color-start" skelDefaultVars)
    , eq "skeleton defaults --n-color-end" (Just "#ddd") (lookup "--n-color-end" skelDefaultVars)
    , eq "skeleton defaults --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" skelDefaultVars)
    , eq "skeleton text display = inline-block" (Just "inline-block") (lookup "display" skelTextVars)
    , eq "skeleton text vertical-align = -0.125em" (Just "-0.125em") (lookup "vertical-align" skelTextVars)
    , eq "skeleton text width = 120px" (Just "120px") (lookup "width" skelTextVars)
    , eq "skeleton circle border-radius = 50%" (Just "50%") (lookup "border-radius" skelCircleVars)
    , eq "skeleton circle width == height" (lookup "width" skelCircleVars) (lookup "height" skelCircleVars)
    , eq "skeleton circle width = 40px" (Just "40px") (lookup "width" skelCircleVars)
    , eq "skeleton round border-radius = 4096px" (Just "4096px") (lookup "border-radius" skelRoundVars)
    , eq "skeleton not sharp uses theme radius" (Just common.borderRadius) (lookup "border-radius" skelSoftVars)
    , eq "skeleton not animated animation = none" (Just "none") (lookup "animation" skelStaticVars)
    , eq "skeleton size Large height = heightLarge" (Just common.heightLarge) (lookup "height" skelSizeVars)
    , eq "skeleton custom width passes through" (Just "50%") (lookup "width" skelCustomVars)

    -- 13. NUI.Spin cssVarsFor ---------------------------------------------------
    , eq "spin cssVarsFor has 6 vars" 6 (List.length spinDefaultVars)
    , eq "spin cssVarsFor exact --n-* names"
        [ "--n-bezier", "--n-opacity-spinning", "--n-size", "--n-color", "--n-text-color", "--n-font-size" ]
        (varKeys spinDefaultVars)
    , eq "spin cssVarsFor --n-size (Medium)" (Just common.heightMedium) (lookup "--n-size" spinDefaultVars)
    , eq "spin cssVarsFor --n-color = primary" (Just common.primaryColor) (lookup "--n-color" spinDefaultVars)
    , eq "spin cssVarsFor --n-text-color = primary" (Just common.primaryColor) (lookup "--n-text-color" spinDefaultVars)
    , eq "spin cssVarsFor --n-opacity-spinning" (Just common.opacityDisabled) (lookup "--n-opacity-spinning" spinDefaultVars)
    , eq "spin cssVarsFor --n-font-size" (Just common.fontSize) (lookup "--n-font-size" spinDefaultVars)
    , eq "spin cssVarsFor --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" spinDefaultVars)
    , eq "spin cssVarsFor Small --n-size" (Just common.heightSmall) (lookup "--n-size" spinSmallVars)
    , eq "spin cssVarsFor Large --n-size" (Just common.heightLarge) (lookup "--n-size" spinLargeVars)
    , eq "spin cssVarsFor Number 24 --n-size" (Just "24px") (lookup "--n-size" spinNumberVars)

    -- 14. NUI.GradientText cssVarsFor ------------------------------------------
    , eq "gradient-text cssVarsFor has 5 vars" 5 (List.length gtDefaultVars)
    , eq "gradient-text cssVarsFor exact --n-* names"
        [ "--n-bezier", "--n-rotate", "--n-color-start", "--n-color-end", "--n-font-weight" ]
        (varKeys gtDefaultVars)
    , eq "gradient-text default --n-color-start (primary 60%)" (Just "rgba(24, 160, 88, 0.6)") (lookup "--n-color-start" gtDefaultVars)
    , eq "gradient-text default --n-color-end (primary)" (Just "#18a058") (lookup "--n-color-end" gtDefaultVars)
    , eq "gradient-text --n-rotate" (Just "252deg") (lookup "--n-rotate" gtDefaultVars)
    , eq "gradient-text --n-font-weight = strong" (Just common.fontWeightStrong) (lookup "--n-font-weight" gtDefaultVars)
    , eq "gradient-text --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" gtDefaultVars)
    , eq "gradient-text Info --n-color-start" (Just "rgba(32, 128, 240, 0.6)") (lookup "--n-color-start" gtInfoVars)
    , eq "gradient-text Info --n-color-end" (Just "#2080f0") (lookup "--n-color-end" gtInfoVars)

    -- 15. NUI.Statistic cssVarsFor ----------------------------------------------
    , eq "statistic cssVarsFor has 9 vars" 9 (List.length statDefaultVars)
    , eq "statistic cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-label-font-size"
        , "--n-label-font-weight"
        , "--n-label-text-color"
        , "--n-value-font-weight"
        , "--n-value-font-size"
        , "--n-value-prefix-text-color"
        , "--n-value-suffix-text-color"
        , "--n-value-text-color"
        ]
        (varKeys statDefaultVars)
    , eq "statistic --n-label-font-size" (Just common.fontSize) (lookup "--n-label-font-size" statDefaultVars)
    , eq "statistic --n-value-font-size" (Just "24px") (lookup "--n-value-font-size" statDefaultVars)
    , eq "statistic --n-label-text-color" (Just common.textColor3) (lookup "--n-label-text-color" statDefaultVars)
    , eq "statistic --n-value-text-color" (Just common.textColor2) (lookup "--n-value-text-color" statDefaultVars)
    , eq "statistic --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" statDefaultVars)

    -- 16. NUI.Breadcrumb cssVarsFor ---------------------------------------------
    , eq "breadcrumb cssVarsFor has 12 vars" 12 (List.length bcVars)
    , eq "breadcrumb cssVarsFor exact --n-* names"
        [ "--n-font-size"
        , "--n-bezier"
        , "--n-item-text-color"
        , "--n-item-text-color-hover"
        , "--n-item-text-color-pressed"
        , "--n-item-text-color-active"
        , "--n-separator-color"
        , "--n-item-color-hover"
        , "--n-item-color-pressed"
        , "--n-item-border-radius"
        , "--n-font-weight-active"
        , "--n-item-line-height"
        ]
        (varKeys bcVars)
    , eq "breadcrumb --n-item-text-color" (Just common.textColor3) (lookup "--n-item-text-color" bcVars)
    , eq "breadcrumb --n-item-text-color-active" (Just common.textColor2) (lookup "--n-item-text-color-active" bcVars)
    , eq "breadcrumb --n-font-weight-active" (Just "400") (lookup "--n-font-weight-active" bcVars)
    , eq "breadcrumb --n-item-line-height" (Just "1.25") (lookup "--n-item-line-height" bcVars)
    , eq "breadcrumb --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" bcVars)

    -- 17. NUI.Timeline cssVarsFor -----------------------------------------------
    , eq "timeline cssVarsFor has 12 vars" 12 (List.length tlDefaultVars)
    , eq "timeline cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-circle-border"
        , "--n-icon-color"
        , "--n-content-font-size"
        , "--n-content-text-color"
        , "--n-line-color"
        , "--n-meta-text-color"
        , "--n-title-font-size"
        , "--n-title-font-weight"
        , "--n-title-margin"
        , "--n-title-text-color"
        , "--n-icon-size"
        ]
        (varKeys tlDefaultVars)
    , eq "timeline --n-circle-border (default)" (Just "2px solid rgb(118, 124, 130)") (lookup "--n-circle-border" tlDefaultVars)
    , eq "timeline Info --n-circle-border" (Just "2px solid #2080f0") (lookup "--n-circle-border" tlInfoVars)
    , eq "timeline Info --n-icon-color" (Just "#2080f0") (lookup "--n-icon-color" tlInfoVars)
    , eq "timeline --n-title-font-size (medium)" (Just common.fontSize) (lookup "--n-title-font-size" tlDefaultVars)
    , eq "timeline Large --n-title-font-size" (Just common.fontSizeHuge) (lookup "--n-title-font-size" tlLargeVars)
    , eq "timeline --n-icon-size (medium)" (Just common.fontSize) (lookup "--n-icon-size" tlDefaultVars)
    , eq "timeline iconSize 20 -> 20px" (Just "20px") (lookup "--n-icon-size" tlIconSizeVars)
    , eq "timeline --n-title-margin (medium)" (Just "0 0 6px 0") (lookup "--n-title-margin" tlDefaultVars)
    , eq "timeline --n-line-color = railColor" (Just common.railColor) (lookup "--n-line-color" tlDefaultVars)

    -- 18. NUI.Thing cssVarsFor --------------------------------------------------
    , eq "thing cssVarsFor has 5 vars" 5 (List.length thingVars)
    , eq "thing cssVarsFor exact --n-* names"
        [ "--n-bezier", "--n-font-size", "--n-text-color", "--n-title-font-weight", "--n-title-text-color" ]
        (varKeys thingVars)
    , eq "thing --n-font-size" (Just common.fontSize) (lookup "--n-font-size" thingVars)
    , eq "thing --n-text-color" (Just common.textColor2) (lookup "--n-text-color" thingVars)
    , eq "thing --n-title-text-color" (Just common.textColor1) (lookup "--n-title-text-color" thingVars)
    , eq "thing --n-title-font-weight" (Just common.fontWeightStrong) (lookup "--n-title-font-weight" thingVars)

    -- 19. NUI.Marquee cssVarsFor ------------------------------------------------
    , eq "marquee cssVarsFor has 6 vars" 6 (List.length marqueeVars)
    , eq "marquee cssVarsFor exact --n-* names"
        [ "--n-play", "--n-direction", "--n-duration", "--n-delay", "--n-iteration-count", "--n-min-width" ]
        (varKeys marqueeVars)
    , eq "marquee --n-play default = running" (Just "running") (lookup "--n-play" marqueeVars)
    , eq "marquee --n-duration default = 0s" (Just "0s") (lookup "--n-duration" marqueeVars)
    , eq "marquee --n-iteration-count" (Just "infinite") (lookup "--n-iteration-count" marqueeVars)
    , eq "marquee --n-play paused" (Just "paused") (lookup "--n-play" marqueePausedVars)
    , eq "marquee --n-duration 2.5 -> 2.5s" (Just "2.5s") (lookup "--n-duration" marqueePausedVars)

    -- 20. NUI.List cssVarsFor ----------------------------------------------------
    , eq "list cssVarsFor has 13 vars" 13 (List.length nlistVars)
    , eq "list cssVarsFor exact --n-* names"
        [ "--n-font-size"
        , "--n-bezier"
        , "--n-text-color"
        , "--n-color"
        , "--n-border-radius"
        , "--n-border-color"
        , "--n-border-color-modal"
        , "--n-border-color-popover"
        , "--n-color-modal"
        , "--n-color-popover"
        , "--n-color-hover"
        , "--n-color-hover-modal"
        , "--n-color-hover-popover"
        ]
        (varKeys nlistVars)
    , eq "list --n-text-color" (Just common.textColor2) (lookup "--n-text-color" nlistVars)
    , eq "list --n-color" (Just common.tableColor) (lookup "--n-color" nlistVars)
    , eq "list --n-color-hover-modal" (Just "rgba(243, 243, 245, 1)") (lookup "--n-color-hover-modal" nlistVars)

    -- 21. NUI.PageHeader cssVarsFor ----------------------------------------------
    , eq "page-header cssVarsFor has 10 vars" 10 (List.length pageHeaderVars)
    , eq "page-header cssVarsFor exact --n-* names"
        [ "--n-title-text-color"
        , "--n-title-font-size"
        , "--n-title-font-weight"
        , "--n-font-size"
        , "--n-back-size"
        , "--n-subtitle-text-color"
        , "--n-back-color"
        , "--n-back-color-hover"
        , "--n-back-color-pressed"
        , "--n-bezier"
        ]
        (varKeys pageHeaderVars)
    , eq "page-header --n-title-font-size" (Just "18px") (lookup "--n-title-font-size" pageHeaderVars)
    , eq "page-header --n-back-size" (Just common.heightTiny) (lookup "--n-back-size" pageHeaderVars)
    , eq "page-header --n-back-color" (Just common.textColor2) (lookup "--n-back-color" pageHeaderVars)
    , eq "page-header --n-back-color-hover" (Just common.primaryColorHover) (lookup "--n-back-color-hover" pageHeaderVars)

    -- 22. NUI.Split cssVarsFor -------------------------------------------------
    , eq "split cssVarsFor has 3 vars" 3 (List.length splitVars)
    , eq "split cssVarsFor exact --n-* names"
        [ "--n-bezier", "--n-resize-trigger-color", "--n-resize-trigger-color-hover" ]
        (varKeys splitVars)
    , eq "split --n-resize-trigger-color = borderColor" (Just common.borderColor) (lookup "--n-resize-trigger-color" splitVars)
    , eq "split --n-resize-trigger-color-hover = primaryColorHover" (Just common.primaryColorHover) (lookup "--n-resize-trigger-color-hover" splitVars)

    -- 23. NUI.Steps cssVarsFor --------------------------------------------------
    , eq "steps cssVarsFor has 12 vars" 12 (List.length stepsVars)
    , eq "steps cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-description-text-color"
        , "--n-header-text-color"
        , "--n-indicator-border-color"
        , "--n-indicator-color"
        , "--n-indicator-icon-size"
        , "--n-indicator-index-font-size"
        , "--n-indicator-size"
        , "--n-indicator-text-color"
        , "--n-splitor-color"
        , "--n-step-header-font-size"
        , "--n-step-header-font-weight"
        ]
        (varKeys stepsVars)
    , eq "steps --n-indicator-size (medium)" (Just common.heightSmall) (lookup "--n-indicator-size" stepsVars)
    , eq "steps --n-step-header-font-size (medium)" (Just common.fontSizeHuge) (lookup "--n-step-header-font-size" stepsVars)
    , eq "steps Small --n-indicator-size" (Just common.heightTiny) (lookup "--n-indicator-size" stepsSmallVars)
    , eq "steps Small --n-step-header-font-size" (Just common.fontSize) (lookup "--n-step-header-font-size" stepsSmallVars)
    , eq "steps Process --n-indicator-color = primary" (Just common.primaryColor) (lookup "--n-indicator-color" stepsVars)
    , eq "steps Finish --n-indicator-color = transparent" (Just "#0000") (lookup "--n-indicator-color" stepsFinishVars)
    , eq "steps Process --n-header-text-color = textColor1" (Just common.textColor1) (lookup "--n-header-text-color" stepsVars)
    , eq "steps Finish --n-header-text-color = textColorDisabled" (Just common.textColorDisabled) (lookup "--n-header-text-color" stepsFinishVars)

    -- 24. NUI.BackTop cssVarsFor ------------------------------------------------
    , eq "back-top cssVarsFor has 13 vars" 13 (List.length backTopVars)
    , eq "back-top cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-border-radius"
        , "--n-height"
        , "--n-width"
        , "--n-box-shadow"
        , "--n-box-shadow-hover"
        , "--n-box-shadow-pressed"
        , "--n-color"
        , "--n-icon-size"
        , "--n-icon-color"
        , "--n-icon-color-hover"
        , "--n-icon-color-pressed"
        , "--n-text-color"
        ]
        (varKeys backTopVars)
    , eq "back-top --n-border-radius = common.heightTiny" (Just common.heightTiny) (lookup "--n-border-radius" backTopVars)
    , eq "back-top --n-height" (Just "44px") (lookup "--n-height" backTopVars)
    , eq "back-top --n-icon-size" (Just "26px") (lookup "--n-icon-size" backTopVars)
    , eq "back-top --n-color = common.popoverColor" (Just common.popoverColor) (lookup "--n-color" backTopVars)
    , eq "back-top --n-icon-color-hover = primaryColorHover" (Just common.primaryColorHover) (lookup "--n-icon-color-hover" backTopVars)

    -- 25. NUI.QrCode cssVarsFor -------------------------------------------------
    , eq "qr-code cssVarsFor exact order"
        [ ( "padding", "12px" )
        , ( "background-color", "#FFF" )
        , ( "width", "100px" )
        , ( "height", "100px" )
        , ( "--n-border-radius", common.borderRadius )
        ]
        qrVars
    , eq "qr-code Px 8 padding" (Just "8px") (lookup "padding" (QrCode.cssVarsFor light { qrD | padding = QrCode.Px 8 }))
    , eq "qr-code Custom padding passes through" (Just "4px 8px") (lookup "padding" (QrCode.cssVarsFor light { qrD | padding = QrCode.Custom "4px 8px" }))
    , eq "qr-code size 140 sets width" (Just "140px") (lookup "width" (QrCode.cssVarsFor light { qrD | size = 140 }))

    -- 26. NUI.Qrcodegen (Nayuki encoder) ----------------------------------------
    , eq "qrcodegen HELLO WORLD (M) size 21" 21 (encodedSize "HELLO WORLD" Qrcodegen.Medium)
    , eq "qrcodegen grid is size x size" True (gridSquare "HELLO WORLD" Qrcodegen.Medium)
    , eq "qrcodegen finder (0,0) dark" True (moduleAt "HELLO WORLD" Qrcodegen.Medium 0 0)
    , eq "qrcodegen finder (1,1) light" False (moduleAt "HELLO WORLD" Qrcodegen.Medium 1 1)
    , eq "qrcodegen finder (3,3) dark" True (moduleAt "HELLO WORLD" Qrcodegen.Medium 3 3)
    , eq "qrcodegen overflow errors" True (isErr (Qrcodegen.encodeText (String.repeat 4000 "x") Qrcodegen.Low))

    -- 27. NUI.Rate cssVarsFor ---------------------------------------------------
    , eq "rate cssVarsFor has 4 vars" 4 (List.length rateVars)
    , eq "rate cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-item-color"
        , "--n-item-color-active"
        , "--n-item-size"
        ]
        (varKeys rateVars)
    , eq "rate --n-item-color = common.railColor" (Just common.railColor) (lookup "--n-item-color" rateVars)
    , eq "rate --n-item-color-active default #FFCC33" (Just "#FFCC33") (lookup "--n-item-color-active" rateVars)
    , eq "rate --n-item-color-active honours color option" (Just "#f0a020") (lookup "--n-item-color-active" rateColorVars)
    , eq "rate --n-item-size Small" (Just "16px") (lookup "--n-item-size" rateSmallVars)
    , eq "rate --n-item-size Medium" (Just "20px") (lookup "--n-item-size" rateVars)
    , eq "rate --n-item-size Large" (Just "24px") (lookup "--n-item-size" rateLargeVars)
    , eq "rate --n-bezier = common.cubicBezierEaseInOut" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" rateVars)

    -- 28. NUI.Collapse cssVarsFor -----------------------------------------------
    , eq "collapse cssVarsFor has 12 vars" 12 (List.length collapseVars)
    , eq "collapse cssVarsFor exact --n-* names"
        [ "--n-font-size"
        , "--n-bezier"
        , "--n-text-color"
        , "--n-divider-color"
        , "--n-title-padding"
        , "--n-title-font-size"
        , "--n-title-text-color"
        , "--n-title-text-color-disabled"
        , "--n-title-font-weight"
        , "--n-arrow-color"
        , "--n-arrow-color-disabled"
        , "--n-item-margin"
        ]
        (varKeys collapseVars)
    , eq "collapse --n-title-padding" (Just "16px 0 0 0") (lookup "--n-title-padding" collapseVars)
    , eq "collapse --n-item-margin" (Just "16px 0 0 0") (lookup "--n-item-margin" collapseVars)
    , eq "collapse --n-font-size = common.fontSize" (Just common.fontSize) (lookup "--n-font-size" collapseVars)
    , eq "collapse --n-title-font-size = common.fontSize" (Just common.fontSize) (lookup "--n-title-font-size" collapseVars)
    , eq "collapse --n-bezier = common.cubicBezierEaseInOut" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" collapseVars)
    , eq "collapse --n-text-color = common.textColor2" (Just common.textColor2) (lookup "--n-text-color" collapseVars)
    , eq "collapse --n-divider-color = common.dividerColor" (Just common.dividerColor) (lookup "--n-divider-color" collapseVars)
    , eq "collapse --n-title-text-color = common.textColor1" (Just common.textColor1) (lookup "--n-title-text-color" collapseVars)
    , eq "collapse --n-title-text-color-disabled = common.textColorDisabled" (Just common.textColorDisabled) (lookup "--n-title-text-color-disabled" collapseVars)
    , eq "collapse --n-title-font-weight = common.fontWeight" (Just common.fontWeight) (lookup "--n-title-font-weight" collapseVars)
    , eq "collapse --n-arrow-color = common.textColor2" (Just common.textColor2) (lookup "--n-arrow-color" collapseVars)
    , eq "collapse --n-arrow-color-disabled = common.textColorDisabled" (Just common.textColorDisabled) (lookup "--n-arrow-color-disabled" collapseVars)

    -- 29. NUI.FloatButton cssVarsFor --------------------------------------------
    , eq "float-button cssVarsFor has 9 vars" 9 (List.length floatButtonDefaultVars)
    , eq "float-button cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-box-shadow"
        , "--n-box-shadow-hover"
        , "--n-box-shadow-pressed"
        , "--n-color"
        , "--n-text-color"
        , "--n-color-hover"
        , "--n-color-pressed"
        , "--n-border-radius-square"
        ]
        (varKeys floatButtonDefaultVars)
    , eq "float-button default --n-color = common.popoverColor" (Just common.popoverColor) (lookup "--n-color" floatButtonDefaultVars)
    , eq "float-button default --n-text-color = common.textColor2" (Just common.textColor2) (lookup "--n-text-color" floatButtonDefaultVars)
    , eq "float-button default --n-color-hover = buttonColor2Hover" (Just common.buttonColor2Hover) (lookup "--n-color-hover" floatButtonDefaultVars)
    , eq "float-button default --n-color-pressed = buttonColor2Pressed" (Just common.buttonColor2Pressed) (lookup "--n-color-pressed" floatButtonDefaultVars)
    , eq "float-button primary --n-color = common.primaryColor" (Just common.primaryColor) (lookup "--n-color" floatButtonPrimaryVars)
    , eq "float-button primary --n-text-color = #fff" (Just "#fff") (lookup "--n-text-color" floatButtonPrimaryVars)
    , eq "float-button primary --n-color-hover = primaryColorHover" (Just common.primaryColorHover) (lookup "--n-color-hover" floatButtonPrimaryVars)
    , eq "float-button primary --n-color-pressed = primaryColorPressed" (Just common.primaryColorPressed) (lookup "--n-color-pressed" floatButtonPrimaryVars)
    , eq "float-button type switch changes --n-color" True (lookup "--n-color" floatButtonDefaultVars /= lookup "--n-color" floatButtonPrimaryVars)
    , eq "float-button --n-border-radius-square = common.borderRadius" (Just common.borderRadius) (lookup "--n-border-radius-square" floatButtonDefaultVars)
    , eq "float-button --n-box-shadow" (Just "0 2px 8px 0px rgba(0, 0, 0, .16)") (lookup "--n-box-shadow" floatButtonDefaultVars)
    , eq "float-button --n-box-shadow-hover" (Just "0 2px 12px 0px rgba(0, 0, 0, .24)") (lookup "--n-box-shadow-hover" floatButtonDefaultVars)
    , eq "float-button --n-box-shadow-pressed" (Just "0 2px 12px 0px rgba(0, 0, 0, .24)") (lookup "--n-box-shadow-pressed" floatButtonDefaultVars)

    -- 30. NUI.InputOtp cssVarsFor -----------------------------------------------
    , eq "input-otp cssVarsFor has 2 vars" 2 (List.length iotVars)
    , eq "input-otp cssVarsFor exact --n-* names" [ "--n-gap", "--n-input-width" ] (varKeys iotVars)
    , eq "input-otp --n-gap default Medium = theme gapMedium" (Just iotTheme.gapMedium) (lookup "--n-gap" iotVars)
    , eq "input-otp --n-gap default Small = theme gapSmall" (Just iotTheme.gapSmall) (lookup "--n-gap" iotSmallVars)
    , eq "input-otp --n-gap default Large = theme gapLarge" (Just iotTheme.gapLarge) (lookup "--n-gap" iotLargeVars)
    , eq "input-otp --n-gap Px 16 -> 16px" (Just "16px") (lookup "--n-gap" iotPxVars)
    , eq "input-otp --n-gap Custom \"1rem\" passes through" (Just "1rem") (lookup "--n-gap" iotCustomVars)
    , eq "input-otp --n-input-width Small = theme inputWidthSmall" (Just iotTheme.inputWidthSmall) (lookup "--n-input-width" iotSmallVars)
    , eq "input-otp --n-input-width Medium = theme inputWidthMedium" (Just iotTheme.inputWidthMedium) (lookup "--n-input-width" iotVars)
    , eq "input-otp --n-input-width Large = theme inputWidthLarge" (Just iotTheme.inputWidthLarge) (lookup "--n-input-width" iotLargeVars)
    , eq "input-otp --n-input-width Small literal 24px" (Just "24px") (lookup "--n-input-width" iotSmallVars)
    , eq "input-otp --n-input-width Medium literal 30px" (Just "30px") (lookup "--n-input-width" iotVars)
    , eq "input-otp --n-input-width Large literal 36px" (Just "36px") (lookup "--n-input-width" iotLargeVars)
    , eq "input-otp --n-input-width unaffected by gap override" (Just "30px") (lookup "--n-input-width" iotPxVars)

    -- 31. NUI.DynamicTags cssVarsFor --------------------------------------------
    , eq "dynamic-tags cssVarsFor has 1 var" 1 (List.length dtVars)
    , eq "dynamic-tags cssVarsFor exact --n-* names" [ "--n-input-width" ] (varKeys dtVars)
    , eq "dynamic-tags --n-input-width = theme inputWidth" (Just dtTheme.inputWidth) (lookup "--n-input-width" dtVars)
    , eq "dynamic-tags --n-input-width literal 64px" (Just "64px") (lookup "--n-input-width" dtVars)

    -- 32. NUI.Calendar cssVarsFor -----------------------------------------------
    , eq "calendar cssVarsFor has 21 vars" 21 (List.length calVars)
    , eq "calendar cssVarsFor exact --n-* names (order)"
        [ "--n-bezier"
        , "--n-border-color"
        , "--n-border-color-modal"
        , "--n-border-color-popover"
        , "--n-border-radius"
        , "--n-text-color"
        , "--n-title-font-weight"
        , "--n-title-font-size"
        , "--n-title-text-color"
        , "--n-day-text-color"
        , "--n-font-size"
        , "--n-line-height"
        , "--n-date-color-current"
        , "--n-date-text-color-current"
        , "--n-cell-color"
        , "--n-cell-color-modal"
        , "--n-cell-color-popover"
        , "--n-cell-color-hover"
        , "--n-cell-color-hover-modal"
        , "--n-cell-color-hover-popover"
        , "--n-bar-color"
        ]
        (varKeys calVars)
    , eq "calendar --n-bezier = common.cubicBezierEaseInOut" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" calVars)
    , eq "calendar --n-border-color = theme borderColor" (Just calTheme.borderColor) (lookup "--n-border-color" calVars)
    , eq "calendar --n-border-color literal rgba(239, 239, 245, 1)" (Just "rgba(239, 239, 245, 1)") (lookup "--n-border-color" calVars)
    , eq "calendar --n-border-color-modal = theme borderColorModal" (Just calTheme.borderColorModal) (lookup "--n-border-color-modal" calVars)
    , eq "calendar --n-border-color-popover = theme borderColorPopover" (Just calTheme.borderColorPopover) (lookup "--n-border-color-popover" calVars)
    , eq "calendar --n-border-radius = common.borderRadius" (Just common.borderRadius) (lookup "--n-border-radius" calVars)
    , eq "calendar --n-text-color = common.textColor2" (Just common.textColor2) (lookup "--n-text-color" calVars)
    , eq "calendar --n-title-font-weight = common.fontWeightStrong" (Just common.fontWeightStrong) (lookup "--n-title-font-weight" calVars)
    , eq "calendar --n-title-font-size = theme titleFontSize" (Just calTheme.titleFontSize) (lookup "--n-title-font-size" calVars)
    , eq "calendar --n-title-font-size literal 22px" (Just "22px") (lookup "--n-title-font-size" calVars)
    , eq "calendar --n-title-text-color = common.textColor1" (Just common.textColor1) (lookup "--n-title-text-color" calVars)
    , eq "calendar --n-day-text-color = common.textColorDisabled" (Just common.textColorDisabled) (lookup "--n-day-text-color" calVars)
    , eq "calendar --n-font-size = common.fontSize" (Just common.fontSize) (lookup "--n-font-size" calVars)
    , eq "calendar --n-line-height = common.lineHeight" (Just common.lineHeight) (lookup "--n-line-height" calVars)
    , eq "calendar --n-date-color-current = common.primaryColor" (Just common.primaryColor) (lookup "--n-date-color-current" calVars)
    , eq "calendar --n-date-text-color-current = common.baseColor" (Just common.baseColor) (lookup "--n-date-text-color-current" calVars)
    , eq "calendar --n-cell-color = common.cardColor" (Just common.cardColor) (lookup "--n-cell-color" calVars)
    , eq "calendar --n-cell-color-modal = common.modalColor" (Just common.modalColor) (lookup "--n-cell-color-modal" calVars)
    , eq "calendar --n-cell-color-popover = common.popoverColor" (Just common.popoverColor) (lookup "--n-cell-color-popover" calVars)
    , eq "calendar --n-cell-color-hover = theme cellColorHover" (Just calTheme.cellColorHover) (lookup "--n-cell-color-hover" calVars)
    , eq "calendar --n-cell-color-hover-modal = theme cellColorHoverModal" (Just calTheme.cellColorHoverModal) (lookup "--n-cell-color-hover-modal" calVars)
    , eq "calendar --n-cell-color-hover-popover = theme cellColorHoverPopover" (Just calTheme.cellColorHoverPopover) (lookup "--n-cell-color-hover-popover" calVars)
    , eq "calendar --n-bar-color = common.primaryColor" (Just common.primaryColor) (lookup "--n-bar-color" calVars)

    -- 33. NUI.Calendar panel helpers ---------------------------------------------
    , eq "calendar panelOf keeps the month" { year = 2024, month = 6 } (Calendar.panelOf { year = 2024, month = 6, day = 20 })
    , eq "calendar panelOf keeps leap Feb" { year = 2024, month = 2 } (Calendar.panelOf { year = 2024, month = 2, day = 29 })
    , eq "calendar addMonthsPanel -1 wraps Jan -> prev Dec" { year = 2023, month = 12 } (Calendar.addMonthsPanel { year = 2024, month = 1 } -1)
    , eq "calendar addMonthsPanel +1 wraps Dec -> next Jan" { year = 2025, month = 1 } (Calendar.addMonthsPanel { year = 2024, month = 12 } 1)
    , eq "calendar addMonthsPanel within a year" { year = 2024, month = 7 } (Calendar.addMonthsPanel { year = 2024, month = 6 } 1)
    , eq "calendar todayPanel is Nothing when panel == now month"
        Nothing
        (Calendar.todayPanel { calDefaults | panel = { year = 2024, month = 6 }, now = { year = 2024, month = 6, day = 15 } })
    , eq "calendar todayPanel is Just now-month when they differ"
        (Just { year = 2024, month = 6 })
        (Calendar.todayPanel { calDefaults | panel = { year = 2024, month = 3 }, now = { year = 2024, month = 6, day = 15 } })

    -- 34. NUI.Pagination pageItems (upstream createPageItemsInfo) -----------------
    , eq "pagination pageCount 1 -> [1]" [ "1" ] (pageLabels pg1)
    , eq "pagination pageCount 1 hasFastBackward False" False pg1.hasFastBackward
    , eq "pagination pageCount 1 hasFastForward False" False pg1.hasFastForward
    , eq "pagination pageCount 1 fastBackwardTo 1" 1 pg1.fastBackwardTo
    , eq "pagination pageCount 1 fastForwardTo 1" 1 pg1.fastForwardTo
    , eq "pagination pageCount 2 -> [1,2]" [ "1", "2" ] (pageLabels pg2a)
    , eq "pagination pageCount 2 page 1 active" (Just 1) (activeLabel pg2a)
    , eq "pagination pageCount 2 page 2 active" (Just 2) (activeLabel pg2b)
    , eq "pagination pageCount 2 page 2 mayBeFastBackward" (Just True) (mayBeFastBackwardOf 2 pg2a)
    , eq "pagination pageCount 2 page 2 mayBeFastForward" (Just False) (mayBeFastForwardOf 2 pg2a)
    , eq "pagination middle labels (1, fast-backward, 4..8, fast-forward, 16)"
        [ "1", "fast-backward", "4", "5", "6", "7", "8", "fast-forward", "16" ]
        (pageLabels pgMid)
    , eq "pagination middle active label 6" (Just 6) (activeLabel pgMid)
    , eq "pagination middle hasFastBackward True" True pgMid.hasFastBackward
    , eq "pagination middle hasFastForward True" True pgMid.hasFastForward
    , eq "pagination middle fastBackwardTo 3" 3 pgMid.fastBackwardTo
    , eq "pagination middle fastForwardTo 9" 9 pgMid.fastForwardTo
    , eq "pagination middle backward options = range 2..3" (Just (rangeOptions 2 3)) (fastBackwardOptions pgMid)
    , eq "pagination middle forward options = range 9..15" (Just (rangeOptions 9 15)) (fastForwardOptions pgMid)
    , eq "pagination middle no left split at page 1 -> [1,2,3..7]"
        [ "1", "2", "3", "4", "5", "6", "7" ]
        (List.take 7 (pageLabels pgFirst))
    , eq "pagination first-page labels (no fast-backward; fast-forward + 16)"
        [ "1", "2", "3", "4", "5", "6", "7", "fast-forward", "16" ]
        (pageLabels pgFirst)
    , eq "pagination first-page hasFastBackward False" False pgFirst.hasFastBackward
    , eq "pagination first-page fastBackwardTo 1" 1 pgFirst.fastBackwardTo
    , eq "pagination first-page hasFastForward True" True pgFirst.hasFastForward
    , eq "pagination first-page fastForwardTo 8" 8 pgFirst.fastForwardTo
    , eq "pagination first-page page 2 mayBeFastBackward" (Just True) (mayBeFastBackwardOf 2 pgFirst)
    , eq "pagination last-page labels (fast-backward, no fast-forward, 16)"
        [ "1", "fast-backward", "10", "11", "12", "13", "14", "15", "16" ]
        (pageLabels pgLast)
    , eq "pagination last-page active label 16" (Just 16) (activeLabel pgLast)
    , eq "pagination last-page hasFastBackward True" True pgLast.hasFastBackward
    , eq "pagination last-page fastBackwardTo 9" 9 pgLast.fastBackwardTo
    , eq "pagination last-page hasFastForward False" False pgLast.hasFastForward
    , eq "pagination last-page fastForwardTo 16" 16 pgLast.fastForwardTo
    , eq "pagination last-page page 15 mayBeFastForward" (Just True) (mayBeFastForwardOf 15 pgLast)
    , eq "pagination last-page backward options = range 2..9" (Just (rangeOptions 2 9)) (fastBackwardOptions pgLast)
    , eq "pagination showQuickJumpDropdown False -> backward options Nothing" Nothing (fastBackwardOptions pgMidNoDrop)
    , eq "pagination showQuickJumpDropdown False -> forward options Nothing" Nothing (fastForwardOptions pgMidNoDrop)
    , eq "pagination showQuickJumpDropdown False keeps the window labels"
        [ "1", "fast-backward", "4", "5", "6", "7", "8", "fast-forward", "16" ]
        (pageLabels pgMidNoDrop)
    , eq "pagination showQuickJumpDropdown False still hasFastBackward" True pgMidNoDrop.hasFastBackward
    , eq "pagination showQuickJumpDropdown False still hasFastForward" True pgMidNoDrop.hasFastForward
    , eq "pagination pageSlot 7 labels (odd slot)"
        [ "1", "fast-backward", "5", "6", "7", "fast-forward", "16" ]
        (pageLabels pgSlot7)
    , eq "pagination pageSlot 7 fastBackwardTo 4" 4 pgSlot7.fastBackwardTo
    , eq "pagination pageSlot 7 fastForwardTo 8" 8 pgSlot7.fastForwardTo
    , eq "pagination pageSlot 7 backward options = range 2..4" (Just (rangeOptions 2 4)) (fastBackwardOptions pgSlot7)
    , eq "pagination pageSlot 8 labels (even slot)"
        [ "1", "fast-backward", "5", "6", "7", "8", "fast-forward", "16" ]
        (pageLabels pgSlot8)
    , eq "pagination pageSlot 8 fastBackwardTo 4" 4 pgSlot8.fastBackwardTo
    , eq "pagination pageSlot 8 fastForwardTo 9" 9 pgSlot8.fastForwardTo
    , eq "pagination pageSlot 8 forward options = range 9..15" (Just (rangeOptions 9 15)) (fastForwardOptions pgSlot8)

    -- 35. NUI.Pagination pageCount / getDefaultPageSize ---------------------------
    , eq "pagination pageCount 0 items -> 1" 1 (Pagination.pageCount { itemCount = 0, pageSize = 10 })
    , eq "pagination pageCount 1 item -> 1" 1 (Pagination.pageCount { itemCount = 1, pageSize = 10 })
    , eq "pagination pageCount 10 items -> 1" 1 (Pagination.pageCount { itemCount = 10, pageSize = 10 })
    , eq "pagination pageCount 11 items -> 2 (float division)" 2 (Pagination.pageCount { itemCount = 11, pageSize = 10 })
    , eq "pagination pageCount 99 items -> 10" 10 (Pagination.pageCount { itemCount = 99, pageSize = 10 })
    , eq "pagination pageCount 100 items -> 10" 10 (Pagination.pageCount { itemCount = 100, pageSize = 10 })
    , eq "pagination pageCount 153 items -> 16" 16 (Pagination.pageCount { itemCount = 153, pageSize = 10 })
    , eq "pagination pageCount 20 items / 6 -> 4" 4 (Pagination.pageCount { itemCount = 20, pageSize = 6 })
    , eq "pagination getDefaultPageSize defaultPageSize wins"
        20
        (Pagination.getDefaultPageSize { defaultPageSize = Just 20, pageSizes = [ Pagination.PageSizeNumber 50 ] })
    , eq "pagination getDefaultPageSize number entry 10"
        10
        (Pagination.getDefaultPageSize { defaultPageSize = Nothing, pageSizes = [ Pagination.PageSizeNumber 10 ] })
    , eq "pagination getDefaultPageSize number entry 50"
        50
        (Pagination.getDefaultPageSize { defaultPageSize = Nothing, pageSizes = [ Pagination.PageSizeNumber 50 ] })
    , eq "pagination getDefaultPageSize number 0 returned as-is (falsy trap)"
        0
        (Pagination.getDefaultPageSize { defaultPageSize = Nothing, pageSizes = [ Pagination.PageSizeNumber 0 ] })
    , eq "pagination getDefaultPageSize option value 20"
        20
        (Pagination.getDefaultPageSize { defaultPageSize = Nothing, pageSizes = [ Pagination.PageSizeOption { label = "20 / page", value = 20 } ] })
    , eq "pagination getDefaultPageSize option value 0 falls back to 10 (JS ||)"
        10
        (Pagination.getDefaultPageSize { defaultPageSize = Nothing, pageSizes = [ Pagination.PageSizeOption { label = "0", value = 0 } ] })
    , eq "pagination getDefaultPageSize empty pageSizes -> 10"
        10
        (Pagination.getDefaultPageSize { defaultPageSize = Nothing, pageSizes = [] })

    -- 36. NUI.Pagination cssVarsFor -----------------------------------------------
    , eq "pagination cssVarsFor has 43 vars" 43 (List.length pgDefaultVars)
    , eq "pagination cssVarsFor exact --n-* names (order)"
        [ "--n-prefix-margin"
        , "--n-suffix-margin"
        , "--n-item-font-size"
        , "--n-select-width"
        , "--n-select-margin"
        , "--n-input-width"
        , "--n-input-margin"
        , "--n-input-margin-rtl"
        , "--n-item-size"
        , "--n-item-text-color"
        , "--n-item-text-color-disabled"
        , "--n-item-text-color-hover"
        , "--n-item-text-color-active"
        , "--n-item-text-color-pressed"
        , "--n-item-color"
        , "--n-item-color-hover"
        , "--n-item-color-disabled"
        , "--n-item-color-active"
        , "--n-item-color-active-hover"
        , "--n-item-color-pressed"
        , "--n-item-border"
        , "--n-item-border-hover"
        , "--n-item-border-disabled"
        , "--n-item-border-active"
        , "--n-item-border-pressed"
        , "--n-item-padding"
        , "--n-item-border-radius"
        , "--n-bezier"
        , "--n-jumper-font-size"
        , "--n-jumper-text-color"
        , "--n-jumper-text-color-disabled"
        , "--n-item-margin"
        , "--n-item-margin-rtl"
        , "--n-button-icon-size"
        , "--n-button-icon-color"
        , "--n-button-icon-color-hover"
        , "--n-button-icon-color-pressed"
        , "--n-button-color-hover"
        , "--n-button-color"
        , "--n-button-color-pressed"
        , "--n-button-border"
        , "--n-button-border-hover"
        , "--n-button-border-pressed"
        ]
        (varKeys pgDefaultVars)
    , eq "pagination --n-bezier = common.cubicBezierEaseInOut" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" pgDefaultVars)
    , eq "pagination --n-item-border-radius = common.borderRadius" (Just common.borderRadius) (lookup "--n-item-border-radius" pgDefaultVars)
    , eq "pagination --n-item-text-color = common.textColor2" (Just common.textColor2) (lookup "--n-item-text-color" pgDefaultVars)
    , eq "pagination --n-item-text-color-active = common.primaryColor (literal #18a058)" (Just "#18a058") (lookup "--n-item-text-color-active" pgDefaultVars)
    , eq "pagination --n-item-text-color-hover = primaryColorHover (#36ad6a)" (Just "#36ad6a") (lookup "--n-item-text-color-hover" pgDefaultVars)
    , eq "pagination --n-item-border-active literal #18a058" (Just "1px solid #18a058") (lookup "--n-item-border-active" pgDefaultVars)
    , eq "pagination --n-item-font-size Medium = common.fontSizeSmall (14px)" (Just "14px") (lookup "--n-item-font-size" pgDefaultVars)
    , eq "pagination --n-item-size Medium = common.heightSmall (28px)" (Just "28px") (lookup "--n-item-size" pgDefaultVars)
    , eq "pagination --n-button-icon-size Medium = 16px" (Just "16px") (lookup "--n-button-icon-size" pgDefaultVars)
    , eq "pagination --n-input-width = 60px" (Just "60px") (lookup "--n-input-width" pgDefaultVars)
    , eq "pagination --n-item-size Small = 22px" (Just "22px") (lookup "--n-item-size" pgSmallVars)
    , eq "pagination --n-button-icon-size Small = 14px" (Just "14px") (lookup "--n-button-icon-size" pgSmallVars)
    , eq "pagination --n-item-size Large = common.heightMedium (34px)" (Just "34px") (lookup "--n-item-size" pgLargeVars)
    , eq "pagination --n-button-icon-size Large = 18px" (Just "18px") (lookup "--n-button-icon-size" pgLargeVars)
    , eq "pagination Tiny clamps to Small (item-size 22px)" (Just "22px") (lookup "--n-item-size" pgTinyVars)

    -- 37. NUI.InputNumber parse / parseNumber ------------------------------------
    , eqNaN "input-number parse \"\" -> Nothing" Nothing (InputNumber.parse "")
    , eqNaN "input-number parse whitespace -> Nothing" Nothing (InputNumber.parse "   ")
    , eqNaN "input-number parse \"abc\" -> Just NaN" (Just (0 / 0)) (InputNumber.parse "abc")
    , eqNaN "input-number parse \"42\" -> Just 42" (Just 42) (InputNumber.parse "42")
    , eqNaN "input-number parse \"3.14\" -> Just 3.14" (Just 3.14) (InputNumber.parse "3.14")
    , eqNaN "input-number parse \" 12 \" trims -> Just 12" (Just 12) (InputNumber.parse " 12 ")
    , eqNaN "input-number parse \"-3\" -> Just -3" (Just -3) (InputNumber.parse "-3")
    , eqNaN "input-number parse \"0x10\" radix -> Just 16" (Just 16) (InputNumber.parse "0x10")
    , eqNaN "input-number parseNumber \"\" -> Just 0 (JS Number(''))" (Just 0) (InputNumber.parseNumber "")
    , eqNaN "input-number parseNumber \"abc\" -> Nothing" Nothing (InputNumber.parseNumber "abc")
    , eqNaN "input-number parseNumber \"42\" -> Just 42" (Just 42) (InputNumber.parseNumber "42")
    , eqNaN "input-number parseNumber \"1e3\" -> Just 1000" (Just 1000) (InputNumber.parseNumber "1e3")

    -- 38. NUI.InputNumber isWipValue / validator ----------------------------------
    , eq "input-number isWipValue \"0.\" True" True (InputNumber.isWipValue "0.")
    , eq "input-number isWipValue \"-0\" True" True (InputNumber.isWipValue "-0")
    , eq "input-number isWipValue \"-\" True" True (InputNumber.isWipValue "-")
    , eq "input-number isWipValue \"1.0\" True" True (InputNumber.isWipValue "1.0")
    , eq "input-number isWipValue \"1.20\" True" True (InputNumber.isWipValue "1.20")
    , eq "input-number isWipValue \"0.1\" False" False (InputNumber.isWipValue "0.1")
    , eq "input-number isWipValue \"1\" False" False (InputNumber.isWipValue "1")
    , eq "input-number isWipValue \"12.34\" False" False (InputNumber.isWipValue "12.34")
    , eq "input-number isWipValue \".\" False" False (InputNumber.isWipValue ".")
    , eq "input-number validator Nothing True" True (InputNumber.validator Nothing)
    , eq "input-number validator (Just 5) True" True (InputNumber.validator (Just 5))
    , eq "input-number validator (Just NaN) False" False (InputNumber.validator (Just (0 / 0)))

    -- 39. NUI.InputNumber format / toFixedJs --------------------------------------
    , eq "input-number format Nothing Nothing -> \"\"" "" (InputNumber.format Nothing Nothing)
    , eq "input-number format (Just 42) Nothing -> \"42\"" "42" (InputNumber.format (Just 42) Nothing)
    , eq "input-number format (Just 42) (Just 2) -> \"42.00\"" "42.00" (InputNumber.format (Just 42) (Just 2))
    , eq "input-number format (Just 3.14159) (Just 2) -> \"3.14\"" "3.14" (InputNumber.format (Just 3.14159) (Just 2))
    , eq "input-number format (Just 1234.5678) Nothing -> full String(value)" "1234.5678" (InputNumber.format (Just 1234.5678) Nothing)
    , eq "input-number format (Just 2.675) (Just 2) -> \"2.67\"" "2.67" (InputNumber.format (Just 2.675) (Just 2))
    , eq "input-number format (Just 0.125) (Just 2) -> \"0.13\"" "0.13" (InputNumber.format (Just 0.125) (Just 2))
    , eq "input-number format (Just 1.005) (Just 2) -> \"1.00\"" "1.00" (InputNumber.format (Just 1.005) (Just 2))
    , eq "input-number toFixedJs 42 0 -> \"42\"" "42" (InputNumber.toFixedJs 42 0)
    , eq "input-number toFixedJs 42 2 -> \"42.00\"" "42.00" (InputNumber.toFixedJs 42 2)
    , eq "input-number toFixedJs 2.675 2 -> \"2.67\"" "2.67" (InputNumber.toFixedJs 2.675 2)
    , eq "input-number toFixedJs 0.125 2 -> \"0.13\" (exact tie rounds away)" "0.13" (InputNumber.toFixedJs 0.125 2)
    , eq "input-number toFixedJs -0 2 -> \"0.00\" (no sign for -0)" "0.00" (InputNumber.toFixedJs 0 2)

    -- 40. NUI.InputNumber getPrecision / getMaxPrecision ---------------------------
    , eq "input-number getPrecision 0.1 -> 1" 1 (InputNumber.getPrecision 0.1)
    , eq "input-number getPrecision 1 -> 0" 0 (InputNumber.getPrecision 1)
    , eq "input-number getPrecision 1.234 -> 3" 3 (InputNumber.getPrecision 1.234)
    , eq "input-number getPrecision 100 -> 0" 0 (InputNumber.getPrecision 100)
    , eq "input-number getPrecision 1e-7 -> 0 (exponent form)" 0 (InputNumber.getPrecision 1.0e-7)
    , eq "input-number getMaxPrecision max of min/max/step/current"
        5
        (InputNumber.getMaxPrecision { min = Just 0.5, max = Just 10, step = 0.01, precision = Nothing, displayedValue = "" } 3.14159)
    , eq "input-number getMaxPrecision all integers -> 0"
        0
        (InputNumber.getMaxPrecision { min = Nothing, max = Nothing, step = 1, precision = Nothing, displayedValue = "" } 2)
    , eq "input-number getMaxPrecision min 1.5 only -> 1"
        1
        (InputNumber.getMaxPrecision { min = Just 1.5, max = Nothing, step = 1, precision = Nothing, displayedValue = "" } 2)

    -- 41. NUI.InputNumber deriveValueFromDisplayedValue ---------------------------
    , eq "input-number derive clamps 20 above max 10 (doUpdateIfValid)"
        (InputNumber.NumberValue 10)
        (InputNumber.deriveValueFromDisplayedValue nCtxMax { offset = 0, doUpdateIfValid = True, fixPrecision = False, isInputing = False })
    , eq "input-number derive above max without doUpdateIfValid -> Invalid"
        InputNumber.InvalidValue
        (InputNumber.deriveValueFromDisplayedValue nCtxMax { offset = 0, doUpdateIfValid = False, fixPrecision = False, isInputing = False })
    , eq "input-number derive clamps 1 below min 5 (doUpdateIfValid)"
        (InputNumber.NumberValue 5)
        (InputNumber.deriveValueFromDisplayedValue nCtxMin { offset = 0, doUpdateIfValid = True, fixPrecision = False, isInputing = False })
    , eq "input-number derive below min without doUpdateIfValid -> Invalid"
        InputNumber.InvalidValue
        (InputNumber.deriveValueFromDisplayedValue nCtxMin { offset = 0, doUpdateIfValid = False, fixPrecision = False, isInputing = False })
    , eq "input-number derive offset +1 of 5 -> 6"
        (InputNumber.NumberValue 6)
        (InputNumber.deriveValueFromDisplayedValue nCtxPlain { offset = 1, doUpdateIfValid = True, fixPrecision = True, isInputing = False })
    , eq "input-number derive offset -1 of 5 -> 4"
        (InputNumber.NumberValue 4)
        (InputNumber.deriveValueFromDisplayedValue nCtxPlain { offset = -1, doUpdateIfValid = True, fixPrecision = True, isInputing = False })
    , eq "input-number derive empty -> NullValue"
        InputNumber.NullValue
        (InputNumber.deriveValueFromDisplayedValue nCtxEmpty { offset = 0, doUpdateIfValid = False, fixPrecision = False, isInputing = False })
    , eq "input-number derive \"abc\" (NaN) -> Invalid"
        InputNumber.InvalidValue
        (InputNumber.deriveValueFromDisplayedValue nCtxNaN { offset = 0, doUpdateIfValid = False, fixPrecision = False, isInputing = False })
    , eq "input-number derive wip \"0.\" while inputing -> Invalid"
        InputNumber.InvalidValue
        (InputNumber.deriveValueFromDisplayedValue nCtxWip { offset = 0, doUpdateIfValid = True, fixPrecision = False, isInputing = True })
    , eq "input-number derive precision gate blocks 1.234 at precision 2"
        InputNumber.InvalidValue
        (InputNumber.deriveValueFromDisplayedValue nCtxPrec { offset = 0, doUpdateIfValid = True, fixPrecision = False, isInputing = False })
    , eq "input-number derive precision gate fixed -> 1.23"
        (InputNumber.NumberValue 1.23)
        (InputNumber.deriveValueFromDisplayedValue nCtxPrec { offset = 0, doUpdateIfValid = True, fixPrecision = True, isInputing = False })
    , eq "input-number derive uses step precision when precision unset (offset 0.25 -> 1.25)"
        (InputNumber.NumberValue 1.25)
        (InputNumber.deriveValueFromDisplayedValue nCtxStep { offset = 0.25, doUpdateIfValid = True, fixPrecision = False, isInputing = False })

    -- 42. NUI.InputNumber add / minus / createValidValue ---------------------------
    , eq "input-number addable (value 5, step 1) True" True (InputNumber.addable (InputNumber.contextOf inNum5))
    , eq "input-number minusable (value 5, step 1) True" True (InputNumber.minusable (InputNumber.contextOf inNum5))
    , eq "input-number addUpdate (value 5) -> Just (Just 6)" (Just (Just 6)) (InputNumber.addUpdate inNum5)
    , eq "input-number minusUpdate (value 5) -> Just (Just 4)" (Just (Just 4)) (InputNumber.minusUpdate inNum5)
    , eq "input-number addable at max -> False" False (InputNumber.addable (InputNumber.contextOf inNumMaxed))
    , eq "input-number addUpdate at max -> Nothing (button disabled)" Nothing (InputNumber.addUpdate inNumMaxed)
    , eq "input-number addUpdate empty value -> Just (Just createValidValue 0)" (Just (Just 0)) (InputNumber.addUpdate inNumDefaults)
    , eq "input-number createValidValue min 3 -> 3" 3 (InputNumber.createValidValue inNumMin3)
    , eq "input-number createValidValue min -5 -> max 0 -5 = 0" 0 (InputNumber.createValidValue inNumMinNeg5)
    , eq "input-number createValidValue max -2 -> min 0 -2 = -2" -2 (InputNumber.createValidValue inNumMaxNeg2)
    , eq "input-number createValidValue max 5 -> 0" 0 (InputNumber.createValidValue inNumMax5)

    -- 43. NUI.InputNumber inputUpdate / displayedValueFor -------------------------
    , eq "input-number inputUpdate \"7\" -> Just (Just 7)" (Just (Just 7)) (InputNumber.inputUpdate inNum1 "7")
    , eq "input-number inputUpdate wip \"0.\" -> Nothing" Nothing (InputNumber.inputUpdate inNum1 "0.")
    , eq "input-number inputUpdate unparseable \"abc\" -> Nothing" Nothing (InputNumber.inputUpdate inNum1 "abc")
    , eq "input-number inputUpdate with updateValueOnInput False -> Nothing" Nothing (InputNumber.inputUpdate inNum1NoLive "7")
    , eq "input-number inputUpdate with precision set -> Nothing" Nothing (InputNumber.inputUpdate inNum1Prec "7")
    , eq "input-number displayedValueFor no value -> \"\"" "" (InputNumber.displayedValueFor inNumDefaults)
    , eq "input-number displayedValueFor value 5 -> \"5\"" "5" (InputNumber.displayedValueFor inNum5)
    , eq "input-number displayedValueFor 5 precision 2 -> \"5.00\"" "5.00" (InputNumber.displayedValueFor inNum5Prec2)
    , eq "input-number displayedValueFor 1.2345 precision 2 overflows -> full text" "1.2345" (InputNumber.displayedValueFor inNumOverflow)

    -- 44. NUI.Layout positionClass / cssVarsFor -----------------------------------
    , eq "layout positionClass Static = static" "static" (Layout.positionClass Layout.Static)
    , eq "layout positionClass Absolute = absolute" "absolute" (Layout.positionClass Layout.Absolute)
    , eq "layout cssVarsFor has 3 vars" 3 (List.length layoutVars)
    , eq "layout cssVarsFor exact --n-* names" [ "--n-bezier", "--n-color", "--n-text-color" ] (varKeys layoutVars)
    , eq "layout --n-bezier = common.cubicBezierEaseInOut" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" layoutVars)
    , eq "layout --n-color = theme color (bodyColor #fff)" (Just "#fff") (lookup "--n-color" layoutVars)
    , eq "layout --n-color = LayoutTheme.vars.color" (Just layoutTheme.color) (lookup "--n-color" layoutVars)
    , eq "layout --n-text-color = theme textColor" (Just layoutTheme.textColor) (lookup "--n-text-color" layoutVars)
    , eq "layout embedded --n-color = theme colorEmbedded" (Just layoutTheme.colorEmbedded) (lookup "--n-color" layoutEmbeddedVars)
    , eq "layout embedded --n-color literal actionColor rgb(250, 250, 252)" (Just "rgb(250, 250, 252)") (lookup "--n-color" layoutEmbeddedVars)
    , eq "layout embedded --n-color differs from plain" True (lookup "--n-color" layoutEmbeddedVars /= lookup "--n-color" layoutVars)

    -- 45. NUI.LayoutSider cssVarsFor ----------------------------------------------
    , eq "layout-sider cssVarsFor has 9 vars (non-inverted)" 9 (List.length siderDefaultVars)
    , eq "layout-sider cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-toggle-button-color"
        , "--n-toggle-button-border"
        , "--n-toggle-bar-color"
        , "--n-toggle-bar-color-hover"
        , "--n-color"
        , "--n-text-color"
        , "--n-border-color"
        , "--n-toggle-button-icon-color"
        ]
        (varKeys siderDefaultVars)
    , eq "layout-sider --n-color = theme siderColor (cardColor #fff)" (Just layoutTheme.siderColor) (lookup "--n-color" siderDefaultVars)
    , eq "layout-sider --n-toggle-button-border literal" (Just "1px solid rgb(239, 239, 245)") (lookup "--n-toggle-button-border" siderDefaultVars)
    , eq "layout-sider --n-toggle-bar-color literal rgba(191, 191, 191, 1)" (Just "rgba(191, 191, 191, 1)") (lookup "--n-toggle-bar-color" siderDefaultVars)
    , eq "layout-sider --n-toggle-button-icon-color = theme icon color" (Just layoutTheme.siderToggleButtonIconColor) (lookup "--n-toggle-button-icon-color" siderDefaultVars)
    , eq "layout-sider inverted --n-color = theme siderColorInverted" (Just layoutTheme.siderColorInverted) (lookup "--n-color" siderInvertedVars)
    , eq "layout-sider inverted --n-color literal invertedColor rgb(0, 20, 40)" (Just "rgb(0, 20, 40)") (lookup "--n-color" siderInvertedVars)
    , eq "layout-sider inverted --n-border-color differs from plain" True (lookup "--n-border-color" siderInvertedVars /= lookup "--n-border-color" siderDefaultVars)
    , eq "layout-sider inverted var set differs from plain" True (siderInvertedVars /= siderDefaultVars)
    , eq "layout-sider inverted --n-toggle-button-icon-color matches upstream (textColor2)" (Just common.textColor2) (lookup "--n-toggle-button-icon-color" siderInvertedVars)

    -- 46. NUI.LayoutHeader / LayoutFooter cssVarsFor -------------------------------
    , eq "layout-header cssVarsFor has 4 vars" 4 (List.length headerDefaultVars)
    , eq "layout-header cssVarsFor exact --n-* names" [ "--n-bezier", "--n-color", "--n-text-color", "--n-border-color" ] (varKeys headerDefaultVars)
    , eq "layout-header --n-color = theme headerColor (cardColor #fff)" (Just layoutTheme.headerColor) (lookup "--n-color" headerDefaultVars)
    , eq "layout-header --n-border-color = theme headerBorderColor (dividerColor)" (Just layoutTheme.headerBorderColor) (lookup "--n-border-color" headerDefaultVars)
    , eq "layout-header inverted --n-color = theme headerColorInverted" (Just layoutTheme.headerColorInverted) (lookup "--n-color" headerInvertedVars)
    , eq "layout-header inverted --n-color literal invertedColor rgb(0, 20, 40)" (Just "rgb(0, 20, 40)") (lookup "--n-color" headerInvertedVars)
    , eq "layout-header inverted --n-color differs from plain" True (lookup "--n-color" headerInvertedVars /= lookup "--n-color" headerDefaultVars)
    , eq "layout-footer cssVarsFor has 4 vars" 4 (List.length footerDefaultVars)
    , eq "layout-footer cssVarsFor exact --n-* names" [ "--n-bezier", "--n-color", "--n-text-color", "--n-border-color" ] (varKeys footerDefaultVars)
    , eq "layout-footer --n-color = theme footerColor (actionColor)" (Just layoutTheme.footerColor) (lookup "--n-color" footerDefaultVars)
    , eq "layout-footer --n-color literal actionColor rgb(250, 250, 252)" (Just "rgb(250, 250, 252)") (lookup "--n-color" footerDefaultVars)
    , eq "layout-footer inverted --n-color = theme footerColorInverted" (Just layoutTheme.footerColorInverted) (lookup "--n-color" footerInvertedVars)
    , eq "layout-footer inverted --n-color literal invertedColor rgb(0, 20, 40)" (Just "rgb(0, 20, 40)") (lookup "--n-color" footerInvertedVars)

    -- 47. NUI.Grid responsive helpers --------------------------------------------
    , eq "grid parse Number 24 / NoQuery -> Just \"24\""
        (Just "24")
        (Grid.parseResponsivePropValue (Grid.Number 24) Grid.NoQuery)
    , eq "grid parse Custom \"1 s:2 m:3\" / NoQuery -> default Just \"1\""
        (Just "1")
        (Grid.parseResponsivePropValue (Grid.Custom "1 s:2 m:3") Grid.NoQuery)
    , eq "grid parse ByKeys [s,m] -> widest active key wins, Just \"3\""
        (Just "3")
        (Grid.parseResponsivePropValue (Grid.Custom "1 s:2 m:3") (Grid.ByKeys [ "s", "m" ]))
    , eq "grid parse ByKeys [xs,s] -> Just \"2\""
        (Just "2")
        (Grid.parseResponsivePropValue (Grid.Custom "1 s:2 m:3") (Grid.ByKeys [ "xs", "s" ]))
    , eq "grid parse ByKeys [] -> falls back to the default Just \"1\""
        (Just "1")
        (Grid.parseResponsivePropValue (Grid.Custom "1 s:2 m:3") (Grid.ByKeys []))
    , eq "grid parse ByKeys unmatched key -> default Just \"1\""
        (Just "1")
        (Grid.parseResponsivePropValue (Grid.Custom "1 s:2 m:3") (Grid.ByKeys [ "zz" ]))
    , eq "grid parse ByWidth 800 on \"2 768:3\" -> largest numeric key <= width Just \"3\""
        (Just "3")
        (Grid.parseResponsivePropValue (Grid.Custom "2 768:3") (Grid.ByWidth 800))
    , eq "grid parse ByWidth 100 on \"2 768:3\" -> bare token (key 0) Just \"2\""
        (Just "2")
        (Grid.parseResponsivePropValue (Grid.Custom "2 768:3") (Grid.ByWidth 100))
    , eq "grid parse ByWidth 768 on \"2 768:3\" -> boundary matches Just \"3\""
        (Just "3")
        (Grid.parseResponsivePropValue (Grid.Custom "2 768:3") (Grid.ByWidth 768))
    , eq "grid parse ByWidth with no default and nothing <= width -> Nothing"
        Nothing
        (Grid.parseResponsivePropValue (Grid.Custom "768:3") (Grid.ByWidth 100))
    , eq "grid parse Custom with no default / NoQuery -> Nothing"
        Nothing
        (Grid.parseResponsivePropValue (Grid.Custom "s:2") Grid.NoQuery)
    , eq "grid parse later token overwrites earlier for the same key (Just \"2\")"
        (Just "2")
        (Grid.parseResponsivePropValue (Grid.Custom "s:1 s:2") (Grid.ByKeys [ "s" ]))
    , eq "grid breakpointKeys default 0 -> [xs]"
        [ "xs" ]
        (Grid.breakpointKeys Grid.defaultBreakpoints 0)
    , eq "grid breakpointKeys default 639 -> [xs]"
        [ "xs" ]
        (Grid.breakpointKeys Grid.defaultBreakpoints 639)
    , eq "grid breakpointKeys default 640 -> [xs,s]"
        [ "xs", "s" ]
        (Grid.breakpointKeys Grid.defaultBreakpoints 640)
    , eq "grid breakpointKeys default 1023 -> [xs,s]"
        [ "xs", "s" ]
        (Grid.breakpointKeys Grid.defaultBreakpoints 1023)
    , eq "grid breakpointKeys default 1920 -> all six ascending"
        [ "xs", "s", "m", "l", "xl", "xxl" ]
        (Grid.breakpointKeys Grid.defaultBreakpoints 1920)
    , eq "grid defaultBreakpoints = the 6 upstream pairs"
        [ ( "xs", 0 ), ( "s", 640 ), ( "m", 1024 ), ( "l", 1280 ), ( "xl", 1536 ), ( "xxl", 1920 ) ]
        Grid.defaultBreakpoints
    , eq "grid defaultCols = 24" 24 Grid.defaultCols
    , eq "grid defaultSpan = 1" 1 Grid.defaultSpan
    , eq "grid defaults cols = Number 24" (Grid.Number 24) gridDefaults.cols
    , eq "grid defaults query = NoQuery" Grid.NoQuery gridDefaults.query
    , eq "grid defaults breakpoints = defaultBreakpoints" Grid.defaultBreakpoints gridDefaults.breakpoints
    , eq "grid defaults collapsedRows = 1" 1 gridDefaults.collapsedRows
    , eq "grid defaults itemResponsive = False" False gridDefaults.itemResponsive
    , eq "grid item span default = Number 1" (Grid.Number 1) Grid.item.span
    , eq "grid item offset default = Number 0" (Grid.Number 0) Grid.item.offset
    , eq "grid item suffix default = False" False Grid.item.suffix
    , eq "grid item show default = True" True Grid.item.show
    , eq "grid viewWithOverflow 3x span12 / cols24 (no collapse) -> no overflow"
        False
        (gridOverflow gridDefaults (gridHalfItems 3))
    , eq "grid viewWithOverflow collapsed cols12 4x span6 -> overflow"
        True
        (gridOverflow gridCollapseOpts (gridHalfItems 4))
    , eq "grid viewWithOverflow collapsed cols12 2x span6 -> no overflow"
        False
        (gridOverflow gridCollapseOpts (gridHalfItems 2))
    , eq "grid viewWithOverflow layoutShiftDisabled -> never overflows"
        False
        (gridOverflow gridLayoutShiftOpts (gridHalfItems 10))

    -- 48. NUI.Flex defaults ------------------------------------------------------
    , eq "flex defaults direction = Horizontal" Flex.Horizontal flexDefaults.direction
    , eq "flex defaults size = Medium" Flex.Medium flexDefaults.size
    , eq "flex defaults justify = JustifyStart" Flex.JustifyStart flexDefaults.justify
    , eq "flex defaults wrap = True" True flexDefaults.wrap
    , eq "flex defaults align = Nothing" Nothing flexDefaults.align
    , eq "flex defaults inline = False" False flexDefaults.inline
    , eq "flex defaults reverse = False" False flexDefaults.reverse
    , eq "flex defaults rtl = False" False flexDefaults.rtl

    -- 49. NUI.Highlight helpers --------------------------------------------------
    , eq "highlight escapeRegExp prefixes every regexp metacharacter with a backslash"
        "\\.\\*\\+\\?\\^\\$\\{\\}\\(\\)\\|\\[\\]\\\\"
        (Highlight.escapeRegExp ".*+?^${}()|[]\\")
    , eq "highlight escapeRegExp leaves ordinary characters untouched"
        "abc123 -_/@#%&,"
        (Highlight.escapeRegExp "abc123 -_/@#%&,")
    , eq "highlight escapeRegExp keeps ordinary chars and escapes metachars in place"
        "a\\.b\\*c\\(9\\)"
        (Highlight.escapeRegExp "a.b*c(9)")
    , eq "highlight splitAndMarkByRegex case-sensitive marks only the exact case"
        [ { text = "a", isMatch = False }, { text = "bc", isMatch = True }, { text = "ABC", isMatch = False } ]
        (Highlight.splitAndMarkByRegex "abcABC" [ "bc" ] True True)
    , eq "highlight splitAndMarkByRegex case-insensitive marks every case"
        [ { text = "a", isMatch = False }
        , { text = "bc", isMatch = True }
        , { text = "A", isMatch = False }
        , { text = "BC", isMatch = True }
        ]
        (Highlight.splitAndMarkByRegex "abcABC" [ "bc" ] False True)
    , eq "highlight splitAndMarkByRegex autoEscape=True treats \"a.c\" literally (no match)"
        [ { text = "aXc", isMatch = False } ]
        (Highlight.splitAndMarkByRegex "aXc" [ "a.c" ] False True)
    , eq "highlight splitAndMarkByRegex autoEscape=False lets \"a.c\" match \"aXc\""
        [ { text = "aXc", isMatch = True } ]
        (Highlight.splitAndMarkByRegex "aXc" [ "a.c" ] False False)
    , eq "highlight splitAndMarkByRegex [] patterns -> one unmarked chunk"
        [ { text = "anything", isMatch = False } ]
        (Highlight.splitAndMarkByRegex "anything" [] False True)
    , eq "highlight splitAndMarkByRegex empty text -> []"
        []
        (Highlight.splitAndMarkByRegex "" [ "a" ] False True)
    , eq "highlight splitAndMarkByRegex no match -> one unmarked chunk"
        [ { text = "Hello world", isMatch = False } ]
        (Highlight.splitAndMarkByRegex "Hello world" [ "xyz" ] False True)
    , eq "highlight splitAndMarkByRegex multi-word alternation mirrors upstream"
        [ { text = "The ", isMatch = False }
        , { text = "quick", isMatch = True }
        , { text = " brown ", isMatch = False }
        , { text = "fox", isMatch = True }
        , { text = " jumps over the ", isMatch = False }
        , { text = "lazy", isMatch = True }
        , { text = " dog", isMatch = False }
        ]
        (Highlight.splitAndMarkByRegex "The quick brown fox jumps over the lazy dog" [ "quick", "fox", "lazy" ] False True)
    , eq "highlight splitAndMarkByRegex match at the start"
        [ { text = "hello", isMatch = True }, { text = " world", isMatch = False } ]
        (Highlight.splitAndMarkByRegex "hello world" [ "hello" ] True True)
    , eq "highlight splitAndMarkByRegex match at the end leaves no trailing empty chunk"
        [ { text = "hello ", isMatch = False }, { text = "world", isMatch = True } ]
        (Highlight.splitAndMarkByRegex "hello world" [ "world" ] True True)
    , eq "highlight splitAndMarkByRegex whole-string match -> a single marked chunk"
        [ { text = "hello", isMatch = True } ]
        (Highlight.splitAndMarkByRegex "hello" [ "hello" ] True True)
    , eq "highlight splitAndMarkByRegex escaped \"$\" matches a literal dollar sign"
        [ { text = "Price: ", isMatch = False }, { text = "$100.99", isMatch = True } ]
        (Highlight.splitAndMarkByRegex "Price: $100.99" [ "$100.99" ] True True)
    , eq "highlight splitAndMarkByRegex unicode alternation"
        [ { text = "你好", isMatch = True }
        , { text = "世界 ", isMatch = False }
        , { text = "hello", isMatch = True }
        , { text = " world", isMatch = False }
        ]
        (Highlight.splitAndMarkByRegex "你好世界 hello world" [ "你好", "hello" ] True True)
    , eq "highlight splitAndMarkByRegex invalid pattern (unescaped) -> one unmarked chunk"
        [ { text = "abc", isMatch = False } ]
        (Highlight.splitAndMarkByRegex "abc" [ "(" ] False False)
    , eq "highlight defaults (text)" "" hlD.text
    , eq "highlight defaults (patterns)" [] hlD.patterns
    , eq "highlight defaults (caseSensitive)" False hlD.caseSensitive
    , eq "highlight defaults (autoEscape)" True hlD.autoEscape
    , eq "highlight defaults (highlightTag)" "mark" hlD.highlightTag
    , eq "highlight defaults (highlightClass)" Nothing hlD.highlightClass
    , eq "highlight defaults (highlightStyle)" [] hlD.highlightStyle

    -- 50. NUI.NumberAnimation helpers --------------------------------------------
    , eq "number-animation easeOut 0 = 0" 0 (NumberAnimation.easeOut 0)
    , eq "number-animation easeOut 1 = 1" 1 (NumberAnimation.easeOut 1)
    , eq "number-animation easeOut 0.5 = 1 - 0.5^5 = 0.96875"
        0.96875
        (NumberAnimation.easeOut 0.5)
    , eq "number-animation tweenValue elapsed 0 = from"
        10
        (NumberAnimation.tweenValue { from = 10, to = 110, duration = 1000, elapsed = 0 })
    , eq "number-animation tweenValue elapsed = duration = exactly to"
        110
        (NumberAnimation.tweenValue { from = 10, to = 110, duration = 1000, elapsed = 1000 })
    , eq "number-animation tweenValue elapsed past duration = exactly to"
        110
        (NumberAnimation.tweenValue { from = 10, to = 110, duration = 1000, elapsed = 2500 })
    , eq "number-animation tweenValue duration 0 finishes at once at to"
        110
        (NumberAnimation.tweenValue { from = 10, to = 110, duration = 0, elapsed = 0 })
    , eq "number-animation tweenValue half way = from + (to - from) * easeOut 0.5"
        106.875
        (NumberAnimation.tweenValue { from = 10, to = 110, duration = 1000, elapsed = 500 })
    , eq "number-animation roundTo 2 1.005 = 1.01 (lodash string shift)"
        1.01
        (NumberAnimation.roundTo 2 1.005)
    , eq "number-animation roundTo 0 1234.5678 = 1235"
        1235
        (NumberAnimation.roundTo 0 1234.5678)
    , eq "number-animation roundTo 2 1234.5678 = 1234.57"
        1234.57
        (NumberAnimation.roundTo 2 1234.5678)
    , eq "number-animation roundTo -2 1234 = 1200 (negative precision)"
        1200
        (NumberAnimation.roundTo -2 1234)
    , eq "number-animation roundTo 0 -1.5 = -1 (ties toward +Infinity)"
        -1
        (NumberAnimation.roundTo 0 -1.5)
    , eq "number-animation formatToFixed 0 1234.5678 = \"1235\""
        "1235"
        (NumberAnimation.formatToFixed 0 1234.5678)
    , eq "number-animation formatToFixed 2 1234.5678 = \"1234.57\""
        "1234.57"
        (NumberAnimation.formatToFixed 2 1234.5678)
    , eq "number-animation formatToFixed 2 0 = \"0.00\""
        "0.00"
        (NumberAnimation.formatToFixed 2 0)
    , eq "number-animation formatToFixed 3 0.0005 = \"0.001\""
        "0.001"
        (NumberAnimation.formatToFixed 3 0.0005)
    , eq "number-animation formatToFixed 7 1e-7 = \"0.0000001\" (no exponent form)"
        "0.0000001"
        (NumberAnimation.formatToFixed 7 1.0e-7)
    , eq "number-animation groupDigits \",\" \"1234567\" = \"1,234,567\""
        "1,234,567"
        (NumberAnimation.groupDigits "," "1234567")
    , eq "number-animation groupDigits keeps the leading minus"
        "-1,234,567"
        (NumberAnimation.groupDigits "," "-1234567")
    , eq "number-animation groupDigits leaves three digits ungrouped"
        "123"
        (NumberAnimation.groupDigits "," "123")
    , eq "number-animation groupDigits uses the caller separator"
        "1.234.567"
        (NumberAnimation.groupDigits "." "1234567")
    , eq "number-animation format record shape (precision 2)"
        { integer = "16", decimal = Just "50", decimalSeparator = "." }
        (NumberAnimation.format { naD | to = 16.5, precision = 2, elapsed = 2000 })
    , eq "number-animation format decimal = Nothing at precision 0"
        { integer = "10", decimal = Nothing, decimalSeparator = "." }
        (NumberAnimation.format { naD | from = 10, to = 10, precision = 0 })
    , eq "number-animation format groups the integer and keeps a Just decimal"
        { integer = "1,234,567", decimal = Just "50", decimalSeparator = "." }
        (NumberAnimation.format { naD | from = 1234567.5, to = 1234567.5, precision = 2, showSeparator = True })
    , eq "number-animation format carries the caller decimal separator"
        { integer = "10", decimal = Just "00", decimalSeparator = "," }
        (NumberAnimation.format { naD | from = 10, to = 10, precision = 2, decimalSeparator = "," })

    -- 51. NUI.Icon cssVarsFor ----------------------------------------------------
    , eq "icon cssVarsFor (depth Nothing) keys = bezier + color + opacity"
        [ "--n-bezier", "--n-color", "--n-opacity" ]
        (varKeys iconDefaultVars)
    , eq "icon cssVarsFor depth Nothing keeps --n-bezier"
        (Just light.common.cubicBezierEaseInOut)
        (lookup "--n-bezier" iconDefaultVars)
    , eq "icon cssVarsFor depth Nothing empties --n-color"
        (Just "")
        (lookup "--n-color" iconDefaultVars)
    , eq "icon cssVarsFor depth Nothing empties --n-opacity"
        (Just "")
        (lookup "--n-opacity" iconDefaultVars)
    , eq "icon cssVarsFor depth Just Depth2 --n-color = icon colour (#000)"
        (Just "#000")
        (lookup "--n-color" iconDepthVars)
    , eq "icon cssVarsFor depth Just Depth2 --n-opacity = v.opacity2Depth"
        (Just (IconTheme.vars light).opacity2Depth)
        (lookup "--n-opacity" iconDepthVars)
    , eq "icon cssVarsFor depth Just Depth2 --n-opacity = 0.72"
        (Just "0.72")
        (lookup "--n-opacity" iconDepthVars)
    , eq "icon cssVarsFor depth Just Depth2 keeps --n-bezier"
        (Just "cubic-bezier(.4, 0, .2, 1)")
        (lookup "--n-bezier" iconDepthVars)
    , eq "icon cssVarsFor dark depth Just Depth1 --n-color = #fff"
        (Just "#fff")
        (lookup "--n-color" iconDarkVars)
    , eq "icon cssVarsFor dark depth Just Depth1 --n-opacity = 0.9"
        (Just "0.9")
        (lookup "--n-opacity" iconDarkVars)
    , eq "icon cssVarsFor exact list (depth Nothing)"
        [ ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" ), ( "--n-color", "" ), ( "--n-opacity", "" ) ]
        (Icon.cssVarsFor light iconD)
    , eq "icon cssVarsFor Depth1 opacity = 0.82"
        (Just "0.82")
        (lookup "--n-opacity" (Icon.cssVarsFor light { iconD | depth = Just Icon.Depth1 }))
    , eq "icon cssVarsFor Depth3 opacity = 0.38"
        (Just "0.38")
        (lookup "--n-opacity" (Icon.cssVarsFor light { iconD | depth = Just Icon.Depth3 }))
    , eq "icon cssVarsFor Depth4 opacity = 0.24"
        (Just "0.24")
        (lookup "--n-opacity" (Icon.cssVarsFor light { iconD | depth = Just Icon.Depth4 }))
    , eq "icon cssVarsFor Depth5 opacity = 0.18"
        (Just "0.18")
        (lookup "--n-opacity" (Icon.cssVarsFor light { iconD | depth = Just Icon.Depth5 }))
    , eq "icon defaults depth = Nothing" Nothing iconD.depth
    , eq "icon defaults size = Nothing" Nothing iconD.size
    , eq "icon defaults color = Nothing" Nothing iconD.color

    -- 52. NUI.IconWrapper cssVarsFor ---------------------------------------------
    , eq "icon-wrapper cssVarsFor keys = bezier + color + icon-color"
        [ "--n-bezier", "--n-color", "--n-icon-color" ]
        (varKeys iconWrapperVars)
    , eq "icon-wrapper cssVarsFor --n-bezier = common.easeInOut"
        (Just "cubic-bezier(.4, 0, .2, 1)")
        (lookup "--n-bezier" iconWrapperVars)
    , eq "icon-wrapper cssVarsFor --n-color = primary (#18a058)"
        (Just "#18a058")
        (lookup "--n-color" iconWrapperVars)
    , eq "icon-wrapper cssVarsFor --n-color = vIconWrapperLight.color"
        (Just vIconWrapperLight.color)
        (lookup "--n-color" iconWrapperVars)
    , eq "icon-wrapper cssVarsFor --n-icon-color = baseColor (#FFF)"
        (Just "#FFF")
        (lookup "--n-icon-color" iconWrapperVars)
    , eq "icon-wrapper cssVarsFor dark --n-color = #63e2b7"
        (Just "#63e2b7")
        (lookup "--n-color" iconWrapperDarkVars)
    , eq "icon-wrapper cssVarsFor dark --n-icon-color = #000"
        (Just "#000")
        (lookup "--n-icon-color" iconWrapperDarkVars)
    , eq "icon-wrapper defaults size = Px 24" (IconWrapper.Px 24) iconWrapperD.size
    , eq "icon-wrapper defaults borderRadius = Px 6" (IconWrapper.Px 6) iconWrapperD.borderRadius
    , eq "icon-wrapper defaults color = Nothing" Nothing iconWrapperD.color
    , eq "icon-wrapper defaults iconColor = Nothing" Nothing iconWrapperD.iconColor

    -- 53. NUI.FloatButtonGroup cssVarsFor -----------------------------------------
    , eq "float-button-group cssVarsFor keys"
        [ "--n-bezier", "--n-box-shadow", "--n-color", "--n-button-border-color", "--n-border-radius-square" ]
        (varKeys fbGroupVars)
    , eq "float-button-group cssVarsFor --n-bezier"
        (Just "cubic-bezier(.4, 0, .2, 1)")
        (lookup "--n-bezier" fbGroupVars)
    , eq "float-button-group cssVarsFor --n-box-shadow"
        (Just "0 2px 8px 0px rgba(0, 0, 0, .12)")
        (lookup "--n-box-shadow" fbGroupVars)
    , eq "float-button-group cssVarsFor --n-color = popoverColor (#fff)"
        (Just "#fff")
        (lookup "--n-color" fbGroupVars)
    , eq "float-button-group cssVarsFor --n-button-border-color = dividerColor"
        (Just "rgb(239, 239, 245)")
        (lookup "--n-button-border-color" fbGroupVars)
    , eq "float-button-group cssVarsFor --n-border-radius-square = borderRadius (3px)"
        (Just "3px")
        (lookup "--n-border-radius-square" fbGroupVars)
    , eq "float-button-group cssVarsFor dark --n-color = rgb(72, 72, 78)"
        (Just "rgb(72, 72, 78)")
        (lookup "--n-color" fbGroupDarkVars)
    , eq "float-button-group cssVarsFor dark --n-button-border-color"
        (Just "rgba(255, 255, 255, 0.09)")
        (lookup "--n-button-border-color" fbGroupDarkVars)
    , eq "float-button-group cssVarsFor exact list (light)"
        [ ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
        , ( "--n-box-shadow", "0 2px 8px 0px rgba(0, 0, 0, .12)" )
        , ( "--n-color", "#fff" )
        , ( "--n-button-border-color", "rgb(239, 239, 245)" )
        , ( "--n-border-radius-square", "3px" )
        ]
        (FloatButtonGroup.cssVarsFor light)
    , eq "float-button-group defaults shape = Circle" FloatButton.Circle fbGroupD.shape
    , eq "float-button-group defaults position = Fixed" FloatButton.Fixed fbGroupD.position
    , eq "float-button-group defaults left = Nothing" Nothing fbGroupD.left
    , eq "float-button-group defaults right = Nothing" Nothing fbGroupD.right
    , eq "float-button-group defaults top = Nothing" Nothing fbGroupD.top
    , eq "float-button-group defaults bottom = Nothing" Nothing fbGroupD.bottom

    -- 54. NUI.Heatmap pure core --------------------------------------------------
    , eq "heatmap calcColorByValue maxValue 0 -> colors[0]"
        "#a"
        (Heatmap.calcColorByValue heatmapColors4 (Just 5) 0)
    , eq "heatmap calcColorByValue Nothing -> colors[0]"
        "#a"
        (Heatmap.calcColorByValue heatmapColors4 Nothing 10)
    , eq "heatmap calcColorByValue value 0 -> colors[0]"
        "#a"
        (Heatmap.calcColorByValue heatmapColors4 (Just 0) 10)
    , eq "heatmap calcColorByValue value < 0 -> colors[0]"
        "#a"
        (Heatmap.calcColorByValue heatmapColors4 (Just -3) 10)
    , eq "heatmap calcColorByValue ceil buckets 6/10 over 4 colours -> index 2"
        "#c"
        (Heatmap.calcColorByValue heatmapColors4 (Just 6) 10)
    , eq "heatmap calcColorByValue ceil buckets 3/10 over 4 colours -> index 1 (floor -> 0)"
        "#b"
        (Heatmap.calcColorByValue heatmapColors4 (Just 3) 10)
    , eq "heatmap calcColorByValue exact maxValue -> last colour"
        "#d"
        (Heatmap.calcColorByValue heatmapColors4 (Just 10) 10)
    , eq "heatmap calcColorByValue value > maxValue clamps to last colour"
        "#d"
        (Heatmap.calcColorByValue heatmapColors4 (Just 99) 10)
    , eq "heatmap calcColorByValue single-colour list -> that colour"
        "#only"
        (Heatmap.calcColorByValue [ "#only" ] (Just 5) 10)
    , eq "heatmap calcColorByValue empty list -> \"\" (upstream undefined)"
        ""
        (Heatmap.calcColorByValue [] (Just 5) 10)
    , eq "heatmap completeDataGaps [] -> []"
        []
        (Heatmap.completeDataGaps Time.utc [] 0 False)
    , eq "heatmap completeDataGaps value list (utc: week padding -> Nothing)"
        [ Nothing, Just 5, Just 0, Just 0, Just 0, Just 0, Just 0, Just 3, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing ]
        (heatmapValues heatmapNormUtc)
    , eq "heatmap completeDataGaps span length (utc) = 14"
        14
        (List.length heatmapNormUtc)
    , eq "heatmap completeDataGaps first timestamp = week-start midnight (day-key alignment)"
        (Time.millisToPosix (19722 * 86400000))
        (List.head heatmapNormUtc |> Maybe.map .timestamp |> Maybe.withDefault (Time.millisToPosix -1))
    , eq "heatmap completeDataGaps unsorted input -> same span as sorted"
        (heatmapValues heatmapNormUtc)
        (heatmapValues (Heatmap.completeDataGaps Time.utc (List.reverse heatmapData) 0 False))
    , eq "heatmap completeDataGaps duplicate timestamps last-wins (same day -> no 0-fill)"
        [ Nothing, Just 2, Nothing, Nothing, Nothing, Nothing, Nothing ]
        (heatmapValues heatmapNormDup)
    , eq "heatmap completeDataGaps fillCalendarLeading pads the week start with value 0"
        (Just 0)
        (List.head (heatmapValues heatmapNormFill) |> Maybe.withDefault Nothing)
    , eq "heatmap completeDataGaps fillCalendarLeading leaves the trailing week as Nothing"
        (List.repeat 6 Nothing)
        (List.drop 8 (heatmapValues heatmapNormFill))
    , eq "heatmap completeDataGaps local-day semantics: zone -300 span = 7"
        7
        (List.length heatmapNormPrev)
    , eq "heatmap completeDataGaps local-day semantics: zone -300 shifts the first day onto the data"
        [ Just 5, Just 0, Just 0, Just 0, Just 0, Just 0, Just 3 ]
        (heatmapValues heatmapNormPrev)
    , eq "heatmap createDayRect colIndex = floor(days / 7) across a month boundary"
        1
        heatmapRectFeb.colIndex
    , eq "heatmap createDayRect rowIndex = (getDay - weekStartOn) mod 7"
        1
        heatmapRectFeb.rowIndex
    , eq "heatmap createDayRect colour via calcColorByValue"
        "#c"
        heatmapRectFeb.color
    , eq "heatmap createDayRect same-week item -> col 0"
        0
        heatmapRectWed.colIndex
    , eq "heatmap createDayRect Wednesday rowIndex 3 (weekStartOn 0)"
        3
        heatmapRectWed.rowIndex
    , eq "heatmap createDayRect value 0 -> colors[0]"
        "#a"
        heatmapRectWed.color
    , eq "heatmap createSparseMatrix always 7 rows"
        7
        (List.length heatmapSparse)
    , eq "heatmap createSparseMatrix row0 fills the gap with Nothing"
        (Just [ Just 1, Nothing, Just 2 ])
        (listAt 0 heatmapSparse)
    , eq "heatmap createSparseMatrix empty row -> []"
        (Just [])
        (listAt 1 heatmapSparse)
    , eq "heatmap createSparseMatrix row3 keeps a leading hole"
        (Just [ Nothing, Just 3 ])
        (listAt 3 heatmapSparse)
    , eq "heatmap createSparseMatrix duplicate (row,col) last-wins"
        (Just [ Nothing, Just 2 ])
        (listAt 0 heatmapSparseDup)
    , eq "heatmap createLoadingMatrix 7 rows"
        7
        (List.length heatmapLoading)
    , eq "heatmap createLoadingMatrix 7 x 53"
        (List.repeat 7 53)
        (List.map List.length heatmapLoading)
    , eq "heatmap createLoadingMatrix all cells dead (value 0, #000000, timestamp = now)"
        True
        (List.all
            (\r -> List.all (\c -> c.value == Just 0 && c.color == "#000000" && c.timestamp == heatmapLoadNow) r)
            heatmapLoading
        )
    , eq "heatmap createLoadingMatrix row dayOfWeek = (weekStartOn + row) mod 7"
        (List.map (\row -> modBy 7 (1 + row)) (List.range 0 6))
        (List.map (\r -> r |> List.head |> Maybe.map .dayOfWeek |> Maybe.withDefault -1) heatmapLoading)
    , eq "heatmap createLoadingMatrix row0 colIndex = 0..52"
        (List.range 0 52)
        (List.map .colIndex (Maybe.withDefault [] (listAt 0 heatmapLoading)))
    , eq "heatmap dataMonthLabels [] -> []"
        []
        (Heatmap.dataMonthLabels Time.utc [])
    , eq "heatmap dataMonthLabels empty first row -> []"
        []
        (Heatmap.dataMonthLabels Time.utc [ [] ])
    , eq "heatmap dataMonthLabels <3-column months dropped; colSpan + month sort"
        [ { month = 2, colSpan = 3 }, { month = 3, colSpan = 3 } ]
        (Heatmap.dataMonthLabels Time.utc [ List.map Just heatmapMonthRow ])
    , eq "heatmap dataMonthLabels skips holes scanning down a column"
        [ { month = 1, colSpan = 3 } ]
        (Heatmap.dataMonthLabels Time.utc heatmapHoleMatrix)
    , eq "heatmap dataMonthLabels 6-week range from Jan 1: Jan survives, Feb (1 col) dropped"
        [ { month = 1, colSpan = 5 } ]
        (Heatmap.dataMonthLabels Time.utc heatmap42Matrix)
    , eq "heatmap 6-week pipeline matrix is 7 x 6"
        (List.repeat 7 6)
        (List.map List.length heatmap42Matrix)
    , eq "heatmap loadingMonthLabels months 1..12"
        (List.range 1 12)
        (List.map .month Heatmap.loadingMonthLabels)
    , eq "heatmap loadingMonthLabels fixed colSpans"
        [ 5, 4, 5, 4, 5, 4, 5, 4, 4, 5, 4, 4 ]
        (List.map .colSpan Heatmap.loadingMonthLabels)
    , eq "heatmap loadingMonthLabels colSpans sum to 53 (matrix width)"
        53
        (List.sum (List.map .colSpan Heatmap.loadingMonthLabels))
    , eq "heatmap cssVarsFor exact default list (11 vars, medium)"
        [ ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
        , ( "--n-font-size", "12px" )
        , ( "--n-font-weight", "400" )
        , ( "--n-text-color", "rgb(51, 54, 57)" )
        , ( "--n-border-radius", "2px" )
        , ( "--n-border-color", "#fff" )
        , ( "--n-loading-color-start", "rgba(0, 0, 0, 0.06)" )
        , ( "--n-loading-color-end", "rgba(0, 0, 0, 0.12)" )
        , ( "--n-rect-size", "11px" )
        , ( "--n-x-gap", "3px" )
        , ( "--n-y-gap", "3px" )
        ]
        (Heatmap.cssVarsFor light heatmapD)
    , eq "heatmap cssVarsFor Small --n-rect-size 10px"
        (Just "10px")
        (lookup "--n-rect-size" heatmapVarsSmall)
    , eq "heatmap cssVarsFor Large --n-rect-size 12px"
        (Just "12px")
        (lookup "--n-rect-size" heatmapVarsLarge)
    , eq "heatmap cssVarsFor Small --n-x-gap 2px"
        (Just "2px")
        (lookup "--n-x-gap" heatmapVarsSmall)
    , eq "heatmap cssVarsFor Small --n-y-gap 2px"
        (Just "2px")
        (lookup "--n-y-gap" heatmapVarsSmall)
    , eq "heatmap cssVarsFor Small --n-font-size = fontSizeTiny 12px"
        (Just "12px")
        (lookup "--n-font-size" heatmapVarsSmall)
    , eq "heatmap cssVarsFor Large --n-font-size = fontSizeSmall 14px"
        (Just "14px")
        (lookup "--n-font-size" heatmapVarsLarge)
    , eq "heatmap cssVarsFor explicit xGap wins over the size default"
        (Just "5px")
        (lookup "--n-x-gap" heatmapVarsGap)
    , eq "heatmap cssVarsFor explicit yGap wins over the size default"
        (Just "8px")
        (lookup "--n-y-gap" heatmapVarsGap)
    , eq "heatmap cssVarsFor dark --n-text-color = dark textColor2"
        (Just "rgba(255, 255, 255, 0.82)")
        (lookup "--n-text-color" (Heatmap.cssVarsFor dark heatmapD))
    , eq "heatmap cssVarsFor dark --n-loading-color-start"
        (Just "rgba(255, 255, 255, 0.12)")
        (lookup "--n-loading-color-start" (Heatmap.cssVarsFor dark heatmapD))
    , eq "heatmap defaults data []"
        []
        heatmapD.data
    , eq "heatmap defaults loadingData Nothing"
        Nothing
        heatmapD.loadingData
    , eq "heatmap defaults size Medium"
        Heatmap.Medium
        heatmapD.size
    , eq "heatmap defaults firstDayOfWeek 0"
        0
        heatmapD.firstDayOfWeek
    , eq "heatmap defaults showColorIndicator True"
        True
        heatmapD.showColorIndicator
    , eq "heatmap defaults minimumColor Nothing"
        Nothing
        heatmapD.minimumColor
    , eq "heatmap defaults activeColors Nothing"
        Nothing
        heatmapD.activeColors
    , eq "heatmap defaults colorTheme Nothing"
        Nothing
        heatmapD.colorTheme
    , eq "heatmap defaults indicator labels"
        ( "less", "more" )
        ( heatmapD.indicatorLessText, heatmapD.indicatorMoreText )

    -- 55. NUI.LoadingBar pure state machine -------------------------------------
    , eq "loadingbar init started False" False LoadingBar.init.started
    , eq "loadingbar init status Starting" LoadingBar.Starting LoadingBar.init.status
    , eq "loadingbar init progress 0" 0 LoadingBar.init.progress
    , eq "loadingbar init toProgress 80" 80 LoadingBar.init.toProgress
    , eq "loadingbar init runId 0" 0 LoadingBar.init.runId
    , eq "loadingbar init kicked False" False LoadingBar.init.kicked
    , eq "loadingbar init phase Nothing" Nothing LoadingBar.init.phase
    , eq "loadingbar start sets started" True loadingBarStarting.started
    , eq "loadingbar start resets status Starting" LoadingBar.Starting loadingBarStarting.status
    , eq "loadingbar start progress from 0" 0 loadingBarStarting.progress
    , eq "loadingbar start stages toProgress 80" 80 loadingBarStarting.toProgress
    , eq "loadingbar start bumps runId to 1" 1 loadingBarStarting.runId
    , eq "loadingbar start kicked False" False loadingBarStarting.kicked
    , eq "loadingbar a second start bumps runId to 2" 2 (LoadingBar.start loadingBarStarting).runId
    , eq "loadingbar startFromTo progress 20" 20 loadingBarFromTo.progress
    , eq "loadingbar startFromTo toProgress 60" 60 loadingBarFromTo.toProgress
    , eq "loadingbar startFromTo started" True loadingBarFromTo.started
    , eq "loadingbar startFromTo runId 1" 1 loadingBarFromTo.runId
    , eq "loadingbar kick moves progress to toProgress (80)" 80 loadingBarKicked.progress
    , eq "loadingbar kick sets kicked" True loadingBarKicked.kicked
    , eq "loadingbar kick after startFromTo moves to 60" 60 loadingBarFromToKicked.progress
    , eq "loadingbar finish after started+kicked -> Finishing" LoadingBar.Finishing loadingBarFinishing.status
    , eq "loadingbar finish after started+kicked -> progress 100" 100 loadingBarFinishing.progress
    , eq "loadingbar finish unstarted is a no-op" LoadingBar.init (LoadingBar.finish LoadingBar.init)
    , eq "loadingbar finish from kicked starting -> Finishing" LoadingBar.Finishing (LoadingBar.finish loadingBarKicked).status
    , eq "loadingbar finish from kicked starting -> progress 100" 100 (LoadingBar.finish loadingBarKicked).progress
    , eq "loadingbar finish from idle-error is a no-op (status)" LoadingBar.Erroring (LoadingBar.finish (LoadingBar.error LoadingBar.init)).status
    , eq "loadingbar finish from idle-error keeps progress 100" 100 (LoadingBar.finish (LoadingBar.error LoadingBar.init)).progress
    , eq "loadingbar finish second call keeps progress 100" 100 (LoadingBar.finish loadingBarFinishing).progress
    , eq "loadingbar error mid-Starting -> Erroring" LoadingBar.Erroring (LoadingBar.start LoadingBar.init |> LoadingBar.error).status
    , eq "loadingbar error mid-Starting -> progress 100" 100 (LoadingBar.start LoadingBar.init |> LoadingBar.error).progress
    , eq "loadingbar error mid-Starting keeps runId" 1 (LoadingBar.start LoadingBar.init |> LoadingBar.error).runId
    , eq "loadingbar error from idle -> started" True (LoadingBar.error LoadingBar.init).started
    , eq "loadingbar error from idle -> Erroring" LoadingBar.Erroring (LoadingBar.error LoadingBar.init).status
    , eq "loadingbar error from idle -> progress 100" 100 (LoadingBar.error LoadingBar.init).progress
    , eq "loadingbar error from idle -> toProgress 100" 100 (LoadingBar.error LoadingBar.init).toProgress
    , eq "loadingbar error from idle bumps runId to 1" 1 (LoadingBar.error LoadingBar.init).runId
    , eq "loadingbar error from idle kicked False" False (LoadingBar.error LoadingBar.init).kicked
    , eq "loadingbar error while leaving is a no-op (status)" LoadingBar.Finishing (LoadingBar.error loadingBarLeave).status
    , eq "loadingbar error while leaving keeps progress 100" 100 (LoadingBar.error loadingBarLeave).progress
    , eq "loadingbar error while leaving keeps runId" 1 (LoadingBar.error loadingBarLeave).runId
    , eq "loadingbar error while leave-active is a no-op" 1 (LoadingBar.error { loadingBarFinishing | phase = Just Internal.LeaveActive }).runId
    , eq "loadingbar error with no leave phase restarts the run (guard window divergence)" 2 (LoadingBar.error loadingBarFinishing).runId
    , eq "loadingbar error restart from Finishing -> Erroring" LoadingBar.Erroring (LoadingBar.error loadingBarFinishing).status
    , eq "loadingbar cssVarsFor keys" [ "--n-height", "--n-color-loading", "--n-color-error" ] (varKeys (LoadingBar.cssVarsFor Theme.default))
    , eq "loadingbar cssVarsFor height 2px" (Just "2px") (lookup "--n-height" (LoadingBar.cssVarsFor Theme.default))
    , eq "loadingbar cssVarsFor colorLoading = primary" (Just "#18a058") (lookup "--n-color-loading" (LoadingBar.cssVarsFor Theme.default))
    , eq "loadingbar cssVarsFor colorError" (Just "#d03050") (lookup "--n-color-error" (LoadingBar.cssVarsFor Theme.default))
    , eq "loadingbar cssVarsFor dark colorError red" (Just "red") (lookup "--n-color-error" (LoadingBar.cssVarsFor Theme.dark))
    , eq "loadingbar cssVarsFor dark colorLoading = dark primary" (Just "#63e2b7") (lookup "--n-color-loading" (LoadingBar.cssVarsFor Theme.dark))

    -- 56. NUI.DynamicInput pure list core ---------------------------------------
    , eq "dynamicinput insertAt -1 on empty -> [item]" [ "x" ] (DynamicInput.insertAt -1 "x" [])
    , eq "dynamicinput insertAt -1 on non-empty -> index 0" [ "x", "a", "b" ] (DynamicInput.insertAt -1 "x" [ "a", "b" ])
    , eq "dynamicinput insertAt 0 -> after first" [ "a", "x", "b" ] (DynamicInput.insertAt 0 "x" [ "a", "b" ])
    , eq "dynamicinput insertAt 1 -> appended (index+1 semantics)" [ "a", "b", "x" ] (DynamicInput.insertAt 1 "x" [ "a", "b" ])
    , eq "dynamicinput insertAt past the end appends" [ "a", "b", "x" ] (DynamicInput.insertAt 9 "x" [ "a", "b" ])
    , eq "dynamicinput removeAt 0" [ "b", "c" ] (DynamicInput.removeAt 0 [ "a", "b", "c" ])
    , eq "dynamicinput removeAt 1" [ "a", "c" ] (DynamicInput.removeAt 1 [ "a", "b", "c" ])
    , eq "dynamicinput removeAt last" [ "a", "b" ] (DynamicInput.removeAt 2 [ "a", "b", "c" ])
    , eq "dynamicinput removeAt out of range is a no-op" [ "a", "b" ] (DynamicInput.removeAt 9 [ "a", "b" ])
    , eq "dynamicinput removeAt -1 is a no-op" [ "a", "b" ] (DynamicInput.removeAt -1 [ "a", "b" ])
    , eq "dynamicinput moveUp 0 is a no-op (negative target, the fixed bug)" [ "a", "b", "c" ] (DynamicInput.moveUp 0 [ "a", "b", "c" ])
    , eq "dynamicinput moveUp 1 swaps with 0" [ "b", "a", "c" ] (DynamicInput.moveUp 1 [ "a", "b", "c" ])
    , eq "dynamicinput moveUp last swaps with previous" [ "a", "c", "b" ] (DynamicInput.moveUp 2 [ "a", "b", "c" ])
    , eq "dynamicinput moveDown last is a no-op (out of range target)" [ "a", "b", "c" ] (DynamicInput.moveDown 2 [ "a", "b", "c" ])
    , eq "dynamicinput moveDown 0 swaps with 1" [ "b", "a", "c" ] (DynamicInput.moveDown 0 [ "a", "b", "c" ])
    , eq "dynamicinput moveDown 1 swaps with 2" [ "a", "c", "b" ] (DynamicInput.moveDown 1 [ "a", "b", "c" ])
    , eq "dynamicinput moveUp on empty is a no-op" [] (DynamicInput.moveUp 0 [])
    , eq "dynamicinput moveDown on empty is a no-op" [] (DynamicInput.moveDown 0 [])
    , eq "dynamicinput moveUp single is a no-op" [ "a" ] (DynamicInput.moveUp 0 [ "a" ])
    , eq "dynamicinput moveDown single is a no-op" [ "a" ] (DynamicInput.moveDown 0 [ "a" ])
    , eq "dynamicinput moveUp past the end is a no-op (swap guard)" [ "a", "b" ] (DynamicInput.moveUp 5 [ "a", "b" ])
    , eq "dynamicinput moveDown at the last index is a no-op" [ "a", "b" ] (DynamicInput.moveDown 1 [ "a", "b" ])
    , eq "dynamicinput insertionDisabled max 3 count 3" True (DynamicInput.insertionDisabled (Just 3) 3)
    , eq "dynamicinput insertionDisabled max 3 count 2" False (DynamicInput.insertionDisabled (Just 3) 2)
    , eq "dynamicinput insertionDisabled max 3 count 4" True (DynamicInput.insertionDisabled (Just 3) 4)
    , eq "dynamicinput insertionDisabled Nothing is never disabled" False (DynamicInput.insertionDisabled Nothing 99)
    , eq "dynamicinput removeDisabled min 1 len 1" True (DynamicInput.removeDisabled 1 1)
    , eq "dynamicinput removeDisabled min 1 len 2" False (DynamicInput.removeDisabled 1 2)
    , eq "dynamicinput removeDisabled min 0 len 0" True (DynamicInput.removeDisabled 0 0)
    , eq "dynamicinput removeDisabled min 2 len 2" True (DynamicInput.removeDisabled 2 2)
    , eq "dynamicinput removeDisabled min 2 len 3" False (DynamicInput.removeDisabled 2 3)
    , eq "dynamicinput inputDefaults min 0" 0 DynamicInput.inputDefaults.min
    , eq "dynamicinput inputDefaults max Nothing" Nothing DynamicInput.inputDefaults.max
    , eq "dynamicinput inputDefaults value []" [] DynamicInput.inputDefaults.value
    , eq "dynamicinput inputDefaults showSortButton False" False DynamicInput.inputDefaults.showSortButton
    , eq "dynamicinput pairDefaults value []" [] DynamicInput.pairDefaults.value
    , eq "dynamicinput cssVarsFor keys" [ "--action-margin", "--action-margin-rtl" ] (varKeys (DynamicInput.cssVarsFor Theme.default))
    , eq "dynamicinput cssVarsFor actionMargin" (Just "0 0 0 20px") (lookup "--action-margin" (DynamicInput.cssVarsFor Theme.default))
    , eq "dynamicinput cssVarsFor actionMarginRtl" (Just "0 20px 0 0") (lookup "--action-margin-rtl" (DynamicInput.cssVarsFor Theme.default))

    -- 57. NUI.Form — trigger filter ---------------------------------------------
    , eq "form trigger: manual (Nothing) runs every rule" [ "f is required" ] (fmsgs (fval Nothing [ freq ] (Just (Form.VString ""))))
    , eq "form trigger: manual runs a blur/change-restricted rule" [ "t" ] (fmsgs (fval Nothing [ fbwd ] (Just (Form.VString ""))))
    , eq "form trigger: a trigger-less rule is EXCLUDED under a passed trigger (upstream-exact)" [] (fval (Just Form.OnBlur) [ freq ] (Just (Form.VString "")))
    , eq "form trigger: a trigger-less rule still runs for a manual validate" [ "f is required" ] (fmsgs (fval Nothing [ freq ] (Just (Form.VString ""))))
    , eq "form trigger: membership in (blur)" [ "t" ] (fmsgs (fval (Just Form.OnBlur) [ fbwd ] (Just (Form.VString ""))))
    , eq "form trigger: membership in (change)" [ "t" ] (fmsgs (fval (Just Form.OnChange) [ fbwd ] (Just (Form.VString ""))))
    , eq "form trigger: membership out (input) drops the rule" [] (fval (Just Form.OnInput) [ fbwd ] (Just (Form.VString "")))
    , eq "form trigger: membership out (focus) drops the rule" [] (fval (Just Form.OnFocus) [ fbwd ] (Just (Form.VString "")))
    , eq "form trigger: an empty trigger list never matches" [] (fval (Just Form.OnBlur) [ fstr [] ] (Just (Form.VString "")))
    , eq "form trigger: on-focus membership" [ "t" ] (fmsgs (fval (Just Form.OnFocus) [ fstr [ Form.OnFocus ] ] (Just (Form.VString ""))))

    -- 58. NUI.Form — level partition -------------------------------------------
    , eq "form level: an error suppresses a failing warning" [ { level = Form.ErrorLevel, message = "E" } ] (fval Nothing [ ferr "E", fwarn "W" ] Nothing)
    , eq "form level: the warning loses even when listed first" [ { level = Form.ErrorLevel, message = "E" } ] (fval Nothing [ fwarn "W", ferr "E" ] Nothing)
    , eq "form level: no errors -> the warning surfaces" [ { level = Form.WarningLevel, message = "W" } ] (fval Nothing [ Form.defaultRule, fwarn "W" ] Nothing)
    , eq "form level: warning feedback reports WarningLevel" [ Form.WarningLevel ] (flevels (fval Nothing [ fwarn "W" ] Nothing))
    , eq "form level: rule order is preserved inside the error level" [ "E1", "E2" ] (fmsgs (fval Nothing [ ferr "E1", ferr "E2" ] Nothing))
    , eq "form level: rule order is preserved inside the warning level" [ "W1", "W2" ] (fmsgs (fval Nothing [ fwarn "W1", fwarn "W2" ] Nothing))
    , eq "form level: a warning is dropped entirely once an error exists" 1 (List.length (fval Nothing [ ferr "E", fwarn "W" ] Nothing))

    -- 59. NUI.Form — absent values ---------------------------------------------
    , eq "form absent: Nothing passes a rule without required" [] (fval Nothing [ Form.defaultRule ] Nothing)
    , eq "form absent: VNull is absent too" [] (fval Nothing [ Form.defaultRule ] (Just Form.VNull))
    , eq "form absent: required + Nothing fails" [ "f is required" ] (fmsgs (fval Nothing [ freq ] Nothing))
    , eq "form absent: only required can fail (min/len/pattern/whitespace/enum skip)" [ "f is required" ] (fmsgs (fval Nothing [ { fdflt | required = True, min = Just 5, len = Just 3, pattern = Just "[0-9]+", whitespace = True, enum_ = [ "a" ] } ] Nothing))
    , eq "form absent: non-required skips min/len/pattern/whitespace" [] (fval Nothing [ { fdflt | min = Just 5, len = Just 3, pattern = Just "[0-9]+", whitespace = True } ] Nothing)
    , eq "form absent: required + VNull under an array rule fails" [ "f is required" ] (fmsgs (fval Nothing [ { fdflt | required = True, type_ = Form.TypeArray } ] (Just Form.VNull)))

    -- 60. NUI.Form — required ---------------------------------------------------
    , eq "form required: empty string fails" [ "f is required" ] (fmsgs (fval Nothing [ freq ] (Just (Form.VString ""))))
    , eq "form required: empty array fails (array rule)" [ "f is required" ] (fmsgs (fval Nothing [ { fdflt | required = True, type_ = Form.TypeArray } ] (Just (Form.VArray []))))
    , eq "form required: number 0 passes" [] (fval Nothing [ { fdflt | required = True, type_ = Form.TypeNumber } ] (Just (Form.VNumber 0)))
    , eq "form required: boolean false passes" [] (fval Nothing [ { fdflt | required = True, type_ = Form.TypeBoolean } ] (Just (Form.VBool False)))
    , eq "form required: non-empty string passes" [] (fval Nothing [ freq ] (Just (Form.VString "x")))
    , eq "form required: message=Just is verbatim (no interpolation)" [ "Custom!" ] (fmsgs (fval Nothing [ { freq | message = Just "Custom!" } ] Nothing))
    , eq "form required: the default message interpolates the field name" [ "email is required" ] (fmsgs (fvalAs "email" Nothing [ freq ] Nothing))

    -- 61. NUI.Form — type matrix ------------------------------------------------
    , eq "form type: string x TypeString passes" [] (fval Nothing [ { fdflt | type_ = Form.TypeString } ] (Just (Form.VString "x")))
    , eq "form type: empty string passes TypeString" [] (fval Nothing [ { fdflt | type_ = Form.TypeString } ] (Just (Form.VString "")))
    , eq "form type: string x TypeNumber -> is not a number" [ "f is not a number" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeNumber } ] (Just (Form.VString "x"))))
    , eq "form type: number x TypeNumber passes" [] (fval Nothing [ { fdflt | type_ = Form.TypeNumber } ] (Just (Form.VNumber 5)))
    , eq "form type: number x TypeString -> is not a string" [ "f is not a string" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeString } ] (Just (Form.VNumber 5))))
    , eq "form type: array x TypeArray passes" [] (fval Nothing [ { fdflt | type_ = Form.TypeArray } ] (Just (Form.VArray [ Form.VString "a" ])))
    , eq "form type: string x TypeArray -> is not an array" [ "f is not an array" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeArray } ] (Just (Form.VString "x"))))
    , eq "form type: bool x TypeBoolean passes" [] (fval Nothing [ { fdflt | type_ = Form.TypeBoolean } ] (Just (Form.VBool True)))
    , eq "form type: bool x TypeString -> is not a string" [ "f is not a string" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeString } ] (Just (Form.VBool True))))
    , eq "form type: empty string is NOT empty for a boolean rule" [ "f is not a boolean" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeBoolean } ] (Just (Form.VString ""))))
    , eq "form type: TypeAny runs no type check (every value kind)" [ 0, 0, 0, 0, 0 ] (List.map (\v -> List.length (fval Nothing [ { fdflt | type_ = Form.TypeAny } ] (Just v))) [ Form.VString "x", Form.VNumber 1, Form.VArray [], Form.VBool False, Form.VNull ])
    , eq "form type: empty string under TypeNumber coerces to absent (non-required passes)" [] (fval Nothing [ { fdflt | type_ = Form.TypeNumber } ] (Just (Form.VString "")))
    , eq "form type: empty string under TypeNumber + required fails required only" [ "f is required" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeNumber, required = True } ] (Just (Form.VString ""))))

    -- 62. NUI.Form — range (len/min/max else-if cascade) ------------------------
    , eq "form range: number below min" [ "f cannot be less than 5" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeNumber, min = Just 5 } ] (Just (Form.VNumber 4))))
    , eq "form range: number at min passes" [] (fval Nothing [ { fdflt | type_ = Form.TypeNumber, min = Just 5 } ] (Just (Form.VNumber 5)))
    , eq "form range: number above max" [ "f cannot be greater than 5" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeNumber, max = Just 5 } ] (Just (Form.VNumber 6))))
    , eq "form range: number min+max" [ "f must be between 1 and 5" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeNumber, min = Just 1, max = Just 5 } ] (Just (Form.VNumber 6))))
    , eq "form range: number len" [ "f must equal 3" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeNumber, len = Just 3 } ] (Just (Form.VNumber 4))))
    , eq "form range: len wins over min (else-if cascade)" [ "f must equal 3" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeNumber, len = Just 3, min = Just 1 } ] (Just (Form.VNumber 4))))
    , eq "form range: string below min" [ "f must be at least 3 characters" ] (fmsgs (fval Nothing [ { fdflt | min = Just 3 } ] (Just (Form.VString "ab"))))
    , eq "form range: string at min passes" [] (fval Nothing [ { fdflt | min = Just 3 } ] (Just (Form.VString "abc")))
    , eq "form range: string above max" [ "f cannot be longer than 3 characters" ] (fmsgs (fval Nothing [ { fdflt | max = Just 3 } ] (Just (Form.VString "abcd"))))
    , eq "form range: string min+max" [ "f must be between 1 and 3 characters" ] (fmsgs (fval Nothing [ { fdflt | min = Just 1, max = Just 3 } ] (Just (Form.VString "abcd"))))
    , eq "form range: string len" [ "f must be exactly 3 characters" ] (fmsgs (fval Nothing [ { fdflt | len = Just 3 } ] (Just (Form.VString "abcd"))))
    , eq "form range: astral char counts as one (surrogate-corrected len)" [] (fval Nothing [ { fdflt | len = Just 1 } ] (Just (Form.VString "𠮷")))
    , eq "form range: astral char is length 1 for min too" [ "f must be at least 2 characters" ] (fmsgs (fval Nothing [ { fdflt | min = Just 2 } ] (Just (Form.VString "𠮷"))))
    , eq "form range: array below min" [ "f cannot be less than 2 in length" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeArray, min = Just 2 } ] (Just (Form.VArray [ Form.VString "a" ]))))
    , eq "form range: array above max" [ "f cannot be greater than 2 in length" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeArray, max = Just 2 } ] (Just (Form.VArray [ Form.VString "a", Form.VString "b", Form.VString "c" ]))))
    , eq "form range: array min+max" [ "f must be between 1 and 2 in length" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeArray, min = Just 1, max = Just 2 } ] (Just (Form.VArray [ Form.VString "a", Form.VString "b", Form.VString "c" ]))))
    , eq "form range: array len" [ "f must be exactly 2 in length" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeArray, len = Just 2 } ] (Just (Form.VArray [ Form.VString "a" ]))))
    , eq "form range: an empty array is NOT skipped (min runs on [])" [ "f cannot be less than 3 in length" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeArray, min = Just 3 } ] (Just (Form.VArray []))))
    , eq "form range: an empty array + required fails required (not range)" [ "f is required" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeArray, required = True, min = Just 3 } ] (Just (Form.VArray []))))
    , eq "form range: an empty array + satisfiable max passes when not required" [] (fval Nothing [ { fdflt | type_ = Form.TypeArray, max = Just 3 } ] (Just (Form.VArray [])))
    , eq "form range: skipped for booleans" [] (fval Nothing [ { fdflt | type_ = Form.TypeBoolean, min = Just 5 } ] (Just (Form.VBool True)))
    , eq "form range: two checks fail in one rule (type + range)" [ "f is not a string", "f cannot be less than 5" ] (fmsgs (fval Nothing [ { fdflt | min = Just 5 } ] (Just (Form.VNumber 4))))
    , eq "form range: message=Just collapses two failures into one verbatim line" [ "custom" ] (fmsgs (fval Nothing [ { fdflt | min = Just 5, message = Just "custom" } ] (Just (Form.VNumber 4))))

    -- 63. NUI.Form — enum --------------------------------------------------------
    , eq "form enum: member passes" [] (fval Nothing [ { fdflt | type_ = Form.TypeEnum, enum_ = [ "a", "b" ] } ] (Just (Form.VString "a")))
    , eq "form enum: non-member fails with the joined list" [ "f must be one of a, b" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeEnum, enum_ = [ "a", "b" ] } ] (Just (Form.VString "c"))))
    , eq "form enum: three entries join with ', '" [ "f must be one of red, green, blue" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeEnum, enum_ = [ "red", "green", "blue" ] } ] (Just (Form.VString "pink"))))
    , eq "form enum: a non-string value is not a member" [ "f must be one of a, b" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeEnum, enum_ = [ "a", "b" ] } ] (Just (Form.VNumber 1))))
    , eq "form enum: an empty list is ACTIVE and always fails (trailing space)" [ "f must be one of " ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeEnum, enum_ = [] } ] (Just (Form.VString "x"))))
    , eq "form enum: empty string is NOT empty for an enum (fails membership)" [ "f must be one of a, b" ] (fmsgs (fval Nothing [ { fdflt | type_ = Form.TypeEnum, enum_ = [ "a", "b" ] } ] (Just (Form.VString ""))))
    , eq "form enum: an absent value + non-required skips the check" [] (fval Nothing [ { fdflt | type_ = Form.TypeEnum, enum_ = [ "a", "b" ] } ] Nothing)

    -- 64. NUI.Form — whitespace --------------------------------------------------
    , eq "form whitespace: all-whitespace fails with cannot be empty" [ "f cannot be empty" ] (fmsgs (fval Nothing [ { fdflt | whitespace = True } ] (Just (Form.VString "   "))))
    , eq "form whitespace: whitespace around a word passes" [] (fval Nothing [ { fdflt | whitespace = True } ] (Just (Form.VString " x ")))
    , eq "form whitespace: empty string never reaches the whitespace check" [] (fval Nothing [ { fdflt | whitespace = True } ] (Just (Form.VString "")))
    , eq "form whitespace: empty + required yields only is-required" [ "f is required" ] (fmsgs (fval Nothing [ { fdflt | whitespace = True, required = True } ] (Just (Form.VString ""))))
    , eq "form whitespace: ignored under TypeNumber" [] (fval Nothing [ { fdflt | type_ = Form.TypeNumber, whitespace = True } ] (Just (Form.VNumber 1)))

    -- 65. NUI.Form — pattern -----------------------------------------------------
    , eq "form pattern: a match passes" [] (fval Nothing [ { fdflt | pattern = Just "[0-9]+" } ] (Just (Form.VString "123")))
    , eq "form pattern: a mismatch carries field, value and source" [ "f value abc does not match pattern [0-9]+" ] (fmsgs (fval Nothing [ { fdflt | pattern = Just "[0-9]+" } ] (Just (Form.VString "abc"))))
    , eq "form pattern: a non-string value fails the rule" True (not (List.isEmpty (fval Nothing [ { fdflt | pattern = Just "[0-9]+" } ] (Just (Form.VNumber 1)))))
    , eq "form pattern: an uncompilable source fails loudly (default message)" [ "Validation error on field f" ] (fmsgs (fval Nothing [ { fdflt | pattern = Just "[" } ] (Just (Form.VString "x"))))
    , eq "form pattern: uncompilable + message=Just is verbatim" [ "bad" ] (fmsgs (fval Nothing [ { fdflt | pattern = Just "[", message = Just "bad" } ] (Just (Form.VString "x"))))
    , eq "form pattern: the uncompilable default message interpolates the field" [ "Validation error on field age" ] (fmsgs (fvalAs "age" Nothing [ { fdflt | pattern = Just "[" } ] (Just (Form.VString "x"))))
    , eq "form pattern: absent value passes when not required" [] (fval Nothing [ { fdflt | pattern = Just "[0-9]+" } ] Nothing)

    -- 66. NUI.Form — custom validator -------------------------------------------
    , eq "form validator: False yields field ++ ' fails'" [ "f fails" ] (fmsgs (fval Nothing [ { fdflt | validator = Just (\_ -> False) } ] (Just (Form.VString "x"))))
    , eq "form validator: False + message=Just is verbatim" [ "nope" ] (fmsgs (fval Nothing [ { fdflt | validator = Just (\_ -> False), message = Just "nope" } ] (Just (Form.VString "x"))))
    , eq "form validator: True passes" [] (fval Nothing [ { fdflt | validator = Just (\_ -> True) } ] (Just (Form.VString "x")))
    , eq "form validator: replaces the structural checks (required + min ignored)" [] (fval Nothing [ { fdflt | validator = Just (\_ -> True), required = True, min = Just 5 } ] (Just (Form.VString "abc")))
    , eq "form validator: sees the value (pass)" [] (fval Nothing [ { fdflt | validator = Just (\v -> v == Form.VNumber 5) } ] (Just (Form.VNumber 5)))
    , eq "form validator: sees the value (fail)" [ "f fails" ] (fmsgs (fval Nothing [ { fdflt | validator = Just (\v -> v == Form.VNumber 5) } ] (Just (Form.VNumber 6))))
    , eq "form validator: runs for an absent value too" [ "z" ] (fmsgs (fval Nothing [ { fdflt | validator = Just (\_ -> False), message = Just "z" } ] Nothing))
    , eq "form validator: the trigger filter still applies" [] (fval (Just Form.OnInput) [ { fdflt | validator = Just (\_ -> False), trigger = Just [ Form.OnBlur ] } ] (Just (Form.VString "x")))

    -- 67. NUI.Form — isRequired -------------------------------------------------
    , eq "form isRequired: empty list is False" False (Form.isRequired [])
    , eq "form isRequired: no required rule is False" False (Form.isRequired [ Form.defaultRule ])
    , eq "form isRequired: a required rule is True" True (Form.isRequired [ { fdflt | required = True } ])
    , eq "form isRequired: any required rule wins" True (Form.isRequired [ Form.defaultRule, { fdflt | required = True } ])
    , eq "form isRequired: message/validator alone do not set it" False (Form.isRequired [ { fdflt | message = Just "x", validator = Just (\_ -> False) } ])

    -- 68. NUI.Form — validateForm ------------------------------------------------
    , eq "form validateForm: no filter -> every path, Rules order" [ ( "a", [] ), ( "b", [ { level = Form.ErrorLevel, message = "b-req" } ] ), ( "c", [] ) ] (Form.validateForm Nothing Nothing formRules formValues)
    , eq "form validateForm: the paths filter keeps Rules order, not filter order" [ "a", "c" ] (List.map Tuple.first (Form.validateForm Nothing (Just [ "c", "a" ]) formRules formValues))
    , eq "form validateForm: a single filtered path" [ ( "b", [ { level = Form.ErrorLevel, message = "b-req" } ] ) ] (Form.validateForm Nothing (Just [ "b" ]) formRules formValues)
    , eq "form validateForm: a valid filtered path is emitted empty" [ ( "c", [] ) ] (Form.validateForm Nothing (Just [ "c" ]) formRules formValues)
    , eq "form validateForm: unknown filtered paths are not emitted" [] (Form.validateForm Nothing (Just [ "zz" ]) formRules formValues)
    , eq "form validateForm: value lookup is first-match-wins" [ ( "a", [ { level = Form.ErrorLevel, message = "a-req" } ] ) ] (Form.validateForm Nothing Nothing [ ( "a", [ ferr "a-req" ] ) ] [ ( "a", Form.VString "" ), ( "a", Form.VString "x" ) ])
    , eq "form validateForm: first-match-wins (a valid first entry)" [ ( "a", [] ) ] (Form.validateForm Nothing Nothing [ ( "a", [ ferr "a-req" ] ) ] [ ( "a", Form.VString "x" ), ( "a", Form.VString "" ) ])
    , eq "form validateForm: a missing value entry is absent (path is the field name)" [ ( "a", [ { level = Form.ErrorLevel, message = "a is required" } ] ) ] (Form.validateForm Nothing Nothing [ ( "a", [ freq ] ) ] [])
    , eq "form validateForm: the trigger filter threads through (no match)" [ ( "a", [] ) ] (Form.validateForm (Just Form.OnChange) Nothing [ ( "a", [ { freq | trigger = Just [ Form.OnBlur ], message = Just "a-blur" } ] ) ] [ ( "a", Form.VString "" ) ])
    , eq "form validateForm: the trigger filter threads through (match)" [ ( "a", [ { level = Form.ErrorLevel, message = "a-blur" } ] ) ] (Form.validateForm (Just Form.OnBlur) Nothing [ ( "a", [ { freq | trigger = Just [ Form.OnBlur ], message = Just "a-blur" } ] ) ] [ ( "a", Form.VString "" ) ])
    , eq "form validateForm: each path keeps its own level partition" [ ( "w", [ { level = Form.WarningLevel, message = "w1" } ] ), ( "e", [ { level = Form.ErrorLevel, message = "e1" } ] ) ] (Form.validateForm Nothing Nothing [ ( "w", [ fwarn "w1" ] ), ( "e", [ ferr "e1" ] ) ] [])

    -- 69. NUI.Form — cssVarsForItem ---------------------------------------------
    , eq "form vars: the 16 upstream keys (sorted)" formItemVarKeys (List.sort (varKeys (Form.cssVarsForItem light Form.itemDefaults)))
    , eq "form vars: count is 16" 16 (List.length (Form.cssVarsForItem light Form.itemDefaults))
    , eq "form vars: bezier" (Just "cubic-bezier(.4, 0, .2, 1)") (fvar light Form.itemDefaults "--n-bezier")
    , eq "form vars: line-height" (Just "1.6") (fvar light Form.itemDefaults "--n-line-height")
    , eq "form vars: medium blank height" (Just "34px") (fvar light Form.itemDefaults "--n-blank-height")
    , eq "form vars: medium label height" (Just "26px") (fvar light Form.itemDefaults "--n-label-height")
    , eq "form vars: top+medium label font size" (Just "14px") (fvar light Form.itemDefaults "--n-label-font-size")
    , eq "form vars: top label text align defaults to flex-start" (Just "flex-start") (fvar light Form.itemDefaults "--n-label-text-align")
    , eq "form vars: top label padding is the vertical one" (Just "0 0 6px 2px") (fvar light Form.itemDefaults "--n-label-padding")
    , eq "form vars: label font weight" (Just "400") (fvar light Form.itemDefaults "--n-label-font-weight")
    , eq "form vars: asterisk color" (Just "#d03050") (fvar light Form.itemDefaults "--n-asterisk-color")
    , eq "form vars: label text color" (Just "rgb(31, 34, 37)") (fvar light Form.itemDefaults "--n-label-text-color")
    , eq "form vars: feedback padding" (Just "4px 0 0 2px") (fvar light Form.itemDefaults "--n-feedback-padding")
    , eq "form vars: medium feedback font size" (Just "14px") (fvar light Form.itemDefaults "--n-feedback-font-size")
    , eq "form vars: medium feedback height" (Just "24px") (fvar light Form.itemDefaults "--n-feedback-height")
    , eq "form vars: feedback text color" (Just "rgb(118, 124, 130)") (fvar light Form.itemDefaults "--n-feedback-text-color")
    , eq "form vars: feedback warning color" (Just "#f0a020") (fvar light Form.itemDefaults "--n-feedback-text-color-warning")
    , eq "form vars: feedback error color" (Just "#d03050") (fvar light Form.itemDefaults "--n-feedback-text-color-error")
    , eq "form vars: small blank height" (Just "28px") (fvar light { fditem | size = Form.Small } "--n-blank-height")
    , eq "form vars: small label height" (Just "24px") (fvar light { fditem | size = Form.Small } "--n-label-height")
    , eq "form vars: small top label font size" (Just "13px") (fvar light { fditem | size = Form.Small } "--n-label-font-size")
    , eq "form vars: small feedback font size" (Just "13px") (fvar light { fditem | size = Form.Small } "--n-feedback-font-size")
    , eq "form vars: large blank height" (Just "40px") (fvar light { fditem | size = Form.Large } "--n-blank-height")
    , eq "form vars: large label height" (Just "28px") (fvar light { fditem | size = Form.Large } "--n-label-height")
    , eq "form vars: large feedback height" (Just "26px") (fvar light { fditem | size = Form.Large } "--n-feedback-height")
    , eq "form vars: left medium label font size" (Just "14px") (fvar light { fditem | labelPlacement = Just Form.Left } "--n-label-font-size")
    , eq "form vars: left label padding is the horizontal one" (Just "0 12px 0 0") (fvar light { fditem | labelPlacement = Just Form.Left } "--n-label-padding")
    , eq "form vars: left label text align is right" (Just "right") (fvar light { fditem | labelPlacement = Just Form.Left } "--n-label-text-align")
    , eq "form vars: left small label font size" (Just "14px") (fvar light { fditem | labelPlacement = Just Form.Left, size = Form.Small } "--n-label-font-size")
    , eq "form vars: left large label font size" (Just "15px") (fvar light { fditem | labelPlacement = Just Form.Left, size = Form.Large } "--n-label-font-size")
    , eq "form vars: top + align right becomes flex-end" (Just "flex-end") (fvar light { fditem | labelAlign = Just Form.AlignRight } "--n-label-text-align")
    , eq "form vars: top + align center stays flex-start (upstream override)" (Just "flex-start") (fvar light { fditem | labelAlign = Just Form.AlignCenter } "--n-label-text-align")
    , eq "form vars: top + align left is flex-start" (Just "flex-start") (fvar light { fditem | labelAlign = Just Form.AlignLeft } "--n-label-text-align")
    , eq "form vars: left + align left is left" (Just "left") (fvar light { fditem | labelPlacement = Just Form.Left, labelAlign = Just Form.AlignLeft } "--n-label-text-align")
    , eq "form vars: left + align center is center" (Just "center") (fvar light { fditem | labelPlacement = Just Form.Left, labelAlign = Just Form.AlignCenter } "--n-label-text-align")
    , eq "form vars: dark asterisk color" (Just "#e88080") (fvar dark Form.itemDefaults "--n-asterisk-color")
    , eq "form vars: dark label text color" (Just "rgba(255, 255, 255, 0.9)") (fvar dark Form.itemDefaults "--n-label-text-color")
    , eq "form vars: dark feedback error color" (Just "#e88080") (fvar dark Form.itemDefaults "--n-feedback-text-color-error")
    , eq "form vars: itemDefaults size is medium" Form.Medium Form.itemDefaults.size
    , eq "form vars: itemDefaults showFeedback defaults True" True Form.itemDefaults.showFeedback
    , eq "form vars: itemDefaults requireMarkPlacement defaults right" Form.MarkRight Form.itemDefaults.requireMarkPlacement
    , eq "form vars: itemDefaults labelPlacement defaults Nothing" Nothing Form.itemDefaults.labelPlacement
    , eq "form vars: itemDefaults validation defaults Nothing" Nothing Form.itemDefaults.validation
    , eq "form vars: Form.defaults.inline is False" False Form.defaults.inline
    , eq "form vars: Form.defaults.onSubmit is Nothing" Nothing Form.defaults.onSubmit

    -- descriptions: defaults -------------------------------------------------
    , eq "desc defaults: column" 3 ddflt.column
    , eq "desc defaults: columns Nothing" Nothing ddflt.columns
    , eq "desc defaults: labelPlacement top" Descriptions.Top ddflt.labelPlacement
    , eq "desc defaults: labelAlign left" Descriptions.AlignLeft ddflt.labelAlign
    , eq "desc defaults: separator" ":" ddflt.separator
    , eq "desc defaults: size medium" Descriptions.Medium ddflt.size
    , eq "desc defaults: bordered False" False ddflt.bordered
    , eq "desc defaults: title Nothing" Nothing ddflt.title
    , eq "desc item defaults: span" 1 ditem.span
    , eq "desc item defaults: label Nothing" Nothing ditem.label
    , eq "desc item defaults: content empty" [] ditem.content

    -- descriptions: resolvedColumns ------------------------------------------
    , eq "desc resolvedColumns: column when columns Nothing" 3 (Descriptions.resolvedColumns ddflt)
    , eq "desc resolvedColumns: columns wins" 4 (Descriptions.resolvedColumns { ddflt | columns = Just 4 })

    -- descriptions: engine (row packing + colspans) --------------------------
    , eq "desc layout top 4x1 col3" "H0:2,H1:2,H2:2|C0:2,C1:2,C2:2|H3:6|C3:6" (dlayout 3 Descriptions.Top False [ 1, 1, 1, 1 ])
    , eq "desc layout left 4x1 col3" "K0:2,K1:2,K2:2|K3:6" (dlayout 3 Descriptions.Left False [ 1, 1, 1, 1 ])
    , eq "desc layout left-bordered 4x1 col3" "H0:1,C0:1,H1:1,C1:1,H2:1,C2:1|H3:1,C3:7" (dlayout 3 Descriptions.Left True [ 1, 1, 1, 1 ])
    , eq "desc layout top single item spans the row" "H0:6|C0:6" (dlayout 3 Descriptions.Top False [ 1 ])
    , eq "desc layout no items -> no rows" "" (dlayout 3 Descriptions.Top False [])
    , eq "desc layout top last item absorbs remainder" "H0:2,H1:4|C0:2,C1:4" (dlayout 3 Descriptions.Top False [ 1, 1 ])
    , eq "desc layout top span2 mid-row" "H0:2,H1:4|C0:2,C1:4" (dlayout 3 Descriptions.Top False [ 1, 2 ])
    , eq "desc layout left last cell absorbs remainder" "K0:2,K1:4" (dlayout 3 Descriptions.Left False [ 1, 2 ])
    , eq "desc layout left-bordered span2" "H0:1,C0:1,H1:1,C1:5" (dlayout 3 Descriptions.Left True [ 1, 2 ])
    , eq "desc layout col4 4x1 is one logical row" "H0:2,H1:2,H2:2,H3:2|C0:2,C1:2,C2:2,C3:2" (dlayout 4 Descriptions.Top False [ 1, 1, 1, 1 ])
    , eq "desc layout col1 forces a row per item" "H0:2|C0:2|H1:2|C1:2" (dlayout 1 Descriptions.Top False [ 1, 1 ])

    -- descriptions: cssVars (theme math) -------------------------------------
    , eq "desc vars: 19 keys in upstream order"
        [ "--n-title-text-color", "--n-th-padding", "--n-td-padding", "--n-font-size", "--n-bezier", "--n-th-font-weight", "--n-line-height", "--n-th-text-color", "--n-td-text-color", "--n-th-color", "--n-th-color-modal", "--n-th-color-popover", "--n-td-color", "--n-td-color-modal", "--n-td-color-popover", "--n-border-radius", "--n-border-color", "--n-border-color-modal", "--n-border-color-popover" ]
        (varKeys (Descriptions.cssVars light ddflt))
    , eq "desc vars: title text color = textColor1" (Just "rgb(31, 34, 37)") (dvar light ddflt "--n-title-text-color")
    , eq "desc vars: medium th padding (non-bordered) = 0" (Just "0") (dvar light ddflt "--n-th-padding")
    , eq "desc vars: medium td padding (non-bordered)" (Just "0 0 12px 0") (dvar light ddflt "--n-td-padding")
    , eq "desc vars: medium bordered th padding" (Just "12px 16px") (dvar light { ddflt | bordered = True } "--n-th-padding")
    , eq "desc vars: medium bordered td padding" (Just "12px 16px") (dvar light { ddflt | bordered = True } "--n-td-padding")
    , eq "desc vars: small bordered th padding" (Just "8px 12px") (dvar light { ddflt | bordered = True, size = Descriptions.Small } "--n-th-padding")
    , eq "desc vars: large bordered td padding" (Just "16px 24px") (dvar light { ddflt | bordered = True, size = Descriptions.Large } "--n-td-padding")
    , eq "desc vars: medium font size" (Just "14px") (dvar light ddflt "--n-font-size")
    , eq "desc vars: large font size" (Just "15px") (dvar light { ddflt | size = Descriptions.Large } "--n-font-size")
    , eq "desc vars: bezier" (Just "cubic-bezier(.4, 0, .2, 1)") (dvar light ddflt "--n-bezier")
    , eq "desc vars: th font weight" (Just "500") (dvar light ddflt "--n-th-font-weight")
    , eq "desc vars: line height" (Just "1.6") (dvar light ddflt "--n-line-height")
    , eq "desc vars: th text color = textColor1" (Just "rgb(31, 34, 37)") (dvar light ddflt "--n-th-text-color")
    , eq "desc vars: td text color = textColor2" (Just "rgb(51, 54, 57)") (dvar light ddflt "--n-td-text-color")
    , eq "desc vars: th color = composite(cardColor, tableHeaderColor)" (Just "rgba(250, 250, 252, 1)") (dvar light ddflt "--n-th-color")
    , eq "desc vars: td color = cardColor" (Just "#fff") (dvar light ddflt "--n-td-color")
    , eq "desc vars: border radius" (Just "3px") (dvar light ddflt "--n-border-radius")
    , eq "desc vars: border color = composite(cardColor, dividerColor)" (Just "rgba(239, 239, 245, 1)") (dvar light ddflt "--n-border-color")
    , eq "desc vars: dark th color" (Just "rgba(38, 38, 42, 1)") (dvar dark ddflt "--n-th-color")
    , eq "desc vars: dark border color" (Just "rgba(45, 45, 48, 1)") (dvar dark ddflt "--n-border-color")
    , eq "desc vars: dark title text color" (Just "rgba(255, 255, 255, 0.9)") (dvar dark ddflt "--n-title-text-color")

    -- tabs: defaults --------------------------------------------------------
    , eq "tab defaults: type bar" Tabs.Bar tdefault.type_
    , eq "tab defaults: size medium" Tabs.Medium tdefault.size
    , eq "tab defaults: placement top" Tabs.Top tdefault.placement
    , eq "tab defaults: value" "a" tdefault.value
    , eq "tab defaults: justifyContent Nothing" Nothing tdefault.justifyContent
    , eq "tab defaults: closable False" False tdefault.closable
    , eq "tab defaults: addable False" False tdefault.addable
    , eq "tab defaults: trigger click" Tabs.Click tdefault.trigger
    , eq "tab defaults: displayDirective ShowIf" Tabs.ShowIf tdefault.displayDirective
    , eq "tab defaults: rtl False" False tdefault.rtl
    , eq "tab defaults: prefix Nothing" Nothing tdefault.prefix
    , eq "tab defaults: suffix Nothing" Nothing tdefault.suffix
    , eq "tab defaults: onChange Nothing" Nothing tdefault.onChange
    , eq "tab defaults: onClose Nothing" Nothing tdefault.onClose
    , eq "tab defaults: onAdd Nothing" Nothing tdefault.onAdd

    -- tabs: cssVars (theme math) -------------------------------------------
    , eq "tab vars: 32 keys in upstream order"
        [ "--n-bezier", "--n-color-segment", "--n-bar-color", "--n-tab-font-size", "--n-tab-text-color", "--n-tab-text-color-active", "--n-tab-text-color-disabled", "--n-tab-text-color-hover", "--n-pane-text-color", "--n-tab-border-color", "--n-tab-border-radius", "--n-close-size", "--n-close-icon-size", "--n-close-color-hover", "--n-close-color-pressed", "--n-close-border-radius", "--n-close-icon-color", "--n-close-icon-color-hover", "--n-close-icon-color-pressed", "--n-tab-color", "--n-tab-font-weight", "--n-tab-font-weight-active", "--n-tab-padding", "--n-tab-padding-vertical", "--n-tab-gap", "--n-tab-gap-vertical", "--n-pane-padding-left", "--n-pane-padding-right", "--n-pane-padding-top", "--n-pane-padding-bottom", "--n-font-weight-strong", "--n-tab-color-segment" ]
        (varKeys (Tabs.cssVars light tdefault))
    , eq "tab vars: bezier" (Just "cubic-bezier(.4, 0, .2, 1)") (tvar light tdefault "--n-bezier")
    , eq "tab vars: color-segment = light tabColor" (Just "rgb(247, 247, 250)") (tvar light tdefault "--n-color-segment")
    , eq "tab vars: bar-color = primaryColor" (Just "#18a058") (tvar light tdefault "--n-bar-color")
    , eq "tab vars: tab-font-size medium" (Just "14px") (tvar light tdefault "--n-tab-font-size")
    , eq "tab vars: tab-font-size small" (Just "14px") (tvar light tSmallOpts "--n-tab-font-size")
    , eq "tab vars: tab-font-size large" (Just "16px") (tvar light tLargeOpts "--n-tab-font-size")
    , eq "tab vars: bar text color = textColor1" (Just "rgb(31, 34, 37)") (tvar light tdefault "--n-tab-text-color")
    , eq "tab vars: bar active text color = primaryColor" (Just "#18a058") (tvar light tdefault "--n-tab-text-color-active")
    , eq "tab vars: bar hover text color = primaryColor" (Just "#18a058") (tvar light tdefault "--n-tab-text-color-hover")
    , eq "tab vars: bar disabled text color" (Just "rgba(194, 194, 194, 1)") (tvar light tdefault "--n-tab-text-color-disabled")
    , eq "tab vars: segment active text color = textColor2" (Just "rgb(51, 54, 57)") (tvar light tSegmentOpts "--n-tab-text-color-active")
    , eq "tab vars: line text color = textColor1" (Just "rgb(31, 34, 37)") (tvar light tLineOpts "--n-tab-text-color")
    , eq "tab vars: card text color = textColor1" (Just "rgb(31, 34, 37)") (tvar light tCardOpts "--n-tab-text-color")
    , eq "tab vars: pane text color = textColor2" (Just "rgb(51, 54, 57)") (tvar light tdefault "--n-pane-text-color")
    , eq "tab vars: tab border color = dividerColor" (Just "rgb(239, 239, 245)") (tvar light tdefault "--n-tab-border-color")
    , eq "tab vars: tab border radius" (Just "3px") (tvar light tdefault "--n-tab-border-radius")
    , eq "tab vars: close size" (Just "18px") (tvar light tdefault "--n-close-size")
    , eq "tab vars: close icon size" (Just "14px") (tvar light tdefault "--n-close-icon-size")
    , eq "tab vars: close color hover" (Just "rgba(0, 0, 0, .09)") (tvar light tdefault "--n-close-color-hover")
    , eq "tab vars: close color pressed" (Just "rgba(0, 0, 0, .13)") (tvar light tdefault "--n-close-color-pressed")
    , eq "tab vars: close border radius" (Just "3px") (tvar light tdefault "--n-close-border-radius")
    , eq "tab vars: close icon color" (Just "rgba(102, 102, 102, 1)") (tvar light tdefault "--n-close-icon-color")
    , eq "tab vars: close icon color hover" (Just "rgba(102, 102, 102, 1)") (tvar light tdefault "--n-close-icon-color-hover")
    , eq "tab vars: close icon color pressed" (Just "rgba(102, 102, 102, 1)") (tvar light tdefault "--n-close-icon-color-pressed")
    , eq "tab vars: tab color = tabColor" (Just "rgb(247, 247, 250)") (tvar light tdefault "--n-tab-color")
    , eq "tab vars: tab font weight" (Just "400") (tvar light tdefault "--n-tab-font-weight")
    , eq "tab vars: tab font weight active" (Just "400") (tvar light tdefault "--n-tab-font-weight-active")
    , eq "tab vars: medium bar padding" (Just "6px 0") (tvar light tdefault "--n-tab-padding")
    , eq "tab vars: medium bar padding vertical" (Just "8px 16px") (tvar light tdefault "--n-tab-padding-vertical")
    , eq "tab vars: medium bar gap" (Just "36px") (tvar light tdefault "--n-tab-gap")
    , eq "tab vars: medium bar gap vertical" (Just "8px") (tvar light tdefault "--n-tab-gap-vertical")
    , eq "tab vars: medium line padding" (Just "10px 0") (tvar light tLineOpts "--n-tab-padding")
    , eq "tab vars: medium card padding" (Just "10px 20px") (tvar light tCardOpts "--n-tab-padding")
    , eq "tab vars: medium card gap" (Just "4px") (tvar light tCardOpts "--n-tab-gap")
    , eq "tab vars: medium segment padding" (Just "6px 0") (tvar light tSegmentOpts "--n-tab-padding")
    , eq "tab vars: medium segment gap" (Just "0") (tvar light tSegmentOpts "--n-tab-gap")
    , eq "tab vars: small bar padding" (Just "4px 0") (tvar light tSmallOpts "--n-tab-padding")
    , eq "tab vars: large bar padding" (Just "10px 0") (tvar light tLargeOpts "--n-tab-padding")
    , eq "tab vars: small pane padding top" (Just "8px") (tvar light tSmallOpts "--n-pane-padding-top")
    , eq "tab vars: medium pane padding top" (Just "12px") (tvar light tdefault "--n-pane-padding-top")
    , eq "tab vars: large pane padding top" (Just "16px") (tvar light tLargeOpts "--n-pane-padding-top")
    , eq "tab vars: pane padding left (from shorthand)" (Just "0") (tvar light tdefault "--n-pane-padding-left")
    , eq "tab vars: pane padding right (from shorthand)" (Just "0") (tvar light tdefault "--n-pane-padding-right")
    , eq "tab vars: pane padding bottom (from shorthand)" (Just "0") (tvar light tdefault "--n-pane-padding-bottom")
    , eq "tab vars: font weight strong" (Just "500") (tvar light tdefault "--n-font-weight-strong")
    , eq "tab vars: tab color segment = baseColor" (Just "#FFF") (tvar light tdefault "--n-tab-color-segment")
    , eq "tab vars: dark color-segment = dark inputColor" (Just "rgba(255, 255, 255, 0.1)") (tvar dark tdefault "--n-color-segment")
    , eq "tab vars: dark tab color segment = dark inputColor" (Just "rgba(255, 255, 255, 0.1)") (tvar dark tdefault "--n-tab-color-segment")
    , eq "tab vars: dark bar color = dark primaryColor" (Just "#63e2b7") (tvar dark tdefault "--n-bar-color")

    -- scrollbar: defaults ---------------------------------------------------
    , eq "scrollbar defaults: xScrollable False" False sD.xScrollable
    , eq "scrollbar defaults: yPlacement Right" Scrollbar.Right sD.yPlacement
    , eq "scrollbar defaults: xPlacement Bottom" Scrollbar.Bottom sD.xPlacement
    , eq "scrollbar defaults: rtl False" False sD.rtl
    , eq "scrollbar defaults: showYBar False" False sD.showYBar
    , eq "scrollbar defaults: showXBar False" False sD.showXBar
    , eq "scrollbar defaults: yBarStyle Nothing" Nothing sD.yBarStyle
    , eq "scrollbar defaults: xBarStyle Nothing" Nothing sD.xBarStyle
    , eq "scrollbar defaults: contentClass Nothing" Nothing sD.contentClass
    , eq "scrollbar defaults: contentStyle Nothing" Nothing sD.contentStyle

    -- scrollbar: cssVars (theme math) ---------------------------------------
    , eq "scrollbar vars: 23 keys" 23 (List.length (Scrollbar.cssVars light sD))
    , eq "scrollbar vars: first key = bezier" (Just "--n-scrollbar-bezier") (List.head (varKeys (Scrollbar.cssVars light sD)))
    , eq "scrollbar vars: last key = rail color" (Just "--n-scrollbar-rail-color") (listAt 22 (varKeys (Scrollbar.cssVars light sD)))
    , eq "scrollbar vars: bezier = theme.common.cubicBezierEaseInOut" (Just light.common.cubicBezierEaseInOut) (svar light sD "--n-scrollbar-bezier")
    , eq "scrollbar vars: color" (Just "rgba(0, 0, 0, 0.25)") (svar light sD "--n-scrollbar-color")
    , eq "scrollbar vars: width" (Just "5px") (svar light sD "--n-scrollbar-width")
    , eq "scrollbar vars: height" (Just "5px") (svar light sD "--n-scrollbar-height")
    , eq "scrollbar vars: border radius" (Just "5px") (svar light sD "--n-scrollbar-border-radius")
    , eq "scrollbar vars: rail color transparent" (Just "transparent") (svar light sD "--n-scrollbar-rail-color")
    , eq "scrollbar vars: horizontal-top top" (Just "4px") (svar light sD "--n-scrollbar-rail-top-horizontal-top")
    , eq "scrollbar vars: horizontal-top left" (Just "2px") (svar light sD "--n-scrollbar-rail-left-horizontal-top")
    , eq "scrollbar vars: horizontal-top bottom = auto" (Just "auto") (svar light sD "--n-scrollbar-rail-bottom-horizontal-top")
    , eq "scrollbar vars: horizontal-bottom top = auto" (Just "auto") (svar light sD "--n-scrollbar-rail-top-horizontal-bottom")
    , eq "scrollbar vars: horizontal-bottom bottom" (Just "4px") (svar light sD "--n-scrollbar-rail-bottom-horizontal-bottom")
    , eq "scrollbar vars: vertical-right top" (Just "2px") (svar light sD "--n-scrollbar-rail-top-vertical-right")
    , eq "scrollbar vars: vertical-right right" (Just "4px") (svar light sD "--n-scrollbar-rail-right-vertical-right")
    , eq "scrollbar vars: vertical-right bottom" (Just "2px") (svar light sD "--n-scrollbar-rail-bottom-vertical-right")
    , eq "scrollbar vars: vertical-right left = auto" (Just "auto") (svar light sD "--n-scrollbar-rail-left-vertical-right")
    , eq "scrollbar vars: vertical-left top" (Just "2px") (svar light sD "--n-scrollbar-rail-top-vertical-left")
    , eq "scrollbar vars: vertical-left right = auto" (Just "auto") (svar light sD "--n-scrollbar-rail-right-vertical-left")
    , eq "scrollbar vars: vertical-left bottom" (Just "2px") (svar light sD "--n-scrollbar-rail-bottom-vertical-left")
    , eq "scrollbar vars: vertical-left left" (Just "4px") (svar light sD "--n-scrollbar-rail-left-vertical-left")
    , eq "scrollbar vars: rtl swaps vertical-right right to auto" (Just "auto") (svar light sRtlOpts "--n-scrollbar-rail-right-vertical-right")
    , eq "scrollbar vars: rtl swaps vertical-right left to 4px" (Just "4px") (svar light sRtlOpts "--n-scrollbar-rail-left-vertical-right")
    , eq "scrollbar vars: rtl swaps vertical-left right to 4px" (Just "4px") (svar light sRtlOpts "--n-scrollbar-rail-right-vertical-left")
    , eq "scrollbar vars: rtl swaps vertical-left left to auto" (Just "auto") (svar light sRtlOpts "--n-scrollbar-rail-left-vertical-left")
    , eq "scrollbar vars: rtl leaves horizontal-top left unchanged" (Just "2px") (svar light sRtlOpts "--n-scrollbar-rail-left-horizontal-top")
    , eq "scrollbar vars: rtl leaves horizontal-bottom bottom unchanged" (Just "4px") (svar light sRtlOpts "--n-scrollbar-rail-bottom-horizontal-bottom")

    -- popover: defaults -----------------------------------------------------
    , eq "popover defaults: showArrow True" True pD.showArrow
    , eq "popover defaults: arrowPointToCenter False" False pD.arrowPointToCenter
    , eq "popover defaults: overlap False" False pD.overlap
    , eq "popover defaults: raw False" False pD.raw
    , eq "popover defaults: scrollable False" False pD.scrollable
    , eq "popover defaults: width Nothing" Nothing pD.width
    , eq "popover defaults: rtl False" False pD.rtl
    , eq "popover defaults: header Nothing" Nothing pD.header
    , eq "popover defaults: footer Nothing" Nothing pD.footer
    , eq "popover defaults: transition Nothing" Nothing pD.transition
    , eq "popover defaults: arrowClass Nothing" Nothing pD.arrowClass
    , eq "popover defaults: arrowStyle Nothing" Nothing pD.arrowStyle
    , eq "popover defaults: arrowWrapperClass Nothing" Nothing pD.arrowWrapperClass
    , eq "popover defaults: arrowWrapperStyle Nothing" Nothing pD.arrowWrapperStyle
    , eq "popover defaults: contentClass Nothing" Nothing pD.contentClass
    , eq "popover defaults: contentStyle Nothing" Nothing pD.contentStyle
    , eq "popover defaults: headerClass Nothing" Nothing pD.headerClass
    , eq "popover defaults: headerStyle Nothing" Nothing pD.headerStyle
    , eq "popover defaults: footerClass Nothing" Nothing pD.footerClass
    , eq "popover defaults: footerStyle Nothing" Nothing pD.footerStyle
    , eq "popover defaults: attributes []" True (List.isEmpty pD.attributes)

    -- popover: cssVars (theme math) -----------------------------------------
    , eq "popover vars: 15 keys" 15 (List.length (Popover.cssVars light))
    , eq "popover vars: full 15-list (name+value, in order)" expectedPopoverVars (Popover.cssVars light)
    , eq "popover vars: --n-space" (Just "6px") (lookup "--n-space" (Popover.cssVars light))

    -- popover: placementName (all 12) ---------------------------------------
    , eq "popover placement: Top" "top" (Popover.placementName Popover.Top)
    , eq "popover placement: TopStart" "top-start" (Popover.placementName Popover.TopStart)
    , eq "popover placement: TopEnd" "top-end" (Popover.placementName Popover.TopEnd)
    , eq "popover placement: Bottom" "bottom" (Popover.placementName Popover.Bottom)
    , eq "popover placement: BottomStart" "bottom-start" (Popover.placementName Popover.BottomStart)
    , eq "popover placement: BottomEnd" "bottom-end" (Popover.placementName Popover.BottomEnd)
    , eq "popover placement: Left" "left" (Popover.placementName Popover.Left)
    , eq "popover placement: LeftStart" "left-start" (Popover.placementName Popover.LeftStart)
    , eq "popover placement: LeftEnd" "left-end" (Popover.placementName Popover.LeftEnd)
    , eq "popover placement: Right" "right" (Popover.placementName Popover.Right)
    , eq "popover placement: RightStart" "right-start" (Popover.placementName Popover.RightStart)
    , eq "popover placement: RightEnd" "right-end" (Popover.placementName Popover.RightEnd)

    -- tooltip: defaults (the popover's) -------------------------------------
    , eq "tooltip defaults == popover defaults" Popover.defaults Tooltip.defaults
    , eq "tooltip defaults: showArrow True" True tD.showArrow
    , eq "tooltip defaults: overlap False" False tD.overlap
    , eq "tooltip defaults: extraClasses []" True (List.isEmpty tD.extraClasses)
    , eq "tooltip defaults: rtl False" False tD.rtl

    -- tooltip: placementName / API through the alias ------------------------
    , eq "tooltip placementName: Top" "top" (Tooltip.placementName Popover.Top)
    , eq "tooltip placementName: BottomEnd" "bottom-end" (Tooltip.placementName Popover.BottomEnd)
    , eq "tooltip placementName: LeftStart" "left-start" (Tooltip.placementName Popover.LeftStart)

    -- tooltip: cssVars (theme math) -----------------------------------------
    , eq "tooltip vars: 15 keys (light)" 15 (List.length (Tooltip.cssVars light))
    , eq "tooltip vars: full 15-list light (name+value, in order)" expectedTooltipLightVars (Tooltip.cssVars light)
    , eq "tooltip light vars: --n-color" (Just "rgba(38, 38, 38, 1)") (lookup "--n-color" (Tooltip.cssVars light))
    , eq "tooltip light vars: --n-text-color" (Just "#FFF") (lookup "--n-text-color" (Tooltip.cssVars light))
    , eq "tooltip light vars: --n-padding = popover padding" (Just "8px 14px") (lookup "--n-padding" (Tooltip.cssVars light))
    , eq "tooltip light vars: --n-space = popover space" (Just "6px") (lookup "--n-space" (Tooltip.cssVars light))
    , eq "tooltip vars: 15 keys (dark)" 15 (List.length (Tooltip.cssVars dark))
    , eq "tooltip vars: full 15-list dark (name+value, in order)" expectedTooltipDarkVars (Tooltip.cssVars dark)
    , eq "tooltip dark vars: --n-color = popoverColor" (Just "rgb(72, 72, 78)") (lookup "--n-color" (Tooltip.cssVars dark))
    , eq "tooltip dark vars: --n-text-color = textColor2" (Just "rgba(255, 255, 255, 0.82)") (lookup "--n-text-color" (Tooltip.cssVars dark))

    -- tooltip: differs from popover ONLY in the two colour keys (light) -----
    , eq "tooltip vs popover (light): each 15 vars" ( 15, 15 ) ( List.length (Tooltip.cssVars light), List.length (Popover.cssVars light) )
    , eq "tooltip vs popover (light): the other 13 vars are identical" (stripColorVars (Popover.cssVars light)) (stripColorVars (Tooltip.cssVars light))
    , eq "tooltip vs popover (light): 13 shared keys" 13 (List.length (stripColorVars (Tooltip.cssVars light)))
    , eq "tooltip vs popover (light): --n-color pair (tooltip rgba vs popover #fff)" ( Just "rgba(38, 38, 38, 1)", Just "#fff" ) ( lookup "--n-color" (Tooltip.cssVars light), lookup "--n-color" (Popover.cssVars light) )
    , eq "tooltip vs popover (light): --n-text-color pair (tooltip #FFF vs popover textColor2)" ( Just "#FFF", Just "rgb(51, 54, 57)" ) ( lookup "--n-text-color" (Tooltip.cssVars light), lookup "--n-text-color" (Popover.cssVars light) )
    , eq "tooltip vs popover (light): --n-padding pair is identical" ( Just "8px 14px", Just "8px 14px" ) ( lookup "--n-padding" (Tooltip.cssVars light), lookup "--n-padding" (Popover.cssVars light) )
    ]



-- VIEW -------------------------------------------------------------------------


view : () -> Html Msg
view _ =
    let
        failures =
            checks |> List.filter (\c -> not c.ok) |> List.length
    in
    Html.div [ HA.class "nui-root", HA.id "app" ]
        [ Html.node "style" [] [ Html.text Css.css ]
        , Html.h1 []
            [ Html.text
                ("elm-naive-ui foundation tests — "
                    ++ String.fromInt (List.length checks)
                    ++ " assertions"
                )
            ]
        , Html.div
            [ HA.id "results"
            , HA.attribute "data-total" (String.fromInt (List.length checks))
            , HA.attribute "data-failures" (String.fromInt failures)
            ]
            (List.map renderCheck checks)
        , probeNodes
        , liveNodes
        ]


renderCheck : Check -> Html Msg
renderCheck c =
    Html.div
        [ HA.class "check"
        , HA.attribute "data-test"
            (if c.ok then
                "pass"

             else
                "fail"
            )
        , HA.attribute "data-name" c.name
        , HA.attribute "data-detail" c.detail
        ]
        [ Html.text
            (if c.ok then
                "PASS " ++ c.name

             else
                "FAIL " ++ c.name ++ " :: " ++ c.detail
            )
        ]


probeVarList : List ( String, String )
probeVarList =
    [ ( "--n-a", "1px" )
    , ( "--n-b", "initial" )
    , ( "--n-c", "" )
    , ( "--n-d", "red" )
    ]


probeNodes : Html Msg
probeNodes =
    Html.div [ HA.id "probes" ]
        [ Element.layout []
            (Element.column [ Element.spacing 4 ]
                [ Element.el [ Element.htmlAttribute (HA.id "probe-vars"), Internal.cssVars probeVarList ] Element.none
                , Element.el [ Element.htmlAttribute (HA.id "probe-vars-empty"), Internal.cssVars [ ( "--dropped", "initial" ) ] ] Element.none
                , Element.el [ Element.htmlAttribute (HA.id "probe-classes"), Internal.classes [ "n-button", "x" ] ] Element.none
                ]
            )
        ]


liveNodes : Html Msg
liveNodes =
    Html.div [ HA.id "live" ]
        [ Element.layout []
            (Element.column [ Element.spacing 8 ]
                [ Element.el [ Element.htmlAttribute (HA.id "live-primary") ]
                    (Button.view Theme.default primaryOpts [ Element.text "Primary" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-disabled") ]
                    (Button.view Theme.default disabledRoundOpts [ Element.text "Disabled" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tag-primary") ]
                    (Tag.view Theme.default primaryTagOpts [ Element.text "Primary" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tag-checked") ]
                    (Tag.view Theme.default checkedTagOpts [ Element.text "Checked" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tag-disabled") ]
                    (Tag.view Theme.default disabledTagOpts [ Element.text "Disabled" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-num") ]
                    (Badge.view Theme.default badgeNumOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-overflow") ]
                    (Badge.view Theme.default badgeOverflowOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-dot") ]
                    (Badge.view Theme.default badgeDotOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-empty") ]
                    (Empty.view Theme.default emptyLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-line") ]
                    (Progress.view Theme.default progressLineOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-circle") ]
                    (Progress.view Theme.default progressCircleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-multiple") ]
                    (Progress.view Theme.default progressMultipleOpts [ Element.text "Circle racing!" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-multiple-plain") ]
                    (Progress.view Theme.default progressMultiplePlainOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-gradient-line") ]
                    (Progress.view Theme.default progressGradientLineOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-gradient-circle") ]
                    (Progress.view Theme.default progressGradientCircleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-gradient-multiple") ]
                    (Progress.view Theme.default progressGradientMultipleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-result") ]
                    (Result.view Theme.default resultLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-skeleton") ]
                    (Skeleton.view Theme.default skeletonLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-spin") ]
                    (Spin.view Theme.default Spin.defaults [])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-scroll-up") ]
                    (Badge.view Theme.default badgeScrollUpOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-scroll-down") ]
                    (Badge.view Theme.default badgeScrollDownOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-wave") ]
                    (Badge.view Theme.default badgeWaveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-leave") ]
                    (Badge.view Theme.default badgeLeaveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-spin-transition") ]
                    (Spin.view Theme.default spinTransitionOpts [ Element.text "Content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-alert") ]
                    (Alert.view Theme.default rtlAlertOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-button") ]
                    (Button.view Theme.default rtlButtonOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-card") ]
                    (Card.view Theme.default rtlCardOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-checkbox") ]
                    (Checkbox.view Theme.default rtlCheckboxOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-input") ]
                    (Input.view Theme.default rtlInputOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-radio") ]
                    (Radio.view Theme.default rtlRadioOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-radio-group") ]
                    (Radio.group Theme.default rtlRadioGroupOpts [ Radio.choice "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-space") ]
                    (Space.view Theme.default rtlSpaceOpts [ Element.text "A", Element.text "B" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-tag") ]
                    (Tag.view Theme.default rtlTagOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-badge") ]
                    (Badge.view Theme.default rtlBadgeOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-railstyle-line") ]
                    (Progress.view Theme.default progressRailStyleLineOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-railstyle-multiple") ]
                    (Progress.view Theme.default progressRailStyleMultipleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-railstyle-circle") ]
                    (Progress.view Theme.default progressRailStyleCircleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-avatar-group") ]
                    (AvatarGroup.view Theme.default avatarGroupOpts avatarGroupFour)
                , Element.el [ Element.htmlAttribute (HA.id "live-avatar-group-plain") ]
                    (AvatarGroup.view Theme.default
                        avatarGroupPlainOpts
                        [ { src = "a.png" }, { src = "b.png" } ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-avatar-group-vertical") ]
                    (AvatarGroup.view Theme.default avatarGroupVerticalOpts [ { src = "a.png" } ])
                , Element.el [ Element.htmlAttribute (HA.id "live-avatar-group-slots") ]
                    (AvatarGroup.view Theme.default
                        avatarGroupSlotOpts
                        [ { src = "a.png" }, { src = "b.png" }, { src = "c.png" } ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-button-group") ]
                    (ButtonGroup.view Theme.default
                        buttonGroupOpts
                        [ Button.view Theme.default Button.defaults [ Element.text "A" ]
                        , Button.view Theme.default Button.defaults [ Element.text "B" ]
                        , Button.view Theme.default Button.defaults [ Element.text "C" ]
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-button-group-vertical") ]
                    (ButtonGroup.view Theme.default
                        buttonGroupVerticalOpts
                        [ Button.view Theme.default Button.defaults [ Element.text "A" ]
                        , Button.view Theme.default Button.defaults [ Element.text "B" ]
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-offset") ]
                    (Badge.view Theme.default badgeOffsetOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-gradient-text") ]
                    (GradientText.view Theme.default gradientLiveOpts [ Element.text "Wonderful" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-gradient-custom") ]
                    (GradientText.view Theme.default gradientCustomOpts [ Element.text "Custom" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-statistic") ]
                    (Statistic.view Theme.default statisticLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-breadcrumb") ]
                    (Breadcrumb.view Theme.default breadcrumbLiveOpts breadcrumbLiveItems)
                , Element.el [ Element.htmlAttribute (HA.id "live-timeline") ]
                    (Timeline.view Theme.default timelineLiveOpts timelineLiveItems)
                , Element.el [ Element.htmlAttribute (HA.id "live-timeline-large") ]
                    (Timeline.view Theme.default timelineLargeOpts [ Timeline.item ])
                , Element.el [ Element.htmlAttribute (HA.id "live-thing") ]
                    (Thing.view Theme.default thingLiveOpts [ Element.text "Body" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-marquee") ]
                    (Marquee.view Theme.default marqueeLiveOpts [ Element.text "Scroll" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-list") ]
                    (NList.view Theme.default nlistLiveOpts nlistLiveItems)
                , Element.el [ Element.htmlAttribute (HA.id "live-page-header") ]
                    (PageHeader.view Theme.default pageHeaderLiveOpts [ Element.text "Body" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-affix") ]
                    (Affix.view Theme.default affixLiveOpts [ Element.text "Sticky" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-countdown") ]
                    (Countdown.view Theme.default countdownLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-countdown-3") ]
                    (Countdown.view Theme.default countdownLiveOpts3 [])
                , Element.el [ Element.htmlAttribute (HA.id "live-split") ]
                    (Split.view Theme.default splitLiveOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-steps") ]
                    (Steps.view Theme.default stepsLiveOpts stepsLiveItems)
                , Element.el [ Element.htmlAttribute (HA.id "live-ellipsis") ]
                    (Ellipsis.view Theme.default
                        ellipsisLineClampOpts
                        [ Element.text "A very long single line of text that gets cut off with an ellipsis character." ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-ellipsis-expanded") ]
                    (Ellipsis.view Theme.default ellipsisExpandedOpts [ Element.text "Expanded two-line clamp." ])
                , Element.el [ Element.htmlAttribute (HA.id "live-back-top") ]
                    (BackTop.view Theme.default backTopLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-qr-code") ]
                    (QrCode.view Theme.default qrCodeLiveOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-qr-code-styled") ]
                    (QrCode.view Theme.default qrCodeStyledOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-collapse") ]
                    (Collapse.view Theme.default collapseLiveOpts collapseLiveItems)
                , Element.el [ Element.htmlAttribute (HA.id "live-collapse-show") ]
                    (Collapse.view Theme.default collapseShowOpts collapseOneItem)
                , Element.el [ Element.htmlAttribute (HA.id "live-collapse-rtl") ]
                    (Collapse.view Theme.default collapseRtlOpts collapseOneItem)
                , Element.el [ Element.htmlAttribute (HA.id "live-rate") ]
                    (Rate.view Theme.default rateLiveOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-rate-readonly") ]
                    (Rate.view Theme.default rateReadonlyOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-rate-half") ]
                    (Rate.view Theme.default rateHalfOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-float-button") ]
                    (FloatButton.view Theme.default floatButtonLiveOpts [ Element.text "+" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-float-button-square") ]
                    (FloatButton.view Theme.default floatButtonSquareOpts [ Element.text "+" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-float-button-menu") ]
                    (FloatButton.view Theme.default floatButtonMenuOpts [ Element.text "+" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-float-button-width") ]
                    (FloatButton.view Theme.default floatButtonWidthOpts [ Element.text "+" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-float-button-percent") ]
                    (FloatButton.view Theme.default floatButtonPercentOpts [ Element.text "+" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-input-otp") ]
                    (InputOtp.view Theme.default inputOtpLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-input-otp-rtl-block") ]
                    (InputOtp.view Theme.default inputOtpRtlBlockOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-input-otp-mask") ]
                    (InputOtp.view Theme.default inputOtpMaskOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-tags") ]
                    (DynamicTags.view Theme.default dynamicTagsLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-tags-input") ]
                    (DynamicTags.view Theme.default dynamicTagsInputOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-calendar") ]
                    (Calendar.view Theme.default calendarLiveOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-calendar-6wk") ]
                    (Calendar.view Theme.default calendarSixWeekOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-pagination") ]
                    (Pagination.view Theme.default paginationLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-pagination-simple") ]
                    (Pagination.view Theme.default paginationSimpleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-pagination-disabled") ]
                    (Pagination.view Theme.default paginationDisabledOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-pagination-rtl") ]
                    (Pagination.view Theme.default paginationRtlOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-input-number") ]
                    (InputNumber.view Theme.default
                        inputNumberLiveOpts
                        [ Element.text "P", Element.text "S" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-input-number-both") ]
                    (InputNumber.view Theme.default
                        inputNumberBothOpts
                        [ Element.text "P", Element.text "S" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-input-number-nobutton") ]
                    (InputNumber.view Theme.default
                        inputNumberNoButtonOpts
                        [ Element.text "P", Element.text "S" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-input-number-rtl") ]
                    (InputNumber.view Theme.default inputNumberRtlOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout") ]
                    (Layout.view Theme.default layoutPlainOpts [ Element.text "C" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-sider") ]
                    (Layout.view Theme.default layoutSiderOpts [ Element.text "C" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-absolute") ]
                    (Layout.view Theme.default layoutAbsoluteOpts [ Element.text "C" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-embedded") ]
                    (Layout.view Theme.default layoutEmbeddedOpts [ Element.text "C" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-content") ]
                    (Layout.content Theme.default layoutPlainOpts [ Element.text "C" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-sider-root") ]
                    (LayoutSider.view Theme.default siderOpts [ Element.text "Side" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-sider-arrow") ]
                    (LayoutSider.view Theme.default siderArrowOpts [ Element.text "Side" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-sider-bar") ]
                    (LayoutSider.view Theme.default siderBarOpts [ Element.text "Side" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-sider-right") ]
                    (LayoutSider.view Theme.default siderRightCollapsedOpts [ Element.text "Side" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-sider-collapsed-nocontent") ]
                    (LayoutSider.view Theme.default siderCollapsedNoContentOpts [ Element.text "Side" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-sider-inverted") ]
                    (LayoutSider.view Theme.default siderInvertedOpts [ Element.text "Side" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-sider-noborder") ]
                    (LayoutSider.view Theme.default siderNoBorderOpts [ Element.text "Side" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-header") ]
                    (LayoutHeader.view Theme.default layoutHeaderOpts [ Element.text "H" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-header-inverted") ]
                    (LayoutHeader.view Theme.default layoutHeaderInvertedOpts [ Element.text "H" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-footer") ]
                    (LayoutFooter.view Theme.default layoutFooterOpts [ Element.text "F" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-layout-footer-inverted") ]
                    (LayoutFooter.view Theme.default layoutFooterInvertedOpts [ Element.text "F" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-default") ]
                    (Flex.view Theme.default flexDefaults [ Element.text "A", Element.text "B" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-inline") ]
                    (Flex.view Theme.default flexInlineOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-vertical") ]
                    (Flex.view Theme.default flexVerticalOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-reverse") ]
                    (Flex.view Theme.default flexReverseOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-reverse-vertical") ]
                    (Flex.view Theme.default flexReverseVerticalOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-align") ]
                    (Flex.view Theme.default flexAlignCenterOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-space-between") ]
                    (Flex.view Theme.default flexSpaceBetweenOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-gap-number") ]
                    (Flex.view Theme.default flexNumberGapOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-gap-number2") ]
                    (Flex.view Theme.default flexNumber2GapOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-rtl") ]
                    (Flex.view Theme.default flexRtlOpts [ Element.text "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-flex-empty") ]
                    (Flex.view Theme.default flexDefaults [])
                , Element.el [ Element.htmlAttribute (HA.id "live-grid-basic") ]
                    (Grid.view gridDefaults
                        [ { gridItemBase | span = Grid.Number 12, attributes = [ Element.htmlAttribute (HA.id "grid-basic-a") ], content = [ Element.text "A" ] }
                        , { gridItemBase | span = Grid.Number 12, attributes = [ Element.htmlAttribute (HA.id "grid-basic-b") ], content = [ Element.text "B" ] }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-grid-offset") ]
                    (Grid.view gridDefaults
                        [ { gridItemBase | span = Grid.Number 6, offset = Grid.Number 3, attributes = [ Element.htmlAttribute (HA.id "grid-offset-a") ], content = [ Element.text "O" ] } ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-grid-layoutshift") ]
                    (Grid.view gridLayoutShiftOpts
                        [ { gridItemBase | span = Grid.Number 12, attributes = [ Element.htmlAttribute (HA.id "grid-ls-a") ], content = [ Element.text "L" ] } ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-grid-collapse") ]
                    (Grid.view gridCollapseOpts
                        [ { gridItemBase | span = Grid.Number 6, attributes = [ Element.htmlAttribute (HA.id "grid-collapse-0") ], content = [ Element.text "0" ] }
                        , { gridItemBase | span = Grid.Number 6, attributes = [ Element.htmlAttribute (HA.id "grid-collapse-1") ], content = [ Element.text "1" ] }
                        , { gridItemBase | span = Grid.Number 6, attributes = [ Element.htmlAttribute (HA.id "grid-collapse-2") ], content = [ Element.text "2" ] }
                        , { gridItemBase | span = Grid.Number 6, attributes = [ Element.htmlAttribute (HA.id "grid-collapse-3") ], content = [ Element.text "3" ] }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-grid-suffix") ]
                    (Grid.view gridSuffixOpts
                        [ { gridItemBase | span = Grid.Number 12, attributes = [ Element.htmlAttribute (HA.id "grid-suffix-0") ], content = [ Element.text "0" ] }
                        , { gridItemBase | span = Grid.Number 12, attributes = [ Element.htmlAttribute (HA.id "grid-suffix-1") ], content = [ Element.text "1" ] }
                        , { gridItemBase | suffix = True, span = Grid.Number 6, attributes = [ Element.htmlAttribute (HA.id "grid-suffix-s") ], content = [ Element.text "…" ] }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-grid-show-false") ]
                    (Grid.view gridDefaults
                        [ { gridItemBase | show = False, attributes = [ Element.htmlAttribute (HA.id "grid-hide-a") ], content = [ Element.text "H" ] }
                        , { gridItemBase | span = Grid.Number 12, attributes = [ Element.htmlAttribute (HA.id "grid-hide-b") ], content = [ Element.text "V" ] }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-grid-span-zero") ]
                    (Grid.view gridDefaults
                        [ { gridItemBase | span = Grid.Number 0, attributes = [ Element.htmlAttribute (HA.id "grid-zero-a") ], content = [ Element.text "Z" ] }
                        , { gridItemBase | span = Grid.Number 12, attributes = [ Element.htmlAttribute (HA.id "grid-zero-b") ], content = [ Element.text "B" ] }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-highlight") ]
                    (Highlight.view Theme.default highlightLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-highlight-escaped") ]
                    (Highlight.view Theme.default highlightEscapedOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-highlight-empty") ]
                    (Highlight.view Theme.default highlightEmptyOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-number-animation") ]
                    (NumberAnimation.view Theme.default numberAnimationLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-number-animation-mid") ]
                    (NumberAnimation.view Theme.default numberAnimationMidOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-icon-default") ]
                    (Icon.view Theme.default Icon.defaults [ Element.text "I" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-icon-depth") ]
                    (Icon.view Theme.default iconDepthOpts [ Element.text "I" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-icon-wrapper") ]
                    (IconWrapper.view Theme.default IconWrapper.defaults [ Element.text "I" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-icon-wrapper-styled") ]
                    (IconWrapper.view Theme.default iconWrapperStyledOpts [ Element.text "I" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-float-button-group") ]
                    (FloatButtonGroup.view Theme.default
                        FloatButtonGroup.defaults
                        [ FloatButton.view Theme.default FloatButton.defaults [ Element.text "+" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-float-button-group-square") ]
                    (FloatButtonGroup.view Theme.default
                        floatButtonGroupSquareOpts
                        [ FloatButton.view Theme.default floatButtonSquareOpts [ Element.text "+" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-heatmap") ]
                    (Heatmap.view Theme.default heatmapLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-heatmap-loading") ]
                    (Heatmap.view Theme.default heatmapLoadingOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-heatmap-small") ]
                    (Heatmap.view Theme.default heatmapSmallOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-heatmap-leading") ]
                    (Heatmap.view Theme.default heatmapLeadingOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-heatmap-no-fill") ]
                    (Heatmap.view Theme.default heatmapNoFillOpts [])

                -- LoadingBar
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-init") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults LoadingBar.init)
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-starting") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults loadingBarStarting)
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-kicked") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults loadingBarKicked)
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-from-to") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults loadingBarFromTo)
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-finishing") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults loadingBarFinishing)
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-erroring") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults loadingBarErroring)
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-idle-error") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults (LoadingBar.error LoadingBar.init))
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-enter") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults { loadingBarStarting | phase = Just Internal.EnterFrom })
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-leave") ]
                    (LoadingBar.view Theme.default LoadingBar.defaults { loadingBarFinishing | phase = Just Internal.LeaveFrom })
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-custom-loading") ]
                    (LoadingBar.view Theme.default loadingBarCustomOpts loadingBarKicked)
                , Element.el [ Element.htmlAttribute (HA.id "live-loading-bar-custom-error") ]
                    (LoadingBar.view Theme.default loadingBarCustomOpts loadingBarErroring)

                -- DynamicInput
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-input-input") ]
                    (DynamicInput.viewInput Theme.default dynamicInputLiveOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-input-pair") ]
                    (DynamicInput.viewPair Theme.default dynamicInputPairLiveOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-input-max-sort") ]
                    (DynamicInput.viewInput Theme.default dynamicInputMaxSortOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-input-empty") ]
                    (DynamicInput.viewInput Theme.default dynamicInputEmptyOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-input-min") ]
                    (DynamicInput.viewInput Theme.default dynamicInputMinLiveOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-input-maxed") ]
                    (DynamicInput.viewInput Theme.default dynamicInputMaxedOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-input-rtl") ]
                    (DynamicInput.viewInput Theme.default dynamicInputRtlOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dynamic-input-item-style") ]
                    (DynamicInput.viewInput Theme.default dynamicInputItemStyleOpts)

                -- Form
                , Element.el [ Element.htmlAttribute (HA.id "live-form-plain") ]
                    (Form.view Theme.default Form.defaults [ Element.text "Body" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-inline") ]
                    (Form.view Theme.default { fdefs | inline = True } [ Element.text "Body" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-submit") ]
                    (Form.view Theme.default { fdefs | onSubmit = Just NoOp } [ Element.text "Body" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-default") ]
                    (Form.item Theme.default Form.itemDefaults [ Element.text "Body" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-label") ]
                    (Form.item Theme.default { fditem | label = Just "Name", required = True } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-label-for") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelFor = Just "the-input" } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-label-left") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelPlacement = Just Form.Left, labelAlign = Just Form.AlignLeft, requireMarkPlacement = Form.MarkLeft, required = True } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-left-rightmark") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelPlacement = Just Form.Left, labelAlign = Just Form.AlignLeft, requireMarkPlacement = Form.MarkRight, required = True } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-left-noalign") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelPlacement = Just Form.Left, requireMarkPlacement = Form.MarkLeft, required = True } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-hanging") ]
                    (Form.item Theme.default { fditem | label = Just "Name", requireMarkPlacement = Form.MarkRightHanging } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-hanging-shown") ]
                    (Form.item Theme.default { fditem | label = Just "Name", requireMarkPlacement = Form.MarkRightHanging, required = True } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-mark-force") ]
                    (Form.item Theme.default { fditem | label = Just "Name", showRequireMark = Just True } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-mark-hide") ]
                    (Form.item Theme.default { fditem | label = Just "Name", required = True, showRequireMark = Just False } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-no-label") ]
                    (Form.item Theme.default { fditem | label = Just "Name", showLabel = Just False } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-small") ]
                    (Form.item Theme.default { fditem | size = Form.Small, label = Just "S" } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-large") ]
                    (Form.item Theme.default { fditem | size = Form.Large } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-content") ]
                    (Form.item Theme.default { fditem | contentClass = Just "my-content", contentStyle = Just "background:red" } [ Element.text "Body" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-label-width") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelPlacement = Just Form.Left, labelWidth = Just (Form.Px 120) } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-label-width-px80") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelPlacement = Just Form.Left, labelWidth = Just (Form.Px 80) } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-label-width-custom") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelPlacement = Just Form.Left, labelWidth = Just (Form.Custom "10em") } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-label-width-top") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelWidth = Just (Form.Px 80) } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-label-style") ]
                    (Form.item Theme.default { fditem | label = Just "Name", labelStyle = Just "text-decoration:underline" } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-feedback") ]
                    (Form.item Theme.default { fditem | feedback = Just "Controlled" } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-validation-warn") ]
                    (Form.item Theme.default { fditem | validation = Just [ { level = Form.WarningLevel, message = "w1" }, { level = Form.WarningLevel, message = "w2" } ] } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-validation-error") ]
                    (Form.item Theme.default { fditem | validation = Just [ { level = Form.ErrorLevel, message = "e1" } ] } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-validation-override") ]
                    (Form.item Theme.default { fditem | validation = Just [ { level = Form.ErrorLevel, message = "e1" } ], validationStatus = Just Form.WarningLevel } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-status-only") ]
                    (Form.item Theme.default { fditem | validationStatus = Just Form.ErrorLevel } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-feedback-off") ]
                    (Form.item Theme.default { fditem | showFeedback = False, feedback = Just "Hidden" } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-form-item-feedback-style") ]
                    (Form.item Theme.default { fditem | feedback = Just "F", feedbackClass = Just "my-fb", feedbackStyle = Just "color:blue" } [])

                -- Descriptions
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-basic") ]
                    (Descriptions.view Theme.default descBasicOpts descBasicItems)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-bordered") ]
                    (Descriptions.view Theme.default descBorderedOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-left") ]
                    (Descriptions.view Theme.default descLeftOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-left-bordered") ]
                    (Descriptions.view Theme.default descLeftBorderedOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-columns") ]
                    (Descriptions.view Theme.default descColumnsOpts descItems4)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-small") ]
                    (Descriptions.view Theme.default descSmallOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-large-bordered") ]
                    (Descriptions.view Theme.default descLargeBorderedOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-separator") ]
                    (Descriptions.view Theme.default descSeparatorOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-empty-separator") ]
                    (Descriptions.view Theme.default descEmptySeparatorOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-center") ]
                    (Descriptions.view Theme.default descCenterOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-passthrough") ]
                    (Descriptions.view Theme.default descPassthroughOpts descItems3)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-item-style") ]
                    (Descriptions.view Theme.default descBorderedOpts descItemStyled)
                , Element.el [ Element.htmlAttribute (HA.id "live-descriptions-empty") ]
                    (Descriptions.view Theme.default ddflt [])

                -- Tabs
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-default") ]
                    (Tabs.view Theme.default tdefault ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-line") ]
                    (Tabs.view Theme.default tLineOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-card") ]
                    (Tabs.view Theme.default tCardOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-segment") ]
                    (Tabs.view Theme.default tSegmentOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-small") ]
                    (Tabs.view Theme.default tSmallOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-large") ]
                    (Tabs.view Theme.default tLargeOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-bottom") ]
                    (Tabs.view Theme.default tBottomOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-left") ]
                    (Tabs.view Theme.default tLeftOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-right") ]
                    (Tabs.view Theme.default tRightOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-justify") ]
                    (Tabs.view Theme.default tJustifyOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-closable-bar") ]
                    (Tabs.view Theme.default tClosableBarOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-card-closable") ]
                    (Tabs.view Theme.default tCardClosableOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-card-closable-disabled") ]
                    (Tabs.view Theme.default tCardClosableOpts ttabsDisabled)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-addable") ]
                    (Tabs.view Theme.default tAddableOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-rtl") ]
                    (Tabs.view Theme.default tRtlOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-prefix-suffix") ]
                    (Tabs.view Theme.default tPrefixSuffixOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-disabled") ]
                    (Tabs.view Theme.default tDisabledOpts ttabsDisabled)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-show") ]
                    (Tabs.view Theme.default tShowOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-hover") ]
                    (Tabs.view Theme.default tHoverOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-styling") ]
                    (Tabs.view Theme.default tStylingOpts ttabs)

                -- Scrollbar
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-default") ]
                    (Scrollbar.view Theme.default sD [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-bars") ]
                    (Scrollbar.view Theme.default sBarsOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-x") ]
                    (Scrollbar.view Theme.default sXOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-top-rail") ]
                    (Scrollbar.view Theme.default sTopRailOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-left") ]
                    (Scrollbar.view Theme.default sLeftOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-rtl") ]
                    (Scrollbar.view Theme.default sRtlOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-styling") ]
                    (Scrollbar.view Theme.default sStylingOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-x-content") ]
                    (Scrollbar.view Theme.default sXContentOpts [ Element.text "content" ])

                -- Popover (the host wrapper carries the v-placement attribute)
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-default"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pD [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-width"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pWidthOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-header-footer"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pHeaderFooterOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-header-only"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pHeaderOnlyOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-header-empty"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pHeaderOnlyOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-no-arrow"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pNoArrowOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-overlap"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pOverlapOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-raw"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pRawOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-rtl"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pRtlOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-center-arrow"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pCenterArrowOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-scrollable"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pScrollableOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-scrollable-header"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pScrollableHeaderOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-transition"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pTransitionOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-passthrough"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.default pPassthroughOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-placement"), Popover.placementAttribute Popover.TopStart ]
                    (Popover.view Theme.default pD [ Element.text "content" ])

                -- Tooltip (the popover body + the n-tooltip marker; a dark mount
                -- and a dark popover mount to pin the dark differential)
                , Element.el [ Element.htmlAttribute (HA.id "live-tooltip-default"), Tooltip.placementAttribute Popover.Top ]
                    (Tooltip.view Theme.default tD [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tooltip-dark"), Tooltip.placementAttribute Popover.Top ]
                    (Tooltip.view Theme.dark tD [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tooltip-no-arrow"), Tooltip.placementAttribute Popover.Top ]
                    (Tooltip.view Theme.default tNoArrowOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tooltip-overlap"), Tooltip.placementAttribute Popover.Top ]
                    (Tooltip.view Theme.default tOverlapOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tooltip-extra"), Tooltip.placementAttribute Popover.Top ]
                    (Tooltip.view Theme.default tExtraOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tooltip-placement"), Tooltip.placementAttribute Popover.BottomEnd ]
                    (Tooltip.view Theme.default tD [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tooltip-width"), Tooltip.placementAttribute Popover.Top ]
                    (Tooltip.view Theme.default tWidthOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tooltip-transition"), Tooltip.placementAttribute Popover.Top ]
                    (Tooltip.view Theme.default tTransitionOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popover-dark"), Popover.placementAttribute Popover.Top ]
                    (Popover.view Theme.dark pD [ Element.text "content" ])
                ]
            )
        ]
