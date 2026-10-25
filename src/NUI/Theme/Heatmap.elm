module NUI.Theme.Heatmap exposing (Vars, vars)

{-| Theme variables for **Heatmap** (upstream `src/Heatmap/styles/light.ts` & `dark.ts`, cssr
selfVars). Fields map 1:1 onto the component's `--n-*` custom properties
(kebab-case of the field name). `vars` resolves the light/dark palette from
`theme.mode` + `theme.common` — upstream's `self(common)`; override individual
fields to customise.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties this component's CSS consumes, as one record.
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


{-| Resolve this component's variables for a theme (see the module doc).
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
