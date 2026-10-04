module NUI.TimePicker exposing
    ( Options
    , TimeAction(..)
    , UnitFilter(..)
    , defaultOptions
    , formatValue
    , panel
    , parseInput
    , snapNow
    , view
    )

{-| Naive UI's `TimePicker` — an `NUI.Input` trigger plus a caller-mounted
columns panel (upstream mounts the panel in its own `VFollower`; the port
renders the trigger and offers the body separately, the `NUI.TreeSelect` /
`NUI.AutoComplete` composition precedent — show state, positioning,
clickoutside and keyboard are caller-owned runtime).

    import NUI.TimePicker as TimePicker

    TimePicker.view theme
        { TimePicker.defaultOptions
            | value = Just model.time
            , onUpdateValue = Just SetTime
        }

    -- the panel is a separate element — mount it yourself when `show`
    TimePicker.panel theme
        { TimePicker.defaultOptions
            | value = Just model.time
            , onUpdateValue = Just SetTime
        }

Trigger (`view`) DOM:

    div.n-time-picker
      style = 3 trigger vars → --n-icon-color-disabled-override, --n-bezier
      └─ NUI.Input.view (see its docstring) with the picker seams on:
         `passivelyActivated`, `attrSize = format.length + 4`,
         `internalForceFocus = show`, `textDecoration = 'line-through'` while
         the value is invalid, `readonly = inputReadonly || disabled`, and the
         clock icon riding `suffix` (not clearable) or `clear-icon-placeholder`
         (clearable — swaps to the clear icon over a value) inside
         `i.n-base-icon.n-time-picker-icon`.

Panel (`panel`) DOM — the body carrying the 14 time-picker vars:

    div.n-time-picker-panel [fade-in-scale-up-transition-*]
      tabindex = 0
      style = 14 vars → --n-item-border-radius
      ├─ div.n-time-picker-cols
      │   └─ per visible unit: div.n-time-picker-col
      │        [.n-time-picker-col--invalid] [.n-time-picker-col--transition-disabled]
      │        └─ NUI.Scrollbar.view > item divs + div.n-time-picker-col__padding
      ├─ div.n-time-picker-actions        — iff actions non-empty
      │    └─ NUI.Button size=tiny each (confirm: type primary + class
      │       .n-time-picker-actions__confirm + disabled iff invalid)
      └─ div[width:0;height:0][tabindex 0]  — NBaseFocusDetector

Visible units follow the format string exactly as upstream
(`hourInFormat = /H|h|K|k/.test(format)`, `format.includes('m')`,
`format.includes('s')`), plus the AM/PM column whenever `use12Hours`.

**Punts (caller-owned runtime, the port-wide convention).**

  - The scroll-to-active `scrollTimer` (`TimePicker.tsx:657-676`) measures the
    active item's `offsetTop` and scrolls each column — DOM geometry, no
    static effect. `data-active` rides the active item (`NUI.Scrollbar`'s
    position is caller-owned via `yBarStyle`).
  - The IANA `timeZone` prop is replaced by `zone : Time.Zone` (caller
    supplied; `Time.utc` by default). `formatValue` / `parseInput` take it
    explicitly.
  - The `memorizedValue` auto-restore (`watch(mergedShow)` re-emits the
    memorized value when the current one is invalid, `:801-805`) is
    caller-owned data.
  - The panel's Tab handling (`handleMenuKeydown`) is caller-owned; the inert
    focus-detector sentinel at the panel's tail is what the runtime watches.
  - Enter / Escape activation (`handleWrapperKeydownEnter` / `...Esc`),
    programmatic focus / blur, the `onActivate` / `onDeactivate` emissions,
    clickoutside and the follower placement are caller-owned (no ports in
    house style — flip `show` yourself).
  - `onUpdate:value` fires with `(value, formattedValue)` upstream; a single
    Elm message cannot carry both — use `onUpdateValue` (format with
    `formatValue` when you need the string) and `onUpdateFormattedValue`
    separately.
  - `[oracle D]` **actions order.** The port renders `opts.actions` in the
    caller's list order; upstream renders a fixed `clear, now, confirm` gated by
    membership (`Panel.tsx:328-360`). Identical for the default
    `[Now, Confirm]`; only a non-canonical caller list reorders.

`formatValue` implements the date-fns token subset `H HH h hh K k m mm s ss a`
plus `'...'` literals (`''` → `'`); everything else passes through verbatim.
`parseInput` is `strictParse` (`date-picker/src/utils.ts:480-495`): parse then
re-`format` and require string equality, else `Nothing`. Parsed fields fill from
1970-01-01 (upstream's backup is `new Date()`; the time-of-day is what the
trigger compares) and are placed in `zone` via its offset at that instant.

-}

import Element exposing (Element)
import Element.Events
import Html
import Html.Attributes as HA
import NUI.Button as Button
import NUI.Input as Input
import NUI.Internal as I
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.TimePicker as TimePickerTheme
import NUI.Types as T
import Svg
import Time



-- TYPES ------------------------------------------------------------------------


{-| The panel actions (upstream `Array<'clear' | 'now' | 'confirm' | null>`).
-}
type TimeAction
    = Clear
    | Now
    | Confirm


{-| Upstream `hours` / `minutes` / `seconds: MaybeArray<number>` — an unset
filter, a step (`number`, keep values where `value % step === 0`) or an
explicit allow-list.
-}
type UnitFilter
    = AllUnits
    | StepUnits Int
    | OnlyUnits (List Int)


