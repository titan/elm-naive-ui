module NUI.Thing exposing
    ( Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Thing`, rebuilt on elm-ui.

    NUI.Thing.view theme
        { NUI.Thing.defaults
            | avatar = Just (Element.text "A")
            , title = Just "naive-ui"
            , titleExtra = Just "v2.0"
            , description = Just "A Vue 3 component library."
        }
        [ Element.text "Thing content." ]

The element carries the `.n-thing` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

**Header layout.** Exactly as upstream: when `contentIndented` is set the avatar
sits above the whole block; otherwise the avatar leads an
`n-thing-avatar-header-wrapper` row (when the thing has an avatar or header).
Content goes in the default slot, `description` is the label line.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Thing as ThingTheme


type alias Options msg =
    { title : Maybe String
    , titleExtra : Maybe String
    , description : Maybe String
    , contentIndented : Bool
    , avatar : Maybe (Element msg)
    , footer : Maybe (Element msg)
    , action : Maybe (Element msg)
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { title = Nothing
    , titleExtra = Nothing
    , description = Nothing
    , contentIndented = False
    , avatar = Nothing
    , footer = Nothing
    , action = Nothing
    , rtl = False
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        hasHeader =
            opts.title /= Nothing || opts.titleExtra /= Nothing

        headerEl =
            if hasHeader then
                Just
                    (Element.row
                        [ I.classes [ "n-thing-header" ] ]
                        (titleEl opts ++ titleExtraEl opts)
                    )

            else
                Nothing

        descriptionEl =
            Maybe.map
                (\d ->
                    Element.row
                        [ I.classes [ "n-thing-main__description" ] ]
                        [ Element.text d ]
                )
                opts.description

        mainHeader =
            if not opts.contentIndented && (hasHeader || opts.avatar /= Nothing) then
                [ Element.row
                    [ I.classes [ "n-thing-avatar-header-wrapper" ] ]
                    (List.filterMap identity
                        [ avatarEl opts
                        , if hasHeader then
                            Just
                                (Element.column
                                    [ I.classes [ "n-thing-header-wrapper" ] ]
                                    (List.filterMap identity [ headerEl, descriptionEl ])
                                )

                          else
                            Nothing
                        ]
                    )
                ]

            else
                List.filterMap identity [ headerEl, descriptionEl ]

        contentEl =
            if List.isEmpty children then
                Nothing

            else
                Just (Element.column [ I.classes [ "n-thing-main__content" ] ] children)

        footerEl =
            Maybe.map
                (\f -> Element.row [ I.classes [ "n-thing-main__footer" ] ] [ f ])
                opts.footer

        actionEl =
            Maybe.map
                (\a -> Element.row [ I.classes [ "n-thing-main__action" ] ] [ a ])
                opts.action

        mainEl =
            Element.column
                [ I.classes [ "n-thing-main" ] ]
                (mainHeader ++ List.filterMap identity [ contentEl, footerEl, actionEl ])

        topAvatarEl =
            if opts.contentIndented then
                avatarEl opts

            else
                Nothing
    in
    Element.row
        (I.classes
            ("n-thing" :: I.classIf opts.rtl "n-thing--rtl")
            :: I.cssVars (cssVarsFor theme)
            :: opts.attributes
        )
        (List.filterMap identity [ topAvatarEl ] ++ [ mainEl ])


titleEl : Options msg -> List (Element msg)
titleEl opts =
    case opts.title of
        Just title ->
            [ Element.el [ I.classes [ "n-thing-header__title" ] ] (Element.text title) ]

        Nothing ->
            []


titleExtraEl : Options msg -> List (Element msg)
titleExtraEl opts =
    case opts.titleExtra of
        Just extra ->
            [ Element.el [ I.classes [ "n-thing-header__extra" ] ] (Element.text extra) ]

        Nothing ->
            []


avatarEl : Options msg -> Maybe (Element msg)
avatarEl opts =
    Maybe.map
        (\a -> Element.row [ I.classes [ "n-thing-avatar" ] ] [ a ])
        opts.avatar


{-| The thing's `--n-*` custom properties (they do not depend on the options).
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            ThingTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-text-color", v.textColor )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-title-text-color", v.titleTextColor )
    ]
