module NUI.Theme.Upload exposing (Vars, vars)

{-| Theme variables for the **Upload** component — the Elm counterpart of Naive UI's
`src/Upload/styles/light.ts` & `dark.ts` cssr theme (selfVars). Upload renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`fontSize` → `--n-font-size`, `lineHeight` → `--n-line-height`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Upload's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Upload CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`fontSize` → `--n-font-size`).

Collected by concern:

  - chrome (font, line height, radius): `fontSize`, `lineHeight`, `borderRadius`
  - dragger (surface & borders): `draggerColor`, `draggerBorder`, `draggerBorderHover`
  - file list items (surfaces, text, icons, borders, opacity): `itemColorHover`, `itemColorHoverError`, `itemTextColor`, `itemTextColorError`, `itemTextColorSuccess`, `itemIconColor`, `itemDisabledOpacity`, `itemBorderImageCardError`, `itemBorderImageCard`

-}
type alias Vars =
    { fontSize : String
    , lineHeight : String
    , borderRadius : String
    , draggerColor : String
    , draggerBorder : String
    , draggerBorderHover : String
    , itemColorHover : String
    , itemColorHoverError : String
    , itemTextColor : String
    , itemTextColorError : String
    , itemTextColorSuccess : String
    , itemIconColor : String
    , itemDisabledOpacity : String
    , itemBorderImageCardError : String
    , itemBorderImageCard : String
    }


{-| Resolve the Upload variables for a theme — upstream `self(common)`: Light and Dark
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
    { fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , draggerColor = common.actionColor
    , draggerBorder = "1px dashed rgb(224, 224, 230)"
    , draggerBorderHover = "1px dashed #18a058"
    , itemColorHover = common.hoverColor
    , itemColorHoverError = "rgba(208, 48, 80, 0.06)"
    , itemTextColor = common.textColor2
    , itemTextColorError = common.errorColor
    , itemTextColorSuccess = common.successColor
    , itemIconColor = common.iconColor
    , itemDisabledOpacity = common.opacityDisabled
    , itemBorderImageCardError = "1px solid #d03050"
    , itemBorderImageCard = "1px solid rgb(224, 224, 230)"
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , draggerColor = common.actionColor
    , draggerBorder = "1px dashed rgba(255, 255, 255, 0.24)"
    , draggerBorderHover = "1px dashed #63e2b7"
    , itemColorHover = common.hoverColor
    , itemColorHoverError = "rgba(232, 128, 128, 0.09)"
    , itemTextColor = common.textColor2
    , itemTextColorError = common.errorColor
    , itemTextColorSuccess = common.successColor
    , itemIconColor = common.iconColor
    , itemDisabledOpacity = common.opacityDisabled
    , itemBorderImageCardError = "1px solid #e88080"
    , itemBorderImageCard = "1px solid rgba(255, 255, 255, 0.24)"
    }
