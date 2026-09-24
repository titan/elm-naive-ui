module NUI.Slider exposing
    ( Mark
    , Options
    , Step(..)
    , closestMark
    , cssVars
    , defaults
    , indicatorCssVars
    , pointerToValue
    , sanitizeValue
    , stepValue
    , valueToPercentage
    , view
    )

{-| Naive UI's `Slider` — the rail/fill/handles navigation for numeric
values, single or range. Upstream is one component over an arrified value
list (single = `[value]`; `range` switches scalar↔array semantics).

    import NUI.Slider as Slider
    import NUI.Theme as Theme

    Slider.view Theme.default
        { sliderD
            | value = [ 40 ]
            , marks = [ { value = 34, label = "34" } ]
        }

**DOM** (horizontal, marks set):

    div.n-slider(--disabled|--active|--with-mark|--vertical|--reverse)
    │         [style: 25 --n-* vars; mousedown/touchstart]
    └─ div.n-slider-rail
        ├─ div.n-slider-rail__fill [style: left|bottom %, width|height %]
        ├─ div.n-slider-dots(--transition-disabled)
        │   └─ div.n-slider-dot(--active) [style: left|… %]
        ├─ div.n-slider-handles
        │   └─ div.n-slider-handle-wrapper [tabindex, role=slider, aria-*,
        │           style: left|… %, z-index] > (thumb | div.n-slider-handle)
        │       └─ div.n-slider-handle-indicator--<placement> [5 vars]  (tooltip)
        └─ div.n-slider-marks
            └─ div.n-slider-mark [style: left|… %]

**The state contract.** Upstream's drag runtime (document mousemove/up,
rect measurement, focus management) is caller-owned (the `NUI.Split` /
`NUI.Rate` precedent): `value`, `activeIndex`, `hoverIndex`, `dragging`
and `dotTransitionDisabled` are caller state. The view emits the discrete
handle events (`onHandleFocus`/`onHandleBlur`/`onHandleMouseEnter`/
`onHandleMouseLeave`, index-tagged) and a bare root `onMousedown`
(upstream binds the same handler to mousedown + touchstart); the
pointer→value→snap math is exported pure (`pointerToValue`,
`sanitizeValue`, `stepValue`, `closestMark`). `preventDefault` (upstream
only when a handle is picked) and arrow-key stepping are the caller's
`attributes` seam (`stepValue` carries the math).

**The popover seam.** Upstream teleports the value indicator through
`VBinder/VFollower` (`fade-in-scale-up` transition). The port renders the
indicator inline under its handle-wrapper — the positioned/teleported
wrapper is the caller's (`NUI.Popover` conventions). `tooltip` gates the
indicator; `showTooltip` is the persistent non-range override (upstream's
`enabled = showTooltip && !range` is the follower seam).

**Divergences from upstream (documented):**

  - `marks` is a `List Mark` in caller order (upstream's
    `Record<string,…>` insertion order); an empty list stands for absent
    marks (upstream's truthy-empty-object edge is a Vue-ism not modelled).
  - The `keyboard` prop and the `to`/teleport plumbing are not ported
    (above); `onUpdate:value`'s emission rides the caller's drag runtime,
    so the view carries no value-change handler — `onDragstart`/
    `onDragend` likewise (the root `onMousedown` signal covers the start).
  - `formatTooltip` formats the indicator text only (upstream default is
    the raw number — `String.fromFloat` is byte-identical to JS
    `String(number)`).
  - Upstream's `handleCountExceeds2` (more than two values: the fill
    renders unstyled — a bare node is kept — and all dots go inactive) is
    kept; `aria-disabled` reads the RAW `disabled` prop (upstream quirk —
    the attribute is emitted only when disabled; never the form-item
    merge, which the port has none of).
  - Accepted edges: `stepPrecision` counts the decimals segment of the
    step's string (upstream counts every char after the dot, exponent
    included — only reachable for degenerate exponent-form steps); the
    sanitize buffer is always `±1` (upstream treats a falsy `0` as unset
    and substitutes the direction default — the port's call sites never
    pass anything but `±1`).

(Record updates bind `defaults` to a local first — see `NUI.Button`.)

-}

import Element exposing (Element)
import Html.Attributes as HA
import Html.Events
import Json.Decode
import NUI.InputNumber exposing (toFixedJs)
import NUI.Internal as I
import NUI.Popover as Popover
import NUI.Theme exposing (Theme)
import NUI.Theme.Slider as SliderTheme



