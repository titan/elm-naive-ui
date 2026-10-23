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

The whole page is theme-switchable: `ThemeToggled` (the top bar's Light/Dark
button) flips `themeMode`, every family's `sections` and all the chrome
re-render under the derived `NUI.Theme` (`Showcase.paletteFor` restyles the
shared card/footer/code chrome).

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
import NUI.Button as Button
import NUI.Css as Css
import NUI.Theme as Theme
import NUI.Theme.Color as ThemeColor
import NUI.Types as T
import NUI.Typography as Typo
import Sections.Controls
import Sections.Data
import Sections.Display
import Sections.General
import Sections.Motion
import Sections.Nav
import Sections.Overlays
import Sections.Pickers
import Showcase exposing (paletteFor)
import Svg
import Svg.Attributes as SA
import Task exposing (Task)
import Time



-- APP STATE (the Live/* families own the interactive state; the chrome owns
-- the scrollspy's active section and the page-wide theme mode).


type alias Model =
    { themeMode : Theme.Mode
    , general : Sections.General.Model
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
    { themeMode = Theme.Light
    , general = Sections.General.init
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
    = ThemeToggled
    | GeneralMsg Sections.General.Msg
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
        ThemeToggled ->
            -- Spy state is deliberately untouched: the DOM is not re-laid
            -- out (same geometry), so the last reads stay valid.
            ( { model
                | themeMode =
                    case model.themeMode of
                        Theme.Light ->
                            Theme.Dark

                        Theme.Dark ->
                            Theme.Light
              }
            , Cmd.none
            )

        GeneralMsg m ->
            ( { model | general = Sections.General.update m model.general }, Cmd.none )

        ControlsMsg m ->
            let
                ( nextControls, controlsCmd ) =
                    Sections.Controls.update m model.controls
            in
            ( { model | controls = nextControls }, Cmd.map ControlsMsg controlsCmd )

        DataMsg m ->
            ( { model | data = Sections.Data.update m model.data }, Cmd.none )

        DisplayMsg m ->
            let
                ( nextDisplay, displayCmd ) =
                    Sections.Display.update m model.display
            in
            ( { model | display = nextDisplay }, Cmd.map DisplayMsg displayCmd )

        NavMsg m ->
            let
                ( nextNav, navCmd ) =
                    Sections.Nav.update m model.nav
            in
            ( { model | nav = nextNav }, Cmd.map NavMsg navCmd )

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



-- THEME


{-| The page theme — computed per render from the mode. Every component and
every chrome colour below renders with it; `ThemeToggled` just flips the
mode.
-}
modelTheme : Model -> Theme.Theme
modelTheme model =
    Theme.withMode model.themeMode Theme.default


{-| The memoized chrome `<style>` node — keyed on the mode alone, so the
per-msg diff skips re-comparing the text child until the theme flips.
-}
chromeNode : Theme.Mode -> Html.Html msg
chromeNode mode =
    Showcase.chromeCssNode (Theme.withMode mode Theme.default)


{-| Parses the palette's `#rgb`/`#rrggbb`/`rgb()`/`rgba()` strings for
elm-ui's `Bg.color`/`Font.color` attributes — via the library's own parser
(the same one that derives hover colours from these strings inside the
components). All inputs come from `Showcase.paletteFor`.
-}
color : String -> Element.Color
color raw =
    case ThemeColor.parse raw of
        Just c ->
            Element.fromRgb
                { red = c.r / 255
                , green = c.g / 255
                , blue = c.b / 255
                , alpha = c.a
                }

        Nothing ->
            Element.rgb 0 0 0



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
        |> List.map Showcase.sectionId



-- PAGE CHROME


typ : Typo.Options msg
typ =
    Typo.defaults


page : Model -> Element Msg
page model =
    let
        p =
            paletteFor (modelTheme model)
    in
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Bg.color (color p.bg)
        , Font.family [ Font.typeface "system-ui", Font.sansSerif ]
        , Font.color (color p.text)
        ]
        (Element.column
            [ Element.width Element.fill ]
            [ topBar p.accent model.themeMode
            , Element.row
                [ Element.width Element.fill
                , Element.alignTop
                ]
                [ sidebar p (sectionActive (activeSection model.spyYs model.spyVp))
                , content p model
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


topBar : String -> Theme.Mode -> Element Msg
topBar accent mode =
    let
        p =
            paletteFor (Theme.withMode mode Theme.default)
    in
    Element.el
        [ Element.width Element.fill
        , Element.height (Element.px 60)
        , Bg.color (color p.surface)
        , Element.htmlAttribute
            (HA.attribute
                "style"
                ("position:sticky;top:0;z-index:100;border-bottom:1px solid " ++ p.border)
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
                    , Bg.color (color accent)
                    ]
                    Element.none
                , Element.el
                    [ Font.size 17, Font.bold, Element.centerY ]
                    (Element.text "elm-naive-ui")
                ]
            , Element.el
                [ Element.centerY
                , Font.size 12
                , Font.color (color p.textMuted)
                ]
                (Element.text "naive-ui v2.45.3 · 100 components · Elm port")
            , Element.el
                [ Element.alignRight, Element.centerY ]
                (Button.view (Theme.withMode mode Theme.default)
                    { btnD | size = T.Small, onPress = Just ThemeToggled, icon = Just (themeGlyph mode) }
                    [ Element.text (themeToggleLabel mode) ]
                )
            ]
        )


{-| The `Button.defaults` baseline for the toggle, at top level so the record
literal is a stable reference (not that it needs to be — it is applied once
per topBar render — but it keeps the view lean).
-}
btnD : Button.Options Msg
btnD =
    Button.defaults


themeToggleLabel : Theme.Mode -> String
themeToggleLabel mode =
    case mode of
        Theme.Light ->
            "Dark mode"

        Theme.Dark ->
            "Light mode"


{-| A small sun/moon glyph, inline SVG stroke currentColor so it inherits the
button's text colour (theme-aware for free).
-}
themeGlyph : Theme.Mode -> Element msg
themeGlyph mode =
    Element.html
        (Svg.svg
            [ SA.viewBox "0 0 16 16"
            , SA.width "12"
            , SA.height "12"
            , HA.attribute "aria-hidden" "true"
            ]
            [ Svg.path
                [ SA.fill "none"
                , SA.stroke "currentColor"
                , SA.strokeWidth "1.5"
                , SA.strokeLinecap "round"
                , SA.strokeLinejoin "round"
                , SA.d
                    (case mode of
                        Theme.Light ->
                            -- moon (click → dark)
                            "M13.5 9.5A6 6 0 0 1 6.5 2.5a6 6 0 1 0 7 7z"

                        Theme.Dark ->
                            -- sun (click → light)
                            "M8 11.5A3.5 3.5 0 1 0 8 4.5a3.5 3.5 0 0 0 0 7zM8 1.5v1.4M8 13.1v1.4M1.5 8h1.4M13.1 8h1.4M3.4 3.4l1 1M11.6 11.6l1 1M12.6 3.4l-1 1M4.4 11.6l-1 1"
                    )
                ]
                []
            ]
        )


{-| The sticky sidebar: family groups of section links, internally scrollable,
active link in the primary colour.
-}
sidebar : Showcase.Palette -> (String -> Bool) -> Element msg
sidebar p isActive =
    Element.el
        [ Element.width (Element.px 224)
        , Element.alignTop
        , Element.htmlAttribute (HA.id "nui-sidebar")
        , Element.htmlAttribute
            (HA.attribute
                "style"
                ("position:sticky;top:60px;height:calc(100vh - 60px);overflow-y:auto;border-right:1px solid " ++ p.border)
            )
        ]
        (Element.column
            [ Element.width Element.fill
            , Element.paddingXY 14 24
            , Element.spacing 3
            ]
            (List.concatMap (navGroup p isActive) navGroups)
        )


navGroup : Showcase.Palette -> (String -> Bool) -> ( String, List String ) -> List (Element msg)
navGroup p isActive ( group, titles ) =
    Element.el
        [ Element.paddingEach { top = 14, bottom = 4, left = 10, right = 0 }
        , Font.size 11
        , Font.bold
        , Font.color (color p.textFaint)
        , Element.htmlAttribute
            (HA.attribute
                "style"
                ("position:sticky;top:0;z-index:1;background:" ++ p.bg)
            )
        ]
        (Element.text (String.toUpper group))
        :: List.map (navItem p isActive) titles


navItem : Showcase.Palette -> (String -> Bool) -> String -> Element msg
navItem p isActive title =
    let
        id =
            Showcase.sectionId title

        accentColor =
            color p.accent

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
                Element.htmlAttribute (HA.attribute "style" ("background:" ++ p.activeBg))
                    :: Font.color accentColor
                    :: base

            else
                Font.color (color p.navIdle)
                    :: base
    in
    Element.link attrs
        { url = "#" ++ id
        , label = Element.el [] (Element.text title)
        }


content : Showcase.Palette -> Model -> Element Msg
content p model =
    Element.column
        [ Element.width (Element.maximum 1080 Element.fill)
        , Element.alignTop
        , Element.paddingEach { top = 44, bottom = 120, left = 44, right = 36 }
        , Element.spacing 48
        ]
        (hero (modelTheme model) :: lazyCssElement :: lazyChromeCss model.themeMode :: [ body model ])


{-| The 487KB stylesheet `<style>` node, lazily — a constant Html tree that
the per-msg full diff would otherwise re-compare every frame.
-}
lazyCssElement : Element msg
lazyCssElement =
    Element.html (Html.Lazy.lazy (\() -> Css.elementNode) ())


{-| Same for the showcase's chrome `<style>` node — keyed on the mode, so it
re-emits only when the theme flips.
-}
lazyChromeCss : Theme.Mode -> Element msg
lazyChromeCss mode =
    Element.html (Html.Lazy.lazy chromeNode mode)


hero : Theme.Theme -> Element msg
hero t =
    Element.column [ Element.spacing 8 ]
        [ Typo.h1 t typ [ Element.text "Naive UI for Elm" ]
        , Typo.text t
            { typ | depth = Just 3 }
            [ Element.text "Naive UI components built on elm-ui — Naive UI's own CSS, driven by a typed Elm theme." ]
        ]


{-| The ordered body — EXACTLY `navGroups` order (family by family, title by
title), so the sidebar reads top-to-bottom as the page scrolls. The order is
load-bearing for navigation: keep the two lists in sync when adding a
section (87 entries, 1:1 — every section has exactly one sidebar entry).
Each family body comes from its module's `sections` (static rows + live
rows in place).

Each family is wrapped in `Element.Lazy.lazy` against its own sub-model: a
message routed to one family (e.g. a ColorPicker drag inside Pickers)
re-renders only that family's slice, and the other seven diff as identical
lazy thunks — the page is ~26k DOM nodes, and re-diffing all of it per
mousemove made drag updates visibly laggy (~185ms/frame in a trace).

-}
body : Model -> Element Msg
body model =
    Element.column [ Element.width Element.fill, Element.spacing 0 ]
        [ lazyFamily GeneralMsg Sections.General.sections model.themeMode model.general
        , lazyFamily ControlsMsg Sections.Controls.sections model.themeMode model.controls
        , lazyFamily DataMsg Sections.Data.sections model.themeMode model.data
        , lazyFamily DisplayMsg Sections.Display.sections model.themeMode model.display
        , lazyFamily NavMsg Sections.Nav.sections model.themeMode model.nav
        , lazyFamily OverlaysMsg Sections.Overlays.sections model.themeMode model.overlays
        , lazyFamily PickersMsg Sections.Pickers.sections model.themeMode model.pickers
        , lazyFamily MotionMsg Sections.Motion.sections model.themeMode model.motion
        ]


{-| One family's slice, lazily. Every argument passed to
`Element.Lazy.lazy4` MUST be a stable reference, not an inline lambda or a
freshly-allocated tuple/record: the underlying virtual-dom thunk compares
refs (fn, args) by `===`, and anything rebuilt per render — a closure
captured in `body`, a tuple literal — makes the thunk miss every time and
the whole family re-diffs anyway. Top-level `familyNode`, the `Msg`
constructor (`GeneralMsg` etc.), the family's top-level `sections`, the
mode (a variant constructor value) and the sub-model record are all stable
across renders, so an unrelated family's msg skips its entire vdom diff.
The `Theme` itself is derived from the mode INSIDE the node — a fresh
record per render would break the ref comparison.
-}
lazyFamily :
    (fmsg -> Msg)
    -> (fmodel -> Theme.Theme -> List (Element fmsg))
    -> Theme.Mode
    -> fmodel
    -> Element Msg
lazyFamily toMsg familySections mode fmodel =
    Element.Lazy.lazy4 familyNode toMsg familySections mode fmodel


familyNode :
    (fmsg -> Msg)
    -> (fmodel -> Theme.Theme -> List (Element fmsg))
    -> Theme.Mode
    -> fmodel
    -> Element Msg
familyNode toMsg familySections mode fmodel =
    Element.column
        [ Element.width Element.fill ]
        (List.map (Element.map toMsg) (familySections fmodel (Theme.withMode mode Theme.default)))
