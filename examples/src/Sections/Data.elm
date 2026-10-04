module Sections.Data exposing (calendarSection, dataTableSection, dynamicInputSection, dynamicTagsSection, imagePreviewSection, imageSection, tableSection, transferSection, treeSection, uploadSection)

{-| Static showcase sections for the data display/entry family, moved
verbatim from Main.elm — the rendered DOM must stay byte-identical (the
check-dom gate reads this surface).
-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Calendar as Calendar
import NUI.DataTable as DataTable
import NUI.DynamicInput as DynamicInput
import NUI.DynamicTags as DynamicTags
import NUI.Image as Image
import NUI.ImageGroup as ImageGroup
import NUI.ImagePreview as ImagePreview
import NUI.Pagination as Pagination
import NUI.Table as Table
import NUI.Transfer as Transfer
import NUI.Tree as Tree
import NUI.Types as T
import NUI.Upload as Upload
import Showcase exposing (demoRow, section, theme)


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


dynamicTagsSection : Element msg
dynamicTagsSection =
    section "Dynamic Tags" "Editable tag lists (the tags, input and draft are caller-owned)." <|
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


calendarSection : Element msg
calendarSection =
    section "Calendar" "A month view (the panel, value and locale are caller-owned)." <|
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


dynamicInputSection : Element msg
dynamicInputSection =
    section "DynamicInput"
        "A list of values, each row an input (or key / value pair) with add / remove / sort actions. Pure list core: `insertAt` / `removeAt` / `moveUp` / `moveDown`, guarded by `min` / `max`."
    <|
        -- The component fills its mount (`width fill` on the root), so the demos
        -- mount it directly in the card — a fixed-px wrapper left the dashed
        -- "+ Create" button spanning only that wrapper, not the full card.
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


tableSection : Element msg
tableSection =
    section "Table"
        "Naive UI's static table — the real `<table class=\"n-table\">` root (six modifier classes, the 21 `--n-*` vars with the three size-keyed ones resolved) over a typed `thead` / `tbody` tree of `th` / `td` cells (`colspan` / `rowspan` first-class, `Element` content embedded through `display: contents`). Fully static — nothing runtime."
    <|
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


treeSection : Element msg
treeSection =
    section "Tree"
        "Naive UI's tree — the `div.n-tree` root (17 `--n-*` vars; three derived from the wrapper-padding/height strings) rendering the flattened visible nodes as `n-tree-node-wrapper` rows: a `showLine` indent chain, the switcher (arrow svg, the loading spinner for `loadingKeys` keys — sw20/r85 baseline under the `spin*` overrides), the `data-checkbox`-wrapped `NUI.Checkbox` (cascade-checked via the shipped treemate helpers), and the prefix/label/suffix content. Everything interactive is data: `expandedKeys` / `checkedKeys` / `selectedKeys` / `pendingKey` / `loadingKeys` / `dropMark`; the pure helpers (`flatten`, `getCheckedKeys`, `check` / `uncheck`, `toggleExpand`, `toggleSelect`, `getNonLeafKeys`, `filterTree`) do the treemate math. Not ported: virtual list, expand motion, drag/keyboard events."
    <|
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


imageSection : Element msg
imageSection =
    section "Image"
        "The img surface (upstream `NImage`): `n-image` root + img with the full upstream attribute pack (`data-error`, `data-preview-src`, `data-group-id`, native `loading`, `object-fit`). Load/error/lazy state is caller-owned — `showError` flips the img to `fallbackSrc` + the `--preview-disabled` class, or swaps in the error slot replacing the img entirely; a `placeholder` renders while `loaded` is False and hides the img 0×0 (upstream bytes). The preview modal is the caller's seam (`onClick` + the preview-container `cssVars`)."
    <|
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


imagePreviewSection : Element msg
imagePreviewSection =
    section "Image Preview & Group"
        "The preview modal family (upstream `NImagePreview`/`NImageGroup`): container (the five toolbar `--n-*` vars) > overlay (click-to-close seat) > toolbar (prev/next only when `onPrev` is set — upstream keys both on `onPrev` — then rotate CCW/CW, original size, zoomOut, zoomIn, download, close) > wrapper > `img.n-image-preview`. The runtime is caller-owned (`NUI.Modal` precedent): `zoom` starts at `zoom0` and moves through the pure transforms (`zoomIn`/`zoomOut`/`rotateClockwise`/`resizeToOriginalSize`/`toggleOriginalSize`/`switchReset`), drag clamps through `moveStrategy` + `derivedOffset`, document keys map through `keyAction`, and `syncTransformOrigin` writes the thumbnail's center into `wrapperStyle`. The group adds the url registry (`srcList` wins with `p${index}` keys, else the caller-threaded `registered` ids) and the wrap-around walk (`nextIndex`/`prevIndex` skip empty urls). Demo cells confine the fixed tree like the modal demos."
    <|
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


dataTableSection : Element msg
dataTableSection =
    let
        dtD =
            DataTable.defaults

        colD =
            DataTable.columnDefaults

        person name age address =
            { name = name
            , age = age
            , address = address
            }

        people =
            [ person "Jesse Tripps" 28 "0350 Nesrnew Drive, Bellevue, WA"
            , person "Jaime Whyte" 32 "1512 Radney Street, Dallas, TX"
            , person "Boris Wuhrer" 41 "785 Skiles Walks, Roseville, WA"
            , person "Terry Malany" 22 "752 Sutter Avenue, Sacramento, CA"
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
    section "Data Table"
        "The advanced table (upstream `NDataTable`) — column definitions drive the colgroup, header cells and body cells; `rowKey` keys rows and the empty state renders `NEmpty`. Selection (checkbox / radio / extra menu), row expansion, scroll-X / fixed columns / max-height / flex-height (the discrete-header split), ellipsis columns, the loading overlay, the filter surface (trigger, pipeline, exported `filterMenu` body) and the structure extras — group headers (`children`), summary rows (`summary` / `summaryPlacement`) and merge cells (`colSpan` / `rowSpan` / `titleColSpan` — a swallowed slot renders no td) — ship in this batch, on top of sorting and pagination. The sort / page / checked / expanded / filter state is caller-owned — this page is static, so nothing is wired (the open menu is the caller's `NUI.Popover` runtime)."
    <|
        [ demoRow "Basic"
            [ DataTable.view theme
                { dtD | columns = columns, data = people, rowKey = .name }
            ]
        , demoRow "Striped + bordered"
            [ DataTable.view theme
                { dtD
                    | columns = columns
                    , data = people
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
                { dtD | columns = sortableColumns, data = people, rowKey = .name }
            , DataTable.view theme
                { dtD
                    | columns = sortableColumns
                    , data = people
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
                    , data = people
                    , rowKey = .name
                    , pagination = Just { dtPg | pageSize = Just 2 }
                }
            ]
        , demoRow "Sort + pagination"
            [ DataTable.view theme
                { dtD
                    | columns = sortableColumns
                    , data = people
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
                { dtD | columns = filterColumns, data = people, rowKey = .name }
            , DataTable.view theme
                { dtD
                    | columns = filterColumns
                    , data = people
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
                    , data = people
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
                    , data = people
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
                    , data = people
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
                    , data = people
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
                    , data = people
                    , rowKey = .name
                    , scrollX = Just 600
                }
            ]
        , demoRow "Max height (discrete header)"
            [ DataTable.view theme
                { dtD
                    | columns = columns
                    , data = people
                    , rowKey = .name
                    , maxHeight = Just 120
                }
            ]
        , demoRow "Flex height"
            [ Element.el [ Element.height (Element.px 220), Element.width Element.fill ]
                (DataTable.view theme
                    { dtD
                        | columns = columns
                        , data = people
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
                    , data = people
                    , rowKey = .name
                }
            ]
        , demoRow "Loading"
            [ DataTable.view theme
                { dtD
                    | columns = columns
                    , data = people
                    , rowKey = .name
                    , loading = True
                }
            ]
        , demoRow "Table layout fixed"
            [ DataTable.view theme
                { dtD
                    | columns = columns
                    , data = people
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
                    , data = people
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
                    , data = people
                    , rowKey = .name
                }
            ]
        ]


transferSection : Element msg
transferSection =
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
    section "Transfer"
        "Two lists with select-all / clear — value and patterns are caller-owned."
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


uploadSection : Element msg
uploadSection =
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
    section "Upload"
        "A file trigger over a caller-owned file list — pick/drag, upload state and thumbnails are the caller's to own."
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
