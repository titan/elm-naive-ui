module NUI.Theme.Rate exposing (Vars, vars)

{-| Theme variables for the **Rate** component — the Elm counterpart of Naive UI's
`src/Rate/styles/light.ts` & `dark.ts` cssr theme (selfVars). Rate renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`itemColor` → `--n-item-color`, `itemColorActive` → `--n-item-color-active`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Rate's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Rate CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`itemColor` → `--n-item-color`).
-}
type alias Vars =
    { itemColor : String
    , itemColorActive : String
    , sizeSmall : String
    , sizeMedium : String
    , sizeLarge : String
    }


{-| Resolve the Rate variables for a theme — upstream `self(common)`: Light and Dark
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
    { itemColor = common.railColor
    , itemColorActive = "#FFCC33"
    , sizeSmall = "16px"
    , sizeMedium = "20px"
    , sizeLarge = "24px"
    }


dark : Common -> Vars
dark common =
    { itemColor = common.railColor
    , itemColorActive = "#CCAA33"
    , sizeSmall = "16px"
    , sizeMedium = "20px"
    , sizeLarge = "24px"
    }
