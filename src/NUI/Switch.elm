module NUI.Switch exposing (Options, defaults, view)

{-| Naive UI's `Switch`, rebuilt on elm-ui.

    import NUI.Switch exposing (defaults)

    NUI.Switch.view theme NUI.Switch.defaults []

    NUI.Switch.view theme
        { defaults
            | value = model.active
            , onChange = Just Toggled
        }
        []

    NUI.Switch.view theme
        { defaults
            | checked = Element.text "Checked"
            , unchecked = Element.text "Unchecked"
        }
        []

The visual result is Naive UI's own: the element carries the `.n-switch` BEM
classes and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive
UI's exact CSS.

A switch shows different content depending on its state, so the `checked` /
`unchecked` / icon slots are `Options` fields; the `view` children argument is
there for API symmetry with the other components and is ignored.

-}

import Element exposing (Element)
import Element.Events as Events
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Theme exposing (Theme)
import NUI.Theme.Switch as SwitchTheme
import NUI.Types exposing (Size(..))


type alias Options msg =
    { value : Bool
    , onChange : Maybe (Bool -> msg)
    , disabled : Bool
    , size : Size
    , loading : Bool
    , spinStrokeWidth : Maybe Int
    , spinStroke : Maybe String
    , spinScale : Maybe Float
    , spinRadius : Maybe Int
    , round : Bool
    , rubberBand : Bool
    , railColor : Maybe String
    , railColorActive : Maybe String
    , railStyle : Maybe (Bool -> List ( String, String ))
    , checked : Maybe (Element msg)
    , unchecked : Maybe (Element msg)
    , icon : Maybe (Element msg)
    , checkedIcon : Maybe (Element msg)
    , uncheckedIcon : Maybe (Element msg)
    }


