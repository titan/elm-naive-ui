module Live.Pickers exposing (Model, Msg, init, subscriptions, update, view)

{-| LIVE demos — a real update loop for the pickers family: Select, Popselect,
Cascader, TreeSelect, AutoComplete, Mention, DatePicker, TimePicker,
ColorPicker.

Every picker's open state (menu / panel show) and value are caller-owned per
the port's contract. Where the port ships the interaction algebra as pure
helpers, update uses those instead of re-deriving semantics
(`Select.toggleValue`, `Popselect.toggleValue`, `Cascader.toggleValue`,
`TreeSelect.handleNodeClick` / `deleteOption`, `Tree.toggleExpand`,
`DatePicker.singleDateClick` / `dualDateClick` / `dualHover` /
`sanitizeValue`, `defaultActions`, `TimePicker.formatValue`,
`ColorPicker.convertColor` / `getModeFromValue`).

Menus and panels are separate caller-mounted bodies (upstream mounts each in
its own follower): the trigger always renders, the body only while open.

Oracle-round divergences (tasks/recon/live-oracle.md):

  - [oracle D] **AutoComplete hides the empty-state menu** — `acMenuOpen`
    requires non-empty matches, so the menu's configured `empty` slot is
    unreachable (upstream shows the empty-state menu while focused with
    text). The Mention row in this module mounts its `empty` slot correctly.
  - [oracle D] **dpSingleCloses re-runs `singleDateClick` against
    `Single Nothing`** — sound, because the helper's `close` is type-only
    (closes for Date/Week/Year panels) and the demo discards the re-derived
    value; the reconstruction is just how the close flag is reached.
  - [smoke note — resolved 2026-10] **The daterange panel now opens from the
    DOM.** `NUI.Input`'s pair inputs carry `onFocus`/`onBlur` (mirrored into
    `pairEvents`, upstream `Input.tsx:1289/1422`), so `DpRangeFocused` fires
    from either input; the LIVE smoke drives the full two-click
    `dualDateClick` flow (day A → hover preview → day B → Confirm) here and
    the single-date panel alongside it.

-}

import Browser.Dom
import Browser.Events
import Element exposing (Element)
import Element.Border as Border
import Element.Events
import Html.Attributes as HA
import Json.Decode
import NUI.AutoComplete as AutoComplete
import NUI.Button as Button
import NUI.Cascader as Cascader
import NUI.ColorPicker as ColorPicker
import NUI.DatePicker as DatePicker
import NUI.Input as Input
import NUI.Internal.Color as Color
import NUI.Mention as Mention
import NUI.Popselect as Popselect
import NUI.Select as Select
import NUI.SelectMenu as SelectMenu
import NUI.Theme exposing (Theme)
import NUI.TimePicker as TimePicker
import NUI.Tree as Tree
import NUI.TreeSelect as TreeSelect
import NUI.Types as T
import Showcase exposing (chip, demoRow)
import Task
import Time



-- MODEL (one field per caller-owned bit of component state)


type alias Model =
    { selOpen : Bool
    , selSingle : SelectMenu.Value
    , selMultiOpen : Bool
    , selMulti : SelectMenu.Value
    , popOpen : Bool
    , popValue : SelectMenu.Value
    , cascOpen : Bool
    , cascValue : SelectMenu.Value
    , cascHover : Maybe String
    , tsOpen : Bool
    , tsValue : SelectMenu.Value
    , tsExpanded : List String
    , tsPending : Maybe String
    , acText : String
    , acFocused : Bool
    , mnText : String
    , dpShow : Bool
    , dpValue : DatePicker.Value
    , dpCal : Maybe Int
    , dpMonthPanel : Bool
    , dpRangeShow : Bool
    , dpRange : DatePicker.Value
    , dpRangeText : Maybe ( String, String )
    , dpSelecting : Bool
    , dpStartCal : Maybe Int
    , dpEndCal : Maybe Int
    , dpRangeMonthPanel : Bool
    , tpShow : Bool
    , tpValue : Maybe Int
    , cpShow : Bool
    , cpValue : Maybe String
    , cpDraft : Maybe String
    , cpMode : ColorPicker.Mode
    , cpUndo : List (Maybe String)
    , cpRedo : List (Maybe String)
    , cpDrag : Maybe ColorPicker.PointerArea
    , cpUnitText : Maybe String
    }


init : Model
init =
    { selOpen = False
    , selSingle = SelectMenu.Single Nothing
    , selMultiOpen = False
    , selMulti = SelectMenu.Multiple [ "drive" ]
    , popOpen = False
    , popValue = SelectMenu.Single Nothing
    , cascOpen = False
    , cascValue = SelectMenu.Single Nothing
    , cascHover = Nothing
    , tsOpen = False
    , tsValue = SelectMenu.Single Nothing
    , tsExpanded = [ "nav" ]
    , tsPending = Nothing
    , acText = ""
    , acFocused = False
    , mnText = "Ping "
    , dpShow = False
    , dpValue = DatePicker.Single Nothing
    , dpCal = Just dpNowMs
    , dpMonthPanel = False
    , dpRangeShow = False
    , dpRange = DatePicker.Range (Just ( may10, may20 ))
    , dpRangeText = Nothing
    , dpSelecting = False
    , dpStartCal = Just may10
    , dpEndCal = Just may20
    , dpRangeMonthPanel = False
    , tpShow = False
    , tpValue = Just tenToFiftyFour
    , cpShow = False
    , cpValue = Just cpSeed
    , cpDraft = Just cpSeed
    , cpMode = Maybe.withDefault ColorPicker.Hex (ColorPicker.getModeFromValue (Just cpSeed))
    , cpUndo = []
    , cpRedo = []
    , cpDrag = Nothing
    , cpUnitText = Nothing
    }



-- UPDATE (one case per channel; component semantics come from the port)


