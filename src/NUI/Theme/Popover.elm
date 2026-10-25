module NUI.Theme.Popover exposing (Vars, vars)

{-| Theme variables for **Popover** (upstream `src/Popover/styles/light.ts` & `dark.ts`, cssr
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
    { space : String
    , spaceArrow : String
    , arrowOffset : String
    , arrowOffsetVertical : String
    , arrowHeight : String
    , padding : String
    , fontSize : String
    , borderRadius : String
    , color : String
    , dividerColor : String
    , textColor : String
    , boxShadow : String
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
    { space = "6px"
    , spaceArrow = "10px"
    , arrowOffset = "10px"
    , arrowOffsetVertical = "10px"
    , arrowHeight = "6px"
    , padding = "8px 14px"
    , fontSize = common.fontSize
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , dividerColor = common.dividerColor
    , textColor = common.textColor2
    , boxShadow = common.boxShadow2
    }


dark : Common -> Vars
dark common =
    { space = "6px"
    , spaceArrow = "10px"
    , arrowOffset = "10px"
    , arrowOffsetVertical = "10px"
    , arrowHeight = "6px"
    , padding = "8px 14px"
    , fontSize = common.fontSize
    , borderRadius = common.borderRadius
    , color = common.popoverColor
    , dividerColor = common.dividerColor
    , textColor = common.textColor2
    , boxShadow = common.boxShadow2
    }
