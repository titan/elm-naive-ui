module NUI.DataTable exposing
    ( Align(..)
    , Column
    , Options
    , Size(..)
    , SortOrder(..)
    , SortState
    , SortValue(..)
    , Sorter(..)
    , SorterCompare(..)
    , boundedPage
    , columnDefaults
    , createNextSorter
    , cssVars
    , defaultSortStates
    , defaults
    , deriveNextSorter
    , filteredData
    , getMultiplePriority
    , getSortFunction
    , isColumnSorting
    , isSortable
    , mergedItemCount
    , mergedPageSize
    , mergedPaginationOpts
    , mergedSortStates
    , nextSortOrder
    , paginatedData
    , showPagination
    , sortValueCompare
    , sortedData
    , view
    )

{-| Naive UI's `DataTable` (`n-data-table`), the advanced data table —
rebuilt on elm-ui.

    import NUI.DataTable exposing (columnDefaults, defaults)

    NUI.DataTable.view theme
        { defaults
            | rowKey = .id
            , columns =
                [ { columnDefaults | key = "name", title = "Name", view = .name >> Element.text }
                , { columnDefaults
                    | key = "age"
                    , title = "Age"
                    , view = .age >> String.fromInt >> Element.text
                    , width = Just 120
                  }
                ]
            , data = rows
        }

(Record updates bind `defaults` to a local first — see `NUI.Button`.)

DOM (batch-2 — one table, the header lives inside the body table, the
pagination node after the wrapper):

    div.n-data-table [--rtl] [--bordered] [--bottom-bordered] [--single-line]
                     [--single-column] [--empty]        (empty iff no paginated rows)
      style = the 47 `--n-*` vars
      ├─ div.n-data-table-wrapper
      │  └─ div.n-data-table-base-table
      │     └─ div.n-data-table-base-table-body (the `n-scrollbar` root)
      │        └─ div.n-scrollbar-container > div.n-scrollbar-content
      │           ├─ table.n-data-table-table [inline table-layout:auto]
      │           │  ├─ colgroup > col (style width/min-width/max-width — always)
      │           │  ├─ thead.n-data-table-thead[data-n-id]
      │           │  │  └─ tr.n-data-table-tr > th[data-col-key]
      │           │  │     [--sorting] [--sortable] [--last]
      │           │  │     └─ div.n-data-table-th__title-wrapper
      │           │  │        ├─ div.n-data-table-th__title              (iff showHeader)
      │           │  │        └─ span.n-data-table-sorter [--asc|--desc] (iff column sortable)
      │           │  │           └─ i.n-base-icon > svg (the arrow-down glyph)
      │           │  └─ tbody.n-data-table-tbody[data-n-id]             (iff paginated rows)
      │           │     └─ tr.n-data-table-tr [--striped] > td[data-col-key]
      │           │        (td gains --sorting when the column is actively sorting)
      │           └─ div.n-data-table-empty > NEmpty                    (iff no paginated rows)
      └─ div.n-data-table__pagination > NPagination + the prefix slot   (iff pagination shown)

Cell content is `Element msg`, embedded through `Element.layoutWith`
(`display: contents`, the `NUI.Table` precedent); the scroll area is
`NUI.Scrollbar.view`, the empty state `NUI.Empty.view` and the pager
`NUI.Pagination.view`.

Divergences (documented):

  - **Batch-2 scope.** Sort and pagination ship here; filter, selection,
    expand, loading, fixed columns, scrollX, group headers, summary rows,
    virtual scroll and resizable columns are upcoming batches.
    `maxHeight`/`flexHeight` (which split the header into its own table)
    are not modelled, so the header always renders inside the single body
    table — upstream's `headerInBody` path.
  - **Render-prop sorter customizations are not modelled.** Upstream's
    `renderSorter` / `renderSorterIcon` (per-column and the global
    `DataTable.renderSorter` component prop) and `customNextSortOrder` have
    no Elm surface: the sort button always renders the base icon span and
    the click cycle is fixed `false → descend → ascend`.
  - **An ordinal `compare` stands in for `localeCompare`** in the default
    sorter (`sortValueCompare`) — Elm has no `String.compare` / ICU
    collation, so string ordering is by code point.
  - **One page / page-size handler channel.** Upstream fires the pagination
    object's own handlers, then the table-level `onUpdate:page` /
    `onUpdate:pageSize`, then the deprecated `onChange` / `onPageSizeChange`,
    then writes uncontrolled refs; Elm carries the table-level
    `onUpdatePage` / `onUpdatePageSize` only, and `mergedPaginationOpts`
    replaces the pagination record's own handlers with them. Upstream also
    force-disables the pager while `loading` — that override arrives with
    the loading batch.
  - **`pagination.defaultPage` / `defaultPageSize` seeds are caller-owned.**
    `NUI.Pagination` has no such fields, so callers seed their model and
    pass `currentPage` / `pageSize` explicitly; the pagination prefix
    (upstream: a render-prop on the pagination object) rides
    `paginationPrefix` into the pager's prefix slot.
  - **The sort click handler only attaches to a th when the column is
    sortable and `onSorterChange` is set.** Upstream attaches the listener
    to every basic-column th and no-ops inside it — listener presence is
    not a DOM byte, so this is a compile-time guard, not a port change.
  - **JS sort is stable by spec**; `List.sortWith`'s tie order is an
    implementation detail — if a pinned tie order ever disagrees, re-derive
    from the upstream bytes.
  - **`data-n-id` is the constant `"1"`.** Upstream stamps a random seemly
    component id on thead/tbody; it only keys the fixed-column shadow
    cssr that a later batch will port.
  - **`table-layout` is pinned to `auto`** (upstream's default `tableLayout`
    prop; upstream switches to `fixed` for virtual scroll / flexHeight /
    maxHeight / ellipsis columns — all batch-3+ surfaces).
  - **`title` is a plain `String`** until the header-render batch (upstream
    also accepts a render function returning VNodes).
  - **`rowAttributes` land verbatim after the row's `class` attribute.**
    Upstream merges `rowProps(row, index).class` into the row's class list;
    Elm attributes are opaque, and a caller `Html.Attributes.class` would
    replace the whole `className` (Elm properties are last-wins), so prefer
    `rowClassName` for classes.
  - **Scrollbar-content children ride elm-ui layout wrappers.** The table
    and the empty node reach `.n-scrollbar-content` as
    `display: contents` wrapper divs (the `NUI.Scrollbar` child-embedding
    shape shared with the menu consumers), not as flat children — the
    first raw `<table>` consumer. Verified equivalent: no cssr rule on
    either side uses a direct-child combinator past the content div, and
    the `--empty` height chain targets the content div itself.
  - **`Column.width` is `Maybe Int` (px).** Upstream accepts
    `number | string` (`'10%'`); a string form arrives if a batch needs it.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events
import NUI.Empty
import NUI.Internal as I
import NUI.Pagination
import NUI.Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.DataTable as DataTableTheme
import Svg


{-| Upstream `DataTableSize` — `'small' | 'medium' | 'large'`; like upstream
it emits no class and only keys the font-size / th-padding / td-padding
variables (`mergedSizeRef` defaults medium).
-}
type Size
    = Small
    | Medium
    | Large


{-| Upstream `CommonColumnInfo.align` — `'left' | 'center' | 'right'`. Sets the
inline `text-align` on the cells (and the header unless `titleAlign`
overrides it) and, redundantly, the `n-data-table-td--{align}-align` class.
-}
type Align
    = AlignLeft
    | AlignCenter
    | AlignRight


{-| Upstream `SortOrder` — `'ascend' | 'descend' | false` (`NoSort` is the
`false`; upstream's comment notes `null` may be added for compat). Drives
the sorter icon's `--asc` / `--desc` flags and the comparator's sign.
-}
type SortOrder
    = Ascend
    | Descend
    | NoSort


{-| The realization of upstream's `row[columnKey]` for the default sorter —
the three shapes `getDefaultSorterFn` distinguishes: `null`, number, string
(Elm columns have no `row[columnKey]`, so the caller supplies the accessor).
-}
type SortValue
    = SortNumber Float
    | SortString String
    | SortNull


{-| The `compare` field of upstream's `SorterMultiple` — `'default'`
(`CompareDefault`, over the `SortValue` accessor) or an explicit compare fn
(`CompareBy`); an absent `compare` is modelled by `Nothing` at the
`SorterMultiple` site.
-}
type SorterCompare row
    = CompareDefault (row -> SortValue)
    | CompareBy (row -> row -> Basics.Order)


{-| Upstream `Column.sorter` (`Sorter<T> | boolean | 'default'`):
`SorterDefault` is `sorter: 'default'`, `SorterBy` a plain compare fn,
`SorterMultiple` the `{ multiple, compare? }` object, `SorterAsync`
`sorter: true` (async/remote sorting — the state is tracked and rendered,
the data is the caller's). Upstream's `false` / `undefined` (show nothing)
is the plain `Column.sorter = Nothing`.
-}
type Sorter row
    = SorterDefault (row -> SortValue)
    | SorterBy (row -> row -> Basics.Order)
    | SorterMultiple Int (Maybe (SorterCompare row))
    | SorterAsync


{-| Upstream `SortState` — one column's live sort: its key, its order and
the sorter it was seeded from. Upstream also lets the state's `sorter` be
`false` / `true` / `'default'`; the show-nothing `false` has no state here
(it is `Column.sorter = Nothing` before it ever becomes one).
-}
type alias SortState row =
    { columnKey : String
    , order : SortOrder
    , sorter : Sorter row
    }


{-| One column — upstream's basic `TableBaseColumn` (`type: undefined`):
`key` sources the `data-col-key` attribute, `view` renders the cell body
(upstream `render`, falling back to `row[key]`). The width fields feed the
`<col>` / `<th>` / `<td>` styles exactly like upstream's
`createCustomWidthStyle` (a set `width` also backs an unset `minWidth` on
the `<col>` only). `className` lands on both the `th` and every `td` of
the column, after the base class. The sorter fields: `sorter` opts the
column into sorting (`isColumnSortable`), `defaultSortOrder` seeds the
initial uncontrolled state (`NoSort` ≙ upstream's `false`), `sortOrder`
marks the column controlled — its `Just` value (a `NoSort` included) wins
over the uncontrolled list.
-}
type alias Column row msg =
    { key : String
    , title : String
    , view : row -> Element msg
    , align : Maybe Align
    , titleAlign : Maybe Align
    , width : Maybe Int
    , minWidth : Maybe Int
    , maxWidth : Maybe Int
    , className : Maybe String
    , sorter : Maybe (Sorter row)
    , defaultSortOrder : SortOrder
    , sortOrder : Maybe SortOrder
    }


{-| The column placeholders — `key` / `title` / `view` are the caller's to
set (the keyless rest is `Nothing` / `NoSort`).
-}
columnDefaults : Column row msg
columnDefaults =
    { key = ""
    , title = ""
    , view = \_ -> Element.none
    , align = Nothing
    , titleAlign = Nothing
    , width = Nothing
    , minWidth = Nothing
    , maxWidth = Nothing
    , className = Nothing
    , sorter = Nothing
    , defaultSortOrder = NoSort
    , sortOrder = Nothing
    }


{-| The data-table options (upstream `dataTableProps`):
`bordered`, `bottomBordered` and `singleLine` default `True` (upstream's
booleans). `bottomBordered` is emitted only when `bordered` is off —
upstream `mergedBottomBordered` (the wrapper border wins when bordered).
`--single-line` keeps upstream's inverted CSS semantics: `True` means _no_
vertical cell borders (`cNotM('single-line')` rules add them). The sort /
pagination surface: `sortStates` is the uncontrolled sort state (seed it
with `defaultSortStates`), `onSorterChange` the click channel (without it
the sortable headers render but never fire), `remote` hands the data and
the page window to the caller, `pagination` carries the
`NUI.Pagination.Options` object merged per upstream, `paginationPrefix`
its prefix slot, and `onUpdatePage` / `onUpdatePageSize` the table-level
handlers that replace the object's own (see the divergence notes).
-}
type alias Options row msg =
    { columns : List (Column row msg)
    , data : List row
    , rowKey : row -> String
    , size : Size
    , bordered : Bool
    , bottomBordered : Bool
    , singleLine : Bool
    , singleColumn : Bool
    , striped : Bool
    , rowClassName : Maybe (row -> Int -> String)
    , rowAttributes : Maybe (row -> Int -> List (Html.Attribute msg))
    , showHeader : Bool
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    , sortStates : List (SortState row)
    , onSorterChange : Maybe (List (SortState row) -> msg)
    , remote : Bool
    , paginateSinglePage : Bool
    , pagination : Maybe (NUI.Pagination.Options msg)
    , paginationPrefix : List (Element msg)
    , onUpdatePage : Maybe (Int -> msg)
    , onUpdatePageSize : Maybe (Int -> msg)
    }


defaults : Options row msg
defaults =
    { columns = []
    , data = []
    , rowKey = \_ -> ""
    , size = Medium
    , bordered = True
    , bottomBordered = True
    , singleLine = True
    , singleColumn = False
    , striped = False
    , rowClassName = Nothing
    , rowAttributes = Nothing
    , showHeader = True
    , rtl = False
    , attributes = []
    , sortStates = []
    , onSorterChange = Nothing
    , remote = False
    , paginateSinglePage = True
    , pagination = Nothing
    , paginationPrefix = []
    , onUpdatePage = Nothing
    , onUpdatePageSize = Nothing
    }



-- VIEW -------------------------------------------------------------------------


{-| The data table — the `n-data-table` root carrying the modifier classes
(`DataTable.tsx` render's class array, minus the batch-4 `--loading` /
`--flex-height` and the inline-theme `themeClass`) and the 47-var inline
set, over the wrapper → base-table → scrollbar → single-table chain, with
the pagination node after the wrapper (`mergedShowPagination` decides it;
upstream's loading transition follows in a later batch).
-}
view : Theme -> Options row msg -> Element msg
view theme opts =
    let
        empty =
            paginatedData opts == []

        bottomBordered =
            if opts.bordered then
                False

            else
                opts.bottomBordered
    in
    Element.column
        ([ I.classes (rootClasses opts bottomBordered empty)
         , I.cssVars (cssVars theme opts.size)
         ]
            ++ opts.attributes
        )
        [ Element.el [ I.classes [ "n-data-table-wrapper" ] ]
            (Element.el [ I.classes [ "n-data-table-base-table" ] ]
                (scrollbarNode theme opts)
            )
        , paginationNode theme opts
        ]


{-| The root's class list — `n-data-table` plus the modifiers in upstream's
class-array order, each only when truthy. `--empty` keys off the paginated
data (upstream `mergedEmpty`: paginated data length 0) and
`--bottom-bordered` is forced off while `--bordered` is on.
-}
rootClasses : Options row msg -> Bool -> Bool -> List String
rootClasses opts bottomBordered empty =
    [ "n-data-table" ]
        ++ I.classIf opts.rtl "n-data-table--rtl"
        ++ I.classIf opts.bordered "n-data-table--bordered"
        ++ I.classIf bottomBordered "n-data-table--bottom-bordered"
        ++ I.classIf opts.singleLine "n-data-table--single-line"
        ++ I.classIf opts.singleColumn "n-data-table--single-column"
        ++ I.classIf empty "n-data-table--empty"


{-| The pagination node (`DataTable.tsx` render): a sibling AFTER the
wrapper — the bare `div.n-data-table__pagination` carrying only the class,
over the merged pager. Upstream's `disabled={loading}` override on the
pager arrives with the loading batch; the prefix slot rides
`paginationPrefix` (upstream: a render-prop on the pagination object).
-}
paginationNode : Theme -> Options row msg -> Element msg
paginationNode theme opts =
    if showPagination opts then
        Element.el [ I.classes [ "n-data-table__pagination" ] ]
            (NUI.Pagination.view theme (mergedPaginationOpts opts) opts.paginationPrefix)

    else
        Element.none


{-| The scroll area — upstream's body `NScrollbar` with the
`n-data-table-base-table-body` fallthrough class on its root and
`contentStyle = minWidth: 100%` (upstream `formatLength(scrollX) || '100%'`;
no `scrollX` in this batch). Children: the table, then — upstream
`{this.empty ? createEmptyNode() : null}` right after `</table>` — the
empty state, a sibling inside the scrollbar content (empty keys off the
paginated data).
-}
scrollbarNode : Theme -> Options row msg -> Element msg
scrollbarNode theme opts =
    let
        sb =
            NUI.Scrollbar.defaults
    in
    NUI.Scrollbar.view theme
        { sb
            | extraClasses = [ "n-data-table-base-table-body" ]
            , contentStyle = Just "min-width: 100%"
        }
        (tableNode opts
            :: (if paginatedData opts == [] then
                    [ Element.el [ I.classes [ "n-data-table-empty" ] ]
                        (NUI.Empty.view theme NUI.Empty.defaults [])
                    ]

                else
                    []
               )
        )


{-| The body's single `<table>` (no maxHeight/flexHeight in this batch, so
there is no separate header table): class + the inline `table-layout`,
then colgroup, thead (iff `showHeader`), tbody (iff paginated rows
non-empty) — `Body.tsx`'s non-virtual render. No `width`/`minWidth` on
this table (the scrollbar content's `min-width` carries it).
-}
tableNode : Options row msg -> Element msg
tableNode opts =
    let
        merged =
            mergedSortStates opts.columns opts.sortStates

        rows =
            paginatedData opts
    in
    Element.html
        (Html.table
            [ HA.class "n-data-table-table"
            , HA.attribute "style" "table-layout:auto"
            ]
            ([ Html.colgroup [] (List.map colNode opts.columns) ]
                ++ theadNode opts merged
                ++ tbodyNode opts merged rows
            )
        )


{-| The colgroup — always rendered, even with no data. One `<col>` per
column whose style is built only from the set width fields, upstream
`createCustomWidthStyle`: `width`, then `min-width` (falling back to
`width`), then `max-width`. All absent → no style attribute (Vue drops the
empty object). The vnode `key` is not a DOM attribute.
-}
colNode : Column row msg -> Html.Html msg
colNode col =
    Html.col
        (case colStyle col of
            Just style ->
                [ HA.attribute "style" style ]

            Nothing ->
                []
        )
        []


{-| `createCustomWidthStyle` (upstream `utils.ts`), byte form without
spaces — `width:{n}px;min-width:{n}px;max-width:{n}px` from the set fields,
`min-width` falling back to `width` when unset.
-}
colStyle : Column row msg -> Maybe String
colStyle col =
    let
        parts =
            List.filterMap identity
                [ stylePart "width" (Maybe.map pxfy col.width)
                , stylePart "min-width"
                    (Maybe.map pxfy (orElse col.minWidth col.width))
                , stylePart "max-width" (Maybe.map pxfy col.maxWidth)
                ]
    in
    if parts == [] then
        Nothing

    else
        Just (String.join ";" parts)


{-| The `<thead>` — upstream `TableHeader` with `discrete={false}` (the
header-in-body path): the bare thead with `data-n-id`, one `tr` with only
its base class, one `th` per column (the sort wiring per `thNode`).
-}
theadNode : Options row msg -> List (SortState row) -> List (Html.Html msg)
theadNode opts merged =
    if opts.showHeader then
        [ Html.thead
            [ HA.class "n-data-table-thead"
            , HA.attribute "data-n-id" "1"
            ]
            [ Html.tr [ HA.class "n-data-table-tr" ]
                (List.map (thNode opts merged) (lastFlags opts.columns))
            ]
        ]

    else
        []


{-| One header cell — `Header.tsx`'s th for a basic column: base class,
then `--sorting` (iff a state names this key with a truthy order), then
`--sortable` (iff the column carries a sorter), then `--last` (last
column), then `column.className`; the always-present `data-col-key`; the
style built only from the set fields (`width`, then `text-align` from
`titleAlign || align`; upstream's fixed offsets and the body-path `height`
are all `undefined` here). `colspan`/`rowspan` render the constant `1` on
every th (upstream always passes them; API-level spans arrive with the
group-header/merge-cell batch); attribute order matches upstream (`style`,
spans, `data-col-key`, `class`, then the sort click handler — last, and
only on a sortable column with `onSorterChange` set). The content is the
title wrapper: title div, then the sorter span when the column is
sortable.
-}
thNode : Options row msg -> List (SortState row) -> ( Column row msg, Bool ) -> Html.Html msg
thNode opts merged ( col, isLast ) =
    let
        sortable =
            isSortable col

        currentState =
            List.filter (\state -> state.columnKey == col.key) merged
                |> List.head

        order =
            currentState
                |> Maybe.map .order
                |> Maybe.withDefault NoSort
    in
    Html.th
        (thStyleAttr col
            ++ [ HA.colspan 1
               , HA.rowspan 1
               , HA.attribute "data-col-key" col.key
               , HA.class
                    (String.join " "
                        ([ "n-data-table-th" ]
                            ++ I.classIf (isColumnSorting col merged) "n-data-table-th--sorting"
                            ++ I.classIf sortable "n-data-table-th--sortable"
                            ++ I.classIf isLast "n-data-table-th--last"
                            ++ maybeClass col.className
                        )
                    )
               ]
            ++ sortClickAttr opts merged col currentState
        )
        [ Html.div [ HA.class "n-data-table-th__title-wrapper" ]
            ([ Html.div [ HA.class "n-data-table-th__title" ]
                [ Html.text col.title ]
             ]
                ++ (if sortable then
                        [ sortButtonNode order ]

                    else
                        []
                   )
            )
        ]


thStyleAttr : Column row msg -> List (Html.Attribute msg)
thStyleAttr col =
    rawStyleAttr
        (stylePairs
            [ ( "width", Maybe.map pxfy col.width )
            , ( "text-align", Maybe.map alignName (orElse col.titleAlign col.align) )
            ]
        )


{-| The th's sort click handler (`Header.tsx` `handleColHeaderClick`, minus
the filter/resizable `happensIn` guards — later batches): the
`deriveNextSorter` of the merged base and the column's next state, fed to
`onSorterChange`. Only present when the column is sortable and the caller
wired the channel (upstream attaches the listener to every basic-column th
and no-ops inside).
-}
sortClickAttr :
    Options row msg
    -> List (SortState row)
    -> Column row msg
    -> Maybe (SortState row)
    -> List (Html.Attribute msg)
sortClickAttr opts merged col current =
    if isSortable col then
        case opts.onSorterChange of
            Just onSorterChange ->
                [ Html.Events.onClick
                    (onSorterChange (deriveNextSorter merged (createNextSorter col current)))
                ]

            Nothing ->
                []

    else
        []


{-| The sorter span (`SortButton.tsx`, name `SortIcon`): base class plus
`--asc` / `--desc` for the merged order of the column, wrapping the
`n-base-icon` arrow-down glyph. Upstream renders a `renderSorter` prop in
place of the whole span when given — not modelled (see the module
divergences).
-}
sortButtonNode : SortOrder -> Html.Html msg
sortButtonNode order =
    Html.span
        [ HA.class
            (String.join " "
                ([ "n-data-table-sorter" ]
                    ++ I.classIf (order == Ascend) "n-data-table-sorter--asc"
                    ++ I.classIf (order == Descend) "n-data-table-sorter--desc"
                )
            )
        ]
        [ Html.i [ HA.class "n-base-icon" ] [ arrowDownIcon ] ]


{-| The arrow-down glyph (upstream `ArrowDownIcon` under `NBaseIcon`) — the
per-component SVG pattern of `NUI.Alert`'s icons (`Svg.node` +
`HA.attribute`).
-}
arrowDownIcon : Html.Html msg
arrowDownIcon =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 28 28"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Svg.node "path" [ HA.attribute "d" arrowDownPath ] [] ]
            ]
        ]


arrowDownPath : String
arrowDownPath =
    "M23.7916,15.2664 C24.0788,14.9679 24.0696,14.4931 23.7711,14.206 C23.4726,13.9188 22.9978,13.928 22.7106,14.2265 L14.7511,22.5007 L14.7511,3.74792 C14.7511,3.33371 14.4153,2.99792 14.0011,2.99792 C13.5869,2.99792 13.2511,3.33371 13.2511,3.74793 L13.2511,22.4998 L5.29259,14.2265 C5.00543,13.928 4.53064,13.9188 4.23213,14.206 C3.93361,14.4931 3.9244,14.9679 4.21157,15.2664 L13.2809,24.6944 C13.6743,25.1034 14.3289,25.1034 14.7223,24.6944 L23.7916,15.2664 Z"


{-| The `<tbody>` — omitted entirely while the paginated data is empty
(upstream `{!this.empty ? <tbody>… : null}`); attribute order matches
upstream (`data-n-id` first here, `class` first on the thead).
-}
tbodyNode : Options row msg -> List (SortState row) -> List row -> List (Html.Html msg)
tbodyNode opts merged rows =
    if rows == [] then
        []

    else
        [ Html.tbody
            [ HA.attribute "data-n-id" "1"
            , HA.class "n-data-table-tbody"
            ]
            (List.indexedMap (trNode opts merged rows) rows)
        ]


{-| One body row — `Body.tsx`'s `renderRow` for a normal row: base class,
then `--striped` (iff `striped && index % 2 === 1` — the parity index runs
over the paginated rows), then the `rowClassName(row, index)` result when
non-empty, then the caller's `rowAttributes` verbatim (see the
`rowAttributes` divergence note).
-}
trNode : Options row msg -> List (SortState row) -> List row -> Int -> row -> Html.Html msg
trNode opts merged rows index row =
    Html.tr
        ([ HA.class
            (String.join " "
                ([ "n-data-table-tr" ]
                    ++ I.classIf (opts.striped && modBy 2 index == 1) "n-data-table-tr--striped"
                    ++ rowClassNameOf opts row index
                )
            )
         ]
            ++ rowAttrsOf opts row index
        )
        (List.map (tdNode opts merged rows index row) (lastFlags opts.columns))


