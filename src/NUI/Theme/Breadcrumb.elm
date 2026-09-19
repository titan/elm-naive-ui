module NUI.Theme.Breadcrumb exposing (Vars, vars)

{-| Naive UI breadcrumb theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { fontWeightActive : String
    , fontSize : String
    , itemLineHeight : String
    , itemTextColor : String
    , itemTextColorHover : String
    , itemTextColorPressed : String
    , itemTextColorActive : String
    , itemBorderRadius : String
    , itemColorHover : String
    , itemColorPressed : String
    , separatorColor : String
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
    { fontWeightActive = common.fontWeight
    , fontSize = common.fontSize
    , itemLineHeight = "1.25"
    , itemTextColor = common.textColor3
    , itemTextColorHover = common.textColor2
    , itemTextColorPressed = common.textColor2
    , itemTextColorActive = common.textColor2
    , itemBorderRadius = common.borderRadius
    , itemColorHover = common.buttonColor2Hover
    , itemColorPressed = common.buttonColor2Pressed
    , separatorColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { fontWeightActive = common.fontWeight
    , fontSize = common.fontSize
    , itemLineHeight = "1.25"
    , itemTextColor = common.textColor3
    , itemTextColorHover = common.textColor2
    , itemTextColorPressed = common.textColor2
    , itemTextColorActive = common.textColor2
    , itemBorderRadius = common.borderRadius
    , itemColorHover = common.buttonColor2Hover
    , itemColorPressed = common.buttonColor2Pressed
    , separatorColor = common.textColor3
    }
