module NUI.Space exposing (Align(..), Direction(..), Justify(..), Options, SpaceSize(..), defaults, view)

{-| Naive UI's `Space`, rebuilt on elm-ui.

    NUI.Space.view theme
        NUI.Space.defaults
        [ NUI.Button.view theme NUI.Button.defaults [ Element.text "Ok" ] ]

Naive UI's Space ships no CSS — it is a plain flex container styled inline
(`display`, `flex-direction`, `justify-content`, `align-items`, `flex-wrap`,
`gap`). This module reproduces exactly those declarations as inline styles on an
elm-ui `row`/`column`, so the rendered layout matches Naive UI's
flex-gap-supported output (every modern browser).

**Wrapper divergence.** Upstream defaults to `wrapItem: true`, wrapping every
child in a `div[role=none]` (the `itemClass` / `itemStyle` carriers, and the
pre-flex-gap margin layout). This port renders the children straight into the
flex container — equivalent to upstream's `wrapItem: false` +
`internalUseGap` shape (the one modern browsers take anyway through the
`ensureSupportFlexGap` probe), so `wrapItem` / `itemClass` / `itemStyle` are
not modelled. An empty child list renders `Element.none`, like upstream's
`!children.length → null`.

@docs Align, Direction, Justify, Options, SpaceSize, defaults, view

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Space as SpaceTheme


{-| Naive UI's `vertical` prop.
-}
type Direction
    = Horizontal
    | Vertical


{-| Naive UI's `align` prop (flex `align-items`). `Nothing` omits the
declaration, falling back to the flex default (`stretch`), like Naive UI.
-}
type Align
    = Stretch
    | Baseline
    | Start
    | End
    | Center
    | FlexStart
    | FlexEnd


{-| Naive UI's `justify` prop (flex `justify-content`); `start`/`end` map to
`flex-start`/`flex-end` as in Naive UI.
-}
type Justify
    = JustifyStart
    | JustifyEnd
    | JustifyCenter
    | SpaceAround
    | SpaceBetween
    | SpaceEvenly


{-| Naive UI's `size`: a preset resolved from the Space theme (`small`, `medium`,
`large` — Naive UI defines no `tiny` gap) or an explicit gap in pixels
(single number or `( row, column )` pair).
-}
type SpaceSize
    = Small
    | Medium
    | Large
    | Number Int
    | Number2 Int Int


{-| The space options — Naive UI's props one-to-one: `direction` + `reverse`
(the flex-direction), `size` (the gap), `align` (`Nothing` omits the
declaration, the flex default — upstream's absent prop), `wrap` (only
effective horizontally, like upstream's `!wrap || vertical → nowrap`),
`justify`, `inline`, `rtl`, and `attributes`. See the module docstring for
the unmodelled `wrapItem` wrapper.
-}
type alias Options msg =
    { direction : Direction
    , size : SpaceSize
    , align : Maybe Align
    , wrap : Bool
    , justify : Justify
    , reverse : Bool
    , inline : Bool
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults: a horizontal wrapping row at the `medium` gap, no
align override, start-justified, block-level, LTR.
-}
defaults : Options msg
defaults =
    { direction = Horizontal
    , size = Medium
    , align = Nothing
    , wrap = True
    , justify = JustifyStart
    , reverse = False
    , inline = False
    , rtl = False
    , attributes = []
    }


{-| The `n-space` element — the flex container with Naive UI's exact inline
declarations (display, flex-direction, justify-content, flex-wrap, gap,
align-items when set) and the `--rtl` marker. `Element.none` for an empty
child list, like upstream's null render.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    if List.isEmpty children then
        Element.none

    else
        let
            v =
                SpaceTheme.vars theme

            ( rowGap, colGap ) =
                gapOf opts.size v

            styles =
                [ HA.style "display"
                    (if opts.inline then
                        "inline-flex"

                     else
                        "flex"
                    )
                , HA.style "flex-direction" (directionCss opts.direction opts.reverse)
                , HA.style "justify-content" (justifyCss opts.justify)
                , HA.style "flex-wrap"
                    (if opts.wrap && opts.direction == Horizontal then
                        "wrap"

                     else
                        "nowrap"
                    )
                , HA.style "gap" <|
                    String.fromInt rowGap
                        ++ "px "
                        ++ String.fromInt colGap
                        ++ "px"
                ]
                    ++ (case opts.align of
                            Just a ->
                                [ HA.style "align-items" (alignCss a) ]

                            Nothing ->
                                []
                       )
        in
        (case opts.direction of
            Horizontal ->
                Element.row

            Vertical ->
                Element.column
        )
            ([ I.classes ("n-space" :: I.classIf opts.rtl "n-space--rtl")
             , Element.htmlAttribute (HA.attribute "role" "none")
             ]
                ++ List.map Element.htmlAttribute styles
                ++ opts.attributes
            )
            children


directionCss : Direction -> Bool -> String
directionCss direction reverse =
    case ( direction, reverse ) of
        ( Horizontal, False ) ->
            "row"

        ( Horizontal, True ) ->
            "row-reverse"

        ( Vertical, False ) ->
            "column"

        ( Vertical, True ) ->
            "column-reverse"


justifyCss : Justify -> String
justifyCss justify =
    case justify of
        JustifyStart ->
            "flex-start"

        JustifyEnd ->
            "flex-end"

        JustifyCenter ->
            "center"

        SpaceAround ->
            "space-around"

        SpaceBetween ->
            "space-between"

        SpaceEvenly ->
            "space-evenly"


alignCss : Align -> String
alignCss align =
    case align of
        Stretch ->
            "stretch"

        Baseline ->
            "baseline"

        Start ->
            "start"

        End ->
            "end"

        Center ->
            "center"

        FlexStart ->
            "flex-start"

        FlexEnd ->
            "flex-end"


{-| Naive UI resolves the preset through `createKey('gap', size)` and `getGap`,
yielding `{ vertical, horizontal }` in pixels.
-}
gapOf : SpaceSize -> SpaceTheme.Vars -> ( Int, Int )
gapOf size v =
    case size of
        Number n ->
            ( n, n )

        Number2 vertical horizontal ->
            ( vertical, horizontal )

        Small ->
            parseGap v.gapSmall

        Medium ->
            parseGap v.gapMedium

        Large ->
            parseGap v.gapLarge


parseGap : String -> ( Int, Int )
parseGap value =
    case
        String.split " " value
            |> List.map (String.dropRight 2)
            |> List.filterMap String.toInt
    of
        [ row, col ] ->
            ( row, col )

        [ only ] ->
            ( only, only )

        _ ->
            ( 0, 0 )
