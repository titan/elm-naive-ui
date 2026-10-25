module NUI.Theme.Dialog exposing (Vars, vars)

{-| Theme variables for the **Dialog** component — the Elm counterpart of Naive UI's
`src/Dialog/styles/light.ts` & `dark.ts` cssr theme (selfVars). Dialog renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`titleFontSize` → `--n-title-font-size`, `padding` → `--n-padding`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Dialog's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Dialog CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`titleFontSize` → `--n-title-font-size`).
-}
type alias Vars =
    { titleFontSize : String
    , padding : String
    , iconSize : String
    , actionSpace : String
    , contentMargin : String
    , iconMargin : String
    , iconMarginIconTop : String
    , closeSize : String
    , closeIconSize : String
    , closeMargin : String
    , closeMarginIconTop : String
    , fontSize : String
    , lineHeight : String
    , border : String
    , titleTextColor : String
    , textColor : String
    , color : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeBorderRadius : String
    , iconColor : String
    , iconColorInfo : String
    , iconColorSuccess : String
    , iconColorWarning : String
    , iconColorError : String
    , borderRadius : String
    , titleFontWeight : String
    }


{-| Resolve the Dialog variables for a theme — upstream `self(common)`: Light and Dark
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
    { titleFontSize = "18px"
    , padding = "16px 28px 20px 28px"
    , iconSize = "28px"
    , actionSpace = "12px"
    , contentMargin = "8px 0 16px 0"
    , iconMargin = "0 4px 0 0"
    , iconMarginIconTop = "4px 0 8px 0"
    , closeSize = "22px"
    , closeIconSize = "18px"
    , closeMargin = "20px 26px 0 0"
    , closeMarginIconTop = "10px 16px 0 0"
    , fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , border = "1px solid rgb(239, 239, 245)"
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , color = common.modalColor
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeBorderRadius = common.borderRadius
    , iconColor = common.primaryColor
    , iconColorInfo = common.infoColor
    , iconColorSuccess = common.successColor
    , iconColorWarning = common.warningColor
    , iconColorError = common.errorColor
    , borderRadius = common.borderRadius
    , titleFontWeight = common.fontWeightStrong
    }


dark : Common -> Vars
dark common =
    { titleFontSize = "18px"
    , padding = "16px 28px 20px 28px"
    , iconSize = "28px"
    , actionSpace = "12px"
    , contentMargin = "8px 0 16px 0"
    , iconMargin = "0 4px 0 0"
    , iconMarginIconTop = "4px 0 8px 0"
    , closeSize = "22px"
    , closeIconSize = "18px"
    , closeMargin = "20px 26px 0 0"
    , closeMarginIconTop = "10px 16px 0 0"
    , fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , border = "1px solid rgba(255, 255, 255, 0.09)"
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , color = common.modalColor
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeBorderRadius = common.borderRadius
    , iconColor = common.primaryColor
    , iconColorInfo = common.infoColor
    , iconColorSuccess = common.successColor
    , iconColorWarning = common.warningColor
    , iconColorError = common.errorColor
    , borderRadius = common.borderRadius
    , titleFontWeight = common.fontWeightStrong
    }
