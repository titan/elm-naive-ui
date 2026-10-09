module Sections.Pickers exposing
    ( Model
    , Msg
    , init
    , sections
    , subscriptions
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
    `alphaFromPoint` geometry against the rect captured synchronously at
    press (the mousedown decoder carries the surface's size and viewport
    origin — no async rect read), and per-unit typing parses through the
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

Phase 2 — the static rows are state-driven with identical init (the brief's
technique; `spec*` fields, init = each row's current literals). The open
menu / open panel specimens (Select/Cascader/TreeSelect/AutoComplete/Mention
menus, DatePicker/TimePicker/ColorPicker pairs) keep rendering open at init
but wire their value + channels so interacting commits (option click moves
the checkmark, day/cell click commits, Confirm/Clear closes the panel —
`open` per row, init True) and the trigger's focus/click reopens. Rows that
are pure state showcases (disabled/status/sizes/loading/empty/pattern pins,
the no-channel plain triggers — Select emits nothing without a mounted menu)
stay specimens. ColorPicker static rows wire value/mode/undo-redo/
confirm/clear/show with ONE live value (every commit path — drag frame,
swatch click, complete unit parse — writes `value` directly, so the
trigger's colour and label track per frame exactly as upstream's single
`mergedValue` does; upstream has no draft/committed split — Confirm only
closes) plus the drag pointer surface (per-instance
`pointerAreaIds` on the shared subscription pair — the drag flag carries
the site) and per-unit typing; TimePicker static
rows skip the column scroll commands (`colContainerIds` belongs to the live
row's panel).

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
    , cpDrag : Maybe CpDragCtx
    , cpDragOrigin : Maybe ( CpDragSite, Maybe String )
    , cpUnitText : Maybe String

    -- phase-2 static-row state (init = the rows' current literals)
    , specSelClearable : SelectMenu.Value
    , specSelMulti : SelectMenu.Value
    , specSelMultiFilter : SelectMenu.Value
    , specSelMenu : SelectMenu.Value
    , specPopSingle : SelectMenu.Value
    , specPopMulti : SelectMenu.Value
    , specPopSelectMenu : SelectMenu.Value
    , specCascSingle : SelectMenu.Value
    , specCascMulti : SelectMenu.Value
    , specCascMenu : SelectMenu.Value
    , specCascMenuHover : Maybe String
    , specCascChild : SelectMenu.Value
    , specCascFlat : SelectMenu.Value
    , specTsSingle : SelectMenu.Value
    , specTsSinglePending : Maybe String
    , specTsMulti : SelectMenu.Value
    , specTsFilter : SelectMenu.Value
    , specAcBasic : String
    , specAcGroup : String
    , specAcClearable : String
    , specMnBasic : String
    , specMnBasic2 : String
    , specMnTextarea : String
    , specMnAutosize : String
    , specMnGroupTag : String
    , specMnGroupUser : String
    , specMnGroup2 : String
    , specDp : SpecDpStates
    , specTp : SpecTpStates
    , specCp : SpecCpStates
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
    , cpDragOrigin = Nothing
    , cpUnitText = Nothing

    -- phase-2 static-row state — every field is the row's CURRENT literal
    , specSelClearable = SelectMenu.Single (Just "drive")
    , specSelMulti = SelectMenu.Multiple [ "a", "b", "c", "d", "ghost" ]
    , specSelMultiFilter = SelectMenu.Multiple [ "drive" ]
    , specSelMenu = SelectMenu.Single (Just "drive")
    , specPopSingle = SelectMenu.Single (Just "drive")
    , specPopMulti = SelectMenu.Multiple [ "in-my-life", "the-word" ]
    , specPopSelectMenu = SelectMenu.Single Nothing
    , specCascSingle = SelectMenu.Single (Just "eleanor")
    , specCascMulti = SelectMenu.Multiple [ "abbey", "revolver" ]
    , specCascMenu = SelectMenu.Multiple [ "abbey", "come" ]
    , specCascMenuHover = Just "revolver"
    , specCascChild = SelectMenu.Single (Just "drive")
    , specCascFlat = SelectMenu.Multiple [ "abbey" ]
    , specTsSingle = SelectMenu.Single (Just "o1-1")
    , specTsSinglePending = Just "o1-1"
    , specTsMulti = SelectMenu.Multiple [ "o1-1", "o2" ]
    , specTsFilter = SelectMenu.Single (Just "o1-3")
    , specAcBasic = "Dri"
    , specAcGroup = "In My Life"
    , specAcClearable = "clear me"
    , specMnBasic = "@710"
    , specMnBasic2 = ""
    , specMnTextarea = "A textarea.\nPing @710mechgy here."
    , specMnAutosize = "Autosized textarea:\ngrows with content."
    , specMnGroupTag = "#e"
    , specMnGroupUser = "@z"
    , specMnGroup2 = "@in my"
    , specDp = specDpInit
    , specTp = specTpInit
    , specCp = specCpInit
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
    | CpClosed
    | CpValueUpdated (Maybe String)
    | CpModeChanged ColorPicker.Mode
    | CpConfirmed (Maybe String)
    | CpCleared
    | CpUndone
    | CpRedone
    | CpDragStarted ColorPicker.PointerPress
    | CpDragMove Int Int
    | CpDragEnd
    | CpUnitTyped Int String -- phase-2 static rows (state-drive with identical init)
    | SpecSelCleared
    | SpecSelMultiTagDeleted String
    | SpecSelMultiFilterTagDeleted String
    | SpecSelMenuPicked String
    | SpecPopSinglePicked SelectMenu.Value
    | SpecPopMultiPicked SelectMenu.Value
    | SpecPopSelectMenuPicked String
    | SpecCascSingleCleared
    | SpecCascMultiTagDeleted String
    | SpecCascMenuToggled String
    | SpecCascChildPicked String
    | SpecCascFlatToggled String
    | SpecTsNodeClicked SpecTsRow String
    | SpecAcBasicTyped String
    | SpecAcBasicPicked String
    | SpecAcGroupTyped String
    | SpecAcGroupPicked String
    | SpecAcClearableTyped String
    | SpecAcCustomPicked String
    | SpecMnBasicTyped String
    | SpecMnBasicPicked String
    | SpecMnBasic2Typed String
    | SpecMnTextareaTyped String
    | SpecMnAutosizeTyped String
    | SpecMnGroupTagTyped String
    | SpecMnGroupTagPicked String
    | SpecMnGroupUserTyped String
    | SpecMnGroupUserPicked String
    | SpecMnGroup2Typed String
    | SpecMnGroup2Picked String
    | SpecDpFocused SpecDpRow
    | SpecDpValueSet SpecDpRow DatePicker.Value
    | SpecDpCleared SpecDpRow
    | SpecDpConfirmed SpecDpRow
    | SpecDpCalendar SpecDpRow DatePicker.CalendarSide Int
    | SpecDpMonthToggled SpecDpRow Bool
    | SpecDpDateClicked SpecDpRow Int
    | SpecDpHovered SpecDpRow Int
    | SpecDpMonthItem SpecDpRow Int DatePicker.RangePos
    | SpecTpFocused SpecTpRow
    | SpecTpValueSet SpecTpRow (Maybe Int)
    | SpecTpConfirmed SpecTpRow
    | SpecTpCleared SpecTpRow
    | SpecCpOpened SpecCpRow
    | SpecCpValueUpdated SpecCpRow (Maybe String)
    | SpecCpModeChanged SpecCpRow ColorPicker.Mode
    | SpecCpConfirmed SpecCpRow (Maybe String)
    | SpecCpCleared SpecCpRow
    | SpecCpUndone SpecCpRow
    | SpecCpRedone SpecCpRow
    | SpecCpUnitTyped SpecCpRow Int String
    | SpecCpDragStarted SpecCpRow Int ColorPicker.PointerPress


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

        CpDragStarted press ->
            ( updatePure (CpDragStarted press) model, Cmd.none )

        SpecCpDragStarted row inst press ->
            ( updatePure (SpecCpDragStarted row inst press) model, Cmd.none )

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
            -- the trigger emits onUpdateShow True; upstream re-syncs nothing
            -- here (the value is always live), but the undo stack starts
            -- fresh when the panel closed last (watch(mergedShowRef) resets
            -- it to [value] — the port models that as empty undo/redo lists,
            -- undoable = not (List.isEmpty cpUndo))
            { model | cpShow = True, cpUnitText = Nothing }

        CpClosed ->
            -- panel closed (Confirm/Clear/trigger toggle): upstream resets
            -- the undo stack to [currentValue] (watch mergedShowRef)
            { model | cpShow = False, cpUndo = [], cpRedo = [] }

        CpDragStarted press ->
            -- upstream commits the pressed position immediately
            -- (Pallete.tsx handleMouseDown → handleMouseMove(e)) — the press
            -- geometry rode in synchronously with the event (relative coords
            -- + surface size + viewport origin), so the commit is pure and
            -- same-tick. The pre-drag value is snapshotted PER SITE —
            -- mouse-up pushes it onto that row's undo stack (onComplete)
            { model
                | cpDrag =
                    Just
                        { area = press.area
                        , site = CpLiveSite
                        , rect = cpPressRect press
                        }
                , cpDragOrigin = Just ( CpLiveSite, model.cpValue )
            }
                |> cpDragApplyPress press

        CpDragMove x y ->
            -- pure per-frame tracking: client coords against the press-cached
            -- viewport rect — zero DOM reads, zero async tasks
            case model.cpDrag of
                Just ctx ->
                    cpDragApply ctx.area ctx.site x y ctx.rect model

                Nothing ->
                    model

        CpDragEnd ->
            -- upstream onComplete on mouse-up: push the pre-drag value onto
            -- the dragged site's undo stack once (handleComplete pushes the
            -- CURRENT value; the port's two-list shape stores pre-states, so
            -- the origin it is) and clear that site's redo
            case model.cpDragOrigin of
                Just ( CpLiveSite, origin ) ->
                    { model
                        | cpDrag = Nothing
                        , cpUndo = maybeCons (Just origin) model.cpUndo
                        , cpRedo = []
                        , cpDragOrigin = Nothing
                    }

                Just ( CpSpecSite row, origin ) ->
                    { model | cpDrag = Nothing, cpDragOrigin = Nothing }
                        |> specCpUpd
                            row
                            (\st ->
                                { st
                                    | undo = maybeCons (Just origin) st.undo
                                    , redo = []
                                }
                            )

                Nothing ->
                    { model | cpDrag = Nothing }

        CpUnitTyped index raw ->
            cpUnitTyped index raw model

        CpValueUpdated value ->
            -- upstream doUpdateValue 'input' (swatch click): live commit;
            -- swatches ALSO run onComplete (pushes the stack) — that lands
            -- in the same handleComplete as drag mouse-up, so push here too
            { model
                | cpValue = value
                , cpDraft = value
                , cpUndo = model.cpValue :: model.cpUndo
                , cpRedo = []
            }

        CpModeChanged mode ->
            -- the panel computed nextDisplayedMode already
            { model | cpMode = mode }

        CpConfirmed _ ->
            -- upstream handleConfirm: the value is already live-committed
            -- (no stack push, no value change) — the panel just closes
            { model | cpShow = False, cpUndo = [], cpRedo = [] }

        CpCleared ->
            -- upstream handleClear: null value + close; the stack resets on
            -- close (watch mergedShowRef) — modeled as empty undo/redo
            { model
                | cpValue = Nothing
                , cpDraft = Nothing
                , cpShow = False
                , cpUndo = []
                , cpRedo = []
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

        -- phase-2 static rows
        SpecSelCleared ->
            { model | specSelClearable = SelectMenu.Single Nothing }

        SpecSelMultiTagDeleted key ->
            { model
                | specSelMulti =
                    SelectMenu.Multiple (List.filter ((/=) key) (valueKeys model.specSelMulti))
            }

        SpecSelMultiFilterTagDeleted key ->
            { model
                | specSelMultiFilter =
                    SelectMenu.Multiple (List.filter ((/=) key) (valueKeys model.specSelMultiFilter))
            }

        SpecSelMenuPicked key ->
            { model | specSelMenu = Select.toggleValue False model.specSelMenu key }

        SpecPopSinglePicked value ->
            { model | specPopSingle = value }

        SpecPopMultiPicked value ->
            { model | specPopMulti = value }

        SpecPopSelectMenuPicked key ->
            { model | specPopSelectMenu = Select.toggleValue False model.specPopSelectMenu key }

        SpecCascSingleCleared ->
            { model | specCascSingle = SelectMenu.Single Nothing }

        SpecCascMultiTagDeleted key ->
            { model
                | specCascMulti =
                    SelectMenu.Multiple (List.filter ((/=) key) (valueKeys model.specCascMulti))
            }

        SpecCascMenuToggled key ->
            -- the columns menu stays mounted (open specimen): a branch click
            -- retargets the hover column, a leaf click commits the checkmark
            if cascIsLeaf key then
                { model
                    | specCascMenu =
                        Cascader.toggleValue True Cascader.All model.specCascMenu key cascOptions
                }

            else
                { model | specCascMenuHover = Just key }

        SpecCascChildPicked key ->
            { model
                | specCascChild =
                    Cascader.toggleValue True Cascader.Child model.specCascChild key cascOptions
            }

        SpecCascFlatToggled key ->
            -- the flat menu's row activation: membership flip on the raw list
            { model
                | specCascFlat =
                    case model.specCascFlat of
                        SelectMenu.Multiple keys ->
                            if List.member key keys then
                                SelectMenu.Multiple (List.filter ((/=) key) keys)

                            else
                                SelectMenu.Multiple (keys ++ [ key ])

                        single ->
                            single
            }

        SpecTsNodeClicked row key ->
            let
                cfg =
                    tsSpecCfg row

                opts =
                    { tsD
                        | options = tsStaticData
                        , multiple = cfg.multiple
                        , checkable = cfg.checkable
                        , cascade = cfg.cascade
                    }
            in
            case row of
                TsSingleRow ->
                    { model
                        | specTsSingle = TreeSelect.handleNodeClick opts model.specTsSingle key
                        , specTsSinglePending = Just key
                    }

                TsMultiRow ->
                    { model | specTsMulti = TreeSelect.handleNodeClick opts model.specTsMulti key }

                TsFilterRow ->
                    { model | specTsFilter = TreeSelect.handleNodeClick opts model.specTsFilter key }

        SpecAcBasicTyped text ->
            { model | specAcBasic = text }

        SpecAcBasicPicked key ->
            { model | specAcBasic = Maybe.withDefault key (selectLabel key songOptions) }

        SpecAcGroupTyped text ->
            { model | specAcGroup = text }

        SpecAcGroupPicked key ->
            { model | specAcGroup = Maybe.withDefault key (selectLabel key selectOptions) }

        SpecAcClearableTyped text ->
            { model | specAcClearable = text }

        SpecAcCustomPicked key ->
            -- the label commit for the custom-row menu's plain leaf
            { model | specAcBasic = key }

        SpecMnBasicTyped text ->
            { model | specMnBasic = text }

        SpecMnBasicPicked value ->
            { model | specMnBasic = spliceMention model.specMnBasic value }

        SpecMnBasic2Typed text ->
            { model | specMnBasic2 = text }

        SpecMnTextareaTyped text ->
            { model | specMnTextarea = text }

        SpecMnAutosizeTyped text ->
            { model | specMnAutosize = text }

        SpecMnGroupTagTyped text ->
            { model | specMnGroupTag = text }

        SpecMnGroupTagPicked value ->
            { model | specMnGroupTag = spliceTag model.specMnGroupTag value }

        SpecMnGroupUserTyped text ->
            { model | specMnGroupUser = text }

        SpecMnGroupUserPicked value ->
            { model | specMnGroupUser = spliceMention model.specMnGroupUser value }

        SpecMnGroup2Typed text ->
            { model | specMnGroup2 = text }

        SpecMnGroup2Picked value ->
            { model | specMnGroup2 = spliceMention model.specMnGroup2 value }

        SpecDpFocused row ->
            specDpUpd row (\st -> { st | open = True }) model

        SpecDpValueSet row value ->
            -- single/range shape guard: a range panel never stores a single
            -- value and vice versa (the shortcuts row mixes both shapes).
            -- Range commits come from the shortcut buttons (the only range
            -- commit channel — day clicks go through SpecDpDateClicked), and
            -- upstream's shortcut click commits AND closes.
            if DatePicker.isRangeType (specDpType row) then
                case value of
                    DatePicker.Range _ ->
                        specDpUpd
                            row
                            (\st ->
                                { st
                                    | value = value
                                    , monthPanel = False
                                    , selecting = False
                                    , open = st.open && not (specDpCloses row value)
                                }
                            )
                            model

                    _ ->
                        model

            else
                case value of
                    DatePicker.Single _ ->
                        specDpUpd
                            row
                            (\st ->
                                { st
                                    | value = value
                                    , open = st.open && not (specDpCloses row value)
                                    , monthPanel = False
                                }
                            )
                            model

                    _ ->
                        model

        SpecDpCleared row ->
            specDpUpd
                row
                (\st ->
                    { st
                        | value = specDpEmpty (specDpType row)
                        , open = False
                        , monthPanel = False
                        , selecting = False
                    }
                )
                model

        SpecDpConfirmed row ->
            specDpUpd
                row
                (\st ->
                    { st
                        | value = specDpSanitize (specDpType row) st.value
                        , open = False
                        , selecting = False
                        , monthPanel = False
                    }
                )
                model

        SpecDpCalendar row side anchor ->
            specDpUpd
                row
                (\st ->
                    case side of
                        DatePicker.CalStart ->
                            { st | startCalendarValue = Just anchor }

                        DatePicker.CalEnd ->
                            { st | endCalendarValue = Just anchor }
                )
                model

        SpecDpMonthToggled row open ->
            specDpUpd row (\st -> { st | monthPanel = open }) model

        SpecDpDateClicked row ts ->
            specDpUpd
                row
                (\st ->
                    let
                        result =
                            DatePicker.dualDateClick
                                { value = st.value
                                , selecting = st.selecting
                                , type_ = specDpType row
                                , closeOnSelect = False
                                , updateValueOnClose = False
                                }
                                ts
                    in
                    { st
                        | value = result.value
                        , selecting = result.selecting
                        , open = st.open && not result.close
                    }
                )
                model

        SpecDpHovered row ts ->
            specDpUpd
                row
                (\st ->
                    case
                        DatePicker.dualHover
                            { value = st.value
                            , selecting = st.selecting
                            , memorizedStart = Nothing
                            , disabled = False
                            }
                            ts
                    of
                        Just value ->
                            { st | value = value }

                        Nothing ->
                            st
                )
                model

        SpecDpMonthItem row ts pos ->
            specDpUpd
                row
                (\st -> { st | value = DatePicker.colItemClick (specDpType row) st.value ts pos })
                model

        SpecTpFocused row ->
            specTpUpd row (\st -> { st | open = True }) model

        SpecTpValueSet row value ->
            -- column item clicks (and Now) keep the panel open
            specTpUpd row (\st -> { st | value = value }) model

        SpecTpConfirmed row ->
            specTpUpd row (\st -> { st | open = False }) model

        SpecTpCleared row ->
            specTpUpd row (\st -> { st | value = Nothing }) model

        SpecCpOpened row ->
            -- the trigger's onUpdateShow: reopen (one live value — nothing
            -- to re-sync)
            specCpUpd row (\st -> { st | open = True }) model

        SpecCpValueUpdated row value ->
            -- upstream doUpdateValue 'input' (swatch click): live commit;
            -- swatches ALSO run onComplete (pushes the stack) — same as the
            -- live row
            specCpUpd
                row
                (\st -> { st | value = value, undo = st.value :: st.undo, redo = [] })
                model

        SpecCpModeChanged row mode ->
            specCpUpd row (\st -> { st | mode = mode }) model

        SpecCpConfirmed row _ ->
            -- upstream handleConfirm: the value is already live-committed
            -- (no stack push, no value change) — the panel just closes and
            -- the stack resets (watch mergedShowRef)
            specCpUpd row (\st -> { st | open = False, undo = [], redo = [] }) model

        SpecCpCleared row ->
            -- upstream handleClear: null value + close; the stack resets on
            -- close (watch mergedShowRef)
            specCpUpd
                row
                (\st -> { st | value = Nothing, open = False, undo = [], redo = [] })
                model

        SpecCpUndone row ->
            specCpUpd
                row
                (\st ->
                    case st.undo of
                        prev :: rest ->
                            { st
                                | value = prev
                                , undo = rest
                                , redo = st.value :: st.redo
                            }

                        [] ->
                            st
                )
                model

        SpecCpRedone row ->
            specCpUpd
                row
                (\st ->
                    case st.redo of
                        next :: rest ->
                            { st
                                | value = next
                                , redo = rest
                                , undo = st.value :: st.undo
                            }

                        [] ->
                            st
                )
                model

        SpecCpUnitTyped row index raw ->
            -- same normalize-commit algebra as the live row's CpUnitTyped,
            -- against the row's own value/mode (complete parse commits the
            -- value + pushes the stack, incomplete keeps the raw text)
            specCpUpd
                row
                (\st ->
                    case specCpUnitParse st index raw of
                        Just value ->
                            { st | value = Just value, unitText = Nothing, undo = st.value :: st.undo, redo = [] }

                        Nothing ->
                            { st | unitText = Just raw }
                )
                model

        SpecCpDragStarted row inst press ->
            -- the spec row's press: same same-tick click-commits semantics
            -- as the live row, against the row's own draft
            { model
                | cpDrag =
                    Just
                        { area = press.area
                        , site = CpSpecSite row
                        , rect = cpPressRect press
                        }
                , cpDragOrigin = Just ( CpSpecSite row, (specCpGet row model).value )
            }
                |> cpDragApplyPress press


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


{-| `Just x` conses, `Nothing` passes the list through (the drag-origin
unset case — no drag ran, nothing to push).
-}
maybeCons : Maybe a -> List a -> List a
maybeCons maybeX xs =
    case maybeX of
        Just x ->
            x :: xs

        Nothing ->
            xs


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



-- COLORPICKER DRAG (live row + spec rows share one subscription pair)


{-| One live drag: which surface is dragged, whose value it commits (the
live row's model fields vs a spec row's state), and the dragged surface's
viewport rect — captured synchronously at press from the event itself, so
the whole drag is pure client − rect arithmetic (zero DOM reads).
-}
type alias CpDragCtx =
    { area : ColorPicker.PointerArea
    , site : CpDragSite
    , rect : { width : Float, height : Float, left : Float, bottom : Float }
    }


{-| The drag surface ids a drag is reading rects from, plus the site the
geometry commits to (the live row's model fields vs a spec row's state).
-}
type alias CpDragIds =
    { site : CpDragSite
    , palette : String
    , hue : String
    , alpha : String
    }


type CpDragSite
    = CpLiveSite
    | CpSpecSite SpecCpRow


{-| The live row's ids (its panel's `pointerAreaIds` seam).
-}
cpLiveIds : CpDragIds
cpLiveIds =
    { site = CpLiveSite
    , palette = "live-cp-palette"
    , hue = "live-cp-hue"
    , alpha = "live-cp-alpha"
    }


{-| The dragged surface's viewport rect, built from the press event itself:
`left`/`top` are `clientX/Y − offsetX/Y` (same-tick `getBoundingClientRect`
origin), `width`/`height` are the surface's `clientWidth/Height`. The
rect's `bottom` (viewport-space y of the surface's bottom edge) is what
`svFromPoint` measures brightness against.
-}
cpPressRect :
    ColorPicker.PointerPress
    -> { width : Float, height : Float, left : Float, bottom : Float }
