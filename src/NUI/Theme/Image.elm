module NUI.Theme.Image exposing (Vars, vars)

{-| Naive UI image theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { toolbarIconColor : String
    , toolbarColor : String
    , toolbarBoxShadow : String
    , toolbarBorderRadius : String
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
    { toolbarIconColor = "rgba(255, 255, 255, .9)"
    , toolbarColor = "rgba(0, 0, 0, .35)"
    , toolbarBoxShadow = "none"
    , toolbarBorderRadius = "24px"
    }


dark : Common -> Vars
dark common =
    { toolbarIconColor = common.textColor2
    , toolbarColor = "rgba(0, 0, 0, .35)"
    , toolbarBoxShadow = "none"
    , toolbarBorderRadius = "24px"
    }
