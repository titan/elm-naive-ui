module NUI.Input exposing
    ( InputType(..)
    , Options
    , PairSource(..)
    , Status(..)
    , defaults
    , group
    , groupLabel
    , view
    )

{-| Naive UI's `Input` (plus `InputGroup` and `InputGroupLabel`), rebuilt on elm-ui.

The component owns its value: pass the current string in `value` and receive
updates through `onInput`.

    Input.view theme
        { defaults
            | value = model.value
            , onInput = Just GotInput
            , placeholder = Just "Basic Input"
        }

    -- textarea / password / sizes / statuses
    Input.view theme
        { defaults
            | type_ = Input.Textarea
            , rows = 4
            , status = Just Input.Warning
        }

    Input.view theme
        { defaults
            | type_ = Input.Password
            , clearable = True
            , round = True
            , size = NUI.Types.Small
            , prefix = Just (Element.text "¥")
            , suffix = Just (Element.text "RMB")
        }

Input groups (Naive UI's `n-input-group` / `n-input-group-label`):

    Input.group
        [ Input.groupLabel theme
            { size = NUI.Types.Medium, bordered = True }
            [ Element.text "https://" ]
        , Input.view theme { defaults | placeholder = Just "website" }
        , Input.groupLabel theme
            { size = NUI.Types.Medium, bordered = True }
            [ Element.text ".com" ]
        ]

(`defaults` must be bound to a local name first — Elm's record update syntax
does not accept a qualified `Input.defaults` there.)

The visual result is Naive UI's own: the elements carry the `.n-input` BEM
classes and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive
UI's exact CSS.

Three seams beyond the basic props:

  - `varOverrides` — upstream's per-instance `builtinThemeOverrides` as a
    key/value patch over the resolved `--n-*` vars (a known key is swapped
    in place, an unknown one appended — `NUI.Button.varOverrides` is the
    same seam); `NUI.InputOtp`'s slots use it for upstream's
    `{ paddingTiny, …, paddingLarge: '0' }` zeroing (`InputOtp.tsx` render:
    `--n-padding-left/right: 0`).

  - `autosize` — upstream `autosize: Boolean | {minRows?, maxRows?}`
    (`Input.tsx:89`); here `Bool` only. `True` emits `n-input--autosize`
    on the root and suppresses `n-input--resizable` (upstream
    `Input.tsx:1130-1131` gates `--resizable` on `resizable && !autosize`
    and fires `--autosize` on the flag alone, ungated on `type`). The
    height measurement itself (`Input.tsx:339-375` — the minRows/maxRows
    math, `overflow` toggling) is runtime DOM sizing — caller-owned; the
    object form maps to the caller setting `rows` / CSS.

  - `loading` — upstream renders its `NBaseSuffix` spinner whenever the
    `loading` prop is set (`Input.tsx:1345-1352`); here `loading = True`.
    DOM (the `NUI.BaseSelection` suffix idiom): `div.n-base-loading
    .n-base-suffix` (strokeWidth 24, scale 0.85, `role="img"
    aria-label="loading"`) > `__transition-wrapper` > `__container` > the
    spinner svg. It renders inside `.n-input__suffix` — which now appears
    for loading alone too — in upstream order `[clear, loading, suffix
    slot]` (`internalLoadingBeforeSuffix` defaults true).

  - `inputAttributes` — upstream's `inputProps`: raw attributes onto the
    inner `<input>` / `<textarea>` element (upstream demos pass
    `autocomplete='disabled'`, `id`, `max`). The field-owned attributes
    (`type` / `value` / `placeholder` / `maxlength` / `minlength` /
    `disabled` / `readonly` / `rows` / the input event) always render
    FIRST and win duplicate names (HTML keeps the first occurrence; the
    raw list appends after) — pass only attributes the fields above don't
    own.

Picker-trigger seams (all default-off — the standalone input renders
byte-identically without them; upstream drives them from the picker
components' `NInput` invocations):

  - `passivelyActivated` / `activated` — the manual-activation focus split
    (upstream `Input.tsx:1140-1143` on the root, `:1203` / `:1273` / `:1410`
    on the inner elements): while `passivelyActivated && !activated` the ROOT
    carries `tabindex 0` (iff not disabled) and the inner input / textarea
    carry `tabindex -1`. Enter / Escape activation
    (`handleWrapperKeydownEnter` / `...Esc`) and programmatic focus
    (`focus()` / `activate()`) are caller-owned runtime — no ports in house
    style; flip `activated` yourself.

  - `internalForceFocus` — upstream's visual-only focus seam (`mergedFocus`,
    `Input.tsx:283-285`): adds `n-input--focus` to the root. Upstream has NO
    `--active` / `--hover` classes at all (hover is pure CSS `:hover`,
    activation is state-only).

  - `textDecoration` — inline `text-decoration` on the input / textarea
    element (upstream `:1208` / `:1269`; the pickers pass `'line-through'`
    while the value is invalid).

  - `attrSize` — the native `size` attribute on the `<input>` only (upstream
    `:1288`; the default 20 equals the HTML default, so it is emitted only
    when set — TimePicker passes `format.length + 4`). Never the textarea.

  - `onFocus` / `onBlur` — raw focus / blur events on the input / textarea
    element; in pair mode BOTH inputs carry them (upstream `Input.tsx:1289` /
    `:1422` binds focus/blur on each pair input — mirrored into `pairEvents`
    2026-10 after the live smoke found a pair trigger wired like DatePicker's
    daterange could never hear a focus).

  - pair mode — upstream `Input.tsx:1395-1465`. Set `pairValue = Just (
    start, end )` and the root gains `n-input--pair` and the body becomes
    `div.n-input-wrapper` (input 1, NO suffix) → `span.n-input__separator`
    (`separatorNode`) → `div.n-input-wrapper` (input 2 + the pair-only
    `div.n-input__suffix`). Input 1 carries the `attrSize` `size` attribute and
    `pairTextDecoration`'s first half; input 2 carries neither (`Input.tsx:1434`
    — no `inputProps` spread, no `size`). Typing emits through `onPairInput`
    with the whole pair and a `PairSource` tag (`PairFirst` / `PairSecond`; the
    clear control emits `("", "")` + `PairClear`, upstream's `0 | 1 | 'clear'`).
    Standalone single-input bytes are unchanged — every field defaults off.

  - `extraRootClasses` — upstream's fallthrough `class` merge onto the
    `.n-input` root (the pickers pass their own marker here, e.g.
    `n-date-panel-date-input`); appended after the component classes.

  - `extraRootAttributes` — upstream's fallthrough `style`/attrs onto the
    root (ColorPicker's alpha unit passes `flex-grow: 1.25` here,
    `ColorInputUnit.tsx:162`); appended after the component's own, so a
    duplicate name wins HTML's first-occurrence rule against them — pass
    only attributes the component does not own.

  - `clearIconPlaceholder` — upstream's `clear-icon-placeholder` slot: the
    content shown inside `NBaseClear`'s placeholder while the clear button
    is hidden. `NBaseClear` renders iff `clearable` OR this is set (upstream
    `:1324-1346`), but the `.n-input__suffix` wrapper itself still needs
    `clearable` / a suffix / loading (upstream's own suffix condition,
    `:1316-1320`) — exactly as upstream. A picker's icon rides this slot
    when `clearable` (it swaps to the clear icon over a value) and `suffix`
    otherwise. The port's `NBaseClear` DOM diverges from upstream only in
    carrying the `_internal/clear` rules as inline styles (that cssr is not
    part of the generated stylesheet — the existing clear implementation's
    divergence); an `Element` here embeds with `display:contents`
    (`clearPlaceholder` is the raw-`Html` twin).

-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Theme exposing (Theme)
import NUI.Theme.Input as InputTheme
import NUI.Types as T exposing (Size(..))
import Svg


{-| Naive UI's `type` prop (`text` | `password` | `textarea`).
-}
type InputType
    = Text
    | Password
    | Textarea


{-| Naive UI's form validation `status` (`success` | `warning` | `error`).
Upstream's input cssr only renders `warning` / `error` (`input.cssr.ts:349`,
`['warning', 'error'].map(...)`) — a `success` input emits
`n-input--success-status` but no rule targets it, so it falls back to the default
gray border. The port closes that gap in-component (`statusVars`): the
`success` status rebinds the same resting / hover / focus border vars the base
rules read to the success family, so the border turns green without new CSS.
-}
type Status
    = Success
    | Warning
    | Error


{-| Which side of a pair input changed (upstream's `source: 0 | 1 | 'clear'`).
-}
type PairSource
    = PairFirst
    | PairSecond
    | PairClear


type alias Options msg =
    { value : String
    , onInput : Maybe (String -> msg)
    , placeholder : Maybe String
    , size : Size
    , type_ : InputType
    , status : Maybe Status
    , disabled : Bool
    , readonly : Bool
    , round : Bool
    , clearable : Bool
    , bordered : Bool
    , stateful : Bool
    , resizable : Bool
    , autosize : Bool
    , rows : Int
    , maxlength : Maybe Int
    , minlength : Maybe Int
    , prefix : Maybe (Element msg)
    , suffix : Maybe (Element msg)
    , clearPlaceholder : Maybe (Html.Html msg)
    , rtl : Bool
    , loading : Bool
    , inputAttributes : List (Html.Attribute msg)
    , passivelyActivated : Bool
    , activated : Bool
    , internalForceFocus : Bool
    , textDecoration : Maybe String
    , attrSize : Maybe Int
    , onFocus : Maybe msg
    , onBlur : Maybe msg
    , clearIconPlaceholder : Maybe (Element msg)
    , pairValue : Maybe ( String, String )
    , pairPlaceholder : Maybe ( String, String )
    , pairTextDecoration : Maybe ( String, String )
    , separatorNode : Maybe (Element msg)
    , onPairInput : Maybe (( String, String ) -> PairSource -> msg)
    , varOverrides : List ( String, String )
    , extraRootClasses : List String
    , extraRootAttributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { value = ""
    , onInput = Nothing
    , placeholder = Nothing
    , size = Medium
    , type_ = Text
    , status = Nothing
    , disabled = False
    , readonly = False
    , round = False
    , clearable = False
    , bordered = True
    , stateful = True
    , resizable = True
    , autosize = False
    , rows = 3
    , maxlength = Nothing
    , minlength = Nothing
    , prefix = Nothing
    , suffix = Nothing
    , clearPlaceholder = Nothing
    , rtl = False
    , loading = False
    , inputAttributes = []
    , passivelyActivated = False
    , activated = False
    , internalForceFocus = False
    , textDecoration = Nothing
    , attrSize = Nothing
    , onFocus = Nothing
    , onBlur = Nothing
    , clearIconPlaceholder = Nothing
    , pairValue = Nothing
    , pairPlaceholder = Nothing
    , pairTextDecoration = Nothing
    , separatorNode = Nothing
    , onPairInput = Nothing
    , varOverrides = []
    , extraRootClasses = []
    , extraRootAttributes = []
    }


view : Theme -> Options msg -> Element msg
view theme opts =
    let
        isTextarea =
            opts.type_ == Textarea

        borderEls =
            if opts.bordered then
                [ emptyEl "n-input__border"
                , emptyEl "n-input__state-border"
                ]

            else
                []

        children =
            case opts.pairValue of
                Just _ ->
                    pairBody opts

                Nothing ->
                    [ singleWrapper opts ]
    in
    Element.row
        ([ I.classes (rootClasses opts isTextarea)
         , I.cssVars
            (I.applyVarOverrides opts.varOverrides
                (I.applyVarOverrides (statusVars theme opts.status)
                    (cssVars theme opts.size (InputTheme.vars theme))
                )
            )
         ]
            ++ passiveRootTabindex opts
            ++ opts.extraRootAttributes
        )
        (children ++ borderEls)


{-| The single (non-pair) body: the one wrapper with the input area and the
suffix block.
-}
singleWrapper : Options msg -> Element msg
singleWrapper opts =
    Element.row [ I.classes [ "n-input-wrapper" ] ] <|
        List.concat
            [ case opts.prefix of
                Just p ->
                    [ prefixEl p ]

                Nothing ->
                    []
            , [ inputArea opts ]
            , suffixArea opts
            ]


{-| The wrapper's `tabindex 0` under manual activation (upstream
`Input.tsx:1140-1143`): the root is focusable only while passively
activated, not yet activated, and not disabled.
-}
passiveRootTabindex : Options msg -> List (Element.Attribute msg)
passiveRootTabindex opts =
    if opts.passivelyActivated && not opts.activated && not opts.disabled then
        [ Element.htmlAttribute (HA.tabindex 0) ]

    else
        []


emptyEl : String -> Element msg
emptyEl c =
    Element.el [ I.classes [ c ] ] Element.none


prefixEl : Element msg -> Element msg
prefixEl p =
    Element.row [ I.classes [ "n-input__prefix" ] ] [ p ]



-- input / textarea area ------------------------------------------------------
--
-- Rendered as raw Html (embedded with `Element.html`) rather than elm-ui
-- elements: Naive UI's `.n-input__input` is a plain block div and a plain flex
-- item (`flex-shrink: 1`), while elm-ui's `.s` class would force
-- `flex-shrink: 0` and make long values overflow the bordered box instead of
-- clipping. The DOM ends up identical to Naive UI's.


inputArea : Options msg -> Element msg
inputArea opts =
    Element.html <|
        case opts.type_ of
            Textarea ->
                Html.div [ HA.class "n-input__textarea" ]
                    (Html.textarea
                        ([ HA.class "n-input__textarea-el"
                         , HA.rows opts.rows
                         , HA.value opts.value
                         , HA.disabled opts.disabled
                         , HA.readonly opts.readonly
                         ]
                            ++ placeholderAttrs opts
                            ++ lengthAttrs opts
                            ++ triggerAttrs opts
                            ++ inputEvents opts
                            ++ opts.inputAttributes
                        )
                        []
                        :: placeholderHtml False opts
                    )

            _ ->
                Html.div [ HA.class "n-input__input" ]
                    (Html.input
                        ([ HA.class "n-input__input-el"
                         , HA.type_ (nativeType opts.type_)
                         , HA.value opts.value
                         , HA.disabled opts.disabled
                         , HA.readonly opts.readonly
                         ]
                            ++ placeholderAttrs opts
                            ++ lengthAttrs opts
                            ++ triggerAttrs opts
                            ++ attrSizeAttrs opts
                            ++ inputEvents opts
                            ++ opts.inputAttributes
                        )
                        []
                        :: placeholderHtml True opts
                    )


nativeType : InputType -> String
nativeType t =
    case t of
        Text ->
            "text"

        Password ->
            "password"

        Textarea ->
            "text"


{-| Naive UI hides the native `::placeholder` through CSS and renders its own
`.n-input__placeholder` layer while the value is empty; it still sets the
native attribute (autofill, a11y). Same here.
-}
placeholderAttrs : Options msg -> List (Html.Attribute msg)
placeholderAttrs opts =
    nonEmptyPlaceholder opts
        |> Maybe.map (\p -> [ HA.placeholder p ])
        |> Maybe.withDefault []


placeholderHtml : Bool -> Options msg -> List (Html msg)
placeholderHtml withSpan opts =
    case nonEmptyPlaceholder opts of
        Just ph ->
            if String.isEmpty opts.value then
                [ Html.div [ HA.class "n-input__placeholder" ]
                    [ if withSpan then
                        Html.span [] [ Html.text ph ]

                      else
                        Html.text ph
                    ]
                ]

            else
                []

        Nothing ->
            []


nonEmptyPlaceholder : Options msg -> Maybe String
nonEmptyPlaceholder opts =
    opts.placeholder
        |> Maybe.andThen
            (\p ->
                if String.isEmpty p then
                    Nothing

                else
                    Just p
            )


lengthAttrs : Options msg -> List (Html.Attribute msg)
lengthAttrs opts =
    List.filterMap identity
        [ Maybe.map HA.maxlength opts.maxlength
        , Maybe.map HA.minlength opts.minlength
        ]


inputEvents : Options msg -> List (Html.Attribute msg)
inputEvents opts =
    case opts.onInput of
        Just f ->
            [ HE.onInput f ]

        Nothing ->
            []


{-| The picker-trigger attributes shared by the input and the textarea: the
manual-activation `tabindex -1` (upstream `:1203` / `:1273`), the inline
`text-decoration` (`:1208` / `:1269`), and the raw focus / blur events. All
default-off.
-}
triggerAttrs : Options msg -> List (Html.Attribute msg)
triggerAttrs opts =
    (if opts.passivelyActivated && not opts.activated then
        [ HA.tabindex -1 ]

     else
        []
    )
        ++ (case opts.textDecoration of
                Just d ->
                    [ HA.style "text-decoration" d ]

                Nothing ->
                    []
           )
        ++ (case opts.onFocus of
                Just m ->
                    [ HE.onFocus m ]

                Nothing ->
                    []
           )
        ++ (case opts.onBlur of
                Just m ->
                    [ HE.onBlur m ]

                Nothing ->
                    []
           )


{-| The native `size` attribute — the `<input>` only (upstream `:1288`);
emitted only when set (the default 20 equals the HTML default, so a bare
input renders attribute-less, byte-identically).
-}
attrSizeAttrs : Options msg -> List (Html.Attribute msg)
attrSizeAttrs opts =
    case opts.attrSize of
        Just n ->
            [ HA.attribute "size" (String.fromInt n) ]

        Nothing ->
            []



-- pair mode (upstream `Input.tsx:1395-1465`) ------------------------------------


{-| The pair body — wrapper 1 (no suffix) / separator / wrapper 2 (+ suffix).
-}
pairBody : Options msg -> List (Element msg)
pairBody opts =
    [ Element.row [ I.classes [ "n-input-wrapper" ] ] <|
        List.concat
            [ case opts.prefix of
                Just p ->
                    [ prefixEl p ]

                Nothing ->
                    []
            , [ pairInputArea opts 0 ]
            ]
    , Element.html <|
        Html.span [ HA.class "n-input__separator" ]
            (case opts.separatorNode of
                Just node ->
                    [ embedEl node ]

                Nothing ->
                    []
            )
    , Element.row [ I.classes [ "n-input-wrapper" ] ]
        (pairInputArea opts 1 :: pairSuffixArea opts)
    ]


{-| One side of the pair — the plain `.n-input__input` block (raw `Html`, the
`inputArea` idiom). Input 1 carries the `size` attribute and input properties;
input 2 carries neither (`Input.tsx:1406-1438`).
-}
pairInputArea : Options msg -> Int -> Element msg
pairInputArea opts index =
    let
        ( value, placeholder, decoration ) =
            pairParts opts index

        inputEl =
            Html.input
                ([ HA.class "n-input__input-el"
                 , HA.type_ "text"
                 , HA.value value
                 , HA.disabled opts.disabled
                 , HA.readonly opts.readonly
                 ]
                    ++ (placeholder
                            |> Maybe.map (\p -> [ HA.placeholder p ])
                            |> Maybe.withDefault []
                       )
                    ++ pairTriggerAttrs opts index decoration
                )
                []

        placeholderEl =
            if String.isEmpty value then
                case placeholder of
                    Just p ->
                        [ Html.div [ HA.class "n-input__placeholder" ]
                            [ Html.span [] [ Html.text p ] ]
                        ]

                    Nothing ->
                        []

            else
                []
    in
    Element.html (Html.div [ HA.class "n-input__input" ] (inputEl :: placeholderEl))


{-| The pair's per-side value / placeholder / text-decoration. An empty
placeholder string renders no native attribute / placeholder layer (mirrors
`nonEmptyPlaceholder`).
-}
pairParts : Options msg -> Int -> ( String, Maybe String, Maybe String )
pairParts opts index =
    let
        ( value, holder, decoration ) =
            case opts.pairValue of
                Just ( a, b ) ->
                    if index == 0 then
                        ( a, Maybe.map Tuple.first opts.pairPlaceholder, Maybe.map Tuple.first opts.pairTextDecoration )

                    else
                        ( b, Maybe.map Tuple.second opts.pairPlaceholder, Maybe.map Tuple.second opts.pairTextDecoration )

                Nothing ->
                    ( "", Nothing, Nothing )

        nonEmpty p =
            if String.isEmpty p then
                Nothing

            else
                Just p
    in
    ( value, Maybe.andThen nonEmpty holder, Maybe.andThen nonEmpty decoration )


{-| The picker-trigger attributes for one side of the pair: the manual-activation
`tabindex -1` (`Input.tsx:1410`), the inline `text-decoration`
(`Input.tsx:1434`), the `size` attribute on input 1 only (`Input.tsx:1288`),
the `onInput` event tagged with the pair source, and the raw focus / blur
events (upstream binds both on EVERY pair input, `Input.tsx:1289/1422`).
-}
pairTriggerAttrs : Options msg -> Int -> Maybe String -> List (Html.Attribute msg)
pairTriggerAttrs opts index decoration =
    (if opts.passivelyActivated && not opts.activated then
        [ HA.tabindex -1 ]

     else
        []
    )
        ++ (case decoration of
                Just d ->
                    [ HA.style "text-decoration" d ]

                Nothing ->
                    []
           )
        ++ (if index == 0 then
                attrSizeAttrs opts

            else
                []
           )
        ++ pairEvents opts index


{-| The pair's events: `onInput` tagged with the pair source, then the raw
focus / blur events mirrored from single mode (upstream binds focus/blur on
BOTH pair inputs regardless of the input handler, `Input.tsx:1289/1422`).
-}
pairEvents : Options msg -> Int -> List (Html.Attribute msg)
pairEvents opts index =
    (case opts.onPairInput of
        Just toMsg ->
            let
                ( a, b ) =
                    case opts.pairValue of
                        Just pair ->
                            pair

                        Nothing ->
                            ( "", "" )
            in
            [ HE.onInput
                (\v ->
                    if index == 0 then
                        toMsg ( v, b ) PairFirst

                    else
                        toMsg ( a, v ) PairSecond
                )
            ]

        Nothing ->
            []
    )
        ++ (case opts.onFocus of
                Just m ->
                    [ HE.onFocus m ]

                Nothing ->
                    []
           )
        ++ (case opts.onBlur of
                Just m ->
                    [ HE.onBlur m ]

                Nothing ->
                    []
           )


{-| The pair-only suffix — `div.n-input__suffix` renders iff `clearable` OR a
suffix slot is set (`Input.tsx:1441-1463`); no loading / count / eye participate
in the pair suffix.
-}
pairSuffixArea : Options msg -> List (Element msg)
pairSuffixArea opts =
    if opts.clearable || opts.suffix /= Nothing then
        [ Element.row [ I.classes [ "n-input__suffix" ] ] <|
            List.concat
                [ pairClearArea opts
                , case opts.suffix of
                    Just s ->
                        [ s ]

                    Nothing ->
                        []
                ]
        ]

    else
        []


pairClearArea : Options msg -> List (Element msg)
pairClearArea opts =
    if not opts.clearable then
        []

    else
        [ Element.html <|
            Html.div
                [ HA.class "n-base-clear"
                , HA.style "flex-shrink" "0"
                , HA.style "height" "1em"
                , HA.style "width" "1em"
                , HA.style "position" "relative"
                ]
                [ if pairShowClear opts then
                    pairClearButton opts

                  else
                    clearPlaceholder opts
                ]
        ]


pairShowClear : Options msg -> Bool
pairShowClear opts =
    not opts.disabled
        && not opts.readonly
        && (case opts.pairValue of
                Just ( a, b ) ->
                    not (String.isEmpty a && String.isEmpty b)

                Nothing ->
                    False
           )


pairClearButton : Options msg -> Html msg
pairClearButton opts =
    Html.div
        ([ HA.class "n-base-clear__clear"
         , HA.attribute "data-clear" "true"
         , HA.style "font-size" "var(--n-clear-size)"
         , HA.style "height" "1em"
         , HA.style "width" "1em"
         , HA.style "cursor" "pointer"
         , HA.style "color" "var(--n-clear-color)"
         , HA.style "transition" "color .3s var(--n-bezier)"
         , HA.style "display" "flex"
         ]
            ++ centeredStyle
            ++ (case opts.onPairInput of
                    Just toMsg ->
                        [ HE.onClick (toMsg ( "", "" ) PairClear) ]

                    Nothing ->
                        []
               )
        )
        [ baseIcon clearIcon ]



-- suffix / clear button ------------------------------------------------------


suffixArea : Options msg -> List (Element msg)
suffixArea opts =
    if opts.clearable || opts.suffix /= Nothing || opts.loading then
        [ Element.row [ I.classes [ "n-input__suffix" ] ] <|
            List.concat
                [ clearArea opts
                , loadingArea opts
                , case opts.suffix of
                    Just s ->
                        [ s ]

                    Nothing ->
                        []
                ]
        ]

    else
        []


{-| Naive UI's `NBaseClear`. Its own cssr block (`_internal/clear`) is not part
of the generated stylesheet, so the rules are ported as inline styles; the
`--n-*` values still resolve from the `.n-input` root.
-}
clearArea : Options msg -> List (Element msg)
clearArea opts =
    if not opts.clearable && opts.clearIconPlaceholder == Nothing then
        []

    else
        [ Element.html <|
            Html.div
                [ HA.class "n-base-clear"
                , HA.style "flex-shrink" "0"
                , HA.style "height" "1em"
                , HA.style "width" "1em"
                , HA.style "position" "relative"
                ]
                [ if opts.clearable && showClear opts then
                    clearButton opts

                  else
                    clearPlaceholder opts
                ]
        ]


{-| Naive UI reveals the clear icon on hover / focus only; without internal
state we show it whenever there is something to clear. The placeholder div
keeps the reserved 1em slot exactly like Naive UI's hidden state.
-}
showClear : Options msg -> Bool
showClear opts =
    not opts.disabled
        && not opts.readonly
        && not (String.isEmpty opts.value)


clearButton : Options msg -> Html msg
clearButton opts =
    Html.div
        ([ HA.class "n-base-clear__clear"
         , HA.attribute "data-clear" "true"
         , HA.style "font-size" "var(--n-clear-size)"
         , HA.style "height" "1em"
         , HA.style "width" "1em"
         , HA.style "cursor" "pointer"
         , HA.style "color" "var(--n-clear-color)"
         , HA.style "transition" "color .3s var(--n-bezier)"
         , HA.style "display" "flex"
         ]
            ++ centeredStyle
            ++ clearClick opts
        )
        [ baseIcon clearIcon ]


clearClick : Options msg -> List (Html.Attribute msg)
clearClick opts =
    case opts.onInput of
        Just f ->
            [ HE.onClick (f "") ]

        Nothing ->
            []


clearPlaceholder : Options msg -> Html msg
clearPlaceholder opts =
    Html.div
        ([ HA.class "n-base-clear__placeholder"
         , HA.style "display" "flex"
         ]
            ++ centeredStyle
        )
        (case opts.clearIconPlaceholder of
            Just el ->
                [ embedEl el ]

            Nothing ->
                case opts.clearPlaceholder of
                    Just icon ->
                        [ icon ]

                    Nothing ->
                        []
        )


{-| An `Element` inside the raw clear DOM — embed through `layoutWith` with
`noStaticStyleSheet` (the `NUI.Scrollbar.embedChild` idiom) so no duplicate
elm-ui stylesheet lands and the node joins no layout.
-}
embedEl : Element msg -> Html msg
embedEl el =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        el


centeredStyle : List (Html.Attribute msg)
centeredStyle =
    [ HA.style "position" "absolute"
    , HA.style "left" "50%"
    , HA.style "top" "50%"
    , HA.style "transform" "translateX(-50%) translateY(-50%)"
    ]


{-| Naive UI's `NBaseIcon` (`_internal/icon` cssr, also not generated).
-}
baseIcon : Html msg -> Html msg
baseIcon icon =
    Html.div
        [ HA.class "n-base-icon"
        , HA.style "height" "1em"
        , HA.style "width" "1em"
        , HA.style "line-height" "1em"
        , HA.style "text-align" "center"
        , HA.style "display" "inline-block"
        , HA.style "position" "relative"
        , HA.style "fill" "currentColor"
        ]
        [ icon ]


{-| Naive UI's `ClearIcon` (16×16 dismiss circle).
-}
clearIcon : Html msg
clearIcon =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "width" "1em"
        , HA.attribute "height" "1em"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Svg.node "path" [ HA.attribute "d" clearPath ] [] ]
            ]
        ]


