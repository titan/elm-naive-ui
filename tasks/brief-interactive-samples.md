# BRIEF — Phase 2: wire the samples themselves (every demo row interactive)

GOAL: In every `examples/src/Sections/*.elm`, the STATIC demo rows — the ones
that were kept inert in phase 1 — must now be driven by the module's Model so
they respond to user input in place. The phase-1 "live rows" (the appended
`#live-*` rows) stay EXACTLY as they are (test hooks); this phase upgrades the
rows ABOVE them.

## Core technique: state-drive with identical init

Each static row that renders a stateful component gets its own Model field(s),
initialized to the CURRENT static literal values, and every Options channel is
wired to a Msg constructor:

    -- before
    demoRow "Basics"
        [ Input.view theme { inputD | value = "Hello" } ]

    -- after
    demoRow "Basics"
        [ Input.view theme
            { inputD | value = model.basicText, onInput = Just BasicInput }
        ]
    -- Model: basicText = "Hello"   Msg: BasicInput String

Because init == the old literals, the INITIAL rendered DOM is byte-identical.
The component itself is the feedback (typed text, toggled switch, switched tab,
expanded panel, selected item) — do NOT add captions/labels to show state.

## HARD RULES

1. **Initial DOM byte-identical.** init values == current literals; same
   wrappers, widths, ids, attrs, demoRow labels, row order. No new text nodes.
   No new ids (skip `secf-` — not needed; feedback is the component itself).
2. **Wire every channel that exists** on stateful components: onInput, onBlur,
   onFocus, onChange/onCheck, onToggle, onSelect, onExpandedKeysChange,
   onUpdatePage, onJumperInput, onClose (tab/tag), onAdd, onPress (where a
   press has visible meaning, e.g. clearable input's clear already works via
   onInput), onUpdateValue, onUpdateShowMenu, onBack, etc.
3. **Deliberate state-showcase rows stay fixed** — rows whose PURPOSE is a
   pinned state keep it: `disabled`, `loading`, `readonly`, Slider's
   pinned-drag/hover indicator rows, Menu's "fixed state" rows, Pin OPEN menu
   demos in Pickers that exist to show the open panel (wire their interactive
   siblings instead). Rule of thumb: if the demoRow label says what state it
   shows ("Disabled", "Loading", "Tooltip indicator (pinned…)", "Vertical +
   reverse", "fixed state"), it is a specimen — leave it. If the label names a
   variant/behavior ("Basics", "Sizes", "Types", "Line clamp 2", "Bar
   (default)"), it must respond.
   EXCEPTION: Pickers' open-menu specimens may keep rendering open at init but
   SHOULD wire trigger click → close (value/open in model, init open).
4. **Don't touch**: the phase-1 live rows (appended `#live-*` rows) and their
   helpers; `Main.elm`; `Showcase.elm`; `tests/**`; `tools/**`; `src/**`.
5. **No Msg/field name collisions** within the module; new Msg constructors
   named after the demo (e.g. `TabsCardChanged`, `SelSinglePicked`).
6. Multi-instance rows (e.g. "Sizes" showing Small/Medium/Large tabs) can share
   ONE model field (all instances reflect the same value) — that is fine and
   keeps the demo coherent; per-instance fields only when values must differ
   (e.g. Switch row shows False AND True instances: one shared `Bool` cannot
   show both — keep such contrast rows pinned to their contrasting literals
   ONLY if wiring would homogenize them; otherwise wire the FIRST instance and
   keep the rest as specimens. Prefer: wire instances whose current value is
   "neutral/default"; keep non-default specimens fixed).
7. `update` stays pure (`Sections.Pickers` keeps its Cmd signature — extend,
   don't change it). `subscriptions` unchanged.

## VALIDATION (worktree, from repo root)

```bash
export ELM_HOME=/tmp/elm-home
(cd examples && elm make src/Main.elm --output=index.html)   # must compile
elm-format --yes examples/src/Sections/<Family>.elm
# from the MAIN checkout (has node_modules):
node /home/titan/Works/elm/elm-naive-ui/tools/verify/check-dom.mjs <abs-worktree>/examples/index.html
# → 100 components, 0 failures  (initial DOM preserved)
```

Do NOT commit. REPORT: per-section list of rows wired vs rows left as
specimens (with the reason), validation tails.
