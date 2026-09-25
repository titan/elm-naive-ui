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
import NUI.Descriptions as Descriptions
import NUI.Dialog as Dialog
import NUI.DialogProvider as DialogProvider
import NUI.Divider as Divider
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
import NUI.Internal as I
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
import NUI.Theme as Theme exposing (Theme)
import NUI.Thing as Thing
import NUI.Timeline as Timeline
import NUI.Tooltip as Tooltip
import NUI.Tree as Tree
import NUI.Types as T
import NUI.Typography as Typo
import NUI.Watermark as Watermark
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


messageD : Message.Options msg
messageD =
    Message.defaults


messageI : Message.Item msg
messageI =
    Message.item


messageS : Message.State msg
messageS =
    Message.init


notificationD : Notification.Options msg
notificationD =
    Notification.defaults


notificationI : Notification.Item msg
notificationI =
    Notification.item


notificationS : Notification.State msg
notificationS =
    Notification.init


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


popconfirmD : Popconfirm.Options msg
popconfirmD =
    Popconfirm.defaults


popselectD : Popselect.Options msg
popselectD =
    Popselect.defaults


selectMenuD : SelectMenu.Options msg
selectMenuD =
    SelectMenu.defaults


selectD : Select.Options msg
selectD =
    Select.defaults


selMenuD : Select.MenuOptions msg
selMenuD =
    Select.menuDefaults


cascaderD : Cascader.Options msg
cascaderD =
    Cascader.defaults


cascMenuD : Cascader.MenuOptions msg
cascMenuD =
    Cascader.menuDefaults


cascSelectMenuD : Cascader.SelectMenuOptions msg
cascSelectMenuD =
    Cascader.selectMenuDefaults


acD : AutoComplete.Options msg
acD =
    AutoComplete.defaults


acMenuD : AutoComplete.MenuOptions msg
acMenuD =
    AutoComplete.menuDefaults


mnD : Mention.Options msg
mnD =
    Mention.defaults


mnMenuD : Mention.MenuOptions msg
mnMenuD =
    Mention.menuDefaults


menuD : Menu.Options msg
menuD =
    Menu.defaults


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


drawerD : Drawer.Options msg
drawerD =
    Drawer.defaults


drawerContentD : DrawerContent.Options msg
drawerContentD =
    DrawerContent.defaults


dialogD : Dialog.Options msg
dialogD =
    Dialog.defaults


dialogPI =
    DialogProvider.item


dialogPS =
    DialogProvider.init


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
    , popconfirmSection
    , popselectSection
    , selectSection
    , cascaderSection
    , treeSection
    , tableSection
    , watermarkSection
    , autoCompleteSection
    , mentionSection
    , tooltipSection
    , dropdownSection
    , menuSection
    , sliderSection
    , imageSection
    , imagePreviewSection
    , messageSection
    , notificationSection
    , modalSection
    , drawerSection
    , dialogSection
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


popconfirmSection : Element msg
popconfirmSection =
    section "Popconfirm"
        "The popover body with the confirm panel in its default slot (upstream renders `NPopover` with the `popconfirm` extra class). The panel's icon/body/action structure and the composed action buttons — negative plain `small` first, positive `small` Primary, `positiveProps`/`negativeProps` spreading over the derived base, the action row always rendered — are DOM; the caller owns the show state, the `'click'` trigger and the close gate (upstream's return-false-keeps-it-open is the caller's update)."
    <|
        [ demoRow "Default + no icon / action slot"
            [ popoverHost Popover.Top
                []
                (Popconfirm.view theme
                    { popconfirmD | popover = { popoverD | width = Just "220px" } }
                    [ Element.text "Delete it?" ]
                )
            , popoverHost Popover.Top
                []
                (Popconfirm.view theme
                    { popconfirmD
                        | popover = { popoverD | width = Just "220px" }
                        , showIcon = False
                        , action = Just [ Element.text "#action — the slot replaces the buttons" ]
                    }
                    [ Element.text "No icon; the body renders content-only." ]
                )
            ]
        , demoRow "Custom texts + button-props overrides"
            [ popoverHost Popover.Top
                []
                (Popconfirm.view theme
                    { popconfirmD
                        | popover = { popoverD | width = Just "240px" }
                        , positiveText = Popconfirm.CustomText "Sure"
                        , negativeText = Popconfirm.CustomText "Not yet"
                        , positiveProps = Just (\b -> { b | round = True })
                        , negativeProps = Just (\b -> { b | round = True })
                    }
                    [ Element.text "CustomText labels; Hidden drops a button (the row stays)." ]
                )
            ]
        ]