{-| The trigger + panel options. Runtime behaviour (show, positioning,
activation, keyboard, clickoutside) is caller-owned — see the module
docstring.
-}
type alias Options msg =
    { value : Maybe Int
    , text : Maybe String
    , onInput : Maybe (String -> msg)
    , onUpdateValue : Maybe (Maybe Int -> msg)
    , onUpdateFormattedValue : Maybe (Maybe String -> msg)
    , onUpdateShow : Maybe (Bool -> msg)
    , onClear : Maybe msg
    , onConfirm : Maybe msg
    , onFocus : Maybe msg
    , onBlur : Maybe msg
    , show : Bool
    , format : String
    , use12Hours : Bool
    , placeholder : String
    , size : T.Size
    , bordered : Bool
    , clearable : Bool
    , status : Maybe Input.Status
    , disabled : Bool
    , inputReadonly : Bool
    , showIcon : Bool
    , actions : List TimeAction
    , hours : UnitFilter
    , minutes : UnitFilter
    , seconds : UnitFilter
    , isHourDisabled : Maybe (Int -> Bool)
    , isMinuteDisabled : Maybe (Int -> Maybe Int -> Bool)
    , isSecondDisabled : Maybe (Int -> Maybe Int -> Maybe Int -> Bool)
    , zone : Time.Zone
    , now : Time.Posix
    , transition : Maybe I.TransitionPhase
    , iconNode : Maybe (Element msg)
    }


{-| Naive UI's defaults (`format: 'HH:mm:ss'`, `placeholder: 'Select Time'`
via the en-US locale, `actions: ['now', 'confirm']`, `showIcon: true`,
`bordered: true`, `use12Hours: false`, the four-size scale defaulting
Medium; everything else false / empty, no value, no filter, no validator).
-}
defaultOptions : Options msg
defaultOptions =
    { value = Nothing
    , text = Nothing
    , onInput = Nothing
    , onUpdateValue = Nothing
    , onUpdateFormattedValue = Nothing
    , onUpdateShow = Nothing
    , onClear = Nothing
    , onConfirm = Nothing
    , onFocus = Nothing
    , onBlur = Nothing
    , show = False
    , format = "HH:mm:ss"
    , use12Hours = False
    , placeholder = "Select Time"
    , size = T.Medium
    , bordered = True
    , clearable = False
    , status = Nothing
    , disabled = False
    , inputReadonly = False
    , showIcon = True
    , actions = [ Now, Confirm ]
    , hours = AllUnits
    , minutes = AllUnits
    , seconds = AllUnits
    , isHourDisabled = Nothing
    , isMinuteDisabled = Nothing
    , isSecondDisabled = Nothing
    , zone = Time.utc
    , now = Time.millisToPosix 0
    , transition = Nothing
    , iconNode = Nothing
    }



-- VIEW -------------------------------------------------------------------------


