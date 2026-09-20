module NUI.Theme.InputOtp exposing (Vars, vars)

{-| Naive UI input-otp theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { inputWidthSmall : String
    , inputWidthMedium : String
    , inputWidthLarge : String
    , gapSmall : String
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
    { inputWidthSmall = "24px"
    , inputWidthMedium = "30px"
    , inputWidthLarge = "36px"
    , gapSmall = "8px"
    , gapMedium = "8px"
    , gapLarge = "8px"
    }


dark : Common -> Vars
dark common =
    { inputWidthSmall = "24px"
    , inputWidthMedium = "30px"
    , inputWidthLarge = "36px"
    , gapSmall = "8px"
    , gapMedium = "8px"
    , gapLarge = "8px"
    }
