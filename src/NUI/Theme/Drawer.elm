module NUI.Theme.Drawer exposing (Vars, vars)

{-| Naive UI drawer theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { bodyPadding : String
    , borderRadius : String
    , headerPadding : String
    , footerPadding : String
    , color : String
    , textColor : String
    , titleTextColor : String
    , titleFontSize : String
    , titleFontWeight : String
    , boxShadow : String
    , lineHeight : String
    , headerBorderBottom : String
    , footerBorderTop : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeSize : String
    , closeIconSize : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeBorderRadius : String
    , resizableTriggerColorHover : String
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
    { bodyPadding = "16px 24px"
    , borderRadius = common.borderRadius
    , headerPadding = "16px 24px"
    , footerPadding = "16px 24px"
    , color = common.modalColor
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , titleFontSize = "18px"
    , titleFontWeight = common.fontWeightStrong
    , boxShadow = common.boxShadow3
    , lineHeight = common.lineHeight
    , headerBorderBottom = "1px solid rgb(239, 239, 245)"
    , footerBorderTop = "1px solid rgb(239, 239, 245)"
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeSize = "22px"
    , closeIconSize = "18px"
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , resizableTriggerColorHover = common.primaryColorHover
    }


dark : Common -> Vars
dark common =
    { bodyPadding = "16px 24px"
    , borderRadius = common.borderRadius
    , headerPadding = "16px 24px"
    , footerPadding = "16px 24px"
    , color = common.modalColor
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , titleFontSize = "18px"
    , titleFontWeight = common.fontWeightStrong
    , boxShadow = common.boxShadow3
    , lineHeight = common.lineHeight
    , headerBorderBottom = "1px solid rgba(255, 255, 255, 0.09)"
    , footerBorderTop = "1px solid rgba(255, 255, 255, 0.09)"
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeSize = "22px"
    , closeIconSize = "18px"
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , resizableTriggerColorHover = common.primaryColorHover
    }
