module NUI.Skeleton exposing
    ( Length(..)
    , Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Skeleton`, rebuilt on elm-ui.

    NUI.Skeleton.view theme NUI.Skeleton.defaults []

    -- three shimmering text lines
    NUI.Skeleton.view theme
        { opts
            | text = True
            , width = Just (NUI.Skeleton.Px 120)
            , repeat = 3
        }
        []

    -- a round avatar placeholder
    NUI.Skeleton.view theme
        { opts | circle = True, width = Just (NUI.Skeleton.Px 40) }
        []

(`defaults` must be bound to a local first — Elm's record update syntax does
not accept a qualified `NUI.Skeleton.defaults` there.)

The visual result is Naive UI's own: the element carries the `.n-skeleton`
class and one inline `style` attribute holding both the plain properties
`Skeleton.tsx` computes (`display`, `vertical-align`, `border-radius`,
`width`, `height`, `animation`) and the `--n-*` custom properties. `NUI.Css`
ships Naive UI's exact CSS, including the `skeleton-loading` keyframes.

Naive UI's `Skeleton` renders an empty placeholder div and has no slot, so
the `List (Element msg)` parameter exists only to keep the uniform NUI
component API — children are not rendered.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Skeleton as SkeletonTheme
import NUI.Types exposing (Size(..))


{-| A CSS length — Naive UI's `string | number` `height` / `width` prop.
`Px 40` renders as `40px` (seemly's `pxfy` on a number); `Custom "2em"` /
`Custom "50%"` passes an arbitrary CSS length string through unchanged.
-}
type Length
    = Px Int
    | Custom String


type alias Options msg =
    { text : Bool
    , round : Bool
    , circle : Bool
    , height : Maybe Length
    , width : Maybe Length
    , size : Maybe Size
    , repeat : Int
    , animated : Bool
    , sharp : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { text = False
    , round = False
    , circle = False
    , height = Nothing
    , width = Nothing
    , size = Nothing
    , repeat = 1
    , animated = True
    , sharp = True
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts _ =
    let
        copy =
            Element.el
                ([ I.classes [ "n-skeleton" ]
                 , I.cssVars (cssVarsFor theme opts)
                 ]
                    ++ opts.attributes
                )
                Element.none
    in
    if opts.repeat > 1 then
        repeatWrapper (List.concatMap (always [ copy, newline ]) (List.range 1 opts.repeat))

    else
        copy


{-| With `repeat > 1`, Naive UI returns a fragment of `[child, '\n', …]`, so
the copies are laid out by the _parent_. An Elm view must return one element,
so they are wrapped in a `display: contents` div — a box that generates
nothing, leaving the children to behave exactly like fragment siblings (this
is what keeps repeated `text` skeletons flowing inline, separated by the
newline text nodes).
-}
repeatWrapper : List (Element msg) -> Element msg
repeatWrapper children =
    Element.row
        [ Element.htmlAttribute (HA.style "display" "contents") ]
        children


{-| The `'\n'` text node Naive UI places after every repeated skeleton.
Rendered as an HTML text node — `Element.text` would wrap it in a div — it
collapses to the word space that separates inline-block text skeletons.
-}
newline : Element msg
newline =
    Element.html (Html.text "\n")


{-| The entries of the single inline `style` attribute for these options:
the plain properties from `Skeleton.tsx`'s computed style plus the `--n-*`
custom properties, in upstream order. `view` renders exactly this list
through `NUI.Internal.cssVars`, which drops the empty "unset" entries
(`display: ''` and friends) the way Vue drops empty style values.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            SkeletonTheme.vars theme

        sizeHeight =
            Maybe.andThen (\size -> sizeHeightOf size v) opts.size

        width =
            Maybe.map lengthToString opts.width

        height =
            Maybe.map lengthToString opts.height

        mergedWidth =
            if opts.circle then
                firstJust [ width, height, sizeHeight ]

            else
                width

        mergedHeight =
            firstJust
                [ if opts.circle then
                    firstJust [ width, height ]

                  else
                    height
                , sizeHeight
                ]
    in
    [ ( "display"
      , if opts.text then
            "inline-block"

        else
            ""
      )
    , ( "vertical-align"
      , if opts.text then
            "-0.125em"

        else
            ""
      )
    , ( "border-radius"
      , if opts.circle then
            "50%"

        else if opts.round then
            "4096px"

        else if opts.sharp then
            ""

        else
            v.borderRadius
      )
    , ( "width", Maybe.withDefault "" mergedWidth )
    , ( "height", Maybe.withDefault "" mergedHeight )
    , ( "animation"
      , if opts.animated then
            ""

        else
            "none"
      )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-color-start", v.color )
    , ( "--n-color-end", v.colorEnd )
    ]


firstJust : List (Maybe a) -> Maybe a
firstJust maybes =
    maybes
        |> List.filterMap identity
        |> List.head


lengthToString : Length -> String
lengthToString length =
    case length of
        Px n ->
            String.fromInt n ++ "px"

        Custom string ->
            string


{-| Naive UI's `createKey('height', size)` lookup into the Skeleton theme.
Upstream's `SkeletonSize` only allows `small | medium | large`; `Tiny` finds
no `heightTiny` variable there either (the runtime lookup misses), so it
maps to nothing — width and height then fall back to the `.n-skeleton` CSS.
-}
sizeHeightOf : Size -> SkeletonTheme.Vars -> Maybe String
sizeHeightOf size v =
    case size of
        Small ->
            Just v.heightSmall

        Medium ->
            Just v.heightMedium

        Large ->
            Just v.heightLarge

        Tiny ->
            Nothing
