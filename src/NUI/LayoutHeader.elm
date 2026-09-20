module NUI.LayoutHeader exposing
    ( Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `LayoutHeader`, rebuilt on elm-ui.

    import NUI.LayoutHeader exposing (defaults)

    NUI.LayoutHeader.view theme
        { defaults | bordered = True }
        [ Element.text "Header" ]

The element carries the `.n-layout-header` BEM classes and Naive UI's `--n-*`
custom properties (`headerColor` / `headerColorInverted` etc. from
`NUI.Theme.Layout`); `NUI.Css` ships Naive UI's exact CSS.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Layout exposing (Position(..), positionClass)
import NUI.Theme exposing (Theme)
import NUI.Theme.Layout as LayoutTheme


type alias Options msg =
    { position : Position
    , bordered : Bool
    , inverted : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { position = Static
    , bordered = False
    , inverted = False
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.column
        ([ I.classes
            ([ "n-layout-header"
             , "n-layout-header--" ++ positionClass opts.position ++ "-positioned"
             ]
                ++ I.classIf opts.bordered "n-layout-header--bordered"
            )
         , I.cssVars (cssVars theme opts)
         ]
            ++ opts.attributes
        )
        children


{-| The raw `--n-*` custom properties a header with these options attaches.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    cssVars theme opts


cssVars : Theme -> Options msg -> List ( String, String )
cssVars theme opts =
    let
        v =
            LayoutTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-color"
      , if opts.inverted then
            v.headerColorInverted

        else
            v.headerColor
      )
    , ( "--n-text-color"
      , if opts.inverted then
            v.textColorInverted

        else
            v.textColor
      )
    , ( "--n-border-color"
      , if opts.inverted then
            v.headerBorderColorInverted

        else
            v.headerBorderColor
      )
    ]
