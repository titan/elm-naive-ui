module NUI.Theme.InternalSelection exposing (Vars, vars)

{-| Theme variables for the **InternalSelection** component — the Elm counterpart of Naive UI's
`src/InternalSelection/styles/light.ts` & `dark.ts` cssr theme (selfVars). InternalSelection renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`paddingSingle` → `--n-padding-single`, `paddingMultiple` → `--n-padding-multiple`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to InternalSelection's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the InternalSelection CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`paddingSingle` → `--n-padding-single`).
-}
type alias Vars =
    { paddingSingle : String
    , paddingMultiple : String
    , clearSize : String
    , arrowSize : String
    , fontSizeTiny : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , heightTiny : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , borderRadius : String
    , fontWeight : String
    , textColor : String
    , textColorDisabled : String
    , placeholderColor : String
    , placeholderColorDisabled : String
    , color : String
    , colorDisabled : String
    , colorActive : String
    , border : String
    , borderHover : String
    , borderActive : String
    , borderFocus : String
    , boxShadowHover : String
    , boxShadowActive : String
    , boxShadowFocus : String
    , caretColor : String
    , arrowColor : String
    , arrowColorDisabled : String
    , loadingColor : String
    , borderWarning : String
    , borderHoverWarning : String
    , borderActiveWarning : String
    , borderFocusWarning : String
    , boxShadowHoverWarning : String
    , boxShadowActiveWarning : String
    , boxShadowFocusWarning : String
    , colorActiveWarning : String
    , caretColorWarning : String
    , borderError : String
    , borderHoverError : String
    , borderActiveError : String
    , borderFocusError : String
    , boxShadowHoverError : String
    , boxShadowActiveError : String
    , boxShadowFocusError : String
    , colorActiveError : String
    , caretColorError : String
    , clearColor : String
    , clearColorHover : String
    , clearColorPressed : String
    }


{-| Resolve the InternalSelection variables for a theme — upstream `self(common)`: Light and Dark
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
    { paddingSingle = "0 26px 0 12px"
    , paddingMultiple = "3px 26px 0 12px"
    , clearSize = "16px"
    , arrowSize = "16px"
    , fontSizeTiny = common.fontSizeTiny
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , heightTiny = common.heightTiny
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , borderRadius = common.borderRadius
    , fontWeight = common.fontWeight
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    , placeholderColor = common.placeholderColor
    , placeholderColorDisabled = common.placeholderColorDisabled
    , color = common.inputColor
    , colorDisabled = common.inputColorDisabled
    , colorActive = common.inputColor
    , border = "1px solid rgb(224, 224, 230)"
    , borderHover = "1px solid #36ad6a"
    , borderActive = "1px solid #18a058"
    , borderFocus = "1px solid #36ad6a"
    , boxShadowHover = "none"
    , boxShadowActive = "0 0 0 2px rgba(24, 160, 88, 0.2)"
    , boxShadowFocus = "0 0 0 2px rgba(24, 160, 88, 0.2)"
    , caretColor = common.primaryColor
    , arrowColor = common.iconColor
    , arrowColorDisabled = common.iconColorDisabled
    , loadingColor = common.primaryColor
    , borderWarning = "1px solid #f0a020"
    , borderHoverWarning = "1px solid #fcb040"
    , borderActiveWarning = "1px solid #f0a020"
    , borderFocusWarning = "1px solid #fcb040"
    , boxShadowHoverWarning = "none"
    , boxShadowActiveWarning = "0 0 0 2px rgba(240, 160, 32, 0.2)"
    , boxShadowFocusWarning = "0 0 0 2px rgba(240, 160, 32, 0.2)"
    , colorActiveWarning = common.inputColor
    , caretColorWarning = common.warningColor
    , borderError = "1px solid #d03050"
    , borderHoverError = "1px solid #de576d"
    , borderActiveError = "1px solid #d03050"
    , borderFocusError = "1px solid #de576d"
    , boxShadowHoverError = "none"
    , boxShadowActiveError = "0 0 0 2px rgba(208, 48, 80, 0.2)"
    , boxShadowFocusError = "0 0 0 2px rgba(208, 48, 80, 0.2)"
    , colorActiveError = common.inputColor
    , caretColorError = common.errorColor
    , clearColor = common.clearColor
    , clearColorHover = common.clearColorHover
    , clearColorPressed = common.clearColorPressed
    }


dark : Common -> Vars
dark common =
    { paddingSingle = "0 26px 0 12px"
    , paddingMultiple = "3px 26px 0 12px"
    , clearSize = "16px"
    , arrowSize = "16px"
    , fontSizeTiny = common.fontSizeTiny
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , heightTiny = common.heightTiny
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , borderRadius = common.borderRadius
    , fontWeight = common.fontWeight
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    , placeholderColor = common.placeholderColor
    , placeholderColorDisabled = common.placeholderColorDisabled
    , color = common.inputColor
    , colorDisabled = common.inputColorDisabled
    , colorActive = "rgba(99, 226, 183, 0.1)"
    , border = "1px solid #0000"
    , borderHover = "1px solid #7fe7c4"
    , borderActive = "1px solid #63e2b7"
    , borderFocus = "1px solid #7fe7c4"
    , boxShadowHover = "none"
    , boxShadowActive = "0 0 8px 0 rgba(99, 226, 183, 0.4)"
    , boxShadowFocus = "0 0 8px 0 rgba(99, 226, 183, 0.4)"
    , caretColor = common.primaryColor
    , arrowColor = common.iconColor
    , arrowColorDisabled = common.iconColorDisabled
    , loadingColor = common.primaryColor
    , borderWarning = "1px solid #f2c97d"
    , borderHoverWarning = "1px solid #f5d599"
    , borderActiveWarning = "1px solid #f2c97d"
    , borderFocusWarning = "1px solid #f5d599"
    , boxShadowHoverWarning = "none"
    , boxShadowActiveWarning = "0 0 8px 0 rgba(242, 201, 125, 0.4)"
    , boxShadowFocusWarning = "0 0 8px 0 rgba(242, 201, 125, 0.4)"
    , colorActiveWarning = "rgba(242, 201, 125, 0.1)"
    , caretColorWarning = common.warningColor
    , borderError = "1px solid #e88080"
    , borderHoverError = "1px solid #e98b8b"
    , borderActiveError = "1px solid #e88080"
    , borderFocusError = "1px solid #e98b8b"
    , boxShadowHoverError = "none"
    , boxShadowActiveError = "0 0 8px 0 rgba(232, 128, 128, 0.4)"
    , boxShadowFocusError = "0 0 8px 0 rgba(232, 128, 128, 0.4)"
    , colorActiveError = "rgba(232, 128, 128, 0.1)"
    , caretColorError = common.errorColor
    , clearColor = common.clearColor
    , clearColorHover = common.clearColorHover
    , clearColorPressed = common.clearColorPressed
    }
