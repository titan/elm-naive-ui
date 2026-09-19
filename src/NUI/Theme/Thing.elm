module NUI.Theme.Thing exposing (Vars, vars)

{-| Naive UI thing theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { fontSize : String
    , titleTextColor : String
    , textColor : String
    , titleFontWeight : String
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
    { fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , titleFontWeight = common.fontWeightStrong
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , titleFontWeight = common.fontWeightStrong
    }