type Msg
    = ToggleSelectSingle
    | SelectSinglePicked String
    | SelectSingleCleared
    | ToggleSelectMulti
    | SelectMultiPicked String
    | SelectMultiTagDeleted String
    | SelectMultiCleared
    | TogglePopselect
    | PopselectPicked SelectMenu.Value
    | ToggleCascader
    | CascaderHovered String
    | CascaderToggled String
    | CascaderCleared
    | ToggleTreeSelect
    | TreeNodeClicked String
    | TreeTagDeleted String
    | TreeCleared
    | AcTyped String
    | AcPicked String
    | MnTyped String
    | MnPicked String
    | DpFocused
    | DpValueSet DatePicker.Value
    | DpCleared
    | DpCalendar DatePicker.CalendarSide Int
    | DpMonthPanelToggled Bool
    | DpRangeFocused
    | DpRangeDateClicked Int
    | DpRangeHovered Int
    | DpRangeConfirmed
    | DpRangeCleared
    | DpRangePairTyped String String Input.PairSource
    | DpRangeCalendar DatePicker.CalendarSide Int
    | DpRangeMonthPanelToggled Bool
    | TpFocused
    | TpValueSet (Maybe Int)
    | TpConfirmed
    | TpCleared
    | TpClosed
    | TpScrolled
    | CpOpened
    | CpValueUpdated (Maybe String)
    | CpModeChanged ColorPicker.Mode
    | CpConfirmed (Maybe String)
    | CpCleared
    | CpUndone
    | CpRedone
    | CpDragStarted ColorPicker.PointerArea
    | CpDragMove Int Int
    | CpDragApply Int Int { width : Float, height : Float, left : Float, bottom : Float }
    | CpDragEnd
    | CpUnitTyped Int String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TpFocused ->
            -- upstream scrollTimer: each visible column scrolls its
            -- [data-active] item to the top (scrollTo offsetTop). The
            -- columns' scroll containers carry ids via colContainerIds,
            -- and the item offsets are index * item-height — both known
            -- without a DOM read (the item height is the theme's 34px).
            ( { model | tpShow = True }, tpScrollToActive model )

        CpDragMove x y ->
            cpDragMove x y model

        _ ->
            ( updatePure msg model, Cmd.none )


updatePure : Msg -> Model -> Model
updatePure msg model =
    case msg of
        ToggleSelectSingle ->
            { model | selOpen = not model.selOpen }

        SelectSinglePicked key ->
            { model
                | selSingle = Select.toggleValue False model.selSingle key
                , selOpen = False
            }

        SelectSingleCleared ->
            -- the clear click also bubbles to the wrapper's toggle, closing it
            { model | selSingle = SelectMenu.Single Nothing, selOpen = False }

        ToggleSelectMulti ->
            { model | selMultiOpen = not model.selMultiOpen }

        SelectMultiPicked key ->
            { model | selMulti = Select.toggleValue True model.selMulti key }

        SelectMultiTagDeleted key ->
            { model | selMulti = SelectMenu.Multiple (List.filter ((/=) key) (valueKeys model.selMulti)) }

        SelectMultiCleared ->
            { model | selMulti = SelectMenu.Multiple [], selMultiOpen = False }

        TogglePopselect ->
            { model | popOpen = not model.popOpen }

        PopselectPicked value ->
            -- single popselect auto-closes on select (upstream's panel toggle)
            { model | popValue = value, popOpen = False }

        ToggleCascader ->
            { model | cascOpen = not model.cascOpen }

        CascaderHovered key ->
            -- the hover key's path is what opens the next column
            { model | cascHover = Just key }

        CascaderToggled key ->
            if cascIsLeaf key then
                { model
                    | cascValue = Cascader.toggleValue True Cascader.All model.cascValue key cascOptions
                    , cascOpen = False
                    , cascHover = Nothing
                }

            else
                { model | cascHover = Just key }

        CascaderCleared ->
            { model | cascValue = SelectMenu.Single Nothing, cascOpen = False, cascHover = Nothing }

        ToggleTreeSelect ->
            { model | tsOpen = not model.tsOpen }

        TreeNodeClicked key ->
            { model
                | tsValue = TreeSelect.handleNodeClick (tsOptions model) model.tsValue key
                , tsPending = Just key
                , tsExpanded =
                    if treeIsBranch key then
                        Tree.toggleExpand False treeData key model.tsExpanded

                    else
                        model.tsExpanded
            }

        TreeTagDeleted key ->
            { model | tsValue = TreeSelect.deleteOption (tsOptions model) model.tsValue key }

        TreeCleared ->
            { model | tsValue = TreeSelect.clearValue model.tsValue, tsOpen = False }

        AcTyped text ->
            -- focused-typed: on with the input, off after any select
            { model | acText = text, acFocused = True }

        AcPicked key ->
            -- the commit is the option's LABEL (upstream's label commit)
            { model
                | acText = Maybe.withDefault key (selectLabel key songOptions)
                , acFocused = False
            }

        MnTyped text ->
            { model | mnText = text }

        MnPicked value ->
            { model | mnText = spliceMention model.mnText value }

        DpFocused ->
            { model | dpShow = True }

        DpValueSet value ->
            -- a `date` panel closes on commit: the close flag is
            -- `singleDateClick`'s own algebra (run here against the target
            -- reconstructed from the committed timestamp)
            { model
                | dpValue = value
                , dpShow = not (dpSingleCloses value)
                , dpMonthPanel = False
            }

        DpCleared ->
            -- upstream's handleClearClick commits empty and closes
            { model | dpValue = DatePicker.Single Nothing, dpShow = False, dpMonthPanel = False }

        DpCalendar _ anchor ->
            { model | dpCal = Just anchor }

        DpMonthPanelToggled open ->
            { model | dpMonthPanel = open }

        DpRangeFocused ->
            { model | dpRangeShow = True }

        DpRangeDateClicked ts ->
            let
                result =
                    DatePicker.dualDateClick
                        { value = model.dpRange
                        , selecting = model.dpSelecting
                        , type_ = DatePicker.Daterange
                        , closeOnSelect = False
                        , updateValueOnClose = False
                        }
                        ts
            in
            { model
                | dpRange = result.value
                , dpSelecting = result.selecting
                , dpRangeShow = model.dpRangeShow && not result.close
                , dpRangeText = Nothing
            }

        DpRangeHovered ts ->
            -- the hover keeps the preview pair synced while selecting
            case
                DatePicker.dualHover
                    { value = model.dpRange
                    , selecting = model.dpSelecting
                    , memorizedStart = Nothing
                    , disabled = False
                    }
                    ts
            of
                Just value ->
                    { model | dpRange = value }

                Nothing ->
                    model

        DpRangeConfirmed ->
            -- doUpdateValue sanitizes both ends (datetimerange → second,
            -- monthrange → month, daterange → day)
            case model.dpRange of
                DatePicker.Range (Just ( a, b )) ->
                    { model
                        | dpRange =
                            DatePicker.Range
                                (Just
                                    ( DatePicker.sanitizeValue DatePicker.Daterange a
                                    , DatePicker.sanitizeValue DatePicker.Daterange b
                                    )
                                )
                        , dpRangeShow = False
                        , dpSelecting = False
                        , dpRangeText = Nothing
                        , dpRangeMonthPanel = False
                    }

                _ ->
                    { model | dpRangeShow = False, dpSelecting = False, dpRangeMonthPanel = False }

        DpRangeCleared ->
            { model
                | dpRange = DatePicker.Range Nothing
                , dpRangeText = Nothing
                , dpSelecting = False
                , dpRangeShow = False
                , dpRangeMonthPanel = False
            }

        DpRangePairTyped a b source ->
            case source of
                Input.PairClear ->
                    { model | dpRange = DatePicker.Range Nothing, dpRangeText = Nothing, dpSelecting = False }

                _ ->
                    -- typed text echoes through `rangeText` (upstream parses
                    -- on blur/enter; the parser is the port's internal)
                    { model | dpRangeText = Just ( a, b ) }

        DpRangeCalendar side anchor ->
            case side of
                DatePicker.CalStart ->
                    { model | dpStartCal = Just anchor }

                DatePicker.CalEnd ->
                    { model | dpEndCal = Just anchor }

        DpRangeMonthPanelToggled open ->
            { model | dpRangeMonthPanel = open }

        TpFocused ->
            { model | tpShow = True }

        TpScrolled ->
            -- the scroll command's ack; nothing to change (the DOM move is
            -- the point — upstream scrollTimer's scrollTop set)
            model

        TpValueSet value ->
            -- column item clicks (and Now, via snapNow) keep the panel open
            { model | tpValue = value }

        TpConfirmed ->
            { model | tpShow = False }

        TpCleared ->
            { model | tpValue = Nothing }

        TpClosed ->
            { model | tpShow = False }

        CpOpened ->
            -- the trigger emits onUpdateShow True; the draft re-syncs to the
            -- committed value on open
            { model | cpShow = True, cpDraft = model.cpValue, cpUnitText = Nothing }

        CpDragStarted area ->
            -- upstream binds document mousemove/mouseup on mousedown; here
            -- the subscription pair below drives the move/end while the
            -- drag flag is set
            { model | cpDrag = Just area }

        CpDragMove _ _ ->
            model

        CpDragApply x y rect ->
            cpDragApply x y rect model

        CpDragEnd ->
            { model | cpDrag = Nothing }

        CpUnitTyped index raw ->
            cpUnitTyped index raw model

        CpValueUpdated value ->
            { model | cpDraft = value }

        CpModeChanged mode ->
            -- the panel computed nextDisplayedMode already
            { model | cpMode = mode }

        CpConfirmed value ->
            { model
                | cpValue = value
                , cpDraft = value
                , cpUndo = model.cpValue :: model.cpUndo
                , cpRedo = []
                , cpShow = False
            }

        CpCleared ->
            { model
                | cpValue = Nothing
                , cpDraft = Nothing
                , cpUndo = model.cpValue :: model.cpUndo
                , cpRedo = []
                , cpShow = False
            }

        CpUndone ->
            case model.cpUndo of
                prev :: rest ->
                    { model
                        | cpValue = prev
                        , cpDraft = prev
                        , cpUndo = rest
                        , cpRedo = model.cpValue :: model.cpRedo
                    }

                [] ->
                    model

        CpRedone ->
            case model.cpRedo of
                next :: rest ->
                    { model
                        | cpValue = next
                        , cpDraft = next
                        , cpRedo = rest
                        , cpUndo = model.cpValue :: model.cpUndo
                    }

                [] ->
                    model


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.cpDrag of
        Just _ ->
            -- upstream binds document mousemove + mouseup while a drag is
            -- live (Pallete.tsx:34-52 etc.); Browser.Events mirrors that pair
            Sub.batch
                [ Browser.Events.onMouseMove (moveDecoder CpDragMove)
                , Browser.Events.onMouseUp (Json.Decode.succeed CpDragEnd)
                ]

        Nothing ->
            Sub.none


moveDecoder : (Int -> Int -> Msg) -> Json.Decode.Decoder Msg
moveDecoder toMsg =
    Json.Decode.map2 toMsg
        (Json.Decode.field "clientX" Json.Decode.int)
        (Json.Decode.field "clientY" Json.Decode.int)


{-| Upstream `scrollTimer` — each visible column's scroll container jumps so
the `[data-active]` item sits at the top (scrollTop = offsetTop). The item
offsets are index × item-height (34px, the theme var), computed from the
value; the containers are addressed by the `colContainerIds` seam.
-}
tpScrollToActive : Model -> Cmd Msg
tpScrollToActive model =
    let
        itemHeight =
            34

        hour =
            model.tpValue |> Maybe.map (\ms -> Time.toHour Time.utc (Time.millisToPosix ms)) |> Maybe.withDefault 0

        minute =
            model.tpValue |> Maybe.map (\ms -> Time.toMinute Time.utc (Time.millisToPosix ms)) |> Maybe.withDefault 0

        second =
            model.tpValue |> Maybe.map (\ms -> Time.toSecond Time.utc (Time.millisToPosix ms)) |> Maybe.withDefault 0

        scrollTo id top =
            Task.attempt (\_ -> TpScrolled) (Browser.Dom.setViewportOf id 0 top)
    in
    Cmd.batch
        [ scrollTo "live-tp-col-hour" (toFloat hour * itemHeight)
        , scrollTo "live-tp-col-minute" (toFloat minute * itemHeight)
        , scrollTo "live-tp-col-second" (toFloat second * itemHeight)
        ]


{-| One drag move: read the dragged surface's rect, run the port's geometry
helper against the document-space pointer, convert the result to the
panel's displayed mode. The rect read is async, so the move is carried as a
command-issued update (Task.perform against the current pointer).
-}
cpDragMove : Int -> Int -> Model -> ( Model, Cmd Msg )
cpDragMove x y model =
    case model.cpDrag of
        Nothing ->
            ( model, Cmd.none )

        Just area ->
            ( model
            , case areaId area of
                Just id ->
                    Browser.Dom.getElement id
                        |> Task.attempt
                            (\result ->
                                case result of
                                    Ok el ->
                                        CpDragApply x y { width = el.element.width, height = el.element.height, left = el.element.x, bottom = el.element.y + el.element.height }

                                    Err _ ->
                                        CpDragMove 0 0
                            )

                Nothing ->
                    Cmd.none
            )


areaId : ColorPicker.PointerArea -> Maybe String
areaId area =
    case area of
        ColorPicker.PaletteArea ->
            Just "live-cp-palette"

        ColorPicker.HueArea ->
            Just "live-cp-hue"

        ColorPicker.AlphaArea ->
            Just "live-cp-alpha"


{-| The geometry commit: `svFromPoint` / `hueFromPoint` / `alphaFromPoint`
against the freshly-read rect, converted into the displayed mode. The
pointer coordinates are viewport-relative (Browser.Events) and the rect
from `getElement` is scroll-independent document-space, so the viewport's
scroll offset is added to the pointer first.
-}
cpDragApply :
    Int
    -> Int
    -> { width : Float, height : Float, left : Float, bottom : Float }
    -> Model
    -> Model
cpDragApply x y rect model =
    case model.cpDrag of
        Nothing ->
            model

        Just area ->
            let
                nextValue =
                    case area of
                        ColorPicker.PaletteArea ->
                            let
                                { s, v } =
                                    ColorPicker.svFromPoint rect { x = toFloat x, y = toFloat y }

                                base =
                                    Maybe.withDefault { h = 0, s = 100, v = 100 } (Color.hsvaOf model.cpDraft |> Maybe.map (\c -> { h = c.h, s = c.s, v = c.v }))

                                alpha =
                                    Maybe.map .a (Color.hsvaOf model.cpDraft) |> Maybe.withDefault 1
                            in
                            ColorPicker.convertColor
                                (Color.toHsvaString (Color.hsvWithAlpha alpha { s = s, v = v, h = base.h }))
                                model.cpMode
                                (ColorPicker.getModeFromValue model.cpDraft)

                        ColorPicker.HueArea ->
                            let
                                hue =
                                    ColorPicker.hueFromPoint { width = rect.width, left = rect.left } (toFloat x)

                                base =
                                    Maybe.withDefault { h = toFloat hue, s = 100, v = 100 } (Color.hsvaOf model.cpDraft |> Maybe.map (\c -> { h = c.h, s = c.s, v = c.v }))

                                alpha =
                                    Maybe.map .a (Color.hsvaOf model.cpDraft) |> Maybe.withDefault 1
                            in
                            ColorPicker.convertColor
                                (Color.toHsvaString (Color.hsvWithAlpha alpha { base | h = toFloat hue }))
                                model.cpMode
                                (ColorPicker.getModeFromValue model.cpDraft)

                        ColorPicker.AlphaArea ->
                            let
                                a =
                                    ColorPicker.alphaFromPoint { width = rect.width, left = rect.left } (toFloat x)

                                base =
                                    Color.hsvaOf model.cpDraft |> Maybe.withDefault (Color.hsvWithAlpha 1 { h = 0, s = 100, v = 100 })
                            in
                            ColorPicker.convertColor
                                (Color.toHsvaString { base | a = a })
                                model.cpMode
                                (ColorPicker.getModeFromValue model.cpDraft)
            in
            { model | cpDraft = nextValue, cpUnitText = Nothing }


{-| One unit input keystroke — upstream `ColorInputUnit` parses per-unit
(`normalizeHexaUnit` for HEX, `normalizeRgbUnit` / `normalizeHueUnit` /
`normalizeSlvUnit` for the channels, `normalizeAlphaUnit` for A). The port
commits per keystroke (divergence 8), so a complete parse updates the draft
immediately; an incomplete parse keeps the raw text in `cpUnitText` and the
input echoes it (the panel's value stays the last good colour).
-}
cpUnitTyped : Int -> String -> Model -> Model
cpUnitTyped index raw model =
    let
        parsed : Maybe (Maybe String)
        parsed =
            case model.cpMode of
                ColorPicker.Hex ->
                    if ColorPicker.normalizeHexaUnit raw then
                        Just (ColorPicker.convertColor (String.toUpper raw) model.cpMode Nothing)

                    else
                        Nothing

                _ ->
                    let
                        labels =
                            unitLabels model

                        label =
                            List.head (List.drop index labels)

                        baseHSV =
                            Maybe.withDefault (Color.hsvWithAlpha 1 { h = 0, s = 100, v = 100 }) (Color.hsvaOf model.cpDraft)

                        alpha =
                            Maybe.map .a (Color.hsvaOf model.cpDraft) |> Maybe.withDefault 1
                    in
                    case label of
                        Just "A" ->
                            ColorPicker.normalizeAlphaUnit raw
                                |> Maybe.map (\a -> ColorPicker.convertColor (Color.toHsvaString { baseHSV | a = a }) model.cpMode Nothing)

                        Just "H" ->
                            ColorPicker.normalizeHueUnit raw
                                |> Maybe.map (\h -> ColorPicker.convertColor (Color.toHsvaString (Color.hsvWithAlpha alpha { h = toFloat h, s = baseHSV.s, v = baseHSV.v })) model.cpMode Nothing)

                        Just "S" ->
                            ColorPicker.normalizeSlvUnit raw
                                |> Maybe.map (\s -> ColorPicker.convertColor (Color.toHsvaString (Color.hsvWithAlpha alpha { h = baseHSV.h, s = toFloat s, v = baseHSV.v })) model.cpMode Nothing)

                        Just "V" ->
                            ColorPicker.normalizeSlvUnit raw
                                |> Maybe.map (\v -> ColorPicker.convertColor (Color.toHsvaString (Color.hsvWithAlpha alpha { h = baseHSV.h, s = baseHSV.s, v = toFloat v })) model.cpMode Nothing)

                        Just "R" ->
                            channelSet model (\c -> { c | r = channel raw })

                        Just "G" ->
                            channelSet model (\c -> { c | g = channel raw })

                        Just "B" ->
                            channelSet model (\c -> { c | b = channel raw })

                        Just "L" ->
                            lightnessSet model raw

                        _ ->
                            Nothing
    in
    case parsed of
        Just (Just value) ->
            { model | cpDraft = Just value, cpUnitText = Nothing }

        _ ->
            { model | cpUnitText = Just raw }


unitLabels : Model -> List String
unitLabels model =
    let
        base =
            case model.cpMode of
                ColorPicker.Rgb ->
                    [ "R", "G", "B" ]

                ColorPicker.Hsl ->
                    [ "H", "S", "L" ]

                ColorPicker.Hsv ->
                    [ "H", "S", "V" ]

                ColorPicker.Hex ->
                    []
    in
    base ++ [ "A" ]


channel : String -> Float
channel raw =
    ColorPicker.normalizeRgbUnit raw
        |> Maybe.map toFloat
        |> Maybe.withDefault 0


channelSet : Model -> (Color.RGBA -> Color.RGBA) -> Maybe (Maybe String)
channelSet model set =
    Maybe.map
        (\c ->
            ColorPicker.convertColor
                (Color.toRgbaString (set c))
                model.cpMode
                Nothing
        )
        (Color.rgbaOf model.cpDraft)


lightnessSet : Model -> String -> Maybe (Maybe String)
lightnessSet model raw =
    ColorPicker.normalizeSlvUnit raw
        |> Maybe.andThen
            (\l ->
                Maybe.map
                    (\c ->
                        ColorPicker.convertColor
                            (Color.toHslaString { c | l = toFloat l })
                            model.cpMode
                            Nothing
                    )
                    (Color.hslaOf model.cpDraft)
            )



-- VIEW (same visual grammar as the static sections)


view : Theme -> Model -> Element Msg
view theme model =
    Element.column [ Element.spacing 20, Element.width Element.fill ]
        [ demoRow "Select · single"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 230) ]
                [ Select.view theme
                    { selD
                        | value = model.selSingle
                        , placeholder = "Pick a song"
                        , clearable = True
                        , active = model.selOpen
                        , onClear = Just SelectSingleCleared
                        , attributes =
                            [ Element.htmlAttribute (HA.id "live-select-single")
                            , Element.Events.onClick ToggleSelectSingle
                            ]
                    }
                    songOptions
                , chip ("value: " ++ describe (valueKey model.selSingle |> Maybe.andThen (\k -> selectLabel k songOptions)))
                , if model.selOpen then
                    Select.menu theme
                        { selMenuD
                            | value = model.selSingle
                            , onToggle = Just SelectSinglePicked
                            , attributes =
                                [ Element.htmlAttribute (HA.id "live-select-single-menu")
                                , Element.width (Element.px 230)
                                ]
                        }
                        songOptions

                  else
                    Element.none
                ]
            ]
        , demoRow "Select · multiple (tags)"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 280) ]
                [ Select.view theme
                    { selD
                        | multiple = True
                        , value = model.selMulti
                        , placeholder = "Pick songs"
                        , clearable = True
                        , active = model.selMultiOpen
                        , onClear = Just SelectMultiCleared
                        , onDeleteTag = Just SelectMultiTagDeleted
                        , attributes =
                            [ Element.htmlAttribute (HA.id "live-select-multiple")
                            , Element.Events.onClick ToggleSelectMulti
                            ]
                    }
                    songOptions
                , chip ("tags: " ++ describeRange (valueKeys model.selMulti))
                , if model.selMultiOpen then
                    Select.menu theme
                        { selMenuD
                            | multiple = True
                            , value = model.selMulti
                            , onToggle = Just SelectMultiPicked
                            , attributes =
                                [ Element.htmlAttribute (HA.id "live-select-multiple-menu")
                                , Element.width (Element.px 280)
                                ]
                        }
                        songOptions

                  else
                    Element.none
                ]
            ]
        , demoRow "Popselect · value"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 200) ]
                [ Button.view theme
                    { btnD
                        | onPress = Just TogglePopselect
                        , attributes = [ Element.htmlAttribute (HA.id "live-popselect-trigger") ]
                    }
                    [ Element.text ("Align: " ++ describe (valueKey model.popValue |> Maybe.andThen (\k -> selectLabel k popOptions))) ]
                , if model.popOpen then
                    Popselect.view theme
                        { popD
                            | width = Just "170px"
                            , value = model.popValue
                            , onUpdateValue = Just PopselectPicked
                            , attributes = [ Element.htmlAttribute (HA.id "live-popselect") ]
                        }
                        popOptions

                  else
                    Element.none
                ]
            ]
        , demoRow "Cascader · drill (province → city)"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 380) ]
                [ Cascader.view theme
                    { cascD
                        | value = model.cascValue
                        , placeholder = "Pick a region"
                        , clearable = True
                        , hover = model.cascOpen
                        , active = model.cascOpen
                        , onClear = Just CascaderCleared
                        , attributes =
                            [ Element.htmlAttribute (HA.id "live-cascader")
                            , Element.Events.onClick ToggleCascader
                            ]
                    }
                    cascOptions
                , chip ("path: " ++ cascValueText model.cascValue)
                , if model.cascOpen then
                    Cascader.menu theme
                        { cascMenuD
                            | hoverKey = model.cascHover
                            , value = model.cascValue
                            , expandTrigger = Cascader.Hover
                            , onHover = Just CascaderHovered
                            , onToggle = Just CascaderToggled
                            , attributes =
                                [ Element.htmlAttribute (HA.id "live-cascader-menu")
                                , Element.width (Element.px 380)
                                ]
                        }
                        cascOptions

                  else
                    Element.none
                ]
            ]
        , demoRow "TreeSelect · pick node"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 280) ]
                [ Element.el
                    [ Element.width Element.fill, Element.Events.onClick ToggleTreeSelect ]
                    (TreeSelect.view theme (tsOptions model))
                , chip ("selected: " ++ describe (valueKey model.tsValue |> Maybe.andThen treeLabel))
                , if model.tsOpen then
                    Element.el
                        [ Element.width (Element.px 280), Element.htmlAttribute (HA.id "live-treeselect-menu") ]
                        (TreeSelect.menu theme (tsOptions model))

                  else
                    Element.none
                ]
            ]
        , demoRow "AutoComplete · filter"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 260) ]
                [ AutoComplete.view theme
                    { acD
                        | value = model.acText
                        , onInput = Just AcTyped
                        , clearable = True
                        , placeholder = "Type a song…"
                        , attributes = [ Element.htmlAttribute (HA.id "live-autocomplete") ]
                    }
                , chip
                    ("value: \""
                        ++ model.acText
                        ++ "\" · "
                        ++ String.fromInt (List.length (acMatches model.acText))
                        ++ " match(es)"
                    )
                , if acMenuOpen model then
                    AutoComplete.menu theme
                        { acMenuD
                            | onToggle = Just AcPicked
                            , empty = Just (Element.text "No match")
                            , attributes =
                                [ Element.htmlAttribute (HA.id "live-autocomplete-menu")
                                , Element.width (Element.px 260)
                                ]
                        }
                        (acMatches model.acText)

                  else
                    Element.none
                ]
            ]
        , demoRow "Mention · @ trigger"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 320) ]
                [ Mention.view theme
                    { mnD
                        | value = model.mnText
                        , onInput = Just MnTyped
                        , placeholder = "Type @ to mention"
                        , attributes = [ Element.htmlAttribute (HA.id "live-mention") ]
                    }
                , chip (maybeChip "run: @" (mnRun model.mnText))
                , if mnRun model.mnText /= Nothing then
                    Mention.menu theme
                        { mnMenuD
                            | onToggle = Just MnPicked
                            , empty = Just (Element.text "No match")
                            , attributes =
                                [ Element.htmlAttribute (HA.id "live-mention-menu")
                                , Element.width (Element.px 260)
                                ]
                        }
                        (mnMatches model.mnText)

                  else
                    Element.none
                ]
            ]
        , demoRow "DatePicker · single panel"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 260) ]
                [ Element.el
                    [ Element.width Element.fill, Element.htmlAttribute (HA.id "live-datepicker") ]
                    (DatePicker.view theme (dpSingleOpts model))
                , chip ("committed: " ++ dpValueText model.dpValue)
                , if model.dpShow then
                    Element.el
                        [ Element.width (Element.px 310), Element.htmlAttribute (HA.id "live-datepicker-panel") ]
                        (DatePicker.panel theme (dpSingleOpts model))

                  else
                    Element.none
                ]
            ]
        , demoRow "DatePicker · daterange"
            [ Element.column [ Element.spacing 8, Element.width Element.fill ]
                [ Element.el
                    [ Element.width Element.fill, Element.htmlAttribute (HA.id "live-daterange") ]
                    (DatePicker.view theme (dpRangeOpts model))
                , chip (dpRangeText_ model)
                , if model.dpRangeShow then
                    Element.el
                        [ Element.width Element.fill, Element.htmlAttribute (HA.id "live-daterange-panel") ]
                        (DatePicker.panel theme (dpRangeOpts model))

                  else
                    Element.none
                ]
            ]
        , demoRow "TimePicker · columns"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 220) ]
                [ Element.el
                    [ Element.width Element.fill, Element.htmlAttribute (HA.id "live-timepicker") ]
                    (TimePicker.view theme (tpOpts model))
                , chip
                    ("value: "
                        ++ (case model.tpValue of
                                Just ms ->
                                    TimePicker.formatValue "HH:mm:ss" Time.utc ms

                                Nothing ->
                                    "unset"
                           )
                    )
                , Button.view theme { btnD | onPress = Just TpClosed, size = T.Tiny } [ Element.text "Close panel" ]
                , if model.tpShow then
                    Element.el
                        [ Element.width (Element.px 220), Element.htmlAttribute (HA.id "live-timepicker-panel") ]
                        (TimePicker.panel theme (tpOpts model))

                  else
                    Element.none
                ]
            ]
        , demoRow "ColorPicker · full loop"
            [ Element.column [ Element.spacing 8, Element.width (Element.px 260) ]
                [ Element.el
                    [ Element.width Element.fill, Element.htmlAttribute (HA.id "live-colorpicker") ]
                    (ColorPicker.view theme (cpTriggerOpts model))
                , Element.row [ Element.spacing 10 ]
                    [ colorSwatch model.cpValue
                    , chip ("committed: " ++ cpHexText model.cpValue)
                    , chip ("draft: " ++ cpHexText model.cpDraft)
                    ]
                , if model.cpShow then
                    Element.el
                        [ Element.width (Element.px 260), Element.htmlAttribute (HA.id "live-colorpicker-panel") ]
                        (ColorPicker.panel theme (cpPanelOpts model))

                  else
                    Element.none
                ]
            ]
        ]



