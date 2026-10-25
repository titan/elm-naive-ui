module NUI.Theme.DatePicker exposing (Vars, vars)

{-| Theme variables for the **DatePicker** component — the Elm counterpart of Naive UI's
`src/DatePicker/styles/light.ts` & `dark.ts` cssr theme (selfVars). DatePicker renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`itemSize` → `--n-item-size`, `itemCellWidth` → `--n-item-cell-width`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to DatePicker's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the DatePicker CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`itemSize` → `--n-item-size`).
-}
type alias Vars =
    { itemSize : String
    , itemCellWidth : String
    , itemCellHeight : String
    , scrollItemWidth : String
    , scrollItemHeight : String
    , panelExtraFooterPadding : String
    , panelActionPadding : String
    , calendarTitlePadding : String
    , calendarTitleHeight : String
    , arrowSize : String
    , panelHeaderPadding : String
    , calendarDaysHeight : String
    , calendarTitleGridTempateColumns : String
    , calendarLeftPaddingDate : String
    , calendarLeftPaddingDatetime : String
    , calendarLeftPaddingDaterange : String
    , calendarLeftPaddingDatetimerange : String
    , calendarLeftPaddingMonth : String
    , calendarLeftPaddingYear : String
    , calendarLeftPaddingQuarter : String
    , calendarLeftPaddingMonthrange : String
    , calendarLeftPaddingQuarterrange : String
    , calendarLeftPaddingYearrange : String
    , calendarLeftPaddingWeek : String
    , calendarRightPaddingDate : String
    , calendarRightPaddingDatetime : String
    , calendarRightPaddingDaterange : String
    , calendarRightPaddingDatetimerange : String
    , calendarRightPaddingMonth : String
    , calendarRightPaddingYear : String
    , calendarRightPaddingQuarter : String
    , calendarRightPaddingMonthrange : String
    , calendarRightPaddingQuarterrange : String
    , calendarRightPaddingYearrange : String
    , calendarRightPaddingWeek : String
    , itemFontSize : String
    , calendarDaysFontSize : String
    , calendarTitleFontSize : String
    , itemTextColor : String
    , itemTextColorDisabled : String
    , itemTextColorActive : String
    , itemTextColorCurrent : String
    , itemColorIncluded : String
    , itemColorHover : String
    , itemColorDisabled : String
    , itemColorActive : String
    , itemBorderRadius : String
    , panelColor : String
    , panelTextColor : String
    , arrowColor : String
    , calendarTitleTextColor : String
    , calendarTitleColorHover : String
    , calendarDaysTextColor : String
    , panelHeaderDividerColor : String
    , calendarDaysDividerColor : String
    , calendarDividerColor : String
    , panelActionDividerColor : String
    , panelBoxShadow : String
    , panelBorderRadius : String
    , calendarTitleFontWeight : String
    , scrollItemBorderRadius : String
    , iconColor : String
    , iconColorDisabled : String
    }


