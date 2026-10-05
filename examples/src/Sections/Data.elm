module Sections.Data exposing
    ( Model
    , Msg
    , calendarSection
    , dataTableSection
    , dynamicInputSection
    , dynamicTagsSection
    , imagePreviewSection
    , imageSection
    , init
    , sections
    , subscriptions
    , tableSection
    , transferSection
    , treeSection
    , update
    , uploadSection
    )

{-| Data family sections: Dynamic Tags, Calendar, Dynamic Input, Table,
Tree, Image, Image Preview & Group, Data Table, Transfer, Upload.

The static rows moved verbatim from Main.elm — that surface feeds the
check-dom gate, so every root keeps rendering exactly as before. The live
demo rows (moved verbatim from Live/Data.elm — same demoRow labels, same
`#live-*` ids) run a real update loop owned by this module: caller-owned
state per each port's contract — the component renders whatever the model
says, every channel feeds one Msg constructor, and the pure interaction
helpers the ports ship (DataTable's checked-keys algebra, Tree's treemate
`check`/`uncheck`/`toggleExpand`/`toggleSelect`, Calendar's panel recipe,
ImagePreview's zoom transforms, ImageGroup's walk, Upload's `mark*` state
machine, DynamicInput's array edits, Form's validation engine) run in
`update`, never re-derived by hand.

Two ports ship no event channels by design, and the demos stay honest about
it instead of faking them:

  - **Table** is fully static (its header says so); the row click rides the
    documented `Row.attributes` seam (upstream's bare `<tr>` wrapper).
  - **Tree** renders all state as data; the row click rides the documented
    `nodeProps` attribute seam (with `blockLine` so it lands on the node
    div). The port's switcher/checkbox are display-only, so expand folds
    into the node click and check rides `checkOnClick` (an upstream flag).

Oracle-round divergences (tasks/recon/live-oracle.md):

  - [oracle D] **DtPageSize resets the page to 1** — upstream clamps into
    the new pageCount instead (`mergedPage` watcher; Nav's twin Pagination
    demo clamps). With 8 rows / ≤2 pages the two recipes are observationally
    identical here; align to the clamp when next touched.

-}

import Element exposing (Element)
import Html.Attributes as HA
import Html.Events as HE
import NUI.Button as Button
import NUI.Calendar as Calendar
import NUI.DataTable as DataTable
import NUI.DynamicInput as DynamicInput
import NUI.DynamicTags as DynamicTags
import NUI.Form as Form
import NUI.Image as Image
import NUI.ImageGroup as ImageGroup
import NUI.ImagePreview as ImagePreview
import NUI.Input as Input
import NUI.InputNumber as InputNumber
import NUI.Pagination as Pagination
import NUI.Table as Table
import NUI.Theme exposing (Theme)
import NUI.Transfer as Transfer
import NUI.Tree as Tree
import NUI.Types as T
import NUI.Typography as Typo
import NUI.Upload as Upload
import Showcase exposing (chip, demoRow, section, theme)



-- MODEL


type alias Model =
    { tablePick : Maybe String
    , dtChecked : List String
    , dtLastSelected : String
    , dtSort : List (DataTable.SortState Person)
    , dtPage : Int
    , dtPageSize : Int
    , treeExpanded : List String
    , treeChecked : List String
    , treeSelected : List String
    , transferValue : List String
    , transferSourcePattern : String
    , transferTargetPattern : String
    , calPanel : Calendar.Panel
    , calValue : Maybe Calendar.Date
    , previewShow : Bool
    , previewIndex : Int
    , previewZoom : ImagePreview.Zoom
    , previewDerived : Bool
    , groupShow : Bool
    , groupCurrent : Int
    , groupZoom : ImagePreview.Zoom
    , files : List Upload.FileInfo
    , uploadSeq : Int
    , uploadNote : String
    , previewNote : String
    , pairs : List ( String, String )
    , tags : List String
    , tagsShowInput : Bool
    , tagsDraft : String
    , formName : String
    , formNameFeedback : List Form.Feedback
    , formAge : Maybe Float
    , formAgeFeedback : List Form.Feedback
    , formSubmitted : Maybe ( String, String )
    }


init : Model
init =
    { tablePick = Nothing
    , dtChecked = []
    , dtLastSelected = ""
    , dtSort = []
    , dtPage = 1
    , dtPageSize = 4
    , treeExpanded = [ "radiohead" ]
    , treeChecked = []
    , treeSelected = []
    , transferValue = [ "1" ]
    , transferSourcePattern = ""
    , transferTargetPattern = ""
    , calPanel = { year = 2024, month = 6 }
    , calValue = Nothing
    , previewShow = False
    , previewIndex = 0
    , previewZoom = ImagePreview.zoom0
    , previewDerived = False
    , groupShow = False
    , groupCurrent = 0
    , groupZoom = ImagePreview.zoom0
    , files = []
    , uploadSeq = 0
    , uploadNote = "no file action yet"
    , previewNote = "no toolbar action yet"
    , pairs = []
    , tags = [ "Naive UI", "Elm" ]
    , tagsShowInput = False
    , tagsDraft = ""
    , formName = ""
    , formNameFeedback = []
    , formAge = Nothing
    , formAgeFeedback = []
    , formSubmitted = Nothing
    }



-- MSG


type Msg
    = TablePick String
      -- DataTable (one table, three live behaviors)
    | DtCheck (List String) (List Person) (DataTable.CheckEmit Person)
    | DtSort (List (DataTable.SortState Person))
    | DtPage Int
    | DtPageSize Int
      -- Tree (nodeProps seam — see module docs)
    | TreeNodeClick String
      -- Transfer
    | TransferCheck (List String)
    | TransferSourceFilter String
    | TransferTargetFilter String
      -- Calendar
    | CalPanel Calendar.Panel
    | CalPick Calendar.Date
      -- ImagePreview (full toolbar algebra; measurement simulated)
    | PreviewOpen Int
    | PreviewClose
    | PreviewPrev
    | PreviewNext
    | PreviewZoomIn
    | PreviewZoomOut
    | PreviewRotateClockwise
    | PreviewRotateCounterclockwise
    | PreviewOriginalSize
    | PreviewDblclick
    | PreviewDownload
      -- ImageGroup
    | GroupOpen Int
    | GroupPrev
    | GroupNext
    | GroupClose
      -- Upload (simulated file list)
    | UploadAdd
    | UploadPick
    | UploadAddFailing
    | UploadAdvance
    | UploadRemove String
    | UploadRetry String
    | UploadPreview String
    | UploadDownload String
      -- DynamicInput (pair preset)
    | SetPairs (List ( String, String ))
    | PairRemove Int
      -- DynamicTags
    | TagsActivate
    | TagsDraft String
    | TagsConfirm
    | TagsUpdate (List String)
      -- Form
    | FormNameInput String
    | FormNameBlur
    | FormAgeChange (Maybe Float)
    | FormSubmit


update : Msg -> Model -> Model
update msg model =
    case msg of
        TablePick name ->
            { model | tablePick = Just name }

        DtCheck keys _ emit ->
            { model
                | dtChecked = keys
                , dtLastSelected =
                    case emit.row of
                        Just row ->
                            row.name

                        Nothing ->
                            model.dtLastSelected
            }

        DtSort states ->
            { model | dtSort = states }

        DtPage page ->
            { model | dtPage = page }

        DtPageSize size ->
            { model | dtPageSize = size, dtPage = 1 }

        TreeNodeClick key ->
            case treeInfo key treeData of
                Just info ->
                    if info.disabled then
                        model

                    else
                        let
                            -- the view's own normalization (cascade, All)
                            normalized =
                                Tree.getCheckedKeys True Tree.All False model.treeChecked treeData
                        in
                        { model
                            | treeExpanded = Tree.toggleExpand False treeData key model.treeExpanded
                            , treeSelected = Tree.toggleSelect False True key model.treeSelected
                            , treeChecked =
                                if List.member key normalized.checkedKeys then
                                    Tree.uncheck True Tree.All False key model.treeChecked treeData

                                else
                                    Tree.check True Tree.All False key model.treeChecked treeData
                        }

                Nothing ->
                    model

        TransferCheck value ->
            { model | transferValue = value }

        TransferSourceFilter pattern ->
            { model | transferSourcePattern = pattern }

        TransferTargetFilter pattern ->
            { model | transferTargetPattern = pattern }

        CalPanel panel ->
            { model | calPanel = panel }

        CalPick date ->
            -- the header's recipe: a clicked other-month cell also moves
            -- the panel to that month
            { model
                | calValue = Just date
                , calPanel =
                    if Calendar.panelOf date /= model.calPanel then
                        Calendar.panelOf date

                    else
                        model.calPanel
            }

        PreviewOpen index ->
            { model
                | previewShow = True
                , previewIndex = index
                , previewZoom = ImagePreview.zoom0
                , previewDerived = False
            }

        PreviewClose ->
            { model | previewShow = False }

        PreviewPrev ->
            { model
                | previewIndex = modBy (List.length previewSrcs) (model.previewIndex - 1)
                , previewZoom = ImagePreview.switchReset model.previewZoom
                , previewDerived = False
            }

        PreviewNext ->
            { model
                | previewIndex = modBy (List.length previewSrcs) (model.previewIndex + 1)
                , previewZoom = ImagePreview.switchReset model.previewZoom
                , previewDerived = False
            }

        PreviewZoomIn ->
            { model
                | previewZoom = ImagePreview.zoomIn previewMaxScale model.previewZoom
                , previewDerived = True
            }

        PreviewZoomOut ->
            -- the header's two-step: apply zoomOut, re-measure (simulated),
            -- then clamp the offsets through derivedOffset
            let
                zoom =
                    ImagePreview.zoomOut model.previewZoom

                offsets =
                    ImagePreview.derivedOffset Nothing
                        { rect = fakeRect zoom
                        , viewport = fakeViewport
                        , start = { offsetX = zoom.offsetX, offsetY = zoom.offsetY }
                        }
            in
            { model
                | previewZoom = { zoom | offsetX = offsets.offsetX, offsetY = offsets.offsetY }
                , previewDerived = True
            }

        PreviewRotateClockwise ->
            { model
                | previewZoom = ImagePreview.rotateClockwise model.previewZoom
                , previewDerived = True
            }

        PreviewRotateCounterclockwise ->
            { model
                | previewZoom = ImagePreview.rotateCounterclockwise model.previewZoom
                , previewDerived = True
            }

        PreviewOriginalSize ->
            { model
                | previewZoom = ImagePreview.resizeToOriginalSize previewOriginalScale model.previewZoom
                , previewDerived = True
            }

        PreviewDblclick ->
            { model
                | previewZoom = ImagePreview.toggleOriginalSize previewOriginalScale model.previewZoom
                , previewDerived = True
            }

        PreviewDownload ->
            { model | previewNote = "download requested (no-op — the browser download is the caller's port)" }

        GroupOpen index ->
            -- the header's toggleShow half: setCurrentId through the
            -- exported helper, then show
            let
                base =
                    ImageGroup.defaults

                current =
                    (ImageGroup.showImage ("p" ++ String.fromInt index) { base | srcList = gallery }).current
            in
            { model | groupShow = True, groupCurrent = current, groupZoom = ImagePreview.zoom0 }

        GroupPrev ->
            -- toolbar prev: reset the zoom, then go
            let
                base =
                    ImageGroup.defaults

                current =
                    (ImageGroup.go -1 { base | srcList = gallery, current = model.groupCurrent }).current
            in
            { model | groupCurrent = current, groupZoom = ImagePreview.switchReset model.groupZoom }

        GroupNext ->
            let
                base =
                    ImageGroup.defaults

                current =
                    (ImageGroup.go 1 { base | srcList = gallery, current = model.groupCurrent }).current
            in
            { model | groupCurrent = current, groupZoom = ImagePreview.switchReset model.groupZoom }

        GroupClose ->
            { model | groupShow = False }

        UploadAdd ->
            addFakeFile model fakeImageFile

        UploadPick ->
            addFakeFile model (\n -> fakeFile n "picked.txt" "text/plain")

        UploadAddFailing ->
            addFakeFile model (\n -> fakeFile n ("broken-" ++ String.fromInt n ++ ".zip") "application/zip")

        UploadAdvance ->
            { model | files = List.map advanceFile model.files }

        UploadRemove id ->
            { model | files = Upload.removeFileById id model.files }

        UploadRetry id ->
            { model
                | files =
                    List.map
                        (\file ->
                            if file.id == id then
                                Upload.markUploading 0 file

                            else
                                file
                        )
                        model.files
            }

        UploadPreview id ->
            { model | uploadNote = "preview " ++ fileNameOf id model.files }

        UploadDownload id ->
            { model | uploadNote = "download " ++ fileNameOf id model.files }

        SetPairs pairs ->
            { model | pairs = pairs }

        PairRemove index ->
            { model | pairs = DynamicInput.removeAt index model.pairs }

        TagsActivate ->
            { model | tagsShowInput = True }

        TagsDraft draft ->
            { model | tagsDraft = draft }

        TagsConfirm ->
            -- the header's documented confirm recipe
            { model
                | tags =
                    if model.tagsDraft == "" then
                        model.tags

                    else
                        model.tags ++ [ model.tagsDraft ]
                , tagsShowInput = False
                , tagsDraft = ""
            }

        TagsUpdate tags ->
            { model | tags = tags }

        FormNameInput name ->
            { model
                | formName = name
                , formNameFeedback = Form.validateValue (Just Form.OnInput) nameField nameRules (Just (Form.VString name))
            }

        FormNameBlur ->
            { model
                | formNameFeedback = Form.validateValue (Just Form.OnBlur) nameField nameRules (Just (Form.VString model.formName))
            }

        FormAgeChange age ->
            { model
                | formAge = age
                , formAgeFeedback = Form.validateValue (Just Form.OnChange) ageField ageRules (Just (ageValue age))
            }

        FormSubmit ->
            let
                result =
                    Form.validateForm Nothing Nothing formRules (formValues model)

                nameFb =
                    feedbackOf nameField result

                ageFb =
                    feedbackOf ageField result

                clean =
                    List.isEmpty nameFb && List.isEmpty ageFb
            in
            { model
                | formNameFeedback = nameFb
                , formAgeFeedback = ageFb
                , formSubmitted =
                    if clean then
                        Just ( model.formName, Maybe.withDefault "—" (Maybe.map ageLabel model.formAge) )

                    else
                        model.formSubmitted
            }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


dtagsD : DynamicTags.Options msg
dtagsD =
    DynamicTags.defaults


diD : DynamicInput.InputOptions msg
diD =
    DynamicInput.inputDefaults


diPairD : DynamicInput.PairOptions msg
diPairD =
    DynamicInput.pairDefaults


calD : Calendar.Options msg
calD =
    Calendar.defaults


tableD : Table.Options msg
tableD =
    Table.defaults


{-| A two-column demo table (head + three body rows).
-}
tableContent : Table.Table msg
tableContent =
    { head =
        [ { rowD | cells = [ tableCell "Name", tableCell "Origin" ] } ]
    , body =
        [ { rowD | cells = [ tableCell "Naive", tableCell "Vue" ] }
        , { rowD | cells = [ tableCell "elm-naive-ui", tableCell "Elm" ] }
        , { rowD | cells = [ tableCell "Seemly", tableCell "Utils" ] }
        ]
    }


{-| The colspan / rowspan demo (naive-ui docs' merge-cell shape).
-}
spanContent : Table.Table msg
spanContent =
    { head =
        [ { rowD | cells = [ tableCell "", cellD, cellD ] } ]
    , body =
        [ { rowD
            | cells =
                [ { cellD | content = [ Element.text "Guitar" ], rowspan = Just 2 }
                , tableCell "1998"
                , tableCell "Songs"
                ]
          }
        , { rowD | cells = [ tableCell "2001", { cellD | colspan = Just 2, content = [ Element.text "Albums + Tours" ] } ] }
        ]
    }


rowD : Table.Row msg
rowD =
    Table.rowDefaults


cellD : Table.Cell msg
cellD =
    Table.cellDefaults


tableCell : String -> Table.Cell msg
tableCell label =
    { cellD | content = [ Element.text label ] }


treeD : Tree.Options msg
treeD =
    Tree.defaults


{-| Two albums, a nested disc one deep, a disabled leaf — enough shape for
the indent chain, the `--last-child` / `--is-leaf` guide lines, the
`--checkable` cascade, and the disabled state.
-}
treeOptions : List (Tree.TreeOption msg)
treeOptions =
    [ Tree.TreeOption
        { key = "beatles"
        , label = "The Beatles"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children =
            Just
                [ leafOption "drive" "Drive My Car"
                , leafOption "nowhere" "Nowhere Man"
                , Tree.TreeOption
                    { key = "anthology"
                    , label = "Anthology"
                    , disabled = False
                    , checkboxDisabled = False
                    , isLeaf = False
                    , children = Just [ leafOption "anth1" "Anthology 1" ]
                    , prefix = []
                    , suffix = []
                    }
                ]
        , prefix = []
        , suffix = []
        }
    , Tree.TreeOption
        { key = "stones"
        , label = "The Rolling Stones"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children = Just [ leafOption "exile" "Exile on Main St." ]
        , prefix = []
        , suffix = []
        }
    , Tree.TreeOption
        { key = "wildlife"
        , label = "Wild Life (disabled)"
        , disabled = True
        , checkboxDisabled = False
        , isLeaf = True
        , children = Nothing
        , prefix = []
        , suffix = []
        }
    ]


leafOption : String -> String -> Tree.TreeOption msg
leafOption key label =
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


modalHost : List (Element.Attribute msg) -> Element msg -> Element msg
modalHost attrs content =
    -- `Element.width`/`height` (NOT raw style): elm-ui's `we` companion
    -- class is what restores `flex-basis: auto` for a row child — a raw
    -- `style="width:…"` leaves `flex-basis: 0%` in force and the host
    -- collapses to its 2px border, taking the fixed preview tree with it.
    Element.el
        ([ Element.width (Element.px 320)
         , Element.height (Element.px 210)
         , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;transform:translate(0,0);overflow:hidden;border:1px solid #efeff5;background:#fafafc"
            )
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


imageD : Image.Options msg
imageD =
    Image.defaults


imageLogo : String
imageLogo =
    -- An inline SVG (a green plate + white disc stand-in for upstream's
    -- naivelogo), not the naiveui.com asset: the remote SVG is
    -- hotlink-blocked in some environments and every consumer of this
    -- constant (object-fit / placeholder / lazy / preview / group cells,
    -- the fallback demo) reads as a broken image when it 404s. A data URI
    -- always loads.
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20200%20150'%3E%3Crect%20width='200'%20height='150'%20fill='%2318a058'/%3E%3Ccircle%20cx='100'%20cy='75'%20r='40'%20fill='%23ffffff'/%3E%3C/svg%3E"


previewD : ImagePreview.Options msg
previewD =
    ImagePreview.defaults


previewZoom0 : ImagePreview.Zoom
previewZoom0 =
    ImagePreview.zoom0


groupD : ImageGroup.Options msg
groupD =
    ImageGroup.defaults



-- 10 · DYNAMIC TAGS


tagsOpts : Model -> DynamicTags.Options Msg
tagsOpts model =
    let
        dD =
            DynamicTags.defaults
    in
    { dD
        | value = model.tags
        , showInput = model.tagsShowInput
        , inputValue = model.tagsDraft
        , onActivate = Just TagsActivate
        , onInputValue = Just TagsDraft
        , onConfirm = Just TagsConfirm
        , onUpdateValue = Just TagsUpdate
    }


tagsDemo : Theme -> Model -> Element Msg
tagsDemo theme model =
    Element.column [ Element.spacing 10, Element.width (Element.px 480) ]
        [ DynamicTags.view theme (tagsOpts model) []
        , caption
            [ "tags: " ++ listLabel model.tags
            , if model.tagsShowInput then
                "input: \"" ++ model.tagsDraft ++ "\""

              else
                "input: hidden"
            ]
        , note theme
            "The add trigger activates the built-in input (onActivate → showInput), typing feeds the caller-owned draft (onInputValue), Enter confirms (append + hide + clear, the header's recipe), and a tag's close reports the next list (onUpdateValue)."
        ]


dynamicTagsRows : List (Element msg)
dynamicTagsRows =
    [ demoRow "Tags"
        [ DynamicTags.view theme
            { dtagsD | value = [ "Naive UI", "Elm", "elm-ui" ] }
            []
        , DynamicTags.view theme
            { dtagsD | value = [ "small", "medium" ], size = T.Small, round = True }
            []
        ]
    , demoRow "Input shown (caller owns the draft)"
        [ DynamicTags.view theme
            { dtagsD | value = [ "one", "two" ], showInput = True, inputValue = "thr" }
            []
        ]
    ]


dynamicTagsSection : Element msg
dynamicTagsSection =
    section "Dynamic Tags"
        "Editable tag lists (the tags, input and draft are caller-owned)."
        dynamicTagsRows


tagsLiveRow : Model -> Element Msg
tagsLiveRow model =
    demoRow "Dynamic Tags · add / confirm / close" [ tagsDemo theme model ]


dynamicTagsLiveSection : Model -> Element Msg
dynamicTagsLiveSection model =
    section "Dynamic Tags"
        "Editable tag lists (the tags, input and draft are caller-owned)."
        (dynamicTagsRows ++ [ tagsLiveRow model ])



-- 5 · CALENDAR


calNow : Calendar.Date
calNow =
    { year = 2024, month = 6, day = 15 }


calOpts : Model -> Calendar.Options Msg
calOpts model =
    let
        cD =
            Calendar.defaults
    in
    { cD
        | panel = model.calPanel
        , now = calNow
        , value = model.calValue
        , onUpdateValue = Just CalPick
        , onPanelChange = Just CalPanel
        , attributes = [ Element.htmlAttribute (HA.id "live-data-calendar") ]
    }


calendarDemo : Theme -> Model -> Element Msg
calendarDemo theme model =
    Element.column [ Element.spacing 10, Element.width (Element.px 420) ]
        [ Calendar.view theme (calOpts model)
        , caption
            [ "panel: " ++ Calendar.enUS.title model.calPanel
            , "selected: " ++ Maybe.withDefault "—" (Maybe.map formatDate model.calValue)
            ]
        , note theme
            "The header buttons emit onPanelChange with the target panel; clicking a cell emits onUpdateValue (clicking an other-month cell also moves the panel — the header's two-message recipe, applied in update)."
        ]


calendarRows : List (Element msg)
calendarRows =
    [ Element.el [ Element.width (Element.px 420) ]
        (Calendar.view theme
            { calD | panel = { year = 2024, month = 6 }, now = { year = 2024, month = 6, day = 15 } }
        )
    , Element.el [ Element.width (Element.px 420) ]
        (Calendar.view theme
            { calD
                | panel = { year = 2024, month = 6 }
                , now = { year = 2024, month = 6, day = 15 }
                , value = Just { year = 2024, month = 6, day = 20 }
            }
        )
    ]


calendarSection : Element msg
calendarSection =
    section "Calendar"
        "A month view (the panel, value and locale are caller-owned)."
        calendarRows


calendarLiveRow : Model -> Element Msg
calendarLiveRow model =
    demoRow "Calendar · panel + date" [ calendarDemo theme model ]


calendarLiveSection : Model -> Element Msg
calendarLiveSection model =
    section "Calendar"
        "A month view (the panel, value and locale are caller-owned)."
        (calendarRows ++ [ calendarLiveRow model ])



-- 9 · DYNAMIC INPUT (pair preset)


pairOpts : Model -> DynamicInput.PairOptions Msg
pairOpts model =
    let
        pD =
            DynamicInput.pairDefaults
    in
    { pD
        | value = model.pairs
        , min = 1
        , max = Just 4
        , showSortButton = True
        , keyPlaceholder = Just "Key"
        , valuePlaceholder = Just "Value"
        , onUpdateValue = Just SetPairs
        , onRemove = Just PairRemove
    }


pairDemo : Theme -> Model -> Element Msg
pairDemo theme model =
    let
        pairChips =
            if List.isEmpty model.pairs then
                [ "empty — press Create" ]

            else
                List.map (\( k, v ) -> k ++ " = " ++ v) model.pairs
    in
    Element.column [ Element.spacing 10, Element.width (Element.px 480) ]
        [ DynamicInput.viewPair theme (pairOpts model)
        , caption pairChips
        , note theme
            "Pair preset over a caller-owned list: typing reports the whole list (onUpdateValue with the entry replaced), Create / add / sort presses carry the inserted or moved list (insertAt / moveUp / moveDown inside the component), and the remove press owns its own channel — onRemove carries the index and update applies removeAt itself, the documented split."
        ]


dynamicInputRows : List (Element msg)
dynamicInputRows =
    [ demoRow "Preset: input"
        [ DynamicInput.viewInput theme
            { diD
                | value = [ "Alice", "Bob", "Cindy" ]
                , placeholder = Just "Name"
            }
        ]
    , demoRow "Preset: pair"
        [ DynamicInput.viewPair theme
            { diPairD
                | value = [ ( "Name", "Naive UI" ), ( "Author", "07akioni" ) ]
                , keyPlaceholder = Just "Key"
                , valuePlaceholder = Just "Value"
            }
        ]
    , demoRow "Max + sort buttons"
        [ DynamicInput.viewInput theme
            { diD
                | value = [ "Only", "Three" ]
                , max = Just 3
                , showSortButton = True
            }
        ]
    , demoRow "Empty (Create button)"
        [ DynamicInput.viewInput theme { diD | value = [] }
        ]
    ]


dynamicInputSection : Element msg
dynamicInputSection =
    section "DynamicInput"
        "A list of values, each row an input (or key / value pair) with add / remove / sort actions. Pure list core: `insertAt` / `removeAt` / `moveUp` / `moveDown`, guarded by `min` / `max`."
        dynamicInputRows


pairLiveRow : Model -> Element Msg
pairLiveRow model =
    demoRow "Dynamic Input · pair list editor" [ pairDemo theme model ]


dynamicInputLiveSection : Model -> Element Msg
dynamicInputLiveSection model =
    section "DynamicInput"
        "A list of values, each row an input (or key / value pair) with add / remove / sort actions. Pure list core: `insertAt` / `removeAt` / `moveUp` / `moveDown`, guarded by `min` / `max`."
        (dynamicInputRows ++ [ pairLiveRow model ])



-- 1 · TABLE


tableDemo : Theme -> Model -> Element Msg
tableDemo theme model =
    let
        tD =
            Table.defaults

        cD =
            Table.cellDefaults

        rD =
            Table.rowDefaults

        header =
            { rD
                | cells =
                    [ { cD | content = [ Element.text "Fruit" ] }
                    , { cD | content = [ Element.text "Taste" ] }
                    ]
            }

        fruitRow ( name, taste ) =
            { rD
                | attributes =
                    [ HE.onClick (TablePick name)
                    , HA.id ("live-data-table-row-" ++ name)
                    ]
                , cells =
                    [ { cD | content = [ Element.text name ] }
                    , { cD | content = [ Element.text taste ] }
                    ]
            }

        rows =
            List.map fruitRow [ ( "Yuzu", "sharp" ), ( "Mango", "sweet" ), ( "Umeboshi", "sour" ) ]
    in
    Element.column [ Element.spacing 10 ]
        [ Table.view theme tD { head = [ header ], body = rows }
        , caption [ "picked: " ++ Maybe.withDefault "—" model.tablePick ]
        , note theme
            "NUI.Table is the port's fully-static table — no channel in Options by design. The row click rides the documented Row.attributes seam (upstream's bare <tr> wrapper), not a faked channel."
        ]


tableRows : List (Element msg)
tableRows =
    [ demoRow "Basic (defaults: bordered, bottom-bordered, single-line)"
        [ Table.view theme tableD tableContent
        ]
    , demoRow "Sizes · un-bordered · multi-line"
        [ Table.view theme { tableD | size = Table.Small } tableContent
        , Table.view theme { tableD | size = Table.Large, bordered = False, bottomBordered = False } tableContent
        ]
    , demoRow "Striped · single-column · multi-line cells"
        [ Table.view theme { tableD | striped = True, singleLine = False } tableContent
        , Table.view theme { tableD | singleColumn = True } tableContent
        ]
    , demoRow "Colspan / rowspan"
        [ Table.view theme tableD spanContent
        ]
    , demoRow "RTL"
        [ Table.view theme { tableD | rtl = True } tableContent
        ]
    ]


tableSection : Element msg
tableSection =
    section "Table"
        "Naive UI's static table — the real `<table class=\"n-table\">` root (six modifier classes, the 21 `--n-*` vars with the three size-keyed ones resolved) over a typed `thead` / `tbody` tree of `th` / `td` cells (`colspan` / `rowspan` first-class, `Element` content embedded through `display: contents`). Fully static — nothing runtime."
        tableRows


tableLiveRow : Model -> Element Msg
tableLiveRow model =
    demoRow "Table · row state (Row.attributes seam)" [ tableDemo theme model ]


tableLiveSection : Model -> Element Msg
tableLiveSection model =
    section "Table"
        "Naive UI's static table — the real `<table class=\"n-table\">` root (six modifier classes, the 21 `--n-*` vars with the three size-keyed ones resolved) over a typed `thead` / `tbody` tree of `th` / `td` cells (`colspan` / `rowspan` first-class, `Element` content embedded through `display: contents`). Fully static — nothing runtime."
        (tableRows ++ [ tableLiveRow model ])



-- 3 · TREE


treeData : List (Tree.TreeOption Msg)
treeData =
    [ Tree.TreeOption
        { key = "radiohead"
        , label = "Radiohead"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children = Just [ leafOption "ok" "OK Computer", leafOption "kid" "Kid A" ]
        , prefix = []
        , suffix = []
        }
    , Tree.TreeOption
        { key = "talk"
        , label = "Talk Talk"
        , disabled = False
        , checkboxDisabled = False
        , isLeaf = False
        , children = Just [ leafOption "spirit" "Spirit of Eden" ]
        , prefix = []
        , suffix = []
        }
    , leafOption "solo" "Solo Act"
    , Tree.TreeOption
        { key = "banned"
        , label = "Disabled Leaf"
        , disabled = True
        , checkboxDisabled = False
        , isLeaf = True
        , children = Nothing
        , prefix = []
        , suffix = []
        }
    ]


treeKeyOf : Tree.TreeOption Msg -> String
treeKeyOf (Tree.TreeOption raw) =
    raw.key


treeInfo : String -> List (Tree.TreeOption Msg) -> Maybe { disabled : Bool }
treeInfo key options =
    case options of
        [] ->
            Nothing

        (Tree.TreeOption raw) :: rest ->
            if raw.key == key then
                Just { disabled = raw.disabled }

            else
                case raw.children of
                    Just kids ->
                        case treeInfo key kids of
                            Just info ->
                                Just info

                            Nothing ->
                                treeInfo key rest

                    Nothing ->
                        treeInfo key rest


treeOpts : Model -> Tree.Options Msg
treeOpts model =
    let
        tD =
            Tree.defaults
    in
    { tD
        | data = treeData
        , expandedKeys = model.treeExpanded
        , checkedKeys = model.treeChecked
        , selectedKeys = model.treeSelected
        , checkable = True
        , cascade = True
        , checkOnClick = True
        , blockLine = True
        , nodeProps =
            Just
                (\option ->
                    [ Element.htmlAttribute (HE.onClick (TreeNodeClick (treeKeyOf option)))
                    , Element.htmlAttribute (HA.id ("live-data-tree-" ++ treeKeyOf option))
                    ]
                )
        , attributes = [ Element.htmlAttribute (HA.id "live-data-tree") ]
    }


treeDemo : Theme -> Model -> Element Msg
treeDemo theme model =
    let
        normalized =
            Tree.getCheckedKeys True Tree.All False model.treeChecked treeData
    in
    Element.column [ Element.spacing 10 ]
        [ Tree.view theme (treeOpts model)
        , caption
            [ "checked: " ++ listLabel normalized.checkedKeys
            , "half-checked: " ++ listLabel normalized.indeterminateKeys
            , "selected: " ++ listLabel model.treeSelected
            , "expanded: " ++ listLabel model.treeExpanded
            ]
        , note theme
            "The port renders every tree state as data — switcher and checkbox clicks are not channelled, so the row click (nodeProps, on the node div under blockLine) drives all three: expand (toggleExpand), select (toggleSelect) and check (treemate check/uncheck under checkOnClick, with the cascade re-normalized through getCheckedKeys)."
        ]


treeRows : List (Element msg)
treeRows =
    [ demoRow "Basic · checkable (cascade, Child strategy)"
        [ Tree.view theme
            { treeD | data = treeOptions, expandedKeys = [ "beatles", "stones" ] }
        , Tree.view theme
            { treeD
                | data = treeOptions
                , expandedKeys = [ "beatles" ]
                , checkable = True
                , cascade = True
                , checkStrategy = Tree.Child
                , checkedKeys = [ "drive", "nowhere" ]
            }
        ]
    , demoRow "Multiple selection · showLine"
        [ Tree.view theme
            { treeD
                | data = treeOptions
                , expandedKeys = [ "beatles" ]
                , multiple = True
                , selectedKeys = [ "drive", "exile" ]
            }
        , Tree.view theme
            { treeD | data = treeOptions, expandedKeys = [ "beatles", "stones" ], showLine = True }
        ]
    , demoRow "block-line + ellipsis · pending + highlight"
        [ Tree.view theme
            { treeD
                | data = treeOptions
                , expandedKeys = [ "beatles" ]
                , blockLine = True
                , ellipsis = True
                , pendingKey = Just "nowhere"
                , highlightKeys = Just [ "revolver" ]
            }
        ]
    , demoRow "Loading switcher · empty"
        [ Tree.view theme
            { treeD | data = treeOptions, expandedKeys = [ "beatles", "stones" ], loadingKeys = [ "stones" ] }
        , Tree.view theme { treeD | attributes = [ Element.width (Element.px 240) ] }
        ]
    ]


treeSection : Element msg
treeSection =
    section "Tree"
        "Naive UI's tree — the `div.n-tree` root (17 `--n-*` vars; three derived from the wrapper-padding/height strings) rendering the flattened visible nodes as `n-tree-node-wrapper` rows: a `showLine` indent chain, the switcher (arrow svg, the loading spinner for `loadingKeys` keys — sw20/r85 baseline under the `spin*` overrides), the `data-checkbox`-wrapped `NUI.Checkbox` (cascade-checked via the shipped treemate helpers), and the prefix/label/suffix content. Everything interactive is data: `expandedKeys` / `checkedKeys` / `selectedKeys` / `pendingKey` / `loadingKeys` / `dropMark`; the pure helpers (`flatten`, `getCheckedKeys`, `check` / `uncheck`, `toggleExpand`, `toggleSelect`, `getNonLeafKeys`, `filterTree`) do the treemate math. Not ported: virtual list, expand motion, drag/keyboard events."
        treeRows


treeLiveRow : Model -> Element Msg
treeLiveRow model =
    demoRow "Tree · check + expand + select (nodeProps seam)" [ treeDemo theme model ]


treeLiveSection : Model -> Element Msg
treeLiveSection model =
    section "Tree"
        "Naive UI's tree — the `div.n-tree` root (17 `--n-*` vars; three derived from the wrapper-padding/height strings) rendering the flattened visible nodes as `n-tree-node-wrapper` rows: a `showLine` indent chain, the switcher (arrow svg, the loading spinner for `loadingKeys` keys — sw20/r85 baseline under the `spin*` overrides), the `data-checkbox`-wrapped `NUI.Checkbox` (cascade-checked via the shipped treemate helpers), and the prefix/label/suffix content. Everything interactive is data: `expandedKeys` / `checkedKeys` / `selectedKeys` / `pendingKey` / `loadingKeys` / `dropMark`; the pure helpers (`flatten`, `getCheckedKeys`, `check` / `uncheck`, `toggleExpand`, `toggleSelect`, `getNonLeafKeys`, `filterTree`) do the treemate math. Not ported: virtual list, expand motion, drag/keyboard events."
        (treeRows ++ [ treeLiveRow model ])



-- 6 · IMAGE PREVIEW (full toolbar)


liveImageLogo : String
liveImageLogo =
    "https://www.naiveui.com/assets/naivelogo.93278402.svg"


previewSrcs : List String
previewSrcs =
    [ "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
    , liveImageLogo
    ]


{-| Measurement is caller-owned (natural size + window) — simulated with
fixed values, exactly what a ports-less host would pin. The record is
structural (`ImagePreview.maxScale` / `originalSizeScale` input shape).
-}
fakeMetrics =
    { naturalWidth = 160, naturalHeight = 120, innerWidth = 1920, innerHeight = 1080 }


fakeViewport : ImagePreview.Viewport
fakeViewport =
    { width = 1920, height = 1080 }


previewMaxScale : Float
previewMaxScale =
    ImagePreview.maxScale fakeMetrics


previewOriginalScale : Float
previewOriginalScale =
    ImagePreview.originalSizeScale fakeMetrics


fakeRect : ImagePreview.Zoom -> ImagePreview.Rect
fakeRect zoom =
    let
        width =
            fakeMetrics.naturalWidth * zoom.scale

        height =
            fakeMetrics.naturalHeight * zoom.scale

        left =
            (fakeViewport.width - width) / 2 + zoom.offsetX

        top =
            (fakeViewport.height - height) / 2 + zoom.offsetY
    in
    { left = left
    , top = top
    , width = width
    , height = height
    , right = left + width
    , bottom = top + height
    }


previewOpts : Model -> ImagePreview.Options Msg
previewOpts model =
    let
        pD =
            ImagePreview.defaults

        src =
            List.drop model.previewIndex previewSrcs
                |> List.head
                |> Maybe.withDefault liveImageLogo
    in
    { pD
        | show = True
        , src = Just src
        , zoom = model.previewZoom
        , imgDerived = model.previewDerived
        , onPrev = Just PreviewPrev
        , onNext = Just PreviewNext
        , onClose = Just PreviewClose
        , onZoomIn = Just PreviewZoomIn
        , onZoomOut = Just PreviewZoomOut
        , onRotateClockwise = Just PreviewRotateClockwise
        , onRotateCounterclockwise = Just PreviewRotateCounterclockwise
        , onOriginalSize = Just PreviewOriginalSize
        , onDownload = Just PreviewDownload
        , onImgDblclick = Just PreviewDblclick
        , attributes = [ Element.htmlAttribute (HA.id "live-data-image-preview") ]
    }


previewDemo : Theme -> Model -> Element Msg
previewDemo theme model =
    let
        imageD_ =
            Image.defaults

        thumb index src =
            Image.view theme
                { imageD_
                    | src = Just src
                    , width = Just "120"
                    , height = Just "90"
                    , onClick = Just (PreviewOpen index)
                    , attributes = [ Element.htmlAttribute (HA.id ("live-data-image-" ++ String.fromInt index)) ]
                }
    in
    Element.column [ Element.spacing 10 ]
        [ Element.row [ Element.spacing 8 ] (List.indexedMap thumb previewSrcs)
        , caption
            [ "src: " ++ String.fromInt model.previewIndex
            , "scale: " ++ String.fromFloat model.previewZoom.scale
            , "rotate: " ++ String.fromFloat model.previewZoom.rotate ++ "°"
            , model.previewNote
            ]
        , note theme
            "The full toolbar algebra is pure state: zoomIn / zoomOut (with the derivedOffset clamp step over simulated measurements — real measurement is the caller's port), rotate both ways, resize/toggle original size, prev/next with switchReset, and dblclick's toggleOriginalSize. Open preview mounts as a fixed overlay; close unmounts it (displayDirective: 'if')."
        , if model.previewShow then
            ImagePreview.view theme (previewOpts model)

          else
            Element.none
        ]


imageRows : List (Element msg)
imageRows =
    [ demoRow "Basic + object-fit (fixed state)"
        [ cell
            (Image.view theme
                { imageD
                    | src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                    , width = Just "160"
                    , height = Just "120"
                }
            )
        , cell
            (Image.view theme
                { imageD
                    | src = Just imageLogo
                    , width = Just "160"
                    , height = Just "120"
                    , objectFit = Image.Contain
                }
            )
        , cell
            (Image.view theme
                { imageD
                    | src = Just imageLogo
                    , width = Just "160"
                    , height = Just "120"
                    , objectFit = Image.Cover
                    , alt = Just "Cover fit"
                }
            )
        ]
    , demoRow "Error → fallbackSrc + error slot (fixed state)"
        [ cell
            (Image.view theme
                { imageD
                    | src = Just "https:// 07akioni.oss-cn-beijing.aliyuncs.com/broken.jpeg"
                    , fallbackSrc = Just imageLogo
                    , showError = True
                    , width = Just "160"
                    , height = Just "120"
                }
            )
        , cell
            (Image.view theme
                { imageD
                    | src = Just "https:// 07akioni.oss-cn-beijing.aliyuncs.com/broken.jpeg"
                    , showError = True
                    , error = Just (Element.text "Load failed")
                    , width = Just "160"
                    , height = Just "120"
                }
            )
        ]
    , demoRow "Placeholder (img hidden 0×0 until loaded) + preview-disabled + lazy"
        [ cell
            (Image.view theme
                { imageD
                    | src = Just imageLogo
                    , width = Just "160"
                    , height = Just "120"
                    , placeholder = Just (Element.text "Placeholder")
                }
            )
        , cell
            (Image.view theme
                { imageD
                    | src = Just imageLogo
                    , width = Just "160"
                    , height = Just "120"
                    , previewDisabled = True
                }
            )
        , cell
            (Image.view theme
                { imageD
                    | src = Just imageLogo
                    , width = Just "160"
                    , height = Just "120"
                    , lazy = True
                }
            )
        ]
    ]


imageSection : Element msg
imageSection =
    section "Image"
        "The img surface (upstream `NImage`): `n-image` root + img with the full upstream attribute pack (`data-error`, `data-preview-src`, `data-group-id`, native `loading`, `object-fit`). Load/error/lazy state is caller-owned — `showError` flips the img to `fallbackSrc` + the `--preview-disabled` class, or swaps in the error slot replacing the img entirely; a `placeholder` renders while `loaded` is False and hides the img 0×0 (upstream bytes). The preview modal is the caller's seam (`onClick` + the preview-container `cssVars`)."
        imageRows


previewLiveRow : Model -> Element Msg
previewLiveRow model =
    demoRow "Image · click to preview (full toolbar)" [ previewDemo theme model ]


imageLiveSection : Model -> Element Msg
imageLiveSection model =
    section "Image"
        "The img surface (upstream `NImage`): `n-image` root + img with the full upstream attribute pack (`data-error`, `data-preview-src`, `data-group-id`, native `loading`, `object-fit`). Load/error/lazy state is caller-owned — `showError` flips the img to `fallbackSrc` + the `--preview-disabled` class, or swaps in the error slot replacing the img entirely; a `placeholder` renders while `loaded` is False and hides the img 0×0 (upstream bytes). The preview modal is the caller's seam (`onClick` + the preview-container `cssVars`)."
        (imageRows ++ [ previewLiveRow model ])



-- 7 · IMAGE GROUP


gallery : List String
gallery =
    [ "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
    , liveImageLogo
    , "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
    ]


groupOpts : Model -> ImageGroup.Options Msg
groupOpts model =
    let
        gD =
            ImageGroup.defaults
    in
    { gD
        | srcList = gallery
        , current = model.groupCurrent
        , show = True
        , zoom = model.groupZoom
        , onPrev = Just GroupPrev
        , onNext = Just GroupNext
        , onClose = Just GroupClose
        , attributes = [ Element.htmlAttribute (HA.id "live-data-image-group") ]
    }


groupDemo : Theme -> Model -> Element Msg
groupDemo theme model =
    let
        imageD_ =
            Image.defaults

        thumb index src =
            Image.view theme
                { imageD_
                    | src = Just src
                    , width = Just "100"
                    , height = Just "75"
                    , onClick = Just (GroupOpen index)
                    , attributes = [ Element.htmlAttribute (HA.id ("live-data-group-thumb-" ++ String.fromInt index)) ]
                }
    in
    Element.column [ Element.spacing 10 ]
        [ Element.row [ Element.spacing 8 ] (List.indexedMap thumb gallery)
        , caption
            [ "current: p" ++ String.fromInt model.groupCurrent
            , "show: " ++ boolLabel model.groupShow
            ]
        , note theme
            "Click a thumbnail to open the group preview at that index (showImage over the p${index} registry); the toolbar prev/next route through the reset + go step (switchReset then ImageGroup.go, the wrap-around walk that skips empty urls); close unmounts."
        , if model.groupShow then
            ImageGroup.view theme (groupOpts model)

          else
            Element.none
        ]


imagePreviewRows : List (Element msg)
imagePreviewRows =
    [ demoRow "Standalone preview (fixed state: open, zoom identity)"
        [ modalHost []
            (ImagePreview.view theme
                { previewD
                    | show = True
                    , src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                }
            )
        ]
    , demoRow "Zoom/rotate state + previewed-img props (8px white frame)"
        [ modalHost []
            (ImagePreview.view theme
                { previewD
                    | show = True
                    , src = Just imageLogo
                    , zoom = { previewZoom0 | scale = 1.5, scaleExp = 1, rotate = 90 }
                    , imgDerived = True
                    , previewedImgStyle = [ ( "border", "8px solid white" ) ]
                }
            )
        ]
    , demoRow "Toolbar suppressed + drag state (grabbing cursor, no transition)"
        [ modalHost []
            (ImagePreview.view theme
                { previewD
                    | show = True
                    , src = Just imageLogo
                    , showToolbar = False
                }
            )
        , modalHost []
            (ImagePreview.view theme
                { previewD
                    | show = True
                    , src = Just imageLogo
                    , dragging = True
                    , imgDerived = True
                    , previewedImgStyle = [ ( "border", "8px solid white" ) ]
                }
            )
        ]
    , demoRow "Group (srcList registry, second image current; slot thumbnails beside)"
        [ cell
            (Element.row [ Element.spacing 8 ]
                [ Image.view theme
                    { imageD | src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg", width = Just "80", height = Just "60" }
                , Image.view theme
                    { imageD | src = Just imageLogo, width = Just "80", height = Just "60" }
                ]
            )
        , modalHost []
            (ImageGroup.view theme
                { groupD
                    | show = True
                    , srcList =
                        [ "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                        , imageLogo
                        , imageLogo
                        ]
                    , current = 1
                }
            )
        ]
    ]


imagePreviewSection : Element msg
imagePreviewSection =
    section "Image Preview & Group"
        "The preview modal family (upstream `NImagePreview`/`NImageGroup`): container (the five toolbar `--n-*` vars) > overlay (click-to-close seat) > toolbar (prev/next only when `onPrev` is set — upstream keys both on `onPrev` — then rotate CCW/CW, original size, zoomOut, zoomIn, download, close) > wrapper > `img.n-image-preview`. The runtime is caller-owned (`NUI.Modal` precedent): `zoom` starts at `zoom0` and moves through the pure transforms (`zoomIn`/`zoomOut`/`rotateClockwise`/`resizeToOriginalSize`/`toggleOriginalSize`/`switchReset`), drag clamps through `moveStrategy` + `derivedOffset`, document keys map through `keyAction`, and `syncTransformOrigin` writes the thumbnail's center into `wrapperStyle`. The group adds the url registry (`srcList` wins with `p${index}` keys, else the caller-threaded `registered` ids) and the wrap-around walk (`nextIndex`/`prevIndex` skip empty urls). Demo cells confine the fixed tree like the modal demos."
        imagePreviewRows


groupLiveRow : Model -> Element Msg
groupLiveRow model =
    demoRow "Image Group · gallery walk" [ groupDemo theme model ]


imagePreviewLiveSection : Model -> Element Msg
imagePreviewLiveSection model =
    section "Image Preview & Group"
        "The preview modal family (upstream `NImagePreview`/`NImageGroup`): container (the five toolbar `--n-*` vars) > overlay (click-to-close seat) > toolbar (prev/next only when `onPrev` is set — upstream keys both on `onPrev` — then rotate CCW/CW, original size, zoomOut, zoomIn, download, close) > wrapper > `img.n-image-preview`. The runtime is caller-owned (`NUI.Modal` precedent): `zoom` starts at `zoom0` and moves through the pure transforms (`zoomIn`/`zoomOut`/`rotateClockwise`/`resizeToOriginalSize`/`toggleOriginalSize`/`switchReset`), drag clamps through `moveStrategy` + `derivedOffset`, document keys map through `keyAction`, and `syncTransformOrigin` writes the thumbnail's center into `wrapperStyle`. The group adds the url registry (`srcList` wins with `p${index}` keys, else the caller-threaded `registered` ids) and the wrap-around walk (`nextIndex`/`prevIndex` skip empty urls). Demo cells confine the fixed tree like the modal demos."
        (imagePreviewRows ++ [ groupLiveRow model ])



-- 2 · DATA TABLE


type alias Person =
    { name : String
    , age : Int
    , address : String
    }


person : String -> Int -> String -> Person
person name age address =
    { name = name, age = age, address = address }


people : List Person
people =
    [ person "Jesse Tripps" 28 "0350 Nesrnew Drive, Bellevue, WA"
    , person "Jaime Whyte" 32 "1512 Radney Street, Dallas, TX"
    , person "Boris Wuhrer" 41 "785 Skiles Walks, Roseville, WA"
    , person "Terry Malany" 22 "752 Sutter Avenue, Sacramento, CA"
    , person "Mila Parly" 36 "419 Ridgewood Lane, Portland, OR"
    , person "Ade Nwachukwu" 45 "88 Larkspur Court, Austin, TX"
    , person "Greta Sund" 19 "203 Alder Street, Eugene, OR"
    , person "Ravi Menon" 51 "630 Birch Alley, Denver, CO"
    ]


dtColumns : List (DataTable.Column Person Msg)
dtColumns =
    let
        colD =
            DataTable.columnDefaults

        selection =
            { colD | kind = DataTable.KindSelection, multiple = True }

        nameCol =
            { colD | key = "name", title = "Name", view = \p -> Element.text p.name }

        ageCol =
            { colD
                | key = "age"
                , title = "Age"
                , width = Just 110
                , align = Just DataTable.AlignCenter
                , view = \p -> Element.text (String.fromInt p.age)
                , sorter = Just (DataTable.SorterBy (\a b -> compare a.age b.age))
            }

        addressCol =
            { colD
                | key = "address"
                , title = "Address"
                , width = Just 320
                , view = \p -> Element.text p.address
            }
    in
    [ selection, nameCol, ageCol, addressCol ]


dtOpts : Model -> DataTable.Options Person Msg
dtOpts model =
    let
        dtD =
            DataTable.defaults

        pgD =
            Pagination.defaults
    in
    { dtD
        | columns = dtColumns
        , data = people
        , rowKey = .name
        , checkedRowKeys = model.dtChecked
        , lastSelectedKey = model.dtLastSelected
        , onUpdateCheckedRowKeys = Just DtCheck
        , sortStates = model.dtSort
        , onSorterChange = Just DtSort
        , pagination = Just { pgD | currentPage = model.dtPage, pageSize = Just model.dtPageSize }
        , onUpdatePage = Just DtPage
        , onUpdatePageSize = Just DtPageSize
        , attributes = [ Element.htmlAttribute (HA.id "live-data-table") ]
    }


dataTableDemo : Theme -> Model -> Element Msg
dataTableDemo theme model =
    let
        opts =
            dtOpts model

        lastPage =
            ceiling (toFloat (List.length people) / toFloat (DataTable.mergedPageSize opts))

        sortLabel =
            case List.filter (\s -> s.order /= DataTable.NoSort) opts.sortStates of
                s :: _ ->
                    "sort: "
                        ++ s.columnKey
                        ++ " "
                        ++ (if s.order == DataTable.Descend then
                                "↓"

                            else
                                "↑"
                           )

                [] ->
                    "sort: none"

        btn =
            Button.defaults
    in
    Element.column [ Element.spacing 10, Element.width (Element.px 780) ]
        [ DataTable.view theme opts
        , Element.row
            [ Element.spacing 6 ]
            [ Button.view theme
                { btn | size = T.Tiny, onPress = Just (DtPageSize 4) }
                [ Element.text "4 / page" ]
            , Button.view theme
                { btn | size = T.Tiny, onPress = Just (DtPageSize 8) }
                [ Element.text "8 / page" ]
            ]
        , caption
            [ "checked: " ++ listLabel opts.checkedRowKeys
            , "anchor: "
                ++ (if opts.lastSelectedKey == "" then
                        "—"

                    else
                        opts.lastSelectedKey
                   )
            , "page: " ++ String.fromInt (DataTable.boundedPage opts) ++ " / " ++ String.fromInt lastPage
            , sortLabel
            ]
        , note theme
            "One table, three live behaviors: the checkbox column (header + rows + the shift-click range), the Age sorter header click (sort runs in the render pipeline off sortStates), and the pager (rows slice through paginatedData — boundedPage clamps). The pager's own size picker is documented-unported, so page size rides the same onUpdatePageSize channel from the two buttons."
        ]


dataTableRows : List (Element msg)
dataTableRows =
    let
        dtD =
            DataTable.defaults

        colD =
            DataTable.columnDefaults

        person_ name age address =
            { name = name
            , age = age
            , address = address
            }

        people_ =
            [ person_ "Jesse Tripps" 28 "0350 Nesrnew Drive, Bellevue, WA"
            , person_ "Jaime Whyte" 32 "1512 Radney Street, Dallas, TX"
            , person_ "Boris Wuhrer" 41 "785 Skiles Walks, Roseville, WA"
            , person_ "Terry Malany" 22 "752 Sutter Avenue, Sacramento, CA"
            ]

        nameCol =
            { colD | key = "name", title = "Name", view = \p -> Element.text p.name }

        ageCol =
            { colD
                | key = "age"
                , title = "Age"
                , view = \p -> Element.text (String.fromInt p.age)
                , width = Just 120
                , align = Just DataTable.AlignCenter
            }

        addressCol =
            { colD | key = "address", title = "Address", view = \p -> Element.text p.address }

        columns =
            [ nameCol, ageCol, addressCol ]

        ageSorter =
            DataTable.SorterBy (\a b -> compare a.age b.age)

        sortableColumns =
            [ nameCol, { ageCol | sorter = Just ageSorter }, addressCol ]

        filterColumns =
            [ nameCol
            , ageCol
            , { addressCol
                | filter =
                    Just
                        (DataTable.FilterCustom
                            (\value p -> String.contains value p.address)
                        )
                , filterOptions =
                    Just
                        [ { label = "Bellevue, WA", value = "Bellevue" }
                        , { label = "Dallas, TX", value = "Dallas" }
                        , { label = "Roseville, WA", value = "Roseville" }
                        ]
              }
            ]

        ageDescend =
            { columnKey = "age", order = DataTable.Descend, sorter = ageSorter }

        summaryPeople =
            List.range 0 9
                |> List.map (\i -> { name = String.fromInt i, age = i })

        summaryColumns =
            [ { colD | key = "name", title = "Name", view = \p -> Element.text p.name }
            , { colD | key = "age", title = "Age", view = \p -> Element.text (String.fromInt p.age) }
            ]

        summaryOf rows =
            let
                total =
                    rows
                        |> List.map .age
                        |> List.sum
                        |> String.fromInt
                        |> Element.text
            in
            [ [ ( "name", { value = Just total, colSpan = Just 1, rowSpan = Just 2 } )
              , ( "age", { value = Just total, colSpan = Just 2, rowSpan = Just 1 } )
              ]
            ]

        dtPg =
            Pagination.defaults
    in
    [ demoRow "Basic"
        [ DataTable.view theme
            { dtD | columns = columns, data = people_, rowKey = .name }
        ]
    , demoRow "Striped + bordered"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , striped = True
            }
        ]
    , demoRow "Empty"
        [ DataTable.view theme
            { dtD | columns = columns, data = [], rowKey = .name }
        ]
    , demoRow "Sorting"
        [ DataTable.view theme
            { dtD | columns = sortableColumns, data = people_, rowKey = .name }
        , DataTable.view theme
            { dtD
                | columns = sortableColumns
                , data = people_
                , rowKey = .name
                , sortStates =
                    DataTable.defaultSortStates sortableColumns
                        |> List.map
                            (\state ->
                                if state.columnKey == "age" then
                                    { state | order = DataTable.Descend }

                                else
                                    state
                            )
            }
        ]
    , demoRow "Pagination"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , pagination = Just { dtPg | pageSize = Just 2 }
            }
        ]
    , demoRow "Sort + pagination"
        [ DataTable.view theme
            { dtD
                | columns = sortableColumns
                , data = people_
                , rowKey = .name
                , sortStates = [ ageDescend ]
                , pagination =
                    Just
                        { dtPg
                            | pageSize = Just 2
                            , currentPage = 2
                        }
            }
        ]
    , demoRow "Filter"
        [ DataTable.view theme
            { dtD | columns = filterColumns, data = people_, rowKey = .name }
        , DataTable.view theme
            { dtD
                | columns = filterColumns
                , data = people_
                , rowKey = .name
                , filterStates = [ ( "address", DataTable.FilterMany [ "Bellevue" ] ) ]
            }
        ]
    , demoRow "Selection"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { colD | kind = DataTable.KindSelection, disabled = Just (\p -> p.age >= 40) }
                    , nameCol
                    , ageCol
                    , addressCol
                    ]
                , data = people_
                , rowKey = .name
                , checkedRowKeys = [ "Jaime Whyte", "Boris Wuhrer" ]
            }
        ]
    , demoRow "Selection (single)"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { colD | kind = DataTable.KindSelection, multiple = False }
                    , nameCol
                    , ageCol
                    ]
                , data = people_
                , rowKey = .name
                , checkedRowKeys = [ "Boris Wuhrer", "Jesse Tripps" ]
            }
        ]
    , demoRow "Selection extra"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { colD
                        | kind = DataTable.KindSelection
                        , options = [ DataTable.SelectionAll, DataTable.SelectionNone ]
                      }
                    , nameCol
                    , ageCol
                    ]
                , data = people_
                , rowKey = .name
                , checkedRowKeys = [ "Terry Malany" ]
            }
        ]
    , demoRow "Expand"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { colD
                        | kind = DataTable.KindExpand
                        , renderExpand = Just (\p _ -> Element.text (p.name ++ " — " ++ p.address))
                        , expandable = Just (\p -> p.age > 30)
                      }
                    , nameCol
                    , ageCol
                    ]
                , data = people_
                , rowKey = .name
                , expandedRowKeys = [ "Boris Wuhrer" ]
            }
        ]
    , demoRow "Scroll X + fixed columns"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { nameCol | fixed = Just DataTable.FixedLeft, width = Just 150 }
                    , ageCol
                    , { colD | key = "note", title = "Note", view = \p -> Element.text (p.address ++ " — some long note column") }
                    , { addressCol | fixed = Just DataTable.FixedRight, width = Just 220 }
                    ]
                , data = people_
                , rowKey = .name
                , scrollX = Just 600
            }
        ]
    , demoRow "Max height (discrete header)"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , maxHeight = Just 120
            }
        ]
    , demoRow "Flex height"
        [ Element.el [ Element.height (Element.px 220), Element.width Element.fill ]
            (DataTable.view theme
                { dtD
                    | columns = columns
                    , data = people_
                    , rowKey = .name
                    , flexHeight = True
                }
            )
        ]
    , demoRow "Ellipsis"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { colD
                        | key = "name"
                        , title = "Name"
                        , view = \p -> Element.text (p.name ++ " — " ++ p.address)
                        , ellipsis = Just DataTable.EllipsisPlain
                        , width = Just 160
                      }
                    , ageCol
                    ]
                , data = people_
                , rowKey = .name
            }
        ]
    , demoRow "Loading"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , loading = True
            }
        ]
    , demoRow "Table layout fixed"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , tableLayout = DataTable.TableFixed
            }
        ]
    , demoRow "Group header"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { nameCol | width = Just 100 }
                    , { colD
                        | key = "age"
                        , title = "Age"
                        , width = Just 100
                        , children =
                            Just
                                [ DataTable.ColumnChild
                                    { colD
                                        | key = "test1"
                                        , title = "test1"
                                        , view = \p -> Element.text (String.fromInt p.age)
                                    }
                                , DataTable.ColumnChild
                                    { colD
                                        | key = "test2"
                                        , title = "test2"
                                        , view = \p -> Element.text p.address
                                    }
                                ]
                      }
                    ]
                , data = people_
                , rowKey = .name
            }
        ]
    , demoRow "Summary (Σ45 · bottom / top)"
        [ DataTable.view theme
            { dtD
                | columns = summaryColumns
                , data = summaryPeople
                , rowKey = .name
                , summary = Just summaryOf
            }
        , DataTable.view theme
            { dtD
                | columns = summaryColumns
                , data = summaryPeople
                , rowKey = .name
                , summary = Just summaryOf
                , summaryPlacement = DataTable.SummaryTop
            }
        ]

    -- Merge cells (the docs' merge-cell shape): a vertical merge on Name
    -- (row 0 spans rows 0–1) plus a horizontal merge on Age (row 0 spans the
    -- Age + Address tracks). The merged tracks land on Address / the Name
    -- row-span, so every row still paints its own Age cell and no row is
    -- left with zero cells (the old colspan=3 across the Age track swallowed
    -- Age for both spanned rows and blanked row 1 completely).
    , demoRow "Merge cells (row 0 · colspan 2 / rowspan 2)"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { nameCol
                        | rowSpan =
                            Just
                                (\_ rowIndex ->
                                    if rowIndex == 0 then
                                        2

                                    else
                                        1
                                )
                      }
                    , { ageCol
                        | colSpan =
                            Just
                                (\_ rowIndex ->
                                    if rowIndex == 0 then
                                        2

                                    else
                                        1
                                )
                      }
                    , addressCol
                    ]
                , data = people_
                , rowKey = .name
            }
        ]
    ]