-- OPTION RECORDS (record-update needs a plain variable first)


selD : Select.Options Msg
selD =
    Select.defaults


selMenuD : Select.MenuOptions Msg
selMenuD =
    Select.menuDefaults


popD : Popselect.Options Msg
popD =
    Popselect.defaults


cascD : Cascader.Options Msg
cascD =
    Cascader.defaults


cascMenuD : Cascader.MenuOptions Msg
cascMenuD =
    Cascader.menuDefaults


acD : AutoComplete.Options Msg
acD =
    AutoComplete.defaults


acMenuD : AutoComplete.MenuOptions Msg
acMenuD =
    AutoComplete.menuDefaults


mnD : Mention.Options Msg
mnD =
    Mention.defaults


mnMenuD : Mention.MenuOptions Msg
mnMenuD =
    Mention.menuDefaults


dpD : DatePicker.Options Msg
dpD =
    DatePicker.defaultOptions


tpD : TimePicker.Options Msg
tpD =
    TimePicker.defaultOptions


cpD : ColorPicker.Options Msg
cpD =
    ColorPicker.defaultOptions


btnD : Button.Options Msg
btnD =
    Button.defaults


tsOptions : Model -> TreeSelect.Options Msg
tsOptions model =
    { tsD
        | options = treeData
        , value = model.tsValue
        , expandedKeys = model.tsExpanded
        , pendingKey = model.tsPending
        , placeholder = "Pick a node"
        , clearable = True
        , hover = model.tsOpen
        , active = model.tsOpen
        , onClear = Just TreeCleared
        , onDeleteTag = Just TreeTagDeleted
        , onNodeClick = Just TreeNodeClicked
    }


