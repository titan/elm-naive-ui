module NUI.Marquee exposing
    ( Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Marquee`, rebuilt on elm-ui.

    import NUI.Marquee exposing (defaults)

    NUI.Marquee.view theme
        { defaults | duration = 12 }
        [ Element.text "Scrolling text" ]

The element carries the `.n-marquee` BEM classes and the animation `--n-*`
custom properties, and `NUI.Css` ships Naive UI's exact CSS (including the
`n-marquee` keyframes).

**Runtime.** Upstream measures the content and container widths with a
`ResizeObserver` and derives the duration (and, with `auto-fill`, the repeat
count). This library is pure, so the caller owns those numbers: pass the scroll
`duration` in seconds directly, and — for `autoFill` — the `repeat` count
(`repeatCountInOneGroup`). The rendered DOM (two `__group`s, one item repeated)
is exactly upstream's.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)


type alias Options msg =
    { duration : Float
    , play : Bool
    , autoFill : Bool
    , repeat : Int
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { duration = 0
    , play = True
    , autoFill = False
    , repeat = 1
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ opts children =
    let
        original =
            item True children

        mirror =
            item False children

        ( groupOne, groupTwo ) =
            if opts.autoFill then
                ( original :: List.repeat (max 0 (opts.repeat - 1)) mirror
                , List.repeat (max 1 opts.repeat) mirror
                )

            else
                ( [ original ], [ mirror ] )
    in
    Element.row
        (I.classes
            ("n-marquee" :: I.classIf opts.autoFill "n-marquee--auto-fill")
            :: I.cssVars (cssVarsFor opts)
            :: opts.attributes
        )
        [ group groupOne, group groupTwo ]


group : List (Element msg) -> Element msg
group children =
    Element.row [ I.classes [ "n-marquee__group" ] ] children


{-| Naive UI's `__item` — the original (measured) item carries the extra
`__original-item` class, which upstream emits but no stylesheet rule targets.
-}
item : Bool -> List (Element msg) -> Element msg
item isOriginal children =
    Element.row
        [ I.classes
            ("n-marquee__item"
                :: I.classIf isOriginal "n-marquee__original-item"
            )
        ]
        children


{-| The animation custom properties upstream computes from its measurements —
here supplied directly by the caller (see the module note).
-}
cssVarsFor : Options msg -> List ( String, String )
cssVarsFor opts =
    [ ( "--n-play"
      , if opts.play then
            "running"

        else
            "paused"
      )
    , ( "--n-direction", "normal" )
    , ( "--n-duration", String.fromFloat opts.duration ++ "s" )
    , ( "--n-delay", "0s" )
    , ( "--n-iteration-count", "infinite" )
    , ( "--n-min-width", "auto" )
    ]