rowClassNameOf : Options row msg -> row -> Int -> List String
rowClassNameOf opts row index =
    case opts.rowClassName of
        Just f ->
            let
                cls =
                    f row index
            in
            if cls == "" then
                []

            else
                [ cls ]

        Nothing ->
            []


rowAttrsOf : Options row msg -> row -> Int -> List (Html.Attribute msg)
rowAttrsOf opts row index =
    case opts.rowAttributes of
        Just f ->
            f row index

        Nothing ->
            []


{-| One body cell — `Body.tsx`'s td for a basic column: class order is base
→ `column.className` → `--sorting` (iff a state names this key with a
truthy order — the whole-column highlight) → `--{align}-align` (iff align
set — redundant with the inline `text-align`, upstream emits both) →
`--last-col` → `--last-row` (last over the paginated rows); the
always-present `data-col-key`; the style always carries the empty
`--indent-offset:` declaration after `text-align`/`width` (upstream seeds
`{'--indent-offset': ''}` unconditionally — only tree children fill the
value), with `colspan`/`rowspan` the constant `1`; the cell body is the
caller's element embedded through `layoutWith`.
-}
tdNode :
    Options row msg
    -> List (SortState row)
    -> List row
    -> Int
    -> row
    -> ( Column row msg, Bool )
    -> Html.Html msg