popselectSection : Element msg
popselectSection =
    section "Popselect"
        "The popover-family body whose select-menu root is itself the popover-shared body (upstream `internalRenderBody` — the `Dropdown` path: no `n-popover` element, `--n-padding` zeroed, `--show-arrow` present unless `overlap` even with no arrow node). Selection is pure — `value` drives the per-option checkmarks, `toggleValue` computes the next value — while the caller owns the show state (`'hover'` trigger), positioning (default placement bottom) and the auto-close on single select. `NUI.SelectMenu` (the support module this composes) stands bare in the last row."
    <|
        [ demoRow "Single (leaves + group)"
            [ popoverHost Popover.Bottom
                []
                (Popselect.view theme
                    { popselectD
                        | width = Just "200px"
                        , value = SelectMenu.Single (Just "drive")
                    }
                    popselectOptions
                )
            ]
        , demoRow "Multiple (--multiple marker)"
            [ popoverHost Popover.Bottom
                []
                (Popselect.view theme
                    { popselectD
                        | width = Just "200px"
                        , multiple = True
                        , value = SelectMenu.Multiple [ "in-my-life", "the-word" ]
                    }
                    popselectOptions
                )
            ]
        , demoRow "Bare NUI.SelectMenu (no popover classes)"
            [ SelectMenu.view theme
                { selectMenuD
                    | size = SelectMenu.Small
                    , header = Just (Element.text "Header")
                    , action = Just (Element.text "#action")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                popselectOptions
            ]
        ]


{-| The shared popselect rows — leaves and a group (upstream's flatten renders
the group header followed by its children as siblings).
-}
popselectOptions : List (SelectMenu.Option msg)
popselectOptions =
    [ SelectMenu.Option
        { value = "drive"
        , label = "Drive My Car"
        , disabled = False
        , attributes = []
        }
    , SelectMenu.Option
        { value = "nowhere-man"
        , label = "Nowhere Man"
        , disabled = True
        , attributes = []
        }
    , SelectMenu.Group
        { label = "Rubber Soul"
        , children =
            [ SelectMenu.Option
                { value = "in-my-life"
                , label = "In My Life"
                , disabled = False
                , attributes = []
                }
            , SelectMenu.Option
                { value = "the-word"
                , label = "The Word"
                , disabled = False
                , attributes = []
                }
            ]
        , attributes = []
        }
    ]


selectSection : Element msg
selectSection =
    section "Select"
        "Naive UI's select — a bare `.n-select` wrapper around the `NUI.BaseSelection` trigger (every var lives there); the menu is a separate caller-mounted body (upstream opens it in its own follower), `Select.menu` here. `view` derives the display from `value` + options: the single label (unknown values show themselves while `fallbackOption` is on), the multiple tags (same fallback; unknowns drop when off) with the numeric `maxTagCount` slice's `+N` counter, and the clear icon — `clearable && (hover || active) && selected`; `pattern` flows to the filter input, `filterOptions` being the pure default filter. The caller owns the show state, positioning and keyboard."
    <|
        [ demoRow "Single (leaves + group)"
            [ Select.view theme
                { selectD | attributes = [ Element.width (Element.px 200) ] }
                selectOptions
            ]
        , demoRow "Selected + clearable (hover)"
            [ Select.view theme
                { selectD
                    | value = SelectMenu.Single (Just "drive")
                    , clearable = True
                    , hover = True
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            ]
        , demoRow "Filterable (active, empty pattern)"
            [ Select.view theme
                { selectD
                    | filterable = True
                    , active = True
                    , pattern = ""
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            ]
        , demoRow "Multiple (maxTagCount 3 + fallback)"
            [ Select.view theme
                { selectD
                    | multiple = True
                    , maxTagCount = Just 3
                    , value = SelectMenu.Multiple [ "a", "b", "c", "d", "ghost" ]
                    , attributes = [ Element.width (Element.px 260) ]
                }
                letterOptions
            ]
        , demoRow "Multiple filterable (pattern)"
            [ Select.view theme
                { selectD
                    | multiple = True
                    , filterable = True
                    , active = True
                    , pattern = "dri"
                    , value = SelectMenu.Multiple [ "drive" ]
                    , attributes = [ Element.width (Element.px 260) ]
                }
                selectOptions
            ]
        , demoRow "Sizes · status · disabled"
            [ Select.view theme
                { selectD
                    | size = Select.Small
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            , Select.view theme
                { selectD
                    | size = Select.Large
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 240) ]
                }
                selectOptions
            , Select.view theme
                { selectD
                    | status = Just BaseSelection.Warning
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            , Select.view theme
                { selectD
                    | disabled = True
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            ]
        , demoRow "Menu: loading (the __loading row)"
            [ Select.menu theme
                { selMenuD
                    | loading = True
                    , attributes = [ Element.width (Element.px 200) ]
                }
                [ SelectMenu.Option { value = "a", label = "A", disabled = False, attributes = [] }
                , SelectMenu.Option { value = "b", label = "B", disabled = False, attributes = [] }
                ]
            ]
        , demoRow "Menu: header · action · selected"
            [ Select.menu theme
                { selMenuD
                    | header = Just (Element.text "Header")
                    , action = Just (Element.text "#action")
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            ]
        ]


{-| The select rows — leaves (one disabled) and a group (the flatten renders
the header followed by its children as siblings).
-}
selectOptions : List (SelectMenu.Option msg)
selectOptions =
    [ SelectMenu.Option
        { value = "drive"
        , label = "Drive My Car"
        , disabled = False
        , attributes = []
        }
    , SelectMenu.Option
        { value = "nowhere-man"
        , label = "Nowhere Man"
        , disabled = True
        , attributes = []
        }
    , SelectMenu.Group
        { label = "Rubber Soul"
        , children =
            [ SelectMenu.Option
                { value = "in-my-life"
                , label = "In My Life"
                , disabled = False
                , attributes = []
                }
            , SelectMenu.Option
                { value = "the-word"
                , label = "The Word"
                , disabled = False
                , attributes = []
                }
            ]
        , attributes = []
        }
    ]


{-| The lettered rows the multiple demos select from (the `ghost` value in
the maxTagCount demo is absent here — the `fallbackOption` tag).
-}
letterOptions : List (SelectMenu.Option msg)
letterOptions =
    List.map
        (\letter ->
            SelectMenu.Option
                { value = String.toLower letter
                , label = letter
                , disabled = False
                , attributes = []
                }
        )
        [ "A", "B", "C", "D", "E" ]


{-| The cascader section — the trigger plus both caller-mounted bodies.
-}
cascaderSection : Element msg
cascaderSection =
    section "Cascader"
        "Naive UI's cascader — the `NUI.BaseSelection` trigger (the `NUI.Select` lane) plus the multi-column menu, both caller-mounted bodies (upstream opens each in its own follower): `Cascader.menu` for the columns (the hover key's path decides them, `menuModel`; option states come from the value's `All`-strategy normalization) and `Cascader.selectMenu` for the filterable flat body (`filterOptions`' path-label rows). `view` derives the display from `value` + the tree: the single path label (unknown keys show themselves), the multiple cascade-normalized tags with the numeric `maxTagCount` slice. The treemate cascade logic ships pure — `getCheckedKeys` / `check` / `uncheck` / `toggleValue`; the caller owns the show state, positioning, keyboard and remote loading (`loadingKeys`)."
    <|
        [ demoRow "Single (path label) · multiple (maxTagCount)"
            [ Cascader.view theme
                { cascaderD
                    | value = SelectMenu.Single (Just "eleanor")
                    , clearable = True
                    , hover = True
                    , attributes = [ Element.width (Element.px 280) ]
                }
                cascaderOptions
            , Cascader.view theme
                { cascaderD
                    | multiple = True
                    , maxTagCount = Just 2
                    , value = SelectMenu.Multiple [ "abbey", "revolver" ]
                    , attributes = [ Element.width (Element.px 320) ]
                }
                cascaderOptions
            ]
        , demoRow "Columns menu (hover key opens the second column)"
            [ Cascader.menu theme
                { cascMenuD
                    | hoverKey = Just "revolver"
                    , multiple = True
                    , value = SelectMenu.Multiple [ "abbey", "come" ]
                    , attributes = [ Element.width (Element.px 420) ]
                }
                cascaderOptions
            ]
        , demoRow "Columns menu: child strategy (leaf checkmarks) · empty · action"
            [ Cascader.menu theme
                { cascMenuD
                    | checkStrategy = Cascader.Child
                    , value = SelectMenu.Single (Just "drive")
                    , action = Just (Element.text "#action")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                cascaderOptions
            , Cascader.menu theme
                { cascMenuD | attributes = [ Element.width (Element.px 200) ] }
                []
            ]
        , demoRow "Filterable flat menu (pattern 'sub')"
            [ Cascader.selectMenu theme
                { cascSelectMenuD
                    | multiple = True
                    , value = SelectMenu.Multiple [ "abbey" ]
                    , attributes = [ Element.width (Element.px 280) ]
                }
                (Cascader.filterOptions "sub" Cascader.All " / " cascaderOptions)
            ]
        ]


{-| The cascader fixture — three two-level albums (branches) with song
leaves; `revolver`'s column is what the hover key opens.
-}
cascaderOptions : List Cascader.Option
cascaderOptions =
    [ Cascader.Option
        { value = "rubber"
        , label = "Rubber Soul"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "drive", label = "Drive My Car", disabled = False, children = Nothing }
                , Cascader.Option { value = "nowhere", label = "Nowhere Man", disabled = False, children = Nothing }
                ]
        }
    , Cascader.Option
        { value = "revolver"
        , label = "Revolver"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "eleanor", label = "Eleanor Rigby", disabled = False, children = Nothing }
                , Cascader.Option { value = "yellow", label = "Yellow Submarine", disabled = False, children = Nothing }
                ]
        }
    , Cascader.Option
        { value = "abbey"
        , label = "Abbey Road"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "come", label = "Come Together", disabled = False, children = Nothing }
                , Cascader.Option { value = "here", label = "Here Comes the Sun", disabled = False, children = Nothing }
                ]
        }
    ]


{-| The tree section — one root per demo shape. All interaction state is
caller-owned: the expanded / checked / selected / loading keys are plain
lists the caller derives with `Tree.toggleExpand` / `Tree.check` / … and
feeds back in.
-}
tableSection : Element msg
tableSection =
    section "Table"
        "Naive UI's static table — the real `<table class=\"n-table\">` root (six modifier classes, the 21 `--n-*` vars with the three size-keyed ones resolved) over a typed `thead` / `tbody` tree of `th` / `td` cells (`colspan` / `rowspan` first-class, `Element` content embedded through `display: contents`). Fully static — nothing runtime."
    <|
        [ demoRow "Basic (defaults: bordered, bottom-bordered, single-line)"
            [ Table.view theme tableD tableContent
            ]
        , demoRow "Sizes · un-bordered · multi-line"
            [ Table.view theme { tableD | size = Table.Small } tableContent
            , Table.view theme { tableD | size = Table.Large, bordered = False, bottomBordered = False } tableContent
            ]
        , demoRow "Striped · single-column · multi-line cells"
            [ Table.view theme { tableD | striped = True, singleLine = False } tableContent
            , Table.view theme { tableD | singleColumn = True } tableContent
            ]
        , demoRow "Colspan / rowspan"
            [ Table.view theme tableD spanContent
            ]
        , demoRow "RTL"
            [ Table.view theme { tableD | rtl = True } tableContent
            ]
        ]


