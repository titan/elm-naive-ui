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
    { color = "#d03050"
    , colorInfo = "#2080f0"
    , colorSuccess = "#18a058"
    , colorError = "#d03050"
    , colorWarning = "#f0a020"
    , fontSize = common.fontSizeMini
    , fontFamily = common.fontFamily
    }


dark : Common -> Vars
dark common =
    { color = "rgb(208, 58, 82)"
    , colorInfo = "rgb(56, 137, 197)"
    , colorSuccess = "rgb(42, 148, 125)"
    , colorError = "rgb(208, 58, 82)"
    , colorWarning = "rgb(240, 138, 0)"
    , fontSize = common.fontSizeMini
    , fontFamily = common.fontFamily
    }
