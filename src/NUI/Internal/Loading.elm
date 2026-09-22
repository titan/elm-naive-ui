module NUI.Internal.Loading exposing (spinner)

{-| Naive UI's internal `NBaseLoading` spinner svg
(`src/_internal/loading/src/Loading.tsx`), ported verbatim onto elm/svg.

**Single source.** Every `n-base-loading` spinner rendering in the library
goes through `spinner` — this supersedes the port's old "local copies, not
cross-module internal imports" convention _for the loading svg specifically_
(Button / BaseSelection / Input each carried a hand-rolled `Html.node` copy,
Switch a data-URI background image). The wrapper divs stay caller-owned,
because their class combos differ per call site: the root
`div.n-base-loading[role=img][aria-label=loading]` (plus the caller's extra
classes — Button's `n-icon-slot`, BaseSelection / Input's `n-base-suffix`,
Spin's `n-spin`), `.__transition-wrapper`, `.__container`, and the
`show=false` placeholder branch — see `Loading.tsx`'s render.

**Geometry** (r' = radius / scale; every value computed with
`String.fromFloat`, never rounded or hardcoded — the doubles print exactly):

    svg     class n-base-loading__icon · xmlns http://www.w3.org/2000/svg
            viewBox `0 0 {2r'} {2r'}` · style `color:{stroke}` iff stroke set
    g       animateTransform rotate `0 r' r';270 r' r'` — begin 0s, dur 1.6s,
            fill freeze, repeatCount indefinite
    circle  class n-base-loading__icon · fill none · stroke currentColor ·
            stroke-width {strokeWidth} · stroke-linecap round · cx/cy r' ·
            r {radius − strokeWidth/2} · stroke-dasharray {5.67·radius} ·
            stroke-dashoffset {18.48·radius}
            animateTransform rotate `0 r' r';135 r' r';450 r' r'`
            animate stroke-dashoffset `{5.67r};{1.42r};{5.67r}`

For the library's geometries (radius 100): dash `567`, offset `1848`, the
animate keyframes `142`, circle `r` 90 (strokeWidth 20, Button / Switch) or
88 (strokeWidth 24, the input suffix); at scale 0.85, r'
`117.64705882352942` and viewBox `235.29411764705884`.

elm/svg serializes into the SVG namespace (`createElementNS`), so a real
browser renders the arc — `Html.node "svg"` would produce an HTML-namespace
unknown element it never draws. The one attribute elm/svg's set lacks,
`xmlns`, is emitted via `Html.Attributes.attribute` (the same underlying
`VirtualDom.Attribute` type under elm/html's alias).

-}

import Html.Attributes as HA
import Svg exposing (Svg)
import Svg.Attributes as SA


{-| The `NBaseLoading` spinner svg — every loading spinner in the library
renders through this one builder (the record mirrors upstream's props:
`strokeWidth` 28, `scale` 1, `radius` 100, `stroke` unset by default). The
wrapper divs are caller-owned; see the module doc.
-}
spinner :
    { strokeWidth : Float
    , radius : Float
    , scale : Float
    , stroke : Maybe String
    }
    -> Svg msg
spinner { strokeWidth, radius, scale, stroke } =
    let
        scaledRadius =
            radius / scale
    in
    Svg.svg
        ([ SA.class "n-base-loading__icon"
         , SA.viewBox (box scaledRadius)
         , xmlns
         ]
            ++ (case stroke of
                    -- Vue's `style={{ color: stroke }}` (absent when unset)
                    Just s ->
                        [ SA.style ("color:" ++ s) ]

                    Nothing ->
                        []
               )
        )
        [ Svg.g []
            [ animateTransform [ 0, 270 ] scaledRadius
            , Svg.circle
                [ SA.class "n-base-loading__icon"
                , SA.fill "none"
                , SA.stroke "currentColor"
                , SA.strokeWidth (String.fromFloat strokeWidth)
                , SA.strokeLinecap "round"
                , SA.cx (String.fromFloat scaledRadius)
                , SA.cy (String.fromFloat scaledRadius)
                , SA.r (String.fromFloat (radius - strokeWidth / 2))
                , SA.strokeDasharray (String.fromFloat (5.67 * radius))
                , SA.strokeDashoffset (String.fromFloat (18.48 * radius))
                ]
                [ animateTransform [ 0, 135, 450 ] scaledRadius
                , Svg.node "animate"
                    [ SA.attributeName "stroke-dashoffset"
                    , SA.values
                        (String.join ";"
                            [ String.fromFloat (5.67 * radius)
                            , String.fromFloat (1.42 * radius)
                            , String.fromFloat (5.67 * radius)
                            ]
                        )
                    , SA.begin "0s"
                    , SA.dur duration
                    , SA.fill "freeze"
                    , SA.repeatCount "indefinite"
                    ]
                    []
                ]
            ]
        ]


{-| `NBaseLoading`'s SMIL duration constant.
-}
duration : String
duration =
    "1.6s"


{-| elm/svg has no `xmlns` attribute (nor a generic `attribute`), so the
upstream constant goes through `Html.Attributes.attribute` — an
`Html.Attribute msg` is the same `VirtualDom.Attribute msg` as a
`Svg.Attribute msg`.
-}
xmlns : Svg.Attribute msg
xmlns =
    HA.attribute "xmlns" "http://www.w3.org/2000/svg"


box : Float -> String
box scaledRadius =
    "0 0 "
        ++ String.fromFloat (2 * scaledRadius)
        ++ " "
        ++ String.fromFloat (2 * scaledRadius)


{-| `<animateTransform attributeName="transform" type="rotate" values="{deg}
{r'} {r'}; …">` with upstream's begin/dur/fill/repeatCount.
-}
animateTransform : List Float -> Float -> Svg msg
animateTransform degrees scaledRadius =
    Svg.node "animateTransform"
        [ SA.attributeName "transform"
        , SA.type_ "rotate"
        , SA.values (rotateValues degrees scaledRadius)
        , SA.begin "0s"
        , SA.dur duration
        , SA.fill "freeze"
        , SA.repeatCount "indefinite"
        ]
        []


rotateValues : List Float -> Float -> String
rotateValues degrees scaledRadius =
    let
        point deg =
            String.fromFloat deg
                ++ " "
                ++ String.fromFloat scaledRadius
                ++ " "
                ++ String.fromFloat scaledRadius
    in
    String.join ";" (List.map point degrees)
