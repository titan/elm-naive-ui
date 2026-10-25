module NUI.Theme.Skeleton exposing (Vars, vars)

{-| Theme variables for **Skeleton** (upstream `src/Skeleton/styles/light.ts` & `dark.ts`, cssr
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
    , colorEnd : String
    , borderRadius : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
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
    { color = "#eee"
    , colorEnd = "#ddd"
    , borderRadius = common.borderRadius
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    }


dark : Common -> Vars
dark common =
    { color = "rgba(255, 255, 255, 0.12)"
    , colorEnd = "rgba(255, 255, 255, 0.18)"
    , borderRadius = common.borderRadius
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    }
