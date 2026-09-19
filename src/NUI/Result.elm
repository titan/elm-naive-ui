module NUI.Result exposing
    ( Options
    , Size(..)
    , Status(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Result`, rebuilt on elm-ui.

    NUI.Result.view theme NUI.Result.defaults []

    NUI.Result.view theme
        { NUI.Result.defaults
            | status = NUI.Result.Code404
            , size = NUI.Result.Huge
            , title = Just "404"
            , description = Just "Page not found"
        }
        [ Element.text "You can put some content here." ]

The visual result is Naive UI's own: the element carries the `.n-result` BEM classes
and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS.
The children of `view` are the default slot (`.n-result-content`); `footer` renders
the footer slot.

-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Result as ResultTheme
import Svg exposing (Svg)
import Svg.Attributes as SA


{-| Naive UI's `status` prop. `Info`/`Success`/`Warning`/`Error` render the
monochrome status icons (they inherit `--n-icon-color`); the HTTP codes render
Naive UI's colorful preset illustrations.
-}
type Status
    = Info
    | Success
    | Warning
    | Error
    | Code403
    | Code404
    | Code418
    | Code500


{-| Naive UI's result sizes (`ResultSize` — unlike most components it has no
`tiny`, but adds `huge`).
-}
type Size
    = Small
    | Medium
    | Large
    | Huge


type alias Options msg =
    { status : Status
    , size : Size
    , title : Maybe String
    , description : Maybe String
    , icon : Maybe (Element msg)
    , footer : Maybe (Element msg)
    }


defaults : Options msg
defaults =
    { status = Info
    , size = Medium
    , title = Nothing
    , description = Nothing
    , icon = Nothing
    , footer = Nothing
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        iconEl =
            Element.el [ I.classes [ "n-result-icon" ] ]
                (case opts.icon of
                    Just custom ->
                        custom

                    Nothing ->
                        Element.html (baseIcon (statusIcon opts.status))
                )

        headerEl =
            Element.column
                [ I.classes [ "n-result-header" ] ]
                (List.concat
                    [ case opts.title of
                        Just t ->
                            [ Element.el [ I.classes [ "n-result-header__title" ] ] (Element.text t) ]

                        Nothing ->
                            []
                    , case opts.description of
                        Just d ->
                            [ Element.el [ I.classes [ "n-result-header__description" ] ] (Element.text d) ]

                        Nothing ->
                            []
                    ]
                )

        contentEl =
            if List.isEmpty children then
                []

            else
                [ Element.column [ I.classes [ "n-result-content" ] ] children ]

        footerEl =
            case opts.footer of
                Just f ->
                    [ Element.el [ I.classes [ "n-result-footer" ] ] f ]

                Nothing ->
                    []
    in
    Element.column
        [ I.classes [ "n-result" ]
        , I.cssVars (cssVarsFor theme opts)
        ]
        ([ iconEl, headerEl ] ++ contentEl ++ footerEl)


{-| The raw `--n-*` custom properties a result with these options attaches (before
`NUI.Internal.renderVars` drops `initial`/empty values). Exposed so the `--n-*`
output can be asserted directly; `view` uses exactly this.

The `403`/`404`/`418`/`500` statuses have no `iconColorXXX` theme variable, so
Naive UI emits `--n-icon-color: ''` — we emit the empty string, which
`NUI.Internal.cssVars` drops (their illustrations carry their own colors).

-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            ResultTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", fontSizeOf opts.size v )
    , ( "--n-icon-size", iconSizeOf opts.size v )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-text-color", v.textColor )
    , ( "--n-title-font-size", titleFontSizeOf opts.size v )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-icon-color", iconColorOf opts.status v )
    ]


{-| Naive UI's `createKey('fontSize', size)`.
-}
fontSizeOf : Size -> ResultTheme.Vars -> String
fontSizeOf size v =
    case size of
        Small ->
            v.fontSizeSmall

        Medium ->
            v.fontSizeMedium

        Large ->
            v.fontSizeLarge

        Huge ->
            v.fontSizeHuge


{-| Naive UI's `createKey('titleFontSize', size)`.
-}
titleFontSizeOf : Size -> ResultTheme.Vars -> String
titleFontSizeOf size v =
    case size of
        Small ->
            v.titleFontSizeSmall

        Medium ->
            v.titleFontSizeMedium

        Large ->
            v.titleFontSizeLarge

        Huge ->
            v.titleFontSizeHuge


{-| Naive UI's `createKey('iconSize', size)`.
-}
iconSizeOf : Size -> ResultTheme.Vars -> String
iconSizeOf size v =
    case size of
        Small ->
            v.iconSizeSmall

        Medium ->
            v.iconSizeMedium

        Large ->
            v.iconSizeLarge

        Huge ->
            v.iconSizeHuge


{-| Naive UI's `createKey('iconColor', status)`; undefined for the HTTP codes
(`iconColor || ''` upstream).
-}
iconColorOf : Status -> ResultTheme.Vars -> String
iconColorOf status v =
    case status of
        Info ->
            v.iconColorInfo

        Success ->
            v.iconColorSuccess

        Warning ->
            v.iconColorWarning

        Error ->
            v.iconColorError

        Code403 ->
            ""

        Code404 ->
            ""

        Code418 ->
            ""

        Code500 ->
            ""



-- ICONS (Naive UI renders the status icon through NBaseIcon: an
-- `<i class="n-base-icon">` wrapping the SVG)


baseIcon : Svg msg -> Html msg
baseIcon icon =
    Html.i [ HA.class "n-base-icon" ] [ icon ]


statusIcon : Status -> Svg msg
statusIcon status =
    case status of
        Info ->
            monochromeIcon "0 0 28 28" infoPath

        Success ->
            monochromeIcon "0 0 48 48" successPath

        Warning ->
            monochromeIcon "0 0 24 24" warningPath

        Error ->
            monochromeIcon "0 0 48 48" errorPath

        Code403 ->
            svg403

        Code404 ->
            svg404

        Code418 ->
            svg418

        Code500 ->
            svg500


{-| The `_internal` status icons: monochrome paths that inherit `currentColor`,
colored by `--n-icon-color` through `.n-base-icon`.
-}
monochromeIcon : String -> String -> Svg msg
monochromeIcon viewBox d =
    Svg.svg
        [ SA.viewBox viewBox
        , SA.version "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.g
            [ SA.stroke "none"
            , SA.strokeWidth "1"
            , SA.fillRule "evenodd"
            ]
            [ Svg.g
                [ SA.fillRule "nonzero" ]
                [ Svg.path [ SA.d d ] [] ]
            ]
        ]


{-| The colorful preset illustrations shipped with `Result` (`result/src/*.tsx`).
-}
presetIcon : List (Svg msg) -> Svg msg
presetIcon children =
    Svg.svg
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , SA.viewBox "0 0 36 36"
        ]
        children


svg403 : Svg msg
svg403 =
    presetIcon
        [ Svg.path
            [ SA.fill "#EF9645"
            , SA.d "M15.5 2.965c1.381 0 2.5 1.119 2.5 2.5v.005L20.5.465c1.381 0 2.5 1.119 2.5 2.5V4.25l2.5-1.535c1.381 0 2.5 1.119 2.5 2.5V8.75L29 18H15.458L15.5 2.965z"
            ]
            []
        , Svg.path
            [ SA.fill "#FFDC5D"
            , SA.d "M4.625 16.219c1.381-.611 3.354.208 4.75 2.188.917 1.3 1.187 3.151 2.391 3.344.46.073 1.234-.313 1.234-1.397V4.5s0-2 2-2 2 2 2 2v11.633c0-.029 1-.064 1-.082V2s0-2 2-2 2 2 2 2v14.053c0 .017 1 .041 1 .069V4.25s0-2 2-2 2 2 2 2v12.638c0 .118 1 .251 1 .398V8.75s0-2 2-2 2 2 2 2V24c0 6.627-5.373 12-12 12-4.775 0-8.06-2.598-9.896-5.292C8.547 28.423 8.096 26.051 8 25.334c0 0-.123-1.479-1.156-2.865-1.469-1.969-2.5-3.156-3.125-3.866-.317-.359-.625-1.707.906-2.384z"
            ]
            []
        ]


svg404 : Svg msg
svg404 =
    presetIcon
        [ Svg.circle
            [ SA.fill "#FFCB4C"
            , SA.cx "18"
            , SA.cy "17.018"
            , SA.r "17"
            ]
            []
        , Svg.path
            [ SA.fill "#65471B"
            , SA.d "M14.524 21.036c-.145-.116-.258-.274-.312-.464-.134-.46.13-.918.59-1.021 4.528-1.021 7.577 1.363 7.706 1.465.384.306.459.845.173 1.205-.286.358-.828.401-1.211.097-.11-.084-2.523-1.923-6.182-1.098-.274.061-.554-.016-.764-.184z"
            ]
            []
        , Svg.ellipse
            [ SA.fill "#65471B"
            , SA.cx "13.119"
            , SA.cy "11.174"
            , SA.rx "2.125"
            , SA.ry "2.656"
            ]
            []
        , Svg.ellipse
            [ SA.fill "#65471B"
            , SA.cx "24.375"
            , SA.cy "12.236"
            , SA.rx "2.125"
            , SA.ry "2.656"
            ]
            []
        , Svg.path
            [ SA.fill "#F19020"
            , SA.d "M17.276 35.149s1.265-.411 1.429-1.352c.173-.972-.624-1.167-.624-1.167s1.041-.208 1.172-1.376c.123-1.101-.861-1.363-.861-1.363s.97-.4 1.016-1.539c.038-.959-.995-1.428-.995-1.428s5.038-1.221 5.556-1.341c.516-.12 1.32-.615 1.069-1.694-.249-1.08-1.204-1.118-1.697-1.003-.494.115-6.744 1.566-8.9 2.068l-1.439.334c-.54.127-.785-.11-.404-.512.508-.536.833-1.129.946-2.113.119-1.035-.232-2.313-.433-2.809-.374-.921-1.005-1.649-1.734-1.899-1.137-.39-1.945.321-1.542 1.561.604 1.854.208 3.375-.833 4.293-2.449 2.157-3.588 3.695-2.83 6.973.828 3.575 4.377 5.876 7.952 5.048l3.152-.681z"
            ]
            []
        , Svg.path
            [ SA.fill "#65471B"
            , SA.d "M9.296 6.351c-.164-.088-.303-.224-.391-.399-.216-.428-.04-.927.393-1.112 4.266-1.831 7.699-.043 7.843.034.433.231.608.747.391 1.154-.216.405-.74.546-1.173.318-.123-.063-2.832-1.432-6.278.047-.257.109-.547.085-.785-.042zm12.135 3.75c-.156-.098-.286-.243-.362-.424-.187-.442.023-.927.468-1.084 4.381-1.536 7.685.48 7.823.567.415.26.555.787.312 1.178-.242.39-.776.495-1.191.238-.12-.072-2.727-1.621-6.267-.379-.266.091-.553.046-.783-.096z"
            ]
            []
        ]


svg418 : Svg msg
svg418 =
    presetIcon
        [ Svg.ellipse
            [ SA.fill "#292F33"
            , SA.cx "18"
            , SA.cy "26"
            , SA.rx "18"
            , SA.ry "10"
            ]
            []
        , Svg.ellipse
            [ SA.fill "#66757F"
            , SA.cx "18"
            , SA.cy "24"
            , SA.rx "18"
            , SA.ry "10"
            ]
            []
        , Svg.path
            [ SA.fill "#E1E8ED"
            , SA.d "M18 31C3.042 31 1 16 1 12h34c0 2-1.958 19-17 19z"
            ]
            []
        , Svg.path
            [ SA.fill "#77B255"
            , SA.d "M35 12.056c0 5.216-7.611 9.444-17 9.444S1 17.271 1 12.056C1 6.84 8.611 3.611 18 3.611s17 3.229 17 8.445z"
            ]
            []
        , Svg.ellipse
            [ SA.fill "#A6D388"
            , SA.cx "18"
            , SA.cy "13"
            , SA.rx "15"
            , SA.ry "7"
            ]
            []
        , Svg.path
            [ SA.d "M21 17c-.256 0-.512-.098-.707-.293-2.337-2.337-2.376-4.885-.125-8.262.739-1.109.9-2.246.478-3.377-.461-1.236-1.438-1.996-1.731-2.077-.553 0-.958-.443-.958-.996 0-.552.491-.995 1.043-.995.997 0 2.395 1.153 3.183 2.625 1.034 1.933.91 4.039-.351 5.929-1.961 2.942-1.531 4.332-.125 5.738.391.391.391 1.023 0 1.414-.195.196-.451.294-.707.294zm-6-2c-.256 0-.512-.098-.707-.293-2.337-2.337-2.376-4.885-.125-8.262.727-1.091.893-2.083.494-2.947-.444-.961-1.431-1.469-1.684-1.499-.552 0-.989-.447-.989-1 0-.552.458-1 1.011-1 .997 0 2.585.974 3.36 2.423.481.899 1.052 2.761-.528 5.131-1.961 2.942-1.531 4.332-.125 5.738.391.391.391 1.023 0 1.414-.195.197-.451.295-.707.295z"
            , SA.fill "#5C913B"
            ]
            []
        ]


svg500 : Svg msg
svg500 =
    presetIcon
        [ Svg.path
            [ SA.fill "#FFCC4D"
            , SA.d "M36 18c0 9.941-8.059 18-18 18-9.94 0-18-8.059-18-18C0 8.06 8.06 0 18 0c9.941 0 18 8.06 18 18"
            ]
            []
        , Svg.ellipse
            [ SA.fill "#664500"
            , SA.cx "18"
            , SA.cy "27"
            , SA.rx "5"
            , SA.ry "6"
            ]
            []
        , Svg.path
            [ SA.fill "#664500"
            , SA.d "M5.999 11c-.208 0-.419-.065-.599-.2-.442-.331-.531-.958-.2-1.4C8.462 5.05 12.816 5 13 5c.552 0 1 .448 1 1 0 .551-.445.998-.996 1-.155.002-3.568.086-6.204 3.6-.196.262-.497.4-.801.4zm24.002 0c-.305 0-.604-.138-.801-.4-2.64-3.521-6.061-3.598-6.206-3.6-.55-.006-.994-.456-.991-1.005C22.006 5.444 22.45 5 23 5c.184 0 4.537.05 7.8 4.4.332.442.242 1.069-.2 1.4-.18.135-.39.2-.599.2zm-16.087 4.5l1.793-1.793c.391-.391.391-1.023 0-1.414s-1.023-.391-1.414 0L12.5 14.086l-1.793-1.793c-.391-.391-1.023-.391-1.414 0s-.391 1.023 0 1.414l1.793 1.793-1.793 1.793c-.391.391-.391 1.023 0 1.414.195.195.451.293.707.293s.512-.098.707-.293l1.793-1.793 1.793 1.793c.195.195.451.293.707.293s.512-.098.707-.293c.391-.391.391-1.023 0-1.414L13.914 15.5zm11 0l1.793-1.793c.391-.391.391-1.023 0-1.414s-1.023-.391-1.414 0L23.5 14.086l-1.793-1.793c-.391-.391-1.023-.391-1.414 0s-.391 1.023 0 1.414l1.793 1.793-1.793 1.793c-.391.391-.391 1.023 0 1.414.195.195.451.293.707.293s.512-.098.707-.293l1.793-1.793 1.793 1.793c.195.195.451.293.707.293s.512-.098.707-.293c.391-.391.391-1.023 0-1.414L24.914 15.5z"
            ]
            []
        ]


infoPath : String
infoPath =
    "M14,2 C20.6274,2 26,7.37258 26,14 C26,20.6274 20.6274,26 14,26 C7.37258,26 2,20.6274 2,14 C2,7.37258 7.37258,2 14,2 Z M14,11 C13.4477,11 13,11.4477 13,12 L13,12 L13,20 C13,20.5523 13.4477,21 14,21 C14.5523,21 15,20.5523 15,20 L15,20 L15,12 C15,11.4477 14.5523,11 14,11 Z M14,6.75 C13.3096,6.75 12.75,7.30964 12.75,8 C12.75,8.69036 13.3096,9.25 14,9.25 C14.6904,9.25 15.25,8.69036 15.25,8 C15.25,7.30964 14.6904,6.75 14,6.75 Z"


successPath : String
successPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M32.6338835,17.6161165 C32.1782718,17.1605048 31.4584514,17.1301307 30.9676119,17.5249942 L30.8661165,17.6161165 L20.75,27.732233 L17.1338835,24.1161165 C16.6457281,23.6279612 15.8542719,23.6279612 15.3661165,24.1161165 C14.9105048,24.5717282 14.8801307,25.2915486 15.2749942,25.7823881 L15.3661165,25.8838835 L19.8661165,30.3838835 C20.3217282,30.8394952 21.0415486,30.8698693 21.5323881,30.4750058 L21.6338835,30.3838835 L32.6338835,19.3838835 C33.1220388,18.8957281 33.1220388,18.1042719 32.6338835,17.6161165 Z"


warningPath : String
warningPath =
    "M12,2 C17.523,2 22,6.478 22,12 C22,17.522 17.523,22 12,22 C6.477,22 2,17.522 2,12 C2,6.478 6.477,2 12,2 Z M12.0018002,15.0037242 C11.450254,15.0037242 11.0031376,15.4508407 11.0031376,16.0023869 C11.0031376,16.553933 11.450254,17.0010495 12.0018002,17.0010495 C12.5533463,17.0010495 13.0004628,16.553933 13.0004628,16.0023869 C13.0004628,15.4508407 12.5533463,15.0037242 12.0018002,15.0037242 Z M11.99964,7 C11.4868042,7.00018474 11.0642719,7.38637706 11.0066858,7.8837365 L11,8.00036004 L11.0018003,13.0012393 L11.00857,13.117858 C11.0665141,13.6151755 11.4893244,14.0010638 12.0021602,14.0008793 C12.5149968,14.0006946 12.9375283,13.6145023 12.9951144,13.1171428 L13.0018002,13.0005193 L13,7.99964009 L12.9932303,7.8830214 C12.9352861,7.38570354 12.5124758,6.99981552 11.99964,7 Z"


errorPath : String
errorPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M17.8838835,16.1161165 L17.7823881,16.0249942 C17.3266086,15.6583353 16.6733914,15.6583353 16.2176119,16.0249942 L16.1161165,16.1161165 L16.0249942,16.2176119 C15.6583353,16.6733914 15.6583353,17.3266086 16.0249942,17.7823881 L16.1161165,17.8838835 L22.233,24 L16.1161165,30.1161165 L16.0249942,30.2176119 C15.6583353,30.6733914 15.6583353,31.3266086 16.0249942,31.7823881 L16.1161165,31.8838835 L16.2176119,31.9750058 C16.6733914,32.3416647 17.3266086,32.3416647 17.7823881,31.9750058 L17.8838835,31.8838835 L24,25.767 L30.1161165,31.8838835 L30.2176119,31.9750058 C30.6733914,32.3416647 31.3266086,32.3416647 31.7823881,31.9750058 L31.8838835,31.8838835 L31.9750058,31.7823881 C32.3416647,31.3266086 32.3416647,30.6733914 31.9750058,30.2176119 L31.8838835,30.1161165 L25.767,24 L31.8838835,17.8838835 L31.9750058,17.7823881 C32.3416647,17.3266086 32.3416647,16.6733914 31.9750058,16.2176119 L31.8838835,16.1161165 L31.7823881,16.0249942 C31.3266086,15.6583353 30.6733914,15.6583353 30.2176119,16.0249942 L30.1161165,16.1161165 L24,22.233 L17.8838835,16.1161165 L17.7823881,16.0249942 L17.8838835,16.1161165 Z"
