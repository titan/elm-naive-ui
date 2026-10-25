module NUI.TreeSelect exposing (Options, Size(..), checkStrategyOf, clearValue, defaults, deleteOption, handleNodeClick, initialPendingKey, menu, menuVars, mergedCascade, view)

{-| Naive UI's `TreeSelect` — a `NUI.BaseSelection` trigger plus a
caller-mounted tree menu (the `NUI.Select` / `NUI.Cascader` composition
precedent: upstream mounts the menu in its own `VFollower`, so the port
renders the trigger and offers the body separately; show state,
positioning, clickoutside and keyboard are caller-owned runtime).

    import NUI.SelectMenu exposing (Value(..))
    import NUI.TreeSelect as TreeSelect

    TreeSelect.view theme
        { TreeSelect.defaults
            , value = Single (Just "outfield")
            , options = data
            , onUpdateValue = Just Changed
        }

Essential contract: node clicks, tag closes and clears run through the
exported pure helpers (`handleNodeClick`, `deleteOption`, `clearValue`,
`initialPendingKey`) — upstream's unified select / check convergence,
frozen below; mount `menu` in your own positioned wrapper and drive the
`--pending` key through `pendingKey`.

Trigger/panel DOM shapes and porting notes live in the comment block below
the module doc.

@docs Options, Size, checkStrategyOf, clearValue, defaults, deleteOption, handleNodeClick, initialPendingKey, menu, menuVars, mergedCascade, view

-}

