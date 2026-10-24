module NUI.Theme.Tag exposing (Vars, vars)

{-| Theme variables for the **Tag** component — the Elm counterpart of Naive UI's
`src/Tag/styles/light.ts` & `dark.ts` cssr theme (selfVars). Tag renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`closeIconSizeTiny` → `--n-close-icon-size-tiny`, `closeIconSizeSmall` → `--n-close-icon-size-small`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Tag's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Tag CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`closeIconSizeTiny` → `--n-close-icon-size-tiny`).

Collected by concern:

  - per-size close sizes & icon sizes: `closeIconSizeTiny`, `closeIconSizeSmall`, `closeIconSizeMedium`, `closeIconSizeLarge`, `closeSizeTiny`, `closeSizeSmall`, `closeSizeMedium`, `closeSizeLarge`
  - per-size heights & font sizes: `heightTiny`, `heightSmall`, `heightMedium`, `heightLarge`, `fontSizeTiny`, `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`
  - base tag look (padding, border, radius, colors, opacity, weight): `padding`, `closeMargin`, `closeBorderRadius`, `borderRadius`, `opacityDisabled`, `fontWeightStrong`, `border`, `textColor`, `color`, `colorBordered`
  - typed variants (Primary/Info/Success/Warning/Error): `borderPrimary`, `textColorPrimary`, `colorPrimary`, `colorBorderedPrimary`, `closeIconColorPrimary`, `closeIconColorHoverPrimary`, `closeIconColorPressedPrimary`, `closeColorHoverPrimary`, `closeColorPressedPrimary`, `borderInfo`, `textColorInfo`, `colorInfo`, `colorBorderedInfo`, `closeIconColorInfo`, `closeIconColorHoverInfo`, `closeIconColorPressedInfo`, `closeColorHoverInfo`, `closeColorPressedInfo`, `borderSuccess`, `textColorSuccess`, `colorSuccess`, `colorBorderedSuccess`, `closeIconColorSuccess`, `closeIconColorHoverSuccess`, `closeIconColorPressedSuccess`, `closeColorHoverSuccess`, `closeColorPressedSuccess`, `borderWarning`, `textColorWarning`, `colorWarning`, `colorBorderedWarning`, `closeIconColorWarning`, `closeIconColorHoverWarning`, `closeIconColorPressedWarning`, `closeColorHoverWarning`, `closeColorPressedWarning`, `borderError`, `textColorError`, `colorError`, `colorBorderedError`, `closeIconColorError`, `closeIconColorHoverError`, `closeIconColorPressedError`, `closeColorHoverError`, `closeColorPressedError`
  - checkable states: `textColorCheckable`, `textColorHoverCheckable`, `textColorPressedCheckable`, `textColorChecked`, `colorCheckable`, `colorHoverCheckable`, `colorPressedCheckable`, `colorChecked`, `colorCheckedHover`, `colorCheckedPressed`
  - close button colors & states: `closeIconColor`, `closeIconColorHover`, `closeIconColorPressed`, `closeColorHover`, `closeColorPressed`

-}
type alias Vars =
    { closeIconSizeTiny : String
    , closeIconSizeSmall : String
    , closeIconSizeMedium : String
    , closeIconSizeLarge : String
    , closeSizeTiny : String
    , closeSizeSmall : String
    , closeSizeMedium : String
    , closeSizeLarge : String
    , padding : String
    , closeMargin : String
    , closeBorderRadius : String
    , heightTiny : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , borderRadius : String
    , opacityDisabled : String
    , fontSizeTiny : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontWeightStrong : String
    , textColorCheckable : String
    , textColorHoverCheckable : String
    , textColorPressedCheckable : String
    , textColorChecked : String
    , colorCheckable : String
    , colorHoverCheckable : String
    , colorPressedCheckable : String
    , colorChecked : String
    , colorCheckedHover : String
    , colorCheckedPressed : String
    , border : String
    , textColor : String
    , color : String
    , colorBordered : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeColorHover : String
    , closeColorPressed : String
    , borderPrimary : String
    , textColorPrimary : String
    , colorPrimary : String
    , colorBorderedPrimary : String
    , closeIconColorPrimary : String
    , closeIconColorHoverPrimary : String
    , closeIconColorPressedPrimary : String
    , closeColorHoverPrimary : String
    , closeColorPressedPrimary : String
    , borderInfo : String
    , textColorInfo : String
    , colorInfo : String
    , colorBorderedInfo : String
    , closeIconColorInfo : String
    , closeIconColorHoverInfo : String
    , closeIconColorPressedInfo : String
    , closeColorHoverInfo : String
    , closeColorPressedInfo : String
    , borderSuccess : String
    , textColorSuccess : String
    , colorSuccess : String
    , colorBorderedSuccess : String
    , closeIconColorSuccess : String
    , closeIconColorHoverSuccess : String
    , closeIconColorPressedSuccess : String
    , closeColorHoverSuccess : String
    , closeColorPressedSuccess : String
    , borderWarning : String
    , textColorWarning : String
    , colorWarning : String
    , colorBorderedWarning : String
    , closeIconColorWarning : String
    , closeIconColorHoverWarning : String
    , closeIconColorPressedWarning : String
    , closeColorHoverWarning : String
    , closeColorPressedWarning : String
    , borderError : String
    , textColorError : String
    , colorError : String
    , colorBorderedError : String
    , closeIconColorError : String
    , closeIconColorHoverError : String
    , closeIconColorPressedError : String
    , closeColorHoverError : String
    , closeColorPressedError : String
    }


