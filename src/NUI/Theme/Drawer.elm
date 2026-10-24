module NUI.Theme.Drawer exposing (Vars, vars)

{-| Theme variables for the **Drawer** component — the Elm counterpart of Naive UI's
`src/Drawer/styles/light.ts` & `dark.ts` cssr theme (selfVars). Drawer renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`bodyPadding` → `--n-body-padding`, `borderRadius` → `--n-border-radius`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Drawer's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Drawer CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`bodyPadding` → `--n-body-padding`).

Collected by concern:

  - layout metrics: `bodyPadding`, `borderRadius`, `headerPadding`, `footerPadding`, `titleFontSize`, `titleFontWeight`, `lineHeight`, `closeSize`, `closeIconSize`
  - chrome colors & states: `color`, `textColor`, `titleTextColor`, `boxShadow`, `headerBorderBottom`, `footerBorderTop`, `closeIconColor`, `closeIconColorHover`, `closeIconColorPressed`, `closeColorHover`, `closeColorPressed`, `closeBorderRadius`, `resizableTriggerColorHover`

-}
type alias Vars =
    { bodyPadding : String
    , borderRadius : String
    , headerPadding : String
    , footerPadding : String
    , color : String
    , textColor : String
    , titleTextColor : String
    , titleFontSize : String
    , titleFontWeight : String
    , boxShadow : String
    , lineHeight : String
    , headerBorderBottom : String
    , footerBorderTop : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeSize : String
    , closeIconSize : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeBorderRadius : String
    , resizableTriggerColorHover : String
    }


{-| Resolve the Drawer variables for a theme — upstream `self(common)`: Light and Dark
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
    { bodyPadding = "16px 24px"
    , borderRadius = common.borderRadius
    , headerPadding = "16px 24px"
    , footerPadding = "16px 24px"
    , color = common.modalColor
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , titleFontSize = "18px"
    , titleFontWeight = common.fontWeightStrong
    , boxShadow = common.boxShadow3
    , lineHeight = common.lineHeight
    , headerBorderBottom = "1px solid rgb(239, 239, 245)"
    , footerBorderTop = "1px solid rgb(239, 239, 245)"
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeSize = "22px"
    , closeIconSize = "18px"
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , resizableTriggerColorHover = common.primaryColorHover
    }


dark : Common -> Vars
dark common =
    { bodyPadding = "16px 24px"
    , borderRadius = common.borderRadius
    , headerPadding = "16px 24px"
    , footerPadding = "16px 24px"
    , color = common.modalColor
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , titleFontSize = "18px"
    , titleFontWeight = common.fontWeightStrong
    , boxShadow = common.boxShadow3
    , lineHeight = common.lineHeight
    , headerBorderBottom = "1px solid rgba(255, 255, 255, 0.09)"
    , footerBorderTop = "1px solid rgba(255, 255, 255, 0.09)"
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , closeSize = "22px"
    , closeIconSize = "18px"
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , resizableTriggerColorHover = common.primaryColorHover
    }
