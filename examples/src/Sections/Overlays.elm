module Sections.Overlays exposing
    ( Model
    , Msg
    , dialogSection
    , drawerSection
    , dropdownSection
    , init
    , loadingBarSection
    , messageSection
    , modalSection
    , notificationSection
    , popconfirmSection
    , popoverSection
    , sections
    , subscriptions
    , tooltipSection
    , update
    )

{-| Overlays family sections: LoadingBar, Popover, Popconfirm, Tooltip,
Dropdown, Message, Notification, Modal, Drawer, Dialog.

The static rows moved verbatim from Main.elm — that surface feeds the
check-dom gate (`.n-modal-container` / `.n-popover` / `.n-popconfirm` /
`.n-tooltip` / `.n-dropdown` / `.n-message-wrapper` /
`.n-notification-wrapper` / `.n-loading-bar` render open from init), so every
static demo row keeps rendering exactly as before. The live demo rows (moved
verbatim from Live/Overlays.elm — same demoRow labels, same `#live-*` ids,
controls immediately before the cell they drive) run a real update loop
owned by this module: the family is open/close + queue state, all
caller-owned per the port's contract (no portal runtime); the live rows
toggle the overlays CLOSED → OPEN from the model.

  - **Popover-family triggers** (Dropdown/Popover/Tooltip/Popconfirm): show
    state + trigger events are the caller's — the trigger button's `onPress`
    / the host's mouseenter-mouseleave drive a Bool in the model; the body
    mounts/unmounts (`displayDirective: 'if'` semantics).
  - **Modal's outside-click** is caller-owned too (the port's mask is inert
    by design): the demo simulates it with a click listener on the container
    (mask clicks bubble up to it) plus a stopPropagation seam on the card
    body, so inner clicks never close the modal.
  - **Message / Notification queues**: one caller-owned `State` each; the
    push/destroy/remove transforms ARE the interaction helpers. Upstream arms
    a `setTimeout` hide clock — this family is `Sub.none`, so the clock is
    the user's next click: the close icon stamps the leave (`destroy`) and a
    second click completes it (`remove`), exactly the two beats the caller
    with a real timer would fire.
  - [oracle D] **Appear phase is settled at push** — `settleMessage` /
    `settleNotification` clear `EnterFrom` in the same update (no caller
    clock in this family), so items render instantly visible. LOAD-BEARING
    for the LIVE/OVR smoke ("created messages are VISIBLE") — keep.
  - **LoadingBar** is a pure state machine the caller steps — the buttons are
    the animation frames (`start`/`kick`/`finish`/`error` + the enter/leave
    phase ladder).

Phase 2 wires the static rows' own channels to the same model (initial
values equal the old literals, so the initial DOM is byte-identical and
every overlay root still renders open from init — the check-dom gate):

  - **Dropdown static rows** wire `value` + `onSelect` (init = the current
    literal) — the menus stay mounted (static specimens of the open menu),
    leaf clicks navigate the active-option highlight in place.
  - **Message / Notification "Closable" rows** move their item fixtures into
    the model with `onClose` wired — the close × runs the same two-beat
    caller-owned hide clock as the live queues (destroy, then remove).
  - **Modal / Drawer static rows** wire `show` (init `True`) plus the close
    channels the presets expose (Card/DrawerContent `onClose`, the drawer's
    real `onMaskClick`, the dialog presets' positive/negative/×) — the
    container roots always render, so closing only unmounts mask + body.
  - **Popover / Popconfirm / Tooltip static rows** stay pure specimens: their
    Options carry no show/close channel at all (the popover runtime is
    caller-owned upstream — the live rows ARE that runtime), and the pinned
    phase/appearance rows (LoadingBar Starting/Finishing/Error, popover
    Enter-active, modal Enter-active, drawer Hidden-mask/Enter-active,
    DialogProvider fixed queues, bare `Dialog.view` bodies) exist to show
    those states.

-}

import Element exposing (Element)
import Element.Events
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode
import NUI.Button as Button
import NUI.Card as Card
import NUI.Dialog as Dialog
import NUI.DialogProvider as DialogProvider
import NUI.Drawer as Drawer
import NUI.DrawerContent as DrawerContent
import NUI.Dropdown as Dropdown
import NUI.Internal as I
import NUI.LoadingBar as LoadingBar
import NUI.Message as Message
import NUI.Modal as Modal
import NUI.Notification as Notification
import NUI.Popconfirm as Popconfirm
import NUI.Popover as Popover
import NUI.Radio as Radio
import NUI.Switch as Switch
import NUI.Tooltip as Tooltip
import NUI.Types as T
import NUI.Typography as Typo
import Showcase exposing (chip, darkTheme, demoRow, section, theme)
import Svg
import Svg.Attributes as SA


lbD : LoadingBar.Options msg
lbD =
    LoadingBar.defaults


messageD : Message.Options msg
messageD =
    Message.defaults


messageI : Message.Item msg
messageI =
    Message.item


messageS : Message.State msg
messageS =
    Message.init


notificationD : Notification.Options msg
notificationD =
    Notification.defaults


notificationI : Notification.Item msg
notificationI =
    Notification.item


notificationS : Notification.State msg
notificationS =
    Notification.init


popoverD : Popover.Options msg
popoverD =
    Popover.defaults


popconfirmD : Popconfirm.Options msg
popconfirmD =
    Popconfirm.defaults


tooltipD : Tooltip.Options msg
tooltipD =
    Tooltip.defaults


dropdownD : Dropdown.Options msg
dropdownD =
    Dropdown.defaults


modalD : Modal.Options msg
modalD =
    Modal.defaults


modalCardD : Card.Options msg
modalCardD =
    Modal.cardDefaults


drawerD : Drawer.Options msg
drawerD =
    Drawer.defaults


drawerContentD : DrawerContent.Options msg
drawerContentD =
    DrawerContent.defaults


dialogD : Dialog.Options msg
dialogD =
    Dialog.defaults


dialogPI =
    DialogProvider.item



-- MODEL (open/close + queue state, all caller-owned)


type alias Model =
    { dropdownOpen : Bool
    , dropdownHover : Bool
    , dropdownPick : String
    , popoverOpen : Bool
    , popoverPinned : Bool
    , popoverOutcome : String
    , tooltipHover : Bool
    , popconfirmOpen : Bool
    , popconfirmOutcome : String
    , modalOpen : Bool
    , modalCount : Int
    , modalOutcome : String
    , drawerOpen : Bool
    , drawerPlacement : Drawer.Placement
    , drawerOutcome : String
    , dialogOpen : Bool
    , dialogOutcome : String
    , messages : Message.State Msg
    , messageKey : Int
    , messageOutcome : String
    , notifications : Notification.State Msg
    , notificationKey : Int
    , notificationOutcome : String
    , loadingBar : LoadingBar.State
    , loadingOutcome : String
    , dropdownBasicValue : Maybe String
    , dropdownGroupValue : Maybe String
    , dropdownChildValue : Maybe String
    , dropdownActiveValue : Maybe String
    , dropdownVariantValue : Maybe String
    , staticMessages : List (Message.Item Msg)
    , staticNotifications : List (Notification.Item Msg)
    , modalCardOpen : Bool
    , modalDialogOpen : Bool
    , modalConfirmOpen : Bool
    , dialogSamplesOpen : Bool
    , drawerStaticOpen : Bool
    }


init : Model
init =
    { dropdownOpen = False
    , dropdownHover = False
    , dropdownPick = ""
    , popoverOpen = False
    , popoverPinned = False
    , popoverOutcome = "the trigger owns the show state"
    , tooltipHover = False
    , popconfirmOpen = False
    , popconfirmOutcome = "not asked yet"
    , modalOpen = False
    , modalCount = 0
    , modalOutcome = "closed"
    , drawerOpen = False
    , drawerPlacement = Drawer.Right
    , drawerOutcome = "closed"
    , dialogOpen = False
    , dialogOutcome = "—"
    , messages =
        { messageS
            | placement = Message.Top
            , containerStyle = Just "position:relative;"
            , closable = True
        }
    , messageKey = 0
    , messageOutcome = "queue empty"
    , notifications =
        { notificationS
            | placement = Notification.TopRight
            , containerStyle = Just "position:relative;"
            , max = Just 3
        }
    , notificationKey = 0
    , notificationOutcome = "queue empty"
    , loadingBar = LoadingBar.init
    , loadingOutcome = "idle — the bar is unmounted"
    , dropdownBasicValue = Nothing
    , dropdownGroupValue = Nothing
    , dropdownChildValue = Just "target"
    , dropdownActiveValue = Just "target"
    , dropdownVariantValue = Nothing
    , staticMessages =
        [ { messageI
            | key = "c1"
            , options =
                { messageD
                    | kind = Message.Info
                    , content = "Close me"
                    , closable = Just True
                    , onClose = Just (StaticMessageClose "c1")
                }
          }
        , { messageI
            | key = "c2"
            , options =
                { messageD
                    | kind = Message.Success
                    , content = "Also closable"
                    , closable = Just True
                    , onClose = Just (StaticMessageClose "c2")
                }
          }
        ]
    , staticNotifications =
        [ { notificationI
            | key = "full"
            , options =
                { notificationD
                    | kind = Notification.Info
                    , title = Just "Closable with the full tree"
                    , description = Just "The description row"
                    , content = Just "The content — upstream renders this in a <pre>"
                    , meta = Just "the meta line"
                    , action = Just (Element.text "action")
                    , closable = Just True
                    , onClose = Just (StaticNotificationClose "full")
                }
          }
        , { notificationI
            | key = "plain"
            , options =
                { notificationD
                    | title = Just "No avatar — bare main (close renders: closable defaults true)"
                    , kind = Notification.Default
                    , onClose = Just (StaticNotificationClose "plain")
                }
          }
        ]
    , modalCardOpen = True
    , modalDialogOpen = True
    , modalConfirmOpen = True
    , dialogSamplesOpen = True
    , drawerStaticOpen = True
    }



-- UPDATE (one case per channel; component semantics come from the port)


