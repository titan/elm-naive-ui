module NUI.Theme.Tag exposing (Vars, vars)


{-| Naive UI tag theme variables.
-}


import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { closeIconSizeTiny : String
    , closeIconSizeSmall : String
    , closeIconSizeMedium : String
    , closeIconSizeLarge : String
    , closeSizeTiny : String
    , closeSizeSmall : String
    , closeSizeMedium : String
    , closeSizeLarge : String
    , padding : String
    , closeMargin : String
    , closeBorderRadius : String
    , heightTiny : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , borderRadius : String
    , opacityDisabled : String
    , fontSizeTiny : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontWeightStrong : String
    , textColorCheckable : String
    , textColorHoverCheckable : String
    , textColorPressedCheckable : String
    , textColorChecked : String
    , colorCheckable : String
    , colorHoverCheckable : String
    , colorPressedCheckable : String
    , colorChecked : String
    , colorCheckedHover : String
    , colorCheckedPressed : String
    , border : String
    , textColor : String
    , color : String
    , colorBordered : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeColorHover : String
    , closeColorPressed : String
    , borderPrimary : String
    , textColorPrimary : String
    , colorPrimary : String
    , colorBorderedPrimary : String
    , closeIconColorPrimary : String
    , closeIconColorHoverPrimary : String
    , closeIconColorPressedPrimary : String
    , closeColorHoverPrimary : String
    , closeColorPressedPrimary : String
    , borderInfo : String
    , textColorInfo : String
    , colorInfo : String
    , colorBorderedInfo : String
    , closeIconColorInfo : String
    , closeIconColorHoverInfo : String
    , closeIconColorPressedInfo : String
    , closeColorHoverInfo : String
    , closeColorPressedInfo : String
    , borderSuccess : String
    , textColorSuccess : String
    , colorSuccess : String
    , colorBorderedSuccess : String
    , closeIconColorSuccess : String
    , closeIconColorHoverSuccess : String
    , closeIconColorPressedSuccess : String
    , closeColorHoverSuccess : String
    , closeColorPressedSuccess : String
    , borderWarning : String
    , textColorWarning : String
    , colorWarning : String
    , colorBorderedWarning : String
    , closeIconColorWarning : String
    , closeIconColorHoverWarning : String
    , closeIconColorPressedWarning : String
    , closeColorHoverWarning : String
    , closeColorPressedWarning : String
    , borderError : String
    , textColorError : String
    , colorError : String
    , colorBorderedError : String
    , closeIconColorError : String
    , closeIconColorHoverError : String
    , closeIconColorPressedError : String
    , closeColorHoverError : String
    , closeColorPressedError : String
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
    { closeIconSizeTiny = common.fontSizeMini
    , closeIconSizeSmall = common.fontSizeMini
    , closeIconSizeMedium = common.fontSize
    , closeIconSizeLarge = common.fontSize
    , closeSizeTiny = common.fontSizeHuge
    , closeSizeSmall = common.fontSizeHuge
    , closeSizeMedium = "18px"
    , closeSizeLarge = "18px"
    , padding = "0 7px"
    , closeMargin = "0 0 0 4px"
    , closeBorderRadius = common.borderRadiusSmall
    , heightTiny = common.fontSizeHuge
    , heightSmall = common.heightTiny
    , heightMedium = common.heightSmall
    , heightLarge = common.heightMedium
    , borderRadius = common.borderRadiusSmall
    , opacityDisabled = common.opacityDisabled
    , fontSizeTiny = common.fontSizeMini
    , fontSizeSmall = common.fontSizeMini
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSize
    , fontWeightStrong = common.fontWeightStrong
    , textColorCheckable = common.textColor2
    , textColorHoverCheckable = common.textColor2
    , textColorPressedCheckable = common.textColor2
    , textColorChecked = common.baseColor
    , colorCheckable = "#0000"
    , colorHoverCheckable = common.buttonColor2Hover
    , colorPressedCheckable = common.buttonColor2Pressed
    , colorChecked = common.primaryColor
    , colorCheckedHover = common.primaryColorHover
    , colorCheckedPressed = common.primaryColorPressed
    , border = "1px solid rgb(224, 224, 230)"
    , textColor = common.textColor2
    , color = common.tagColor
    , colorBordered = "rgb(250, 250, 252)"
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColor
    , closeIconColorPressed = common.closeIconColor
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , borderPrimary = "1px solid rgba(24, 160, 88, 0.3)"
    , textColorPrimary = common.primaryColor
    , colorPrimary = "rgba(24, 160, 88, 0.12)"
    , colorBorderedPrimary = "rgba(24, 160, 88, 0.1)"
    , closeIconColorPrimary = "#18a058"
    , closeIconColorHoverPrimary = "#18a058"
    , closeIconColorPressedPrimary = "#18a058"
    , closeColorHoverPrimary = "rgba(24, 160, 88, 0.12)"
    , closeColorPressedPrimary = "rgba(24, 160, 88, 0.18)"
    , borderInfo = "1px solid rgba(32, 128, 240, 0.3)"
    , textColorInfo = common.infoColor
    , colorInfo = "rgba(32, 128, 240, 0.12)"
    , colorBorderedInfo = "rgba(32, 128, 240, 0.1)"
    , closeIconColorInfo = "#2080f0"
    , closeIconColorHoverInfo = "#2080f0"
    , closeIconColorPressedInfo = "#2080f0"
    , closeColorHoverInfo = "rgba(32, 128, 240, 0.12)"
    , closeColorPressedInfo = "rgba(32, 128, 240, 0.18)"
    , borderSuccess = "1px solid rgba(24, 160, 88, 0.3)"
    , textColorSuccess = common.primaryColor
    , colorSuccess = "rgba(24, 160, 88, 0.12)"
    , colorBorderedSuccess = "rgba(24, 160, 88, 0.1)"
    , closeIconColorSuccess = "#18a058"
    , closeIconColorHoverSuccess = "#18a058"
    , closeIconColorPressedSuccess = "#18a058"
    , closeColorHoverSuccess = "rgba(24, 160, 88, 0.12)"
    , closeColorPressedSuccess = "rgba(24, 160, 88, 0.18)"
    , borderWarning = "1px solid rgba(240, 160, 32, 0.35)"
    , textColorWarning = common.warningColor
    , colorWarning = "rgba(240, 160, 32, 0.15)"
    , colorBorderedWarning = "rgba(240, 160, 32, 0.12)"
    , closeIconColorWarning = "#f0a020"
    , closeIconColorHoverWarning = "#f0a020"
    , closeIconColorPressedWarning = "#f0a020"
    , closeColorHoverWarning = "rgba(240, 160, 32, 0.12)"
    , closeColorPressedWarning = "rgba(240, 160, 32, 0.18)"
    , borderError = "1px solid rgba(208, 48, 80, 0.23)"
    , textColorError = common.errorColor
    , colorError = "rgba(208, 48, 80, 0.1)"
    , colorBorderedError = "rgba(208, 48, 80, 0.08)"
    , closeIconColorError = "#d03050"
    , closeIconColorHoverError = "#d03050"
    , closeIconColorPressedError = "#d03050"
    , closeColorHoverError = "rgba(208, 48, 80, 0.12)"
    , closeColorPressedError = "rgba(208, 48, 80, 0.18)"
    }


dark : Common -> Vars
dark common =
    { closeIconSizeTiny = common.fontSizeMini
    , closeIconSizeSmall = common.fontSizeMini
    , closeIconSizeMedium = common.fontSize
    , closeIconSizeLarge = common.fontSize
    , closeSizeTiny = common.fontSizeHuge
    , closeSizeSmall = common.fontSizeHuge
    , closeSizeMedium = "18px"
    , closeSizeLarge = "18px"
    , padding = "0 7px"
    , closeMargin = "0 0 0 4px"
    , closeBorderRadius = common.borderRadiusSmall
    , heightTiny = common.fontSizeHuge
    , heightSmall = common.heightTiny
    , heightMedium = common.heightSmall
    , heightLarge = common.heightMedium
    , borderRadius = common.borderRadiusSmall
    , opacityDisabled = common.opacityDisabled
    , fontSizeTiny = common.fontSizeMini
    , fontSizeSmall = common.fontSizeMini
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSize
    , fontWeightStrong = common.fontWeightStrong
    , textColorCheckable = common.textColor2
    , textColorHoverCheckable = common.textColor2
    , textColorPressedCheckable = common.textColor2
    , textColorChecked = common.baseColor
    , colorCheckable = "#0000"
    , colorHoverCheckable = common.buttonColor2Hover
    , colorPressedCheckable = common.buttonColor2Pressed
    , colorChecked = common.primaryColor
    , colorCheckedHover = common.primaryColorHover
    , colorCheckedPressed = common.primaryColorPressed
    , border = "1px solid rgba(255, 255, 255, 0.24)"
    , textColor = common.textColor2
    , color = common.tagColor
    , colorBordered = "#0000"
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColor
    , closeIconColorPressed = common.closeIconColor
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , borderPrimary = "1px solid rgba(99, 226, 183, 0.3)"
    , textColorPrimary = common.primaryColor
    , colorPrimary = "rgba(99, 226, 183, 0.16)"
    , colorBorderedPrimary = "#0000"
    , closeIconColorPrimary = "rgba(69, 158, 128, 1)"
    , closeIconColorHoverPrimary = "rgba(69, 158, 128, 1)"
    , closeIconColorPressedPrimary = "rgba(69, 158, 128, 1)"
    , closeColorHoverPrimary = "rgba(99, 226, 183, 0.16)"
    , closeColorPressedPrimary = "rgba(99, 226, 183, 0.12)"
    , borderInfo = "1px solid rgba(112, 192, 232, 0.3)"
    , textColorInfo = common.infoColor
    , colorInfo = "rgba(112, 192, 232, 0.16)"
    , colorBorderedInfo = "#0000"
    , closeIconColorInfo = "rgba(112, 192, 232, 0.7)"
    , closeIconColorHoverInfo = "rgba(112, 192, 232, 0.7)"
    , closeIconColorPressedInfo = "rgba(112, 192, 232, 0.7)"
    , closeColorHoverInfo = "rgba(112, 192, 232, 0.16)"
    , closeColorPressedInfo = "rgba(112, 192, 232, 0.12)"
    , borderSuccess = "1px solid rgba(99, 226, 183, 0.3)"
    , textColorSuccess = common.primaryColor
    , colorSuccess = "rgba(99, 226, 183, 0.16)"
    , colorBorderedSuccess = "#0000"
    , closeIconColorSuccess = "rgba(99, 226, 183, 0.7)"
    , closeIconColorHoverSuccess = "rgba(99, 226, 183, 0.7)"
    , closeIconColorPressedSuccess = "rgba(99, 226, 183, 0.7)"
    , closeColorHoverSuccess = "rgba(99, 226, 183, 0.16)"
    , closeColorPressedSuccess = "rgba(99, 226, 183, 0.12)"
    , borderWarning = "1px solid rgba(242, 201, 125, 0.3)"
    , textColorWarning = common.warningColor
    , colorWarning = "rgba(242, 201, 125, 0.16)"
    , colorBorderedWarning = "#0000"
    , closeIconColorWarning = "rgba(242, 201, 125, 0.7)"
    , closeIconColorHoverWarning = "rgba(242, 201, 125, 0.7)"
    , closeIconColorPressedWarning = "rgba(242, 201, 125, 0.7)"
    , closeColorHoverWarning = "rgba(242, 201, 125, 0.16)"
    , closeColorPressedWarning = "rgba(242, 201, 125, 0.11)"
    , borderError = "1px solid rgba(232, 128, 128, 0.3)"
    , textColorError = common.errorColor
    , colorError = "rgba(232, 128, 128, 0.16)"
    , colorBorderedError = "#0000"
    , closeIconColorError = "rgba(232, 128, 128, 0.7)"
    , closeIconColorHoverError = "rgba(232, 128, 128, 0.7)"
    , closeIconColorPressedError = "rgba(232, 128, 128, 0.7)"
    , closeColorHoverError = "rgba(232, 128, 128, 0.16)"
    , closeColorPressedError = "rgba(232, 128, 128, 0.12)"
    }
