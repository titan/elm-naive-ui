module NUI.PageHeader exposing
    ( Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `PageHeader`, rebuilt on elm-ui.

    import NUI.PageHeader exposing (defaults)

    NUI.PageHeader.view theme
        { defaults
            | title = Just "Users"
            , subtitle = Just "Manage the team."
            , onBack = Just Back
            , extra = Just "Extra"
        }
        [ Element.text "Page content." ]

The element carries the `.n-page-header*` BEM classes and Naive UI's `--n-*`
custom properties, and `NUI.Css` ships Naive UI's exact CSS.

`showBack` is driven by `onBack` (`Nothing` hides the back control, exactly as
upstream keys it off the `on-back` prop); `back` replaces the default arrow icon.

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.PageHeader as PageHeaderTheme
import Svg


type alias Options msg =
    { title : Maybe String
    , subtitle : Maybe String
    , extra : Maybe String
    , onBack : Maybe msg
    , avatar : Maybe (Element msg)
    , header : Maybe (Element msg)
    , footer : Maybe (Element msg)
    , back : Maybe (Element msg)
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { title = Nothing
    , subtitle = Nothing
    , extra = Nothing
    , onBack = Nothing
    , avatar = Nothing
    , header = Nothing
    , footer = Nothing
    , back = Nothing
    , rtl = False
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        showBack =
            opts.onBack /= Nothing

        showTitle =
            opts.title /= Nothing

        showSubtitle =
            opts.subtitle /= Nothing

        showExtra =
            opts.extra /= Nothing

        headerSlot =
            Maybe.map
                (\h -> Element.row [ I.classes [ "n-page-header-header" ] ] [ h ])
                opts.header

        headerEl =
            if showBack || opts.avatar /= Nothing || showTitle || showSubtitle || showExtra then
                Just
                    (Element.row
                        [ I.classes [ "n-page-header" ]
                        , fillWidth
                        ]
                        (Element.row
                            [ I.classes [ "n-page-header__main" ] ]
                            (List.filterMap identity
                                [ backEl opts
                                , avatarEl opts
                                , textEl "n-page-header__title" opts.title
                                , textEl "n-page-header__subtitle" opts.subtitle
                                ]
                            )
                            :: List.filterMap identity
                                [ textEl "n-page-header__extra" opts.extra ]
                        )
                    )

            else
                Nothing

        contentEl =
            if List.isEmpty children then
                Nothing

            else
                Just (Element.column [ I.classes [ "n-page-header-content" ] ] children)

        footerEl =
            Maybe.map
                (\f -> Element.row [ I.classes [ "n-page-header-footer" ] ] [ f ])
                opts.footer
    in
    Element.column
        (I.classes
            ("n-page-header-wrapper"
                :: I.classIf opts.rtl "n-page-header-wrapper--rtl"
            )
            :: I.cssVars (cssVarsFor theme)
            :: opts.attributes
        )
        (List.filterMap identity [ headerSlot, headerEl, contentEl, footerEl ])


avatarEl : Options msg -> Maybe (Element msg)
avatarEl opts =
    Maybe.map
        (\a -> Element.row [ I.classes [ "n-page-header__avatar" ] ] [ a ])
        opts.avatar


textEl : String -> Maybe String -> Maybe (Element msg)
textEl className maybeText =
    Maybe.map
        (\t -> Element.el [ I.classes [ className ] ] (Element.text t))
        maybeText


{-| The `n-page-header` flex row must span its wrapper so
`justify-content: space-between` can push `n-page-header__extra` to the
container's right edge (upstream's `__extra` is a sibling of `__main` on a
plain full-width div). elm-ui's `.s.c > .s.wc` sets `align-self: flex-start`
on a width-content child of a column, collapsing the row to its content and
leaving `extra` abutting the subtitle; `Element.width Element.fill` (the `wf`
class) resolves to `width: 100%` under the wrapper column.
-}
fillWidth : Element.Attribute msg
fillWidth =
    Element.width Element.fill


backEl : Options msg -> Maybe (Element msg)
backEl opts =
    if opts.onBack == Nothing then
        Nothing

    else
        Just
            (Element.row
                ([ I.classes [ "n-page-header__back" ] ]
                    ++ (case opts.onBack of
                            Just msg ->
                                [ Events.onClick msg ]

                            Nothing ->
                                []
                       )
                )
                [ Maybe.withDefault defaultBackIcon opts.back ]
            )


{-| Naive UI's `ArrowBackIcon` inside an `NBaseIcon` (`.n-base-icon`, styled by
the extracted internal stylesheet).
-}
defaultBackIcon : Element msg
defaultBackIcon =
    Element.html <|
        Html.i
            [ HA.class "n-base-icon" ]
            [ Svg.node "svg"
                [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
                , HA.attribute "viewBox" "0 0 24 24"
                ]
                [ Svg.node "path"
                    [ HA.attribute "fill" "none"
                    , HA.attribute "d" "M0 0h24v24H0V0z"
                    ]
                    []
                , Svg.node "path"
                    [ HA.attribute "d" arrowBackPath ]
                    []
                ]
            ]


arrowBackPath : String
arrowBackPath =
    "M19 11H7.83l4.88-4.88c.39-.39.39-1.03 0-1.42-.39-.39-1.02-.39-1.41 0l-6.59 6.59c-.39.39-.39 1.02 0 1.41l6.59 6.59c.39.39 1.02.39 1.41 0 .39-.39.39-1.02 0-1.41L7.83 13H19c.55 0 1-.45 1-1s-.45-1-1-1z"


{-| The page header's `--n-*` custom properties (they do not depend on the
options).
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            PageHeaderTheme.vars theme
    in
    [ ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-title-font-size", v.titleFontSize )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-back-size", v.backSize )
    , ( "--n-subtitle-text-color", v.subtitleTextColor )
    , ( "--n-back-color", v.backColor )
    , ( "--n-back-color-hover", v.backColorHover )
    , ( "--n-back-color-pressed", v.backColorPressed )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    ]
