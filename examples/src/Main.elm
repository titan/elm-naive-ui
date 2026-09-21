module Main exposing (main)

{-| Showcase page for elm-naive-ui: every component, rendered by the library.
-}

import Element exposing (Element)
import Element.Background as Bg
import Element.Font as Font
import Html
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
import NUI.Divider as Divider
import NUI.Dropdown as Dropdown
import NUI.DynamicInput as DynamicInput
import NUI.DynamicTags as DynamicTags
import NUI.Ellipsis as Ellipsis
import NUI.Empty as Empty
import NUI.Flex as Flex
import NUI.FloatButton as FloatButton
import NUI.FloatButtonGroup as FloatButtonGroup
import NUI.GradientText as GradientText
import NUI.Grid as Grid
import NUI.Heatmap as Heatmap
import NUI.Highlight as Highlight
import NUI.Icon as Icon
import NUI.IconWrapper as IconWrapper
import NUI.Input as Input
import NUI.InputNumber as InputNumber
import NUI.InputOtp as InputOtp
import NUI.Internal as I
import NUI.Layout as Layout
import NUI.LayoutFooter as LayoutFooter
import NUI.LayoutHeader as LayoutHeader
import NUI.LayoutSider as LayoutSider
import NUI.List as NList
import NUI.LoadingBar as LoadingBar
import NUI.Marquee as Marquee
import NUI.Modal as Modal
import NUI.NumberAnimation as NumberAnimation
import NUI.PageHeader as PageHeader
import NUI.Pagination as Pagination
import NUI.Popover as Popover
import NUI.Progress as Progress
import NUI.QrCode as QrCode
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
import NUI.Switch as Switch
import NUI.Tabs as Tabs
import NUI.Tag as Tag
import NUI.Theme as Theme exposing (Theme)
import NUI.Thing as Thing
import NUI.Timeline as Timeline
import NUI.Tooltip as Tooltip
import NUI.Types as T
import NUI.Typography as Typo
import Time



-- THEMES


theme : Theme
theme =
    Theme.default


purple : Theme
purple =
    Theme.setPrimary "#7c3aed" theme


darkTheme : Theme
darkTheme =
    Theme.dark



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


btn : Button.Options msg
btn =
    Button.defaults


typ : Typo.Options msg
typ =
    Typo.defaults


tagD : Tag.Options msg
tagD =
    Tag.defaults


alertD : Alert.Options msg
alertD =
    Alert.defaults


inputD : Input.Options msg
inputD =
    Input.defaults


iotpD : InputOtp.Options msg
iotpD =
    InputOtp.defaults


cbD : Checkbox.Options msg
cbD =
    Checkbox.defaults


swD : Switch.Options msg
swD =
    Switch.defaults


radioD : Radio.Options msg
radioD =
    Radio.defaults


radioGD : Radio.GroupOptions String msg
radioGD =
    Radio.groupDefaults


divD : Divider.Options msg
divD =
    Divider.defaults


dtagsD : DynamicTags.Options msg
dtagsD =
    DynamicTags.defaults


lbD : LoadingBar.Options msg
lbD =
    LoadingBar.defaults


diD : DynamicInput.InputOptions msg
diD =
    DynamicInput.inputDefaults


diPairD : DynamicInput.PairOptions msg
diPairD =
    DynamicInput.pairDefaults


descD : Descriptions.Options msg
descD =
    Descriptions.defaults


descItemD : Descriptions.Item msg
descItemD =
    Descriptions.itemDefaults


tabsD : Tabs.Options msg
tabsD =
    Tabs.defaults


tabsItems : List (Tabs.Tab msg)
tabsItems =
    [ { name = "one", label = Element.text "One", disabled = False, closable = Nothing, content = [ Element.text "First pane" ] }
    , { name = "two", label = Element.text "Two", disabled = False, closable = Nothing, content = [ Element.text "Second pane" ] }
    , { name = "three", label = Element.text "Three", disabled = True, closable = Nothing, content = [ Element.text "Third pane" ] }
    ]


scrollbarD : Scrollbar.Options msg
scrollbarD =
    Scrollbar.defaults


popoverD : Popover.Options msg
popoverD =
    Popover.defaults


tooltipD : Tooltip.Options msg
tooltipD =
    Tooltip.defaults


dropdownD : Dropdown.Options msg
dropdownD =
    Dropdown.defaults


modalD : Modal.Options msg
modalD =
    Modal.defaults


modalCardD : Card.Options msg
modalCardD =
    Modal.cardDefaults


avD : Avatar.Options msg
avD =
    Avatar.defaults


agD : AvatarGroup.Options msg
agD =
    AvatarGroup.defaults


bgD : ButtonGroup.Options msg
bgD =
    ButtonGroup.defaults


calD : Calendar.Options msg
calD =
    Calendar.defaults


pgD : Pagination.Options msg
pgD =
    Pagination.defaults


inD : InputNumber.Options msg
inD =
    InputNumber.defaults


layD : Layout.Options msg
layD =
    Layout.defaults


lhD : LayoutHeader.Options msg
lhD =
    LayoutHeader.defaults


lfD : LayoutFooter.Options msg
lfD =
    LayoutFooter.defaults


lsD : LayoutSider.Options msg
lsD =
    LayoutSider.defaults


cardD : Card.Options msg
cardD =
    Card.defaults


spaceD : Space.Options msg
spaceD =
    Space.defaults


badgeD : Badge.Options msg
badgeD =
    Badge.defaults


emptyD : Empty.Options msg
emptyD =
    Empty.defaults


progD : Progress.Options msg
progD =
    Progress.defaults


resultD : Result.Options msg
resultD =
    Result.defaults


skelD : Skeleton.Options msg
skelD =
    Skeleton.defaults


spinD : Spin.Options msg
spinD =
    Spin.defaults


gtD : GradientText.Options msg
gtD =
    GradientText.defaults


statD : Statistic.Options msg
statD =
    Statistic.defaults


bcD : Breadcrumb.Options msg
bcD =
    Breadcrumb.defaults


bcItem : Breadcrumb.Item msg
bcItem =
    Breadcrumb.item


tlD : Timeline.Options msg
tlD =
    Timeline.defaults


tlItem : Timeline.Item msg
tlItem =
    Timeline.item


thingD : Thing.Options msg
thingD =
    Thing.defaults


marqueeD : Marquee.Options msg
marqueeD =
    Marquee.defaults


nlistD : NList.Options msg
nlistD =
    NList.defaults


nlistItem : NList.Item msg
nlistItem =
    NList.item


pageHeaderD : PageHeader.Options msg
pageHeaderD =
    PageHeader.defaults


affixD : Affix.Options msg
affixD =
    Affix.defaults


countdownD : Countdown.Options msg
countdownD =
    Countdown.defaults


splitD : Split.Options msg
splitD =
    Split.defaults


stepsD : Steps.Options msg
stepsD =
    Steps.defaults


stepsItem : Steps.Item msg
stepsItem =
    Steps.item


backTopD : BackTop.Options msg
backTopD =
    BackTop.defaults


ellipsisD : Ellipsis.Options msg
ellipsisD =
    Ellipsis.defaults


qrD : QrCode.Options msg
qrD =
    QrCode.defaults


collapseD : Collapse.Options msg
collapseD =
    Collapse.defaults


collapseItem : Collapse.Item msg
collapseItem =
    Collapse.item


rateD : Rate.Options msg
rateD =
    Rate.defaults


floatButtonD : FloatButton.Options msg
floatButtonD =
    FloatButton.defaults


floatButtonGroupD : FloatButtonGroup.Options msg
floatButtonGroupD =
    FloatButtonGroup.defaults


highlightD : Highlight.Options msg
highlightD =
    Highlight.defaults


iconD : Icon.Options msg
iconD =
    Icon.defaults


iconWrapperD : IconWrapper.Options msg
iconWrapperD =
    IconWrapper.defaults


heatmapD : Heatmap.Options msg
heatmapD =
    Heatmap.defaults


numberAnimationD : NumberAnimation.Options msg
numberAnimationD =
    NumberAnimation.defaults


flexD : Flex.Options msg
flexD =
    Flex.defaults


gridD : Grid.Options msg
gridD =
    Grid.defaults


gridItem : Grid.Item msg
gridItem =
    Grid.item


{-| A distinct colour per showcase avatar (the group's slot path uses the
`src` as a label).
-}
avatarColor : String -> String
avatarColor name =
    case name of
        "Alice" ->
            "#18a058"

        "Bob" ->
            "#2080f0"

        "Carol" ->
            "#f0a020"

        "Dave" ->
            "#d03050"

        _ ->
            "#8a8a8a"



-- PAGE


main : Html.Html msg
main =
    Css.layout [] page


page : Element msg
page =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Bg.color (Element.rgb 1 1 1)
        , Font.family [ Font.typeface "system-ui", Font.sansSerif ]
        ]
        (Element.el
            [ Element.width (Element.maximum 880 Element.fill)
            , Element.centerX
            , Element.paddingXY 24 40
            ]
            (Element.column [ Element.spacing 34, Element.width Element.fill ]
                (Css.element :: header ++ body)
            )
        )


header : List (Element msg)
header =
    [ Element.column [ Element.spacing 8 ]
        [ Typo.h1 theme typ [ Element.text "Naive UI for Elm" ]
        , Typo.text theme
            { typ | depth = Just 3 }
            [ Element.text "Naive UI components built on elm-ui — Naive UI's own CSS, driven by a typed Elm theme." ]
        ]
    ]


