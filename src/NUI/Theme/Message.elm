module NUI.Theme.Message exposing (Vars, vars)

{-| Theme variables for the **Message** component — the Elm counterpart of Naive UI's
`src/Message/styles/light.ts` & `dark.ts` cssr theme (selfVars). Message renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`margin` → `--n-margin`, `padding` → `--n-padding`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Message's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Message CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`margin` → `--n-margin`).
-}
type alias Vars =
    { margin : String
    , padding : String
    , maxWidth : String
    , minWidth : String
    , iconMargin : String
    , closeMargin : String
    , closeSize : String
    , closeIconSize : String
    , iconSize : String
    , fontSize : String
    , closeBorderRadius : String
    , textColor : String
    , textColorInfo : String
    , textColorSuccess : String
    , textColorError : String
    , textColorWarning : String
    , textColorLoading : String
    , color : String
    , colorInfo : String
    , colorSuccess : String
    , colorError : String
    , colorWarning : String
    , colorLoading : String
    , boxShadow : String
    , boxShadowInfo : String
    , boxShadowSuccess : String
    , boxShadowError : String
    , boxShadowWarning : String
    , boxShadowLoading : String
    , iconColor : String
    , iconColorInfo : String
    , iconColorSuccess : String
    , iconColorWarning : String
    , iconColorError : String
    , iconColorLoading : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeColorHoverInfo : String
    , closeColorPressedInfo : String
    , closeIconColorInfo : String
    , closeIconColorHoverInfo : String
    , closeIconColorPressedInfo : String
    , closeColorHoverSuccess : String
    , closeColorPressedSuccess : String
    , closeIconColorSuccess : String
    , closeIconColorHoverSuccess : String
    , closeIconColorPressedSuccess : String
    , closeColorHoverError : String
    , closeColorPressedError : String
    , closeIconColorError : String
    , closeIconColorHoverError : String
    , closeIconColorPressedError : String
    , closeColorHoverWarning : String
    , closeColorPressedWarning : String
    , closeIconColorWarning : String
    , closeIconColorHoverWarning : String
    , closeIconColorPressedWarning : String
    , closeColorHoverLoading : String
    , closeColorPressedLoading : String
    , closeIconColorLoading : String
    , closeIconColorHoverLoading : String
    , closeIconColorPressedLoading : String
    , loadingColor : String
    , lineHeight : String
    , borderRadius : String
    , border : String
    }


