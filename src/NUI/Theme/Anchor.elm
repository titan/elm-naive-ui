module NUI.Theme.Anchor exposing (Vars, vars)

{-| Theme variables for **Anchor** (upstream `src/Anchor/styles/light.ts` & `dark.ts`, cssr
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
    { linkFontSize : String
    , linkPadding : String
    , railWidth : String
    , borderRadius : String
    , railColor : String
    , railColorActive : String
    , linkColor : String
    , linkTextColor : String
    , linkTextColorHover : String
    , linkTextColorPressed : String
    , linkTextColorActive : String
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
    { linkFontSize = "13px"
    , linkPadding = "0 0 0 16px"
    , railWidth = "4px"
    , borderRadius = common.borderRadius
    , railColor = common.railColor
    , railColorActive = common.primaryColor
    , linkColor = "rgba(24, 160, 88, 0.15)"
    , linkTextColor = common.textColor2
    , linkTextColorHover = common.primaryColorHover
    , linkTextColorPressed = common.primaryColorPressed
    , linkTextColorActive = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { linkFontSize = "13px"
    , linkPadding = "0 0 0 16px"
    , railWidth = "4px"
    , borderRadius = common.borderRadius
    , railColor = common.railColor
    , railColorActive = common.primaryColor
    , linkColor = "rgba(99, 226, 183, 0.15)"
    , linkTextColor = common.textColor2
    , linkTextColorHover = common.primaryColorHover
    , linkTextColorPressed = common.primaryColorPressed
    , linkTextColorActive = common.primaryColor
    }
