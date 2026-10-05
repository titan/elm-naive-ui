# carousel-oracle.md — oracle audit (transcribed from the lane's final message)

Commit audited: `bc721dd` (feat `7b40a44` + fix `5f94bdf`). Read-only lane; method notes:
byte-checked claims, three empirically confirmed (Vue SSR of the usercontrol pattern to
see where `vShow` lands; `elm repl` reads of the port's actual state values; jsdom dumps
of the built fixture DOM).

**VERDICT: 4 S findings, 8 D findings, 5 R** → all 4 S fixed in `36e076c`.

## S findings (all fixed in 36e076c)

- **S1 usercontrol branch drops the nested `.n-carousel__slide` node** (and put
  `display:none` on the wrong element). Upstream `Carousel.tsx:1035-1043` maps the
  NCarouselItem vnodes into the wrappers — each wrapper contains a real
  `div.n-carousel__slide[role=option][tabindex=-1][data-index][aria-hidden]`, and `vShow`
  (SSR-confirmed) sets `display:none` ON that inner slide. Also: the usercontrol
  `slideStylesRef` branch returns early — size only, NO margin. Fix: `userControlWrapper`
  wraps a `slideNodeUC`; display:none moved onto the item.
- **S2 dragEnd velocity branch: final translate flipped.** Upstream Vue `watch(realIndexRef…,
  {flush:'pre'})` is ASYNC: in the flick branch `prev()`/`next()` only write the display
  index (queueing the watcher), the sync `else` branch runs `fixTranslate(speed)` →
  `translateTo(real)`, and the queued watcher body lands AFTER it — final translate is the
  loop-jump CLONE target (0), with `transitionend` snapping back later. The port's eager
  `applyIndexChange` ran before `fixTranslate`, ending at 4000 (the long-way animate).
  Reproduced via `elm repl` (`.translate = 4000`); confirmed the port now ends at 0.
- **S3 non-sequence effects emit a track style upstream omits.** `translateStyleRef` stays
  `{}` for fade/card/custom (`updateTranslate` never runs: the watcher's translateTo is
  sequence-gated; `fixTranslate`'s non-seq branch gates on `previousTranslate !== 0`) ⇒ NO
  style attribute on `__slides`. Same root cause leaked the live drag offset onto
  non-sequence tracks (`handleTouchmove` is sequence-gated, `Carousel.tsx:657`). Fix:
  `slidesNode` emits the style attr only under `sequenceLayout`.
- **S4 `onSlideClick` channel declared but never wired.** Upstream
  `onCarouselItemClick` (`Carousel.tsx:565-577`): `effect==='card' && allowClick &&
  !isRealActive` → `to(index)` (+suppression). Fix: listener attached when the gate
  passes; suppression stays caller-side (documented).

## D findings (verified documented)

- D1 defaultIndex seed = TRUE slide count (module notes + pins §A6). ✓
- D2 prevSlideStyle/nextSlideStyle string-only. ✓
- D3 transitionStyle narrowed to the 2 `keep()`ed keys. ✓
- D4 isMounted rAF → `markMounted`. ✓
- D5 custom effect `display:none` instead of Vue Transition (placement itself was S1). ✓
- D6 root style = house `renderVars` form (house-wide). ✓
- D7 renderDots/renderArrow wrapped in `display:contents` div, reduced payloads. ✓
- D8 measurement/timer/focus/globalDragging caller-side. ✓

## R findings (no action)

- R1 dot Enter/Space matched on `e.code` (`"Enter"|"Space"`) vs upstream `e.key`
  (`'Enter'|' '`) — equivalent for real events.
- R2 `decodeDragPoint` reads top-level clientX/Y (touch coords live on `touches[0]`) —
  docstring already says touch callers supply their own decoder.
- R3 `dotKeyAction` lacks the disabled-gate (net-effect harmless; focusDot caller-side).
- R4 the eager-`applyIndexChange` modeling behind S2 is invisible at every other call site.
- R5 `to()`'s upper clamp `totalView` — faithful, re-clamped.

## Pins honesty

Re-derived §A1–A5 from bytes — honest; A4 correction (1500) confirmed right; A5(a)
drag-to-clone long-animate CONFIRMED (expectedDirection 0 during dragEnd ⇒ no
normalization); A6 seed quirk correct + documented. **§D10 was circular** (matched the
port's wrong usercontrol reading) — re-pinned in `36e076c` from `Carousel.tsx:1035-1043`
+ SSR, plus new probes: S2 eq pins (flick END translate 0 / 2000), S3 track-style probes
(fade/card/custom none; slide keeps). §D8/§D1 previously never probed the non-sequence
track — S3 is now sampled.

## Gate after fixes

`8/8`; `3992 assertions — 3992 passed, 0 failed`; DOM `data-total=2426 data-failures=0`;
elm-format `[]`; `ALL CHECKS PASSED`.
