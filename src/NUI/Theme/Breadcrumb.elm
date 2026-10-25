module NUI.Theme.Breadcrumb exposing (Vars, vars)

{-| Theme variables for the **Breadcrumb** component — the Elm counterpart of Naive UI's
`src/Breadcrumb/styles/light.ts` & `dark.ts` cssr theme (selfVars). Breadcrumb renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`fontWeightActive` → `--n-font-weight-active`, `fontSize` → `--n-font-size`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Breadcrumb's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Breadcrumb CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`fontWeightActive` → `--n-font-weight-active`).
-}
type alias Vars =
    { fontWeightActive : String
    , fontSize : String
    , itemLineHeight : String
    , itemTextColor : String
    , itemTextColorHover : String
    , itemTextColorPressed : String
    , itemTextColorActive : String
    , itemBorderRadius : String
    , itemColorHover : String
    , itemColorPressed : String
    , separatorColor : String
    }


{-| Resolve the Breadcrumb variables for a theme — upstream `self(common)`: Light and Dark
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
    { fontWeightActive = "400"
    , fontSize = common.fontSize
    , itemLineHeight = "1.25"
    , itemTextColor = common.textColor3
    , itemTextColorHover = common.textColor2
    , itemTextColorPressed = common.textColor2
    , itemTextColorActive = common.textColor2
    , itemBorderRadius = common.borderRadius
    , itemColorHover = common.buttonColor2Hover
    , itemColorPressed = common.buttonColor2Pressed
    , separatorColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { fontWeightActive = "400"
    , fontSize = common.fontSize
    , itemLineHeight = "1.25"
    , itemTextColor = common.textColor3
    , itemTextColorHover = common.textColor2
    , itemTextColorPressed = common.textColor2
    , itemTextColorActive = common.textColor2
    , itemBorderRadius = common.borderRadius
    , itemColorHover = common.buttonColor2Hover
    , itemColorPressed = common.buttonColor2Pressed
    , separatorColor = common.textColor3
    }