body : List (Element msg)
body =
    [ typographySection
    , buttonSection
    , tagSection
    , alertSection
    , inputSection
    , inputOtpSection
    , dynamicTagsSection
    , calendarSection
    , paginationSection
    , inputNumberSection
    , selectionSection
    , dividerSection
    , avatarSection
    , cardSection
    , spaceSection
    , badgeSection
    , emptySection
    , progressSection
    , resultSection
    , skeletonSection
    , spinSection
    , gradientTextSection
    , statisticSection
    , breadcrumbSection
    , timelineSection
    , thingSection
    , marqueeSection
    , listSection
    , pageHeaderSection
    , affixSection
    , countdownSection
    , splitSection
    , layoutSection
    , flexSection
    , gridSection
    , stepsSection
    , ellipsisSection
    , backTopSection
    , qrCodeSection
    , collapseSection
    , rateSection
    , floatButtonSection
    , floatButtonGroupSection
    , iconSection
    , highlightSection
    , numberAnimationSection
    , heatmapSection
    , loadingBarSection
    , dynamicInputSection
    , descriptionsSection
    , tabsSection
    , scrollbarSection
    , popoverSection
    , tooltipSection
    , dropdownSection
    , modalSection
    , rtlSection
    , themeSection
    ]



-- SECTIONS


