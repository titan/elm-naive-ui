module NUI.Theme.Switch exposing (Vars, vars)

{-| Theme variables for the **Switch** component — the Elm counterpart of Naive UI's
`src/Switch/styles/light.ts` & `dark.ts` cssr theme (selfVars). Switch renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`buttonHeightSmall` → `--n-button-height-small`, `buttonHeightMedium` → `--n-button-height-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Switch's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Switch CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`buttonHeightSmall` → `--n-button-height-small`).
-}
type alias Vars =
    { buttonHeightSmall : String
    , buttonHeightMedium : String
    , buttonHeightLarge : String
    , buttonWidthSmall : String
    , buttonWidthMedium : String
    , buttonWidthLarge : String
    , buttonWidthPressedSmall : String
    , buttonWidthPressedMedium : String
    , buttonWidthPressedLarge : String
    , railHeightSmall : String
    , railHeightMedium : String
    , railHeightLarge : String
    , railWidthSmall : String
    , railWidthMedium : String
    , railWidthLarge : String
    , iconColor : String
    , textColor : String
    , loadingColor : String
    , opacityDisabled : String
    , railColor : String
    , railColorActive : String
    , buttonBoxShadow : String
    , buttonColor : String
    , railBorderRadiusSmall : String
    , railBorderRadiusMedium : String
    , railBorderRadiusLarge : String
    , buttonBorderRadiusSmall : String
    , buttonBorderRadiusMedium : String
    , buttonBorderRadiusLarge : String
    , boxShadowFocus : String
    }


{-| Resolve the Switch variables for a theme — upstream `self(common)`: Light and Dark
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
    { buttonHeightSmall = "14px"
    , buttonHeightMedium = "18px"
    , buttonHeightLarge = "22px"
    , buttonWidthSmall = "14px"
    , buttonWidthMedium = "18px"
    , buttonWidthLarge = "22px"
    , buttonWidthPressedSmall = "20px"
    , buttonWidthPressedMedium = "24px"
    , buttonWidthPressedLarge = "28px"
    , railHeightSmall = "18px"
    , railHeightMedium = "22px"
    , railHeightLarge = "26px"
    , railWidthSmall = "32px"
    , railWidthMedium = "40px"
    , railWidthLarge = "48px"
    , iconColor = common.textColor3
    , textColor = "white"
    , loadingColor = common.primaryColor
    , opacityDisabled = common.opacityDisabled
    , railColor = "rgba(0, 0, 0, .14)"
    , railColorActive = common.primaryColor
    , buttonBoxShadow = "0 1px 4px 0 rgba(0, 0, 0, 0.3), inset 0 0 1px 0 rgba(0, 0, 0, 0.05)"
    , buttonColor = "#FFF"
    , railBorderRadiusSmall = common.borderRadius
    , railBorderRadiusMedium = common.borderRadius
    , railBorderRadiusLarge = common.borderRadius
    , buttonBorderRadiusSmall = common.borderRadius
    , buttonBorderRadiusMedium = common.borderRadius
    , buttonBorderRadiusLarge = common.borderRadius
    , boxShadowFocus = "0 0 0 2px rgba(24, 160, 88, 0.2)"
    }


dark : Common -> Vars
dark common =
    { buttonHeightSmall = "14px"
    , buttonHeightMedium = "18px"
    , buttonHeightLarge = "22px"
    , buttonWidthSmall = "14px"
    , buttonWidthMedium = "18px"
    , buttonWidthLarge = "22px"
    , buttonWidthPressedSmall = "20px"
    , buttonWidthPressedMedium = "24px"
    , buttonWidthPressedLarge = "28px"
    , railHeightSmall = "18px"
    , railHeightMedium = "22px"
    , railHeightLarge = "26px"
    , railWidthSmall = "32px"
    , railWidthMedium = "40px"
    , railWidthLarge = "48px"
    , iconColor = common.baseColor
    , textColor = common.textColor2
    , loadingColor = common.primaryColorSuppl
    , opacityDisabled = common.opacityDisabled
    , railColor = "rgba(255, 255, 255, .20)"
    , railColorActive = common.primaryColorSuppl
    , buttonBoxShadow = "0px 2px 4px 0 rgba(0, 0, 0, 0.4)"
    , buttonColor = "#FFF"
    , railBorderRadiusSmall = common.borderRadius
    , railBorderRadiusMedium = common.borderRadius
    , railBorderRadiusLarge = common.borderRadius
    , buttonBorderRadiusSmall = common.borderRadius
    , buttonBorderRadiusMedium = common.borderRadius
    , buttonBorderRadiusLarge = common.borderRadius
    , boxShadowFocus = "0 0 8px 0 rgba(99, 226, 183, 0.3)"
    }
