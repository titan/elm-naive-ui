module Main exposing (main)

{-| Showcase page for elm-naive-ui: every component, rendered by the library
— and interactive in place.

Each family module (Sections/_.elm) owns its own Model/Msg/update loop
(caller-owned state per the port's contract) and exposes both a `sections`
function (the live family body — static rows plus live demo rows) and the
legacy per-section exports. This module is the harness: app state (one field
per family), docs-style page chrome (sticky top bar + sidebar nav + content
column) and the ordered body list. The former dedicated "Live · _" sections
are gone — their update loops and demo rows were merged into the per-family
modules verbatim (same #live-\* ids, same captions).

The sidebar is a real scrollspy: a `Time.every` tick re-reads every
section id (derived from the title by `Showcase.sectionId` — the same
function `Showcase.section` uses for the anchor ids) plus the viewport
offset, and the deepest section above the activation line becomes the
active nav item. Reads UPSERT into the model (a tick never wipes the map),
so the highlight survives page growth — the Log demo appends rows while you
scroll — and every section is re-measured live each tick. No ports — the
tasks are plain Elm.

-}

import Browser
import Browser.Dom
import Element exposing (Element)
import Element.Background as Bg
import Element.Border as Border
import Element.Font as Font
import Element.Lazy
import Html
import Html.Attributes as HA
import Html.Lazy
import NUI.Css as Css
import NUI.Typography as Typo
import Sections.Controls
import Sections.Data
import Sections.Display
import Sections.General
import Sections.Motion
import Sections.Nav
import Sections.Overlays
import Sections.Pickers
import Showcase exposing (sectionId, theme)
import Task exposing (Task)
import Time



-- APP STATE (the Live/* families own the interactive state; the chrome owns
-- the scrollspy's active section).


type alias Model =
    { general : Sections.General.Model
    , controls : Sections.Controls.Model
    , data : Sections.Data.Model
    , display : Sections.Display.Model
    , nav : Sections.Nav.Model
    , overlays : Sections.Overlays.Model
    , pickers : Sections.Pickers.Model
    , motion : Sections.Motion.Model
    , spyYs : List ( String, Float )
    , spyVp : Maybe Float
    , prevActive : Maybe String
    }


init : Model
init =
    { general = Sections.General.init
    , controls = Sections.Controls.init
    , data = Sections.Data.init
    , display = Sections.Display.init
    , nav = Sections.Nav.init
    , overlays = Sections.Overlays.init
    , pickers = Sections.Pickers.init
    , motion = Sections.Motion.init
    , spyYs = []
    , spyVp = Nothing
    , prevActive = Nothing
    }


type Msg
    = GeneralMsg Sections.General.Msg
    | ControlsMsg Sections.Controls.Msg
    | DataMsg Sections.Data.Msg
    | DisplayMsg Sections.Display.Msg
    | NavMsg Sections.Nav.Msg
    | OverlaysMsg Sections.Overlays.Msg
    | PickersMsg Sections.Pickers.Msg
    | MotionMsg Sections.Motion.Msg
    | SpyRequest
    | SpyY String Float
    | SpyVp Float
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GeneralMsg m ->
            ( { model | general = Sections.General.update m model.general }, Cmd.none )

        ControlsMsg m ->
            ( { model | controls = Sections.Controls.update m model.controls }, Cmd.none )

        DataMsg m ->
            ( { model | data = Sections.Data.update m model.data }, Cmd.none )

        DisplayMsg m ->
            ( { model | display = Sections.Display.update m model.display }, Cmd.none )

        NavMsg m ->
            ( { model | nav = Sections.Nav.update m model.nav }, Cmd.none )

        OverlaysMsg m ->
            ( { model | overlays = Sections.Overlays.update m model.overlays }, Cmd.none )

        PickersMsg m ->
            let
                ( nextPickers, pickersCmd ) =
                    Sections.Pickers.update m model.pickers
            in
            ( { model | pickers = nextPickers }, Cmd.map PickersMsg pickersCmd )

        MotionMsg m ->
            ( { model | motion = Sections.Motion.update m model.motion }, Cmd.none )

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
        [ Sub.map GeneralMsg (Sections.General.subscriptions model.general)
        , Sub.map ControlsMsg (Sections.Controls.subscriptions model.controls)
        , Sub.map DataMsg (Sections.Data.subscriptions model.data)
        , Sub.map DisplayMsg (Sections.Display.subscriptions model.display)
        , Sub.map NavMsg (Sections.Nav.subscriptions model.nav)
        , Sub.map OverlaysMsg (Sections.Overlays.subscriptions model.overlays)
        , Sub.map PickersMsg (Sections.Pickers.subscriptions model.pickers)
        , Sub.map MotionMsg (Sections.Motion.subscriptions model.motion)
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
        (hero :: lazyCssElement :: lazyChromeCss :: [ body model ])


{-| The 487KB stylesheet `<style>` node, lazily — a constant Html tree that
the per-msg full diff would otherwise re-compare every frame.
-}
lazyCssElement : Element msg
lazyCssElement =
    Element.html (Html.Lazy.lazy (\() -> Css.elementNode) ())


{-| Same for the showcase's chrome `<style>` node.
-}
lazyChromeCss : Element msg
lazyChromeCss =
    Element.html (Html.Lazy.lazy (\() -> Showcase.chromeCssNode) ())


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
section (87 entries, 1:1 — every section has exactly one sidebar entry).
Each family body comes from its module's `sections` (static rows + live
rows in place).

Each family is wrapped in `Element.Lazy.lazy2` against its own sub-model: a
message routed to one family (e.g. a ColorPicker drag inside Pickers)
re-renders only that family's slice, and the other seven diff as identical
lazy thunks — the page is ~26k DOM nodes, and re-diffing all of it per
mousemove made drag updates visibly laggy (~185ms/frame in a trace).

-}
body : Model -> Element Msg
body model =
    Element.column [ Element.width Element.fill, Element.spacing 0 ]
        [ lazyFamily GeneralMsg Sections.General.sections model.general
        , lazyFamily ControlsMsg Sections.Controls.sections model.controls
        , lazyFamily DataMsg Sections.Data.sections model.data
        , lazyFamily DisplayMsg Sections.Display.sections model.display
        , lazyFamily NavMsg Sections.Nav.sections model.nav
        , lazyFamily OverlaysMsg Sections.Overlays.sections model.overlays
        , lazyFamily PickersMsg Sections.Pickers.sections model.pickers
        , lazyFamily MotionMsg Sections.Motion.sections model.motion
        ]


{-| One family's slice, lazily. Every argument passed to
`Element.Lazy.lazy3` MUST be a stable reference, not an inline lambda or a
freshly-allocated tuple/record: the underlying virtual-dom thunk compares
refs (fn, args) by `===`, and anything rebuilt per render — a closure
captured in `body`, a tuple literal — makes the thunk miss every time and
the whole family re-diffs anyway. Top-level `familyNode`, the `Msg`
constructor (`GeneralMsg` etc.), the family's top-level `sections` and the
sub-model record are all stable across renders, so an unrelated family's
msg skips its entire vdom diff.
-}
lazyFamily :
    (fmsg -> Msg)
    -> (fmodel -> List (Element fmsg))
    -> fmodel
    -> Element Msg
lazyFamily toMsg familySections fmodel =
    Element.Lazy.lazy3 familyNode toMsg familySections fmodel


familyNode : (fmsg -> Msg) -> (fmodel -> List (Element fmsg)) -> fmodel -> Element Msg
familyNode toMsg familySections fmodel =
    Element.column [ Element.width Element.fill ] (List.map (Element.map toMsg) (familySections fmodel))
