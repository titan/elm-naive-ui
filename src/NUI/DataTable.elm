module NUI.DataTable exposing
    ( Align(..)
    , Column
    , Options
    , Size(..)
    , columnDefaults
    , cssVars
    , defaults
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

DOM (batch-1 core — one table, the header lives inside the body table):

    div.n-data-table [--rtl] [--bordered] [--bottom-bordered] [--single-line]
                     [--single-column] [--empty]
      style = the 47 `--n-*` vars
      └─ div.n-data-table-wrapper
         └─ div.n-data-table-base-table
            └─ div.n-data-table-base-table-body (the `n-scrollbar` root)
               └─ div.n-scrollbar-container > div.n-scrollbar-content
                  ├─ table.n-data-table-table [inline table-layout:auto]
                  │  ├─ colgroup > col (style width/min-width/max-width — always)
                  │  ├─ thead.n-data-table-thead[data-n-id]
                  │  │  └─ tr.n-data-table-tr > th[data-col-key]
                  │  │     └─ div.n-data-table-th__title-wrapper
                  │  │        └─ div.n-data-table-th__title     (iff showHeader)
                  │  └─ tbody.n-data-table-tbody[data-n-id]     (iff data non-empty)
                  │     └─ tr.n-data-table-tr [--striped] > td[data-col-key]
                  └─ div.n-data-table-empty > NEmpty            (iff data empty)

Cell content is `Element msg`, embedded through `Element.layoutWith`
(`display: contents`, the `NUI.Table` precedent); the scroll area is
`NUI.Scrollbar.view` and the empty state `NUI.Empty.view`.

Divergences (documented):

  - **Batch-1 scope.** Sort/filter/selection/expand/pagination/loading/
    fixed columns/scrollX/group headers/summary rows/virtual scroll/
    resizable columns are upcoming batches. `maxHeight`/`flexHeight`
    (which split the header into its own table) are not modelled, so the
    header always renders inside the single body table — upstream's
    `headerInBody` path.
  - **`data-n-id` is the constant `"1"`.** Upstream stamps a random seemly
    component id on thead/tbody; it only keys the fixed-column shadow
    cssr that a later batch will port.
  - **`table-layout` is pinned to `auto`** (upstream's default `tableLayout`
    prop; upstream switches to `fixed` for virtual scroll / flexHeight /
    maxHeight / ellipsis columns — all batch-2+ surfaces).
  - **`title` is a plain `String`** until the header-render batch (upstream
    also accepts a render function returning VNodes).
  - **`rowAttributes` land verbatim after the row's `class` attribute.**
    Upstream merges `rowProps(row, index).class` into the row's class list;
    Elm attributes are opaque, and a caller `Html.Attributes.class` would
    replace the whole `className` (Elm properties are last-wins), so prefer
    `rowClassName` for classes.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Empty
import NUI.Internal as I
import NUI.Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.DataTable as DataTableTheme


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


{-| One column — upstream's basic `TableBaseColumn` (`type: undefined`):
`key` sources the `data-col-key` attribute, `view` renders the cell body
(upstream `render`, falling back to `row[key]`). The width fields feed the
`<col>` / `<th>` / `<td>` styles exactly like upstream's
`createCustomWidthStyle` (a set `width` also backs an unset `minWidth` on
the `<col>` only). `className` lands on both the `th` and every `td` of the
column, after the base class.
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
    }


{-| The column placeholders — `key` / `title` / `view` are the caller's to
set (the keyless rest is `Nothing`).
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
    }


{-| The data-table options (upstream `dataTableProps`, batch-1 surface):
`bordered`, `bottomBordered` and `singleLine` default `True` (upstream's
booleans). `bottomBordered` is emitted only when `bordered` is off —
upstream `mergedBottomBordered` (the wrapper border wins when bordered).
`--single-line` keeps upstream's inverted CSS semantics: `True` means _no_
vertical cell borders (`cNotM('single-line')` rules add them).
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
    }



-- VIEW -------------------------------------------------------------------------


{-| The data table — the `n-data-table` root carrying the modifier classes
(`DataTable.tsx` render's class array, minus the batch-2+ `--loading` /
`--flex-height` and the inline-theme `themeClass`) and the 47-var inline
set, over the wrapper → base-table → scrollbar → single-table chain.
-}
view : Theme -> Options row msg -> Element msg
view theme opts =
    let
        empty =
            opts.data == []

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
        ]