dataTableSection : Element msg
dataTableSection =
    section "Data Table"
        "The advanced table (upstream `NDataTable`) — column definitions drive the colgroup, header cells and body cells; `rowKey` keys rows and the empty state renders `NEmpty`. Selection (checkbox / radio / extra menu), row expansion, scroll-X / fixed columns / max-height / flex-height (the discrete-header split), ellipsis columns, the loading overlay, the filter surface (trigger, pipeline, exported `filterMenu` body) and the structure extras — group headers (`children`), summary rows (`summary` / `summaryPlacement`) and merge cells (`colSpan` / `rowSpan` / `titleColSpan` — a swallowed slot renders no td) — ship in this batch, on top of sorting and pagination. The sort / page / checked / expanded / filter state is caller-owned — this page is static, so nothing is wired (the open menu is the caller's `NUI.Popover` runtime)."
        dataTableRows


dataTableLiveRow : Model -> Element Msg
dataTableLiveRow model =
    demoRow "Data Table · selection + sort + pagination" [ dataTableDemo theme model ]


dataTableLiveSection : Model -> Element Msg
dataTableLiveSection model =
    section "Data Table"
        "The advanced table (upstream `NDataTable`) — column definitions drive the colgroup, header cells and body cells; `rowKey` keys rows and the empty state renders `NEmpty`. Selection (checkbox / radio / extra menu), row expansion, scroll-X / fixed columns / max-height / flex-height (the discrete-header split), ellipsis columns, the loading overlay, the filter surface (trigger, pipeline, exported `filterMenu` body) and the structure extras — group headers (`children`), summary rows (`summary` / `summaryPlacement`) and merge cells (`colSpan` / `rowSpan` / `titleColSpan` — a swallowed slot renders no td) — ship in this batch, on top of sorting and pagination. The sort / page / checked / expanded / filter state is caller-owned — this page is static, so nothing is wired (the open menu is the caller's `NUI.Popover` runtime)."
        (dataTableRows ++ [ dataTableLiveRow model ])



