module NUI.Theme.Equation exposing (Vars, vars)

{-| Naive UI equation theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    {}


vars : Theme -> Vars
vars theme =
    case theme.mode of
        Theme.Light ->
            light theme.common

        Theme.Dark ->
            dark theme.common


light : Common -> Vars
light common =
    {}


dark : Common -> Vars
dark common =
    {}
