module Live.Data exposing (Model, Msg, init, subscriptions, update, view)

{-| LIVE demos — a real update loop for the data family: Table, DataTable,
Tree, Transfer, Calendar, Image, ImageGroup, ImagePreview, Upload,
DynamicInput, DynamicTags, Form.

Caller-owned state per each port's contract — the component renders whatever
the model says, every channel feeds one Msg constructor, and the pure
interaction helpers the ports ship (DataTable's checked-keys algebra, Tree's
treemate `check`/`uncheck`/`toggleExpand`/`toggleSelect`, Calendar's panel
recipe, ImagePreview's zoom transforms, ImageGroup's walk, Upload's `mark*`
state machine, DynamicInput's array edits, Form's validation engine) run in
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
import Showcase exposing (chip, demoRow)



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



-- VIEW


view : Theme -> Model -> Element Msg
view theme model =
    Element.column [ Element.spacing 20, Element.width Element.fill ]
        [ demoRow "Table · row state (Row.attributes seam)" [ tableDemo theme model ]
        , demoRow "Data Table · selection + sort + pagination" [ dataTableDemo theme model ]
        , demoRow "Tree · check + expand + select (nodeProps seam)" [ treeDemo theme model ]
        , demoRow "Transfer · move + filter" [ transferDemo theme model ]
        , demoRow "Calendar · panel + date" [ calendarDemo theme model ]
        , demoRow "Image · click to preview (full toolbar)" [ previewDemo theme model ]
        , demoRow "Image Group · gallery walk" [ groupDemo theme model ]
        , demoRow "Upload · simulated file list" [ uploadDemo theme model ]
        , demoRow "Dynamic Input · pair list editor" [ pairDemo theme model ]
        , demoRow "Dynamic Tags · add / confirm / close" [ tagsDemo theme model ]
        , demoRow "Form · validate + submit" [ formDemo theme model ]
        ]



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



-- 3 · TREE


leafOption : String -> String -> Tree.TreeOption Msg
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



-- 6 · IMAGE PREVIEW (full toolbar)


imageLogo : String
imageLogo =
    "https://www.naiveui.com/assets/naivelogo.93278402.svg"


previewSrcs : List String
previewSrcs =
    [ "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
    , imageLogo
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
                |> Maybe.withDefault imageLogo
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
        imageD =
            Image.defaults

        thumb index src =
            Image.view theme
                { imageD
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



-- 7 · IMAGE GROUP


gallery : List String
gallery =
    [ "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
    , imageLogo
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
        imageD =
            Image.defaults

        thumb index src =
            Image.view theme
                { imageD
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
    { base | thumbnailUrl = Just imageLogo }


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
