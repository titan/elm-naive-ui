# BRIEF — feat(carousel): NUI.Carousel module

You are implementing the FEATURE batch for the Carousel component port (naive-ui v2.45.3 →
Elm, byte-level DOM fidelity). Prep is committed (`b6c123e`: NUI.Theme.Carousel + css
extracted + exposed). Work in `/home/titan/Works/elm/elm-naive-ui` (branch master).
Commit at the end.

## Read FIRST, in order

1. `tasks/recon/carousel-2-elm.md` — THE design. Follow it; §0 verdict, §1 types, §2 Env,
   §3 pure functions (incl. the index-change pipeline + applyIndexChange), §4 rendering
   strategy (RAW Html via Element.html — this is settled, do not revisit), §7 divergences.
2. `tasks/recon/carousel-1-upstream.md` — upstream bytes: §2 API defaults, §3 DOM byte-map
   (root class order, slide/dots/arrow attrs, SVG d-strings verbatim), §4 state machine,
   §5 cssr rules. THE ground truth.
3. `tasks/recon/carousel-pins.md` — §A worked derivations (A1-A6: the exact numbers your
   algebra must reproduce) and §T traps. Do NOT write tests (next batch does) — but the
   port must make §A true.
4. `src/NUI/Upload.elm` — exemplar for module layout, docstring style, Options-record
   pattern, `Maybe msg` channels, cssVarsFor.
5. `src/NUI/Internal.elm` — helpers (`classes`, `cssVars`, `renderVars`) — NOTE: with the
   raw-Html strategy you mostly need `I.renderVars` (style string) + plain
   `Html.Attributes`; `I.classes` is an Element attribute.
6. `src/NUI/Theme/Carousel.elm` — the generated theme module (Vars/vars).

Upstream mirror (READ-ONLY): `/home/titan/Works/elm/naive-ui/src/carousel/` (v2.45.3).
NEVER edit anything under it.

## Scope — files you may touch (nothing else)

CREATE `src/NUI/Carousel.elm` (est 1200-1600 L) per carousel-2:
  - Types: Direction/Effect/DotType/DotPlacement/Trigger/PerView/Size/DragPoint/WheelInfo/
    KeyInfo/State/Options/Env (+ DotKeyAction, SlideInfo).
  - `defaults` (Options) mirroring upstream defaults EXACTLY (carousel-1 §2.1).
  - `init : Int -> State` (slide count arg; seed = INTENDED semantics per pins A6:
    displayIndex = getDisplayIndex(getRealIndex(defaultIndex…)) with TRUE totalView — the
    function takes Options + slide count), `resize`, `setSlideSizes`, `markMounted`.
  - Pure algebra (carousel-2 §3): clampValue/resolveSpeed (Regex; elm/regex is a dep)/
    getDisplayIndex/getRealIndex/getPrevIndex/getNextIndex (Maybe Int)/getDisplayTotalView/
    duplicateWrap/envOf/getTranslate/getLastViewTranslate/translateTo/fixTranslate/
    applyIndexChange (the watcher body — loop-jump normalization AFTER the display→real
    reflow)/toRealIndex/to/prev/next/prevIfSlideTransitionEnd/nextIfSlideTransitionEnd/
    transitionEnd/dragStart/dragMove/dragEnd/wheel/dotKeyAction/indexChange/slideInfo/
    autoplayEnabled/decodeDragPoint.
  - Views (raw Html builders, all returning `Html msg` except `view` which returns
    `Element msg` via a single `Element.html`): `view`, plus exported `viewDots`,
    `viewArrowGroup` and private slide/svg builders.
  - `cssVarsFor : Theme -> List (String, String)` — 8 vars in upstream order (carousel-2 §6).
  - Module docstring: divergences from carousel-2 §7 (5 + the raw-Html/static-render note),
    the A6 defaultIndex quirk note, upstream refs with line numbers.

EDIT `elm.json` — expose `"NUI.Carousel"` after `"NUI.Calendar"` (main list is alphabetical).

EDIT `examples/src/Main.elm` — add `carouselSection` AFTER `uploadSection` (line ~5278+;
register in the section list after `uploadSection` at :774). Import `NUI.Carousel as
Carousel`. Fixtures per pins §D — all STATIC (examples are static renders; the caller-owned
clock/measurement story goes in the section subtitle + demoRow captions):
  - basic: 4 slides (Html.img with distinct gradients/urls), perViewSize {1000,400} via
    `Carousel.resize`, loop → 6 slide divs, dots 4, `id="live-carousel"` (match the
    `live-*` id convention via `attributes = [ Element.htmlAttribute (HA.id …) ]` — root
    attrs come through `Element.htmlAttribute` inside the Element.html wrapper? NO — root
    IS raw Html; route Options.attributes (Element.Attribute msg) onto the Element.html
    wrapper? Settled: Options.attributes apply to the ROOT raw div via the `Element.html`
    wrapper node? — simplest: `view` attaches `opts.attributes` on the Element.html wrapper
    is WRONG for byte-fidelity; instead the view applies them as Html attrs on the root
    div by keeping `attributes : List (Html.Attribute msg)` (DEVIATION from Upload's
    Element.Attribute — note in docstring) and examples pass `HA.id "live-carousel"`).
  - vertical + dotPlacement right; arrows (showArrow); dotType line; loop=False (disabled
    prev arrow); slidesPerView 3 + spaceBetween 20; fade + card (card with
    prevSlideStyle/nextSlideStyle from the upstream custom-card demo); custom
    (usercontrol) with renderDots text counter like the custom-dots demo ("1 / 4");
    defaultIndex 2. Every demo needs explicit perViewSize fed (Carousel.resize on init
    state) so the static DOM shows deterministic px transforms.

