# carousel-1-upstream.md — naive-ui v2.45.3 `Carousel` upstream map

Read-only recon. Upstream mount: `/home/titan/Works/elm/naive-ui` (naive-ui v2.45.3).
All `path:line` cites are relative to `src/carousel/` unless a `src/`/root prefix is shown.
Cross-checks the orchestrator's deep-read of `Carousel.tsx`, the three child components,
`CarouselContext.ts` and both utils; the unique-value material is `styles/index.cssr.ts`,
the theme files, tests, and demos. Byte-critical strings (class tokens, d-strings) are quoted
exactly; nothing upstream is pasted wholesale.

---

## 1. File inventory

| File | Lines | Role |
| --- | --- | --- |
| `index.ts` | 8 | Package barrel: exports `NCarousel`, `carouselProps`, `NCarouselItem`, and types `CarouselProps`, `CarouselSlots`, `CarouselArrowSlotProps`, `CarouselDotSlotProps`, `CarouselInst`. **No `internal`/`sub-component` exports** (no `CarouselDots`/`CarouselArrow`/context/utils public). |
| `src/Carousel.tsx` | 1074 | Root component + `carouselProps` + all state machine, drag/wheel/autoplay, render tree. The whole machine lives here. |
| `src/CarouselItem.tsx` | 101 | `NCarouselItem` (`name: 'CarouselItem'`), export `isCarouselItem(vnode)`, `__slide` div render + per-item scoped slot props. |
| `src/CarouselDots.tsx` | 138 | `NCarouselDots`: `__dots` `role=tablist`, per-dot divs, click/hover/keyboard. Props are module-local (`carouselDotsProps`), **not exported**. |
| `src/CarouselArrow.tsx` | 77 | `NCarouselArrow`: `__arrow-group` + two `__arrow` divs, two inline SVG glyph fns (`renderBackwardIcon`/`renderForwardIcon`). No props. |
| `src/CarouselContext.ts` | 47 | `CarouselContextValue` interface, `carouselMethodsInjectionKey` (`'n-carousel-methods'`), `provideCarouselContext`, `useCarouselContext` (throws outside a carousel). |
| `src/interface.ts` | 41 | `CarouselInst`, `ArrowScopedSlotProps`, `DotScopedSlotProps`, `Size`, `CarouselArrowSlotProps`, `CarouselDotSlotProps`. |
| `src/styles/index.cssr.ts` | 358 | The only cssr file; selector byte-map (§5). |
| `src/utils/index.ts` | 38 | re-exports duplicatedLogic + event; `calculateSize(el, innerOnly)`, `clampValue`, `resolveSpeed`. |
| `src/utils/duplicatedLogic.ts` | 79 | Duplicate-slide + display↔real index algebra (§4). |
| `src/utils/event.ts` | 3 | `isTouchEvent(e)` only. |
| `styles/light.ts` | 28 | `self()` (7 keys), `carouselLight`. |
| `styles/dark.ts` | 11 | `carouselDark` — **reuses `self` from light, no dark self-override**. |
| `styles/index.ts` | 7 | barrel for both themes + theme types. |
| `tests/Carousel.spec.tsx` | 437 | 16 `it()` blocks (§7). |
| `tests/server.spec.tsx` | 20 | SSR smoke test only. |
| `demos/enUS/*` `demos/zhCN/*` | 18 pairs + `index.demo-entry.md` | §8. |

No `rtl.cssr.ts` in this component (directory has none) — the port's manifest cssr list must
therefore **not** add an rtl entry for carousel.

---

## 2. Public API

### 2.1 Props — `carouselProps` (`Carousel.tsx:73-146`; spread `useTheme.props` first, `73`)

| Prop | Type (PropType) | Default | Line |
| --- | --- | --- | --- |
| `defaultIndex` | `Number` | `0` | 74-77 |
| `currentIndex` | `Number` (controlled) | `undefined` | 78 |
| `showArrow` | `Boolean` | `false` | 79 |
| `dotType` | `'dot' \| 'line'` | `'dot'` | 80-83 |
| `dotPlacement` | `'top' \| 'bottom' \| 'left' \| 'right'` | `'bottom'` | 84-88 |
| `slidesPerView` | `number \| 'auto'` | `1` | 89-92 |
| `spaceBetween` | `Number` | `0` | 93-96 |
| `centeredSlides` | `Boolean` | `false` | 97 |
| `direction` | `'horizontal' \| 'vertical'` | `'horizontal'` | 98-102 |
| `autoplay` | `Boolean` | `false` | 103 |
| `interval` | `Number` | `5000` | 104-107 |
| `loop` | `Boolean` | `true` | 108-111 |
| `effect` | `'slide' \| 'fade' \| 'card' \| 'custom'` | `'slide'` | 112-116 |
| `showDots` | `Boolean` | `true` | 117-120 |
| `trigger` | `'click' \| 'hover'` | `'click'` | 121-125 |
| `transitionStyle` | `TransitionStyle` (`{transitionDuration?, transitionTimingFunction?}`) | `{ transitionDuration: '300ms' }` | 126-132 |
| `transitionProps` | `TransitionProps` (Vue `<Transition>`) | `undefined` | 133 |
| `draggable` | `Boolean` | `false` | 134 |
| `prevSlideStyle` | `CSSProperties \| string` | `undefined` | 135-136 |
| `nextSlideStyle` | `CSSProperties \| string` | `undefined` | 137-138 |
| `touchable` | `Boolean` | `true` | 139-142 |
| `mousewheel` | `Boolean` | `false` | 143 |
| `keyboard` | `Boolean` | `false` | 144 |
| `onUpdate:currentIndex` | `(currentIndex, lastIndex) => void` | — | 145-147 |
| `onUpdateCurrentIndex` | `(currentIndex, lastIndex) => void` | — | 148-150 |

Both update callbacks are fired together in `toRealIndex` (`Carousel.tsx:343-356`), each with
`(displayIndex, lastDisplayIndex)` — i.e. the payload is in the **display** index space, not
the prop's `currentIndex` space. Guarded: only fires when `displayIndex !== mergedDisplayIndex`
(349).

`transitionProperties` constant (the keep-filter list) is defined at `Carousel.tsx:66-69`
as `['transitionDuration','transitionTimingFunction']`.

### 2.2 Controlled / uncontrolled pair

`currentIndex` (prop) vs `defaultIndex` (prop). Merged via `useMergedState(toRef(props,'currentIndex'),
uncontrolledDisplayIndexRef)` (`Carousel.tsx:334-337`). Seed chain:
`defaultRealIndex = getRealIndex(defaultIndex, duplicatedable)` (323-326) →
`uncontrolledDisplayIndexRef = ref(getDisplayIndex(defaultRealIndex, totalView, duplicatedable))`
(327-333) → `mergedDisplayIndexRef` (334) → `realIndexRef = getDisplayIndex` inverse =
`getRealIndex(mergedDisplayIndexRef, duplicatedable)` (338-340). All in the **display** space
on the outside, **real** (duplicate-inclusive) space on the inside.

