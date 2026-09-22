module NUI.DrawerContent exposing
    ( Options
    , defaults
    , view
    )

{-| Naive UI's `NDrawerContent` (upstream `DrawerContent.tsx`) — the drawer's
composition unit: the header/body/footer content rendered inside the drawer's
content wrapper (`NUI.Drawer`'s slot). Upstream `NDrawer`'s default slot
typically receives exactly this component:

    import NUI.Drawer as Drawer
    import NUI.DrawerContent as DrawerContent
    import NUI.Theme as Theme

    Drawer.view Theme.default
        { Drawer.defaults | show = True }
        [ DrawerContent.view Theme.default
            { DrawerContent.defaults
                | title = Just (Element.text "Title")
                , closable = True
            }
            [ Element.text "Body" ]
        ]

    div.n-drawer-content [--native-scrollbar]
      div.n-drawer-header [headerClass] (role=none)     — iff header/title/closable
        div.n-drawer-header__main role=heading aria-level=1   {header || title}
        div.n-base-close.n-base-close--absolute.n-drawer-header__close — iff closable
      (body — see nativeScrollbar below)
        div.n-drawer-body-content-wrapper [bodyContentClass]   {default slot}
      div.n-drawer-footer [footerClass] (role=none)    — iff footer slot

**Body seam** (`nativeScrollbar`, upstream default **true** — mirrors
`NUI.Drawer`'s own content seam): `True` renders
`div.n-drawer-body > div.n-drawer-body-content-wrapper` (plain divs, no
scrollbar node); `False` embeds `NUI.Scrollbar` with the class
`n-drawer-body` **on the scrollbar root** (not a wrapper) and
`contentClass = "n-drawer-body-content-wrapper "` + your
`bodyContentClass` — content nodes are then grandchildren of the scrollbar
content (`NUI.Scrollbar`'s `display: contents` wrapper).

**Close button.** `closable = True` renders the header close button
(`n-base-close n-base-close--absolute n-drawer-header__close`, the
`NUI.Card` inline-close precedent); pass `onClose` for its message.
`aria-level` is pinned to `1` upstream's render.

The `*Class`/`*Style` fields are upstream's `headerClass`/`headerStyle`/
`bodyClass`/`bodyStyle`/`bodyContentClass`/`bodyContentStyle`/`footerClass`/
`footerStyle` props (`Nothing` = omitted).

-}

import Element exposing (Element)
import NUI.Theme exposing (Theme)


type alias Options msg =
    { title : Maybe (Element msg)
    , header : Maybe (Element msg)
    , footer : Maybe (Element msg)
    , closable : Bool
    , onClose : Maybe msg
    , nativeScrollbar : Bool
    , headerClass : Maybe String
    , headerStyle : Maybe String
    , bodyClass : Maybe String
    , bodyStyle : Maybe String
    , bodyContentClass : Maybe String
    , bodyContentStyle : Maybe String
    , footerClass : Maybe String
    , footerStyle : Maybe String
    }


defaults : Options msg
defaults =
    { title = Nothing
    , header = Nothing
    , footer = Nothing
    , closable = False
    , onClose = Nothing
    , nativeScrollbar = True
    , headerClass = Nothing
    , headerStyle = Nothing
    , bodyClass = Nothing
    , bodyStyle = Nothing
    , bodyContentClass = Nothing
    , bodyContentStyle = Nothing
    , footerClass = Nothing
    , footerStyle = Nothing
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ _ _ =
    Element.none
