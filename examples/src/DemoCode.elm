module DemoCode exposing (get)

{-| GENERATED FILE — do not edit. Rebuilt by tools/gen-demo-code.mjs from the
demoRow/demoBox call sites in examples/src/Sections: key -> the source text
of that demo card's items argument, shown by the card footer's code toggle.
-}


get : String -> String
get key =
    case key of
        "ctl-001" ->
            "[ Button.view theme { btn | size = T.Tiny } [ Element.text \"Tiny\" ]\n, Button.view theme { btn | size = T.Small } [ Element.text \"Small\" ]\n, Button.view theme { btn | size = T.Medium } [ Element.text \"Medium\" ]\n, Button.view theme { btn | size = T.Large } [ Element.text \"Large\" ]\n]"

        "ctl-002" ->
            "(List.map\n    (\\k -> Button.view theme { btn | kind = k } [ Element.text (capitalize (T.kindClass k)) ])\n    [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]\n)"

        "ctl-003" ->
            "[ Button.view theme { btn | kind = T.Primary, variant = Button.Secondary } [ Element.text \"Secondary\" ]\n, Button.view theme { btn | kind = T.Primary, variant = Button.Tertiary } [ Element.text \"Tertiary\" ]\n, Button.view theme { btn | kind = T.Primary, variant = Button.Quaternary } [ Element.text \"Quaternary\" ]\n, Button.view theme { btn | kind = T.Primary, variant = Button.Text } [ Element.text \"Text\" ]\n]"

        "ctl-004" ->
            "[ Button.view theme { btn | round = True } [ Element.text \"Round\" ]\n, Button.view theme { btn | circle = True } [ Element.text \"C\" ]\n, Button.view theme { btn | dashed = True } [ Element.text \"Dashed\" ]\n, Button.view theme { btn | kind = T.Primary, ghost = True } [ Element.text \"Ghost\" ]\n, Button.view theme { btn | disabled = True } [ Element.text \"Disabled\" ]\n, Button.view theme { btn | loading = True } [ Element.text \"Loading\" ]\n]"

        "ctl-005" ->
            "[ ButtonGroup.view theme\n    ButtonGroup.defaults\n    [ Button.view theme { btn | kind = T.Primary } [ Element.text \"Left\" ]\n    , Button.view theme { btn | kind = T.Primary } [ Element.text \"Middle\" ]\n    , Button.view theme { btn | kind = T.Primary } [ Element.text \"Right\" ]\n    ]\n]"

        "ctl-006" ->
            "[ ButtonGroup.view theme\n    { bgD | vertical = True }\n    [ Button.view theme btn [ Element.text \"Top\" ]\n    , Button.view theme btn [ Element.text \"Bottom\" ]\n    ]\n]"

        "ctl-007" ->
            "[ Button.view theme\n    { btn\n        | kind = T.Primary\n        , onPress = Just Press\n        , attributes = [ Element.htmlAttribute (HA.id \"live-button-counter\") ]\n    }\n    [ Element.text (\"Pressed \" ++ String.fromInt model.presses ++ \" times\") ]\n, Button.view theme\n    { btn\n        | onPress = Just ResetPresses\n        , attributes = [ Element.htmlAttribute (HA.id \"live-button-reset\") ]\n    }\n    [ Element.text \"Reset\" ]\n]"

        "ctl-008" ->
            "[ Element.el [ Element.width (Element.px 220) ]\n    (Input.view theme { inputD | placeholder = Just \"Placeholder\" })\n, Element.el [ Element.width (Element.px 220) ]\n    (Input.view theme { inputD | value = \"Hello\" })\n]"

        "ctl-009" ->
            "[ Element.el [ Element.width (Element.px 220) ]\n    (Input.view theme { inputD | value = \"Success\", status = Just Input.Success })\n, Element.el [ Element.width (Element.px 220) ]\n    (Input.view theme { inputD | value = \"Warning\", status = Just Input.Warning })\n, Element.el [ Element.width (Element.px 220) ]\n    (Input.view theme { inputD | value = \"Error\", status = Just Input.Error })\n]"

        "ctl-010" ->
            "[ Element.el [ Element.width (Element.px 220) ]\n    (Input.view theme { inputD | value = \"Disabled\", disabled = True })\n, Element.el [ Element.width (Element.px 220) ]\n    (Input.view theme { inputD | value = \"Clearable\", clearable = True })\n]"

        "ctl-011" ->
            "[ Element.column [ Element.spacing 6, Element.width (Element.px 240) ]\n    [ Input.view theme\n        { inputD\n            | value = model.inputText\n            , onInput = Just InputChanged\n            , onFocus = Just InputFocused\n            , onBlur = Just InputBlurred\n            , clearable = True\n            , placeholder = Just \"Type, then clear\"\n            , inputAttributes = [ HA.id \"live-input-controlled\" ]\n        }\n    , Element.text\n        (\"value: \\\"\"\n            ++ model.inputText\n            ++ \"\\\" · focus: \"\n            ++ (if model.inputFocused then\n                    \"yes\"\n\n                else\n                    \"no\"\n               )\n        )\n    ]\n]"

        "ctl-012" ->
            "[ Element.column [ Element.spacing 6, Element.width (Element.px 320) ]\n    [ Input.view theme\n        { inputD\n            | pairValue = Just model.pair\n            , pairPlaceholder = Just ( \"From\", \"To\" )\n            , separatorNode = Just (Element.text \"→\")\n            , clearable = True\n            , onPairInput = Just (\\( first, second ) source -> PairInput first second source)\n        }\n    , Element.text (\"pair: \" ++ Tuple.first model.pair ++ \" → \" ++ Tuple.second model.pair ++ \" · last edit: \" ++ pairSourceName model.pairSource)\n    ]\n]"

        "ctl-013" ->
            "[ InputOtp.view theme { iotpD | length = 4, value = [ \"1\", \"2\", \"3\", \"4\" ] } []\n, InputOtp.view theme { iotpD | length = 6, size = InputOtp.Small, gap = Just (InputOtp.Px 6) } []\n, InputOtp.view theme { iotpD | length = 6, mask = True } []\n]"

        "ctl-014" ->
            "[ InputOtp.view theme { iotpD | rtl = True, length = 6, value = [ \"8\", \"8\", \"8\" ] } []\n]"

        "ctl-015" ->
            "[ Element.column [ Element.spacing 8 ]\n    [ InputOtp.view theme (otpOptions model) []\n    , Element.row [ Element.spacing 8 ]\n        [ smallButton theme \"live-input-otp-reset\" \"Reset\" OtpReset\n        , smallButton theme \"live-input-otp-mask\" \"Mask\" OtpMaskToggled\n        , Element.text (otpCaption model)\n        ]\n    ]\n]"

        "ctl-016" ->
            "[ InputNumber.view theme (numberOptions model) []\n, Button.view theme\n    { btn\n        | size = T.Small\n        , onPress = Just NumberCommit\n        , attributes = [ Element.htmlAttribute (HA.id \"live-input-number-commit\") ]\n    }\n    [ Element.text \"Commit\" ]\n, Element.text (numberCaption model)\n]"

        "ctl-017" ->
            "[ Checkbox.view theme { cbD | checked = True } [ Element.text \"Checked\" ]\n, Checkbox.view theme cbD [ Element.text \"Unchecked\" ]\n, Checkbox.view theme { cbD | indeterminate = True } [ Element.text \"Indeterminate\" ]\n, Checkbox.view theme { cbD | disabled = True, checked = True } [ Element.text \"Disabled\" ]\n]"

        "ctl-018" ->
            "[ Switch.view theme { swD | value = False } []\n, Switch.view theme { swD | value = True } []\n, Switch.view theme { swD | value = True, loading = True } []\n, Switch.view theme { swD | value = False, disabled = True } []\n]"

        "ctl-019" ->
            "[ Radio.group theme\n    { radioGD | value = Just \"sh\" }\n    [ Radio.choice \"bj\" \"Beijing\", Radio.choice \"sh\" \"Shanghai\", Radio.choice \"gz\" \"Guangzhou\" ]\n]"

        "ctl-020" ->
            "[ Radio.group theme\n    { radioGD | value = Just \"m\" }\n    [ Radio.button \"s\" \"Small\", Radio.button \"m\" \"Medium\", Radio.button \"l\" \"Large\" ]\n]"

        "ctl-021" ->
            "[ Radio.view theme { radioD | checked = True } [ Element.text \"Selected\" ]\n, Radio.view theme radioD [ Element.text \"Unselected\" ]\n, Radio.view theme { radioD | disabled = True } [ Element.text \"Disabled\" ]\n]"

        "ctl-022" ->
            "[ Element.el [ Element.htmlAttribute (HA.id \"live-switch-toggle\") ]\n    (Switch.view theme\n        { swD | value = model.switchOn, onChange = Just SwitchToggled }\n        []\n    )\n, Element.text\n    (if model.switchOn then\n        \"on\"\n\n     else\n        \"off\"\n    )\n]"

        "ctl-023" ->
            "[ Element.column [ Element.spacing 8 ]\n    [ Element.el [ Element.htmlAttribute (HA.id \"live-checkbox-master\") ]\n        (Checkbox.view theme\n            { cbD\n                | checked = List.all identity model.checks\n                , indeterminate = masterIndeterminate model\n                , onCheck = Just CheckMaster\n            }\n            [ Element.text \"Check all\" ]\n        )\n    , Element.row [ Element.spacing 16 ]\n        (List.indexedMap (itemCheckbox theme model) model.checks)\n    , Element.text\n        (\"checked: \"\n            ++ String.fromInt (List.length (List.filter identity model.checks))\n            ++ \"/\"\n            ++ String.fromInt (List.length model.checks)\n            ++ (if masterIndeterminate model then\n                    \" · master indeterminate\"\n\n                else\n                    \"\"\n               )\n        )\n    ]\n]"

        "ctl-024" ->
            "[ Radio.group theme\n    { radioGD\n        | value = model.city\n        , onChange = Just RadioPicked\n        , attributes = [ Element.htmlAttribute (HA.id \"live-radio-group\") ]\n    }\n    [ Radio.choice \"bj\" \"Beijing\"\n    , Radio.choice \"sh\" \"Shanghai\"\n    , Radio.choice \"gz\" \"Guangzhou\"\n    ]\n, Element.text (\"picked: \" ++ Maybe.withDefault \"—\" model.city)\n]"

        "ctl-025" ->
            "[ Rate.view theme { rateD | value = Just 4 }\n, Rate.view theme { rateD | value = Just 3, readonly = True }\n, Rate.view theme { rateD | value = Just 2, color = Just \"#f0a020\" }\n]"

        "ctl-026" ->
            "[ Rate.view theme { rateD | allowHalf = True, value = Just 3.5 }\n, Rate.view theme { rateD | size = Rate.Small, value = Just 5 }\n, Rate.view theme { rateD | size = Rate.Large, value = Just 5 }\n]"

        "ctl-027" ->
            "[ Rate.view theme (rateOptions model)\n, Button.view theme\n    { btn | size = T.Small, onPress = Just (RateNudge -0.5), attributes = [ Element.htmlAttribute (HA.id \"live-rate-hover-minus\") ] }\n    [ Element.text \"hover −½\" ]\n, Button.view theme\n    { btn | size = T.Small, onPress = Just (RateNudge 0.5), attributes = [ Element.htmlAttribute (HA.id \"live-rate-hover-plus\") ] }\n    [ Element.text \"hover +½\" ]\n, Button.view theme\n    { btn | size = T.Small, onPress = Just RatePreviewClear, attributes = [ Element.htmlAttribute (HA.id \"live-rate-hover-clear\") ] }\n    [ Element.text \"clear hover\" ]\n, Element.text\n    (\"hovered: \"\n        ++ maybeFloat model.rateHover\n        ++ \" · committed: \"\n        ++ maybeFloat model.rateValue\n    )\n]"

        "ctl-028" ->
            "[ cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Slider.view theme\n            { sliderD\n                | value = [ 40 ]\n                , marks = sliderMarks\n            }\n        )\n    )\n, cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Slider.view theme\n            { sliderD\n                | range = True\n                , value = [ 24, 49 ]\n                , marks = sliderMarks\n            }\n        )\n    )\n]"

        "ctl-029" ->
            "[ cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Slider.view theme\n            { sliderD | value = [ 66 ], hoverIndex = 0, activeIndex = 0, dragging = True }\n        )\n    )\n, cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Slider.view theme\n            { sliderD\n                | value = [ 12 ]\n                , disabled = True\n                , formatTooltip = Just (\\v -> String.fromFloat v ++ \"%\")\n            }\n        )\n    )\n]"

        "ctl-030" ->
            "[ cell\n    (Element.el [ Element.height (Element.px 220) ]\n        (Slider.view theme\n            { sliderD\n                | value = [ 77 ]\n                , vertical = True\n                , marks = sliderMarks\n            }\n        )\n    )\n, cell\n    (Element.el [ Element.height (Element.px 220) ]\n        (Slider.view theme\n            { sliderD\n                | value = [ 77 ]\n                , vertical = True\n                , reverse = True\n                , marks = sliderMarks\n            }\n        )\n    )\n]"

        "ctl-031" ->
            "[ cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Slider.view theme\n            { sliderD\n                | range = True\n                , value = [ 34, 75 ]\n                , step = Slider.StepMarks\n                , marks = sliderMarks\n            }\n        )\n    )\n, cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Slider.view theme { sliderD | range = True, value = [ 10, 50, 90 ], marks = sliderMarks })\n    )\n]"

        "ctl-032" ->
            "[ Element.column [ Element.spacing 6, Element.width (Element.px 260) ]\n    [ Slider.view theme (sliderOptions model)\n    , Element.row [ Element.spacing 8 ]\n        [ smallButton theme \"live-slider-minus\" \"−1\" (SliderStep -1)\n        , smallButton theme \"live-slider-plus\" \"+1\" (SliderStep 1)\n        , Element.text\n            (String.fromFloat model.slider\n                ++ \" (\"\n                ++ String.fromFloat (Slider.valueToPercentage 0 100 model.slider)\n                ++ \"%)\"\n            )\n        ]\n    ]\n]"

        "ctl-033" ->
            "[ Element.column [ Element.spacing 6, Element.width (Element.px 260) ]\n    [ Slider.view theme (rangeOptions model)\n    , Element.row [ Element.spacing 8 ]\n        [ smallButton theme \"live-range-lo-minus\" \"lo −\" (RangeStep 0 -1)\n        , smallButton theme \"live-range-lo-plus\" \"lo +\" (RangeStep 0 1)\n        , smallButton theme \"live-range-hi-minus\" \"hi −\" (RangeStep 1 -1)\n        , smallButton theme \"live-range-hi-plus\" \"hi +\" (RangeStep 1 1)\n        , Element.text\n            (String.fromFloat (Tuple.first model.range)\n                ++ \" – \"\n                ++ String.fromFloat (Tuple.second model.range)\n            )\n        ]\n    ]\n]"

        "dat-001" ->
            "[ DynamicTags.view theme\n    { dtagsD\n        | value = model.tagsSamples\n        , onUpdateValue = Just TagsSamplesUpdate\n    }\n    []\n, DynamicTags.view theme\n    { dtagsD\n        | value = model.tagsSmallSamples\n        , size = T.Small\n        , round = True\n        , onUpdateValue = Just TagsSmallSamplesUpdate\n    }\n    []\n]"

        "dat-002" ->
            "[ DynamicTags.view theme\n    { dtagsD\n        | value = model.tagsInputSamples\n        , showInput = model.tagsInputShown\n        , inputValue = model.tagsInputDraft\n        , onActivate = Just TagsInputActivate\n        , onInputValue = Just TagsInputDraftInput\n        , onConfirm = Just TagsInputConfirm\n        , onUpdateValue = Just TagsInputSamplesUpdate\n    }\n    []\n]"

        "dat-003" ->
            "[ tagsDemo theme model ]"

        "dat-004" ->
            "[ calendarDemo theme model ]"

        "dat-005" ->
            "[ DynamicInput.viewInput theme\n    { diD\n        | value = model.stringsSamples\n        , placeholder = Just \"Name\"\n        , onUpdateValue = Just StringsSamplesUpdate\n        , onRemove = Just StringsSampleRemove\n    }\n]"

        "dat-006" ->
            "[ DynamicInput.viewPair theme\n    { diPairD\n        | value = model.pairsSamples\n        , keyPlaceholder = Just \"Key\"\n        , valuePlaceholder = Just \"Value\"\n        , onUpdateValue = Just PairsSamplesUpdate\n        , onRemove = Just PairsSampleRemove\n    }\n]"

        "dat-007" ->
            "[ DynamicInput.viewInput theme\n    { diD\n        | value = model.onlyThree\n        , max = Just 3\n        , showSortButton = True\n        , onUpdateValue = Just OnlyThreeUpdate\n        , onRemove = Just OnlyThreeRemove\n    }\n]"

        "dat-008" ->
            "[ DynamicInput.viewInput theme { diD | value = [] }\n]"

        "dat-009" ->
            "[ pairDemo theme model ]"

        "dat-010" ->
            "[ Table.view theme tableD tableContent\n]"

        "dat-011" ->
            "[ Table.view theme { tableD | size = Table.Small } tableContent\n, Table.view theme { tableD | size = Table.Large, bordered = False, bottomBordered = False } tableContent\n]"

        "dat-012" ->
            "[ Table.view theme { tableD | striped = True, singleLine = False } tableContent\n, Table.view theme { tableD | singleColumn = True } tableContent\n]"

        "dat-013" ->
            "[ Table.view theme tableD spanContent\n]"

        "dat-014" ->
            "[ Table.view theme { tableD | rtl = True } tableContent\n]"

        "dat-015" ->
            "[ tableDemo theme model ]"

        "dat-016" ->
            "[ Tree.view theme\n    { treeD | data = treeOptions, expandedKeys = [ \"beatles\", \"stones\" ] }\n, Tree.view theme\n    { treeD\n        | data = treeOptions\n        , expandedKeys = model.treeExpandedCheckable\n        , checkable = True\n        , cascade = True\n        , checkStrategy = Tree.Child\n        , checkedKeys = model.treeCheckedBasic\n        , nodeProps = Just (sampleNodeProps True False TreeExpandedCheckableToggle)\n    }\n]"

        "dat-017" ->
            "[ Tree.view theme\n    { treeD\n        | data = treeOptions\n        , expandedKeys = model.treeExpandedMulti\n        , multiple = True\n        , selectedKeys = model.treeSelectedMulti\n        , nodeProps = Just (sampleNodeProps False True TreeExpandedMultiToggle)\n    }\n, Tree.view theme\n    { treeD | data = treeOptions, expandedKeys = model.treeExpandedLine, showLine = True }\n]"

        "dat-018" ->
            "[ Tree.view theme\n    { treeD\n        | data = treeOptions\n        , expandedKeys = model.treeExpandedBlock\n        , blockLine = True\n        , ellipsis = True\n        , pendingKey = Just \"nowhere\"\n        , highlightKeys = Just [ \"revolver\" ]\n        , nodeProps = Just (sampleNodeProps False False TreeExpandedBlockToggle)\n    }\n]"

        "dat-019" ->
            "[ Tree.view theme\n    { treeD | data = treeOptions, expandedKeys = model.treeExpandedLoading, loadingKeys = [ \"stones\" ] }\n, Tree.view theme { treeD | attributes = [ Element.width (Element.px 240) ] }\n]"

        "dat-020" ->
            "[ treeDemo theme model ]"

        "dat-021" ->
            "[ cell\n    (Image.view theme\n        { imageD\n            | src = Just \"https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg\"\n            , width = Just \"160\"\n            , height = Just \"120\"\n        }\n    )\n, cell\n    (Image.view theme\n        { imageD\n            | src = Just imageLogo\n            , width = Just \"160\"\n            , height = Just \"120\"\n            , objectFit = Image.Contain\n        }\n    )\n, cell\n    (Image.view theme\n        { imageD\n            | src = Just imageLogo\n            , width = Just \"160\"\n            , height = Just \"120\"\n            , objectFit = Image.Cover\n            , alt = Just \"Cover fit\"\n        }\n    )\n]"

        "dat-022" ->
            "[ cell\n    (Image.view theme\n        { imageD\n            | src = Just \"https:// 07akioni.oss-cn-beijing.aliyuncs.com/broken.jpeg\"\n            , fallbackSrc = Just imageLogo\n            , showError = True\n            , width = Just \"160\"\n            , height = Just \"120\"\n        }\n    )\n, cell\n    (Image.view theme\n        { imageD\n            | src = Just \"https:// 07akioni.oss-cn-beijing.aliyuncs.com/broken.jpeg\"\n            , showError = True\n            , error = Just (Element.text \"Load failed\")\n            , width = Just \"160\"\n            , height = Just \"120\"\n        }\n    )\n]"

        "dat-023" ->
            "[ cell\n    (Image.view theme\n        { imageD\n            | src = Just imageLogo\n            , width = Just \"160\"\n            , height = Just \"120\"\n            , placeholder = Just (Element.text \"Placeholder\")\n        }\n    )\n, cell\n    (Image.view theme\n        { imageD\n            | src = Just imageLogo\n            , width = Just \"160\"\n            , height = Just \"120\"\n            , previewDisabled = True\n        }\n    )\n, cell\n    (Image.view theme\n        { imageD\n            | src = Just imageLogo\n            , width = Just \"160\"\n            , height = Just \"120\"\n            , lazy = True\n        }\n    )\n]"

        "dat-024" ->
            "[ previewDemo theme model ]"

        "dat-025" ->
            "[ modalHost []\n    (ImagePreview.view theme\n        { previewD\n            | show = True\n            , src = Just \"https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg\"\n        }\n    )\n]"

        "dat-026" ->
            "[ modalHost []\n    (ImagePreview.view theme\n        { previewD\n            | show = True\n            , src = Just imageLogo\n            , zoom = { previewZoom0 | scale = 1.5, scaleExp = 1, rotate = 90 }\n            , imgDerived = True\n            , previewedImgStyle = [ ( \"border\", \"8px solid white\" ) ]\n        }\n    )\n]"

        "dat-027" ->
            "[ modalHost []\n    (ImagePreview.view theme\n        { previewD\n            | show = True\n            , src = Just imageLogo\n            , showToolbar = False\n        }\n    )\n, modalHost []\n    (ImagePreview.view theme\n        { previewD\n            | show = True\n            , src = Just imageLogo\n            , dragging = True\n            , imgDerived = True\n            , previewedImgStyle = [ ( \"border\", \"8px solid white\" ) ]\n        }\n    )\n]"

        "dat-028" ->
            "[ cell\n    (Element.row [ Element.spacing 8 ]\n        [ Image.view theme\n            { imageD | src = Just \"https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg\", width = Just \"80\", height = Just \"60\" }\n        , Image.view theme\n            { imageD | src = Just imageLogo, width = Just \"80\", height = Just \"60\" }\n        ]\n    )\n, modalHost []\n    (ImageGroup.view theme\n        { groupD\n            | show = True\n            , srcList =\n                [ \"https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg\"\n                , imageLogo\n                , imageLogo\n                ]\n            , current = 1\n        }\n    )\n]"

        "dat-029" ->
            "[ groupDemo theme model ]"

        "dat-030" ->
            "[ DataTable.view theme\n    { dtD | columns = columns, data = people_, rowKey = .name }\n]"

        "dat-031" ->
            "[ DataTable.view theme\n    { dtD\n        | columns = columns\n        , data = people_\n        , rowKey = .name\n        , striped = True\n    }\n]"

        "dat-032" ->
            "[ DataTable.view theme\n    { dtD | columns = columns, data = [], rowKey = .name }\n]"

        "dat-033" ->
            "[ DataTable.view theme\n    { dtD\n        | columns = sortableColumns\n        , data = people_\n        , rowKey = .name\n        , sortStates = model.dtSortSample\n        , onSorterChange = Just DtSortSampleChange\n    }\n, DataTable.view theme\n    { dtD\n        | columns = sortableColumns\n        , data = people_\n        , rowKey = .name\n        , sortStates =\n            if List.isEmpty model.dtSortSample then\n                DataTable.defaultSortStates sortableColumns\n                    |> List.map\n                        (\\state ->\n                            if state.columnKey == \"age\" then\n                                { state | order = DataTable.Descend }\n\n                            else\n                                state\n                        )\n\n            else\n                model.dtSortSample\n        , onSorterChange = Just DtSortSampleChange\n    }\n]"

        "dat-034" ->
            "[ DataTable.view theme\n    { dtD\n        | columns = columns\n        , data = people_\n        , rowKey = .name\n        , pagination = Just { dtPg | pageSize = Just 2 }\n    }\n]"

        "dat-035" ->
            "[ DataTable.view theme\n    { dtD\n        | columns = sortableColumns\n        , data = people_\n        , rowKey = .name\n        , sortStates =\n            if List.isEmpty model.dtSortPageSample then\n                [ ageDescend ]\n\n            else\n                model.dtSortPageSample\n        , pagination =\n            Just\n                { dtPg\n                    | pageSize = Just 2\n                    , currentPage = 2\n                }\n        , onSorterChange = Just DtSortPageSampleChange\n    }\n]"

        "dat-036" ->
            "[ DataTable.view theme\n    { dtD | columns = filterColumns, data = people_, rowKey = .name }\n, DataTable.view theme\n    { dtD\n        | columns = filterColumns\n        , data = people_\n        , rowKey = .name\n        , filterStates = [ ( \"address\", DataTable.FilterMany [ \"Bellevue\" ] ) ]\n    }\n]"

        "dat-037" ->
            "[ DataTable.view theme\n    { dtD\n        | columns =\n            [ { colD | kind = DataTable.KindSelection, disabled = Just (\\p -> p.age >= 40) }\n            , nameCol\n            , ageCol\n            , addressCol\n            ]\n        , data = people_\n        , rowKey = .name\n        , checkedRowKeys = model.dtCheckedSelection\n        , onUpdateCheckedRowKeys = Just DtCheckedSelectionChange\n    }\n]"

        "dat-038" ->
            "[ DataTable.view theme\n    { dtD\n        | columns =\n            [ { colD | kind = DataTable.KindSelection, multiple = False }\n            , nameCol\n            , ageCol\n            ]\n        , data = people_\n        , rowKey = .name\n        , checkedRowKeys = model.dtCheckedSingle\n        , onUpdateCheckedRowKeys = Just DtCheckedSingleChange\n    }\n]"

        "dat-039" ->
            "[ DataTable.view theme\n    { dtD\n        | columns =\n            [ { colD\n                | kind = DataTable.KindSelection\n                , options = [ DataTable.SelectionAll, DataTable.SelectionNone ]\n              }\n            , nameCol\n            , ageCol\n            ]\n        , data = people_\n        , rowKey = .name\n        , checkedRowKeys = model.dtCheckedExtra\n        , onUpdateCheckedRowKeys = Just DtCheckedExtraChange\n    }\n]"

        "dat-040" ->
            "[ DataTable.view theme\n    { dtD\n        | columns =\n            [ { colD\n                | kind = DataTable.KindExpand\n                , renderExpand = Just (\\p _ -> Element.text (p.name ++ \" — \" ++ p.address))\n                , expandable = Just (\\p -> p.age > 30)\n              }\n            , nameCol\n            , ageCol\n            ]\n        , data = people_\n        , rowKey = .name\n        , expandedRowKeys = model.dtExpandedKeys\n        , onUpdateExpandedRowKeys = Just DtExpandedToggle\n    }\n]"

        "dat-041" ->
            "[ DataTable.view theme\n    { dtD\n        | columns =\n            [ { nameCol | fixed = Just DataTable.FixedLeft, width = Just 150 }\n            , ageCol\n            , { colD | key = \"note\", title = \"Note\", view = \\p -> Element.text (p.address ++ \" — some long note column\") }\n            , { addressCol | fixed = Just DataTable.FixedRight, width = Just 220 }\n            ]\n        , data = people_\n        , rowKey = .name\n        , scrollX = Just 600\n    }\n]"

        "dat-042" ->
            "[ DataTable.view theme\n    { dtD\n        | columns = columns\n        , data = people_\n        , rowKey = .name\n        , maxHeight = Just 120\n    }\n]"

        "dat-043" ->
            "[ Element.el [ Element.height (Element.px 220), Element.width Element.fill ]\n    (DataTable.view theme\n        { dtD\n            | columns = columns\n            , data = people_\n            , rowKey = .name\n            , flexHeight = True\n        }\n    )\n]"

        "dat-044" ->
            "[ DataTable.view theme\n    { dtD\n        | columns =\n            [ { colD\n                | key = \"name\"\n                , title = \"Name\"\n                , view = \\p -> Element.text (p.name ++ \" — \" ++ p.address)\n                , ellipsis = Just DataTable.EllipsisPlain\n                , width = Just 160\n              }\n            , ageCol\n            ]\n        , data = people_\n        , rowKey = .name\n    }\n]"

        "dat-045" ->
            "[ DataTable.view theme\n    { dtD\n        | columns = columns\n        , data = people_\n        , rowKey = .name\n        , loading = True\n    }\n]"

        "dat-046" ->
            "[ DataTable.view theme\n    { dtD\n        | columns = columns\n        , data = people_\n        , rowKey = .name\n        , tableLayout = DataTable.TableFixed\n    }\n]"

        "dat-047" ->
            "[ DataTable.view theme\n    { dtD\n        | columns =\n            [ { nameCol | width = Just 100 }\n            , { colD\n                | key = \"age\"\n                , title = \"Age\"\n                , width = Just 100\n                , children =\n                    Just\n                        [ DataTable.ColumnChild\n                            { colD\n                                | key = \"test1\"\n                                , title = \"test1\"\n                                , view = \\p -> Element.text (String.fromInt p.age)\n                            }\n                        , DataTable.ColumnChild\n                            { colD\n                                | key = \"test2\"\n                                , title = \"test2\"\n                                , view = \\p -> Element.text p.address\n                            }\n                        ]\n              }\n            ]\n        , data = people_\n        , rowKey = .name\n    }\n]"

        "dat-048" ->
            "[ DataTable.view theme\n    { dtD\n        | columns = summaryColumns\n        , data = summaryPeople\n        , rowKey = .name\n        , summary = Just summaryOf\n    }\n, DataTable.view theme\n    { dtD\n        | columns = summaryColumns\n        , data = summaryPeople\n        , rowKey = .name\n        , summary = Just summaryOf\n        , summaryPlacement = DataTable.SummaryTop\n    }\n]"

        "dat-049" ->
            "[ DataTable.view theme\n    { dtD\n        | columns =\n            [ { nameCol\n                | rowSpan =\n                    Just\n                        (\\_ rowIndex ->\n                            if rowIndex == 0 then\n                                2\n\n                            else\n                                1\n                        )\n              }\n            , { ageCol\n                | colSpan =\n                    Just\n                        (\\_ rowIndex ->\n                            if rowIndex == 0 then\n                                2\n\n                            else\n                                1\n                        )\n              }\n            , addressCol\n            ]\n        , data = people_\n        , rowKey = .name\n    }\n]"

        "dat-050" ->
            "[ dataTableDemo theme model ]"

        "dat-051" ->
            "[ Transfer.view theme\n    { trD\n        | options = opts\n        , value = model.transferValue2\n        , sourceTitle = Just \"Source\"\n        , targetTitle = Just \"Target\"\n        , onCheck = Just TransferSamplesCheck\n    }\n]"

        "dat-052" ->
            "[ Transfer.view theme\n    { trD\n        | options = opts\n        , value = model.transferValueLarge\n        , size = T.Large\n        , sourceFilterable = True\n        , targetFilterable = True\n        , sourceFilterPlaceholder = Just \"Search\"\n        , onCheck = Just TransferLargeCheck\n    }\n]"

        "dat-053" ->
            "[ Transfer.view theme\n    { trD\n        | options = opts\n        , disabled = True\n        , sourceTitle = Just \"Source\"\n    }\n]"

        "dat-054" ->
            "[ Transfer.view theme\n    { trD | sourceTitle = Just \"Source\", targetTitle = Just \"Target\" }\n]"

        "dat-055" ->
            "[ Transfer.view theme\n    { trD\n        | options = opts\n        , value = model.transferValueAll\n        , selectAllText = Just \"Pick everything\"\n        , clearText = Just \"Drop everything\"\n        , onCheck = Just TransferAllCheck\n    }\n]"

        "dat-056" ->
            "[ transferDemo theme model ]"

        "dat-057" ->
            "[ Upload.view theme\n    (withId \"live-upload\"\n        { upD\n            | fileList =\n                [ file \"a\" \"a.png\" Upload.Pending (Just 0) Nothing Nothing Nothing\n                , file \"b\" \"b.png\" Upload.Uploading (Just 42) Nothing Nothing Nothing\n                , file \"c\" \"c.png\" Upload.Finished (Just 100) (Just \"https://example.com/c.png\") Nothing Nothing\n                , file \"d\" \"d.png\" Upload.Error (Just 88) Nothing Nothing Nothing\n                , file \"e\" \"e.png\" Upload.Removed (Just 10) Nothing Nothing Nothing\n                ]\n        }\n    )\n]"

        "dat-058" ->
            "[ Upload.view theme\n    (withId \"live-upload-uploading\"\n        { upD\n            | fileList = [ file \"u\" \"video.mp4\" Upload.Uploading (Just 42) Nothing Nothing Nothing ]\n        }\n    )\n]"

        "dat-059" ->
            "[ Upload.view theme\n    (withId \"live-upload-error\"\n        { upD\n            | fileList = [ file \"e\" \"broken.zip\" Upload.Error (Just 73) Nothing Nothing Nothing ]\n        }\n    )\n]"

        "dat-060" ->
            "[ Upload.view theme\n    (withId \"live-upload-image\"\n        { upD\n            | listType = Upload.Image\n            , fileList =\n                [ file \"i\" \"photo.jpg\" Upload.Uploading (Just 30) Nothing Nothing (Just \"image/jpeg\") ]\n        }\n    )\n]"

        "dat-061" ->
            "[ Upload.view theme\n    (withId \"live-upload-image-card\"\n        { upD\n            | listType = Upload.ImageCard\n            , fileList =\n                [ file \"p\" \"one.jpg\" Upload.Finished (Just 100) (Just imageLogo) (Just imageLogo) (Just \"image/jpeg\") ]\n        }\n    )\n, Upload.view theme\n    (withId \"live-upload-card-thumb\"\n        { upD\n            | listType = Upload.ImageCard\n            , fileList =\n                [ file \"q\" \"two.pdf\" Upload.Finished (Just 100) Nothing Nothing Nothing ]\n        }\n    )\n]"

        "dat-062" ->
            "[ Upload.view theme\n    (withId \"live-upload-dragger\"\n        { upD\n            | draggerInside = True\n            , triggerNode = Just (Upload.viewDragger upD [ Element.text \"Click or drag a file here\" ])\n        }\n    )\n]"

        "dat-063" ->
            "[ Upload.view theme\n    (withId \"live-upload-disabled\"\n        { upD\n            | disabled = True\n            , fileList = [ file \"a\" \"a.png\" Upload.Uploading (Just 5) Nothing Nothing Nothing ]\n        }\n    )\n]"

        "dat-064" ->
            "[ Upload.view theme\n    (withId \"live-upload-max\"\n        { upD\n            | max = Just 1\n            , fileList = [ file \"a\" \"a.png\" Upload.Finished (Just 100) Nothing Nothing Nothing ]\n        }\n    )\n]"

        "dat-065" ->
            "[ Upload.view theme\n    (withId \"live-upload-directory\" { upD | directory = True })\n]"

        "dat-066" ->
            "[ Upload.view theme\n    (withId \"live-upload-rendericon\"\n        { upD\n            | renderIcon = Just (\\_ -> Element.text \"ICON\")\n            , fileList = [ file \"a\" \"a.png\" Upload.Pending (Just 0) Nothing Nothing Nothing ]\n        }\n    )\n, Upload.view theme\n    (withId \"live-upload-always-show\"\n        { upD\n            | alwaysShowActions = True\n            , fileList = [ file \"a\" \"a.png\" Upload.Uploading (Just 20) Nothing Nothing Nothing ]\n        }\n    )\n]"

        "dat-067" ->
            "(Upload.viewAbstract theme\n    upD\n    (Element.el [ Element.htmlAttribute (HA.id \"live-upload-abstract-slot\") ]\n        (Element.text \"Click to pick a file\")\n    )\n)"

        "dat-068" ->
            "[ uploadDemo theme model ]"

        "dsp-001" ->
            "[ Breadcrumb.view theme\n    bcD\n    [ { bcItem | href = Just \"/\", content = [ Element.text \"Home\" ] }\n    , { bcItem | href = Just \"/library\", content = [ Element.text \"Library\" ] }\n    , { bcItem | content = [ Element.text \"Data\" ] }\n    ]\n]"

        "dsp-002" ->
            "[ Breadcrumb.view theme\n    { bcD | separator = \"›\" }\n    [ { bcItem | separator = Just \"›\", href = Just \"/\", content = [ Element.text \"Root\" ] }\n    , { bcItem | separator = Just \"›\", content = [ Element.text \"Leaf\" ] }\n    ]\n]"

        "dsp-003" ->
            "[ Element.el [ Element.width Element.fill ]\n    (PageHeader.view theme\n        { pageHeaderD\n            | title = Just \"Detail page\"\n            , onBack = Just PageBack\n        }\n        [ Element.text\n            (\"The back control fires onBack — \"\n                ++ String.fromInt model.backClicks\n                ++ \" click(s) so far.\"\n            )\n        ]\n    )\n]"

        "dsp-004" ->
            "(Element.el [ Element.padding 12 ]\n    (Affix.view theme\n        { affixD | affixed = True, top = Just 12 }\n        [ Button.view theme { btn | kind = T.Primary } [ Element.text \"Affixed\" ] ]\n    )\n)"

        "dsp-005" ->
            "[ Flex.view theme\n    flexD\n    [ chip \"One\", chip \"Two\", chip \"Three\" ]\n]"

        "dsp-006" ->
            "[ Flex.view theme\n    { flexD | justify = Flex.SpaceBetween, size = Flex.Number 16 }\n    [ chip \"Left\", chip \"Right\" ]\n]"

        "dsp-007" ->
            "[ Flex.view theme\n    { flexD | direction = Flex.Vertical, size = Flex.Number 8, align = Just Flex.Center }\n    [ chip \"Top\", chip \"Middle\", chip \"Bottom\" ]\n]"

        "dsp-008" ->
            "[ Flex.view theme\n    { flexD | inline = True, size = Flex.Number2 4 12, reverse = True }\n    [ chip \"A\", chip \"B\", chip \"C\" ]\n]"

        "dsp-009" ->
            "[ Grid.view\n    { gridD | cols = Grid.Number 12, xGap = Grid.Number 16, yGap = Grid.Number 16 }\n    [ { gridItem | span = Grid.Number 6, content = [ chip \"span 6\" ] }\n    , { gridItem | span = Grid.Number 6, content = [ chip \"span 6\" ] }\n    , { gridItem | span = Grid.Number 4, content = [ chip \"span 4\" ] }\n    , { gridItem | span = Grid.Number 8, content = [ chip \"span 8\" ] }\n    ]\n]"

        "dsp-010" ->
            "[ Grid.view\n    { gridD\n        | cols = Grid.Number 12\n        , xGap = Grid.Number 12\n        , collapsed = True\n        , collapsedRows = 1\n    }\n    [ { gridItem | span = Grid.Number 4, content = [ chip \"4\" ] }\n    , { gridItem | span = Grid.Number 4, content = [ chip \"4\" ] }\n    , { gridItem | span = Grid.Number 4, content = [ chip \"4\" ] }\n    , { gridItem | span = Grid.Number 4, content = [ chip \"hidden\" ] }\n    , { gridItem | suffix = True, content = [ Element.text \"…\" ] }\n    ]\n]"

        "dsp-011" ->
            "[ QrCode.view theme { qrD | value = \"https://www.naiveui.com/\" }\n, QrCode.view theme\n    { qrD\n        | value = \"https://www.naiveui.com/\"\n        , color = \"#18a058\"\n        , backgroundColor = \"#F5F5F5\"\n    }\n]"

        "dsp-012" ->
            "[ QrCode.view theme { qrD | value = \"The rain dampened the sky\", size = 140 }\n, QrCode.view theme\n    { qrD | value = \"雨淋湿了天空\", errorCorrectionLevel = QrCode.H }\n]"

        "dsp-013" ->
            "[ QrCode.view theme\n    { qrD\n        | value = \"https://www.naiveui.com/\"\n        , iconSrc = Just \"https://example.com/icon.png\"\n        , errorCorrectionLevel = QrCode.H\n    }\n]"

        "dsp-014" ->
            "[ FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text \"+\" ]\n, FloatButton.view theme\n    { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square }\n    [ Element.text \"S\" ]\n, FloatButton.view theme\n    { floatButtonD | position = FloatButton.Relative, type_ = FloatButton.Primary }\n    [ Element.text \"+\" ]\n]"

        "dsp-015" ->
            "[ FloatButton.view theme\n    { floatButtonD | position = FloatButton.Relative, description = Just (Element.text \"Top\") }\n    [ Element.text \"↑\" ]\n]"

        "dsp-016" ->
            "[ Element.column [ Element.spacing 24 ]\n    [ FloatButton.view theme\n        { floatButtonD\n            | position = FloatButton.Relative\n            , menuTrigger = Just FloatButton.Click\n            , showMenu = False\n            , menu =\n                [ FloatButton.view theme\n                    { floatButtonD | position = FloatButton.Relative }\n                    [ Element.text \"A\" ]\n                , FloatButton.view theme\n                    { floatButtonD | position = FloatButton.Relative }\n                    [ Element.text \"B\" ]\n                ]\n        }\n        [ Element.text \"+\" ]\n    , Element.el\n        [ Element.paddingEach { top = 160, bottom = 20, left = 20, right = 20 }\n        , Element.htmlAttribute\n            (HA.attribute \"style\" \"position:relative;background:#fff\")\n        ]\n        (FloatButton.view theme\n            { floatButtonD\n                | position = FloatButton.Relative\n                , menuTrigger = Just FloatButton.Click\n                , showMenu = True\n                , menu =\n                    [ FloatButton.view theme\n                        { floatButtonD | position = FloatButton.Relative }\n                        [ Element.text \"A\" ]\n                    , FloatButton.view theme\n                        { floatButtonD | position = FloatButton.Relative }\n                        [ Element.text \"B\" ]\n                    ]\n            }\n            [ Element.text \"+\" ]\n        )\n    ]\n]"

        "dsp-017" ->
            "[ Element.el\n    [ Element.paddingEach { top = 170, bottom = 20, left = 20, right = 20 }\n    , Element.htmlAttribute\n        (HA.attribute \"style\" \"position:relative;background:#fff\")\n    ]\n    (FloatButton.view theme\n        { floatButtonD\n            | position = FloatButton.Relative\n            , menuTrigger = Just FloatButton.Click\n            , showMenu = model.floatMenuOpen\n            , onUpdateShowMenu = Just FloatMenuToggled\n            , menu =\n                [ FloatButton.view theme\n                    { floatButtonD\n                        | position = FloatButton.Relative\n                        , description = Just (Element.text \"Add\")\n                    }\n                    [ Element.text \"+\" ]\n                , FloatButton.view theme\n                    { floatButtonD\n                        | position = FloatButton.Relative\n                        , description = Just (Element.text \"Edit\")\n                    }\n                    [ Element.text \"✎\" ]\n                ]\n        }\n        [ Element.text \"+\" ]\n    )\n, Element.text\n    (if model.floatMenuOpen then\n        \"menu open\"\n\n     else\n        \"menu closed\"\n    )\n]"

        "dsp-018" ->
            "[ Element.el [ Element.width Element.fill ]\n    (Layout.view theme\n        layD\n        [ LayoutHeader.view theme { lhD | bordered = True } [ Element.text \"Header\" ]\n        , Layout.view theme\n            { layD | hasSider = True }\n            [ LayoutSider.view theme\n                { lsD\n                    | bordered = True\n                    , showTrigger = LayoutSider.ArrowCircle\n                    , collapsed = model.siderCollapsed\n                    , onToggleCollapsed = Just SiderToggled\n                }\n                [ Element.text \"Sider\" ]\n            , Layout.content theme layD [ Element.text \"Content\" ]\n            ]\n        , LayoutFooter.view theme { lfD | bordered = True } [ Element.text \"Footer\" ]\n        ]\n    )\n]"

        "dsp-019" ->
            "[ Element.el [ Element.width Element.fill ]\n    (Layout.view theme\n        { layD | hasSider = True }\n        [ -- Content first so the sider paints on the right (upstream's\n          -- collapse-right demo orders the pair this way).\n          -- `showCollapsedContent = False` hides the label when\n          -- collapsed instead of clipping it to a stray fragment\n          -- inside the 48px bar (the upstream show-sider-content\n          -- demo's setting).\n          Layout.content theme layD [ Element.text \"Content\" ]\n        , LayoutSider.view theme\n            { lsD\n                | collapsed = True\n                , width = \"200px\"\n                , collapsedWidth = \"48px\"\n                , showCollapsedContent = False\n                , showTrigger = LayoutSider.Bar\n                , placement = LayoutSider.Right\n            }\n            [ Element.text \"Collapsed\" ]\n        ]\n    )\n]"

        "dsp-020" ->
            "[ Element.el [ Element.width Element.fill ]\n    (Layout.view theme\n        { layD | embedded = True }\n        [ LayoutHeader.view theme lhD [ Element.text \"Embedded header\" ]\n        , Layout.content theme layD [ Element.text \"Embedded content\" ]\n        ]\n    )\n]"

        "dsp-021" ->
            "[ FloatButtonGroup.view theme\n    { floatButtonGroupD | position = FloatButton.Relative, shape = FloatButton.Circle }\n    [ FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text \"+\" ]\n    , FloatButton.view theme { floatButtonD | position = FloatButton.Relative } [ Element.text \"?\" ]\n    ]\n]"

        "dsp-022" ->
            "[ FloatButtonGroup.view theme\n    { floatButtonGroupD | position = FloatButton.Relative, shape = FloatButton.Square }\n    [ FloatButton.view theme { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square } [ Element.text \"A\" ]\n    , FloatButton.view theme { floatButtonD | position = FloatButton.Relative, shape = FloatButton.Square } [ Element.text \"B\" ]\n    ]\n]"

        "dsp-023" ->
            "[ Heatmap.view theme { heatmapD | data = heatmapSample, now = sampleNow } []\n]"

        "dsp-024" ->
            "[ Heatmap.view theme\n    { heatmapD | loading = True, loadingData = Just [], now = sampleNow }\n    []\n]"

        "dsp-025" ->
            "[ Heatmap.view theme\n    { heatmapD\n        | data = heatmapSample\n        , size = Heatmap.Small\n        , activeColors = Just [ \"#e0e7ff\", \"#a5b4fc\", \"#6366f1\", \"#4338ca\", \"#312e81\" ]\n        , fillCalendarLeading = True\n        , now = sampleNow\n    }\n    []\n]"

        "dsp-026" ->
            "[ Descriptions.view theme\n    { descD | title = Just (Element.text \"Description\") }\n    [ { descItemD | label = Just (Element.text \"Breakfast\"), content = [ Element.text \"Apple\" ] }\n    , { descItemD | label = Just (Element.text \"Brunch\"), content = [ Element.text \"Apple\" ] }\n    , { descItemD | label = Just (Element.text \"Lunch\"), content = [ Element.text \"Apple\" ] }\n    , { descItemD | span = 2, label = Just (Element.text \"Supper\"), content = [ Element.text \"Two Apples\" ] }\n    , { descItemD | label = Just (Element.text \"Midnight Snack\"), content = [ Element.text \"Apple\" ] }\n    ]\n]"

        "dsp-027" ->
            "[ Descriptions.view theme\n    { descD | bordered = True }\n    [ { descItemD | label = Just (Element.text \"Name\"), content = [ Element.text \"Naive UI\" ] }\n    , { descItemD | label = Just (Element.text \"Version\"), content = [ Element.text \"0.19\" ] }\n    , { descItemD | label = Just (Element.text \"License\"), content = [ Element.text \"MIT\" ] }\n    ]\n]"

        "dsp-028" ->
            "[ Descriptions.view theme\n    { descD | labelPlacement = Descriptions.Left, bordered = True }\n    [ { descItemD | label = Just (Element.text \"Name\"), content = [ Element.text \"Naive UI\" ] }\n    , { descItemD | label = Just (Element.text \"Version\"), content = [ Element.text \"0.19\" ] }\n    ]\n]"

        "dsp-029" ->
            "[ Descriptions.view theme\n    { descD | columns = Just 4 }\n    (List.map\n        (\\l -> { descItemD | label = Just (Element.text l), content = [ Element.text \"Apple\" ] })\n        [ \"A\", \"B\", \"C\", \"D\" ]\n    )\n]"

        "dsp-030" ->
            "[ Element.el [ Element.height (Element.px 120), Element.width Element.fill ]\n    (Scrollbar.view theme\n        { scrollbarD\n            | showYBar = True\n            , yBarStyle = Just \"height:48px;top:8px\"\n        }\n        [ Element.paragraph [] (List.repeat 3 (Element.text scrollbarCopy)) ]\n    )\n]"

        "dsp-031" ->
            "[ Element.el [ Element.height (Element.px 120), Element.width (Element.px 460) ]\n    (Scrollbar.view theme\n        { scrollbarD\n            | xScrollable = True\n            , showYBar = True\n            , yBarStyle = Just \"height:48px;top:8px\"\n            , showXBar = True\n            , xBarStyle = Just \"width:80px;left:0\"\n        }\n        -- a long nowrap line so the row genuinely overflows and\n        -- the horizontal thumb has something to thumb\n        [ Element.el [ Element.htmlAttribute (HA.attribute \"style\" \"white-space:nowrap\") ]\n            (Element.text (scrollbarCopy ++ \"  \" ++ scrollbarCopy))\n        ]\n    )\n]"

        "dsp-032" ->
            "[ Element.el [ Element.height (Element.px 100), Element.width Element.fill ]\n    (Scrollbar.view theme\n        { scrollbarD | yPlacement = Scrollbar.Left }\n        [ Element.paragraph [] [ Element.text scrollbarCopy ] ]\n    )\n, Element.el [ Element.height (Element.px 100), Element.width (Element.px 460) ]\n    (Scrollbar.view theme\n        { scrollbarD | xScrollable = True, xPlacement = Scrollbar.Top }\n        [ Element.el [ Element.htmlAttribute (HA.attribute \"style\" \"white-space:nowrap\") ]\n            (Element.text scrollbarCopy)\n        ]\n    )\n]"

        "dsp-033" ->
            "[ Watermark.view theme\n    { watermarkD\n        | content = Just \"Naive UI\"\n        , width = 192\n        , height = 128\n        , fontSize = 16\n        , lineHeight = 16\n        , xOffset = 12\n        , yOffset = 28\n        , rotate = -15\n        , cross = True\n    }\n    [ watermarkedText ]\n]"

        "dsp-034" ->
            "[ Watermark.view theme\n    { watermarkD\n        | content = Just \"elm-naive-ui\\nwatermark\"\n        , width = 192\n        , height = 128\n        , xGap = 32\n        , yGap = 32\n        , fontSize = 16\n        , lineHeight = 20\n        , xOffset = 12\n        , yOffset = 28\n        , rotate = -15\n        , textAlign = Watermark.Center\n        , cross = True\n    }\n    [ watermarkedText ]\n]"

        "dsp-035" ->
            "[ Watermark.view theme\n    { watermarkD\n        | content = Just \"Seemly\"\n        , width = 160\n        , height = 64\n        , fontSize = 16\n        , fontWeight = 700\n        , fontStyle = \"italic\"\n        , fontColor = \"rgba(0, 128, 0, .45)\"\n        , rotate = -15\n        , xOffset = 12\n        , yOffset = 28\n        , debug = True\n        , selectable = False\n    }\n    [ watermarkedText ]\n]"

        "dsp-036" ->
            "[ Watermark.view theme\n    { watermarkD\n        | content = Just \"45°\"\n        , width = 96\n        , height = 32\n        , fontSize = 16\n        , lineHeight = 16\n        , globalRotate = 45\n    }\n    [ watermarkedText ]\n]"

        "dsp-037" ->
            "[ Code.view theme\n    { codeD\n        | code = \"const message = 'hello'\"\n        , language = Just \"javascript\"\n        , hljs = Just codeHljs\n    }\n    []\n]"

        "dsp-038" ->
            "[ Element.text \"Call \"\n, Code.view theme\n    { codeD\n        | code = \"greet()\"\n        , language = Just \"javascript\"\n        , hljs = Just codeHljs\n        , inline = True\n    }\n    []\n, Element.text \" to run it.\"\n]"

        "dsp-039" ->
            "[ Code.view theme\n    { codeD\n        | code = \"const a = 1\\nconst b = 2\\nconst c = 3\"\n        , language = Just \"javascript\"\n        , hljs = Just codeHljs\n        , showLineNumbers = True\n    }\n    []\n]"

        "dsp-040" ->
            "[ Element.el [ Element.width (Element.px 220) ]\n    (Code.view theme\n        { codeD\n            | code = \"const longName = someFunction(anotherArgument, yetAnotherArgument)\"\n            , language = Just \"javascript\"\n            , hljs = Just codeHljs\n            , wordWrap = True\n            , showLineNumbers = True\n        }\n        []\n    )\n]"

        "dsp-041" ->
            "[ Code.view theme\n    { codeD\n        | code = \"const%20x%20%3D%201\"\n        , uri = True\n        , language = Just \"javascript\"\n        , hljs = Just codeHljs\n    }\n    []\n]"

        "dsp-042" ->
            "[ Code.view theme\n    { codeD\n        | code = \"    const spaced = true    \"\n        , trim = False\n        , language = Just \"javascript\"\n        , hljs = Just codeHljs\n    }\n    []\n]"

        "dsp-043" ->
            "[ Code.view theme\n    { codeD | code = \"const plain = 1\", language = Just \"javascript\" }\n    []\n]"

        "dsp-044" ->
            "[ Equation.view theme { equationD | value = \"E = mc^2\", katex = Just fakeKatex } ]"

        "dsp-045" ->
            "[ Equation.view theme { equationD | value = \"x^2 + y^2 = z^2\", katex = Just fakeKatexDisplay } ]"

        "dsp-046" ->
            "[ Equation.view theme { equationD | value = \"a^2 + b^2 = c^2\" } ]"

        "gen-001" ->
            "[ Typo.text theme { typ | strong = True } [ Element.text \"Strong\" ]\n, Typo.text theme { typ | italic = True } [ Element.text \"Italic\" ]\n, Typo.text theme { typ | underline = True } [ Element.text \"Underline\" ]\n, Typo.text theme { typ | delete = True } [ Element.text \"Deleted\" ]\n, Typo.text theme { typ | code = True } [ Element.text \"code\" ]\n]"

        "gen-002" ->
            "(List.map\n    (\\k -> Tag.view theme { tagD | kind = k } [ Element.text (capitalize (T.kindClass k)) ])\n    [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]\n)"

        "gen-003" ->
            "[ Tag.view theme { tagD | round = True } [ Element.text \"Round\" ]\n, Tag.view theme { tagD | bordered = False } [ Element.text \"Filled\" ]\n, Tag.view theme { tagD | kind = T.Primary, strong = True } [ Element.text \"Strong\" ]\n, if model.tagClosableShown then\n    Tag.view theme\n        { tagD | closable = True, onClose = Just TagClosableClosed }\n        [ Element.text \"Closable\" ]\n\n  else\n    Element.none\n, Tag.view theme\n    { tagD\n        | kind = T.Success\n        , checkable = True\n        , checked = model.tagCheckedDemo\n        , onCheck = Just TagCheckedDemo\n    }\n    [ Element.text \"Checked\" ]\n, Tag.view theme { tagD | disabled = True } [ Element.text \"Disabled\" ]\n]"

        "gen-004" ->
            "[ Element.row [ Element.spacing 8 ]\n    (List.map\n        (\\name ->\n            Tag.view theme\n                { tagD\n                    | closable = True\n                    , onClose = Just (TagClosed name)\n                }\n                [ Element.text name ]\n        )\n        model.tags\n    )\n, Button.view theme\n    { btn\n        | size = T.Small\n        , onPress = Just TagAdd\n        , attributes = [ Element.htmlAttribute (HA.id \"secf-tag-add\") ]\n    }\n    [ Element.text \"Add tag\" ]\n, Tag.view theme\n    { tagD\n        | checkable = True\n        , checked = model.tagChecked\n        , onCheck = Just TagChecked\n    }\n    [ Element.text \"Check me\" ]\n, Element.text\n    (String.fromInt (List.length model.tags)\n        ++ \" tags · checked: \"\n        ++ (if model.tagChecked then\n                \"yes\"\n\n            else\n                \"no\"\n           )\n    )\n]"

        "gen-005" ->
            "[ fillWidth\n    (Alert.view theme\n        { alertD | showIcon = False }\n        [ Element.text \"A default alert.\" ]\n    )\n]"

        "gen-006" ->
            "[ fillWidth\n    (Alert.view theme\n        { alertD | kind = T.Info, title = Just \"Info\" }\n        [ Element.text \"With a title and icon.\" ]\n    )\n, if List.member \"kinds-success\" model.alertsClosed then\n    Element.none\n\n  else\n    fillWidth\n        (Alert.view theme\n            { alertD\n                | kind = T.Success\n                , title = Just \"Success\"\n                , closable = True\n                , onClose = Just (AlertClosed \"kinds-success\")\n            }\n            [ Element.text \"Closable alert.\" ]\n        )\n, fillWidth (Alert.view theme { alertD | kind = T.Warning } [ Element.text \"A warning.\" ])\n, fillWidth\n    (Alert.view theme\n        { alertD | kind = T.Error, bordered = False }\n        [ Element.text \"Borderless error.\" ]\n    )\n]"

        "gen-007" ->
            "([ Button.view theme\n    { btn\n        | size = T.Small\n        , onPress = Just AlertReset\n        , attributes = [ Element.htmlAttribute (HA.id \"secf-alert-reset\") ]\n    }\n    [ Element.text \"Reset alerts\" ]\n , Element.text\n    (if List.isEmpty model.alertsClosed then\n        \"all shown\"\n\n     else\n        String.fromInt (List.length model.alertsClosed) ++ \" dismissed\"\n    )\n ]\n    ++ List.filterMap\n        (\\( key, view ) ->\n            if List.member key model.alertsClosed then\n                Nothing\n\n            else\n                Just (fillWidth view)\n        )\n        [ ( \"info\"\n          , Alert.view theme\n                { alertD\n                    | kind = T.Info\n                    , title = Just \"Dismissible\"\n                    , closable = True\n                    , onClose = Just (AlertClosed \"info\")\n                }\n                [ Element.text \"Click the × — this alert unmounts until Reset.\" ]\n          )\n        , ( \"warning\"\n          , Alert.view theme\n                { alertD\n                    | kind = T.Warning\n                    , closable = True\n                    , onClose = Just (AlertClosed \"warning\")\n                }\n                [ Element.text \"Same channel, no title.\" ]\n          )\n        ]\n)"

        "gen-008" ->
            "[ Divider.view theme { divD | titlePlacement = Divider.Left } [ Element.text \"Left\" ]\n, Divider.view theme { divD | titlePlacement = Divider.Center } [ Element.text \"Center\" ]\n, Divider.view theme { divD | titlePlacement = Divider.Right } [ Element.text \"Right\" ]\n]"

        "gen-009" ->
            "[ Divider.view theme { divD | dashed = True } []\n, Element.row [ Element.spacing 16, Element.height (Element.px 42) ]\n    [ Element.text \"Text\"\n    , Divider.view theme { divD | vertical = True } []\n    , Element.text \"More\"\n    , Divider.view theme { divD | vertical = True } []\n    , Element.text \"End\"\n    ]\n]"

        "gen-010" ->
            "[ Avatar.view theme { avD | size = Avatar.Tiny } [ Element.text \"T\" ]\n, Avatar.view theme { avD | size = Avatar.Small } [ Element.text \"S\" ]\n, Avatar.view theme { avD | size = Avatar.Medium } [ Element.text \"M\" ]\n, Avatar.view theme { avD | size = Avatar.Large } [ Element.text \"L\" ]\n, Avatar.view theme { avD | size = Avatar.Huge } [ Element.text \"H\" ]\n]"

        "gen-011" ->
            "[ Avatar.view theme { avD | circle = True, color = Just \"#18a058\" } [ Element.text \"A\" ]\n, Avatar.view theme { avD | circle = True, color = Just \"#2080f0\" } [ Element.text \"B\" ]\n, Avatar.view theme { avD | color = Just \"#f0a020\" } [ Element.text \"Rounded\" ]\n]"

        "gen-012" ->
            "[ AvatarGroup.view theme\n    { agD\n        | max = Just 3\n        , avatar =\n            Just\n                (\\opt ->\n                    Avatar.view theme\n                        { avD | color = Just (avatarColor opt.src) }\n                        [ Element.text (String.left 1 opt.src) ]\n                )\n    }\n    [ { src = \"Alice\" }\n    , { src = \"Bob\" }\n    , { src = \"Carol\" }\n    , { src = \"Dave\" }\n    , { src = \"Eve\" }\n    ]\n, AvatarGroup.view theme\n    { agD | size = Just Avatar.Medium }\n    [ { src = \"https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg\" }\n    , { src = \"https://picsum.photos/id/1/100/100\" }\n    , { src = \"https://picsum.photos/id/2/100/100\" }\n    ]\n]"

        "gen-013" ->
            "[ Space.view theme { spaceD | size = Space.Small } (List.map chip [ \"One\", \"Two\", \"Three\" ]) ]"

        "gen-014" ->
            "[ Space.view theme { spaceD | size = Space.Medium } (List.map chip [ \"One\", \"Two\", \"Three\" ]) ]"

        "gen-015" ->
            "[ Space.view theme\n    { spaceD | direction = Space.Vertical, size = Space.Medium }\n    (List.map chip [ \"Stacked\", \"Vertically\", \"Spaced\" ])\n]"

        "gen-016" ->
            "[ Badge.view theme\n    { badgeD | value = Just (Badge.Number 5) }\n    [ Button.view theme { btn | size = T.Small } [ Element.text \"Mail\" ] ]\n, Badge.view theme\n    { badgeD | value = Just (Badge.Number 200), max = Just 99 }\n    [ Button.view theme { btn | size = T.Small } [ Element.text \"Inbox\" ] ]\n, Badge.view theme\n    { badgeD | dot = True, processing = True, type_ = Badge.Error }\n    [ Button.view theme { btn | size = T.Small } [ Element.text \"Alerts\" ] ]\n]"

        "gen-017" ->
            "(List.map\n    (\\t ->\n        Badge.view theme\n            { badgeD | value = Just (Badge.Number 9), type_ = t }\n            []\n    )\n    [ Badge.Default, Badge.Info, Badge.Success, Badge.Warning, Badge.Error ]\n)"

        "gen-018" ->
            "[ Badge.view theme\n    { badgeD | value = Just (Badge.Text \"New\"), color = Just \"#36ad6a\" }\n    []\n, Badge.view theme { badgeD | dot = True, color = Just \"#18a058\" } []\n]"

        "gen-019" ->
            "[ Badge.view theme\n    { badgeD\n        | value = Just (Badge.Number 128)\n        , previousValue = Just (Badge.Number 118)\n    }\n    []\n, Badge.view theme\n    { badgeD\n        | value = Just (Badge.Number 5)\n        , processing = True\n        , waveActive = True\n    }\n    []\n]"

        "gen-020" ->
            "[ cell (Empty.view theme emptyD []) ]"

        "gen-021" ->
            "[ cell\n    (Empty.view theme\n        { emptyD\n            | description = Just \"Nothing here yet.\"\n            , extra = Just (Button.view theme { btn | size = T.Small } [ Element.text \"Reload\" ])\n        }\n        []\n    )\n]"

        "gen-022" ->
            "[ Element.row\n    [ Element.width Element.fill\n    , Element.htmlAttribute\n        (HA.attribute\n            \"style\"\n            \"justify-content:center;align-items:flex-end;gap:48px;padding:24px 0\"\n        )\n    ]\n    [ Element.el [ Element.width (Element.px 150) ]\n        (Empty.view theme { emptyD | size = Empty.Small, description = Just \"Small\" } [])\n    , Element.el [ Element.width (Element.px 260) ]\n        (Empty.view theme { emptyD | size = Empty.Large, description = Just \"Large\" } [])\n    ]\n]"

        "gen-023" ->
            "[ Element.el [ Element.width (Element.px 210) ]\n    (Result.view theme\n        { resultD | status = Result.Info, title = Just \"Informational\" }\n        []\n    )\n, Element.el [ Element.width (Element.px 210) ]\n    (Result.view theme\n        { resultD | status = Result.Success, title = Just \"Successful\" }\n        []\n    )\n]"

        "gen-024" ->
            "[ Element.el [ Element.width (Element.px 340) ]\n    (Result.view theme\n        { resultD\n            | status = Result.Code404\n            , title = Just \"404\"\n            , description = Just \"The page you are looking for does not exist.\"\n            , footer = Just (Button.view theme btn [ Element.text \"Back home\" ])\n        }\n        [ Element.text \"Custom content can fill the default slot.\" ]\n    )\n]"

        "gen-025" ->
            "(List.map\n    (\\t -> GradientText.view theme { gtD | type_ = t } [ Element.text \"Wonderful\" ])\n    [ GradientText.Primary\n    , GradientText.Info\n    , GradientText.Success\n    , GradientText.Warning\n    , GradientText.Error\n    ]\n)"

        "gen-026" ->
            "[ GradientText.view theme\n    { gtD\n        | gradient =\n            Just (GradientText.Raw \"linear-gradient(90deg, #d03050, #2080f0)\")\n    }\n    [ Element.text \"Raw CSS\" ]\n, GradientText.view theme\n    { gtD | gradient = Just (GradientText.fromTo \"#18a058\" \"#2080f0\") }\n    [ Element.text \"From / To\" ]\n, GradientText.view theme { gtD | size = Just \"22px\" } [ Element.text \"Sized\" ]\n]"

        "gen-027" ->
            "[ Statistic.view theme\n    { statD | label = Just \"Active users\", value = Just \"128\" }\n    []\n, Statistic.view theme\n    { statD\n        | label = Just \"Revenue\"\n        , value = Just \"1,024\"\n        , prefix = Just (Element.text \"$\")\n    }\n    []\n]"

        "gen-028" ->
            "[ Statistic.view theme\n    { statD\n        | label = Just \"Growth\"\n        , tabularNums = True\n        , suffix = Just (Element.text \"%\")\n    }\n    [ Element.text \"12.5\" ]\n]"

        "gen-029" ->
            "[ Element.el [ Element.width (Element.px 320) ]\n    (Thing.view theme\n        { thingD\n            | avatar = Just (Avatar.view theme Avatar.defaults [ Element.text \"N\" ])\n            , title = Just \"naive-ui\"\n            , titleExtra = Just \"v2\"\n            , description = Just \"A Vue 3 component library.\"\n        }\n        [ Element.text \"Content sits under the header.\" ]\n    )\n]"

        "gen-030" ->
            "[ Element.el [ Element.width (Element.px 320) ]\n    (Thing.view theme\n        { thingD\n            | avatar = Just (Avatar.view theme Avatar.defaults [ Element.text \"I\" ])\n            , contentIndented = True\n            , title = Just \"Indented\"\n        }\n        [ Element.text \"The avatar sits above the block.\" ]\n    )\n]"

        "gen-031" ->
            "[ Element.el [ Element.width (Element.px 220) ]\n    (Ellipsis.view theme\n        ellipsisD\n        [ Element.text \"A very long single line of text that gets cut off with an ellipsis character.\" ]\n    )\n]"

        "gen-032" ->
            "[ Element.el [ Element.width (Element.px 220) ]\n    (Ellipsis.view theme\n        { ellipsisD | lineClamp = Just 2 }\n        [ Element.text \"Line clamping caps this paragraph at two lines and hides the remaining text behind a trailing ellipsis.\" ]\n    )\n]"

        "gen-033" ->
            "[ Element.el [ Element.width (Element.px 220) ]\n    (Ellipsis.view theme\n        { ellipsisD\n            | lineClamp = Just 2\n            , expandOnClick = True\n            , expanded = model.ellipsisDemoExpanded\n            , onToggle = Just EllipsisDemoToggled\n        }\n        [ Element.text \"A clickable two-line clamp. The caller toggles `expanded`.\" ]\n    )\n]"

        "gen-034" ->
            "[ Element.el [ Element.width (Element.px 220) ]\n    (Ellipsis.view theme\n        { ellipsisD\n            | lineClamp = Just 2\n            , expandOnClick = True\n            , expanded = model.ellipsisExpanded\n            , onToggle = Just EllipsisToggled\n        }\n        [ Element.text \"Click this clamped paragraph to expand it — the expanded flag lives in the model, so the state survives re-renders.\" ]\n    )\n, Element.text\n    (if model.ellipsisExpanded then\n        \"expanded\"\n\n     else\n        \"clamped\"\n    )\n]"

        "gen-035" ->
            "[ Icon.view theme iconD [ starIcon ]\n, Icon.view theme { iconD | size = Just (Icon.Px 32) } [ starIcon ]\n, Icon.view theme { iconD | depth = Just Icon.Depth2 } [ starIcon ]\n]"

        "gen-036" ->
            "[ IconWrapper.view theme iconWrapperD [ Icon.view theme iconD [ starIcon ] ]\n, IconWrapper.view theme\n    { iconWrapperD | color = Just \"#18a058\", iconColor = Just \"#fff\" }\n    [ Icon.view theme iconD [ starIcon ] ]\n]"

        "gen-037" ->
            "[ Element.el [ Element.width (Element.px 340) ]\n    (fillWidth\n        (Alert.view theme\n            { alertD | rtl = True, kind = T.Info, title = Just \"معلومة\" }\n            [ Element.text \"تنبيه من اليمين إلى اليسار.\" ]\n        )\n    )\n]"

        "gen-038" ->
            "[ Button.view theme { btn | rtl = True, kind = T.Primary } [ Element.text \"Button\" ]\n, Tag.view theme { tagD | rtl = True, kind = T.Primary } [ Element.text \"Tag\" ]\n, Badge.view theme\n    { badgeD | rtl = True, value = Just (Badge.Number 5) }\n    [ Button.view theme { btn | rtl = True, kind = T.Primary } [ Element.text \"Mail\" ] ]\n, Space.view theme\n    { spaceD | rtl = True }\n    [ Element.text \"One\", Element.text \"Two\", Element.text \"Three\" ]\n]"

        "gen-039" ->
            "[ Button.view theme { btn | kind = T.Primary } [ Element.text \"Primary\" ]\n, Tag.view theme { tagD | kind = T.Primary } [ Element.text \"Tag\" ]\n, Switch.view theme { swD | value = True } []\n]"

        "gen-040" ->
            "[ Button.view purple { btn | kind = T.Primary } [ Element.text \"Primary\" ]\n, Tag.view purple { tagD | kind = T.Primary } [ Element.text \"Tag\" ]\n, Switch.view purple { swD | value = True } []\n]"

        "mot-001" ->
            "[ Element.el [ Element.width (Element.px 260) ]\n    (Progress.view theme { progD | percentage = 50 } [])\n, Element.el [ Element.width (Element.px 260) ]\n    (Progress.view theme\n        { progD | percentage = 66, processing = True, height = Just 12 }\n        []\n    )\n, Element.el [ Element.width (Element.px 260) ]\n    (Progress.view theme\n        { progD\n            | percentage = 40\n            , railColor = Just \"#e0e0e0\"\n            , railStyle =\n                Just\n                    [ ( \"background-image\"\n                      , \"repeating-linear-gradient(45deg, #eee, #eee 6px, #ddd 6px, #ddd 12px)\"\n                      )\n                    ]\n        }\n        []\n    )\n]"

        "mot-002" ->
            "[ Element.el [ Element.width (Element.px 260) ]\n    (Progress.view theme\n        { progD | percentage = 100, status = Progress.Success }\n        []\n    )\n, Element.el [ Element.width (Element.px 260) ]\n    (Progress.view theme\n        { progD | percentage = 32, status = Progress.Error }\n        []\n    )\n]"

        "mot-003" ->
            "[ Progress.view theme { progD | type_ = Progress.Circle, percentage = 75 } []\n, Progress.view theme { progD | type_ = Progress.Dashboard, percentage = 60 } []\n]"

        "mot-004" ->
            "[ Progress.view theme\n    { progD\n        | type_ = Progress.MultipleCircle\n        , percentages = [ 80, 60 ]\n        , colors = [ Progress.Solid \"#2080f0\", Progress.Solid \"#18a058\" ]\n        , railColors = [ \"#2080f0\", \"#18a058\" ]\n        , railStyles =\n            [ [ ( \"stroke\", \"#2080f0\" ), ( \"opacity\", \"0.3\" ) ]\n            , [ ( \"stroke\", \"#18a058\" ), ( \"opacity\", \"0.3\" ) ]\n            ]\n        , strokeWidth = 6\n        , circleGap = 0.5\n    }\n    [ Element.text \"Circle racing!\" ]\n, Progress.view theme\n    { progD\n        | type_ = Progress.MultipleCircle\n        , percentages = [ 70, 40 ]\n        , strokeWidth = 10\n        , circleGap = 10\n    }\n    []\n]"

        "mot-005" ->
            "[ Element.el [ Element.width (Element.px 260) ]\n    (Progress.view theme\n        { progD\n            | percentage = 80\n            , color = Just (Progress.Gradient [ \"white\", \"pink\" ])\n        }\n        []\n    )\n, Progress.view theme\n    { progD\n        | type_ = Progress.Circle\n        , percentage = 80\n        , color = Just (Progress.Gradient [ \"#E3F2FD\", \"#2080f0\" ])\n    }\n    []\n, Progress.view theme\n    { progD\n        | type_ = Progress.MultipleCircle\n        , percentages = [ 80, 70 ]\n        , colors =\n            [ Progress.Gradient [ \"white\", \"#18a058\" ]\n            , Progress.Gradient [ \"#E3F2FD\", \"#2080f0\" ]\n            ]\n        , railColors = [ \"#18a058\", \"#2080f0\" ]\n        , strokeWidth = 10\n        , circleGap = 10\n    }\n    [ Element.text \"Circle racing!\" ]\n]"

        "mot-006" ->
            "[ progressDemo theme model ]"

        "mot-007" ->
            "[ Skeleton.view theme\n    { skelD\n        | width = Just (Skeleton.Px 240)\n        , height = Just (Skeleton.Px 16)\n    }\n    []\n]"

        "mot-008" ->
            "[ Skeleton.view theme\n    { skelD | text = True, width = Just (Skeleton.Px 150), repeat = 3 }\n    []\n]"

        "mot-009" ->
            "[ Skeleton.view theme { skelD | circle = True, width = Just (Skeleton.Px 40) } []\n, Skeleton.view theme\n    { skelD\n        | round = True\n        , width = Just (Skeleton.Px 100)\n        , height = Just (Skeleton.Px 12)\n    }\n    []\n, Skeleton.view theme\n    { skelD\n        | width = Just (Skeleton.Px 100)\n        , height = Just (Skeleton.Px 12)\n        , animated = False\n    }\n    []\n]"

        "mot-010" ->
            "[ skeletonDemo theme model ]"

        "mot-011" ->
            "[ Spin.view theme spinD []\n, Spin.view theme { spinD | size = Spin.Small } []\n, Spin.view theme { spinD | size = Spin.Large } []\n]"

        "mot-012" ->
            "[ Spin.view theme { spinD | description = Just (Element.text \"Loading\") } []\n]"

        "mot-013" ->
            "[ Element.el [ Element.width (Element.px 320), Element.height (Element.px 110) ]\n    (Spin.view theme\n        spinD\n        [ Card.view theme\n            { cardD | title = Just (Element.text \"A card\") }\n            [ Element.text \"The spinner overlays this content while loading.\" ]\n        ]\n    )\n]"

        "mot-014" ->
            "[ spinDemo theme model ]"

        "mot-015" ->
            "[ marqueeDemo theme model ]"

        "mot-016" ->
            "[ Countdown.view theme { countdownD | distance = 90000, precision = 0 } []\n, Countdown.view theme { countdownD | distance = 90000, precision = 1 } []\n, Countdown.view theme { countdownD | distance = 90000, precision = 3 } []\n]"

        "mot-017" ->
            "[ Countdown.view theme\n    { countdownD\n        | distance = 5000\n        , render =\n            Just\n                (\\info ->\n                    Element.text (String.fromInt info.seconds ++ \"s left\")\n                )\n    }\n    []\n]"

        "mot-018" ->
            "[ countdownDemo theme model ]"

        "mot-019" ->
            "[ NumberAnimation.view theme\n    { numberAnimationD\n        | from = 0\n        , to = 1234567.5\n        , precision = 2\n        , showSeparator = True\n        , duration = 2000\n        , elapsed = 2000\n    }\n    []\n]"

        "mot-020" ->
            "[ NumberAnimation.view theme\n    { numberAnimationD\n        | from = 10\n        , to = 110\n        , precision = 1\n        , duration = 3000\n        , elapsed = 1500\n    }\n    []\n]"

        "mot-021" ->
            "[ numberDemo theme model ]"

        "mot-022" ->
            "[ spec CarBasicRow ]"

        "mot-023" ->
            "[ spec CarVerticalRow ]"

        "mot-024" ->
            "[ spec CarArrowsRow ]"

        "mot-025" ->
            "[ spec CarNoLoopRow ]"

        "mot-026" ->
            "[ spec CarPerViewRow ]"

        "mot-027" ->
            "[ spec CarFadeRow ]"

        "mot-028" ->
            "[ spec CarCardRow ]"

        "mot-029" ->
            "[ Element.el [ Element.width (Element.px 920) ]\n    (Carousel.view theme\n        customD\n        (Carousel.resize customD { width = 920, height = 360 } (Carousel.init customD 4))\n        slides\n    )\n]"

        "mot-030" ->
            "[ spec CarDefaultIxRow ]"

        "mot-031" ->
            "[ carouselDemo theme model ]"

        "mot-032" ->
            "[ dragDemo theme model ]"

        "mot-033" ->
            "[ Element.el [ Element.width (Element.px 420) ]\n    (Log.view theme\n        { logD\n            | lines = [ \"2026-09-30 first entry\", \"second entry\", \"third entry\" ]\n            , rows = 5\n        }\n    )\n]"

        "mot-034" ->
            "[ Element.el [ Element.width (Element.px 420) ]\n    (Log.view theme\n        { logD\n            | log = Just \"const a = 1\\nconst b = 2\\nconst c = 3\"\n            , language = Just \"javascript\"\n            , hljs = Just codeHljs\n            , loading = True\n            , rows = 4\n        }\n    )\n]"

        "mot-035" ->
            "[ logDemo theme model ]"

        "nav-001" ->
            "[ Element.column [ Element.spacing 12 ]\n    [ Pagination.view theme\n        { pgD\n            | itemCount = Just demoItemCount\n            , pageSizes = List.map Pagination.PageSizeNumber demoSizeValues\n            , pageSize = Just model.pageSize\n            , currentPage = model.page\n            , showQuickJumper = True\n            , jumperValue = model.jumper\n            , onJumperInput = Just JumperInput\n            , onUpdatePage = Just PageSet\n            , onUpdatePageSize = Just PageSizeSet\n            , attributes = [ Element.htmlAttribute (HA.id \"live-pagination\") ]\n        }\n        []\n    , Element.row [ Element.spacing 8 ]\n        (Button.view theme { small | onPress = Just JumperCommit } [ Element.text \"Go\" ]\n            :: List.map sizeButton demoSizeValues\n        )\n    , chip (\"page \" ++ String.fromInt model.page ++ \" / \" ++ String.fromInt lastPage ++ \", \" ++ String.fromInt model.pageSize ++ \" per page\")\n    ]\n]"

        "nav-002" ->
            "[ Element.column [ Element.spacing 12, Element.width (Element.px 520) ]\n    [ Split.view theme\n        { splitD\n            | size = Split.Ratio model.splitRatio\n            , pane1 = [ Element.el [ Element.padding 8 ] (Element.text \"Pane 1\") ]\n            , pane2 = [ Element.el [ Element.padding 8 ] (Element.text \"Pane 2\") ]\n            , attributes = [ Element.htmlAttribute (HA.id \"live-split\"), Element.width Element.fill, Element.height (Element.px 120) ]\n        }\n    , Element.row [ Element.spacing 8 ]\n        [ Button.view theme { small | onPress = Just (SplitNudge -0.1) } [ Element.text \"−10%\" ]\n        , Button.view theme { small | onPress = Just (SplitNudge 0.1) } [ Element.text \"+10%\" ]\n        , Button.view theme { small | onPress = Just SplitReset } [ Element.text \"Reset\" ]\n        , chip (\"pane 1: \" ++ String.fromInt (round (model.splitRatio * 100)) ++ \"%\")\n        ]\n    ]\n]"

        "nav-003" ->
            "[ Element.column [ Element.spacing 12, Element.width (Element.px 520) ]\n    [ Steps.view theme\n        { stepsD\n            | current = Just model.wizardStep\n            , onSelect = Just WizardJump\n            , attributes = [ Element.htmlAttribute (HA.id \"live-steps\") ]\n        }\n        [ { stepsItem | title = Just \"Cart\", description = Just \"Review the cart\" }\n        , { stepsItem | title = Just \"Shipping\", description = Just \"Address and delivery\" }\n        , { stepsItem | title = Just \"Payment\", description = Just \"Pay and confirm\" }\n        ]\n    , Element.row [ Element.spacing 8 ]\n        [ Button.view theme\n            { btn | onPress = Just WizardPrev, disabled = model.wizardStep <= 1 }\n            [ Element.text \"Prev\" ]\n        , Button.view theme\n            { btn | onPress = Just WizardNext, disabled = model.wizardStep >= List.length wizardTitles, kind = T.Primary }\n            [ Element.text \"Next\" ]\n        , chip body\n        ]\n    ]\n]"

        "nav-004" ->
            "(Element.el [ Element.padding 12 ]\n    (BackTop.view theme { backTopD | show = True } [ Element.text \"Up\" ])\n)"

        "nav-005" ->
            "[ Element.row [ Element.spacing 12 ]\n    [ Button.view theme { small | onPress = Just (ScrollBy 300) } [ Element.text \"Scroll down 300\" ]\n    , Button.view theme { small | onPress = Just (ScrollBy -300) } [ Element.text \"Scroll up 300\" ]\n    , chip (\"scrollTop: \" ++ String.fromInt model.scrollTop ++ \" px\")\n    , BackTop.view theme\n        { backTopD\n            | show = model.scrollTop >= backTopThreshold\n            , onClick = Just BackTopPress\n            , attributes = [ Element.htmlAttribute (HA.id \"live-backtop\") ]\n        }\n        []\n    ]\n]"

        "nav-006" ->
            "[ Element.column [ Element.spacing 10, Element.width (Element.px 460) ]\n    [ Collapse.view theme\n        { collapseD\n            | expandedNames = model.accordionNames\n            , onToggle = Just AccordionToggle\n            , attributes = [ Element.htmlAttribute (HA.id \"live-collapse-accordion\") ]\n        }\n        [ panel \"acc-1\" \"Overview\" [ Element.text \"One panel open at most — the update keeps expandedNames a single name (the port's documented accordion recipe).\" ]\n        , panel \"acc-2\" \"Usage\" [ Element.text \"Click a header: onToggle carries the item name, the model decides the next expanded set.\" ]\n        , panel \"acc-3\" \"Notes\" [ Element.text \"Same component as the multiple demo below — only the caller's update differs.\" ]\n        ]\n    , chip (\"expanded: \" ++ namesLabel model.accordionNames)\n    ]\n]"

        "nav-007" ->
            "[ Element.column [ Element.spacing 10, Element.width (Element.px 460) ]\n    [ Collapse.view theme\n        { collapseD\n            | expandedNames = model.multiNames\n            , onToggle = Just MultiToggle\n            , attributes = [ Element.htmlAttribute (HA.id \"live-collapse-multiple\") ]\n        }\n        [ panel \"mul-1\" \"Overview\" [ Element.text \"Any number of panels open — the update toggles membership in expandedNames.\" ]\n        , panel \"mul-2\" \"Usage\" [ Element.text \"Open both, close one — the set is fully caller-owned state.\" ]\n        , panel \"mul-3\" \"Notes\" [ Element.text \"The transition phase (fade-in-height-expand) needs a clock; this family runs Sub.none.\" ]\n        ]\n    , chip (\"expanded: \" ++ namesLabel model.multiNames)\n    ]\n]"

        "nav-008" ->
            "[ Tabs.view theme { tabsD | value = \"one\" } tabsItems ]"

        "nav-009" ->
            "[ Tabs.view theme { tabsD | type_ = Tabs.Line, value = \"two\" } tabsItems ]"

        "nav-010" ->
            "[ Tabs.view theme { tabsD | type_ = Tabs.Card, closable = True, value = \"one\" } tabsItems ]"

        "nav-011" ->
            "[ Tabs.view theme { tabsD | type_ = Tabs.Segment, value = \"two\" } tabsItems ]"

        "nav-012" ->
            "[ Tabs.view theme { tabsD | size = Tabs.Small, value = \"one\" } tabsItems\n, Tabs.view theme { tabsD | size = Tabs.Large, value = \"one\" } tabsItems\n]"

        "nav-013" ->
            "[ Tabs.view theme { tabsD | placement = Tabs.Bottom, value = \"one\" } tabsItems\n, Tabs.view theme { tabsD | placement = Tabs.Left, value = \"one\" } tabsItems\n]"

        "nav-014" ->
            "[ Tabs.view theme { tabsD | displayDirective = Tabs.Show, value = \"one\" } tabsItems ]"

        "nav-015" ->
            "[ Element.column [ Element.spacing 10, Element.width (Element.px 460) ]\n    [ Tabs.view theme opts (List.map toTab model.tabs)\n    , chip (\"active: \" ++ activeLabel)\n    ]\n]"

        "nav-016" ->
            "[ cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Menu.view theme\n            { menuD\n                | value = Just \"who\"\n                , expandedKeys = [ \"sub-1\", \"sub-2\", \"group-1\" ]\n            }\n            menuOpts\n        )\n    )\n]"

        "nav-017" ->
            "[ cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Menu.view theme\n            { menuD\n                | accordion = True\n                , expandedKeys = Menu.initialExpandedKeys True Nothing menuOpts\n            }\n            menuOpts\n        )\n    )\n, cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Menu.view theme\n            { menuD\n                | expandedKeys = Menu.initialExpandedKeys False (Just \"cascader\") menuOpts\n            }\n            menuOpts\n        )\n    )\n]"

        "nav-018" ->
            "[ cell\n    (Element.el [ Element.width (Element.px 64) ]\n        (Menu.view theme\n            { menuD | collapsed = True, value = Just \"who\", expandedKeys = [ \"sub-1\" ] }\n            menuOpts\n        )\n    )\n, cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Menu.view theme\n            { menuD\n                | rootIndent = Just 12\n                , indent = 16\n                , value = Just \"who\"\n                , expandedKeys = [ \"sub-1\", \"group-1\" ]\n            }\n            menuOpts\n        )\n    )\n]"

        "nav-019" ->
            "[ cell\n    (Element.el [ Element.width Element.fill ]\n        (Menu.view theme\n            { menuD | mode = Menu.Horizontal, value = Just \"who\" }\n            menuOpts\n        )\n    )\n, cell\n    (Element.el\n        [ Element.width (Element.px 240)\n        , Element.padding 8\n        , Element.htmlAttribute (HA.attribute \"style\" \"background:rgb(16,16,20)\")\n        ]\n        (Menu.view theme\n            { menuD | inverted = True, value = Just \"who\", expandedKeys = [ \"sub-1\", \"group-1\" ] }\n            menuOpts\n        )\n    )\n]"

        "nav-020" ->
            "[ cell\n    (Element.el [ Element.width (Element.px 240) ]\n        (Menu.view theme\n            { menuD | disabled = True, expandedKeys = [ \"sub-1\" ] }\n            menuOpts\n        )\n    )\n]"

        "nav-021" ->
            "[ Element.column [ Element.spacing 10 ]\n    [ Menu.view theme\n        { menuD\n            | value = model.menuValue\n            , expandedKeys = model.menuExpanded\n            , onSelect = Just MenuSelect\n            , onExpandedKeysChange = Just MenuExpanded\n            , attributes = [ Element.htmlAttribute (HA.id \"live-menu\"), Element.width (Element.px 260) ]\n        }\n        menuOptions\n    , Element.row [ Element.spacing 8 ]\n        [ Button.view theme { small | onPress = Just MenuReveal } [ Element.text \"Expand to selection\" ]\n        , chip (\"value: \" ++ Maybe.withDefault \"—\" model.menuValue)\n        , chip\n            (\"path: \"\n                ++ (if path == \"\" then\n                        \"—\"\n\n                    else\n                        path\n                   )\n            )\n        ]\n    ]\n]"

        "nav-022" ->
            "[ Anchor.view theme\n    { anchorD | activeHref = Just \"#anchor-basic\" }\n    demoLinks\n]"

        "nav-023" ->
            "[ Anchor.view theme\n    { anchorD | type_ = Anchor.Block, activeHref = Just \"#anchor-block\" }\n    demoLinks\n]"

        "nav-024" ->
            "[ Anchor.view theme\n    { anchorD | showRail = False }\n    demoLinks\n, Anchor.view theme\n    { anchorD | showBackground = False, activeHref = Just \"#anchor-api\" }\n    demoLinks\n]"

        "nav-025" ->
            "[ demoBox \"nav-026\"\n    200\n    (Anchor.view theme\n        { anchorD\n            | affix = Just { affixD | affixed = True, top = Just 88 }\n            , activeHref = Just \"#anchor-affix\"\n        }\n        demoLinks\n    )\n]"

        "nav-026" ->
            "(Anchor.view theme\n    { anchorD\n        | affix = Just { affixD | affixed = True, top = Just 88 }\n        , activeHref = Just \"#anchor-affix\"\n    }\n    demoLinks\n)"

        "nav-027" ->
            "[ Element.column [ Element.spacing 10 ]\n    [ Element.row [ Element.spacing 32 ]\n        [ Anchor.view theme (opts \"live-anchor\" Anchor.Rail) links\n        , Anchor.view theme (opts \"live-anchor-block\" Anchor.Block) links\n        ]\n    , chip (\"active: \" ++ model.activeHref)\n    ]\n]"

        "ovr-001" ->
            "[ Element.el [ Element.width (Element.px 440) ]\n    (LoadingBar.view theme\n        { lbD | containerStyle = Just \"position:relative;margin-bottom:8px;\" }\n        (LoadingBar.start LoadingBar.init |> LoadingBar.kick)\n    )\n]"

        "ovr-002" ->
            "[ Element.el [ Element.width (Element.px 440) ]\n    (LoadingBar.view theme\n        { lbD | containerStyle = Just \"position:relative;margin-bottom:8px;\" }\n        (LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.finish)\n    )\n]"

        "ovr-003" ->
            "[ Element.el [ Element.width (Element.px 440) ]\n    (LoadingBar.view theme\n        { lbD | containerStyle = Just \"position:relative;margin-bottom:8px;\" }\n        (LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.error)\n    )\n]"

        "ovr-004" ->
            "[ Button.view theme { btn | size = T.Small, onPress = Just LoadingStart } [ Element.text \"start\" ]\n, Button.view theme { btn | size = T.Small, onPress = Just LoadingKick } [ Element.text \"kick\" ]\n, Button.view theme { btn | size = T.Small, onPress = Just LoadingFadeDone } [ Element.text \"fade ✓\" ]\n, Button.view theme { btn | size = T.Small, onPress = Just LoadingFinish } [ Element.text \"finish\" ]\n, Button.view theme { btn | size = T.Small, onPress = Just LoadingError } [ Element.text \"error\" ]\n, Button.view theme { btn | size = T.Small, onPress = Just LoadingAfterLeave } [ Element.text \"leave ✓\" ]\n, Element.el\n    [ Element.width (Element.px 440)\n    , Element.htmlAttribute (HA.id \"live-loading-bar\")\n    ]\n    (LoadingBar.view theme\n        { lbD | containerStyle = Just \"position:relative;margin-bottom:8px;\" }\n        model.loadingBar\n    )\n, chip (loadingSummary model.loadingBar ++ \" — \" ++ model.loadingOutcome)\n]"

        "ovr-005" ->
            "[ popoverHost Popover.Top\n    []\n    (Popover.view theme\n        { popoverD | width = Just \"240px\" }\n        [ Element.text \"The pure body of a popover — mount it, position it, it is yours.\" ]\n    )\n, popoverHost Popover.Bottom\n    []\n    (Popover.view theme\n        { popoverD\n            | width = Just \"240px\"\n            , header = Just (Element.text \"Title\")\n            , footer = Just (Element.text \"Footer\")\n        }\n        [ Element.text \"Header and footer slots add their wrapper divs and the modifier class.\" ]\n    )\n]"

        "ovr-006" ->
            "[ popoverHost Popover.Right\n    []\n    (Popover.view theme\n        { popoverD | width = Just \"220px\", showArrow = False }\n        [ Element.text \"No arrow.\" ]\n    )\n, popoverHost Popover.Right\n    []\n    (Popover.view theme\n        { popoverD | width = Just \"220px\", overlap = True }\n        [ Element.text \"Overlap: no arrow and no spacing margin.\" ]\n    )\n, popoverHost Popover.Right\n    []\n    (Popover.view theme\n        { popoverD | width = Just \"220px\", raw = True }\n        [ Element.text \"Raw: no background, radius or padding.\" ]\n    )\n]"

        "ovr-007" ->
            "[ popoverHost Popover.Top\n    []\n    (Popover.view theme\n        { popoverD\n            | width = Just \"240px\"\n            , transition = Just I.EnterActive\n        }\n        [ Element.text \"The popover-transition classes are the caller's clock.\" ]\n    )\n]"

        "ovr-008" ->
            "[ popoverHost Popover.Top\n    []\n    (Popover.view theme\n        { popoverD\n            | width = Just \"260px\"\n            , scrollable = True\n            , attributes = [ Element.height (Element.px 120) ]\n        }\n        [ Element.text scrollbarCopy ]\n    )\n]"

        "ovr-009" ->
            "[ popoverHost Popover.Top\n    []\n    (Popconfirm.view theme\n        { popconfirmD | popover = { popoverD | width = Just \"220px\" } }\n        [ Element.text \"Delete it?\" ]\n    )\n, popoverHost Popover.Top\n    []\n    (Popconfirm.view theme\n        { popconfirmD\n            | popover = { popoverD | width = Just \"220px\" }\n            , showIcon = False\n            , action = Just [ Element.text \"#action — the slot replaces the buttons\" ]\n        }\n        [ Element.text \"No icon; the body renders content-only.\" ]\n    )\n]"

        "ovr-010" ->
            "[ popoverHost Popover.Top\n    []\n    (Popconfirm.view theme\n        { popconfirmD\n            | popover = { popoverD | width = Just \"240px\" }\n            , positiveText = Popconfirm.CustomText \"Sure\"\n            , negativeText = Popconfirm.CustomText \"Not yet\"\n            , positiveProps = Just (\\b -> { b | round = True })\n            , negativeProps = Just (\\b -> { b | round = True })\n        }\n        [ Element.text \"CustomText labels; Hidden drops a button (the row stays).\" ]\n    )\n]"

        "ovr-011" ->
            "[ relHost \"live-popconfirm\"\n    Popover.Top\n    [ Button.view theme\n        { btn | kind = T.Error, onPress = Just PopconfirmToggle }\n        [ Element.text \"Delete project…\" ]\n    , if model.popconfirmOpen then\n        Popconfirm.view theme\n            { popconfirmD\n                | popover = { popoverD | width = Just \"240px\" }\n                , onPositiveClick = Just PopconfirmPositive\n                , onNegativeClick = Just PopconfirmNegative\n            }\n            [ Element.text \"Delete the whole project?\" ]\n\n      else\n        Element.none\n    ]\n, chip model.popconfirmOutcome\n]"

        "ovr-012" ->
            "[ Switch.view theme\n    { swD | value = model.popoverPinned, onChange = Just PopoverPinned }\n    [ Element.text \"controlled\" ]\n, Button.view theme\n    { btn | onPress = Just PopoverToggle }\n    [ Element.text\n        (if model.popoverOpen then\n            \"Hide\"\n\n         else\n            \"Show\"\n        )\n    ]\n, relHost \"live-popover\"\n    Popover.Top\n    [ if model.popoverOpen || model.popoverPinned then\n        Popover.view theme\n            { popoverD\n                | width = Just \"240px\"\n                , header = Just (Element.text \"A live popover\")\n                , footer =\n                    Just\n                        (Button.view theme\n                            { btn\n                                | size = T.Small\n                                , onPress = Just PopoverClose\n                            }\n                            [ Element.text \"Close\" ]\n                        )\n                , transition = Just I.EnterActive\n                , attributes = [ Element.htmlAttribute (HA.id \"live-popover-body\") ]\n            }\n            [ Element.text \"The trigger click opens; the footer button is the close channel; the switch forces it open.\" ]\n\n      else\n        Element.none\n    ]\n, chip model.popoverOutcome\n]"

        "ovr-013" ->
            "[ popoverHost Popover.Top\n    []\n    (Tooltip.view theme\n        { tooltipD | width = Just \"200px\" }\n        [ Element.text \"A tooltip bubble.\" ]\n    )\n, popoverHost Popover.Bottom\n    []\n    (Tooltip.view theme\n        { tooltipD | width = Just \"200px\", showArrow = False }\n        [ Element.text \"No arrow.\" ]\n    )\n]"

        "ovr-014" ->
            "[ popoverHost Popover.Right\n    []\n    (Tooltip.view darkTheme\n        { tooltipD | width = Just \"200px\" }\n        [ Element.text \"Same as the dark popover.\" ]\n    )\n]"

        "ovr-015" ->
            "[ Element.column\n    [ Popover.placementAttribute Popover.Bottom\n    , Element.htmlAttribute (HA.attribute \"style\" \"position:relative;padding:6px 0;\")\n    , Element.htmlAttribute (HA.id \"live-tooltip-region\")\n    , Element.Events.onMouseEnter (TooltipHover True)\n    , Element.Events.onMouseLeave (TooltipHover False)\n    ]\n    [ Button.view theme\n        { btn | kind = T.Primary }\n        [ Element.text \"Hover me\" ]\n    , if model.tooltipHover then\n        Tooltip.view theme\n            { tooltipD\n                | width = Just \"220px\"\n                , attributes = [ Element.htmlAttribute (HA.id \"live-tooltip-body\") ]\n            }\n            [ Element.text \"A live tooltip — the hover state lives in the model.\" ]\n\n      else\n        Element.none\n    ]\n, chip\n    (if model.tooltipHover then\n        \"hovering — the tooltip body is mounted\"\n\n     else\n        \"idle — unmounted\"\n    )\n]"

        "ovr-016" ->
            "[ popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD | value = model.dropdownBasicValue, onSelect = Just DropdownBasicSelect }\n        [ Dropdown.Option\n            { key = \"edit\"\n            , label = \"Edit\"\n            , icon = Nothing\n            , disabled = False\n            , children = Nothing\n            , attributes = []\n            }\n        , Dropdown.Option\n            { key = \"duplicate\"\n            , label = \"Duplicate\"\n            , icon = Nothing\n            , disabled = False\n            , children = Nothing\n            , attributes = []\n            }\n        , Dropdown.Divider { attributes = [] }\n        , Dropdown.Option\n            { key = \"delete\"\n            , label = \"Delete\"\n            , icon = Nothing\n            , disabled = True\n            , children = Nothing\n            , attributes = []\n            }\n        ]\n    )\n, popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD\n            | size = Dropdown.Small\n            , value = model.dropdownBasicValue\n            , onSelect = Just DropdownBasicSelect\n        }\n        [ demoLeaf \"small-1\" \"Small\", demoLeaf \"small-2\" \"28px rows\" ]\n    )\n, popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD\n            | size = Dropdown.Huge\n            , value = model.dropdownBasicValue\n            , onSelect = Just DropdownBasicSelect\n        }\n        [ demoLeaf \"huge-1\" \"Huge\", demoLeaf \"huge-2\" \"46px rows, 18px icons\" ]\n    )\n]"

        "ovr-017" ->
            "[ popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD\n            | width = Just \"220px\"\n            , value = model.dropdownGroupValue\n            , onSelect = Just DropdownGroupSelect\n        }\n        [ Dropdown.Group\n            { key = \"group-people\"\n            , label = \"People\"\n            , icon = Nothing\n            , children =\n                [ Dropdown.Option\n                    { key = \"jay\"\n                    , label = \"Jay Gatsby\"\n                    , icon = Just demoIcon\n                    , disabled = False\n                    , children = Nothing\n                    , attributes = []\n                    }\n                , Dropdown.Option\n                    { key = \"daisy\"\n                    , label = \"Daisy Buchanan\"\n                    , icon = Just demoIcon\n                    , disabled = True\n                    , children = Nothing\n                    , attributes = []\n                    }\n                ]\n            }\n        , Dropdown.Divider { attributes = [] }\n        , Dropdown.Option\n            { key = \"others\"\n            , label = \"Others\"\n            , icon = Just demoIcon\n            , disabled = False\n            , children = Just [ demoLeaf \"nick\" \"Nick Carraway\", demoLeaf \"tom\" \"Tom Buchanan\" ]\n            , attributes = []\n            }\n        , Dropdown.Custom\n            { key = \"custom\"\n            , children = [ Element.text \"A custom render option.\" ]\n            , attributes = []\n            }\n        ]\n    )\n, popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD\n            | value = model.dropdownChildValue\n            , onSelect = Just DropdownChildSelect\n        }\n        [ Dropdown.Option\n            { key = \"parent\"\n            , label = \"Parent (child-active)\"\n            , icon = Nothing\n            , disabled = False\n            , children = Just [ demoLeaf \"target\" \"Target (active)\" ]\n            , attributes = []\n            }\n        , demoLeaf \"plain\" \"Plain\"\n        ]\n    )\n, popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD\n            | value = model.dropdownActiveValue\n            , onSelect = Just DropdownActiveSelect\n        }\n        [ demoLeaf \"target\" \"Target (active)\"\n        , demoLeaf \"plain\" \"Plain\"\n        ]\n    )\n]"

        "ovr-018" ->
            "[ popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD\n            | showArrow = True\n            , value = model.dropdownVariantValue\n            , onSelect = Just DropdownVariantSelect\n        }\n        [ demoLeaf \"a1\" \"With the popover arrow\", demoLeaf \"a2\" \"Second item\" ]\n    )\n, popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD\n            | inverted = True\n            , value = model.dropdownVariantValue\n            , onSelect = Just DropdownVariantSelect\n        }\n        [ demoLeaf \"i1\" \"Inverted menu\", demoLeaf \"i2\" \"Primary hover\" ]\n    )\n, popoverHost Popover.Bottom\n    []\n    (Dropdown.view theme\n        { dropdownD\n            | scrollable = True\n            , width = Just \"240px\"\n            , value = model.dropdownVariantValue\n            , onSelect = Just DropdownVariantSelect\n            , attributes = [ Element.height (Element.px 120) ]\n        }\n        (List.indexedMap (\\i _ -> demoLeaf (\"s\" ++ String.fromInt i) (\"Scrollable item \" ++ String.fromInt (i + 1))) (List.range 1 12))\n    )\n]"

        "ovr-019" ->
            "[ relHost \"live-dropdown-click\"\n    Popover.Bottom\n    [ Button.view theme\n        { btn | onPress = Just DropdownToggle }\n        [ Element.text\n            (if model.dropdownOpen then\n                \"Close menu ▴\"\n\n             else\n                \"Open menu ▾\"\n            )\n        ]\n    , if model.dropdownOpen then\n        Dropdown.view theme\n            { dropdownD\n                | onSelect = Just DropdownSelect\n                , attributes = [ Element.htmlAttribute (HA.id \"live-dropdown-menu\") ]\n            }\n            dropdownMenu\n\n      else\n        Element.none\n    ]\n, chip\n    (if String.isEmpty model.dropdownPick then\n        \"no pick yet — a leaf click selects and closes\"\n\n     else\n        \"onSelect → '\" ++ model.dropdownPick ++ \"' (closed by the update)\"\n    )\n]"

        "ovr-020" ->
            "[ Element.column\n    [ Popover.placementAttribute Popover.Bottom\n    , Element.htmlAttribute (HA.attribute \"style\" \"position:relative;padding:6px 0;\")\n    , Element.htmlAttribute (HA.id \"live-dropdown-hover\")\n    , Element.Events.onMouseEnter (DropdownHover True)\n    , Element.Events.onMouseLeave (DropdownHover False)\n    ]\n    [ Button.view theme btn [ Element.text \"Hover me (mouseenter / mouseleave)\" ]\n    , if model.dropdownHover then\n        Dropdown.view theme\n            { dropdownD\n                | onSelect = Just DropdownSelect\n                , attributes = [ Element.htmlAttribute (HA.id \"live-dropdown-hover-menu\") ]\n            }\n            dropdownMenu\n\n      else\n        Element.none\n    ]\n, chip\n    (if model.dropdownHover then\n        \"hovering — mounted\"\n\n     else\n        \"idle — unmounted ('hover' is the caller's trigger runtime)\"\n    )\n]"

        "ovr-021" ->
            "[ messageState Message.Top\n    [ messageOf \"d\" Message.Default \"A default message — no icon wrapper\"\n    , messageOf \"i\" Message.Info \"An info message\"\n    , messageOf \"s\" Message.Success \"A success message\"\n    , messageOf \"w\" Message.Warning \"A warning message\"\n    , messageOf \"e\" Message.Error \"An error message\"\n    , messageOf \"l\" Message.Loading \"A loading message — n-base-loading spinner\"\n    ]\n, messageState Message.BottomRight\n    [ messageOf \"b1\" Message.Info \"Bottom-right placement\"\n    , messageOf \"b2\" Message.Success \"align-items flips to flex-end\"\n    ]\n]"

        "ovr-022" ->
            "[ messageState Message.Top model.staticMessages\n]"

        "ovr-023" ->
            "[ messageState Message.Top\n    [ messageOf \"idle\" Message.Info \"Settled — no phase class\"\n    , { messageI\n        | key = \"entering\"\n        , options = { messageD | kind = Message.Success, content = \"Entering — fade-in-height-expand-transition-enter-active\" }\n        , phase = Just I.EnterActive\n      }\n    , { messageI\n        | key = \"leaving\"\n        , options = { messageD | kind = Message.Warning, content = \"Leaving — fade-in-height-expand-transition-leave-from\" }\n        , phase = Just I.LeaveFrom\n      }\n    ]\n]"

        "ovr-024" ->
            "[ messageState Message.Top\n    [ { messageI\n        | key = \"icon\"\n        , options =\n            { messageD\n                | content = \"Custom icon — the wrapper appears for a Default kind\"\n                , icon = Just (Element.text \"✓\")\n            }\n      }\n    , { messageI\n        | key = \"render\"\n        , options =\n            { messageD\n                | render =\n                    Just\n                        [ Element.el\n                            [ Element.htmlAttribute\n                                (HA.attribute\n                                    \"style\"\n                                    \"background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:10px 20px;color:var(--n-text-color)\"\n                                )\n                            ]\n                            (Element.text \"render — no .n-message tree, no icon/content/close\")\n                        ]\n            }\n      }\n    ]\n]"

        "ovr-025" ->
            "[ Button.view theme { btn | onPress = Just MessageInfo } [ Element.text \"info\" ]\n, Button.view theme { btn | kind = T.Primary, onPress = Just MessageSuccess } [ Element.text \"success\" ]\n, Button.view theme { btn | kind = T.Error, onPress = Just MessageError } [ Element.text \"error\" ]\n, Button.view theme { btn | size = T.Small, onPress = Just MessageClear } [ Element.text \"clear\" ]\n, overlayCell \"live-message-queue\" (Message.view theme model.messages)\n, chip model.messageOutcome\n]"

        "ovr-026" ->
            "[ notificationState Notification.TopRight\n    [ notificationOf \"d\" \"A default notification\" Notification.Default\n    , notificationOf \"i\" \"An info notification\" Notification.Info\n    , notificationOf \"s\" \"A success notification\" Notification.Success\n    , notificationOf \"w\" \"A warning notification\" Notification.Warning\n    , notificationOf \"e\" \"An error notification\" Notification.Error\n    ]\n]"

        "ovr-027" ->
            "[ notificationState Notification.TopRight model.staticNotifications\n]"

        "ovr-028" ->
            "[ notificationState Notification.TopLeft\n    [ notificationOf \"tl\" \"Top-left — scrollable\" Notification.Success ]\n, notificationState Notification.Top\n    [ notificationOf \"tc\" \"Top center — scrollable forced off (no scrollbar tree)\" Notification.Warning ]\n, notificationState Notification.BottomRight\n    [ notificationOf \"br\" \"Bottom-right — align flips\" Notification.Error ]\n]"

        "ovr-029" ->
            "[ notificationState Notification.TopRight\n    [ notificationOf \"idle\" \"Settled — no phase class\" Notification.Info\n    , { notificationI\n        | key = \"entering\"\n        , options = { notificationD | title = Just \"Entering — notification-transition-enter-active\", kind = Notification.Success }\n        , phase = Just I.EnterActive\n      }\n    , { notificationI\n        | key = \"leaving\"\n        , options = { notificationD | title = Just \"Leaving — notification-transition-leave-from\", kind = Notification.Warning }\n        , phase = Just I.LeaveFrom\n      }\n    ]\n]"

        "ovr-030" ->
            "[ Button.view theme { btn | onPress = Just NotificationInfo } [ Element.text \"info\" ]\n, Button.view theme { btn | kind = T.Primary, onPress = Just NotificationSuccess } [ Element.text \"success\" ]\n, Button.view theme { btn | kind = T.Error, onPress = Just NotificationError } [ Element.text \"error\" ]\n, Button.view theme { btn | size = T.Small, onPress = Just NotificationClear } [ Element.text \"clear\" ]\n, overlayCell \"live-notification-queue\" (Notification.view theme model.notifications)\n, chip model.notificationOutcome\n]"

        "ovr-031" ->
            "[ modalHost []\n    (Modal.view theme\n        { modalD | show = True }\n        (Modal.Custom\n            [ Element.htmlAttribute\n                (HA.attribute\n                    \"style\"\n                    \"background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px;color:var(--n-text-color)\"\n                )\n            ]\n            [ Element.text \"Custom content — you own the box; the wrapper carries `n-modal`.\" ]\n        )\n    )\n, modalHost []\n    (Modal.view theme\n        { modalD | show = model.modalCardOpen }\n        (Modal.Card\n            { modalCardD\n                | title = Just (Element.text \"A card modal\")\n                , footer = Just (Element.text \"#footer\")\n                , closable = True\n                , onClose = Just ModalCardClose\n            }\n            [ Element.text \"Unbordered by default — upstream spreads the dialog props last.\" ]\n        )\n    )\n]"

        "ovr-032" ->
            "[ modalHost []\n    (Modal.view theme\n        { modalD | show = True }\n        (Modal.Card\n            { modalCardD\n                | title = Just (Element.text \"Bordered\")\n                , bordered = True\n            }\n            [ Element.text \"Opt back into the card border.\" ]\n        )\n    )\n, modalHost []\n    (Modal.view theme\n        { modalD | show = True }\n        (Modal.Card\n            { modalCardD\n                | title = Just (Element.text \"Segmented\")\n                , segmented =\n                    { content = Card.Hard\n                    , footer = Card.Off\n                    , action = Card.Off\n                    }\n                , footer = Just (Element.text \"#footer\")\n            }\n            [ Element.text \"Content/footer separators.\" ]\n        )\n    )\n, modalHost []\n    (Modal.view darkTheme\n        { modalD | show = True }\n        (Modal.Card\n            { modalCardD | title = Just (Element.text \"Dark theme\") }\n            [ Element.text \"rgb(44, 44, 50) surface, .82 white text.\" ]\n        )\n    )\n]"

        "ovr-033" ->
            "[ modalHost []\n    (Modal.view theme\n        { modalD | show = True, showMask = False }\n        (Modal.Custom\n            [ Element.htmlAttribute\n                (HA.attribute\n                    \"style\"\n                    \"background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px\"\n                )\n            ]\n            [ Element.text \"No mask: --mask-hidden passes clicks through around the content.\" ]\n        )\n    )\n, modalHost []\n    (Modal.view theme\n        { modalD | show = True, zIndex = Just 100 }\n        (Modal.Custom\n            [ Element.htmlAttribute\n                (HA.attribute\n                    \"style\"\n                    \"background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px\"\n                )\n            ]\n            [ Element.text \"z-index: 100 on the container.\" ]\n        )\n    )\n]"

        "ovr-034" ->
            "[ modalHost []\n    (Modal.view theme\n        { modalD\n            | show = True\n            , maskTransition = Just I.EnterActive\n            , bodyTransition = Just I.EnterActive\n        }\n        (Modal.Card\n            { modalCardD | title = Just (Element.text \"Entering\") }\n            [ Element.text \"fade-in + fade-in-scale-up enter-active classes.\" ]\n        )\n    )\n]"

        "ovr-035" ->
            "[ Button.view theme\n    { btn | kind = T.Primary, onPress = Just ModalOpen }\n    [ Element.text \"Open modal\" ]\n, overlayCell \"live-modal\" <|\n    if model.modalOpen then\n        Modal.view theme\n            { modalD\n                | show = True\n                , attributes =\n                    [ Element.Events.onClick ModalMaskClick\n                    , Element.htmlAttribute (HA.id \"live-modal-tree\")\n                    ]\n            }\n            (Modal.Card\n                { modalCardD\n                    | title = Just (Element.text \"Live modal\")\n                    , closable = True\n                    , onClose = Just ModalClose\n                    , attributes = [ swallowClicks ]\n                }\n                [ Element.text (\"Ticks while open: \" ++ String.fromInt model.modalCount)\n                , Button.view theme\n                    { btn | size = T.Small, onPress = Just ModalTick }\n                    [ Element.text \"tick\" ]\n                ]\n            )\n\n    else\n        overlayHint \"modal unmounted — the fixed tree mounts on open (displayDirective: if)\"\n, chip model.modalOutcome\n]"

        "ovr-036" ->
            "[ modalHost []\n    (Drawer.view theme\n        { drawerD | show = model.drawerStaticOpen, placement = Drawer.Right, width = Just \"200px\", onMaskClick = Just DrawerStaticClose }\n        [ drawerBody ]\n    )\n, modalHost []\n    (Drawer.view theme\n        { drawerD | show = model.drawerStaticOpen, placement = Drawer.Left, width = Just \"200px\", onMaskClick = Just DrawerStaticClose }\n        [ drawerBody ]\n    )\n, modalHost []\n    (Drawer.view theme\n        { drawerD | show = model.drawerStaticOpen, placement = Drawer.Top, height = Just \"120px\", onMaskClick = Just DrawerStaticClose }\n        [ drawerBody ]\n    )\n, modalHost []\n    (Drawer.view theme\n        { drawerD | show = model.drawerStaticOpen, placement = Drawer.Bottom, height = Just \"120px\", onMaskClick = Just DrawerStaticClose }\n        [ drawerBody ]\n    )\n]"

        "ovr-037" ->
            "[ modalHost []\n    (Drawer.view theme\n        { drawerD | show = True, placement = Drawer.Right, width = Just \"220px\" }\n        [ Element.el\n            [ Element.htmlAttribute\n                (HA.attribute\n                    \"style\"\n                    \"background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px 0 0 3px;padding:14px 18px;color:var(--n-text-color);height:100%;box-sizing:border-box\"\n                )\n            ]\n            (Element.text \"You own the box; the wrapper carries `n-drawer-content-wrapper`.\")\n        ]\n    )\n]"

        "ovr-038" ->
            "[ modalHost []\n    (Drawer.view theme\n        { drawerD\n            | show = model.drawerStaticOpen\n            , placement = Drawer.Right\n            , width = Just \"180px\"\n            , showMask = Drawer.Transparent\n            , onMaskClick = Just DrawerStaticClose\n        }\n        [ drawerBody ]\n    )\n, modalHost []\n    (Drawer.view theme\n        { drawerD\n            | show = model.drawerStaticOpen\n            , placement = Drawer.Right\n            , width = Just \"180px\"\n            , showMask = Drawer.Hidden\n        }\n        [ drawerBody ]\n    )\n, modalHost []\n    (Drawer.view theme\n        { drawerD | show = model.drawerStaticOpen, placement = Drawer.Right, width = Just \"180px\", zIndex = Just 100 }\n        [ drawerBody ]\n    )\n]"

        "ovr-039" ->
            "[ modalHost []\n    (Drawer.view theme\n        { drawerD\n            | show = True\n            , placement = Drawer.Right\n            , width = Just \"220px\"\n            , nativeScrollbar = False\n        }\n        [ DrawerContent.view theme\n            { drawerContentD\n                | title = Just (Element.text \"Scrollbar body\")\n                , nativeScrollbar = False\n            }\n            [ Element.text \"Both seams swap to `NUI.Scrollbar` — `n-drawer-body` rides the scrollbar root.\" ]\n        ]\n    )\n, modalHost []\n    (Drawer.view theme\n        { drawerD\n            | show = True\n            , placement = Drawer.Right\n            , width = Just \"220px\"\n            , resizable = True\n            , showResizeTriggerHover = True\n        }\n        [ drawerBody ]\n    )\n]"

        "ovr-040" ->
            "[ modalHost []\n    (Drawer.view theme\n        { drawerD\n            | show = True\n            , placement = Drawer.Right\n            , width = Just \"220px\"\n            , maskTransition = Just I.EnterActive\n            , bodyTransition = Just I.EnterActive\n        }\n        [ drawerBody ]\n    )\n]"

        "ovr-041" ->
            "[ Radio.group theme\n    { radioGD\n        | value = Just model.drawerPlacement\n        , onChange = Just DrawerPickPlacement\n    }\n    [ Radio.choice Drawer.Left \"left\"\n    , Radio.choice Drawer.Right \"right\"\n    , Radio.choice Drawer.Top \"top\"\n    , Radio.choice Drawer.Bottom \"bottom\"\n    ]\n, Button.view theme\n    { btn | onPress = Just DrawerOpen }\n    [ Element.text \"Open drawer\" ]\n, overlayCell \"live-drawer\" <|\n    if model.drawerOpen then\n        Drawer.view theme\n            (drawerOptions model.drawerPlacement)\n            [ DrawerContent.view theme\n                { drawerContentD\n                    | title = Just (Element.text (\"Placement: \" ++ Drawer.placementName model.drawerPlacement))\n                    , closable = True\n                    , onClose = Just DrawerClose\n                }\n                [ Element.text \"The mask click and the header ✕ are both live channels.\" ]\n            ]\n\n    else\n        Element.none\n, chip (\"placement: \" ++ Drawer.placementName model.drawerPlacement ++ \" · \" ++ model.drawerOutcome)\n]"

        "ovr-042" ->
            "[ cell\n    (if model.dialogSamplesOpen then\n        Dialog.view theme\n            { dialogD\n                | kind = T.Default\n                , title = Just (Element.text \"Default\")\n                , content = Just (Element.text \"Info glyph on the base icon color.\")\n                , positiveText = Just \"OK\"\n                , onPositiveClick = Just DialogSampleClose\n            }\n\n     else\n        Element.none\n    )\n, cell\n    (if model.dialogSamplesOpen then\n        Dialog.view theme\n            { dialogD\n                | kind = T.Warning\n                , title = Just (Element.text \"Warning\")\n                , content = Just (Element.text \"A warning icon rides the title.\")\n                , positiveText = Just \"Proceed\"\n                , negativeText = Just \"Cancel\"\n                , onPositiveClick = Just DialogSampleClose\n                , onNegativeClick = Just DialogSampleClose\n            }\n\n     else\n        Element.none\n    )\n, cell\n    (if model.dialogSamplesOpen then\n        Dialog.view theme\n            { dialogD\n                | kind = T.Error\n                , title = Just (Element.text \"Error\")\n                , content = Just (Element.text \"Positive button keys to the kind.\")\n                , positiveText = Just \"Retry\"\n                , negativeText = Just \"Dismiss\"\n                , onPositiveClick = Just DialogSampleClose\n                , onNegativeClick = Just DialogSampleClose\n            }\n\n     else\n        Element.none\n    )\n]"

        "ovr-043" ->
            "[ modalHost []\n    (Modal.view theme\n        { modalD | show = model.modalDialogOpen }\n        (Modal.Dialog\n            { dialogD\n                | title = Just (Element.text \"Use dialog?\")\n                , content = Just (Element.text \"The preset body gains n-modal; .n-modal .n-dialog sizes it to 446px.\")\n                , positiveText = Just \"Confirm\"\n                , negativeText = Just \"Cancel\"\n                , onPositiveClick = Just ModalDialogClose\n                , onNegativeClick = Just ModalDialogClose\n            }\n        )\n    )\n, modalHost []\n    (Modal.view theme\n        { modalD | show = model.modalConfirmOpen }\n        (Modal.Confirm\n            { dialogD\n                | kind = T.Info\n                , title = Just (Element.text \"A deprecated alias\")\n                , content = Just (Element.text \"confirm renders the identical body — only the constructor differs.\")\n                , positiveText = Just \"Got it\"\n                , onPositiveClick = Just ModalConfirmClose\n            }\n        )\n    )\n]"

        "ovr-044" ->
            "[ dialogState\n    [ { dialogPI\n        | key = \"d1\"\n        , zIndex = Just 2000\n        , options =\n            { dialogD\n                | kind = T.Warning\n                , title = Just (Element.text \"Delete file?\")\n                , content = Just (Element.text \"A settled dialog — phase Nothing; the caller allocated z-index 2000.\")\n                , positiveText = Just \"OK\"\n                , negativeText = Just \"Cancel\"\n            }\n      }\n    ]\n, dialogState\n    [ { dialogPI\n        | key = \"d2\"\n        , phase = Just I.EnterActive\n        , zIndex = Just 2000\n        , options =\n            { dialogD\n                | kind = T.Info\n                , title = Just (Element.text \"Entering\")\n                , content = Just (Element.text \"Mid-enter — the mask fades in, the body scales up from 0.5.\")\n                , positiveText = Just \"OK\"\n                , negativeText = Just \"Cancel\"\n            }\n      }\n    , { dialogPI\n        | key = \"d3\"\n        , phase = Just I.LeaveActive\n        , zIndex = Just 2001\n        , options =\n            { dialogD\n                | kind = T.Error\n                , title = Just (Element.text \"Leaving\")\n                , content = Just (Element.text \"Mid-leave — destroy stamped LeaveFrom; remove splices on after-leave.\")\n                , positiveText = Just \"OK\"\n                , negativeText = Just \"Cancel\"\n            }\n      }\n    ]\n]"

        "ovr-045" ->
            "[ cell\n    (if model.dialogSamplesOpen then\n        Dialog.view theme\n            { dialogD\n                | kind = T.Success\n                , iconPlacement = Dialog.IconTop\n                , title = Just (Element.text \"Centred\")\n                , content = Just (Element.text \"Icon-top swaps the margins and centres the icon above.\")\n                , positiveText = Just \"OK\"\n                , onPositiveClick = Just DialogSampleClose\n            }\n\n     else\n        Element.none\n    )\n, cell\n    (Dialog.view theme\n        { dialogD\n            | title = Just (Element.text \"Bordered\")\n            , bordered = True\n            , content = Just (Element.text \"Opt back into the border.\")\n            , action =\n                Just\n                    [ Element.text \"#action — the slot replaces the buttons\"\n                    ]\n        }\n    )\n]"

        "ovr-046" ->
            "[ cell\n    (Dialog.view theme\n        { dialogD\n            | kind = T.Error\n            , title = Just (Element.text \"Deleting…\")\n            , content = Just (Element.text \"Positive disabled+loading; the negative never loads.\")\n            , positiveText = Just \"Delete\"\n            , negativeText = Just \"Cancel\"\n            , loading = True\n        }\n    )\n, cell\n    (Dialog.view theme\n        { dialogD\n            | title = Just (Element.text \"Overrides\")\n            , content = Just (Element.text \"positiveProps updates the derived base (spread semantics).\")\n            , positiveText = Just \"Round primary\"\n            , negativeText = Just \"Round negative\"\n            , positiveProps = Just (\\b -> { b | round = True })\n            , negativeProps = Just (\\b -> { b | round = True })\n        }\n    )\n, cell\n    (Dialog.view darkTheme\n        { dialogD\n            | kind = T.Warning\n            , title = Just (Element.text \"Dark\")\n            , content = Just (Element.text \"modalColor surface, dark-common close/kind colors.\")\n            , positiveText = Just \"OK\"\n        }\n    )\n]"

        "ovr-047" ->
            "[ Button.view theme\n    { btn | onPress = Just DialogOpen }\n    [ Element.text \"Open dialog\" ]\n, overlayCell \"live-dialog\" <|\n    if model.dialogOpen then\n        Modal.view theme\n            { modalD\n                | show = True\n                , attributes = [ Element.htmlAttribute (HA.id \"live-dialog-tree\") ]\n            }\n            (Modal.Dialog\n                { dialogD\n                    | title = Just (Element.text \"Submit the report?\")\n                    , content = Just (Element.text \"Every button fires its own channel — the outcome is below.\")\n                    , positiveText = Just \"Submit\"\n                    , negativeText = Just \"Not yet\"\n                    , closable = True\n                    , onPositiveClick = Just DialogPositive\n                    , onNegativeClick = Just DialogNegative\n                    , onClose = Just DialogClose\n                }\n            )\n\n    else\n        Element.none\n, chip (\"outcome: \" ++ model.dialogOutcome)\n]"

        "pic-001" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 230) ]\n    [ Select.view theme\n        { selectD\n            | value = model.selSingle\n            , placeholder = \"Pick a song\"\n            , clearable = True\n            , active = model.selOpen\n            , onClear = Just SelectSingleCleared\n            , attributes =\n                [ Element.htmlAttribute (HA.id \"live-select-single\")\n                , Element.Events.onClick ToggleSelectSingle\n                ]\n        }\n        songOptions\n    , chip (\"value: \" ++ describe (valueKey model.selSingle |> Maybe.andThen (\\k -> selectLabel k songOptions)))\n    , if model.selOpen then\n        Select.menu theme\n            { selMenuD\n                | value = model.selSingle\n                , onToggle = Just SelectSinglePicked\n                , attributes =\n                    [ Element.htmlAttribute (HA.id \"live-select-single-menu\")\n                    , Element.width (Element.px 230)\n                    ]\n            }\n            songOptions\n\n      else\n        Element.none\n    ]\n]"

        "pic-002" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 280) ]\n    [ Select.view theme\n        { selectD\n            | multiple = True\n            , value = model.selMulti\n            , placeholder = \"Pick songs\"\n            , clearable = True\n            , active = model.selMultiOpen\n            , onClear = Just SelectMultiCleared\n            , onDeleteTag = Just SelectMultiTagDeleted\n            , attributes =\n                [ Element.htmlAttribute (HA.id \"live-select-multiple\")\n                , Element.Events.onClick ToggleSelectMulti\n                ]\n        }\n        songOptions\n    , chip (\"tags: \" ++ describeRange (valueKeys model.selMulti))\n    , if model.selMultiOpen then\n        Select.menu theme\n            { selMenuD\n                | multiple = True\n                , value = model.selMulti\n                , onToggle = Just SelectMultiPicked\n                , attributes =\n                    [ Element.htmlAttribute (HA.id \"live-select-multiple-menu\")\n                    , Element.width (Element.px 280)\n                    ]\n            }\n            songOptions\n\n      else\n        Element.none\n    ]\n]"

        "pic-003" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 200) ]\n    [ Button.view theme\n        { btnD\n            | onPress = Just TogglePopselect\n            , attributes = [ Element.htmlAttribute (HA.id \"live-popselect-trigger\") ]\n        }\n        [ Element.text (\"Align: \" ++ describe (valueKey model.popValue |> Maybe.andThen (\\k -> selectLabel k popOptions))) ]\n    , if model.popOpen then\n        Popselect.view theme\n            { popselectD\n                | width = Just \"170px\"\n                , value = model.popValue\n                , onUpdateValue = Just PopselectPicked\n                , attributes = [ Element.htmlAttribute (HA.id \"live-popselect\") ]\n            }\n            popOptions\n\n      else\n        Element.none\n    ]\n]"

        "pic-004" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 380) ]\n    [ Cascader.view theme\n        { cascaderD\n            | value = model.cascValue\n            , placeholder = \"Pick a region\"\n            , clearable = True\n            , hover = model.cascOpen\n            , active = model.cascOpen\n            , onClear = Just CascaderCleared\n            , attributes =\n                [ Element.htmlAttribute (HA.id \"live-cascader\")\n                , Element.Events.onClick ToggleCascader\n                ]\n        }\n        cascOptions\n    , chip (\"path: \" ++ cascValueText model.cascValue)\n    , if model.cascOpen then\n        Cascader.menu theme\n            { cascMenuD\n                | hoverKey = model.cascHover\n                , value = model.cascValue\n                , expandTrigger = Cascader.Hover\n                , onHover = Just CascaderHovered\n                , onToggle = Just CascaderToggled\n                , attributes =\n                    [ Element.htmlAttribute (HA.id \"live-cascader-menu\")\n                    , Element.width (Element.px 380)\n                    ]\n            }\n            cascOptions\n\n      else\n        Element.none\n    ]\n]"

        "pic-005" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 280) ]\n    [ Element.el\n        [ Element.width Element.fill, Element.Events.onClick ToggleTreeSelect ]\n        (TreeSelect.view theme (tsOptions model))\n    , chip (\"selected: \" ++ describe (valueKey model.tsValue |> Maybe.andThen treeLabel))\n    , if model.tsOpen then\n        Element.el\n            [ Element.width (Element.px 280), Element.htmlAttribute (HA.id \"live-treeselect-menu\") ]\n            (TreeSelect.menu theme (tsOptions model))\n\n      else\n        Element.none\n    ]\n]"

        "pic-006" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 260) ]\n    [ AutoComplete.view theme\n        { acD\n            | value = model.acText\n            , onInput = Just AcTyped\n            , clearable = True\n            , placeholder = \"Type a song…\"\n            , attributes = [ Element.htmlAttribute (HA.id \"live-autocomplete\") ]\n        }\n    , chip\n        (\"value: \\\"\"\n            ++ model.acText\n            ++ \"\\\" · \"\n            ++ String.fromInt (List.length (acMatches model.acText))\n            ++ \" match(es)\"\n        )\n    , if acMenuOpen model then\n        AutoComplete.menu theme\n            { acMenuD\n                | onToggle = Just AcPicked\n                , empty = Just (Element.text \"No match\")\n                , attributes =\n                    [ Element.htmlAttribute (HA.id \"live-autocomplete-menu\")\n                    , Element.width (Element.px 260)\n                    ]\n            }\n            (acMatches model.acText)\n\n      else\n        Element.none\n    ]\n]"

        "pic-007" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 320) ]\n    [ Mention.view theme\n        { mnD\n            | value = model.mnText\n            , onInput = Just MnTyped\n            , placeholder = \"Type @ to mention\"\n            , attributes = [ Element.htmlAttribute (HA.id \"live-mention\") ]\n        }\n    , chip (maybeChip \"run: @\" (mnRun model.mnText))\n    , if mnRun model.mnText /= Nothing then\n        Mention.menu theme\n            { mnMenuD\n                | onToggle = Just MnPicked\n                , empty = Just (Element.text \"No match\")\n                , attributes =\n                    [ Element.htmlAttribute (HA.id \"live-mention-menu\")\n                    , Element.width (Element.px 260)\n                    ]\n            }\n            (mnMatches model.mnText)\n\n      else\n        Element.none\n    ]\n]"

        "pic-008" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 260) ]\n    [ Element.el\n        [ Element.width Element.fill, Element.htmlAttribute (HA.id \"live-datepicker\") ]\n        (DatePicker.view theme (dpSingleOpts model))\n    , chip (\"committed: \" ++ dpValueText model.dpValue)\n    , if model.dpShow then\n        Element.el\n            [ Element.width (Element.px 310), Element.htmlAttribute (HA.id \"live-datepicker-panel\") ]\n            (DatePicker.panel theme (dpSingleOpts model))\n\n      else\n        Element.none\n    ]\n]"

        "pic-009" ->
            "[ Element.column [ Element.spacing 8, Element.width Element.fill ]\n    [ Element.el\n        [ Element.width Element.fill, Element.htmlAttribute (HA.id \"live-daterange\") ]\n        (DatePicker.view theme (dpRangeOpts model))\n    , chip (dpRangeText_ model)\n    , if model.dpRangeShow then\n        Element.el\n            [ Element.width Element.fill, Element.htmlAttribute (HA.id \"live-daterange-panel\") ]\n            (DatePicker.panel theme (dpRangeOpts model))\n\n      else\n        Element.none\n    ]\n]"

        "pic-010" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 220) ]\n    [ Element.el\n        [ Element.width Element.fill, Element.htmlAttribute (HA.id \"live-timepicker\") ]\n        (TimePicker.view theme (tpOpts model))\n    , chip\n        (\"value: \"\n            ++ (case model.tpValue of\n                    Just ms ->\n                        TimePicker.formatValue \"HH:mm:ss\" Time.utc ms\n\n                    Nothing ->\n                        \"unset\"\n               )\n        )\n    , Button.view theme { btnD | onPress = Just TpClosed, size = T.Tiny } [ Element.text \"Close panel\" ]\n    , if model.tpShow then\n        Element.el\n            [ Element.width (Element.px 220), Element.htmlAttribute (HA.id \"live-timepicker-panel\") ]\n            (TimePicker.panel theme (tpOpts model))\n\n      else\n        Element.none\n    ]\n]"

        "pic-011" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 260) ]\n    [ Element.el\n        [ Element.width Element.fill, Element.htmlAttribute (HA.id \"live-colorpicker\") ]\n        (ColorPicker.view theme (cpTriggerOpts model))\n    , Element.row [ Element.spacing 10 ]\n        [ colorSwatch model.cpValue\n        , chip (\"value: \" ++ cpHexText model.cpValue)\n        , chip (\"undo \" ++ String.fromInt (List.length model.cpUndo) ++ \"/\" ++ String.fromInt (List.length model.cpRedo) ++ \" redo\")\n        ]\n    , if model.cpShow then\n        Element.el\n            [ Element.width (Element.px 260), Element.htmlAttribute (HA.id \"live-colorpicker-panel\") ]\n            (ColorPicker.panel theme (cpPanelOpts model))\n\n      else\n        Element.none\n    ]\n]"

        "pic-012" ->
            "[ Select.view theme\n    { selectD | attributes = [ Element.width (Element.px 200) ] }\n    selectOptions\n]"

        "pic-013" ->
            "[ Select.view theme\n    { selectD\n        | value = model.specSelClearable\n        , clearable = True\n        , hover = True\n        , onClear = Just SpecSelCleared\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    selectOptions\n]"

        "pic-014" ->
            "[ Select.view theme\n    { selectD\n        | filterable = True\n        , active = True\n        , pattern = \"\"\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    selectOptions\n]"

        "pic-015" ->
            "[ Select.view theme\n    { selectD\n        | multiple = True\n        , maxTagCount = Just 3\n        , value = model.specSelMulti\n        , onDeleteTag = Just SpecSelMultiTagDeleted\n        , attributes = [ Element.width (Element.px 260) ]\n    }\n    letterOptions\n]"

        "pic-016" ->
            "[ Select.view theme\n    { selectD\n        | multiple = True\n        , filterable = True\n        , active = True\n        , pattern = \"dri\"\n        , value = model.specSelMultiFilter\n        , onDeleteTag = Just SpecSelMultiFilterTagDeleted\n        , attributes = [ Element.width (Element.px 260) ]\n    }\n    selectOptions\n]"

        "pic-017" ->
            "[ Select.view theme\n    { selectD\n        | size = Select.Small\n        , value = SelectMenu.Single (Just \"drive\")\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    selectOptions\n, Select.view theme\n    { selectD\n        | size = Select.Large\n        , value = SelectMenu.Single (Just \"drive\")\n        , attributes = [ Element.width (Element.px 240) ]\n    }\n    selectOptions\n, Select.view theme\n    { selectD\n        | status = Just BaseSelection.Warning\n        , value = SelectMenu.Single (Just \"drive\")\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    selectOptions\n, Select.view theme\n    { selectD\n        | disabled = True\n        , value = SelectMenu.Single (Just \"drive\")\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    selectOptions\n]"

        "pic-018" ->
            "[ Select.menu theme\n    { selMenuD\n        | loading = True\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    [ SelectMenu.Option { value = \"a\", label = \"A\", disabled = False, attributes = [] }\n    , SelectMenu.Option { value = \"b\", label = \"B\", disabled = False, attributes = [] }\n    ]\n]"

        "pic-019" ->
            "[ Select.menu theme\n    { selMenuD\n        | header = Just (Element.text \"Header\")\n        , action = Just (Element.text \"#action\")\n        , value = model.specSelMenu\n        , onToggle = Just SpecSelMenuPicked\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    selectOptions\n]"

        "pic-020" ->
            "[ popoverHost Popover.Bottom\n    []\n    (Popselect.view theme\n        { popselectD\n            | width = Just \"200px\"\n            , value = model.specPopSingle\n            , onUpdateValue = Just SpecPopSinglePicked\n        }\n        popselectOptions\n    )\n]"

        "pic-021" ->
            "[ popoverHost Popover.Bottom\n    []\n    (Popselect.view theme\n        { popselectD\n            | width = Just \"200px\"\n            , multiple = True\n            , value = model.specPopMulti\n            , onUpdateValue = Just SpecPopMultiPicked\n        }\n        popselectOptions\n    )\n]"

        "pic-022" ->
            "[ SelectMenu.view theme\n    { selectMenuD\n        | size = SelectMenu.Small\n        , header = Just (Element.text \"Header\")\n        , action = Just (Element.text \"#action\")\n        , value = model.specPopSelectMenu\n        , onToggle = Just SpecPopSelectMenuPicked\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    popselectOptions\n]"

        "pic-023" ->
            "[ Cascader.view theme\n    { cascaderD\n        | value = model.specCascSingle\n        , clearable = True\n        , hover = True\n        , onClear = Just SpecCascSingleCleared\n        , attributes = [ Element.width (Element.px 280) ]\n    }\n    cascaderOptions\n, Cascader.view theme\n    { cascaderD\n        | multiple = True\n        , maxTagCount = Just 2\n        , value = model.specCascMulti\n        , onDeleteTag = Just SpecCascMultiTagDeleted\n        , attributes = [ Element.width (Element.px 320) ]\n    }\n    cascaderOptions\n]"

        "pic-024" ->
            "[ Cascader.menu theme\n    { cascMenuD\n        | hoverKey = model.specCascMenuHover\n        , multiple = True\n        , value = model.specCascMenu\n        , expandTrigger = Cascader.Click\n        , onToggle = Just SpecCascMenuToggled\n        , attributes = [ Element.width (Element.px 420) ]\n    }\n    cascaderOptions\n]"

        "pic-025" ->
            "[ Cascader.menu theme\n    { cascMenuD\n        | checkStrategy = Cascader.Child\n        , value = model.specCascChild\n        , onToggle = Just SpecCascChildPicked\n        , action = Just (Element.text \"#action\")\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n    cascaderOptions\n, Cascader.menu theme\n    { cascMenuD | attributes = [ Element.width (Element.px 200) ] }\n    []\n]"

        "pic-026" ->
            "[ Cascader.selectMenu theme\n    { cascSelectMenuD\n        | multiple = True\n        , value = model.specCascFlat\n        , onToggle = Just SpecCascFlatToggled\n        , attributes = [ Element.width (Element.px 280) ]\n    }\n    (Cascader.filterOptions \"sub\" Cascader.All \" / \" cascaderOptions)\n]"

        "pic-027" ->
            "[ Element.column [ Element.spacing 8 ]\n    [ TreeSelect.view theme\n        (rowOpts singleCfg model.specTsSingle model.specTsSinglePending [ \"o1\" ])\n    , Element.el [ menuBox ]\n        (TreeSelect.menu theme\n            (rowOpts singleCfg model.specTsSingle model.specTsSinglePending [ \"o1\", \"o1-1\" ])\n        )\n    ]\n]"

        "pic-028" ->
            "[ Element.column [ Element.spacing 8 ]\n    [ TreeSelect.view theme\n        (rowOpts multiCfg model.specTsMulti Nothing [ \"o1\" ])\n    , Element.el [ menuBox ]\n        (TreeSelect.menu theme (rowOpts multiCfg model.specTsMulti Nothing [ \"o1\" ]))\n    ]\n]"

        "pic-029" ->
            "[ Element.column [ Element.spacing 8 ]\n    [ TreeSelect.view theme\n        (rowOpts filterCfg model.specTsFilter Nothing [ \"o1\", \"o1-1\" ]\n            |> (\\o -> { o | filterable = True, showPath = True })\n        )\n    , Element.el [ menuBox ]\n        (TreeSelect.menu theme\n            (rowOpts filterCfg model.specTsFilter Nothing [ \"o1\" ]\n                |> (\\o -> { o | filterable = True, pattern = \"eft\" })\n            )\n        )\n    ]\n]"

        "pic-030" ->
            "[ Element.column [ Element.spacing 8 ]\n    [ TreeSelect.view theme\n        { tsD\n            | options = data\n            , status = Just BaseSelection.Error\n            , clearable = True\n            , hover = True\n            , value = SelectMenu.Single (Just \"o2\")\n        }\n    , Element.el [ menuBox ]\n        (TreeSelect.menu theme\n            { tsD\n                | header = Just (Element.text \"Header slot\")\n                , action = Just (Element.text \"Action slot\")\n                , empty = Just (Element.text \"No data\")\n                , options = []\n            }\n        )\n    ]\n]"

        "pic-031" ->
            "[ AutoComplete.view theme\n    { acD\n        | value = model.specAcBasic\n        , onInput = Just SpecAcBasicTyped\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, AutoComplete.view theme\n    { acD\n        | value = \"v4f2\"\n        , inputAttributes =\n            [ HA.attribute \"autocomplete\" \"disabled\"\n            , HA.id \"ac-input-props\"\n            ]\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, AutoComplete.menu theme\n    { acMenuD\n        | onToggle = Just SpecAcBasicPicked\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n    [ AutoComplete.fromString \"Drive My Car\"\n    , AutoComplete.fromString \"Day Tripper\"\n    ]\n]"

        "pic-032" ->
            "[ AutoComplete.view theme\n    { acD | size = AutoComplete.Small, value = \"Dri\", attributes = [ Element.width (Element.px 200) ] }\n, AutoComplete.view theme\n    { acD | value = \"Dri\", attributes = [ Element.width (Element.px 220) ] }\n, AutoComplete.view theme\n    { acD | size = AutoComplete.Large, value = \"Dri\", attributes = [ Element.width (Element.px 240) ] }\n, AutoComplete.menu theme\n    { acMenuD | attributes = [ Element.width (Element.px 220) ] }\n    (List.take 2 selectOptions)\n]"

        "pic-033" ->
            "[ AutoComplete.view theme\n    { acD\n        | value = model.specAcGroup\n        , onInput = Just SpecAcGroupTyped\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, AutoComplete.menu theme\n    { acMenuD\n        | onToggle = Just SpecAcGroupPicked\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n    selectOptions\n]"

        "pic-034" ->
            "[ AutoComplete.view theme\n    { acD\n        | status = Just Input.Warning\n        , value = \"warn@example.com\"\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, AutoComplete.view theme\n    { acD\n        | status = Just Input.Error\n        , value = \"error@example.com\"\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, AutoComplete.view theme\n    { acD\n        | disabled = True\n        , value = \"Disabled\"\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n]"

        "pic-035" ->
            "[ AutoComplete.view theme\n    { acD\n        | value = model.specAcClearable\n        , clearable = True\n        , onInput = Just SpecAcClearableTyped\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n, AutoComplete.view theme\n    { acD\n        | value = \"Loading…\"\n        , loading = True\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n, AutoComplete.view theme\n    { acD\n        | value = \"all three\"\n        , clearable = True\n        , loading = True\n        , suffix = Just (Element.text \"@\")\n        , attributes = [ Element.width (Element.px 200) ]\n    }\n]"

        "pic-036" ->
            "[ AutoComplete.view theme\n    { acD | placeholder = \"Type to open\", attributes = [ Element.width (Element.px 220) ] }\n, AutoComplete.menu theme\n    { acMenuD\n        | empty = Just (Empty.view theme emptyD [])\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n    []\n]"

        "pic-037" ->
            "[ cell\n    (Element.column [ Element.spacing 6, Element.width Element.fill ]\n        [ AutoComplete.view theme\n            { acD | placeholder = \"clearAfterSelect → \\\"\\\"\", attributes = [ Element.width (Element.px 200) ] }\n        , chip \"onSelect \\\"Drive My Car\\\" → value = \\\"\\\"\"\n        ]\n    )\n, cell\n    (Element.column [ Element.spacing 6, Element.width Element.fill ]\n        [ AutoComplete.view theme\n            { acD\n                | value = \"Dri\"\n                , placeholder = \"append ⇒ value ++ label\"\n                , attributes = [ Element.width (Element.px 200) ]\n            }\n        , chip \"onSelect \\\"Drive My Car\\\" → \\\"DriDrive My Car\\\"\"\n        ]\n    )\n]"

        "pic-038" ->
            "[ AutoComplete.menu theme\n    { acMenuD\n        | onToggle = Just SpecAcCustomPicked\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n    [ AutoComplete.fromString \"A plain row\"\n    , SelectMenu.Custom\n        { key = \"ac-custom\"\n        , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text \"renderOption row\" ]\n        }\n    ]\n]"

        "pic-039" ->
            "[ cell\n    (Element.column [ Element.spacing 6, Element.width Element.fill ]\n        [ Mention.view theme\n            { mnD\n                | value = model.specMnBasic\n                , onInput = Just SpecMnBasicTyped\n                , attributes = [ Element.width (Element.px 220) ]\n            }\n        , Mention.menu theme\n            { mnMenuD\n                | onToggle = Just SpecMnBasicPicked\n                , attributes = [ Element.width (Element.px 220) ]\n            }\n            mentionOptions\n        ]\n    )\n, Mention.view theme\n    { mnD\n        | value = model.specMnBasic2\n        , onInput = Just SpecMnBasic2Typed\n        , placeholder = \"Type @ to mention\"\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n]"

        "pic-040" ->
            "[ Mention.view theme\n    { mnD | size = Mention.Small, value = \"@710\", attributes = [ Element.width (Element.px 200) ] }\n, Mention.view theme\n    { mnD | value = \"@710\", attributes = [ Element.width (Element.px 220) ] }\n, Mention.view theme\n    { mnD | size = Mention.Large, value = \"@710\", attributes = [ Element.width (Element.px 240) ] }\n, Mention.menu theme\n    { mnMenuD | attributes = [ Element.width (Element.px 220) ] }\n    (List.take 4 mentionOptions)\n]"

        "pic-041" ->
            "[ Element.el [ Element.width (Element.px 360) ]\n    (Mention.view theme\n        { mnD\n            | type_ = Mention.Textarea\n            , value = model.specMnTextarea\n            , onInput = Just SpecMnTextareaTyped\n            , placeholder = \"Type @ to mention\"\n        }\n    )\n]"

        "pic-042" ->
            "[ Element.el [ Element.width (Element.px 360) ]\n    (Mention.view theme\n        { mnD\n            | type_ = Mention.Textarea\n            , autosize = True\n            , value = model.specMnAutosize\n            , onInput = Just SpecMnAutosizeTyped\n        }\n    )\n]"

        "pic-043" ->
            "[ cell\n    (Element.column [ Element.spacing 6, Element.width Element.fill ]\n        [ Mention.view theme\n            { mnD\n                | value = model.specMnGroupTag\n                , onInput = Just SpecMnGroupTagTyped\n                , placeholder = \"# for tags\"\n                , attributes = [ Element.width (Element.px 200) ]\n            }\n        , chip \"prefix \\\"#\\\" → the tag list\"\n        , Mention.menu theme\n            { mnMenuD\n                | onToggle = Just (\\value -> SpecMnGroupTagPicked (\"#\" ++ value))\n                , attributes = [ Element.width (Element.px 200) ]\n            }\n            mentionTagOptions\n        ]\n    )\n, cell\n    (Element.column [ Element.spacing 6, Element.width Element.fill ]\n        [ Mention.view theme\n            { mnD\n                | value = model.specMnGroupUser\n                , onInput = Just SpecMnGroupUserTyped\n                , placeholder = \"@ for users\"\n                , attributes = [ Element.width (Element.px 200) ]\n            }\n        , chip \"prefix \\\"@\\\" → the user list\"\n        , Mention.menu theme\n            { mnMenuD\n                | onToggle = Just (\\value -> SpecMnGroupUserPicked (\"@\" ++ value))\n                , attributes = [ Element.width (Element.px 200) ]\n            }\n            mentionOptions\n        ]\n    )\n]"

        "pic-044" ->
            "[ Mention.view theme\n    { mnD\n        | value = \"@7\"\n        , placeholder = \"Fetching users…\"\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, Mention.menu theme\n    { mnMenuD | loading = True, attributes = [ Element.width (Element.px 220) ] }\n    mentionOptions\n]"

        "pic-045" ->
            "[ Mention.view theme\n    { mnD\n        | value = model.specMnGroup2\n        , onInput = Just SpecMnGroup2Typed\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, Mention.menu theme\n    { mnMenuD\n        | onToggle = Just (\\value -> SpecMnGroup2Picked value)\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n    (selectOptions\n        ++ [ SelectMenu.Custom\n                { key = \"mention-custom\"\n                , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text \"renderOption row\" ]\n                }\n           ]\n    )\n]"

        "pic-046" ->
            "[ Mention.view theme\n    { mnD\n        | status = Just Input.Warning\n        , value = \"@710\"\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, Mention.view theme\n    { mnD\n        | status = Just Input.Error\n        , value = \"@zhe\"\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n, Mention.view theme\n    { mnD\n        | disabled = True\n        , value = \"Disabled\"\n        , attributes = [ Element.width (Element.px 220) ]\n    }\n]"

        "pic-047" ->
            "[ specDpPair DpDateRow model ]"

        "pic-048" ->
            "[ specDpPair DpDatetimeRow model ]"

        "pic-049" ->
            "[ specDpPair DpDaterangeRow model ]"

        "pic-050" ->
            "[ specDpPair DpDatetimerangeRow model ]"

        "pic-051" ->
            "[ specDpPair DpMonthRow model ]"

        "pic-052" ->
            "[ specDpPair DpYearRow model ]"

        "pic-053" ->
            "[ specDpPair DpQuarterRow model ]"

        "pic-054" ->
            "[ specDpPair DpMonthrangeRow model ]"

        "pic-055" ->
            "[ specDpPair DpWeekRow model ]"

        "pic-056" ->
            "[ DatePicker.view theme { dpD | now = dpNow, size = T.Small, value = DatePicker.Single (Just dpNowMs) }\n, DatePicker.view theme { dpD | now = dpNow, value = DatePicker.Single (Just dpNowMs), clearable = True }\n, DatePicker.view theme { dpD | now = dpNow, size = T.Large, placeholder = Just \"Pick a date\" }\n, DatePicker.view theme { dpD | now = dpNow, value = DatePicker.Single (Just dpNowMs), status = Just Input.Error }\n, DatePicker.view theme { dpD | now = dpNow, value = DatePicker.Single (Just dpNowMs), disabled = True }\n]"

        "pic-057" ->
            "[ specDpPair DpShortcutsRow model ]"

        "pic-058" ->
            "[ specTpPair TpBasicRow model ]"

        "pic-059" ->
            "[ specTpPair TpHmRow model ]"

        "pic-060" ->
            "[ specTpPair Tp12Row model ]"

        "pic-061" ->
            "[ specTpPair TpActionsRow model ]"

        "pic-062" ->
            "[ specTpPair TpDisabledRow model ]"

        "pic-063" ->
            "[ TimePicker.view theme { tpD | now = dpNow, size = T.Small, value = Just tenToFiftyFour }\n, TimePicker.view theme { tpD | now = dpNow, value = Just tenToFiftyFour, clearable = True }\n, TimePicker.view theme { tpD | now = dpNow, size = T.Large, placeholder = \"Pick\" }\n, TimePicker.view theme { tpD | now = dpNow, value = Just tenToFiftyFour, disabled = True }\n, TimePicker.view theme { tpD | now = dpNow, value = Just tenToFiftyFour, status = Just Input.Error }\n]"

        "pic-064" ->
            "[ specCpPair CpBasicRow 0 model identity ]"

        "pic-065" ->
            "[ specCpPair CpAlphaRow 0 model identity ]"

        "pic-066" ->
            "[ specCpPair CpSizesRow 0 model (\\o -> { o | size = T.Small })\n, specCpPair CpSizesRow 1 model identity\n, specCpPair CpSizesRow 2 model (\\o -> { o | size = T.Large })\n]"

        "pic-067" ->
            "[ Element.column [ Element.spacing 8, Element.width (Element.px 240) ]\n    [ ColorPicker.view theme { cpD | value = Just specCpRed, disabled = True }\n    , Element.el [ Element.width (Element.px 240) ]\n        (ColorPicker.panel theme { cpD | value = Just specCpRed, disabled = True })\n    ]\n]"

        "pic-068" ->
            "[ specCpPair CpSingleModeRow 0 model identity ]"

        "pic-069" ->
            "[ specCpPair CpSwatchesRow 0 model identity ]"

        "pic-070" ->
            "[ specCpPair CpClearRow 0 model identity ]"

        "pic-071" ->
            "[ specCpPair CpPreviewRow 0 model identity ]"

        "pic-072" ->
            "[ ColorPicker.view theme\n    { cpD\n        | value = Just specCpRed\n        , customTrigger = Just (Button.view theme { btn | kind = T.Primary } [ Element.text \"Pick a colour\" ])\n    }\n]"

        "pic-073" ->
            "[ specCpPair CpUndoRow 0 model identity ]"

        _ ->
            ""
