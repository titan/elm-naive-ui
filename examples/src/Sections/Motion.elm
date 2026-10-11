module Sections.Motion exposing
    ( Model
    , Msg
    , countdownSection
    , init
    , logSection
    , marqueeSection
    , numberAnimationSection
    , progressSection
    , sections
    , skeletonSection
    , spinSection
    , subscriptions
    , update
    )

{-| Motion family sections: Progress, Skeleton, Spin, Marquee, Countdown,
Number Animation, Carousel, Log.

The static rows moved verbatim from Main.elm — that surface feeds the
check-dom gate, so every root keeps rendering exactly as before. The live
demo rows (moved verbatim from Live/Motion.elm — same demoRow labels, same
`#live-*` ids, same captions) run a real update loop owned by this module.

Phase 2 — the static rows that HAVE channels are state-driven with identical
init (the brief's technique): every static Carousel row keeps its exact
literals (size, effect, dots, arrows, `defaultIndex`, its `live-carousel-*`
id) but renders from a per-row `Carousel.State` initialised to the same
`resize opts size (init opts 4)` it used to build inline, with `onDotTo` /
`onPrev` / `onNext` / `onSlideClick` (card) / `onDotKeydown` + `keyboard`
wired to one Msg each — dots, arrows, Enter/Space and arrow-key navigation
now move the slides. The remaining Motion components expose no msg channels
at all (Progress/Skeleton/Spin/Marquee/Countdown/NumberAnimation/Log are
caller-clock display components — their Options records carry no `on*`
fields), so those rows stay specimens; the Log live row covers Log.

Every runtime concern the port documents as caller-owned lands here:

  - **Carousel**: the autoplay `Time.every` clock (hover-paused via the root
    mouse channels), arrows / dots / wheel / dot-keyboard routed through the
    port's own `prev` / `next` / `to` / `wheel` / `dotKeyAction` algebra, and
    the loop-jump snap via `transitionEnd`. The drag demo subscribes to
    document-level `mousemove` / `mouseup` ONLY while a drag is active and
    feeds the port's `dragStart` / `dragMove` / `dragEnd` (elapsed ms from a
    20 ms tick clock — the port takes the elapsed time explicitly).
  - [oracle D] **Autoplay clock is free-running** — upstream's
    stopAutoplay/resetAutoplay restarts the FULL interval on un-hover;
    `Time.every` may fire sooner after un-pausing. Hover-pause itself is
    faithful.
  - **Log**: the scroll position is model-owned geometry (fixed 17.5 px lines)
    fed to the port's pure `scrollEvents` / `wheelEvents` — the wheel listener
    is real (wheel bubbles to the root; scroll events do not), the buttons
    step the same simulated position, and `RequireMoreFrom` flashes the
    loader until a 600 ms tick appends / prepends the batch.
  - **Countdown / NumberAnimation**: `Time.every` clocks subtracted as Posix
    deltas; the tween goes through the port's `tweenValue` (retargeting
    restarts from the currently displayed value).
  - **Progress / Spin / Skeleton / Marquee**: plain model toggles.

No ports, no JS — model state plus `Time.every` / `Browser.Events`, exactly
the caller-owned pattern every header docstring describes.

-}

import Browser.Events
import Element exposing (Element)
import Element.Background as Bg
import Element.Border as Border
import Html
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import NUI.Button as Button
import NUI.Card as Card
import NUI.Carousel as Carousel
import NUI.Checkbox as Checkbox
import NUI.Countdown as Countdown
import NUI.Log as Log
import NUI.Marquee as Marquee
import NUI.NumberAnimation as NumberAnimation
import NUI.Progress as Progress
import NUI.Skeleton as Skeleton
import NUI.Spin as Spin
import NUI.Switch as Switch
import NUI.Tag as Tag
import NUI.Theme exposing (Theme)
import NUI.Types as T
import Showcase exposing (chip, codeHljs, demoRow, section)
import Time



-- MODEL


type alias Model =
    { autoplay : Bool
    , carouselPaused : Bool
    , carousel : Carousel.State
    , announce : Maybe String
    , dragging : Bool
    , drag : Carousel.State
    , dragElapsed : Float
    , dragLastTick : Maybe Int
    , logLines : List String
    , logSeq : Int
    , logRec : Int
    , logScrollTop : Float
    , logPending : Maybe Log.Panel
    , countdown : Int
    , clockLast : Maybe Int
    , naFrom : Float
    , naTo : Float
    , naElapsed : Float
    , naLast : Maybe Int
    , progress : Float
    , processing : Bool
    , spinShow : Bool
    , loaded : Bool
    , marqueePlay : Bool
    , specCarousels : SpecCarStates
    }


init : Model
init =
    { autoplay = True
    , carousel =
        Carousel.resize (carouselOpts True)
            carSize
            (Carousel.markMounted (Carousel.init (carouselOpts True) 4))
    , carouselPaused = False
    , announce = Nothing
    , dragging = False
    , drag =
        Carousel.resize dragOpts
            dragSize
            (Carousel.markMounted (Carousel.init dragOpts 4))
    , dragElapsed = 0
    , dragLastTick = Nothing
    , logLines = List.map logLine (List.range 1 12)
    , logSeq = 13
    , logRec = 1
    , logScrollTop = 0
    , logPending = Nothing
    , countdown = 90000
    , clockLast = Nothing
    , naFrom = 0
    , naTo = 0
    , naElapsed = naDuration
    , naLast = Nothing
    , progress = 50
    , processing = False
    , spinShow = True
    , loaded = False
    , marqueePlay = True
    , specCarousels =
        { basic = specCarInit CarBasicRow
        , vertical = specCarInit CarVerticalRow
        , arrows = specCarInit CarArrowsRow
        , noLoop = specCarInit CarNoLoopRow
        , perView = specCarInit CarPerViewRow
        , fade = specCarInit CarFadeRow
        , card = specCarInit CarCardRow
        , defaultIx = specCarInit CarDefaultIxRow
        }
    }



-- MSG


type Msg
    = -- Carousel · autoplay + arrows + dots + wheel
      ToggleAutoplay Bool
    | AutoTick Time.Posix
    | CarPrev
    | CarNext
    | CarDotTo Int
    | CarTransitionEnd
    | CarWheel Carousel.WheelInfo
    | CarEnter
    | CarLeave
    | CarDotKey Int Carousel.KeyInfo
      -- Carousel · pointer drag
    | DragStart Carousel.DragPoint
    | DragMove Float Float
    | DragTick Time.Posix
    | DragEnd
    | DragTransitionEnd
      -- Log · scroll + load
    | LogScrollStep Float
    | LogWheel Float
    | LogFlushTick Time.Posix
      -- Countdown · live clock
    | ClockTick Time.Posix
    | CountdownRestart
      -- NumberAnimation · tween
    | NaTarget Float
    | NaTick Time.Posix
      -- Progress · drive
    | ProgressDelta Float
    | ProgressProcessing Bool
      -- Spin · toggle
    | SpinToggle Bool
      -- Skeleton · load
    | SkelToggle Bool
      -- Marquee · play
    | MarqueeToggle Bool
      -- Carousel · static rows (phase 2: state-drive with identical init)
    | SpecCarPrev SpecCarRow
    | SpecCarNext SpecCarRow
    | SpecCarTo SpecCarRow Int
    | SpecCarSlide SpecCarRow Int
    | SpecCarEnd SpecCarRow
    | SpecCarKey SpecCarRow Int Carousel.KeyInfo



