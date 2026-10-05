# BRIEF — Live.Nav (Tabs, Collapse, Menu, Pagination, Steps, Anchor, BackTop, Split)

Read `tasks/brief-live-common.md` FIRST. FILE: `examples/src/Live/Nav.elm`
(replace the stub). subscriptions = Sub.none.

Read first: `src/NUI/Tabs.elm`, `src/NUI/Collapse.elm`, `src/NUI/Menu.elm`,
`src/NUI/Pagination.elm`, `src/NUI/Steps.elm`, `src/NUI/Anchor.elm`,
`src/NUI/BackTop.elm`, `src/NUI/Split.elm` (headers + Options + exposed helpers,
e.g. Tabs has onAdd/active-name state, Collapse expandedNames, Menu
activeKey/expandedKeys + onNodeClick/onExpandedKeysChange, Pagination page/pageSize
channels, Steps current, Anchor activeHref, BackTop onClick, Split
onDragStateChange/size).

DEMOS:
1. **Tabs · live tab bar** — active name in model (click tab switches pane content);
   closable tabs actually close (add/remove via onAdd/onDelete if exposed — onAdd at
   minimum); a "+ add tab" if the port exposes it.
2. **Collapse · accordion vs multiple** — two Collapse demos: one accordion mode
   (single expanded), one multiple; toggling via onToggle updates expandedNames.
3. **Menu · navigate** — Menu with expandable sub-items (onExpandedKeysChange) and
   active item (onNodeClick); show the active key.
4. **Pagination · page + size** — page state; page change and page-size change both
   update a caption ("page 3 / 8, 20 per page"). Jumper input too (onJumperInput).
5. **Steps · wizard** — 3-step wizard: Next/Prev buttons drive `current`; a Step
   click jumps if the port allows.
6. **Anchor · simulated scroll** — buttons switch activeHref; the rail highlights the
   active link (this is the caller-owned scroll state pattern — simulate it).
7. **BackTop · simulated scroll** — model holds a fake scrollTop; clicking scrolls it
   back to 0, visibility = scrollTop > threshold; onClick channel wired.
8. **Split · drag** — Split with pane size in the model; onDragStateChange (+
   onMousedown channels if exposed) updates the split position from… NOTE: real
   pointer tracking needs subscriptions — since this family is Sub.none, drive the
   size with +/- buttons and a slider-like pair of buttons, and note that real drag
   is the Motion family's pattern. If Split's API makes a no-sub drag impossible,
   buttons-only is acceptable.
