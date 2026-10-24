module NUI.InputNumber exposing
    ( ButtonPlacement(..), DeriveArgs, DerivedValue(..), NumberContext, Options
    , addUpdate, addable, contextOf, createValidValue, defaults
    , deriveValueFromDisplayedValue, displayedValueFor, displayedValueInvalid
    , format, getMaxPrecision, getPrecision, inputUpdate, isWipValue
    , minusUpdate, minusable, parse, parseNumber, toFixedJs, validator, view
    )

{-| Naive UI's `InputNumber`, rebuilt on elm-ui: a text input for numbers with
clamp-to-`min`/`max`, `precision` formatting and add / minus buttons (real
`NUI.Button`s, rendered in the input's suffix — or split around it for
`Both` — with Naive UI's add / remove base-icon glyphs).

@docs ButtonPlacement, DeriveArgs, DerivedValue, NumberContext, Options
@docs addUpdate, addable, contextOf, createValidValue, defaults
@docs deriveValueFromDisplayedValue, displayedValueFor, displayedValueInvalid
@docs format, getMaxPrecision, getPrecision, inputUpdate, isWipValue
@docs minusUpdate, minusable, parse, parseNumber, toFixedJs, validator, view

    import NUI.InputNumber exposing (defaults)

    NUI.InputNumber.view theme
        { defaults
            | value = model.number
            , onChange = Just SetNumber
            , onInput = Just NumberInput
        }
        []

    NUI.InputNumber.view theme
        { defaults
            | min = Just 0
            , max = Just 10
            , step = 0.01
            , precision = Just 2
            , size = NUI.Types.Small
            , buttonPlacement = NUI.InputNumber.Both
        }
        []

**Caller-owned runtime** (same contract as `NUI.Calendar`'s `now` / `panel`).
Upstream keeps a `displayedValueRef` text buffer and derives everything from
it; this library is pure, so the caller owns the buffer and the value:

  - `displayedValue : Maybe String` — **the text buffer, the option that
    carries the typing state.** `Nothing` means "not typing": the view derives
    the text from `value` exactly like upstream's `deriveDisplayedValueFromValue`
    (see `displayedValueFor`). `Just raw` means the user is mid-edit: the raw
    text is shown verbatim (including wip values like `"0."` or `"-0"`).
  - `onInput` fires with the raw text of every keystroke. Store it
    (`displayedValue = Just raw`) and, when `updateValueOnInput` is on and no
    `precision` is set, apply `inputUpdate opts raw` to `value` — the port of
    upstream's `handleUpdateDisplayedValue` live-sync guard and all.
  - `onChange` fires with upstream's `doUpdateValue` payload. The add / minus
    buttons emit it via `addUpdate` / `minusUpdate`; on receipt set
    `value = payload` and `displayedValue = Nothing` (the buffer re-derives).
  - What stays with the caller: the blur / Enter commit
    (`deriveValueFromDisplayedValue ctx { offset = 0, doUpdateIfValid = True,
    fixPrecision = True, isInputing = False }` — upstream's exact `doBlur` /
    Enter-key call), the ArrowUp / ArrowDown keys (commit, then
    `addUpdate` / `minusUpdate`), and the hold-to-repeat timers (800 ms
    threshold, 100 ms interval — each tick is one `addUpdate` / `minusUpdate`).
    `NUI.Input` exposes no focus / blur / keydown hooks, so those cannot be
    wired from `view`.

**Slots.** The children model upstream's `prefix` / `suffix` slots: the first
child is the prefix slot, the second the suffix slot (both optional). While
`showButton` is on, upstream wraps slot content in `n-input-number-prefix` /
`n-input-number-suffix` spans — so does `view`.

**Upstream utils, ported faithfully and exposed** (a tester asserts them):
`parse`, `isWipValue`, `validator`, `format`, `parseNumber` from
`input-number/src/utils.ts`, plus `toFixedJs` (JavaScript's
`Number.prototype.toFixed`, computed from the exact decimal expansion of the
double — `String.fromFloat` is already byte-identical to JS `String(number)`,
verified against Node). `parse` keeps upstream's null-vs-NaN distinction:
empty / whitespace-only input is `Nothing` (upstream `null`, which clears the
value), while unparseable text is `Just (0/0)` (upstream `NaN`, which is
invalid and commits nothing) — `deriveValueFromDisplayedValue` behaves
differently for the two, exactly like upstream.

**Gaps vs upstream (documented, not worked around):**

  - Upstream narrows the inner input's padding through `builtinThemeOverrides`
    (`small "0 8px 0 10px"`, `medium "0 8px 0 12px"`, `large "0 8px 0 14px"`);
    `NUI.Input` has no padding option (see `NUI.InputOtp`'s header), so the
    input renders with its own defaults (`"0 10px"` / `"0 12px"` / `"0 14px"`)
    — the right padding is 2–6 px wider than upstream when buttons show.
  - Upstream strikes invalid text through (`textDecoration = 'line-through'`
    when `displayedValueInvalid`); `NUI.Input` has no text-decoration option.
  - `NUI.Input`'s `prefix` / `suffix` are single `Element`s, so a slot holding
    both a span and the buttons needs one extra wrapper `div` (an unclassed
    flex row — visually inert inside the inline-flex `n-input__suffix`).
  - Upstream sets `focusable={false}` on the buttons; `NUI.Button` always
    renders `tabindex 0` when enabled.
  - Upstream props not carried by this API: `autofocus`, `loading`,
    `clearable`, `round`, `keyboard`, `inputProps`, `bordered` and the custom
    `parse` / `format` / `validator` functions.

-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import NUI.Button as Button
import NUI.Input as Input
import NUI.Internal as I
import NUI.Internal.Color as Color
import NUI.Theme exposing (Theme)
import NUI.Theme.InputNumber as InputNumberTheme
import NUI.Types as T
import Svg


{-| Upstream's `buttonPlacement` prop: `right` (both buttons after the input)
or `both` (minus before, add after).
-}
type ButtonPlacement
    = Right
    | Both


{-| The `n-input-number` props. `displayedValue` is the caller-owned typing
buffer (see the module docs); `onChange` carries `doUpdateValue`'s payload
(`Maybe Float` — `Nothing` clears), `onInput` the raw keystroke text.
-}
type alias Options msg =
    { value : Maybe Float
    , displayedValue : Maybe String
    , min : Maybe Float
    , max : Maybe Float
    , step : Float
    , precision : Maybe Int
    , placeholder : Maybe String
    , disabled : Bool
    , readonly : Bool
    , size : T.Size
    , showButton : Bool
    , buttonPlacement : ButtonPlacement
    , status : Maybe Input.Status
    , updateValueOnInput : Bool
    , rtl : Bool
    , onChange : Maybe (Maybe Float -> msg)
    , onInput : Maybe (String -> msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream's initial state: empty value and buffer, no bounds, `step = 1`,
no precision, medium size, both buttons after the input, live update on.
-}
defaults : Options msg
defaults =
    { value = Nothing
    , displayedValue = Nothing
    , min = Nothing
    , max = Nothing
    , step = 1
    , precision = Nothing
    , placeholder = Just "Please Input"
    , disabled = False
    , readonly = False
    , size = T.Medium
    , showButton = True
    , buttonPlacement = Right
    , status = Nothing
    , updateValueOnInput = True
    , rtl = False
    , onChange = Nothing
    , onInput = Nothing
    , attributes = []
    }


{-| The `n-input-number` root: one div wrapping the inner `n-input` with the
buttons threaded through its prefix / suffix slots. Children: element 0 is
the `prefix` slot, element 1 the `suffix` slot (both optional, both wrapped
in `n-input-number-prefix` / `-suffix` spans while `showButton` is on).
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        prefixChild =
            List.head children

        suffixChild =
            List.drop 1 children |> List.head
    in
    Element.row
        (I.classes (rootClasses opts) :: opts.attributes)
        [ inputElement theme opts prefixChild suffixChild ]


rootClasses : Options msg -> List String
rootClasses opts =
    [ "n-input-number" ]
        ++ I.classIf opts.rtl "n-input-number--rtl"


{-| The inner `n-input` — upstream's whole render is this root div plus one
`NInput` carrying the value, the merged props and the two slot-rendering
functions.
-}
inputElement : Theme -> Options msg -> Maybe (Element msg) -> Maybe (Element msg) -> Element msg
inputElement theme opts prefixChild suffixChild =
    let
        inputDefaults =
            Input.defaults
    in
    Input.view theme
        { inputDefaults
            | value = (contextOf opts).displayedValue
            , onInput = opts.onInput
            , placeholder = opts.placeholder
            , size = opts.size
            , status = opts.status
            , disabled = opts.disabled
            , readonly = opts.readonly
            , rtl = opts.rtl
            , prefix = prefixSlot theme opts prefixChild
            , suffix = suffixSlot theme opts suffixChild
        }


{-| Upstream's `prefix` slot: with buttons on and `both` placement it is the
minus button plus the wrapped prefix span; otherwise the raw slot (no span,
exactly like upstream's `$slots.prefix?.()` fallback).
-}
prefixSlot : Theme -> Options msg -> Maybe (Element msg) -> Maybe (Element msg)
prefixSlot theme opts prefixChild =
    if opts.showButton then
        case opts.buttonPlacement of
            Both ->
                Just (slotRow (minusButton theme opts :: wrappedSlot "n-input-number-prefix" prefixChild))

            Right ->
                prefixChild

    else
        prefixChild


{-| Upstream's `suffix` slot: with buttons on it is the wrapped suffix span,
then the minus button (`right` placement only), then the add button; otherwise
the raw slot.
-}
suffixSlot : Theme -> Options msg -> Maybe (Element msg) -> Maybe (Element msg)
suffixSlot theme opts suffixChild =
    if opts.showButton then
        let
            minus =
                case opts.buttonPlacement of
                    Right ->
                        [ minusButton theme opts ]

                    Both ->
                        []
        in
        Just (slotRow (wrappedSlot "n-input-number-suffix" suffixChild ++ minus ++ [ addButton theme opts ]))

    else
        suffixChild


{-| Upstream wraps slot content in `n-input-number-prefix` / `-suffix` spans
only when the slot has content (`resolveWrappedSlot`).
-}
wrappedSlot : String -> Maybe (Element msg) -> List (Element msg)
wrappedSlot cls child =
    case child of
        Just c ->
            [ Element.el [ I.classes [ cls ] ] c ]

        Nothing ->
            []


{-| `NUI.Input`'s slots take one element, so several siblings need a wrapper;
a single child is passed straight through (upstream's DOM has no wrapper).
-}
slotRow : List (Element msg) -> Element msg
slotRow els =
    case els of
        [ single ] ->
            single

        _ ->
            Element.row [] els



-- add / minus buttons (upstream: NButton text + NBaseIcon glyph) -------------


{-| `buttonThemeOverrides` (`InputNumber.tsx:657-667`): both buttons' disabled
text colour comes from THIS component's `iconColorDisabled`, rgba-split so
the Button keeps its own opacity channel — `textColorTextDisabled` becomes
`rgb(r, g, b)`, `opacityDisabled` the alpha — threaded through `NUI.Button`'s
`varOverrides` seam (a text-variant button emits the former as
`--n-text-color-disabled`). Light: `rgb(194, 194, 194)` / `1`; dark:
`rgb(255, 255, 255)` / `0.38`. An unparsable colour is upstream-unreachable
(theme-generated); it degrades to no override.
-}
buttonVarOverrides : Theme -> List ( String, String )
buttonVarOverrides theme =
    case Color.rgba (InputNumberTheme.vars theme).iconColorDisabled of
        Ok { r, g, b, a } ->
            [ ( "--n-text-color-disabled"
              , "rgb(" ++ String.fromFloat r ++ ", " ++ String.fromFloat g ++ ", " ++ String.fromFloat b ++ ")"
              )
            , ( "--n-opacity-disabled", String.fromFloat a )
            ]

        Err _ ->
            []


minusButton : Theme -> Options msg -> Element msg
minusButton theme opts =
    let
        base =
            Button.defaults
    in
    Button.view theme
        { base
            | variant = Button.Text
            , disabled = not (minusable (contextOf opts)) || opts.disabled || opts.readonly
            , icon = Just (baseIcon removeIconSvg)
            , varOverrides = buttonVarOverrides theme
            , onPress =
                case opts.onChange of
                    Nothing ->
                        Nothing

                    Just toMsg ->
                        Maybe.map toMsg (minusUpdate opts)
        }
        []


addButton : Theme -> Options msg -> Element msg
addButton theme opts =
    let
        base =
            Button.defaults
    in
    Button.view theme
        { base
            | variant = Button.Text
            , disabled = not (addable (contextOf opts)) || opts.disabled || opts.readonly
            , icon = Just (baseIcon addIconSvg)
            , varOverrides = buttonVarOverrides theme
            , onPress =
                case opts.onChange of
                    Nothing ->
                        Nothing

                    Just toMsg ->
                        Maybe.map toMsg (addUpdate opts)
        }
        []


{-| Upstream's `NBaseIcon` — an `<i class="n-base-icon">` (its cssr rules ship
in the stylesheet, unlike `NUI.Input`'s inline-styled clear icon port).
-}
baseIcon : Html msg -> Element msg
baseIcon svg =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ svg ])


{-| Upstream `AddIcon` (`_internal/icons/Add.tsx`).
-}
addIconSvg : Html msg
addIconSvg =
    Svg.node "svg"
        [ HA.attribute "width" "512"
        , HA.attribute "height" "512"
        , HA.attribute "viewBox" "0 0 512 512"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M256 112V400M400 256H112"
            , HA.attribute "stroke" "currentColor"
            , HA.attribute "stroke-width" "32"
            , HA.attribute "stroke-linecap" "round"
            , HA.attribute "stroke-linejoin" "round"
            ]
            []
        ]


{-| Upstream `RemoveIcon` (`_internal/icons/Remove.tsx`).
-}
removeIconSvg : Html msg
removeIconSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 512 512"
        ]
        [ Svg.node "line"
            [ HA.attribute "x1" "400"
            , HA.attribute "y1" "256"
            , HA.attribute "x2" "112"
            , HA.attribute "y2" "256"
            , HA.attribute "style" "fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 32px"
            ]
            []
        ]



-- upstream utils.ts, ported faithfully ----------------------------------------


{-| Upstream `parse`: `null` for empty / whitespace-only input, else JS
`Number(value)`. The NaN case is kept as `Just (0/0)` — upstream's `null`
clears the value while its `NaN` is merely invalid, and
`deriveValueFromDisplayedValue` tells them apart.
-}
parse : String -> Maybe Float
parse value =
    if String.trim value == "" then
        Nothing

    else
        case parseJs value of
            JsNaN ->
                Just (0 / 0)

            JsNumber f ->
                Just f


{-| Upstream `parseNumber` — the string arm (`number` inputs are the identity,
`null` is `Nothing`): JS `Number(string)` with `NaN` collapsed to `Nothing`.
Note `parseNumber "" == Just 0` (JS `Number("")`) while `parse "" == Nothing`.
-}
parseNumber : String -> Maybe Float
parseNumber number =
    case parseJs number of
        JsNaN ->
            Nothing

        JsNumber f ->
            Just f


{-| Upstream `isWipValue`: true while the user may still be typing a decimal
(`"0."`, `"1.20"`, `"-0"`, `"-"`), so the raw text must not be replaced by its
parsed value. A faithful port of

    (value.includes('.')
      && (/^(-)?\d+.*(\.|0)$/.test(value) || /^-?\d*$/.test(value)))
    || value === '-'
    || value === '-0'

(The second alternative can never fire for a string that contains `'.'`, but
it is ported anyway; JS regex `.` excludes line terminators, which a
single-line input value cannot contain.)

-}
isWipValue : String -> Bool
isWipValue value =
    (String.contains "." value && (wipEndsDotOrZero value || wipDigitsOnly value))
        || value
        == "-"
        || value
        == "-0"


{-| `/^(-)?\d+.*(\.|0)$/` — an optional minus, at least one digit, anything,
then a final `.` or `0`.
-}
wipEndsDotOrZero : String -> Bool
wipEndsDotOrZero value =
    let
        body =
            if String.startsWith "-" value then
                String.dropLeft 1 value

            else
                value
    in
    (case String.uncons body of
        Just ( c, _ ) ->
            Char.isDigit c

        Nothing ->
            False
    )
        && (String.endsWith "." value || String.endsWith "0" value)


{-| `/^-?\d*$/`.
-}
wipDigitsOnly : String -> Bool
wipDigitsOnly value =
    let
        body =
            if String.startsWith "-" value then
                String.dropLeft 1 value

            else
                value
    in
    String.all Char.isDigit body


{-| Upstream `validator`: `null` passes (an empty input is valid), `NaN` does
not.
-}
validator : Maybe Float -> Bool
validator value =
    case value of
        Nothing ->
            True

        Just v ->
            not (Basics.isNaN v)


{-| Upstream `format`: `''` for no value, `String(value)` without a precision
(`String.fromFloat` is byte-identical to JS `String(number)`), `toFixed`
with one.
-}
format : Maybe Float -> Maybe Int -> String
format value precision =
    case value of
        Nothing ->
            ""

        Just v ->
            case precision of
                Nothing ->
                    String.fromFloat v

                Just p ->
                    toFixedJs v p


{-| JavaScript `Number.prototype.toFixed`, from the exact decimal expansion of
the double: `2.675 → "2.67"` (its binary value is below the tie), `0.125 →
"0.13"` (an exact tie rounds away from zero — as does `-0.125 → "-0.13"`),
`|x| ≥ 1e21` falls back to `String(x)` (`"1e+21"`), NaN / Infinity render as
`"NaN"` / `"Infinity"`. Precision is clamped into JS's 0–100 range (JS throws
`RangeError` outside it).
-}
toFixedJs : Float -> Int -> String
toFixedJs x f =
    if Basics.isNaN x then
        "NaN"

    else if x == 0 then
        -- `-0` is not `< 0`, so it renders without a sign
        zeroFixed (max 0 f)

    else if abs x >= 1.0e21 then
        String.fromFloat x

    else
        let
            f2 =
                clamp 0 100 f

            ( m, e ) =
                decompose (abs x)

            shifted =
                e + f2

            base =
                mulPow 5 f2 (bigFromInt m)

            scaled =
                if shifted >= 0 then
                    mulPow 2 shifted base

                else
                    base

            times =
                if shifted < 0 then
                    -shifted

                else
                    0

            ( quotient, roundUp ) =
                halveTimes scaled times

            n =
                if roundUp then
                    bigAddOne quotient

                else
                    quotient
        in
        renderFixed (x < 0) n f2


zeroFixed : Int -> String
zeroFixed f =
    if f <= 0 then
        "0"

    else
        "0." ++ String.repeat f "0"


{-| JS `Number(string)` — trimmed, `Infinity`, `NaN`, `0x`/`0o`/`0b` radix
literals (unsigned only, like JS) and the decimal grammar `String.toFloat`
already accepts (`"+1"`, `"1."`, `".5"`, `"1e+21"`, denormals). Radix literals
taller than 2^53 accumulate rounding per digit where JS rounds once — an ulp
off for 16+-digit literals only.
-}
parseJs : String -> JsNumber
parseJs raw =
    let
        s =
            String.trim raw
    in
    if String.isEmpty s then
        JsNumber 0

    else
        case s of
            "Infinity" ->
                JsNumber (1 / 0)

            "+Infinity" ->
                JsNumber (1 / 0)

            "-Infinity" ->
                JsNumber (negate (1 / 0))

            _ ->
                case radixLiteral s of
                    Just v ->
                        JsNumber v

                    Nothing ->
                        case String.toFloat s of
                            Just v ->
                                JsNumber v

                            Nothing ->
                                JsNaN


type JsNumber
    = JsNaN
    | JsNumber Float


radixLiteral : String -> Maybe Float
radixLiteral s =
    if startsWithAny [ "0x", "0X" ] s then
        digitsValue 16 (String.dropLeft 2 s)

    else if startsWithAny [ "0o", "0O" ] s then
        digitsValue 8 (String.dropLeft 2 s)

    else if startsWithAny [ "0b", "0B" ] s then
        digitsValue 2 (String.dropLeft 2 s)

    else
        Nothing


startsWithAny : List String -> String -> Bool
startsWithAny prefixes s =
    List.any (\p -> String.startsWith p s) prefixes


digitsValue : Int -> String -> Maybe Float
digitsValue base digits =
    if String.isEmpty digits then
        Nothing

    else
        String.foldl
            (\c acc ->
                acc
                    |> Maybe.andThen
                        (\v ->
                            Maybe.map (\d -> v * toFloat base + toFloat d) (digitValue base c)
                        )
            )
            (Just 0)
            digits


digitValue : Int -> Char -> Maybe Int
digitValue base c =
    let
        code =
            Char.toCode c
    in
    (if code >= 48 && code <= 57 then
        Just (code - 48)

     else if code >= 97 && code <= 122 then
        Just (code - 87)

     else if code >= 65 && code <= 90 then
        Just (code - 55)

     else
        Nothing
    )
        |> Maybe.andThen
            (\d ->
                if d < base then
                    Just d

                else
                    Nothing
            )


{-| `Number.parseFloat` over the strings `toFixedJs` / `String.fromFloat`
produce (fixed-point and exponential decimals, `Infinity`).
-}
parseFloatJs : String -> Float
parseFloatJs s =
    case s of
        "Infinity" ->
            1 / 0

        "-Infinity" ->
            negate (1 / 0)

        _ ->
            Maybe.withDefault 0 (String.toFloat s)



-- pure value derivations (ports of the setup() computeds) ---------------------


{-| Everything the derivations need, extracted from `Options` by `contextOf`
(upstream closes over the props instead).
-}
type alias NumberContext =
    { min : Maybe Float
    , max : Maybe Float
    , step : Float
    , precision : Maybe Int
    , displayedValue : String
    }


{-| Upstream `deriveValueFromDisplayedValue`'s flags.
-}
type alias DeriveArgs =
    { offset : Float
    , doUpdateIfValid : Bool
    , fixPrecision : Bool
    , isInputing : Bool
    }


{-| Upstream's `null | number | false` return: `NullValue` is `null` (the
value clears), `NumberValue` is a number (with `doUpdateIfValid = True` this
is also the `onChange` payload — upstream called `doUpdateValue` with it),
`InvalidValue` is `false` (no update).
-}
type DerivedValue
    = InvalidValue
    | NullValue
    | NumberValue Float


{-| The resolved context: `min` / `max` as given, `step` as upstream's
`mergedStepRef` (`abs`, and `0` becomes `1`), and `displayedValue` as the
caller-owned buffer or its derivation from `value`.
-}
contextOf : Options msg -> NumberContext
contextOf opts =
    { min = opts.min
    , max = opts.max
    , step = mergedStep opts.step
    , precision = opts.precision
    , displayedValue = Maybe.withDefault (displayedValueFor opts) opts.displayedValue
    }


mergedStep : Float -> Float
mergedStep step =
    if step == 0 then
        1

    else
        abs step


{-| Upstream `getPrecision(value)`: the decimal count of `String(value)`
(`0.1 → 1`, `1e-7 → 0` — exponent forms carry no fraction).
-}
getPrecision : Float -> Int
getPrecision value =
    case String.split "." (String.fromFloat value) of
        [ _, fraction ] ->
            String.length fraction

        _ ->
            0


{-| Upstream `getMaxPrecision(currentValue)`: the maximum decimal count of
`min`, `max`, `step` and the current value (absent ones count `0`). This is
the precision used when the `precision` option is unset — upstream resolves
`precision ?? getMaxPrecision(parsedValue)`, it does **not** take a max of the
option and the step.
-}
getMaxPrecision : NumberContext -> Float -> Int
getMaxPrecision ctx currentValue =
    [ Maybe.map getPrecision ctx.min
    , Maybe.map getPrecision ctx.max
    , Just (getPrecision ctx.step)
    , Just (getPrecision currentValue)
    ]
        |> List.filterMap identity
        |> List.maximum
        |> Maybe.withDefault 0


{-| Upstream `deriveValueFromDisplayedValue`, verbatim: the wip guard, the
null / NaN split, the precision gate (`precision < currentPrecision` blocks
unless `fixPrecision`), the offset with `toFixed` at the resolved precision,
the `min` / `max` clamping (`doUpdateIfValid` and not `isInputing` turn an
out-of-range result into the bound instead of `false`), and the `validator`
checks. The custom `props.validator` predicate has no counterpart in this API
(see the module gaps).
-}
deriveValueFromDisplayedValue : NumberContext -> DeriveArgs -> DerivedValue
deriveValueFromDisplayedValue ctx args =
    if args.isInputing && isWipValue ctx.displayedValue then
        InvalidValue

    else
        case parse ctx.displayedValue of
            Nothing ->
                NullValue

            Just parsed ->
                if validator (Just parsed) then
                    deriveFromParsed ctx args parsed

                else
                    InvalidValue


deriveFromParsed : NumberContext -> DeriveArgs -> Float -> DerivedValue
deriveFromParsed ctx args parsed =
    case ctx.precision of
        Just p ->
            if p < getPrecision parsed && not args.fixPrecision then
                InvalidValue

            else
                deriveNext ctx args parsed p

        Nothing ->
            deriveNext ctx args parsed (getMaxPrecision ctx parsed)


deriveNext : NumberContext -> DeriveArgs -> Float -> Int -> DerivedValue
deriveNext ctx args parsed p =
    let
        next =
            parseFloatJs (toFixedJs (parsed + args.offset) p)
    in
    if validator (Just next) then
        clampTo ctx args next

    else
        InvalidValue


clampTo : NumberContext -> DeriveArgs -> Float -> DerivedValue
clampTo ctx args next =
    let
        mayFix =
            args.doUpdateIfValid && not args.isInputing

        afterMax =
            case ctx.max of
                Just mx ->
                    if next > mx && not mayFix then
                        Nothing

                    else
                        Just (min next mx)

                Nothing ->
                    Just next
    in
    case afterMax of
        Nothing ->
            InvalidValue

        Just v ->
            case ctx.min of
                Just mn ->
                    if v < mn && not mayFix then
                        InvalidValue

                    else
                        NumberValue (max v mn)

                Nothing ->
                    NumberValue v


{-| Upstream `deriveDisplayedValueFromValue` (without the custom-`format`
branch this API does not carry): the text the input shows for `value` —
`""` for no value, `String(v)` unless a set `precision` fits it, else
`toFixed(v, precision)`, and `"NaN"` for a NaN value.
-}
displayedValueFor : Options msg -> String
displayedValueFor opts =
    case opts.value of
        Nothing ->
            format Nothing Nothing

        Just v ->
            if validator (Just v) then
                if opts.precision == Nothing || getPrecision v > Maybe.withDefault 0 opts.precision then
                    format (Just v) Nothing

                else
                    format (Just v) opts.precision

            else
                String.fromFloat v


{-| Upstream `addableRef`: whether the add button is enabled — the current
displayed value yields a number under a `+step` offset.
-}
addable : NumberContext -> Bool
addable ctx =
    not <|
        derivedIsInvalid <|
            deriveValueFromDisplayedValue ctx
                { offset = ctx.step
                , doUpdateIfValid = False
                , fixPrecision = False
                , isInputing = False
                }


{-| Upstream `minusableRef`, the `−step` twin of `addable`.
-}
minusable : NumberContext -> Bool
minusable ctx =
    not <|
        derivedIsInvalid <|
            deriveValueFromDisplayedValue ctx
                { offset = -ctx.step
                , doUpdateIfValid = False
                , fixPrecision = False
                , isInputing = False
                }


{-| Upstream `displayedValueInvalidRef` (drives the `line-through` that
`NUI.Input` cannot render — see the module gaps).
-}
displayedValueInvalid : NumberContext -> Bool
displayedValueInvalid ctx =
    derivedIsInvalid <|
        deriveValueFromDisplayedValue ctx
            { offset = 0
            , doUpdateIfValid = False
            , fixPrecision = False
            , isInputing = False
            }


derivedIsInvalid : DerivedValue -> Bool
derivedIsInvalid derived =
    case derived of
        InvalidValue ->
            True

        _ ->
            False


{-| Upstream `doAdd` as a pure function: `Nothing` when the button would not
fire (not addable — the button renders disabled then); `Just payload`
otherwise — `createValidValue` when the value is empty, else the `+step`
derivation with `doUpdateIfValid` / `fixPrecision`.
-}
addUpdate : Options msg -> Maybe (Maybe Float)
addUpdate opts =
    let
        ctx =
            contextOf opts
    in
    if not (addable ctx) then
        Nothing

    else
        case opts.value of
            Nothing ->
                Just (Just (createValidValue opts))

            Just _ ->
                deriveUpdate ctx
                    { offset = ctx.step
                    , doUpdateIfValid = True
                    , fixPrecision = True
                    , isInputing = False
                    }


{-| Upstream `doMinus`, the `−step` twin of `addUpdate`.
-}
minusUpdate : Options msg -> Maybe (Maybe Float)
minusUpdate opts =
    let
        ctx =
            contextOf opts
    in
    if not (minusable ctx) then
        Nothing

    else
        case opts.value of
            Nothing ->
                Just (Just (createValidValue opts))

            Just _ ->
                deriveUpdate ctx
                    { offset = -ctx.step
                    , doUpdateIfValid = True
                    , fixPrecision = True
                    , isInputing = False
                    }


{-| Upstream `handleUpdateDisplayedValue`'s live-sync half: the `onChange`
payload a typed `raw` produces, when `updateValueOnInput` is on and no
`precision` is set (upstream also gates on the absent custom `parse` /
`format`, which this API does not carry). `Nothing` — no update.
-}
inputUpdate : Options msg -> String -> Maybe (Maybe Float)
inputUpdate opts raw =
    let
        ctx =
            contextOf opts
    in
    if opts.updateValueOnInput && opts.precision == Nothing then
        deriveUpdate
            { ctx | displayedValue = raw }
            { offset = 0
            , doUpdateIfValid = True
            , fixPrecision = False
            , isInputing = True
            }

    else
        Nothing


{-| Upstream `createValidValue`: the value an empty input takes when a button
is pressed — `max(0, min)`, else `min(0, max)`, else `0`.
-}
createValidValue : Options msg -> Float
createValidValue opts =
    case opts.min of
        Just mn ->
            max 0 mn

        Nothing ->
            case opts.max of
                Just mx ->
                    min 0 mx

                Nothing ->
                    0


deriveUpdate : NumberContext -> DeriveArgs -> Maybe (Maybe Float)
deriveUpdate ctx args =
    case deriveValueFromDisplayedValue ctx args of
        NumberValue v ->
            Just (Just v)

        NullValue ->
            Just Nothing

        InvalidValue ->
            Nothing



-- exact decimal arithmetic (for toFixedJs) ------------------------------------
--
-- A double is m * 2^e exactly; its decimal expansion is therefore finite and
-- computable with little-endian decimal digit strings ("Big" below).


{-| `|x| = m * 2^e` with `m` an integer (`2^52 ≤ m < 2^53`, so it fits an
`Int`); every step is exact for powers of two.
-}
decompose : Float -> ( Int, Int )
decompose ax =
    let
        twoTo52 =
            4503599627370496.0

        normalize v e =
            if v >= 2 then
                normalize (v / 2) (e + 1)

            else if v < 1 then
                normalize (v * 2) (e - 1)

            else
                ( v, e )

        ( significand, e0 ) =
            normalize ax 0
    in
    ( round ((significand - 1) * twoTo52) + 4503599627370496
    , e0 - 52
    )


type alias Big =
    List Int


bigFromInt : Int -> Big
bigFromInt n =
    bigFromPositive (toFloat (max 0 n))


{-| `//` and `modBy` wrap at 32 bits, so split the digits of a value up to
2^53 in float space (exact there). The digit `v - 10 * floor (v / 10)` is an
integer below 10, and `floor` keeps the quotient exact below 2^53.
-}
bigFromPositive : Float -> Big
bigFromPositive v =
    if v <= 0 then
        []

    else
        let
            quotient =
                floor (v / 10)
        in
        truncate (v - toFloat quotient * 10) :: bigFromPositive (toFloat quotient)


{-| Multiply by a single decimal digit (`toFixedJs` needs 2 and 5).
-}
bigMulSmall : Int -> Big -> Big
bigMulSmall small digits =
    bigMulSmallGo small digits 0


bigMulSmallGo : Int -> Big -> Int -> Big
bigMulSmallGo small digits carry =
    case digits of
        [] ->
            if carry <= 0 then
                []

            else
                [ carry ]

        d :: rest ->
            let
                product =
                    d * small + carry
            in
            modBy 10 product :: bigMulSmallGo small rest (product // 10)


mulPow : Int -> Int -> Big -> Big
mulPow base times big =
    List.foldl (\_ acc -> bigMulSmall base acc) big (List.repeat times ())


{-| Halve once; the remainder's parity is the next bit of the binary fraction
being dropped.
-}
halve : Big -> ( Big, Int )
halve digits =
    halveGo (List.reverse digits) 0 []


halveGo : List Int -> Int -> List Int -> ( Big, Int )
halveGo high carry acc =
    case high of
        [] ->
            ( dropHighZeros acc, carry )

        d :: rest ->
            let
                current =
                    carry * 10 + d
            in
            halveGo rest (modBy 2 current) (current // 2 :: acc)


{-| Halve `times` times. `roundUp` is the parity of the last halving — bit
`times - 1` of the original number, i.e. whether the dropped fraction reached
one half (ties round away from zero, exactly like JS).
-}
halveTimes : Big -> Int -> ( Big, Bool )
halveTimes big times =
    let
        ( quotient, lastParity ) =
            List.foldl (\_ ( b, _ ) -> halve b) ( big, 0 ) (List.repeat times ())
    in
    ( quotient, lastParity == 1 )


dropHighZeros : Big -> Big
dropHighZeros big =
    big
        |> List.reverse
        |> dropWhile (\d -> d == 0)
        |> List.reverse


dropWhile : (a -> Bool) -> List a -> List a
dropWhile predicate list =
    case list of
        x :: rest ->
            if predicate x then
                dropWhile predicate rest

            else
                list

        [] ->
            []


bigAddOne : Big -> Big
bigAddOne digits =
    case digits of
        [] ->
            [ 1 ]

        d :: rest ->
            if d < 9 then
                d + 1 :: rest

            else
                0 :: bigAddOne rest


bigToString : Big -> String
bigToString digits =
    case digits of
        [] ->
            "0"

        _ ->
            digits
                |> List.reverse
                |> List.map String.fromInt
                |> String.concat


renderFixed : Bool -> Big -> Int -> String
renderFixed neg n f =
    let
        s =
            bigToString n

        len =
            String.length s

        intPart =
            if len <= f then
                "0"

            else
                String.slice 0 (len - f) s

        fracPart =
            if len <= f then
                String.repeat (f - len) "0" ++ s

            else
                String.slice (len - f) len s
    in
    (if neg then
        "-"

     else
        ""
    )
        ++ intPart
        ++ (if f > 0 then
                "." ++ fracPart

            else
                ""
           )
