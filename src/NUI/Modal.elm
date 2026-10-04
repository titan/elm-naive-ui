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
`.n-modal` rules land on it). The Custom wrapper is TWO nodes: the port-owned
`.n-modal` shell — which also inlines `flex-shrink: 1; min-width: 0`, since
elm-ui nodes carry `flex-shrink: 0` and would hold an auto-width custom body
at its max-content size, spilling past the scroll content's box (upstream's
plain div keeps the flex default) — and an inner carrier column receiving
the caller's `attributes`: a caller `style` attribute on the shell itself
would clobber the port's geometry declarations (duplicate `style`
attributes, last one wins). `Card` composes `NUI.Card.view` with the
`n-modal` class, `role="dialog"` and `aria-modal="true"` merged onto the card
root (via Card's `extraClasses`/`attributes` seams) — start from
`cardDefaults`: upstream spreads `{...cardBaseProps, ...dialogProps}` so the
card is unbordered by default inside a modal. **Both presets wrap each child in
`Element.paragraph`** — a bare elm-ui `Element.text` carries `white-space: pre`
and a content-width box, so it never wraps and overflows the card/mask on one
line; upstream's `n-modal` body is normal block flow (the `pre` belongs only to
a `content-in-pre` variant). Either way the body phase class
(`fade-in-scale-up-transition-*`) is forced **last** in the root class list
(the house invariant, cf. `NUI.Dropdown`), after any caller-supplied
`extraClasses`. `dialog`/`confirm` presets compose `NUI.Dialog` (see the
**The dialog presets** paragraph below).

`showMask = False` adds `n-modal-body-wrapper--mask-hidden` (pointer-events
pass-through except the content) exactly as upstream's `maskHidden = !showMask`.

**The dialog presets** compose `NUI.Dialog.view`: the body root keeps its own
`.n-dialog` classes and vars, gains `n-modal` (prepended to the dialog's
`extraClasses`, before the phase classes — phase LAST stays) and
`aria-modal="true"` (upstream `BodyWrapper` adds exactly that; `role=dialog`
is the dialog's own). Upstream's `.n-modal .n-dialog` rule (width `446px`,
`max-width: calc(100vw - 32px)`) ships with dialog's cssr, so the composed
body is sized for free. The env-level runtime (`useDialog` queue, the
return-`false`-blocks-close gate, mask/esc/drag) is caller-owned — see
`NUI.Dialog`'s contract.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Card
import NUI.Dialog
import NUI.Internal as I
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.Modal as ModalTheme


{-| The modal's content preset: `Custom` (no upstream preset), `Card`
(upstream `preset: 'card'`), or the dialog pair `Dialog`/`Confirm` (upstream
`preset: 'dialog' | 'confirm'` — `confirm` is a deprecated alias of `dialog`;
both render the identical `NUI.Dialog` body, only the constructor differs).
-}
type Preset msg
    = Custom (List (Element.Attribute msg)) (List (Element msg))
    | Card (NUI.Card.Options msg) (List (Element msg))
    | Dialog (NUI.Dialog.Options msg)
    | Confirm (NUI.Dialog.Options msg)


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
            -- two layers: the port-owned `.n-modal` shell and the caller's
            -- attribute carrier. The shell inlines `flex-shrink: 1;
            -- min-width: 0` — elm-ui nodes carry `flex-shrink: 0` (the `.s`
            -- class), so an auto-width custom body holds its max-content width
            -- and spills past the scroll content's box; upstream's plain div
            -- keeps the flex default (shrink 1) and lets the mask/viewport
            -- bound it. The declarations cannot ride the caller's node: a
            -- caller `style` attribute would clobber them (duplicate style
            -- attributes, last wins), so the shell owns geometry and the
            -- caller's attrs (styles included) land on the inner column —
            -- visually identical, the `NUI.Card` styleAttr merge precedent
            -- turned inside out.
            --
            -- children ride in wrapping paragraphs: elm-ui text carries
            -- `white-space: pre` and would overflow the mask/cell on one
            -- unbreakable line (the `NUI.Popover.bodyNodes` note).
            Element.column
                [ I.classes ("n-modal" :: phases)
                , Element.htmlAttribute (HA.attribute "style" "flex-shrink:1;min-width:0")
                ]
                [ Element.column attrs
                    (List.map (\child -> Element.paragraph [] [ child ]) children)
                ]

        Card cardOpts children ->
            -- caller `extraClasses` sit between `n-modal` and the phase class:
            -- the transition class stays LAST in the root class list (the house
            -- invariant, cf. `NUI.Dropdown`).
            --
            -- children ride in wrapping paragraphs, exactly like `Custom`: a
            -- bare elm-ui `Element.text` carries `white-space: pre` (the `.s.t`
            -- helper) and its `.s.t.wc.hc` box is content-width, so it never
            -- wraps and overflows the card / mask on one unbreakable line (the
            -- `n-modal` body is normal block flow upstream — the pre only
            -- belongs to a `content-in-pre` variant). `Element.paragraph`
            -- restores `white-space: normal` + `width: 100%` on the text.
            NUI.Card.view theme
                { cardOpts
                    | extraClasses = "n-modal" :: (cardOpts.extraClasses ++ phases)
                    , attributes = ariaModal :: cardOpts.attributes
                    , role = Just "dialog"
                }
                (List.map (\child -> Element.paragraph [] [ child ]) children)

        Dialog dialogOpts ->
            dialogBody theme phases dialogOpts

        Confirm dialogOpts ->
            -- preset 'confirm' is upstream's deprecated alias of 'dialog':
            -- BodyWrapper renders the identical NDialog for both.
            dialogBody theme phases dialogOpts


dialogBody : Theme -> List String -> NUI.Dialog.Options msg -> Element msg
dialogBody theme phases dialogOpts =
    NUI.Dialog.view theme
        { dialogOpts
            | extraClasses = "n-modal" :: (dialogOpts.extraClasses ++ phases)
            , attributes = ariaModal :: dialogOpts.attributes
        }


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
