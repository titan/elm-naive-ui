module NUI.DialogProvider exposing
    ( Item
    , State
    , create
    , destroy
    , destroyAll
    , error
    , info
    , init
    , item
    , remove
    , success
    , view
    , warning
    )

{-| Naive UI's dialog service (upstream `NDialogProvider` + `NDialogEnvironment`

  - `useDialog()`): one caller-owned `State` holds the queue; the transforms are
    the provider API; each item renders the full `NModal` shell around its
    `NUI.Dialog` body via `NUI.Modal.view`'s `Dialog` preset.

    div.n-modal-container (4 modal vars [+ z-index]) — per item, no shared
    ├─ div.n-modal-mask (fade-in-transition phase) container upstream:
    └─ div.n-modal-body-wrapper the provider renders
    └─ n-scrollbar > .n-modal-scroll-content a Fragment
    └─ div.n-dialog.n-modal [phase class LAST]
    (the NUI.Dialog body, 28 vars, aria-modal)

    import NUI.Dialog as Dialog
    import NUI.DialogProvider as DialogProvider
    import NUI.Theme as Theme

    state =
    DialogProvider.info "d1"
    { Dialog.defaults
    | kind = T.Warning
    , title = Just (Element.text "Delete")
    , content = Just (Element.text "Once deleted, gone.")
    , positiveText = Just "Delete"
    }
    DialogProvider.init

    -- wrap the fragment at the call site:
    Element.column [] (DialogProvider.view Theme.default state)

**Everything runtime is caller-owned** (the `NUI.Message`/`NUI.Notification`
service pattern, over the `NUI.Modal` shell contract):

  - **The imperative queue.** Upstream `NDialogProvider` keeps a reactive
    `dialogList`; `create` pushes a reactive options record and returns it
    (`destroy` on the reactive calls the environment's `hide`). Here the
    transforms are pure `State -> State` and the caller threads the state.
  - **Mount appears.** `create` stamps `Just Internal.EnterFrom` — the
    environment mounts with `internalAppear`, so the enter transition runs on
    first paint (the mask fades in, the body scales up from 0.5).
  - **`destroy` / `destroyAll` stamp `Just Internal.LeaveFrom`** (upstream
    `hide()` → `show = false`), and are **no-ops on already-leaving items** —
    resetting the phase ladder would restart the leave. `remove` splices the
    item out — call it on after-leave; it is what empties the DOM.
  - **No clock, no eviction.** Dialogs have no upstream `duration`/`max`: they
    persist until destroyed, and `destroyAll` hides every live dialog at once.
  - **Close gating is the caller.** Upstream hides unless a callback returns
    `false` (`Promise.resolve(cb).then(r => r === false || hide())`). Here
    `onPositiveClick`/`onNegativeClick`/`onClose` are plain msgs on the body
    options; completing a close is the caller calling `destroy` — the veto is
    _not_ calling it. The shell-level runtime (`maskClosable`/`onMaskClick`
    outside-click, `closeOnEsc`/`onEsc`, `autoFocus`/`trapFocus`,
    `blockScroll`, drag, mouse `transformOrigin`) is `NUI.Modal`-layer caller
    runtime by that module's contract (its mask is inert and `aria-hidden`).
  - **z-index is per item, caller-allocated** (upstream `zindexable`
    increments; here `NUI.Modal` renders what you pass).

**`view` returns the per-dialog trees**, in queue order — upstream renders a
Fragment of environments with no container element, so the port has nothing
container-shaped to return. Wrap at the call site (`modalHost` in the demos).
An empty queue renders no trees at all (upstream: `dialogList.length` is 0 →
no environments mount).

-}

import Element exposing (Element)
import NUI.Dialog as Dialog
import NUI.Internal as I
import NUI.Modal as Modal
import NUI.Theme exposing (Theme)
import NUI.Types as T


{-| One dialog environment: the provider key, the transition phase (the one
clock drives both the mask's `fade-in-transition` and the body's
`fade-in-scale-up-transition`), the caller-allocated `z-index`, and the body
options (upstream `DialogOptions` — the dialog props plus the env's `style`,
which `NUI.Dialog.Options.style` carries onto `.n-dialog` after the vars).
-}
type alias Item msg =
    { key : String
    , phase : Maybe I.TransitionPhase
    , zIndex : Maybe Int
    , options : Dialog.Options msg
    }


