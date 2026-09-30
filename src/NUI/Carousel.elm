module NUI.Carousel exposing
    ( ArrowInfo
    , Direction(..)
    , DotKeyAction(..)
    , DotPlacement(..)
    , DotType(..)
    , DotsInfo
    , DragPoint
    , Effect(..)
    , Env
    , KeyInfo
    , Options
    , PerView(..)
    , Size
    , SlideInfo
    , State
    , Trigger(..)
    , WheelInfo
    , applyIndexChange
    , autoplayEnabled
    , clampValue
    , cssVarsFor
    , decodeDragPoint
    , defaults
    , dotKeyAction
    , dragEnd
    , dragMove
    , dragStart
    , duplicateWrap
    , envOf
    , fixTranslate
    , getDisplayIndex
    , getDisplayTotalView
    , getLastViewTranslate
    , getNextIndex
    , getPrevIndex
    , getRealIndex
    , getTranslate
    , indexChange
    , init
    , markMounted
    , next
    , nextIfSlideTransitionEnd
    , prev
    , prevIfSlideTransitionEnd
    , resize
    , resolveSpeed
    , setSlideSizes
    , slideInfo
    , to
    , toRealIndex
    , transitionEnd
    , translateTo
    , view
    , viewArrowGroup
    , viewDots
    , wheel
    )

