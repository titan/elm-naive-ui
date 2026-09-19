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
    , colorEndPrimary = common.primaryColor
    , colorStartInfo = "rgba(32, 128, 240, 0.6)"
    , colorEndInfo = common.infoColor
    , colorStartWarning = "rgba(240, 160, 32, 0.6)"
    , colorEndWarning = common.warningColor
    , colorStartError = "rgba(208, 48, 80, 0.6)"
    , colorEndError = common.errorColor
    , colorStartSuccess = "rgba(24, 160, 88, 0.6)"
    , colorEndSuccess = common.successColor
    }


dark : Common -> Vars
dark common =
    { fontWeight = common.fontWeightStrong
    , rotate = "252deg"
    , colorStartPrimary = common.primaryColor
    , colorEndPrimary = common.primaryColorSuppl
    , colorStartInfo = common.infoColor
    , colorEndInfo = common.infoColorSuppl
    , colorStartWarning = common.warningColor
    , colorEndWarning = common.warningColorSuppl
    , colorStartError = common.errorColor
    , colorEndError = common.errorColorSuppl
    , colorStartSuccess = common.successColor
    , colorEndSuccess = common.successColorSuppl
    }
