# BRIEF — Live.Overlays (Dropdown, Popover, Tooltip, Popconfirm, Modal, Drawer, Dialog, Message, Notification, LoadingBar)

Read `tasks/brief-live-common.md` FIRST. FILE: `examples/src/Live/Overlays.elm`
(replace the stub). subscriptions = Sub.none.

This family is open/close + queue state. The port renders overlay bodies as ordinary
nodes (no portal runtime) — the static sections render them inline OPEN; your demos
toggle them CLOSED→OPEN via model state. Read how the static Main.elm renders each
(e.g. dropdownSection, popoverSection, modalSection, drawerSection, dialogSection,
messageSection, notificationSection, loadingBarSection) — copy those option records
and drive them from state.

Read first: `src/NUI/Dropdown.elm`, `src/NUI/Popover.elm`, `src/NUI/Tooltip.elm`,
`src/NUI/Popconfirm.elm`, `src/NUI/Modal.elm`, `src/NUI/Drawer.elm` +
`src/NUI/DrawerContent.elm`, `src/NUI/Dialog.elm` (+ `DialogProvider` if the demo
needs its queue), `src/NUI/Message.elm`, `src/NUI/Notification.elm`,
`src/NUI/LoadingBar.elm`.

DEMOS:
1. **Dropdown · trigger + menu** — Button trigger; click toggles; option click sets a
   caption AND closes. If Dropdown supports hover-trigger, a second demo with
   mouseenter/mouseleave channels.
2. **Popover · controlled** — open on trigger click, close via its action/close
   channel; a "controlled open" toggle beside it.
3. **Tooltip · hover** — Tooltip showing on hover (mouseenter/mouseleave if exposed,
   else a model toggle standing in for hover).
4. **Popconfirm · confirm flow** — open → onPositiveClick/onNegativeClick branches,
   outcome caption.
5. **Modal · open/close + mask** — button opens; close via onClose/onMaskClick (wire
   BOTH); content shows a counter that still updates while open.
6. **Drawer · placement picker** — Radio group picks placement (left/right/top/bottom
   as the port supports); open/close incl. onMaskClick.
7. **Dialog · positive/negative** — open → onPositiveClick/onNegativeClick/onClose
   each produce a distinct outcome caption.
8. **Message · queue** — three buttons push kinds (info/success/error) into
   Message.State (init/item + onClose/onLeave/onAfterLeave channels drive removal);
   render the queue where the static section renders it. Auto-dismiss via a simple
   "click to dismiss" + leave channels (no timers needed — Sub.none family; if the
   port's Message lifecycle expects caller timing, dismiss on click only and note it).
9. **Notification · queue** — same pattern; if the static section shows a
   transition-phase option, keep instances static-phase (no animation clocks here).
10. **LoadingBar · trigger** — buttons start/finish/error the bar per the port's
    loading state API (LoadingBar.State/Options — read the header); drive phases from
    model transitions on click (start → finishing → finish on subsequent clicks).
