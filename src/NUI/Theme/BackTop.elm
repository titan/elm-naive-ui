module NUI.Theme.BackTop exposing (Vars, vars)

{-| Theme variables for **BackTop** (upstream `src/BackTop/styles/light.ts` & `dark.ts`, cssr
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
    { width : String
    , height : String
    , borderRadius : String
    , iconSize : String
    , color : String
    , textColor : String
    , iconColor : String
    , iconColorHover : String
    , iconColorPressed : String
    , boxShadow : String
    , boxShadowHover : String
    , boxShadowPressed : String
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
    { width = "44px"
    , height = "44px"
    , borderRadius = "22px"
    , iconSize = "26px"
    , color = common.popoverColor
    , textColor = common.textColor2
    , iconColor = common.textColor2
    , iconColorHover = common.primaryColorHover
    , iconColorPressed = common.primaryColorPressed
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    }


dark : Common -> Vars
dark common =
    { width = "44px"
    , height = "44px"
    , borderRadius = "22px"
    , iconSize = "26px"
    , color = common.popoverColor
    , textColor = common.textColor2
    , iconColor = common.textColor2
    , iconColorHover = common.primaryColorHover
    , iconColorPressed = common.primaryColorPressed
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    }
