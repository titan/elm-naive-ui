module Sections.Display exposing
    ( Model
    , Msg
    , affixSection
    , breadcrumbSection
    , codeSection
    , descriptionsSection
    , equationSection
    , flexSection
    , floatButtonGroupSection
    , floatButtonSection
    , gridSection
    , heatmapSection
    , init
    , layoutSection
    , listSection
    , pageHeaderSection
    , qrCodeSection
    , scrollbarSection
    , sections
    , subscriptions
    , timelineSection
    , update
    , watermarkSection
    )

{-| Display family sections: layout and data display primitives.

The static rows moved verbatim from Main.elm — that surface feeds the
check-dom gate, so every root keeps rendering exactly as before. The live
demo rows run a real update loop owned by this module (FloatButton's
`onUpdateShowMenu` menu channel, PageHeader's `onBack`). Phase 2 wires the
Layout "Basic" row's sider collapse trigger to the same model
(`LayoutSider.onToggleCollapsed`; init keeps the expanded literal, so the
initial DOM is byte-identical). The rest of this family is non-interactive
by design: Breadcrumb/Timeline/List (no click channel exists — `clickable`
is a class flag only)/PageHeader static row/Affix/Flex/Grid/QrCode/
FloatButton "Menu" resting+open specimens (the live row covers the toggle)/
FloatButtonGroup (no channels)/Heatmap/Descriptions/Scrollbar (no onScroll
channel)/Watermark/Code/Equation keep their static form.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Affix as Affix
import NUI.Breadcrumb as Breadcrumb
import NUI.Button as Button
import NUI.Code as Code
import NUI.Descriptions as Descriptions
import NUI.Equation as Equation
import NUI.Flex as Flex
import NUI.FloatButton as FloatButton
import NUI.FloatButtonGroup as FloatButtonGroup
import NUI.Grid as Grid
import NUI.Heatmap as Heatmap
import NUI.Layout as Layout
import NUI.LayoutFooter as LayoutFooter
import NUI.LayoutHeader as LayoutHeader
import NUI.LayoutSider as LayoutSider
import NUI.List as NList
import NUI.PageHeader as PageHeader
import NUI.QrCode as QrCode
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Timeline as Timeline
import NUI.Types as T
import NUI.Watermark as Watermark
import Showcase exposing (chip, codeHljs, demoBox, demoRow, fakeKatex, fakeKatexDisplay, section)
import Time



-- MODEL (one field per caller-owned bit of interactive state)


type alias Model =
    { backClicks : Int
    , floatMenuOpen : Bool
    , siderCollapsed : Bool
    }


init : Model
init =
    { backClicks = 0
    , floatMenuOpen = False
    , siderCollapsed = False
    }



-- UPDATE (one case per channel)


type Msg
    = PageBack
    | FloatMenuToggled Bool
    | SiderToggled Bool


update : Msg -> Model -> Model
update msg model =
    case msg of
        PageBack ->
            { model | backClicks = model.backClicks + 1 }

        FloatMenuToggled open ->
            { model | floatMenuOpen = open }

        SiderToggled collapsed ->
            { model | siderCollapsed = collapsed }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


btn : Button.Options msg
btn =
    Button.defaults


descD : Descriptions.Options msg
descD =
    Descriptions.defaults


descItemD : Descriptions.Item msg
descItemD =
    Descriptions.itemDefaults


scrollbarD : Scrollbar.Options msg
scrollbarD =
    Scrollbar.defaults


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


qrD : QrCode.Options msg
qrD =
    QrCode.defaults


floatButtonD : FloatButton.Options msg
floatButtonD =
    FloatButton.defaults


floatButtonGroupD : FloatButtonGroup.Options msg
floatButtonGroupD =
    FloatButtonGroup.defaults


codeD : Code.Options msg
codeD =
    Code.defaults


equationD : Equation.Options
equationD =
    Equation.defaults


heatmapD : Heatmap.Options msg
heatmapD =
    Heatmap.defaults


flexD : Flex.Options msg
flexD =
    Flex.defaults


gridD : Grid.Options msg
gridD =
    Grid.defaults


gridItem : Grid.Item msg
gridItem =
    Grid.item



-- SECTIONS


breadcrumbSection : Theme -> Element msg
breadcrumbSection theme =
    section theme "Breadcrumb" "Navigation trails." <|
        [ demoRow theme
            "dsp-001"
            "Default"
            [ Breadcrumb.view theme
                bcD
                [ { bcItem | href = Just "/", content = [ Element.text "Home" ] }
                , { bcItem | href = Just "/library", content = [ Element.text "Library" ] }
                , { bcItem | content = [ Element.text "Data" ] }
                ]
            ]
        , demoRow theme
            "dsp-002"
            "Custom separator (per item)"
            [ Breadcrumb.view theme
                { bcD | separator = "›" }
                [ { bcItem | separator = Just "›", href = Just "/", content = [ Element.text "Root" ] }
                , { bcItem | separator = Just "›", content = [ Element.text "Leaf" ] }
                ]
            ]
        ]


timelineSection : Theme -> Element msg
timelineSection theme =
    section theme "Timeline" "Vertical event trails." <|
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


listSection : Theme -> Element msg
listSection theme =
    section theme "List" "Bordered, hoverable item lists." <|
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


pageHeaderRows : Theme -> List (Element msg)
pageHeaderRows theme =
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


pageHeaderSection : Theme -> Element msg
pageHeaderSection theme =
    section theme
        "Page Header"
        "Title, subtitle and extra (pass `onBack` to add the back control)."
        (pageHeaderRows theme)


{-| Live: `#secf-pageheader-back` — the back button counts real clicks
(onBack is the port's caller-owned channel; Nothing hides the control).
-}
pageHeaderLiveRow : Model -> Theme -> Element Msg
pageHeaderLiveRow model theme =
    demoRow theme
        "dsp-003"
        "PageHeader · back clicks (live)"
        [ Element.el [ Element.width Element.fill ]
            (PageHeader.view theme
                { pageHeaderD
                    | title = Just "Detail page"
                    , onBack = Just PageBack
                }
                [ Element.text
                    ("The back control fires onBack — "
                        ++ String.fromInt model.backClicks
                        ++ " click(s) so far."
                    )
                ]
            )
        ]


pageHeaderLiveSection : Model -> Theme -> Element Msg
pageHeaderLiveSection model theme =
    section theme
        "Page Header"
        "Title, subtitle and extra (pass `onBack` to add the back control)."
        (pageHeaderRows theme ++ [ pageHeaderLiveRow model theme ])


affixSection : Theme -> Element msg
affixSection theme =
    section theme "Affix" "Pins content while scrolling (the affixed state is caller-owned). The preview box is the containing block — the fixed button stays inside it." <|
        [ demoBox theme
            "dsp-004"
            150
            (Element.el [ Element.padding 12 ]
                (Affix.view theme
                    { affixD | affixed = True, top = Just 12 }
                    [ Button.view theme { btn | kind = T.Primary } [ Element.text "Affixed" ] ]
                )
            )
        ]


flexSection : Theme -> Element msg
flexSection theme =
    section theme
        "Flex"
        "Naive UI's flexbox primitive — an inline flex container (no stylesheet rule; the layout is inline `display`/`gap`)."
    <|
        [ demoRow theme
            "dsp-005"
            "Gap"
            [ Flex.view theme
                flexD
                [ chip theme "One", chip theme "Two", chip theme "Three" ]
            ]
        , demoRow theme
            "dsp-006"
            "Justify · space-between"
            [ Flex.view theme
                { flexD | justify = Flex.SpaceBetween, size = Flex.Number 16 }
                [ chip theme "Left", chip theme "Right" ]
            ]
        , demoRow theme
            "dsp-007"
            "Vertical · centered"
            [ Flex.view theme
                { flexD | direction = Flex.Vertical, size = Flex.Number 8, align = Just Flex.Center }
                [ chip theme "Top", chip theme "Middle", chip theme "Bottom" ]
            ]
        , demoRow theme
            "dsp-008"
            "Inline · reversed"
            [ Flex.view theme
                { flexD | inline = True, size = Flex.Number2 4 12, reverse = True }
                [ chip theme "A", chip theme "B", chip theme "C" ]
            ]
        ]


gridSection : Theme -> Element msg
gridSection theme =
    section theme
        "Grid"
        "A 24-column CSS grid (inline `display:grid`, no stylesheet rule); span/offset and the responsive collapse algorithm are caller-driven."
    <|
        [ demoRow theme
            "dsp-009"
            "Spans (12-col tracks)"
            [ Grid.view
                { gridD | cols = Grid.Number 12, xGap = Grid.Number 16, yGap = Grid.Number 16 }
                [ { gridItem | span = Grid.Number 6, content = [ chip theme "span 6" ] }
                , { gridItem | span = Grid.Number 6, content = [ chip theme "span 6" ] }
                , { gridItem | span = Grid.Number 4, content = [ chip theme "span 4" ] }
                , { gridItem | span = Grid.Number 8, content = [ chip theme "span 8" ] }
                ]
            ]
        , demoRow theme
            "dsp-010"
            "Collapsed (responsive overflow → suffix rest)"
            [ Grid.view
                { gridD
                    | cols = Grid.Number 12
                    , xGap = Grid.Number 12
                    , collapsed = True
                    , collapsedRows = 1
                }
                [ { gridItem | span = Grid.Number 4, content = [ chip theme "4" ] }
                , { gridItem | span = Grid.Number 4, content = [ chip theme "4" ] }
                , { gridItem | span = Grid.Number 4, content = [ chip theme "4" ] }
                , { gridItem | span = Grid.Number 4, content = [ chip theme "hidden" ] }
                , { gridItem | suffix = True, content = [ Element.text "…" ] }
                ]
            ]
        ]


qrCodeSection : Theme -> Element msg
qrCodeSection theme =
    section theme "QrCode" "QR codes, encoded by the ported Nayuki library and drawn as inline SVG." <|
        [ demoRow theme
            "dsp-011"
            "Values"
            [ QrCode.view theme { qrD | value = "https://www.naiveui.com/" }
            , QrCode.view theme
                { qrD
                    | value = "https://www.naiveui.com/"
                    , color = "#18a058"
                    , backgroundColor = "#F5F5F5"
                }
            ]
        , demoRow theme
            "dsp-012"
            "Size & error correction"
            [ QrCode.view theme { qrD | value = "The rain dampened the sky", size = 140 }
            , QrCode.view theme
                { qrD | value = "雨淋湿了天空", errorCorrectionLevel = QrCode.H }
            ]
        , demoRow theme
            "dsp-013"
            "Icon"
            [ QrCode.view theme
                { qrD
                    | value = "https://www.naiveui.com/"
                    , iconSrc = Just "https://example.com/icon.png"
                    , errorCorrectionLevel = QrCode.H
                }
            ]
        ]


floatButtonRows : Theme -> List (Element msg)
floatButtonRows theme =
    [ demoRow theme
        "dsp-014"
        "Shapes & types"
        [ FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text "+" ]
        , FloatButton.view theme
            { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square }
            [ Element.text "S" ]
        , FloatButton.view theme
            { floatButtonD | position = FloatButton.Relative, type_ = FloatButton.Primary }
            [ Element.text "+" ]
        ]
    , demoRow theme
        "dsp-015"
        "Description"
        [ FloatButton.view theme
            { floatButtonD | position = FloatButton.Relative, description = Just (Element.text "Top") }
            [ Element.text "↑" ]
        ]
    , demoRow theme
        "dsp-016"
        "Menu"
        -- Resting state (showMenu = False): the body icon shows and the
        -- close glyph stays hidden until the menu opens. A second demo
        -- renders the open state in a non-clipping box so the popped menu
        -- (absolutely positioned above the button) is visible.
        [ Element.column [ Element.spacing 24 ]
            [ FloatButton.view theme
                { floatButtonD
                    | position = FloatButton.Relative
                    , menuTrigger = Just FloatButton.Click
                    , showMenu = False
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
            , Element.el
                [ Element.paddingEach { top = 160, bottom = 20, left = 20, right = 20 }
                , Element.htmlAttribute
                    (HA.attribute "style" "position:relative;background:#fff")
                ]
                (FloatButton.view theme
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
                )
            ]
        ]
    ]


floatButtonSection : Theme -> Element msg
floatButtonSection theme =
    section theme
        "Float Button"
        "A floating action button (position and offsets are caller-owned)."
        (floatButtonRows theme)


{-| Live: `#secf-float-menu` — the click-triggered menu really opens/closes
(showMenu is caller-owned; onUpdateShowMenu carries the toggle).
-}
floatButtonLiveRow : Model -> Theme -> Element Msg
floatButtonLiveRow model theme =
    demoRow theme
        "dsp-017"
        "FloatButton · click menu (live)"
        [ Element.el
            [ Element.paddingEach { top = 170, bottom = 20, left = 20, right = 20 }
            , Element.htmlAttribute
                (HA.attribute "style" "position:relative;background:#fff")
            ]
            (FloatButton.view theme
                { floatButtonD
                    | position = FloatButton.Relative
                    , menuTrigger = Just FloatButton.Click
                    , showMenu = model.floatMenuOpen
                    , onUpdateShowMenu = Just FloatMenuToggled
                    , menu =
                        [ FloatButton.view theme
                            { floatButtonD
                                | position = FloatButton.Relative
                                , description = Just (Element.text "Add")
                            }
                            [ Element.text "+" ]
                        , FloatButton.view theme
                            { floatButtonD
                                | position = FloatButton.Relative
                                , description = Just (Element.text "Edit")
                            }
                            [ Element.text "✎" ]
                        ]
                }
                [ Element.text "+" ]
            )
        , Element.text
            (if model.floatMenuOpen then
                "menu open"

             else
                "menu closed"
            )
        ]


floatButtonLiveSection : Model -> Theme -> Element Msg
floatButtonLiveSection model theme =
    section theme
        "Float Button"
        "A floating action button (position and offsets are caller-owned)."
        (floatButtonRows theme ++ [ floatButtonLiveRow model theme ])


layoutSection : Model -> Theme -> Element Msg
layoutSection model theme =
    section theme "Layout" "App shell — header, sider, content and footer (the sider's collapsed state is caller-owned)." <|
        [ demoRow theme
            "dsp-018"
            "Basic (header · sider · content · footer)"
            [ Element.el [ Element.width Element.fill ]
                (Layout.view theme
                    layD
                    [ LayoutHeader.view theme { lhD | bordered = True } [ Element.text "Header" ]
                    , Layout.view theme
                        { layD | hasSider = True }
                        [ LayoutSider.view theme
                            { lsD
                                | bordered = True
                                , showTrigger = LayoutSider.ArrowCircle
                                , collapsed = model.siderCollapsed
                                , onToggleCollapsed = Just SiderToggled
                            }
                            [ Element.text "Sider" ]
                        , Layout.content theme layD [ Element.text "Content" ]
                        ]
                    , LayoutFooter.view theme { lfD | bordered = True } [ Element.text "Footer" ]
                    ]
                )
            ]
        , demoRow theme
            "dsp-019"
            "Collapsed sider (right placement · bar trigger)"
            [ Element.el [ Element.width Element.fill ]
                (Layout.view theme
                    { layD | hasSider = True }
                    [ -- Content first so the sider paints on the right (upstream's
                      -- collapse-right demo orders the pair this way).
                      -- `showCollapsedContent = False` hides the label when
                      -- collapsed instead of clipping it to a stray fragment
                      -- inside the 48px bar (the upstream show-sider-content
                      -- demo's setting).
                      Layout.content theme layD [ Element.text "Content" ]
                    , LayoutSider.view theme
                        { lsD
                            | collapsed = True
                            , width = "200px"
                            , collapsedWidth = "48px"
                            , showCollapsedContent = False
                            , showTrigger = LayoutSider.Bar
                            , placement = LayoutSider.Right
                        }
                        [ Element.text "Collapsed" ]
                    ]
                )
            ]
        , demoRow theme
            "dsp-020"
            "Embedded (inset shell)"
            [ Element.el [ Element.width Element.fill ]
                (Layout.view theme
                    { layD | embedded = True }
                    [ LayoutHeader.view theme lhD [ Element.text "Embedded header" ]
                    , Layout.content theme layD [ Element.text "Embedded content" ]
                    ]
                )
            ]
        ]


floatButtonGroupSection : Theme -> Element msg
floatButtonGroupSection theme =
    section theme
        "Float Button Group"
        "A group of float buttons (shape, position and offsets are caller-owned)."
    <|
        [ demoRow theme
            "dsp-021"
            "Circle"
            [ FloatButtonGroup.view theme
                { floatButtonGroupD | position = FloatButton.Relative, shape = FloatButton.Circle }
                [ FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text "+" ]
                , FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text "?" ]
                ]
            ]
        , demoRow theme
            "dsp-022"
            "Square"
            [ FloatButtonGroup.view theme
                { floatButtonGroupD | position = FloatButton.Relative, shape = FloatButton.Square }
                [ FloatButton.view theme { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square } [ Element.text "A" ]
                , FloatButton.view theme { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square } [ Element.text "B" ]
                ]
            ]
        ]


heatmapSection : Theme -> Element msg
heatmapSection theme =
    section theme
        "Heatmap"
        "GitHub-style contribution calendar: a real `table` of day rects coloured by `value / maxValue`, with week/month labels and a less/more indicator. Time is caller-owned (`zone`/`now`)."
    <|
        [ demoRow theme
            "dsp-023"
            "Default"
            [ Heatmap.view theme { heatmapD | data = heatmapSample, now = sampleNow } []
            ]
        , demoRow theme
            "dsp-024"
            "Loading"
            [ Heatmap.view theme
                { heatmapD | loading = True, loadingData = Just [], now = sampleNow }
                []
            ]
        , demoRow theme
            "dsp-025"
            "Small + custom palette + gaps filled"
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


descriptionsSection : Theme -> Element msg
descriptionsSection theme =
    section theme
        "Descriptions"
        "Labelled field/value tables. `span` and `column` pack the rows; the packer is the pure `Descriptions.layout`."
    <|
        [ demoRow theme
            "dsp-026"
            "Basic (title + a span-2 cell)"
            [ Descriptions.view theme
                { descD | title = Just (Element.text "Description") }
                [ { descItemD | label = Just (Element.text "Breakfast"), content = [ Element.text "Apple" ] }
                , { descItemD | label = Just (Element.text "Brunch"), content = [ Element.text "Apple" ] }
                , { descItemD | label = Just (Element.text "Lunch"), content = [ Element.text "Apple" ] }
                , { descItemD | span = 2, label = Just (Element.text "Supper"), content = [ Element.text "Two Apples" ] }
                , { descItemD | label = Just (Element.text "Midnight Snack"), content = [ Element.text "Apple" ] }
                ]
            ]
        , demoRow theme
            "dsp-027"
            "Bordered"
            [ Descriptions.view theme
                { descD | bordered = True }
                [ { descItemD | label = Just (Element.text "Name"), content = [ Element.text "Naive UI" ] }
                , { descItemD | label = Just (Element.text "Version"), content = [ Element.text "0.19" ] }
                , { descItemD | label = Just (Element.text "License"), content = [ Element.text "MIT" ] }
                ]
            ]
        , demoRow theme
            "dsp-028"
            "Left label placement (bordered)"
            [ Descriptions.view theme
                { descD | labelPlacement = Descriptions.Left, bordered = True }
                [ { descItemD | label = Just (Element.text "Name"), content = [ Element.text "Naive UI" ] }
                , { descItemD | label = Just (Element.text "Version"), content = [ Element.text "0.19" ] }
                ]
            ]
        , demoRow theme
            "dsp-029"
            "Columns = 4"
            [ Descriptions.view theme
                { descD | columns = Just 4 }
                (List.map
                    (\l -> { descItemD | label = Just (Element.text l), content = [ Element.text "Apple" ] })
                    [ "A", "B", "C", "D" ]
                )
            ]
        ]


scrollbarSection : Theme -> Element msg
scrollbarSection theme =
    section theme
        "Scrollbar"
        "A styled scroll container with custom rails. The caller owns whether each bar is shown and its measured geometry."
    <|
        [ demoRow theme
            "dsp-030"
            "Vertical bar shown"
            [ Element.el [ Element.height (Element.px 120), Element.width Element.fill ]
                (Scrollbar.view theme
                    { scrollbarD
                        | showYBar = True
                        , yBarStyle = Just "height:48px;top:8px"
                    }
                    [ Element.paragraph [] (List.repeat 3 (Element.text scrollbarCopy)) ]
                )
            ]
        , demoRow theme
            "dsp-031"
            "Both rails (x-scrollable)"
            -- a fixed-px cell (not `width fill`): a fill cell keeps
            -- `flex-basis: 0%` + `min-width: auto`, and the nowrap content's
            -- min-content inflates the cell to content width instead of
            -- letting the scroll container clip it
            [ Element.el [ Element.height (Element.px 120), Element.width (Element.px 460) ]
                (Scrollbar.view theme
                    { scrollbarD
                        | xScrollable = True
                        , showYBar = True
                        , yBarStyle = Just "height:48px;top:8px"
                        , showXBar = True
                        , xBarStyle = Just "width:80px;left:0"
                    }
                    -- a long nowrap line so the row genuinely overflows and
                    -- the horizontal thumb has something to thumb
                    [ Element.el [ Element.htmlAttribute (HA.attribute "style" "white-space:nowrap") ]
                        (Element.text (scrollbarCopy ++ "  " ++ scrollbarCopy))
                    ]
                )
            ]
        , demoRow theme
            "dsp-032"
            "Rails only (left / top)"
            [ Element.el [ Element.height (Element.px 100), Element.width Element.fill ]
                (Scrollbar.view theme
                    { scrollbarD | yPlacement = Scrollbar.Left }
                    [ Element.paragraph [] [ Element.text scrollbarCopy ] ]
                )
            , Element.el [ Element.height (Element.px 100), Element.width (Element.px 460) ]
                (Scrollbar.view theme
                    { scrollbarD | xScrollable = True, xPlacement = Scrollbar.Top }
                    [ Element.el [ Element.htmlAttribute (HA.attribute "style" "white-space:nowrap") ]
                        (Element.text scrollbarCopy)
                    ]
                )
            ]
        ]


scrollbarCopy : String
scrollbarCopy =
    "And as I sat there, brooding on the old unknown world, I thought of Gatsby's wonder when he first picked out the green light at the end of Daisy's dock."


watermarkSection : Theme -> Element msg
watermarkSection theme =
    section theme
        "Watermark"
        "Naive UI's watermark — the `div.n-watermark-container` (the `--selectable` / `--global-rotate` / `--fullscreen` modifiers; bare overlay when fullscreen without global rotation) wrapping the content plus the tiled `div.n-watermark` overlay (`background-size` tiling, the `cross` offset pair, the `max(142vh, 142vw)` rotated positioning, `z-index` handoff between the two nodes). The tile itself is upstream's canvas `toDataURL` seam, rebuilt purely: an SVG of the canvas dimensions — one `<text>` per line with the full font stack — base64-encoded in-library; `image` is referenced directly instead of re-rasterised. No `--n-*` vars — the theme's single `fontFamily` feeds the tile's font fallback."
    <|
        [ demoRow theme
            "dsp-033"
            "Basic · upstream demo tile (192×128, cross)"
            [ Watermark.view theme
                { watermarkD
                    | content = Just "Naive UI"
                    , width = 192
                    , height = 128
                    , fontSize = 16
                    , lineHeight = 16
                    , xOffset = 12
                    , yOffset = 28
                    , rotate = -15
                    , cross = True
                }
                [ watermarkedText ]
            ]
        , demoRow theme
            "dsp-034"
            "Two lines · centered · gaps · cross"
            [ Watermark.view theme
                { watermarkD
                    | content = Just "elm-naive-ui\nwatermark"
                    , width = 192
                    , height = 128
                    , xGap = 32
                    , yGap = 32
                    , fontSize = 16
                    , lineHeight = 20
                    , xOffset = 12
                    , yOffset = 28
                    , rotate = -15
                    , textAlign = Watermark.Center
                    , cross = True
                }
                [ watermarkedText ]
            ]
        , demoRow theme
            "dsp-035"
            "Font stack · debug · not selectable"
            [ Watermark.view theme
                { watermarkD
                    | content = Just "Seemly"
                    , width = 160
                    , height = 64
                    , fontSize = 16
                    , fontWeight = 700
                    , fontStyle = "italic"
                    , fontColor = "rgba(0, 128, 0, .45)"
                    , rotate = -15
                    , xOffset = 12
                    , yOffset = 28
                    , debug = True
                    , selectable = False
                }
                [ watermarkedText ]
            ]
        , demoRow theme
            "dsp-036"
            "Global rotate (overflow-hidden container)"
            [ Watermark.view theme
                { watermarkD
                    | content = Just "45°"
                    , width = 96
                    , height = 32
                    , fontSize = 16
                    , lineHeight = 16
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


codeSection : Theme -> Element msg
codeSection theme =
    section theme
        "Code"
        "A code block over a caller-supplied highlight.js — highlighting is the caller's to own."
        [ demoRow theme
            "dsp-037"
            "Basic (highlighted)"
            [ Code.view theme
                { codeD
                    | code = "const message = 'hello'"
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                }
                []
            ]
        , demoRow theme
            "dsp-038"
            "Inline"
            [ Element.text "Call "
            , Code.view theme
                { codeD
                    | code = "greet()"
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                    , inline = True
                }
                []
            , Element.text " to run it."
            ]
        , demoRow theme
            "dsp-039"
            "Line numbers"
            [ Code.view theme
                { codeD
                    | code = "const a = 1\nconst b = 2\nconst c = 3"
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                    , showLineNumbers = True
                }
                []
            ]
        , demoRow theme
            "dsp-040"
            "Word wrap (line numbers suppressed)"
            [ Element.el [ Element.width (Element.px 220) ]
                (Code.view theme
                    { codeD
                        | code = "const longName = someFunction(anotherArgument, yetAnotherArgument)"
                        , language = Just "javascript"
                        , hljs = Just codeHljs
                        , wordWrap = True
                        , showLineNumbers = True
                    }
                    []
                )
            ]
        , demoRow theme
            "dsp-041"
            "URI encoded"
            [ Code.view theme
                { codeD
                    | code = "const%20x%20%3D%201"
                    , uri = True
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                }
                []
            ]
        , demoRow theme
            "dsp-042"
            "Trim off"
            [ Code.view theme
                { codeD
                    | code = "    const spaced = true    "
                    , trim = False
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                }
                []
            ]
        , demoRow theme
            "dsp-043"
            "No hljs (plain text)"
            [ Code.view theme
                { codeD | code = "const plain = 1", language = Just "javascript" }
                []
            ]
        ]


equationSection : Theme -> Element msg
equationSection theme =
    section theme
        "Equation"
        "KaTeX-rendered math via a caller-supplied renderToString closure (the component ships no KaTeX)."
        [ demoRow theme
            "dsp-044"
            "Inline (fake katex)"
            [ Equation.view theme { equationD | value = "E = mc^2", katex = Just fakeKatex } ]
        , demoRow theme
            "dsp-045"
            "Display wrapper"
            [ Equation.view theme { equationD | value = "x^2 + y^2 = z^2", katex = Just fakeKatexDisplay } ]
        , demoRow theme
            "dsp-046"
            "No katex"
            [ Equation.view theme { equationD | value = "a^2 + b^2 = c^2" } ]
        ]



-- FAMILY BODY (Main.body order; live variants where live demos exist)


sections : Model -> Theme -> List (Element Msg)
sections model theme =
    [ breadcrumbSection theme
    , timelineSection theme
    , listSection theme
    , pageHeaderLiveSection model theme
    , affixSection theme
    , flexSection theme
    , gridSection theme
    , qrCodeSection theme
    , floatButtonLiveSection model theme
    , layoutSection model theme
    , floatButtonGroupSection theme
    , heatmapSection theme
    , descriptionsSection theme
    , scrollbarSection theme
    , watermarkSection theme
    , codeSection theme
    , equationSection theme
    ]