type Msg
    = DropdownToggle
    | DropdownHover Bool
    | DropdownSelect String
    | PopoverToggle
    | PopoverClose
    | PopoverPinned Bool
    | TooltipHover Bool
    | PopconfirmToggle
    | PopconfirmPositive
    | PopconfirmNegative
    | ModalOpen
    | ModalMaskClick
    | ModalClose
    | ModalTick
    | ModalInsideClick
    | DrawerOpen
    | DrawerMaskClose
    | DrawerClose
    | DrawerPickPlacement Drawer.Placement
    | DialogOpen
    | DialogPositive
    | DialogNegative
    | DialogClose
    | MessageInfo
    | MessageSuccess
    | MessageError
    | MessageClose String
    | MessageClear
    | NotificationInfo
    | NotificationSuccess
    | NotificationError
    | NotificationClose String
    | NotificationClear
    | LoadingStart
    | LoadingKick
    | LoadingFadeDone
    | LoadingFinish
    | LoadingError
    | LoadingAfterLeave
      -- phase-2: the static rows' own channels
    | DropdownBasicSelect String
    | DropdownGroupSelect String
    | DropdownChildSelect String
    | DropdownActiveSelect String
    | DropdownVariantSelect String
    | StaticMessageClose String
    | StaticNotificationClose String
    | ModalCardClose
    | ModalDialogClose
    | ModalConfirmClose
    | DialogSampleClose
    | DrawerStaticClose


update : Msg -> Model -> Model
update msg model =
    case msg of
        DropdownToggle ->
            { model | dropdownOpen = not model.dropdownOpen }

        DropdownHover hovering ->
            { model | dropdownHover = hovering }

        DropdownSelect key ->
            { model
                | dropdownPick = key
                , dropdownOpen = False
                , dropdownHover = False
            }

        PopoverToggle ->
            { model | popoverOpen = not model.popoverOpen }

        PopoverClose ->
            { model
                | popoverOpen = False
                , popoverOutcome =
                    if model.popoverPinned then
                        "footer Close fired — but the controlled switch pins it open"

                    else
                        "footer Close fired — body unmounted"
            }

        PopoverPinned pinned ->
            { model
                | popoverPinned = pinned
                , popoverOutcome =
                    if pinned then
                        "controlled: forced open"

                    else
                        "controlled: released (back to the trigger)"
            }

        TooltipHover hovering ->
            { model | tooltipHover = hovering }

        PopconfirmToggle ->
            { model | popconfirmOpen = not model.popconfirmOpen }

        PopconfirmPositive ->
            { model
                | popconfirmOpen = False
                , popconfirmOutcome = "positive — deleted (the update closes; the veto is yours)"
            }

        PopconfirmNegative ->
            { model
                | popconfirmOpen = False
                , popconfirmOutcome = "negative — kept (closed by the update)"
            }

        ModalOpen ->
            { model | modalOpen = True, modalOutcome = "open — clicks still tick" }

        ModalMaskClick ->
            { model | modalOpen = False, modalOutcome = "closed via mask click (bubbled to the container)" }

        ModalClose ->
            { model | modalOpen = False, modalOutcome = "closed via the header ✕ (onClose)" }

        ModalTick ->
            { model | modalCount = model.modalCount + 1 }

        ModalInsideClick ->
            {- swallowed at the card root so inner clicks never reach the
               container's mask-click listener — no model change
            -}
            model

        DrawerOpen ->
            { model | drawerOpen = True, drawerOutcome = "open" }

        DrawerMaskClose ->
            { model | drawerOpen = False, drawerOutcome = "closed via onMaskClick (the drawer's real channel)" }

        DrawerClose ->
            { model | drawerOpen = False, drawerOutcome = "closed via the header ✕ (onClose)" }

        DrawerPickPlacement placement ->
            { model | drawerPlacement = placement }

        DialogOpen ->
            { model | dialogOpen = True, dialogOutcome = "open" }

        DialogPositive ->
            { model | dialogOpen = False, dialogOutcome = "onPositiveClick → submitted" }

        DialogNegative ->
            { model | dialogOpen = False, dialogOutcome = "onNegativeClick → cancelled" }

        DialogClose ->
            { model | dialogOpen = False, dialogOutcome = "onClose → dismissed (✕)" }

        MessageInfo ->
            pushMessage model
                (\key -> { messageD | kind = Message.Info, content = "Disk usage at 62% — pushed live", onClose = Just (MessageClose key) })
                Message.info
                "info"

        MessageSuccess ->
            pushMessage model
                (\key -> { messageD | kind = Message.Success, content = "Deploy finished in 3.2s", onClose = Just (MessageClose key) })
                Message.success
                "success"

        MessageError ->
            pushMessage model
                (\key -> { messageD | kind = Message.Error, content = "Build failed — see the logs", onClose = Just (MessageClose key) })
                Message.error
                "error"

        MessageClose key ->
            -- the caller-owned hide clock: click 1 stamps the leave
            -- (`destroy`), click 2 completes it (`remove`) — the two beats a
            -- real timer would fire 300ms apart.
            if List.any (\i -> i.key == key && isLeaving i.phase) model.messages.items then
                { model
                    | messages = Message.remove key model.messages
                    , messageOutcome = "onClose '" ++ key ++ "' → after-leave → remove (spliced)"
                }

            else
                { model
                    | messages = Message.destroy key model.messages
                    , messageOutcome = "onClose '" ++ key ++ "' → destroy (leave stamped — click ✕ again to splice)"
                }

        MessageClear ->
            if List.any (\i -> not (isLeaving i.phase)) model.messages.items then
                { model | messages = Message.destroyAll model.messages, messageOutcome = "destroyAll — every leave stamped (again to splice)" }

            else
                { model
                    | messages = List.foldl (\i s -> Message.remove i.key s) model.messages model.messages.items
                    , messageOutcome = "all removed (after-leave ran)"
                }

        NotificationInfo ->
            pushNotification model
                (\key ->
                    { notificationD
                        | title = Just "Build queued"
                        , description = Just "12 jobs running"
                        , meta = Just "just now"
                        , onClose = Just (NotificationClose key)
                    }
                )
                Notification.info
                "info"

        NotificationSuccess ->
            pushNotification model
                (\key ->
                    { notificationD
                        | title = Just "Deploy succeeded"
                        , description = Just "v2.4.1 is live"
                        , meta = Just "just now"
                        , onClose = Just (NotificationClose key)
                    }
                )
                Notification.success
                "success"

        NotificationError ->
            pushNotification model
                (\key ->
                    { notificationD
                        | title = Just "Deploy failed"
                        , content = Just "exit code 1"
                        , meta = Just "just now"
                        , onClose = Just (NotificationClose key)
                    }
                )
                Notification.error
                "error"

        NotificationClose key ->
            if List.any (\i -> i.key == key && isLeaving i.phase) model.notifications.items then
                { model
                    | notifications = Notification.remove key model.notifications
                    , notificationOutcome = "onClose '" ++ key ++ "' → after-leave → remove (spliced)"
                }

            else
                { model
                    | notifications = Notification.destroy key model.notifications
                    , notificationOutcome = "onClose '" ++ key ++ "' → destroy (leave stamped — click ✕ again to splice)"
                }

        NotificationClear ->
            if List.any (\i -> not (isLeaving i.phase)) model.notifications.items then
                { model | notifications = Notification.destroyAll model.notifications, notificationOutcome = "destroyAll — every leave stamped (again to splice)" }

            else
                { model
                    | notifications = List.foldl (\i s -> Notification.remove i.key s) model.notifications model.notifications.items
                    , notificationOutcome = "all removed (after-leave ran)"
                }

        LoadingStart ->
            { model
                | loadingBar = model.loadingBar |> LoadingBar.start |> loadingPhase I.EnterFrom
                , loadingOutcome = "start 0 → 80 (phase enter-from — the appear frame)"
            }

        LoadingKick ->
            { model
                | loadingBar = model.loadingBar |> LoadingBar.kick |> loadingPhase I.EnterActive
                , loadingOutcome = "kick — the CSS tweens max-width to 80% over 4s"
            }

        LoadingFadeDone ->
            { model
                | loadingBar = loadingPhaseClear model.loadingBar
                , loadingOutcome = "enter fade done (.3s caller clock) — the bar holds"
            }

        LoadingFinish ->
            { model
                | loadingBar = model.loadingBar |> LoadingBar.finish |> loadingPhase I.LeaveFrom
                , loadingOutcome = "finish — retargets to 100% in .2s, the leave fade starts"
            }

        LoadingError ->
            { model
                | loadingBar = model.loadingBar |> LoadingBar.error |> loadingPhase I.LeaveFrom
                , loadingOutcome = "error — the red bar runs to 100% in .2s"
            }

        LoadingAfterLeave ->
            { model
                | loadingBar = loadingPhaseClear model.loadingBar
                , loadingOutcome = "after-leave (.8s clock) — the container collapses"
            }

        DropdownBasicSelect key ->
            { model | dropdownBasicValue = Just key }

        DropdownGroupSelect key ->
            { model | dropdownGroupValue = Just key }

        DropdownChildSelect key ->
            { model | dropdownChildValue = Just key }

        DropdownActiveSelect key ->
            { model | dropdownActiveValue = Just key }

        DropdownVariantSelect key ->
            { model | dropdownVariantValue = Just key }

        StaticMessageClose key ->
            -- the same two-beat caller-owned hide clock as the live queue
            let
                state =
                    { messageS | items = model.staticMessages }
            in
            if List.any (\i -> i.key == key && isLeaving i.phase) model.staticMessages then
                { model | staticMessages = (Message.remove key state).items }

            else
                { model | staticMessages = (Message.destroy key state).items }

        StaticNotificationClose key ->
            let
                state =
                    { notificationS | items = model.staticNotifications }
            in
            if List.any (\i -> i.key == key && isLeaving i.phase) model.staticNotifications then
                { model | staticNotifications = (Notification.remove key state).items }

            else
                { model | staticNotifications = (Notification.destroy key state).items }

        ModalCardClose ->
            { model | modalCardOpen = False }

        ModalDialogClose ->
            { model | modalDialogOpen = False }

        ModalConfirmClose ->
            { model | modalConfirmOpen = False }

        DialogSampleClose ->
            { model | dialogSamplesOpen = False }

        DrawerStaticClose ->
            { model | drawerStaticOpen = False }


