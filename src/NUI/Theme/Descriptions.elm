module NUI.Theme.Descriptions exposing (Vars, vars)

{-| Theme variables for **Descriptions** (upstream `src/Descriptions/styles/light.ts` & `dark.ts`, cssr
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
    { thPaddingBorderedSmall : String
    , thPaddingBorderedMedium : String
    , thPaddingBorderedLarge : String
    , thPaddingSmall : String
    , thPaddingMedium : String
    , thPaddingLarge : String
    , tdPaddingBorderedSmall : String
    , tdPaddingBorderedMedium : String
    , tdPaddingBorderedLarge : String
    , tdPaddingSmall : String
    , tdPaddingMedium : String
    , tdPaddingLarge : String
    , lineHeight : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , titleTextColor : String
    , thColor : String
    , thColorModal : String
    , thColorPopover : String
    , thTextColor : String
    , thFontWeight : String
    , tdTextColor : String
    , tdColor : String
    , tdColorModal : String
    , tdColorPopover : String
    , borderColor : String
    , borderColorModal : String
    , borderColorPopover : String
    , borderRadius : String
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
    { thPaddingBorderedSmall = "8px 12px"
    , thPaddingBorderedMedium = "12px 16px"
    , thPaddingBorderedLarge = "16px 24px"
    , thPaddingSmall = "0"
    , thPaddingMedium = "0"
    , thPaddingLarge = "0"
    , tdPaddingBorderedSmall = "8px 12px"
    , tdPaddingBorderedMedium = "12px 16px"
    , tdPaddingBorderedLarge = "16px 24px"
    , tdPaddingSmall = "0 0 8px 0"
    , tdPaddingMedium = "0 0 12px 0"
    , tdPaddingLarge = "0 0 16px 0"
    , lineHeight = common.lineHeight
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , titleTextColor = common.textColor1
    , thColor = "rgba(250, 250, 252, 1)"
    , thColorModal = "rgba(250, 250, 252, 1)"
    , thColorPopover = "rgba(250, 250, 252, 1)"
    , thTextColor = common.textColor1
    , thFontWeight = common.fontWeightStrong
    , tdTextColor = common.textColor2
    , tdColor = common.cardColor
    , tdColorModal = common.modalColor
    , tdColorPopover = common.popoverColor
    , borderColor = "rgba(239, 239, 245, 1)"
    , borderColorModal = "rgba(239, 239, 245, 1)"
    , borderColorPopover = "rgba(239, 239, 245, 1)"
    , borderRadius = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { thPaddingBorderedSmall = "8px 12px"
    , thPaddingBorderedMedium = "12px 16px"
    , thPaddingBorderedLarge = "16px 24px"
    , thPaddingSmall = "0"
    , thPaddingMedium = "0"
    , thPaddingLarge = "0"
    , tdPaddingBorderedSmall = "8px 12px"
    , tdPaddingBorderedMedium = "12px 16px"
    , tdPaddingBorderedLarge = "16px 24px"
    , tdPaddingSmall = "0 0 8px 0"
    , tdPaddingMedium = "0 0 12px 0"
    , tdPaddingLarge = "0 0 16px 0"
    , lineHeight = common.lineHeight
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , titleTextColor = common.textColor1
    , thColor = "rgba(38, 38, 42, 1)"
    , thColorModal = "rgba(57, 57, 62, 1)"
    , thColorPopover = "rgba(83, 83, 89, 1)"
    , thTextColor = common.textColor1
    , thFontWeight = common.fontWeightStrong
    , tdTextColor = common.textColor2
    , tdColor = common.cardColor
    , tdColorModal = common.modalColor
    , tdColorPopover = common.popoverColor
    , borderColor = "rgba(45, 45, 48, 1)"
    , borderColorModal = "rgba(63, 63, 68, 1)"
    , borderColorPopover = "rgba(88, 88, 94, 1)"
    , borderRadius = common.borderRadius
    }
