module Sections.Display exposing
    ( affixSection
    , breadcrumbSection
    , codeSection
    , descriptionsSection
    , equationSection
    , flexSection
    , floatButtonGroupSection
    , floatButtonSection
    , gridSection
    , heatmapSection
    , layoutSection
    , listSection
    , pageHeaderSection
    , qrCodeSection
    , scrollbarSection
    , timelineSection
    , watermarkSection
    )

{-| Static showcase sections for the Display family (layout and data display
primitives), moved verbatim from Main.elm — the rendered DOM must stay
byte-identical (the check-dom gate reads this surface).
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
import NUI.Timeline as Timeline
import NUI.Types as T
import NUI.Watermark as Watermark
import Showcase exposing (chip, codeHljs, demoBox, demoRow, fakeKatex, fakeKatexDisplay, section, theme)
import Time



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


breadcrumbSection : Element msg
breadcrumbSection =
    section "Breadcrumb" "Navigation trails." <|
        [ demoRow "Default"
            [ Breadcrumb.view theme
                bcD
                [ { bcItem | href = Just "/", content = [ Element.text "Home" ] }
                , { bcItem | href = Just "/library", content = [ Element.text "Library" ] }
                , { bcItem | content = [ Element.text "Data" ] }
                ]
            ]
        , demoRow "Custom separator (per item)"
            [ Breadcrumb.view theme
                { bcD | separator = "›" }
                [ { bcItem | separator = Just "›", href = Just "/", content = [ Element.text "Root" ] }
                , { bcItem | separator = Just "›", content = [ Element.text "Leaf" ] }
                ]
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
    section "Affix" "Pins content while scrolling (the affixed state is caller-owned). The preview box is the containing block — the fixed button stays inside it." <|
        [ demoBox 150
            (Element.el [ Element.padding 12 ]
                (Affix.view theme
                    { affixD | affixed = True, top = Just 12 }
                    [ Button.view theme { btn | kind = T.Primary } [ Element.text "Affixed" ] ]
                )
            )
        ]


flexSection : Element msg
flexSection =
    section "Flex"
        "Naive UI's flexbox primitive — an inline flex container (no stylesheet rule; the layout is inline `display`/`gap`)."
    <|
        [ demoRow "Gap"
            [ Flex.view theme
                flexD
                [ chip "One", chip "Two", chip "Three" ]
            ]
        , demoRow "Justify · space-between"
            [ Flex.view theme
                { flexD | justify = Flex.SpaceBetween, size = Flex.Number 16 }
                [ chip "Left", chip "Right" ]
            ]
        , demoRow "Vertical · centered"
            [ Flex.view theme
                { flexD | direction = Flex.Vertical, size = Flex.Number 8, align = Just Flex.Center }
                [ chip "Top", chip "Middle", chip "Bottom" ]
            ]
        , demoRow "Inline · reversed"
            [ Flex.view theme
                { flexD | inline = True, size = Flex.Number2 4 12, reverse = True }
                [ chip "A", chip "B", chip "C" ]
            ]
        ]


gridSection : Element msg
gridSection =
    section "Grid"
        "A 24-column CSS grid (inline `display:grid`, no stylesheet rule); span/offset and the responsive collapse algorithm are caller-driven."
    <|
        [ demoRow "Spans (12-col tracks)"
            [ Grid.view
                { gridD | cols = Grid.Number 12, xGap = Grid.Number 16, yGap = Grid.Number 16 }
                [ { gridItem | span = Grid.Number 6, content = [ chip "span 6" ] }
                , { gridItem | span = Grid.Number 6, content = [ chip "span 6" ] }
                , { gridItem | span = Grid.Number 4, content = [ chip "span 4" ] }
                , { gridItem | span = Grid.Number 8, content = [ chip "span 8" ] }
                ]
            ]
        , demoRow "Collapsed (responsive overflow → suffix rest)"
            [ Grid.view
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
        [ demoRow "Basic (header · sider · content · footer)"
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
            ]
        , demoRow "Collapsed sider (right placement · bar trigger)"
            [ Element.el [ Element.width Element.fill ]
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
            ]
        , demoRow "Embedded (inset shell)"
            [ Element.el [ Element.width Element.fill ]
                (Layout.view theme
                    { layD | embedded = True }
                    [ LayoutHeader.view theme lhD [ Element.text "Embedded header" ]
                    , Layout.content theme layD [ Element.text "Embedded content" ]
                    ]
                )
            ]
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
        , demoRow "Rails only (left / top)"
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


watermarkSection : Element msg
watermarkSection =
    section "Watermark"
        "Naive UI's watermark — the `div.n-watermark-container` (the `--selectable` / `--global-rotate` / `--fullscreen` modifiers; bare overlay when fullscreen without global rotation) wrapping the content plus the tiled `div.n-watermark` overlay (`background-size` tiling, the `cross` offset pair, the `max(142vh, 142vw)` rotated positioning, `z-index` handoff between the two nodes). The tile itself is upstream's canvas `toDataURL` seam, rebuilt purely: an SVG of the canvas dimensions — one `<text>` per line with the full font stack — base64-encoded in-library; `image` is referenced directly instead of re-rasterised. No `--n-*` vars — the theme's single `fontFamily` feeds the tile's font fallback."
    <|
        [ demoRow "Basic · upstream demo tile (192×128, cross)"
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
        , demoRow "Two lines · centered · gaps · cross"
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
        , demoRow "Font stack · debug · not selectable"
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
        , demoRow "Global rotate (overflow-hidden container)"
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


codeSection : Element msg
codeSection =
    section "Code"
        "A code block over a caller-supplied highlight.js — highlighting is the caller's to own."
        [ demoRow "Basic (highlighted)"
            [ Code.view theme
                { codeD
                    | code = "const message = 'hello'"
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                }
                []
            ]
        , demoRow "Inline"
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
        , demoRow "Line numbers"
            [ Code.view theme
                { codeD
                    | code = "const a = 1\nconst b = 2\nconst c = 3"
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                    , showLineNumbers = True
                }
                []
            ]
        , demoRow "Word wrap (line numbers suppressed)"
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
        , demoRow "URI encoded"
            [ Code.view theme
                { codeD
                    | code = "const%20x%20%3D%201"
                    , uri = True
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                }
                []
            ]
        , demoRow "Trim off"
            [ Code.view theme
                { codeD
                    | code = "    const spaced = true    "
                    , trim = False
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                }
                []
            ]
        , demoRow "No hljs (plain text)"
            [ Code.view theme
                { codeD | code = "const plain = 1", language = Just "javascript" }
                []
            ]
        ]


equationSection : Element msg
equationSection =
    section "Equation"
        "KaTeX-rendered math via a caller-supplied renderToString closure (the component ships no KaTeX)."
        [ demoRow "Inline (fake katex)"
            [ Equation.view theme { equationD | value = "E = mc^2", katex = Just fakeKatex } ]
        , demoRow "Display wrapper"
            [ Equation.view theme { equationD | value = "x^2 + y^2 = z^2", katex = Just fakeKatexDisplay } ]
        , demoRow "No katex"
            [ Equation.view theme { equationD | value = "a^2 + b^2 = c^2" } ]
        ]
