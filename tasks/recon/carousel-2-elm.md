# Carousel → Elm design (carousel-2)

Grounded in Carousel.tsx / CarouselItem.tsx / CarouselDots.tsx / CarouselArrow.tsx /
utils/{index,duplicatedLogic}.ts @ naive-ui v2.45.3 (read in full this session).
Cross-checked against port house patterns: NUI.Upload (Options msg + Maybe msg channels +
pure State→State mirrors), NUI.Internal (I.classes/I.cssVars), tests harness (static HTML in
jsdom — no layout, so every measured quantity is caller-fed state).

## 0. Verdict

Single module `src/NUI/Carousel.elm` (upload precedent: in-module utils at this scale).
No Internal engine split — nothing here is shared with other surfaces. The component is a
**state machine + geometry engine over a caller-fed container size**, with the service
pattern for everything time/DOM-bound (timer, focus, document-level drag listeners,
measurement). This is the same shape as Upload's XHR treatment.

## 1. Types

```elm
type Direction = Horizontal | Vertical            -- direction prop
type Effect = SlideEffect | FadeEffect | CardEffect | CustomEffect
type DotType = Dot | Line                          -- dotType
type DotPlacement = DotsTop | DotsBottom | DotsLeft | DotsRight
type Trigger = ClickTrigger | HoverTrigger
type PerView = PerView Int | PerViewAuto           -- slidesPerView: number | 'auto'
type alias Size = { width : Float, height : Float }
type alias DragPoint = { x : Float, y : Float, time : Float }   -- ms epoch
type alias WheelInfo = { deltaX : Float, deltaY : Float, shiftKey : Bool }
type alias KeyInfo = { code : String, shiftKey, altKey, ctrlKey, metaKey : Bool }
```

### State (mirrors upstream closure state; init `default slides defaultIndex`)
```elm
type alias State =
    { displayIndex : Int            -- uncontrolled display-space index
    , perViewSize : Size            -- caller-measured INNER container size (init 0/0)
    , autoSlideSizes : List Size    -- measured per-slide sizes, auto mode only
    , previousTranslate : Float     -- upstream module-level let
    , inTransition : Bool
    , expectedDirection : Int       -- -1 | 0 | 1
    , mounted : Bool                -- upstream isMountedRef (rAF); gates fade/card slide
                                    --   transitionStyle merge. init False, caller sets True
    , dragging : Bool
    , isEffectiveDrag : Bool
    , dragOffset : Float
    , dragAnchor : Maybe DragPoint  -- start point/time
    }
```
NOT in state (upstream closure, port treatment):
- `autoplayTimer` → caller clock (Time.every interval → `next`), paused per
  `autoplayActive`/root hover; see §5.
