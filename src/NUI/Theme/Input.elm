module NUI.Theme.Input exposing (Vars, vars)

{-| Theme variables for the **Input** component — the Elm counterpart of Naive UI's
`src/Input/styles/light.ts` & `dark.ts` cssr theme (selfVars). Input renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`paddingTiny` → `--n-padding-tiny`, `paddingSmall` → `--n-padding-small`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Input's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Input CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`paddingTiny` → `--n-padding-tiny`).

Collected by concern:

  - Warning/Error state colors: `loadingColorWarning`, `borderWarning`, `borderHoverWarning`, `colorFocusWarning`, `borderFocusWarning`, `boxShadowFocusWarning`, `caretColorWarning`, `loadingColorError`, `borderError`, `borderHoverError`, `colorFocusError`, `borderFocusError`, `boxShadowFocusError`, `caretColorError`
  - clear button states: `clearColor`, `clearColorHover`, `clearColorPressed`
  - icon & suffix colors: `iconColor`, `iconColorDisabled`, `iconColorHover`, `iconColorPressed`, `suffixTextColor`
  - loading spinners: `loadingColor`
  - per-size paddings & metrics: `paddingTiny`, `paddingSmall`, `paddingMedium`, `paddingLarge`, `clearSize`, `heightTiny`, `heightSmall`, `heightMedium`, `heightLarge`, `fontSizeTiny`, `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`, `lineHeightTextarea`
  - base text, placeholder, surfaces, borders & focus ring: `fontWeight`, `countTextColorDisabled`, `countTextColor`, `lineHeight`, `borderRadius`, `iconSize`, `groupLabelColor`, `groupLabelTextColor`, `textColor`, `textColorDisabled`, `textDecorationColor`, `caretColor`, `placeholderColor`, `placeholderColorDisabled`, `color`, `colorHover`, `colorDisabled`, `colorFocus`, `groupLabelBorder`, `border`, `borderHover`, `borderDisabled`, `borderFocus`, `boxShadowFocus`

-}
type alias Vars =
    { paddingTiny : String
    , paddingSmall : String
    , paddingMedium : String
    , paddingLarge : String
    , clearSize : String
    , fontWeight : String
    , countTextColorDisabled : String
    , countTextColor : String
    , heightTiny : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , fontSizeTiny : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , lineHeight : String
    , lineHeightTextarea : String
    , borderRadius : String
    , iconSize : String
    , groupLabelColor : String
    , groupLabelTextColor : String
    , textColor : String
    , textColorDisabled : String
    , textDecorationColor : String
    , caretColor : String
    , placeholderColor : String
    , placeholderColorDisabled : String
    , color : String
    , colorHover : String
    , colorDisabled : String
    , colorFocus : String
    , groupLabelBorder : String
    , border : String
    , borderHover : String
    , borderDisabled : String
    , borderFocus : String
    , boxShadowFocus : String
    , loadingColor : String
    , loadingColorWarning : String
    , borderWarning : String
    , borderHoverWarning : String
    , colorFocusWarning : String
    , borderFocusWarning : String
    , boxShadowFocusWarning : String
    , caretColorWarning : String
    , loadingColorError : String
    , borderError : String
    , borderHoverError : String
    , colorFocusError : String
    , borderFocusError : String
    , boxShadowFocusError : String
    , caretColorError : String
    , clearColor : String
    , clearColorHover : String
    , clearColorPressed : String
    , iconColor : String
    , iconColorDisabled : String
    , iconColorHover : String
    , iconColorPressed : String
    , suffixTextColor : String
    }


