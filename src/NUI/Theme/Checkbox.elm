module NUI.Theme.Checkbox exposing (Vars, vars)

{-| Naive UI checkbox theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { sizeSmall : String
    , sizeMedium : String
    , sizeLarge : String
    , labelPadding : String
    , labelFontWeight : String
    , labelLineHeight : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , borderRadius : String
    , color : String
    , colorChecked : String
    , colorDisabled : String
    , colorDisabledChecked : String
    , colorTableHeader : String
    , colorTableHeaderModal : String
    , colorTableHeaderPopover : String
    , checkMarkColor : String
    , checkMarkColorDisabled : String
    , checkMarkColorDisabledChecked : String
    , border : String
    , borderDisabled : String
    , borderDisabledChecked : String
    , borderChecked : String
    , borderFocus : String
    , boxShadowFocus : String
    , textColor : String
    , textColorDisabled : String
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
    { sizeSmall = "14px"
    , sizeMedium = "16px"
    , sizeLarge = "18px"
    , labelPadding = "0 8px"
    , labelFontWeight = "400"
    , labelLineHeight = common.lineHeight
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , borderRadius = common.borderRadiusSmall
    , color = common.baseColor
    , colorChecked = common.primaryColor
    , colorDisabled = common.inputColorDisabled
    , colorDisabledChecked = common.inputColorDisabled
    , colorTableHeader = common.cardColor
    , colorTableHeaderModal = common.modalColor
    , colorTableHeaderPopover = common.popoverColor
    , checkMarkColor = common.baseColor
    , checkMarkColorDisabled = common.textColorDisabled
    , checkMarkColorDisabledChecked = common.textColorDisabled
    , border = "1px solid rgb(224, 224, 230)"
    , borderDisabled = "1px solid rgb(224, 224, 230)"
    , borderDisabledChecked = "1px solid rgb(224, 224, 230)"
    , borderChecked = "1px solid #18a058"
    , borderFocus = "1px solid #18a058"
    , boxShadowFocus = "0 0 0 2px rgba(24, 160, 88, 0.3)"
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    }


dark : Common -> Vars
dark common =
    { sizeSmall = "14px"
    , sizeMedium = "16px"
    , sizeLarge = "18px"
    , labelPadding = "0 8px"
    , labelFontWeight = "400"
    , labelLineHeight = common.lineHeight
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , borderRadius = common.borderRadiusSmall
    , color = "#0000"
    , colorChecked = common.primaryColor
    , colorDisabled = common.inputColorDisabled
    , colorDisabledChecked = common.inputColorDisabled
    , colorTableHeader = common.cardColor
    , colorTableHeaderModal = common.modalColor
    , colorTableHeaderPopover = common.popoverColor
    , checkMarkColor = common.cardColor
    , checkMarkColorDisabled = common.textColorDisabled
    , checkMarkColorDisabledChecked = common.textColorDisabled
    , border = "1px solid rgba(255, 255, 255, 0.24)"
    , borderDisabled = "1px solid rgba(255, 255, 255, 0.24)"
    , borderDisabledChecked = "1px solid rgba(255, 255, 255, 0.24)"
    , borderChecked = "1px solid #63e2b7"
    , borderFocus = "1px solid #63e2b7"
    , boxShadowFocus = "0 0 0 2px rgba(99, 226, 183, 0.3)"
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    }