typographySection : Element msg
typographySection =
    section "Typography"
        "Headers, text and rich content."
        [ Typo.h1 theme typ [ Element.text "H1 Heading" ]
        , Typo.h3 theme typ [ Element.text "H3 Heading" ]
        , Typo.p theme
            typ
            [ Element.text "Body copy. Naive UI's typography scale, weights and colours." ]
        , Element.wrappedRow [ Element.spacing 16 ]
            (List.map
                (\k -> Typo.text theme { typ | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
                [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
            )
        , demoRow "Styles"
            [ Typo.text theme { typ | strong = True } [ Element.text "Strong" ]
            , Typo.text theme { typ | italic = True } [ Element.text "Italic" ]
            , Typo.text theme { typ | underline = True } [ Element.text "Underline" ]
            , Typo.text theme { typ | delete = True } [ Element.text "Deleted" ]
            , Typo.text theme { typ | code = True } [ Element.text "code" ]
            ]
        , Typo.blockquote theme
            typ
            [ Element.text "A quote renders with the blockquote bar and muted colour." ]
        , Typo.ul theme
            typ
            [ Typo.li [ Element.text "First item" ]
            , Typo.li [ Element.text "Second item" ]
            ]
        , Typo.hr theme
        , Typo.a theme
            { typ | href = Just "https://www.naiveui.com" }
            [ Element.text "A link" ]
        ]


buttonSection : Element msg
buttonSection =
    section "Button" "Sizes, types, variants and shapes." <|
        [ demoRow "Sizes"
            [ Button.view theme { btn | size = T.Tiny } [ Element.text "Tiny" ]
            , Button.view theme { btn | size = T.Small } [ Element.text "Small" ]
            , Button.view theme { btn | size = T.Medium } [ Element.text "Medium" ]
            , Button.view theme { btn | size = T.Large } [ Element.text "Large" ]
            ]
        , demoRow "Types"
            (List.map
                (\k -> Button.view theme { btn | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
                [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
            )
        , demoRow "Variants"
            [ Button.view theme { btn | kind = T.Primary, variant = Button.Secondary } [ Element.text "Secondary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Tertiary } [ Element.text "Tertiary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Quaternary } [ Element.text "Quaternary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Text } [ Element.text "Text" ]
            ]
        , demoRow "Shapes & states"
            [ Button.view theme { btn | round = True } [ Element.text "Round" ]
            , Button.view theme { btn | circle = True } [ Element.text "C" ]
            , Button.view theme { btn | dashed = True } [ Element.text "Dashed" ]
            , Button.view theme { btn | kind = T.Primary, ghost = True } [ Element.text "Ghost" ]
            , Button.view theme { btn | disabled = True } [ Element.text "Disabled" ]
            , Button.view theme { btn | loading = True } [ Element.text "Loading" ]
            ]
        , Element.el [ Element.width (Element.px 320) ]
            (Button.view theme { btn | block = True } [ Element.text "Block" ])
        , demoRow "Group"
            [ ButtonGroup.view theme
                ButtonGroup.defaults
                [ Button.view theme { btn | kind = T.Primary } [ Element.text "Left" ]
                , Button.view theme { btn | kind = T.Primary } [ Element.text "Middle" ]
                , Button.view theme { btn | kind = T.Primary } [ Element.text "Right" ]
                ]
            , ButtonGroup.view theme
                { bgD | vertical = True }
                [ Button.view theme btn [ Element.text "Top" ]
                , Button.view theme btn [ Element.text "Bottom" ]
                ]
            ]
        ]


tagSection : Element msg
tagSection =
    section "Tag" "Compact labels, with optional close and check states." <|
        [ demoRow "Types"
            (List.map
                (\k -> Tag.view theme { tagD | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
                [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
            )
        , demoRow "Shapes & states"
            [ Tag.view theme { tagD | round = True } [ Element.text "Round" ]
            , Tag.view theme { tagD | bordered = False } [ Element.text "Filled" ]
            , Tag.view theme { tagD | kind = T.Primary, strong = True } [ Element.text "Strong" ]
            , Tag.view theme { tagD | closable = True } [ Element.text "Closable" ]
            , Tag.view theme { tagD | kind = T.Success, checkable = True, checked = True } [ Element.text "Checked" ]
            , Tag.view theme { tagD | disabled = True } [ Element.text "Disabled" ]
            ]
        ]


alertSection : Element msg
alertSection =
    section "Alert" "Inline messages." <|
        [ Alert.view theme alertD [ Element.text "A default alert." ]
        , Alert.view theme
            { alertD | kind = T.Info, title = Just "Info" }
            [ Element.text "With a title and icon." ]
        , Alert.view theme
            { alertD | kind = T.Success, title = Just "Success", closable = True }
            [ Element.text "Closable alert." ]
        , Alert.view theme { alertD | kind = T.Warning } [ Element.text "A warning." ]
        , Alert.view theme
            { alertD | kind = T.Error, bordered = False }
            [ Element.text "Borderless error." ]
        ]


inputSection : Element msg
inputSection =
    section "Input" "Text fields, statuses and a textarea." <|
        [ demoRow "Basics"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | placeholder = Just "Placeholder" })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Hello", round = True })
            ]
        , demoRow "Statuses"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Success", status = Just Input.Success })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Warning", status = Just Input.Warning })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Error", status = Just Input.Error })
            ]
        , demoRow "States"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Disabled", disabled = True })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Clearable", clearable = True })
            ]
        , Element.el [ Element.width (Element.px 440) ]
            (Input.view theme
                { inputD
                    | type_ = Input.Textarea
                    , rows = 3
                    , value = "A textarea.\nMultiple lines."
                }
            )
        ]


inputOtpSection : Element msg
inputOtpSection =
    section "Input OTP" "One-time-code inputs (the value and focus are caller-owned)." <|
        [ demoRow "Lengths & sizes"
            [ InputOtp.view theme { iotpD | length = 4, value = [ "1", "2", "3", "4" ] } []
            , InputOtp.view theme { iotpD | length = 6, size = InputOtp.Small, gap = Just (InputOtp.Px 6) } []
            , InputOtp.view theme { iotpD | length = 6, mask = True } []
            ]
        , demoRow "RTL"
            [ InputOtp.view theme { iotpD | rtl = True, length = 6, value = [ "8", "8", "8" ] } []
            ]
        ]


dynamicTagsSection : Element msg
dynamicTagsSection =
    section "Dynamic Tags" "Editable tag lists (the tags, input and draft are caller-owned)." <|
        [ demoRow "Tags"
            [ DynamicTags.view theme
                { dtagsD | value = [ "Naive UI", "Elm", "elm-ui" ] }
                []
            , DynamicTags.view theme
                { dtagsD | value = [ "small", "medium" ], size = T.Small, round = True }
                []
            ]
        , demoRow "Input shown (caller owns the draft)"
            [ DynamicTags.view theme
                { dtagsD | value = [ "one", "two" ], showInput = True, inputValue = "thr" }
                []
            ]
        ]


calendarSection : Element msg
calendarSection =
    section "Calendar" "A month view (the panel, value and locale are caller-owned)." <|
        [ Element.el [ Element.width (Element.px 420) ]
            (Calendar.view theme
                { calD | panel = { year = 2024, month = 6 }, now = { year = 2024, month = 6, day = 15 } }
            )
        , Element.el [ Element.width (Element.px 420) ]
            (Calendar.view theme
                { calD
                    | panel = { year = 2024, month = 6 }
                    , now = { year = 2024, month = 6, day = 15 }
                    , value = Just { year = 2024, month = 6, day = 20 }
                }
            )
        ]


paginationSection : Element msg
paginationSection =
    section "Pagination" "Page windows (the page, the page size and the jumper text are caller-owned)." <|
        [ Pagination.view theme { pgD | itemCount = Just 153, currentPage = 2 } []
        , Pagination.view theme { pgD | itemCount = Just 153, currentPage = 6 } []
        , Pagination.view theme { pgD | itemCount = Just 42, currentPage = 3, simple = True } []
        , Pagination.view theme
            { pgD
                | itemCount = Just 500
                , currentPage = 12
                , showQuickJumper = True
                , jumperValue = "12"
                , suffix = Just (Element.text "items")
            }
            []
        , Pagination.view theme { pgD | itemCount = Just 90, currentPage = 4, disabled = True } []
        ]


inputNumberSection : Element msg
inputNumberSection =
    section "Input Number" "Numeric entry (the text buffer is caller-owned)." <|
        [ InputNumber.view theme { inD | value = Just 3 } []
        , InputNumber.view theme
            { inD
                | value = Just 0.5
                , min = Just 0
                , max = Just 1
                , step = 0.01
                , precision = Just 2
            }
            []
        , InputNumber.view theme { inD | value = Just 42, buttonPlacement = InputNumber.Both } []
        , InputNumber.view theme { inD | value = Nothing, placeholder = Just "Enter a number" } []
        , InputNumber.view theme { inD | value = Just 7, disabled = True } []
        ]


selectionSection : Element msg
selectionSection =
    section "Checkbox · Switch · Radio" "Selection controls." <|
        [ demoRow "Checkbox"
            [ Checkbox.view theme { cbD | checked = True } [ Element.text "Checked" ]
            , Checkbox.view theme cbD [ Element.text "Unchecked" ]
            , Checkbox.view theme { cbD | indeterminate = True } [ Element.text "Indeterminate" ]
            , Checkbox.view theme { cbD | disabled = True, checked = True } [ Element.text "Disabled" ]
            ]
        , demoRow "Switch"
            [ Switch.view theme { swD | value = False } []
            , Switch.view theme { swD | value = True } []
            , Switch.view theme { swD | value = True, loading = True } []
            , Switch.view theme { swD | value = False, disabled = True } []
            ]
        , demoRow "Radio group"
            [ Radio.group theme
                { radioGD | value = Just "sh" }
                [ Radio.choice "bj" "Beijing", Radio.choice "sh" "Shanghai", Radio.choice "gz" "Guangzhou" ]
            ]
        , demoRow "Radio button group"
            [ Radio.group theme
                { radioGD | value = Just "m" }
                [ Radio.button "s" "Small", Radio.button "m" "Medium", Radio.button "l" "Large" ]
            ]
        , demoRow "Radio standalone"
            [ Radio.view theme { radioD | checked = True } [ Element.text "Selected" ]
            , Radio.view theme radioD [ Element.text "Unselected" ]
            , Radio.view theme { radioD | disabled = True } [ Element.text "Disabled" ]
            ]
        ]


dividerSection : Element msg
dividerSection =
    section "Divider" "Separates content." <|
        [ Divider.view theme { divD | titlePlacement = Divider.Left } [ Element.text "Left" ]
        , Divider.view theme { divD | titlePlacement = Divider.Center } [ Element.text "Center" ]
        , Divider.view theme { divD | titlePlacement = Divider.Right } [ Element.text "Right" ]
        , Divider.view theme { divD | dashed = True } []
        , Element.row [ Element.spacing 16, Element.height (Element.px 42) ]
            [ Element.text "Text"
            , Divider.view theme { divD | vertical = True } []
            , Element.text "More"
            , Divider.view theme { divD | vertical = True } []
            , Element.text "End"
            ]
        ]


avatarSection : Element msg
avatarSection =
    section "Avatar" "Sizes, shapes and colours." <|
        [ demoRow "Sizes"
            [ Avatar.view theme { avD | size = Avatar.Tiny } [ Element.text "T" ]
            , Avatar.view theme { avD | size = Avatar.Small } [ Element.text "S" ]
            , Avatar.view theme { avD | size = Avatar.Medium } [ Element.text "M" ]
            , Avatar.view theme { avD | size = Avatar.Large } [ Element.text "L" ]
            , Avatar.view theme { avD | size = Avatar.Huge } [ Element.text "H" ]
            ]
        , demoRow "Shapes & colours"
            [ Avatar.view theme { avD | circle = True, color = Just "#18a058" } [ Element.text "A" ]
            , Avatar.view theme { avD | circle = True, color = Just "#2080f0" } [ Element.text "B" ]
            , Avatar.view theme { avD | color = Just "#f0a020" } [ Element.text "Rounded" ]
            ]
        , demoRow "Group"
            [ AvatarGroup.view theme
                { agD
                    | max = Just 3
                    , avatar =
                        Just
                            (\opt ->
                                Avatar.view theme
                                    { avD | color = Just (avatarColor opt.src) }
                                    [ Element.text (String.left 1 opt.src) ]
                            )
                }
                [ { src = "Alice" }
                , { src = "Bob" }
                , { src = "Carol" }
                , { src = "Dave" }
                , { src = "Eve" }
                ]
            , AvatarGroup.view theme
                { agD | vertical = True, size = Just Avatar.Medium }
                [ { src = "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg" }
                , { src = "https://picsum.photos/id/1/100/100" }
                , { src = "https://picsum.photos/id/2/100/100" }
                ]
            ]
        ]


cardSection : Element msg
cardSection =
    section "Card" "Bordered containers, optionally hoverable." <|
        [ Element.row [ Element.spacing 16, Element.width Element.fill ]
            [ Element.el [ Element.width Element.fill ]
                (Card.view theme
                    { cardD | title = Just (Element.text "Basic card") }
                    [ Element.text "Content of the card." ]
                )
            , Element.el [ Element.width Element.fill ]
                (Card.view theme
                    { cardD | title = Just (Element.text "Hoverable"), hoverable = True }
                    [ Element.text "Hover me for a shadow." ]
                )
            ]
        , Card.view theme
            { cardD
                | title = Just (Element.text "With header extra")
                , headerExtra = Just (Tag.view theme { tagD | kind = T.Primary } [ Element.text "New" ])
                , footer = Just (Element.text "Footer")
            }
            [ Element.text "Card body content." ]
        , Card.view theme
            { cardD | embedded = True, title = Just (Element.text "Embedded") }
            [ Element.text "An embedded (inset) card." ]
        ]


spaceSection : Element msg
spaceSection =
    section "Space" "Spacing between arbitrary children." <|
        [ demoRow "Small gap"
            [ Space.view theme { spaceD | size = Space.Small } (List.map chip [ "One", "Two", "Three" ]) ]
        , demoRow "Medium gap"
            [ Space.view theme { spaceD | size = Space.Medium } (List.map chip [ "One", "Two", "Three" ]) ]
        , demoRow "Vertical"
            [ Space.view theme
                { spaceD | direction = Space.Vertical, size = Space.Medium }
                (List.map chip [ "Stacked", "Vertically", "Spaced" ])
            ]
        ]


badgeSection : Element msg
badgeSection =
    section "Badge" "Counts and status dots on arbitrary content." <|
        [ demoRow "Annotating a button"
            [ Badge.view theme
                { badgeD | value = Just (Badge.Number 5) }
                [ Button.view theme { btn | size = T.Small } [ Element.text "Mail" ] ]
            , Badge.view theme
                { badgeD | value = Just (Badge.Number 200), max = Just 99 }
                [ Button.view theme { btn | size = T.Small } [ Element.text "Inbox" ] ]
            , Badge.view theme
                { badgeD | dot = True, processing = True, type_ = Badge.Error }
                [ Button.view theme { btn | size = T.Small } [ Element.text "Alerts" ] ]
            ]
        , demoRow "Types"
            (List.map
                (\t ->
                    Badge.view theme
                        { badgeD | value = Just (Badge.Number 9), type_ = t }
                        []
                )
                [ Badge.Default, Badge.Info, Badge.Success, Badge.Warning, Badge.Error ]
            )
        , demoRow "Custom colour"
            [ Badge.view theme
                { badgeD | value = Just (Badge.Text "New"), color = Just "#36ad6a" }
                []
            , Badge.view theme { badgeD | dot = True, color = Just "#18a058" } []
            ]
        , demoRow "Runtime (digit scroll · wave)"
            [ Badge.view theme
                { badgeD
                    | value = Just (Badge.Number 128)
                    , previousValue = Just (Badge.Number 118)
                }
                []
            , Badge.view theme
                { badgeD
                    | value = Just (Badge.Number 5)
                    , processing = True
                    , waveActive = True
                }
                []
            ]
        ]


emptySection : Element msg
emptySection =
    section "Empty" "Placeholder for empty states." <|
        [ demoRow "Default"
            [ Element.el [ Element.width (Element.px 240) ]
                (Empty.view theme emptyD [])
            ]
        , demoRow "Description & extra"
            [ Element.el [ Element.width (Element.px 240) ]
                (Empty.view theme
                    { emptyD
                        | description = Just "Nothing here yet."
                        , extra = Just (Button.view theme { btn | size = T.Small } [ Element.text "Reload" ])
                    }
                    []
                )
            ]
        , demoRow "Sizes"
            [ Element.el [ Element.width (Element.px 150) ]
                (Empty.view theme { emptyD | size = Empty.Small, description = Just "Small" } [])
            , Element.el [ Element.width (Element.px 260) ]
                (Empty.view theme { emptyD | size = Empty.Large, description = Just "Large" } [])
            ]
        ]


progressSection : Element msg
progressSection =
    section "Progress" "Line, circle, dashboard and multiple-circle meters." <|
        [ demoRow "Line"
            [ Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme { progD | percentage = 50 } [])
            , Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD | percentage = 66, processing = True, height = Just 12 }
                    []
                )
            , Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD
                        | percentage = 40
                        , railColor = Just "#e0e0e0"
                        , railStyle =
                            Just
                                [ ( "background-image"
                                  , "repeating-linear-gradient(45deg, #eee, #eee 6px, #ddd 6px, #ddd 12px)"
                                  )
                                ]
                    }
                    []
                )
            ]
        , demoRow "Statuses"
            [ Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD | percentage = 100, status = Progress.Success }
                    []
                )
            , Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD | percentage = 32, status = Progress.Error }
                    []
                )
            ]
        , demoRow "Circle & dashboard"
            [ Progress.view theme { progD | type_ = Progress.Circle, percentage = 75 } []
            , Progress.view theme { progD | type_ = Progress.Dashboard, percentage = 60 } []
            ]
        , demoRow "Multiple circle"
            [ Progress.view theme
                { progD
                    | type_ = Progress.MultipleCircle
                    , percentages = [ 80, 60 ]
                    , colors = [ Progress.Solid "#2080f0", Progress.Solid "#18a058" ]
                    , railColors = [ "#2080f0", "#18a058" ]
                    , railStyles =
                        [ [ ( "stroke", "#2080f0" ), ( "opacity", "0.3" ) ]
                        , [ ( "stroke", "#18a058" ), ( "opacity", "0.3" ) ]
                        ]
                    , strokeWidth = 6
                    , circleGap = 0.5
                }
                [ Element.text "Circle racing!" ]
            , Progress.view theme
                { progD
                    | type_ = Progress.MultipleCircle
                    , percentages = [ 70, 40 ]
                    , strokeWidth = 10
                    , circleGap = 10
                }
                []
            ]
        , demoRow "Gradients"
            [ Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD
                        | percentage = 80
                        , color = Just (Progress.Gradient [ "white", "pink" ])
                    }
                    []
                )
            , Progress.view theme
                { progD
                    | type_ = Progress.Circle
                    , percentage = 80
                    , color = Just (Progress.Gradient [ "#E3F2FD", "#2080f0" ])
                }
                []
            , Progress.view theme
                { progD
                    | type_ = Progress.MultipleCircle
                    , percentages = [ 80, 70 ]
                    , colors =
                        [ Progress.Gradient [ "white", "#18a058" ]
                        , Progress.Gradient [ "#E3F2FD", "#2080f0" ]
                        ]
                    , railColors = [ "#18a058", "#2080f0" ]
                    , strokeWidth = 10
                    , circleGap = 10
                }
                [ Element.text "Circle racing!" ]
            ]
        ]