{-| Resolve the Input variables for a theme — upstream `self(common)`: Light and Dark
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
    { paddingTiny = "0 8px"
    , paddingSmall = "0 10px"
    , paddingMedium = "0 12px"
    , paddingLarge = "0 14px"
    , clearSize = "16px"
    , fontWeight = common.fontWeight
    , countTextColorDisabled = common.textColorDisabled
    , countTextColor = common.textColor3
    , heightTiny = common.heightTiny
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , fontSizeTiny = common.fontSizeTiny
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , lineHeight = common.lineHeight
    , lineHeightTextarea = common.lineHeight
    , borderRadius = common.borderRadius
    , iconSize = "16px"
    , groupLabelColor = common.actionColor
    , groupLabelTextColor = common.textColor2
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    , textDecorationColor = common.textColor2
    , caretColor = common.primaryColor
    , placeholderColor = common.placeholderColor
    , placeholderColorDisabled = common.placeholderColorDisabled
    , color = common.inputColor
    , colorHover = common.inputColor
    , colorDisabled = common.inputColorDisabled
    , colorFocus = common.inputColor
    , groupLabelBorder = "1px solid rgb(224, 224, 230)"
    , border = "1px solid rgb(224, 224, 230)"
    , borderHover = "1px solid #36ad6a"
    , borderDisabled = "1px solid rgb(224, 224, 230)"
    , borderFocus = "1px solid #36ad6a"
    , boxShadowFocus = "0 0 0 2px rgba(24, 160, 88, 0.2)"
    , loadingColor = common.primaryColor
    , loadingColorWarning = common.warningColor
    , borderWarning = "1px solid #f0a020"
    , borderHoverWarning = "1px solid #fcb040"
    , colorFocusWarning = common.inputColor
    , borderFocusWarning = "1px solid #fcb040"
    , boxShadowFocusWarning = "0 0 0 2px rgba(240, 160, 32, 0.2)"
    , caretColorWarning = common.warningColor
    , loadingColorError = common.errorColor
    , borderError = "1px solid #d03050"
    , borderHoverError = "1px solid #de576d"
    , colorFocusError = common.inputColor
    , borderFocusError = "1px solid #de576d"
    , boxShadowFocusError = "0 0 0 2px rgba(208, 48, 80, 0.2)"
    , caretColorError = common.errorColor
    , clearColor = common.clearColor
    , clearColorHover = common.clearColorHover
    , clearColorPressed = common.clearColorPressed
    , iconColor = common.iconColor
    , iconColorDisabled = common.iconColorDisabled
    , iconColorHover = common.iconColorHover
    , iconColorPressed = common.iconColorPressed
    , suffixTextColor = common.textColor2
    }


dark : Common -> Vars
dark common =
    { paddingTiny = "0 8px"
    , paddingSmall = "0 10px"
    , paddingMedium = "0 12px"
    , paddingLarge = "0 14px"
    , clearSize = "16px"
    , fontWeight = common.fontWeight
    , countTextColorDisabled = common.textColorDisabled
    , countTextColor = common.textColor3
    , heightTiny = common.heightTiny
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , fontSizeTiny = common.fontSizeTiny
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , lineHeight = common.lineHeight
    , lineHeightTextarea = common.lineHeight
    , borderRadius = common.borderRadius
    , iconSize = "16px"
    , groupLabelColor = common.inputColor
    , groupLabelTextColor = common.textColor2
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    , textDecorationColor = common.textColor2
    , caretColor = common.primaryColor
    , placeholderColor = common.placeholderColor
    , placeholderColorDisabled = common.placeholderColorDisabled
    , color = common.inputColor
    , colorHover = common.inputColor
    , colorDisabled = common.inputColorDisabled
    , colorFocus = "rgba(99, 226, 183, 0.1)"
    , groupLabelBorder = "1px solid #0000"
    , border = "1px solid #0000"
    , borderHover = "1px solid #7fe7c4"
    , borderDisabled = "1px solid #0000"
    , borderFocus = "1px solid #7fe7c4"
    , boxShadowFocus = "0 0 8px 0 rgba(99, 226, 183, 0.3)"
    , loadingColor = common.primaryColor
    , loadingColorWarning = common.warningColor
    , borderWarning = "1px solid #f2c97d"
    , borderHoverWarning = "1px solid #f5d599"
    , colorFocusWarning = "rgba(242, 201, 125, 0.1)"
    , borderFocusWarning = "1px solid #f5d599"
    , boxShadowFocusWarning = "0 0 8px 0 rgba(242, 201, 125, 0.3)"
    , caretColorWarning = common.warningColor
    , loadingColorError = common.errorColor
    , borderError = "1px solid #e88080"
    , borderHoverError = "1px solid #e98b8b"
    , colorFocusError = "rgba(232, 128, 128, 0.1)"
    , borderFocusError = "1px solid #e98b8b"
    , boxShadowFocusError = "0 0 8px 0 rgba(232, 128, 128, 0.3)"
    , caretColorError = common.errorColor
    , clearColor = common.clearColor
    , clearColorHover = common.clearColorHover
    , clearColorPressed = common.clearColorPressed
    , iconColor = common.iconColor
    , iconColorDisabled = common.iconColorDisabled
    , iconColorHover = common.iconColorHover
    , iconColorPressed = common.iconColorPressed
    , suffixTextColor = common.textColor2
    }
