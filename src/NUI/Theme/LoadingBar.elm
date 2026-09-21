module NUI.Theme.LoadingBar exposing (Vars, vars)

{-| Naive UI loading-bar theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { colorError : String
    , colorLoading : String
    , height : String
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
    { colorError = common.errorColor
    , colorLoading = common.primaryColor
    , height = "2px"
    }


dark : Common -> Vars
dark common =
    { colorError = "red"
    , colorLoading = common.primaryColor
    , height = "2px"
    }