tdNode opts merged rows rowIndex row ( col, isLastCol ) =
    let
        isLastRow =
            rowIndex + 1 == List.length rows
    in
    Html.td
        (tdStyleAttr col
            ++ [ HA.colspan 1
               , HA.rowspan 1
               , HA.attribute "data-col-key" col.key
               , HA.class
                    (String.join " "
                        ([ "n-data-table-td" ]
                            ++ maybeClass col.className
                            ++ I.classIf (isColumnSorting col merged) "n-data-table-td--sorting"
                            ++ (case col.align of
                                    Just align ->
                                        [ "n-data-table-td--" ++ alignName align ++ "-align" ]

                                    Nothing ->
                                        []
                               )
                            ++ I.classIf isLastCol "n-data-table-td--last-col"
                            ++ I.classIf isLastRow "n-data-table-td--last-row"
                        )
                    )
               ]
        )
        [ embedChild (col.view row) ]


tdStyleAttr : Column row msg -> List (Html.Attribute msg)
tdStyleAttr col =
    let
        parts =
            List.filterMap identity
                [ stylePart "text-align" (Maybe.map alignName col.align)
                , stylePart "width" (Maybe.map pxfy col.width)
                ]
    in
    [ HA.attribute "style" (String.join ";" (parts ++ [ "--indent-offset:" ])) ]


