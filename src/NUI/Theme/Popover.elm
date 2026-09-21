module NUI.Theme.Popover exposing (Vars, vars)

{-| Naive UI popover theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { space : String
    , spaceArrow : String
    , arrowOffset : String
    , arrowOffsetVertical : String
    , arrowHeight : String
    , padding : String
    , fontSize : String
    , borderRadius : String
    , color : String
    , dividerColor : String
    , textColor : String
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
    { space = "6px"
    , spaceArrow = "10px"
    , arrowOffset = "10px"
    , arrowOffsetVertical = "10px"
    , arrowHeight = "6px"
    , padding = "8px 14px"
    , fontSize = common.fontSize
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , dividerColor = common.dividerColor
    , textColor = common.textColor2
    , boxShadow = common.boxShadow2
    }


dark : Common -> Vars
dark common =
    { space = "6px"
    , spaceArrow = "10px"
    , arrowOffset = "10px"
    , arrowOffsetVertical = "10px"
    , arrowHeight = "6px"
    , padding = "8px 14px"
    , fontSize = common.fontSize
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , dividerColor = common.dividerColor
    , textColor = common.textColor2
    , boxShadow = common.boxShadow2
    }
