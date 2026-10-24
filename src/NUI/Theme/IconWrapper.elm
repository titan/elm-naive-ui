module NUI.Theme.IconWrapper exposing (Vars, vars)

{-| Theme variables for the **IconWrapper** component — the Elm counterpart of Naive UI's
`src/IconWrapper/styles/light.ts` & `dark.ts` cssr theme (selfVars). IconWrapper renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`color` → `--n-color`, `iconColor` → `--n-icon-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to IconWrapper's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the IconWrapper CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`color` → `--n-color`).

Collected by concern:

  - surface & glyph colors: `color`, `iconColor`

-}
type alias Vars =
    { color : String
    , iconColor : String
    }


{-| Resolve the IconWrapper variables for a theme — upstream `self(common)`: Light and Dark
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
    { color = common.primaryColor
    , iconColor = common.baseColor
    }


dark : Common -> Vars
dark common =
    { color = common.primaryColor
    , iconColor = common.baseColor
    }