tsD : TreeSelect.Options Msg
tsD =
    TreeSelect.defaults


dpSingleOpts : Model -> DatePicker.Options Msg
dpSingleOpts model =
    { dpD
        | value = model.dpValue
        , show = model.dpShow
        , now = dpNow
        , clearable = True
        , placeholder = Just "Pick a date"
        , inputReadonly = True
        , calendarValue = model.dpCal
        , monthPanelShow = model.dpMonthPanel
        , actions = Just (DatePicker.defaultActions DatePicker.Date True)
        , onFocus = Just DpFocused
        , onClear = Just DpCleared
        , onUpdateValue = Just DpValueSet
        , onUpdateCalendarValue = Just DpCalendar
        , onUpdateMonthPanelShow = Just DpMonthPanelToggled
    }


dpRangeOpts : Model -> DatePicker.Options Msg
dpRangeOpts model =
    { dpD
        | type_ = DatePicker.Daterange
        , value = model.dpRange
        , rangeText = model.dpRangeText
        , show = model.dpRangeShow
        , now = dpNow
        , clearable = True
        , selecting = model.dpSelecting
        , startCalendarValue = model.dpStartCal
        , endCalendarValue = model.dpEndCal
        , monthPanelShow = model.dpRangeMonthPanel
        , actions = Just (DatePicker.defaultActions DatePicker.Daterange True)
        , onFocus = Just DpRangeFocused
        , onClear = Just DpRangeCleared
        , onConfirm = Just DpRangeConfirmed
        , onDateClick = Just DpRangeDateClicked
        , onDateEnter = Just DpRangeHovered
        , onPairInput = Just (\( a, b ) source -> DpRangePairTyped a b source)
        , onUpdateCalendarValue = Just DpRangeCalendar
        , onUpdateMonthPanelShow = Just DpRangeMonthPanelToggled
    }


