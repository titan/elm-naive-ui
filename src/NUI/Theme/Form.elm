module NUI.Theme.Form exposing (Vars, vars)

{-| Theme variables for **Form** (upstream `src/Form/styles/light.ts` & `dark.ts`, cssr
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
