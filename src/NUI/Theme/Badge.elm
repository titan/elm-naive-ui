module NUI.Theme.Badge exposing (Vars, vars)

{-| Theme variables for the **Badge** component — the Elm counterpart of Naive UI's
`src/Badge/styles/light.ts` & `dark.ts` cssr theme (selfVars). Badge renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`color` → `--n-color`, `colorInfo` → `--n-color-info`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Badge's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Badge CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`color` → `--n-color`).
-}
type alias Vars =
    { color : String
    , colorInfo : String
    , colorSuccess : String
    , colorError : String
    , colorWarning : String
    , fontSize : String
    , fontFamily : String
    }


{-| Resolve the Badge variables for a theme — upstream `self(common)`: Light and Dark
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
    { color = common.errorColor
    , colorInfo = common.infoColor
    , colorSuccess = common.successColor
    , colorError = common.errorColor
    , colorWarning = common.warningColor
    , fontSize = "12px"
    , fontFamily = common.fontFamily
    }


dark : Common -> Vars
dark common =
    { color = common.errorColorSuppl
    , colorInfo = common.infoColorSuppl
    , colorSuccess = common.successColorSuppl
    , colorError = common.errorColorSuppl
    , colorWarning = common.warningColorSuppl
    , fontSize = "12px"
    , fontFamily = common.fontFamily
    }
