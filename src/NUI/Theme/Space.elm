module NUI.Theme.Space exposing (Vars, vars)

{-| Theme variables for **Space** (upstream `src/Space/styles/light.ts` & `dark.ts`, cssr
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
    { gapSmall : String
    , gapMedium : String
    , gapLarge : String
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
    { gapSmall = "4px 8px"
    , gapMedium = "8px 12px"
    , gapLarge = "12px 16px"
    }


dark : Common -> Vars
dark common =
    { gapSmall = "4px 8px"
    , gapMedium = "8px 12px"
    , gapLarge = "12px 16px"
    }
