# BRIEF — oracle(carousel): byte-fidelity audit (READ-ONLY; you commit nothing)

You are an independent fidelity auditor for the just-landed Carousel port. Work in
`/home/titan/Works/elm/elm-naive-ui` (master). You may READ everything and RUN builds/gates,
but you MUST NOT edit any file or commit. Deliver findings as a report in your final message
(the orchestrator transcribes them into tasks/recon/carousel-oracle.md and fixes S findings).

## What to audit

The port `src/NUI/Carousel.elm` (+ examples carouselSection + check-dom target) against
upstream naive-ui v2.45.3 carousel.

## Path map (read-only)

- Upstream (verbatim): /home/titan/Works/elm/naive-ui/src/carousel/ — Carousel.tsx,
  CarouselItem.tsx, CarouselDots.tsx, CarouselArrow.tsx, CarouselContext.ts, interface.ts,
  utils/{index,duplicatedLogic,event}.ts, src/styles/index.cssr.ts, styles/{light,dark}.ts,
  tests/Carousel.spec.tsx
- Port: src/NUI/Carousel.elm, src/NUI/Theme/Carousel.elm (generated), elm.json,
  examples/src/Main.elm (carouselSection), tools/verify/check-dom.mjs,
  tests/src/Main.elm + tests/inspect.mjs (carousel blocks)
- Recon (the port's claimed contract — audit AGAINST the bytes, not against the recon):
  tasks/recon/carousel-1-upstream.md, carousel-2-elm.md, carousel-pins.md

## Method (byte-level)

1. Walk Carousel.tsx render (:1000-1063) → root class array ORDER + gates (:1002-1011),
   listener spread (:866-871, 1012-1016), slides container (:1019-1046: role, translateStyle,
   transitionend, usercontrol wrapper branch vs plain), dots gate + default (:1048-1060),
   arrow gate (:1061-1063). Diff against the port's view.
2. CarouselItem.tsx render (:60-100): class order (--current/--prev/--next), role=option,
   tabindex, data-index (REAL duplicate-inclusive space), aria-hidden "true"/"false",
   getSlideStyle composition (base + prevSlideStyle + nextSlideStyle, Carousel.tsx:541-556).
3. CarouselDots.tsx (:96-137): tablist/button roles, aria-selected, --{dotType}, --active,
   per-trigger handler wiring, keyboard matrix (:41-94 — Enter/Space precede the keyboard
   matrix; modifier + input/textarea guards; direction-aware PageUp/Down/arrows).
4. CarouselArrow.tsx: group/arrow/--disabled, role=button, SVG d-strings VERBATIM (diff
   char-by-char; transcription slips are S findings), g fill=none, path fill=currentColor,
   viewBox 0 0 16 16.
5. Pure algebra vs bytes (THE core of this audit — Carousel.tsx:171-519, 593-755, 803-864):
   - computed chain (:171-201) incl. duplicatedable = loop && spv===1 && slide
   - slideSizes both branches (:203-227: measured-auto vs remaining*percentage), translates
     accumulation + centered offset (:228-246), totalView both branches (:295-317 incl. the
     auto while-loop), displayTotalView
   - seed chain (:323-341) — NOTE the port intentionally seeds with TRUE slide count
     (documented divergence, pins A6); verify the docstring says so
   - toRealIndex clamp/emit (:343-356), to (:396-409, totalView upper clamp quirk),
     prev/next (:410-422), guarded variants (:428-436)
   - THE index-change pipeline: realIndex watcher (:803-837) — display→real REFLOW after the
     write, the two duplicatedable loop-jump normalizations (expected -1: last==1 &&
     next==len-2 → 0; expected 1: last==len-2 && next==1 → len-1), translateTo with speed,
     fixTranslate on non-slide, expectedDirection reset
   - translate machinery (:440-519): updateTranslate key order (duration, timingFunction,
     transform), inTransition conditions, previousTranslate := getTranslate(REAL index)
     even under normalization (:463), getTranslate last-view branch, getLastViewTranslate
     both branches, handleTransitionEnd (:715-727: snap + '0ms' + inTransition=False)
   - drag (:593-713): clamped dragOffset, touchend scan list slice(0, totalView-1) +
     lastView, nearest-loop break condition, velocity rules (>perView/2 || >0.4 → prev;
     < -perView/2 || < -0.4 → next), isEffectiveDrag latch, card click → to(index)
     (:565-577)
   - mousewheel (:728-755): shift fallback, m sign, responseStep 10, inTransition guard
   - watches (:838-864): duplicatedable/displaySlidesPerView → toRealIndex(realIndex);
     translates deep → fixTranslate; sequenceLayout toggle → updateTranslate(0)/fixTranslate
   - autoplay gating (:579-591: !autoplay || displayTotalView<2)
6. cssVars: 8 vars, ORDER (Carousel.tsx:903-925), values vs styles/light.ts 7-key self
   (dark = common swap, no override). Diff cssVarsFor + src/NUI/Theme/Carousel.elm +
   tools/generated/carousel.json.
7. State/Env/Options field audit vs carousel-2 §1-2: every upstream default mapped exactly;
   every Maybe-msg channel wired at the right element with the right gate.
8. Sanity-run: `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` → confirm 8/8, note totals.
9. Pins honesty: re-derive §A of carousel-pins.md FROM THE BYTES; flag any test circular
   (derived from the port). SPECIAL: pins A5(a) claims the drag-to-clone settle animates the
   LONG way (400→4000) because expectedDirection is 0 during dragEnd — verify or refute
   from the bytes; A6 defaultIndex seed quirk likewise.

## Severity

- S = port bug (DOM/algebra/bytes diverge from upstream): MUST fix. Cite file:line both sides.
- D = documented divergence or intentional gap: verify the docstring/doc covers it; new ones
  → list as D findings.
- R = risk/observation, no action.

## Output format (final message)

```
VERDICT: N S findings, N D findings, N R
S1..Sn: [title] upstream <path:line> vs port <path:line> — expected X, got Y — fix hint
D1..Dn: [title] — one line each (cite the docstring that covers it, or 'UNDOCUMENTED')
R1..Rn: one-liners
pins: honest|circular(N)
gate: <tail line>
```

## Tool hygiene

Never repeat an identical tool call back-to-back — vary ranges/flags. Use sed -n ranges and
grep -n; avoid dumping whole files twice. If a read is blocked, switch method rather than retry.
