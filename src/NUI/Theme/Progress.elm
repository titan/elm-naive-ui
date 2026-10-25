module NUI.Theme.Progress exposing (Vars, vars)

{-| Theme variables for **Progress** (upstream `src/Progress/styles/light.ts` & `dark.ts`, cssr
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
    { fontSize : String
    , fontSizeCircle : String
    , fontWeightCircle : String
    , railColor : String
    , railHeight : String
    , iconSizeCircle : String
    , iconSizeLine : String
    , iconColor : String
    , iconColorInfo : String
    , iconColorSuccess : String
    , iconColorWarning : String
    , iconColorError : String
    , textColorCircle : String
    , textColorLineInner : String
    , textColorLineOuter : String
    , fillColor : String
    , fillColorInfo : String
    , fillColorSuccess : String
    , fillColorWarning : String
    , fillColorError : String
    , lineBgProcessing : String
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
    { fontSize = common.fontSize
    , fontSizeCircle = "28px"
    , fontWeightCircle = common.fontWeight
    , railColor = common.progressRailColor
    , railHeight = "8px"
    , iconSizeCircle = "36px"
    , iconSizeLine = "18px"
    , iconColor = common.infoColor
    , iconColorInfo = common.infoColor
    , iconColorSuccess = common.successColor
    , iconColorWarning = common.warningColor
    , iconColorError = common.errorColor
    , textColorCircle = common.textColor2
    , textColorLineInner = "rgb(255, 255, 255)"
    , textColorLineOuter = common.textColor2
    , fillColor = common.infoColor
    , fillColorInfo = common.infoColor
    , fillColorSuccess = common.successColor
    , fillColorWarning = common.warningColor
    , fillColorError = common.errorColor
    , lineBgProcessing = "linear-gradient(90deg, rgba(255, 255, 255, .3) 0%, rgba(255, 255, 255, .5) 100%)"
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , fontSizeCircle = "28px"
    , fontWeightCircle = common.fontWeight
    , railColor = common.progressRailColor
    , railHeight = "8px"
    , iconSizeCircle = "36px"
    , iconSizeLine = "18px"
    , iconColor = common.infoColor
    , iconColorInfo = common.infoColor
    , iconColorSuccess = common.successColor
    , iconColorWarning = common.warningColor
    , iconColorError = common.errorColor
    , textColorCircle = common.textColor2
    , textColorLineInner = "rgb(0, 0, 0)"
    , textColorLineOuter = common.textColor2
    , fillColor = common.infoColor
    , fillColorInfo = common.infoColor
    , fillColorSuccess = common.successColor
    , fillColorWarning = common.warningColor
    , fillColorError = common.errorColor
    , lineBgProcessing = "linear-gradient(90deg, rgba(255, 255, 255, .3) 0%, rgba(255, 255, 255, .5) 100%)"
    }