tableD : Table.Options msg
tableD =
    Table.defaults


{-| A two-column demo table (head + three body rows).
-}
tableContent : Table.Table msg
tableContent =
    { head =
        [ { rowD | cells = [ tableCell "Name", tableCell "Origin" ] } ]
    , body =
        [ { rowD | cells = [ tableCell "Naive", tableCell "Vue" ] }
        , { rowD | cells = [ tableCell "elm-naive-ui", tableCell "Elm" ] }
        , { rowD | cells = [ tableCell "Seemly", tableCell "Utils" ] }
        ]
    }


{-| The colspan / rowspan demo (naive-ui docs' merge-cell shape).
-}
spanContent : Table.Table msg
spanContent =
    { head =
        [ { rowD | cells = [ tableCell "", cellD, cellD ] } ]
    , body =
        [ { rowD
            | cells =
                [ { cellD | content = [ Element.text "Guitar" ], rowspan = Just 2 }
                , tableCell "1998"
                , tableCell "Songs"
                ]
          }
        , { rowD | cells = [ tableCell "2001", { cellD | colspan = Just 2, content = [ Element.text "Albums + Tours" ] } ] }
        ]
    }


rowD : Table.Row msg
rowD =
    Table.rowDefaults


cellD : Table.Cell msg
cellD =
    Table.cellDefaults


tableCell : String -> Table.Cell msg
tableCell label =
    { cellD | content = [ Element.text label ] }


watermarkSection : Element msg
watermarkSection =
    section "Watermark"
        "Naive UI's watermark — the `div.n-watermark-container` (the `--selectable` / `--global-rotate` / `--fullscreen` modifiers; bare overlay when fullscreen without global rotation) wrapping the content plus the tiled `div.n-watermark` overlay (`background-size` tiling, the `cross` offset pair, the `max(142vh, 142vw)` rotated positioning, `z-index` handoff between the two nodes). The tile itself is upstream's canvas `toDataURL` seam, rebuilt purely: an SVG of the canvas dimensions — one `<text>` per line with the full font stack — base64-encoded in-library; `image` is referenced directly instead of re-rasterised. No `--n-*` vars — the theme's single `fontFamily` feeds the tile's font fallback."
    <|
        [ demoRow "Basic · default 32×32 tile"
            [ Watermark.view theme
                { watermarkD | content = Just "Naive UI" }
                [ watermarkedText ]
            ]
        , demoRow "Two lines · centered · gaps · cross"
            [ Watermark.view theme
                { watermarkD
                    | content = Just "elm-naive-ui\nwatermark"
                    , width = 120
                    , height = 44
                    , xGap = 32
                    , yGap = 32
                    , lineHeight = 20
                    , textAlign = Watermark.Center
                    , cross = True
                }
                [ watermarkedText ]
            ]
        , demoRow "Font stack · debug · not selectable"
            [ Watermark.view theme
                { watermarkD
                    | content = Just "Seemly"
                    , width = 100
                    , height = 32
                    , fontSize = 18
                    , fontWeight = 700
                    , fontStyle = "italic"
                    , fontColor = "rgba(0, 128, 0, .45)"
                    , rotate = -20
                    , debug = True
                    , selectable = False
                }
                [ watermarkedText ]
            ]
        , demoRow "Global rotate (overflow-hidden container)"
            [ Watermark.view theme
                { watermarkD
                    | content = Just "45°"
                    , globalRotate = 45
                }
                [ watermarkedText ]
            ]
        ]


watermarkD : Watermark.Options msg
watermarkD =
    Watermark.defaults


watermarkedText : Element msg
watermarkedText =
    Element.el [ Element.padding 24 ] (Element.text "The watermarked content sits in the container; the tile overlays it (pointer-events: none).")


treeSection : Element msg
treeSection =
    section "Tree"
        "Naive UI's tree — the `div.n-tree` root (17 `--n-*` vars; three derived from the wrapper-padding/height strings) rendering the flattened visible nodes as `n-tree-node-wrapper` rows: a `showLine` indent chain, the switcher (arrow svg, the loading spinner for `loadingKeys` keys — sw20/r85 baseline under the `spin*` overrides), the `data-checkbox`-wrapped `NUI.Checkbox` (cascade-checked via the shipped treemate helpers), and the prefix/label/suffix content. Everything interactive is data: `expandedKeys` / `checkedKeys` / `selectedKeys` / `pendingKey` / `loadingKeys` / `dropMark`; the pure helpers (`flatten`, `getCheckedKeys`, `check` / `uncheck`, `toggleExpand`, `toggleSelect`, `getNonLeafKeys`, `filterTree`) do the treemate math. Not ported: virtual list, expand motion, drag/keyboard events."
    <|
        [ demoRow "Basic · checkable (cascade, Child strategy)"
            [ Tree.view theme
                { treeD | data = treeOptions, expandedKeys = [ "beatles", "stones" ] }
            , Tree.view theme
                { treeD
                    | data = treeOptions
                    , expandedKeys = [ "beatles" ]
                    , checkable = True
                    , cascade = True
                    , checkStrategy = Tree.Child
                    , checkedKeys = [ "drive", "nowhere" ]
                }
            ]
        , demoRow "Multiple selection · showLine"
            [ Tree.view theme
                { treeD
                    | data = treeOptions
                    , expandedKeys = [ "beatles" ]
                    , multiple = True
                    , selectedKeys = [ "drive", "exile" ]
                }
            , Tree.view theme
                { treeD | data = treeOptions, expandedKeys = [ "beatles", "stones" ], showLine = True }
            ]
        , demoRow "block-line + ellipsis · pending + highlight"
            [ Tree.view theme
                { treeD
                    | data = treeOptions
                    , expandedKeys = [ "beatles" ]
                    , blockLine = True
                    , ellipsis = True
                    , pendingKey = Just "nowhere"
                    , highlightKeys = Just [ "revolver" ]
                }
            ]
        , demoRow "Loading switcher · empty"
            [ Tree.view theme
                { treeD | data = treeOptions, expandedKeys = [ "beatles", "stones" ], loadingKeys = [ "stones" ] }
            , Tree.view theme { treeD | attributes = [ Element.width (Element.px 240) ] }
            ]
        ]


treeD : Tree.Options msg
treeD =
    Tree.defaults


{-| Two albums, a nested disc one deep, a disabled leaf — enough shape for
the indent chain, the `--last-child` / `--is-leaf` guide lines, the
`--checkable` cascade, and the disabled state.
-}
treeOptions : List (Tree.TreeOption msg)
treeOptions =
    [ Tree.TreeOption
        { key = "beatles"
        , label = "The Beatles"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children =
            Just
                [ leafOption "drive" "Drive My Car"
                , leafOption "nowhere" "Nowhere Man"
                , Tree.TreeOption
                    { key = "anthology"
                    , label = "Anthology"
                    , disabled = False
                    , checkboxDisabled = False
                    , isLeaf = False
                    , children = Just [ leafOption "anth1" "Anthology 1" ]
                    , prefix = []
                    , suffix = []
                    }
                ]
        , prefix = []
        , suffix = []
        }
    , Tree.TreeOption
        { key = "stones"
        , label = "The Rolling Stones"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children = Just [ leafOption "exile" "Exile on Main St." ]
        , prefix = []
        , suffix = []
        }
    , Tree.TreeOption
        { key = "wildlife"
        , label = "Wild Life (disabled)"
        , disabled = True
        , checkboxDisabled = False
        , isLeaf = True
        , children = Nothing
        , prefix = []
        , suffix = []
        }
    ]


leafOption : String -> String -> Tree.TreeOption msg
leafOption key label =
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


autoCompleteSection : Element msg
autoCompleteSection =
    section "AutoComplete"
        "Naive UI's autocomplete — a bare `.n-auto-complete` wrapper around a plain `NUI.Input` trigger (NOT the selection: upstream drives `NInput` directly, no `NInternalSelection`); the menu is a separate caller-mounted body (its own follower upstream), `AutoComplete.menu` here — hardcoded Medium, `tabindex -1`, never `--selected` (no checkmark node), and `loading` is the input's suffix spinner, never a menu row. The caller owns the whole show gate (`getShow ? getShow (value || \"\") : value ≠ \"\"`, focused-typed, `showEmpty`), positioning, keyboard and the select commit (`onSelect value` always, then `clearAfterSelect` → null / the label commit, `append` ⇒ `value ++ label`); it does no filtering of its own — options are yours to derive (the email demo's suffix list). `fromString` lifts bare strings; `inputAttributes` is upstream's `inputProps`."
    <|
        [ demoRow "Basic (value + open menu + inputProps)"
            [ AutoComplete.view theme
                { acD | value = "Dri", attributes = [ Element.width (Element.px 220) ] }
            , AutoComplete.view theme
                { acD
                    | value = "v4f2"
                    , inputAttributes =
                        [ HA.attribute "autocomplete" "disabled"
                        , HA.id "ac-input-props"
                        ]
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , AutoComplete.menu theme
                { acMenuD | attributes = [ Element.width (Element.px 220) ] }
                [ AutoComplete.fromString "Drive My Car"
                , AutoComplete.fromString "Day Tripper"
                ]
            ]
        , demoRow "Sizes (the menu stays Medium)"
            [ AutoComplete.view theme
                { acD | size = AutoComplete.Small, value = "Dri", attributes = [ Element.width (Element.px 200) ] }
            , AutoComplete.view theme
                { acD | value = "Dri", attributes = [ Element.width (Element.px 220) ] }
            , AutoComplete.view theme
                { acD | size = AutoComplete.Large, value = "Dri", attributes = [ Element.width (Element.px 240) ] }
            , AutoComplete.menu theme
                { acMenuD | attributes = [ Element.width (Element.px 220) ] }
                (List.take 2 selectOptions)
            ]
        , demoRow "Group (header + children)"
            [ AutoComplete.view theme
                { acD | value = "In My Life", attributes = [ Element.width (Element.px 220) ] }
            , AutoComplete.menu theme
                { acMenuD | attributes = [ Element.width (Element.px 220) ] }
                selectOptions
            ]
        , demoRow "Status · disabled"
            [ AutoComplete.view theme
                { acD
                    | status = Just Input.Warning
                    , value = "warn@example.com"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , AutoComplete.view theme
                { acD
                    | status = Just Input.Error
                    , value = "error@example.com"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , AutoComplete.view theme
                { acD
                    | disabled = True
                    , value = "Disabled"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            ]
        , demoRow "Clearable · loading (suffix order: clear, loading, slot)"
            [ AutoComplete.view theme
                { acD | value = "clear me", clearable = True, attributes = [ Element.width (Element.px 200) ] }
            , AutoComplete.view theme
                { acD
                    | value = "Loading…"
                    , loading = True
                    , attributes = [ Element.width (Element.px 200) ]
                }
            , AutoComplete.view theme
                { acD
                    | value = "all three"
                    , clearable = True
                    , loading = True
                    , suffix = Just (Element.text "@")
                    , attributes = [ Element.width (Element.px 200) ]
                }
            ]
        , demoRow "Show gate (showEmpty + the empty seam)"
            [ AutoComplete.view theme
                { acD | placeholder = "Type to open", attributes = [ Element.width (Element.px 220) ] }
            , AutoComplete.menu theme
                { acMenuD
                    | empty = Just (Empty.view theme emptyD [])
                    , attributes = [ Element.width (Element.px 220) ]
                }
                []
            ]
        , demoRow "After select (the caller-owned commit)"
            [ cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ AutoComplete.view theme
                        { acD | placeholder = "clearAfterSelect → \"\"", attributes = [ Element.width (Element.px 200) ] }
                    , chip "onSelect \"Drive My Car\" → value = \"\""
                    ]
                )
            , cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ AutoComplete.view theme
                        { acD
                            | value = "Dri"
                            , placeholder = "append ⇒ value ++ label"
                            , attributes = [ Element.width (Element.px 200) ]
                        }
                    , chip "onSelect \"Drive My Car\" → \"DriDrive My Car\""
                    ]
                )
            ]
        , demoRow "Custom rows (renderLabel / renderOption)"
            [ AutoComplete.menu theme
                { acMenuD | attributes = [ Element.width (Element.px 220) ] }
                [ AutoComplete.fromString "A plain row"
                , SelectMenu.Custom
                    { key = "ac-custom"
                    , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text "renderOption row" ]
                    }
                ]
            ]
        ]


