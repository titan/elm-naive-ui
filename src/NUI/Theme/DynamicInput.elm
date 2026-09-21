module NUI.Theme.DynamicInput exposing (Vars, vars)

{-| Naive UI dynamic-input theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { actionMargin : String
    , actionMarginRtl : String
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
    { actionMargin = "0 0 0 20px"
    , actionMarginRtl = "0 20px 0 0"
    }


dark : Common -> Vars
dark common =
    { actionMargin = "0 0 0 20px"
    , actionMarginRtl = "0 20px 0 0"
    }
