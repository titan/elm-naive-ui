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
`n-drawer-body` **on the scrollbar root** (via its `extraClasses` seam, not a
wrapper) and `contentClass = "n-drawer-body-content-wrapper "` + your
`bodyContentClass` — content nodes are then grandchildren of the scrollbar
content (`NUI.Scrollbar`'s `display: contents` wrapper). Upstream quirk kept
faithful: in the scrollbar branch `bodyClass`/`bodyStyle` are **not** applied
(upstream passes only the static `n-drawer-body` class there), and the
`scrollbarProps` escape hatch is not modelled.

**Close button.** `closable = True` renders the header close button
(`n-base-close n-base-close--absolute n-drawer-header__close`, the
`NUI.Card` inline-close precedent); pass `onClose` for its message (upstream
wires it to `doUpdateShow(false)` unconditionally). `aria-level` is pinned
to `1`, matching upstream's render.

The `*Class`/`*Style` fields are upstream's `headerClass`/`headerStyle`/
`bodyClass`/`bodyStyle`/`bodyContentClass`/`bodyContentStyle`/`footerClass`/
`footerStyle` props (`Nothing` = omitted).

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import Svg


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
view theme opts children =
    Element.column
        [ I.classes
            ("n-drawer-content"
                :: I.classIf opts.nativeScrollbar "n-drawer-content--native-scrollbar"
            )
        , roleAttr "none"
        ]
        (List.filterMap identity
            [ headerNode opts
            , Just (bodyNode theme opts children)
            , footerNode opts
            ]
        )


{-| Upstream renders the header when the header slot, a title or `closable`
exists; the header slot wins over the title inside `__main`.
-}
headerNode : Options msg -> Maybe (Element msg)
headerNode opts =
    if opts.header /= Nothing || opts.title /= Nothing || opts.closable then
        Just
            (Element.row
                ([ I.classes ("n-drawer-header" :: extraClass opts.headerClass)
                 , roleAttr "none"
                 ]
                    ++ rawStyleAttr opts.headerStyle
                )
                (List.filterMap identity
                    [ Just
                        (Element.row
                            [ I.classes [ "n-drawer-header__main" ]
                            , roleAttr "heading"
                            , Element.htmlAttribute (HA.attribute "aria-level" "1")
                            ]
                            [ Maybe.withDefault Element.none (orElse opts.header opts.title) ]
                        )
                    , if opts.closable then
                        Just (closeButton opts.onClose)

                      else
                        Nothing
                    ]
                )
            )

    else
        Nothing


{-| The body: plain divs (native, the default) or `NUI.Scrollbar` carrying
`n-drawer-body` on its root. The default slot lands inside
`.n-drawer-body-content-wrapper` either way.
-}
bodyNode : Theme -> Options msg -> List (Element msg) -> Element msg
bodyNode theme opts children =
    if opts.nativeScrollbar then
        Element.column
            ([ I.classes ("n-drawer-body" :: extraClass opts.bodyClass)
             , roleAttr "none"
             ]
                ++ rawStyleAttr opts.bodyStyle
            )
            [ Element.column
                ([ I.classes ("n-drawer-body-content-wrapper" :: extraClass opts.bodyContentClass)
                 , roleAttr "none"
                 ]
                    ++ rawStyleAttr opts.bodyContentStyle
                )
                children
            ]

    else
        let
            scrollbarBase =
                Scrollbar.defaults
        in
        Scrollbar.view theme
            { scrollbarBase
                | extraClasses = [ "n-drawer-body" ]
                , contentClass =
                    Just
                        (String.join " "
                            ("n-drawer-body-content-wrapper" :: extraClass opts.bodyContentClass)
                        )
                , contentStyle = opts.bodyContentStyle
            }
            children


footerNode : Options msg -> Maybe (Element msg)
footerNode opts =
    Maybe.map
        (\f ->
            Element.row
                ([ I.classes ("n-drawer-footer" :: extraClass opts.footerClass)
                 , roleAttr "none"
                 ]
                    ++ rawStyleAttr opts.footerStyle
                )
                [ f ]
        )
        opts.footer


orElse : Maybe a -> Maybe a -> Maybe a
orElse primary fallback =
    case primary of
        Just _ ->
            primary

        Nothing ->
            fallback


{-| The close button — upstream renders its internal `NBaseClose` (`absolute`
variant) with the drawer's `__close` class. `n-base-close`'s structure CSS is
inline here (the `NUI.Card` precedent); the `--n-*` values it uses resolve
against the `NUI.Drawer` container, where `cssVars` emits them.
-}
closeButton : Maybe msg -> Element msg
closeButton onClose =
    Element.el
        ([ I.classes [ "n-base-close", "n-base-close--absolute", "n-drawer-header__close" ]
         , Element.htmlAttribute (HA.attribute "style" closeStyle)
         , roleAttr "button"
         , Element.htmlAttribute (HA.attribute "aria-label" "close")
         , Element.htmlAttribute (HA.tabindex -1)
         ]
            ++ (case onClose of
                    Just msg ->
                        [ Events.onClick msg ]

                    Nothing ->
                        []
               )
        )
        closeIcon


closeStyle : String
closeStyle =
    String.join ";"
        [ "display:flex"
        , "align-items:center"
        , "justify-content:center"
        , "cursor:pointer"
        , "background-color:transparent"
        , "color:var(--n-close-icon-color)"
        , "border-radius:var(--n-close-border-radius)"
        , "height:var(--n-close-icon-size)"
        , "width:var(--n-close-icon-size)"
        , "font-size:var(--n-close-icon-size)"
        , "outline:none"
        , "border:none"
        , "position:relative"
        , "padding:0"
        ]


{-| `n-base-close--absolute` sizes the button by the icon, not `--n-close-size`.
-}
closeIcon : Element msg
closeIcon =
    Element.el
        [ I.classes [ "n-base-icon" ]
        , Element.htmlAttribute (HA.attribute "style" baseIconStyle)
        ]
        (Element.html <|
            Svg.node "svg"
                [ HA.attribute "viewBox" "0 0 12 12"
                , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
                , HA.attribute "aria-hidden" "true"
                , HA.attribute "style" "height:1em;width:1em"
                ]
                [ Svg.node "path"
                    [ HA.attribute "fill" "currentColor"
                    , HA.attribute "d" closePath
                    ]
                    []
                ]
        )


baseIconStyle : String
baseIconStyle =
    String.join ";"
        [ "height:1em"
        , "width:1em"
        , "line-height:1em"
        , "text-align:center"
        , "display:inline-block"
        , "position:relative"
        , "fill:currentColor"
        ]


{-| Naive UI's `CloseIcon` path (the wrapping `<g>` elements are rendering no-ops).
-}
closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91190884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91190884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,9.95118446 2.34170876,9.95118446 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 Z"


roleAttr : String -> Element.Attribute msg
roleAttr r =
    Element.htmlAttribute (HA.attribute "role" r)


extraClass : Maybe String -> List String
extraClass maybeClass =
    case maybeClass of
        Just c ->
            if String.isEmpty c then
                []

            else
                [ c ]

        Nothing ->
            []


rawStyleAttr : Maybe String -> List (Element.Attribute msg)
rawStyleAttr maybeStyle =
    case maybeStyle of
        Just style ->
            [ Element.htmlAttribute (HA.attribute "style" style) ]

        Nothing ->
            []
