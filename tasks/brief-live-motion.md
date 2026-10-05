# BRIEF — Live.Motion (Carousel, Log, Countdown, NumberAnimation, Progress, Spin, Skeleton, Marquee)

Read `tasks/brief-live-common.md` FIRST. FILE: `examples/src/Live/Motion.elm`
(replace the stub). THIS family USES subscriptions (`Time.every`) — Main already maps
`Live.Motion.subscriptions` into the app.

Read first (Carousel's header is long and the contract is precise):
`src/NUI/Carousel.elm` (State/init/resize + the full pure algebra: to/prev/next/
guarded ×2/transitionEnd/dragStart/dragMove/dragEnd/wheel/dotKeyAction/indexChange/
autoplayEnabled + Options channels onPrev/onNext/onDotTo/onTransitionEnd/onWheel/
onSlideClick/onTouchStart/onRootMouseEnter/onRootMouseLeave/onDotKeydown),
`src/NUI/Log.elm` (mergedLines/styleHeight/scrollEvents/wheelEvents + loading state),
`src/NUI/Countdown.elm`, `src/NUI/NumberAnimation.elm`, `src/NUI/Progress.elm`,
`src/NUI/Spin.elm`, `src/NUI/Skeleton.elm`, `src/NUI/Marquee.elm`.
Also skim the static carouselSection/logSection in examples/src/Main.elm — it shows
the exact `Carousel.init opts 4` + `Carousel.resize opts size state` wiring and the
fake gradient slide images (copy the slide helper).

DEMOS:
1. **Carousel · autoplay + arrows + dots + wheel** — THE centerpiece. Fixed measured
   size (no real measurement needed). Model holds `Carousel.State` + autoplay on/off.
   - subscriptions: when autoplay is on (and not paused), `Time.every interval Tick`
     where update runs the port's autoplay step (read the header for how autoplay
     advances — use the port's own indexChange/next algebra, NOT a hand-rolled jump).
   - onPrev/onNext/onDotTo wired to the port's prev/next/to; onTransitionEnd to the
     port's transitionEnd (the loop-jump snap); onWheel to the port's wheel; hover
     pause via onRootMouseEnter/onRootMouseLeave toggling autoplay.
   - caption shows current index (displayIndex/toRealIndex per the port).
2. **Carousel · drag** — pointer drag via Browser.Events document subscriptions:
     mousedown on the track (the port's onTouchStart/onSlideClick or an mousedown
     attr — read what the port exposes) starts drag (dragStart), mousemove feeds
     dragMove, mouseup ends (dragEnd). Subscribe ONLY while dragging. If the port's
     drag API is pointer-event-shaped in a way that needs coordinates, decode them
     (Decode.field "clientX"). If genuinely intractable, SKIP drag and report why —
     the rest must land.
3. **Log · scroll + load** — a fixed-rows Log over a model list; scroll channels
   (scrollEvents: RequireMore/ReachBottom etc.) append/prepend simulated lines; the
   wheel path too if exposed; a "loading" flash: set loading True on RequireMore,
   clear it on the appended batch (no timer needed — append immediately, or use one
   Time.every tick if a delay is essential).
4. **Countdown · live clock** — Time.every 1000ms; show the port's rendered countdown
   against a model target (read the header for its value/format API).
5. **NumberAnimation · animate** — a value target changed by a button; Time.every
   ~33ms steps the port's animation state toward it (use the port's own from/to
   transition helpers — read the header; if it exposes only the value formatting,
   do linear interpolation in the model and use the port for display, noting it).
6. **Progress · drive** — buttons ±10% update the value; the port renders. If
   Progress supports an indeterminate/processing state, a toggle for it.
7. **Spin · toggle** — checkbox switches Spin (spinning container with content).
8. **Skeleton · toggle** — toggle between Skeleton and the loaded content.
9. **Marquee · play** — toggle playing (delay/loop per the port's API).
