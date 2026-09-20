module NUI.Avatar exposing
    ( AvatarSize(..)
    , Options
    , defaults
    , view
    )

{-| Naive UI's `Avatar`, rebuilt on elm-ui.

    import NUI.Avatar exposing (defaults)

    NUI.Avatar.view theme
        { defaults | src = Just "https://example.com/avatar.png" }
        []

    NUI.Avatar.view theme NUI.Avatar.defaults [ Element.text "N" ]

Text children are centered the way Naive UI's `fitTextTransform` does after its
initial measurement (the measurement-driven downscale of oversized text is not
reproduced).

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Avatar as AvatarTheme


{-| Naive UI's avatar `size`: a preset name (including `huge`, which only Avatar
uses) or an explicit pixel number.
-}
type AvatarSize
    = Tiny
    | Small
    | Medium
    | Large
    | Huge
    | Number Int


type alias Options msg =
    { size : AvatarSize
    , round : Bool
    , circle : Bool
    , bordered : Bool
    , color : Maybe String
    , src : Maybe String
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { size = Medium
    , round = False
    , circle = False
    , bordered = False
    , color = Nothing
    , src = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        v =
            AvatarTheme.vars theme

        isRound =
            opts.round || opts.circle

        height =
            heightOf opts.size v

        body =
            if not (List.isEmpty children) then
                [ Element.row
                    [ I.classes [ "n-avatar__text" ]
                    , Element.htmlAttribute
                        (HA.style "transform" "translateX(-50%) translateY(-50%)")
                    ]
                    children
                ]

            else
                case opts.src of
                    Just src ->
                        [ Element.image
                            [ I.classes [ "n-avatar__img" ]
                            , Element.htmlAttribute (HA.style "width" "100%")
                            , Element.htmlAttribute (HA.style "height" "100%")
                            ]
                            { src = src, description = "" }
                        ]

                    Nothing ->
                        []

        vars =
            [ ( "--n-font-size", v.fontSize )
            , ( "--n-border"
              , if opts.bordered then
                    v.border

                else
                    "none"
              )
            , ( "--n-border-radius"
              , if isRound then
                    "50%"

                else
                    v.borderRadius
              )
            , ( "--n-color", Maybe.withDefault v.color opts.color )
            , ( "--n-color-modal", Maybe.withDefault v.colorModal opts.color )
            , ( "--n-color-popover", Maybe.withDefault v.colorPopover opts.color )
            , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
            , ( "--n-merged-size", "var(--n-avatar-size-override, " ++ height ++ ")" )
            ]
    in
    Element.row
        ([ I.classes [ "n-avatar" ]
         , I.cssVars vars
         ]
            ++ opts.attributes
        )
        body


heightOf : AvatarSize -> AvatarTheme.Vars -> String
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

        Huge ->
            v.heightHuge

        Number n ->
            String.fromInt n ++ "px"
