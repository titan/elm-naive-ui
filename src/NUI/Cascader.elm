module NUI.Cascader exposing
    ( CheckStrategy(..)
    , ExpandTrigger(..)
    , MenuOptions
    , Option(..)
    , Options
    , SelectMenuOptions
    , Size(..)
    , Status
    , check
    , defaults
    , filterOptions
    , getCheckedKeys
    , menu
    , menuDefaults
    , menuVars
    , selectMenu
    , selectMenuDefaults
    , selectMenuVars
    , toggleValue
    , uncheck
    , valueKeys
    , view
    )

{-| Naive UI's `Cascader` — a thin composition over `NUI.BaseSelection` (the
trigger, the `NUI.Select` lane) plus the multi-column menu body, exactly
upstream's split (`Cascader.tsx` mounts the trigger in a `VTarget` and the
menu in its own `VFollower`; the filterable flat menu rides a second
follower — here both bodies are separate caller-mounted views).

    import Cascader exposing (Option(..), defaults)

    Cascader.view theme
        { defaults | multiple = True }
        [ Option
            { value = "drive"
            , label = "Drive"
            , disabled = False
            , children =
                Just
                    [ Option
                        { value = "car"
                        , label = "Car"
                        , disabled = False
                        , children = Nothing
                        }
                    ]
            }
        ]

(Record updates bind `defaults` to a local first — see `NUI.Button`.) The
value flows out through the menus' `onToggle`, not a trigger field.

Trigger (`view`) DOM — the `.n-cascader` wrapper is bare (no vars, no extra
classes; `position:relative; width:100%` come from the stylesheet):

    div.n-cascader
      └─ NUI.BaseSelection.view (see its docstring for the full tree;
         `view` derives the display state from `value` + the option tree
         per the module docs — path labels, fallback keys, tag slicing)

Menu (`menu`) DOM — the columns body, carrying the 17 cascader vars:

    div.n-cascader-menu [fade-in-scale-up-transition-*]
      tabindex = 0 (upstream hardcodes it)
      style = 17 vars → --n-menu-mask-color
      ├─ div.n-cascader-submenu-wrapper                       — iff column 0 non-empty
      │    ├─ div.n-cascader-submenu [--virtual]              — per column
      │    │    style = getColumnStyle level (iff columnStyle)
      │    │    └─ NUI.Scrollbar
      │    │        └─ div.n-cascader-option [--pending] [--disabled]
      │    │                       [--show-prefix]             — per option
      │    │            ├─ div.n-cascader-option__prefix      — iff showCheckbox
      │    │            │    > NCheckbox{checked, indeterminate, disabled,
      │    │            │        focusable=false}             — inert (below)
      │    │            ├─ span.n-cascader-option__label {label}
      │    │            └─ div.n-cascader-option__suffix
      │    │                 > div.n-cascader-option-icon-placeholder
      │    │                     > branch: NBaseLoading(scale .85, strokeWidth 24,
      │    │                       show=isLoading) > arrow | placeholder
      │    │                       > leaf: checkmark iff checkStrategy = Child
      │    │                         && !(multiple && cascade) — with the
      │    │                         fade-in-scale-up phase class
      │    └─ div.n-base-menu-mask {mask}                     — iff mask
      ├─ div.n-cascader-menu__empty {empty | NUI.Empty}      — iff column 0 empty
      ├─ div.n-cascader-menu-action [data-action]            — iff action
      └─ div[width:0;height:0][tabindex 0]                   — NFocusDetector, inert

Select menu (`selectMenu`) DOM — the filterable flat body (`showSelectMenu`
upstream = `filterable && pattern /= ""`; the caller mounts this instead of
`menu`): the `NUI.SelectMenu` root carrying `extraClasses =
["n-cascader", …]`… exactly `["n-cascader-menu", transition?]`, the merged
`selectMenuVars` (23 + 17, last-wins superset — the `NUI.Select.menu`
precedent) and `focusable = False` (upstream passes no `focusable`).

Caller-owned runtime (the port-wide convention): show state and follower
positioning (mount the body in your own positioned wrapper), the
`fade-in-scale-up-transition` phases, keyboard navigation (`keyboardKey`)
and hover expansion (`hoverKey` — its path is what paints `--pending`),
`pattern` + `onPatternInput` (filtering runs through `filterOptions`),
`remote`/`onLoad` orchestration (`loadingKeys` paints the per-option
spinners; the option tree itself is the loaded state, so treemate's
`SubtreeNotLoadedError` and `allowCheckingNotLoaded` are moot), the mask's
`showOnce` timing (render `mask` while the message shows; its
`fade-in-transition` classes are not driven), `autoPending` and the select
menu's keyboard `prev`/`next`/`enter` (inject `--pending` through the flat
rows' `attributes` — the `NUI.SelectMenu` seam), the responsive
`maxTagCount` overflow and its preview popover (numeric is the static seam
here, as in `NUI.Select`), `ellipsisTagPopoverProps`, form-item
size/disabled/status merging, IME, `onFocus`/`onBlur`/`onTabout`, column
scrolling, `virtualScroll`'s windowing (`virtual` only adds the
`--virtual` width class; the full column renders).

Not ported: `renderLabel` / `renderPrefix` / `renderSuffix` / `arrow`-
adjacent custom render slots beyond `arrow` itself; `leafOnly` /
`onChange` (deprecated upstream); `valueField` / `labelField` /
`childrenField` / `disabledField` (fixed record names — the
`NUI.SelectMenu` limitation); a custom `filter` (pass pre-built flat rows
to `selectMenu` instead of `filterOptions`' output); treemate group /
ignored nodes. The checkbox renders states only: Elm has no
`stopPropagation` hook (the `NUI.Tabs` note), so a wired checkbox would
double-fire with the row's own `onToggle` — branch checks arrive through
the row click instead. `Cascader.Size` is upstream's three-size scale (no
`tiny`); the menu carries no size variant (heights flow through the vars),
and neither body has an `rtl.cssr` upstream (the trigger's `rtl` rides
`NUI.BaseSelection`).

