module NUI.Icon exposing (Depth(..), Length(..), Options, cssVarsFor, defaults, view)

{-| Naive UI's `Icon`, rebuilt on elm-ui.

    import NUI.Icon exposing (defaults)

    NUI.Icon.view theme NUI.Icon.defaults
        [ mySvg ]

    NUI.Icon.view theme
        { defaults
            | size = Just (NUI.Icon.Px 40)
            , depth = Just NUI.Icon.Depth2
        }
        [ mySvg ]

The element carries the `.n-icon` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS. Pass the glyph itself —
usually an `svg` — as the child (upstream's `component` prop is the same thing
one level up).

**Divergences.** elm-ui renders the root as a `<div>` rather than upstream's
`<i>`; `.n-icon` is targeted by class, so all of Naive UI's rules apply — the
only visible difference is `<i>`'s browser-default italic for text children.
Upstream's `depth` also accepts the strings `'1'`–`'5'`; those select the same
opacities, which `Depth` covers. Upstream's dev-only "don't wrap `n-icon`
inside `n-icon`" warning is not reproduced.

@docs Depth, Length, Options, cssVarsFor, defaults, view

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Icon as IconTheme


{-| Naive UI's `depth` (`1`–`5`): when set, the icon takes the theme's colour
at the matching opacity step (`opacity1Depth`…`opacity5Depth`) and gains the
`n-icon--depth` / `n-icon--color-transition` classes.
-}
type Depth
    = Depth1
    | Depth2
    | Depth3
    | Depth4
    | Depth5


{-| A CSS length — a pixel count or a raw CSS length (`"1.5em"`).
-}
type Length
    = Px Int
    | Custom String


{-| The icon options — Naive UI's props: the `depth` (theme colour at an
opacity step), the `size` (a `font-size`, upstream's `size` prop), the `color`
override, and `attributes`.
-}
type alias Options msg =
    { depth : Maybe Depth
    , size : Maybe Length
    , color : Maybe String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults: no depth, no size, no colour, no extra attributes
(theme sizing only).
-}
defaults : Options msg
defaults =
    { depth = Nothing
    , size = Nothing
    , color = Nothing
    , attributes = []
    }


{-| The `n-icon` element — a `role="img"` row carrying the `--depth` /
`--color-transition` classes under a depth, the `--n-*` vars plus the
optional inline `font-size` / `color`, and the glyph children verbatim.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        classes =
            [ "n-icon" ]
                ++ (case opts.depth of
                        Just _ ->
                            [ "n-icon--depth", "n-icon--color-transition" ]

                        Nothing ->
                            []
                   )
    in
    Element.row
        ([ I.classes classes
         , I.cssVars (cssVarsFor theme opts ++ inlineStyle opts)
         , Element.htmlAttribute (HA.attribute "role" "img")
         ]
            ++ opts.attributes
        )
        children


{-| The raw `--n-*` custom properties an icon with these options attaches
(before `NUI.Internal.cssVars` drops empty values — upstream sets `--n-color`
and `--n-opacity` to `''` when `depth` is unset, which the DOM drops too, but
`--n-bezier` is always emitted). Exposed so the `--n-*` output can be asserted
directly; `view` uses exactly this.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            IconTheme.vars theme
    in
    ( "--n-bezier", theme.common.cubicBezierEaseInOut )
        :: (case opts.depth of
                Just depth ->
                    [ ( "--n-color", v.color )
                    , ( "--n-opacity", opacityOf depth v )
                    ]

                Nothing ->
                    [ ( "--n-color", "" )
                    , ( "--n-opacity", "" )
                    ]
           )


{-| The plain declarations upstream's `mergedStyle` merges into the same
`style` attribute as the vars: `font-size` from `size` and `color` from
`color`, each omitted when unset.
-}
inlineStyle : Options msg -> List ( String, String )
inlineStyle opts =
    List.filterMap identity
        [ Maybe.map (\s -> ( "font-size", formatLength s )) opts.size
        , Maybe.map (\c -> ( "color", c )) opts.color
        ]


{-| Upstream's `` self[`opacity${depth}Depth`] ``.
-}
opacityOf : Depth -> IconTheme.Vars -> String
opacityOf depth v =
    case depth of
        Depth1 ->
            v.opacity1Depth

        Depth2 ->
            v.opacity2Depth

        Depth3 ->
            v.opacity3Depth

        Depth4 ->
            v.opacity4Depth

        Depth5 ->
            v.opacity5Depth


formatLength : Length -> String
formatLength length =
    case length of
        Px n ->
            if n == 0 then
                "0"

            else
                String.fromInt n ++ "px"

        Custom s ->
            -- Upstream's `formatLength`: a pure-number string gains a `px` unit
            -- (`"40"` -> `"40px"`); anything else passes through.
            if isPureNumber s then
                case String.toFloat s of
                    Just num ->
                        if num == 0 then
                            "0"

                        else
                            String.fromFloat num ++ "px"

                    Nothing ->
                        s

            else
                s


isPureNumber : String -> Bool
isPureNumber s =
    s /= "" && String.all (\c -> Char.isDigit c || c == '.') s
