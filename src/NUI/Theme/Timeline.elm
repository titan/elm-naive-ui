module NUI.Theme.Timeline exposing (Vars, vars)

{-| Naive UI timeline theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { titleMarginMedium : String
    , titleMarginLarge : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , iconSizeMedium : String
    , iconSizeLarge : String
    , contentFontSize : String
    , titleFontWeight : String
    , circleBorder : String
    , circleBorderInfo : String
    , circleBorderError : String
    , circleBorderSuccess : String
    , circleBorderWarning : String
    , iconColor : String
    , iconColorInfo : String
    , iconColorError : String
    , iconColorSuccess : String
    , iconColorWarning : String
    , titleTextColor : String
    , contentTextColor : String
    , metaTextColor : String
    , lineColor : String
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
    { titleMarginMedium = "0 0 6px 0"
    , titleMarginLarge = "-2px 0 6px 0"
    , titleFontSizeMedium = common.fontSize
    , titleFontSizeLarge = common.fontSizeHuge
    , iconSizeMedium = common.fontSize
    , iconSizeLarge = common.fontSize
    , contentFontSize = common.fontSize
    , titleFontWeight = common.fontWeightStrong
    , circleBorder = "2px solid rgb(118, 124, 130)"
    , circleBorderInfo = "2px solid #2080f0"
    , circleBorderError = "2px solid #d03050"
    , circleBorderSuccess = "2px solid #18a058"
    , circleBorderWarning = "2px solid #f0a020"
    , iconColor = common.textColor3
    , iconColorInfo = common.infoColor
    , iconColorError = common.errorColor
    , iconColorSuccess = common.successColor
    , iconColorWarning = common.warningColor
    , titleTextColor = common.textColor1
    , contentTextColor = common.textColor2
    , metaTextColor = common.textColor3
    , lineColor = common.railColor
    }


dark : Common -> Vars
dark common =
    { titleMarginMedium = "0 0 6px 0"
    , titleMarginLarge = "-2px 0 6px 0"
    , titleFontSizeMedium = common.fontSize
    , titleFontSizeLarge = common.fontSizeHuge
    , iconSizeMedium = common.fontSize
    , iconSizeLarge = common.fontSize
    , contentFontSize = common.fontSize
    , titleFontWeight = common.fontWeightStrong
    , circleBorder = "2px solid rgba(255, 255, 255, 0.52)"
    , circleBorderInfo = "2px solid rgb(56, 137, 197)"
    , circleBorderError = "2px solid rgb(208, 58, 82)"
    , circleBorderSuccess = "2px solid rgb(42, 148, 125)"
    , circleBorderWarning = "2px solid rgb(240, 138, 0)"
    , iconColor = common.textColor3
    , iconColorInfo = common.infoColorSuppl
    , iconColorError = common.errorColorSuppl
    , iconColorSuccess = common.successColorSuppl
    , iconColorWarning = common.warningColorSuppl
    , titleTextColor = common.textColor1
    , contentTextColor = common.textColor2
    , metaTextColor = common.textColor3
    , lineColor = common.railColor
    }
