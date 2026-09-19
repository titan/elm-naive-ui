module NUI.List exposing
    ( Item
    , Options
    , cssVarsFor
    , defaults
    , item
    , view
    )

{-| Naive UI's `List` and `ListItem`, rebuilt on elm-ui.

    NUI.List.view theme
        NUI.List.defaults
        [ { NUI.List.item | content = [ Element.text "First" ] }
        , { NUI.List.item
            | prefix = Just (Element.text "•")
            , content = [ Element.text "Second" ]
            , suffix = Just (Element.text "→")
          }
        ]

The element carries the `.n-list` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

Naive UI injects `showDivider` from the list into each item; here items are plain
records rendered by the list itself, so the divider is controlled by the list's
`showDivider` (Naive UI's `size` prop, incidentally, has no effect on the
markup or the variables, so it is not modelled).

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.List as ListTheme


type alias Options msg =
    { bordered : Bool
    , clickable : Bool
    , hoverable : Bool
    , showDivider : Bool
    , header : Maybe (Element msg)
    , footer : Maybe (Element msg)
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { bordered = False
    , clickable = False
    , hoverable = False
    , showDivider = True
    , header = Nothing
    , footer = Nothing
    , rtl = False
    , attributes = []
    }


{-| One list entry — upstream's `n-list-item`. `content` is its default slot.
-}
type alias Item msg =
    { prefix : Maybe (Element msg)
    , content : List (Element msg)
    , suffix : Maybe (Element msg)
    }


item : Item msg
item =
    { prefix = Nothing
    , content = []
    , suffix = Nothing
    }


view : Theme -> Options msg -> List (Item msg) -> Element msg
view theme opts items =
    let
        headerEl =
            Maybe.map
                (\h -> Element.row [ I.classes [ "n-list__header" ] ] [ h ])
                opts.header

        footerEl =
            Maybe.map
                (\f -> Element.row [ I.classes [ "n-list__footer" ] ] [ f ])
                opts.footer
    in
    Element.column
        (I.classes
            ([ "n-list" ]
                ++ I.classIf opts.rtl "n-list--rtl"
                ++ I.classIf opts.bordered "n-list--bordered"
                ++ I.classIf opts.showDivider "n-list--show-divider"
                ++ I.classIf opts.hoverable "n-list--hoverable"
                ++ I.classIf opts.clickable "n-list--clickable"
            )
            :: I.cssVars (cssVarsFor theme)
            :: opts.attributes
        )
        (List.filterMap identity [ headerEl ]
            ++ List.map (renderItem opts) items
            ++ List.filterMap identity [ footerEl ]
        )


renderItem : Options msg -> Item msg -> Element msg
renderItem opts it =
    Element.row
        [ I.classes [ "n-list-item" ] ]
        (List.filterMap identity
            [ Maybe.map
                (\p -> Element.row [ I.classes [ "n-list-item__prefix" ] ] [ p ])
                it.prefix
            , if List.isEmpty it.content then
                Nothing

              else
                Just (Element.column [ I.classes [ "n-list-item__main" ] ] it.content)
            , Maybe.map
                (\s -> Element.row [ I.classes [ "n-list-item__suffix" ] ] [ s ])
                it.suffix
            , if opts.showDivider then
                Just (Element.el [ I.classes [ "n-list-item__divider" ] ] Element.none)

              else
                Nothing
            ]
        )


{-| The list's `--n-*` custom properties (they do not depend on the options).
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            ListTheme.vars theme
    in
    [ ( "--n-font-size", v.fontSize )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-text-color", v.textColor )
    , ( "--n-color", v.color )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-border-color-modal", v.borderColorModal )
    , ( "--n-border-color-popover", v.borderColorPopover )
    , ( "--n-color-modal", v.colorModal )
    , ( "--n-color-popover", v.colorPopover )
    , ( "--n-color-hover", v.colorHover )
    , ( "--n-color-hover-modal", v.colorHoverModal )
    , ( "--n-color-hover-popover", v.colorHoverPopover )
    ]
