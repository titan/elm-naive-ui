module NUI.Ellipsis exposing (Options, defaults, view)

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

**Divergence (single-line clamp):** upstream's single-line mode relies on
`text-overflow: ellipsis` with `white-space: nowrap` inheriting into the slot
text. elm-ui wraps every text child in its own `div.t` and its stylesheet pins
`.s.p .t { white-space: normal }` there, so the inherited `nowrap` never
reaches the text and the paragraph wraps out to four lines. This port also
emits `-webkit-line-clamp: 1` (+ the `-webkit-inline-box` display the clamp
needs) for the same end state — one line, ellipsis glyph — through the same
mechanism the multi-line rows already use (which the `.t` wrapper cannot
defeat).

@docs Options, defaults, view

-}

import Element exposing (Element)
import Element.Events as Events
import NUI.Internal as I
import NUI.Theme exposing (Theme)


{-| The ellipsis options — Naive UI's props plus the caller-owned `expanded`:
`lineClamp` (upstream's `lineClamp`, `Nothing` = the single-line mode), the
`expanded` flag (upstream's internal state), `expandOnClick` (upstream's
`expand-trigger: 'click'`), `onToggle` fired on that click, and `attributes`.
-}
type alias Options msg =
    { lineClamp : Maybe Int
    , expanded : Bool
    , expandOnClick : Bool
    , onToggle : Maybe msg
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults: no clamp (single-line mode), collapsed, no click
expansion, no toggle message, no extra attributes.
-}
defaults : Options msg
defaults =
    { lineClamp = Nothing
    , expanded = False
    , expandOnClick = False
    , onToggle = Nothing
    , attributes = []
    }


{-| The `n-ellipsis` element — a paragraph carrying `--line-clamp` when
`lineClamp` is set (plus `--cursor-pointer` under `expandOnClick`), and the
inline style upstream computes: nothing once `expanded`, the `-webkit-line-clamp`
when clamped, or the single-line `text-overflow: ellipsis` fallback otherwise.
-}
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
                [ ( "text-overflow", "ellipsis" )
                , ( "display", "-webkit-inline-box" )
                , ( "-webkit-box-orient", "vertical" )
                , ( "-webkit-line-clamp", "1" )
                ]

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
