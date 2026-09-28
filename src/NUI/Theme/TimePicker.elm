module NUI.Theme.TimePicker exposing (Vars, vars)

{-| Naive UI time-picker theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { itemFontSize : String
    , itemHeight : String
    , itemWidth : String
    , panelActionPadding : String
    , panelColor : String
    , panelBoxShadow : String
    , panelDividerColor : String
    , itemTextColor : String
    , itemTextColorActive : String
    , itemColorHover : String
    , itemOpacityDisabled : String
    , itemBorderRadius : String
    , borderRadius : String
    , iconColor : String
    , iconColorDisabled : String
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
    { itemFontSize = "12px"
    , itemHeight = "36px"
    , itemWidth = "52px"
    , panelActionPadding = "8px 0"
    , panelColor = common.popoverColor
    , panelBoxShadow = common.boxShadow2
    , panelDividerColor = common.dividerColor
    , itemTextColor = common.textColor2
    , itemTextColorActive = common.primaryColor
    , itemColorHover = common.hoverColor
    , itemOpacityDisabled = common.opacityDisabled
    , itemBorderRadius = common.borderRadius
    , borderRadius = common.borderRadius
    , iconColor = common.iconColor
    , iconColorDisabled = common.iconColorDisabled
    }


dark : Common -> Vars
dark common =
    { itemFontSize = "12px"
    , itemHeight = "36px"
    , itemWidth = "52px"
    , panelActionPadding = "8px 0"
    , panelColor = common.popoverColor
    , panelBoxShadow = common.boxShadow2
    , panelDividerColor = common.dividerColor
    , itemTextColor = common.textColor2
    , itemTextColorActive = common.primaryColor
    , itemColorHover = common.hoverColor
    , itemOpacityDisabled = common.opacityDisabled
    , itemBorderRadius = common.borderRadius
    , borderRadius = common.borderRadius
    , iconColor = common.iconColor
    , iconColorDisabled = common.iconColorDisabled
    }
