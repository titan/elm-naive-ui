module NUI.Theme.Icon exposing (Vars, vars)

{-| Theme variables for the **Icon** component — the Elm counterpart of Naive UI's
`src/Icon/styles/light.ts` & `dark.ts` cssr theme (selfVars). Icon renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`color` → `--n-color`, `opacity1Depth` → `--n-opacity1-depth`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Icon's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Icon CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`color` → `--n-color`).

Collected by concern:

  - base color: `color`
  - depth opacity scale: `opacity1Depth`, `opacity2Depth`, `opacity3Depth`, `opacity4Depth`, `opacity5Depth`

-}
type alias Vars =
    { color : String
    , opacity1Depth : String
    , opacity2Depth : String
    , opacity3Depth : String
    , opacity4Depth : String
    , opacity5Depth : String
    }


{-| Resolve the Icon variables for a theme — upstream `self(common)`: Light and Dark
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
    { color = common.textColorBase
    , opacity1Depth = common.opacity1
    , opacity2Depth = common.opacity2
    , opacity3Depth = common.opacity3
    , opacity4Depth = common.opacity4
    , opacity5Depth = common.opacity5
    }


dark : Common -> Vars
dark common =
    { color = common.textColorBase
    , opacity1Depth = common.opacity1
    , opacity2Depth = common.opacity2
    , opacity3Depth = common.opacity3
    , opacity4Depth = common.opacity4
    , opacity5Depth = common.opacity5
    }
