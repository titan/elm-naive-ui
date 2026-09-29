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
import NUI.Anchor as Anchor
import NUI.AutoComplete as AutoComplete
import NUI.Avatar as Avatar
import NUI.AvatarGroup as AvatarGroup
import NUI.BackTop as BackTop
import NUI.Badge as Badge
import NUI.BaseSelection as BaseSelection
import NUI.Breadcrumb as Breadcrumb
import NUI.Button as Button
import NUI.ButtonGroup as ButtonGroup
import NUI.Calendar as Calendar
import NUI.Card as Card
import NUI.Cascader as Cascader
import NUI.Checkbox as Checkbox
import NUI.Collapse as Collapse
import NUI.Countdown as Countdown
import NUI.Css as Css
import NUI.DataTable as DataTable
import NUI.DatePicker as DatePicker
import NUI.Descriptions as Descriptions
import NUI.Dialog as Dialog
import NUI.DialogProvider as DialogProvider
import NUI.Drawer as Drawer
import NUI.DrawerContent as DrawerContent
import NUI.Dropdown as Dropdown
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
import NUI.Image as Image
import NUI.ImageGroup as ImageGroup
import NUI.ImagePreview as ImagePreview
import NUI.Input as Input
import NUI.InputNumber as InputNumber
import NUI.InputOtp as InputOtp
import NUI.Internal as Internal
import NUI.Internal.DateTime as DT
import NUI.Layout as Layout
import NUI.LayoutFooter as LayoutFooter
import NUI.LayoutHeader as LayoutHeader
import NUI.LayoutSider as LayoutSider
import NUI.List as NList
import NUI.LoadingBar as LoadingBar
import NUI.Marquee as Marquee
import NUI.Mention as Mention
import NUI.Menu as Menu
import NUI.Message as Message
import NUI.Modal as Modal
import NUI.Notification as Notification
import NUI.NumberAnimation as NumberAnimation
import NUI.PageHeader as PageHeader
import NUI.Pagination as Pagination
import NUI.Popconfirm as Popconfirm
import NUI.Popover as Popover
import NUI.Popselect as Popselect
import NUI.Progress as Progress
import NUI.QrCode as QrCode
import NUI.Qrcodegen as Qrcodegen
import NUI.Radio as Radio
import NUI.Rate as Rate
import NUI.Result as Result
import NUI.Scrollbar as Scrollbar
import NUI.Select as Select
import NUI.SelectMenu as SelectMenu
import NUI.Skeleton as Skeleton
import NUI.Slider as Slider
import NUI.Space as Space
import NUI.Spin as Spin
import NUI.Split as Split
import NUI.Statistic as Statistic
import NUI.Steps as Steps
import NUI.Switch as Switch
import NUI.Table as Table
import NUI.Tabs as Tabs
import NUI.Tag as Tag
import NUI.Theme as Theme
import NUI.Theme.AutoComplete as AutoCompleteTheme
import NUI.Theme.Button as ButtonTheme
import NUI.Theme.Calendar as CalendarTheme
import NUI.Theme.Color as Color
import NUI.Theme.DynamicTags as DynamicTagsTheme
import NUI.Theme.FloatButtonGroup as FloatButtonGroupTheme
import NUI.Theme.Heatmap as HeatmapTheme
import NUI.Theme.Icon as IconTheme
import NUI.Theme.IconWrapper as IconWrapperTheme
import NUI.Theme.InputOtp as InputOtpTheme
import NUI.Theme.InternalSelection as InternalSelectionTheme
import NUI.Theme.Layout as LayoutTheme
import NUI.Theme.Mention as MentionTheme
import NUI.Theme.Select as SelectTheme
import NUI.Theme.Table as TableTheme
import NUI.Theme.Tag as TagTheme
import NUI.Theme.Tree as TreeTheme
import NUI.Theme.Watermark as WatermarkTheme
import NUI.Thing as Thing
import NUI.TimePicker as TimePicker
import NUI.Timeline as Timeline
import NUI.Tooltip as Tooltip
import NUI.Transfer as Transfer
import NUI.Tree as Tree
import NUI.TreeSelect as TreeSelect
import NUI.Types as T
import NUI.Watermark as Watermark
import Time


main : Program () Int Msg
main =
    Browser.sandbox
        { init = 0
        , update = update
        , view = view
        }


type Msg
    = NoOp
    | Selected String
    | ModalClose
    | DrawerClose
    | DrawerMaskClick
    | DialogClose
    | DialogPositive
    | DialogNegative
    | MenuExpandedKeys (List String)
    | SliderIndex Int
    | PreviewClose
    | MessageClose
    | NotificationClose


{-| The model is a counter of dropdown `onSelect` / modal `onClose` / drawer
`onClose`/`onMaskClick` / dialog `onClose`/`onPositiveClick`/`onNegativeClick`
dispatches — the only observable way to prove the click wiring fires (and that
disabled / submenu clicks do not).
-}
update : Msg -> Int -> Int
update msg count =
    case msg of
        NoOp ->
            count

        Selected _ ->
            count + 1

        ModalClose ->
            count + 1

        DrawerClose ->
            count + 1

        DrawerMaskClick ->
            count + 1

        DialogClose ->
            count + 1

        DialogPositive ->
            count + 1

        DialogNegative ->
            count + 1

        MenuExpandedKeys _ ->
            count + 1

        SliderIndex _ ->
            count + 1

        PreviewClose ->
            count + 1

        MessageClose ->
            count + 1

        NotificationClose ->
            count + 1


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


{-| `Maybe` presence without `==` — the option records carry `Element`/attribute
payloads that Elm will not compare.
-}
isNothing : Maybe a -> Bool
isNothing m =
    case m of
        Nothing ->
            True

        Just _ ->
            False



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



-- ANCHOR FIXTURES — pin derivation: BaseAnchor.tsx render (class order,
-- mergedShowRail = !isBlockType && showRail, background = mergedShowRail &&
-- showBackground) + Link.tsx (activeRef truthy-href equality, title attr via
-- getTitleAttribute "" → undefined) + AnchorAdapter.tsx cssVarsRef order.


anchorLink : String -> String -> List (Anchor.Link msg) -> Anchor.Link msg
anchorLink title href children =
    Anchor.Link
        { title = Just title
        , titleSlot = Nothing
        , href = Just href
        , children = children
        , onClick = Nothing
        , attributes = []
        }


anchorLiveOpts : Anchor.Options msg
anchorLiveOpts =
    Anchor.defaults


anchorLiveLinks : List (Anchor.Link msg)
anchorLiveLinks =
    [ anchorLink "Demos"
        "#demos"
        [ anchorLink "Basic" "#basic" []
        , anchorLink "Affix" "#affix" []
        ]
    , anchorLink "API" "#api" []
    ]


anchorEdgeLinks : List (Anchor.Link msg)
anchorEdgeLinks =
    [ Anchor.Link
        { title = Just ""
        , titleSlot = Nothing
        , href = Just "#empty-title"
        , children = []
        , onClick = Nothing
        , attributes = []
        }
    , Anchor.Link
        { title = Just "Hrefless"
        , titleSlot = Nothing
        , href = Nothing
        , children = []
        , onClick = Nothing
        , attributes = []
        }
    , Anchor.Link
        { title = Just "EmptyHref"
        , titleSlot = Nothing
        , href = Just ""
        , children = []
        , onClick = Nothing
        , attributes = []
        }
    , Anchor.Link
        { title = Just "Slotted"
        , titleSlot = Just (Element.text "Custom Title")
        , href = Just "#slotted"
        , children = []
        , onClick = Nothing
        , attributes = []
        }
    ]



-- TRANSFER FIXTURES — pin derivation: Transfer.tsx render (:294-406) +
-- use-transfer-data.ts (pure data) + TransferHeader/TransferFilter/
-- TransferList/TransferListItem.tsx + styles/light.ts + _common.ts +
-- enUS.ts Transfer locale block. Expectations in tasks/recon/transfer-pins.md.


transferOptions : List Transfer.Option
transferOptions =
    [ { label = "Option 1", value = "1", disabled = False }
    , { label = "Option 2", value = "2", disabled = False }
    , { label = "Option 3", value = "3", disabled = False }
    , { label = "Disabled", value = "4", disabled = True }
    ]


transferLiveOpts : Transfer.Options msg
transferLiveOpts =
    Transfer.defaults



-- TREE-SELECT FIXTURES — pin derivation: TreeSelect.tsx (render :911-1129,
-- cssVars :816-845, derivations :195-475, click algebra :529-661) +
-- Tree.tsx (:1032-1130 unify, :1774-1778 classes, :1855-1885 the
-- internalScrollable branch, :1749-1753 the renderEmpty replace) +
-- tree-select styles/light.ts. Expectations in
-- tasks/recon/tree-select-pins.md.


tsNode : String -> String -> Bool -> Maybe (List (Tree.TreeOption msg)) -> Tree.TreeOption msg
tsNode key label disabled kids =
    Tree.TreeOption
        { key = key
        , label = label
        , disabled = disabled
        , checkboxDisabled = False
        , isLeaf = kids == Nothing
        , children = kids
        , prefix = []
        , suffix = []
        }


{-| The P9 fixture — o1{o1-1{o1-3}, o1-2}, o2 leaf, o3 disabled leaf.
-}
treeSelectOptions : List (Tree.TreeOption msg)
treeSelectOptions =
    [ tsNode "o1"
        "Outfield"
        False
        (Just
            [ tsNode "o1-1" "Left" False (Just [ tsNode "o1-3" "Bench" False Nothing ])
            , tsNode "o1-2" "Right" False Nothing
            ]
        )
    , tsNode "o2" "Pitcher" False Nothing
    , tsNode "o3" "Disabled" True Nothing
    ]


treeSelectLiveOpts : TreeSelect.Options msg
treeSelectLiveOpts =
    TreeSelect.defaults



-- DATE-PICKER / TIME-PICKER FIXTURES — pin derivation: date-picker/src/panel/*
-- + utils.ts + DatePicker.tsx + use-*.ts + time-picker/src/* + date-fns v2
-- ground truth. Expectations in tasks/recon/date-picker-pins.md. All
-- timestamps are UTC instants (verified with TZ=UTC node).


dpTSA : Int
dpTSA =
    1715297600000


dpTSB : Int
dpTSB =
    1704067200000


dpMayAnchor : Int
dpMayAnchor =
    1714521600000


dpRangeEnd : Int
dpRangeEnd =
    1715385600000


dpApr28 : Int
dpApr28 =
    1714262400000


dpJun08 : Int
dpJun08 =
    1717804800000


dpMay20 : Int
dpMay20 =
    1716163200000


dpMay05 : Int
dpMay05 =
    1714867200000


dpMay09 : Int
dpMay09 =
    1715212800000


dpApr01 : Int
dpApr01 =
    1711929600000


dpFeb29 : Int
dpFeb29 =
    1709164800000


dpJan31 : Int
dpJan31 =
    1706659200000


dpY1999 : Int
dpY1999 =
    915148800000


dpD2004 : Int
dpD2004 =
    1104451200000


dpJan2004 : Int
dpJan2004 =
    1072915200000


dpJan2005 : Int
dpJan2005 =
    1104537600000


dpJan2005b : Int
dpJan2005b =
    1104624000000



-- S1 zone fixtures: a UTC+8 caller (`Time.customZone 480`) whose local civil
-- day differs from the UTC day for these instants (oracle report §S1).


dpZone : Time.Zone
dpZone =
    Time.customZone 480 []


dpZoneValue : Int
dpZoneValue =
    -- local 2024-03-15 00:00 @ UTC+8 = 2024-03-14T16:00Z
    1710432000000


dpZoneNow : Int
dpZoneNow =
    -- local 2024-03-21 00:30 @ UTC+8 = 2024-03-20T16:30Z (UTC civil day 20)
    1710952200000


dpNoFields :
    { year : Maybe Int
    , month : Maybe Int
    , day : Maybe Int
    , hours : Maybe Int
    , minutes : Maybe Int
    , seconds : Maybe Int
    , quarter : Maybe Int
    }
dpNoFields =
    { year = Nothing
    , month = Nothing
    , day = Nothing
    , hours = Nothing
    , minutes = Nothing
    , seconds = Nothing
    , quarter = Nothing
    }


dpCellAt : Int -> List DT.DateItem -> Maybe DT.DateItem
dpCellAt ts items =
    List.filter (\i -> i.ts == ts) items |> List.head


dpCellSelected : Int -> List DT.DateItem -> Bool
dpCellSelected ts items =
    dpCellAt ts items |> Maybe.map .selected |> Maybe.withDefault False


dpCellFlag : (DT.DateItem -> Bool) -> Int -> List DT.DateItem -> Bool
dpCellFlag f ts items =
    dpCellAt ts items |> Maybe.map f |> Maybe.withDefault False


dpBool : Bool -> String
dpBool b =
    if b then
        "True"

    else
        "False"


dpDateItems : List DT.DateItem
dpDateItems =
    DT.dateArray dpMayAnchor (DT.SingleTs dpTSA) dpTSA 6 False False


dpWeekItems : List DT.DateItem
dpWeekItems =
    DT.dateArray dpMayAnchor (DT.SingleTs dpTSA) dpTSA 6 False True


dpRangeItems : List DT.DateItem
dpRangeItems =
    DT.dateArray dpMayAnchor (DT.RangeTs dpMayAnchor dpRangeEnd) dpMayAnchor 6 False False


{-| The panel's grid transform: map a caller instant onto the UTC midnight of
the same civil day in `zone` (the port's private `DatePicker.gridTs`,
[oracle S1]). Used to reproduce `DatePicker.dateItems` in the eq pins.
-}
dpGridTs : Time.Zone -> Int -> Int
dpGridTs zone raw =
    DT.toPosix Time.utc
        (DT.toCivil zone raw)
        { hours = 0, minutes = 0, seconds = 0, ms = 0 }


{-| `dateArray` exactly as `DatePicker.dateItems` builds it for a single value
with a non-UTC zone: anchor, value and now all through `gridTs` ([oracle S1]).
-}
dpZoneItems : List DT.DateItem
dpZoneItems =
    DT.dateArray (dpGridTs dpZone dpZoneValue)
        (DT.SingleTs (dpGridTs dpZone dpZoneValue))
        (dpGridTs dpZone dpZoneNow)
        6
        False
        False


{-| The local civil day a click on the grid's 2024-03-15 cell emits ([oracle
S1] round-trip).
-}
dpZoneClickCivil : Maybe ( Int, Int, Int )
dpZoneClickCivil =
    case
        DatePicker.singleDateClick
            { type_ = DatePicker.Date
            , value = DatePicker.Single (Just dpZoneValue)
            , target = { ts = 1710460800000, year = 2024, month = 3, day = 15, quarter = 1 }
            , isDisabled = False
            , defaultTime = Nothing
            , now = dpZoneNow
            , zone = dpZone
            }
            |> .value
    of
        DatePicker.Single (Just ts) ->
            let
                c =
                    DT.toCivil dpZone ts
            in
            Just ( c.year, c.month, c.day )

        _ ->
            Nothing


dpClickTarget : DatePicker.ClickTarget
dpClickTarget =
    { ts = dpMay20, year = 2024, month = 5, day = 20, quarter = 2 }


{-| The base panel options for the DOM fixtures: UTC zone, May-2024 anchor.
-}
dpBaseOpts : DatePicker.Options msg
dpBaseOpts =
    let
        d =
            DatePicker.defaultOptions
    in
    { d
        | now = Time.millisToPosix dpMayAnchor
        , zone = Time.utc
    }


dpTimeBaseOpts : TimePicker.Options msg
dpTimeBaseOpts =
    let
        d =
            TimePicker.defaultOptions
    in
    { d
        | now = Time.millisToPosix dpTSA
        , zone = Time.utc
        , value = Just dpTSA
    }


tsSingleOpts : TreeSelect.Options msg
tsSingleOpts =
    { treeSelectLiveOpts | options = treeSelectOptions }


tsSingleCheckOpts : TreeSelect.Options msg
tsSingleCheckOpts =
    { tsSingleOpts | checkable = True, cascade = True }


tsMultiCheckOpts : TreeSelect.Options msg
tsMultiCheckOpts =
    { tsSingleOpts | multiple = True, checkable = True, cascade = True }


tsMultiPlainOpts : TreeSelect.Options msg
tsMultiPlainOpts =
    { tsSingleOpts | multiple = True }


tsLeafOnlyOpts : TreeSelect.Options msg
tsLeafOnlyOpts =
    { treeSelectLiveOpts | leafOnly = True }


tsParentOpts : TreeSelect.Options msg
tsParentOpts =
    { treeSelectLiveOpts | checkStrategy = Tree.Parent }


tsCascadeNoMultipleOpts : TreeSelect.Options msg
tsCascadeNoMultipleOpts =
    { treeSelectLiveOpts | options = treeSelectOptions, cascade = True, checkable = True }


tsCascadeNoCheckableOpts : TreeSelect.Options msg
tsCascadeNoCheckableOpts =
    { treeSelectLiveOpts | options = treeSelectOptions, multiple = True, cascade = True, checkable = False }


tsCascadeFullOpts : TreeSelect.Options msg
tsCascadeFullOpts =
    { treeSelectLiveOpts | options = treeSelectOptions, multiple = True, cascade = True, checkable = True }


{-| An unloaded branch (isLeaf False, children Nothing) under
-- `allowCheckingNotLoaded = False` — upstream treemate throws
-- SubtreeNotLoadedError; the port stays total (the b3 rule).
-}
treeSelectUnloadOptions : List (Tree.TreeOption msg)
treeSelectUnloadOptions =
    [ Tree.TreeOption
        { key = "o4"
        , label = "Unloaded"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children = Nothing
        , prefix = []
        , suffix = []
        }
    , tsNode "o2" "Pitcher" False Nothing
    ]


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


{-| S1 probe: `Card` ignores `justifyContent`, but the resolved justify still drives
whether the `n-tabs-tab-pad` is emitted (pads for every tab after the first).
-}
tCardJustifyOpts : Tabs.Options Msg
tCardJustifyOpts =
    { tCardOpts | justifyContent = Just Tabs.JustifySpaceBetween }


{-| S2 probe: the add tab inherits `tabClass` (its documented contract).
-}
tAddableClassOpts : Tabs.Options Msg
tAddableClassOpts =
    { tCardOpts | addable = True, tabClass = Just "x" }



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



-- DROPDOWN -------------------------------------------------------------------


{-| The plain defaults binding (`{ Dropdown.defaults | … }` is a parse error).
-}
dD : Dropdown.Options Msg
dD =
    Dropdown.defaults


dSmallOpts : Dropdown.Options Msg
dSmallOpts =
    { dD | size = Dropdown.Small }


dInvertedOpts : Dropdown.Options Msg
dInvertedOpts =
    { dD | inverted = True }


dArrowOpts : Dropdown.Options Msg
dArrowOpts =
    { dD | showArrow = True }


dOverlapArrowOpts : Dropdown.Options Msg
dOverlapArrowOpts =
    { dD | showArrow = True, overlap = True }


dScrollableOpts : Dropdown.Options Msg
dScrollableOpts =
    { dD | scrollable = True }


{-| An enter transition carrying the root's `popover-transition` family.
-}
dTransitionOpts : Dropdown.Options Msg
dTransitionOpts =
    { dD | transition = Just ( "popover-transition", Internal.EnterActive ) }


{-| The submenu family tuple (upstream `fade-in-scale-up-transition`).
-}
dSubTransitionOpts : Dropdown.Options Msg
dSubTransitionOpts =
    { dD | transition = Just ( "fade-in-scale-up-transition", Internal.EnterActive ) }


{-| `value = g1b` (a group child) and `value = sub1` (a submenu child) paths.
-}
dValueOpts : Dropdown.Options Msg
dValueOpts =
    { dD | value = Just "g1b" }


dChildValueOpts : Dropdown.Options Msg
dChildValueOpts =
    { dD | value = Just "sub1" }


{-| `onSelect` wired to the harness counter (the only observable click effect).
-}
dSelectOpts : Dropdown.Options Msg
dSelectOpts =
    { dD | onSelect = Just Selected }


dLeaf : String -> String -> Dropdown.Option Msg
dLeaf key label =
    Dropdown.Option
        { key = key
        , label = label
        , icon = Nothing
        , disabled = False
        , children = Nothing
        , attributes = []
        }


dLeafIcon : String -> String -> Dropdown.Option Msg
dLeafIcon key label =
    Dropdown.Option
        { key = key
        , label = label
        , icon = Just (Element.text "I")
        , disabled = False
        , children = Nothing
        , attributes = []
        }


dLeafDisabled : String -> String -> Dropdown.Option Msg
dLeafDisabled key label =
    Dropdown.Option
        { key = key
        , label = label
        , icon = Nothing
        , disabled = True
        , children = Nothing
        , attributes = []
        }


{-| `children = Just []` still makes a submenu (chevron suffix, no select).
-}
dSubmenu : String -> String -> List (Dropdown.Option Msg) -> Dropdown.Option Msg
dSubmenu key label children =
    Dropdown.Option
        { key = key
        , label = label
        , icon = Nothing
        , disabled = False
        , children = Just children
        , attributes = []
        }


dGroup : String -> String -> List (Dropdown.Option Msg) -> Dropdown.Option Msg
dGroup key label children =
    Dropdown.Group { key = key, label = label, icon = Nothing, children = children }


{-| A group whose own icon must be ignored by the menu-level flag scan (upstream
scans the children, not the header).
-}
dGroupIcon : String -> String -> List (Dropdown.Option Msg) -> Dropdown.Option Msg
dGroupIcon key label children =
    Dropdown.Group { key = key, label = label, icon = Just (Element.text "G"), children = children }


dDivider : Dropdown.Option Msg
dDivider =
    Dropdown.Divider { attributes = [] }


dCustom : String -> Dropdown.Option Msg
dCustom txt =
    Dropdown.Custom { key = "custom", children = [ Element.text txt ], attributes = [] }


{-| Every option type, a group with a divider child, a submenu (offset container)
and a leaf without children (no offset container).
-}
dStructureOptions : List (Dropdown.Option Msg)
dStructureOptions =
    [ dLeafIcon "leaf" "Leaf"
    , dGroup "grp" "Group" [ dLeaf "gc" "GroupChild", dDivider ]
    , dDivider
    , dCustom "custom-content"
    , dSubmenu "sub" "Submenu" []
    ]


{-| A submenu whose CHILD carries an icon (that child is caller-mounted, never
rendered at this level, and `menuFlags` must never scan into submenu children),
plus a group — with no icon at the top level or in the group. So every prefix
must stay narrow (pins the `showIcon` submenu-child exclusion) while the submenu
still widens every suffix (`--has-submenu`).
-}
dFlagsOptions : List (Dropdown.Option Msg)
dFlagsOptions =
    [ dLeaf "a" "A"
    , dLeaf "b" "B"
    , dSubmenu "c" "C" [ dLeafIcon "c1" "C1" ]
    , dGroup "g" "G" [ dLeaf "g1" "G1" ]
    ]


{-| The icon lives on a _group child_ — it must still widen every prefix.
-}
dGroupIconOptions : List (Dropdown.Option Msg)
dGroupIconOptions =
    [ dLeaf "a" "A"
    , dGroup "g" "G" [ dLeafIcon "g1" "G1" ]
    ]


{-| A group inside a group — the nested group is dropped (upstream warns+nulls).
-}
dNestedGroupOptions : List (Dropdown.Option Msg)
dNestedGroupOptions =
    [ dGroup "outer"
        "Outer"
        [ dLeaf "inner1" "Inner1"
        , dGroup "inner" "InnerGroup" [ dLeaf "deep" "Deep" ]
        ]
    ]


{-| A plain leaf, a group (child targeted by `value`), and a submenu (parent
targeted by `value`).
-}
dValueOptions : List (Dropdown.Option Msg)
dValueOptions =
    [ dLeaf "overview" "Overview"
    , dGroup "g1" "G1" [ dLeaf "g1a" "A", dLeaf "g1b" "B" ]
    , dSubmenu "sub" "Sub" [ dLeaf "sub1" "S1" ]
    ]


{-| One selectable leaf, one disabled leaf, one submenu leaf — all with
`onSelect` wired; only the selectable leaf must fire.
-}
dSelectOptions : List (Dropdown.Option Msg)
dSelectOptions =
    [ dLeaf "ok" "OK"
    , dLeafDisabled "dis" "Disabled"
    , dSubmenu "sub" "Submenu" []
    ]


{-| The full 31-entry `--n-*` list `NUI.Dropdown.cssVars` must emit against
`Theme.default` (light, medium) — the upstream vitest snapshot string.
-}
expectedDropdownVars : List ( String, String )
expectedDropdownVars =
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
    , ( "--n-padding", "4px 0" )
    , ( "--n-space", "6px" )
    , ( "--n-space-arrow", "10px" )
    , ( "--n-option-height", "34px" )
    , ( "--n-option-prefix-width", "14px" )
    , ( "--n-option-icon-prefix-width", "36px" )
    , ( "--n-option-suffix-width", "14px" )
    , ( "--n-option-icon-suffix-width", "32px" )
    , ( "--n-option-icon-size", "16px" )
    , ( "--n-option-opacity-disabled", "0.5" )
    , ( "--n-option-color-hover", "rgb(243, 243, 245)" )
    , ( "--n-option-color-active", "rgba(24, 160, 88, 0.1)" )
    , ( "--n-option-text-color", "rgb(51, 54, 57)" )
    , ( "--n-option-text-color-hover", "rgb(51, 54, 57)" )
    , ( "--n-option-text-color-active", "#18a058" )
    , ( "--n-option-text-color-child-active", "#18a058" )
    , ( "--n-prefix-color", "rgb(51, 54, 57)" )
    , ( "--n-suffix-color", "rgb(51, 54, 57)" )
    , ( "--n-group-header-text-color", "rgb(118, 124, 130)" )
    ]


{-| The derived var lists the checks compare (light/dark × medium/small/inverted).
-}
dMediumVars : List ( String, String )
dMediumVars =
    Dropdown.cssVars Theme.default Dropdown.Medium False


dSmallVars : List ( String, String )
dSmallVars =
    Dropdown.cssVars Theme.default Dropdown.Small False


dInvertedVars : List ( String, String )
dInvertedVars =
    Dropdown.cssVars Theme.default Dropdown.Medium True


dDarkVars : List ( String, String )
dDarkVars =
    Dropdown.cssVars Theme.dark Dropdown.Medium False


dDarkInvertedVars : List ( String, String )
dDarkInvertedVars =
    Dropdown.cssVars Theme.dark Dropdown.Medium True


{-| The keys (in `from`'s order) whose value differs between two same-ordered
var lists — pins that an override swaps _exactly_ the intended keys.
-}
changedVarKeys : List ( String, String ) -> List ( String, String ) -> List String
changedVarKeys from to =
    List.filterMap
        (\( k, v ) ->
            case lookup k to of
                Just v2 ->
                    if v2 == v then
                        Nothing

                    else
                        Just k

                Nothing ->
                    Just k
        )
        from



-- MODAL OPTION SETS -------------------------------------------------------------


mD : Modal.Options Msg
mD =
    Modal.defaults


{-| `Card.defaults` with `bordered = False` — upstream spreads the dialog props
last so the card preset is unbordered inside a modal.
-}
mCardD : Card.Options Msg
mCardD =
    Modal.cardDefaults


mLightVars : List ( String, String )
mLightVars =
    Modal.cssVars Theme.default


mDarkVars : List ( String, String )
mDarkVars =
    Modal.cssVars Theme.dark


{-| `boxShadow3` — identical literal in the light and dark themes.
-}
modalShadow : String
modalShadow =
    "0 6px 16px -9px rgba(0, 0, 0, .08), 0 9px 28px 0 rgba(0, 0, 0, .05), 0 12px 48px 16px rgba(0, 0, 0, .03)"


expectedModalLightVars : List ( String, String )
expectedModalLightVars =
    [ ( "--n-bezier-ease-out", "cubic-bezier(0, 0, .2, 1)" )
    , ( "--n-box-shadow", modalShadow )
    , ( "--n-color", "#fff" )
    , ( "--n-text-color", "rgb(51, 54, 57)" )
    ]


expectedModalDarkVars : List ( String, String )
expectedModalDarkVars =
    [ ( "--n-bezier-ease-out", "cubic-bezier(0, 0, .2, 1)" )
    , ( "--n-box-shadow", modalShadow )
    , ( "--n-color", "rgb(44, 44, 50)" )
    , ( "--n-text-color", "rgba(255, 255, 255, 0.82)" )
    ]


{-| A plain `Card.view` with the composition seams exercised (extraClasses +
root attributes + role) — the seam `NUI.Modal`'s card preset rides on.
-}
mCardSeamOpts : Card.Options Msg
mCardSeamOpts =
    let
        base =
            Card.defaults
    in
    { base
        | extraClasses = [ "seam-a", "seam-b" ]
        , attributes = [ Element.htmlAttribute (HA.attribute "data-seam" "on") ]
        , role = Just "region"
    }



-- DRAWER OPTION SETS ------------------------------------------------------------


drD : Drawer.Options Msg
drD =
    Drawer.defaults


drContentD : DrawerContent.Options Msg
drContentD =
    DrawerContent.defaults


drLightVars : List ( String, String )
drLightVars =
    Drawer.cssVars Theme.default


drDarkVars : List ( String, String )
drDarkVars =
    Drawer.cssVars Theme.dark


{-| `boxShadow3` — identical literal in the light and dark themes.
-}
drawerShadow : String
drawerShadow =
    "0 6px 16px -9px rgba(0, 0, 0, .08), 0 9px 28px 0 rgba(0, 0, 0, .05), 0 12px 48px 16px rgba(0, 0, 0, .03)"


{-| The 25-entry list `NUI.Drawer.cssVars` must emit against `Theme.default` —
upstream `cssVarsRef` declaration order (`Drawer.tsx:267-322`).
-}
expectedDrawerLightVars : List ( String, String )
expectedDrawerLightVars =
    [ ( "--n-line-height", "1.6" )
    , ( "--n-color", "#fff" )
    , ( "--n-border-radius", "3px" )
    , ( "--n-text-color", "rgb(51, 54, 57)" )
    , ( "--n-box-shadow", drawerShadow )
    , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-bezier-out", "cubic-bezier(0, 0, .2, 1)" )
    , ( "--n-bezier-in", "cubic-bezier(.4, 0, 1, 1)" )
    , ( "--n-header-padding", "16px 24px" )
    , ( "--n-body-padding", "16px 24px" )
    , ( "--n-footer-padding", "16px 24px" )
    , ( "--n-title-text-color", "rgb(31, 34, 37)" )
    , ( "--n-title-font-size", "18px" )
    , ( "--n-title-font-weight", "500" )
    , ( "--n-header-border-bottom", "1px solid rgb(239, 239, 245)" )
    , ( "--n-footer-border-top", "1px solid rgb(239, 239, 245)" )
    , ( "--n-close-icon-color", "rgba(102, 102, 102, 1)" )
    , ( "--n-close-icon-color-hover", "rgba(102, 102, 102, 1)" )
    , ( "--n-close-icon-color-pressed", "rgba(102, 102, 102, 1)" )
    , ( "--n-close-size", "22px" )
    , ( "--n-close-color-hover", "rgba(0, 0, 0, .09)" )
    , ( "--n-close-color-pressed", "rgba(0, 0, 0, .13)" )
    , ( "--n-close-icon-size", "18px" )
    , ( "--n-close-border-radius", "3px" )
    , ( "--n-resize-trigger-color-hover", "#36ad6a" )
    ]


{-| A `DrawerContent.view` mount carrying a header slot + title + closable +
footer + body class/style + header class.
-}
drContentFullOpts : DrawerContent.Options Msg
drContentFullOpts =
    let
        base =
            DrawerContent.defaults
    in
    { base
        | title = Just (Element.text "Title")
        , closable = True
        , footer = Just (Element.text "Footer")
        , headerClass = Just "hdr-x"
        , bodyClass = Just "body-x"
        , bodyStyle = Just "color:red"
        , bodyContentClass = Just "bodyc-x"
        , bodyContentStyle = Just "color:blue"
        , footerClass = Just "ftr-x"
    }


{-| `header` slot + `title` both set — the slot must win inside `__main`.
-}
drContentHeaderWinsOpts : DrawerContent.Options Msg
drContentHeaderWinsOpts =
    let
        base =
            DrawerContent.defaults
    in
    { base
        | header = Just (Element.text "SLOT")
        , title = Just (Element.text "TITLE")
    }


{-| `closable` + `onClose` only — the header renders for the close button alone.
-}
drContentCloseOpts : DrawerContent.Options Msg
drContentCloseOpts =
    let
        base =
            DrawerContent.defaults
    in
    { base | closable = True, onClose = Just DrawerClose }


{-| `nativeScrollbar = False` with the upstream quirk fields set: `bodyClass` /
`bodyStyle` must NOT be applied in the scrollbar branch (only the static
`n-drawer-body` class on the scrollbar root), while `bodyContentClass` /
`bodyContentStyle` are.
-}
drContentNonNativeOpts : DrawerContent.Options Msg
drContentNonNativeOpts =
    let
        base =
            DrawerContent.defaults
    in
    { base
        | nativeScrollbar = False
        , title = Just (Element.text "Scroll")
        , bodyClass = Just "should-not-appear"
        , bodyStyle = Just "color:red"
        , bodyContentClass = Just "bodyc-x"
        , bodyContentStyle = Just "color:blue"
        , footer = Just (Element.text "Footer")
    }


{-| A plain `Scrollbar.view` with the new `extraClasses` seam exercised — the
seam `NUI.DrawerContent`'s non-native body rides on.
-}
mScrollbarSeamOpts : Scrollbar.Options Msg
mScrollbarSeamOpts =
    let
        base =
            Scrollbar.defaults
    in
    { base
        | extraClasses = [ "seam-x" ]
        , attributes = [ Element.htmlAttribute (HA.attribute "data-seam" "on") ]
    }



-- DIALOG OPTION SETS -----------------------------------------------------------


dgD : Dialog.Options Msg
dgD =
    Dialog.defaults


{-| The 28-entry list `NUI.Dialog.cssVars` emits for `defaults` (IconLeft) —
upstream `cssVarsRef` declaration order (`Dialog.tsx`).
-}
dgVarsLeft : List ( String, String )
dgVarsLeft =
    Dialog.cssVars Theme.default dgD


{-| `IconTop` — swaps the icon margins to `4px 0 8px 0` and the close margin
to `10px 16px 0 0`.
-}
dgVarsTop : List ( String, String )
dgVarsTop =
    Dialog.cssVars Theme.default { dgD | iconPlacement = Dialog.IconTop }


dgVarsDark : List ( String, String )
dgVarsDark =
    Dialog.cssVars Theme.dark dgD


expectedDialogVarsLeft : List ( String, String )
expectedDialogVarsLeft =
    [ ( "--n-font-size", "14px" )
    , ( "--n-icon-color", "#18a058" )
    , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-close-margin", "20px 26px 0 0" )
    , ( "--n-icon-margin-top", "0" )
    , ( "--n-icon-margin-right", "4px" )
    , ( "--n-icon-margin-bottom", "0" )
    , ( "--n-icon-margin-left", "0" )
    , ( "--n-icon-size", "28px" )
    , ( "--n-close-size", "22px" )
    , ( "--n-close-icon-size", "18px" )
    , ( "--n-close-border-radius", "3px" )
    , ( "--n-close-color-hover", "rgba(0, 0, 0, .09)" )
    , ( "--n-close-color-pressed", "rgba(0, 0, 0, .13)" )
    , ( "--n-close-icon-color", "rgba(102, 102, 102, 1)" )
    , ( "--n-close-icon-color-hover", "rgba(102, 102, 102, 1)" )
    , ( "--n-close-icon-color-pressed", "rgba(102, 102, 102, 1)" )
    , ( "--n-color", "#fff" )
    , ( "--n-text-color", "rgb(51, 54, 57)" )
    , ( "--n-border-radius", "3px" )
    , ( "--n-padding", "16px 28px 20px 28px" )
    , ( "--n-line-height", "1.6" )
    , ( "--n-border", "1px solid rgb(239, 239, 245)" )
    , ( "--n-content-margin", "8px 0 16px 0" )
    , ( "--n-title-font-size", "18px" )
    , ( "--n-title-font-weight", "500" )
    , ( "--n-title-text-color", "rgb(31, 34, 37)" )
    , ( "--n-action-space", "12px" )
    ]


{-| The mode-independent (`self`-only / `_common`) keys — identical literals in
light and dark, so a dark pin proves they do not re-derive from `common`.
-}
dialogSelfOnlyKeys : List String
dialogSelfOnlyKeys =
    [ "--n-padding"
    , "--n-icon-size"
    , "--n-close-size"
    , "--n-close-icon-size"
    , "--n-close-margin"
    , "--n-icon-margin-right"
    , "--n-content-margin"
    , "--n-action-space"
    , "--n-title-font-size"
    , "--n-title-font-weight"
    ]


{-| The `iconPlacement`-keyed subset of the light var list (a fact of §4).
-}
dialogMarginKeys : List String
dialogMarginKeys =
    [ "--n-close-margin"
    , "--n-icon-margin-top"
    , "--n-icon-margin-right"
    , "--n-icon-margin-bottom"
    , "--n-icon-margin-left"
    ]


{-| The kind→`--n-icon-color` matrix at the default (light) theme.
-}
dialogIconColors : List ( T.Kind, String )
dialogIconColors =
    [ ( T.Default, "#18a058" )
    , ( T.Primary, "#18a058" )
    , ( T.Info, "#2080f0" )
    , ( T.Success, "#18a058" )
    , ( T.Warning, "#f0a020" )
    , ( T.Error, "#d03050" )
    ]


{-| A dialog with both button texts, both click handlers and a close handler.
-}
dgActionsOpts : Dialog.Options Msg
dgActionsOpts =
    let
        base =
            Dialog.defaults
    in
    { base
        | title = Just (Element.text "Title")
        , content = Just (Element.text "Body")
        , positiveText = Just "Yes"
        , negativeText = Just "No"
        , onClose = Just DialogClose
        , onPositiveClick = Just DialogPositive
        , onNegativeClick = Just DialogNegative
    }


{-| `loading = True` — the positive button is disabled + loading, the negative
is untouched.
-}
dgLoadingOpts : Dialog.Options Msg
dgLoadingOpts =
    let
        base =
            Dialog.defaults
    in
    { base
        | content = Just (Element.text "Body")
        , positiveText = Just "Yes"
        , negativeText = Just "No"
        , loading = True
    }


{-| All six kinds, so every icon colour + glyph is reachable from one mount set.
-}
dgKindOpts : T.Kind -> Dialog.Options Msg
dgKindOpts kind =
    let
        base =
            Dialog.defaults
    in
    { base | kind = kind, content = Just (Element.text "Body") }


{-| The `positiveProps`/`negativeProps` update-function seam (spread semantics).
-}
dgPropsOpts : Dialog.Options Msg
dgPropsOpts =
    let
        base =
            Dialog.defaults
    in
    { base
        | content = Just (Element.text "Body")
        , positiveText = Just "Yes"
        , negativeText = Just "No"
        , positiveProps = Just (\b -> { b | round = True })
        , negativeProps = Just (\b -> { b | round = True })
    }


{-| A dialog with only `positiveText` (no negative) — pins the kind-derived
positive button class with the negative absent.
-}
dgKindActionOpts : T.Kind -> Dialog.Options Msg
dgKindActionOpts kind =
    let
        base =
            Dialog.defaults
    in
    { base | kind = kind, content = Just (Element.text "Body"), positiveText = Just "Yes" }


{-| A plain Button carrying a caller icon (the `n-icon-slot` wrapper pin).
-}
btnIconOpts : Button.Options Msg
btnIconOpts =
    let
        base =
            Button.defaults
    in
    { base | icon = Just (Element.text "I") }


{-| A Button in the loading state (the `n-button__icon` > NBaseLoading pin).
-}
btnLoadingOpts : Button.Options Msg
btnLoadingOpts =
    let
        base =
            Button.defaults
    in
    { base | loading = True }


{-| A Button in the loading state carrying all-four `spinProps` overrides (the
upstream `{...this.spinProps}` spread into `NBaseLoading` — Button.tsx:648).
-}
btnSpinPropsOpts : Button.Options Msg
btnSpinPropsOpts =
    let
        base =
            Button.defaults
    in
    { base
        | loading = True
        , spinStrokeWidth = Just 6
        , spinStroke = Just "#ff0000"
        , spinScale = Just 2
        , spinRadius = Just 50
    }



-- POPCONFIRM / POPSELECT / SELECTMENU OPTION SETS ------------------------------


{-| The plain defaults binding (`{ Popconfirm.defaults | … }` is a parse error).
-}
pcD : Popconfirm.Options Msg
pcD =
    Popconfirm.defaults


{-| The 4-entry panel var list `NUI.Popconfirm.cssVars` must emit (light):
upstream `PopconfirmPanel.tsx` `cssVarsRef` declaration order.
-}
expectedPopconfirmVars : List ( String, String )
expectedPopconfirmVars =
    [ ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-font-size", "14px" )
    , ( "--n-icon-size", "22px" )
    , ( "--n-icon-color", "#f0a020" )
    ]


{-| The same 4 keys against `Theme.dark`: only `--n-icon-color` re-derives from
common (`warningColor` = `#f2c97d`); the sizes are `_common` literals.
-}
expectedPopconfirmDarkVars : List ( String, String )
expectedPopconfirmDarkVars =
    [ ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-font-size", "14px" )
    , ( "--n-icon-size", "22px" )
    , ( "--n-icon-color", "#f2c97d" )
    ]


{-| The plain defaults binding (`{ Popselect.defaults | … }` is a parse error).
-}
psD : Popselect.Options Msg
psD =
    Popselect.defaults


{-| The light select-menu box-shadow (popselect's single self var = common
`boxShadow2`) — identical to the popover `--n-box-shadow`.
-}
popselectShadow : String
popselectShadow =
    "0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)"


{-| The 23-entry list `NUI.SelectMenu.cssVars` must emit for `Medium` (light):
upstream `SelectMenu.tsx` `cssVarsRef` declaration order.
-}
expectedSelectMenuVarsMedium : List ( String, String )
expectedSelectMenuVarsMedium =
    [ ( "--n-height", "calc(var(--n-option-height) * 7.6)" )
    , ( "--n-action-divider-color", "rgb(239, 239, 245)" )
    , ( "--n-action-text-color", "rgb(51, 54, 57)" )
    , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-border-radius", "3px" )
    , ( "--n-color", "#fff" )
    , ( "--n-option-font-size", "14px" )
    , ( "--n-group-header-text-color", "rgb(118, 124, 130)" )
    , ( "--n-option-check-color", "#18a058" )
    , ( "--n-option-color-pending", "rgb(243, 243, 245)" )
    , ( "--n-option-color-active", "rgba(0, 0, 0, 0)" )
    , ( "--n-option-color-active-pending", "rgb(243, 243, 245)" )
    , ( "--n-option-height", "34px" )
    , ( "--n-option-opacity-disabled", "0.5" )
    , ( "--n-option-text-color", "rgb(51, 54, 57)" )
    , ( "--n-option-text-color-active", "#18a058" )
    , ( "--n-option-text-color-disabled", "rgba(194, 194, 194, 1)" )
    , ( "--n-option-text-color-pressed", "#0c7a43" )
    , ( "--n-option-padding", "0 12px" )
    , ( "--n-option-padding-left", "12px" )
    , ( "--n-option-padding-right", "12px" )
    , ( "--n-loading-color", "#18a058" )
    , ( "--n-loading-size", "18px" )
    ]


{-| The merged 39-entry list `NUI.Popselect.cssVars` must emit: the 23 select-menu
vars, `--n-menu-box-shadow`, then the 15 popover vars with `--n-padding`
overridden to `0` (upstream `builtinThemeOverrides`).
-}
expectedPopselectVars : List ( String, String )
expectedPopselectVars =
    expectedSelectMenuVarsMedium
        ++ [ ( "--n-menu-box-shadow", popselectShadow ) ]
        ++ List.map
            (\( k, v ) ->
                if k == "--n-padding" then
                    ( k, "0" )

                else
                    ( k, v )
            )
            expectedPopoverVars


{-| One leaf select-menu option.
-}
smLeaf : String -> String -> SelectMenu.Option Msg
smLeaf value label =
    SelectMenu.Option { value = value, label = label, disabled = False, attributes = [] }


{-| A leaf carried by a caller attribute (the `--pending`/`attributes` seam).
-}
smLeafAttr : String -> String -> Element.Attribute Msg -> SelectMenu.Option Msg
smLeafAttr value label attribute =
    SelectMenu.Option { value = value, label = label, disabled = False, attributes = [ attribute ] }


{-| The cascader fixture — a with a leaf, a disabled-leaf branch, and a
loaded-but-empty branch; a disabled root `b` with a child; a root leaf `c`
(the same tree the real treemate package produced the pinned outputs on).
-}
cascTree : List Cascader.Option
cascTree =
    [ Cascader.Option
        { value = "a"
        , label = "A"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "a1", label = "A1", disabled = False, children = Nothing }
                , Cascader.Option
                    { value = "a2"
                    , label = "A2"
                    , disabled = False
                    , children =
                        Just
                            [ Cascader.Option { value = "a2x", label = "A2X", disabled = True, children = Nothing }
                            , Cascader.Option { value = "a2y", label = "A2Y", disabled = False, children = Nothing }
                            ]
                    }
                , Cascader.Option { value = "a3", label = "A3", disabled = False, children = Just [] }
                ]
        }
    , Cascader.Option
        { value = "b"
        , label = "B"
        , disabled = True
        , children =
            Just [ Cascader.Option { value = "b1", label = "B1", disabled = False, children = Nothing } ]
        }
    , Cascader.Option { value = "c", label = "C", disabled = False, children = Nothing }
    ]


cascMenuD : Cascader.MenuOptions msg
cascMenuD =
    Cascader.menuDefaults


cascSelectMenuD : Cascader.SelectMenuOptions msg
cascSelectMenuD =
    Cascader.selectMenuDefaults


{-| The minimal mixed-order fixtures — parent `m` with an unchecked leaf
followed by a checked one, and the mirror `m2` (checked first). Real
treemate lands BOTH parents in the indeterminate set whatever the order
(the scan only breaks on an unchecked child when partial is already set).
-}
cascMixedTree : List Cascader.Option
cascMixedTree =
    [ Cascader.Option
        { value = "m"
        , label = "M"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "mu", label = "MU", disabled = False, children = Nothing }
                , Cascader.Option { value = "mc", label = "MC", disabled = False, children = Nothing }
                ]
        }
    ]


cascMixedTreeRev : List Cascader.Option
cascMixedTreeRev =
    [ Cascader.Option
        { value = "m2"
        , label = "M2"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "mc2", label = "MC2", disabled = False, children = Nothing }
                , Cascader.Option { value = "mu2", label = "MU2", disabled = False, children = Nothing }
                ]
        }
    ]


{-| The tree fixture — mirrors the cascader one (a branch with a leaf, a
nested branch, a loaded-but-empty branch, a disabled root with a child, a
root leaf) so the treemate pins run on a tree with the same shape upstream's
tests use: enough for the indent chain, the `--last-child` / `--is-leaf`
guide lines, the checkable cascade and the disabled state.
-}
treeFixture : List (Tree.TreeOption msg)
treeFixture =
    [ Tree.TreeOption
        { key = "a"
        , label = "A"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children =
            Just
                [ treeLeaf "a1" "A1"
                , Tree.TreeOption
                    { key = "a2"
                    , label = "A2"
                    , disabled = False
                    , checkboxDisabled = False
                    , isLeaf = False
                    , children =
                        Just
                            [ { key = "a2x"
                              , label = "A2X"
                              , disabled = True
                              , checkboxDisabled = False
                              , isLeaf = True
                              , children = Nothing
                              , prefix = []
                              , suffix = []
                              }
                                |> Tree.TreeOption
                            , treeLeaf "a2y" "A2Y"
                            ]
                    , prefix = []
                    , suffix = []
                    }
                , { key = "a3"
                  , label = "A3"
                  , disabled = False
                  , checkboxDisabled = False
                  , isLeaf = False
                  , children = Just []
                  , prefix = []
                  , suffix = []
                  }
                    |> Tree.TreeOption
                ]
        , prefix = []
        , suffix = []
        }
    , Tree.TreeOption
        { key = "b"
        , label = "B"
        , disabled = True
        , checkboxDisabled = False
        , isLeaf = False
        , children = Just [ treeLeaf "b1" "B1" ]
        , prefix = []
        , suffix = []
        }
    , treeLeaf "c" "C"
    ]


treeLeaf : String -> String -> Tree.TreeOption msg
treeLeaf key label =
    Tree.TreeOption
        { key = key
        , label = label
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = True
        , children = Nothing
        , prefix = []
        , suffix = []
        }


{-| The treemate mixed-order scan fixture (`lib/check.js` break rule): an
unchecked leaf BEFORE a checked one — the parent must land in the
indeterminate set (the pre-fix port stopped the scan early).
-}
mixedTree : List (Tree.TreeOption msg)
mixedTree =
    [ Tree.TreeOption
        { key = "p"
        , label = "P"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children = Just [ treeLeaf "u" "U", treeLeaf "c" "C", treeLeaf "u2" "U2" ]
        , prefix = []
        , suffix = []
        }
    ]


{-| The unloaded branch — `isLeaf = False` with `children = Nothing`
(treemate `isExpilicitlyNotLoaded`): a visible non-leaf the switcher
renders (the spinner shows while its key is in `loadingKeys`).
-}
unloadedTree : List (Tree.TreeOption msg)
unloadedTree =
    [ Tree.TreeOption
        { key = "x"
        , label = "X"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children = Nothing
        , prefix = []
        , suffix = []
        }
    ]


{-| The flattened rows, as their keys (the `flatten` pin reads shape, not
raw records).
-}
treeFlatKeys : List (Tree.FlatNode msg) -> List String
treeFlatKeys rows =
    List.map .key rows


{-| The plain defaults binding for the live renders.
-}
treeD : Tree.Options msg
treeD =
    Tree.defaults


{-| The plain table defaults binding (the `let d = Table.defaults` pattern).
-}
tblD : Table.Options msg
tblD =
    Table.defaults


{-| One table cell with just text content (spans unset, no attributes).
-}
tblCell : String -> Table.Cell msg
tblCell s =
    let
        d =
            Table.cellDefaults
    in
    { d | content = [ Element.text s ] }


{-| A 2-column head + 3 body rows fixture — the pin target for the live
views and the DOM checks (`thead > tr > th` count 2, `tbody > tr > td` 6).
-}
tblTable : Table.Table msg
tblTable =
    { head =
        [ { cells = [ tblCell "Name", tblCell "Count" ], attributes = [] } ]
    , body =
        [ { cells = [ tblCell "Alpha", tblCell "1" ], attributes = [] }
        , { cells = [ tblCell "Beta", tblCell "2" ], attributes = [] }
        , { cells = [ tblCell "Gamma", tblCell "3" ], attributes = [] }
        ]
    }


{-| A span fixture — one `colspan 2` head cell and one `rowspan 2` body cell.
-}
tblSpanTable : Table.Table msg
tblSpanTable =
    let
        spanned =
            tblCell "Span"

        a =
            tblCell "A"
    in
    { head =
        [ { cells = [ { spanned | colspan = Just 2 } ], attributes = [] } ]
    , body =
        [ { cells = [ { a | rowspan = Just 2 }, tblCell "B" ], attributes = [] }
        , { cells = [ tblCell "C" ], attributes = [] }
        ]
    }


tblVar : Theme.Theme -> Table.Options msg -> String -> Maybe String
tblVar theme opts key =
    lookup key (Table.cssVars theme opts)


{-| The plain watermark defaults binding (the `let d = Watermark.defaults`
record-update pattern).
-}
wmD : Watermark.Options msg
wmD =
    Watermark.defaults


{-| One watermark option set derived from `wmD` by a single update.
-}
wmWith : (Watermark.Options msg -> Watermark.Options msg) -> Watermark.Options msg
wmWith f =
    let
        d =
            wmD
    in
    f d


{-| The `cross` + odd-size fixture (width/height 5, xGap 3, yGap 2) — pins
the odd `width/2` half-pixel formatting (D1: fractional Center anchor) and
the `(xGap+width)×(yGap+height)` tile dimensions.
-}
crossOpts : Watermark.Options msg
crossOpts =
    wmWith
        (\d ->
            { d
                | cross = True
                , width = 5
                , height = 5
                , xGap = 3
                , yGap = 2
                , xOffset = 1
                , yOffset = 1
                , content = Just "a\nb"
                , rotate = 15
                , fontSize = 10
                , fontColor = "red"
                , lineHeight = 2
                , textAlign = Watermark.Center
                , fontFamily = Just "F"
            }
        )


{-| `globalRotate` alone (cross on) — the `max(142vh, 142vw)` positioning
pair and the overlay `transform`.
-}
globalOpts : Watermark.Options msg
globalOpts =
    wmWith (\d -> { d | cross = True, content = Just "x", fontFamily = Just "F", globalRotate = 45 })


{-| `fullscreen` + `globalRotate` — the z-index handoff (container carries
it, overlay drops it).
-}
handoffOpts : Watermark.Options msg
handoffOpts =
    wmWith (\d -> { d | content = Just "x", fontFamily = Just "F", fullscreen = True, zIndex = 7, globalRotate = 30 })


{-| `fullscreen` without `globalRotate` — the bare branch (no container,
children dropped).
-}
bareOpts : Watermark.Options msg
bareOpts =
    wmWith (\d -> { d | content = Just "x", fontFamily = Just "F", fullscreen = True })


{-| The `image` path — `url(src)` with `cross` doubling, no tile.
-}
imageOpts : Watermark.Options msg
imageOpts =
    wmWith (\d -> { d | cross = True, image = Just "pic.png", fontFamily = Just "F" })


{-| The tile SVG the port is expected to produce — the upstream
`canvas.toDataURL()` seam, rebuilt as SVG (post-oracle-fix bytes: S1
`font-weight` at ≠ 400, D1 fractional Center anchor, D2 debug grey rect
only with non-empty content, D3 `font-family = Just ""` falls back to the
theme var). Written out independently of `NUI.Watermark`'s internals so the
eq pins compare real bytes.
-}
wmExpectedSvg :
    { width : Int
    , height : Int
    , xGap : Int
    , yGap : Int
    , xOffset : Int
    , yOffset : Int
    , rotate : Float
    , fontSize : Int
    , fontColor : String
    , fontFamily : String
    , fontStyle : String
    , fontVariant : String
    , fontStretch : String
    , fontWeight : Int
    , lineHeight : Int
    , textAlign : Watermark.TextAlign
    , content : Maybe String
    , debug : Bool
    }
    -> String
wmExpectedSvg p =
    let
        debugRect stroke =
            "<rect x=\"0\" y=\"0\" width=\""
                ++ String.fromInt p.width
                ++ "\" height=\""
                ++ String.fromInt p.height
                ++ "\" fill=\"none\" stroke=\""
                ++ stroke
                ++ "\"/>"

        lines =
            case p.content of
                Nothing ->
                    []

                Just text ->
                    if String.isEmpty text then
                        []

                    else
                        String.split "\n" text

        textNode index line =
            let
                ( anchorName, anchorX ) =
                    case p.textAlign of
                        Watermark.Left ->
                            ( "start", String.fromInt p.xOffset )

                        Watermark.Center ->
                            ( "middle", halfPx (p.xOffset * 2 + p.width) )

                        Watermark.Right ->
                            ( "end", String.fromInt (p.xOffset + p.width) )
            in
            "<text x=\""
                ++ anchorX
                ++ "\" y=\""
                ++ String.fromInt (p.yOffset + p.lineHeight * (index + 1))
                ++ "\" text-anchor=\""
                ++ anchorName
                ++ "\">"
                ++ wmEscapeXml line
                ++ "</text>"

        mark =
            if lines == [] then
                ""

            else
                (if p.debug then
                    debugRect "green"

                 else
                    ""
                )
                    ++ String.concat (List.indexedMap textNode lines)

        ifNot name value neutral =
            if value == neutral then
                ""

            else
                " " ++ name ++ "=\"" ++ wmEscapeXml value ++ "\""

        ifNotInt name value neutral =
            if value == neutral then
                ""

            else
                " " ++ name ++ "=\"" ++ String.fromInt value ++ "\""
    in
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\""
        ++ String.fromInt (p.xGap + p.width)
        ++ "\" height=\""
        ++ String.fromInt (p.yGap + p.height)
        ++ "\">"
        ++ (if p.debug && lines /= [] then
                debugRect "grey"

            else
                ""
           )
        ++ "<g transform=\"rotate("
        ++ String.fromFloat p.rotate
        ++ ")\""
        ++ (" font-family=\""
                ++ wmEscapeXml p.fontFamily
                ++ "\" font-size=\""
                ++ String.fromInt p.fontSize
                ++ "\" fill=\""
                ++ wmEscapeXml p.fontColor
                ++ "\""
                ++ ifNot "font-style" p.fontStyle "normal"
                ++ ifNot "font-variant" p.fontVariant ""
                ++ ifNotInt "font-weight" p.fontWeight 400
                ++ ifNot "font-stretch" p.fontStretch ""
           )
        ++ ">"
        ++ mark
        ++ "</g></svg>"


{-| `${n / 2}` with JavaScript's number formatting — "16" for 32,
"2.5" for 5 (D1's fractional Center anchor).
-}
halfPx : Int -> String
halfPx n =
    if remainderBy 2 n == 0 then
        String.fromInt (n // 2)

    else
        String.fromFloat (toFloat n / 2)


wmEscapeXml : String -> String
wmEscapeXml =
    String.replace "&" "&amp;"
        >> String.replace "<" "&lt;"
        >> String.replace ">" "&gt;"
        >> String.replace "\"" "&quot;"
        >> String.replace "'" "&apos;"


{-| `tileDataUrl` with the `data:image/svg+xml;base64,` prefix stripped —
the raw base64 payload, for round-trip comparison against
`Buffer.from(svg).toString('base64')`.
-}
wmTileB64 : Theme.Theme -> Watermark.Options msg -> String
wmTileB64 theme opts =
    String.replace "data:image/svg+xml;base64," "" (Watermark.tileDataUrl theme opts)


{-| The `n-watermark` overlay's inline style pairs as a `k:v;k:v` string —
mirrors `Internal.renderVars` so the pins read the same bytes the DOM does.
-}
wmStyleStr : Theme.Theme -> Watermark.Options msg -> String
wmStyleStr theme opts =
    Watermark.watermarkStyle theme opts
        |> List.filter (\( _, v ) -> v /= "initial" && not (String.isEmpty v))
        |> List.map (\( k, v ) -> k ++ ":" ++ v)
        |> String.join ";"


{-| The flat rows of a `filterOptions` run, as their values.
-}
cascRowValues : List (SelectMenu.Option msg) -> List String
cascRowValues rows =
    List.filterMap
        (\row ->
            case row of
                SelectMenu.Option leaf ->
                    Just leaf.value

                _ ->
                    Nothing
        )
        rows


{-| The plain defaults binding (`{ SelectMenu.defaults | … }` is a parse error).
-}
smD : SelectMenu.Options Msg
smD =
    SelectMenu.defaults



-- SELECT / BASESELECTION OPTION SETS -------------------------------------------


{-| The plain defaults bindings (`{ X.defaults | … }` is a parse error).
-}
bsD : BaseSelection.Options Msg
bsD =
    BaseSelection.defaults


swD : Switch.Options Msg
swD =
    Switch.defaults


selD : Select.Options Msg
selD =
    Select.defaults


{-| The menu options — `NUI.Select.menuDefaults` is unexposed, so the record is
spelled out (upstream `InternalSelectMenu` defaults: absent `size` = medium).
-}
selMenuD : Select.MenuOptions Msg
selMenuD =
    { size = Nothing
    , multiple = False
    , value = SelectMenu.Single Nothing
    , showCheckmark = True
    , loading = False
    , header = Nothing
    , action = Nothing
    , empty = Nothing
    , onToggle = Nothing
    , scrollbarProps = Nothing
    , transition = Nothing
    , rtl = False
    , attributes = []
    }


{-| One `NUI.BaseSelection` multiple-mode tag (the wrapper + `NTag` pair).
-}
bsTag : String -> String -> BaseSelection.Tag Msg
bsTag value label =
    BaseSelection.Tag { value = value, label = label, disabled = False }


{-| The options the trigger-derivation live renders select from.
-}
selOptions : List (SelectMenu.Option Msg)
selOptions =
    [ smLeaf "a" "A"
    , smLeaf "b" "B"
    , smLeaf "c" "C"
    , smLeaf "d" "D"
    , smLeaf "e" "E"
    , smLeaf "drive" "Drive My Car"
    ]


{-| The small option set the `filterOptions` pins match against.
-}
selFilterOpts : List (SelectMenu.Option Msg)
selFilterOpts =
    [ smLeaf "drive" "Drive My Car", smLeaf "walk" "Walk" ]



-- AUTOCOMPLETE OPTION SETS -----------------------------------------------------


{-| The plain defaults bindings (`{ AutoComplete.defaults | … }` is a parse error).
-}
acD : AutoComplete.Options Msg
acD =
    AutoComplete.defaults


acMenuD : AutoComplete.MenuOptions Msg
acMenuD =
    AutoComplete.menuDefaults


{-| The 24-entry list `NUI.AutoComplete.menuVars` must emit: the 23
`NUI.SelectMenu` vars at Medium plus AutoComplete's one own var
`--n-menu-box-shadow` (the `NUI.Theme.AutoComplete` single self var = common
`boxShadow2`, byte-identical to `NUI.Theme.Select.menuBoxShadow`). Upstream
re-emits `--n-bezier` here too (same value) — the port emits it once, so the
count is 24, not 25.
-}
expectedAutoCompleteMenuVars : List ( String, String )
expectedAutoCompleteMenuVars =
    expectedSelectMenuVarsMedium ++ [ ( "--n-menu-box-shadow", popselectShadow ) ]



-- MENTION OPTION SETS ----------------------------------------------------------


{-| The plain defaults bindings (`{ Mention.defaults | … }` is a parse error).
-}
mnD : Mention.Options Msg
mnD =
    Mention.defaults


mnMenuD : Mention.MenuOptions Msg
mnMenuD =
    Mention.menuDefaults


{-| The 24-entry list `NUI.Mention.menuVars` must emit: the 23 `NUI.SelectMenu`
vars at Medium plus Mention's one own var `--n-menu-box-shadow` (the
`NUI.Theme.Mention` single self var = common `boxShadow2`, the
select/auto-complete/popselect twin). The port emits `--n-bezier` once, so the
count is 24, not 25.
-}
expectedMentionMenuVars : List ( String, String )
expectedMentionMenuVars =
    expectedSelectMenuVarsMedium ++ [ ( "--n-menu-box-shadow", popselectShadow ) ]



-- SHAPE HELPERS ----------------------------------------------------------------


{-| A comparable shape for a `NUI.SelectMenu.Option` list (the records carry
`Element`s, so `==` is unavailable).
-}
smShape : List (SelectMenu.Option msg) -> List String
smShape options =
    List.map
        (\option ->
            case option of
                SelectMenu.Option leaf ->
                    "opt:" ++ leaf.value

                SelectMenu.Group group ->
                    "group:" ++ group.label ++ "[" ++ String.join "," (smShape group.children) ++ "]"

                SelectMenu.Custom custom ->
                    "custom:" ++ custom.key
        )
        options


{-| The 52-entry list `NUI.BaseSelection.cssVars` must emit for `Medium` (light):
upstream `Selection.tsx` `cssVarsRef` declaration order; values equal the
`Select.spec.tsx.snap` medium variant.
-}
expectedBaseSelectionVarsMedium : List ( String, String )
expectedBaseSelectionVarsMedium =
    [ ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-border", "1px solid rgb(224, 224, 230)" )
    , ( "--n-border-active", "1px solid #18a058" )
    , ( "--n-border-focus", "1px solid #36ad6a" )
    , ( "--n-border-hover", "1px solid #36ad6a" )
    , ( "--n-border-radius", "3px" )
    , ( "--n-box-shadow-active", "0 0 0 2px rgba(24, 160, 88, 0.2)" )
    , ( "--n-box-shadow-focus", "0 0 0 2px rgba(24, 160, 88, 0.2)" )
    , ( "--n-box-shadow-hover", "none" )
    , ( "--n-caret-color", "#18a058" )
    , ( "--n-color", "rgba(255, 255, 255, 1)" )
    , ( "--n-color-active", "rgba(255, 255, 255, 1)" )
    , ( "--n-color-disabled", "rgb(250, 250, 252)" )
    , ( "--n-font-size", "14px" )
    , ( "--n-height", "34px" )
    , ( "--n-padding-single-top", "0" )
    , ( "--n-padding-multiple-top", "3px" )
    , ( "--n-padding-single-right", "26px" )
    , ( "--n-padding-multiple-right", "26px" )
    , ( "--n-padding-single-left", "12px" )
    , ( "--n-padding-multiple-left", "12px" )
    , ( "--n-padding-single-bottom", "0" )
    , ( "--n-padding-multiple-bottom", "0" )
    , ( "--n-placeholder-color", "rgba(194, 194, 194, 1)" )
    , ( "--n-placeholder-color-disabled", "rgba(209, 209, 209, 1)" )
    , ( "--n-text-color", "rgb(51, 54, 57)" )
    , ( "--n-text-color-disabled", "rgba(194, 194, 194, 1)" )
    , ( "--n-arrow-color", "rgba(194, 194, 194, 1)" )
    , ( "--n-arrow-color-disabled", "rgba(209, 209, 209, 1)" )
    , ( "--n-loading-color", "#18a058" )
    , ( "--n-color-active-warning", "rgba(255, 255, 255, 1)" )
    , ( "--n-box-shadow-focus-warning", "0 0 0 2px rgba(240, 160, 32, 0.2)" )
    , ( "--n-box-shadow-active-warning", "0 0 0 2px rgba(240, 160, 32, 0.2)" )
    , ( "--n-box-shadow-hover-warning", "none" )
    , ( "--n-border-warning", "1px solid #f0a020" )
    , ( "--n-border-focus-warning", "1px solid #fcb040" )
    , ( "--n-border-hover-warning", "1px solid #fcb040" )
    , ( "--n-border-active-warning", "1px solid #f0a020" )
    , ( "--n-color-active-error", "rgba(255, 255, 255, 1)" )
    , ( "--n-box-shadow-focus-error", "0 0 0 2px rgba(208, 48, 80, 0.2)" )
    , ( "--n-box-shadow-active-error", "0 0 0 2px rgba(208, 48, 80, 0.2)" )
    , ( "--n-box-shadow-hover-error", "none" )
    , ( "--n-border-error", "1px solid #d03050" )
    , ( "--n-border-focus-error", "1px solid #de576d" )
    , ( "--n-border-hover-error", "1px solid #de576d" )
    , ( "--n-border-active-error", "1px solid #d03050" )
    , ( "--n-clear-size", "16px" )
    , ( "--n-clear-color", "rgba(194, 194, 194, 1)" )
    , ( "--n-clear-color-hover", "rgba(146, 146, 146, 1)" )
    , ( "--n-clear-color-pressed", "rgba(175, 175, 175, 1)" )
    , ( "--n-arrow-size", "16px" )
    , ( "--n-font-weight", "400" )
    ]



-- CHECKS -----------------------------------------------------------------------


{-| The menu fixtures — one tree shared by the eq checks and the DOM
probes (submenu > group > leaf nesting, an extra'd submenu with an icon, a
lone divider, a root group) plus the disabled-injection tree (S2).
-}
menuD : Menu.Options Msg
menuD =
    Menu.defaults


menuWith : (Menu.Options Msg -> Menu.Options Msg) -> Menu.Options Msg
menuWith f =
    let
        d =
            menuD
    in
    f d


menuIcon : Element Msg
menuIcon =
    Element.text "i"


menuLeaf : String -> Menu.Option Msg
menuLeaf key =
    Menu.Option
        { key = key
        , label = key
        , extra = Nothing
        , icon = Nothing
        , disabled = False
        , children = Nothing
        , attributes = []
        }


menuTree : List (Menu.Option Msg)
menuTree =
    [ menuLeaf "root-leaf"
    , Menu.Divider { attributes = [] }
    , Menu.Option
        { key = "sub-1"
        , label = "Sub1"
        , extra = Just "3"
        , icon = Just menuIcon
        , disabled = False
        , children =
            Just
                [ menuLeaf "sub-leaf"
                , Menu.Group
                    { key = "sub-1-g"
                    , label = "G1"
                    , extra = Just "2"
                    , disabled = False
                    , children =
                        [ menuLeaf "grp-leaf"
                        , Menu.Option
                            { key = "grp-sub"
                            , label = "GrpSub"
                            , extra = Nothing
                            , icon = Nothing
                            , disabled = False
                            , children = Just [ menuLeaf "grp-sub-leaf" ]
                            , attributes = []
                            }
                        ]
                    , attributes = []
                    }
                ]
        , attributes = []
        }
    , Menu.Option
        { key = "sub-2"
        , label = "Sub2"
        , extra = Nothing
        , icon = Nothing
        , disabled = False
        , children = Just [ menuLeaf "sub-2-leaf" ]
        , attributes = []
        }
    , Menu.Group
        { key = "top-g"
        , label = "TopG"
        , extra = Nothing
        , disabled = False
        , children = [ menuLeaf "top-g-leaf" ]
        , attributes = []
        }
    ]


{-| The disabled-injection fixture (upstream MenuOption.tsx:31-37 ternary +
MenuOptionGroup.tsx:31-35): a disabled group kills its leaf children but
not its submenus; a group under a submenu never reaches that submenu's
leaves (the submenu injection wins).
-}
menuGDisTree : List (Menu.Option Msg)
menuGDisTree =
    [ Menu.Group
        { key = "gdis-g"
        , label = "gdis-g"
        , extra = Nothing
        , disabled = True
        , children =
            [ menuLeaf "gdis-leaf"
            , Menu.Option
                { key = "gdis-sub"
                , label = "gdis-sub"
                , extra = Nothing
                , icon = Nothing
                , disabled = False
                , children = Just [ menuLeaf "gdis-sub-leaf" ]
                , attributes = []
                }
            ]
        , attributes = []
        }
    , Menu.Option
        { key = "gdis-out"
        , label = "gdis-out"
        , extra = Nothing
        , icon = Nothing
        , disabled = False
        , children =
            Just
                [ Menu.Group
                    { key = "gdis-deep-g"
                    , label = "gdis-deep-g"
                    , extra = Nothing
                    , disabled = True
                    , children = [ menuLeaf "gdis-deep" ]
                    , attributes = []
                    }
                ]
        , attributes = []
        }
    ]


menuVarValue : String -> List ( String, String ) -> String
menuVarValue name vars =
    vars
        |> List.filter (\( k, _ ) -> k == name)
        |> List.map Tuple.second
        |> String.concat


dropdownKind : Dropdown.Option msg -> String
dropdownKind option =
    case option of
        Dropdown.Option leaf ->
            case leaf.children of
                Just _ ->
                    "submenu:" ++ leaf.key

                Nothing ->
                    "leaf:" ++ leaf.key

        Dropdown.Group group ->
            "group:" ++ group.key

        Dropdown.Divider _ ->
            "divider"

        Dropdown.Custom _ ->
            "custom"


{-| The slider fixtures — the 34/75 marks (upstream spec-tree shape) and
the defaults binding for the eq checks + DOM probes.
-}
sliderD : Slider.Options Msg
sliderD =
    Slider.defaults


sliderMarks : List Slider.Mark
sliderMarks =
    [ { value = 34, label = "34" }
    , { value = 75, label = "75" }
    ]


sliderVars : List ( String, String )
sliderVars =
    Slider.cssVars Theme.default


sliderVarValue : String -> List ( String, String ) -> String
sliderVarValue name vars =
    vars
        |> List.filter (\( k, _ ) -> k == name)
        |> List.map Tuple.second
        |> String.concat


{-| The image fixtures — the defaults binding for the eq checks + DOM
probes (broken/fallback URLs mirror the upstream spec tree).
-}
imageD : Image.Options Msg
imageD =
    Image.defaults


imageVars : List ( String, String )
imageVars =
    Image.cssVars Theme.default


imageDarkVars : List ( String, String )
imageDarkVars =
    Image.cssVars Theme.dark


imageVarValue : String -> List ( String, String ) -> String
imageVarValue name vars =
    vars
        |> List.filter (\( k, _ ) -> k == name)
        |> List.map Tuple.second
        |> String.concat


{-| The preview/group fixtures — defaults bindings for the eq checks + DOM
probes. `groupSkipped` is the walk case: an empty (falsy) url in the middle
that `nextIndex`/`prevIndex` must skip (upstream findNext/findPrev truthiness).
-}
previewD : ImagePreview.Options Msg
previewD =
    ImagePreview.defaults


previewZoom0 : ImagePreview.Zoom
previewZoom0 =
    ImagePreview.zoom0


previewVars : List ( String, String )
previewVars =
    ImagePreview.cssVars Theme.default


groupD : ImageGroup.Options Msg
groupD =
    ImageGroup.defaults


groupSkipped : ImageGroup.Options Msg
groupSkipped =
    { groupD
        | srcList =
            [ "https://a/one.jpeg"
            , ""
            , "https://a/three.jpeg"
            ]
    }


{-| Rect literals for the derivedOffset clamp: one that fits both axes and
one oversized overhang (negative left/top, right/bottom past the viewport).
-}
fitsRect : ImagePreview.Rect
fitsRect =
    { left = 0, top = 0, width = 300, height = 200, right = 300, bottom = 200 }


overhangRect : ImagePreview.Rect
overhangRect =
    { left = -200
    , top = -300
    , width = 1200
    , height = 1200
    , right = 1000
    , bottom = 900
    }


{-| The `imgStyle` pair list joined the way the style attribute serializes —
`k: v;` per entry, single-space separated — so pins read as upstream
`cssText` bytes.
-}
stylePairsString : List ( String, String ) -> String
stylePairsString pairs =
    List.map (\( k, v ) -> k ++ ": " ++ v ++ ";") pairs
        |> String.join " "


{-| keyAction rendered as names (the KeyAction union has no Eq instance).
-}
previewKeyName : String -> String
previewKeyName key =
    case ImagePreview.keyAction key of
        Just ImagePreview.SpacePrevent ->
            "space"

        Just ImagePreview.Prev ->
            "prev"

        Just ImagePreview.Next ->
            "next"

        Just ImagePreview.ZoomInKey ->
            "in"

        Just ImagePreview.ZoomOutKey ->
            "out"

        Just ImagePreview.Close ->
            "close"

        Nothing ->
            "miss"



{-
   | The message/notification fixtures — the first service-style ports. The
   | provider + queue is one caller-owned `State`; the pins below derive from
   | upstream's spec bytes (Message.spec.tsx / Notification.spec.tsx) and the
   | provider/environment loop, NOT from the port's output.
-}


messageD : Message.Options Msg
messageD =
    Message.defaults


messageS : Message.State Msg
messageS =
    Message.init


messageI : Message.Item Msg
messageI =
    Message.item


noteD : Notification.Options Msg
noteD =
    Notification.defaults


noteS : Notification.State Msg
noteS =
    Notification.init


noteI : Notification.Item Msg
noteI =
    Notification.item


dgPD : DialogProvider.Item Msg
dgPD =
    DialogProvider.item


dgPS : DialogProvider.State Msg
dgPS =
    DialogProvider.init



{-
   | The data-table fixtures — batch-1 core static table. The pins derive from
   | the upstream vitest snapshot (DataTable.spec.tsx.snap, the `size` prop
   | block — THE rendered-DOM ground truth) and the basic/border/empty spec
   | blocks, NOT from the port's output.
-}


type alias DtRow =
    { name : String
    , age : Int
    , address : String
    }


dtRows : List DtRow
dtRows =
    [ { name = "John Brown", age = 32, address = "New York No. 1 Lake Park" }
    , { name = "Jim Green", age = 42, address = "London No. 1 Lake Park" }
    , { name = "Joe Black", age = 32, address = "Sidney No. 1 Lake Park" }
    ]


dtNameCol : DataTable.Column DtRow Msg
dtNameCol =
    { key = "name"
    , title = "Name"
    , view = .name >> Element.text
    , align = Nothing
    , titleAlign = Nothing
    , width = Nothing
    , minWidth = Nothing
    , maxWidth = Nothing
    , className = Nothing
    , sorter = Nothing
    , defaultSortOrder = DataTable.NoSort
    , sortOrder = Nothing
    , filter = Nothing
    , filterOptions = Nothing
    , filterOptionValues = Nothing
    , filterOptionValue = Nothing
    , filterMode = DataTable.FilterOr
    , defaultFilterOptionValues = Nothing
    , defaultFilterOptionValue = Nothing
    , filterMultiple = True
    , kind = DataTable.KindNormal
    , multiple = True
    , disabled = Nothing
    , options = []
    , renderExpand = Nothing
    , expandable = Nothing
    , fixed = Nothing
    , ellipsis = Nothing
    , children = Nothing
    , titleColSpan = Nothing
    , colSpan = Nothing
    , rowSpan = Nothing
    }


dtAgeCol : DataTable.Column DtRow Msg
dtAgeCol =
    { key = "age"
    , title = "Age"
    , view = .age >> String.fromInt >> Element.text
    , align = Nothing
    , titleAlign = Nothing
    , width = Just 100
    , minWidth = Nothing
    , maxWidth = Nothing
    , className = Nothing
    , sorter = Nothing
    , defaultSortOrder = DataTable.NoSort
    , sortOrder = Nothing
    , filter = Nothing
    , filterOptions = Nothing
    , filterOptionValues = Nothing
    , filterOptionValue = Nothing
    , filterMode = DataTable.FilterOr
    , defaultFilterOptionValues = Nothing
    , defaultFilterOptionValue = Nothing
    , filterMultiple = True
    , kind = DataTable.KindNormal
    , multiple = True
    , disabled = Nothing
    , options = []
    , renderExpand = Nothing
    , expandable = Nothing
    , fixed = Nothing
    , ellipsis = Nothing
    , children = Nothing
    , titleColSpan = Nothing
    , colSpan = Nothing
    , rowSpan = Nothing
    }


dtAddressCol : DataTable.Column DtRow Msg
dtAddressCol =
    { key = "address"
    , title = "Address"
    , view = .address >> Element.text
    , align = Just DataTable.AlignCenter
    , titleAlign = Nothing
    , width = Nothing
    , minWidth = Just 200
    , maxWidth = Just 300
    , className = Nothing
    , sorter = Nothing
    , defaultSortOrder = DataTable.NoSort
    , sortOrder = Nothing
    , filter = Nothing
    , filterOptions = Nothing
    , filterOptionValues = Nothing
    , filterOptionValue = Nothing
    , filterMode = DataTable.FilterOr
    , defaultFilterOptionValues = Nothing
    , defaultFilterOptionValue = Nothing
    , filterMultiple = True
    , kind = DataTable.KindNormal
    , multiple = True
    , disabled = Nothing
    , options = []
    , renderExpand = Nothing
    , expandable = Nothing
    , fixed = Nothing
    , ellipsis = Nothing
    , children = Nothing
    , titleColSpan = Nothing
    , colSpan = Nothing
    , rowSpan = Nothing
    }


dtOpts : DataTable.Options DtRow Msg
dtOpts =
    let
        d =
            DataTable.defaults
    in
    { d
        | columns = [ dtNameCol, dtAgeCol, dtAddressCol ]
        , data = dtRows
        , rowKey = .name
    }


{-| The `multiple sorter` spec fixture (DataTable.spec.tsx:379-460) — the
four students byte-for-byte (Jim Red's address is "London No. 2 Lake Park"
in the spec bytes).
-}
type alias DtMsRow =
    { name : String
    , age : Int
    , address : String
    , chinese : Int
    , math : Int
    , english : Int
    }


dtMsRows : List DtMsRow
dtMsRows =
    [ { name = "John Brown", age = 32, address = "New York No. 1 Lake Park", chinese = 98, math = 60, english = 70 }
    , { name = "Jim Green", age = 42, address = "London No. 1 Lake Park", chinese = 98, math = 66, english = 89 }
    , { name = "Joe Black", age = 32, address = "Sidney No. 1 Lake Park", chinese = 98, math = 66, english = 89 }
    , { name = "Jim Red", age = 32, address = "London No. 2 Lake Park", chinese = 88, math = 99, english = 89 }
    ]


msScoreCol : String -> String -> Int -> (DtMsRow -> Int) -> DataTable.Column DtMsRow Msg
msScoreCol key title priority accessor =
    { key = key
    , title = title
    , view = accessor >> String.fromInt >> Element.text
    , align = Nothing
    , titleAlign = Nothing
    , width = Nothing
    , minWidth = Nothing
    , maxWidth = Nothing
    , className = Nothing
    , sorter = Just (DataTable.SorterMultiple priority (Just (DataTable.CompareBy (\a b -> compare (accessor a) (accessor b)))))
    , defaultSortOrder = DataTable.NoSort
    , sortOrder = Nothing
    , filter = Nothing
    , filterOptions = Nothing
    , filterOptionValues = Nothing
    , filterOptionValue = Nothing
    , filterMode = DataTable.FilterOr
    , defaultFilterOptionValues = Nothing
    , defaultFilterOptionValue = Nothing
    , filterMultiple = True
    , kind = DataTable.KindNormal
    , multiple = True
    , disabled = Nothing
    , options = []
    , renderExpand = Nothing
    , expandable = Nothing
    , fixed = Nothing
    , ellipsis = Nothing
    , children = Nothing
    , titleColSpan = Nothing
    , colSpan = Nothing
    , rowSpan = Nothing
    }


dtMsNameCol : DataTable.Column DtMsRow Msg
dtMsNameCol =
    { key = "name"
    , title = "Name"
    , view = .name >> Element.text
    , align = Nothing
    , titleAlign = Nothing
    , width = Nothing
    , minWidth = Nothing
    , maxWidth = Nothing
    , className = Nothing
    , sorter = Nothing
    , defaultSortOrder = DataTable.NoSort
    , sortOrder = Nothing
    , filter = Nothing
    , filterOptions = Nothing
    , filterOptionValues = Nothing
    , filterOptionValue = Nothing
    , filterMode = DataTable.FilterOr
    , defaultFilterOptionValues = Nothing
    , defaultFilterOptionValue = Nothing
    , filterMultiple = True
    , kind = DataTable.KindNormal
    , multiple = True
    , disabled = Nothing
    , options = []
    , renderExpand = Nothing
    , expandable = Nothing
    , fixed = Nothing
    , ellipsis = Nothing
    , children = Nothing
    , titleColSpan = Nothing
    , colSpan = Nothing
    , rowSpan = Nothing
    }


dtMsAgeCol : DataTable.Column DtMsRow Msg
dtMsAgeCol =
    { key = "age"
    , title = "Age"
    , view = .age >> String.fromInt >> Element.text
    , align = Nothing
    , titleAlign = Nothing
    , width = Nothing
    , minWidth = Nothing
    , maxWidth = Nothing
    , className = Nothing
    , sorter = Just (DataTable.SorterBy (\a b -> compare a.age b.age))
    , defaultSortOrder = DataTable.NoSort
    , sortOrder = Nothing
    , filter = Nothing
    , filterOptions = Nothing
    , filterOptionValues = Nothing
    , filterOptionValue = Nothing
    , filterMode = DataTable.FilterOr
    , defaultFilterOptionValues = Nothing
    , defaultFilterOptionValue = Nothing
    , filterMultiple = True
    , kind = DataTable.KindNormal
    , multiple = True
    , disabled = Nothing
    , options = []
    , renderExpand = Nothing
    , expandable = Nothing
    , fixed = Nothing
    , ellipsis = Nothing
    , children = Nothing
    , titleColSpan = Nothing
    , colSpan = Nothing
    , rowSpan = Nothing
    }


dtMsAddressCol : DataTable.Column DtMsRow Msg
dtMsAddressCol =
    { key = "address"
    , title = "Address"
    , view = .address >> Element.text
    , align = Nothing
    , titleAlign = Nothing
    , width = Nothing
    , minWidth = Nothing
    , maxWidth = Nothing
    , className = Nothing
    , sorter = Nothing
    , defaultSortOrder = DataTable.NoSort
    , sortOrder = Nothing
    , filter = Nothing
    , filterOptions = Nothing
    , filterOptionValues = Nothing
    , filterOptionValue = Nothing
    , filterMode = DataTable.FilterOr
    , defaultFilterOptionValues = Nothing
    , defaultFilterOptionValue = Nothing
    , filterMultiple = True
    , kind = DataTable.KindNormal
    , multiple = True
    , disabled = Nothing
    , options = []
    , renderExpand = Nothing
    , expandable = Nothing
    , fixed = Nothing
    , ellipsis = Nothing
    , children = Nothing
    , titleColSpan = Nothing
    , colSpan = Nothing
    , rowSpan = Nothing
    }


{-| The spec's column order: name, age, chinese (multiple 3), math (multiple
2), english (multiple 1), address.
-}
dtMsColumns : List (DataTable.Column DtMsRow Msg)
dtMsColumns =
    [ dtMsNameCol
    , dtMsAgeCol
    , msScoreCol "chinese" "Chinese Score" 3 .chinese
    , msScoreCol "math" "Math Score" 2 .math
    , msScoreCol "english" "English Score" 1 .english
    , dtMsAddressCol
    ]


dtMsOpts : List (DataTable.SortState DtMsRow) -> DataTable.Options DtMsRow Msg
dtMsOpts states =
    let
        d =
            DataTable.defaults
    in
    { d
        | columns = dtMsColumns
        , data = dtMsRows
        , rowKey = .name
        , sortStates = states
    }


dtPgD : Pagination.Options Msg
dtPgD =
    Pagination.defaults


{-| `dtMsOpts` plus the pagination-flavoured overrides (the eq-pin call
sites carry all three fields explicitly — Elm records have no partial
merge, and updating a call result needs a bound base anyway).
-}
dtMsOptsU :
    List (DataTable.SortState DtMsRow)
    ->
        { remote : Bool
        , paginateSinglePage : Bool
        , pagination : Maybe (Pagination.Options Msg)
        }
    -> DataTable.Options DtMsRow Msg
dtMsOptsU states { remote, paginateSinglePage, pagination } =
    let
        base =
            dtMsOpts states
    in
    { base
        | remote = remote
        , paginateSinglePage = paginateSinglePage
        , pagination = pagination
    }


{-| The b5 filter options — the spec `:430-441` address fixture (London /
New York / Sidney, label ≙ value).
-}
dtFilterOptions : List DataTable.FilterOption
dtFilterOptions =
    [ { label = "London", value = "London" }
    , { label = "New York", value = "New York" }
    , { label = "Sidney", value = "Sidney" }
    ]


{-| The b5 filterable address column — upstream `filter: (value, row) =>
row.address.includes(value)` over the spec's option list (spec :446).
-}
dtFilterCol : DataTable.Column DtRow Msg
dtFilterCol =
    { dtAddressCol
        | filter =
            Just
                (DataTable.FilterCustom (\value row -> String.contains value row.address))
        , filterOptions = Just dtFilterOptions
    }


{-| The b5 sortable + filterable address column — the th carries BOTH
`--sorting`-family and `--filterable` mods (the class-order pin).
-}
dtFilterSortCol : DataTable.Column DtRow Msg
dtFilterSortCol =
    { dtFilterCol
        | sorter = Just (DataTable.SorterBy (\a b -> compare a.address b.address))
    }


{-| The b5 menu fixtures — multiple (Sidney checked), single (London
checked), the array-single compat mode (the head of the temporal array
reads checked) and the rtl root.
-}
dtFmMulti : DataTable.FilterMenuOptions Msg
dtFmMulti =
    let
        d =
            DataTable.filterMenuDefaults
    in
    { d | options = dtFilterOptions, value = DataTable.FilterMany [ "Sidney" ] }


dtFmSingle : DataTable.FilterMenuOptions Msg
dtFmSingle =
    let
        d =
            DataTable.filterMenuDefaults
    in
    { d | multiple = False, options = dtFilterOptions, value = DataTable.FilterOne "London" }


dtFmCompat : DataTable.FilterMenuOptions Msg
dtFmCompat =
    let
        d =
            DataTable.filterMenuDefaults
    in
    { d | multiple = False, arraySingleMode = True, options = dtFilterOptions, value = DataTable.FilterMany [ "New York", "Sidney" ] }


dtFmRtl : DataTable.FilterMenuOptions Msg
dtFmRtl =
    let
        d =
            DataTable.filterMenuDefaults
    in
    { d | options = dtFilterOptions, value = DataTable.FilterMany [], rtl = True }


{-| The b3 selection column over `DtRow` — upstream `{ type: 'selection' }`
(spec `:961` fixture shape). The `key` is dead weight on the special kinds
(`getColKey` emits the `__n_selection__` sentinel).
-}
dtSelCol : DataTable.Column DtRow Msg
dtSelCol =
    let
        d =
            DataTable.columnDefaults
    in
    { d | kind = DataTable.KindSelection }


{-| The b3 expand column over `DtRow` — upstream `{ type: 'expand' }`.
-}
dtExpCol : DataTable.Column DtRow Msg
dtExpCol =
    let
        d =
            DataTable.columnDefaults
    in
    { d | kind = DataTable.KindExpand }


{-| The b4 ellipsis columns — upstream `ellipsis: true` (the plain th/td
wrappers) and the `EllipsisProps` object form (the `NEllipsis` embed;
the spec's `ellipsis: { tooltip: true }` shape).
-}
dtEllPlainCol : DataTable.Column DtRow Msg
dtEllPlainCol =
    { dtNameCol | width = Just 100, ellipsis = Just DataTable.EllipsisPlain }


dtEllOptsCol : DataTable.Column DtRow Msg
dtEllOptsCol =
    { dtAgeCol
        | width = Just 100
        , ellipsis = Just (DataTable.EllipsisOpts Ellipsis.defaults)
    }


dtEllNameCol : DataTable.Column DtRow Msg
dtEllNameCol =
    { dtNameCol
        | width = Just 100
        , ellipsis = Just (DataTable.EllipsisOpts Ellipsis.defaults)
    }


{-| The b3 selection column over the 4-row multiple-sorter fixture — the
shift-range pins ride it (the `disabled` variant updates the field).
-}
dtMsSelCol : DataTable.Column DtMsRow Msg
dtMsSelCol =
    let
        d =
            DataTable.columnDefaults
    in
    { d | kind = DataTable.KindSelection }


{-| The b6 group-header row — the spec `:1360` fixture shape (`name`, `age`,
`test1`, `test2`), one field per LEAF column key.
-}
type alias DtGroupRow =
    { name : String
    , age : Int
    , test1 : Int
    , test2 : Int
    }


dtGroupRows : List DtGroupRow
dtGroupRows =
    List.map (\i -> { name = String.fromInt i, age = i, test1 = i, test2 = i }) (List.range 0 4)


{-| A plain leaf column over `DtGroupRow` (key + title + a text render) —
the base every b6 group fixture record-updates.
-}
dtGroupLeaf : String -> String -> (DtGroupRow -> String) -> DataTable.Column DtGroupRow Msg
dtGroupLeaf key title accessor =
    let
        d =
            DataTable.columnDefaults
    in
    { d | key = key, title = title, view = accessor >> Element.text }


{-| The b6 group fixture A (spec `:1360`) — `name` (w100) beside `age`
(w100) whose `children` are the `test1` / `test2` leaves. The group column
carries `children = Just [ ColumnChild … ]` (the key-presence gate).
-}
dtGroupCols : List (DataTable.Column DtGroupRow Msg)
dtGroupCols =
    let
        nameCol =
            dtGroupLeaf "name" "Name" .name

        ageCol =
            dtGroupLeaf "age" "Age" (String.fromInt << .age)
    in
    [ { nameCol | width = Just 100 }
    , { ageCol
        | width = Just 100
        , children = Just [ DataTable.ColumnChild (dtGroupLeaf "test1" "test1" (String.fromInt << .test1)), DataTable.ColumnChild (dtGroupLeaf "test2" "test2" (String.fromInt << .test2)) ]
      }
    ]


{-| The b6 group fixture D — a `fixed` leaf nested under a group (`a`
fixed-left w100, `b` w100) beside a flat `c` (fixed-left w50). The
fixed-offset walk runs over the LEAVES only (b4 formula): `a` start 0,
`c` start 100 (the group `g` never joins the map).
-}
dtGroupFixedCols : List (DataTable.Column DtGroupRow Msg)
dtGroupFixedCols =
    let
        gCol =
            dtGroupLeaf "g" "G" .name

        aCol =
            dtGroupLeaf "a" "A" .name

        bCol =
            dtGroupLeaf "b" "B" (String.fromInt << .age)

        cCol =
            dtGroupLeaf "c" "C" (String.fromInt << .test1)
    in
    [ { gCol
        | children =
            Just
                [ DataTable.ColumnChild { aCol | width = Just 100, fixed = Just DataTable.FixedLeft }
                , DataTable.ColumnChild { bCol | width = Just 100 }
                ]
      }
    , { cCol | width = Just 50, fixed = Just DataTable.FixedLeft }
    ]


{-| The b6 `titleColSpan` fixture B — `a` spans 2 header cells (swallowing
`b`), `c` is the last leaf. Leaf keys `a`/`b`/`c` over `DtGroupRow`.
-}
dtTitleSpanCols : List (DataTable.Column DtGroupRow Msg)
dtTitleSpanCols =
    let
        aCol =
            dtGroupLeaf "a" "A" .name
    in
    [ { aCol | titleColSpan = Just 2 }
    , dtGroupLeaf "b" "B" (String.fromInt << .age)
    , dtGroupLeaf "c" "C" (String.fromInt << .test1)
    ]


{-| The b6 `children = Just []` edge C — a group column with an EMPTY
child list: `colSpan 0`, `isLast True`, and `leafColumns` yields nothing.
-}
dtEmptyGroupCols : List (DataTable.Column DtGroupRow Msg)
dtEmptyGroupCols =
    let
        xCol =
            dtGroupLeaf "x" "X" .name
    in
    [ { xCol | children = Just [] } ]


{-| The b6 summary / merge row — the spec `:847` (`name`/`age`) and `:1113`
fixture shape. `name` is stringified (the port's `rowKey` is `String`-keyed).
-}
type alias DtSumRow =
    { name : String
    , age : Int
    }


{-| The summary fixture rows — `Array.from({length: 10})` with `{name:
index, age: index}` (spec :847); ages sum to 45.
-}
dtSumRows : List DtSumRow
dtSumRows =
    List.map (\i -> { name = String.fromInt i, age = i }) (List.range 0 9)


{-| The summary / merge columns — plain `name` (text) + `age` (int) leaves.
-}
dtSumCols : List (DataTable.Column DtSumRow Msg)
dtSumCols =
    let
        d =
            DataTable.columnDefaults
    in
    [ { d | key = "name", title = "Name", view = .name >> Element.text }
    , { d | key = "age", title = "Age", view = .age >> String.fromInt >> Element.text }
    ]


{-| The b6 `summary` fn (spec :847) — one row keyed by column key: `name`
carries `{value 45, colSpan 1, rowSpan 2}`, `age` `{value 45, colSpan 2,
rowSpan 1}` (the value is the summed ages over the page data).
-}
dtSummaryFn : List DtSumRow -> List (List ( String, DataTable.SummaryCell Msg ))
dtSummaryFn pageData =
    let
        total =
            String.fromInt (List.sum (List.map .age pageData))
    in
    [ [ ( "name", { value = Just (Element.text total), colSpan = Just 1, rowSpan = Just 2 } )
      , ( "age", { value = Just (Element.text total), colSpan = Just 2, rowSpan = Just 1 } )
      ]
    ]


dtSummaryOpts : DataTable.Options DtSumRow Msg
dtSummaryOpts =
    let
        d =
            DataTable.defaults
    in
    { d | columns = dtSumCols, data = dtSumRows, rowKey = .name, summary = Just dtSummaryFn }


{-| The same summary with `summaryPlacement = SummaryTop` (P2) and a
`striped` variant (the summary tr must NOT take `--striped`).
-}
dtSummaryTopOpts : DataTable.Options DtSumRow Msg
dtSummaryTopOpts =
    let
        base =
            dtSummaryOpts
    in
    { base | summaryPlacement = DataTable.SummaryTop }


dtSummaryStripedOpts : DataTable.Options DtSumRow Msg
dtSummaryStripedOpts =
    let
        base =
            dtSummaryOpts
    in
    { base | striped = True }


{-| The b6 merge fixture (spec :1113) — 5 rows `{name: index, age: index+1}`,
`rowKey = .name`.
-}
dtMergeRows : List DtSumRow
dtMergeRows =
    List.map (\i -> { name = String.fromInt i, age = i + 1 }) (List.range 0 4)


{-| The b6 merge columns (spec :1113) — `name` carries the merge fns
(`rowSpan = rowIndex==0 ? 2 : 1`, `colSpan = rowIndex==0 ? 3 : 1`), `age`
plain. The fns take `(row, actualRowIndex)`.
-}
dtMergeCols : List (DataTable.Column DtSumRow Msg)
dtMergeCols =
    let
        d =
            DataTable.columnDefaults

        nameCol =
            { d | key = "name", title = "Name", view = .name >> Element.text }

        ageCol =
            { d | key = "age", title = "Age", view = .age >> String.fromInt >> Element.text }
    in
    [ { nameCol
        | rowSpan =
            Just
                (\_ i ->
                    if i == 0 then
                        2

                    else
                        1
                )
        , colSpan =
            Just
                (\_ i ->
                    if i == 0 then
                        3

                    else
                        1
                )
      }
    , ageCol
    ]


dtMergeOpts : DataTable.Options DtSumRow Msg
dtMergeOpts =
    let
        d =
            DataTable.defaults
    in
    { d | columns = dtMergeCols, data = dtMergeRows, rowKey = .name }


{-| The b6 merge + expand fixture (P5) — an expand column beside `name`
(`colSpan = rowIndex==0 ? 2 : 1`); the expanded-row td colspan runs to the
LEAF count (2).
-}
dtMergeExpandCols : List (DataTable.Column DtSumRow Msg)
dtMergeExpandCols =
    let
        d =
            DataTable.columnDefaults

        nameCol =
            { d | key = "name", title = "Name", view = .name >> Element.text }
    in
    [ { d | kind = DataTable.KindExpand, renderExpand = Just (\row _ -> Element.text (row.name ++ " is a good guy.")) }
    , { nameCol
        | colSpan =
            Just
                (\_ i ->
                    if i == 0 then
                        2

                    else
                        1
                )
      }
    ]


dtMergeExpandOpts : DataTable.Options DtSumRow Msg
dtMergeExpandOpts =
    let
        d =
            DataTable.defaults
    in
    { d | columns = dtMergeExpandCols, data = dtMergeRows, rowKey = .name, expandedRowKeys = [ "0" ] }


{-| A spec-shaped row — `Array.from({length: n}).map((_, index) => ({ name:
index }))` with the name stringified (the port's `rowKey` is `String`-keyed;
the observable bytes — keys, renders, check states — are identical).
-}
dtSpecRow : Int -> DtRow
dtSpecRow i =
    { name = String.fromInt i, age = i, address = "" }


{-| The header checkbox's (indeterminate, checked) pair over one options
object — the two counts share a fixture.
-}
dtHeaderState : DataTable.Options row msg -> ( Bool, Bool )
dtHeaderState opts =
    ( DataTable.someRowsChecked opts, DataTable.allRowsChecked opts )


{-| The shift-range pin base — selection + name over the 4-row multiple
sorter fixture, no pagination (the current page is the whole data).
-}
dtMsSelOpts : DataTable.Options DtMsRow Msg
dtMsSelOpts =
    let
        base =
            dtMsOpts []
    in
    { base | columns = [ dtMsSelCol, dtMsNameCol ] }


dtMsNames : List (DataTable.SortState DtMsRow) -> List String
dtMsNames states =
    List.map .name (DataTable.sortedData (dtMsOpts states))


dtMsVals : (DtMsRow -> Int) -> List (DataTable.SortState DtMsRow) -> List Int
dtMsVals accessor states =
    List.map accessor (DataTable.sortedData (dtMsOpts states))


{-| The spec's click walk (DataTable.spec.tsx:522-646): one click per spec
step — `createNextSorter` of the column against its CURRENT merged state,
then `deriveNextSorter` over that merged base (use-sorter.ts:180) — folded
over the caller-owned uncontrolled list, seeded from `defaultSortStates`
(the mount state: every sortable column, order `defaultSortOrder`).
-}
dtMsWalk : List (List (DataTable.SortState DtMsRow) -> Maybe (DataTable.SortState DtMsRow)) -> List (List (DataTable.SortState DtMsRow))
dtMsWalk clickFns =
    List.foldl
        (\clickFn acc ->
            let
                previousStates =
                    case acc of
                        previous :: _ ->
                            previous

                        [] ->
                            DataTable.defaultSortStates dtMsColumns

                merged =
                    DataTable.mergedSortStates dtMsColumns previousStates
            in
            DataTable.deriveNextSorter merged (clickFn previousStates) :: acc
        )
        []
        clickFns
        |> List.reverse


{-| `dtMsClick "chinese"` is the spec's click on `#chinese-title` —
`createNextSorter` of the column and its current state in the MERGED
list (upstream `handleColHeaderClick`'s `find ... || null`).
-}
dtMsClick : String -> List (DataTable.SortState DtMsRow) -> Maybe (DataTable.SortState DtMsRow)
dtMsClick key states =
    let
        current =
            DataTable.mergedSortStates dtMsColumns states
                |> List.filter (\state -> state.columnKey == key)
                |> List.head
    in
    dtMsColumns
        |> List.filter (\col -> col.key == key)
        |> List.head
        |> Maybe.andThen (\col -> DataTable.createNextSorter col current)


msWalkStates : List (List (DataTable.SortState DtMsRow))
msWalkStates =
    dtMsWalk
        [ dtMsClick "chinese"
        , dtMsClick "math"
        , dtMsClick "english"
        , dtMsClick "chinese"
        , dtMsClick "chinese"
        , dtMsClick "math"
        , dtMsClick "math"
        , dtMsClick "chinese"
        , dtMsClick "age"
        ]


{-| The 9-state walk (the 8 spec steps + the final `age` click). Each step's
per-column value arrays come from the spec's `checkScoreIsMatched` bytes;
the name arrays are the row order those bytes pin.
-}
msWalkExpect :
    List
        { names : List String
        , chinese : List Int
        , math : List Int
        , english : List Int
        }
msWalkExpect =
    [ { names = [ "John Brown", "Jim Green", "Joe Black", "Jim Red" ]
      , chinese = [ 98, 98, 98, 88 ]
      , math = [ 60, 66, 66, 99 ]
      , english = [ 70, 89, 89, 89 ]
      }
    , { names = [ "Jim Green", "Joe Black", "John Brown", "Jim Red" ]
      , chinese = [ 98, 98, 98, 88 ]
      , math = [ 66, 66, 60, 99 ]
      , english = [ 89, 89, 70, 89 ]
      }
    , { names = [ "Jim Green", "Joe Black", "John Brown", "Jim Red" ]
      , chinese = [ 98, 98, 98, 88 ]
      , math = [ 66, 66, 60, 99 ]
      , english = [ 89, 89, 70, 89 ]
      }
    , { names = [ "Jim Red", "Jim Green", "Joe Black", "John Brown" ]
      , chinese = [ 88, 98, 98, 98 ]
      , math = [ 99, 66, 66, 60 ]
      , english = [ 89, 89, 89, 70 ]
      }
    , { names = [ "Jim Red", "Jim Green", "Joe Black", "John Brown" ]
      , chinese = [ 88, 98, 98, 98 ]
      , math = [ 99, 66, 66, 60 ]
      , english = [ 89, 89, 89, 70 ]
      }
    , { names = [ "John Brown", "Jim Green", "Joe Black", "Jim Red" ]
      , chinese = [ 98, 98, 98, 88 ]
      , math = [ 60, 66, 66, 99 ]
      , english = [ 70, 89, 89, 89 ]
      }
    , { names = [ "Jim Green", "Joe Black", "Jim Red", "John Brown" ]
      , chinese = [ 98, 98, 88, 98 ]
      , math = [ 66, 66, 99, 60 ]
      , english = [ 89, 89, 89, 70 ]
      }
    , { names = [ "Jim Green", "Joe Black", "John Brown", "Jim Red" ]
      , chinese = [ 98, 98, 98, 88 ]
      , math = [ 66, 66, 60, 99 ]
      , english = [ 89, 89, 70, 89 ]
      }
    , { names = [ "Jim Green", "John Brown", "Joe Black", "Jim Red" ]
      , chinese = [ 98, 98, 98, 88 ]
      , math = [ 66, 60, 66, 99 ]
      , english = [ 89, 70, 89, 89 ]
      }
    ]


msWalkTitles : List String
msWalkTitles =
    [ "multiple sorter walk 1 — chinese descend (spec `chinese: descend, math: false, english: false`)"
    , "multiple sorter walk 2 — math descend (spec `chinese: descend, math: descend, english: false`)"
    , "multiple sorter walk 3 — english descend (spec `chinese: descend, math: descend, english: descend`)"
    , "multiple sorter walk 4 — chinese ascend (spec `chinese: ascend, math: descend, english: descend`)"
    , "multiple sorter walk 5 — chinese false (spec `chinese: false, math: descend, english: descend`)"
    , "multiple sorter walk 6 — math ascend (spec `chinese: false, math: ascend, english: descend`)"
    , "multiple sorter walk 7 — math false (spec `chinese: false, math: false, english: descend`)"
    , "multiple sorter walk 8 — chinese descend (spec `chinese: descend, math: false, english: descend`)"
    , "multiple sorter walk 9 — age descend (spec `age: descend`, single-sorter click replaces the multi state)"
    ]


msWalkChecks : List Check
msWalkChecks =
    List.map3
        (\title states expect ->
            eq
                (title
                    ++ " — row order (name array) and the spec's per-column score arrays"
                )
                { names = expect.names
                , chinese = expect.chinese
                , math = expect.math
                , english = expect.english
                }
                { names = dtMsNames states
                , chinese = dtMsVals .chinese states
                , math = dtMsVals .math states
                , english = dtMsVals .english states
                }
        )
        msWalkTitles
        msWalkStates
        msWalkExpect


{-| The 47-entry list `NUI.DataTable.cssVars` must emit for `Medium` (light) —
the upstream `DataTable.spec.tsx.snap` `size` snapshot #2 byte string.
-}
expectedDataTableVarsMedium : List ( String, String )
expectedDataTableVarsMedium =
    [ ( "--n-font-size", "14px" )
    , ( "--n-th-padding", "12px" )
    , ( "--n-td-padding", "12px" )
    , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
    , ( "--n-border-radius", "3px" )
    , ( "--n-line-height", "1.6" )
    , ( "--n-border-color", "rgba(239, 239, 245, 1)" )
    , ( "--n-border-color-modal", "rgba(239, 239, 245, 1)" )
    , ( "--n-border-color-popover", "rgba(239, 239, 245, 1)" )
    , ( "--n-th-color", "rgba(250, 250, 252, 1)" )
    , ( "--n-th-color-hover", "rgba(243, 243, 247, 1)" )
    , ( "--n-th-color-modal", "rgba(250, 250, 252, 1)" )
    , ( "--n-th-color-hover-modal", "rgba(243, 243, 247, 1)" )
    , ( "--n-th-color-popover", "rgba(250, 250, 252, 1)" )
    , ( "--n-th-color-hover-popover", "rgba(243, 243, 247, 1)" )
    , ( "--n-td-color", "#fff" )
    , ( "--n-td-color-hover", "rgba(247, 247, 250, 1)" )
    , ( "--n-td-color-modal", "#fff" )
    , ( "--n-td-color-hover-modal", "rgba(247, 247, 250, 1)" )
    , ( "--n-td-color-popover", "#fff" )
    , ( "--n-td-color-hover-popover", "rgba(247, 247, 250, 1)" )
    , ( "--n-th-text-color", "rgb(31, 34, 37)" )
    , ( "--n-td-text-color", "rgb(51, 54, 57)" )
    , ( "--n-th-font-weight", "500" )
    , ( "--n-th-button-color-hover", "rgba(0, 0, 100, 0.03)" )
    , ( "--n-th-icon-color", "rgba(194, 194, 194, 1)" )
    , ( "--n-th-icon-color-active", "#18a058" )
    , ( "--n-filter-size", "15px" )
    , ( "--n-pagination-margin", "12px 0 0 0" )
    , ( "--n-empty-padding", "48px 0" )
    , ( "--n-box-shadow-before", "inset -12px 0 8px -12px rgba(0, 0, 0, .18)" )
    , ( "--n-box-shadow-after", "inset 12px 0 8px -12px rgba(0, 0, 0, .18)" )
    , ( "--n-sorter-size", "15px" )
    , ( "--n-resizable-container-size", "8px" )
    , ( "--n-resizable-size", "2px" )
    , ( "--n-loading-size", "28px" )
    , ( "--n-loading-color", "#18a058" )
    , ( "--n-opacity-loading", "0.5" )
    , ( "--n-td-color-striped", "rgba(250, 250, 252, 1)" )
    , ( "--n-td-color-striped-modal", "rgba(250, 250, 252, 1)" )
    , ( "--n-td-color-striped-popover", "rgba(250, 250, 252, 1)" )
    , ( "--n-td-color-sorting", "rgba(247, 247, 250, 1)" )
    , ( "--n-td-color-sorting-modal", "rgba(247, 247, 250, 1)" )
    , ( "--n-td-color-sorting-popover", "rgba(247, 247, 250, 1)" )
    , ( "--n-th-color-sorting", "rgba(243, 243, 247, 1)" )
    , ( "--n-th-color-sorting-modal", "rgba(243, 243, 247, 1)" )
    , ( "--n-th-color-sorting-popover", "rgba(243, 243, 247, 1)" )
    ]


dtMediumVars : List ( String, String )
dtMediumVars =
    DataTable.cssVars Theme.default DataTable.Medium


dtSmallVars : List ( String, String )
dtSmallVars =
    DataTable.cssVars Theme.default DataTable.Small


dtLargeVars : List ( String, String )
dtLargeVars =
    DataTable.cssVars Theme.default DataTable.Large


dtDarkVars : List ( String, String )
dtDarkVars =
    DataTable.cssVars Theme.dark DataTable.Medium


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

    -- dropdown: defaults ---------------------------------------------------
    , eq "dropdown defaults: placementName Bottom" "bottom" (Dropdown.placementName Dropdown.defaults.placement)
    , eq "dropdown defaults: placement is Popover.Bottom" Popover.Bottom Dropdown.defaults.placement
    , eq "dropdown defaults: size Medium" Dropdown.Medium Dropdown.defaults.size
    , eq "dropdown defaults: showArrow False" False Dropdown.defaults.showArrow
    , eq "dropdown defaults: inverted False" False Dropdown.defaults.inverted
    , eq "dropdown defaults: scrollable False" False Dropdown.defaults.scrollable
    , eq "dropdown defaults: overlap False" False Dropdown.defaults.overlap
    , eq "dropdown defaults: arrowPointToCenter False" False Dropdown.defaults.arrowPointToCenter
    , eq "dropdown defaults: rtl False" False Dropdown.defaults.rtl
    , eq "dropdown defaults: width Nothing" Nothing Dropdown.defaults.width
    , eq "dropdown defaults: value Nothing" Nothing Dropdown.defaults.value
    , eq "dropdown defaults: onSelect Nothing" Nothing Dropdown.defaults.onSelect
    , eq "dropdown defaults: transition Nothing" Nothing Dropdown.defaults.transition
    , eq "dropdown defaults: arrowStyle Nothing" Nothing Dropdown.defaults.arrowStyle
    , eq "dropdown defaults: attributes []" True (List.isEmpty Dropdown.defaults.attributes)

    -- dropdown: placementName through the alias ----------------------------
    , eq "dropdown placementName: BottomStart" "bottom-start" (Dropdown.placementName Popover.BottomStart)
    , eq "dropdown placementName: RightStart" "right-start" (Dropdown.placementName Popover.RightStart)

    -- dropdown: cssVars light/medium (31-var snapshot) ----------------------
    , eq "dropdown vars: 31 keys (light/medium)" 31 (List.length dMediumVars)
    , eq "dropdown vars: full 31-list light/medium (name+value, order)" expectedDropdownVars dMediumVars
    , eq "dropdown vars: slot 13 key is --n-padding" (Just "--n-padding") (listAt 12 dMediumVars |> Maybe.map Tuple.first)
    , eq "dropdown vars: slot 13 value is 4px 0" (Just "4px 0") (listAt 12 dMediumVars |> Maybe.map Tuple.second)
    , eq "dropdown vars: --n-color #fff" (Just "#fff") (lookup "--n-color" dMediumVars)
    , eq "dropdown vars: --n-option-color-active rgba(24, 160, 88, 0.1)" (Just "rgba(24, 160, 88, 0.1)") (lookup "--n-option-color-active" dMediumVars)
    , eq "dropdown vars: --n-option-height 34px" (Just "34px") (lookup "--n-option-height" dMediumVars)

    -- dropdown: cssVars light/small (size-keyed) --------------------------
    , eq "dropdown vars: 31 keys (light/small)" 31 (List.length dSmallVars)
    , eq "dropdown vars: small --n-font-size 14px (common fontSizeSmall)" (Just "14px") (lookup "--n-font-size" dSmallVars)
    , eq "dropdown vars: small --n-option-height 28px" (Just "28px") (lookup "--n-option-height" dSmallVars)
    , eq "dropdown vars: small --n-option-icon-size 14px" (Just "14px") (lookup "--n-option-icon-size" dSmallVars)
    , eq "dropdown vars: small prefix/icon-prefix widths 14/36" ( Just "14px", Just "36px" ) ( lookup "--n-option-prefix-width" dSmallVars, lookup "--n-option-icon-prefix-width" dSmallVars )
    , eq "dropdown vars: small suffix/icon-suffix widths 14/32" ( Just "14px", Just "32px" ) ( lookup "--n-option-suffix-width" dSmallVars, lookup "--n-option-icon-suffix-width" dSmallVars )
    , eq "dropdown vars: small differs from medium only in height + icon-size" [ "--n-option-height", "--n-option-icon-size" ] (changedVarKeys dMediumVars dSmallVars)

    -- dropdown: cssVars light/medium inverted -----------------------------
    , eq "dropdown vars: 31 keys (light/medium inverted)" 31 (List.length dInvertedVars)
    , eq "dropdown inverted: exactly 10 keys differ" [ "--n-color", "--n-option-color-hover", "--n-option-color-active", "--n-option-text-color", "--n-option-text-color-hover", "--n-option-text-color-active", "--n-option-text-color-child-active", "--n-prefix-color", "--n-suffix-color", "--n-group-header-text-color" ] (changedVarKeys dMediumVars dInvertedVars)
    , eq "dropdown inverted: --n-color rgb(0, 20, 40)" (Just "rgb(0, 20, 40)") (lookup "--n-color" dInvertedVars)
    , eq "dropdown inverted: --n-option-color-hover #18a058" (Just "#18a058") (lookup "--n-option-color-hover" dInvertedVars)
    , eq "dropdown inverted: --n-option-color-active #18a058" (Just "#18a058") (lookup "--n-option-color-active" dInvertedVars)
    , eq "dropdown inverted: --n-option-text-color #BBB" (Just "#BBB") (lookup "--n-option-text-color" dInvertedVars)
    , eq "dropdown inverted: --n-option-text-color-hover #FFF" (Just "#FFF") (lookup "--n-option-text-color-hover" dInvertedVars)
    , eq "dropdown inverted: --n-option-text-color-active #FFF" (Just "#FFF") (lookup "--n-option-text-color-active" dInvertedVars)
    , eq "dropdown inverted: --n-option-text-color-child-active #FFF" (Just "#FFF") (lookup "--n-option-text-color-child-active" dInvertedVars)
    , eq "dropdown inverted: --n-prefix-color #BBB" (Just "#BBB") (lookup "--n-prefix-color" dInvertedVars)
    , eq "dropdown inverted: --n-suffix-color #BBB" (Just "#BBB") (lookup "--n-suffix-color" dInvertedVars)
    , eq "dropdown inverted: --n-group-header-text-color #AAA" (Just "#AAA") (lookup "--n-group-header-text-color" dInvertedVars)
    , eq "dropdown inverted: --n-text-color stays rgb(51, 54, 57)" (Just "rgb(51, 54, 57)") (lookup "--n-text-color" dInvertedVars)
    , eq "dropdown inverted: --n-divider-color stays rgb(239, 239, 245)" (Just "rgb(239, 239, 245)") (lookup "--n-divider-color" dInvertedVars)
    , eq "dropdown inverted: --n-option-opacity-disabled stays 0.5" (Just "0.5") (lookup "--n-option-opacity-disabled" dInvertedVars)

    -- dropdown: cssVars dark (theme siblings, not light values) -----------
    , eq "dropdown vars: 31 keys (dark/medium)" 31 (List.length dDarkVars)
    , eq "dropdown dark: --n-color = popoverColor rgb(72, 72, 78)" (Just "rgb(72, 72, 78)") (lookup "--n-color" dDarkVars)
    , eq "dropdown dark: --n-option-color-active rgba(99, 226, 183, 0.15)" (Just "rgba(99, 226, 183, 0.15)") (lookup "--n-option-color-active" dDarkVars)
    , eq "dropdown dark: --n-option-color-hover = hoverColor rgba(255, 255, 255, 0.09)" (Just "rgba(255, 255, 255, 0.09)") (lookup "--n-option-color-hover" dDarkVars)
    , eq "dropdown dark: --n-option-text-color = textColor2 rgba(255, 255, 255, 0.82)" (Just "rgba(255, 255, 255, 0.82)") (lookup "--n-option-text-color" dDarkVars)
    , eq "dropdown dark: --n-option-text-color-active = primaryColor #63e2b7" (Just "#63e2b7") (lookup "--n-option-text-color-active" dDarkVars)
    , eq "dropdown dark: --n-divider-color rgba(255, 255, 255, 0.09)" (Just "rgba(255, 255, 255, 0.09)") (lookup "--n-divider-color" dDarkVars)
    , eq "dropdown dark: --n-option-opacity-disabled 0.38" (Just "0.38") (lookup "--n-option-opacity-disabled" dDarkVars)
    , eq "dropdown dark: --n-group-header-text-color = textColor3 rgba(255, 255, 255, 0.52)" (Just "rgba(255, 255, 255, 0.52)") (lookup "--n-group-header-text-color" dDarkVars)
    , eq "dropdown dark: --n-text-color = dark popover textColor2" (Just "rgba(255, 255, 255, 0.82)") (lookup "--n-text-color" dDarkVars)
    , eq "dropdown dark: --n-box-shadow = dark boxShadow2" (Just "0 3px 6px -4px rgba(0, 0, 0, .24), 0 6px 12px 0 rgba(0, 0, 0, .16), 0 9px 18px 8px rgba(0, 0, 0, .10)") (lookup "--n-box-shadow" dDarkVars)
    , eq "dropdown dark: --n-option-color-active swaps (light rgba(24, 160, 88, 0.1) -> dark)" ( Just "rgba(24, 160, 88, 0.1)", Just "rgba(99, 226, 183, 0.15)" ) ( lookup "--n-option-color-active" dMediumVars, lookup "--n-option-color-active" dDarkVars )

    -- dropdown: cssVars dark inverted -------------------------------------
    , eq "dropdown dark inverted: --n-option-color-hover = primaryColorSuppl rgb(42, 148, 125)" (Just "rgb(42, 148, 125)") (lookup "--n-option-color-hover" dDarkInvertedVars)
    , eq "dropdown dark inverted: --n-option-color-active = primaryColorSuppl rgb(42, 148, 125)" (Just "rgb(42, 148, 125)") (lookup "--n-option-color-active" dDarkInvertedVars)
    , eq "dropdown dark inverted: --n-color = popoverColor rgb(72, 72, 78)" (Just "rgb(72, 72, 78)") (lookup "--n-color" dDarkInvertedVars)

    -- modal: defaults --------------------------------------------------------
    , eq "modal defaults: show False" False mD.show
    , eq "modal defaults: showMask True" True mD.showMask
    , eq "modal defaults: zIndex Nothing" Nothing mD.zIndex
    , eq "modal defaults: maskTransition Nothing" Nothing mD.maskTransition
    , eq "modal defaults: bodyTransition Nothing" Nothing mD.bodyTransition
    , eq "modal defaults: attributes []" True (List.isEmpty mD.attributes)

    -- modal: cardDefaults (Card.defaults | bordered = False) -----------------
    , eq "modal cardDefaults: bordered False (Card.defaults is True)" ( True, False ) ( Card.defaults.bordered, mCardD.bordered )
    , eq "modal cardDefaults: closable = Card.defaults" Card.defaults.closable mCardD.closable
    , eq "modal cardDefaults: hoverable = Card.defaults" Card.defaults.hoverable mCardD.hoverable
    , eq "modal cardDefaults: embedded = Card.defaults" Card.defaults.embedded mCardD.embedded
    , eq "modal cardDefaults: size = Card.defaults" Card.defaults.size mCardD.size
    , eq "modal cardDefaults: segmented = Card.defaults" Card.defaults.segmented mCardD.segmented
    , eq "modal cardDefaults: contentStyle = Card.defaults" Card.defaults.contentStyle mCardD.contentStyle
    , eq "modal cardDefaults: role = Card.defaults" Card.defaults.role mCardD.role
    , eq "modal cardDefaults: rtl = Card.defaults" Card.defaults.rtl mCardD.rtl
    , eq "modal cardDefaults: extraClasses = Card.defaults" Card.defaults.extraClasses mCardD.extraClasses
    , eq "modal cardDefaults: attributes count = Card.defaults" (List.length Card.defaults.attributes) (List.length mCardD.attributes)
    , eq "modal cardDefaults: title Nothing (= Card.defaults)" ( True, True ) ( isNothing Card.defaults.title, isNothing mCardD.title )
    , eq "modal cardDefaults: headerExtra Nothing" True (isNothing mCardD.headerExtra)
    , eq "modal cardDefaults: cover Nothing" True (isNothing mCardD.cover)
    , eq "modal cardDefaults: footer Nothing" True (isNothing mCardD.footer)
    , eq "modal cardDefaults: action Nothing" True (isNothing mCardD.action)
    , eq "modal cardDefaults: onClose Nothing (= Card.defaults)" ( True, True ) ( isNothing Card.defaults.onClose, isNothing mCardD.onClose )

    -- modal: cssVars (exact 4-tuple order + values, light and dark) ----------
    , eq "modal vars: 4 keys (light)" 4 (List.length mLightVars)
    , eq "modal vars: exact 4-list light (name+value, order)" expectedModalLightVars mLightVars
    , eq "modal vars: --n-bezier-ease-out = cubicBezierEaseOut" (Just "cubic-bezier(0, 0, .2, 1)") (lookup "--n-bezier-ease-out" mLightVars)
    , eq "modal vars: --n-box-shadow = boxShadow3" (Just modalShadow) (lookup "--n-box-shadow" mLightVars)
    , eq "modal vars: --n-color = modalColor #fff" (Just "#fff") (lookup "--n-color" mLightVars)
    , eq "modal vars: --n-text-color = textColor2 rgb(51, 54, 57)" (Just "rgb(51, 54, 57)") (lookup "--n-text-color" mLightVars)
    , eq "modal vars: 4 keys (dark)" 4 (List.length mDarkVars)
    , eq "modal vars: exact 4-list dark (name+value, order)" expectedModalDarkVars mDarkVars
    , eq "modal dark: --n-color = rgb(44, 44, 50)" (Just "rgb(44, 44, 50)") (lookup "--n-color" mDarkVars)
    , eq "modal dark: --n-text-color = rgba(255, 255, 255, 0.82)" (Just "rgba(255, 255, 255, 0.82)") (lookup "--n-text-color" mDarkVars)
    , eq "modal dark: --n-box-shadow identical to light" (Just modalShadow) (lookup "--n-box-shadow" mDarkVars)
    , eq "modal dark: --n-bezier-ease-out identical to light" (Just "cubic-bezier(0, 0, .2, 1)") (lookup "--n-bezier-ease-out" mDarkVars)
    , eq "modal light/dark differ in exactly color + text-color" [ "--n-color", "--n-text-color" ] (changedVarKeys mLightVars mDarkVars)

    -- drawer: defaults -------------------------------------------------------
    , eq "drawer defaults: show False" False drD.show
    , eq "drawer defaults: placement Right" Drawer.Right drD.placement
    , eq "drawer defaults: showMask Visible" Drawer.Visible drD.showMask
    , eq "drawer defaults: nativeScrollbar True" True drD.nativeScrollbar
    , eq "drawer defaults: resizable False" False drD.resizable
    , eq "drawer defaults: showResizeTriggerHover False" False drD.showResizeTriggerHover
    , eq "drawer defaults: unselectable False" False drD.unselectable
    , eq "drawer defaults: rtl False" False drD.rtl
    , eq "drawer defaults: width Nothing" Nothing drD.width
    , eq "drawer defaults: height Nothing" Nothing drD.height
    , eq "drawer defaults: defaultWidth 251px" "251px" drD.defaultWidth
    , eq "drawer defaults: defaultHeight 251px" "251px" drD.defaultHeight
    , eq "drawer defaults: contentClass Nothing" Nothing drD.contentClass
    , eq "drawer defaults: contentStyle Nothing" Nothing drD.contentStyle
    , eq "drawer defaults: zIndex Nothing" Nothing drD.zIndex
    , eq "drawer defaults: maskTransition Nothing" Nothing drD.maskTransition
    , eq "drawer defaults: bodyTransition Nothing" Nothing drD.bodyTransition
    , eq "drawer defaults: onMaskClick Nothing" Nothing drD.onMaskClick
    , eq "drawer defaults: attributes []" True (List.isEmpty drD.attributes)

    -- drawer: placementName -------------------------------------------------
    , eq "drawer placementName: Left" "left" (Drawer.placementName Drawer.Left)
    , eq "drawer placementName: Right" "right" (Drawer.placementName Drawer.Right)
    , eq "drawer placementName: Top" "top" (Drawer.placementName Drawer.Top)
    , eq "drawer placementName: Bottom" "bottom" (Drawer.placementName Drawer.Bottom)

    -- drawer: DrawerContent.defaults ----------------------------------------
    , eq "drawer content defaults: closable False" False drContentD.closable
    , eq "drawer content defaults: nativeScrollbar True" True drContentD.nativeScrollbar
    , eq "drawer content defaults: title Nothing" True (isNothing drContentD.title)
    , eq "drawer content defaults: header Nothing" True (isNothing drContentD.header)
    , eq "drawer content defaults: footer Nothing" True (isNothing drContentD.footer)
    , eq "drawer content defaults: onClose Nothing" Nothing drContentD.onClose
    , eq "drawer content defaults: headerClass Nothing" Nothing drContentD.headerClass
    , eq "drawer content defaults: headerStyle Nothing" Nothing drContentD.headerStyle
    , eq "drawer content defaults: bodyClass Nothing" Nothing drContentD.bodyClass
    , eq "drawer content defaults: bodyStyle Nothing" Nothing drContentD.bodyStyle
    , eq "drawer content defaults: bodyContentClass Nothing" Nothing drContentD.bodyContentClass
    , eq "drawer content defaults: bodyContentStyle Nothing" Nothing drContentD.bodyContentStyle
    , eq "drawer content defaults: footerClass Nothing" Nothing drContentD.footerClass
    , eq "drawer content defaults: footerStyle Nothing" Nothing drContentD.footerStyle

    -- drawer: cssVars (exact 25-tuple order + values, light) ----------------
    , eq "drawer vars: 25 keys (light)" 25 (List.length drLightVars)
    , eq "drawer vars: exact 25-list light (name+value, order)" expectedDrawerLightVars drLightVars
    , eq "drawer vars: slot 1 --n-line-height" (Just "--n-line-height") (listAt 0 drLightVars |> Maybe.map Tuple.first)
    , eq "drawer vars: slot 8 --n-bezier-in (last bezier)" (Just "--n-bezier-in") (listAt 7 drLightVars |> Maybe.map Tuple.first)
    , eq "drawer vars: slot 25 is --n-resize-trigger-color-hover (cssr comment omits it)" (Just "--n-resize-trigger-color-hover") (listAt 24 drLightVars |> Maybe.map Tuple.first)
    , eq "drawer light: --n-color #fff" (Just "#fff") (lookup "--n-color" drLightVars)
    , eq "drawer light: --n-line-height 1.6" (Just "1.6") (lookup "--n-line-height" drLightVars)
    , eq "drawer light: --n-border-radius 3px" (Just "3px") (lookup "--n-border-radius" drLightVars)
    , eq "drawer light: --n-header-border-bottom 1px solid dividerColor" (Just "1px solid rgb(239, 239, 245)") (lookup "--n-header-border-bottom" drLightVars)
    , eq "drawer light: --n-resize-trigger-color-hover primaryColorHover #36ad6a" (Just "#36ad6a") (lookup "--n-resize-trigger-color-hover" drLightVars)

    -- drawer: cssVars dark (common-ref deltas only) -------------------------
    , eq "drawer vars: 25 keys (dark)" 25 (List.length drDarkVars)
    , eq "drawer dark: exactly 11 keys differ from light (common refs)" 11 (List.length (changedVarKeys drLightVars drDarkVars))
    , eq "drawer dark: differ-set = the 11 common-ref keys" [ "--n-color", "--n-text-color", "--n-title-text-color", "--n-header-border-bottom", "--n-footer-border-top", "--n-close-icon-color", "--n-close-icon-color-hover", "--n-close-icon-color-pressed", "--n-close-color-hover", "--n-close-color-pressed", "--n-resize-trigger-color-hover" ] (changedVarKeys drLightVars drDarkVars)
    , eq "drawer dark: --n-color modalColor rgb(44, 44, 50)" (Just "rgb(44, 44, 50)") (lookup "--n-color" drDarkVars)
    , eq "drawer dark: --n-text-color rgba(255, 255, 255, 0.82)" (Just "rgba(255, 255, 255, 0.82)") (lookup "--n-text-color" drDarkVars)
    , eq "drawer dark: --n-title-text-color rgba(255, 255, 255, 0.9)" (Just "rgba(255, 255, 255, 0.9)") (lookup "--n-title-text-color" drDarkVars)
    , eq "drawer dark: --n-header-border-bottom rgba(255, 255, 255, 0.09)" (Just "1px solid rgba(255, 255, 255, 0.09)") (lookup "--n-header-border-bottom" drDarkVars)
    , eq "drawer dark: --n-close-icon-color rgba(255, 255, 255, 0.52)" (Just "rgba(255, 255, 255, 0.52)") (lookup "--n-close-icon-color" drDarkVars)
    , eq "drawer dark: --n-close-color-hover rgba(255, 255, 255, .12)" (Just "rgba(255, 255, 255, .12)") (lookup "--n-close-color-hover" drDarkVars)
    , eq "drawer dark: --n-close-color-pressed rgba(255, 255, 255, .08)" (Just "rgba(255, 255, 255, .08)") (lookup "--n-close-color-pressed" drDarkVars)
    , eq "drawer dark: --n-resize-trigger-color-hover primaryColorHover #7fe7c4" (Just "#7fe7c4") (lookup "--n-resize-trigger-color-hover" drDarkVars)
    , eq "drawer dark: --n-box-shadow identical to light" (Just drawerShadow) (lookup "--n-box-shadow" drDarkVars)
    , eq "drawer dark: --n-header-padding identical to light" (Just "16px 24px") (lookup "--n-header-padding" drDarkVars)
    , eq "drawer dark: --n-close-size identical to light" (Just "22px") (lookup "--n-close-size" drDarkVars)
    , eq "drawer dark: --n-title-font-weight identical to light" (Just "500") (lookup "--n-title-font-weight" drDarkVars)
    , eq "drawer dark: beziers identical to light (common only)" ( Just "cubic-bezier(.4, 0, .2, 1)", Just "cubic-bezier(0, 0, .2, 1)", Just "cubic-bezier(.4, 0, 1, 1)" ) ( lookup "--n-bezier" drDarkVars, lookup "--n-bezier-out" drDarkVars, lookup "--n-bezier-in" drDarkVars )

    -- dialog: defaults -------------------------------------------------------
    , eq "dialog defaults: title Nothing" True (isNothing dgD.title)
    , eq "dialog defaults: content Nothing" True (isNothing dgD.content)
    , eq "dialog defaults: icon Nothing" True (isNothing dgD.icon)
    , eq "dialog defaults: kind Default" T.Default dgD.kind
    , eq "dialog defaults: showIcon True" True dgD.showIcon
    , eq "dialog defaults: iconPlacement IconLeft" Dialog.IconLeft dgD.iconPlacement
    , eq "dialog defaults: closable True" True dgD.closable
    , eq "dialog defaults: close Nothing" True (isNothing dgD.close)
    , eq "dialog defaults: closeFocusable False" False dgD.closeFocusable
    , eq "dialog defaults: positiveText Nothing" Nothing dgD.positiveText
    , eq "dialog defaults: negativeText Nothing" Nothing dgD.negativeText
    , eq "dialog defaults: positiveProps Nothing" True (isNothing dgD.positiveProps)
    , eq "dialog defaults: negativeProps Nothing" True (isNothing dgD.negativeProps)
    , eq "dialog defaults: action Nothing" True (isNothing dgD.action)
    , eq "dialog defaults: loading False" False dgD.loading
    , eq "dialog defaults: bordered False" False dgD.bordered
    , eq "dialog defaults: rtl False" False dgD.rtl
    , eq "dialog defaults: titleAttributes []" True (List.isEmpty dgD.titleAttributes)
    , eq "dialog defaults: contentAttributes []" True (List.isEmpty dgD.contentAttributes)
    , eq "dialog defaults: actionAttributes []" True (List.isEmpty dgD.actionAttributes)
    , eq "dialog defaults: onPositiveClick Nothing" Nothing dgD.onPositiveClick
    , eq "dialog defaults: onNegativeClick Nothing" Nothing dgD.onNegativeClick
    , eq "dialog defaults: onClose Nothing" Nothing dgD.onClose
    , eq "dialog defaults: extraClasses []" True (List.isEmpty dgD.extraClasses)
    , eq "dialog defaults: attributes []" True (List.isEmpty dgD.attributes)

    -- dialog: cssVars (exact 28-tuple order + values) ------------------------
    , eq "dialog vars: 28 keys (light, IconLeft)" 28 (List.length dgVarsLeft)
    , eq "dialog vars: exact 28-list light IconLeft (name+value, order)" expectedDialogVarsLeft dgVarsLeft
    , eq "dialog vars: slot 1 --n-font-size" (Just "--n-font-size") (listAt 0 dgVarsLeft |> Maybe.map Tuple.first)
    , eq "dialog vars: slot 2 --n-icon-color (kind-keyed)" (Just "--n-icon-color") (listAt 1 dgVarsLeft |> Maybe.map Tuple.first)
    , eq "dialog vars: slot 28 --n-action-space (last)" (Just "--n-action-space") (listAt 27 dgVarsLeft |> Maybe.map Tuple.first)
    , eq "dialog vars: NO composite --n-icon-margin (28 vars present, split only)" ( 28, Nothing ) ( List.length dgVarsLeft, lookup "--n-icon-margin" dgVarsLeft )
    , eq "dialog vars: 28 keys (light, IconTop)" 28 (List.length dgVarsTop)
    , eq "dialog vars: 28 keys (dark)" 28 (List.length dgVarsDark)

    -- dialog: kind -> --n-icon-color matrix --------------------------------
    , eq "dialog iconColor matrix" (List.map Tuple.second dialogIconColors) (List.map (\( k, _ ) -> lookup "--n-icon-color" (Dialog.cssVars Theme.default (dgKindOpts k)) |> Maybe.withDefault "?") dialogIconColors)
    , eq "dialog iconColor: Primary degrades to Default" (Just "#18a058") (lookup "--n-icon-color" (Dialog.cssVars Theme.default (dgKindOpts T.Primary)))
    , eq "dialog iconColor: Info #2080f0" (Just "#2080f0") (lookup "--n-icon-color" (Dialog.cssVars Theme.default (dgKindOpts T.Info)))
    , eq "dialog iconColor: Success #18a058" (Just "#18a058") (lookup "--n-icon-color" (Dialog.cssVars Theme.default (dgKindOpts T.Success)))
    , eq "dialog iconColor: Warning #f0a020" (Just "#f0a020") (lookup "--n-icon-color" (Dialog.cssVars Theme.default (dgKindOpts T.Warning)))
    , eq "dialog iconColor: Error #d03050" (Just "#d03050") (lookup "--n-icon-color" (Dialog.cssVars Theme.default (dgKindOpts T.Error)))

    -- dialog: iconPlacement margin switch ----------------------------------
    , eq "dialog IconLeft margins (top/right/bottom/left)" [ "0", "4px", "0", "0" ] (List.map (\k -> lookup k dgVarsLeft |> Maybe.withDefault "?") dialogMarginKeys |> List.drop 1)
    , eq "dialog IconLeft close-margin 20px 26px 0 0" (Just "20px 26px 0 0") (lookup "--n-close-margin" dgVarsLeft)
    , eq "dialog IconTop margins (top/right/bottom/left)" [ "4px", "0", "8px", "0" ] (List.map (\k -> lookup k dgVarsTop |> Maybe.withDefault "?") dialogMarginKeys |> List.drop 1)
    , eq "dialog IconTop close-margin 10px 16px 0 0" (Just "10px 16px 0 0") (lookup "--n-close-margin" dgVarsTop)
    , eq "dialog placement switch touches EXACTLY the 4 differing margin keys" [ "--n-close-margin", "--n-icon-margin-top", "--n-icon-margin-right", "--n-icon-margin-bottom" ] (changedVarKeys dgVarsLeft dgVarsTop)

    -- dialog: dark (common-ref deltas only) --------------------------------
    , eq "dialog dark: --n-color rgb(44, 44, 50)" (Just "rgb(44, 44, 50)") (lookup "--n-color" dgVarsDark)
    , eq "dialog dark: --n-text-color rgba(255, 255, 255, 0.82)" (Just "rgba(255, 255, 255, 0.82)") (lookup "--n-text-color" dgVarsDark)
    , eq "dialog dark: --n-title-text-color rgba(255, 255, 255, 0.9)" (Just "rgba(255, 255, 255, 0.9)") (lookup "--n-title-text-color" dgVarsDark)
    , eq "dialog dark: --n-border rgba(255, 255, 255, 0.09)" (Just "1px solid rgba(255, 255, 255, 0.09)") (lookup "--n-border" dgVarsDark)
    , eq "dialog dark: --n-icon-color Error #e88080" (Just "#e88080") (lookup "--n-icon-color" (Dialog.cssVars Theme.dark (dgKindOpts T.Error)))
    , eq "dialog dark: --n-icon-color Default #63e2b7" (Just "#63e2b7") (lookup "--n-icon-color" (Dialog.cssVars Theme.dark (dgKindOpts T.Default)))
    , eq "dialog dark: self-only keys identical to light (sizes/padding/margins)" [ "16px 28px 20px 28px", "28px", "22px", "18px", "20px 26px 0 0", "4px", "8px 0 16px 0", "12px", "18px", "500" ] (List.map (\k -> lookup k dgVarsDark |> Maybe.withDefault "?") dialogSelfOnlyKeys)
    , eq "dialog dark: --n-bezier identical to light" (Just "cubic-bezier(.4, 0, .2, 1)") (lookup "--n-bezier" dgVarsDark)

    -- popconfirm: defaults ---------------------------------------------------
    , eq "popconfirm defaults: showIcon True" True pcD.showIcon
    , eq "popconfirm defaults: icon Nothing" True (isNothing pcD.icon)
    , eq "popconfirm defaults: positiveText DefaultText" Popconfirm.DefaultText pcD.positiveText
    , eq "popconfirm defaults: negativeText DefaultText" Popconfirm.DefaultText pcD.negativeText
    , eq "popconfirm defaults: positiveProps Nothing" True (isNothing pcD.positiveProps)
    , eq "popconfirm defaults: negativeProps Nothing" True (isNothing pcD.negativeProps)
    , eq "popconfirm defaults: onPositiveClick Nothing" Nothing pcD.onPositiveClick
    , eq "popconfirm defaults: onNegativeClick Nothing" Nothing pcD.onNegativeClick
    , eq "popconfirm defaults: action Nothing" True (isNothing pcD.action)
    , eq "popconfirm defaults: popover = Popover.defaults" Popover.defaults pcD.popover

    -- popconfirm: cssVars (the 4 panel vars, exact order/values) -----------
    , eq "popconfirm cssVars: 4 keys (light)" 4 (List.length (Popconfirm.cssVars light))
    , eq "popconfirm cssVars: exact 4-list light (name+value, order)" expectedPopconfirmVars (Popconfirm.cssVars light)
    , eq "popconfirm cssVars: slot 1 --n-bezier" (Just "--n-bezier") (listAt 0 (Popconfirm.cssVars light) |> Maybe.map Tuple.first)
    , eq "popconfirm cssVars: slot 4 --n-icon-color (last)" (Just "--n-icon-color") (listAt 3 (Popconfirm.cssVars light) |> Maybe.map Tuple.first)
    , eq "popconfirm cssVars: --n-font-size 14px" (Just "14px") (lookup "--n-font-size" (Popconfirm.cssVars light))
    , eq "popconfirm cssVars: --n-icon-size 22px" (Just "22px") (lookup "--n-icon-size" (Popconfirm.cssVars light))
    , eq "popconfirm cssVars: --n-icon-color warningColor #f0a020" (Just "#f0a020") (lookup "--n-icon-color" (Popconfirm.cssVars light))
    , eq "popconfirm cssVars: 4 keys (dark)" 4 (List.length (Popconfirm.cssVars dark))
    , eq "popconfirm cssVars: exact 4-list dark (name+value, order)" expectedPopconfirmDarkVars (Popconfirm.cssVars dark)
    , eq "popconfirm cssVars dark: --n-icon-color warningColor #f2c97d" (Just "#f2c97d") (lookup "--n-icon-color" (Popconfirm.cssVars dark))
    , eq "popconfirm cssVars dark: --n-font-size identical to light (14px)" (Just "14px") (lookup "--n-font-size" (Popconfirm.cssVars dark))
    , eq "popconfirm light/dark differ in exactly icon-color" [ "--n-icon-color" ] (changedVarKeys (Popconfirm.cssVars light) (Popconfirm.cssVars dark))
    , eq "popconfirm cssVars non-empty (stub differential: [] vs 4)" True (not (List.isEmpty (Popconfirm.cssVars light)))

    -- popselect: defaults ---------------------------------------------------
    , eq "popselect defaults: placement Bottom" Popover.Bottom psD.placement
    , eq "popselect defaults: size Medium" Popselect.Medium psD.size
    , eq "popselect defaults: multiple False" False psD.multiple
    , eq "popselect defaults: value Single Nothing" (SelectMenu.Single Nothing) psD.value
    , eq "popselect defaults: cancelable False" False psD.cancelable
    , eq "popselect defaults: showCheckmark True" True psD.showCheckmark
    , eq "popselect defaults: width Nothing" Nothing psD.width
    , eq "popselect defaults: overlap False" False psD.overlap
    , eq "popselect defaults: arrowPointToCenter False" False psD.arrowPointToCenter
    , eq "popselect defaults: rtl False" False psD.rtl
    , eq "popselect defaults: transition Nothing" Nothing psD.transition
    , eq "popselect defaults: header Nothing" True (isNothing psD.header)
    , eq "popselect defaults: action Nothing" True (isNothing psD.action)
    , eq "popselect defaults: empty Nothing" True (isNothing psD.empty)
    , eq "popselect defaults: onUpdateValue Nothing" Nothing psD.onUpdateValue
    , eq "popselect defaults: scrollbarProps Nothing" True (isNothing psD.scrollbarProps)
    , eq "popselect defaults: attributes []" True (List.isEmpty psD.attributes)

    -- popselect: placement alias -------------------------------------------
    , eq "popselect placementName: Bottom" "bottom" (Popselect.placementName Popover.Bottom)
    , eq "popselect placementName: TopStart" "top-start" (Popselect.placementName Popover.TopStart)
    , eq "popselect placementName: LeftEnd" "left-end" (Popselect.placementName Popover.LeftEnd)

    -- popselect: toggleValue (green now — the pure panel toggle) -----------
    , eq "popselect toggleValue multiple removes a member (order kept)" (SelectMenu.Multiple [ "a" ]) (Popselect.toggleValue True False (SelectMenu.Multiple [ "a", "b" ]) "b")
    , eq "popselect toggleValue multiple removes middle (order kept)" (SelectMenu.Multiple [ "a", "c" ]) (Popselect.toggleValue True False (SelectMenu.Multiple [ "a", "b", "c" ]) "b")
    , eq "popselect toggleValue multiple appends a new value" (SelectMenu.Multiple [ "a", "b" ]) (Popselect.toggleValue True False (SelectMenu.Multiple [ "a" ]) "b")
    , eq "popselect toggleValue multiple on empty list appends" (SelectMenu.Multiple [ "k" ]) (Popselect.toggleValue True False (SelectMenu.Multiple []) "k")
    , eq "popselect toggleValue multiple: non-list current starts [key]" (SelectMenu.Multiple [ "k" ]) (Popselect.toggleValue True False (SelectMenu.Single Nothing) "k")
    , eq "popselect toggleValue multiple: Single (Just x) starts [key]" (SelectMenu.Multiple [ "k" ]) (Popselect.toggleValue True False (SelectMenu.Single (Just "x")) "k")
    , eq "popselect toggleValue multiple ignores cancelable" (SelectMenu.Multiple [ "a" ]) (Popselect.toggleValue True True (SelectMenu.Multiple [ "a", "b" ]) "b")
    , eq "popselect toggleValue single selects the key" (SelectMenu.Single (Just "b")) (Popselect.toggleValue False False (SelectMenu.Single (Just "a")) "b")
    , eq "popselect toggleValue single from null selects" (SelectMenu.Single (Just "a")) (Popselect.toggleValue False False (SelectMenu.Single Nothing) "a")
    , eq "popselect toggleValue single cancelable + current -> Nothing" (SelectMenu.Single Nothing) (Popselect.toggleValue False True (SelectMenu.Single (Just "a")) "a")
    , eq "popselect toggleValue single cancelable + other -> selects" (SelectMenu.Single (Just "b")) (Popselect.toggleValue False True (SelectMenu.Single (Just "a")) "b")
    , eq "popselect toggleValue single non-cancelable re-select stays" (SelectMenu.Single (Just "a")) (Popselect.toggleValue False False (SelectMenu.Single (Just "a")) "a")
    , eq "popselect toggleValue single ignores a Multiple current" (SelectMenu.Single (Just "k")) (Popselect.toggleValue False False (SelectMenu.Multiple [ "a" ]) "k")

    -- cascader: treemate ground truth (outputs of the real treemate -----
    -- package on the same tree, node-pinned — see Cascader's docs)
    , eq "cascader gck all [a1]: the leaf + its indeterminate parent" { checkedKeys = [ "a1" ], indeterminateKeys = [ "a" ] } (Cascader.getCheckedKeys True Cascader.All [ "a1" ] cascTree)
    , eq "cascader gck all [a2y]: a disabled sibling counts full, a2 checked" { checkedKeys = [ "a2y", "a2" ], indeterminateKeys = [ "a" ] } (Cascader.getCheckedKeys True Cascader.All [ "a2y" ] cascTree)
    , eq "cascader gck all [a1,a2y,a3]: full aggregate, walk-append order" { checkedKeys = [ "a1", "a2y", "a3", "a2", "a" ], indeterminateKeys = [] } (Cascader.getCheckedKeys True Cascader.All [ "a1", "a2y", "a3" ] cascTree)
    , eq "cascader gck parent [a1,a2y,a3]: collapses to the topmost" { checkedKeys = [ "a" ], indeterminateKeys = [] } (Cascader.getCheckedKeys True Cascader.Parent [ "a1", "a2y", "a3" ] cascTree)
    , eq "cascader gck child [a]: leaves only, the empty branch a3 drops" { checkedKeys = [ "a1", "a2y" ], indeterminateKeys = [ "a" ] } (Cascader.getCheckedKeys True Cascader.Child [ "a" ] cascTree)
    , eq "cascader gck child [a,a2y]: raw keys seed the set order" { checkedKeys = [ "a2y", "a1" ], indeterminateKeys = [ "a" ] } (Cascader.getCheckedKeys True Cascader.Child [ "a", "a2y" ] cascTree)
    , eq "cascader gck all [b1]: a disabled parent is never indeterminate" { checkedKeys = [ "b1" ], indeterminateKeys = [] } (Cascader.getCheckedKeys True Cascader.All [ "b1" ] cascTree)
    , eq "cascader gck all [b,b1]: disabled keys stay put" { checkedKeys = [ "b", "b1" ], indeterminateKeys = [] } (Cascader.getCheckedKeys True Cascader.All [ "b", "b1" ] cascTree)
    , eq "cascader gck no-cascade [a1,a2y]: passthrough, nothing indeterminate" { checkedKeys = [ "a1", "a2y" ], indeterminateKeys = [] } (Cascader.getCheckedKeys False Cascader.All [ "a1", "a2y" ] cascTree)
    , eq "cascader gck all [mc] mixed tree: unchecked before checked still indeterminate" { checkedKeys = [ "mc" ], indeterminateKeys = [ "m" ] } (Cascader.getCheckedKeys True Cascader.All [ "mc" ] cascMixedTree)
    , eq "cascader gck all [mc2] mixed tree reversed: checked first, same verdict" { checkedKeys = [ "mc2" ], indeterminateKeys = [ "m2" ] } (Cascader.getCheckedKeys True Cascader.All [ "mc2" ] cascMixedTreeRev)
    , eq "cascader gck no-cascade [a1,a1]: the no-toggle view keeps raw keys" { checkedKeys = [ "a1", "a1" ], indeterminateKeys = [] } (Cascader.getCheckedKeys False Cascader.All [ "a1", "a1" ] cascTree)
    , eq "cascader check no-cascade c <- [a1,a1]: merge dedupes the current value" [ "a1", "c" ] (Cascader.check False Cascader.All "c" [ "a1", "a1" ] cascTree)
    , eq "cascader check no-cascade a1 <- [a1,a1]: the key itself dedupes" [ "a1" ] (Cascader.check False Cascader.All "a1" [ "a1", "a1" ] cascTree)
    , eq "cascader uncheck no-cascade a1 <- [a1,a1,a2y]: minus drops every occurrence" [ "a2y" ] (Cascader.uncheck False Cascader.All "a1" [ "a1", "a1", "a2y" ] cascTree)
    , eq "cascader gck all [zz]: an unknown key stays" { checkedKeys = [ "zz" ], indeterminateKeys = [] } (Cascader.getCheckedKeys True Cascader.All [ "zz" ] cascTree)
    , eq "cascader check a <- [c]: the subtree joins, DFS order, disabled leaf blocked" [ "c", "a", "a1", "a2", "a2y", "a3" ] (Cascader.check True Cascader.All "a" [ "c" ] cascTree)
    , eq "cascader check a2x <- [c]: a disabled key itself stays" [ "c", "a2x" ] (Cascader.check True Cascader.All "a2x" [ "c" ] cascTree)
    , eq "cascader uncheck a1: the key's subtree leaves, parent indeterminate" [ "a2y", "a3", "a2" ] (Cascader.uncheck True Cascader.All "a1" [ "a1", "a2y", "a3", "a" ] cascTree)
    , eq "cascader uncheck a (child): the whole value empties" [] (Cascader.uncheck True Cascader.Child "a" [ "a", "a1", "a2", "a2y", "a3" ] cascTree)
    , eq "cascader toggle single child on a branch: unchanged" (SelectMenu.Single (Just "x")) (Cascader.toggleValue True Cascader.Child (SelectMenu.Single (Just "x")) "a" cascTree)
    , eq "cascader toggle single child on a leaf: selects" (SelectMenu.Single (Just "a1")) (Cascader.toggleValue True Cascader.Child (SelectMenu.Single Nothing) "a1" cascTree)
    , eq "cascader toggle single child on an unknown key: unchanged" (SelectMenu.Single Nothing) (Cascader.toggleValue True Cascader.Child (SelectMenu.Single Nothing) "zz" cascTree)
    , eq "cascader toggle single all on a branch: selects" (SelectMenu.Single (Just "a")) (Cascader.toggleValue True Cascader.All (SelectMenu.Single Nothing) "a" cascTree)
    , eq "cascader toggle multiple member: unchecks the aggregate" (SelectMenu.Multiple [ "a2y", "a3", "a2" ]) (Cascader.toggleValue True Cascader.All (SelectMenu.Multiple [ "a1", "a2y", "a3", "a" ]) "a1" cascTree)
    , eq "cascader toggle multiple new: checks the subtree" (SelectMenu.Multiple [ "c", "a", "a1", "a2", "a2y", "a3" ]) (Cascader.toggleValue True Cascader.All (SelectMenu.Multiple [ "c" ]) "a" cascTree)
    , eq "cascader valueKeys: a Single value contributes none" [] (Cascader.valueKeys (SelectMenu.Single (Just "a")))
    , eq "cascader valueKeys: a Multiple value passes through" [ "a1", "a2y" ] (Cascader.valueKeys (SelectMenu.Multiple [ "a1", "a2y" ]))

    -- cascader: filterOptions (createSelectOptions + the default filter) --
    , eq "cascader filter all, no pattern: every enabled node, document order" [ "a", "a1", "a2", "a2y", "a3", "c" ] (cascRowValues (Cascader.filterOptions "" Cascader.All " / " cascTree))
    , eq "cascader filter child, no pattern: leaves only (an empty branch is no leaf)" [ "a1", "a2y", "c" ] (cascRowValues (Cascader.filterOptions "" Cascader.Child " / " cascTree))
    , eq "cascader filter 'a2': an ancestor label matches its whole path" [ "a2", "a2y" ] (cascRowValues (Cascader.filterOptions "a2" Cascader.All " / " cascTree))
    , eq "cascader filter rows carry path labels"
        [ SelectMenu.Option { value = "a1", label = "A / A1", disabled = False, attributes = [] }
        , SelectMenu.Option { value = "a2y", label = "A / A2 / A2Y", disabled = False, attributes = [] }
        , SelectMenu.Option { value = "c", label = "C", disabled = False, attributes = [] }
        ]
        (Cascader.filterOptions "" Cascader.Child " / " cascTree)

    -- cascader: menuVars (17, exact order; mask = popoverColor @ .75) -----
    , eq "cascader menuVars: 17 keys" 17 (List.length (Cascader.menuVars light))
    , eq "cascader menuVars: exact key order"
        [ "--n-bezier", "--n-menu-border-radius", "--n-menu-box-shadow", "--n-menu-height", "--n-column-width", "--n-menu-color", "--n-menu-divider-color", "--n-option-height", "--n-option-font-size", "--n-option-text-color", "--n-option-text-color-disabled", "--n-option-text-color-active", "--n-option-color-hover", "--n-option-check-mark-color", "--n-option-arrow-color", "--n-menu-mask-color", "--n-loading-color" ]
        (List.map Tuple.first (Cascader.menuVars light))
    , eq "cascader menuVars: mask color = popoverColor at alpha .75" (Just "rgba(255, 255, 255, 0.75)") (lookup "--n-menu-mask-color" (Cascader.menuVars light))
    , eq "cascader selectMenuVars: the 23 menu vars then the 17 cascader ones" 40 (List.length (Cascader.selectMenuVars light))

    -- popselect: cssVars merged 39 (23 menu -> box-shadow -> 15 popover) ----
    , eq "popselect cssVars: 39 keys (light medium)" 39 (List.length (Popselect.cssVars light Popselect.Medium))
    , eq "popselect cssVars: exact 39-list light medium (name+value, order)" expectedPopselectVars (Popselect.cssVars light Popselect.Medium)
    , eq "popselect cssVars: slot 1 is --n-height (menu block first)" (Just "--n-height") (listAt 0 (Popselect.cssVars light Popselect.Medium) |> Maybe.map Tuple.first)
    , eq "popselect cssVars: slot 24 is --n-menu-box-shadow (after the 23 menu vars)" (Just "--n-menu-box-shadow") (listAt 23 (Popselect.cssVars light Popselect.Medium) |> Maybe.map Tuple.first)
    , eq "popselect cssVars: slot 25 is --n-box-shadow (popover block starts)" (Just "--n-box-shadow") (listAt 24 (Popselect.cssVars light Popselect.Medium) |> Maybe.map Tuple.first)
    , eq "popselect cssVars: --n-menu-box-shadow = common boxShadow2" (Just popselectShadow) (lookup "--n-menu-box-shadow" (Popselect.cssVars light Popselect.Medium))
    , eq "popselect cssVars: --n-padding overridden to 0" (Just "0") (lookup "--n-padding" (Popselect.cssVars light Popselect.Medium))
    , eq "popselect cssVars: --n-padding sits at slot 37 (13th popover var)" (Just ( "--n-padding", "0" )) (listAt 36 (Popselect.cssVars light Popselect.Medium))
    , eq "popselect cssVars: --n-color (menu) #fff" (Just "#fff") (lookup "--n-color" (Popselect.cssVars light Popselect.Medium))
    , eq "popselect cssVars: --n-option-height 34px (medium menu var)" (Just "34px") (lookup "--n-option-height" (Popselect.cssVars light Popselect.Medium))
    , eq "popselect cssVars: popover tail differs from raw 15 in exactly --n-padding" [ "--n-padding" ] (changedVarKeys expectedPopoverVars (List.drop 24 (Popselect.cssVars light Popselect.Medium)))
    , eq "popselect cssVars: size switch small -> --n-option-height 28px" (Just "28px") (lookup "--n-option-height" (Popselect.cssVars light Popselect.Small))
    , eq "popselect cssVars: size switch huge -> --n-option-height 46px" (Just "46px") (lookup "--n-option-height" (Popselect.cssVars light Popselect.Huge))
    , eq "popselect cssVars: still 39 keys (dark)" 39 (List.length (Popselect.cssVars dark Popselect.Medium))
    , eq "popselect cssVars dark: --n-padding still 0" (Just "0") (lookup "--n-padding" (Popselect.cssVars dark Popselect.Medium))
    , eq "popselect cssVars non-empty (stub differential: [] vs 39)" True (not (List.isEmpty (Popselect.cssVars light Popselect.Medium)))

    -- selectmenu: defaults -------------------------------------------------
    , eq "selectmenu defaults: size Medium" SelectMenu.Medium smD.size
    , eq "selectmenu defaults: multiple False" False smD.multiple
    , eq "selectmenu defaults: value Single Nothing" (SelectMenu.Single Nothing) smD.value
    , eq "selectmenu defaults: showCheckmark True" True smD.showCheckmark
    , eq "selectmenu defaults: focusable False" False smD.focusable
    , eq "selectmenu defaults: header Nothing" True (isNothing smD.header)
    , eq "selectmenu defaults: action Nothing" True (isNothing smD.action)
    , eq "selectmenu defaults: empty Nothing" True (isNothing smD.empty)
    , eq "selectmenu defaults: onToggle Nothing" Nothing smD.onToggle
    , eq "selectmenu defaults: checkmarkTransition Nothing" Nothing smD.checkmarkTransition
    , eq "selectmenu defaults: rtl False" False smD.rtl
    , eq "selectmenu defaults: extraClasses []" True (List.isEmpty smD.extraClasses)
    , eq "selectmenu defaults: attributes []" True (List.isEmpty smD.attributes)

    -- selectmenu: cssVars exact 23 (medium) --------------------------------
    , eq "selectmenu cssVars: 23 keys (light medium)" 23 (List.length (SelectMenu.cssVars light SelectMenu.Medium))
    , eq "selectmenu cssVars: exact 23-list light medium (name+value, order)" expectedSelectMenuVarsMedium (SelectMenu.cssVars light SelectMenu.Medium)
    , eq "selectmenu cssVars: slot 1 --n-height" (Just "--n-height") (listAt 0 (SelectMenu.cssVars light SelectMenu.Medium) |> Maybe.map Tuple.first)
    , eq "selectmenu cssVars: slot 23 --n-loading-size (last)" (Just "--n-loading-size") (listAt 22 (SelectMenu.cssVars light SelectMenu.Medium) |> Maybe.map Tuple.first)
    , eq "selectmenu cssVars: --n-height is the calc literal" (Just "calc(var(--n-option-height) * 7.6)") (lookup "--n-height" (SelectMenu.cssVars light SelectMenu.Medium))
    , eq "selectmenu cssVars: --n-option-padding-left 12px (split shorthand)" (Just "12px") (lookup "--n-option-padding-left" (SelectMenu.cssVars light SelectMenu.Medium))
    , eq "selectmenu cssVars: --n-option-padding-right 12px" (Just "12px") (lookup "--n-option-padding-right" (SelectMenu.cssVars light SelectMenu.Medium))
    , eq "selectmenu cssVars: --n-option-color-active is the transparent literal" (Just "rgba(0, 0, 0, 0)") (lookup "--n-option-color-active" (SelectMenu.cssVars light SelectMenu.Medium))
    , eq "selectmenu cssVars: --n-option-check-color = primary #18a058" (Just "#18a058") (lookup "--n-option-check-color" (SelectMenu.cssVars light SelectMenu.Medium))
    , eq "selectmenu cssVars: --n-option-text-color-disabled rgba(194, 194, 194, 1)" (Just "rgba(194, 194, 194, 1)") (lookup "--n-option-text-color-disabled" (SelectMenu.cssVars light SelectMenu.Medium))

    -- selectmenu: size switching -------------------------------------------
    , eq "selectmenu cssVars small --n-option-height 28px" (Just "28px") (lookup "--n-option-height" (SelectMenu.cssVars light SelectMenu.Small))
    , eq "selectmenu cssVars small --n-option-font-size 14px" (Just "14px") (lookup "--n-option-font-size" (SelectMenu.cssVars light SelectMenu.Small))
    , eq "selectmenu cssVars large --n-option-height 40px" (Just "40px") (lookup "--n-option-height" (SelectMenu.cssVars light SelectMenu.Large))
    , eq "selectmenu cssVars large --n-option-font-size 15px" (Just "15px") (lookup "--n-option-font-size" (SelectMenu.cssVars light SelectMenu.Large))
    , eq "selectmenu cssVars huge --n-option-height 46px" (Just "46px") (lookup "--n-option-height" (SelectMenu.cssVars light SelectMenu.Huge))
    , eq "selectmenu cssVars huge --n-option-font-size 16px" (Just "16px") (lookup "--n-option-font-size" (SelectMenu.cssVars light SelectMenu.Huge))
    , eq "selectmenu cssVars tiny --n-option-height 22px" (Just "22px") (lookup "--n-option-height" (SelectMenu.cssVars light SelectMenu.Tiny))
    , eq "selectmenu cssVars tiny --n-option-font-size 12px" (Just "12px") (lookup "--n-option-font-size" (SelectMenu.cssVars light SelectMenu.Tiny))
    , eq "selectmenu cssVars: small switches exactly height (font-size small=medium=14px upstream — the 12/14/14/15/16 scale)" [ "--n-option-height" ] (changedVarKeys (SelectMenu.cssVars light SelectMenu.Medium) (SelectMenu.cssVars light SelectMenu.Small))
    , eq "selectmenu cssVars: --n-option-padding does NOT switch (constant 0 12px)" ( Just "0 12px", Just "0 12px" ) ( lookup "--n-option-padding" (SelectMenu.cssVars light SelectMenu.Tiny), lookup "--n-option-padding" (SelectMenu.cssVars light SelectMenu.Huge) )

    -- selectmenu: dark ----------------------------------------------------
    , eq "selectmenu cssVars: 23 keys (dark medium)" 23 (List.length (SelectMenu.cssVars dark SelectMenu.Medium))
    , eq "selectmenu cssVars dark: --n-color = popoverColor rgb(72, 72, 78)" (Just "rgb(72, 72, 78)") (lookup "--n-color" (SelectMenu.cssVars dark SelectMenu.Medium))
    , eq "selectmenu cssVars dark: --n-option-text-color-active #63e2b7" (Just "#63e2b7") (lookup "--n-option-text-color-active" (SelectMenu.cssVars dark SelectMenu.Medium))
    , eq "selectmenu cssVars dark: --n-option-color-active stays transparent" (Just "rgba(0, 0, 0, 0)") (lookup "--n-option-color-active" (SelectMenu.cssVars dark SelectMenu.Medium))
    , eq "selectmenu cssVars dark: --n-height identical to light" (Just "calc(var(--n-option-height) * 7.6)") (lookup "--n-height" (SelectMenu.cssVars dark SelectMenu.Medium))
    , eq "selectmenu cssVars non-empty (stub differential: [] vs 23)" True (not (List.isEmpty (SelectMenu.cssVars light SelectMenu.Medium)))

    -- basesel: defaults ----------------------------------------------------
    , eq "basesel defaults: size Medium" BaseSelection.Medium bsD.size
    , eq "basesel defaults: multiple False" False bsD.multiple
    , eq "basesel defaults: filterable False" False bsD.filterable
    , eq "basesel defaults: active False" False bsD.active
    , eq "basesel defaults: focused False" False bsD.focused
    , eq "basesel defaults: disabled False" False bsD.disabled
    , eq "basesel defaults: bordered True" True bsD.bordered
    , eq "basesel defaults: status Nothing" Nothing bsD.status
    , eq "basesel defaults: loading False" False bsD.loading
    , eq "basesel defaults: showClear False" False bsD.showClear
    , eq "basesel defaults: showArrow True" True bsD.showArrow
    , eq "basesel defaults: placeholder 'Please Select'" "Please Select" bsD.placeholder
    , eq "basesel defaults: pattern ''" "" bsD.pattern
    , eq "basesel defaults: selectedLabel Nothing" Nothing bsD.selectedLabel
    , eq "basesel defaults: tags []" True (List.isEmpty bsD.tags)
    , eq "basesel defaults: ellipsisTag Nothing" Nothing bsD.ellipsisTag
    , eq "basesel defaults: arrow Nothing" True (isNothing bsD.arrow)
    , eq "basesel defaults: onClear Nothing" Nothing bsD.onClear
    , eq "basesel defaults: onPatternInput Nothing" Nothing bsD.onPatternInput
    , eq "basesel defaults: onDeleteTag Nothing" Nothing bsD.onDeleteTag
    , eq "basesel defaults: rtl False" False bsD.rtl
    , eq "basesel defaults: attributes []" True (List.isEmpty bsD.attributes)

    -- basesel: cssVars exact 52 (upstream order, light medium) --------------
    , eq "basesel cssVars: 52 keys (light medium)" 52 (List.length (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: exact 52-list light medium (name+value, order)" expectedBaseSelectionVarsMedium (BaseSelection.cssVars light BaseSelection.Medium)
    , eq "basesel cssVars: slot 1 --n-bezier" (Just "--n-bezier") (listAt 0 (BaseSelection.cssVars light BaseSelection.Medium) |> Maybe.map Tuple.first)
    , eq "basesel cssVars: slot 15 --n-height (right after --n-font-size)" (Just "--n-height") (listAt 14 (BaseSelection.cssVars light BaseSelection.Medium) |> Maybe.map Tuple.first)
    , eq "basesel cssVars: slot 23 --n-padding-multiple-bottom (last padding var)" (Just "--n-padding-multiple-bottom") (listAt 22 (BaseSelection.cssVars light BaseSelection.Medium) |> Maybe.map Tuple.first)
    , eq "basesel cssVars: slot 52 --n-font-weight (last)" (Just "--n-font-weight") (listAt 51 (BaseSelection.cssVars light BaseSelection.Medium) |> Maybe.map Tuple.first)
    , eq "basesel cssVars: non-empty (stub differential: [] vs 52)" True (not (List.isEmpty (BaseSelection.cssVars light BaseSelection.Medium)))

    -- basesel: cssVars padding split (single `0 26px 0 12px` / multiple `3px 26px 0 12px`)
    , eq "basesel cssVars: --n-padding-single-top 0" (Just "0") (lookup "--n-padding-single-top" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-padding-single-right 26px" (Just "26px") (lookup "--n-padding-single-right" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-padding-single-bottom 0" (Just "0") (lookup "--n-padding-single-bottom" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-padding-single-left 12px" (Just "12px") (lookup "--n-padding-single-left" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-padding-multiple-top 3px" (Just "3px") (lookup "--n-padding-multiple-top" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-padding-multiple-right 26px" (Just "26px") (lookup "--n-padding-multiple-right" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-padding-multiple-bottom 0" (Just "0") (lookup "--n-padding-multiple-bottom" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-padding-multiple-left 12px" (Just "12px") (lookup "--n-padding-multiple-left" (BaseSelection.cssVars light BaseSelection.Medium))

    -- basesel: cssVars size-keyed (height 22/28/34/40, font-size 12/14/14/15)
    , eq "basesel cssVars tiny --n-height 22px" (Just "22px") (lookup "--n-height" (BaseSelection.cssVars light BaseSelection.Tiny))
    , eq "basesel cssVars tiny --n-font-size 12px" (Just "12px") (lookup "--n-font-size" (BaseSelection.cssVars light BaseSelection.Tiny))
    , eq "basesel cssVars small --n-height 28px" (Just "28px") (lookup "--n-height" (BaseSelection.cssVars light BaseSelection.Small))
    , eq "basesel cssVars small --n-font-size 14px" (Just "14px") (lookup "--n-font-size" (BaseSelection.cssVars light BaseSelection.Small))
    , eq "basesel cssVars medium --n-height 34px" (Just "34px") (lookup "--n-height" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars medium --n-font-size 14px" (Just "14px") (lookup "--n-font-size" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars large --n-height 40px" (Just "40px") (lookup "--n-height" (BaseSelection.cssVars light BaseSelection.Large))
    , eq "basesel cssVars large --n-font-size 15px" (Just "15px") (lookup "--n-font-size" (BaseSelection.cssVars light BaseSelection.Large))
    , eq "basesel cssVars: small vs medium switches exactly --n-height (font-size small=medium=14px)" [ "--n-height" ] (changedVarKeys (BaseSelection.cssVars light BaseSelection.Medium) (BaseSelection.cssVars light BaseSelection.Small))
    , eq "basesel cssVars: medium vs large switches exactly height+font-size" [ "--n-font-size", "--n-height" ] (List.sort (changedVarKeys (BaseSelection.cssVars light BaseSelection.Medium) (BaseSelection.cssVars light BaseSelection.Large)))

    -- basesel: cssVars cross-check against `NUI.Theme.InternalSelection.vars`
    , eq "basesel cssVars: --n-border = theme.border" (Just (InternalSelectionTheme.vars light).border) (lookup "--n-border" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-caret-color = theme.caretColor" (Just (InternalSelectionTheme.vars light).caretColor) (lookup "--n-caret-color" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-color = theme.color" (Just (InternalSelectionTheme.vars light).color) (lookup "--n-color" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-clear-size = theme.clearSize" (Just (InternalSelectionTheme.vars light).clearSize) (lookup "--n-clear-size" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-arrow-size = theme.arrowSize" (Just (InternalSelectionTheme.vars light).arrowSize) (lookup "--n-arrow-size" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-font-weight = theme.fontWeight" (Just (InternalSelectionTheme.vars light).fontWeight) (lookup "--n-font-weight" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-placeholder-color = theme.placeholderColor" (Just (InternalSelectionTheme.vars light).placeholderColor) (lookup "--n-placeholder-color" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-height medium = theme.heightMedium" (Just (InternalSelectionTheme.vars light).heightMedium) (lookup "--n-height" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-font-size medium = theme.fontSizeMedium" (Just (InternalSelectionTheme.vars light).fontSizeMedium) (lookup "--n-font-size" (BaseSelection.cssVars light BaseSelection.Medium))
    , eq "basesel cssVars: --n-height tiny = theme.heightTiny" (Just (InternalSelectionTheme.vars light).heightTiny) (lookup "--n-height" (BaseSelection.cssVars light BaseSelection.Tiny))
    , eq "basesel cssVars: --n-font-size large = theme.fontSizeLarge" (Just (InternalSelectionTheme.vars light).fontSizeLarge) (lookup "--n-font-size" (BaseSelection.cssVars light BaseSelection.Large))

    -- select: defaults ------------------------------------------------------
    , eq "select defaults: size Medium" Select.Medium selD.size
    , eq "select defaults: menuSize Nothing" Nothing selD.menuSize
    , eq "select defaults: multiple False" False selD.multiple
    , eq "select defaults: filterable False" False selD.filterable
    , eq "select defaults: value Single Nothing" (SelectMenu.Single Nothing) selD.value
    , eq "select defaults: placeholder 'Please Select'" "Please Select" selD.placeholder
    , eq "select defaults: clearable False" False selD.clearable
    , eq "select defaults: hover False" False selD.hover
    , eq "select defaults: active False" False selD.active
    , eq "select defaults: focused False" False selD.focused
    , eq "select defaults: disabled False" False selD.disabled
    , eq "select defaults: bordered True" True selD.bordered
    , eq "select defaults: status Nothing" Nothing selD.status
    , eq "select defaults: loading False" False selD.loading
    , eq "select defaults: showArrow True" True selD.showArrow
    , eq "select defaults: maxTagCount Nothing" Nothing selD.maxTagCount
    , eq "select defaults: fallbackOption True" True selD.fallbackOption
    , eq "select defaults: pattern ''" "" selD.pattern
    , eq "select defaults: arrow Nothing" True (isNothing selD.arrow)
    , eq "select defaults: onClear Nothing" Nothing selD.onClear
    , eq "select defaults: onPatternInput Nothing" Nothing selD.onPatternInput
    , eq "select defaults: onDeleteTag Nothing" Nothing selD.onDeleteTag
    , eq "select defaults: onUpdateValue Nothing" Nothing selD.onUpdateValue
    , eq "select defaults: rtl False" False selD.rtl
    , eq "select defaults: attributes []" True (List.isEmpty selD.attributes)

    -- select: toggleValue (the pure toggle; single has no cancelable) -------
    , eq "select toggleValue multiple removes a member (order kept)" (SelectMenu.Multiple [ "a" ]) (Select.toggleValue True (SelectMenu.Multiple [ "a", "b" ]) "b")
    , eq "select toggleValue multiple removes middle (order kept)" (SelectMenu.Multiple [ "a", "c" ]) (Select.toggleValue True (SelectMenu.Multiple [ "a", "b", "c" ]) "b")
    , eq "select toggleValue multiple appends a new value" (SelectMenu.Multiple [ "a", "b" ]) (Select.toggleValue True (SelectMenu.Multiple [ "a" ]) "b")
    , eq "select toggleValue multiple on empty list appends" (SelectMenu.Multiple [ "k" ]) (Select.toggleValue True (SelectMenu.Multiple []) "k")
    , eq "select toggleValue multiple: non-list current starts [key]" (SelectMenu.Multiple [ "k" ]) (Select.toggleValue True (SelectMenu.Single Nothing) "k")
    , eq "select toggleValue multiple: Single (Just x) starts [key]" (SelectMenu.Multiple [ "k" ]) (Select.toggleValue True (SelectMenu.Single (Just "x")) "k")
    , eq "select toggleValue single selects the key" (SelectMenu.Single (Just "b")) (Select.toggleValue False (SelectMenu.Single (Just "a")) "b")
    , eq "select toggleValue single from null selects" (SelectMenu.Single (Just "a")) (Select.toggleValue False (SelectMenu.Single Nothing) "a")
    , eq "select toggleValue single re-select stays (no cancelable)" (SelectMenu.Single (Just "a")) (Select.toggleValue False (SelectMenu.Single (Just "a")) "a")
    , eq "select toggleValue single ignores a Multiple current" (SelectMenu.Single (Just "k")) (Select.toggleValue False (SelectMenu.Multiple [ "a" ]) "k")

    -- select: filterOptions (trim + case-insensitive substring; label then value)
    , eq "select filterOptions: empty pattern is identity" (smShape selFilterOpts) (smShape (Select.filterOptions "" selFilterOpts))
    , eq "select filterOptions: whitespace-only pattern is identity (trim)" (smShape selFilterOpts) (smShape (Select.filterOptions "   " selFilterOpts))
    , eq "select filterOptions: case-insensitive substring on the label" [ "opt:drive" ] (smShape (Select.filterOptions "DRIV" selFilterOpts))
    , eq "select filterOptions: trimmed pattern still matches" [ "opt:drive" ] (smShape (Select.filterOptions "  drive  " selFilterOpts))
    , eq "select filterOptions: falls back to the value when the label misses" [ "opt:aliased" ] (smShape (Select.filterOptions "alias" [ smLeaf "aliased" "A", smLeaf "x" "X" ]))
    , eq "select filterOptions: no match -> []" [] (smShape (Select.filterOptions "zzz" selFilterOpts))
    , eq "select filterOptions: group children filtered, group kept when non-empty" [ "group:G[opt:alpha]" ] (smShape (Select.filterOptions "alpha" [ SelectMenu.Group { label = "G", children = [ smLeaf "alpha" "Alpha", smLeaf "beta" "Beta" ], attributes = [] } ]))
    , eq "select filterOptions: group dropped when its children all miss" [] (smShape (Select.filterOptions "zzz" [ SelectMenu.Group { label = "G", children = [ smLeaf "alpha" "Alpha" ], attributes = [] } ]))
    , eq "select filterOptions: nested groups recursed, inner dropped when empty" [ "group:Outer[opt:alpha]" ] (smShape (Select.filterOptions "alpha" [ SelectMenu.Group { label = "Outer", children = [ smLeaf "alpha" "Alpha", SelectMenu.Group { label = "Inner", children = [ smLeaf "beta" "Beta" ], attributes = [] } ], attributes = [] } ]))
    , eq "select filterOptions: Custom rows pass through while leaves filter out" [ "custom:c" ] (smShape (Select.filterOptions "zzz" [ SelectMenu.Custom { key = "c", node = Element.text "x" }, smLeaf "alpha" "Alpha" ]))

    -- select: menuVars (23 menu vars + Select's own --n-menu-box-shadow) ----
    , eq "select menuVars: 24 keys (light medium)" 24 (List.length (Select.menuVars light Select.Medium))
    , eq "select menuVars: first 23 == the SelectMenu var block (order)" expectedSelectMenuVarsMedium (List.take 23 (Select.menuVars light Select.Medium))
    , eq "select menuVars: slot 24 --n-menu-box-shadow (LAST)" (Just ( "--n-menu-box-shadow", popselectShadow )) (listAt 23 (Select.menuVars light Select.Medium))
    , eq "select menuVars: last key --n-menu-box-shadow" (Just "--n-menu-box-shadow") (List.reverse (Select.menuVars light Select.Medium) |> List.head |> Maybe.map Tuple.first)
    , eq "select menuVars: --n-menu-box-shadow = SelectTheme.menuBoxShadow" (Just (SelectTheme.vars light).menuBoxShadow) (lookup "--n-menu-box-shadow" (Select.menuVars light Select.Medium))
    , eq "select menuVars: non-empty (stub differential: [] vs 24)" True (not (List.isEmpty (Select.menuVars light Select.Medium)))
    , eq "select menuVars: size switch small -> --n-option-height 28px" (Just "28px") (lookup "--n-option-height" (Select.menuVars light Select.Small))

    -- autocomplete: menuVars (23 menu vars + AutoComplete's own --n-menu-box-shadow) ----
    , eq "autocomplete menuVars: 24 keys (light)" 24 (List.length (AutoComplete.menuVars light))
    , eq "autocomplete menuVars: exact 24-list light (name+value, order)" expectedAutoCompleteMenuVars (AutoComplete.menuVars light)
    , eq "autocomplete menuVars: first 23 == the SelectMenu var block (order)" expectedSelectMenuVarsMedium (List.take 23 (AutoComplete.menuVars light))
    , eq "autocomplete menuVars: slot 24 --n-menu-box-shadow (LAST)" (Just ( "--n-menu-box-shadow", popselectShadow )) (listAt 23 (AutoComplete.menuVars light))
    , eq "autocomplete menuVars: last key --n-menu-box-shadow" (Just "--n-menu-box-shadow") (List.reverse (AutoComplete.menuVars light) |> List.head |> Maybe.map Tuple.first)
    , eq "autocomplete menuVars: --n-menu-box-shadow = AutoCompleteTheme.menuBoxShadow" (Just (AutoCompleteTheme.vars light).menuBoxShadow) (lookup "--n-menu-box-shadow" (AutoComplete.menuVars light))
    , eq "autocomplete menuVars: non-empty (stub differential: [] vs 24)" True (not (List.isEmpty (AutoComplete.menuVars light)))

    -- mention: menuVars (23 menu vars + Mention's own --n-menu-box-shadow) ----
    , eq "mention menuVars: 24 keys (light)" 24 (List.length (Mention.menuVars light))
    , eq "mention menuVars: exact 24-list light (name+value, order)" expectedMentionMenuVars (Mention.menuVars light)
    , eq "mention menuVars: first 23 == the SelectMenu var block (order)" expectedSelectMenuVarsMedium (List.take 23 (Mention.menuVars light))
    , eq "mention menuVars: slot 24 --n-menu-box-shadow (LAST)" (Just ( "--n-menu-box-shadow", popselectShadow )) (listAt 23 (Mention.menuVars light))
    , eq "mention menuVars: last key --n-menu-box-shadow" (Just "--n-menu-box-shadow") (List.reverse (Mention.menuVars light) |> List.head |> Maybe.map Tuple.first)
    , eq "mention menuVars: --n-menu-box-shadow = MentionTheme.menuBoxShadow" (Just (MentionTheme.vars light).menuBoxShadow) (lookup "--n-menu-box-shadow" (Mention.menuVars light))
    , eq "mention menuVars: non-empty (stub differential: [] vs 24)" True (not (List.isEmpty (Mention.menuVars light)))

    -- mention: frozen defaults (real in the stub; they guard the contract) ----
    , eq "mention defaults: placeholder == \"\" (NOT the AC baked 'Please Input')" "" mnD.placeholder
    , eq "mention defaults: type_ == Text" Mention.Text mnD.type_
    , eq "mention defaults: autosize == False" False mnD.autosize
    , eq "mention defaults: bordered == True" True mnD.bordered
    , eq "mention menuDefaults: loading == False" False mnMenuD.loading

    -- tree: treemate ground truth (the same real-treemate pins as the
    -- cascader batch — the stub returns the inputs unchanged, so every
    -- normalization / walk pin below is RED by construction) ------------
    , eq "tree defaults: checkStrategy == All" Tree.All Tree.defaults.checkStrategy
    , eq "tree defaults: checkboxPlacement == Left" Tree.Left Tree.defaults.checkboxPlacement
    , eq "tree defaults: indent == 24" 24 Tree.defaults.indent
    , eq "tree defaults: checkable == False" False Tree.defaults.checkable
    , eq "tree defaults: cascade == False" False Tree.defaults.cascade
    , eq "tree defaults: selectable == True" True Tree.defaults.selectable
    , eq "tree defaults: showLine == False" False Tree.defaults.showLine
    , eq "tree defaults: rtl == False" False Tree.defaults.rtl
    , eq "tree gck all [a1]: the leaf + its indeterminate parent" { checkedKeys = [ "a1" ], indeterminateKeys = [ "a" ] } (Tree.getCheckedKeys True Tree.All False [ "a1" ] treeFixture)
    , eq "tree gck all [a2y]: a disabled sibling counts full, a2 checked" { checkedKeys = [ "a2y", "a2" ], indeterminateKeys = [ "a" ] } (Tree.getCheckedKeys True Tree.All False [ "a2y" ] treeFixture)
    , eq "tree gck parent [a1,a2y,a3]: collapses to the topmost" { checkedKeys = [ "a" ], indeterminateKeys = [] } (Tree.getCheckedKeys True Tree.Parent False [ "a1", "a2y", "a3" ] treeFixture)
    , eq "tree gck child [a]: leaves only, the empty branch a3 drops" { checkedKeys = [ "a1", "a2y" ], indeterminateKeys = [ "a" ] } (Tree.getCheckedKeys True Tree.Child False [ "a" ] treeFixture)
    , eq "tree gck all [b1]: a disabled parent is never indeterminate" { checkedKeys = [ "b1" ], indeterminateKeys = [] } (Tree.getCheckedKeys True Tree.All False [ "b1" ] treeFixture)
    , eq "tree gck no-cascade [a1,a2y]: passthrough, nothing indeterminate" { checkedKeys = [ "a1", "a2y" ], indeterminateKeys = [] } (Tree.getCheckedKeys False Tree.All False [ "a1", "a2y" ] treeFixture)
    , eq "tree gck all [zz]: an unknown key stays" { checkedKeys = [ "zz" ], indeterminateKeys = [] } (Tree.getCheckedKeys True Tree.All False [ "zz" ] treeFixture)
    , eq "tree check a <- [c]: the subtree joins, DFS order, disabled leaf blocked" [ "c", "a", "a1", "a2", "a2y", "a3" ] (Tree.check True Tree.All False "a" [ "c" ] treeFixture)
    , eq "tree check a2x <- [c]: a disabled key itself stays" [ "c", "a2x" ] (Tree.check True Tree.All False "a2x" [ "c" ] treeFixture)
    , eq "tree uncheck a1: the key's subtree leaves, parent indeterminate" [ "a2y", "a3", "a2" ] (Tree.uncheck True Tree.All False "a1" [ "a1", "a2y", "a3", "a" ] treeFixture)
    , eq "tree uncheck a (child): the whole value empties" [] (Tree.uncheck True Tree.Child False "a" [ "a", "a1", "a2", "a2y", "a3" ] treeFixture)
    , eq "tree flatten [] collapsed: roots only, document order, level 0" [ "a", "b", "c" ] (treeFlatKeys (Tree.flatten [] treeFixture))
    , eq "tree flatten [a]: the branch's children join at level 1" [ "a", "a1", "a2", "a3", "b", "c" ] (treeFlatKeys (Tree.flatten [ "a" ] treeFixture))
    , eq "tree flatten [a,a2]: nested leaves, a2x disabled travels" [ "a", "a1", "a2", "a2x", "a2y", "a3", "b", "c" ] (treeFlatKeys (Tree.flatten [ "a", "a2" ] treeFixture))
    , eq "tree flatten unknown key: ignored (children of nothing)" [ "a", "b", "c" ] (treeFlatKeys (Tree.flatten [ "zz" ] treeFixture))
    , eq "tree flatten depth: a1 is level 1, a2y is level 2" [ 1, 2 ] (List.map .level (List.filter (\n -> n.key == "a1" || n.key == "a2y") (Tree.flatten [ "a", "a2" ] treeFixture)))
    , eq "tree flatten last-child chain: a1 is not last (a2 follows), a2y is last (a2x precedes)" [ False, True ] (List.map .isLastChild (List.filter (\n -> n.key == "a1" || n.key == "a2y") (Tree.flatten [ "a", "a2" ] treeFixture)))
    , eq "tree getNonLeafKeys: every branch key, document order (loaded-empty a3 counts: real treemate output)" [ "a", "a2", "a3", "b" ] (Tree.getNonLeafKeys treeFixture)
    , eq "tree toggleExpand: a leaf key never joins the expanded set (Tree.tsx:1098 isLeaf guard)" [ "a" ] (Tree.toggleExpand False treeFixture "c" [ "a" ])
    , eq "tree toggleExpand: the key drops when present" [ "c" ] (Tree.toggleExpand False treeFixture "a" [ "a", "c" ])
    , eq "tree toggleExpand accordion: expanding b collapses the sibling a" [ "b" ] (Tree.toggleExpand True treeFixture "b" [ "a" ])
    , eq "tree toggleExpand unknown key: ignored (Tree.tsx:1098 getNode guard -> unchanged)" [ "a" ] (Tree.toggleExpand False treeFixture "zz" [ "a" ])
    , eq "tree toggleSelect single: replaces the set" [ "a2" ] (Tree.toggleSelect False False "a2" [ "a1" ])
    , eq "tree toggleSelect single cancelable: re-select clears" [] (Tree.toggleSelect False True "a1" [ "a1" ])
    , eq "tree toggleSelect single non-cancelable: re-select stays" [ "a1" ] (Tree.toggleSelect False False "a1" [ "a1" ])
    , eq "tree toggleSelect multiple: toggles membership" [ "a1", "a2" ] (Tree.toggleSelect True True "a2" [ "a1" ])
    , eq "tree toggleSelect multiple non-cancelable: append-only" [ "a1", "a2" ] (Tree.toggleSelect True False "a1" [ "a1", "a2" ] |> List.reverse |> List.reverse)

    -- Upstream filterTree ("A2" / "A2X" / "A2Y" all contain "a2"): matched
    -- leaves keep their origin node (a2x included), the branch above them is
    -- cloned with the built children, and both clone keys are expanded.
    , eq "tree filterTree 'a2': the branch above the match survives, the match highlights, the path expands"
        { tree = [ Tree.TreeOption { key = "a", label = "A", disabled = False, checkboxDisabled = False, isLeaf = False, children = Just [ Tree.TreeOption { key = "a2", label = "A2", disabled = False, checkboxDisabled = False, isLeaf = False, children = Just [ Tree.TreeOption { key = "a2x", label = "A2X", disabled = True, checkboxDisabled = False, isLeaf = True, children = Nothing, prefix = [], suffix = [] }, Tree.TreeOption { key = "a2y", label = "A2Y", disabled = False, checkboxDisabled = False, isLeaf = True, children = Nothing, prefix = [], suffix = [] } ], prefix = [], suffix = [] } ], prefix = [], suffix = [] } ]
        , highlightKeys = [ "a2", "a2x", "a2y" ]
        , expandedKeys = [ "a", "a2" ]
        }
        (Tree.filterTree "a2" treeFixture)
    , eq "tree filterTree empty pattern: the whole tree passes untouched" treeFixture (Tree.filterTree "" treeFixture).tree

    -- treemate mixed-order scan: unchecked child BEFORE a checked one still
    -- lands the parent in the indeterminate set (lib/check.js break rule)
    , eq "tree cascade scan: check 'c' after unchecked 'u' keeps the key" [ "c" ] (Tree.check True Tree.All False "c" [] mixedTree)
    , eq "tree cascade scan: the parent is indeterminate (checked child after an unchecked one)" [ "p" ] (Tree.getCheckedKeys True Tree.All False [ "c" ] mixedTree).indeterminateKeys

    -- non-cascade check runs through treemate's merge (Set semantics: dedupe)
    , eq "tree non-cascade check dedupes caller keys (treemate merge)" [ "k1", "k2" ] (Tree.check False Tree.All False "k2" [ "k1", "k1" ] mixedTree)

    -- the unloaded branch (isLeaf = False, children = Nothing): visible,
    -- non-leaf, spinner-able; cascade keeps its key under allowNotLoaded
    , eq "tree unloaded branch: flatten renders it" [ "x" ] (treeFlatKeys (Tree.flatten [] unloadedTree))
    , eq "tree unloaded branch: flatten marks isLeaf False" [ False ] (List.map .isLeaf (Tree.flatten [] unloadedTree))
    , eq "tree unloaded branch: getNonLeafKeys counts it (treemate !isLeaf)" [ "x" ] (Tree.getNonLeafKeys unloadedTree)
    , eq "tree filterTree no match: an empty pruned tree" [] (Tree.filterTree "zzz" treeFixture).tree
    , eq "tree cssVars: 17 keys (light)" 17 (List.length (Tree.cssVars light))
    , eq "tree cssVars: exact key order (upstream cssVarsRef)"
        [ "--n-arrow-color", "--n-loading-color", "--n-bezier", "--n-font-size", "--n-node-border-radius", "--n-node-color-active", "--n-node-color-hover", "--n-node-color-pressed", "--n-node-text-color", "--n-node-text-color-disabled", "--n-drop-mark-color", "--n-node-wrapper-padding", "--n-line-offset-top", "--n-line-offset-bottom", "--n-node-content-height", "--n-line-height", "--n-line-color" ]
        (varKeys (Tree.cssVars light))
    , eq "tree cssVars: --n-line-offset-top = the negated wrapper-padding top" (Just "-3px") (lookup "--n-line-offset-top" (Tree.cssVars light))

    -- seemly getPadding (= getMargin) case-2: "3px 0" → bottom = parts[0] = "3px"
    -- (standard CSS vertical/horizontal shorthand), NOT parts[1]
    -- (tools/node_modules/seemly/es/css/index.js getMargin).
    , eq "tree cssVars: --n-line-offset-bottom = the negated wrapper-padding bottom" (Just "-3px") (lookup "--n-line-offset-bottom" (Tree.cssVars light))
    , eq "tree cssVars: --n-node-content-height = nodeHeight - padding (30 - 3 - 3)" (Just "24px") (lookup "--n-node-content-height" (Tree.cssVars light))
    , eq "tree cssVars: --n-arrow-color = common.textColor3" (Just light.common.textColor3) (lookup "--n-arrow-color" (Tree.cssVars light))
    , eq "tree cssVars: --n-loading-color = common.primaryColor" (Just light.common.primaryColor) (lookup "--n-loading-color" (Tree.cssVars light))
    , eq "tree cssVars: --n-node-color-active = the theme self value" (Just (TreeTheme.vars light).nodeColorActive) (lookup "--n-node-color-active" (Tree.cssVars light))

    -- table: the static n-table (upstream Table.tsx tableProps defaults +
    -- cssVarsRef declaration order; the five tag wrappers are bare) --------
    , eq "table defaults: size == Medium" Table.Medium tblD.size
    , eq "table defaults: bordered == True" True tblD.bordered
    , eq "table defaults: bottomBordered == True" True tblD.bottomBordered
    , eq "table defaults: singleLine == True" True tblD.singleLine
    , eq "table defaults: singleColumn == False" False tblD.singleColumn
    , eq "table defaults: striped == False" False tblD.striped
    , eq "table defaults: rtl == False" False tblD.rtl
    , eq "table defaults: attributes empty" True (List.isEmpty tblD.attributes)
    , eq "table rowDefaults: cells empty" True (List.isEmpty Table.rowDefaults.cells)
    , eq "table rowDefaults: attributes empty" True (List.isEmpty Table.rowDefaults.attributes)
    , eq "table cellDefaults: content empty" True (List.isEmpty Table.cellDefaults.content)
    , eq "table cellDefaults: colspan Nothing" Nothing Table.cellDefaults.colspan
    , eq "table cellDefaults: rowspan Nothing" Nothing Table.cellDefaults.rowspan
    , eq "table cellDefaults: attributes empty" True (List.isEmpty Table.cellDefaults.attributes)
    , eq "table cssVars: 21 keys (light, default opts)" 21 (List.length (Table.cssVars light tblD))
    , eq "table cssVars: exact key order (upstream cssVarsRef)"
        [ "--n-bezier", "--n-td-color", "--n-td-color-modal", "--n-td-color-popover", "--n-td-text-color", "--n-border-color", "--n-border-color-modal", "--n-border-color-popover", "--n-border-radius", "--n-font-size", "--n-th-color", "--n-th-color-modal", "--n-th-color-popover", "--n-th-font-weight", "--n-th-text-color", "--n-line-height", "--n-td-padding", "--n-th-padding", "--n-td-color-striped", "--n-td-color-striped-modal", "--n-td-color-striped-popover" ]
        (varKeys (Table.cssVars light tblD))
    , eq "table cssVars: length == 21 for default opts (nothing dropped)" 21 (List.length (Table.cssVars light tblD))
    , eq "table cssVars: --n-td-color = common cardColor (#fff)" (Just "#fff") (tblVar light tblD "--n-td-color")
    , eq "table cssVars: --n-th-font-weight = common fontWeightStrong (500)" (Just "500") (tblVar light tblD "--n-th-font-weight")
    , eq "table cssVars: --n-bezier = common cubicBezierEaseInOut" (Just "cubic-bezier(.4, 0, .2, 1)") (tblVar light tblD "--n-bezier")
    , eq "table cssVars: --n-border-radius = common borderRadius (3px)" (Just "3px") (tblVar light tblD "--n-border-radius")
    , eq "table cssVars: --n-line-height = common lineHeight (1.6)" (Just "1.6") (tblVar light tblD "--n-line-height")
    , eq "table cssVars: --n-th-text-color = common textColor1" (Just "rgb(31, 34, 37)") (tblVar light tblD "--n-th-text-color")
    , eq "table cssVars: --n-td-text-color = common textColor2" (Just "rgb(51, 54, 57)") (tblVar light tblD "--n-td-text-color")
    , eq "table cssVars: --n-th-color = composite(cardColor, tableHeaderColor)" (Just "rgba(250, 250, 252, 1)") (tblVar light tblD "--n-th-color")
    , eq "table cssVars: --n-border-color = composite(cardColor, dividerColor)" (Just "rgba(239, 239, 245, 1)") (tblVar light tblD "--n-border-color")
    , eq "table cssVars: --n-td-color-striped = composite(cardColor, tableColorStriped)" (Just "rgba(250, 250, 252, 1)") (tblVar light tblD "--n-td-color-striped")
    , eq "table cssVars: medium font size (createKey fontSize medium)" (Just "14px") (tblVar light tblD "--n-font-size")
    , eq "table cssVars: small font size" (Just "14px") (tblVar light { tblD | size = Table.Small } "--n-font-size")
    , eq "table cssVars: large font size" (Just "15px") (tblVar light { tblD | size = Table.Large } "--n-font-size")
    , eq "table cssVars: medium td padding" (Just "12px") (tblVar light tblD "--n-td-padding")
    , eq "table cssVars: small td padding" (Just "6px") (tblVar light { tblD | size = Table.Small } "--n-td-padding")
    , eq "table cssVars: large td padding" (Just "12px") (tblVar light { tblD | size = Table.Large } "--n-td-padding")
    , eq "table cssVars: medium th padding" (Just "12px") (tblVar light tblD "--n-th-padding")
    , eq "table cssVars: small th padding" (Just "6px") (tblVar light { tblD | size = Table.Small } "--n-th-padding")
    , eq "table cssVars: large th padding" (Just "12px") (tblVar light { tblD | size = Table.Large } "--n-th-padding")

    -- watermark: the container/overlay pair + the pure-SVG tile (upstream
    -- Watermark.tsx watermarkProps defaults + render style-object order) --
    , eq "watermark defaults: debug == False" False wmD.debug
    , eq "watermark defaults: cross == False" False wmD.cross
    , eq "watermark defaults: fullscreen == False" False wmD.fullscreen
    , eq "watermark defaults: width == 32" 32 wmD.width
    , eq "watermark defaults: height == 32" 32 wmD.height
    , eq "watermark defaults: zIndex == 10" 10 wmD.zIndex
    , eq "watermark defaults: xGap == 0" 0 wmD.xGap
    , eq "watermark defaults: yGap == 0" 0 wmD.yGap
    , eq "watermark defaults: yOffset == 0" 0 wmD.yOffset
    , eq "watermark defaults: xOffset == 0" 0 wmD.xOffset
    , eq "watermark defaults: rotate == 0" 0 wmD.rotate
    , eq "watermark defaults: textAlign == Left" Watermark.Left wmD.textAlign
    , eq "watermark defaults: image == Nothing" Nothing wmD.image
    , eq "watermark defaults: imageOpacity == 1" 1 wmD.imageOpacity
    , eq "watermark defaults: imageWidth == Nothing" Nothing wmD.imageWidth
    , eq "watermark defaults: imageHeight == Nothing" Nothing wmD.imageHeight
    , eq "watermark defaults: content == Nothing" Nothing wmD.content
    , eq "watermark defaults: selectable == True" True wmD.selectable
    , eq "watermark defaults: fontSize == 14" 14 wmD.fontSize
    , eq "watermark defaults: fontFamily == Nothing" Nothing wmD.fontFamily
    , eq "watermark defaults: fontStyle == \"normal\"" "normal" wmD.fontStyle
    , eq "watermark defaults: fontVariant == \"\"" "" wmD.fontVariant
    , eq "watermark defaults: fontWeight == 400" 400 wmD.fontWeight
    , eq "watermark defaults: fontColor == \"rgba(128, 128, 128, .3)\"" "rgba(128, 128, 128, .3)" wmD.fontColor
    , eq "watermark defaults: fontStretch == \"\"" "" wmD.fontStretch
    , eq "watermark defaults: lineHeight == 14" 14 wmD.lineHeight
    , eq "watermark defaults: globalRotate == 0" 0 wmD.globalRotate
    , eq "watermark defaults: attributes empty" True (List.isEmpty wmD.attributes)

    -- watermarkStyle: the overlay's inline declarations in upstream's
    -- style-object order (transform, zIndex, backgroundSize,
    -- backgroundPosition, backgroundImage)
    , eq "watermarkStyle default: pair order + values (z-index, background-size, empty position, background-image)"
        [ ( "z-index", "10" ), ( "background-size", "32px" ), ( "background-position", "" ), ( "background-image", "url(" ++ Watermark.tileDataUrl light wmD ++ ")" ) ]
        (Watermark.watermarkStyle light wmD)
    , eq "watermarkStyle cross unrotated: background-position = width/2 height/2, 0 0 (odd halves)"
        [ ( "z-index", "10" ), ( "background-size", "8px" ), ( "background-position", "2.5px 2.5px, 0 0" ), ( "background-image", "url(" ++ Watermark.tileDataUrl light crossOpts ++ "), url(" ++ Watermark.tileDataUrl light crossOpts ++ ")" ) ]
        (Watermark.watermarkStyle light crossOpts)
    , eq "watermarkStyle globalRotate alone: transform first, zIndex kept, max(142vh,142vw) cross pair"
        [ ( "transform", "translateX(-50%) translateY(-50%) rotate(45deg)" ), ( "z-index", "10" ), ( "background-size", "32px" ), ( "background-position", "calc(max(142vh, 142vw) + 16px) calc(max(142vh, 142vw) + 16px), max(142vh, 142vw) max(142vh, 142vw)" ), ( "background-image", "url(" ++ Watermark.tileDataUrl light globalOpts ++ "), url(" ++ Watermark.tileDataUrl light globalOpts ++ ")" ) ]
        (Watermark.watermarkStyle light globalOpts)
    , eq "watermarkStyle fullscreen+globalRotate: zIndex handoff — overlay drops z-index, keeps transform"
        [ ( "transform", "translateX(-50%) translateY(-50%) rotate(30deg)" ), ( "background-size", "32px" ), ( "background-position", "max(142vh, 142vw)" ), ( "background-image", "url(" ++ Watermark.tileDataUrl light handoffOpts ++ ")" ) ]
        (Watermark.watermarkStyle light handoffOpts)
    , eq "watermarkStyle image path: url(src) with cross doubling"
        [ ( "z-index", "10" ), ( "background-size", "32px" ), ( "background-position", "16px 16px, 0 0" ), ( "background-image", "url(pic.png), url(pic.png)" ) ]
        (Watermark.watermarkStyle light imageOpts)
    , eq "watermarkStyle empty background-position drops out of the rendered style string"
        True
        (String.startsWith "z-index:10;background-size:32px;background-image:url(data:image/svg+xml;base64," (wmStyleStr light wmD))

    -- containerStyle: just the zIndex handoff
    , eq "containerStyle default: empty" [] (Watermark.containerStyle wmD)
    , eq "containerStyle fullscreen+globalRotate: z-index moves to the container" [ ( "z-index", "7" ) ] (Watermark.containerStyle handoffOpts)
    , eq "containerStyle globalRotate alone: empty (overlay keeps z-index)" [] (Watermark.containerStyle globalOpts)

    -- tileDataUrl: deterministic SVG + base64 round-trip + structure
    , eq "tileDataUrl default: prefix is data:image/svg+xml;base64,"
        True
        (String.startsWith "data:image/svg+xml;base64," (Watermark.tileDataUrl light wmD))
    , eq "tileDataUrl default (no content): blank tile, no <text>, dimensions (xGap+width)×(yGap+height)"
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "rgba(128, 128, 128, .3)", fontFamily = (WatermarkTheme.vars light).fontFamily, fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Nothing, debug = False }
        )
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "rgba(128, 128, 128, .3)", fontFamily = (WatermarkTheme.vars light).fontFamily, fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "", debug = False }
        )
    , eq "tileDataUrl content \"a\\nb\" (crossOpts): one <text> per line, y = yOffset + lineHeight*(i+1), D1 fractional Center anchor (width/2 = 2.5)"
        (wmExpectedSvg
            { width = 5, height = 5, xGap = 3, yGap = 2, xOffset = 1, yOffset = 1, rotate = 15, fontSize = 10, fontColor = "red", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 2, textAlign = Watermark.Center, content = Just "a\nb", debug = False }
        )
        (wmExpectedSvg
            { width = 5, height = 5, xGap = 3, yGap = 2, xOffset = 1, yOffset = 1, rotate = 15, fontSize = 10, fontColor = "red", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 2, textAlign = Watermark.Center, content = Just "a\nb", debug = False }
        )
    , eq "tileDataUrl Right anchor: text-anchor=end at xOffset+width"
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Right, content = Just "x", debug = False }
        )
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Right, content = Just "x", debug = False }
        )
    , eq "tileDataUrl debug: grey rect outside the rotate group, green rect inside (D2: grey only with content)"
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "x", debug = True }
        )
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "x", debug = True }
        )
    , eq "tileDataUrl debug + empty content (D2): NO grey rect (upstream clearRect wipes it)"
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Nothing, debug = True }
        )
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Nothing, debug = True }
        )
    , eq "tileDataUrl escapeXml: &<>\"' content escapes to &amp;&lt;&gt;&quot;&apos;"
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "&<>\"'", debug = False }
        )
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "&<>\"'", debug = False }
        )
    , eq "tileDataUrl font stack: style/variant/stretch omitted at default, fontFamily falls back to the theme var"
        True
        (String.contains ("font-family=\"" ++ wmEscapeXml (WatermarkTheme.vars light).fontFamily ++ "\"")
            (wmExpectedSvg
                { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = (WatermarkTheme.vars light).fontFamily, fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Nothing, debug = False }
            )
            && not
                (String.contains "font-style="
                    (wmExpectedSvg
                        { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = (WatermarkTheme.vars light).fontFamily, fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Nothing, debug = False }
                    )
                )
        )
    , eq "tileDataUrl S1: font-weight 700 renders when fontWeight ≠ 400, omitted at 400"
        True
        (String.contains "font-weight=\"700\""
            (wmExpectedSvg
                { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 700, lineHeight = 14, textAlign = Watermark.Left, content = Just "x", debug = False }
            )
            && not
                (String.contains "font-weight="
                    (wmExpectedSvg
                        { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = "F", fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "x", debug = False }
                    )
                )
        )
    , eq "tileDataUrl D3: fontFamily = Just \"\" falls back to the theme var (upstream `||`)"
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = (WatermarkTheme.vars light).fontFamily, fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Nothing, debug = False }
        )
        (wmExpectedSvg
            { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = 0, fontSize = 14, fontColor = "c", fontFamily = (WatermarkTheme.vars light).fontFamily, fontStyle = "normal", fontVariant = "", fontStretch = "", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Nothing, debug = False }
        )
    , eq "tileDataUrl font stack: non-default style/variant/stretch DO render"
        True
        (String.contains "font-style=\"italic\""
            (wmExpectedSvg
                { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = -20, fontSize = 18, fontColor = "green", fontFamily = "F", fontStyle = "italic", fontVariant = "small-caps", fontStretch = "condensed", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "Seemly", debug = False }
            )
            && String.contains "font-variant=\"small-caps\""
                (wmExpectedSvg
                    { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = -20, fontSize = 18, fontColor = "green", fontFamily = "F", fontStyle = "italic", fontVariant = "small-caps", fontStretch = "condensed", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "Seemly", debug = False }
                )
            && String.contains "font-stretch=\"condensed\""
                (wmExpectedSvg
                    { width = 32, height = 32, xGap = 0, yGap = 0, xOffset = 0, yOffset = 0, rotate = -20, fontSize = 18, fontColor = "green", fontFamily = "F", fontStyle = "italic", fontVariant = "small-caps", fontStretch = "condensed", fontWeight = 400, lineHeight = 14, textAlign = Watermark.Left, content = Just "Seemly", debug = False }
                )
        )

    -- menu: treemate keyPath semantics through groups (getPath().keyPath
    -- includes group keys — groups are tree nodes) --
    , eq "menu keyPathTo descends submenu > group > submenu to the leaf"
        (Just [ "sub-1", "sub-1-g", "grp-sub", "grp-sub-leaf" ])
        (Menu.keyPathTo "grp-sub-leaf" menuTree)
    , eq "menu keyPathTo miss -> Nothing"
        Nothing
        (Menu.keyPathTo "nope" menuTree)

    -- toggleExpand (Menu.tsx): close filters; open appends; accordion closes
    -- the FIRST open level-1 sibling only --
    , eq "menu toggleExpanded close removes the key"
        [ "sub-2" ]
        (Menu.toggleExpanded False menuTree [ "sub-1", "sub-2" ] "sub-1")
    , eq "menu toggleExpanded open appends (non-accordion)"
        [ "sub-1", "sub-2" ]
        (Menu.toggleExpanded False menuTree [ "sub-1" ] "sub-2")
    , eq "menu toggleExpanded accordion closes the first open level-1 sibling, deeper keys stay"
        [ "sub-1-g", "sub-2" ]
        (Menu.toggleExpanded True menuTree [ "sub-1", "sub-1-g" ] "sub-2")
    , eq "menu toggleExpanded accordion leaves level-2 opens alone"
        [ "sub-1", "grp-sub" ]
        (Menu.toggleExpanded True menuTree [ "sub-1" ] "grp-sub")

    -- showOption (expandTo): includeSelf:false path + accordion level-1
    -- pruning --
    , eq "menu expandTo expands the ancestor path (self excluded)"
        [ "sub-1", "sub-1-g", "grp-sub" ]
        (Menu.expandTo False menuTree "grp-sub-leaf" [])
    , eq "menu expandTo accordion closes level-1 keys off the path"
        [ "sub-1", "sub-1-g", "grp-sub" ]
        (Menu.expandTo True menuTree "grp-sub-leaf" [ "sub-2" ])
    , eq "menu expandTo unknown key leaves the state alone"
        [ "sub-1" ]
        (Menu.expandTo True menuTree "nope" [ "sub-1" ])

    -- uncontrolled init: defaultExpandAll = non-leaf keys (groups count,
    -- dividers never; empty children lists are leaves) --
    , eq "menu initialExpandedKeys expandAll = every non-leaf key in walk order"
        [ "sub-1", "sub-1-g", "grp-sub", "sub-2", "top-g" ]
        (Menu.initialExpandedKeys True Nothing menuTree)
    , eq "menu initialExpandedKeys value path"
        [ "sub-1", "sub-1-g" ]
        (Menu.initialExpandedKeys False (Just "grp-leaf") menuTree)

    -- rawNodes → NDropdown options (the popover seam mapping; extra has no
    -- dropdown counterpart and is dropped) --
    , eq "menu submenuDropdownOptions maps leaf/submenu/group/divider"
        [ "leaf:root-leaf", "divider", "submenu:sub-1", "submenu:sub-2", "group:top-g" ]
        (List.map dropdownKind (Menu.submenuDropdownOptions menuTree))

    -- the 43-var cssVars block (Menu.tsx cssVarsRef declaration order) --
    , eq "menu cssVars names in upstream declaration order (43)"
        "--n-divider-color|--n-bezier|--n-font-size|--n-border-color-horizontal|--n-border-radius|--n-item-height|--n-group-text-color|--n-color|--n-item-text-color|--n-item-text-color-hover|--n-item-text-color-active|--n-item-text-color-child-active|--n-item-text-color-child-active-hover|--n-item-text-color-active-hover|--n-item-icon-color|--n-item-icon-color-hover|--n-item-icon-color-active|--n-item-icon-color-active-hover|--n-item-icon-color-child-active|--n-item-icon-color-child-active-hover|--n-item-icon-color-collapsed|--n-item-text-color-horizontal|--n-item-text-color-hover-horizontal|--n-item-text-color-active-horizontal|--n-item-text-color-child-active-horizontal|--n-item-text-color-child-active-hover-horizontal|--n-item-text-color-active-hover-horizontal|--n-item-icon-color-horizontal|--n-item-icon-color-hover-horizontal|--n-item-icon-color-active-horizontal|--n-item-icon-color-active-hover-horizontal|--n-item-icon-color-child-active-horizontal|--n-item-icon-color-child-active-hover-horizontal|--n-arrow-color|--n-arrow-color-hover|--n-arrow-color-active|--n-arrow-color-active-hover|--n-arrow-color-child-active|--n-arrow-color-child-active-hover|--n-item-color-hover|--n-item-color-active|--n-item-color-active-hover|--n-item-color-active-collapsed"
        (List.map Tuple.first (Menu.cssVars Theme.default False)
            |> String.join "|"
        )
    , eq "menu cssVars inverted keeps the exact same names in order"
        (List.map Tuple.first (Menu.cssVars Theme.default False))
        (List.map Tuple.first (Menu.cssVars Theme.default True))
    , eq "menu cssVars item-height 42px / font-size 14px (light self + fontBodyMedium)"
        [ "42px", "14px" ]
        [ menuVarValue "--n-item-height" (Menu.cssVars Theme.default False)
        , menuVarValue "--n-font-size" (Menu.cssVars Theme.default False)
        ]
    , eq "menu cssVars item-color-active normal = changeColor(primary, .1) literal"
        "rgba(24, 160, 88, 0.1)"
        (menuVarValue "--n-item-color-active" (Menu.cssVars Theme.default False))
    , eq "menu cssVars item-color-active inverted = primary"
        "#18a058"
        (menuVarValue "--n-item-color-active" (Menu.cssVars Theme.default True))

    -- slider: getClosestMark semantics (strictly-closer, first wins ties,
    -- index into the passed list — upstream reuses it for handle picking) --
    , eq "slider closestMark picks the strictly-closest candidate"
        (Just { index = 0, distance = 6, value = 34 })
        (Slider.closestMark [ 34, 75 ] 40)
    , eq "slider closestMark tie -> the FIRST candidate wins"
        (Just { index = 0, distance = 10, value = 10 })
        (Slider.closestMark [ 10, 30 ] 20)
    , eq "slider closestMark miss -> Nothing"
        Nothing
        (Slider.closestMark [] 40)

    -- valueToPercentage / pointerToValue (getPointValue: no clamp — sanitize owns it) --
    , eq "slider valueToPercentage (min 1 max 101 value 24 = 23)"
        23
        (Slider.valueToPercentage 1 101 24)
    , eq "slider pointerToValue horizontal (clientX 25 on a 100px rail)"
        25
        (Slider.pointerToValue { vertical = False, reverse = False, min = 0, max = 100, railStart = 0, railSize = 100, pointer = 25 })
    , eq "slider pointerToValue vertical (bottom-origin, (bottom − clientY)/height)"
        77
        (Slider.pointerToValue { vertical = True, reverse = False, min = 0, max = 100, railStart = 100, railSize = 100, pointer = 23 })
    , eq "slider pointerToValue reverse flips the percentage"
        75
        (Slider.pointerToValue { vertical = False, reverse = True, min = 0, max = 100, railStart = 0, railSize = 100, pointer = 25 })

    -- sanitizeValue: 'mark' snap (the current value is a candidate), buffer direction --
    , eq "slider sanitize step:'mark' — closest of [34, 75, current 50] to 40 = 34 (dist 6)"
        34
        (Slider.sanitizeValue { step = Slider.StepMarks, min = 0, max = 100, markValues = [ 34, 75 ] } 40 50 Nothing)
    , eq "slider sanitize step:'mark' + upward buffer — 50 still beats 75 (dist 10 < 25 from target 40)"
        50
        (Slider.sanitizeValue { step = Slider.StepMarks, min = 0, max = 100, markValues = [ 34, 75 ] } 40 50 (Just 1))

    -- S1/S2 oracle round: the 'mark' and frozen branches return RAW — no
    -- clamp (out-of-range values survive verbatim; only numeric clamps) --
    , eq "slider sanitize step:'mark' returns the out-of-range mark RAW (no clamp)"
        120
        (Slider.sanitizeValue { step = Slider.StepMarks, min = 0, max = 100, markValues = [ 120 ] } 110 50 Nothing)
    , eq "slider sanitize frozen step returns the out-of-range current RAW (no clamp)"
        130
        (Slider.sanitizeValue { step = Slider.Step 0, min = 0, max = 100, markValues = [] } 80 130 Nothing)

    -- step <= 0 freezes (upstream quirk) --
    , eq "slider sanitize step<=0 freezes the current value"
        20
        (Slider.sanitizeValue { step = Slider.Step 0, min = 0, max = 100, markValues = [] } 80 20 Nothing)

    -- stepping grid: leftStep/rightStep floor semantics, marks appended --
    , eq "slider sanitize stepping grid (step 5 from 12 upward → 15)"
        15
        (Slider.sanitizeValue { step = Slider.Step 5, min = 0, max = 100, markValues = [] } 80 12 (Just 1))
    , eq "slider sanitize stepping lets a mark hijack the grid (34 nearer than 40)"
        34
        (Slider.sanitizeValue { step = Slider.Step 5, min = 0, max = 100, markValues = [ 34 ] } 80 33 (Just 1))

    -- non-stepping: roundValue vs marks, marks win ties, clamp at bounds --
    , eq "slider sanitize drag rounds to the step grid"
        40
        (Slider.sanitizeValue { step = Slider.Step 10, min = 0, max = 100, markValues = [] } 40 50 Nothing)
    , eq "slider sanitize drag: the nearer mark beats the rounded grid"
        34
        (Slider.sanitizeValue { step = Slider.Step 10, min = 0, max = 100, markValues = [ 34, 75 ] } 33 50 Nothing)
    , eq "slider sanitize clamps to max"
        100
        (Slider.sanitizeValue { step = Slider.Step 50, min = 0, max = 100, markValues = [] } 95 10 Nothing)

    -- stepValue (arrow keys): grid step, mark step, frozen step --
    , eq "slider stepValue +1 from 40 → 41"
        41
        (Slider.stepValue { step = Slider.Step 1, min = 0, max = 100, markValues = [] } 40 1)
    , eq "slider stepValue −1 from 40 → 39"
        39
        (Slider.stepValue { step = Slider.Step 1, min = 0, max = 100, markValues = [] } 40 -1)
    , eq "slider stepValue step:'mark' still moves (to the mark above)"
        75
        (Slider.stepValue { step = Slider.StepMarks, min = 0, max = 100, markValues = [ 34, 75 ] } 34 1)

    -- cssVars: the 25-name block in upstream order + spot values (light _common/self) --
    , eq "slider cssVars names in upstream emission order (25)"
        "--n-bezier|--n-dot-border|--n-dot-border-active|--n-dot-border-radius|--n-dot-box-shadow|--n-dot-color|--n-dot-color-modal|--n-dot-color-popover|--n-dot-height|--n-dot-width|--n-fill-color|--n-fill-color-hover|--n-font-size|--n-handle-box-shadow|--n-handle-box-shadow-active|--n-handle-box-shadow-focus|--n-handle-box-shadow-hover|--n-handle-color|--n-handle-size|--n-opacity-disabled|--n-rail-color|--n-rail-color-hover|--n-rail-height|--n-rail-width-vertical|--n-mark-font-size"
        (List.map Tuple.first sliderVars
            |> String.join "|"
        )
    , eq "slider cssVars spot sizes + primary fill (light _common + self)"
        [ "4px", "18px", "#FFF", "#18a058" ]
        [ sliderVarValue "--n-rail-height" sliderVars
        , sliderVarValue "--n-handle-size" sliderVars
        , sliderVarValue "--n-handle-color" sliderVars
        , sliderVarValue "--n-fill-color" sliderVars
        ]
    , eq "slider indicatorCssVars 5 names in order"
        "--n-font-size|--n-indicator-border-radius|--n-indicator-box-shadow|--n-indicator-color|--n-indicator-text-color"
        (List.map Tuple.first (Slider.indicatorCssVars Theme.default)
            |> String.join "|"
        )
    , eq "slider indicatorCssVars spot (color literal + radius)"
        [ "rgba(0, 0, 0, .85)", "3px" ]
        [ sliderVarValue "--n-indicator-color" (Slider.indicatorCssVars Theme.default)
        , sliderVarValue "--n-indicator-border-radius" (Slider.indicatorCssVars Theme.default)
        ]

    -- image: resolveSrc (the upstream render ternary — error→fallbackSrc,
    -- observer-gated lazy, native lazy, plain) --
    , eq "image resolveSrc plain → loadSrc"
        (Just "https://x/p.jpeg")
        (Image.resolveSrc { imageD | src = Just "https://x/p.jpeg" })
    , eq "image resolveSrc showError → fallbackSrc"
        (Just "https://x/fallback.svg")
        (Image.resolveSrc
            { imageD
                | src = Just "https://x/broken.jpeg"
                , fallbackSrc = Just "https://x/fallback.svg"
                , showError = True
            }
        )
    , eq "image resolveSrc showError without fallbackSrc → Nothing (attr omitted)"
        Nothing
        (Image.resolveSrc { imageD | src = Just "https://x/p.jpeg", showError = True })
    , eq "image resolveSrc lazy + observer + not started → Nothing"
        Nothing
        (Image.resolveSrc
            { imageD
                | src = Just "https://x/p.jpeg"
                , lazy = True
                , intersectionObserver = True
                , shouldStartLoading = False
            }
        )
    , eq "image resolveSrc lazy + observer + started → loadSrc"
        (Just "https://x/p.jpeg")
        (Image.resolveSrc
            { imageD
                | src = Just "https://x/p.jpeg"
                , lazy = True
                , intersectionObserver = True
                , shouldStartLoading = True
            }
        )
    , eq "image resolveSrc lazy native (no observer) → loadSrc (attr gates the fetch)"
        (Just "https://x/p.jpeg")
        (Image.resolveSrc { imageD | src = Just "https://x/p.jpeg", lazy = True })

    -- errorReplacesImg (showError && errorNode.length) / loadingValue --
    , eq "image errorReplacesImg: showError + slot → True"
        True
        (Image.errorReplacesImg { imageD | showError = True, error = Just (Element.text "Load failed") })
    , eq "image errorReplacesImg: showError without slot → False (img swaps to fallbackSrc)"
        False
        (Image.errorReplacesImg { imageD | showError = True })
    , eq "image errorReplacesImg: slot without showError → False"
        False
        (Image.errorReplacesImg { imageD | error = Just (Element.text "Load failed") })
    , eq "image loadingValue: lazy without observer → \"lazy\" (native lazy)"
        "lazy"
        (Image.loadingValue { imageD | lazy = True })
    , eq "image loadingValue: lazy WITH observer → \"eager\" (observer owns the gate)"
        "eager"
        (Image.loadingValue { imageD | lazy = True, intersectionObserver = True })
    , eq "image loadingValue: not lazy → \"eager\""
        "eager"
        (Image.loadingValue imageD)

    -- cssVars: the 5-name preview-container block in upstream order + spots --
    , eq "image cssVars names in upstream emission order (5)"
        "--n-bezier|--n-toolbar-icon-color|--n-toolbar-color|--n-toolbar-border-radius|--n-toolbar-box-shadow"
        (List.map Tuple.first imageVars
            |> String.join "|"
        )
    , eq "image cssVars spots (light: toolbar literals + common bezier)"
        [ "cubic-bezier(.4, 0, .2, 1)", "rgba(255, 255, 255, .9)", "rgba(0, 0, 0, .35)", "none", "24px" ]
        [ imageVarValue "--n-bezier" imageVars
        , imageVarValue "--n-toolbar-icon-color" imageVars
        , imageVarValue "--n-toolbar-color" imageVars
        , imageVarValue "--n-toolbar-box-shadow" imageVars
        , imageVarValue "--n-toolbar-border-radius" imageVars
        ]
    , eq "image cssVars dark: icon color derives from common.textColor2"
        "rgba(255, 255, 255, 0.82)"
        (imageVarValue "--n-toolbar-icon-color" imageDarkVars)

    -- image preview: zoom math (ImagePreview.tsx — guards, scaleRadix 1.5,
    -- BLEEDING 32, the ceil-log resize, the dblclick toggle that does NOT
    -- touch scaleExp) --
    , eq "preview zoomIn: exp+1 then min(maxScale, 1.5^exp)"
        { scale = 1.5, scaleExp = 1, offsetX = 0, offsetY = 0, rotate = 0 }
        (ImagePreview.zoomIn 4 previewZoom0)
    , eq "preview zoomIn chained: 1.5^2 = 2.25 under max 4"
        { scale = 2.25, scaleExp = 2, offsetX = 0, offsetY = 0, rotate = 0 }
        (ImagePreview.zoomIn 4 (ImagePreview.zoomIn 4 previewZoom0))
    , eq "preview zoomIn guard: scale >= maxScale leaves zoom untouched"
        previewZoom0
        (ImagePreview.zoomIn 1 previewZoom0)
    , eq "preview zoomOut: guard 1 > 0.5, exp-1, max(0.5, 1.5^-1)"
        { scale = 0.6666666666666666, scaleExp = -1, offsetX = 0, offsetY = 0, rotate = 0 }
        (ImagePreview.zoomOut previewZoom0)
    , eq "preview zoomOut floor: second step clamps at 0.5 (1.5^-2 = 0.444… loses)"
        { scale = 0.5, scaleExp = -2, offsetX = 0, offsetY = 0, rotate = 0 }
        (ImagePreview.zoomOut (ImagePreview.zoomOut previewZoom0))
    , eq "preview zoomOut guard: scale 0.5 is the floor, unchanged"
        { scale = 0.5, scaleExp = -2, offsetX = 0, offsetY = 0, rotate = 0 }
        (ImagePreview.zoomOut { scale = 0.5, scaleExp = -2, offsetX = 0, offsetY = 0, rotate = 0 })
    , eq "preview maxScale: max(3, h*2, w*2) with BLEEDING=32 (936/468=2, 1000/500=2)"
        4
        (ImagePreview.maxScale { naturalWidth = 1000, naturalHeight = 936, innerWidth = 532, innerHeight = 500 })
    , eq "preview maxScale: the 3-floor holds for fitting images"
        3
        (ImagePreview.maxScale { naturalWidth = 100, naturalHeight = 100, innerWidth = 800, innerHeight = 600 })
    , eq "preview originalSizeScale: fitting image → 1"
        1
        (ImagePreview.originalSizeScale { naturalWidth = 100, naturalHeight = 100, innerWidth = 800, innerHeight = 600 })
    , eq "preview originalSizeScale: overshoot takes the max ratio (1000/500=2 vs 500/1000=0.5)"
        2
        (ImagePreview.originalSizeScale { naturalWidth = 1000, naturalHeight = 500, innerWidth = 532, innerHeight = 1032 })
    , eq "preview resizeToOriginalSize: scale to target, exp = ceil(log_1.5 2) = 2, offsets zeroed"
        { scale = 2, scaleExp = 2, offsetX = 0, offsetY = 0, rotate = 0 }
        (ImagePreview.resizeToOriginalSize 2 previewZoom0)
    , eq "preview toggleOriginalSize (dblclick): scale → target with scaleExp untouched"
        { scale = 2, scaleExp = 0, offsetX = 0, offsetY = 0, rotate = 0 }
        (ImagePreview.toggleOriginalSize 2 previewZoom0)
    , eq "preview toggleOriginalSize: second dblclick returns to 1 (scale == target)"
        { scale = 1, scaleExp = 0, offsetX = 0, offsetY = 0, rotate = 0 }
        (ImagePreview.toggleOriginalSize 2 (ImagePreview.toggleOriginalSize 2 previewZoom0))
    , eq "preview switchReset: the prev/next reset (scale 1, exp 0, offsets 0, rotate 0)"
        previewZoom0
        (ImagePreview.switchReset { scale = 2.25, scaleExp = 2, offsetX = 30, offsetY = -12, rotate = 180 })
    , eq "preview rotate: +90 clockwise / -90 counterclockwise"
        ( 90, -90 )
        ( ImagePreview.rotateClockwise previewZoom0 |> .rotate
        , ImagePreview.rotateCounterclockwise previewZoom0 |> .rotate
        )

    -- transformStyle / imgStyle: the derivePreviewStyle bytes (raw floats,
    -- no toFixed; transition:none BEFORE the transform while dragging, AFTER
    -- it otherwise) --
    , eq "preview transformStyle: the exact transform fragment, raw floats"
        "transform-origin:center|transform:translateX(12.5px) translateY(-3px) rotate(90deg) scale(1.5)"
        (ImagePreview.transformStyle { scale = 1.5, scaleExp = 1, offsetX = 12.5, offsetY = -3, rotate = 90 }
            |> List.map (\( k, v ) -> k ++ ":" ++ v)
            |> String.join "|"
        )
    , eq "preview imgStyle resting: controlled prefix, cursor grab, transform (transition stays implicit)"
        "border: 8px solid white; cursor: grab; transform-origin: center; transform: translateX(0px) translateY(0px) rotate(0deg) scale(1);"
        (ImagePreview.imgStyle
            { dragging = False
            , transition = True
            , controlled = [ ( "border", "8px solid white" ) ]
            , zoom = previewZoom0
            }
            |> stylePairsString
        )
    , eq "preview imgStyle dragging: grabbing + transition:none BEFORE the transform"
        "cursor: grabbing; transition: none; transform-origin: center; transform: translateX(0px) translateY(0px) rotate(0deg) scale(1);"
        (ImagePreview.imgStyle
            { dragging = True
            , transition = True
            , controlled = []
            , zoom = previewZoom0
            }
            |> stylePairsString
        )
    , eq "preview imgStyle suppressed transition: transition:none AFTER the transform"
        "cursor: grab; transform-origin: center; transform: translateX(0px) translateY(0px) rotate(0deg) scale(1); transition: none;"
        (ImagePreview.imgStyle
            { dragging = False
            , transition = False
            , controlled = []
            , zoom = previewZoom0
            }
            |> stylePairsString
        )

    -- drag math: getMoveStrategy signs + the getDerivedOffset clamp --
    , eq "preview moveStrategy: positive deltas → Left/Top"
        { horizontal = ImagePreview.HorizontalLeft, vertical = ImagePreview.VerticalTop, deltaHorizontal = 60, deltaVertical = 40 }
        (let
            s =
                ImagePreview.moveStrategy { mouseDownClientX = 100, mouseDownClientY = 100, mouseUpClientX = 40, mouseUpClientY = 60 }
         in
         { horizontal = s.horizontal, vertical = s.vertical, deltaHorizontal = s.deltaHorizontal, deltaVertical = s.deltaVertical }
        )
    , eq "preview moveStrategy: negative deltas → Right/Bottom"
        { horizontal = ImagePreview.HorizontalRight, vertical = ImagePreview.VerticalBottom, deltaHorizontal = -60, deltaVertical = -40 }
        (let
            s =
                ImagePreview.moveStrategy { mouseDownClientX = 40, mouseDownClientY = 60, mouseUpClientX = 100, mouseUpClientY = 100 }
         in
         { horizontal = s.horizontal, vertical = s.vertical, deltaHorizontal = s.deltaHorizontal, deltaVertical = s.deltaVertical }
        )
    , eq "preview derivedOffset: image fits the viewport → 0/0"
        { offsetX = 0, offsetY = 0 }
        (ImagePreview.derivedOffset Nothing
            { rect = fitsRect
            , viewport = { width = 800, height = 600 }
            , start = { offsetX = 40, offsetY = 40 }
            }
        )
    , eq "preview derivedOffset: left/top edges visible → snap in (+half each axis)"
        { offsetX = 100, offsetY = 200 }
        (ImagePreview.derivedOffset Nothing
            { rect = { left = 10, top = 20, width = 1000, height = 1000, right = 1010, bottom = 1020 }
            , viewport = { width = 800, height = 600 }
            , start = { offsetX = 0, offsetY = 0 }
            }
        )
    , eq "preview derivedOffset: right/bottom edges visible → tuck in (−half each axis)"
        { offsetX = -100, offsetY = -200 }
        (ImagePreview.derivedOffset Nothing
            { rect = { left = -700, top = -500, width = 1000, height = 1000, right = 300, bottom = 500 }
            , viewport = { width = 800, height = 600 }
            , start = { offsetX = 0, offsetY = 0 }
            }
        )
    , eq "preview derivedOffset: overhang + Right/Top strategy → X min, Y falls to max (upstream keys min on verticalBottom)"
        { offsetX = 200, offsetY = 460 }
        (ImagePreview.derivedOffset
            (Just { deltaHorizontal = -250, deltaVertical = 40, horizontal = ImagePreview.HorizontalRight, vertical = ImagePreview.VerticalTop })
            { rect = overhangRect
            , viewport = { width = 800, height = 600 }
            , start = { offsetX = 500, offsetY = 500 }
            }
        )
    , eq "preview derivedOffset: overhang + Left/Bottom strategy → X max, Y min (Bottom hits the min branch)"
        { offsetX = 750, offsetY = 300 }
        (ImagePreview.derivedOffset
            (Just { deltaHorizontal = -250, deltaVertical = 40, horizontal = ImagePreview.HorizontalLeft, vertical = ImagePreview.VerticalBottom })
            { rect = overhangRect
            , viewport = { width = 800, height = 600 }
            , start = { offsetX = 500, offsetY = 500 }
            }
        )
    , eq "preview derivedOffset: no strategy → the undefined-destructure fallback (max −half, start)"
        { offsetX = 500, offsetY = 500 }
        (ImagePreview.derivedOffset Nothing
            { rect = overhangRect
            , viewport = { width = 800, height = 600 }
            , start = { offsetX = 500, offsetY = 500 }
            }
        )

    -- keyboard: the document keydown mapping (handleKeydown) --
    , eq "preview keyAction: Space prevent-only, ←/→ prev/next, ↑/↓ zoom, Escape close, miss"
        "space|prev|next|in|out|close|miss"
        (String.join "|"
            (List.map previewKeyName
                [ " ", "ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Escape", "a" ]
            )
        )

    -- group: the merged registry (p-keys win) + the wrap-around walk that
    -- skips falsy (empty) urls (upstream findNext/findPrev truthiness) --
    , eq "group urlMap: srcList wins with p-keys, registered entries ignored"
        [ ( "p0", "https://a/one.jpeg" ), ( "p1", "" ), ( "p2", "https://a/three.jpeg" ) ]
        (ImageGroup.urlMap { groupSkipped | registered = [ ( "r1", "https://x/reg.jpeg" ) ] })
    , eq "group urlMap: without srcList the registered (imageId, url) pairs stand verbatim"
        [ ( "r7", "u7" ), ( "r9", "" ) ]
        (ImageGroup.urlMap { groupD | registered = [ ( "r7", "u7" ), ( "r9", "" ) ] })
    , eq "group imageIds/currentId/currentUrl at current=0"
        ( [ "p0", "p1", "p2" ], Just "p0", Just "https://a/one.jpeg" )
        ( ImageGroup.imageIds groupSkipped
        , ImageGroup.currentId groupSkipped
        , ImageGroup.currentUrl groupSkipped
        )
    , eq "group currentUrl with a falsy entry reads Just \"\" (upstream map.get falsiness)"
        (Just "")
        (ImageGroup.currentUrl { groupD | registered = [ ( "r7", "u7" ), ( "r9", "" ) ], current = 1 })
    , eq "group nextIndex skips the empty p1 (findNext truthiness)"
        (Just 2)
        (ImageGroup.nextIndex groupSkipped)
    , eq "group prevIndex from 0 wraps to the tail"
        (Just 2)
        (ImageGroup.prevIndex groupSkipped)
    , eq "group nextIndex from the tail wraps to 0"
        (Just 0)
        (ImageGroup.nextIndex { groupSkipped | current = 2 })
    , eq "group prevIndex from 2 skips back over the empty p1 to 0"
        (Just 0)
        (ImageGroup.prevIndex { groupSkipped | current = 2 })
    , eq "group go: +1 → 2 (skip), then +1 → 0 (wrap), −1 from 2 → 0"
        ( 2, 0, 0 )
        ( ImageGroup.go 1 groupSkipped |> .current
        , ImageGroup.go 1 { groupSkipped | current = 2 } |> .current
        , ImageGroup.go -1 { groupSkipped | current = 2 } |> .current
        )
    , eq "group go with no truthy target leaves current unchanged"
        0
        (ImageGroup.go 1 { groupD | registered = [ ( "r7", "" ) ] } |> .current)
    , eq "group showImage: moves to the id, is idempotent there, refuses unknown ids"
        ( 2, 2, 0 )
        ( ImageGroup.showImage "p2" groupSkipped |> .current
        , ImageGroup.showImage "p2" (ImageGroup.showImage "p2" groupSkipped) |> .current
        , ImageGroup.showImage "pX" groupSkipped |> .current
        )
    , eq "group previewOptions: the preview is fed src=currentUrl, the seams pass through, no previewed-img context"
        { src = Just "https://a/three.jpeg", showToolbar = True, onPrev = Just NoOp, scale = 2, previewedImgStyle = [] }
        (let
            po =
                ImageGroup.previewOptions
                    { groupSkipped
                        | current = 2
                        , show = True
                        , onPrev = Just NoOp
                        , zoom = { previewZoom0 | scale = 2 }
                    }
         in
         { src = po.src
         , showToolbar = po.showToolbar
         , onPrev = po.onPrev
         , scale = po.zoom.scale
         , previewedImgStyle = po.previewedImgStyle
         }
        )

    -- cssVars: the preview delegates to the image batch's five-var list --
    , eq "preview cssVars = the image batch's five-var emission verbatim"
        imageVars
        previewVars

    -- ===================================================================
    -- Message / Notification — the first service-style ports. Upstream is an
    -- imperative provider (message.create() → MessageReactive); the port is a
    -- caller-owned `State` + pure `State -> State` transforms. Expectations
    -- derived from MessageProvider/NotificationProvider/Environment bytes and
    -- the upstream spec files, not from the port's output.
    -- ===================================================================
    -- message: create stamps the enter phase (upstream mounts its Transition
    -- with appear — the FIRST paint already carries the enter-from class) --
    , eq "message create stamps Just EnterFrom (upstream appear=true)"
        [ Just Internal.EnterFrom ]
        (Message.create "m1" { messageD | content = "Saved" } messageS
            |> .items
            |> List.map .phase
        )
    , eq "message create appends in order (the DOM order upstream renders)"
        [ "m1", "m2" ]
        (messageS
            |> Message.create "m1" { messageD | content = "one" }
            |> Message.create "m2" { messageD | content = "two" }
            |> .items
            |> List.map .key
        )
    , eq "message typed helpers stamp the kind AFTER the options (upstream create(content, { ...options, type: 'info' }))"
        Message.Info
        (Message.info "k" { messageD | kind = Message.Error } messageS
            |> .items
            |> List.reverse
            |> List.head
            |> Maybe.map .options
            |> Maybe.map .kind
            |> Maybe.withDefault Message.Default
        )

    -- message: max eviction — upstream `if (max && list.length >= max)
    -- shift()`: instant, no leave, NO callbacks on the evictee; count
    -- includes leaving items; exactly one drop per create; Just 0 (falsy) is
    -- unlimited --
    , eq "message max: exactly one instant head-drop per create, count includes leaving items"
        [ "m2", "m3", "m4" ]
        ({ messageS
            | max = Just 2
            , items =
                [ { messageI | key = "m1", phase = Just Internal.LeaveTo }
                , { messageI | key = "m2" }
                , { messageI | key = "m3" }
                ]
         }
            |> Message.create "m4" messageD
            |> .items
            |> List.map .key
        )
    , eq "message max = Just 0 is UNLIMITED (JS truthiness — no eviction ever)"
        3
        ({ messageS | max = Just 0 }
            |> Message.create "a" messageD
            |> Message.create "b" messageD
            |> Message.create "c" messageD
            |> .items
            |> List.length
        )

    -- message: destroy — upstream hide() on an already-hidden env is a true
    -- no-op; resetting the ladder would restart the collapse (byte-visible) --
    , eq "message destroy on an already-leaving item is a NO-OP (no ladder restart)"
        (Just Internal.LeaveTo)
        ({ messageS | items = [ { messageI | key = "m1", phase = Just Internal.LeaveTo } ] }
            |> Message.destroy "m1"
            |> .items
            |> List.head
            |> Maybe.map .phase
            |> Maybe.withDefault Nothing
        )
    , eq "message destroy on an idle item stamps LeaveFrom; unknown key is a no-op"
        ( [ Just Internal.LeaveFrom, Nothing ], [ "m1", "m2" ] )
        ({ messageS | items = [ { messageI | key = "m1" }, { messageI | key = "m2" } ] }
            |> Message.destroy "m1"
            |> Message.destroy "zz"
            |> (\s -> ( List.map .phase s.items, List.map .key s.items ))
        )
    , eq "message destroyAll: live items enter LeaveFrom, leaving ones keep their phase"
        [ Just Internal.LeaveFrom, Just Internal.LeaveFrom, Just Internal.LeaveTo ]
        ({ messageS
            | items =
                [ { messageI | key = "a" }
                , { messageI | key = "b", phase = Just Internal.EnterTo }
                , { messageI | key = "c", phase = Just Internal.LeaveTo }
                ]
         }
            |> Message.destroyAll
            |> .items
            |> List.map .phase
        )
    , eq "message remove splices by key (upstream onInternalAfterLeave → splice — what empties the container)"
        [ "m1", "m3" ]
        ({ messageS | items = List.map (\k -> { messageI | key = k }) [ "m1", "m2", "m3" ] }
            |> Message.remove "m2"
            |> .items
            |> List.map .key
        )

    -- message: the hide clock — upstream setHideTimeout guards `if
    -- (duration)`, so Just 0 stays never and does NOT fall back to the
    -- provider default --
    , eq "message effectiveDuration: Nothing → provider default (3000); Just 0 → never (the falsy check beats the fallback)"
        ( Just 3000, Just 0 )
        ( Message.effectiveDuration { messageD | duration = Nothing } { messageS | duration = 3000 }
        , Message.effectiveDuration { messageD | duration = Just 0 } { messageS | duration = 3000 }
        )
    , eq "message cssVars: the 27 wrapper vars (upstream Message.tsx cssVarsRef — same names for every kind, values kind-keyed)"
        27
        (List.length (Message.cssVarsFor Theme.default Message.Info))

    -- ===================================================================
    -- Notification — the message twin with byte-visible deltas.
    -- ===================================================================
    -- notification: max eviction DESTROYS (animated) the oldest LIVE item —
    -- upstream walks the head, skips keys in leavingKeySet, calls its
    -- destroy(); nothing is dropped instantly (the pure port always animates
    -- — upstream's instant splice is a not-yet-mounted ref race) --
    , eq "notification max: evicts the oldest live item ANIMATEDLY (LeaveFrom), new item still appended"
        ( [ "m1", "m2", "m3" ], [ Just Internal.LeaveFrom, Nothing, Just Internal.EnterFrom ] )
        ({ noteS
            | max = Just 2
            , items = [ { noteI | key = "m1" }, { noteI | key = "m2" } ]
         }
            |> Notification.create "m3" noteD
            |> (\s -> ( List.map .key s.items, List.map .phase s.items ))
        )

    -- notification: max counts only LIVE items (leavingKeySet subtracted;
    -- enter-phase items count — they are live) --
    , eq "notification max counts only live items (a leaving item does not count toward max)"
        [ "m1", "m2" ]
        ({ noteS
            | max = Just 1
            , items = [ { noteI | key = "m1", phase = Just Internal.LeaveTo } ]
         }
            |> Notification.create "m2" noteD
            |> .items
            |> List.map .key
        )
    , eq "notification destroy no-op on leaving; destroyAll leaves already-leaving phases alone"
        [ Just Internal.LeaveFrom, Just Internal.LeaveTo ]
        ({ noteS | items = [ { noteI | key = "a" }, { noteI | key = "b", phase = Just Internal.LeaveTo } ] }
            |> Notification.destroyAll
            |> .items
            |> List.map .phase
        )

    -- notification: NO provider duration (upstream notificationProviderProps
    -- has none) — Nothing means never; the State arg is template symmetry --
    , eq "notification effectiveDuration: the item's own duration ONLY — Nothing stays Nothing (no provider fallback)"
        ( Nothing, Just 0, Just 4500 )
        ( Notification.effectiveDuration noteD noteS
        , Notification.effectiveDuration { noteD | duration = Just 0 } noteS
        , Notification.effectiveDuration { noteD | duration = Just 4500 } noteS
        )

    -- notification: vars ride the wrapper AND n-notification;
    -- --n-icon-color only for typed kinds (no iconColorDefault upstream —
    -- Vue skips the undefined style) --
    , eq "notification cssVars: 30 vars for the default kind, 31 once typed (--n-icon-color appears)"
        ( 30, 31 )
        ( List.length (Notification.cssVarsFor Theme.default Notification.Default)
        , List.length (Notification.cssVarsFor Theme.default Notification.Info)
        )
    , eq "notification --n-icon-color per kind = the theme's typed iconColour (createKey('iconColor', type))"
        ( [], [ ( "--n-icon-color", Theme.default.common.infoColor ) ] )
        ( Notification.cssVarsFor Theme.default Notification.Default
            |> List.filter (\( k, _ ) -> k == "--n-icon-color")
        , Notification.cssVarsFor Theme.default Notification.Info
            |> List.filter (\( k, _ ) -> k == "--n-icon-color")
        )

    -- ===================================================================
    -- Dialog service — the provider half (NDialogProvider + environments).
    -- Upstream: a reactive dialogList; create appends keyed (internalAppear
    -- mounts through the transition); hide() -> show = false; after-leave
    -- splices by key. No clock, no max: a dialog lives until destroyed.
    -- ===================================================================
    , eq "dialog create appends keyed and stamps Just EnterFrom (upstream mounts with internalAppear)"
        [ Just Internal.EnterFrom ]
        (DialogProvider.create "d1" { dgD | content = Just (Element.text "Hi") } dgPS
            |> .items
            |> List.map .phase
        )
    , eq "dialog typed helper stamps kind AFTER the options (create({ ...options, type }))"
        ( [ T.Info ], [ T.Error ] )
        ( DialogProvider.info "d1" { dgD | kind = T.Error } dgPS
            |> .items
            |> List.map (.options >> .kind)
        , DialogProvider.error "d1" { dgD | kind = T.Success } dgPS
            |> .items
            |> List.map (.options >> .kind)
        )
    , eq "dialog destroy on a mid-leave item does not restart the ladder (upstream hide() on show = false is a no-op)"
        [ Just Internal.LeaveTo ]
        ({ dgPS | items = [ { dgPD | key = "d1", phase = Just Internal.LeaveTo } ] }
            |> DialogProvider.destroy "d1"
            |> .items
            |> List.map .phase
        )
    , eq "dialog destroyAll stamps the leave on every live item; already-leaving ones keep their phase"
        [ Just Internal.LeaveFrom, Just Internal.LeaveFrom ]
        (dgPS
            |> DialogProvider.create "d1" dgD
            |> DialogProvider.create "d2" dgD
            |> DialogProvider.destroy "d2"
            |> DialogProvider.destroyAll
            |> .items
            |> List.map .phase
        )
    , eq "dialog remove splices by key (upstream handleAfterLeave); an unknown key is a no-op"
        ( [ "d2" ], [ "d1", "d2" ] )
        ( dgPS
            |> DialogProvider.create "d1" dgD
            |> DialogProvider.create "d2" dgD
            |> DialogProvider.remove "d1"
            |> .items
            |> List.map .key
        , dgPS
            |> DialogProvider.create "d1" dgD
            |> DialogProvider.create "d2" dgD
            |> DialogProvider.remove "nope"
            |> .items
            |> List.map .key
        )
    , eq "dialog view: an empty queue renders no trees (upstream renders a Fragment of environments)"
        ( 0, 2 )
        ( DialogProvider.view Theme.default dgPS |> List.length
        , dgPS
            |> DialogProvider.create "d1" dgD
            |> DialogProvider.create "d2" dgD
            |> DialogProvider.view Theme.default
            |> List.length
        )
    , eq "dialog service kind keys the body --n-icon-color (upstream spec: info #2080f0, error #d03050)"
        ( [ ( "--n-icon-color", Theme.default.common.infoColor ) ]
        , [ ( "--n-icon-color", Theme.default.common.errorColor ) ]
        )
        ( case
            DialogProvider.info "d1" { dgD | kind = T.Error } dgPS
                |> .items
          of
            [ it ] ->
                Dialog.cssVars Theme.default it.options
                    |> List.filter (\( k, _ ) -> k == "--n-icon-color")

            _ ->
                []
        , case
            DialogProvider.error "d1" { dgD | kind = T.Success } dgPS
                |> .items
          of
            [ it ] ->
                Dialog.cssVars Theme.default it.options
                    |> List.filter (\( k, _ ) -> k == "--n-icon-color")

            _ ->
                []
        )

    -- Data table — batch-1 core static table. Pins derive from the
    -- upstream vitest snapshot (`size` block = the var ground truth) and
    -- the basic/border/empty spec blocks, NOT from the port's output.
    -- ===================================================================
    , eq "data-table cssVars: the full 47-pair Medium set in cssVarsRef byte order"
        expectedDataTableVarsMedium
        dtMediumVars
    , eq "data-table cssVars length is 47 (upstream cssVarsRef direct count)"
        47
        (List.length dtMediumVars)
    , eq "data-table cssVars: Small keys the 8px th/td paddings and the 14px font"
        [ ( "--n-font-size", "14px" ), ( "--n-th-padding", "8px" ), ( "--n-td-padding", "8px" ) ]
        (List.take 3 dtSmallVars)
    , eq "data-table cssVars: Large keys the 15px font (paddings stay 12px)"
        [ ( "--n-font-size", "15px" ), ( "--n-th-padding", "12px" ), ( "--n-td-padding", "12px" ) ]
        (List.take 3 dtLargeVars)
    , eq "data-table cssVars dark: border/shadow/striped literals from dark.ts, cssVarsRef order"
        [ ( "--n-border-color", "rgba(45, 45, 48, 1)" )
        , ( "--n-box-shadow-before", "inset -12px 0 8px -12px rgba(0, 0, 0, .36)" )
        , ( "--n-box-shadow-after", "inset 12px 0 8px -12px rgba(0, 0, 0, .36)" )
        , ( "--n-td-color-striped", "rgba(36, 36, 39, 1)" )
        ]
        (List.filter
            (\( k, _ ) ->
                List.member k
                    [ "--n-border-color", "--n-box-shadow-before", "--n-box-shadow-after", "--n-td-color-striped" ]
            )
            dtDarkVars
        )
    , eq "data-table defaults: bordered/singleLine/showHeader true; striped/singleColumn/rtl false (use-config.ts ?? true / interface.ts)"
        [ True, True, True, False, False, False ]
        [ DataTable.defaults.bordered
        , DataTable.defaults.singleLine
        , DataTable.defaults.showHeader
        , DataTable.defaults.striped
        , DataTable.defaults.singleColumn
        , DataTable.defaults.rtl
        ]

    -- Data table — batch-2 sort + pagination. Pins derive from the
    -- upstream spec bytes (DataTable.spec.tsx `multiple sorter` +
    -- `itemCount` blocks) and the use-sorter/use-table-data/utils
    -- source, NOT from the port's output.
    -- ===================================================================
    , eq "data-table nextSortOrder: the upstream click cycle false→descend→ascend→false (getNextOrderOf)"
        [ DataTable.Descend, DataTable.Ascend, DataTable.NoSort, DataTable.Descend ]
        [ DataTable.nextSortOrder DataTable.NoSort
        , DataTable.nextSortOrder DataTable.Descend
        , DataTable.nextSortOrder DataTable.Ascend
        , DataTable.nextSortOrder DataTable.NoSort
        ]
    , eq "data-table createNextSorter: sorterless column → Nothing (utils.ts `column.sorter === undefined → null`)"
        Nothing
        (DataTable.createNextSorter dtNameCol Nothing)
    , eq "data-table createNextSorter: no current state → fresh Descend (getNextOrderOf(false))"
        (Just ( "age", DataTable.Descend ))
        (DataTable.createNextSorter dtMsAgeCol Nothing
            |> Maybe.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table createNextSorter: same-key current → order advanced through the cycle (Ascend→NoSort)"
        (Just ( "age", DataTable.NoSort ))
        (DataTable.createNextSorter dtMsAgeCol
            (Just { columnKey = "age", order = DataTable.Ascend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) })
            |> Maybe.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table createNextSorter: foreign-key current → fresh Descend on the clicked column"
        (Just ( "chinese", DataTable.Descend ))
        (let
            chineseCol =
                msScoreCol "chinese" "Chinese Score" 3 .chinese
         in
         DataTable.createNextSorter chineseCol
            (Just { columnKey = "age", order = DataTable.Ascend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) })
            |> Maybe.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table deriveNextSorter: multi click keeps only the base's multi states and upserts at the key (use-sorter.ts getUpdatedSorterState)"
        [ ( "chinese", DataTable.Ascend ), ( "math", DataTable.Descend ) ]
        (DataTable.deriveNextSorter
            [ { columnKey = "chinese", order = DataTable.Ascend, sorter = DataTable.SorterMultiple 3 Nothing }
            , { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) }
            ]
            (Just { columnKey = "math", order = DataTable.Descend, sorter = DataTable.SorterMultiple 2 Nothing })
            |> List.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table deriveNextSorter: single click replaces the whole state with exactly [state]"
        [ ( "age", DataTable.Descend ) ]
        (DataTable.deriveNextSorter
            [ { columnKey = "chinese", order = DataTable.Ascend, sorter = DataTable.SorterMultiple 3 Nothing }
            , { columnKey = "math", order = DataTable.Descend, sorter = DataTable.SorterMultiple 2 Nothing }
            ]
            (Just { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) })
            |> List.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table deriveNextSorter: Nothing → [] (upstream null clears the sorter)"
        []
        (DataTable.deriveNextSorter
            [ { columnKey = "chinese", order = DataTable.Ascend, sorter = DataTable.SorterMultiple 3 Nothing } ]
            Nothing
            |> List.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table defaultSortStates: seeds every sortable column from defaultSortOrder (NoSort default, one Ascend), column order (use-sorter.ts defaultSortState)"
        [ ( "age", DataTable.NoSort ), ( "chinese", DataTable.Ascend ), ( "math", DataTable.NoSort ) ]
        (let
            chineseAscend =
                msScoreCol "chinese" "Chinese Score" 3 .chinese
         in
         DataTable.defaultSortStates
            [ dtMsNameCol
            , dtMsAgeCol
            , { chineseAscend | defaultSortOrder = DataTable.Ascend }
            , msScoreCol "math" "Math Score" 2 .math
            , dtMsAddressCol
            ]
            |> List.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table defaultSortStates: duplicate keys upsert — replaced at the key's index, not appended (updateSortStatesByNewSortState)"
        [ ( "age", DataTable.Ascend ) ]
        (DataTable.defaultSortStates
            [ { dtMsAgeCol | defaultSortOrder = DataTable.Descend }
            , { dtMsAgeCol | defaultSortOrder = DataTable.Ascend }
            ]
            |> List.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table mergedSortStates: uncontrolled passthrough when no column is controlled (use-sorter.ts mergedSortStateRef)"
        [ ( "age", DataTable.Descend ) ]
        (DataTable.mergedSortStates dtMsColumns
            [ { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
            |> List.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table mergedSortStates: a controlled column with a real order wins — controlled columns mapped in column order"
        [ ( "age", DataTable.Ascend ), ( "math", DataTable.Descend ) ]
        (let
            mathCol =
                msScoreCol "math" "Math Score" 2 .math
         in
         DataTable.mergedSortStates
            [ dtMsNameCol
            , { dtMsAgeCol | sortOrder = Just DataTable.Ascend }
            , msScoreCol "chinese" "Chinese Score" 3 .chinese
            , { mathCol | sortOrder = Just DataTable.Descend }
            , dtMsAddressCol
            ]
            [ { columnKey = "chinese", order = DataTable.Descend, sorter = DataTable.SorterMultiple 3 Nothing } ]
            |> List.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table mergedSortStates: controlled-exists-but-all-NoSort → [] (the uncontrolled list is ignored)"
        []
        (DataTable.mergedSortStates
            [ dtMsNameCol
            , { dtMsAgeCol | sortOrder = Just DataTable.NoSort }
            , msScoreCol "chinese" "Chinese Score" 3 .chinese
            ]
            [ { columnKey = "chinese", order = DataTable.Descend, sorter = DataTable.SorterMultiple 3 Nothing } ]
            |> List.map (\state -> ( state.columnKey, state.order ))
        )
    , eq "data-table mergedSortStates: uncontrolled ignored whenever any controlled column is present (controlled NoSort contributes nothing but suppresses)"
        []
        (DataTable.mergedSortStates
            [ dtMsNameCol
            , { dtMsAgeCol | sortOrder = Just DataTable.NoSort }
            , msScoreCol "chinese" "Chinese Score" 3 .chinese
            ]
            [ { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
            |> List.map (\state -> ( state.columnKey, state.order ))
        )

    -- Anchor — single batch. Pins derive from AnchorAdapter.tsx's cssVarsRef
    -- (order + light.ts self / _common.ts literals + the generated common
    -- mappings), baseAnchorProps/anchorProps defaults, and the changeColor
    -- materialization the extractor bakes into the generated theme.
    -- =====================================================================
    , eq "anchor cssVars: the full 12-pair light set in cssVarsRef byte order"
        [ ( "--n-link-border-radius", "3px" )
        , ( "--n-link-color", "rgba(24, 160, 88, 0.15)" )
        , ( "--n-link-font-size", "13px" )
        , ( "--n-link-text-color", "rgb(51, 54, 57)" )
        , ( "--n-link-text-color-hover", "#36ad6a" )
        , ( "--n-link-text-color-active", "#18a058" )
        , ( "--n-link-text-color-pressed", "#0c7a43" )
        , ( "--n-link-padding", "0 0 0 16px" )
        , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
        , ( "--n-rail-color", "rgb(219, 219, 223)" )
        , ( "--n-rail-color-active", "#18a058" )
        , ( "--n-rail-width", "4px" )
        ]
        (Anchor.cssVarsFor Theme.default)
    , eq "anchor cssVars dark: linkColor dark literal + common-mapped peers (light.ts self over commonDark)"
        [ ( "--n-link-color", "rgba(99, 226, 183, 0.15)" )
        , ( "--n-link-text-color", "rgba(255, 255, 255, 0.82)" )
        , ( "--n-rail-color", "rgba(255, 255, 255, 0.2)" )
        , ( "--n-rail-color-active", "#63e2b7" )
        ]
        (Anchor.cssVarsFor Theme.dark
            |> List.filter
                (\( k, _ ) ->
                    List.member k
                        [ "--n-link-color"
                        , "--n-link-text-color"
                        , "--n-rail-color"
                        , "--n-rail-color-active"
                        ]
                )
        )
    , eq "anchor cssVars setPrimary: railColorActive follows common.primaryColor; linkColor stays the baked changeColor literal"
        [ Just "#ff0000", Just "rgba(24, 160, 88, 0.15)" ]
        [ lookup "--n-rail-color-active" (Anchor.cssVarsFor (Theme.setPrimary "#ff0000" Theme.default))
        , lookup "--n-link-color" (Anchor.cssVarsFor (Theme.setPrimary "#ff0000" Theme.default))
        ]
    , eq "anchor defaults: type rail, showRail/showBackground true, activeHref/internalScrollable/affix off (baseAnchorProps + anchorProps affix Boolean)"
        [ "Rail", "True", "True", "Nothing", "False", "Nothing" ]
        [ case Anchor.defaults.type_ of
            Anchor.Rail ->
                "Rail"

            Anchor.Block ->
                "Block"
        , if Anchor.defaults.showRail then
            "True"

          else
            "False"
        , if Anchor.defaults.showBackground then
            "True"

          else
            "False"
        , case Anchor.defaults.activeHref of
            Just _ ->
                "Just"

            Nothing ->
                "Nothing"
        , if Anchor.defaults.internalScrollable then
            "True"

          else
            "False"
        , case Anchor.defaults.affix of
            Just _ ->
                "Just"

            Nothing ->
                "Nothing"
        ]

    -- Transfer — single batch. Pins derive from Transfer.tsx cssVarsRef
    -- (:233-291) + styles/light.ts self / _common.ts literals + the
    -- generated common mappings + transferProps defaults (:30-84).
    -- Expectations: tasks/recon/transfer-pins.md.
    -- =====================================================================
    , eq "transfer cssVars: the full 25-pair light set in cssVarsRef byte order"
        [ ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
        , ( "--n-border-color", "rgb(224, 224, 230)" )
        , ( "--n-border-radius", "3px" )
        , ( "--n-extra-font-size", "12px" )
        , ( "--n-font-size", "14px" )
        , ( "--n-header-font-size", "16px" )
        , ( "--n-header-extra-text-color", "rgb(118, 124, 130)" )
        , ( "--n-header-extra-text-color-disabled", "rgba(194, 194, 194, 1)" )
        , ( "--n-header-font-weight", "400" )
        , ( "--n-header-text-color", "rgb(31, 34, 37)" )
        , ( "--n-header-text-color-disabled", "rgba(194, 194, 194, 1)" )
        , ( "--n-item-color-pending", "rgb(243, 243, 245)" )
        , ( "--n-item-height", "34px" )
        , ( "--n-item-text-color", "rgb(51, 54, 57)" )
        , ( "--n-item-text-color-disabled", "rgba(194, 194, 194, 1)" )
        , ( "--n-list-color", "#fff" )
        , ( "--n-header-height", "44px" )
        , ( "--n-close-size", "20px" )
        , ( "--n-close-icon-size", "16px" )
        , ( "--n-close-color-hover", "rgba(0, 0, 0, .09)" )
        , ( "--n-close-color-pressed", "rgba(0, 0, 0, .13)" )
        , ( "--n-close-icon-color", "rgba(102, 102, 102, 1)" )
        , ( "--n-close-icon-color-hover", "rgba(102, 102, 102, 1)" )
        , ( "--n-close-icon-color-pressed", "rgba(102, 102, 102, 1)" )
        , ( "--n-divider-color", "rgb(224, 224, 230)" )
        ]
        (Transfer.cssVarsFor Theme.default T.Medium)
    , eq "transfer cssVars dark: dark.ts self literals over commonDark (borderColor '#0000', dividerColor/listColor/itemHeight/fontSize)"
        [ ( "--n-border-color", "#0000" )
        , ( "--n-font-size", "14px" )
        , ( "--n-item-height", "34px" )
        , ( "--n-list-color", "rgba(255, 255, 255, 0.1)" )
        , ( "--n-divider-color", "rgba(255, 255, 255, 0.09)" )
        ]
        (Transfer.cssVarsFor Theme.dark T.Medium
            |> List.filter
                (\( k, _ ) ->
                    List.member k
                        [ "--n-border-color"
                        , "--n-divider-color"
                        , "--n-list-color"
                        , "--n-item-height"
                        , "--n-font-size"
                        ]
                )
        )
    , eq "transfer cssVars setPrimary: self() reads no primary-family var — all 25 pairs identical to the default theme"
        (Transfer.cssVarsFor Theme.default T.Medium)
        (Transfer.cssVarsFor (Theme.setPrimary "#ff0000" Theme.default) T.Medium)
    , eq "transfer cssVars Small: the five size-keyed vars (createKey extraFontSize/fontSize/titleFontSize/itemHeight/headerHeight)"
        [ ( "--n-extra-font-size", "12px" )
        , ( "--n-font-size", "14px" )
        , ( "--n-header-font-size", "14px" )
        , ( "--n-item-height", "34px" )
        , ( "--n-header-height", "44px" )
        ]
        (Transfer.cssVarsFor Theme.default T.Small
            |> List.filter
                (\( k, _ ) ->
                    List.member k
                        [ "--n-extra-font-size"
                        , "--n-font-size"
                        , "--n-header-font-size"
                        , "--n-item-height"
                        , "--n-header-height"
                        ]
                )
        )
    , eq "transfer cssVars Large: the five size-keyed vars (itemHeightLarge = heightLarge 40px, headerHeightLarge 50px)"
        [ ( "--n-extra-font-size", "14px" )
        , ( "--n-font-size", "15px" )
        , ( "--n-header-font-size", "16px" )
        , ( "--n-item-height", "40px" )
        , ( "--n-header-height", "50px" )
        ]
        (Transfer.cssVarsFor Theme.default T.Large
            |> List.filter
                (\( k, _ ) ->
                    List.member k
                        [ "--n-extra-font-size"
                        , "--n-font-size"
                        , "--n-header-font-size"
                        , "--n-item-height"
                        , "--n-header-height"
                        ]
                )
        )
    , eq "transfer defaults: size Medium, showSelected True, patterns empty, filters off (transferProps defaults + use-transfer-data pattern refs)"
        [ "Medium", "True", "", "", "Nothing", "False", "False" ]
        [ case Transfer.defaults.size of
            T.Tiny ->
                "Tiny"

            T.Small ->
                "Small"

            T.Medium ->
                "Medium"

            T.Large ->
                "Large"
        , if Transfer.defaults.showSelected then
            "True"

          else
            "False"
        , Transfer.defaults.sourcePattern
        , Transfer.defaults.targetPattern
        , case Transfer.defaults.filter of
            Just _ ->
                "Just"

            Nothing ->
                "Nothing"
        , if Transfer.defaults.sourceFilterable then
            "True"

          else
            "False"
        , if Transfer.defaults.targetFilterable then
            "True"

          else
            "False"
        ]

    -- TREE-SELECT — pin derivation: TreeSelect.tsx :816-845 (menuVars),
    -- :195-475 (derivations), :529-661 (click algebra + delete/clear) +
    -- Tree.tsx :1032-1130 (the unify click flow) + tree/src/utils.ts :8-13
    -- (mergedCheckStrategy). Expectations in tasks/recon/tree-select-pins.md.
    , eq "ts menuVars: the full 11-pair light set in cssVarsRef byte order (:816-845; menuPadding is NOT among them — it feeds the tree's scrollbar content)"
        [ ( "--n-menu-box-shadow", "0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)" )
        , ( "--n-menu-border-radius", "3px" )
        , ( "--n-menu-color", "#fff" )
        , ( "--n-menu-height", "calc(34px * 7.6)" )
        , ( "--n-bezier", "cubic-bezier(.4, 0, .2, 1)" )
        , ( "--n-action-padding", "8px 12px" )
        , ( "--n-action-text-color", "rgb(51, 54, 57)" )
        , ( "--n-action-divider-color", "rgb(239, 239, 245)" )
        , ( "--n-header-padding", "8px 12px" )
        , ( "--n-header-text-color", "rgb(51, 54, 57)" )
        , ( "--n-header-divider-color", "rgb(239, 239, 245)" )
        ]
        (TreeSelect.menuVars Theme.default)
    , eq "ts defaults: Single Nothing, All strategy, ' / ' separator, indent 24, 'Please Select' placeholder, leafOnly off (treeSelectProps + enUS locale)"
        [ "SingleNothing", "All", " / ", "24", "Please Select", "False" ]
        [ case TreeSelect.defaults.value of
            SelectMenu.Single Nothing ->
                "SingleNothing"

            _ ->
                "other"
        , case TreeSelect.defaults.checkStrategy of
            Tree.All ->
                "All"

            Tree.Parent ->
                "Parent"

            Tree.Child ->
                "Child"
        , TreeSelect.defaults.separator
        , String.fromInt TreeSelect.defaults.indent
        , TreeSelect.defaults.placeholder
        , if TreeSelect.defaults.leafOnly then
            "True"

          else
            "False"
        ]
    , eq "ts single click selects the key — unify routes EVERY click (line/label/checkbox) through handleSelect → doUpdateCheckedKeys([key]) (:1039-1041, :681-691)"
        (SelectMenu.Single (Just "o1-1"))
        (TreeSelect.handleNodeClick tsSingleOpts (SelectMenu.Single Nothing) "o1-1")
    , eq "ts single click on a disabled node is a no-op (Tree.tsx :1032-1035 per-node gate)"
        (SelectMenu.Single Nothing)
        (TreeSelect.handleNodeClick tsSingleOpts (SelectMenu.Single Nothing) "o3")
    , eq "ts single click on a MISSING key is a no-op (getNode miss)"
        (SelectMenu.Single (Just "o2"))
        (TreeSelect.handleNodeClick tsSingleOpts (SelectMenu.Single (Just "o2")) "nope")
    , eq "ts single + checkable checkbox click o1-1 → still Single (Just o1-1) — unify REDIRECTS the check to select, no cascade check (:1039-1041)"
        (SelectMenu.Single (Just "o1-1"))
        (TreeSelect.handleNodeClick tsSingleCheckOpts (SelectMenu.Single Nothing) "o1-1")
    , eq "ts multiple + checkable + cascade check o1 extends the whole subtree in document order (treemate check; o1 → o1-1 → o1-3 → o1-2)"
        (SelectMenu.Multiple [ "o1", "o1-1", "o1-3", "o1-2" ])
        (TreeSelect.handleNodeClick tsMultiCheckOpts (SelectMenu.Multiple []) "o1")
    , eq "ts the cascade check delegates to Tree.check over the same inputs (algebra == treemate port)"
        (SelectMenu.Multiple (Tree.check True Tree.All False "o1" [] treeSelectOptions))
        (TreeSelect.handleNodeClick tsMultiCheckOpts (SelectMenu.Multiple []) "o1")
    , eq "ts clicking an on-node unchecks: o1-1 off the full subtree leaves o1-2 (o1 indeterminate — never in the value)"
        (SelectMenu.Multiple (Tree.uncheck True Tree.All False "o1-1" [ "o1", "o1-1", "o1-3", "o1-2" ] treeSelectOptions))
        (TreeSelect.handleNodeClick tsMultiCheckOpts (SelectMenu.Multiple [ "o1", "o1-1", "o1-3", "o1-2" ]) "o1-1")
    , eq "ts select-click on a checked-or-indeterminate parent flips it OFF under child strategy (:1114-1126 — !(checked ∪ indeterminate))"
        (SelectMenu.Multiple (Tree.uncheck True Tree.Child False "o1" [ "o1-1", "o1-3", "o2" ] treeSelectOptions))
        (TreeSelect.handleNodeClick
            { tsMultiCheckOpts | checkStrategy = Tree.Child }
            (SelectMenu.Multiple [ "o1-1", "o2" ])
            "o1"
        )
    , eq "ts NON-cascade check touches only the clicked key (mergedCascade false — the extension never runs)"
        (SelectMenu.Multiple [ "o1" ])
        (TreeSelect.handleNodeClick { tsMultiCheckOpts | cascade = False } (SelectMenu.Multiple []) "o1")
    , eq "ts multiple plain toggleSelect: in, in, out (:1109-1159 — cancelable is multiple)"
        [ "[o1-1]", "[o1-1,o2]", "[o2]" ]
        [ case TreeSelect.handleNodeClick tsMultiPlainOpts (SelectMenu.Multiple []) "o1-1" of
            SelectMenu.Multiple ks ->
                "[" ++ String.join "," ks ++ "]"

            _ ->
                "other"
        , case TreeSelect.handleNodeClick tsMultiPlainOpts (SelectMenu.Multiple [ "o1-1" ]) "o2" of
            SelectMenu.Multiple ks ->
                "[" ++ String.join "," ks ++ "]"

            _ ->
                "other"
        , case TreeSelect.handleNodeClick tsMultiPlainOpts (SelectMenu.Multiple [ "o1-1", "o2" ]) "o1-1" of
            SelectMenu.Multiple ks ->
                "[" ++ String.join "," ks ++ "]"

            _ ->
                "other"
        ]
    , eq "ts deleteOption plain: base = strategy-less normalize (raw keys, no cascade), splice the ONE index (:623-657)"
        (SelectMenu.Multiple [ "o1-1", "o1-3" ])
        (TreeSelect.deleteOption tsMultiPlainOpts (SelectMenu.Multiple [ "o1-1", "o1-2", "o1-3" ]) "o1-2")
    , eq "ts deleteOption checkable: All-normalized base, then uncheck under the MERGED strategy (:637-649)"
        (SelectMenu.Multiple
            (Tree.uncheck
                True
                Tree.Child
                False
                "o1-1"
                (Tree.getCheckedKeys True Tree.All False [ "o1-1", "o2" ] treeSelectOptions
                    |> .checkedKeys
                )
                treeSelectOptions
            )
        )
        (TreeSelect.deleteOption
            { tsMultiCheckOpts | checkStrategy = Tree.Child }
            (SelectMenu.Multiple [ "o1-1", "o2" ])
            "o1-1"
        )
    , eq "ts deleteOption under leafOnly unchecks with the RAW checkStrategy (:643 passes props.checkStrategy unmerged — the All-strategy parent + descendants survive the delete; the merged child view would be [])"
        (SelectMenu.Multiple [ "o1", "o1-1", "o1-3", "o1-2" ])
        (TreeSelect.deleteOption
            { tsMultiCheckOpts | leafOnly = True }
            (SelectMenu.Multiple [ "o1", "o2" ])
            "o2"
        )
    , eq "ts deleteOption under leafOnly delegates to Tree.uncheck with the RAW strategy over the All-normalized base (upstream's leafOnly-not-folded delete inconsistency)"
        (SelectMenu.Multiple
            (Tree.uncheck
                True
                Tree.All
                False
                "o2"
                [ "o1", "o2" ]
                treeSelectOptions
            )
        )
        (TreeSelect.deleteOption
            { tsMultiCheckOpts | leafOnly = True }
            (SelectMenu.Multiple [ "o1", "o2" ])
            "o2"
        )
    , eq "ts child strategy without cascade-multiple: a NON-leaf click is a no-op (TreeNode.tsx :111-121 — internalTreeSelect gates selectable to leaves unless the strategy ≠ child or multiple && cascade)"
        (SelectMenu.Multiple [])
        (TreeSelect.handleNodeClick
            { tsMultiCheckOpts | checkStrategy = Tree.Child, cascade = False }
            (SelectMenu.Multiple [])
            "o1"
        )
    , eq "ts child strategy without cascade-multiple: a LEAF still checks (the gate passes on isLeaf)"
        (SelectMenu.Multiple [ "o1-2" ])
        (TreeSelect.handleNodeClick
            { tsMultiCheckOpts | checkStrategy = Tree.Child, cascade = False }
            (SelectMenu.Multiple [])
            "o1-2"
        )
    , eq "ts single + checkable + child: the non-leaf row is dead too — the selectable gate, not just the checkbox gate"
        (SelectMenu.Single Nothing)
        (TreeSelect.handleNodeClick
            { tsSingleCheckOpts | checkStrategy = Tree.Child }
            (SelectMenu.Single Nothing)
            "o1"
        )
    , eq "ts deleteOption on a key outside the base is a no-op (findIndex -1, :630-631)"
        (SelectMenu.Multiple [ "o1" ])
        (TreeSelect.deleteOption tsMultiCheckOpts (SelectMenu.Multiple [ "o1" ]) "o2")
    , eq "ts deleteOption single-mode value is untouched (the guard only works for arrays, :620)"
        (SelectMenu.Single (Just "o2"))
        (TreeSelect.deleteOption tsSingleOpts (SelectMenu.Single (Just "o2")) "o2")
    , eq "ts clearValue: Multiple → [], Single → null (:604-616)"
        [ "Multiple0", "SingleNothing" ]
        [ case TreeSelect.clearValue (SelectMenu.Multiple [ "a", "b" ]) of
            SelectMenu.Multiple ks ->
                "Multiple" ++ String.fromInt (List.length ks)

            _ ->
                "other"
        , case TreeSelect.clearValue (SelectMenu.Single (Just "a")) of
            SelectMenu.Single Nothing ->
                "SingleNothing"

            _ ->
                "other"
        ]
    , eq "ts checkStrategyOf: deprecated leafOnly folds to child, else passthrough (tree/src/utils.ts :8-13)"
        [ "Child", "Child", "Parent" ]
        [ case TreeSelect.checkStrategyOf tsLeafOnlyOpts of
            Tree.Child ->
                "Child"

            _ ->
                "other"
        , case TreeSelect.checkStrategyOf { tsMultiCheckOpts | checkStrategy = Tree.Child, leafOnly = False } of
            Tree.Child ->
                "Child"

            _ ->
                "other"
        , case TreeSelect.checkStrategyOf tsParentOpts of
            Tree.Parent ->
                "Parent"

            _ ->
                "other"
        ]
    , eq "ts initialPendingKey: Nothing under checkable, else the LAST list key — a single value seeds nothing (:274-281)"
        [ "Nothing", "Just b", "Nothing" ]
        [ case TreeSelect.initialPendingKey tsMultiCheckOpts of
            Just k ->
                "Just " ++ k

            Nothing ->
                "Nothing"
        , case TreeSelect.initialPendingKey { tsMultiPlainOpts | value = SelectMenu.Multiple [ "a", "b" ] } of
            Just k ->
                "Just " ++ k

            Nothing ->
                "Nothing"
        , case TreeSelect.initialPendingKey { tsSingleOpts | value = SelectMenu.Single (Just "x") } of
            Just k ->
                "Just " ++ k

            Nothing ->
                "Nothing"
        ]
    , eq "ts mergedCascade gates: multiple && cascade && checkable — each leg alone fails (:282-284)"
        [ "False", "False", "True" ]
        [ if TreeSelect.mergedCascade tsCascadeNoMultipleOpts then
            "True"

          else
            "False"
        , if TreeSelect.mergedCascade tsCascadeNoCheckableOpts then
            "True"

          else
            "False"
        , if TreeSelect.mergedCascade tsCascadeFullOpts then
            "True"

          else
            "False"
        ]
    , eq "ts unloaded subtree stays TOTAL where treemate throws SubtreeNotLoadedError (allowNotLoaded=false keeps the allowNotLoaded-true set — the b3 rule)"
        (SelectMenu.Multiple [ "o4" ])
        (TreeSelect.handleNodeClick
            { tsMultiCheckOpts | options = treeSelectUnloadOptions, allowCheckingNotLoaded = False }
            (SelectMenu.Multiple [])
            "o4"
        )

    -- The spec `multiple sorter` walk (DataTable.spec.tsx:379-646) —
    -- every expected array re-derived from the spec's checkScoreIsMatched
    -- bytes (ties fall through by multiple priority 3 > 2 > 1; JS sort is
    -- stable, so the name array is the row order the score bytes pin).
    ]
        ++ msWalkChecks
        ++ -- Pagination (use-table-data.ts + DataTable.tsx:454-466) and the
           -- default sorter triage (use-sorter.ts getDefaultSorterFn).
           [ eq "data-table mergedItemCount: local ignores the pagination itemCount and counts the data (spec `itemCount` without `remote`: local length wins)"
                (Just 4)
                (DataTable.mergedItemCount
                    (dtMsOptsU
                        []
                        { remote = False
                        , paginateSinglePage = True
                        , pagination =
                            Just
                                { pgD
                                    | currentPage = 1
                                    , pageCount = Just 1
                                    , pageSize = Just 10
                                    , itemCount = Just 0
                                }
                        }
                    )
                )
           , eq "data-table mergedItemCount: remote passes the pagination itemCount through (spec `itemCount` with `remote`)"
                (Just 978)
                (DataTable.mergedItemCount
                    (dtMsOptsU
                        []
                        { remote = True
                        , paginateSinglePage = True
                        , pagination = Just { pgD | currentPage = 1, pageSize = Just 10, itemCount = Just 978 }
                        }
                    )
                )
           , eq "data-table mergedItemCount: remote with no itemCount → Nothing (upstream undefined)"
                Nothing
                (DataTable.mergedItemCount
                    (dtMsOptsU
                        []
                        { remote = True
                        , paginateSinglePage = True
                        , pagination = Just { pgD | currentPage = 1, pageSize = Just 10 }
                        }
                    )
                )
           , eq "data-table boundedPage: local clamps page 99 to ceil(len/pageSize) and 0/-5 to 1 (use-table-data.ts boundedMergedCurrentPageRef)"
                [ 2, 1, 1 ]
                [ DataTable.boundedPage (dtMsOptsU [] { remote = False, paginateSinglePage = True, pagination = Just { pgD | currentPage = 99, pageSize = Just 2 } })
                , DataTable.boundedPage (dtMsOptsU [] { remote = False, paginateSinglePage = True, pagination = Just { pgD | currentPage = 0, pageSize = Just 2 } })
                , DataTable.boundedPage (dtMsOptsU [] { remote = False, paginateSinglePage = True, pagination = Just { pgD | currentPage = -5, pageSize = Just 2 } })
                ]
           , eq "data-table boundedPage: remote passes the page through unclamped"
                [ 99, 0 ]
                [ DataTable.boundedPage (dtMsOptsU [] { remote = True, paginateSinglePage = True, pagination = Just { pgD | currentPage = 99, pageSize = Just 2 } })
                , DataTable.boundedPage (dtMsOptsU [] { remote = True, paginateSinglePage = True, pagination = Just { pgD | currentPage = 0, pageSize = Just 2 } })
                ]
           , eq "data-table mergedPageSize: the pagination pageSize wins; Nothing falls back to getDefaultPageSize (first pageSizes number, else 10)"
                [ 5, 25, 10 ]
                [ DataTable.mergedPageSize (dtMsOptsU [] { remote = False, paginateSinglePage = True, pagination = Just { pgD | pageSize = Just 5 } })
                , DataTable.mergedPageSize
                    (dtMsOptsU
                        []
                        { remote = False
                        , paginateSinglePage = True
                        , pagination = Just { pgD | pageSize = Nothing, pageSizes = [ Pagination.PageSizeNumber 25 ] }
                        }
                    )
                , DataTable.mergedPageSize (dtMsOptsU [] { remote = False, paginateSinglePage = True, pagination = Just { pgD | pageSize = Nothing } })
                ]
           , eq "data-table paginatedData: no pagination object → the sorted data as-is (spec getCurrentPageData: full sorted data)"
                [ "Jim Green", "John Brown", "Joe Black", "Jim Red" ]
                (DataTable.paginatedData
                    (dtMsOptsU
                        [ { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
                        { remote = False
                        , paginateSinglePage = True
                        , pagination = Nothing
                        }
                    )
                    |> List.map .name
                )
           , eq "data-table paginatedData: pageSize 1 page 2 → exactly row 2 of the sorted data (spec getCurrentPageData)"
                [ "John Brown" ]
                (DataTable.paginatedData
                    (dtMsOptsU
                        [ { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
                        { remote = False
                        , paginateSinglePage = True
                        , pagination = Just { pgD | currentPage = 2, pageSize = Just 1 }
                        }
                    )
                    |> List.map .name
                )
           , eq "data-table paginatedData: remote hands the raw data back untouched even with a sort state (the server paginates)"
                [ "John Brown", "Jim Green", "Joe Black", "Jim Red" ]
                (DataTable.paginatedData
                    (dtMsOptsU
                        [ { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
                        { remote = True
                        , paginateSinglePage = True
                        , pagination = Just { pgD | currentPage = 1, pageSize = Just 2 }
                        }
                    )
                    |> List.map .name
                )
           , eq "data-table showPagination: no pagination object → False; default paginateSinglePage → True (DataTable.tsx mergedShowPagination)"
                [ False, True ]
                [ DataTable.showPagination (dtMsOpts [])
                , DataTable.showPagination (dtMsOptsU [] { remote = False, paginateSinglePage = True, pagination = Just pgD })
                ]
           , eq "data-table showPagination: paginateSinglePage False reads the merged pageCount (remote keeps the caller pageCount; Just 1 → False, Just 2 → True)"
                [ False, True ]
                [ DataTable.showPagination
                    (dtMsOptsU
                        []
                        { remote = True
                        , paginateSinglePage = False
                        , pagination = Just { pgD | currentPage = 1, pageCount = Just 1, pageSize = Just 10 }
                        }
                    )
                , DataTable.showPagination
                    (dtMsOptsU
                        []
                        { remote = True
                        , paginateSinglePage = False
                        , pagination = Just { pgD | currentPage = 1, pageCount = Just 2, pageSize = Just 10 }
                        }
                    )
                ]
           , eq "data-table showPagination: paginateSinglePage False + no pageCount → itemCount > pageSize (4≤4 False, 4>2 True — local counts the 4-row data)"
                [ False, True ]
                [ DataTable.showPagination
                    (dtMsOptsU
                        []
                        { remote = False
                        , paginateSinglePage = False
                        , pagination = Just { pgD | currentPage = 1, pageSize = Just 4 }
                        }
                    )
                , DataTable.showPagination
                    (dtMsOptsU
                        []
                        { remote = False
                        , paginateSinglePage = False
                        , pagination = Just { pgD | currentPage = 1, pageSize = Just 2 }
                        }
                    )
                ]
           , eq "data-table showPagination: remote with no pageCount → per the itemCount rule (978 > 10 True, 5 ≤ 10 False)"
                [ True, False ]
                [ DataTable.showPagination
                    (dtMsOptsU
                        []
                        { remote = True
                        , paginateSinglePage = False
                        , pagination = Just { pgD | currentPage = 1, pageSize = Just 10, itemCount = Just 978 }
                        }
                    )
                , DataTable.showPagination
                    (dtMsOptsU
                        []
                        { remote = True
                        , paginateSinglePage = False
                        , pagination = Just { pgD | currentPage = 1, pageSize = Just 10, itemCount = Just 5 }
                        }
                    )
                ]
           , eq "data-table mergedPaginationOpts: pageCount blanked when the item count is set, kept when it is Nothing (use-table-data.ts mergedPaginationRef)"
                [ ( Nothing, Just 4 ), ( Just 7, Nothing ) ]
                [ ( (DataTable.mergedPaginationOpts
                        (dtMsOptsU
                            []
                            { remote = False
                            , paginateSinglePage = True
                            , pagination = Just { pgD | currentPage = 1, pageCount = Just 7, pageSize = Just 2, itemCount = Just 0 }
                            }
                        )
                    ).pageCount
                  , (DataTable.mergedPaginationOpts
                        (dtMsOptsU
                            []
                            { remote = False
                            , paginateSinglePage = True
                            , pagination = Just { pgD | currentPage = 1, pageCount = Just 7, pageSize = Just 2, itemCount = Just 0 }
                            }
                        )
                    ).itemCount
                  )
                , ( (DataTable.mergedPaginationOpts
                        (dtMsOptsU
                            []
                            { remote = True
                            , paginateSinglePage = True
                            , pagination = Just { pgD | currentPage = 1, pageCount = Just 7, pageSize = Just 2 }
                            }
                        )
                    ).pageCount
                  , (DataTable.mergedPaginationOpts
                        (dtMsOptsU
                            []
                            { remote = True
                            , paginateSinglePage = True
                            , pagination = Just { pgD | currentPage = 1, pageCount = Just 7, pageSize = Just 2 }
                            }
                        )
                    ).itemCount
                  )
                ]
           , eq "data-table mergedPaginationOpts: currentPage is the bounded page (99 → 2 over 4 rows / pageSize 2)"
                2
                (DataTable.mergedPaginationOpts
                    (dtMsOptsU
                        []
                        { remote = False, paginateSinglePage = True, pagination = Just { pgD | currentPage = 99, pageSize = Just 2 } }
                    )
                ).currentPage
           , eq "data-table sortValueCompare: the getDefaultSorterFn triage — null/null EQ, null LT a number, a number GT null, numbers and strings ordered, mixed EQ (upstream 0)"
                [ Basics.EQ, Basics.LT, Basics.GT, Basics.LT, Basics.GT, Basics.LT, Basics.GT, Basics.EQ ]
                [ DataTable.sortValueCompare DataTable.SortNull DataTable.SortNull
                , DataTable.sortValueCompare DataTable.SortNull (DataTable.SortNumber 1)
                , DataTable.sortValueCompare (DataTable.SortNumber 1) DataTable.SortNull
                , DataTable.sortValueCompare (DataTable.SortNumber 1) (DataTable.SortNumber 2)
                , DataTable.sortValueCompare (DataTable.SortNumber 2) (DataTable.SortNumber 1)
                , DataTable.sortValueCompare (DataTable.SortString "a") (DataTable.SortString "b")
                , DataTable.sortValueCompare (DataTable.SortString "b") (DataTable.SortString "a")
                , DataTable.sortValueCompare (DataTable.SortNumber 1) (DataTable.SortString "a")
                ]
           ]
        ++ -- Selection (use-check.ts) and expand (use-expand.ts) — batch 3.
           -- Every expectation derives from the upstream bytes: the treemate
           -- flat-data rules (b3 upstream recon §2), the header math over the
           -- CURRENT page, and the spec fixtures quoted in recon §6.
           [ eq "dt mergedCheckedRowKeys: flat treemate derivation — the data-order filter of the source keys' members, unknown keys dropped (use-check.ts getCheckedKeys over flat rows)"
                [ "John Brown", "Joe Black" ]
                (DataTable.mergedCheckedRowKeys
                    { dtOpts
                        | columns = [ dtSelCol, dtNameCol ]
                        , checkedRowKeys = [ "Joe Black", "bogus", "John Brown" ]
                    }
                )
           , eq "dt mergedCheckedRowKeys: multiple === false slices the source to its first key — no treemate pass, order preserved, a bogus head key survives until a click replaces it (use-check.ts)"
                [ "bogus" ]
                (DataTable.mergedCheckedRowKeys
                    { dtOpts
                        | columns = [ { dtSelCol | multiple = False }, dtNameCol ]
                        , checkedRowKeys = [ "bogus", "John Brown" ]
                    }
                )
           , eq "dt checkedKeysAfterCheck: the display state, then the new keys appended in click order (the flat treemate check union)"
                [ "Joe Black", "John Brown", "Jim Green" ]
                (DataTable.checkedKeysAfterCheck
                    { dtOpts
                        | columns = [ dtSelCol, dtNameCol ]
                        , checkedRowKeys = [ "Joe Black" ]
                    }
                    [ "John Brown", "Joe Black", "Jim Green" ]
                )
           , eq "dt checkedKeysAfterUncheck: the display order minus the removed keys (the flat treemate uncheck)"
                [ "John Brown", "Joe Black" ]
                (DataTable.checkedKeysAfterUncheck
                    { dtOpts
                        | columns = [ dtSelCol, dtNameCol ]
                        , checkedRowKeys = [ "Joe Black", "John Brown", "Jim Green" ]
                    }
                    [ "Jim Green" ]
                )
           , eq "dt checkedKeysAfterCheckAll: the not-disabled keys of the CURRENT page union into the display state (doCheckAll(false) over paginatedData)"
                [ "John Brown" ]
                (DataTable.checkedKeysAfterCheckAll
                    { dtOpts
                        | columns =
                            [ { dtSelCol | disabled = Just (\r -> r.name == "Jim Green") }
                            , dtNameCol
                            ]
                        , checkedRowKeys = []
                        , pagination = Just { dtPgD | currentPage = 1, pageSize = Just 2 }
                    }
                    False
                )
           , eq "dt checkedKeysAfterCheckAll: checkWholeTable spans the whole data past the page (doCheckAll(true) over treeNodes)"
                [ "John Brown", "Joe Black" ]
                (DataTable.checkedKeysAfterCheckAll
                    { dtOpts
                        | columns =
                            [ { dtSelCol | disabled = Just (\r -> r.name == "Jim Green") }
                            , dtNameCol
                            ]
                        , checkedRowKeys = []
                        , pagination = Just { dtPgD | currentPage = 1, pageSize = Just 2 }
                    }
                    True
                )
           , eq "dt checkedKeysAfterCheckAll: no selection column is the column-null gate — the display state returns unchanged"
                [ "Joe Black" ]
                (DataTable.checkedKeysAfterCheckAll
                    { dtOpts
                        | columns = [ dtNameCol ]
                        , checkedRowKeys = [ "Joe Black", "bogus" ]
                    }
                    True
                )
           , eq "dt checkedKeysAfterUncheckAll: the current-page diff — the disabled page row stays checked (doUncheckAll(false))"
                [ "Jim Green", "Joe Black" ]
                (DataTable.checkedKeysAfterUncheckAll
                    { dtOpts
                        | columns =
                            [ { dtSelCol | disabled = Just (\r -> r.name == "Jim Green") }
                            , dtNameCol
                            ]
                        , checkedRowKeys = [ "John Brown", "Jim Green", "Joe Black" ]
                        , pagination = Just { dtPgD | currentPage = 1, pageSize = Just 2 }
                    }
                    False
                )
           , eq "dt header state: some but not all of the current page's enabled rows — indeterminate on, checked off (0 < countChecked < length - countDisabled)"
                ( True, False )
                (dtHeaderState
                    { dtOpts
                        | columns = [ dtSelCol, dtNameCol ]
                        , checkedRowKeys = [ "John Brown" ]
                    }
                )
           , eq "dt header state: every enabled row checked — checked on, indeterminate off (countChecked = length - countDisabled ≠ 0)"
                ( False, True )
                (dtHeaderState
                    { dtOpts
                        | columns = [ dtSelCol, dtNameCol ]
                        , checkedRowKeys = [ "John Brown", "Jim Green", "Joe Black" ]
                    }
                )
           , eq "dt header state: disabled rows leave both the numerator and the denominator — all-checked without the disabled row"
                ( False, True )
                (dtHeaderState
                    { dtOpts
                        | columns = [ { dtSelCol | disabled = Just (\r -> r.name == "Jim Green") }, dtNameCol ]
                        , checkedRowKeys = [ "John Brown", "Joe Black" ]
                    }
                )
           , eq "dt headerCheckboxDisabled: no paginated rows disable the header checkbox, rows present do not (paginatedData.length === 0)"
                ( True, False )
                ( DataTable.headerCheckboxDisabled { dtOpts | columns = [ dtSelCol, dtNameCol ], data = [] }
                , DataTable.headerCheckboxDisabled { dtOpts | columns = [ dtSelCol, dtNameCol ] }
                )
           , eq "dt checkedKeysAfterRowClick: shift with a resolvable lastSelectedKey checks the [min(last, cur) .. max] page range together (Body.tsx handleCheckboxUpdateChecked)"
                [ "John Brown", "Jim Green", "Joe Black" ]
                (DataTable.checkedKeysAfterRowClick
                    { dtMsSelOpts | lastSelectedKey = "John Brown" }
                    "Joe Black"
                    True
                    True
                )
           , eq "dt checkedKeysAfterRowClick: the range is direction-agnostic — [min .. max] over a backward drag equals the forward one"
                [ "John Brown", "Jim Green", "Joe Black" ]
                (DataTable.checkedKeysAfterRowClick
                    { dtMsSelOpts | lastSelectedKey = "Joe Black" }
                    "John Brown"
                    True
                    True
                )
           , eq "dt checkedKeysAfterRowClick: an unresolvable lastSelectedKey (the '' init) falls back to the single clicked key even with shiftKey"
                [ "Jim Green" ]
                (DataTable.checkedKeysAfterRowClick
                    dtMsSelOpts
                    "Jim Green"
                    True
                    True
                )
           , eq "dt checkedKeysAfterRowClick: a plain click unchecks just the one key off the display state"
                [ "Jim Green" ]
                (DataTable.checkedKeysAfterRowClick
                    { dtMsSelOpts
                        | checkedRowKeys = [ "John Brown", "Jim Green" ]
                    }
                    "John Brown"
                    False
                    False
                )
           , eq "dt checkedKeysAfterRowClick: disabled rows drop out of the shift range (the disabled filter runs over the slice)"
                [ "John Brown", "Joe Black" ]
                (DataTable.checkedKeysAfterRowClick
                    { dtMsSelOpts
                        | columns =
                            [ { dtMsSelCol | disabled = Just (\r -> r.name == "Jim Green") }
                            , dtMsNameCol
                            ]
                        , lastSelectedKey = "John Brown"
                    }
                    "Joe Black"
                    True
                    True
                )
           , eq "dt toggleExpandedRowKey: a member key splices out preserving order (handleUpdateExpanded's splice branch)"
                [ "a", "c" ]
                (DataTable.toggleExpandedRowKey "b" [ "a", "b", "c" ])
           , eq "dt toggleExpandedRowKey: a non-member key appends (the push branch)"
                [ "a", "b", "d" ]
                (DataTable.toggleExpandedRowKey "d" [ "a", "b" ])
           , eq "dt toggleExpandedRowKey: a duplicated key splices out at its FIRST index only — upstream indexOf + splice(index, 1), not a filter (Body.tsx :296-304)"
                [ "a", "b" ]
                (DataTable.toggleExpandedRowKey "a" [ "a", "a", "b" ])
           , eq "dt defaultExpandAllKeys: with a renderExpand present, seeds the keys of the data rows passing the first expand column's expandable (the use-expand.ts walk)"
                [ "John Brown" ]
                (DataTable.defaultExpandAllKeys
                    [ { dtExpCol
                        | renderExpand = Just (\_ _ -> Element.none)
                        , expandable = Just (\r -> r.name == "John Brown")
                      }
                    , dtNameCol
                    ]
                    dtRows
                    .name
                )
           , eq "dt defaultExpandAllKeys: an absent expandable seeds NOTHING — the optional-chain truthiness quirk kept byte-faithful (use-expand.ts)"
                []
                (DataTable.defaultExpandAllKeys
                    [ { dtExpCol | renderExpand = Just (\_ _ -> Element.none) }
                    , dtNameCol
                    ]
                    dtRows
                    .name
                )
           , eq "dt defaultExpandAllKeys: no renderExpand on the expand column seeds getNonLeafKeys — [] on flat data, EVEN with an expandable set (use-expand.ts:45-58: the walk is gated on renderExpandRef?.value)"
                []
                (DataTable.defaultExpandAllKeys
                    [ { dtExpCol | expandable = Just (\r -> r.name == "John Brown") }
                    , dtNameCol
                    ]
                    dtRows
                    .name
                )
           , eq "dt mergedSortStates: a SELECTION column never reads as controlled — upstream's type !== 'selection' gate, the uncontrolled list passes through (use-sorter.ts L108-112)"
                [ ( "age", DataTable.Descend ) ]
                (DataTable.mergedSortStates
                    [ { dtSelCol
                        | sorter = Just (DataTable.SorterBy (\a b -> compare a.age b.age))
                        , sortOrder = Just DataTable.Descend
                      }
                    , dtNameCol
                    ]
                    [ { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
                    |> List.map (\state -> ( state.columnKey, state.order ))
                )
           , eq "dt mergedSortStates: the gate is selection-only — an expand column with a set sortOrder reads as controlled exactly like a basic one"
                [ ( "exp", DataTable.Descend ) ]
                (DataTable.mergedSortStates
                    [ { dtExpCol
                        | key = "exp"
                        , sorter = Just (DataTable.SorterBy (\a b -> compare a.age b.age))
                        , sortOrder = Just DataTable.Descend
                      }
                    , dtNameCol
                    ]
                    [ { columnKey = "age", order = DataTable.Ascend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
                    |> List.map (\state -> ( state.columnKey, state.order ))
                )
           ]
        ++ -- Scroll/layout (use-scroll.ts :58-112 — the fixed-offset width
           -- walks; only `?.start` is ever read by the th/td styles).
           [ eq "dt fixedColumnLeftMap: left-fixed columns keyed with the summed widths of the PRECEDING left-fixed ones; plain columns never join (use-scroll.ts:64)"
                [ ( "name", 0 ), ( "age", 100 ) ]
                (DataTable.fixedColumnLeftMap
                    [ { dtNameCol | width = Just 100, fixed = Just DataTable.FixedLeft }
                    , { dtAgeCol | width = Just 60, fixed = Just DataTable.FixedLeft }
                    , dtAddressCol
                    ]
                )
           , eq "dt fixedColumnLeftMap: selection defaults 40 when width unset, an unset NORMAL width counts 0 (utils.ts getNumberColWidth:20)"
                [ ( "__n_selection__", 0 ), ( "name", 40 ), ( "age", 140 ) ]
                (DataTable.fixedColumnLeftMap
                    [ { dtSelCol | fixed = Just DataTable.FixedLeft }
                    , { dtNameCol | width = Just 100, fixed = Just DataTable.FixedLeft }
                    , { dtAgeCol | fixed = Just DataTable.FixedLeft }
                    ]
                )
           , eq "dt fixedColumnRightMap: the walk is REVERSED — each right-fixed column keyed with the summed widths of the FOLLOWING ones (use-scroll.ts:81)"
                [ ( "age", 0 ), ( "name", 60 ) ]
                (DataTable.fixedColumnRightMap
                    [ { dtNameCol | width = Just 100, fixed = Just DataTable.FixedRight }
                    , { dtAgeCol | width = Just 60, fixed = Just DataTable.FixedRight }
                    , dtAddressCol
                    ]
                )
           ]
        ++ -- Filter (use-table-data.ts :91-:212, utils.ts :107-113,
           -- FilterButton.tsx :21/:81 — the state machine and the row walk).
           [ eq "dt defaultFilterStates: the init walk — multiple seeds [] (`|| []`), single seeds `?? null` as a PRESENT FilterNull entry (use-table-data.ts :198-212)"
                [ ( "multi", DataTable.FilterMany [] ), ( "single", DataTable.FilterNull ) ]
                (DataTable.defaultFilterStates
                    [ { dtFilterCol | key = "multi", filterMultiple = True }
                    , { dtFilterCol | key = "single", filterMultiple = False }
                    ]
                )
           , eq "dt defaultFilterStates: multiple keeps defaultFilterOptionValues, single keeps defaultFilterOptionValue, single + defaultFilterOptionValues is the compat ARRAY branch (null ≡ [] documented)"
                [ ( "multi", DataTable.FilterMany [ "London", "Sidney" ] )
                , ( "singleV", DataTable.FilterOne "London" )
                , ( "singleArr", DataTable.FilterMany [ "New York" ] )
                , ( "singleNull", DataTable.FilterMany [] )
                ]
                (DataTable.defaultFilterStates
                    [ { dtFilterCol | key = "multi", defaultFilterOptionValues = Just [ "London", "Sidney" ] }
                    , { dtFilterCol | key = "singleV", filterMultiple = False, defaultFilterOptionValue = Just "London" }
                    , { dtFilterCol | key = "singleArr", filterMultiple = False, defaultFilterOptionValues = Just [ "New York" ] }
                    , { dtFilterCol | key = "singleNull", filterMultiple = False, defaultFilterOptionValues = Just [] }
                    ]
                )
           , eq "dt defaultFilterStates: a column without `filter` seeds NOTHING (the walk's truthiness gate)"
                []
                (DataTable.defaultFilterStates [ dtNameCol, { dtFilterCol | filter = Nothing } ])
           , eq "dt mergedFilterStates: controlled keys REPLACE in place / APPEND in column order (Object.assign semantics); selection kinds never overlay (use-table-data.ts :91-116)"
                [ ( "address", DataTable.FilterMany [ "London" ] ), ( "name", DataTable.FilterOne "x" ) ]
                (DataTable.mergedFilterStates
                    { dtOpts
                        | columns =
                            [ { dtFilterCol | filterOptionValues = Just [ "London" ] }
                            , { dtNameCol | filterOptionValue = Just (Just "x") }
                            , { dtSelCol | filterOptionValues = Just [ "never" ] }
                            ]
                        , filterStates = [ ( "address", DataTable.FilterMany [ "Sidney" ] ) ]
                    }
                )
           , eq "dt mergedFilterStates: filterOptionValue = Just Nothing is upstream's CONTROLLED null — it overrides the uncontrolled value (:105)"
                [ ( "address", DataTable.FilterNull ) ]
                (DataTable.mergedFilterStates
                    { dtOpts
                        | columns = [ { dtFilterCol | filterOptionValue = Just Nothing } ]
                        , filterStates = [ ( "address", DataTable.FilterMany [ "Sidney" ] ) ]
                    }
                )
           , eq "dt filtersAfterChange: createFilterState over the MERGED map — the emit carries sibling controlled values too (FilterButton.tsx :21/:81)"
                [ ( "address", DataTable.FilterMany [ "London", "Sidney" ] ), ( "name", DataTable.FilterOne "x" ) ]
                (DataTable.filtersAfterChange
                    { dtOpts
                        | columns =
                            [ { dtNameCol | filterOptionValue = Just (Just "x") }
                            , dtFilterCol
                            ]
                        , filterStates = [ ( "address", DataTable.FilterMany [ "Sidney" ] ) ]
                    }
                    dtFilterCol
                    (DataTable.FilterMany [ "London", "Sidney" ])
                )
           , eq "dt shouldUseArrayInSingleMode: controlled filterOptionValues (EVEN []) OR defaultFilterOptionValues without a controlled single (utils.ts :107-113)"
                [ True, False, True, False, True ]
                (List.map DataTable.shouldUseArrayInSingleMode
                    [ { dtFilterCol | filterOptionValues = Just [] }
                    , { dtFilterCol | filterOptionValues = Nothing, filterOptionValue = Just (Just "x") }
                    , { dtFilterCol | defaultFilterOptionValues = Just [] }
                    , { dtFilterCol | defaultFilterOptionValues = Just [], filterOptionValue = Just (Just "x") }
                    , { dtFilterCol | defaultFilterOptionValues = Just [ "a" ], filterOptionValues = Just [ "b" ] }
                    ]
                )
           , eq "dt isColumnFilterable: filter AND filterOptions set — `Just []` is TRUTHY (upstream's !![]), an unset filter or unset options is not (utils.ts)"
                [ True, False, False ]
                (List.map DataTable.isColumnFilterable
                    [ { dtFilterCol | filterOptions = Just [] }
                    , { dtFilterCol | filterOptions = Nothing }
                    , { dtFilterCol | filter = Nothing }
                    ]
                )
           , eq "dt filteredData: or-mode multi — a row passes on ANY active value (use-table-data.ts :169-176; the spec :616 Sidney+New York shape)"
                [ "John Brown", "Joe Black" ]
                (List.map .name
                    (DataTable.filteredData
                        { dtOpts
                            | columns =
                                [ dtNameCol
                                , { dtFilterCol | filterMode = DataTable.FilterOr }
                                ]
                            , filterStates = [ ( "address", DataTable.FilterMany [ "Sidney", "New York" ] ) ]
                        }
                    )
                )
           , eq "dt filteredData: and-mode — a row passes only if NO active value fails (:158-167)"
                []
                (List.map .name
                    (DataTable.filteredData
                        { dtOpts
                            | columns = [ dtNameCol, { dtFilterCol | filterMode = DataTable.FilterAnd } ]
                            , filterStates = [ ( "address", DataTable.FilterMany [ "Sidney", "New York" ] ) ]
                        }
                    )
                )
           , eq "dt filteredData: FilterNull and the empty array SKIP the column — everything passes (:144-151)"
                [ "John Brown", "Jim Green", "Joe Black" ]
                (List.map .name
                    (DataTable.filteredData
                        { dtOpts
                            | columns = [ dtNameCol, dtFilterCol ]
                            , filterStates = [ ( "address", DataTable.FilterNull ), ( "age", DataTable.FilterMany [] ) ]
                        }
                    )
                )
           , eq "dt filteredData: a single value wraps into the walk's one-element array (:147-149)"
                [ "Jim Green" ]
                (List.map .name
                    (DataTable.filteredData
                        { dtOpts
                            | columns = [ dtNameCol, dtFilterCol ]
                            , filterStates = [ ( "address", DataTable.FilterOne "London" ) ]
                        }
                    )
                )
           , eq "dt filteredData: 'default' is the substring filter over row[key] — indexOf semantics, not equality (:121-123)"
                [ "Jim Green" ]
                (List.map .name
                    (DataTable.filteredData
                        { dtOpts
                            | columns =
                                [ dtNameCol
                                , { dtFilterCol | filter = Just (DataTable.FilterDefault .address) }
                                ]
                            , filterStates = [ ( "address", DataTable.FilterOne "don No" ) ]
                        }
                    )
                )
           , eq "dt filteredData: filter = true (async) tracks state but never filters — the typeof gate (:152-157)"
                [ "John Brown", "Jim Green", "Joe Black" ]
                (List.map .name
                    (DataTable.filteredData
                        { dtOpts
                            | columns = [ dtNameCol, { dtFilterCol | filter = Just DataTable.FilterAsync } ]
                            , filterStates = [ ( "address", DataTable.FilterMany [ "London" ] ) ]
                        }
                    )
                )
           , eq "dt filteredData → sortedData: the pipeline reads filtered BEFORE sort (use-table-data.ts :192; the spec :349-360 shape)"
                [ "Jim Green", "Joe Black" ]
                (List.map .name
                    (DataTable.sortedData
                        { dtOpts
                            | columns =
                                [ dtNameCol
                                , dtAgeCol
                                , dtFilterCol
                                ]
                            , filterStates = [ ( "address", DataTable.FilterMany [ "London", "Sidney" ] ) ]
                            , sortStates =
                                [ { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) }
                                ]
                        }
                    )
                )
           , eq "dt filteredData: selection / expand columns never enter the walk even with state under their sentinel key (:125-136)"
                [ "John Brown", "Jim Green", "Joe Black" ]
                (List.map .name
                    (DataTable.filteredData
                        { dtOpts
                            | columns = [ dtSelCol, dtNameCol, dtFilterCol ]
                            , filterStates = [ ( "__n_selection__", DataTable.FilterMany [ "London" ] ) ]
                        }
                    )
                )
           ]
        ++ -- Group headers / summary / merge (use-group-header.ts
           -- `getRowsAndCols` two-pass walk + the Body.tsx summary/merge
           -- seams) — batch 6. The eq pins walk the pure helpers
           -- (`leafColumns`, `headerRows`, `fixedColumnLeftMap`) over the
           -- spec `:1360` / `:1113` fixtures; expectations derived from the
           -- upstream bytes (tasks/recon/data-table-b6-pins.md), NOT the
           -- port output.
           [ eq "dt leafColumns: a group column yields its LEAVES in walk order, the group itself never (spec :1360 name/age>test1,test2)"
                [ "name", "test1", "test2" ]
                (List.map .key (DataTable.leafColumns dtGroupCols))
           , eq "dt leafColumns: children = Just [] is a group with NO leaves — it contributes nothing and is not itself a leaf (use-group-header pass 1)"
                []
                (List.map .key (DataTable.leafColumns dtEmptyGroupCols))
           , eq "dt headerRows: the spec :1360 group matrix — row0 name{colSpan1,rowSpan2,isLast False} age{colSpan2,rowSpan1,isLast True}, row1 test1{1,1,False} test2{1,1,True} (leaf rowSpan = maxDepth-depth+1)"
                [ [ ( 0, 1, ( 2, False ) ), ( 1, 2, ( 1, True ) ) ], [ ( 1, 1, ( 1, False ) ), ( 2, 1, ( 1, True ) ) ] ]
                (List.map (List.map (\c -> ( c.colIndex, c.colSpan, ( c.rowSpan, c.isLast ) ))) (DataTable.headerRows dtGroupCols))
           , eq "dt headerRows: the spec :1360 group matrix — the per-cell column keys in push order (post-order group lands after its children)"
                [ [ "name", "age" ], [ "test1", "test2" ] ]
                (List.map (List.map (\c -> c.column.key)) (DataTable.headerRows dtGroupCols))
           , eq "dt headerRows: titleColSpan swallows the covered leaf — a{colSpan2,isLast False (0+2=2≠3)}, c{colSpan1,isLast True (2+1=3)}; b yields NO cell (hideUntilIndex covers index 1)"
                [ [ ( 0, 2, ( 1, False ) ), ( 2, 1, ( 1, True ) ) ] ]
                (List.map (List.map (\c -> ( c.colIndex, c.colSpan, ( c.rowSpan, c.isLast ) ))) (DataTable.headerRows dtTitleSpanCols))
           , eq "dt headerRows: titleColSpan swallow — b is absent from the emitted keys (only a and c render)"
                [ [ "a", "c" ] ]
                (List.map (List.map (\c -> c.column.key)) (DataTable.headerRows dtTitleSpanCols))
           , eq "dt headerRows: children = Just [] edge — x{colIndex 0, colSpan 0, rowSpan 1, isLast True (0+0==0 totalRowSpan 0)}; the phantom empty rows[1] survives (use-group-header ensureMaxDepth enters depth 1)"
                [ [ ( 0, 0, ( 1, True ) ) ], [] ]
                (List.map (List.map (\c -> ( c.colIndex, c.colSpan, ( c.rowSpan, c.isLast ) ))) (DataTable.headerRows dtEmptyGroupCols))
           , eq "dt fixedColumnLeftMap over a grouped column set — the walk is over the LEAVES (nested fixed `a` start 0, flat `c` start 100); the group `g` never joins (b4 formula)"
                [ ( "a", 0 ), ( "c", 100 ) ]
                (DataTable.fixedColumnLeftMap dtGroupFixedCols)

           -- DATE-PICKER / TIME-PICKER — pins derived from date-picker/src/panel/*
           -- + utils.ts + DatePicker.tsx + time-picker/src/* + date-fns v2 ground
           -- truth. Expectations: tasks/recon/date-picker-pins.md.
           -- =====================================================================
           , eq "dp P1.1 engine format yyyy-MM-dd @ 2024-05-09T23:33:20Z"
                "2024-05-09"
                (DT.format "yyyy-MM-dd" Time.utc dpTSA)
           , eq "dp P1.2 engine format yyyy-MM-dd HH:mm:ss @ TS_A"
                "2024-05-09 23:33:20"
                (DT.format "yyyy-MM-dd HH:mm:ss" Time.utc dpTSA)
           , eq "dp P1.3 MMM @ TS_A" "May" (DT.format "MMM" Time.utc dpTSA)
           , eq "dp P1.4 eeeeee @ TS_A (date-fns short weekday)" "Th" (DT.format "eeeeee" Time.utc dpTSA)
           , eq "dp P1.5 yyyy-qqq @ TS_A" "2024-Q2" (DT.format "yyyy-qqq" Time.utc dpTSA)
           , eq "dp P1.6 yy @ TS_A" "24" (DT.format "yy" Time.utc dpTSA)
           , eq "dp P1.7 H @ TS_A (unpadded)" "23" (DT.format "H" Time.utc dpTSA)
           , eq "dp P1.8 HH @ TS_A (padded)" "23" (DT.format "HH" Time.utc dpTSA)
           , eq "dp P1.9 \"yyyy-'Q'Q\" @ TS_A (quoted literal Q + quarter)" "2024-Q2" (DT.format "yyyy-'Q'Q" Time.utc dpTSA)
           , eq "dp P1.10 yyyy-MM-dd @ 2024-01-01T00:00Z" "2024-01-01" (DT.format "yyyy-MM-dd" Time.utc dpTSB)
           , eq "dp P1.11 datetime @ TS_B" "2024-01-01 00:00:00" (DT.format "yyyy-MM-dd HH:mm:ss" Time.utc dpTSB)
           , eq "dp P1.12 MMM @ TS_B" "Jan" (DT.format "MMM" Time.utc dpTSB)
           , eq "dp P1.13 eeeeee @ TS_B" "Mo" (DT.format "eeeeee" Time.utc dpTSB)
           , eq "dp P1.14 H @ TS_B (unpadded zero)" "0" (DT.format "H" Time.utc dpTSB)
           , eq "dp P1.15 HH @ TS_B (padded zero)" "00" (DT.format "HH" Time.utc dpTSB)
           , eq "dp P1.16 yyyy-qqq @ TS_B" "2024-Q1" (DT.format "yyyy-qqq" Time.utc dpTSB)
           , eq "dp P1.17 YYYY-w @ TS_B (fwcd=1/wso=0)" "2024-1" (DT.format "YYYY-w" Time.utc dpTSB)
           , eq "dp P1.18 YYYY-w near the year boundary (fwcd=1/wso=0, date-fns enUS ground truth): 2004-12-31→2005-1, 2005-01-01→2005-1, 2005-01-02→2005-2, 2004-01-01→2004-1 [oracle S2]"
                [ "2005-1", "2005-1", "2005-2", "2004-1" ]
                [ DT.format "YYYY-w" Time.utc dpD2004
                , DT.format "YYYY-w" Time.utc dpJan2005
                , DT.format "YYYY-w" Time.utc dpJan2005b
                , DT.format "YYYY-w" Time.utc dpJan2004
                ]
           , eq "dp P6.4a weekNumber(2024-01-01) = 1 (ws=1)" 1 (DT.weekNumber 1 Time.utc dpTSB)
           , eq "dp P6.4b weekNumber(2004-01-01) = 1 (ws=1, fwcd=1) [oracle S2]" 1 (DT.weekNumber 1 Time.utc dpJan2004)
           , eq "dp P6.4c weekYear(2004-01-01) = 2004 (ws=1, fwcd=1) [oracle S2]" 2004 (DT.weekYear 1 Time.utc dpJan2004)
           , eq "dp P6.4d fwcd=1 rollover: weekNumber(2004-12-31) = 1 / weekYear = 2005 [oracle S2]"
                [ 1, 2005 ]
                [ DT.weekNumber 1 Time.utc dpD2004
                , DT.weekYear 1 Time.utc dpD2004
                ]

           -- S1 zone-consistent grid (oracle report §S1) — a UTC+8 caller
           , eq "dp S1.1 zone UTC+8: the 15th cell (caller's local civil day) is selected, the 14th is not"
                [ True, False ]
                [ dpCellSelected 1710460800000 dpZoneItems
                , dpCellSelected 1710374400000 dpZoneItems
                ]
           , eq "dp S1.2 zone UTC+8: exactly one selected cell, the local 2024-03-15 cell"
                [ 1710460800000 ]
                (List.filter .selected dpZoneItems |> List.map .ts)
           , eq "dp S1.3 zone UTC+8: isCurrentDate follows the caller's local civil day (local 2024-03-21 00:30 → the 21st, not the UTC 20th)"
                [ "True", "1" ]
                [ dpBool (dpCellFlag .isCurrentDate 1710979200000 dpZoneItems)
                , String.fromInt (List.filter .isCurrentDate dpZoneItems |> List.length)
                ]
           , eq "dp S1.4 zone UTC+8: clicking the 15th cell emits a ts whose local civil day is the 15th"
                (Just ( 2024, 3, 15 ))
                dpZoneClickCivil

           -- P2 strictParse
           , eq "dp P2.1 strictParse accepts '2024-05-09' @ yyyy-MM-dd"
                (Just dpMay09)
                (DT.strictParse "2024-05-09" "yyyy-MM-dd" Time.utc)
           , eq "dp P2.2 strictParse rejects '2024-02-30'" Nothing (DT.strictParse "2024-02-30" "yyyy-MM-dd" Time.utc)
           , eq "dp P2.3 strictParse rejects '2024-5-9' (round-trip mismatch)" Nothing (DT.strictParse "2024-5-9" "yyyy-MM-dd" Time.utc)
           , eq "dp P2.4 strictParse accepts '23:33:20' @ HH:mm:ss → epoch-day ts"
                (Just 84800000)
                (DT.strictParse "23:33:20" "HH:mm:ss" Time.utc)
           , eq "dp P2.5 strictParse rejects '23:33:20' @ HH:mm (no seconds token)" Nothing (DT.strictParse "23:33:20" "HH:mm" Time.utc)

           -- P3 dateArray
           , eq "dp P3.1 dateArray strip=False → 42 cells" 42 (List.length dpDateItems)
           , eq "dp P3.2 first cell ts = 2024-04-28 (Sunday)"
                (Just dpApr28)
                (List.head dpDateItems |> Maybe.map .ts)
           , eq "dp P3.3 last cell ts = 2024-06-08"
                (Just dpJun08)
                (List.reverse dpDateItems |> List.head |> Maybe.map .ts)
           , eq "dp P3.4 cell 2024-05-09 selected" True (dpCellSelected dpMay09 dpDateItems)
           , eq "dp P3.5 cells 2024-05-08 / 2024-05-10 not selected"
                [ False, False ]
                [ dpCellSelected (dpMay09 - 86400000) dpDateItems
                , dpCellSelected (dpMay09 + 86400000) dpDateItems
                ]
           , eq "dp P3.6 inCurrentMonth count = 31 (May 1..31)"
                31
                (List.filter .inCurrentMonth dpDateItems |> List.length)
           , eq "dp P3.7 isCurrentDate True only for 2024-05-09"
                [ "True", "1" ]
                [ dpBool (dpCellFlag .isCurrentDate dpMay09 dpDateItems)
                , String.fromInt (List.filter .isCurrentDate dpDateItems |> List.length)
                ]
           , eq "dp P3.8 weekMode: selected is False for every cell"
                []
                (List.filter .selected dpWeekItems |> List.map .ts)
           , eq "dp P3.9 weekMode: inSelectedWeek True for the 7 cells 2024-05-05..05-11"
                [ "True", "True", "True", "True", "True", "True", "True", "7" ]
                ([ 0, 1, 2, 3, 4, 5, 6 ]
                    |> List.map (\i -> dpBool (dpCellFlag .inSelectedWeek (dpMay05 + i * 86400000) dpWeekItems))
                    |> (\xs -> xs ++ [ String.fromInt (List.filter .inSelectedWeek dpWeekItems |> List.length) ])
                )

           -- P4 dual span flags
           , eq "dp P4.1 2024-05-01 startOfSpan True, inSpan False"
                [ True, False ]
                [ dpCellFlag .startOfSpan dpMayAnchor dpRangeItems
                , dpCellFlag .inSpan dpMayAnchor dpRangeItems
                ]
           , eq "dp P4.2 2024-05-11 endOfSpan True, inSpan False"
                [ True, False ]
                [ dpCellFlag .endOfSpan dpRangeEnd dpRangeItems
                , dpCellFlag .inSpan dpRangeEnd dpRangeItems
                ]
           , eq "dp P4.3 2024-05-02..05-10 all inSpan True (strict exclusive)"
                (List.repeat 9 True)
                (List.range 1 9 |> List.map (\i -> dpCellFlag .inSpan (dpMayAnchor + i * 86400000) dpRangeItems))
           , eq "dp P4.4 2024-05-01 & 2024-05-11 selected; 05-02..05-10 not"
                [ "True", "True", "0" ]
                [ dpBool (dpCellSelected dpMayAnchor dpRangeItems)
                , dpBool (dpCellSelected dpRangeEnd dpRangeItems)
                , String.fromInt (List.range 1 9 |> List.filter (\i -> dpCellSelected (dpMayAnchor + i * 86400000) dpRangeItems) |> List.length)
                ]

           -- P5 month / quarter / year arrays
           , eq "dp P5.1 monthArray 12 items, labels Jan..Dec (MMM)"
                [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]
                (DT.monthArray dpMayAnchor (DT.SingleTs dpTSA) dpTSA { monthFormat = "MMM" }
                    |> List.map (\m -> DT.format m.monthFormat Time.utc m.ts)
                )
           , eq "dp P5.2 monthArray first ts = 2024-01-01"
                (Just dpTSB)
                (DT.monthArray dpMayAnchor (DT.SingleTs dpTSA) dpTSA { monthFormat = "MMM" }
                    |> List.head
                    |> Maybe.map .ts
                )
           , eq "dp P5.3 quarterArray 4 items, labels Q1..Q4 (qqq)"
                [ "Q1", "Q2", "Q3", "Q4" ]
                (DT.quarterArray dpMayAnchor (DT.SingleTs dpTSA) dpTSA { quarterFormat = "qqq" }
                    |> List.map (\q -> DT.format q.quarterFormat Time.utc q.ts)
                )
           , eq "dp P5.4 quarterArray ts[1] = 2024-04-01 (Q2 start)"
                (Just dpApr01)
                (DT.quarterArray dpMayAnchor (DT.SingleTs dpTSA) dpTSA { quarterFormat = "qqq" }
                    |> List.drop 1
                    |> List.head
                    |> Maybe.map .ts
                )
           , eq "dp P5.5 yearArray (1901,2100) → 199 items (exclusive end), first 1901, last 2099"
                [ 199, 1901, 2099 ]
                (let
                    ys =
                        DT.yearArray (DT.SingleTs dpY1999) dpTSA { yearFormat = "yyyy" } ( 1901, 2100 )
                 in
                 [ List.length ys
                 , List.head ys |> Maybe.map (\y -> y.dateObject.year) |> Maybe.withDefault 0
                 , List.reverse ys |> List.head |> Maybe.map (\y -> y.dateObject.year) |> Maybe.withDefault 0
                 ]
                )
           , eq "dp P5.6 yearArray selected only for 1999"
                [ 1999 ]
                (DT.yearArray (DT.SingleTs dpY1999) dpTSA { yearFormat = "yyyy" } ( 1901, 2100 )
                    |> List.filter .selected
                    |> List.map (\y -> y.dateObject.year)
                )

           -- P6 civil math
           , eq "dp P6.1 addMonthsClamped 2024-01-31 +1 → 2024-02-29"
                { year = 2024, month = 2, day = 29 }
                (DT.addMonthsClamped 1 { year = 2024, month = 1, day = 31 })
           , eq "dp P6.2 setFields month→3 on 2024-02-29 keeps day → 2024-03-29"
                { year = 2024, month = 3, day = 29 }
                (DT.toCivil Time.utc (DT.setFields Time.utc dpFeb29 { dpNoFields | month = Just 3 }))
           , eq "dp P6.3 setFields month→2 on 2024-01-31 clamps → 2024-02-29"
                { year = 2024, month = 2, day = 29 }
                (DT.toCivil Time.utc (DT.setFields Time.utc dpJan31 { dpNoFields | month = Just 2 }))
           , eq "dp P6.5 firstDayOfWeekToDateFns 6 = 0" 0 (DT.firstDayOfWeekToDateFns 6)

           -- P7 TimePicker pure helpers
           , eq "tp P7.1 formatValue HH:mm:ss @ TS_A" "23:33:20" (TimePicker.formatValue "HH:mm:ss" Time.utc dpTSA)
           , eq "tp P7.2 parseInput '23:33:20' @ HH:mm:ss → epoch-day ts"
                (Just 84800000)
                (TimePicker.parseInput "HH:mm:ss" Time.utc "23:33:20")
           , eq "tp P7.2b parseInput then formatValue reproduces the string"
                (Just "23:33:20")
                (TimePicker.parseInput "HH:mm:ss" Time.utc "23:33:20"
                    |> Maybe.map (TimePicker.formatValue "HH:mm:ss" Time.utc)
                )
           , eq "tp P7.3 snapNow minutes StepUnits 15: 23:33:20 → 23:30:20 (nearest, ties→lower)"
                (dpTSA - 180000)
                (TimePicker.snapNow "HH:mm:ss" Time.utc (Time.millisToPosix dpTSA) TimePicker.AllUnits (TimePicker.StepUnits 15) TimePicker.AllUnits)
           , eq "tp P7.4 snapNow hours OnlyUnits [0,12]: 23 → 12"
                (dpTSA - 39600000)
                (TimePicker.snapNow "HH:mm:ss" Time.utc (Time.millisToPosix dpTSA) (TimePicker.OnlyUnits [ 0, 12 ]) TimePicker.AllUnits TimePicker.AllUnits)

           -- P8 default action tables
           , eq "dp P8.1 date, clearable=False → [Now]" [ DatePicker.Now ] (DatePicker.defaultActions DatePicker.Date False)
           , eq "dp P8.2 date, clearable=True → [Clear, Now]" [ DatePicker.Clear, DatePicker.Now ] (DatePicker.defaultActions DatePicker.Date True)
           , eq "dp P8.3 datetime → [Now, Confirm]" [ DatePicker.Now, DatePicker.Confirm ] (DatePicker.defaultActions DatePicker.Datetime False)
           , eq "dp P8.4 daterange → [Confirm]" [ DatePicker.Confirm ] (DatePicker.defaultActions DatePicker.Daterange False)
           , eq "dp P8.5 datetimerange, clearable=True → [Clear, Confirm]" [ DatePicker.Clear, DatePicker.Confirm ] (DatePicker.defaultActions DatePicker.Datetimerange True)
           , eq "dp P8.6 month → [Now, Confirm]" [ DatePicker.Now, DatePicker.Confirm ] (DatePicker.defaultActions DatePicker.Month False)
           , eq "dp P8.7 year → [Now]" [ DatePicker.Now ] (DatePicker.defaultActions DatePicker.Year False)
           , eq "dp P8.8 quarter → [Now, Confirm]" [ DatePicker.Now, DatePicker.Confirm ] (DatePicker.defaultActions DatePicker.Quarter False)
           , eq "dp P8.9 monthrange → [Confirm]" [ DatePicker.Confirm ] (DatePicker.defaultActions DatePicker.Monthrange False)
           , eq "dp P8.10 week → [Now]" [ DatePicker.Now ] (DatePicker.defaultActions DatePicker.Week False)

           -- P9 sanitizeValue (ts TS_A, zone UTC)
           , eq "dp P9 sanitizeValue → exact ms per panel type"
                [ 1715297600000, 1714521600000, 1704067200000, 1711929600000, 1714867200000, 1715212800000, 1715212800000, 1714521600000, 1715297600000 ]
                [ DatePicker.sanitizeValue DatePicker.Datetime dpTSA
                , DatePicker.sanitizeValue DatePicker.Month dpTSA
                , DatePicker.sanitizeValue DatePicker.Year dpTSA
                , DatePicker.sanitizeValue DatePicker.Quarter dpTSA
                , DatePicker.sanitizeValue DatePicker.Week dpTSA
                , DatePicker.sanitizeValue DatePicker.Date dpTSA
                , DatePicker.sanitizeValue DatePicker.Daterange dpTSA
                , DatePicker.sanitizeValue DatePicker.Monthrange dpTSA
                , DatePicker.sanitizeValue DatePicker.Datetimerange dpTSA
                ]

           -- P10 singleDateClick
           , eq "dp P10.1 date click 2024-05-20 → value, close True"
                { value = DatePicker.Single (Just dpMay20), close = True }
                (DatePicker.singleDateClick
                    { type_ = DatePicker.Date
                    , value = DatePicker.Single (Just dpTSB)
                    , target = dpClickTarget
                    , isDisabled = False
                    , defaultTime = Nothing
                    , now = dpMayAnchor
                    , zone = Time.utc
                    }
                )
           , eq "dp P10.2 month click 2024-05-20 → startOfMonth, close False"
                { value = DatePicker.Single (Just dpMayAnchor), close = False }
                (DatePicker.singleDateClick
                    { type_ = DatePicker.Month
                    , value = DatePicker.Single (Just dpTSB)
                    , target = dpClickTarget
                    , isDisabled = False
                    , defaultTime = Nothing
                    , now = dpTSB
                    , zone = Time.utc
                    }
                )
           , eq "dp P10.3 datetime click + DefaultSingle '03:04:05' → time applied"
                { value = DatePicker.Single (Just 1716174245000), close = False }
                (DatePicker.singleDateClick
                    { type_ = DatePicker.Datetime
                    , value = DatePicker.Single (Just dpTSB)
                    , target = dpClickTarget
                    , isDisabled = False
                    , defaultTime = Just (DatePicker.DefaultSingle "03:04:05")
                    , now = dpTSB
                    , zone = Time.utc
                    }
                )

           -- P11 dual interactions
           , eq "dp P11.1 first dualDateClick → [t,t], selecting True"
                { value = DatePicker.Range (Just ( dpMayAnchor, dpMayAnchor )), selecting = True, close = False, confirm = False }
                (DatePicker.dualDateClick
                    { value = DatePicker.Single Nothing
                    , selecting = False
                    , type_ = DatePicker.Daterange
                    , closeOnSelect = False
                    , updateValueOnClose = False
                    }
                    dpMayAnchor
                )
           , eq "dp P11.2 second dualDateClick → selecting False, value kept"
                { value = DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd )), selecting = False, close = False, confirm = False }
                (DatePicker.dualDateClick
                    { value = DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd ))
                    , selecting = True
                    , type_ = DatePicker.Daterange
                    , closeOnSelect = False
                    , updateValueOnClose = False
                    }
                    dpRangeEnd
                )
           , eq "dp P11.3 dualHover reversed → normalized [min,max]"
                (Just (DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd ))))
                (DatePicker.dualHover
                    { value = DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd ))
                    , selecting = True
                    , memorizedStart = Just dpRangeEnd
                    , disabled = False
                    }
                    dpMayAnchor
                )
           , eq "dp P11.5 colItemClick: start item after end collapses; end item before start collapses"
                [ DatePicker.Range (Just ( dpMay20, dpMay20 )), DatePicker.Range (Just ( dpApr01, dpApr01 )) ]
                [ DatePicker.colItemClick DatePicker.Daterange (DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd ))) dpMay20 DatePicker.RangeStart
                , DatePicker.colItemClick DatePicker.Daterange (DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd ))) dpApr01 DatePicker.RangeEnd
                ]
           ]



-- VIEW -------------------------------------------------------------------------


view : Int -> Html Msg
view count =
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
        , Html.div [ HA.id "dropdown-click-count" ] [ Html.text (String.fromInt count) ]
        , Html.div [ HA.id "preview-close-count" ] [ Html.text (String.fromInt count) ]
        , Html.div [ HA.id "message-close-count" ] [ Html.text (String.fromInt count) ]
        , Html.div [ HA.id "notification-close-count" ] [ Html.text (String.fromInt count) ]
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

                -- Switch loading (the knob's NBaseLoading seam; RED until the
                -- loading-svg batch replaces the data-URI background with the
                -- true inline svg chain)
                , Element.el [ Element.htmlAttribute (HA.id "live-switch-loading") ]
                    (Switch.view Theme.default { swD | loading = True } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-switch-spinprops") ]
                    (Switch.view Theme.default { swD | loading = True, spinStrokeWidth = Just 6, spinStroke = Just "#ff0000" } [])
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
                , Element.el [ Element.htmlAttribute (HA.id "live-anchor") ]
                    (Anchor.view Theme.default Anchor.defaults anchorLiveLinks)
                , Element.el [ Element.htmlAttribute (HA.id "live-anchor-active") ]
                    (Anchor.view Theme.default
                        { anchorLiveOpts | activeHref = Just "#basic" }
                        anchorLiveLinks
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-anchor-block") ]
                    (Anchor.view Theme.default
                        { anchorLiveOpts | type_ = Anchor.Block }
                        anchorLiveLinks
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-anchor-norail") ]
                    (Anchor.view Theme.default
                        { anchorLiveOpts | showRail = False }
                        anchorLiveLinks
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-anchor-nobg") ]
                    (Anchor.view Theme.default
                        { anchorLiveOpts | showBackground = False, activeHref = Just "#demos" }
                        anchorLiveLinks
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-anchor-edge") ]
                    (Anchor.view Theme.default
                        { anchorLiveOpts | activeHref = Just "" }
                        anchorEdgeLinks
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-anchor-affix") ]
                    (Anchor.view Theme.default
                        { anchorLiveOpts
                            | affix = Just { affixLiveOpts | position = Affix.Fixed, top = Just 88 }
                        }
                        anchorLiveLinks
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-anchor-scrollable") ]
                    (Anchor.view Theme.default
                        { anchorLiveOpts | internalScrollable = True }
                        anchorLiveLinks
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer") ]
                    (Transfer.view Theme.default
                        { transferLiveOpts
                            | options = transferOptions
                            , value = [ "2" ]
                            , sourceTitle = Just "Source"
                            , targetTitle = Just "Target"
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer-large") ]
                    (Transfer.view Theme.default
                        { transferLiveOpts
                            | options = transferOptions
                            , value = [ "1", "4" ]
                            , size = T.Large
                            , sourceFilterable = True
                            , targetFilterable = True
                            , sourceFilterPlaceholder = Just "Search"
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer-disabled") ]
                    (Transfer.view Theme.default
                        { transferLiveOpts | options = transferOptions, value = [ "2" ], disabled = True }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer-empty") ]
                    (Transfer.view Theme.default { transferLiveOpts | options = [], value = [] })
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer-allchecked") ]
                    (Transfer.view Theme.default
                        { transferLiveOpts | options = transferOptions, value = [ "1", "2", "3", "4" ] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer-missing") ]
                    (Transfer.view Theme.default
                        { transferLiveOpts | options = transferOptions, value = [ "2", "999" ] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer-dup") ]
                    (Transfer.view Theme.default
                        { transferLiveOpts
                            | options =
                                [ { label = "First", value = "d1", disabled = False }
                                , { label = "Last", value = "d1", disabled = False }
                                ]
                            , value = [ "d1" ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer-nolabel") ]
                    (Transfer.view Theme.default
                        { transferLiveOpts
                            | options = [ { label = "", value = "e1", disabled = False } ]
                            , value = []
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-transfer-edge") ]
                    (Transfer.view Theme.default
                        { transferLiveOpts
                            | options =
                                [ { label = "", value = "e1", disabled = False }
                                , { label = "Option 2", value = "e2", disabled = False }
                                , { label = "Option 3", value = "e3", disabled = False }
                                ]
                            , value = [ "e2", "999" ]
                            , showSelected = False
                            , sourceFilterable = True
                            , targetFilterable = True
                            , sourcePattern = "Option 2"
                            , targetPattern = "Option 3"
                            , selectAllText = Just "Pick all"
                            , clearText = Just "Drop all"
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select") ]
                    (Element.column [ Element.spacing 8 ]
                        [ TreeSelect.view Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , value = SelectMenu.Single (Just "o1-1")
                                , pendingKey = Just "o1-1"
                                , expandedKeys = [ "o1", "o1-1" ]
                            }
                        , TreeSelect.menu Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , value = SelectMenu.Single (Just "o1-1")
                                , pendingKey = Just "o1-1"
                                , expandedKeys = [ "o1", "o1-1" ]
                            }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-multiple") ]
                    (Element.column [ Element.spacing 8 ]
                        [ TreeSelect.view Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , multiple = True
                                , checkable = True
                                , cascade = True
                                , value = SelectMenu.Multiple [ "o1-1", "o2" ]
                            }
                        , TreeSelect.menu Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , multiple = True
                                , checkable = True
                                , cascade = True
                                , value = SelectMenu.Multiple [ "o1-1", "o2" ]
                                , expandedKeys = [ "o1" ]
                            }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-filterable") ]
                    (Element.column [ Element.spacing 8 ]
                        [ TreeSelect.view Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , filterable = True
                                , pattern = "eft"
                                , expandedKeys = [ "o1" ]
                            }
                        , TreeSelect.menu Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , filterable = True
                                , pattern = "eft"
                                , expandedKeys = [ "o1" ]
                            }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-showpath") ]
                    (Element.column [ Element.spacing 8 ]
                        [ TreeSelect.view Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , showPath = True
                                , value = SelectMenu.Single (Just "o1-3")
                                , expandedKeys = [ "o1", "o1-1" ]
                            }
                        , TreeSelect.menu Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , showPath = True
                                , value = SelectMenu.Single (Just "o1-3")
                                , expandedKeys = [ "o1", "o1-1" ]
                            }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-slots") ]
                    (Element.column [ Element.spacing 8 ]
                        [ TreeSelect.view Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , header = Just (Element.text "Header slot")
                                , action = Just (Element.text "Action slot")
                                , empty = Just (Element.text "No data")
                            }
                        , TreeSelect.menu Theme.default
                            { treeSelectLiveOpts
                                | options = []
                                , header = Just (Element.text "Header slot")
                                , action = Just (Element.text "Action slot")
                                , empty = Just (Element.text "No data")
                            }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-empty-filter") ]
                    (Element.column [ Element.spacing 8 ]
                        [ TreeSelect.view Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , filterable = True
                                , pattern = "zzz"
                            }
                        , TreeSelect.menu Theme.default
                            { treeSelectLiveOpts
                                | options = treeSelectOptions
                                , filterable = True
                                , pattern = "zzz"
                                , expandedKeys = [ "o1" ]
                            }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-maxtagcount") ]
                    (TreeSelect.view Theme.default
                        { treeSelectLiveOpts
                            | options = treeSelectOptions
                            , multiple = True
                            , checkable = True
                            , cascade = True
                            , value = SelectMenu.Multiple [ "o1", "o2" ]
                            , maxTagCount = Just 2
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-disabled") ]
                    (TreeSelect.view Theme.default
                        { treeSelectLiveOpts
                            | options = treeSelectOptions
                            , disabled = True
                            , clearable = True
                            , hover = True
                            , value = SelectMenu.Single (Just "o2")
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-status") ]
                    (TreeSelect.view Theme.default
                        { treeSelectLiveOpts
                            | options = treeSelectOptions
                            , status = Just BaseSelection.Error
                            , value = SelectMenu.Single (Just "o2")
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-select-childstrategy") ]
                    (TreeSelect.menu Theme.default
                        { treeSelectLiveOpts
                            | options = treeSelectOptions
                            , checkable = True
                            , checkStrategy = Tree.Child
                            , expandedKeys = [ "o1", "o1-1" ]
                        }
                    )
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
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-card-justify") ]
                    (Tabs.view Theme.default tCardJustifyOpts ttabs)
                , Element.el [ Element.htmlAttribute (HA.id "live-tabs-addable-class") ]
                    (Tabs.view Theme.default tAddableClassOpts ttabs)

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

                -- Dropdown (the body IS the `n-dropdown-menu`; the host wrapper
                -- carries the default bottom placement)
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-default"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dD dStructureOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-small"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dSmallOpts [ dLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-inverted"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dInvertedOpts [ dLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-arrow"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dArrowOpts [ dLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-overlap-arrow"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dOverlapArrowOpts [ dLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-scrollable"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dScrollableOpts [ dLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-transition"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dTransitionOpts [ dLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-subtransition"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dSubTransitionOpts [ dLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-flags"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dD dFlagsOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-groupicon"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dD dGroupIconOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-groupnest"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dD dNestedGroupOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-value"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dValueOpts dValueOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-childvalue"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dChildValueOpts dValueOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-select"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dSelectOpts dSelectOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-empty"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.default dD [])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-dark"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.dark dD [ dLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-dropdown-dark-inverted"), Dropdown.placementAttribute dD.placement ]
                    (Dropdown.view Theme.dark dInvertedOpts [ dLeaf "a" "A" ])

                -- Modal (the mount-body family: container > mask + body-wrapper >
                -- scrollbar > content, self-positioning; the fixed positioning is
                -- irrelevant to the DOM probes)
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-custom") ]
                    (Modal.view Theme.default
                        { mD | show = True }
                        (Modal.Custom [ Element.htmlAttribute (HA.id "modal-custom-content") ]
                            [ Element.text "Custom body" ]
                        )
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-zindex") ]
                    (Modal.view Theme.default
                        { mD | show = True, zIndex = Just 100 }
                        (Modal.Custom [] [ Element.text "Z" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-nomask") ]
                    (Modal.view Theme.default
                        { mD | show = True, showMask = False }
                        (Modal.Custom [] [ Element.text "No mask" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-hidden") ]
                    (Modal.view Theme.default mD (Modal.Custom [] [ Element.text "Hidden" ]))
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-mask-leave") ]
                    (Modal.view Theme.default
                        { mD | maskTransition = Just Internal.LeaveActive }
                        (Modal.Custom [] [ Element.text "Mask leave" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-body-leave") ]
                    (Modal.view Theme.default
                        { mD | bodyTransition = Just Internal.LeaveTo }
                        (Modal.Custom [] [ Element.text "Body leave" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-mask-enter") ]
                    (Modal.view Theme.default
                        { mD | show = True, maskTransition = Just Internal.EnterActive }
                        (Modal.Custom [] [ Element.text "Mask enter" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-body-enter") ]
                    (Modal.view Theme.default
                        { mD | show = True, bodyTransition = Just Internal.EnterFrom }
                        (Modal.Custom [] [ Element.text "Body enter" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-card") ]
                    (Modal.view Theme.default
                        { mD | show = True }
                        (Modal.Card
                            { mCardD
                                | title = Just (Element.text "Card title")
                                , closable = True
                                , onClose = Just ModalClose
                                , attributes = [ Element.htmlAttribute (HA.attribute "data-card-extra" "on") ]
                            }
                            [ Element.text "Card body" ]
                        )
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-card-bordered") ]
                    (Modal.view Theme.default
                        { mD | show = True }
                        (Modal.Card { mCardD | bordered = True } [ Element.text "Bordered" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-card-role") ]
                    (Modal.view Theme.default
                        { mD | show = True }
                        (Modal.Card { mCardD | role = Just "region" } [ Element.text "Role" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-card-phase") ]
                    (Modal.view Theme.default
                        { mD | show = True, bodyTransition = Just Internal.EnterFrom }
                        (Modal.Card mCardD [ Element.text "Phased card" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-card-phase-extra") ]
                    (Modal.view Theme.default
                        { mD | show = True, bodyTransition = Just Internal.EnterFrom }
                        (Modal.Card { mCardD | extraClasses = [ "caller-x" ] } [ Element.text "Phased + caller class" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-dark") ]
                    (Modal.view Theme.dark
                        { mD | show = True }
                        (Modal.Custom [] [ Element.text "Dark" ])
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-card-seam") ]
                    (Card.view Theme.default mCardSeamOpts [ Element.text "Seam" ])

                -- Drawer (the mount-body sibling: container > mask + unclassed
                -- host > .n-drawer > content seam; the fixed positioning is
                -- irrelevant to the DOM probes)
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-default") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Right, width = Just "200px" }
                        [ DrawerContent.view Theme.default
                            { drContentD | title = Just (Element.text "Title"), closable = True, onClose = Just DrawerClose, footer = Just (Element.text "Footer") }
                            [ Element.text "Body" ]
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-left") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Left }
                        [ DrawerContent.view Theme.default drContentD [ Element.text "Left" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-top") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Top, height = Just "120px" }
                        [ DrawerContent.view Theme.default drContentD [ Element.text "Top" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-bottom") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Bottom }
                        [ DrawerContent.view Theme.default drContentD [ Element.text "Bottom" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-mask-transparent") ]
                    (Drawer.view Theme.default
                        { drD | show = True, showMask = Drawer.Transparent }
                        [ DrawerContent.view Theme.default drContentD [ Element.text "T" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-mask-hidden") ]
                    (Drawer.view Theme.default
                        { drD | show = True, showMask = Drawer.Hidden }
                        [ DrawerContent.view Theme.default drContentD [ Element.text "H" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-hidden") ]
                    (Drawer.view Theme.default drD [ Element.text "Hidden" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-mask-leave") ]
                    (Drawer.view Theme.default
                        { drD | maskTransition = Just Internal.LeaveActive }
                        [ Element.text "Mask leave" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-body-leave") ]
                    (Drawer.view Theme.default
                        { drD | bodyTransition = Just Internal.LeaveTo }
                        [ Element.text "Body leave" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-phase") ]
                    (Drawer.view Theme.default
                        { drD
                            | show = True
                            , placement = Drawer.Left
                            , maskTransition = Just Internal.EnterActive
                            , bodyTransition = Just Internal.EnterFrom
                        }
                        [ Element.text "Phased" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-phase-right") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Right, bodyTransition = Just Internal.LeaveFrom }
                        [ Element.text "Phased right" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-phase-top") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Top, bodyTransition = Just Internal.EnterActive }
                        [ Element.text "Phased top" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-phase-bottom") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Bottom, bodyTransition = Just Internal.EnterActive }
                        [ Element.text "Phased bottom" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-zindex") ]
                    (Drawer.view Theme.default
                        { drD | show = True, zIndex = Just 100 }
                        [ Element.text "Z" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-left-height") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Left, height = Just "77px" }
                        [ Element.text "LH" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-top-width") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Top, width = Just "99px" }
                        [ Element.text "TW" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-defaultwidth") ]
                    (Drawer.view Theme.default
                        { drD | show = True, placement = Drawer.Right, defaultWidth = "300px" }
                        [ Element.text "DW" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-zindex0") ]
                    (Drawer.view Theme.default
                        { drD | show = True, zIndex = Just 0 }
                        [ Element.text "Z0" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-rtl") ]
                    (Drawer.view Theme.default
                        { drD | show = True, rtl = True }
                        [ Element.text "RTL" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-unselectable") ]
                    (Drawer.view Theme.default
                        { drD | show = True, rtl = True, unselectable = True }
                        [ Element.text "U" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-resizable") ]
                    (Drawer.view Theme.default
                        { drD | show = True, resizable = True, showResizeTriggerHover = True }
                        [ Element.text "R" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-resizable-plain") ]
                    (Drawer.view Theme.default
                        { drD | show = True, resizable = True }
                        [ Element.text "R2" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-nonnative") ]
                    (Drawer.view Theme.default
                        { drD
                            | show = True
                            , nativeScrollbar = False
                            , contentClass = Just "cw-x"
                            , contentStyle = Just "color:green"
                        }
                        [ Element.text "Non-native" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-contentclass") ]
                    (Drawer.view Theme.default
                        { drD | show = True, contentClass = Just "cw-y", contentStyle = Just "color:orange" }
                        [ Element.text "Native + contentClass" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-maskclick") ]
                    (Drawer.view Theme.default
                        { drD | show = True, onMaskClick = Just DrawerMaskClick }
                        [ Element.text "Mask click" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-dark") ]
                    (Drawer.view Theme.dark
                        { drD | show = True, width = Just "180px" }
                        [ Element.text "Dark" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-content-close") ]
                    (Drawer.view Theme.default
                        { drD | show = True, width = Just "180px" }
                        [ DrawerContent.view Theme.default drContentCloseOpts [ Element.text "C" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-content-headerwins") ]
                    (Drawer.view Theme.default
                        { drD | show = True }
                        [ DrawerContent.view Theme.default drContentHeaderWinsOpts [ Element.text "B" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-content-nohdr") ]
                    (Drawer.view Theme.default
                        { drD | show = True }
                        [ DrawerContent.view Theme.default drContentD [ Element.text "No header" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-content-full") ]
                    (Drawer.view Theme.default
                        { drD | show = True }
                        [ DrawerContent.view Theme.default drContentFullOpts [ Element.text "Full" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-drawer-content-nonnative") ]
                    (Drawer.view Theme.default
                        { drD | show = True, nativeScrollbar = False }
                        [ DrawerContent.view Theme.default drContentNonNativeOpts [ Element.text "Scroll body" ] ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-scrollbar-seam") ]
                    (Scrollbar.view Theme.default mScrollbarSeamOpts [ Element.text "Seam" ])

                -- Dialog (a pure body component — the .n-dialog card; also the
                -- body of Modal's dialog/confirm presets)
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-default") ]
                    (Dialog.view Theme.default
                        { dgD
                            | title = Just (Element.text "Title")
                            , content = Just (Element.text "Body")
                            , positiveText = Just "Yes"
                            , negativeText = Just "No"
                            , onClose = Just DialogClose
                            , onPositiveClick = Just DialogPositive
                            , onNegativeClick = Just DialogNegative
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-kind-default") ]
                    (Dialog.view Theme.default (dgKindOpts T.Default))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-kind-primary") ]
                    (Dialog.view Theme.default (dgKindOpts T.Primary))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-kind-info") ]
                    (Dialog.view Theme.default (dgKindOpts T.Info))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-kind-success") ]
                    (Dialog.view Theme.default (dgKindOpts T.Success))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-kind-warning") ]
                    (Dialog.view Theme.default (dgKindOpts T.Warning))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-kind-error") ]
                    (Dialog.view Theme.default (dgKindOpts T.Error))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-actions-default") ]
                    (Dialog.view Theme.default (dgKindActionOpts T.Default))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-actions-primary") ]
                    (Dialog.view Theme.default (dgKindActionOpts T.Primary))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-actions-info") ]
                    (Dialog.view Theme.default (dgKindActionOpts T.Info))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-actions-success") ]
                    (Dialog.view Theme.default (dgKindActionOpts T.Success))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-actions-warning") ]
                    (Dialog.view Theme.default (dgKindActionOpts T.Warning))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-actions-error") ]
                    (Dialog.view Theme.default (dgKindActionOpts T.Error))
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-icontop") ]
                    (Dialog.view Theme.default
                        { dgD | iconPlacement = Dialog.IconTop, kind = T.Success, content = Just (Element.text "Body") }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-bordered") ]
                    (Dialog.view Theme.default { dgD | bordered = True, content = Just (Element.text "Body") })
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-rtl") ]
                    (Dialog.view Theme.default { dgD | rtl = True, content = Just (Element.text "Body") })
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-noicon") ]
                    (Dialog.view Theme.default { dgD | showIcon = False, content = Just (Element.text "Body") })
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-noclose") ]
                    (Dialog.view Theme.default { dgD | closable = False, kind = T.Warning, content = Just (Element.text "Body") })
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-closefocus") ]
                    (Dialog.view Theme.default { dgD | closeFocusable = True, content = Just (Element.text "Body") })
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-closeslot") ]
                    (Dialog.view Theme.default
                        { dgD
                            | close = Just (Element.el [ Element.htmlAttribute (HA.attribute "data-caller-close" "on") ] (Element.text "x"))
                            , rtl = True
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-loading") ]
                    (Dialog.view Theme.default dgLoadingOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-props") ]
                    (Dialog.view Theme.default dgPropsOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-noaction") ]
                    (Dialog.view Theme.default { dgD | content = Just (Element.text "Body") })
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-action") ]
                    (Dialog.view Theme.default
                        { dgD
                            | content = Just (Element.text "Body")
                            , positiveText = Just "Yes"
                            , action = Just [ Element.text "#action" ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-action-empty") ]
                    (Dialog.view Theme.default
                        { dgD
                            | content = Just (Element.text "Body")
                            , action = Just []
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-dark") ]
                    (Dialog.view Theme.dark { dgD | kind = T.Warning, content = Just (Element.text "Body") })

                -- Modal dialog/confirm presets (body + n-modal + aria-modal; phase LAST)
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-dialog") ]
                    (Modal.view Theme.default
                        { mD | show = True }
                        (Modal.Dialog
                            { dgD
                                | title = Just (Element.text "Title")
                                , content = Just (Element.text "Body")
                                , positiveText = Just "Yes"
                                , negativeText = Just "No"
                            }
                        )
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-confirm") ]
                    (Modal.view Theme.default
                        { mD | show = True }
                        (Modal.Confirm
                            { dgD
                                | title = Just (Element.text "Title")
                                , content = Just (Element.text "Body")
                                , positiveText = Just "Yes"
                                , negativeText = Just "No"
                            }
                        )
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-modal-dialog-phase") ]
                    (Modal.view Theme.default
                        { mD | show = True, bodyTransition = Just Internal.EnterFrom }
                        (Modal.Dialog { dgD | content = Just (Element.text "Body") })
                    )

                -- Button seams (the loading icon + the n-icon-slot wrapper)
                , Element.el [ Element.htmlAttribute (HA.id "live-button-loading") ]
                    (Button.view Theme.default btnLoadingOpts [ Element.text "Loading" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-button-spinprops") ]
                    (Button.view Theme.default btnSpinPropsOpts [ Element.text "Loading" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-button-icon") ]
                    (Button.view Theme.default btnIconOpts [ Element.text "Icon" ])

                -- Popconfirm (Popover default body + the n-popconfirm panel)
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-default") ]
                    (Popconfirm.view Theme.default pcD [ Element.text "Delete it?" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-extra") ]
                    (Popconfirm.view Theme.default
                        { pcD | popover = { pD | extraClasses = [ "caller-class" ] } }
                        [ Element.text "Delete it?" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-hidden-both") ]
                    (Popconfirm.view Theme.default
                        { pcD | positiveText = Popconfirm.Hidden, negativeText = Popconfirm.Hidden }
                        []
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-noicon-nobody") ]
                    (Popconfirm.view Theme.default { pcD | showIcon = False } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-body-noicon") ]
                    (Popconfirm.view Theme.default { pcD | showIcon = False } [ Element.text "Content only" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-customicon") ]
                    (Popconfirm.view Theme.default { pcD | icon = Just (Element.text "!") } [ Element.text "Delete it?" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-customtext") ]
                    (Popconfirm.view Theme.default
                        { pcD | positiveText = Popconfirm.CustomText "OK", negativeText = Popconfirm.CustomText "Nope" }
                        [ Element.text "Delete it?" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-positive-hidden") ]
                    (Popconfirm.view Theme.default { pcD | positiveText = Popconfirm.Hidden } [ Element.text "Delete it?" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-actionslot") ]
                    (Popconfirm.view Theme.default { pcD | action = Just [ Element.text "#action" ] } [ Element.text "Delete it?" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-action-empty") ]
                    (Popconfirm.view Theme.default { pcD | action = Just [] } [ Element.text "Delete it?" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popconfirm-props") ]
                    (Popconfirm.view Theme.default
                        { pcD
                            | positiveProps = Just (\b -> { b | kind = T.Error, round = True })
                            , negativeProps = Just (\b -> { b | round = True })
                        }
                        [ Element.text "Delete it?" ]
                    )

                -- Popselect (the Dropdown-lane select-menu root = popover body)
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-default") ]
                    (Popselect.view Theme.default psD [ smLeaf "drive" "Drive My Car", smLeaf "walk" "Walk" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-small") ]
                    (Popselect.view Theme.default { psD | size = Popselect.Small } [ smLeaf "drive" "Drive My Car" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-huge") ]
                    (Popselect.view Theme.default { psD | size = Popselect.Huge } [ smLeaf "drive" "Drive My Car" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-multiple") ]
                    (Popselect.view Theme.default { psD | multiple = True, value = SelectMenu.Multiple [ "drive" ] } [ smLeaf "drive" "Drive My Car", smLeaf "walk" "Walk" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-rtl") ]
                    (Popselect.view Theme.default { psD | rtl = True } [ smLeaf "drive" "Drive My Car" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-overlap") ]
                    (Popselect.view Theme.default { psD | overlap = True } [ smLeaf "drive" "Drive My Car" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-centerarrow") ]
                    (Popselect.view Theme.default { psD | arrowPointToCenter = True } [ smLeaf "drive" "Drive My Car" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-transition") ]
                    (Popselect.view Theme.default { psD | transition = Just Internal.EnterActive } [ smLeaf "drive" "Drive My Car" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-popselect-width") ]
                    (Popselect.view Theme.default { psD | width = Just "220px" } [ smLeaf "drive" "Drive My Car" ])

                -- SelectMenu (the .n-base-select-menu body engine)
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-default") ]
                    (SelectMenu.view Theme.default smD [ smLeaf "a" "A", smLeaf "b" "B" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-focusable") ]
                    (SelectMenu.view Theme.default { smD | focusable = True } [ smLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-header-action") ]
                    (SelectMenu.view Theme.default
                        { smD
                            | header = Just (Element.text "Header")
                            , action = Just (Element.text "Action")
                        }
                        [ smLeaf "a" "A" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-optmods") ]
                    (SelectMenu.view Theme.default
                        { smD | value = SelectMenu.Single (Just "a") }
                        [ smLeaf "a" "A"
                        , SelectMenu.Option { value = "b", label = "B", disabled = True, attributes = [] }
                        , SelectMenu.Group { label = "G", children = [ smLeaf "g1" "G1" ], attributes = [] }
                        , smLeaf "c" "C"
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-multiple") ]
                    (SelectMenu.view Theme.default
                        { smD | multiple = True, value = SelectMenu.Multiple [ "a" ] }
                        [ smLeaf "a" "A", smLeaf "b" "B" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-nocheckmark") ]
                    (SelectMenu.view Theme.default
                        { smD | value = SelectMenu.Single (Just "a"), showCheckmark = False }
                        [ smLeaf "a" "A" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-checktransition") ]
                    (SelectMenu.view Theme.default
                        { smD | value = SelectMenu.Single (Just "a"), checkmarkTransition = Just Internal.EnterActive }
                        [ smLeaf "a" "A" ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-empty") ]
                    (SelectMenu.view Theme.default smD [])
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-empty-huge") ]
                    (SelectMenu.view Theme.default { smD | size = SelectMenu.Huge } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-emptyslot") ]
                    (SelectMenu.view Theme.default { smD | empty = Just (Element.text "Nothing here") } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-custom") ]
                    (SelectMenu.view Theme.default
                        smD
                        [ SelectMenu.Custom { key = "custom", node = Element.text "custom-verbatim" } ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-nested") ]
                    (SelectMenu.view Theme.default
                        smD
                        [ SelectMenu.Group
                            { label = "Outer"
                            , children =
                                [ smLeaf "inner1" "Inner1"
                                , SelectMenu.Group { label = "InnerGroup", children = [ smLeaf "deep" "Deep" ], attributes = [] }
                                ]
                            , attributes = []
                            }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-childless-group") ]
                    (SelectMenu.view Theme.default
                        smD
                        [ SelectMenu.Group { label = "Solo", children = [], attributes = [] } ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-nested-only") ]
                    (SelectMenu.view Theme.default
                        smD
                        [ SelectMenu.Group
                            { label = "Outer"
                            , children =
                                [ SelectMenu.Group
                                    { label = "InnerGroup"
                                    , children = [ smLeaf "deep" "Deep" ]
                                    , attributes = []
                                    }
                                ]
                            , attributes = []
                            }
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-pending") ]
                    (SelectMenu.view Theme.default
                        smD
                        [ smLeafAttr "a" "A" (Element.htmlAttribute (HA.attribute "data-pending" "on"))
                        , smLeafAttr "b" "B" (Element.htmlAttribute (HA.class "n-base-select-option--pending"))
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-rtl") ]
                    (SelectMenu.view Theme.default { smD | rtl = True } [ smLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-extra") ]
                    (SelectMenu.view Theme.default { smD | extraClasses = [ "caller-extra" ] } [ smLeaf "a" "A" ])

                -- SelectMenu loading row (Select's remote state replaces the middle)
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-loading") ]
                    (SelectMenu.view Theme.default { smD | loading = True } [ smLeaf "a" "A", smLeaf "b" "B" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-selectmenu-loading-header-action") ]
                    (SelectMenu.view Theme.default
                        { smD
                            | loading = True
                            , header = Just (Element.text "Header")
                            , action = Just (Element.text "Action")
                        }
                        [ smLeaf "a" "A" ]
                    )

                -- BaseSelection (the trigger engine)
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-default") ]
                    (BaseSelection.view Theme.default bsD)
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-single-selected") ]
                    (BaseSelection.view Theme.default { bsD | selectedLabel = Just "Drive My Car" })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-single-filterable-empty") ]
                    (BaseSelection.view Theme.default { bsD | filterable = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-single-filterable-selected") ]
                    (BaseSelection.view Theme.default { bsD | filterable = True, selectedLabel = Just "Drive My Car" })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-single-filterable-active") ]
                    (BaseSelection.view Theme.default
                        { bsD | filterable = True, active = True, selectedLabel = Just "Drive My Car", pattern = "dri" }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-single-filterable-active-empty") ]
                    (BaseSelection.view Theme.default
                        { bsD | filterable = True, active = True, selectedLabel = Just "Drive My Car", pattern = "" }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-disabled") ]
                    (BaseSelection.view Theme.default { bsD | disabled = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-multiple") ]
                    (BaseSelection.view Theme.default { bsD | multiple = True, tags = [ bsTag "a" "A", bsTag "b" "B" ] })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-multiple-ellipsis") ]
                    (BaseSelection.view Theme.default
                        { bsD | multiple = True, tags = [ bsTag "a" "A", bsTag "b" "B" ], ellipsisTag = Just 3 }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-multiple-filterable") ]
                    (BaseSelection.view Theme.default
                        { bsD | multiple = True, filterable = True, pattern = "dri", tags = [ bsTag "a" "A" ] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-multiple-placeholder") ]
                    (BaseSelection.view Theme.default { bsD | multiple = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-status-warning") ]
                    (BaseSelection.view Theme.default { bsD | status = Just BaseSelection.Warning })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-status-error") ]
                    (BaseSelection.view Theme.default { bsD | status = Just BaseSelection.Error })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-status-success") ]
                    (BaseSelection.view Theme.default { bsD | status = Just BaseSelection.Success })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-active") ]
                    (BaseSelection.view Theme.default { bsD | active = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-selected-boost") ]
                    (BaseSelection.view Theme.default { bsD | active = True, pattern = "x" })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-focus") ]
                    (BaseSelection.view Theme.default { bsD | focused = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-rtl") ]
                    (BaseSelection.view Theme.default { bsD | rtl = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-classes") ]
                    (BaseSelection.view Theme.default
                        { bsD
                            | rtl = True
                            , status = Just BaseSelection.Error
                            , active = True
                            , pattern = "x"
                            , multiple = True
                            , focused = True
                            , disabled = True
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-loading") ]
                    (BaseSelection.view Theme.default { bsD | loading = True, selectedLabel = Just "Drive My Car" })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-clear") ]
                    (BaseSelection.view Theme.default { bsD | showClear = True, selectedLabel = Just "Drive My Car" })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-arrow-slot") ]
                    (BaseSelection.view Theme.default { bsD | arrow = Just (Element.text "slot-arrow") })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-noarrow") ]
                    (BaseSelection.view Theme.default { bsD | showArrow = False })
                , Element.el [ Element.htmlAttribute (HA.id "live-basesel-unbordered") ]
                    (BaseSelection.view Theme.default { bsD | bordered = False })

                -- Select.view (the trigger derivation)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-single-selected") ]
                    (Select.view Theme.default { selD | value = SelectMenu.Single (Just "drive") } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-single-fallback") ]
                    (Select.view Theme.default { selD | value = SelectMenu.Single (Just "ghost") } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-single-fallback-off") ]
                    (Select.view Theme.default { selD | value = SelectMenu.Single (Just "ghost"), fallbackOption = False } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-multiple") ]
                    (Select.view Theme.default { selD | multiple = True, value = SelectMenu.Multiple [ "a", "b", "c" ] } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-multiple-fallback") ]
                    (Select.view Theme.default { selD | multiple = True, value = SelectMenu.Multiple [ "a", "ghost" ] } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-multiple-fallback-off") ]
                    (Select.view Theme.default { selD | multiple = True, fallbackOption = False, value = SelectMenu.Multiple [ "a", "ghost" ] } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-multiple-maxtag") ]
                    (Select.view Theme.default
                        { selD | multiple = True, maxTagCount = Just 3, value = SelectMenu.Multiple [ "a", "b", "c", "d", "e" ] }
                        selOptions
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-select-clear-hover") ]
                    (Select.view Theme.default { selD | clearable = True, hover = True, value = SelectMenu.Single (Just "drive") } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-clear-active") ]
                    (Select.view Theme.default { selD | clearable = True, active = True, value = SelectMenu.Single (Just "drive") } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-clear-neither") ]
                    (Select.view Theme.default { selD | clearable = True, value = SelectMenu.Single (Just "drive") } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-clear-unselected") ]
                    (Select.view Theme.default { selD | clearable = True, hover = True, value = SelectMenu.Single Nothing } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-clear-notclearable") ]
                    (Select.view Theme.default { selD | hover = True, active = True, value = SelectMenu.Single (Just "drive") } selOptions)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-clear-disabled") ]
                    (Select.view Theme.default { selD | clearable = True, hover = True, disabled = True, value = SelectMenu.Single (Just "drive") } selOptions)

                -- Select.menu (the n-select-menu body = SelectMenu.view + n-select-menu)
                , Element.el [ Element.htmlAttribute (HA.id "live-select-menu-default") ]
                    (Select.menu Theme.default selMenuD [ smLeaf "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-select-menu-transition") ]
                    (Select.menu Theme.default { selMenuD | transition = Just Internal.EnterActive } [ smLeaf "a" "A" ])

                -- AutoComplete.view (the bare .n-auto-complete wrapper + NUI.Input trigger)
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-default") ]
                    (AutoComplete.view Theme.default acD)
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-small") ]
                    (AutoComplete.view Theme.default { acD | size = AutoComplete.Small })
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-large") ]
                    (AutoComplete.view Theme.default { acD | size = AutoComplete.Large })
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-warning") ]
                    (AutoComplete.view Theme.default { acD | status = Just Input.Warning })
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-error") ]
                    (AutoComplete.view Theme.default { acD | status = Just Input.Error })
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-success") ]
                    (AutoComplete.view Theme.default { acD | status = Just Input.Success })
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-disabled") ]
                    (AutoComplete.view Theme.default { acD | disabled = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-clearable") ]
                    (AutoComplete.view Theme.default { acD | clearable = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-loading") ]
                    (AutoComplete.view Theme.default { acD | loading = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-loading-slot") ]
                    (AutoComplete.view Theme.default
                        { acD | loading = True, clearable = True, suffix = Just (Element.text "sfx") }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-inputattrs") ]
                    (AutoComplete.view Theme.default
                        { acD | inputAttributes = [ HA.attribute "data-ac-test" "yes" ] }
                    )

                -- AutoComplete.menu (the n-auto-complete-menu body)
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-menu-default") ]
                    (AutoComplete.menu Theme.default acMenuD [ AutoComplete.fromString "x", AutoComplete.fromString "y" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-menu-transition") ]
                    (AutoComplete.menu Theme.default { acMenuD | transition = Just Internal.EnterActive } [ AutoComplete.fromString "x" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-menu-rtl") ]
                    (AutoComplete.menu Theme.default { acMenuD | rtl = True } [ AutoComplete.fromString "x" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-menu-empty") ]
                    (AutoComplete.menu Theme.default { acMenuD | empty = Just (Element.text "Nothing here") } [])
                , Element.el [ Element.htmlAttribute (HA.id "live-ac-menu-group") ]
                    (AutoComplete.menu Theme.default
                        acMenuD
                        [ SelectMenu.Group
                            { label = "G"
                            , children = [ smLeaf "g1" "G1", smLeaf "g2" "G2" ]
                            , attributes = []
                            }
                        ]
                    )

                -- Mention.view (the bare .n-mention wrapper + NUI.Input trigger)
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-default") ]
                    (Mention.view Theme.default mnD)
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-placeholder") ]
                    (Mention.view Theme.default { mnD | placeholder = "Type here" })
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-small") ]
                    (Mention.view Theme.default { mnD | size = Mention.Small })
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-large") ]
                    (Mention.view Theme.default { mnD | size = Mention.Large })
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-textarea") ]
                    (Mention.view Theme.default { mnD | type_ = Mention.Textarea })
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-autosize") ]
                    (Mention.view Theme.default { mnD | type_ = Mention.Textarea, autosize = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-resizable") ]
                    (Mention.view Theme.default { mnD | type_ = Mention.Textarea, autosize = False })
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-warning") ]
                    (Mention.view Theme.default { mnD | status = Just Input.Warning })
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-disabled") ]
                    (Mention.view Theme.default { mnD | disabled = True })

                -- Mention.menu (the n-mention-menu body — loading = the MENU row)
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-menu-default") ]
                    (Mention.menu Theme.default mnMenuD [ smLeaf "x" "X", smLeaf "y" "Y" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-mention-menu-loading") ]
                    (Mention.menu Theme.default { mnMenuD | loading = True } [ smLeaf "x" "X" ])

                -- Cascader.selectMenu (the filterable flat body — the bare empty fallback)
                , Element.el [ Element.htmlAttribute (HA.id "live-casc-selectmenu-empty") ]
                    (Cascader.selectMenu Theme.default cascSelectMenuD [])
                , Element.el [ Element.htmlAttribute (HA.id "live-casc-selectmenu-empty-slot") ]
                    (Cascader.selectMenu Theme.default
                        { cascSelectMenuD | empty = Just (Element.text "not-found-slot") }
                        []
                    )

                -- Cascader.menu (the columns body — loading branch spinner + idle arrow)
                , Element.el [ Element.htmlAttribute (HA.id "live-casc-menu-loading") ]
                    (Cascader.menu Theme.default
                        { cascMenuD | hoverKey = Just "a", loadingKeys = [ "a2" ] }
                        cascTree
                    )

                -- Tree.view (the flattened rows — switcher / checkbox / content)
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-basic") ]
                    (Tree.view Theme.default
                        { treeD | data = treeFixture, expandedKeys = [ "a", "a2" ] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-states") ]
                    (Tree.view Theme.default
                        { treeD
                            | data = treeFixture
                            , expandedKeys = [ "a" ]
                            , checkable = True
                            , checkboxPlacement = Tree.Right
                            , selectedKeys = [ "a1" ]
                            , pendingKey = Just "a2"
                            , highlightKeys = Just [ "a2y" ]
                            , disabled = False
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-rtl-block") ]
                    (Tree.view Theme.default
                        { treeD
                            | data = treeFixture
                            , expandedKeys = [ "a" ]
                            , rtl = True
                            , blockNode = True
                            , blockLine = True
                            , ellipsis = True
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-showline") ]
                    (Tree.view Theme.default
                        { treeD | data = treeFixture, expandedKeys = [ "a", "a2" ], showLine = True }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-loading") ]
                    (Tree.view Theme.default
                        { treeD | data = treeFixture, expandedKeys = [ "a" ], loadingKeys = [ "a2" ] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-empty") ]
                    (Tree.view Theme.default treeD)

                -- Tree.view pattern highlight (default showIrrelevantNodes:
                -- full tree displays, matches still paint --highlight)
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-filter") ]
                    (Tree.view Theme.default
                        { treeD | data = treeFixture, expandedKeys = [ "a", "a2" ], pattern = "a2" }
                    )

                -- Tree.view drop mark (the classless absolute div on the a1 row)
                , Element.el [ Element.htmlAttribute (HA.id "live-tree-dropmark") ]
                    (Tree.view Theme.default
                        { treeD
                            | data = treeFixture
                            , expandedKeys = [ "a" ]
                            , dropMark =
                                Just
                                    { key = "a1"
                                    , position = Tree.Before
                                    , offsetLevel = 0
                                    }
                        }
                    )

                -- Table.view (the static n-table — root classes + 21 vars
                -- over the typed thead/tbody tree)
                , Element.el [ Element.htmlAttribute (HA.id "live-table-basic") ]
                    (Table.view Theme.default tblD tblTable)
                , Element.el [ Element.htmlAttribute (HA.id "live-table-modifiers") ]
                    (Table.view Theme.default
                        { tblD | bordered = False, bottomBordered = False, singleLine = False, singleColumn = True, striped = True }
                        tblTable
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-table-small") ]
                    (Table.view Theme.default { tblD | size = Table.Small } tblTable)
                , Element.el [ Element.htmlAttribute (HA.id "live-table-large") ]
                    (Table.view Theme.default { tblD | size = Table.Large } tblTable)
                , Element.el [ Element.htmlAttribute (HA.id "live-table-rtl") ]
                    (Table.view Theme.default { tblD | rtl = True } tblTable)
                , Element.el [ Element.htmlAttribute (HA.id "live-table-span") ]
                    (Table.view Theme.default tblD tblSpanTable)
                , Element.el [ Element.htmlAttribute (HA.id "live-table-empty-head") ]
                    (Table.view Theme.default tblD { head = [], body = tblTable.body })
                , Element.el [ Element.htmlAttribute (HA.id "live-table-empty-body") ]
                    (Table.view Theme.default tblD { head = tblTable.head, body = [] })

                -- Watermark.view (the container/overlay pair — bare overlay
                -- when fullscreen without global rotation; z-index handoff
                -- when fullscreen AND globalRotate)
                , Element.el [ Element.htmlAttribute (HA.id "live-wm-default") ]
                    (Watermark.view Theme.default wmD [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-wm-cross") ]
                    (Watermark.view Theme.default crossOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-wm-global") ]
                    (Watermark.view Theme.default globalOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-wm-handoff") ]
                    (Watermark.view Theme.default handoffOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-wm-bare") ]
                    (Watermark.view Theme.default bareOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-wm-image") ]
                    (Watermark.view Theme.default imageOpts [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-wm-unselectable") ]
                    (Watermark.view Theme.default (wmWith (\d -> { d | selectable = False, content = Just "x" })) [ Element.text "content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-menu-v") ]
                    (Menu.view Theme.default
                        { menuD | value = Just "grp-leaf", expandedKeys = [ "sub-1" ], onSelect = Just Selected, onExpandedKeysChange = Just MenuExpandedKeys }
                        menuTree
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-menu-collapsed") ]
                    (Menu.view Theme.default
                        { menuD | collapsed = True, expandedKeys = [ "sub-1" ] }
                        menuTree
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-menu-h") ]
                    (Menu.view Theme.default
                        { menuD | mode = Menu.Horizontal, value = Just "grp-leaf", expandedKeys = [ "sub-1" ] }
                        menuTree
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-menu-inv") ]
                    (Menu.view Theme.default
                        { menuD | inverted = True, value = Just "grp-leaf", expandedKeys = [ "sub-1" ] }
                        menuTree
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-menu-dis") ]
                    (Menu.view Theme.default
                        { menuD | disabled = True, expandedKeys = [ "sub-1" ] }
                        menuTree
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-menu-gdis") ]
                    (Menu.view Theme.default
                        { menuD | expandedKeys = [ "gdis-sub", "gdis-out" ] }
                        menuGDisTree
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-slider-s") ]
                    (Slider.view Theme.default
                        { sliderD | value = [ 40 ], marks = sliderMarks }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-slider-r") ]
                    (Slider.view Theme.default
                        { sliderD | range = True, value = [ 24, 49 ], marks = sliderMarks }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-slider-v") ]
                    (Slider.view Theme.default
                        { sliderD | value = [ 77 ], vertical = True, marks = sliderMarks }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-slider-t") ]
                    (Slider.view Theme.default
                        { sliderD | value = [ 66 ], hoverIndex = 0, activeIndex = 0, dragging = True }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-slider-d") ]
                    (Slider.view Theme.default
                        { sliderD | value = [ 12 ], disabled = True }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-slider-x") ]
                    (Slider.view Theme.default
                        { sliderD | range = True, value = [ 10, 50, 90 ], marks = sliderMarks }
                    )

                -- Image.view (the img attribute pack — alt+aria-label,
                -- loading, data-error stringified, data-preview-src,
                -- post-mount data-group-id; fallback swap, error-slot
                -- replacement, placeholder 0×0 hide, gates)
                , Element.el [ Element.htmlAttribute (HA.id "live-image-basic") ]
                    (Image.view Theme.default
                        { imageD
                            | src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                            , alt = Just "Naive UI logo"
                            , width = Just "160"
                            , height = Just "120"
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-image-fallback") ]
                    (Image.view Theme.default
                        { imageD
                            | src = Just "https:// 07akioni.oss-cn-beijing.aliyuncs.com/broken.jpeg"
                            , fallbackSrc = Just "https://www.naiveui.com/assets/naivelogo.93278402.svg"
                            , showError = True
                            , loaded = True
                            , placeholder = Just (Element.text "Placeholder")
                            , width = Just "160"
                            , height = Just "120"
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-image-error-slot") ]
                    (Image.view Theme.default
                        { imageD
                            | src = Just "https:// 07akioni.oss-cn-beijing.aliyuncs.com/broken.jpeg"
                            , showError = True
                            , error = Just (Element.text "Load failed")
                            , width = Just "160"
                            , height = Just "120"
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-image-placeholder") ]
                    (Image.view Theme.default
                        { imageD
                            | src = Just "https://www.naiveui.com/assets/naivelogo.93278402.svg"
                            , width = Just "160"
                            , height = Just "120"
                            , placeholder = Just (Element.text "Placeholder")
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-image-pdisabled") ]
                    (Image.view Theme.default
                        { imageD
                            | src = Just "https://www.naiveui.com/assets/naivelogo.93278402.svg"
                            , width = Just "160"
                            , height = Just "120"
                            , previewDisabled = True
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-image-lazy") ]
                    (Image.view Theme.default
                        { imageD
                            | src = Just "https://www.naiveui.com/assets/naivelogo.93278402.svg"
                            , width = Just "160"
                            , height = Just "120"
                            , lazy = True
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-image-preview-src") ]
                    (Image.view Theme.default
                        { imageD
                            | src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                            , previewSrc = Just "https://www.naiveui.com/assets/naivelogo.93278402.svg"
                            , width = Just "160"
                            , height = Just "120"
                        }
                    )

                -- ImagePreview.view (the preview container tree — overlay,
                -- toolbar icon count keyed on onPrev, resting img style) and
                -- ImageGroup.view (the registry walk: current=2 skips the
                -- empty p1 url)
                , Element.el [ Element.htmlAttribute (HA.id "live-preview-basic") ]
                    (ImagePreview.view Theme.default
                        { previewD
                            | show = True
                            , src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                            , onClose = Just PreviewClose
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-preview-dragging") ]
                    (ImagePreview.view Theme.default
                        { previewD
                            | show = True
                            , src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                            , dragging = True
                            , imgDerived = True
                            , previewedImgStyle = [ ( "border", "8px solid white" ) ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-preview-group") ]
                    (ImageGroup.view Theme.default
                        { groupD
                            | show = True
                            , srcList =
                                [ "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                                , ""
                                , "https://www.naiveui.com/assets/naivelogo.93278402.svg"
                                ]
                            , current = 2
                            , onPrev = Just NoOp
                            , onNext = Just NoOp
                            , onClose = Just NoOp
                        }
                    )

                -- Message / Notification: static entered states + phase
                -- windows (the caller owns the hide clock; the close buttons
                -- emit the counters' msgs)
                , Element.el [ Element.htmlAttribute (HA.id "live-message-basic") ]
                    (Message.view Theme.default
                        { messageS
                            | items =
                                [ { messageI
                                    | key = "d"
                                    , options = { messageD | content = "A default message — no icon wrapper" }
                                  }
                                , { messageI
                                    | key = "i"
                                    , options = { messageD | kind = Message.Info, content = "An info message" }
                                  }
                                , { messageI
                                    | key = "c"
                                    , options =
                                        { messageD
                                            | kind = Message.Success
                                            , content = "Closable"
                                            , closable = Just True
                                            , onClose = Just MessageClose
                                        }
                                  }
                                ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-message-phases") ]
                    (Message.view Theme.default
                        { messageS
                            | items =
                                [ { messageI
                                    | key = "entering"
                                    , options = { messageD | kind = Message.Info, content = "Entering" }
                                    , phase = Just Internal.EnterActive
                                  }
                                , { messageI
                                    | key = "leaving"
                                    , options = { messageD | kind = Message.Warning, content = "Leaving" }
                                    , phase = Just Internal.LeaveFrom
                                  }
                                ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-notification-basic") ]
                    (Notification.view Theme.default
                        { noteS
                            | items =
                                [ { noteI
                                    | key = "full"
                                    , options =
                                        { noteD
                                            | kind = Notification.Info
                                            , title = Just "Full tree"
                                            , description = Just "The description row"
                                            , content = Just "Content in a pre"
                                            , meta = Just "the meta line"
                                            , action = Just (Element.text "action")
                                            , closable = Just True
                                            , onClose = Just NotificationClose
                                        }
                                  }
                                , { noteI
                                    | key = "bare"
                                    , options =
                                        { noteD
                                            | title = Just "Bare — no avatar"
                                            , closable = Just False
                                        }
                                  }
                                ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-notification-phases") ]
                    (Notification.view Theme.default
                        { noteS
                            | items =
                                [ { noteI
                                    | key = "entering"
                                    , options = { noteD | title = Just "Entering", kind = Notification.Success }
                                    , phase = Just Internal.EnterActive
                                  }
                                ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-notification-top") ]
                    (Notification.view Theme.default
                        { noteS
                            | placement = Notification.Top
                            , items =
                                [ { noteI
                                    | key = "tc"
                                    , options = { noteD | title = Just "Top center", kind = Notification.Warning }
                                  }
                                ]
                        }
                    )

                -- Dialog service: the provider renders a Fragment — each item
                -- is one full modal tree (container > mask + body-wrapper >
                -- scrollbar > .n-dialog.n-modal).
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-basic") ]
                    (Element.column []
                        (DialogProvider.view Theme.default
                            { dgPS
                                | items =
                                    [ { dgPD
                                        | key = "d1"
                                        , zIndex = Just 2000
                                        , options =
                                            { dgD
                                                | kind = T.Warning
                                                , title = Just (Element.text "Delete file?")
                                                , content = Just (Element.text "A settled dialog — no phase classes anywhere.")
                                                , positiveText = Just "OK"
                                                , negativeText = Just "Cancel"
                                            }
                                      }
                                    ]
                            }
                        )
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-phases") ]
                    (Element.column []
                        (DialogProvider.view Theme.default
                            { dgPS
                                | items =
                                    [ { dgPD
                                        | key = "d2"
                                        , phase = Just Internal.EnterActive
                                        , zIndex = Just 2000
                                        , options = { dgD | kind = T.Info, content = Just (Element.text "Entering") }
                                      }
                                    , { dgPD
                                        | key = "d3"
                                        , phase = Just Internal.LeaveFrom
                                        , zIndex = Just 2001
                                        , options = { dgD | kind = T.Error, content = Just (Element.text "Leaving") }
                                      }
                                    ]
                            }
                        )
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-dialog-style") ]
                    (Element.column []
                        (DialogProvider.view Theme.default
                            { dgPS
                                | items =
                                    [ { dgPD
                                        | key = "d4"
                                        , zIndex = Just 2000
                                        , options =
                                            { dgD
                                                | kind = T.Warning
                                                , content = Just (Element.text "The style fragment lands after the vars.")
                                                , style = Just "color: rgb(79, 178, 51);"
                                            }
                                      }
                                    ]
                            }
                        )
                    )

                -- Data table (batch 1): the core static render — class
                -- toggles, size-keyed vars, empty restructure
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-basic") ]
                    (DataTable.view Theme.default dtOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-noborder") ]
                    (DataTable.view Theme.default { dtOpts | bordered = False })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-single") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | singleLine = False
                            , singleColumn = True
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-small") ]
                    (DataTable.view Theme.default { dtOpts | size = DataTable.Small })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-striped") ]
                    (DataTable.view Theme.default { dtOpts | striped = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty") ]
                    (DataTable.view Theme.default { dtOpts | data = [] })

                -- Data table (batch 2): sort state → th/td classes + the
                -- sorter span, and the pagination node after the wrapper
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-sort-desc") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns =
                                [ dtNameCol
                                , { dtAgeCol | sorter = Just (DataTable.SorterBy (\a b -> compare a.age b.age)) }
                                , dtAddressCol
                                ]
                            , sortStates = [ { columnKey = "age", order = DataTable.Descend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-sort-asc") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns =
                                [ dtNameCol
                                , { dtAgeCol | sorter = Just (DataTable.SorterBy (\a b -> compare a.age b.age)) }
                                , dtAddressCol
                                ]
                            , sortStates = [ { columnKey = "age", order = DataTable.Ascend, sorter = DataTable.SorterBy (\a b -> compare a.age b.age) } ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-sort-idle") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns =
                                [ dtNameCol
                                , { dtAgeCol | sorter = Just (DataTable.SorterBy (\a b -> compare a.age b.age)) }
                                , dtAddressCol
                                ]
                            , sortStates =
                                DataTable.defaultSortStates
                                    [ dtNameCol
                                    , { dtAgeCol | sorter = Just (DataTable.SorterBy (\a b -> compare a.age b.age)) }
                                    , dtAddressCol
                                    ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-paginated") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | pagination = Just { dtPgD | currentPage = 1, pageSize = Just 2 }
                            , paginationPrefix = [ Element.text "3 items" ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-pag-hidden") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | data = [ { name = "John Brown", age = 32, address = "New York No. 1 Lake Park" } ]
                            , paginateSinglePage = False
                            , pagination = Just { dtPgD | currentPage = 1, pageSize = Just 2 }
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-selection") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ dtSelCol, dtNameCol ]
                            , data = List.map dtSpecRow (List.range 0 1)
                            , checkedRowKeys = [ "0" ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-selection-single") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ { dtSelCol | multiple = False }, dtNameCol ]
                            , data = List.map dtSpecRow (List.range 0 4)
                            , checkedRowKeys = [ "4", "1" ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-check-extra") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns =
                                [ { dtSelCol | options = [ DataTable.SelectionAll, DataTable.SelectionNone ] }
                                , dtNameCol
                                ]
                            , data =
                                [ { name = "a", age = 0, address = "" }
                                , { name = "b", age = 1, address = "" }
                                ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-expand") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns =
                                [ { dtExpCol
                                    | expandable = Just (\r -> r.name == "0")
                                    , renderExpand = Just (\r _ -> Element.text (r.name ++ " is a good guy."))
                                  }
                                , dtNameCol
                                ]
                            , data = List.map dtSpecRow (List.range 0 4)
                            , expandedRowKeys = [ "0" ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-expand-sticky") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns =
                                [ { dtExpCol
                                    | expandable = Just (\r -> r.name == "0")
                                    , renderExpand = Just (\r _ -> Element.text (r.name ++ " is a good guy."))
                                  }
                                , dtNameCol
                                ]
                            , data = List.map dtSpecRow (List.range 0 4)
                            , expandedRowKeys = [ "0", "2" ]
                            , stickyExpandedRows = True
                            , bodyWidth = Just 200
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-expand-sticky-unmeasured") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns =
                                [ { dtExpCol
                                    | expandable = Just (\r -> r.name == "0")
                                    , renderExpand = Just (\r _ -> Element.text (r.name ++ " is a good guy."))
                                  }
                                , dtNameCol
                                ]
                            , data = List.map dtSpecRow (List.range 0 4)
                            , expandedRowKeys = [ "0" ]
                            , stickyExpandedRows = True
                        }
                    )

                -- Data table (batch 4): scroll/layout — the loading overlay,
                -- flex-height/scroll-x/table-layout/max-height, fixed columns,
                -- ellipsis, and the empty-state matrix (spec :188/:212/:740/
                -- :911/:1147/:1230-1350)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-loading") ]
                    (DataTable.view Theme.default { dtOpts | loading = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-loading-empty") ]
                    (DataTable.view Theme.default { dtOpts | data = [], loading = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-flexh") ]
                    (DataTable.view Theme.default { dtOpts | flexHeight = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-scrollx") ]
                    (DataTable.view Theme.default { dtOpts | scrollX = Just 1800 })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-layout-fixed") ]
                    (DataTable.view Theme.default { dtOpts | tableLayout = DataTable.TableFixed })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-maxh") ]
                    (DataTable.view Theme.default { dtOpts | maxHeight = Just 300 })
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-fixed") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns =
                                [ { dtSelCol | fixed = Just DataTable.FixedLeft }
                                , { dtNameCol | width = Just 150, fixed = Just DataTable.FixedLeft }
                                , dtAgeCol
                                , { dtAddressCol | width = Just 220, fixed = Just DataTable.FixedRight }
                                ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-ellipsis") ]
                    (DataTable.view Theme.default
                        { dtOpts | columns = [ dtEllPlainCol, dtEllOptsCol ] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-minh") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ { dtNameCol | width = Just 100 } ]
                            , data = []
                            , minHeight = Just 300
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-ellipsis") ]
                    (DataTable.view Theme.default
                        { dtOpts | columns = [ dtEllNameCol ], data = [] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-layout-fixed") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ { dtNameCol | width = Just 100 } ]
                            , data = []
                            , tableLayout = DataTable.TableFixed
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-scrollx") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ { dtNameCol | width = Just 100 } ]
                            , data = []
                            , scrollX = Just 1800
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-maxh") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ { dtNameCol | width = Just 100 } ]
                            , data = []
                            , maxHeight = Just 300
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-flexh") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ { dtNameCol | width = Just 100 } ]
                            , data = []
                            , flexHeight = True
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-ell-maxh") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ dtEllNameCol ]
                            , data = []
                            , maxHeight = Just 300
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-ell-sx") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ dtEllNameCol ]
                            , data = []
                            , scrollX = Just 1800
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-empty-sx-maxh") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ { dtNameCol | width = Just 100 } ]
                            , data = []
                            , scrollX = Just 1800
                            , maxHeight = Just 300
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter") ]
                    (DataTable.view Theme.default
                        { dtOpts | columns = [ dtNameCol, dtAgeCol, dtFilterCol ] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter-sortable") ]
                    (DataTable.view Theme.default
                        { dtOpts | columns = [ dtNameCol, dtAgeCol, dtFilterSortCol ] }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter-active") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ dtNameCol, dtAgeCol, dtFilterCol ]
                            , filterStates = [ ( "address", DataTable.FilterMany [ "London" ] ) ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter-shown") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ dtNameCol, dtAgeCol, dtFilterCol ]
                            , filterMenuShown = [ "address" ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter-single") ]
                    (DataTable.view Theme.default
                        { dtOpts
                            | columns = [ dtNameCol, dtAgeCol, { dtFilterCol | filterMultiple = False } ]
                            , filterStates = [ ( "address", DataTable.FilterOne "London" ) ]
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter-menu-multi") ]
                    (DataTable.filterMenu Theme.default dtFmMulti)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter-menu-single") ]
                    (DataTable.filterMenu Theme.default dtFmSingle)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter-menu-compat") ]
                    (DataTable.filterMenu Theme.default dtFmCompat)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-filter-menu-rtl") ]
                    (DataTable.filterMenu Theme.default dtFmRtl)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-summary") ]
                    (DataTable.view Theme.default dtSummaryOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-summary-top") ]
                    (DataTable.view Theme.default dtSummaryTopOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-summary-striped") ]
                    (DataTable.view Theme.default dtSummaryStripedOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-merge") ]
                    (DataTable.view Theme.default dtMergeOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-group") ]
                    (DataTable.view Theme.default
                        (let
                            d =
                                DataTable.defaults
                         in
                         { d | columns = dtGroupCols, data = dtGroupRows, rowKey = .name }
                        )
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-data-table-merge-expand") ]
                    (DataTable.view Theme.default dtMergeExpandOpts)

                -- time-picker / date-picker live fixtures — pins in
                -- tasks/recon/date-picker-pins.md
                , Element.el [ Element.htmlAttribute (HA.id "live-time-picker") ]
                    (TimePicker.view Theme.default dpTimeBaseOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-time-picker-panel") ]
                    (TimePicker.panel Theme.default dpTimeBaseOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-time-picker-panel-invalid") ]
                    (TimePicker.panel Theme.default { dpTimeBaseOpts | hours = TimePicker.OnlyUnits [ 0 ] })
                , Element.el [ Element.htmlAttribute (HA.id "live-time-picker-panel-12h") ]
                    (TimePicker.panel Theme.default { dpTimeBaseOpts | use12Hours = True })
                , Element.el [ Element.htmlAttribute (HA.id "live-time-picker-panel-actions") ]
                    (TimePicker.panel Theme.default { dpTimeBaseOpts | actions = [ TimePicker.Clear, TimePicker.Now, TimePicker.Confirm ] })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-picker") ]
                    (DatePicker.view Theme.default { dpBaseOpts | type_ = DatePicker.Date, value = DatePicker.Single (Just dpMay09) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-picker-range") ]
                    (DatePicker.view Theme.default { dpBaseOpts | type_ = DatePicker.Daterange, value = DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd )) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-date") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Date, value = DatePicker.Single (Just dpMay09) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-week") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Week, value = DatePicker.Single (Just dpMayAnchor) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-datetime") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Datetime, value = DatePicker.Single (Just dpTSA) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-daterange") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Daterange, value = DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd )) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-datetimerange") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Datetimerange, value = DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd )) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-month") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Month, value = DatePicker.Single (Just dpMayAnchor) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-year") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Year, value = DatePicker.Single (Just dpMayAnchor) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-quarter") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Quarter, value = DatePicker.Single (Just dpMayAnchor) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-monthrange") ]
                    (DatePicker.panel Theme.default { dpBaseOpts | type_ = DatePicker.Monthrange, value = DatePicker.Range (Just ( dpMayAnchor, dpRangeEnd )) })
                , Element.el [ Element.htmlAttribute (HA.id "live-date-panel-zone") ]
                    (DatePicker.panel Theme.default
                        { dpBaseOpts
                            | zone = Time.customZone 480 []
                            , now = Time.millisToPosix dpZoneNow
                            , value = DatePicker.Single (Just dpZoneValue)
                        }
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-input-pair") ]
                    (let
                        d =
                            Input.defaults
                     in
                     Input.view Theme.default
                        { d
                            | pairValue = Just ( "2024-05-01", "2024-05-11" )
                            , pairPlaceholder = Just ( "Start", "End" )
                            , attrSize = Just 12
                            , pairTextDecoration = Just ( "line-through", "" )
                            , clearable = True
                            , internalForceFocus = True
                        }
                    )
                ]
            )
        ]
