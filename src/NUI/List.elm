module NUI.List exposing (Item, Options, cssVarsFor, defaults, item, view)

{-| Naive UI's `List` and `ListItem`, rebuilt on elm-ui.

@docs Item, Options, cssVarsFor, defaults, item, view

    import NUI.List exposing (item)

    NUI.List.view theme
        NUI.List.defaults
        [ { item | content = [ Element.text "First" ] }
        , { item
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


{-| The `n-list` props — the shell's border / hover / click modifiers, the
divider injection, and the optional header / footer slots. The list's
`size` prop has no markup or var effect upstream and is not modelled.
-}
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


{-| A plain list: dividers on, no border, no hover / click affordances, no
header / footer, LTR.
-}
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


{-| An empty item — no prefix, no content, no suffix.
-}
item : Item msg
item =
    { prefix = Nothing
    , content = []
    , suffix = Nothing
    }


{-| The `n-list` element: optional header, the items as `n-list-item` rows
(prefix? main, suffix?, divider when `showDivider`), optional footer —
the list's `--n-*` vars on the root. `showDivider` is read per item here
(upstream injects it into every child instead).
-}
view : Theme -> Options msg -> List (Item msg) -> Element msg
view theme opts items =
    let
        headerEl =
            Maybe.map
                (\h -> Element.row [ I.classes [ "n-list__header" ], fillWidth ] [ h ])
                opts.header

        footerEl =
            Maybe.map
                (\f -> Element.row [ I.classes [ "n-list__footer" ], fillWidth ] [ f ])
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
        [ I.classes [ "n-list-item" ]
        , fillWidth
        ]
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


{-| elm-ui's `.s.c > .s.wc` sets `align-self: flex-start` on a width-content row
child, so `.n-list-item` / `__header` / `__footer` collapse to their content
width. Upstream renders `n-list-item` as a full-width flex row
(`.n-list-item { display: flex }`), so restore the browser default and let the
row span the list — otherwise the bordered shell's right edge only ever meets
the content. `Element.width Element.fill` (the `wf` class) resolves to
`width: 100%` under the `n-list` column.
-}
fillWidth : Element.Attribute msg
fillWidth =
    Element.width Element.fill


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
