module NUI.Theme.Scrollbar exposing (Vars, vars)

{-| Theme variables for **Scrollbar** (upstream `src/_internal/scrollbar/styles/light.ts` & `dark.ts`, cssr
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
    { railInsetHorizontalBottom : String
    , railInsetHorizontalTop : String
    , railInsetVerticalRight : String
    , railInsetVerticalLeft : String
    , railColor : String
    , height : String
    , width : String
    , borderRadius : String
    , color : String
    , colorHover : String
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
    { railInsetHorizontalBottom = "auto 2px 4px 2px"
    , railInsetHorizontalTop = "4px 2px auto 2px"
    , railInsetVerticalRight = "2px 4px 2px auto"
    , railInsetVerticalLeft = "2px auto 2px 4px"
    , railColor = "transparent"
    , height = common.scrollbarHeight
    , width = common.scrollbarWidth
    , borderRadius = common.scrollbarBorderRadius
    , color = common.scrollbarColor
    , colorHover = common.scrollbarColorHover
    }


dark : Common -> Vars
dark common =
    { railInsetHorizontalBottom = "auto 2px 4px 2px"
    , railInsetHorizontalTop = "4px 2px auto 2px"
    , railInsetVerticalRight = "2px 4px 2px auto"
    , railInsetVerticalLeft = "2px auto 2px 4px"
    , railColor = "transparent"
    , height = common.scrollbarHeight
    , width = common.scrollbarWidth
    , borderRadius = common.scrollbarBorderRadius
    , color = common.scrollbarColor
    , colorHover = common.scrollbarColorHover
    }
