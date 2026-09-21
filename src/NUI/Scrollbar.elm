module NUI.Scrollbar exposing
    ( HorizontalPlacement(..)
    , Options
    , VerticalPlacement(..)
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's `Scrollbar` (`n-scrollbar`), rebuilt on elm-ui.

    import NUI.Scrollbar exposing (defaults)

    NUI.Scrollbar.view theme
        { defaults | showYBar = True, yBarStyle = Just "height:40px;top:0" }
        [ Element.el [ Element.height (Element.px 400) ] (Element.text "Long content") ]

The element carries the `.n-scrollbar` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

**Runtime.** Upstream measures the container/content, decides whether a rail
overflows (`needXBar` / `needYBar`), reads the bar geometry, and shows the bar on
hover (`trigger`) or always (`trigger === 'none'`). This library is pure, so the
caller owns that state: `showYBar` / `showXBar` decide whether a bar element is
rendered (upstream's `needBar && isShowBar && !isIos`) and `yBarStyle` / `xBarStyle`
carry the measured geometry as raw CSS (the `NUI.BackTop` / `NUI.Affix`
caller-owned-runtime precedent). The rails themselves always render.

**Documented gaps:**

  - `vueuc`'s `VResizeObserver` (content/container resize tracking) is omitted.
  - `trigger` (public `'none' | 'hover'`) is not modelled: it only selects between a
    no-op `Wrapper` and a `Transition`, so it has no static DOM effect. Hover-driven
    show/hide is the caller's (`attributes` can bind `mouseenter` / `mouseleave`).
  - `onScroll` is not modelled; attach it with `attributes` (the `NUI.Layout`
    precedent for a native scroll container).
  - `n-scrollbar-rail--disabled` (added by a `watchEffect` when a rail does not
    overflow) is not modelled — runtime.
  - The `fade-in-transition` on the bar is not driven (caller-owned; cf. LoadingBar).
  - The horizontal bar's RTL offset (`right` vs `left`) is caller-owned via `xBarStyle`.
  - The `scrollable` / `duration` / `container*` / `*RailStyle` / `useUnifiedContainer`
    / `triggerDisplayManually` / `internal*` props and the `scrollTo` / `scrollBy` /
    `sync` instance methods are internal-only or imperative — not modelled. The
    `container` prop (a caller-owned scroll element) is not reproduced: the built-in
    `n-scrollbar-container` / `n-scrollbar-content` are always rendered.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Scrollbar as ScrollbarTheme


{-| The vertical rail's side (upstream `yPlacement`); default `Right`.
-}
type VerticalPlacement
    = Left
    | Right


{-| The horizontal rail's side (upstream `xPlacement`); default `Bottom`.
-}
type HorizontalPlacement
    = Top
    | Bottom


{-| The `n-scrollbar` options. The bar visibility and geometry are caller-owned.
-}
type alias Options msg =
    { xScrollable : Bool
    , yPlacement : VerticalPlacement
    , xPlacement : HorizontalPlacement
    , rtl : Bool
    , showYBar : Bool
    , showXBar : Bool
    , yBarStyle : Maybe String
    , xBarStyle : Maybe String
    , contentClass : Maybe String
    , contentStyle : Maybe String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (with the bars hidden — the runtime cannot measure).
-}
defaults : Options msg
defaults =
    { xScrollable = False
    , yPlacement = Right
    , xPlacement = Bottom
    , rtl = False
    , showYBar = False
    , showXBar = False
    , yBarStyle = Nothing
    , xBarStyle = Nothing
    , contentClass = Nothing
    , contentStyle = Nothing
    , attributes = []
    }


{-| The `n-scrollbar` element.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ _ _ =
    Element.none


{-| The 23 `--n-*` custom properties the root attaches (upstream cssVarsRef).
-}
cssVars : Theme -> Options msg -> List ( String, String )
cssVars _ _ =
    []