clearPath : String
clearPath =
    "M8,2 C11.3137085,2 14,4.6862915 14,8 C14,11.3137085 11.3137085,14 8,14 C4.6862915,14 2,11.3137085 2,8 C2,4.6862915 4.6862915,2 8,2 Z M6.5343055,5.83859116 C6.33943736,5.70359511 6.07001296,5.72288026 5.89644661,5.89644661 L5.89644661,5.89644661 L5.83859116,5.9656945 C5.70359511,6.16056264 5.72288026,6.42998704 5.89644661,6.60355339 L5.89644661,6.60355339 L7.293,8 L5.89644661,9.39644661 L5.83859116,9.4656945 C5.70359511,9.66056264 5.72288026,9.92998704 5.89644661,10.1035534 L5.89644661,10.1035534 L5.9656945,10.1614088 C6.16056264,10.2964049 6.42998704,10.2771197 6.60355339,10.1035534 L6.60355339,10.1035534 L8,8.707 L9.39644661,10.1035534 L9.4656945,10.1614088 C9.66056264,10.2964049 9.92998704,10.2771197 10.1035534,10.1035534 L10.1035534,10.1035534 L10.1614088,10.0343055 C10.2964049,9.83943736 10.2771197,9.57001296 10.1035534,9.39644661 L10.1035534,9.39644661 L8.707,8 L10.1035534,6.60355339 L10.1614088,6.5343055 C10.2964049,6.33943736 10.2771197,6.07001296 10.1035534,5.89644661 L10.1035534,5.89644661 L10.0343055,5.83859116 C9.83943736,5.70359511 9.57001296,5.72288026 9.39644661,5.89644661 L9.39644661,5.89644661 L8,7.293 L6.60355339,5.89644661 Z"


