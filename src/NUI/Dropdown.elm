module NUI.Dropdown exposing
    ( DividerOption
    , GroupOption
    , LeafOption
    , Option(..)
    , Options
    , Placement
    , RenderOption
    , Size(..)
    , cssVars
    , defaults
    , placementAttribute
    , placementName
    , view
    )

{-| Naive UI's `Dropdown` — the `n-dropdown-menu` body. Upstream the component
is the popover runtime with the body swapped (`internalRenderBody`,
`Dropdown.tsx`): the popover contributes the trigger/show/positioning machinery,
the shared classes (`n-popover-shared` + overlap/arrow modifiers) and half the
CSS vars; the dropdown contributes the menu DOM, the `n-dropdown` /
`n-dropdown--{size}-size` markers and its own theme vars.

    import NUI.Dropdown as Dropdown
    import NUI.Theme as Theme

    Dropdown.view Theme.default
        Dropdown.defaults
        [ Dropdown.Option
            { key = "feedback"
            , label = "Feedback"
            , icon = Nothing
            , disabled = False
            , children = Nothing
            , attributes = []
            }
        , Dropdown.Divider { attributes = [] }
        ]

**Everything in `NUI.Popover`'s docstring about the caller-owned runtime
applies** — show state, trigger, delay/positioning, the `v-placement` wrapper
(use `placementAttribute`), the `--v-offset-*` note. The dropdown default
placement is `Bottom` (upstream overrides the popover's top).

**The caller-owned submenu contract** (beyond the popover's omissions):

  - Submenu open state, the 300 ms hover defer, and submenu positioning are
    yours. The port renders the (inert) `n-dropdown-offset-container` scaffold
    inside submenu options; you mount each submenu's `view` (same options, the
    children list) inside your own positioned wrapper, upstream-style in a
    `div.n-dropdown-menu-wrapper` you own. Submenus use the
    `"fade-in-scale-up-transition"` family (rules are scoped
    `.n-dropdown-menu.fade-in-scale-up-*`), the root uses
    `"popover-transition"` — hence `transition` carries the family explicitly.

**Documented gaps** (beyond the popover's):

  - `key` is required per option (upstream generates keys for keyless options);
    with duplicate keys the first match wins for `value` highlighting.
  - `label`/`icon` replace upstream's `label|title` + render hooks;
    `renderLabel`/`renderIcon`/`renderOption`/`nodeProps`/`menuProps` become
    per-option `attributes` (they land on the option body, upstream's
    `option.props`), the `Custom` variant, and root `attributes`. `extra` /
    `titleExtra` (Menu features) and the `labelField`/`keyField`/
    `childrenField` overrides are not modelled.
  - `onSelect` fires on leaf clicks (non-disabled, non-submenu); closing the
    menu afterwards is your model change (upstream closes automatically).
  - Pending (hover) option state is runtime — inject
    `n-dropdown-option-body--pending` classes via the option's `attributes`.
  - `keyboard` navigation, `show === false` filtering (just omit the option),
    and group-in-group (dropped, as upstream nulls it) are not modelled.
  - Derived colours (`optionColorActive` = `changeColor(primary, …)`) are
    pinned literals in `NUI.Theme.Dropdown` — computed at the default theme;
    a `common` override does not re-derive them (toolchain convention, cf. Tag).
  - The submenu chevron SVG is inlined here (house style, cf. `NUI.Collapse`).

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Popover as Popover
import NUI.Theme exposing (Theme)



-- TYPES ------------------------------------------------------------------------


{-| A follower placement — the constructors live in `NUI.Popover`
(`Popover.Bottom`, `Popover.TopStart`, …); the dropdown default is `Bottom`.
-}
type alias Placement =
    Popover.Placement


{-| The menu size — drives `n-dropdown--{size}-size` and the size-keyed vars
(option height / font size / icon and column widths). Upstream default is
`Medium`.
-}
type Size
    = Small
    | Medium
    | Large
    | Huge


{-| One menu entry. `Option` is a selectable (or submenu) row, `Group` a
labelled section (one level only), `Divider` the 1px rule, `Custom` upstream's
`type: 'render'` escape hatch.
-}
type Option msg
    = Option (LeafOption msg)
    | Group (GroupOption msg)
    | Divider (DividerOption msg)
    | Custom (RenderOption msg)


{-| A selectable row — `children = Just …` makes it a submenu (chevron suffix,
no select on click). `attributes` land on the option body div (upstream
`option.props`).
-}
type alias LeafOption msg =
    { key : String
    , label : String
    , icon : Maybe (Element msg)
    , disabled : Bool
    , children : Maybe (List (Option msg))
    , attributes : List (Element.Attribute msg)
    }


{-| A group header followed by its children. Nested groups are dropped
(upstream warns and renders nothing for them).
-}
type alias GroupOption msg =
    { key : String
    , label : String
    , icon : Maybe (Element msg)
    , children : List (Option msg)
    }


{-| The divider rule. `attributes` land on the div.
-}
type alias DividerOption msg =
    { attributes : List (Element.Attribute msg) }


{-| Upstream's `type: 'render'` — arbitrary content in a wrapper div.
-}
type alias RenderOption msg =
    { key : String
    , children : List (Element msg)
    , attributes : List (Element.Attribute msg)
    }


{-| The menu body's options.
-}
type alias Options msg =
    { placement : Placement
    , size : Size
    , inverted : Bool
    , scrollable : Bool
    , showArrow : Bool
    , arrowStyle : Maybe String
    , overlap : Bool
    , arrowPointToCenter : Bool
    , rtl : Bool
    , width : Maybe String
    , value : Maybe String
    , onSelect : Maybe (String -> msg)
    , transition : Maybe ( String, I.TransitionPhase )
    , attributes : List (Element.Attribute msg)
    }


{-| The dropdown's defaults — upstream `dropdownBaseProps` over the popover's:
placement `Bottom`, size `Medium`, `showArrow` **False** (the dropdown's own
default overrides the popover's `True`), everything else off / `Nothing`.
-}
defaults : Options msg
defaults =
    { placement = Popover.Bottom
    , size = Medium
    , inverted = False
    , scrollable = False
    , showArrow = False
    , arrowStyle = Nothing
    , overlap = False
    , arrowPointToCenter = False
    , rtl = False
    , width = Nothing
    , value = Nothing
    , onSelect = Nothing
    , transition = Nothing
    , attributes = []
    }



-- PLACEMENT (re-bound to the popover's) -----------------------------------------


{-| The placement's `v-placement` string (see `NUI.Popover.placementName`).
-}
placementName : Placement -> String
placementName =
    Popover.placementName


{-| The `v-placement` attribute for the caller's positioned wrapper (see
`NUI.Popover.placementAttribute`).
-}
placementAttribute : Placement -> Element.Attribute msg
placementAttribute =
    Popover.placementAttribute



-- VIEW -------------------------------------------------------------------------


{-| The `n-dropdown-menu` body — the single root div carrying both the menu
classes and the popover-shared ones (`n-popover-shared`, overlap/arrow
modifiers), the 31 merged CSS vars, the option rows, and (when `showArrow`
survives the `overlap` merge) the popover arrow pair. Mount it inside a
wrapper that carries `placementAttribute`.
-}
view : Theme -> Options msg -> List (Option msg) -> Element msg
view _ _ _ =
    Element.none


{-| The 31 `--n-*` custom properties the body attaches — the popover's 15
(six of them re-valued from the dropdown theme: `--n-font-size`,
`--n-color`, `--n-divider-color`, `--n-border-radius`, `--n-padding`,
`--n-bezier`) followed by the dropdown's own 16 in upstream declaration
order. Size- and inverted-dependent.
-}
cssVars : Theme -> Size -> Bool -> List ( String, String )
cssVars _ _ _ =
    []
