module NUI.Theme.Flex exposing (Vars, vars)

{-| Naive UI flex theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { gapSmall : String
    , gapMedium : String
    , gapLarge : String
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
    { gapSmall = "4px 8px"
    , gapMedium = "8px 12px"
    , gapLarge = "12px 16px"
    }


dark : Common -> Vars
dark common =
    { gapSmall = "4px 8px"
    , gapMedium = "8px 12px"
    , gapLarge = "12px 16px"
    }
