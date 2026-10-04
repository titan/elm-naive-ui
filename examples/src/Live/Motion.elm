module Live.Motion exposing (Model, Msg, init, subscriptions, update, view)

{-| LIVE demos — a real update loop for the motion family: Carousel, Log,
Countdown, NumberAnimation, Progress, Spin, Skeleton, Marquee.

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
import NUI.Theme exposing (Theme)
import NUI.Types as T
import Showcase exposing (chip, demoRow)
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
    }


init : Model
init =
    { autoplay = True
    , carouselPaused = False
    , carousel =
        Carousel.resize (carouselOpts True)
            carSize
            (Carousel.markMounted (Carousel.init (carouselOpts True) 4))
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
            { model
                | countdown = max 0 (model.countdown - round (sinceMs model.clockLast now))
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



-- VIEW


view : Theme -> Model -> Element Msg
view theme model =
    Element.column [ Element.spacing 20, Element.width Element.fill ]
        [ demoRow "Carousel · autoplay + arrows + dots + wheel"
            [ carouselDemo theme model ]
        , demoRow "Carousel · pointer drag"
            [ dragDemo theme model ]
        , demoRow "Log · scroll + load"
            [ logDemo theme model ]
        , demoRow "Countdown · live clock"
            [ countdownDemo theme model ]
        , demoRow "NumberAnimation · tween"
            [ numberDemo theme model ]
        , demoRow "Progress · drive"
            [ progressDemo theme model ]
        , demoRow "Spin · toggle"
            [ spinDemo theme model ]
        , demoRow "Skeleton · load"
            [ skeletonDemo theme model ]
        , demoRow "Marquee · play"
            [ marqueeDemo theme model ]
        ]


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
                    , chip "loaded"
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


{-| Defaults are bound to plain locals first (record update needs a bare
variable — `{ Button.defaults | … }` is a parse error).
-}
btn : Button.Options Msg
btn =
    Button.defaults


swD : Switch.Options Msg
swD =
    Switch.defaults


cbD : Checkbox.Options Msg
cbD =
    Checkbox.defaults


logD : Log.Options Msg
logD =
    Log.defaults


countdownD : Countdown.Options Msg
countdownD =
    Countdown.defaults


naD : NumberAnimation.Options Msg
naD =
    NumberAnimation.defaults


naDuration : Float
naDuration =
    2000


progD : Progress.Options Msg
progD =
    Progress.defaults


spinD : Spin.Options Msg
spinD =
    Spin.defaults


skelD : Skeleton.Options msg
skelD =
    Skeleton.defaults


marqueeD : Marquee.Options Msg
marqueeD =
    Marquee.defaults


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