-- 4 · TRANSFER


transferOptions : List Transfer.Option
transferOptions =
    [ { label = "Option 1", value = "1", disabled = False }
    , { label = "Option 2", value = "2", disabled = False }
    , { label = "Option 3", value = "3", disabled = False }
    , { label = "Option 4", value = "4", disabled = False }
    , { label = "Option 5", value = "5", disabled = False }
    , { label = "Disabled", value = "6", disabled = True }
    ]


transferOpts : Model -> Transfer.Options Msg
transferOpts model =
    let
        trD =
            Transfer.defaults
    in
    { trD
        | options = transferOptions
        , value = model.transferValue
        , sourceTitle = Just "Source"
        , targetTitle = Just "Target"
        , sourceFilterable = True
        , targetFilterable = True
        , sourceFilterPlaceholder = Just "Search"
        , sourcePattern = model.transferSourcePattern
        , targetPattern = model.transferTargetPattern
        , onCheck = Just TransferCheck
        , onSourceFilterInput = Just TransferSourceFilter
        , onTargetFilterInput = Just TransferTargetFilter
        , attributes = [ Element.htmlAttribute (HA.id "live-data-transfer") ]
    }


transferDemo : Theme -> Model -> Element Msg
transferDemo theme model =
    Element.column [ Element.spacing 10 ]
        [ Transfer.view theme (transferOpts model)
        , caption
            [ "value: " ++ listLabel model.transferValue
            , "source filter: \"" ++ model.transferSourcePattern ++ "\""
            , "target filter: \"" ++ model.transferTargetPattern ++ "\""
            ]
        , note theme
            "Item toggles, select-all / unselect-all and clear all collapse into the single onCheck channel with the next value list (upstream doUpdateValue); the two filter inputs feed onSourceFilterInput / onTargetFilterInput and ride back in as patterns."
        ]