{-| The root's class list — `n-data-table` plus the modifiers in upstream's
class-array order, each only when truthy. Note `--empty` keys off the data
(upstream `mergedEmpty`: paginated data length 0) and `--bottom-bordered`
is forced off while `--bordered` is on.
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


{-| The scroll area — upstream's body `NScrollbar` with the
`n-data-table-base-table-body` fallthrough class on its root and
`contentStyle = minWidth: 100%` (upstream `formatLength(scrollX) || '100%'`;
no `scrollX` in batch 1). Children: the table, then — upstream
`{this.empty ? createEmptyNode() : null}` right after `</table>` — the
empty state, a sibling inside the scrollbar content.
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
            :: (if opts.data == [] then
                    [ Element.el [ I.classes [ "n-data-table-empty" ] ]
                        (NUI.Empty.view theme NUI.Empty.defaults [])
                    ]

                else
                    []
               )
        )


{-| The body's single `<table>` (no maxHeight/flexHeight in batch 1, so
there is no separate header table): class + the inline `table-layout`,
then colgroup, thead (iff `showHeader`), tbody (iff data non-empty) —
`Body.tsx`'s non-virtual render. No `width`/`minWidth` on this table
(the scrollbar content's `min-width` carries it).
-}
tableNode : Options row msg -> Element msg
tableNode opts =
    Element.html
        (Html.table
            [ HA.class "n-data-table-table"
            , HA.attribute "style" "table-layout:auto"
            ]
            (colgroupNode opts.columns
                ++ theadNode opts
                ++ tbodyNode opts
            )
        )


{-| The colgroup — always rendered, even with no data. One `<col>` per
column whose style is built only from the set width fields, upstream
`createCustomWidthStyle`: `width`, then `min-width` (falling back to
`width`), then `max-width`. All absent → no style attribute (Vue drops the
empty object). The vnode `key` is not a DOM attribute.
-}
colgroupNode : List (Column row msg) -> List (Html.Html msg)
colgroupNode columns =
    [ Html.colgroup [] (List.map colNode columns) ]


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
its base class, one `th` per column.
-}
theadNode : Options row msg -> List (Html.Html msg)
theadNode opts =
    if opts.showHeader then
        [ Html.thead
            [ HA.class "n-data-table-thead"
            , HA.attribute "data-n-id" "1"
            ]
            [ Html.tr [ HA.class "n-data-table-tr" ]
                (List.map thNode (lastFlags opts.columns))
            ]
        ]

    else
        []


{-| One header cell — `Header.tsx`'s th for a basic column: base class,
then `--last` (last column), then `column.className`; the always-present
`data-col-key`; the style built only from the set fields (`width`, then
`text-align` from `titleAlign || align`; upstream's fixed offsets and the
body-path `height` are all `undefined` here). No colspan/rowspan in batch 1.
-}
thNode : ( Column row msg, Bool ) -> Html.Html msg
thNode ( col, isLast ) =
    Html.th
        ([ HA.class
            (String.join " "
                ([ "n-data-table-th" ]
                    ++ I.classIf isLast "n-data-table-th--last"
                    ++ maybeClass col.className
                )
            )
         , HA.attribute "data-col-key" col.key
         ]
            ++ thStyleAttr col
        )
        [ Html.div [ HA.class "n-data-table-th__title-wrapper" ]
            [ Html.div [ HA.class "n-data-table-th__title" ]
                [ Html.text col.title ]
            ]
        ]


thStyleAttr : Column row msg -> List (Html.Attribute msg)
thStyleAttr col =
    rawStyleAttr
        (stylePairs
            [ ( "width", Maybe.map pxfy col.width )
            , ( "text-align", Maybe.map alignName (orElse col.titleAlign col.align) )
            ]
        )


{-| The `<tbody>` — omitted entirely while the data is empty (upstream
`{!this.empty ? <tbody>… : null}`); attribute order matches upstream
(`data-n-id` first here, `class` first on the thead).
-}
tbodyNode : Options row msg -> List (Html.Html msg)
tbodyNode opts =
    if opts.data == [] then
        []

    else
        [ Html.tbody
            [ HA.attribute "data-n-id" "1"
            , HA.class "n-data-table-tbody"
            ]
            (List.indexedMap (trNode opts) opts.data)
        ]


{-| One body row — `Body.tsx`'s `renderRow` for a normal row: base class,
then `--striped` (iff `striped && index % 2 === 1`), then the
`rowClassName(row, index)` result when non-empty, then the caller's
`rowAttributes` verbatim (see the `rowAttributes` divergence note).
-}
trNode : Options row msg -> Int -> row -> Html.Html msg
trNode opts index row =
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
        (List.map (tdNode opts index row) (lastFlags opts.columns))


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
→ `column.className` → `--{align}-align` (iff align set — redundant with
the inline `text-align`, upstream emits both) → `--last-col` → `--last-row`;
the always-present `data-col-key`; the style built only from the set fields
(`text-align`, then `width`); the cell body is the caller's element embedded
through `layoutWith`. No colspan/rowspan in batch 1.
-}
tdNode : Options row msg -> Int -> row -> ( Column row msg, Bool ) -> Html.Html msg
tdNode opts rowIndex row ( col, isLastCol ) =
    let
        isLastRow =
            rowIndex + 1 == List.length opts.data
    in
    Html.td
        ([ HA.class
            (String.join " "
                ([ "n-data-table-td" ]
                    ++ maybeClass col.className
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
         , HA.attribute "data-col-key" col.key
         ]
            ++ tdStyleAttr col
        )
        [ embedChild (col.view row) ]


tdStyleAttr : Column row msg -> List (Html.Attribute msg)
tdStyleAttr col =
    rawStyleAttr
        (stylePairs
            [ ( "text-align", Maybe.map alignName col.align )
            , ( "width", Maybe.map pxfy col.width )
            ]
        )


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