{-| The trigger — the `.n-time-picker` wrapper (the 3 trigger vars) over the
`NUI.Input` carrying the picker seams.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.el
        [ I.classes [ "n-time-picker" ]
        , I.cssVars (triggerVars theme)
        ]
        (Input.view theme (inputOptions opts))


{-| The 3 trigger `--n-*` vars (`TimePicker.tsx:814-823`, declaration order).
-}
triggerVars : Theme -> List ( String, String )
triggerVars theme =
    let
        v =
            TimePickerTheme.vars theme
    in
    [ ( "--n-icon-color-override", v.iconColor )
    , ( "--n-icon-color-disabled-override", v.iconColorDisabled )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    ]


{-| The trigger's `NUI.Input` options — upstream's `NInput` invocation
(`TimePicker.tsx:955-1002`). The clock icon rides `suffix` when not
clearable and `clear-icon-placeholder` when clearable (upstream's own
`clearable ? 'clear-icon-placeholder' : 'suffix'` branch).
-}
inputOptions : Options msg -> Input.Options msg
inputOptions opts =
    let
        d =
            Input.defaults

        icon =
            timePickerIcon opts
    in
    { d
        | value = displayText opts
        , onInput = opts.onInput
        , placeholder = Just opts.placeholder
        , size = opts.size
        , status = opts.status
        , disabled = opts.disabled
        , readonly = opts.inputReadonly || opts.disabled
        , clearable = opts.clearable
        , bordered = opts.bordered
        , stateful = True
        , passivelyActivated = True
        , internalForceFocus = opts.show
        , textDecoration =
            if isValueInvalid opts then
                Just "line-through"

            else
                Nothing
        , attrSize = Just (String.length opts.format + 4)
        , onFocus = opts.onFocus
        , onBlur = opts.onBlur
        , suffix =
            if opts.showIcon && not opts.clearable then
                Just icon

            else
                Nothing
        , clearIconPlaceholder =
            if opts.showIcon && opts.clearable then
                Just icon

            else
                Nothing
    }


{-| The trigger's displayed string — the caller's `text` override, else the
formatted `value`, else empty.
-}
displayText : Options msg -> String
displayText opts =
    case opts.text of
        Just t ->
            t

        Nothing ->
            case opts.value of
                Just v ->
                    formatValue opts.format opts.zone v

                Nothing ->
                    ""


{-| The `i.n-base-icon.n-time-picker-icon` clock glyph (the caller's
`iconNode` slot overrides `TimeIcon`, upstream `$slots.icon ? ... : <TimeIcon/>`).
-}
timePickerIcon : Options msg -> Element msg
timePickerIcon opts =
    Element.html
        (Html.i [ HA.class "n-base-icon n-time-picker-icon" ]
            [ case opts.iconNode of
                Just el ->
                    embedHtml el

                Nothing ->
                    timeSvg
            ]
        )


{-| An `Element` inside the raw icon node — the `NUI.Scrollbar` /
`NUI.Input` `layoutWith`/`noStaticStyleSheet` embed idiom.
-}
embedHtml : Element msg -> Html.Html msg
embedHtml el =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        el



-- PANEL ------------------------------------------------------------------------


{-| The panel body — `tabindex` 0, the 14 vars, the transition phase class,
the columns, the actions row (iff non-empty), then the inert focus detector.
Mount it in your own follower-positioned wrapper.
-}
panel : Theme -> Options msg -> Element msg
panel theme opts =
    Element.column
        [ I.classes (panelClasses opts)
        , Element.htmlAttribute (HA.tabindex 0)
        , I.cssVars (panelVars theme)
        ]
        (colsNode theme opts
            :: (List.filterMap identity [ actionsNode theme opts ]
                    ++ [ focusDetectorNode ]
               )
        )


{-| The `.n-time-picker-panel` class list — the base plus the
`fade-in-scale-up-transition` phase (`TimePicker.tsx:1079`).
-}
panelClasses : Options msg -> List String
panelClasses opts =
    "n-time-picker-panel"
        :: (case opts.transition of
                Just phase ->
                    [ I.transitionClass "fade-in-scale-up-transition" phase ]

                Nothing ->
                    []
           )


{-| The panel's inline `--n-*` set — the 14 vars (`TimePicker.tsx:884-906`,
declaration order).
-}
panelVars : Theme -> List ( String, String )
panelVars theme =
    let
        v =
            TimePickerTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-item-color-hover", v.itemColorHover )
    , ( "--n-item-font-size", v.itemFontSize )
    , ( "--n-item-height", v.itemHeight )
    , ( "--n-item-opacity-disabled", v.itemOpacityDisabled )
    , ( "--n-item-text-color", v.itemTextColor )
    , ( "--n-item-text-color-active", v.itemTextColorActive )
    , ( "--n-item-width", v.itemWidth )
    , ( "--n-panel-action-padding", v.panelActionPadding )
    , ( "--n-panel-box-shadow", v.panelBoxShadow )
    , ( "--n-panel-color", v.panelColor )
    , ( "--n-panel-divider-color", v.panelDividerColor )
    , ( "--n-item-border-radius", v.itemBorderRadius )
    ]


{-| The `.n-time-picker-cols` row — one column per visible unit, in upstream
order (hour, minute, second, period).
-}
colsNode : Theme -> Options msg -> Element msg
colsNode theme opts =
    Element.row
        [ I.classes [ "n-time-picker-cols" ] ]
        (List.filterMap identity
            [ if hourVisible opts.format then
                Just (hourCol theme opts)

              else
                Nothing
            , if minuteVisible opts.format then
                Just (minuteCol theme opts)

              else
                Nothing
            , if secondVisible opts.format then
                Just (secondCol theme opts)

              else
                Nothing
            , if opts.use12Hours then
                Just (periodCol theme opts)

              else
                Nothing
            ]
        )


