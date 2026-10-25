module NUI.Theme.PageHeader exposing (Vars, vars)

{-| Theme variables for **PageHeader** (upstream `src/PageHeader/styles/light.ts` & `dark.ts`, cssr
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
    { titleFontSize : String
    , backSize : String
    , titleFontWeight : String
    , fontSize : String
    , titleTextColor : String
    , backColor : String
    , backColorHover : String
    , backColorPressed : String
    , subtitleTextColor : String
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
    { titleFontSize = "18px"
    , backSize = "22px"
    , titleFontWeight = common.fontWeightStrong
    , fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , backColor = common.textColor2
    , backColorHover = common.primaryColorHover
    , backColorPressed = common.primaryColorPressed
    , subtitleTextColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { titleFontSize = "18px"
    , backSize = "22px"
    , titleFontWeight = common.fontWeightStrong
    , fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , backColor = common.textColor2
    , backColorHover = common.primaryColorHover
    , backColorPressed = common.primaryColorPressed
    , subtitleTextColor = common.textColor3
    }