### 2.3 Slots (`CarouselSlots`, `Carousel.tsx:151-155`)

| Slot | Shape (`interface.ts`) | Cite |
| --- | --- | --- |
| `default` | `() => VNode[]` | 152 |
| `arrow` | `(props: CarouselArrowSlotProps) => VNode[]` = `{ total, currentIndex, to, prev, next }` | 153 (`interface.ts:27-33`) |
| `dots` | `(props: CarouselDotSlotProps) => VNode[]` = `{ total, currentIndex, to }` | 154 (`interface.ts:35-39`) |

Actual slot prop objects are built at `Carousel.tsx:873-887`: `arrowSlotProps` =
`keep(carouselContext, ['to','prev','next','isPrevDisabled','isNextDisabled'])` +
`{ total: displayTotalView, currentIndex: displayIndex }` (873-882); `dotSlotProps` =
`{ total: displayTotalView, currentIndex: displayIndex, to }` (884-888). Note the documented
prop interface and the runtime object agree on keys (`total`/`currentIndex`), but the
`ArrowSlotProps` type `CarouselArrowSlotProps` (`interface.ts:27-33`) is structurally identical
to `ArrowScopedSlotProps` (`interface.ts:8-17`).

### 2.4 Exposed instance — `CarouselInst` (`interface.ts:3-8`)

`caroulseExposedMethod` (`Carousel.tsx:889-894`): `getCurrentIndex: () => mergedDisplayIndexRef.value`
(**display** index), `to`, `prev`, `next`. `to/prev/next` are the setup-scope fns, spread into
the render context (`...caroulseExposedMethod`, 941).

### 2.5 `NCarouselItem` scoped-slot props

`CarouselItem.tsx:88-93` renders `slots.default?.({ isPrev, isNext, isActive, index })` where
`index` is the item's real (duplicate-inclusive) index (`indexRef`, `CarouselItem.tsx:27-30`).

---

## 3. DOM tree byte-map

### 3.1 Root `div` (`Carousel.tsx:1000-1017`)

Class array order **exactly** (`1002-1011`):
1. `themeClass` — only present when `inlineThemeDisabled` (`useThemeClass('carousel', undefined, cssVarsRef, props)`, `927-929`); else `undefined`.
2. `{cls}-carousel`
3. `{cls}-carousel--vertical` — iff `direction === 'vertical'`
4. `{cls}-carousel--show-arrow` — iff `showArrow`
5. `{cls}-carousel--{dotPlacement}` — **always**
6. `{cls}-carousel--{direction}` — **always**
7. `{cls}-carousel--{effect}` — **always**
8. `{cls}-carousel--usercontrol` — iff `effect === 'custom'` (`userWantsControl`)

Note #5 precedes #6/#7; #2..#8 are all unconditional-with-gate strings in the array literal,
so the ordinal order above is the rendered order (Vue drops falsy entries).

Attributes/handlers (`1012-1016`):
- `ref="selfElRef"`
- `style={cssVars}` (the 8 `--n-*` vars, §6; `undefined` when `inlineThemeDisabled`).
- spread `slidesControlListeners` (`Carousel.tsx:866-871`): `onTouchstartPassive` (only if `touchable`),
  `onMousedown` (only if `draggable`), `onWheel` (only if `mousewheel`) — each is
  `handleTouchstart` / `handleMousewheel` or `undefined` (Vue skips `undefined`).
- `onMouseenter={handleMouseenter}` / `onMouseleave={handleMouseleave}` (always).

### 3.2 `VResizeObserver` wrapper(s) + `__slides` div (`Carousel.tsx:1019-1046`)

`<VResizeObserver onResize={handleResize}>` wraps the slides div (`1019`). vueuc's
`VResizeObserver` is **renderless** (no own DOM node; consistent with the port's convention,
cf. `tasks/recon/tabs-1-upstream.md:123/158`). Its slot content is the single element:

```
div{class}-carousel__slides            (1024-1030)
  ref="slidesElRef"
  class={ `${cls}-carousel__slides` }  (single string, not array)
  role="listbox"                       (1026)
  style={ translateStyle }             (1027)
  onTransitionend={ handleTransitionEnd } (1028)
```

`translateStyle` (`Carousel.tsx:439`): initial value `{}` (empty object). After any
`updateTranslate(translate, speed)` (`440-446`) it becomes
`Object.assign({}, transitionStyleRef.value, { transform, transitionDuration: `${speed}ms` })`:
- key order = `transitionDuration` (+ `transitionTimingFunction` if present in the filtered
  `transitionStyle`) then `transform`, then `transitionDuration` **overwritten again** by the
  speed value. Filtered via `keep(transitionStyle, ['transitionDuration','transitionTimingFunction'])`
  (`248-253`); the default `transitionStyle` = `{transitionDuration:'300ms'}` → merges to
  `{ transitionDuration:'0ms', transform:'translateX(0px)' }` on a 0-speed call.
- `transform` = `translateY(-Npx)` when vertical else `translateX(-Npx)` (`442-445`).

`handleTransitionEnd` (`715-726`) additionally mutates `translateStyleRef.value.transitionDuration = '0ms'`
after a sequence-layout transition.

Children of `__slides`:
- **plain branch** (not `userWantsControl`, `1044`): the slide vnodes directly (`1044`, `:slides`).
- **`usercontrol` branch** (`effect === 'custom'`, `1035-1043`): each slide wrapped in a plain
  `div` (no class) with `style={slideStyles[i]}` and `key={i}`, whose only child is
  `<Transition {...transitionProps}>` wrapping the slide, with the directive
  `[[vShow, this.isActive(i)]]` applied to the Transition. The wrapper `div` is the node the
  cssr `--usercontrol` rule targets (`.n-carousel--usercontrol .n-carousel__slides > div`,
  §5/`index.cssr.ts:141-154`).

### 3.3 `NCarouselItem` (`CarouselItem.tsx:60-100`) — `__slide` div

```
div{class}-carousel__slide              (73)
  ref="selfElRef"
  class=[ `${cls}-carousel__slide`,
          { [`${cls}-carousel__slide--current`]: isActive,
            [`${cls}-carousel__slide--prev`]:    isPrev,
            [`${cls}-carousel__slide--next`]:    isNext } ]   (67-76)
  role="option"                         (83)
  tabindex="-1"                         (84)
  data-index={ index }                  (85)   ← real index (duplicate-inclusive; see below)
  aria-hidden={ !isActive }             (86)   ← Vue renders "true"/"false"
  style={ getSlideStyle(index) }         (87)
  onClickCapture={ handleClick }         (91)
```

