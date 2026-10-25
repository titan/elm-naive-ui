module NUI.Theme.Form exposing (Vars, vars)

{-| Theme variables for the **Form** component — the Elm counterpart of Naive UI's
`src/Form/styles/light.ts` & `dark.ts` cssr theme (selfVars). Form renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`feedbackPadding` → `--n-feedback-padding`, `feedbackHeightSmall` → `--n-feedback-height-small`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Form's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Form CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`feedbackPadding` → `--n-feedback-padding`).
-}
type alias Vars =
    { feedbackPadding : String
    , feedbackHeightSmall : String
    , feedbackHeightMedium : String
    , feedbackHeightLarge : String
    , feedbackFontSizeSmall : String
    , feedbackFontSizeMedium : String
    , feedbackFontSizeLarge : String
    , labelFontSizeLeftSmall : String
    , labelFontSizeLeftMedium : String
    , labelFontSizeLeftLarge : String
    , labelFontSizeTopSmall : String
    , labelFontSizeTopMedium : String
    , labelFontSizeTopLarge : String
    , labelHeightSmall : String
    , labelHeightMedium : String
    , labelHeightLarge : String
    , labelPaddingVertical : String
    , labelPaddingHorizontal : String
    , labelTextAlignVertical : String
    , labelTextAlignHorizontal : String
    , labelFontWeight : String
    , blankHeightSmall : String
    , blankHeightMedium : String
    , blankHeightLarge : String
    , lineHeight : String
    , labelTextColor : String
    , asteriskColor : String
    , feedbackTextColorError : String
    , feedbackTextColorWarning : String
    , feedbackTextColor : String
    }


{-| Resolve the Form variables for a theme — upstream `self(common)`: Light and Dark
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
    { feedbackPadding = "4px 0 0 2px"
    , feedbackHeightSmall = "24px"
    , feedbackHeightMedium = "24px"
    , feedbackHeightLarge = "26px"
    , feedbackFontSizeSmall = "13px"
    , feedbackFontSizeMedium = "14px"
    , feedbackFontSizeLarge = "14px"
    , labelFontSizeLeftSmall = "14px"
    , labelFontSizeLeftMedium = "14px"
    , labelFontSizeLeftLarge = "15px"
    , labelFontSizeTopSmall = "13px"
    , labelFontSizeTopMedium = "14px"
    , labelFontSizeTopLarge = "14px"
    , labelHeightSmall = "24px"
    , labelHeightMedium = "26px"
    , labelHeightLarge = "28px"
    , labelPaddingVertical = "0 0 6px 2px"
    , labelPaddingHorizontal = "0 12px 0 0"
    , labelTextAlignVertical = "left"
    , labelTextAlignHorizontal = "right"
    , labelFontWeight = "400"
    , blankHeightSmall = common.heightSmall
    , blankHeightMedium = common.heightMedium
    , blankHeightLarge = common.heightLarge
    , lineHeight = common.lineHeight
    , labelTextColor = common.textColor1
    , asteriskColor = common.errorColor
    , feedbackTextColorError = common.errorColor
    , feedbackTextColorWarning = common.warningColor
    , feedbackTextColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { feedbackPadding = "4px 0 0 2px"
    , feedbackHeightSmall = "24px"
    , feedbackHeightMedium = "24px"
    , feedbackHeightLarge = "26px"
    , feedbackFontSizeSmall = "13px"
    , feedbackFontSizeMedium = "14px"
    , feedbackFontSizeLarge = "14px"
    , labelFontSizeLeftSmall = "14px"
    , labelFontSizeLeftMedium = "14px"
    , labelFontSizeLeftLarge = "15px"
    , labelFontSizeTopSmall = "13px"
    , labelFontSizeTopMedium = "14px"
    , labelFontSizeTopLarge = "14px"
    , labelHeightSmall = "24px"
    , labelHeightMedium = "26px"
    , labelHeightLarge = "28px"
    , labelPaddingVertical = "0 0 6px 2px"
    , labelPaddingHorizontal = "0 12px 0 0"
    , labelTextAlignVertical = "left"
    , labelTextAlignHorizontal = "right"
    , labelFontWeight = "400"
    , blankHeightSmall = common.heightSmall
    , blankHeightMedium = common.heightMedium
    , blankHeightLarge = common.heightLarge
    , lineHeight = common.lineHeight
    , labelTextColor = common.textColor1
    , asteriskColor = common.errorColor
    , feedbackTextColorError = common.errorColor
    , feedbackTextColorWarning = common.warningColor
    , feedbackTextColor = common.textColor3
    }
