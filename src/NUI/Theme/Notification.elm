module NUI.Theme.Notification exposing (Vars, vars)

{-| Theme variables for the **Notification** component — the Elm counterpart of Naive UI's
`src/Notification/styles/light.ts` & `dark.ts` cssr theme (selfVars). Notification renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`closeMargin` → `--n-close-margin`, `closeSize` → `--n-close-size`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Notification's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Notification CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`closeMargin` → `--n-close-margin`).
-}
type alias Vars =
    { closeMargin : String
    , closeSize : String
    , closeIconSize : String
    , width : String
    , padding : String
    , titleFontSize : String
    , metaFontSize : String
    , descriptionFontSize : String
    , borderRadius : String
    , lineHeight : String
    , fontSize : String
    , headerFontWeight : String
    , iconColor : String
    , iconColorSuccess : String
    , iconColorInfo : String
    , iconColorWarning : String
    , iconColorError : String
    , color : String
    , textColor : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeBorderRadius : String
    , closeColorHover : String
    , closeColorPressed : String
    , headerTextColor : String
    , descriptionTextColor : String
    , actionTextColor : String
    , boxShadow : String
    }


{-| Resolve the Notification variables for a theme — upstream `self(common)`: Light and Dark
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
    { closeMargin = "16px 12px"
    , closeSize = "20px"
    , closeIconSize = "16px"
    , width = "365px"
    , padding = "16px"
    , titleFontSize = "16px"
    , metaFontSize = "12px"
    , descriptionFontSize = "12px"
    , borderRadius = common.borderRadius
    , lineHeight = common.lineHeight
    , fontSize = common.fontSize
    , headerFontWeight = common.fontWeightStrong
    , iconColor = common.textColor2
    , iconColorSuccess = common.successColor
    , iconColorInfo = common.infoColor
    , iconColorWarning = common.warningColor
    , iconColorError = common.errorColor
    , color = common.popoverColor
    , textColor = common.textColor2
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeBorderRadius = common.borderRadius
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , headerTextColor = common.textColor1
    , descriptionTextColor = common.textColor3
    , actionTextColor = common.textColor2
    , boxShadow = common.boxShadow2
    }


dark : Common -> Vars
dark common =
    { closeMargin = "16px 12px"
    , closeSize = "20px"
    , closeIconSize = "16px"
    , width = "365px"
    , padding = "16px"
    , titleFontSize = "16px"
    , metaFontSize = "12px"
    , descriptionFontSize = "12px"
    , borderRadius = common.borderRadius
    , lineHeight = common.lineHeight
    , fontSize = common.fontSize
    , headerFontWeight = common.fontWeightStrong
    , iconColor = common.textColor2
    , iconColorSuccess = common.successColor
    , iconColorInfo = common.infoColor
    , iconColorWarning = common.warningColor
    , iconColorError = common.errorColor
    , color = common.popoverColor
    , textColor = common.textColor2
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeBorderRadius = common.borderRadius
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , headerTextColor = common.textColor1
    , descriptionTextColor = common.textColor3
    , actionTextColor = common.textColor2
    , boxShadow = common.boxShadow2
    }