{-| Naive UI's `Carousel`, rebuilt as a pure state machine + geometry engine.

    import NUI.Carousel as Carousel
    import NUI.Theme as Theme

    opts : Carousel.Options msg
    opts =
        { Carousel.defaults | slidesPerView = Carousel.PerView 3 }

    slides : List (Html.Html msg)
    slides =
        [ Html.div [] [ Html.text "one" ], Html.div [] [ Html.text "two" ] ]

    view :
        { state : Carousel.State, opts : Carousel.Options msg }
        -> Element.Element msg
    view model =
        Carousel.view Theme.default
            model.opts
            (Carousel.resize model.opts { width = 1000, height = 400 } (Carousel.init model.opts 2))
            slides

The DOM is Naive UI's own: the root `div.n-carousel` (the 8 `--n-*` vars),
the `div.n-carousel__slides` track (`transition-duration` + `transform`), the
`div.n-carousel__slide` options (`--current` / `--prev` / `--next`), the
`div.n-carousel__dots` tablist, and the `div.n-carousel__arrow-group` pair.
`css/naive-ui.css` ships Naive UI's exact CSS.

**Rendering strategy (settled).** The whole carousel is ONE raw `Html` tree
wrapped in a single `Element.html`. The cssr owns the track's `display:flex`
(and `flex-direction:column` under `--vertical`); an elm-ui Element would emit
competing inline layout styles, and there is no public `Element -> Html`.
Consequence: slides are `List (Html msg)` (upstream slides are arbitrary
vnode content; the `NCarouselItem` scoped-slot flags are exposed as the pure
`slideInfo` helper instead).

**Caller-owned runtime.** Upstream drives a `setInterval` clock, rAF mount
flag, `document`-level drag listeners, `ResizeObserver` measurement, focus and
capture-phase click suppression. This library is pure, so the port exposes the
render surface and the pure `State -> State` mirrors; the host app owns the
effects (the same service/caller pattern `NUI.Upload` uses for XHR):

  - **Autoplay**: caller `Time.every interval` -> `next` while
    `env.autoplayEnabled`; root hover pauses via `onRootMouseEnter` /
    `onRootMouseLeave`.
  - **Measurement**: `resize` feeds the measured INNER container size
    (upstream `calculateSize(innerOnly=true)`), `setSlideSizes` feeds the
    per-slide sizes in `'auto'` mode. Examples/tests feed fixed sizes so the
    static DOM is deterministic.
  - **Drag**: caller subscribes to document move/end, decodes points with
    `decodeDragPoint`, and calls `dragMove` / `dragEnd`. `wheel`,
    `dotKeyAction`, `indexChange`, `slideInfo` are the remaining pure ports.

**Accepted divergences (documented edges):**

1.  No Vue `<Transition>` machinery: `transitionProps` is dropped; `effect:
    custom` hides inactive slides with `display: none` (no enter/leave
    classes).
2.  Measurement, timer, focus management, capture-phase click suppression and
    the `globalDragging` singleton are caller-side.
3.  `transitionStyle` is narrowed to the two keys upstream `keep()`s
    (`transitionDuration` + optional `transitionTimingFunction`).
4.  `prevSlideStyle` / `nextSlideStyle` accept the **string** form only
    (upstream also allows a CSSProperties object; `normalizeStyle` joins it —
    strings cover the typed use).
5.  The `isMounted` rAF flag is caller-set state (`markMounted`); static output
    matches upstream SSR (fade/card slides carry no transition props until
    mounted).

**Oracle round (`tasks/recon/carousel-oracle.md`) — 4 S findings fixed here:**

  - `[oracle S1]` usercontrol renders `wrapper div > div.n-carousel__slide`
    (upstream maps the ITEM vnodes into plain wrappers,
    `Carousel.tsx:1035-1043`); `vShow`'s `display: none` lives on the inner
    item, and BOTH usercontrol styles are the early-return branch — size
    only, no margin.
  - `[oracle S2]` `dragEnd`'s flick branch reproduces Vue's ASYNC
    `realIndex` watcher (`flush: 'pre'`): the sync `fixTranslate` runs first,
    the queued watcher body lands after it — the final translate is the
    loop-jump clone target, `transitionend` snaps back to the real slide.
  - `[oracle S3]` the track carries NO style attribute for non-sequence
    effects (upstream `translateStyleRef` stays `{}`); the live drag translate
    is sequence-only (`Carousel.tsx:657`).
  - `[oracle S4]` `onSlideClick` fires on the card-effect gate
    (`allowClick && effect=='card' && !isRealActive`, `Carousel.tsx:565-577`);
    the listener is attached only when the gate passes (the closed gate emits
    nothing either way; the `preventDefault` suppression half is caller-side).

Non-divergences worth noting: controlled usage is supported exactly as
upstream (`opts.currentIndex` wins over `state.displayIndex` via
`useMergedState`; route the same events through `to`). `to`'s upper clamp is
`totalView` (not `-1`) upstream — faithful, harmless (re-clamped by
`toRealIndex`).

**Port-surface notes (vs `tasks/recon/carousel-2-elm.md` §3):**

  - `init` takes `Options` + the slide count so the `defaultIndex` seed follows
    the evident INTENT (pins §A6): `displayIndex =
    getDisplayIndex(getRealIndex(defaultIndex, duplicatedable), totalView,
    duplicatedable)` with the TRUE total view. Upstream seeds during setup
    with `slideElsRef` still empty (`totalView` 1 -> every `defaultIndex`
    lands on display 0); nothing re-seeds it post-mount. The port documents the
    upstream setup-order quirk and pins the intended semantics.
  - `State` carries the slide count (`slideCount`) so the navigation functions
    (`to` / `prev` / `next` / `transitionEnd` / `dragEnd` / …) stay
    self-contained; `envOf` still takes the count explicitly (its documented
    signature) and internal callers pass `state.slideCount`.
  - `applyIndexChange` (the `realIndex` watcher body) takes the watcher's
    `lastRealIndex` as an extra `Int`: Vue reactivity supplies it upstream and
    there is no pure equivalent otherwise.
  - `dragEnd` takes the elapsed drag time (`Float` ms) — upstream reads
    `Date.now()`, which is a runtime concern.
  - `getLastViewTranslate`'s "auto" gate is upstream's NARROW
    `displaySlidesPerView == auto` (`Carousel.tsx:480`) — NOT `Env.autoSlideSize`.
    Consequence: `centeredSlides + slidesPerView:auto` (displaySpv forced to 1)
    takes the numeric branch `translates[totalView - 1]`. Pins §A4 re-derived
    from bytes and CORRECTED (1500, not 900 — orchestrator re-check vs
    Carousel.tsx:186-189, 478-497; the feat lane had flagged the divergence).
  - Inline style strings: the root uses the house `NUI.Internal.renderVars`
    form (joined `k:v` with `;`, no spaces); the track/slide styles mirror
    upstream Vue's serialization (`key: value; key: value`) since they are the
    byte-fidelity contract's target. `[oracle D]` The inline-theme `themeClass`
    is never emitted (house-wide).

Upstream refs: `carousel/src/Carousel.tsx` (props :73-146, `.tsx` state
machinery :156-894, render :1000-1063), `CarouselItem.tsx`,
`CarouselDots.tsx:27-94`, `CarouselArrow.tsx:6-33`,
`utils/duplicatedLogic.ts`, `utils/index.ts:20-37`,
`styles/index.cssr.ts`.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Carousel as CarouselTheme
import Regex
import Svg



-- TYPES -------------------------------------------------------------------------


{-| Upstream `direction` prop.
-}
type Direction
    = Horizontal
    | Vertical


{-| Upstream `effect` prop.
-}
type Effect
    = SlideEffect
    | FadeEffect
    | CardEffect
    | CustomEffect


{-| Upstream `dotType` prop (the port drops the internal `'never'` variant).
-}
type DotType
    = Dot
    | Line


{-| Upstream `dotPlacement` prop.
-}
type DotPlacement
    = DotsTop
    | DotsBottom
    | DotsLeft
    | DotsRight


{-| Upstream `trigger` prop.
-}
type Trigger
    = ClickTrigger
    | HoverTrigger


{-| Upstream `slidesPerView`: a number or `'auto'`.
-}
type PerView
    = PerView Int
    | PerViewAuto


{-| A measured width/height pair (upstream `Size`).
-}
type alias Size =
    { width : Float, height : Float }


{-| A drag point: client coordinates plus a timestamp (ms epoch).
-}
type alias DragPoint =
    { x : Float, y : Float, time : Float }


{-| A wheel event summary.
-}
type alias WheelInfo =
    { deltaX : Float, deltaY : Float, shiftKey : Bool }


{-| A keyboard event summary (the `code` + modifier state).
-}
type alias KeyInfo =
    { code : String
    , shiftKey : Bool
    , altKey : Bool
    , ctrlKey : Bool
    , metaKey : Bool
    }


{-| The dots keydown matrix outcome (`CarouselDots.tsx:54-84`). `Enter` /
`Space` are handled by the view itself (`onDotTo`); everything else routes to
`onDotKeydown` for the caller to map through `dotKeyAction`.
-}
type DotKeyAction
    = ToNext
    | ToPrev
    | None


{-| The `NCarouselItem` scoped-slot flags for one slide (`index` is the REAL,
duplicate-inclusive index).
-}
type alias SlideInfo =
    { isPrev : Bool
    , isNext : Bool
    , isActive : Bool
    , index : Int
    }


{-| The `#arrow` scoped-slot payload (minimal: the caller wires the actual
navigation through its own messages).
-}
type alias ArrowInfo =
    { total : Int
    , currentIndex : Int
    , isPrevDisabled : Bool
    , isNextDisabled : Bool
    }


{-| The `#dots` scoped-slot payload (upstream `CarouselDotSlotProps`).
-}
type alias DotsInfo =
    { total : Int
    , currentIndex : Int
    }


{-| Upstream closure state. `displayIndex` is the uncontrolled DISPLAY-space
index; `translate` / `translateSpeed` mirror `translateStyleRef`;
`previousTranslate` mirrors the module-level restore point; `dragAnchor` is the
recorded drag start point.
-}
type alias State =
    { displayIndex : Int
    , slideCount : Int
    , perViewSize : Size
    , autoSlideSizes : List Size
    , previousTranslate : Float
    , translate : Float
    , translateSpeed : Float
    , inTransition : Bool
    , expectedDirection : Int
    , mounted : Bool
    , dragging : Bool
    , isEffectiveDrag : Bool
    , dragOffset : Float
    , dragAnchor : Maybe DragPoint
    }


{-| The computed rendering state (the pin surface). See `envOf`.
-}
type alias Env =
    { vertical : Bool
    , sequenceLayout : Bool
    , duplicatedable : Bool
    , userWantsControl : Bool
    , centeredSlides : Bool
    , spaceBetween : Float
    , displaySlidesPerView : PerView
    , realSlidesPerView : PerView
    , autoSlideSize : Bool
    , slides : Int
    , totalSlides : Int
    , slideSizes : List Size
    , translates : List Float
    , totalView : Int
    , displayTotalView : Int
    , displayIndex : Int
    , realIndex : Int
    , perViewSize : Size
    , speed : Float
    , autoplayEnabled : Bool
    }


{-| The component's props (`carouselProps`), with Elm message channels in
place of Vue listeners (listeners never serialize to DOM attributes).
`attributes` are applied to the raw root `div` (Html, not Element — see the
module notes).
-}
type alias Options msg =
    { defaultIndex : Int
    , currentIndex : Maybe Int
    , showArrow : Bool
    , dotType : DotType
    , dotPlacement : DotPlacement
    , slidesPerView : PerView
    , spaceBetween : Float
    , centeredSlides : Bool
    , direction : Direction
    , autoplay : Bool
    , interval : Float
    , loop : Bool
    , effect : Effect
    , showDots : Bool
    , trigger : Trigger
    , transitionDuration : String
    , transitionTimingFunction : Maybe String
    , draggable : Bool
    , touchable : Bool
    , mousewheel : Bool
    , keyboard : Bool
    , prevSlideStyle : Maybe String
    , nextSlideStyle : Maybe String
    , renderArrow : Maybe (ArrowInfo -> Element msg)
    , renderDots : Maybe (DotsInfo -> Element msg)
    , onDotTo : Maybe (Int -> msg)
    , onPrev : Maybe msg
    , onNext : Maybe msg
    , onSlideClick : Maybe (Int -> msg)
    , onTransitionEnd : Maybe msg
    , onRootMouseEnter : Maybe msg
    , onRootMouseLeave : Maybe msg
    , onTouchStart : Maybe (DragPoint -> msg)
    , onWheel : Maybe (WheelInfo -> msg)
    , onDotKeydown : Maybe (Int -> KeyInfo -> msg)
    , attributes : List (Html.Attribute msg)
    }


{-| Upstream `carouselProps` defaults, byte-for-byte.
-}
defaults : Options msg
defaults =
    { defaultIndex = 0
    , currentIndex = Nothing
    , showArrow = False
    , dotType = Dot
    , dotPlacement = DotsBottom
    , slidesPerView = PerView 1
    , spaceBetween = 0
    , centeredSlides = False
    , direction = Horizontal
    , autoplay = False
    , interval = 5000
    , loop = True
    , effect = SlideEffect
    , showDots = True
    , trigger = ClickTrigger
    , transitionDuration = "300ms"
    , transitionTimingFunction = Nothing
    , draggable = False
    , touchable = True
    , mousewheel = False
    , keyboard = False
    , prevSlideStyle = Nothing
    , nextSlideStyle = Nothing
    , renderArrow = Nothing
    , renderDots = Nothing
    , onDotTo = Nothing
    , onPrev = Nothing
    , onNext = Nothing
    , onSlideClick = Nothing
    , onTransitionEnd = Nothing
    , onRootMouseEnter = Nothing
    , onRootMouseLeave = Nothing
    , onTouchStart = Nothing
    , onWheel = Nothing
    , onDotKeydown = Nothing
    , attributes = []
    }


zeroSize : Size
zeroSize =
    { width = 0, height = 0 }



-- STATE SEED / CALLER-FED MEASUREMENT -------------------------------------------


{-| Seed the state for `slideCount` slides. The `defaultIndex` seed follows the
INTENDED semantics (pins §A6); see the module notes.
-}
init : Options msg -> Int -> State
init opts count =
    let
        st0 =
            { displayIndex = 0
            , slideCount = count
            , perViewSize = zeroSize
            , autoSlideSizes = []
            , previousTranslate = 0
            , translate = 0
            , translateSpeed = 0
            , inTransition = False
            , expectedDirection = 0
            , mounted = False
            , dragging = False
            , isEffectiveDrag = False
            , dragOffset = 0
            , dragAnchor = Nothing
            }

        env0 =
            envOf opts st0 count

        seeded =
            getDisplayIndex
                (getRealIndex opts.defaultIndex env0.duplicatedable)
                env0.totalView
                env0.duplicatedable
    in
    reseat opts { st0 | displayIndex = seeded }


{-| Feed the measured INNER container size (upstream
`calculateSize(selfEl, innerOnly=true)`) and re-seat the translate.
-}
resize : Options msg -> Size -> State -> State
resize opts size st =
    reseat opts { st | perViewSize = size }


{-| Feed the measured per-slide sizes (auto mode only; upstream
`handleSlideResize` -> `slideSizesTrigger`).
-}
setSlideSizes : Options msg -> List Size -> State -> State
setSlideSizes opts sizes st =
    reseat opts { st | autoSlideSizes = sizes }


{-| Upstream `requestAnimationFrame(() => isMountedRef.value = true)` — the
caller sets this once mounted (fade/card slide transition props gate on it).
-}
markMounted : State -> State
markMounted st =
    { st | mounted = True }


{-| Re-run the translate pipeline at the current speed (the static-render
equivalent of upstream's measure -> `fixTranslate` cycle; see the module
notes).
-}
reseat : Options msg -> State -> State
reseat opts st =
    let
        env0 =
            envOf opts st st.slideCount
    in
    if env0.sequenceLayout then
        translateTo opts st env0.realIndex env0.speed

    else
        fixTranslate opts st env0.speed



-- PURE UTILS (utils/index.ts, utils/duplicatedLogic.ts) --------------------------


{-| Upstream `clampValue(value, min, max)`.
-}
clampValue : Float -> Float -> Float -> Float
clampValue value min_ max_ =
    if value < min_ then
        min_

    else if value > max_ then
        max_

    else
        value


{-| Upstream `resolveSpeed` (`utils/index.ts:26-37`): `undefined` -> 0; the lazy
`/^((\d+)?\.?\d+?)(ms|s)?$/`; default unit ms, `s` x1000, no match -> 0.
-}
resolveSpeed : Maybe String -> Float
resolveSpeed value =
    case value of
        Nothing ->
            0

        Just raw ->
            case Regex.findAtMost 1 timeRegex raw of
                match :: _ ->
                    let
                        number =
                            submatch 0 match

                        unit =
                            case submatch 2 match of
                                "" ->
                                    "ms"

                                u ->
                                    u
                    in
                    parseNumber number
                        * (if unit == "s" then
                            1000

                           else
                            1
                          )

                [] ->
                    0


timeRegex : Regex.Regex
timeRegex =
    Regex.fromString "^((\\d+)?\\.?\\d+?)(ms|s)?$"
        |> Maybe.withDefault Regex.never


submatch : Int -> Regex.Match -> String
submatch i match =
    match.submatches
        |> List.drop i
        |> List.head
        |> Maybe.withDefault Nothing
        |> Maybe.withDefault ""


{-| Parse a numeric string, tolerating a leading `.` (JS `Number('.5') == 0.5`
but Elm's `String.toFloat ".5"` may reject it).
-}
parseNumber : String -> Float
parseNumber s =
    case String.toFloat s of
        Just n ->
            n

        Nothing ->
            case String.toFloat ("0" ++ s) of
                Just n ->
                    n

                Nothing ->
                    0


{-| Upstream `getDisplayIndex` (`duplicatedLogic.ts:32-45`).
-}
getDisplayIndex : Int -> Int -> Bool -> Int
getDisplayIndex current length duplicatedable =
    if length == 1 then
        0

    else if not duplicatedable then
        current

    else if current == 0 then
        length - 3

    else if current == length - 1 then
        0

    else
        current - 1


{-| Upstream `getRealIndex`.
-}
getRealIndex : Int -> Bool -> Int
getRealIndex current duplicatedable =
    if not duplicatedable then
        current

    else
        current + 1


{-| Upstream `getPrevIndex` (`Nothing` for the JS `null`).
-}
getPrevIndex : Int -> Int -> Bool -> Maybe Int
getPrevIndex current length duplicatedable =
    if current < 0 then
        Nothing

    else if current == 0 then
        if duplicatedable then
            Just (length - 1)

        else
            Nothing

    else
        Just (current - 1)


{-| Upstream `getNextIndex` (`Nothing` for the JS `null`).
-}
getNextIndex : Int -> Int -> Bool -> Maybe Int
getNextIndex current length duplicatedable =
    if current > length - 1 then
        Nothing

    else if current == length - 1 then
        if duplicatedable then
            Just 0

        else
            Nothing

    else
        Just (current + 1)


{-| Upstream `getDisplayTotalView`.
-}
getDisplayTotalView : Int -> Bool -> Int
getDisplayTotalView total duplicatedable =
    if duplicatedable && total > 3 then
        total - 2

    else
        total


{-| Upstream `addDuplicateSlides`' content wrap: prepend the last element and
append the first when there is more than one (`[a,b,c] -> [c,a,b,c,a]`).
-}
duplicateWrap : List a -> List a
duplicateWrap xs =
    if List.length xs > 1 then
        case ( List.head (List.reverse xs), List.head xs ) of
            ( Just last, Just first ) ->
                last :: xs ++ [ first ]

            _ ->
                xs

    else
        xs



-- ENV (the computed chain) ------------------------------------------------------


{-| The one-stop derived rendering state (`Carousel.tsx:171-341`).
-}
envOf : Options msg -> State -> Int -> Env
envOf opts st slideCount =
    let
        vertical =
            opts.direction == Vertical

        sequenceLayout =
            opts.effect == SlideEffect

        duplicatedable =
            opts.loop && opts.slidesPerView == PerView 1 && sequenceLayout

        userWantsControl =
            opts.effect == CustomEffect

        displaySpv =
            if not sequenceLayout || opts.centeredSlides then
                PerView 1

            else
                opts.slidesPerView

        realSpv =
            if userWantsControl then
                PerView 1

            else
                opts.slidesPerView

        autoSlideSize =
            displaySpv == PerViewAuto || (opts.slidesPerView == PerViewAuto && opts.centeredSlides)

        totalSlides =
            if duplicatedable then
                slideCount + 2

            else
                slideCount

        perViewAxis =
            axisValue vertical st.perViewSize

        axisSize =
            case realSpv of
                PerView n ->
                    let
                        remaining =
                            perViewAxis - toFloat (n - 1) * opts.spaceBetween
                    in
                    remaining * (1 / toFloat (max 1 n))

                PerViewAuto ->
                    perViewAxis

        slideSizes =
            if slideCount == 0 then
                []

            else if autoSlideSize then
                st.autoSlideSizes

            else
                List.repeat totalSlides (setAxis vertical axisSize st.perViewSize)

        translates =
            List.foldl
                (\size ( previous, acc ) ->
                    let
                        s =
                            axisValue vertical size
                    in
                    ( previous + s + opts.spaceBetween
                    , acc
                        ++ [ previous
                                + (if opts.centeredSlides then
                                    (s - perViewAxis) / 2

                                   else
                                    0
                                  )
                           ]
                    )
                )
                ( 0, [] )
                slideSizes
                |> Tuple.second

        totalView =
            case displaySpv of
                PerView n ->
                    max (totalSlides - n) 0 + 1

                PerViewAuto ->
                    if List.isEmpty slideSizes then
                        totalSlides

                    else
                        let
                            length =
                                List.length slideSizes

                            lastSize =
                                axisValue vertical (Maybe.withDefault zeroSize (atIndex (length - 1) slideSizes))

                            loop i lvs =
                                if i > 1 && lvs < perViewAxis then
                                    loop (i - 1) (lvs + (listAt (i - 1) translates - listAt (i - 2) translates))

                                else
                                    i
                        in
                        clampInt (loop length lastSize + 1) 1 length

        displayIndex =
            Maybe.withDefault st.displayIndex opts.currentIndex

        realIndex =
            getRealIndex displayIndex duplicatedable

        speed =
            if userWantsControl then
                0

            else
                resolveSpeed (Just opts.transitionDuration)
    in
    { vertical = vertical
    , sequenceLayout = sequenceLayout
    , duplicatedable = duplicatedable
    , userWantsControl = userWantsControl
    , centeredSlides = opts.centeredSlides
    , spaceBetween = opts.spaceBetween
    , displaySlidesPerView = displaySpv
    , realSlidesPerView = realSpv
    , autoSlideSize = autoSlideSize
    , slides = slideCount
    , totalSlides = totalSlides
    , slideSizes = slideSizes
    , translates = translates
    , totalView = totalView
    , displayTotalView = getDisplayTotalView totalView duplicatedable
    , displayIndex = displayIndex
    , realIndex = realIndex
    , perViewSize = st.perViewSize
    , speed = speed
    , autoplayEnabled = opts.autoplay && getDisplayTotalView totalView duplicatedable >= 2
    }


{-| Upstream `autoplayEnabledRef`: `autoplay && displayTotalView >= 2`.
-}
autoplayEnabled : Bool -> Int -> Bool
autoplayEnabled autoplay displayTotalView =
    autoplay && displayTotalView >= 2


axisValue : Bool -> Size -> Float
axisValue vertical size =
    if vertical then
        size.height

    else
        size.width


setAxis : Bool -> Float -> Size -> Size
setAxis vertical value size =
    if vertical then
        { size | height = value }

    else
        { size | width = value }


envAxis : Env -> Float
envAxis env =
    axisValue env.vertical env.perViewSize


envSizeAxisName : Env -> String
envSizeAxisName env =
    if env.vertical then
        "height"

    else
        "width"


envSpaceAxisName : Env -> String
envSpaceAxisName env =
    if env.vertical then
        "bottom"

    else
        "right"


atIndex : Int -> List a -> Maybe a
atIndex i list =
    List.head (List.drop i list)


listAt : Int -> List Float -> Float
listAt i list =
    Maybe.withDefault 0 (atIndex i list)


clampInt : Int -> Int -> Int -> Int
clampInt value min_ max_ =
    max min_ (min value max_)



-- INDEX / TRANSLATE PIPELINE ----------------------------------------------------


{-| Upstream `toRealIndex` (`Carousel.tsx:343-356`): clamp, map to the display
index, write the uncontrolled index, then run the `realIndex` watcher body
(`applyIndexChange`) — there is no direct translate call upstream; the watcher
does it.
-}
toRealIndex : Options msg -> State -> Int -> State
toRealIndex opts st index =
    let
        env0 =
            envOf opts st st.slideCount

        idx =
            clampInt index 0 (env0.totalView - 1)

        newDisplay =
            getDisplayIndex idx env0.totalView env0.duplicatedable

        merged =
            Maybe.withDefault st.displayIndex opts.currentIndex
    in
    if newDisplay == merged then
        st

    else
        let
            st1 =
                { st | displayIndex = newDisplay }

            newMerged =
                Maybe.withDefault st1.displayIndex opts.currentIndex

            oldReal =
                getRealIndex merged env0.duplicatedable

            newReal =
                getRealIndex newMerged env0.duplicatedable
        in
        if newReal == oldReal then
            st1

        else
            applyIndexChange opts st1 oldReal env0.speed


{-| Upstream `to(index)` (`Carousel.tsx:387-397`): `index` is a DISPLAY index;
`realIndex` is clamped to `totalView` (the faithful off-by-one — re-clamped by
`toRealIndex`).
-}
to : Options msg -> State -> Int -> State
to opts st index =
    let
        env0 =
            envOf opts st st.slideCount

        realIndex =
            clampInt (getRealIndex index env0.duplicatedable) 0 env0.totalView
    in
    if index /= env0.displayIndex || realIndex /= env0.realIndex then
        toRealIndex opts st realIndex

    else
        st


{-| Upstream `prev()` — the transition-GUARDED form (arrows/dots-keyboard).
-}
prev : Options msg -> State -> State
prev opts st =
    let
        env0 =
            envOf opts st st.slideCount
    in
    case getPrevIndex env0.realIndex env0.totalView opts.loop of
        Just p ->
            toRealIndex opts { st | expectedDirection = -1 } p

        Nothing ->
            st


{-| Upstream `next()`.
-}
next : Options msg -> State -> State
next opts st =
    let
        env0 =
            envOf opts st st.slideCount
    in
    case getNextIndex env0.realIndex env0.totalView opts.loop of
        Just n ->
            toRealIndex opts { st | expectedDirection = 1 } n

        Nothing ->
            st


{-| Upstream `prevIfSlideTransitionEnd`.
-}
prevIfSlideTransitionEnd : Options msg -> State -> State
prevIfSlideTransitionEnd opts st =
    if not st.inTransition || not (envOf opts st st.slideCount).duplicatedable then
        prev opts st

    else
        st


{-| Upstream `nextIfSlideTransitionEnd`.
-}
nextIfSlideTransitionEnd : Options msg -> State -> State
nextIfSlideTransitionEnd opts st =
    if not st.inTransition || not (envOf opts st st.slideCount).duplicatedable then
        next opts st

    else
        st


{-| Upstream `getTranslate` (`Carousel.tsx:461-469`).
-}
getTranslate : Env -> Int -> Float
getTranslate env index =
    if index >= env.totalView - 1 then
        getLastViewTranslate env

    else
        listAt index env.translates


{-| Upstream `getLastViewTranslate` (`Carousel.tsx:470-490`). The "auto" gate is
upstream's narrow `displaySlidesPerView == auto` (NOT `Env.autoSlideSize` — see module
notes + pins §A4 CORRECTED).
-}
getLastViewTranslate : Env -> Float
getLastViewTranslate env =
    if env.displaySlidesPerView == PerViewAuto then
        let
            perView =
                envAxis env
        in
        case List.head (List.reverse env.translates) of
            Nothing ->
                perView

            Just lastTranslate ->
                (lastTranslate + lastSlideAxis env) - perView

    else
        listAt (env.totalView - 1) env.translates


lastSlideAxis : Env -> Float
lastSlideAxis env =
    case List.head (List.reverse env.slideSizes) of
        Just size ->
            axisValue env.vertical size

        Nothing ->
            0


{-| Upstream `translateTo(index, speed)` (`Carousel.tsx:452-459`).
-}
translateTo : Options msg -> State -> Int -> Float -> State
translateTo opts st index speed =
    let
        env0 =
            envOf opts st st.slideCount

        translate =
            getTranslate env0 index

        st1 =
            if translate /= st.previousTranslate && speed > 0 then
                { st | inTransition = True }

            else
                st
    in
    { st1
        | previousTranslate = getTranslate env0 env0.realIndex
        , translate = translate
        , translateSpeed = speed
    }


{-| Upstream `fixTranslate(speed)` (`Carousel.tsx:447-451`).
-}
fixTranslate : Options msg -> State -> Float -> State
fixTranslate opts st speed =
    let
        env0 =
            envOf opts st st.slideCount
    in
    if env0.sequenceLayout then
        translateTo opts st env0.realIndex speed

    else if st.previousTranslate /= 0 then
        let
            st1 =
                if not st.inTransition && speed > 0 then
                    { st | inTransition = True }

                else
                    st
        in
        { st1 | previousTranslate = 0, translate = 0, translateSpeed = speed }

    else
        st


{-| The `realIndex` watcher body (`Carousel.tsx:803-837`): the two
`duplicatedable` loop-jump normalizations, then `translateTo` (sequence
layout) or `fixTranslate`. `lastRealIndex` is the watcher's `lastRealIndex`
(Vue supplies it upstream).
-}
applyIndexChange : Options msg -> State -> Int -> Float -> State
applyIndexChange opts st lastRealIndex speed =
    let
        env0 =
            envOf opts st st.slideCount
    in
    if env0.realIndex == lastRealIndex then
        { st | expectedDirection = 0 }

    else
        let
            nextIndex =
                if env0.sequenceLayout && env0.duplicatedable then
                    let
                        length =
                            env0.totalView
                    in
                    if st.expectedDirection == -1 && lastRealIndex == 1 && env0.realIndex == length - 2 then
                        0

                    else if st.expectedDirection == 1 && lastRealIndex == length - 2 && env0.realIndex == 1 then
                        length - 1

                    else
                        env0.realIndex

                else
                    env0.realIndex

            st1 =
                if env0.sequenceLayout then
                    translateTo opts st nextIndex speed

                else
                    fixTranslate opts st speed
        in
        { st1 | expectedDirection = 0 }


{-| Upstream `handleTransitionEnd` (`Carousel.tsx:715-727`).
-}
transitionEnd : Options msg -> State -> State
transitionEnd opts st =
    let
        env0 =
            envOf opts st st.slideCount

        st1 =
            if env0.sequenceLayout && st.inTransition then
                translateTo opts st env0.realIndex 0

            else
                st

        st2 =
            if env0.sequenceLayout then
                { st1 | translateSpeed = 0 }

            else
                st1
    in
    { st2 | inTransition = False }


{-| Upstream's `onUpdate:currentIndex` emit condition: (current, last) display
indices iff the display index changed.
-}
indexChange : State -> State -> Maybe ( Int, Int )
indexChange old new =
    if new.displayIndex /= old.displayIndex then
        Just ( new.displayIndex, old.displayIndex )

    else
        Nothing


{-| The `NCarouselItem` scoped-slot flags for a real slide index.
-}
slideInfo : Options msg -> State -> Int -> Maybe SlideInfo
slideInfo opts st index =
    let
        env0 =
            envOf opts st st.slideCount
    in
    if index < 0 || index > env0.totalSlides - 1 then
        Nothing

    else
        let
            ( isActive, isPrev, isNext ) =
                slideFlags env0 opts.loop index
        in
        Just { isPrev = isPrev, isNext = isNext, isActive = isActive, index = index }


slideFlags : Env -> Bool -> Int -> ( Bool, Bool, Bool )
slideFlags env loop index =
    ( env.realIndex == index
    , env.totalView > 1 && getPrevIndex env.realIndex env.totalView loop == Just index
    , env.totalView > 1 && getNextIndex env.realIndex env.totalView loop == Just index
    )



-- DRAG / WHEEL / KEYBOARD -------------------------------------------------------


{-| Upstream `handleTouchstart` (`Carousel.tsx:593-640`), reduced to the pure
state changes (`globalDragging`, `preventDefault`, document listeners are
caller-side).
-}
dragStart : Options msg -> State -> DragPoint -> State
dragStart _ st point =
    { st
        | dragging = True
        , isEffectiveDrag = False
        , dragAnchor = Just point
        , dragOffset = 0
    }


{-| Upstream `handleTouchmove` (`Carousel.tsx:641-660`): offset along the axis,
clamped to +/- the per-view size; live translate updates only in sequence
layout.
-}
dragMove : Options msg -> State -> { x : Float, y : Float } -> State
dragMove opts st point =
    let
        env0 =
            envOf opts st st.slideCount

        anchor =
            Maybe.withDefault { x = point.x, y = point.y, time = 0 } st.dragAnchor

        raw =
            if env0.vertical then
                point.y - anchor.y

            else
                point.x - anchor.x

        perView =
            envAxis env0

        offset =
            clampValue raw -perView perView

        st1 =
            { st | dragOffset = offset }
    in
    if env0.sequenceLayout then
        { st1 | translate = st.previousTranslate - offset, translateSpeed = 0 }

    else
        st1


{-| Upstream `handleTouchend` (`Carousel.tsx:661-713`) given the elapsed drag
time (upstream reads `Date.now()`).
-}
dragEnd : Options msg -> State -> Float -> State
dragEnd opts st elapsed =
    let
        env0 =
            envOf opts st st.slideCount

        real0 =
            env0.realIndex

        currentIndex =
            if not st.inTransition && st.dragOffset /= 0 && env0.sequenceLayout then
                let
                    currentTranslate =
                        st.previousTranslate - st.dragOffset

                    scanList =
                        List.take (env0.totalView - 1) env0.translates ++ [ getLastViewTranslate env0 ]
                in
                scanNearest currentTranslate scanList real0

            else
                real0

        ( stAfterMove, flickDir ) =
            if currentIndex == real0 then
                let
                    perView =
                        envAxis env0

                    ratio =
                        if elapsed == 0 then
                            if st.dragOffset > 0 then
                                1 / 0

                            else if st.dragOffset < 0 then
                                -1 / 0

                            else
                                0

                        else
                            st.dragOffset / elapsed
                in
                if st.dragOffset > perView / 2 || ratio > 0.4 then
                    ( prev opts st, Just -1 )

                else if st.dragOffset < -perView / 2 || ratio < -0.4 then
                    ( next opts st, Just 1 )

                else
                    ( st, Nothing )

            else
                ( st, Nothing )
    in
    if currentIndex /= real0 then
        let
            st1 =
                toRealIndex opts { stAfterMove | isEffectiveDrag = True } currentIndex

            unconditional =
                not env0.duplicatedable
                    || (Maybe.withDefault st1.displayIndex opts.currentIndex /= st1.displayIndex)

            st2 =
                if unconditional then
                    fixTranslate opts st1 env0.speed

                else
                    st1
        in
        resetDragStatus st2

    else
        resetDragStatus
            (case flickDir of
                Just dir ->
                    -- `[oracle S2]` Vue's `watch(realIndexRef, …, { flush: 'pre' })`
                    -- is ASYNC: in the flick branch `prev()`/`next()` only WRITE
                    -- the display index (queueing the watcher), the sync
                    -- `else` branch runs `fixTranslate(speed)` FIRST, and the
                    -- queued watcher body lands AFTER it — so the final
                    -- translate is the loop-jump clone target (0), with
                    -- `transitionend` snapping back to the real slide later
                    -- (`Carousel.tsx:661-713` + `:803-837`). The eager
                    -- `applyIndexChange` inside `prev`/`next` models the same
                    -- body, so we re-set `expectedDirection` and re-apply it
                    -- after `fixTranslate` to reproduce the flush order.
                    let
                        stFix =
                            fixTranslate opts stAfterMove env0.speed
                    in
                    applyIndexChange opts { stFix | expectedDirection = dir } real0 env0.speed

                Nothing ->
                    fixTranslate opts stAfterMove env0.speed
            )


scanNearest : Float -> List Float -> Int -> Int
scanNearest target translates initial =
    scanHelper target translates 0 Nothing initial


scanHelper : Float -> List Float -> Int -> Maybe Float -> Int -> Int
scanHelper target translates i prevOffset best =
    case translates of
        [] ->
            best

        t :: rest ->
            let
                offset =
                    abs (t - target)
            in
            case prevOffset of
                Just po ->
                    if po < offset then
                        best

                    else
                        scanHelper target rest (i + 1) (Just offset) i

                Nothing ->
                    scanHelper target rest (i + 1) (Just offset) i


resetDragStatus : State -> State
resetDragStatus st =
    { st | dragging = False, dragOffset = 0, dragAnchor = Nothing }


{-| Upstream `handleMousewheel` (`Carousel.tsx:728-755`).
-}
wheel : Options msg -> State -> WheelInfo -> State
wheel opts st info =
    let
        env0 =
            envOf opts st st.slideCount
    in
    if st.inTransition then
        st

    else
        let
            dx =
                if info.shiftKey && info.deltaX == 0 then
                    info.deltaY

                else
                    info.deltaX

            dy =
                info.deltaY

            d =
                if dx /= 0 then
                    dx

                else
                    dy

            m =
                if d > 0 then
                    1

                else
                    -1

            rx =
                if env0.vertical then
                    0

                else
                    m

            ry =
                if env0.vertical then
                    m

                else
                    0
        in
        if ry * dy >= 10 || rx * dx >= 10 then
            if m == 1 then
                next opts st

            else
                prev opts st

        else
            st


{-| Upstream `handleKeyboard` (`CarouselDots.tsx:54-84`) — the `code` matrix
after the `keyboard` + modifier guards. The `document.activeElement`
input/textarea guard is DOM-only (caller-side); `Enter`/`Space` are handled by
the view (`onDotTo`).
-}
dotKeyAction : Options msg -> Env -> KeyInfo -> Maybe DotKeyAction
dotKeyAction opts env info =
    if not opts.keyboard then
        Nothing

    else if info.shiftKey || info.altKey || info.ctrlKey || info.metaKey then
        Just None

    else
        let
            verticalNext =
                info.code == "PageUp" || info.code == "ArrowUp"

            verticalPrev =
                info.code == "PageDown" || info.code == "ArrowDown"

            horizontalNext =
                info.code == "PageUp" || info.code == "ArrowRight"

            horizontalPrev =
                info.code == "PageDown" || info.code == "ArrowLeft"

            wantNext =
                if env.vertical then
                    verticalNext

                else
                    horizontalNext

            wantPrev =
                if env.vertical then
                    verticalPrev

                else
                    horizontalPrev
        in
        if wantNext then
            Just ToNext

        else if wantPrev then
            Just ToPrev

        else
            Just None


{-| A drag point from `clientX` / `clientY` (+ optional `time`). Touch events
nest coordinates under `touches[0]`; callers decoding raw touch events supply
their own decoder (listeners never serialize to DOM, so this is inert in the
static output).
-}
decodeDragPoint : Decode.Decoder DragPoint
decodeDragPoint =
    Decode.map3 DragPoint
        (Decode.oneOf [ Decode.field "clientX" Decode.float, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.field "clientY" Decode.float, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.field "time" Decode.float, Decode.succeed 0 ])



-- VIEW --------------------------------------------------------------------------


{-| Render the carousel. Slides are the caller's raw `Html` (upstream arbitrary
vnode content).
-}
view : Theme -> Options msg -> State -> List (Html.Html msg) -> Element msg
view theme opts state slides =
    Element.html (rootNode theme opts state slides)