{-| The loading suffix — upstream mounts `NBaseSuffix` with `loading` and
`showArrow` / `showClear` both false (`Input.tsx:1345-1352`), which is the
`NUI.BaseSelection` suffix idiom reduced to the spinner alone: `NBaseLoading`
at strokeWidth 24 / scale 0.85 (radius 100), `role="img"`
`aria-label="loading"`, no idle placeholder slot. It renders between the
clear icon and the suffix slot — `internalLoadingBeforeSuffix` defaults
true (`Input.tsx:1353-1359`). Loading svgs render through
`NUI.Internal.Loading` (single source; upstream's `scale` is pure svg
geometry, `scaledRadius = radius / scale`, so the geometry renders the exact
`100 / 0.85` forms — circle `r` 88, dash 567 / 1848), and the svg now also
carries the upstream class `n-base-loading__icon`.
-}
loadingArea : Options msg -> List (Element msg)
loadingArea opts =
    if not opts.loading then
        []

    else
        [ Element.el
            [ I.classes [ "n-base-loading", "n-base-suffix" ]
            , Element.htmlAttribute (HA.attribute "role" "img")
            , Element.htmlAttribute (HA.attribute "aria-label" "loading")
            ]
            (Element.el
                [ I.classes [ "n-base-loading__transition-wrapper" ] ]
                (Element.el
                    [ I.classes [ "n-base-loading__container" ] ]
                    (Element.html
                        (Loading.spinner
                            { strokeWidth = 24
                            , radius = 100
                            , scale = 0.85
                            , stroke = Nothing
                            }
                        )
                    )
                )
            )
        ]