resultSection : Element msg
resultSection =
    section "Result" "Important feedback pages." <|
        [ demoRow "Statuses"
            [ Element.el [ Element.width (Element.px 210) ]
                (Result.view theme
                    { resultD | status = Result.Info, title = Just "Informational" }
                    []
                )
            , Element.el [ Element.width (Element.px 210) ]
                (Result.view theme
                    { resultD | status = Result.Success, title = Just "Successful" }
                    []
                )
            ]
        , Element.el [ Element.width (Element.px 340) ]
            (Result.view theme
                { resultD
                    | status = Result.Code404
                    , title = Just "404"
                    , description = Just "The page you are looking for does not exist."
                    , footer = Just (Button.view theme btn [ Element.text "Back home" ])
                }
                [ Element.text "Custom content can fill the default slot." ]
            )
        ]


skeletonSection : Element msg
skeletonSection =
    section "Skeleton" "Placeholder shimmer for loading content." <|
        [ demoRow "Default"
            [ Skeleton.view theme
                { skelD
                    | width = Just (Skeleton.Px 240)
                    , height = Just (Skeleton.Px 16)
                }
                []
            ]
        , demoRow "Text & repeat"
            [ Skeleton.view theme
                { skelD | text = True, width = Just (Skeleton.Px 150), repeat = 3 }
                []
            ]
        , demoRow "Shapes & states"
            [ Skeleton.view theme { skelD | circle = True, width = Just (Skeleton.Px 40) } []
            , Skeleton.view theme
                { skelD
                    | round = True
                    , width = Just (Skeleton.Px 100)
                    , height = Just (Skeleton.Px 12)
                }
                []
            , Skeleton.view theme
                { skelD
                    | width = Just (Skeleton.Px 100)
                    , height = Just (Skeleton.Px 12)
                    , animated = False
                }
                []
            ]
        ]


spinSection : Element msg
spinSection =
    section "Spin" "Loading spinners, standalone or wrapping content." <|
        [ demoRow "Standalone"
            [ Spin.view theme spinD []
            , Spin.view theme { spinD | size = Spin.Small } []
            , Spin.view theme { spinD | size = Spin.Large } []
            ]
        , demoRow "With description"
            [ Spin.view theme { spinD | description = Just (Element.text "Loading") } []
            ]
        , demoRow "Wrapping content"
            [ Element.el [ Element.width (Element.px 320), Element.height (Element.px 110) ]
                (Spin.view theme
                    spinD
                    [ Card.view theme
                        { cardD | title = Just (Element.text "A card") }
                        [ Element.text "The spinner overlays this content while loading." ]
                    ]
                )
            ]
        ]


gradientTextSection : Element msg
gradientTextSection =
    section "Gradient Text" "Themed gradient text." <|
        [ demoRow "Types"
            (List.map
                (\t -> GradientText.view theme { gtD | type_ = t } [ Element.text "Wonderful" ])
                [ GradientText.Primary
                , GradientText.Info
                , GradientText.Success
                , GradientText.Warning
                , GradientText.Error
                ]
            )
        , demoRow "Custom gradient"
            [ GradientText.view theme
                { gtD
                    | gradient =
                        Just (GradientText.Raw "linear-gradient(90deg, #d03050, #2080f0)")
                }
                [ Element.text "Raw CSS" ]
            , GradientText.view theme
                { gtD | gradient = Just (GradientText.fromTo "#18a058" "#2080f0") }
                [ Element.text "From / To" ]
            , GradientText.view theme { gtD | size = Just "22px" } [ Element.text "Sized" ]
            ]
        ]


statisticSection : Element msg
statisticSection =
    section "Statistic" "Labelled numeric displays." <|
        [ demoRow "Basic"
            [ Statistic.view theme
                { statD | label = Just "Active users", value = Just "128" }
                []
            , Statistic.view theme
                { statD
                    | label = Just "Revenue"
                    , value = Just "1,024"
                    , prefix = Just (Element.text "$")
                }
                []
            ]
        , demoRow "Tabular nums & custom value"
            [ Statistic.view theme
                { statD
                    | label = Just "Growth"
                    , tabularNums = True
                    , suffix = Just (Element.text "%")
                }
                [ Element.text "12.5" ]
            ]
        ]


breadcrumbSection : Element msg
breadcrumbSection =
    section "Breadcrumb" "Navigation trails." <|
        [ Breadcrumb.view theme
            bcD
            [ { bcItem | href = Just "/", content = [ Element.text "Home" ] }
            , { bcItem | href = Just "/library", content = [ Element.text "Library" ] }
            , { bcItem | content = [ Element.text "Data" ] }
            ]
        , Breadcrumb.view theme
            { bcD | separator = "›" }
            [ { bcItem | separator = Just "›", href = Just "/", content = [ Element.text "Root" ] }
            , { bcItem | separator = Just "›", content = [ Element.text "Leaf" ] }
            ]
        ]


timelineSection : Element msg
timelineSection =
    section "Timeline" "Vertical event trails." <|
        [ Timeline.view theme
            tlD
            [ { tlItem | time = Just "2023-01-01", content = [ Element.text "Project created" ] }
            , { tlItem
                | type_ = Timeline.Success
                , title = Just "Deployed"
                , time = Just "2023-01-02"
                , content = [ Element.text "Shipped to production." ]
              }
            , { tlItem
                | type_ = Timeline.Warning
                , lineType = Timeline.Dashed
                , content = [ Element.text "Investigating a warning" ]
              }
            ]
        , Timeline.view theme
            { tlD | itemPlacement = Timeline.Right }
            [ { tlItem | time = Just "1", content = [ Element.text "Right aligned" ] } ]
        ]


thingSection : Element msg
thingSection =
    section "Thing" "A flexible content block (avatar + header + body)." <|
        [ demoRow "With avatar"
            [ Element.el [ Element.width (Element.px 320) ]
                (Thing.view theme
                    { thingD
                        | avatar = Just (Avatar.view theme Avatar.defaults [ Element.text "N" ])
                        , title = Just "naive-ui"
                        , titleExtra = Just "v2"
                        , description = Just "A Vue 3 component library."
                    }
                    [ Element.text "Content sits under the header." ]
                )
            ]
        , demoRow "Indented content"
            [ Element.el [ Element.width (Element.px 320) ]
                (Thing.view theme
                    { thingD
                        | avatar = Just (Avatar.view theme Avatar.defaults [ Element.text "I" ])
                        , contentIndented = True
                        , title = Just "Indented"
                    }
                    [ Element.text "The avatar sits above the block." ]
                )
            ]
        ]


marqueeSection : Element msg
marqueeSection =
    section "Marquee" "Scrolling content (duration is caller-owned)." <|
        [ Element.el [ Element.width (Element.px 360) ]
            (Marquee.view theme
                { marqueeD | duration = 8, autoFill = True, repeat = 2 }
                [ Tag.view theme { tagD | kind = T.Primary } [ Element.text "Naive UI" ]
                , Element.text "  ·  scrolling text  ·  "
                , Tag.view theme { tagD | kind = T.Success } [ Element.text "Elm" ]
                ]
            )
        ]