{-| One column — `div.n-time-picker-col` (+ `--invalid` / `--transition-disabled`
in upstream's per-column declaration order) wrapping the scrollbar body.
-}
colNode : Theme -> List String -> List (Element msg) -> Element msg
colNode theme colClasses items =
    Element.el
        [ I.classes colClasses ]
        (Scrollbar.view theme
            Scrollbar.defaults
            [ Element.column [] (items ++ [ paddingNode ]) ]
        )


paddingNode : Element msg
paddingNode =
    Element.el [ I.classes [ "n-time-picker-col__padding" ] ] Element.none


{-| `transitionDisabled`: while a transition phase is active the columns drop
their item transitions (the `--transition-disabled` modifier).
-}
transitionDisabled : Options msg -> Bool
transitionDisabled opts =
    opts.transition /= Nothing


{-| Hour column — upstream class order: base, invalid, transition-disabled
(`Panel.tsx:216-220`).
-}
hourCol : Theme -> Options msg -> Element msg
hourCol theme opts =
    colNode theme
        ([ "n-time-picker-col" ]
            ++ I.classIf (isHourInvalid opts) "n-time-picker-col--invalid"
            ++ I.classIf (transitionDisabled opts) "n-time-picker-col--transition-disabled"
        )
        (hourItems opts)


{-| Minute column — upstream class order: base, transition-disabled, invalid
(`Panel.tsx:240-244`, the exact upstream array order).
-}
minuteCol : Theme -> Options msg -> Element msg
minuteCol theme opts =
    colNode theme
        ([ "n-time-picker-col" ]
            ++ I.classIf (transitionDisabled opts) "n-time-picker-col--transition-disabled"
            ++ I.classIf (isMinuteInvalid opts) "n-time-picker-col--invalid"
        )
        (minuteItems opts)


{-| Second column — upstream class order: base, invalid, transition-disabled.
-}
secondCol : Theme -> Options msg -> Element msg
secondCol theme opts =
    colNode theme
        ([ "n-time-picker-col" ]
            ++ I.classIf (isSecondInvalid opts) "n-time-picker-col--invalid"
            ++ I.classIf (transitionDisabled opts) "n-time-picker-col--transition-disabled"
        )
        (secondItems opts)


{-| AM/PM column — upstream column order: base, invalid, transition-disabled.
`isAmPmInvalid` is never passed upstream, so `--invalid` never fires.
-}
periodCol : Theme -> Options msg -> Element msg
periodCol theme opts =
    colNode theme
        ([ "n-time-picker-col" ]
            ++ I.classIf (transitionDisabled opts) "n-time-picker-col--transition-disabled"
        )
        (periodItems opts)


{-| Hour items — upstream `hoursRef` (`Panel.tsx:97-124`): the 24-hour list
(`getTimeUnits(time.hours, hours)`), or the AM/PM-mapped 12-hour list under
`use12Hours`, whose item `value` is the 24-hour form and whose disabled flag
reads `isHourDisabled` at that 24-hour value.
-}
hourItems : Options msg -> List (Element msg)
hourItems opts =
    let
        period =
            hourPeriod opts

        current =
            hourValue opts

        base =
            baseMs opts
    in
    List.map
        (\label ->
            let
                value =
                    hour24Of period label (toInt label)
            in
            itemNode
                (current == Just value)
                (hourDisabled opts value)
                (clickInt opts (setHour opts.zone base value))
                label
        )
        (units hoursBase opts.hours period)


{-| Minute items — upstream `minutesRef`: `getTimeUnits(time.minutes, minutes)`,
`isMinuteDisabled(minute, hour)`.
-}
minuteItems : Options msg -> List (Element msg)
minuteItems opts =
    let
        current =
            minuteValue opts

        base =
            baseMs opts
    in
    List.map
        (\label ->
            let
                value =
                    toInt label

                disabled =
                    Maybe.map (\f -> f value (hourValue opts)) opts.isMinuteDisabled
                        |> Maybe.withDefault False
            in
            itemNode (current == Just value) disabled (clickInt opts (setMinute opts.zone base value)) label
        )
        (units minutesBase opts.minutes Nothing)


{-| Second items — upstream `secondsRef`: `getTimeUnits(time.seconds, seconds)`,
`isSecondDisabled(second, minute, hour)`.
-}
secondItems : Options msg -> List (Element msg)
secondItems opts =
    let
        current =
            secondValue opts

        base =
            baseMs opts
    in
    List.map
        (\label ->
            let
                value =
                    toInt label

                disabled =
                    Maybe.map (\f -> f value (minuteValue opts) (hourValue opts)) opts.isSecondDisabled
                        |> Maybe.withDefault False
            in
            itemNode (current == Just value) disabled (clickInt opts (setSecond opts.zone base value)) label
        )
        (units secondsBase opts.seconds Nothing)


{-| AM/PM items — upstream `amPmRef` (`Panel.tsx:130-160`): AM is disabled
when every hour 0–11 is disabled, PM when every hour 12–23 is; no validator
means neither is disabled.
-}
periodItems : Options msg -> List (Element msg)
periodItems opts =
    let
        current =
            amPmValue opts

        base =
            baseMs opts
    in
    List.map
        (\( label, period ) ->
            itemNode
                (current == Just period)
                (periodDisabled opts period)
                (clickInt opts (setPeriod opts.zone base period))
                label
        )
        [ ( "AM", "am" ), ( "PM", "pm" ) ]


periodDisabled : Options msg -> String -> Bool
periodDisabled opts period =
    case opts.isHourDisabled of
        Nothing ->
            False

        Just isDisabled ->
            List.all isDisabled (hoursInPeriod period)


hoursInPeriod : String -> List Int
hoursInPeriod period =
    if period == "am" then
        List.range 0 11

    else
        List.range 12 23


{-| One column item — `div.n-time-picker-col__item` (+ `--active` / `--disabled`),
`data-active=""` when active, clickable only when enabled.
-}
itemNode : Bool -> Bool -> Maybe msg -> String -> Element msg
itemNode active disabled click label =
    Element.el
        (I.classes
            ([ "n-time-picker-col__item" ]
                ++ I.classIf active "n-time-picker-col__item--active"
                ++ I.classIf disabled "n-time-picker-col__item--disabled"
            )
            :: Element.width Element.fill
            :: (if active then
                    [ Element.htmlAttribute (HA.attribute "data-active" "") ]

                else
                    []
               )
            ++ (case click of
                    Just m ->
                        [ Element.Events.onClick m ]

                    Nothing ->
                        []
               )
        )
        (Element.text label)


{-| The `.n-time-picker-actions` row — absent when `actions` is empty. Each
action is an `NUI.Button` size `tiny`; confirm is `type=primary` with the
`.n-time-picker-actions__confirm` marker and `disabled` while the value is
invalid (`Panel.tsx:328-360`).
-}
actionsNode : Theme -> Options msg -> Maybe (Element msg)
actionsNode theme opts =
    if List.isEmpty opts.actions then
        Nothing

    else
        Just
            (Element.row
                [ I.classes [ "n-time-picker-actions" ] ]
                (List.filterMap (actionButton theme opts) opts.actions)
            )


actionButton : Theme -> Options msg -> TimeAction -> Maybe (Element msg)
actionButton theme opts action =
    let
        base =
            Button.defaults
    in
    case action of
        Clear ->
            Just
                (Button.view theme
                    { base | size = T.Tiny, onPress = opts.onClear }
                    [ Element.text "Clear" ]
                )

        Now ->
            Just
                (Button.view theme
                    { base
                        | size = T.Tiny
                        , onPress =
                            Maybe.map
                                (\toMsg ->
                                    toMsg
                                        (Just
                                            (snapNow
                                                opts.format
                                                opts.zone
                                                opts.now
                                                opts.hours
                                                opts.minutes
                                                opts.seconds
                                            )
                                        )
                                )
                                opts.onUpdateValue
                    }
                    [ Element.text "Now" ]
                )

        Confirm ->
            Just
                (Button.view theme
                    { base
                        | size = T.Tiny
                        , kind = T.Primary
                        , disabled = isValueInvalid opts
                        , onPress = opts.onConfirm
                        , attributes = [ I.classes [ "n-time-picker-actions__confirm" ] ]
                    }
                    [ Element.text "OK" ]
                )


{-| NFocusDetector's inert sentinel (`width:0;height:0`, `tabindex=0`, no
classes), always the panel's last child (the `NUI.TreeSelect` bytes).
-}
focusDetectorNode : Element msg
focusDetectorNode =
    Element.html
        (Html.div
            [ HA.attribute "style" "width:0;height:0"
            , HA.tabindex 0
            ]
            []
        )



