module NUI.Theme.TimePicker exposing (Vars, vars)

{-| Theme variables for the **TimePicker** component — the Elm counterpart of Naive UI's
`src/TimePicker/styles/light.ts` & `dark.ts` cssr theme (selfVars). TimePicker renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`itemFontSize` → `--n-item-font-size`, `itemHeight` → `--n-item-height`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to TimePicker's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the TimePicker CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`itemFontSize` → `--n-item-font-size`).
-}
type alias Vars =
    { itemFontSize : String
    , itemHeight : String
    , itemWidth : String
    , panelActionPadding : String
    , panelColor : String
    , panelBoxShadow : String
    , panelDividerColor : String
    , itemTextColor : String
    , itemTextColorActive : String
    , itemColorHover : String
    , itemOpacityDisabled : String
    , itemBorderRadius : String
    , borderRadius : String
    , iconColor : String
    , iconColorDisabled : String
    }


{-| Resolve the TimePicker variables for a theme — upstream `self(common)`: Light and Dark
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
    { itemFontSize = "12px"
    , itemHeight = "36px"
    , itemWidth = "52px"
    , panelActionPadding = "8px 0"
    , panelColor = common.popoverColor
    , panelBoxShadow = common.boxShadow2
    , panelDividerColor = common.dividerColor
    , itemTextColor = common.textColor2
    , itemTextColorActive = common.primaryColor
    , itemColorHover = common.hoverColor
    , itemOpacityDisabled = common.opacityDisabled
    , itemBorderRadius = common.borderRadius
    , borderRadius = common.borderRadius
    , iconColor = common.iconColor
    , iconColorDisabled = common.iconColorDisabled
    }


dark : Common -> Vars
dark common =
    { itemFontSize = "12px"
    , itemHeight = "36px"
    , itemWidth = "52px"
    , panelActionPadding = "8px 0"
    , panelColor = common.popoverColor
    , panelBoxShadow = common.boxShadow2
    , panelDividerColor = common.dividerColor
    , itemTextColor = common.textColor2
    , itemTextColorActive = common.primaryColor
    , itemColorHover = common.hoverColor
    , itemOpacityDisabled = common.opacityDisabled
    , itemBorderRadius = common.borderRadius
    , borderRadius = common.borderRadius
    , iconColor = common.iconColor
    , iconColorDisabled = common.iconColorDisabled
    }
