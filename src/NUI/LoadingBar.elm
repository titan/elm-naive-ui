module NUI.LoadingBar exposing
    ( Options, State, Status(..), cssVarsFor, defaults, error, finish, init
    , kick, start, startFromTo, view
    )

{-| Naive UI's `LoadingBar` — the bar itself, rebuilt on elm-ui: one
`div.n-loading-bar-container` (fixed to the top of the viewport) wrapping one
`div.n-loading-bar.n-loading-bar--{status}` whose inline `max-width` is the
progress. `NUI.Css` ships Naive UI's exact CSS — including the `max-width 4s
linear` tween for `--starting` and the `.2s` ones for `--finishing` /
`--error`. The `--n-*` custom properties come from `NUI.Theme.LoadingBar`.

@docs Options, State, Status, cssVarsFor, defaults, error, finish, init
@docs kick, start, startFromTo, view

    import NUI.Internal as I
    import NUI.LoadingBar as LoadingBar


    -- a full run, driven from the caller's update (phase + transition
    -- together; `kick` one animation frame after `start`):
    --
    --   StartLoading  -> LoadingBar.start { model | phase = Just I.EnterFrom }
    --   Kick          -> LoadingBar.kick                    -- next frame
    --   FinishLoading -> LoadingBar.finish { model | phase = Just I.LeaveFrom }
    --
    --   view: LoadingBar.view theme LoadingBar.defaults model

**The caller-owned contract.** Upstream drives the bar imperatively inside a
`LoadingBarProvider`; the port is a pure state machine the caller steps (the
`NUI.Countdown` precedent). No timers live here — the fade phases are
caller-driven (the `NUI.BackTop` / `NUI.Spin` precedent):

  - `start` / `startFromTo` (defaults `0 → 80`) — a fresh run whose `runId`
    change remounts the bar (keyed) so it reappears at `from` with an inline
    `transition: none` instead of tweening from the previous run's width;
    `toProgress` is staged for `kick`.
  - `kick` — invoke one animation frame after `start` (e.g. from
    `Browser.Events.onAnimationFrame`): the bar moves to `toProgress` and the
    CSS tween takes over.
  - `finish` — `--finishing` (the CSS retargets `max-width` to `100%` in
    `.2s`); no-op unless a run is loading.
  - `error` — mid-run: `--error` and a `.2s` tween to `100%`; from idle: an
    already-finished error run (`start(100, 100, 'error')` — drive it like a
    `start`). No-op while a finish/error is still fading out.
  - **Fade phases + the guard.** Set `phase = Just I.EnterFrom` in the same
    update as `start` (or an idle `error`), advance to `EnterActive` next
    frame, clear to `Nothing` after the `.3s` fade; set `LeaveFrom` with
    `finish` / `error`, advance to `LeaveActive` and clear after the `.8s`
    fade — that clear is the port's `handleAfterLeave` and releases the
    finish/error no-op guard (hold the `Leave` phase, and a second
    `error`/`finish` no-ops instead of restarting).
  - **Visibility.** A started run paints its bar for EVERY status — a
    `--starting` tween, a settled `--finishing` at 100%, an `--error` at 100%
    in the error colour; a not-started run renders `Element.none`. A settled
    finished/errored run STAYS painted at its final width (the frozen static
    demos rely on it).

(The upstream imperative-mutation walkthrough, the per-function upstream
mapping with line citations and the full divergence list live in the plain
comment right below — internal port notes, deliberately kept out of the
published docs.)

-}

{- INTERNAL PORT NOTES — moved out of the module doc (plain comments do not
      enter docs.json; the published docs must stay under the package-size
      limit). Nothing here changes the public contract summarised above.

   **Caller-owned runtime.** Upstream mounts the bar inside a `LoadingBarProvider`
   and drives it imperatively (`useLoadingBar()` → `start` / `finish` / `error`),
   mutating the live DOM node across `nextTick`s — `el.className = …`,
   `el.style.maxWidth = …`, `el.style.transition = 'none'` … `''`, with forced
   reflows (`void el.offsetWidth`, LoadingBar.tsx:70-77). The provider, the
   teleport (`to`), and the composable are not ported; the component is a pure
   state machine the caller steps, and `view` renders exactly the DOM those
   mutations would have produced:

     - `start` / `startFromTo` — upstream `start()` (LoadingBar.tsx:58-77).
     - `kick` — replaces upstream's forced-reflow dance (LoadingBar.tsx:73-76).
     - `finish` — upstream `finish()` (LoadingBar.tsx:79-92). No-op unless a run
       is loading — upstream's live `finishing || erroring` guard
       (LoadingBar.tsx:80-81).
     - `error` — upstream `error()` (LoadingBar.tsx:94-117); from idle it starts
       an already-finished error run (upstream's `start(100, 100, 'error')`,
       LoadingBar.tsx:99-107).
     - `init` — `started = False`; the view renders `Element.none` (upstream:
       `if (!this.started) return null`, LoadingBar.tsx:171-172).

   **Visibility.** Upstream shows the container via `v-show` on `loading ||
   (!loading && entering)` — i.e. `loading || entering` — inside a
   `<Transition name="fade-in-transition" appear>` (LoadingBar.tsx:176-209); a
   hiding element only collapses once the `.8s` leave fade has finished, and
   `handleAfterLeave` then resets the flags (LoadingBar.tsx:125-127).

   **Divergences from upstream** (everything else is a faithful port):

     - **Provider skipped.** No `LoadingBarProvider` / `useLoadingBar` /
       teleport (`to`): the caller owns one `State`, renders the bar where it
       wants it, and passes the provider's props (`containerClass`,
       `containerStyle`, `loadingBarStyle`) as `Options` instead.
     - **The reflow dance is data.** Upstream juggles `className` / `maxWidth` /
       `transition` imperatively across `nextTick`s; the port encodes the same
       frames declaratively (`kicked`, the `runId` keyed remount). One transient
       upstream frame disappears: the just-mounted bar with the bare
       `n-loading-bar` class (no modifier, no `max-width`, transparent) before
       `start`'s callback lands — here `start` sets the status atomically, with
       the same (invisible) rendering.
     - **A settled `--finishing` / `--error` run stays painted.** Upstream's
       `v-show` retargets to `false` the moment `loading` clears (on
       `finish` / `error`), so the bar survives only the `.8s` leave fade before
       `handleAfterLeave` collapses it. The port has no collapse signal once the
       caller clears the phase, so `isDisplayed` keeps a finished/errored run
       visible at its final width — the frozen static demos (which call
       `finish` / `error` with no phase) rely on it.
     - **`transitionDisabled` / `css=false`** — upstream's flag that keeps
       Vue's transition engine from fighting those imperative style writes
       (LoadingBar.tsx:34, 52-53, 183) — has no equivalent; the pure port has no
       such race.
     - **Guard window.** Upstream holds the `finishing || erroring` no-op guard
       from `finish`/`error` until the leave fade ends
       (`handleAfterLeave` → `init()`); the port holds it while a `Leave` phase
       is set. A second `error` in the very same update as the first
       `error`/`finish` — before the caller has attached the `Leave` phase —
       restarts the run instead of no-oping. Unreachable when the recipe above
       is followed (set the `Leave` phase together with `finish`/`error`).
     - **`loadingBarStyle`** — upstream accepts `string | CSSProperties` per
       variant (LoadingBar.tsx:43-48); the port takes raw CSS strings, merged
       verbatim after the themed vars and `max-width` (so the fragment wins on
       conflicts), the `error` variant picked while erroring. Same for
       `containerStyle` (a raw fragment on the container, after the view's own
       `display: none`).
     - **`inlineThemeDisabled` / `themeClass`** mode is not ported — the port
       always emits the inline `--n-*` vars on the bar (upstream's default
       mode, LoadingBar.tsx:200-206).
     - **`attributes` exists for record parity only** — the root is raw HTML
       (`Element.html`, the `NUI.Highlight` / `NUI.Heatmap` precedent: an
       `Element.Attribute` cannot attach to a raw node), so it is unused.

-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Keyed
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.LoadingBar as LoadingBarTheme


{-| The bar's status — upstream's `createClassName` argument
(LoadingBar.tsx:14-19): `--starting` (loading tween), `--finishing`
(completing), `--error` (failed).
-}
type Status
    = Starting
    | Finishing
    | Erroring


{-| One run of the bar. `started` mounts the container; `status` drives the
bar's modifier class (and doubles as upstream's `loading` flag —
`Starting` ⇔ loading); `progress` is the rendered `max-width` percentage and
`toProgress` where `kick` tweens to; `runId` keys the bar element so a new
run remounts instead of tweening from the old width; `kicked` is upstream's
post-reflow frame (the inline `transition: none` is emitted until it is set);
`phase` is the container's `fade-in-transition` phase (caller-driven — see
the module docs).
-}
type alias State =
    { started : Bool
    , status : Status
    , progress : Float
    , toProgress : Float
    , runId : Int
    , kicked : Bool
    , phase : Maybe I.TransitionPhase
    }


{-| Upstream's idle state: not started (the view renders `Element.none`),
`Starting`, progress 0 staging 80, run 0, not kicked, no phase.
-}
init : State
init =
    { started = False
    , status = Starting
    , progress = 0
    , toProgress = 80
    , runId = 0
    , kicked = False
    , phase = Nothing
    }


{-| Upstream's `start()` with its defaults — `start(0, 80, 'starting')`.
-}
start : State -> State
start =
    startFromTo 0 80


{-| Upstream's `start(fromProgress, toProgress, 'starting')`
(LoadingBar.tsx:58-77): mounts the container, resets the bar to `from` with
the transition disabled (the `runId` remount + inline `transition: none`),
and stages `to` for `kick`.
-}
startFromTo : Float -> Float -> State -> State
startFromTo fromProgress toProgress state =
    { state
        | started = True
        , status = Starting
        , progress = fromProgress
        , toProgress = toProgress
        , runId = state.runId + 1
        , kicked = False
    }


{-| Upstream's reflow frame (LoadingBar.tsx:73-76): the caller invokes this
one animation frame after `start`, which re-enables the CSS transition and
moves the bar to `toProgress`.
-}
kick : State -> State
kick state =
    { state | progress = state.toProgress, kicked = True }


{-| Upstream's `finish()` (LoadingBar.tsx:79-92). No-op unless a run is
loading — upstream's `finishing || erroring` guard (which for `finish` is
observably a no-op in every other state too: a settled bar is hidden either
way).
-}
finish : State -> State
finish state =
    if isLoading state then
        { state | status = Finishing, progress = 100 }

    else
        state


{-| Upstream's `error()` (LoadingBar.tsx:94-117). Mid-run: `--error` and a
`.2s` tween to `100%`. From idle (never started, or a previous run whose
leave fade has ended — upstream resets its flags in `handleAfterLeave`, the
clear of the `Leave` phase here): the `start(100, 100, 'error')` run
(LoadingBar.tsx:99-107), which shows a finished red bar; drive it like a
`start` (an `EnterFrom` phase for the appear, then the leave). No-op while a
finish/error is still fading out (a `Leave` phase is held).
-}
error : State -> State
error state =
    if isLoading state then
        { state | status = Erroring, progress = 100 }

    else if isSettling state then
        state

    else
        { state
            | started = True
            , status = Erroring
            , progress = 100
            , toProgress = 100
            , runId = state.runId + 1
            , kicked = False
        }


{-| Upstream's `loading` ref (LoadingBar.tsx:34): true between `start` and
`finish`/`error` — encoded as `status == Starting` on a started run (the
idle-error path jumps straight to `Erroring`).
-}
isLoading : State -> Bool
isLoading state =
    state.started && state.status == Starting


{-| Upstream's live `finishing || erroring` guard (LoadingBar.tsx:80-81,
95-96): held from `finish`/`error` until the leave fade ends
(`handleAfterLeave` → `init()`), which the caller models by holding a
`Leave` phase.
-}
isSettling : State -> Bool
isSettling state =
    (state.status == Finishing || state.status == Erroring)
        && isLeavingPhase state.phase


{-| The provider-side props upstream threads from `LoadingBarProvider`:
the container's extra class / style, and the per-variant raw style fragment
for the bar (the `error` one picked while erroring). `attributes` exists for
record parity only (the root is raw `Html`; see the module docs).
-}
type alias Options msg =
    { containerClass : Maybe String
    , containerStyle : Maybe String
    , loadingBarStyle : Maybe { loading : String, error : String }
    , attributes : List (Element.Attribute msg)
    }


{-| No container class / style, no bar style overrides — upstream's bare
provider defaults.
-}
defaults : Options msg
defaults =
    { containerClass = Nothing
    , containerStyle = Nothing
    , loadingBarStyle = Nothing
    , attributes = []
    }


{-| The container element — `Element.none` for a not-started run (upstream's
`if (!this.started) return null`), else the fixed `n-loading-bar-container`
holding the `runId`-keyed bar. Mount it wherever the caller wants the bar
(upstream's teleport target).
-}
view : Theme -> Options msg -> State -> Element msg
view theme opts state =
    if not state.started then
        Element.none

    else
        Element.html (container theme opts state)



-- DOM (upstream render(), LoadingBar.tsx:170-216)


{-| The container — the `Transition`'s child, so the fade classes and the
`v-show` `display: none` land on it (LoadingBar.tsx:192-198, 209). A keyed
node so the bar inside remounts per `runId`.
-}
container : Theme -> Options msg -> State -> Html msg
container theme opts state =
    let
        containerClasses =
            "n-loading-bar-container"
                :: List.filterMap identity
                    [ Maybe.map (I.transitionClass "fade-in-transition") state.phase
                    , opts.containerClass
                    ]

        containerStyle =
            String.join ";"
                (I.classIf (not (isDisplayed state)) "display:none"
                    ++ List.filterMap identity [ opts.containerStyle ]
                )
    in
    Html.Keyed.node "div"
        [ HA.class (String.join " " containerClasses)
        , HA.attribute "style" containerStyle
        ]
        [ ( String.fromInt state.runId, bar theme opts state ) ]


{-| Upstream's `v-show` condition `loading || (!loading && entering)` — i.e.
`loading || entering` (LoadingBar.tsx:209) — generalised over the port's
statuses: a started run paints its bar for EVERY status — a `--starting` run
mid-tween, a settled `--finishing` at 100%, and a `--error` run at 100% in
the error colour — and an enter/leave fade phase additionally holds the
container mounted mid-fade. Upstream clears `loading` on `finish` / `error`
and relies on the leave fade to keep the bar drawn until `handleAfterLeave`;
the port has no such collapse signal once the caller clears the phase, so a
finished/errored run stays painted at its final width (the frozen static
demos call `finish` / `error` with no phase — see the divergence below).

The container is therefore only collapsed for a run that has not started —
and `view` already renders `Element.none` for that case.

-}
isDisplayed : State -> Bool
isDisplayed state =
    state.status
        == Starting
        || state.status
        == Finishing
        || state.status
        == Erroring
        || isEnterPhase state.phase
        || isLeavingPhase state.phase


{-| The bar itself (LoadingBar.tsx:200-206): the modifier class and inline
`max-width` upstream sets imperatively (LoadingBar.tsx:72, 77, 90, 114), the
themed vars from its `cssVarsRef` (LoadingBar.tsx:136-144), and the caller's
`loadingBarStyle` fragment (the `error` one while erroring,
LoadingBar.tsx:43-48).
-}
bar : Theme -> Options msg -> State -> Html msg
bar theme opts state =
    Html.div
        [ HA.class ("n-loading-bar n-loading-bar--" ++ statusSuffix state.status)
        , HA.attribute "style" (barStyle theme opts state)
        ]
        []


statusSuffix : Status -> String
statusSuffix status =
    case status of
        Starting ->
            "starting"

        Finishing ->
            "finishing"

        Erroring ->
            "error"


{-| One `style` attribute for the bar: the themed vars and `max-width`
first, then the inline `transition: none` of the not-yet-kicked frame
(upstream's `el.style.transition = 'none'` … `''`, LoadingBar.tsx:73-76),
then the caller's fragment verbatim (so it wins on conflicts).
-}
barStyle : Theme -> Options msg -> State -> String
barStyle theme opts state =
    let
        transitionNone =
            if state.kicked then
                []

            else
                [ ( "transition", "none" ) ]

        fragment =
            case opts.loadingBarStyle of
                Just styles ->
                    [ if state.status == Erroring then
                        styles.error

                      else
                        styles.loading
                    ]

                Nothing ->
                    []
    in
    renderStyle
        (cssVarsFor theme
            ++ [ ( "max-width", String.fromFloat state.progress ++ "%" ) ]
            ++ transitionNone
        )
        fragment


{-| The raw `--n-*` custom properties the bar attaches — upstream's
`cssVarsRef` (LoadingBar.tsx:136-144). Exposed so the `--n-*` output can be
asserted directly; `view` uses exactly this.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            LoadingBarTheme.vars theme
    in
    [ ( "--n-height", v.height )
    , ( "--n-color-loading", v.colorLoading )
    , ( "--n-color-error", v.colorError )
    ]


{-| Render one `style` attribute: `k: v` declarations (with
`NUI.Internal.renderVars`'s `initial` / empty filtering) followed by raw CSS
fragments verbatim.
-}
renderStyle : List ( String, String ) -> List String -> String
renderStyle pairs raws =
    String.join ";"
        (List.filter (not << String.isEmpty) (I.renderVars pairs :: raws))


{-| Upstream's `entering` ref (LoadingBar.tsx:33): true from the Transition's
`onEnter` to its `onAfterEnter` — here, while an enter phase is held.
-}
isEnterPhase : Maybe I.TransitionPhase -> Bool
isEnterPhase phase =
    case phase of
        Just I.EnterFrom ->
            True

        Just I.EnterActive ->
            True

        Just I.EnterTo ->
            True

        _ ->
            False


isLeavingPhase : Maybe I.TransitionPhase -> Bool
isLeavingPhase phase =
    Maybe.withDefault False (Maybe.map I.isLeavePhase phase)
