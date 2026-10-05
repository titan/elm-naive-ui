# BRIEF — oracle audit: the six Live/* showcase modules

You are the ORACLE lane: read-only auditor. Workspace:
`/home/titan/Works/elm/elm-naive-ui`, master @ `274f863`. Upstream (read-only):
`/home/titan/Works/elm/naive-ui` (v2.45.3).
DO NOT edit src/, examples/, tests/, tools/. DO NOT commit. Your only output
file: `tasks/recon/live-oracle.md`.

⚠ SESSION GUARD: single pass; no repeat expensive reads. Do NOT run
verify.sh (≈5 min; the orchestrator owns the gate).

## Audit object (~6.6k L of demo code + wiring)
`examples/src/Live/Controls.elm` (724), `Live/Nav.elm` (752),
`Live/Motion.elm` (1002), `Live/Overlays.elm` (1092), `Live/Data.elm` (1562),
`Live/Pickers.elm` (1434), `examples/src/Showcase.elm` (82), and the
Browser.element integration in `examples/src/Main.elm` (the Live dispatch
seams only — the 87 static sections are out of scope and MUST stay).

These are EXAMPLES, not the port. The audit lens is **demo semantics vs port
contracts**: does each demo drive `src/NUI/*.elm` the way the port's API
promises, and does the resulting behavior match what a naive-ui user would
expect from the upstream demos?

Per-lane inventory (from git log `731b237..6721ea1`, 6 commits):
Controls (Button counter, Input single+pair+clear, InputNumber, Switch,
Checkbox all+indeterminate, Radio.Group, Rate hover/commit, Slider
single+range, InputOtp), Nav (Tabs live+add/close, Collapse accordion vs
multiple, Menu expand+active, Pagination page/size/jumper, Steps wizard,
Anchor simulated scroll, BackTop threshold, Split), Motion (Carousel ×2
autoplay/arrows/dots/wheel/drag, Log scroll-load, Countdown ×2,
NumberAnimation, Progress ×2, Spin, Skeleton, Marquee), Data (DataTable
selection+sort+pagination, Tree check/expand/select, Transfer move+filter,
Calendar panel+date, Image→Preview, ImageGroup, Upload simulated,
DynamicInput/DynamicTags, Form validate+submit, Table Row.attributes),
Overlays (Dropdown, Popover, Tooltip, Popconfirm, Modal, Drawer, Dialog,
Message/Notification queues, LoadingBar), Pickers (Select, Popselect,
Cascader, TreeSelect, AutoComplete, Mention, DatePicker single+daterange,
TimePicker, ColorPicker).

## Method
1. **Port-contract cross-check**: for each demo, read the corresponding
   `src/NUI/*.elm` API surface it calls. Flag: hand-rolled logic that shadows
   algebra the port already owns (e.g. reimplementing
   DatePicker.singleDateClick/dualDateClick, Carousel.dragEnd,
   Log.scrollEvents, provider queue transforms instead of using them);
   misuse of port Options/State (fields driven the port ignores, or state the
   demo never lets the port see); channels wired to no-op updates.
2. **Upstream behavior comparison**: the mounted naive-ui tree's demo/play
   files (`/home/titan/Works/elm/naive-ui/src/*/demos/*.demo.vue` or
   `docs/demo/**`) define expected interaction semantics. Demos may simplify
   (showcase, not port) — but semantics that MISREPRESENT the component
   (wrong commit timing, wrong close behavior, wrong queueing) are findings.
3. **Elm-correctness scan**: update loops (no stuck states, filters applied
   where the demo claims), subscriptions (Carousel autoplay Time.every,
   Browser.Events drag/focus — subscribed only while relevant), Cmd usage,
   initial models (overlays start CLOSED — required by the smoke).
4. **Smoke coupling**: `tests/inspect.mjs` has a standing LIVE/OVR phase (11
   scenarios, 78 `LIVE/OVR:` checks) that drives the Overlays demo through
   the real update loop. Cross-check those scenarios against
   Live/Overlays.elm behavior. EVERY finding gets a "smoke impact" note:
   would the natural fix change/break any LIVE/OVR assertion?
5. Empirical where cheap: `elm repl` (ELM_HOME=/tmp/elm-home) for pure
   helper algebra; `node` for pure JS-side derivations. No page builds.

## Report format (tasks/recon/live-oracle.md)
- **S** (must fix): demo actively wrong vs port contract — misdrives the API,
  misrepresents component semantics, or contains a real update/subscription
  bug. Worked proof + suggested minimal fix + smoke impact.
- **D** (document): accepted simplifications/divergences — each gets a
  suggested one-line `[oracle D]` comment for the module.
- **R** (risk/notes): latent traps, demo patterns that will bite future
  maintainers, candidates for promoting other lanes' smokes.
- Per-module verdict + an overall verdict on the showcase's honesty as a
  port showcase.

## Known context (verify, don't trust)
- The showcase is 87 static sections (check-dom surface, 100 roots) + six
  Live families; static sections deliberately keep always-open overlay/panel
  instances — that asymmetry is by design, not a finding.
- Overlays is the only lane whose smoke got promoted; the others are covered
  by eq/DOM pins + check-dom only.
- Lane history: one spawn in six silently fell back to a broken provider —
  treat any suspiciously thin module as possibly under-reviewed and note it.
- Main.elm is 5,884 L (static sections live there); a split is a separate
  unqueued candidate — do NOT audit the 87 sections.
