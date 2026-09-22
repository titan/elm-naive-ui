module NUI.Checkbox exposing
    ( Options
    , defaults
    , view
    )

{-| Naive UI's `Checkbox`, rebuilt on elm-ui.

    import NUI.Checkbox exposing (defaults)

    NUI.Checkbox.view theme NUI.Checkbox.defaults
        [ Element.text "Banana" ]

    NUI.Checkbox.view theme
        { defaults
            | checked = True
            , onCheck = Just Toggled
        }
        [ Element.text "Apple" ]

The list of child elements is the label slot (`naive-ui`'s default slot / `label`
prop); when it is empty no label element is rendered and the component shows only
the box.

The visual result is Naive UI's own: the element carries the `.n-checkbox` BEM
classes and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's
exact CSS.

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Checkbox as CheckboxTheme
import NUI.Types exposing (Size(..))
import Svg
import Svg.Attributes as SA


type alias Options msg =
    { size : Size
    , checked : Bool
    , indeterminate : Bool
    , disabled : Bool
    , focusable : Bool
    , onCheck : Maybe (Bool -> msg)
    , rtl : Bool
    }


defaults : Options msg
defaults =
    { size = Medium
    , checked = False
    , indeterminate = False
    , disabled = False
    , focusable = True
    , onCheck = Nothing
    , rtl = False
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts label =
    let
        v =
            CheckboxTheme.vars theme

        hasLabel =
            not (List.isEmpty label)

        box =
            Element.el
                [ I.classes [ "n-checkbox-box" ] ]
                (Element.row []
                    [ Element.el
                        [ I.classes [ "n-checkbox-icon" ] ]
                        (if opts.indeterminate then
                            lineMark

                         else
                            checkMark
                        )
                    , Element.el
                        [ I.classes [ "n-checkbox-box__border" ] ]
                        Element.none
                    ]
                )

        boxWrapper =
            Element.el
                [ I.classes [ "n-checkbox-box-wrapper" ] ]
                (Element.row []
                    [ Element.text "\u{00A0}", box ]
                )

        labelEl =
            if hasLabel then
                [ Element.el
                    [ I.classes [ "n-checkbox__label" ] ]
                    (Element.column [] label)
                ]

            else
                []

        classes =
            [ "n-checkbox" ]
                ++ I.classIf opts.rtl "n-checkbox--rtl"
                ++ I.classIf opts.checked "n-checkbox--checked"
                ++ I.classIf opts.disabled "n-checkbox--disabled"
                ++ I.classIf opts.indeterminate "n-checkbox--indeterminate"
                ++ I.classIf hasLabel "n-checkbox--show-label"

        interactive =
            [ Element.htmlAttribute (HA.attribute "role" "checkbox")
            , Element.htmlAttribute
                (HA.attribute "aria-checked"
                    (if opts.indeterminate then
                        "mixed"

                     else if opts.checked then
                        "true"

                     else
                        "false"
                    )
                )
            ]
                ++ (if opts.disabled || not opts.focusable then
                        []

                    else
                        [ Element.htmlAttribute (HA.tabindex 0) ]
                   )
                ++ (case opts.onCheck of
                        Just onCheck ->
                            if opts.disabled then
                                []

                            else
                                [ Events.onClick (onCheck (not opts.checked)) ]

                        Nothing ->
                            []
                   )
    in
    Element.row
        (I.classes classes
            :: I.cssVars (cssVars theme opts.size v)
            :: interactive
        )
        (boxWrapper :: labelEl)


cssVars : Theme -> Size -> CheckboxTheme.Vars -> List ( String, String )
cssVars theme size v =
    [ ( "--n-label-line-height", v.labelLineHeight )
    , ( "--n-label-font-weight", v.labelFontWeight )
    , ( "--n-size", sizeOf size v )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-border", v.border )
    , ( "--n-border-checked", v.borderChecked )
    , ( "--n-border-focus", v.borderFocus )
    , ( "--n-border-disabled", v.borderDisabled )
    , ( "--n-border-disabled-checked", v.borderDisabledChecked )
    , ( "--n-box-shadow-focus", v.boxShadowFocus )
    , ( "--n-color", v.color )
    , ( "--n-color-checked", v.colorChecked )
    , ( "--n-color-table", v.colorTableHeader )
    , ( "--n-color-table-modal", v.colorTableHeaderModal )
    , ( "--n-color-table-popover", v.colorTableHeaderPopover )
    , ( "--n-color-disabled", v.colorDisabled )
    , ( "--n-color-disabled-checked", v.colorDisabledChecked )
    , ( "--n-text-color", v.textColor )
    , ( "--n-text-color-disabled", v.textColorDisabled )
    , ( "--n-check-mark-color", v.checkMarkColor )
    , ( "--n-check-mark-color-disabled", v.checkMarkColorDisabled )
    , ( "--n-check-mark-color-disabled-checked", v.checkMarkColorDisabledChecked )
    , ( "--n-font-size", fontSizeOf size v )
    , ( "--n-label-padding", v.labelPadding )
    ]


{-| Naive UI's `createKey('size', size)` — the checkbox has no `tiny` scale,
so it falls back to `small`.
-}
sizeOf : Size -> CheckboxTheme.Vars -> String
sizeOf size v =
    case size of
        Tiny ->
            v.sizeSmall

        Small ->
            v.sizeSmall

        Medium ->
            v.sizeMedium

        Large ->
            v.sizeLarge


{-| Naive UI's `createKey('fontSize', size)`.
-}
fontSizeOf : Size -> CheckboxTheme.Vars -> String
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


{-| `renderCheckMark()` — the `.check-icon` svg, animated by Naive UI's CSS.
-}
checkMark : Element msg
checkMark =
    mark "check-icon"
        "0 0 64 64"
        "M50.42,16.76L22.34,39.45l-8.1-11.46c-1.12-1.58-3.3-1.96-4.88-0.84c-1.58,1.12-1.95,3.3-0.84,4.88l10.26,14.51  c0.56,0.79,1.42,1.31,2.38,1.45c0.16,0.02,0.32,0.03,0.48,0.03c0.8,0,1.57-0.27,2.2-0.78l30.99-25.03c1.5-1.21,1.74-3.42,0.52-4.92  C54.13,15.78,51.93,15.55,50.42,16.76z"


{-| `renderLineMark()` — the `.line-icon` svg shown while `indeterminate`.
-}
lineMark : Element msg
lineMark =
    mark "line-icon"
        "0 0 100 100"
        "M80.2,55.5H21.4c-2.8,0-5.1-2.5-5.1-5.5l0,0c0-3,2.3-5.5,5.1-5.5h58.7c2.8,0,5.1,2.5,5.1,5.5l0,0C85.2,53.1,82.9,55.5,80.2,55.5z"


mark : String -> String -> String -> Element msg
mark iconClass viewBox path =
    Element.html
        (Svg.node "svg"
            -- SA.class, not HA.class: the svg renders in the SVG namespace
            -- (Svg.node), where a `className` property fact throws — Svg's
            -- class is a plain `class` attribute.
            [ SA.class iconClass
            , HA.attribute "viewBox" viewBox
            ]
            [ Svg.node "path" [ HA.attribute "d" path ] [] ]
        )
