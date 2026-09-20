module NUI.Theme.BackTop exposing (Vars, vars)

{-| Naive UI back-top theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { width : String
    , height : String
    , borderRadius : String
    , iconSize : String
    , color : String
    , textColor : String
    , iconColor : String
    , iconColorHover : String
    , iconColorPressed : String
    , boxShadow : String
    , boxShadowHover : String
    , boxShadowPressed : String
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
    { width = "44px"
    , height = "44px"
    , borderRadius = "22px"
    , iconSize = "26px"
    , color = common.popoverColor
    , textColor = common.textColor2
    , iconColor = common.textColor2
    , iconColorHover = common.primaryColorHover
    , iconColorPressed = common.primaryColorPressed
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    }


dark : Common -> Vars
dark common =
    { width = "44px"
    , height = "44px"
    , borderRadius = "22px"
    , iconSize = "26px"
    , color = common.popoverColor
    , textColor = common.textColor2
    , iconColor = common.textColor2
    , iconColorHover = common.primaryColorHover
    , iconColorPressed = common.primaryColorPressed
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    }
