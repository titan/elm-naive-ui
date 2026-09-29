module NUI.Theme.Carousel exposing (Vars, vars)

{-| Naive UI carousel theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { dotSize : String
    , dotColor : String
    , dotColorActive : String
    , dotColorFocus : String
    , dotLineWidth : String
    , dotLineWidthActive : String
    , arrowColor : String
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
    { dotSize = "8px"
    , dotColor = "rgba(255, 255, 255, .3)"
    , dotColorActive = "rgba(255, 255, 255, 1)"
    , dotColorFocus = "rgba(255, 255, 255, .5)"
    , dotLineWidth = "16px"
    , dotLineWidthActive = "24px"
    , arrowColor = "#eee"
    }


dark : Common -> Vars
dark common =
    { dotSize = "8px"
    , dotColor = "rgba(255, 255, 255, .3)"
    , dotColorActive = "rgba(255, 255, 255, 1)"
    , dotColorFocus = "rgba(255, 255, 255, .5)"
    , dotLineWidth = "16px"
    , dotLineWidthActive = "24px"
    , arrowColor = "#eee"
    }
