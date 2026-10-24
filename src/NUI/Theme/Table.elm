module NUI.Theme.Table exposing (Vars, vars)

{-| Theme variables for the **Table** component — the Elm counterpart of Naive UI's
`src/Table/styles/light.ts` & `dark.ts` cssr theme (selfVars). Table renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`thPaddingSmall` → `--n-th-padding-small`, `thPaddingMedium` → `--n-th-padding-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Table's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Table CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`thPaddingSmall` → `--n-th-padding-small`).

Collected by concern:

  - per-size cell paddings (th/td): `thPaddingSmall`, `thPaddingMedium`, `thPaddingLarge`, `tdPaddingSmall`, `tdPaddingMedium`, `tdPaddingLarge`
  - per-size font sizes, line height & radius: `fontSizeSmall`, `fontSizeMedium`, `fontSizeLarge`, `lineHeight`, `borderRadius`
  - borders (incl. modal/popover): `borderColor`, `borderColorModal`, `borderColorPopover`
  - cell surfaces (th/td, striped, modal/popover): `tdColor`, `tdColorModal`, `tdColorPopover`, `tdColorStriped`, `tdColorStripedModal`, `tdColorStripedPopover`, `thColor`, `thColorModal`, `thColorPopover`
  - header & cell text: `thTextColor`, `tdTextColor`, `thFontWeight`

-}
type alias Vars =
    { thPaddingSmall : String
    , thPaddingMedium : String
    , thPaddingLarge : String
    , tdPaddingSmall : String
    , tdPaddingMedium : String
    , tdPaddingLarge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , lineHeight : String
    , borderRadius : String
    , borderColor : String
    , borderColorModal : String
    , borderColorPopover : String
    , tdColor : String
    , tdColorModal : String
    , tdColorPopover : String
    , tdColorStriped : String
    , tdColorStripedModal : String
    , tdColorStripedPopover : String
    , thColor : String
    , thColorModal : String
    , thColorPopover : String
    , thTextColor : String
    , tdTextColor : String
    , thFontWeight : String
    }


{-| Resolve the Table variables for a theme — upstream `self(common)`: Light and Dark
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
    { thPaddingSmall = "6px"
    , thPaddingMedium = "12px"
    , thPaddingLarge = "12px"
    , tdPaddingSmall = "6px"
    , tdPaddingMedium = "12px"
    , tdPaddingLarge = "12px"
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , borderColor = "rgba(239, 239, 245, 1)"
    , borderColorModal = "rgba(239, 239, 245, 1)"
    , borderColorPopover = "rgba(239, 239, 245, 1)"
    , tdColor = common.cardColor
    , tdColorModal = common.modalColor
    , tdColorPopover = common.popoverColor
    , tdColorStriped = "rgba(250, 250, 252, 1)"
    , tdColorStripedModal = "rgba(250, 250, 252, 1)"
    , tdColorStripedPopover = "rgba(250, 250, 252, 1)"
    , thColor = "rgba(250, 250, 252, 1)"
    , thColorModal = "rgba(250, 250, 252, 1)"
    , thColorPopover = "rgba(250, 250, 252, 1)"
    , thTextColor = common.textColor1
    , tdTextColor = common.textColor2
    , thFontWeight = common.fontWeightStrong
    }


dark : Common -> Vars
dark common =
    { thPaddingSmall = "6px"
    , thPaddingMedium = "12px"
    , thPaddingLarge = "12px"
    , tdPaddingSmall = "6px"
    , tdPaddingMedium = "12px"
    , tdPaddingLarge = "12px"
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , borderColor = "rgba(45, 45, 48, 1)"
    , borderColorModal = "rgba(63, 63, 68, 1)"
    , borderColorPopover = "rgba(88, 88, 94, 1)"
    , tdColor = common.cardColor
    , tdColorModal = common.modalColor
    , tdColorPopover = common.popoverColor
    , tdColorStriped = "rgba(36, 36, 39, 1)"
    , tdColorStripedModal = "rgba(55, 55, 60, 1)"
    , tdColorStripedPopover = "rgba(81, 81, 87, 1)"
    , thColor = "rgba(38, 38, 42, 1)"
    , thColorModal = "rgba(57, 57, 62, 1)"
    , thColorPopover = "rgba(83, 83, 89, 1)"
    , thTextColor = common.textColor1
    , tdTextColor = common.textColor2
    , thFontWeight = common.fontWeightStrong
    }