-}

import Element exposing (Element)
import Element.Events
import Html
import Html.Attributes as HA
import NUI.BaseSelection as BaseSelection
import NUI.Checkbox
import NUI.Empty
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Scrollbar
import NUI.SelectMenu as SelectMenu
import NUI.Theme exposing (Theme)
import NUI.Theme.Cascader as CascaderTheme
import NUI.Theme.Color
import Svg



-- TYPES ------------------------------------------------------------------------


{-| Upstream `CascaderSize` — `'small' | 'medium' | 'large'` (no `tiny`);
keys the trigger only (the menus take their heights from the vars).
-}
type Size
    = Small
    | Medium
    | Large


{-| Upstream `FormValidationStatus` — re-bound to `NUI.BaseSelection.Status`.
-}
type alias Status =
    BaseSelection.Status


{-| Upstream `CheckStrategy` — `'all' | 'parent' | 'child'`: which tree
levels a multiple-mode value keys (and the trigger tags) keep once the
cascade normalization collapses descendants into ancestors.
-}
type CheckStrategy
    = All
    | Parent
    | Child


{-| Upstream `ExpandTrigger` — `'click' | 'hover'`: what opens the next
column. Only `Hover` wires the option rows' `mouseenter` / `mousemove`
(upstream skips both when `remote`, which the port cannot see — wire
nothing yourself under a remote tree).
-}
type ExpandTrigger
    = Click
    | Hover


{-| One option node — upstream's raw `CascaderOption`, wrapped because a
recursive record cannot be a type alias. `children = Nothing` is
upstream's absent `children` field (a leaf); `Just []` is a loaded-but-
empty branch, which upstream counts as a non-leaf that opens an empty
column (an empty array is truthy in treemate's `isLeaf`).
-}
type Option
    = Option
        { value : String
        , label : String
        , disabled : Bool
        , children : Maybe (List Option)
        }


{-| The trigger options. Runtime behaviour (show state, hover, focus,
filtering orchestration) is caller-owned.
-}
type alias Options msg =
    { size : Size
    , multiple : Bool
    , filterable : Bool
    , value : SelectMenu.Value
    , placeholder : String
    , clearable : Bool
    , hover : Bool
    , active : Bool
    , focused : Bool
    , disabled : Bool
    , bordered : Bool
    , status : Maybe Status
    , showPath : Bool
    , separator : String
    , cascade : Bool
    , checkStrategy : CheckStrategy
    , maxTagCount : Maybe Int
    , pattern : String
    , arrow : Maybe (Element msg)
    , onClear : Maybe msg
    , onPatternInput : Maybe (String -> msg)
    , onDeleteTag : Maybe (String -> msg)
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`size: 'medium'` via the form/config merge,
`showPath` / `cascade` on, `checkStrategy: 'all'`, `separator: ' / '`,
placeholder = the en-US locale `'Please Select'`, `value = Single Nothing`
= null, `bordered` on via the config default; everything else `False` /
empty — upstream declares those booleans `undefined` (inert, only
truthy-checked) rather than `false`, which `False` matches).
-}
defaults : Options msg
defaults =
    { size = Medium
    , multiple = False
    , filterable = False
    , value = SelectMenu.Single Nothing
    , placeholder = "Please Select"
    , clearable = False
    , hover = False
    , active = False
    , focused = False
    , disabled = False
    , bordered = True
    , status = Nothing
    , showPath = True
    , separator = " / "
    , cascade = True
    , checkStrategy = All
    , maxTagCount = Nothing
    , pattern = ""
    , arrow = Nothing
    , onClear = Nothing
    , onPatternInput = Nothing
    , onDeleteTag = Nothing
    , rtl = False
    , attributes = []
    }


{-| The columns-menu options. Runtime behaviour (show state, keyboard,
hover key, remote loading) is caller-owned.
-}
type alias MenuOptions msg =
    { hoverKey : Maybe String
    , keyboardKey : Maybe String
    , loadingKeys : List String
    , virtual : Bool
    , multiple : Bool
    , value : SelectMenu.Value
    , cascade : Bool
    , checkStrategy : CheckStrategy
    , expandTrigger : ExpandTrigger
    , columnStyle : Maybe (Int -> String)
    , mask : Maybe String
    , checkmarkTransition : Maybe I.TransitionPhase
    , transition : Maybe I.TransitionPhase
    , spinStrokeWidth : Maybe Float
    , spinStroke : Maybe String
    , spinScale : Maybe Float
    , spinRadius : Maybe Float
    , action : Maybe (Element msg)
    , empty : Maybe (Element msg)
    , onToggle : Maybe (String -> msg)
    , onHover : Maybe (String -> msg)
    , attributes : List (Element.Attribute msg)
    }


