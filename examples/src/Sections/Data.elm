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
import Showcase exposing (chip, demoRow, section)



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
    , abstractFiles : List Upload.FileInfo
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

    -- phase-2: the static rows' own channels (init == the old literals)
    , tagsSamples : List String
    , tagsSmallSamples : List String
    , tagsInputSamples : List String
    , tagsInputDraft : String
    , tagsInputShown : Bool
    , calSamplesValue : Maybe Calendar.Date
    , calSamplesPanel : Calendar.Panel
    , stringsSamples : List String
    , pairsSamples : List ( String, String )
    , onlyThree : List String
    , treeExpandedCheckable : List String
    , treeExpandedMulti : List String
    , treeExpandedLine : List String
    , treeExpandedBlock : List String
    , treeExpandedLoading : List String
    , treeCheckedBasic : List String
    , treeSelectedMulti : List String
    , transferValue2 : List String
    , transferValueLarge : List String
    , transferValueAll : List String
    , dtSortSample : List (DataTable.SortState Person)
    , dtSortPageSample : List (DataTable.SortState Person)
    , dtCheckedSelection : List String
    , dtCheckedSingle : List String
    , dtCheckedExtra : List String
    , dtExpandedKeys : List String
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
    , abstractFiles = []
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
    , tagsSamples = [ "Naive UI", "Elm", "elm-ui" ]
    , tagsSmallSamples = [ "small", "medium" ]
    , tagsInputSamples = [ "one", "two" ]
    , tagsInputDraft = "thr"
    , tagsInputShown = True
    , calSamplesValue = Just { year = 2024, month = 6, day = 20 }
    , calSamplesPanel = { year = 2024, month = 6 }
    , stringsSamples = [ "Alice", "Bob", "Cindy" ]
    , pairsSamples = [ ( "Name", "Naive UI" ), ( "Author", "07akioni" ) ]
    , onlyThree = [ "Only", "Three" ]
    , treeExpandedCheckable = [ "beatles" ]
    , treeExpandedMulti = [ "beatles" ]
    , treeExpandedLine = [ "beatles", "stones" ]
    , treeExpandedBlock = [ "beatles" ]
    , treeExpandedLoading = [ "beatles", "stones" ]
    , treeCheckedBasic = [ "drive", "nowhere" ]
    , treeSelectedMulti = [ "drive", "exile" ]
    , transferValue2 = [ "2" ]
    , transferValueLarge = [ "1", "4" ]
    , transferValueAll = [ "1", "2", "3", "4" ]
    , dtSortSample = []
    , dtSortPageSample = []
    , dtCheckedSelection = [ "Jaime Whyte", "Boris Wuhrer" ]
    , dtCheckedSingle = [ "Boris Wuhrer", "Jesse Tripps" ]
    , dtCheckedExtra = [ "Terry Malany" ]
    , dtExpandedKeys = [ "Boris Wuhrer" ]
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
    | UploadAbstractPick
    | UploadAbstractRemove String
    | UploadAbstractAdvance
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
      -- phase-2: the static rows' own channels
    | TagsSamplesUpdate (List String)
    | TagsSmallSamplesUpdate (List String)
    | TagsInputSamplesUpdate (List String)
    | TagsInputDraftInput String
    | TagsInputConfirm
    | TagsInputActivate
    | CalSamplesPick Calendar.Date
    | CalSamplesPanel Calendar.Panel
    | StringsSamplesUpdate (List String)
    | StringsSampleRemove Int
    | PairsSamplesUpdate (List ( String, String ))
    | PairsSampleRemove Int
    | OnlyThreeUpdate (List String)
    | OnlyThreeRemove Int
    | SampleTreeNodeClick { key : String, check : Bool, select : Bool, expandedToggle : Msg }
    | TreeExpandedCheckableToggle String
    | TreeExpandedMultiToggle String
    | TreeExpandedBlockToggle String
    | TransferSamplesCheck (List String)
    | TransferLargeCheck (List String)
    | TransferAllCheck (List String)
    | DtSortSampleChange (List (DataTable.SortState Person))
    | DtSortPageSampleChange (List (DataTable.SortState Person))
    | DtCheckedSelectionChange (List String) (List Person) (DataTable.CheckEmit Person)
    | DtCheckedSingleChange (List String) (List Person) (DataTable.CheckEmit Person)
    | DtCheckedExtraChange (List String) (List Person) (DataTable.CheckEmit Person)
    | DtExpandedToggle (List String)


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

        UploadAbstractPick ->
            -- abstract trigger: the caller owns the click; same simulated
            -- handleFileAddition (pendingFile + appendFile) as the live row
            { model
                | abstractFiles =
                    Upload.appendFile
                        (fakeFile model.uploadSeq "abstract-pick.txt" "text/plain")
                        model.abstractFiles
                , uploadSeq = model.uploadSeq + 1
                , uploadNote = "abstract trigger clicked"
            }

        UploadAbstractRemove id ->
            { model | abstractFiles = Upload.removeFileById id model.abstractFiles }

        UploadAbstractAdvance ->
            { model | abstractFiles = List.map advanceFile model.abstractFiles }

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

        TagsSamplesUpdate tags ->
            { model | tagsSamples = tags }

        TagsSmallSamplesUpdate tags ->
            { model | tagsSmallSamples = tags }

        TagsInputSamplesUpdate tags ->
            { model | tagsInputSamples = tags }

        TagsInputDraftInput draft ->
            { model | tagsInputDraft = draft }

        TagsInputConfirm ->
            -- the header's documented confirm recipe
            { model
                | tagsInputSamples =
                    if model.tagsInputDraft == "" then
                        model.tagsInputSamples

                    else
                        model.tagsInputSamples ++ [ model.tagsInputDraft ]
                , tagsInputShown = False
                , tagsInputDraft = ""
            }

        TagsInputActivate ->
            { model | tagsInputShown = True }

        CalSamplesPick date ->
            -- the header's recipe: an other-month pick also moves the panel
            { model
                | calSamplesValue = Just date
                , calSamplesPanel =
                    if Calendar.panelOf date /= model.calSamplesPanel then
                        Calendar.panelOf date

                    else
                        model.calSamplesPanel
            }

        CalSamplesPanel panel ->
            { model | calSamplesPanel = panel }

        StringsSamplesUpdate strings ->
            { model | stringsSamples = strings }

        StringsSampleRemove index ->
            { model | stringsSamples = DynamicInput.removeAt index model.stringsSamples }

        PairsSamplesUpdate pairs ->
            { model | pairsSamples = pairs }

        PairsSampleRemove index ->
            { model | pairsSamples = DynamicInput.removeAt index model.pairsSamples }

        OnlyThreeUpdate strings ->
            { model | onlyThree = strings }

        OnlyThreeRemove index ->
            { model | onlyThree = DynamicInput.removeAt index model.onlyThree }

        SampleTreeNodeClick info ->
            -- the three-fold node click of the live row's recipe; each row's
            -- nodeProps closes over its own expanded-set toggle (the
            -- per-instance sets differ — see the Model fields)
            let
                checked =
                    if info.check then
                        if List.member info.key (Tree.getCheckedKeys True Tree.All False model.treeCheckedBasic treeOptions).checkedKeys then
                            Tree.uncheck True Tree.All False info.key model.treeCheckedBasic treeOptions

                        else
                            Tree.check True Tree.All False info.key model.treeCheckedBasic treeOptions

                    else
                        model.treeCheckedBasic

                selected =
                    if info.select then
                        Tree.toggleSelect True True info.key model.treeSelectedMulti

                    else
                        model.treeSelectedMulti
            in
            update info.expandedToggle
                { model
                    | treeCheckedBasic = checked
                    , treeSelectedMulti = selected
                }

        TreeExpandedCheckableToggle key ->
            { model | treeExpandedCheckable = Tree.toggleExpand False treeOptions key model.treeExpandedCheckable }

        TreeExpandedMultiToggle key ->
            { model | treeExpandedMulti = Tree.toggleExpand False treeOptions key model.treeExpandedMulti }

        TreeExpandedBlockToggle key ->
            { model | treeExpandedBlock = Tree.toggleExpand False treeOptions key model.treeExpandedBlock }

        TransferSamplesCheck value ->
            { model | transferValue2 = value }

        TransferLargeCheck value ->
            { model | transferValueLarge = value }

        TransferAllCheck value ->
            { model | transferValueAll = value }

        DtSortSampleChange states ->
            { model | dtSortSample = states }

        DtSortPageSampleChange states ->
            { model | dtSortPageSample = states }

        DtCheckedSelectionChange keys _ _ ->
            { model | dtCheckedSelection = keys }

        DtCheckedSingleChange keys _ _ ->
            { model | dtCheckedSingle = keys }

        DtCheckedExtraChange keys _ _ ->
            { model | dtCheckedExtra = keys }

        DtExpandedToggle keys ->
            { model | dtExpandedKeys = keys }


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


