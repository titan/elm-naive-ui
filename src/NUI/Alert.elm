module NUI.Alert exposing (Options, defaults, view)

{-| Naive UI's `Alert`, rebuilt on elm-ui.

    NUI.Alert.view theme
        NUI.Alert.defaults
        [ Element.text "Just as in the original component." ]

    NUI.Alert.view theme
        { NUI.Alert.defaults
            | kind = T.Success
            , title = Just "Success"
            , closable = True
            , onClose = Just Dismiss
        }
        [ Element.text "Just as in the original component." ]

The visual result is Naive UI's own: the element carries the `.n-alert` BEM classes
and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS.

Naive UI's alert has no `primary` type, so `T.Primary` falls back to the un-suffixed
(default) theme variables.

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Alert as AlertTheme
import NUI.Types as T exposing (Kind(..))


type alias Options msg =
    { kind : Kind
    , title : Maybe String
    , bordered : Bool
    , closable : Bool
    , showIcon : Bool
    , icon : Maybe (Element msg)
    , onClose : Maybe msg
    }


defaults : Options msg
defaults =
    { kind = Default
    , title = Nothing
    , bordered = True
    , closable = False
    , showIcon = True
    , icon = Nothing
    , onClose = Nothing
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        v =
            AlertTheme.vars theme

        closeEl =
            if opts.closable then
                [ Element.el
                    ([ I.classes [ "n-base-close", "n-alert__close" ]
                     , Element.htmlAttribute (HA.attribute "role" "button")
                     , Element.htmlAttribute (HA.tabindex 0)
                     , Element.htmlAttribute (HA.attribute "aria-label" "close")
                     ]
                        ++ (case opts.onClose of
                                Just msg ->
                                    [ Events.onClick msg ]

                                Nothing ->
                                    []
                           )
                    )
                    (baseIcon (Just closeIcon))
                ]

            else
                []

        borderEl =
            if opts.bordered then
                [ Element.el [ I.classes [ "n-alert__border" ] ] Element.none ]

            else
                []

        iconEl =
            if opts.showIcon then
                [ Element.el
                    [ I.classes [ "n-alert__icon" ]
                    , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
                    ]
                    (case opts.icon of
                        Just custom ->
                            custom

                        Nothing ->
                            baseIcon (kindIcon opts.kind)
                    )
                ]

            else
                []

        titleEl =
            case opts.title of
                Just t ->
                    [ Element.paragraph
                        [ I.classes [ "n-alert-body__title" ]
                        , Element.spacing 0
                        ]
                        [ Element.text t ]
                    ]

                Nothing ->
                    []

        contentEl =
            if List.isEmpty children then
                []

            else
                [ Element.paragraph
                    [ I.classes [ "n-alert-body__content" ]
                    , Element.spacing 0
                    ]
                    children
                ]

        bodyEl =
            Element.column
                [ I.classes [ "n-alert-body", "n-alert-body--bordered" ]
                , Element.width Element.fill
                ]
                (titleEl ++ contentEl)

        classes =
            List.concat
                [ [ "n-alert" ]
                , I.classIf opts.closable "n-alert--closable"
                , I.classIf opts.showIcon "n-alert--show-icon"
                , I.classIf (opts.title == Nothing && opts.closable) "n-alert--right-adjust"
                ]
    in
    Element.column
        [ I.classes classes
        , I.cssVars (cssVars theme v opts.kind)
        , Element.htmlAttribute (HA.attribute "role" "alert")
        ]
        (closeEl ++ borderEl ++ iconEl ++ [ bodyEl ])


cssVars : Theme -> AlertTheme.Vars -> Kind -> List ( String, String )
cssVars theme v kind =
    let
        k =
            kindVars kind v

        ( iconMarginLeft, iconMarginRight ) =
            marginSides v.iconMargin
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-color", k.color )
    , ( "--n-close-icon-size", v.closeIconSize )
    , ( "--n-close-border-radius", v.closeBorderRadius )
    , ( "--n-close-color-hover", k.closeColorHover )
    , ( "--n-close-color-pressed", k.closeColorPressed )
    , ( "--n-close-icon-color", k.closeIconColor )
    , ( "--n-close-icon-color-hover", k.closeIconColorHover )
    , ( "--n-close-icon-color-pressed", k.closeIconColorPressed )
    , ( "--n-icon-color", k.iconColor )
    , ( "--n-border", k.border )
    , ( "--n-title-text-color", k.titleTextColor )
    , ( "--n-content-text-color", k.contentTextColor )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-icon-size", v.iconSize )
    , ( "--n-icon-margin", v.iconMargin )
    , ( "--n-icon-margin-rtl", v.iconMarginRtl )
    , ( "--n-close-size", v.closeSize )
    , ( "--n-close-margin", v.closeMargin )
    , ( "--n-close-margin-rtl", v.closeMarginRtl )
    , ( "--n-padding", v.padding )
    , ( "--n-icon-margin-left", iconMarginLeft )
    , ( "--n-icon-margin-right", iconMarginRight )
    ]


{-| Naive UI's `createKey('foo', type)` — the `default` type uses the bare name.
Alert has no `primary` type, so `Primary` shares the default set.
-}
type alias KindVars =
    { color : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , iconColor : String
    , border : String
    , titleTextColor : String
    , contentTextColor : String
    }


kindVars : Kind -> AlertTheme.Vars -> KindVars
kindVars kind v =
    case kind of
        Info ->
            { color = v.colorInfo
            , closeColorHover = v.closeColorHoverInfo
            , closeColorPressed = v.closeColorPressedInfo
            , closeIconColor = v.closeIconColorInfo
            , closeIconColorHover = v.closeIconColorHoverInfo
            , closeIconColorPressed = v.closeIconColorPressedInfo
            , iconColor = v.iconColorInfo
            , border = v.borderInfo
            , titleTextColor = v.titleTextColorInfo
            , contentTextColor = v.contentTextColorInfo
            }

        Success ->
            { color = v.colorSuccess
            , closeColorHover = v.closeColorHoverSuccess
            , closeColorPressed = v.closeColorPressedSuccess
            , closeIconColor = v.closeIconColorSuccess
            , closeIconColorHover = v.closeIconColorHoverSuccess
            , closeIconColorPressed = v.closeIconColorPressedSuccess
            , iconColor = v.iconColorSuccess
            , border = v.borderSuccess
            , titleTextColor = v.titleTextColorSuccess
            , contentTextColor = v.contentTextColorSuccess
            }

        Warning ->
            { color = v.colorWarning
            , closeColorHover = v.closeColorHoverWarning
            , closeColorPressed = v.closeColorPressedWarning
            , closeIconColor = v.closeIconColorWarning
            , closeIconColorHover = v.closeIconColorHoverWarning
            , closeIconColorPressed = v.closeIconColorPressedWarning
            , iconColor = v.iconColorWarning
            , border = v.borderWarning
            , titleTextColor = v.titleTextColorWarning
            , contentTextColor = v.contentTextColorWarning
            }

        Error ->
            { color = v.colorError
            , closeColorHover = v.closeColorHoverError
            , closeColorPressed = v.closeColorPressedError
            , closeIconColor = v.closeIconColorError
            , closeIconColorHover = v.closeIconColorHoverError
            , closeIconColorPressed = v.closeIconColorPressedError
            , iconColor = v.iconColorError
            , border = v.borderError
            , titleTextColor = v.titleTextColorError
            , contentTextColor = v.contentTextColorError
            }

        Default ->
            baseKindVars v

        Primary ->
            baseKindVars v


baseKindVars : AlertTheme.Vars -> KindVars
baseKindVars v =
    { color = v.color
    , closeColorHover = v.closeColorHover
    , closeColorPressed = v.closeColorPressed
    , closeIconColor = v.closeIconColor
    , closeIconColorHover = v.closeIconColorHover
    , closeIconColorPressed = v.closeIconColorPressed
    , iconColor = v.iconColor
    , border = v.border
    , titleTextColor = v.titleTextColor
    , contentTextColor = v.contentTextColor
    }


{-| seemly's `getMargin`, reduced to the left/right pair the `--n-icon-margin-*`
vars need. Handles the 1–4 value CSS shorthand forms like the original.
-}
marginSides : String -> ( String, String )
marginSides margin =
    case String.words margin of
        [ all ] ->
            ( all, all )

        [ _, right ] ->
            ( right, right )

        [ _, right, _ ] ->
            ( right, right )

        [ _, right, _, left ] ->
            ( left, right )

        _ ->
            ( "", "" )



-- ICONS (Naive UI renders these through NBaseIcon; an `<i class="n-base-icon">`)


baseIcon : Maybe (Html.Html msg) -> Element msg
baseIcon maybeSvg =
    Element.html
        (Html.i
            [ HA.class "n-base-icon" ]
            (Maybe.map List.singleton maybeSvg |> Maybe.withDefault [])
        )


kindIcon : Kind -> Maybe (Html.Html msg)
kindIcon kind =
    case kind of
        Info ->
            Just (svgIcon "0 0 28 28" infoPath)

        Success ->
            Just (svgIcon "0 0 48 48" successPath)

        Warning ->
            Just (svgIcon "0 0 24 24" warningPath)

        Error ->
            Just (svgIcon "0 0 48 48" errorPath)

        Default ->
            Nothing

        Primary ->
            Nothing


closeIcon : Html.Html msg
closeIcon =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 12 12" ]
        [ Html.node "g"
            [ HA.attribute "fill" "currentColor"
            , HA.attribute "fill-rule" "nonzero"
            ]
            [ Html.node "path" [ HA.attribute "d" closePath ] [] ]
        ]


svgIcon : String -> String -> Html.Html msg
svgIcon viewBox d =
    Html.node "svg"
        [ HA.attribute "viewBox" viewBox ]
        [ Html.node "g"
            [ HA.attribute "fill-rule" "evenodd" ]
            [ Html.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Html.node "path" [ HA.attribute "d" d ] [] ]
            ]
        ]