{-| There is no public `Element` → `Html`, so a caller's element is
embedded through `Element.layoutWith` (the `NUI.Table` /
`NUI.Descriptions` precedent). The wrapper carries `display: contents` plus
`font`/`color: inherit`; `noStaticStyleSheet` keeps elm-ui's static
stylesheet from re-clobbering the bridge.
-}
embedChild : Element msg -> Html.Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child



-- SORT -------------------------------------------------------------------------


{-| `getDefaultSorterFn`'s compare (upstream `use-sorter.ts`): null/null
ties, a lone null sorts first, number × number and string × string compare,
anything else ties (upstream `0`). Upstream compares strings with
`localeCompare`; Elm has no ICU collation, so an ordinal `compare` (strings
are `comparable`) stands in — the accepted divergence for non-ASCII
payloads.
-}
sortValueCompare : SortValue -> SortValue -> Basics.Order
sortValueCompare value1 value2 =
    case ( value1, value2 ) of
        ( SortNull, SortNull ) ->
            EQ

        ( SortNull, _ ) ->
            LT

        ( _, SortNull ) ->
            GT

        ( SortNumber number1, SortNumber number2 ) ->
            compare number1 number2

        ( SortString string1, SortString string2 ) ->
            compare string1 string2

        _ ->
            EQ


