module NUI.Ellipsis exposing
    ( Options
    , defaults
    , view
    )

{-| Naive UI's `Ellipsis`, rebuilt on elm-ui.

    import NUI.Ellipsis exposing (defaults)

    NUI.Ellipsis.view theme
        { defaults | lineClamp = Just 2 }
        [ Element.text "Long text that will be clamped to two lines…" ]

    NUI.Ellipsis.view theme
        { defaults | expandOnClick = True, onToggle = Just Toggle }
        [ Element.text "Click to expand or collapse" ]

The element carries the `.n-ellipsis` BEM classes and, and `NUI.Css` ships Naive
UI's exact CSS.

**State.** Upstream tracks `expanded` internally and measures the element to decide
whether a tooltip is needed; this library is pure, so the caller owns `expanded`
and the view emits the same classes and inline style upstream computes
(`text-overflow: ellipsis`, or `-webkit-line-clamp` at the clamp). Countdown-style
tooltip and cursor-measurement behavior is not reproduced.

Countdown-style measurement aside, Ellipsis declares **no** `--n-*` variables.

-}

import Element exposing (Element)
import Element.Events as Events
import NUI.Internal as I
import NUI.Theme exposing (Theme)


type alias Options msg =
    { lineClamp : Maybe Int
    , expanded : Bool
    , expandOnClick : Bool
    , onToggle : Maybe msg
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { lineClamp = Nothing
    , expanded = False
    , expandOnClick = False
    , onToggle = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ opts children =
    let
        hasLineClamp =
            opts.lineClamp /= Nothing

        classes =
            [ "n-ellipsis" ]
                ++ I.classIf hasLineClamp "n-ellipsis--line-clamp"
                ++ I.classIf opts.expandOnClick "n-ellipsis--cursor-pointer"

        style =
            if opts.expanded then
                []

            else if hasLineClamp then
                [ ( "-webkit-line-clamp", String.fromInt (Maybe.withDefault 0 opts.lineClamp) ) ]

            else
                [ ( "text-overflow", "ellipsis" ) ]

        clickAttrs =
            if opts.expandOnClick then
                case opts.onToggle of
                    Just msg ->
                        [ Events.onClick msg ]

                    Nothing ->
                        []

            else
                []
    in
    Element.paragraph
        ([ I.classes classes ]
            ++ (if List.isEmpty style then
                    []

                else
                    [ I.cssVars style ]
               )
            ++ clickAttrs
            ++ opts.attributes
        )
        children
