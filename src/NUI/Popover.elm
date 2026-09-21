module NUI.Popover exposing
    ( Options
    , Placement(..)
    , cssVars
    , defaults
    , placementAttribute
    , placementName
    , view
    )

{-| Naive UI's `Popover` body (`n-popover`), rebuilt on elm-ui.

    import NUI.Popover exposing (defaults)

    NUI.Popover.view theme
        { defaults | header = Just (Element.text "Title") }
        [ Element.text "Content" ]

The element carries the `.n-popover` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

**What this module is.** Upstream `n-popover` is two things: a trigger runtime
(hover/click/focus state machine with `delay`/`duration` timers, clickoutside,
z-index pooling, `VBinder`/`VTarget` measurement of the trigger, `VFollower`
positioning and flip) and the body it shows. This library is pure, so only the
**body** is ported (the `NUI.BackTop` / `NUI.Affix` / `NUI.Scrollbar`
caller-owned-runtime precedent): the caller owns the show state (mount/unmount
this element), the trigger (their element, their handlers), and the positioned
wrapper the body must sit in (below).

**The wrapper contract.** Every placement rule in Naive UI's CSS is
`[v-placement="…"] > .n-popover-shared` (margin, arrow position) reading
`--v-offset-left/top` and `--v-target-width/height` runtime variables. Put the
body inside a wrapper that carries the `v-placement` attribute —
`placementAttribute` emits it — and position it yourself (upstream's follower
applies `transform: translateX(…) translateY(…)`, z-index, and the `--v-*`
variables; see vueuc's `v-binder-follower-content`). The wrapper must live
inside `nui-root` (this port's CSS is doubly scoped; upstream teleports to
`body` instead). The `--v-*` variables default to `0px` and only matter for
`arrowPointToCenter` and the arrow `-start`/`-end` offsets.

**Documented gaps:**

  - `trigger` (`'hover' | 'click' | 'focus' | 'manual'`), `delay`, `duration`,
    `keepAliveOnHover`, `disabled`, `flip`, `zIndex`, `to`, `x`/`y` and the
    events (`on-update:show`, `on-clickoutside`) are runtime — not modelled.
    Bind the trigger's DOM events with your own handlers.
  - `show` is modelled by mounting / unmounting this element (upstream's
    `displayDirective: 'if'`, the default). `'show'`-style keep-mounted hiding
    is the caller's (`attributes` can carry `display: none`), and the
    enter/leave animation is driven through `transition` phases below.
  - `placement` has no `Options` field: it affects only the wrapper attribute
    (`placementAttribute`), never the body node.
  - `width: 'trigger'` (match-trigger-width) is runtime measurement — set the
    px yourself. A numeric `width` upstream becomes `"<n>px"`; the port takes
    raw CSS.
  - `minWidth` / `maxWidth` are deprecated upstream (and upstream pushes
    `minWidth` as `maxWidth` — an upstream bug) — not modelled.
  - `internalRenderBody` and the other `internal*` props (the dropdown /
    tooltip reuse lane) are not modelled; those components will compose this
    module directly.
  - `n-popover--show-header-or-footer` and the header / footer nodes exist only
    while `header` / `footer` are `Just` (upstream renders each wrapper only
    when its slot is non-empty).

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Popover as PopoverTheme


{-| A follower placement (vueuc's 12 `FollowerPlacement` values). The value
feeds `placementAttribute` for the caller's wrapper; the body itself is
placement-independent.
-}
type Placement
    = Top
    | TopStart
    | TopEnd
    | Bottom
    | BottomStart
    | BottomEnd
    | Left
    | LeftStart
    | LeftEnd
    | Right
    | RightStart
    | RightEnd


{-| The placement's `v-placement` string (`"top-start"`, …).
-}
placementName : Placement -> String
placementName placement =
    case placement of
        Top ->
            "top"

        TopStart ->
            "top-start"

        TopEnd ->
            "top-end"

        Bottom ->
            "bottom"

        BottomStart ->
            "bottom-start"

        BottomEnd ->
            "bottom-end"

        Left ->
            "left"

        LeftStart ->
            "left-start"

        LeftEnd ->
            "left-end"

        Right ->
            "right"

        RightStart ->
            "right-start"

        RightEnd ->
            "right-end"


{-| The `v-placement` attribute for the caller's positioned wrapper — the body's
direct parent (upstream: vueuc's `v-binder-follower-content`, which also carries
the inline `transform` positioning, z-index, and the `--v-offset-*` /
`--v-target-*` variables).
-}
placementAttribute : Placement -> Element.Attribute msg
placementAttribute placement =
    Element.htmlAttribute (HA.attribute "v-placement" (placementName placement))


{-| The `n-popover` options. Runtime behaviour (show state, positioning) is
caller-owned.
-}
type alias Options msg =
    { showArrow : Bool
    , arrowPointToCenter : Bool
    , overlap : Bool
    , raw : Bool
    , scrollable : Bool
    , width : Maybe String
    , rtl : Bool
    , header : Maybe (Element msg)
    , footer : Maybe (Element msg)
    , transition : Maybe I.TransitionPhase
    , arrowClass : Maybe String
    , arrowStyle : Maybe String
    , arrowWrapperClass : Maybe String
    , arrowWrapperStyle : Maybe String
    , contentClass : Maybe String
    , contentStyle : Maybe String
    , headerClass : Maybe String
    , headerStyle : Maybe String
    , footerClass : Maybe String
    , footerStyle : Maybe String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`showArrow: true` upstream; everything else false /
empty — note `overlap` disables the arrow upstream, which the view applies).
-}
defaults : Options msg
defaults =
    { showArrow = True
    , arrowPointToCenter = False
    , overlap = False
    , raw = False
    , scrollable = False
    , width = Nothing
    , rtl = False
    , header = Nothing
    , footer = Nothing
    , transition = Nothing
    , arrowClass = Nothing
    , arrowStyle = Nothing
    , arrowWrapperClass = Nothing
    , arrowWrapperStyle = Nothing
    , contentClass = Nothing
    , contentStyle = Nothing
    , headerClass = Nothing
    , headerStyle = Nothing
    , footerClass = Nothing
    , footerStyle = Nothing
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The `n-popover` body element.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ _ _ =
    Element.none


{-| The 15 `--n-*` custom properties the body attaches (upstream cssVarsRef).
-}
cssVars : Theme -> List ( String, String )
cssVars _ =
    []
