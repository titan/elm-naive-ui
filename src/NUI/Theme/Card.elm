module NUI.Theme.Card exposing (Vars, vars)


{-| Naive UI card theme variables.
-}


import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { paddingSmall : String
    , paddingMedium : String
    , paddingLarge : String
    , paddingHuge : String
    , titleFontSizeSmall : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , titleFontSizeHuge : String
    , closeIconSize : String
    , closeSize : String
    , lineHeight : String
    , color : String
    , colorModal : String
    , colorPopover : String
    , colorTarget : String
    , colorEmbedded : String
    , colorEmbeddedModal : String
    , colorEmbeddedPopover : String
    , textColor : String
    , titleTextColor : String
    , borderColor : String
    , actionColor : String
    , titleFontWeight : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeBorderRadius : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , boxShadow : String
    , borderRadius : String
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
    { paddingSmall = "12px 16px 12px"
    , paddingMedium = "19px 24px 20px"
    , paddingLarge = "23px 32px 24px"
    , paddingHuge = "27px 40px 28px"
    , titleFontSizeSmall = common.fontSizeHuge
    , titleFontSizeMedium = "18px"
    , titleFontSizeLarge = "18px"
    , titleFontSizeHuge = "18px"
    , closeIconSize = "18px"
    , closeSize = common.heightTiny
    , lineHeight = common.lineHeight
    , color = common.tableColor
    , colorModal = common.modalColor
    , colorPopover = common.popoverColor
    , colorTarget = common.primaryColor
    , colorEmbedded = "rgb(250, 250, 252)"
    , colorEmbeddedModal = "rgb(250, 250, 252)"
    , colorEmbeddedPopover = "rgb(250, 250, 252)"
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , borderColor = common.dividerColor
    , actionColor = common.actionColor
    , titleFontWeight = common.fontWeightStrong
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColor
    , closeIconColorPressed = common.closeIconColor
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSize
    , fontSizeHuge = common.fontSize
    , boxShadow = common.boxShadow1
    , borderRadius = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { paddingSmall = "12px 16px 12px"
    , paddingMedium = "19px 24px 20px"
    , paddingLarge = "23px 32px 24px"
    , paddingHuge = "27px 40px 28px"
    , titleFontSizeSmall = common.fontSizeHuge
    , titleFontSizeMedium = "18px"
    , titleFontSizeLarge = "18px"
    , titleFontSizeHuge = "18px"
    , closeIconSize = "18px"
    , closeSize = common.heightTiny
    , lineHeight = common.lineHeight
    , color = common.tableColor
    , colorModal = common.modalColor
    , colorPopover = common.popoverColor
    , colorTarget = common.primaryColor
    , colorEmbedded = "rgb(24, 24, 28)"
    , colorEmbeddedModal = "rgb(44, 44, 50)"
    , colorEmbeddedPopover = "rgb(72, 72, 78)"
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , borderColor = common.dividerColor
    , actionColor = common.actionColor
    , titleFontWeight = common.fontWeightStrong
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColor
    , closeIconColorPressed = common.closeIconColor
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSize
    , fontSizeHuge = common.fontSize
    , boxShadow = common.boxShadow1
    , borderRadius = common.borderRadius
    }
