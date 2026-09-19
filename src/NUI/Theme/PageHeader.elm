module NUI.Theme.PageHeader exposing (Vars, vars)

{-| Naive UI page-header theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { titleFontSize : String
    , backSize : String
    , titleFontWeight : String
    , fontSize : String
    , titleTextColor : String
    , backColor : String
    , backColorHover : String
    , backColorPressed : String
    , subtitleTextColor : String
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
    { titleFontSize = "18px"
    , backSize = common.heightTiny
    , titleFontWeight = common.fontWeightStrong
    , fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , backColor = common.textColor2
    , backColorHover = common.primaryColorHover
    , backColorPressed = common.primaryColorPressed
    , subtitleTextColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { titleFontSize = "18px"
    , backSize = common.heightTiny
    , titleFontWeight = common.fontWeightStrong
    , fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , backColor = common.textColor2
    , backColorHover = common.primaryColorHover
    , backColorPressed = common.primaryColorPressed
    , subtitleTextColor = common.textColor3
    }
