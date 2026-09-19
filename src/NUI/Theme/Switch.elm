module NUI.Theme.Switch exposing (Vars, vars)

{-| Naive UI switch theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { buttonHeightSmall : String
    , buttonHeightMedium : String
    , buttonHeightLarge : String
    , buttonWidthSmall : String
    , buttonWidthMedium : String
    , buttonWidthLarge : String
    , buttonWidthPressedSmall : String
    , buttonWidthPressedMedium : String
    , buttonWidthPressedLarge : String
    , railHeightSmall : String
    , railHeightMedium : String
    , railHeightLarge : String
    , railWidthSmall : String
    , railWidthMedium : String
    , railWidthLarge : String
    , iconColor : String
    , textColor : String
    , loadingColor : String
    , opacityDisabled : String
    , railColor : String
    , railColorActive : String
    , buttonBoxShadow : String
    , buttonColor : String
    , railBorderRadiusSmall : String
    , railBorderRadiusMedium : String
    , railBorderRadiusLarge : String
    , buttonBorderRadiusSmall : String
    , buttonBorderRadiusMedium : String
    , buttonBorderRadiusLarge : String
    , boxShadowFocus : String
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
    { buttonHeightSmall = common.fontSize
    , buttonHeightMedium = "18px"
    , buttonHeightLarge = common.heightTiny
    , buttonWidthSmall = common.fontSize
    , buttonWidthMedium = "18px"
    , buttonWidthLarge = common.heightTiny
    , buttonWidthPressedSmall = "20px"
    , buttonWidthPressedMedium = "24px"
    , buttonWidthPressedLarge = common.heightSmall
    , railHeightSmall = "18px"
    , railHeightMedium = common.heightTiny
    , railHeightLarge = "26px"
    , railWidthSmall = "32px"
    , railWidthMedium = common.heightLarge
    , railWidthLarge = "48px"
    , iconColor = common.textColor3
    , textColor = "white"
    , loadingColor = common.primaryColor
    , opacityDisabled = common.opacityDisabled
    , railColor = "rgba(0, 0, 0, .14)"
    , railColorActive = common.primaryColor
    , buttonBoxShadow = "0 1px 4px 0 rgba(0, 0, 0, 0.3), inset 0 0 1px 0 rgba(0, 0, 0, 0.05)"
    , buttonColor = "#FFF"
    , railBorderRadiusSmall = common.borderRadius
    , railBorderRadiusMedium = common.borderRadius
    , railBorderRadiusLarge = common.borderRadius
    , buttonBorderRadiusSmall = common.borderRadius
    , buttonBorderRadiusMedium = common.borderRadius
    , buttonBorderRadiusLarge = common.borderRadius
    , boxShadowFocus = "0 0 0 2px rgba(24, 160, 88, 0.2)"
    }


dark : Common -> Vars
dark common =
    { buttonHeightSmall = common.fontSize
    , buttonHeightMedium = "18px"
    , buttonHeightLarge = common.heightTiny
    , buttonWidthSmall = common.fontSize
    , buttonWidthMedium = "18px"
    , buttonWidthLarge = common.heightTiny
    , buttonWidthPressedSmall = "20px"
    , buttonWidthPressedMedium = "24px"
    , buttonWidthPressedLarge = common.heightSmall
    , railHeightSmall = "18px"
    , railHeightMedium = common.heightTiny
    , railHeightLarge = "26px"
    , railWidthSmall = "32px"
    , railWidthMedium = common.heightLarge
    , railWidthLarge = "48px"
    , iconColor = common.baseColor
    , textColor = common.textColor2
    , loadingColor = common.primaryColorSuppl
    , opacityDisabled = common.opacityDisabled
    , railColor = "rgba(255, 255, 255, .20)"
    , railColorActive = common.primaryColorSuppl
    , buttonBoxShadow = "0px 2px 4px 0 rgba(0, 0, 0, 0.4)"
    , buttonColor = "#FFF"
    , railBorderRadiusSmall = common.borderRadius
    , railBorderRadiusMedium = common.borderRadius
    , railBorderRadiusLarge = common.borderRadius
    , buttonBorderRadiusSmall = common.borderRadius
    , buttonBorderRadiusMedium = common.borderRadius
    , buttonBorderRadiusLarge = common.borderRadius
    , boxShadowFocus = "0 0 8px 0 rgba(99, 226, 183, 0.3)"
    }