rootNode : Theme -> Options msg -> State -> List (Html.Html msg) -> Html.Html msg
rootNode theme opts state slides =
    let
        env0 =
            envOf opts state state.slideCount
    in
    Html.div
        (rootAttributes theme opts ++ rootListeners opts)
        (slidesNode opts state env0 slides
            :: (dotsNodes opts state env0 ++ arrowNodes opts state env0)
        )


rootAttributes : Theme -> Options msg -> List (Html.Attribute msg)
rootAttributes theme opts =
    [ HA.class (String.join " " (rootClasses opts))
    , HA.attribute "style" (I.renderVars (cssVarsFor theme))
    ]
        ++ opts.attributes


rootClasses : Options msg -> List String
rootClasses opts =
    [ "n-carousel" ]
        ++ I.classIf (opts.direction == Vertical) "n-carousel--vertical"
        ++ I.classIf opts.showArrow "n-carousel--show-arrow"
        ++ [ "n-carousel--" ++ dotPlacementSuffix opts.dotPlacement
           , "n-carousel--" ++ directionSuffix opts.direction
           , "n-carousel--" ++ effectSuffix opts.effect
           ]
        ++ I.classIf (opts.effect == CustomEffect) "n-carousel--usercontrol"


dotPlacementSuffix : DotPlacement -> String
dotPlacementSuffix placement =
    case placement of
        DotsTop ->
            "top"

        DotsBottom ->
            "bottom"

        DotsLeft ->
            "left"

        DotsRight ->
            "right"


