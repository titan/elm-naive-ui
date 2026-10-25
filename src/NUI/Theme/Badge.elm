module NUI.Theme.Badge exposing (Vars, vars)

{-| Theme variables for **Badge** (upstream `src/Badge/styles/light.ts` & `dark.ts`, cssr
selfVars). Fields map 1:1 onto the component's `--n-*` custom properties
(kebab-case of the field name). `vars` resolves the light/dark palette from
`theme.mode` + `theme.common` — upstream's `self(common)`; override individual
fields to customise.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties this component's CSS consumes, as one record.
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


{-| Resolve this component's variables for a theme (see the module doc).
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
