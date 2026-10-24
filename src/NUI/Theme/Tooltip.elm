module NUI.Theme.Tooltip exposing (Vars, vars)

{-| Theme variables for the **Tooltip** component — the Elm counterpart of Naive UI's
`src/Tooltip/styles/light.ts` & `dark.ts` cssr theme (selfVars). Tooltip renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`padding` → `--n-padding`, `borderRadius` → `--n-border-radius`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Tooltip's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Tooltip CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`padding` → `--n-padding`).

Collected by concern:

  - panel chrome (padding, radius, shadow, surface & text): `padding`, `borderRadius`, `boxShadow`, `color`, `textColor`

-}
type alias Vars =
    { padding : String
    , borderRadius : String
    , boxShadow : String
    , color : String
    , textColor : String
    }


{-| Resolve the Tooltip variables for a theme — upstream `self(common)`: Light and Dark
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
    { padding = "8px 14px"
    , borderRadius = common.borderRadius
    , boxShadow = common.boxShadow2
    , color = "rgba(38, 38, 38, 1)"
    , textColor = common.baseColor
    }


dark : Common -> Vars
dark common =
    { padding = "8px 14px"
    , borderRadius = common.borderRadius
    , boxShadow = common.boxShadow2
    , color = common.popoverColor
    , textColor = common.textColor2
    }