directionSuffix : Direction -> String
directionSuffix direction =
    case direction of
        Horizontal ->
            "horizontal"

        Vertical ->
            "vertical"


effectSuffix : Effect -> String
effectSuffix effect =
    case effect of
        SlideEffect ->
            "slide"

        FadeEffect ->
            "fade"

        CardEffect ->
            "card"

        CustomEffect ->
            "custom"


dotTypeSuffix : DotType -> String
dotTypeSuffix dotType =
    case dotType of
        Dot ->
            "dot"

        Line ->
            "line"


rootListeners : Options msg -> List (Html.Attribute msg)
rootListeners opts =
    List.concat
        [ if opts.touchable then
            Maybe.withDefault [] (Maybe.map (\f -> [ HE.on "touchstart" (Decode.map f decodeDragPoint) ]) opts.onTouchStart)

          else
            []
        , if opts.draggable then
            Maybe.withDefault [] (Maybe.map (\f -> [ HE.on "mousedown" (Decode.map f decodeDragPoint) ]) opts.onTouchStart)

          else
            []
        , if opts.mousewheel then
            Maybe.withDefault [] (Maybe.map (\m -> [ HE.on "wheel" (Decode.map m decodeWheelInfo) ]) opts.onWheel)

          else
            []
        , Maybe.withDefault [] (Maybe.map (\m -> [ HE.onMouseEnter m ]) opts.onRootMouseEnter)
        , Maybe.withDefault [] (Maybe.map (\m -> [ HE.onMouseLeave m ]) opts.onRootMouseLeave)
        ]