{-| The user rows the mention demos pick from (the default @-trigger
story — the module does no scan, the caller gates the list).
-}
mentionOptions : List (SelectMenu.Option msg)
mentionOptions =
    List.map
        (\name ->
            SelectMenu.Option
                { value = String.toLower name
                , label = name
                , disabled = False
                , attributes = []
                }
        )
        [ "710mechgy", "Zhe", "Alice", "Bob", "Carol" ]


{-| The tag rows the custom-prefix (#) cell picks from — the second of
the two caller-gated option lists.
-}
mentionTagOptions : List (SelectMenu.Option msg)
mentionTagOptions =
    List.map
        (\tag ->
            SelectMenu.Option
                { value = tag
                , label = "#" ++ tag
                , disabled = False
                , attributes = []
                }
        )
        [ "elm", "naive-ui", "ui" ]


mentionSection : Element msg
mentionSection =
    section "Mention"
        "Naive UI's mention — the same family as AutoComplete: a bare `.n-mention` wrapper around a plain `NUI.Input` trigger (NOT the selection — no `NInternalSelection` upstream), plus a separate caller-mounted `NUI.SelectMenu` body (`Mention.menu`). Three divergences from AutoComplete, frozen: `loading` is the MENU's `__loading` row (`MenuOptions.loading`), never the input suffix; upstream filters internally (the default `startsWith` predicate — the port drops the engine, the caller pre-filters and passes the filtered list); and the wrapper's cssr has no `display: inline-flex` (`width: 100%; z-index: auto; position: relative`) with `placeholder` defaulting to `\"\"`. The menu is hardcoded Medium, `tabindex -1`, and `value` stays `Single Nothing` — never `--selected`, no checkmark node. Options are `NUI.SelectMenu.Option` verbatim — no `fromString` (there are no bare-string options upstream); `type_` is `text`/`textarea` only. The caller owns the whole runtime: the show gate (the prefix scan + caret + separator formulas), the select splice, keyboard and positioning (upstream anchors the follower at the caret via mirror-div measurement — un-portable)."
    <|
        [ demoRow "Basic (the default @-trigger — caret inside an @-run opens)"
            [ cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ Mention.view theme
                        { mnD
                            | value = "@710"
                            , attributes = [ Element.width (Element.px 220) ]
                        }
                    , chip "prefix \"@\" · separator \" \" — the splice is caller-owned"
                    , Mention.menu theme
                        { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
                        mentionOptions
                    ]
                )
            , Mention.view theme
                { mnD
                    | placeholder = "Type @ to mention"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            ]
        , demoRow "Sizes (the menu stays Medium)"
            [ Mention.view theme
                { mnD | size = Mention.Small, value = "@710", attributes = [ Element.width (Element.px 200) ] }
            , Mention.view theme
                { mnD | value = "@710", attributes = [ Element.width (Element.px 220) ] }
            , Mention.view theme
                { mnD | size = Mention.Large, value = "@710", attributes = [ Element.width (Element.px 240) ] }
            , Mention.menu theme
                { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
                (List.take 4 mentionOptions)
            ]
        , demoRow "Textarea (type_ = Textarea — the union is text/textarea only)"
            [ Element.el [ Element.width (Element.px 360) ]
                (Mention.view theme
                    { mnD
                        | type_ = Mention.Textarea
                        , value = "A textarea.\nPing @710mechgy here."
                        , placeholder = "Type @ to mention"
                    }
                )
            ]
        , demoRow "Autosize (n-input--autosize, resizable suppressed — height measurement caller-owned)"
            [ Element.el [ Element.width (Element.px 360) ]
                (Mention.view theme
                    { mnD
                        | type_ = Mention.Textarea
                        , autosize = True
                        , value = "Autosized textarea:\ngrows with content."
                    }
                )
            ]
        , demoRow "Custom prefix (#@ — the caller gates the option set; the module does no scan)"
            [ cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ Mention.view theme
                        { mnD
                            | value = "#e"
                            , placeholder = "# for tags"
                            , attributes = [ Element.width (Element.px 200) ]
                        }
                    , chip "prefix \"#\" → the tag list"
                    , Mention.menu theme
                        { mnMenuD | attributes = [ Element.width (Element.px 200) ] }
                        mentionTagOptions
                    ]
                )
            , cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ Mention.view theme
                        { mnD
                            | value = "@z"
                            , placeholder = "@ for users"
                            , attributes = [ Element.width (Element.px 200) ]
                        }
                    , chip "prefix \"@\" → the user list"
                    , Mention.menu theme
                        { mnMenuD | attributes = [ Element.width (Element.px 200) ] }
                        mentionOptions
                    ]
                )
            ]
        , demoRow "Loading (THE divergence — the menu's __loading row, never the input suffix)"
            [ Mention.view theme
                { mnD
                    | value = "@7"
                    , placeholder = "Fetching users…"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , Mention.menu theme
                { mnMenuD | loading = True, attributes = [ Element.width (Element.px 220) ] }
                mentionOptions
            ]
        , demoRow "Group + custom rows (renderLabel lane)"
            [ Mention.view theme
                { mnD
                    | value = "@in my"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , Mention.menu theme
                { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
                (selectOptions
                    ++ [ SelectMenu.Custom
                            { key = "mention-custom"
                            , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text "renderOption row" ]
                            }
                       ]
                )
            ]
        , demoRow "Status · disabled"
            [ Mention.view theme
                { mnD
                    | status = Just Input.Warning
                    , value = "@710"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , Mention.view theme
                { mnD
                    | status = Just Input.Error
                    , value = "@zhe"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , Mention.view theme
                { mnD
                    | disabled = True
                    , value = "Disabled"
                    , attributes = [ Element.width (Element.px 220) ]
                }
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


{-| One static message demo cell: a fresh provider state in the given
placement; the fixed container is pinned into the cell with `position:
relative` (the LoadingBar demo's trick).
-}
messageState : Message.Placement -> List (Message.Item msg) -> Element msg
messageState placement items =
    modalHost []
        (Message.view theme
            { messageS
                | placement = placement
                , containerStyle = Just "position:relative;"
                , items = items
            }
        )


messageOf : String -> Message.Kind -> String -> Message.Item msg
messageOf key kind content =
    { messageI
        | key = key
        , options = { messageD | kind = kind, content = content }
    }


messageSection : Element msg
messageSection =
    section "Message"
        "Naive UI's message service: one caller-owned `State` holds the provider props (`max` — `Just 0` is unlimited and evictions drop the oldest item instantly, the 3000ms default, merged `keepAliveOnHover`/`closable`, `placement`) plus the queue. `create` appends and stamps the enter phase; `destroy` stamps the leave phase (a no-op while already leaving, like upstream's `hide()` on a hidden message); `remove` splices once the leave has run — the caller owns the hide clock, so these demos are static entered states (`phase = Nothing`) with one mid-enter item. A close click emits `onClose` only — completing the close is the caller's `destroy`; a message's close is never vetoed."
    <|
        [ demoRow "Kinds (one container, stacked)"
            [ messageState Message.Top
                [ messageOf "d" Message.Default "A default message — no icon wrapper"
                , messageOf "i" Message.Info "An info message"
                , messageOf "s" Message.Success "A success message"
                , messageOf "w" Message.Warning "A warning message"
                , messageOf "e" Message.Error "An error message"
                , messageOf "l" Message.Loading "A loading message — n-base-loading spinner"
                ]
            , messageState Message.BottomRight
                [ messageOf "b1" Message.Info "Bottom-right placement"
                , messageOf "b2" Message.Success "align-items flips to flex-end"
                ]
            ]
        , demoRow "Closable (onClose fires; you destroy)"
            [ messageState Message.Top
                [ { messageI
                    | key = "c1"
                    , options =
                        { messageD
                            | kind = Message.Info
                            , content = "Close me"
                            , closable = Just True
                            , onClose = Nothing
                        }
                  }
                , { messageI
                    | key = "c2"
                    , options =
                        { messageD
                            | kind = Message.Success
                            , content = "Also closable"
                            , closable = Just True
                        }
                  }
                ]
            ]
        , demoRow "Transition phases (caller clock)"
            [ messageState Message.Top
                [ messageOf "idle" Message.Info "Settled — no phase class"
                , { messageI
                    | key = "entering"
                    , options = { messageD | kind = Message.Success, content = "Entering — fade-in-height-expand-transition-enter-active" }
                    , phase = Just I.EnterActive
                  }
                , { messageI
                    | key = "leaving"
                    , options = { messageD | kind = Message.Warning, content = "Leaving — fade-in-height-expand-transition-leave-from" }
                    , phase = Just I.LeaveFrom
                  }
                ]
            ]
        , demoRow "Custom icon + render (replaces the whole body)"
            [ messageState Message.Top
                [ { messageI
                    | key = "icon"
                    , options =
                        { messageD
                            | content = "Custom icon — the wrapper appears for a Default kind"
                            , icon = Just (Element.text "✓")
                        }
                  }
                , { messageI
                    | key = "render"
                    , options =
                        { messageD
                            | render =
                                Just
                                    [ Element.el
                                        [ Element.htmlAttribute
                                            (HA.attribute
                                                "style"
                                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:10px 20px;color:var(--n-text-color)"
                                            )
                                        ]
                                        (Element.text "render — no .n-message tree, no icon/content/close")
                                    ]
                        }
                  }
                ]
            ]
        ]


{-| One static notification demo cell — the message demo's trick: a fresh
provider state per cell, pinned into it with `position: relative`.
-}
notificationState : Notification.Placement -> List (Notification.Item msg) -> Element msg
notificationState placement items =
    modalHost []
        (Notification.view theme
            { notificationS
                | placement = placement
                , containerStyle = Just "position:relative;"
                , items = items
            }
        )


notificationOf : String -> String -> Notification.Kind -> Notification.Item msg
notificationOf key title kind =
    { notificationI
        | key = key
        , options = { notificationD | title = Just title, kind = kind }
    }


notificationSection : Element msg
notificationSection =
    section "Notification"
        "Naive UI's notification service — the `NUI.Message` twin: one caller-owned `State` (provider props + queue) and pure transforms. Deltas: vars ride BOTH the wrapper and `n-notification`; `--n-icon-color` is emitted only for typed kinds (no `iconColorDefault` upstream); the default `scrollable` provider wraps the queue in an `n-scrollbar` tree (forced off for the `top`/`bottom` centers); the container gains a bare `transitioning` class while any item holds a phase; `content` renders in a `<pre>`; the close click emits `onClose` and the VETO is the caller not calling `destroy` (upstream's `false`/rejected-promise rule). These demos are static entered states — the caller owns the hide clock."
    <|
        [ demoRow "Kinds (top-right — scrollable, so the n-scrollbar tree shows)"
            [ notificationState Notification.TopRight
                [ notificationOf "d" "A default notification" Notification.Default
                , notificationOf "i" "An info notification" Notification.Info
                , notificationOf "s" "A success notification" Notification.Success
                , notificationOf "w" "A warning notification" Notification.Warning
                , notificationOf "e" "An error notification" Notification.Error
                ]
            ]
        , demoRow "Closable + description / content-in-pre / meta + action"
            [ notificationState Notification.TopRight
                [ { notificationI
                    | key = "full"
                    , options =
                        { notificationD
                            | kind = Notification.Info
                            , title = Just "Closable with the full tree"
                            , description = Just "The description row"
                            , content = Just "The content — upstream renders this in a <pre>"
                            , meta = Just "the meta line"
                            , action = Just (Element.text "action")
                            , closable = Just True
                        }
                  }
                , notificationOf "plain" "No avatar — bare main (close renders: closable defaults true)" Notification.Default
                ]
            ]
        , demoRow "Placements (top/bottom centers force the scrollbar off)"
            [ notificationState Notification.TopLeft
                [ notificationOf "tl" "Top-left — scrollable" Notification.Success ]
            , notificationState Notification.Top
                [ notificationOf "tc" "Top center — scrollable forced off (no scrollbar tree)" Notification.Warning ]
            , notificationState Notification.BottomRight
                [ notificationOf "br" "Bottom-right — align flips" Notification.Error ]
            ]
        , demoRow "Transition phases (caller clock) + the container's transitioning class"
            [ notificationState Notification.TopRight
                [ notificationOf "idle" "Settled — no phase class" Notification.Info
                , { notificationI
                    | key = "entering"
                    , options = { notificationD | title = Just "Entering — notification-transition-enter-active", kind = Notification.Success }
                    , phase = Just I.EnterActive
                  }
                , { notificationI
                    | key = "leaving"
                    , options = { notificationD | title = Just "Leaving — notification-transition-leave-from", kind = Notification.Warning }
                    , phase = Just I.LeaveFrom
                  }
                ]
            ]
        ]


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


{-| A plain demo cell for a standalone `.n-dialog` body (no fixed tree to
confine — just a sized box; the block body fills it).
-}
cell : Element msg -> Element msg
cell content =
    Element.el
        [ Element.width (Element.px 320)
        , Element.htmlAttribute
            (HA.attribute "style" "border:1px solid #efeff5;background:#fafafc")
        ]
        content


modalSection : Element msg
modalSection =
    section "Modal"
        "The mount-body family — its own fixed tree (container > mask > body-wrapper > scrollbar > content), self-positioned and centred by flex. The caller owns mounting, the show state, the transition clock (one clock drives the mask and body tuples), outside-click closing and Esc; the `dialog`/`confirm` presets compose `NUI.Dialog` (its section follows). The demo cells confine the fixed tree with a `transform: translate(0,0)` containing block."
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


{-| The drawer's `NDrawerContent` body — title, closable header, footer.
-}
drawerBody : Element msg
drawerBody =
    DrawerContent.view theme
        { drawerContentD
            | title = Just (Element.text "A drawer")
            , closable = True
            , footer = Just (Element.text "#footer")
        }
        [ Element.text "Edge-anchored, sized on the placement's axis." ]


drawerSection : Element msg
drawerSection =
    section "Drawer"
        "The mount-body sibling of Modal — its own container/mask/host tree, edge-anchored (`position: absolute` per placement, the body transition family derived from it) instead of flex-centred. `NDrawerContent` composition (header/body/footer + close), the 3-state mask, the native-scrollbar seam (default: no scrollbar node, unlike Modal) and the resize trigger are DOM; the caller owns the show state, the transition clock, mask-click closing (`onMaskClick` — the mask is interactive here), Esc and the resize drag."
    <|
        [ demoRow "Four placements (NDrawerContent composition)"
            [ modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Right, width = Just "200px" }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Left, width = Just "200px" }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Top, height = Just "120px" }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Bottom, height = Just "120px" }
                    [ drawerBody ]
                )
            ]
        , demoRow "Custom content (no DrawerContent)"
            [ modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Right, width = Just "220px" }
                    [ Element.el
                        [ Element.htmlAttribute
                            (HA.attribute
                                "style"
                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px 0 0 3px;padding:14px 18px;color:var(--n-text-color);height:100%;box-sizing:border-box"
                            )
                        ]
                        (Element.text "You own the box; the wrapper carries `n-drawer-content-wrapper`.")
                    ]
                )
            ]
        , demoRow "Mask variants + z-index"
            [ modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "180px"
                        , showMask = Drawer.Transparent
                    }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "180px"
                        , showMask = Drawer.Hidden
                    }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Right, width = Just "180px", zIndex = Just 100 }
                    [ drawerBody ]
                )
            ]
        , demoRow "Scroll seams + resize trigger"
            [ modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "220px"
                        , nativeScrollbar = False
                    }
                    [ DrawerContent.view theme
                        { drawerContentD
                            | title = Just (Element.text "Scrollbar body")
                            , nativeScrollbar = False
                        }
                        [ Element.text "Both seams swap to `NUI.Scrollbar` — `n-drawer-body` rides the scrollbar root." ]
                    ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "220px"
                        , resizable = True
                        , showResizeTriggerHover = True
                    }
                    [ drawerBody ]
                )
            ]
        , demoRow "Enter-active phase (caller clock)"
            [ modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "220px"
                        , maskTransition = Just I.EnterActive
                        , bodyTransition = Just I.EnterActive
                    }
                    [ drawerBody ]
                )
            ]
        ]


