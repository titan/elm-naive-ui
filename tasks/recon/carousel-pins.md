# Carousel pins (derived from upstream bytes BEFORE the port)

House rule: every pin below is derived from naive-ui v2.45.3 source (cites relative to
`src/carousel/`), NOT from the port. Worked numbers first (§A) so REDs can be re-derived.

## §A Worked derivations (the numbers behind the pins)

### A1. Geometry, 4 slides, spv=1, loop, perViewSize {w:1000, h:400}
- duplicatedable (loop && spv==1 && slide) → totalSlides = 6 (clone-last, s0..s3, clone-first)
- slideSizes: non-auto branch, spv=1 → remaining = 1000 - 0 = 1000, percentage 1 → 1000 each
- translates (Carousel.tsx:228-246, space 0, not centered): [0,1000,2000,3000,4000,5000]
- totalView (Carousel.tsx:295-301) = max(6-1,0)+1 = 6; displayTotalView = 6-2 = 4
- seed: defaultIndex 0 → real 1 → display getDisplayIndex(1,6,T) = 0 → realIndex 1
- post-measure initial translate: translateTo(1, 300) → getTranslate(1) = 1000 →
  inTransition True (1000≠0), previousTranslate := 1000
- isPrev/isNext at real 1: prev=0 (clone), next=2

### A2. Loop-jump pipeline (THE technique — Carousel.tsx:803-837 + reflow derivation)
prev() at display 0 / real 1 (state: previousTranslate 1000, inTransition False):
1. expectedDirection := -1; getRealPrevIndex(1) = 0; toRealIndex(0)
2. display' = getDisplayIndex(0,6,T) = 6-3 = 3 (≠0) → write → realIndex RE-FLOWS to
   getRealIndex(3) = 4
3. watcher: (last=1, next=4=length-2, expected=-1) → case 1 → normalized := 0
4. translateTo(0, 300): translate = translates[0] = 0; 0≠1000 && speed>0 → inTransition True;
   previousTranslate := getTranslate(realIndex=4) = 4000  ← REAL index, not the normalized 0
   (Carousel.tsx:463); transform animates 1000 → 0 (prepended clone shows s3)
5. transitionend: slide && inTransition → translateTo(4, 0): translate 4000 == previousTranslate
   4000 → no inTransition change; updateTranslate(4000, 0) = INSTANT snap (same content);
   transitionDuration forced '0ms'; inTransition := False; expectedDirection stays 0
Next/append case is the mirror: at real 4 (display 3) next() → getNextIndex(4,6,T)=0 →
toRealIndex(0)?? NO — getNextIndex(current=4): 4===length-1? no → 5. toRealIndex(5) →
display' = getDisplayIndex(5,6,T) = 0 → reflow real 1 → watcher (last=4=len-2, next=1,
expected=1) → case 2 → translateTo(5, 300) (appended clone) → transitionend snap to 1.
EDGE: dots `to(0)` from display 3: expected=0 → NO normalization → translateTo(1,300) —
the long backward animate is upstream behavior (no shortcut).

### A3. Geometry, spv=3, spaceBetween=20, loop=False, 4 slides, perView 1000
- not duplicatedable → totalSlides 4; slideSizes: remaining = 1000-2*20 = 960, pct 1/3 →
  320 each; translates [0, 340, 680, 1020]
- totalView = max(4-3,0)+1 = 2; displayTotalView 2; dots count 2
- useComputedSize = !(auto || spv==1) = True → slide style `width: 320px` + `margin-right: 20px`
- at display 0: --next on 1; NO --prev (getPrevIndex(0,4,F) = Nothing); arrows: prev disabled

### A4. Centered auto (centeredSlides + spv auto), measured sizes, perView 1000
sizes [600,200,1000,400], space 0 (centered demo uses 30 — 0 keeps numbers clean):
- translates: t0 = 0+(600-1000)/2 = -200; prev=600; t1 = 600+(200-1000)/2 = 200; prev=800;
  t2 = 800+(1000-1000)/2 = 800; prev=1800; t3 = 1800+(400-1000)/2 = 1500; prev=2200
  → [-200, 200, 800, 1500]