{-| Resolve the Message variables for a theme — upstream `self(common)`: Light and Dark
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
    { margin = "0 0 8px 0"
    , padding = "10px 20px"
    , maxWidth = "720px"
    , minWidth = "420px"
    , iconMargin = "0 10px 0 0"
    , closeMargin = "0 0 0 10px"
    , closeSize = "20px"
    , closeIconSize = "16px"
    , iconSize = "20px"
    , fontSize = "14px"
    , closeBorderRadius = common.borderRadius
    , textColor = common.textColor2
    , textColorInfo = common.textColor2
    , textColorSuccess = common.textColor2
    , textColorError = common.textColor2
    , textColorWarning = common.textColor2
    , textColorLoading = common.textColor2
    , color = common.popoverColor
    , colorInfo = common.popoverColor
    , colorSuccess = common.popoverColor
    , colorError = common.popoverColor
    , colorWarning = common.popoverColor
    , colorLoading = common.popoverColor
    , boxShadow = common.boxShadow2
    , boxShadowInfo = common.boxShadow2
    , boxShadowSuccess = common.boxShadow2
    , boxShadowError = common.boxShadow2
    , boxShadowWarning = common.boxShadow2
    , boxShadowLoading = common.boxShadow2
    , iconColor = common.textColor2
    , iconColorInfo = common.infoColor
    , iconColorSuccess = common.successColor
    , iconColorWarning = common.warningColor
    , iconColorError = common.errorColor
    , iconColorLoading = common.primaryColor
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeColorHoverInfo = common.closeColorHover
    , closeColorPressedInfo = common.closeColorPressed
    , closeIconColorInfo = common.closeIconColor
    , closeIconColorHoverInfo = common.closeIconColorHover
    , closeIconColorPressedInfo = common.closeIconColorPressed
    , closeColorHoverSuccess = common.closeColorHover
    , closeColorPressedSuccess = common.closeColorPressed
    , closeIconColorSuccess = common.closeIconColor
    , closeIconColorHoverSuccess = common.closeIconColorHover
    , closeIconColorPressedSuccess = common.closeIconColorPressed
    , closeColorHoverError = common.closeColorHover
    , closeColorPressedError = common.closeColorPressed
    , closeIconColorError = common.closeIconColor
    , closeIconColorHoverError = common.closeIconColorHover
    , closeIconColorPressedError = common.closeIconColorPressed
    , closeColorHoverWarning = common.closeColorHover
    , closeColorPressedWarning = common.closeColorPressed
    , closeIconColorWarning = common.closeIconColor
    , closeIconColorHoverWarning = common.closeIconColorHover
    , closeIconColorPressedWarning = common.closeIconColorPressed
    , closeColorHoverLoading = common.closeColorHover
    , closeColorPressedLoading = common.closeColorPressed
    , closeIconColorLoading = common.closeIconColor
    , closeIconColorHoverLoading = common.closeIconColorHover
    , closeIconColorPressedLoading = common.closeIconColorPressed
    , loadingColor = common.primaryColor
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , border = "0"
    }


dark : Common -> Vars
dark common =
    { margin = "0 0 8px 0"
    , padding = "10px 20px"
    , maxWidth = "720px"
    , minWidth = "420px"
    , iconMargin = "0 10px 0 0"
    , closeMargin = "0 0 0 10px"
    , closeSize = "20px"
    , closeIconSize = "16px"
    , iconSize = "20px"
    , fontSize = "14px"
    , closeBorderRadius = common.borderRadius
    , textColor = common.textColor2
    , textColorInfo = common.textColor2
    , textColorSuccess = common.textColor2
    , textColorError = common.textColor2
    , textColorWarning = common.textColor2
    , textColorLoading = common.textColor2
    , color = common.popoverColor
    , colorInfo = common.popoverColor
    , colorSuccess = common.popoverColor
    , colorError = common.popoverColor
    , colorWarning = common.popoverColor
    , colorLoading = common.popoverColor
    , boxShadow = common.boxShadow2
    , boxShadowInfo = common.boxShadow2
    , boxShadowSuccess = common.boxShadow2
    , boxShadowError = common.boxShadow2
    , boxShadowWarning = common.boxShadow2
    , boxShadowLoading = common.boxShadow2
    , iconColor = common.textColor2
    , iconColorInfo = common.infoColor
    , iconColorSuccess = common.successColor
    , iconColorWarning = common.warningColor
    , iconColorError = common.errorColor
    , iconColorLoading = common.primaryColor
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeColorHoverInfo = common.closeColorHover
    , closeColorPressedInfo = common.closeColorPressed
    , closeIconColorInfo = common.closeIconColor
    , closeIconColorHoverInfo = common.closeIconColorHover
    , closeIconColorPressedInfo = common.closeIconColorPressed
    , closeColorHoverSuccess = common.closeColorHover
    , closeColorPressedSuccess = common.closeColorPressed
    , closeIconColorSuccess = common.closeIconColor
    , closeIconColorHoverSuccess = common.closeIconColorHover
    , closeIconColorPressedSuccess = common.closeIconColorPressed
    , closeColorHoverError = common.closeColorHover
    , closeColorPressedError = common.closeColorPressed
    , closeIconColorError = common.closeIconColor
    , closeIconColorHoverError = common.closeIconColorHover
    , closeIconColorPressedError = common.closeIconColorPressed
    , closeColorHoverWarning = common.closeColorHover
    , closeColorPressedWarning = common.closeColorPressed
    , closeIconColorWarning = common.closeIconColor
    , closeIconColorHoverWarning = common.closeIconColorHover
    , closeIconColorPressedWarning = common.closeIconColorPressed
    , closeColorHoverLoading = common.closeColorHover
    , closeColorPressedLoading = common.closeColorPressed
    , closeIconColorLoading = common.closeIconColor
    , closeIconColorHoverLoading = common.closeIconColorHover
    , closeIconColorPressedLoading = common.closeIconColorPressed
    , loadingColor = common.primaryColor
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , border = "0"
    }
