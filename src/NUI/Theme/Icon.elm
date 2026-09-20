module NUI.Theme.Icon exposing (Vars, vars)

{-| Naive UI icon theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { color : String
    , opacity1Depth : String
    , opacity2Depth : String
    , opacity3Depth : String
    , opacity4Depth : String
    , opacity5Depth : String
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
    { color = common.textColorBase
    , opacity1Depth = common.opacity1
    , opacity2Depth = common.opacity2
    , opacity3Depth = common.opacity3
    , opacity4Depth = common.opacity4
    , opacity5Depth = common.opacity5
    }


dark : Common -> Vars
dark common =
    { color = common.textColorBase
    , opacity1Depth = common.opacity1
    , opacity2Depth = common.opacity2
    , opacity3Depth = common.opacity3
    , opacity4Depth = common.opacity4
    , opacity5Depth = common.opacity5
    }
