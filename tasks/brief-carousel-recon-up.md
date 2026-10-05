# Brief: Carousel upstream recon (read-only) — naive-ui v2.45.3

You are a recon lane for the elm-naive-ui port project. Upstream reference tree (READ-ONLY):
`/home/titan/Works/elm/naive-ui` (naive-ui v2.45.3). Main workspace:
`/home/titan/Works/elm/elm-naive-ui` (do not touch ANY tracked file there).

## Task
Study the ENTIRE upstream carousel surface and write ONE file:
`/home/titan/Works/elm/elm-naive-ui/tasks/recon/carousel-1-upstream.md`

Cite every claim as `path:line` relative to `src/carousel/`. The orchestrator has already
deep-read Carousel.tsx, all three child components, CarouselContext.ts and both utils files —
those sections exist to CROSS-CHECK and EXTEND (exact line cites + anything missed), so be
precise, not prose-y. Your unique value: styles/index.cssr.ts (358 L), theme files, tests,
demos, index.ts exports.

## Required sections (in this order)

1. **File inventory** — every file under src/carousel with line counts and one-line role.
2. **Public API** — every prop with name/type/default (carouselProps, Carousel.tsx:73-146),
   controlled/uncontrolled pair (`currentIndex` vs `defaultIndex`), both update callbacks
   (`onUpdate:currentIndex` + `onUpdateCurrentIndex`, signature `(currentIndex, lastIndex)`),
   all slots (default/arrow/dots) with their slot-prop shapes (interface.ts), the exposed
   instance methods (CarouselInst), and `NCarouselItem`'s scoped-slot props
   ({isPrev,isNext,isActive,index}).
3. **DOM tree byte-map (THE IMPORTANT PART)** — for each rendered element, the EXACT class
   list construction order and gates, attributes, and style sources:
   - root div (Carousel.tsx render): full class array order incl. themeClass, `--vertical`,
     `--show-arrow`, `--{dotPlacement}`, `--{direction}`, `--{effect}`, `--usercontrol`; which
     listeners get spread (touchstartPassive/mousedown/wheel gates); mouseenter/leave.
   - the VResizeObserver wrapper(s) and `__slides` div: role, style (translateStyle — initial
     value AND post-`updateTranslate` shape, key order), onTransitionend; the usercontrol
     branch (per-slide wrapper div + Transition + vShow) vs the plain branch.
   - CarouselItem.tsx: `__slide` div classes (`--current`/`--prev`/`--next` gates), role,
     tabindex, data-index (which index space — real incl duplicates?), aria-hidden rendering,
     style (getSlideStyle composition: slideStyles + prevSlideStyle/nextSlideStyle normalize),
     onClickCapture → onCarouselItemClick (incl. the `card` effect to() behavior).
   - CarouselDots.tsx: `__dots` + `--{dotType}` classes, role=tablist; per-dot div: role=button,
     tabindex, aria-selected, `__dot` + `--active` classes; which handlers fire per trigger
     mode; the keyboard handler's exact key matrix (PageUp/Down, arrows, direction-aware,
     modifier guards, activeElement nodeName guards) and focusDot.
   - CarouselArrow.tsx: `__arrow-group`, two `__arrow` divs + `--disabled` gates, role=button,
     the two SVG d-strings BYTE-VERBATIM (record them exactly), fill=currentColor, g fill=none.
4. **State machine & pure algebra (cross-check)** — with exact line cites: computed chain
   (vertical/sizeAxis/spaceAxis/sequenceLayout/duplicatedable/userWantsControl/
   displaySlidesPerView/realSlidesPerView/autoSlideSize), slideSizes formula (both branches:
   measured auto vs `remaining*percentage`), slideTranslates accumulation (centeredSlides
   offset), transitionStyleRef `keep()` filter, speed/usercontrol=0, slideStyles (useComputedSize
   gate, margin-spaceAxis, fade/card+isMounted transitionStyle merge), totalView (both branches
   incl. the auto while-loop), displayTotalView, display↔real index mapping + clamp/emit in
   toRealIndex/to/prev/next, the realIndex watcher's duplicated loop-jump normalization
   (expectedTransitionDirection cases), translate machinery (updateTranslate/fixTranslate/
   translateTo/getTranslate/getLastViewTranslate both branches, inTransition + previousTranslate
   side-channels), drag flow (globalDragging, clamped dragOffset, touchend nearest-translate
   loop + 50%/0.4px-per-ms velocity rules, card click), mousewheel (responseStep 10, shift
   deltaX fallback, direction matrix, inTransition guard), autoplay (setInterval next,
   displayTotalView<2 disable, hover pause), the watches (duplicatedable/displaySlidesPerView
   → toRealIndex; slideTranslates deep → fixTranslate; sequenceLayout toggle), onUpdated slide
   re-sort, and which quantities are DOM-MEASURED (perViewSize via calculateSize(selfEl,true)
   innerOnly; auto-mode per-slide sizes; VResizeObserver triggers). Flag any you believe the
   orchestrator's summary above got wrong or missed.
5. **cssr styles byte-map** — styles/index.cssr.ts (358 L): EVERY rule selector in order with
   the vars/properties it consumes, the `-carousel--usercontrol`/effect/direction/dotPlacement/
   dotType variants, any global/mount-based rules (cagr styleMount), slides/slide/arrow/dots
   rules incl. hover/focus/active states and transition declarations. This feeds the port's
   css extraction and DOM probes, so selector strings must be exact.
6. **Theme** — styles/light.ts + dark.ts: the self key list (expect dotSize, dotColor,
   dotColorActive, dotColorFocus, dotLineWidth, dotLineWidthActive, arrowColor — confirm
   EXACTLY, with light vs dark values and which common vars feed cssVars
   (Carousel.tsx cssVarsRef, 8 vars). Note any dark self-override subtlety.
7. **Tests inventory** — Carousel.spec.tsx (437 L) + server.spec.tsx: what behaviors are
   pinned upstream (list each `it()` with one line), especially anything the port's pins doc
   should mirror; note the duplicated-index expectations and any autoplay/vi-timer tests.
8. **Demos inventory** — every demo file under demos/ (enUS+zhCN pairs) with one line each.
9. **Port-fit assessment** — which parts are pure Elm (index algebra, geometry given container
   size, drag settle, wheel gating) vs DOM-bound (measurement, focus, native transitionend,
   setInterval) and any edge cases that will become accepted divergences (e.g. transitionProps
   Vue-specific, globalDragging singleton, focusDot).

## Hard constraints
- READ-ONLY on both trees except writing the single output file above. NO `git` at all. NO
  commits. NO builds. NO npm.
- Tool hygiene: never issue the same tool call twice; if a read fails once, note it and move on.
  A repeated identical failing call can kill this session.
- Do not paste entire upstream files — extract, cite, and only quote byte-critical strings
  (selectors, class names, d-strings) exactly.
- Finish with the doc written, then reply with a ≤10-line summary + the doc path.