cpPressRect press =
    { width = toFloat press.width
    , height = toFloat press.height
    , left = press.left
    , bottom = press.top + toFloat press.height
    }


{-| The press's immediate geometry commit — upstream
`handleMouseDown → handleMouseMove(e)` in the same tick. Takes the ctx the
`CpDragStarted` branch just built (rect + site), commits the pressed colour
purely, and hands back the model with the drag running.
-}
cpDragApplyPress :
    ColorPicker.PointerPress
    -> Model
    -> Model
cpDragApplyPress press model =
    case model.cpDrag of
        Just ctx ->
            cpDragApply
                ctx.area
                ctx.site
                (round press.left + press.x)
                (round press.top + press.y)
                ctx.rect
                model

        Nothing ->
            model


{-| The geometry commit: `svFromPoint` / `hueFromPoint` / `alphaFromPoint`
against the press-cached (viewport-space) rect, converted into the displayed
mode. Pointer coordinates and the cached rect are both viewport-relative,
so the per-frame move path is pure client − rect arithmetic.
-}
cpDragApply :
    ColorPicker.PointerArea
    -> CpDragSite
    -> Int
    -> Int
    -> { width : Float, height : Float, left : Float, bottom : Float }
    -> Model
    -> Model
cpDragApply area site x y rect model =
    case site of
        CpLiveSite ->
            -- upstream doUpdateValue 'cursor': ONE live value —
            -- cpValue and cpDraft move together every mousemove
            -- (the trigger shows the changing colour while dragging)
            { model
                | cpValue = cpDragValue area x y rect model.cpDraft model.cpMode
                , cpDraft = cpDragValue area x y rect model.cpDraft model.cpMode
                , cpUnitText = Nothing
            }

        CpSpecSite row ->
            -- the same ONE-live-value commit as the live site: st.value
            -- moves every frame, so the trigger tracks while dragging
            specCpUpd
                row
                (\st ->
                    { st
                        | value = cpDragValue area x y rect st.value st.mode
                        , unitText = Nothing
                    }
                )
                model


