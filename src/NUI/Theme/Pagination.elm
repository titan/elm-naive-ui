module NUI.Theme.Pagination exposing (Vars, vars)

{-| Naive UI pagination theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { itemPaddingSmall : String
    , itemMarginSmall : String
    , itemMarginSmallRtl : String
    , itemPaddingMedium : String
    , itemMarginMedium : String
    , itemMarginMediumRtl : String
    , itemPaddingLarge : String
    , itemMarginLarge : String
    , itemMarginLargeRtl : String
    , buttonIconSizeSmall : String
    , buttonIconSizeMedium : String
    , buttonIconSizeLarge : String
    , inputWidthSmall : String
    , selectWidthSmall : String
    , inputMarginSmall : String
    , inputMarginSmallRtl : String
    , selectMarginSmall : String
    , prefixMarginSmall : String
    , suffixMarginSmall : String
    , inputWidthMedium : String
    , selectWidthMedium : String
    , inputMarginMedium : String
    , inputMarginMediumRtl : String
    , selectMarginMedium : String
    , prefixMarginMedium : String
    , suffixMarginMedium : String
    , inputWidthLarge : String
    , selectWidthLarge : String
    , inputMarginLarge : String
    , inputMarginLargeRtl : String
    , selectMarginLarge : String
    , prefixMarginLarge : String
    , suffixMarginLarge : String
    , buttonColor : String
    , buttonColorHover : String
    , buttonColorPressed : String
    , buttonBorder : String
    , buttonBorderHover : String
    , buttonBorderPressed : String
    , buttonIconColor : String
    , buttonIconColorHover : String
    , buttonIconColorPressed : String
    , itemTextColor : String
    , itemTextColorHover : String
    , itemTextColorPressed : String
    , itemTextColorActive : String
    , itemTextColorDisabled : String
    , itemColor : String
    , itemColorHover : String
    , itemColorPressed : String
    , itemColorActive : String
    , itemColorActiveHover : String
    , itemColorDisabled : String
    , itemBorder : String
    , itemBorderHover : String
    , itemBorderPressed : String
    , itemBorderActive : String
    , itemBorderDisabled : String
    , itemBorderRadius : String
    , itemSizeSmall : String
    , itemSizeMedium : String
    , itemSizeLarge : String
    , itemFontSizeSmall : String
    , itemFontSizeMedium : String
    , itemFontSizeLarge : String
    , jumperFontSizeSmall : String
    , jumperFontSizeMedium : String
    , jumperFontSizeLarge : String
    , jumperTextColor : String
    , jumperTextColorDisabled : String
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
    { itemPaddingSmall = "0 4px"
    , itemMarginSmall = "0 0 0 8px"
    , itemMarginSmallRtl = "0 8px 0 0"
    , itemPaddingMedium = "0 4px"
    , itemMarginMedium = "0 0 0 8px"
    , itemMarginMediumRtl = "0 8px 0 0"
    , itemPaddingLarge = "0 4px"
    , itemMarginLarge = "0 0 0 8px"
    , itemMarginLargeRtl = "0 8px 0 0"
    , buttonIconSizeSmall = "14px"
    , buttonIconSizeMedium = "16px"
    , buttonIconSizeLarge = "18px"
    , inputWidthSmall = "60px"
    , selectWidthSmall = "unset"
    , inputMarginSmall = "0 0 0 8px"
    , inputMarginSmallRtl = "0 8px 0 0"
    , selectMarginSmall = "0 0 0 8px"
    , prefixMarginSmall = "0 8px 0 0"
    , suffixMarginSmall = "0 0 0 8px"
    , inputWidthMedium = "60px"
    , selectWidthMedium = "unset"
    , inputMarginMedium = "0 0 0 8px"
    , inputMarginMediumRtl = "0 8px 0 0"
    , selectMarginMedium = "0 0 0 8px"
    , prefixMarginMedium = "0 8px 0 0"
    , suffixMarginMedium = "0 0 0 8px"
    , inputWidthLarge = "60px"
    , selectWidthLarge = "unset"
    , inputMarginLarge = "0 0 0 8px"
    , inputMarginLargeRtl = "0 8px 0 0"
    , selectMarginLarge = "0 0 0 8px"
    , prefixMarginLarge = "0 8px 0 0"
    , suffixMarginLarge = "0 0 0 8px"
    , buttonColor = "#0000"
    , buttonColorHover = "#0000"
    , buttonColorPressed = "#0000"
    , buttonBorder = "1px solid rgb(224, 224, 230)"
    , buttonBorderHover = "1px solid rgb(224, 224, 230)"
    , buttonBorderPressed = "1px solid rgb(224, 224, 230)"
    , buttonIconColor = common.textColor2
    , buttonIconColorHover = common.textColor2
    , buttonIconColorPressed = common.textColor2
    , itemTextColor = common.textColor2
    , itemTextColorHover = common.primaryColorHover
    , itemTextColorPressed = common.primaryColorPressed
    , itemTextColorActive = common.primaryColor
    , itemTextColorDisabled = common.textColorDisabled
    , itemColor = "#0000"
    , itemColorHover = "#0000"
    , itemColorPressed = "#0000"
    , itemColorActive = "#0000"
    , itemColorActiveHover = "#0000"
    , itemColorDisabled = common.inputColorDisabled
    , itemBorder = "1px solid #0000"
    , itemBorderHover = "1px solid #0000"
    , itemBorderPressed = "1px solid #0000"
    , itemBorderActive = "1px solid #18a058"
    , itemBorderDisabled = "1px solid rgb(224, 224, 230)"
    , itemBorderRadius = common.borderRadius
    , itemSizeSmall = "22px"
    , itemSizeMedium = common.heightSmall
    , itemSizeLarge = common.heightMedium
    , itemFontSizeSmall = "12px"
    , itemFontSizeMedium = common.fontSizeSmall
    , itemFontSizeLarge = common.fontSizeMedium
    , jumperFontSizeSmall = "12px"
    , jumperFontSizeMedium = common.fontSizeSmall
    , jumperFontSizeLarge = common.fontSizeMedium
    , jumperTextColor = common.textColor2
    , jumperTextColorDisabled = common.textColorDisabled
    }


dark : Common -> Vars
dark common =
    { itemPaddingSmall = "0 4px"
    , itemMarginSmall = "0 0 0 8px"
    , itemMarginSmallRtl = "0 8px 0 0"
    , itemPaddingMedium = "0 4px"
    , itemMarginMedium = "0 0 0 8px"
    , itemMarginMediumRtl = "0 8px 0 0"
    , itemPaddingLarge = "0 4px"
    , itemMarginLarge = "0 0 0 8px"
    , itemMarginLargeRtl = "0 8px 0 0"
    , buttonIconSizeSmall = "14px"
    , buttonIconSizeMedium = "16px"
    , buttonIconSizeLarge = "18px"
    , inputWidthSmall = "60px"
    , selectWidthSmall = "unset"
    , inputMarginSmall = "0 0 0 8px"
    , inputMarginSmallRtl = "0 8px 0 0"
    , selectMarginSmall = "0 0 0 8px"
    , prefixMarginSmall = "0 8px 0 0"
    , suffixMarginSmall = "0 0 0 8px"
    , inputWidthMedium = "60px"
    , selectWidthMedium = "unset"
    , inputMarginMedium = "0 0 0 8px"
    , inputMarginMediumRtl = "0 8px 0 0"
    , selectMarginMedium = "0 0 0 8px"
    , prefixMarginMedium = "0 8px 0 0"
    , suffixMarginMedium = "0 0 0 8px"
    , inputWidthLarge = "60px"
    , selectWidthLarge = "unset"
    , inputMarginLarge = "0 0 0 8px"
    , inputMarginLargeRtl = "0 8px 0 0"
    , selectMarginLarge = "0 0 0 8px"
    , prefixMarginLarge = "0 8px 0 0"
    , suffixMarginLarge = "0 0 0 8px"
    , buttonColor = "#0000"
    , buttonColorHover = "#0000"
    , buttonColorPressed = "#0000"
    , buttonBorder = "1px solid rgba(255, 255, 255, 0.24)"
    , buttonBorderHover = "1px solid rgba(255, 255, 255, 0.24)"
    , buttonBorderPressed = "1px solid rgba(255, 255, 255, 0.24)"
    , buttonIconColor = common.textColor2
    , buttonIconColorHover = common.textColor2
    , buttonIconColorPressed = common.textColor2
    , itemTextColor = common.textColor2
    , itemTextColorHover = common.primaryColorHover
    , itemTextColorPressed = common.primaryColorPressed
    , itemTextColorActive = common.primaryColor
    , itemTextColorDisabled = common.textColorDisabled
    , itemColor = "#0000"
    , itemColorHover = "#0000"
    , itemColorPressed = "#0000"
    , itemColorActive = "#0000"
    , itemColorActiveHover = "#0000"
    , itemColorDisabled = common.inputColorDisabled
    , itemBorder = "1px solid #0000"
    , itemBorderHover = "1px solid #0000"
    , itemBorderPressed = "1px solid #0000"
    , itemBorderActive = "1px solid rgba(99, 226, 183, 0.52)"
    , itemBorderDisabled = "1px solid #0000"
    , itemBorderRadius = common.borderRadius
    , itemSizeSmall = "22px"
    , itemSizeMedium = common.heightSmall
    , itemSizeLarge = common.heightMedium
    , itemFontSizeSmall = "12px"
    , itemFontSizeMedium = common.fontSizeSmall
    , itemFontSizeLarge = common.fontSizeMedium
    , jumperFontSizeSmall = "12px"
    , jumperFontSizeMedium = common.fontSizeSmall
    , jumperFontSizeLarge = common.fontSizeMedium
    , jumperTextColor = common.textColor2
    , jumperTextColorDisabled = common.textColorDisabled
    }
