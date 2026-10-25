module NUI.Theme.FloatButtonGroup exposing (Vars, vars)

{-| Theme variables for **FloatButtonGroup** (upstream `src/FloatButtonGroup/styles/light.ts` & `dark.ts`, cssr
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
    , buttonBorderColor : String
    , borderRadiusSquare : String
    , boxShadow : String
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