listSection : Element msg
listSection =
    section "List" "Bordered, hoverable item lists." <|
        [ Element.el [ Element.width (Element.px 360) ]
            (NList.view theme
                { nlistD | bordered = True, hoverable = True }
                [ { nlistItem | content = [ Element.text "First item" ] }
                , { nlistItem
                    | prefix = Just (Element.text "•")
                    , content = [ Element.text "Second item" ]
                    , suffix = Just (Element.text "→")
                  }
                , { nlistItem | content = [ Element.text "Third item" ] }
                ]
            )
        ]


pageHeaderSection : Element msg
pageHeaderSection =
    section "Page Header"
        "Title, subtitle and extra (pass `onBack` to add the back control)."
    <|
        [ Element.el [ Element.width Element.fill ]
            (PageHeader.view theme
                { pageHeaderD
                    | title = Just "Page title"
                    , subtitle = Just "Second level"
                    , extra = Just "Extra"
                }
                [ Element.text "The page body sits below the header." ]
            )
        ]


affixSection : Element msg
affixSection =
    section "Affix" "Pins content while scrolling (the affixed state is caller-owned)." <|
        [ Element.el [ Element.height (Element.px 56) ]
            (Affix.view theme
                { affixD | affixed = True, top = Just 12 }
                [ Button.view theme { btn | kind = T.Primary } [ Element.text "Affixed" ] ]
            )
        ]


countdownSection : Element msg
countdownSection =
    section "Countdown" "Remaining time (the caller owns the clock)." <|
        [ demoRow "Precisions"
            [ Countdown.view theme { countdownD | distance = 90000, precision = 0 } []
            , Countdown.view theme { countdownD | distance = 90000, precision = 1 } []
            , Countdown.view theme { countdownD | distance = 90000, precision = 3 } []
            ]
        , demoRow "Custom render"
            [ Countdown.view theme
                { countdownD
                    | distance = 5000
                    , render =
                        Just
                            (\info ->
                                Element.text (String.fromInt info.seconds ++ "s left")
                            )
                }
                []
            ]
        ]


splitSection : Element msg
splitSection =
    section "Split" "Resizable panes (the size is caller-owned)." <|
        [ Element.el [ Element.height (Element.px 120), Element.width Element.fill ]
            (Split.view theme
                { splitD
                    | pane1 = [ Element.el [ Element.padding 8 ] (Element.text "Pane 1") ]
                    , pane2 = [ Element.el [ Element.padding 8 ] (Element.text "Pane 2") ]
                }
            )
        ]


flexSection : Element msg
flexSection =
    section "Flex"
        "Naive UI's flexbox primitive — an inline flex container (no stylesheet rule; the layout is inline `display`/`gap`)."
    <|
        [ Flex.view theme
            flexD
            [ chip "One", chip "Two", chip "Three" ]
        , Flex.view theme
            { flexD | justify = Flex.SpaceBetween, size = Flex.Number 16 }
            [ chip "Left", chip "Right" ]
        , Flex.view theme
            { flexD | direction = Flex.Vertical, size = Flex.Number 8, align = Just Flex.Center }
            [ chip "Top", chip "Middle", chip "Bottom" ]
        , Flex.view theme
            { flexD | inline = True, size = Flex.Number2 4 12, reverse = True }
            [ chip "A", chip "B", chip "C" ]
        ]


gridSection : Element msg
gridSection =
    section "Grid"
        "A 24-column CSS grid (inline `display:grid`, no stylesheet rule); span/offset and the responsive collapse algorithm are caller-driven."
    <|
        [ Grid.view
            { gridD | cols = Grid.Number 12, xGap = Grid.Number 16, yGap = Grid.Number 16 }
            [ { gridItem | span = Grid.Number 6, content = [ chip "span 6" ] }
            , { gridItem | span = Grid.Number 6, content = [ chip "span 6" ] }
            , { gridItem | span = Grid.Number 4, content = [ chip "span 4" ] }
            , { gridItem | span = Grid.Number 8, content = [ chip "span 8" ] }
            ]
        , Grid.view
            { gridD
                | cols = Grid.Number 12
                , xGap = Grid.Number 12
                , collapsed = True
                , collapsedRows = 1
            }
            [ { gridItem | span = Grid.Number 4, content = [ chip "4" ] }
            , { gridItem | span = Grid.Number 4, content = [ chip "4" ] }
            , { gridItem | span = Grid.Number 4, content = [ chip "4" ] }
            , { gridItem | span = Grid.Number 4, content = [ chip "hidden" ] }
            , { gridItem | suffix = True, content = [ Element.text "…" ] }
            ]
        ]


stepsSection : Element msg
stepsSection =
    section "Steps" "Progress through a sequence." <|
        [ Steps.view theme
            { stepsD | current = Just 2 }
            [ { stepsItem | title = Just "First", description = Just "Details" }
            , { stepsItem | title = Just "Second" }
            , { stepsItem | title = Just "Third" }
            ]
        ]


ellipsisSection : Element msg
ellipsisSection =
    section "Ellipsis" "Truncated text (the expand state is caller-owned)." <|
        [ Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                ellipsisD
                [ Element.text "A very long single line of text that gets cut off with an ellipsis character." ]
            )
        , Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                { ellipsisD | lineClamp = Just 2 }
                [ Element.text "Line clamping caps this paragraph at two lines and hides the remaining text behind a trailing ellipsis." ]
            )
        , Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                { ellipsisD | lineClamp = Just 2, expandOnClick = True }
                [ Element.text "A clickable two-line clamp. The caller toggles `expanded`." ]
            )
        ]


backTopSection : Element msg
backTopSection =
    section "BackTop" "A fixed back-to-top button (the scroll state is caller-owned)." <|
        [ BackTop.view theme { backTopD | show = True } [ Element.text "Up" ]
        ]


qrCodeSection : Element msg
qrCodeSection =
    section "QrCode" "QR codes, encoded by the ported Nayuki library and drawn as inline SVG." <|
        [ demoRow "Values"
            [ QrCode.view theme { qrD | value = "https://www.naiveui.com/" }
            , QrCode.view theme
                { qrD
                    | value = "https://www.naiveui.com/"
                    , color = "#18a058"
                    , backgroundColor = "#F5F5F5"
                }
            ]
        , demoRow "Size & error correction"
            [ QrCode.view theme { qrD | value = "The rain dampened the sky", size = 140 }
            , QrCode.view theme
                { qrD | value = "雨淋湿了天空", errorCorrectionLevel = QrCode.H }
            ]
        , demoRow "Icon"
            [ QrCode.view theme
                { qrD
                    | value = "https://www.naiveui.com/"
                    , iconSrc = Just "https://example.com/icon.png"
                    , errorCorrectionLevel = QrCode.H
                }
            ]
        ]


collapseSection : Element msg
collapseSection =
    section "Collapse" "Expandable panels (the expanded set is caller-owned)." <|
        [ Collapse.view theme
            { collapseD | expandedNames = [ "1" ] }
            [ { collapseItem
                | name = "1"
                , title = Just "First panel"
                , content = [ Element.text "The first panel is expanded by default." ]
              }
            , { collapseItem
                | name = "2"
                , title = Just "Second panel"
                , content = [ Element.text "Click the header, the extra or the arrow to toggle." ]
              }
            , { collapseItem
                | name = "3"
                , title = Just "Disabled panel"
                , disabled = True
                , content = [ Element.text "A disabled panel cannot be toggled." ]
              }
            ]
        , Collapse.view theme
            { collapseD
                | arrowPlacement = Collapse.ArrowRight
                , displayDirective = Collapse.ShowContent
            }
            [ { collapseItem
                | name = "a"
                , title = Just "Arrow on the right"
                , content = [ Element.text "The arrow sits after the title." ]
              }
            ]
        ]


rateSection : Element msg
rateSection =
    section "Rate" "Star ratings (the value and hover are caller-owned)." <|
        [ demoRow "Value"
            [ Rate.view theme { rateD | value = Just 4 }
            , Rate.view theme { rateD | value = Just 3, readonly = True }
            , Rate.view theme { rateD | value = Just 2, color = Just "#f0a020" }
            ]
        , demoRow "Half & sizes"
            [ Rate.view theme { rateD | allowHalf = True, value = Just 3.5 }
            , Rate.view theme { rateD | size = Rate.Small, value = Just 5 }
            , Rate.view theme { rateD | size = Rate.Large, value = Just 5 }
            ]
        ]


floatButtonSection : Element msg
floatButtonSection =
    section "Float Button"
        "A floating action button (position and offsets are caller-owned)."
    <|
        [ demoRow "Shapes & types"
            [ FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text "+" ]
            , FloatButton.view theme
                { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square }
                [ Element.text "S" ]
            , FloatButton.view theme
                { floatButtonD | position = FloatButton.Relative, type_ = FloatButton.Primary }
                [ Element.text "+" ]
            ]
        , demoRow "Description"
            [ FloatButton.view theme
                { floatButtonD | position = FloatButton.Relative, description = Just (Element.text "Top") }
                [ Element.text "↑" ]
            ]
        , demoRow "Menu"
            [ FloatButton.view theme
                { floatButtonD
                    | position = FloatButton.Relative
                    , menuTrigger = Just FloatButton.Click
                    , showMenu = True
                    , menu =
                        [ FloatButton.view theme
                            { floatButtonD | position = FloatButton.Relative }
                            [ Element.text "A" ]
                        , FloatButton.view theme
                            { floatButtonD | position = FloatButton.Relative }
                            [ Element.text "B" ]
                        ]
                }
                [ Element.text "+" ]
            ]
        ]


