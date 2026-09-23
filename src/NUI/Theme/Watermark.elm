module NUI.Theme.Watermark exposing (Vars, vars)

{-| Naive UI watermark theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { fontFamily : String
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
    { fontFamily = common.fontFamily
    }


dark : Common -> Vars
dark common =
    { fontFamily = common.fontFamily
    }
