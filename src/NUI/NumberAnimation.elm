module NUI.NumberAnimation exposing (Formatted, Options, defaults, view, easeOut, tweenValue, roundTo, formatToFixed, format, groupDigits)

{-| Naive UI's `NumberAnimation`, rebuilt on elm-ui.

    import NUI.NumberAnimation exposing (defaults)

    NUI.NumberAnimation.view theme
        { defaults | to = 110, from = 10, duration = 3000, elapsed = 1500 }
        []

Upstream's `formattedValueRef`, directly assertable:

    import NUI.NumberAnimation exposing (defaults)

    NUI.NumberAnimation.format
        { defaults
            | to = 1234567.5
            , precision = 1
            , showSeparator = True
            , elapsed = 2000
        }
    -- { integer = "1,234,567", decimal = Just "5", decimalSeparator = "." }

**Runtime.** Upstream owns a `requestAnimationFrame` tween (`utils.ts`'s
`tween`, plus the `play` / `active` / `onFinish` props) and derives the
displayed value from `performance.now()`. This library is pure, so the caller
owns the clock — the same contract as `NUI.Countdown` — and passes `elapsed`,
the milliseconds since the animation started. `tweenValue` maps that onto
upstream's exact expression, including the
`elapsedTime = Math.min(current - startTime, duration)` clamp and the exact
`to` that upstream's `onFinish` assigns once that clamp bites: `elapsed = 0`
displays `from`, any `elapsed >= duration` displays `to` (and a `duration`
of `0` finishes immediately, as upstream's `elapsedTime === duration` does).

`elapsed` was chosen over an already-resolved `value` so that `from` / `to` /
`duration` stay live inside the options — the record remains the single
source of truth and the caller supplies only what a clock actually knows.
Upstream's `active` and `play()` collapse into when the caller starts
advancing `elapsed`, and `onFinish` into noticing `elapsed >= duration`.

Elm has no `Intl`, so the locale-derived strings are inputs too:
`decimalSeparator` and `groupSeparator` default to `"."` / `","` — en-US,
Naive UI's fallback locale, and zh-CN agree on both. Grouping is fixed
3-digit thousands; locales that group differently (hi-IN's `12,34,567`) have
no equivalent.

NumberAnimation carries no classes and no `--n-*` variables of its own
(like `NUI.Countdown`).

@docs Formatted, Options, defaults, view, easeOut, tweenValue, roundTo, formatToFixed, format, groupDigits

-}

import Element exposing (Element)
import NUI.Theme exposing (Theme)


{-| Upstream's `formattedValueRef`: the three strings its `render()` joins —
`integer`, then `decimalSeparator` and `decimal` when a fractional part
exists. `decimal` is `Nothing` at `precision = 0` (upstream's `undefined`),
but `"50"` at `precision = 2` is a real, truthy part — `16.50` renders.
-}
type alias Formatted =
    { integer : String
    , decimal : Maybe String
    , decimalSeparator : String
    }


{-| `to`, `from`, `duration`, `precision` and `showSeparator` mirror the
upstream props (same defaults). `elapsed` is the caller-owned clock and
`decimalSeparator` / `groupSeparator` the caller-owned locale pieces — see
the module docs. `attributes` land on the root element; upstream's `locale`
prop is what the two separator strings replace.
-}
type alias Options msg =
    { to : Float
    , from : Float
    , duration : Float
    , precision : Int
    , showSeparator : Bool
    , elapsed : Float
    , decimalSeparator : String
    , groupSeparator : String
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream's prop defaults (`duration: 2000`, `precision: 0`, no
separator, `%`-style unit semantics — `to` / `from` both `0`), plus the
port's runtime inputs at rest: `elapsed = 0` (nothing has ticked) and the
en-US separators `"."` / `","`.
-}
defaults : Options msg
defaults =
    { to = 0
    , from = 0
    , duration = 2000
    , precision = 0
    , showSeparator = False
    , elapsed = 0
    , decimalSeparator = "."
    , groupSeparator = ","
    , attributes = []
    }


{-| Upstream's `render()`: `[integer, decimal ? decimalSeparator : null,
decimal]` — one text run. Upstream returns bare text vnodes (a fragment);
here that becomes the single elm-ui element, as in `NUI.Countdown`.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ opts _ =
    Element.el opts.attributes (Element.text (display (format opts)))



-- tween (utils.ts) ---------------------------------------------------------------


{-| Upstream's easing, `1 - (1 - t) ** 5` (easeOutQuint). `easeOut 0 == 0`,
`easeOut 1 == 1`.
-}
easeOut : Float -> Float
easeOut t =
    1 - (1 - t) ^ 5


{-| Upstream's `tween` value: the tweened number `elapsed` milliseconds in,
where upstream's loop computes
`from + (to - from) * easeOut(Math.min(current - startTime, duration) / duration)`
and its `onFinish` then assigns `to` exactly. So `elapsed >= duration`
returns `to` outright (no `from + (to - from) * easeOut 1`, which can sit one
ulp off `to` in Float), and `duration = 0` finishes immediately. Negative
`elapsed` flows through the formula unclamped — upstream's monotonic clock
can never produce it, and this port changes no upstream expression.
-}
tweenValue :
    { from : Float
    , to : Float
    , duration : Float
    , elapsed : Float
    }
    -> Float
tweenValue { from, to, duration, elapsed } =
    let
        clamped =
            min elapsed duration
    in
    if clamped >= duration then
        to

    else
        from + (to - from) * easeOut (clamped / duration)


{-| The currently displayed number — upstream's `displayedValueRef`, which is
`from` until the tween ticks and `to` once finished.
-}
displayedValue : Options msg -> Float
displayedValue opts =
    tweenValue
        { from = opts.from
        , to = opts.to
        , duration = opts.duration
        , elapsed = opts.elapsed
        }



-- lodash round -------------------------------------------------------------------


{-| lodash's `round(value, precision)` — what upstream formats the displayed
value with. The decimal point is shifted through the number's _string_ form
(`"1.005e2"`, round, `"101e-2"` back), lodash's exponent trick, so binary
representation error never enters:

    roundTo 2 1.005 == 1.01

where the naive `roundTo p v = toFloat (round (v * 10 ^ p)) / 10 ^ p` yields
`1` (`1.005 * 100 == 100.49999…` as a Float).

Ties go up, JS `Math.round`-style — half towards `+Infinity`, not away from
zero. That is exactly what elm/core's `round` _implements_ (its kernel is
`Math.round`, so `round -1.5 == -1` — run it), even though the elm/core
_docs_ claim ".5 away from zero", which would give `-2`; `roundTo` follows
the implementation, matching lodash (`roundTo 0 -1.5 == -1`,
`roundTo 2 -1.005 == -1`). Negative precision works as in lodash
(`roundTo -2 1234 == 1200`), and as in lodash the precision is capped at
`292`. Precision `0` skips the shift and rounds directly, mirroring
lodash's `if (precision && …)` guard.

-}
roundTo : Int -> Float -> Float
roundTo precision value =
    let
        p =
            min precision 292
    in
    if p /= 0 && not (isNaN value) && not (isInfinite value) then
        shiftDecimal (negate p) (jsRound (shiftDecimal p value))

    else
        jsRound value


{-| JS `Math.round`: exactly elm/core's implemented `round` (the kernel is
`Math.round`), including ties towards `+Infinity`. Kept as a named helper so
the JS semantics are explicit; `toFloat` round-trips magnitudes past Elm's
`Int` range unchanged (they are JS numbers throughout).
-}
jsRound : Float -> Float
jsRound x =
    toFloat (round x)


{-| Shift the decimal point `places` right (positive) or left (negative)
through the number's decimal string — lodash's
`pair[0] + 'e' + (+pair[1] + precision)` / `+pair[0] + 'e' + (+pair[1] - precision)`.
Overflowing exponents parse to `Infinity` and underflowing to `0`, exactly
as JS `Number("…e…")` does.
-}
shiftDecimal : Int -> Float -> Float
shiftDecimal places value =
    let
        ( mantissa, exponent ) =
            splitExponent (String.fromFloat value)
    in
    String.toFloat (mantissa ++ "e" ++ String.fromInt (exponent + places))
        |> Maybe.withDefault value


{-| `String.fromFloat`'s output as `( digits, point position )`: `"1234.57"`
becomes `( "123457", 4 )`; the exponent form `"5e-8"` (used below `1e-7` and
above `1e21`, with a `"e+21"` sign Elm's `String.toInt` accepts) becomes
`( "5", -7 )`.
-}
splitExponent : String -> ( String, Int )
splitExponent s =
    case String.split "e" s of
        [ mantissa ] ->
            ( mantissa, 0 )

        [ mantissa, exponent ] ->
            ( mantissa, Maybe.withDefault 0 (String.toInt exponent) )

        _ ->
            ( s, 0 )



-- JS toFixed ---------------------------------------------------------------------


{-| Upstream's `round(displayedValue, precision).toFixed(precision)`:

    formatToFixed 0 1234.5678 == "1235"

    formatToFixed 2 1234.5678 == "1234.57"

    formatToFixed 2 0 == "0.00"

    formatToFixed 3 0.0005 == "0.001"

JS `toFixed` never uses exponent notation and always emits exactly
`precision` fractional digits — unlike `String.fromFloat`, which produces
`"1e-7"` below `1e-7`. (The one divergence kept: JS `toFixed` switches to
`"1e+21"` at `1e21` and beyond, where this still writes the digits out —
upstream never animates that high.) The sign is that of the _rounded_ value,
so `-0.0004` at precision 2 is `"0.00"`, not `"-0.00"` — upstream's round
trip already loses the negative zero there.

-}
formatToFixed : Int -> Float -> String
formatToFixed precision value =
    toFixed precision (roundTo precision value)


{-| JS `Number.prototype.toFixed(precision)`.
-}
toFixed : Int -> Float -> String
toFixed precision value =
    if isNaN value then
        "NaN"

    else if isInfinite value then
        if value > 0 then
            "Infinity"

        else
            "-Infinity"

    else
        let
            p =
                max 0 precision

            rounded =
                roundTo p value

            sign =
                if rounded < 0 then
                    "-"

                else
                    ""
        in
        sign ++ fixedFraction p (plainDigits (abs rounded))


{-| A finite number's decimal digits and decimal-point position, both
`"1234.57"` and `"5e-8"` forms.
-}
plainDigits : Float -> ( String, Int )
plainDigits v =
    let
        fromMantissa mantissa exponent =
            case String.split "." mantissa of
                [ whole ] ->
                    ( whole, String.length whole + exponent )

                [ before, after ] ->
                    ( before ++ after, String.length before + exponent )

                _ ->
                    ( "0", 1 )
    in
    case String.split "e" (String.fromFloat v) of
        [ dotForm ] ->
            fromMantissa dotForm 0

        [ mantissa, exponent ] ->
            fromMantissa mantissa (Maybe.withDefault 0 (String.toInt exponent))

        _ ->
            ( "0", 1 )


{-| Place the decimal point and pad to exactly `p` fractional digits:
`( "123457", 4 )` at `p = 2` is `"1234.57"`, `( "0", 1 )` at `p = 2` is
`"0.00"`, and `( "1", -6 )` at `p = 7` is `"0.0000001"`.
-}
fixedFraction : Int -> ( String, Int ) -> String
fixedFraction p ( rawDigits, rawPt ) =
    let
        digits =
            if rawPt < 0 then
                String.repeat (negate rawPt) "0" ++ rawDigits

            else if String.length rawDigits < rawPt then
                rawDigits ++ String.repeat (rawPt - String.length rawDigits) "0"

            else
                rawDigits

        pt =
            max 0 rawPt

        intDigits =
            if pt == 0 then
                "0"

            else
                String.slice 0 pt digits

        fracDigits =
            String.padRight p '0' (String.slice pt (pt + p) digits)
    in
    if p <= 0 then
        intDigits

    else
        intDigits ++ "." ++ fracDigits



-- formattedValue -----------------------------------------------------------------


{-| The displayed value as upstream's `formattedValueRef` computes it:
`round(displayedValue, precision).toFixed(precision)`, split at the decimal
point, with the integer part optionally grouped. Exposed so the formatter is
directly assertable without rendering:

    NUI.NumberAnimation.format
        { defaults | to = 16.5, precision = 2, elapsed = 2000 }
    -- { integer = "16", decimal = Just "50", decimalSeparator = "." }

-}
format : Options msg -> Formatted
format opts =
    case String.split "." (formatToFixed opts.precision (displayedValue opts)) of
        [ integer ] ->
            formatted opts integer Nothing

        integer :: decimal ->
            formatted opts integer (Just (String.concat decimal))

        [] ->
            formatted opts "0" Nothing


formatted : Options msg -> String -> Maybe String -> Formatted
formatted opts integer decimal =
    { integer =
        if opts.showSeparator then
            groupDigits opts.groupSeparator integer

        else
            integer
    , decimal = decimal
    , decimalSeparator = opts.decimalSeparator
    }


{-| Upstream's `showSeparator` branch:
`new Intl.NumberFormat(locale).format(Number(integer))` — default-options
`Intl` grouping, which for the locales at hand is plain thousands. The
separator is caller-owned here; the digits are grouped in threes from the
right and a leading `-` stays put:

    groupDigits "," "1234567" == "1,234,567"

    groupDigits "," "-1234567" == "-1,234,567"

Locales with other group sizes (hi-IN's `12,34,567`) are out of scope — see
the module docs.

-}
groupDigits : String -> String -> String
groupDigits separator digits =
    let
        ( sign, magnitude ) =
            if String.startsWith "-" digits then
                ( "-", String.dropLeft 1 digits )

            else
                ( "", digits )
    in
    sign ++ groupMagnitude separator magnitude


groupMagnitude : String -> String -> String
groupMagnitude separator magnitude =
    let
        len =
            String.length magnitude
    in
    if len > 3 then
        groupMagnitude separator (String.slice 0 (len - 3) magnitude)
            ++ separator
            ++ String.slice (len - 3) len magnitude

    else
        magnitude


{-| What upstream's `render()` joins into text. (Kept internal: it is
`integer`, then `decimalSeparator ++ decimal` when `decimal` exists — the
`Formatted` record says the same thing.)
-}
display : Formatted -> String
display f =
    f.integer
        ++ (case f.decimal of
                Just decimal ->
                    f.decimalSeparator ++ decimal

                Nothing ->
                    ""
           )
