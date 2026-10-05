# BRIEF — Live.Pickers (Select, Popselect, Cascader, TreeSelect, AutoComplete, Mention, DatePicker, TimePicker, ColorPicker)

Read `tasks/brief-live-common.md` FIRST. FILE: `examples/src/Live/Pickers.elm`
(replace the stub). subscriptions = Sub.none.

This is the state-heavy family: every picker has an OPEN state (menu/panel show) owned
by the caller + a VALUE. Read each module header — several ports expose the open/close
state as an Option (e.g. `show`/`showMenu` fields) and pure helpers for the panel
algebra. DatePicker and TimePicker are the big ones: their click/format algebra is
exposed as pure helpers (`defaultActions`, `sanitizeValue`, `singleDateClick`,
`dualDateClick`, `dualHover`, `colItemClick`, `quickMonthClick` …) — USE them in update.

Read first: `src/NUI/Select.elm` + `src/NUI/SelectMenu.elm`, `src/NUI/Popselect.elm`,
`src/NUI/Cascader.elm`, `src/NUI/TreeSelect.elm`, `src/NUI/AutoComplete.elm`,
`src/NUI/Mention.elm`, `src/NUI/DatePicker.elm`, `src/NUI/TimePicker.elm`,
`src/NUI/ColorPicker.elm`. Also skim `examples/src/Main.elm`'s static picker sections
for the exact option-shape idioms (they render menus OPEN — copy their option records,
then drive them from state).

DEMOS:
1. **Select · single** — trigger + menu; click item → value set + menu closes
   (toggle open on trigger click). Show selected label.
2. **Select · multiple** — tags accumulate/delete (onDeleteTag channel if exposed).
3. **Popselect · value** — Popselect over 3 options, selected shown next to it.
4. **Cascader · drill** — a 2-level option tree (e.g. province → city); open on click,
   hovering/expanding levels per the port's onHover/onToggle channels, commit leaf →
   show the path.
5. **TreeSelect · pick node** — small tree, open/close + select.
6. **AutoComplete · filter** — input filters a static suggestion list (onInput →
   pattern in model → menu shows matches); pick → input set.
7. **Mention · @ trigger** — detect "@" in the input to open the menu; insert choice.
8. **DatePicker · single panel** — trigger opens the date panel; date clicks go
   through the exposed click-algebra helpers; formatted value shown. Include the
   month/quick-jump panel only if the helpers make it tractable.
9. **DatePicker · daterange** — pair trigger (pairValue/onPairInput), dualDateClick
   algebra, show both ends.
10. **TimePicker · columns** — open panel, column item clicks, confirm; show value.
11. **ColorPicker · full loop** — open panel, mode/value/undo/redo channels
    (onUpdateShow/onUpdateMode/onUpdateValue/onUndo/onRedo/onConfirm/onClear), show
    the committed color as a swatch + hex text.

Keep each picker's open state independent in the Model (record fields per component).
If a component's open state is NOT an Option (i.e. the menu is a separate root you
render conditionally — see how the static showcase renders `Select.menuDefaults`
alongside `Select.defaults`), then render `trigger` always and the menu/panel node
only when open.
