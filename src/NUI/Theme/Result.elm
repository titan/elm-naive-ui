module NUI.Theme.Result exposing (Vars, vars)

{-| Theme variables for the **Result** component — the Elm counterpart of Naive UI's
`src/Result/styles/light.ts` & `dark.ts` cssr theme (selfVars). Result renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`titleFontSizeSmall` → `--n-title-font-size-small`, `titleFontSizeMedium` → `--n-title-font-size-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Result's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Result CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`titleFontSizeSmall` → `--n-title-font-size-small`).

Collected by concern:

  - per-size icon sizes: `iconSizeSmall`, `iconSizeMedium`, `iconSizeLarge`, `iconSizeHuge`
  - per-size title & body font sizes: `titleFontSizeSmall`, `titleFontSizeMedium`, `titleFontSizeLarge`, `titleFontSizeHuge`, `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`, `fontSizeHuge`
  - title & body text, line height & weight: `lineHeight`, `titleFontWeight`, `titleTextColor`, `textColor`
  - status icon colors: `iconColorError`, `iconColorSuccess`, `iconColorInfo`, `iconColorWarning`

-}
type alias Vars =
    { titleFontSizeSmall : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , titleFontSizeHuge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , iconSizeSmall : String
    , iconSizeMedium : String
    , iconSizeLarge : String
    , iconSizeHuge : String
    , lineHeight : String
    , titleFontWeight : String
    , titleTextColor : String
    , textColor : String
    , iconColorError : String
    , iconColorSuccess : String
    , iconColorInfo : String
    , iconColorWarning : String
    }


{-| Resolve the Result variables for a theme — upstream `self(common)`: Light and Dark
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
    { titleFontSizeSmall = "26px"
    , titleFontSizeMedium = "32px"
    , titleFontSizeLarge = "40px"
    , titleFontSizeHuge = "48px"
    , fontSizeSmall = "14px"
    , fontSizeMedium = "14px"
    , fontSizeLarge = "15px"
    , fontSizeHuge = "16px"
    , iconSizeSmall = "64px"
    , iconSizeMedium = "80px"
    , iconSizeLarge = "100px"
    , iconSizeHuge = "125px"
    , lineHeight = common.lineHeight
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , iconColorError = common.errorColor
    , iconColorSuccess = common.successColor
    , iconColorInfo = common.infoColor
    , iconColorWarning = common.warningColor
    }


dark : Common -> Vars
dark common =
    { titleFontSizeSmall = "26px"
    , titleFontSizeMedium = "32px"
    , titleFontSizeLarge = "40px"
    , titleFontSizeHuge = "48px"
    , fontSizeSmall = "14px"
    , fontSizeMedium = "14px"
    , fontSizeLarge = "15px"
    , fontSizeHuge = "16px"
    , iconSizeSmall = "64px"
    , iconSizeMedium = "80px"
    , iconSizeLarge = "100px"
    , iconSizeHuge = "125px"
    , lineHeight = common.lineHeight
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , iconColorError = common.errorColor
    , iconColorSuccess = common.successColor
    , iconColorInfo = common.infoColor
    , iconColorWarning = common.warningColor
    }