slidesNode : Options msg -> State -> Env -> List (Html.Html msg) -> Html.Html msg
slidesNode opts state env0 slides =
    let
        rendered =
            if env0.duplicatedable then
                duplicateWrap slides

            else
                slides

        content =
            if env0.userWantsControl then
                List.indexedMap (userControlWrapper opts state env0) rendered

            else
                List.indexedMap (slideNode opts state env0) rendered

        -- [oracle S3] upstream `translateStyleRef` stays `{}` for non-sequence
        -- effects (fade/card/custom: `updateTranslate` only ever runs under
        -- `sequenceLayout`, and `fixTranslate`'s non-seq branch is gated on
        -- `previousTranslate !== 0`, which never becomes non-zero there) — no
        -- style attribute on the track at all.
        styleAttrs =
            if env0.sequenceLayout then
                [ HA.attribute "style" (trackStyle opts state env0) ]

            else
                []
    in
    Html.div
        ([ HA.class "n-carousel__slides"
         , HA.attribute "role" "listbox"
         ]
            ++ styleAttrs
            ++ transitionEndListener opts
        )
        content


transitionEndListener : Options msg -> List (Html.Attribute msg)
transitionEndListener opts =
    Maybe.withDefault []
        (Maybe.map (\m -> [ HE.on "transitionend" (Decode.succeed m) ]) opts.onTransitionEnd)


