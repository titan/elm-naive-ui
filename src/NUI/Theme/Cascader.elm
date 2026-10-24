module NUI.Theme.Cascader exposing (Vars, vars)

{-| Theme variables for the **Cascader** component — the Elm counterpart of Naive UI's
`src/Cascader/styles/light.ts` & `dark.ts` cssr theme (selfVars). Cascader renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`menuBorderRadius` → `--n-menu-border-radius`, `menuColor` → `--n-menu-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Cascader's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Cascader CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`menuBorderRadius` → `--n-menu-border-radius`).

Collected by concern:

  - menu chrome: `menuBorderRadius`, `menuColor`, `menuBoxShadow`, `menuDividerColor`, `menuHeight`
  - option text states: `optionTextColor`, `optionTextColorActive`, `optionTextColorDisabled`
  - option metrics, check-mark & loading: `optionArrowColor`, `optionHeight`, `optionFontSize`, `optionColorHover`, `optionCheckMarkColor`, `loadingColor`, `columnWidth`

-}
type alias Vars =
    { menuBorderRadius : String
    , menuColor : String
    , menuBoxShadow : String
    , menuDividerColor : String
    , menuHeight : String
    , optionArrowColor : String
    , optionHeight : String
    , optionFontSize : String
    , optionColorHover : String
    , optionTextColor : String
    , optionTextColorActive : String
    , optionTextColorDisabled : String
    , optionCheckMarkColor : String
    , loadingColor : String
    , columnWidth : String
    }


{-| Resolve the Cascader variables for a theme — upstream `self(common)`: Light and Dark
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
    { menuBorderRadius = common.borderRadius
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuDividerColor = common.dividerColor
    , menuHeight = "calc(var(--n-option-height) * 6.6)"
    , optionArrowColor = common.textColor3
    , optionHeight = common.heightMedium
    , optionFontSize = common.fontSizeMedium
    , optionColorHover = common.hoverColor
    , optionTextColor = common.textColor2
    , optionTextColorActive = common.primaryColor
    , optionTextColorDisabled = common.textColorDisabled
    , optionCheckMarkColor = common.primaryColor
    , loadingColor = common.primaryColor
    , columnWidth = "180px"
    }


dark : Common -> Vars
dark common =
    { menuBorderRadius = common.borderRadius
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuDividerColor = common.dividerColor
    , menuHeight = "calc(var(--n-option-height) * 6.6)"
    , optionArrowColor = common.textColor3
    , optionHeight = common.heightMedium
    , optionFontSize = common.fontSizeMedium
    , optionColorHover = common.hoverColor
    , optionTextColor = common.textColor2
    , optionTextColorActive = common.primaryColor
    , optionTextColorDisabled = common.textColorDisabled
    , optionCheckMarkColor = common.primaryColor
    , loadingColor = common.primaryColor
    , columnWidth = "180px"
    }
