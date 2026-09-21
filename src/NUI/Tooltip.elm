module NUI.Tooltip exposing
    ( Options
    , Placement
    , cssVars
    , defaults
    , placementAttribute
    , placementName
    , view
    )

{-| Naive UI's `Tooltip` — upstream calls it "popover wearing waistcoat": the
`n-popover` body driven by the tooltip theme.

    import NUI.Theme as Theme
    import NUI.Tooltip exposing (defaults)

    NUI.Tooltip.view Theme.default
        defaults
        [ Element.text "A tooltip" ]

The element is the popover body (`.n-popover …` classes, Naive UI's exact CSS)
plus the `n-tooltip` marker class, with five of the popover vars overridden by
the tooltip theme: in light mode a dark bubble (`--n-color` black-ish,
`--n-text-color` the base colour); dark mode matches the popover's own colours.

**Everything in `NUI.Popover`'s docstring applies** — the caller-owned show
state / trigger / positioning, the `v-placement` wrapper contract (use
`placementAttribute`), the `--v-offset-*` note, the header/footer/scrollable
structure, `overlap` suppressing the arrow, and the transition phases. This
module only swaps the theme; see `NUI.Popover` for the full contract.

**Documented gaps** (beyond the popover's):

  - `NUI.Theme.Tooltip`'s light `color` is a pinned literal
    (`rgba(38, 38, 38, 1)`, upstream `composite(baseColor, 'rgba(0, 0, .85)')`
    computed at the default theme) — overriding `common.baseColor` does not
    re-derive it (the toolchain convention for derived values; cf. Tag).

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Popover as Popover
import NUI.Theme exposing (Theme)
import NUI.Theme.Popover as PopoverTheme
import NUI.Theme.Tooltip as TooltipTheme


{-| The tooltip options — the popover's (upstream threads every
`popoverBaseProps` through unchanged).
-}
type alias Options msg =
    Popover.Options msg


{-| A follower placement (see `NUI.Popover.Placement`). The constructors live
in `NUI.Popover` (`Popover.Top`, `Popover.Bottom`, …) — the alias makes them
interchangeable with this module's API.
-}
type alias Placement =
    Popover.Placement


{-| The tooltip's defaults — the popover's.
-}
defaults : Options msg
defaults =
    Popover.defaults


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


{-| The tooltip body — the `n-popover` body with the `n-tooltip` marker class
and the tooltip theme's vars.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Popover.viewWithVars theme
        { opts | extraClasses = "n-tooltip" :: opts.extraClasses }
        (cssVars theme)
        children


{-| The 15 `--n-*` custom properties the tooltip body attaches — the popover's
list with `--n-padding`, `--n-border-radius`, `--n-box-shadow`, `--n-color`
and `--n-text-color` taken from the tooltip theme (upstream order).
-}
cssVars : Theme -> List ( String, String )
cssVars theme =
    let
        p =
            PopoverTheme.vars theme

        t =
            TooltipTheme.vars theme
    in
    [ ( "--n-box-shadow", t.boxShadow )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-bezier-ease-in", theme.common.cubicBezierEaseIn )
    , ( "--n-bezier-ease-out", theme.common.cubicBezierEaseOut )
    , ( "--n-font-size", p.fontSize )
    , ( "--n-text-color", t.textColor )
    , ( "--n-color", t.color )
    , ( "--n-divider-color", p.dividerColor )
    , ( "--n-border-radius", t.borderRadius )
    , ( "--n-arrow-height", p.arrowHeight )
    , ( "--n-arrow-offset", p.arrowOffset )
    , ( "--n-arrow-offset-vertical", p.arrowOffsetVertical )
    , ( "--n-padding", t.padding )
    , ( "--n-space", p.space )
    , ( "--n-space-arrow", p.spaceArrow )
    ]