dynamicTagsRows : Model -> Theme -> List (Element Msg)
dynamicTagsRows model theme =
    [ demoRow theme
        "dat-001"
        "Tags"
        [ DynamicTags.view theme
            { dtagsD
                | value = model.tagsSamples
                , onUpdateValue = Just TagsSamplesUpdate
            }
            []
        , DynamicTags.view theme
            { dtagsD
                | value = model.tagsSmallSamples
                , size = T.Small
                , round = True
                , onUpdateValue = Just TagsSmallSamplesUpdate
            }
            []
        ]
    , demoRow theme
        "dat-002"
        "Input shown (caller owns the draft)"
        [ DynamicTags.view theme
            { dtagsD
                | value = model.tagsInputSamples
                , showInput = model.tagsInputShown
                , inputValue = model.tagsInputDraft
                , onActivate = Just TagsInputActivate
                , onInputValue = Just TagsInputDraftInput
                , onConfirm = Just TagsInputConfirm
                , onUpdateValue = Just TagsInputSamplesUpdate
            }
            []
        ]
    ]


dynamicTagsSection : Model -> Theme -> Element Msg
dynamicTagsSection model theme =
    section theme
        "Dynamic Tags"
        "Editable tag lists — keyword sets, chips, recipient pickers. Naive UI's DynamicTags pairs an inline adding input with closable tags: the tags, the draft text and whether the input is open are all caller-owned model fields driven through update messages. Rows show the stacked default, the always-open input variant, and a live row that actually adds, confirms and dismisses."
        (dynamicTagsRows model theme)


tagsLiveRow : Model -> Theme -> Element Msg
tagsLiveRow model theme =
    demoRow theme
        "dat-003"
        "Dynamic Tags · add / confirm / close"
        [ Element.column [ Element.spacing 10, Element.width (Element.px 480) ]
            [ DynamicTags.view theme (tagsOpts model) []
            , caption theme
                [ "tags: " ++ listLabel model.tags
                , if model.tagsShowInput then
                    "input: \"" ++ model.tagsDraft ++ "\""

                  else
                    "input: hidden"
                ]
            , note theme
                "The add trigger activates the built-in input (onActivate → showInput), typing feeds the caller-owned draft (onInputValue), Enter confirms (append + hide + clear, the header's recipe), and a tag's close reports the next list (onUpdateValue)."
            ]
        ]


dynamicTagsLiveSection : Model -> Theme -> Element Msg
dynamicTagsLiveSection model theme =
    section theme
        "Dynamic Tags"
        "Editable tag lists — keyword sets, chips, recipient pickers. Naive UI's DynamicTags pairs an inline adding input with closable tags: the tags, the draft text and whether the input is open are all caller-owned model fields driven through update messages. Rows show the stacked default, the always-open input variant, and a live row that actually adds, confirms and dismisses."
        (dynamicTagsRows model theme ++ [ tagsLiveRow model theme ])



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


calendarRows : Model -> Theme -> List (Element Msg)
calendarRows model theme =
    [ demoRow theme
        "dat-069"
        "Basic (panel + now)"
        [ Element.el [ Element.width (Element.px 420) ]
            (Calendar.view theme
                { calD | panel = { year = 2024, month = 6 }, now = { year = 2024, month = 6, day = 15 } }
            )
        ]
    , demoRow theme
        "dat-070"
        "Selected date (caller-owned value + events)"
        [ Element.el [ Element.width (Element.px 420) ]
            (Calendar.view theme
                { calD
                    | panel = model.calSamplesPanel
                    , now = { year = 2024, month = 6, day = 15 }
                    , value = model.calSamplesValue
                    , onUpdateValue = Just CalSamplesPick
                    , onPanelChange = Just CalSamplesPanel
                }
            )
        ]
    ]


