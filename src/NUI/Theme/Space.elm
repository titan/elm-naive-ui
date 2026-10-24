module NUI.Theme.Space exposing (Vars, vars)

{-| Theme variables for the **Space** component — the Elm counterpart of Naive UI's
`src/Space/styles/light.ts` & `dark.ts` cssr theme (selfVars). Space renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`gapSmall` → `--n-gap-small`, `gapMedium` → `--n-gap-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Space's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Space CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`gapSmall` → `--n-gap-small`).

Collected by concern:

  - gaps per size: `gapSmall`, `gapMedium`, `gapLarge`

-}
type alias Vars =
    { gapSmall : String
    , gapMedium : String
    , gapLarge : String
    }


{-| Resolve the Space variables for a theme — upstream `self(common)`: Light and Dark
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
    { gapSmall = "4px 8px"
    , gapMedium = "8px 12px"
    , gapLarge = "12px 16px"
    }


dark : Common -> Vars
dark common =
    { gapSmall = "4px 8px"
    , gapMedium = "8px 12px"
    , gapLarge = "12px 16px"
    }