{-| One message pushed through the provider transforms: the typed helper
stamps the kind, `create` appends (stamping `EnterFrom`, upstream's
`appear`), and the appear frame is applied in the same update — the phase is
invisible until the caller's clock advances it, and this family has no
timers. `effectiveDuration` is the port's resolved-auto-hide helper.
-}
pushMessage :
    Model
    -> (String -> Message.Options Msg)
    -> (String -> Message.Options Msg -> Message.State Msg -> Message.State Msg)
    -> String
    -> Model
pushMessage model makeOptions typed kindName =
    let
        key =
            "m" ++ String.fromInt (model.messageKey + 1)

        opts =
            makeOptions key

        duration =
            case Message.effectiveDuration opts model.messages of
                Just ms ->
                    String.fromFloat ms ++ "ms"

                Nothing ->
                    "never"
    in
    { model
        | messages = model.messages |> typed key opts |> settleMessage key
        , messageKey = model.messageKey + 1
        , messageOutcome = kindName ++ " '" ++ key ++ "' created (auto-hide " ++ duration ++ " — the caller's clock)"
    }


settleMessage : String -> Message.State Msg -> Message.State Msg
settleMessage key state =
    { state
        | items =
            List.map
                (\i ->
                    if i.key == key then
                        { i | phase = Nothing }

                    else
                        i
                )
                state.items
    }


{-| The notification twin of `pushMessage` — plus the `max = 3` eviction note:
upstream destroys the oldest still-live item (animated), unlike Message's
instant drop.
-}
pushNotification :
    Model
    -> (String -> Notification.Options Msg)
    -> (String -> Notification.Options Msg -> Notification.State Msg -> Notification.State Msg)
    -> String
    -> Model
pushNotification model makeOptions typed kindName =
    let
        key =
            "n" ++ String.fromInt (model.notificationKey + 1)

        state =
            model.notifications
                |> typed key (makeOptions key)
                |> settleNotification key

        evicted =
            if List.any (\i -> isLeaving i.phase) state.items then
                " — max 3: the oldest was evicted into its leave"

            else
                ""
    in
    { model
        | notifications = state
        , notificationKey = model.notificationKey + 1
        , notificationOutcome = kindName ++ " '" ++ key ++ "' created (no auto-hide — the clock is yours)" ++ evicted
    }


settleNotification : String -> Notification.State Msg -> Notification.State Msg
settleNotification key state =
    { state
        | items =
            List.map
                (\i ->
                    if i.key == key then
                        { i | phase = Nothing }

                    else
                        i
                )
                state.items
    }


isLeaving : Maybe I.TransitionPhase -> Bool
isLeaving phase =
    case phase of
        Just p ->
            I.isLeavePhase p

        Nothing ->
            False


loadingPhase : I.TransitionPhase -> LoadingBar.State -> LoadingBar.State
loadingPhase phase state =
    { state | phase = Just phase }


loadingPhaseClear : LoadingBar.State -> LoadingBar.State
loadingPhaseClear state =
    { state | phase = Nothing }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


dialogPS =
    DialogProvider.init


