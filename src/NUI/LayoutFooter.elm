module NUI.LayoutFooter exposing
    ( Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `LayoutFooter`, rebuilt on elm-ui.

    import NUI.LayoutFooter exposing (defaults)

    NUI.LayoutFooter.view theme
        { defaults | bordered = True }
        [ Element.text "Footer" ]

The element carries the `.n-layout-footer` BEM classes and Naive UI's `--n-*`
custom properties (`footerColor` / `footerColorInverted` etc. from
`NUI.Theme.Layout`); `NUI.Css` ships Naive UI's exact CSS.

**Divergence (visibility chrome):** like `NUI.LayoutHeader`, the non-inverted
footer additionally carries an inline light background (`#f7f7fa`) + padding so
the region reads as part of the app shell on white surfaces (upstream's light
`footerColor` is `rgb(250, 250, 252)`, visually indistinguishable there).
Inverted footers keep the pure `--n-*` theming.

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
            ([ "n-layout-footer"
             , "n-layout-footer--" ++ positionClass opts.position ++ "-positioned"
             ]
                ++ I.classIf opts.bordered "n-layout-footer--bordered"
            )
         , I.cssVars (cssVars theme opts ++ regionChrome opts)
         ]
            ++ opts.attributes
        )
        children


{-| The raw `--n-*` custom properties a footer with these options attaches.
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
            v.footerColorInverted

        else
            v.footerColor
      )
    , ( "--n-text-color"
      , if opts.inverted then
            v.textColorInverted

        else
            v.textColor
      )
    , ( "--n-border-color"
      , if opts.inverted then
            v.footerBorderColorInverted

        else
            v.footerBorderColor
      )
    ]


{-| The non-inverted region's visibility chrome (see the module docstring);
merged into the element's inline style after the `--n-*` vars (`view` only —
`cssVarsFor` stays the pure `--n-*` record).
-}
regionChrome : Options msg -> List ( String, String )
regionChrome opts =
    if opts.inverted then
        []

    else
        [ ( "background-color", "#f7f7fa" )
        , ( "padding", "12px 24px" )
        ]