{-| Resolve the DatePicker variables for a theme — upstream `self(common)`: Light and Dark
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
    { itemSize = "24px"
    , itemCellWidth = "38px"
    , itemCellHeight = "32px"
    , scrollItemWidth = "80px"
    , scrollItemHeight = "40px"
    , panelExtraFooterPadding = "8px 12px"
    , panelActionPadding = "8px 12px"
    , calendarTitlePadding = "0"
    , calendarTitleHeight = "28px"
    , arrowSize = "14px"
    , panelHeaderPadding = "8px 12px"
    , calendarDaysHeight = "32px"
    , calendarTitleGridTempateColumns = "28px 28px 1fr 28px 28px"
    , calendarLeftPaddingDate = "6px 12px 4px 12px"
    , calendarLeftPaddingDatetime = "4px 12px"
    , calendarLeftPaddingDaterange = "6px 12px 4px 12px"
    , calendarLeftPaddingDatetimerange = "4px 12px"
    , calendarLeftPaddingMonth = "0"
    , calendarLeftPaddingYear = "0"
    , calendarLeftPaddingQuarter = "0"
    , calendarLeftPaddingMonthrange = "0"
    , calendarLeftPaddingQuarterrange = "0"
    , calendarLeftPaddingYearrange = "0"
    , calendarLeftPaddingWeek = "6px 12px 4px 12px"
    , calendarRightPaddingDate = "6px 12px 4px 12px"
    , calendarRightPaddingDatetime = "4px 12px"
    , calendarRightPaddingDaterange = "6px 12px 4px 12px"
    , calendarRightPaddingDatetimerange = "4px 12px"
    , calendarRightPaddingMonth = "0"
    , calendarRightPaddingYear = "0"
    , calendarRightPaddingQuarter = "0"
    , calendarRightPaddingMonthrange = "0"
    , calendarRightPaddingQuarterrange = "0"
    , calendarRightPaddingYearrange = "0"
    , calendarRightPaddingWeek = "0"
    , itemFontSize = common.fontSize
    , calendarDaysFontSize = common.fontSize
    , calendarTitleFontSize = common.fontSize
    , itemTextColor = common.textColor2
    , itemTextColorDisabled = common.textColorDisabled
    , itemTextColorActive = common.popoverColor
    , itemTextColorCurrent = common.primaryColor
    , itemColorIncluded = "rgba(24, 160, 88, 0.1)"
    , itemColorHover = common.hoverColor
    , itemColorDisabled = common.hoverColor
    , itemColorActive = common.primaryColor
    , itemBorderRadius = common.borderRadiusSmall
    , panelColor = common.popoverColor
    , panelTextColor = common.textColor2
    , arrowColor = common.iconColor
    , calendarTitleTextColor = common.textColor1
    , calendarTitleColorHover = common.hoverColor
    , calendarDaysTextColor = common.textColor2
    , panelHeaderDividerColor = common.dividerColor
    , calendarDaysDividerColor = common.dividerColor
    , calendarDividerColor = common.dividerColor
    , panelActionDividerColor = common.dividerColor
    , panelBoxShadow = common.boxShadow2
    , panelBorderRadius = common.borderRadius
    , calendarTitleFontWeight = common.fontWeightStrong
    , scrollItemBorderRadius = common.borderRadius
    , iconColor = common.iconColor
    , iconColorDisabled = common.iconColorDisabled
    }


dark : Common -> Vars
dark common =
    { itemSize = "24px"
    , itemCellWidth = "38px"
    , itemCellHeight = "32px"
    , scrollItemWidth = "80px"
    , scrollItemHeight = "40px"
    , panelExtraFooterPadding = "8px 12px"
    , panelActionPadding = "8px 12px"
    , calendarTitlePadding = "0"
    , calendarTitleHeight = "28px"
    , arrowSize = "14px"
    , panelHeaderPadding = "8px 12px"
    , calendarDaysHeight = "32px"
    , calendarTitleGridTempateColumns = "28px 28px 1fr 28px 28px"
    , calendarLeftPaddingDate = "6px 12px 4px 12px"
    , calendarLeftPaddingDatetime = "4px 12px"
    , calendarLeftPaddingDaterange = "6px 12px 4px 12px"
    , calendarLeftPaddingDatetimerange = "4px 12px"
    , calendarLeftPaddingMonth = "0"
    , calendarLeftPaddingYear = "0"
    , calendarLeftPaddingQuarter = "0"
    , calendarLeftPaddingMonthrange = "0"
    , calendarLeftPaddingQuarterrange = "0"
    , calendarLeftPaddingYearrange = "0"
    , calendarLeftPaddingWeek = "6px 12px 4px 12px"
    , calendarRightPaddingDate = "6px 12px 4px 12px"
    , calendarRightPaddingDatetime = "4px 12px"
    , calendarRightPaddingDaterange = "6px 12px 4px 12px"
    , calendarRightPaddingDatetimerange = "4px 12px"
    , calendarRightPaddingMonth = "0"
    , calendarRightPaddingYear = "0"
    , calendarRightPaddingQuarter = "0"
    , calendarRightPaddingMonthrange = "0"
    , calendarRightPaddingQuarterrange = "0"
    , calendarRightPaddingYearrange = "0"
    , calendarRightPaddingWeek = "0"
    , itemFontSize = common.fontSize
    , calendarDaysFontSize = common.fontSize
    , calendarTitleFontSize = common.fontSize
    , itemTextColor = common.textColor2
    , itemTextColorDisabled = common.textColorDisabled
    , itemTextColorActive = common.popoverColor
    , itemTextColorCurrent = common.primaryColor
    , itemColorIncluded = "rgba(99, 226, 183, 0.15)"
    , itemColorHover = "rgba(88, 88, 94, 1)"
    , itemColorDisabled = "rgba(88, 88, 94, 1)"
    , itemColorActive = common.primaryColor
    , itemBorderRadius = common.borderRadiusSmall
    , panelColor = common.popoverColor
    , panelTextColor = common.textColor2
    , arrowColor = common.iconColor
    , calendarTitleTextColor = common.textColor1
    , calendarTitleColorHover = common.hoverColor
    , calendarDaysTextColor = common.textColor2
    , panelHeaderDividerColor = common.dividerColor
    , calendarDaysDividerColor = common.dividerColor
    , calendarDividerColor = common.dividerColor
    , panelActionDividerColor = common.dividerColor
    , panelBoxShadow = common.boxShadow2
    , panelBorderRadius = common.borderRadius
    , calendarTitleFontWeight = common.fontWeightStrong
    , scrollItemBorderRadius = common.borderRadius
    , iconColor = common.iconColor
    , iconColorDisabled = common.iconColorDisabled
    }