{-| Resolve the Tag variables for a theme — upstream `self(common)`: Light and Dark
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
    { closeIconSizeTiny = "12px"
    , closeIconSizeSmall = "12px"
    , closeIconSizeMedium = "14px"
    , closeIconSizeLarge = "14px"
    , closeSizeTiny = "16px"
    , closeSizeSmall = "16px"
    , closeSizeMedium = "18px"
    , closeSizeLarge = "18px"
    , padding = "0 7px"
    , closeMargin = "0 0 0 4px"
    , closeBorderRadius = common.borderRadiusSmall
    , heightTiny = common.heightMini
    , heightSmall = common.heightTiny
    , heightMedium = common.heightSmall
    , heightLarge = common.heightMedium
    , borderRadius = common.borderRadiusSmall
    , opacityDisabled = common.opacityDisabled
    , fontSizeTiny = common.fontSizeMini
    , fontSizeSmall = common.fontSizeTiny
    , fontSizeMedium = common.fontSizeSmall
    , fontSizeLarge = common.fontSizeMedium
    , fontWeightStrong = common.fontWeightStrong
    , textColorCheckable = common.textColor2
    , textColorHoverCheckable = common.textColor2
    , textColorPressedCheckable = common.textColor2
    , textColorChecked = common.baseColor
    , colorCheckable = "#0000"
    , colorHoverCheckable = common.buttonColor2Hover
    , colorPressedCheckable = common.buttonColor2Pressed
    , colorChecked = common.primaryColor
    , colorCheckedHover = common.primaryColorHover
    , colorCheckedPressed = common.primaryColorPressed
    , border = "1px solid rgb(224, 224, 230)"
    , textColor = common.textColor2
    , color = common.tagColor
    , colorBordered = "rgb(250, 250, 252)"
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , borderPrimary = "1px solid rgba(24, 160, 88, 0.3)"
    , textColorPrimary = common.primaryColor
    , colorPrimary = "rgba(24, 160, 88, 0.12)"
    , colorBorderedPrimary = "rgba(24, 160, 88, 0.1)"
    , closeIconColorPrimary = common.primaryColor
    , closeIconColorHoverPrimary = common.primaryColor
    , closeIconColorPressedPrimary = common.primaryColor
    , closeColorHoverPrimary = "rgba(24, 160, 88, 0.12)"
    , closeColorPressedPrimary = "rgba(24, 160, 88, 0.18)"
    , borderInfo = "1px solid rgba(32, 128, 240, 0.3)"
    , textColorInfo = common.infoColor
    , colorInfo = "rgba(32, 128, 240, 0.12)"
    , colorBorderedInfo = "rgba(32, 128, 240, 0.1)"
    , closeIconColorInfo = common.infoColor
    , closeIconColorHoverInfo = common.infoColor
    , closeIconColorPressedInfo = common.infoColor
    , closeColorHoverInfo = "rgba(32, 128, 240, 0.12)"
    , closeColorPressedInfo = "rgba(32, 128, 240, 0.18)"
    , borderSuccess = "1px solid rgba(24, 160, 88, 0.3)"
    , textColorSuccess = common.successColor
    , colorSuccess = "rgba(24, 160, 88, 0.12)"
    , colorBorderedSuccess = "rgba(24, 160, 88, 0.1)"
    , closeIconColorSuccess = common.successColor
    , closeIconColorHoverSuccess = common.successColor
    , closeIconColorPressedSuccess = common.successColor
    , closeColorHoverSuccess = "rgba(24, 160, 88, 0.12)"
    , closeColorPressedSuccess = "rgba(24, 160, 88, 0.18)"
    , borderWarning = "1px solid rgba(240, 160, 32, 0.35)"
    , textColorWarning = common.warningColor
    , colorWarning = "rgba(240, 160, 32, 0.15)"
    , colorBorderedWarning = "rgba(240, 160, 32, 0.12)"
    , closeIconColorWarning = common.warningColor
    , closeIconColorHoverWarning = common.warningColor
    , closeIconColorPressedWarning = common.warningColor
    , closeColorHoverWarning = "rgba(240, 160, 32, 0.12)"
    , closeColorPressedWarning = "rgba(240, 160, 32, 0.18)"
    , borderError = "1px solid rgba(208, 48, 80, 0.23)"
    , textColorError = common.errorColor
    , colorError = "rgba(208, 48, 80, 0.1)"
    , colorBorderedError = "rgba(208, 48, 80, 0.08)"
    , closeIconColorError = common.errorColor
    , closeIconColorHoverError = common.errorColor
    , closeIconColorPressedError = common.errorColor
    , closeColorHoverError = "rgba(208, 48, 80, 0.12)"
    , closeColorPressedError = "rgba(208, 48, 80, 0.18)"
    }


dark : Common -> Vars
dark common =
    { closeIconSizeTiny = "12px"
    , closeIconSizeSmall = "12px"
    , closeIconSizeMedium = "14px"
    , closeIconSizeLarge = "14px"
    , closeSizeTiny = "16px"
    , closeSizeSmall = "16px"
    , closeSizeMedium = "18px"
    , closeSizeLarge = "18px"
    , padding = "0 7px"
    , closeMargin = "0 0 0 4px"
    , closeBorderRadius = common.borderRadiusSmall
    , heightTiny = common.heightMini
    , heightSmall = common.heightTiny
    , heightMedium = common.heightSmall
    , heightLarge = common.heightMedium
    , borderRadius = common.borderRadiusSmall
    , opacityDisabled = common.opacityDisabled
    , fontSizeTiny = common.fontSizeMini
    , fontSizeSmall = common.fontSizeTiny
    , fontSizeMedium = common.fontSizeSmall
    , fontSizeLarge = common.fontSizeMedium
    , fontWeightStrong = common.fontWeightStrong
    , textColorCheckable = common.textColor2
    , textColorHoverCheckable = common.textColor2
    , textColorPressedCheckable = common.textColor2
    , textColorChecked = common.baseColor
    , colorCheckable = "#0000"
    , colorHoverCheckable = common.buttonColor2Hover
    , colorPressedCheckable = common.buttonColor2Pressed
    , colorChecked = common.primaryColor
    , colorCheckedHover = common.primaryColorHover
    , colorCheckedPressed = common.primaryColorPressed
    , border = "1px solid rgba(255, 255, 255, 0.24)"
    , textColor = common.textColor2
    , color = common.tagColor
    , colorBordered = "#0000"
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , borderPrimary = "1px solid rgba(99, 226, 183, 0.3)"
    , textColorPrimary = common.primaryColor
    , colorPrimary = "rgba(99, 226, 183, 0.16)"
    , colorBorderedPrimary = "#0000"
    , closeIconColorPrimary = "rgba(69, 158, 128, 1)"
    , closeIconColorHoverPrimary = "rgba(69, 158, 128, 1)"
    , closeIconColorPressedPrimary = "rgba(69, 158, 128, 1)"
    , closeColorHoverPrimary = "rgba(99, 226, 183, 0.16)"
    , closeColorPressedPrimary = "rgba(99, 226, 183, 0.12)"
    , borderInfo = "1px solid rgba(112, 192, 232, 0.3)"
    , textColorInfo = common.infoColor
    , colorInfo = "rgba(112, 192, 232, 0.16)"
    , colorBorderedInfo = "#0000"
    , closeIconColorInfo = "rgba(112, 192, 232, 0.7)"
    , closeIconColorHoverInfo = "rgba(112, 192, 232, 0.7)"
    , closeIconColorPressedInfo = "rgba(112, 192, 232, 0.7)"
    , closeColorHoverInfo = "rgba(112, 192, 232, 0.16)"
    , closeColorPressedInfo = "rgba(112, 192, 232, 0.12)"
    , borderSuccess = "1px solid rgba(99, 226, 183, 0.3)"
    , textColorSuccess = common.successColor
    , colorSuccess = "rgba(99, 226, 183, 0.16)"
    , colorBorderedSuccess = "#0000"
    , closeIconColorSuccess = "rgba(99, 226, 183, 0.7)"
    , closeIconColorHoverSuccess = "rgba(99, 226, 183, 0.7)"
    , closeIconColorPressedSuccess = "rgba(99, 226, 183, 0.7)"
    , closeColorHoverSuccess = "rgba(99, 226, 183, 0.16)"
    , closeColorPressedSuccess = "rgba(99, 226, 183, 0.12)"
    , borderWarning = "1px solid rgba(242, 201, 125, 0.3)"
    , textColorWarning = common.warningColor
    , colorWarning = "rgba(242, 201, 125, 0.16)"
    , colorBorderedWarning = "#0000"
    , closeIconColorWarning = "rgba(242, 201, 125, 0.7)"
    , closeIconColorHoverWarning = "rgba(242, 201, 125, 0.7)"
    , closeIconColorPressedWarning = "rgba(242, 201, 125, 0.7)"
    , closeColorHoverWarning = "rgba(242, 201, 125, 0.16)"
    , closeColorPressedWarning = "rgba(242, 201, 125, 0.11)"
    , borderError = "1px solid rgba(232, 128, 128, 0.3)"
    , textColorError = common.errorColor
    , colorError = "rgba(232, 128, 128, 0.16)"
    , colorBorderedError = "#0000"
    , closeIconColorError = "rgba(232, 128, 128, 0.7)"
    , closeIconColorHoverError = "rgba(232, 128, 128, 0.7)"
    , closeIconColorPressedError = "rgba(232, 128, 128, 0.7)"
    , closeColorHoverError = "rgba(232, 128, 128, 0.16)"
    , closeColorPressedError = "rgba(232, 128, 128, 0.12)"
    }
