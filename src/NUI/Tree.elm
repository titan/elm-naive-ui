module NUI.Tree exposing
    ( CheckResult
    , CheckStrategy(..)
    , CheckboxPlacement(..)
    , DropMark
    , DropPosition(..)
    , FilteredTree
    , FlatNode
    , Options
    , TreeOption(..)
    , check
    , cssVars
    , defaults
    , filterTree
    , flatten
    , getCheckedKeys
    , getNonLeafKeys
    , toggleExpand
    , toggleSelect
    , uncheck
    , view
    )

{-| Naive UI's `Tree`, rebuilt on elm-ui.

    import NUI.Tree exposing (defaults)

    NUI.Tree.view theme { defaults | data = data, expandedKeys = [ "a" ] } []

Upstream renders a flat node list (`getFlattenedNodes` over the expanded
keys) as `div.n-tree-node-wrapper` rows inside the `div.n-tree` root; each
row is an indent chain (guide lines under `showLine`), a switcher (arrow
svg, or the loading spinner while the key is in `loadingKeys`), an optional
checkbox, and the content (prefix / label / suffix). All interaction state —
expanded / checked / selected / pending / loading keys — is caller-owned
data, exactly as upstream's controlled props; the view emits the DOM for it.

Upstream: `src/tree/src/Tree.tsx` (render + cssVars), `TreeNode.tsx`,
`TreeNodeSwitcher.tsx`, `TreeNodeCheckbox.tsx`, `TreeNodeContent.tsx`,
`utils.ts` (`filterTree`), and treemate (`getCheckedKeys`, flatten, check /
uncheck cascade math).

Not ported (runtime, caller-owned): the virtual-list branch (plain wrapper
path only, as in Select/Cascader), the expand/collapse `MotionWrapper`
transition, drag-drop event wiring (the drop mark itself is data:
`dropMark`), keyboard navigation (`pendingKey` is data), and the async
`onLoad` dance (`loadingKeys` is data). `--n-drop-mark-color` /
`--n-loading-color` stay live through those data fields.

-}

import Element
import Html
import Html.Attributes as HA
import NUI.Checkbox
import NUI.Empty
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Theme as Theme
import NUI.Theme.Tree as TreeTheme
import Svg


{-| Upstream `CheckStrategy` — `'all' | 'parent' | 'child'`.
-}
type CheckStrategy
    = All
    | Parent
    | Child


{-| Upstream `checkboxPlacement` — `'left' | 'right'`.
-}
type CheckboxPlacement
    = Left
    | Right


{-| Upstream `DropPosition` — `'before' | 'inside' | 'after'`.
-}
type DropPosition
    = Before
    | Inside
    | After


{-| Static drop-mark state (upstream derives it from drag events; here the
caller passes it). `offsetLevel` shifts a `Before` / `After` line left by
one indent per level (`dnd.tsx` `renderDropMark`).
-}
type alias DropMark =
    { key : String
    , position : DropPosition
    , offsetLevel : Int
    }


{-| One tree node — upstream's raw `TreeOption`, wrapped because a recursive
record cannot be a type alias. `children = Nothing` is upstream's absent
`children` field; `Just []` is a loaded-but-empty branch, which treemate
counts as non-leaf (the switcher renders, expanded or not). `isLeaf`
overrides the inference when `True` (upstream `isLeaf` prop).
-}
type TreeOption msg
    = TreeOption
        { key : String
        , label : String
        , disabled : Bool
        , checkboxDisabled : Bool
        , isLeaf : Bool
        , children : Maybe (List (TreeOption msg))
        , prefix : List (Element.Element msg)
        , suffix : List (Element.Element msg)
        }


{-| One flattened, visible node — treemate's `TreeNode` fields the render
reads: document-order position, depth (0 = root), last-child flags for the
`showLine` indent chain (self first, then ancestors nearest-first).
-}
type alias FlatNode msg =
    { option : TreeOption msg
    , key : String
    , level : Int
    , isLeaf : Bool
    , disabled : Bool
    , isLastChild : Bool
    , parentIsLast : List Bool
    }


{-| treemate's checked-state result — the normalized checked keys plus the
computed indeterminate set (upstream `getCheckedKeys`; the view skips the
indeterminate set when `Options.indeterminateKeys` overrides it).
-}
type alias CheckResult =
    { checkedKeys : List String
    , indeterminateKeys : List String
    }


{-| `filterTree`'s result (`utils.ts`) — the pruned tree that keeps matches
and their ancestor branches, the keys to highlight (`--highlight`), and the
keys that must expand to reveal the matches.
-}
type alias FilteredTree msg =
    { tree : List (TreeOption msg)
    , highlightKeys : List String
    , expandedKeys : List String
    }


