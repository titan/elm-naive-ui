module Sections.Controls exposing
    ( Model
    , Msg
    , buttonSection
    , init
    , inputNumberSection
    , inputOtpSection
    , inputSection
    , rateSection
    , sections
    , selectionSection
    , sliderSection
    , subscriptions
    , update
    )

{-| Controls family sections: Button, Input, Input OTP, Input Number,
Checkbox · Switch · Radio, Rate, Slider.

The static rows moved verbatim from Main.elm — that surface feeds the
check-dom gate, so every root keeps rendering exactly as before (the six
draggable slider rows now carry live state underneath; at rest they render
the same fixed values). The live demo rows (moved verbatim from Live/Controls.elm — same demoRow labels,
same `#live-*` ids) run a real update loop owned by this module: caller-
owned state per the port's contract (the component renders whatever the
model says; every channel feeds one Msg constructor). Where the port ships
the interaction algebra as pure helpers, update uses those instead of
re-deriving semantics (`InputNumber.inputUpdate` /
`deriveValueFromDisplayedValue`, `Slider.stepValue`).

The update returns `( Model, Cmd Msg )` (the Pickers precedent) for
runtime concerns the pure port cannot own: InputOtp's focus auto-advance —
upstream's `focusOnChar` needs DOM focus, so `OtpChanged` derives the next
slot (first empty, else last) and focuses it through `Browser.Dom.focus`
(`otpAdvance`) — and the Slider drag's press-time rect measurement (below).

The Slider drag runs the port's documented caller-owned runtime for real
(upstream `Slider.tsx` `handleRailMouseDown`/`startDragging`/
`handleMouseMove`) — ONE generic runtime over a spec table (`specs`
below; every draggable row, horizontal or vertical): the `attributes`
seam carries a `preventDefaultOn "mousedown"` decoder that reads the
press's clientX/Y (the port's `onMousedown` seam is a bare signal — no
coordinates), a follow-up `Browser.Dom.getElement` measures the root's box
(page space; `travelOf` rebases it by the scroll offset so it pairs with
the events' client coords), the handles travel box is the root inset by
`handleSize/2` on the travel axis (the cssr `.n-slider-handles` inset
rule; `handleSizePx` below), the press picks the closest handle
(`Slider.closestMark` over the row's values; a single value is always
handle 0) and jumps it through `Slider.pointerToValue` + `sanitizeValue`;
the document mousemove/mouseup pair then runs via `Browser.Events` (the
ColorPicker precedent) against the press-cached box — upstream re-reads
the rect per move, the press snapshot is the established demo compromise.
Touch drags are out of scope: elm/browser ships no touchmove/touchend
subscription seam (touchstart's preventDefault still suppresses scroll on
press). The only deliberately dead sliders are ctl-029's two cells (the
pinned indicator and the disabled rail are state fixtures, not demos).

Oracle-round divergences (tasks/recon/live-oracle.md):

  - [oracle D] **Rate hover is button-simulated** — upstream's hover preview
    is pointer-position algebra inside the port's rendering seam; the demo's
    ±½ buttons drive the same `hoverValue` field the port reads.
  - [oracle D] **Range handles can cross** — stepping "lo +" past `hi`
    produces `lo > hi` (upstream swaps handle identity on crossing); the
    port ships no range-ordering helper — drag runtime is caller-owned by
    contract — and the render self-heals (the fill spans min..max of the
    arrified value).

-}

import Browser.Dom
import Browser.Events
import Dict
import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode
import NUI.Button as Button
import NUI.ButtonGroup as ButtonGroup
import NUI.Checkbox as Checkbox
import NUI.Input as Input
import NUI.InputNumber as InputNumber
import NUI.InputOtp as InputOtp
import NUI.Radio as Radio
import NUI.Rate as Rate
import NUI.Slider as Slider
import NUI.Switch as Switch
import NUI.Theme exposing (Theme)
import NUI.Types as T
import Showcase exposing (capitalize, demoRow, demoRowUnfenced, section)
import Task



-- SLIDER SPEC TABLE (the shared drag runtime's data)


{-| One draggable slider row: the DOM/`Browser.Dom` id, the option flags
the runtime must honor (axes, snap grid) and the initial arrified value.
Rendering, press handling and move tracking all read this table — adding a
draggable row is adding an entry. The ctl-029 state fixtures are
deliberately absent (they pin `hoverIndex`/`dragging`/`disabled`).
-}
type alias Spec =
    { id : String
    , range : Bool
    , vertical : Bool
    , reverse : Bool
    , min : Float
    , max : Float
    , step : Slider.Step
    , marks : List Slider.Mark
    , init : List Float
    }


specs : List Spec
specs =
    [ { id = "live-slider-marked", range = False, vertical = False, reverse = False, min = 0, max = 100, step = Slider.Step 1, marks = sliderMarks, init = [ 40 ] }
    , { id = "live-slider-range-marks", range = True, vertical = False, reverse = False, min = 0, max = 100, step = Slider.Step 1, marks = sliderMarks, init = [ 24, 49 ] }
    , { id = "live-slider-vertical", range = False, vertical = True, reverse = False, min = 0, max = 100, step = Slider.Step 1, marks = sliderMarks, init = [ 77 ] }
    , { id = "live-slider-vertical-reverse", range = False, vertical = True, reverse = True, min = 0, max = 100, step = Slider.Step 1, marks = sliderMarks, init = [ 77 ] }
    , { id = "live-slider-snap", range = True, vertical = False, reverse = False, min = 0, max = 100, step = Slider.StepMarks, marks = sliderMarks, init = [ 34, 75 ] }
    , { id = "live-slider-multi", range = True, vertical = False, reverse = False, min = 0, max = 100, step = Slider.Step 1, marks = sliderMarks, init = [ 10, 50, 90 ] }
    , singleSpec
    , { id = "live-slider-range", range = True, vertical = False, reverse = False, min = 0, max = 100, step = Slider.Step 1, marks = rangeMarks, init = [ 20, 60 ] }
    ]


singleSpec : Spec
singleSpec =
    { id = "live-slider-single", range = False, vertical = False, reverse = False, min = 0, max = 100, step = Slider.Step 1, marks = [], init = [ 40 ] }


specOf : String -> Spec
specOf id =
    -- rendered ids all come from `specs`; the fallback keeps the lookup total
    Maybe.withDefault singleSpec (List.head (List.filter (\s -> s.id == id) specs))


configOf : Spec -> { step : Slider.Step, min : Float, max : Float, markValues : List Float }
configOf spec =
    { step = spec.step
    , min = spec.min
    , max = spec.max
    , markValues = List.map .value spec.marks
    }



-- MODEL (one field per caller-owned bit of component state)


type alias Model =
    { presses : Int
    , inputText : String
    , inputFocused : Bool
    , pair : ( String, String )
    , pairSource : Maybe Input.PairSource
    , numberValue : Maybe Float
    , numberBuffer : Maybe String
    , switchOn : Bool
    , checks : List Bool
    , city : Maybe String
    , rateValue : Maybe Float
    , rateHover : Maybe Float
    , sliders : Dict.Dict String RowState
    , otp : List String
    , otpMasked : Bool
    }


{-| One draggable slider row's caller-owned state (the port's contract:
the component renders whatever this says).
-}
type alias RowState =
    { value : List Float
    , active : Int
    , hover : Int
    , drag : Maybe DragRail
    }


