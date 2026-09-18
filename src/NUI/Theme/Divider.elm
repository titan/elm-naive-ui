module NUI.Theme.Divider exposing (Vars, vars)


{-| Naive UI divider theme variables.
-}


import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { textColor : String
    , color : String
    , fontWeight : String
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
    { textColor = common.textColor1
    , color = common.dividerColor
    , fontWeight = common.fontWeightStrong
    }


dark : Common -> Vars
dark common =
    { textColor = common.textColor1
    , color = common.dividerColor
    , fontWeight = common.fontWeightStrong
    }