{-| The shared geometry commit — `svFromPoint` / `hueFromPoint` /
`alphaFromPoint` against the (press-cached) rect, converted into the
displayed mode. Pure over (draft, mode), so the live row and the spec rows
run the same algebra (the site routing happens in `cpDragApply`).
-}
cpDragValue :
    ColorPicker.PointerArea
    -> Int
    -> Int
    -> { width : Float, height : Float, left : Float, bottom : Float }
    -> Maybe String
    -> ColorPicker.Mode
    -> Maybe String
cpDragValue area x y rect draft mode =
    case area of
        ColorPicker.PaletteArea ->
            let
                { s, v } =
                    ColorPicker.svFromPoint rect { x = toFloat x, y = toFloat y }

                base =
                    Maybe.withDefault { h = 0, s = 100, v = 100 } (Color.hsvaOf draft |> Maybe.map (\c -> { h = c.h, s = c.s, v = c.v }))

                alpha =
                    Maybe.map .a (Color.hsvaOf draft) |> Maybe.withDefault 1
            in
            ColorPicker.convertColor
                (Color.toHsvaString (Color.hsvWithAlpha alpha { s = s, v = v, h = base.h }))
                mode
                (ColorPicker.getModeFromValue draft)

        ColorPicker.HueArea ->
            let
                hue =
                    ColorPicker.hueFromPoint { width = rect.width, left = rect.left } (toFloat x)

                base =
                    Maybe.withDefault { h = toFloat hue, s = 100, v = 100 } (Color.hsvaOf draft |> Maybe.map (\c -> { h = c.h, s = c.s, v = c.v }))

                alpha =
                    Maybe.map .a (Color.hsvaOf draft) |> Maybe.withDefault 1
            in
            ColorPicker.convertColor
                (Color.toHsvaString (Color.hsvWithAlpha alpha { base | h = toFloat hue }))
                mode
                (ColorPicker.getModeFromValue draft)

        ColorPicker.AlphaArea ->
            let
                a =
                    ColorPicker.alphaFromPoint { width = rect.width, left = rect.left } (toFloat x)

                base =
                    Color.hsvaOf draft |> Maybe.withDefault (Color.hsvWithAlpha 1 { h = 0, s = 100, v = 100 })
            in
            ColorPicker.convertColor
                (Color.toHsvaString { base | a = a })
                mode
                (ColorPicker.getModeFromValue draft)


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
            -- upstream 'input' commit + handleComplete: live value + stack
            -- push (complete parse = one committed change)
            { model
                | cpValue = Just value
                , cpDraft = Just value
                , cpUndo = model.cpValue :: model.cpUndo
                , cpRedo = []
                , cpUnitText = Nothing
            }

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



