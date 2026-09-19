# Architecture & conventions

`elm-naive-ui` rebuilds [Naive UI](https://www.naiveui.com) components on top of
[elm-ui](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/), aiming for
the **same display effect** as the original.

## How fidelity is achieved

Naive UI styles a component from two inputs:

1. **Static structure CSS** — BEM rules like `.n-button { display:inline-flex; … }`,
   including `:hover` / `:focus` / `:active` / `:disabled` states and transitions.
2. **Themed values** — inline `--n-*` CSS custom properties, derived from the theme
   (`self(commonVars)` in Naive UI).

This project reproduces both, so what the browser renders is Naive UI's own CSS:

- `css/naive-ui.css` (and the embedded `NUI.Css.Generated`) contains Naive UI's **exact**
  CSS, generated from its `cssr` sources by `tools/` — not hand-written.
- Each component attaches the same BEM classes **and** an inline `style` carrying the
  same `--n-*` custom properties, computed in Elm from `NUI.Theme.<Comp>.vars`.

### Beating elm-ui's own classes

elm-ui renders elements with helper classes (`.s`, `.s.r`, `.s.e`, `.ui`, `.hc`, …) that
declare `display`, `flex-direction`, `flex-basis`, `white-space`, `padding`, `color`, …
This would fight Naive UI's rules. Two mechanisms resolve it:

- Every generated Naive UI rule is scoped under `.nui-root.nui-root ` (two identical
  class selectors) so it always out-specifies elm-ui's class rules. The app root must
  therefore carry the `nui-root` class — `NUI.Css.layout` adds it, and `NUI.Css.element`
  renders the stylesheet node.
- `tools/bridge.css` restores browser defaults for the two properties Naive UI does
  **not** declare but elm-ui changes: `flex-basis` and `white-space`.

**Do not edit `css/naive-ui.css`, `src/NUI/Css/Generated.elm`, or `tools/bridge.css`
per-component.** If a component needs an extra bridge rule, note it in the PR/task
summary so it can be added centrally.

## Module layout

```
src/
  NUI/Types.elm            Kind, Size (public enums) + kindClass/sizeClass
  NUI/Internal.elm         classes / classIf / cssVars helpers
  NUI/Css.elm              stylesheet + `layout` / `rootAttribute`
  NUI/Css/Generated.elm    GENERATED — do not edit
  NUI/Theme.elm            Theme = { mode, common }, default/dark/setPrimary
  NUI/Theme/Common.elm     GENERATED — common vars (light/dark)
  NUI/Theme/<Comp>.elm     GENERATED — component vars: `vars : Theme -> Vars`
  NUI/<Comp>.elm           the component
```

Generated theme modules map each component variable either to a `common` field (so theme
overrides propagate) or to a literal. Regenerate everything with `cd tools && npm run extract`.

## Component conventions

Model each component on `src/NUI/Button.elm`.

- **API**: an `Options msg` record plus `defaults : Options msg` and
  `view : Theme -> Options msg -> List (Element msg) -> Element msg`.

  ```elm
  NUI.Button.view theme { NUI.Button.defaults | kind = T.Primary } [ Element.text "Ok" ]
  ```

- **Theme vars**: `NUI.Theme.<Comp>.vars theme` gives the component's `Vars`; read the
  exact fields Naive UI's `cssVars` uses. Port that logic faithfully from
  `src/<comp>/src/<Comp>.tsx` (`cssVarsRef`) — do not invent values.
- **Classes**: copy the class list from the original `render()` (e.g.
  `.n-button--{size}-type`), including ones not present in the CSS — they cost nothing
  and keep parity with other components / button groups.
- **Root element**: use `Element.row` for row-like roots (Naive UI sets `display` itself,
  which wins; `flex-direction: row` then comes from elm-ui) — see `NUI.Button`. Use
  `Element.el` only when a column root is intended.
- **Attach** `NUI.Internal.classes [...]` and `NUI.Internal.cssVars [...]` (the latter
  drops `initial` values, matching Naive UI's "unset" marker).
- **Interactive elements**: `onPress : Maybe msg` → add `role="button"`, `tabindex 0`
  and `Element.Events.onClick`. Naive UI uses a real `<button>`; a styled `<div>` renders
  identically because `.n-button` sets all button-reset properties itself.
- **Icons**: render Naive UI's `__icon` / `__border` / `__state-border` wrapper elements
  so the CSS applies.
- **RTL**: components that support it take an `rtl : Bool` option and add their
  `n-<comp>--rtl` class. The RTL *rules* come from each component's
  `src/<comp>/src/styles/rtl.cssr.ts`, listed in `tools/manifest.mjs` alongside the
  base cssr (Naive UI mounts them via `useRtl`); regenerate with `npm run extract`.
- **Runtime behaviour**: Naive UI animates from `ref`/`watch`/`setTimeout`/`Transition`
  state. This library is pure, so that state is data-driven — the caller owns it (and
  its timers) and the view emits exactly Naive UI's DOM for it (e.g. Progress gradient
  colours, Badge `previousValue` / `waveActive`, Spin/Badge mount/leave via a
  `NUI.Internal.TransitionPhase`). No component holds a Model/update loop.

## Reference source (read-only)

The Naive UI checkout is at `/home/titan/Works/elm/naive-ui` (override with
`NAIVE_UI_SRC`). Per component:

```
src/<comp>/src/<Comp>.tsx          implementation + cssVars
src/<comp>/src/styles/*.cssr.ts    structure CSS (already extracted)
src/<comp>/styles/light.ts         theme var derivations (`self`)
src/<comp>/src/public-types.ts     props
src/<comp>/demos/enUS/*.md         usage examples
```

## Building & verifying

```bash
# everything (installs packages if needed)
ELM_HOME=/tmp/elm-home ./scripts/verify.sh
```

That runs, in order:

1.  `tools/verify/check-classes.mjs` — every `n-*` class a component emits exists in the
    extracted stylesheet (static; catches typos).
2.  `elm make` — the library compiles.
3.  `elm make src/Main.elm` — the example page compiles.
4.  `tools/verify/check-dom.mjs` — renders the example in jsdom and asserts each component
    root has `flex-basis: auto` (the bridge works) and carries its `--n-*` variables.
5.  `tests/run.sh` — 89 assertions over theme maths, `cssVars`, and live DOM output.
6.  `elm-format --validate`.

```bash
# library only
ELM_HOME=/tmp/elm-home elm make

# example page
cd examples && ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=index.html
```

`ELM_HOME` must point at a directory with the packages pre-installed; see
`scripts/install-elm-packages.sh` (github.com is blocked in this sandbox; packages are
fetched from `codeload.github.com`).
