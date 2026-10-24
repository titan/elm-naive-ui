module NUI.Layout exposing (Options, Position(..), content, cssVarsFor, defaults, positionClass, view)

{-| Naive UI's `Layout` (and `LayoutContent`), rebuilt on elm-ui.

@docs Options, Position, content, cssVarsFor, defaults, positionClass, view

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
UI's rules declare every load-bearing property, so the result renders the same
— except for width: an elm-ui `el` defaults to `width shrink` (the `wc` class
pins `align-self: flex-start`), which would shrink-wrap the shell inside a
flex parent, so `view` / `content` explicitly set `width fill` (the block-div
`n-layout` fills its mount).

**Divergence (content padding):** upstream's docs demos pass
`content-style="padding: 24px;"` to every `n-layout-content` / sider; callers
that copy those demos verbatim get an unpadded wall of text otherwise. This
port merges a default `padding: 12px 24px` into `content`'s scroll container
(`view` stays untouched) — a caller's own `contentStyle` pairs land later in
the same declaration block and win.

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


{-| The `position` suffix upstream's layout family appends to its modifier
classes (`static` / `absolute`) — shared by `NUI.LayoutHeader` /
`NUI.LayoutFooter` / `NUI.LayoutSider` through their `Position` option.
-}
positionClass : Position -> String
positionClass position =
    case position of
        Static ->
            "static"

        Absolute ->
            "absolute"


{-| The `n-layout` props: positioning, the sider-row flag, the embedded
colour variant, and the scroll container's inline style pairs (`contentStyle`
merges after the template's own pairs — a caller's later pair wins).
-}
type alias Options msg =
    { position : Position
    , hasSider : Bool
    , embedded : Bool
    , nativeScrollbar : Bool
    , contentStyle : List ( String, String )
    , attributes : List (Element.Attribute msg)
    }


{-| A static, scrollable, non-embedded layout with no inline styles — the
plain shell Naive UI's docs demos build on.
-}
defaults : Options msg
defaults =
    { position = Static
    , hasSider = False
    , embedded = False
    , nativeScrollbar = True
    , contentStyle = []
    , attributes = []
    }


{-| The `n-layout` root (no content class) — `width fill` on the elm-ui root
(see the module docs), the scroll container as its only child.
-}
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
        ([ Element.width Element.fill
         , I.classes
            (I.classIf isContent "n-layout-content"
                ++ [ "n-layout"
                   , "n-layout--" ++ positionClass opts.position ++ "-positioned"
                   ]
            )
         , I.cssVars (cssVars theme opts)
         ]
            ++ opts.attributes
        )
        (scrollContainer isContent opts children)


{-| The native scroll container. Upstream also binds `onScroll` here; its
`contentStyle` and the `hasSider` inline styles are merged into one inline
style, later pairs winning, exactly like Vue's style-array merge.

The container also sets `width fill`: upstream's `.n-layout-scroll-container`
is a plain block `div` inside a block `.n-layout`, so it spans the shell; here
the root is an elm-ui column (`display:flex`), where a default `width shrink`
column child pins `align-self: flex-start` and shrink-wraps — which in turn
capped the header / footer `width: 100%` resolution.

-}
scrollContainer : Bool -> Options msg -> List (Element msg) -> Element msg
scrollContainer isContent opts children =
    Element.column
        [ Element.width Element.fill
        , I.classes [ "n-layout-scroll-container" ]
        , I.cssVars (contentPadding isContent ++ opts.contentStyle ++ hasSiderStyle opts.hasSider)
        ]
        children


{-| `content`'s default padding (see the module docstring); `view` renders
without one, matching upstream's bare `n-layout`.
-}
contentPadding : Bool -> List ( String, String )
contentPadding isContent =
    if isContent then
        [ ( "padding", "12px 24px" ) ]

    else
        []


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