infoPath : String
infoPath =
    "M14,2 C20.6274,2 26,7.37258 26,14 C26,20.6274 20.6274,26 14,26 C7.37258,26 2,20.6274 2,14 C2,7.37258 7.37258,2 14,2 Z M14,11 C13.4477,11 13,11.4477 13,12 L13,12 L13,20 C13,20.5523 13.4477,21 14,21 C14.5523,21 15,20.5523 15,20 L15,20 L15,12 C15,11.4477 14.5523,11 14,11 Z M14,6.75 C13.3096,6.75 12.75,7.30964 12.75,8 C12.75,8.69036 13.3096,9.25 14,9.25 C14.6904,9.25 15.25,8.69036 15.25,8 C15.25,7.30964 14.6904,6.75 14,6.75 Z"


successPath : String
successPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M32.6338835,17.6161165 C32.1782718,17.1605048 31.4584514,17.1301307 30.9676119,17.5249942 L30.8661165,17.6161165 L20.75,27.732233 L17.1338835,24.1161165 C16.6457281,23.6279612 15.8542719,23.6279612 15.3661165,24.1161165 C14.9105048,24.5717282 14.8801307,25.2915486 15.2749942,25.7823881 L15.3661165,25.8838835 L19.8661165,30.3838835 C20.3217282,30.8394952 21.0415486,30.8698693 21.5323881,30.4750058 L21.6338835,30.3838835 L32.6338835,19.3838835 C33.1220388,18.8957281 33.1220388,18.1042719 32.6338835,17.6161165 Z"