dialogState : List (DialogProvider.Item msg) -> Element msg
dialogState items =
    modalHost []
        (Element.column [] (DialogProvider.view theme { dialogPS | items = items }))


dialogSection : Element msg
dialogSection =
    section "Dialog"
        "A pure body component (upstream `NDialog`) — the `.n-dialog` card, never a mask or container. Standalone here, and as Modal's `dialog`/`confirm` preset bodies (the preset adds `n-modal` + `aria-modal`, phase class last). Composed actions (negative ghost/small first, positive small + kind-derived + loading), the kind→ icon/type system, icon-top placement, and the caller-owned runtime: the `useDialog` queue is ported as `NUI.DialogProvider` (fixed queues below — one caller-owned `State`, pure transforms, no clock: dialogs persist until destroyed), while close gating, mask/esc stay yours (see Modal)."
    <|
        [ demoRow "Kinds (bare body — the icon/type system)"
            [ cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Default
                        , title = Just (Element.text "Default")
                        , content = Just (Element.text "Info glyph on the base icon color.")
                        , positiveText = Just "OK"
                    }
                )
            , cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Warning
                        , title = Just (Element.text "Warning")
                        , content = Just (Element.text "A warning icon rides the title.")
                        , positiveText = Just "Proceed"
                        , negativeText = Just "Cancel"
                    }
                )
            , cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Error
                        , title = Just (Element.text "Error")
                        , content = Just (Element.text "Positive button keys to the kind.")
                        , positiveText = Just "Retry"
                        , negativeText = Just "Dismiss"
                    }
                )
            ]
        , demoRow "Modal dialog/confirm presets"
            [ modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Dialog
                        { dialogD
                            | title = Just (Element.text "Use dialog?")
                            , content = Just (Element.text "The preset body gains n-modal; .n-modal .n-dialog sizes it to 446px.")
                            , positiveText = Just "Confirm"
                            , negativeText = Just "Cancel"
                        }
                    )
                )
            , modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Confirm
                        { dialogD
                            | kind = T.Info
                            , title = Just (Element.text "A deprecated alias")
                            , content = Just (Element.text "confirm renders the identical body — only the constructor differs.")
                            , positiveText = Just "Got it"
                        }
                    )
                )
            ]
        , demoRow "useDialog service (NUI.DialogProvider — fixed queues)"
            [ dialogState
                [ { dialogPI
                    | key = "d1"
                    , zIndex = Just 2000
                    , options =
                        { dialogD
                            | kind = T.Warning
                            , title = Just (Element.text "Delete file?")
                            , content = Just (Element.text "A settled dialog — phase Nothing; the caller allocated z-index 2000.")
                            , positiveText = Just "OK"
                            , negativeText = Just "Cancel"
                        }
                  }
                ]
            , dialogState
                [ { dialogPI
                    | key = "d2"
                    , phase = Just I.EnterActive
                    , zIndex = Just 2000
                    , options =
                        { dialogD
                            | kind = T.Info
                            , title = Just (Element.text "Entering")
                            , content = Just (Element.text "Mid-enter — the mask fades in, the body scales up from 0.5.")
                            , positiveText = Just "OK"
                            , negativeText = Just "Cancel"
                        }
                  }
                , { dialogPI
                    | key = "d3"
                    , phase = Just I.LeaveActive
                    , zIndex = Just 2001
                    , options =
                        { dialogD
                            | kind = T.Error
                            , title = Just (Element.text "Leaving")
                            , content = Just (Element.text "Mid-leave — destroy stamped LeaveFrom; remove splices on after-leave.")
                            , positiveText = Just "OK"
                            , negativeText = Just "Cancel"
                        }
                  }
                ]
            ]
        , demoRow "icon-top, bordered, custom action"
            [ cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Success
                        , iconPlacement = Dialog.IconTop
                        , title = Just (Element.text "Centred")
                        , content = Just (Element.text "Icon-top swaps the margins and centres the icon above.")
                        , positiveText = Just "OK"
                    }
                )
            , cell
                (Dialog.view theme
                    { dialogD
                        | title = Just (Element.text "Bordered")
                        , bordered = True
                        , content = Just (Element.text "Opt back into the border.")
                        , action =
                            Just
                                [ Element.text "#action — the slot replaces the buttons"
                                ]
                    }
                )
            ]
        , demoRow "Loading + button-props overrides + dark"
            [ cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Error
                        , title = Just (Element.text "Deleting…")
                        , content = Just (Element.text "Positive disabled+loading; the negative never loads.")
                        , positiveText = Just "Delete"
                        , negativeText = Just "Cancel"
                        , loading = True
                    }
                )
            , cell
                (Dialog.view theme
                    { dialogD
                        | title = Just (Element.text "Overrides")
                        , content = Just (Element.text "positiveProps updates the derived base (spread semantics).")
                        , positiveText = Just "Round primary"
                        , negativeText = Just "Round negative"
                        , positiveProps = Just (\b -> { b | round = True })
                        , negativeProps = Just (\b -> { b | round = True })
                    }
                )
            , cell
                (Dialog.view darkTheme
                    { dialogD
                        | kind = T.Warning
                        , title = Just (Element.text "Dark")
                        , content = Just (Element.text "modalColor surface, dark-common close/kind colors.")
                        , positiveText = Just "OK"
                    }
                )
            ]
        ]