{-| Deterministic demo data (UTC midnights, ~10 weeks, some gaps and zeros).
-}
loadingBarRows : List (Element msg)
loadingBarRows =
    [ demoRow "ovr-001"
        "Starting (80%)"
        [ Element.el [ Element.width (Element.px 440) ]
            (LoadingBar.view theme
                { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                (LoadingBar.start LoadingBar.init |> LoadingBar.kick)
            )
        ]
    , demoRow "ovr-002"
        "Finishing"
        [ Element.el [ Element.width (Element.px 440) ]
            (LoadingBar.view theme
                { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                (LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.finish)
            )
        ]
    , demoRow "ovr-003"
        "Error"
        [ Element.el [ Element.width (Element.px 440) ]
            (LoadingBar.view theme
                { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                (LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.error)
            )
        ]
    ]


loadingBarSection : Element msg
loadingBarSection =
    section "LoadingBar"
        "Top loading indicator: a `max-width`-transitioned bar driven by a caller-owned state machine (`start` / `kick` / `finish` / `error`). The container is `position: fixed` by default; the demos pin it relatively."
        loadingBarRows


{-| Live: `#live-loading-bar` (buttons immediately before the bar cell —
`nearestPreceding` resolves them by document order).
-}
loadingBarClockRow : Model -> Element Msg
loadingBarClockRow model =
    demoRow "ovr-004" "LoadingBar · manual clock" <|
        [ Button.view theme { btn | size = T.Small, onPress = Just LoadingStart } [ Element.text "start" ]
        , Button.view theme { btn | size = T.Small, onPress = Just LoadingKick } [ Element.text "kick" ]
        , Button.view theme { btn | size = T.Small, onPress = Just LoadingFadeDone } [ Element.text "fade ✓" ]
        , Button.view theme { btn | size = T.Small, onPress = Just LoadingFinish } [ Element.text "finish" ]
        , Button.view theme { btn | size = T.Small, onPress = Just LoadingError } [ Element.text "error" ]
        , Button.view theme { btn | size = T.Small, onPress = Just LoadingAfterLeave } [ Element.text "leave ✓" ]
        , Element.el
            [ Element.width (Element.px 440)
            , Element.htmlAttribute (HA.id "live-loading-bar")
            ]
            (LoadingBar.view theme
                { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                model.loadingBar
            )
        , chip (loadingSummary model.loadingBar ++ " — " ++ model.loadingOutcome)
        ]


loadingBarLiveSection : Model -> Element Msg
loadingBarLiveSection model =
    section "LoadingBar"
        "Top loading indicator: a `max-width`-transitioned bar driven by a caller-owned state machine (`start` / `kick` / `finish` / `error`). The container is `position: fixed` by default; the demos pin it relatively."
        (loadingBarRows ++ [ loadingBarClockRow model ])


scrollbarCopy : String
scrollbarCopy =
    "And as I sat there, brooding on the old unknown world, I thought of Gatsby's wonder when he first picked out the green light at the end of Daisy's dock."


{-| The caller-owned follower wrapper: a `v-placement` host the popover body sits
in (upstream: vueuc's `v-binder-follower-content` with runtime positioning).
Rendered as a labelled "static preview" box — bordered, tinted, min-height so
the floating body reads as a mounted preview, not an unanchored island.
-}
popoverHost : Popover.Placement -> List (Element.Attribute msg) -> Element msg -> Element msg
popoverHost placement attrs content =
    Element.el
        ([ Popover.placementAttribute placement
         , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;padding:34px 28px;min-height:120px;min-width:180px;border:1px dashed #dcdae2;border-radius:4px;background:#fafafc"
            )
         ]
            ++ attrs
        )
        content


popoverRows : List (Element msg)
popoverRows =
    [ demoRow "ovr-005"
        "Basic (top) + header/footer (bottom)"
        [ popoverHost Popover.Top
            []
            (Popover.view theme
                { popoverD | width = Just "240px" }
                [ Element.text "The pure body of a popover — mount it, position it, it is yours." ]
            )
        , popoverHost Popover.Bottom
            []
            (Popover.view theme
                { popoverD
                    | width = Just "240px"
                    , header = Just (Element.text "Title")
                    , footer = Just (Element.text "Footer")
                }
                [ Element.text "Header and footer slots add their wrapper divs and the modifier class." ]
            )
        ]
    , demoRow "ovr-006"
        "No arrow / overlap / raw"
        [ popoverHost Popover.Right
            []
            (Popover.view theme
                { popoverD | width = Just "220px", showArrow = False }
                [ Element.text "No arrow." ]
            )
        , popoverHost Popover.Right
            []
            (Popover.view theme
                { popoverD | width = Just "220px", overlap = True }
                [ Element.text "Overlap: no arrow and no spacing margin." ]
            )
        , popoverHost Popover.Right
            []
            (Popover.view theme
                { popoverD | width = Just "220px", raw = True }
                [ Element.text "Raw: no background, radius or padding." ]
            )
        ]
    , demoRow "ovr-007"
        "Enter-active transition (caller-driven)"
        [ popoverHost Popover.Top
            []
            (Popover.view theme
                { popoverD
                    | width = Just "240px"
                    , transition = Just I.EnterActive
                }
                [ Element.text "The popover-transition classes are the caller's clock." ]
            )
        ]
    , demoRow "ovr-008"
        "Scrollable (n-scrollbar child)"
        [ popoverHost Popover.Top
            []
            (Popover.view theme
                { popoverD
                    | width = Just "260px"
                    , scrollable = True
                    , attributes = [ Element.height (Element.px 120) ]
                }
                [ Element.text scrollbarCopy ]
            )
        ]
    ]


popconfirmRows : List (Element msg)
popconfirmRows =
    [ demoRow "ovr-009"
        "Default + no icon / action slot"
        [ popoverHost Popover.Top
            []
            (Popconfirm.view theme
                { popconfirmD | popover = { popoverD | width = Just "220px" } }
                [ Element.text "Delete it?" ]
            )
        , popoverHost Popover.Top
            []
            (Popconfirm.view theme
                { popconfirmD
                    | popover = { popoverD | width = Just "220px" }
                    , showIcon = False
                    , action = Just [ Element.text "#action — the slot replaces the buttons" ]
                }
                [ Element.text "No icon; the body renders content-only." ]
            )
        ]
    , demoRow "ovr-010"
        "Custom texts + button-props overrides"
        [ popoverHost Popover.Top
            []
            (Popconfirm.view theme
                { popconfirmD
                    | popover = { popoverD | width = Just "240px" }
                    , positiveText = Popconfirm.CustomText "Sure"
                    , negativeText = Popconfirm.CustomText "Not yet"
                    , positiveProps = Just (\b -> { b | round = True })
                    , negativeProps = Just (\b -> { b | round = True })
                }
                [ Element.text "CustomText labels; Hidden drops a button (the row stays)." ]
            )
        ]
    ]


popconfirmSection : Element msg
popconfirmSection =
    section "Popconfirm"
        "The popover body with the confirm panel in its default slot (upstream renders `NPopover` with the `popconfirm` extra class). The panel's icon/body/action structure and the composed action buttons — negative plain `small` first, positive `small` Primary, `positiveProps`/`negativeProps` spreading over the derived base, the action row always rendered — are DOM; the caller owns the show state, the `'click'` trigger and the close gate (upstream's return-false-keeps-it-open is the caller's update)."
        popconfirmRows


{-| Live: `#live-popconfirm` (the trigger button stays immediately before
the cell it drives).
-}
popconfirmFlowRow : Model -> Element Msg
popconfirmFlowRow model =
    demoRow "ovr-011" "Popconfirm · confirm flow" <|
        [ relHost "live-popconfirm"
            Popover.Top
            [ Button.view theme
                { btn | kind = T.Error, onPress = Just PopconfirmToggle }
                [ Element.text "Delete project…" ]
            , if model.popconfirmOpen then
                Popconfirm.view theme
                    { popconfirmD
                        | popover = { popoverD | width = Just "240px" }
                        , onPositiveClick = Just PopconfirmPositive
                        , onNegativeClick = Just PopconfirmNegative
                    }
                    [ Element.text "Delete the whole project?" ]

              else
                Element.none
            ]
        , chip model.popconfirmOutcome
        ]


popconfirmLiveSection : Model -> Element Msg
popconfirmLiveSection model =
    section "Popconfirm"
        "The popover body with the confirm panel in its default slot (upstream renders `NPopover` with the `popconfirm` extra class). The panel's icon/body/action structure and the composed action buttons — negative plain `small` first, positive `small` Primary, `positiveProps`/`negativeProps` spreading over the derived base, the action row always rendered — are DOM; the caller owns the show state, the `'click'` trigger and the close gate (upstream's return-false-keeps-it-open is the caller's update)."
        (popconfirmRows ++ [ popconfirmFlowRow model ])


popoverSection : Element msg
popoverSection =
    section "Popover"
        "The `n-popover` body. The caller owns the show state and the positioned `v-placement` wrapper (here: `popoverHost`); placements, arrows, header/footer and the scrollable scrollbar are static DOM."
        popoverRows


{-| Live: `#live-popover` (the pin switch and the Show button stay the
nearest preceding controls — `nearestPreceding('.n-switch')` resolves the
switch by document order).
-}
popoverControlledRow : Model -> Element Msg
popoverControlledRow model =
    demoRow "ovr-012" "Popover · controlled" <|
        [ Switch.view theme
            { swD | value = model.popoverPinned, onChange = Just PopoverPinned }
            [ Element.text "controlled" ]
        , Button.view theme
            { btn | onPress = Just PopoverToggle }
            [ Element.text
                (if model.popoverOpen then
                    "Hide"

                 else
                    "Show"
                )
            ]
        , relHost "live-popover"
            Popover.Top
            [ if model.popoverOpen || model.popoverPinned then
                Popover.view theme
                    { popoverD
                        | width = Just "240px"
                        , header = Just (Element.text "A live popover")
                        , footer =
                            Just
                                (Button.view theme
                                    { btn
                                        | size = T.Small
                                        , onPress = Just PopoverClose
                                    }
                                    [ Element.text "Close" ]
                                )
                        , transition = Just I.EnterActive
                        , attributes = [ Element.htmlAttribute (HA.id "live-popover-body") ]
                    }
                    [ Element.text "The trigger click opens; the footer button is the close channel; the switch forces it open." ]

              else
                Element.none
            ]
        , chip model.popoverOutcome
        ]


popoverLiveSection : Model -> Element Msg
popoverLiveSection model =
    section "Popover"
        "The `n-popover` body. The caller owns the show state and the positioned `v-placement` wrapper (here: `popoverHost`); placements, arrows, header/footer and the scrollable scrollbar are static DOM."
        (popoverRows ++ [ popoverControlledRow model ])


tooltipRows : List (Element msg)
tooltipRows =
    [ demoRow "ovr-013"
        "Light theme (dark bubble)"
        [ popoverHost Popover.Top
            []
            (Tooltip.view theme
                { tooltipD | width = Just "200px" }
                [ Element.text "A tooltip bubble." ]
            )
        , popoverHost Popover.Bottom
            []
            (Tooltip.view theme
                { tooltipD | width = Just "200px", showArrow = False }
                [ Element.text "No arrow." ]
            )
        ]
    , demoRow "ovr-014"
        "Dark theme (popover colours)"
        [ popoverHost Popover.Right
            []
            (Tooltip.view darkTheme
                { tooltipD | width = Just "200px" }
                [ Element.text "Same as the dark popover." ]
            )
        ]
    ]


tooltipSection : Element msg
tooltipSection =
    section "Tooltip"
        "Popover wearing waistcoat — the same body (`n-tooltip` marker class), the tooltip theme swapping the colours: a dark bubble in light mode, the popover's own colours in dark."
        tooltipRows


{-| Live: `#live-tooltip-region` (mouseenter/mouseleave on the host region).
-}
tooltipHoverRow : Model -> Element Msg
tooltipHoverRow model =
    demoRow "ovr-015" "Tooltip · hover" <|
        [ Element.column
            [ Popover.placementAttribute Popover.Bottom
            , Element.htmlAttribute (HA.attribute "style" "position:relative;padding:6px 0;")
            , Element.htmlAttribute (HA.id "live-tooltip-region")
            , Element.Events.onMouseEnter (TooltipHover True)
            , Element.Events.onMouseLeave (TooltipHover False)
            ]
            [ Button.view theme
                { btn | kind = T.Primary }
                [ Element.text "Hover me" ]
            , if model.tooltipHover then
                Tooltip.view theme
                    { tooltipD
                        | width = Just "220px"
                        , attributes = [ Element.htmlAttribute (HA.id "live-tooltip-body") ]
                    }
                    [ Element.text "A live tooltip — the hover state lives in the model." ]

              else
                Element.none
            ]
        , chip
            (if model.tooltipHover then
                "hovering — the tooltip body is mounted"

             else
                "idle — unmounted"
            )
        ]


tooltipLiveSection : Model -> Element Msg
tooltipLiveSection model =
    section "Tooltip"
        "Popover wearing waistcoat — the same body (`n-tooltip` marker class), the tooltip theme swapping the colours: a dark bubble in light mode, the popover's own colours in dark."
        (tooltipRows ++ [ tooltipHoverRow model ])


dropdownRows : Model -> List (Element Msg)
dropdownRows model =
    [ demoRow "ovr-016"
        "Basic + sizes"
        [ popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD | value = model.dropdownBasicValue, onSelect = Just DropdownBasicSelect }
                [ Dropdown.Option
                    { key = "edit"
                    , label = "Edit"
                    , icon = Nothing
                    , disabled = False
                    , children = Nothing
                    , attributes = []
                    }
                , Dropdown.Option
                    { key = "duplicate"
                    , label = "Duplicate"
                    , icon = Nothing
                    , disabled = False
                    , children = Nothing
                    , attributes = []
                    }
                , Dropdown.Divider { attributes = [] }
                , Dropdown.Option
                    { key = "delete"
                    , label = "Delete"
                    , icon = Nothing
                    , disabled = True
                    , children = Nothing
                    , attributes = []
                    }
                ]
            )
        , popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD
                    | size = Dropdown.Small
                    , value = model.dropdownBasicValue
                    , onSelect = Just DropdownBasicSelect
                }
                [ demoLeaf "small-1" "Small", demoLeaf "small-2" "28px rows" ]
            )
        , popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD
                    | size = Dropdown.Huge
                    , value = model.dropdownBasicValue
                    , onSelect = Just DropdownBasicSelect
                }
                [ demoLeaf "huge-1" "Huge", demoLeaf "huge-2" "46px rows, 18px icons" ]
            )
        ]
    , demoRow "ovr-017"
        "Groups, dividers, icons, submenus, custom"
        [ popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD
                    | width = Just "220px"
                    , value = model.dropdownGroupValue
                    , onSelect = Just DropdownGroupSelect
                }
                [ Dropdown.Group
                    { key = "group-people"
                    , label = "People"
                    , icon = Nothing
                    , children =
                        [ Dropdown.Option
                            { key = "jay"
                            , label = "Jay Gatsby"
                            , icon = Just demoIcon
                            , disabled = False
                            , children = Nothing
                            , attributes = []
                            }
                        , Dropdown.Option
                            { key = "daisy"
                            , label = "Daisy Buchanan"
                            , icon = Just demoIcon
                            , disabled = True
                            , children = Nothing
                            , attributes = []
                            }
                        ]
                    }
                , Dropdown.Divider { attributes = [] }
                , Dropdown.Option
                    { key = "others"
                    , label = "Others"
                    , icon = Just demoIcon
                    , disabled = False
                    , children = Just [ demoLeaf "nick" "Nick Carraway", demoLeaf "tom" "Tom Buchanan" ]
                    , attributes = []
                    }
                , Dropdown.Custom
                    { key = "custom"
                    , children = [ Element.text "A custom render option." ]
                    , attributes = []
                    }
                ]
            )
        , popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD
                    | value = model.dropdownChildValue
                    , onSelect = Just DropdownChildSelect
                }
                [ Dropdown.Option
                    { key = "parent"
                    , label = "Parent (child-active)"
                    , icon = Nothing
                    , disabled = False
                    , children = Just [ demoLeaf "target" "Target (active)" ]
                    , attributes = []
                    }
                , demoLeaf "plain" "Plain"
                ]
            )
        , popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD
                    | value = model.dropdownActiveValue
                    , onSelect = Just DropdownActiveSelect
                }
                [ demoLeaf "target" "Target (active)"
                , demoLeaf "plain" "Plain"
                ]
            )
        ]
    , demoRow "ovr-018"
        "Arrow / inverted / scrollable"
        [ popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD
                    | showArrow = True
                    , value = model.dropdownVariantValue
                    , onSelect = Just DropdownVariantSelect
                }
                [ demoLeaf "a1" "With the popover arrow", demoLeaf "a2" "Second item" ]
            )
        , popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD
                    | inverted = True
                    , value = model.dropdownVariantValue
                    , onSelect = Just DropdownVariantSelect
                }
                [ demoLeaf "i1" "Inverted menu", demoLeaf "i2" "Primary hover" ]
            )
        , popoverHost Popover.Bottom
            []
            (Dropdown.view theme
                { dropdownD
                    | scrollable = True
                    , width = Just "240px"
                    , value = model.dropdownVariantValue
                    , onSelect = Just DropdownVariantSelect
                    , attributes = [ Element.height (Element.px 120) ]
                }
                (List.indexedMap (\i _ -> demoLeaf ("s" ++ String.fromInt i) ("Scrollable item " ++ String.fromInt (i + 1))) (List.range 1 12))
            )
        ]
    ]


