module NUI.Theme.Skeleton exposing (Vars, vars)

{-| Naive UI skeleton theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { color : String
    , colorEnd : String
    , borderRadius : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
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
    { color = "#eee"
    , colorEnd = "#ddd"
    , borderRadius = common.borderRadius
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    }


dark : Common -> Vars
dark common =
    { color = "rgba(255, 255, 255, 0.12)"
    , colorEnd = "rgba(255, 255, 255, 0.18)"
    , borderRadius = common.borderRadius
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    }
