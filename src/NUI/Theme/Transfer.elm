module NUI.Theme.Transfer exposing (Vars, vars)

{-| Theme variables for the **Transfer** component — the Elm counterpart of Naive UI's
`src/Transfer/styles/light.ts` & `dark.ts` cssr theme (selfVars). Transfer renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`extraFontSizeSmall` → `--n-extra-font-size-small`, `extraFontSizeMedium` → `--n-extra-font-size-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Transfer's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Transfer CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`extraFontSizeSmall` → `--n-extra-font-size-small`).

Collected by concern:

  - per-size typography (extra/title/body font sizes): `extraFontSizeSmall`, `extraFontSizeMedium`, `extraFontSizeLarge`, `titleFontSizeSmall`, `titleFontSizeMedium`, `titleFontSizeLarge`, `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`
  - per-size header & item heights: `headerHeightSmall`, `headerHeightMedium`, `headerHeightLarge`, `itemHeightSmall`, `itemHeightMedium`, `itemHeightLarge`
  - close button (sizes, colors & states): `closeSize`, `closeIconSize`, `closeColorHover`, `closeColorPressed`, `closeIconColor`, `closeIconColorHover`, `closeIconColorPressed`
  - surfaces, borders & divider: `borderRadius`, `dividerColor`, `borderColor`, `listColor`, `headerColor`
  - text colors (title/extra/item, incl. disabled): `titleTextColor`, `titleTextColorDisabled`, `extraTextColor`, `extraTextColorDisabled`, `itemTextColor`, `itemTextColorDisabled`
  - misc (title weight, pending surface): `itemColorPending`, `titleFontWeight`

-}
type alias Vars =
    { extraFontSizeSmall : String
    , extraFontSizeMedium : String
    , extraFontSizeLarge : String
    , titleFontSizeSmall : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , closeSize : String
    , closeIconSize : String
    , headerHeightSmall : String
    , headerHeightMedium : String
    , headerHeightLarge : String
    , itemHeightSmall : String
    , itemHeightMedium : String
    , itemHeightLarge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , borderRadius : String
    , dividerColor : String
    , borderColor : String
    , listColor : String
    , headerColor : String
    , titleTextColor : String
    , titleTextColorDisabled : String
    , extraTextColor : String
    , extraTextColorDisabled : String
    , itemTextColor : String
    , itemTextColorDisabled : String
    , itemColorPending : String
    , titleFontWeight : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    }


{-| Resolve the Transfer variables for a theme — upstream `self(common)`: Light and Dark
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
    { extraFontSizeSmall = "12px"
    , extraFontSizeMedium = "12px"
    , extraFontSizeLarge = "14px"
    , titleFontSizeSmall = "14px"
    , titleFontSizeMedium = "16px"
    , titleFontSizeLarge = "16px"
    , closeSize = "20px"
    , closeIconSize = "16px"
    , headerHeightSmall = "44px"
    , headerHeightMedium = "44px"
    , headerHeightLarge = "50px"
    , itemHeightSmall = common.heightMedium
    , itemHeightMedium = common.heightMedium
    , itemHeightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , borderRadius = common.borderRadius
    , dividerColor = common.borderColor
    , borderColor = common.borderColor
    , listColor = common.cardColor
    , headerColor = "rgba(250, 250, 252, 1)"
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , extraTextColor = common.textColor3
    , extraTextColorDisabled = common.textColorDisabled
    , itemTextColor = common.textColor2
    , itemTextColorDisabled = common.textColorDisabled
    , itemColorPending = common.hoverColor
    , titleFontWeight = common.fontWeight
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    }


dark : Common -> Vars
dark common =
    { extraFontSizeSmall = "12px"
    , extraFontSizeMedium = "12px"
    , extraFontSizeLarge = "14px"
    , titleFontSizeSmall = "14px"
    , titleFontSizeMedium = "16px"
    , titleFontSizeLarge = "16px"
    , closeSize = "20px"
    , closeIconSize = "16px"
    , headerHeightSmall = "44px"
    , headerHeightMedium = "44px"
    , headerHeightLarge = "50px"
    , itemHeightSmall = common.heightMedium
    , itemHeightMedium = common.heightMedium
    , itemHeightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , borderRadius = common.borderRadius
    , dividerColor = common.dividerColor
    , borderColor = "#0000"
    , listColor = common.inputColor
    , headerColor = common.tableHeaderColor
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , extraTextColor = common.textColor3
    , extraTextColorDisabled = common.textColorDisabled
    , itemTextColor = common.textColor2
    , itemTextColorDisabled = common.textColorDisabled
    , itemColorPending = common.hoverColor
    , titleFontWeight = common.fontWeight
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    }