transferRows : List (Element msg)
transferRows =
    let
        trD =
            Transfer.defaults

        opts =
            [ { label = "Option 1", value = "1", disabled = False }
            , { label = "Option 2", value = "2", disabled = False }
            , { label = "Option 3", value = "3", disabled = False }
            , { label = "Disabled", value = "4", disabled = True }
            ]
    in
    [ demoRow "Basic"
        [ Transfer.view theme
            { trD
                | options = opts
                , value = [ "2" ]
                , sourceTitle = Just "Source"
                , targetTitle = Just "Target"
            }
        ]
    , demoRow "Filterable + large"
        [ Transfer.view theme
            { trD
                | options = opts
                , value = [ "1", "4" ]
                , size = T.Large
                , sourceFilterable = True
                , targetFilterable = True
                , sourceFilterPlaceholder = Just "Search"
            }
        ]
    , demoRow "Disabled + empty target"
        [ Transfer.view theme
            { trD
                | options = opts
                , disabled = True
                , sourceTitle = Just "Source"
            }
        ]
    , demoRow "Empty options"
        [ Transfer.view theme
            { trD | sourceTitle = Just "Source", targetTitle = Just "Target" }
        ]
    , demoRow "All checked + custom texts"
        [ Transfer.view theme
            { trD
                | options = opts
                , value = [ "1", "2", "3", "4" ]
                , selectAllText = Just "Pick everything"
                , clearText = Just "Drop everything"
            }
        ]
    ]


