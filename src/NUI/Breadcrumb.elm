module NUI.Breadcrumb exposing
    ( Item
    , Options
    , cssVarsFor
    , defaults
    , item
    , view
    )

{-| Naive UI's `Breadcrumb` and `BreadcrumbItem`, rebuilt on elm-ui.

    import NUI.Breadcrumb exposing (item)

    NUI.Breadcrumb.view theme
        NUI.Breadcrumb.defaults
        [ { item | content = [ Element.text "Home" ], href = Just "/" }
        , { item | content = [ Element.text "Library" ], href = Just "/library" }
        , { item | content = [ Element.text "Data" ] }
        ]

The element carries the `.n-breadcrumb` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

**Separator.** Naive UI injects the breadcrumb's `separator` into each item
(`item.separator ?? breadcrumb.separator`); Elm has no injection, so each `Item`
carries its own `separator` (falling back to `"/"` when unset). Set it on the
items when you change the breadcrumb's separator.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Breadcrumb as BreadcrumbTheme


type alias Options msg =
    { separator : String
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { separator = "/"
    , attributes = []
    }


{-| One breadcrumb entry — upstream's `n-breadcrumb-item`. `content` is its
default slot; `href` renders a real anchor (`a.n-breadcrumb-item__link`),
otherwise a `span`. `attributes` lets callers add e.g. `aria-current`.
-}
type alias Item msg =
    { href : Maybe String
    , clickable : Bool
    , showSeparator : Bool
    , separator : Maybe String
    , content : List (Element msg)
    , attributes : List (Element.Attribute msg)
    }


item : Item msg
item =
    { href = Nothing
    , clickable = True
    , showSeparator = True
    , separator = Nothing
    , content = []
    , attributes = []
    }


view : Theme -> Options msg -> List (Item msg) -> Element msg
view theme opts items =
    Element.el
        ([ I.classes [ "n-breadcrumb" ]
         , I.cssVars (cssVarsFor theme)
         , Element.htmlAttribute (HA.attribute "aria-label" "Breadcrumb")
         ]
            ++ opts.attributes
        )
        (Element.row [] (List.map (renderItem opts) items))


renderItem : Options msg -> Item msg -> Element msg
renderItem opts it =
    Element.row
        (I.classes
            ("n-breadcrumb-item"
                :: I.classIf it.clickable "n-breadcrumb-item--clickable"
            )
            :: it.attributes
        )
        (linkEl it :: separatorEl opts it)


linkEl : Item msg -> Element msg
linkEl it =
    let
        linkAttrs =
            [ I.classes [ "n-breadcrumb-item__link" ] ]
    in
    case it.href of
        Just url ->
            Element.link linkAttrs
                { url = url, label = Element.paragraph [] it.content }

        Nothing ->
            Element.row linkAttrs it.content


separatorEl : Options msg -> Item msg -> List (Element msg)
separatorEl opts it =
    if it.showSeparator then
        [ Element.el
            [ I.classes [ "n-breadcrumb-item__separator" ]
            , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
            ]
            (Element.text (Maybe.withDefault opts.separator it.separator))
        ]

    else
        []


{-| The breadcrumb's `--n-*` custom properties (they do not depend on the
options). Exposed so the output can be asserted directly; `view` uses this.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            BreadcrumbTheme.vars theme
    in
    [ ( "--n-font-size", v.fontSize )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-item-text-color", v.itemTextColor )
    , ( "--n-item-text-color-hover", v.itemTextColorHover )
    , ( "--n-item-text-color-pressed", v.itemTextColorPressed )
    , ( "--n-item-text-color-active", v.itemTextColorActive )
    , ( "--n-separator-color", v.separatorColor )
    , ( "--n-item-color-hover", v.itemColorHover )
    , ( "--n-item-color-pressed", v.itemColorPressed )
    , ( "--n-item-border-radius", v.itemBorderRadius )
    , ( "--n-font-weight-active", v.fontWeightActive )
    , ( "--n-item-line-height", v.itemLineHeight )
    ]
