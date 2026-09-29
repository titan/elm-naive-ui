module NUI.Theme.Upload exposing (Vars, vars)

{-| Naive UI upload theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { fontSize : String
    , lineHeight : String
    , borderRadius : String
    , draggerColor : String
    , draggerBorder : String
    , draggerBorderHover : String
    , itemColorHover : String
    , itemColorHoverError : String
    , itemTextColor : String
    , itemTextColorError : String
    , itemTextColorSuccess : String
    , itemIconColor : String
    , itemDisabledOpacity : String
    , itemBorderImageCardError : String
    , itemBorderImageCard : String
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
    { fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , draggerColor = common.actionColor
    , draggerBorder = "1px dashed rgb(224, 224, 230)"
    , draggerBorderHover = "1px dashed #18a058"
    , itemColorHover = common.hoverColor
    , itemColorHoverError = "rgba(208, 48, 80, 0.06)"
    , itemTextColor = common.textColor2
    , itemTextColorError = common.errorColor
    , itemTextColorSuccess = common.successColor
    , itemIconColor = common.iconColor
    , itemDisabledOpacity = common.opacityDisabled
    , itemBorderImageCardError = "1px solid #d03050"
    , itemBorderImageCard = "1px solid rgb(224, 224, 230)"
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , draggerColor = common.actionColor
    , draggerBorder = "1px dashed rgba(255, 255, 255, 0.24)"
    , draggerBorderHover = "1px dashed #63e2b7"
    , itemColorHover = common.hoverColor
    , itemColorHoverError = "rgba(232, 128, 128, 0.09)"
    , itemTextColor = common.textColor2
    , itemTextColorError = common.errorColor
    , itemTextColorSuccess = common.successColor
    , itemIconColor = common.iconColor
    , itemDisabledOpacity = common.opacityDisabled
    , itemBorderImageCardError = "1px solid #e88080"
    , itemBorderImageCard = "1px solid rgba(255, 255, 255, 0.24)"
    }
