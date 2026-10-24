module NUI.Theme.Descriptions exposing (Vars, vars)

{-| Theme variables for the **Descriptions** component — the Elm counterpart of Naive UI's
`src/Descriptions/styles/light.ts` & `dark.ts` cssr theme (selfVars). Descriptions renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`thPaddingBorderedSmall` → `--n-th-padding-bordered-small`, `thPaddingBorderedMedium` → `--n-th-padding-bordered-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Descriptions's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Descriptions CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`thPaddingBorderedSmall` → `--n-th-padding-bordered-small`).

Collected by concern:

  - per-size th/td paddings (bordered & not): `thPaddingBorderedSmall`, `thPaddingBorderedMedium`, `thPaddingBorderedLarge`, `thPaddingSmall`, `thPaddingMedium`, `thPaddingLarge`, `tdPaddingBorderedSmall`, `tdPaddingBorderedMedium`, `tdPaddingBorderedLarge`, `tdPaddingSmall`, `tdPaddingMedium`, `tdPaddingLarge`
  - typography & shape: `lineHeight`, `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`, `titleTextColor`, `thFontWeight`, `borderRadius`
  - surfaces incl. modal & popover: `thColor`, `thColorModal`, `thColorPopover`, `thTextColor`, `tdTextColor`, `tdColor`, `tdColorModal`, `tdColorPopover`, `borderColor`, `borderColorModal`, `borderColorPopover`

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


{-| Resolve the Descriptions variables for a theme — upstream `self(common)`: Light and Dark
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
