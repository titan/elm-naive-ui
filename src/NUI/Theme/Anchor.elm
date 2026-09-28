module NUI.Theme.Anchor exposing (Vars, vars)

{-| Naive UI anchor theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { linkFontSize : String
    , linkPadding : String
    , railWidth : String
    , borderRadius : String
    , railColor : String
    , railColorActive : String
    , linkColor : String
    , linkTextColor : String
    , linkTextColorHover : String
    , linkTextColorPressed : String
    , linkTextColorActive : String
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
    { linkFontSize = "13px"
    , linkPadding = "0 0 0 16px"
    , railWidth = "4px"
    , borderRadius = common.borderRadius
    , railColor = common.railColor
    , railColorActive = common.primaryColor
    , linkColor = "rgba(24, 160, 88, 0.15)"
    , linkTextColor = common.textColor2
    , linkTextColorHover = common.primaryColorHover
    , linkTextColorPressed = common.primaryColorPressed
    , linkTextColorActive = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { linkFontSize = "13px"
    , linkPadding = "0 0 0 16px"
    , railWidth = "4px"
    , borderRadius = common.borderRadius
    , railColor = common.railColor
    , railColorActive = common.primaryColor
    , linkColor = "rgba(99, 226, 183, 0.15)"
    , linkTextColor = common.textColor2
    , linkTextColorHover = common.primaryColorHover
    , linkTextColorPressed = common.primaryColorPressed
    , linkTextColorActive = common.primaryColor
    }
