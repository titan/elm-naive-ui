module NUI.Countdown exposing (Options, TimeInfo, defaults, view)

{-| Naive UI's `Countdown`, rebuilt on elm-ui.

    import NUI.Countdown exposing (defaults)

    NUI.Countdown.view theme
        { defaults | distance = 90000, precision = 1 }
        []

    -- custom rendering
    NUI.Countdown.view theme
        { defaults
            | distance = 5000
            , render = Just (\info -> Element.text (String.fromInt info.seconds ++ "s left"))
        }
        []

**Runtime.** Upstream runs its own timer and derives the remaining `distance`
from `duration` / `elapsed` / `performance.now()`. This library is pure, so the
caller owns the clock and passes the remaining `distance` in milliseconds; the
view reproduces upstream's `render()` exactly — including the per-precision
round-up (`+999` / `+99` / `+9`) and the default display string.

Countdown carries no classes and no `--n-*` variables of its own.

@docs Options, TimeInfo, defaults, view

-}

import Element exposing (Element)
import NUI.Theme exposing (Theme)


{-| The decomposed remaining time, exactly as upstream's `CountdownTimeInfo`.
-}
type alias TimeInfo =
    { hours : Int
    , minutes : Int
    , seconds : Int
    , milliseconds : Int
    }


{-| The countdown's options: the remaining `distance` in milliseconds (the
caller owns the clock), the `precision` (0 = seconds, 1 = tenths, 2 =
hundredths, 3 = full milliseconds) driving both rounding and display, an
optional `render` replacing the default `HH:MM:SS[.mmm]` string, and root
`attributes` (the Vue fallthrough seam).
-}
type alias Options msg =
    { distance : Int
    , precision : Int
    , render : Maybe (TimeInfo -> Element msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Zero distance, precision 0, no custom render — displays `00:00:00`.
-}
defaults : Options msg
defaults =
    { distance = 0
    , precision = 0
    , render = Nothing
    , attributes = []
    }


{-| The countdown element — a bare `Element.el` carrying the fallthrough
attributes and either the custom `render` output or the default display
string (upstream's `render()` math: per-precision `+999`/`+99`/`+9`
round-up, then truncated milliseconds). The child list is ignored — upstream
renders no default slot.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ opts _ =
    Element.el opts.attributes <|
        case opts.render of
            Just render ->
                render (timeInfo opts.precision opts.distance)

            Nothing ->
                Element.text (displayValue opts.precision (timeInfo opts.precision opts.distance))


{-| Upstream's `render()`: the `distance` adjustment and millisecond rounding
depend on `precision`.
-}
timeInfo : Int -> Int -> TimeInfo
timeInfo precision distance =
    let
        base =
            decompose (distance + adjust precision)
    in
    case precision of
        0 ->
            { base | milliseconds = 0 }

        1 ->
            { base | milliseconds = (base.milliseconds // 100) * 100 }

        2 ->
            { base | milliseconds = (base.milliseconds // 10) * 10 }

        _ ->
            base


adjust : Int -> Int
adjust precision =
    case precision of
        0 ->
            999

        1 ->
            99

        2 ->
            9

        _ ->
            0


decompose : Int -> TimeInfo
decompose distance =
    { hours = distance // 3600000
    , minutes = modBy 3600000 distance // 60000
    , seconds = modBy 60000 distance // 1000
    , milliseconds = modBy 1000 distance
    }


{-| Upstream's `getDisplayValue` — `HH:MM:SS` at precision 0, otherwise
`HH:MM:SS.mmm` with `precision` fractional digits.
-}
displayValue : Int -> TimeInfo -> String
displayValue precision info =
    let
        base =
            pad 2 info.hours ++ ":" ++ pad 2 info.minutes ++ ":" ++ pad 2 info.seconds
    in
    if precision == 0 then
        base

    else
        base ++ "." ++ pad precision (info.milliseconds // divisor precision)


divisor : Int -> Int
divisor precision =
    if precision == 1 then
        100

    else if precision == 2 then
        10

    else
        1


pad : Int -> Int -> String
pad width n =
    String.padLeft width '0' (String.fromInt n)