menuOpts : List (Menu.Option msg)
menuOpts =
    [ Menu.Option
        { key = "home"
        , label = "Home"
        , extra = Nothing
        , icon = Just starIcon
        , disabled = False
        , children = Nothing
        , attributes = []
        }
    , Menu.Option
        { key = "sub-1"
        , label = "Components"
        , extra = Just "16"
        , icon = Just starIcon
        , disabled = False
        , children =
            Just
                [ Menu.Option
                    { key = "sub-2"
                    , label = "Nested submenu"
                    , extra = Nothing
                    , icon = Just starIcon
                    , disabled = False
                    , children =
                        Just
                            [ Menu.Option
                                { key = "table", label = "Table", extra = Nothing, icon = Just starIcon, disabled = False, children = Nothing, attributes = [] }
                            , Menu.Option
                                { key = "cascader", label = "Cascader", extra = Nothing, icon = Nothing, disabled = False, children = Nothing, attributes = [] }
                            ]
                    , attributes = []
                    }
                , Menu.Group
                    { key = "group-1"
                    , label = "Layout"
                    , extra = Nothing
                    , disabled = False
                    , children =
                        [ Menu.Option
                            { key = "who", label = "Who is selected", extra = Nothing, icon = Just starIcon, disabled = False, children = Nothing, attributes = [] }
                        , Menu.Option
                            { key = "grid", label = "Grid (disabled)", extra = Nothing, icon = Nothing, disabled = True, children = Nothing, attributes = [] }
                        ]
                    , attributes = []
                    }
                ]
        , attributes = []
        }
    , Menu.Divider { attributes = [] }
    , Menu.Option
        { key = "about", label = "About", extra = Nothing, icon = Nothing, disabled = False, children = Nothing, attributes = [] }
    ]


