module NUI.Theme.Rate exposing (Vars, vars)

{-| Theme variables for **Rate** (upstream `src/Rate/styles/light.ts` & `dark.ts`, cssr
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
    { itemColor : String
    , itemColorActive : String
    , sizeSmall : String
    , sizeMedium : String
    , sizeLarge : String
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
    { itemColor = common.railColor
    , itemColorActive = "#FFCC33"
    , sizeSmall = "16px"
    , sizeMedium = "20px"
    , sizeLarge = "24px"
    }


dark : Common -> Vars
dark common =
    { itemColor = common.railColor
    , itemColorActive = "#CCAA33"
    , sizeSmall = "16px"
    , sizeMedium = "20px"
    , sizeLarge = "24px"
    }