{-| `getSortFunction` (upstream `use-sorter.ts`) — resolves a sorter to its
compare fn: `'default'` (`SorterDefault`, and a multiple's
`compare: 'default'`) becomes `sortValueCompare` over the accessor, an
explicit fn passes through, a `{ multiple }` without a `compare` and the
async `true` sorter resolve to nothing — the state is still tracked (it
still drives `--sorting` and the sorter icon) but never orders rows.
-}
getSortFunction : Sorter row -> Maybe (row -> row -> Basics.Order)
getSortFunction sorter =
    case sorter of
        SorterDefault accessor ->
            Just (\row1 row2 -> sortValueCompare (accessor row1) (accessor row2))

        SorterBy compareFn ->
            Just compareFn

        SorterMultiple _ maybeCompare ->
            case maybeCompare of
                Just (CompareDefault accessor) ->
                    Just (\row1 row2 -> sortValueCompare (accessor row1) (accessor row2))

                Just (CompareBy compareFn) ->
                    Just compareFn

                Nothing ->
                    Nothing

        SorterAsync ->
            Nothing


{-| `getMultiplePriority` (upstream `use-sorter.ts`) — `Just` the
`multiple` number of a `SorterMultiple`, `Nothing` for every other shape
(upstream's `false`).
-}
getMultiplePriority : Sorter row -> Maybe Int
getMultiplePriority sorter =
    case sorter of
        SorterMultiple multiple _ ->
            Just multiple

        _ ->
            Nothing


{-| `isColumnSortable` (upstream `utils.ts`, minus the group-column guard —
group columns are a later batch): the column carries a sorter.
-}
isSortable : Column row msg -> Bool
isSortable col =
    col.sorter /= Nothing


{-| `isColumnSorting` (upstream `utils.ts`) — some sort state names this
column's key with a truthy order (`Ascend` / `Descend`).
-}
isColumnSorting : Column row msg -> List (SortState row) -> Bool
isColumnSorting col states =
    List.any (\state -> state.columnKey == col.key && state.order /= NoSort) states


{-| The initial uncontrolled state (upstream `defaultSortState`): every
column with a sorter seeds `{ columnKey, sorter, order = defaultSortOrder }`
into the state, upserted by key (`updateSortStatesByNewSortState` — replaced
at the key's index, else appended), in column order.
-}
defaultSortStates : List (Column row msg) -> List (SortState row)
defaultSortStates columns =
    List.foldl
        (\col acc ->
            case col.sorter of
                Nothing ->
                    acc

                Just sorter ->
                    upsertSortState
                        { columnKey = col.key
                        , order = col.defaultSortOrder
                        , sorter = sorter
                        }
                        acc
        )
        []
        columns


{-| `updateSortStatesByNewSortState` (upstream `use-sorter.ts`) — replace
the state at its `columnKey`'s index, else append it.
-}
upsertSortState : SortState row -> List (SortState row) -> List (SortState row)
upsertSortState state states =
    if List.any (\existing -> existing.columnKey == state.columnKey) states then
        List.map
            (\existing ->
                if existing.columnKey == state.columnKey then
                    state

                else
                    existing
            )
            states

    else
        states ++ [ state ]


{-| `mergedSortStateRef` (upstream `use-sorter.ts`) — the effective state:
a column with a sorter and a `sortOrder` is controlled; if any controlled
column actually sorts (order ≠ `NoSort`), the state is the controlled
columns with a non-`NoSort` order mapped to `{ columnKey, order, sorter }`
in column order (a controlled `NoSort` column contributes nothing but still
suppresses the uncontrolled list); if some column is controlled but none
sorts, the state is `[]`; otherwise the uncontrolled list passes through
as-is.
-}
mergedSortStates : List (Column row msg) -> List (SortState row) -> List (SortState row)
mergedSortStates columns uncontrolled =
    let
        controlled =
            List.filter
                (\col -> col.sorter /= Nothing && col.sortOrder /= Nothing)
                columns

        activeStates =
            List.filterMap
                (\col ->
                    case ( col.sortOrder, col.sorter ) of
                        ( Just order, Just sorter ) ->
                            if order /= NoSort then
                                Just
                                    { columnKey = col.key
                                    , order = order
                                    , sorter = sorter
                                    }

                            else
                                Nothing

                        _ ->
                            Nothing
                )
                controlled
    in
    if List.any (\col -> col.sortOrder /= Just NoSort) controlled then
        activeStates

    else if controlled /= [] then
        []

    else
        uncontrolled


{-| `getNextOrderOf` (upstream `utils.ts`) — the click cycle
`false → descend → ascend → false`, so a column's first click sorts
descending.
-}
nextSortOrder : SortOrder -> SortOrder
nextSortOrder order =
    case order of
        NoSort ->
            Descend

        Descend ->
            Ascend

        Ascend ->
            NoSort


{-| `createNextSorter` (upstream `utils.ts`) — the state a click on `col`
produces: nothing when the column has no sorter, a fresh descending state
when there is no current state (or it names another key), else the current
state with its order advanced through the cycle.
-}
createNextSorter : Column row msg -> Maybe (SortState row) -> Maybe (SortState row)
createNextSorter col current =
    case col.sorter of
        Nothing ->
            Nothing

        Just sorter ->
            case current of
                Nothing ->
                    Just
                        { columnKey = col.key
                        , order = Descend
                        , sorter = sorter
                        }

                Just state ->
                    if state.columnKey /= col.key then
                        Just
                            { columnKey = col.key
                            , order = Descend
                            , sorter = sorter
                            }

                    else
                        Just { state | order = nextSortOrder state.order }


{-| `deriveNextSorter` → `getUpdatedSorterState` (upstream
`use-sorter.ts:180` — note the base is the MERGED state, not the caller's
uncontrolled list): a multiple sorter keeps only the base's
multiple-priority states and upserts the new one among them; a single
sorter replaces the whole state; nothing clears it.
-}
deriveNextSorter : List (SortState row) -> Maybe (SortState row) -> List (SortState row)
deriveNextSorter base next =
    case next of
        Nothing ->
            []

        Just state ->
            case getMultiplePriority state.sorter of
                Just _ ->
                    base
                        |> List.filter (\existing -> getMultiplePriority existing.sorter /= Nothing)
                        |> upsertSortState state

                Nothing ->
                    [ state ]


{-| The `some()` walk of `sortedDataRef`'s comparator (upstream
`use-sorter.ts:148-178`, ported exactly): the first active state that has a
compare fn and a truthy order and actually distinguishes the rows wins,
inverted when the order is `Descend` (`getFlagOfOrder`: ascend `1`,
descend `-1`); a state without a fn (or with `NoSort`) never distinguishes,
so ties fall through to the next state, and a full tie is `EQ`.
-}
compareRows : List (SortState row) -> row -> row -> Basics.Order
compareRows activeSorters row1 row2 =
    case activeSorters of
        [] ->
            EQ

        { sorter, order } :: rest ->
            if order /= NoSort then
                case getSortFunction sorter of
                    Just compareFn ->
                        case compareFn row1 row2 of
                            EQ ->
                                compareRows rest row1 row2

                            result ->
                                applyOrderFlag order result

                    Nothing ->
                        compareRows rest row1 row2

            else
                compareRows rest row1 row2


{-| `getFlagOfOrder` (upstream `utils.ts`) — the comparator sign: ascend
keeps the result, descend inverts it (`false` never reaches here — a
`NoSort` state does not distinguish).
-}
applyOrderFlag : SortOrder -> Basics.Order -> Basics.Order
applyOrderFlag order result =
    case order of
        Descend ->
            case result of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT

        _ ->
            result


{-| `sortedDataRef` (upstream `use-sorter.ts`) — the filtered data sorted
by the merged state: no state at all passes the data through untouched;
otherwise the states are ordered by multiple priority descending (missing
priorities count `0`; JS sort is stable, so ties keep merged order) and
the rows fold through `compareRows`.
-}
sortedData : Options row msg -> List row
sortedData opts =
    case mergedSortStates opts.columns opts.sortStates of
        [] ->
            filteredData opts

        merged ->
            List.sortWith
                (compareRows (byPriorityDesc merged))
                (filteredData opts)


byPriorityDesc : List (SortState row) -> List (SortState row)
byPriorityDesc states =
    List.sortBy
        (\state -> negate (Maybe.withDefault 0 (getMultiplePriority state.sorter)))
        states



-- PAGINATION --------------------------------------------------------------------


{-| `filteredDataRef` — the identity for now (the filter seam lands with
the filter batch), kept so the pipeline reads upstream's
treeMate → filter → sort → paginate chain.
-}
filteredData : Options row msg -> List row
filteredData opts =
    opts.data


{-| `mergedPageSizeRef` (upstream `use-table-data.ts`) — the pagination
object's `pageSize`, else `getDefaultPageSize` over its `pageSizes`
(`NUI.Pagination` has no `defaultPageSize` field — see the divergence
notes).
-}
mergedPageSize : Options row msg -> Int
mergedPageSize opts =
    let
        base =
            paginationBase opts
    in
    Maybe.withDefault
        (NUI.Pagination.getDefaultPageSize
            { defaultPageSize = Nothing
            , pageSizes = base.pageSizes
            }
        )
        base.pageSize


{-| `mergedItemCountRef` (upstream `use-table-data.ts`) — remote defers to
the pagination object's `itemCount` (possibly nothing); local counts the
filtered data.
-}
mergedItemCount : Options row msg -> Maybe Int
mergedItemCount opts =
    if opts.remote then
        paginationBase opts |> .itemCount

    else
        Just (List.length (filteredData opts))


{-| `boundedMergedCurrentPageRef` (upstream `use-table-data.ts`) — remote
passes the page through; local clamps it into
`[1, ceil(length / pageSize)]`.
-}
boundedPage : Options row msg -> Int
boundedPage opts =
    if opts.remote then
        paginationBase opts |> .currentPage

    else
        let
            lastPage =
                ceiling (toFloat (List.length (filteredData opts)) / toFloat (mergedPageSize opts))
        in
        max 1 (min lastPage (paginationBase opts |> .currentPage))


{-| The pagination-object base — `NUI.Pagination.defaults` when the caller
passed none (only reachable for the merge helpers; `paginatedData` /
`showPagination` short-circuit on `opts.pagination == Nothing` first, like
upstream's `!props.pagination` guards).
-}
paginationBase : Options row msg -> NUI.Pagination.Options msg
paginationBase opts =
    Maybe.withDefault NUI.Pagination.defaults opts.pagination


{-| `mergedPaginationRef` (upstream `use-table-data.ts:303-331`) — the
caller's pagination object with the derived overrides: the bounded page,
the merged page size, the merged item count, the pageCount blanked
whenever the item count is set (upstream `undefined`), and the table-level
page/page-size handlers replacing the object's own (the single-channel
divergence).
-}
mergedPaginationOpts : Options row msg -> NUI.Pagination.Options msg
mergedPaginationOpts opts =
    let
        base =
            paginationBase opts
    in
    { base
        | currentPage = boundedPage opts
        , pageSize = Just (mergedPageSize opts)
        , itemCount = mergedItemCount opts
        , pageCount =
            if mergedItemCount opts == Nothing then
                base.pageCount

            else
                Nothing
        , onUpdatePage = opts.onUpdatePage
        , onUpdatePageSize = opts.onUpdatePageSize
    }


{-| `paginatedDataRef` (upstream `use-table-data.ts`) — remote hands the
raw data to the caller (the server paginates); no pagination object means
the sorted data as-is; otherwise the sorted data's window from
`(page - 1) * pageSize`, `pageSize` rows deep.
-}
paginatedData : Options row msg -> List row
paginatedData opts =
    if opts.remote then
        opts.data

    else
        case opts.pagination of
            Nothing ->
                sortedData opts

            Just _ ->
                let
                    pageSize =
                        mergedPageSize opts
                in
                List.take pageSize
                    (List.drop ((boundedPage opts - 1) * pageSize) (sortedData opts))


{-| `mergedShowPaginationRef` (upstream `DataTable.tsx:454-466`) — no
pagination object means no node; `paginateSinglePage` (upstream default
`true`) shows it anyway; otherwise read the MERGED pagination: a pageCount
shows iff it exceeds 1 (the merge blanks it whenever itemCount is set),
else `itemCount && pageSize && itemCount > pageSize` (upstream's truthy
short-circuit is subsumed — a 0 item count never exceeds the page size).
-}
showPagination : Options row msg -> Bool
showPagination opts =
    case opts.pagination of
        Nothing ->
            False

        Just _ ->
            if opts.paginateSinglePage then
                True

            else
                let
                    merged =
                        mergedPaginationOpts opts
                in
                case merged.pageCount of
                    Just count ->
                        count > 1

                    Nothing ->
                        case ( merged.itemCount, merged.pageSize ) of
                            ( Just itemCount, Just pageSize ) ->
                                itemCount > pageSize

                            _ ->
                                False



-- HELPERS ----------------------------------------------------------------------


{-| Pair each item with whether it is the last of the list — the `isLast`
/ `isLastCol` flags of upstream's row/col iteration.
-}
lastFlags : List a -> List ( a, Bool )
lastFlags xs =
    List.map2 (\x isLast -> ( x, isLast ))
        xs
        (List.repeat (List.length xs - 1) False ++ [ True ])


maybeClass : Maybe String -> List String
maybeClass maybe =
    case maybe of
        Just c ->
            [ c ]

        Nothing ->
            []


{-| `stylePart k (Just v)` is `Just "k:v"`; `Nothing` entries are dropped by
`List.filterMap`, matching Vue's style normalization (falsy/undefined
values render no declaration).
-}
stylePart : String -> Maybe String -> Maybe String
stylePart key maybeValue =
    Maybe.map (\value -> key ++ ":" ++ value) maybeValue


