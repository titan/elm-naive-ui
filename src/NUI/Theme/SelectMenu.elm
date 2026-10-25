module NUI.Theme.SelectMenu exposing (Vars, vars)

{-| Theme variables for the **SelectMenu** component — the Elm counterpart of Naive UI's
`src/_internal/select-menu/styles/light.ts` & `dark.ts` cssr theme (selfVars). SelectMenu renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`height` → `--n-height`, `paddingTiny` → `--n-padding-tiny`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to SelectMenu's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the SelectMenu CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`height` → `--n-height`).
-}
type alias Vars =
    { height : String
    , paddingTiny : String
    , paddingSmall : String
    , paddingMedium : String
    , paddingLarge : String
    , paddingHuge : String
    , optionPaddingTiny : String
    , optionPaddingSmall : String
    , optionPaddingMedium : String
    , optionPaddingLarge : String
    , optionPaddingHuge : String
    , loadingSize : String
    , optionFontSizeTiny : String
    , optionFontSizeSmall : String
    , optionFontSizeMedium : String
    , optionFontSizeLarge : String
    , optionFontSizeHuge : String
    , optionHeightTiny : String
    , optionHeightSmall : String
    , optionHeightMedium : String
    , optionHeightLarge : String
    , optionHeightHuge : String
    , borderRadius : String
    , color : String
    , groupHeaderTextColor : String
    , actionDividerColor : String
    , optionTextColor : String
    , optionTextColorPressed : String
    , optionTextColorDisabled : String
    , optionTextColorActive : String
    , optionOpacityDisabled : String
    , optionCheckColor : String
    , optionColorPending : String
    , optionColorActive : String
    , optionColorActivePending : String
    , actionTextColor : String
    , loadingColor : String
    }


{-| Resolve the SelectMenu variables for a theme — upstream `self(common)`: Light and Dark
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
    { height = "calc(var(--n-option-height) * 7.6)"
    , paddingTiny = "4px 0"
    , paddingSmall = "4px 0"
    , paddingMedium = "4px 0"
    , paddingLarge = "4px 0"
    , paddingHuge = "4px 0"
    , optionPaddingTiny = "0 12px"
    , optionPaddingSmall = "0 12px"
    , optionPaddingMedium = "0 12px"
    , optionPaddingLarge = "0 12px"
    , optionPaddingHuge = "0 12px"
    , loadingSize = "18px"
    , optionFontSizeTiny = common.fontSizeTiny
    , optionFontSizeSmall = common.fontSizeSmall
    , optionFontSizeMedium = common.fontSizeMedium
    , optionFontSizeLarge = common.fontSizeLarge
    , optionFontSizeHuge = common.fontSizeHuge
    , optionHeightTiny = common.heightTiny
    , optionHeightSmall = common.heightSmall
    , optionHeightMedium = common.heightMedium
    , optionHeightLarge = common.heightLarge
    , optionHeightHuge = common.heightHuge
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , groupHeaderTextColor = common.textColor3
    , actionDividerColor = common.dividerColor
    , optionTextColor = common.textColor2
    , optionTextColorPressed = common.primaryColorPressed
    , optionTextColorDisabled = common.textColorDisabled
    , optionTextColorActive = common.primaryColor
    , optionOpacityDisabled = common.opacityDisabled
    , optionCheckColor = common.primaryColor
    , optionColorPending = common.hoverColor
    , optionColorActive = "rgba(0, 0, 0, 0)"
    , optionColorActivePending = common.hoverColor
    , actionTextColor = common.textColor2
    , loadingColor = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { height = "calc(var(--n-option-height) * 7.6)"
    , paddingTiny = "4px 0"
    , paddingSmall = "4px 0"
    , paddingMedium = "4px 0"
    , paddingLarge = "4px 0"
    , paddingHuge = "4px 0"
    , optionPaddingTiny = "0 12px"
    , optionPaddingSmall = "0 12px"
    , optionPaddingMedium = "0 12px"
    , optionPaddingLarge = "0 12px"
    , optionPaddingHuge = "0 12px"
    , loadingSize = "18px"
    , optionFontSizeTiny = common.fontSizeTiny
    , optionFontSizeSmall = common.fontSizeSmall
    , optionFontSizeMedium = common.fontSizeMedium
    , optionFontSizeLarge = common.fontSizeLarge
    , optionFontSizeHuge = common.fontSizeHuge
    , optionHeightTiny = common.heightTiny
    , optionHeightSmall = common.heightSmall
    , optionHeightMedium = common.heightMedium
    , optionHeightLarge = common.heightLarge
    , optionHeightHuge = common.heightHuge
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , groupHeaderTextColor = common.textColor3
    , actionDividerColor = common.dividerColor
    , optionTextColor = common.textColor2
    , optionTextColorPressed = common.primaryColorPressed
    , optionTextColorDisabled = common.textColorDisabled
    , optionTextColorActive = common.primaryColor
    , optionOpacityDisabled = common.opacityDisabled
    , optionCheckColor = common.primaryColor
    , optionColorPending = common.hoverColor
    , optionColorActive = "rgba(0, 0, 0, 0)"
    , optionColorActivePending = common.hoverColor
    , actionTextColor = common.textColor2
    , loadingColor = common.primaryColor
    }
