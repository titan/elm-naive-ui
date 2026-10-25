module NUI.Theme.DynamicInput exposing (Vars, vars)

{-| Theme variables for **DynamicInput** (upstream `src/DynamicInput/styles/light.ts` & `dark.ts`, cssr
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
    { actionMargin : String
    , actionMarginRtl : String
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
    { actionMargin = "0 0 0 20px"
    , actionMarginRtl = "0 20px 0 0"
    }


dark : Common -> Vars
dark common =
    { actionMargin = "0 0 0 20px"
    , actionMarginRtl = "0 20px 0 0"
    }