{-| The set declarations joined Vue-style (`k:v` with `;` separators, no
trailing semicolon), or `Nothing` when there is nothing to declare — an
empty style object renders no `style` attribute.
-}
stylePairs : List ( String, Maybe String ) -> Maybe String
stylePairs pairs =
    let
        parts =
            List.filterMap (\( k, mv ) -> stylePart k mv) pairs
    in
    if parts == [] then
        Nothing

    else
        Just (String.join ";" parts)


rawStyleAttr : Maybe String -> List (Html.Attribute msg)
rawStyleAttr maybeStyle =
    case maybeStyle of
        Just style ->
            [ HA.attribute "style" style ]

        Nothing ->
            []


orElse : Maybe a -> Maybe a -> Maybe a
orElse first second =
    case first of
        Just value ->
            Just value

        Nothing ->
            second


alignName : Align -> String
alignName align =
    case align of
        AlignLeft ->
            "left"

        AlignCenter ->
            "center"

        AlignRight ->
            "right"


pxfy : Int -> String
pxfy n =
    String.fromInt n ++ "px"



-- THEME ------------------------------------------------------------------------


{-| The root's inline `--n-*` set — upstream `cssVarsRef` (`DataTable.tsx`),
byte-for-byte declaration order. The three size-keyed vars resolve through
`createKey('fontSize'|'thPadding'|'tdPadding', mergedSize)`; everything
else reads the theme module directly (the composite colours are baked
literals there). The filter-menu-only `--n-action-*` vars are not on the
root upstream either.
-}
cssVars : Theme -> Size -> List ( String, String )
cssVars theme size =
    let
        v =
            DataTableTheme.vars theme
    in
    [ ( "--n-font-size", keyed .fontSizeSmall .fontSizeMedium .fontSizeLarge v size )
    , ( "--n-th-padding", keyed .thPaddingSmall .thPaddingMedium .thPaddingLarge v size )
    , ( "--n-td-padding", keyed .tdPaddingSmall .tdPaddingMedium .tdPaddingLarge v size )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-border-color-modal", v.borderColorModal )
    , ( "--n-border-color-popover", v.borderColorPopover )
    , ( "--n-th-color", v.thColor )
    , ( "--n-th-color-hover", v.thColorHover )
    , ( "--n-th-color-modal", v.thColorModal )
    , ( "--n-th-color-hover-modal", v.thColorHoverModal )
    , ( "--n-th-color-popover", v.thColorPopover )
    , ( "--n-th-color-hover-popover", v.thColorHoverPopover )
    , ( "--n-td-color", v.tdColor )
    , ( "--n-td-color-hover", v.tdColorHover )
    , ( "--n-td-color-modal", v.tdColorModal )
    , ( "--n-td-color-hover-modal", v.tdColorHoverModal )
    , ( "--n-td-color-popover", v.tdColorPopover )
    , ( "--n-td-color-hover-popover", v.tdColorHoverPopover )
    , ( "--n-th-text-color", v.thTextColor )
    , ( "--n-td-text-color", v.tdTextColor )
    , ( "--n-th-font-weight", v.thFontWeight )
    , ( "--n-th-button-color-hover", v.thButtonColorHover )
    , ( "--n-th-icon-color", v.thIconColor )
    , ( "--n-th-icon-color-active", v.thIconColorActive )
    , ( "--n-filter-size", v.filterSize )
    , ( "--n-pagination-margin", v.paginationMargin )
    , ( "--n-empty-padding", v.emptyPadding )
    , ( "--n-box-shadow-before", v.boxShadowBefore )
    , ( "--n-box-shadow-after", v.boxShadowAfter )
    , ( "--n-sorter-size", v.sorterSize )
    , ( "--n-resizable-container-size", v.resizableContainerSize )
    , ( "--n-resizable-size", v.resizableSize )
    , ( "--n-loading-size", v.loadingSize )
    , ( "--n-loading-color", v.loadingColor )
    , ( "--n-opacity-loading", v.opacityLoading )
    , ( "--n-td-color-striped", v.tdColorStriped )
    , ( "--n-td-color-striped-modal", v.tdColorStripedModal )
    , ( "--n-td-color-striped-popover", v.tdColorStripedPopover )
    , ( "--n-td-color-sorting", v.tdColorSorting )
    , ( "--n-td-color-sorting-modal", v.tdColorSortingModal )
    , ( "--n-td-color-sorting-popover", v.tdColorSortingPopover )
    , ( "--n-th-color-sorting", v.thColorSorting )
    , ( "--n-th-color-sorting-modal", v.thColorSortingModal )
    , ( "--n-th-color-sorting-popover", v.thColorSortingPopover )
    ]


keyed :
    (DataTableTheme.Vars -> String)
    -> (DataTableTheme.Vars -> String)
    -> (DataTableTheme.Vars -> String)
    -> DataTableTheme.Vars
    -> Size
    -> String
keyed small medium large v size =
    case size of
        Small ->
            small v

        Medium ->
            medium v

        Large ->
            large v
