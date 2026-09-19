module NUI.Progress exposing
    ( FillColor(..)
    , IndicatorPlacement(..)
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

    NUI.Progress.view theme
        { NUI.Progress.defaults
            | type_ = NUI.Progress.MultipleCircle
            , percentages = [ 80, 60 ]
            , colors = [ NUI.Progress.Solid "#2080f0", NUI.Progress.Solid "#18a058" ]
            , railColors = [ "#2080f0", "#18a058" ]
            , strokeWidth = 6
            , circleGap = 0.5
        }
        [ Element.text "Circle racing!" ]

The visual result is Naive UI's own: the element carries the `.n-progress`
BEM classes and Naive UI's `--n-*` custom properties, and `NUI.Css` ships
Naive UI's exact CSS. The children are the default slot: custom indicator
content, replacing the percentage text / status icon.

`Dashboard` is the circle graph with `gapDegree` defaulting to 75.
`MultipleCircle` draws concentric rings — one per entry in `percentages`, each
with its own fill colour (`colors`) and rail colour (`railColors`) — and turns
the default slot into the centre indicator when a child is given.

A fill colour may be a solid colour (`Solid "#2080f0"`) or a linear gradient
(`Gradient [ "white", "#18a058" ]`), Naive UI's `string | { stops }`. Rails are
solid colours only, as upstream. The gradient's `id` is byte-identical to
Naive UI's (`gradient-` + css-render's murmur2 hash for circles, the ring index
for multiple-circle).

-}

import Bitwise
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


{-| A fill colour: a solid CSS colour, or Naive UI's `{ stops }` gradient — a
list of colour stops whose first two are the gradient's ends (`stops[0]` /
`stops[1]`). Rails are always `Solid`; only fills may be `Gradient`.
-}
type FillColor
    = Solid String
    | Gradient (List String)


{-| Naive UI's `indicator-placement` (line only): the indicator sits inside
the fill or after the graph.
-}
type IndicatorPlacement
    = Inside
    | Outside


type alias Options msg =
    { type_ : ProgressType
    , percentage : Float
    , percentages : List Float
    , status : Status
    , showIndicator : Bool
    , indicatorPlacement : IndicatorPlacement
    , color : Maybe FillColor
    , colors : List FillColor
    , railColor : Maybe String
    , railColors : List String
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
    , circleGap : Float
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { type_ = Line
    , percentage = 0
    , percentages = [ 0 ]
    , status = Default
    , showIndicator = True
    , indicatorPlacement = Outside
    , color = Nothing
    , colors = []
    , railColor = Nothing
    , railColors = []
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
    , circleGap = 1
    , attributes = []
    }



-- VIEW


{-| The themed progress root (`div.n-progress.n-progress--{type}--
{status}`) with Line / Circle / dashboard / multiple-circle graph and
indicator inside.
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
            (HA.attribute "aria-valuenow" (rootValuenow opts))
         ]
            ++ opts.attributes
        )
        (case opts.type_ of
            MultipleCircle ->
                [ multipleCircle opts children ]

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


{-| `aria-valuenow` from `Progress.tsx`: the single `percentage` for one graph,
but the comma-joined list for `multiple-circle` (Vue stringifies the array
prop).
-}
rootValuenow : Options msg -> String
rootValuenow opts =
    if opts.type_ == MultipleCircle then
        String.join "," (List.map String.fromFloat opts.percentages)

    else
        String.fromFloat opts.percentage


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
                                ++ optional "background" (fillBackground opts.color)
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
                        (circleFillStroke opts.color)
                    )
                ]
                []
    in
    Svg.svg
        [ SvgA.viewBox ("0 0 " ++ size ++ " " ++ size) ]
        (circleGradientDefs opts
            ++ [ Svg.g [] [ railPath ]
               , Svg.g [] [ fillPath ]
               ]
        )


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



-- MULTIPLE CIRCLE (`MultipleCircle.tsx`)


