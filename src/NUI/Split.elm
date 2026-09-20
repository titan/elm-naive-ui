module NUI.Split exposing
    ( Direction(..)
    , Options
    , Size(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Split`, rebuilt on elm-ui.

    import NUI.Split exposing (defaults)

    NUI.Split.view theme
        { defaults
            | size = NUI.Split.Ratio 0.4
            , pane1 = [ Element.text "Left" ]
            , pane2 = [ Element.text "Right" ]
        }

The element carries the `.n-split` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

**Runtime.** Upstream turns drag gestures into a new `size` (`px` or a ratio)
and flips the resize trigger's hover class while dragging. This library is pure,
so the caller owns `size` and `dragging`; the rendered markup (panes, trigger
wrapper, trigger) and the computed `flex` / trigger-size styles match upstream.

**Theme.** Naive UI's split theme is two common-variable lookups
(`resizableTriggerColor` = `borderColor`, `resizableTriggerColorHover` =
`primaryColorHover`) and its dark theme omits `self`, so this module reads them
from `theme.common` directly rather than from a generated theme module.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)


{-| Which way the panes are laid out (Naive UI's `direction`).
-}
type Direction
    = Horizontal
    | Vertical


{-| Pane 1's size — upstream's `size` prop: a `number` is a fraction of the
container (`Ratio 0.5`), a `string` is any CSS length (`Length "300px"`).
-}
type Size
    = Ratio Float
    | Length String


type alias Options msg =
    { direction : Direction
    , size : Size
    , resizeTriggerSize : Int
    , disabled : Bool
    , dragging : Bool
    , pane1 : List (Element msg)
    , pane2 : List (Element msg)
    , pane1Style : List ( String, String )
    , pane2Style : List ( String, String )
    , resizeTrigger : Maybe (Element msg)
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { direction = Horizontal
    , size = Ratio 0.5
    , resizeTriggerSize = 3
    , disabled = False
    , dragging = False
    , pane1 = []
    , pane2 = []
    , pane1Style = []
    , pane2Style = []
    , resizeTrigger = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> Element msg
view theme opts =
    let
        horizontal =
            opts.direction == Horizontal

        triggerPx =
            String.fromInt opts.resizeTriggerSize ++ "px"

        firstPaneStyle =
            case opts.size of
                Length length ->
                    [ ( "flex", "0 0 " ++ length ) ]

                Ratio fraction ->
                    let
                        scaled =
                            fraction * 100

                        px =
                            toFloat opts.resizeTriggerSize * scaled / 100
                    in
                    [ ( "flex"
                      , "0 0 calc("
                            ++ String.fromFloat scaled
                            ++ "% - "
                            ++ String.fromFloat px
                            ++ "px)"
                      )
                    ]

        triggerStyle =
            if horizontal then
                [ ( "width", triggerPx ), ( "height", "100%" ) ]

            else
                [ ( "width", "100%" ), ( "height", triggerPx ) ]

        wrapperStyle =
            if horizontal then
                [ ( "width", triggerPx ), ( "cursor", "col-resize" ) ]

            else
                [ ( "height", triggerPx ), ( "cursor", "row-resize" ) ]

        defaultTrigger =
            Element.el
                [ I.classes
                    ("n-split__resize-trigger"
                        :: I.classIf opts.dragging "n-split__resize-trigger--hover"
                    )
                , I.cssVars triggerStyle
                ]
                Element.none

        triggerWrapper =
            if opts.disabled then
                []

            else
                [ Element.row
                    [ I.classes [ "n-split__resize-trigger-wrapper" ]
                    , I.cssVars wrapperStyle
                    ]
                    [ Maybe.withDefault defaultTrigger opts.resizeTrigger ]
                ]
    in
    Element.row
        (I.classes
            ("n-split"
                :: [ "n-split--" ++ directionClass opts.direction ]
            )
            :: I.cssVars (cssVarsFor theme)
            :: opts.attributes
        )
        (Element.column
            [ I.classes [ "n-split-pane-1" ]
            , I.cssVars (firstPaneStyle ++ opts.pane1Style)
            ]
            opts.pane1
            :: triggerWrapper
            ++ [ Element.column
                    ([ I.classes [ "n-split-pane-2" ] ]
                        ++ maybeStyle opts.pane2Style
                    )
                    opts.pane2
               ]
        )


directionClass : Direction -> String
directionClass direction =
    case direction of
        Horizontal ->
            "horizontal"

        Vertical ->
            "vertical"


maybeStyle : List ( String, String ) -> List (Element.Attribute msg)
maybeStyle pairs =
    if List.isEmpty pairs then
        []

    else
        [ I.cssVars pairs ]


{-| The split's `--n-*` custom properties (they do not depend on the options).
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-resize-trigger-color", theme.common.borderColor )
    , ( "--n-resize-trigger-color-hover", theme.common.primaryColorHover )
    ]
