module NUI.Message exposing
    ( Placement(..), Kind(..), Options, defaults, Item, item, State, init, create, info, success, warning, error
    , loading, destroy, destroyAll, remove, effectiveDuration, view, cssVarsFor
    )

{-| Naive UI's `Message` service (provider + environments), rebuilt on elm-ui.

    import NUI.Internal as I
    import NUI.Message as Message


    -- in `update` (the caller owns the queue and the hide clock):
    --
    --   ShowMessage -> ( Message.create "hi" { Message.defaults | content = "Saved" } model.messages
    --                  , ...schedule a `Hide` msg via `Message.effectiveDuration` ...
    --                  )
    --   Hide        -> ( Message.destroy "hi" model.messages, ... )     -- stamp LeaveFrom
    --   AfterLeave  -> ( Message.remove "hi" model.messages, ... )      -- splice when the leave ends
    --
    --   view: Message.view theme model.messages

**The caller-owned contract.** This library is pure — no ports, no `update` —
so the upstream provider's props and the queue live in one caller-owned
`State` and `view` renders exactly the DOM the upstream environments would
show. Config the transforms READ while transforming lives in `State` (`max`,
`duration`, `keepAliveOnHover`, `closable`, `rtl`); view-only config lives in
`Options`; the three mergeable props merge per-item-then-provider exactly as
the provider's JSX does:

  - `create` — appends in DOM order, stamped `phase = Just I.EnterFrom`. At
    `max` the OLDEST item is dropped from the state INSTANTLY — no leave
    phase, none of its callbacks fire (upstream `shift()` unmounts it
    untransitioned); the count includes items already leaving; exactly one
    drop per create; `Just 0` and `Nothing` are UNLIMITED.
  - `info` / `success` / `warning` / `error` / `loading` — `create` with the
    kind stamped (`loading` renders the `n-base-loading` spinner).
  - `destroy` / `destroyAll` — stamp `Just I.LeaveFrom` (the ladder resets to
    `LeaveFrom` even mid-enter); NO-OP for items already leaving; unknown
    keys are no-ops.
  - `remove` — splice the item once its leave has ended (fire your
    after-leave msg one leave-duration after `destroy`). Removing mid-leave
    makes the container vanish before the animation ends.
  - `effectiveDuration` — the resolved hide timeout the caller arms: the
    item's `duration` when set, else the provider default on `State`; `Just
    0` stays `Just 0` and means NEVER (the upstream falsy check beats the
    provider default).
  - **The hide clock is data.** The caller owns the timer (clear/re-arm on
    hover for `keepAliveOnHover`) and fires `onLeave` / `onAfterLeave` from
    it — on EVERY transition leave, timer expiry included, but NOT on
    max-eviction (the evictee is unmounted without a transition and fires
    nothing at all). A close-icon click emits `onClose` fire-and-forget; a
    message's close is never vetoed — completing it is the caller's
    `destroy` in the same update.

(The upstream provider/DOM walkthrough, the callback matrix, the
icon-wrapper rules and the full divergence list live in the plain comment
right below — internal port notes, deliberately kept out of the published
docs.)

@docs Placement, Kind, Options, defaults, Item, item, State, init, create, info, success, warning, error
@docs loading, destroy, destroyAll, remove, effectiveDuration, view, cssVarsFor

-}

{- INTERNAL PORT NOTES — moved out of the module doc (plain comments do not
      enter docs.json; the published docs must stay under the package-size
      limit). Nothing here changes the public contract summarised above.

   Upstream is a `MessageProvider` holding a queue of `MessageEnvironment`s.
   Each environment renders `<NFadeInExpandTransition appear>` around a `div
   .n-message-wrapper` (whose inline `align-items` and `--n-*` vars the message
   carries) and owns a `setTimeout(hide, duration)` clock.

   **Service-template rule.** Config upstream READS while transforming lives in
   `State` (`max`, `duration`, `keepAliveOnHover`, `closable`, `rtl` — the
   provider props), view-only config lives in `Options`. The three mergeable
   props merge per-item-then-provider exactly as the provider's JSX does
   (`message.duration === undefined ? this.duration : message.duration`), at
   transform/view time.

   **Callback matrix** (upstream MessageEnvironment.tsx):

     - close-icon click → `onClose` only — fire-and-forget; a message's close is
       never vetoed (upstream ignores `onClose`'s return and `hide()`s
       unconditionally). The port emits `onClose`; completing the close is the
       caller's `destroy` in the same update.
     - timer expiry / `destroy` / `destroyAll` → hide WITHOUT `onClose`.
     - `onLeave` / `onAfterLeave` fire on every transition leave — timer expiry
       included — but NOT on max-eviction (the evictee is unmounted without a
       transition and fires nothing at all). A pure view cannot fire messages on
       its own; the caller fires them from the clock it owns (onLeave when
       stamping the leave, onAfterLeave when the leave has run its 300ms).

   **Icon wrapper.** Upstream renders `div.n-message__icon` iff
   `showIcon && (icon /= Nothing || kind /= Default)` — a `Default` message
   without a custom icon has NO icon wrapper even at `showIcon = True`, and
   `render /= Nothing` replaces the whole body (icon, content and close included)
   so it never renders one. The `NIconSwitchTransition` around the icon (an
   animation for live TYPE changes) is dropped: items are immutable here — edit
   the item's `options` instead.

   **Divergences from upstream** (everything else is a faithful port):

     - **Provider / teleport skipped.** No `MessageProvider`, no `to` teleport:
       the caller owns one `State` and mounts the container where it wants it
       (the `NUI.LoadingBar` precedent).
     - **The hide clock is data.** Upstream arms `setTimeout` on mount, clears it
       on hover and re-arms it on leave (`keepAliveOnHover`); the caller owns the
       timer and steps the phases. The wrapper's internal mouseenter/mouseleave
       listeners are still emitted — but only when the MERGED `keepAliveOnHover`
       is on, and attached to a decoder that can never produce a message (the
       options expose no public mouse handlers — upstream's API has none either;
       pausing the clock on hover is the caller's job).
     - **`max-height` pinning of `fade-in-height-expand`** (upstream measures the
       element at runtime) is not reproduced — the phase classes and the caller
       clock drive the CSS transition, the `NUI.Menu` precedent.
     - **`MessageReactive` mutability** — upstream lets `create`'s return value
       mutate `content` / `type` live; here an item's `options` are plain data —
       rebuild the state with the edited options.
     - **`spinProps`** — the loading icon's bytes are fixed (strokeWidth 24,
       scale 0.85, upstream's defaults at the message call site). The deprecated
       `hide` / `deactivate` / `onHide` / `onAfterHide` aliases are not ported.
     - **`onClose` return value** — ignored (upstream ignores it too).
     - **`themeClass` / `inlineThemeDisabled`** — not ported; the inline
       `--n-*` vars are always emitted (upstream's default mode).

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Theme exposing (Theme)
import NUI.Theme.Message as MessageTheme
import Svg



-- TYPES


{-| Where the container pins itself (upstream `placement`): the class
`n-message-container--{placement}` positions it; `Top*` placements also flip
the wrappers' inline `align-items` to `flex-start` (bottom: `flex-end`).
-}
type Placement
    = Top
    | TopLeft
    | TopRight
    | Bottom
    | BottomLeft
    | BottomRight


{-| Upstream `MessageType`: the kind drives the `--{kind}-type` modifier
classes and the kind-keyed theme vars (and the default icon — `Default` has
none, `Loading` renders `n-base-loading`).
-}
type Kind
    = Default
    | Info
    | Success
    | Warning
    | Error
    | Loading


{-| One message's options — upstream `MessageOptions` spread into the
environment (`Nothing` durations / flags fall through to the provider props on
`State`).
-}
type alias Options msg =
    { kind : Kind
    , content : String
    , render : Maybe (List (Element msg))
    , duration : Maybe Float
    , closable : Maybe Bool
    , keepAliveOnHover : Maybe Bool
    , showIcon : Bool
    , icon : Maybe (Element msg)
    , onClose : Maybe msg
    , onLeave : Maybe msg
    , onAfterLeave : Maybe msg
    }


{-| Upstream defaults: kind `default` (MessageProvider's `create` spreads
`{ type: 'default', ...options }`), provider-prop fallbacks unset, icon shown.
-}
defaults : Options msg
defaults =
    { kind = Default
    , content = ""
    , render = Nothing
    , duration = Nothing
    , closable = Nothing
    , keepAliveOnHover = Nothing
    , showIcon = True
    , icon = Nothing
    , onClose = Nothing
    , onLeave = Nothing
    , onAfterLeave = Nothing
    }


{-| One queued message — upstream `MessageEnvironment`. `key` is
caller-supplied and must be unique (upstream generates Vue-internal ids; the
`NUI.Menu` `key` precedent — it never reaches the DOM). `phase` is the
`fade-in-height-expand` transition window: `Nothing` is the settled (entered)
state; `create` stamps `Just I.EnterFrom`, `destroy` stamps `Just I.LeaveFrom`
and the caller walks the ladder, removing the item when the leave ends.
-}
type alias Item msg =
    { key : String
    , options : Options msg
    , phase : Maybe I.TransitionPhase
    }


{-| A hand-built item: empty key, `defaults` options, settled phase.
-}
item : Item msg
item =
    { key = ""
    , options = defaults
    , phase = Nothing
    }


{-| The provider props plus the queue. `max` counts every item — leaving ones
included, exactly like upstream's `messageList.length` (`Just 0` =
unlimited). `duration` / `keepAliveOnHover` / `closable` are the provider
defaults the per-item `Maybe`s fall back to. `containerClass` /
`containerStyle` land on the container (the style fragment verbatim, after
the view's own attributes).
-}
type alias State msg =
    { placement : Placement
    , max : Maybe Int
    , duration : Float
    , keepAliveOnHover : Bool
    , closable : Bool
    , rtl : Bool
    , containerClass : Maybe String
    , containerStyle : Maybe String
    , items : List (Item msg)
    }


{-| Upstream provider defaults: `top`, unlimited, 3000ms, no hover-keep, not
closable, LTR, empty queue.
-}
init : State msg
init =
    { placement = Top
    , max = Nothing
    , duration = 3000
    , keepAliveOnHover = False
    , closable = False
    , rtl = False
    , containerClass = Nothing
    , containerStyle = Nothing
    , items = []
    }



-- TRANSFORMS


{-| Upstream `create()` (MessageProvider.tsx): at `max` (a truthy max and
`List.length items >= max`) the oldest item is dropped BEFORE appending —
instantly, with no leave phase and none of its callbacks (upstream `shift()`
unmounts it untransitioned); `Just 0` is unlimited and the count includes
leaving items. The new item is stamped `Just I.EnterFrom` (upstream mounts its
`Transition` with `appear`).
-}
create : String -> Options msg -> State msg -> State msg
create key options state =
    let
        kept =
            case state.max of
                Just max ->
                    if max > 0 && List.length state.items >= max then
                        List.drop 1 state.items

                    else
                        state.items

                Nothing ->
                    state.items
    in
    { state
        | items = kept ++ [ { key = key, options = options, phase = Just I.EnterFrom } ]
    }


{-| Upstream `info()` — `create` with the kind stamped.
-}
info : String -> Options msg -> State msg -> State msg
info key options =
    create key { options | kind = Info }


{-| Upstream `success()` — `create` with the kind stamped.
-}
success : String -> Options msg -> State msg -> State msg
success key options =
    create key { options | kind = Success }


{-| Upstream `warning()` — `create` with the kind stamped.
-}
warning : String -> Options msg -> State msg -> State msg
warning key options =
    create key { options | kind = Warning }


{-| Upstream `error()` — `create` with the kind stamped.
-}
error : String -> Options msg -> State msg -> State msg
error key options =
    create key { options | kind = Error }


{-| Upstream `loading()` — `create` with the kind stamped (renders the
`n-base-loading` spinner in the icon wrapper).
-}
loading : String -> Options msg -> State msg -> State msg
loading key options =
    create key { options | kind = Loading }


{-| Upstream `destroy()` → the environment's `hide()`: stamp
`Just I.LeaveFrom` — unless the item is already in a leave phase, in which
case this is a NO-OP (upstream's `showRef` is already `false`; resetting the
ladder would restart the collapse). Unknown keys are no-ops.
-}
destroy : String -> State msg -> State msg
destroy key state =
    { state | items = List.map (hideItem key) state.items }


{-| Upstream `destroyAll()`: `destroy` for every item, same leave-phase no-op
rule.
-}
destroyAll : State msg -> State msg
destroyAll state =
    { state | items = List.map hideAllItem state.items }


{-| Upstream `onInternalAfterLeave` → `splice`: drop the item with this key.
The caller invokes it when the leave has ended (one leave-duration after
`destroy`); it is what empties the container. Removing mid-leave makes the
container vanish before the animation ends.
-}
remove : String -> State msg -> State msg
remove key state =
    { state | items = List.filter (\it -> it.key /= key) state.items }


{-| The resolved hide timeout the caller arms: the item's `duration` when set,
else the provider default — `Just 0` stays `Just 0` and means NEVER (upstream
`setHideTimeout` guards `if (duration)`, so the falsy check beats the
provider default).
-}
effectiveDuration : Options msg -> State msg -> Maybe Float
effectiveDuration options state =
    Just (Maybe.withDefault state.duration options.duration)



-- VIEW


{-| The container (`n-message-container.n-message-container--{placement}` +
the caller's `containerClass`/`containerStyle`), rendered only while items
exist — upstream renders `messageList.length ? <Teleport>… : null`. The
container's fixed positioning, insets and per-placement `align-items` come
from the extracted CSS.
-}
view : Theme -> State msg -> Element msg
view theme state =
    case state.items of
        [] ->
            Element.none

        items ->
            Element.column
                ([ I.classes (containerClasses state) ] ++ containerStyleAttr state)
                (List.map (itemNode theme state) items)


containerClasses : State msg -> List String
containerClasses state =
    [ "n-message-container"
    , "n-message-container--" ++ placementClass state.placement
    ]
        ++ extraClass state.containerClass


{-| The container's single `style` attribute: the port's per-placement
`align-items` (and `justify-content: flex-end` for the bottom placements —
upstream's own container CSS values) inline, then the caller's
`containerStyle` fragment verbatim (upstream `style={this.containerStyle}`;
the caller's declarations win, the spread convention).

Why inline: elm-ui's default column-alignment classes (`.s.c.cl`, `align-items:
flex-start`) tie on specificity with the scoped `.n-message-container` base
rule and beat it on cascade order — pinning every message to the container's
left edge. Inline declarations cannot be tie-broken, so the upstream CSS
contract (top: centred; top-left: start; \*-right/bottom: end) holds whichever
sheet lands last.

-}
containerStyleAttr : State msg -> List (Element.Attribute msg)
containerStyleAttr state =
    [ Element.htmlAttribute
        (HA.attribute "style" (portContainerStyle state ++ callerContainerStyle state))
    ]


portContainerStyle : State msg -> String
portContainerStyle state =
    let
        alignItemsValue =
            case state.placement of
                Top ->
                    "center"

                TopLeft ->
                    "flex-start"

                TopRight ->
                    "flex-end"

                Bottom ->
                    "center"

                BottomLeft ->
                    "flex-start"

                BottomRight ->
                    "flex-end"

        justifyContent =
            case state.placement of
                Top ->
                    ""

                TopLeft ->
                    ""

                TopRight ->
                    ""

                Bottom ->
                    ";justify-content:flex-end"

                BottomLeft ->
                    ";justify-content:flex-end"

                BottomRight ->
                    ";justify-content:flex-end"
    in
    "align-items:" ++ alignItemsValue ++ justifyContent


callerContainerStyle : State msg -> String
callerContainerStyle state =
    case state.containerStyle of
        Just style ->
            if String.isEmpty style then
                ""

            else
                ";" ++ style

        Nothing ->
            ""


{-| One environment: `div.n-message-wrapper` — the `Transition`'s child, so
the `fade-in-height-expand` phase class sits LAST in the class list (the
`NUI.Modal` house invariant). The inline `style` merges the wrapper's
`align-items` (first, upstream's style array order) with the kind-keyed
`--n-*` vars. The internal hover listeners attach only when the MERGED
`keepAliveOnHover` is on. A `render` option replaces the entire body
(upstream `renderMessage ? renderMessage(props) : …`).
-}
itemNode : Theme -> State msg -> Item msg -> Element msg
itemNode theme state it =
    Element.row
        ([ I.classes ([ "n-message-wrapper" ] ++ phaseClasses it.phase)
         , I.cssVars
            ((( "align-items", alignItems state.placement )
                :: cssVarsFor theme it.options.kind
             )
                ++ -- `align-self: auto` (port-added): the container's per-placement
                   -- `align-items` (top: centred, top-left: start, *-right/bottom:
                   -- end — upstream's own container CSS) is what aligns each
                   -- wrapper in the column's cross axis, but elm-ui's
                   -- `.s.c > .wc` pins every wrapped child to
                   -- `align-self: flex-start`, overriding the container's
                   -- alignment for that child — every message stacked at the
                   -- container's left edge. `auto` defers back to the
                   -- container's `align-items`; inline beats the class rule.
                   -- Appended AFTER the upstream declarations so the upstream
                   -- style prefix stays byte-identical. (The leading
                   -- `align-items` is upstream's own inline style on the
                   -- wrapper — it styles the wrapper's own row content, not
                   -- this axis, so the two never collide.)
                   [ ( "align-self", "auto" ) ]
            )
         ]
            ++ hoverListeners (Maybe.withDefault state.keepAliveOnHover it.options.keepAliveOnHover)
        )
        [ case it.options.render of
            Just elements ->
                Element.column [] elements

            Nothing ->
                messageNode state it
        ]


messageNode : State msg -> Item msg -> Element msg
messageNode state it =
    Element.row
        [ I.classes
            ([ "n-message"
             , "n-message--" ++ kindClass it.options.kind ++ "-type"
             ]
                ++ I.classIf state.rtl "n-message--rtl"
            )
        , Element.htmlAttribute
            -- let the box shrink inside its wrapper: elm-ui nodes carry
            -- `flex-shrink: 0` + auto min-width (the `.s` class), so a long
            -- message holds its max-content width and spills past the
            -- container — upstream's plain div keeps the flex default
            -- (shrink 1) and the content wraps at the container's edge
            -- (max-width: var(--n-max-width) still caps it above)
            (HA.attribute "style" "flex-shrink:1;min-width:0")
        ]
        (List.filterMap identity
            [ iconWrapper it
            , Just
                (Element.paragraph
                    [ I.classes [ "n-message__content" ]
                    , Element.htmlAttribute
                        -- let the content shrink inside the `.n-message` row:
                        -- elm-ui nodes carry `flex-shrink: 0` + auto min-width
                        -- (the `.s` class), so a long word would hold its full
                        -- width and spill past the message box — upstream's
                        -- plain div keeps the flex default (shrink 1) and the
                        -- paragraph's `overflow-wrap: break-word` splits it
                        (HA.attribute "style" "min-width:0;flex-shrink:1")
                    ]
                    [ Element.text it.options.content ]
                )
            , closeButton state it
            ]
        )


{-| `div.n-message__icon` iff `showIcon && (icon /= Nothing || kind /=
Default)` — a `Default` message without a custom icon has NO wrapper even at
`showIcon = True`, and `render` never reaches here. The
`NIconSwitchTransition` (icon type-change animation) is dropped — items are
immutable data; see the module docs.
-}
iconWrapper : Item msg -> Maybe (Element msg)
iconWrapper it =
    if it.options.showIcon && (it.options.icon /= Nothing || it.options.kind /= Default) then
        Just
            (Element.el
                [ I.classes
                    [ "n-message__icon"
                    , "n-message__icon--" ++ kindClass it.options.kind ++ "-type"
                    ]
                ]
                (iconNode it.options)
            )

    else
        Nothing


iconNode : Options msg -> Element msg
iconNode options =
    case options.icon of
        Just icon ->
            icon

        Nothing ->
            case options.kind of
                Loading ->
                    Element.html loadingNode

                kind ->
                    Element.html (baseIcon (kindSvg kind))


{-| Upstream `NBaseClose` (`absolute`): a real `<button>` carrying
`n-base-close--absolute` and the `n-message__close` hook, with the close icon
in an `n-base-icon`. The click emits `onClose` — fire-and-forget; completing
the close is the caller's `destroy` (the message close is never vetoed).
-}
closeButton : State msg -> Item msg -> Maybe (Element msg)
closeButton state it =
    if Maybe.withDefault state.closable it.options.closable then
        Just
            (Element.html
                (Html.button
                    ([ HA.class "n-base-close n-base-close--absolute n-message__close"
                     , HA.attribute "type" "button"
                     , HA.attribute "tabindex" "0"
                     , HA.attribute "aria-label" "close"
                     ]
                        ++ onClickMsg it.options.onClose
                    )
                    [ baseIcon [ closeIcon ] ]
                )
            )

    else
        Nothing



-- HELPERS (private)


{-| The `fade-in-height-expand` phase class, appended last in the wrapper's
class list; `Nothing` (the settled state) adds none.
-}
phaseClasses : Maybe I.TransitionPhase -> List String
phaseClasses phase =
    case phase of
        Just p ->
            [ I.transitionClass "fade-in-height-expand-transition" p ]

        Nothing ->
            []


{-| `destroy` for one item — the leave-phase no-op rule (see `destroy`).
-}
hideItem : String -> Item msg -> Item msg
hideItem key it =
    if it.key == key then
        hidePhase it

    else
        it


{-| `destroyAll` for one item — the same no-op rule.
-}
hideAllItem : Item msg -> Item msg
hideAllItem =
    hidePhase


hidePhase : Item msg -> Item msg
hidePhase it =
    case it.phase of
        Just p ->
            if I.isLeavePhase p then
                it

            else
                { it | phase = Just I.LeaveFrom }

        Nothing ->
            { it | phase = Just I.LeaveFrom }


{-| The internal hover listeners, attached only when the merged
`keepAliveOnHover` is on (upstream `onMouseenter={keepAliveOnHover ?
handleMouseenter : undefined}`). The decoder never succeeds, so no message can
fire: the listeners exist for DOM shape; pausing/re-arming the hide clock on
hover is the caller's job.
-}
hoverListeners : Bool -> List (Element.Attribute msg)
hoverListeners keepAliveOnHover =
    if keepAliveOnHover then
        [ Element.htmlAttribute (HE.on "mouseenter" (Json.Decode.fail "caller-owned clock"))
        , Element.htmlAttribute (HE.on "mouseleave" (Json.Decode.fail "caller-owned clock"))
        ]

    else
        []


onClickMsg : Maybe msg -> List (Html.Attribute msg)
onClickMsg maybeMsg =
    case maybeMsg of
        Just msg ->
            [ HE.onClick msg ]

        Nothing ->
            []


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


{-| Upstream `placement.startsWith('top') ? 'flex-start' : 'flex-end'` — the
wrapper's inline `align-items`, first in the merged `style` attribute.
-}
alignItems : Placement -> String
alignItems placement =
    case placement of
        Top ->
            "flex-start"

        TopLeft ->
            "flex-start"

        TopRight ->
            "flex-start"

        Bottom ->
            "flex-end"

        BottomLeft ->
            "flex-end"

        BottomRight ->
            "flex-end"


placementClass : Placement -> String
placementClass placement =
    case placement of
        Top ->
            "top"

        TopLeft ->
            "top-left"

        TopRight ->
            "top-right"

        Bottom ->
            "bottom"

        BottomLeft ->
            "bottom-left"

        BottomRight ->
            "bottom-right"


kindClass : Kind -> String
kindClass kind =
    case kind of
        Default ->
            "default"

        Info ->
            "info"

        Success ->
            "success"

        Warning ->
            "warning"

        Error ->
            "error"

        Loading ->
            "loading"



-- THEME


{-| The wrapper's `--n-*` custom properties — upstream `Message.tsx`
`cssVarsRef`, in its exact declaration order. The `type`-keyed values
(`textColor` / `color` / `boxShadow` / the close colors) resolve per `Kind`
via `createKey('textColor', type)`.
-}
cssVarsFor : Theme -> Kind -> List ( String, String )
cssVarsFor theme kind =
    let
        v =
            MessageTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-margin", v.margin )
    , ( "--n-padding", v.padding )
    , ( "--n-max-width", v.maxWidth )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-icon-margin", v.iconMargin )
    , ( "--n-icon-size", v.iconSize )
    , ( "--n-close-icon-size", v.closeIconSize )
    , ( "--n-close-border-radius", v.closeBorderRadius )
    , ( "--n-close-size", v.closeSize )
    , ( "--n-close-margin", v.closeMargin )
    , ( "--n-text-color", kindTextColor kind v )
    , ( "--n-color", kindColor kind v )
    , ( "--n-box-shadow", kindBoxShadow kind v )
    , ( "--n-icon-color-info", v.iconColorInfo )
    , ( "--n-icon-color-success", v.iconColorSuccess )
    , ( "--n-icon-color-warning", v.iconColorWarning )
    , ( "--n-icon-color-error", v.iconColorError )
    , ( "--n-icon-color-loading", v.iconColorLoading )
    , ( "--n-close-color-hover", kindCloseColorHover kind v )
    , ( "--n-close-color-pressed", kindCloseColorPressed kind v )
    , ( "--n-close-icon-color", kindCloseIconColor kind v )
    , ( "--n-close-icon-color-pressed", kindCloseIconColorPressed kind v )
    , ( "--n-close-icon-color-hover", kindCloseIconColorHover kind v )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-border", v.border )
    ]


kindTextColor : Kind -> MessageTheme.Vars -> String
kindTextColor kind v =
    case kind of
        Default ->
            v.textColor

        Info ->
            v.textColorInfo

        Success ->
            v.textColorSuccess

        Warning ->
            v.textColorWarning

        Error ->
            v.textColorError

        Loading ->
            v.textColorLoading


kindColor : Kind -> MessageTheme.Vars -> String
kindColor kind v =
    case kind of
        Default ->
            v.color

        Info ->
            v.colorInfo

        Success ->
            v.colorSuccess

        Warning ->
            v.colorWarning

        Error ->
            v.colorError

        Loading ->
            v.colorLoading


kindBoxShadow : Kind -> MessageTheme.Vars -> String
kindBoxShadow kind v =
    case kind of
        Default ->
            v.boxShadow

        Info ->
            v.boxShadowInfo

        Success ->
            v.boxShadowSuccess

        Warning ->
            v.boxShadowWarning

        Error ->
            v.boxShadowError

        Loading ->
            v.boxShadowLoading


kindCloseColorHover : Kind -> MessageTheme.Vars -> String
kindCloseColorHover kind v =
    case kind of
        Default ->
            v.closeColorHover

        Info ->
            v.closeColorHoverInfo

        Success ->
            v.closeColorHoverSuccess

        Warning ->
            v.closeColorHoverWarning

        Error ->
            v.closeColorHoverError

        Loading ->
            v.closeColorHoverLoading


kindCloseColorPressed : Kind -> MessageTheme.Vars -> String
kindCloseColorPressed kind v =
    case kind of
        Default ->
            v.closeColorPressed

        Info ->
            v.closeColorPressedInfo

        Success ->
            v.closeColorPressedSuccess

        Warning ->
            v.closeColorPressedWarning

        Error ->
            v.closeColorPressedError

        Loading ->
            v.closeColorPressedLoading


kindCloseIconColor : Kind -> MessageTheme.Vars -> String
kindCloseIconColor kind v =
    case kind of
        Default ->
            v.closeIconColor

        Info ->
            v.closeIconColorInfo

        Success ->
            v.closeIconColorSuccess

        Warning ->
            v.closeIconColorWarning

        Error ->
            v.closeIconColorError

        Loading ->
            v.closeIconColorLoading


kindCloseIconColorPressed : Kind -> MessageTheme.Vars -> String
kindCloseIconColorPressed kind v =
    case kind of
        Default ->
            v.closeIconColorPressed

        Info ->
            v.closeIconColorPressedInfo

        Success ->
            v.closeIconColorPressedSuccess

        Warning ->
            v.closeIconColorPressedWarning

        Error ->
            v.closeIconColorPressedError

        Loading ->
            v.closeIconColorPressedLoading


kindCloseIconColorHover : Kind -> MessageTheme.Vars -> String
kindCloseIconColorHover kind v =
    case kind of
        Default ->
            v.closeIconColorHover

        Info ->
            v.closeIconColorHoverInfo

        Success ->
            v.closeIconColorHoverSuccess

        Warning ->
            v.closeIconColorHoverWarning

        Error ->
            v.closeIconColorHoverError

        Loading ->
            v.closeIconColorHoverLoading



-- ICONS (Naive UI renders these through NBaseIcon: an `<i class="n-base-icon">`)


baseIcon : List (Html.Html msg) -> Html.Html msg
baseIcon children =
    Html.i [ HA.class "n-base-icon" ] children


kindSvg : Kind -> List (Html.Html msg)
kindSvg kind =
    case kind of
        Info ->
            [ svgIcon "0 0 28 28" infoPath ]

        Success ->
            [ svgIcon "0 0 48 48" successPath ]

        Warning ->
            [ svgIcon "0 0 24 24" warningPath ]

        Error ->
            [ svgIcon "0 0 48 48" errorPath ]

        Default ->
            []

        Loading ->
            []


svgIcon : String -> String -> Html.Html msg
svgIcon viewBox d =
    Svg.node "svg"
        [ HA.attribute "viewBox" viewBox
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Svg.node "path" [ HA.attribute "d" d ] [] ]
            ]
        ]


closeIcon : Html.Html msg
closeIcon =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 12 12"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "aria-hidden" "true"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Svg.node "path" [ HA.attribute "d" closePath ] [] ]
            ]
        ]


{-| The `Loading` kind's icon: upstream `NBaseLoading` with the message call
site's fixed props (strokeWidth 24, scale 0.85; radius 100 default) — the
`n-base-loading` div tree (with its `role="img"` / `aria-label="loading"`)
around `NUI.Internal.Loading.spinner`'s SMIL svg. `String.fromFloat` prints
the scaled geometry exactly like JS (`2 * 100 / 0.85` → `235.29411764705884`).
-}
loadingNode : Html.Html msg
loadingNode =
    Html.div
        [ HA.class "n-base-loading"
        , HA.attribute "role" "img"
        , HA.attribute "aria-label" "loading"
        ]
        [ Html.div [ HA.class "n-base-loading__transition-wrapper" ]
            [ Html.div [ HA.class "n-base-loading__container" ]
                [ Loading.spinner
                    { strokeWidth = 24
                    , radius = 100
                    , scale = 0.85
                    , stroke = Nothing
                    }
                ]
            ]
        ]


infoPath : String
infoPath =
    "M14,2 C20.6274,2 26,7.37258 26,14 C26,20.6274 20.6274,26 14,26 C7.37258,26 2,20.6274 2,14 C2,7.37258 7.37258,2 14,2 Z M14,11 C13.4477,11 13,11.4477 13,12 L13,12 L13,20 C13,20.5523 13.4477,21 14,21 C14.5523,21 15,20.5523 15,20 L15,20 L15,12 C15,11.4477 14.5523,11 14,11 Z M14,6.75 C13.3096,6.75 12.75,7.30964 12.75,8 C12.75,8.69036 13.3096,9.25 14,9.25 C14.6904,9.25 15.25,8.69036 15.25,8 C15.25,7.30964 14.6904,6.75 14,6.75 Z"


successPath : String
successPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M32.6338835,17.6161165 C32.1782718,17.1605048 31.4584514,17.1301307 30.9676119,17.5249942 L30.8661165,17.6161165 L20.75,27.732233 L17.1338835,24.1161165 C16.6457281,23.6279612 15.8542719,23.6279612 15.3661165,24.1161165 C14.9105048,24.5717282 14.8801307,25.2915486 15.2749942,25.7823881 L15.3661165,25.8838835 L19.8661165,30.3838835 C20.3217282,30.8394952 21.0415486,30.8698693 21.5323881,30.4750058 L21.6338835,30.3838835 L32.6338835,19.3838835 C33.1220388,18.8957281 33.1220388,18.1042719 32.6338835,17.6161165 Z"


warningPath : String
warningPath =
    "M12,2 C17.523,2 22,6.478 22,12 C22,17.522 17.523,22 12,22 C6.477,22 2,17.522 2,12 C2,6.478 6.477,2 12,2 Z M12.0018002,15.0037242 C11.450254,15.0037242 11.0031376,15.4508407 11.0031376,16.0023869 C11.0031376,16.553933 11.450254,17.0010495 12.0018002,17.0010495 C12.5533463,17.0010495 13.0004628,16.553933 13.0004628,16.0023869 C13.0004628,15.4508407 12.5533463,15.0037242 12.0018002,15.0037242 Z M11.99964,7 C11.4868042,7.00018474 11.0642719,7.38637706 11.0066858,7.8837365 L11,8.00036004 L11.0018003,13.0012393 L11.00857,13.117858 C11.0665141,13.6151758 11.4893244,14.0010638 12.0021602,14.0008793 C12.514996,14.0006946 12.9375283,13.6145023 12.9951144,13.1171428 L13.0018002,13.0005193 L13,7.99964009 L12.9932303,7.8830214 C12.9352861,7.38570354 12.5124758,6.99981552 11.99964,7 Z"


errorPath : String
errorPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M17.8838835,16.1161165 L17.7823881,16.0249942 C17.3266086,15.6583353 16.6733914,15.6583353 16.2176119,16.0249942 L16.1161165,16.1161165 L16.0249942,16.2176119 C15.6583353,16.6733914 15.6583353,17.3266086 16.0249942,17.7823881 L16.1161165,17.8838835 L22.233,24 L16.1161165,30.1161165 L16.0249942,30.2176119 C15.6583353,30.6733914 15.6583353,31.3266086 16.0249942,31.7823881 L16.1161165,31.8838835 L16.2176119,31.9750058 C16.6733914,32.3416647 17.3266086,32.3416647 17.7823881,31.9750058 L17.8838835,31.8838835 L24,25.767 L30.1161165,31.8838835 L30.2176119,31.9750058 C30.6733914,32.3416647 31.3266086,32.3416647 31.7823881,31.9750058 L31.8838835,31.8838835 L31.9750058,31.7823881 C32.3416647,31.3266086 32.3416647,30.6733914 31.9750058,30.2176119 L31.8838835,30.1161165 L25.767,24 L31.8838835,17.8838835 L31.9750058,17.7823881 C32.3416647,17.3266086 32.3416647,16.6733914 31.9750058,16.2176119 L31.8838835,16.1161165 L31.7823881,16.0249942 C31.3266086,15.6583353 30.6733914,15.6583353 30.2176119,16.0249942 L30.1161165,16.1161165 L24,22.233 L17.8838835,16.1161165 L17.7823881,16.0249942 L17.8838835,16.1161165 Z"


closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91140884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91140884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,10.0488155 2.34170876,10.0488155 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 L2.14644661,2.14644661 L2.08859116,2.2156945 Z"
