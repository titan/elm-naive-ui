module NUI.Theme.Result exposing (Vars, vars)

{-| Naive UI result theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { titleFontSizeSmall : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , titleFontSizeHuge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , iconSizeSmall : String
    , iconSizeMedium : String
    , iconSizeLarge : String
    , iconSizeHuge : String
    , lineHeight : String
    , titleFontWeight : String
    , titleTextColor : String
    , textColor : String
    , iconColorError : String
    , iconColorSuccess : String
    , iconColorInfo : String
    , iconColorWarning : String
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
    { titleFontSizeSmall = "26px"
    , titleFontSizeMedium = "32px"
    , titleFontSizeLarge = common.heightLarge
    , titleFontSizeHuge = "48px"
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSizeLarge
    , fontSizeHuge = common.fontSizeHuge
    , iconSizeSmall = "64px"
    , iconSizeMedium = "80px"
    , iconSizeLarge = "100px"
    , iconSizeHuge = "125px"
    , lineHeight = common.lineHeight
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , iconColorError = common.errorColor
    , iconColorSuccess = common.successColor
    , iconColorInfo = common.infoColor
    , iconColorWarning = common.warningColor
    }


dark : Common -> Vars
dark common =
    { titleFontSizeSmall = "26px"
    , titleFontSizeMedium = "32px"
    , titleFontSizeLarge = common.heightLarge
    , titleFontSizeHuge = "48px"
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSizeLarge
    , fontSizeHuge = common.fontSizeHuge
    , iconSizeSmall = "64px"
    , iconSizeMedium = "80px"
    , iconSizeLarge = "100px"
    , iconSizeHuge = "125px"
    , lineHeight = common.lineHeight
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , iconColorError = common.errorColor
    , iconColorSuccess = common.primaryColor
    , iconColorInfo = common.infoColor
    , iconColorWarning = common.warningColor
    }
