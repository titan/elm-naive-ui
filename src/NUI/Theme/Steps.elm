module NUI.Theme.Steps exposing (Vars, vars)

{-| Naive UI steps theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { stepHeaderFontSizeSmall : String
    , stepHeaderFontSizeMedium : String
    , indicatorIndexFontSizeSmall : String
    , indicatorIndexFontSizeMedium : String
    , indicatorSizeSmall : String
    , indicatorSizeMedium : String
    , indicatorIconSizeSmall : String
    , indicatorIconSizeMedium : String
    , stepHeaderFontWeight : String
    , indicatorTextColorProcess : String
    , indicatorTextColorWait : String
    , indicatorTextColorFinish : String
    , indicatorTextColorError : String
    , indicatorBorderColorProcess : String
    , indicatorBorderColorWait : String
    , indicatorBorderColorFinish : String
    , indicatorBorderColorError : String
    , indicatorColorProcess : String
    , indicatorColorWait : String
    , indicatorColorFinish : String
    , indicatorColorError : String
    , splitorColorProcess : String
    , splitorColorWait : String
    , splitorColorFinish : String
    , splitorColorError : String
    , headerTextColorProcess : String
    , headerTextColorWait : String
    , headerTextColorFinish : String
    , headerTextColorError : String
    , descriptionTextColorProcess : String
    , descriptionTextColorWait : String
    , descriptionTextColorFinish : String
    , descriptionTextColorError : String
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
    { stepHeaderFontSizeSmall = common.fontSize
    , stepHeaderFontSizeMedium = common.fontSizeHuge
    , indicatorIndexFontSizeSmall = common.fontSize
    , indicatorIndexFontSizeMedium = common.fontSizeHuge
    , indicatorSizeSmall = common.heightTiny
    , indicatorSizeMedium = common.heightSmall
    , indicatorIconSizeSmall = common.fontSize
    , indicatorIconSizeMedium = "18px"
    , stepHeaderFontWeight = common.fontWeightStrong
    , indicatorTextColorProcess = common.baseColor
    , indicatorTextColorWait = common.textColorDisabled
    , indicatorTextColorFinish = common.primaryColor
    , indicatorTextColorError = common.errorColor
    , indicatorBorderColorProcess = common.primaryColor
    , indicatorBorderColorWait = common.textColorDisabled
    , indicatorBorderColorFinish = common.primaryColor
    , indicatorBorderColorError = common.errorColor
    , indicatorColorProcess = common.primaryColor
    , indicatorColorWait = "#0000"
    , indicatorColorFinish = "#0000"
    , indicatorColorError = "#0000"
    , splitorColorProcess = common.textColorDisabled
    , splitorColorWait = common.textColorDisabled
    , splitorColorFinish = common.primaryColor
    , splitorColorError = common.textColorDisabled
    , headerTextColorProcess = common.textColor1
    , headerTextColorWait = common.textColorDisabled
    , headerTextColorFinish = common.textColorDisabled
    , headerTextColorError = common.errorColor
    , descriptionTextColorProcess = common.textColor2
    , descriptionTextColorWait = common.textColorDisabled
    , descriptionTextColorFinish = common.textColorDisabled
    , descriptionTextColorError = common.errorColor
    }


dark : Common -> Vars
dark common =
    { stepHeaderFontSizeSmall = common.fontSize
    , stepHeaderFontSizeMedium = common.fontSizeHuge
    , indicatorIndexFontSizeSmall = common.fontSize
    , indicatorIndexFontSizeMedium = common.fontSizeHuge
    , indicatorSizeSmall = common.heightTiny
    , indicatorSizeMedium = common.heightSmall
    , indicatorIconSizeSmall = common.fontSize
    , indicatorIconSizeMedium = "18px"
    , stepHeaderFontWeight = common.fontWeightStrong
    , indicatorTextColorProcess = common.baseColor
    , indicatorTextColorWait = common.textColorDisabled
    , indicatorTextColorFinish = common.primaryColor
    , indicatorTextColorError = common.errorColor
    , indicatorBorderColorProcess = common.primaryColor
    , indicatorBorderColorWait = common.textColorDisabled
    , indicatorBorderColorFinish = common.primaryColor
    , indicatorBorderColorError = common.errorColor
    , indicatorColorProcess = common.primaryColor
    , indicatorColorWait = "#0000"
    , indicatorColorFinish = "#0000"
    , indicatorColorError = "#0000"
    , splitorColorProcess = common.textColorDisabled
    , splitorColorWait = common.textColorDisabled
    , splitorColorFinish = common.primaryColor
    , splitorColorError = common.textColorDisabled
    , headerTextColorProcess = common.textColor1
    , headerTextColorWait = common.textColorDisabled
    , headerTextColorFinish = common.textColorDisabled
    , headerTextColorError = common.errorColor
    , descriptionTextColorProcess = common.textColor2
    , descriptionTextColorWait = common.textColorDisabled
    , descriptionTextColorFinish = common.textColorDisabled
    , descriptionTextColorError = common.errorColor
    }
