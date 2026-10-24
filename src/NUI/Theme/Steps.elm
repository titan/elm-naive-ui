module NUI.Theme.Steps exposing (Vars, vars)

{-| Theme variables for the **Steps** component — the Elm counterpart of Naive UI's
`src/Steps/styles/light.ts` & `dark.ts` cssr theme (selfVars). Steps renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`stepHeaderFontSizeSmall` → `--n-step-header-font-size-small`, `stepHeaderFontSizeMedium` → `--n-step-header-font-size-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Steps's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Steps CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`stepHeaderFontSizeSmall` → `--n-step-header-font-size-small`).

Collected by concern:

  - per-size header & index font sizes: `stepHeaderFontSizeSmall`, `stepHeaderFontSizeMedium`, `indicatorIndexFontSizeSmall`, `indicatorIndexFontSizeMedium`, `stepHeaderFontWeight`
  - per-size indicator & icon sizes: `indicatorSizeSmall`, `indicatorSizeMedium`, `indicatorIconSizeSmall`, `indicatorIconSizeMedium`
  - state palettes (process/wait/finish/error): `indicatorTextColorProcess`, `indicatorTextColorWait`, `indicatorTextColorFinish`, `indicatorTextColorError`, `indicatorBorderColorProcess`, `indicatorBorderColorWait`, `indicatorBorderColorFinish`, `indicatorBorderColorError`, `indicatorColorProcess`, `indicatorColorWait`, `indicatorColorFinish`, `indicatorColorError`, `splitorColorProcess`, `splitorColorWait`, `splitorColorFinish`, `splitorColorError`, `headerTextColorProcess`, `headerTextColorWait`, `headerTextColorFinish`, `headerTextColorError`, `descriptionTextColorProcess`, `descriptionTextColorWait`, `descriptionTextColorFinish`, `descriptionTextColorError`

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


{-| Resolve the Steps variables for a theme — upstream `self(common)`: Light and Dark
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
