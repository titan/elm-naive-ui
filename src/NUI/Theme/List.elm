module NUI.Theme.List exposing (Vars, vars)

{-| Theme variables for the **List** component — the Elm counterpart of Naive UI's
`src/List/styles/light.ts` & `dark.ts` cssr theme (selfVars). List renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`textColor` → `--n-text-color`, `color` → `--n-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to List's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the List CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`textColor` → `--n-text-color`).

Collected by concern:

  - item surface colors & hover, incl. modal/popover: `color`, `colorHover`, `colorModal`, `colorHoverModal`, `colorPopover`, `colorHoverPopover`
  - borders & radius: `borderColor`, `borderColorModal`, `borderColorPopover`, `borderRadius`
  - typography: `textColor`, `fontSize`

-}
type alias Vars =
    { textColor : String
    , color : String
    , colorHover : String
    , colorModal : String
    , colorHoverModal : String
    , colorPopover : String
    , colorHoverPopover : String
    , borderColor : String
    , borderColorModal : String
    , borderColorPopover : String
    , borderRadius : String
    , fontSize : String
    }


{-| Resolve the List variables for a theme — upstream `self(common)`: Light and Dark
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
    { textColor = common.textColor2
    , color = common.cardColor
    , colorHover = common.hoverColor
    , colorModal = common.modalColor
    , colorHoverModal = "rgba(243, 243, 245, 1)"
    , colorPopover = common.popoverColor
    , colorHoverPopover = "rgba(243, 243, 245, 1)"
    , borderColor = common.dividerColor
    , borderColorModal = "rgba(239, 239, 245, 1)"
    , borderColorPopover = "rgba(239, 239, 245, 1)"
    , borderRadius = common.borderRadius
    , fontSize = common.fontSize
    }


dark : Common -> Vars
dark common =
    { textColor = common.textColor2
    , color = common.cardColor
    , colorHover = common.hoverColor
    , colorModal = common.modalColor
    , colorHoverModal = "rgba(63, 63, 68, 1)"
    , colorPopover = common.popoverColor
    , colorHoverPopover = "rgba(88, 88, 94, 1)"
    , borderColor = common.dividerColor
    , borderColorModal = "rgba(63, 63, 68, 1)"
    , borderColorPopover = "rgba(88, 88, 94, 1)"
    , borderRadius = common.borderRadius
    , fontSize = common.fontSize
    }
