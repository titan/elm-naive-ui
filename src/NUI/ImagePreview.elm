module NUI.ImagePreview exposing
    ( HorizontalDirection(..)
    , KeyAction(..)
    , MoveStrategy
    , Options
    , Rect
    , VerticalDirection(..)
    , Viewport
    , Zoom
    , cssVars
    , defaults
    , derivedOffset
    , keyAction
    , maxScale
    , moveStrategy
    , originalSizeScale
    , resizeToOriginalSize
    , rotateClockwise
    , rotateCounterclockwise
    , switchReset
    , toggleOriginalSize
    , toolbarButtons
    , transformStyle
    , view
    , zoom0
    , zoomIn
    , zoomOut
    )

{-| Naive UI's `ImagePreview` (the `n-image` modal), rebuilt on elm-ui.

    import NUI.ImagePreview as ImagePreview

    ImagePreview.view theme
        { ImagePreview.defaults
            | show = True
            , src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
            , zoom = ImagePreview.zoom0
            , onClose = Just Closed
        }

The element is the `.n-image-preview-container` overlay tree: container
(the five `--n-*` preview vars), `.n-image-preview-overlay` (click-to-close
seam), `.n-image-preview-toolbar` (prev/next when `onPrev` is set — upstream
keys both on `onPrev` alone — then rotateCCW, rotateCW, original size,
zoomOut, zoomIn, download, close, each an `i.n-base-icon`), and
`.n-image-preview-wrapper` holding `img.n-image-preview`. `NUI.Css` ships
Naive UI's exact CSS (the whole preview family came with the image batch).

The runtime is caller-owned (Modal/Slider precedent):

  - **Mounting.** No teleport — mount `view` wherever you like and unmount
    when fully closed (`displayDirective: 'if'` semantics). While a leave
    phase runs, keep it mounted: pass the phase through
    `overlayTransition` / `toolbarTransition` (`fade-in-transition`) or
    `wrapperTransition` (`fade-in-scale-up-transition`) and the matching
    node stays rendered with its phase class.
  - **Zoom / drag state.** `zoom` is the whole upstream vector
    (`scale`/`scaleExp`/`offsetX`/`offsetY`/`rotate`, init `zoom0`). The
    transforms are exported pure: `zoomIn` / `zoomOut` /
    `resizeToOriginalSize` / `toggleOriginalSize` (dblclick — does NOT touch
    `scaleExp`, upstream bytes) / `rotateCounterclockwise` /
    `rotateClockwise` / `switchReset` (prev/next switch: scale 1, exp 0,
    offsets 0, rotate 0). `maxScale` / `originalSizeScale` take the img
    natural size plus the viewport (`BLEEDING = 32` lives inside).
    `zoomOut`'s upstream dance (measure the rect at the new scale, clamp
    offsets, restore) is the caller's two-step: apply `zoomOut`,
    re-measure, then `derivedOffset` + write `zoom.offsetX/Y`.
  - **The img style.** Upstream rewrites `style.cssText` wholesale
    (`derivePreviewStyle`); `transformStyle` is the exact transform
    fragment (raw floats — `String.fromFloat` ≡ `String(number)`) and the
    view renders `cursor: grab`/`grabbing` around it in upstream order
    (dragging: `transition: none` BEFORE the transform, else AFTER, and
    only when the transition is suppressed). `previewedImgStyle` is the
    controlled prefix (upstream `previewedImgProps.style`); pass keys
    already kebab-cased.
  - **Drag.** `moveStrategy` + `derivedOffset` port `getMoveStrategy` /
    `getDerivedOffset` (the viewport clamp); bind `onImgMousedown` and run
    them in your update. `keepDragOffset` is simply "skip the `derivedOffset`
    application on mouseup".
  - **Keyboard.** Upstream binds `keydown` on `document`; bind it in your
    own runtime and feed `keyAction` (Space → preventDefault only, ←/→ →
    prev/next, ↑/↓ → zoom in/out, Escape → close).
  - **`syncTransformOrigin`.** Measure the thumbnail's bounding-rect center
    and write it into `wrapperStyle` as `("transform-origin",
    "<tx>px <ty>px")` on enter/before-leave.
  - **Wheel.** Upstream only `preventDefault`s on the container — attach it
    yourself via `attributes` (`Html.Events.custom "wheel"` with
    `preventDefault = True`).