transferSection : Element msg
transferSection =
    section "Transfer"
        "Two lists with select-all / clear — value and patterns are caller-owned."
        transferRows


transferLiveRow : Model -> Element Msg
transferLiveRow model =
    demoRow "Transfer · move + filter" [ transferDemo theme model ]


transferLiveSection : Model -> Element Msg
transferLiveSection model =
    section "Transfer"
        "Two lists with select-all / clear — value and patterns are caller-owned."
        (transferRows ++ [ transferLiveRow model ])



-- 8 · UPLOAD (simulated file list)


fakeFile : Int -> String -> String -> Upload.FileInfo
fakeFile seq name mime =
    Upload.pendingFile
        { id = "f" ++ String.fromInt seq
        , name = name
        , type_ = Just mime
        , fullPath = Nothing
        , batchId = Nothing
        }


fakeImageFile : Int -> Upload.FileInfo
fakeImageFile seq =
    -- the caller writes the resolved thumbnail url (caller-owned
    -- resolution, per the header)
    let
        base =
            fakeFile seq ("shot-" ++ String.fromInt seq ++ ".png") "image/png"
    in
    { base | thumbnailUrl = Just liveImageLogo }


addFakeFile : Model -> (Int -> Upload.FileInfo) -> Model
addFakeFile model build =
    { model
        | files = Upload.appendFile (build model.uploadSeq) model.files
        , uploadSeq = model.uploadSeq + 1
    }


