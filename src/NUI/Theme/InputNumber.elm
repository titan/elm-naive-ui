module NUI.Theme.InputNumber exposing (Vars, vars)

{-| Naive UI input-number theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { iconColorDisabled : String
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
    { iconColorDisabled = common.textColorDisabled
    }


dark : Common -> Vars
dark common =
    { iconColorDisabled = common.textColorDisabled
    }
