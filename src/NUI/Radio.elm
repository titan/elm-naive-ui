module NUI.Radio exposing
    ( Choice
    , GroupOptions
    , Options
    , button
    , choice
    , defaults
    , group
    , groupDefaults
    , view
    )

{-| Naive UI's `Radio` and `RadioGroup`, rebuilt on elm-ui.

    NUI.Radio.view theme
        { NUI.Radio.defaults | checked = True }
        [ Element.text "歌单" ]

    NUI.Radio.group theme
        { NUI.Radio.groupDefaults
            | value = Just model.city
            , onChange = Just SetCity
        }
        [ NUI.Radio.choice "Beijing" "北京"
        , NUI.Radio.choice "Shanghai" "上海"
        , NUI.Radio.choice "Guangzhou" "广州"
        ]

    -- button group (Naive UI's `n-radio-button` children)
    NUI.Radio.group theme
        { NUI.Radio.groupDefaults | value = Just model.size, onChange = Just SetSize }
        [ NUI.Radio.button "small" "小"
        , NUI.Radio.button "medium" "中"
        , NUI.Radio.button "large" "大"
        ]

The visual result is Naive UI's own: elements carry the `.n-radio` /
`.n-radio-group` BEM classes and Naive UI's `--n-*` custom properties, and
`NUI.Css` ships Naive UI's exact CSS.

Notes on the port:

  - Radio is check-only, like the original: activating an already-checked
    radio fires nothing, and a radio cannot be unchecked by clicking it.
  - A group disables a choice when either the group or the choice is disabled.
  - `Tiny` clamps to `Small` — Naive UI's radio scale has no tiny step.
  - String labels render pixel-identical to Naive UI. Custom `Element` label
    content is aligned but renders at elm-ui's `line-height: 1` (elm-ui forces
    it on text wrappers; see `NUI.Internal` and `tools/bridge.css`).
  - Naive UI's `--focus` ring is driven by native input focus events and is
    not reproduced (stateless view).

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Radio as RadioTheme
import NUI.Types exposing (Size(..))


type alias Options msg =
    { size : Size
    , checked : Bool
    , disabled : Bool
    , label : Maybe String
    , onChange : Maybe msg
    , rtl : Bool
    }


defaults : Options msg
defaults =
    { size = Medium
    , checked = False
    , disabled = False
    , label = Nothing
    , onChange = Nothing
    , rtl = False
    }


{-| One entry of a radio group: value, label text, and whether it is disabled.
`choice` renders Naive UI's `n-radio`, `button` its `n-radio-button`.
-}
type alias Choice value =
    { value : value
    , label : String
    , disabled : Bool
    , button : Bool
    }


choice : value -> String -> Choice value
choice value label =
    { value = value, label = label, disabled = False, button = False }


button : value -> String -> Choice value
button value label =
    { value = value, label = label, disabled = False, button = True }


type alias GroupOptions value msg =
    { value : Maybe value
    , onChange : Maybe (value -> msg)
    , size : Size
    , disabled : Bool
    , rtl : Bool
    }


groupDefaults : GroupOptions value msg
groupDefaults =
    { value = Nothing
    , onChange = Nothing
    , size = Medium
    , disabled = False
    , rtl = False
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        v =
            RadioTheme.vars theme

        {- The `&nbsp;` gives the wrapper its height, exactly as in Naive UI's
           render. Raw text (not `Element.text`) so it inherits this
           element's line-height instead of elm-ui's forced `line-height: 1`
           — which only matches Naive UI for string labels, so the inline
           line-height below is attached in that case only.
        -}
        stringLabel =
            List.isEmpty children && opts.label /= Nothing

        dotWrapper =
            Element.row
                ([ I.classes [ "n-radio__dot-wrapper" ] ]
                    ++ (if stringLabel then
                            [ I.cssVars [ ( "line-height", "var(--n-label-line-height)" ) ] ]

                        else
                            []
                       )
                )
                [ Element.html (Html.text "\u{00A0}")
                , Element.el
                    [ I.classes ("n-radio__dot" :: I.classIf opts.checked "n-radio__dot--checked") ]
                    Element.none
                ]

        {- Naive UI renders the label div only when there is content, and as
           plain HTML: slot children win over the `label` prop.
        -}
        labelEl =
            if not (List.isEmpty children) then
                [ Element.row [ I.classes [ "n-radio__label" ] ] children ]

            else
                opts.label
                    |> Maybe.map
                        (\s ->
                            [ Element.html
                                (Html.div [ HA.class "n-radio__label" ] [ Html.text s ])
                            ]
                        )
                    |> Maybe.withDefault []
    in
    Element.row
        (I.classes
            ("n-radio"
                :: I.classIf opts.rtl "n-radio--rtl"
                ++ I.classIf opts.disabled "n-radio--disabled"
                ++ I.classIf opts.checked "n-radio--checked"
            )
            :: I.cssVars (radioCssVars theme v opts.size)
            :: interactive opts.disabled opts.checked opts.onChange
        )
        (dotWrapper :: labelEl)


group : Theme -> GroupOptions value msg -> List (Choice value) -> Element msg
group theme opts choices =
    let
        v =
            RadioTheme.vars theme

        isButtonGroup =
            List.any .button choices

        isChecked c =
            opts.value == Just c.value

        {- Naive UI's splitor priority (checked beats enabled beats rest),
           computed from the raw choice props just like `mapSlot` does.
        -}
        splitorBetween a b =
            let
                priority c =
                    (if isChecked c then
                        2

                     else
                        0
                    )
                        + (if c.disabled then
                            0

                           else
                            1
                          )

                side =
                    if priority a < priority b then
                        b

                    else
                        a
            in
            Element.el
                [ I.classes
                    ("n-radio-group__splitor"
                        :: I.classIf side.disabled "n-radio-group__splitor--disabled"
                        ++ I.classIf (isChecked side) "n-radio-group__splitor--checked"
                    )
                ]
                Element.none

        child c =
            let
                disabled =
                    opts.disabled || c.disabled

                {- Check-only: an already-checked radio fires nothing. -}
                onChange =
                    if isChecked c || disabled then
                        Nothing

                    else
                        Maybe.map (\f -> f c.value) opts.onChange
            in
            if c.button then
                radioButton (isChecked c) disabled onChange c.label

            else
                view theme
                    { defaults
                        | size = opts.size
                        , checked = isChecked c
                        , disabled = disabled
                        , label = Just c.label
                        , onChange = onChange
                    }
                    []

        {- Splitors sit between consecutive buttons, as in `mapSlot`. -}
        splitored cs =
            case cs of
                [] ->
                    []

                [ c ] ->
                    [ child c ]

                c :: (d :: _) ->
                    child c :: splitorBetween c d :: splitored (List.drop 1 cs)
    in
    Element.row
        [ I.classes
            ("n-radio-group"
                :: I.classIf opts.rtl "n-radio-group--rtl"
                ++ I.classIf isButtonGroup "n-radio-group--button-group"
            )
        , I.cssVars (groupCssVars theme v opts.size)
        ]
        (if isButtonGroup then
            splitored choices

         else
            List.map child choices
        )


{-| Naive UI's `RadioButton`: markup only — its values come from the group's
inline custom properties, which is why it carries no `cssVars` of its own.
-}
radioButton : Bool -> Bool -> Maybe msg -> String -> Element msg
radioButton checked disabled onChange label =
    Element.row
        (I.classes
            ("n-radio-button"
                :: I.classIf disabled "n-radio-button--disabled"
                ++ I.classIf checked "n-radio-button--checked"
            )
            :: interactive disabled False onChange
        )
        [ Element.el [ I.classes [ "n-radio-button__state-border" ] ] Element.none
        , Element.html (Html.div [ HA.class "n-radio__label" ] [ Html.text label ])
        ]


{-| The original's hidden native `<input type="radio">` is dropped, as with
`NUI.Button`: a labelled div with `role`/`tabindex` renders identically.
-}
interactive : Bool -> Bool -> Maybe msg -> List (Element.Attribute msg)
interactive disabled checked onChange =
    if disabled then
        [ Element.htmlAttribute (HA.attribute "aria-disabled" "true") ]

    else
        [ Element.htmlAttribute (HA.attribute "role" "radio")
        , Element.htmlAttribute
            (HA.attribute "aria-checked"
                (if checked then
                    "true"

                 else
                    "false"
                )
            )
        , Element.htmlAttribute (HA.tabindex 0)
        ]
            ++ (if checked then
                    []

                else
                    case onChange of
                        Just msg ->
                            [ Events.onClick msg ]

                        Nothing ->
                            []
               )


radioCssVars : Theme -> RadioTheme.Vars -> Size -> List ( String, String )
radioCssVars theme v size =
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-label-line-height", v.labelLineHeight )
    , ( "--n-label-font-weight", v.labelFontWeight )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-box-shadow-active", v.boxShadowActive )
    , ( "--n-box-shadow-disabled", v.boxShadowDisabled )
    , ( "--n-box-shadow-focus", v.boxShadowFocus )
    , ( "--n-box-shadow-hover", v.boxShadowHover )
    , ( "--n-color", v.color )
    , ( "--n-color-active", v.colorActive )
    , ( "--n-color-disabled", v.colorDisabled )
    , ( "--n-dot-color-active", v.dotColorActive )
    , ( "--n-dot-color-disabled", v.dotColorDisabled )
    , ( "--n-font-size", fontSizeOf size v )
    , ( "--n-radio-size", radioSizeOf size v )
    , ( "--n-text-color", v.textColor )
    , ( "--n-text-color-disabled", v.textColorDisabled )
    , ( "--n-label-padding", v.labelPadding )
    ]


groupCssVars : Theme -> RadioTheme.Vars -> Size -> List ( String, String )
groupCssVars theme v size =
    [ ( "--n-font-size", fontSizeOf size v )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-button-border-color", v.buttonBorderColor )
    , ( "--n-button-border-color-active", v.buttonBorderColorActive )
    , ( "--n-button-border-radius", v.buttonBorderRadius )
    , ( "--n-button-box-shadow", v.buttonBoxShadow )
    , ( "--n-button-box-shadow-focus", v.buttonBoxShadowFocus )
    , ( "--n-button-box-shadow-hover", v.buttonBoxShadowHover )
    , ( "--n-button-color", v.buttonColor )
    , ( "--n-button-color-active", v.buttonColorActive )
    , ( "--n-button-text-color", v.buttonTextColor )
    , ( "--n-button-text-color-hover", v.buttonTextColorHover )
    , ( "--n-button-text-color-active", v.buttonTextColorActive )
    , ( "--n-height", buttonHeightOf size v )
    , ( "--n-opacity-disabled", v.opacityDisabled )
    ]


{-| Naive UI's radio scale has no tiny step; it clamps to small.
-}
fontSizeOf : Size -> RadioTheme.Vars -> String
fontSizeOf size v =
    case size of
        Tiny ->
            v.fontSizeSmall

        Small ->
            v.fontSizeSmall

        Medium ->
            v.fontSizeMedium

        Large ->
            v.fontSizeLarge


radioSizeOf : Size -> RadioTheme.Vars -> String
radioSizeOf size v =
    case size of
        Tiny ->
            v.radioSizeSmall

        Small ->
            v.radioSizeSmall

        Medium ->
            v.radioSizeMedium

        Large ->
            v.radioSizeLarge


buttonHeightOf : Size -> RadioTheme.Vars -> String
buttonHeightOf size v =
    case size of
        Tiny ->
            v.buttonHeightSmall

        Small ->
            v.buttonHeightSmall

        Medium ->
            v.buttonHeightMedium

        Large ->
            v.buttonHeightLarge
