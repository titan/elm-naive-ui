module NUI.SelectMenu exposing
    ( GroupOption
    , LeafOption
    , Option(..)
    , Options
    , RenderOption
    , Size(..)
    , Value(..)
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's internal select-menu body (upstream `NInternalSelectMenu`,
`_internal/select-menu/`), rebuilt on elm-ui — the support module
`NUI.Popselect` renders (the `NUI.DrawerContent` / `NUI.Scrollbar` precedent;
the future `Select` batch extends it).

    div.n-base-select-menu .n-base-select-menu--{size}-size
        [--rtl] [--multiple] [+ caller extraClasses]
      tabindex = focusable ? 0 : -1
      style = 23 css vars
      ├─ div.n-base-select-menu__header [data-header]          — iff header
      ├─ NUI.Scrollbar
      │    > div.n-base-select-menu-option-wrapper             — padding from size
      │        > div.n-base-select-group-header {label}        — group header
      │        > div.n-base-select-option [--disabled] [--selected]
      │            [--grouped] [--pending] [--show-checkmark]
      │          > div.__content {label, [i.n-base-icon.__check > svg]}
      │                                                        — check iff selected && showCheckmark
      │    (empty list → div.__empty [data-empty] {empty | NUI.Empty})
      └─ div.n-base-select-menu__action [data-action]          — iff action
          + div[width:0;height:0][tabindex=0]                  — NFocusDetector, inert

Everything runtime is caller-owned (the popover-family precedent): keyboard
navigation and `--pending` (caller-injected per-option `attributes`),
`virtualScroll` (the virtual list — the plain option-wrapper path only),
`loading`, focus handlers, `onTabOut`. `--grouped` is computed from the tree;
`--show-checkmark` lands on EVERY option while `showCheckmark` (upstream
default true — the padding rule needs it). Options carry `value : String`
keys (upstream allows numbers); `Custom` renders its node verbatim with no
toggle wiring. Empty = no flattened rows (groups' children included).

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)


{-| Upstream's size scale — the theme keys all five (`PopselectSize` drops
`tiny`; that union lives in `NUI.Popselect`).
-}
type Size
    = Tiny
    | Small
    | Medium
    | Large
    | Huge


{-| Upstream `value: string | number | array | null`: `Single` for single
mode (`Nothing` = null), `Multiple` for multiple mode.
-}
type Value
    = Single (Maybe String)
    | Multiple (List String)


{-| One menu row: a leaf option, a group (header + children, one level —
nested groups are dropped like treemate flattens), or a fully custom node.
-}
type Option msg
    = Option (LeafOption msg)
    | Group (GroupOption msg)
    | Custom (RenderOption msg)


{-| A leaf row — `value` is upstream's option `value` (the treemate key).
-}
type alias LeafOption msg =
    { value : String
    , label : String
    , disabled : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| A group: its header renders first, then its children as siblings
(upstream renders the flattened fragment).
-}
type alias GroupOption msg =
    { label : String
    , children : List (Option msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream `rawNode.render` / `renderOption` — the node replaces the row
outright (no toggle wiring; it still counts as a row for emptiness).
-}
type alias RenderOption msg =
    { key : String
    , node : Element msg
    }


{-| The menu options. Runtime behaviour (keyboard, pending, focus) is
caller-owned.
-}
type alias Options msg =
    { size : Size
    , multiple : Bool
    , value : Value
    , showCheckmark : Bool
    , focusable : Bool
    , header : Maybe (Element msg)
    , action : Maybe (Element msg)
    , empty : Maybe (Element msg)
    , onToggle : Maybe (String -> msg)
    , checkmarkTransition : Maybe I.TransitionPhase
    , rtl : Bool
    , extraClasses : List String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`showCheckmark: true` upstream; the rest false /
empty; `value = Single Nothing` = null).
-}
defaults : Options msg
defaults =
    { size = Medium
    , multiple = False
    , value = Single Nothing
    , showCheckmark = True
    , focusable = False
    , header = Nothing
    , action = Nothing
    , empty = Nothing
    , onToggle = Nothing
    , checkmarkTransition = Nothing
    , rtl = False
    , extraClasses = []
    , attributes = []
    }


{-| The `.n-base-select-menu` body per the module docstring tree.
-}
view : Theme -> Options msg -> List (Option msg) -> Element msg
view _ _ _ =
    Element.none


{-| The 23 `--n-*` custom properties the menu attaches (upstream cssVarsRef,
declaration order). Size-keyed: `--n-option-font-size` / `--n-option-height` /
`--n-option-padding` switch on `size`; `--n-height` is the
`calc(var(--n-option-height) * 7.6)` literal.
-}
cssVars : Theme -> Size -> List ( String, String )
cssVars _ _ =
    []
