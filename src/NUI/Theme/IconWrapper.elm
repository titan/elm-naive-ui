module NUI.Theme.IconWrapper exposing (Vars, vars)

{-| Naive UI icon-wrapper theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { color : String
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
    { color = common.primaryColor
    , iconColor = common.baseColor
    }


dark : Common -> Vars
dark common =
    { color = common.primaryColor
    , iconColor = common.baseColor
    }