tpOpts : Model -> TimePicker.Options Msg
tpOpts model =
    { tpD
        | value = model.tpValue
        , show = model.tpShow
        , now = dpNow
        , clearable = True
        , placeholder = "Pick time"
        , inputReadonly = True
        , actions = [ TimePicker.Clear, TimePicker.Now, TimePicker.Confirm ]
        , colContainerIds =
            Just
                { hour = "live-tp-col-hour"
                , minute = "live-tp-col-minute"
                , second = "live-tp-col-second"
                , period = "live-tp-col-period"
                }
        , onFocus = Just TpFocused
        , onClear = Just TpCleared
        , onConfirm = Just TpConfirmed
        , onUpdateValue = Just TpValueSet
    }


cpTriggerOpts : Model -> ColorPicker.Options Msg
cpTriggerOpts model =
    { cpD
        | value = model.cpValue
        , displayedMode = model.cpMode
        , swatches = cpSwatches
        , onUpdateShow = Just (\_ -> CpOpened)
    }


cpPanelOpts : Model -> ColorPicker.Options Msg
cpPanelOpts model =
    { cpD
        | value = model.cpDraft
        , displayedMode = model.cpMode
        , swatches = cpSwatches
        , showPreview = True
        , actions = Just [ ColorPicker.ConfirmAction, ColorPicker.ClearAction ]
        , internalActions = Just [ ColorPicker.UndoAction, ColorPicker.RedoAction ]
        , undoable = not (List.isEmpty model.cpUndo)
        , redoable = not (List.isEmpty model.cpRedo)
        , attributes = [ HA.id "live-cp-panel" ]
        , pointerAreaIds =
            Just
                { palette = "live-cp-palette"
                , hue = "live-cp-hue"
                , alpha = "live-cp-alpha"
                }
        , onMousedown = Just CpDragStarted
        , onUnitInput = Just (\i raw -> CpUnitTyped i raw)
        , onUpdateValue = Just CpValueUpdated
        , onUpdateMode = Just CpModeChanged
        , onConfirm = Just CpConfirmed
        , onClear = Just CpCleared
        , onUndo = Just CpUndone
        , onRedo = Just CpRedone
    }