trackStyle : Options msg -> State -> Env -> String
trackStyle opts state env0 =
    -- sequence-only caller (the gate lives in `slidesNode`); the live drag
    -- translate also only exists under sequenceLayout upstream
    -- (`handleTouchmove` gates on it, `Carousel.tsx:657`).
    let
        translate =
            if state.dragging then
                state.previousTranslate - state.dragOffset

            else
                state.translate

        transform =
            if env0.vertical then
                "translateY(-" ++ num translate ++ "px)"

            else
                "translateX(-" ++ num translate ++ "px)"

        decls =
            ("transition-duration: " ++ num state.translateSpeed ++ "ms")
                :: (case opts.transitionTimingFunction of
                        Just tf ->
                            [ "transition-timing-function: " ++ tf ]

                        Nothing ->
                            []
                   )
                ++ [ "transform: " ++ transform ]
    in
    String.join "; " decls


slideNode : Options msg -> State -> Env -> Int -> Html.Html msg -> Html.Html msg
slideNode opts state env0 i content =
    slideNodeIn opts state env0 False i content


{-| `[oracle S1]` The usercontrol inner node: same `n-carousel__slide` element
upstream renders inside each plain wrapper (`Carousel.tsx:1035-1043` maps the
NCarouselItem vnodes, and `vShow` lands `display: none` on THAT item), with
the usercontrol `slideStyles` branch — size only, NO margin (`slideStylesRef`
returns early, `Carousel.tsx:275-280`).
-}
slideNodeUC : Options msg -> State -> Env -> Int -> Html.Html msg -> Html.Html msg
slideNodeUC opts state env0 i content =
    slideNodeIn opts state env0 True i content