layoutSection : Element msg
layoutSection =
    section "Layout" "App shell — header, sider, content and footer (the sider's collapsed state is caller-owned)." <|
        [ Element.el [ Element.width Element.fill ]
            (Layout.view theme
                layD
                [ LayoutHeader.view theme { lhD | bordered = True } [ Element.text "Header" ]
                , Layout.view theme
                    { layD | hasSider = True }
                    [ LayoutSider.view theme
                        { lsD | bordered = True, showTrigger = LayoutSider.ArrowCircle }
                        [ Element.text "Sider" ]
                    , Layout.content theme layD [ Element.text "Content" ]
                    ]
                , LayoutFooter.view theme { lfD | bordered = True } [ Element.text "Footer" ]
                ]
            )
        , Element.el [ Element.width Element.fill ]
            (Layout.view theme
                { layD | hasSider = True }
                [ LayoutSider.view theme
                    { lsD
                        | collapsed = True
                        , width = "200px"
                        , collapsedWidth = "48px"
                        , showCollapsedContent = True
                        , showTrigger = LayoutSider.Bar
                        , placement = LayoutSider.Right
                    }
                    [ Element.text "Collapsed" ]
                , Layout.content theme layD [ Element.text "Content" ]
                ]
            )
        , Element.el [ Element.width Element.fill ]
            (Layout.view theme
                { layD | embedded = True }
                [ LayoutHeader.view theme lhD [ Element.text "Embedded header" ]
                , Layout.content theme layD [ Element.text "Embedded content" ]
                ]
            )
        ]


floatButtonGroupSection : Element msg
floatButtonGroupSection =
    section "Float Button Group"
        "A group of float buttons (shape, position and offsets are caller-owned)."
    <|
        [ demoRow "Circle"
            [ FloatButtonGroup.view theme
                { floatButtonGroupD | position = FloatButton.Relative, shape = FloatButton.Circle }
                [ FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text "+" ]
                , FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text "?" ]
                ]
            ]
        , demoRow "Square"
            [ FloatButtonGroup.view theme
                { floatButtonGroupD | position = FloatButton.Relative, shape = FloatButton.Square }
                [ FloatButton.view theme { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square } [ Element.text "A" ]
                , FloatButton.view theme { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square } [ Element.text "B" ]
                ]
            ]
        ]


iconSection : Element msg
iconSection =
    section "Icon"
        "Naive UI's icon primitive (`.n-icon`) and its rounded wrapper (`.n-icon-wrapper`). Pass the glyph as the child."
    <|
        [ demoRow "Icon"
            [ Icon.view theme iconD [ starIcon ]
            , Icon.view theme { iconD | size = Just (Icon.Px 32) } [ starIcon ]
            , Icon.view theme { iconD | depth = Just Icon.Depth2 } [ starIcon ]
            ]
        , demoRow "Wrapper"
            [ IconWrapper.view theme iconWrapperD [ Icon.view theme iconD [ starIcon ] ]
            , IconWrapper.view theme
                { iconWrapperD | color = Just "#18a058", iconColor = Just "#fff" }
                [ Icon.view theme iconD [ starIcon ] ]
            ]
        ]


highlightSection : Element msg
highlightSection =
    section "Highlight"
        "Plain text with every pattern occurrence wrapped in a `mark` (no stylesheet of its own)."
    <|
        [ Highlight.view theme
            { highlightD | text = "Naive UI is awesome", patterns = [ "Naive", "UI" ] }
            []
        , Highlight.view theme
            { highlightD
                | text = "naive-ui is written in TypeScript"
                , patterns = [ "naive", "typescript" ]
                , caseSensitive = False
            }
            []
        , Highlight.view theme
            { highlightD
                | text = "Price: $100.99 and $5"
                , patterns = [ "$1", "$5" ]
                , highlightStyle = [ ( "color", "red" ) ]
            }
            []
        ]


numberAnimationSection : Element msg
numberAnimationSection =
    section "Number Animation"
        "A tweened number (the clock is caller-owned — pass `elapsed`). No classes or variables of its own."
    <|
        [ demoRow "Grouped"
            [ NumberAnimation.view theme
                { numberAnimationD
                    | from = 0
                    , to = 1234567.5
                    , precision = 2
                    , showSeparator = True
                    , duration = 2000
                    , elapsed = 2000
                }
                []
            ]
        , demoRow "Precision"
            [ NumberAnimation.view theme
                { numberAnimationD
                    | from = 10
                    , to = 110
                    , precision = 1
                    , duration = 3000
                    , elapsed = 1500
                }
                []
            ]
        ]


heatmapSection : Element msg
heatmapSection =
    section "Heatmap"
        "GitHub-style contribution calendar: a real `table` of day rects coloured by `value / maxValue`, with week/month labels and a less/more indicator. Time is caller-owned (`zone`/`now`)."
    <|
        [ demoRow "Default"
            [ Heatmap.view theme { heatmapD | data = heatmapSample, now = sampleNow } []
            ]
        , demoRow "Loading"
            [ Heatmap.view theme
                { heatmapD | loading = True, loadingData = Just [], now = sampleNow }
                []
            ]
        , demoRow "Small + custom palette + gaps filled"
            [ Heatmap.view theme
                { heatmapD
                    | data = heatmapSample
                    , size = Heatmap.Small
                    , activeColors = Just [ "#e0e7ff", "#a5b4fc", "#6366f1", "#4338ca", "#312e81" ]
                    , fillCalendarLeading = True
                    , now = sampleNow
                }
                []
            ]
        ]


