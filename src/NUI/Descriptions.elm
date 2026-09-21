module NUI.Descriptions exposing
    ( Align(..)
    , Cell
    , CellShape(..)
    , Item
    , Options
    , Placement(..)
    , Size(..)
    , cssVars
    , defaults
    , itemDefaults
    , layout
    , resolvedColumns
    , view
    )

{-| Naive UI's `Descriptions` (`n-descriptions` + `n-descriptions-item`), rebuilt on elm-ui.

    import NUI.Descriptions exposing (defaults, itemDefaults)

    NUI.Descriptions.view theme NUI.Descriptions.defaults
        [ { itemDefaults | label = Just (Element.text "Breakfast"), content = [ Element.text "Apple" ] }
        , { itemDefaults | label = Just (Element.text "Lunch"), content = [ Element.text "Apple" ] }
        ]

The visual result is Naive UI's own: the root carries the `.n-descriptions` BEM classes and
Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS.

**Engine / view split.** `layout` is a pure packer: given the per-item `span`s and the
`column` count it produces the table's rows, each row a list of `Cell`s (a shape, a colspan,
and the item index), reproducing `Descriptions.tsx` render()'s `reduce` exactly — including
its cols spans, which are what make a `span` and the "last cell absorbs the row" rule render.
The caller owns the items; nothing is measured or looked up.

