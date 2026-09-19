module NUI.Theme.FloatButton exposing (Vars, vars)

{-| Naive UI float-button theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { color : String
    , colorHover : String
    , colorPressed : String
    , colorPrimary : String
    , colorPrimaryHover : String
    , colorPrimaryPressed : String
    , textColor : String
    , boxShadow : String
    , boxShadowHover : String
    , boxShadowPressed : String
    , textColorPrimary : String
    , borderRadiusSquare : String
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
    { color = common.popoverColor
    , colorHover = common.buttonColor2Hover
    , colorPressed = common.buttonColor2Pressed
    , colorPrimary = common.primaryColor
    , colorPrimaryHover = common.primaryColorHover
    , colorPrimaryPressed = common.primaryColorPressed
    , textColor = common.textColor2
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .16)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .24)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .24)"
    , textColorPrimary = "#fff"
    , borderRadiusSquare = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { color = common.popoverColor
    , colorHover = common.buttonColor2Hover
    , colorPressed = common.buttonColor2Pressed
    , colorPrimary = common.primaryColor
    , colorPrimaryHover = common.primaryColorHover
    , colorPrimaryPressed = common.primaryColorPressed
    , textColor = common.textColor2
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , textColorPrimary = common.baseColor
    , borderRadiusSquare = common.borderRadius
    }
