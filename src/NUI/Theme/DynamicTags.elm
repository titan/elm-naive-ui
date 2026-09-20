module NUI.Theme.DynamicTags exposing (Vars, vars)

{-| Naive UI dynamic-tags theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { inputWidth : String
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
    { inputWidth = "64px"
    }


dark : Common -> Vars
dark common =
    { inputWidth = "64px"
    }