**Divergences from upstream (documented):**

  - Pure data: no provide/inject, no item registry, no size cascade into children. `Item`s
    are passed as records (the `NUI.Grid` precedent), because Elm cannot read props off an
    arbitrary `Element`.
  - An item's `labelClass` / `contentClass` are **inert upstream** (render() reads only the
    parent's) → omitted from `Item`; only the item's `labelStyle` / `contentStyle` override
    the parent's.
  - `title` is `Maybe (Element msg)` (upstream's `title` String ∪ `header` slot); the header
    renders whenever it is `Just _`.
  - `labelStyle` / `contentStyle` are raw CSS fragments (upstream also accepts a style object).
  - The extracted stylesheet targets `n-descriptions-table-row__label`, but upstream's DOM
    emits `n-descriptions-table-content__label` — a selector mismatch reproduced faithfully
    (the label span simply carries no rule, exactly as upstream).
  - The root is an elm-ui column whose children fill the width (`NUI.Card` precedent); Naive
    UI sets no `display` on `.n-descriptions`.

-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Descriptions as DescriptionsTheme


{-| Naive UI's `labelPlacement`.
-}
type Placement
    = Top
    | Left


{-| Naive UI's `labelAlign`.
-}
type Align
    = AlignLeft
    | AlignCenter
    | AlignRight


{-| Naive UI's `DescriptionsSize` (`small | medium | large`).
-}
type Size
    = Small
    | Medium
    | Large


{-| One `n-descriptions-item`. `span` defaults to 1; `labelStyle` / `contentStyle` override
the parent's when set.
-}
type alias Item msg =
    { label : Maybe (Element msg)
    , span : Int
    , labelStyle : Maybe String
    , contentStyle : Maybe String
    , content : List (Element msg)
    }


{-| Naive UI's `n-descriptions` props.
-}
type alias Options msg =
    { title : Maybe (Element msg)
    , column : Int
    , columns : Maybe Int
    , labelPlacement : Placement
    , labelAlign : Align
    , separator : String
    , size : Size
    , bordered : Bool
    , labelClass : Maybe String
    , labelStyle : Maybe String
    , contentClass : Maybe String
    , contentStyle : Maybe String
    }


defaults : Options msg
defaults =
    { title = Nothing
    , column = 3
    , columns = Nothing
    , labelPlacement = Top
    , labelAlign = AlignLeft
    , separator = ":"
    , size = Medium
    , bordered = False
    , labelClass = Nothing
    , labelStyle = Nothing
    , contentClass = Nothing
    , contentStyle = Nothing
    }


itemDefaults : Item msg
itemDefaults =
    { label = Nothing
    , span = 1
    , labelStyle = Nothing
    , contentStyle = Nothing
    , content = []
    }


{-| The cell kind a layout row holds. `HeaderCell` renders a `<th>` (the label), `ContentCell`
a `<td>` (the content), and `CombinedCell` the non-bordered left-placement `<td>` that holds
both — the `__label` span, the separator and the `__content` span.
-}
type CellShape
    = HeaderCell
    | ContentCell
    | CombinedCell


type alias Cell =
    { shape : CellShape
    , colspan : Int
    , index : Int
    }


{-| The effective column count (`columns` wins over `column`, upstream `useCompitable`).
-}
resolvedColumns : Options msg -> Int
resolvedColumns opts =
    Maybe.withDefault opts.column opts.columns


{-| Pack `span`s into the table's rows, reproducing `Descriptions.tsx` render()'s `reduce`.
For item `i` with span `s` and accumulated span `m` before it:

  - **Top**: a `HeaderCell` and a `ContentCell`, each `colspan = isLast ? (column - m) * 2 : s * 2`.
  - **Left + bordered**: a `HeaderCell colspan = 1`, then
    `ContentCell colspan = isLast ? (column - m) * 2 + 1 : s * 2 - 1`.
  - **Left + non-bordered**: one `CombinedCell colspan = isLast ? (column - m) * 2 : s * 2`.

A row is flushed once `m + s >= column` (or on the last item); `m` resets to 0. Each flush
emits the label row, then — for `Top` — the content row as a separate `<tr>`.

-}
layout :
    { column : Int, labelPlacement : Placement, bordered : Bool }
    -> List Int
    -> List (List Cell)
layout cfg spans =
    let
        n =
            List.length spans

        step ( i, s ) state =
            let
                m =
                    state.span

                isLast =
                    i == n - 1

                acc =
                    m + s

                rowColspan =
                    if isLast then
                        (cfg.column - m) * 2

                    else
                        s * 2

                labelCells =
                    case cfg.labelPlacement of
                        Top ->
                            [ { shape = HeaderCell, colspan = rowColspan, index = i } ]

                        Left ->
                            if cfg.bordered then
                                [ { shape = HeaderCell, colspan = 1, index = i }
                                , { shape = ContentCell
                                  , colspan =
                                        if isLast then
                                            (cfg.column - m) * 2 + 1

                                        else
                                            s * 2 - 1
                                  , index = i
                                  }
                                ]

                            else
                                [ { shape = CombinedCell, colspan = rowColspan, index = i } ]

                contentCells =
                    case cfg.labelPlacement of
                        Top ->
                            [ { shape = ContentCell, colspan = rowColspan, index = i } ]

                        Left ->
                            []

                row =
                    state.row ++ labelCells

                contentRow =
                    state.contentRow ++ contentCells

                flush =
                    acc >= cfg.column || isLast
            in
            if flush then
                { span = 0
                , row = []
                , contentRow = []
                , rows =
                    state.rows
                        ++ (if List.isEmpty row then
                                []

                            else
                                [ row ]
                           )
                        ++ (if cfg.labelPlacement /= Left && not (List.isEmpty contentRow) then
                                [ contentRow ]

                            else
                                []
                           )
                }

            else
                { state | span = acc, row = row, contentRow = contentRow }
    in
    (List.foldl
        step
        { span = 0, row = [], contentRow = [], rows = [] }
        (List.indexedMap Tuple.pair spans)
    ).rows


{-| The root's `--n-*` custom properties, per `Descriptions.tsx` `cssVarsRef`.
-}
cssVars : Theme -> Options msg -> List ( String, String )
cssVars theme opts =
    let
        v =
            DescriptionsTheme.vars theme
    in
    [ ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-th-padding"
      , if opts.bordered then
            thPaddingBordered opts.size v

        else
            thPadding opts.size v
      )
    , ( "--n-td-padding"
      , if opts.bordered then
            tdPaddingBordered opts.size v

        else
            tdPadding opts.size v
      )
    , ( "--n-font-size", fontSize opts.size v )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-th-font-weight", v.thFontWeight )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-th-text-color", v.thTextColor )
    , ( "--n-td-text-color", v.tdTextColor )
    , ( "--n-th-color", v.thColor )
    , ( "--n-th-color-modal", v.thColorModal )
    , ( "--n-th-color-popover", v.thColorPopover )
    , ( "--n-td-color", v.tdColor )
    , ( "--n-td-color-modal", v.tdColorModal )
    , ( "--n-td-color-popover", v.tdColorPopover )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-border-color-modal", v.borderColorModal )
    , ( "--n-border-color-popover", v.borderColorPopover )
    ]


