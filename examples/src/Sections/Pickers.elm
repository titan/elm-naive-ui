module Sections.Pickers exposing
    ( Model
    , Msg
    , autoCompleteSection
    , cascaderSection
    , colorPickerSection
    , datePickerSection
    , init
    , mentionSection
    , popselectSection
    , sections
    , selectSection
    , subscriptions
    , timePickerSection
    , treeSelectSection
    , update
    )

{-| Pickers family sections: Select, Popselect, Cascader, TreeSelect,
AutoComplete, Mention, DatePicker, TimePicker, ColorPicker.

The static rows moved verbatim from Main.elm — that surface feeds the
check-dom gate, so every root keeps rendering exactly as before. The live
demo rows (moved verbatim from Live/Pickers.elm — same demoRow labels,
same `#live-*` ids, same chip captions) run a real update loop owned by
this module: caller-owned open state and values per the port's contract,
each component renders what the model says and every Options msg channel
feeds one Msg constructor.

Every picker's open state (menu / panel show) and value are caller-owned per
the port's contract. Where the port ships the interaction algebra as pure
helpers, update uses those instead of re-deriving semantics
(`Select.toggleValue`, `Popselect.toggleValue`, `Cascader.toggleValue`,
`TreeSelect.handleNodeClick` / `deleteOption`, `Tree.toggleExpand`,
`DatePicker.singleDateClick` / `dualDateClick` / `dualHover` /
`sanitizeValue`, `defaultActions`, `TimePicker.formatValue`,
`ColorPicker.convertColor` / `getModeFromValue`). Menus and panels are
separate caller-mounted bodies (upstream mounts each in its own follower):
the trigger always renders, the body only while open.

Simulated runtime (the port's documented caller-owned concerns):

  - **TimePicker** — upstream `scrollTimer` scrolls each visible column so
    the `[data-active]` item sits at the top; `TpFocused` issues
    `Browser.Dom.setViewportOf` against the `colContainerIds` seam (offsets
    computed as index × the theme's 34px item height, no DOM read). The
    scroll is why this family's update returns a `Cmd Msg` — the only
    family that does.
  - **ColorPicker** — upstream binds document `mousemove`/`mouseup` while a
    drag is live; the `Browser.Events` subscription pair drives the move/
    end through the port's `svFromPoint` / `hueFromPoint` /
    `alphaFromPoint` geometry, the pointer surface rect read is a
    `Browser.Dom.getElement` task, and per-unit typing parses through the
    port's `normalize*Unit` helpers (complete parse commits the draft,
    incomplete keeps the raw text in `cpUnitText`).

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
import NUI.BaseSelection as BaseSelection
import NUI.Button as Button
import NUI.Cascader as Cascader
import NUI.ColorPicker as ColorPicker
import NUI.DatePicker as DatePicker
import NUI.Empty as Empty
import NUI.Input as Input
import NUI.Internal.Color as Color
import NUI.Mention as Mention
import NUI.Popover as Popover
import NUI.Popselect as Popselect
import NUI.Select as Select
import NUI.SelectMenu as SelectMenu
import NUI.Tag as Tag
import NUI.TimePicker as TimePicker
import NUI.Tree as Tree
import NUI.TreeSelect as TreeSelect
import NUI.Types as T
import Showcase exposing (chip, demoRow, section, theme)
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



-- VIEW (live demo rows — verbatim from Live/Pickers.elm; each lands in a
-- demoRow with its original label, appended to its family section)


{-| Live: `#live-select-single` (+ `#live-select-single-menu` while open).
-}
selectSingleLiveRow : Model -> Element Msg
selectSingleLiveRow model =
    demoRow "Select · single"
        [ Element.column [ Element.spacing 8, Element.width (Element.px 230) ]
            [ Select.view theme
                { selectD
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


{-| Live: `#live-select-multiple` (+ `#live-select-multiple-menu`).
-}
selectMultipleLiveRow : Model -> Element Msg
selectMultipleLiveRow model =
    demoRow "Select · multiple (tags)"
        [ Element.column [ Element.spacing 8, Element.width (Element.px 280) ]
            [ Select.view theme
                { selectD
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


{-| Live: `#live-popselect-trigger` / `#live-popselect` (the menu body while open).
-}
popselectLiveRow : Model -> Element Msg
popselectLiveRow model =
    demoRow "Popselect · value"
        [ Element.column [ Element.spacing 8, Element.width (Element.px 200) ]
            [ Button.view theme
                { btnD
                    | onPress = Just TogglePopselect
                    , attributes = [ Element.htmlAttribute (HA.id "live-popselect-trigger") ]
                }
                [ Element.text ("Align: " ++ describe (valueKey model.popValue |> Maybe.andThen (\k -> selectLabel k popOptions))) ]
            , if model.popOpen then
                Popselect.view theme
                    { popselectD
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


{-| Live: `#live-cascader` (+ `#live-cascader-menu` while open).
-}
cascaderLiveRow : Model -> Element Msg
cascaderLiveRow model =
    demoRow "Cascader · drill (province → city)"
        [ Element.column [ Element.spacing 8, Element.width (Element.px 380) ]
            [ Cascader.view theme
                { cascaderD
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


{-| Live: `#live-treeselect-menu` (the menu body while open).
-}
treeSelectLiveRow : Model -> Element Msg
treeSelectLiveRow model =
    demoRow "TreeSelect · pick node"
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


{-| Live: `#live-autocomplete` (+ `#live-autocomplete-menu` while the show gate passes).
-}
autoCompleteLiveRow : Model -> Element Msg
autoCompleteLiveRow model =
    demoRow "AutoComplete · filter"
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


{-| Live: `#live-mention` (+ `#live-mention-menu` while an @-run is active).
-}
mentionLiveRow : Model -> Element Msg
mentionLiveRow model =
    demoRow "Mention · @ trigger"
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


{-| Live: `#live-datepicker` / `#live-datepicker-panel` (the `committed:` chip is the s2LeafText caption).
-}
dpSingleLiveRow : Model -> Element Msg
dpSingleLiveRow model =
    demoRow "DatePicker · single panel"
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


{-| Live: `#live-daterange` / `#live-daterange-panel` — the chip caption is a leaf div matching `^(unset|\d{13} → \d{13})( · selecting)?$` and must stay the FIRST document-order match (LIVE/PICK gate).
-}
dpRangeLiveRow : Model -> Element Msg
dpRangeLiveRow model =
    demoRow "DatePicker · daterange"
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


{-| Live: `#live-timepicker` / `#live-timepicker-panel` (TpFocused issues the column scroll commands).
-}
tpLiveRow : Model -> Element Msg
tpLiveRow model =
    demoRow "TimePicker · columns"
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


{-| Live: `#live-colorpicker` / `#live-colorpicker-panel` (drag via the Browser.Events pair, rect read via Browser.Dom).
-}
cpLiveRow : Model -> Element Msg
cpLiveRow model =
    demoRow "ColorPicker · full loop"
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



-- OPTION RECORDS (record-update needs a plain variable first)


dpD : DatePicker.Options msg
dpD =
    DatePicker.defaultOptions


tpD : TimePicker.Options msg
tpD =
    TimePicker.defaultOptions


cpD : ColorPicker.Options msg
cpD =
    ColorPicker.defaultOptions


btnD : Button.Options msg
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


tsD : TreeSelect.Options msg
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



-- STATIC FIXTURE OPTION LISTS (unchanged)


{-| The select rows — leaves (one disabled) and a group (the flatten renders
the header followed by its children as siblings).
-}
selectOptions : List (SelectMenu.Option msg)
selectOptions =
    [ SelectMenu.Option
        { value = "drive"
        , label = "Drive My Car"
        , disabled = False
        , attributes = []
        }
    , SelectMenu.Option
        { value = "nowhere-man"
        , label = "Nowhere Man"
        , disabled = True
        , attributes = []
        }
    , SelectMenu.Group
        { label = "Rubber Soul"
        , children =
            [ SelectMenu.Option
                { value = "in-my-life"
                , label = "In My Life"
                , disabled = False
                , attributes = []
                }
            , SelectMenu.Option
                { value = "the-word"
                , label = "The Word"
                , disabled = False
                , attributes = []
                }
            ]
        , attributes = []
        }
    ]


{-| The lettered rows the multiple demos select from (the `ghost` value in
the maxTagCount demo is absent here — the `fallbackOption` tag).
-}
letterOptions : List (SelectMenu.Option msg)
letterOptions =
    List.map
        (\letter ->
            SelectMenu.Option
                { value = String.toLower letter
                , label = letter
                , disabled = False
                , attributes = []
                }
        )
        [ "A", "B", "C", "D", "E" ]


{-| The shared popselect rows — leaves and a group (upstream's flatten renders
the group header followed by its children as siblings).
-}
popselectOptions : List (SelectMenu.Option msg)
popselectOptions =
    [ SelectMenu.Option
        { value = "drive"
        , label = "Drive My Car"
        , disabled = False
        , attributes = []
        }
    , SelectMenu.Option
        { value = "nowhere-man"
        , label = "Nowhere Man"
        , disabled = True
        , attributes = []
        }
    , SelectMenu.Group
        { label = "Rubber Soul"
        , children =
            [ SelectMenu.Option
                { value = "in-my-life"
                , label = "In My Life"
                , disabled = False
                , attributes = []
                }
            , SelectMenu.Option
                { value = "the-word"
                , label = "The Word"
                , disabled = False
                , attributes = []
                }
            ]
        , attributes = []
        }
    ]


{-| The cascader fixture — three two-level albums (branches) with song
leaves; `revolver`'s column is what the hover key opens.
-}
cascaderOptions : List Cascader.Option
cascaderOptions =
    [ Cascader.Option
        { value = "rubber"
        , label = "Rubber Soul"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "drive", label = "Drive My Car", disabled = False, children = Nothing }
                , Cascader.Option { value = "nowhere", label = "Nowhere Man", disabled = False, children = Nothing }
                ]
        }
    , Cascader.Option
        { value = "revolver"
        , label = "Revolver"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "eleanor", label = "Eleanor Rigby", disabled = False, children = Nothing }
                , Cascader.Option { value = "yellow", label = "Yellow Submarine", disabled = False, children = Nothing }
                ]
        }
    , Cascader.Option
        { value = "abbey"
        , label = "Abbey Road"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "come", label = "Come Together", disabled = False, children = Nothing }
                , Cascader.Option { value = "here", label = "Here Comes the Sun", disabled = False, children = Nothing }
                ]
        }
    ]


{-| The user rows the mention demos pick from (the default @-trigger
story — the module does no scan, the caller gates the list).
-}
mentionOptions : List (SelectMenu.Option msg)
mentionOptions =
    List.map
        (\name ->
            SelectMenu.Option
                { value = String.toLower name
                , label = name
                , disabled = False
                , attributes = []
                }
        )
        [ "710mechgy", "Zhe", "Alice", "Bob", "Carol" ]


{-| The tag rows the custom-prefix (#) cell picks from — the second of
the two caller-gated option lists.
-}
mentionTagOptions : List (SelectMenu.Option msg)
mentionTagOptions =
    List.map
        (\tag ->
            SelectMenu.Option
                { value = tag
                , label = "#" ++ tag
                , disabled = False
                , attributes = []
                }
        )
        [ "elm", "naive-ui", "ui" ]



-- SECTIONS (static rows verbatim; live variants append the live demo rows)


{-| The Select section description (shared by the static and live variants).
-}
selectDesc : String
selectDesc =
    "Naive UI's select — a bare `.n-select` wrapper around the `NUI.BaseSelection` trigger (every var lives there); the menu is a separate caller-mounted body (upstream opens it in its own follower), `Select.menu` here. `view` derives the display from `value` + options: the single label (unknown values show themselves while `fallbackOption` is on), the multiple tags (same fallback; unknowns drop when off) with the numeric `maxTagCount` slice's `+N` counter, and the clear icon — `clearable && (hover || active) && selected`; `pattern` flows to the filter input, `filterOptions` being the pure default filter. The caller owns the show state, positioning and keyboard."


selectRows : List (Element msg)
selectRows =
    [ demoRow "Single (leaves + group)"
        [ Select.view theme
            { selectD | attributes = [ Element.width (Element.px 200) ] }
            selectOptions
        ]
    , demoRow "Selected + clearable (hover)"
        [ Select.view theme
            { selectD
                | value = SelectMenu.Single (Just "drive")
                , clearable = True
                , hover = True
                , attributes = [ Element.width (Element.px 200) ]
            }
            selectOptions
        ]
    , demoRow "Filterable (active, empty pattern)"
        [ Select.view theme
            { selectD
                | filterable = True
                , active = True
                , pattern = ""
                , attributes = [ Element.width (Element.px 200) ]
            }
            selectOptions
        ]
    , demoRow "Multiple (maxTagCount 3 + fallback)"
        [ Select.view theme
            { selectD
                | multiple = True
                , maxTagCount = Just 3
                , value = SelectMenu.Multiple [ "a", "b", "c", "d", "ghost" ]
                , attributes = [ Element.width (Element.px 260) ]
            }
            letterOptions
        ]
    , demoRow "Multiple filterable (pattern)"
        [ Select.view theme
            { selectD
                | multiple = True
                , filterable = True
                , active = True
                , pattern = "dri"
                , value = SelectMenu.Multiple [ "drive" ]
                , attributes = [ Element.width (Element.px 260) ]
            }
            selectOptions
        ]
    , demoRow "Sizes · status · disabled"
        [ Select.view theme
            { selectD
                | size = Select.Small
                , value = SelectMenu.Single (Just "drive")
                , attributes = [ Element.width (Element.px 200) ]
            }
            selectOptions
        , Select.view theme
            { selectD
                | size = Select.Large
                , value = SelectMenu.Single (Just "drive")
                , attributes = [ Element.width (Element.px 240) ]
            }
            selectOptions
        , Select.view theme
            { selectD
                | status = Just BaseSelection.Warning
                , value = SelectMenu.Single (Just "drive")
                , attributes = [ Element.width (Element.px 200) ]
            }
            selectOptions
        , Select.view theme
            { selectD
                | disabled = True
                , value = SelectMenu.Single (Just "drive")
                , attributes = [ Element.width (Element.px 200) ]
            }
            selectOptions
        ]
    , demoRow "Menu: loading (the __loading row)"
        [ Select.menu theme
            { selMenuD
                | loading = True
                , attributes = [ Element.width (Element.px 200) ]
            }
            [ SelectMenu.Option { value = "a", label = "A", disabled = False, attributes = [] }
            , SelectMenu.Option { value = "b", label = "B", disabled = False, attributes = [] }
            ]
        ]
    , demoRow "Menu: header · action · selected"
        [ Select.menu theme
            { selMenuD
                | header = Just (Element.text "Header")
                , action = Just (Element.text "#action")
                , value = SelectMenu.Single (Just "drive")
                , attributes = [ Element.width (Element.px 200) ]
            }
            selectOptions
        ]
    ]


selectSection : Element msg
selectSection =
    section "Select" selectDesc selectRows


selectLiveSection : Model -> Element Msg
selectLiveSection model =
    section "Select" selectDesc (selectRows ++ [ selectSingleLiveRow model, selectMultipleLiveRow model ])


{-| The Popselect section description (shared by the static and live variants).
-}
popselectDesc : String
popselectDesc =
    "The popover-family body whose select-menu root is itself the popover-shared body (upstream `internalRenderBody` — the `Dropdown` path: no `n-popover` element, `--n-padding` zeroed, `--show-arrow` present unless `overlap` even with no arrow node). Selection is pure — `value` drives the per-option checkmarks, `toggleValue` computes the next value — while the caller owns the show state (`'hover'` trigger), positioning (default placement bottom) and the auto-close on single select. `NUI.SelectMenu` (the support module this composes) stands bare in the last row."


popselectRows : List (Element msg)
popselectRows =
    [ demoRow "Single (leaves + group)"
        [ popoverHost Popover.Bottom
            []
            (Popselect.view theme
                { popselectD
                    | width = Just "200px"
                    , value = SelectMenu.Single (Just "drive")
                }
                popselectOptions
            )
        ]
    , demoRow "Multiple (--multiple marker)"
        [ popoverHost Popover.Bottom
            []
            (Popselect.view theme
                { popselectD
                    | width = Just "200px"
                    , multiple = True
                    , value = SelectMenu.Multiple [ "in-my-life", "the-word" ]
                }
                popselectOptions
            )
        ]
    , demoRow "Bare NUI.SelectMenu (no popover classes)"
        [ SelectMenu.view theme
            { selectMenuD
                | size = SelectMenu.Small
                , header = Just (Element.text "Header")
                , action = Just (Element.text "#action")
                , attributes = [ Element.width (Element.px 200) ]
            }
            popselectOptions
        ]
    ]


popselectSection : Element msg
popselectSection =
    section "Popselect" popselectDesc popselectRows


popselectLiveSection : Model -> Element Msg
popselectLiveSection model =
    section "Popselect" popselectDesc (popselectRows ++ [ popselectLiveRow model ])


{-| The Cascader section description (shared by the static and live variants).
-}
cascaderDesc : String
cascaderDesc =
    "Naive UI's cascader — the `NUI.BaseSelection` trigger (the `NUI.Select` lane) plus the multi-column menu, both caller-mounted bodies (upstream opens each in its own follower): `Cascader.menu` for the columns (the hover key's path decides them, `menuModel`; option states come from the value's `All`-strategy normalization) and `Cascader.selectMenu` for the filterable flat body (`filterOptions`' path-label rows). `view` derives the display from `value` + the tree: the single path label (unknown keys show themselves), the multiple cascade-normalized tags with the numeric `maxTagCount` slice. The treemate cascade logic ships pure — `getCheckedKeys` / `check` / `uncheck` / `toggleValue`; the caller owns the show state, positioning, keyboard and remote loading (`loadingKeys`)."


cascaderRows : List (Element msg)
cascaderRows =
    [ demoRow "Single (path label) · multiple (maxTagCount)"
        [ Cascader.view theme
            { cascaderD
                | value = SelectMenu.Single (Just "eleanor")
                , clearable = True
                , hover = True
                , attributes = [ Element.width (Element.px 280) ]
            }
            cascaderOptions
        , Cascader.view theme
            { cascaderD
                | multiple = True
                , maxTagCount = Just 2
                , value = SelectMenu.Multiple [ "abbey", "revolver" ]
                , attributes = [ Element.width (Element.px 320) ]
            }
            cascaderOptions
        ]
    , demoRow "Columns menu (hover key opens the second column)"
        [ Cascader.menu theme
            { cascMenuD
                | hoverKey = Just "revolver"
                , multiple = True
                , value = SelectMenu.Multiple [ "abbey", "come" ]
                , attributes = [ Element.width (Element.px 420) ]
            }
            cascaderOptions
        ]
    , demoRow "Columns menu: child strategy (leaf checkmarks) · empty · action"
        [ Cascader.menu theme
            { cascMenuD
                | checkStrategy = Cascader.Child
                , value = SelectMenu.Single (Just "drive")
                , action = Just (Element.text "#action")
                , attributes = [ Element.width (Element.px 200) ]
            }
            cascaderOptions
        , Cascader.menu theme
            { cascMenuD | attributes = [ Element.width (Element.px 200) ] }
            []
        ]
    , demoRow "Filterable flat menu (pattern 'sub')"
        [ Cascader.selectMenu theme
            { cascSelectMenuD
                | multiple = True
                , value = SelectMenu.Multiple [ "abbey" ]
                , attributes = [ Element.width (Element.px 280) ]
            }
            (Cascader.filterOptions "sub" Cascader.All " / " cascaderOptions)
        ]
    ]


cascaderSection : Element msg
cascaderSection =
    section "Cascader" cascaderDesc cascaderRows


cascaderLiveSection : Model -> Element Msg
cascaderLiveSection model =
    section "Cascader" cascaderDesc (cascaderRows ++ [ cascaderLiveRow model ])


{-| The TreeSelect section description (shared by the static and live variants).
-}
treeSelectDesc : String
treeSelectDesc =
    "A selection trigger over a tree menu — show, positioning and the pattern/expand state are caller-owned."


treeSelectRows : List (Element msg)
treeSelectRows =
    let
        node key label disabled kids =
            Tree.TreeOption
                { key = key
                , label = label
                , disabled = disabled
                , checkboxDisabled = False
                , isLeaf = kids == Nothing
                , children = kids
                , prefix = []
                , suffix = []
                }

        data =
            [ node "o1"
                "Outfield"
                False
                (Just
                    [ node "o1-1" "Left" False (Just [ node "o1-3" "Bench" False Nothing ])
                    , node "o1-2" "Right" False Nothing
                    ]
                )
            , node "o2" "Pitcher" False Nothing
            , node "o3" "Disabled" True Nothing
            ]

        menuBox =
            Element.width (Element.px 260)
    in
    [ demoRow "Basic single"
        [ Element.column [ Element.spacing 8 ]
            [ TreeSelect.view theme
                { tsD
                    | options = data
                    , value = SelectMenu.Single (Just "o1-1")
                    , pendingKey = Just "o1-1"
                    , expandedKeys = [ "o1" ]
                }
            , Element.el [ menuBox ]
                (TreeSelect.menu theme
                    { tsD
                        | options = data
                        , value = SelectMenu.Single (Just "o1-1")
                        , pendingKey = Just "o1-1"
                        , expandedKeys = [ "o1", "o1-1" ]
                    }
                )
            ]
        ]
    , demoRow "Multiple + cascade + checkable"
        [ Element.column [ Element.spacing 8 ]
            [ TreeSelect.view theme
                { tsD
                    | options = data
                    , multiple = True
                    , checkable = True
                    , cascade = True
                    , value = SelectMenu.Multiple [ "o1-1", "o2" ]
                    , maxTagCount = Just 2
                }
            , Element.el [ menuBox ]
                (TreeSelect.menu theme
                    { tsD
                        | options = data
                        , multiple = True
                        , checkable = True
                        , cascade = True
                        , value = SelectMenu.Multiple [ "o1-1", "o2" ]
                        , expandedKeys = [ "o1" ]
                    }
                )
            ]
        ]
    , demoRow "Filterable + showPath"
        [ Element.column [ Element.spacing 8 ]
            [ TreeSelect.view theme
                { tsD
                    | options = data
                    , filterable = True
                    , showPath = True
                    , value = SelectMenu.Single (Just "o1-3")
                    , expandedKeys = [ "o1", "o1-1" ]
                }
            , Element.el [ menuBox ]
                (TreeSelect.menu theme
                    { tsD
                        | options = data
                        , filterable = True
                        , pattern = "eft"
                        , expandedKeys = [ "o1" ]
                    }
                )
            ]
        ]
    , demoRow "Slots + empty"
        [ Element.column [ Element.spacing 8 ]
            [ TreeSelect.view theme
                { tsD
                    | options = data
                    , status = Just BaseSelection.Error
                    , clearable = True
                    , hover = True
                    , value = SelectMenu.Single (Just "o2")
                }
            , Element.el [ menuBox ]
                (TreeSelect.menu theme
                    { tsD
                        | header = Just (Element.text "Header slot")
                        , action = Just (Element.text "Action slot")
                        , empty = Just (Element.text "No data")
                        , options = []
                    }
                )
            ]
        ]
    ]


treeSelectSection : Element msg
treeSelectSection =
    section "TreeSelect" treeSelectDesc treeSelectRows


treeSelectLiveSection : Model -> Element Msg
treeSelectLiveSection model =
    section "TreeSelect" treeSelectDesc (treeSelectRows ++ [ treeSelectLiveRow model ])


{-| The AutoComplete section description (shared by the static and live variants).
-}
autoCompleteDesc : String
autoCompleteDesc =
    "Naive UI's autocomplete — a bare `.n-auto-complete` wrapper around a plain `NUI.Input` trigger (NOT the selection: upstream drives `NInput` directly, no `NInternalSelection`); the menu is a separate caller-mounted body (its own follower upstream), `AutoComplete.menu` here — hardcoded Medium, `tabindex -1`, never `--selected` (no checkmark node), and `loading` is the input's suffix spinner, never a menu row. The caller owns the whole show gate (`getShow ? getShow (value || \"\") : value ≠ \"\"`, focused-typed, `showEmpty`), positioning, keyboard and the select commit (`onSelect value` always, then `clearAfterSelect` → null / the label commit, `append` ⇒ `value ++ label`); it does no filtering of its own — options are yours to derive (the email demo's suffix list). `fromString` lifts bare strings; `inputAttributes` is upstream's `inputProps`."


autoCompleteRows : List (Element msg)
autoCompleteRows =
    [ demoRow "Basic (value + open menu + inputProps)"
        [ AutoComplete.view theme
            { acD | value = "Dri", attributes = [ Element.width (Element.px 220) ] }
        , AutoComplete.view theme
            { acD
                | value = "v4f2"
                , inputAttributes =
                    [ HA.attribute "autocomplete" "disabled"
                    , HA.id "ac-input-props"
                    ]
                , attributes = [ Element.width (Element.px 220) ]
            }
        , AutoComplete.menu theme
            { acMenuD | attributes = [ Element.width (Element.px 220) ] }
            [ AutoComplete.fromString "Drive My Car"
            , AutoComplete.fromString "Day Tripper"
            ]
        ]
    , demoRow "Sizes (the menu stays Medium)"
        [ AutoComplete.view theme
            { acD | size = AutoComplete.Small, value = "Dri", attributes = [ Element.width (Element.px 200) ] }
        , AutoComplete.view theme
            { acD | value = "Dri", attributes = [ Element.width (Element.px 220) ] }
        , AutoComplete.view theme
            { acD | size = AutoComplete.Large, value = "Dri", attributes = [ Element.width (Element.px 240) ] }
        , AutoComplete.menu theme
            { acMenuD | attributes = [ Element.width (Element.px 220) ] }
            (List.take 2 selectOptions)
        ]
    , demoRow "Group (header + children)"
        [ AutoComplete.view theme
            { acD | value = "In My Life", attributes = [ Element.width (Element.px 220) ] }
        , AutoComplete.menu theme
            { acMenuD | attributes = [ Element.width (Element.px 220) ] }
            selectOptions
        ]
    , demoRow "Status · disabled"
        [ AutoComplete.view theme
            { acD
                | status = Just Input.Warning
                , value = "warn@example.com"
                , attributes = [ Element.width (Element.px 220) ]
            }
        , AutoComplete.view theme
            { acD
                | status = Just Input.Error
                , value = "error@example.com"
                , attributes = [ Element.width (Element.px 220) ]
            }
        , AutoComplete.view theme
            { acD
                | disabled = True
                , value = "Disabled"
                , attributes = [ Element.width (Element.px 220) ]
            }
        ]
    , demoRow "Clearable · loading (suffix order: clear, loading, slot)"
        [ AutoComplete.view theme
            { acD | value = "clear me", clearable = True, attributes = [ Element.width (Element.px 200) ] }
        , AutoComplete.view theme
            { acD
                | value = "Loading…"
                , loading = True
                , attributes = [ Element.width (Element.px 200) ]
            }
        , AutoComplete.view theme
            { acD
                | value = "all three"
                , clearable = True
                , loading = True
                , suffix = Just (Element.text "@")
                , attributes = [ Element.width (Element.px 200) ]
            }
        ]
    , demoRow "Show gate (showEmpty + the empty seam)"
        [ AutoComplete.view theme
            { acD | placeholder = "Type to open", attributes = [ Element.width (Element.px 220) ] }
        , AutoComplete.menu theme
            { acMenuD
                | empty = Just (Empty.view theme emptyD [])
                , attributes = [ Element.width (Element.px 220) ]
            }
            []
        ]
    , demoRow "After select (the caller-owned commit)"
        [ cell
            (Element.column [ Element.spacing 6, Element.width Element.fill ]
                [ AutoComplete.view theme
                    { acD | placeholder = "clearAfterSelect → \"\"", attributes = [ Element.width (Element.px 200) ] }
                , chip "onSelect \"Drive My Car\" → value = \"\""
                ]
            )
        , cell
            (Element.column [ Element.spacing 6, Element.width Element.fill ]
                [ AutoComplete.view theme
                    { acD
                        | value = "Dri"
                        , placeholder = "append ⇒ value ++ label"
                        , attributes = [ Element.width (Element.px 200) ]
                    }
                , chip "onSelect \"Drive My Car\" → \"DriDrive My Car\""
                ]
            )
        ]
    , demoRow "Custom rows (renderLabel / renderOption)"
        [ AutoComplete.menu theme
            { acMenuD | attributes = [ Element.width (Element.px 220) ] }
            [ AutoComplete.fromString "A plain row"
            , SelectMenu.Custom
                { key = "ac-custom"
                , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text "renderOption row" ]
                }
            ]
        ]
    ]


autoCompleteSection : Element msg
autoCompleteSection =
    section "AutoComplete" autoCompleteDesc autoCompleteRows


autoCompleteLiveSection : Model -> Element Msg
autoCompleteLiveSection model =
    section "AutoComplete" autoCompleteDesc (autoCompleteRows ++ [ autoCompleteLiveRow model ])


{-| The Mention section description (shared by the static and live variants).
-}
mentionDesc : String
mentionDesc =
    "Naive UI's mention — the same family as AutoComplete: a bare `.n-mention` wrapper around a plain `NUI.Input` trigger (NOT the selection — no `NInternalSelection` upstream), plus a separate caller-mounted `NUI.SelectMenu` body (`Mention.menu`). Three divergences from AutoComplete, frozen: `loading` is the MENU's `__loading` row (`MenuOptions.loading`), never the input suffix; upstream filters internally (the default `startsWith` predicate — the port drops the engine, the caller pre-filters and passes the filtered list); and the wrapper's cssr has no `display: inline-flex` (`width: 100%; z-index: auto; position: relative`) with `placeholder` defaulting to `\"\"`. The menu is hardcoded Medium, `tabindex -1`, and `value` stays `Single Nothing` — never `--selected`, no checkmark node. Options are `NUI.SelectMenu.Option` verbatim — no `fromString` (there are no bare-string options upstream); `type_` is `text`/`textarea` only. The caller owns the whole runtime: the show gate (the prefix scan + caret + separator formulas), the select splice, keyboard and positioning (upstream anchors the follower at the caret via mirror-div measurement — un-portable)."


mentionRows : List (Element msg)
mentionRows =
    [ demoRow "Basic (the default @-trigger — caret inside an @-run opens)"
        [ cell
            (Element.column [ Element.spacing 6, Element.width Element.fill ]
                [ Mention.view theme
                    { mnD
                        | value = "@710"
                        , attributes = [ Element.width (Element.px 220) ]
                    }
                , Mention.menu theme
                    { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
                    mentionOptions
                ]
            )
        , Mention.view theme
            { mnD
                | placeholder = "Type @ to mention"
                , attributes = [ Element.width (Element.px 220) ]
            }
        ]
    , demoRow "Sizes (the menu stays Medium)"
        [ Mention.view theme
            { mnD | size = Mention.Small, value = "@710", attributes = [ Element.width (Element.px 200) ] }
        , Mention.view theme
            { mnD | value = "@710", attributes = [ Element.width (Element.px 220) ] }
        , Mention.view theme
            { mnD | size = Mention.Large, value = "@710", attributes = [ Element.width (Element.px 240) ] }
        , Mention.menu theme
            { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
            (List.take 4 mentionOptions)
        ]
    , demoRow "Textarea (type_ = Textarea — the union is text/textarea only)"
        [ Element.el [ Element.width (Element.px 360) ]
            (Mention.view theme
                { mnD
                    | type_ = Mention.Textarea
                    , value = "A textarea.\nPing @710mechgy here."
                    , placeholder = "Type @ to mention"
                }
            )
        ]
    , demoRow "Autosize (n-input--autosize, resizable suppressed — height measurement caller-owned)"
        [ Element.el [ Element.width (Element.px 360) ]
            (Mention.view theme
                { mnD
                    | type_ = Mention.Textarea
                    , autosize = True
                    , value = "Autosized textarea:\ngrows with content."
                }
            )
        ]
    , demoRow "Custom prefix (#@ — the caller gates the option set; the module does no scan)"
        [ cell
            (Element.column [ Element.spacing 6, Element.width Element.fill ]
                [ Mention.view theme
                    { mnD
                        | value = "#e"
                        , placeholder = "# for tags"
                        , attributes = [ Element.width (Element.px 200) ]
                    }
                , chip "prefix \"#\" → the tag list"
                , Mention.menu theme
                    { mnMenuD | attributes = [ Element.width (Element.px 200) ] }
                    mentionTagOptions
                ]
            )
        , cell
            (Element.column [ Element.spacing 6, Element.width Element.fill ]
                [ Mention.view theme
                    { mnD
                        | value = "@z"
                        , placeholder = "@ for users"
                        , attributes = [ Element.width (Element.px 200) ]
                    }
                , chip "prefix \"@\" → the user list"
                , Mention.menu theme
                    { mnMenuD | attributes = [ Element.width (Element.px 200) ] }
                    mentionOptions
                ]
            )
        ]
    , demoRow "Loading (THE divergence — the menu's __loading row, never the input suffix)"
        [ Mention.view theme
            { mnD
                | value = "@7"
                , placeholder = "Fetching users…"
                , attributes = [ Element.width (Element.px 220) ]
            }
        , Mention.menu theme
            { mnMenuD | loading = True, attributes = [ Element.width (Element.px 220) ] }
            mentionOptions
        ]
    , demoRow "Group + custom rows (renderLabel lane)"
        [ Mention.view theme
            { mnD
                | value = "@in my"
                , attributes = [ Element.width (Element.px 220) ]
            }
        , Mention.menu theme
            { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
            (selectOptions
                ++ [ SelectMenu.Custom
                        { key = "mention-custom"
                        , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text "renderOption row" ]
                        }
                   ]
            )
        ]
    , demoRow "Status · disabled"
        [ Mention.view theme
            { mnD
                | status = Just Input.Warning
                , value = "@710"
                , attributes = [ Element.width (Element.px 220) ]
            }
        , Mention.view theme
            { mnD
                | status = Just Input.Error
                , value = "@zhe"
                , attributes = [ Element.width (Element.px 220) ]
            }
        , Mention.view theme
            { mnD
                | disabled = True
                , value = "Disabled"
                , attributes = [ Element.width (Element.px 220) ]
            }
        ]
    ]


mentionSection : Element msg
mentionSection =
    section "Mention" mentionDesc mentionRows


mentionLiveSection : Model -> Element Msg
mentionLiveSection model =
    section "Mention" mentionDesc (mentionRows ++ [ mentionLiveRow model ])


{-| The DatePicker section description (shared by the static and live variants).
-}
datePickerDesc : String
datePickerDesc =
    "An input trigger over a caller-mounted calendar panel — every upstream panel type, with show state, positioning and the value caller-owned."


datePickerRows : List (Element msg)
datePickerRows =
    let
        now =
            Time.millisToPosix 1715731200000

        may15 =
            1715731200000

        dt =
            1715770440000

        base =
            { dpD | now = now }

        pair opts =
            Element.column [ Element.spacing 12, Element.width Element.fill ]
                [ DatePicker.view theme opts
                , DatePicker.panel theme opts
                ]

        rangeOpts opts =
            { opts
                | value = DatePicker.Range (Just ( may10, may20 ))
                , startCalendarValue = Just may10
                , endCalendarValue = Just may20
            }
    in
    [ demoRow "Date"
        [ pair { base | value = DatePicker.Single (Just may15) } ]
    , demoRow "Datetime"
        [ pair { base | type_ = DatePicker.Datetime, value = DatePicker.Single (Just dt) } ]
    , demoRow "Date range (pair input)"
        [ pair (rangeOpts { base | type_ = DatePicker.Daterange }) ]
    , demoRow "Datetime range"
        [ pair (rangeOpts { base | type_ = DatePicker.Datetimerange }) ]
    , demoRow "Month"
        [ pair { base | type_ = DatePicker.Month, value = DatePicker.Single (Just may15) } ]
    , demoRow "Year"
        [ pair
            { base
                | type_ = DatePicker.Year
                , value = DatePicker.Single (Just may15)
                , yearRange = ( 2015, 2035 )
            }
        ]
    , demoRow "Quarter"
        [ pair { base | type_ = DatePicker.Quarter, value = DatePicker.Single (Just may15) } ]
    , demoRow "Month range"
        [ pair (rangeOpts { base | type_ = DatePicker.Monthrange }) ]
    , demoRow "Week"
        [ pair { base | type_ = DatePicker.Week, value = DatePicker.Single (Just may15) } ]
    , demoRow "Sizes / clearable / status / disabled"
        [ DatePicker.view theme { base | size = T.Small, value = DatePicker.Single (Just may15) }
        , DatePicker.view theme { base | value = DatePicker.Single (Just may15), clearable = True }
        , DatePicker.view theme { base | size = T.Large, placeholder = Just "Pick a date" }
        , DatePicker.view theme { base | value = DatePicker.Single (Just may15), status = Just Input.Error }
        , DatePicker.view theme { base | value = DatePicker.Single (Just may15), disabled = True }
        ]
    , demoRow "Range clearable + shortcuts"
        [ pair
            (rangeOpts
                { base
                    | type_ = DatePicker.Daterange
                    , clearable = True
                    , shortcuts =
                        [ ( "This week", DatePicker.ShortcutRange ( may10, may20 ) )
                        , ( "Today", DatePicker.ShortcutSingle may15 )
                        ]
                }
            )
        ]
    ]


datePickerSection : Element msg
datePickerSection =
    section "DatePicker" datePickerDesc datePickerRows


datePickerLiveSection : Model -> Element Msg
datePickerLiveSection model =
    section "DatePicker" datePickerDesc (datePickerRows ++ [ dpSingleLiveRow model, dpRangeLiveRow model ])


{-| The TimePicker section description (shared by the static and live variants).
-}
timePickerDesc : String
timePickerDesc =
    "An input trigger over a caller-mounted clock panel — show state, positioning and the value are caller-owned."


timePickerRows : List (Element msg)
timePickerRows =
    let
        tenToEleven =
            (10 * 60 + 54) * 60 * 1000

        pair opts =
            Element.column [ Element.spacing 8 ]
                [ TimePicker.view theme opts
                , Element.el [ Element.width (Element.px 200) ]
                    (TimePicker.panel theme opts)
                ]
    in
    [ demoRow "Default (HH:mm:ss)"
        [ pair { tpD | value = Just tenToEleven } ]
    , demoRow "Hour + minute (HH:mm)"
        [ pair { tpD | format = "HH:mm", value = Just tenToEleven } ]
    , demoRow "12 hours + period (hh:mm:ss a)"
        [ pair { tpD | use12Hours = True, format = "hh:mm:ss a", value = Just tenToEleven } ]
    , demoRow "Actions clear / now / confirm"
        [ pair
            { tpD
                | value = Just tenToEleven
                , clearable = True
                , actions = [ TimePicker.Clear, TimePicker.Now, TimePicker.Confirm ]
            }
        ]
    , demoRow "Disabled units (5-min steps, seconds 0/30, hours ≤ 12)"
        [ pair
            { tpD
                | value = Just tenToEleven
                , minutes = TimePicker.StepUnits 5
                , seconds = TimePicker.OnlyUnits [ 0, 30 ]
                , isHourDisabled = Just (\h -> h > 12)
            }
        ]
    , demoRow "Sizes / clearable / disabled / status"
        [ TimePicker.view theme { tpD | size = T.Small, value = Just tenToEleven }
        , TimePicker.view theme { tpD | value = Just tenToEleven, clearable = True }
        , TimePicker.view theme { tpD | size = T.Large, placeholder = "Pick" }
        , TimePicker.view theme { tpD | value = Just tenToEleven, disabled = True }
        , TimePicker.view theme { tpD | value = Just tenToEleven, status = Just Input.Error }
        ]
    ]


timePickerSection : Element msg
timePickerSection =
    section "TimePicker" timePickerDesc timePickerRows


timePickerLiveSection : Model -> Element Msg
timePickerLiveSection model =
    section "TimePicker" timePickerDesc (timePickerRows ++ [ tpLiveRow model ])


{-| The ColorPicker section description (shared by the static and live variants).
-}
colorPickerDesc : String
colorPickerDesc =
    "A colour trigger over a caller-mounted palette panel — show state, positioning, drag and the value are caller-owned."


colorPickerRows : List (Element msg)
colorPickerRows =
    let
        cpd =
            ColorPicker.defaultOptions

        pair opts =
            Element.column [ Element.spacing 8, Element.width (Element.px 240) ]
                [ ColorPicker.view theme opts
                , Element.el [ Element.width (Element.px 240) ] (ColorPicker.panel theme opts)
                ]

        red =
            "#d03050"
    in
    [ demoRow "Basic"
        [ pair { cpd | value = Just red } ]
    , demoRow "Alpha off + confirm"
        [ pair { cpd | value = Just red, showAlpha = False, actions = Just [ ColorPicker.ConfirmAction ] } ]
    , demoRow "Sizes"
        [ pair { cpd | value = Just red, size = T.Small }
        , pair { cpd | value = Just red }
        , pair { cpd | value = Just red, size = T.Large }
        ]
    , demoRow "Disabled"
        [ pair { cpd | value = Just red, disabled = True } ]
    , demoRow "Single mode (hex)"
        [ pair { cpd | value = Just red, modes = [ ColorPicker.Hex ], displayedMode = ColorPicker.Hex } ]
    , demoRow "Swatches"
        [ pair
            { cpd
                | value = Just red
                , swatches = [ "#000000", "#ffffff", red, "rgba(208, 48, 80, 1)", "#0f0" ]
            }
        ]
    , demoRow "Actions clear"
        [ pair { cpd | value = Just red, actions = Just [ ColorPicker.ClearAction ] } ]
    , demoRow "Preview (native input)"
        [ pair { cpd | value = Just red, showPreview = True } ]
    , demoRow "Custom trigger"
        [ ColorPicker.view theme
            { cpd
                | value = Just red
                , customTrigger = Just (Button.view theme { btn | kind = T.Primary } [ Element.text "Pick a colour" ])
            }
        ]
    , demoRow "Undo / redo actions"
        [ pair
            { cpd
                | value = Just red
                , internalActions = Just [ ColorPicker.UndoAction, ColorPicker.RedoAction ]
                , undoable = True
            }
        ]
    ]


colorPickerSection : Element msg
colorPickerSection =
    section "ColorPicker" colorPickerDesc colorPickerRows


colorPickerLiveSection : Model -> Element Msg
colorPickerLiveSection model =
    section "ColorPicker" colorPickerDesc (colorPickerRows ++ [ cpLiveRow model ])


{-| The family body in Main.body order — live variants for every section
(each gains at least one live demo row appended after the static rows).
-}
sections : Model -> List (Element Msg)
sections model =
    [ selectLiveSection model
    , popselectLiveSection model
    , cascaderLiveSection model
    , treeSelectLiveSection model
    , autoCompleteLiveSection model
    , mentionLiveSection model
    , datePickerLiveSection model
    , timePickerLiveSection model
    , colorPickerLiveSection model
    ]



-- OPTION RECORDS / SHARED FIXTURES / HELPERS (static surface, unchanged)


btn : Button.Options msg
btn =
    Button.defaults


tagD : Tag.Options msg
tagD =
    Tag.defaults


emptyD : Empty.Options msg
emptyD =
    Empty.defaults


popselectD : Popselect.Options msg
popselectD =
    Popselect.defaults


selectMenuD : SelectMenu.Options msg
selectMenuD =
    SelectMenu.defaults


selectD : Select.Options msg
selectD =
    Select.defaults


selMenuD : Select.MenuOptions msg
selMenuD =
    Select.menuDefaults


cascaderD : Cascader.Options msg
cascaderD =
    Cascader.defaults


cascMenuD : Cascader.MenuOptions msg
cascMenuD =
    Cascader.menuDefaults


cascSelectMenuD : Cascader.SelectMenuOptions msg
cascSelectMenuD =
    Cascader.selectMenuDefaults


acD : AutoComplete.Options msg
acD =
    AutoComplete.defaults


acMenuD : AutoComplete.MenuOptions msg
acMenuD =
    AutoComplete.menuDefaults


mnD : Mention.Options msg
mnD =
    Mention.defaults


mnMenuD : Mention.MenuOptions msg
mnMenuD =
    Mention.menuDefaults


{-| The caller-owned follower wrapper: a `v-placement` host the popover body sits
in (upstream: vueuc's `v-binder-follower-content` with runtime positioning).
-}
popoverHost : Popover.Placement -> List (Element.Attribute msg) -> Element msg -> Element msg
popoverHost placement attrs content =
    Element.el
        ([ Popover.placementAttribute placement
         , Element.htmlAttribute (HA.attribute "style" "position:relative;padding:34px 28px;")
         ]
            ++ attrs
        )
        content


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