{-| The blank item: unkeyed, unphased, unstacked, default body. `create` and
the typed helpers build the real thing (stamping the enter phase).
-}
item : Item msg
item =
    { key = ""
    , phase = Nothing
    , zIndex = Nothing
    , options = Dialog.defaults
    }


{-| The queue. Upstream's provider holds no dialog-level props (just the
teleport target, which is the caller's mount point here), so this is exactly
the list.
-}
type alias State msg =
    { items : List (Item msg) }


{-| Upstream `dialogListRef = ref([])`.
-}
init : State msg
init =
    { items = [] }



-- TRANSFORMS


{-| `create(options)` — append keyed, stamping `Just Internal.EnterFrom` (the
environment mounts with `internalAppear`, so even a fresh mount enters
through the transition). Keying is caller-side (`createId()` upstream).
-}
create : String -> Dialog.Options msg -> State msg -> State msg
create key options state =
    { state
        | items =
            state.items
                ++ [ { item | key = key, options = options, phase = Just I.EnterFrom } ]
    }


{-| `useDialog().info(options)` — the typed API stamps `type` AFTER the
options (`create({ ...options, type })` upstream), so it wins over whatever
`kind` the options carried.
-}
info : String -> Dialog.Options msg -> State msg -> State msg
info =
    typed T.Info


{-| `useDialog().success(options)` — kind stamped after the options.
-}
success : String -> Dialog.Options msg -> State msg -> State msg
success =
    typed T.Success


{-| `useDialog().warning(options)` — kind stamped after the options.
-}
warning : String -> Dialog.Options msg -> State msg -> State msg
warning =
    typed T.Warning


{-| `useDialog().error(options)` — kind stamped after the options.
-}
error : String -> Dialog.Options msg -> State msg -> State msg
error =
    typed T.Error


typed : T.Kind -> String -> Dialog.Options msg -> State msg -> State msg
typed kind key options state =
    create key { options | kind = kind } state


{-| `dialogReactive.destroy()` → the environment's `hide()`: stamp
`Just Internal.LeaveFrom`. A no-op on already-leaving items (upstream sets
`show = false` again — nothing visible happens; resetting the ladder would
restart the leave).
-}
destroy : String -> State msg -> State msg
destroy key state =
    { state
        | items =
            List.map
                (\it ->
                    if it.key == key then
                        stampLeave it

                    else
                        it
                )
                state.items
    }


{-| `destroyAll()` — `hide()` on every registered instance. Already-leaving
items are untouched (upstream's `hide` on a hiding dialog is a no-op), live
items stamp the leave.
-}
destroyAll : State msg -> State msg
destroyAll state =
    { state | items = List.map stampLeave state.items }


{-| Splice the item out — call it on after-leave (upstream
`handleAfterLeave` removes by key once the modal's leave transition ends).
This is what empties the container DOM.
-}
remove : String -> State msg -> State msg
remove key state =
    { state | items = List.filter (\it -> it.key /= key) state.items }


stampLeave : Item msg -> Item msg
stampLeave it =
    case it.phase of
        Just p ->
            if I.isLeavePhase p then
                it

            else
                { it | phase = Just I.LeaveFrom }

        Nothing ->
            { it | phase = Just I.LeaveFrom }



-- VIEW


{-| The queue rendered: one full modal tree per item (upstream's Fragment of
`NDialogEnvironment`s — there is no container element to render). An empty
queue renders no trees.
-}
view : Theme -> State msg -> List (Element msg)
view theme state =
    List.map (itemNode theme) state.items


{-| The environment: `show = True` while the item lives, the item's phase
driving BOTH transitions (mask `fade-in-transition`, body
`fade-in-scale-up-transition` — one clock upstream, same here), the
caller-allocated z-index, and the `Dialog` preset body.
-}
itemNode : Theme -> Item msg -> Element msg
itemNode theme it =
    Modal.view theme
        { show = True
        , showMask = True
        , zIndex = it.zIndex
        , maskTransition = it.phase
        , bodyTransition = it.phase
        , attributes = []
        }
        (Modal.Dialog it.options)
