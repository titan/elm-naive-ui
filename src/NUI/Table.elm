module NUI.Table exposing (Cell, Options, Row, Size(..), Table, cellDefaults, cssVars, defaults, rowDefaults, view)

{-| Naive UI's `Table` (`n-table`), the static table — real `<table>` DOM,
rebuilt on elm-ui.

    import NUI.Table exposing (cellDefaults, defaults, rowDefaults)

    NUI.Table.view theme
        NUI.Table.defaults
        { head = [ { rowDefaults | cells = [ { cellDefaults | content = [ Element.text "Name" ] } ] } ]
        , body = [ { rowDefaults | cells = [ { cellDefaults | content = [ Element.text "Naive" ] } ] } ]
        }

(Record updates bind `defaults` to a local first — see `NUI.Button`.)

Upstream is five components: `Table` renders the `<table class="n-table">`
root (modifier classes + the 21 `--n-*` vars) and `Th` / `Td` / `Tr` /
`Thead` / `Tbody` are BARE tag wrappers the caller composes by hand. The
port keeps the root faithful and types the tag tree: `Table.head` rows
render as `<thead><tr><th>…` (omitted entirely when empty), `Table.body`
as `<tbody><tr><td>…`. Cell content is `Element msg`, embedded through
`Element.layoutWith` (`display: contents`, the `NUI.Descriptions`
precedent — there is no public `Element` → `Html`).

DOM (`Table.tsx` render + the five wrappers):

    table.n-table [--rtl] [--bottom-bordered] [--bordered] [--single-line]
                  [--single-column] [--striped]
      style = 21 vars
      ├─ thead > tr > th{colspan?, rowspan?}          — iff head non-empty
      └─ tbody > tr > td{colspan?, rowspan?}          — iff body non-empty

Divergences from upstream (documented): the root sits inside a bare
elm-ui wrapper `div` (the `NUI.Descriptions` root shape — caller
`attributes` need an elm-ui element to land on; Naive UI's own root IS
the `table` tag, and every `.n-table` rule resolves identically through
the wrapper), and `thead` / `tbody` take no caller attributes (upstream
reaches them only through Vue fallthrough on the hand-composed wrappers;
row and cell attributes are modelled, section attributes are not).

Not ported: nothing — the component is fully static (no runtime state, no
slots beyond the rows themselves). `--n-merged-border-color` is derived on
the ROOT RULE in the stylesheet (not an inline var), and the modal /
popover color variants ride the `insideModal` / `insidePopover` container
selectors automatically.

@docs Cell, Options, Row, Size, Table, cellDefaults, cssVars, defaults, rowDefaults, view

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme as Theme
import NUI.Theme.Table as TableTheme


{-| Upstream `TableSize` — `'small' | 'medium' | 'large'`; keys the
font-size and the th / td padding vars (`mergedSizeRef` defaults medium).
-}
type Size
    = Small
    | Medium
    | Large


{-| The table options (upstream `tableProps`): `bordered`, `bottomBordered`
and `singleLine` default `True` (upstream's booleans), the rest `False` /
`Medium`.
-}
type alias Options msg =
    { size : Size
    , bordered : Bool
    , bottomBordered : Bool
    , singleLine : Bool
    , singleColumn : Bool
    , striped : Bool
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| Medium bordered single-line table — upstream's three default-`True`
booleans on, no stripes, no rtl.
-}
defaults : Options msg
defaults =
    { size = Medium
    , bordered = True
    , bottomBordered = True
    , singleLine = True
    , singleColumn = False
    , striped = False
    , rtl = False
    , attributes = []
    }


{-| One header or body cell — upstream's `<th>` / `<td>` with their native
span attributes (`Nothing` omits the attribute, as upstream's absent
prop); `attributes` land on the tag itself (raw `Html` attributes — the
tag is not an elm-ui element).
-}
type alias Cell msg =
    { content : List (Element msg)
    , colspan : Maybe Int
    , rowspan : Maybe Int
    , attributes : List (Html.Attribute msg)
    }


{-| An empty cell — no content, no span attributes.
-}
cellDefaults : Cell msg
cellDefaults =
    { content = []
    , colspan = Nothing
    , rowspan = Nothing
    , attributes = []
    }


{-| One row — upstream's bare `<tr>` (cells plus whatever attributes the
caller put on the tag).
-}
type alias Row msg =
    { cells : List (Cell msg)
    , attributes : List (Html.Attribute msg)
    }


{-| An empty row — no cells, no attributes.
-}
rowDefaults : Row msg
rowDefaults =
    { cells = []
    , attributes = []
    }


{-| The table content — `head` renders as `<thead>` rows (of `<th>` cells)
and is omitted entirely when empty, `body` as `<tbody>` rows (of `<td>`
cells), likewise.
-}
type alias Table msg =
    { head : List (Row msg)
    , body : List (Row msg)
    }



-- VIEW -------------------------------------------------------------------------


{-| The static table — the `<table class="n-table">` root with upstream's
modifier classes (`Table.tsx` render: rtl, bottom-bordered, bordered,
single-line, single-column, striped — the three default-`True` modifiers
present unless turned off) and the 21-var inline set, over the typed
`thead` / `tbody` tree, inside the bare elm-ui wrapper that carries the
caller `attributes` (the `NUI.Descriptions` root shape).
-}
view : Theme.Theme -> Options msg -> Table msg -> Element msg
view theme opts table =
    Element.el
        opts.attributes
        (Element.html
            (Html.table
                [ HA.class (String.join " " (rootClasses opts))
                , HA.attribute "style" (I.renderVars (cssVars theme opts))
                ]
                (headNodes table.head ++ bodyNodes table.body)
            )
        )


{-| The root's class list — `n-table` plus the six modifiers in upstream's
declaration order (`Table.tsx` render's object literal), each only when
truthy (the three default-`True` booleans included).
-}
rootClasses : Options msg -> List String
rootClasses opts =
    [ "n-table" ]
        ++ I.classIf opts.rtl "n-table--rtl"
        ++ I.classIf opts.bottomBordered "n-table--bottom-bordered"
        ++ I.classIf opts.bordered "n-table--bordered"
        ++ I.classIf opts.singleLine "n-table--single-line"
        ++ I.classIf opts.singleColumn "n-table--single-column"
        ++ I.classIf opts.striped "n-table--striped"


{-| The root's inline `--n-*` set — upstream `cssVarsRef` (`Table.tsx`),
declaration order: the three size-keyed vars resolve through
`createKey('fontSize'|'tdPadding'|'thPadding', mergedSize)`.
-}
cssVars : Theme.Theme -> Options msg -> List ( String, String )
cssVars theme opts =
    let
        v =
            TableTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-td-color", v.tdColor )
    , ( "--n-td-color-modal", v.tdColorModal )
    , ( "--n-td-color-popover", v.tdColorPopover )
    , ( "--n-td-text-color", v.tdTextColor )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-border-color-modal", v.borderColorModal )
    , ( "--n-border-color-popover", v.borderColorPopover )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-font-size", keyed .fontSizeSmall .fontSizeMedium .fontSizeLarge v opts.size )
    , ( "--n-th-color", v.thColor )
    , ( "--n-th-color-modal", v.thColorModal )
    , ( "--n-th-color-popover", v.thColorPopover )
    , ( "--n-th-font-weight", v.thFontWeight )
    , ( "--n-th-text-color", v.thTextColor )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-td-padding", keyed .tdPaddingSmall .tdPaddingMedium .tdPaddingLarge v opts.size )
    , ( "--n-th-padding", keyed .thPaddingSmall .thPaddingMedium .thPaddingLarge v opts.size )
    , ( "--n-td-color-striped", v.tdColorStriped )
    , ( "--n-td-color-striped-modal", v.tdColorStripedModal )
    , ( "--n-td-color-striped-popover", v.tdColorStripedPopover )
    ]


keyed :
    (TableTheme.Vars -> String)
    -> (TableTheme.Vars -> String)
    -> (TableTheme.Vars -> String)
    -> TableTheme.Vars
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



-- TAG TREE ----------------------------------------------------------------------


headNodes : List (Row msg) -> List (Html.Html msg)
headNodes rows =
    if rows == [] then
        []

    else
        [ Html.thead [] (List.map (rowNode "th") rows) ]


bodyNodes : List (Row msg) -> List (Html.Html msg)
bodyNodes rows =
    if rows == [] then
        []

    else
        [ Html.tbody [] (List.map (rowNode "td") rows) ]


rowNode : String -> Row msg -> Html.Html msg
rowNode tag row =
    Html.tr row.attributes (List.map (cellNode tag) row.cells)


{-| One cell — the `th` / `td` tag (head rows pass `"th"`, body rows
`"td"`), carrying the span attributes when set plus the caller's own.
-}
cellNode : String -> Cell msg -> Html.Html msg
cellNode tag cell =
    Html.node tag
        (spanAttr HA.colspan cell.colspan
            ++ spanAttr HA.rowspan cell.rowspan
            ++ cell.attributes
        )
        (List.map embedChild cell.content)


spanAttr : (Int -> Html.Attribute msg) -> Maybe Int -> List (Html.Attribute msg)
spanAttr attr maybe =
    case maybe of
        Just n ->
            [ attr n ]

        Nothing ->
            []


{-| There is no public `Element` → `Html`, so a caller's element is
embedded through `Element.layoutWith` (the `NUI.Descriptions` /
`NUI.Form` precedent). The wrapper carries `display: contents` plus
`font`/`color: inherit`; `noStaticStyleSheet` keeps elm-ui's static
stylesheet from re-clobbering the bridge.
-}
embedChild : Element msg -> Html.Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child
