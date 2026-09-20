module NUI.Theme.Typography exposing (Vars, vars)

{-| Naive UI typography theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { headerFontSize1 : String
    , headerFontSize2 : String
    , headerFontSize3 : String
    , headerFontSize4 : String
    , headerFontSize5 : String
    , headerFontSize6 : String
    , headerMargin1 : String
    , headerMargin2 : String
    , headerMargin3 : String
    , headerMargin4 : String
    , headerMargin5 : String
    , headerMargin6 : String
    , headerPrefixWidth1 : String
    , headerPrefixWidth2 : String
    , headerPrefixWidth3 : String
    , headerPrefixWidth4 : String
    , headerPrefixWidth5 : String
    , headerPrefixWidth6 : String
    , headerBarWidth1 : String
    , headerBarWidth2 : String
    , headerBarWidth3 : String
    , headerBarWidth4 : String
    , headerBarWidth5 : String
    , headerBarWidth6 : String
    , pMargin : String
    , liMargin : String
    , olPadding : String
    , ulPadding : String
    , aTextColor : String
    , blockquoteTextColor : String
    , blockquotePrefixColor : String
    , blockquoteLineHeight : String
    , blockquoteFontSize : String
    , codeBorderRadius : String
    , liTextColor : String
    , liLineHeight : String
    , liFontSize : String
    , hrColor : String
    , headerFontWeight : String
    , headerTextColor : String
    , pTextColor : String
    , pTextColor1Depth : String
    , pTextColor2Depth : String
    , pTextColor3Depth : String
    , pLineHeight : String
    , pFontSize : String
    , headerBarColor : String
    , headerBarColorPrimary : String
    , headerBarColorInfo : String
    , headerBarColorError : String
    , headerBarColorWarning : String
    , headerBarColorSuccess : String
    , textColor : String
    , textColor1Depth : String
    , textColor2Depth : String
    , textColor3Depth : String
    , textColorPrimary : String
    , textColorInfo : String
    , textColorSuccess : String
    , textColorWarning : String
    , textColorError : String
    , codeTextColor : String
    , codeColor : String
    , codeBorder : String
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
    { headerFontSize1 = "30px"
    , headerFontSize2 = common.heightTiny
    , headerFontSize3 = "18px"
    , headerFontSize4 = common.fontSizeHuge
    , headerFontSize5 = common.fontSizeHuge
    , headerFontSize6 = common.fontSizeHuge
    , headerMargin1 = "28px 0 20px 0"
    , headerMargin2 = "28px 0 20px 0"
    , headerMargin3 = "28px 0 20px 0"
    , headerMargin4 = "28px 0 18px 0"
    , headerMargin5 = "28px 0 18px 0"
    , headerMargin6 = "28px 0 18px 0"
    , headerPrefixWidth1 = common.fontSizeHuge
    , headerPrefixWidth2 = common.fontSizeHuge
    , headerPrefixWidth3 = common.fontSizeMini
    , headerPrefixWidth4 = common.fontSizeMini
    , headerPrefixWidth5 = common.fontSizeMini
    , headerPrefixWidth6 = common.fontSizeMini
    , headerBarWidth1 = "4px"
    , headerBarWidth2 = "4px"
    , headerBarWidth3 = common.borderRadius
    , headerBarWidth4 = common.borderRadius
    , headerBarWidth5 = common.borderRadius
    , headerBarWidth6 = common.borderRadius
    , pMargin = "16px 0 16px 0"
    , liMargin = ".25em 0 0 0"
    , olPadding = "0 0 0 2em"
    , ulPadding = "0 0 0 2em"
    , aTextColor = common.primaryColor
    , blockquoteTextColor = common.textColor2
    , blockquotePrefixColor = common.borderColor
    , blockquoteLineHeight = common.lineHeight
    , blockquoteFontSize = common.fontSize
    , codeBorderRadius = common.borderRadiusSmall
    , liTextColor = common.textColor2
    , liLineHeight = common.lineHeight
    , liFontSize = common.fontSize
    , hrColor = common.dividerColor
    , headerFontWeight = common.fontWeightStrong
    , headerTextColor = common.textColor1
    , pTextColor = common.textColor2
    , pTextColor1Depth = common.textColor1
    , pTextColor2Depth = common.textColor2
    , pTextColor3Depth = common.textColor3
    , pLineHeight = common.lineHeight
    , pFontSize = common.fontSize
    , headerBarColor = common.primaryColor
    , headerBarColorPrimary = common.primaryColor
    , headerBarColorInfo = common.infoColor
    , headerBarColorError = common.errorColor
    , headerBarColorWarning = common.warningColor
    , headerBarColorSuccess = common.successColor
    , textColor = common.textColor2
    , textColor1Depth = common.textColor1
    , textColor2Depth = common.textColor2
    , textColor3Depth = common.textColor3
    , textColorPrimary = common.primaryColor
    , textColorInfo = common.infoColor
    , textColorSuccess = common.successColor
    , textColorWarning = common.warningColor
    , textColorError = common.errorColor
    , codeTextColor = common.textColor2
    , codeColor = common.codeColor
    , codeBorder = "1px solid #0000"
    }


dark : Common -> Vars
dark common =
    { headerFontSize1 = "30px"
    , headerFontSize2 = common.heightTiny
    , headerFontSize3 = "18px"
    , headerFontSize4 = common.fontSizeHuge
    , headerFontSize5 = common.fontSizeHuge
    , headerFontSize6 = common.fontSizeHuge
    , headerMargin1 = "28px 0 20px 0"
    , headerMargin2 = "28px 0 20px 0"
    , headerMargin3 = "28px 0 20px 0"
    , headerMargin4 = "28px 0 18px 0"
    , headerMargin5 = "28px 0 18px 0"
    , headerMargin6 = "28px 0 18px 0"
    , headerPrefixWidth1 = common.fontSizeHuge
    , headerPrefixWidth2 = common.fontSizeHuge
    , headerPrefixWidth3 = common.fontSizeMini
    , headerPrefixWidth4 = common.fontSizeMini
    , headerPrefixWidth5 = common.fontSizeMini
    , headerPrefixWidth6 = common.fontSizeMini
    , headerBarWidth1 = "4px"
    , headerBarWidth2 = "4px"
    , headerBarWidth3 = common.borderRadius
    , headerBarWidth4 = common.borderRadius
    , headerBarWidth5 = common.borderRadius
    , headerBarWidth6 = common.borderRadius
    , pMargin = "16px 0 16px 0"
    , liMargin = ".25em 0 0 0"
    , olPadding = "0 0 0 2em"
    , ulPadding = "0 0 0 2em"
    , aTextColor = common.primaryColor
    , blockquoteTextColor = common.textColor2
    , blockquotePrefixColor = common.borderColor
    , blockquoteLineHeight = common.lineHeight
    , blockquoteFontSize = common.fontSize
    , codeBorderRadius = common.borderRadiusSmall
    , liTextColor = common.textColor2
    , liLineHeight = common.lineHeight
    , liFontSize = common.fontSize
    , hrColor = common.dividerColor
    , headerFontWeight = common.fontWeightStrong
    , headerTextColor = common.textColor1
    , pTextColor = common.textColor2
    , pTextColor1Depth = common.textColor1
    , pTextColor2Depth = common.textColor2
    , pTextColor3Depth = common.textColor3
    , pLineHeight = common.lineHeight
    , pFontSize = common.fontSize
    , headerBarColor = common.primaryColor
    , headerBarColorPrimary = common.primaryColor
    , headerBarColorInfo = common.infoColor
    , headerBarColorError = common.errorColor
    , headerBarColorWarning = common.warningColor
    , headerBarColorSuccess = common.successColor
    , textColor = common.textColor2
    , textColor1Depth = common.textColor1
    , textColor2Depth = common.textColor2
    , textColor3Depth = common.textColor3
    , textColorPrimary = common.primaryColor
    , textColorInfo = common.infoColor
    , textColorSuccess = common.successColor
    , textColorWarning = common.warningColor
    , textColorError = common.errorColor
    , codeTextColor = common.textColor2
    , codeColor = common.codeColor
    , codeBorder = "1px solid #0000"
    }
