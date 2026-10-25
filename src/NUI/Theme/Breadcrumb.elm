module NUI.Theme.Breadcrumb exposing (Vars, vars)

{-| Theme variables for **Breadcrumb** (upstream `src/Breadcrumb/styles/light.ts` & `dark.ts`, cssr
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
    { fontWeightActive : String
    , fontSize : String
    , itemLineHeight : String
    , itemTextColor : String
    , itemTextColorHover : String
    , itemTextColorPressed : String
    , itemTextColorActive : String
    , itemBorderRadius : String
    , itemColorHover : String
    , itemColorPressed : String
    , separatorColor : String
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
    { fontWeightActive = "400"
    , fontSize = common.fontSize
    , itemLineHeight = "1.25"
    , itemTextColor = common.textColor3
    , itemTextColorHover = common.textColor2
    , itemTextColorPressed = common.textColor2
    , itemTextColorActive = common.textColor2
    , itemBorderRadius = common.borderRadius
    , itemColorHover = common.buttonColor2Hover
    , itemColorPressed = common.buttonColor2Pressed
    , separatorColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { fontWeightActive = "400"
    , fontSize = common.fontSize
    , itemLineHeight = "1.25"
    , itemTextColor = common.textColor3
    , itemTextColorHover = common.textColor2
    , itemTextColorPressed = common.textColor2
    , itemTextColorActive = common.textColor2
    , itemBorderRadius = common.borderRadius
    , itemColorHover = common.buttonColor2Hover
    , itemColorPressed = common.buttonColor2Pressed
    , separatorColor = common.textColor3
    }