-- SPEC-ROW UNIT TYPING (the live row's algebra, against a SpecCpState)


{-| The live row's `cpUnitTyped` parse, re-run against a spec row's own
draft/mode (the record shape is the only difference — the normalizers and
the convert-into-displayed-mode flow are identical).
-}
specCpUnitParse : SpecCpState -> Int -> String -> Maybe String
specCpUnitParse st index raw =
    case st.mode of
        ColorPicker.Hex ->
            if ColorPicker.normalizeHexaUnit raw then
                ColorPicker.convertColor (String.toUpper raw) st.mode Nothing

            else
                Nothing

        _ ->
            let
                labels =
                    specCpUnitLabels st

                label =
                    List.head (List.drop index labels)

                baseHSV =
                    Maybe.withDefault (Color.hsvWithAlpha 1 { h = 0, s = 100, v = 100 }) (Color.hsvaOf st.value)

                alpha =
                    Maybe.map .a (Color.hsvaOf st.value) |> Maybe.withDefault 1
            in
            case label of
                Just "A" ->
                    ColorPicker.normalizeAlphaUnit raw
                        |> Maybe.andThen (\a -> ColorPicker.convertColor (Color.toHsvaString { baseHSV | a = a }) st.mode Nothing)

                Just "H" ->
                    ColorPicker.normalizeHueUnit raw
                        |> Maybe.andThen (\h -> ColorPicker.convertColor (Color.toHsvaString (Color.hsvWithAlpha alpha { h = toFloat h, s = baseHSV.s, v = baseHSV.v })) st.mode Nothing)

                Just "S" ->
                    ColorPicker.normalizeSlvUnit raw
                        |> Maybe.andThen (\s -> ColorPicker.convertColor (Color.toHsvaString (Color.hsvWithAlpha alpha { h = baseHSV.h, s = toFloat s, v = baseHSV.v })) st.mode Nothing)

                Just "V" ->
                    ColorPicker.normalizeSlvUnit raw
                        |> Maybe.andThen (\v -> ColorPicker.convertColor (Color.toHsvaString (Color.hsvWithAlpha alpha { h = baseHSV.h, s = baseHSV.s, v = toFloat v })) st.mode Nothing)

                Just "R" ->
                    specChannelSet st (\c -> { c | r = channel raw })

                Just "G" ->
                    specChannelSet st (\c -> { c | g = channel raw })

                Just "B" ->
                    specChannelSet st (\c -> { c | b = channel raw })

                Just "L" ->
                    ColorPicker.normalizeSlvUnit raw
                        |> Maybe.andThen
                            (\l ->
                                Maybe.map
                                    (\c ->
                                        ColorPicker.convertColor
                                            (Color.toHslaString { c | l = toFloat l })
                                            st.mode
                                            Nothing
                                            |> Maybe.withDefault ""
                                    )
                                    (Color.hslaOf st.value)
                            )

                _ ->
                    Nothing


specCpUnitLabels : SpecCpState -> List String
specCpUnitLabels st =
    let
        base =
            case st.mode of
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


specChannelSet : SpecCpState -> (Color.RGBA -> Color.RGBA) -> Maybe String
specChannelSet st set =
    Maybe.map
        (\c ->
            ColorPicker.convertColor
                (Color.toRgbaString (set c))
                st.mode
                Nothing
                |> Maybe.withDefault ""
        )
        (Color.rgbaOf st.value)



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
                , chip ("value: " ++ cpHexText model.cpValue)
                , chip ("undo " ++ String.fromInt (List.length model.cpUndo) ++ "/" ++ String.fromInt (List.length model.cpRedo) ++ " redo")
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
        , onUpdateShow =
            Just
                (\open ->
                    if open then
                        CpOpened

                    else
                        CpClosed
                )
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
                { palette = cpLiveIds.palette
                , hue = cpLiveIds.hue
                , alpha = cpLiveIds.alpha
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



-- PHASE-2 SPEC ROW STATE (DatePicker / TimePicker / ColorPicker / TreeSelect)
--
-- One state record per wired static row, initialised to the row's CURRENT
-- literals (the panels render OPEN at init — the open-specimen exception in
-- the brief). The update branches above drive them through these row-tagged
-- helpers; the rows below render value/open straight out of the state, so a
-- commit/clear/confirm closes the panel (it unmounts) and the trigger's
-- focus/click reopens it. `show` stays False on the trigger options on
-- purpose: it only feeds the input's `n-input--focus` class, which the
-- static specimens never carried (byte-identical initial DOM).


type SpecDpRow
    = DpDateRow
    | DpDatetimeRow
    | DpDaterangeRow
    | DpDatetimerangeRow
    | DpMonthRow
    | DpYearRow
    | DpQuarterRow
    | DpMonthrangeRow
    | DpWeekRow
    | DpShortcutsRow


type alias SpecDpState =
    { open : Bool
    , value : DatePicker.Value
    , startCalendarValue : Maybe Int
    , endCalendarValue : Maybe Int
    , monthPanel : Bool
    , selecting : Bool
    }


type alias SpecDpStates =
    { date : SpecDpState
    , datetime : SpecDpState
    , daterange : SpecDpState
    , datetimerange : SpecDpState
    , month : SpecDpState
    , year : SpecDpState
    , quarter : SpecDpState
    , monthrange : SpecDpState
    , week : SpecDpState
    , shortcuts : SpecDpState
    }


{-| The `Datetime` row's literal (1715770440000 ms — the static row's `dt`).
-}
dtMs : Int
dtMs =
    1715770440000


specDpSingleInit : Int -> SpecDpState
specDpSingleInit ts =
    { open = True
    , value = DatePicker.Single (Just ts)
    , startCalendarValue = Nothing
    , endCalendarValue = Nothing
    , monthPanel = False
    , selecting = False
    }


specDpRangeInit : SpecDpState
specDpRangeInit =
    { open = True
    , value = DatePicker.Range (Just ( may10, may20 ))
    , startCalendarValue = Just may10
    , endCalendarValue = Just may20
    , monthPanel = False
    , selecting = False
    }


specDpInit : SpecDpStates
specDpInit =
    { date = specDpSingleInit dpNowMs
    , datetime = specDpSingleInit dtMs
    , daterange = specDpRangeInit
    , datetimerange = specDpRangeInit
    , month = specDpSingleInit dpNowMs
    , year = specDpSingleInit dpNowMs
    , quarter = specDpSingleInit dpNowMs
    , monthrange = specDpRangeInit
    , week = specDpSingleInit dpNowMs
    , shortcuts = specDpRangeInit
    }


specDpType : SpecDpRow -> DatePicker.PanelType
specDpType row =
    case row of
        DpDateRow ->
            DatePicker.Date

        DpDatetimeRow ->
            DatePicker.Datetime

        DpDaterangeRow ->
            DatePicker.Daterange

        DpDatetimerangeRow ->
            DatePicker.Datetimerange

        DpMonthRow ->
            DatePicker.Month

        DpYearRow ->
            DatePicker.Year

        DpQuarterRow ->
            DatePicker.Quarter

        DpMonthrangeRow ->
            DatePicker.Monthrange

        DpWeekRow ->
            DatePicker.Week

        DpShortcutsRow ->
            DatePicker.Daterange


{-| Upstream `emptyValue`: range panels clear to `Range Nothing`, singles to
`Single Nothing`.
-}
specDpEmpty : DatePicker.PanelType -> DatePicker.Value
specDpEmpty type_ =
    if DatePicker.isRangeType type_ then
        DatePicker.Range Nothing

    else
        DatePicker.Single Nothing


{-| Confirm sanitizes both ends of a range (datetimerange → second,
monthrange → month, else day) / the single timestamp — the same per-type
`sanitizeValue` the live rows run on confirm.
-}
specDpSanitize : DatePicker.PanelType -> DatePicker.Value -> DatePicker.Value
specDpSanitize type_ value =
    case value of
        DatePicker.Range (Just ( a, b )) ->
            DatePicker.Range
                (Just
                    ( DatePicker.sanitizeValue type_ a
                    , DatePicker.sanitizeValue type_ b
                    )
                )

        DatePicker.Single (Just ts) ->
            DatePicker.Single (Just (DatePicker.sanitizeValue type_ ts))

        _ ->
            value


{-| The close flag after a single-panel commit — `singleDateClick`'s own close
algebra, re-run against the committed timestamp (the live `dpSingleCloses`
construction; the oracle-D note above covers why the re-derivation is sound).
Range panels never close on a cell commit.
-}
specDpCloses : SpecDpRow -> DatePicker.Value -> Bool
specDpCloses row value =
    if DatePicker.isRangeType (specDpType row) then
        -- range panels close only on the shortcut-commit channel (the
        -- SpecDpValueSet range arm — day clicks route to SpecDpDateClicked,
        -- whose own close flag governs there)
        row == DpShortcutsRow

    else
        case value of
            DatePicker.Single (Just ts) ->
                .close
                    (DatePicker.singleDateClick
                        { type_ = specDpType row
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


specDpGet : SpecDpRow -> Model -> SpecDpState
specDpGet row model =
    case row of
        DpDateRow ->
            model.specDp.date

        DpDatetimeRow ->
            model.specDp.datetime

        DpDaterangeRow ->
            model.specDp.daterange

        DpDatetimerangeRow ->
            model.specDp.datetimerange

        DpMonthRow ->
            model.specDp.month

        DpYearRow ->
            model.specDp.year

        DpQuarterRow ->
            model.specDp.quarter

        DpMonthrangeRow ->
            model.specDp.monthrange

        DpWeekRow ->
            model.specDp.week

        DpShortcutsRow ->
            model.specDp.shortcuts


specDpSet : SpecDpRow -> SpecDpState -> SpecDpStates -> SpecDpStates
specDpSet row st states =
    case row of
        DpDateRow ->
            { states | date = st }

        DpDatetimeRow ->
            { states | datetime = st }

        DpDaterangeRow ->
            { states | daterange = st }

        DpDatetimerangeRow ->
            { states | datetimerange = st }

        DpMonthRow ->
            { states | month = st }

        DpYearRow ->
            { states | year = st }

        DpQuarterRow ->
            { states | quarter = st }

        DpMonthrangeRow ->
            { states | monthrange = st }

        DpWeekRow ->
            { states | week = st }

        DpShortcutsRow ->
            { states | shortcuts = st }


specDpUpd : SpecDpRow -> (SpecDpState -> SpecDpState) -> Model -> Model
specDpUpd row f model =
    { model | specDp = specDpSet row (f (specDpGet row model)) model.specDp }


{-| One wired static row's options: the row's own literals (type, `now`,
range anchors) with every channel the panel/trigger afford. `show` stays
False (byte-parity — see the section comment); the panel mounts on `open`.
-}
specDpOpts : SpecDpRow -> Model -> DatePicker.Options Msg
specDpOpts row model =
    let
        st =
            specDpGet row model
    in
    { dpD
        | value = st.value
        , type_ = specDpType row
        , show = False
        , now = dpNow
        , calendarValue = st.startCalendarValue
        , startCalendarValue = st.startCalendarValue
        , endCalendarValue = st.endCalendarValue
        , monthPanelShow = st.monthPanel
        , selecting = st.selecting
        , onFocus = Just (SpecDpFocused row)
        , onClear = Just (SpecDpCleared row)
        , onConfirm = Just (SpecDpConfirmed row)
        , onUpdateValue = Just (SpecDpValueSet row)
        , onDateClick = Just (SpecDpDateClicked row)
        , onDateEnter = Just (SpecDpHovered row)
        , onMonthItemClick = Just (SpecDpMonthItem row)
        , onUpdateCalendarValue = Just (SpecDpCalendar row)
        , onUpdateMonthPanelShow = Just (SpecDpMonthToggled row)
    }
        |> specDpRowOpts row


{-| The per-row literal extras the static rows carried beyond the base.
-}
specDpRowOpts : SpecDpRow -> DatePicker.Options Msg -> DatePicker.Options Msg
specDpRowOpts row opts =
    case row of
        DpYearRow ->
            { opts | yearRange = ( 2015, 2035 ) }

        DpShortcutsRow ->
            { opts
                | clearable = True
                , shortcuts =
                    [ ( "This week", DatePicker.ShortcutRange ( may10, may20 ) )
                    , ( "Today", DatePicker.ShortcutSingle dpNowMs )
                    ]
            }

        _ ->
            opts


{-| The wired static pair: trigger always renders, the panel while `open`
(init True — the open specimen; commit/clear/confirm closes it).
-}
specDpPair : SpecDpRow -> Model -> Element Msg
specDpPair row model =
    Element.column [ Element.spacing 12, Element.width Element.fill ]
        [ DatePicker.view theme (specDpOpts row model)
        , if (specDpGet row model).open then
            DatePicker.panel theme (specDpOpts row model)

          else
            Element.none
        ]


type SpecTpRow
    = TpBasicRow
    | TpHmRow
    | Tp12Row
    | TpActionsRow
    | TpDisabledRow


type alias SpecTpState =
    { open : Bool
    , value : Maybe Int
    }


type alias SpecTpStates =
    { basic : SpecTpState
    , hm : SpecTpState
    , twelve : SpecTpState
    , actions : SpecTpState
    , disabled : SpecTpState
    }


specTpRowInit : SpecTpState
specTpRowInit =
    { open = True
    , value = Just tenToFiftyFour
    }


specTpInit : SpecTpStates
specTpInit =
    { basic = specTpRowInit
    , hm = specTpRowInit
    , twelve = specTpRowInit
    , actions = specTpRowInit
    , disabled = specTpRowInit
    }


specTpGet : SpecTpRow -> Model -> SpecTpState
specTpGet row model =
    case row of
        TpBasicRow ->
            model.specTp.basic

        TpHmRow ->
            model.specTp.hm

        Tp12Row ->
            model.specTp.twelve

        TpActionsRow ->
            model.specTp.actions

        TpDisabledRow ->
            model.specTp.disabled


specTpSet : SpecTpRow -> SpecTpState -> SpecTpStates -> SpecTpStates
specTpSet row st states =
    case row of
        TpBasicRow ->
            { states | basic = st }

        TpHmRow ->
            { states | hm = st }

        Tp12Row ->
            { states | twelve = st }

        TpActionsRow ->
            { states | actions = st }

        TpDisabledRow ->
            { states | disabled = st }


specTpUpd : SpecTpRow -> (SpecTpState -> SpecTpState) -> Model -> Model
specTpUpd row f model =
    { model | specTp = specTpSet row (f (specTpGet row model)) model.specTp }


specTpOpts : SpecTpRow -> Model -> TimePicker.Options Msg
specTpOpts row model =
    let
        st =
            specTpGet row model
    in
    { tpD
        | value = st.value
        , show = False
        , now = dpNow
        , onFocus = Just (SpecTpFocused row)
        , onClear = Just (SpecTpCleared row)
        , onConfirm = Just (SpecTpConfirmed row)
        , onUpdateValue = Just (SpecTpValueSet row)
    }
        |> specTpRowOpts row


specTpRowOpts : SpecTpRow -> TimePicker.Options Msg -> TimePicker.Options Msg
specTpRowOpts row opts =
    case row of
        TpHmRow ->
            { opts | format = "HH:mm" }

        Tp12Row ->
            { opts | use12Hours = True, format = "hh:mm:ss a" }

        TpActionsRow ->
            { opts
                | clearable = True
                , actions = [ TimePicker.Clear, TimePicker.Now, TimePicker.Confirm ]
            }

        TpDisabledRow ->
            { opts
                | minutes = TimePicker.StepUnits 5
                , seconds = TimePicker.OnlyUnits [ 0, 30 ]
                , isHourDisabled = Just (\h -> h > 12)
            }

        _ ->
            opts


specTpPair : SpecTpRow -> Model -> Element Msg
specTpPair row model =
    Element.column [ Element.spacing 8 ]
        [ TimePicker.view theme (specTpOpts row model)
        , Element.el [ Element.width (Element.px 200) ]
            (if (specTpGet row model).open then
                TimePicker.panel theme (specTpOpts row model)

             else
                Element.none
            )
        ]


type SpecCpRow
    = CpBasicRow
    | CpAlphaRow
    | CpSizesRow
    | CpSwatchesRow
    | CpClearRow
    | CpPreviewRow
    | CpUndoRow
    | CpSingleModeRow


type alias SpecCpState =
    { open : Bool
    , value : Maybe String
    , mode : ColorPicker.Mode
    , undo : List (Maybe String)
    , redo : List (Maybe String)
    , unitText : Maybe String
    }


type alias SpecCpStates =
    { basic : SpecCpState
    , alpha : SpecCpState
    , sizes : SpecCpState
    , swatches : SpecCpState
    , clear : SpecCpState
    , preview : SpecCpState
    , undo : SpecCpState
    , singleMode : SpecCpState
    }


{-| The static rows' shared colour literal (each row's `red`).
-}
specCpRed : String
specCpRed =
    "#d03050"


{-| `displayedMode` inits to the Options default (`Rgb`) — the literal the
static panels rendered (the RGBA unit row), NOT the value's own hex mode.
The undo row seeds its stack so `undoable` starts True exactly as its pinned
literal did, while Undo/Redo clicks have real stack semantics.
-}
specCpRowInit : List (Maybe String) -> SpecCpState
specCpRowInit undo =
    { open = True
    , value = Just specCpRed
    , mode = ColorPicker.Rgb
    , undo = undo
    , redo = []
    , unitText = Nothing
    }


specCpInit : SpecCpStates
specCpInit =
    { basic = specCpRowInit []
    , alpha = specCpRowInit []
    , sizes = specCpRowInit []
    , swatches = specCpRowInit []
    , clear = specCpRowInit []
    , preview = specCpRowInit []
    , undo = specCpRowInit [ Just specCpRed ]
    , singleMode = { open = True, value = Just specCpRed, mode = ColorPicker.Hex, undo = [], redo = [], unitText = Nothing }
    }


specCpGet : SpecCpRow -> Model -> SpecCpState
specCpGet row model =
    case row of
        CpBasicRow ->
            model.specCp.basic

        CpAlphaRow ->
            model.specCp.alpha

        CpSizesRow ->
            model.specCp.sizes

        CpSwatchesRow ->
            model.specCp.swatches

        CpClearRow ->
            model.specCp.clear

        CpPreviewRow ->
            model.specCp.preview

        CpUndoRow ->
            model.specCp.undo

        CpSingleModeRow ->
            model.specCp.singleMode


specCpSet : SpecCpRow -> SpecCpState -> SpecCpStates -> SpecCpStates
specCpSet row st states =
    case row of
        CpBasicRow ->
            { states | basic = st }

        CpAlphaRow ->
            { states | alpha = st }

        CpSizesRow ->
            { states | sizes = st }

        CpSwatchesRow ->
            { states | swatches = st }

        CpClearRow ->
            { states | clear = st }

        CpPreviewRow ->
            { states | preview = st }

        CpUndoRow ->
            { states | undo = st }

        CpSingleModeRow ->
            { states | singleMode = st }


specCpUpd : SpecCpRow -> (SpecCpState -> SpecCpState) -> Model -> Model
specCpUpd row f model =
    { model | specCp = specCpSet row (f (specCpGet row model)) model.specCp }


{-| The shared literal base (value/mode + the per-row extras) — ONE live
value feeds both roots (the trigger's colour/label and the panel track per
commit, upstream's single `mergedValue`).
-}
specCpBase : SpecCpRow -> Model -> ColorPicker.Options Msg
specCpBase row model =
    let
        st =
            specCpGet row model
    in
    { cpD
        | value = st.value
        , displayedMode = st.mode
        , onUpdateShow = Just (\_ -> SpecCpOpened row)
    }
        |> specCpRowOpts row


specCpRowOpts : SpecCpRow -> ColorPicker.Options Msg -> ColorPicker.Options Msg
specCpRowOpts row opts =
    case row of
        CpAlphaRow ->
            { opts | showAlpha = False, actions = Just [ ColorPicker.ConfirmAction ] }

        CpSwatchesRow ->
            { opts
                | swatches =
                    [ "#000000", "#ffffff", specCpRed, "rgba(208, 48, 80, 1)", "#0f0" ]
            }

        CpClearRow ->
            { opts | actions = Just [ ColorPicker.ClearAction ] }

        CpPreviewRow ->
            { opts | showPreview = True }

        CpUndoRow ->
            { opts
                | internalActions = Just [ ColorPicker.UndoAction, ColorPicker.RedoAction ]
            }

        CpBasicRow ->
            opts

        CpSizesRow ->
            opts

        CpSingleModeRow ->
            -- the pinned single-mode showcase: `modes = [ Hex ]` makes the
            -- mode button render hex-only (no switch away possible), so the
            -- pin IS the options — the row still wires drag/swatches/undo
            { opts | modes = [ ColorPicker.Hex ], displayedMode = ColorPicker.Hex }


specCpTriggerOpts : SpecCpRow -> Model -> ColorPicker.Options Msg
specCpTriggerOpts row model =
    specCpBase row model


{-| A row instance's drag-surface ids — static per (row, instance) so the
Sizes row's three instances each read their own rect (a shared id would
route every drag to the first instance's surfaces).
-}
specCpAreaIds : SpecCpRow -> Int -> CpDragIds
specCpAreaIds row inst =
    let
        tag =
            case row of
                CpBasicRow ->
                    "basic"

                CpAlphaRow ->
                    "alpha"

                CpSizesRow ->
                    "sizes"

                CpSwatchesRow ->
                    "swatches"

                CpClearRow ->
                    "clear"

                CpPreviewRow ->
                    "preview"

                CpUndoRow ->
                    "undo"

                CpSingleModeRow ->
                    "single"
    in
    { site = CpSpecSite row
    , palette = "spec-cp-" ++ tag ++ "-" ++ String.fromInt inst ++ "-palette"
    , hue = "spec-cp-" ++ tag ++ "-" ++ String.fromInt inst ++ "-hue"
    , alpha = "spec-cp-" ++ tag ++ "-" ++ String.fromInt inst ++ "-alpha"
    }


specCpPanelOpts : SpecCpRow -> Model -> ColorPicker.Options Msg
specCpPanelOpts row model =
    let
        st =
            specCpGet row model

        base =
            specCpBase row model
    in
    { base
        | undoable = not (List.isEmpty st.undo)
        , redoable = not (List.isEmpty st.redo)
        , onUnitInput = Just (\i raw -> SpecCpUnitTyped row i raw)
        , onUpdateValue = Just (SpecCpValueUpdated row)
        , onUpdateMode = Just (SpecCpModeChanged row)
        , onConfirm = Just (SpecCpConfirmed row)
        , onClear = Just (SpecCpCleared row)
        , onUndo = Just (SpecCpUndone row)
        , onRedo = Just (SpecCpRedone row)
    }


{-| The per-instance panel options — the shared row options plus the
instance's drag seams (`pointerAreaIds` so its surfaces carry ids,
`onMousedown` so a drag start records which instance's ids to read).
-}
specCpPairOpts : SpecCpRow -> Int -> Model -> ColorPicker.Options Msg
specCpPairOpts row inst model =
    let
        base =
            specCpPanelOpts row model

        ids =
            specCpAreaIds row inst
    in
    { base
        | pointerAreaIds =
            Just
                { palette = ids.palette
                , hue = ids.hue
                , alpha = ids.alpha
                }
        , onMousedown = Just (SpecCpDragStarted row inst)
    }


{-| The wired static pair — `extras` applies the per-instance literal (the
Sizes row's Small/Medium/Large) to BOTH roots, exactly as the inline literal
set did.
-}
specCpPair :
    SpecCpRow
    -> Int
    -> Model
    -> (ColorPicker.Options Msg -> ColorPicker.Options Msg)
    -> Element Msg
specCpPair row inst model extras =
    Element.column [ Element.spacing 8, Element.width (Element.px 240) ]
        [ ColorPicker.view theme (extras (specCpTriggerOpts row model))
        , Element.el [ Element.width (Element.px 240) ]
            (if (specCpGet row model).open then
                ColorPicker.panel theme
                    (extras
                        (specCpUnitTextEcho (specCpGet row model)
                            (specCpPairOpts row inst model)
                        )
                    )

             else
                Element.none
            )
        ]


{-| The `unitText` echo — an incomplete unit parse keeps the raw string in
the row state and shows it in the panel's value slot (the live row's
`cpUnitText` split: a complete parse commits the draft, an incomplete one
never touches it).
-}
specCpUnitTextEcho : SpecCpState -> ColorPicker.Options msg -> ColorPicker.Options msg
specCpUnitTextEcho st opts =
    case st.unitText of
        Just _ ->
            { opts | value = st.unitText }

        Nothing ->
            opts



-- PHASE-2 SPEC ROW STATE (TreeSelect)


type SpecTsRow
    = TsSingleRow
    | TsMultiRow
    | TsFilterRow


{-| The three wired rows' shared option shape (the view's `singleCfg` /
`multiCfg` / `filterCfg` — one source of truth for both sides).
-}
tsSpecCfg : SpecTsRow -> { multiple : Bool, checkable : Bool, cascade : Bool }
tsSpecCfg row =
    case row of
        TsSingleRow ->
            { multiple = False, checkable = False, cascade = False }

        TsMultiRow ->
            { multiple = True, checkable = True, cascade = True }

        TsFilterRow ->
            { multiple = False, checkable = False, cascade = False }


{-| The static rows' tree fixture (the `data` the rows built inline).
-}
tsStaticData : List (Tree.TreeOption Msg)
tsStaticData =
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
    in
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
    spliceRun '@' text value


{-| The tag cell's splice — same shape, the run marker is `#` (the caller
gates the prefix, the module scans the run it was handed).
-}
spliceTag : String -> String -> String
spliceTag text value =
    spliceRun '#' text value


spliceRun : Char -> String -> String -> String
spliceRun marker text value =
    case List.maximum (String.indexes (String.fromChar marker) text) of
        Nothing ->
            text

        Just at ->
            String.slice 0 at text ++ String.fromChar marker ++ value ++ " "


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
            (HA.style "background-color"
                -- css only knows rgb/hsl/hex — the drag path commits the
                -- displayed mode's format (upstream parity), which can be
                -- hsva(...) and would silently fail as a background
                (maybeColor
                    |> Color.hslaOf
                    |> Maybe.map Color.toHslaString
                    |> Maybe.withDefault "transparent"
                )
            )
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


selectRows : Model -> List (Element Msg)
selectRows model =
    [ demoRow "Single (leaves + group)"
        -- specimen: nothing to commit — no menu is mounted in this row and
        -- Select emits no channel without one (value is display-only here)
        [ Select.view theme
            { selectD | attributes = [ Element.width (Element.px 200) ] }
            selectOptions
        ]
    , demoRow "Selected + clearable (hover)"
        -- wired: clearable value with the clear × armed (onClear)
        [ Select.view theme
            { selectD
                | value = model.specSelClearable
                , clearable = True
                , hover = True
                , onClear = Just SpecSelCleared
                , attributes = [ Element.width (Element.px 200) ]
            }
            selectOptions
        ]
    , demoRow "Filterable (active, empty pattern)"
        -- specimen: the pinned active/filter state is the row's purpose (the
        -- pattern input drives the mounted-menu filtering, absent here)
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
        -- wired: tag × deletes from the value (onDeleteTag)
        [ Select.view theme
            { selectD
                | multiple = True
                , maxTagCount = Just 3
                , value = model.specSelMulti
                , onDeleteTag = Just SpecSelMultiTagDeleted
                , attributes = [ Element.width (Element.px 260) ]
            }
            letterOptions
        ]
    , demoRow "Multiple filterable (pattern)"
        -- wired: the pinned pattern stays, the tags still delete
        [ Select.view theme
            { selectD
                | multiple = True
                , filterable = True
                , active = True
                , pattern = "dri"
                , value = model.specSelMultiFilter
                , onDeleteTag = Just SpecSelMultiFilterTagDeleted
                , attributes = [ Element.width (Element.px 260) ]
            }
            selectOptions
        ]
    , demoRow "Sizes · status · disabled"
        -- specimen row (sizes/status/disabled are the showcase; the tags are
        -- not clearable and no menu is mounted)
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
        -- specimen: loading replaces the menu middle — nothing clickable
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
        -- wired: the open menu's options toggle the checkmark (onToggle)
        [ Select.menu theme
            { selMenuD
                | header = Just (Element.text "Header")
                , action = Just (Element.text "#action")
                , value = model.specSelMenu
                , onToggle = Just SpecSelMenuPicked
                , attributes = [ Element.width (Element.px 200) ]
            }
            selectOptions
        ]
    ]


