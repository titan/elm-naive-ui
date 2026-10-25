module NUI.Theme.DynamicTags exposing (Vars, vars)

{-| Theme variables for the **DynamicTags** component — the Elm counterpart of Naive UI's
`src/DynamicTags/styles/light.ts` & `dark.ts` cssr theme (selfVars). DynamicTags renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`inputWidth` → `--n-input-width`).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to DynamicTags's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the DynamicTags CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`inputWidth` → `--n-input-width`).
-}
type alias Vars =
    { inputWidth : String
    }


{-| Resolve the DynamicTags variables for a theme — upstream `self(common)`: Light and Dark
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
    { inputWidth = "64px"
    }


dark : Common -> Vars
dark common =
    { inputWidth = "64px"
    }
