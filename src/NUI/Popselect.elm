module NUI.Popselect exposing
    ( Options
    , Placement
    , Size(..)
    , cssVars
    , defaults
    , placementAttribute
    , placementName
    , toggleValue
    , view
    )

{-| Naive UI's `Popselect` — the popover-family body whose **select-menu root
is the popover-shared body** (upstream swaps the body via
`internalRenderBody`; the `NUI.Dropdown` lane — this is NOT a
`NUI.Popover.view` wrapper):

    import NUI.Popselect as Popselect
    import NUI.SelectMenu

    Popselect.view theme
        { Popselect.defaults | onUpdateValue = Just Selected }
        [ NUI.SelectMenu.Option
            { value = "drive", label = "Drive My Car", disabled = False, attributes = [] }
        ]

DOM (everything in `NUI.Popover`'s docstring about the runtime applies — the
caller owns show/trigger (`'hover'` default)/positioning and mounts the body
in a `placementAttribute` wrapper, default placement **bottom**):

    div.n-base-select-menu .n-base-select-menu--{size}-size
        [--rtl] [--multiple] .n-popselect-menu .n-popover-shared
        [rtl] [overlap] .n-popover-shared--show-arrow (ALWAYS) [center-arrow]
        [popover-transition-*]
      tabindex = 0 (focusable)
      style = 23 menu vars → --n-menu-box-shadow → [width?] → 15 popover vars
              (--n-padding = 0, upstream builtinThemeOverrides)
      └─ NUI.SelectMenu rows (header / options-or-empty / action) — see there

There is **no `n-popover` class, no `n-popover__content` wrapper, no arrow
node** — the internalRenderBody path (identical to Dropdown). The
`--show-arrow` modifier is always emitted (upstream removed the prop but the
popover default keeps the class — a margin-only cosmetic quirk; pinned).

**Selection** is pure: `value` (`SelectMenu.Value`) drives `--selected` +
the checkmark per option; clicking a non-disabled leaf fires
`onUpdateValue` with the NEXT value computed by `toggleValue` (upstream's
panel `toggle`: multiple toggles list membership preserving order; single
selects — or deselects to `Single Nothing` when `cancelable` and the value
was current). Upstream then auto-closes on single select — the caller's
update does that here. Sizes: upstream `PopselectSize` has no `tiny` — the
four constructors map onto `NUI.SelectMenu.Size` internally.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Popover as Popover
import NUI.Scrollbar
import NUI.SelectMenu as SelectMenu
import NUI.Theme exposing (Theme)


{-| Upstream `PopselectSize` — `'small' | 'medium' | 'large' | 'huge'` (no
`tiny`; mapped onto `NUI.SelectMenu.Size` internally).
-}
type Size
    = Small
    | Medium
    | Large
    | Huge


{-| A follower placement (see `NUI.Popover.Placement`). The constructors live
in `NUI.Popover` — the alias makes them interchangeable with this module's
API. Upstream default: `bottom`.
-}
type alias Placement =
    Popover.Placement


{-| The popselect options. Runtime behaviour (show state, positioning) is
caller-owned.
-}
type alias Options msg =
    { placement : Placement
    , size : Size
    , multiple : Bool
    , value : SelectMenu.Value
    , cancelable : Bool
    , showCheckmark : Bool
    , width : Maybe String
    , overlap : Bool
    , arrowPointToCenter : Bool
    , rtl : Bool
    , transition : Maybe I.TransitionPhase
    , header : Maybe (Element msg)
    , action : Maybe (Element msg)
    , empty : Maybe (Element msg)
    , onUpdateValue : Maybe (SelectMenu.Value -> msg)
    , scrollbarProps : Maybe (NUI.Scrollbar.Options msg -> NUI.Scrollbar.Options msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`size: 'medium'`, `showCheckmark` true via the menu,
`value = Single Nothing`; everything else false / empty).
-}
defaults : Options msg
defaults =
    { placement = Popover.Bottom
    , size = Medium
    , multiple = False
    , value = SelectMenu.Single Nothing
    , cancelable = False
    , showCheckmark = True
    , width = Nothing
    , overlap = False
    , arrowPointToCenter = False
    , rtl = False
    , transition = Nothing
    , header = Nothing
    , action = Nothing
    , empty = Nothing
    , onUpdateValue = Nothing
    , scrollbarProps = Nothing
    , attributes = []
    }


{-| The `n-popselect-menu` body — the select-menu root carrying the
popover-shared classes and the 39 merged vars. Mount it inside a wrapper
that carries `placementAttribute`.
-}
view : Theme -> Options msg -> List (SelectMenu.Option msg) -> Element msg
view _ _ _ =
    Element.none


{-| The merged 39 `--n-*` custom properties on the root, in order: the 23
select-menu vars, `--n-menu-box-shadow`, then `[width?]` and the 15 popover
vars with `--n-padding` overridden to `0` (upstream
`builtinThemeOverrides`; the `NUI.Tooltip` var-swap precedent).
-}
cssVars : Theme -> Size -> List ( String, String )
cssVars _ _ =
    []


{-| Upstream's pure panel `toggle` (PopselectPanel.tsx): the next value after
clicking `key`. Multiple mode toggles list membership (existing order kept,
new values appended; a non-list current value starts fresh from the key);
single mode selects the key — or deselects to `Single Nothing` when
`cancelable` and the key was already current.
-}
toggleValue : Bool -> Bool -> SelectMenu.Value -> String -> SelectMenu.Value
toggleValue multiple cancelable current key =
    if multiple then
        case current of
            SelectMenu.Multiple values ->
                if List.member key values then
                    SelectMenu.Multiple (List.filter (\v -> v /= key) values)

                else
                    SelectMenu.Multiple (values ++ [ key ])

            _ ->
                SelectMenu.Multiple [ key ]

    else if cancelable && current == SelectMenu.Single (Just key) then
        SelectMenu.Single Nothing

    else
        SelectMenu.Single (Just key)


{-| The placement's `v-placement` string — re-bound to `NUI.Popover`'s.
-}
placementName : Placement -> String
placementName =
    Popover.placementName


{-| The `v-placement` attribute for the caller's positioned wrapper —
re-bound to `NUI.Popover`'s.
-}
placementAttribute : Placement -> Element.Attribute msg
placementAttribute =
    Popover.placementAttribute
