module NUI.Theme.Empty exposing (Vars, vars)

{-| Naive UI empty theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { iconSizeTiny : String
    , iconSizeSmall : String
    , iconSizeMedium : String
    , iconSizeLarge : String
    , iconSizeHuge : String
    , fontSizeTiny : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , textColor : String
    , iconColor : String
    , extraTextColor : String
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
    { iconSizeTiny = "28px"
    , iconSizeSmall = "34px"
    , iconSizeMedium = "40px"
    , iconSizeLarge = "46px"
    , iconSizeHuge = "52px"
    , fontSizeTiny = common.fontSizeMini
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSizeLarge
    , fontSizeHuge = common.fontSizeHuge
    , textColor = common.textColorDisabled
    , iconColor = common.textColorDisabled
    , extraTextColor = common.textColor2
    }


dark : Common -> Vars
dark common =
    { iconSizeTiny = "28px"
    , iconSizeSmall = "34px"
    , iconSizeMedium = "40px"
    , iconSizeLarge = "46px"
    , iconSizeHuge = "52px"
    , fontSizeTiny = common.fontSizeMini
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSizeLarge
    , fontSizeHuge = common.fontSizeHuge
    , textColor = common.textColorDisabled
    , iconColor = common.textColorDisabled
    , extraTextColor = common.textColor2
    }
