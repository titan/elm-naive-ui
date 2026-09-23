module NUI.Theme.Tree exposing (Vars, vars)

{-| Naive UI tree theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { fontSize : String
    , lineHeight : String
    , nodeHeight : String
    , nodeWrapperPadding : String
    , nodeBorderRadius : String
    , nodeColorHover : String
    , nodeColorPressed : String
    , nodeColorActive : String
    , arrowColor : String
    , nodeTextColor : String
    , nodeTextColorDisabled : String
    , loadingColor : String
    , dropMarkColor : String
    , lineColor : String
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
    { fontSize = common.fontSize
    , lineHeight = "1.5"
    , nodeHeight = "30px"
    , nodeWrapperPadding = "3px 0"
    , nodeBorderRadius = common.borderRadiusSmall
    , nodeColorHover = common.hoverColor
    , nodeColorPressed = common.pressedColor
    , nodeColorActive = "rgba(24, 160, 88, 0.1)"
    , arrowColor = common.textColor3
    , nodeTextColor = common.textColor2
    , nodeTextColorDisabled = common.textColorDisabled
    , loadingColor = common.primaryColor
    , dropMarkColor = common.primaryColor
    , lineColor = common.dividerColor
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , lineHeight = "1.5"
    , nodeHeight = "30px"
    , nodeWrapperPadding = "3px 0"
    , nodeBorderRadius = common.borderRadiusSmall
    , nodeColorHover = common.hoverColor
    , nodeColorPressed = common.pressedColor
    , nodeColorActive = "rgba(99, 226, 183, 0.15)"
    , arrowColor = common.textColor3
    , nodeTextColor = common.textColor2
    , nodeTextColorDisabled = common.textColorDisabled
    , loadingColor = common.primaryColor
    , dropMarkColor = common.primaryColor
    , lineColor = common.dividerColor
    }
