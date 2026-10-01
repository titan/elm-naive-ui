module Live.Controls exposing (Model, Msg, init, subscriptions, update, view)

{-| LIVE demos — a real update loop for the controls family: Button, Input,
InputNumber, Switch, Checkbox, Radio, Rate, Slider, InputOtp.

Caller-owned state per the port's contract: the component renders whatever
the model says; every channel feeds one Msg constructor. Where the port
ships the interaction algebra as pure helpers, update uses those instead
of re-deriving semantics (`InputNumber.inputUpdate` /
`deriveValueFromDisplayedValue`, `Slider.stepValue`).

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

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Button as Button
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
import Showcase exposing (demoRow)



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
    , slider : Float
    , sliderActive : Int
    , sliderHover : Int
    , sliderDragging : Bool
    , range : ( Float, Float )
    , rangeActive : Int
    , rangeHover : Int
    , rangeDragging : Bool
    , otp : List String
    , otpMasked : Bool
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
    , slider = 40
    , sliderActive = -1
    , sliderHover = -1
    , sliderDragging = False
    , range = ( 20, 60 )
    , rangeActive = -1
    , rangeHover = -1
    , rangeDragging = False
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
    | SliderStep Int
    | SliderMousedown
    | SliderFocus
    | SliderBlur
    | SliderEnter
    | SliderLeave
    | RangeStep Int Int
    | RangeMousedown
    | RangeFocus Int
    | RangeBlur Int
    | RangeEnter Int
    | RangeLeave Int
    | OtpChanged (List String)
    | OtpReset
    | OtpMaskToggled


update : Msg -> Model -> Model
update msg model =
    case msg of
        Press ->
            { model | presses = model.presses + 1 }

        ResetPresses ->
            { model | presses = 0 }

        InputChanged raw ->
            { model | inputText = raw }

        InputFocused ->
            { model | inputFocused = True }

        InputBlurred ->
            { model | inputFocused = False }

        PairInput first second source ->
            { model | pair = ( first, second ), pairSource = Just source }

        NumberInput raw ->
            -- the port's handleUpdateDisplayedValue: keep the raw buffer,
            -- live-sync value when the option allows it
            { model
                | numberBuffer = Just raw
                , numberValue =
                    case InputNumber.inputUpdate (numberOptions model) raw of
                        Just updated ->
                            updated

                        Nothing ->
                            model.numberValue
            }

        NumberChanged payload ->
            -- add / minus buttons (via addUpdate / minusUpdate inside view)
            { model | numberValue = payload, numberBuffer = Nothing }

        NumberCommit ->
            -- the caller-owned blur / Enter commit, verbatim upstream args
            case
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

        SwitchToggled on ->
            { model | switchOn = on }

        CheckItem index on ->
            { model
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

        CheckMaster on ->
            { model | checks = List.map (always on) model.checks }

        RadioPicked value ->
            { model | city = Just value }

        RateSelected value ->
            { model | rateValue = Just value }

        RateNudge delta ->
            let
                base =
                    Maybe.withDefault (Maybe.withDefault 0 model.rateValue) model.rateHover
            in
            { model | rateHover = Just (clamp 0 5 (base + delta)) }

        RatePreviewClear ->
            { model | rateHover = Nothing }

        SliderStep ratio ->
            { model | slider = Slider.stepValue singleConfig model.slider ratio }

        SliderMousedown ->
            { model | sliderDragging = True, sliderActive = 0 }

        SliderFocus ->
            { model | sliderActive = 0 }

        SliderBlur ->
            { model | sliderActive = -1, sliderDragging = False }

        SliderEnter ->
            { model | sliderHover = 0 }

        SliderLeave ->
            { model | sliderHover = -1 }

        RangeStep index ratio ->
            let
                ( lo, hi ) =
                    model.range

                next =
                    Slider.stepValue rangeConfig
                        (if index == 0 then
                            lo

                         else
                            hi
                        )
                        ratio
            in
            { model
                | range =
                    if index == 0 then
                        ( next, hi )

                    else
                        ( lo, next )
            }

        RangeMousedown ->
            { model | rangeDragging = True, rangeActive = 0 }

        RangeFocus index ->
            { model | rangeActive = index }

        RangeBlur _ ->
            { model | rangeActive = -1, rangeDragging = False }

        RangeEnter index ->
            { model | rangeHover = index }

        RangeLeave _ ->
            { model | rangeHover = -1 }

        OtpChanged value ->
            { model | otp = value }

        OtpReset ->
            { model | otp = [] }

        OtpMaskToggled ->
            { model | otpMasked = not model.otpMasked }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW (same visual grammar as the static sections)


view : Theme -> Model -> Element Msg
view theme model =
    Element.column [ Element.spacing 20, Element.width Element.fill ]
        [ demoRow "Button · press counter"
            [ Button.view theme
                { btnD
                    | kind = T.Primary
                    , onPress = Just Press
                    , attributes = [ Element.htmlAttribute (HA.id "live-button-counter") ]
                }
                [ Element.text ("Pressed " ++ String.fromInt model.presses ++ " times") ]
            , Button.view theme
                { btnD
                    | onPress = Just ResetPresses
                    , attributes = [ Element.htmlAttribute (HA.id "live-button-reset") ]
                }
                [ Element.text "Reset" ]
            ]
        , demoRow "Input · controlled + clear"
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
        , demoRow "Input · pair (date-range-like)"
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
        , demoRow "InputNumber · stepper + commit"
            [ InputNumber.view theme (numberOptions model) []
            , Button.view theme
                { btnD
                    | size = T.Small
                    , onPress = Just NumberCommit
                    , attributes = [ Element.htmlAttribute (HA.id "live-input-number-commit") ]
                }
                [ Element.text "Commit" ]
            , Element.text (numberCaption model)
            ]
        , demoRow "Switch · toggle"
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
        , demoRow "Checkbox · group + indeterminate master"
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
        , demoRow "Radio.Group · pick one"
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
        , demoRow "Rate · hover preview + commit"
            [ Rate.view theme (rateOptions model)
            , Button.view theme
                { btnD | size = T.Small, onPress = Just (RateNudge -0.5), attributes = [ Element.htmlAttribute (HA.id "live-rate-hover-minus") ] }
                [ Element.text "hover −½" ]
            , Button.view theme
                { btnD | size = T.Small, onPress = Just (RateNudge 0.5), attributes = [ Element.htmlAttribute (HA.id "live-rate-hover-plus") ] }
                [ Element.text "hover +½" ]
            , Button.view theme
                { btnD | size = T.Small, onPress = Just RatePreviewClear, attributes = [ Element.htmlAttribute (HA.id "live-rate-hover-clear") ] }
                [ Element.text "clear hover" ]
            , Element.text
                ("hovered: "
                    ++ maybeFloat model.rateHover
                    ++ " · committed: "
                    ++ maybeFloat model.rateValue
                )
            ]
        , demoRow "Slider · single (hover/focus indicator + arrow-step algebra)"
            [ Element.column [ Element.spacing 6, Element.width (Element.px 260) ]
                [ Slider.view theme (sliderOptions model)
                , Element.row [ Element.spacing 8 ]
                    [ smallButton theme "live-slider-minus" "−1" (SliderStep -1)
                    , smallButton theme "live-slider-plus" "+1" (SliderStep 1)
                    , Element.text
                        (String.fromFloat model.slider
                            ++ " ("
                            ++ String.fromFloat (Slider.valueToPercentage 0 100 model.slider)
                            ++ "%)"
                        )
                    ]
                ]
            ]
        , demoRow "Slider · range (per-handle steps, marks snap)"
            [ Element.column [ Element.spacing 6, Element.width (Element.px 260) ]
                [ Slider.view theme (rangeOptions model)
                , Element.row [ Element.spacing 8 ]
                    [ smallButton theme "live-range-lo-minus" "lo −" (RangeStep 0 -1)
                    , smallButton theme "live-range-lo-plus" "lo +" (RangeStep 0 1)
                    , smallButton theme "live-range-hi-minus" "hi −" (RangeStep 1 -1)
                    , smallButton theme "live-range-hi-plus" "hi +" (RangeStep 1 1)
                    , Element.text
                        (String.fromFloat (Tuple.first model.range)
                            ++ " – "
                            ++ String.fromFloat (Tuple.second model.range)
                        )
                    ]
                ]
            ]
        , demoRow "InputOtp · completion"
            [ Element.column [ Element.spacing 8 ]
                [ InputOtp.view theme (otpOptions model) []
                , Element.row [ Element.spacing 8 ]
                    [ smallButton theme "live-input-otp-reset" "Reset" OtpReset
                    , smallButton theme "live-input-otp-mask" "Mask" OtpMaskToggled
                    , Element.text (otpCaption model)
                    ]
                ]
            ]
        ]



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


btnD : Button.Options msg
btnD =
    Button.defaults


inputD : Input.Options msg
inputD =
    Input.defaults


swD : Switch.Options msg
swD =
    Switch.defaults


cbD : Checkbox.Options msg
cbD =
    Checkbox.defaults


radioGD : Radio.GroupOptions String msg
radioGD =
    Radio.groupDefaults


rateD : Rate.Options msg
rateD =
    Rate.defaults


sliderD : Slider.Options msg
sliderD =
    Slider.defaults


iotpD : InputOtp.Options msg
iotpD =
    InputOtp.defaults


inD : InputNumber.Options msg
inD =
    InputNumber.defaults



-- OPTIONS BUILDERS


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


sliderOptions : Model -> Slider.Options Msg
sliderOptions model =
    { sliderD
        | value = [ model.slider ]
        , activeIndex = model.sliderActive
        , hoverIndex = model.sliderHover
        , dragging = model.sliderDragging
        , onMousedown = Just SliderMousedown
        , onHandleFocus = Just (\_ -> SliderFocus)
        , onHandleBlur = Just (\_ -> SliderBlur)
        , onHandleMouseEnter = Just (\_ -> SliderEnter)
        , onHandleMouseLeave = Just (\_ -> SliderLeave)
        , attributes = [ Element.htmlAttribute (HA.id "live-slider-single") ]
    }


rangeOptions : Model -> Slider.Options Msg
rangeOptions model =
    { sliderD
        | range = True
        , value = [ Tuple.first model.range, Tuple.second model.range ]
        , marks = rangeMarks
        , activeIndex = model.rangeActive
        , hoverIndex = model.rangeHover
        , dragging = model.rangeDragging
        , onMousedown = Just RangeMousedown
        , onHandleFocus = Just RangeFocus
        , onHandleBlur = Just RangeBlur
        , onHandleMouseEnter = Just RangeEnter
        , onHandleMouseLeave = Just RangeLeave
        , attributes = [ Element.htmlAttribute (HA.id "live-slider-range") ]
    }


otpOptions : Model -> InputOtp.Options Msg
otpOptions model =
    { iotpD
        | value = model.otp
        , length = 6
        , allowInput = Just (\char _ _ -> String.all Char.isDigit char)
        , mask = model.otpMasked
        , onUpdateValue = Just OtpChanged
        , attributes = [ Element.htmlAttribute (HA.id "live-input-otp") ]
    }


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
        { btnD
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
