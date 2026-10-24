module NUI.Select exposing (MenuOptions, Options, Size(..), Status, defaults, filterOptions, menu, menuDefaults, menuVars, toggleValue, view)

{-| Naive UI's `Select` — a thin composition over `NUI.BaseSelection` (the
trigger) and `NUI.SelectMenu` (the body). NOT a popover-family body-swap:
upstream mounts the menu in its own `VFollower` (positioning/clickoutside/
show/keyboard all runtime), so the port renders the trigger and offers the
menu as a separate caller-mounted body (the `NUI.Dropdown` lane minus the
popover entirely).

    import NUI.Select as Select
    import NUI.SelectMenu

    Select.view theme
        { Select.defaults | onUpdateValue = Just Changed }
        [ NUI.SelectMenu.Option
            { value = "drive", label = "Drive My Car", disabled = False, attributes = [] }
        ]

Trigger (`view`) DOM — the `.n-select` wrapper is bare (no vars, no extra
classes; all styling lives on the `.n-base-selection` trigger and the menu):

    div.n-select
      └─ NUI.BaseSelection.view (see its docstring for the full tree;
         `view` derives the display state from `value` + `options`)

`view` derives, per upstream: single `selectedLabel` = the value's option's
label, else the fallback (`fallbackOption` default true → the value itself
as its label; false → no selection shown); multiple `tags` = the value list
order mapped onto options (same fallback rules; unknown values drop when
`fallbackOption = False`); numeric `maxTagCount` slices the tags and sets
`ellipsisTag = Just rest` when `rest > 0`; `showClear = clearable &&
!disabled && (hover || active) && selected` (upstream `mergedClearable &&
selected` — hover is the one truly-runtime input, hence a field here).

Menu (`menu`) DOM — the select-menu root carrying Select's own additions
(the `NUI.Popselect` composition precedent, minus the popover classes):

    div.n-base-select-menu .n-base-select-menu--{size}-size
        [--rtl] [--multiple] .n-select-menu [fade-in-scale-up-transition-*]
      tabindex = 0 (focusable, upstream hardcodes true)
      style = 23 menu vars → --n-menu-box-shadow
      └─ NUI.SelectMenu rows incl. the __loading row (loading) — see there

`menuVars` = the 23 `NUI.SelectMenu` vars + `--n-menu-box-shadow` (Select's
single own var). The transition class is the follower's
`fade-in-scale-up-transition` phase (upstream wraps the menu in that
`Transition`).

Caller-owned runtime (the port-wide convention): show state, positioning
and mounting, keyboard navigation and pending (`--pending` via per-option
`attributes`), `virtualScroll`, filtering state (`pattern` +
`onPatternInput` flow through; `filterOptions` is the pure default filter),
`remote`/`loading` orchestration, tag creation (`tag` mode — prepend a
being-created option to the list you pass), the responsive `maxTagCount`
overflow and its preview popover (slice + `BaseSelection.ellipsisTag` is
the static seam), `clearFilterAfterSelect`, form-item size/disabled/status
merging, `consistentMenuWidth` (width follows the trigger's wrapper),
`onSearch`/`onScroll`/`onFocus`/`onBlur`, IME. `widthMode` is dead upstream
(declared, never read) — not ported; `items`/`onChange` deprecated; the
`default` slot upstream never renders. Values are `String` keys
(upstream allows numbers; the documented `NUI.SelectMenu` limitation).

@docs MenuOptions, Options, Size, Status, defaults, filterOptions, menu, menuDefaults, menuVars, toggleValue, view

-}

import Element exposing (Element)
import NUI.BaseSelection as BaseSelection
import NUI.Internal as I
import NUI.Scrollbar
import NUI.SelectMenu as SelectMenu
import NUI.Theme exposing (Theme)
import NUI.Theme.Select as SelectTheme



-- TYPES ------------------------------------------------------------------------


{-| Upstream `SelectSize` — `'tiny' | 'small' | 'medium' | 'large'` (no
`huge`; keys both the trigger and, via `menuSize`, the menu).
-}
type Size
    = Tiny
    | Small
    | Medium
    | Large