selectLiveSection : Model -> Element Msg
selectLiveSection model =
    section "Select" selectDesc (selectRows model ++ [ selectSingleLiveRow model, selectMultipleLiveRow model ])


{-| The Popselect section description (shared by the static and live variants).
-}
popselectDesc : String
popselectDesc =
    "The popover-family body whose select-menu root is itself the popover-shared body (upstream `internalRenderBody` — the `Dropdown` path: no `n-popover` element, `--n-padding` zeroed, `--show-arrow` present unless `overlap` even with no arrow node). Selection is pure — `value` drives the per-option checkmarks, `toggleValue` computes the next value — while the caller owns the show state (`'hover'` trigger), positioning (default placement bottom) and the auto-close on single select. `NUI.SelectMenu` (the support module this composes) stands bare in the last row."


popselectRows : Model -> List (Element Msg)
popselectRows model =
    [ demoRow "Single (leaves + group)"
        -- wired (open specimen): value + onUpdateValue — a row click moves
        -- the checkmark in place
        [ popoverHost Popover.Bottom
            []
            (Popselect.view theme
                { popselectD
                    | width = Just "200px"
                    , value = model.specPopSingle
                    , onUpdateValue = Just SpecPopSinglePicked
                }
                popselectOptions
            )
        ]
    , demoRow "Multiple (--multiple marker)"
        -- wired (open specimen): same, multiple tags
        [ popoverHost Popover.Bottom
            []
            (Popselect.view theme
                { popselectD
                    | width = Just "200px"
                    , multiple = True
                    , value = model.specPopMulti
                    , onUpdateValue = Just SpecPopMultiPicked
                }
                popselectOptions
            )
        ]
    , demoRow "Bare NUI.SelectMenu (no popover classes)"
        -- wired (open specimen): the bare menu's rows toggle
        [ SelectMenu.view theme
            { selectMenuD
                | size = SelectMenu.Small
                , header = Just (Element.text "Header")
                , action = Just (Element.text "#action")
                , value = model.specPopSelectMenu
                , onToggle = Just SpecPopSelectMenuPicked
                , attributes = [ Element.width (Element.px 200) ]
            }
            popselectOptions
        ]
    ]


