module NUI.Theme.SelectMenu exposing (Vars, vars)

{-| Naive UI selectMenu theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { height : String
    , paddingTiny : String
    , paddingSmall : String
    , paddingMedium : String
    , paddingLarge : String
    , paddingHuge : String
    , optionPaddingTiny : String
    , optionPaddingSmall : String
    , optionPaddingMedium : String
    , optionPaddingLarge : String
    , optionPaddingHuge : String
    , loadingSize : String
    , optionFontSizeTiny : String
    , optionFontSizeSmall : String
    , optionFontSizeMedium : String
    , optionFontSizeLarge : String
    , optionFontSizeHuge : String
    , optionHeightTiny : String
    , optionHeightSmall : String
    , optionHeightMedium : String
    , optionHeightLarge : String
    , optionHeightHuge : String
    , borderRadius : String
    , color : String
    , groupHeaderTextColor : String
    , actionDividerColor : String
    , optionTextColor : String
    , optionTextColorPressed : String
    , optionTextColorDisabled : String
    , optionTextColorActive : String
    , optionOpacityDisabled : String
    , optionCheckColor : String
    , optionColorPending : String
    , optionColorActive : String
    , optionColorActivePending : String
    , actionTextColor : String
    , loadingColor : String
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
    { height = "calc(var(--n-option-height) * 7.6)"
    , paddingTiny = "4px 0"
    , paddingSmall = "4px 0"
    , paddingMedium = "4px 0"
    , paddingLarge = "4px 0"
    , paddingHuge = "4px 0"
    , optionPaddingTiny = "0 12px"
    , optionPaddingSmall = "0 12px"
    , optionPaddingMedium = "0 12px"
    , optionPaddingLarge = "0 12px"
    , optionPaddingHuge = "0 12px"
    , loadingSize = "18px"
    , optionFontSizeTiny = common.fontSizeTiny
    , optionFontSizeSmall = common.fontSizeSmall
    , optionFontSizeMedium = common.fontSizeMedium
    , optionFontSizeLarge = common.fontSizeLarge
    , optionFontSizeHuge = common.fontSizeHuge
    , optionHeightTiny = common.heightTiny
    , optionHeightSmall = common.heightSmall
    , optionHeightMedium = common.heightMedium
    , optionHeightLarge = common.heightLarge
    , optionHeightHuge = common.heightHuge
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , groupHeaderTextColor = common.textColor3
    , actionDividerColor = common.dividerColor
    , optionTextColor = common.textColor2
    , optionTextColorPressed = common.primaryColorPressed
    , optionTextColorDisabled = common.textColorDisabled
    , optionTextColorActive = common.primaryColor
    , optionOpacityDisabled = common.opacityDisabled
    , optionCheckColor = common.primaryColor
    , optionColorPending = common.hoverColor
    , optionColorActive = "rgba(0, 0, 0, 0)"
    , optionColorActivePending = common.hoverColor
    , actionTextColor = common.textColor2
    , loadingColor = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { height = "calc(var(--n-option-height) * 7.6)"
    , paddingTiny = "4px 0"
    , paddingSmall = "4px 0"
    , paddingMedium = "4px 0"
    , paddingLarge = "4px 0"
    , paddingHuge = "4px 0"
    , optionPaddingTiny = "0 12px"
    , optionPaddingSmall = "0 12px"
    , optionPaddingMedium = "0 12px"
    , optionPaddingLarge = "0 12px"
    , optionPaddingHuge = "0 12px"
    , loadingSize = "18px"
    , optionFontSizeTiny = common.fontSizeTiny
    , optionFontSizeSmall = common.fontSizeSmall
    , optionFontSizeMedium = common.fontSizeMedium
    , optionFontSizeLarge = common.fontSizeLarge
    , optionFontSizeHuge = common.fontSizeHuge
    , optionHeightTiny = common.heightTiny
    , optionHeightSmall = common.heightSmall
    , optionHeightMedium = common.heightMedium
    , optionHeightLarge = common.heightLarge
    , optionHeightHuge = common.heightHuge
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , groupHeaderTextColor = common.textColor3
    , actionDividerColor = common.dividerColor
    , optionTextColor = common.textColor2
    , optionTextColorPressed = common.primaryColorPressed
    , optionTextColorDisabled = common.textColorDisabled
    , optionTextColorActive = common.primaryColor
    , optionOpacityDisabled = common.opacityDisabled
    , optionCheckColor = common.primaryColor
    , optionColorPending = common.hoverColor
    , optionColorActive = "rgba(0, 0, 0, 0)"
    , optionColorActivePending = common.hoverColor
    , actionTextColor = common.textColor2
    , loadingColor = common.primaryColor
    }
