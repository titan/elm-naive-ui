# BRIEF — Interactive Sections migration (shared constraints)

GOAL: The examples page keeps its 87 sections, but interactivity moves OUT of the
dedicated "Live · *" sections (examples/src/Live/*.elm) INTO the per-family
`examples/src/Sections/*.elm` modules. After this migration every component's demos
are interactive in place, and the six Live sections are deleted.

Full gate-hook recon: `tasks/recon/RECON-live-refactor-gate-hooks.md` (READ IT — §7 is
the checklist). Hard rules below are non-negotiable; they keep `tests/inspect.mjs`
(four live phases), `tools/verify/check-dom.mjs` and `scripts/verify.sh` green.

## Target module shape (every family module)

Each `Sections/<Family>.elm` ends up with BOTH APIs simultaneously (the dual API is
deliberate: Main.elm is NOT touched in this phase, so the interim build stays green):

```elm
module Sections.Controls
    exposing
        ( Model, Msg, init, update, subscriptions   -- merged from Live/Controls.elm
        , sections                                    -- NEW: full family body, live-aware
        , buttonSection, inputSection, ...            -- legacy static exports, UNCHANGED
        )

sections : Model -> List (Element Msg)   -- exact current body order, live sections swapped in
```

- Move the Live module's `Model`/`Msg`/`init`/`update`/`subscriptions`/helpers into the
  Sections module VERBATIM (same field names, same Msg constructors, same update logic,
  same subscriptions — including `Live/Pickers.elm`'s `Cmd`-returning update).
- For each section that gains live demos, add a live variant that reuses the static
  rows and appends the live rows, e.g.:
  ```elm
  buttonRows : List (Element msg)          -- extracted from the legacy section body
  buttonSection = section "Button" desc buttonRows                    -- unchanged export
  buttonLiveSection : Model -> Element Msg
  buttonLiveSection model = section "Button" desc (buttonRows ++ [ pressRow model ])
  ```
  Same section title/desc (the anchor id `sec-…` and the sidebar stay 1:1).
- `sections model` lists the family body in EXACTLY the current order, using the live
  variant for sections that have live demos and the legacy one elsewhere.
- Merge header doc comments (keep the Live module's oracle-divergence notes).
- Name collisions (e.g. both files bind `btn`, `tabsD`): keep ONE binding when
  identical; when the live one is `Msg`-typed and the static is polymorphic, prefer
  the polymorphic one and specialize at use sites. Rename only when values differ.

## HARD CONSTRAINTS (violating any breaks the gates)

1. **`#live-*` ids are sacred.** Move them verbatim; never rename, never re-prefix.
   `live-checkbox-item-1` is generated (`"live-checkbox-item-" ++ String.fromInt i`).
2. **A live demoRow's internal structure is frozen**: controls/captions stay siblings
   in the same parent, in the same order (controls BEFORE the cell they drive).
   `nearestPreceding` (inspect.mjs:11973) resolves controls by document order; captions
   are read via `parentElement.textContent` (`s2RowText`) and deepest-leaf matching
   (`s2LeafText`). Copy the Live module's row markup byte-for-byte; only the enclosing
   section changes.
3. **Button labels and caption strings stay unique page-wide** (global text lookups:
   `Show`, `Open modal`, `Open drawer`, `Open dialog`, `Close`, `info`, `success`,
   `clear`, `start`, `kick`, `finish`, `error`, `Not yet`, `Submit`, `Cancel`,
   `Confirm`, `Delete project…`, `Reset`, `Mask`, `+1`, `−1`, `lo +`, `hi −`,
   `Scroll up 120 px`, `Scroll down 120 px`, `hovered: …`, `committed: …`, etc.).
   Your static rows must not introduce colliding button text or leaf captions.
4. **Do not delete or make conditional any static demo row.** check-dom requires one
   always-rendered instance of every component root (especially `.n-modal-container`,
   `.n-popover`, `.n-popconfirm`, `.n-tooltip`, `.n-dropdown`, `.n-message-wrapper`,
   `.n-notification-wrapper`, `.n-loading-bar` — the static Overlay sections render
   them open from init; keep that).
5. **Do not touch**: `examples/src/Main.elm`, `examples/src/Live/*` (still imported by
   Main), `tests/**`, `tools/**`, `src/**`, `Showcase.elm`, other Sections modules.
6. New ids you introduce (only where genuinely needed) use the prefix `secf-` and must
   not collide with `live-*` or the `#live-*` set.
7. Live `subscriptions` must survive into the Sections module even if it looks unused
   in this phase (integration wires it later). `Live/Pickers`'s `Cmd` return type too.

## VALIDATION (all must pass in your worktree, from repo root)

```bash
export ELM_HOME="${ELM_HOME:-/tmp/elm-home}"
(cd examples && elm make src/Main.elm --output=index.html)   # interim page: identical to baseline
elm-format --validate examples/src/Sections/<YourFamily>.elm  # or --yes to format first
node tools/verify/check-dom.mjs examples/index.html           # 103 selectors, 0 MISSING
```

Do NOT run the full `tests/run.sh` (slow; integration phase owns it). Do not commit —
leave the working tree dirty; the orchestrator merges branches.

## REPORT BACK

- which sections gained which live rows (mapping table)
- any Live code you had to adapt (collision renames, helper moves) and why
- validation output tails (make ok / check-dom ok / elm-format ok)
