module NUI.Theme.Select exposing (Vars, vars)

{-| Naive UI select theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { menuBoxShadow : String
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
    { menuBoxShadow = common.boxShadow2
    }


dark : Common -> Vars
dark common =
    { menuBoxShadow = common.boxShadow2
    }