view : Theme -> Options msg -> List (Item msg) -> Element msg
view theme opts items =
    let
        column =
            resolvedColumns opts

        rows =
            layout
                { column = column, labelPlacement = opts.labelPlacement, bordered = opts.bordered }
                (List.map .span items)

        headerEl =
            Maybe.map
                (\t ->
                    Element.el
                        [ I.classes [ "n-descriptions-header" ]
                        , Element.width Element.fill
                        ]
                        t
                )
                opts.title

        wrapperEl =
            Element.el
                [ I.classes [ "n-descriptions-table-wrapper" ]
                , Element.width Element.fill
                ]
                (Element.html (table column opts items rows))
    in
    Element.column
        (I.classes (rootClasses opts) :: I.cssVars (cssVars theme opts) :: [])
        (List.filterMap identity [ headerEl, Just wrapperEl ])


rootClasses : Options msg -> List String
rootClasses opts =
    [ "n-descriptions"
    , "n-descriptions--" ++ placementClass opts.labelPlacement ++ "-label-placement"
    , "n-descriptions--" ++ alignClass opts.labelAlign ++ "-label-align"
    , "n-descriptions--" ++ sizeClass opts.size ++ "-size"
    ]
        ++ I.classIf opts.bordered "n-descriptions--bordered"


placementClass : Placement -> String
placementClass placement =
    case placement of
        Top ->
            "top"

        Left ->
            "left"


alignClass : Align -> String
alignClass align =
    case align of
        AlignLeft ->
            "left"

        AlignCenter ->
            "center"

        AlignRight ->
            "right"


sizeClass : Size -> String
sizeClass size =
    case size of
        Small ->
            "small"

        Medium ->
            "medium"

        Large ->
            "large"



-- TABLE ------------------------------------------------------------------------


table : Int -> Options msg -> List (Item msg) -> List (List Cell) -> Html msg
table column opts items rows =
    Html.table
        [ HA.class "n-descriptions-table" ]
        [ Html.tbody []
            (spacerRow column opts.labelPlacement
                ++ List.map (dataRow opts items) rows
            )
        ]


{-| Top placement emits a leading `visibility:collapse` row of `2 * column` empty `<td>`, which
forces the table to the full column count so the cell colspans lay out (upstream render()).
-}
spacerRow : Int -> Placement -> List (Html msg)
spacerRow column placement =
    case placement of
        Left ->
            []

        Top ->
            [ Html.tr
                [ HA.class "n-descriptions-table-row"
                , HA.attribute "style" "visibility:collapse"
                ]
                (List.repeat (max 0 (column * 2)) (Html.td [] []))
            ]


dataRow : Options msg -> List (Item msg) -> List Cell -> Html msg
dataRow opts items cells =
    Html.tr
        [ HA.class "n-descriptions-table-row" ]
        (List.map (cellNode opts items) cells)


