module NUI.IconWrapper exposing (Length(..), Options, cssVarsFor, defaults, view)

{-| Naive UI's `IconWrapper`, rebuilt on elm-ui.

    import NUI.IconWrapper exposing (defaults)

    NUI.IconWrapper.view theme NUI.IconWrapper.defaults
        [ myIcon ]

    NUI.IconWrapper.view theme
        { defaults
            | size = NUI.IconWrapper.Px 18
            , color = Just "red"
        }
        [ myIcon ]

The element carries the `.n-icon-wrapper` class and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS. Pass the icon (usually an
`NUI.Icon.view`) as the child.

@docs Length, Options, cssVarsFor, defaults, view

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.IconWrapper as IconWrapperTheme


{-| A CSS length — a pixel count or a raw CSS length (`"50%"`).
-}
type Length
    = Px Int
    | Custom String


{-| The wrapper options — Naive UI's props: the `size` (both `width` and
`height`), the `borderRadius`, the `color` (`background-color`) and
`iconColor` (`color`) overrides, and `attributes`.
-}
type alias Options msg =
    { size : Length
    , borderRadius : Length
    , color : Maybe String
    , iconColor : Maybe String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults: a 24px wrapper with a 6px radius, no background or
icon colour, no extra attributes.
-}
defaults : Options msg
defaults =
    { size = Px 24
    , borderRadius = Px 6
    , color = Nothing
    , iconColor = Nothing
    , attributes = []
    }


{-| The `n-icon-wrapper` element — a row carrying the `--n-*` vars plus the
inline `height`/`width`/`border-radius` (and `background-color`/`color` when
set), with the icon children verbatim.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.row
        ([ I.classes [ "n-icon-wrapper" ]
         , I.cssVars (cssVarsFor theme ++ inlineStyle opts)
         ]
            ++ opts.attributes
        )
        children


{-| The raw `--n-*` custom properties the wrapper attaches. Exposed so the
`--n-*` output can be asserted directly; `view` uses exactly this.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            IconWrapperTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-color", v.color )
    , ( "--n-icon-color", v.iconColor )
    ]


{-| The plain declarations upstream merges into the same `style` attribute as
the vars: `height` / `width` from `size`, `border-radius` from `borderRadius`,
and — when set — `background-color` from `color` and `color` from `iconColor`.
-}
inlineStyle : Options msg -> List ( String, String )
inlineStyle opts =
    [ ( "height", formatLength opts.size )
    , ( "width", formatLength opts.size )
    , ( "border-radius", formatLength opts.borderRadius )
    ]
        ++ List.filterMap identity
            [ Maybe.map (\c -> ( "background-color", c )) opts.color
            , Maybe.map (\c -> ( "color", c )) opts.iconColor
            ]


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
