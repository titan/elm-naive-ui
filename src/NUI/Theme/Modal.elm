module NUI.Theme.Modal exposing (Vars, vars)

{-| Naive UI modal theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { color : String
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
    { color = common.modalColor
    , textColor = common.textColor2
    , boxShadow = common.boxShadow3
    }


dark : Common -> Vars
dark common =
    { color = common.modalColor
    , textColor = common.textColor2
    , boxShadow = common.boxShadow3
    }