popselectLiveSection : Model -> Element Msg
popselectLiveSection model =
    section "Popselect" popselectDesc (popselectRows model ++ [ popselectLiveRow model ])


{-| The Cascader section description (shared by the static and live variants).
-}
cascaderDesc : String
cascaderDesc =
    "Naive UI's cascader — the `NUI.BaseSelection` trigger (the `NUI.Select` lane) plus the multi-column menu, both caller-mounted bodies (upstream opens each in its own follower): `Cascader.menu` for the columns (the hover key's path decides them, `menuModel`; option states come from the value's `All`-strategy normalization) and `Cascader.selectMenu` for the filterable flat body (`filterOptions`' path-label rows). `view` derives the display from `value` + the tree: the single path label (unknown keys show themselves), the multiple cascade-normalized tags with the numeric `maxTagCount` slice. The treemate cascade logic ships pure — `getCheckedKeys` / `check` / `uncheck` / `toggleValue`; the caller owns the show state, positioning, keyboard and remote loading (`loadingKeys`)."


cascaderRows : Model -> List (Element Msg)
cascaderRows model =
    [ demoRow "Single (path label) · multiple (maxTagCount)"
        -- wired: clearable single (onClear) + multiple tag delete (onDeleteTag)
        [ Cascader.view theme
            { cascaderD
                | value = model.specCascSingle
                , clearable = True
                , hover = True
                , onClear = Just SpecCascSingleCleared
                , attributes = [ Element.width (Element.px 280) ]
            }
            cascaderOptions
        , Cascader.view theme
            { cascaderD
                | multiple = True
                , maxTagCount = Just 2
                , value = model.specCascMulti
                , onDeleteTag = Just SpecCascMultiTagDeleted
                , attributes = [ Element.width (Element.px 320) ]
            }
            cascaderOptions
        ]
    , demoRow "Columns menu (hover key opens the second column)"
        -- wired (open specimen): option clicks toggle the value; a branch
        -- click retargets the hover column (expand stays click here)
        [ Cascader.menu theme
            { cascMenuD
                | hoverKey = model.specCascMenuHover
                , multiple = True
                , value = model.specCascMenu
                , expandTrigger = Cascader.Click
                , onToggle = Just SpecCascMenuToggled
                , attributes = [ Element.width (Element.px 420) ]
            }
            cascaderOptions
        ]
    , demoRow "Columns menu: child strategy (leaf checkmarks) · empty · action"
        -- wired: the child-strategy menu's leaf clicks commit; the empty
        -- menu has nothing to wire (specimen)
        [ Cascader.menu theme
            { cascMenuD
                | checkStrategy = Cascader.Child
                , value = model.specCascChild
                , onToggle = Just SpecCascChildPicked
                , action = Just (Element.text "#action")
                , attributes = [ Element.width (Element.px 200) ]
            }
            cascaderOptions
        , Cascader.menu theme
            { cascMenuD | attributes = [ Element.width (Element.px 200) ] }
            []
        ]
    , demoRow "Filterable flat menu (pattern 'sub')"
        -- wired: the flat multiple menu's rows flip membership
        [ Cascader.selectMenu theme
            { cascSelectMenuD
                | multiple = True
                , value = model.specCascFlat
                , onToggle = Just SpecCascFlatToggled
                , attributes = [ Element.width (Element.px 280) ]
            }
            (Cascader.filterOptions "sub" Cascader.All " / " cascaderOptions)
        ]
    ]


