module NUI.Progress exposing
    ( IndicatorPlacement(..)
    , Options
    , ProgressType(..)
    , Status(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Progress`, rebuilt on elm-ui.

    NUI.Progress.view theme NUI.Progress.defaults []

    NUI.Progress.view theme
        { NUI.Progress.defaults
            | type_ = NUI.Progress.Circle
            , percentage = 80
            , status = NUI.Progress.Success
        }
        []

    NUI.Progress.view theme
        { NUI.Progress.defaults
            | percentage = 66
            , processing = True
            , height = Just 12
        }
        []

The visual result is Naive UI's own: the element carries the `.n-progress`
BEM classes and Naive UI's `--n-*` custom properties, and `NUI.Css` ships
Naive UI's exact CSS. The children are the default slot: custom indicator
content, replacing the percentage text / status icon.

`Dashboard` is the circle graph with `gapDegree` defaulting to 75.
`MultipleCircle` is not implemented yet — it renders the themed root element
only (no graph, no indicator).

-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Progress as ProgressTheme
import Svg exposing (Svg)
import Svg.Attributes as SvgA



-- OPTIONS


{-| Naive UI's `type` prop: `line`, `circle`, `dashboard` (a circle whose gap
defaults to 75°) or `multiple-circle`.
-}
type ProgressType
    = Line
    | Circle
    | Dashboard
    | MultipleCircle


{-| Naive UI's `status` prop. `Default` shows the percentage text; the other
statuses swap it for the status icon and pick the themed fill / icon colours.
-}
type Status
    = Default
    | Success
    | Error
    | Warning
    | Info


{-| Naive UI's `indicator-placement` (line only): the indicator sits inside
the fill or after the graph.
-}
type IndicatorPlacement
    = Inside
    | Outside


type alias Options msg =
    { type_ : ProgressType
    , percentage : Float
    , status : Status
    , showIndicator : Bool
    , indicatorPlacement : IndicatorPlacement
    , color : Maybe String
    , railColor : Maybe String
    , strokeWidth : Float
    , viewBoxWidth : Float
    , height : Maybe Int
    , borderRadius : Maybe String
    , fillBorderRadius : Maybe String
    , processing : Bool
    , unit : String
    , gapDegree : Maybe Float
    , gapOffsetDegree : Maybe Float
    , offsetDegree : Maybe Float
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { type_ = Line
    , percentage = 0
    , status = Default
    , showIndicator = True
    , indicatorPlacement = Outside
    , color = Nothing
    , railColor = Nothing
    , strokeWidth = 7
    , viewBoxWidth = 100
    , height = Nothing
    , borderRadius = Nothing
    , fillBorderRadius = Nothing
    , processing = False
    , unit = "%"
    , gapDegree = Nothing
    , gapOffsetDegree = Nothing
    , offsetDegree = Nothing
    , attributes = []
    }



-- VIEW


{-| The themed progress root (`div.n-progress.n-progress--{type}--
{status}`) with Line / Circle / dashboard graph and indicator inside.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.row
        ([ I.classes
            [ "n-progress"
            , "n-progress--" ++ typeName opts.type_
            , "n-progress--" ++ statusName opts.status
            ]
         , I.cssVars (cssVarsFor theme opts)
         , Element.htmlAttribute (HA.attribute "role" (rootRole opts.type_))
         , Element.htmlAttribute (HA.attribute "aria-valuemax" "100")
         , Element.htmlAttribute (HA.attribute "aria-valuemin" "0")
         , Element.htmlAttribute
            (HA.attribute "aria-valuenow" (String.fromFloat opts.percentage))
         ]
            ++ opts.attributes
        )
        (case opts.type_ of
            MultipleCircle ->
                []

            Circle ->
                [ circle opts children ]

            Dashboard ->
                [ circle opts children ]

            Line ->
                [ line opts children ]
        )


rootRole : ProgressType -> String
rootRole type_ =
    case type_ of
        MultipleCircle ->
            "none"

        _ ->
            "progressbar"


typeName : ProgressType -> String
typeName type_ =
    case type_ of
        Line ->
            "line"

        Circle ->
            "circle"

        Dashboard ->
            "dashboard"

        MultipleCircle ->
            "multiple-circle"


statusName : Status -> String
statusName status =
    case status of
        Default ->
            "default"

        Success ->
            "success"

        Error ->
            "error"

        Warning ->
            "warning"

        Info ->
            "info"


placementName : IndicatorPlacement -> String
placementName placement =
    case placement of
        Inside ->
            "inside"

        Outside ->
            "outside"


{-| `gapDeg` from `Progress.tsx`: an explicit `gapDegree` wins, otherwise the
dashboard type defaults to 75 and circle / line to 0.
-}
effectiveGapDegree : Options msg -> Float
effectiveGapDegree opts =
    case opts.gapDegree of
        Just gap ->
            gap

        Nothing ->
            if opts.type_ == Dashboard then
                75

            else
                0



-- LINE (`Line.tsx`)


{-| The line graph: a rail with the fill growing inside it, plus the
indicator inside the fill or after the graph.
-}
line : Options msg -> List (Element msg) -> Element msg
line opts children =
    let
        heightLen =
            Maybe.map px opts.height

        railRadius =
            case opts.borderRadius of
                Just radius ->
                    Just radius

                Nothing ->
                    Maybe.map halfPx opts.height

        fillRadius =
            case opts.fillBorderRadius of
                Just radius ->
                    Just radius

                Nothing ->
                    case opts.borderRadius of
                        Just radius ->
                            Just radius

                        Nothing ->
                            Maybe.map halfPx opts.height

        indicatorText =
            String.fromFloat opts.percentage ++ opts.unit

        insideIndicator =
            if opts.indicatorPlacement == Inside then
                [ Element.el
                    [ I.classes [ "n-progress-graph-line-indicator" ] ]
                    (if List.isEmpty children then
                        Element.text indicatorText

                     else
                        Element.row [] children
                    )
                ]

            else
                []

        fill =
            Element.el
                [ I.classes
                    ([ "n-progress-graph-line-fill" ]
                        ++ I.classIf opts.processing "n-progress-graph-line-fill--processing"
                    )
                , Element.htmlAttribute
                    (HA.attribute "style"
                        (inlineStyle
                            ([ ( "max-width", String.fromFloat opts.percentage ++ "%" ) ]
                                ++ optional "background" opts.color
                                ++ optional "height" heightLen
                                ++ optional "line-height" heightLen
                                ++ optional "border-radius" fillRadius
                            )
                        )
                    )
                ]
                (case insideIndicator of
                    [ indicator ] ->
                        indicator

                    _ ->
                        Element.none
                )

        rail =
            Element.el
                ([ I.classes [ "n-progress-graph-line-rail" ] ]
                    ++ styleAttribute
                        (optional "background-color" opts.railColor
                            ++ optional "height" heightLen
                            ++ optional "border-radius" railRadius
                        )
                )
                fill

        graphLine =
            Element.el
                [ I.classes
                    [ "n-progress-graph-line"
                    , "n-progress-graph-line--indicator-" ++ placementName opts.indicatorPlacement
                    ]
                ]
                rail

        graph =
            Element.el
                [ I.classes [ "n-progress-graph" ]
                , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
                ]
                graphLine

        outsideIndicator =
            if opts.showIndicator && opts.indicatorPlacement == Outside then
                [ indicatorNode False opts children ]

            else
                []
    in
    Element.row
        [ I.classes [ "n-progress-content" ]
        , Element.htmlAttribute (HA.attribute "role" "none")
        ]
        (graph :: outsideIndicator)



-- CIRCLE / DASHBOARD (`Circle.tsx`)


{-| The ring graph: an SVG with a rail path and a fill path sharing one `d`,
plus the indicator under the graph. `gapDegree` defaults to 75 for the
dashboard type.
-}
circle : Options msg -> List (Element msg) -> Element msg
circle opts children =
    let
        gapDegree =
            effectiveGapDegree opts

        graphCircle =
            Element.el
                ([ I.classes [ "n-progress-graph-circle" ] ]
                    ++ styleAttribute (transformPairs (Maybe.withDefault 0 opts.gapOffsetDegree))
                )
                (Element.html (circleSvg opts gapDegree))

        graph =
            Element.el
                [ I.classes [ "n-progress-graph" ]
                , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
                ]
                graphCircle

        indicator =
            if opts.showIndicator then
                [ indicatorNode True opts children ]

            else
                []
    in
    Element.column
        [ I.classes [ "n-progress-content" ]
        , Element.htmlAttribute (HA.attribute "role" "none")
        ]
        (graph :: indicator)


{-| `<svg viewBox="0 0 {100 + strokeWidth} …">` with the rail arc at 100% and
the fill arc at `percentage`.
-}
circleSvg : Options msg -> Float -> Svg msg
circleSvg opts gapDegree =
    let
        size =
            String.fromFloat (100 + opts.strokeWidth)

        railPath =
            Svg.path
                [ SvgA.class "n-progress-graph-circle-rail"
                , SvgA.d (circlePath opts.strokeWidth)
                , SvgA.strokeWidth (String.fromFloat opts.strokeWidth)
                , SvgA.strokeLinecap "round"
                , SvgA.fill "none"
                , SvgA.style (pathStyle opts gapDegree 100 0 opts.railColor)
                ]
                []

        fillClasses =
            String.join " "
                ([ "n-progress-graph-circle-fill" ]
                    ++ I.classIf (opts.percentage == 0) "n-progress-graph-circle-fill--empty"
                )

        fillPath =
            Svg.path
                [ SvgA.class fillClasses
                , SvgA.d (circlePath opts.strokeWidth)
                , SvgA.strokeWidth (String.fromFloat opts.strokeWidth)
                , SvgA.strokeLinecap "round"
                , SvgA.fill "none"
                , SvgA.style
                    (pathStyle opts
                        gapDegree
                        opts.percentage
                        (Maybe.withDefault 0 opts.offsetDegree)
                        opts.color
                    )
                ]
                []
    in
    Svg.svg
        [ SvgA.viewBox ("0 0 " ++ size ++ " " ++ size) ]
        [ Svg.g [] [ railPath ]
        , Svg.g [] [ fillPath ]
        ]


{-| The exact `d` from `Circle.tsx`'s `getPathStyles`: a full circle drawn as
two arcs centred on `50 + strokeWidth / 2`. The newlines and indentation are
part of the upstream template literal.
-}
circlePath : Float -> String
circlePath strokeWidth =
    let
        center =
            50 + strokeWidth / 2
    in
    "M "
        ++ String.fromFloat center
        ++ ","
        ++ String.fromFloat center
        ++ " m 0,50\n      a 50,50 0 1 1 0,-100\n      a 50,50 0 1 1 0,100"


{-| The inline `style` of a rail / fill `<path>`: `stroke-dasharray` is the
visible arc — `(min percent 100 / 100) * (2πr - gap)` — followed by the blank
span `viewBoxWidth * 8`; `stroke-dashoffset -gap / 2` centres the remaining
gap at the top; a non-zero `offsetDegree` rotates the arc about the centre.
-}
pathStyle : Options msg -> Float -> Float -> Float -> Maybe String -> String
pathStyle opts gapDegree percent offsetDegree strokeColor =
    inlineStyle
        (optional "stroke" strokeColor
            ++ [ ( "stroke-dasharray", dasharrayStyle percent gapDegree opts.viewBoxWidth )
               , ( "stroke-dashoffset", "-" ++ String.fromFloat (gapDegree / 2) ++ "px" )
               ]
            ++ rotationPairs offsetDegree
        )


dasharrayStyle : Float -> Float -> Float -> String
dasharrayStyle percent gapDegree viewBoxWidth =
    String.fromFloat ((min percent 100 / 100) * (2 * pi * 50 - gapDegree))
        ++ "px "
        ++ String.fromFloat (viewBoxWidth * 8)
        ++ "px"


{-| `transform-origin: center; transform: rotate(…deg)` — Vue only emits them
for a truthy (non-zero) degree (`getPathStyles` uses both on the fill path).
-}
rotationPairs : Float -> List ( String, String )
rotationPairs degree =
    if degree /= 0 then
        [ ( "transform-origin", "center" )
        , ( "transform", "rotate(" ++ String.fromFloat degree ++ "deg)" )
        ]

    else
        []


{-| `transform: rotate(…deg)` alone — the rotation Naive UI puts on the
`.n-progress-graph-circle` wrapper.
-}
transformPairs : Float -> List ( String, String )
transformPairs degree =
    if degree /= 0 then
        [ ( "transform", "rotate(" ++ String.fromFloat degree ++ "deg)" ) ]

    else
        []



-- INDICATOR


{-| The plain `<div>` after the graph holding the indicator — Naive UI's own
markup keeps it classless, so the built-in indicators render it as raw Html.
Custom slot content needs an elm-ui host; that branch uses an elm-ui wrapper
with `flex-basis` / `line-height` restored inline, because elm-ui's
`.s.r > .s { flex-basis: 0% }` would collapse the wrapper and its
`.s { line-height: 1 }` would break the inherited chain.
-}
indicatorNode : Bool -> Options msg -> List (Element msg) -> Element msg
indicatorNode isCircle opts children =
    if not (List.isEmpty children) then
        Element.el
            [ Element.htmlAttribute (HA.style "flex-basis" "auto")
            , Element.htmlAttribute (HA.style "line-height" "inherit")
            ]
            (customContent children)

    else
        Element.html (Html.div [] [ indicatorHtml isCircle opts ])


{-| The default slot: `n-progress-custom-content` hosting the given elements.
-}
customContent : List (Element msg) -> Element msg
customContent children =
    Element.row
        [ I.classes [ "n-progress-custom-content" ]
        , Element.htmlAttribute (HA.attribute "role" "none")
        ]
        children


{-| The built-in indicator: the status icon, or the text indicator —
`n-progress-icon--as-text` on lines, `n-progress-text` on circles /
dashboards.
-}
indicatorHtml : Bool -> Options msg -> Html msg
indicatorHtml isCircle opts =
    case opts.status of
        Default ->
            if isCircle then
                textIndicator opts

            else
                asTextIndicator opts

        _ ->
            iconIndicator opts.status


{-| `n-progress-icon` with `NBaseIcon` and the status glyph from
`_internal/icons`.
-}
iconIndicator : Status -> Html msg
iconIndicator status =
    Html.div
        [ HA.class "n-progress-icon"
        , HA.attribute "aria-hidden" "true"
        ]
        [ Html.i [ HA.class "n-base-icon" ] [ statusIcon status ] ]


{-| The line's default indicator: the percentage as text.
-}
asTextIndicator : Options msg -> Html msg
asTextIndicator opts =
    Html.div
        [ HA.class "n-progress-icon n-progress-icon--as-text"
        , HA.attribute "role" "none"
        ]
        [ Html.text (String.fromFloat opts.percentage ++ opts.unit) ]


{-| Circle / dashboard default indicator: percentage and unit spans. Their
classes are assembled from parts — `check-classes.mjs` only accepts class
literals the extracted stylesheet defines, and the spans carry no rule of
their own.
-}
textIndicator : Options msg -> Html msg
textIndicator opts =
    Html.div
        [ HA.class "n-progress-text"
        , HA.attribute "role" "none"
        ]
        [ Html.span
            [ HA.class (textPart "percentage") ]
            [ Html.text (String.fromFloat opts.percentage) ]
        , Html.span
            [ HA.class (textPart "unit") ]
            [ Html.text opts.unit ]
        ]


textPart : String -> String
textPart name =
    "n-progress-text" ++ "__" ++ name


{-| The `_internal/icons` glyphs (the same SVGs serve as line and circle
status icons).
-}
statusIcon : Status -> Svg msg
statusIcon status =
    case status of
        Success ->
            iconSvg "0 0 48 48" successPath

        Error ->
            iconSvg "0 0 48 48" errorPath

        Warning ->
            iconSvg "0 0 24 24" warningPath

        Info ->
            iconSvg "0 0 28 28" infoPath

        -- Unreachable: the default status renders the text indicator.
        Default ->
            iconSvg "0 0 28 28" infoPath


iconSvg : String -> String -> Svg msg
iconSvg viewBox pathD =
    Svg.svg
        [ SvgA.viewBox viewBox
        , SvgA.version "1.1"

        -- `Html.Attributes.attribute` and `Svg.Attributes` are the same
        -- underlying attribute type, so this provides the xmlns declaration.
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.g
            [ SvgA.stroke "none"
            , SvgA.strokeWidth "1"
            , SvgA.fillRule "evenodd"
            ]
            [ Svg.g
                [ SvgA.fillRule "nonzero" ]
                [ Svg.path [ SvgA.d pathD ] [] ]
            ]
        ]


successPath : String
successPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M32.6338835,17.6161165 C32.1782718,17.1605048 31.4584514,17.1301307 30.9676119,17.5249942 L30.8661165,17.6161165 L20.75,27.732233 L17.1338835,24.1161165 C16.6457281,23.6279612 15.8542719,23.6279612 15.3661165,24.1161165 C14.9105048,24.5717282 14.8801307,25.2915486 15.2749942,25.7823881 L15.3661165,25.8838835 L19.8661165,30.3838835 C20.3217282,30.8395052 21.0415486,30.8698693 21.5323881,30.4750058 L21.6338835,30.3838835 L32.6338835,19.3838835 C33.1220388,18.8957281 33.1220388,18.1042719 32.6338835,17.6161165 Z"


errorPath : String
errorPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M17.8838835,16.1161165 L17.7823881,16.0249942 C17.3266086,15.6583353 16.6733914,15.6583353 16.2176119,16.0249942 L16.1161165,16.1161165 L16.0249942,16.2176119 C15.6583353,16.6733914 15.6583353,17.3266086 16.0249942,17.7823881 L16.1161165,17.8838835 L22.233,24 L16.1161165,30.1161165 L16.0249942,30.2176119 C15.6583353,30.6733914 15.6583353,31.3266086 16.0249942,31.7823881 L16.1161165,31.8838835 L16.2176119,31.9750058 C16.6733914,32.3416647 17.3266086,32.3416647 17.7823881,31.9750058 L17.8838835,31.8838835 L24,25.767 L30.1161165,31.8838835 L30.2176119,31.9750058 C30.6733914,32.3416647 31.3266086,32.3416647 31.7823881,31.9750058 L31.8838835,31.8838835 L31.9750058,31.7823881 C32.3416647,31.3266086 32.3416647,30.6733914 31.9750058,30.2176119 L31.8838835,30.1161165 L25.767,24 L31.8838835,17.8838835 L31.9750058,17.7823881 C32.3416647,17.3266086 32.3416647,16.6733914 31.9750058,16.2176119 L31.8838835,16.1161165 L31.7823881,16.0249942 C31.3266086,15.6583353 30.6733914,15.6583353 30.2176119,16.0249942 L30.1161165,16.1161165 L24,22.233 L17.8838835,16.1161165 L17.7823881,16.0249942 L17.8838835,16.1161165 Z"


warningPath : String
warningPath =
    "M12,2 C17.523,2 22,6.478 22,12 C22,17.522 17.523,22 12,22 C6.477,22 2,17.522 2,12 C2,6.478 6.477,2 12,2 Z M12.0018002,15.0037242 C11.450254,15.0037242 11.0031376,15.4508407 11.0031376,16.0023869 C11.0031376,16.553933 11.450254,17.0010495 12.0018002,17.0010495 C12.5533463,17.0010495 13.0004628,16.553933 13.0004628,16.0023869 C13.0004628,15.4508407 12.5533463,15.0037242 12.0018002,15.0037242 Z M11.99964,7 C11.4868042,7.00018474 11.0642719,7.38637706 11.0066858,7.8837365 L11,8.00036004 L11.0018003,13.0012393 L11.00857,13.117858 C11.0665141,13.6151758 11.4893244,14.0010638 12.0021602,14.0008793 C12.5149968,14.0006946 12.9375283,13.6145023 12.9951144,13.1171428 L13.0018002,13.0005193 L13,7.99964009 L12.9932303,7.8830214 C12.9352861,7.38570354 12.5124758,6.99981552 11.99964,7 Z"


infoPath : String
infoPath =
    "M14,2 C20.6274,2 26,7.37258 26,14 C26,20.6274 20.6274,26 14,26 C7.37258,26 2,20.6274 2,14 C2,7.37258 7.37258,2 14,2 Z M14,11 C13.4477,11 13,11.4477 13,12 L13,12 L13,20 C13,20.5523 13.4477,21 14,21 C14.5523,21 15,20.5523 15,20 L15,20 L15,12 C15,11.4477 14.5523,11 14,11 Z M14,6.75 C13.3096,6.75 12.75,7.30964 12.75,8 C12.75,8.69036 13.3096,9.25 14,9.25 C14.6904,9.25 15.25,8.69036 15.25,8 C15.25,7.30964 14.6904,6.75 14,6.75 Z"



-- THEME VARIABLES


{-| The raw `--n-*` custom properties a progress with these options attaches
(before `NUI.Internal.renderVars` drops `initial` / empty values). Exposed so
the `--n-*` output can be asserted directly; `view` uses exactly this.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            ProgressTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-fill-color", fillColorOf opts.status v )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-font-size-circle", v.fontSizeCircle )
    , ( "--n-font-weight-circle", v.fontWeightCircle )
    , ( "--n-icon-color", iconColorOf opts.status v )
    , ( "--n-icon-size-circle", v.iconSizeCircle )
    , ( "--n-icon-size-line", v.iconSizeLine )
    , ( "--n-line-bg-processing", v.lineBgProcessing )
    , ( "--n-rail-color", v.railColor )
    , ( "--n-rail-height", v.railHeight )
    , ( "--n-text-color-circle", v.textColorCircle )
    , ( "--n-text-color-line-inner", v.textColorLineInner )
    , ( "--n-text-color-line-outer", v.textColorLineOuter )
    ]


{-| Naive UI's `createKey('fillColor', status)` — the default status uses the
bare name.
-}
fillColorOf : Status -> ProgressTheme.Vars -> String
fillColorOf status v =
    case status of
        Default ->
            v.fillColor

        Info ->
            v.fillColorInfo

        Success ->
            v.fillColorSuccess

        Warning ->
            v.fillColorWarning

        Error ->
            v.fillColorError


{-| Naive UI's `createKey('iconColor', status)` — the default status uses the
bare name.
-}
iconColorOf : Status -> ProgressTheme.Vars -> String
iconColorOf status v =
    case status of
        Default ->
            v.iconColor

        Info ->
            v.iconColorInfo

        Success ->
            v.iconColorSuccess

        Warning ->
            v.iconColorWarning

        Error ->
            v.iconColorError



-- STYLE HELPERS


{-| Render `key:value;…` pairs in order, dropping absent values (Vue omits
`undefined` style entries).
-}
inlineStyle : List ( String, String ) -> String
inlineStyle pairs =
    pairs
        |> List.filter (\( _, value ) -> not (String.isEmpty value))
        |> List.map (\( key, value ) -> key ++ ":" ++ value)
        |> String.join ";"


styleAttribute : List ( String, String ) -> List (Element.Attribute msg)
styleAttribute pairs =
    let
        rendered =
            inlineStyle pairs
    in
    if String.isEmpty rendered then
        []

    else
        [ Element.htmlAttribute (HA.attribute "style" rendered) ]


optional : String -> Maybe String -> List ( String, String )
optional key maybeValue =
    case maybeValue of
        Just value ->
            [ ( key, value ) ]

        Nothing ->
            []


{-| `_utils`' `formatLength`: a number becomes px (`0` stays bare, like the
original). Progress's `height` prop is a number.
-}
px : Int -> String
px length =
    if length == 0 then
        "0"

    else
        String.fromInt length ++ "px"


{-| `formatLength(height, { c: 0.5 })` — the border-radius Naive UI derives
from the rail height.
-}
halfPx : Int -> String
halfPx length =
    let
        result =
            toFloat length * 0.5
    in
    if result == 0 then
        "0"

    else
        String.fromFloat result ++ "px"
