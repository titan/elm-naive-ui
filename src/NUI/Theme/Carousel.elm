module NUI.Theme.Carousel exposing (Vars, vars)

{-| Theme variables for **Carousel** (upstream `src/Carousel/styles/light.ts` & `dark.ts`, cssr
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
    { dotSize : String
    , dotColor : String
    , dotColorActive : String
    , dotColorFocus : String
    , dotLineWidth : String
    , dotLineWidthActive : String
    , arrowColor : String
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
    { dotSize = "8px"
    , dotColor = "rgba(255, 255, 255, .3)"
    , dotColorActive = "rgba(255, 255, 255, 1)"
    , dotColorFocus = "rgba(255, 255, 255, .5)"
    , dotLineWidth = "16px"
    , dotLineWidthActive = "24px"
    , arrowColor = "#eee"
    }


dark : Common -> Vars
dark common =
    { dotSize = "8px"
    , dotColor = "rgba(255, 255, 255, .3)"
    , dotColorActive = "rgba(255, 255, 255, 1)"
    , dotColorFocus = "rgba(255, 255, 255, .5)"
    , dotLineWidth = "16px"
    , dotLineWidthActive = "24px"
    , arrowColor = "#eee"
    }