-- UNITS ------------------------------------------------------------------------


hoursBase : List String
hoursBase =
    List.range 0 23 |> List.map fixValue


minutesBase : List String
minutesBase =
    List.range 0 59 |> List.map fixValue


secondsBase : List String
secondsBase =
    List.range 0 59 |> List.map fixValue


{-| Upstream `getTimeUnits` (`utils.ts:184-232`). `period` only affects the
hour list; minutes / seconds pass `Nothing`.
-}
units : List String -> UnitFilter -> Maybe String -> List String
units base filter period =
    case filter of
        OnlyUnits values ->
            (case period of
                Just "am" ->
                    List.filter (\v -> v < 12) values

                Just "pm" ->
                    List.map
                        (\v ->
                            if v == 12 then
                                12

                            else
                                v - 12
                        )
                        (List.filter (\v -> v >= 12) values)

                _ ->
                    values
            )
                |> List.map fixValue

        StepUnits step ->
            case period of
                Just "am" ->
                    List.filter (\h -> toInt h < 12 && modBy step (toInt h) == 0) base

                Just "pm" ->
                    List.filter (\h -> toInt h >= 12 && modBy step (toInt h) == 0) base
                        |> List.map
                            (\h ->
                                fixValue
                                    (if toInt h == 12 then
                                        12

                                     else
                                        toInt h - 12
                                    )
                            )

                _ ->
                    List.filter (\h -> modBy step (toInt h) == 0) base

        AllUnits ->
            case period of
                Just "am" ->
                    List.filter (\h -> toInt h < 12) base

                Just "pm" ->
                    List.filter (\h -> toInt h >= 12) base
                        |> List.map
                            (\h ->
                                fixValue
                                    (if toInt h == 12 then
                                        12

                                     else
                                        toInt h - 12
                                    )
                            )

                _ ->
                    base


{-| Upstream `isTimeInStep` (`utils.ts:234-246`) — an unset filter allows
every value.
-}
isTimeInStep : Int -> UnitFilter -> Bool
isTimeInStep value filter =
    case filter of
        AllUnits ->
            True

        StepUnits step ->
            modBy step value == 0

        OnlyUnits list ->
            List.member value list


{-| Upstream `findSimilarTime` (`utils.ts:248-277`) — the nearest value in the
unit list, an exact match returning itself, an empty list returning the value
(upstream throws).
-}
findSimilar : List Int -> Int -> Int
findSimilar list value =
    if List.member value list then
        value

    else
        case
            ( List.filter (\v -> v < value) list |> List.maximum
            , List.filter (\v -> v > value) list |> List.minimum
            )
        of
            ( Just lower, Just upper ) ->
                if upper - value > value - lower then
                    lower

                else
                    upper

            ( Just lower, Nothing ) ->
                lower

            ( Nothing, Just upper ) ->
                upper

            ( Nothing, Nothing ) ->
                value


snapUnit : Int -> UnitFilter -> List String -> Int
snapUnit current filter base =
    if isTimeInStep current filter then
        current

    else
        findSimilar (List.map toInt (units base filter Nothing)) current


{-| Snap the current time onto the visible units' filters — upstream
`handleNowClick` (`TimePicker.tsx:764-787`): for each unit, use the current
value when it already satisfies the filter, else `findSimilarTime`. Only the
units present in `format` are touched.
-}
snapNow : String -> Time.Zone -> Time.Posix -> UnitFilter -> UnitFilter -> UnitFilter -> Int
snapNow format zone posix hours minutes seconds =
    let
        h =
            Time.toHour zone posix

        m =
            Time.toMinute zone posix

        s =
            Time.toSecond zone posix

        mergedHour =
            if hourVisible format then
                snapUnit h hours hoursBase

            else
                h

        mergedMinute =
            if minuteVisible format then
                snapUnit m minutes minutesBase

            else
                m

        mergedSecond =
            if secondVisible format then
                snapUnit s seconds secondsBase

            else
                s
    in
    Time.posixToMillis posix
        + (mergedHour - h)
        * 3600000
        + (mergedMinute - m)
        * 60000
        + (mergedSecond - s)
        * 1000