Class order: base string first, then the object modifiers in key order `current`, `prev`, `next`
(Vue appends present modifiers in insertion order). A slide is normally `--current` XOR
`--prev` XOR `--next`, but `card` can render `--current`/`--prev`/`--next`; the modifiers are
independent booleans (isPrev/isNext/isActive from the context).

`data-index` = `indexRef` = `NCarousel.getSlideIndex(selfEl)` (`CarouselItem.tsx:27-30`) =
`slideElsRef.value.indexOf(selfEl)` (`Carousel.tsx:534-540`) → the index **into the slideEls
array**, which under `duplicatedable` contains the prepended+appended clones. So it is the
**real** index space (`0..n+1` for `n` logical slides), not the display space `0..n-1`.
`aria-hidden` is a Vue-rendered string attribute (`"true"` when not active) — confirmed by
the spec's `.attributes('aria-hidden')` assertions (§7).

`getSlideStyle` (`Carousel.tsx:541-556`): `normalizeStyle([slideStylesRef[index], isPrev &&
prevSlideStyle || '', isNext && nextSlideStyle || ''])`. So composition order = base slide
style, then `prevSlideStyle` (if isPrev), then `nextSlideStyle` (if isNext); later wins on
conflict. Returns `undefined` when `index === -1`.

### 3.4 `NCarouselDots` (`CarouselDots.tsx:96-137`)

```
div{class}-carousel__dots                       (99)
  class=[ `${cls}-carousel__dots`, `${cls}-carousel__dots--${dotType}` ]  (100-103)
  role="tablist"                                (104)
  ├─ per dot (indexMap(this.total, i => …))   (105)
  │   div{class}-carousel__dot                   (110)
  │     aria-selected={ i === currentIndex }     (109)  ← "true"/"false"
  │     ref={ el => dotEls.push(el) }            (108)
  │     role="button"                            (111)
  │     tabindex="0"  (string literal)           (112)
  │     class=[ `${cls}-carousel__dot`, selected && `${cls}-carousel__dot--active` ] (113-116)
  │     key={ i }
  │     onClick={ () => handleClick(i) }         (118-120)
  │     onMouseenter={ () => handleMouseenter(i) }  (121-123)
  │     onKeydown={ e => handleKeydown(e, i) }   (124-126)
```

`selected = i === this.currentIndex` (`106`) uses the **display** `currentIndex`. `dotType`
default `'dot'` (also accepts `'line'`; prop type even allows `'never'`, `CarouselDots.tsx:6-19`).

Trigger behaviour (`27-39`):
- `handleClick`: `to(current)` iff `trigger === 'click'` (36-40).
- `handleMouseenter`: `to(current)` iff `trigger === 'hover'` (31-35).

Keyboard (`CarouselDots.tsx:41-94`):
- `handleKeydown(e, current)` (`41-53`): `Enter`/`' '` → `preventDefault()` + `to(current)`;
  then if `props.keyboard` → `handleKeyboard(e)`.
- `handleKeyboard` (`54-84`): bail if `shiftKey||altKey||ctrlKey||metaKey` (55-57); bail if
  `document.activeElement` `nodeName === 'input'|'textarea'` (58-62). Key matrix by `e.code`:
  - vertical: next = `PageUp|ArrowUp`, prev = `PageDown|ArrowDown` (63-64, 75-76)
  - horizontal: next = `PageUp|ArrowRight`, prev = `PageDown|ArrowLeft` (65-66, 77-78)
  - direction chosen by `NCarousel.isVertical()` (67, 72-73); if neither → return (68-70).
  - `preventDefault()` (71); if wantNext && !isNextDisabled → `next()` + `focusDot(currentIndexRef.value)`
    (80-82); else if wantPrev && !isPrevDisabled → `prev()` + `focusDot(currentIndexRef.value)` (83-85).
- `focusDot(index)` = `dotElsRef.value[index]?.focus()` (87-89); `dotElsRef` is cleared
  `onBeforeUpdate` (91).

### 3.5 `NCarouselArrow` (`CarouselArrow.tsx:44-76`)

```
div{class}-carousel__arrow-group                (50)
  ├─ div{class}-carousel__arrow                 (55)
  │    class=[ `${cls}-carousel__arrow`, isPrevDisabled() && `${cls}-carousel__arrow--disabled` ] (55-61)
  │    role="button"  onClick={ prev }           (62-64)
  │    └─ renderBackwardIcon() → <svg>           (65)
  └─ div{class}-carousel__arrow                 (66)
       class=[ …, isNextDisabled() && `${cls}-carousel__arrow--disabled` ] (67-72)
       role="button"  onClick={ next }           (73-74)
       └─ renderForwardIcon() → <svg>            (75)
```

`--disabled` is applied only when `isPrevDisabled()`/`isNextDisabled()` (no click guard in the
handler itself — `prev`/`next` internally no-op via `getRealPrevIndex===null`).

**SVG bytes (verbatim).** Both icons: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">`
→ `<g fill="none">` → `<path fill="currentColor" d="…">`.

- backward (`CarouselArrow.tsx:6-18`), d-string:
  `M10.26 3.2a.75.75 0 0 1 .04 1.06L6.773 8l3.527 3.74a.75.75 0 1 1-1.1 1.02l-4-4.25a.75.75 0 0 1 0-1.02l4-4.25a.75.75 0 0 1 1.06-.04z`
- forward (`CarouselArrow.tsx:21-33`), d-string:
  `M5.74 3.2a.75.75 0 0 0-.04 1.06L9.227 8L5.7 11.74a.75.75 0 1 0 1.1 1.02l4-4.25a.75.75 0 0 0 0-1.02l-4-4.25a.75.75 0 0 0-1.06-.04z`

(`g` has `fill="none"`, `path` has `fill="currentColor"`; the path is the only child of the `g`.)

### 3.6 Sibling order in the root (`Carousel.tsx:1017-1063`)

`__slides` (inside the outer VResizeObserver) → dots → arrow. Dots gate:
`showDots && dotSlotProps.total > 1` then slot-or-default (`1048-1060`); default child is
`<NCarouselDots key={dotType + dotPlacement} total currentIndex dotType trigger keyboard />`
(the concatenated key forces remount when `dotType` **or** `dotPlacement` changes — note
`dotPlacement` is not a prop of NCarouselDots, only a remount key). Arrow gate: `showArrow`
then slot-or-default `<NCarouselArrow />` (`1061-1063`).

### 3.7 Slide-set construction (`Carousel.tsx:972-997`)

`children = flatten(defaultSlot())` (972); `slides = filterCarouselItem(children)` (973, keeps
only vnodes whose `type.name === 'CarouselItem'`, `1067-1076`). If none filtered, **every**
child is wrapped in an `NCarouselItem` (`974-981`, `cloneVNode(ch)` in the default slot). If
`duplicatedable` → `addDuplicateSlides(slides)` (`982-984`, §4). `slideVNodesRef.value = slides`
(985). If `autoSlideSize` → each slide wrapped in a `<VResizeObserver onResize={handleSlideResize}>`
(`986-996`); again renderless. `onRender?.()` (`997`, inline-theme SSR hook).

