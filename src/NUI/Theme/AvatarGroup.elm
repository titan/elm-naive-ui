module NUI.Theme.AvatarGroup exposing (Vars, vars)

{-| Naive UI avatar-group theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { gap : String
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
    { gap = "-12px"
    }


dark : Common -> Vars
dark common =
    { gap = "-12px"
    }
