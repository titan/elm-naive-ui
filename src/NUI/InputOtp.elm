module NUI.InputOtp exposing
    ( Gap(..)
    , Options
    , Size(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `InputOtp`, rebuilt on elm-ui.

    import NUI.InputOtp exposing (defaults)

    NUI.InputOtp.view theme
        { defaults
            | value = model.otp
            , onUpdateValue = Just GotOtp
        }
        []

    NUI.InputOtp.view theme
        { defaults
            | mask = True
            , size = NUI.InputOtp.Small
            , length = 4
            , gap = Just (NUI.InputOtp.Px 16)
        }
        []

(`defaults` must be bound to a local name first — see `NUI.Input`.)

The element carries the `.n-input-otp` BEM classes and Naive UI's `--n-*`
custom properties, and `NUI.Css` ships Naive UI's exact CSS. Each slot is an
`NUI.Input.view` (an `n-input`), exactly like upstream's default slot fallback.

**Runtime.** Upstream owns the per-slot value (`useMergedState`) and justifies
it to `length` entries; this library is pure, so the caller owns `value` (the
view re-justifies it to `length` slots for rendering). `onUpdateValue` receives
the value Naive UI reports: the single-character input rule, the multi-character
(paste / autofill) distribution across slots and the `allowInput` filter are
ported from upstream's `handleInput`. What stays with the caller: slot focus
movement (`focusOnChar`, arrow keys, the auto-advance after input — DOM
focus, i.e. `Browser.Dom.focus`), upstream's `onFinish` (derive it
from `onUpdateValue`: every slot non-empty) and the paste / keydown handlers
(`NUI.Input` exposes no such hooks). On rejection by `allowInput` the browser
fires no `input` event, so no message is emitted (matching upstream); a no-op
`onUpdateValue` is only emitted when an already-empty slot is re-input, which
upstream fires and then swallows via a shallow-equality check.

The `slotInputAttributes` seam carries raw attributes onto each built-in
slot's inner `<input>` (upstream's typed default slot lets a caller reach
the inner `NInput` — there is no `inputProps` on `n-input-otp` itself): pass
per-index ids (`\i -> [ HA.id ("otp-" ++ String.fromInt i) ]`) so
`Browser.Dom.focus` can move between slots — the demo app's auto-advance
recipe (examples/src/Sections/Controls.elm) focuses the first empty slot
after every `onUpdateValue`.

The children argument models upstream's typed default slot: element _i_
replaces the built-in input of slot _i_ (pass `[]` for the built-in inputs).
Upstream zeroes each inner input's padding through `builtinThemeOverrides`;
the built-in slots pass that to `NUI.Input.varOverrides`
(`--n-padding-left/right: 0`) — children replacing a slot must do their own
zeroing if they want the same 24–36px-cell geometry.

-}

import Element exposing (Element)
import Html exposing (Html)
import NUI.Input as Input
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.InputOtp as InputOtpTheme
import NUI.Types as T


{-| The slot size — Naive UI's `size` prop (`small | medium | large`).
-}
type Size
    = Small
    | Medium
    | Large