-- FIXTURES


songOptions : List (SelectMenu.Option Msg)
songOptions =
    List.map
        (\( key, label, disabled ) ->
            SelectMenu.Option { value = key, label = label, disabled = disabled, attributes = [] }
        )
        [ ( "drive", "Drive My Car", False )
        , ( "nowhere-man", "Nowhere Man", True )
        , ( "in-my-life", "In My Life", False )
        , ( "the-word", "The Word", False )
        , ( "day-tripper", "Day Tripper", False )
        ]


popOptions : List (SelectMenu.Option Msg)
popOptions =
    List.map
        (\( key, label ) ->
            SelectMenu.Option { value = key, label = label, disabled = False, attributes = [] }
        )
        [ ( "left", "Left" ), ( "center", "Center" ), ( "right", "Right" ) ]


mentionOptions : List (SelectMenu.Option Msg)
mentionOptions =
    List.map
        (\name -> SelectMenu.Option { value = String.toLower name, label = name, disabled = False, attributes = [] })
        [ "710mechgy", "Zhe", "Alice", "Bob", "Carol" ]


cpSwatches : List String
cpSwatches =
    [ "#18a058", "#2080f0", "#f0a020", "#d03050", "#ffffff" ]


cpSeed : String
cpSeed =
    "#18a058"


