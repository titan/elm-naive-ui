module NUI.Switch exposing (Options, defaults, view)

{-| Naive UI's `Switch`, rebuilt on elm-ui.

    NUI.Switch.view theme NUI.Switch.defaults []

    NUI.Switch.view theme
        { NUI.Switch.defaults
            | value = model.active
            , onChange = Just Toggled
        }
        []

    NUI.Switch.view theme
        { NUI.Switch.defaults
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
import NUI.Theme exposing (Theme)
import NUI.Theme.Switch as SwitchTheme
import NUI.Types exposing (Size(..))


type alias Options msg =
    { value : Bool
    , onChange : Maybe (Bool -> msg)
    , disabled : Bool
    , size : Size
    , loading : Bool
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
                Just (loadingEl v)

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


{-| Naive UI renders `NBaseLoading` (an animated SVG arc). elm/html cannot
create SVG namespaced nodes (no elm/svg dependency), so the exact spinner SVG
— same geometry and SMIL animation — is embedded as a data-URI background
with the theme's loading colour baked in (a background SVG cannot use
`var(--n-loading-color)`). Sizing (`1em`) that normally comes from the
`n-base-loading` cssr (not part of the extracted stylesheet) is inlined too.
-}
loadingEl : SwitchTheme.Vars -> Element msg
loadingEl v =
    Element.el
        ([ I.classes [ "n-base-loading" ]
         , Element.htmlAttribute (HA.attribute "role" "img")
         , Element.htmlAttribute (HA.attribute "aria-label" "loading")
         ]
            ++ List.map
                (\( k, val ) -> Element.htmlAttribute (HA.style k val))
                (loadingStyles v.loadingColor)
        )
        Element.none


loadingStyles : String -> List ( String, String )
loadingStyles color =
    [ ( "width", "1em" )
    , ( "height", "1em" )
    , ( "line-height", "0" )
    , ( "background-image", "url(\"data:image/svg+xml," ++ encodeSvg (spinnerSvg color) ++ "\")" )
    , ( "background-repeat", "no-repeat" )
    , ( "background-position", "center" )
    , ( "background-size", "100% 100%" )
    ]


{-| `NBaseLoading` with the switch's `strokeWidth = 20` (radius 100, scale 1).
-}
spinnerSvg : String -> String
spinnerSvg color =
    String.concat
        [ "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 200 200\">"
        , "<g>"
        , "<animateTransform attributeName=\"transform\" type=\"rotate\" values=\"0 100 100;270 100 100\" begin=\"0s\" dur=\"1.6s\" fill=\"freeze\" repeatCount=\"indefinite\"/>"
        , "<circle cx=\"100\" cy=\"100\" r=\"90\" fill=\"none\" stroke=\""
        , color
        , "\" stroke-width=\"20\" stroke-linecap=\"round\" stroke-dasharray=\"567\" stroke-dashoffset=\"1848\">"
        , "<animateTransform attributeName=\"transform\" type=\"rotate\" values=\"0 100 100;135 100 100;450 100 100\" begin=\"0s\" dur=\"1.6s\" fill=\"freeze\" repeatCount=\"indefinite\"/>"
        , "<animate attributeName=\"stroke-dashoffset\" values=\"567;142;567\" begin=\"0s\" dur=\"1.6s\" fill=\"freeze\" repeatCount=\"indefinite\"/>"
        , "</circle>"
        , "</g>"
        , "</svg>"
        ]


encodeSvg : String -> String
encodeSvg svg =
    svg
        |> String.replace "%" "%25"
        |> String.replace "<" "%3C"
        |> String.replace ">" "%3E"
        |> String.replace "\"" "%22"
        |> String.replace "#" "%23"


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
