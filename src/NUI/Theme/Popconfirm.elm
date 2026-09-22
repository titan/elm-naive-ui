module NUI.Theme.Popconfirm exposing (Vars, vars)

{-| Naive UI popconfirm theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { iconSize : String
    , fontSize : String
    , iconColor : String
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
    { iconSize = "22px"
    , fontSize = common.fontSize
    , iconColor = common.warningColor
    }


dark : Common -> Vars
dark common =
    { iconSize = "22px"
    , fontSize = common.fontSize
    , iconColor = common.warningColor
    }