slideNodeIn : Options msg -> State -> Env -> Bool -> Int -> Html.Html msg -> Html.Html msg
slideNodeIn opts state env0 userControl i content =
    let
        ( isActive, isPrev, isNext ) =
            slideFlags env0 opts.loop i

        classes =
            "n-carousel__slide"
                :: (I.classIf isActive "n-carousel__slide--current"
                        ++ I.classIf isPrev "n-carousel__slide--prev"
                        ++ I.classIf isNext "n-carousel__slide--next"
                   )

        styleStr =
            slideStyle opts state env0 userControl i isActive isPrev isNext
    in
    Html.div
        ([ HA.class (String.join " " classes)
         , HA.attribute "role" "option"
         , HA.attribute "tabindex" "-1"
         , HA.attribute "data-index" (String.fromInt i)
         , HA.attribute "aria-hidden"
            (if isActive then
                "false"

             else
                "true"
            )
         ]
            ++ (if String.isEmpty styleStr then
                    []

                else
                    [ HA.attribute "style" styleStr ]
               )
            ++ slideClickListener opts state env0 i isActive
        )
        [ content ]


{-| `[oracle S4]` Upstream `onCarouselItemClick` (`Carousel.tsx:565-577`): the
card-effect `to(index)` fires only when `allowClick && effect === 'card' &&
!isRealActive` (`allowClick = !inTransition && !dragging &&
!isEffectiveDrag`). The handler itself is attached to every item in every
effect (the internal gate decides); the `preventDefault`/`stopPropagation`
suppression half stays caller-side (documented divergence).
-}
slideClickListener : Options msg -> State -> Env -> Int -> Bool -> List (Html.Attribute msg)
slideClickListener opts state env0 i isActive =
    case opts.onSlideClick of
        Nothing ->
            []

        Just f ->
            let
                allowClick =
                    not state.inTransition && not state.dragging && not state.isEffectiveDrag

                fires =
                    opts.effect == CardEffect && allowClick && not isActive
            in
            -- when the gate is closed there is no msg to emit (the
            -- preventDefault/stopPropagation suppression half stays caller-side)
            if fires then
                [ HE.onClick (f i) ]

            else
                []


slideStyle : Options msg -> State -> Env -> Bool -> Int -> Bool -> Bool -> Bool -> String
slideStyle opts state env0 userControl i isActive isPrev isNext =
    let
        useComputedSize =
            not (env0.autoSlideSize || env0.realSlidesPerView == PerView 1)

        sizeDecls =
            if useComputedSize then
                [ envSizeAxisName env0
                    ++ ": "
                    ++ num (axisValue env0.vertical (Maybe.withDefault zeroSize (atIndex i env0.slideSizes)))
                    ++ "px"
                ]

            else
                []

        -- `[oracle S1]` the usercontrol `slideStylesRef` branch returns early:
        -- `getSlideSize(i)` only — no margin (`Carousel.tsx:275-292`).
        marginDecls =
            if userControl then
                []

            else
                [ "margin-" ++ envSpaceAxisName env0 ++ ": " ++ num opts.spaceBetween ++ "px" ]

        transitionDecls =
            if state.mounted && (opts.effect == FadeEffect || opts.effect == CardEffect) then
                ("transition-duration: " ++ opts.transitionDuration)
                    :: (case opts.transitionTimingFunction of
                            Just tf ->
                                [ "transition-timing-function: " ++ tf ]

                            Nothing ->
                                []
                       )

            else
                []

        extraDecls =
            (if isPrev then
                Maybe.withDefault [] (Maybe.map (\s -> [ s ]) opts.prevSlideStyle)

             else
                []
            )
                ++ (if isNext then
                        Maybe.withDefault [] (Maybe.map (\s -> [ s ]) opts.nextSlideStyle)

                    else
                        []
                   )

        -- `[oracle S1]` `vShow` on the usercontrol item: `display: none` when
        -- inactive, nothing when active (display:'' restores).
        displayDecls =
            if userControl && not isActive then
                [ "display: none" ]

            else
                []
    in
    String.join "; " (sizeDecls ++ marginDecls ++ transitionDecls ++ extraDecls ++ displayDecls)


{-| `[oracle S1]` The usercontrol wrapper (`Carousel.tsx:1035-1043`): a PLAIN
classless `div` whose style is the usercontrol `slideStyles[i]` — size only,
NO margin, no display — wrapping the real `n-carousel__slide` item (vShow's
`display: none` lives on that inner item, not here).
-}
userControlWrapper : Options msg -> State -> Env -> Int -> Html.Html msg -> Html.Html msg
userControlWrapper opts state env0 i content =
    let
        useComputedSize =
            not (env0.autoSlideSize || env0.realSlidesPerView == PerView 1)

        sizeDecls =
            if useComputedSize then
                [ envSizeAxisName env0
                    ++ ": "
                    ++ num (axisValue env0.vertical (Maybe.withDefault zeroSize (atIndex i env0.slideSizes)))
                    ++ "px"
                ]

            else
                []

        wrapperAttrs =
            if List.isEmpty sizeDecls then
                []

            else
                [ HA.attribute "style" (String.join "; " sizeDecls) ]
    in
    Html.div wrapperAttrs [ slideNodeUC opts state env0 i content ]


