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
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme as Theme
import NUI.Theme.Tree as TreeTheme


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



-- VIEW


{-| The tree — the `div.n-tree` root (`--rtl` / `--checkable` /
`--block-node` / `--block-line` / `--ellipsis` modifiers, `tabindex 0`,
inline `--n-*` vars) and one `n-tree-node-wrapper` row per flattened node;
the `.n-tree__empty` body when nothing is visible.
-}
view : Theme.Theme -> Options msg -> Element.Element msg
view theme opts =
    -- TODO(port): flattened rows, switcher, checkbox, content, empty state.
    Element.el
        (rootAttributes theme opts)
        Element.none


{-| The root's class / `tabindex` / var attribute list — shared by `view` and
the stub so the root parity is pinned from the start.
-}
rootAttributes : Theme.Theme -> Options msg -> List (Element.Attribute msg)
rootAttributes theme opts =
    [ I.classes
        ([ "n-tree"
         ]
            ++ I.classIf opts.rtl "n-tree--rtl"
            ++ I.classIf opts.checkable "n-tree--checkable"
            ++ I.classIf opts.blockNode "n-tree--block-node"
            ++ I.classIf opts.blockLine "n-tree--block-line"
            ++ I.classIf opts.ellipsis "n-tree--ellipsis"
        )
    , Element.htmlAttribute (HA.tabindex 0)
    , I.cssVars (cssVars theme)
    ]
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



-- PURE LOGIC


{-| treemate's `getCheckedKeys` — normalize raw keys against the tree. With
`cascade` the aggregate is computed over enabled nodes (a disabled node
blocks its own key and its subtree); `allowCheckingNotLoaded` keeps keys
whose nodes are unloaded (`children = Nothing`).
-}
getCheckedKeys : Bool -> CheckStrategy -> Bool -> List String -> List (TreeOption msg) -> CheckResult
getCheckedKeys _ _ _ keys _ =
    -- TODO(port): treemate cascade normalization.
    { checkedKeys = keys, indeterminateKeys = [] }


{-| Upstream `doCheck`'s multiple branch — treemate's `check`: the key's
extended subtree joins the checked set, then the cascade re-normalizes.
-}
check : Bool -> CheckStrategy -> Bool -> String -> List String -> List (TreeOption msg) -> List String
check _ _ _ _ keys _ =
    -- TODO(port): treemate check + normalization.
    keys


{-| Upstream `doUncheck` — treemate's `uncheck`: the key's extended subtree
leaves the checked set, then the cascade re-normalizes.
-}
uncheck : Bool -> CheckStrategy -> Bool -> String -> List String -> List (TreeOption msg) -> List String
uncheck _ _ _ _ keys _ =
    -- TODO(port): treemate uncheck + normalization.
    keys


{-| Upstream `handleSwitcherClick`'s expand set update (`Tree.tsx:1104`): the
key toggles in the expanded list; under `accordion` its expanded siblings
collapse (`Tree.tsx:1086`). Unknown keys expand (upstream appends).
-}
toggleExpand : Bool -> List (TreeOption msg) -> String -> List String -> List String
toggleExpand _ _ _ expandedKeys =
    -- TODO(port): accordion-aware toggle.
    expandedKeys


{-| Upstream `handleSelect` (`Tree.tsx:1109`): single mode replaces the set
(clears it when the key was selected and `cancelable`); multiple toggles
membership (append-only when not `cancelable`).
-}
toggleSelect : Bool -> Bool -> String -> List String -> List String
toggleSelect _ _ _ selectedKeys =
    -- TODO(port): multiple / cancelable semantics.
    selectedKeys


{-| Upstream `getNonLeafKeys` — every node's key that has children (the
`defaultExpandAll` seed).
-}
getNonLeafKeys : List (TreeOption msg) -> List String
getNonLeafKeys _ =
    -- TODO(port): non-leaf key walk.
    []


{-| Upstream `getFlattenedNodes` — the visible nodes in document order:
children of expanded keys only, each with its depth and last-child chain.
-}
flatten : List String -> List (TreeOption msg) -> List (FlatNode msg)
flatten _ _ =
    -- TODO(port): expanded-keys flatten.
    []


{-| Upstream `filterTree` (`utils.ts:78`) with the default case-insensitive
label-contains matcher: the pruned tree keeps every match and the branch
above it, the highlight set is the matched keys, and the expanded set is
what reveals them. (`Options.filter` swaps the matcher; `pattern = ""`
skips the whole thing.)
-}
filterTree : String -> List (TreeOption msg) -> FilteredTree msg
filterTree _ data =
    -- TODO(port): two-phase filter walk.
    { tree = data, highlightKeys = [], expandedKeys = [] }



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

        at index fallback =
            List.drop index parts
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