Accepted edges (documented divergences):

  - Toolbar tooltips (`showToolbarTooltip`) are not wired: upstream wraps
    each icon in a renderless Binder, so the closed-state DOM is identical;
    the open tooltip body is the caller's `NUI.Tooltip` seam.
  - `renderToolbar` is not modelled; `toolbarButtons` exposes the exact
    default node list so a caller can recompose it.
  - The download button renders; the browser download itself is the
    caller's msg (upstream `_utils` `download`).
  - `zindexable` is the caller's `attributes` seam — upstream's directive
    writes an inline `z-index` while shown; put the rule (or a style
    override) on the container yourself.
  - Vue's `key={previewSrc}` (img node re-created on src change) is not
    modelled; Elm re-renders the attribute.
  - The container in group mode is identical (`NUI.ImageGroup` composes
    this view); `previewedImgProps` only flow in standalone mode upstream
    (group's preview gets no `imageContext`) — the group passes none.

Note: record updates bind `defaults` to a local first, then patch fields.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as Events
import Json.Decode as Decode
import NUI.Image as Image
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import Svg



-- OPTIONS


type alias Options msg =
    { show : Bool
    , src : Maybe String
    , showToolbar : Bool
    , zoom : Zoom
    , dragging : Bool
    , imgTransition : Bool
    , overlayTransition : Maybe I.TransitionPhase
    , toolbarTransition : Maybe I.TransitionPhase
    , wrapperTransition : Maybe I.TransitionPhase
    , wrapperStyle : List ( String, String )
    , onPrev : Maybe msg
    , onNext : Maybe msg
    , onClose : Maybe msg
    , onRotateCounterclockwise : Maybe msg
    , onRotateClockwise : Maybe msg
    , onOriginalSize : Maybe msg
    , onZoomOut : Maybe msg
    , onZoomIn : Maybe msg
    , onDownload : Maybe msg
    , onImgMousedown : Maybe msg
    , onImgDblclick : Maybe msg
    , onImgDragstart : Maybe msg
    , previewedImgClass : Maybe String
    , previewedImgStyle : List ( String, String )
    , previewedImgAttributes : List (Html.Attribute msg)
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { show = False
    , src = Nothing
    , showToolbar = True
    , zoom = zoom0
    , dragging = False
    , imgTransition = True
    , overlayTransition = Nothing
    , toolbarTransition = Nothing
    , wrapperTransition = Nothing
    , wrapperStyle = []
    , onPrev = Nothing
    , onNext = Nothing
    , onClose = Nothing
    , onRotateCounterclockwise = Nothing
    , onRotateClockwise = Nothing
    , onOriginalSize = Nothing
    , onZoomOut = Nothing
    , onZoomIn = Nothing
    , onDownload = Nothing
    , onImgMousedown = Nothing
    , onImgDblclick = Nothing
    , onImgDragstart = Nothing
    , previewedImgClass = Nothing
    , previewedImgStyle = []
    , previewedImgAttributes = []
    , attributes = []
    }



-- ZOOM STATE (pure upstream math)


{-| The zoom/pan/rotate vector: `scaleExp` is the exponent over
`scaleRadix = 1.5` (`scale = 1.5 ^ scaleExp`, clamped), `rotate` is in
degrees. `zoom0` is upstream's init (`scale = 1`, `scaleExp = 0`, no offset,
no rotation).
-}
type alias Zoom =
    { scale : Float
    , scaleExp : Int
    , offsetX : Float
    , offsetY : Float
    , rotate : Float
    }


zoom0 : Zoom
zoom0 =
    { scale = 1
    , scaleExp = 0
    , offsetX = 0
    , offsetY = 0
    , rotate = 0
    }


{-| Upstream's module constant (`ImagePreview.tsx`, `BLEEDING = 32`).
-}
bleeding : Float
bleeding =
    32


{-| Upstream's `scaleRadix` (1.5) — exposed because `resizeToOriginalSize`
documents its logarithm.
-}
scaleRadix : Float
scaleRadix =
    1.5


{-| Inputs shared by `maxScale` and `originalSizeScale`: the preview img's
natural size and `window.innerWidth`/`innerHeight`.
-}
type alias ImageMetrics =
    { naturalWidth : Float
    , naturalHeight : Float
    , innerWidth : Float
    , innerHeight : Float
    }


{-| `Math.max(3, heightMaxScale * 2, widthMaxScale * 2)` where each
maxScale is `Math.max(1, natural / (inner - 32))`.
-}
maxScale : ImageMetrics -> Float
maxScale m =
    let
        heightMaxScale =
            max 1 (m.naturalHeight / (m.innerHeight - bleeding))

        widthMaxScale =
            max 1 (m.naturalWidth / (m.innerWidth - bleeding))
    in
    max 3 (max (heightMaxScale * 2) (widthMaxScale * 2))


{-| `getOrignalImageSizeScale` (sic): 1 when the image fits, else the larger
overshoot ratio.
-}
originalSizeScale : ImageMetrics -> Float
originalSizeScale m =
    let
        heightScale =
            m.naturalHeight / (m.innerHeight - bleeding)

        widthScale =
            m.naturalWidth / (m.innerWidth - bleeding)
    in
    if heightScale < 1 && widthScale < 1 then
        1

    else
        max heightScale widthScale


{-| Zoom in: guarded by `scale < maxScale`; `scaleExp += 1` then
`scale = min maxScale (1.5 ^ scaleExp)`.
-}
zoomIn : Float -> Zoom -> Zoom
zoomIn maxScale_ z =
    if z.scale < maxScale_ then
        { z
            | scaleExp = z.scaleExp + 1
            , scale = min maxScale_ (scaleRadix ^ toFloat (z.scaleExp + 1))
        }

    else
        z


{-| Zoom out's scale step: guarded by `scale > 0.5`; `scaleExp -= 1` then
`scale = max 0.5 (1.5 ^ scaleExp)`. The viewport-clamp of the offsets is the
caller's follow-up (`derivedOffset`), matching upstream's measure-at-new-scale
dance.
-}
zoomOut : Zoom -> Zoom
zoomOut z =
    if z.scale > 0.5 then
        { z
            | scaleExp = z.scaleExp - 1
            , scale = max 0.5 (scaleRadix ^ toFloat (z.scaleExp - 1))
        }

    else
        z


{-| `resizeToOrignalImageSize` (sic): scale to `originalSizeScale`,
`scaleExp = ceil(ln scale / ln 1.5)`, offsets zeroed.
-}
resizeToOriginalSize : Float -> Zoom -> Zoom
resizeToOriginalSize target z =
    { z
        | scale = target
        , scaleExp = ceiling (logBase scaleRadix target)
        , offsetX = 0
        , offsetY = 0
    }


{-| Dblclick toggle: `scale === originalSizeScale ? 1 : originalSizeScale`
— `scaleExp` deliberately untouched (upstream bytes).
-}
toggleOriginalSize : Float -> Zoom -> Zoom
toggleOriginalSize target z =
    { z
        | scale =
            if z.scale == target then
                1

            else
                target
    }


rotateCounterclockwise : Zoom -> Zoom
rotateCounterclockwise z =
    { z | rotate = z.rotate - 90 }


rotateClockwise : Zoom -> Zoom
rotateClockwise z =
    { z | rotate = z.rotate + 90 }


{-| The prev/next switch reset (`handleSwitchPrev/Next` before their `onPrev`
/ `onNext` fire): scale 1, exp 0, offsets 0, rotate 0.
-}
switchReset : Zoom -> Zoom
switchReset _ =
    zoom0


{-| The transform fragment of `derivePreviewStyle`, with raw floats exactly
as upstream emits them (`String.fromFloat` ≡ JS `String(number)`):

    transform-origin: center; transform: translateX(Xpx) translateY(Ypx) rotate(Rdeg) scale(S);

-}
transformStyle : Zoom -> List ( String, String )
transformStyle z =
    [ ( "transform-origin", "center" )
    , ( "transform"
      , "translateX("
            ++ String.fromFloat z.offsetX
            ++ "px) translateY("
            ++ String.fromFloat z.offsetY
            ++ "px) rotate("
            ++ String.fromFloat z.rotate
            ++ "deg) scale("
            ++ String.fromFloat z.scale
            ++ ")"
      )
    ]


{-| The full `style` pack `derivePreviewStyle` writes onto the preview img,
split into declarations in upstream order:

  - the controlled prefix (`previewedImgStyle`) first,
  - `cursor: grabbing; transition: none;` then the transform while dragging,
  - else `cursor: grab;` transform, and `transition: none` appended only
    when the transition is suppressed (the non-animated intermediate writes).

-}
imgStyle :
    { dragging : Bool
    , transition : Bool
    , controlled : List ( String, String )
    , zoom : Zoom
    }
    -> List ( String, String )
imgStyle cfg =
    if cfg.dragging then
        cfg.controlled
            ++ [ ( "cursor", "grabbing" ), ( "transition", "none" ) ]
            ++ transformStyle cfg.zoom

    else
        cfg.controlled
            ++ [ ( "cursor", "grab" ) ]
            ++ transformStyle cfg.zoom
            ++ (if cfg.transition then
                    []

                else
                    [ ( "transition", "none" ) ]
               )



-- DRAG MATH (pure upstream port)


{-| `getBoundingClientRect` fields the offset clamp reads.
-}
type alias Rect =
    { left : Float
    , top : Float
    , width : Float
    , height : Float
    , right : Float
    , bottom : Float
    }


type alias Viewport =
    { width : Float
    , height : Float
    }


type HorizontalDirection
    = HorizontalLeft
    | HorizontalRight


type VerticalDirection
    = VerticalTop
    | VerticalBottom


{-| `getMoveStrategy`'s output: drag deltas plus the directions their signs
imply.
-}
type alias MoveStrategy =
    { deltaHorizontal : Float
    , deltaVertical : Float
    , horizontal : HorizontalDirection
    , vertical : VerticalDirection
    }


{-| `getMoveStrategy`: `delta = mouseDown - mouseUp`; positive → Left/Top.
-}
moveStrategy :
    { mouseDownClientX : Float
    , mouseDownClientY : Float
    , mouseUpClientX : Float
    , mouseUpClientY : Float
    }
    -> MoveStrategy
moveStrategy o =
    let
        deltaHorizontal =
            o.mouseDownClientX - o.mouseUpClientX

        deltaVertical =
            o.mouseDownClientY - o.mouseUpClientY
    in
    { deltaHorizontal = deltaHorizontal
    , deltaVertical = deltaVertical
    , horizontal =
        if deltaHorizontal > 0 then
            HorizontalLeft

        else
            HorizontalRight
    , vertical =
        if deltaVertical > 0 then
            VerticalTop

        else
            VerticalBottom
    }


{-| `getDerivedOffset` — "avoid image move outside viewport". Without a
strategy (the zoom-out clamp call) the fallback branch reads `max(-half,
start)`/`max(-half, start)` on each axis, matching upstream's undefined
destructure.
-}
derivedOffset :
    Maybe MoveStrategy
    ->
        { rect : Rect
        , viewport : Viewport
        , start : { offsetX : Float, offsetY : Float }
        }
    -> { offsetX : Float, offsetY : Float }
derivedOffset maybeStrategy o =
    let
        halfW =
            (o.rect.width - o.viewport.width) / 2

        halfH =
            (o.rect.height - o.viewport.height) / 2

        strategyDeltaX =
            case maybeStrategy of
                Just s ->
                    s.deltaHorizontal

                Nothing ->
                    0

        strategyDeltaY =
            case maybeStrategy of
                Just s ->
                    s.deltaVertical

                Nothing ->
                    0

        nextOffsetX =
            if o.rect.width <= o.viewport.width then
                0

            else if o.rect.left > 0 then
                halfW

            else if o.rect.right < o.viewport.width then
                -halfW

            else
                case maybeStrategy of
                    Just s ->
                        if s.horizontal == HorizontalRight then
                            min halfW (o.start.offsetX - strategyDeltaX)

                        else
                            max -halfW (o.start.offsetX - strategyDeltaX)

                    Nothing ->
                        max -halfW o.start.offsetX

        nextOffsetY =
            if o.rect.height <= o.viewport.height then
                0

            else if o.rect.top > 0 then
                halfH

            else if o.rect.bottom < o.viewport.height then
                -halfH

            else
                case maybeStrategy of
                    Just s ->
                        if s.vertical == VerticalBottom then
                            min halfH (o.start.offsetY - strategyDeltaY)

                        else
                            max -halfH (o.start.offsetY - strategyDeltaY)

                    Nothing ->
                        max -halfH o.start.offsetY
    in
    { offsetX = nextOffsetX
    , offsetY = nextOffsetY
    }



-- KEYBOARD


{-| The `document` keydown mapping (`handleKeydown`): Space only
`preventDefault`s; ←/→ fire prev/next without preventing; ↑/↓ prevent and
zoom; Escape closes.
-}
type KeyAction
    = SpacePrevent
    | Prev
    | Next
    | ZoomInKey
    | ZoomOutKey
    | Close


keyAction : String -> Maybe KeyAction
keyAction key =
    case key of
        " " ->
            Just SpacePrevent

        "ArrowLeft" ->
            Just Prev

        "ArrowRight" ->
            Just Next

        "ArrowUp" ->
            Just ZoomInKey

        "ArrowDown" ->
            Just ZoomOutKey

        "Escape" ->
            Just Close

        _ ->
            Nothing



-- THEME VARS


{-| The five `--n-*` preview-container vars (ImagePreview.tsx
`cssVarsRef`), identical entry-for-entry to the image batch's emission —
delegated to `NUI.Image.cssVars`.
-}
cssVars : Theme -> List ( String, String )
cssVars theme =
    Image.cssVars theme



-- VIEW


{-| The overlay tree: container > (overlay? toolbar? wrapper). Mount it
while `show` or any leave phase runs; unmount once fully closed.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.row
        ([ I.classes [ "n-image-preview-container" ]
         , I.cssVars (cssVars theme)
         ]
            ++ opts.attributes
        )
        (overlayEl opts
            ++ toolbarEl opts
            ++ wrapperEl opts
        )


overlayEl : Options msg -> List (Element msg)
overlayEl opts =
    if opts.show || leaving opts.overlayTransition then
        [ Element.el
            [ I.classes
                ("n-image-preview-overlay"
                    :: phaseClasses "fade-in-transition" opts.overlayTransition
                )
            ]
            Element.none
        ]

    else
        []


toolbarEl : Options msg -> List (Element msg)
toolbarEl opts =
    if opts.showToolbar && (opts.show || leaving opts.toolbarTransition) then
        [ Element.row
            [ I.classes
                ("n-image-preview-toolbar"
                    :: phaseClasses "fade-in-transition" opts.toolbarTransition
                )
            ]
            (toolbarButtons opts)
        ]

    else
        []


{-| The default toolbar node list, in upstream order — prev+next when (and
only when) `onPrev` is set, then rotateCCW, rotateCW, original size, zoomOut,
zoomIn, download, close. Exposed for `renderToolbar`-style recomposition.
-}
toolbarButtons : Options msg -> List (Element msg)
toolbarButtons opts =
    let
        icon msg svg =
            Element.html
                (Html.i
                    ([ HA.class "n-base-icon" ]
                        ++ (case msg of
                                Just m ->
                                    [ Events.onClick m ]

                                Nothing ->
                                    []
                           )
                    )
                    [ svg ]
                )

        prevNext =
            case opts.onPrev of
                Just _ ->
                    [ icon opts.onPrev prevIconSvg
                    , icon opts.onNext nextIconSvg
                    ]

                Nothing ->
                    []
    in
    prevNext
        ++ [ icon opts.onRotateCounterclockwise rotateCounterclockwiseSvg
           , icon opts.onRotateClockwise rotateClockwiseSvg
           , icon opts.onOriginalSize resizeSmallSvg
           , icon opts.onZoomOut zoomOutSvg
           , icon opts.onZoomIn zoomInSvg
           , icon opts.onDownload downloadSvg
           , icon opts.onClose closeIconSvg
           ]


{-| The wrapper (`vShow` seat of the upstream transition) and the preview
img.
-}
wrapperEl : Options msg -> List (Element msg)
wrapperEl opts =
    [ Element.el
        ([ I.classes
            ("n-image-preview-wrapper"
                :: phaseClasses
                    "fade-in-scale-up-transition"
                    opts.wrapperTransition
            )
         ]
            ++ List.map
                (\( k, v ) -> Element.htmlAttribute (HA.style k v))
                opts.wrapperStyle
        )
        (Element.html (previewImg opts))
    ]


previewImg : Options msg -> Html.Html msg
previewImg opts =
    Html.img
        (opts.previewedImgAttributes
            ++ [ HA.attribute "draggable" "false" ]
            ++ eventAttr "mousedown" opts.onImgMousedown
            ++ eventAttr "dblclick" opts.onImgDblclick
            ++ [ HA.class
                    (String.join " "
                        ("n-image-preview"
                            :: (case opts.previewedImgClass of
                                    Just c ->
                                        [ c ]

                                    Nothing ->
                                        []
                               )
                        )
                    )
               ]
            ++ (case opts.src of
                    Just s ->
                        [ HA.src s ]

                    Nothing ->
                        []
               )
            ++ List.map (\( k, v ) -> HA.style k v)
                (imgStyle
                    { dragging = opts.dragging
                    , transition = opts.imgTransition
                    , controlled = opts.previewedImgStyle
                    , zoom = opts.zoom
                    }
                )
            ++ eventAttr "dragstart" opts.onImgDragstart
        )
        []


eventAttr : String -> Maybe msg -> List (Html.Attribute msg)
eventAttr name maybeMsg =
    case maybeMsg of
        Just m ->
            [ Events.on name (Decode.succeed m) ]

        Nothing ->
            []


phaseClasses : String -> Maybe I.TransitionPhase -> List String
phaseClasses family maybePhase =
    case maybePhase of
        Just phase ->
            [ I.transitionClass family phase ]

        Nothing ->
            []


leaving : Maybe I.TransitionPhase -> Bool
leaving maybePhase =
    case maybePhase of
        Just phase ->
            I.isLeavePhase phase

        Nothing ->
            False



-- ICONS (upstream bytes; prev/next/close from `src/image/src/icons.tsx`,
-- the rest from `_internal/icons`)


prevIconSvg : Html.Html msg
prevIconSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M6 5C5.75454 5 5.55039 5.17688 5.50806 5.41012L5.5 5.5V14.5C5.5 14.7761 5.72386 15 6 15C6.24546 15 6.44961 14.8231 6.49194 14.5899L6.5 14.5V5.5C6.5 5.22386 6.27614 5 6 5ZM13.8536 5.14645C13.68 4.97288 13.4106 4.9536 13.2157 5.08859L13.1464 5.14645L8.64645 9.64645C8.47288 9.82001 8.4536 10.0894 8.58859 10.2843L8.64645 10.3536L13.1464 14.8536C13.3417 15.0488 13.6583 15.0488 13.8536 14.8536C14.0271 14.68 14.0464 14.4106 13.9114 14.2157L13.8536 14.1464L9.70711 10L13.8536 5.85355C14.0488 5.65829 14.0488 5.34171 13.8536 5.14645Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


nextIconSvg : Html.Html msg
nextIconSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M13.5 5C13.7455 5 13.9496 5.17688 13.9919 5.41012L14 5.5V14.5C14 14.7761 13.7761 15 13.5 15C13.2545 15 13.0504 14.8231 13.0081 14.5899L13 14.5V5.5C13 5.22386 13.2239 5 13.5 5ZM5.64645 5.14645C5.82001 4.97288 6.08944 4.9536 6.28431 5.08859L6.35355 5.14645L10.8536 9.64645C11.0271 9.82001 11.0464 10.0894 10.9114 10.2843L10.8536 10.3536L6.35355 14.8536C6.15829 15.0488 5.84171 15.0488 5.64645 14.8536C5.47288 14.68 5.4536 14.4106 5.58859 14.2157L5.64645 14.1464L9.79289 10L5.64645 5.85355C5.45118 5.65829 5.45118 5.34171 5.64645 5.14645Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


closeIconSvg : Html.Html msg
closeIconSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M4.089 4.216l.057-.07a.5.5 0 0 1 .638-.057l.07.057L10 9.293l5.146-5.147a.5.5 0 0 1 .638-.057l.07.057a.5.5 0 0 1 .057.638l-.057.07L10.707 10l5.147 5.146a.5.5 0 0 1 .057.638l-.057.07a.5.5 0 0 1-.638.057l-.07-.057L10 10.707l-5.146 5.147a.5.5 0 0 1-.638.057l-.07-.057a.5.5 0 0 1-.057-.638l.057-.07L9.293 10L4.146 4.854a.5.5 0 0 1-.057-.638l.057-.07l-.057.07z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


rotateCounterclockwiseSvg : Html.Html msg
rotateCounterclockwiseSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M17 10C17 6.13401 13.866 3 10 3C6.13401 3 3 6.13401 3 10C3 12.7916 4.63419 15.2026 7 16.3265V14.5C7 14.2239 7.22386 14 7.5 14C7.77614 14 8 14.2239 8 14.5V17.5C8 17.7761 7.77614 18 7.5 18H4.5C4.22386 18 4 17.7761 4 17.5C4 17.2239 4.22386 17 4.5 17H6.12422C3.66539 15.6357 2 13.0128 2 10C2 5.58172 5.58172 2 10 2C14.4183 2 18 5.58172 18 10C18 10.2761 17.7761 10.5 17.5 10.5C17.2239 10.5 17 10.2761 17 10Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        , Svg.node "path"
            [ HA.attribute "d" "M10 12C8.89543 12 8 11.1046 8 10C8 8.89543 8.89543 8 10 8C11.1046 8 12 8.89543 12 10C12 11.1046 11.1046 12 10 12ZM10 11C10.5523 11 11 10.5523 11 10C11 9.44772 10.5523 9 10 9C9.44772 9 9 9.44772 9 10C9 10.5523 9.44772 11 10 11Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


rotateClockwiseSvg : Html.Html msg
rotateClockwiseSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M3 10C3 6.13401 6.13401 3 10 3C13.866 3 17 6.13401 17 10C17 12.7916 15.3658 15.2026 13 16.3265V14.5C13 14.2239 12.7761 14 12.5 14C12.2239 14 12 14.2239 12 14.5V17.5C12 17.7761 12.2239 18 12.5 18H15.5C15.7761 18 16 17.7761 16 17.5C16 17.2239 15.7761 17 15.5 17H13.8758C16.3346 15.6357 18 13.0128 18 10C18 5.58172 14.4183 2 10 2C5.58172 2 2 5.58172 2 10C2 10.2761 2.22386 10.5 2.5 10.5C2.77614 10.5 3 10.2761 3 10Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        , Svg.node "path"
            [ HA.attribute "d" "M10 12C11.1046 12 12 11.1046 12 10C12 8.89543 11.1046 8 10 8C8.89543 8 8 8.89543 8 10C8 11.1046 8.89543 12 10 12ZM10 11C9.44772 11 9 10.5523 9 10C9 9.44772 9.44772 9 10 9C10.5523 9 11 9.44772 11 10C11 10.5523 10.5523 11 10 11Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


resizeSmallSvg : Html.Html msg
resizeSmallSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 20 20"
        ]
        [ Svg.node "g"
            [ HA.attribute "fill" "none" ]
            [ Svg.node "path"
                [ HA.attribute "d" "M5.5 4A1.5 1.5 0 0 0 4 5.5v1a.5.5 0 0 1-1 0v-1A2.5 2.5 0 0 1 5.5 3h1a.5.5 0 0 1 0 1h-1zM16 5.5A1.5 1.5 0 0 0 14.5 4h-1a.5.5 0 0 1 0-1h1A2.5 2.5 0 0 1 17 5.5v1a.5.5 0 0 1-1 0v-1zm0 9a1.5 1.5 0 0 1-1.5 1.5h-1a.5.5 0 0 0 0 1h1a2.5 2.5 0 0 0 2.5-2.5v-1a.5.5 0 0 0-1 0v1zm-12 0A1.5 1.5 0 0 0 5.5 16h1.25a.5.5 0 0 1 0 1H5.5A2.5 2.5 0 0 1 3 14.5v-1.25a.5.5 0 0 1 1 0v1.25zM8.5 7A1.5 1.5 0 0 0 7 8.5v3A1.5 1.5 0 0 0 8.5 13h3a1.5 1.5 0 0 0 1.5-1.5v-3A1.5 1.5 0 0 0 11.5 7h-3zM8 8.5a.5.5 0 0 1 .5-.5h3a.5.5 0 0 1 .5.5v3a.5.5 0 0 1-.5.5h-3a.5.5 0 0 1-.5-.5v-3z"
                , HA.attribute "fill" "currentColor"
                ]
                []
            ]
        ]


zoomInSvg : Html.Html msg
zoomInSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M11.5 8.5C11.5 8.22386 11.2761 8 11 8H9V6C9 5.72386 8.77614 5.5 8.5 5.5C8.22386 5.5 8 5.72386 8 6V8H6C5.72386 8 5.5 8.22386 5.5 8.5C5.5 8.77614 5.72386 9 6 9H8V11C8 11.2761 8.22386 11.5 8.5 11.5C8.77614 11.5 9 11.2761 9 11V9H11C11.2761 9 11.5 8.77614 11.5 8.5Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        , Svg.node "path"
            [ HA.attribute "d" "M8.5 3C11.5376 3 14 5.46243 14 8.5C14 9.83879 13.5217 11.0659 12.7266 12.0196L16.8536 16.1464C17.0488 16.3417 17.0488 16.6583 16.8536 16.8536C16.68 17.0271 16.4106 17.0464 16.2157 16.9114L16.1464 16.8536L12.0196 12.7266C11.0659 13.5217 9.83879 14 8.5 14C5.46243 14 3 11.5376 3 8.5C3 5.46243 5.46243 3 8.5 3ZM8.5 4C6.01472 4 4 6.01472 4 8.5C4 10.9853 6.01472 13 8.5 13C10.9853 13 13 10.9853 13 8.5C13 6.01472 10.9853 4 8.5 4Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


zoomOutSvg : Html.Html msg
zoomOutSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M11 8C11.2761 8 11.5 8.22386 11.5 8.5C11.5 8.77614 11.2761 9 11 9H6C5.72386 9 5.5 8.77614 5.5 8.5C5.5 8.22386 5.72386 8 6 8H11Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        , Svg.node "path"
            [ HA.attribute "d" "M14 8.5C14 5.46243 11.5376 3 8.5 3C5.46243 3 3 5.46243 3 8.5C3 11.5376 5.46243 14 8.5 14C9.83879 14 11.0659 13.5217 12.0196 12.7266L16.1464 16.8536L16.2157 16.9114C16.4106 17.0464 16.68 17.0271 16.8536 16.8536C17.0488 16.6583 17.0488 16.3417 16.8536 16.1464L12.7266 12.0196C13.5217 11.0659 14 9.83879 14 8.5ZM4 8.5C4 6.01472 6.01472 4 8.5 4C10.9853 4 13 6.01472 13 8.5C13 10.9853 10.9853 13 8.5 13C6.01472 13 4 10.9853 4 8.5Z"
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


downloadSvg : Html.Html msg
downloadSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Svg.node "path"
                    [ HA.attribute "d" "M3.5,13 L12.5,13 C12.7761424,13 13,13.2238576 13,13.5 C13,13.7454599 12.8231248,13.9496084 12.5898756,13.9919443 L12.5,14 L3.5,14 C3.22385763,14 3,13.7761424 3,13.5 C3,13.2545401 3.17687516,13.0503916 3.41012437,13.0080557 L3.5,13 L12.5,13 L3.5,13 Z M7.91012437,1.00805567 L8,1 C8.24545989,1 8.44960837,1.17687516 8.49194433,1.41012437 L8.5,1.5 L8.5,10.292 L11.1819805,7.6109127 C11.3555469,7.43734635 11.6249713,7.4180612 11.8198394,7.55305725 L11.8890873,7.6109127 C12.0626536,7.78447906 12.0819388,8.05390346 11.9469427,8.2487716 L11.8890873,8.31801948 L8.35355339,11.8535534 C8.17998704,12.0271197 7.91056264,12.0464049 7.7156945,11.9114088 L7.64644661,11.8535534 L4.1109127,8.31801948 C3.91565056,8.12275734 3.91565056,7.80617485 4.1109127,7.6109127 C4.28447906,7.43734635 4.55390346,7.4180612 4.7487716,7.55305725 L4.81801948,7.6109127 L7.5,10.292 L7.5,1.5 C7.5,1.25454011 7.67687516,1.05039163 7.91012437,1.00805567 L8,1 L7.91012437,1.00805567 Z"
                    ]
                    []
                ]
            ]
        ]