calendarSection : Model -> Theme -> Element Msg
calendarSection model theme =
    section theme
        "Calendar"
        "A month calendar for picking and displaying dates, ported from Naive UI's Calendar. The current panel, the selected value and the locale all live in your model — the component is a pure view over them, with headers and cell callbacks as messages. Rows show single and ranged selection, the double-panel form, and custom cell content."
        (calendarRows model theme)


calendarLiveRow : Model -> Theme -> Element Msg
calendarLiveRow model theme =
    demoRow theme
        "dat-004"
        "Calendar · panel + date"
        [ Element.column [ Element.spacing 10, Element.width (Element.px 420) ]
            [ Calendar.view theme (calOpts model)
            , caption theme
                [ "panel: " ++ Calendar.enUS.title model.calPanel
                , "selected: " ++ Maybe.withDefault "—" (Maybe.map formatDate model.calValue)
                ]
            , note theme
                "The header buttons emit onPanelChange with the target panel; clicking a cell emits onUpdateValue (clicking an other-month cell also moves the panel — the header's two-message recipe, applied in update)."
            ]
        ]


calendarLiveSection : Model -> Theme -> Element Msg
calendarLiveSection model theme =
    section theme
        "Calendar"
        "A month calendar for picking and displaying dates, ported from Naive UI's Calendar. The current panel, the selected value and the locale all live in your model — the component is a pure view over them, with headers and cell callbacks as messages. Rows show single and ranged selection, the double-panel form, and custom cell content."
        (calendarRows model theme ++ [ calendarLiveRow model theme ])



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


dynamicInputRows : Model -> Theme -> List (Element Msg)
dynamicInputRows model theme =
    [ demoRow theme
        "dat-005"
        "Preset: input"
        [ DynamicInput.viewInput theme
            { diD
                | value = model.stringsSamples
                , placeholder = Just "Name"
                , onUpdateValue = Just StringsSamplesUpdate
                , onRemove = Just StringsSampleRemove
            }
        ]
    , demoRow theme
        "dat-006"
        "Preset: pair"
        [ DynamicInput.viewPair theme
            { diPairD
                | value = model.pairsSamples
                , keyPlaceholder = Just "Key"
                , valuePlaceholder = Just "Value"
                , onUpdateValue = Just PairsSamplesUpdate
                , onRemove = Just PairsSampleRemove
            }
        ]
    , demoRow theme
        "dat-007"
        "Max + sort buttons"
        [ DynamicInput.viewInput theme
            { diD
                | value = model.onlyThree
                , max = Just 3
                , showSortButton = True
                , onUpdateValue = Just OnlyThreeUpdate
                , onRemove = Just OnlyThreeRemove
            }
        ]
    , demoRow theme
        "dat-008"
        "Empty (Create button)"
        [ DynamicInput.viewInput theme { diD | value = [] }
        ]
    ]


dynamicInputSection : Model -> Theme -> Element Msg
dynamicInputSection model theme =
    section theme
        "DynamicInput"
        "A dynamic list of input rows — plain values or key/value pairs with add, remove and sort buttons. The list lives in your model; pure helpers (`insertAt`, `removeAt`, `moveUp`, `moveDown`) do the list math, guarded by `min` and `max`. The rows show the input and pair presets, the empty state's Create button, then a live pair-list editor."
        (dynamicInputRows model theme)


pairLiveRow : Model -> Theme -> Element Msg
pairLiveRow model theme =
    demoRow theme
        "dat-009"
        "Dynamic Input · pair list editor"
        [ let
            pairChips =
                if List.isEmpty model.pairs then
                    [ "empty — press Create" ]

                else
                    List.map (\( k, v ) -> k ++ " = " ++ v) model.pairs
          in
          Element.column [ Element.spacing 10, Element.width (Element.px 480) ]
            [ DynamicInput.viewPair theme (pairOpts model)
            , caption theme pairChips
            , note theme
                "Pair preset over a caller-owned list: typing reports the whole list (onUpdateValue with the entry replaced), Create / add / sort presses carry the inserted or moved list (insertAt / moveUp / moveDown inside the component), and the remove press owns its own channel — onRemove carries the index and update applies removeAt itself, the documented split."
            ]
        ]


dynamicInputLiveSection : Model -> Theme -> Element Msg
dynamicInputLiveSection model theme =
    section theme
        "DynamicInput"
        "A dynamic list of input rows — plain values or key/value pairs with add, remove and sort buttons. The list lives in your model; pure helpers (`insertAt`, `removeAt`, `moveUp`, `moveDown`) do the list math, guarded by `min` and `max`. The rows show the input and pair presets, the empty state's Create button, then a live pair-list editor."
        (dynamicInputRows model theme ++ [ pairLiveRow model theme ])



-- 1 · TABLE