-- UPDATE


update : Msg -> Model -> Model
update msg model =
    case msg of
        -- Carousel · autoplay + arrows + dots + wheel
        ToggleAutoplay on ->
            { model | autoplay = on }

        AutoTick _ ->
            let
                opts =
                    carouselOpts model.autoplay

                env =
                    Carousel.envOf opts model.carousel model.carousel.slideCount
            in
            if env.autoplayEnabled then
                carStep Carousel.next model

            else
                model

        CarPrev ->
            carStep Carousel.prev model

        CarNext ->
            carStep Carousel.next model

        CarDotTo i ->
            carStep (\o s -> Carousel.to o s i) model

        CarTransitionEnd ->
            { model | carousel = Carousel.transitionEnd (carouselOpts model.autoplay) model.carousel }

        CarWheel info ->
            carStep (\o s -> Carousel.wheel o s info) model

        CarEnter ->
            { model | carouselPaused = True }

        CarLeave ->
            { model | carouselPaused = False }

        CarDotKey _ info ->
            let
                opts =
                    carouselOpts model.autoplay

                env =
                    Carousel.envOf opts model.carousel model.carousel.slideCount
            in
            case Carousel.dotKeyAction opts env info of
                Just Carousel.ToNext ->
                    carStep Carousel.next model

                Just Carousel.ToPrev ->
                    carStep Carousel.prev model

                _ ->
                    model

        -- Carousel · pointer drag
        DragStart point ->
            if model.dragging then
                model

            else
                { model
                    | drag = Carousel.dragStart dragOpts model.drag point
                    , dragging = True
                    , dragElapsed = 0
                    , dragLastTick = Nothing
                }

        DragMove x y ->
            if model.dragging then
                { model | drag = Carousel.dragMove dragOpts model.drag { x = x, y = y } }

            else
                model

        DragTick now ->
            if model.dragging then
                { model
                    | dragElapsed = model.dragElapsed + sinceMs model.dragLastTick now
                    , dragLastTick = Just (Time.posixToMillis now)
                }

            else
                model

        DragEnd ->
            if model.dragging then
                { model
                    | drag = Carousel.dragEnd dragOpts model.drag model.dragElapsed
                    , dragging = False
                    , dragLastTick = Nothing
                }

            else
                model

        DragTransitionEnd ->
            { model | drag = Carousel.transitionEnd dragOpts model.drag }

        -- Log · scroll + load
        LogScrollStep delta ->
            let
                top =
                    clampLogScroll model (model.logScrollTop + delta)

                events =
                    Log.scrollEvents (logScrollMetrics model top)
            in
            applyLogEvents events { model | logScrollTop = top }

        LogWheel deltaY ->
            let
                top =
                    clampLogScroll model (model.logScrollTop + deltaY)

                m =
                    logMetrics model

                events =
                    Log.wheelEvents
                        { scrollTop = round top
                        , containerHeight = round m.containerHeight
                        , contentHeight = round m.contentHeight
                        , deltaY = deltaY
                        }
            in
            applyLogEvents events { model | logScrollTop = top }

        LogFlushTick _ ->
            case model.logPending of
                Nothing ->
                    model

                Just Log.Top ->
                    { model
                        | logLines =
                            List.map (\n -> "recovered " ++ String.fromInt n ++ " · journal replay")
                                (List.range model.logRec (model.logRec + 5))
                                ++ model.logLines
                        , logRec = model.logRec + 6
                        , logPending = Nothing
                    }

                Just Log.Bottom ->
                    { model
                        | logLines =
                            model.logLines
                                ++ List.map (\n -> "tail " ++ String.fromInt n ++ " · worker heartbeat")
                                    (List.range model.logSeq (model.logSeq + 5))
                        , logSeq = model.logSeq + 6
                        , logPending = Nothing
                    }

        -- Countdown · live clock
        ClockTick now ->
            let
                next =
                    max 0 (model.countdown - round (sinceMs model.clockLast now))
            in
            -- a showcase countdown never reads "dead": at zero the 90 s
            -- window restarts (a stopped 00:00:00 looks broken, not live)
            { model
                | countdown =
                    if next == 0 then
                        90000

                    else
                        next
                , clockLast = Just (Time.posixToMillis now)
            }

        CountdownRestart ->
            { model | countdown = 90000, clockLast = Nothing }

        -- NumberAnimation · tween
        NaTarget target ->
            { model
                | naFrom =
                    NumberAnimation.tweenValue
                        { from = model.naFrom
                        , to = model.naTo
                        , duration = naDuration
                        , elapsed = model.naElapsed
                        }
                , naTo = target
                , naElapsed = 0
                , naLast = Nothing
            }

        NaTick now ->
            { model
                | naElapsed = min naDuration (model.naElapsed + sinceMs model.naLast now)
                , naLast = Just (Time.posixToMillis now)
            }

        -- Progress · drive
        ProgressDelta d ->
            { model | progress = clamp 0 100 (model.progress + d) }

        ProgressProcessing on ->
            { model | processing = on }

        -- Spin · toggle
        SpinToggle on ->
            { model | spinShow = on }

        -- Skeleton · load
        SkelToggle on ->
            { model | loaded = on }

        -- Marquee · play
        MarqueeToggle on ->
            { model | marqueePlay = on }

        -- Carousel · static rows
        SpecCarPrev row ->
            specCarStep row Carousel.prev model

        SpecCarNext row ->
            specCarStep row Carousel.next model

        SpecCarTo row i ->
            specCarStep row (\o s -> Carousel.to o s i) model

        SpecCarSlide row i ->
            -- the card-effect gate: clicking an inactive slide runs `to`
            specCarStep row (\o s -> Carousel.to o s i) model

        SpecCarEnd row ->
            { model
                | specCarousels =
                    specCarSet row
                        (Carousel.transitionEnd (specCarOpts row) (specCarGet row model))
                        model.specCarousels
            }

        SpecCarKey row _ info ->
            let
                opts =
                    specCarOpts row

                st =
                    specCarGet row model

                env =
                    Carousel.envOf opts st st.slideCount
            in
            case Carousel.dotKeyAction opts env info of
                Just Carousel.ToNext ->
                    specCarStep row Carousel.next model

                Just Carousel.ToPrev ->
                    specCarStep row Carousel.prev model

                _ ->
                    model



