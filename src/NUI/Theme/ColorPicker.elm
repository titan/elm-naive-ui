module NUI.Theme.ColorPicker exposing (Vars, vars)

{-| Naive UI color-picker theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { panelFontSize : String
    , boxShadow : String
    , color : String
    , textColor : String
    , borderRadius : String
    , border : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , dividerColor : String
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
    { panelFontSize = common.fontSize
    , boxShadow = common.boxShadow2
    , color = common.popoverColor
    , textColor = common.textColor2
    , borderRadius = common.borderRadius
    , border = "1px solid rgb(224, 224, 230)"
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , dividerColor = common.dividerColor
    }


dark : Common -> Vars
dark common =
    { panelFontSize = common.fontSize
    , boxShadow = common.boxShadow2
    , color = common.popoverColor
    , textColor = common.textColor2
    , borderRadius = common.borderRadius
    , border = "1px solid rgba(255, 255, 255, 0.24)"
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , dividerColor = common.dividerColor
    }