tableRows : Theme -> List (Element msg)
tableRows theme =
    [ demoRow theme
        "dat-010"
        "Basic (defaults: bordered, bottom-bordered, single-line)"
        [ let
            rD =
                Table.rowDefaults

            cD =
                Table.cellDefaults

            textCell label =
                { cD | content = [ Element.text label ] }

            table =
                { head =
                    [ { rD | cells = [ textCell "Name", textCell "Origin" ] } ]
                , body =
                    [ { rD | cells = [ textCell "Naive", textCell "Vue" ] }
                    , { rD | cells = [ textCell "elm-naive-ui", textCell "Elm" ] }
                    , { rD | cells = [ textCell "Seemly", textCell "Utils" ] }
                    ]
                }
          in
          Table.view theme Table.defaults table
        ]
    , demoRow theme
        "dat-011"
        "Sizes · un-bordered · multi-line"
        [ let
            tD =
                Table.defaults

            rD =
                Table.rowDefaults

            cD =
                Table.cellDefaults

            textCell label =
                { cD | content = [ Element.text label ] }

            table =
                { head =
                    [ { rD | cells = [ textCell "Name", textCell "Origin" ] } ]
                , body =
                    [ { rD | cells = [ textCell "Naive", textCell "Vue" ] }
                    , { rD | cells = [ textCell "elm-naive-ui", textCell "Elm" ] }
                    , { rD | cells = [ textCell "Seemly", textCell "Utils" ] }
                    ]
                }
          in
          Element.row [ Element.spacing 16 ]
            [ Table.view theme { tD | size = Table.Small } table
            , Table.view theme { tD | size = Table.Large, bordered = False, bottomBordered = False } table
            ]
        ]
    , demoRow theme
        "dat-012"
        "Striped · single-column · multi-line cells"
        [ let
            tD =
                Table.defaults

            rD =
                Table.rowDefaults

            cD =
                Table.cellDefaults

            textCell label =
                { cD | content = [ Element.text label ] }

            table =
                { head =
                    [ { rD | cells = [ textCell "Name", textCell "Origin" ] } ]
                , body =
                    [ { rD | cells = [ textCell "Naive", textCell "Vue" ] }
                    , { rD | cells = [ textCell "elm-naive-ui", textCell "Elm" ] }
                    , { rD | cells = [ textCell "Seemly", textCell "Utils" ] }
                    ]
                }
          in
          Element.row [ Element.spacing 16 ]
            [ Table.view theme { tD | striped = True, singleLine = False } table
            , Table.view theme { tD | singleColumn = True } table
            ]
        ]
    , demoRow theme
        "dat-013"
        "Colspan / rowspan"
        [ let
            rD =
                Table.rowDefaults

            cD =
                Table.cellDefaults

            textCell label =
                { cD | content = [ Element.text label ] }

            table =
                { head =
                    [ { rD | cells = [ textCell "", cD, cD ] } ]
                , body =
                    [ { rD
                        | cells =
                            [ { cD | content = [ Element.text "Guitar" ], rowspan = Just 2 }
                            , textCell "1998"
                            , textCell "Songs"
                            ]
                      }
                    , { rD
                        | cells =
                            [ textCell "2001"
                            , { cD | content = [ Element.text "Albums + Tours" ], colspan = Just 2 }
                            ]
                      }
                    ]
                }
          in
          Table.view theme Table.defaults table
        ]
    , demoRow theme
        "dat-014"
        "RTL"
        [ let
            tD =
                Table.defaults

            rD =
                Table.rowDefaults

            cD =
                Table.cellDefaults

            textCell label =
                { cD | content = [ Element.text label ] }

            table =
                { head =
                    [ { rD | cells = [ textCell "Name", textCell "Origin" ] } ]
                , body =
                    [ { rD | cells = [ textCell "Naive", textCell "Vue" ] }
                    , { rD | cells = [ textCell "elm-naive-ui", textCell "Elm" ] }
                    , { rD | cells = [ textCell "Seemly", textCell "Utils" ] }
                    ]
                }
          in
          Table.view theme { tD | rtl = True } table
        ]
    ]


tableSection : Theme -> Element msg
tableSection theme =
    section theme
        "Table"
        "A static n-table with typed head/body cells, colspan/rowspan and Element content — release notes, spec tables, pricing grids. It is fully static by design: no runtime state, and a row click rides the documented Row.attributes seam. The rows show borders, sizes, striped and single-column forms, merged cells, and RTL."
        (tableRows theme)


tableLiveRow : Model -> Theme -> Element Msg
tableLiveRow model theme =
    demoRow theme
        "dat-015"
        "Table · row state (Row.attributes seam)"
        [ let
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
            , caption theme [ "picked: " ++ Maybe.withDefault "—" model.tablePick ]
            , note theme
                "NUI.Table is the port's fully-static table — no channel in Options by design. The row click rides the documented Row.attributes seam (upstream's bare <tr> wrapper), not a faked channel."
            ]
        ]


tableLiveSection : Model -> Theme -> Element Msg
tableLiveSection model theme =
    section theme
        "Table"
        "A static n-table with typed head/body cells, colspan/rowspan and Element content — release notes, spec tables, pricing grids. It is fully static by design: no runtime state, and a row click rides the documented Row.attributes seam. The rows show borders, sizes, striped and single-column forms, merged cells, and RTL."
        (tableRows theme ++ [ tableLiveRow model theme ])



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