cascaderLiveSection : Model -> Element Msg
cascaderLiveSection model =
    section "Cascader" cascaderDesc (cascaderRows model ++ [ cascaderLiveRow model ])


{-| The TreeSelect section description (shared by the static and live variants).
-}
treeSelectDesc : String
treeSelectDesc =
    "A selection trigger over a tree menu — show, positioning and the pattern/expand state are caller-owned."


treeSelectRows : Model -> List (Element Msg)
treeSelectRows model =
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

        -- the per-row shared option set: value/pending/expanded mirror the
        -- row's own literals (identical init), the node click is wired
        rowOpts :
            { multiple : Bool, checkable : Bool, cascade : Bool }
            -> SelectMenu.Value
            -> Maybe String
            -> List String
            -> TreeSelect.Options Msg
        rowOpts cfg value pending expanded =
            { tsD
                | options = data
                , multiple = cfg.multiple
                , checkable = cfg.checkable
                , cascade = cfg.cascade
                , value = value
                , pendingKey = pending
                , expandedKeys = expanded
                , onNodeClick = Just (rowMsg cfg)
            }
                |> (\o ->
                        if cfg.multiple then
                            { o | maxTagCount = Just 2 }

                        else
                            o
                   )

        rowMsg cfg =
            if cfg.multiple then
                SpecTsNodeClicked TsMultiRow

            else if cfg.checkable then
                SpecTsNodeClicked TsMultiRow

            else
                SpecTsNodeClicked TsSingleRow

        singleCfg =
            { multiple = False, checkable = False, cascade = False }

        multiCfg =
            { multiple = True, checkable = True, cascade = True }

        filterCfg =
            { multiple = False, checkable = False, cascade = False }
    in
    [ demoRow "Basic single"
        [ Element.column [ Element.spacing 8 ]
            [ TreeSelect.view theme
                (rowOpts singleCfg model.specTsSingle model.specTsSinglePending [ "o1" ])
            , Element.el [ menuBox ]
                (TreeSelect.menu theme
                    (rowOpts singleCfg model.specTsSingle model.specTsSinglePending [ "o1", "o1-1" ])
                )
            ]
        ]
    , demoRow "Multiple + cascade + checkable"
        [ Element.column [ Element.spacing 8 ]
            [ TreeSelect.view theme
                (rowOpts multiCfg model.specTsMulti Nothing [ "o1" ])
            , Element.el [ menuBox ]
                (TreeSelect.menu theme (rowOpts multiCfg model.specTsMulti Nothing [ "o1" ]))
            ]
        ]
    , demoRow "Filterable + showPath"
        [ Element.column [ Element.spacing 8 ]
            [ TreeSelect.view theme
                (rowOpts filterCfg model.specTsFilter Nothing [ "o1", "o1-1" ]
                    |> (\o -> { o | filterable = True, showPath = True })
                )
            , Element.el [ menuBox ]
                (TreeSelect.menu theme
                    (rowOpts filterCfg model.specTsFilter Nothing [ "o1" ]
                        |> (\o -> { o | filterable = True, pattern = "eft" })
                    )
                )
            ]
        ]
    , demoRow "Slots + empty"
        -- specimen row: the trigger's status/clearable/hover are the showcase
        -- and the menu is header/action/empty pins (no tree rows to click)
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


treeSelectLiveSection : Model -> Element Msg
treeSelectLiveSection model =
    section "TreeSelect" treeSelectDesc (treeSelectRows model ++ [ treeSelectLiveRow model ])


{-| The AutoComplete section description (shared by the static and live variants).
-}
autoCompleteDesc : String
autoCompleteDesc =
    "Naive UI's autocomplete — a bare `.n-auto-complete` wrapper around a plain `NUI.Input` trigger (NOT the selection: upstream drives `NInput` directly, no `NInternalSelection`); the menu is a separate caller-mounted body (its own follower upstream), `AutoComplete.menu` here — hardcoded Medium, `tabindex -1`, never `--selected` (no checkmark node), and `loading` is the input's suffix spinner, never a menu row. The caller owns the whole show gate (`getShow ? getShow (value || \"\") : value ≠ \"\"`, focused-typed, `showEmpty`), positioning, keyboard and the select commit (`onSelect value` always, then `clearAfterSelect` → null / the label commit, `append` ⇒ `value ++ label`); it does no filtering of its own — options are yours to derive (the email demo's suffix list). `fromString` lifts bare strings; `inputAttributes` is upstream's `inputProps`."


autoCompleteRows : Model -> List (Element Msg)
autoCompleteRows model =
    [ demoRow "Basic (value + open menu + inputProps)"
        -- wired: the first input's typing + the open menu's select commit;
        -- the second keeps its inputProps specimen (autofocus pin)
        [ AutoComplete.view theme
            { acD
                | value = model.specAcBasic
                , onInput = Just SpecAcBasicTyped
                , attributes = [ Element.width (Element.px 220) ]
            }
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
            { acMenuD
                | onToggle = Just SpecAcBasicPicked
                , attributes = [ Element.width (Element.px 220) ]
            }
            [ AutoComplete.fromString "Drive My Car"
            , AutoComplete.fromString "Day Tripper"
            ]
        ]
    , demoRow "Sizes (the menu stays Medium)"
        -- specimen row: Small/Medium/Large are the showcase; the menu mounts
        -- the same two rows as the basic demo (nothing new to commit)
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
        -- wired: group demo's input + the grouped menu's select
        [ AutoComplete.view theme
            { acD
                | value = model.specAcGroup
                , onInput = Just SpecAcGroupTyped
                , attributes = [ Element.width (Element.px 220) ]
            }
        , AutoComplete.menu theme
            { acMenuD
                | onToggle = Just SpecAcGroupPicked
                , attributes = [ Element.width (Element.px 220) ]
            }
            selectOptions
        ]
    , demoRow "Status · disabled"
        -- specimen row (status/disabled are the showcase)
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
        -- wired: the clearable instance's × empties the value (the clear
        -- fires onInput "" — upstream null ≡ ""); loading and the triple
        -- instance stay specimens (their pins are the point)
        [ AutoComplete.view theme
            { acD
                | value = model.specAcClearable
                , clearable = True
                , onInput = Just SpecAcClearableTyped
                , attributes = [ Element.width (Element.px 200) ]
            }
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
        -- specimen row: the empty seam + placeholder pin (nothing to select)
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
        -- specimen row: the two chips document the commit semantics (the
        -- inputs themselves stay inert — the live row exercises the loop)
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
        -- wired: the custom-row menu's leaf still selects (commit → the
        -- basic input's value)
        [ AutoComplete.menu theme
            { acMenuD
                | onToggle = Just SpecAcCustomPicked
                , attributes = [ Element.width (Element.px 220) ]
            }
            [ AutoComplete.fromString "A plain row"
            , SelectMenu.Custom
                { key = "ac-custom"
                , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text "renderOption row" ]
                }
            ]
        ]
    ]


autoCompleteLiveSection : Model -> Element Msg
autoCompleteLiveSection model =
    section "AutoComplete" autoCompleteDesc (autoCompleteRows model ++ [ autoCompleteLiveRow model ])


{-| The Mention section description (shared by the static and live variants).
-}
mentionDesc : String
mentionDesc =
    "Naive UI's mention — the same family as AutoComplete: a bare `.n-mention` wrapper around a plain `NUI.Input` trigger (NOT the selection — no `NInternalSelection` upstream), plus a separate caller-mounted `NUI.SelectMenu` body (`Mention.menu`). Three divergences from AutoComplete, frozen: `loading` is the MENU's `__loading` row (`MenuOptions.loading`), never the input suffix; upstream filters internally (the default `startsWith` predicate — the port drops the engine, the caller pre-filters and passes the filtered list); and the wrapper's cssr has no `display: inline-flex` (`width: 100%; z-index: auto; position: relative`) with `placeholder` defaulting to `\"\"`. The menu is hardcoded Medium, `tabindex -1`, and `value` stays `Single Nothing` — never `--selected`, no checkmark node. Options are `NUI.SelectMenu.Option` verbatim — no `fromString` (there are no bare-string options upstream); `type_` is `text`/`textarea` only. The caller owns the whole runtime: the show gate (the prefix scan + caret + separator formulas), the select splice, keyboard and positioning (upstream anchors the follower at the caret via mirror-div measurement — un-portable)."


