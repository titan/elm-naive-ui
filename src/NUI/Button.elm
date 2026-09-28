module NUI.Button exposing
    ( IconPlacement(..)
    , Options
    , Variant(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Button`, rebuilt on elm-ui.

    import NUI.Button exposing (defaults)

    NUI.Button.view theme NUI.Button.defaults
        [ Element.text "Default" ]

    NUI.Button.view theme
        { defaults | kind = NUI.Button.Primary }
        [ Element.text "Primary" ]

    -- while loading, the icon slot renders Naive UI's NBaseLoading; the four
    -- `spin*` fields port upstream's `spinProps` spread over its
    -- strokeWidth-20 baseline (each `Just` wins per-field, `Nothing` keeps it)
    NUI.Button.view theme
        { defaults
            | loading = True
            , spinStrokeWidth = Just 6
            , spinStroke = Just "#ff0000"
        }
        [ Element.text "Loading" ]

The visual result is Naive UI's own: the element carries the `.n-button` BEM classes
and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS.

-}

import Element exposing (Element)
import Element.Events as Events
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Theme exposing (Theme)
import NUI.Theme.Button as ButtonTheme
import NUI.Theme.Color as Color
import NUI.Types as T exposing (Kind(..), Size(..))


type Variant
    = Filled
    | Secondary
    | Tertiary
    | Quaternary
    | Text


type IconPlacement
    = IconLeft
    | IconRight


type alias Options msg =
    { kind : Kind
    , size : Size
    , variant : Variant
    , ghost : Bool
    , dashed : Bool
    , round : Bool
    , circle : Bool
    , block : Bool
    , disabled : Bool
    , loading : Bool
    , spinStrokeWidth : Maybe Int
    , spinStroke : Maybe String
    , spinScale : Maybe Float
    , spinRadius : Maybe Int
    , strong : Bool
    , bordered : Bool
    , color : Maybe String
    , textColor : Maybe String
    , icon : Maybe (Element msg)
    , iconPlacement : IconPlacement
    , onPress : Maybe msg
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { kind = Default
    , size = Medium
    , variant = Filled
    , ghost = False
    , dashed = False
    , round = False
    , circle = False
    , block = False
    , disabled = False
    , loading = False
    , spinStrokeWidth = Nothing
    , spinStroke = Nothing
    , spinScale = Nothing
    , spinRadius = Nothing
    , strong = False
    , bordered = True
    , color = Nothing
    , textColor = Nothing
    , icon = Nothing
    , iconPlacement = IconLeft
    , onPress = Nothing
    , rtl = False
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        v =
            ButtonTheme.vars theme

        isText =
            opts.variant == Text

        showBorder =
            not (List.member opts.variant [ Quaternary, Tertiary, Secondary, Text ])
                && (opts.color == Nothing || opts.ghost || opts.dashed)
                && opts.bordered

        content =
            Element.el [ I.classes [ "n-button__content" ] ] (Element.column [] children)

        iconEl =
            if opts.loading then
                Just (Element.el [ I.classes [ "n-button__icon" ] ] (loadingEl opts))

            else
                case opts.icon of
                    Just ic ->
                        Just
                            (Element.el [ I.classes [ "n-button__icon" ] ]
                                (Element.el
                                    [ I.classes [ "n-icon-slot" ]
                                    , Element.htmlAttribute (HA.attribute "role" "none")
                                    ]
                                    ic
                                )
                            )

                    Nothing ->
                        Nothing

        body =
            case opts.iconPlacement of
                IconRight ->
                    content :: List.filterMap identity [ iconEl ]

                IconLeft ->
                    List.filterMap identity [ iconEl ] ++ [ content ]

        borderEls =
            if showBorder then
                [ Element.el
                    [ I.classes [ "n-button__border" ]
                    , I.cssVars (customColorVars opts.color)
                    ]
                    Element.none
                , Element.el
                    [ I.classes [ "n-button__state-border" ]
                    , I.cssVars (customColorVars opts.color)
                    ]
                    Element.none
                ]

            else
                []

        classes =
            List.concat
                [ [ "n-button"
                  , "n-button--" ++ T.kindClass opts.kind ++ "-type"
                  , "n-button--" ++ T.sizeClass opts.size ++ "-type"
                  ]
                , I.classIf opts.rtl "n-button--rtl"
                , I.classIf opts.disabled "n-button--disabled"
                , I.classIf opts.block "n-button--block"
                , I.classIf (opts.dashed && not isText) "n-button--dashed"
                , I.classIf (opts.color /= Nothing) "n-button--color"
                , I.classIf (opts.variant == Secondary) "n-button--secondary"
                , I.classIf opts.loading "n-button--loading"
                , I.classIf opts.ghost "n-button--ghost"
                ]

        interactive =
            if opts.disabled || opts.loading then
                [ Element.htmlAttribute (HA.attribute "aria-disabled" "true") ]

            else
                [ Element.htmlAttribute (HA.attribute "role" "button")
                , Element.htmlAttribute (HA.tabindex 0)
                ]
                    ++ (case opts.onPress of
                            Just msg ->
                                [ Events.onClick msg ]

                            Nothing ->
                                []
                       )
    in
    Element.row
        (I.classes classes
            :: I.cssVars (cssVars theme opts v)
            :: interactive
            ++ opts.attributes
        )
        (body ++ borderEls)


{-| The raw `--n-*` custom properties a button with these options attaches (before
`NUI.Internal.renderVars` drops `initial`/empty values). Exposed so the `--n-*` output
can be asserted directly; `view` uses exactly this.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    cssVars theme opts (ButtonTheme.vars theme)


cssVars : Theme -> Options msg -> ButtonTheme.Vars -> List ( String, String )
cssVars theme opts v =
    let
        common =
            theme.common

        isText =
            opts.variant == Text

        cs =
            colorSet opts.kind v

        height =
            heightOf opts.size v

        fontSize =
            fontSizeOf opts.size v

        padding =
            paddingOf opts.size v

        paddingRound =
            paddingRoundOf opts.size v

        iconSize =
            iconSizeOf opts.size v

        borderRadius =
            borderRadiusOf opts.size v

        iconMargin =
            iconMarginOf opts.size v

        custom =
            opts.color

        customText =
            opts.textColor

        fontVars =
            [ ( "--n-font-weight"
              , if opts.strong then
                    v.fontWeightStrong

                else
                    v.fontWeight
              )
            ]

        colorVars =
            if opts.variant == Text then
                let
                    base =
                        Maybe.withDefault cs.textColorText custom

                    hover =
                        Maybe.withDefault cs.textColorTextHover custom
                in
                [ ( "--n-color", "#0000" )
                , ( "--n-text-color", base )
                , ( "--n-text-color-hover", hover )
                , ( "--n-text-color-pressed", Maybe.withDefault cs.textColorTextPressed custom )
                , ( "--n-text-color-focus", hover )
                , ( "--n-text-color-disabled", Maybe.withDefault cs.textColorTextDisabled custom )
                ]

            else if opts.ghost || opts.dashed then
                let
                    base =
                        Maybe.withDefault cs.textColorGhost custom
                in
                [ ( "--n-color", "#0000" )
                , ( "--n-ripple-color", Maybe.withDefault cs.rippleColor custom )
                , ( "--n-text-color", base )
                , ( "--n-text-color-hover", Maybe.withDefault cs.textColorGhostHover custom )
                , ( "--n-text-color-pressed", Maybe.withDefault cs.textColorGhostPressed custom )
                , ( "--n-text-color-focus", Maybe.withDefault cs.textColorGhostHover custom )
                , ( "--n-text-color-disabled", Maybe.withDefault cs.textColorGhostDisabled custom )
                ]

            else if opts.variant == Secondary then
                let
                    isColored =
                        opts.kind /= Default

                    typeText =
                        case opts.kind of
                            Default ->
                                v.textColor

                            _ ->
                                cs.color

                    merged =
                        Maybe.withDefault typeText custom

                    colored alpha =
                        Color.changeColor merged alpha
                in
                [ ( "--n-color"
                  , if isColored then
                        colored (String.toFloat v.colorOpacitySecondary |> Maybe.withDefault 0.16)

                    else
                        v.colorSecondary
                  )
                , ( "--n-color-hover"
                  , if isColored then
                        colored (String.toFloat v.colorOpacitySecondaryHover |> Maybe.withDefault 0.22)

                    else
                        v.colorSecondaryHover
                  )
                , ( "--n-color-pressed"
                  , if isColored then
                        colored (String.toFloat v.colorOpacitySecondaryPressed |> Maybe.withDefault 0.28)

                    else
                        v.colorSecondaryPressed
                  )
                , ( "--n-color-focus", v.colorSecondaryHover )
                , ( "--n-color-disabled", v.colorSecondary )
                , ( "--n-ripple-color", "#0000" )
                , ( "--n-text-color", merged )
                , ( "--n-text-color-hover", merged )
                , ( "--n-text-color-pressed", merged )
                , ( "--n-text-color-focus", merged )
                , ( "--n-text-color-disabled", merged )
                ]

            else if opts.variant == Tertiary || opts.variant == Quaternary then
                let
                    typeColor =
                        case opts.kind of
                            Default ->
                                v.textColor

                            _ ->
                                cs.color

                    merged =
                        Maybe.withDefault typeColor custom

                    colorVars_ =
                        if opts.variant == Tertiary then
                            [ ( "--n-color", v.colorTertiary )
                            , ( "--n-color-hover", v.colorTertiaryHover )
                            , ( "--n-color-pressed", v.colorTertiaryPressed )
                            , ( "--n-color-focus", v.colorSecondaryHover )
                            , ( "--n-color-disabled", v.colorTertiary )
                            ]

                        else
                            [ ( "--n-color", v.colorQuaternary )
                            , ( "--n-color-hover", v.colorQuaternaryHover )
                            , ( "--n-color-pressed", v.colorQuaternaryPressed )
                            , ( "--n-color-focus", v.colorQuaternaryHover )
                            , ( "--n-color-disabled", v.colorQuaternary )
                            ]
                in
                colorVars_
                    ++ [ ( "--n-ripple-color", "#0000" )
                       , ( "--n-text-color", merged )
                       , ( "--n-text-color-hover", merged )
                       , ( "--n-text-color-pressed", merged )
                       , ( "--n-text-color-focus", merged )
                       , ( "--n-text-color-disabled", merged )
                       ]

            else
                [ ( "--n-color", Maybe.withDefault cs.color custom )
                , ( "--n-color-hover"
                  , Maybe.withDefault cs.colorHover (Maybe.map Color.createHoverColor custom)
                  )
                , ( "--n-color-pressed"
                  , Maybe.withDefault cs.colorPressed (Maybe.map Color.createPressedColor custom)
                  )
                , ( "--n-color-focus"
                  , Maybe.withDefault cs.colorFocus (Maybe.map Color.createHoverColor custom)
                  )
                , ( "--n-color-disabled", Maybe.withDefault cs.colorDisabled custom )
                , ( "--n-ripple-color", Maybe.withDefault cs.rippleColor custom )
                , ( "--n-text-color"
                  , customText
                        |> Maybe.withDefault
                            (if custom /= Nothing then
                                v.textColorPrimary

                             else
                                cs.textColor
                            )
                  )
                , ( "--n-text-color-hover"
                  , customText
                        |> Maybe.withDefault
                            (if custom /= Nothing then
                                v.textColorHoverPrimary

                             else
                                cs.textColorHover
                            )
                  )
                , ( "--n-text-color-pressed"
                  , customText
                        |> Maybe.withDefault
                            (if custom /= Nothing then
                                v.textColorPressedPrimary

                             else
                                cs.textColorPressed
                            )
                  )
                , ( "--n-text-color-focus"
                  , customText
                        |> Maybe.withDefault
                            (if custom /= Nothing then
                                v.textColorFocusPrimary

                             else
                                cs.textColorFocus
                            )
                  )
                , ( "--n-text-color-disabled"
                  , customText
                        |> Maybe.withDefault
                            (if custom /= Nothing then
                                v.textColorDisabledPrimary

                             else
                                cs.textColorDisabled
                            )
                  )
                ]

        borderVars =
            if opts.variant == Text then
                [ ( "--n-border", "none" )
                , ( "--n-border-hover", "none" )
                , ( "--n-border-pressed", "none" )
                , ( "--n-border-focus", "none" )
                , ( "--n-border-disabled", "none" )
                ]

            else
                [ ( "--n-border", cs.border )
                , ( "--n-border-hover", cs.borderHover )
                , ( "--n-border-pressed", cs.borderPressed )
                , ( "--n-border-focus", cs.borderFocus )
                , ( "--n-border-disabled", cs.borderDisabled )
                ]

        sizeVars =
            [ ( "--n-width"
              , if opts.circle && not isText then
                    height

                else
                    "initial"
              )
            , ( "--n-height"
              , if isText then
                    "initial"

                else
                    height
              )
            , ( "--n-font-size", fontSize )
            , ( "--n-padding"
              , if opts.circle then
                    "initial"

                else if isText then
                    "initial"

                else if opts.round then
                    paddingRound

                else
                    padding
              )
            , ( "--n-icon-size", iconSize )
            , ( "--n-icon-margin", iconMargin )
            , ( "--n-border-radius"
              , if isText then
                    "initial"

                else if opts.circle || opts.round then
                    height

                else
                    borderRadius
              )
            ]
    in
    [ ( "--n-bezier", common.cubicBezierEaseInOut )
    , ( "--n-bezier-ease-out", common.cubicBezierEaseOut )
    , ( "--n-ripple-duration", v.rippleDuration )
    , ( "--n-opacity-disabled", v.opacityDisabled )
    , ( "--n-wave-opacity", v.waveOpacity )
    ]
        ++ fontVars
        ++ colorVars
        ++ borderVars
        ++ sizeVars


customColorVars : Maybe String -> List ( String, String )
customColorVars maybeColor =
    case maybeColor of
        Nothing ->
            []

        Just color ->
            let
                hover =
                    Color.createHoverColor color
            in
            [ ( "--n-border-color", color )
            , ( "--n-border-color-hover", hover )
            , ( "--n-border-color-pressed", Color.createPressedColor color )
            , ( "--n-border-color-focus", hover )
            , ( "--n-border-color-disabled", color )
            ]


{-| Naive UI's `createKey('foo', type)` — the `default` type uses the bare name.
-}
type alias ColorSet =
    { color : String
    , colorHover : String
    , colorPressed : String
    , colorFocus : String
    , colorDisabled : String
    , rippleColor : String
    , textColor : String
    , textColorHover : String
    , textColorPressed : String
    , textColorFocus : String
    , textColorDisabled : String
    , textColorText : String
    , textColorTextHover : String
    , textColorTextPressed : String
    , textColorTextDisabled : String
    , textColorGhost : String
    , textColorGhostHover : String
    , textColorGhostPressed : String
    , textColorGhostDisabled : String
    , border : String
    , borderHover : String
    , borderPressed : String
    , borderFocus : String
    , borderDisabled : String
    }


colorSet : Kind -> ButtonTheme.Vars -> ColorSet
colorSet kind v =
    case kind of
        Default ->
            { color = v.color
            , colorHover = v.colorHover
            , colorPressed = v.colorPressed
            , colorFocus = v.colorFocus
            , colorDisabled = v.colorDisabled
            , rippleColor = v.rippleColor
            , textColor = v.textColor
            , textColorHover = v.textColorHover
            , textColorPressed = v.textColorPressed
            , textColorFocus = v.textColorFocus
            , textColorDisabled = v.textColorDisabled
            , textColorText = v.textColorText
            , textColorTextHover = v.textColorTextHover
            , textColorTextPressed = v.textColorTextPressed
            , textColorTextDisabled = v.textColorTextDisabled
            , textColorGhost = v.textColorGhost
            , textColorGhostHover = v.textColorGhostHover
            , textColorGhostPressed = v.textColorGhostPressed
            , textColorGhostDisabled = v.textColorGhostDisabled
            , border = v.border
            , borderHover = v.borderHover
            , borderPressed = v.borderPressed
            , borderFocus = v.borderFocus
            , borderDisabled = v.borderDisabled
            }

        Primary ->
            { color = v.colorPrimary
            , colorHover = v.colorHoverPrimary
            , colorPressed = v.colorPressedPrimary
            , colorFocus = v.colorFocusPrimary
            , colorDisabled = v.colorDisabledPrimary
            , rippleColor = v.rippleColorPrimary
            , textColor = v.textColorPrimary
            , textColorHover = v.textColorHoverPrimary
            , textColorPressed = v.textColorPressedPrimary
            , textColorFocus = v.textColorFocusPrimary
            , textColorDisabled = v.textColorDisabledPrimary
            , textColorText = v.textColorTextPrimary
            , textColorTextHover = v.textColorTextHoverPrimary
            , textColorTextPressed = v.textColorTextPressedPrimary
            , textColorTextDisabled = v.textColorTextDisabledPrimary
            , textColorGhost = v.textColorGhostPrimary
            , textColorGhostHover = v.textColorGhostHoverPrimary
            , textColorGhostPressed = v.textColorGhostPressedPrimary
            , textColorGhostDisabled = v.textColorGhostDisabledPrimary
            , border = v.borderPrimary
            , borderHover = v.borderHoverPrimary
            , borderPressed = v.borderPressedPrimary
            , borderFocus = v.borderFocusPrimary
            , borderDisabled = v.borderDisabledPrimary
            }

        Info ->
            { color = v.colorInfo
            , colorHover = v.colorHoverInfo
            , colorPressed = v.colorPressedInfo
            , colorFocus = v.colorFocusInfo
            , colorDisabled = v.colorDisabledInfo
            , rippleColor = v.rippleColorInfo
            , textColor = v.textColorInfo
            , textColorHover = v.textColorHoverInfo
            , textColorPressed = v.textColorPressedInfo
            , textColorFocus = v.textColorFocusInfo
            , textColorDisabled = v.textColorDisabledInfo
            , textColorText = v.textColorTextInfo
            , textColorTextHover = v.textColorTextHoverInfo
            , textColorTextPressed = v.textColorTextPressedInfo
            , textColorTextDisabled = v.textColorTextDisabledInfo
            , textColorGhost = v.textColorGhostInfo
            , textColorGhostHover = v.textColorGhostHoverInfo
            , textColorGhostPressed = v.textColorGhostPressedInfo
            , textColorGhostDisabled = v.textColorGhostDisabledInfo
            , border = v.borderInfo
            , borderHover = v.borderHoverInfo
            , borderPressed = v.borderPressedInfo
            , borderFocus = v.borderFocusInfo
            , borderDisabled = v.borderDisabledInfo
            }

        Success ->
            { color = v.colorSuccess
            , colorHover = v.colorHoverSuccess
            , colorPressed = v.colorPressedSuccess
            , colorFocus = v.colorFocusSuccess
            , colorDisabled = v.colorDisabledSuccess
            , rippleColor = v.rippleColorSuccess
            , textColor = v.textColorSuccess
            , textColorHover = v.textColorHoverSuccess
            , textColorPressed = v.textColorPressedSuccess
            , textColorFocus = v.textColorFocusSuccess
            , textColorDisabled = v.textColorDisabledSuccess
            , textColorText = v.textColorTextSuccess
            , textColorTextHover = v.textColorTextHoverSuccess
            , textColorTextPressed = v.textColorTextPressedSuccess
            , textColorTextDisabled = v.textColorTextDisabledSuccess
            , textColorGhost = v.textColorGhostSuccess
            , textColorGhostHover = v.textColorGhostHoverSuccess
            , textColorGhostPressed = v.textColorGhostPressedSuccess
            , textColorGhostDisabled = v.textColorGhostDisabledSuccess
            , border = v.borderSuccess
            , borderHover = v.borderHoverSuccess
            , borderPressed = v.borderPressedSuccess
            , borderFocus = v.borderFocusSuccess
            , borderDisabled = v.borderDisabledSuccess
            }

        Warning ->
            { color = v.colorWarning
            , colorHover = v.colorHoverWarning
            , colorPressed = v.colorPressedWarning
            , colorFocus = v.colorFocusWarning
            , colorDisabled = v.colorDisabledWarning
            , rippleColor = v.rippleColorWarning
            , textColor = v.textColorWarning
            , textColorHover = v.textColorHoverWarning
            , textColorPressed = v.textColorPressedWarning
            , textColorFocus = v.textColorFocusWarning
            , textColorDisabled = v.textColorDisabledWarning
            , textColorText = v.textColorTextWarning
            , textColorTextHover = v.textColorTextHoverWarning
            , textColorTextPressed = v.textColorTextPressedWarning
            , textColorTextDisabled = v.textColorTextDisabledWarning
            , textColorGhost = v.textColorGhostWarning
            , textColorGhostHover = v.textColorGhostHoverWarning
            , textColorGhostPressed = v.textColorGhostPressedWarning
            , textColorGhostDisabled = v.textColorGhostDisabledWarning
            , border = v.borderWarning
            , borderHover = v.borderHoverWarning
            , borderPressed = v.borderPressedWarning
            , borderFocus = v.borderFocusWarning
            , borderDisabled = v.borderDisabledWarning
            }

        Error ->
            { color = v.colorError
            , colorHover = v.colorHoverError
            , colorPressed = v.colorPressedError
            , colorFocus = v.colorFocusError
            , colorDisabled = v.colorDisabledError
            , rippleColor = v.rippleColorError
            , textColor = v.textColorError
            , textColorHover = v.textColorHoverError
            , textColorPressed = v.textColorPressedError
            , textColorFocus = v.textColorFocusError
            , textColorDisabled = v.textColorDisabledError
            , textColorText = v.textColorTextError
            , textColorTextHover = v.textColorTextHoverError
            , textColorTextPressed = v.textColorTextPressedError
            , textColorTextDisabled = v.textColorTextDisabledError
            , textColorGhost = v.textColorGhostError
            , textColorGhostHover = v.textColorGhostHoverError
            , textColorGhostPressed = v.textColorGhostPressedError
            , textColorGhostDisabled = v.textColorGhostDisabledError
            , border = v.borderError
            , borderHover = v.borderHoverError
            , borderPressed = v.borderPressedError
            , borderFocus = v.borderFocusError
            , borderDisabled = v.borderDisabledError
            }


heightOf : Size -> ButtonTheme.Vars -> String
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


fontSizeOf : Size -> ButtonTheme.Vars -> String
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


paddingOf : Size -> ButtonTheme.Vars -> String
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


paddingRoundOf : Size -> ButtonTheme.Vars -> String
paddingRoundOf size v =
    case size of
        Tiny ->
            v.paddingRoundTiny

        Small ->
            v.paddingRoundSmall

        Medium ->
            v.paddingRoundMedium

        Large ->
            v.paddingRoundLarge


iconSizeOf : Size -> ButtonTheme.Vars -> String
iconSizeOf size v =
    case size of
        Tiny ->
            v.iconSizeTiny

        Small ->
            v.iconSizeSmall

        Medium ->
            v.iconSizeMedium

        Large ->
            v.iconSizeLarge


iconMarginOf : Size -> ButtonTheme.Vars -> String
iconMarginOf size v =
    case size of
        Tiny ->
            v.iconMarginTiny

        Small ->
            v.iconMarginSmall

        Medium ->
            v.iconMarginMedium

        Large ->
            v.iconMarginLarge


borderRadiusOf : Size -> ButtonTheme.Vars -> String
borderRadiusOf size v =
    case size of
        Tiny ->
            v.borderRadiusTiny

        Small ->
            v.borderRadiusSmall

        Medium ->
            v.borderRadiusMedium

        Large ->
            v.borderRadiusLarge


{-| The loading spinner — upstream's `NBaseLoading` (`strokeWidth: 20`, the
radius/scale defaults) carrying the `n-icon-slot` class, exactly as
`Button.tsx` renders it under `span.n-button__icon` while loading. The svg is
`NUI.Internal.Loading.spinner`, the library's single source (SMIL children
kept — browsers animate the dash arc; jsdom just carries the nodes).
The four `spin*` options port upstream's `spinProps` spread over that
`<NBaseLoading strokeWidth={20}/>` (Button.tsx:648): a caller-set field wins
per-field over the sw-20/r-100/scale-1 baseline; `Nothing` keeps the baseline
value.
-}
loadingEl : Options msg -> Element msg
loadingEl opts =
    Element.el
        [ I.classes [ "n-base-loading", "n-icon-slot" ]
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