menuSection : Element msg
menuSection =
    section "Menu"
        "The navigation tree (upstream `NMenu` over treemate options) — one recursive walk renders submenu/option/group/divider. State is caller-owned: `value` + `expandedKeys` in, `onSelect` / `onExpandedKeysChange` out (accordion applied via `toggleExpanded`); `initialExpandedKeys` / `expandTo` mirror the uncontrolled and imperative seams. Horizontal and collapsed submenus, and collapsed-leaf tooltips, are caller-mounted popovers — `submenuDropdownOptions` feeds `NUI.Dropdown.view`."
    <|
        [ demoRow "Vertical (fixed state: path expanded, leaf selected)"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Menu.view theme
                        { menuD
                            | value = Just "who"
                            , expandedKeys = [ "sub-1", "sub-2", "group-1" ]
                        }
                        menuOpts
                    )
                )
            ]
        , demoRow "Accordion + expand-all / value-path init"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Menu.view theme
                        { menuD
                            | accordion = True
                            , expandedKeys = Menu.initialExpandedKeys True Nothing menuOpts
                        }
                        menuOpts
                    )
                )
            , cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Menu.view theme
                        { menuD
                            | expandedKeys = Menu.initialExpandedKeys False (Just "cascader") menuOpts
                        }
                        menuOpts
                    )
                )
            ]
        , demoRow "Collapsed (icon-only centering) + indent tuning"
            [ cell
                (Element.el [ Element.width (Element.px 64) ]
                    (Menu.view theme
                        { menuD | collapsed = True, value = Just "who", expandedKeys = [ "sub-1" ] }
                        menuOpts
                    )
                )
            , cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Menu.view theme
                        { menuD
                            | rootIndent = Just 12
                            , indent = 16
                            , value = Just "who"
                            , expandedKeys = [ "sub-1", "group-1" ]
                        }
                        menuOpts
                    )
                )
            ]
        , demoRow "Horizontal + inverted"
            [ cell
                (Element.el [ Element.width Element.fill ]
                    (Menu.view theme
                        { menuD | mode = Menu.Horizontal, value = Just "who" }
                        menuOpts
                    )
                )
            , cell
                (Element.el
                    [ Element.width (Element.px 240)
                    , Element.padding 8
                    , Element.htmlAttribute (HA.attribute "style" "background:rgb(16,16,20)")
                    ]
                    (Menu.view theme
                        { menuD | inverted = True, value = Just "who", expandedKeys = [ "sub-1", "group-1" ] }
                        menuOpts
                    )
                )
            ]
        , demoRow "Menu disabled (submenu dead, root leaf alive — upstream quirk)"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Menu.view theme
                        { menuD | disabled = True, expandedKeys = [ "sub-1" ] }
                        menuOpts
                    )
                )
            ]
        ]


sliderD : Slider.Options msg
sliderD =
    Slider.defaults


sliderMarks : List Slider.Mark
sliderMarks =
    [ { value = 34, label = "34" }
    , { value = 75, label = "75" }
    ]