{-| Upstream `FormValidationStatus` — re-bound to `NUI.BaseSelection.Status`.
-}
type alias Status =
    BaseSelection.Status


{-| The trigger options. Runtime behaviour (show state, positioning,
keyboard, filtering orchestration) is caller-owned.
-}
type alias Options msg =
    { size : Size
    , menuSize : Maybe Size
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
    , loading : Bool
    , showArrow : Bool
    , maxTagCount : Maybe Int
    , fallbackOption : Bool
    , pattern : String
    , arrow : Maybe (Element msg)
    , onClear : Maybe msg
    , onPatternInput : Maybe (String -> msg)
    , onDeleteTag : Maybe (String -> msg)
    , onUpdateValue : Maybe (SelectMenu.Value -> msg)
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`size: 'medium'` via the form/config merge,
`showArrow: true`, `fallbackOption` on, placeholder = the en-US locale
`'Please Select'`, `value = Single Nothing` = null; everything else false /
empty).
-}
defaults : Options msg
defaults =
    { size = Medium
    , menuSize = Nothing
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
    , loading = False
    , showArrow = True
    , maxTagCount = Nothing
    , fallbackOption = True
    , pattern = ""
    , arrow = Nothing
    , onClear = Nothing
    , onPatternInput = Nothing
    , onDeleteTag = Nothing
    , onUpdateValue = Nothing
    , rtl = False
    , attributes = []
    }


{-| The menu options. Runtime behaviour is caller-owned; `size = Nothing` is
upstream's absent `menuSize` (the menu's own `medium` default).
-}
type alias MenuOptions msg =
    { size : Maybe Size
    , multiple : Bool
    , value : SelectMenu.Value
    , showCheckmark : Bool
    , loading : Bool
    , header : Maybe (Element msg)
    , action : Maybe (Element msg)
    , empty : Maybe (Element msg)
    , onToggle : Maybe (String -> msg)
    , renderOption : Maybe (SelectMenu.BuiltRow msg -> Element msg)
    , scrollbarProps : Maybe (NUI.Scrollbar.Options msg -> NUI.Scrollbar.Options msg)
    , transition : Maybe I.TransitionPhase
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| The menu defaults (`showCheckmark: true`, `value = Single Nothing`,
`size = Nothing` = medium; everything else false / empty).
-}
menuDefaults : MenuOptions msg
menuDefaults =
    { size = Nothing
    , multiple = False
    , value = SelectMenu.Single Nothing
    , showCheckmark = True
    , loading = False
    , header = Nothing
    , action = Nothing
    , empty = Nothing
    , onToggle = Nothing
    , renderOption = Nothing
    , scrollbarProps = Nothing
    , transition = Nothing
    , rtl = False
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The `.n-select` wrapper + the `NUI.BaseSelection` trigger, with the
display state derived from `value` + `options` per the module docstring.
-}
view : Theme -> Options msg -> List (SelectMenu.Option msg) -> Element msg
view theme opts options =
    Element.el
        ([ I.classes [ "n-select" ] ] ++ opts.attributes)
        (BaseSelection.view theme (baseSelectionOptions opts options))


{-| The trigger's options derived per the module docstring: the single label
/ the multiple tags (upstream `selectedOptionRef` / `selectedOptionsRef` via
`getMergedOptions` — option lookup first, then the fallback), the numeric
`maxTagCount` slice and the clear gate — everything else passes straight
through (the wrapper keeps `attributes`; `BaseSelection` gets none of its
own).
-}
baseSelectionOptions : Options msg -> List (SelectMenu.Option msg) -> BaseSelection.Options msg
baseSelectionOptions opts options =
    let
        selectedLabel =
            case opts.value of
                SelectMenu.Single (Just value) ->
                    case findLeaf value options of
                        Just leaf ->
                            Just leaf.label

                        Nothing ->
                            fallbackLabel opts.fallbackOption value

                _ ->
                    Nothing

        tags =
            case opts.value of
                SelectMenu.Multiple values ->
                    List.filterMap (tagFor opts.fallbackOption options) values

                _ ->
                    []

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
        , loading = opts.loading
        , showClear =
            opts.clearable
                && not opts.disabled
                && (opts.hover || opts.active)
                && selected
        , showArrow = opts.showArrow
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


