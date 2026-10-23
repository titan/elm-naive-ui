# Oracle audit — the six Live/* showcase modules

Scope: `examples/src/Live/{Controls,Nav,Motion,Overlays,Data,Pickers}.elm`,
`examples/src/Showcase.elm`, the Live seams of `examples/src/Main.elm`
(`Main.elm:131-195, 866-883`). master @ `274f863`. Upstream comparisons read
from the mounted `/home/titan/Works/elm/naive-ui` (v2.45.3). Read-only pass;
verify.sh not run (orchestrator owns the gate).

Method actually executed: every demo's update/view was read in full and
cross-checked against the `src/NUI/*.elm` API it drives (Slider
`stepValue`/`sanitizeValue`/`valueToPercentage`, InputNumber
`inputUpdate`/`deriveValueFromDisplayedValue`/`displayedValueInvalid`,
Menu `initialExpandedKeys`/`expandTo`/`keyPathTo`/`toggleExpanded`,
Pagination `pageCount`/`getDefaultPageSize`, Carousel's full exported state
machine + the root mousedown-through-`onTouchStart` gate, Log
`scrollEvents`/`wheelEvents`, LoadingBar `start/kick/finish/error`, Message /
Notification provider transforms, Modal `attributes`-on-container contract,
Tree treemate helpers, TreeSelect `handleNodeClick`/`deleteOption`/
`clearValue`, DatePicker `singleDateClick`/`dualDateClick`/`dualHover`/
`sanitizeValue`/`defaultActions`, ColorPicker `onUpdateShow` (emits only
`True`, ever — port-documented), AutoComplete clear-through-`onInput ""`).
Upstream semantics verified where the demos make claims: tabs close
(`addable.demo.vue` + `Tabs.tsx handleClose`), Pagination jumper
(`doQuickJump`, `handleJumperInput`), page-size change (`doUpdatePageSize` +
`mergedPage` clamp), Carousel hover-pause (`stopAutoplay`/`resetAutoplay`),
Steps clickability (`Step.tsx` `onUpdate:current`). The LIVE/OVR phase
(`tests/inspect.mjs:11915+`, 11 scenarios / 78 `ovlLiveOk` checks — counted)
was cross-checked line-by-line against `Live/Overlays.elm`.

---

## S — must fix

### S1 · Nav — closing a background tab steals activation

`Live/Nav.elm` `TabClose` unconditionally reassigns
`activeTab = activeAfterClose name model.tabs` (`Nav.elm:161-165`).

Upstream's own addable/closable demo reassigns the value **only when the
closed tab is the active one**:

```js
// naive-ui src/tabs/demos/enUS/addable.demo.vue handleClose
panels.splice(nameIndex, 1)
if (name === valueRef.value) {                       // ← the guard
  valueRef.value = panels[Math.min(nameIndex, panels.length - 1)]
}
```

`activeAfterClose` itself is faithful (same-index replacement, else last),
but without the guard: with tabs `[docs, demos, api]`, active `docs`,
closing the background `demos` re-activates to `api`. A naive-ui user's
expectation — closing a background tab never moves the selection — is
misrepresented, and the demo caption (`active: …`) makes the wrong value
visible.

Proof of order-safety under the port's documented close-click double-fire
(`NUI/Tabs.elm:48-49`: close click does not stopPropagation, so `TabClose`
fires at the button, then `TabChange` bubbles at the tab): DOM dispatch is
inner-first, so the sequence is always `[TabClose name, TabChange name]`.

- background close: `TabClose` updates `tabs`, leaves `activeTab`;
  `TabChange name` finds `name` gone → guard no-ops. ✓
- active close: `TabClose` moves activation to the neighbour; `TabChange`
  no-ops. ✓ (Same outcomes if the order were ever reversed.)

Minimal fix (one branch):

```elm
TabClose name ->
    { model
        | tabs = List.filter (\t -> t.name /= name) model.tabs
        , activeTab =
            if model.activeTab == name then
                activeAfterClose name model.tabs

            else
                model.activeTab
        }
```