{-| The subscription-free progress ticker: Pending walks Uploading, an
Uploading file at >= 99% settles — Finished, or Error for the simulated
broken upload (so the retry button is reachable). Broken files keep
failing, mirroring a server that always rejects them.
-}
advanceFile : Upload.FileInfo -> Upload.FileInfo
advanceFile file =
    case file.status of
        Upload.Pending ->
            Upload.markUploading 50 file

        Upload.Uploading ->
            if Maybe.withDefault 0 file.percentage >= 99 then
                if String.contains "broken" file.name then
                    Upload.markError file

                else
                    Upload.markFinished file

            else
                Upload.markUploading (Maybe.withDefault 0 file.percentage + 50) file

        _ ->
            file


fileNameOf : String -> List Upload.FileInfo -> String
fileNameOf id files =
    files
        |> List.filter (\f -> f.id == id)
        |> List.head
        |> Maybe.map .name
        |> Maybe.withDefault id


uploadOpts : Theme -> Model -> Upload.Options Msg
uploadOpts theme model =
    let
        uD =
            Upload.defaults

        btn =
            Button.defaults
    in
    { uD
        | fileList = model.files
        , listType = Upload.ImageCard
        , showDownloadButton = True
        , triggerNode =
            Just
                (Button.view theme
                    { btn | onPress = Nothing }
                    [ Element.text "Add file" ]
                )
        , onTriggerClick = Just UploadAdd
        , onFileChange = Just UploadPick
        , onRemove = Just UploadRemove
        , onRetry = Just UploadRetry
        , onPreview = Just UploadPreview
        , onDownload = Just UploadDownload
        , attributes = [ Element.htmlAttribute (HA.id "live-data-upload") ]
    }


