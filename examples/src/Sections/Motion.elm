module Sections.Motion exposing
    ( carouselSection
    , countdownSection
    , logSection
    , marqueeSection
    , numberAnimationSection
    , progressSection
    , skeletonSection
    , spinSection
    )

{-| Static showcase sections for the Motion family (carousel, log, countdown,
number animation, progress, spin, skeleton, marquee), moved verbatim from
Main.elm — the rendered DOM must stay byte-identical (the check-dom gate
reads this surface).
-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Card as Card
import NUI.Carousel as Carousel
import NUI.Countdown as Countdown
import NUI.Log as Log
import NUI.Marquee as Marquee
import NUI.NumberAnimation as NumberAnimation
import NUI.Progress as Progress
import NUI.Skeleton as Skeleton
import NUI.Spin as Spin
import NUI.Tag as Tag
import NUI.Types as T
import Showcase exposing (codeHljs, demoRow, section, theme)



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


tagD : Tag.Options msg
tagD =
    Tag.defaults


cardD : Card.Options msg
cardD =
    Card.defaults


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



-- SECTIONS (Main.elm document order)


progressSection : Element msg
progressSection =
    section "Progress" "Line, circle, dashboard and multiple-circle meters." <|
        [ demoRow "Line"
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
        , demoRow "Statuses"
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
        , demoRow "Circle & dashboard"
            [ Progress.view theme { progD | type_ = Progress.Circle, percentage = 75 } []
            , Progress.view theme { progD | type_ = Progress.Dashboard, percentage = 60 } []
            ]
        , demoRow "Multiple circle"
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
        , demoRow "Gradients"
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


skeletonSection : Element msg
skeletonSection =
    section "Skeleton" "Placeholder shimmer for loading content." <|
        [ demoRow "Default"
            [ Skeleton.view theme
                { skelD
                    | width = Just (Skeleton.Px 240)
                    , height = Just (Skeleton.Px 16)
                }
                []
            ]
        , demoRow "Text & repeat"
            [ Skeleton.view theme
                { skelD | text = True, width = Just (Skeleton.Px 150), repeat = 3 }
                []
            ]
        , demoRow "Shapes & states"
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


spinSection : Element msg
spinSection =
    section "Spin" "Loading spinners, standalone or wrapping content." <|
        [ demoRow "Standalone"
            [ Spin.view theme spinD []
            , Spin.view theme { spinD | size = Spin.Small } []
            , Spin.view theme { spinD | size = Spin.Large } []
            ]
        , demoRow "With description"
            [ Spin.view theme { spinD | description = Just (Element.text "Loading") } []
            ]
        , demoRow "Wrapping content"
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


marqueeSection : Element msg
marqueeSection =
    section "Marquee" "Scrolling content (duration is caller-owned)." <|
        [ Element.el [ Element.width (Element.px 360) ]
            (Marquee.view theme
                { marqueeD | duration = 8, autoFill = True, repeat = 2 }
                [ Tag.view theme { tagD | kind = T.Primary } [ Element.text "Naive UI" ]
                , Element.text "  ·  scrolling text  ·  "
                , Tag.view theme { tagD | kind = T.Success } [ Element.text "Elm" ]
                ]
            )
        ]


countdownSection : Element msg
countdownSection =
    section "Countdown" "Remaining time (the caller owns the clock)." <|
        [ demoRow "Precisions"
            [ Countdown.view theme { countdownD | distance = 90000, precision = 0 } []
            , Countdown.view theme { countdownD | distance = 90000, precision = 1 } []
            , Countdown.view theme { countdownD | distance = 90000, precision = 3 } []
            ]
        , demoRow "Custom render"
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


numberAnimationSection : Element msg
numberAnimationSection =
    section "Number Animation"
        "A tweened number (the clock is caller-owned — pass `elapsed`). No classes or variables of its own."
    <|
        [ demoRow "Grouped"
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
        , demoRow "Precision"
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


carouselSection : Element msg
carouselSection =
    let
        carouselD =
            Carousel.defaults

        img gradient =
            Html.img
                [ HA.attribute "style" ("display:block;width:100%;height:100%;object-fit:cover;background:" ++ gradient)
                , HA.src "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
                , HA.alt ""
                ]
                []

        carouselSlides =
            [ img "linear-gradient(135deg, #18a058, #63e2b7)"
            , img "linear-gradient(135deg, #2080f0, #70c0e8)"
            , img "linear-gradient(135deg, #f0a020, #fcd68a)"
            , img "linear-gradient(135deg, #d03050, #e88080)"
            ]

        demo : String -> Carousel.Size -> Carousel.Options msg -> Element msg
        demo id size opts =
            Element.el [ Element.width (Element.px (round size.width)) ]
                (Carousel.view theme
                    { opts | attributes = [ HA.id id ] }
                    (Carousel.resize opts size (Carousel.init opts 4))
                    carouselSlides
                )
    in
    section "Carousel"
        "A slide track over a caller-owned clock and measurement — autoplay, drag and resize are the caller's to own."
        [ demoRow "Basic (loop, 4 slides + clones)"
            [ demo "live-carousel" { width = 920, height = 360 } carouselD ]
        , demoRow "Vertical + dots right"
            [ demo "live-carousel-vertical"
                { width = 560, height = 280 }
                { carouselD | direction = Carousel.Vertical, dotPlacement = Carousel.DotsRight }
            ]
        , demoRow "Arrows + line dots"
            [ demo "live-carousel-arrows"
                { width = 920, height = 360 }
                { carouselD | showArrow = True, dotType = Carousel.Line }
            ]
        , demoRow "Loop off (previous arrow disabled)"
            [ demo "live-carousel-no-loop"
                { width = 920, height = 360 }
                { carouselD | loop = False, showArrow = True }
            ]
        , demoRow "slidesPerView 3 + spaceBetween 20"
            [ demo "live-carousel-slides-per-view"
                { width = 920, height = 360 }
                { carouselD
                    | slidesPerView = Carousel.PerView 3
                    , spaceBetween = 20
                    , loop = False
                    , showArrow = True
                }
            ]
        , demoRow "Fade"
            [ demo "live-carousel-fade"
                { width = 920, height = 360 }
                { carouselD | effect = Carousel.FadeEffect }
            ]
        , demoRow "Card (previous/next slide styles)"
            [ demo "live-carousel-card"
                { width = 920, height = 360 }
                { carouselD
                    | effect = Carousel.CardEffect
                    , showDots = False
                    , prevSlideStyle = Just "transform:translateX(-60%) scale(0.7)"
                    , nextSlideStyle = Just "transform:translateX(60%) scale(0.7)"
                }
            ]
        , demoRow "Custom (usercontrol) + renderDots"
            [ demo "live-carousel-custom"
                { width = 920, height = 360 }
                { carouselD
                    | effect = Carousel.CustomEffect
                    , renderDots =
                        Just
                            (\info ->
                                Element.text (String.fromInt (info.currentIndex + 1) ++ " / " ++ String.fromInt info.total)
                            )
                }
            ]
        , demoRow "defaultIndex 2 (seeded)"
            [ demo "live-carousel-default-index"
                { width = 920, height = 360 }
                { carouselD | defaultIndex = 2 }
            ]
        ]


logSection : Element msg
logSection =
    section "Log"
        "A scrolling log pane (Code + Scrollbar + loader) — scrolling, wheel and load events are the caller's to own."
        [ demoRow "Lines (fixed rows)"
            [ Element.el [ Element.width (Element.px 420) ]
                (Log.view theme
                    { logD
                        | lines = [ "2026-09-30 first entry", "second entry", "third entry" ]
                        , rows = 5
                    }
                )
            ]
        , demoRow "Highlighted + loading"
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
