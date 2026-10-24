module NUI.Theme.Calendar exposing (Vars, vars)

{-| Theme variables for the **Calendar** component — the Elm counterpart of Naive UI's
`src/Calendar/styles/light.ts` & `dark.ts` cssr theme (selfVars). Calendar renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`titleFontSize` → `--n-title-font-size`, `borderRadius` → `--n-border-radius`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Calendar's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Calendar CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`titleFontSize` → `--n-title-font-size`).

Collected by concern:

  - title & shape: `titleFontSize`, `borderRadius`, `titleFontWeight`, `titleTextColor`
  - borders/surfaces incl. modal & popover: `borderColor`, `borderColorModal`, `borderColorPopover`, `dateColorCurrent`, `cellColorHover`, `cellColorHoverModal`, `cellColorHoverPopover`, `cellColor`, `cellColorModal`, `cellColorPopover`, `barColor`
  - typography: `textColor`, `dayTextColor`, `fontSize`, `lineHeight`, `dateTextColorCurrent`

-}
type alias Vars =
    { titleFontSize : String
    , borderRadius : String
    , borderColor : String
    , borderColorModal : String
    , borderColorPopover : String
    , textColor : String
    , titleFontWeight : String
    , titleTextColor : String
    , dayTextColor : String
    , fontSize : String
    , lineHeight : String
    , dateColorCurrent : String
    , dateTextColorCurrent : String
    , cellColorHover : String
    , cellColorHoverModal : String
    , cellColorHoverPopover : String
    , cellColor : String
    , cellColorModal : String
    , cellColorPopover : String
    , barColor : String
    }


{-| Resolve the Calendar variables for a theme — upstream `self(common)`: Light and Dark
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
    { titleFontSize = "22px"
    , borderRadius = common.borderRadius
    , borderColor = "rgba(239, 239, 245, 1)"
    , borderColorModal = "rgba(239, 239, 245, 1)"
    , borderColorPopover = "rgba(239, 239, 245, 1)"
    , textColor = common.textColor2
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , dayTextColor = common.textColorDisabled
    , fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , dateColorCurrent = common.primaryColor
    , dateTextColorCurrent = common.baseColor
    , cellColorHover = "rgba(243, 243, 245, 1)"
    , cellColorHoverModal = "rgba(243, 243, 245, 1)"
    , cellColorHoverPopover = "rgba(243, 243, 245, 1)"
    , cellColor = common.cardColor
    , cellColorModal = common.modalColor
    , cellColorPopover = common.popoverColor
    , barColor = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { titleFontSize = "22px"
    , borderRadius = common.borderRadius
    , borderColor = "rgba(45, 45, 48, 1)"
    , borderColorModal = "rgba(63, 63, 68, 1)"
    , borderColorPopover = "rgba(88, 88, 94, 1)"
    , textColor = common.textColor2
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , dayTextColor = common.textColorDisabled
    , fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , dateColorCurrent = common.primaryColor
    , dateTextColorCurrent = common.baseColor
    , cellColorHover = "rgba(45, 45, 48, 1)"
    , cellColorHoverModal = "rgba(63, 63, 68, 1)"
    , cellColorHoverPopover = "rgba(88, 88, 94, 1)"
    , cellColor = common.cardColor
    , cellColorModal = common.modalColor
    , cellColorPopover = common.popoverColor
    , barColor = common.primaryColor
    }