uploadDemo : Theme -> Model -> Element Msg
uploadDemo theme model =
    let
        btn =
            Button.defaults

        statusLabel file =
            file.name
                ++ " · "
                ++ statusName file.status
                ++ " "
                ++ String.fromInt (Maybe.withDefault 0 file.percentage)
                ++ "%"
    in
    Element.column [ Element.spacing 10, Element.width Element.fill ]
        [ Upload.view theme (uploadOpts theme model)
        , Element.row [ Element.spacing 6 ]
            [ Button.view theme
                { btn | size = T.Tiny, onPress = Just UploadAddFailing }
                [ Element.text "Add failing file" ]
            , Button.view theme
                { btn | size = T.Tiny, onPress = Just UploadAdvance }
                [ Element.text "Advance progress" ]
            ]
        , caption (List.map statusLabel model.files ++ [ model.uploadNote ])
        , note theme
            "Real pickers and XHR need JS — simulated per the port's caller-owned contract: the trigger click appends a fake pending file (pendingFile + appendFile), the ticker walks the mark* state machine (Uploading → Finished, or Error for broken-*.zip to drive the retry button), and onRemove / onRetry / onPreview / onDownload carry file ids."
        ]


statusName : Upload.Status -> String
statusName status =
    case status of
        Upload.Pending ->
            "pending"

        Upload.Uploading ->
            "uploading"

        Upload.Finished ->
            "finished"

        Upload.Removed ->
            "removed"

        Upload.Error ->
            "error"