cascOptions : List Cascader.Option
cascOptions =
    let
        node value label children =
            Cascader.Option
                { value = value, label = label, disabled = False, children = children }

        leafs pairs =
            Just (List.map (\( v, l ) -> node v l Nothing) pairs)
    in
    [ node "sichuan" "Sichuan" (leafs [ ( "chengdu", "Chengdu" ), ( "leshan", "Leshan" ) ])
    , node "guangdong" "Guangdong" (leafs [ ( "guangzhou", "Guangzhou" ), ( "shenzhen", "Shenzhen" ) ])
    , node "zhejiang" "Zhejiang" (leafs [ ( "hangzhou", "Hangzhou" ), ( "ningbo", "Ningbo" ) ])
    ]


treeData : List (Tree.TreeOption Msg)
treeData =
    let
        branch key label kids =
            Tree.TreeOption
                { key = key
                , label = label
                , disabled = False
                , checkboxDisabled = False
                , isLeaf = False
                , children = Just kids
                , prefix = []
                , suffix = []
                }

        leaf key label =
            Tree.TreeOption
                { key = key
                , label = label
                , disabled = False
                , checkboxDisabled = False
                , isLeaf = True
                , children = Nothing
                , prefix = []
                , suffix = []
                }
    in
    [ branch "nav"
        "Navigation"
        [ leaf "nav-menu" "Menu"
        , leaf "nav-tabs" "Tabs"
        , leaf "nav-breadcrumb" "Breadcrumb"
        ]
    , branch "picker" "Pickers" [ leaf "picker-select" "Select", leaf "picker-cascader" "Cascader" ]
    , leaf "theme" "Theme"
    ]


dpNow : Time.Posix
dpNow =
    Time.millisToPosix dpNowMs


dpNowMs : Int
dpNowMs =
    1715731200000


may10 : Int
may10 =
    1715299200000


may20 : Int
may20 =
    1716163200000


tenToFiftyFour : Int
tenToFiftyFour =
    (10 * 60 + 54) * 60 * 1000



-- DERIVED TEXT (inspectability chips)


valueKey : SelectMenu.Value -> Maybe String
valueKey value =
    case value of
        SelectMenu.Single key ->
            key

        SelectMenu.Multiple (key :: _) ->
            Just key

        SelectMenu.Multiple [] ->
            Nothing


valueKeys : SelectMenu.Value -> List String
valueKeys value =
    case value of
        SelectMenu.Multiple keys ->
            keys

        SelectMenu.Single _ ->
            []


describe : Maybe String -> String
describe maybe =
    Maybe.withDefault "—" maybe


describeRange : List String -> String
describeRange keys =
    case keys of
        [] ->
            "—"

        _ ->
            String.join ", " keys


selectLabel : String -> List (SelectMenu.Option msg) -> Maybe String
selectLabel key options =
    List.filterMap
        (\opt ->
            case opt of
                SelectMenu.Option leaf_ ->
                    if leaf_.value == key then
                        Just leaf_.label

                    else
                        Nothing

                SelectMenu.Group group ->
                    selectLabel key group.children

                SelectMenu.Custom _ ->
                    Nothing
        )
        options
        |> List.head