- `globalDragging` singleton → caller-side, documented divergence.
- `slideElsRef`/`slideVNodesRef` → the port knows its slides statically; `Env.slides`
  (caller's list length) replaces registration.

### Options msg (~34 fields; defaults mirror upstream defaults exactly)
defaultIndex=0, currentIndex : Maybe Int (controlled — wins when set, useMergedState),
showArrow=False, dotType=Dot, dotPlacement=DotsBottom, slidesPerView=PerView 1,
spaceBetween=0, centeredSlides=False, direction=Horizontal, autoplay=False, interval=5000,
loop=True, effect=SlideEffect, showDots=True, trigger=ClickTrigger,
transitionDuration : String = "300ms" + transitionTimingFunction : Maybe String
(upstream keeps exactly these 2 keys from transitionStyle), draggable=False,
touchable=True, mousewheel=False, keyboard=False, prevSlideStyle : Maybe String,
nextSlideStyle : Maybe String, renderArrow : Maybe (ArrowInfo -> Element msg),
renderDots : Maybe (DotsInfo -> Element msg), slides wrapper content is the `view` arg.
Event channels (Maybe …, default Nothing):
- `onDotTo : Maybe (Int -> msg)` (dots click + hover-trigger + Enter/Space keydown)
- `onPrev : Maybe msg`, `onNext : Maybe msg` (arrows — the TRANSITION-GUARDED fns)
- `onSlideClick : Maybe (Int -> msg)` (card effect to(i); also click-suppression channel)
- `onTransitionEnd : Maybe msg` (slides container)
- `onRootMouseEnter : Maybe msg`, `onRootMouseLeave : Maybe msg` (autoplay pause/resume)
- `onTouchStart : Maybe (DragPoint -> msg)` (slides container, gated by touchable/draggable)
- `onWheel : Maybe (WheelInfo -> msg)` (gated by mousewheel; preventDefault)
- `onDotKeydown : Maybe (Int -> KeyInfo -> msg)` (dots keydown; NOTE: the view handles
  Enter/Space itself → fires `onDotTo i` directly, faithful to CarouselDots.tsx:41-53 where
  Enter/Space precede the keyboard matrix — `onDotKeydown` only carries the matrix keys)
- `attributes : List (Html.Attribute msg)` (root div; Html not Element — the root is raw
  Html per §4)

## 2. Env — the pure "computed" chain (one-stop derive, THE pin surface)

```elm
type alias Env =
    { vertical : Bool, sizeAxis : Axis, spaceAxis : SpaceAxis
    , sequenceLayout : Bool                  -- effect == slide
    , duplicatedable : Bool                  -- loop && slidesPerView==1 && slide
    , userWantsControl : Bool                -- effect == custom
    , displaySlidesPerView : PerView         -- (!slide || centered) ? 1 : spv
    , realSlidesPerView : PerView            -- custom ? 1 : spv
    , autoSlideSize : Bool                   -- displaySpv==auto || (spv==auto && centered)
    , slides : Int, totalSlides : Int        -- excl / incl duplicates
    , slideSizes : List Size, translates : List Float
    , totalView : Int, displayTotalView : Int
    , displayIndex : Int, realIndex : Int
    , speed : Float                          -- custom ? 0 : resolveSpeed duration
    , autoplayEnabled : Bool                 -- autoplay && displayTotalView >= 2
    }
envOf : Options msg -> State -> Int -> Env
```
Exact formulas (Carousel.tsx:171-341): slideSizes non-auto branch =
`perViewSize[axis]` then if spv numeric: `remaining = axis - (spv-1)*spaceBetween;
axis = remaining * (1 / max(1, spv))` (all slides same size); auto branch = measured
`autoSlideSizes` (state). translates = accumulate `previous + (centered ?
(slideSize - perViewSize)/2 : 0)`, step `slideSize + spaceBetween` (Carousel.tsx:228-246).
totalView numeric branch = `max(slides - spv, 0) + 1` over TOTAL slides incl duplicates;
auto branch = the while-loop folding trailing sizes (Carousel.tsx:295-337).
displayTotalView = getDisplayTotalView(totalView, duplicatedable).

## 3. Pure function exports (eq-pin targets; every one cites upstream)

From utils (byte-faithful):
- `clampValue : Float -> Float -> Float -> Float` (min/max NaN-free order: <min→min, >max→max)
- `resolveSpeed : Maybe String -> Float` — undefined→0; the lazy regex
  `/^((\d+)?\.?\d+?)(ms|s)?$/`, default unit ms, s ×1000, no-match→0. Pin: "300ms"→300,
  ".5s"→500, "2s"→2000, "10"→10, "1."→0, "ms"→0, "abc"→0, "1.5s"→1500.
- duplicatedLogic: `getDisplayIndex current length duplicatedable` (length==1→0;
  0→length-3; length-1→0; else -1), `getRealIndex` (+1), `getPrevIndex` (0→dup?length-1:Null),
  `getNextIndex` (length-1→dup?0:Null; >length-1→Null), `getDisplayTotalView`
  (dup&&>3 → -2). Port `Maybe Int` for the null returns.
- `duplicateWrap : List a -> List a` — prepend-last/append-first when length>1 (the
  slot [0 1 2] → display 2 0 1 2 0 layout). Used by the view on slide content.

Inst methods (Carousel.tsx:343-438):
- `to : Options -> State -> Int -> State` — clamp real, toRealIndex if changed
- `prev`/`next : Options -> State -> State` — set expectedDirection ∓/±1 then toRealIndex
- `prevIfSlideTransitionEnd`/`nextIfSlideTransitionEnd` — guarded by `inTransition &&
  duplicatedable` (these are what arrows/dots-keyboard/context use)
- `toRealIndex` — clamp 0..totalView-1, displayIndex change guard (emission is caller-diff,
  see §5); after the write it reflows real = getRealIndex(newDisplay) and runs
  `applyIndexChange` (the watcher body, above)

Translate machinery (Carousel.tsx:440-519) as pure state transforms; the VIEW derives
`translateStyle` from state (drag live-offset included):
- `getTranslate : Env -> Int -> Float` (index ≥ totalView-1 → lastViewTranslate)
- `getLastViewTranslate : Env -> Float` (auto: overallSize - perView; else
  translates[totalView-1] || 0)
- `translateTo : Options -> State -> Int -> State` — sets inTransition when translate moved
  and speed>0; previousTranslate := getTranslate(realIndex)
- `fixTranslate : Options -> State -> State`
- `transitionEnd : Options -> State -> State` — slide&&inTransition → translateTo(real,0);
  sets duration 0ms for slide; inTransition=False (Carousel.tsx:715-727)

**Index-change pipeline (THE subtlety — recon §4.6 + re-derivation).** Upstream has no
`toRealIndex → translate` call; the WATCHER on realIndexRef does it, and realIndexRef is
DERIVED from the display index that toRealIndex just wrote (display d → real d+1 under dup).
So after prev() at display 0: toRealIndex(0) writes display=length-3 (n-1) → reflow real =
length-2 → watcher sees (last=1, next=length-2, expected=-1) → case 1 → translateTo(0)
(animate to the PREPENDED clone) → transitionEnd → translateTo(real=length-2, 0) instant snap
to the equivalent real slide. Mirror exactly:

```elm
applyIndexChange : Options -> State -> Float -> State   -- (speed) = the watcher body
-- called by toRealIndex AFTER the display-index write + reflow; runs the two
-- duplicatedable loop-jump normalizations (expected -1: last==1 && next==len-2 → 0 ;
-- expected 1: last==len-2 && next==1 → len-1), then translateTo(normalized, speed)
-- (slide) / fixTranslate (else); expectedDirection := 0
```
`toRealIndex` = clamp → displayIndex' → guard vs merged (opts.currentIndex override) →
write + applyIndexChange. `prev`/`next` set expectedDirection ∓/±1 first.

Drag (Carousel.tsx:593-713):
- `dragStart : Options -> State -> DragPoint -> State` (axis pos from x/y)
- `dragMove : Options -> State -> { x, y } -> State` — dragOffset = clamp(offset, ±perView)
- `dragEnd : Options -> State -> State` — the full settle: nearest-translate scan over
  `[translates[0..totalView-2], lastViewTranslate]`, then the
  `dragOffset > perView/2 || dragOffset/timeElapsed > 0.4` → prev /
  `< -perView/2 || < -0.4` → next rules on same-index, else toRealIndex(nearest)+
  fixTranslate, isEffectiveDrag latch, reset anchors.

Event algebra:
- `wheel : Options -> State -> WheelInfo -> State` — shift deltaX fallback, m =
  (deltaX||deltaY)>0 ? 1 : -1, responseStep 10 gate, prev/next (Carousel.tsx:728-755)
- `dotKeyAction : Options -> Env -> KeyInfo -> Maybe DotKeyAction`
  (= ToNext | ToPrev | None after the Enter/Space/`to(i)` and modifier/input guards)
  (CarouselDots.tsx:29-77)
- `indexChange : State -> State -> Maybe (Int, Int)` — (current, last) iff displayIndex
  changed (caller maps with onIndexChange; exactly toRealIndex's emit condition)

## 4. View

**Rendering strategy (settled): the whole carousel renders as ONE raw `Html` tree wrapped
in a single `Element.html`** — root div, track, slides, dots, arrows. Rationale: the cssr
owns the track's `display:flex` (and `flex-direction:column` under `--vertical`); any
elm-ui Element would emit competing inline layout styles and there is no Element→Html
converter for slide content anyway. Consequence: slides are `List (Html msg)` (upstream
slides are arbitrary vnode content; `NCarouselItem`'s scoped-slot flags are exposed as the
pure `slideInfo : Options msg -> State -> Int -> Maybe SlideInfo` helper instead).
Byte-fidelity bonus: root style attr carries exactly the 8 cssVars, track style exactly the
translateStyle serialization.

`view : Theme -> Options msg -> State -> List (Html msg) -> Element msg`
(+ `viewDots`, `viewArrowGroup` as raw-Html builders for custom slots). DOM contract:

- Root: `n-carousel` + `--vertical`?, `--show-arrow`?, `--{dotPlacement}`,
  `--{direction}`, `--{effect}`, `--usercontrol`? — IN THAT ORDER; cssVars (8, §6) on
  style; touch/mouse/wheel listeners per §1 gates; root mouseenter/leave only matter for
  autoplay (attach when onRootMouseEnter set).
- Slides container `n-carousel__slides`, role="listbox", style = translateStyle
  (`transform: translateX/Y(-{t}px)` + `transition-duration: {speed}ms` +
  timingFunction when set; during drag: `previousTranslate - dragOffset`, duration 0),
  transitionend wired.
- Slide wrappers `n-carousel__slide` + `--current`/`--prev`/`--next` (isRealActive /
  isRealPrev / isRealNext over the REAL index incl duplicates), role="option",
  tabindex="-1", data-index = real position (clones get 0 / N+1),
  aria-hidden = not isActive, style = slideStyle (size px when useComputedSize, margin-
  {spaceAxis} px, fade/card+mounted transition props, prevSlideStyle/nextSlideStyle
  appended), click handler (card→to(i) via onSlideClick; suppression is caller-side).
- Dots (showDots && displayTotalView > 1): `n-carousel__dots n-carousel__dots--{dotType}`
  role="tablist"; dot divs role="button" tabindex="0" aria-selected, `n-carousel__dot`
  + `--active`, click/hover per trigger, keydown wired.
- Arrows (showArrow): `n-carousel__arrow-group` of two `n-carousel__arrow` (+`--disabled`
  when prev/next null) role="button" divs, SVG d-strings byte-verbatim (16-vB, g fill=none,
  path fill=currentColor).
- usercontrol branch: per-slide wrapper div (slideStyles[i]) with non-active
  `display: none` (vShow semantics); NO Vue Transition — see divergences.
- Slides list passed through `duplicateWrap` when duplicatedable; content Elements are
  reused verbatim in both clone positions (Elm VDom handles this fine).

## 5. Service boundary (caller-owned — house service pattern)

- Autoplay clock: caller `Time.every interval` → `next opts st` when `env.autoplayEnabled`;
  root hover pauses (onRootMouseEnter/Leave msgs stop/start the caller's Sub).
- Measurement: `resize : Size -> State -> State` (container INNER size — caller subtracts
  padding, calculateSize(innerOnly=true) semantics) and `setSlideSizes : List Size ->
  State -> State` (auto mode). Examples/tests feed fixed sizes so jsdom output is
  deterministic; real apps use an element probe port.
- Document-level drag move/end: caller Browser.Events subs decoding clientX/Y →
  `dragMove`/`dragEnd`; export `decodeDragPoint : Decode.Decoder DragPoint`.
- Focus management (focusDot), activeElement input/textarea guard, capture-phase click
  suppression, globalDragging singleton: caller-side, documented divergences.

## 6. Theme / css

`cssVarsFor` 8 vars in upstream order: --n-bezier, --n-dot-color, --n-dot-color-focus,
--n-dot-color-active, --n-dot-size, --n-dot-line-width, --n-dot-line-width-active,
--n-arrow-color. Theme module `NUI.Theme.Carousel` from extract (manifest key `carousel`).
CONFIRMED by recon-1 §6: 7 self keys (dotSize 8px, dotColor rgba(255,255,255,.3),
dotColorActive rgba(255,255,255,1), dotColorFocus rgba(255,255,255,.5), dotLineWidth 16px,
dotLineWidthActive 24px, arrowColor #eee); dark = common swap ONLY (no self override).

## 7. Accepted divergences (docstring `[divergence]` lines, pins doc §D)

1. No Vue Transition machinery: `transitionProps` prop dropped; `effect: custom` hides
   inactive slides via `display: none` without enter/leave classes.
2. Measurement, timer, focus, capture-click, globalDragging: caller-owned (§5).
3. `transitionStyle` prop narrowed to the 2 keys upstream `keep()`s (duration string +
   optional timing function).
4. prevSlideStyle/nextSlideStyle: string form only (upstream also allows CSSProperties
   object — normalizeStyle joins them; strings cover the typed use).
5. isMounted rAF flag is caller-set state (static output matches upstream SSR: fade/card
   slides carry no transition props until mounted=True).

Controlled usage (NOT a divergence): the caller updates their model + passes
`currentIndex`; since `opts.currentIndex` overrides `state.displayIndex` in `envOf`
(useMergedState), routing the same events through `to` works for both modes — the stale
uncontrolled field is shadowed. `to`'s own upper clamp is `totalView` (not `-1`) upstream —
faithful, harmless (re-clamped).

## 8. Wiring checklist (feat commit)

manifest `carousel` (CONFIRMED: no rtl.cssr upstream — cssr list is just
`carousel/src/styles/index.cssr.ts`) → extract →
`NUI.Theme.Carousel` in elm.json (prep) → `NUI.Carousel` exposure + examples carouselSection
(basic / arrows+dots / vertical / slidesPerView demo with fixed perViewSize so static DOM is
deterministic / custom dots) + README row + check-dom targets (+ check-classes ALLOW only
if rule-less markers emerge — none expected) → gate 8/8.
