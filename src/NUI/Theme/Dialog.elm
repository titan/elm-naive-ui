module NUI.Theme.Dialog exposing (Vars, vars)

{-| Naive UI dialog theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


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
