module NUI.Theme.Radio exposing (Vars, vars)

{-| Theme variables for the **Radio** component — the Elm counterpart of Naive UI's
`src/Radio/styles/light.ts` & `dark.ts` cssr theme (selfVars). Radio renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`radioSizeSmall` → `--n-radio-size-small`, `radioSizeMedium` → `--n-radio-size-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Radio's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Radio CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`radioSizeSmall` → `--n-radio-size-small`).

Collected by concern:

  - per-size radio sizes & font sizes: `radioSizeSmall`, `radioSizeMedium`, `radioSizeLarge`, `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`
  - label: `labelPadding`, `labelFontWeight`, `labelLineHeight`
  - box shadows (default & button focus/hover): `boxShadow`, `boxShadowActive`, `boxShadowFocus`, `boxShadowHover`, `boxShadowDisabled`
  - dot colors: `dotColorActive`, `dotColorDisabled`
  - button-mode surfaces, borders & text: `buttonHeightSmall`, `buttonHeightMedium`, `buttonHeightLarge`, `buttonBorderColor`, `buttonBorderColorActive`, `buttonBorderColorHover`, `buttonColor`, `buttonColorActive`, `buttonTextColor`, `buttonTextColorActive`, `buttonTextColorHover`, `buttonBoxShadowFocus`, `buttonBoxShadowHover`, `buttonBoxShadow`, `buttonBorderRadius`
  - plain radio surfaces & text: `color`, `colorDisabled`, `colorActive`, `textColor`, `textColorDisabled`, `opacityDisabled`

-}
type alias Vars =
    { radioSizeSmall : String
    , radioSizeMedium : String
    , radioSizeLarge : String
    , labelPadding : String
    , labelFontWeight : String
    , labelLineHeight : String
    , buttonHeightSmall : String
    , buttonHeightMedium : String
    , buttonHeightLarge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , boxShadow : String
    , boxShadowActive : String
    , boxShadowFocus : String
    , boxShadowHover : String
    , boxShadowDisabled : String
    , color : String
    , colorDisabled : String
    , colorActive : String
    , textColor : String
    , textColorDisabled : String
    , dotColorActive : String
    , dotColorDisabled : String
    , buttonBorderColor : String
    , buttonBorderColorActive : String
    , buttonBorderColorHover : String
    , buttonColor : String
    , buttonColorActive : String
    , buttonTextColor : String
    , buttonTextColorActive : String
    , buttonTextColorHover : String
    , opacityDisabled : String
    , buttonBoxShadowFocus : String
    , buttonBoxShadowHover : String
    , buttonBoxShadow : String
    , buttonBorderRadius : String
    }


{-| Resolve the Radio variables for a theme — upstream `self(common)`: Light and Dark
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
    { radioSizeSmall = "14px"
    , radioSizeMedium = "16px"
    , radioSizeLarge = "18px"
    , labelPadding = "0 8px"
    , labelFontWeight = "400"
    , labelLineHeight = common.lineHeight
    , buttonHeightSmall = common.heightSmall
    , buttonHeightMedium = common.heightMedium
    , buttonHeightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , boxShadow = "inset 0 0 0 1px rgb(224, 224, 230)"
    , boxShadowActive = "inset 0 0 0 1px #18a058"
    , boxShadowFocus = "inset 0 0 0 1px #18a058, 0 0 0 2px rgba(24, 160, 88, 0.2)"
    , boxShadowHover = "inset 0 0 0 1px #18a058"
    , boxShadowDisabled = "inset 0 0 0 1px rgb(224, 224, 230)"
    , color = common.baseColor
    , colorDisabled = common.inputColorDisabled
    , colorActive = "#0000"
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    , dotColorActive = common.primaryColor
    , dotColorDisabled = common.borderColor
    , buttonBorderColor = common.borderColor
    , buttonBorderColorActive = common.primaryColor
    , buttonBorderColorHover = common.borderColor
    , buttonColor = common.baseColor
    , buttonColorActive = common.baseColor
    , buttonTextColor = common.textColor2
    , buttonTextColorActive = common.primaryColor
    , buttonTextColorHover = common.primaryColor
    , opacityDisabled = common.opacityDisabled
    , buttonBoxShadowFocus = "inset 0 0 0 1px #18a058, 0 0 0 2px rgba(24, 160, 88, 0.3)"
    , buttonBoxShadowHover = "inset 0 0 0 1px #0000"
    , buttonBoxShadow = "inset 0 0 0 1px #0000"
    , buttonBorderRadius = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { radioSizeSmall = "14px"
    , radioSizeMedium = "16px"
    , radioSizeLarge = "18px"
    , labelPadding = "0 8px"
    , labelFontWeight = "400"
    , labelLineHeight = common.lineHeight
    , buttonHeightSmall = common.heightSmall
    , buttonHeightMedium = common.heightMedium
    , buttonHeightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , boxShadow = "inset 0 0 0 1px rgba(255, 255, 255, 0.24)"
    , boxShadowActive = "inset 0 0 0 1px #63e2b7"
    , boxShadowFocus = "inset 0 0 0 1px #63e2b7, 0 0 0 2px rgba(99, 226, 183, 0.3)"
    , boxShadowHover = "inset 0 0 0 1px #63e2b7"
    , boxShadowDisabled = "inset 0 0 0 1px rgba(255, 255, 255, 0.24)"
    , color = "#0000"
    , colorDisabled = common.inputColorDisabled
    , colorActive = "#0000"
    , textColor = common.textColor2
    , textColorDisabled = common.textColorDisabled
    , dotColorActive = common.primaryColor
    , dotColorDisabled = common.borderColor
    , buttonBorderColor = common.borderColor
    , buttonBorderColorActive = common.primaryColor
    , buttonBorderColorHover = common.primaryColor
    , buttonColor = "#0000"
    , buttonColorActive = common.primaryColor
    , buttonTextColor = common.textColor2
    , buttonTextColorActive = common.baseColor
    , buttonTextColorHover = common.primaryColor
    , opacityDisabled = common.opacityDisabled
    , buttonBoxShadowFocus = "inset 0 0 0 1px #63e2b7, 0 0 0 2px rgba(99, 226, 183, 0.3)"
    , buttonBoxShadowHover = "inset 0 0 0 1px #63e2b7"
    , buttonBoxShadow = "inset 0 0 0 1px #0000"
    , buttonBorderRadius = common.borderRadius
    }
