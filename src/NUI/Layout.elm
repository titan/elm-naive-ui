module NUI.Layout exposing
    ( Options
    , Position(..)
    , content
    , cssVarsFor
    , defaults
    , positionClass
    , view
    )

{-| Naive UI's `Layout` (and `LayoutContent`), rebuilt on elm-ui.

    import NUI.Layout exposing (defaults)

    NUI.Layout.view theme
        { defaults | hasSider = True }
        [ NUI.LayoutSider.view theme NUI.LayoutSider.defaults [ Element.text "Sider" ]
        , NUI.Layout.content theme defaults [ Element.text "Content" ]
        ]

`view` renders `n-layout`; `content` renders Naive UI's `LayoutContent` — the
exact same component (upstream literally calls `createLayoutComponent True`)
with one extra `n-layout-content` class. The element carries the `.n-layout`
BEM classes and Naive UI's `--n-*` custom properties, and `NUI.Css` ships
Naive UI's exact CSS.

With `hasSider` the scroll container gets Naive UI's inline
`display:flex; flex-wrap:nowrap; width:100%; flex-direction:row` so siders and
content line up in a row.

**Documented gaps** (runtime concerns this pure library leaves to the caller):

  - `scrollTo` — imperative instance method, not modelled.
  - `nativeScrollbar = False` — upstream swaps the scroll container for an
    `NScrollbar`, which is not ported; only the native path is supported and
    `False` currently renders it too.
  - `onScroll` / `scrollbarProps` / `contentClass` — omitted; `contentStyle`
    covers the styling need (extra attributes can go on the children).
  - `siderPlacement` — upstream siders read it from their parent layout; here
    the placement is a direct `NUI.LayoutSider.placement` option.
  - `useReactivated` scroll restore — the caller owns scroll state.

The root is an elm-ui element where upstream uses a plain block `div`; Naive
UI's rules declare every load-bearing property, so the result renders the same.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Layout as LayoutTheme


{-| Naive UI's `position` prop, shared by the whole layout family: `static`
flows in the document, `absolute` pins the element (Naive UI's
`--absolute-positioned` modifier).
-}
type Position
    = Static
    | Absolute


positionClass : Position -> String
positionClass position =
    case position of
        Static ->
            "static"

        Absolute ->
            "absolute"


type alias Options msg =
    { position : Position
    , hasSider : Bool
    , embedded : Bool
    , nativeScrollbar : Bool
    , contentStyle : List ( String, String )
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { position = Static
    , hasSider = False
    , embedded = False
    , nativeScrollbar = True
    , contentStyle = []
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    layoutView False theme opts children


{-| Naive UI's `LayoutContent` (`n-layout-content`): the same component as
`view` with the additional `n-layout-content` class. Naive UI's CSS has no rule
for that class — it is a semantic marker — so `view` and `content` render
identically; emit it anyway for parity with upstream's DOM.
-}
content : Theme -> Options msg -> List (Element msg) -> Element msg
content theme opts children =
    layoutView True theme opts children


layoutView : Bool -> Theme -> Options msg -> List (Element msg) -> Element msg
layoutView isContent theme opts children =
    Element.el
        ([ I.classes
            (I.classIf isContent "n-layout-content"
                ++ [ "n-layout"
                   , "n-layout--" ++ positionClass opts.position ++ "-positioned"
                   ]
            )
         , I.cssVars (cssVars theme opts)
         ]
            ++ opts.attributes
        )
        (scrollContainer opts children)


{-| The native scroll container. Upstream also binds `onScroll` here; its
`contentStyle` and the `hasSider` inline styles are merged into one inline
style, later pairs winning, exactly like Vue's style-array merge.
-}
scrollContainer : Options msg -> List (Element msg) -> Element msg
scrollContainer opts children =
    Element.column
        [ I.classes [ "n-layout-scroll-container" ]
        , I.cssVars (opts.contentStyle ++ hasSiderStyle opts.hasSider)
        ]
        children


{-| Naive UI's `hasSiderStyle`, applied inline to the scroll container.
-}
hasSiderStyle : Bool -> List ( String, String )
hasSiderStyle hasSider =
    if hasSider then
        [ ( "display", "flex" )
        , ( "flex-wrap", "nowrap" )
        , ( "width", "100%" )
        , ( "flex-direction", "row" )
        ]

    else
        []


{-| The raw `--n-*` custom properties a layout with these options attaches.
Exposed so the `--n-*` output can be asserted directly; `view` and `content`
use exactly this.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    cssVars theme opts


cssVars : Theme -> Options msg -> List ( String, String )
cssVars theme opts =
    let
        v =
            LayoutTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-color"
      , if opts.embedded then
            v.colorEmbedded

        else
            v.color
      )
    , ( "--n-text-color", v.textColor )
    ]
