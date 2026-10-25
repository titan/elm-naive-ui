module NUI.Theme.Log exposing (Vars, vars)

{-| Theme variables for **Log** (upstream `src/Log/styles/light.ts` & `dark.ts`, cssr
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
    { loaderFontSize : String
    , loaderTextColor : String
    , loaderColor : String
    , loaderBorder : String
    , loadingColor : String
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
    { loaderFontSize = common.fontSize
    , loaderTextColor = common.textColor2
    , loaderColor = common.modalColor
    , loaderBorder = "1px solid rgb(224, 224, 230)"
    , loadingColor = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { loaderFontSize = common.fontSize
    , loaderTextColor = common.textColor2
    , loaderColor = common.inputColor
    , loaderBorder = "1px solid #0000"
    , loadingColor = common.primaryColor
    }
