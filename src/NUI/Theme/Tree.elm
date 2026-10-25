module NUI.Theme.Tree exposing (Vars, vars)

{-| Theme variables for **Tree** (upstream `src/Tree/styles/light.ts` & `dark.ts`, cssr
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
    { fontSize : String
    , lineHeight : String
    , nodeHeight : String
    , nodeWrapperPadding : String
    , nodeBorderRadius : String
    , nodeColorHover : String
    , nodeColorPressed : String
    , nodeColorActive : String
    , arrowColor : String
    , nodeTextColor : String
    , nodeTextColorDisabled : String
    , loadingColor : String
    , dropMarkColor : String
    , lineColor : String
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
    { fontSize = common.fontSize
    , lineHeight = "1.5"
    , nodeHeight = "30px"
    , nodeWrapperPadding = "3px 0"
    , nodeBorderRadius = common.borderRadiusSmall
    , nodeColorHover = common.hoverColor
    , nodeColorPressed = common.pressedColor
    , nodeColorActive = "rgba(24, 160, 88, 0.1)"
    , arrowColor = common.textColor3
    , nodeTextColor = common.textColor2
    , nodeTextColorDisabled = common.textColorDisabled
    , loadingColor = common.primaryColor
    , dropMarkColor = common.primaryColor
    , lineColor = common.dividerColor
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , lineHeight = "1.5"
    , nodeHeight = "30px"
    , nodeWrapperPadding = "3px 0"
    , nodeBorderRadius = common.borderRadiusSmall
    , nodeColorHover = common.hoverColor
    , nodeColorPressed = common.pressedColor
    , nodeColorActive = "rgba(99, 226, 183, 0.15)"
    , arrowColor = common.textColor3
    , nodeTextColor = common.textColor2
    , nodeTextColorDisabled = common.textColorDisabled
    , loadingColor = common.primaryColor
    , dropMarkColor = common.primaryColor
    , lineColor = common.dividerColor
    }