- totalView auto loop (Carousel.tsx:301-316): lastViewSize=400 <1000 → i=3, lastViewSize
  += t[3]-t[2] = 700 → 1100; stop (i>1 but 1100≥1000) → clamp(4,1,4) = 4
  [NOTE: for centered+auto, displaySlidesPerView is forced to 1 (Carousel.tsx:186-189)
  so totalView actually takes the NUMERIC branch max(4-1,0)+1 = 4 — same number here]
- getLastViewTranslate: displaySlidesPerView is 1 (NOT 'auto') for centered+auto →
  NUMERIC branch → translates[totalView-1] = 1500.
  CORRECTED: was pinned 900 via the auto branch (wrong gate — autoSlideSize ≠
  displaySlidesPerView==='auto'); re-derived from Carousel.tsx:478-497 by the
  orchestrator after the feat lane flagged it.

### A5. Drag settle (4 slides, dup, perView 1000; Carousel.tsx:647-692)
start display 0 / real 1, previousTranslate 1000, not inTransition. dragMove → dragOffset
600 (clamped to ±1000). handleTouchend:
- currentTranslate = 1000-600 = 400
- scan list = translates[0..4] + lastView(5000) = [0,1000,2000,3000,4000,5000]; offsets from
  400: [400,600,…] → break at i=1 → currentIndex 0
- currentIndex 0 ≠ realIndex 1 → isEffectiveDrag := True; toRealIndex(0) → display 3 →
  reflow real 4; watcher (expected=0) → NO normalization → translateTo(4, 300): 4000≠1000 →
  inTransition True; previousTranslate := 4000. [!] The track animates 400 → 4000 (long
  forward) even though the drag was toward the prepended clone at 0 — derived from bytes;
  flag for oracle cross-check.
- same-index release (dragOffset 200 → nearest 1000 == current): currentTranslate 800,
  offsets [800, 200,…] → i stays... i0: |0-800|=800 set; i1: |1000-800|=200 < 800 → set cur=1;
  i2: 1200 > 200 break → currentIndex 1 == realIndex → velocity branch:
  dragOffset 200 < 500 and 200/1000ms = 0.2 < 0.4 → no move → fixTranslate(speed) →
  translateTo(1, 300) (restore), resetDragStatus. Fast flick: 200px in 400ms = 0.5 > 0.4 → next()

### A6. defaultIndex seed quirk (Carousel.tsx:323-333) [FLAG — oracle]
Upstream seeds `ref(getDisplayIndex(getRealIndex(defaultIndex, dup), totalViewRef.value, dup))`
during SETUP — totalViewRef.value evaluates with slideElsRef STILL EMPTY → totalView 1 →
getDisplayIndex(_, 1, _) = 0 for EVERY defaultIndex (both dup and non-dup). Post-mount nothing
re-seeds it (the [duplicatedable, displaySlidesPerView] watch fires on change only). Derived
consequence: upstream defaultIndex > 0 renders at display 0. PORT DECISION: seed with the
TRUE slide count (the evident intent — display = getDisplayIndex(getRealIndex(defaultIndex,
dup), totalView, dup)); docstring documents the upstream setup-order quirk. Pins pin the
INTENDED semantics.

## §E eq pins (tests/src/Main.elm)

1. resolveSpeed: "300ms"→300, ".5s"→500, "2s"→2000, "10"→10, "1.5s"→1500, "0.4s"→400,
   "1."→0, "ms"→0, "abc"→0, ""→0, Nothing→0 (utils/index.ts:26-37)
2. clampValue: (5,0,3)→3, (-1,0,3)→0, (2,0,3)→2, (7,0,10)→7
3. getDisplayIndex: (0,6,T)→3, (5,6,T)→0, (2,6,T)→1, (2,6,F)→2, (x,1,T)→0, (0,1,F)→0
4. getRealIndex: (0,T)→1, (3,T)→4, (3,F)→3
5. getPrevIndex: (0,6,T)→Just 5, (0,6,F)→Nothing, (0,4,F)→Nothing, (3,6,*)→Just 2,
   (-1,6,T)→Nothing
