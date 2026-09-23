module NUI.Theme.Cascader exposing (Vars, vars)

{-| Naive UI cascader theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { menuBorderRadius : String
    , menuColor : String
    , menuBoxShadow : String
    , menuDividerColor : String
    , menuHeight : String
    , optionArrowColor : String
    , optionHeight : String
    , optionFontSize : String
    , optionColorHover : String
    , optionTextColor : String
    , optionTextColorActive : String
    , optionTextColorDisabled : String
    , optionCheckMarkColor : String
    , loadingColor : String
    , columnWidth : String
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
    { menuBorderRadius = common.borderRadius
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuDividerColor = common.dividerColor
    , menuHeight = "calc(var(--n-option-height) * 6.6)"
    , optionArrowColor = common.textColor3
    , optionHeight = common.heightMedium
    , optionFontSize = common.fontSizeMedium
    , optionColorHover = common.hoverColor
    , optionTextColor = common.textColor2
    , optionTextColorActive = common.primaryColor
    , optionTextColorDisabled = common.textColorDisabled
    , optionCheckMarkColor = common.primaryColor
    , loadingColor = common.primaryColor
    , columnWidth = "180px"
    }


dark : Common -> Vars
dark common =
    { menuBorderRadius = common.borderRadius
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuDividerColor = common.dividerColor
    , menuHeight = "calc(var(--n-option-height) * 6.6)"
    , optionArrowColor = common.textColor3
    , optionHeight = common.heightMedium
    , optionFontSize = common.fontSizeMedium
    , optionColorHover = common.hoverColor
    , optionTextColor = common.textColor2
    , optionTextColorActive = common.primaryColor
    , optionTextColorDisabled = common.textColorDisabled
    , optionCheckMarkColor = common.primaryColor
    , loadingColor = common.primaryColor
    , columnWidth = "180px"
    }