-- SUBSCRIPTIONS (this family owns the clocks)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 1000 ClockTick
        , if model.autoplay && not model.carouselPaused then
            Time.every (carouselOpts model.autoplay).interval AutoTick

          else
            Sub.none
        , if model.naElapsed < naDuration then
            Time.every 33 NaTick

          else
            Sub.none
        , if model.logPending /= Nothing then
            Time.every 600 LogFlushTick

          else
            Sub.none
        , if model.dragging then
            Sub.batch
                [ Browser.Events.onMouseMove
                    (Decode.map2 DragMove
                        (Decode.field "clientX" Decode.float)
                        (Decode.field "clientY" Decode.float)
                    )
                , Browser.Events.onMouseUp (Decode.succeed DragEnd)
                , Time.every 20 DragTick
                ]

          else
            Sub.none
        ]



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


{-| Which static carousel row owns a state (phase 2). The Custom (usercontrol)
row is deliberately absent — its `renderDots` slot replaces the dot bar with
plain text, so there is nothing clickable to wire; it stays a specimen.
-}
type SpecCarRow
    = CarBasicRow
    | CarVerticalRow
    | CarArrowsRow
    | CarNoLoopRow
    | CarPerViewRow
    | CarFadeRow
    | CarCardRow
    | CarDefaultIxRow


{-| The eight states, one per row, in the row order above.
-}
type alias SpecCarStates =
    { basic : Carousel.State
    , vertical : Carousel.State
    , arrows : Carousel.State
    , noLoop : Carousel.State
    , perView : Carousel.State
    , fade : Carousel.State
    , card : Carousel.State
    , defaultIx : Carousel.State
    }


