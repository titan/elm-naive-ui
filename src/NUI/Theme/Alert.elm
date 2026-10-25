module NUI.Theme.Alert exposing (Vars, vars)

{-| Theme variables for the **Alert** component — the Elm counterpart of Naive UI's
`src/Alert/styles/light.ts` & `dark.ts` cssr theme (selfVars). Alert renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`iconMargin` → `--n-icon-margin`, `iconMarginRtl` → `--n-icon-margin-rtl`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Alert's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Alert CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`iconMargin` → `--n-icon-margin`).
-}
type alias Vars =
    { iconMargin : String
    , iconMarginRtl : String
    , iconSize : String
    , closeIconSize : String
    , closeSize : String
    , closeMargin : String
    , closeMarginRtl : String
    , padding : String
    , fontSize : String
    , lineHeight : String
    , titleFontWeight : String
    , borderRadius : String
    , border : String
    , color : String
    , titleTextColor : String
    , iconColor : String
    , contentTextColor : String
    , closeBorderRadius : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , borderInfo : String
    , colorInfo : String
    , titleTextColorInfo : String
    , iconColorInfo : String
    , contentTextColorInfo : String
    , closeColorHoverInfo : String
    , closeColorPressedInfo : String
    , closeIconColorInfo : String
    , closeIconColorHoverInfo : String
    , closeIconColorPressedInfo : String
    , borderSuccess : String
    , colorSuccess : String
    , titleTextColorSuccess : String
    , iconColorSuccess : String
    , contentTextColorSuccess : String
    , closeColorHoverSuccess : String
    , closeColorPressedSuccess : String
    , closeIconColorSuccess : String
    , closeIconColorHoverSuccess : String
    , closeIconColorPressedSuccess : String
    , borderWarning : String
    , colorWarning : String
    , titleTextColorWarning : String
    , iconColorWarning : String
    , contentTextColorWarning : String
    , closeColorHoverWarning : String
    , closeColorPressedWarning : String
    , closeIconColorWarning : String
    , closeIconColorHoverWarning : String
    , closeIconColorPressedWarning : String
    , borderError : String
    , colorError : String
    , titleTextColorError : String
    , iconColorError : String
    , contentTextColorError : String
    , closeColorHoverError : String
    , closeColorPressedError : String
    , closeIconColorError : String
    , closeIconColorHoverError : String
    , closeIconColorPressedError : String
    }


