module Main exposing (main)

{-| Showcase page for elm-naive-ui: every component, rendered by the library.

The 87 static sections live in the Sections/\* family modules (moved verbatim
from here — that surface feeds the check-dom gate, so it must keep rendering
every root). Interactivity lives in the Live/\* family modules (own
Model/Msg/update each, spliced in via Element.map) — one real update loop per
component family. This module is the harness: app state, docs-style page
chrome (sticky top bar + sidebar nav + content column) and the ordered body
list.

The sidebar is a real scrollspy: a `Time.every` tick re-reads every
section id (derived from the title by `Showcase.sectionId` — the same
function `Showcase.section` uses for the anchor ids) plus the viewport
offset, and the deepest section above the activation line becomes the
active nav item. Reads UPSERT into the model (a tick never wipes the map),
so the highlight survives page growth — the Live·Log demo appends rows
while you scroll — and every section is re-measured live each tick. No
ports — the tasks are plain Elm.

-}

import Browser
import Browser.Dom
import Element exposing (Element)
import Element.Background as Bg
import Element.Border as Border
import Element.Font as Font
import Html.Attributes as HA
import Live.Controls
import Live.Data
import Live.Motion
import Live.Nav
import Live.Overlays
import Live.Pickers
import NUI.Css as Css
import NUI.Typography as Typo
import Sections.Controls exposing (buttonSection, inputNumberSection, inputOtpSection, inputSection, rateSection, selectionSection, sliderSection)
import Sections.Data exposing (calendarSection, dataTableSection, dynamicInputSection, dynamicTagsSection, imagePreviewSection, imageSection, tableSection, transferSection, treeSection, uploadSection)
import Sections.Display exposing (affixSection, breadcrumbSection, codeSection, descriptionsSection, equationSection, flexSection, floatButtonGroupSection, floatButtonSection, gridSection, heatmapSection, layoutSection, listSection, pageHeaderSection, qrCodeSection, scrollbarSection, timelineSection, watermarkSection)
import Sections.General exposing (alertSection, avatarSection, badgeSection, cardSection, dividerSection, ellipsisSection, emptySection, gradientTextSection, highlightSection, iconSection, resultSection, rtlSection, spaceSection, statisticSection, tagSection, themeSection, thingSection, typographySection)
import Sections.Motion exposing (carouselSection, countdownSection, logSection, marqueeSection, numberAnimationSection, progressSection, skeletonSection, spinSection)
import Sections.Nav exposing (anchorSection, backTopSection, collapseSection, menuSection, paginationSection, splitSection, stepsSection, tabsSection)
import Sections.Overlays exposing (dialogSection, drawerSection, dropdownSection, loadingBarSection, messageSection, modalSection, notificationSection, popconfirmSection, popoverSection, tooltipSection)
import Sections.Pickers exposing (autoCompleteSection, cascaderSection, colorPickerSection, datePickerSection, mentionSection, popselectSection, selectSection, timePickerSection, treeSelectSection)
import Showcase exposing (chromeCss, section, sectionId, theme)
import Task exposing (Task)
import Time



