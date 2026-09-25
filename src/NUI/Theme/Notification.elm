module NUI.Theme.Notification exposing (Vars, vars)

{-| Naive UI notification theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


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
