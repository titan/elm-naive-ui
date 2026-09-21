module NUI.Theme.Scrollbar exposing (Vars, vars)

{-| Naive UI scrollbar theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { railInsetHorizontalBottom : String
    , railInsetHorizontalTop : String
    , railInsetVerticalRight : String
    , railInsetVerticalLeft : String
    , railColor : String
    , height : String
    , width : String
    , borderRadius : String
    , color : String
    , colorHover : String
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
    { railInsetHorizontalBottom = "auto 2px 4px 2px"
    , railInsetHorizontalTop = "4px 2px auto 2px"
    , railInsetVerticalRight = "2px 4px 2px auto"
    , railInsetVerticalLeft = "2px auto 2px 4px"
    , railColor = "transparent"
    , height = common.scrollbarHeight
    , width = common.scrollbarWidth
    , borderRadius = common.scrollbarBorderRadius
    , color = common.scrollbarColor
    , colorHover = common.scrollbarColorHover
    }


dark : Common -> Vars
dark common =
    { railInsetHorizontalBottom = "auto 2px 4px 2px"
    , railInsetHorizontalTop = "4px 2px auto 2px"
    , railInsetVerticalRight = "2px 4px 2px auto"
    , railInsetVerticalLeft = "2px auto 2px 4px"
    , railColor = "transparent"
    , height = common.scrollbarHeight
    , width = common.scrollbarWidth
    , borderRadius = common.scrollbarBorderRadius
    , color = common.scrollbarColor
    , colorHover = common.scrollbarColorHover
    }
