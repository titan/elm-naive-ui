module NUI.Theme.Collapse exposing (Vars, vars)

{-| Theme variables for **Collapse** (upstream `src/Collapse/styles/light.ts` & `dark.ts`, cssr
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
    , titleFontWeight : String
    , dividerColor : String
    , titleTextColor : String
    , titleTextColorDisabled : String
    , fontSize : String
    , textColor : String
    , arrowColor : String
    , arrowColorDisabled : String
    , itemMargin : String
    , titlePadding : String
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
    { titleFontSize = common.fontSize
    , titleFontWeight = common.fontWeight
    , dividerColor = common.dividerColor
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , fontSize = common.fontSize
    , textColor = common.textColor2
    , arrowColor = common.textColor2
    , arrowColorDisabled = common.textColorDisabled
    , itemMargin = "16px 0 0 0"
    , titlePadding = "16px 0 0 0"
    }


dark : Common -> Vars
dark common =
    { titleFontSize = common.fontSize
    , titleFontWeight = common.fontWeight
    , dividerColor = common.dividerColor
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , fontSize = common.fontSize
    , textColor = common.textColor2
    , arrowColor = common.textColor2
    , arrowColorDisabled = common.textColorDisabled
    , itemMargin = "16px 0 0 0"
    , titlePadding = "16px 0 0 0"
    }
