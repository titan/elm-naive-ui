module Live.Overlays exposing (Model, Msg, init, subscriptions, update, view)

{-| LIVE demos — a real update loop for the overlays family: Dropdown,
Popover, Tooltip, Popconfirm, Modal, Drawer, Dialog, Message, Notification,
LoadingBar.

This family is open/close + queue state, all caller-owned per the port's
contract (no portal runtime): the static sections render the always-open
instances; these demos toggle them CLOSED → OPEN from the model.

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
  - **LoadingBar** is a pure state machine the caller steps — the buttons are
    the animation frames (`start`/`kick`/`finish`/`error` + the enter/leave
    phase ladder).

-}

import Element exposing (Element)
import Element.Events
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode
import NUI.Button as Button
import NUI.Card as Card
import NUI.Dialog as Dialog
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
import NUI.Theme exposing (Theme)
import NUI.Tooltip as Tooltip
import NUI.Types as T
import Showcase exposing (chip, demoRow)



-- MODEL


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
    }



-- UPDATE


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



-- VIEW


view : Theme -> Model -> Element Msg
view theme model =
    Element.column
        [ Element.spacing 20, Element.width Element.fill ]
        [ demoRow "Dropdown · click trigger" <|
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
        , demoRow "Dropdown · hover trigger" <|
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
        , demoRow "Popover · controlled" <|
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
                        { popD
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
        , demoRow "Tooltip · hover" <|
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
                        { tipD
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
        , demoRow "Popconfirm · confirm flow" <|
            [ relHost "live-popconfirm"
                Popover.Top
                [ Button.view theme
                    { btn | kind = T.Error, onPress = Just PopconfirmToggle }
                    [ Element.text "Delete project…" ]
                , if model.popconfirmOpen then
                    Popconfirm.view theme
                        { confirmD
                            | popover = { popD | width = Just "240px" }
                            , onPositiveClick = Just PopconfirmPositive
                            , onNegativeClick = Just PopconfirmNegative
                        }
                        [ Element.text "Delete the whole project?" ]

                  else
                    Element.none
                ]
            , chip model.popconfirmOutcome
            ]
        , demoRow "Modal · open/close + mask" <|
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
                    Element.none
            , chip model.modalOutcome
            ]
        , demoRow "Drawer · placement picker" <|
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
        , demoRow "Dialog · positive/negative" <|
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
        , demoRow "Message · queue (click-to-dismiss clock)" <|
            [ Button.view theme { btn | onPress = Just MessageInfo } [ Element.text "info" ]
            , Button.view theme { btn | kind = T.Primary, onPress = Just MessageSuccess } [ Element.text "success" ]
            , Button.view theme { btn | kind = T.Error, onPress = Just MessageError } [ Element.text "error" ]
            , Button.view theme { btn | size = T.Small, onPress = Just MessageClear } [ Element.text "clear" ]
            , overlayCell "live-message-queue" (Message.view theme model.messages)
            , chip model.messageOutcome
            ]
        , demoRow "Notification · queue (max 3)" <|
            [ Button.view theme { btn | onPress = Just NotificationInfo } [ Element.text "info" ]
            , Button.view theme { btn | kind = T.Primary, onPress = Just NotificationSuccess } [ Element.text "success" ]
            , Button.view theme { btn | kind = T.Error, onPress = Just NotificationError } [ Element.text "error" ]
            , Button.view theme { btn | size = T.Small, onPress = Just NotificationClear } [ Element.text "clear" ]
            , overlayCell "live-notification-queue" (Notification.view theme model.notifications)
            , chip model.notificationOutcome
            ]
        , demoRow "LoadingBar · manual clock" <|
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
        ]



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


btn : Button.Options msg
btn =
    Button.defaults


swD : Switch.Options msg
swD =
    Switch.defaults


radioGD : Radio.GroupOptions Drawer.Placement msg
radioGD =
    Radio.groupDefaults


popD : Popover.Options msg
popD =
    Popover.defaults


tipD : Tooltip.Options msg
tipD =
    Tooltip.defaults


confirmD : Popconfirm.Options msg
confirmD =
    Popconfirm.defaults


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


lbD : LoadingBar.Options msg
lbD =
    LoadingBar.defaults


messageD : Message.Options msg
messageD =
    Message.defaults


notificationD : Notification.Options msg
notificationD =
    Notification.defaults


messageS : Message.State msg
messageS =
    Message.init


notificationS : Notification.State msg
notificationS =
    Notification.init



-- VIEW HELPERS


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
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;transform:translate(0,0);height:210px;width:320px;overflow:hidden;border:1px solid #efeff5;background:#fafafc"
            )
        ]
        content


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


dropdownMenu : List (Dropdown.Option Msg)
dropdownMenu =
    [ dropdownLeaf "edit" "Edit"
    , dropdownLeaf "duplicate" "Duplicate"
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
                [ dropdownLeaf "nick" "Nick Carraway"
                , dropdownLeaf "tom" "Tom Buchanan"
                ]
        , attributes = []
        }
    ]


dropdownLeaf : String -> String -> Dropdown.Option Msg
dropdownLeaf key label =
    Dropdown.Option
        { key = key
        , label = label
        , icon = Nothing
        , disabled = False
        , children = Nothing
        , attributes = []
        }


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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