{-| The phase-2 static rows' `nodeProps` seam — the port's documented
node-click attribute hook (same seam the live row uses). `withCheck` rides
the treemate check/uncheck algebra under `checkOnClick`, `withSelect` the
toggleSelect walk; both always fold in the expand toggle (the switcher is
display-only, so the node click owns expand too — the module doc's recipe).
-}
sampleNodeProps : Bool -> Bool -> (String -> Msg) -> Tree.TreeOption Msg -> List (Element.Attribute Msg)
sampleNodeProps withCheck withSelect expandedToggle option =
    let
        key =
            treeKeyOf option
    in
    case treeInfo key treeOptions of
        Just info ->
            if info.disabled then
                []

            else
                [ Element.htmlAttribute
                    (HE.onClick
                        (SampleTreeNodeClick
                            { key = key
                            , check = withCheck
                            , select = withSelect
                            , expandedToggle = expandedToggle key
                            }
                        )
                    )
                ]

        Nothing ->
            []


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


treeRows : Model -> Theme -> List (Element Msg)
treeRows model theme =
    [ demoRow theme
        "dat-016"
        "Basic · checkable (cascade, Child strategy)"
        [ Tree.view theme
            { treeD | data = treeOptions, expandedKeys = [ "beatles", "stones" ] }
        , Tree.view theme
            { treeD
                | data = treeOptions
                , expandedKeys = model.treeExpandedCheckable
                , checkable = True
                , cascade = True
                , checkStrategy = Tree.Child
                , checkedKeys = model.treeCheckedBasic
                , nodeProps = Just (sampleNodeProps True False TreeExpandedCheckableToggle)
            }
        ]
    , demoRow theme
        "dat-017"
        "Multiple selection · showLine"
        [ Tree.view theme
            { treeD
                | data = treeOptions
                , expandedKeys = model.treeExpandedMulti
                , multiple = True
                , selectedKeys = model.treeSelectedMulti
                , nodeProps = Just (sampleNodeProps False True TreeExpandedMultiToggle)
            }
        , Tree.view theme
            { treeD | data = treeOptions, expandedKeys = model.treeExpandedLine, showLine = True }
        ]
    , demoRow theme
        "dat-018"
        "block-line + ellipsis · pending + highlight"
        [ Tree.view theme
            { treeD
                | data = treeOptions
                , expandedKeys = model.treeExpandedBlock
                , blockLine = True
                , ellipsis = True
                , pendingKey = Just "nowhere"
                , highlightKeys = Just [ "revolver" ]
                , nodeProps = Just (sampleNodeProps False False TreeExpandedBlockToggle)
            }
        ]
    , demoRow theme
        "dat-019"
        "Loading switcher · empty"
        [ Tree.view theme
            { treeD | data = treeOptions, expandedKeys = model.treeExpandedLoading, loadingKeys = [ "stones" ] }
        , Tree.view theme { treeD | attributes = [ Element.width (Element.px 240) ] }
        ]
    ]


treeSection : Model -> Theme -> Element Msg
treeSection model theme =
    section theme
        "Tree"
        "Naive UI's tree — the `div.n-tree` root (17 `--n-*` vars; three derived from the wrapper-padding/height strings) rendering the flattened visible nodes as `n-tree-node-wrapper` rows: a `showLine` indent chain, the switcher (arrow svg, the loading spinner for `loadingKeys` keys — sw20/r85 baseline under the `spin*` overrides), the `data-checkbox`-wrapped `NUI.Checkbox` (cascade-checked via the shipped treemate helpers), and the prefix/label/suffix content. Everything interactive is data: `expandedKeys` / `checkedKeys` / `selectedKeys` / `pendingKey` / `loadingKeys` / `dropMark`; the pure helpers (`flatten`, `getCheckedKeys`, `check` / `uncheck`, `toggleExpand`, `toggleSelect`, `getNonLeafKeys`, `filterTree`) do the treemate math. Not ported: virtual list, expand motion, drag/keyboard events."
        (treeRows model theme)


treeLiveRow : Model -> Theme -> Element Msg
treeLiveRow model theme =
    demoRow theme
        "dat-020"
        "Tree · check + expand + select (nodeProps seam)"
        [ let
            normalized =
                Tree.getCheckedKeys True Tree.All False model.treeChecked treeData
          in
          Element.column [ Element.spacing 10 ]
            [ Tree.view theme (treeOpts model)
            , caption theme
                [ "checked: " ++ listLabel normalized.checkedKeys
                , "half-checked: " ++ listLabel normalized.indeterminateKeys
                , "selected: " ++ listLabel model.treeSelected
                , "expanded: " ++ listLabel model.treeExpanded
                ]
            , note theme
                "The port renders every tree state as data — switcher and checkbox clicks are not channelled, so the row click (nodeProps, on the node div under blockLine) drives all three: expand (toggleExpand), select (toggleSelect) and check (treemate check/uncheck under checkOnClick, with the cascade re-normalized through getCheckedKeys)."
            ]
        ]


treeLiveSection : Model -> Theme -> Element Msg
treeLiveSection model theme =
    section theme
        "Tree"
        "Naive UI's tree — the `div.n-tree` root (17 `--n-*` vars; three derived from the wrapper-padding/height strings) rendering the flattened visible nodes as `n-tree-node-wrapper` rows: a `showLine` indent chain, the switcher (arrow svg, the loading spinner for `loadingKeys` keys — sw20/r85 baseline under the `spin*` overrides), the `data-checkbox`-wrapped `NUI.Checkbox` (cascade-checked via the shipped treemate helpers), and the prefix/label/suffix content. Everything interactive is data: `expandedKeys` / `checkedKeys` / `selectedKeys` / `pendingKey` / `loadingKeys` / `dropMark`; the pure helpers (`flatten`, `getCheckedKeys`, `check` / `uncheck`, `toggleExpand`, `toggleSelect`, `getNonLeafKeys`, `filterTree`) do the treemate math. Not ported: virtual list, expand motion, drag/keyboard events."
        (treeRows model theme ++ [ treeLiveRow model theme ])



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


imageRows : Theme -> List (Element msg)
imageRows theme =
    [ demoRow theme
        "dat-021"
        "Basic + object-fit (fixed state)"
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
    , demoRow theme
        "dat-022"
        "Error → fallbackSrc + error slot (fixed state)"
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
    , demoRow theme
        "dat-023"
        "Placeholder (img hidden 0×0 until loaded) + preview-disabled + lazy"
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


imageSection : Theme -> Element msg
imageSection theme =
    section theme
        "Image"
        "A themed `<img>` wrapper with lazy loading, error fallback and a click-to-preview seam — avatars, galleries, article figures. Load and error state are caller-owned: `showError` swaps to `fallbackSrc`, and a placeholder renders until `loaded` flips. The rows show object-fit, the error path, placeholder and lazy variants, then a live click-to-preview specimen."
        (imageRows theme)


previewLiveRow : Model -> Theme -> Element Msg
previewLiveRow model theme =
    demoRow theme
        "dat-024"
        "Image · click to preview (full toolbar)"
        [ let
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
            , caption theme
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
        ]


imageLiveSection : Model -> Theme -> Element Msg
imageLiveSection model theme =
    section theme
        "Image"
        "A themed `<img>` wrapper with lazy loading, error fallback and a click-to-preview seam — avatars, galleries, article figures. Load and error state are caller-owned: `showError` swaps to `fallbackSrc`, and a placeholder renders until `loaded` flips. The rows show object-fit, the error path, placeholder and lazy variants, then a live click-to-preview specimen."
        (imageRows theme ++ [ previewLiveRow model theme ])



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


imagePreviewRows : Theme -> List (Element msg)
imagePreviewRows theme =
    [ demoRow theme
        "dat-025"
        "Standalone preview (fixed state: open, zoom identity)"
        [ modalHost []
            (ImagePreview.view theme
                { previewD
                    | show = True
                    , src = Just "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg"
                }
            )
        ]
    , demoRow theme
        "dat-026"
        "Zoom/rotate state + previewed-img props (8px white frame)"
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
    , demoRow theme
        "dat-027"
        "Toolbar suppressed + drag state (grabbing cursor, no transition)"
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
    , demoRow theme
        "dat-028"
        "Group (srcList registry, second image current; slot thumbnails beside)"
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


imagePreviewSection : Theme -> Element msg
imagePreviewSection theme =
    section theme
        "Image Preview & Group"
        "The preview modal family (upstream `NImagePreview`/`NImageGroup`): container (the five toolbar `--n-*` vars) > overlay (click-to-close seat) > toolbar (prev/next only when `onPrev` is set — upstream keys both on `onPrev` — then rotate CCW/CW, original size, zoomOut, zoomIn, download, close) > wrapper > `img.n-image-preview`. The runtime is caller-owned (`NUI.Modal` precedent): `zoom` starts at `zoom0` and moves through the pure transforms (`zoomIn`/`zoomOut`/`rotateClockwise`/`resizeToOriginalSize`/`toggleOriginalSize`/`switchReset`), drag clamps through `moveStrategy` + `derivedOffset`, document keys map through `keyAction`, and `syncTransformOrigin` writes the thumbnail's center into `wrapperStyle`. The group adds the url registry (`srcList` wins with `p${index}` keys, else the caller-threaded `registered` ids) and the wrap-around walk (`nextIndex`/`prevIndex` skip empty urls). Demo cells confine the fixed tree like the modal demos."
        (imagePreviewRows theme)


groupLiveRow : Model -> Theme -> Element Msg
groupLiveRow model theme =
    demoRow theme
        "dat-029"
        "Image Group · gallery walk"
        [ let
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
            , caption theme
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
        ]


imagePreviewLiveSection : Model -> Theme -> Element Msg
imagePreviewLiveSection model theme =
    section theme
        "Image Preview & Group"
        "The preview modal family (upstream `NImagePreview`/`NImageGroup`): container (the five toolbar `--n-*` vars) > overlay (click-to-close seat) > toolbar (prev/next only when `onPrev` is set — upstream keys both on `onPrev` — then rotate CCW/CW, original size, zoomOut, zoomIn, download, close) > wrapper > `img.n-image-preview`. The runtime is caller-owned (`NUI.Modal` precedent): `zoom` starts at `zoom0` and moves through the pure transforms (`zoomIn`/`zoomOut`/`rotateClockwise`/`resizeToOriginalSize`/`toggleOriginalSize`/`switchReset`), drag clamps through `moveStrategy` + `derivedOffset`, document keys map through `keyAction`, and `syncTransformOrigin` writes the thumbnail's center into `wrapperStyle`. The group adds the url registry (`srcList` wins with `p${index}` keys, else the caller-threaded `registered` ids) and the wrap-around walk (`nextIndex`/`prevIndex` skip empty urls). Demo cells confine the fixed tree like the modal demos."
        (imagePreviewRows theme ++ [ groupLiveRow model theme ])



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


dataTableRows : Model -> Theme -> List (Element Msg)
dataTableRows model theme =
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
    [ demoRow theme
        "dat-030"
        "Basic"
        [ DataTable.view theme
            { dtD | columns = columns, data = people_, rowKey = .name }
        ]
    , demoRow theme
        "dat-031"
        "Striped + bordered"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , striped = True
            }
        ]
    , demoRow theme
        "dat-032"
        "Empty"
        [ DataTable.view theme
            { dtD | columns = columns, data = [], rowKey = .name }
        ]
    , demoRow theme
        "dat-033"
        "Sorting"
        [ DataTable.view theme
            { dtD
                | columns = sortableColumns
                , data = people_
                , rowKey = .name
                , sortStates = model.dtSortSample
                , onSorterChange = Just DtSortSampleChange
            }
        , DataTable.view theme
            { dtD
                | columns = sortableColumns
                , data = people_
                , rowKey = .name
                , sortStates =
                    if List.isEmpty model.dtSortSample then
                        DataTable.defaultSortStates sortableColumns
                            |> List.map
                                (\state ->
                                    if state.columnKey == "age" then
                                        { state | order = DataTable.Descend }

                                    else
                                        state
                                )

                    else
                        model.dtSortSample
                , onSorterChange = Just DtSortSampleChange
            }
        ]
    , demoRow theme
        "dat-034"
        "Pagination"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , pagination = Just { dtPg | pageSize = Just 2 }
            }
        ]
    , demoRow theme
        "dat-035"
        "Sort + pagination"
        [ DataTable.view theme
            { dtD
                | columns = sortableColumns
                , data = people_
                , rowKey = .name
                , sortStates =
                    if List.isEmpty model.dtSortPageSample then
                        [ ageDescend ]

                    else
                        model.dtSortPageSample
                , pagination =
                    Just
                        { dtPg
                            | pageSize = Just 2
                            , currentPage = 2
                        }
                , onSorterChange = Just DtSortPageSampleChange
            }
        ]
    , demoRow theme
        "dat-036"
        "Filter"
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
    , demoRow theme
        "dat-037"
        "Selection"
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
                , checkedRowKeys = model.dtCheckedSelection
                , onUpdateCheckedRowKeys = Just DtCheckedSelectionChange
            }
        ]
    , demoRow theme
        "dat-038"
        "Selection (single)"
        [ DataTable.view theme
            { dtD
                | columns =
                    [ { colD | kind = DataTable.KindSelection, multiple = False }
                    , nameCol
                    , ageCol
                    ]
                , data = people_
                , rowKey = .name
                , checkedRowKeys = model.dtCheckedSingle
                , onUpdateCheckedRowKeys = Just DtCheckedSingleChange
            }
        ]
    , demoRow theme
        "dat-039"
        "Selection extra"
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
                , checkedRowKeys = model.dtCheckedExtra
                , onUpdateCheckedRowKeys = Just DtCheckedExtraChange
            }
        ]
    , demoRow theme
        "dat-040"
        "Expand"
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
                , expandedRowKeys = model.dtExpandedKeys
                , onUpdateExpandedRowKeys = Just DtExpandedToggle
            }
        ]
    , demoRow theme
        "dat-041"
        "Scroll X + fixed columns"
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
    , demoRow theme
        "dat-042"
        "Max height (discrete header)"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , maxHeight = Just 120
            }
        ]
    , demoRow theme
        "dat-043"
        "Flex height"
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
    , demoRow theme
        "dat-044"
        "Ellipsis"
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
    , demoRow theme
        "dat-045"
        "Loading"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , loading = True
            }
        ]
    , demoRow theme
        "dat-046"
        "Table layout fixed"
        [ DataTable.view theme
            { dtD
                | columns = columns
                , data = people_
                , rowKey = .name
                , tableLayout = DataTable.TableFixed
            }
        ]
    , demoRow theme
        "dat-047"
        "Group header"
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
    , demoRow theme
        "dat-048"
        "Summary (Σ45 · bottom / top)"
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
    , demoRow theme
        "dat-049"
        "Merge cells (row 0 · colspan 2 / rowspan 2)"
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