{-| Resolve the Alert variables for a theme — upstream `self(common)`: Light and Dark
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
    { iconMargin = "11px 8px 0 12px"
    , iconMarginRtl = "11px 12px 0 8px"
    , iconSize = "24px"
    , closeIconSize = "16px"
    , closeSize = "20px"
    , closeMargin = "13px 14px 0 0"
    , closeMarginRtl = "13px 0 0 14px"
    , padding = "13px"
    , fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , titleFontWeight = common.fontWeightStrong
    , borderRadius = common.borderRadius
    , border = "1px solid rgb(239, 239, 245)"
    , color = common.actionColor
    , titleTextColor = common.textColor1
    , iconColor = common.textColor2
    , contentTextColor = common.textColor2
    , closeBorderRadius = common.borderRadius
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , borderInfo = "1px solid rgba(199, 223, 251, 1)"
    , colorInfo = "rgba(237, 245, 254, 1)"
    , titleTextColorInfo = common.textColor1
    , iconColorInfo = common.infoColor
    , contentTextColorInfo = common.textColor2
    , closeColorHoverInfo = common.closeColorHover
    , closeColorPressedInfo = common.closeColorPressed
    , closeIconColorInfo = common.closeIconColor
    , closeIconColorHoverInfo = common.closeIconColorHover
    , closeIconColorPressedInfo = common.closeIconColorPressed
    , borderSuccess = "1px solid rgba(197, 231, 213, 1)"
    , colorSuccess = "rgba(237, 247, 242, 1)"
    , titleTextColorSuccess = common.textColor1
    , iconColorSuccess = common.successColor
    , contentTextColorSuccess = common.textColor2
    , closeColorHoverSuccess = common.closeColorHover
    , closeColorPressedSuccess = common.closeColorPressed
    , closeIconColorSuccess = common.closeIconColor
    , closeIconColorHoverSuccess = common.closeIconColorHover
    , closeIconColorPressedSuccess = common.closeIconColorPressed
    , borderWarning = "1px solid rgba(250, 224, 181, 1)"
    , colorWarning = "rgba(254, 247, 237, 1)"
    , titleTextColorWarning = common.textColor1
    , iconColorWarning = common.warningColor
    , contentTextColorWarning = common.textColor2
    , closeColorHoverWarning = common.closeColorHover
    , closeColorPressedWarning = common.closeColorPressed
    , closeIconColorWarning = common.closeIconColor
    , closeIconColorHoverWarning = common.closeIconColorHover
    , closeIconColorPressedWarning = common.closeIconColorPressed
    , borderError = "1px solid rgba(243, 203, 211, 1)"
    , colorError = "rgba(251, 238, 241, 1)"
    , titleTextColorError = common.textColor1
    , iconColorError = common.errorColor
    , contentTextColorError = common.textColor2
    , closeColorHoverError = common.closeColorHover
    , closeColorPressedError = common.closeColorPressed
    , closeIconColorError = common.closeIconColor
    , closeIconColorHoverError = common.closeIconColorHover
    , closeIconColorPressedError = common.closeIconColorPressed
    }


dark : Common -> Vars
dark common =
    { iconMargin = "11px 8px 0 12px"
    , iconMarginRtl = "11px 12px 0 8px"
    , iconSize = "24px"
    , closeIconSize = "16px"
    , closeSize = "20px"
    , closeMargin = "13px 14px 0 0"
    , closeMarginRtl = "13px 0 0 14px"
    , padding = "13px"
    , fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , titleFontWeight = common.fontWeightStrong
    , borderRadius = common.borderRadius
    , border = "1px solid rgba(255, 255, 255, 0.09)"
    , color = common.inputColor
    , titleTextColor = common.textColor1
    , iconColor = common.textColor2
    , contentTextColor = common.textColor2
    , closeBorderRadius = common.borderRadius
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , borderInfo = "1px solid rgba(56, 137, 197, 0.35)"
    , colorInfo = "rgba(56, 137, 197, 0.25)"
    , titleTextColorInfo = common.textColor1
    , iconColorInfo = common.infoColorSuppl
    , contentTextColorInfo = common.textColor2
    , closeColorHoverInfo = common.closeColorHover
    , closeColorPressedInfo = common.closeColorPressed
    , closeIconColorInfo = common.closeIconColor
    , closeIconColorHoverInfo = common.closeIconColorHover
    , closeIconColorPressedInfo = common.closeIconColorPressed
    , borderSuccess = "1px solid rgba(42, 148, 125, 0.35)"
    , colorSuccess = "rgba(42, 148, 125, 0.25)"
    , titleTextColorSuccess = common.textColor1
    , iconColorSuccess = common.successColorSuppl
    , contentTextColorSuccess = common.textColor2
    , closeColorHoverSuccess = common.closeColorHover
    , closeColorPressedSuccess = common.closeColorPressed
    , closeIconColorSuccess = common.closeIconColor
    , closeIconColorHoverSuccess = common.closeIconColorHover
    , closeIconColorPressedSuccess = common.closeIconColorPressed
    , borderWarning = "1px solid rgba(240, 138, 0, 0.35)"
    , colorWarning = "rgba(240, 138, 0, 0.25)"
    , titleTextColorWarning = common.textColor1
    , iconColorWarning = common.warningColorSuppl
    , contentTextColorWarning = common.textColor2
    , closeColorHoverWarning = common.closeColorHover
    , closeColorPressedWarning = common.closeColorPressed
    , closeIconColorWarning = common.closeIconColor
    , closeIconColorHoverWarning = common.closeIconColorHover
    , closeIconColorPressedWarning = common.closeIconColorPressed
    , borderError = "1px solid rgba(208, 58, 82, 0.35)"
    , colorError = "rgba(208, 58, 82, 0.25)"
    , titleTextColorError = common.textColor1
    , iconColorError = common.errorColorSuppl
    , contentTextColorError = common.textColor2
    , closeColorHoverError = common.closeColorHover
    , closeColorPressedError = common.closeColorPressed
    , closeIconColorError = common.closeIconColor
    , closeIconColorHoverError = common.closeIconColorHover
    , closeIconColorPressedError = common.closeIconColorPressed
    }
