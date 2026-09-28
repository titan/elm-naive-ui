module NUI.Input exposing
    ( InputType(..)
    , Options
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


{-| Naive UI's form validation `status`. Only `warning` / `error` change the
look (exactly like Naive UI, whose CSS has no `success` rules either).
-}
type Status
    = Success
    | Warning
    | Error


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

        wrapper =
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
    in
    Element.row
        [ I.classes (rootClasses opts isTextarea)
        , I.cssVars (cssVars theme opts.size (InputTheme.vars theme))
        ]
        (wrapper :: borderEls)


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
                [ if showClear opts then
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
         , HA.attribute "data-clear" ""
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
        (case opts.clearPlaceholder of
            Just icon ->
                [ icon ]

            Nothing ->
                []
        )


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
        , I.classIf opts.stateful "n-input--stateful"
        ]


statusClass : Status -> String
statusClass s =
    case s of
        Success ->
            "success"

        Warning ->
            "warning"

        Error ->
            "error"


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
