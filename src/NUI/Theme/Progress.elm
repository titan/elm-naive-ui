module NUI.Theme.Progress exposing (Vars, vars)

{-| Theme variables for the **Progress** component — the Elm counterpart of Naive UI's
`src/Progress/styles/light.ts` & `dark.ts` cssr theme (selfVars). Progress renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`fontSize` → `--n-font-size`, `fontSizeCircle` → `--n-font-size-circle`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Progress's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Progress CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`fontSize` → `--n-font-size`).
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


{-| Resolve the Progress variables for a theme — upstream `self(common)`: Light and Dark
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