mentionRows : Model -> List (Element Msg)
mentionRows model =
    [ demoRow "Basic (the default @-trigger — caret inside an @-run opens)"
        -- wired: the first cell's input types + the mounted menu splices
        -- the mention; the second input is the placeholder specimen
        [ cell
            (Element.column [ Element.spacing 6, Element.width Element.fill ]
                [ Mention.view theme
                    { mnD
                        | value = model.specMnBasic
                        , onInput = Just SpecMnBasicTyped
                        , attributes = [ Element.width (Element.px 220) ]
                    }
                , Mention.menu theme
                    { mnMenuD
                        | onToggle = Just SpecMnBasicPicked
                        , attributes = [ Element.width (Element.px 220) ]
                    }
                    mentionOptions
                ]
            )
        , Mention.view theme
            { mnD
                | value = model.specMnBasic2
                , onInput = Just SpecMnBasic2Typed
                , placeholder = "Type @ to mention"
                , attributes = [ Element.width (Element.px 220) ]
            }
        ]
    , demoRow "Sizes (the menu stays Medium)"
        -- specimen row: Small/Medium/Large are the showcase (shared value
        -- would homogenize the three sizes' text)
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
        -- wired: the textarea types into the model
        [ Element.el [ Element.width (Element.px 360) ]
            (Mention.view theme
                { mnD
                    | type_ = Mention.Textarea
                    , value = model.specMnTextarea
                    , onInput = Just SpecMnTextareaTyped
                    , placeholder = "Type @ to mention"
                }
            )
        ]
    , demoRow "Autosize (n-input--autosize, resizable suppressed — height measurement caller-owned)"
        -- wired: same, the autosize textarea
        [ Element.el [ Element.width (Element.px 360) ]
            (Mention.view theme
                { mnD
                    | type_ = Mention.Textarea
                    , autosize = True
                    , value = model.specMnAutosize
                    , onInput = Just SpecMnAutosizeTyped
                }
            )
        ]
    , demoRow "Custom prefix (#@ — the caller gates the option set; the module does no scan)"
        -- wired: the group demo's input types + BOTH mounted menus splice
        -- into the same run
        [ cell
            (Element.column [ Element.spacing 6, Element.width Element.fill ]
                [ Mention.view theme
                    { mnD
                        | value = model.specMnGroupTag
                        , onInput = Just SpecMnGroupTagTyped
                        , placeholder = "# for tags"
                        , attributes = [ Element.width (Element.px 200) ]
                    }
                , chip "prefix \"#\" → the tag list"
                , Mention.menu theme
                    { mnMenuD
                        | onToggle = Just (\value -> SpecMnGroupTagPicked ("#" ++ value))
                        , attributes = [ Element.width (Element.px 200) ]
                    }
                    mentionTagOptions
                ]
            )
        , cell
            (Element.column [ Element.spacing 6, Element.width Element.fill ]
                [ Mention.view theme
                    { mnD
                        | value = model.specMnGroupUser
                        , onInput = Just SpecMnGroupUserTyped
                        , placeholder = "@ for users"
                        , attributes = [ Element.width (Element.px 200) ]
                    }
                , chip "prefix \"@\" → the user list"
                , Mention.menu theme
                    { mnMenuD
                        | onToggle = Just (\value -> SpecMnGroupUserPicked ("@" ++ value))
                        , attributes = [ Element.width (Element.px 200) ]
                    }
                    mentionOptions
                ]
            )
        ]
    , demoRow "Loading (THE divergence — the menu's __loading row, never the input suffix)"
        -- specimen row: the loading pin is the point (loading replaces the
        -- menu middle — nothing clickable)
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
        -- wired: the input types + the grouped menu's rows splice
        [ Mention.view theme
            { mnD
                | value = model.specMnGroup2
                , onInput = Just SpecMnGroup2Typed
                , attributes = [ Element.width (Element.px 220) ]
            }
        , Mention.menu theme
            { mnMenuD
                | onToggle = Just (\value -> SpecMnGroup2Picked value)
                , attributes = [ Element.width (Element.px 220) ]
            }
            (selectOptions
                ++ [ SelectMenu.Custom
                        { key = "mention-custom"
                        , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text "renderOption row" ]
                        }
                   ]
            )
        ]
    , demoRow "Status · disabled"
        -- specimen row (status/disabled are the showcase)
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


mentionLiveSection : Model -> Element Msg
mentionLiveSection model =
    section "Mention" mentionDesc (mentionRows model ++ [ mentionLiveRow model ])


{-| The DatePicker section description (shared by the static and live variants).
-}
datePickerDesc : String
datePickerDesc =
    "An input trigger over a caller-mounted calendar panel — every upstream panel type, with show state, positioning and the value caller-owned."


datePickerRows : Model -> List (Element Msg)
datePickerRows model =
    [ demoRow "Date"
        -- wired: value/calendar/month-panel state; day click commits + closes
        [ specDpPair DpDateRow model ]
    , demoRow "Datetime"
        -- wired: same, with the datetime actions (Now/Confirm) live
        [ specDpPair DpDatetimeRow model ]
    , demoRow "Date range (pair input)"
        -- wired: two-click dual select, hover preview, Confirm commits
        [ specDpPair DpDaterangeRow model ]
    , demoRow "Datetime range"
        -- wired: same + the per-side embedded time pickers
        [ specDpPair DpDatetimerangeRow model ]
    , demoRow "Month"
        -- wired: month cell click commits + closes
        [ specDpPair DpMonthRow model ]
    , demoRow "Year"
        -- wired: year cell click commits + closes (yearRange literal kept)
        [ specDpPair DpYearRow model ]
    , demoRow "Quarter"
        -- wired: quarter cell click commits + closes
        [ specDpPair DpQuarterRow model ]
    , demoRow "Month range"
        -- wired: dual month select, Confirm commits
        [ specDpPair DpMonthrangeRow model ]
    , demoRow "Week"
        -- wired: week cell click commits + closes
        [ specDpPair DpWeekRow model ]
    , demoRow "Sizes / clearable / status / disabled"
        -- specimen row (sizes/clearable/status/disabled are the showcase —
        -- plain triggers with no mounted panel emit nothing)
        [ DatePicker.view theme { dpD | now = dpNow, size = T.Small, value = DatePicker.Single (Just dpNowMs) }
        , DatePicker.view theme { dpD | now = dpNow, value = DatePicker.Single (Just dpNowMs), clearable = True }
        , DatePicker.view theme { dpD | now = dpNow, size = T.Large, placeholder = Just "Pick a date" }
        , DatePicker.view theme { dpD | now = dpNow, value = DatePicker.Single (Just dpNowMs), status = Just Input.Error }
        , DatePicker.view theme { dpD | now = dpNow, value = DatePicker.Single (Just dpNowMs), disabled = True }
        ]
    , demoRow "Range clearable + shortcuts"
        -- wired: shortcut hover previews / click commits + closes
        [ specDpPair DpShortcutsRow model ]
    ]


datePickerLiveSection : Model -> Element Msg
datePickerLiveSection model =
    section "DatePicker" datePickerDesc (datePickerRows model ++ [ dpSingleLiveRow model, dpRangeLiveRow model ])


{-| The TimePicker section description (shared by the static and live variants).
-}
timePickerDesc : String
timePickerDesc =
    "An input trigger over a caller-mounted clock panel — show state, positioning and the value are caller-owned."


timePickerRows : Model -> List (Element Msg)
timePickerRows model =
    [ demoRow "Default (HH:mm:ss)"
        -- wired: column item clicks set the value, Confirm commits + closes
        [ specTpPair TpBasicRow model ]
    , demoRow "Hour + minute (HH:mm)"
        -- wired: same, the two-column format
        [ specTpPair TpHmRow model ]
    , demoRow "12 hours + period (hh:mm:ss a)"
        -- wired: same, the period column included
        [ specTpPair Tp12Row model ]
    , demoRow "Actions clear / now / confirm"
        -- wired: Clear empties, Now snaps, Confirm closes
        [ specTpPair TpActionsRow model ]
    , demoRow "Disabled units (5-min steps, seconds 0/30, hours ≤ 12)"
        -- wired: the filters gate the columns; clicks still commit
        [ specTpPair TpDisabledRow model ]
    , demoRow "Sizes / clearable / disabled / status"
        -- specimen row (sizes/clearable/disabled/status are the showcase —
        -- plain triggers with no mounted panel emit nothing)
        [ TimePicker.view theme { tpD | now = dpNow, size = T.Small, value = Just tenToFiftyFour }
        , TimePicker.view theme { tpD | now = dpNow, value = Just tenToFiftyFour, clearable = True }
        , TimePicker.view theme { tpD | now = dpNow, size = T.Large, placeholder = "Pick" }
        , TimePicker.view theme { tpD | now = dpNow, value = Just tenToFiftyFour, disabled = True }
        , TimePicker.view theme { tpD | now = dpNow, value = Just tenToFiftyFour, status = Just Input.Error }
        ]
    ]


timePickerLiveSection : Model -> Element Msg
timePickerLiveSection model =
    section "TimePicker" timePickerDesc (timePickerRows model ++ [ tpLiveRow model ])


{-| The ColorPicker section description (shared by the static and live variants).
-}
colorPickerDesc : String
colorPickerDesc =
    "A colour trigger over a caller-mounted palette panel — show state, positioning, drag and the value are caller-owned."


colorPickerRows : Model -> List (Element Msg)
colorPickerRows model =
    [ demoRow "Basic"
        -- wired: swatch clicks + mode toggle drive the draft; the trigger
        -- reopens after a close; palette/hue/alpha drags commit live
        [ specCpPair CpBasicRow 0 model identity ]
    , demoRow "Alpha off + confirm"
        -- wired: Confirm commits + closes
        [ specCpPair CpAlphaRow 0 model identity ]
    , demoRow "Sizes"
        -- wired: the three sizes share one row state (the brief's shared-
        -- field rule -- they showcase the SAME colour at three sizes), each
        -- instance reading its own drag rects (per-instance surface ids)
        [ specCpPair CpSizesRow 0 model (\o -> { o | size = T.Small })
        , specCpPair CpSizesRow 1 model identity
        , specCpPair CpSizesRow 2 model (\o -> { o | size = T.Large })
        ]
    , demoRow "Disabled"
        -- specimen row (the disabled pin is the point -- the trigger and
        -- panel render but nothing can fire)
        [ Element.column [ Element.spacing 8, Element.width (Element.px 240) ]
            [ ColorPicker.view theme { cpD | value = Just specCpRed, disabled = True }
            , Element.el [ Element.width (Element.px 240) ]
                (ColorPicker.panel theme { cpD | value = Just specCpRed, disabled = True })
            ]
        ]
    , demoRow "Single mode (hex)"
        -- wired: the pinned single-mode unit row — `modes = [ Hex ]` is both
        -- the showcase pin AND the enforcement (no other mode exists to
        -- switch to), so drag/swatches/undo run live against it
        [ specCpPair CpSingleModeRow 0 model identity ]
    , demoRow "Swatches"
        -- wired: swatch clicks commit to the draft
        [ specCpPair CpSwatchesRow 0 model identity ]
    , demoRow "Actions clear"
        -- wired: Clear empties + closes
        [ specCpPair CpClearRow 0 model identity ]
    , demoRow "Preview (native input)"
        -- wired: the preview tracks the draft
        [ specCpPair CpPreviewRow 0 model identity ]
    , demoRow "Custom trigger"
        -- specimen row (the custom trigger is the showcase -- a plain button
        -- replaces the picker's own trigger surface)
        [ ColorPicker.view theme
            { cpD
                | value = Just specCpRed
                , customTrigger = Just (Button.view theme { btn | kind = T.Primary } [ Element.text "Pick a colour" ])
            }
        ]
    , demoRow "Undo / redo actions"
        -- wired: real undo/redo stacks (seeded so undoable starts True)
        [ specCpPair CpUndoRow 0 model identity ]
    ]


colorPickerLiveSection : Model -> Element Msg
colorPickerLiveSection model =
    section "ColorPicker" colorPickerDesc (colorPickerRows model ++ [ cpLiveRow model ])


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