-- APP STATE (the Live/* families own the interactive state; the chrome owns
-- the scrollspy's active section).


type alias Model =
    { controls : Live.Controls.Model
    , pickers : Live.Pickers.Model
    , overlays : Live.Overlays.Model
    , nav : Live.Nav.Model
    , data : Live.Data.Model
    , motion : Live.Motion.Model
    , spyYs : List ( String, Float )
    , spyVp : Maybe Float
    , prevActive : Maybe String
    }


init : Model
init =
    { controls = Live.Controls.init
    , pickers = Live.Pickers.init
    , overlays = Live.Overlays.init
    , nav = Live.Nav.init
    , data = Live.Data.init
    , motion = Live.Motion.init
    , spyYs = []
    , spyVp = Nothing
    , prevActive = Nothing
    }


type Msg
    = ControlsMsg Live.Controls.Msg
    | PickersMsg Live.Pickers.Msg
    | OverlaysMsg Live.Overlays.Msg
    | NavMsg Live.Nav.Msg
    | DataMsg Live.Data.Msg
    | MotionMsg Live.Motion.Msg
    | SpyRequest
    | SpyY String Float
    | SpyVp Float
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ControlsMsg m ->
            ( { model | controls = Live.Controls.update m model.controls }, Cmd.none )

        PickersMsg m ->
            let
                ( nextPickers, pickersCmd ) =
                    Live.Pickers.update m model.pickers
            in
            ( { model | pickers = nextPickers }, Cmd.map PickersMsg pickersCmd )

        OverlaysMsg m ->
            ( { model | overlays = Live.Overlays.update m model.overlays }, Cmd.none )

        NavMsg m ->
            ( { model | nav = Live.Nav.update m model.nav }, Cmd.none )

        DataMsg m ->
            ( { model | data = Live.Data.update m model.data }, Cmd.none )

        MotionMsg m ->
            ( { model | motion = Live.Motion.update m model.motion }, Cmd.none )

        SpyRequest ->
            -- No wipe: the previous tick's map stays live while the new
            -- reads are in flight (one rAF later), and each SpyY upserts its
            -- own entry — the highlight never blanks and page growth (the
            -- Live·Log demo appends rows on scroll) is absorbed by the next
            -- tick's fresh measurement.
            ( model
            , Cmd.batch (spyViewport :: List.map spySample navSectionIds)
            )

        SpyY id y ->
            withSpy
                { model
                    | spyYs =
                        ( id, y )
                            :: List.filter (Tuple.first >> (/=) id) model.spyYs
                }

        SpyVp vp ->
            withSpy { model | spyVp = Just vp }

        NoOp ->
            ( model, Cmd.none )


{-| One parallel DOM read per section (each is its own rAF-gated task — a
`Task.sequence` of them would need one frame per link, i.e. 93 frames per
tick; batched, every pending read resolves in a single frame and Elm folds
the 93 messages into one render). `Browser.Dom.getElement`'s `element.y` is
measured scroll-independent (document y), so the viewport offset rides
alongside and the view subtracts it.
-}
spySample : String -> Cmd Msg
spySample id =
    Browser.Dom.getElement id
        |> Task.map (.element >> .y)
        |> Task.onError (\_ -> Task.succeed (1 / 0))
        |> Task.perform (SpyY id)


spyViewport : Cmd Msg
spyViewport =
    Browser.Dom.getViewport
        |> Task.map .viewport
        |> Task.map .y
        |> Task.perform SpyVp


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map ControlsMsg (Live.Controls.subscriptions model.controls)
        , Sub.map PickersMsg (Live.Pickers.subscriptions model.pickers)
        , Sub.map OverlaysMsg (Live.Overlays.subscriptions model.overlays)
        , Sub.map NavMsg (Live.Nav.subscriptions model.nav)
        , Sub.map DataMsg (Live.Data.subscriptions model.data)
        , Sub.map MotionMsg (Live.Motion.subscriptions model.motion)
        , Time.every 350 (\_ -> SpyRequest)
        ]


main : Program () Model Msg
main =
    Browser.element
        { init =
            \() ->
                ( init
                , Cmd.batch (List.map spySample navSectionIds)
                )
        , view = \model -> Css.layout [] (page model)
        , update = update
        , subscriptions = subscriptions
        }



-- NAV CONFIG (section titles are the single source of truth: Showcase.section
-- derives the anchor ids from them, the sidebar derives its hrefs the same way)


navGroups : List ( String, List String )
navGroups =
    [ ( "General"
      , [ "Typography"
        , "Tag"
        , "Alert"
        , "Divider"
        , "Avatar"
        , "Card"
        , "Space"
        , "Badge"
        , "Empty"
        , "Result"
        , "Gradient Text"
        , "Statistic"
        , "Thing"
        , "Ellipsis"
        , "Icon"
        , "Highlight"
        , "RTL"
        , "Theme"
        ]
      )
    , ( "Controls"
      , [ "Button"
        , "Input"
        , "Input OTP"
        , "Input Number"
        , "Checkbox · Switch · Radio"
        , "Rate"
        , "Slider"
        ]
      )
    , ( "Data"
      , [ "Dynamic Tags"
        , "Calendar"
        , "DynamicInput"
        , "Table"
        , "Tree"
        , "Image"
        , "Image Preview & Group"
        , "Data Table"
        , "Transfer"
        , "Upload"
        ]
      )
    , ( "Display"
      , [ "Breadcrumb"
        , "Timeline"
        , "List"
        , "Page Header"
        , "Affix"
        , "Flex"
        , "Grid"
        , "QrCode"
        , "Float Button"
        , "Layout"
        , "Float Button Group"
        , "Heatmap"
        , "Descriptions"
        , "Scrollbar"
        , "Watermark"
        , "Code"
        , "Equation"
        ]
      )
    , ( "Nav"
      , [ "Pagination"
        , "Split"
        , "Steps"
        , "BackTop"
        , "Collapse"
        , "Tabs"
        , "Menu"
        , "Anchor"
        ]
      )
    , ( "Overlays"
      , [ "LoadingBar"
        , "Popover"
        , "Popconfirm"
        , "Tooltip"
        , "Dropdown"
        , "Message"
        , "Notification"
        , "Modal"
        , "Drawer"
        , "Dialog"
        ]
      )
    , ( "Pickers"
      , [ "Select"
        , "Popselect"
        , "Cascader"
        , "TreeSelect"
        , "AutoComplete"
        , "Mention"
        , "DatePicker"
        , "TimePicker"
        , "ColorPicker"
        ]
      )
    , ( "Motion"
      , [ "Progress"
        , "Skeleton"
        , "Spin"
        , "Marquee"
        , "Countdown"
        , "Number Animation"
        , "Carousel"
        , "Log"
        ]
      )
    , ( "Live"
      , [ "Live · Controls"
        , "Live · Pickers"
        , "Live · Overlays"
        , "Live · Nav"
        , "Live · Data"
        , "Live · Motion"
        ]
      )
    ]


navSectionIds : List String
navSectionIds =
    navGroups
        |> List.concatMap Tuple.second
        |> List.map sectionId



-- PAGE CHROME


typ : Typo.Options msg
typ =
    Typo.defaults


accentColor : Element.Color
accentColor =
    Element.rgb255 0x18 0xA0 0x58


page : Model -> Element Msg
page model =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Bg.color (Element.rgb 1 1 1)
        , Font.family [ Font.typeface "system-ui", Font.sansSerif ]
        , Font.color (Element.rgb255 0x33 0x36 0x39)
        ]
        (Element.column
            [ Element.width Element.fill ]
            [ topBar
            , Element.row
                [ Element.width Element.fill
                , Element.alignTop
                ]
                [ sidebar (sectionActive (activeSection model.spyYs model.spyVp))
                , content model
                ]
            ]
        )


{-| The deepest section whose top has crossed the activation line — the one
the reader is looking at. The line sits 300px below the viewport top: past
the 60px sticky bar and into the reading zone, so a section whose heading
is well inside the frame is active (a tighter threshold left a visible
heading still highlighting its predecessor). `Nothing` only before the
very first reads land.
-}
activeSection : List ( String, Float ) -> Maybe Float -> Maybe String
activeSection ys vp =
    case vp of
        Nothing ->
            Nothing

        Just v ->
            List.foldl
                (\( id, y ) best ->
                    let
                        rel =
                            y - v
                    in
                    if rel <= 300 && (best == Nothing || (Maybe.map Tuple.second best |> Maybe.withDefault 0) <= rel) then
                        Just ( id, rel )

                    else
                        best
                )
                Nothing
                ys
                |> Maybe.map Tuple.first


{-| True when this section id is the scrollspy's active one.
-}
sectionActive : Maybe String -> String -> Bool
sectionActive active id =
    active == Just id


{-| Recompute the active section and, when it changed, scroll the sidebar rail
so the active link is on screen (the rail is internally scrollable — without
this, mid-page sections would highlight off-screen). The rail/link reads run
in the same frame, so the sticky rail's scroll-dependent offset cancels out.
-}
withSpy : Model -> ( Model, Cmd Msg )
withSpy model =
    let
        active =
            activeSection model.spyYs model.spyVp
    in
    if active == model.prevActive then
        ( model, Cmd.none )

    else
        ( { model | prevActive = active }, scrollSidebar active )


{-| Bring the active nav link ~120px below the rail's top: read the link's and
rail's document y in one batch (their shared sticky offset cancels in the
difference), add the rail's current scroll, then set the rail's scrollTop.
-}
scrollSidebar : Maybe String -> Cmd Msg
scrollSidebar maybeActive =
    case maybeActive of
        Nothing ->
            Cmd.none

        Just id ->
            Task.attempt (\_ -> NoOp)
                (Task.map3
                    (\linkY railY rail -> linkY - railY + rail.viewport.y - 120)
                    (elemY ("navlink-" ++ id))
                    (elemY "nui-sidebar")
                    (Browser.Dom.getViewportOf "nui-sidebar")
                    |> Task.andThen
                        (\top -> Browser.Dom.setViewportOf "nui-sidebar" 0 (max 0 top))
                )


elemY : String -> Task Browser.Dom.Error Float
elemY domId =
    Browser.Dom.getElement domId
        |> Task.map (.element >> .y)


topBar : Element msg
topBar =
    Element.el
        [ Element.width Element.fill
        , Element.height (Element.px 60)
        , Bg.color (Element.rgb 1 1 1)
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:sticky;top:0;z-index:100;border-bottom:1px solid #efeff5"
            )
        ]
        (Element.row
            [ Element.width Element.fill
            , Element.height Element.fill
            , Element.paddingXY 28 0
            , Element.spacing 12
            ]
            [ Element.row [ Element.spacing 10, Element.centerY ]
                [ Element.el
                    [ Element.width (Element.px 10)
                    , Element.height (Element.px 10)
                    , Border.rounded 5
                    , Bg.color accentColor
                    ]
                    Element.none
                , Element.el
                    [ Font.size 17, Font.bold, Element.centerY ]
                    (Element.text "elm-naive-ui")
                ]
            , Element.el
                [ Element.centerY
                , Font.size 12
                , Font.color (Element.rgb255 0x7C 0x80 0x87)
                ]
                (Element.text "naive-ui v2.45.3 · 100 components · Elm port")
            ]
        )


{-| The sticky sidebar: family groups of section links, internally scrollable,
active link in the primary colour.
-}
sidebar : (String -> Bool) -> Element msg
sidebar isActive =
    Element.el
        [ Element.width (Element.px 224)
        , Element.alignTop
        , Element.htmlAttribute (HA.id "nui-sidebar")
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:sticky;top:60px;height:calc(100vh - 60px);overflow-y:auto;border-right:1px solid #efeff5"
            )
        ]
        (Element.column
            [ Element.width Element.fill
            , Element.paddingXY 14 24
            , Element.spacing 3
            ]
            (List.concatMap (navGroup isActive) navGroups)
        )


navGroup : (String -> Bool) -> ( String, List String ) -> List (Element msg)
navGroup isActive ( group, titles ) =
    Element.el
        [ Element.paddingEach { top = 14, bottom = 4, left = 10, right = 0 }
        , Font.size 11
        , Font.bold
        , Font.color (Element.rgb255 0x90 0x93 0x99)
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:sticky;top:0;z-index:1;background:#fff"
            )
        ]
        (Element.text (String.toUpper group))
        :: List.map (navItem isActive) titles


navItem : (String -> Bool) -> String -> Element msg
navItem isActive title =
    let
        id =
            sectionId title

        base =
            [ Element.width Element.fill
            , Element.htmlAttribute (HA.id ("navlink-" ++ id))
            , Element.paddingXY 10 4
            , Border.rounded 3
            , Font.size 13
            , Element.mouseOver [ Font.color accentColor ]
            ]

        attrs =
            if isActive id then
                Element.htmlAttribute (HA.attribute "style" "background:#f0faf5")
                    :: Font.color accentColor
                    :: base

            else
                Font.color (Element.rgb255 0x4C 0x50 0x56)
                    :: base
    in
    Element.link attrs
        { url = "#" ++ id
        , label = Element.el [] (Element.text title)
        }


content : Model -> Element Msg
content model =
    Element.column
        [ Element.width (Element.maximum 1080 Element.fill)
        , Element.alignTop
        , Element.paddingEach { top = 44, bottom = 120, left = 44, right = 36 }
        , Element.spacing 48
        ]
        (hero :: (Css.element :: chromeCss :: body model))


hero : Element msg
hero =
    Element.column [ Element.spacing 8 ]
        [ Typo.h1 theme typ [ Element.text "Naive UI for Elm" ]
        , Typo.text theme
            { typ | depth = Just 3 }
            [ Element.text "Naive UI components built on elm-ui — Naive UI's own CSS, driven by a typed Elm theme." ]
        ]


{-| The ordered body — EXACTLY `navGroups` order (family by family, title by
title), so the sidebar reads top-to-bottom as the page scrolls. The order is
load-bearing for navigation: keep the two lists in sync when adding a
section (93 entries, 1:1 — every section has exactly one sidebar entry).
-}
body : Model -> List (Element Msg)
body model =
    [ typographySection
    , tagSection
    , alertSection
    , dividerSection
    , avatarSection
    , cardSection
    , spaceSection
    , badgeSection
    , emptySection
    , resultSection
    , gradientTextSection
    , statisticSection
    , thingSection
    , ellipsisSection
    , iconSection
    , highlightSection
    , rtlSection
    , themeSection
    , buttonSection
    , inputSection
    , inputOtpSection
    , inputNumberSection
    , selectionSection
    , rateSection
    , sliderSection
    , dynamicTagsSection
    , calendarSection
    , dynamicInputSection
    , tableSection
    , treeSection
    , imageSection
    , imagePreviewSection
    , dataTableSection
    , transferSection
    , uploadSection
    , breadcrumbSection
    , timelineSection
    , listSection
    , pageHeaderSection
    , affixSection
    , flexSection
    , gridSection
    , qrCodeSection
    , floatButtonSection
    , layoutSection
    , floatButtonGroupSection
    , heatmapSection
    , descriptionsSection
    , scrollbarSection
    , watermarkSection
    , codeSection
    , equationSection
    , paginationSection
    , splitSection
    , stepsSection
    , backTopSection
    , collapseSection
    , tabsSection
    , menuSection
    , anchorSection
    , loadingBarSection
    , popoverSection
    , popconfirmSection
    , tooltipSection
    , dropdownSection
    , messageSection
    , notificationSection
    , modalSection
    , drawerSection
    , dialogSection
    , selectSection
    , popselectSection
    , cascaderSection
    , treeSelectSection
    , autoCompleteSection
    , mentionSection
    , datePickerSection
    , timePickerSection
    , colorPickerSection
    , progressSection
    , skeletonSection
    , spinSection
    , marqueeSection
    , countdownSection
    , numberAnimationSection
    , carouselSection
    , logSection
    , section "Live · Controls"
        "A real update loop: Button, Input, InputNumber, Switch, Checkbox, Radio, Rate, Slider, InputOtp — state in the model, every channel one Msg."
        [ Element.map ControlsMsg (Live.Controls.view theme model.controls) ]
    , section "Live · Pickers"
        "A real update loop: Select, Popselect, Cascader, TreeSelect, AutoComplete, Mention, DatePicker, TimePicker, ColorPicker — open state and values in the model."
        [ Element.map PickersMsg (Live.Pickers.view theme model.pickers) ]
    , section "Live · Overlays"
        "A real update loop: Dropdown, Popover, Tooltip, Popconfirm, Modal, Drawer, Dialog, Message, Notification, LoadingBar — open/queue state in the model."
        [ Element.map OverlaysMsg (Live.Overlays.view theme model.overlays) ]
    , section "Live · Nav"
        "A real update loop: Tabs, Collapse, Menu, Pagination, Steps, Anchor, BackTop, Split — active/expanded state in the model."
        [ Element.map NavMsg (Live.Nav.view theme model.nav) ]
    , section "Live · Data"
        "A real update loop: Table, DataTable, Tree, Transfer, Calendar, Image preview, Upload, DynamicInput, DynamicTags, Form — selection and list state in the model."
        [ Element.map DataMsg (Live.Data.view theme model.data) ]
    , section "Live · Motion"
        "A real update loop: Carousel (autoplay clock + arrows + drag), Log (scroll load), Countdown, NumberAnimation, Progress, Spin, Skeleton, Marquee — time-driven state."
        [ Element.map MotionMsg (Live.Motion.view theme model.motion) ]
    ]