{-| The tree options. Runtime behaviour (expansion / checking / selection /
loading orchestration, keyboard, drag) is caller-owned: it composes the
pure `toggleExpand` / `check` / `uncheck` / `toggleSelect` helpers with its
own messages and feeds the derived lists back in through this record.
-}
type alias Options msg =
    { data : List (TreeOption msg)
    , expandedKeys : List String
    , checkedKeys : List String
    , indeterminateKeys : Maybe (List String)
    , selectedKeys : List String
    , pendingKey : Maybe String
    , highlightKeys : Maybe (List String)
    , loadingKeys : List String
    , pattern : String
    , filter : Maybe (String -> TreeOption msg -> Bool)
    , showIrrelevantNodes : Bool
    , checkable : Bool
    , cascade : Bool
    , checkStrategy : CheckStrategy
    , allowCheckingNotLoaded : Bool
    , checkboxPlacement : CheckboxPlacement
    , selectable : Bool
    , multiple : Bool
    , cancelable : Bool
    , expandOnClick : Bool
    , checkOnClick : Bool
    , blockLine : Bool
    , blockNode : Bool
    , showLine : Bool
    , ellipsis : Bool
    , indent : Int
    , disabled : Bool
    , rtl : Bool
    , dropMark : Maybe DropMark
    , renderLabel : Maybe ({ checked : Bool, option : TreeOption msg, selected : Bool } -> Element.Element msg)
    , renderPrefix : Maybe ({ checked : Bool, option : TreeOption msg, selected : Bool } -> Element.Element msg)
    , renderSuffix : Maybe ({ checked : Bool, option : TreeOption msg, selected : Bool } -> Element.Element msg)
    , renderSwitcherIcon : Maybe ({ expanded : Bool, option : TreeOption msg, selected : Bool } -> Element.Element msg)
    , nodeProps : Maybe (TreeOption msg -> List (Element.Attribute msg))
    , spinStrokeWidth : Maybe Float
    , spinStroke : Maybe String
    , spinScale : Maybe Float
    , spinRadius : Maybe Float
    , empty : Maybe (Element.Element msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream prop defaults (`treeSharedProps` + `treeProps`): no state keys,
checkable off, cascade off, `All` strategy, checkboxes on the left,
selectable single with cancel, indent 24, LTR.
-}
defaults : Options msg
defaults =
    { data = []
    , expandedKeys = []
    , checkedKeys = []
    , indeterminateKeys = Nothing
    , selectedKeys = []
    , pendingKey = Nothing
    , highlightKeys = Nothing
    , loadingKeys = []
    , pattern = ""
    , filter = Nothing
    , showIrrelevantNodes = True
    , checkable = False
    , cascade = False
    , checkStrategy = All
    , allowCheckingNotLoaded = False
    , checkboxPlacement = Left
    , selectable = True
    , multiple = False
    , cancelable = True
    , expandOnClick = False
    , checkOnClick = False
    , blockLine = False
    , blockNode = False
    , showLine = False
    , ellipsis = False
    , indent = 24
    , disabled = False
    , rtl = False
    , dropMark = Nothing
    , renderLabel = Nothing
    , renderPrefix = Nothing
    , renderSuffix = Nothing
    , renderSwitcherIcon = Nothing
    , nodeProps = Nothing
    , spinStrokeWidth = Nothing
    , spinStroke = Nothing
    , spinScale = Nothing
    , spinRadius = Nothing
    , empty = Nothing
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The tree — the `div.n-tree` root (`--rtl` / `--checkable` / `--block-node`
(blockLine OR blockNode, `Tree.tsx:1775-1776`) / `--block-line` / `--ellipsis`
modifiers, `tabindex 0` unless `disabled`, inline `--n-*` vars) and one
`n-tree-node-wrapper` row per flattened node (`TreeNode.tsx:399-501`); the
`.n-tree__empty` body (an `NUI.Empty` carrying the class itself,
`Tree.tsx:1896-1903`) when nothing is visible.

The display derivation (`Tree.tsx:395-474, 565-576`): a non-empty `pattern`
with `showIrrelevantNodes = False` swaps the display tree for
`filterTree`'s pruned tree; the highlight set is `highlightKeys` when given,
else the filter's match set (derived whenever `pattern` is non-empty — the
display switch is the only part `showIrrelevantNodes` gates). Checked /
indeterminate normalize against the FULL data tree always (upstream
`dataTreeMate` vs `displayTreeMate`); `indeterminateKeys` overrides the
computed set wholesale.

-}
view : Theme.Theme -> Options msg -> Element.Element msg
view theme opts =
    let
        filterInfo =
            if opts.pattern == "" || opts.showIrrelevantNodes then
                { displayTree = opts.data
                , highlightKeys = []
                }

            else
                let
                    info =
                        filterTreeWith
                            (Maybe.withDefault defaultFilter opts.filter)
                            opts.pattern
                            opts.data
                in
                { displayTree = info.tree
                , highlightKeys = info.highlightKeys
                }

        status =
            getCheckedKeys opts.cascade
                opts.checkStrategy
                opts.allowCheckingNotLoaded
                opts.checkedKeys
                opts.data

        state =
            { checked = status.checkedKeys
            , indeterminate =
                Maybe.withDefault status.indeterminateKeys opts.indeterminateKeys
            , highlight =
                Maybe.withDefault filterInfo.highlightKeys opts.highlightKeys
            }

        visible =
            flatten opts.expandedKeys filterInfo.displayTree
    in
    Element.column
        (rootAttributes theme opts)
        (if visible == [] then
            [ emptyNode theme opts ]

         else
            List.map (rowNode theme opts state) visible
        )