---

## 4. State machine & pure algebra (cross-check)

### 4.1 Computed chain (`Carousel.tsx:171-201`)

| Computed | Definition | Line |
| --- | --- | --- |
| `vertical` | `direction === 'vertical'` | 171 |
| `sizeAxis` | `vertical ? 'height' : 'width'` | 172 |
| `spaceAxis` | `vertical ? 'bottom' : 'right'` | 173-175 |
| `sequenceLayout` | `effect === 'slide'` | 176 |
| `duplicatedable` | `loop && slidesPerView === 1 && sequenceLayout` | 177-182 |
| `userWantsControl` | `effect === 'custom'` | 183 |
| `displaySlidesPerView` | `(!sequenceLayout || centeredSlides) ? 1 : slidesPerView` | 186-189 |
| `realSlidesPerView` | `userWantsControl ? 1 : slidesPerView` | 190-193 |
| `autoSlideSize` | `displaySlidesPerView === 'auto' \|\| (slidesPerView === 'auto' && centeredSlides)` | 194-199 |

### 4.2 Sizes & translates

`perViewSizeRef = ref({width:0,height:0})` (201); `slideSizesTrigger = ref(0)` (202).
`slideSizesRef` (`203-227`): reads `slideSizesTrigger.value` (touch to re-eval). If
`autoSlideSize` → `slidesEls.map(el => calculateSize(el))` (208-210; **DOM-measured**, no
`innerOnly`). Else `axisSize = perViewSize[axis]`; if `slidesPerView !== 'auto'`:
`remaining = axisSize - (slidesPerView-1)*spaceBetween`, `percentage = 1 / max(1, slidesPerView)`,
`axisSize = remaining * percentage` (211-218); returns `slidesEls.map(() => ({...perViewSize, [axis]: axisSize}))`.

`slideTranlatesRef` (`228-246`, note the upstream typo "Tranlates"): accumulates
`previousTranslate += slideSize + spaceBetween`; when `centeredSlides`, `translate += (slideSize - perViewSize[axis]) / 2`
(237-240). Empty when no slide sizes.

### 4.3 Styles

`isMountedRef` set via `requestAnimationFrame` in `onMounted` (247, 776-779).
`transitionStyleRef = transitionStyle ? keep(transitionStyle, transitionProperties) : {}` (248-253).
`speedRef = userWantsControl ? 0 : resolveSpeed(transitionDuration)` (254-257).
`slideStylesRef` (`259-294`): `useComputedSize = !(autoSlideSize || realSlidesPerView === 1)`
(264-266). Per-slide `getSlideSize(i)` returns `{ [axis]: `${slideSizes[i][axis]}px` }` only
when `useComputedSize` (267-274). `userWantsControl` → only `getSlideSize(i)` per slide (275-280).
Else per-slide style = `{ ...getSlideSize(i), [`margin-${spaceAxis}`]: `${spaceBetween}px` }`
and, when `isMounted && (effect==='fade'||effect==='card')`, merges `transitionStyleRef.value`
(282-292).

### 4.4 Total views

`totalViewRef` (`295-317`): `slidesPerView = displaySlidesPerView`, `totalSlides = slideElsRef.value.length`
(**duplicate-inclusive**). If not `'auto'`: `max(totalSlides - slidesPerView, 0) + 1` (299-300).
Else the auto while-loop (301-316): `lastViewSize = last slide size`; `i = length`; while
`i>1 && lastViewSize < perViewSize` → `i--`, `lastViewSize += translates[i] - translates[i-1]`;
return `clampValue(i+1, 1, length)`.
`displayTotalViewRef = getDisplayTotalView(totalViewRef, duplicatedable)` (318-320) — with
duplicates, `total-2` when `total>3`.

### 4.5 Display ↔ real mapping & clamp/emit (`utils/duplicatedLogic.ts`)

- `getRealIndex(current, duplicatedable) = duplicatedable ? current+1 : current` (44-50).
- `getDisplayIndex(current, length, duplicatedable)`: `length===1 → 0`; else if not duplicated →
  `current`; else `current===0 → length-3`, `current===length-1 → 0`, else `current-1` (29-42).
- `getPrevIndex(current, length, dup)`: `current<0 → null`; `current===0 ? (dup?length-1:null) : current-1` (52-60).
- `getNextIndex(current, length, dup)`: `current>length-1 → null`; `current===length-1 ? (dup?0:null) : current+1` (62-70).
- `getDisplayTotalView(total, dup) = dup && total>3 ? total-2 : total` (72-78).
- `addDuplicateSlides(slides)` (10-22): if `length>1`, **push** a clone of `slides[0]` keyed
  `carousel-item-duplicate-0-append`, then **unshift** a clone of `slides[length-1]` keyed
  `carousel-item-duplicate-${length-1}-prepend` → strip = `[clone(last), s0, s1, …, s_{n-1}, clone(first)]`
  (real index 0 = last clone, real 1..n = logical, real n+1 = first clone).

`toRealIndex(index)` (`Carousel.tsx:343-356`): `index = clampValue(index, 0, totalView-1)`;
`displayIndex = getDisplayIndex(index, totalView, duplicatedable)`; if `displayIndex !== mergedDisplayIndex`
→ set `uncontrolledDisplayIndexRef` and fire both `onUpdate:currentIndex` + `onUpdateCurrentIndex`
with `(displayIndex, lastDisplayIndex)`.

`to(index)` (`396-409`): `realIndex = clampValue(getRealIndex(index, duplicatedable), 0, totalView)`
— **upper bound is `totalView`, not `totalView-1`** (harmless: `toRealIndex` re-clamps); fires
`toRealIndex(realIndex)` iff `index !== mergedDisplayIndex || realIndex !== realIndexRef`.
`prev()` (410-415) / `next()` (417-422) set `expectedTransitionDirection = -1 / 1` then
`toRealIndex(getRealPrevIndex()/getRealNextIndex())` when non-null.
`isRealPrev/isRealNext` (`367-377`) use `getSlideIndex` + `getRealPrevIndex()/getRealNextIndex()`
and require `totalView > 1`; `isRealActive` (379-383) compares to `realIndexRef`.
Display helpers: `isDisplayActive(index) = mergedDisplayIndex === index` (385-386);
`isPrevDisabled/isNextDisabled = getRealPrevIndex()/getRealNextIndex() === null` (388-393).

### 4.6 realIndex watcher — duplicated loop-jump normalization (`Carousel.tsx:803-837`)

