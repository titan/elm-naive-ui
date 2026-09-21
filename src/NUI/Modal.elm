module NUI.Modal exposing
    ( Options
    , Preset(..)
    , cardDefaults
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's `Modal` — the mount-body family: unlike `NUI.Popover`/
`NUI.Dropdown` (a follower anchored to a trigger), Modal renders its own fixed
full-viewport tree and centres the content with flex (`align-self: center;
margin: auto` inside the scroll content). Upstream `Modal.tsx` is orchestration
around `BodyWrapper.tsx` (the `ModalBody` component):

    div.n-modal-container (role=none, the 4 css vars [+ z-index])
      div.n-modal-mask (aria-hidden)                       — iff showMask
      div.n-modal-body-wrapper [--mask-hidden] (role=none)
        NUI.Scrollbar (contentClass n-modal-scroll-content)
          the content root, always classed `n-modal`

    import NUI.Modal as Modal
    import NUI.Theme as Theme

    Modal.view Theme.default
        Modal.defaults
        (Modal.Custom []
            [ Element.text "Content" ])

    -- the card preset: upstream spreads dialog props last, so the card is
    -- UNBORDERED by default — start from Modal.cardDefaults
    Modal.view Theme.default
        { Modal.defaults | show = True }
        (Modal.Card
            { Modal.cardDefaults
                | title = Just (Element.text "Title")
                , closable = True
            }
            [ Element.text "Card content" ])

**Everything runtime is caller-owned** (the popover family precedent, applied
to the inverse architecture — upstream provides
`popoverBodyInjectionKey = null`, it consumes nothing):

  - **Mounting and `show`.** The caller decides where the tree lives (upstream
    teleports to `to`; mount `view` wherever you want it) and owns the show
    state. `show = False` with no leave phase renders a bare container —
    unmount the view when fully closed (`displayDirective: 'if'` semantics;
    the keep-mounted `display: none` variant is not modelled).
  - **Transitions.** Both the mask (`fade-in-transition`) and the content
    (`fade-in-scale-up-transition`, enter scale `.5`) run `.25s` on the same
    clock: pass the phase through `maskTransition`/`bodyTransition` and keep
    the view mounted while either is a leave phase (`I.isLeavePhase`). The
    mask node and the body-wrapper tree are only rendered while
    `show || isLeavePhase …`.
  - **Outside-click closing.** Upstream's mask never receives clicks (the
    fixed body-wrapper overlays it; `maskClosable` closes via the
    `clickoutside` directive on the content node). The port's mask is inert
    and `aria-hidden`; wire your own outside-click handling.
  - **Keyboard.** `closeOnEsc`/`onEsc`, `trapFocus`/`autoFocus` (VFocusTrap
    tab cycling) are caller runtime.
  - **`blockScroll`.** Upstream locks `document.body`; not reachable from a
    pure view.
  - **Drag and mouse `transformOrigin`.** Global mousemove/mousedown runtime
    (upstream `useDragModal` + the modal provider's mouse tracking); the port
    is effectively `transformOrigin: 'center'`. The `.n-modal .n-draggable`
    CSS rule ships unused.
  - **z-index.** No `zindexable` auto-increment: pass `zIndex` and allocate
    stacking yourself (rendered as `z-index` appended after the vars).

**Presets.** `Custom` wraps your content in a port-owned `div.n-modal`
(upstream clones the caller's root vnode and merges the class onto it — Elm
elements cannot be cloned; the extra wrapper is visually identical because the
`.n-modal` rules land on it). `Card` composes `NUI.Card.view` with the
`n-modal` class, `role="dialog"` and `aria-modal="true"` merged onto the card
root (via Card's `extraClasses`/`attributes` seams) — start from
`cardDefaults`: upstream spreads `{...cardBaseProps, ...dialogProps}` so the
card is unbordered by default inside a modal. `dialog`/`confirm` presets are
**deferred** until `NUI.Dialog` exists (their own ~30-var theme, icon/type
system and action buttons); the `Preset` type grows constructors then.

`showMask = False` adds `n-modal-body-wrapper--mask-hidden` (pointer-events
pass-through except the content) exactly as upstream's `maskHidden = !showMask`.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Card
import NUI.Internal as I
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.Modal as ModalTheme


{-| The modal's content preset: `Custom` (no upstream preset) or `Card`
(upstream `preset: 'card'`).
-}
type Preset msg
    = Custom (List (Element.Attribute msg)) (List (Element msg))
    | Card (NUI.Card.Options msg) (List (Element msg))


type alias Options msg =
    { show : Bool
    , showMask : Bool
    , zIndex : Maybe Int
    , maskTransition : Maybe I.TransitionPhase
    , bodyTransition : Maybe I.TransitionPhase
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { show = False
    , showMask = True
    , zIndex = Nothing
    , maskTransition = Nothing
    , bodyTransition = Nothing
    , attributes = []
    }


{-| Upstream's card preset is unbordered by default
(`{...cardBaseProps, ...dialogProps}` — the dialog spread wins).
-}
cardDefaults : NUI.Card.Options msg
cardDefaults =
    let
        base =
            NUI.Card.defaults
    in
    { base | bordered = False }


view : Theme -> Options msg -> Preset msg -> Element msg
view theme opts preset =
    let
        scrollbarBase =
            Scrollbar.defaults
    in
    Element.row
        ([ I.classes [ "n-modal-container" ]
         , I.cssVars (cssVars theme ++ zIndexVar opts.zIndex)
         , roleAttr "none"
         ]
            ++ opts.attributes
        )
        (List.filterMap identity
            [ maskNode opts
            , bodyNode theme opts scrollbarBase preset
            ]
        )


maskNode : Options msg -> Maybe (Element msg)
maskNode opts =
    if opts.showMask && (opts.show || leaving opts.maskTransition) then
        Just
            (Element.el
                [ I.classes ("n-modal-mask" :: phaseClasses "fade-in-transition" opts.maskTransition)
                , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
                ]
                Element.none
            )

    else
        Nothing


bodyNode : Theme -> Options msg -> Scrollbar.Options msg -> Preset msg -> Maybe (Element msg)
bodyNode theme opts scrollbarBase preset =
    if opts.show || leaving opts.bodyTransition then
        Just
            (Element.el
                [ I.classes
                    ([ "n-modal-body-wrapper" ]
                        ++ I.classIf (not opts.showMask) "n-modal-body-wrapper--mask-hidden"
                    )
                , roleAttr "none"
                ]
                (Scrollbar.view theme
                    { scrollbarBase | contentClass = Just "n-modal-scroll-content" }
                    [ contentNode theme opts preset ]
                )
            )

    else
        Nothing


contentNode : Theme -> Options msg -> Preset msg -> Element msg
contentNode theme opts preset =
    let
        phases =
            phaseClasses "fade-in-scale-up-transition" opts.bodyTransition
    in
    case preset of
        Custom attrs children ->
            Element.column
                (I.classes ("n-modal" :: phases) :: attrs)
                children

        Card cardOpts children ->
            NUI.Card.view theme
                { cardOpts
                    | extraClasses = "n-modal" :: (phases ++ cardOpts.extraClasses)
                    , attributes = ariaModal :: cardOpts.attributes
                    , role = Just "dialog"
                }
                children


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


ariaModal : Element.Attribute msg
ariaModal =
    Element.htmlAttribute (HA.attribute "aria-modal" "true")


{-| Naive UI's `cssVarsRef` — the container's four custom properties, in
upstream declaration order.
-}
cssVars : Theme -> List ( String, String )
cssVars theme =
    let
        v =
            ModalTheme.vars theme
    in
    [ ( "--n-bezier-ease-out", theme.common.cubicBezierEaseOut )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-color", v.color )
    , ( "--n-text-color", v.textColor )
    ]
