module NUI.Theme.ColorPicker exposing (Vars, vars)

{-| Theme variables for the **ColorPicker** component — the Elm counterpart of Naive UI's
`src/ColorPicker/styles/light.ts` & `dark.ts` cssr theme (selfVars). ColorPicker renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`panelFontSize` → `--n-panel-font-size`, `boxShadow` → `--n-box-shadow`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to ColorPicker's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the ColorPicker CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`panelFontSize` → `--n-panel-font-size`).

Collected by concern:

  - panel chrome: `panelFontSize`, `boxShadow`, `dividerColor`
  - per-size control metrics: `heightSmall`, `heightMedium`, `heightLarge`, `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`
  - control colors & border: `color`, `textColor`, `borderRadius`, `border`

-}
type alias Vars =
    { panelFontSize : String
    , boxShadow : String
    , color : String
    , textColor : String
    , borderRadius : String
    , border : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , dividerColor : String
    }


{-| Resolve the ColorPicker variables for a theme — upstream `self(common)`: Light and Dark
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
    { panelFontSize = common.fontSize
    , boxShadow = common.boxShadow2
    , color = common.popoverColor
    , textColor = common.textColor2
    , borderRadius = common.borderRadius
    , border = "1px solid rgb(224, 224, 230)"
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , dividerColor = common.dividerColor
    }


dark : Common -> Vars
dark common =
    { panelFontSize = common.fontSize
    , boxShadow = common.boxShadow2
    , color = common.popoverColor
    , textColor = common.textColor2
    , borderRadius = common.borderRadius
    , border = "1px solid rgba(255, 255, 255, 0.24)"
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , dividerColor = common.dividerColor
    }
