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
        [rtl] [overlap] .n-popover-shared--show-arrow [center-arrow]
        [popover-transition-*]
      tabindex = 0 (focusable)
      style = 23 menu vars → --n-menu-box-shadow → [width?] → 15 popover vars
              (--n-padding = 0, upstream builtinThemeOverrides)
      └─ NUI.SelectMenu rows (header / options-or-empty / action) — see there

There is **no `n-popover` class, no `n-popover__content` wrapper, no arrow
node** — the internalRenderBody path (identical to Dropdown). The
`--show-arrow` modifier follows the popover's `mergedShowArrow =
!overlap && showArrow` (popselect omits the prop, so the default `true`
survives — present unless `overlap`, even though no arrow node renders on
this path; a margin-only cosmetic quirk; pinned).

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
import NUI.Theme.Popselect as PopselectTheme


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



-- VIEW -------------------------------------------------------------------------


{-| The `n-popselect-menu` body — the select-menu root carrying the
popover-shared classes and the 39 merged vars. Mount it inside a wrapper
that carries `placementAttribute`.
-}
view : Theme -> Options msg -> List (SelectMenu.Option msg) -> Element msg
view theme opts options =
    SelectMenu.view theme (menuOptions theme opts) options


{-| The panel assembled through `NUI.SelectMenu`'s composition seams: the
popover-shared classes ride `extraClasses` (applied after the menu's own
classes) and the merged root style rides `attributes` (applied last, so its
superset wins over the menu's own vars by last-wins). Upstream the panel
renders `NInternalSelectMenu` with `focusable` hardcoded true (root
`tabindex="0"`), and the popover's `internalRenderBody` merge lays the
shared classes and body style on top.
-}
menuOptions : Theme -> Options msg -> SelectMenu.Options msg
menuOptions theme opts =
    { size = menuSize opts.size
    , multiple = opts.multiple
    , value = opts.value
    , showCheckmark = opts.showCheckmark
    , focusable = True
    , loading = False
    , header = opts.header
    , action = opts.action
    , empty = opts.empty
    , onToggle =
        Maybe.map
            (\update key -> update (toggleValue opts.multiple opts.cancelable opts.value key))
            opts.onUpdateValue
    , checkmarkTransition = Nothing
    , rtl = opts.rtl
    , extraClasses = popoverSharedClasses opts
    , attributes = I.cssVars (rootVars theme opts) :: opts.attributes
    }


{-| `PopselectSize` onto the menu's five-size scale (no `Tiny` upstream).
-}
menuSize : Size -> SelectMenu.Size
menuSize size =
    case size of
        Small ->
            SelectMenu.Small

        Medium ->
            SelectMenu.Medium

        Large ->
            SelectMenu.Large

        Huge ->
            SelectMenu.Huge


{-| The classes the popover's body-swap merge contributes after the menu's
own (the panel's `n-popselect-menu` first, then the `internalRenderBody`
class list, transition class last). `--show-arrow` follows the popover's
`mergedShowArrow = !overlap && showArrow` (`NUI.Popover`/`NUI.Dropdown`
convention) — popselect omits `showArrow`, so the default `true` survives:
present unless `overlap`, even though no arrow node renders on this path
(a margin-only cosmetic quirk; pinned).
-}
popoverSharedClasses : Options msg -> List String
popoverSharedClasses opts =
    [ "n-popselect-menu", "n-popover-shared" ]
        ++ I.classIf opts.rtl "n-popover--rtl"
        ++ I.classIf opts.overlap "n-popover-shared--overlap"
        ++ I.classIf (not opts.overlap) "n-popover-shared--show-arrow"
        ++ I.classIf opts.arrowPointToCenter "n-popover-shared--center-arrow"
        ++ (case opts.transition of
                Just phase ->
                    [ I.transitionClass "popover-transition" phase ]

                Nothing ->
                    []
           )



-- THEME ------------------------------------------------------------------------


{-| The merged 39 `--n-*` custom properties on the root, in order: the 23
select-menu vars, `--n-menu-box-shadow`, then `[width?]` and the 15 popover
vars with `--n-padding` overridden to `0` (upstream
`builtinThemeOverrides`; the `NUI.Tooltip` var-swap precedent). The `[width?]`
slot is `view`'s — the function takes no width and emits 23 + 1 + 15.
-}
cssVars : Theme -> Size -> List ( String, String )
cssVars theme size =
    menuVars theme size ++ popoverVars theme


{-| The style `view` attaches — `cssVars` with upstream's `width` spliced
between `--n-menu-box-shadow` and the popover vars (the popover's
`[width?, …vars]` body style merges in after the panel's own vars).
-}
rootVars : Theme -> Options msg -> List ( String, String )
rootVars theme opts =
    menuVars theme opts.size
        ++ (case opts.width of
                Just w ->
                    [ ( "width", w ) ]

                Nothing ->
                    []
           )
        ++ popoverVars theme


{-| The menu's vars plus the popselect theme's one — the panel's own style
contribution.
-}
menuVars : Theme -> Size -> List ( String, String )
menuVars theme size =
    SelectMenu.cssVars theme (menuSize size)
        ++ [ ( "--n-menu-box-shadow", (PopselectTheme.vars theme).menuBoxShadow ) ]


{-| The popover's 15 vars with `--n-padding` zeroed — upstream
`builtinThemeOverrides { padding: '0' }` (the `NUI.Tooltip` var-swap lane).
-}
popoverVars : Theme -> List ( String, String )
popoverVars theme =
    Popover.cssVars theme
        |> List.map
            (\( name, value ) ->
                if name == "--n-padding" then
                    ( name, "0" )

                else
                    ( name, value )
            )


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
