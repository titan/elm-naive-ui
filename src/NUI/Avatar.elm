module NUI.Avatar exposing (AvatarSize(..), Options, defaults, view)

{-| Naive UI's `Avatar`, rebuilt on elm-ui.

    import NUI.Avatar exposing (defaults)

    NUI.Avatar.view theme
        { defaults | src = Just "https://example.com/avatar.png" }
        []

    NUI.Avatar.view theme NUI.Avatar.defaults [ Element.text "N" ]

Text children are centered the way Naive UI's `fitTextTransform` does after its
initial measurement. Upstream then _scales_ oversized text down to fit the tile
(a runtime measurement we cannot take in a pure view), so this port instead lets
a text avatar grow to fit its label: the tile is `min-width` its configured size
and `width` its content, so `Rounded` renders on one line inside a slightly wider
tile rather than clipped edge-to-edge mid-glyph (short labels — `T`, `A`, `+3` —
stay exactly the configured square).

A `src` image renders as a CSS `background-image` tile rather than an `<img>`:
a failed load then falls back to the avatar's own colour tile (upstream's
`renderFallback` / `fallback-src` behaviour) instead of leaking the browser's
broken-image glyph. Loaded images look identical (stretched to fill, matching
upstream's `.n-avatar img { width/height: 100% }`).

@docs AvatarSize, Options, defaults, view

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Avatar as AvatarTheme


{-| Naive UI's avatar `size`: a preset name (including `huge`, which only Avatar
uses) or an explicit pixel number.
-}
type AvatarSize
    = Tiny
    | Small
    | Medium
    | Large
    | Huge
    | Number Int


{-| The avatar options. `size` keys the tile dimensions (and the round /
circle radius), `round` / `circle` both render `border-radius: 50%` (upstream
quirk), `bordered` adds `--n-border`, `color` overrides the theme tile colour,
`src` renders the image tile instead of text children, `attributes` land on
the `n-avatar` root.
-}
type alias Options msg =
    { size : AvatarSize
    , round : Bool
    , circle : Bool
    , bordered : Bool
    , color : Maybe String
    , src : Maybe String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults — medium square tile, no border, no image, themed
colour.
-}
defaults : Options msg
defaults =
    { size = Medium
    , round = False
    , circle = False
    , bordered = False
    , color = Nothing
    , src = Nothing
    , attributes = []
    }


{-| Render one avatar: the `n-avatar` root with the `--n-*` vars. Text children
land in `n-avatar__text`; a `src` renders the background-image tile; neither
is present when both are unset. See the module doc for the text-fit trade-off.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        v =
            AvatarTheme.vars theme

        isRound =
            opts.round || opts.circle

        height =
            heightOf opts.size v

        body =
            if not (List.isEmpty children) then
                [ Element.row
                    [ I.classes [ "n-avatar__text" ]
                    , Element.htmlAttribute (HA.style "position" "static")
                    , Element.htmlAttribute (HA.style "left" "auto")
                    , Element.htmlAttribute (HA.style "top" "auto")
                    , Element.htmlAttribute (HA.style "transform" "none")
                    , Element.htmlAttribute (HA.style "white-space" "nowrap")
                    ]
                    children
                ]

            else
                case opts.src of
                    Just src ->
                        [ Element.html <|
                            Html.div
                                [ HA.class "n-avatar__img"
                                , HA.attribute "style" (imageStyle src)
                                ]
                                []
                        ]

                    Nothing ->
                        []

        vars =
            [ ( "--n-font-size", v.fontSize )
            , ( "--n-border"
              , if opts.bordered then
                    v.border

                else
                    "none"
              )
            , ( "--n-border-radius"
              , if isRound then
                    "50%"

                else
                    v.borderRadius
              )
            , ( "--n-color", Maybe.withDefault v.color opts.color )
            , ( "--n-color-modal", Maybe.withDefault v.colorModal opts.color )
            , ( "--n-color-popover", Maybe.withDefault v.colorPopover opts.color )
            , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
            , ( "--n-merged-size", "var(--n-avatar-size-override, " ++ height ++ ")" )

            -- Upstream keeps the avatar a fixed square and scales the text down
            -- (a runtime measurement). Without that measurement, let a text
            -- avatar grow to fit instead: `width` its content, `min-width` the
            -- configured size, both children centred. A short label therefore
            -- stays the exact square; a longer one widens rather than clipping.
            , ( "width", "max-content" )
            , ( "min-width", "var(--n-merged-size)" )
            , ( "justify-content", "center" )
            , ( "align-items", "center" )
            ]
    in
    Element.row
        ([ I.classes [ "n-avatar" ]
         , I.cssVars vars
         ]
            ++ opts.attributes
        )
        body


heightOf : AvatarSize -> AvatarTheme.Vars -> String
heightOf size v =
    case size of
        Tiny ->
            v.heightTiny

        Small ->
            v.heightSmall

        Medium ->
            v.heightMedium

        Large ->
            v.heightLarge

        Huge ->
            v.heightHuge

        Number n ->
            String.fromInt n ++ "px"


{-| A `src` image as a CSS background tile: on a failed load nothing paints but
the avatar's own `--n-merged-color` (upstream's fallback), rather than the
broken-image glyph an empty `<img>` would leak. `background-size: 100% 100%`
reproduces upstream's `.n-avatar img { width: 100%; height: 100% }` (the default
stretch fit).
-}
imageStyle : String -> String
imageStyle src =
    "width:100%;height:100%;background-image:url(\""
        ++ src
        ++ "\");background-size:100% 100%;background-position:center;background-repeat:no-repeat"
