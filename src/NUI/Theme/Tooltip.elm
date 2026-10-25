module NUI.Theme.Tooltip exposing (Vars, vars)

{-| Theme variables for **Tooltip** (upstream `src/Tooltip/styles/light.ts` & `dark.ts`, cssr
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
    { padding : String
    , borderRadius : String
    , boxShadow : String
    , color : String
    , textColor : String
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
    { padding = "8px 14px"
    , borderRadius = common.borderRadius
    , boxShadow = common.boxShadow2
    , color = "rgba(38, 38, 38, 1)"
    , textColor = common.baseColor
    }


dark : Common -> Vars
dark common =
    { padding = "8px 14px"
    , borderRadius = common.borderRadius
    , boxShadow = common.boxShadow2
    , color = common.popoverColor
    , textColor = common.textColor2
    }