{-| The concentric-rings graph: one rail / fill `<path>` pair per entry in
`percentages`, each ring inset by `strokeWidth / 2 * (1 + 2i) + circleGap * i`.
The default slot becomes the centre indicator, but only when a child is given —
unlike `Circle`, the built-in text / icon indicators never render. A ring whose
`colors` entry is a `Gradient` gets a `<linearGradient id="gradient-{i}">`
(`x1="100%" y1="0%" x2="0%" y2="100%"`) in the `<defs>`.
-}
multipleCircle : Options msg -> List (Element msg) -> Element msg
multipleCircle opts children =
    let
        graphCircle =
            Element.el
                [ I.classes [ "n-progress-graph-circle" ] ]
                (Element.html (multipleCircleSvg opts))

        graph =
            Element.el
                [ I.classes [ "n-progress-graph" ]
                , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
                ]
                graphCircle

        indicator =
            if opts.showIndicator && not (List.isEmpty children) then
                [ multipleIndicator children ]

            else
                []
    in
    Element.column
        [ I.classes [ "n-progress-content" ]
        , Element.htmlAttribute (HA.attribute "role" "none")
        ]
        (graph :: indicator)


{-| `<svg viewBox="0 0 {viewBoxWidth} {viewBoxWidth}">` with one `<g>` per
percentage.
-}
multipleCircleSvg : Options msg -> Svg msg
multipleCircleSvg opts =
    let
        size =
            String.fromFloat opts.viewBoxWidth
    in
    Svg.svg
        [ SvgA.viewBox ("0 0 " ++ size ++ " " ++ size) ]
        (multipleCircleDefs opts
            :: List.indexedMap (multipleCircleRings opts) opts.percentages
        )


{-| One ring: a rail `<path>` (full circle, per-circle rail colour) and a fill
`<path>` (arc at `percent`, per-circle colour) sharing the same `d`.
-}
multipleCircleRings : Options msg -> Int -> Float -> Svg msg
multipleCircleRings opts index percent =
    let
        pathD =
            multipleCirclePath opts index

        rail =
            Svg.path
                [ SvgA.class "n-progress-graph-circle-rail"
                , SvgA.d pathD
                , SvgA.strokeWidth (String.fromFloat opts.strokeWidth)
                , SvgA.strokeLinecap "round"
                , SvgA.fill "none"
                , SvgA.style
                    (inlineStyle
                        (( "stroke-dashoffset", "0" )
                            :: optional "stroke" (nth index opts.railColors)
                        )
                    )
                ]
                []

        fillClasses =
            String.join " "
                ([ "n-progress-graph-circle-fill" ]
                    ++ I.classIf (percent == 0) "n-progress-graph-circle-fill--empty"
                )

        fill =
            Svg.path
                [ SvgA.class fillClasses
                , SvgA.d pathD
                , SvgA.strokeWidth (String.fromFloat opts.strokeWidth)
                , SvgA.strokeLinecap "round"
                , SvgA.fill "none"
                , SvgA.style
                    (inlineStyle
                        (( "stroke-dasharray", multipleDasharray opts index percent )
                            :: ( "stroke-dashoffset", "0" )
                            :: optional "stroke" (multipleFillStroke opts.colors index)
                        )
                    )
                ]
                []
    in
    Svg.g [] [ rail, fill ]


{-| `circlePath(r, strokeWidth, viewBoxWidth)` from `MultipleCircle.tsx`:
`m {vw/2} {vw/2 - r} a {r} {r} 0 1 1 0 {2r} a {r} {r} 0 1 1 0 -{2r}`.
-}
multipleCirclePath : Options msg -> Int -> String
multipleCirclePath opts index =
    let
        r =
            multipleCircleRadius opts index

        half =
            String.fromFloat (opts.viewBoxWidth / 2)

        top =
            String.fromFloat (opts.viewBoxWidth / 2 - r)

        radius =
            String.fromFloat r

        diameter =
            String.fromFloat (2 * r)
    in
    "m "
        ++ half
        ++ " "
        ++ top
        ++ " a "
        ++ radius
        ++ " "
        ++ radius
        ++ " 0 1 1 0 "
        ++ diameter
        ++ " a "
        ++ radius
        ++ " "
        ++ radius
        ++ " 0 1 1 0 -"
        ++ diameter


{-| The ring radius: `viewBoxWidth / 2 - (strokeWidth / 2) * (1 + 2i) -
circleGap * i`.
-}
multipleCircleRadius : Options msg -> Int -> Float
multipleCircleRadius opts index =
    let
        i =
            toFloat index
    in
    opts.viewBoxWidth
        / 2
        - (opts.strokeWidth / 2)
        * (1 + 2 * i)
        - opts.circleGap
        * i


{-| The fill `stroke-dasharray`: the visible arc `(pi * percent / 100) * r * 2`
followed by the blank span `viewBoxWidth * 8`. Unlike `Circle`, upstream emits
this comma-separated and unit-less.
-}
multipleDasharray : Options msg -> Int -> Float -> String
multipleDasharray opts index percent =
    String.fromFloat (((pi * percent) / 100) * multipleCircleRadius opts index * 2)
        ++ ", "
        ++ String.fromFloat (opts.viewBoxWidth * 8)