6. getNextIndex: (5,6,T)→Just 0, (5,6,F)→Nothing, (3,4,F)→Nothing (>len-1), (2,6,*)→Just 3
7. getDisplayTotalView: (6,T)→4, (4,T)→2, (3,T)→3, (6,F)→6
8. duplicateWrap: [a,b,c]→[c,a,b,c,a]; [x]→[x]; []→[]
9. envOf A1: translates/totalView/displayTotalView/realIndex/speed 300/autoplayEnabled False
10. envOf A3: slideSizes 320, translates [0,340,680,1020], totalView 2, useComputedSize style
    parts "width: 320px" + "margin-right: 20px", no --prev at 0
11. envOf A4: translates [-200,200,800,1500], totalView 4, lastViewTranslate 1500 (CORRECTED)
12. prev() pipeline A2 steps 1-4: displayIndex→3, expectedDirection→0, inTransition True,
    previousTranslate 4000; + transitionEnd step 5: displayIndex 3, inTransition False,
    snap translate 4000 (duration '0ms')
13. next() append case mirror (A2): from real 4 → display 0, previousTranslate 1000
    (getTranslate(1)), animate target 5000 (appended clone), transitionEnd snap 1000
14. to(0) from display 3 (A2 edge): no normalization, translateTo(1,300) — translate 1000
15. dragEnd A5 both branches: (a) settle-to-0 → display 3, isEffectiveDrag True,
    inTransition True, previousTranslate 4000; (b) same-index slow → display 0, translate
    restored 1000, isEffectiveDrag False; (c) same-index flick right (dragOffset +200 in
    400ms = 0.5 > 0.4) → prev → the loop-jump pipeline → display 3, animate target 0
    (clone), previousTranslate 4000; (d) same-index flick LEFT (dragOffset -200/400ms =
    -0.5 < -0.4) → next → display 1
16. dragMove clamp: offset 1500 → dragOffset 1000; -1500 → -1000
17. wheel: horizontal {dx:15,dy:0} → next (display+1); {dx:-15} → prev; {dx:0,dy:20} → no-op
    (rx*0 < 10); vertical {dy:12} → next; shift {dx:0,dy:12,shift} → next (deltaX fallback);
    responseStep: {dx:9} → no-op; inTransition → no-op
18. dotKeyAction: horizontal {ArrowRight}→ToNext, {PageUp}→ToNext, {ArrowLeft}→ToPrev,
    {PageDown}→ToPrev; vertical {ArrowUp}→ToNext, {ArrowDown}→ToPrev; {shift+ArrowRight}→None;
    {Enter}/{Space} handled by the view channel (to i), not dotKeyAction — pin only the
    matrix keys
19. indexChange: (0→1)→Just(1,0); (1→1)→Nothing
20. autoplayEnabled: (autoplay T, dtv 4)→True; (autoplay T, dtv 1)→False; (autoplay F, _)→False

## §D DOM probes (tests/inspect.mjs; port static output at fixture-fed sizes)

1. basic (A1 fixture, perViewSize fed {1000,400}): root classes exactly
   `n-carousel n-carousel--bottom n-carousel--horizontal n-carousel--slide`; slides div
   role=listbox, style contains `transition-duration: 300ms` and `transform: translateX(-1000px)`;
   6 slide divs; data-index 0..5; aria-hidden true except [data-index="1"]; --current on 1,
   --prev on 0, --next on 2; slide style `margin-right: 0px`; 4 dots, dot[0] --active +
   aria-selected true; role tablist/button; tabindex 0
2. vertical: direction token renders in BOTH slot #3 (the `--vertical` gate) and slot #6
   (`--{direction}`) → class attribute contains `n-carousel--vertical` TWICE:
   `n-carousel n-carousel--vertical n-carousel--bottom n-carousel--vertical n-carousel--slide`.
   Probe asserts the class attribute string (not classList, which dedupes)
