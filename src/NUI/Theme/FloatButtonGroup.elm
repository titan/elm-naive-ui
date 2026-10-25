module NUI.Theme.FloatButtonGroup exposing (Vars, vars)

{-| Theme variables for the **FloatButtonGroup** component — the Elm counterpart of Naive UI's
`src/FloatButtonGroup/styles/light.ts` & `dark.ts` cssr theme (selfVars). FloatButtonGroup renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`color` → `--n-color`, `buttonBorderColor` → `--n-button-border-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to FloatButtonGroup's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the FloatButtonGroup CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`color` → `--n-color`).
-}
type alias Vars =
    { color : String
    , buttonBorderColor : String
    , borderRadiusSquare : String
    , boxShadow : String
    }


{-| Resolve the FloatButtonGroup variables for a theme — upstream `self(common)`: Light and Dark
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
    { color = common.popoverColor
    , buttonBorderColor = common.dividerColor
    , borderRadiusSquare = common.borderRadius
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    }


dark : Common -> Vars
dark common =
    { color = common.popoverColor
    , buttonBorderColor = common.dividerColor
    , borderRadiusSquare = common.borderRadius
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    }