{-| The columns-menu defaults (`virtual` on = upstream's `virtualScroll:
true`, `expandTrigger: 'click'`; everything else false / empty).
-}
menuDefaults : MenuOptions msg
menuDefaults =
    { hoverKey = Nothing
    , keyboardKey = Nothing
    , loadingKeys = []
    , virtual = True
    , multiple = False
    , value = SelectMenu.Single Nothing
    , cascade = True
    , checkStrategy = All
    , expandTrigger = Click
    , columnStyle = Nothing
    , mask = Nothing
    , checkmarkTransition = Nothing
    , transition = Nothing
    , spinStrokeWidth = Nothing
    , spinStroke = Nothing
    , spinScale = Nothing
    , spinRadius = Nothing
    , action = Nothing
    , empty = Nothing
    , onToggle = Nothing
    , onHover = Nothing
    , attributes = []
    }


{-| The filterable flat-menu options. The rows arrive pre-filtered (the
default pipeline is `filterOptions`); runtime behaviour (pending,
keyboard) is caller-owned.
-}
type alias SelectMenuOptions msg =
    { multiple : Bool
    , value : SelectMenu.Value
    , transition : Maybe I.TransitionPhase
    , empty : Maybe (Element msg)
    , onToggle : Maybe (String -> msg)
    , scrollbarProps : Maybe (NUI.Scrollbar.Options msg -> NUI.Scrollbar.Options msg)
    , attributes : List (Element.Attribute msg)
    }


{-| The flat-menu defaults (`value = Single Nothing` = null; everything
else false / empty).
-}
selectMenuDefaults : SelectMenuOptions msg
selectMenuDefaults =
    { multiple = False
    , value = SelectMenu.Single Nothing
    , transition = Nothing
    , empty = Nothing
    , onToggle = Nothing
    , scrollbarProps = Nothing
    , attributes = []
    }



-- PURE LOGIC -------------------------------------------------------------------


{-| treemate's checked-state result — the normalized checked keys plus the
cascade's partially-checked parents.
-}
type alias CheckResult =
    { checkedKeys : List String
    , indeterminateKeys : List String
    }


{-| treemate's `getCheckedKeys` — normalize raw keys against the tree. With
`cascade`, each key extends to its whole enabled subtree and the parents
aggregate bottom-up (`indeterminateKeys` collects the partial ones);
`checkStrategy` then collapses the result (`All` keeps every level,
`Parent` the topmost checked ancestor, `Child` leaf levels only — exactly
treemate's synthetic-set walk). Without `cascade` the keys pass through
`merge` / `minus` semantics and nothing is indeterminate.
-}
getCheckedKeys : Bool -> CheckStrategy -> List String -> List Option -> CheckResult
getCheckedKeys cascade strategy keys options =
    normalize cascade strategy NoToggle keys (index options)


{-| Upstream `doCheck`'s multiple branch — treemate's `check`: the key's
subtree joins the checked set, then the strategy normalization runs. The
result list IS the new value (upstream writes it straight through
`doUpdateValue`).
-}
check : Bool -> CheckStrategy -> String -> List String -> List Option -> List String
check cascade strategy key current options =
    .checkedKeys (normalize cascade strategy (ToCheck key) current (index options))


{-| Upstream `doUncheck` — treemate's `uncheck`: the key's extended subtree
and its available (non-disabled) ancestors leave the checked set.
-}
uncheck : Bool -> CheckStrategy -> String -> List String -> List Option -> List String
uncheck cascade strategy key current options =
    .checkedKeys (normalize cascade strategy (ToUncheck key) current (index options))


{-| The row-activation toggle both menus funnel into: multiple mode flips
the key's membership in the RAW value (upstream `CascaderSelectMenu`'s
`doCheck`; the columns rows' `checked || indeterminate` gate converges — a
normalized-in key re-checks to itself); single mode is upstream `doCheck`
— always the key, except `Child` demands a leaf (an unknown key or a
branch returns the current value unchanged, upstream's `false`).
-}
toggleValue : Bool -> CheckStrategy -> SelectMenu.Value -> String -> List Option -> SelectMenu.Value
toggleValue cascade strategy current key options =
    case current of
        SelectMenu.Multiple keys ->
            if List.member key keys then
                SelectMenu.Multiple (uncheck cascade strategy key keys options)

            else
                SelectMenu.Multiple (check cascade strategy key keys options)

        SelectMenu.Single _ ->
            if strategy == Child && not (isLeafKey key options) then
                current

            else
                SelectMenu.Single (Just key)


{-| The multiple-mode keys of a value — upstream feeds `mergedValueRef` (an
array) to `getCheckedKeys`; a single-mode value contributes none.
-}
valueKeys : SelectMenu.Value -> List String
valueKeys value =
    case value of
        SelectMenu.Multiple keys ->
            keys

        SelectMenu.Single _ ->
            []



-- TREE INDEX -------------------------------------------------------------------


{-| treemate's built index: one entry per node in document order, each
carrying its column (the sibling list it renders in), its root-first
ancestor chain and its level — `treeNodes` / `treeNodeMap` /
`levelTreeNodeMap` fused.
-}
type alias Node =
    { option : Option
    , column : List Option
    , ancestors : List Option
    , level : Int
    }


index : List Option -> List Node
index options =
    indexColumn 0 [] options


indexColumn : Int -> List Option -> List Option -> List Node
indexColumn level ancestors column =
    List.concatMap
        (\option ->
            Node option column ancestors level
                :: (case childrenOf option of
                        Just children ->
                            indexColumn (level + 1) (ancestors ++ [ option ]) children

                        Nothing ->
                            []
                   )
        )
        column


{-| treemate's `getNode` — first node whose key matches, document order
(duplicate keys are invalid data upstream; its map would keep the last).
-}
find : String -> List Node -> Maybe Node
find key nodes =
    List.head (List.filter (\n -> valueOf n.option == key) nodes)


{-| The record inside the `Option` wrapper.
-}
fields : Option -> { value : String, label : String, disabled : Bool, children : Maybe (List Option) }
fields (Option raw) =
    raw


valueOf : Option -> String
valueOf option =
    .value (fields option)


labelOf : Option -> String
labelOf option =
    .label (fields option)


disabledOf : Option -> Bool
disabledOf option =
    .disabled (fields option)


childrenOf : Option -> Maybe (List Option)
childrenOf option =
    .children (fields option)


{-| treemate's `isLeaf` — the `children` field decides: absent is a leaf,
an empty-but-present list is a loaded empty branch (a truthy array).
-}
isLeaf : Option -> Bool
isLeaf option =
    childrenOf option == Nothing


isLeafKey : String -> List Option -> Bool
isLeafKey key options =
    case find key (index options) of
        Just node ->
            isLeaf node.option

        Nothing ->
            False


{-| treemate's `getPath` — the root-first node chain to the key, self
included.
-}
findPath : String -> List Option -> Maybe (List Option)
findPath key column =
    case column of
        [] ->
            Nothing

        option :: rest ->
            if valueOf option == key then
                Just [ option ]

            else
                case findPath key (Maybe.withDefault [] (childrenOf option)) of
                    Just subPath ->
                        Just (option :: subPath)

                    Nothing ->
                        findPath key rest


{-| The hover key's path labels — upstream's `getPathLabel`: root-first
labels joined by the separator.
-}
pathLabel : String -> List Option -> String
pathLabel separator path =
    String.join separator (List.map labelOf path)


{-| Upstream `menuModelRef` — the open columns: with no hover key just the
root column; with one, the column of every path node plus the hovered
node's children when it is a loaded non-leaf that is not currently loading
(`Just []` opens an empty column, upstream's truthy-children check).
-}
menuModel : Maybe String -> List String -> List Option -> List (List Option)
menuModel hoverKey loadingKeys options =
    case hoverKey of
        Nothing ->
            [ options ]

        Just key ->
            case findPath key options of
                Nothing ->
                    [ options ]

                Just path ->
                    let
                        columns =
                            options :: List.filterMap childrenOf (init path)
                    in
                    columns
                        ++ (case last path of
                                Just node ->
                                    if not (isLeaf node) && not (List.member key loadingKeys) then
                                        Maybe.withDefault [] (childrenOf node) |> List.singleton

                                    else
                                        []

                                Nothing ->
                                    []
                           )


init : List a -> List a
init list =
    List.take (List.length list - 1) list


last : List a -> Maybe a
last list =
    List.head (List.drop (List.length list - 1) list)


{-| The hover key's `keyPath` — the keys of the path, self included; every
option row on it paints `--pending` (upstream `hoverKeyPathRef`).
-}
hoverKeyPath : Maybe String -> List Option -> List String
hoverKeyPath hoverKey options =
    case hoverKey of
        Nothing ->
            []

        Just key ->
            case findPath key options of
                Just path ->
                    List.map valueOf path

                Nothing ->
                    []



-- CASCADE NORMALIZATION ---------------------------------------------------------


{-| The treemate toggle a normalization run starts from.
-}
type Toggle
    = NoToggle
    | ToCheck String
    | ToUncheck String


normalize : Bool -> CheckStrategy -> Toggle -> List String -> List Node -> CheckResult
normalize cascade strategy toggle keys nodes =
    if not cascade then
        { checkedKeys =
            case toggle of
                ToCheck key ->
                    dedupe (keys ++ [ key ])

                ToUncheck key ->
                    dedupe (List.filter ((/=) key) keys)

                NoToggle ->
                    keys
        , indeterminateKeys = []
        }

    else
        let
            extended =
                case toggle of
                    ToCheck key ->
                        extendCheckedKeySet (keys ++ [ key ]) nodes

                    ToUncheck key ->
                        afterUncheck key keys nodes

                    NoToggle ->
                        extendCheckedKeySet keys nodes
        in
        cascadeWalk (levelsDesc nodes) extended [] strategy


{-| treemate's `getExtendedCheckedKeySet` — each checked key's enabled
subtree joins the set (a disabled node blocks its own key and its
subtree); raw keys missing from the tree stay put.
-}
extendCheckedKeySet : List String -> List Node -> List String
extendCheckedKeySet keys nodes =
    Tuple.second
        (List.foldl
            (\key ( visited, extended ) ->
                case find key nodes of
                    Just node ->
                        visit node ( visited, extended ) nodes

                    Nothing ->
                        ( visited, extended )
            )
            ( [], dedupe keys )
            (dedupe keys)
        )


visit : Node -> ( List String, List String ) -> List Node -> ( List String, List String )
visit node ( visited, extended ) nodes =
    if disabledOf node.option then
        ( visited, extended )

    else
        let
            key =
                valueOf node.option

            state =
                if List.member key visited then
                    ( visited, extended )

                else
                    ( key :: visited, addIfAbsent key extended )
        in
        List.foldl
            (\child st ->
                case find (valueOf child) nodes of
                    Just childNode ->
                        visit childNode st nodes

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
afterUncheck : String -> List String -> List Node -> List String
afterUncheck key current nodes =
    let
        extended =
            extendCheckedKeySet current nodes

        toUncheck =
            extendCheckedKeySet [ key ] nodes

        ascendants =
            availableAscendants [ key ] nodes
    in
    List.filter (\k -> not (List.member k toUncheck) && not (List.member k ascendants)) extended


availableAscendants : List String -> List Node -> List String
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


ascend : List Option -> List String -> List String
ascend nearestFirst visited =
    case nearestFirst of
        [] ->
            visited

        ancestor :: rest ->
            if disabledOf ancestor then
                visited

            else if List.member (valueOf ancestor) visited then
                visited

            else
                ascend rest (valueOf ancestor :: visited)


{-| The nodes grouped by level, deepest first (treemate's `levelTreeNodeMap`
walked `maxLevel` → 0; the intra-level order is document order, which the
set arithmetic does not depend on).
-}
levelsDesc : List Node -> List ( Int, List Node )
levelsDesc nodes =
    groupLevels nodes []
        |> List.sortBy Tuple.first
        |> List.reverse


groupLevels : List Node -> List ( Int, List Node ) -> List ( Int, List Node )
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
cascadeWalk : List ( Int, List Node ) -> List String -> List String -> CheckStrategy -> CheckResult
cascadeWalk groups checked indeterminate strategy =
    case groups of
        [] ->
            { checkedKeys = checked, indeterminateKeys = indeterminate }

        ( level, nodes ) :: rest ->
            let
                ( checked1, indeterminate1 ) =
                    List.foldl
                        (\node state -> cascadeNode level node state strategy)
                        ( checked, indeterminate )
                        nodes
            in
            cascadeWalk rest checked1 indeterminate1 strategy


cascadeNode : Int -> Node -> ( List String, List String ) -> CheckStrategy -> ( List String, List String )
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
                        (\k -> not (List.any (\c -> not (disabledOf c) && not (isLeaf c) && valueOf c == k) children))
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
                    valueOf node.option

                ( checked2, indeterminate2 ) =
                    if fullyChecked && not allDisabled then
                        ( addIfAbsent key
                            (if strategy == Parent then
                                List.filter (\k -> not (List.any (\c -> not (disabledOf c) && valueOf c == k) children)) checkedAfterChildStrategy

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


{-| treemate's per-parent scan over its children (disabled ones skipped):
a checked child marks partial, an indeterminate or unchecked one clears
full — and either break ends the scan (the checked branch never clears
full, upstream's quirk).
-}
scanChildren : List Option -> List String -> List String -> ( Bool, Bool, Bool ) -> ( Bool, Bool, Bool )
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
                        valueOf child
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



-- VIEW -------------------------------------------------------------------------


{-| The `.n-cascader` wrapper + the `NUI.BaseSelection` trigger, with the
display state derived from `value` + the option tree per the module
docstring (single: the path label, the raw label under `showPath = False`,
or the unknown key as its own label; multiple: the strategy-normalized
tags with the same fallback).
-}
view : Theme -> Options msg -> List Option -> Element msg
view theme opts options =
    Element.el
        ([ I.classes [ "n-cascader" ] ] ++ opts.attributes)
        (BaseSelection.view theme (baseSelectionOptions opts options))


{-| The trigger's options derived per the module docstring: upstream
`selectedOptionRef` / `selectedOptionsRef` — the multiple tags come from
the value's `All`-normalized keys re-normalized under `checkStrategy`
(upstream `mergedKeysRef` → `selectedOptionsRef`), each falling back to
the bare key; the numeric `maxTagCount` slice and the clear gate (hover is
the one truly-runtime input) — everything else passes straight through
(the wrapper keeps `attributes`; `BaseSelection` gets none of its own).
-}
baseSelectionOptions : Options msg -> List Option -> BaseSelection.Options msg
baseSelectionOptions opts options =
    let
        selectedLabel =
            case opts.value of
                SelectMenu.Single (Just value) ->
                    case findPath value options of
                        Just path ->
                            Just
                                (if opts.showPath then
                                    pathLabel opts.separator path

                                 else
                                    Maybe.withDefault value (Maybe.map labelOf (last path))
                                )

                        Nothing ->
                            Just value

                _ ->
                    Nothing

        tags =
            getCheckedKeys opts.cascade All (valueKeys opts.value) options
                |> .checkedKeys
                |> (\keys -> .checkedKeys (getCheckedKeys opts.cascade opts.checkStrategy keys options))
                |> List.map (tagFor opts options)

        ( shownTags, ellipsisTag ) =
            sliceTags opts.maxTagCount tags

        selected =
            if opts.multiple then
                not (List.isEmpty tags)

            else
                selectedLabel /= Nothing

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
        , showClear =
            opts.clearable
                && not opts.disabled
                && (opts.hover || opts.active)
                && selected
        , placeholder = opts.placeholder
        , pattern = opts.pattern
        , selectedLabel = selectedLabel
        , tags = shownTags
        , ellipsisTag = ellipsisTag
        , arrow = opts.arrow
        , onClear = opts.onClear
        , onPatternInput = opts.onPatternInput
        , onDeleteTag = opts.onDeleteTag
        , rtl = opts.rtl
    }


{-| One multiple-mode tag — upstream's `{ label, value }` objects: the
node's path label (its raw label under `showPath = False`), or the bare
key when the tree does not carry it; never disabled (upstream builds the
objects fresh, so tags stay closable).
-}
tagFor : Options msg -> List Option -> String -> BaseSelection.Tag msg
tagFor opts options key =
    let
        label =
            case findPath key options of
                Just path ->
                    if opts.showPath then
                        pathLabel opts.separator path

                    else
                        Maybe.withDefault key (Maybe.map labelOf (last path))

                Nothing ->
                    key
    in
    BaseSelection.Tag { value = key, label = label, disabled = False }


{-| Upstream's numeric `maxTagCount` (the selection trigger's own slice) —
keep the first `n` tags and report the rest as the `+N` ellipsis tag;
`'responsive'` overflow is caller-owned (the module docstring).
-}
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


{-| `Cascader.Size` onto the trigger's — the same three constructors, two
distinct unions (the selection trigger keeps its own `Tiny`).
-}
baseSize : Size -> BaseSelection.Size
baseSize size =
    case size of
        Small ->
            BaseSelection.Small

        Medium ->
            BaseSelection.Medium

        Large ->
            BaseSelection.Large



-- MENU -------------------------------------------------------------------------


{-| The columns body — `menuModel` decides the open columns from the hover
key; the root is the `NFocusDetector`'s host (upstream hardcodes
`tabindex 0`; focus / keydown / mousedown wiring is caller-owned through
`attributes`).
-}
menu : Theme -> MenuOptions msg -> List Option -> Element msg
menu theme mopts options =
    let
        columns =
            menuModel mopts.hoverKey mopts.loadingKeys options

        state =
            let
                checked =
                    getCheckedKeys mopts.cascade All (valueKeys mopts.value) options
            in
            { checkedKeys = checked.checkedKeys
            , indeterminateKeys = checked.indeterminateKeys
            , hoverKeys = hoverKeyPath mopts.hoverKey options
            }

        body =
            case columns of
                first :: _ ->
                    if List.isEmpty first then
                        emptyNode theme mopts

                    else
                        submenuWrapperNode theme mopts options state columns

                [] ->
                    emptyNode theme mopts
    in
    Element.column
        ([ I.classes
            ("n-cascader-menu"
                :: (case mopts.transition of
                        Just phase ->
                            [ I.transitionClass "fade-in-scale-up-transition" phase ]

                        Nothing ->
                            []
                   )
            )
         , Element.htmlAttribute (HA.tabindex 0)
         , I.cssVars (menuVars theme)
         ]
            ++ mopts.attributes
        )
        ([ body ]
            ++ (case mopts.action of
                    Just action ->
                        [ actionNode action ]

                    Nothing ->
                        []
               )
            ++ [ focusDetectorNode ]
        )


{-| The per-menu row derivations, computed once: the `All`-strategy
normalization (upstream `mergedKeysRef` — the option states never see
`checkStrategy`) and the hover key's path keys.
-}
type alias RowState =
    { checkedKeys : List String
    , indeterminateKeys : List String
    , hoverKeys : List String
    }


{-| `div.n-cascader-submenu-wrapper` — the open columns plus the remote
error mask; every column renders behind its own `NUI.Scrollbar`.
-}
submenuWrapperNode : Theme -> MenuOptions msg -> List Option -> RowState -> List (List Option) -> Element msg
submenuWrapperNode theme mopts options state columns =
    Element.row
        [ I.classes [ "n-cascader-submenu-wrapper" ] ]
        (List.indexedMap (submenuNode theme mopts options state) columns
            ++ (case mopts.mask of
                    Just message ->
                        [ Element.el
                            [ I.classes [ "n-base-menu-mask" ] ]
                            (Element.text message)
                        ]

                    Nothing ->
                        []
               )
        )


{-| One column — `n-cascader-submenu` with the `--virtual` width class and
the caller's per-level `getColumnStyle` as a raw style string (upstream
merges the returned style onto the div).
-}
submenuNode : Theme -> MenuOptions msg -> List Option -> RowState -> Int -> List Option -> Element msg
submenuNode theme mopts options state level column =
    let
        scrollbarDefaults =
            NUI.Scrollbar.defaults
    in
    Element.el
        ([ I.classes
            (I.classIf mopts.virtual "n-cascader-submenu--virtual"
                ++ [ "n-cascader-submenu" ]
            )
         ]
            ++ (case mopts.columnStyle of
                    Just style ->
                        [ Element.htmlAttribute (HA.attribute "style" (style level)) ]

                    Nothing ->
                        []
               )
        )
        (NUI.Scrollbar.view theme
            scrollbarDefaults
            (List.map (optionNode theme mopts state) column)
        )


{-| One option row — the `--pending` breadcrumb (the keyboard key or the
hover path), `--disabled`, and `--show-prefix` under `showCheckbox`
(upstream's `--selected` / `--active` classes exist in the cssr but are
never emitted by `CascaderOption`). The click fires `onToggle` for every
enabled option (leaf toggles, branch expands — upstream `handleClick`
does both through one handler); `Hover` expansion wires `mouseenter` /
`mousemove` (upstream skips them under `remote`, which the port cannot
see).
-}
optionNode : Theme -> MenuOptions msg -> RowState -> Option -> Element msg
optionNode theme mopts state option =
    let
        key =
            valueOf option

        checked =
            if mopts.multiple then
                List.member key state.checkedKeys

            else
                case mopts.value of
                    SelectMenu.Single (Just value) ->
                        value == key

                    _ ->
                        False

        indeterminate =
            mopts.multiple && List.member key state.indeterminateKeys

        pending =
            mopts.keyboardKey
                == Just key
                || List.member key state.hoverKeys

        disabled =
            disabledOf option

        showCheckbox =
            (mopts.multiple && mopts.cascade) || mopts.checkStrategy /= Child

        clickAttrs =
            case ( mopts.onToggle, disabled ) of
                ( Just toggle, False ) ->
                    [ Element.Events.onClick (toggle key) ]

                _ ->
                    []

        hoverAttrs =
            case ( mopts.expandTrigger, mopts.onHover, disabled ) of
                ( Hover, Just onHover, False ) ->
                    [ Element.Events.onMouseEnter (onHover key)
                    , Element.Events.onMouseMove (onHover key)
                    ]

                _ ->
                    []

        prefix =
            if showCheckbox then
                [ prefixNode theme mopts option checked indeterminate disabled ]

            else
                []

        suffix =
            suffixNode mopts option checked
    in
    Element.row
        ([ I.classes
            ([ "n-cascader-option" ]
                ++ I.classIf pending "n-cascader-option--pending"
                ++ I.classIf disabled "n-cascader-option--disabled"
                ++ I.classIf showCheckbox "n-cascader-option--show-prefix"
            )
         ]
            ++ clickAttrs
            ++ hoverAttrs
        )
        (prefix
            ++ [ Element.el [ I.classes [ "n-cascader-option__label" ] ] (Element.text (labelOf option)) ]
            ++ [ suffix ]
        )


{-| The checkbox prefix — states only (`focusable = false`, upstream's
`data-checkbox` click filtering is impossible without `stopPropagation`;
see the module docstring).
-}
prefixNode : Theme -> MenuOptions msg -> Option -> Bool -> Bool -> Bool -> Element msg
prefixNode theme _ option checked indeterminate disabled =
    let
        checkboxDefaults =
            NUI.Checkbox.defaults
    in
    Element.el
        [ I.classes [ "n-cascader-option__prefix" ]

        -- Upstream's `__prefix` is a plain `div.n-cascader-option__prefix`
        -- whose ONLY box rules are Naive UI's own (`display:flex;
        -- justify-content:center`, 4 class selectors). The port renders it
        -- as an elm-ui `Element.el`, which also tags on the `.s.e` layout
        -- classes; elm-ui's `.s.e { display:flex; flex-direction:column }
        -- (one class selector, but it comes LAST in the sheet, so it wins
        -- the tie against Naive UI's earlier same-specificity rule) flips
        -- the main axis to vertical — `justify-content:center` then centers
        -- the 16px checkbox vertically while leaving it glued to the
        -- slot's LEFT edge (0px inset in the 32px prefix; upstream is 8px).
        -- Inline `flex-direction: row` (inline beats both stylesheets)
        -- restores upstream's axis so the centering is horizontal, as shipped.
        , Element.htmlAttribute (HA.style "flex-direction" "row")
        ]
        (NUI.Checkbox.view theme
            { checkboxDefaults
                | focusable = False
                , checked = checked
                , indeterminate = indeterminate
                , disabled = disabled
            }
            []
        )


{-| The suffix cell — always the icon placeholder, carrying (branches) the
`NBaseLoading`-wrapped arrow (the spinner while the option is loading,
`spinProps` overriding the geometry), or (leaves, under `Child` with no
cascade checkboxes) the checked checkmark with its transition phase.
-}
suffixNode : MenuOptions msg -> Option -> Bool -> Element msg
suffixNode mopts option checked =
    Element.el
        [ I.classes [ "n-cascader-option__suffix" ]

        -- Same `.s.e` column-axis flip as the prefix above: the suffix's
        -- `justify-content:center` must run on the horizontal axis, or the
        -- 16px arrow/checkmark hugs the slot's left edge (upstream: 8px in
        -- the 32px suffix).
        , Element.htmlAttribute (HA.style "flex-direction" "row")
        ]
        (Element.el
            [ I.classes [ "n-cascader-option-icon-placeholder" ] ]
            (if not (isLeaf option) then
                loadingIconNode mopts option

             else if mopts.checkStrategy == Child && not (mopts.multiple && mopts.cascade) then
                if checked then
                    checkmarkNode mopts.checkmarkTransition

                else
                    Element.none

             else
                Element.none
            )
        )


loadingIconNode : MenuOptions msg -> Option -> Element msg
loadingIconNode mopts option =
    Element.el
        [ I.classes [ "n-base-loading", "n-cascader-option-icon" ]
        , Element.htmlAttribute (HA.attribute "role" "img")
        , Element.htmlAttribute (HA.attribute "aria-label" "loading")
        ]
        (if List.member (valueOf option) mopts.loadingKeys then
            Element.el
                [ I.classes [ "n-base-loading__transition-wrapper" ] ]
                (Element.el
                    [ I.classes [ "n-base-loading__container" ] ]
                    (Element.html
                        (Loading.spinner
                            { strokeWidth = Maybe.withDefault 24 mopts.spinStrokeWidth
                            , radius = Maybe.withDefault 100 mopts.spinRadius
                            , scale = Maybe.withDefault 0.85 mopts.spinScale
                            , stroke = mopts.spinStroke
                            }
                        )
                    )
                )

         else
            Element.el
                [ I.classes [ "n-base-loading__placeholder" ] ]
                (Element.html
                    (Html.i
                        [ HA.class "n-base-icon n-cascader-option-icon n-cascader-option-icon--arrow" ]
                        [ chevronRightSvg ]
                    )
                )
        )


{-| The checked leaf's checkmark — `i.n-base-icon` with the checkmark
modifier and the `fade-in-scale-up-transition` phase class when the caller
drives one (`Nothing` mounts it settled). Drive ENTER phases only:
upstream's `Transition` wraps the checked branch
(`CascaderOption.tsx:245-256`), so leave phases animate a logically
unchecked row — a `leave-*` class on a checked row pins the icon at
opacity 0 (`NUI.SelectMenu.checkmarkTransition` shares the wart).
-}
checkmarkNode : Maybe I.TransitionPhase -> Element msg
checkmarkNode maybePhase =
    Element.html
        (Html.i
            [ HA.class
                (String.join " "
                    ([ "n-base-icon", "n-cascader-option-icon", "n-cascader-option-icon--checkmark" ]
                        ++ (case maybePhase of
                                Just phase ->
                                    [ I.transitionClass "fade-in-scale-up-transition" phase ]

                                Nothing ->
                                    []
                           )
                    )
                )
            ]
            [ checkmarkSvg ]
        )


{-| The empty fallback — the `empty` slot or `NUI.Empty` at its own default
size (upstream passes no size).
-}
emptyNode : Theme -> MenuOptions msg -> Element msg
emptyNode theme mopts =
    Element.el
        [ I.classes [ "n-cascader-menu__empty" ] ]
        (Maybe.withDefault (NUI.Empty.view theme NUI.Empty.defaults []) mopts.empty)


{-| The action slot wrapper (`resolveWrappedSlot` gates it on the slot);
`data-action` serializes `"true"` (bare JSX attr — the transfer S2 rule).
-}
actionNode : Element msg -> Element msg
actionNode action =
    Element.el
        [ I.classes [ "n-cascader-menu-action" ]
        , Element.htmlAttribute (HA.attribute "data-action" "true")
        ]
        action


{-| NFocusDetector's inert sentinel (`width:0;height:0`, `tabindex=0`, no
classes), always mounted right after the body (upstream renders it
unconditionally; the port keeps the div inert).
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



-- ICONS -------------------------------------------------------------------------


{-| Upstream `ChevronRightIcon` (`_internal/icons/ChevronRight.tsx`) —
viewBox `0 0 16 16`, one `currentColor` path; the shipped `.n-base-icon
svg` rule sizes it.
-}
chevronRightSvg : Html.Html msg
chevronRightSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" chevronRightPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


chevronRightPath : String
chevronRightPath =
    "M5.64645 3.14645C5.45118 3.34171 5.45118 3.65829 5.64645 3.85355L9.79289 8L5.64645 12.1464C5.45118 12.3417 5.45118 12.6583 5.64645 12.8536C5.84171 13.0488 6.15829 13.0488 6.35355 12.8536L10.8536 8.35355C11.0488 8.15829 11.0488 7.84171 10.8536 7.64645L6.35355 3.14645C6.15829 2.95118 5.84171 2.95118 5.64645 3.14645Z"


{-| Upstream `CheckmarkIcon` (`_internal/icons/Checkmark.tsx`) — the same
node `NUI.SelectMenu` renders (viewBox `0 0 16 16`).
-}
checkmarkSvg : Html.Html msg
checkmarkSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" checkmarkPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


checkmarkPath : String
checkmarkPath =
    "M14.046 3.486a.75.75 0 0 1-.032 1.06l-7.93 7.474a.85.85 0 0 1-1.188-.022l-2.68-2.72a.75.75 0 1 1 1.068-1.053l2.234 2.267l7.468-7.038a.75.75 0 0 1 1.06.032z"



-- THEME ------------------------------------------------------------------------


{-| The 17 `--n-*` custom properties both menu roots carry (upstream
`cssVarsRef`, declaration order — the same set rides the flat select menu
through the follower's style merge). `--n-menu-mask-color` is
`changeColor(menuColor, { alpha: 0.75 })`; `--n-column-width` / the
heights come straight from the theme vars. The trigger's 52 live in
`NUI.BaseSelection.cssVars`.
-}
menuVars : Theme -> List ( String, String )
menuVars theme =
    let
        v =
            CascaderTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-menu-border-radius", v.menuBorderRadius )
    , ( "--n-menu-box-shadow", v.menuBoxShadow )
    , ( "--n-menu-height", v.menuHeight )
    , ( "--n-column-width", v.columnWidth )
    , ( "--n-menu-color", v.menuColor )
    , ( "--n-menu-divider-color", v.menuDividerColor )
    , ( "--n-option-height", v.optionHeight )
    , ( "--n-option-font-size", v.optionFontSize )
    , ( "--n-option-text-color", v.optionTextColor )
    , ( "--n-option-text-color-disabled", v.optionTextColorDisabled )
    , ( "--n-option-text-color-active", v.optionTextColorActive )
    , ( "--n-option-color-hover", v.optionColorHover )
    , ( "--n-option-check-mark-color", v.optionCheckMarkColor )
    , ( "--n-option-arrow-color", v.optionArrowColor )
    , ( "--n-menu-mask-color", NUI.Theme.Color.changeColor v.menuColor 0.75 )
    , ( "--n-loading-color", v.loadingColor )
    ]



-- SELECT MENU -------------------------------------------------------------------


{-| The filterable flat body — the `NUI.SelectMenu` root carrying the
`n-cascader-menu` class (its `.n-cascader-menu` rules apply to this root
too), the transition phase, and the merged `selectMenuVars` superset.
Mount it instead of `menu` while `filterable && pattern /= ""` (upstream
`showSelectMenu`). Keyboard `--pending` rides the flat rows'
`attributes` (the `NUI.SelectMenu` seam); `autoPending` is runtime.
The empty fallback is the BARE `__empty` wrapper: upstream always
provides the empty slot (`not-found`'s content or `[]`,
`CascaderSelectMenu.tsx:200-203`), so `NEmpty` never mounts — the
opposite of `Select.menu`, whose absent slot falls back to `NUI.Empty`.
`smopts.empty = Nothing` is the upstream default (wrapper only);
`Just e` is the `not-found` slot.
-}
selectMenu : Theme -> SelectMenuOptions msg -> List (SelectMenu.Option msg) -> Element msg
selectMenu theme smopts rows =
    SelectMenu.view theme (selectMenuOptions theme smopts) rows


{-| The flat body's `NUI.SelectMenu` composition: the always-provided
empty slot (upstream `resolveSlot(not-found, () => [])`) maps to `Just` —
a bare `__empty` wrapper by default (`Element.none`), the slot content
otherwise — so `SelectMenu`'s own `NUI.Empty` fallback never fires.
-}
selectMenuOptions : Theme -> SelectMenuOptions msg -> SelectMenu.Options msg
selectMenuOptions theme smopts =
    let
        d =
            SelectMenu.defaults
    in
    { d
        | multiple = smopts.multiple
        , value = smopts.value
        , empty = Just (Maybe.withDefault Element.none smopts.empty)
        , onToggle = smopts.onToggle
        , extraClasses =
            "n-cascader-menu"
                :: (case smopts.transition of
                        Just phase ->
                            [ I.transitionClass "fade-in-scale-up-transition" phase ]

                        Nothing ->
                            []
                   )
        , attributes =
            I.cssVars (selectMenuVars theme) :: smopts.attributes
    }


{-| Upstream's default filter pipeline (`createSelectOptions` + the default
`filter`): the tree flattens root-first (disabled nodes never list), each
non-disabled node becoming a row under `All` / `Parent` and each leaf only
under `Child` (upstream `isLeaf || !checkStrategyIsChild`), labeled with
its path label; a non-empty pattern keeps the rows whose PATH contains the
needle (case-insensitive substring on any non-empty node label — the row
label itself is never matched).
-}
filterOptions : String -> CheckStrategy -> String -> List Option -> List (SelectMenu.Option msg)
filterOptions pattern checkStrategy separator options =
    let
        needle =
            if String.isEmpty pattern then
                Nothing

            else
                Just (String.toLower pattern)
    in
    traverseSelect needle checkStrategy separator [] options


