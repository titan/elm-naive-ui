module Main exposing (main)

{-| Showcase page for elm-naive-ui: every component, rendered by the library.

The 87 static sections live in the Sections/\* family modules (moved verbatim
from here — that surface feeds the check-dom gate, so it must keep rendering
every root). Interactivity lives in the Live/\* family modules (own
Model/Msg/update each, spliced in via Element.map) — one real update loop per
component family. This module is only the harness: app state, page chrome and
the ordered body list.

-}

import Browser
import Element exposing (Element)
import Element.Background as Bg
import Element.Font as Font
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
import Showcase exposing (section, theme)



-- APP STATE (the Live/* families own the interactive state)


type alias Model =
    { controls : Live.Controls.Model
    , pickers : Live.Pickers.Model
    , overlays : Live.Overlays.Model
    , nav : Live.Nav.Model
    , data : Live.Data.Model
    , motion : Live.Motion.Model
    }


init : Model
init =
    { controls = Live.Controls.init
    , pickers = Live.Pickers.init
    , overlays = Live.Overlays.init
    , nav = Live.Nav.init
    , data = Live.Data.init
    , motion = Live.Motion.init
    }


type Msg
    = ControlsMsg Live.Controls.Msg
    | PickersMsg Live.Pickers.Msg
    | OverlaysMsg Live.Overlays.Msg
    | NavMsg Live.Nav.Msg
    | DataMsg Live.Data.Msg
    | MotionMsg Live.Motion.Msg


update : Msg -> Model -> Model
update msg model =
    case msg of
        ControlsMsg m ->
            { model | controls = Live.Controls.update m model.controls }

        PickersMsg m ->
            { model | pickers = Live.Pickers.update m model.pickers }

        OverlaysMsg m ->
            { model | overlays = Live.Overlays.update m model.overlays }

        NavMsg m ->
            { model | nav = Live.Nav.update m model.nav }

        DataMsg m ->
            { model | data = Live.Data.update m model.data }

        MotionMsg m ->
            { model | motion = Live.Motion.update m model.motion }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map ControlsMsg (Live.Controls.subscriptions model.controls)
        , Sub.map PickersMsg (Live.Pickers.subscriptions model.pickers)
        , Sub.map OverlaysMsg (Live.Overlays.subscriptions model.overlays)
        , Sub.map NavMsg (Live.Nav.subscriptions model.nav)
        , Sub.map DataMsg (Live.Data.subscriptions model.data)
        , Sub.map MotionMsg (Live.Motion.subscriptions model.motion)
        ]



-- PAGE


main : Program () Model Msg
main =
    Browser.element
        { init = \() -> ( init, Cmd.none )
        , view = \model -> Css.layout [] (page model)
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscriptions
        }


typ : Typo.Options msg
typ =
    Typo.defaults


page : Model -> Element Msg
page model =
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
                (Css.element :: header ++ body model)
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


body : Model -> List (Element Msg)
body model =
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
    , dataTableSection
    , anchorSection
    , transferSection
    , treeSelectSection
    , timePickerSection
    , datePickerSection
    , colorPickerSection
    , uploadSection
    , carouselSection
    , codeSection
    , equationSection
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
    , rtlSection
    , themeSection
    ]
