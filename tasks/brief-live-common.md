# BRIEF (common) — Live/* interactive demo modules — READ FIRST, applies to every family brief

## GOAL
The elm-naive-ui showcase (examples/) is becoming a real Elm app. `examples/src/Main.elm`
is already a `Browser.element` over six `Live/*` family models. YOUR JOB: replace ONE
stub — `examples/src/Live/<Family>.elm` — with a real interactive module. You write
ONLY that file. Nothing else.

## HARD CONTRACT (the stub already satisfies it; keep the shape)
```elm
module Live.<Family> exposing (Model, Msg, init, subscriptions, update, view)

view : NUI.Theme.Theme -> Model -> Element.Element Msg
update : Msg -> Model -> Model            -- NO Cmd — Main wraps it
subscriptions : Model -> Sub.Sub Msg      -- Sub.none unless the brief says otherwise
init : Model
```
Main calls `Live.<Family>.view Showcase.theme model.<family>` and `Element.map`s it.
Your `view` renders a `Element.column [ Element.spacing 20, Element.width Element.fill ]`
of `Showcase.demoRow` blocks — same visual grammar as the static sections.

## AVAILABLE CHROME (import Showcase)
`Showcase.section`, `Showcase.demoRow : String -> List (Element msg) -> Element msg`,
`Showcase.chip`, `Showcase.theme`. For component defaults use the house pattern: bind a
local plain name FIRST (`btn = Button.defaults`) because record update needs a bare
variable — `{ Button.defaults | ... }` is a parse error. NEVER use qualified defaults
in a record update.

## HOW TO WIRE EACH COMPONENT
1. READ the component module under `src/NUI/<Name>.elm` — header docstring (the port
   contract, caller-owned concerns) + the `Options`/state types. The header is the
   source of truth for what the caller must own.
2. Every `Maybe msg` / `Maybe (X -> msg)` channel in Options that has demo value gets
   ONE Msg constructor. State that the component renders goes in YOUR Model.
3. Where the port exposes pure interaction helpers (e.g. `Carousel.next`,
   `DatePicker.singleDateClick`, `Log.scrollEvents`), USE THEM in update — do not
   re-derive component semantics by hand; that algebra is what the port ships.
4. Static demo content (text, tags) may reuse Showcase.chip / Element.text.

## RULES
- WRITE ONLY `examples/src/Live/<Family>.elm`. Do NOT touch Main.elm, Showcase.elm,
  src/, tests/, or any other Live/*.elm. If you believe another file must change,
  STOP and report it in your final message instead.
- No new dependencies. elm/browser, elm/time, elm/core, elm/html, elm/json, elm/regex,
  elm/svg, elm/url, elm/virtual-dom, mdgriffith/elm-ui are available (examples/elm.json).
- NO ports, NO JS. If a real browser capability is needed (file picker, measurement),
  SIMULATE with model state (fake file list, fixed sizes) — that is the port's
  documented caller-owned pattern and is the point of the demo.
- Every live demo row gets a short uppercase-ish label via demoRow, e.g.
  `demoRow "Button · press counter" [...]`.
- Put `HA.id "live-<component>-<variant>"` (Html.Attributes) on interactive roots via
  the component's `attributes`/attrs seam when it has one — inspectability, not required.
- Msg constructors: name them after the semantic (`Press`, `SetName String`,
  `ToggleOpen Bool`), one per channel; update is a plain case.
- Initial states: CLOSED for overlays/panels (the static sections already render the
  always-open instances that the check-dom gate needs — do not try to keep yours open).

## VERIFY (in your workspace)
```bash
cd examples && ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=/dev/null
elm-format --yes src/Live/<Family>.elm
```
Iterate until both are clean. `elm make` error output is your friend: unused imports
are HARD ERRORS in Elm — prune them.

## COMMIT (in your workspace, on YOUR branch)
```bash
git rev-parse --abbrev-ref HEAD   # must NOT be master — your worktree branch
git add examples/src/Live/<Family>.elm
git commit -m "feat(examples/live): <Family> — <one-line component list>"
```
Then report: components wired, channels used, helpers exercised, anything you
deliberately skipped + why.
