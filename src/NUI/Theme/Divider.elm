module NUI.Theme.Divider exposing (Vars, vars)

{-| Theme variables for the **Divider** component — the Elm counterpart of Naive UI's
`src/Divider/styles/light.ts` & `dark.ts` cssr theme (selfVars). Divider renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`textColor` → `--n-text-color`, `color` → `--n-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Divider's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Divider CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`textColor` → `--n-text-color`).
-}
type alias Vars =
    { textColor : String
    , color : String
    , fontWeight : String
    }


{-| Resolve the Divider variables for a theme — upstream `self(common)`: Light and Dark
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
    { textColor = common.textColor1
    , color = common.dividerColor
    , fontWeight = common.fontWeightStrong
    }


dark : Common -> Vars
dark common =
    { textColor = common.textColor1
    , color = common.dividerColor
    , fontWeight = common.fontWeightStrong
    }