-- input group ----------------------------------------------------------------


{-| Naive UI's `n-input-group`: a full-width row that rounds off the inner
corners of its children. Takes any `NUI.Input.view` / `NUI.Button.view` /
`groupLabel` elements.
-}
group : List (Element msg) -> Element msg
group children =
    Element.row [ I.classes [ "n-input-group" ] ] children


{-| Naive UI's `n-input-group-label`.
-}
groupLabel : Theme -> { size : Size, bordered : Bool } -> List (Element msg) -> Element msg
groupLabel theme cfg children =
    let
        v =
            InputTheme.vars theme

        {- Naive UI renders label children as inline content of an
           `inline-block` root and centers them with `line-height: var(--n-height)`
           (the label CSS uses the height, not the line height). elm-ui elements
           are block-level with `line-height: 1` (`.s`), so restore inline flow
           and the root's line height on a wrapper.
        -}
        inline child =
            Element.el
                [ Element.htmlAttribute (HA.style "display" "inline-block")
                , Element.htmlAttribute (HA.style "line-height" "var(--n-height)")
                ]
                child

        borderEls =
            if cfg.bordered then
                [ emptyEl "n-input-group-label__border" ]

            else
                []
    in
    Element.row
        [ I.classes [ "n-input-group-label" ]
        , I.cssVars
            [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
            , ( "--n-group-label-color", v.groupLabelColor )
            , ( "--n-group-label-border", v.groupLabelBorder )
            , ( "--n-border-radius", v.borderRadius )
            , ( "--n-group-label-text-color", v.groupLabelTextColor )
            , ( "--n-font-size", fontSizeOf cfg.size v )
            , ( "--n-line-height", v.lineHeight )
            , ( "--n-height", heightOf cfg.size v )
            ]
        ]
        (List.map inline children ++ borderEls)



