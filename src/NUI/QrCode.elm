module NUI.QrCode exposing
    ( ErrorCorrectionLevel(..)
    , Options
    , Padding(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `QrCode`, rebuilt on elm-ui.

    NUI.QrCode.view theme
        { NUI.QrCode.defaults | value = "https://www.naiveui.com/" }

    NUI.QrCode.view theme
        { NUI.QrCode.defaults
            | value = "https://www.naiveui.com/"
            , color = "#18a058"
            , backgroundColor = "#F5F5F5"
            , errorCorrectionLevel = NUI.QrCode.H
        }

The symbol is encoded by the ported Nayuki library (`NUI.Qrcodegen`) and drawn
as an inline `<svg>`; `NUI.Css` ships Naive UI's exact CSS (`.n-qr-code` plus
the `--n-border-radius` variable).

**Rendering backend.** Upstream defaults to a `<canvas>` and can also emit an
inline `<svg>` (`type="svg"`). This library is pure, so it always renders the
`<svg>` form — the same modules, the same pixels, without imperative canvas
drawing or image preloading. Because of that, upstream's canvas-only
`icon-background-color` / `icon-border-radius` props are not modelled.

**Runtime.** The `iconSrc` image is referenced directly (`<image href=…>`), so
the caller owns loading it. A `value` that does not fit yields an empty
container (upstream throws); the default `value` is `"-"`, mirroring upstream's
`value ?? '-'` fallback.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Qrcodegen as Qrcodegen
import NUI.Theme exposing (Theme)
import NUI.Theme.QrCode as QrCodeTheme


{-| The QR error correction level, mirroring upstream's
`error-correction-level` prop (`'L' | 'M' | 'Q' | 'H'`).
-}
type ErrorCorrectionLevel
    = L
    | M
    | Q
    | H


{-| Naive UI's `string | number` `padding` prop. `Px 12` renders `12px`;
`Custom "5%"` passes an arbitrary CSS length through unchanged.
-}
type Padding
    = Px Int
    | Custom String


type alias Options msg =
    { value : String
    , color : String
    , backgroundColor : String
    , iconSrc : Maybe String
    , iconSize : Int
    , size : Int
    , padding : Padding
    , errorCorrectionLevel : ErrorCorrectionLevel
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { value = "-"
    , color = "#000"
    , backgroundColor = "#FFF"
    , iconSrc = Nothing
    , iconSize = 40
    , size = 100
    , padding = Px 12
    , errorCorrectionLevel = M
    , attributes = []
    }


{-| The QR container: `div.n-qr-code` sized by `size` and padded by `padding`,
holding Naive UI's inline `<svg>` symbol.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.el
        ([ I.classes [ "n-qr-code" ]
         , I.cssVars (cssVarsFor theme opts)
         ]
            ++ opts.attributes
        )
        (case Qrcodegen.encodeText opts.value (toEcc opts.errorCorrectionLevel) of
            Ok qr ->
                renderSvg opts qr

            Err _ ->
                Element.none
        )


{-| The entries of the container's inline `style` attribute, in upstream order:
the plain properties from `QrCode.tsx` (`padding`, `background-color`, `width`,
`height`) followed by the `--n-*` custom properties.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    [ ( "padding", paddingToString opts.padding )
    , ( "background-color", opts.backgroundColor )
    , ( "width", px opts.size )
    , ( "height", px opts.size )
    , ( "--n-border-radius", (QrCodeTheme.vars theme).borderRadius )
    ]


{-| The inline `<svg>` symbol, mirroring upstream's `svg` render: a transparent
bounding path, the dark-module path, and an optional icon `<image>`.
-}
renderSvg : Options msg -> Qrcodegen.QrCode -> Element msg
renderSvg opts qr =
    let
        numCells =
            Qrcodegen.size qr

        n =
            String.fromInt numCells
    in
    Element.html
        (Html.node "svg"
            [ HA.attribute "height" (String.fromInt opts.size)
            , HA.attribute "width" (String.fromInt opts.size)
            , HA.attribute "viewBox" ("0 0 " ++ n ++ " " ++ n)
            , HA.attribute "role" "img"
            ]
            ([ Html.node "path"
                [ HA.attribute "fill" "transparent"
                , HA.attribute "d" ("M0,0 h" ++ n ++ "v" ++ n ++ "H0z")
                , HA.attribute "shape-rendering" "crispEdges"
                ]
                []
             , Html.node "path"
                [ HA.attribute "fill" opts.color
                , HA.attribute "d" (generatePath (Qrcodegen.getModules qr) 0)
                , HA.attribute "shape-rendering" "crispEdges"
                ]
                []
             ]
                ++ iconNodes opts numCells
            )
        )


{-| Upstream's centered icon `<image>` when `iconSrc` is set. The size is
`iconSize` (`0` falls back to 10% of `size`) converted from pixels to module
units — exactly upstream's `svgInfo` math.
-}
iconNodes : Options msg -> Int -> List (Html.Html msg)
iconNodes opts numCells =
    case opts.iconSrc of
        Nothing ->
            []

        Just src ->
            let
                sizeF =
                    toFloat opts.size

                scale =
                    toFloat numCells / sizeF

                iconSize =
                    if opts.iconSize == 0 then
                        floor (sizeF * 0.1)

                    else
                        opts.iconSize

                width =
                    toFloat iconSize * scale

                height =
                    width

                left =
                    toFloat numCells / 2 - width / 2

                top =
                    toFloat numCells / 2 - height / 2
            in
            [ Html.node "image"
                [ HA.attribute "href" src
                , HA.attribute "width" (String.fromFloat width)
                , HA.attribute "height" (String.fromFloat height)
                , HA.attribute "x" (String.fromFloat left)
                , HA.attribute "y" (String.fromFloat top)
                , HA.attribute "preserveAspectRatio" "none"
                ]
                []
            ]


{-| Upstream's `generatePath`: one `d` per row, each a run of `h…v1H…z` (or a
single module) operations, concatenated.
-}
generatePath : List (List Bool) -> Int -> String
generatePath modules margin =
    modules
        |> List.indexedMap (rowPaths margin)
        |> String.concat


rowPaths : Int -> Int -> List Bool -> String
rowPaths margin y row =
    let
        lastIndex =
            List.length row - 1

        step ( x, cell ) ( start, acc ) =
            case start of
                Just s ->
                    if not cell then
                        ( Nothing
                        , acc ++ [ "M" ++ String.fromInt (s + margin) ++ " " ++ String.fromInt (y + margin) ++ "h" ++ String.fromInt (x - s) ++ "v1H" ++ String.fromInt (s + margin) ++ "z" ]
                        )

                    else if x == lastIndex then
                        ( start
                        , acc ++ [ "M" ++ String.fromInt (s + margin) ++ "," ++ String.fromInt (y + margin) ++ " h" ++ String.fromInt (x + 1 - s) ++ "v1H" ++ String.fromInt (s + margin) ++ "z" ]
                        )

                    else
                        ( start, acc )

                Nothing ->
                    if x == lastIndex then
                        if cell then
                            ( start
                            , acc ++ [ "M" ++ String.fromInt (x + margin) ++ "," ++ String.fromInt (y + margin) ++ " h1v1H" ++ String.fromInt (x + margin) ++ "z" ]
                            )

                        else
                            ( start, acc )

                    else if cell then
                        ( Just x, acc )

                    else
                        ( start, acc )
    in
    row
        |> List.indexedMap Tuple.pair
        |> List.foldl step ( Nothing, [] )
        |> Tuple.second
        |> String.concat


toEcc : ErrorCorrectionLevel -> Qrcodegen.Ecc
toEcc level =
    case level of
        L ->
            Qrcodegen.Low

        M ->
            Qrcodegen.Medium

        Q ->
            Qrcodegen.Quartile

        H ->
            Qrcodegen.High


paddingToString : Padding -> String
paddingToString padding =
    case padding of
        Px n ->
            px n

        Custom string ->
            string


px : Int -> String
px n =
    String.fromInt n ++ "px"
