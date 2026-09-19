module NUI.Theme.QrCode exposing (Vars, vars)

{-| Naive UI qr-code theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { borderRadius : String
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
    { borderRadius = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { borderRadius = common.borderRadius
    }