-- TYPES -------------------------------------------------------------------------


{-| The follower placement for the indicator — the constructors live in
`NUI.Popover` (`Popover.Top`, `Popover.BottomStart`, …). Upstream's default
is `vertical ? 'right' : 'top'`.
-}
type alias Placement =
    Popover.Placement


{-| The step grid — `Step n` (numbers `<= 0` freeze the value, upstream
quirk) or `StepMarks` (`step: 'mark'`, snapping to the marks only).
-}
type Step
    = Step Float
    | StepMarks


{-| One mark — `value` is the rail percentage source, `label` the mark
text (upstream keys the record by the value's string).
-}
type alias Mark =
    { value : Float
    , label : String
    }


{-| The slider's options — upstream `sliderProps` minus the drag runtime,
the teleport plumbing and the uncontrolled default (state lives with the
caller).
-}
type alias Options msg =
    { range : Bool
    , value : List Float
    , min : Float
    , max : Float
    , step : Step
    , marks : List Mark
    , vertical : Bool
    , reverse : Bool
    , disabled : Bool
    , tooltip : Bool
    , showTooltip : Bool
    , placement : Maybe Placement
    , formatTooltip : Maybe (Float -> String)
    , activeIndex : Int
    , hoverIndex : Int
    , dragging : Bool
    , dotTransitionDisabled : Bool
    , thumb : Maybe (Element msg)
    , onHandleFocus : Maybe (Int -> msg)
    , onHandleBlur : Maybe (Int -> msg)
    , onHandleMouseEnter : Maybe (Int -> msg)
    , onHandleMouseLeave : Maybe (Int -> msg)
    , onMousedown : Maybe msg
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream `sliderProps` defaults: 0–100, step 1, everything else off /
`Nothing` / `[]` (except `tooltip`, on as upstream); indices are
upstream's `-1` sentinels.
-}
defaults : Options msg
defaults =
    { range = False
    , value = [ 0 ]
    , min = 0
    , max = 100
    , step = Step 1
    , marks = []
    , vertical = False
    , reverse = False
    , disabled = False
    , tooltip = True
    , showTooltip = False
    , placement = Nothing
    , formatTooltip = Nothing
    , activeIndex = -1
    , hoverIndex = -1
    , dragging = False
    , dotTransitionDisabled = False
    , thumb = Nothing
    , onHandleFocus = Nothing
    , onHandleBlur = Nothing
    , onHandleMouseEnter = Nothing
    , onHandleMouseLeave = Nothing
    , onMousedown = Nothing
    , attributes = []
    }



-- VIEW --------------------------------------------------------------------------


{-| The `n-slider` root — the five modifier classes in upstream order
(`--disabled`, `--active`, `--with-mark`, `--vertical`, `--reverse`), the
25 CSS vars, and the rail walk. See the module docstring for the state and
popover contracts.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    let
        arrified =
            List.map (clampValue opts.min opts.max) opts.value

        ctx =
            { theme = theme
            , opts = opts
            , arrified = arrified
            , exceeds2 = List.length arrified > 2
            , styleDirection =
                directionKey opts.vertical opts.reverse
            }
    in
    Element.el
        ([ I.classes
            ([ "n-slider" ]
                ++ I.classIf opts.disabled "n-slider--disabled"
                ++ I.classIf (opts.activeIndex /= -1) "n-slider--active"
                ++ I.classIf (not (List.isEmpty opts.marks)) "n-slider--with-mark"
                ++ I.classIf opts.vertical "n-slider--vertical"
                ++ I.classIf opts.reverse "n-slider--reverse"
            )
         , I.cssVars (cssVars theme)
         ]
            ++ mousedownAttrs opts
            ++ opts.attributes
        )
        (railNode ctx)


type alias Ctx msg =
    { theme : Theme
    , opts : Options msg
    , arrified : List Float
    , exceeds2 : Bool
    , styleDirection : String
    }


directionKey : Bool -> Bool -> String
directionKey vertical reverse =
    if vertical then
        if reverse then
            "top"

        else
            "bottom"

    else if reverse then
        "right"

    else
        "left"


mousedownAttrs : Options msg -> List (Element.Attribute msg)
mousedownAttrs opts =
    case opts.onMousedown of
        Just handler ->
            [ Element.htmlAttribute (Html.Events.on "mousedown" (Json.Decode.succeed handler))
            , Element.htmlAttribute (Html.Events.on "touchstart" (Json.Decode.succeed handler))
            ]

        Nothing ->
            []


railNode : Ctx msg -> Element msg
railNode ctx =
    Element.el
        [ I.classes [ "n-slider-rail" ] ]
        (Element.column []
            (fillNode ctx :: dotsNode ctx ++ [ handlesNode ctx ] ++ marksNode ctx)
        )



-- FILL (upstream fillStyleRef) ------------------------------------------------------


{-| The fill span — >2 values leave it UNSTYLED (upstream `fillStyleRef`
returns undefined but keeps the node — a bare div); single spans
`min → value`, range spans `min(values) → max(values)`; the direction key
first, then width/height.
-}
fillNode : Ctx msg -> Element msg
fillNode ctx =
    if ctx.exceeds2 then
        -- upstream renders the fill div unconditionally; >2 values just
        -- leaves fillStyle undefined — a bare unstyled node (kept)
        Element.el [ I.classes [ "n-slider-rail__fill" ] ] Element.none

    else
        let
            opts =
                ctx.opts

            startValue =
                if opts.range then
                    Maybe.withDefault opts.min (List.minimum ctx.arrified)

                else
                    opts.min

            endValue =
                if opts.range then
                    Maybe.withDefault opts.max (List.maximum ctx.arrified)

                else
                    Maybe.withDefault opts.min (List.head ctx.arrified)

            start =
                valueToPercentage opts.min opts.max startValue

            span =
                valueToPercentage opts.min opts.max endValue - start
        in
        Element.el
            [ I.classes [ "n-slider-rail__fill" ]
            , Element.htmlAttribute (HA.style ctx.styleDirection (pct start))
            , Element.htmlAttribute
                (HA.style
                    (if opts.vertical then
                        "height"

                     else
                        "width"
                    )
                    (pct span)
                )
            ]
            Element.none



-- DOTS + MARKS (upstream markInfosRef) ------------------------------------------------


{-| One mark's `active` read — range-inclusive / single-minimum, `False`
for every dot when more than two values.
-}
markActive : Ctx msg -> Float -> Bool
markActive ctx num =
    if ctx.exceeds2 then
        False

    else
        let
            orderValues =
                List.sort ctx.arrified
        in
        if ctx.opts.range then
            num
                >= Maybe.withDefault num (List.minimum orderValues)
                && num
                <= Maybe.withDefault num (List.maximum orderValues)

        else
            num <= Maybe.withDefault num (List.head orderValues)


dotsNode : Ctx msg -> List (Element msg)
dotsNode ctx =
    if List.isEmpty ctx.opts.marks then
        []

    else
        [ Element.column
            [ I.classes
                ([ "n-slider-dots" ]
                    ++ I.classIf ctx.opts.dotTransitionDisabled "n-slider-dots--transition-disabled"
                )
            ]
            (List.map (dotNode ctx) ctx.opts.marks)
        ]


dotNode : Ctx msg -> Mark -> Element msg
dotNode ctx mark =
    Element.el
        [ I.classes
            ([ "n-slider-dot" ]
                ++ I.classIf (markActive ctx mark.value) "n-slider-dot--active"
            )
        , Element.htmlAttribute
            (HA.style ctx.styleDirection
                (pct (valueToPercentage ctx.opts.min ctx.opts.max mark.value))
            )
        ]
        Element.none


marksNode : Ctx msg -> List (Element msg)
marksNode ctx =
    if List.isEmpty ctx.opts.marks then
        []

    else
        [ Element.column
            [ I.classes [ "n-slider-marks" ] ]
            (List.map (markNode ctx) ctx.opts.marks)
        ]


markNode : Ctx msg -> Mark -> Element msg
markNode ctx mark =
    Element.el
        [ I.classes [ "n-slider-mark" ]
        , Element.htmlAttribute
            (HA.style ctx.styleDirection
                (pct (valueToPercentage ctx.opts.min ctx.opts.max mark.value))
            )
        ]
        (Element.text mark.label)



-- HANDLES (upstream Slider.tsx render) ------------------------------------------------


handlesNode : Ctx msg -> Element msg
handlesNode ctx =
    Element.column
        [ I.classes [ "n-slider-handles" ] ]
        (List.indexedMap (handleNode ctx) ctx.arrified)


handleNode : Ctx msg -> Int -> Float -> Element msg
handleNode ctx index value =
    let
        opts =
            ctx.opts

        ariaDisabled =
            -- upstream aria-disabled={this.disabled} — RAW prop; Vue drops
            -- the attribute when falsy
            if opts.disabled then
                [ Element.htmlAttribute (HA.attribute "aria-disabled" "true") ]

            else
                []

        indicator =
            if opts.tooltip && isShowTooltip opts index then
                [ indicatorNode ctx value ]

            else
                []

        inner =
            case opts.thumb of
                Just thumb ->
                    thumb

                Nothing ->
                    Element.el [ I.classes [ "n-slider-handle" ] ] Element.none

        handleEvents =
            [ case opts.onHandleFocus of
                Just handler ->
                    [ Element.htmlAttribute (Html.Events.onFocus (handler index)) ]

                Nothing ->
                    []
            , case opts.onHandleBlur of
                Just handler ->
                    [ Element.htmlAttribute (Html.Events.onBlur (handler index)) ]

                Nothing ->
                    []
            , case opts.onHandleMouseEnter of
                Just handler ->
                    [ Element.htmlAttribute (Html.Events.on "mouseenter" (Json.Decode.succeed (handler index))) ]

                Nothing ->
                    []
            , case opts.onHandleMouseLeave of
                Just handler ->
                    [ Element.htmlAttribute (Html.Events.on "mouseleave" (Json.Decode.succeed (handler index))) ]

                Nothing ->
                    []
            ]
                |> List.concat
    in
    Element.el
        ([ I.classes [ "n-slider-handle-wrapper" ]
         , Element.htmlAttribute
            (HA.tabindex
                (if opts.disabled then
                    -1

                 else
                    0
                )
            )
         , Element.htmlAttribute (HA.attribute "role" "slider")
         , Element.htmlAttribute (HA.attribute "aria-valuenow" (String.fromFloat value))
         , Element.htmlAttribute (HA.attribute "aria-valuemin" (String.fromFloat opts.min))
         , Element.htmlAttribute (HA.attribute "aria-valuemax" (String.fromFloat opts.max))
         , Element.htmlAttribute
            (HA.attribute "aria-orientation"
                (if opts.vertical then
                    "vertical"

                 else
                    "horizontal"
                )
            )
         , Element.htmlAttribute (HA.style ctx.styleDirection (pct (valueToPercentage opts.min opts.max value)))
         , Element.htmlAttribute
            (HA.style "z-index" <|
                String.fromInt <|
                    if index == opts.activeIndex then
                        1

                    else
                        0
            )
         ]
            ++ ariaDisabled
            ++ handleEvents
        )
        (Element.column [] (inner :: indicator))


{-| Upstream `isShowTooltip` — the persistent `showTooltip`, the hovered
handle, or the dragged handle.
-}
isShowTooltip : Options msg -> Int -> Bool
isShowTooltip opts index =
    opts.showTooltip
        || opts.hoverIndex
        == index
        || (opts.activeIndex == index && opts.dragging)


{-| The inline indicator — the positioned/teleported wrapper is the
caller's (`NUI.Popover` seam); the port renders it under the handle.
-}
indicatorNode : Ctx msg -> Float -> Element msg
indicatorNode ctx value =
    let
        opts =
            ctx.opts

        mergedPlacement =
            Maybe.withDefault
                (if opts.vertical then
                    Popover.Right

                 else
                    Popover.Top
                )
                opts.placement
    in
    Element.el
        [ I.classes
            [ "n-slider-handle-indicator"
            , "n-slider-handle-indicator--" ++ Popover.placementName mergedPlacement
            ]
        , I.cssVars (indicatorCssVars ctx.theme)
        ]
        (Element.text <|
            case opts.formatTooltip of
                Just format ->
                    format value

                Nothing ->
                    String.fromFloat value
        )


pct : Float -> String
pct value =
    String.fromFloat value ++ "%"



-- PURE LOGIC (upstream value conversion + snapping) ------------------------------------


{-| Upstream `getClosestMark` — the strictly-closest candidate (the first
wins ties); `index` is the index INTO the passed list (upstream reuses it
for range handle picking).
-}
closestMark : List Float -> Float -> Maybe { index : Int, distance : Float, value : Float }
closestMark markValues currentValue =
    closestMarkWithBuffer markValues currentValue Nothing


closestMarkWithBuffer : List Float -> Float -> Maybe Float -> Maybe { index : Int, distance : Float, value : Float }
closestMarkWithBuffer markValues currentValue buffer =
    List.foldl
        (\( index, candidate ) found ->
            let
                diff =
                    candidate - currentValue

                distance =
                    abs diff

                passes =
                    passesBuffer diff buffer
            in
            case found of
                Nothing ->
                    if passes then
                        Just { index = index, distance = distance, value = candidate }

                    else
                        Nothing

                Just best ->
                    if passes && distance < best.distance then
                        Just { index = index, distance = distance, value = candidate }

                    else
                        found
        )
        Nothing
        (List.indexedMap Tuple.pair markValues)


passesBuffer : Float -> Maybe Float -> Bool
passesBuffer diff buffer =
    case buffer of
        Nothing ->
            True

        Just b ->
            diff * b > 0


{-| Upstream `valueToPercentage` — `(value - min) / (max - min) * 100`.
-}
valueToPercentage : Float -> Float -> Float -> Float
valueToPercentage lo hi value =
    ((value - lo) / (hi - lo)) * 100


{-| Upstream `getPointValue` — the pointer→value derivation for the
caller's drag runtime. `railStart` is the measured `.n-slider-handles`
rect's `left` (horizontal) or `bottom` (vertical); `railSize` its
width/height; `pointer` the event's `clientX`/`clientY`. `reverse` flips
the percentage, exactly as upstream. Returns the RAW unclamped value —
`sanitizeValue` owns the clamp (upstream likewise).
-}
pointerToValue :
    { vertical : Bool
    , reverse : Bool
    , min : Float
    , max : Float
    , railStart : Float
    , railSize : Float
    , pointer : Float
    }
    -> Float
pointerToValue { vertical, reverse, min, max, railStart, railSize, pointer } =
    let
        percentage =
            if vertical then
                (railStart - pointer) / railSize

            else
                (pointer - railStart) / railSize

        adjusted =
            if reverse then
                1 - percentage

            else
                percentage
    in
    min + (max - min) * adjusted


{-| The sanitize config — the step grid, the clamp bounds and the mark
values (the caller's `marks |> List.map .value`).
-}
type alias SanitizeConfig =
    { step : Step
    , min : Float
    , max : Float
    , markValues : List Float
    }


{-| Upstream `sanitizeValue` — the snap. `step: 'mark'` picks the closest
mark (the current value appended as a candidate) and returns it RAW — no
clamp, so an out-of-range mark survives verbatim; `step <= 0` freezes the
current value, also RAW; stepping (`buffer` present — keyboard/drag
direction, always `±1`; upstream treats `0` as falsy/unset) builds the
surrounding step grid and lets marks hijack it; otherwise the rounded
value competes with the marks (marks win ties — they precede the round
value in the candidate list). Only the numeric branches clamp (and fall
back to the current value when no candidate passes).
-}
sanitizeValue : SanitizeConfig -> Float -> Float -> Maybe Float -> Float
sanitizeValue config value currentValue maybeBuffer =
    let
        stepping =
            maybeBuffer /= Nothing

        buffer =
            Maybe.withDefault
                (if value - currentValue > 0 then
                    1

                 else
                    -1
                )
                maybeBuffer
    in
    case config.step of
        StepMarks ->
            -- upstream returns the closest mark RAW — no clamp (the mark can
            -- sit outside [min, max]; render clamps via the arrified map)
            closestMarkWithBuffer (config.markValues ++ [ currentValue ])
                value
                (if stepping then
                    Just buffer

                 else
                    Nothing
                )
                |> Maybe.map .value
                |> Maybe.withDefault currentValue

        Step step ->
            if step <= 0 then
                -- frozen: RAW currentValue (upstream returns it verbatim)
                currentValue

            else
                let
                    p =
                        stepPrecision step

                    closest : Maybe Float
                    closest =
                        if stepping then
                            let
                                currentStep =
                                    toFixedNumber (currentValue / step) p

                                actualStep =
                                    toFloat (floor currentStep)

                                leftStep =
                                    if currentStep > actualStep then
                                        actualStep

                                    else
                                        actualStep - 1

                                rightStep =
                                    if currentStep < actualStep then
                                        actualStep

                                    else
                                        actualStep + 1
                            in
                            closestMarkWithBuffer
                                ([ toFixedNumber (leftStep * step) p
                                 , toFixedNumber (rightStep * step) p
                                 ]
                                    ++ config.markValues
                                )
                                currentValue
                                (Just buffer)
                                |> Maybe.map .value

                        else
                            closestMarkWithBuffer (config.markValues ++ [ getRoundValue config value ])
                                value
                                Nothing
                                |> Maybe.map .value
                in
                case closest of
                    Just candidate ->
                        clampValue config.min config.max candidate

                    Nothing ->
                        currentValue


{-| Upstream `handleStepValue` — the arrow-key step (ratio `±1`): the
frozen steps keep the current value, `step: 'mark'` still moves (the
marks candidates carry it), the buffer is the ratio's sign.
-}
stepValue : SanitizeConfig -> Float -> Int -> Float
stepValue config current ratio =
    let
        next =
            case config.step of
                Step step ->
                    if step <= 0 then
                        current

                    else
                        current + step * toFloat ratio

                StepMarks ->
                    current
    in
    sanitizeValue config next current <|
        Just <|
            if ratio > 0 then
                1

            else
                -1


getRoundValue : SanitizeConfig -> Float -> Float
getRoundValue config value =
    case config.step of
        Step step ->
            if step <= 0 then
                value

            else
                let
                    newValue =
                        toFloat (round ((value - config.min) / step)) * step + config.min
                in
                toFixedNumber newValue (stepPrecision step)

        StepMarks ->
            value


clampValue : Float -> Float -> Float -> Float
clampValue lo hi value =
    min hi (max lo value)


stepPrecision : Float -> Int
stepPrecision step =
    let
        stepString =
            String.fromFloat step
    in
    case String.split "." stepString of
        [ _, decimals ] ->
            String.length decimals

        _ ->
            0


toFixedNumber : Float -> Int -> Float
toFixedNumber value precision =
    Maybe.withDefault value (String.toFloat (toFixedJs value precision))



-- THEME -------------------------------------------------------------------------


{-| The 25 `--n-*` custom properties the root attaches (upstream emission
order — alphabetical after `--n-bezier`, with `--n-mark-font-size` last).
-}
cssVars : Theme -> List ( String, String )
cssVars theme =
    let
        s =
            SliderTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-dot-border", s.dotBorder )
    , ( "--n-dot-border-active", s.dotBorderActive )
    , ( "--n-dot-border-radius", s.dotBorderRadius )
    , ( "--n-dot-box-shadow", s.dotBoxShadow )
    , ( "--n-dot-color", s.dotColor )
    , ( "--n-dot-color-modal", s.dotColorModal )
    , ( "--n-dot-color-popover", s.dotColorPopover )
    , ( "--n-dot-height", s.dotHeight )
    , ( "--n-dot-width", s.dotWidth )
    , ( "--n-fill-color", s.fillColor )
    , ( "--n-fill-color-hover", s.fillColorHover )
    , ( "--n-font-size", s.fontSize )
    , ( "--n-handle-box-shadow", s.handleBoxShadow )
    , ( "--n-handle-box-shadow-active", s.handleBoxShadowActive )
    , ( "--n-handle-box-shadow-focus", s.handleBoxShadowFocus )
    , ( "--n-handle-box-shadow-hover", s.handleBoxShadowHover )
    , ( "--n-handle-color", s.handleColor )
    , ( "--n-handle-size", s.handleSize )
    , ( "--n-opacity-disabled", s.opacityDisabled )
    , ( "--n-rail-color", s.railColor )
    , ( "--n-rail-color-hover", s.railColorHover )
    , ( "--n-rail-height", s.railHeight )
    , ( "--n-rail-width-vertical", s.railWidthVertical )
    , ( "--n-mark-font-size", s.markFontSize )
    ]


{-| The 5 vars the indicator carries (its own mini-theme upstream —
`slider-indicator`).
-}
indicatorCssVars : Theme -> List ( String, String )
indicatorCssVars theme =
    let
        s =
            SliderTheme.vars theme
    in
    [ ( "--n-font-size", s.fontSize )
    , ( "--n-indicator-border-radius", s.indicatorBorderRadius )
    , ( "--n-indicator-box-shadow", s.indicatorBoxShadow )
    , ( "--n-indicator-color", s.indicatorColor )
    , ( "--n-indicator-text-color", s.indicatorTextColor )
    ]