```
watch(realIndexRef, (nextRealIndex, lastRealIndex) => {
  if (nextRealIndex === lastRealIndex) { expectedTransitionDirection = 0; return }   // 805-808
  resetAutoplay()                                                                   // 810
  if (sequenceLayout) {
    if (duplicatedable) {
      const { value: length } = totalViewRef        // = n+2 here
      if (expectedTransitionDirection === -1 && lastRealIndex === 1 && nextRealIndex === length - 2)
        nextRealIndex = 0
      else if (expectedTransitionDirection === 1 && lastRealIndex === length - 2 && nextRealIndex === 1)
        nextRealIndex = length - 1
    }
    translateTo(nextRealIndex, speedRef.value)      // 826
  } else fixTranslate()                             // 828
  expectedTransitionDirection = 0                   // 830
}, { immediate: true })                             // 836
```

So the two "loop-jump" cases are the real-index edges `1 ↔ length-2`. With duplicates
`length = totalView = n+2`, so `length-2` = the last logical real index `n`; `1` = the first
logical real index. When `prev` (dir −1) yields a `1 → n` transition the animation target is
redirected to real `0` (the prepended clone of the last slide), and when `next` (dir +1) yields
`n → 1` it is redirected to real `length-1` (the appended clone of the first slide), so the
strip animates one step onto the clone instead of snapping across the strip.
⚠ **Flag for oracle cross-check:** static reading of `getPrevIndex`/`getNextIndex` suggests the
edge transitions reached from `prev()/next()` are `1→0` and `n→n+1`, not `1→n` / `n→1`, so the
exact reachability of these two branches should be verified against runtime (this is the piece
most worth pinning behaviourally rather than by inspection).

### 4.7 Translate machinery (`Carousel.tsx:426-498`)

- `inTransition` flag (426); `previousTranslate` (438); `translateStyleRef` (439).
- `updateTranslate(translate, speed=0)` (440-446) — see §3.2 for the object shape.
- `fixTranslate(speed=0)` (448-457): if `sequenceLayout` → `translateTo(realIndexRef, speed)`;
  else if `previousTranslate !== 0` → set `inTransition = true` if `!inTransition && speed>0`,
  then `updateTranslate((previousTranslate = 0), speed)`.
- `translateTo(index, speed)` (459-465): `translate = getTranslate(index)`; set `inTransition`
  if `translate !== previousTranslate && speed>0`; `previousTranslate = getTranslate(realIndexRef)`;
  `updateTranslate(translate, speed)`.
- `getTranslate(index)` (467-476): `index >= totalView-1 ? getLastViewTranslate() : slideTranslates[index] || 0`.
- `getLastViewTranslate()` (478-498): if `displaySlidesPerView === 'auto'` → overall size =
  `lastTranslate + slideSizes[last][axis]` (or `perViewSize` if `lastTranslate` undefined),
  return `overallSize - perViewSize`; else `slideTranslates[totalView-1] || 0`.
- `prevIfSlideTransitionEnd/nextIfSlideTransitionEnd` (428-436): `(!inTransition || !duplicatedable) ? prev()/next() : noop`
  — these are what the **arrow/dots** context uses.

### 4.8 Drag flow (`Carousel.tsx:559-713`)