{-| A CSS length for the `gap` prop — a pixel count (upstream's `pxfy` number)
or a raw CSS length string.
-}
type Gap
    = Px Int
    | Custom String


type alias Options msg =
    { value : List String
    , length : Int
    , onUpdateValue : Maybe (List String -> msg)
    , allowInput : Maybe (String -> Int -> List String -> Bool)
    , size : Size
    , gap : Maybe Gap
    , block : Bool
    , mask : Bool
    , disabled : Bool
    , readonly : Bool
    , status : Maybe Input.Status
    , placeholder : Maybe String
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    , slotInputAttributes : Int -> List (Html.Attribute msg)
    }


defaults : Options msg
defaults =
    { value = []
    , length = 6
    , onUpdateValue = Nothing
    , allowInput = Nothing
    , size = Medium
    , gap = Nothing
    , block = False
    , mask = False
    , disabled = False
    , readonly = False
    , status = Nothing
    , placeholder = Nothing
    , rtl = False
    , attributes = []
    , slotInputAttributes = \_ -> []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.row
        ([ I.classes (rootClasses opts)
         , I.cssVars (cssVarsFor theme opts)
         ]
            ++ opts.attributes
        )
        (List.map (slotElement theme opts children) (List.range 0 (opts.length - 1)))



-- per-slot content -------------------------------------------------------------


{-| Upstream renders one `<NInput>` per index through its typed default slot;
element _i_ of the children replaces the built-in input of slot _i_.
-}
slotElement : Theme -> Options msg -> List (Element msg) -> Int -> Element msg
slotElement theme opts children index =
    case List.drop index children |> List.head of
        Just el ->
            el

        Nothing ->
            defaultItem theme opts index


{-| The default slot fallback: one `n-input` fed with the per-index props
upstream passes (`value` / `type` / `size` / `placeholder` / `disabled` /
`readonly` / `status` / `onInput`).
-}
defaultItem : Theme -> Options msg -> Int -> Element msg
defaultItem theme opts index =
    let
        inputDefaults =
            Input.defaults
    in
    Input.view theme
        { inputDefaults
            | value = at index (justifyValue opts.length opts.value)
            , onInput = itemOnInput opts index
            , placeholder = opts.placeholder
            , size = toInputSize opts.size
            , type_ =
                if opts.mask then
                    Input.Password

                else
                    Input.Text
            , status = opts.status
            , disabled = opts.disabled
            , readonly = opts.readonly

            -- Upstream zeroes every inner input's padding through its
            -- `builtinThemeOverrides` ({ paddingTiny..paddingLarge: '0' },
            -- InputOtp.tsx render); the slots are 24–36px wide, so the size's
            -- default padding would leave the digit almost no content width.
            -- The override lands on the resolved `--n-padding-left/right` —
            -- the exact vars upstream's zeroed paddings produce.
            , varOverrides =
                [ ( "--n-padding-left", "0" )
                , ( "--n-padding-right", "0" )
                ]
            , inputAttributes = opts.slotInputAttributes index
        }


itemOnInput : Options msg -> Int -> Maybe (String -> msg)
itemOnInput opts index =
    Maybe.map (\toMsg raw -> toMsg (inputUpdate opts index raw)) opts.onUpdateValue



-- upstream handleInput, as a pure function -------------------------------------


{-| Upstream's `handleInput`: what `onUpdate:value` receives when slot `index`
reports the raw string `raw` (the diff against the current slot value, the
multi-character distribution, and the `allowInput` filter are all ported; the
focus side effects are the caller's).
-}
inputUpdate : Options msg -> Int -> String -> List String
inputUpdate opts index raw =
    let
        current =
            justifyValue opts.length opts.value

        currentAtIndex =
            at index current

        diff =
            replaceFirst currentAtIndex raw

        text =
            if String.isEmpty diff then
                raw

            else
                diff
    in
    if String.length text > 1 then
        distribute opts index current (String.toList text)

    else if allowed opts (String.right 1 text) index current then
        setAt index (String.right 1 text) current

    else
        current


{-| Upstream's multi-character branch (paste-like input / autofill): write the
characters one slot at a time, skipping the ones `allowInput` rejects, and stop
once the last slot is written.
-}
distribute : Options msg -> Int -> List String -> List Char -> List String
distribute opts startIndex current chars =
    case chars of
        [] ->
            current

        c :: rest ->
            if allowed opts (String.fromChar c) startIndex current then
                let
                    next =
                        setAt startIndex (String.fromChar c) current
                in
                if startIndex + 1 >= List.length current then
                    next

                else
                    distribute opts (startIndex + 1) next rest

            else
                distribute opts startIndex current rest


allowed : Options msg -> String -> Int -> List String -> Bool
allowed opts char index current =
    case opts.allowInput of
        Just f ->
            f char index current

        Nothing ->
            True


{-| Upstream's `justifyValue`: truncate to `length` entries, then pad with
empty strings.
-}
justifyValue : Int -> List String -> List String
justifyValue length value =
    let
        taken =
            List.take length value
    in
    taken ++ List.repeat (length - List.length taken) ""


at : Int -> List String -> String
at index list =
    List.drop index list |> List.head |> Maybe.withDefault ""


setAt : Int -> String -> List String -> List String
setAt index value list =
    List.indexedMap
        (\i v ->
            if i == index then
                value

            else
                v
        )
        list


{-| JS `String.replace(search, '')` — removes the first occurrence only (Elm's
`String.replace` removes all of them).
-}
replaceFirst : String -> String -> String
replaceFirst needle haystack =
    case String.split needle haystack of
        head :: tail ->
            head ++ String.join needle tail

        [] ->
            haystack



-- classes & vars ---------------------------------------------------------------


rootClasses : Options msg -> List String
rootClasses opts =
    [ "n-input-otp" ]
        ++ I.classIf opts.rtl "n-input-otp--rtl"
        ++ I.classIf opts.block "n-input-otp--block"


{-| The raw `--n-*` custom properties an input-otp with these options attaches
(before `NUI.Internal.renderVars` drops `initial`/empty values). Exposed so the
`--n-*` output can be asserted directly; `view` uses exactly this.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            InputOtpTheme.vars theme
    in
    [ ( "--n-gap", gapValue opts v )
    , ( "--n-input-width", inputWidthOf opts.size v )
    ]


{-| `propGap === undefined ? gap : typeof propGap === 'number' ? pxfy(propGap) : propGap`.
-}
gapValue : Options msg -> InputOtpTheme.Vars -> String
gapValue opts v =
    case opts.gap of
        Just (Px n) ->
            String.fromInt n ++ "px"

        Just (Custom s) ->
            s

        Nothing ->
            gapOf opts.size v


gapOf : Size -> InputOtpTheme.Vars -> String
gapOf size v =
    case size of
        Small ->
            v.gapSmall

        Medium ->
            v.gapMedium

        Large ->
            v.gapLarge


inputWidthOf : Size -> InputOtpTheme.Vars -> String
inputWidthOf size v =
    case size of
        Small ->
            v.inputWidthSmall

        Medium ->
            v.inputWidthMedium

        Large ->
            v.inputWidthLarge


{-| Upstream's `InputOtpSize` is exactly the small / medium / large subset of
`NUI.Types.Size` the inner `NInput` accepts.
-}
toInputSize : Size -> T.Size
toInputSize size =
    case size of
        Small ->
            T.Small

        Medium ->
            T.Medium

        Large ->
            T.Large
