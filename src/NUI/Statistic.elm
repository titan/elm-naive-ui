module NUI.Statistic exposing
    ( Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Statistic`, rebuilt on elm-ui.

    NUI.Statistic.view theme
        { NUI.Statistic.defaults | label = Just "Active users", value = Just "128" }
        []

    -- a custom value (default slot) instead of the `value` string
    NUI.Statistic.view theme
        { NUI.Statistic.defaults
            | label = Just "Growth"
            , prefix = Just (Element.text "$")
            , suffix = Just (Element.text "USD")
        }
        [ Element.text "1,024" ]

The element carries the `.n-statistic` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

The `value` prop wins over the default slot, exactly as upstream: when `value` is
set the slot is ignored.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Statistic as StatisticTheme


type alias Options msg =
    { label : Maybe String
    , value : Maybe String
    , tabularNums : Bool
    , prefix : Maybe (Element msg)
    , suffix : Maybe (Element msg)
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { label = Nothing
    , value = Nothing
    , tabularNums = False
    , prefix = Nothing
    , suffix = Nothing
    , rtl = False
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        labelEl =
            case opts.label of
                Just label ->
                    [ Element.el
                        [ I.classes [ "n-statistic__label" ] ]
                        (Element.text label)
                    ]

                Nothing ->
                    []

        contentEl =
            case opts.value of
                Just value ->
                    [ Element.el
                        [ I.classes [ "n-statistic-value__content" ] ]
                        (Element.text value)
                    ]

                Nothing ->
                    if List.isEmpty children then
                        []

                    else
                        [ Element.row
                            [ I.classes [ "n-statistic-value__content" ] ]
                            children
                        ]

        prefixEl =
            Maybe.map
                (\p ->
                    Element.el
                        [ I.classes [ "n-statistic-value__prefix" ] ]
                        p
                )
                opts.prefix

        suffixEl =
            Maybe.map
                (\s ->
                    Element.el
                        [ I.classes [ "n-statistic-value__suffix" ] ]
                        s
                )
                opts.suffix

        valueEl =
            Element.row
                (I.classes [ "n-statistic-value" ]
                    :: tabularStyle opts.tabularNums
                )
                (List.filterMap identity [ prefixEl ]
                    ++ contentEl
                    ++ List.filterMap identity [ suffixEl ]
                )
    in
    Element.column
        (I.classes
            ("n-statistic"
                :: I.classIf opts.rtl "n-statistic--rtl"
            )
            :: I.cssVars (cssVarsFor theme opts)
            :: opts.attributes
        )
        (labelEl ++ [ valueEl ])


{-| Upstream sets `font-variant-numeric` to `''` when off (a no-op); we simply
omit the inline style then.
-}
tabularStyle : Bool -> List (Element.Attribute msg)
tabularStyle on =
    if on then
        [ I.cssVars [ ( "font-variant-numeric", "tabular-nums" ) ] ]

    else
        []


cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme _ =
    let
        v =
            StatisticTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-label-font-size", v.labelFontSize )
    , ( "--n-label-font-weight", v.labelFontWeight )
    , ( "--n-label-text-color", v.labelTextColor )
    , ( "--n-value-font-weight", v.valueFontWeight )
    , ( "--n-value-font-size", v.valueFontSize )
    , ( "--n-value-prefix-text-color", v.valuePrefixTextColor )
    , ( "--n-value-suffix-text-color", v.valueSuffixTextColor )
    , ( "--n-value-text-color", v.valueTextColor )
    ]
