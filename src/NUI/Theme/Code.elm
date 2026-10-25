module NUI.Theme.Code exposing (Vars, vars)

{-| Theme variables for **Code** (upstream `src/Code/styles/light.ts` & `dark.ts`, cssr
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
    { textColor : String
    , fontSize : String
    , fontWeightStrong : String
    , mono3 : String
    , hue1 : String
    , hue2 : String
    , hue3 : String
    , hue4 : String
    , hue5 : String
    , hue52 : String
    , hue6 : String
    , hue62 : String
    , lineNumberTextColor : String
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
    { textColor = common.textColor2
    , fontSize = common.fontSize
    , fontWeightStrong = common.fontWeightStrong
    , mono3 = "#a0a1a7"
    , hue1 = "#0184bb"
    , hue2 = "#4078f2"
    , hue3 = "#a626a4"
    , hue4 = "#50a14f"
    , hue5 = "#e45649"
    , hue52 = "#c91243"
    , hue6 = "#986801"
    , hue62 = "#c18401"
    , lineNumberTextColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { textColor = common.textColor2
    , fontSize = common.fontSize
    , fontWeightStrong = common.fontWeightStrong
    , mono3 = "#5c6370"
    , hue1 = "#56b6c2"
    , hue2 = "#61aeee"
    , hue3 = "#c678dd"
    , hue4 = "#98c379"
    , hue5 = "#e06c75"
    , hue52 = "#be5046"
    , hue6 = "#d19a66"
    , hue62 = "#e6c07b"
    , lineNumberTextColor = common.textColor3
    }