uploadRows : List (Element msg)
uploadRows =
    let
        upD =
            Upload.defaults

        file id name status pct url thumb mime =
            { id = id
            , batchId = Nothing
            , name = name
            , percentage = pct
            , status = status
            , url = url
            , thumbnailUrl = thumb
            , type_ = mime
            , fullPath = Nothing
            }

        withId id opts =
            { opts | attributes = [ Element.htmlAttribute (HA.id id) ] }
    in
    [ demoRow "Text list (all statuses)"
        [ Upload.view theme
            (withId "live-upload"
                { upD
                    | fileList =
                        [ file "a" "a.png" Upload.Pending (Just 0) Nothing Nothing Nothing
                        , file "b" "b.png" Upload.Uploading (Just 42) Nothing Nothing Nothing
                        , file "c" "c.png" Upload.Finished (Just 100) (Just "https://example.com/c.png") Nothing Nothing
                        , file "d" "d.png" Upload.Error (Just 88) Nothing Nothing Nothing
                        , file "e" "e.png" Upload.Removed (Just 10) Nothing Nothing Nothing
                        ]
                }
            )
        ]
    , demoRow "Uploading (line progress + cancel)"
        [ Upload.view theme
            (withId "live-upload-uploading"
                { upD
                    | fileList = [ file "u" "video.mp4" Upload.Uploading (Just 42) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow "Error (error kind + retry)"
        [ Upload.view theme
            (withId "live-upload-error"
                { upD
                    | fileList = [ file "e" "broken.zip" Upload.Error (Just 73) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow "Image type"
        [ Upload.view theme
            (withId "live-upload-image"
                { upD
                    | listType = Upload.Image
                    , fileList =
                        [ file "i" "photo.jpg" Upload.Uploading (Just 30) Nothing Nothing (Just "image/jpeg") ]
                }
            )
        ]
    , demoRow "Image card (thumbnail anchor / icon)"
        [ Upload.view theme
            (withId "live-upload-image-card"
                { upD
                    | listType = Upload.ImageCard
                    , fileList =
                        [ file "p" "one.jpg" Upload.Finished (Just 100) (Just imageLogo) (Just imageLogo) (Just "image/jpeg") ]
                }
            )
        , Upload.view theme
            (withId "live-upload-card-thumb"
                { upD
                    | listType = Upload.ImageCard
                    , fileList =
                        [ file "q" "two.pdf" Upload.Finished (Just 100) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow "Dragger trigger"
        [ Upload.view theme
            (withId "live-upload-dragger"
                { upD
                    | draggerInside = True
                    , triggerNode = Just (Upload.viewDragger upD [ Element.text "Click or drag a file here" ])
                }
            )
        ]
    , demoRow "Disabled"
        [ Upload.view theme
            (withId "live-upload-disabled"
                { upD
                    | disabled = True
                    , fileList = [ file "a" "a.png" Upload.Uploading (Just 5) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow "Max reached (trigger disabled)"
        [ Upload.view theme
            (withId "live-upload-max"
                { upD
                    | max = Just 1
                    , fileList = [ file "a" "a.png" Upload.Finished (Just 100) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow "Directory"
        [ Upload.view theme
            (withId "live-upload-directory" { upD | directory = True })
        ]
    , demoRow "renderIcon + alwaysShowActions"
        [ Upload.view theme
            (withId "live-upload-rendericon"
                { upD
                    | renderIcon = Just (\_ -> Element.text "ICON")
                    , fileList = [ file "a" "a.png" Upload.Pending (Just 0) Nothing Nothing Nothing ]
                }
            )
        , Upload.view theme
            (withId "live-upload-always-show"
                { upD
                    | alwaysShowActions = True
                    , fileList = [ file "a" "a.png" Upload.Uploading (Just 20) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow "Abstract trigger"
        (Upload.viewAbstract theme
            upD
            (Element.el [ Element.htmlAttribute (HA.id "live-upload-abstract-slot") ]
                (Element.text "Click to pick a file")
            )
        )
    ]


uploadSection : Element msg
uploadSection =
    section "Upload"
        "A file trigger over a caller-owned file list — pick/drag, upload state and thumbnails are the caller's to own."
        uploadRows


uploadLiveRow : Model -> Element Msg
uploadLiveRow model =
    demoRow "Upload · simulated file list" [ uploadDemo theme model ]


uploadLiveSection : Model -> Element Msg
uploadLiveSection model =
    section "Upload"
        "A file trigger over a caller-owned file list — pick/drag, upload state and thumbnails are the caller's to own."
        (uploadRows ++ [ uploadLiveRow model ])



-- 11 · FORM


nameField : String
nameField =
    "user.name"


ageField : String
ageField =
    "user.age"


nameRules : List Form.Rule
nameRules =
    let
        rule =
            Form.defaultRule
    in
    [ { rule
        | required = True
        , message = Just "Name is required"
        , trigger = Just [ Form.OnInput, Form.OnBlur ]
      }
    , { rule
        | min = Just 2
        , max = Just 12
        , message = Just "Name must be 2–12 characters"
        , trigger = Just [ Form.OnInput ]
      }
    ]


ageRules : List Form.Rule
ageRules =
    let
        rule =
            Form.defaultRule
    in
    [ { rule
        | required = True
        , message = Just "Age is required"
        , trigger = Just [ Form.OnChange ]
      }
    , { rule
        | type_ = Form.TypeNumber
        , min = Just 18
        , max = Just 99
        , message = Just "Age must be between 18 and 99"
        , trigger = Just [ Form.OnChange ]
      }
    ]


formRules : Form.Rules
formRules =
    [ ( nameField, nameRules ), ( ageField, ageRules ) ]


ageValue : Maybe Float -> Form.Value
ageValue age =
    case age of
        Just n ->
            Form.VNumber n

        Nothing ->
            Form.VNull


formValues : Model -> Form.Values
formValues model =
    [ ( nameField, Form.VString model.formName )
    , ( ageField, ageValue model.formAge )
    ]


feedbackOf : String -> List ( String, List Form.Feedback ) -> List Form.Feedback
feedbackOf field result =
    result
        |> List.filter (\( path, _ ) -> path == field)
        |> List.head
        |> Maybe.map Tuple.second
        |> Maybe.withDefault []


ageLabel : Float -> String
ageLabel age =
    if age == toFloat (round age) then
        String.fromInt (round age)

    else
        String.fromFloat age


feedbackText : List Form.Feedback -> Maybe String
feedbackText feedback =
    if List.isEmpty feedback then
        Nothing

    else
        Just (String.join " " (List.map .message feedback))


formDemo : Theme -> Model -> Element Msg
formDemo theme model =
    let
        formD =
            Form.defaults

        iD =
            Form.itemDefaults

        inputD =
            Input.defaults

        inD =
            InputNumber.defaults

        btn =
            Button.defaults

        nameItem =
            { iD
                | label = Just "Name"
                , required = Form.isRequired nameRules
                , validation = Just model.formNameFeedback
                , feedback = feedbackText model.formNameFeedback
            }

        ageItem =
            { iD
                | label = Just "Age"
                , required = Form.isRequired ageRules
                , validation = Just model.formAgeFeedback
                , feedback = feedbackText model.formAgeFeedback
            }

        submitted =
            case model.formSubmitted of
                Just ( name, age ) ->
                    "submitted: " ++ name ++ " / " ++ age

                Nothing ->
                    "submitted: —"
    in
    Element.column [ Element.spacing 10, Element.width (Element.px 400) ]
        [ Form.view theme
            { formD | onSubmit = Just FormSubmit }
            [ Form.item theme
                nameItem
                [ Input.view theme
                    { inputD
                        | value = model.formName
                        , placeholder = Just "Enter your name"
                        , onInput = Just FormNameInput
                        , onBlur = Just FormNameBlur
                    }
                ]
            , Form.item theme
                ageItem
                [ InputNumber.view theme
                    { inD
                        | value = model.formAge
                        , min = Just 1
                        , max = Just 120
                        , placeholder = Just "Enter your age"
                        , onChange = Just FormAgeChange
                    }
                    []
                ]
            , Element.row
                [ Element.spacing 8, Element.paddingEach { top = 4, right = 0, bottom = 0, left = 0 } ]
                [ Button.view theme
                    { btn | onPress = Just FormSubmit }
                    [ Element.text "Submit" ]
                ]
            ]
        , caption [ submitted ]
        , note theme
            "The pure engine runs in update per the header's recipe: typing / blurring validate the triggered rules (validateValue with OnInput / OnBlur / OnChange), Submit runs every rule through validateForm and only collects the values when both fields are clean; the feedback rides back into the items' validation slot."
        ]



-- CAPTION HELPERS


caption : List String -> Element Msg
caption labels =
    Element.row [ Element.spacing 6 ] (List.map chip labels)


note : Theme -> String -> Element Msg
note theme text =
    let
        typ =
            Typo.defaults
    in
    Typo.text theme
        { typ | depth = Just 3, size = Just 12 }
        [ Element.text text ]


listLabel : List String -> String
listLabel items =
    if List.isEmpty items then
        "—"

    else
        String.join ", " items


boolLabel : Bool -> String
boolLabel b =
    if b then
        "yes"

    else
        "no"


formatDate : Calendar.Date -> String
formatDate d =
    String.fromInt d.year
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt d.month)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt d.day)



-- SECTIONS (family body in Main.body order — live variants throughout)


{-| The family body in Main.body order — every section here has a live
variant (the Form live demo moved with its helpers but renders nowhere
this phase; Main.elm is untouched, integration wires it later).
-}
sections : Model -> List (Element Msg)
sections model =
    [ dynamicTagsLiveSection model
    , calendarLiveSection model
    , dynamicInputLiveSection model
    , tableLiveSection model
    , treeLiveSection model
    , imageLiveSection model
    , imagePreviewLiveSection model
    , dataTableLiveSection model
    , transferLiveSection model
    , uploadLiveSection model
    ]