sliderSection : Element msg
sliderSection =
    section "Slider"
        "The rail/fill/handles numeric input (upstream `NSlider`). Drag is caller-owned runtime (`NUI.Split` precedent): `value`/`activeIndex`/`hoverIndex`/`dragging` in, discrete handle events + the root mousedown signal out; `pointerToValue`/`sanitizeValue`/`stepValue` carry the pointer→snap math. The value indicator renders inline (the teleported follower is the caller's popover seam)."
    <|
        [ demoRow "Single + range (fixed state; marks feed dots/marks/snap)"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD
                            | value = [ 40 ]
                            , marks = sliderMarks
                        }
                    )
                )
            , cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD
                            | range = True
                            , value = [ 24, 49 ]
                            , marks = sliderMarks
                        }
                    )
                )
            ]
        , demoRow "Tooltip indicator (pinned via hoverIndex / drag) + disabled"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD | value = [ 66 ], hoverIndex = 0, activeIndex = 0, dragging = True }
                    )
                )
            , cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD
                            | value = [ 12 ]
                            , disabled = True
                            , formatTooltip = Just (\v -> String.fromFloat v ++ "%")
                        }
                    )
                )
            ]
        , demoRow "Vertical + reverse (direction keys flip, dots still 34/75)"
            [ cell
                (Element.el [ Element.height (Element.px 220) ]
                    (Slider.view theme
                        { sliderD
                            | value = [ 77 ]
                            , vertical = True
                            , marks = sliderMarks
                        }
                    )
                )
            , cell
                (Element.el [ Element.height (Element.px 220) ]
                    (Slider.view theme
                        { sliderD
                            | value = [ 77 ]
                            , vertical = True
                            , reverse = True
                            , marks = sliderMarks
                        }
                    )
                )
            ]
        , demoRow "Range snap (`step: 'mark'`) + >2 values (fill suppressed, dots inactive — upstream quirk)"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD
                            | range = True
                            , value = [ 34, 75 ]
                            , step = Slider.StepMarks
                            , marks = sliderMarks
                        }
                    )
                )
            , cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD | range = True, value = [ 10, 50, 90 ], marks = sliderMarks }
                    )
                )
            ]
        ]


imageD : Image.Options msg
imageD =
    Image.defaults


imageLogo : String
imageLogo =
    "https://www.naiveui.com/assets/naivelogo.93278402.svg"


previewD : ImagePreview.Options msg
previewD =
    ImagePreview.defaults


previewZoom0 : ImagePreview.Zoom
previewZoom0 =
    ImagePreview.zoom0


groupD : ImageGroup.Options msg
groupD =
    ImageGroup.defaults


imageSection : Element msg
imageSection =
    section "Image"
        "The img surface (upstream `NImage`): `n-image` root + img with the full upstream attribute pack (`data-error`, `data-preview-src`, `data-group-id`, native `loading`, `object-fit`). Load/error/lazy state is caller-owned — `showError` flips the img to `fallbackSrc` + the `--preview-disabled` class, or swaps in the error slot replacing the img entirely; a `placeholder` renders while `loaded` is False and hides the img 0×0 (upstream bytes). The preview modal is the caller's seam (`onClick` + the preview-container `cssVars`)."
    <|
        [ demoRow "Basic + object-fit (fixed state)"
            [ cell
                (Image.view theme
                    { imageD
                        | src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                        , width = Just "160"
                        , height = Just "120"
                    }
                )
            , cell
                (Image.view theme
                    { imageD
                        | src = Just imageLogo
                        , width = Just "160"
                        , height = Just "120"
                        , objectFit = Image.Contain
                    }
                )
            , cell
                (Image.view theme
                    { imageD
                        | src = Just imageLogo
                        , width = Just "160"
                        , height = Just "120"
                        , objectFit = Image.Cover
                        , alt = Just "Cover fit"
                    }
                )
            ]
        , demoRow "Error → fallbackSrc + error slot (fixed state)"
            [ cell
                (Image.view theme
                    { imageD
                        | src = Just "https:// 07akioni.oss-cn-beijing.aliyuncs.com/broken.jpeg"
                        , fallbackSrc = Just imageLogo
                        , showError = True
                        , width = Just "160"
                        , height = Just "120"
                    }
                )
            , cell
                (Image.view theme
                    { imageD
                        | src = Just "https:// 07akioni.oss-cn-beijing.aliyuncs.com/broken.jpeg"
                        , showError = True
                        , error = Just (Element.text "Load failed")
                        , width = Just "160"
                        , height = Just "120"
                    }
                )
            ]
        , demoRow "Placeholder (img hidden 0×0 until loaded) + preview-disabled + lazy"
            [ cell
                (Image.view theme
                    { imageD
                        | src = Just imageLogo
                        , width = Just "160"
                        , height = Just "120"
                        , placeholder = Just (Element.text "Placeholder")
                    }
                )
            , cell
                (Image.view theme
                    { imageD
                        | src = Just imageLogo
                        , width = Just "160"
                        , height = Just "120"
                        , previewDisabled = True
                    }
                )
            , cell
                (Image.view theme
                    { imageD
                        | src = Just imageLogo
                        , width = Just "160"
                        , height = Just "120"
                        , lazy = True
                    }
                )
            ]
        ]


imagePreviewSection : Element msg
imagePreviewSection =
    section "Image Preview & Group"
        "The preview modal family (upstream `NImagePreview`/`NImageGroup`): container (the five toolbar `--n-*` vars) > overlay (click-to-close seat) > toolbar (prev/next only when `onPrev` is set — upstream keys both on `onPrev` — then rotate CCW/CW, original size, zoomOut, zoomIn, download, close) > wrapper > `img.n-image-preview`. The runtime is caller-owned (`NUI.Modal` precedent): `zoom` starts at `zoom0` and moves through the pure transforms (`zoomIn`/`zoomOut`/`rotateClockwise`/`resizeToOriginalSize`/`toggleOriginalSize`/`switchReset`), drag clamps through `moveStrategy` + `derivedOffset`, document keys map through `keyAction`, and `syncTransformOrigin` writes the thumbnail's center into `wrapperStyle`. The group adds the url registry (`srcList` wins with `p${index}` keys, else the caller-threaded `registered` ids) and the wrap-around walk (`nextIndex`/`prevIndex` skip empty urls). Demo cells confine the fixed tree like the modal demos."
    <|
        [ demoRow "Standalone preview (fixed state: open, zoom identity)"
            [ modalHost []
                (ImagePreview.view theme
                    { previewD
                        | show = True
                        , src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                    }
                )
            ]
        , demoRow "Zoom/rotate state + previewed-img props (8px white frame)"
            [ modalHost []
                (ImagePreview.view theme
                    { previewD
                        | show = True
                        , src = Just imageLogo
                        , zoom = { previewZoom0 | scale = 1.5, scaleExp = 1, rotate = 90 }
                        , imgDerived = True
                        , previewedImgStyle = [ ( "border", "8px solid white" ) ]
                    }
                )
            ]
        , demoRow "Toolbar suppressed + drag state (grabbing cursor, no transition)"
            [ modalHost []
                (ImagePreview.view theme
                    { previewD
                        | show = True
                        , src = Just imageLogo
                        , showToolbar = False
                    }
                )
            , modalHost []
                (ImagePreview.view theme
                    { previewD
                        | show = True
                        , src = Just imageLogo
                        , dragging = True
                        , imgDerived = True
                        , previewedImgStyle = [ ( "border", "8px solid white" ) ]
                    }
                )
            ]
        , demoRow "Group (srcList registry, second image current; slot thumbnails beside)"
            [ cell
                (Element.row [ Element.spacing 8 ]
                    [ Image.view theme
                        { imageD | src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg", width = Just "80", height = Just "60" }
                    , Image.view theme
                        { imageD | src = Just imageLogo, width = Just "80", height = Just "60" }
                    ]
                )
            , modalHost []
                (ImageGroup.view theme
                    { groupD
                        | show = True
                        , srcList =
                            [ "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                            , imageLogo
                            , imageLogo
                            ]
                        , current = 1
                    }
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