{-| The multiple-circle indicator: the default slot inside a classless `<div>` /
`.n-progress-text` pair (no `role`, unlike the circle's built-in text). Custom
slot content needs an elm-ui host, so `flex-basis` / `line-height` are restored
inline the way `indicatorNode` does.
-}
multipleIndicator : List (Element msg) -> Element msg
multipleIndicator children =
    Element.el
        [ Element.htmlAttribute (HA.style "flex-basis" "auto")
        , Element.htmlAttribute (HA.style "line-height" "inherit")
        ]
        (Element.row
            [ I.classes [ "n-progress-text" ] ]
            children
        )


{-| `List.get` by index — the per-circle colour arrays may be shorter than
`percentages` (Vue leaves the rest `undefined`, which drops the `stroke`).
-}
nth : Int -> List a -> Maybe a
nth index items =
    items |> List.drop index |> List.head



-- GRADIENT COLOURS


{-| `Line.tsx`'s `styleFillColorRef`: a gradient becomes
`linear-gradient(to right, {stops[0]} , {stops[1]})` (note the space before the
comma, straight from upstream's template literal); a solid colour passes
through.
-}
fillBackground : Maybe FillColor -> Maybe String
fillBackground fillColor =
    case fillColor of
        Just (Gradient stops) ->
            Just ("linear-gradient(to right, " ++ stopAt 0 stops ++ " , " ++ stopAt 1 stops ++ ")")

        Just (Solid color) ->
            Just color

        Nothing ->
            Nothing


{-| `Circle.tsx`'s `createGradientNode`: a `<defs><linearGradient>` only when
the fill colour is a gradient (upstream renders `false` otherwise). The `id` is
`gradient-{hash}` with `hash = css-render's hash(JSON.stringify(fillColor))`.
-}
circleGradientDefs : Options msg -> List (Svg msg)
circleGradientDefs opts =
    case opts.color of
        Just (Gradient stops) ->
            [ Svg.defs []
                [ Svg.linearGradient
                    [ SvgA.id (circleGradientId stops)
                    , SvgA.x1 "0%"
                    , SvgA.y1 "100%"
                    , SvgA.x2 "100%"
                    , SvgA.y2 "0%"
                    ]
                    [ Svg.stop [ SvgA.offset "0%", SvgA.stopColor (stopAt 0 stops) ] []
                    , Svg.stop [ SvgA.offset "100%", SvgA.stopColor (stopAt 1 stops) ] []
                    ]
                ]
            ]

        _ ->
            []


{-| `Circle.tsx`'s fill `stroke`: `url(#gradient-{hash})` for a gradient, the
plain colour for a solid one.
-}
circleFillStroke : Maybe FillColor -> Maybe String
circleFillStroke fillColor =
    case fillColor of
        Just (Gradient stops) ->
            Just ("url(#" ++ circleGradientId stops ++ ")")

        Just (Solid color) ->
            Just color

        Nothing ->
            Nothing


{-| `MultipleCircle.tsx`'s `<defs>` — one `<linearGradient id="gradient-{i}">`
per gradient ring, in ring order (non-gradient rings contribute nothing).
-}
multipleCircleDefs : Options msg -> Svg msg
multipleCircleDefs opts =
    Svg.defs []
        (opts.percentages
            |> List.indexedMap (\index _ -> multipleGradientNodeAt opts index)
            |> List.filterMap identity
        )


multipleGradientNodeAt : Options msg -> Int -> Maybe (Svg msg)
multipleGradientNodeAt opts index =
    case nth index opts.colors of
        Just (Gradient stops) ->
            Just
                (Svg.linearGradient
                    [ SvgA.id ("gradient-" ++ String.fromInt index)
                    , SvgA.x1 "100%"
                    , SvgA.y1 "0%"
                    , SvgA.x2 "0%"
                    , SvgA.y2 "100%"
                    ]
                    [ Svg.stop [ SvgA.offset "0%", SvgA.stopColor (stopAt 0 stops) ] []
                    , Svg.stop [ SvgA.offset "100%", SvgA.stopColor (stopAt 1 stops) ] []
                    ]
                )

        _ ->
            Nothing


{-| `MultipleCircle.tsx`'s fill `stroke`: `url(#gradient-{i})` when that ring's
colour is a gradient, the plain colour otherwise. (Upstream's id here is the
bare ring index, not a content hash.)
-}
multipleFillStroke : List FillColor -> Int -> Maybe String
multipleFillStroke colors index =
    case nth index colors of
        Just (Gradient _) ->
            Just ("url(#gradient-" ++ String.fromInt index ++ ")")

        Just (Solid color) ->
            Just color

        Nothing ->
            Nothing


{-| `stops[n]` with JS's `undefined` collapsed to the empty string (which
`optional` then drops, like Vue's absent attribute).
-}
stopAt : Int -> List String -> String
stopAt index stops =
    stops |> List.drop index |> List.head |> Maybe.withDefault ""


{-| The `id` Naive UI gives a circle gradient: `gradient-` + css-render's
`hash(JSON.stringify({ stops: […] }))`.
-}
circleGradientId : List String -> String
circleGradientId stops =
    "gradient-" ++ murmur2 (jsonStops stops)


{-| `JSON.stringify({ stops: […] })` for a list of colour strings — enough of
JSON to match what css-render hashes upstream (`{"stops":["white","pink"]}`).
-}
jsonStops : List String -> String
jsonStops stops =
    "{\"stops\":[" ++ String.join "," (List.map (\stop -> "\"" ++ stop ++ "\"") stops) ++ "]}"


{-| `@emotion/hash` (the murmur2 behind css-render's `hash`), ported with
`Bitwise` so gradient ids are byte-identical to upstream. Inputs here are ASCII
(colour stops), so UTF-16 code units and code points coincide.
-}
murmur2 : String -> String
murmur2 str =
    let
        multiplier =
            0x5BD1E995

        -- `Math.imul(x, multiplier)` emulation from the original source.
        imul x =
            Bitwise.and x 0xFFFF
                * multiplier
                + Bitwise.shiftLeftBy 16 (Bitwise.shiftRightZfBy 16 x * 0xE995)

        block h a b c d =
            let
                k =
                    Bitwise.or
                        (Bitwise.or
                            (Bitwise.and (Char.toCode a) 0xFF)
                            (Bitwise.shiftLeftBy 8 (Bitwise.and (Char.toCode b) 0xFF))
                        )
                        (Bitwise.or
                            (Bitwise.shiftLeftBy 16 (Bitwise.and (Char.toCode c) 0xFF))
                            (Bitwise.shiftLeftBy 24 (Bitwise.and (Char.toCode d) 0xFF))
                        )

                mixed =
                    Bitwise.xor (imul k) (Bitwise.shiftRightZfBy 24 (imul k))
            in
            Bitwise.xor (imul mixed) (imul h)

        loop h chars =
            case chars of
                a :: b :: c :: d :: rest ->
                    loop (block h a b c d) rest

                _ ->
                    tail h chars

        tail h chars =
            case chars of
                [ a, b, c ] ->
                    imul
                        (Bitwise.xor
                            (Bitwise.xor
                                (Bitwise.xor h (Bitwise.shiftLeftBy 16 (Bitwise.and (Char.toCode c) 0xFF)))
                                (Bitwise.shiftLeftBy 8 (Bitwise.and (Char.toCode b) 0xFF))
                            )
                            (Bitwise.and (Char.toCode a) 0xFF)
                        )

                [ a, b ] ->
                    imul
                        (Bitwise.xor
                            (Bitwise.xor h (Bitwise.shiftLeftBy 8 (Bitwise.and (Char.toCode b) 0xFF)))
                            (Bitwise.and (Char.toCode a) 0xFF)
                        )

                [ a ] ->
                    imul (Bitwise.xor h (Bitwise.and (Char.toCode a) 0xFF))

                _ ->
                    h

        finalize h =
            let
                h1 =
                    Bitwise.xor h (Bitwise.shiftRightZfBy 13 h)

                h2 =
                    imul h1
            in
            toBase36 (Bitwise.shiftRightZfBy 0 (Bitwise.xor h2 (Bitwise.shiftRightZfBy 15 h2)))
    in
    finalize (loop 0 (String.toList str))


{-| `(value >>> 0).toString(36)` — lowercase base36 of the unsigned 32-bit hash.
-}
toBase36 : Int -> String
toBase36 n =
    if n < 36 then
        String.fromChar (Char.fromCode (base36Digit n))

    else
        toBase36 (n // 36) ++ String.fromChar (Char.fromCode (base36Digit (modBy 36 n)))


base36Digit : Int -> Int
base36Digit d =
    if d < 10 then
        48 + d

    else
        87 + d



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
