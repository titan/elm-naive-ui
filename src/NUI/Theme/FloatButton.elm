module NUI.Theme.FloatButton exposing (Vars, vars)

{-| Theme variables for **FloatButton** (upstream `src/FloatButton/styles/light.ts` & `dark.ts`, cssr
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
    , colorHover : String
    , colorPressed : String
    , colorPrimary : String
    , colorPrimaryHover : String
    , colorPrimaryPressed : String
    , textColor : String
    , boxShadow : String
    , boxShadowHover : String
    , boxShadowPressed : String
    , textColorPrimary : String
    , borderRadiusSquare : String
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
    , colorHover = common.buttonColor2Hover
    , colorPressed = common.buttonColor2Pressed
    , colorPrimary = common.primaryColor
    , colorPrimaryHover = common.primaryColorHover
    , colorPrimaryPressed = common.primaryColorPressed
    , textColor = common.textColor2
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .16)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .24)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .24)"
    , textColorPrimary = "#fff"
    , borderRadiusSquare = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { color = common.popoverColor
    , colorHover = common.buttonColor2Hover
    , colorPressed = common.buttonColor2Pressed
    , colorPrimary = common.primaryColor
    , colorPrimaryHover = common.primaryColorHover
    , colorPrimaryPressed = common.primaryColorPressed
    , textColor = common.textColor2
    , boxShadow = "0 2px 8px 0px rgba(0, 0, 0, .12)"
    , boxShadowHover = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , boxShadowPressed = "0 2px 12px 0px rgba(0, 0, 0, .18)"
    , textColorPrimary = common.baseColor
    , borderRadiusSquare = common.borderRadius
    }
