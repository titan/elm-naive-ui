module NUI.Theme.Radio exposing (Vars, vars)

{-| Naive UI radio theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { radioSizeSmall : String
    , radioSizeMedium : String
    , radioSizeLarge : String
    , labelPadding : String
    , labelFontWeight : String
    , labelLineHeight : String
    , buttonHeightSmall : String
    , buttonHeightMedium : String
    , buttonHeightLarge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , boxShadow : String
    , boxShadowActive : String
    , boxShadowFocus : String
    , boxShadowHover : String
    , boxShadowDisabled : String
    , color : String
    , colorDisabled : String
    , colorActive : String
    , textColor : String
    , textColorDisabled : String
    , dotColorActive : String
    , dotColorDisabled : String
    , buttonBorderColor : String
    , buttonBorderColorActive : String
    , buttonBorderColorHover : String
    , buttonColor : String
    , buttonColorActive : String
    , buttonTextColor : String
    , buttonTextColorActive : String
    , buttonTextColorHover : String
    , opacityDisabled : String
    , buttonBoxShadowFocus : String
    , buttonBoxShadowHover : String
    , buttonBoxShadow : String
    , buttonBorderRadius : String
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
    { radioSizeSmall = "14px"
    , radioSizeMedium = "16px"
    , radioSizeLarge = "18px"
    , labelPadding = "0 8px"
    , labelFontWeight = "400"
    , labelLineHeight = common.lineHeight
    , buttonHeightSmall = common.heightSmall
    , buttonHeightMedium = common.heightMedium
    , buttonHeightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , boxShadow = "inset 0 0 0 1px rgb(224, 224, 230)"
    , boxShadowActive = "inset 0 0 0 1px #18a058"
    , boxShadowFocus = "inset 0 0 0 1px #18a058, 0 0 0 2px rgba(24, 160, 88, 0.2)"
    , boxShadowHover = "inset 0 0 0 1px #18a058"
    , boxShadowDisabled = "inset 0 0 0 1px rgb(224, 224, 230)"
    , color = common.baseColor
    , colorDisabled = common.inputColorDisabled
    , colorActive = "#0000"
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    , dotColorActive = common.primaryColor
    , dotColorDisabled = common.borderColor
    , buttonBorderColor = common.borderColor
    , buttonBorderColorActive = common.primaryColor
    , buttonBorderColorHover = common.borderColor
    , buttonColor = common.baseColor
    , buttonColorActive = common.baseColor
    , buttonTextColor = common.textColor2
    , buttonTextColorActive = common.primaryColor
    , buttonTextColorHover = common.primaryColor
    , opacityDisabled = common.opacityDisabled
    , buttonBoxShadowFocus = "inset 0 0 0 1px #18a058, 0 0 0 2px rgba(24, 160, 88, 0.3)"
    , buttonBoxShadowHover = "inset 0 0 0 1px #0000"
    , buttonBoxShadow = "inset 0 0 0 1px #0000"
    , buttonBorderRadius = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { radioSizeSmall = "14px"
    , radioSizeMedium = "16px"
    , radioSizeLarge = "18px"
    , labelPadding = "0 8px"
    , labelFontWeight = "400"
    , labelLineHeight = common.lineHeight
    , buttonHeightSmall = common.heightSmall
    , buttonHeightMedium = common.heightMedium
    , buttonHeightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , boxShadow = "inset 0 0 0 1px rgba(255, 255, 255, 0.24)"
    , boxShadowActive = "inset 0 0 0 1px #63e2b7"
    , boxShadowFocus = "inset 0 0 0 1px #63e2b7, 0 0 0 2px rgba(99, 226, 183, 0.3)"
    , boxShadowHover = "inset 0 0 0 1px #63e2b7"
    , boxShadowDisabled = "inset 0 0 0 1px rgba(255, 255, 255, 0.24)"
    , color = "#0000"
    , colorDisabled = common.inputColorDisabled
    , colorActive = "#0000"
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    , dotColorActive = common.primaryColor
    , dotColorDisabled = common.borderColor
    , buttonBorderColor = common.borderColor
    , buttonBorderColorActive = common.primaryColor
    , buttonBorderColorHover = common.primaryColor
    , buttonColor = "#0000"
    , buttonColorActive = common.primaryColor
    , buttonTextColor = common.textColor2
    , buttonTextColorActive = common.baseColor
    , buttonTextColorHover = common.primaryColor
    , opacityDisabled = common.opacityDisabled
    , buttonBoxShadowFocus = "inset 0 0 0 1px #63e2b7, 0 0 0 2px rgba(99, 226, 183, 0.3)"
    , buttonBoxShadowHover = "inset 0 0 0 1px #63e2b7"
    , buttonBoxShadow = "inset 0 0 0 1px #0000"
    , buttonBorderRadius = common.borderRadius
    }