-- UNIT STATE -------------------------------------------------------------------


{-| The value in milliseconds, or `now` when there is none — the base every
item click rebuilds from (upstream `mergedValueRef.value || getTime(now)`).
-}
baseMs : Options msg -> Int
baseMs opts =
    Maybe.withDefault (Time.posixToMillis opts.now) opts.value


hourValue : Options msg -> Maybe Int
hourValue opts =
    Maybe.map (\v -> Time.toHour opts.zone (Time.millisToPosix v)) opts.value


minuteValue : Options msg -> Maybe Int
minuteValue opts =
    Maybe.map (\v -> Time.toMinute opts.zone (Time.millisToPosix v)) opts.value


secondValue : Options msg -> Maybe Int
secondValue opts =
    Maybe.map (\v -> Time.toSecond opts.zone (Time.millisToPosix v)) opts.value


amPmValue : Options msg -> Maybe String
amPmValue opts =
    Maybe.map
        (\v ->
            if Time.toHour opts.zone (Time.millisToPosix v) < 12 then
                "am"

            else
                "pm"
        )
        opts.value


{-| The AM/PM the hour column is built against — the value's period, else
`now`'s (`amPmValue ?? getAmPm(now)`).
-}
hourPeriod : Options msg -> Maybe String
hourPeriod opts =
    if opts.use12Hours then
        Just
            (Maybe.withDefault
                (if Time.toHour opts.zone opts.now < 12 then
                    "am"

                 else
                    "pm"
                )
                (amPmValue opts)
            )

    else
        Nothing


{-| A 12-hour column label's 24-hour value (`Panel.tsx:112-120`): a PM label
other than `12` shifts by twelve.
-}
hour24Of : Maybe String -> String -> Int -> Int
hour24Of period label n =
    if period == Just "pm" && label /= "12" then
        n + 12

    else
        n


hourDisabled : Options msg -> Int -> Bool
hourDisabled opts value =
    Maybe.map (\f -> f value) opts.isHourDisabled
        |> Maybe.withDefault False


{-| Replace the hour on the base timestamp, keeping the date (`TimePicker.tsx`
`handleHourClick` via `set(value, { hours })`; here a pure millisecond
shift).
-}
setHour : Time.Zone -> Int -> Int -> Int
setHour zone base value =
    base + (value - Time.toHour zone (Time.millisToPosix base)) * 3600000


setMinute : Time.Zone -> Int -> Int -> Int
setMinute zone base value =
    base + (value - Time.toMinute zone (Time.millisToPosix base)) * 60000


setSecond : Time.Zone -> Int -> Int -> Int
setSecond zone base value =
    base + (value - Time.toSecond zone (Time.millisToPosix base)) * 1000


{-| Switch AM/PM — a ±12-hour shift when the current half differs.
-}
setPeriod : Time.Zone -> Int -> String -> Int
setPeriod zone base period =
    let
        h =
            Time.toHour zone (Time.millisToPosix base)
    in
    if period == "am" && h >= 12 then
        base - 12 * 3600000

    else if period == "pm" && h < 12 then
        base + 12 * 3600000

    else
        base


clickInt : Options msg -> Int -> Maybe msg
clickInt opts newMs =
    Maybe.map (\toMsg -> toMsg (Just newMs)) opts.onUpdateValue



-- VALIDATORS -------------------------------------------------------------------


{-| Upstream `isHourInvalid` (`TimePicker.tsx:354-362`): an out-of-filter hour
or one rejected by `isHourDisabled`.
-}
isHourInvalid : Options msg -> Bool
isHourInvalid opts =
    case hourValue opts of
        Nothing ->
            False

        Just h ->
            not (isTimeInStep h opts.hours)
                || (Maybe.map (\f -> f h) opts.isHourDisabled |> Maybe.withDefault False)


isMinuteInvalid : Options msg -> Bool
isMinuteInvalid opts =
    case ( minuteValue opts, hourValue opts ) of
        ( Just m, Just h ) ->
            not (isTimeInStep m opts.minutes)
                || (Maybe.map (\f -> f m (Just h)) opts.isMinuteDisabled |> Maybe.withDefault False)

        _ ->
            False


isSecondInvalid : Options msg -> Bool
isSecondInvalid opts =
    case ( secondValue opts, minuteValue opts, hourValue opts ) of
        ( Just s, Just m, Just h ) ->
            not (isTimeInStep s opts.seconds)
                || (Maybe.map (\f -> f s (Just m) (Just h)) opts.isSecondDisabled |> Maybe.withDefault False)

        _ ->
            False


{-| Upstream `isValueInvalid` — gates the `line-through` trigger decoration
and the confirm button's `disabled`.
-}
isValueInvalid : Options msg -> Bool
isValueInvalid opts =
    isHourInvalid opts || isMinuteInvalid opts || isSecondInvalid opts



-- FORMAT / PARSE (date-fns subset) ---------------------------------------------


{-| `format(ms, format)` over the date-fns token subset the time picker uses:
`H HH h hh K k m mm s ss a`, `'...'` literals (`''` → `'`), everything else
passed through verbatim.
-}
formatValue : String -> Time.Zone -> Int -> String
formatValue format zone ms =
    let
        posix =
            Time.millisToPosix ms
    in
    scanFormat
        (Time.toHour zone posix)
        (Time.toMinute zone posix)
        (Time.toSecond zone posix)
        format


