module NUI.Theme.Icon exposing (Vars, vars)

{-| Theme variables for **Icon** (upstream `src/Icon/styles/light.ts` & `dark.ts`, cssr
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
    , opacity1Depth : String
    , opacity2Depth : String
    , opacity3Depth : String
    , opacity4Depth : String
    , opacity5Depth : String
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
    { color = common.textColorBase
    , opacity1Depth = common.opacity1
    , opacity2Depth = common.opacity2
    , opacity3Depth = common.opacity3
    , opacity4Depth = common.opacity4
    , opacity5Depth = common.opacity5
    }


dark : Common -> Vars
dark common =
    { color = common.textColorBase
    , opacity1Depth = common.opacity1
    , opacity2Depth = common.opacity2
    , opacity3Depth = common.opacity3
    , opacity4Depth = common.opacity4
    , opacity5Depth = common.opacity5
    }
