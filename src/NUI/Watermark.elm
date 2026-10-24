module NUI.Watermark exposing (Options, TextAlign(..), containerStyle, defaults, tileDataUrl, view, watermarkStyle)

{-| Naive UI's `Watermark` (`n-watermark`) — the tiled text / image overlay,
rebuilt on elm-ui.

    import Element
    import NUI.Theme as Theme
    import NUI.Watermark exposing (defaults)

    NUI.Watermark.view Theme.default
        { defaults | content = Just "Naive UI" }
        [ Element.text "The watermarked content" ]

(Record updates bind `defaults` to a local first — see `NUI.Button`.)

DOM (`Watermark.tsx` render):

    div.n-watermark-container [--global-rotate] [--fullscreen] [--selectable]
      style = zIndex (iff global-rotate AND fullscreen)
      ├─ …children (the watermarked content)         — iff not the bare branch
      └─ div.n-watermark [--global-rotate] [--fullscreen]
           style = transform? zIndex? background-size
                   background-position? background-image

When `fullscreen` and no `globalRotate`, upstream returns the watermark node
BARE (no container, children dropped); the port does the same (`view`'s
children are ignored in that branch).

**The canvas seam.** Upstream draws the tile on a runtime `<canvas>`
(`fillText` / `drawImage` → `toDataURL`) and tiles it as a background image.
There is no canvas in pure Elm, so the port rebuilds the tile as an SVG and
base64-encodes it in-library (the `NUI.Qrcodegen` precedent — reimplementing
upstream's JS image math purely):

  - `content` — an SVG tile of exactly the canvas dimensions
    (`(xGap + width) × (yGap + height)`), one `<text>` per line with the
    upstream font stack / colour, inside the upstream `rotate` transform.
    Empty or absent `content` is upstream's third branch (`clearRect`) — a
    blank tile, so the overlay is present but invisible.
  - `image` — referenced directly: `url(<image>)` composed into the same
    `cross` doubling and the same `background-size` tiling. Upstream
    re-rasterises the image onto the tile canvas (applying `imageOpacity`,
    `imageWidth` / `imageHeight` scaling and the offsets); those three props
    are kept for API parity but the pure render cannot apply them — the
    display matches when the image's natural size fits the tile.

Divergences from upstream (documented): the MIME prefix is
`data:image/svg+xml` where the canvas emits `data:image/png`; the tile is
rendered at ratio 1 (upstream multiplies every canvas coordinate by
`devicePixelRatio` — identical display at ratio 1); `textAlign` `Center` /
`Right` anchor on the mark box (`xOffset` .. `xOffset + width`) where
upstream measures the text with `measureText` and anchors on the measured
box — identical when the longest line is exactly `width` wide, and `Left`
is exact; the `debug` rects are drawn in the SVG tile only (the image path
has no tile to draw on, and the grey outline is dropped on the empty tile
— upstream's `clearRect` wipes it); and the root sits inside a bare elm-ui wrapper
`div` carrying the caller `attributes` (the `NUI.Table` root shape), with
each child embedded through a `display: contents` wrapper (the
`NUI.Descriptions` seam — there is no public `Element` → `Html`).

Not ported: nothing else — `onFontsReady` re-rendering and the
`isBrowser` / `warnOnce` guards are runtime plumbing around the canvas.

@docs Options, TextAlign, containerStyle, defaults, tileDataUrl, view, watermarkStyle

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme as Theme
import NUI.Theme.Watermark as WatermarkTheme



-- OPTIONS ------------------------------------------------------------------------


{-| Upstream `textAlign` — `'left' | 'center' | 'right'`; anchors each line
inside the mark box (see the canvas-seam note above).
-}
type TextAlign
    = Left
    | Center
    | Right


{-| The watermark options (upstream `watermarkProps`): `selectable` defaults
`True`, sizes are pixels, `rotate` / `globalRotate` are degrees, and the
font props feed the tile's `<text>` (upstream: the canvas font string).
`imageOpacity` / `imageWidth` / `imageHeight` are API parity only — see the
canvas-seam note.
-}
type alias Options msg =
    { debug : Bool
    , cross : Bool
    , fullscreen : Bool
    , width : Int
    , height : Int
    , zIndex : Int
    , xGap : Int
    , yGap : Int
    , yOffset : Int
    , xOffset : Int
    , rotate : Float
    , textAlign : TextAlign
    , image : Maybe String
    , imageOpacity : Float
    , imageWidth : Maybe Int
    , imageHeight : Maybe Int
    , content : Maybe String
    , selectable : Bool
    , fontSize : Int
    , fontFamily : Maybe String
    , fontStyle : String
    , fontVariant : String
    , fontWeight : Int
    , fontColor : String
    , fontStretch : String
    , lineHeight : Int
    , globalRotate : Float
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`width` / `height` 32, `zIndex` 10, `fontSize` 16,
`fontWeight` 400, `rotate` 0, `lineHeight` 16 degrees of a default 32px tile,
selectable, not fullscreen, no cross, no debug, no content).
-}
defaults : Options msg
defaults =
    { debug = False
    , cross = False
    , fullscreen = False
    , width = 32
    , height = 32
    , zIndex = 10
    , xGap = 0
    , yGap = 0
    , yOffset = 0
    , xOffset = 0
    , rotate = 0
    , textAlign = Left
    , image = Nothing
    , imageOpacity = 1
    , imageWidth = Nothing
    , imageHeight = Nothing
    , content = Nothing
    , selectable = True
    , fontSize = 14
    , fontFamily = Nothing
    , fontStyle = "normal"
    , fontVariant = ""
    , fontWeight = 400
    , fontColor = "rgba(128, 128, 128, .3)"
    , fontStretch = ""
    , lineHeight = 14
    , globalRotate = 0
    , attributes = []
    }



-- VIEW ---------------------------------------------------------------------------


{-| The watermark — the container `div` wrapping the children plus the tiled
overlay `div` (or the overlay alone, when `fullscreen` without
`globalRotate` — upstream's bare return), inside the bare elm-ui wrapper
that carries the caller `attributes` (the `NUI.Table` root shape).
-}
view : Theme.Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.el
        opts.attributes
        (Element.html (rootNode theme opts children))


rootNode : Theme.Theme -> Options msg -> List (Element msg) -> Html.Html msg
rootNode theme opts children =
    if opts.fullscreen && opts.globalRotate == 0 then
        watermarkNode theme opts

    else
        Html.div
            (HA.class (String.join " " (containerClasses opts))
                :: styleAttrs (containerStyle opts)
            )
            (List.map embedChild children ++ [ watermarkNode theme opts ])


{-| The overlay itself — `div.n-watermark` with the two modifiers in
upstream's declaration order, carrying the transform / zIndex / background
set.
-}
watermarkNode : Theme.Theme -> Options msg -> Html.Html msg
watermarkNode theme opts =
    Html.div
        (HA.class (String.join " " (watermarkClasses opts))
            :: styleAttrs (watermarkStyle theme opts)
        )
        []


{-| `n-watermark` plus the global-rotate / fullscreen modifiers
(`Watermark.tsx` render's class array).
-}
watermarkClasses : Options msg -> List String
watermarkClasses opts =
    [ "n-watermark" ]
        ++ I.classIf (opts.globalRotate /= 0) "n-watermark--global-rotate"
        ++ I.classIf opts.fullscreen "n-watermark--fullscreen"


{-| `n-watermark-container` plus the global-rotate / fullscreen / selectable
modifiers (upstream's class array; `--selectable` rides the default-`True`
prop, and the stylesheet's `:not(.n-watermark-container--selectable)` rule
is what actually disables selection).
-}
containerClasses : Options msg -> List String
containerClasses opts =
    [ "n-watermark-container" ]
        ++ I.classIf (opts.globalRotate /= 0) "n-watermark-container--global-rotate"
        ++ I.classIf opts.fullscreen "n-watermark-container--fullscreen"
        ++ I.classIf opts.selectable "n-watermark-container--selectable"



-- INLINE STYLE -------------------------------------------------------------------


{-| The overlay's inline declarations in upstream's style-object order
(see the full note above).
-}
watermarkStyle : Theme.Theme -> Options msg -> List ( String, String )
watermarkStyle theme opts =
    (if opts.globalRotate /= 0 then
        [ ( "transform"
          , "translateX(-50%) translateY(-50%) rotate("
                ++ String.fromFloat opts.globalRotate
                ++ "deg)"
          )
        ]

     else
        []
    )
        ++ (if isFullScreenGlobalRotate opts then
                []

            else
                [ ( "z-index", String.fromInt opts.zIndex ) ]
           )
        ++ [ ( "background-size", String.fromInt (opts.xGap + opts.width) ++ "px" )
           , ( "background-position", backgroundPosition opts )
           , ( "background-image", backgroundImage theme opts )
           ]


{-| The container's inline declarations — just the `z-index` the fullscreen /
global-rotate branch needs (upstream moves it off the overlay there), empty
otherwise.
-}
containerStyle : Options msg -> List ( String, String )
containerStyle opts =
    if isFullScreenGlobalRotate opts then
        [ ( "z-index", String.fromInt opts.zIndex ) ]

    else
        []


isFullScreenGlobalRotate : Options msg -> Bool
isFullScreenGlobalRotate opts =
    opts.globalRotate /= 0 && opts.fullscreen


{-| Upstream `backgroundPosition` — the `cross` offset tiles at
`width/2 height/2, 0 0` (unrotated) or the
`calc(max(142vh, 142vw) + width/2 px) …, max(142vh, 142vw) …` pair under
global rotation (upstream's `rotatedImageOffset = 'max(142vh, 142vw)'`);
empty (dropped) when not `cross` and unrotated.
-}
backgroundPosition : Options msg -> String
backgroundPosition opts =
    if opts.globalRotate == 0 then
        if opts.cross then
            halfPx opts.width ++ "px " ++ halfPx opts.height ++ "px, 0 0"

        else
            ""

    else if opts.cross then
        "calc(max(142vh, 142vw) + "
            ++ halfPx opts.width
            ++ "px) calc(max(142vh, 142vw) + "
            ++ halfPx opts.height
            ++ "px), max(142vh, 142vw) max(142vh, 142vw)"

    else
        "max(142vh, 142vw)"


{-| Upstream `backgroundImage` — the tile URL, doubled when `cross`.
-}
backgroundImage : Theme.Theme -> Options msg -> String
backgroundImage theme opts =
    let
        url =
            case opts.image of
                Just src ->
                    "url(" ++ src ++ ")"

                Nothing ->
                    "url(" ++ tileDataUrl theme opts ++ ")"
    in
    if opts.cross then
        url ++ ", " ++ url

    else
        url


{-| `${n / 2}` with JavaScript's number formatting — `"16"` for 32,
`"2.5"` for 5.
-}
halfPx : Int -> String
halfPx n =
    if remainderBy 2 n == 0 then
        String.fromInt (n // 2)

    else
        String.fromFloat (toFloat n / 2)


styleAttrs : List ( String, String ) -> List (Html.Attribute msg)
styleAttrs pairs =
    if pairs == [] then
        []

    else
        [ HA.attribute "style" (I.renderVars pairs) ]


{-| There is no public `Element` → `Html`, so a caller's element is embedded
through `Element.layoutWith` (the `NUI.Descriptions` / `NUI.Table`
precedent). The wrapper carries `display: contents` plus `font` / `color:
inherit`; `noStaticStyleSheet` keeps elm-ui's static stylesheet from
re-clobbering the bridge.
-}
embedChild : Element msg -> Html.Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child



-- THE TILE ------------------------------------------------------------------------


{-| The tile as a `data:` URL — what upstream's `canvas.toDataURL()` stood
for: an SVG of the canvas dimensions, base64-encoded in-library. `content`
lines render as `<text>`; absent / empty content is the blank tile
(upstream's `clearRect` branch).
-}


{-| The tile as a `data:image/svg+xml;base64,…` URL — what upstream's
`canvas.toDataURL()` stood for; `view`'s overlay backgrounds itself with it.
-}
tileDataUrl : Theme.Theme -> Options msg -> String
tileDataUrl theme opts =
    "data:image/svg+xml;base64," ++ encodeBase64Utf8 (tileSvg theme opts)


tileSvg : Theme.Theme -> Options msg -> String
tileSvg theme opts =
    let
        debugRect stroke =
            "<rect x=\"0\" y=\"0\" width=\""
                ++ String.fromInt opts.width
                ++ "\" height=\""
                ++ String.fromInt opts.height
                ++ "\" fill=\"none\" stroke=\""
                ++ stroke
                ++ "\"/>"

        mark =
            case contentLines opts of
                [] ->
                    ""

                lines ->
                    (if opts.debug then
                        debugRect "green"

                     else
                        ""
                    )
                        ++ String.concat (List.indexedMap (textNode opts) lines)
    in
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\""
        ++ String.fromInt (opts.xGap + opts.width)
        ++ "\" height=\""
        ++ String.fromInt (opts.yGap + opts.height)
        ++ "\">"
        ++ (if opts.debug && mark /= "" then
                debugRect "grey"

            else
                ""
           )
        ++ "<g transform=\"rotate("
        ++ String.fromFloat opts.rotate
        ++ ")\""
        ++ fontAttrs theme opts
        ++ ">"
        ++ mark
        ++ "</g></svg>"


{-| Upstream's content split — `String.split "\\n"`; `Nothing` and `Just ""`
both render no text (upstream's falsy-`content` `clearRect` branch).
-}
contentLines : Options msg -> List String
contentLines opts =
    case opts.content of
        Nothing ->
            []

        Just text ->
            if String.isEmpty text then
                []

            else
                String.split "\n" text


{-| One line — upstream `fillText` at `canvasOffsetTop + lineHeight * (i +
1)` (alphabetic baseline, as SVG's default), anchored per `textAlign` on
the mark box (`xOffset` .. `xOffset + width` — see the module docstring's
canvas-seam note).
-}
textNode : Options msg -> Int -> String -> String
textNode opts index line =
    let
        ( anchorName, anchorX ) =
            case opts.textAlign of
                Left ->
                    ( "start", String.fromInt opts.xOffset )

                Center ->
                    -- upstream's measured-box centre lands at `width / 2` for
                    -- the widest line; emit the exact fraction on odd widths
                    -- (JS number formatting — `"2.5"`, not the floor `2`)
                    ( "middle"
                    , if remainderBy 2 opts.width == 0 then
                        String.fromInt (opts.xOffset + opts.width // 2)

                      else
                        String.fromFloat (toFloat opts.xOffset + toFloat opts.width / 2)
                    )

                Right ->
                    ( "end", String.fromInt (opts.xOffset + opts.width) )
    in
    "<text x=\""
        ++ anchorX
        ++ "\" y=\""
        ++ String.fromInt (opts.yOffset + opts.lineHeight * (index + 1))
        ++ "\" text-anchor=\""
        ++ anchorName
        ++ "\">"
        ++ escapeXml line
        ++ "</text>"


{-| The font stack — upstream's canvas `ctx.font` string
(`fontStyle fontVariant fontWeight fontStretch fontSize/lineHeight
fontFamily`) as SVG attributes; the `normal` / empty defaults are omitted
(no-ops on both sides; `font-weight` rides SVG's own 400 default), and
`fontFamily` falls back to the theme's single var on `Nothing` or the
empty string (upstream's `||` treats both as absent), as upstream's
`themeRef.value.self.fontFamily`.
-}
fontAttrs : Theme.Theme -> Options msg -> String
fontAttrs theme opts =
    let
        ifNot name value neutral =
            if value == neutral then
                ""

            else
                " " ++ name ++ "=\"" ++ escapeXml value ++ "\""
    in
    " font-family=\""
        ++ escapeXml
            (Maybe.withDefault (WatermarkTheme.vars theme).fontFamily
                (Maybe.andThen
                    (\f ->
                        if String.isEmpty f then
                            Nothing

                        else
                            Just f
                    )
                    opts.fontFamily
                )
            )
        ++ "\" font-size=\""
        ++ String.fromInt opts.fontSize
        ++ "\" fill=\""
        ++ escapeXml opts.fontColor
        ++ "\""
        ++ (if opts.fontWeight /= 400 then
                " font-weight=\"" ++ String.fromInt opts.fontWeight ++ "\""

            else
                ""
           )
        ++ ifNot "font-style" opts.fontStyle "normal"
        ++ ifNot "font-variant" opts.fontVariant ""
        ++ ifNot "font-stretch" opts.fontStretch ""


escapeXml : String -> String
escapeXml =
    String.replace "&" "&amp;"
        >> String.replace "<" "&lt;"
        >> String.replace ">" "&gt;"
        >> String.replace "\"" "&quot;"
        >> String.replace "'" "&apos;"



-- BASE64 --------------------------------------------------------------------------


{-| Base64 over the string's UTF-8 bytes (canvas tiles may carry any text —
the encoder goes through code points, so CJK content survives).
-}
encodeBase64Utf8 : String -> String
encodeBase64Utf8 =
    String.toList >> List.concatMap utf8Bytes >> encodeBase64Bytes


utf8Bytes : Char -> List Int
utf8Bytes c =
    let
        cp =
            Char.toCode c
    in
    if cp < 0x80 then
        [ cp ]

    else if cp < 0x0800 then
        [ 0xC0 + cp // 0x40, 0x80 + remainderBy 0x40 cp ]

    else if cp < 0x00010000 then
        [ 0xE0 + cp // 0x1000
        , 0x80 + remainderBy 0x40 (cp // 0x40)
        , 0x80 + remainderBy 0x40 cp
        ]

    else
        [ 0xF0 + cp // 0x00040000
        , 0x80 + remainderBy 0x40 (cp // 0x1000)
        , 0x80 + remainderBy 0x40 (cp // 0x40)
        , 0x80 + remainderBy 0x40 cp
        ]


encodeBase64Bytes : List Int -> String
encodeBase64Bytes bytes =
    case bytes of
        [] ->
            ""

        [ a ] ->
            String.fromList [ char64 (a // 4), char64 (remainderBy 4 a * 16), '=', '=' ]

        [ a, b ] ->
            String.fromList
                [ char64 (a // 4)
                , char64 (remainderBy 4 a * 16 + b // 16)
                , char64 (remainderBy 16 b * 4)
                , '='
                ]

        a :: b :: c :: rest ->
            String.fromList
                [ char64 (a // 4)
                , char64 (remainderBy 4 a * 16 + b // 16)
                , char64 (remainderBy 16 b * 4 + c // 64)
                , char64 (remainderBy 64 c)
                ]
                ++ encodeBase64Bytes rest


char64 : Int -> Char
char64 i =
    String.slice i (i + 1) "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        |> String.toList
        |> List.head
        |> Maybe.withDefault 'A'