{-| The root's class / `tabindex` / var attribute list (`Tree.tsx:1774-1778,
1886-1891`): the five modifiers — `--block-node` fires on `blockLine` too,
exactly upstream's `(blockLine || blockNode) &&` — the `tabindex 0` focus
seam (upstream `mergedFocusable = internalFocusable && !disabled`), and the
inline vars.
-}
rootAttributes : Theme.Theme -> Options msg -> List (Element.Attribute msg)
rootAttributes theme opts =
    [ I.classes
        ([ "n-tree"
         ]
            ++ I.classIf opts.rtl "n-tree--rtl"
            ++ I.classIf opts.checkable "n-tree--checkable"
            ++ I.classIf (opts.blockLine || opts.blockNode) "n-tree--block-node"
            ++ I.classIf opts.blockLine "n-tree--block-line"
            ++ I.classIf opts.ellipsis "n-tree--ellipsis"
        )
    ]
        ++ (if opts.disabled then
                []

            else
                [ Element.htmlAttribute (HA.tabindex 0) ]
           )
        ++ [ I.cssVars (cssVars theme) ]
        ++ opts.attributes


{-| The root's inline `--n-*` set — upstream `cssVarsRef` (`Tree.tsx:1676`):
the 14 theme self values plus `--n-bezier` (common) and three values derived
from the padding/height strings (shorthand-split, `depx`-math): the negated
wrapper-padding top/bottom offsets for the `showLine` guide lines and the
remaining per-node content height.
-}
cssVars : Theme.Theme -> List ( String, String )
cssVars theme =
    let
        v =
            TreeTheme.vars theme

        padding =
            getPadding v.nodeWrapperPadding

        lineOffsetTop =
            "-" ++ padding.top

        lineOffsetBottom =
            "-" ++ padding.bottom

        nodeContentHeight =
            String.fromInt
                (depx v.nodeHeight - depx padding.top - depx padding.bottom)
                ++ "px"
    in
    [ ( "--n-arrow-color", v.arrowColor )
    , ( "--n-loading-color", v.loadingColor )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-node-border-radius", v.nodeBorderRadius )
    , ( "--n-node-color-active", v.nodeColorActive )
    , ( "--n-node-color-hover", v.nodeColorHover )
    , ( "--n-node-color-pressed", v.nodeColorPressed )
    , ( "--n-node-text-color", v.nodeTextColor )
    , ( "--n-node-text-color-disabled", v.nodeTextColorDisabled )
    , ( "--n-drop-mark-color", v.dropMarkColor )
    , ( "--n-node-wrapper-padding", v.nodeWrapperPadding )
    , ( "--n-line-offset-top", lineOffsetTop )
    , ( "--n-line-offset-bottom", lineOffsetBottom )
    , ( "--n-node-content-height", nodeContentHeight )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-line-color", v.lineColor )
    ]


{-| Per-row view state the derivation computes once for the whole tree: the
cascade-normalized checked set, its indeterminate set (`indeterminateKeys`
may override), and the highlight set.
-}
type alias RowState =
    { checked : List String
    , indeterminate : List String
    , highlight : List String
    }


{-| One visible node's row — the wrapper div (its padding is CSS-only) over
the `.n-tree-node` flex row with the state classes (`TreeNode.tsx:435-447`,
declaration order): `--selected`, `--checkable` (the per-node gate
`TreeNode.tsx:122-129`: under `cascade` or a non-`Child` strategy every
node, otherwise leaves only), `--highlight`, `--pending`, `--disabled`,
`--selectable` (`TreeNode.tsx:111-121`, non-tree-select branch: the node's
own enabled state plus the tree switch), `--clickable` (`selectable ||
expandOnClick || checkOnClick`). Children order (`TreeNode.tsx:461-499`):
indent chain, switcher (or the `showLine` leaf indent), left checkbox,
content, drop mark, right checkbox.
-}
rowNode : Theme.Theme -> Options msg -> RowState -> FlatNode msg -> Element.Element msg
rowNode theme opts state flat =
    let
        key =
            keyOf flat.option

        disabled =
            opts.disabled || flat.disabled

        checkable =
            opts.checkable
                && (opts.cascade
                        || opts.checkStrategy
                        /= Child
                        || flat.isLeaf
                   )

        selectable =
            not flat.disabled && opts.selectable

        checkOnClick =
            checkable && opts.checkOnClick && not flat.disabled

        clickable =
            selectable || opts.expandOnClick || checkOnClick

        right =
            opts.checkboxPlacement == Right

        checkbox =
            checkboxNode theme opts state flat checkable disabled

        nodePropsAttrs =
            case opts.nodeProps of
                Just f ->
                    f flat.option

                Nothing ->
                    []
    in
    Element.el
        [ I.classes [ "n-tree-node-wrapper" ] ]
        (Element.row
            ([ I.classes
                ([ "n-tree-node" ]
                    ++ I.classIf (List.member key opts.selectedKeys) "n-tree-node--selected"
                    ++ I.classIf checkable "n-tree-node--checkable"
                    ++ I.classIf (List.member key state.highlight) "n-tree-node--highlight"
                    ++ I.classIf (opts.pendingKey == Just key) "n-tree-node--pending"
                    ++ I.classIf disabled "n-tree-node--disabled"
                    ++ I.classIf selectable "n-tree-node--selectable"
                    ++ I.classIf clickable "n-tree-node--clickable"
                )
             ]
                ++ (if opts.blockLine then
                        nodePropsAttrs

                    else
                        []
                   )
            )
            (indentNodes opts flat
                ++ [ if flat.isLeaf && opts.showLine then
                        leafIndentNode opts flat

                     else
                        switcherNode opts state flat
                   ]
                ++ [ if right then
                        Element.none

                     else
                        checkbox
                   ]
                ++ [ contentNode opts state flat ]
                ++ [ dropMarkNode opts flat ]
                ++ [ if right then
                        checkbox

                     else
                        Element.none
                   ]
            )
        )


{-| The indent chain (`TreeNode.tsx:268-310`): `level` plain indents, or
under `showLine` one per ancestor (root-first — the parentIsLast chain
reversed), `--show-line` on every ancestor that is NOT its parent's last
child (a guide line continues past it).
-}
indentNodes : Options msg -> FlatNode msg -> List (Element.Element msg)
indentNodes opts flat =
    if opts.showLine then
        List.map
            (\ancestorIsLast ->
                Element.el
                    [ I.classes
                        ([ "n-tree-node-indent" ]
                            ++ I.classIf (not ancestorIsLast) "n-tree-node-indent--show-line"
                        )
                    ]
                    (indentWidth opts)
            )
            (List.reverse flat.parentIsLast)

    else
        List.repeat flat.level
            (Element.el [ I.classes [ "n-tree-node-indent" ] ] (indentWidth opts))


{-| The `showLine` leaf's indent — replaces the switcher entirely
(`TreeNode.tsx:472-486`), carrying `--is-leaf` and `--last-child`.
-}
leafIndentNode : Options msg -> FlatNode msg -> Element.Element msg
leafIndentNode opts flat =
    Element.el
        [ I.classes
            ([ "n-tree-node-indent", "n-tree-node-indent--show-line" ]
                ++ I.classIf flat.isLeaf "n-tree-node-indent--is-leaf"
                ++ I.classIf flat.isLastChild "n-tree-node-indent--last-child"
            )
        ]
        (indentWidth opts)


{-| The inner width div every indent carries (`TreeNode.tsx:275-278`).
-}
indentWidth : Options msg -> Element.Element msg
indentWidth opts =
    Element.el
        [ Element.htmlAttribute
            (HA.style "width" (String.fromInt opts.indent ++ "px"))
        ]
        Element.none


{-| The switcher (`TreeNodeSwitcher.tsx`): `data-switcher`, `width: indent`,
`--expanded` / `--hide` (hidden exactly when the node is a leaf — the
`showLine` leaf renders the indent instead), and the `__icon` div with
either the loading spinner or the arrow (upstream's `NBaseIcon` +
`SwitcherIcon`).
-}
switcherNode : Options msg -> RowState -> FlatNode msg -> Element.Element msg
switcherNode opts state flat =
    let
        key =
            keyOf flat.option
    in
    Element.el
        [ I.classes
            ([ "n-tree-node-switcher" ]
                ++ I.classIf (List.member key opts.expandedKeys) "n-tree-node-switcher--expanded"
                ++ I.classIf flat.isLeaf "n-tree-node-switcher--hide"
            )
        , Element.htmlAttribute
            (HA.style "width" (String.fromInt opts.indent ++ "px"))
        , Element.htmlAttribute (HA.attribute "data-switcher" "")
        ]
        (Element.el
            [ I.classes [ "n-tree-node-switcher__icon" ] ]
            (if List.member key opts.loadingKeys then
                loadingIconNode opts

             else
                case opts.renderSwitcherIcon of
                    Just render ->
                        render
                            { expanded = List.member key opts.expandedKeys
                            , option = flat.option
                            , selected = List.member key opts.selectedKeys
                            }

                    Nothing ->
                        Element.html
                            (Html.i [ HA.class "n-base-icon" ] [ switcherSvg ])
            )
        )


{-| The loading switcher — `NBaseLoading`'s own markup (root
`role="img" aria-label="loading"`, `Loading.tsx:50`) wrapped in the
transition/container divs, spinning with the `TreeNodeSwitcher.tsx:50-56`
baseline (`strokeWidth 20, radius 85`, `scale` 1 unset) under the
per-field `spin*` overrides (the `spinProps` spread lands AFTER the
explicit props, so each `Just` wins).
-}
loadingIconNode : Options msg -> Element.Element msg
loadingIconNode opts =
    Element.el
        [ I.classes [ "n-base-loading" ]
        , Element.htmlAttribute (HA.attribute "role" "img")
        , Element.htmlAttribute (HA.attribute "aria-label" "loading")
        ]
        (Element.el
            [ I.classes [ "n-base-loading__transition-wrapper" ] ]
            (Element.el
                [ I.classes [ "n-base-loading__container" ] ]
                (Element.html
                    (Loading.spinner
                        { strokeWidth = Maybe.withDefault 20 opts.spinStrokeWidth
                        , radius = Maybe.withDefault 85 opts.spinRadius
                        , scale = Maybe.withDefault 1 opts.spinScale
                        , stroke = opts.spinStroke
                        }
                    )
                )
            )
        )


{-| The checkbox cell (`TreeNodeCheckbox.tsx`): the `data-checkbox` span
(`width: indent`, `--right` on the right) around an `NUI.Checkbox` —
`disabled` merges tree, node and `checkboxDisabled`
(`TreeNode.tsx:489-491`), checked / indeterminate come from the normalized
state, focusable on (upstream `internalCheckboxFocusable` default).
-}
checkboxNode : Theme.Theme -> Options msg -> RowState -> FlatNode msg -> Bool -> Bool -> Element.Element msg
checkboxNode theme opts state flat checkable disabled =
    let
        key =
            keyOf flat.option

        (TreeOption raw) =
            flat.option

        d =
            NUI.Checkbox.defaults
    in
    if checkable then
        Element.el
            [ I.classes
                ([ "n-tree-node-checkbox" ]
                    ++ I.classIf (opts.checkboxPlacement == Right) "n-tree-node-checkbox--right"
                )
            , Element.htmlAttribute
                (HA.style "width" (String.fromInt opts.indent ++ "px"))
            , Element.htmlAttribute (HA.attribute "data-checkbox" "")
            ]
            (NUI.Checkbox.view theme
                { d
                    | checked = List.member key state.checked
                    , indeterminate = List.member key state.indeterminate
                    , disabled = disabled || raw.checkboxDisabled
                    , focusable = True
                }
                []
            )

    else
        Element.none


{-| The content span (`TreeNodeContent.tsx:56-105`): the node's `nodeProps`
attributes (skipped under `blockLine`, where they ride the node div
instead — `TreeNode.tsx:483,494`), then `__prefix` (when a render prefix or
node prefix exists), the always-present `__text`, and `__suffix` (when a
render suffix or node suffix exists). Render fns receive `{option,
selected, checked}`.
-}
contentNode : Options msg -> RowState -> FlatNode msg -> Element.Element msg
contentNode opts state flat =
    let
        (TreeOption raw) =
            flat.option

        key =
            keyOf flat.option

        ctx =
            { checked = List.member key state.checked
            , option = flat.option
            , selected = List.member key opts.selectedKeys
            }

        prefix =
            case opts.renderPrefix of
                Just render ->
                    Just (render ctx)

                Nothing ->
                    if raw.prefix == [] then
                        Nothing

                    else
                        Just (Element.row [] raw.prefix)

        text =
            case opts.renderLabel of
                Just render ->
                    render ctx

                Nothing ->
                    Element.text raw.label

        suffix =
            case opts.renderSuffix of
                Just render ->
                    Just (render ctx)

                Nothing ->
                    if raw.suffix == [] then
                        Nothing

                    else
                        Just (Element.row [] raw.suffix)

        nodePropsAttrs =
            case opts.nodeProps of
                Just f ->
                    f flat.option

                Nothing ->
                    []
    in
    Element.row
        ([ I.classes [ "n-tree-node-content" ] ]
            ++ (if opts.blockLine then
                    []

                else
                    nodePropsAttrs
               )
        )
        [ case prefix of
            Just element ->
                Element.el
                    [ I.classes [ "n-tree-node-content__prefix" ] ]
                    element

            Nothing ->
                Element.none
        , Element.el
            [ I.classes [ "n-tree-node-content__text" ] ]
            text
        , case suffix of
            Just element ->
                Element.el
                    [ I.classes [ "n-tree-node-content__suffix" ] ]
                    element

            Nothing ->
                Element.none
        ]


{-| The static drop mark (`dnd.tsx:8-41`, mounted in the node row right
after the content, `TreeNode.tsx:494-497`): a classless absolutely
positioned div — `inside` is the full inset ring
(`box-shadow: inset 0 0 0 2px var(--n-drop-mark-color)`,
`border-radius: inherit`); `before` / `after` are 2px lines at the
top/bottom, `left = contentOffsetLeft + 6 - offsetLevel * indent`
(upstream reads `el.offsetLeft`; the port computes it from its own row
geometry: one indent per level, the switcher's, and the left checkbox's).
`translateY(±4px)` and `transform-origin` follow the position.
-}
dropMarkNode : Options msg -> FlatNode msg -> Element.Element msg
dropMarkNode opts flat =
    case opts.dropMark of
        Nothing ->
            Element.none

        Just { key, position, offsetLevel } ->
            if key /= keyOf flat.option then
                Element.none

            else
                let
                    checkboxLeft =
                        opts.checkable && opts.checkboxPlacement == Left

                    left =
                        (flat.level
                            + 1
                            + (if checkboxLeft then
                                1

                               else
                                0
                              )
                        )
                            * opts.indent
                            + 6
                            - offsetLevel
                            * opts.indent

                    common =
                        "position:absolute;box-sizing:border-box;right:0;"

                    line position_ cssPosition transform =
                        common
                            ++ cssPosition
                            ++ ":0;left:"
                            ++ String.fromInt left
                            ++ "px;height:2px;background:var(--n-drop-mark-color);transform-origin:"
                            ++ position_
                            ++ ";border-radius:1px;transform:translateY("
                            ++ transform
                            ++ "px)"
                in
                Element.html
                    (Html.div
                        [ HA.attribute "style"
                            (case position of
                                Inside ->
                                    common
                                        ++ "left:0;top:0;bottom:0;border-radius:inherit;box-shadow: inset 0 0 0 2px var(--n-drop-mark-color)"

                                Before ->
                                    line "top" "top" "-4"

                                After ->
                                    line "bottom" "bottom" "4"
                            )
                        ]
                        []
                    )


{-| The empty body — an `NUI.Empty` carrying the `n-tree__empty` class
itself (`Tree.tsx:1896-1903`), or the caller's `empty` element wholesale
(upstream's `resolveSlot`: the slot replaces the default, class included).
-}
emptyNode : Theme.Theme -> Options msg -> Element.Element msg
emptyNode theme opts =
    case opts.empty of
        Just element ->
            element

        Nothing ->
            let
                d =
                    NUI.Empty.defaults
            in
            NUI.Empty.view theme
                { d | attributes = [ I.classes [ "n-tree__empty" ] ] }
                []



-- PURE LOGIC -------------------------------------------------------------------


{-| treemate's `getCheckedKeys` — normalize raw keys against the tree. With
`cascade`, each key extends to its whole enabled subtree and the parents
aggregate bottom-up (`indeterminateKeys` collects the partial ones);
`checkStrategy` then collapses the result (`All` keeps every level,
`Parent` the topmost checked ancestor, `Child` leaf levels only). An
unloaded node (`children = Nothing`, `isLeaf = False`) keeps its own key
under `allowCheckingNotLoaded` and is dropped without it (upstream
`check` / `uncheck` throw `SubtreeNotLoadedError` there — the pure port
drops the key instead; `getCheckedKeys` normalization never throws and
behaves identically either way).
-}
getCheckedKeys : Bool -> CheckStrategy -> Bool -> List String -> List (TreeOption msg) -> CheckResult
getCheckedKeys cascade strategy allowNotLoaded keys options =
    normalize cascade strategy allowNotLoaded NoToggle keys (index options)


{-| Upstream `doCheck`'s multiple branch (`Tree.tsx:1034-1062`) — treemate's
`check`: the key's subtree joins the checked set, then the cascade
re-normalizes. See `getCheckedKeys` for the unloaded-node rule.
-}
check : Bool -> CheckStrategy -> Bool -> String -> List String -> List (TreeOption msg) -> List String
check cascade strategy allowNotLoaded key current options =
    .checkedKeys
        (normalize cascade strategy allowNotLoaded (ToCheck key) current (index options))


{-| Upstream `doUncheck` — treemate's `uncheck`: the key's extended subtree
and its available (non-disabled) ancestors leave the checked set, then the
cascade re-normalizes.
-}
uncheck : Bool -> CheckStrategy -> Bool -> String -> List String -> List (TreeOption msg) -> List String
uncheck cascade strategy allowNotLoaded key current options =
    .checkedKeys
        (normalize cascade strategy allowNotLoaded (ToUncheck key) current (index options))


{-| Upstream `toggleExpand` (`Tree.tsx:1104-1131`): a present key collapses
(order preserved); an absent one expands unless it is unknown or a leaf.
Under `accordion` every expanded SIBLING of the key (the parent's whole
children list, self included) collapses first, then the key appends.
-}
toggleExpand : Bool -> List (TreeOption msg) -> String -> List String -> List String
toggleExpand accordion data key expandedKeys =
    if List.member key expandedKeys then
        List.filter ((/=) key) expandedKeys

    else
        case find key (index data) of
            Nothing ->
                expandedKeys

            Just node ->
                if isLeaf node.option then
                    expandedKeys

                else if accordion then
                    let
                        siblingKeys =
                            List.map keyOf node.siblings
                    in
                    List.filter (\k -> not (List.member k siblingKeys)) expandedKeys
                        ++ [ key ]

                else
                    expandedKeys ++ [ key ]


{-| Upstream `handleSelect`'s set update (`Tree.tsx:1109-1159`): single mode
replaces the set, clearing it when the key was selected and `cancelable`;
multiple mode toggles membership — append-only when not `cancelable`. The
disabled / selectable guards around it are caller-owned.
-}
toggleSelect : Bool -> Bool -> String -> List String -> List String
toggleSelect multiple cancelable key selectedKeys =
    if multiple then
        if List.member key selectedKeys then
            if cancelable then
                List.filter ((/=) key) selectedKeys

            else
                selectedKeys

        else
            selectedKeys ++ [ key ]

    else if List.member key selectedKeys then
        if cancelable then
            []

        else
            selectedKeys

    else
        [ key ]


{-| Upstream `getNonLeafKeys` — every expandable node's key in document
order (a node is a leaf when `isLeaf` is set or `children` is `Nothing`,
so `Just []` branches count as non-leaves).
-}
getNonLeafKeys : List (TreeOption msg) -> List String
getNonLeafKeys options =
    List.map (keyOf << .option)
        (List.filter
            (\node -> not (isLeaf node.option))
            (index options)
        )


{-| Upstream `getFlattenedNodes` — the visible nodes in document order:
children join only while their parent's key sits in `expandedKeys`, each
with its depth (roots at 0), leaf / disabled resolution, last-child flag,
and the ancestors' last-child chain (nearest-first) for the `showLine`
indent.
-}
flatten : List String -> List (TreeOption msg) -> List (FlatNode msg)
flatten expandedKeys options =
    flattenLevel expandedKeys 0 [] options


flattenLevel :
    List String
    -> Int
    -> List Bool
    -> List (TreeOption msg)
    -> List (FlatNode msg)
flattenLevel expandedKeys level parentIsLast siblings =
    let
        count =
            List.length siblings
    in
    List.concatMap
        (\( index_, option ) ->
            let
                key =
                    keyOf option

                flat =
                    { option = option
                    , key = key
                    , level = level
                    , isLeaf = isLeaf option
                    , disabled = disabledOf option
                    , isLastChild = index_ + 1 == count
                    , parentIsLast = parentIsLast
                    }
            in
            flat
                :: (if List.member key expandedKeys then
                        case childrenOf option of
                            Just kids ->
                                flattenLevel expandedKeys
                                    (level + 1)
                                    (flat.isLastChild :: parentIsLast)
                                    kids

                            Nothing ->
                                []

                    else
                        []
                   )
        )
        (List.indexedMap Tuple.pair siblings)


{-| Upstream `filterTree` (`utils.ts:78-146`) with the default
case-insensitive label-contains matcher (`Tree.tsx:397-411`): the pruned
tree keeps every match and the branch above it (a matched branch deep in a
collapsed subtree keeps its whole subtree — the visited-tail rule), the
highlight set is the matched keys in document order, and the expanded set
is the cloned-branch keys that reveal the matches. An empty pattern
echoes the tree untouched.
-}
filterTree : String -> List (TreeOption msg) -> FilteredTree msg
filterTree pattern options =
    filterTreeWith defaultFilter pattern options


{-| `filterTree` under a caller matcher (upstream's `filter` prop swap).
-}
filterTreeWith :
    (String -> TreeOption msg -> Bool)
    -> String
    -> List (TreeOption msg)
    -> FilteredTree msg
filterTreeWith matcher pattern options =
    if pattern == "" then
        { tree = options, highlightKeys = [], expandedKeys = [] }

    else
        let
            ( tails, nonTails, highlights ) =
                visitTree matcher pattern [] options ( [], [], [] )

            ( tree, expanded ) =
                buildTree tails nonTails options
        in
        { tree = tree
        , highlightKeys = highlights
        , expandedKeys = expanded
        }


{-| Upstream's default filter — the (non-empty) pattern as a
case-insensitive substring of the label.
-}
defaultFilter : String -> TreeOption msg -> Bool
defaultFilter pattern option =
    String.contains (String.toLower pattern) (String.toLower (labelOf option))


{-| `filterTree`'s first phase (`utils.ts:84-113`): walk with a path
stack; a match joins the tail set and the highlight set, and each ancestor
up the stack joins the non-tail set — stopping at the first ancestor
already in it — unless it was a tail, in which case it demotes to
non-tail.
-}
visitTree :
    (String -> TreeOption msg -> Bool)
    -> String
    -> List (TreeOption msg)
    -> List (TreeOption msg)
    -> ( List String, List String, List String )
    -> ( List String, List String, List String )
visitTree matcher pattern path siblings acc =
    List.foldl
        (\option acc1 ->
            let
                path1 =
                    path ++ [ option ]

                ( t, nt, h ) =
                    acc1

                ( tails1, nonTails1, highlights1 ) =
                    if matcher pattern option then
                        let
                            ( t2, nt2 ) =
                                markAncestors
                                    (List.reverse
                                        (List.take (List.length path1 - 1) path1)
                                    )
                                    ( addIfAbsent (keyOf option) t
                                    , nt
                                    )
                        in
                        ( t2, nt2, addIfAbsent (keyOf option) h )

                    else
                        ( t, nt, h )
            in
            case childrenOf option of
                Just kids ->
                    visitTree matcher pattern path1 kids ( tails1, nonTails1, highlights1 )

                Nothing ->
                    ( tails1, nonTails1, highlights1 )
        )
        acc
        siblings


markAncestors : List (TreeOption msg) -> ( List String, List String ) -> ( List String, List String )
markAncestors nearestFirst ( tails, nonTails ) =
    case nearestFirst of
        [] ->
            ( tails, nonTails )

        ancestor :: rest ->
            let
                key =
                    keyOf ancestor
            in
            if List.member key nonTails then
                ( tails, nonTails )

            else
                markAncestors rest
                    ( List.filter ((/=) key) tails
                    , addIfAbsent key nonTails
                    )


{-| `filterTree`'s second phase (`utils.ts:115-141`): visited tails keep
their origin node whole; visited non-tail branches clone to
`children = []` (their key joins `expandedKeys`) and recurse — anything
unvisited drops.
-}
buildTree :
    List String
    -> List String
    -> List (TreeOption msg)
    -> ( List (TreeOption msg), List String )
buildTree tails nonTails siblings =
    List.foldl
        (\option ( acc, expanded ) ->
            let
                key =
                    keyOf option
            in
            if not (List.member key tails) && not (List.member key nonTails) then
                ( acc, expanded )

            else
                case childrenOf option of
                    Just kids ->
                        if List.member key tails then
                            ( acc ++ [ option ], expanded )

                        else
                            let
                                (TreeOption raw) =
                                    option

                                ( built, expanded2 ) =
                                    buildTree tails nonTails kids
                            in
                            ( acc
                                ++ [ TreeOption { raw | children = Just built }
                                   ]
                            , expanded ++ key :: expanded2
                            )

                    Nothing ->
                        ( acc ++ [ option ], expanded )
        )
        ( [], [] )
        siblings



-- TREE INDEX -------------------------------------------------------------------


{-| treemate's built index: one entry per node in document order, carrying
its level, its root-first ancestor chain and the sibling list it belongs
to (self included) — `treeNodes` / `treeNodeMap` fused with what the
expand / accordion toggles need.
-}
type alias Indexed msg =
    { option : TreeOption msg
    , level : Int
    , ancestors : List (TreeOption msg)
    , siblings : List (TreeOption msg)
    }


index : List (TreeOption msg) -> List (Indexed msg)
index options =
    indexColumn 0 [] options


indexColumn :
    Int
    -> List (TreeOption msg)
    -> List (TreeOption msg)
    -> List (Indexed msg)
indexColumn level ancestors siblings =
    List.concatMap
        (\( index_, option ) ->
            Indexed option level ancestors siblings
                :: (case childrenOf option of
                        Just kids ->
                            indexColumn (level + 1) (ancestors ++ [ option ]) kids

                        Nothing ->
                            []
                   )
        )
        (List.indexedMap Tuple.pair siblings)


{-| treemate's `getNode` — first node whose key matches, document order
(duplicate keys are invalid data upstream; its map would keep the last).
-}
find : String -> List (Indexed msg) -> Maybe (Indexed msg)
find key nodes =
    List.head (List.filter (\n -> keyOf n.option == key) nodes)


{-| The record inside the `TreeOption` wrapper.
-}
fields :
    TreeOption msg
    ->
        { key : String
        , label : String
        , disabled : Bool
        , checkboxDisabled : Bool
        , isLeaf : Bool
        , children : Maybe (List (TreeOption msg))
        , prefix : List (Element.Element msg)
        , suffix : List (Element.Element msg)
        }
fields (TreeOption raw) =
    raw


keyOf : TreeOption msg -> String
keyOf option =
    .key (fields option)


labelOf : TreeOption msg -> String
labelOf option =
    .label (fields option)


disabledOf : TreeOption msg -> Bool
disabledOf option =
    .disabled (fields option)


childrenOf : TreeOption msg -> Maybe (List (TreeOption msg))
childrenOf option =
    .children (fields option)


{-| treemate's `isLeaf` — the explicit `isLeaf` prop wins; without it the
`children` field decides: absent is a leaf, an empty-but-present list is a
loaded empty branch (a truthy array).
-}
isLeaf : TreeOption msg -> Bool
isLeaf option =
    let
        raw =
            fields option
    in
    raw.isLeaf || raw.children == Nothing


{-| An expandable node whose children have not arrived — `isLeaf = False`
with `children = Nothing`. Upstream's `shallowLoaded` negation
(`Tree.tsx` `triggerLoading`); the `allowCheckingNotLoaded` gate reads it.
-}
unloadedOf : TreeOption msg -> Bool
unloadedOf option =
    not (fields option).isLeaf && .children (fields option) == Nothing



-- CASCADE NORMALIZATION ---------------------------------------------------------


{-| The treemate toggle a normalization run starts from.
-}
type Toggle
    = NoToggle
    | ToCheck String
    | ToUncheck String


normalize :
    Bool
    -> CheckStrategy
    -> Bool
    -> Toggle
    -> List String
    -> List (Indexed msg)
    -> CheckResult
normalize cascade strategy allowNotLoaded toggle keys nodes =
    if not cascade then
        { checkedKeys =
            case toggle of
                ToCheck key ->
                    addIfAbsent key keys

                ToUncheck key ->
                    List.filter ((/=) key) keys

                NoToggle ->
                    keys
        , indeterminateKeys = []
        }

    else
        let
            extended =
                case toggle of
                    ToCheck key ->
                        extendCheckedKeySet allowNotLoaded (keys ++ [ key ]) nodes

                    ToUncheck key ->
                        afterUncheck allowNotLoaded key keys nodes

                    NoToggle ->
                        extendCheckedKeySet allowNotLoaded keys nodes
        in
        cascadeWalk (levelsDesc nodes) extended [] strategy


{-| treemate's `getExtendedCheckedKeySet` — each checked key's enabled
subtree joins the set (a disabled node blocks its own key and its
subtree; an unloaded node keeps only its own key under
`allowCheckingNotLoaded`, nothing without it); raw keys missing from the
tree stay put.
-}
extendCheckedKeySet : Bool -> List String -> List (Indexed msg) -> List String
extendCheckedKeySet allowNotLoaded keys nodes =
    Tuple.second
        (List.foldl
            (\key ( visited, extended ) ->
                case find key nodes of
                    Just node ->
                        visit allowNotLoaded node ( visited, extended ) nodes

                    Nothing ->
                        ( visited, extended )
            )
            ( [], dedupe keys )
            (dedupe keys)
        )


visit :
    Bool
    -> Indexed msg
    -> ( List String, List String )
    -> List (Indexed msg)
    -> ( List String, List String )
visit allowNotLoaded node ( visited, extended ) nodes =
    if disabledOf node.option then
        ( visited, extended )

    else if unloadedOf node.option && not allowNotLoaded then
        ( visited, extended )

    else
        let
            key =
                keyOf node.option

            state =
                if List.member key visited then
                    ( visited, extended )

                else
                    ( key :: visited, addIfAbsent key extended )
        in
        List.foldl
            (\child st ->
                case find (keyOf child) nodes of
                    Just childNode ->
                        visit allowNotLoaded childNode st nodes

                    Nothing ->
                        st
            )
            state
            (Maybe.withDefault [] (childrenOf node.option))


{-| treemate's `getExtendedCheckedKeySetAfterUncheck` — the current set's
extension minus the unchecked key's extension and its available ancestors
(the chain up to the first disabled ancestor, each stop breaking the
walk; a node already visited through another key stops it too).
-}
afterUncheck : Bool -> String -> List String -> List (Indexed msg) -> List String
afterUncheck allowNotLoaded key current nodes =
    let
        extended =
            extendCheckedKeySet allowNotLoaded current nodes

        toUncheck =
            extendCheckedKeySet allowNotLoaded [ key ] nodes

        ascendants =
            availableAscendants [ key ] nodes
    in
    List.filter
        (\k -> not (List.member k toUncheck) && not (List.member k ascendants))
        extended


availableAscendants : List String -> List (Indexed msg) -> List String
availableAscendants keys nodes =
    List.foldl
        (\key visited ->
            case find key nodes of
                Just node ->
                    ascend (List.reverse node.ancestors) visited

                Nothing ->
                    visited
        )
        []
        keys


ascend : List (TreeOption msg) -> List String -> List String
ascend nearestFirst visited =
    case nearestFirst of
        [] ->
            visited

        ancestor :: rest ->
            if disabledOf ancestor then
                visited

            else if List.member (keyOf ancestor) visited then
                visited

            else
                ascend rest (keyOf ancestor :: visited)


{-| The nodes grouped by level, deepest first (treemate's `levelTreeNodeMap`
walked `maxLevel` → 0; the intra-level order is document order, which the
set arithmetic does not depend on).
-}
levelsDesc : List (Indexed msg) -> List ( Int, List (Indexed msg) )
levelsDesc nodes =
    groupLevels nodes []
        |> List.sortBy Tuple.first
        |> List.reverse


groupLevels :
    List (Indexed msg)
    -> List ( Int, List (Indexed msg) )
    -> List ( Int, List (Indexed msg) )
groupLevels nodes acc =
    case nodes of
        [] ->
            acc

        node :: rest ->
            let
                level =
                    node.level
            in
            case List.partition (\( l, _ ) -> l == level) acc of
                ( ( _, same ) :: _, others ) ->
                    groupLevels rest (( level, same ++ [ node ] ) :: others)

                ( [], others ) ->
                    groupLevels rest (( level, [ node ] ) :: others)


{-| The cascade phase — bottom-up per node: `Child` first drops checked
non-leaf children (only leaves stay), then the parent aggregates (all
enabled children checked → the parent joins the checked set, collapsing
its children under `Parent`; some → indeterminate), and a checked level-0
branch leaves the set under `Child` (no higher level cleans it).
-}
cascadeWalk :
    List ( Int, List (Indexed msg) )
    -> List String
    -> List String
    -> CheckStrategy
    -> CheckResult
cascadeWalk groups checked indeterminate strategy =
    case groups of
        [] ->
            { checkedKeys = checked, indeterminateKeys = indeterminate }

        ( level, nodes ) :: rest ->
            let
                ( checked1, indeterminate1 ) =
                    List.foldl
                        (\node st -> cascadeNode level node st strategy)
                        ( checked, indeterminate )
                        nodes
            in
            cascadeWalk rest checked1 indeterminate1 strategy


cascadeNode :
    Int
    -> Indexed msg
    -> ( List String, List String )
    -> CheckStrategy
    -> ( List String, List String )
cascadeNode level node ( checked, indeterminate ) strategy =
    if isLeaf node.option then
        ( checked, indeterminate )

    else
        let
            children =
                Maybe.withDefault [] (childrenOf node.option)

            checkedAfterChildStrategy =
                if strategy == Child then
                    List.filter
                        (\k ->
                            not
                                (List.any
                                    (\c ->
                                        not (disabledOf c)
                                            && not (isLeaf c)
                                            && keyOf c
                                            == k
                                    )
                                    children
                                )
                        )
                        checked

                else
                    checked
        in
        if disabledOf node.option then
            ( checkedAfterChildStrategy, indeterminate )

        else
            let
                ( fullyChecked, partialChecked, allDisabled ) =
                    scanChildren children checkedAfterChildStrategy indeterminate ( True, False, True )

                key =
                    keyOf node.option

                ( checked2, indeterminate2 ) =
                    if fullyChecked && not allDisabled then
                        ( addIfAbsent key
                            (if strategy == Parent then
                                List.filter
                                    (\k ->
                                        not
                                            (List.any
                                                (\c -> not (disabledOf c) && keyOf c == k)
                                                children
                                            )
                                    )
                                    checkedAfterChildStrategy

                             else
                                checkedAfterChildStrategy
                            )
                        , indeterminate
                        )

                    else if partialChecked then
                        ( checkedAfterChildStrategy, addIfAbsent key indeterminate )

                    else
                        ( checkedAfterChildStrategy, indeterminate )
            in
            ( if level == 0 && strategy == Child && List.member key checked2 then
                List.filter ((/=) key) checked2

              else
                checked2
            , indeterminate2
            )


{-| treemate's per-parent scan over its children (disabled ones skipped): a
checked child marks partial, an indeterminate or unchecked one clears
full — and either break ends the scan (the checked branch never clears
full, upstream's quirk).
-}
scanChildren :
    List (TreeOption msg)
    -> List String
    -> List String
    -> ( Bool, Bool, Bool )
    -> ( Bool, Bool, Bool )
scanChildren children checked indeterminate ( fullyChecked, partialChecked, allDisabled ) =
    case children of
        [] ->
            ( fullyChecked, partialChecked, allDisabled )

        child :: rest ->
            if disabledOf child then
                scanChildren rest checked indeterminate ( fullyChecked, partialChecked, allDisabled )

            else
                let
                    key =
                        keyOf child
                in
                if List.member key checked then
                    scanChildren rest checked indeterminate ( fullyChecked, True, False )

                else if List.member key indeterminate then
                    ( False, True, False )

                else if partialChecked then
                    ( False, True, False )

                else
                    scanChildren rest checked indeterminate ( False, False, False )


addIfAbsent : String -> List String -> List String
addIfAbsent key keys =
    if List.member key keys then
        keys

    else
        keys ++ [ key ]


dedupe : List String -> List String
dedupe keys =
    List.foldl addIfAbsent [] keys



-- ICONS -------------------------------------------------------------------------


{-| Upstream `SwitcherIcon` (`_internal/icons/Switcher.tsx`) — the bare
32×32 triangle; the fill arrives through `.n-base-icon`'s
`fill: currentColor` rule (the path carries no fill of its own).
-}
switcherSvg : Html.Html msg
switcherSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 32 32"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path" [ HA.attribute "d" "M12 8l10 8l-10 8z" ] [] ]



-- INTERNALS


{-| seemly's `getPadding` shorthand split (as in `NUI.Card`) — the derived
`--n-line-offset-*` / `--n-node-content-height` vars read only top/bottom.
-}
getPadding : String -> { top : String, bottom : String }
getPadding padding =
    let
        parts =
            padding
                |> String.trim
                |> String.words

        at idx fallback =
            List.drop idx parts
                |> List.head
                |> Maybe.withDefault fallback

        top =
            at 0 ""
    in
    { top = top
    , bottom = at 2 top
    }


{-| seemly's `depx` — the px length as a plain number (`"0"` included).
-}
depx : String -> Int
depx value =
    value
        |> String.replace "px" ""
        |> String.trim
        |> String.toFloat
        |> Maybe.map round
        |> Maybe.withDefault 0