dataTableSection : Model -> Theme -> Element Msg
dataTableSection model theme =
    section theme
        "Data Table"
        "The advanced table (upstream `NDataTable`) — column definitions drive the colgroup, header cells and body cells; `rowKey` keys rows and the empty state renders `NEmpty`. Selection (checkbox / radio / extra menu), row expansion, scroll-X / fixed columns / max-height / flex-height (the discrete-header split), ellipsis columns, the loading overlay, the filter surface (trigger, pipeline, exported `filterMenu` body) and the structure extras — group headers (`children`), summary rows (`summary` / `summaryPlacement`) and merge cells (`colSpan` / `rowSpan` / `titleColSpan` — a swallowed slot renders no td) — ship in this batch, on top of sorting and pagination. The sort / page / checked / expanded / filter state is caller-owned — this page is static, so nothing is wired (the open menu is the caller's `NUI.Popover` runtime)."
        (dataTableRows model theme)


dataTableLiveRow : Model -> Theme -> Element Msg
dataTableLiveRow model theme =
    demoRow theme
        "dat-050"
        "Data Table · selection + sort + pagination"
        [ let
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
            , caption theme
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
        ]


dataTableLiveSection : Model -> Theme -> Element Msg
dataTableLiveSection model theme =
    section theme
        "Data Table"
        "The advanced table (upstream `NDataTable`) — column definitions drive the colgroup, header cells and body cells; `rowKey` keys rows and the empty state renders `NEmpty`. Selection (checkbox / radio / extra menu), row expansion, scroll-X / fixed columns / max-height / flex-height (the discrete-header split), ellipsis columns, the loading overlay, the filter surface (trigger, pipeline, exported `filterMenu` body) and the structure extras — group headers (`children`), summary rows (`summary` / `summaryPlacement`) and merge cells (`colSpan` / `rowSpan` / `titleColSpan` — a swallowed slot renders no td) — ship in this batch, on top of sorting and pagination. The sort / page / checked / expanded / filter state is caller-owned — this page is static, so nothing is wired (the open menu is the caller's `NUI.Popover` runtime)."
        (dataTableRows model theme ++ [ dataTableLiveRow model theme ])



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