Smoke impact: **none.** No LIVE/OVR scenario touches Nav; the tests-page
fixtures in `tests/src/Main.elm` are a separate page; eq/DOM pins are
port-level and the fix changes no initial state. The comment above
`TabChange` ("whichever order the two messages arrive in, closing wins")
stays true and should be kept.

No other S findings: the other five modules drive the port contracts
faithfully (worked checks in the method paragraph above); overlays start
closed exactly as the LIVE/OVR boot asserts; all subscriptions are gated
(`Sub.none` everywhere except Motion, whose five clocks are each scoped to
live state); no channel is wired to a dead update (the one deliberate no-op,
`ModalInsideClick`, is the documented stopPropagation seam).

---

## D — document (accepted simplifications / divergences)

Each gets a one-liner for the module docstring.

**Live/Nav**

- `[oracle D]` **Jumper input keeps raw text.** Upstream strips `\D+` at
  input (`Pagination.tsx handleJumperInput`); the demo stores the raw draft
  and `String.toInt` no-ops on garbage (commit then neither jumps nor clears
  — same visible outcome as upstream's NaN early-return).
- `[oracle D]` **PageSize clamp, not reset.** `PageSizeSet` clamps the page
  to the new `pageCount` (upstream's `mergedPage` watcher semantics). See
  D·Data-2 for the twin lane that resets instead.

**Live/Controls**

- `[oracle D]` **Rate hover is button-simulated.** Upstream's hover preview
  is pointer-position algebra inside the port's rendering seam; the demo's
  ±½ buttons drive the same `hoverValue` field the port reads.
- `[oracle D]` **Range handles can cross.** "lo +" steps past `hi` produce
  `lo > hi` (upstream swaps handle identity on crossing); the port ships no
  range-ordering helper — drag runtime is caller-owned by contract — and the
  render self-heals (`fillNode` spans `min..max` of the arrified value).

**Live/Motion**

- `[oracle D]` **Autoplay clock is free-running.** Upstream
  `stopAutoplay`/`resetAutoplay` on hover pause/resume *restarts* the full
  interval on un-hover; the demo's `Time.every interval` may fire sooner
  after un-pausing. Hover-pause itself is faithful.

**Live/Overlays**

- `[oracle D]` **Appear phase is settled at push.**
  `settleMessage`/`settleNotification` clear `EnterFrom` in the same update
  (no caller clock in this family) — items render instantly visible. This
  is *load-bearing* for LIVE/OVR ("created messages are VISIBLE (appear
  settled)"). Keep.
- `[oracle D]` **Two-beat close replaces the timer.** Close-click 1 =
  `destroy` (leave stamped), click 2 = `remove`; `clear` =
  `destroyAll` then fold-`remove`. Documented in-module; matches the smoke.

**Live/Data**

- `[oracle D]` **One node click drives expand + select + check.** Upstream
  separates switcher / checkbox / node click (`checkOnClick` is the one
  legitimate fold); the port's switcher/checkbox are display-only, so the
  nodeProps seam carries all three. Already in the module docstring.
- `[oracle D]` **DtPageSize resets page to 1.** Upstream clamps
  (`mergedPage` watcher); Nav's twin demo clamps. With 8 rows / ≤2 pages
  the two recipes are observationally identical here — align to the clamp
  (or comment) when next touched.

**Live/Pickers**

- `[oracle D — resolved 2026-11]` **AutoComplete hides the empty-state
  menu.** `acMenuOpen` required non-empty matches, so the menu's configured
  `empty = Just "No match"` slot was unreachable; upstream shows the
  empty-state menu while focused with text. RESOLVED: the gate now mirrors
  the frozen upstream formula (`showOptions && canBeActivated &&
  (showEmpty || options non-empty)`, `AutoComplete.tsx:193-207`) through
  `acGate`; the live row keeps the default gate (no menu on zero matches)
  and its second cell runs the same gate with `showEmpty = True`
  (`onFocus`/`onBlur` seams added to `NUI.AutoComplete.Options` for
  `canBeActivated`). (The Mention row in the same module mounts its `empty`
  slot correctly.)
- `[oracle D]` **`dpSingleCloses` re-runs `singleDateClick` against
  `Single Nothing`.** Sound — the helper's `close` is type-only
  (`List.member type_ [Date, Week, Year]`, `DatePicker.elm:693`) and the
  demo discards the re-derived value — but the reconstruction deserves the
  comment it half-has.

---

## R — risks / notes

- **R1 · The pure-update seam is the family contract.** `Main.update :
  Msg -> Model -> Model` (no Cmd anywhere in the six modules). The demos
  compensate with click-clocked state machines (Message two-beat, Upload
  "Advance progress", LoadingBar manual clock). Any future Live demo needing
  real effects must either stay in this idiom or change Main's seam — don't
  let a fixer "just add a Cmd".
- **R2 · Two page-size recipes live in the tree** (Nav clamp vs Data
  reset). Pick the clamp (upstream semantics) when either is next edited.
- **R3 · Crossed range handles** (D·Controls-2): if ever promoted, either
  hand-roll the swap in the demo or surface a port helper — don't fork
  `sanitizeValue` locally.
- **R4 · `valueKey` reads only the head of a `Multiple`.** The Pickers
  captions for multi-value demos under-report (single tag shown). Extenders
  should switch captions to `valueKeys`.
- **R5 · Smoke promotion candidates.** The strongest next LIVE phases, in
  order: (a) Controls/InputNumber — the buffer/commit/invalid loop is pure
  and captioned (`numberCaption` already prints value · buffer · valid);
  (b) Motion/Carousel — arrows/dots/wheel are pure `carStep`s; drag needs
  the 20 ms tick clock but jsdom's `pretendToBeVisual` handles that;
  (c) Pickers/DatePicker daterange — `dualDateClick`/`dualHover` two-click
  flow is exactly the LIVE/OVR pattern (open state in model, no timers).
- **R6 · Lane-thinness check.** All six inventories from the brief are
  present and wired; none reads as under-reviewed (Controls is smallest at
  724 L but delegates to port algebra everywhere it exists). The broken-
  provider spawn from lane history left no thin module in the tree as it
  stands today.
- **R7 · Overlays' `pushNotification` "evicted" caption** is inferred from
  "any item leaving after push" — it can mislabel when an item was already
  leaving from a manual close. Caption-only; the eviction itself is the
  port's `create` transform and is smoke-pinned.

---

## Per-module verdicts

| Module | Verdict |
| --- | --- |
| Live/Controls | **Honest.** Every port helper that exists is used (`stepValue`, `inputUpdate`, `deriveValueFromDisplayedValue`); state fields match the port's caller-owned contract one-for-one. D-notes only. |
| Live/Nav | **One real misrepresentation (S1)**; otherwise exemplary — the accordion recipe, Menu seeding via `initialExpandedKeys`, jumper clamp+clear, BackTop 180px default are all upstream-faithful. |
| Live/Motion | **Honest and the strongest engineering** — five gated clocks, document-drag only while dragging, full delegation to the Carousel/Log state machines, `Time.posixToMillis` delta clocks that don't drift. |
| Live/Overlays | **Honest and smoke-locked.** All 78 LIVE/OVR assertions trace to real update branches; the no-timer compensations (two-beat close, manual LoadingBar ladder) are documented and the smoke depends on them. |
| Live/Data | **Honest.** The two channel-less ports (Table, Tree) are driven through their documented seams, not faked channels; every port interaction helper runs in update. Two D-notes. |
| Live/Pickers | **Honest with one cosmetic dead-end** (AutoComplete empty slot unreachable); the hard algebra (DatePicker dual-click/hover/sanitize, Cascader/TreeSelect/Select toggles, ColorPicker undo/redo stack) is all port-delegated and correctly staged. |

**Overall:** the showcase is honest as a port showcase — it demonstrates
the ports' caller-owned-state contracts the way the port docstrings
promise, and its simplifications are almost all self-documented at the
point of divergence. Exactly one fix is owed (S1, three lines in
`Live/Nav.elm`); everything else is comment-grade. No LIVE/OVR assertion
is affected by any suggested change, and D·Overlays-1 must be preserved
when the family ever gains a real timer.

*— oracle lane, single pass, `tasks/recon/live-oracle.md`*
