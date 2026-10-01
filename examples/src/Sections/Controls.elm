module Sections.Controls exposing
    ( buttonSection
    , inputNumberSection
    , inputOtpSection
    , inputSection
    , rateSection
    , selectionSection
    , sliderSection
    )

{-| Static showcase sections for the Controls family (Button, Input, Input OTP,
Input Number, Checkbox · Switch · Radio, Rate, Slider), moved verbatim from
Main.elm — the rendered DOM must stay byte-identical (the check-dom gate reads
this surface).
-}

import Element exposing (Element)
import Html.Attributes as HA
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
import NUI.Types as T
import Showcase exposing (capitalize, demoRow, section, theme)



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



-- SECTIONS


buttonSection : Element msg
buttonSection =
    section "Button" "Sizes, types, variants and shapes." <|
        [ demoRow "Sizes"
            [ Button.view theme { btn | size = T.Tiny } [ Element.text "Tiny" ]
            , Button.view theme { btn | size = T.Small } [ Element.text "Small" ]
            , Button.view theme { btn | size = T.Medium } [ Element.text "Medium" ]
            , Button.view theme { btn | size = T.Large } [ Element.text "Large" ]
            ]
        , demoRow "Types"
            (List.map
                (\k -> Button.view theme { btn | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
                [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
            )
        , demoRow "Variants"
            [ Button.view theme { btn | kind = T.Primary, variant = Button.Secondary } [ Element.text "Secondary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Tertiary } [ Element.text "Tertiary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Quaternary } [ Element.text "Quaternary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Text } [ Element.text "Text" ]
            ]
        , demoRow "Shapes & states"
            [ Button.view theme { btn | round = True } [ Element.text "Round" ]
            , Button.view theme { btn | circle = True } [ Element.text "C" ]
            , Button.view theme { btn | dashed = True } [ Element.text "Dashed" ]
            , Button.view theme { btn | kind = T.Primary, ghost = True } [ Element.text "Ghost" ]
            , Button.view theme { btn | disabled = True } [ Element.text "Disabled" ]
            , Button.view theme { btn | loading = True } [ Element.text "Loading" ]
            ]
        , Element.el [ Element.width (Element.px 320) ]
            (Button.view theme { btn | block = True } [ Element.text "Block" ])
        , demoRow "Group"
            [ ButtonGroup.view theme
                ButtonGroup.defaults
                [ Button.view theme { btn | kind = T.Primary } [ Element.text "Left" ]
                , Button.view theme { btn | kind = T.Primary } [ Element.text "Middle" ]
                , Button.view theme { btn | kind = T.Primary } [ Element.text "Right" ]
                ]
            , ButtonGroup.view theme
                { bgD | vertical = True }
                [ Button.view theme btn [ Element.text "Top" ]
                , Button.view theme btn [ Element.text "Bottom" ]
                ]
            ]
        ]


inputSection : Element msg
inputSection =
    section "Input" "Text fields, statuses and a textarea." <|
        [ demoRow "Basics"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | placeholder = Just "Placeholder" })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Hello", round = True })
            ]
        , demoRow "Statuses"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Success", status = Just Input.Success })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Warning", status = Just Input.Warning })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Error", status = Just Input.Error })
            ]
        , demoRow "States"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Disabled", disabled = True })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Clearable", clearable = True })
            ]
        , Element.el [ Element.width (Element.px 440) ]
            (Input.view theme
                { inputD
                    | type_ = Input.Textarea
                    , rows = 3
                    , value = "A textarea.\nMultiple lines."
                }
            )
        ]


inputOtpSection : Element msg
inputOtpSection =
    section "Input OTP" "One-time-code inputs (the value and focus are caller-owned)." <|
        [ demoRow "Lengths & sizes"
            [ InputOtp.view theme { iotpD | length = 4, value = [ "1", "2", "3", "4" ] } []
            , InputOtp.view theme { iotpD | length = 6, size = InputOtp.Small, gap = Just (InputOtp.Px 6) } []
            , InputOtp.view theme { iotpD | length = 6, mask = True } []
            ]
        , demoRow "RTL"
            [ InputOtp.view theme { iotpD | rtl = True, length = 6, value = [ "8", "8", "8" ] } []
            ]
        ]


inputNumberSection : Element msg
inputNumberSection =
    section "Input Number" "Numeric entry (the text buffer is caller-owned)." <|
        [ InputNumber.view theme { inD | value = Just 3 } []
        , InputNumber.view theme
            { inD
                | value = Just 0.5
                , min = Just 0
                , max = Just 1
                , step = 0.01
                , precision = Just 2
            }
            []
        , InputNumber.view theme { inD | value = Just 42, buttonPlacement = InputNumber.Both } []
        , InputNumber.view theme { inD | value = Nothing, placeholder = Just "Enter a number" } []
        , InputNumber.view theme { inD | value = Just 7, disabled = True } []
        ]