dropdownSection : Model -> Element Msg
dropdownSection model =
    section "Dropdown"
        "The `n-dropdown-menu` body — the popover runtime's sibling, rendered as its own element (`n-popover-shared` + `n-dropdown` markers, the merged 31-var set). The caller owns show state, the `v-placement` wrapper (here: `popoverHost`), and any submenu mounts."
        (dropdownRows model)


{-| Live: `#live-dropdown-click` / `#live-dropdown-menu`.
-}
dropdownClickRow : Model -> Element Msg
dropdownClickRow model =
    demoRow "ovr-019" "Dropdown · click trigger" <|
        [ relHost "live-dropdown-click"
            Popover.Bottom
            [ Button.view theme
                { btn | onPress = Just DropdownToggle }
                [ Element.text
                    (if model.dropdownOpen then
                        "Close menu ▴"

                     else
                        "Open menu ▾"
                    )
                ]
            , if model.dropdownOpen then
                Dropdown.view theme
                    { dropdownD
                        | onSelect = Just DropdownSelect
                        , attributes = [ Element.htmlAttribute (HA.id "live-dropdown-menu") ]
                    }
                    dropdownMenu

              else
                Element.none
            ]
        , chip
            (if String.isEmpty model.dropdownPick then
                "no pick yet — a leaf click selects and closes"

             else
                "onSelect → '" ++ model.dropdownPick ++ "' (closed by the update)"
            )
        ]


{-| Live: `#live-dropdown-hover` / `#live-dropdown-hover-menu`.
-}
dropdownHoverRow : Model -> Element Msg
dropdownHoverRow model =
    demoRow "ovr-020" "Dropdown · hover trigger" <|
        [ Element.column
            [ Popover.placementAttribute Popover.Bottom
            , Element.htmlAttribute (HA.attribute "style" "position:relative;padding:6px 0;")
            , Element.htmlAttribute (HA.id "live-dropdown-hover")
            , Element.Events.onMouseEnter (DropdownHover True)
            , Element.Events.onMouseLeave (DropdownHover False)
            ]
            [ Button.view theme btn [ Element.text "Hover me (mouseenter / mouseleave)" ]
            , if model.dropdownHover then
                Dropdown.view theme
                    { dropdownD
                        | onSelect = Just DropdownSelect
                        , attributes = [ Element.htmlAttribute (HA.id "live-dropdown-hover-menu") ]
                    }
                    dropdownMenu

              else
                Element.none
            ]
        , chip
            (if model.dropdownHover then
                "hovering — mounted"

             else
                "idle — unmounted ('hover' is the caller's trigger runtime)"
            )
        ]


dropdownLiveSection : Model -> Element Msg
dropdownLiveSection model =
    section "Dropdown"
        "The `n-dropdown-menu` body — the popover runtime's sibling, rendered as its own element (`n-popover-shared` + `n-dropdown` markers, the merged 31-var set). The caller owns show state, the `v-placement` wrapper (here: `popoverHost`), and any submenu mounts."
        (dropdownRows model ++ [ dropdownClickRow model, dropdownHoverRow model ])


demoLeaf : String -> String -> Dropdown.Option msg
demoLeaf key label =
    Dropdown.Option
        { key = key
        , label = label
        , icon = Nothing
        , disabled = False
        , children = Nothing
        , attributes = []
        }


demoIcon : Element msg
demoIcon =
    Element.html
        (Svg.svg
            [ SA.viewBox "0 0 512 512"
            , SA.fill "none"
            ]
            [ Svg.circle
                [ SA.cx "256"
                , SA.cy "256"
                , SA.r "208"
                , SA.stroke "currentColor"
                , SA.strokeWidth "32"
                ]
                []
            ]
        )


{-| One static message demo cell: a fresh provider state in the given
placement; the fixed container is pinned into the cell with `position:
relative` (the LoadingBar demo's trick).
-}
messageState : Message.Placement -> List (Message.Item Msg) -> Element Msg
messageState placement items =
    modalHost []
        (Message.view theme
            { messageS
                | placement = placement
                , containerStyle = Just "position:relative;"
                , items = items
            }
        )


messageOf : String -> Message.Kind -> String -> Message.Item Msg
messageOf key kind content =
    { messageI
        | key = key
        , options = { messageD | kind = kind, content = content }
    }


messageRows : Model -> List (Element Msg)
messageRows model =
    [ demoRow "ovr-021"
        "Kinds (one container, stacked)"
        [ messageState Message.Top
            [ messageOf "d" Message.Default "A default message — no icon wrapper"
            , messageOf "i" Message.Info "An info message"
            , messageOf "s" Message.Success "A success message"
            , messageOf "w" Message.Warning "A warning message"
            , messageOf "e" Message.Error "An error message"
            , messageOf "l" Message.Loading "A loading message — n-base-loading spinner"
            ]
        , messageState Message.BottomRight
            [ messageOf "b1" Message.Info "Bottom-right placement"
            , messageOf "b2" Message.Success "align-items flips to flex-end"
            ]
        ]
    , demoRow "ovr-022"
        "Closable (onClose fires; you destroy)"
        [ messageState Message.Top model.staticMessages
        ]
    , demoRow "ovr-023"
        "Transition phases (caller clock)"
        [ messageState Message.Top
            [ messageOf "idle" Message.Info "Settled — no phase class"
            , { messageI
                | key = "entering"
                , options = { messageD | kind = Message.Success, content = "Entering — fade-in-height-expand-transition-enter-active" }
                , phase = Just I.EnterActive
              }
            , { messageI
                | key = "leaving"
                , options = { messageD | kind = Message.Warning, content = "Leaving — fade-in-height-expand-transition-leave-from" }
                , phase = Just I.LeaveFrom
              }
            ]
        ]
    , demoRow "ovr-024"
        "Custom icon + render (replaces the whole body)"
        [ messageState Message.Top
            [ { messageI
                | key = "icon"
                , options =
                    { messageD
                        | content = "Custom icon — the wrapper appears for a Default kind"
                        , icon = Just (Element.text "✓")
                    }
              }
            , { messageI
                | key = "render"
                , options =
                    { messageD
                        | render =
                            Just
                                [ Element.el
                                    [ Element.htmlAttribute
                                        (HA.attribute
                                            "style"
                                            "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:10px 20px;color:var(--n-text-color)"
                                        )
                                    ]
                                    (Element.text "render — no .n-message tree, no icon/content/close")
                                ]
                    }
              }
            ]
        ]
    ]


messageSection : Model -> Element Msg
messageSection model =
    section "Message"
        "Naive UI's message service: one caller-owned `State` holds the provider props (`max` — `Just 0` is unlimited and evictions drop the oldest item instantly, the 3000ms default, merged `keepAliveOnHover`/`closable`, `placement`) plus the queue. `create` appends and stamps the enter phase; `destroy` stamps the leave phase (a no-op while already leaving, like upstream's `hide()` on a hidden message); `remove` splices once the leave has run — the caller owns the hide clock, so these demos are static entered states (`phase = Nothing`) with one mid-enter item. A close click emits `onClose` only — completing the close is the caller's `destroy`; a message's close is never vetoed."
        (messageRows model)


{-| Live: `#live-message-queue` (the push buttons stay immediately before the cell — `nearestPreceding` resolves them by document order).
-}
messageQueueRow : Model -> Element Msg
messageQueueRow model =
    demoRow "ovr-025" "Message · queue (click-to-dismiss clock)" <|
        [ Button.view theme { btn | onPress = Just MessageInfo } [ Element.text "info" ]
        , Button.view theme { btn | kind = T.Primary, onPress = Just MessageSuccess } [ Element.text "success" ]
        , Button.view theme { btn | kind = T.Error, onPress = Just MessageError } [ Element.text "error" ]
        , Button.view theme { btn | size = T.Small, onPress = Just MessageClear } [ Element.text "clear" ]
        , overlayCell "live-message-queue" (Message.view theme model.messages)
        , chip model.messageOutcome
        ]


messageLiveSection : Model -> Element Msg
messageLiveSection model =
    section "Message"
        "Naive UI's message service: one caller-owned `State` holds the provider props (`max` — `Just 0` is unlimited and evictions drop the oldest item instantly, the 3000ms default, merged `keepAliveOnHover`/`closable`, `placement`) plus the queue. `create` appends and stamps the enter phase; `destroy` stamps the leave phase (a no-op while already leaving, like upstream's `hide()` on a hidden message); `remove` splices once the leave has run — the caller owns the hide clock, so these demos are static entered states (`phase = Nothing`) with one mid-enter item. A close click emits `onClose` only — completing the close is the caller's `destroy`; a message's close is never vetoed."
        (messageRows model ++ [ messageQueueRow model ])


{-| One static notification demo cell — the message demo's trick: a fresh
provider state per cell, pinned into it with `position: relative`.
-}
notificationState : Notification.Placement -> List (Notification.Item Msg) -> Element Msg
notificationState placement items =
    modalHost []
        (Notification.view theme
            { notificationS
                | placement = placement
                , containerStyle = Just "position:relative;"
                , items = items
            }
        )


notificationOf : String -> String -> Notification.Kind -> Notification.Item Msg
notificationOf key title kind =
    { notificationI
        | key = key
        , options = { notificationD | title = Just title, kind = kind }
    }


notificationRows : Model -> List (Element Msg)
notificationRows model =
    [ demoRow "ovr-026"
        "Kinds (top-right — scrollable, so the n-scrollbar tree shows)"
        [ notificationState Notification.TopRight
            [ notificationOf "d" "A default notification" Notification.Default
            , notificationOf "i" "An info notification" Notification.Info
            , notificationOf "s" "A success notification" Notification.Success
            , notificationOf "w" "A warning notification" Notification.Warning
            , notificationOf "e" "An error notification" Notification.Error
            ]
        ]
    , demoRow "ovr-027"
        "Closable + description / content-in-pre / meta + action"
        [ notificationState Notification.TopRight model.staticNotifications
        ]
    , demoRow "ovr-028"
        "Placements (top/bottom centers force the scrollbar off)"
        [ notificationState Notification.TopLeft
            [ notificationOf "tl" "Top-left — scrollable" Notification.Success ]
        , notificationState Notification.Top
            [ notificationOf "tc" "Top center — scrollable forced off (no scrollbar tree)" Notification.Warning ]
        , notificationState Notification.BottomRight
            [ notificationOf "br" "Bottom-right — align flips" Notification.Error ]
        ]
    , demoRow "ovr-029"
        "Transition phases (caller clock) + the container's transitioning class"
        [ notificationState Notification.TopRight
            [ notificationOf "idle" "Settled — no phase class" Notification.Info
            , { notificationI
                | key = "entering"
                , options = { notificationD | title = Just "Entering — notification-transition-enter-active", kind = Notification.Success }
                , phase = Just I.EnterActive
              }
            , { notificationI
                | key = "leaving"
                , options = { notificationD | title = Just "Leaving — notification-transition-leave-from", kind = Notification.Warning }
                , phase = Just I.LeaveFrom
              }
            ]
        ]
    ]


notificationSection : Model -> Element Msg
notificationSection model =
    section "Notification"
        "Naive UI's notification service — the `NUI.Message` twin: one caller-owned `State` (provider props + queue) and pure transforms. Deltas: vars ride BOTH the wrapper and `n-notification`; `--n-icon-color` is emitted only for typed kinds (no `iconColorDefault` upstream); the default `scrollable` provider wraps the queue in an `n-scrollbar` tree (forced off for the `top`/`bottom` centers); the container gains a bare `transitioning` class while any item holds a phase; `content` renders in a `<pre>`; the close click emits `onClose` and the VETO is the caller not calling `destroy` (upstream's `false`/rejected-promise rule). These demos are static entered states — the caller owns the hide clock."
        (notificationRows model)


{-| Live: `#live-notification-queue` (the push buttons stay immediately before the cell — `nearestPreceding` resolves them by document order).
-}
notificationQueueRow : Model -> Element Msg
notificationQueueRow model =
    demoRow "ovr-030" "Notification · queue (max 3)" <|
        [ Button.view theme { btn | onPress = Just NotificationInfo } [ Element.text "info" ]
        , Button.view theme { btn | kind = T.Primary, onPress = Just NotificationSuccess } [ Element.text "success" ]
        , Button.view theme { btn | kind = T.Error, onPress = Just NotificationError } [ Element.text "error" ]
        , Button.view theme { btn | size = T.Small, onPress = Just NotificationClear } [ Element.text "clear" ]
        , overlayCell "live-notification-queue" (Notification.view theme model.notifications)
        , chip model.notificationOutcome
        ]


notificationLiveSection : Model -> Element Msg
notificationLiveSection model =
    section "Notification"
        "Naive UI's notification service — the `NUI.Message` twin: one caller-owned `State` (provider props + queue) and pure transforms. Deltas: vars ride BOTH the wrapper and `n-notification`; `--n-icon-color` is emitted only for typed kinds (no `iconColorDefault` upstream); the default `scrollable` provider wraps the queue in an `n-scrollbar` tree (forced off for the `top`/`bottom` centers); the container gains a bare `transitioning` class while any item holds a phase; `content` renders in a `<pre>`; the close click emits `onClose` and the VETO is the caller not calling `destroy` (upstream's `false`/rejected-promise rule). These demos are static entered states — the caller owns the hide clock."
        (notificationRows model ++ [ notificationQueueRow model ])


{-| The fixed-tree preview cell (Modal/Drawer/DialogProvider): a sized,
relative, translated box — `transform` makes it the containing block for the
components' fixed trees, `overflow: hidden` keeps their geometry inside.
Width/height ride elm-ui's px classes (raw inline width collapses under
`.s.r > .s { flex-basis: 0% }` when the cell sits in a demo card row).
-}
modalHost : List (Element.Attribute msg) -> Element msg -> Element msg
modalHost attrs content =
    Element.el
        ([ Element.width (Element.px 320)
         , Element.height (Element.px 210)
         , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;transform:translate(0,0);overflow:hidden;border:1px solid #efeff5;border-radius:4px;background:#fafafc"
            )
         ]
            ++ attrs
        )
        content