-- classes & vars ---------------------------------------------------------------


rootClasses : Options msg -> Bool -> List String
rootClasses opts isTextarea =
    List.concat
        [ [ "n-input"
          , "n-input--" ++ T.sizeClass opts.size ++ "-size"
          ]
        , case opts.status of
            Just s ->
                [ "n-input--" ++ statusClass s ++ "-status" ]

            Nothing ->
                []
        , I.classIf opts.rtl "n-input--rtl"
        , I.classIf opts.disabled "n-input--disabled"
        , I.classIf isTextarea "n-input--textarea"
        , I.classIf (isTextarea && opts.resizable && not opts.autosize) "n-input--resizable"
        , I.classIf opts.autosize "n-input--autosize"
        , I.classIf (opts.round && not isTextarea) "n-input--round"
        , I.classIf (opts.pairValue /= Nothing) "n-input--pair"
        , I.classIf opts.internalForceFocus "n-input--focus"
        , I.classIf opts.stateful "n-input--stateful"
        ]
        ++ opts.extraRootClasses


statusClass : Status -> String
statusClass s =
    case s of
        Success ->
            "success"

        Warning ->
            "warning"

        Error ->
            "error"


{-| Upstream's input stylesheet styles `warning` / `error` status only
(`input.cssr.ts:349`); `success` has no rules, so upstream's own
`n-input--success-status` falls back to the default gray border. The port fills
that gap by rebinding the three vars the base `n-input__border` /
`n-input__state-border` rules read (`--n-border` for rest, `--n-border-hover` /
`--n-border-focus` for the interactive states) to the success colour family —
the border turns the same green Naive UI uses for `success` elsewhere
(`theme.common.successColor` = `#18a058` light / `#63e2b7` dark) with no new CSS.
Every other status leaves the vars untouched.
-}
statusVars : Theme -> Maybe Status -> List ( String, String )
statusVars theme maybeStatus =
    case maybeStatus of
        Just Success ->
            [ ( "--n-border", "1px solid " ++ theme.common.successColor )
            , ( "--n-border-hover", "1px solid " ++ theme.common.successColorHover )
            , ( "--n-border-focus", "1px solid " ++ theme.common.successColorHover )
            ]

        _ ->
            []