defaults : Options msg
defaults =
    { value = False
    , onChange = Nothing
    , disabled = False
    , size = Medium
    , loading = False
    , spinStrokeWidth = Nothing
    , spinStroke = Nothing
    , spinScale = Nothing
    , spinRadius = Nothing
    , round = True
    , rubberBand = True
    , railColor = Nothing
    , railColorActive = Nothing
    , railStyle = Nothing
    , checked = Nothing
    , unchecked = Nothing
    , icon = Nothing
    , checkedIcon = Nothing
    , uncheckedIcon = Nothing
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts _ =
    let
        v =
            SwitchTheme.vars theme

        hasIcon =
            opts.icon /= Nothing || opts.checkedIcon /= Nothing || opts.uncheckedIcon /= Nothing

        knobIcon =
            if opts.loading then
                Just (loadingEl opts)

            else
                let
                    stateIcon =
                        if opts.value then
                            case opts.checkedIcon of
                                Just i ->
                                    Just i

                                Nothing ->
                                    opts.icon

                        else
                            case opts.uncheckedIcon of
                                Just i ->
                                    Just i

                                Nothing ->
                                    opts.icon
                in
                Maybe.map (Element.el [ I.classes [ "n-switch__button-icon" ] ]) stateIcon

        checkedEl =
            Maybe.map (Element.el [ I.classes [ "n-switch__checked" ] ]) opts.checked

        uncheckedEl =
            Maybe.map (Element.el [ I.classes [ "n-switch__unchecked" ] ]) opts.unchecked

        buttonEl =
            Element.column
                [ I.classes [ "n-switch__button" ] ]
                (List.filterMap identity [ knobIcon, checkedEl, uncheckedEl ])

        placeholderEls =
            if opts.checked /= Nothing || opts.unchecked /= Nothing then
                [ Element.column
                    [ I.classes [ "n-switch__children-placeholder" ] ]
                    [ railPlaceholder opts.checked
                    , railPlaceholder opts.unchecked
                    ]
                ]

            else
                []

        railEl =
            Element.column
                ([ I.classes [ "n-switch__rail" ]
                 , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
                 ]
                    ++ railStyleAttrs opts
                )
                (placeholderEls ++ [ buttonEl ])

        classes =
            List.concat
                [ [ "n-switch" ]
                , I.classIf hasIcon "n-switch--icon"
                , I.classIf opts.value "n-switch--active"
                , I.classIf opts.disabled "n-switch--disabled"
                , I.classIf opts.round "n-switch--round"
                , I.classIf opts.loading "n-switch--loading"
                , I.classIf opts.rubberBand "n-switch--rubber-band"
                ]

        interactive =
            if opts.disabled || opts.loading then
                []

            else
                [ Element.htmlAttribute (HA.tabindex 0) ]
                    ++ (case opts.onChange of
                            Just onChange ->
                                [ Events.onClick (onChange (not opts.value)) ]

                            Nothing ->
                                []
                       )
    in
    Element.row
        ([ I.classes classes
         , I.cssVars (cssVars theme opts v)
         , Element.htmlAttribute (HA.attribute "role" "switch")
         , Element.htmlAttribute
            (HA.attribute "aria-checked"
                (if opts.value then
                    "true"

                 else
                    "false"
                )
            )
         ]
            ++ interactive
        )
        [ railEl ]


{-| Naive UI's hidden measuring block: it sizes the rail to the widest state
content. `__rail-placeholder > __button-placeholder` + a (hidden) copy of the
slot content.
-}
railPlaceholder : Maybe (Element msg) -> Element msg
railPlaceholder content =
    Element.row
        [ I.classes [ "n-switch__rail-placeholder" ] ]
        (Element.el [ I.classes [ "n-switch__button-placeholder" ] ] Element.none
            :: List.filterMap identity [ content ]
        )


{-| Naive UI's `railStyle ({ focused, checked })` — Elm cannot observe focus
from `view`, so the function receives `checked` only.
-}
railStyleAttrs : Options msg -> List (Element.Attribute msg)
railStyleAttrs opts =
    case opts.railStyle of
        Nothing ->
            []

        Just f ->
            List.map
                (\( k, val ) -> Element.htmlAttribute (HA.style k val))
                (f opts.value)


{-| Naive UI renders the real `NBaseLoading` here (upstream `Switch.tsx`:
`<NBaseLoading strokeWidth={20} />` — no `stroke` prop). The arc picks its
color up from the shipped stylesheet — `.n-switch .n-base-loading { color:
var(--n-loading-color) }` resolves through `stroke="currentColor"`, and the
base `n-base-loading` rules carry the `1em` sizing — so no color is baked
and no sizing is inlined. The svg is `NUI.Internal.Loading.spinner` via
elm/svg, a true SVG-namespaced element (the old data-URI background
workaround predates both this stylesheet extraction and elm/svg's arrival:
`Html.node "svg"` lands in the HTML namespace, which no browser renders).
The four `spin*` options port upstream's `spinProps` spread over the
`<NBaseLoading strokeWidth={20}/>` (Switch.tsx:394): a caller-set field wins
per-field over the sw-20 baseline; `Nothing` keeps the baseline value.
-}
loadingEl : Options msg -> Element msg
loadingEl opts =
    Element.el
        [ I.classes [ "n-base-loading" ]
        , Element.htmlAttribute (HA.attribute "role" "img")
        , Element.htmlAttribute (HA.attribute "aria-label" "loading")
        ]
        (Element.el
            [ I.classes [ "n-base-loading__transition-wrapper" ] ]
            (Element.el
                [ I.classes [ "n-base-loading__container" ] ]
                (Element.html
                    (Loading.spinner
                        { strokeWidth =
                            Maybe.withDefault 20 (Maybe.map toFloat opts.spinStrokeWidth)
                        , radius =
                            Maybe.withDefault 100 (Maybe.map toFloat opts.spinRadius)
                        , scale = Maybe.withDefault 1 opts.spinScale
                        , stroke = opts.spinStroke
                        }
                    )
                )
            )
        )


{-| Port of `Switch.tsx`'s `cssVarsRef` (the `CSS.supports('width', 'max(1px)')`
branch — Naive UI itself assumes it for SSR).
-}
cssVars : Theme -> Options msg -> SwitchTheme.Vars -> List ( String, String )
cssVars theme opts v =
    let
        common =
            theme.common

        size =
            opts.size

        buttonHeight =
            buttonHeightOf size v

        buttonWidth =
            buttonWidthOf size v

        railHeight =
            railHeightOf size v

        railWidth =
            railWidthOf size v

        offset =
            "calc((" ++ railHeight ++ " - " ++ buttonHeight ++ ") / 2)"

        height =
            "max(" ++ railHeight ++ ", " ++ buttonHeight ++ ")"

        width =
            "max(" ++ railWidth ++ ", calc(" ++ railWidth ++ " + " ++ buttonHeight ++ " - " ++ railHeight ++ "))"
    in
    [ ( "--n-bezier", common.cubicBezierEaseInOut )
    , ( "--n-button-border-radius", buttonBorderRadiusOf size v )
    , ( "--n-button-box-shadow", v.buttonBoxShadow )
    , ( "--n-button-color", v.buttonColor )
    , ( "--n-button-width", buttonWidth )
    , ( "--n-button-width-pressed", buttonWidthPressedOf size v )
    , ( "--n-button-height", buttonHeight )
    , ( "--n-height", height )
    , ( "--n-offset", offset )
    , ( "--n-opacity-disabled", v.opacityDisabled )
    , ( "--n-rail-border-radius", railBorderRadiusOf size v )
    , ( "--n-rail-color", Maybe.withDefault v.railColor opts.railColor )
    , ( "--n-rail-color-active", Maybe.withDefault v.railColorActive opts.railColorActive )
    , ( "--n-rail-height", railHeight )
    , ( "--n-rail-width", railWidth )
    , ( "--n-width", width )
    , ( "--n-box-shadow-focus", v.boxShadowFocus )
    , ( "--n-loading-color", v.loadingColor )
    , ( "--n-text-color", v.textColor )
    , ( "--n-icon-color", v.iconColor )
    ]


