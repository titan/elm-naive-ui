module NUI.Theme.FloatButton exposing (Vars, vars)

{-| Theme variables for the **FloatButton** component — the Elm counterpart of Naive UI's
`src/FloatButton/styles/light.ts` & `dark.ts` cssr theme (selfVars). FloatButton renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`color` → `--n-color`, `colorHover` → `--n-color-hover`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to FloatButton's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the FloatButton CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`color` → `--n-color`).
-}
type alias Vars =
    { color : String
    , colorHover : String
    , colorPressed : String
    , colorPrimary : String
    , colorPrimaryHover : String
    , colorPrimaryPressed : String
    , textColor : String
    , boxShadow : String
    , boxShadowHover : String
    , boxShadowPressed : String
    , textColorPrimary : String
    , borderRadiusSquare : String
    }


{-| Resolve the FloatButton variables for a theme — upstream `self(common)`: Light and Dark
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
    , colorHover = common.buttonColor2Hover
    , colorPressed = common.buttonColor2Pressed
    , colorPrimary = common.primaryColor
    , colorPrimaryHover = common.primaryColorHover
    , colorPrimaryPressed = common.primaryColorPressed
    , textColor = common.textColor2
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .16)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .24)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .24)"
    , textColorPrimary = "#fff"
    , borderRadiusSquare = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { color = common.popoverColor
    , colorHover = common.buttonColor2Hover
    , colorPressed = common.buttonColor2Pressed
    , colorPrimary = common.primaryColor
    , colorPrimaryHover = common.primaryColorHover
    , colorPrimaryPressed = common.primaryColorPressed
    , textColor = common.textColor2
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , textColorPrimary = common.baseColor
    , borderRadiusSquare = common.borderRadius
    }