Module-level `globalDragging` singleton (156; "only one carousel is allowed to trigger touch
globally"). `handleTouchstart` (593-630): bail if `globalDragging`; bail if the event target is
not inside `slidesElRef` (`getPreciseEventTarget`); set `globalDragging/dragging = true`,
`isEffectiveDrag = false`, `dragStartTime = Date.now()`, `stopAutoplay()`; for non-touch events
`preventDefault()` unless `isContentEditable`; record `dragStartX/Y` by axis; if `touchable`
attach `touchmove/touchend/touchcancel`, if `draggable` attach `mousemove/mouseup` (all on
`document`, via evtd `on`).
`handleTouchmove` (631-646): `dragOffset = clampValue(offset, -perViewSize, perViewSize)`;
`preventDefault()` if cancelable; if `sequenceLayout` → `updateTranslate(previousTranslate - dragOffset, 0)`.
`handleTouchend` (647-698): snaps to nearest translate (nearest-search loop over
`[...slideTranslates.slice(0, totalView-1), getLastViewTranslate()]`, 651-661); if unchanged
index, apply velocity rules — `dragOffset > perViewSize/2 || dragOffset/timeElapsed > 0.4` → `prev()`,
`dragOffset < -perViewSize/2 || dragOffset/timeElapsed < -0.4` → `next()` (663-682); if index
changed → `isEffectiveDrag = true` + `toRealIndex(currentIndex)` + a `nextTick` `fixTranslate`
guard (683-696); else `fixTranslate(speedRef)`. Finally `resetDragStatus()` + `resetAutoplay()`.
`resetDragStatus` (699-713) clears `globalDragging`, drag vars, and all `document` listeners.
`onCarouselItemClick(index, event)` (565-576): `allowClick = !inTransition && !dragging && !isEffectiveDrag`;
in `card` effect with `allowClick && !isRealActive(index)` → `to(index)`, `allowClick = false`;
if `!allowClick` → `preventDefault()` + `stopPropagation()`.

### 4.9 Autoplay / wheel / resize / lifecycle

`autoplayTimer` (578). `stopAutoplay` (579-584). `resetAutoplay` (585-591): disabled if
`!autoplay || displayTotalView < 2`; else `setInterval(next, interval)`.
`handleMousewheel` (728-756): `preventDefault()`; return if `inTransition`; `shiftKey && !deltaX`
→ `deltaX = deltaY`; `m = (deltaX||deltaY) > 0 ? 1 : -1`; `responseStep = 10`; if
`ry*deltaY >= 10 || rx*deltaX >= 10` call `next()` (m=1, if !isNextDisabled) or `prev()` (m=-1,
if !isPrevDisabled).
`handleResize` (757-760): `perViewSizeRef = calculateSize(selfElRef, true)` (**innerOnly**, DOM-measured)
+ `resetAutoplay()`. `handleSlideResize` (761-765): if `autoSlideSize` → `slideSizesTrigger++`.
`handleMouseenter` (766-770): if `autoplay` → `stopAutoplay()`. `handleMouseleave` (771-775):
if `autoplay` → `resetAutoplay()`.
`onMounted` (776-779): `watchEffect(resetAutoplay)` + `requestAnimationFrame(() => isMountedRef = true)`.
`onBeforeUnmount` (780-783): `resetDragStatus()` + `stopAutoplay()`.
`onUpdated` (785-801): re-sorts `slideElsRef` by matching each element to its index in
`slideVNodesRef` (fix index after remount).
Other watches: `[duplicatedable, displaySlidesPerView] → nextTick(() => toRealIndex(realIndexRef))`
(838-843); `slideTranlatesRef` deep → `fixTranslate()` when `sequenceLayout` (845-854);
`sequenceLayout` → on false reset `inTransition` + `updateTranslate(previousTranslate = 0)`, on
true `fixTranslate()` (856-864).

### 4.10 DOM-measured quantities (cannot be pure Elm without a caller seam)

- `perViewSizeRef` ← `calculateSize(selfEl, true)` (757).
- `slideSizesRef` auto mode ← `calculateSize(el)` per slide (208-210).
- Resize triggers: outer VResizeObserver (`handleResize`), per-slide VResizeObserver when
  `autoSlideSize` (`handleSlideResize`).
- `document.activeElement` (dots keyboard, `CarouselDots.tsx:58`), `element.isContentEditable`
  (drag, `Carousel.tsx:610`), `getPreciseEventTarget`, `getComputedStyle`.

### 4.11 Orchestrator-summary deltas

- The summary says "`__slide` div classes (`--current`/`--prev`/`--next` gates)". Confirmed —
  they live in an **object** class binding (`CarouselItem.tsx:67-76`), so the rendered order is
  base → `--current` → `--prev` → `--next` (relevant if the port sorts class tokens).
- `data-index` is the **real** (duplicate-inclusive) index, not the display index — worth an
  explicit note because the specs query `[data-index="…"]` and expect them to line up with the
  display order only after accounting for the prepend shift.
- `to()` clamps its upper bound to `totalView` (not `totalView-1`) at `Carousel.tsx:400`.
- `displaySlidesPerView`/`realSlidesPerView`/`autoSlideSize` are three distinct values (186-199),
  not two.

---

## 5. cssr styles byte-map (`src/styles/index.cssr.ts`, 358 L)

Base: `cB('carousel', …)` (12). Consumed vars (header comment 3-10): `--n-bezier`,
`--n-dot-color`, `--n-dot-color-focus`, `--n-dot-color-active`, `--n-dot-size`,
`--n-dot-line-width`, `--n-dot-line-width-active`, `--n-arrow-color`.

Rules in order (selector built by cssr nesting; `{C}` = `.n-carousel`):

| Line | Selector | Properties / vars |
| --- | --- | --- |
| 12-18 | `{C}` | `position:relative; width:100%; height:100%; touch-action:pan-y; overflow:hidden` |
| 19-25 | `{C} .n-carousel__slides` | `display:flex; width:100%; height:100%; transition-timing-function:var(--n-bezier); transition-property:transform` |
| 26-33 | `…__slides …__slide` | `flex-shrink:0; position:relative; width:100%; height:100%; outline:none; overflow:hidden` |
| 34-37 | `…__slide > img` | `display:block` |
| 39-43 | `{C} .n-carousel__dots` | `position:absolute; display:flex; flex-wrap:nowrap` |
| 44-63 | `…__dots--dot` | wrapper |
| 45-55 | `…__dots--dot …__dot` | `height:var(--n-dot-size); width:var(--n-dot-size); background-color:var(--n-dot-color); border-radius:50%; cursor:pointer; transition: box-shadow .3s var(--n-bezier), background-color .3s var(--n-bezier); outline:none` |
| 56-58 | `…__dots--dot …__dot:focus` | `background-color:var(--n-dot-color-focus)` |
| 59-61 | `…__dots--dot …__dot--active` | `background-color:var(--n-dot-color-active)` |
| 64-86 | `…__dots--line` | wrapper |
| 65-75 | `…__dots--line …__dot` | `border-radius:9999px; width:var(--n-dot-line-width); height:4px; background-color:var(--n-dot-color); cursor:pointer; transition: width .3s var(--n-bezier), box-shadow .3s var(--n-bezier), background-color .3s var(--n-bezier); outline:none` |
| 77-79 | `…__dots--line …__dot:focus` | `background-color:var(--n-dot-color-focus)` |
| 80-84 | `…__dots--line …__dot--active` | `width:var(--n-dot-line-width-active); background-color:var(--n-dot-color-active)` |
| 87-101 | `{C} .n-carousel__arrow` | `transition: background-color .3s var(--n-bezier); cursor:pointer; height:28px; width:28px; display:flex; align-items:center; justify-content:center; background-color:rgba(255,255,255,.2); color:var(--n-arrow-color); border-radius:8px; user-select:none; -webkit-user-select:none; font-size:18px` |
| 102-104 | `…__arrow svg` | `height:1em; width:1em` |
| 106-108 | `…__arrow:hover` | `background-color:rgba(255,255,255,.3)` |
| 110-115 | `{C}--vertical` | `touch-action:pan-x` |
| 113-115 | `{C}--vertical …__slides` | `flex-direction:column` |
| 116-122 | `{C}--vertical{C}--fade …__slide` | `top:50%; left:unset; transform:translateY(-50%)` |
| 123-140 | `{C}--vertical{C}--card …__slide` | `top:50%; left:unset; transform:translateY(-50%) translateZ(-400px)` |
| 129-131 | `…--card …__slide--current` | `transform:translateY(-50%) translateZ(0)` |
| 132-134 | `…--card …__slide--prev` | `transform:translateY(-100%) translateZ(-200px)` |
| 135-137 | `…--card …__slide--next` | `transform:translateY(0%) translateZ(-200px)` |
| 141-154 | `{C}--usercontrol {C}__slides > div` | `position:absolute; top:50%; left:50%; width:100%; height:100%; transform:translate(-50%,-50%)` |
| 155-182 | `{C}--left …__dots` | `transform:translateY(-50%); top:50%; left:12px; flex-direction:column` |
| 162-178 | `{C}--left …__dots--line …__dot` | `width:4px; height:var(--n-dot-line-width); margin:4px 0; transition: height .3s …, box-shadow .3s …, background-color .3s …; outline:none` |
| 173-175 | `…--line …__dot--active` (in left) | `height:var(--n-dot-line-width-active)` |
| 179-181 | `{C}--left …__dot` | `margin:4px 0` |
| 183-186 | `{C} .n-carousel__arrow-group` | `position:absolute; display:flex; flex-wrap:nowrap` |
| 188-191 | `{C}--vertical …__arrow` | `transform:rotate(90deg)` |
| 193-221 | `{C}--show-arrow{C}--bottom/--top/--left/--right …__dots` | dots repositioning (see below) |
| 193-200 | `…--show-arrow…--bottom …__dots` | `transform:translateX(0); bottom:18px; left:18px` |
| 201-207 | `…--top …__dots` | `transform:translateX(0); top:18px; left:18px` |
| 208-214 | `…--left …__dots` | `transform:translateX(0); top:18px; left:18px` |
| 215-221 | `…--right …__dots` | `transform:translateX(0); top:18px; right:18px` |
| 223-233 | `{C}--left …__arrow-group` | `bottom:12px; left:12px; flex-direction:column` |
| 229-231 | `…--left …__arrow-group > *:first-child` | `margin-bottom:12px` |
| 234-270 | `{C}--right …__dots` | `transform:translateY(-50%); top:50%; right:12px; flex-direction:column` |
| 241-257 | `…--right …__dots--line …__dot` + `--active` | same line-dot rules as left |
| 258-260 | `{C}--right …__dot` | `margin:4px 0` |
| 261-269 | `{C}--right …__arrow-group` (`+ > *:first-child`) | `bottom:12px; right:12px; flex-direction:column` / `margin-bottom:12px` |
| 271-294 | `{C}--top …__dots` | `transform:translateX(-50%); top:12px; left:50%` |
| 277-281 | `…--top …__dots--line …__dot` | `margin:0 4px` |
| 283-285 | `{C}--top …__dot` | `margin:0 4px` |
| 286-293 | `{C}--top …__arrow-group` (`+ > *:first-child`) | `top:12px; right:12px` / `margin-right:12px` |
| 295-318 | `{C}--bottom …__dots` | `transform:translateX(-50%); bottom:12px; left:50%` |
| 301-305 | `…--bottom …__dots--line …__dot` | `margin:0 4px` |
| 307-309 | `{C}--bottom …__dot` | `margin:0 4px` |
| 310-317 | `{C}--bottom …__arrow-group` (`+ > *:first-child`) | `bottom:12px; right:12px` / `margin-right:12px` |
| 319-331 | `{C}--fade …__slide` | `position:absolute; opacity:0; transition-property:opacity; pointer-events:none` |
| 326-329 | `…--fade …__slide--current` | `opacity:1; pointer-events:auto` |
| 332-357 | `{C}--card …__slides` | `perspective:1000px` |
| 336-342 | `{C}--card …__slide` | `position:absolute; left:50%; opacity:0; transform:translateX(-50%) translateZ(-400px); transition-property:opacity, transform` |
| 343-347 | `…--card …__slide--current` | `opacity:1; transform:translateX(-50%) translateZ(0); z-index:1` |
| 348-351 | `…--card …__slide--prev` | `opacity:.4; transform:translateX(-100%) translateZ(-200px)` |
| 352-355 | `…--card …__slide--next` | `opacity:.4; transform:translateX(0%) translateZ(-200px)` |

Notes for extraction / class checking:
- **No `styleMount`/`cagr`/global mount rule** in this file — everything is component-scoped
  under `.n-carousel`. (Unlike components that emit top-level global rules.)
- Rules emitted **only as descendants of the modifier chain** (dots-in-placement, arrow-group,
  show-arrow dots) — the port's DOM must keep the `--{dotPlacement}` / `--{direction}` /
  `--show-arrow` / `--effect` / `--usercontrol` classes on the root for these to bite.
- `.n-carousel--vertical` appears **twice** (110 and 188); cssr merges/last-wins as usual, both
  are needed (base vertical + arrow rotation).
- `.n-carousel--left` also appears twice (155 and 223).
- Rule-less emitted classes (candidates for the port's `check-classes` ALLOW if written as
  literals): none extra on the root — every root token except `themeClass` has a rule. Inside
  dots/arrow the tokens `--active`, `--disabled` have rules; `n-carousel__slides`/`__slides`
  has a rule (19). The Transition/vShow wrapper in `usercontrol` mode has **no class**.

---

## 6. Theme (`styles/light.ts`, `styles/dark.ts`)

`self()` (`light.ts:4-14`) — **7 keys** (exactly):

| Key | Light value | Line |
| --- | --- | --- |
| `dotSize` | `8px` | 6 |
| `dotColor` | `rgba(255, 255, 255, .3)` | 7 |
| `dotColorActive` | `rgba(255, 255, 255, 1)` | 8 |
| `dotColorFocus` | `rgba(255, 255, 255, .5)` | 9 |
| `dotLineWidth` | `16px` | 10 |
| `dotLineWidthActive` | `24px` | 11 |
| `arrowColor` | `#eee` | 12 |

`carouselDark` (`dark.ts:7-10`) = `{ name:'Carousel', common: commonDark, self }` — **imports
`self` from `./light`; there is NO dark self-override** (so light and dark share identical self
values; only `common` differs, and the only `common` var consumed is `cubicBezierEaseInOut`).
No Upload-style dark self-subtlety here.

`cssVarsRef` (`Carousel.tsx:903-925`) emits **8** vars: `--n-bezier` (= `common.cubicBezierEaseInOut`),
`--n-dot-color`, `--n-dot-color-focus`, `--n-dot-color-active`, `--n-dot-size`, `--n-dot-line-width`,
`--n-dot-line-width-active`, `--n-arrow-color`. Key order in the object literal:
`--n-bezier, --n-dot-color, --n-dot-color-focus, --n-dot-color-active, --n-dot-size,
--n-dot-line-width, --n-dot-line-width-active, --n-arrow-color`.

---

## 7. Tests inventory (`tests/Carousel.spec.tsx`, 437 L)

16 `it()` blocks (all in `describe('n-carousel')`, `afterEach → vi.useRealTimers()`):

1. `should work with import on demand` (10-13) — mount/unmount `NCarousel`.
2. `should work with \`autoplay\` and \`interval\` prop` (15-42) — after 25ms `[data-index="0"]` `aria-hidden==='true'`; after another 25ms both `0` and `1` are hidden. (Pins the autoplay advance via `[data-index]` + `aria-hidden`.)
3. `should work with \`dot-placement\` prop` (44-56) — root has `n-carousel--{placement}` for top/bottom/left/right.
4. `should work with \`interval\` prop` (58-80) — after 100ms the `__slides` `[data-index="2"]` has `aria-hidden==='false'` and dots `[1]` has `aria-selected==='true'`.
5. `should work with \`show-arrow\` prop` (82-91) — `__arrow-group` and `__arrow` exist.
6. `arrow button should work` (93-138) — `loop:false`; click `[__arrow][1]` → slide[1] `aria-hidden false`; click `[0]` → slide[0] false.
7. `should work with \`centered-slides\` prop` (140-181) — `slidesPerView:'auto'`, `loop:false`; each slide's rect is centered in the wrapper (geometry!).
8. `should work with \`trigger\` prop` (183-217) — click/hover dots switch slides (`aria-hidden`).
9. `should work with \`current-index\` prop` (219-260) — controlled; `getCurrentIndex()` returns 1; exactly one active slide, `data-index==='1'`, has `--current`, correct `src`.
10. `should work with \`dot-type\` prop` (262-291) — dots class `--dot` then `--line`.
11. `should work with \`effect\` prop` (293-311) — root class `--slide/--fade/--card/--custom`.
12. `should work with \`keyboard\` prop` (313-352) — click dot 0, keydown `ArrowRight` → dot[1] selected; `ArrowLeft` → dot[0].
13. `should work with \`space-between\` prop` (354-387) — first `__slide` style lacks then contains `margin-right: 25px;`.
14. `should work with \`show-dots\` prop` (389-414) — `__dots` present then absent.
15. `should work with \`on-update:current-index\` prop` (416-436) — `onUpdateCurrentIndex` called after a dot click.

`tests/server.spec.tsx` (20 L): SSR smoke (`renderToString(<NCarousel/>)` inside try/catch).

Port-relevant notes: the suite leans on `data-index` (real-index space), `aria-hidden`
(string `"true"/"false"`), `aria-selected`, `--current/--prev/--next`, `--active`, root
modifier classes, and one geometry assertion (`centered-slides`). No vi-timer-specific autoplay
test beyond the `interval` timing ones; no duplicated-index explicit assertions (the duplicate
behaviour is exercised indirectly through autoplay/loop defaults).

---

## 8. Demos inventory (18 enUS + 18 zhCN, identical filenames)

| Demo | One-line role |
| --- | --- |
| `basic.vue` | Default `n-carousel` with 4 `<img>` (`.carousel-img`). |
| `arrow.vue` | `show-arrow`. |
| `autoplay.vue` | `autoplay`. |
| `dots.vue` | `dot-type`/`dot-placement`/`show-dots` variations. |
| `vertical.vue` | `direction="vertical"` + `dot-placement="right"`, inline height. |
| `space-between.vue` | `:space-between="20" draggable`. |
| `slides-per-view.vue` | `:slides-per-view="3" :space-between="20" :loop="false" draggable`. |
| `slides-per-view-auto.vue` | `slides-per-view="auto"` + `:space-between="20" :loop="false" draggable`, per-item widths 60/20/40/10%. |
| `centered.vue` | `centered-slides` + `slides-per-view="auto"` + `:space-between="30"` + `:loop="false"`. |
| `effect.vue` | radio switching `slide/fade/card`; uses `n-carousel-item` with `centered-slides`+`slides-per-view='auto'` for card; `:key` remount; `draggable`. |
| `transition-name.vue` | `effect="custom"` + `:transition-props="{ name: 'creative' }"` (CSS enter/leave). |
| `hover.vue` | `trigger="hover"`. |
| `keyboard.vue` | `keyboard` + a focus/`ref` setup (press arrows on dots). |
| `mousewheel.vue` | `mousewheel` + vertical/right placement. |
| `simulate-drag.vue` | `draggable`. |
| `custom-arrow-and-dots.vue` | `#arrow`/`#dots` scoped-slot overrides; also `show-arrow autoplay`. |
| `custom-card.vue` | `effect="card"` + `prev-slide-style`/`next-slide-style` transforms, `:show-dots="false"`. |
| `custom-dots.vue` | `#dots="{ total, currentIndex }"` text `"{{ currentIndex+1 }} / {{ total }}"` + autoplay. |

`index.demo-entry.md` documents the full prop/slot/method tables (matches §2). The zhCN set is
the same 18 demo files (translated markdown) — no extra demos.

---

## 9. Port-fit assessment

**Pure Elm (tractable):**
- Index algebra: the whole `duplicatedLogic.ts` set (`addDuplicateSlides` order/keys,
  `getDisplayIndex`, `getRealIndex`, `getPrevIndex`, `getNextIndex`, `getDisplayTotalView`) —
  pure `Int -> Int -> Bool -> Int`.
- `toRealIndex` / `to` / `prev` / `next` (with clamp + emit guard) and the `expectedTransitionDirection`
  loop-jump normalization — pure given `totalView`/`duplicatedable`.
- Total-view math (`totalViewRef` non-auto branch, `displayTotalView`) and the auto while-loop
  **given** `slideSizes`/`translates`/`perViewSize` as inputs.
- `slideTranslates` accumulation (incl. centered offset), `slideStyles` composition
  (`useComputedSize` gate, `margin-{spaceAxis}`, fade/card `transitionStyle` merge), `speedRef`/
  `resolveSpeed`, `transitionStyle` `keep`-filter.
- Wheel direction matrix + `responseStep`; drag settle geometry (nearest-translate loop,
  50%/0.4px-per-ms rules) given container size; `onCarouselItemClick` gating.
- Root/slide/dots/arrow class + attribute construction, cssVars, SVG glyphs — all pure.

**DOM/runtime-bound (accepted divergences / caller seams):**
- **Measurement**: `calculateSize` (`perViewSize` innerOnly, per-slide auto sizes) and both
  `VResizeObserver`s — the port pattern (cf. Grid/Marquee/DataTable notes in `src/NUI/*.elm`)
  is caller-measured size in, or a documented omission. Carousel *needs* `perViewSize` for
  `slidesPerView != 1/auto` centering, so a caller-provided container size seam is likely
  required; `slidesPerView:1` slide mode can compute translate from percentages without it.
- **`globalDragging` singleton** (`Carousel.tsx:156`) — cannot be a module global in a pure
  view; document as accepted divergence (multi-instance drag coordination lost).
- **`transitionProps` / Vue `<Transition>` + `vShow`** (`effect:'custom'` branch) — Vue-specific
  enter/leave; port renders the `usercontrol` wrapper `div`s (cssr `--usercontrol` needs them)
  but the actual enter/leave animation is caller-owned. `transitionProps` prop likely dropped.
- **`transitionend`** (`onTransitionend=handleTransitionEnd`) + `inTransition` bookkeeping —
  DOM event; port can emit the attribute/hook but the state reset is caller-side.
- **Autoplay** `setInterval` + hover pause (`handleMouseenter/leave`, `watchEffect(resetAutoplay)`) —
  service/caller-owned clock (same pattern as the port's other timed components).
- **Native touch/mouse listeners on `document`** (`evtd on/off`, passive touchstart, `isContentEditable`
  guard) — caller-owned or omitted; `onTouchstartPassive` is a Vue-only prop name.
- **Focus**: `focusDot` + `document.activeElement` guards in the dots keyboard handler —
  DOM-only; likely reduced to the key matrix + `focus` seam or documented.
- **`getPreciseEventTarget` / `getComputedStyle`** — DOM-only.
- **`onUpdated` slide re-sort** (remount index fix) — Vue lifecycle specific; N/A to Elm.

**Likely accepted divergences to record:** `globalDragging` singleton; `transitionProps`
custom-transition; autoplay timer + hover-pause; drag `document` listeners + velocity timing;
`transitionend`-driven `inTransition`; `to()`'s `totalView` (not `-1`) clamp is a faithful
port detail, not a divergence; the duplicated loop-jump watcher (§4.6) should be re-derived at
runtime before pinning (its static reachability is ambiguous).

**Gate/check-classes specifics:** the cssr emits **no** global/mount rule, so every emitted
root token except `themeClass` has a rule; the `themeClass` token (`n-carousel` inline-theme
class, e.g. `n-carousel` + hashed) is the only ALLOW-relevant root token if the port emits it.
`n-carousel--{dotPlacement}`/`--{direction}`/`--{effect}`/`--show-arrow`/`--usercontrol` all
have rules (via descendant selectors), so they are **not** ALLOW entries.
