module NUI.Drawer exposing
    ( Options
    , Placement(..)
    , ShowMask(..)
    , cssVars
    , defaults
    , placementName
    , view
    )

{-| Naive UI's `Drawer` — the mount-body **sibling** of `NUI.Modal`: like Modal
it renders its own fixed full-viewport tree (no trigger/follower), but the
body is **edge-anchored** (`.n-drawer` is `position: absolute` pinned to a
side by `placement`, sized on the placement's axis) instead of flex-centred.
Upstream `Drawer.tsx` orchestrates `DrawerBodyWrapper.tsx` (the component
named `NDrawerContent` in its `name` field — the body wrapper) whose default
slot receives `DrawerContent.tsx` (the inner header/body/footer unit):

    div.n-drawer-container (role=none, the 25 css vars [+ z-index])
      div.n-drawer-mask (aria-hidden) [--invisible]      — iff showMask ≠ Hidden
      div role=none (unclassed host)                      — the body gate
        div.n-drawer [--rtl --{p}-placement] role=dialog aria-modal
          div.n-drawer__resize-trigger [--hover]          — iff resizable
          (content wrapper — see nativeScrollbar below)
            the caller's content (usually `NUI.DrawerContent`)

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
            [ Element.text "Content" ]
        ]

**Everything runtime is caller-owned** (the popover-family precedent, applied
to the mount-body family — upstream provides the `*BodyInjectionKey`s, it
consumes nothing):

  - **Mounting and `show`.** The caller decides where the tree lives and owns
    the show state (`displayDirective: 'if'` semantics only). `show = False`
    with no leave phase renders a bare container — unmount the view when fully
    closed; the keep-mounted `display: none` variant is not modelled
    (caller `attributes` can carry it).
  - **Transitions.** The mask (`fade-in-transition`) and the body
    (`slide-in-from-{placement}-transition`, derived from `placement`) run on
    the same clock the caller drives: pass the phase through
    `maskTransition`/`bodyTransition` and keep the view mounted while either
    is a leave phase (`I.isLeavePhase`). The mask/body nodes render only while
    `show || isLeavePhase …`. Upstream timings: mask `.2s`; body enter `.3s`,
    leave `.2s` (fixed beziers, not the `--n-bezier-*` vars — unlike the
    mask, which reads `--n-bezier-in/out`). The body phase class is forced
    **last** on `.n-drawer`'s class list (the house invariant).
  - **Mask clicks ARE interactive** (the divergence from `NUI.Modal`, whose
    fixed body-wrapper overlays an inert mask): upstream's mask carries
    `onClick=handleMaskClick` (`Drawer.tsx` — `.n-drawer` is out of flow, so
    the zero-height body host does not cover it). Pass `onMaskClick` for the
    primary close surface; `maskClosable` reduces to "pass your close msg".
    Esc (`closeOnEsc`), focus trap, `blockScroll` and the `clickoutside`
    (only when the mask is hidden) stay caller runtime.
  - **Resizable drag.** The trigger node (`resizable = True`) and its
    `--hover` modifier (`showResizeTriggerHover`) are DOM; the drag itself
    (global mousemove/mouseup, min/max clamping, `--unselectable` while
    dragging) is caller runtime — set `unselectable` while your drag is
    active to reproduce upstream.
  - **z-index.** No `zindexable` auto-increment: pass `zIndex` (rendered as
    `z-index` appended after the vars).

**`showMask`** is upstream's `boolean | 'transparent'`: `Visible` (the
default) renders the mask, `Transparent` renders it with
`n-drawer-mask--invisible`, `Hidden` omits the node entirely.

**`nativeScrollbar`** (upstream default **true**) selects the content seam:
`True` renders a plain `div.n-drawer-content-wrapper` (no scrollbar node —
unlike `NUI.Modal`, the default tree embeds no `NUI.Scrollbar`); `False`
embeds `NUI.Scrollbar` with `contentClass = "n-drawer-content-wrapper "` +
your `contentClass`. **Sizing**: `width` (left/right) / `height`
(top/bottom) resolve per axis with the `defaultWidth`/`defaultHeight`
fallback (upstream `251`), emitted as the single inline `style` on
`.n-drawer` (exact upstream pin: `width: 600px;`).

`NUI.DrawerContent` is the composition unit (upstream `NDrawerContent`) — see
its module. Upstream has no `preset` prop (Modal's `Preset` has no analog
here): the slot is the third `view` argument.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Drawer as DrawerTheme


{-| The drawer's side. Upstream `placement` (default `right`).
-}
type Placement
    = Left
    | Right
    | Top
    | Bottom


{-| The block name fragment for a placement (`"right"` for `Right`) — also the
body transition family infix (`slide-in-from-right-transition`).
-}
placementName : Placement -> String
placementName placement =
    case placement of
        Left ->
            "left"

        Right ->
            "right"

        Top ->
            "top"

        Bottom ->
            "bottom"


{-| Upstream `showMask : boolean | 'transparent'` — `Hidden` renders no mask
node, `Transparent` adds `n-drawer-mask--invisible`.
-}
type ShowMask
    = Visible
    | Transparent
    | Hidden


type alias Options msg =
    { show : Bool
    , placement : Placement
    , showMask : ShowMask
    , width : Maybe String
    , height : Maybe String
    , defaultWidth : String
    , defaultHeight : String
    , nativeScrollbar : Bool
    , resizable : Bool
    , showResizeTriggerHover : Bool
    , unselectable : Bool
    , rtl : Bool
    , contentClass : Maybe String
    , contentStyle : Maybe String
    , zIndex : Maybe Int
    , maskTransition : Maybe I.TransitionPhase
    , bodyTransition : Maybe I.TransitionPhase
    , onMaskClick : Maybe msg
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { show = False
    , placement = Right
    , showMask = Visible
    , width = Nothing
    , height = Nothing
    , defaultWidth = "251px"
    , defaultHeight = "251px"
    , nativeScrollbar = True
    , resizable = False
    , showResizeTriggerHover = False
    , unselectable = False
    , rtl = False
    , contentClass = Nothing
    , contentStyle = Nothing
    , zIndex = Nothing
    , maskTransition = Nothing
    , bodyTransition = Nothing
    , onMaskClick = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ _ _ =
    Element.none


{-| Naive UI's `cssVarsRef` — the container's 25 custom properties, in
upstream declaration order (the cssr header comment omits
`--n-resize-trigger-color-hover`; trust `cssVarsRef`).
-}
cssVars : Theme -> List ( String, String )
cssVars _ =
    []