{- DOM shapes and porting notes for `NUI.TreeSelect` — moved verbatim out of the
      module docstring (docs.json must stay under elm publish's 768kb limit);
      plain comments do not enter the published API docs.

   Trigger (`view`) DOM — the `.n-tree-select` wrapper is bare (no vars, no
   extra classes; `z-index / outline / width / position` come from the
   stylesheet):

       div.n-tree-select
         └─ NUI.BaseSelection.view (see its docstring for the full tree;
            `view` derives the display state from `value` + `options` — a
            value whose node is MISSING drops entirely, no fallback label)

   Menu (`menu`) DOM — the body carrying the 11 tree-select vars:

       div.n-tree-select-menu [fade-in-scale-up-transition-*]
         tabindex = 0 (upstream hardcodes it)
         style = 11 vars → --n-header-divider-color
         ├─ div.n-tree-select-menu__header [data-header]     — iff header
         ├─ NUI.Tree.view (internalScrollable — see below)   — iff nodes visible
         ├─ div.n-tree-select-menu__empty                    — iff NO visible
         │    > {empty slot | NUI.Empty}                     nodes (replaces the
         ├─ div.n-tree-select-menu__action [data-action]     whole tree — iff action
         └─ div[width:0;height:0][tabindex 0]                — NFocusDetector

   The embedded tree (`NUI.Tree` with `internalScrollable`): the whole
   `.n-tree` root — classes, 18 vars — rides ON the scrollbar's root via
   fallthrough, the content carries `padding:4px` (the theme's `menuPadding`),
   and the node rows wrap in one attribute-less `div`:

       div.n-scrollbar.n-tree.n-tree--block-node.n-tree--block-line
            [.n-tree--checkable iff checkable] [.n-tree--rtl iff rtl]
         style = scrollbar's own 23 vars ; tree's 18 vars (fallthrough last)
         └─ .n-scrollbar-container > .n-scrollbar-content[padding:4px]
            > div > .n-tree-node-wrapper*   (checkboxes inert + not focusable)

   `data-header` / `data-action` serialize `"true"` (upstream's bare JSX
   attrs compile to `{true}` — the `NUI.Transfer` close-icon aria-hidden
   precedent).

   Value algebra — pure helpers (the `NUI.Transfer` derive precedent).
   Upstream passes `internalUnifySelectCheck` UNCONDITIONALLY, so line
   clicks, label clicks and checkbox clicks all converge:

     - `handleNodeClick opts value key` — single: `Single (Just key)` whatever
       was clicked (checkbox included — cancelable is off upstream; a disabled
       or missing node is a no-op). multiple + checkable: flips the node
       through the tree's cascade check / uncheck under the MERGED cascade
       (`multiple && cascade && checkable`) and MERGED strategy
       (`checkStrategyOf` — `leafOnly` folds to `child`), checked-status base
       normalized with the default `All` strategy exactly as upstream's
       `displayedCheckedKeysRef`. multiple + plain: `Tree.toggleSelect` (rows
       toggle in and out — the checkbox renders states only; a wired checkbox
       would double-fire with the row click, the `NUI.Cascader` note).
       A NON-leaf is dead under the merged `child` strategy without the
       cascade multiple mode (`TreeNode.tsx:111-121` under
       `internalTreeSelect` — no `--selectable`, the click never selects);
       leaves and every non-`child` node click through.
     - `deleteOption opts value key` — the tag close: base =
       `Tree.getCheckedKeys` with cascade + allowNotLoaded but NO strategy
       (upstream `TreeSelect.tsx:623-629` — treemate's default `all`); a key
       outside the base is a no-op; checkable runs `Tree.uncheck` under the
       RAW `checkStrategy` (upstream `:643` passes `props.checkStrategy`
       unmerged — the deprecated `leafOnly` folds everywhere EXCEPT this
       delete path, upstream's own inconsistency), plain splices the single
       index.
     - `clearValue value` — `Multiple []` / `Single Nothing`.
     - `initialPendingKey opts` — the `--pending` seed: `Nothing` under
       `checkable`, else the LAST key of an initial list value (a single value
       seeds nothing). The caller feeds it (and every later click — upstream's
       `pendingNodeKeyRef`) through `pendingKey`.

   Caller-owned runtime (the port-wide convention): show state and follower
   positioning (`placement` / `to` / `consistentMenuWidth` — mount `menu` in
   your own positioned wrapper), the `fade-in-scale-up-transition` phases
   (`transition` carries the class), clickoutside + the keyboard ladder
   (Enter / Escape / ArrowDown through the tree), `onLoad` async
   (`loadingKeys` data), `watchProps`, IME, focus return, the filter's
   expand-to-reveal (a non-empty `pattern` fires `onUpdateExpandedKeys` with
   `Tree.filterTree`'s reveal keys upstream — merge them yourself), and
   `clearFilterAfterSelect` (reset `pattern` after a multiple check).

   Not ported: `getChildren` (fixed record fields — the `NUI.Cascader`
   note), `renderTag` + `ellipsisTagPopoverProps` + the responsive
   `maxTagCount` overflow (numeric slicing is the static seam, as in
   `NUI.Select`), `defaultExpandAll` / `defaultExpandedKeys` (seed
   `expandedKeys` — `Tree.getNonLeafKeys` expands everything),
   `overrideDefaultNodeClickBehavior` (behaviour-only), `menuProps`'s raw
   `style` (use `attributes`; the class rides it too),
   `leafOnly` is deprecated (folds into `checkStrategyOf`), `virtualScroll`'s
   windowing (punted like the `--virtual` columns — the port pins the
   `internalScrollable`-branch bytes, upstream's
   `consistentMenuWidth=false` configuration), numeric option keys
   (`String` keys — the `NUI.SelectMenu` limitation).
-}

import Element exposing (Element)
import Element.Events
import Html
import Html.Attributes as HA
import NUI.BaseSelection as BaseSelection
import NUI.Empty
import NUI.Internal as I
import NUI.SelectMenu as SelectMenu
import NUI.Theme exposing (Theme)
import NUI.Theme.TreeSelect as TreeSelectTheme
import NUI.Tree as Tree exposing (TreeOption(..))



-- OPTIONS ----------------------------------------------------------------------


{-| The trigger + menu options. `value` is the single/multiple collapse
(upstream `Value = string | number | Array | null`); keys are `String`s.
-}
type alias Options msg =
    { value : SelectMenu.Value
    , options : List (TreeOption msg)
    , multiple : Bool
    , checkable : Bool
    , cascade : Bool
    , checkStrategy : Tree.CheckStrategy
    , leafOnly : Bool
    , allowCheckingNotLoaded : Bool
    , filterable : Bool
    , filter : Maybe (String -> TreeOption msg -> Bool)
    , pattern : String
    , clearable : Bool
    , showPath : Bool
    , separator : String
    , placeholder : String
    , size : Size
    , status : Maybe BaseSelection.Status
    , bordered : Bool
    , disabled : Bool
    , loading : Bool
    , maxTagCount : Maybe Int
    , showLine : Bool
    , indent : Int
    , expandedKeys : List String
    , pendingKey : Maybe String
    , active : Bool
    , focused : Bool
    , hover : Bool
    , rtl : Bool
    , renderLabel : Maybe ({ checked : Bool, option : TreeOption msg, selected : Bool } -> Element msg)
    , renderPrefix : Maybe ({ checked : Bool, option : TreeOption msg, selected : Bool } -> Element msg)
    , renderSuffix : Maybe ({ checked : Bool, option : TreeOption msg, selected : Bool } -> Element msg)
    , renderSwitcherIcon : Maybe ({ expanded : Bool, option : TreeOption msg, selected : Bool } -> Element msg)
    , nodeProps : Maybe (TreeOption msg -> List (Element.Attribute msg))
    , header : Maybe (Element msg)
    , action : Maybe (Element msg)
    , empty : Maybe (Element msg)
    , arrow : Maybe (Element msg)
    , transition : Maybe I.TransitionPhase
    , onUpdateValue : Maybe (SelectMenu.Value -> msg)
    , onUpdateShow : Maybe (Bool -> msg)
    , onUpdateExpandedKeys : Maybe (List String -> msg)
    , onUpdateIndeterminateKeys : Maybe (List String -> msg)
    , onPatternInput : Maybe (String -> msg)
    , onClear : Maybe msg
    , onDeleteTag : Maybe (String -> msg)
    , onNodeClick : Maybe (String -> msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`checkStrategy: 'all'`, `separator: ' / '`,
`indent: 24`, `placeholder` = the en-US locale `'Please Select'`, single
`null` value; everything else false / empty).
-}
defaults : Options msg
defaults =
    { value = SelectMenu.Single Nothing
    , options = []
    , multiple = False
    , checkable = False
    , cascade = False
    , checkStrategy = Tree.All
    , leafOnly = False
    , allowCheckingNotLoaded = False
    , filterable = False
    , filter = Nothing
    , pattern = ""
    , clearable = False
    , showPath = False
    , separator = " / "
    , placeholder = "Please Select"
    , size = Medium
    , status = Nothing
    , bordered = True
    , disabled = False
    , loading = False
    , maxTagCount = Nothing
    , showLine = False
    , indent = 24
    , expandedKeys = []
    , pendingKey = Nothing
    , active = False
    , focused = False
    , hover = False
    , rtl = False
    , renderLabel = Nothing
    , renderPrefix = Nothing
    , renderSuffix = Nothing
    , renderSwitcherIcon = Nothing
    , nodeProps = Nothing
    , header = Nothing
    , action = Nothing
    , empty = Nothing
    , arrow = Nothing
    , transition = Nothing
    , onUpdateValue = Nothing
    , onUpdateShow = Nothing
    , onUpdateExpandedKeys = Nothing
    , onUpdateIndeterminateKeys = Nothing
    , onPatternInput = Nothing
    , onClear = Nothing
    , onDeleteTag = Nothing
    , onNodeClick = Nothing
    , attributes = []
    }


{-| Upstream `TreeSelectSize` — the three-size scale (no `tiny`), onto the
trigger's.
-}
type Size
    = Small
    | Medium
    | Large


baseSize : Size -> BaseSelection.Size
baseSize size =
    case size of
        Small ->
            BaseSelection.Small

        Medium ->
            BaseSelection.Medium

        Large ->
            BaseSelection.Large



-- VALUE ALGEBRA -----------------------------------------------------------------


{-| The value as a key list — upstream `treeCheckedKeys` (`TreeSelect.tsx`
:304-316): a multiple value IS the list, a single value its only key,
`null` / an array in the wrong mode nothing.
-}
keysOf : SelectMenu.Value -> List String
keysOf value =
    case value of
        SelectMenu.Multiple keys ->
            keys

        SelectMenu.Single (Just key) ->
            [ key ]

        SelectMenu.Single Nothing ->
            []


{-| Upstream `mergedCascade` (:282-284) — cascade only in the
checkable multiple mode (this is what reaches the tree and the algebra,
NOT the raw `cascade` flag).
-}
mergedCascade : Options msg -> Bool
mergedCascade opts =
    opts.multiple && opts.cascade && opts.checkable


{-| Upstream `useMergedCheckStrategy` — the deprecated `leafOnly` is
`check-strategy="child"`.
-}
checkStrategyOf : Options msg -> Tree.CheckStrategy
checkStrategyOf opts =
    if opts.leafOnly then
        Tree.Child

    else
        opts.checkStrategy


{-| The `--pending` seed (upstream `pendingNodeKeyRef` init, :274-281):
nothing under `checkable`, else the LAST key of an initial list value — a
single value seeds nothing.
-}
initialPendingKey : Options msg -> Maybe String
initialPendingKey opts =
    if opts.checkable then
        Nothing

    else
        case opts.value of
            SelectMenu.Multiple keys ->
                List.reverse keys |> List.head

            SelectMenu.Single _ ->
                Nothing


{-| One node click — every mode converges (upstream
`internalUnifySelectCheck` is always on: a checkbox click in single mode
REDIRECTS to select; a row click in checkable multiple mode becomes the
cascade check / uncheck flip). Disabled or missing nodes are no-ops
(`Tree.tsx:1032-1035`; the per-node gate), and so is a non-leaf under the
merged `child` strategy without the cascade multiple mode — upstream's
per-node selectable gate under `internalTreeSelect` (`TreeNode.tsx
:111-121`: the row renders without `--selectable` and `_handleClick`
returns before `handleSelect` — with `expandOnClick` / `checkOnClick` off,
the tree-select default, the click does nothing at all).
-}
handleNodeClick : Options msg -> SelectMenu.Value -> String -> SelectMenu.Value
handleNodeClick opts value key =
    case findOption key opts.options of
        Nothing ->
            value

        Just (TreeOption node) ->
            if node.disabled || not (nodeSelectable opts node.isLeaf) then
                value

            else if not opts.multiple then
                SelectMenu.Single (Just key)

            else if opts.checkable then
                let
                    cascade =
                        mergedCascade opts

                    base =
                        Tree.getCheckedKeys cascade Tree.All opts.allowCheckingNotLoaded (keysOf value) opts.options

                    on =
                        List.member key base.checkedKeys || List.member key base.indeterminateKeys

                    next =
                        (if on then
                            Tree.uncheck

                         else
                            Tree.check
                        )
                            cascade
                            (checkStrategyOf opts)
                            opts.allowCheckingNotLoaded
                            key
                            base.checkedKeys
                            opts.options
                in
                SelectMenu.Multiple next

            else
                SelectMenu.Multiple (Tree.toggleSelect True True key (keysOf value))


{-| The per-node selectable gate upstream evaluates inside the tree under
`internalTreeSelect` (`TreeNode.tsx:111-121`): a node is selectable when
the merged strategy is not `child`, or the tree's `multiple && cascade`
both hold (`multiple` raw; `cascade` is already the merged cascade
upstream passes down), or the node is a leaf. The same predicate drives
the row's `--selectable` / `--clickable` classes in `NUI.Tree`.
-}
nodeSelectable : Options msg -> Bool -> Bool
nodeSelectable opts isLeaf =
    checkStrategyOf opts
        /= Tree.Child
        || (opts.multiple && mergedCascade opts)
        || isLeaf


{-| The tag close (`handleDeleteOption`, :617-661; multiple mode only).
The base normalizes with cascade + `allowCheckingNotLoaded` but NO
check strategy — treemate's default `all` — then the checkable path
unchecks under the RAW `checkStrategy` (upstream `:643` passes
`props.checkStrategy` unmerged — `leafOnly` does NOT fold on the delete
path) while the plain path splices exactly the found index. A key
outside the base leaves the value untouched.
-}
deleteOption : Options msg -> SelectMenu.Value -> String -> SelectMenu.Value
deleteOption opts value key =
    case value of
        SelectMenu.Multiple keys ->
            let
                cascade =
                    mergedCascade opts

                base =
                    Tree.getCheckedKeys cascade Tree.All opts.allowCheckingNotLoaded keys opts.options

                index =
                    elemIndex key base.checkedKeys
            in
            case index of
                Nothing ->
                    value

                Just at ->
                    if opts.checkable then
                        SelectMenu.Multiple
                            (Tree.uncheck
                                cascade
                                opts.checkStrategy
                                opts.allowCheckingNotLoaded
                                key
                                base.checkedKeys
                                opts.options
                            )

                    else
                        SelectMenu.Multiple (removeAt at base.checkedKeys)

        SelectMenu.Single _ ->
            value


{-| The clear button (`handleClear`, :604-616): an empty list in multiple
mode, `null` in single.
-}
clearValue : SelectMenu.Value -> SelectMenu.Value
clearValue value =
    case value of
        SelectMenu.Multiple _ ->
            SelectMenu.Multiple []

        SelectMenu.Single _ ->
            SelectMenu.Single Nothing


elemIndex : String -> List String -> Maybe Int
elemIndex key keys =
    let
        go at rest =
            case rest of
                [] ->
                    Nothing

                head :: tail ->
                    if head == key then
                        Just at

                    else
                        go (at + 1) tail
    in
    go 0 keys


removeAt : Int -> List String -> List String
removeAt at keys =
    List.append (List.take at keys) (List.drop (at + 1) keys)


{-| Document-order node lookup (the whole tree, visible or not).
-}
findOption : String -> List (TreeOption msg) -> Maybe (TreeOption msg)
findOption key options =
    let
        go rest =
            case rest of
                [] ->
                    Nothing

                head :: tail ->
                    if keyOf head == key then
                        Just head

                    else
                        case childrenOf head of
                            Just kids ->
                                case go kids of
                                    Just found ->
                                        Just found

                                    Nothing ->
                                        go tail

                            Nothing ->
                                go tail
    in
    go options


{-| The root-to-node chain (upstream `treeMate.getPath(key).treeNodePath`).
-}
pathTo : String -> List (TreeOption msg) -> List (TreeOption msg)
pathTo key options =
    let
        go rest chain =
            case rest of
                [] ->
                    Nothing

                head :: tail ->
                    if keyOf head == key then
                        Just (List.reverse (head :: chain))

                    else
                        case childrenOf head of
                            Just kids ->
                                case go kids (head :: chain) of
                                    Just found ->
                                        Just found

                                    Nothing ->
                                        go tail chain

                            Nothing ->
                                go tail chain
    in
    Maybe.withDefault [] (go options [])


keyOf : TreeOption msg -> String
keyOf (TreeOption raw) =
    raw.key


labelOf : TreeOption msg -> String
labelOf (TreeOption raw) =
    raw.label


disabledOf : TreeOption msg -> Bool
disabledOf (TreeOption raw) =
    raw.disabled


childrenOf : TreeOption msg -> Maybe (List (TreeOption msg))
childrenOf (TreeOption raw) =
    raw.children



-- VIEW --------------------------------------------------------------------------


{-| The trigger — the bare `.n-tree-select` wrapper over the selection.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.el
        [ I.classes [ "n-tree-select" ] ]
        (BaseSelection.view theme (baseSelectionOptions opts))


{-| The trigger options — the display derivation (`TreeSelect.tsx`
:322-375, the `NUI.Select` `baseSelectionOptions` precedent minus the
fallback: a value whose node misses renders NOTHING): single takes the
node's label (or the `showPath` join), multiple takes the normalized
checked options' tags in order, the numeric `maxTagCount` slices.
-}
baseSelectionOptions : Options msg -> BaseSelection.Options msg
baseSelectionOptions opts =
    let
        selected =
            if opts.multiple then
                not (List.isEmpty (selectedOptions opts))

            else
                selectedOptionOf opts /= Nothing

        ( shownTags, ellipsisTag ) =
            sliceTags opts.maxTagCount (selectedOptions opts)

        d =
            BaseSelection.defaults
    in
    { d
        | size = baseSize opts.size
        , multiple = opts.multiple
        , filterable = opts.filterable
        , active = opts.active
        , focused = opts.focused
        , disabled = opts.disabled
        , bordered = opts.bordered
        , status = opts.status
        , loading = opts.loading
        , showClear =
            opts.clearable
                && not opts.disabled
                && (opts.hover || opts.active)
                && selected
        , showArrow = True
        , placeholder = opts.placeholder
        , pattern = opts.pattern
        , selectedLabel = selectedOptionOf opts
        , tags = shownTags
        , ellipsisTag = ellipsisTag
        , arrow = opts.arrow
        , onClear = opts.onClear
        , onPatternInput = opts.onPatternInput
        , onDeleteTag = opts.onDeleteTag
        , rtl = opts.rtl
    }


{-| The single-mode label — the node's label, or the root-to-node path's
labels joined by the `separator` under `showPath`. `Nothing` when the
value is empty / an array / the node misses.
-}
selectedOptionOf : Options msg -> Maybe String
selectedOptionOf opts =
    case opts.value of
        SelectMenu.Single (Just key) ->
            case findOption key opts.options of
                Nothing ->
                    Nothing

                Just node ->
                    Just (labelFor opts node key)

        _ ->
            Nothing


{-| The multiple-mode tags — upstream `selectedOptionsRef`: the value
normalized through `getCheckedKeys` under the MERGED cascade + the RAW
strategy (:351-355 passes `props.checkStrategy` — `leafOnly` is NOT folded
here, upstream's own inconsistency; the tree's checks use the merged one),
misses DROPPED, order preserved.
-}
selectedOptions : Options msg -> List (BaseSelection.Tag msg)
selectedOptions opts =
    let
        keys =
            Tree.getCheckedKeys
                (mergedCascade opts)
                opts.checkStrategy
                opts.allowCheckingNotLoaded
                (keysOf opts.value)
                opts.options
                |> .checkedKeys
    in
    List.filterMap
        (\key -> findOption key opts.options |> Maybe.map (\node -> tagFor opts node key))
        keys


tagFor : Options msg -> TreeOption msg -> String -> BaseSelection.Tag msg
tagFor opts node key =
    BaseSelection.Tag
        { value = key
        , label = labelFor opts node key
        , disabled = disabledOf node
        }


labelFor : Options msg -> TreeOption msg -> String -> String
labelFor opts node key =
    if opts.showPath then
        pathTo key opts.options
            |> List.map labelOf
            |> String.join opts.separator

    else
        labelOf node


sliceTags : Maybe Int -> List (BaseSelection.Tag msg) -> ( List (BaseSelection.Tag msg), Maybe Int )
sliceTags maxTagCount tags =
    case maxTagCount of
        Just n ->
            let
                count =
                    List.length tags
            in
            if count > n then
                ( List.take n tags, Just (count - n) )

            else
                ( tags, Nothing )

        Nothing ->
            ( tags, Nothing )



-- MENU --------------------------------------------------------------------------


{-| The menu body — `tabindex` 0, the 11 vars, the optional header / tree
/ empty / action children in upstream order, then the inert focus
detector. Mount it in your own follower-positioned wrapper.
-}
menu : Theme -> Options msg -> Element msg
menu theme opts =
    Element.column
        ([ I.classes
            ("n-tree-select-menu"
                :: (case opts.transition of
                        Just phase ->
                            [ I.transitionClass "fade-in-scale-up-transition" phase ]

                        Nothing ->
                            []
                   )
            )
         , Element.htmlAttribute (HA.tabindex 0)
         , I.cssVars (menuVars theme)
         ]
            ++ opts.attributes
        )
        (List.filterMap identity [ headerNode opts, Just (treeBody theme opts), actionNode opts ]
            ++ [ focusDetectorNode ]
        )


{-| The menu's inline `--n-*` set — upstream `cssVarsRef`
(`TreeSelect.tsx:816-845`), 11 vars in declaration order. `menuPadding`
is NOT among them — it feeds the tree's scrollbar content instead.
-}
menuVars : Theme -> List ( String, String )
menuVars theme =
    let
        v =
            TreeSelectTheme.vars theme
    in
    [ ( "--n-menu-box-shadow", v.menuBoxShadow )
    , ( "--n-menu-border-radius", v.menuBorderRadius )
    , ( "--n-menu-color", v.menuColor )
    , ( "--n-menu-height", v.menuHeight )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-action-padding", v.actionPadding )
    , ( "--n-action-text-color", v.actionTextColor )
    , ( "--n-action-divider-color", v.actionDividerColor )
    , ( "--n-header-padding", v.headerPadding )
    , ( "--n-header-text-color", v.headerTextColor )
    , ( "--n-header-divider-color", v.headerDividerColor )
    ]


{-| The header slot — `resolveWrappedSlot` emits nothing when absent.
-}
headerNode : Options msg -> Maybe (Element msg)
headerNode opts =
    Maybe.map
        (\children ->
            Element.el
                [ I.classes [ "n-tree-select-menu__header" ]
                , Element.htmlAttribute (HA.attribute "data-header" "true")
                ]
                children
        )
        opts.header


{-| The action slot — the header's twin at the menu's tail.
-}
actionNode : Options msg -> Maybe (Element msg)
actionNode opts =
    Maybe.map
        (\children ->
            Element.el
                [ I.classes [ "n-tree-select-menu__action" ]
                , Element.htmlAttribute (HA.attribute "data-action" "true")
                ]
                children
        )
        opts.action


{-| The embedded tree — the `internalScrollable` seams wired exactly as
upstream's `NTree` invocation (`TreeSelect.tsx:1020-1095`): `blockLine`,
no irrelevant nodes under a pattern, `cancelable` only in multiple,
checked / selected keys from the value, the MERGED cascade + strategy,
the `internalTreeSelect` host flag (the per-node selectable gate), the
internal flags off (focus / checkbox focusability), `menuPadding` as the
scrollbar content padding, and the whole-render empty override. Row
clicks ride `nodeProps` (the `NUI.Cascader` note: the checkbox renders
states only — a wired checkbox would double-fire with the row).
-}
treeBody : Theme -> Options msg -> Element msg
treeBody theme opts =
    Tree.view theme (treeOptions theme opts)


treeOptions : Theme -> Options msg -> Tree.Options msg
treeOptions theme opts =
    let
        d =
            Tree.defaults

        v =
            TreeSelectTheme.vars theme

        rowProps =
            case ( opts.nodeProps, opts.onNodeClick ) of
                ( Nothing, Nothing ) ->
                    Nothing

                ( Just props, Nothing ) ->
                    Just props

                ( Nothing, Just handler ) ->
                    Just (\option -> [ Element.Events.onClick (handler (keyOf option)) ])

                ( Just props, Just handler ) ->
                    Just
                        (\option ->
                            props option
                                ++ [ Element.Events.onClick (handler (keyOf option)) ]
                        )
    in
    { d
        | data = opts.options
        , expandedKeys = opts.expandedKeys
        , checkedKeys = keysOf opts.value
        , selectedKeys =
            if opts.checkable then
                []

            else
                keysOf opts.value
        , pendingKey = opts.pendingKey
        , pattern = opts.pattern
        , filter = opts.filter
        , showIrrelevantNodes = False
        , checkable = opts.checkable
        , checkStrategy = checkStrategyOf opts
        , cascade = mergedCascade opts
        , allowCheckingNotLoaded = opts.allowCheckingNotLoaded
        , selectable = True
        , multiple = opts.multiple
        , cancelable = opts.multiple
        , blockLine = True
        , showLine = opts.showLine
        , indent = opts.indent
        , rtl = opts.rtl
        , renderLabel = opts.renderLabel
        , renderPrefix = opts.renderPrefix
        , renderSuffix = opts.renderSuffix
        , renderSwitcherIcon = opts.renderSwitcherIcon
        , nodeProps = rowProps
        , renderEmpty = Just (menuEmptyNode theme opts)
        , internalTreeSelect = True
        , internalScrollable = True
        , internalScrollablePadding = Just v.menuPadding
        , internalFocusable = False
        , internalCheckboxFocusable = False
    }


{-| The filtered-empty body — replaces the WHOLE tree (upstream
`internalRenderEmpty` returns from Tree's render outright): the
`__empty` wrapper over the caller's slot or the plain `NUI.Empty` (no
`n-tree__empty` class — that belongs to the standalone tree's own empty).
-}
menuEmptyNode : Theme -> Options msg -> Element msg
menuEmptyNode theme opts =
    Element.el
        [ I.classes [ "n-tree-select-menu__empty" ] ]
        (case opts.empty of
            Just children ->
                children

            Nothing ->
                NUI.Empty.view theme NUI.Empty.defaults []
        )


{-| NFocusDetector's inert sentinel (`width:0;height:0`, `tabindex=0`, no
classes), always the menu's last child (the `NUI.Cascader` bytes).
-}
focusDetectorNode : Element msg
focusDetectorNode =
    Element.html
        (Html.div
            [ HA.attribute "style" "width:0;height:0"
            , HA.tabindex 0
            ]
            []
        )
