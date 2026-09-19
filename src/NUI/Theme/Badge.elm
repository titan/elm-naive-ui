module NUI.Theme.Badge exposing (Vars, vars)

{-| Naive UI badge theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { color : String
    , colorInfo : String
    , colorSuccess : String
    , colorError : String
    , colorWarning : String
    , fontSize : String
    , fontFamily : String
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
    { color = common.errorColor
    , colorInfo = common.infoColor
    , colorSuccess = common.successColor
    , colorError = common.errorColor
    , colorWarning = common.warningColor
    , fontSize = "12px"
    , fontFamily = common.fontFamily
    }


dark : Common -> Vars
dark common =
    { color = common.errorColorSuppl
    , colorInfo = common.infoColorSuppl
    , colorSuccess = common.successColorSuppl
    , colorError = common.errorColorSuppl
    , colorWarning = common.warningColorSuppl
    , fontSize = "12px"
    , fontFamily = common.fontFamily
    }
