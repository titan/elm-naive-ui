module NUI.Theme.Rate exposing (Vars, vars)

{-| Naive UI rate theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { itemColor : String
    , itemColorActive : String
    , sizeSmall : String
    , sizeMedium : String
    , sizeLarge : String
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
    { itemColor = common.railColor
    , itemColorActive = "#FFCC33"
    , sizeSmall = "16px"
    , sizeMedium = "20px"
    , sizeLarge = "24px"
    }


dark : Common -> Vars
dark common =
    { itemColor = common.railColor
    , itemColorActive = "#CCAA33"
    , sizeSmall = "16px"
    , sizeMedium = "20px"
    , sizeLarge = "24px"
    }