{-| A plain demo cell for a standalone `.n-dialog` body (no fixed tree to
confine — just a sized box; the block body fills it).
-}
cell : Element msg -> Element msg
cell content =
    Element.el
        [ Element.width (Element.px 320)
        , Element.htmlAttribute
            (HA.attribute "style" "border:1px solid #efeff5;border-radius:4px;background:#fafafc")
        ]
        content


modalRows : Model -> List (Element Msg)
modalRows model =
    [ demoRow "ovr-031"
        "Custom content + card preset"
        [ modalHost []
            (Modal.view theme
                { modalD | show = True }
                (Modal.Custom
                    [ Element.htmlAttribute
                        (HA.attribute
                            "style"
                            "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px;color:var(--n-text-color)"
                        )
                    ]
                    [ Element.text "Custom content — you own the box; the wrapper carries `n-modal`." ]
                )
            )
        , modalHost []
            (Modal.view theme
                { modalD | show = model.modalCardOpen }
                (Modal.Card
                    { modalCardD
                        | title = Just (Element.text "A card modal")
                        , footer = Just (Element.text "#footer")
                        , closable = True
                        , onClose = Just ModalCardClose
                    }
                    [ Element.text "Unbordered by default — upstream spreads the dialog props last." ]
                )
            )
        ]
    , demoRow "ovr-032"
        "Card variants (bordered opt-in, segmented, dark)"
        [ modalHost []
            (Modal.view theme
                { modalD | show = True }
                (Modal.Card
                    { modalCardD
                        | title = Just (Element.text "Bordered")
                        , bordered = True
                    }
                    [ Element.text "Opt back into the card border." ]
                )
            )
        , modalHost []
            (Modal.view theme
                { modalD | show = True }
                (Modal.Card
                    { modalCardD
                        | title = Just (Element.text "Segmented")
                        , segmented =
                            { content = Card.Hard
                            , footer = Card.Off
                            , action = Card.Off
                            }
                        , footer = Just (Element.text "#footer")
                    }
                    [ Element.text "Content/footer separators." ]
                )
            )
        , modalHost []
            (Modal.view darkTheme
                { modalD | show = True }
                (Modal.Card
                    { modalCardD | title = Just (Element.text "Dark theme") }
                    [ Element.text "rgb(44, 44, 50) surface, .82 white text." ]
                )
            )
        ]
    , demoRow "ovr-033"
        "No mask (mask-hidden) + z-index"
        [ modalHost []
            (Modal.view theme
                { modalD | show = True, showMask = False }
                (Modal.Custom
                    [ Element.htmlAttribute
                        (HA.attribute
                            "style"
                            "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px"
                        )
                    ]
                    [ Element.text "No mask: --mask-hidden passes clicks through around the content." ]
                )
            )
        , modalHost []
            (Modal.view theme
                { modalD | show = True, zIndex = Just 100 }
                (Modal.Custom
                    [ Element.htmlAttribute
                        (HA.attribute
                            "style"
                            "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px"
                        )
                    ]
                    [ Element.text "z-index: 100 on the container." ]
                )
            )
        ]
    , demoRow "ovr-034"
        "Enter-active phases (caller clock)"
        [ modalHost []
            (Modal.view theme
                { modalD
                    | show = True
                    , maskTransition = Just I.EnterActive
                    , bodyTransition = Just I.EnterActive
                }
                (Modal.Card
                    { modalCardD | title = Just (Element.text "Entering") }
                    [ Element.text "fade-in + fade-in-scale-up enter-active classes." ]
                )
            )
        ]
    ]


modalSection : Model -> Element Msg
modalSection model =
    section "Modal"
        "The mount-body family — its own fixed tree (container > mask > body-wrapper > scrollbar > content), self-positioned and centred by flex. The caller owns mounting, the show state, the transition clock (one clock drives the mask and body tuples), outside-click closing and Esc; the `dialog`/`confirm` presets compose `NUI.Dialog` (its section follows). The demo cells confine the fixed tree with a `transform: translate(0,0)` containing block."
        (modalRows model)


{-| Live: `#live-modal` / `#live-modal-tree` (the `Open modal` trigger stays immediately before the cell).
-}
modalRow : Model -> Element Msg
modalRow model =
    demoRow "ovr-035" "Modal · open/close + mask" <|
        [ Button.view theme
            { btn | kind = T.Primary, onPress = Just ModalOpen }
            [ Element.text "Open modal" ]
        , overlayCell "live-modal" <|
            if model.modalOpen then
                Modal.view theme
                    { modalD
                        | show = True
                        , attributes =
                            [ Element.Events.onClick ModalMaskClick
                            , Element.htmlAttribute (HA.id "live-modal-tree")
                            ]
                    }
                    (Modal.Card
                        { modalCardD
                            | title = Just (Element.text "Live modal")
                            , closable = True
                            , onClose = Just ModalClose
                            , attributes = [ swallowClicks ]
                        }
                        [ Element.text ("Ticks while open: " ++ String.fromInt model.modalCount)
                        , Button.view theme
                            { btn | size = T.Small, onPress = Just ModalTick }
                            [ Element.text "tick" ]
                        ]
                    )

            else
                overlayHint "modal unmounted — the fixed tree mounts on open (displayDirective: if)"
        , chip model.modalOutcome
        ]


modalLiveSection : Model -> Element Msg
modalLiveSection model =
    section "Modal"
        "The mount-body family — its own fixed tree (container > mask > body-wrapper > scrollbar > content), self-positioned and centred by flex. The caller owns mounting, the show state, the transition clock (one clock drives the mask and body tuples), outside-click closing and Esc; the `dialog`/`confirm` presets compose `NUI.Dialog` (its section follows). The demo cells confine the fixed tree with a `transform: translate(0,0)` containing block."
        (modalRows model ++ [ modalRow model ])


