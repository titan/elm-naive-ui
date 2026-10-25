module NUI.Drawer exposing (Options, Placement(..), ShowMask(..), cssVars, defaults, placementName, view)

{-| Naive UI's `Drawer` — the mount-body **sibling** of `NUI.Modal`: like Modal
it renders its own fixed full-viewport tree (no trigger/follower), but the
body is **edge-anchored** (`.n-drawer` is `position: absolute` pinned to a
side by `placement`, sized on the placement's axis) instead of flex-centred.

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

Essential contract: everything runtime is caller-owned — mounting and
`show` (`displayDirective: 'if'` semantics; unmount when fully closed), the
mask / body transitions (phases via `maskTransition` / `bodyTransition`,
mounted through leave phases; body phase class forced last), `onMaskClick`
as the primary close surface (the mask IS interactive, unlike `NUI.Modal`),
resizable drag state and `zIndex`. `showMask` is `Visible | Transparent |
Hidden`; `nativeScrollbar` (default true) picks a plain content wrapper (no
scrollbar node) or an embedded `NUI.Scrollbar`; `width` / `height` resolve
per axis with the `251` fallback onto `.n-drawer`'s single inline style.
`NUI.DrawerContent` is the composition unit for the inner
header/body/footer.

DOM shapes, fidelity notes and porting details live in the comment block
below the module doc.

@docs Options, Placement, ShowMask, cssVars, defaults, placementName, view

-}

{- DOM shapes, fidelity notes and porting details for `NUI.Drawer` — moved verbatim
      out of the module docstring (docs.json must stay under elm publish's 768kb
      limit); plain comments do not enter the published API docs.

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
   `.n-drawer` (exact upstream pin: `width: 600px;`). Upstream's deprecated
   `drawerStyle`/`drawerClass` and the `scrollbarProps` escape hatch are not
   modelled; `attributes` is the container passthrough (the `NUI.Modal` house
   rule — upstream's `$attrs` land on `.n-drawer` instead).

   `NUI.DrawerContent` is the composition unit (upstream `NDrawerContent`) — see
   its module. Upstream has no `preset` prop (Modal's `Preset` has no analog
   here): the slot is the third `view` argument.
-}

import Element exposing (Element)
import Element.Events as Events
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Scrollbar as Scrollbar
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


{-| Upstream `n-drawer`'s props: the show gate, the edge `placement`, the mask
mode, per-axis sizing with the `251px` fallbacks, the scrollbar and resize
seams, the caller-driven transition phases, `onMaskClick`, and the container
`attributes` passthrough. Everything runtime (see the module docstring) is
yours.
-}
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


{-| Upstream defaults: closed, `right` placement, a visible mask, no explicit
size (`251px` fallbacks), native scrollbar, not resizable / selectable / rtl,
no z-index, phases or callbacks.
-}
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


{-| The full fixed-viewport tree per the module docstring: container (vars +
caller `attributes`) → mask (interactive, phase-driven) → body host → the
edge-anchored `.n-drawer` (placement class, transition class last, sizing
style, resize trigger, content wrapper or scrollbar) around your children.
Pass your `NUI.DrawerContent` (or anything) as the slot.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        scrollbarBase =
            Scrollbar.defaults
    in
    Element.row
        ([ I.classes [ "n-drawer-container" ]
         , I.cssVars (cssVars theme ++ zIndexVar opts.zIndex)
         , roleAttr "none"
         ]
            ++ opts.attributes
        )
        (List.filterMap identity
            [ maskNode opts
            , bodyNode theme opts scrollbarBase children
            ]
        )


{-| The mask — upstream renders it (inside the fade transition) only while
`show`, and its div carries `onClick=handleMaskClick` (the primary close
surface; `maskClosable` default true means "pass your close msg").
-}
maskNode : Options msg -> Maybe (Element msg)
maskNode opts =
    if showMaskOn opts.showMask && (opts.show || leaving opts.maskTransition) then
        Just
            (Element.el
                ([ I.classes
                    ("n-drawer-mask"
                        :: I.classIf (opts.showMask == Transparent) "n-drawer-mask--invisible"
                        ++ phaseClasses "fade-in-transition" opts.maskTransition
                    )
                 , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
                 ]
                    ++ (case opts.onMaskClick of
                            Just msg ->
                                [ Events.onClick msg ]

                            Nothing ->
                                []
                       )
                )
                Element.none
            )

    else
        Nothing


{-| Upstream's truthy check: `showMask ? … : null` — only `Hidden`
(`showMask = false`) removes the mask node.
-}
showMaskOn : ShowMask -> Bool
showMaskOn mask =
    mask /= Hidden


{-| The unclassed `div role="none"` host (upstream keeps it so the drawer has
a stable anchor) wrapping the whole body tree — the outer render gate.

It fills the container: upstream's host is a plain block div inside the
inset-0 `.n-drawer-container` and the absolute `.n-drawer` (`left: 0; right:
0` / `top: 0; bottom: 0` per placement) anchors through it at the container's
full size. The port's elm-ui host carries `position: relative` (the `.s`
class), making IT the containing block — at content width it collapses to
zero and takes the edge-anchored panel with it (top/bottom placements render
a zero-width panel). `width/height fill` restores the upstream geometry.

-}
bodyNode : Theme -> Options msg -> Scrollbar.Options msg -> List (Element msg) -> Maybe (Element msg)
bodyNode theme opts scrollbarBase children =
    if opts.show || leaving opts.bodyTransition then
        Just
            (Element.el
                [ roleAttr "none"

                -- Exactly-sized positioned node: `.n-drawer`'s edge offsets
                -- must resolve against a box the size of the container (the
                -- elm-ui `.s` class already sets position:relative; the
                -- explicit inline declaration keeps it robust if the bridge
                -- ever drops that class).
                , Element.htmlAttribute (HA.attribute "style" "position:relative")
                , Element.width Element.fill
                , Element.height Element.fill
                ]
                (drawerNode theme opts scrollbarBase children)
            )

    else
        Nothing


{-| `.n-drawer` itself: edge-anchored, sized on the placement's axis; the
body transition family is derived from `placement` and its phase class is
forced LAST in the class list (the house invariant).
-}
drawerNode : Theme -> Options msg -> Scrollbar.Options msg -> List (Element msg) -> Element msg
drawerNode theme opts scrollbarBase children =
    Element.column
        ([ I.classes
            ([ "n-drawer"
             ]
                ++ I.classIf opts.rtl "n-drawer--rtl"
                ++ [ "n-drawer--" ++ placementName opts.placement ++ "-placement" ]
                ++ I.classIf opts.unselectable "n-drawer--unselectable"
                ++ I.classIf opts.nativeScrollbar "n-drawer--native-scrollbar"
                ++ phaseClasses (bodyTransitionFamily opts.placement) opts.bodyTransition
            )
         , roleAttr "dialog"
         , Element.htmlAttribute (HA.attribute "aria-modal" "true")
         ]
            ++ sizeStyle opts
        )
        (List.filterMap identity
            [ resizeTriggerNode opts
            , Just (contentWrapper theme opts scrollbarBase children)
            ]
        )


bodyTransitionFamily : Placement -> String
bodyTransitionFamily placement =
    "slide-in-from-" ++ placementName placement ++ "-transition"


{-| Upstream's `resize-trigger` — static DOM; the drag (and its hover-delay
runtime) is caller-owned. `--hover` appears while dragging or hovering.
-}
resizeTriggerNode : Options msg -> Maybe (Element msg)
resizeTriggerNode opts =
    if opts.resizable then
        Just
            (Element.el
                [ I.classes
                    ("n-drawer__resize-trigger"
                        :: I.classIf opts.showResizeTriggerHover "n-drawer__resize-trigger--hover"
                    )
                ]
                Element.none
            )

    else
        Nothing


{-| The content seam: a plain wrapper div (native, the default — no scrollbar
node, unlike `NUI.Modal`) or `NUI.Scrollbar` carrying the wrapper class on its
content. Upstream string-concats `"n-drawer-content-wrapper " + contentClass`.

The native wrapper's inline style prepends `min-height: 0`: elm-ui column
children carry `min-height: min-content`, which would stop the wrapper from
shrinking to the panel's (height-constrained) size and push the footer past
the panel edge over the mask. The CSS pair
`.n-drawer.n-drawer--native-scrollbar .n-drawer-content-wrapper`
(`height: 100%` + `overflow: auto`) does the rest — upstream's plain divs have
no min-height to fight (the port's bridge restores only `flex-basis`).

-}
contentWrapper : Theme -> Options msg -> Scrollbar.Options msg -> List (Element msg) -> Element msg
contentWrapper theme opts scrollbarBase children =
    if opts.nativeScrollbar then
        Element.column
            [ I.classes ("n-drawer-content-wrapper" :: extraClass opts.contentClass)
            , roleAttr "none"
            , Element.htmlAttribute (HA.attribute "style" (mergedStyle opts.contentStyle))
            ]
            children

    else
        Scrollbar.view theme
            { scrollbarBase
                | contentClass =
                    Just
                        (String.join " "
                            ("n-drawer-content-wrapper" :: extraClass opts.contentClass)
                        )
                , contentStyle = opts.contentStyle
            }
            children


{-| The port's `min-height: 0` + the caller's style fragment verbatim after it
(one `style` attribute; the caller's declarations win, the spread convention).
-}
mergedStyle : Maybe String -> String
mergedStyle maybeStyle =
    case maybeStyle of
        Just style ->
            if String.isEmpty style then
                "min-height:0"

            else
                "min-height:0;" ++ style

        Nothing ->
            "min-height:0"


{-| Upstream's axis selection: left/right size `width`, top/bottom `height`
(the other axis is dropped from the merged style — the exact upstream pin is
a single-axis `style="width: 600px;"`), with the `251px`-style defaults as
the fallback (`width ?? defaultWidth`).
-}
sizeStyle : Options msg -> List (Element.Attribute msg)
sizeStyle opts =
    let
        axis =
            case opts.placement of
                Left ->
                    ( "width", Maybe.withDefault opts.defaultWidth opts.width )

                Right ->
                    ( "width", Maybe.withDefault opts.defaultWidth opts.width )

                Top ->
                    ( "height", Maybe.withDefault opts.defaultHeight opts.height )

                Bottom ->
                    ( "height", Maybe.withDefault opts.defaultHeight opts.height )
    in
    styleAttr [ axis ]


phaseClasses : String -> Maybe I.TransitionPhase -> List String
phaseClasses family phase =
    case phase of
        Just p ->
            [ I.transitionClass family p ]

        Nothing ->
            []


leaving : Maybe I.TransitionPhase -> Bool
leaving phase =
    case phase of
        Just p ->
            I.isLeavePhase p

        Nothing ->
            False


zIndexVar : Maybe Int -> List ( String, String )
zIndexVar z =
    case z of
        Just n ->
            [ ( "z-index", String.fromInt n ) ]

        Nothing ->
            []


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


{-| A `( key, value )` list as the single inline `style` attribute (merging
several `HA.style` attributes would drop all but the first — the
`NUI.Card` `styleAttr` precedent).
-}
styleAttr : List ( String, String ) -> List (Element.Attribute msg)
styleAttr pairs =
    if List.isEmpty pairs then
        []

    else
        [ Element.htmlAttribute
            (HA.attribute
                "style"
                (String.join ";" (List.map (\( k, val ) -> k ++ ":" ++ val) pairs))
            )
        ]


{-| Naive UI's `cssVarsRef` — the container's 25 custom properties, in
upstream declaration order (the cssr header comment omits
`--n-resize-trigger-color-hover`; trust `cssVarsRef`).
-}
cssVars : Theme -> List ( String, String )
cssVars theme =
    let
        v =
            DrawerTheme.vars theme

        common =
            theme.common
    in
    [ ( "--n-line-height", v.lineHeight )
    , ( "--n-color", v.color )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-text-color", v.textColor )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-bezier", common.cubicBezierEaseInOut )
    , ( "--n-bezier-out", common.cubicBezierEaseOut )
    , ( "--n-bezier-in", common.cubicBezierEaseIn )
    , ( "--n-header-padding", v.headerPadding )
    , ( "--n-body-padding", v.bodyPadding )
    , ( "--n-footer-padding", v.footerPadding )
    , ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-title-font-size", v.titleFontSize )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-header-border-bottom", v.headerBorderBottom )
    , ( "--n-footer-border-top", v.footerBorderTop )
    , ( "--n-close-icon-color", v.closeIconColor )
    , ( "--n-close-icon-color-hover", v.closeIconColorHover )
    , ( "--n-close-icon-color-pressed", v.closeIconColorPressed )
    , ( "--n-close-size", v.closeSize )
    , ( "--n-close-color-hover", v.closeColorHover )
    , ( "--n-close-color-pressed", v.closeColorPressed )
    , ( "--n-close-icon-size", v.closeIconSize )
    , ( "--n-close-border-radius", v.closeBorderRadius )
    , ( "--n-resize-trigger-color-hover", v.resizableTriggerColorHover )
    ]
