module NUI.Theme.Skeleton exposing (Vars, vars)

{-| Theme variables for the **Skeleton** component — the Elm counterpart of Naive UI's
`src/Skeleton/styles/light.ts` & `dark.ts` cssr theme (selfVars). Skeleton renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`color` → `--n-color`, `colorEnd` → `--n-color-end`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Skeleton's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Skeleton CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`color` → `--n-color`).

Collected by concern:

  - surface shimmer & radius: `color`, `colorEnd`, `borderRadius`
  - per-size heights: `heightSmall`, `heightMedium`, `heightLarge`

-}
type alias Vars =
    { color : String
    , colorEnd : String
    , borderRadius : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    }


{-| Resolve the Skeleton variables for a theme — upstream `self(common)`: Light and Dark
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
    { color = "#eee"
    , colorEnd = "#ddd"
    , borderRadius = common.borderRadius
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    }


dark : Common -> Vars
dark common =
    { color = "rgba(255, 255, 255, 0.12)"
    , colorEnd = "rgba(255, 255, 255, 0.18)"
    , borderRadius = common.borderRadius
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    }
