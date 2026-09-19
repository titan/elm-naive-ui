module NUI.Theme.GradientText exposing (Vars, vars)

{-| Naive UI gradient-text theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { fontWeight : String
    , rotate : String
    , colorStartPrimary : String
    , colorEndPrimary : String
    , colorStartInfo : String
    , colorEndInfo : String
    , colorStartWarning : String
    , colorEndWarning : String
    , colorStartError : String
    , colorEndError : String
    , colorStartSuccess : String
    , colorEndSuccess : String
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
    { fontWeight = common.fontWeightStrong
    , rotate = "252deg"
    , colorStartPrimary = "rgba(24, 160, 88, 0.6)"
    , colorEndPrimary = "#18a058"
    , colorStartInfo = "rgba(32, 128, 240, 0.6)"
    , colorEndInfo = "#2080f0"
    , colorStartWarning = "rgba(240, 160, 32, 0.6)"
    , colorEndWarning = "#f0a020"
    , colorStartError = "rgba(208, 48, 80, 0.6)"
    , colorEndError = "#d03050"
    , colorStartSuccess = "rgba(24, 160, 88, 0.6)"
    , colorEndSuccess = "#18a058"
    }


dark : Common -> Vars
dark common =
    { fontWeight = common.fontWeightStrong
    , rotate = "252deg"
    , colorStartPrimary = "#63e2b7"
    , colorEndPrimary = "rgb(42, 148, 125)"
    , colorStartInfo = "#70c0e8"
    , colorEndInfo = "rgb(56, 137, 197)"
    , colorStartWarning = "#f2c97d"
    , colorEndWarning = "rgb(240, 138, 0)"
    , colorStartError = "#e88080"
    , colorEndError = "rgb(208, 58, 82)"
    , colorStartSuccess = "#63e2b7"
    , colorEndSuccess = "rgb(42, 148, 125)"
    }
