module NUI.Theme.Steps exposing (Vars, vars)

{-| Theme variables for **Steps** (upstream `src/Steps/styles/light.ts` & `dark.ts`, cssr
selfVars). Fields map 1:1 onto the component's `--n-*` custom properties
(kebab-case of the field name). `vars` resolves the light/dark palette from
`theme.mode` + `theme.common` — upstream's `self(common)`; override individual
fields to customise.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties this component's CSS consumes, as one record.
-}
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


{-| Resolve this component's variables for a theme (see the module doc).
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
    { stepHeaderFontSizeSmall = "14px"
    , stepHeaderFontSizeMedium = "16px"
    , indicatorIndexFontSizeSmall = "14px"
    , indicatorIndexFontSizeMedium = "16px"
    , indicatorSizeSmall = "22px"
    , indicatorSizeMedium = "28px"
    , indicatorIconSizeSmall = "14px"
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
    { stepHeaderFontSizeSmall = "14px"
    , stepHeaderFontSizeMedium = "16px"
    , indicatorIndexFontSizeSmall = "14px"
    , indicatorIndexFontSizeMedium = "16px"
    , indicatorSizeSmall = "22px"
    , indicatorSizeMedium = "28px"
    , indicatorIconSizeSmall = "14px"
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