{-| Deterministic demo data (UTC midnights, ~10 weeks, some gaps and zeros).
-}
loadingBarSection : Element msg
loadingBarSection =
    section "LoadingBar"
        "Top loading indicator: a `max-width`-transitioned bar driven by a caller-owned state machine (`start` / `kick` / `finish` / `error`). The container is `position: fixed` by default; the demos pin it relatively."
    <|
        [ demoRow "Starting (80%)"
            [ Element.el [ Element.width (Element.px 440) ]
                (LoadingBar.view theme
                    { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                    (LoadingBar.start LoadingBar.init |> LoadingBar.kick)
                )
            ]
        , demoRow "Finishing"
            [ Element.el [ Element.width (Element.px 440) ]
                (LoadingBar.view theme
                    { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                    (LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.finish)
                )
            ]
        , demoRow "Error"
            [ Element.el [ Element.width (Element.px 440) ]
                (LoadingBar.view theme
                    { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                    (LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.error)
                )
            ]
        ]


dynamicInputSection : Element msg
dynamicInputSection =
    section "DynamicInput"
        "A list of values, each row an input (or key / value pair) with add / remove / sort actions. Pure list core: `insertAt` / `removeAt` / `moveUp` / `moveDown`, guarded by `min` / `max`."
    <|
        [ demoRow "Preset: input"
            [ Element.el [ Element.width (Element.px 440) ]
                (DynamicInput.viewInput theme
                    { diD
                        | value = [ "Alice", "Bob", "Cindy" ]
                        , placeholder = Just "Name"
                    }
                )
            ]
        , demoRow "Preset: pair"
            [ Element.el [ Element.width (Element.px 520) ]
                (DynamicInput.viewPair theme
                    { diPairD
                        | value = [ ( "Name", "Naive UI" ), ( "Author", "07akioni" ) ]
                        , keyPlaceholder = Just "Key"
                        , valuePlaceholder = Just "Value"
                    }
                )
            ]
        , demoRow "Max + sort buttons"
            [ Element.el [ Element.width (Element.px 440) ]
                (DynamicInput.viewInput theme
                    { diD
                        | value = [ "Only", "Three" ]
                        , max = Just 3
                        , showSortButton = True
                    }
                )
            ]
        , demoRow "Empty (Create button)"
            [ Element.el [ Element.width (Element.px 440) ]
                (DynamicInput.viewInput theme { diD | value = [] })
            ]
        ]


heatmapSample : List Heatmap.HeatmapDataItem
heatmapSample =
    List.indexedMap
        (\i v ->
            { timestamp = Time.millisToPosix (1704067200000 + i * 86400000)
            , value =
                if modBy 5 i == 0 then
                    Just 0

                else
                    Just (toFloat (modBy 11 (i * 7 + 3)))
            }
        )
        (List.repeat 70 ())


sampleNow : Time.Posix
sampleNow =
    Time.millisToPosix 1710086400000


descriptionsSection : Element msg
descriptionsSection =
    section "Descriptions"
        "Labelled field/value tables. `span` and `column` pack the rows; the packer is the pure `Descriptions.layout`."
    <|
        [ demoRow "Basic (title + a span-2 cell)"
            [ Descriptions.view theme
                { descD | title = Just (Element.text "Description") }
                [ { descItemD | label = Just (Element.text "Breakfast"), content = [ Element.text "Apple" ] }
                , { descItemD | label = Just (Element.text "Brunch"), content = [ Element.text "Apple" ] }
                , { descItemD | label = Just (Element.text "Lunch"), content = [ Element.text "Apple" ] }
                , { descItemD | span = 2, label = Just (Element.text "Supper"), content = [ Element.text "Two Apples" ] }
                , { descItemD | label = Just (Element.text "Midnight Snack"), content = [ Element.text "Apple" ] }
                ]
            ]
        , demoRow "Bordered"
            [ Descriptions.view theme
                { descD | bordered = True }
                [ { descItemD | label = Just (Element.text "Name"), content = [ Element.text "Naive UI" ] }
                , { descItemD | label = Just (Element.text "Version"), content = [ Element.text "0.19" ] }
                , { descItemD | label = Just (Element.text "License"), content = [ Element.text "MIT" ] }
                ]
            ]
        , demoRow "Left label placement (bordered)"
            [ Descriptions.view theme
                { descD | labelPlacement = Descriptions.Left, bordered = True }
                [ { descItemD | label = Just (Element.text "Name"), content = [ Element.text "Naive UI" ] }
                , { descItemD | label = Just (Element.text "Version"), content = [ Element.text "0.19" ] }
                ]
            ]
        , demoRow "Columns = 4"
            [ Descriptions.view theme
                { descD | columns = Just 4 }
                (List.map
                    (\l -> { descItemD | label = Just (Element.text l), content = [ Element.text "Apple" ] })
                    [ "A", "B", "C", "D" ]
                )
            ]
        ]


tabsSection : Element msg
tabsSection =
    section "Tabs"
        "Tabbed navigation with panes. The caller owns the active `value`; `ShowIf` (default) mounts only the active pane."
    <|
        [ demoRow "Bar (default)"
            [ Tabs.view theme { tabsD | value = "one" } tabsItems ]
        , demoRow "Line"
            [ Tabs.view theme { tabsD | type_ = Tabs.Line, value = "two" } tabsItems ]
        , demoRow "Card (closable)"
            [ Tabs.view theme { tabsD | type_ = Tabs.Card, closable = True, value = "one" } tabsItems ]
        , demoRow "Segment"
            [ Tabs.view theme { tabsD | type_ = Tabs.Segment, value = "two" } tabsItems ]
        , demoRow "Sizes (small / medium / large)"
            [ Tabs.view theme { tabsD | size = Tabs.Small, value = "one" } tabsItems
            , Tabs.view theme { tabsD | size = Tabs.Large, value = "one" } tabsItems
            ]
        , demoRow "Placement (bottom / left)"
            [ Tabs.view theme { tabsD | placement = Tabs.Bottom, value = "one" } tabsItems
            , Tabs.view theme { tabsD | placement = Tabs.Left, value = "one" } tabsItems
            ]
        , demoRow "Show directive (all panes mounted)"
            [ Tabs.view theme { tabsD | displayDirective = Tabs.Show, value = "one" } tabsItems ]
        ]


scrollbarSection : Element msg
scrollbarSection =
    section "Scrollbar"
        "A styled scroll container with custom rails. The caller owns whether each bar is shown and its measured geometry."
    <|
        [ demoRow "Vertical bar shown"
            [ Element.el [ Element.height (Element.px 120), Element.width Element.fill ]
                (Scrollbar.view theme
                    { scrollbarD
                        | showYBar = True
                        , yBarStyle = Just "height:48px;top:8px"
                    }
                    [ Element.paragraph [] (List.repeat 3 (Element.text scrollbarCopy)) ]
                )
            ]
        , demoRow "Both rails (x-scrollable)"
            [ Element.el [ Element.height (Element.px 120), Element.width Element.fill ]
                (Scrollbar.view theme
                    { scrollbarD
                        | xScrollable = True
                        , showYBar = True
                        , yBarStyle = Just "height:48px;top:8px"
                        , showXBar = True
                        , xBarStyle = Just "width:80px;left:0"
                    }
                    [ Element.el [ Element.htmlAttribute (HA.attribute "style" "white-space:nowrap") ]
                        (Element.text scrollbarCopy)
                    ]
                )
            ]
        , demoRow "Rails only (left / top)"
            [ Element.el [ Element.height (Element.px 100), Element.width Element.fill ]
                (Scrollbar.view theme
                    { scrollbarD | yPlacement = Scrollbar.Left }
                    [ Element.text scrollbarCopy ]
                )
            , Element.el [ Element.height (Element.px 100), Element.width Element.fill ]
                (Scrollbar.view theme
                    { scrollbarD | xScrollable = True, xPlacement = Scrollbar.Top }
                    [ Element.text scrollbarCopy ]
                )
            ]
        ]


scrollbarCopy : String
scrollbarCopy =
    "And as I sat there, brooding on the old unknown world, I thought of Gatsby's wonder when he first picked out the green light at the end of Daisy's dock."


{-| The caller-owned follower wrapper: a `v-placement` host the popover body sits
in (upstream: vueuc's `v-binder-follower-content` with runtime positioning).
-}
popoverHost : Popover.Placement -> List (Element.Attribute msg) -> Element msg -> Element msg
popoverHost placement attrs content =
    Element.el
        ([ Popover.placementAttribute placement
         , Element.htmlAttribute (HA.attribute "style" "position:relative;padding:34px 28px;")
         ]
            ++ attrs
        )
        content


popoverSection : Element msg
popoverSection =
    section "Popover"
        "The `n-popover` body. The caller owns the show state and the positioned `v-placement` wrapper (here: `popoverHost`); placements, arrows, header/footer and the scrollable scrollbar are static DOM."
    <|
        [ demoRow "Basic (top) + header/footer (bottom)"
            [ popoverHost Popover.Top
                []
                (Popover.view theme
                    { popoverD | width = Just "240px" }
                    [ Element.text "The pure body of a popover — mount it, position it, it is yours." ]
                )
            , popoverHost Popover.Bottom
                []
                (Popover.view theme
                    { popoverD
                        | width = Just "240px"
                        , header = Just (Element.text "Title")
                        , footer = Just (Element.text "Footer")
                    }
                    [ Element.text "Header and footer slots add their wrapper divs and the modifier class." ]
                )
            ]
        , demoRow "No arrow / overlap / raw"
            [ popoverHost Popover.Right
                []
                (Popover.view theme
                    { popoverD | width = Just "220px", showArrow = False }
                    [ Element.text "No arrow." ]
                )
            , popoverHost Popover.Right
                []
                (Popover.view theme
                    { popoverD | width = Just "220px", overlap = True }
                    [ Element.text "Overlap: no arrow and no spacing margin." ]
                )
            , popoverHost Popover.Right
                []
                (Popover.view theme
                    { popoverD | width = Just "220px", raw = True }
                    [ Element.text "Raw: no background, radius or padding." ]
                )
            ]
        , demoRow "Enter-active transition (caller-driven)"
            [ popoverHost Popover.Top
                []
                (Popover.view theme
                    { popoverD
                        | width = Just "240px"
                        , transition = Just I.EnterActive
                    }
                    [ Element.text "The popover-transition classes are the caller's clock." ]
                )
            ]
        , demoRow "Scrollable (n-scrollbar child)"
            [ popoverHost Popover.Top
                []
                (Popover.view theme
                    { popoverD
                        | width = Just "260px"
                        , scrollable = True
                        , attributes = [ Element.height (Element.px 120) ]
                    }
                    [ Element.text scrollbarCopy ]
                )
            ]
        ]


tooltipSection : Element msg
tooltipSection =
    section "Tooltip"
        "Popover wearing waistcoat — the same body (`n-tooltip` marker class), the tooltip theme swapping the colours: a dark bubble in light mode, the popover's own colours in dark."
    <|
        [ demoRow "Light theme (dark bubble)"
            [ popoverHost Popover.Top
                []
                (Tooltip.view theme
                    { tooltipD | width = Just "200px" }
                    [ Element.text "A tooltip bubble." ]
                )
            , popoverHost Popover.Bottom
                []
                (Tooltip.view theme
                    { tooltipD | width = Just "200px", showArrow = False }
                    [ Element.text "No arrow." ]
                )
            ]
        , demoRow "Dark theme (popover colours)"
            [ popoverHost Popover.Right
                []
                (Tooltip.view darkTheme
                    { tooltipD | width = Just "200px" }
                    [ Element.text "Same as the dark popover." ]
                )
            ]
        ]


dropdownSection : Element msg
dropdownSection =
    section "Dropdown"
        "The `n-dropdown-menu` body — the popover runtime's sibling, rendered as its own element (`n-popover-shared` + `n-dropdown` markers, the merged 31-var set). The caller owns show state, the `v-placement` wrapper (here: `popoverHost`), and any submenu mounts."
    <|
        [ demoRow "Basic + sizes"
            [ popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    dropdownD
                    [ Dropdown.Option
                        { key = "edit"
                        , label = "Edit"
                        , icon = Nothing
                        , disabled = False
                        , children = Nothing
                        , attributes = []
                        }
                    , Dropdown.Option
                        { key = "duplicate"
                        , label = "Duplicate"
                        , icon = Nothing
                        , disabled = False
                        , children = Nothing
                        , attributes = []
                        }
                    , Dropdown.Divider { attributes = [] }
                    , Dropdown.Option
                        { key = "delete"
                        , label = "Delete"
                        , icon = Nothing
                        , disabled = True
                        , children = Nothing
                        , attributes = []
                        }
                    ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | size = Dropdown.Small }
                    [ demoLeaf "small-1" "Small", demoLeaf "small-2" "28px rows" ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | size = Dropdown.Huge }
                    [ demoLeaf "huge-1" "Huge", demoLeaf "huge-2" "46px rows, 18px icons" ]
                )
            ]
        , demoRow "Groups, dividers, icons, submenus, custom"
            [ popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | width = Just "220px" }
                    [ Dropdown.Group
                        { key = "group-people"
                        , label = "People"
                        , icon = Nothing
                        , children =
                            [ Dropdown.Option
                                { key = "jay"
                                , label = "Jay Gatsby"
                                , icon = Just demoIcon
                                , disabled = False
                                , children = Nothing
                                , attributes = []
                                }
                            , Dropdown.Option
                                { key = "daisy"
                                , label = "Daisy Buchanan"
                                , icon = Just demoIcon
                                , disabled = True
                                , children = Nothing
                                , attributes = []
                                }
                            ]
                        }
                    , Dropdown.Divider { attributes = [] }
                    , Dropdown.Option
                        { key = "others"
                        , label = "Others"
                        , icon = Just demoIcon
                        , disabled = False
                        , children = Just [ demoLeaf "nick" "Nick Carraway", demoLeaf "tom" "Tom Buchanan" ]
                        , attributes = []
                        }
                    , Dropdown.Custom
                        { key = "custom"
                        , children = [ Element.text "A custom render option." ]
                        , attributes = []
                        }
                    ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | value = Just "target" }
                    [ Dropdown.Option
                        { key = "parent"
                        , label = "Parent (child-active)"
                        , icon = Nothing
                        , disabled = False
                        , children = Just [ demoLeaf "target" "Target (active)" ]
                        , attributes = []
                        }
                    , demoLeaf "plain" "Plain"
                    ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | value = Just "target" }
                    [ demoLeaf "target" "Target (active)"
                    , demoLeaf "plain" "Plain"
                    ]
                )
            ]
        , demoRow "Arrow / inverted / scrollable"
            [ popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | showArrow = True }
                    [ demoLeaf "a1" "With the popover arrow", demoLeaf "a2" "Second item" ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | inverted = True }
                    [ demoLeaf "i1" "Inverted menu", demoLeaf "i2" "Primary hover" ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD
                        | scrollable = True
                        , width = Just "240px"
                        , attributes = [ Element.height (Element.px 120) ]
                    }
                    (List.indexedMap (\i _ -> demoLeaf ("s" ++ String.fromInt i) ("Scrollable item " ++ String.fromInt (i + 1))) (List.range 1 12))
                )
            ]
        ]