{-| Switch has no `tiny` size in Naive UI; clamp it to `small`.
-}
buttonHeightOf : Size -> SwitchTheme.Vars -> String
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


buttonWidthOf : Size -> SwitchTheme.Vars -> String
buttonWidthOf size v =
    case size of
        Tiny ->
            v.buttonWidthSmall

        Small ->
            v.buttonWidthSmall

        Medium ->
            v.buttonWidthMedium

        Large ->
            v.buttonWidthLarge


buttonWidthPressedOf : Size -> SwitchTheme.Vars -> String
buttonWidthPressedOf size v =
    case size of
        Tiny ->
            v.buttonWidthPressedSmall

        Small ->
            v.buttonWidthPressedSmall

        Medium ->
            v.buttonWidthPressedMedium

        Large ->
            v.buttonWidthPressedLarge


railHeightOf : Size -> SwitchTheme.Vars -> String
railHeightOf size v =
    case size of
        Tiny ->
            v.railHeightSmall

        Small ->
            v.railHeightSmall

        Medium ->
            v.railHeightMedium

        Large ->
            v.railHeightLarge


railWidthOf : Size -> SwitchTheme.Vars -> String
railWidthOf size v =
    case size of
        Tiny ->
            v.railWidthSmall

        Small ->
            v.railWidthSmall

        Medium ->
            v.railWidthMedium

        Large ->
            v.railWidthLarge


railBorderRadiusOf : Size -> SwitchTheme.Vars -> String
railBorderRadiusOf size v =
    case size of
        Tiny ->
            v.railBorderRadiusSmall

        Small ->
            v.railBorderRadiusSmall

        Medium ->
            v.railBorderRadiusMedium

        Large ->
            v.railBorderRadiusLarge


buttonBorderRadiusOf : Size -> SwitchTheme.Vars -> String
buttonBorderRadiusOf size v =
    case size of
        Tiny ->
            v.buttonBorderRadiusSmall

        Small ->
            v.buttonBorderRadiusSmall

        Medium ->
            v.buttonBorderRadiusMedium

        Large ->
            v.buttonBorderRadiusLarge
