module NUI.Theme.Tabs exposing (Vars, vars)

{-| Theme variables for the **Tabs** component — the Elm counterpart of Naive UI's
`src/Tabs/styles/light.ts` & `dark.ts` cssr theme (selfVars). Tabs renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`tabFontSizeSmall` → `--n-tab-font-size-small`, `tabFontSizeMedium` → `--n-tab-font-size-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Tabs's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Tabs CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`tabFontSizeSmall` → `--n-tab-font-size-small`).
-}
type alias Vars =
    { tabFontSizeSmall : String
    , tabFontSizeMedium : String
    , tabFontSizeLarge : String
    , tabGapSmallLine : String
    , tabGapMediumLine : String
    , tabGapLargeLine : String
    , tabGapSmallLineVertical : String
    , tabGapMediumLineVertical : String
    , tabGapLargeLineVertical : String
    , tabPaddingSmallLine : String
    , tabPaddingMediumLine : String
    , tabPaddingLargeLine : String
    , tabPaddingVerticalSmallLine : String
    , tabPaddingVerticalMediumLine : String
    , tabPaddingVerticalLargeLine : String
    , tabGapSmallBar : String
    , tabGapMediumBar : String
    , tabGapLargeBar : String
    , tabGapSmallBarVertical : String
    , tabGapMediumBarVertical : String
    , tabGapLargeBarVertical : String
    , tabPaddingSmallBar : String
    , tabPaddingMediumBar : String
    , tabPaddingLargeBar : String
    , tabPaddingVerticalSmallBar : String
    , tabPaddingVerticalMediumBar : String
    , tabPaddingVerticalLargeBar : String
    , tabGapSmallCard : String
    , tabGapMediumCard : String
    , tabGapLargeCard : String
    , tabGapSmallCardVertical : String
    , tabGapMediumCardVertical : String
    , tabGapLargeCardVertical : String
    , tabPaddingSmallCard : String
    , tabPaddingMediumCard : String
    , tabPaddingLargeCard : String
    , tabPaddingSmallSegment : String
    , tabPaddingMediumSegment : String
    , tabPaddingLargeSegment : String
    , tabPaddingVerticalLargeSegment : String
    , tabPaddingVerticalSmallCard : String
    , tabPaddingVerticalMediumCard : String
    , tabPaddingVerticalLargeCard : String
    , tabPaddingVerticalSmallSegment : String
    , tabPaddingVerticalMediumSegment : String
    , tabGapSmallSegment : String
    , tabGapMediumSegment : String
    , tabGapLargeSegment : String
    , tabGapSmallSegmentVertical : String
    , tabGapMediumSegmentVertical : String
    , tabGapLargeSegmentVertical : String
    , panePaddingSmall : String
    , panePaddingMedium : String
    , panePaddingLarge : String
    , closeSize : String
    , closeIconSize : String
    , colorSegment : String
    , tabFontSizeCard : String
    , tabTextColorLine : String
    , tabTextColorActiveLine : String
    , tabTextColorHoverLine : String
    , tabTextColorDisabledLine : String
    , tabTextColorSegment : String
    , tabTextColorActiveSegment : String
    , tabTextColorHoverSegment : String
    , tabTextColorDisabledSegment : String
    , tabTextColorBar : String
    , tabTextColorActiveBar : String
    , tabTextColorHoverBar : String
    , tabTextColorDisabledBar : String
    , tabTextColorCard : String
    , tabTextColorHoverCard : String
    , tabTextColorActiveCard : String
    , tabTextColorDisabledCard : String
    , barColor : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeBorderRadius : String
    , tabColor : String
    , tabColorSegment : String
    , tabBorderColor : String
    , tabFontWeightActive : String
    , tabFontWeight : String
    , tabBorderRadius : String
    , paneTextColor : String
    , fontWeightStrong : String
    }


{-| Resolve the Tabs variables for a theme — upstream `self(common)`: Light and Dark
modes each get their own palette, values drawn from `theme.common`.
-}
vars : Theme -> Vars
vars theme =
    case theme.mode of
        Theme.Light ->
            light theme.common

        Theme.Dark ->
            dark theme.common


light : Common -> Vars
light common =
    { tabFontSizeSmall = "14px"
    , tabFontSizeMedium = "14px"
    , tabFontSizeLarge = "16px"
    , tabGapSmallLine = "36px"
    , tabGapMediumLine = "36px"
    , tabGapLargeLine = "36px"
    , tabGapSmallLineVertical = "8px"
    , tabGapMediumLineVertical = "8px"
    , tabGapLargeLineVertical = "8px"
    , tabPaddingSmallLine = "6px 0"
    , tabPaddingMediumLine = "10px 0"
    , tabPaddingLargeLine = "14px 0"
    , tabPaddingVerticalSmallLine = "6px 12px"
    , tabPaddingVerticalMediumLine = "8px 16px"
    , tabPaddingVerticalLargeLine = "10px 20px"
    , tabGapSmallBar = "36px"
    , tabGapMediumBar = "36px"
    , tabGapLargeBar = "36px"
    , tabGapSmallBarVertical = "8px"
    , tabGapMediumBarVertical = "8px"
    , tabGapLargeBarVertical = "8px"
    , tabPaddingSmallBar = "4px 0"
    , tabPaddingMediumBar = "6px 0"
    , tabPaddingLargeBar = "10px 0"
    , tabPaddingVerticalSmallBar = "6px 12px"
    , tabPaddingVerticalMediumBar = "8px 16px"
    , tabPaddingVerticalLargeBar = "10px 20px"
    , tabGapSmallCard = "4px"
    , tabGapMediumCard = "4px"
    , tabGapLargeCard = "4px"
    , tabGapSmallCardVertical = "4px"
    , tabGapMediumCardVertical = "4px"
    , tabGapLargeCardVertical = "4px"
    , tabPaddingSmallCard = "8px 16px"
    , tabPaddingMediumCard = "10px 20px"
    , tabPaddingLargeCard = "12px 24px"
    , tabPaddingSmallSegment = "4px 0"
    , tabPaddingMediumSegment = "6px 0"
    , tabPaddingLargeSegment = "8px 0"
    , tabPaddingVerticalLargeSegment = "0 8px"
    , tabPaddingVerticalSmallCard = "8px 12px"
    , tabPaddingVerticalMediumCard = "10px 16px"
    , tabPaddingVerticalLargeCard = "12px 20px"
    , tabPaddingVerticalSmallSegment = "0 4px"
    , tabPaddingVerticalMediumSegment = "0 6px"
    , tabGapSmallSegment = "0"
    , tabGapMediumSegment = "0"
    , tabGapLargeSegment = "0"
    , tabGapSmallSegmentVertical = "0"
    , tabGapMediumSegmentVertical = "0"
    , tabGapLargeSegmentVertical = "0"
    , panePaddingSmall = "8px 0 0 0"
    , panePaddingMedium = "12px 0 0 0"
    , panePaddingLarge = "16px 0 0 0"
    , closeSize = "18px"
    , closeIconSize = "14px"
    , colorSegment = common.tabColor
    , tabFontSizeCard = common.fontSize
    , tabTextColorLine = common.textColor1
    , tabTextColorActiveLine = common.primaryColor
    , tabTextColorHoverLine = common.primaryColor
    , tabTextColorDisabledLine = common.textColorDisabled
    , tabTextColorSegment = common.textColor1
    , tabTextColorActiveSegment = common.textColor2
    , tabTextColorHoverSegment = common.textColor2
    , tabTextColorDisabledSegment = common.textColorDisabled
    , tabTextColorBar = common.textColor1
    , tabTextColorActiveBar = common.primaryColor
    , tabTextColorHoverBar = common.primaryColor
    , tabTextColorDisabledBar = common.textColorDisabled
    , tabTextColorCard = common.textColor1
    , tabTextColorHoverCard = common.textColor1
    , tabTextColorActiveCard = common.primaryColor
    , tabTextColorDisabledCard = common.textColorDisabled
    , barColor = common.primaryColor
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , tabColor = common.tabColor
    , tabColorSegment = common.baseColor
    , tabBorderColor = common.dividerColor
    , tabFontWeightActive = common.fontWeight
    , tabFontWeight = common.fontWeight
    , tabBorderRadius = common.borderRadius
    , paneTextColor = common.textColor2
    , fontWeightStrong = common.fontWeightStrong
    }


dark : Common -> Vars
dark common =
    { tabFontSizeSmall = "14px"
    , tabFontSizeMedium = "14px"
    , tabFontSizeLarge = "16px"
    , tabGapSmallLine = "36px"
    , tabGapMediumLine = "36px"
    , tabGapLargeLine = "36px"
    , tabGapSmallLineVertical = "8px"
    , tabGapMediumLineVertical = "8px"
    , tabGapLargeLineVertical = "8px"
    , tabPaddingSmallLine = "6px 0"
    , tabPaddingMediumLine = "10px 0"
    , tabPaddingLargeLine = "14px 0"
    , tabPaddingVerticalSmallLine = "6px 12px"
    , tabPaddingVerticalMediumLine = "8px 16px"
    , tabPaddingVerticalLargeLine = "10px 20px"
    , tabGapSmallBar = "36px"
    , tabGapMediumBar = "36px"
    , tabGapLargeBar = "36px"
    , tabGapSmallBarVertical = "8px"
    , tabGapMediumBarVertical = "8px"
    , tabGapLargeBarVertical = "8px"
    , tabPaddingSmallBar = "4px 0"
    , tabPaddingMediumBar = "6px 0"
    , tabPaddingLargeBar = "10px 0"
    , tabPaddingVerticalSmallBar = "6px 12px"
    , tabPaddingVerticalMediumBar = "8px 16px"
    , tabPaddingVerticalLargeBar = "10px 20px"
    , tabGapSmallCard = "4px"
    , tabGapMediumCard = "4px"
    , tabGapLargeCard = "4px"
    , tabGapSmallCardVertical = "4px"
    , tabGapMediumCardVertical = "4px"
    , tabGapLargeCardVertical = "4px"
    , tabPaddingSmallCard = "8px 16px"
    , tabPaddingMediumCard = "10px 20px"
    , tabPaddingLargeCard = "12px 24px"
    , tabPaddingSmallSegment = "4px 0"
    , tabPaddingMediumSegment = "6px 0"
    , tabPaddingLargeSegment = "8px 0"
    , tabPaddingVerticalLargeSegment = "0 8px"
    , tabPaddingVerticalSmallCard = "8px 12px"
    , tabPaddingVerticalMediumCard = "10px 16px"
    , tabPaddingVerticalLargeCard = "12px 20px"
    , tabPaddingVerticalSmallSegment = "0 4px"
    , tabPaddingVerticalMediumSegment = "0 6px"
    , tabGapSmallSegment = "0"
    , tabGapMediumSegment = "0"
    , tabGapLargeSegment = "0"
    , tabGapSmallSegmentVertical = "0"
    , tabGapMediumSegmentVertical = "0"
    , tabGapLargeSegmentVertical = "0"
    , panePaddingSmall = "8px 0 0 0"
    , panePaddingMedium = "12px 0 0 0"
    , panePaddingLarge = "16px 0 0 0"
    , closeSize = "18px"
    , closeIconSize = "14px"
    , colorSegment = common.inputColor
    , tabFontSizeCard = common.fontSize
    , tabTextColorLine = common.textColor1
    , tabTextColorActiveLine = common.primaryColor
    , tabTextColorHoverLine = common.primaryColor
    , tabTextColorDisabledLine = common.textColorDisabled
    , tabTextColorSegment = common.textColor1
    , tabTextColorActiveSegment = common.textColor2
    , tabTextColorHoverSegment = common.textColor2
    , tabTextColorDisabledSegment = common.textColorDisabled
    , tabTextColorBar = common.textColor1
    , tabTextColorActiveBar = common.primaryColor
    , tabTextColorHoverBar = common.primaryColor
    , tabTextColorDisabledBar = common.textColorDisabled
    , tabTextColorCard = common.textColor1
    , tabTextColorHoverCard = common.textColor1
    , tabTextColorActiveCard = common.primaryColor
    , tabTextColorDisabledCard = common.textColorDisabled
    , barColor = common.primaryColor
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , tabColor = common.tabColor
    , tabColorSegment = common.inputColor
    , tabBorderColor = common.dividerColor
    , tabFontWeightActive = common.fontWeight
    , tabFontWeight = common.fontWeight
    , tabBorderRadius = common.borderRadius
    , paneTextColor = common.textColor2
    , fontWeightStrong = common.fontWeightStrong
    }
