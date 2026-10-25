module NUI.Theme.Image exposing (Vars, vars)

{-| Theme variables for **Image** (upstream `src/Image/styles/light.ts` & `dark.ts`, cssr
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
    { toolbarIconColor : String
    , toolbarColor : String
    , toolbarBoxShadow : String
    , toolbarBorderRadius : String
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
    { toolbarIconColor = "rgba(255, 255, 255, .9)"
    , toolbarColor = "rgba(0, 0, 0, .35)"
    , toolbarBoxShadow = "none"
    , toolbarBorderRadius = "24px"
    }


dark : Common -> Vars
dark common =
    { toolbarIconColor = common.textColor2
    , toolbarColor = "rgba(0, 0, 0, .35)"
    , toolbarBoxShadow = "none"
    , toolbarBorderRadius = "24px"
    }