traverseSelect :
    Maybe String
    -> CheckStrategy
    -> String
    -> List Option
    -> List Option
    -> List (SelectMenu.Option msg)
traverseSelect needle checkStrategy separator path column =
    List.concatMap
        (\option ->
            if disabledOf option then
                []

            else
                let
                    nodePath =
                        path ++ [ option ]

                    row =
                        if
                            (isLeaf option || checkStrategy /= Child)
                                && pathMatches needle nodePath
                        then
                            [ SelectMenu.Option
                                { value = valueOf option
                                , label = pathLabel separator nodePath
                                , disabled = False
                                , attributes = []
                                }
                            ]

                        else
                            []
                in
                row
                    ++ (if isLeaf option then
                            []

                        else
                            traverseSelect needle
                                checkStrategy
                                separator
                                nodePath
                                (Maybe.withDefault [] (childrenOf option))
                       )
        )
        column


{-| Upstream's default `filter` — some non-empty node label on the path
contains the (lowercased) needle (case-insensitive substring, truthiness
guard); no needle keeps every row.
-}
pathMatches : Maybe String -> List Option -> Bool
pathMatches maybeNeedle path =
    case maybeNeedle of
        Nothing ->
            True

        Just needle ->
            List.any
                (\option ->
                    not (String.isEmpty (labelOf option))
                        && String.contains needle (String.toLower (labelOf option))
                )
                path


{-| The flat menu's merged root style — `NUI.SelectMenu`'s 23 (its own
`cssVars`, medium — the size upstream leaves fixed) plus cascader's 17
(the follower's style merge; the duplicated keys agree at medium).
-}
selectMenuVars : Theme -> List ( String, String )
selectMenuVars theme =
    SelectMenu.cssVars theme SelectMenu.Medium ++ menuVars theme