{-| The value's leaf option — upstream's `valOptMap` walk: groups recurse
into their children, `Custom` rows carry no value to match, first match
wins.
-}
findLeaf : String -> List (SelectMenu.Option msg) -> Maybe (SelectMenu.LeafOption msg)
findLeaf value options =
    case options of
        [] ->
            Nothing

        (SelectMenu.Option leaf) :: rest ->
            if leaf.value == value then
                Just leaf

            else
                findLeaf value rest

        (SelectMenu.Group group) :: rest ->
            case findLeaf value group.children of
                Just found ->
                    Just found

                Nothing ->
                    findLeaf value rest

        (SelectMenu.Custom _) :: rest ->
            findLeaf value rest


{-| Upstream's default `fallbackOption` — an unknown value shows itself as
its own label; `fallbackOption = False` shows no selection.
-}
fallbackLabel : Bool -> String -> Maybe String
fallbackLabel fallbackOption value =
    if fallbackOption then
        Just value

    else
        Nothing


{-| One multiple-mode tag — the value's option (its `disabled` rides along,
upstream `closable = !option.disabled`), else the fallback (a bare
value-as-label tag, enabled); unknown values drop when
`fallbackOption = False`.
-}
tagFor : Bool -> List (SelectMenu.Option msg) -> String -> Maybe (BaseSelection.Tag msg)
tagFor fallbackOption options value =
    case findLeaf value options of
        Just leaf ->
            Just
                (BaseSelection.Tag
                    { value = leaf.value
                    , label = leaf.label
                    , disabled = leaf.disabled
                    }
                )

        Nothing ->
            if fallbackOption then
                Just
                    (BaseSelection.Tag
                        { value = value
                        , label = value
                        , disabled = False
                        }
                    )

            else
                Nothing


{-| Upstream's numeric `maxTagCount` — keep the first `n` tags and report the
rest as the `+N` ellipsis tag; `'responsive'` overflow is caller-owned (the
module docstring).
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


{-| `Select.Size` onto the trigger's — the same four constructors, two
distinct unions (the selection trigger has no `Huge`).
-}
baseSize : Size -> BaseSelection.Size
baseSize size =
    case size of
        Tiny ->
            BaseSelection.Tiny

        Small ->
            BaseSelection.Small

        Medium ->
            BaseSelection.Medium

        Large ->
            BaseSelection.Large


{-| The `n-select-menu` body — `NUI.SelectMenu.view` carrying
`extraClasses = ["n-select-menu", transition?]`, `focusable = True`
(upstream hardcodes it) and the `menuVars` style. Mount it in the caller's
positioned wrapper when open.
-}
menu : Theme -> MenuOptions msg -> List (SelectMenu.Option msg) -> Element msg
menu theme mopts options =
    SelectMenu.view theme (menuOptions theme mopts) options


{-| The menu assembled through `NUI.SelectMenu`'s composition seams (the
`NUI.Popselect` precedent minus the popover classes): Select's own
`n-select-menu` class and the follower's `fade-in-scale-up-transition`
phase ride `extraClasses` after the menu's own classes; the merged root
style (`menuVars`, 23 + 1 vars) rides `attributes`, applied last so its
superset wins by last-wins. Upstream hardcodes `focusable`; `scrollbarProps`
has no `SelectMenu` seam (the plain option-wrapper path is the port's
render) — the field stays for the caller. An absent `size` is the menu's
own `medium` default.
-}
menuOptions : Theme -> MenuOptions msg -> SelectMenu.Options msg
menuOptions theme mopts =
    let
        size =
            Maybe.withDefault Medium mopts.size

        d =
            SelectMenu.defaults
    in
    { d
        | size = menuSize size
        , multiple = mopts.multiple
        , value = mopts.value
        , showCheckmark = mopts.showCheckmark
        , focusable = True
        , loading = mopts.loading
        , header = mopts.header
        , action = mopts.action
        , empty = mopts.empty
        , onToggle = mopts.onToggle
        , rtl = mopts.rtl
        , extraClasses =
            "n-select-menu"
                :: (case mopts.transition of
                        Just phase ->
                            [ I.transitionClass "fade-in-scale-up-transition" phase ]

                        Nothing ->
                            []
                   )
        , attributes =
            I.cssVars (menuVars theme size) :: mopts.attributes
    }


