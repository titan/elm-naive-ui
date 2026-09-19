module NUI.BackTop exposing
    ( Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `BackTop`, rebuilt on elm-ui.

    NUI.BackTop.view theme
        { NUI.BackTop.defaults | show = True, onClick = Just ScrollToTop }
        []

The element carries the `.n-back-top` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS (including the
`fade-in-scale-up-transition` rules).

**Runtime.** Upstream decides `show` from a scroll listener, teleports the button
to `body`, and compensates for the locked scrollbar width. This library is pure,
so the caller owns `show` (the button renders only while true) and the offsets;
the `fade-in-scale-up-transition` phase is caller-owned too (pass `transition`).
The `to` / `listen-to` teleport target and the scrollbar-width calc are not
reproduced.

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.BackTop as BackTopTheme


type alias Options msg =
    { show : Bool
    , right : String
    , bottom : String
    , transitionDisabled : Bool
    , transition : Maybe I.TransitionPhase
    , onClick : Maybe msg
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { show = False
    , right = "40px"
    , bottom = "40px"
    , transitionDisabled = False
    , transition = Nothing
    , onClick = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    if not opts.show then
        Element.none

    else
        let
            transitionClasses =
                case opts.transition of
                    Just phase ->
                        [ I.transitionClass "fade-in-scale-up-transition" phase ]

                    Nothing ->
                        []

            clickAttrs =
                case opts.onClick of
                    Just msg ->
                        [ Events.onClick msg ]

                    Nothing ->
                        []
        in
        Element.row
            ([ I.classes
                (("n-back-top"
                    :: I.classIf opts.transitionDisabled "n-back-top--transition-disabled"
                 )
                    ++ transitionClasses
                )
             , I.cssVars ([ ( "right", opts.right ), ( "bottom", opts.bottom ) ] ++ cssVarsFor theme)
             ]
                ++ clickAttrs
                ++ opts.attributes
            )
            (if List.isEmpty children then
                [ defaultIcon ]

             else
                children
            )


{-| The back-top's `--n-*` custom properties (they do not depend on the options).
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            BackTopTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-height", v.height )
    , ( "--n-width", v.width )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-box-shadow-hover", v.boxShadowHover )
    , ( "--n-box-shadow-pressed", v.boxShadowPressed )
    , ( "--n-color", v.color )
    , ( "--n-icon-size", v.iconSize )
    , ( "--n-icon-color", v.iconColor )
    , ( "--n-icon-color-hover", v.iconColorHover )
    , ( "--n-icon-color-pressed", v.iconColorPressed )
    , ( "--n-text-color", v.textColor )
    ]


{-| Naive UI's default icon inside `NBaseIcon` (`.n-base-icon`).
-}
defaultIcon : Element msg
defaultIcon =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ iconSvg ])


iconSvg : Html.Html msg
iconSvg =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 24 24"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Html.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Html.node "g"
                [ HA.attribute "transform" "translate(-139.000000, -4423.000000)"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Html.node "g"
                    [ HA.attribute "transform" "translate(120.000000, 4285.000000)" ]
                    [ Html.node "g"
                        [ HA.attribute "transform" "translate(7.000000, 126.000000)" ]
                        [ Html.node "g"
                            [ HA.attribute "transform" "translate(24.000000, 24.000000) scale(1, -1) translate(-24.000000, -24.000000) translate(12.000000, 12.000000)" ]
                            [ Html.node "g"
                                [ HA.attribute "transform" "translate(4.000000, 2.000000)" ]
                                [ Html.node "path" [ HA.attribute "d" arrowPath ] []
                                , Html.node "path" [ HA.attribute "d" barPath ] []
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


arrowPath : String
arrowPath =
    "M8,0 C8.51283584,0 8.93550716,0.38604019 8.99327227,0.883378875 L9,1 L9,10.584 L12.2928932,7.29289322 C12.6834175,6.90236893 13.3165825,6.90236893 13.7071068,7.29289322 C14.0675907,7.65337718 14.0953203,8.22060824 13.7902954,8.61289944 L13.7071068,8.70710678 L8.70710678,13.7071068 L8.62544899,13.7803112 L8.618,13.784 L8.59530661,13.8036654 L8.4840621,13.8753288 L8.37133602,13.9287745 L8.22929083,13.9735893 L8.14346259,13.9897165 L8.03324678,13.9994506 L7.9137692,13.9962979 L7.77070917,13.9735893 L7.6583843,13.9401293 L7.57677845,13.9063266 L7.47929125,13.8540045 L7.4048407,13.8036865 L7.38131006,13.7856883 C7.35030318,13.7612383 7.32077858,13.7349921 7.29289322,13.7071068 L2.29289322,8.70710678 L2.20970461,8.61289944 C1.90467972,8.22060824 1.93240926,7.65337718 2.29289322,7.29289322 C2.65337718,6.93240926 3.22060824,6.90467972 3.61289944,7.20970461 L3.70710678,7.29289322 L7,10.585 L7,1 L7.00672773,0.883378875 C7.06449284,0.38604019 7.48716416,0 8,0 Z"


barPath : String
barPath =
    "M14.9333333,15.9994506 C15.5224371,15.9994506 16,16.4471659 16,16.9994506 C16,17.5122865 15.5882238,17.9349578 15.0577292,17.9927229 L14.9333333,17.9994506 L1.06666667,17.9994506 C0.477562934,17.9994506 0,17.5517354 0,16.9994506 C0,16.4866148 0.411776203,16.0639435 0.9422708,16.0061783 L1.06666667,15.9994506 L14.9333333,15.9994506 Z"