3. dotPlacement left: `n-carousel--left` present (before --horizontal token); right; top
4. dotType line: dots div `n-carousel__dots n-carousel__dots--line`
5. showArrow: `n-carousel--show-arrow` + __arrow-group + 2 __arrow divs role=button + svg
   path d strings byte-verbatim (backward `M10.26 3.2a.75.75 0 0 1 .04 1.06L6.773 8l3.527
   3.74a.75.75 0 1 1-1.1 1.02l-4-4.25a.75.75 0 0 1 0-1.02l4-4.25a.75.75 0 0 1 1.06-.04z`,
   forward `M5.74 3.2a.75.75 0 0 0-.04 1.06L9.227 8L5.7 11.74a.75.75 0 1 0 1.1 1.02l4-4.25a.75
   .75 0 0 0 0-1.02l-4-4.25a.75.75 0 0 0-1.06-.04z`); loop=True → no --disabled
6. loop=False at display 0: first __arrow has --disabled, second not; no clones (4 slides);
   no --prev slide
7. spv=3/space=20 (A3): slide style `width: 320px` + `margin-right: 20px`; 2 dots;
   spaceBetween 25 variant: first slide style `margin-right: 25px` (upstream spec #13)
8. fade: root --fade; slides role/attrs same; mounted=False → NO transition-duration on
   slide styles; mounted=True fixture → slide style contains `transition-duration: 300ms`
9. card: root --card; prevSlideStyle/nextSlideStyle strings appear appended on --prev /
   --next slide styles (custom-card demo transforms)
10. custom: root --usercontrol; plain wrapper divs (classless) INSIDE __slides each wrapping
    a real `n-carousel__slide` item (data-index 0..3, aria-hidden); vShow's `display: none`
    on INACTIVE INNER ITEMS, active items carry no style; wrappers style = size only (spv 1
    custom → no style at all). CORRECTED after the oracle round (the original §D10 text
    matched the port's wrong reading — circular; re-derived from Carousel.tsx:1035-1043 +
    Vue SSR of the vShow pattern). Non-sequence tracks (fade/card/custom) carry NO style
    attribute at all (translateStyleRef stays {}) — only sequence (slide) tracks do
11. showDots False: no __dots node. 1 slide (displayTotalView 1): no __dots node either
12. cssVars on root style: all 8 --n-* present with theme values (light defaults:
    --n-dot-size 8px etc.)
13. trigger hover: dots still rendered (assert channel wiring only via eq pins — no attr)
14. defaultIndex 2 (4 slides, loop): current slide data-index="3", dots[2] active
    (INTENDED semantics per A6)

## §T traps for the port

- `-0` formatting: JS `${-0}` → "0"; Elm `String.fromFloat (0 - 0)` → "0". Match.
- translateStyle key order: transitionDuration (+timingFunction) FIRST, then transform
  (Object.assign order, recon §3.2) — style string `transition-duration: 300ms;
  transform: translateX(-1000px)`.
- transitionDuration on slides div is the SPEED (ms number re-serialized), and
  handleTransitionEnd forces '0ms' after a slide-mode transition end.
- data-index is the REAL (duplicate-inclusive) index; aria-hidden renders as
  "true"/"false" strings; dots use the DISPLAY index.
- previousTranslate is set from the REAL index even when the watcher normalized the
  translate target to a clone (A2 step 4).
- `to()`'s clamp upper bound is totalView (off-by-one upstream, harmless — re-clamped).
- The dots component remounts on dotType/dotPlacement change (concatenated key) — port has
  no keys; irrelevant to static DOM.
- getSlideStyle composition order: base slideStyles, then prevSlideStyle, then
  nextSlideStyle (normalizeStyle array order — later wins).
- slide count 0/1: addDuplicateSlides no-op (length>1 guard); displayTotalView of 1 →
  getDisplayIndex(anything,1,_) = 0; dots suppressed (total>1 gate).