scanFormat : Int -> Int -> Int -> String -> String
scanFormat h m s str =
    case String.uncons str of
        Nothing ->
            ""

        Just ( c, rest ) ->
            if c == '\'' then
                if String.startsWith "''" str then
                    "'" ++ scanFormat h m s (String.dropLeft 2 str)

                else
                    let
                        ( literal, remaining ) =
                            takeLiteral str
                    in
                    literal ++ scanFormat h m s remaining

            else if isFieldChar c then
                let
                    ( token, remaining ) =
                        spanSame c rest
                in
                tokenValue h m s token ++ scanFormat h m s remaining

            else
                String.cons c (scanFormat h m s rest)


isFieldChar : Char -> Bool
isFieldChar c =
    List.member c [ 'H', 'h', 'K', 'k', 'm', 's', 'a' ]


spanSame : Char -> String -> ( String, String )
spanSame c rest =
    let
        ( same, remaining ) =
            takeWhile ((==) c) (String.toList rest)
    in
    ( String.cons c (String.fromList same), String.fromList remaining )


{-| A single-quoted literal (the leading quote is already consumed by the
caller's lookahead, `str` still starts with it). `''` inside is an escaped
quote; an unterminated literal runs to the end.
-}
takeLiteral : String -> ( String, String )
takeLiteral str =
    goLiteral (String.toList (String.dropLeft 1 str)) []


goLiteral : List Char -> List Char -> ( String, String )
goLiteral chars acc =
    case chars of
        [] ->
            ( String.fromList (List.reverse acc), "" )

        '\'' :: '\'' :: rest ->
            goLiteral rest ('\'' :: acc)

        '\'' :: rest ->
            ( String.fromList (List.reverse acc), String.fromList rest )

        c :: rest ->
            goLiteral rest (c :: acc)


tokenValue : Int -> Int -> Int -> String -> String
tokenValue h m s token =
    case token of
        "H" ->
            String.fromInt h

        "HH" ->
            pad2 h

        "h" ->
            String.fromInt (hour12 h)

        "hh" ->
            pad2 (hour12 h)

        "K" ->
            String.fromInt (modBy 12 h)

        "k" ->
            String.fromInt
                (if h == 0 then
                    24

                 else
                    h
                )

        "m" ->
            String.fromInt m

        "mm" ->
            pad2 m

        "s" ->
            String.fromInt s

        "ss" ->
            pad2 s

        "a" ->
            if h < 12 then
                "AM"

            else
                "PM"

        _ ->
            token


hour12 : Int -> Int
hour12 h =
    if modBy 12 h == 0 then
        12

    else
        modBy 12 h


{-| Upstream `strictParse` (`date-picker/src/utils.ts:480-495`): parse, then
re-`format` and require string equality, else `Nothing`. Parsed fields fill
from the epoch civil day (1970-01-01), placed in `zone`.
-}
parseInput : String -> Time.Zone -> String -> Maybe Int
parseInput format zone input =
    case parseFields format input emptyParsed of
        Nothing ->
            Nothing

        Just parsed ->
            let
                civil =
                    { year = 1970
                    , month = 1
                    , day = 1
                    , hour = Maybe.withDefault 0 (applyPeriod parsed)
                    , minute = Maybe.withDefault 0 parsed.minute
                    , second = Maybe.withDefault 0 parsed.second
                    }

                ms =
                    civilToPosixMs zone civil
            in
            if formatValue format zone ms == input then
                Just ms

            else
                Nothing


type alias Parsed =
    { hour : Maybe Int
    , minute : Maybe Int
    , second : Maybe Int
    , period : Maybe String
    }


emptyParsed : Parsed
emptyParsed =
    { hour = Nothing, minute = Nothing, second = Nothing, period = Nothing }


parseFields : String -> String -> Parsed -> Maybe Parsed
parseFields fmt inp acc =
    if String.isEmpty fmt then
        if String.isEmpty inp then
            Just acc

        else
            Nothing

    else
        case String.uncons fmt of
            Nothing ->
                Just acc

            Just ( c, rest ) ->
                if c == '\'' then
                    if String.startsWith "''" fmt then
                        if String.startsWith "'" inp then
                            parseFields (String.dropLeft 2 fmt) (String.dropLeft 1 inp) acc

                        else
                            Nothing

                    else
                        let
                            ( literal, remainingFmt ) =
                                takeLiteral fmt
                        in
                        if String.startsWith literal inp then
                            parseFields remainingFmt (String.dropLeft (String.length literal) inp) acc

                        else
                            Nothing

                else if List.member c [ 'H', 'h', 'K', 'k', 'm', 's' ] then
                    let
                        ( token, remainingFmt ) =
                            spanSame c rest

                        ( digits, remainingInp ) =
                            takeDigits 2 inp

                        needsTwo =
                            String.length token >= 2
                    in
                    if String.isEmpty digits || (needsTwo && String.length digits < 2) then
                        Nothing

                    else
                        case String.toInt digits of
                            Nothing ->
                                Nothing

                            Just n ->
                                parseFields remainingFmt remainingInp (setField token n acc)

                else if c == 'a' then
                    let
                        head2 =
                            String.toLower (String.left 2 inp)
                    in
                    if head2 == "am" || head2 == "pm" then
                        parseFields rest (String.dropLeft 2 inp) { acc | period = Just head2 }

                    else
                        Nothing

                else if String.startsWith (String.fromChar c) inp then
                    parseFields rest (String.dropLeft 1 inp) acc

                else
                    Nothing


setField : String -> Int -> Parsed -> Parsed
setField token n acc =
    case token of
        "H" ->
            { acc | hour = Just n }

        "HH" ->
            { acc | hour = Just n }

        "h" ->
            { acc | hour = Just n }

        "hh" ->
            { acc | hour = Just n }

        "K" ->
            { acc | hour = Just (modBy 12 n) }

        "k" ->
            { acc
                | hour =
                    Just
                        (if n == 24 then
                            0

                         else
                            n
                        )
            }

        "m" ->
            { acc | minute = Just n }

        "mm" ->
            { acc | minute = Just n }

        "s" ->
            { acc | second = Just n }

        "ss" ->
            { acc | second = Just n }

        _ ->
            acc


applyPeriod : Parsed -> Maybe Int
applyPeriod parsed =
    case parsed.hour of
        Nothing ->
            Nothing

        Just h ->
            case parsed.period of
                Just "pm" ->
                    Just
                        (if h < 12 then
                            h + 12

                         else
                            h
                        )

                Just "am" ->
                    Just
                        (if h == 12 then
                            0

                         else
                            h
                        )

                _ ->
                    Just h


takeDigits : Int -> String -> ( String, String )
takeDigits max inp =
    let
        ( digits, _ ) =
            takeWhile Char.isDigit (List.take max (String.toList inp))
    in
    ( String.fromList digits, String.dropLeft (List.length digits) inp )



-- CIVIL MATH -------------------------------------------------------------------


{-| The epoch-ms of a civil datetime read as if UTC (Howard Hinnant's
`days_from_civil`).
-}
civilToUtcMs : { year : Int, month : Int, day : Int, hour : Int, minute : Int, second : Int } -> Int
civilToUtcMs c =
    (daysFromCivil c.year c.month c.day * 86400 + c.hour * 3600 + c.minute * 60 + c.second) * 1000


daysFromCivil : Int -> Int -> Int -> Int
daysFromCivil year month day =
    let
        y =
            if month <= 2 then
                year - 1

            else
                year

        era =
            (if y >= 0 then
                y

             else
                y - 399
            )
                // 400

        yearOfEra =
            y - era * 400

        monthPrime =
            modBy 12 (month + 9)

        dayOfYear =
            (153 * monthPrime + 2) // 5 + day - 1

        dayOfEra =
            yearOfEra * 365 + yearOfEra // 4 - yearOfEra // 100 + dayOfYear
    in
    era * 146097 + dayOfEra - 719468


{-| `zone`'s offset (local − UTC) at the instant `ms`, read via
`Time.to*` and re-serialised as if UTC.
-}
zoneOffsetMs : Time.Zone -> Int -> Int
zoneOffsetMs zone ms =
    let
        posix =
            Time.millisToPosix ms

        local =
            { year = Time.toYear zone posix
            , month = monthNumber (Time.toMonth zone posix)
            , day = Time.toDay zone posix
            , hour = Time.toHour zone posix
            , minute = Time.toMinute zone posix
            , second = Time.toSecond zone posix
            }
    in
    civilToUtcMs local - ms


{-| A civil datetime in `zone` as epoch-ms (the offset read at the UTC
instant, so no `Zone` internals are needed).
-}
civilToPosixMs : Time.Zone -> { year : Int, month : Int, day : Int, hour : Int, minute : Int, second : Int } -> Int
civilToPosixMs zone civil =
    let
        utc =
            civilToUtcMs civil
    in
    utc - zoneOffsetMs zone utc


monthNumber : Time.Month -> Int
monthNumber month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12



-- VISIBILITY -------------------------------------------------------------------


{-| Upstream `hourInFormat` — `/H|h|K|k/.test(format)` (raw, quotes included).
-}
hourVisible : String -> Bool
hourVisible format =
    List.any (\c -> List.member c [ 'H', 'h', 'K', 'k' ]) (String.toList format)


minuteVisible : String -> Bool
minuteVisible format =
    String.contains "m" format


secondVisible : String -> Bool
secondVisible format =
    String.contains "s" format



-- SMALL HELPERS ----------------------------------------------------------------


{-| The clock glyph (`_internal/icons/Time.tsx`, verbatim path / polyline).
-}
timeSvg : Html.Html msg
timeSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 512 512"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M256,64C150,64,64,150,64,256s86,192,192,192,192-86,192-192S362,64,256,64Z"
            , HA.attribute "style" "fill: none; stroke: currentColor; stroke-miterlimit: 10; stroke-width: 32px;"
            ]
            []
        , Svg.node "polyline"
            [ HA.attribute "points" "256 128 256 272 352 272"
            , HA.attribute "style" "fill: none; stroke: currentColor; stroke-linecap: round; stroke-linejoin: round; stroke-width: 32px;"
            ]
            []
        ]


takeWhile : (a -> Bool) -> List a -> ( List a, List a )
takeWhile pred list =
    case list of
        [] ->
            ( [], [] )

        x :: xs ->
            if pred x then
                let
                    ( kept, rest ) =
                        takeWhile pred xs
                in
                ( x :: kept, rest )

            else
                ( [], list )


fixValue : Int -> String
fixValue n =
    pad2 n


pad2 : Int -> String
pad2 n =
    String.padLeft 2 '0' (String.fromInt n)


toInt : String -> Int
toInt s =
    String.toInt s |> Maybe.withDefault 0