transferRows : Model -> Theme -> List (Element Msg)
transferRows model theme =
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
    [ demoRow theme
        "dat-051"
        "Basic"
        [ Transfer.view theme
            { trD
                | options = opts
                , value = model.transferValue2
                , sourceTitle = Just "Source"
                , targetTitle = Just "Target"
                , onCheck = Just TransferSamplesCheck
            }
        ]
    , demoRow theme
        "dat-052"
        "Filterable + large"
        [ Transfer.view theme
            { trD
                | options = opts
                , value = model.transferValueLarge
                , size = T.Large
                , sourceFilterable = True
                , targetFilterable = True
                , sourceFilterPlaceholder = Just "Search"
                , onCheck = Just TransferLargeCheck
            }
        ]
    , demoRow theme
        "dat-053"
        "Disabled + empty target"
        [ Transfer.view theme
            { trD
                | options = opts
                , disabled = True
                , sourceTitle = Just "Source"
            }
        ]
    , demoRow theme
        "dat-054"
        "Empty options"
        [ Transfer.view theme
            { trD | sourceTitle = Just "Source", targetTitle = Just "Target" }
        ]
    , demoRow theme
        "dat-055"
        "All checked + custom texts"
        [ Transfer.view theme
            { trD
                | options = opts
                , value = model.transferValueAll
                , selectAllText = Just "Pick everything"
                , clearText = Just "Drop everything"
                , onCheck = Just TransferAllCheck
            }
        ]
    ]


transferSection : Model -> Theme -> Element Msg
transferSection model theme =
    section theme
        "Transfer"
        "Naive UI's Transfer: two searchable lists with a shuttle between them — move options in bulk or one by one, with select-all and clear affordances per side. The chosen value, the search patterns and the disabled options are caller-owned state. Rows show the plain form, filtered and disabled variants."
        (transferRows model theme)


transferLiveRow : Model -> Theme -> Element Msg
transferLiveRow model theme =
    demoRow theme
        "dat-056"
        "Transfer · move + filter"
        [ Element.column [ Element.spacing 10 ]
            [ Transfer.view theme (transferOpts model)
            , caption theme
                [ "value: " ++ listLabel model.transferValue
                , "source filter: \"" ++ model.transferSourcePattern ++ "\""
                , "target filter: \"" ++ model.transferTargetPattern ++ "\""
                ]
            , note theme
                "Item toggles, select-all / unselect-all and clear all collapse into the single onCheck channel with the next value list (upstream doUpdateValue); the two filter inputs feed onSourceFilterInput / onTargetFilterInput and ride back in as patterns."
            ]
        ]


transferLiveSection : Model -> Theme -> Element Msg
transferLiveSection model theme =
    section theme
        "Transfer"
        "Naive UI's Transfer: two searchable lists with a shuttle between them — move options in bulk or one by one, with select-all and clear affordances per side. The chosen value, the search patterns and the disabled options are caller-owned state. Rows show the plain form, filtered and disabled variants."
        (transferRows model theme ++ [ transferLiveRow model theme ])



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


