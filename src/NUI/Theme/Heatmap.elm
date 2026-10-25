module NUI.Theme.Heatmap exposing (Vars, vars)

{-| Theme variables for the **Heatmap** component — the Elm counterpart of Naive UI's
`src/Heatmap/styles/light.ts` & `dark.ts` cssr theme (selfVars). Heatmap renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`activeColors` → `--n-active-colors`, `borderRadius` → `--n-border-radius`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Heatmap's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Heatmap CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`activeColors` → `--n-active-colors`).
-}
type alias Vars =
    { activeColors : List String
    , borderRadius : String
    , borderColor : String
    , textColor : String
    , mininumColor : String
    , fontWeight : String
    , loadingColorStart : String
    , loadingColorEnd : String
    , rectSizeSmall : String
    , rectSizeMedium : String
    , rectSizeLarge : String
    , borderRadiusSmall : String
    , borderRadiusMedium : String
    , borderRadiusLarge : String
    , xGapSmall : String
    , xGapMedium : String
    , xGapLarge : String
    , yGapSmall : String
    , yGapMedium : String
    , yGapLarge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    }


{-| Resolve the Heatmap variables for a theme — upstream `self(common)`: Light and Dark
modes each get their own palette, values drawn from `theme.common`.
-}
vars : Theme -> Vars
vars theme =
    case theme.mode of
        Theme.Light ->
            light theme.common

        Theme.Dark ->
            dark theme.common


light : Common -> Vars
light common =
    { activeColors = [ "#9be9a8", "#40c463", "#30a14e", "#216e39" ]
    , borderRadius = common.borderRadius
    , borderColor = common.cardColor
    , textColor = common.textColor2
    , mininumColor = common.buttonColor2Hover
    , fontWeight = common.fontWeight
    , loadingColorStart = "rgba(0, 0, 0, 0.06)"
    , loadingColorEnd = "rgba(0, 0, 0, 0.12)"
    , rectSizeSmall = "10px"
    , rectSizeMedium = "11px"
    , rectSizeLarge = "12px"
    , borderRadiusSmall = "2px"
    , borderRadiusMedium = "2px"
    , borderRadiusLarge = "2px"
    , xGapSmall = "2px"
    , xGapMedium = "3px"
    , xGapLarge = "3px"
    , yGapSmall = "2px"
    , yGapMedium = "3px"
    , yGapLarge = "3px"
    , fontSizeSmall = common.fontSizeTiny
    , fontSizeMedium = common.fontSizeMini
    , fontSizeLarge = common.fontSizeSmall
    }


dark : Common -> Vars
dark common =
    { activeColors = [ "#0d4429", "#006d32", "#26a641", "#39d353" ]
    , borderRadius = common.borderRadius
    , borderColor = common.cardColor
    , textColor = common.textColor2
    , mininumColor = "rgba(255, 255, 255, 0.1)"
    , fontWeight = common.fontWeight
    , loadingColorStart = "rgba(255, 255, 255, 0.12)"
    , loadingColorEnd = "rgba(255, 255, 255, 0.18)"
    , rectSizeSmall = "10px"
    , rectSizeMedium = "11px"
    , rectSizeLarge = "12px"
    , borderRadiusSmall = "2px"
    , borderRadiusMedium = "2px"
    , borderRadiusLarge = "2px"
    , xGapSmall = "2px"
    , xGapMedium = "3px"
    , xGapLarge = "3px"
    , yGapSmall = "2px"
    , yGapMedium = "3px"
    , yGapLarge = "3px"
    , fontSizeSmall = common.fontSizeTiny
    , fontSizeMedium = common.fontSizeMini
    , fontSizeLarge = common.fontSizeSmall
    }
