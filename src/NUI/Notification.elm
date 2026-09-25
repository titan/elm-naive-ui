module NUI.Notification exposing
    ( Item
    , Kind(..)
    , Options
    , Placement(..)
    , State
    , create
    , cssVarsFor
    , defaults
    , destroy
    , destroyAll
    , effectiveDuration
    , error
    , info
    , init
    , item
    , remove
    , success
    , view
    , warning
    )

{-| Naive UI's `Notification` service (provider + environments), rebuilt on
elm-ui. The `NUI.Message` twin: same `State` contract, a few byte-visible
deltas called out below.

    import NUI.Internal as I
    import NUI.Notification as Notification


    -- in `update` (the caller owns the queue and the hide clock):
    --
    --   Notify   -> ( Notification.create "n1" { Notification.defaults | title = Just "Hi" } model.notes
    --              , ...schedule a `Hide` msg via `Notification.effectiveDuration`...
    --              )
    --   Hide     -> ( Notification.destroy "n1" model.notes, ... )      -- stamp LeaveFrom
    --   AfterLeave -> ( Notification.remove "n1" model.notes, ... )     -- splice when the leave ends
    --
    --   view: Notification.view theme model.notes

Upstream is a `NotificationProvider` holding a queue of
`NotificationEnvironment`s. Each environment wraps a `div
.n-notification-wrapper` in `<Transition name="notification-transition"
appear>` and owns a `setTimeout(hide, duration)` clock. This library is pure —
no ports, no `update` — so the provider's props and the queue live in one
caller-owned `State`, the transforms here are the provider API, and `view`
renders exactly the DOM the environments would show:

  - `create` — upstream `create()` (NotificationProvider.tsx): appends to
    `items` in DOM order. It stamps `phase = Just I.EnterFrom` (upstream
    mounts with `appear`). When the provider is at `max` — counted as
    `list.length - leavingCount`, i.e. items already in a leave phase do NOT
    count (upstream's `leavingKeySet`) — the OLDEST still-live item is
    destroyed instead of dropped: it enters its leave ladder animated, exactly
    like a `destroy` (upstream's one instant-splice path is a Vue mount race
    for not-yet-mounted refs; the pure port always animates — documented
    divergence). `max` follows JS truthiness: `Just 0` is UNLIMITED. Exactly
    one eviction per create.
  - `info` / `success` / `warning` / `error` — upstream's typed API: `create`
    with the kind stamped (there is no `loading` kind here, unlike message).
  - `destroy` — upstream `destroy()` → the environment's `hide()`:
    `phase := Just I.LeaveFrom`. NO-OP when the item is already in a leave
    phase (upstream's `showRef` is already `false`; resetting the ladder would
    restart the slide — a byte-visible divergence). Unknown keys are no-ops.
  - `destroyAll` — upstream `destroyAll()`: the same rule for every item.
  - `remove` — upstream `onInternalAfterLeave` → splice: drops the item once
    its leave has ended. This is what empties the container — `view` renders
    `Element.none` while `items` is empty.
  - `effectiveDuration` — the resolved hide timeout: the item's own `duration`
    and NOTHING else. Upstream's notification provider has NO `duration` prop
    (unlike message): `Nothing` means never auto-close, `Just 0` is falsy and
    also means never. The `State` argument exists to keep the service-template
    signature parallel to `NUI.Message` and is deliberately unused.

**Deltas from `NUI.Message`** (each upstream-byte-checked):

  - **Vars on TWO nodes.** Both `n-notification-wrapper` and
    `n-notification` carry the full `--n-*` set (upstream `Notification.tsx`
    puts `cssVars` on both). `--n-icon-color` is emitted only when `kind /=
    Default`: upstream reads `self[createKey('iconColor', type)]` and there is
    no `iconColorDefault` key, so the default type drops the var (Vue skips
    undefined styles).
  - **`transitioning` container class.** Upstream toggles a bare
    `transitioning` class on the container while a transition count is > 0
    (before-enter→after-enter, before-leave→after-leave). The pure derivation:
    any item whose `phase /= Nothing` — VALID ONLY IF the caller holds the
    phase `Just` across the whole window (walk the ladder, then `Nothing` on
    after-enter; `remove` on after-leave). Clearing early diverges silently.
    Mixed enter+leave items still yield the one bare class.
  - **`content` renders in a `<pre>`** (upstream keeps a literal `pre` element
    — whitespace bytes are significant there).
  - **Close can be vetoed.** Upstream's env `handleClose` resolves the user
    `onClose` and hides only when the feedback is not `false` (a rejected
    promise also prevents the hide). In Elm the veto is data, not a return
    value: the port emits `onClose` on close-icon click and the CALLER decides
    whether to `destroy`. Timer expiry / `destroy` / `destroyAll` still hide
    WITHOUT firing `onClose`.
  - **Hover-pause gate is `duration && keepAliveOnHover`** (env bytes): the
    internal mouseenter/mouseleave listeners exist only for a notification
    that has BOTH a duration and the merged keep-alive flag. The public
    `onMouseenter` / `onMouseleave` options are always attached (upstream
    merges them via `mergeEventHandlers`).
  - **Scrollable.** Upstream defaults `scrollable: true` and renders an
    `NScrollbar` (contentStyle `overflow: hidden`) around the wrappers —
    unless the placement is `top` / `bottom`, where scrollable is forced off
    (byte-visible: no scrollbar tree). The scrollbar bars themselves are
    hidden at rest (runtime-measured, `NUI.Scrollbar`'s documented contract).
  - **Falsy text fields.** `title` / `description` / `content` / `meta` skip
    their element when `Nothing` OR an empty string (upstream `this.title ?`
    — `''` is falsy there too).

**Divergences from upstream** (everything else is a faithful port):

  - **Provider / teleport skipped.** No `NotificationProvider`, no `to`
    teleport: the caller owns one `State` and mounts the container where it
    wants it (the `NUI.LoadingBar` precedent).
  - **The hide clock is data.** The caller arms the timer from
    `effectiveDuration`, clears/re-arms on hover (a FULL restart on
    mouseleave — upstream `setHideTimeout`, not a remaining-time resume), and
    steps the phase ladder.
  - **`max-height` pinning of the enter/leave windows** (upstream's manual
    `handleBefore*` height juggling) is not reproduced — the phase classes and
    the caller clock drive the CSS transition (the `NUI.Menu` precedent).
  - **`NotificationReactive` mutability** — edit the item's `options` and
    rebuild the state instead. The deprecated `hide` / `deactivate` /
    `onHide` / `onAfterShow` / `onAfterHide` aliases are not ported.
  - **`themeClass` / `inlineThemeDisabled`** — not ported; the inline
    `--n-*` vars are always emitted (upstream's default mode).
  - **`onAfterEnter`** — notification-only (message has none); fires from the
    caller's clock when the enter ladder settles.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode
import NUI.Internal as I
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.Notification as NotificationTheme
import Svg



-- TYPES


{-| Where the container pins itself (upstream `placement`). `top` / `bottom`
also force the scrollbar off (upstream passes
`scrollable && placement !== 'top' && placement !== 'bottom'`) and the
container gains `left: 50%; transform: translateX(-50%)` from the CSS.
-}
type Placement
    = Top
    | TopLeft
    | TopRight
    | Bottom
    | BottomLeft
    | BottomRight


{-| Upstream `NotificationType` (plus the component's `default`): the kind
drives the default avatar icon and the `--n-icon-color` var (emitted only for
non-default kinds — see the module docs).
-}
type Kind
    = Default
    | Info
    | Success
    | Warning
    | Error


{-| One notification's options — upstream `NotificationOptions`. Text fields
render only when `Just` AND non-empty (upstream's falsy check); `action` /
`avatar` are the Element seams for the render-fn variants.
-}
type alias Options msg =
    { kind : Kind
    , title : Maybe String
    , description : Maybe String
    , content : Maybe String
    , meta : Maybe String
    , action : Maybe (Element msg)
    , avatar : Maybe (Element msg)
    , duration : Maybe Float
    , closable : Maybe Bool
    , keepAliveOnHover : Maybe Bool
    , onClose : Maybe msg
    , onLeave : Maybe msg
    , onAfterEnter : Maybe msg
    , onAfterLeave : Maybe msg
    , onMouseenter : Maybe msg
    , onMouseleave : Maybe msg
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream defaults: kind `default`, everything unset; `closable` falls back
to the environment prop default `True`.
-}
defaults : Options msg
defaults =
    { kind = Default
    , title = Nothing
    , description = Nothing
    , content = Nothing
    , meta = Nothing
    , action = Nothing
    , avatar = Nothing
    , duration = Nothing
    , closable = Nothing
    , keepAliveOnHover = Nothing
    , onClose = Nothing
    , onLeave = Nothing
    , onAfterEnter = Nothing
    , onAfterLeave = Nothing
    , onMouseenter = Nothing
    , onMouseleave = Nothing
    , attributes = []
    }


{-| One queued notification — upstream `NotificationEnvironment`. `key` is
caller-supplied and must be unique (upstream generates ids internally; it
never reaches the DOM). `phase` is the `notification-transition` window:
`Nothing` is the settled state; `create` stamps `Just I.EnterFrom`, `destroy`
stamps `Just I.LeaveFrom`, and the caller walks the ladder, removing the item
when the leave ends.
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


{-| The provider props plus the queue. `max` counts only items NOT in a leave
phase (upstream `list.length - leavingKeySet.size`; `Just 0` = unlimited).
`keepAliveOnHover` is the provider default the per-item `Maybe` falls back to.
There is NO provider `duration` (upstream has none). `containerClass` /
`containerStyle` land on the container (the style fragment verbatim).
-}
type alias State msg =
    { placement : Placement
    , max : Maybe Int
    , scrollable : Bool
    , keepAliveOnHover : Bool
    , rtl : Bool
    , containerClass : Maybe String
    , containerStyle : Maybe String
    , items : List (Item msg)
    }


{-| Upstream provider defaults: `top-right`, unlimited, scrollable, no
hover-keep, LTR, empty queue.
-}
init : State msg
init =
    { placement = TopRight
    , max = Nothing
    , scrollable = True
    , keepAliveOnHover = False
    , rtl = False
    , containerClass = Nothing
    , containerStyle = Nothing
    , items = []
    }



-- TRANSFORMS


{-| Upstream `create()` (NotificationProvider.tsx): at `max` (a truthy max and
more non-leaving items than allowed) the OLDEST still-live item is destroyed —
animated, exactly like `destroy` (upstream walks the list head, skips keys
already leaving, and calls its `destroy()`; the pure port always animates the
evictee). The new item is stamped `Just I.EnterFrom` (upstream mounts with
`appear`).
-}
create : String -> Options msg -> State msg -> State msg
create key options state =
    let
        evicted =
            case state.max of
                Just max ->
                    if max > 0 && liveCount state.items >= max then
                        evictOldestLive state.items

                    else
                        state.items

                Nothing ->
                    state.items
    in
    { state | items = evicted ++ [ { key = key, options = options, phase = Just I.EnterFrom } ] }


{-| Items not currently in a leave phase — upstream
`list.length - leavingKeySet.size` (enter-phase items count: they are live).
-}
liveCount : List (Item msg) -> Int
liveCount items =
    List.length (List.filter isLive items)


isLive : Item msg -> Bool
isLive it =
    case it.phase of
        Just p ->
            not (I.isLeavePhase p)

        Nothing ->
            True


{-| Upstream's head walk: skip the leaving, DESTROY the first live one —
animated, exactly a `destroy` (upstream calls the env's `destroy()`; nothing
is dropped instantly on this path).
-}
evictOldestLive : List (Item msg) -> List (Item msg)
evictOldestLive items =
    case items of
        [] ->
            []

        first :: rest ->
            if isLive first then
                hidePhase first :: rest

            else
                first :: evictOldestLive rest


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


{-| Upstream `destroy()` → the environment's `hide()`: stamp
`Just I.LeaveFrom` — unless the item is already in a leave phase, in which
case this is a NO-OP. Unknown keys are no-ops.
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


{-| Upstream `onInternalAfterLeave` → splice: drop the item with this key.
The caller invokes it when the leave has ended; it is what empties the
container.
-}
remove : String -> State msg -> State msg
remove key state =
    { state | items = List.filter (\it -> it.key /= key) state.items }


{-| The resolved hide timeout: the item's own `duration`, nothing else — the
notification provider has NO duration default (upstream
notificationProviderProps). `Nothing` and `Just 0` both mean never (upstream
`if (duration)`). The `State` argument is unused and exists only to keep the
service-template signature parallel to `NUI.Message`.
-}
effectiveDuration : Options msg -> State msg -> Maybe Float
effectiveDuration options _ =
    options.duration



-- VIEW


{-| The container (`n-notification-container` + `--scrollable` when effective

  - `--{placement}`, then the caller's `containerClass`, then the bare
    `transitioning` class while any item is mid-phase), rendered only while items
    exist — upstream renders `notificationList.length ? <Teleport>… : null`. When
    scrollable, the wrappers ride the `n-scrollbar` tree (contentStyle
    `overflow: hidden`, upstream NotificationContainer).

-}
view : Theme -> State msg -> Element msg
view theme state =
    case state.items of
        [] ->
            Element.none

        items ->
            let
                wrappers =
                    List.map (itemNode theme state) items
            in
            if effectiveScrollable state then
                let
                    scrollbarD =
                        Scrollbar.defaults
                in
                Element.column
                    (containerAttrs state)
                    [ Scrollbar.view theme
                        { scrollbarD | contentStyle = Just "overflow:hidden" }
                        wrappers
                    ]

            else
                Element.column (containerAttrs state) wrappers


containerAttrs : State msg -> List (Element.Attribute msg)
containerAttrs state =
    I.classes
        ([ "n-notification-container" ]
            ++ I.classIf (effectiveScrollable state) "n-notification-container--scrollable"
            ++ [ "n-notification-container--" ++ placementClass state.placement ]
            ++ extraClass state.containerClass
            ++ I.classIf (anyJustPhase state.items) "transitioning"
        )
        :: containerStyleAttr state


{-| Upstream passes `scrollable && placement !== 'top' && placement !==
'bottom'` — the top/bottom centers never get the scrollbar tree.
-}
effectiveScrollable : State msg -> Bool
effectiveScrollable state =
    state.scrollable
        && state.placement
        /= Top
        && state.placement
        /= Bottom


{-| Upstream's `wipTransitionCountRef > 0` — any item holding a phase. The
hold-discipline recipe is in the module docs.
-}
anyJustPhase : List (Item msg) -> Bool
anyJustPhase items =
    List.any (\it -> it.phase /= Nothing) items


containerStyleAttr : State msg -> List (Element.Attribute msg)
containerStyleAttr state =
    case state.containerStyle of
        Just style ->
            if String.isEmpty style then
                []

            else
                [ Element.htmlAttribute (HA.attribute "style" style) ]

        Nothing ->
            []


{-| One environment: `div.n-notification-wrapper` — the `Transition`'s child,
so the `notification-transition` phase class sits LAST in the class list (the
`NUI.Modal` house invariant). The wrapper carries the `--n-*` vars (first of
the two var nodes), the mouse listeners (public ones always; the internal
hover-pause pair only under `duration && keepAliveOnHover`), and the caller's
per-item `attributes` seam.
-}
itemNode : Theme -> State msg -> Item msg -> Element msg
itemNode theme state it =
    let
        vars =
            cssVarsFor theme it.options.kind
    in
    Element.el
        ([ I.classes ([ "n-notification-wrapper" ] ++ phaseClasses it.phase)
         , I.cssVars vars
         ]
            ++ wrapperMouseAttrs it.options
                { hasDuration = effectiveDuration it.options state /= Nothing
                , keepAlive = Maybe.withDefault state.keepAliveOnHover it.options.keepAliveOnHover
                }
            ++ it.options.attributes
        )
        (notificationNode theme state it)


notificationNode : Theme -> State msg -> Item msg -> Element msg
notificationNode theme state it =
    Element.row
        [ I.classes
            ([ "n-notification" ]
                ++ I.classIf state.rtl "n-notification--rtl"
                ++ I.classIf (effectiveClosable state it.options) "n-notification--closable"
                ++ I.classIf (showAvatar it.options) "n-notification--show-avatar"
            )
        , I.cssVars (cssVarsFor theme it.options.kind)
        ]
        (List.filterMap identity
            [ avatarNode it.options
            , closeButton state it.options
            , Just (mainNode it.options)
            ]
        )


{-| Upstream `showAvatar`: `avatar || type !== 'default'`. Inside, the custom
avatar wins; otherwise the kind icon (a default kind never reaches the icon
branch — the wrapper would not render).
-}
showAvatar : Options msg -> Bool
showAvatar options =
    options.avatar /= Nothing || options.kind /= Default


avatarNode : Options msg -> Maybe (Element msg)
avatarNode options =
    if showAvatar options then
        Just
            (Element.el
                [ I.classes [ "n-notification__avatar" ] ]
                (case options.avatar of
                    Just avatar ->
                        avatar

                    Nothing ->
                        Element.html (baseIcon (kindSvg options.kind))
                )
            )

    else
        Nothing


{-| Upstream `NBaseClose`: a real `<button>` carrying `n-base-close` and the
`n-notification__close` hook (no `--absolute` here — message's variant).
Clicking emits `onClose`; the veto (upstream's `false` / rejected promise) is
the caller simply not calling `destroy`. Default `closable` is `True` (the
environment prop default).
-}
closeButton : State msg -> Options msg -> Maybe (Element msg)
closeButton state options =
    if effectiveClosable state options then
        Just
            (Element.html
                (Html.button
                    ([ HA.class "n-base-close n-notification__close"
                     , HA.attribute "type" "button"
                     , HA.attribute "tabindex" "0"
                     , HA.attribute "aria-label" "close"
                     ]
                        ++ onClickMsg options.onClose
                    )
                    [ baseIcon [ closeIcon ] ]
                )
            )

    else
        Nothing


effectiveClosable : State msg -> Options msg -> Bool
effectiveClosable state options =
    Maybe.withDefault True options.closable


{-| Upstream's main tree: `__header` / `__description` / `<pre.__content>` /
`__footer(__meta, __action)`. Text fields render only when `Just` AND
non-empty (upstream's falsy check); the footer exists only when meta or
action does.
-}
mainNode : Options msg -> Element msg
mainNode options =
    Element.column
        [ I.classes [ "n-notification-main" ] ]
        (List.filterMap identity
            [ Maybe.map (headerNode "n-notification-main__header") (truthy options.title)
            , Maybe.map (headerNode "n-notification-main__description") (truthy options.description)
            , Maybe.map contentPre (truthy options.content)
            , footerNode options
            ]
        )


headerNode : String -> String -> Element msg
headerNode class text =
    Element.el [ I.classes [ class ] ] (Element.text text)


{-| Upstream renders the content inside a literal `<pre>` — whitespace bytes
are part of the output.
-}
contentPre : String -> Element msg
contentPre text =
    Element.html (Html.pre [ HA.class "n-notification-main__content" ] [ Html.text text ])


footerNode : Options msg -> Maybe (Element msg)
footerNode options =
    if truthy options.meta /= Nothing || options.action /= Nothing then
        Just
            (Element.column
                [ I.classes [ "n-notification-main-footer" ] ]
                (List.filterMap identity
                    [ Maybe.map
                        (\meta ->
                            Element.el
                                [ I.classes [ "n-notification-main-footer__meta" ] ]
                                (Element.text meta)
                        )
                        (truthy options.meta)
                    , Maybe.map
                        (\action ->
                            Element.el
                                [ I.classes [ "n-notification-main-footer__action" ] ]
                                action
                        )
                        options.action
                    ]
                )
            )

    else
        Nothing


{-| Upstream's truthiness: `Nothing` and empty strings render nothing.
-}
truthy : Maybe String -> Maybe String
truthy maybe =
    case maybe of
        Just text ->
            if text == "" then
                Nothing

            else
                Just text

        Nothing ->
            Nothing



-- HELPERS (private)


{-| The `notification-transition` phase class, appended last in the wrapper's
class list; `Nothing` (the settled state) adds none.
-}
phaseClasses : Maybe I.TransitionPhase -> List String
phaseClasses phase =
    case phase of
        Just p ->
            [ I.transitionClass "notification-transition" p ]

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


{-| The wrapper's mouse listeners: the public handler always attached when
set; otherwise the internal hover-pause listener (shape only — the clock is
the caller's) when the env gate `duration && keepAliveOnHover` holds
(upstream `mergeEventHandlers` under that gate; without a user handler the
listener still exists, it just cannot fire a message).
-}
wrapperMouseAttrs : Options msg -> { hasDuration : Bool, keepAlive : Bool } -> List (Element.Attribute msg)
wrapperMouseAttrs options gate =
    let
        internal =
            gate.hasDuration && gate.keepAlive
    in
    mouseAttr "mouseenter" options.onMouseenter internal
        ++ mouseAttr "mouseleave" options.onMouseleave internal


mouseAttr : String -> Maybe msg -> Bool -> List (Element.Attribute msg)
mouseAttr event user internal =
    case user of
        Just msg ->
            [ Element.htmlAttribute (HE.on event (Json.Decode.succeed msg)) ]

        Nothing ->
            if internal then
                [ Element.htmlAttribute (HE.on event (Json.Decode.fail "caller-owned clock")) ]

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



-- THEME


{-| The `--n-*` custom properties carried by BOTH the wrapper and the
`n-notification` (upstream Notification.tsx `cssVarsRef`, exact declaration
order). `--n-icon-color` resolves per kind via `createKey('iconColor', type)`
and is OMITTED for `Default` (no `iconColorDefault` theme key — upstream's
undefined value is skipped by Vue's style binding). The single `padding`
theme value splits into the four `--n-padding-*` sides (seemly `getPadding`).
-}
cssVarsFor : Theme -> Kind -> List ( String, String )
cssVarsFor theme kind =
    let
        v =
            NotificationTheme.vars theme

        padding =
            paddingParts v.padding
    in
    [ ( "--n-color", v.color )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-text-color", v.textColor )
    , ( "--n-description-text-color", v.descriptionTextColor )
    , ( "--n-action-text-color", v.actionTextColor )
    , ( "--n-title-text-color", v.headerTextColor )
    , ( "--n-title-font-weight", v.headerFontWeight )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-bezier-ease-out", theme.common.cubicBezierEaseOut )
    , ( "--n-bezier-ease-in", theme.common.cubicBezierEaseIn )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-close-border-radius", v.closeBorderRadius )
    , ( "--n-close-color-hover", v.closeColorHover )
    , ( "--n-close-color-pressed", v.closeColorPressed )
    , ( "--n-close-icon-color", v.closeIconColor )
    , ( "--n-close-icon-color-hover", v.closeIconColorHover )
    , ( "--n-close-icon-color-pressed", v.closeIconColorPressed )
    , ( "--n-line-height", v.lineHeight )
    ]
        ++ kindIconColor kind v
        ++ [ ( "--n-close-margin", v.closeMargin )
           , ( "--n-close-size", v.closeSize )
           , ( "--n-close-icon-size", v.closeIconSize )
           , ( "--n-width", v.width )
           , ( "--n-padding-left", padding.left )
           , ( "--n-padding-right", padding.right )
           , ( "--n-padding-top", padding.top )
           , ( "--n-padding-bottom", padding.bottom )
           , ( "--n-title-font-size", v.titleFontSize )
           , ( "--n-meta-font-size", v.metaFontSize )
           , ( "--n-description-font-size", v.descriptionFontSize )
           ]


{-| `--n-icon-color` per kind; `Default` emits nothing (see `cssVarsFor`).
-}
kindIconColor : Kind -> NotificationTheme.Vars -> List ( String, String )
kindIconColor kind v =
    case kind of
        Default ->
            []

        Info ->
            [ ( "--n-icon-color", v.iconColorInfo ) ]

        Success ->
            [ ( "--n-icon-color", v.iconColorSuccess ) ]

        Warning ->
            [ ( "--n-icon-color", v.iconColorWarning ) ]

        Error ->
            [ ( "--n-icon-color", v.iconColorError ) ]


{-| seemly's `getPadding`, the CSS shorthand split into its four sides (the
`NUI.Scrollbar.insetParts` semantics; the only real inputs are the generated
theme constants).
-}
paddingParts : String -> { top : String, right : String, bottom : String, left : String }
paddingParts value =
    case String.words (String.trim value) of
        [ all ] ->
            { top = all, right = all, bottom = all, left = all }

        [ vertical, horizontal ] ->
            { top = vertical, right = horizontal, bottom = vertical, left = horizontal }

        [ topValue, horizontal, bottomValue ] ->
            { top = topValue, right = horizontal, bottom = bottomValue, left = horizontal }

        topValue :: rightValue :: bottomValue :: leftValue :: _ ->
            { top = topValue, right = rightValue, bottom = bottomValue, left = leftValue }

        [] ->
            { top = "", right = "", bottom = "", left = "" }



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


svgIcon : String -> String -> Html.Html msg
svgIcon viewBox d =
    Svg.node "svg"
        [ HA.attribute "viewBox" viewBox ]
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
        [ HA.attribute "viewBox" "0 0 12 12" ]
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


infoPath : String
infoPath =
    "M14,2 C20.6274,2 26,7.37258 26,14 C26,20.6274 20.6274,26 14,26 C7.37258,26 2,20.6274 2,14 C2,7.37258 7.37258,2 14,2 Z M14,11 C13.4477,11 13,11.4477 13,12 L13,12 L13,20 C13,20.5523 13.4477,21 14,21 C14.5523,21 15,20.5523 15,20 L15,20 L15,12 C15,11.4477 14.5523,11 14,11 Z M14,6.75 C13.3096,6.75 12.75,7.30964 12.75,8 C12.75,8.69036 13.3096,9.25 14,9.25 C14.6904,9.25 15.25,8.69036 15.25,8 C15.25,7.30964 14.6904,6.75 14,6.75 Z"


successPath : String
successPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M32.6338835,17.6161165 C32.1782718,17.1605048 31.4584514,17.1301307 30.9676119,17.5249942 L30.8661165,17.6161165 L20.75,27.732233 L17.1338835,24.1161165 C16.6457281,23.6279612 15.8542719,23.6279612 15.3661165,24.1161165 C14.9105048,24.5717282 14.8801307,25.2915486 15.2749942,25.7823881 L15.3661165,25.8838835 L19.8661165,30.3838835 C20.3217282,30.8394952 21.0415486,30.8698693 21.5323881,30.4750058 L21.6338835,30.3838835 L32.6338835,19.3838835 C33.1220388,18.8957281 33.1220388,18.1042719 32.6338835,17.6161165 Z"


warningPath : String
warningPath =
    "M12,2 C17.523,2 22,6.478 22,12 C22,17.522 17.523,22 12,22 C6.477,22 2,17.522 2,12 C2,6.478 6.477,2 12,2 Z M12.0018002,15.0037242 C11.450254,15.0037242 11.0031376,15.4508407 11.0031376,16.0023869 C11.0031376,16.553933 11.450254,17.0010495 12.0018002,17.0010495 C12.5533463,17.0010495 13.0004628,16.553933 13.0004628,16.0023869 C13.0004628,15.4508407 12.5533463,15.0037242 12.0018002,15.0037242 Z M11.99964,7 C11.4868042,7.00018474 11.0642719,7.38637706 11.0066858,7.8837365 L11,8.00036004 L11.0018003,13.0012393 L11.00857,13.117858 C11.0665141,13.6151755 11.4893244,14.0010638 12.0021602,14.0008793 C12.5149968,14.0006946 12.9375283,13.6145023 12.9951144,13.1171428 L13.0018002,13.0005193 L13,7.99964009 L12.9932301,7.8830214 C12.9352861,7.38570354 12.5124757,6.99981552 11.99964,7 Z"


errorPath : String
errorPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M17.8838835,16.1161165 L17.7823881,16.0249942 C17.3266086,15.6583353 16.6733914,15.6583353 16.2176119,16.0249942 L16.1161165,16.1161165 L16.0249942,16.2176119 C15.6583353,16.6733914 15.6583353,17.3266086 16.0249942,17.7823881 L16.1161165,17.8838835 L22.233,24 L16.1161165,30.1161165 L16.0249942,30.2176119 C15.6583353,30.6733914 15.6583353,31.3266086 16.0249942,31.7823881 L16.1161165,31.8838835 L16.2176119,31.9750058 C16.6733914,32.3416647 17.3266086,32.3416647 17.7823881,31.9750058 L17.8838835,31.8838835 L24,25.767 L30.1161165,31.8838835 L30.2176119,31.9750058 C30.6733914,32.3416647 31.3266086,32.3416647 31.7823881,31.9750058 L31.8838835,31.8838835 L31.9750058,31.7823881 C32.3416647,31.3266086 32.3416647,30.6733914 31.9750058,30.2176119 L31.8838835,30.1161165 L25.767,24 L31.8838835,17.8838835 L31.9750058,17.7823881 C32.3416647,17.3266086 32.3416647,16.6733914 31.9750058,16.2176119 L31.8838835,16.1161165 L31.7823881,16.0249942 C31.3266086,15.6583353 30.6733914,15.6583353 30.2176119,16.0249942 L30.1161165,16.1161165 L24,22.233 L17.8838835,16.1161165 L17.7823881,16.0249942 L17.8838835,16.1161165 Z"


closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91140884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91140884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,10.0488155 2.34170876,10.0488155 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 L2.14644661,2.14644661 L2.08859116,2.2156945 Z"