cellNode : Options msg -> List (Item msg) -> Cell -> Html msg
cellNode opts items cell =
    let
        item =
            List.drop cell.index items |> List.head

        label =
            item |> Maybe.andThen .label

        content =
            Maybe.map .content item |> Maybe.withDefault []

        labelStyle =
            styleOf .labelStyle opts.labelStyle item

        contentStyle =
            styleOf .contentStyle opts.contentStyle item

        colspanAttr =
            HA.attribute "colspan" (String.fromInt cell.colspan)
    in
    case cell.shape of
        HeaderCell ->
            Html.th
                (classesOf "n-descriptions-table-header" opts.labelClass
                    :: colspanAttr
                    :: styleList labelStyle
                )
                (labelHtml label)

        ContentCell ->
            Html.td
                (classesOf "n-descriptions-table-content" opts.contentClass
                    :: colspanAttr
                    :: styleList contentStyle
                )
                (List.map embedChild content)

        CombinedCell ->
            Html.td
                [ HA.class "n-descriptions-table-content", colspanAttr ]
                (Html.span
                    (classesOf "n-descriptions-table-content__label" opts.labelClass
                        :: styleList labelStyle
                    )
                    (labelHtml label)
                    :: separatorHtml opts.separator
                    ++ [ Html.span
                            (classesOf "n-descriptions-table-content__content" opts.contentClass
                                :: styleList contentStyle
                            )
                            (List.map embedChild content)
                       ]
                )


{-| The item's style when set, otherwise the parent's (upstream `props.x || this.x`).
-}
styleOf : (a -> Maybe String) -> Maybe String -> Maybe a -> Maybe String
styleOf getter parentStyle maybeItem =
    case maybeItem |> Maybe.andThen getter of
        Just s ->
            Just s

        Nothing ->
            parentStyle


separatorHtml : String -> List (Html msg)
separatorHtml separator =
    if separator == "" then
        []

    else
        [ Html.span [ HA.class "n-descriptions-separator" ] [ Html.text separator ] ]


labelHtml : Maybe (Element msg) -> List (Html msg)
labelHtml maybeLabel =
    case maybeLabel of
        Just el ->
            [ embedChild el ]

        Nothing ->
            []


{-| There is no public `Element` → `Html`, so a caller's element is embedded through
`Element.layoutWith` (the `NUI.Form` precedent). The wrapper carries `display: contents` (so
the child participates directly in the cell) plus `font`/`color: inherit` (best-effort
neutralisation of elm-ui's class-based root font).

`noStaticStyleSheet`: without it every embed would re-emit elm-ui's static stylesheet as a
`<style>` node _after_ the bridge (which only restores `flex-basis`/`line-height`/`white-space`
at equal specificity), re-clobbering `flex-basis: 0%` across the page. The app's own
`Element.layout` supplies the sheet once.

-}
embedChild : Element msg -> Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child


{-| One `class` attribute; `extra` is merged in (never a second `class`, which would clobber).
-}
classesOf : String -> Maybe String -> Html.Attribute msg
classesOf base extra =
    case extra of
        Just c ->
            if c == "" then
                HA.class base

            else
                HA.class (base ++ " " ++ c)

        Nothing ->
            HA.class base


styleList : Maybe String -> List (Html.Attribute msg)
styleList maybeStyle =
    case maybeStyle of
        Just s ->
            [ HA.attribute "style" s ]

        Nothing ->
            []



-- THEME SELECTION --------------------------------------------------------------


fontSize : Size -> DescriptionsTheme.Vars -> String
fontSize size v =
    case size of
        Small ->
            v.fontSizeSmall

        Medium ->
            v.fontSizeMedium

        Large ->
            v.fontSizeLarge


thPadding : Size -> DescriptionsTheme.Vars -> String
thPadding size v =
    case size of
        Small ->
            v.thPaddingSmall

        Medium ->
            v.thPaddingMedium

        Large ->
            v.thPaddingLarge


thPaddingBordered : Size -> DescriptionsTheme.Vars -> String
thPaddingBordered size v =
    case size of
        Small ->
            v.thPaddingBorderedSmall

        Medium ->
            v.thPaddingBorderedMedium

        Large ->
            v.thPaddingBorderedLarge


tdPadding : Size -> DescriptionsTheme.Vars -> String
tdPadding size v =
    case size of
        Small ->
            v.tdPaddingSmall

        Medium ->
            v.tdPaddingMedium

        Large ->
            v.tdPaddingLarge


tdPaddingBordered : Size -> DescriptionsTheme.Vars -> String
tdPaddingBordered size v =
    case size of
        Small ->
            v.tdPaddingBorderedSmall

        Medium ->
            v.tdPaddingBorderedMedium

        Large ->
            v.tdPaddingBorderedLarge
