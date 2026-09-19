module NUI.Theme.Collapse exposing (Vars, vars)

{-| Naive UI collapse theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { titleFontSize : String
    , titleFontWeight : String
    , dividerColor : String
    , titleTextColor : String
    , titleTextColorDisabled : String
    , fontSize : String
    , textColor : String
    , arrowColor : String
    , arrowColorDisabled : String
    , itemMargin : String
    , titlePadding : String
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
    { titleFontSize = common.fontSize
    , titleFontWeight = common.fontWeight
    , dividerColor = common.dividerColor
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , fontSize = common.fontSize
    , textColor = common.textColor2
    , arrowColor = common.textColor2
    , arrowColorDisabled = common.textColorDisabled
    , itemMargin = "16px 0 0 0"
    , titlePadding = "16px 0 0 0"
    }


dark : Common -> Vars
dark common =
    { titleFontSize = common.fontSize
    , titleFontWeight = common.fontWeight
    , dividerColor = common.dividerColor
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , fontSize = common.fontSize
    , textColor = common.textColor2
    , arrowColor = common.textColor2
    , arrowColorDisabled = common.textColorDisabled
    , itemMargin = "16px 0 0 0"
    , titlePadding = "16px 0 0 0"
    }