demoLeaf : String -> String -> Dropdown.Option msg
demoLeaf key label =
    Dropdown.Option
        { key = key
        , label = label
        , icon = Nothing
        , disabled = False
        , children = Nothing
        , attributes = []
        }


demoIcon : Element msg
demoIcon =
    Element.html
        (Html.node "svg"
            [ HA.attribute "viewBox" "0 0 512 512"
            , HA.attribute "fill" "none"
            , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
            ]
            [ Html.node "circle"
                [ HA.attribute "cx" "256"
                , HA.attribute "cy" "256"
                , HA.attribute "r" "208"
                , HA.attribute "stroke" "currentColor"
                , HA.attribute "stroke-width" "32"
                ]
                []
            ]
        )


{-| The caller-owned modal host: upstream teleports the fixed tree to `to`; here a
`transform: translate(0,0)` cell becomes the containing block that confines the
fixed container/mask/body-wrapper, and `overflow: hidden` clips the overlay to
the demo cell.
-}
modalHost : List (Element.Attribute msg) -> Element msg -> Element msg
modalHost attrs content =
    Element.el
        ([ Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;transform:translate(0,0);height:210px;width:320px;overflow:hidden;border:1px solid #efeff5;background:#fafafc"
            )
         ]
            ++ attrs
        )
        content


modalSection : Element msg
modalSection =
    section "Modal"
        "The mount-body family — its own fixed tree (container > mask > body-wrapper > scrollbar > content), self-positioned and centred by flex. The caller owns mounting, the show state, the transition clock (one clock drives the mask and body tuples), outside-click closing and Esc; `dialog`/`confirm` presets land with `NUI.Dialog`. The demo cells confine the fixed tree with a `transform: translate(0,0)` containing block."
    <|
        [ demoRow "Custom content + card preset"
            [ modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Custom
                        [ Element.htmlAttribute
                            (HA.attribute
                                "style"
                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px;color:var(--n-text-color)"
                            )
                        ]
                        [ Element.text "Custom content — you own the box; the wrapper carries `n-modal`." ]
                    )
                )
            , modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Card
                        { modalCardD
                            | title = Just (Element.text "A card modal")
                            , footer = Just (Element.text "#footer")
                            , closable = True
                        }
                        [ Element.text "Unbordered by default — upstream spreads the dialog props last." ]
                    )
                )
            ]
        , demoRow "Card variants (bordered opt-in, segmented, dark)"
            [ modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Card
                        { modalCardD
                            | title = Just (Element.text "Bordered")
                            , bordered = True
                        }
                        [ Element.text "Opt back into the card border." ]
                    )
                )
            , modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Card
                        { modalCardD
                            | title = Just (Element.text "Segmented")
                            , segmented =
                                { content = Card.Hard
                                , footer = Card.Off
                                , action = Card.Off
                                }
                            , footer = Just (Element.text "#footer")
                        }
                        [ Element.text "Content/footer separators." ]
                    )
                )
            , modalHost []
                (Modal.view darkTheme
                    { modalD | show = True }
                    (Modal.Card
                        { modalCardD | title = Just (Element.text "Dark theme") }
                        [ Element.text "rgb(44, 44, 50) surface, .82 white text." ]
                    )
                )
            ]
        , demoRow "No mask (mask-hidden) + z-index"
            [ modalHost []
                (Modal.view theme
                    { modalD | show = True, showMask = False }
                    (Modal.Custom
                        [ Element.htmlAttribute
                            (HA.attribute
                                "style"
                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px"
                            )
                        ]
                        [ Element.text "No mask: --mask-hidden passes clicks through around the content." ]
                    )
                )
            , modalHost []
                (Modal.view theme
                    { modalD | show = True, zIndex = Just 100 }
                    (Modal.Custom
                        [ Element.htmlAttribute
                            (HA.attribute
                                "style"
                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px"
                            )
                        ]
                        [ Element.text "z-index: 100 on the container." ]
                    )
                )
            ]
        , demoRow "Enter-active phases (caller clock)"
            [ modalHost []
                (Modal.view theme
                    { modalD
                        | show = True
                        , maskTransition = Just I.EnterActive
                        , bodyTransition = Just I.EnterActive
                    }
                    (Modal.Card
                        { modalCardD | title = Just (Element.text "Entering") }
                        [ Element.text "fade-in + fade-in-scale-up enter-active classes." ]
                    )
                )
            ]
        ]


rtlSection : Element msg
rtlSection =
    section "RTL"
        "Right-to-left layout — pass `rtl = True`; the RTL rules ship in the stylesheet."
    <|
        [ demoRow "Alert"
            [ Element.el [ Element.width (Element.px 340) ]
                (Alert.view theme
                    { alertD | rtl = True, kind = T.Info, title = Just "Info" }
                    [ Element.text "A right-to-left alert." ]
                )
            ]
        , demoRow "Components"
            [ Button.view theme { btn | rtl = True, kind = T.Primary } [ Element.text "Button" ]
            , Tag.view theme { tagD | rtl = True, kind = T.Primary } [ Element.text "Tag" ]
            , Badge.view theme { badgeD | rtl = True, value = Just (Badge.Number 5) } [ Element.text "Mail" ]
            , Space.view theme
                { spaceD | rtl = True }
                [ Element.text "One", Element.text "Two", Element.text "Three" ]
            ]
        ]


themeSection : Element msg
themeSection =
    section "Theme"
        "One variable set drives every component — override the primary colour and it propagates."
    <|
        [ demoRow "Default primary"
            [ Button.view theme { btn | kind = T.Primary } [ Element.text "Primary" ]
            , Tag.view theme { tagD | kind = T.Primary, bordered = False } [ Element.text "Tag" ]
            , Switch.view theme { swD | value = True } []
            ]
        , demoRow "setPrimary \"#7c3aed\""
            [ Button.view purple { btn | kind = T.Primary } [ Element.text "Primary" ]
            , Tag.view purple { tagD | kind = T.Primary, bordered = False } [ Element.text "Tag" ]
            , Switch.view purple { swD | value = True } []
            ]
        ]



-- HELPERS


{-| A titled block: heading, description, examples, then a divider.
-}
section : String -> String -> List (Element msg) -> Element msg
section title desc examples =
    Element.column [ Element.spacing 16, Element.width Element.fill ]
        [ Typo.h3 theme typ [ Element.text title ]
        , Typo.text theme { typ | depth = Just 3 } [ Element.text desc ]
        , Element.column [ Element.spacing 20, Element.width Element.fill ] examples
        , Divider.view theme divD []
        ]


{-| A labelled, wrapping row of examples.
-}
demoRow : String -> List (Element msg) -> Element msg
demoRow label items =
    Element.column [ Element.spacing 10, Element.width Element.fill ]
        [ Typo.text theme { typ | depth = Just 4, size = Just 12 } [ Element.text (String.toUpper label) ]
        , Element.wrappedRow [ Element.spacing 12 ] items
        ]


chip : String -> Element msg
chip label =
    Tag.view theme { tagD | bordered = False } [ Element.text label ]


{-| A small inline SVG glyph for the icon showcase.
-}
starIcon : Element msg
starIcon =
    Element.html
        (Html.node "svg"
            [ HA.attribute "viewBox" "0 0 24 24"
            , HA.attribute "aria-hidden" "true"
            ]
            [ Html.node "path"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "d" "M12 2l2.9 6.3 6.9.8-5.1 4.7 1.4 6.8L12 17.3 5.9 20.6l1.4-6.8L2.2 9.1l6.9-.8z"
                ]
                []
            ]
        )


capitalize : String -> String
capitalize s =
    String.toUpper (String.left 1 s) ++ String.dropLeft 1 s