{-| The drawer's `NDrawerContent` body — title, closable header, footer.
-}
drawerBody : Element Msg
drawerBody =
    DrawerContent.view theme
        { drawerContentD
            | title = Just (Element.text "A drawer")
            , closable = True
            , onClose = Just DrawerStaticClose
            , footer = Just (Element.text "#footer")
        }
        [ Element.text "Edge-anchored, sized on the placement's axis." ]


drawerRows : Model -> List (Element Msg)
drawerRows model =
    [ demoRow "ovr-036"
        "Four placements (NDrawerContent composition)"
        [ modalHost []
            (Drawer.view theme
                { drawerD | show = model.drawerStaticOpen, placement = Drawer.Right, width = Just "200px", onMaskClick = Just DrawerStaticClose }
                [ drawerBody ]
            )
        , modalHost []
            (Drawer.view theme
                { drawerD | show = model.drawerStaticOpen, placement = Drawer.Left, width = Just "200px", onMaskClick = Just DrawerStaticClose }
                [ drawerBody ]
            )
        , modalHost []
            (Drawer.view theme
                { drawerD | show = model.drawerStaticOpen, placement = Drawer.Top, height = Just "120px", onMaskClick = Just DrawerStaticClose }
                [ drawerBody ]
            )
        , modalHost []
            (Drawer.view theme
                { drawerD | show = model.drawerStaticOpen, placement = Drawer.Bottom, height = Just "120px", onMaskClick = Just DrawerStaticClose }
                [ drawerBody ]
            )
        ]
    , demoRow "ovr-037"
        "Custom content (no DrawerContent)"
        [ modalHost []
            (Drawer.view theme
                { drawerD | show = True, placement = Drawer.Right, width = Just "220px" }
                [ Element.el
                    [ Element.htmlAttribute
                        (HA.attribute
                            "style"
                            "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px 0 0 3px;padding:14px 18px;color:var(--n-text-color);height:100%;box-sizing:border-box"
                        )
                    ]
                    (Element.text "You own the box; the wrapper carries `n-drawer-content-wrapper`.")
                ]
            )
        ]
    , demoRow "ovr-038"
        "Mask variants + z-index"
        [ modalHost []
            (Drawer.view theme
                { drawerD
                    | show = model.drawerStaticOpen
                    , placement = Drawer.Right
                    , width = Just "180px"
                    , showMask = Drawer.Transparent
                    , onMaskClick = Just DrawerStaticClose
                }
                [ drawerBody ]
            )
        , modalHost []
            (Drawer.view theme
                { drawerD
                    | show = model.drawerStaticOpen
                    , placement = Drawer.Right
                    , width = Just "180px"
                    , showMask = Drawer.Hidden
                }
                [ drawerBody ]
            )
        , modalHost []
            (Drawer.view theme
                { drawerD | show = model.drawerStaticOpen, placement = Drawer.Right, width = Just "180px", zIndex = Just 100 }
                [ drawerBody ]
            )
        ]
    , demoRow "ovr-039"
        "Scroll seams + resize trigger"
        [ modalHost []
            (Drawer.view theme
                { drawerD
                    | show = True
                    , placement = Drawer.Right
                    , width = Just "220px"
                    , nativeScrollbar = False
                }
                [ DrawerContent.view theme
                    { drawerContentD
                        | title = Just (Element.text "Scrollbar body")
                        , nativeScrollbar = False
                    }
                    [ Element.text "Both seams swap to `NUI.Scrollbar` — `n-drawer-body` rides the scrollbar root." ]
                ]
            )
        , modalHost []
            (Drawer.view theme
                { drawerD
                    | show = True
                    , placement = Drawer.Right
                    , width = Just "220px"
                    , resizable = True
                    , showResizeTriggerHover = True
                }
                [ drawerBody ]
            )
        ]
    , demoRow "ovr-040"
        "Enter-active phase (caller clock)"
        [ modalHost []
            (Drawer.view theme
                { drawerD
                    | show = True
                    , placement = Drawer.Right
                    , width = Just "220px"
                    , maskTransition = Just I.EnterActive
                    , bodyTransition = Just I.EnterActive
                }
                [ drawerBody ]
            )
        ]
    ]


drawerSection : Model -> Element Msg
drawerSection model =
    section "Drawer"
        "The mount-body sibling of Modal — its own container/mask/host tree, edge-anchored (`position: absolute` per placement, the body transition family derived from it) instead of flex-centred. `NDrawerContent` composition (header/body/footer + close), the 3-state mask, the native-scrollbar seam (default: no scrollbar node, unlike Modal) and the resize trigger are DOM; the caller owns the show state, the transition clock, mask-click closing (`onMaskClick` — the mask is interactive here), Esc and the resize drag."
        (drawerRows model)


{-| Live: `#live-drawer` / `#live-drawer-tree` (the placement radios and `Open drawer` stay immediately before the cell; the `left` radio label is looked up globally first-match).
-}
drawerRow : Model -> Element Msg
drawerRow model =
    demoRow "ovr-041" "Drawer · placement picker" <|
        [ Radio.group theme
            { radioGD
                | value = Just model.drawerPlacement
                , onChange = Just DrawerPickPlacement
            }
            [ Radio.choice Drawer.Left "left"
            , Radio.choice Drawer.Right "right"
            , Radio.choice Drawer.Top "top"
            , Radio.choice Drawer.Bottom "bottom"
            ]
        , Button.view theme
            { btn | onPress = Just DrawerOpen }
            [ Element.text "Open drawer" ]
        , overlayCell "live-drawer" <|
            if model.drawerOpen then
                Drawer.view theme
                    (drawerOptions model.drawerPlacement)
                    [ DrawerContent.view theme
                        { drawerContentD
                            | title = Just (Element.text ("Placement: " ++ Drawer.placementName model.drawerPlacement))
                            , closable = True
                            , onClose = Just DrawerClose
                        }
                        [ Element.text "The mask click and the header ✕ are both live channels." ]
                    ]

            else
                Element.none
        , chip ("placement: " ++ Drawer.placementName model.drawerPlacement ++ " · " ++ model.drawerOutcome)
        ]


drawerLiveSection : Model -> Element Msg
drawerLiveSection model =
    section "Drawer"
        "The mount-body sibling of Modal — its own container/mask/host tree, edge-anchored (`position: absolute` per placement, the body transition family derived from it) instead of flex-centred. `NDrawerContent` composition (header/body/footer + close), the 3-state mask, the native-scrollbar seam (default: no scrollbar node, unlike Modal) and the resize trigger are DOM; the caller owns the show state, the transition clock, mask-click closing (`onMaskClick` — the mask is interactive here), Esc and the resize drag."
        (drawerRows model ++ [ drawerRow model ])


dialogState : List (DialogProvider.Item msg) -> Element msg
dialogState items =
    modalHost []
        (Element.column [] (DialogProvider.view theme { dialogPS | items = items }))


dialogRows : Model -> List (Element Msg)
dialogRows model =
    [ demoRow "ovr-042"
        "Kinds (bare body — the icon/type system)"
        [ cell
            (if model.dialogSamplesOpen then
                Dialog.view theme
                    { dialogD
                        | kind = T.Default
                        , title = Just (Element.text "Default")
                        , content = Just (Element.text "Info glyph on the base icon color.")
                        , positiveText = Just "OK"
                        , onPositiveClick = Just DialogSampleClose
                    }

             else
                Element.none
            )
        , cell
            (if model.dialogSamplesOpen then
                Dialog.view theme
                    { dialogD
                        | kind = T.Warning
                        , title = Just (Element.text "Warning")
                        , content = Just (Element.text "A warning icon rides the title.")
                        , positiveText = Just "Proceed"
                        , negativeText = Just "Cancel"
                        , onPositiveClick = Just DialogSampleClose
                        , onNegativeClick = Just DialogSampleClose
                    }

             else
                Element.none
            )
        , cell
            (if model.dialogSamplesOpen then
                Dialog.view theme
                    { dialogD
                        | kind = T.Error
                        , title = Just (Element.text "Error")
                        , content = Just (Element.text "Positive button keys to the kind.")
                        , positiveText = Just "Retry"
                        , negativeText = Just "Dismiss"
                        , onPositiveClick = Just DialogSampleClose
                        , onNegativeClick = Just DialogSampleClose
                    }

             else
                Element.none
            )
        ]
    , demoRow "ovr-043"
        "Modal dialog/confirm presets"
        [ modalHost []
            (Modal.view theme
                { modalD | show = model.modalDialogOpen }
                (Modal.Dialog
                    { dialogD
                        | title = Just (Element.text "Use dialog?")
                        , content = Just (Element.text "The preset body gains n-modal; .n-modal .n-dialog sizes it to 446px.")
                        , positiveText = Just "Confirm"
                        , negativeText = Just "Cancel"
                        , onPositiveClick = Just ModalDialogClose
                        , onNegativeClick = Just ModalDialogClose
                    }
                )
            )
        , modalHost []
            (Modal.view theme
                { modalD | show = model.modalConfirmOpen }
                (Modal.Confirm
                    { dialogD
                        | kind = T.Info
                        , title = Just (Element.text "A deprecated alias")
                        , content = Just (Element.text "confirm renders the identical body — only the constructor differs.")
                        , positiveText = Just "Got it"
                        , onPositiveClick = Just ModalConfirmClose
                    }
                )
            )
        ]
    , demoRow "ovr-044"
        "useDialog service (NUI.DialogProvider — fixed queues)"
        [ dialogState
            [ { dialogPI
                | key = "d1"
                , zIndex = Just 2000
                , options =
                    { dialogD
                        | kind = T.Warning
                        , title = Just (Element.text "Delete file?")
                        , content = Just (Element.text "A settled dialog — phase Nothing; the caller allocated z-index 2000.")
                        , positiveText = Just "OK"
                        , negativeText = Just "Cancel"
                    }
              }
            ]
        , dialogState
            [ { dialogPI
                | key = "d2"
                , phase = Just I.EnterActive
                , zIndex = Just 2000
                , options =
                    { dialogD
                        | kind = T.Info
                        , title = Just (Element.text "Entering")
                        , content = Just (Element.text "Mid-enter — the mask fades in, the body scales up from 0.5.")
                        , positiveText = Just "OK"
                        , negativeText = Just "Cancel"
                    }
              }
            , { dialogPI
                | key = "d3"
                , phase = Just I.LeaveActive
                , zIndex = Just 2001
                , options =
                    { dialogD
                        | kind = T.Error
                        , title = Just (Element.text "Leaving")
                        , content = Just (Element.text "Mid-leave — destroy stamped LeaveFrom; remove splices on after-leave.")
                        , positiveText = Just "OK"
                        , negativeText = Just "Cancel"
                    }
              }
            ]
        ]
    , demoRow "ovr-045"
        "icon-top, bordered, custom action"
        [ cell
            (if model.dialogSamplesOpen then
                Dialog.view theme
                    { dialogD
                        | kind = T.Success
                        , iconPlacement = Dialog.IconTop
                        , title = Just (Element.text "Centred")
                        , content = Just (Element.text "Icon-top swaps the margins and centres the icon above.")
                        , positiveText = Just "OK"
                        , onPositiveClick = Just DialogSampleClose
                    }

             else
                Element.none
            )
        , cell
            (Dialog.view theme
                { dialogD
                    | title = Just (Element.text "Bordered")
                    , bordered = True
                    , content = Just (Element.text "Opt back into the border.")
                    , action =
                        Just
                            [ Element.text "#action — the slot replaces the buttons"
                            ]
                }
            )
        ]
    , demoRow "ovr-046"
        "Loading + button-props overrides + dark"
        [ cell
            (Dialog.view theme
                { dialogD
                    | kind = T.Error
                    , title = Just (Element.text "Deleting…")
                    , content = Just (Element.text "Positive disabled+loading; the negative never loads.")
                    , positiveText = Just "Delete"
                    , negativeText = Just "Cancel"
                    , loading = True
                }
            )
        , cell
            (Dialog.view theme
                { dialogD
                    | title = Just (Element.text "Overrides")
                    , content = Just (Element.text "positiveProps updates the derived base (spread semantics).")
                    , positiveText = Just "Round primary"
                    , negativeText = Just "Round negative"
                    , positiveProps = Just (\b -> { b | round = True })
                    , negativeProps = Just (\b -> { b | round = True })
                }
            )
        , cell
            (Dialog.view darkTheme
                { dialogD
                    | kind = T.Warning
                    , title = Just (Element.text "Dark")
                    , content = Just (Element.text "modalColor surface, dark-common close/kind colors.")
                    , positiveText = Just "OK"
                }
            )
        ]
    ]