{-| Each row's base options — EXACTLY the static literal sets the row used to
build inline (plus the interaction channels the row's own affordances imply:
arrows rows get `onPrev`/`onNext`, every row gets `onDotTo`, the card row
gets `onSlideClick`, and `keyboard` follows the live precedent). The `id` is
kept per-row (`live-carousel-*` — the row's original attribute).
-}
specCarOpts : SpecCarRow -> Carousel.Options Msg
specCarOpts row =
    let
        d =
            Carousel.defaults
    in
    case row of
        CarBasicRow ->
            { d
                | keyboard = True
                , onDotTo = Just (SpecCarTo CarBasicRow)
                , onDotKeydown = Just (SpecCarKey CarBasicRow)
                , onTransitionEnd = Just (SpecCarEnd CarBasicRow)
                , attributes = [ HA.id "live-carousel" ]
            }

        CarVerticalRow ->
            { d
                | direction = Carousel.Vertical
                , dotPlacement = Carousel.DotsRight
                , keyboard = True
                , onDotTo = Just (SpecCarTo CarVerticalRow)
                , onDotKeydown = Just (SpecCarKey CarVerticalRow)
                , onTransitionEnd = Just (SpecCarEnd CarVerticalRow)
                , attributes = [ HA.id "live-carousel-vertical" ]
            }

        CarArrowsRow ->
            { d
                | showArrow = True
                , dotType = Carousel.Line
                , keyboard = True
                , onPrev = Just (SpecCarPrev CarArrowsRow)
                , onNext = Just (SpecCarNext CarArrowsRow)
                , onDotTo = Just (SpecCarTo CarArrowsRow)
                , onDotKeydown = Just (SpecCarKey CarArrowsRow)
                , onTransitionEnd = Just (SpecCarEnd CarArrowsRow)
                , attributes = [ HA.id "live-carousel-arrows" ]
            }

        CarNoLoopRow ->
            { d
                | loop = False
                , showArrow = True
                , keyboard = True
                , onPrev = Just (SpecCarPrev CarNoLoopRow)
                , onNext = Just (SpecCarNext CarNoLoopRow)
                , onDotTo = Just (SpecCarTo CarNoLoopRow)
                , onDotKeydown = Just (SpecCarKey CarNoLoopRow)
                , onTransitionEnd = Just (SpecCarEnd CarNoLoopRow)
                , attributes = [ HA.id "live-carousel-no-loop" ]
            }

        CarPerViewRow ->
            { d
                | slidesPerView = Carousel.PerView 3
                , spaceBetween = 20
                , loop = False
                , showArrow = True
                , keyboard = True
                , onPrev = Just (SpecCarPrev CarPerViewRow)
                , onNext = Just (SpecCarNext CarPerViewRow)
                , onDotTo = Just (SpecCarTo CarPerViewRow)
                , onDotKeydown = Just (SpecCarKey CarPerViewRow)
                , onTransitionEnd = Just (SpecCarEnd CarPerViewRow)
                , attributes = [ HA.id "live-carousel-slides-per-view" ]
            }

        CarFadeRow ->
            { d
                | effect = Carousel.FadeEffect
                , keyboard = True
                , onDotTo = Just (SpecCarTo CarFadeRow)
                , onDotKeydown = Just (SpecCarKey CarFadeRow)
                , onTransitionEnd = Just (SpecCarEnd CarFadeRow)
                , attributes = [ HA.id "live-carousel-fade" ]
            }

        CarCardRow ->
            { d
                | effect = Carousel.CardEffect
                , showDots = False
                , prevSlideStyle = Just "transform:translateX(-60%) scale(0.7)"
                , nextSlideStyle = Just "transform:translateX(60%) scale(0.7)"
                , keyboard = True
                , onSlideClick = Just (SpecCarSlide CarCardRow)
                , onTransitionEnd = Just (SpecCarEnd CarCardRow)
                , attributes = [ HA.id "live-carousel-card" ]
            }

        CarDefaultIxRow ->
            { d
                | defaultIndex = 2
                , keyboard = True
                , onDotTo = Just (SpecCarTo CarDefaultIxRow)
                , onDotKeydown = Just (SpecCarKey CarDefaultIxRow)
                , onTransitionEnd = Just (SpecCarEnd CarDefaultIxRow)
                , attributes = [ HA.id "live-carousel-default-index" ]
            }


{-| The per-row fixed measured size — the same literal the row passed to
`Carousel.resize` before.
-}
specCarSize : SpecCarRow -> Carousel.Size
specCarSize row =
    case row of
        CarBasicRow ->
            { width = 920, height = 360 }

        CarVerticalRow ->
            { width = 560, height = 280 }

        CarArrowsRow ->
            { width = 920, height = 360 }

        CarNoLoopRow ->
            { width = 920, height = 360 }

        CarPerViewRow ->
            { width = 920, height = 360 }

        CarFadeRow ->
            { width = 920, height = 360 }

        CarCardRow ->
            { width = 920, height = 360 }

        CarDefaultIxRow ->
            { width = 920, height = 360 }


{-| One row's init: the exact `resize opts size (init opts 4)` the row used to
run inline (NO `markMounted` — the static output keeps the pre-mount fade/card
gate, byte-identical to before).
-}
specCarInit : SpecCarRow -> Carousel.State
specCarInit row =
    Carousel.resize (specCarOpts row) (specCarSize row) (Carousel.init (specCarOpts row) 4)


specCarGet : SpecCarRow -> Model -> Carousel.State
specCarGet row model =
    case row of
        CarBasicRow ->
            model.specCarousels.basic

        CarVerticalRow ->
            model.specCarousels.vertical

        CarArrowsRow ->
            model.specCarousels.arrows

        CarNoLoopRow ->
            model.specCarousels.noLoop

        CarPerViewRow ->
            model.specCarousels.perView

        CarFadeRow ->
            model.specCarousels.fade

        CarCardRow ->
            model.specCarousels.card

        CarDefaultIxRow ->
            model.specCarousels.defaultIx


specCarSet : SpecCarRow -> Carousel.State -> SpecCarStates -> SpecCarStates
specCarSet row st states =
    case row of
        CarBasicRow ->
            { states | basic = st }

        CarVerticalRow ->
            { states | vertical = st }

        CarArrowsRow ->
            { states | arrows = st }

        CarNoLoopRow ->
            { states | noLoop = st }

        CarPerViewRow ->
            { states | perView = st }

        CarFadeRow ->
            { states | fade = st }

        CarCardRow ->
            { states | card = st }

        CarDefaultIxRow ->
            { states | defaultIx = st }


{-| One port step over one row's state (the `carStep` pattern, per-row).
-}
specCarStep : SpecCarRow -> (Carousel.Options Msg -> Carousel.State -> Carousel.State) -> Model -> Model
specCarStep row f model =
    { model
        | specCarousels =
            specCarSet row (f (specCarOpts row) (specCarGet row model)) model.specCarousels
    }


tagD : Tag.Options msg
tagD =
    Tag.defaults


cardD : Card.Options msg
cardD =
    Card.defaults


btn : Button.Options Msg
btn =
    Button.defaults


swD : Switch.Options Msg
swD =
    Switch.defaults


cbD : Checkbox.Options Msg
cbD =
    Checkbox.defaults


progD : Progress.Options msg
progD =
    Progress.defaults


skelD : Skeleton.Options msg
skelD =
    Skeleton.defaults


spinD : Spin.Options msg
spinD =
    Spin.defaults


marqueeD : Marquee.Options msg
marqueeD =
    Marquee.defaults


countdownD : Countdown.Options msg
countdownD =
    Countdown.defaults


logD : Log.Options msg
logD =
    Log.defaults


numberAnimationD : NumberAnimation.Options msg
numberAnimationD =
    NumberAnimation.defaults


naD : NumberAnimation.Options Msg
naD =
    NumberAnimation.defaults


naDuration : Float
naDuration =
    2000



-- VIEW (live demo cells — verbatim from Live/Motion.elm; each lands in a
-- demoRow with its original label, appended to its family section)


carouselDemo : Theme -> Model -> Element Msg
carouselDemo theme model =
    let
        opts =
            carouselOpts model.autoplay

        env =
            Carousel.envOf opts model.carousel model.carousel.slideCount

        caption =
            "slide "
                ++ String.fromInt (env.displayIndex + 1)
                ++ " / "
                ++ String.fromInt env.displayTotalView
                ++ " · real "
                ++ String.fromInt env.realIndex
                ++ (if model.carouselPaused then
                        " · paused"

                    else
                        ""
                   )
                ++ (case model.announce of
                        Just a ->
                            " · " ++ a

                        Nothing ->
                            ""
                   )
    in
    Element.column [ Element.spacing 8 ]
        [ Element.row [ Element.spacing 12 ]
            [ Switch.view theme
                { swD | size = T.Small, value = model.autoplay, onChange = Just ToggleAutoplay }
                []
            , Element.text caption
            ]
        , carouselBand carSize (Carousel.view theme opts model.carousel slides)
        ]


dragDemo : Theme -> Model -> Element Msg
dragDemo theme model =
    Element.column [ Element.spacing 8 ]
        [ Element.text
            "Mousedown on the track, move, release — document listeners feed the port's dragStart / dragMove / dragEnd (flick included)."
        , carouselBand dragSize (Carousel.view theme dragOpts model.drag slides)
        , Element.text
            ("drag offset "
                ++ String.fromFloat model.drag.dragOffset
                ++ " px"
                ++ (if model.dragging then
                        " · dragging"

                    else
                        ""
                   )
            )
        ]


logDemo : Theme -> Model -> Element Msg
logDemo theme model =
    Element.column [ Element.spacing 8 ]
        [ Element.row [ Element.spacing 8 ]
            [ smallBtn theme "Scroll up 120 px" (LogScrollStep -120)
            , smallBtn theme "Scroll down 120 px" (LogScrollStep 120)
            , Element.text
                ("scrollTop "
                    ++ String.fromInt (round model.logScrollTop)
                    ++ " px · "
                    ++ String.fromInt (List.length model.logLines)
                    ++ " lines"
                    ++ (case model.logPending of
                            Just Log.Top ->
                                " · loading older…"

                            Just Log.Bottom ->
                                " · loading newer…"

                            Nothing ->
                                ""
                       )
                )
            ]
        , Element.el [ Element.width (Element.px 420) ]
            (Log.view theme
                { logD
                    | lines = model.logLines
                    , rows = logRows
                    , loading = model.logPending /= Nothing
                    , attributes =
                        [ Element.htmlAttribute (HA.id "live-log")
                        , Element.htmlAttribute
                            (HE.on "wheel"
                                (Decode.map LogWheel (Decode.field "deltaY" Decode.float))
                            )
                        ]
                }
            )
        , Element.text "Wheel inside the pane too — the same RequireMoreFrom algebra via Log.wheelEvents."
        ]


countdownDemo : Theme -> Model -> Element Msg
countdownDemo theme model =
    Element.column [ Element.spacing 8 ]
        [ Element.row [ Element.spacing 8 ]
            [ smallBtn theme "Restart 90 s" CountdownRestart
            , Element.text (String.fromInt (model.countdown // 1000) ++ " s remaining")
            ]
        , Countdown.view theme
            { countdownD
                | distance = model.countdown
                , attributes = [ Element.htmlAttribute (HA.id "live-countdown") ]
            }
            []
        , Countdown.view theme
            { countdownD
                | distance = model.countdown
                , precision = 1
                , render =
                    Just
                        (\info ->
                            Element.text
                                (pad2 info.hours ++ "h " ++ pad2 info.minutes ++ "m " ++ pad2 info.seconds ++ "s")
                        )
                , attributes = [ Element.htmlAttribute (HA.id "live-countdown-custom") ]
            }
            []
        ]


numberDemo : Theme -> Model -> Element Msg
numberDemo theme model =
    Element.column [ Element.spacing 8 ]
        [ Element.row [ Element.spacing 8 ]
            [ smallBtn theme "Animate to 4,200" (NaTarget 4200)
            , smallBtn theme "Animate to 120,500" (NaTarget 120500)
            , smallBtn theme "Animate to 64,000,000" (NaTarget 64000000)
            , Element.text ("target " ++ String.fromFloat model.naTo)
            ]
        , NumberAnimation.view theme
            { naD
                | from = model.naFrom
                , to = model.naTo
                , duration = naDuration
                , elapsed = model.naElapsed
                , precision = 0
                , showSeparator = True
                , attributes = [ Element.htmlAttribute (HA.id "live-number-animation") ]
            }
            []
        ]


progressDemo : Theme -> Model -> Element Msg
progressDemo theme model =
    Element.column [ Element.spacing 8 ]
        [ Element.row [ Element.spacing 8 ]
            [ smallBtn theme "− 10" (ProgressDelta -10)
            , smallBtn theme "+ 10" (ProgressDelta 10)
            , Switch.view theme
                { swD | size = T.Small, value = model.processing, onChange = Just ProgressProcessing }
                []
            , Element.text (String.fromFloat model.progress ++ " %")
            ]
        , Progress.view theme
            { progD
                | percentage = model.progress
                , processing = model.processing
                , height = Just 12
                , attributes = [ Element.htmlAttribute (HA.id "live-progress-line") ]
            }
            []
        , Progress.view theme
            { progD
                | type_ = Progress.Circle
                , percentage = model.progress
                , processing = model.processing
                , attributes = [ Element.htmlAttribute (HA.id "live-progress-circle") ]
            }
            []
        ]


spinDemo : Theme -> Model -> Element Msg
spinDemo theme model =
    Element.column [ Element.spacing 8 ]
        [ Checkbox.view theme
            { cbD | checked = model.spinShow, onCheck = Just SpinToggle }
            [ Element.text "Spinning" ]
        , Spin.view theme
            { spinD
                | show = model.spinShow
                , description = Just (Element.text "Loading")
                , attributes = [ Element.htmlAttribute (HA.id "live-spin") ]
            }
            [ Element.column [ Element.spacing 4 ]
                [ Element.text "Live region content"
                , Element.text "The overlay dims it while spinning."
                ]
            ]
        ]


skeletonDemo : Theme -> Model -> Element Msg
skeletonDemo theme model =
    Element.row [ Element.spacing 16, Element.alignTop ]
        [ Switch.view theme
            { swD | size = T.Small, value = model.loaded, onChange = Just SkelToggle }
            []
        , if model.loaded then
            Element.row [ Element.spacing 12 ]
                [ Element.el
                    [ Element.width (Element.px 40)
                    , Element.height (Element.px 40)
                    , Border.rounded 50
                    , Bg.color (Element.rgb 0.09 0.63 0.35)
                    ]
                    Element.none
                , Element.column [ Element.spacing 6 ]
                    [ Element.text "Naive UI for Elm"
                    , Element.text "100 components, pure state, real motion."
                    , chip theme "loaded"
                    ]
                ]

          else
            Element.row [ Element.spacing 12 ]
                [ Skeleton.view theme
                    { skelD
                        | circle = True
                        , width = Just (Skeleton.Px 40)
                        , height = Just (Skeleton.Px 40)
                        , attributes = [ Element.htmlAttribute (HA.id "live-skeleton-avatar") ]
                    }
                    []
                , Element.column [ Element.spacing 8 ]
                    [ Skeleton.view theme
                        { skelD
                            | text = True
                            , width = Just (Skeleton.Px 200)
                            , attributes = [ Element.htmlAttribute (HA.id "live-skeleton-line-1") ]
                        }
                        []
                    , Skeleton.view theme
                        { skelD
                            | text = True
                            , width = Just (Skeleton.Px 150)
                            , attributes = [ Element.htmlAttribute (HA.id "live-skeleton-line-2") ]
                        }
                        []
                    , Skeleton.view theme
                        { skelD
                            | text = True
                            , width = Just (Skeleton.Px 100)
                            , attributes = [ Element.htmlAttribute (HA.id "live-skeleton-line-3") ]
                        }
                        []
                    ]
                ]
        ]


marqueeDemo : Theme -> Model -> Element Msg
marqueeDemo theme model =
    Element.column [ Element.spacing 8 ]
        [ Element.row [ Element.spacing 8 ]
            [ Switch.view theme
                { swD | size = T.Small, value = model.marqueePlay, onChange = Just MarqueeToggle }
                []
            , Element.text
                (if model.marqueePlay then
                    "running"

                 else
                    "paused"
                )
            ]
        , Element.el [ Element.width (Element.px 260) ]
            (Marquee.view theme
                { marqueeD
                    | duration = 12
                    , play = model.marqueePlay
                    , attributes = [ Element.htmlAttribute (HA.id "live-marquee") ]
                }
                [ Element.text "Naive UI for Elm — pure state, real motion — every tick owned by the caller — " ]
            )
        ]



-- CAROUSEL WIRING


{-| The main carousel: fixed measured size, every channel wired to one Msg.
`interval` is what the autoplay subscription reads.
-}
carouselOpts : Bool -> Carousel.Options Msg
carouselOpts autoplay =
    let
        d =
            Carousel.defaults
    in
    { d
        | showArrow = True
        , dotType = Carousel.Line
        , autoplay = autoplay
        , interval = 3000
        , mousewheel = True
        , keyboard = True
        , onPrev = Just CarPrev
        , onNext = Just CarNext
        , onDotTo = Just CarDotTo
        , onTransitionEnd = Just CarTransitionEnd
        , onWheel = Just CarWheel
        , onRootMouseEnter = Just CarEnter
        , onRootMouseLeave = Just CarLeave
        , onDotKeydown = Just CarDotKey
        , attributes = [ HA.id "live-carousel-auto" ]
    }


{-| The drag carousel: `draggable` arms the root mousedown listener (the port
routes it through the `onTouchStart` channel), document subscriptions do the
rest.
-}
dragOpts : Carousel.Options Msg
dragOpts =
    let
        d =
            Carousel.defaults
    in
    { d
        | draggable = True
        , onTouchStart = Just DragStart
        , onTransitionEnd = Just DragTransitionEnd
        , attributes = [ HA.id "live-carousel-drag" ]
    }


carSize : Carousel.Size
carSize =
    { width = 640, height = 260 }


dragSize : Carousel.Size
dragSize =
    { width = 640, height = 260 }


{-| The fake gradient slides from the static section (same helper, same data).
-}
slides : List (Html.Html Msg)
slides =
    let
        img gradient =
            Html.img
                [ HA.attribute "style" ("display:block;width:100%;height:100%;object-fit:cover;background:" ++ gradient)
                , HA.src "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
                , HA.alt ""
                ]
                []
    in
    [ img "linear-gradient(135deg, #18a058, #63e2b7)"
    , img "linear-gradient(135deg, #2080f0, #70c0e8)"
    , img "linear-gradient(135deg, #f0a020, #fcd68a)"
    , img "linear-gradient(135deg, #d03050, #e88080)"
    ]


{-| The carousel viewport: a plain 640x260 band (`size`), clipped by
`overflow: hidden` (the previous lane's fix — the off-band neighbour slides
must stay clipped).

The explicit `min-height` is load-bearing. elm-ui's column-child rule
`.s.c > .s { min-height: min-content }` applies to this wrapper (a flex item
of the demo's column) and makes it at least as tall as its content. The inner
`n-carousel` is `height: 100%`, its slides too, and the 1:1 gradient `<img>`
(`height: 100%` against an auto parent) resolves to its intrinsic square
ratio — so min-content = 640, which BEATS the declared `height: 260px`
(`height` loses to a larger `min-height`) and renders a 640x640 square.
Pinning `min-height` to the band height lets the whole `height: 100%` chain
resolve against the declared band instead of the image's intrinsic size.

-}
carouselBand : Carousel.Size -> Element Msg -> Element Msg
carouselBand size content =
    Element.el
        [ Element.width (Element.px (round size.width))
        , Element.height (Element.px (round size.height))
        , Element.htmlAttribute
            (HA.attribute "style"
                ("overflow:hidden;border-radius:3px;min-height:"
                    ++ String.fromInt (round size.height)
                    ++ "px"
                )
            )
        ]
        content


{-| Run one port step over the main carousel state and let the port's own
`indexChange` emit drive the caption.
-}
carStep : (Carousel.Options Msg -> Carousel.State -> Carousel.State) -> Model -> Model
carStep f model =
    let
        opts =
            carouselOpts model.autoplay

        new =
            f opts model.carousel
    in
    { model
        | carousel = new
        , announce =
            case Carousel.indexChange model.carousel new of
                Just ( current, was ) ->
                    Just ("moved " ++ String.fromInt was ++ " → " ++ String.fromInt current)

                Nothing ->
                    model.announce
    }



-- LOG WIRING (simulated geometry — the real app would feed measured ints)


logRows : Int
logRows =
    6


{-| fontSize 14 × lineHeight 1.25 — the same product `Log.styleHeight` uses.
-}
logLinePx : Float
logLinePx =
    14 * 1.25


logMetrics : Model -> { containerHeight : Float, contentHeight : Float }
logMetrics model =
    { containerHeight = toFloat logRows * logLinePx
    , contentHeight = toFloat (List.length model.logLines) * logLinePx
    }


logScrollMetrics :
    Model
    -> Float
    -> { scrollTop : Int, containerHeight : Int, contentHeight : Int, offsetTop : Int, offsetBottom : Int }
logScrollMetrics model top =
    let
        m =
            logMetrics model
    in
    { scrollTop = round top
    , containerHeight = round m.containerHeight
    , contentHeight = round m.contentHeight
    , offsetTop = 0
    , offsetBottom = 0
    }


clampLogScroll : Model -> Float -> Float
clampLogScroll model top =
    let
        m =
            logMetrics model
    in
    clamp 0 (max 0 (m.contentHeight - m.containerHeight)) top


applyLogEvents : List Log.LogEvent -> Model -> Model
applyLogEvents events model =
    List.foldl applyLogEvent model events


applyLogEvent : Log.LogEvent -> Model -> Model
applyLogEvent event model =
    case event of
        Log.RequireMoreFrom panel ->
            if model.logPending == Nothing then
                { model | logPending = Just panel }

            else
                model

        -- ReachTop / ReachBottom are notifications (a toast upstream) —
        -- nothing to own in this demo.
        Log.ReachTop ->
            model

        Log.ReachBottom ->
            model


logLine : Int -> String
logLine n =
    "10:" ++ pad2 (modBy 60 (n * 7)) ++ ":00 worker heartbeat #" ++ String.fromInt n



-- SHARED HELPERS


smallBtn : Theme -> String -> Msg -> Element Msg
smallBtn theme label msg =
    Button.view theme
        { btn | size = T.Small, onPress = Just msg }
        [ Element.text label ]


{-| The ms elapsed between a ticking clock's last Posix and this one.
-}
sinceMs : Maybe Int -> Time.Posix -> Float
sinceMs last now =
    case last of
        Just l ->
            toFloat (Time.posixToMillis now - l)

        Nothing ->
            0


pad2 : Int -> String
pad2 n =
    String.padLeft 2 '0' (String.fromInt n)



-- SECTIONS (static rows verbatim; live variants append the live demo rows)


progressRows : Theme -> List (Element msg)
progressRows theme =
    [ demoRow theme
        "mot-001"
        "Line"
        [ Element.el [ Element.width (Element.px 260) ]
            (Progress.view theme { progD | percentage = 50 } [])
        , Element.el [ Element.width (Element.px 260) ]
            (Progress.view theme
                { progD | percentage = 66, processing = True, height = Just 12 }
                []
            )
        , Element.el [ Element.width (Element.px 260) ]
            (Progress.view theme
                { progD
                    | percentage = 40
                    , railColor = Just "#e0e0e0"
                    , railStyle =
                        Just
                            [ ( "background-image"
                              , "repeating-linear-gradient(45deg, #eee, #eee 6px, #ddd 6px, #ddd 12px)"
                              )
                            ]
                }
                []
            )
        ]
    , demoRow theme
        "mot-002"
        "Statuses"
        [ Element.el [ Element.width (Element.px 260) ]
            (Progress.view theme
                { progD | percentage = 100, status = Progress.Success }
                []
            )
        , Element.el [ Element.width (Element.px 260) ]
            (Progress.view theme
                { progD | percentage = 32, status = Progress.Error }
                []
            )
        ]
    , demoRow theme
        "mot-003"
        "Circle & dashboard"
        [ Progress.view theme { progD | type_ = Progress.Circle, percentage = 75 } []
        , Progress.view theme { progD | type_ = Progress.Dashboard, percentage = 60 } []
        ]
    , demoRow theme
        "mot-004"
        "Multiple circle"
        [ Progress.view theme
            { progD
                | type_ = Progress.MultipleCircle
                , percentages = [ 80, 60 ]
                , colors = [ Progress.Solid "#2080f0", Progress.Solid "#18a058" ]
                , railColors = [ "#2080f0", "#18a058" ]
                , railStyles =
                    [ [ ( "stroke", "#2080f0" ), ( "opacity", "0.3" ) ]
                    , [ ( "stroke", "#18a058" ), ( "opacity", "0.3" ) ]
                    ]
                , strokeWidth = 6
                , circleGap = 0.5
            }
            [ Element.text "Circle racing!" ]
        , Progress.view theme
            { progD
                | type_ = Progress.MultipleCircle
                , percentages = [ 70, 40 ]
                , strokeWidth = 10
                , circleGap = 10
            }
            []
        ]
    , demoRow theme
        "mot-005"
        "Gradients"
        [ Element.el [ Element.width (Element.px 260) ]
            (Progress.view theme
                { progD
                    | percentage = 80
                    , color = Just (Progress.Gradient [ "white", "pink" ])
                }
                []
            )
        , Progress.view theme
            { progD
                | type_ = Progress.Circle
                , percentage = 80
                , color = Just (Progress.Gradient [ "#E3F2FD", "#2080f0" ])
            }
            []
        , Progress.view theme
            { progD
                | type_ = Progress.MultipleCircle
                , percentages = [ 80, 70 ]
                , colors =
                    [ Progress.Gradient [ "white", "#18a058" ]
                    , Progress.Gradient [ "#E3F2FD", "#2080f0" ]
                    ]
                , railColors = [ "#18a058", "#2080f0" ]
                , strokeWidth = 10
                , circleGap = 10
            }
            [ Element.text "Circle racing!" ]
        ]
    ]


progressSection : Theme -> Element msg
progressSection theme =
    section theme "Progress" "Line, circle, dashboard and multiple-circle meters." (progressRows theme)


{-| Live: `#live-progress-line` / `#live-progress-circle` (model-owned
percentage + processing flag).
-}
progressLiveSection : Model -> Theme -> Element Msg
progressLiveSection model theme =
    section theme
        "Progress"
        "Line, circle, dashboard and multiple-circle meters."
        (progressRows theme ++ [ demoRow theme "mot-006" "Progress · drive" [ progressDemo theme model ] ])


skeletonRows : Theme -> List (Element msg)
skeletonRows theme =
    [ demoRow theme
        "mot-007"
        "Default"
        [ Skeleton.view theme
            { skelD
                | width = Just (Skeleton.Px 240)
                , height = Just (Skeleton.Px 16)
            }
            []
        ]
    , demoRow theme
        "mot-008"
        "Text & repeat"
        [ Skeleton.view theme
            { skelD | text = True, width = Just (Skeleton.Px 150), repeat = 3 }
            []
        ]
    , demoRow theme
        "mot-009"
        "Shapes & states"
        [ Skeleton.view theme { skelD | circle = True, width = Just (Skeleton.Px 40) } []
        , Skeleton.view theme
            { skelD
                | round = True
                , width = Just (Skeleton.Px 100)
                , height = Just (Skeleton.Px 12)
            }
            []
        , Skeleton.view theme
            { skelD
                | width = Just (Skeleton.Px 100)
                , height = Just (Skeleton.Px 12)
                , animated = False
            }
            []
        ]
    ]


skeletonSection : Theme -> Element msg
skeletonSection theme =
    section theme "Skeleton" "Placeholder shimmer for loading content." (skeletonRows theme)


{-| Live: `#live-skeleton-avatar` / `#live-skeleton-line-<n>` (toggle swaps
skeleton ↔ loaded content).
-}
skeletonLiveSection : Model -> Theme -> Element Msg
skeletonLiveSection model theme =
    section theme
        "Skeleton"
        "Placeholder shimmer for loading content."
        (skeletonRows theme ++ [ demoRow theme "mot-010" "Skeleton · load" [ skeletonDemo theme model ] ])


spinRows : Theme -> List (Element msg)
spinRows theme =
    [ demoRow theme
        "mot-011"
        "Standalone"
        [ Spin.view theme spinD []
        , Spin.view theme { spinD | size = Spin.Small } []
        , Spin.view theme { spinD | size = Spin.Large } []
        ]
    , demoRow theme
        "mot-012"
        "With description"
        [ Spin.view theme { spinD | description = Just (Element.text "Loading") } []
        ]
    , demoRow theme
        "mot-013"
        "Wrapping content"
        [ Element.el [ Element.width (Element.px 320), Element.height (Element.px 110) ]
            (Spin.view theme
                spinD
                [ Card.view theme
                    { cardD | title = Just (Element.text "A card") }
                    [ Element.text "The spinner overlays this content while loading." ]
                ]
            )
        ]
    ]


spinSection : Theme -> Element msg
spinSection theme =
    section theme "Spin" "Loading spinners, standalone or wrapping content." (spinRows theme)


{-| Live: `#live-spin` (checkbox toggles the spin overlay over live content).
-}
spinLiveSection : Model -> Theme -> Element Msg
spinLiveSection model theme =
    section theme
        "Spin"
        "Loading spinners, standalone or wrapping content."
        (spinRows theme ++ [ demoRow theme "mot-014" "Spin · toggle" [ spinDemo theme model ] ])


marqueeRows : Theme -> List (Element msg)
marqueeRows theme =
    [ Element.el [ Element.width (Element.px 360) ]
        (Marquee.view theme
            { marqueeD | duration = 8, autoFill = True, repeat = 2 }
            [ Tag.view theme { tagD | kind = T.Primary } [ Element.text "Naive UI" ]
            , Element.text "  ·  scrolling text  ·  "
            , Tag.view theme { tagD | kind = T.Success } [ Element.text "Elm" ]
            ]
        )
    ]


marqueeSection : Theme -> Element msg
marqueeSection theme =
    section theme "Marquee" "Scrolling content (duration is caller-owned)." (marqueeRows theme)


{-| Live: `#live-marquee` (switch pauses/plays via the `play` option).
-}
marqueeLiveSection : Model -> Theme -> Element Msg
marqueeLiveSection model theme =
    section theme
        "Marquee"
        "Scrolling content (duration is caller-owned)."
        (marqueeRows theme ++ [ demoRow theme "mot-015" "Marquee · play" [ marqueeDemo theme model ] ])


countdownRows : Theme -> List (Element msg)
countdownRows theme =
    [ demoRow theme
        "mot-016"
        "Precisions"
        [ Countdown.view theme { countdownD | distance = 90000, precision = 0 } []
        , Countdown.view theme { countdownD | distance = 90000, precision = 1 } []
        , Countdown.view theme { countdownD | distance = 90000, precision = 3 } []
        ]
    , demoRow theme
        "mot-017"
        "Custom render"
        [ Countdown.view theme
            { countdownD
                | distance = 5000
                , render =
                    Just
                        (\info ->
                            Element.text (String.fromInt info.seconds ++ "s left")
                        )
            }
            []
        ]
    ]


countdownSection : Theme -> Element msg
countdownSection theme =
    section theme "Countdown" "Remaining time (the caller owns the clock)." (countdownRows theme)


{-| Live: `#live-countdown` / `#live-countdown-custom` (a real `Time.every`
clock owns the distance; zero restarts the 90 s window).
-}
countdownLiveSection : Model -> Theme -> Element Msg
countdownLiveSection model theme =
    section theme
        "Countdown"
        "Remaining time (the caller owns the clock)."
        (countdownRows theme ++ [ demoRow theme "mot-018" "Countdown · live clock" [ countdownDemo theme model ] ])


numberAnimationRows : Theme -> List (Element msg)
numberAnimationRows theme =
    [ demoRow theme
        "mot-019"
        "Grouped"
        [ NumberAnimation.view theme
            { numberAnimationD
                | from = 0
                , to = 1234567.5
                , precision = 2
                , showSeparator = True
                , duration = 2000
                , elapsed = 2000
            }
            []
        ]
    , demoRow theme
        "mot-020"
        "Precision"
        [ NumberAnimation.view theme
            { numberAnimationD
                | from = 10
                , to = 110
                , precision = 1
                , duration = 3000
                , elapsed = 1500
            }
            []
        ]
    ]


numberAnimationSection : Theme -> Element msg
numberAnimationSection theme =
    section theme
        "Number Animation"
        "A tweened number (the clock is caller-owned — pass `elapsed`). No classes or variables of its own."
        (numberAnimationRows theme)


{-| Live: `#live-number-animation` (a real 33 ms tween clock; retargeting
restarts from the displayed value via the port's `tweenValue`).
-}
numberAnimationLiveSection : Model -> Theme -> Element Msg
numberAnimationLiveSection model theme =
    section theme
        "Number Animation"
        "A tweened number (the clock is caller-owned — pass `elapsed`). No classes or variables of its own."
        (numberAnimationRows theme ++ [ demoRow theme "mot-021" "NumberAnimation · tween" [ numberDemo theme model ] ])


carouselRows : Model -> Theme -> List (Element Msg)
carouselRows model theme =
    let
        spec : SpecCarRow -> Element Msg
        spec row =
            Element.el [ Element.width (Element.px (round (specCarSize row).width)) ]
                (Carousel.view theme (specCarOpts row) (specCarGet row model) slides)

        customD =
            let
                d =
                    Carousel.defaults
            in
            { d
                | effect = Carousel.CustomEffect
                , renderDots =
                    Just
                        (\info ->
                            Element.text (String.fromInt (info.currentIndex + 1) ++ " / " ++ String.fromInt info.total)
                        )
                , attributes = [ HA.id "live-carousel-custom" ]
            }
    in
    [ demoRow theme
        "mot-022"
        "Basic (loop, 4 slides + clones)"
        [ spec CarBasicRow ]
    , demoRow theme
        "mot-023"
        "Vertical + dots right"
        [ spec CarVerticalRow ]
    , demoRow theme
        "mot-024"
        "Arrows + line dots"
        [ spec CarArrowsRow ]
    , demoRow theme
        "mot-025"
        "Loop off (previous arrow disabled)"
        [ spec CarNoLoopRow ]
    , demoRow theme
        "mot-026"
        "slidesPerView 3 + spaceBetween 20"
        [ spec CarPerViewRow ]
    , demoRow theme
        "mot-027"
        "Fade"
        [ spec CarFadeRow ]
    , demoRow theme
        "mot-028"
        "Card (previous/next slide styles)"
        [ spec CarCardRow ]
    , demoRow theme
        "mot-029"
        "Custom (usercontrol) + renderDots"
        [ Element.el [ Element.width (Element.px 920) ]
            (Carousel.view theme
                customD
                (Carousel.resize customD { width = 920, height = 360 } (Carousel.init customD 4))
                slides
            )
        ]
    , demoRow theme
        "mot-030"
        "defaultIndex 2 (seeded)"
        [ spec CarDefaultIxRow ]
    ]


carouselLiveSection : Model -> Theme -> Element Msg
carouselLiveSection model theme =
    section theme
        "Carousel"
        "A slide track over a caller-owned clock and measurement — autoplay, drag and resize are the caller's to own."
        (carouselRows model theme
            ++ [ demoRow theme "mot-031" "Carousel · autoplay + arrows + dots + wheel" [ carouselDemo theme model ]
               , demoRow theme "mot-032" "Carousel · pointer drag" [ dragDemo theme model ]
               ]
        )


logSectionRows : Theme -> List (Element msg)
logSectionRows theme =
    [ demoRow theme
        "mot-033"
        "Lines (fixed rows)"
        [ Element.el [ Element.width (Element.px 420) ]
            (Log.view theme
                { logD
                    | lines = [ "2026-09-30 first entry", "second entry", "third entry" ]
                    , rows = 5
                }
            )
        ]
    , demoRow theme
        "mot-034"
        "Highlighted + loading"
        [ Element.el [ Element.width (Element.px 420) ]
            (Log.view theme
                { logD
                    | log = Just "const a = 1\nconst b = 2\nconst c = 3"
                    , language = Just "javascript"
                    , hljs = Just codeHljs
                    , loading = True
                    , rows = 4
                }
            )
        ]
    ]


logSection : Theme -> Element msg
logSection theme =
    section theme
        "Log"
        "A scrolling log pane (Code + Scrollbar + loader) — scrolling, wheel and load events are the caller's to own."
        (logSectionRows theme)


{-| Live: `#live-log` — the `Scroll up 120 px` / `Scroll down 120 px` buttons
stay immediately before the log cell in the same row (labels unique
page-wide; `nearestPreceding` resolves them).
-}
logLiveSection : Model -> Theme -> Element Msg
logLiveSection model theme =
    section theme
        "Log"
        "A scrolling log pane (Code + Scrollbar + loader) — scrolling, wheel and load events are the caller's to own."
        (logSectionRows theme ++ [ demoRow theme "mot-035" "Log · scroll + load" [ logDemo theme model ] ])


{-| The family body in Main.body order — live variants for every section
(each gains at least one live demo row appended after the static rows).
-}
sections : Model -> Theme -> List (Element Msg)
sections model theme =
    [ progressLiveSection model theme
    , skeletonLiveSection model theme
    , spinLiveSection model theme
    , marqueeLiveSection model theme
    , countdownLiveSection model theme
    , numberAnimationLiveSection model theme
    , carouselLiveSection model theme
    , logLiveSection model theme
    ]
