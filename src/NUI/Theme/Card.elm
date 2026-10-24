module NUI.Theme.Card exposing (Vars, vars)

{-| Theme variables for the **Card** component — the Elm counterpart of Naive UI's
`src/Card/styles/light.ts` & `dark.ts` cssr theme (selfVars). Card renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`paddingSmall` → `--n-padding-small`, `paddingMedium` → `--n-padding-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Card's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Card CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`paddingSmall` → `--n-padding-small`).

Collected by concern:

  - close-button metrics & states: `closeIconSize`, `closeSize`, `closeColorHover`, `closeColorPressed`, `closeBorderRadius`, `closeIconColor`, `closeIconColorHover`, `closeIconColorPressed`
  - per-size paddings & title/body font sizes: `paddingSmall`, `paddingMedium`, `paddingLarge`, `paddingHuge`, `titleFontSizeSmall`, `titleFontSizeMedium`, `titleFontSizeLarge`, `titleFontSizeHuge`, `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`, `fontSizeHuge`
  - surfaces (base/modal/popover/embedded) & elevation: `lineHeight`, `color`, `colorModal`, `colorPopover`, `colorTarget`, `colorEmbedded`, `colorEmbeddedModal`, `colorEmbeddedPopover`, `borderColor`, `actionColor`, `boxShadow`, `borderRadius`
  - text colors: `textColor`, `titleTextColor`, `titleFontWeight`

-}
type alias Vars =
    { paddingSmall : String
    , paddingMedium : String
    , paddingLarge : String
    , paddingHuge : String
    , titleFontSizeSmall : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , titleFontSizeHuge : String
    , closeIconSize : String
    , closeSize : String
    , lineHeight : String
    , color : String
    , colorModal : String
    , colorPopover : String
    , colorTarget : String
    , colorEmbedded : String
    , colorEmbeddedModal : String
    , colorEmbeddedPopover : String
    , textColor : String
    , titleTextColor : String
    , borderColor : String
    , actionColor : String
    , titleFontWeight : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeBorderRadius : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , boxShadow : String
    , borderRadius : String
    }


{-| Resolve the Card variables for a theme — upstream `self(common)`: Light and Dark
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
    { paddingSmall = "12px 16px 12px"
    , paddingMedium = "19px 24px 20px"
    , paddingLarge = "23px 32px 24px"
    , paddingHuge = "27px 40px 28px"
    , titleFontSizeSmall = "16px"
    , titleFontSizeMedium = "18px"
    , titleFontSizeLarge = "18px"
    , titleFontSizeHuge = "18px"
    , closeIconSize = "18px"
    , closeSize = "22px"
    , lineHeight = common.lineHeight
    , color = common.cardColor
    , colorModal = common.modalColor
    , colorPopover = common.popoverColor
    , colorTarget = common.primaryColor
    , colorEmbedded = common.actionColor
    , colorEmbeddedModal = common.actionColor
    , colorEmbeddedPopover = common.actionColor
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , borderColor = common.dividerColor
    , actionColor = common.actionColor
    , titleFontWeight = common.fontWeightStrong
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSize
    , fontSizeHuge = common.fontSize
    , boxShadow = common.boxShadow1
    , borderRadius = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { paddingSmall = "12px 16px 12px"
    , paddingMedium = "19px 24px 20px"
    , paddingLarge = "23px 32px 24px"
    , paddingHuge = "27px 40px 28px"
    , titleFontSizeSmall = "16px"
    , titleFontSizeMedium = "18px"
    , titleFontSizeLarge = "18px"
    , titleFontSizeHuge = "18px"
    , closeIconSize = "18px"
    , closeSize = "22px"
    , lineHeight = common.lineHeight
    , color = common.cardColor
    , colorModal = common.modalColor
    , colorPopover = common.popoverColor
    , colorTarget = common.primaryColor
    , colorEmbedded = common.cardColor
    , colorEmbeddedModal = common.modalColor
    , colorEmbeddedPopover = common.popoverColor
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , borderColor = common.dividerColor
    , actionColor = common.actionColor
    , titleFontWeight = common.fontWeightStrong
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSize
    , fontSizeHuge = common.fontSize
    , boxShadow = common.boxShadow1
    , borderRadius = common.borderRadius
    }
