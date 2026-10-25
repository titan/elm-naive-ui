module NUI.Theme.Dropdown exposing (Vars, vars)

{-| Theme variables for the **Dropdown** component — the Elm counterpart of Naive UI's
`src/Dropdown/styles/light.ts` & `dark.ts` cssr theme (selfVars). Dropdown renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`padding` → `--n-padding`, `optionIconSizeSmall` → `--n-option-icon-size-small`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Dropdown's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Dropdown CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`padding` → `--n-padding`).
-}
type alias Vars =
    { padding : String
    , optionIconSizeSmall : String
    , optionIconSizeMedium : String
    , optionIconSizeLarge : String
    , optionIconSizeHuge : String
    , optionSuffixWidthSmall : String
    , optionSuffixWidthMedium : String
    , optionSuffixWidthLarge : String
    , optionSuffixWidthHuge : String
    , optionIconSuffixWidthSmall : String
    , optionIconSuffixWidthMedium : String
    , optionIconSuffixWidthLarge : String
    , optionIconSuffixWidthHuge : String
    , optionPrefixWidthSmall : String
    , optionPrefixWidthMedium : String
    , optionPrefixWidthLarge : String
    , optionPrefixWidthHuge : String
    , optionIconPrefixWidthSmall : String
    , optionIconPrefixWidthMedium : String
    , optionIconPrefixWidthLarge : String
    , optionIconPrefixWidthHuge : String
    , optionHeightSmall : String
    , optionHeightMedium : String
    , optionHeightLarge : String
    , optionHeightHuge : String
    , borderRadius : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , optionTextColor : String
    , optionTextColorHover : String
    , optionTextColorActive : String
    , optionTextColorChildActive : String
    , color : String
    , dividerColor : String
    , suffixColor : String
    , prefixColor : String
    , optionColorHover : String
    , optionColorActive : String
    , groupHeaderTextColor : String
    , optionTextColorInverted : String
    , optionTextColorHoverInverted : String
    , optionTextColorActiveInverted : String
    , optionTextColorChildActiveInverted : String
    , colorInverted : String
    , dividerColorInverted : String
    , suffixColorInverted : String
    , prefixColorInverted : String
    , optionColorHoverInverted : String
    , optionColorActiveInverted : String
    , groupHeaderTextColorInverted : String
    , optionOpacityDisabled : String
    }


{-| Resolve the Dropdown variables for a theme — upstream `self(common)`: Light and Dark
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
    { padding = "4px 0"
    , optionIconSizeSmall = "14px"
    , optionIconSizeMedium = "16px"
    , optionIconSizeLarge = "16px"
    , optionIconSizeHuge = "18px"
    , optionSuffixWidthSmall = "14px"
    , optionSuffixWidthMedium = "14px"
    , optionSuffixWidthLarge = "16px"
    , optionSuffixWidthHuge = "16px"
    , optionIconSuffixWidthSmall = "32px"
    , optionIconSuffixWidthMedium = "32px"
    , optionIconSuffixWidthLarge = "36px"
    , optionIconSuffixWidthHuge = "36px"
    , optionPrefixWidthSmall = "14px"
    , optionPrefixWidthMedium = "14px"
    , optionPrefixWidthLarge = "16px"
    , optionPrefixWidthHuge = "16px"
    , optionIconPrefixWidthSmall = "36px"
    , optionIconPrefixWidthMedium = "36px"
    , optionIconPrefixWidthLarge = "40px"
    , optionIconPrefixWidthHuge = "40px"
    , optionHeightSmall = common.heightSmall
    , optionHeightMedium = common.heightMedium
    , optionHeightLarge = common.heightLarge
    , optionHeightHuge = common.heightHuge
    , borderRadius = common.borderRadius
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , fontSizeHuge = common.fontSizeHuge
    , optionTextColor = common.textColor2
    , optionTextColorHover = common.textColor2
    , optionTextColorActive = common.primaryColor
    , optionTextColorChildActive = common.primaryColor
    , color = common.popoverColor
    , dividerColor = common.dividerColor
    , suffixColor = common.textColor2
    , prefixColor = common.textColor2
    , optionColorHover = common.hoverColor
    , optionColorActive = "rgba(24, 160, 88, 0.1)"
    , groupHeaderTextColor = common.textColor3
    , optionTextColorInverted = "#BBB"
    , optionTextColorHoverInverted = "#FFF"
    , optionTextColorActiveInverted = "#FFF"
    , optionTextColorChildActiveInverted = "#FFF"
    , colorInverted = common.invertedColor
    , dividerColorInverted = "#BBB"
    , suffixColorInverted = "#BBB"
    , prefixColorInverted = "#BBB"
    , optionColorHoverInverted = common.primaryColor
    , optionColorActiveInverted = common.primaryColor
    , groupHeaderTextColorInverted = "#AAA"
    , optionOpacityDisabled = common.opacityDisabled
    }


dark : Common -> Vars
dark common =
    { padding = "4px 0"
    , optionIconSizeSmall = "14px"
    , optionIconSizeMedium = "16px"
    , optionIconSizeLarge = "16px"
    , optionIconSizeHuge = "18px"
    , optionSuffixWidthSmall = "14px"
    , optionSuffixWidthMedium = "14px"
    , optionSuffixWidthLarge = "16px"
    , optionSuffixWidthHuge = "16px"
    , optionIconSuffixWidthSmall = "32px"
    , optionIconSuffixWidthMedium = "32px"
    , optionIconSuffixWidthLarge = "36px"
    , optionIconSuffixWidthHuge = "36px"
    , optionPrefixWidthSmall = "14px"
    , optionPrefixWidthMedium = "14px"
    , optionPrefixWidthLarge = "16px"
    , optionPrefixWidthHuge = "16px"
    , optionIconPrefixWidthSmall = "36px"
    , optionIconPrefixWidthMedium = "36px"
    , optionIconPrefixWidthLarge = "40px"
    , optionIconPrefixWidthHuge = "40px"
    , optionHeightSmall = common.heightSmall
    , optionHeightMedium = common.heightMedium
    , optionHeightLarge = common.heightLarge
    , optionHeightHuge = common.heightHuge
    , borderRadius = common.borderRadius
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , fontSizeHuge = common.fontSizeHuge
    , optionTextColor = common.textColor2
    , optionTextColorHover = common.textColor2
    , optionTextColorActive = common.primaryColor
    , optionTextColorChildActive = common.primaryColor
    , color = common.popoverColor
    , dividerColor = common.dividerColor
    , suffixColor = common.textColor2
    , prefixColor = common.textColor2
    , optionColorHover = common.hoverColor
    , optionColorActive = "rgba(99, 226, 183, 0.15)"
    , groupHeaderTextColor = common.textColor3
    , optionTextColorInverted = "#BBB"
    , optionTextColorHoverInverted = "#FFF"
    , optionTextColorActiveInverted = "#FFF"
    , optionTextColorChildActiveInverted = "#FFF"
    , colorInverted = common.popoverColor
    , dividerColorInverted = "#BBB"
    , suffixColorInverted = "#BBB"
    , prefixColorInverted = "#BBB"
    , optionColorHoverInverted = common.primaryColorSuppl
    , optionColorActiveInverted = common.primaryColorSuppl
    , groupHeaderTextColorInverted = "#AAA"
    , optionOpacityDisabled = common.opacityDisabled
    }
