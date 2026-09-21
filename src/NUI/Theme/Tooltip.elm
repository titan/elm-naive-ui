module NUI.Theme.Tooltip exposing (Vars, vars)

{-| Naive UI tooltip theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { padding : String
    , borderRadius : String
    , boxShadow : String
    , color : String
    , textColor : String
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
    { padding = "8px 14px"
    , borderRadius = common.borderRadius
    , boxShadow = common.boxShadow2
    , color = "rgba(38, 38, 38, 1)"
    , textColor = common.baseColor
    }


dark : Common -> Vars
dark common =
    { padding = "8px 14px"
    , borderRadius = common.borderRadius
    , boxShadow = common.boxShadow2
    , color = common.popoverColor
    , textColor = common.textColor2
    }
