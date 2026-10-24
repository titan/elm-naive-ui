module NUI.Theme.AvatarGroup exposing (Vars, vars)

{-| Theme variables for the **AvatarGroup** component — the Elm counterpart of Naive UI's
`src/AvatarGroup/styles/light.ts` & `dark.ts` cssr theme (selfVars). AvatarGroup renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`gap` → `--n-gap`).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to AvatarGroup's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the AvatarGroup CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`gap` → `--n-gap`).

Collected by concern:

  - spacing: `gap`

-}
type alias Vars =
    { gap : String
    }


{-| Resolve the AvatarGroup variables for a theme — upstream `self(common)`: Light and Dark
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
    { gap = "-12px"
    }


dark : Common -> Vars
dark common =
    { gap = "-12px"
    }