dotsNodes : Options msg -> State -> Env -> List (Html.Html msg)
dotsNodes opts state env0 =
    if opts.showDots && env0.displayTotalView > 1 then
        [ case opts.renderDots of
            Just render ->
                embedEl (render { total = env0.displayTotalView, currentIndex = env0.displayIndex })

            Nothing ->
                defaultDotsNode opts env0
        ]

    else
        []


defaultDotsNode : Options msg -> Env -> Html.Html msg
defaultDotsNode opts env0 =
    Html.div
        [ HA.class ("n-carousel__dots n-carousel__dots--" ++ dotTypeSuffix opts.dotType)
        , HA.attribute "role" "tablist"
        ]
        (List.range 0 (env0.displayTotalView - 1) |> List.map (dotNode opts env0))


dotNode : Options msg -> Env -> Int -> Html.Html msg
dotNode opts env0 i =
    let
        selected =
            i == env0.displayIndex

        classes =
            "n-carousel__dot"
                ++ (if selected then
                        " n-carousel__dot--active"

                    else
                        ""
                   )

        clickListeners =
            if opts.trigger == ClickTrigger then
                Maybe.withDefault [] (Maybe.map (\f -> [ HE.onClick (f i) ]) opts.onDotTo)

            else
                []

        hoverListeners =
            if opts.trigger == HoverTrigger then
                Maybe.withDefault [] (Maybe.map (\f -> [ HE.onMouseEnter (f i) ]) opts.onDotTo)

            else
                []

        keyListeners =
            if opts.onDotKeydown /= Nothing || opts.onDotTo /= Nothing then
                [ HE.on "keydown" (dotKeydownDecoder opts i) ]

            else
                []
    in
    Html.div
        ([ HA.attribute "aria-selected"
            (if selected then
                "true"

             else
                "false"
            )
         , HA.attribute "role" "button"
         , HA.attribute "tabindex" "0"
         , HA.class classes
         ]
            ++ clickListeners
            ++ hoverListeners
            ++ keyListeners
        )
        []


arrowNodes : Options msg -> State -> Env -> List (Html.Html msg)
arrowNodes opts state env0 =
    if opts.showArrow then
        [ case opts.renderArrow of
            Just render ->
                embedEl
                    (render
                        { total = env0.displayTotalView
                        , currentIndex = env0.displayIndex
                        , isPrevDisabled = isPrevDisabled opts env0
                        , isNextDisabled = isNextDisabled opts env0
                        }
                    )

            Nothing ->
                defaultArrowGroup opts env0
        ]

    else
        []


defaultArrowGroup : Options msg -> Env -> Html.Html msg
defaultArrowGroup opts env0 =
    Html.div [ HA.class "n-carousel__arrow-group" ]
        [ arrowButton (isPrevDisabled opts env0) backwardPath opts.onPrev
        , arrowButton (isNextDisabled opts env0) forwardPath opts.onNext
        ]


isPrevDisabled : Options msg -> Env -> Bool
isPrevDisabled opts env0 =
    getPrevIndex env0.realIndex env0.totalView opts.loop == Nothing


isNextDisabled : Options msg -> Env -> Bool
isNextDisabled opts env0 =
    getNextIndex env0.realIndex env0.totalView opts.loop == Nothing


arrowButton : Bool -> String -> Maybe msg -> Html.Html msg
arrowButton disabled path onPress =
    Html.div
        ([ HA.class
            ("n-carousel__arrow"
                ++ (if disabled then
                        " n-carousel__arrow--disabled"

                    else
                        ""
                   )
            )
         , HA.attribute "role" "button"
         ]
            ++ Maybe.withDefault [] (Maybe.map (\m -> [ HE.onClick m ]) onPress)
        )
        [ arrowSvg path ]


arrowSvg : String -> Svg.Svg msg
arrowSvg path =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 16 16"
        ]
        [ Svg.node "g"
            [ HA.attribute "fill" "none" ]
            [ Svg.node "path"
                [ HA.attribute "d" path
                , HA.attribute "fill" "currentColor"
                ]
                []
            ]
        ]


{-| The default dots builder (`#dots` slot fallback), as raw `Html`.
-}
viewDots : Options msg -> State -> Html.Html msg
viewDots opts state =
    defaultDotsNode opts (envOf opts state state.slideCount)


{-| The default arrow-group builder (`#arrow` slot fallback), as raw `Html`.
-}
viewArrowGroup : Options msg -> State -> Html.Html msg
viewArrowGroup opts state =
    defaultArrowGroup opts (envOf opts state state.slideCount)


embedEl : Element msg -> Html.Html msg
embedEl el =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        el


dotKeydownDecoder : Options msg -> Int -> Decode.Decoder msg
dotKeydownDecoder opts i =
    keyInfoDecoder
        |> Decode.andThen
            (\info ->
                if info.code == "Enter" || info.code == "Space" then
                    case opts.onDotTo of
                        Just f ->
                            Decode.succeed (f i)

                        Nothing ->
                            Decode.fail "carousel dot: Enter/Space with no onDotTo"

                else
                    case opts.onDotKeydown of
                        Just f ->
                            Decode.succeed (f i info)

                        Nothing ->
                            Decode.fail "carousel dot: no onDotKeydown"
            )


keyInfoDecoder : Decode.Decoder KeyInfo
keyInfoDecoder =
    Decode.map5 KeyInfo
        (Decode.oneOf [ Decode.field "code" Decode.string, Decode.succeed "" ])
        (boolField "shiftKey")
        (boolField "altKey")
        (boolField "ctrlKey")
        (boolField "metaKey")


boolField : String -> Decode.Decoder Bool
boolField key =
    Decode.oneOf [ Decode.field key Decode.bool, Decode.succeed False ]


decodeWheelInfo : Decode.Decoder WheelInfo
decodeWheelInfo =
    Decode.map3 WheelInfo
        (Decode.oneOf [ Decode.field "deltaX" Decode.float, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.field "deltaY" Decode.float, Decode.succeed 0 ])
        (boolField "shiftKey")



-- SVG GLYPHS (byte-verbatim from CarouselArrow.tsx) -----------------------------


backwardPath : String
backwardPath =
    "M10.26 3.2a.75.75 0 0 1 .04 1.06L6.773 8l3.527 3.74a.75.75 0 1 1-1.1 1.02l-4-4.25a.75.75 0 0 1 0-1.02l4-4.25a.75.75 0 0 1 1.06-.04z"


forwardPath : String
forwardPath =
    "M5.74 3.2a.75.75 0 0 0-.04 1.06L9.227 8L5.7 11.74a.75.75 0 1 0 1.1 1.02l4-4.25a.75.75 0 0 0 0-1.02l-4-4.25a.75.75 0 0 0-1.06-.04z"



-- CSS VARS ----------------------------------------------------------------------


{-| The raw `--n-*` custom properties the root attaches, in upstream
`cssVarsRef` order (8 vars).
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            CarouselTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-dot-color", v.dotColor )
    , ( "--n-dot-color-focus", v.dotColorFocus )
    , ( "--n-dot-color-active", v.dotColorActive )
    , ( "--n-dot-size", v.dotSize )
    , ( "--n-dot-line-width", v.dotLineWidth )
    , ( "--n-dot-line-width-active", v.dotLineWidthActive )
    , ( "--n-arrow-color", v.arrowColor )
    ]



-- NUMBERS -----------------------------------------------------------------------


{-| JS `${n}`: floats via `String.fromFloat`, `-0` -> `"0"`.
-}
num : Float -> String
num x =
    if x == 0 then
        "0"

    else
        String.fromFloat x