EDIT `README.md` — `| \`NUI.Carousel\`   | ✅ |` row (match neighbor style/alignment).

EDIT `tools/verify/check-dom.mjs` — add `'.n-carousel': true,` to the targets (after
`'.n-upload': true`).

NO check-classes ALLOW edits (recon §5: every emitted class has a rule; the usercontrol
wrapper div has NO class at all — render it classless, it is targeted by
`.n-carousel__slides > div`).

## Byte-fidelity contract (the parts probes will check — get them EXACT)

- Root div class order: `n-carousel` · `n-carousel--vertical` (iff vertical — note it then
  appears TWICE, also as the `--{direction}` token) · `n-carousel--show-arrow` (iff) ·
  `n-carousel--{dotPlacement}` · `n-carousel--{direction}` · `n-carousel--{effect}` ·
  `n-carousel--usercontrol` (iff custom). Root style = the 8 cssVars (I.renderVars order).
- Track: `class="n-carousel__slides" role="listbox"` + style
  `transition-duration: {speed}ms; transform: translateX(-{t}px)` (+ `transition-timing-function`
  BEFORE transform when set — key order: duration, timingFunction, transform;
  carousel-pins §T). During drag: transform uses `previousTranslate - dragOffset`, duration 0.
  `transitionend` listener when onTransitionEnd set.
- Slides: `class="n-carousel__slide [--current] [--prev] [--next]"` (order current,prev,next),
  `role="option" tabindex="-1" data-index="{real}" aria-hidden="{true|false}"`, style =
  `width: {n}px` (iff useComputedSize) + `margin-right|bottom: {n}px` + (fade/card && mounted
  → duration/timing) + prevSlideStyle/nextSlideStyle appended. Content = the caller's Html
  verbatim. Duplicates via duplicateWrap (clones reuse the same Html).
- usercontrol: per-slide classless wrapper div style=slideStyles[i] + `display: none` on
  inactive (vShow), direct child of track.
- Dots (showDots && displayTotalView>1): `n-carousel__dots n-carousel__dots--{dotType}`
  role="tablist"; children `n-carousel__dot [--active]` role="button" tabindex="0"
  aria-selected. Handlers: click→onDotTo (iff trigger=click), mouseenter→onDotTo (iff
  hover), keydown→onDotKeydown (SETTLED: the view decodes code+modifiers; Enter/Space fire
  `onDotTo i` DIRECTLY port-side — CarouselDots.tsx:41-53 — other keys route to
  onDotKeydown for the caller to apply dotKeyAction → prev/next).
- Arrows (showArrow): `n-carousel__arrow-group`; two `n-carousel__arrow [--disabled]`
  role="button" + svg viewBox="0 0 16 16" → g fill="none" → path fill="currentColor" with
  d-bytes copied VERBATIM from `/home/titan/Works/elm/naive-ui/src/carousel/src/CarouselArrow.tsx`
  (do not retype — read the file and copy).
- Number formatting: Floats via String.fromFloat (upstream `${n}`; -0 → "0").

## Hard rules (house conventions — non-negotiable)

- Gate after EVERY step you take a commit for (here: one commit at the end):
  `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` — 8/8 must hold; counts stay 3838/3838
  assertions + 2336 DOM data-total, 0 failures (feat adds no pins). Run it in FOREGROUND.
- elm-format WITH --yes on every touched elm file (src + examples separately).
- Elm record-update CANNOT apply to qualified names — bind locals first. First compile
  error is almost always that.
- apply_patch anchors on short unique seams; compile after multi-edit batches.
- The algebra must reproduce pins §A numbers EXACTLY (A1-A5); where the derivation notes a
  `[!]` flag (A5 drag-to-clone long animate), mirror the BYTES anyway — the oracle round
  rules on it later.
- NO git -A; explicit paths only; tasks/ stays untracked.
- COMMIT: `git add src/NUI/Carousel.elm elm.json examples/src/Main.elm README.md
  tools/verify/check-dom.mjs` then `git commit` with message:
  `feat(carousel): NUI.Carousel — raw-Html track/dots/arrows + pure geometry/index/drag engine + examples + README + check-dom`
  (body: 3-6 bullets — line counts, Env surface, divergences count, rendering strategy.)
- After committing: `git log --oneline -2` + `git status --short` — clean except tasks/.

## Tool hygiene (repeat-call guard KILLS sessions)

Never issue the same tool call twice with identical arguments — vary ranges/patterns.
If a read fails once, switch method instead of retrying.

## Report back

1. Commit hash + wc -l src/NUI/Carousel.elm + files changed.
2. Gate tail (quote it) — assertions/DOM numbers.
3. Any deviation from carousel-2 and why (flag honestly; do NOT silently decide).
4. Confirm the two arrow d-strings were copied verbatim from CarouselArrow.tsx.
