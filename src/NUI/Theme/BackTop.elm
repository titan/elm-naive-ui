module NUI.Theme.BackTop exposing (Vars, vars)

{-| Theme variables for the **BackTop** component — the Elm counterpart of Naive UI's
`src/BackTop/styles/light.ts` & `dark.ts` cssr theme (selfVars). BackTop renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`width` → `--n-width`, `height` → `--n-height`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to BackTop's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the BackTop CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`width` → `--n-width`).
-}
type alias Vars =
    { width : String
    , height : String
    , borderRadius : String
    , iconSize : String
    , color : String
    , textColor : String
    , iconColor : String
    , iconColorHover : String
    , iconColorPressed : String
    , boxShadow : String
    , boxShadowHover : String
    , boxShadowPressed : String
    }


{-| Resolve the BackTop variables for a theme — upstream `self(common)`: Light and Dark
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
    { width = "44px"
    , height = "44px"
    , borderRadius = "22px"
    , iconSize = "26px"
    , color = common.popoverColor
    , textColor = common.textColor2
    , iconColor = common.textColor2
    , iconColorHover = common.primaryColorHover
    , iconColorPressed = common.primaryColorPressed
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    }


dark : Common -> Vars
dark common =
    { width = "44px"
    , height = "44px"
    , borderRadius = "22px"
    , iconSize = "26px"
    , color = common.popoverColor
    , textColor = common.textColor2
    , iconColor = common.textColor2
    , iconColorHover = common.primaryColorHover
    , iconColorPressed = common.primaryColorPressed
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    }