dialogSection : Model -> Element Msg
dialogSection model =
    section "Dialog"
        "A pure body component (upstream `NDialog`) — the `.n-dialog` card, never a mask or container. Standalone here, and as Modal's `dialog`/`confirm` preset bodies (the preset adds `n-modal` + `aria-modal`, phase class last). Composed actions (negative ghost/small first, positive small + kind-derived + loading), the kind→ icon/type system, icon-top placement, and the caller-owned runtime: the `useDialog` queue is ported as `NUI.DialogProvider` (fixed queues below — one caller-owned `State`, pure transforms, no clock: dialogs persist until destroyed), while close gating, mask/esc stay yours (see Modal)."
        (dialogRows model)


{-| Live: `#live-dialog` / `#live-dialog-tree` (the `Open dialog` trigger stays immediately before the cell).
-}
dialogRow : Model -> Element Msg
dialogRow model =
    demoRow "ovr-047" "Dialog · positive/negative" <|
        [ Button.view theme
            { btn | onPress = Just DialogOpen }
            [ Element.text "Open dialog" ]
        , overlayCell "live-dialog" <|
            if model.dialogOpen then
                Modal.view theme
                    { modalD
                        | show = True
                        , attributes = [ Element.htmlAttribute (HA.id "live-dialog-tree") ]
                    }
                    (Modal.Dialog
                        { dialogD
                            | title = Just (Element.text "Submit the report?")
                            , content = Just (Element.text "Every button fires its own channel — the outcome is below.")
                            , positiveText = Just "Submit"
                            , negativeText = Just "Not yet"
                            , closable = True
                            , onPositiveClick = Just DialogPositive
                            , onNegativeClick = Just DialogNegative
                            , onClose = Just DialogClose
                        }
                    )

            else
                Element.none
        , chip ("outcome: " ++ model.dialogOutcome)
        ]


dialogLiveSection : Model -> Element Msg
dialogLiveSection model =
    section "Dialog"
        "A pure body component (upstream `NDialog`) — the `.n-dialog` card, never a mask or container. Standalone here, and as Modal's `dialog`/`confirm` preset bodies (the preset adds `n-modal` + `aria-modal`, phase class last). Composed actions (negative ghost/small first, positive small + kind-derived + loading), the kind→ icon/type system, icon-top placement, and the caller-owned runtime: the `useDialog` queue is ported as `NUI.DialogProvider` (fixed queues below — one caller-owned `State`, pure transforms, no clock: dialogs persist until destroyed), while close gating, mask/esc stay yours (see Modal)."
        (dialogRows model ++ [ dialogRow model ])



-- LIVE VIEW HELPERS (moved verbatim from Live/Overlays.elm)


{-| A relative host stacking trigger + popover-family body — the `v-placement`
wrapper contract (`Popover.placementAttribute`), the body in normal flow like
the static sections' `popoverHost`.
-}
relHost : String -> Popover.Placement -> List (Element msg) -> Element msg
relHost id placement children =
    Element.column
        [ Popover.placementAttribute placement
        , Element.htmlAttribute (HA.attribute "style" "position:relative;padding:6px 0;")
        , Element.htmlAttribute (HA.id id)
        ]
        children


{-| The mount-body family cell (Main's `modalHost`): a
`transform: translate(0,0)` containing block confines the fixed
container/mask/body-wrapper trees, `overflow: hidden` clips the overlay to
the demo cell.
-}
overlayCell : String -> Element msg -> Element msg
overlayCell id content =
    Element.el
        [ Element.htmlAttribute (HA.id id)
        , Element.width (Element.px 320)
        , Element.height (Element.px 210)
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;transform:translate(0,0);overflow:hidden;border:1px solid #efeff5;border-radius:4px;background:#fafafc"
            )
        ]
        content


{-| What an unmounted overlay cell shows instead of empty gray: a muted
placeholder naming the mount point, so the cell reads as a preview host.
-}
overlayHint : String -> Element msg
overlayHint text =
    let
        typ =
            Typo.defaults
    in
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "display:flex;align-items:center;justify-content:center;text-align:center;padding:0 24px;color:#909399;font-size:12px"
            )
        ]
        (Typo.text Showcase.theme { typ | depth = Just 3, size = Just 12 } [ Element.text text ])


{-| The simulated outside-click seam: stops card-inner clicks from bubbling
to the container's `onClick` (which stands in for the port's caller-owned
mask click). The decoder's msg is a deliberate no-op in `update`.
-}
swallowClicks : Element.Attribute Msg
swallowClicks =
    Element.htmlAttribute
        (HE.stopPropagationOn "click"
            (Json.Decode.succeed ( ModalInsideClick, True ))
        )


btn : Button.Options msg
btn =
    Button.defaults


swD : Switch.Options msg
swD =
    Switch.defaults


radioGD : Radio.GroupOptions Drawer.Placement msg
radioGD =
    Radio.groupDefaults


dropdownMenu : List (Dropdown.Option Msg)
dropdownMenu =
    [ demoLeaf "edit" "Edit"
    , demoLeaf "duplicate" "Duplicate"
    , Dropdown.Divider { attributes = [] }
    , Dropdown.Option
        { key = "delete"
        , label = "Delete (disabled)"
        , icon = Nothing
        , disabled = True
        , children = Nothing
        , attributes = []
        }
    , Dropdown.Option
        { key = "others"
        , label = "Others (submenu)"
        , icon = Nothing
        , disabled = False
        , children =
            Just
                [ demoLeaf "nick" "Nick Carraway"
                , demoLeaf "tom" "Tom Buchanan"
                ]
        , attributes = []
        }
    ]


{-| The live drawer's options — sized on the placement's axis (width
left/right, height top/bottom), both close channels wired.
-}
drawerOptions : Drawer.Placement -> Drawer.Options Msg
drawerOptions placement =
    let
        sized =
            case placement of
                Drawer.Left ->
                    { drawerD | width = Just "200px" }

                Drawer.Right ->
                    { drawerD | width = Just "200px" }

                Drawer.Top ->
                    { drawerD | height = Just "120px" }

                Drawer.Bottom ->
                    { drawerD | height = Just "120px" }
    in
    { sized
        | show = True
        , placement = placement
        , onMaskClick = Just DrawerMaskClose
        , attributes = [ Element.htmlAttribute (HA.id "live-drawer-tree") ]
    }


loadingSummary : LoadingBar.State -> String
loadingSummary st =
    (if st.started then
        statusName st.status

     else
        "idle (unmounted)"
    )
        ++ " · "
        ++ String.fromFloat st.progress
        ++ "%"
        ++ (if st.kicked then
                " · kicked"

            else
                ""
           )
        ++ " · phase: "
        ++ phaseName st.phase


statusName : LoadingBar.Status -> String
statusName status =
    case status of
        LoadingBar.Starting ->
            "starting"

        LoadingBar.Finishing ->
            "finishing"

        LoadingBar.Erroring ->
            "erroring"


phaseName : Maybe I.TransitionPhase -> String
phaseName phase =
    case phase of
        Nothing ->
            "settled"

        Just I.EnterFrom ->
            "enter-from"

        Just I.EnterActive ->
            "enter-active"

        Just I.EnterTo ->
            "enter-to"

        Just I.LeaveFrom ->
            "leave-from"

        Just I.LeaveActive ->
            "leave-active"

        Just I.LeaveTo ->
            "leave-to"



-- FAMILY BODY (Main.body order — live variants where live demos exist)


{-| The family body in Main.body order — live variants where live demos
exist. Main.elm is not touched in this phase (the legacy static exports
stay wired there); the integration phase swaps this in.
-}
sections : Model -> List (Element Msg)
sections model =
    [ loadingBarLiveSection model
    , popoverLiveSection model
    , popconfirmLiveSection model
    , tooltipLiveSection model
    , dropdownLiveSection model
    , messageLiveSection model
    , notificationLiveSection model
    , modalLiveSection model
    , drawerLiveSection model
    , dialogLiveSection model
    ]