warningPath : String
warningPath =
    "M12,2 C17.523,2 22,6.478 22,12 C22,17.522 17.523,22 12,22 C6.477,22 2,17.522 2,12 C2,6.478 6.477,2 12,2 Z M12.0018002,15.0037242 C11.450254,15.0037242 11.0031376,15.4508407 11.0031376,16.0023869 C11.0031376,16.553933 11.450254,17.0010495 12.0018002,17.0010495 C12.5533463,17.0010495 13.0004628,16.553933 13.0004628,16.0023869 C13.0004628,15.4508407 12.5533463,15.0037242 12.0018002,15.0037242 Z M11.99964,7 C11.4868042,7.00018474 11.0642719,7.38637706 11.0066858,7.8837365 L11,8.00036004 L11.0018003,13.0012393 L11.00857,13.117858 C11.0665141,13.6151755 11.4893244,14.0010638 12.0021602,14.0008793 C12.5149968,14.0006946 12.9375283,13.6145023 12.9951144,13.1171428 L13.0018002,13.0005193 L13,7.99964009 L12.9932301,7.8830214 C12.9352861,7.38570354 12.5124757,6.99981552 11.99964,7 Z"


errorPath : String
errorPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M17.8838835,16.1161165 L17.7823881,16.0249942 C17.3266086,15.6583353 16.6733914,15.6583353 16.2176119,16.0249942 L16.1161165,16.1161165 L16.0249942,16.2176119 C15.6583353,16.6733914 15.6583353,17.3266086 16.0249942,17.7823881 L16.1161165,17.8838835 L22.233,24 L16.1161165,30.1161165 L16.0249942,30.2176119 C15.6583353,30.6733914 15.6583353,31.3266086 16.0249942,31.7823881 L16.1161165,31.8838835 L16.2176119,31.9750058 C16.6733914,32.3416647 17.3266086,32.3416647 17.7823881,31.9750058 L17.8838835,31.8838835 L24,25.767 L30.1161165,31.8838835 L30.2176119,31.9750058 C30.6733914,32.3416647 31.3781608,32.3416647 31.7823881,31.9750058 L31.8838835,31.8838835 L31.9750058,31.7823881 C32.3416647,31.3266086 32.3416647,30.6733914 31.9750058,30.2176119 L31.8838835,30.1161165 L25.767,24 L31.8838835,17.8838835 L31.9750058,17.7823881 C32.3416647,17.3266086 32.3416647,16.6733914 31.9750058,16.2176119 L31.8838835,16.1161165 L31.7823881,16.0249942 C31.3266086,15.6583353 30.6733914,15.6583353 30.2176119,16.0249942 L30.1161165,16.1161165 L24,22.233 L17.8838835,16.1161165 L17.7823881,16.0249942 L17.8838835,16.1161165 Z"


closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91140884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91140884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,10.0488155 2.34170876,10.0488155 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 L2.14644661,2.14644661 L2.08859116,2.2156945 Z"



