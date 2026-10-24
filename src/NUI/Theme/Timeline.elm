module NUI.Theme.Timeline exposing (Vars, vars)

{-| Theme variables for the **Timeline** component — the Elm counterpart of Naive UI's
`src/Timeline/styles/light.ts` & `dark.ts` cssr theme (selfVars). Timeline renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`titleMarginMedium` → `--n-title-margin-medium`, `titleMarginLarge` → `--n-title-margin-large`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Timeline's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Timeline CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`titleMarginMedium` → `--n-title-margin-medium`).

Collected by concern:

  - per-size title metrics & icon sizes, content font size: `titleMarginMedium`, `titleMarginLarge`, `titleFontSizeMedium`, `titleFontSizeLarge`, `iconSizeMedium`, `iconSizeLarge`, `contentFontSize`
  - title & body text, weight & meta: `titleFontWeight`, `titleTextColor`, `contentTextColor`, `metaTextColor`
  - circle borders (default & typed): `circleBorder`, `circleBorderInfo`, `circleBorderError`, `circleBorderSuccess`, `circleBorderWarning`
  - icon colors (default & typed): `iconColor`, `iconColorInfo`, `iconColorError`, `iconColorSuccess`, `iconColorWarning`
  - line color: `lineColor`

-}
type alias Vars =
    { titleMarginMedium : String
    , titleMarginLarge : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , iconSizeMedium : String
    , iconSizeLarge : String
    , contentFontSize : String
    , titleFontWeight : String
    , circleBorder : String
    , circleBorderInfo : String
    , circleBorderError : String
    , circleBorderSuccess : String
    , circleBorderWarning : String
    , iconColor : String
    , iconColorInfo : String
    , iconColorError : String
    , iconColorSuccess : String
    , iconColorWarning : String
    , titleTextColor : String
    , contentTextColor : String
    , metaTextColor : String
    , lineColor : String
    }


{-| Resolve the Timeline variables for a theme — upstream `self(common)`: Light and Dark
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
    { titleMarginMedium = "0 0 6px 0"
    , titleMarginLarge = "-2px 0 6px 0"
    , titleFontSizeMedium = "14px"
    , titleFontSizeLarge = "16px"
    , iconSizeMedium = "14px"
    , iconSizeLarge = "14px"
    , contentFontSize = common.fontSize
    , titleFontWeight = common.fontWeightStrong
    , circleBorder = "2px solid rgb(118, 124, 130)"
    , circleBorderInfo = "2px solid #2080f0"
    , circleBorderError = "2px solid #d03050"
    , circleBorderSuccess = "2px solid #18a058"
    , circleBorderWarning = "2px solid #f0a020"
    , iconColor = common.textColor3
    , iconColorInfo = common.infoColor
    , iconColorError = common.errorColor
    , iconColorSuccess = common.successColor
    , iconColorWarning = common.warningColor
    , titleTextColor = common.textColor1
    , contentTextColor = common.textColor2
    , metaTextColor = common.textColor3
    , lineColor = common.railColor
    }


dark : Common -> Vars
dark common =
    { titleMarginMedium = "0 0 6px 0"
    , titleMarginLarge = "-2px 0 6px 0"
    , titleFontSizeMedium = "14px"
    , titleFontSizeLarge = "16px"
    , iconSizeMedium = "14px"
    , iconSizeLarge = "14px"
    , contentFontSize = common.fontSize
    , titleFontWeight = common.fontWeightStrong
    , circleBorder = "2px solid rgba(255, 255, 255, 0.52)"
    , circleBorderInfo = "2px solid rgb(56, 137, 197)"
    , circleBorderError = "2px solid rgb(208, 58, 82)"
    , circleBorderSuccess = "2px solid rgb(42, 148, 125)"
    , circleBorderWarning = "2px solid rgb(240, 138, 0)"
    , iconColor = common.textColor3
    , iconColorInfo = common.infoColorSuppl
    , iconColorError = common.errorColorSuppl
    , iconColorSuccess = common.successColorSuppl
    , iconColorWarning = common.warningColorSuppl
    , titleTextColor = common.textColor1
    , contentTextColor = common.textColor2
    , metaTextColor = common.textColor3
    , lineColor = common.railColor
    }