{-| A faithful port of `Input.tsx`'s `cssVarsRef` (including the warning /
error / clear variables that only matter in states we may not reach).
-}
cssVars : Theme -> Size -> InputTheme.Vars -> List ( String, String )
cssVars theme size v =
    let
        ( paddingLeft, paddingRight ) =
            paddingSides (paddingOf size v)
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-count-text-color", v.countTextColor )
    , ( "--n-count-text-color-disabled", v.countTextColorDisabled )
    , ( "--n-color", v.color )
    , ( "--n-color-hover", v.colorHover )
    , ( "--n-font-size", fontSizeOf size v )
    , ( "--n-font-weight", v.fontWeight )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-height", heightOf size v )
    , ( "--n-padding-left", paddingLeft )
    , ( "--n-padding-right", paddingRight )
    , ( "--n-text-color", v.textColor )
    , ( "--n-caret-color", v.caretColor )
    , ( "--n-text-decoration-color", v.textDecorationColor )
    , ( "--n-border", v.border )
    , ( "--n-border-disabled", v.borderDisabled )
    , ( "--n-border-hover", v.borderHover )
    , ( "--n-border-focus", v.borderFocus )
    , ( "--n-placeholder-color", v.placeholderColor )
    , ( "--n-placeholder-color-disabled", v.placeholderColorDisabled )
    , ( "--n-icon-size", v.iconSize )
    , ( "--n-line-height-textarea", v.lineHeightTextarea )
    , ( "--n-color-disabled", v.colorDisabled )
    , ( "--n-color-focus", v.colorFocus )
    , ( "--n-text-color-disabled", v.textColorDisabled )
    , ( "--n-box-shadow-focus", v.boxShadowFocus )
    , ( "--n-loading-color", v.loadingColor )
    , ( "--n-caret-color-warning", v.caretColorWarning )
    , ( "--n-color-focus-warning", v.colorFocusWarning )
    , ( "--n-box-shadow-focus-warning", v.boxShadowFocusWarning )
    , ( "--n-border-warning", v.borderWarning )
    , ( "--n-border-focus-warning", v.borderFocusWarning )
    , ( "--n-border-hover-warning", v.borderHoverWarning )
    , ( "--n-loading-color-warning", v.loadingColorWarning )
    , ( "--n-caret-color-error", v.caretColorError )
    , ( "--n-color-focus-error", v.colorFocusError )
    , ( "--n-box-shadow-focus-error", v.boxShadowFocusError )
    , ( "--n-border-error", v.borderError )
    , ( "--n-border-focus-error", v.borderFocusError )
    , ( "--n-border-hover-error", v.borderHoverError )
    , ( "--n-loading-color-error", v.loadingColorError )
    , ( "--n-clear-color", v.clearColor )
    , ( "--n-clear-size", v.clearSize )
    , ( "--n-clear-color-hover", v.clearColorHover )
    , ( "--n-clear-color-pressed", v.clearColorPressed )
    , ( "--n-icon-color", v.iconColor )
    , ( "--n-icon-color-hover", v.iconColorHover )
    , ( "--n-icon-color-pressed", v.iconColorPressed )
    , ( "--n-icon-color-disabled", v.iconColorDisabled )
    , ( "--n-suffix-text-color", v.suffixTextColor )
    ]


{-| Port of seemly's `getPadding` shorthand split (only the sides we need).
-}
paddingSides : String -> ( String, String )
paddingSides padding =
    case String.words (String.trim padding) of
        [ one ] ->
            ( one, one )

        [ _, right ] ->
            ( right, right )

        [ _, right, _ ] ->
            ( right, right )

        [ _, right, _, left ] ->
            ( left, right )

        _ ->
            ( padding, padding )


paddingOf : Size -> InputTheme.Vars -> String
paddingOf size v =
    case size of
        Tiny ->
            v.paddingTiny

        Small ->
            v.paddingSmall

        Medium ->
            v.paddingMedium

        Large ->
            v.paddingLarge


fontSizeOf : Size -> InputTheme.Vars -> String
fontSizeOf size v =
    case size of
        Tiny ->
            v.fontSizeTiny

        Small ->
            v.fontSizeSmall

        Medium ->
            v.fontSizeMedium

        Large ->
            v.fontSizeLarge


heightOf : Size -> InputTheme.Vars -> String
heightOf size v =
    case size of
        Tiny ->
            v.heightTiny

        Small ->
            v.heightSmall

        Medium ->
            v.heightMedium

        Large ->
            v.heightLarge
