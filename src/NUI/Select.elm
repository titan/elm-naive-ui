module NUI.Select exposing
    ( MenuOptions
    , Options
    , Size(..)
    , Status
    , defaults
    , filterOptions
    , menu
    , menuVars
    , toggleValue
    , view
    )

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
view _ _ _ =
    Element.none


{-| The `n-select-menu` body — `NUI.SelectMenu.view` carrying
`extraClasses = ["n-select-menu", transition?]`, `focusable = True`
(upstream hardcodes it) and the `menuVars` style. Mount it in the caller's
positioned wrapper when open.
-}
menu : Theme -> MenuOptions msg -> List (SelectMenu.Option msg) -> Element msg
menu _ _ _ =
    Element.none



-- PURE LOGIC -------------------------------------------------------------------


{-| Upstream's pure toggle (`handleToggleByOption`): multiple mode toggles
list membership (existing order kept, new values appended; a non-list
current value starts fresh from the key); single mode always selects —
Select has no `cancelable` (that is `NUI.Popselect`).
-}
toggleValue : Bool -> SelectMenu.Value -> String -> SelectMenu.Value
toggleValue _ _ _ =
    SelectMenu.Single Nothing


{-| Upstream's default filter (`resolvedFilter` + `filterOptions`): a
trimmed, case-insensitive substring match on the label, falling back to the
value; groups filter their children recursively and drop when empty;
`Custom` rows pass through (nothing to match). An empty pattern keeps
everything (upstream short-circuits the same way).
-}
filterOptions : String -> List (SelectMenu.Option msg) -> List (SelectMenu.Option msg)
filterOptions _ options =
    options



-- THEME ------------------------------------------------------------------------


{-| The menu's root style — the 23 `NUI.SelectMenu` vars plus Select's one
own var (`--n-menu-box-shadow`, the follower menu's shadow). The trigger's
52 vars live in `NUI.BaseSelection.cssVars`.
-}
menuVars : Theme -> Size -> List ( String, String )
menuVars _ _ =
    []