cascValueText : SelectMenu.Value -> String
cascValueText value =
    case value of
        SelectMenu.Single (Just key) ->
            String.join " / " (List.map cascLabelOf (cascPathOf key cascOptions))

        _ ->
            "unset"


cascLabelOf : Cascader.Option -> String
cascLabelOf opt =
    cascFields opt |> .label


cascFields : Cascader.Option -> { value : String, label : String, children : Maybe (List Cascader.Option) }
cascFields (Cascader.Option o) =
    { value = o.value, label = o.label, children = o.children }


cascPathOf : String -> List Cascader.Option -> List Cascader.Option
cascPathOf key options =
    case List.head (List.filter (\opt -> (cascFields opt).value == key) options) of
        Just found ->
            [ found ]

        Nothing ->
            List.foldl
                (\opt acc ->
                    case acc of
                        x :: _ ->
                            acc

                        [] ->
                            case cascPathOf key (Maybe.withDefault [] (cascFields opt).children) of
                                [] ->
                                    []

                                sub ->
                                    opt :: sub
                )
                []
                options


cascIsLeaf : String -> Bool
cascIsLeaf key =
    case List.head (List.filter (\opt -> (cascFields opt).value == key) cascOptions) of
        Just found ->
            cascFields found |> .children |> (==) Nothing

        Nothing ->
            True


treeFields : Tree.TreeOption msg -> { key : String, label : String, isLeaf : Bool, children : Maybe (List (Tree.TreeOption msg)) }
treeFields (Tree.TreeOption o) =
    { key = o.key, label = o.label, isLeaf = o.isLeaf, children = o.children }


treeLabel : String -> Maybe String
treeLabel key =
    treeFind key treeData |> Maybe.map (\node -> (treeFields node).label)


treeFind : String -> List (Tree.TreeOption msg) -> Maybe (Tree.TreeOption msg)
treeFind key nodes =
    case List.head (List.filter (\node -> (treeFields node).key == key) nodes) of
        Just found ->
            Just found

        Nothing ->
            List.foldl
                (\node acc ->
                    case acc of
                        Just _ ->
                            acc

                        Nothing ->
                            treeFind key (Maybe.withDefault [] (treeFields node).children)
                )
                Nothing
                nodes


treeIsBranch : String -> Bool
treeIsBranch key =
    case treeFind key treeData of
        Just node ->
            not (treeFields node).isLeaf

        Nothing ->
            False


acMenuOpen : Model -> Bool
acMenuOpen model =
    model.acFocused
        && model.acText
        /= ""
        && not
            (List.isEmpty (acMatches model.acText))


acMatches : String -> List (SelectMenu.Option Msg)
acMatches pattern =
    let
        needle =
            String.toLower pattern
    in
    List.filter
        (\opt ->
            case opt of
                SelectMenu.Option leaf_ ->
                    String.contains needle (String.toLower leaf_.label)

                _ ->
                    False
        )
        songOptions


{-| The @-run the caret sits in: everything after the LAST "@" that still has
no separator space (the caller-owned show gate upstream anchors at the caret;
the port leaves the formula to the caller).
-}
mnRun : String -> Maybe String
mnRun text =
    case List.maximum (String.indexes "@" text) of
        Nothing ->
            Nothing

        Just at ->
            let
                run =
                    String.slice (at + 1) (String.length text) text
            in
            if run == "" || String.contains " " run then
                Nothing

            else
                Just run


mnMatches : String -> List (SelectMenu.Option Msg)
mnMatches text =
    case mnRun text of
        Nothing ->
            []

        Just run ->
            let
                needle =
                    String.toLower run
            in
            List.filter
                (\opt ->
                    case opt of
                        SelectMenu.Option leaf_ ->
                            String.startsWith needle (String.toLower leaf_.label)

                        _ ->
                            False
                )
                mentionOptions


{-| The select splice: replace the whole @-run (the "@" included) with the
picked value plus the separator space — upstream's handleSelect.
-}
spliceMention : String -> String -> String
spliceMention text value =
    case List.maximum (String.indexes "@" text) of
        Nothing ->
            text

        Just at ->
            String.slice 0 at text ++ "@" ++ value ++ " "


maybeChip : String -> Maybe String -> String
maybeChip prefix maybe =
    case maybe of
        Just value ->
            prefix ++ value

        Nothing ->
            "no @-run"


dpValueText : DatePicker.Value -> String
dpValueText value =
    case value of
        DatePicker.Single (Just ts) ->
            String.fromInt ts

        _ ->
            "unset"


dpRangeText_ : Model -> String
dpRangeText_ model =
    let
        range =
            case model.dpRange of
                DatePicker.Range (Just ( a, b )) ->
                    String.fromInt a ++ " → " ++ String.fromInt b

                DatePicker.Range Nothing ->
                    "unset"

                DatePicker.Single _ ->
                    ""
    in
    range
        ++ (if model.dpSelecting then
                " · selecting"

            else
                ""
           )


dpSingleCloses : DatePicker.Value -> Bool
dpSingleCloses value =
    case value of
        DatePicker.Single (Just ts) ->
            .close
                (DatePicker.singleDateClick
                    { type_ = DatePicker.Date
                    , value = DatePicker.Single Nothing
                    , target = dpTarget ts
                    , isDisabled = False
                    , defaultTime = Nothing
                    , now = dpNowMs
                    , zone = Time.utc
                    }
                )

        _ ->
            False


dpTarget : Int -> DatePicker.ClickTarget
dpTarget ts =
    let
        posix =
            Time.millisToPosix ts

        monthNumber =
            case Time.toMonth Time.utc posix of
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
    in
    { ts = ts
    , year = Time.toYear Time.utc posix
    , month = monthNumber
    , day = Time.toDay Time.utc posix
    , quarter = (monthNumber - 1) // 3 + 1
    }


cpHexText : Maybe String -> String
cpHexText maybeColor =
    case maybeColor of
        Nothing ->
            "unset"

        Just color ->
            Maybe.withDefault color (ColorPicker.convertColor color ColorPicker.Hex Nothing)


colorSwatch : Maybe String -> Element Msg
colorSwatch maybeColor =
    Element.el
        [ Element.width (Element.px 20)
        , Element.height (Element.px 20)
        , Border.rounded 4
        , Border.width 1
        , Element.htmlAttribute
            (HA.style "background-color" (Maybe.withDefault "transparent" maybeColor))
        ]
        Element.none
