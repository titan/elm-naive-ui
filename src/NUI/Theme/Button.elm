module NUI.Theme.Button exposing (Vars, vars)

{-| Naive UI button theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { paddingTiny : String
    , paddingSmall : String
    , paddingMedium : String
    , paddingLarge : String
    , paddingRoundTiny : String
    , paddingRoundSmall : String
    , paddingRoundMedium : String
    , paddingRoundLarge : String
    , iconMarginTiny : String
    , iconMarginSmall : String
    , iconMarginMedium : String
    , iconMarginLarge : String
    , iconSizeTiny : String
    , iconSizeSmall : String
    , iconSizeMedium : String
    , iconSizeLarge : String
    , rippleDuration : String
    , heightTiny : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , borderRadiusTiny : String
    , borderRadiusSmall : String
    , borderRadiusMedium : String
    , borderRadiusLarge : String
    , fontSizeTiny : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , opacityDisabled : String
    , colorOpacitySecondary : String
    , colorOpacitySecondaryHover : String
    , colorOpacitySecondaryPressed : String
    , colorSecondary : String
    , colorSecondaryHover : String
    , colorSecondaryPressed : String
    , colorTertiary : String
    , colorTertiaryHover : String
    , colorTertiaryPressed : String
    , colorQuaternary : String
    , colorQuaternaryHover : String
    , colorQuaternaryPressed : String
    , color : String
    , colorHover : String
    , colorPressed : String
    , colorFocus : String
    , colorDisabled : String
    , textColor : String
    , textColorTertiary : String
    , textColorHover : String
    , textColorPressed : String
    , textColorFocus : String
    , textColorDisabled : String
    , textColorText : String
    , textColorTextHover : String
    , textColorTextPressed : String
    , textColorTextFocus : String
    , textColorTextDisabled : String
    , textColorGhost : String
    , textColorGhostHover : String
    , textColorGhostPressed : String
    , textColorGhostFocus : String
    , textColorGhostDisabled : String
    , border : String
    , borderHover : String
    , borderPressed : String
    , borderFocus : String
    , borderDisabled : String
    , rippleColor : String
    , colorPrimary : String
    , colorHoverPrimary : String
    , colorPressedPrimary : String
    , colorFocusPrimary : String
    , colorDisabledPrimary : String
    , textColorPrimary : String
    , textColorHoverPrimary : String
    , textColorPressedPrimary : String
    , textColorFocusPrimary : String
    , textColorDisabledPrimary : String
    , textColorTextPrimary : String
    , textColorTextHoverPrimary : String
    , textColorTextPressedPrimary : String
    , textColorTextFocusPrimary : String
    , textColorTextDisabledPrimary : String
    , textColorGhostPrimary : String
    , textColorGhostHoverPrimary : String
    , textColorGhostPressedPrimary : String
    , textColorGhostFocusPrimary : String
    , textColorGhostDisabledPrimary : String
    , borderPrimary : String
    , borderHoverPrimary : String
    , borderPressedPrimary : String
    , borderFocusPrimary : String
    , borderDisabledPrimary : String
    , rippleColorPrimary : String
    , colorInfo : String
    , colorHoverInfo : String
    , colorPressedInfo : String
    , colorFocusInfo : String
    , colorDisabledInfo : String
    , textColorInfo : String
    , textColorHoverInfo : String
    , textColorPressedInfo : String
    , textColorFocusInfo : String
    , textColorDisabledInfo : String
    , textColorTextInfo : String
    , textColorTextHoverInfo : String
    , textColorTextPressedInfo : String
    , textColorTextFocusInfo : String
    , textColorTextDisabledInfo : String
    , textColorGhostInfo : String
    , textColorGhostHoverInfo : String
    , textColorGhostPressedInfo : String
    , textColorGhostFocusInfo : String
    , textColorGhostDisabledInfo : String
    , borderInfo : String
    , borderHoverInfo : String
    , borderPressedInfo : String
    , borderFocusInfo : String
    , borderDisabledInfo : String
    , rippleColorInfo : String
    , colorSuccess : String
    , colorHoverSuccess : String
    , colorPressedSuccess : String
    , colorFocusSuccess : String
    , colorDisabledSuccess : String
    , textColorSuccess : String
    , textColorHoverSuccess : String
    , textColorPressedSuccess : String
    , textColorFocusSuccess : String
    , textColorDisabledSuccess : String
    , textColorTextSuccess : String
    , textColorTextHoverSuccess : String
    , textColorTextPressedSuccess : String
    , textColorTextFocusSuccess : String
    , textColorTextDisabledSuccess : String
    , textColorGhostSuccess : String
    , textColorGhostHoverSuccess : String
    , textColorGhostPressedSuccess : String
    , textColorGhostFocusSuccess : String
    , textColorGhostDisabledSuccess : String
    , borderSuccess : String
    , borderHoverSuccess : String
    , borderPressedSuccess : String
    , borderFocusSuccess : String
    , borderDisabledSuccess : String
    , rippleColorSuccess : String
    , colorWarning : String
    , colorHoverWarning : String
    , colorPressedWarning : String
    , colorFocusWarning : String
    , colorDisabledWarning : String
    , textColorWarning : String
    , textColorHoverWarning : String
    , textColorPressedWarning : String
    , textColorFocusWarning : String
    , textColorDisabledWarning : String
    , textColorTextWarning : String
    , textColorTextHoverWarning : String
    , textColorTextPressedWarning : String
    , textColorTextFocusWarning : String
    , textColorTextDisabledWarning : String
    , textColorGhostWarning : String
    , textColorGhostHoverWarning : String
    , textColorGhostPressedWarning : String
    , textColorGhostFocusWarning : String
    , textColorGhostDisabledWarning : String
    , borderWarning : String
    , borderHoverWarning : String
    , borderPressedWarning : String
    , borderFocusWarning : String
    , borderDisabledWarning : String
    , rippleColorWarning : String
    , colorError : String
    , colorHoverError : String
    , colorPressedError : String
    , colorFocusError : String
    , colorDisabledError : String
    , textColorError : String
    , textColorHoverError : String
    , textColorPressedError : String
    , textColorFocusError : String
    , textColorDisabledError : String
    , textColorTextError : String
    , textColorTextHoverError : String
    , textColorTextPressedError : String
    , textColorTextFocusError : String
    , textColorTextDisabledError : String
    , textColorGhostError : String
    , textColorGhostHoverError : String
    , textColorGhostPressedError : String
    , textColorGhostFocusError : String
    , textColorGhostDisabledError : String
    , borderError : String
    , borderHoverError : String
    , borderPressedError : String
    , borderFocusError : String
    , borderDisabledError : String
    , rippleColorError : String
    , waveOpacity : String
    , fontWeight : String
    , fontWeightStrong : String
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
    { paddingTiny = "0 6px"
    , paddingSmall = "0 10px"
    , paddingMedium = "0 14px"
    , paddingLarge = "0 18px"
    , paddingRoundTiny = "0 10px"
    , paddingRoundSmall = "0 14px"
    , paddingRoundMedium = "0 18px"
    , paddingRoundLarge = "0 22px"
    , iconMarginTiny = "6px"
    , iconMarginSmall = "6px"
    , iconMarginMedium = "6px"
    , iconMarginLarge = "6px"
    , iconSizeTiny = "14px"
    , iconSizeSmall = "18px"
    , iconSizeMedium = "18px"
    , iconSizeLarge = "20px"
    , rippleDuration = ".6s"
    , heightTiny = common.heightTiny
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , borderRadiusTiny = common.borderRadius
    , borderRadiusSmall = common.borderRadius
    , borderRadiusMedium = common.borderRadius
    , borderRadiusLarge = common.borderRadius
    , fontSizeTiny = common.fontSizeTiny
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , opacityDisabled = common.opacityDisabled
    , colorOpacitySecondary = "0.16"
    , colorOpacitySecondaryHover = "0.22"
    , colorOpacitySecondaryPressed = "0.28"
    , colorSecondary = common.buttonColor2
    , colorSecondaryHover = common.buttonColor2Hover
    , colorSecondaryPressed = common.buttonColor2Pressed
    , colorTertiary = common.buttonColor2
    , colorTertiaryHover = common.buttonColor2Hover
    , colorTertiaryPressed = common.buttonColor2Pressed
    , colorQuaternary = "#0000"
    , colorQuaternaryHover = common.buttonColor2Hover
    , colorQuaternaryPressed = common.buttonColor2Pressed
    , color = "#0000"
    , colorHover = "#0000"
    , colorPressed = "#0000"
    , colorFocus = "#0000"
    , colorDisabled = "#0000"
    , textColor = common.textColor2
    , textColorTertiary = common.textColor3
    , textColorHover = common.primaryColorHover
    , textColorPressed = common.primaryColorPressed
    , textColorFocus = common.primaryColorHover
    , textColorDisabled = common.textColor2
    , textColorText = common.textColor2
    , textColorTextHover = common.primaryColorHover
    , textColorTextPressed = common.primaryColorPressed
    , textColorTextFocus = common.primaryColorHover
    , textColorTextDisabled = common.textColor2
    , textColorGhost = common.textColor2
    , textColorGhostHover = common.primaryColorHover
    , textColorGhostPressed = common.primaryColorPressed
    , textColorGhostFocus = common.primaryColorHover
    , textColorGhostDisabled = common.textColor2
    , border = "1px solid rgb(224, 224, 230)"
    , borderHover = "1px solid #36ad6a"
    , borderPressed = "1px solid #0c7a43"
    , borderFocus = "1px solid #36ad6a"
    , borderDisabled = "1px solid rgb(224, 224, 230)"
    , rippleColor = common.primaryColor
    , colorPrimary = common.primaryColor
    , colorHoverPrimary = common.primaryColorHover
    , colorPressedPrimary = common.primaryColorPressed
    , colorFocusPrimary = common.primaryColorHover
    , colorDisabledPrimary = common.primaryColor
    , textColorPrimary = common.baseColor
    , textColorHoverPrimary = common.baseColor
    , textColorPressedPrimary = common.baseColor
    , textColorFocusPrimary = common.baseColor
    , textColorDisabledPrimary = common.baseColor
    , textColorTextPrimary = common.primaryColor
    , textColorTextHoverPrimary = common.primaryColorHover
    , textColorTextPressedPrimary = common.primaryColorPressed
    , textColorTextFocusPrimary = common.primaryColorHover
    , textColorTextDisabledPrimary = common.textColor2
    , textColorGhostPrimary = common.primaryColor
    , textColorGhostHoverPrimary = common.primaryColorHover
    , textColorGhostPressedPrimary = common.primaryColorPressed
    , textColorGhostFocusPrimary = common.primaryColorHover
    , textColorGhostDisabledPrimary = common.primaryColor
    , borderPrimary = "1px solid #18a058"
    , borderHoverPrimary = "1px solid #36ad6a"
    , borderPressedPrimary = "1px solid #0c7a43"
    , borderFocusPrimary = "1px solid #36ad6a"
    , borderDisabledPrimary = "1px solid #18a058"
    , rippleColorPrimary = common.primaryColor
    , colorInfo = common.infoColor
    , colorHoverInfo = common.infoColorHover
    , colorPressedInfo = common.infoColorPressed
    , colorFocusInfo = common.infoColorHover
    , colorDisabledInfo = common.infoColor
    , textColorInfo = common.baseColor
    , textColorHoverInfo = common.baseColor
    , textColorPressedInfo = common.baseColor
    , textColorFocusInfo = common.baseColor
    , textColorDisabledInfo = common.baseColor
    , textColorTextInfo = common.infoColor
    , textColorTextHoverInfo = common.infoColorHover
    , textColorTextPressedInfo = common.infoColorPressed
    , textColorTextFocusInfo = common.infoColorHover
    , textColorTextDisabledInfo = common.textColor2
    , textColorGhostInfo = common.infoColor
    , textColorGhostHoverInfo = common.infoColorHover
    , textColorGhostPressedInfo = common.infoColorPressed
    , textColorGhostFocusInfo = common.infoColorHover
    , textColorGhostDisabledInfo = common.infoColor
    , borderInfo = "1px solid #2080f0"
    , borderHoverInfo = "1px solid #4098fc"
    , borderPressedInfo = "1px solid #1060c9"
    , borderFocusInfo = "1px solid #4098fc"
    , borderDisabledInfo = "1px solid #2080f0"
    , rippleColorInfo = common.infoColor
    , colorSuccess = common.successColor
    , colorHoverSuccess = common.successColorHover
    , colorPressedSuccess = common.successColorPressed
    , colorFocusSuccess = common.successColorHover
    , colorDisabledSuccess = common.successColor
    , textColorSuccess = common.baseColor
    , textColorHoverSuccess = common.baseColor
    , textColorPressedSuccess = common.baseColor
    , textColorFocusSuccess = common.baseColor
    , textColorDisabledSuccess = common.baseColor
    , textColorTextSuccess = common.successColor
    , textColorTextHoverSuccess = common.successColorHover
    , textColorTextPressedSuccess = common.successColorPressed
    , textColorTextFocusSuccess = common.successColorHover
    , textColorTextDisabledSuccess = common.textColor2
    , textColorGhostSuccess = common.successColor
    , textColorGhostHoverSuccess = common.successColorHover
    , textColorGhostPressedSuccess = common.successColorPressed
    , textColorGhostFocusSuccess = common.successColorHover
    , textColorGhostDisabledSuccess = common.successColor
    , borderSuccess = "1px solid #18a058"
    , borderHoverSuccess = "1px solid #36ad6a"
    , borderPressedSuccess = "1px solid #0c7a43"
    , borderFocusSuccess = "1px solid #36ad6a"
    , borderDisabledSuccess = "1px solid #18a058"
    , rippleColorSuccess = common.successColor
    , colorWarning = common.warningColor
    , colorHoverWarning = common.warningColorHover
    , colorPressedWarning = common.warningColorPressed
    , colorFocusWarning = common.warningColorHover
    , colorDisabledWarning = common.warningColor
    , textColorWarning = common.baseColor
    , textColorHoverWarning = common.baseColor
    , textColorPressedWarning = common.baseColor
    , textColorFocusWarning = common.baseColor
    , textColorDisabledWarning = common.baseColor
    , textColorTextWarning = common.warningColor
    , textColorTextHoverWarning = common.warningColorHover
    , textColorTextPressedWarning = common.warningColorPressed
    , textColorTextFocusWarning = common.warningColorHover
    , textColorTextDisabledWarning = common.textColor2
    , textColorGhostWarning = common.warningColor
    , textColorGhostHoverWarning = common.warningColorHover
    , textColorGhostPressedWarning = common.warningColorPressed
    , textColorGhostFocusWarning = common.warningColorHover
    , textColorGhostDisabledWarning = common.warningColor
    , borderWarning = "1px solid #f0a020"
    , borderHoverWarning = "1px solid #fcb040"
    , borderPressedWarning = "1px solid #c97c10"
    , borderFocusWarning = "1px solid #fcb040"
    , borderDisabledWarning = "1px solid #f0a020"
    , rippleColorWarning = common.warningColor
    , colorError = common.errorColor
    , colorHoverError = common.errorColorHover
    , colorPressedError = common.errorColorPressed
    , colorFocusError = common.errorColorHover
    , colorDisabledError = common.errorColor
    , textColorError = common.baseColor
    , textColorHoverError = common.baseColor
    , textColorPressedError = common.baseColor
    , textColorFocusError = common.baseColor
    , textColorDisabledError = common.baseColor
    , textColorTextError = common.errorColor
    , textColorTextHoverError = common.errorColorHover
    , textColorTextPressedError = common.errorColorPressed
    , textColorTextFocusError = common.errorColorHover
    , textColorTextDisabledError = common.textColor2
    , textColorGhostError = common.errorColor
    , textColorGhostHoverError = common.errorColorHover
    , textColorGhostPressedError = common.errorColorPressed
    , textColorGhostFocusError = common.errorColorHover
    , textColorGhostDisabledError = common.errorColor
    , borderError = "1px solid #d03050"
    , borderHoverError = "1px solid #de576d"
    , borderPressedError = "1px solid #ab1f3f"
    , borderFocusError = "1px solid #de576d"
    , borderDisabledError = "1px solid #d03050"
    , rippleColorError = common.errorColor
    , waveOpacity = "0.6"
    , fontWeight = common.fontWeight
    , fontWeightStrong = common.fontWeightStrong
    }


dark : Common -> Vars
dark common =
    { paddingTiny = "0 6px"
    , paddingSmall = "0 10px"
    , paddingMedium = "0 14px"
    , paddingLarge = "0 18px"
    , paddingRoundTiny = "0 10px"
    , paddingRoundSmall = "0 14px"
    , paddingRoundMedium = "0 18px"
    , paddingRoundLarge = "0 22px"
    , iconMarginTiny = "6px"
    , iconMarginSmall = "6px"
    , iconMarginMedium = "6px"
    , iconMarginLarge = "6px"
    , iconSizeTiny = "14px"
    , iconSizeSmall = "18px"
    , iconSizeMedium = "18px"
    , iconSizeLarge = "20px"
    , rippleDuration = ".6s"
    , heightTiny = common.heightTiny
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , borderRadiusTiny = common.borderRadius
    , borderRadiusSmall = common.borderRadius
    , borderRadiusMedium = common.borderRadius
    , borderRadiusLarge = common.borderRadius
    , fontSizeTiny = common.fontSizeTiny
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , opacityDisabled = common.opacityDisabled
    , colorOpacitySecondary = "0.16"
    , colorOpacitySecondaryHover = "0.2"
    , colorOpacitySecondaryPressed = "0.12"
    , colorSecondary = common.buttonColor2
    , colorSecondaryHover = common.buttonColor2Hover
    , colorSecondaryPressed = common.buttonColor2Pressed
    , colorTertiary = common.buttonColor2
    , colorTertiaryHover = common.buttonColor2Hover
    , colorTertiaryPressed = common.buttonColor2Pressed
    , colorQuaternary = "#0000"
    , colorQuaternaryHover = common.buttonColor2Hover
    , colorQuaternaryPressed = common.buttonColor2Pressed
    , color = "#0000"
    , colorHover = "#0000"
    , colorPressed = "#0000"
    , colorFocus = "#0000"
    , colorDisabled = "#0000"
    , textColor = common.textColor2
    , textColorTertiary = common.textColor3
    , textColorHover = common.primaryColorHover
    , textColorPressed = common.primaryColorPressed
    , textColorFocus = common.primaryColorHover
    , textColorDisabled = common.textColor2
    , textColorText = common.textColor2
    , textColorTextHover = common.primaryColorHover
    , textColorTextPressed = common.primaryColorPressed
    , textColorTextFocus = common.primaryColorHover
    , textColorTextDisabled = common.textColor2
    , textColorGhost = common.textColor2
    , textColorGhostHover = common.primaryColorHover
    , textColorGhostPressed = common.primaryColorPressed
    , textColorGhostFocus = common.primaryColorHover
    , textColorGhostDisabled = common.textColor2
    , border = "1px solid rgba(255, 255, 255, 0.24)"
    , borderHover = "1px solid #7fe7c4"
    , borderPressed = "1px solid #5acea7"
    , borderFocus = "1px solid #7fe7c4"
    , borderDisabled = "1px solid rgba(255, 255, 255, 0.24)"
    , rippleColor = common.primaryColor
    , colorPrimary = common.primaryColor
    , colorHoverPrimary = common.primaryColorHover
    , colorPressedPrimary = common.primaryColorPressed
    , colorFocusPrimary = common.primaryColorHover
    , colorDisabledPrimary = common.primaryColor
    , textColorPrimary = common.baseColor
    , textColorHoverPrimary = common.baseColor
    , textColorPressedPrimary = common.baseColor
    , textColorFocusPrimary = common.baseColor
    , textColorDisabledPrimary = common.baseColor
    , textColorTextPrimary = common.primaryColor
    , textColorTextHoverPrimary = common.primaryColorHover
    , textColorTextPressedPrimary = common.primaryColorPressed
    , textColorTextFocusPrimary = common.primaryColorHover
    , textColorTextDisabledPrimary = common.textColor2
    , textColorGhostPrimary = common.primaryColor
    , textColorGhostHoverPrimary = common.primaryColorHover
    , textColorGhostPressedPrimary = common.primaryColorPressed
    , textColorGhostFocusPrimary = common.primaryColorHover
    , textColorGhostDisabledPrimary = common.primaryColor
    , borderPrimary = "1px solid #63e2b7"
    , borderHoverPrimary = "1px solid #7fe7c4"
    , borderPressedPrimary = "1px solid #5acea7"
    , borderFocusPrimary = "1px solid #7fe7c4"
    , borderDisabledPrimary = "1px solid #63e2b7"
    , rippleColorPrimary = common.primaryColor
    , colorInfo = common.infoColor
    , colorHoverInfo = common.infoColorHover
    , colorPressedInfo = common.infoColorPressed
    , colorFocusInfo = common.infoColorHover
    , colorDisabledInfo = common.infoColor
    , textColorInfo = common.baseColor
    , textColorHoverInfo = common.baseColor
    , textColorPressedInfo = common.baseColor
    , textColorFocusInfo = common.baseColor
    , textColorDisabledInfo = common.baseColor
    , textColorTextInfo = common.infoColor
    , textColorTextHoverInfo = common.infoColorHover
    , textColorTextPressedInfo = common.infoColorPressed
    , textColorTextFocusInfo = common.infoColorHover
    , textColorTextDisabledInfo = common.textColor2
    , textColorGhostInfo = common.infoColor
    , textColorGhostHoverInfo = common.infoColorHover
    , textColorGhostPressedInfo = common.infoColorPressed
    , textColorGhostFocusInfo = common.infoColorHover
    , textColorGhostDisabledInfo = common.infoColor
    , borderInfo = "1px solid #70c0e8"
    , borderHoverInfo = "1px solid #8acbec"
    , borderPressedInfo = "1px solid #66afd3"
    , borderFocusInfo = "1px solid #8acbec"
    , borderDisabledInfo = "1px solid #70c0e8"
    , rippleColorInfo = common.infoColor
    , colorSuccess = common.successColor
    , colorHoverSuccess = common.successColorHover
    , colorPressedSuccess = common.successColorPressed
    , colorFocusSuccess = common.successColorHover
    , colorDisabledSuccess = common.successColor
    , textColorSuccess = common.baseColor
    , textColorHoverSuccess = common.baseColor
    , textColorPressedSuccess = common.baseColor
    , textColorFocusSuccess = common.baseColor
    , textColorDisabledSuccess = common.baseColor
    , textColorTextSuccess = common.successColor
    , textColorTextHoverSuccess = common.successColorHover
    , textColorTextPressedSuccess = common.successColorPressed
    , textColorTextFocusSuccess = common.successColorHover
    , textColorTextDisabledSuccess = common.textColor2
    , textColorGhostSuccess = common.successColor
    , textColorGhostHoverSuccess = common.successColorHover
    , textColorGhostPressedSuccess = common.successColorPressed
    , textColorGhostFocusSuccess = common.successColorHover
    , textColorGhostDisabledSuccess = common.successColor
    , borderSuccess = "1px solid #63e2b7"
    , borderHoverSuccess = "1px solid #7fe7c4"
    , borderPressedSuccess = "1px solid #5acea7"
    , borderFocusSuccess = "1px solid #7fe7c4"
    , borderDisabledSuccess = "1px solid #63e2b7"
    , rippleColorSuccess = common.successColor
    , colorWarning = common.warningColor
    , colorHoverWarning = common.warningColorHover
    , colorPressedWarning = common.warningColorPressed
    , colorFocusWarning = common.warningColorHover
    , colorDisabledWarning = common.warningColor
    , textColorWarning = common.baseColor
    , textColorHoverWarning = common.baseColor
    , textColorPressedWarning = common.baseColor
    , textColorFocusWarning = common.baseColor
    , textColorDisabledWarning = common.baseColor
    , textColorTextWarning = common.warningColor
    , textColorTextHoverWarning = common.warningColorHover
    , textColorTextPressedWarning = common.warningColorPressed
    , textColorTextFocusWarning = common.warningColorHover
    , textColorTextDisabledWarning = common.textColor2
    , textColorGhostWarning = common.warningColor
    , textColorGhostHoverWarning = common.warningColorHover
    , textColorGhostPressedWarning = common.warningColorPressed
    , textColorGhostFocusWarning = common.warningColorHover
    , textColorGhostDisabledWarning = common.warningColor
    , borderWarning = "1px solid #f2c97d"
    , borderHoverWarning = "1px solid #f5d599"
    , borderPressedWarning = "1px solid #e6c260"
    , borderFocusWarning = "1px solid #f5d599"
    , borderDisabledWarning = "1px solid #f2c97d"
    , rippleColorWarning = common.warningColor
    , colorError = common.errorColor
    , colorHoverError = common.errorColorHover
    , colorPressedError = common.errorColorPressed
    , colorFocusError = common.errorColorHover
    , colorDisabledError = common.errorColor
    , textColorError = common.baseColor
    , textColorHoverError = common.baseColor
    , textColorPressedError = common.baseColor
    , textColorFocusError = common.baseColor
    , textColorDisabledError = common.baseColor
    , textColorTextError = common.errorColor
    , textColorTextHoverError = common.errorColorHover
    , textColorTextPressedError = common.errorColorPressed
    , textColorTextFocusError = common.errorColorHover
    , textColorTextDisabledError = common.textColor2
    , textColorGhostError = common.errorColor
    , textColorGhostHoverError = common.errorColorHover
    , textColorGhostPressedError = common.errorColorPressed
    , textColorGhostFocusError = common.errorColorHover
    , textColorGhostDisabledError = common.errorColor
    , borderError = "1px solid #e88080"
    , borderHoverError = "1px solid #e98b8b"
    , borderPressedError = "1px solid #e57272"
    , borderFocusError = "1px solid #e98b8b"
    , borderDisabledError = "1px solid #e88080"
    , rippleColorError = common.errorColor
    , waveOpacity = "0.8"
    , fontWeight = common.fontWeight
    , fontWeightStrong = common.fontWeightStrong
    }