{-| The cached rail geometry a live drag tracks against — the handles
travel box measured once at press (client space, rebased by `travelOf` so
it pairs with the events' clientX/clientY directly). The dragged handle
lives on the row (`RowState.active`, upstream `activeIndexRef`).
-}
type alias DragRail =
    { railStart : Float
    , railSize : Float
    }


init : Model
init =
    { presses = 0
    , inputText = ""
    , inputFocused = False
    , pair = ( "", "" )
    , pairSource = Nothing
    , numberValue = Just 3
    , numberBuffer = Nothing
    , switchOn = False
    , checks = [ True, False, False ]
    , city = Nothing
    , rateValue = Nothing
    , rateHover = Nothing
    , sliders =
        Dict.fromList
            (List.map (\s -> ( s.id, { value = s.init, active = -1, hover = -1, drag = Nothing } )) specs)
    , otp = []
    , otpMasked = False
    }



-- UPDATE (one case per channel; component semantics come from the port)


type Msg
    = Press
    | ResetPresses
    | InputChanged String
    | InputFocused
    | InputBlurred
    | PairInput String String Input.PairSource
    | NumberInput String
    | NumberChanged (Maybe Float)
    | NumberCommit
    | SwitchToggled Bool
    | CheckItem Int Bool
    | CheckMaster Bool
    | RadioPicked String
    | RateSelected Float
    | RateNudge Float
    | RatePreviewClear
    | SliderMsg String SliderEvent
    | OtpChanged (List String)
    | OtpReset
    | OtpMaskToggled
    | OtpFocused
    | DragIgnored


{-| One slider row's channel, keyed by the row id at the `SliderMsg` tag:
the press/measure/move/up drag sequence plus the port's discrete handle
events and the ±1 step buttons (`Nudge handle ratio` — `Slider.stepValue`).
-}
type SliderEvent
    = RailPress Float Float
    | Measured Float Float Browser.Dom.Element
    | Move Float Float
    | Up
    | Focus Int
    | Blur Int
    | Enter Int
    | Leave Int
    | Nudge Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Press ->
            ( { model | presses = model.presses + 1 }, Cmd.none )

        ResetPresses ->
            ( { model | presses = 0 }, Cmd.none )

        InputChanged raw ->
            ( { model | inputText = raw }, Cmd.none )

        InputFocused ->
            ( { model | inputFocused = True }, Cmd.none )

        InputBlurred ->
            ( { model | inputFocused = False }, Cmd.none )

        PairInput first second source ->
            ( { model | pair = ( first, second ), pairSource = Just source }, Cmd.none )

        NumberInput raw ->
            -- the port's handleUpdateDisplayedValue: keep the raw buffer,
            -- live-sync value when the option allows it
            ( { model
                | numberBuffer = Just raw
                , numberValue =
                    case InputNumber.inputUpdate (numberOptions model) raw of
                        Just updated ->
                            updated

                        Nothing ->
                            model.numberValue
              }
            , Cmd.none
            )

        NumberChanged payload ->
            -- add / minus buttons (via addUpdate / minusUpdate inside view)
            ( { model | numberValue = payload, numberBuffer = Nothing }, Cmd.none )

        NumberCommit ->
            -- the caller-owned blur / Enter commit, verbatim upstream args
            ( case
                InputNumber.deriveValueFromDisplayedValue
                    (InputNumber.contextOf (numberOptions model))
                    { offset = 0, doUpdateIfValid = True, fixPrecision = True, isInputing = False }
              of
                InputNumber.NumberValue v ->
                    { model | numberValue = Just v, numberBuffer = Nothing }

                InputNumber.NullValue ->
                    { model | numberValue = Nothing, numberBuffer = Nothing }

                InputNumber.InvalidValue ->
                    model
            , Cmd.none
            )

        SwitchToggled on ->
            ( { model | switchOn = on }, Cmd.none )

        CheckItem index on ->
            ( { model
                | checks =
                    List.indexedMap
                        (\i c ->
                            if i == index then
                                on

                            else
                                c
                        )
                        model.checks
              }
            , Cmd.none
            )

        CheckMaster on ->
            ( { model | checks = List.map (always on) model.checks }, Cmd.none )

        RadioPicked value ->
            ( { model | city = Just value }, Cmd.none )

        RateSelected value ->
            ( { model | rateValue = Just value }, Cmd.none )

        RateNudge delta ->
            let
                base =
                    Maybe.withDefault (Maybe.withDefault 0 model.rateValue) model.rateHover
            in
            ( { model | rateHover = Just (clamp 0 5 (base + delta)) }, Cmd.none )

        RatePreviewClear ->
            ( { model | rateHover = Nothing }, Cmd.none )

        SliderMsg id event ->
            ( { model | sliders = Dict.update id (Maybe.map (updateRow (specOf id) event)) model.sliders }
            , case event of
                RailPress x y ->
                    -- upstream handleRailMouseDown: the press arrives, the
                    -- rect read is async in Elm (Browser.Dom) — measure,
                    -- then commit in Measured. The drag flag is NOT set yet
                    -- (dragging starts once the press resolves).
                    Task.attempt (Result.withDefault DragIgnored)
                        (Task.map (SliderMsg id << Measured x y) (Browser.Dom.getElement id))

                _ ->
                    Cmd.none
            )

        OtpChanged value ->
            ( { model | otp = value }, otpAdvance value )

        OtpReset ->
            ( { model | otp = [] }, otpAdvance [] )

        OtpMaskToggled ->
            ( { model | otpMasked = not model.otpMasked }, Cmd.none )

        OtpFocused ->
            ( model, Cmd.none )

        DragIgnored ->
            -- getElement failed (the slider unmounted mid-press); upstream's
            -- railEl-null guard is the equivalent no-op
            ( model, Cmd.none )


{-| One row's event algebra — upstream `handleRailMouseDown` /
`startDragging` / `handleMouseMove` / `stopDragging` plus the discrete
handle events, all reading the row's spec for the axis/snap math. A single
value always picks handle 0; a press picks the closest handle
(`getClosestMark(pointValue, values)`); the press jumps it
(`sanitizeValue(pointValue)` — no buffer on the drag path) and caches the
travel box the move path tracks against. `Up` keeps `active` (upstream
`stopDragging` clears dragging only; blur clears the rest).
-}
updateRow : Spec -> SliderEvent -> RowState -> RowState
updateRow spec event row =
    case event of
        RailPress _ _ ->
            -- the async measure (update's Press branch) resolves into Measured
            row

        Measured x y ele ->
            let
                rail =
                    travelOf spec.vertical ele

                pointValue =
                    pointerValueOf spec rail x y

                picked =
                    pickHandle row.value pointValue

                current =
                    Maybe.withDefault spec.min (List.head (List.drop picked row.value))
            in
            if picked == -1 then
                row

            else
                { row
                    | value =
                        List.indexedMap
                            (\i v ->
                                if i == picked then
                                    Slider.sanitizeValue (configOf spec) pointValue current Nothing

                                else
                                    v
                            )
                            row.value
                    , active = picked
                    , drag = Just rail
                }

        Move x y ->
            case row.drag of
                Nothing ->
                    row

                Just rail ->
                    let
                        raw =
                            pointerValueOf spec rail x y

                        current =
                            Maybe.withDefault spec.min (List.head (List.drop row.active row.value))
                    in
                    { row
                        | value =
                            List.indexedMap
                                (\i v ->
                                    if i == row.active then
                                        Slider.sanitizeValue (configOf spec) raw current Nothing

                                    else
                                        v
                                )
                                row.value
                    }

        Up ->
            { row | drag = Nothing }

        Focus index ->
            { row | active = index }

        Blur _ ->
            -- upstream handleHandleBlur: the only clear of activeIndex
            { row | active = -1, drag = Nothing }

        Enter index ->
            { row | hover = index }

        Leave _ ->
            { row | hover = -1 }

        Nudge handle ratio ->
            let
                current =
                    Maybe.withDefault spec.min (List.head (List.drop handle row.value))
            in
            { row
                | value =
                    List.indexedMap
                        (\i v ->
                            if i == handle then
                                Slider.stepValue (configOf spec) current ratio

                            else
                                v
                        )
                        row.value
            }


{-| Upstream `getClosestMark(pointValue, values).index` — the strictly
closest value wins (ties keep the first); a single value has no choice
(handle 0).
-}
pickHandle : List Float -> Float -> Int
pickHandle values pointValue =
    case values of
        [ _ ] ->
            0

        _ ->
            Slider.closestMark values pointValue
                |> Maybe.map .index
                |> Maybe.withDefault -1


{-| `Slider.pointerToValue` over the spec's axis/reverse — `pointer` is the
press/move's coordinate on the travel axis (clientX horizontal,
clientY vertical).
-}
pointerValueOf : Spec -> DragRail -> Float -> Float -> Float
pointerValueOf spec rail x y =
    Slider.pointerToValue
        { vertical = spec.vertical
        , reverse = spec.reverse
        , min = spec.min
        , max = spec.max
        , railStart = rail.railStart
        , railSize = rail.railSize
        , pointer =
            if spec.vertical then
                y

            else
                x
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        (List.filterMap
            (\( id, row ) ->
                if row.drag /= Nothing then
                    -- upstream startDragging's document pair (mousemove +
                    -- mouseup); Browser.Events is the ColorPicker precedent
                    Just
                        (Sub.batch
                            [ Browser.Events.onMouseMove (dragMoveDecoder (\x y -> SliderMsg id (Move x y)))
                            , Browser.Events.onMouseUp (Json.Decode.succeed (SliderMsg id Up))
                            ]
                        )

                else
                    Nothing
            )
            (Dict.toList model.sliders)
        )


{-| clientX/Y out of the document mousemove (the ColorPicker moveDecoder).
-}
dragMoveDecoder : (Float -> Float -> Msg) -> Json.Decode.Decoder Msg
dragMoveDecoder toMsg =
    Json.Decode.map2 toMsg
        (Json.Decode.field "clientX" Json.Decode.float)
        (Json.Decode.field "clientY" Json.Decode.float)


{-| The root rect → the `.n-slider-handles` travel box: the cssr insets the
handles container by `calc(var(--n-handle-size)/2)` on each side of the
travel axis. `getElement` reports page coords while `mousemove` reports
client coords, so both edges are rebased by the scroll offset
(`viewport.x`/`viewport.y`) — vertical reads the client-space `bottom`
(`pointerToValue`'s vertical convention: railStart = bottom).
-}
travelOf : Bool -> Browser.Dom.Element -> DragRail
travelOf vertical ele =
    let
        inset =
            handleSizePx / 2

        left =
            ele.element.x - ele.viewport.x

        bottom =
            ele.element.y + ele.element.height - ele.viewport.y
    in
    if vertical then
        -- the travel box's bottom edge (client space) — the cssr inset
        -- SUBTRACTS from the bottom on a bottom-anchored axis
        { railStart = bottom - inset
        , railSize = ele.element.height - handleSizePx
        }

    else
        { railStart = left + inset
        , railSize = ele.element.width - handleSizePx
        }


{-| `--n-handle-size: 18px` (NUI.Theme.Slider, both modes). The rows never
override it; if the theme grows a different size, this constant and the
cssr inset stay in lockstep with it.
-}
handleSizePx : Float
handleSizePx =
    18



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


btn : Button.Options msg
btn =
    Button.defaults


inputD : Input.Options msg
inputD =
    Input.defaults


iotpD : InputOtp.Options msg
iotpD =
    InputOtp.defaults


cbD : Checkbox.Options msg
cbD =
    Checkbox.defaults


swD : Switch.Options msg
swD =
    Switch.defaults


radioD : Radio.Options msg
radioD =
    Radio.defaults


radioGD : Radio.GroupOptions String msg
radioGD =
    Radio.groupDefaults


inD : InputNumber.Options msg
inD =
    InputNumber.defaults


rateD : Rate.Options msg
rateD =
    Rate.defaults


bgD : ButtonGroup.Options msg
bgD =
    ButtonGroup.defaults


sliderD : Slider.Options msg
sliderD =
    Slider.defaults



-- OPTIONS BUILDERS (live demos)


numberOptions : Model -> InputNumber.Options Msg
numberOptions model =
    { inD
        | value = model.numberValue
        , displayedValue = model.numberBuffer
        , min = Just 0
        , max = Just 10
        , step = 1
        , placeholder = Just "0 – 10"
        , onChange = Just NumberChanged
        , onInput = Just NumberInput
        , attributes = [ Element.htmlAttribute (HA.id "live-input-number-stepper") ]
    }


rateOptions : Model -> Rate.Options Msg
rateOptions model =
    { rateD
        | value = model.rateValue
        , hoverValue = model.rateHover
        , allowHalf = True
        , onSelect = Just RateSelected
        , attributes = [ Element.htmlAttribute (HA.id "live-rate") ]
    }


sliderOptions : Spec -> RowState -> Slider.Options Msg
sliderOptions spec row =
    { sliderD
        | range = spec.range
        , value = row.value
        , min = spec.min
        , max = spec.max
        , step = spec.step
        , marks = spec.marks
        , vertical = spec.vertical
        , reverse = spec.reverse
        , activeIndex = row.active
        , hoverIndex = row.hover
        , dragging = row.drag /= Nothing
        , onHandleFocus = Just (SliderMsg spec.id << Focus)
        , onHandleBlur = Just (SliderMsg spec.id << Blur)
        , onHandleMouseEnter = Just (SliderMsg spec.id << Enter)
        , onHandleMouseLeave = Just (SliderMsg spec.id << Leave)
        , attributes =
            [ Element.htmlAttribute (HA.id spec.id)
            , Element.htmlAttribute (pressAttr (\x y -> SliderMsg spec.id (RailPress x y)))
            ]
    }


{-| The press seam: upstream `handleRailMouseDown` reads the event's
clientX/Y synchronously (getPointValue). The port's `onMousedown` is a bare
signal, so the demo rides the root `attributes` seam with its own decoder:
`preventDefault` matches upstream's touch-scroll suppression (upstream
guards it behind the handle pick, the demo always picks), and the press
coordinates ride the message into the async rect read (`SliderGo`).
-}
pressAttr : (Float -> Float -> Msg) -> Html.Attribute Msg
pressAttr toMsg =
    HE.preventDefaultOn "mousedown"
        (Json.Decode.map (\m -> ( m, True ))
            (Json.Decode.map2 toMsg
                (Json.Decode.field "clientX" Json.Decode.float)
                (Json.Decode.field "clientY" Json.Decode.float)
            )
        )


otpOptions : Model -> InputOtp.Options Msg
otpOptions model =
    { iotpD
        | value = model.otp
        , length = 6
        , allowInput = Just (\char _ _ -> String.all Char.isDigit char)
        , mask = model.otpMasked
        , onUpdateValue = Just OtpChanged
        , attributes = [ Element.htmlAttribute (HA.id "live-input-otp") ]
        , slotInputAttributes = \i -> [ HA.id (otpSlotId i) ]
    }


{-| Per-slot ids — the addresses `otpAdvance` focuses (one source for both).
-}
otpSlotId : Int -> String
otpSlotId index =
    "live-input-otp-slot-" ++ String.fromInt index


{-| Upstream's post-input focus as a command: focus the first empty slot
(all full → the last one). Errors ignored (the id exists while mounted).
-}
otpAdvance : List String -> Cmd Msg
otpAdvance value =
    let
        slots =
            List.take 6 (value ++ List.repeat 6 "")

        target =
            slots
                |> List.indexedMap Tuple.pair
                |> List.filter (Tuple.second >> String.isEmpty)
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault 5
    in
    Task.attempt (\_ -> OtpFocused)
        (Browser.Dom.focus (otpSlotId target))


singleConfig : { step : Slider.Step, min : Float, max : Float, markValues : List Float }
singleConfig =
    { step = Slider.Step 1
    , min = 0
    , max = 100
    , markValues = []
    }


rangeConfig : { step : Slider.Step, min : Float, max : Float, markValues : List Float }
rangeConfig =
    { step = Slider.Step 1
    , min = 0
    , max = 100
    , markValues = List.map .value rangeMarks
    }


rangeMarks : List Slider.Mark
rangeMarks =
    [ { value = 0, label = "0" }
    , { value = 25, label = "25" }
    , { value = 50, label = "50" }
    , { value = 75, label = "75" }
    , { value = 100, label = "100" }
    ]


sliderMarks : List Slider.Mark
sliderMarks =
    [ { value = 34, label = "34" }
    , { value = 75, label = "75" }
    ]



-- VIEW HELPERS


{-| The indeterminate read the master computes in its own model: some but
not all of the items checked.
-}
masterIndeterminate : Model -> Bool
masterIndeterminate model =
    List.any identity model.checks && not (List.all identity model.checks)


itemCheckbox : Theme -> Model -> Int -> Bool -> Element Msg
itemCheckbox theme model index checked =
    Element.el [ Element.htmlAttribute (HA.id ("live-checkbox-item-" ++ String.fromInt index)) ]
        (Checkbox.view theme
            { cbD | checked = checked, onCheck = Just (CheckItem index) }
            [ Element.text (itemLabel index) ]
        )


itemLabel : Int -> String
itemLabel index =
    case index of
        0 ->
            "Elm"

        1 ->
            "Naive UI"

        _ ->
            "elm-ui"


smallButton : Theme -> String -> String -> Msg -> Element Msg
smallButton theme id label msg =
    Button.view theme
        { btn
            | size = T.Small
            , onPress = Just msg
            , attributes = [ Element.htmlAttribute (HA.id id) ]
        }
        [ Element.text label ]


numberCaption : Model -> String
numberCaption model =
    "value: "
        ++ maybeFloat model.numberValue
        ++ " · buffer: "
        ++ Maybe.withDefault "—" model.numberBuffer
        ++ " · "
        ++ (if InputNumber.displayedValueInvalid (InputNumber.contextOf (numberOptions model)) then
                "invalid"

            else
                "valid"
           )


otpCaption : Model -> String
otpCaption model =
    let
        filled =
            List.length (List.filter (not << String.isEmpty) model.otp)
    in
    if List.length model.otp == 6 && filled == 6 then
        "complete: " ++ String.concat model.otp

    else
        String.fromInt filled ++ "/6 entered"


maybeFloat : Maybe Float -> String
maybeFloat value =
    case value of
        Nothing ->
            "—"

        Just v ->
            String.fromFloat v


pairSourceName : Maybe Input.PairSource -> String
pairSourceName source =
    case source of
        Just Input.PairFirst ->
            "first"

        Just Input.PairSecond ->
            "second"

        Just Input.PairClear ->
            "clear"

        Nothing ->
            "—"


{-| A plain demo cell for a standalone `.n-dialog` body (no fixed tree to
confine — just a sized box; the block body fills it).
-}
cell : Element msg -> Element msg
cell content =
    Element.el
        [ Element.width (Element.px 320)
        , Element.htmlAttribute
            (HA.attribute "style" "border:1px solid #efeff5;background:#fafafc")
        ]
        content



-- SECTIONS (static rows verbatim; live variants append the live demo rows)


buttonRows : Theme -> List (Element msg)
buttonRows theme =
    [ demoRow theme
        "ctl-001"
        "Sizes"
        [ Button.view theme { btn | size = T.Tiny } [ Element.text "Tiny" ]
        , Button.view theme { btn | size = T.Small } [ Element.text "Small" ]
        , Button.view theme { btn | size = T.Medium } [ Element.text "Medium" ]
        , Button.view theme { btn | size = T.Large } [ Element.text "Large" ]
        ]
    , demoRow theme
        "ctl-002"
        "Types"
        (List.map
            (\k -> Button.view theme { btn | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
            [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
        )
    , demoRow theme
        "ctl-003"
        "Variants"
        [ Button.view theme { btn | kind = T.Primary, variant = Button.Secondary } [ Element.text "Secondary" ]
        , Button.view theme { btn | kind = T.Primary, variant = Button.Tertiary } [ Element.text "Tertiary" ]
        , Button.view theme { btn | kind = T.Primary, variant = Button.Quaternary } [ Element.text "Quaternary" ]
        , Button.view theme { btn | kind = T.Primary, variant = Button.Text } [ Element.text "Text" ]
        ]
    , demoRow theme
        "ctl-004"
        "Shapes & states"
        [ Button.view theme { btn | round = True } [ Element.text "Round" ]
        , Button.view theme { btn | circle = True } [ Element.text "C" ]
        , Button.view theme { btn | dashed = True } [ Element.text "Dashed" ]
        , Button.view theme { btn | kind = T.Primary, ghost = True } [ Element.text "Ghost" ]
        , Button.view theme { btn | disabled = True } [ Element.text "Disabled" ]
        , Button.view theme { btn | loading = True } [ Element.text "Loading" ]
        ]
    , Element.el [ Element.width (Element.px 320) ]
        (Button.view theme { btn | block = True } [ Element.text "Block" ])
    , demoRow theme
        "ctl-005"
        "Group (horizontal)"
        [ ButtonGroup.view theme
            ButtonGroup.defaults
            [ Button.view theme { btn | kind = T.Primary } [ Element.text "Left" ]
            , Button.view theme { btn | kind = T.Primary } [ Element.text "Middle" ]
            , Button.view theme { btn | kind = T.Primary } [ Element.text "Right" ]
            ]
        ]
    , demoRow theme
        "ctl-006"
        "Group (vertical)"
        [ ButtonGroup.view theme
            { bgD | vertical = True }
            [ Button.view theme btn [ Element.text "Top" ]
            , Button.view theme btn [ Element.text "Bottom" ]
            ]
        ]
    ]


buttonSection : Theme -> Element msg
buttonSection theme =
    section theme "Button" "The primary action trigger, in every Naive UI kind, variant, shape and size. Supports icon slots on either side, loading state with a built-in spinner, and disabled/custom-color modes; press state is CSS-driven, and onPress is the single message channel. The rows walk sizes → kinds → variants → shapes, then a live press-counter." (buttonRows theme)


{-| Live: `#live-button-counter` / `#live-button-reset`.
-}
buttonPressRow : Model -> Theme -> Element Msg
buttonPressRow model theme =
    demoRow theme
        "ctl-007"
        "Button · press counter"
        [ Button.view theme
            { btn
                | kind = T.Primary
                , onPress = Just Press
                , attributes = [ Element.htmlAttribute (HA.id "live-button-counter") ]
            }
            [ Element.text ("Pressed " ++ String.fromInt model.presses ++ " times") ]
        , Button.view theme
            { btn
                | onPress = Just ResetPresses
                , attributes = [ Element.htmlAttribute (HA.id "live-button-reset") ]
            }
            [ Element.text "Reset" ]
        ]


buttonLiveSection : Model -> Theme -> Element Msg
buttonLiveSection model theme =
    section theme "Button" "The primary action trigger, in every Naive UI kind, variant, shape and size. Supports icon slots on either side, loading state with a built-in spinner, and disabled/custom-color modes; press state is CSS-driven, and onPress is the single message channel. The rows walk sizes → kinds → variants → shapes, then a live press-counter." (buttonRows theme ++ [ buttonPressRow model theme ])


inputRows : Theme -> List (Element msg)
inputRows theme =
    [ demoRow theme
        "ctl-008"
        "Basics"
        [ Element.el [ Element.width (Element.px 220) ]
            (Input.view theme { inputD | placeholder = Just "Placeholder" })
        , Element.el [ Element.width (Element.px 220) ]
            (Input.view theme { inputD | value = "Hello" })
        ]
    , demoRow theme
        "ctl-009"
        "Statuses"
        [ Element.el [ Element.width (Element.px 220) ]
            (Input.view theme { inputD | value = "Success", status = Just Input.Success })
        , Element.el [ Element.width (Element.px 220) ]
            (Input.view theme { inputD | value = "Warning", status = Just Input.Warning })
        , Element.el [ Element.width (Element.px 220) ]
            (Input.view theme { inputD | value = "Error", status = Just Input.Error })
        ]
    , demoRow theme
        "ctl-010"
        "States"
        [ Element.el [ Element.width (Element.px 220) ]
            (Input.view theme { inputD | value = "Disabled", disabled = True })
        , Element.el [ Element.width (Element.px 220) ]
            (Input.view theme { inputD | value = "Clearable", clearable = True })
        ]
    , demoRow theme
        "ctl-034"
        "Textarea"
        [ Element.el [ Element.width (Element.px 440) ]
            (Input.view theme
                { inputD
                    | type_ = Input.Textarea
                    , rows = 3
                    , value = "A textarea.\nMultiple lines."
                }
            )
        ]
    ]


inputSection : Theme -> Element msg
inputSection theme =
    section theme "Input" "The single-line and multi-line text field, in every Naive UI status and state. Pair inputs (date-range style), clearable, disabled and textarea modes are all options on one view. The value is caller-owned — own the field in your model; onInput/onFocus/onBlur are the channels. Rows: basics → statuses → states → textarea, then a live controlled field and a live pair input." (inputRows theme)


{-| Live: `#live-input-controlled`.
-}
inputControlledRow : Model -> Theme -> Element Msg
inputControlledRow model theme =
    demoRow theme
        "ctl-011"
        "Input · controlled + clear"
        [ Element.column [ Element.spacing 6, Element.width (Element.px 240) ]
            [ Input.view theme
                { inputD
                    | value = model.inputText
                    , onInput = Just InputChanged
                    , onFocus = Just InputFocused
                    , onBlur = Just InputBlurred
                    , clearable = True
                    , placeholder = Just "Type, then clear"
                    , inputAttributes = [ HA.id "live-input-controlled" ]
                }
            , Element.text
                ("value: \""
                    ++ model.inputText
                    ++ "\" · focus: "
                    ++ (if model.inputFocused then
                            "yes"

                        else
                            "no"
                       )
                )
            ]
        ]


{-| Live: the pair input (no own id — the caption is the observable).
-}
inputPairRow : Model -> Theme -> Element Msg
inputPairRow model theme =
    demoRow theme
        "ctl-012"
        "Input · pair (date-range-like)"
        [ Element.column [ Element.spacing 6, Element.width (Element.px 320) ]
            [ Input.view theme
                { inputD
                    | pairValue = Just model.pair
                    , pairPlaceholder = Just ( "From", "To" )
                    , separatorNode = Just (Element.text "→")
                    , clearable = True
                    , onPairInput = Just (\( first, second ) source -> PairInput first second source)
                }
            , Element.text ("pair: " ++ Tuple.first model.pair ++ " → " ++ Tuple.second model.pair ++ " · last edit: " ++ pairSourceName model.pairSource)
            ]
        ]


inputLiveSection : Model -> Theme -> Element Msg
inputLiveSection model theme =
    section theme
        "Input"
        "The single-line and multi-line text field, in every Naive UI status and state. Pair inputs (date-range style), clearable, disabled and textarea modes are all options on one view. The value is caller-owned — own the field in your model; onInput/onFocus/onBlur are the channels. Rows: basics → statuses → states → textarea, then a live controlled field and a live pair input."
        (inputRows theme ++ [ inputControlledRow model theme, inputPairRow model theme ])


inputOtpRows : Theme -> List (Element msg)
inputOtpRows theme =
    [ demoRow theme
        "ctl-013"
        "Lengths & sizes"
        [ InputOtp.view theme { iotpD | length = 4, value = [ "1", "2", "3", "4" ] } []
        , InputOtp.view theme { iotpD | length = 6, size = InputOtp.Small, gap = Just (InputOtp.Px 6) } []
        , InputOtp.view theme { iotpD | length = 6, mask = True } []
        ]
    , demoRow theme
        "ctl-014"
        "RTL"
        [ InputOtp.view theme { iotpD | rtl = True, length = 6, value = [ "8", "8", "8" ] } []
        ]
    ]


inputOtpSection : Theme -> Element msg
inputOtpSection theme =
    section theme "Input OTP" "One-time passcode entry: a row of single-character slots with mask, RTL and size/gap options. The value is caller-owned — it is a List String of filled slots, and the view renders exactly what you pass; the focus slot (and the auto-advance on typing) is yours to drive via Browser.Dom. Rows: lengths & sizes → RTL, then a live completion demo with reset and mask toggles." (inputOtpRows theme)


{-| Live: `#live-input-otp` / `#live-input-otp-reset` / `#live-input-otp-mask`.
-}
inputOtpCompletionRow : Model -> Theme -> Element Msg
inputOtpCompletionRow model theme =
    demoRow theme
        "ctl-015"
        "InputOtp · completion"
        [ Element.column [ Element.spacing 8 ]
            [ InputOtp.view theme (otpOptions model) []
            , Element.row [ Element.spacing 8 ]
                [ smallButton theme "live-input-otp-reset" "Reset" OtpReset
                , smallButton theme "live-input-otp-mask" "Mask" OtpMaskToggled
                , Element.text (otpCaption model)
                ]
            ]
        ]


inputOtpLiveSection : Model -> Theme -> Element Msg
inputOtpLiveSection model theme =
    section theme
        "Input OTP"
        "One-time passcode entry: a row of single-character slots with mask, RTL and size/gap options. The value is caller-owned — it is a List String of filled slots, and the view renders exactly what you pass; the focus slot (and the auto-advance on typing) is yours to drive via Browser.Dom. Rows: lengths & sizes → RTL, then a live completion demo with reset and mask toggles."
        (inputOtpRows theme ++ [ inputOtpCompletionRow model theme ])


inputNumberRows : Theme -> List (Element msg)
inputNumberRows theme =
    [ demoRow theme
        "ctl-035"
        "Basic"
        [ InputNumber.view theme { inD | value = Just 3 } []
        , InputNumber.view theme { inD | value = Just 42, buttonPlacement = InputNumber.Both } []
        , InputNumber.view theme { inD | value = Nothing, placeholder = Just "Enter a number" } []
        , InputNumber.view theme { inD | value = Just 7, disabled = True } []
        ]
    , demoRow theme
        "ctl-036"
        "Precision (min/max/step)"
        [ InputNumber.view theme
            { inD
                | value = Just 0.5
                , min = Just 0
                , max = Just 1
                , step = 0.01
                , precision = Just 2
            }
            []
        ]
    ]


inputNumberSection : Theme -> Element msg
inputNumberSection theme =
    section theme "Input Number" "A numeric stepper: a text field plus add/minus buttons, with min/max clamping, fixed step, precision and placeholder modes. The text buffer is caller-owned — the caller owns the field in your model and the port ships the pure parse/commit algebra (inputUpdate, deriveValueFromDisplayedValue). Rows: basic placements → precision clamping, then a live stepper with a real commit button." (inputNumberRows theme)


{-| Live: `#live-input-number-stepper` / `#live-input-number-commit`.
-}
inputNumberStepperRow : Model -> Theme -> Element Msg
inputNumberStepperRow model theme =
    demoRow theme
        "ctl-016"
        "InputNumber · stepper + commit"
        [ InputNumber.view theme (numberOptions model) []
        , Button.view theme
            { btn
                | size = T.Small
                , onPress = Just NumberCommit
                , attributes = [ Element.htmlAttribute (HA.id "live-input-number-commit") ]
            }
            [ Element.text "Commit" ]
        , Element.text (numberCaption model)
        ]


inputNumberLiveSection : Model -> Theme -> Element Msg
inputNumberLiveSection model theme =
    section theme
        "Input Number"
        "A numeric stepper: a text field plus add/minus buttons, with min/max clamping, fixed step, precision and placeholder modes. The text buffer is caller-owned — the caller owns the field in your model and the port ships the pure parse/commit algebra (inputUpdate, deriveValueFromDisplayedValue). Rows: basic placements → precision clamping, then a live stepper with a real commit button."
        (inputNumberRows theme ++ [ inputNumberStepperRow model theme ])


selectionRows : Theme -> List (Element msg)
selectionRows theme =
    [ demoRow theme
        "ctl-017"
        "Checkbox"
        [ Checkbox.view theme { cbD | checked = True } [ Element.text "Checked" ]
        , Checkbox.view theme cbD [ Element.text "Unchecked" ]
        , Checkbox.view theme { cbD | indeterminate = True } [ Element.text "Indeterminate" ]
        , Checkbox.view theme { cbD | disabled = True, checked = True } [ Element.text "Disabled" ]
        ]
    , demoRow theme
        "ctl-018"
        "Switch"
        [ Switch.view theme { swD | value = False } []
        , Switch.view theme { swD | value = True } []
        , Switch.view theme { swD | value = True, loading = True } []
        , Switch.view theme { swD | value = False, disabled = True } []
        ]
    , demoRow theme
        "ctl-019"
        "Radio group"
        [ Radio.group theme
            { radioGD | value = Just "sh" }
            [ Radio.choice "bj" "Beijing", Radio.choice "sh" "Shanghai", Radio.choice "gz" "Guangzhou" ]
        ]
    , demoRow theme
        "ctl-020"
        "Radio button group"
        [ Radio.group theme
            { radioGD | value = Just "m" }
            [ Radio.button "s" "Small", Radio.button "m" "Medium", Radio.button "l" "Large" ]
        ]
    , demoRow theme
        "ctl-021"
        "Radio standalone"
        [ Radio.view theme { radioD | checked = True } [ Element.text "Selected" ]
        , Radio.view theme radioD [ Element.text "Unselected" ]
        , Radio.view theme { radioD | disabled = True } [ Element.text "Disabled" ]
        ]
    ]


selectionSection : Theme -> Element msg
selectionSection theme =
    section theme "Checkbox · Switch · Radio" "The three boolean-and-choice primitives. Checkbox covers checked, indeterminate and disabled; Switch is the loading/disabled on-off; Radio ships standalone, group and button-group forms. All state is caller-owned — own the Bool (or the picked key) in your model and feed it back on every channel. Rows: each control's states, then a live switch toggle, a live checkbox group with an indeterminate master, and a live radio group." (selectionRows theme)


{-| Live: `#live-switch-toggle` (caption read via the row's textContent —
the switch and the caption stay the only children of the row body).
-}
switchToggleRow : Model -> Theme -> Element Msg
switchToggleRow model theme =
    demoRow theme
        "ctl-022"
        "Switch · toggle"
        [ Element.el [ Element.htmlAttribute (HA.id "live-switch-toggle") ]
            (Switch.view theme
                { swD | value = model.switchOn, onChange = Just SwitchToggled }
                []
            )
        , Element.text
            (if model.switchOn then
                "on"

             else
                "off"
            )
        ]


{-| Live: `#live-checkbox-master` / `#live-checkbox-item-<i>` (generated).
-}
checkboxGroupRow : Model -> Theme -> Element Msg
checkboxGroupRow model theme =
    demoRow theme
        "ctl-023"
        "Checkbox · group + indeterminate master"
        [ Element.column [ Element.spacing 8 ]
            [ Element.el [ Element.htmlAttribute (HA.id "live-checkbox-master") ]
                (Checkbox.view theme
                    { cbD
                        | checked = List.all identity model.checks
                        , indeterminate = masterIndeterminate model
                        , onCheck = Just CheckMaster
                    }
                    [ Element.text "Check all" ]
                )
            , Element.row [ Element.spacing 16 ]
                (List.indexedMap (itemCheckbox theme model) model.checks)
            , Element.text
                ("checked: "
                    ++ String.fromInt (List.length (List.filter identity model.checks))
                    ++ "/"
                    ++ String.fromInt (List.length model.checks)
                    ++ (if masterIndeterminate model then
                            " · master indeterminate"

                        else
                            ""
                       )
                )
            ]
        ]


{-| Live: `#live-radio-group`.
-}
radioPickRow : Model -> Theme -> Element Msg
radioPickRow model theme =
    demoRow theme
        "ctl-024"
        "Radio.Group · pick one"
        [ Radio.group theme
            { radioGD
                | value = model.city
                , onChange = Just RadioPicked
                , attributes = [ Element.htmlAttribute (HA.id "live-radio-group") ]
            }
            [ Radio.choice "bj" "Beijing"
            , Radio.choice "sh" "Shanghai"
            , Radio.choice "gz" "Guangzhou"
            ]
        , Element.text ("picked: " ++ Maybe.withDefault "—" model.city)
        ]


selectionLiveSection : Model -> Theme -> Element Msg
selectionLiveSection model theme =
    section theme
        "Checkbox · Switch · Radio"
        "The three boolean-and-choice primitives. Checkbox covers checked, indeterminate and disabled; Switch is the loading/disabled on-off; Radio ships standalone, group and button-group forms. All state is caller-owned — own the Bool (or the picked key) in your model and feed it back on every channel. Rows: each control's states, then a live switch toggle, a live checkbox group with an indeterminate master, and a live radio group."
        (selectionRows theme ++ [ switchToggleRow model theme, checkboxGroupRow model theme, radioPickRow model theme ])


rateRows : Theme -> List (Element msg)
rateRows theme =
    [ demoRow theme
        "ctl-025"
        "Value"
        [ Rate.view theme { rateD | value = Just 4 }
        , Rate.view theme { rateD | value = Just 3, readonly = True }
        , Rate.view theme { rateD | value = Just 2, color = Just "#f0a020" }
        ]
    , demoRow theme
        "ctl-026"
        "Half & sizes"
        [ Rate.view theme { rateD | allowHalf = True, value = Just 3.5 }
        , Rate.view theme { rateD | size = Rate.Small, value = Just 5 }
        , Rate.view theme { rateD | size = Rate.Large, value = Just 5 }
        ]
    ]


rateSection : Theme -> Element msg
rateSection theme =
    section theme "Rate" "A star rating with half-star precision, three sizes, custom color and readonly modes. The value and the hover preview are caller-owned — the view renders value and hoverValue as given, onSelect commits a star and the hover preview is pointer-position algebra you own. Rows: fixed values → half & sizes, then a live demo committing real values alongside a simulated hover preview." (rateRows theme)


{-| Live: `#live-rate` / `#live-rate-hover-*` (hover preview is
button-simulated — see the oracle note above).
-}
rateHoverRow : Model -> Theme -> Element Msg
rateHoverRow model theme =
    demoRow theme
        "ctl-027"
        "Rate · hover preview + commit"
        [ Rate.view theme (rateOptions model)
        , Button.view theme
            { btn | size = T.Small, onPress = Just (RateNudge -0.5), attributes = [ Element.htmlAttribute (HA.id "live-rate-hover-minus") ] }
            [ Element.text "hover −½" ]
        , Button.view theme
            { btn | size = T.Small, onPress = Just (RateNudge 0.5), attributes = [ Element.htmlAttribute (HA.id "live-rate-hover-plus") ] }
            [ Element.text "hover +½" ]
        , Button.view theme
            { btn | size = T.Small, onPress = Just RatePreviewClear, attributes = [ Element.htmlAttribute (HA.id "live-rate-hover-clear") ] }
            [ Element.text "clear hover" ]
        , Element.text
            ("hovered: "
                ++ maybeFloat model.rateHover
                ++ " · committed: "
                ++ maybeFloat model.rateValue
            )
        ]


rateLiveSection : Model -> Theme -> Element Msg
rateLiveSection model theme =
    section theme
        "Rate"
        "A star rating with half-star precision, three sizes, custom color and readonly modes. The value and the hover preview are caller-owned — the view renders value and hoverValue as given, onSelect commits a star and the hover preview is pointer-position algebra you own. Rows: fixed values → half & sizes, then a live demo committing real values alongside a simulated hover preview."
        (rateRows theme ++ [ rateHoverRow model theme ])


sliderRows : Model -> Theme -> List (Element Msg)
sliderRows model theme =
    [ demoRowUnfenced theme
        "ctl-028"
        "Single + range (marks feed dots/marks/snap; drags live)"
        [ cell (sliderCell theme (rowOf model "live-slider-marked"))
        , cell (sliderCell theme (rowOf model "live-slider-range-marks"))
        ]
    , demoRowUnfenced theme
        "ctl-029"
        "Tooltip indicator (pinned via hoverIndex / drag) + disabled"
        [ cell
            (Element.el [ Element.width (Element.px 240) ]
                (Slider.view theme
                    { sliderD | value = [ 66 ], hoverIndex = 0, activeIndex = 0, dragging = True }
                )
            )
        , cell
            (Element.el [ Element.width (Element.px 240) ]
                (Slider.view theme
                    { sliderD
                        | value = [ 12 ]
                        , disabled = True
                        , formatTooltip = Just (\v -> String.fromFloat v ++ "%")
                    }
                )
            )
        ]
    , demoRowUnfenced theme
        "ctl-030"
        "Vertical + reverse (direction keys flip, dots still 34/75; drags live)"
        [ cell (sliderCell theme (rowOf model "live-slider-vertical"))
        , cell (sliderCell theme (rowOf model "live-slider-vertical-reverse"))
        ]
    , demoRowUnfenced theme
        "ctl-031"
        "Range snap (`step: 'mark'`) + >2 values (fill suppressed, dots inactive — upstream quirk; drags live)"
        [ cell (sliderCell theme (rowOf model "live-slider-snap"))
        , cell (sliderCell theme (rowOf model "live-slider-multi"))
        ]
    ]


{-| One draggable cell: the spec-driven slider — 240px wide horizontal,
220px tall vertical. The row-state lookup goes through `specOf`'s table —
a typo'd id falls back to `singleSpec` (never a crash).
-}
sliderCell : Theme -> ( Spec, RowState ) -> Element Msg
sliderCell theme ( spec, row ) =
    Element.el
        (if spec.vertical then
            [ Element.height (Element.px 220) ]

         else
            [ Element.width (Element.px 240) ]
        )
        (Slider.view theme (sliderOptions spec row))


rowOf : Model -> String -> ( Spec, RowState )
rowOf model id =
    ( specOf id, Dict.get id model.sliders |> Maybe.withDefault { value = (specOf id).init, active = -1, hover = -1, drag = Nothing } )


sliderSection : Model -> Theme -> Element Msg
sliderSection model theme =
    section theme
        "Slider"
        "The rail/fill/handles numeric input (upstream `NSlider`). Drag is caller-owned runtime: value, activeIndex, hoverIndex and dragging go in, discrete handle events plus the root mousedown signal come out, and pointerToValue/sanitizeValue/stepValue carry the pointer-to-snap math. Every row below is a live drag (mousedown → document mousemove/mouseup), plus a pinned-indicator fixture and a disabled rail. Rows: single & range with marks → indicator states → vertical/reverse → snap and >2-handle ranges, then a step-algebra single and a closest-handle range."
        (sliderRows model theme)


{-| Live: `#live-slider-single` / `#live-slider-minus` / `#live-slider-plus`
(drag via the root press seam + the document mousemove/mouseup pair).
-}
sliderSingleRow : Model -> Theme -> Element Msg
sliderSingleRow model theme =
    let
        ( spec, row ) =
            rowOf model "live-slider-single"
    in
    demoRowUnfenced theme
        "ctl-032"
        "Slider · single (drag + hover/focus indicator + arrow-step algebra)"
        [ Element.column [ Element.spacing 6, Element.width (Element.px 260) ]
            [ Slider.view theme (sliderOptions spec row)
            , Element.row [ Element.spacing 8 ]
                [ smallButton theme "live-slider-minus" "−1" (SliderMsg "live-slider-single" (Nudge 0 -1))
                , smallButton theme "live-slider-plus" "+1" (SliderMsg "live-slider-single" (Nudge 0 1))
                , Element.text
                    (String.fromFloat (Maybe.withDefault 0 (List.head row.value))
                        ++ " ("
                        ++ String.fromFloat (Slider.valueToPercentage spec.min spec.max (Maybe.withDefault 0 (List.head row.value)))
                        ++ "%)"
                    )
                ]
            ]
        ]


{-| Live: `#live-slider-range` / `#live-range-*` (drag picks the closest
handle; per-handle steps; handles can cross — see the oracle note above).
-}
sliderRangeRow : Model -> Theme -> Element Msg
sliderRangeRow model theme =
    let
        ( spec, row ) =
            rowOf model "live-slider-range"
    in
    demoRowUnfenced theme
        "ctl-033"
        "Slider · range (drag picks the closest handle; per-handle steps, marks snap)"
        [ Element.column [ Element.spacing 6, Element.width (Element.px 260) ]
            [ Slider.view theme (sliderOptions spec row)
            , Element.row [ Element.spacing 8 ]
                [ smallButton theme "live-range-lo-minus" "lo −" (SliderMsg "live-slider-range" (Nudge 0 -1))
                , smallButton theme "live-range-lo-plus" "lo +" (SliderMsg "live-slider-range" (Nudge 0 1))
                , smallButton theme "live-range-hi-minus" "hi −" (SliderMsg "live-slider-range" (Nudge 1 -1))
                , smallButton theme "live-range-hi-plus" "hi +" (SliderMsg "live-slider-range" (Nudge 1 1))
                , Element.text
                    (String.fromFloat (Maybe.withDefault 0 (List.head row.value))
                        ++ " – "
                        ++ String.fromFloat (Maybe.withDefault 0 (List.head (List.drop 1 row.value)))
                    )
                ]
            ]
        ]


sliderLiveSection : Model -> Theme -> Element Msg
sliderLiveSection model theme =
    section theme
        "Slider"
        "The rail/fill/handles numeric input (upstream `NSlider`). Drag is caller-owned runtime: value, activeIndex, hoverIndex and dragging go in, discrete handle events plus the root mousedown signal come out, and pointerToValue/sanitizeValue/stepValue carry the pointer-to-snap math. Every row below is a live drag (mousedown → document mousemove/mouseup), plus a pinned-indicator fixture and a disabled rail. Rows: single & range with marks → indicator states → vertical/reverse → snap and >2-handle ranges, then a step-algebra single and a closest-handle range."
        (sliderRows model theme ++ [ sliderSingleRow model theme, sliderRangeRow model theme ])


{-| The family body in Main.body order — live variants where live demos
exist, legacy sections elsewhere (here every section has a live variant).
-}
sections : Model -> Theme -> List (Element Msg)
sections model theme =
    [ buttonLiveSection model theme
    , inputLiveSection model theme
    , inputOtpLiveSection model theme
    , inputNumberLiveSection model theme
    , selectionLiveSection model theme
    , rateLiveSection model theme
    , sliderLiveSection model theme
    ]