selectionSection : Element msg
selectionSection =
    section "Checkbox · Switch · Radio" "Selection controls." <|
        [ demoRow "Checkbox"
            [ Checkbox.view theme { cbD | checked = True } [ Element.text "Checked" ]
            , Checkbox.view theme cbD [ Element.text "Unchecked" ]
            , Checkbox.view theme { cbD | indeterminate = True } [ Element.text "Indeterminate" ]
            , Checkbox.view theme { cbD | disabled = True, checked = True } [ Element.text "Disabled" ]
            ]
        , demoRow "Switch"
            [ Switch.view theme { swD | value = False } []
            , Switch.view theme { swD | value = True } []
            , Switch.view theme { swD | value = True, loading = True } []
            , Switch.view theme { swD | value = False, disabled = True } []
            ]
        , demoRow "Radio group"
            [ Radio.group theme
                { radioGD | value = Just "sh" }
                [ Radio.choice "bj" "Beijing", Radio.choice "sh" "Shanghai", Radio.choice "gz" "Guangzhou" ]
            ]
        , demoRow "Radio button group"
            [ Radio.group theme
                { radioGD | value = Just "m" }
                [ Radio.button "s" "Small", Radio.button "m" "Medium", Radio.button "l" "Large" ]
            ]
        , demoRow "Radio standalone"
            [ Radio.view theme { radioD | checked = True } [ Element.text "Selected" ]
            , Radio.view theme radioD [ Element.text "Unselected" ]
            , Radio.view theme { radioD | disabled = True } [ Element.text "Disabled" ]
            ]
        ]


rateSection : Element msg
rateSection =
    section "Rate" "Star ratings (the value and hover are caller-owned)." <|
        [ demoRow "Value"
            [ Rate.view theme { rateD | value = Just 4 }
            , Rate.view theme { rateD | value = Just 3, readonly = True }
            , Rate.view theme { rateD | value = Just 2, color = Just "#f0a020" }
            ]
        , demoRow "Half & sizes"
            [ Rate.view theme { rateD | allowHalf = True, value = Just 3.5 }
            , Rate.view theme { rateD | size = Rate.Small, value = Just 5 }
            , Rate.view theme { rateD | size = Rate.Large, value = Just 5 }
            ]
        ]


sliderD : Slider.Options msg
sliderD =
    Slider.defaults


sliderMarks : List Slider.Mark
sliderMarks =
    [ { value = 34, label = "34" }
    , { value = 75, label = "75" }
    ]


sliderSection : Element msg
sliderSection =
    section "Slider"
        "The rail/fill/handles numeric input (upstream `NSlider`). Drag is caller-owned runtime (`NUI.Split` precedent): `value`/`activeIndex`/`hoverIndex`/`dragging` in, discrete handle events + the root mousedown signal out; `pointerToValue`/`sanitizeValue`/`stepValue` carry the pointer→snap math. The value indicator renders inline (the teleported follower is the caller's popover seam)."
    <|
        [ demoRow "Single + range (fixed state; marks feed dots/marks/snap)"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD
                            | value = [ 40 ]
                            , marks = sliderMarks
                        }
                    )
                )
            , cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD
                            | range = True
                            , value = [ 24, 49 ]
                            , marks = sliderMarks
                        }
                    )
                )
            ]
        , demoRow "Tooltip indicator (pinned via hoverIndex / drag) + disabled"
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
        , demoRow "Vertical + reverse (direction keys flip, dots still 34/75)"
            [ cell
                (Element.el [ Element.height (Element.px 220) ]
                    (Slider.view theme
                        { sliderD
                            | value = [ 77 ]
                            , vertical = True
                            , marks = sliderMarks
                        }
                    )
                )
            , cell
                (Element.el [ Element.height (Element.px 220) ]
                    (Slider.view theme
                        { sliderD
                            | value = [ 77 ]
                            , vertical = True
                            , reverse = True
                            , marks = sliderMarks
                        }
                    )
                )
            ]
        , demoRow "Range snap (`step: 'mark'`) + >2 values (fill suppressed, dots inactive — upstream quirk)"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD
                            | range = True
                            , value = [ 34, 75 ]
                            , step = Slider.StepMarks
                            , marks = sliderMarks
                        }
                    )
                )
            , cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Slider.view theme
                        { sliderD | range = True, value = [ 10, 50, 90 ], marks = sliderMarks }
                    )
                )
            ]
        ]