uploadRows : Theme -> List (Element msg)
uploadRows theme =
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
    [ demoRow theme
        "dat-057"
        "Text list (all statuses)"
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
    , demoRow theme
        "dat-058"
        "Uploading (line progress + cancel)"
        [ Upload.view theme
            (withId "live-upload-uploading"
                { upD
                    | fileList = [ file "u" "video.mp4" Upload.Uploading (Just 42) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow theme
        "dat-059"
        "Error (error kind + retry)"
        [ Upload.view theme
            (withId "live-upload-error"
                { upD
                    | fileList = [ file "e" "broken.zip" Upload.Error (Just 73) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow theme
        "dat-060"
        "Image type"
        [ Upload.view theme
            (withId "live-upload-image"
                { upD
                    | listType = Upload.Image
                    , fileList =
                        [ file "i" "photo.jpg" Upload.Uploading (Just 30) Nothing Nothing (Just "image/jpeg") ]
                }
            )
        ]
    , demoRow theme
        "dat-061"
        "Image card (thumbnail anchor / icon)"
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
    , demoRow theme
        "dat-062"
        "Dragger trigger"
        [ Upload.view theme
            (withId "live-upload-dragger"
                { upD
                    | draggerInside = True
                    , triggerNode = Just (Upload.viewDragger upD [ Element.text "Click or drag a file here" ])
                }
            )
        ]
    , demoRow theme
        "dat-063"
        "Disabled"
        [ Upload.view theme
            (withId "live-upload-disabled"
                { upD
                    | disabled = True
                    , fileList = [ file "a" "a.png" Upload.Uploading (Just 5) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow theme
        "dat-064"
        "Max reached (trigger disabled)"
        [ Upload.view theme
            (withId "live-upload-max"
                { upD
                    | max = Just 1
                    , fileList = [ file "a" "a.png" Upload.Finished (Just 100) Nothing Nothing Nothing ]
                }
            )
        ]
    , demoRow theme
        "dat-065"
        "Directory"
        [ Upload.view theme
            (withId "live-upload-directory" { upD | directory = True })
        ]
    , demoRow theme
        "dat-066"
        "renderIcon + alwaysShowActions"
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
    ]


uploadSection : Theme -> Element msg
uploadSection theme =
    section theme
        "Upload"
        "A file-picker trigger over a caller-owned file list — attachments, photo galleries, bulk import. Each `FileInfo` carries status and progress as plain data, so uploading state, retries and thumbnails are yours to own; the port ships no XHR, and this demo simulates the state machine. The rows tour text lists, image cards, a dragger and max/disabled states, then a live simulated upload and an abstract-trigger composition."
        (uploadRows theme)


uploadAbstractRow : Model -> Theme -> Element Msg
uploadAbstractRow model theme =
    let
        upD =
            Upload.defaults

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
    demoRow theme
        "dat-067"
        "Abstract trigger (simulated pick)"
        [ Element.column [ Element.spacing 10, Element.width Element.fill ]
            (Upload.viewAbstract theme
                { upD
                    | fileList = model.abstractFiles
                    , showFileList = False
                    , onFileChange = Just UploadAbstractPick
                    , onRemove = Just UploadAbstractRemove
                }
                (Element.el
                    [ Element.htmlAttribute (HA.id "live-upload-abstract-slot")
                    , Element.htmlAttribute (HE.onClick UploadAbstractPick)
                    , Element.pointer
                    ]
                    (Element.text "Click to add a simulated file")
                )
                ++ [ Upload.viewFileList theme
                        { upD
                            | fileList = model.abstractFiles
                            , onRemove = Just UploadAbstractRemove
                        }
                   , Element.row [ Element.spacing 6 ]
                        [ Button.view theme
                            { btn | size = T.Tiny, onPress = Just UploadAbstractAdvance }
                            [ Element.text "Advance progress" ]
                        ]
                   , caption theme (List.map statusLabel model.abstractFiles)
                   , note theme
                        "Abstract mode renders a Fragment — the hidden file input plus your slot, no .n-upload root. The click is the caller's (wire it on the slot; here it appends a simulated pending file), onFileChange rides the hidden input's change, and the file list is placed separately through viewFileList. Real pickers and XHR are host JS — see the port's caller-owned contract."
                   ]
            )
        ]


uploadLiveRow : Model -> Theme -> Element Msg
uploadLiveRow model theme =
    demoRow theme
        "dat-068"
        "Upload · simulated file list"
        [ let
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
            , caption theme (List.map statusLabel model.files ++ [ model.uploadNote ])
            , note theme
                "Real pickers and XHR need JS — simulated per the port's caller-owned contract: the trigger click appends a fake pending file (pendingFile + appendFile), the ticker walks the mark* state machine (Uploading → Finished, or Error for broken-*.zip to drive the retry button), and onRemove / onRetry / onPreview / onDownload carry file ids."
            ]
        ]


uploadLiveSection : Model -> Theme -> Element Msg
uploadLiveSection model theme =
    section theme
        "Upload"
        "A file-picker trigger over a caller-owned file list — attachments, photo galleries, bulk import. Each `FileInfo` carries status and progress as plain data, so uploading state, retries and thumbnails are yours to own; the port ships no XHR, and this demo simulates the state machine. The rows tour text lists, image cards, a dragger and max/disabled states, then a live simulated upload and an abstract-trigger composition."
        (uploadRows theme ++ [ uploadAbstractRow model theme, uploadLiveRow model theme ])



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
        , caption theme [ submitted ]
        , note theme
            "The pure engine runs in update per the header's recipe: typing / blurring validate the triggered rules (validateValue with OnInput / OnBlur / OnChange), Submit runs every rule through validateForm and only collects the values when both fields are clean; the feedback rides back into the items' validation slot."
        ]



-- CAPTION HELPERS


caption : Theme -> List String -> Element Msg
caption theme labels =
    Element.row [ Element.spacing 6 ] (List.map (chip theme) labels)


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
sections : Model -> Theme -> List (Element Msg)
sections model theme =
    [ dynamicTagsLiveSection model theme
    , calendarLiveSection model theme
    , dynamicInputLiveSection model theme
    , tableLiveSection model theme
    , treeLiveSection model theme
    , imageLiveSection model theme
    , imagePreviewLiveSection model theme
    , dataTableLiveSection model theme
    , transferLiveSection model theme
    , uploadLiveSection model theme
    ]
