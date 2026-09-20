module NUI.Theme.FloatButtonGroup exposing (Vars, vars)

{-| Naive UI float-button-group theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { color : String
    , buttonBorderColor : String
    , borderRadiusSquare : String
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
    { color = common.popoverColor
    , buttonBorderColor = common.dividerColor
    , borderRadiusSquare = common.borderRadius
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    }


dark : Common -> Vars
dark common =
    { color = common.popoverColor
    , buttonBorderColor = common.dividerColor
    , borderRadiusSquare = common.borderRadius
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    }
