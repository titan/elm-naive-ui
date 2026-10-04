module NUI.Divider exposing
    ( Options
    , TitlePlacement(..)
    , defaults
    , view
    )

{-| Naive UI's `Divider`, rebuilt on elm-ui.

    import NUI.Divider exposing (defaults)

    NUI.Divider.view theme NUI.Divider.defaults []

    NUI.Divider.view theme
        { defaults
            | titlePlacement = NUI.Divider.Left
        }
        [ Element.text "Title" ]

The element carries the `.n-divider` BEM classes and Naive UI's `--n-*` custom
properties; `NUI.Css` ships Naive UI's exact CSS.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Divider as DividerTheme


{-| Where the title sits on a horizontal divider (Naive UI's `title-placement`).
-}
type TitlePlacement
    = Left
    | Center
    | Right


type alias Options msg =
    { vertical : Bool
    , titlePlacement : TitlePlacement
    , dashed : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { vertical = False
    , titlePlacement = Center
    , dashed = False
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        v =
            DividerTheme.vars theme

        hasTitle =
            not (List.isEmpty children)

        -- `.n-divider__line` is `width: 100%` and relies on the browser's
        -- default `flex-shrink: 1` to share the row with the title. elm-ui's
        -- `.s { flex-shrink: 0 }` (one class selector, and Naive UI declares no
        -- `flex-shrink` here) freezes both lines at 100% instead, overflowing
        -- the flex row so the title is pushed past the right edge — only the
        -- LEFT placement survives (its left line is pinned to 28px). Restore
        -- the shrink so every placement renders line–title–line.
        line modifier =
            Element.el
                [ I.classes [ "n-divider__line", "n-divider__line--" ++ modifier ]
                , I.cssVars [ ( "flex-shrink", "1" ) ]
                ]
                Element.none

        title =
            Element.row [ I.classes [ "n-divider__title" ] ] children

        body =
            if opts.vertical then
                []

            else
                line "left"
                    :: (if hasTitle then
                            [ title, line "right" ]

                        else
                            []
                       )

        placementClass =
            if hasTitle then
                [ "n-divider--title-position-" ++ placementName opts.titlePlacement ]

            else
                []

        classes =
            [ "n-divider" ]
                ++ I.classIf opts.vertical "n-divider--vertical"
                ++ I.classIf (not hasTitle) "n-divider--no-title"
                ++ I.classIf opts.dashed "n-divider--dashed"
                ++ placementClass

        vars =
            [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
            , ( "--n-color", v.color )
            , ( "--n-text-color", v.textColor )
            , ( "--n-font-weight", v.fontWeight )
            ]
    in
    Element.row
        ([ I.classes classes
         , I.cssVars vars
         , Element.htmlAttribute (HA.attribute "role" "separator")
         ]
            ++ opts.attributes
        )
        body


placementName : TitlePlacement -> String
placementName placement =
    case placement of
        Left ->
            "left"

        Center ->
            "center"

        Right ->
            "right"