{-| `Select.Size` onto the menu's five-size scale — the four constructors 1:1
(`SelectSize` has no `huge`; the menu keeps its own `Huge` for
`NUI.Popselect`).
-}
menuSize : Size -> SelectMenu.Size
menuSize size =
    case size of
        Tiny ->
            SelectMenu.Tiny

        Small ->
            SelectMenu.Small

        Medium ->
            SelectMenu.Medium

        Large ->
            SelectMenu.Large



-- PURE LOGIC -------------------------------------------------------------------


{-| Upstream's pure toggle (`handleToggleByOption`): multiple mode toggles
list membership (existing order kept, new values appended; a non-list
current value starts fresh from the key); single mode always selects —
Select has no `cancelable` (that is `NUI.Popselect`).
-}
toggleValue : Bool -> SelectMenu.Value -> String -> SelectMenu.Value
toggleValue multiple current key =
    if multiple then
        case current of
            SelectMenu.Multiple values ->
                if List.member key values then
                    SelectMenu.Multiple (List.filter (\v -> v /= key) values)

                else
                    SelectMenu.Multiple (values ++ [ key ])

            _ ->
                SelectMenu.Multiple [ key ]

    else
        SelectMenu.Single (Just key)


{-| Upstream's default filter (`resolvedFilter` + `filterOptions`): a
trimmed, case-insensitive substring match on the label, falling back to the
value; groups filter their children recursively and drop when empty;
`Custom` rows pass through (nothing to match). An empty pattern keeps
everything (upstream short-circuits the same way).
-}
filterOptions : String -> List (SelectMenu.Option msg) -> List (SelectMenu.Option msg)
filterOptions pattern options =
    if String.isEmpty (String.trim pattern) then
        options

    else
        List.filterMap (filterOption (String.toLower (String.trim pattern))) options


{-| One node under the trimmed, lowercased needle — a leaf matches on its
label first, then its value (upstream `resolvedFilter`'s two
`patternMatched` probes); a group filters its children recursively and
drops when nothing survived; a `Custom` row passes through (nothing to
match).
-}
filterOption : String -> SelectMenu.Option msg -> Maybe (SelectMenu.Option msg)
filterOption needle option =
    case option of
        SelectMenu.Option leaf ->
            if patternMatched needle leaf.label || patternMatched needle leaf.value then
                Just option

            else
                Nothing

        SelectMenu.Group group ->
            let
                children =
                    List.filterMap (filterOption needle) group.children
            in
            if List.isEmpty children then
                Nothing

            else
                Just (SelectMenu.Group { group | children = children })

        SelectMenu.Custom _ ->
            Just option


{-| Upstream `patternMatched` — `String.contains` is the
`indexOf >= 0` truthiness (`1 + indexOf` of the try/catch original); the
needle arrives already trimmed and lowercased.
-}
patternMatched : String -> String -> Bool
patternMatched needle value =
    String.contains needle (String.toLower value)



-- THEME ------------------------------------------------------------------------


{-| The menu's root style — the 23 `NUI.SelectMenu` vars plus Select's one
own var (`--n-menu-box-shadow`, the follower menu's shadow). The trigger's
52 vars live in `NUI.BaseSelection.cssVars`.
-}
menuVars : Theme -> Size -> List ( String, String )
menuVars theme size =
    SelectMenu.cssVars theme (menuSize size)
        ++ [ ( "--n-menu-box-shadow", (SelectTheme.vars theme).menuBoxShadow ) ]
