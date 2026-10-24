module NUI.Theme.Popover exposing (Vars, vars)

{-| Theme variables for the **Popover** component — the Elm counterpart of Naive UI's
`src/Popover/styles/light.ts` & `dark.ts` cssr theme (selfVars). Popover renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`space` → `--n-space`, `spaceArrow` → `--n-space-arrow`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Popover's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Popover CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`space` → `--n-space`).

Collected by concern:

  - arrow geometry: `space`, `spaceArrow`, `arrowOffset`, `arrowOffsetVertical`, `arrowHeight`
  - panel chrome: `padding`, `fontSize`, `borderRadius`
  - surface, text & shadow: `color`, `dividerColor`, `textColor`, `boxShadow`

-}
type alias Vars =
    { space : String
    , spaceArrow : String
    , arrowOffset : String
    , arrowOffsetVertical : String
    , arrowHeight : String
    , padding : String
    , fontSize : String
    , borderRadius : String
    , color : String
    , dividerColor : String
    , textColor : String
    , boxShadow : String
    }


{-| Resolve the Popover variables for a theme — upstream `self(common)`: Light and Dark
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
    { space = "6px"
    , spaceArrow = "10px"
    , arrowOffset = "10px"
    , arrowOffsetVertical = "10px"
    , arrowHeight = "6px"
    , padding = "8px 14px"
    , fontSize = common.fontSize
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , dividerColor = common.dividerColor
    , textColor = common.textColor2
    , boxShadow = common.boxShadow2
    }


dark : Common -> Vars
dark common =
    { space = "6px"
    , spaceArrow = "10px"
    , arrowOffset = "10px"
    , arrowOffsetVertical = "10px"
    , arrowHeight = "6px"
    , padding = "8px 14px"
    , fontSize = common.fontSize
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , dividerColor = common.dividerColor
    , textColor = common.textColor2
    , boxShadow = common.boxShadow2
    }
