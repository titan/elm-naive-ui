module NUI.Theme.TreeSelect exposing (Vars, vars)

{-| Theme variables for **TreeSelect** (upstream `src/TreeSelect/styles/light.ts` & `dark.ts`, cssr
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
    { menuPadding : String
    , menuColor : String
    , menuBoxShadow : String
    , menuBorderRadius : String
    , menuHeight : String
    , actionDividerColor : String
    , actionTextColor : String
    , actionPadding : String
    , headerDividerColor : String
    , headerTextColor : String
    , headerPadding : String
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
    { menuPadding = "4px"
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuBorderRadius = common.borderRadius
    , menuHeight = "calc(34px * 7.6)"
    , actionDividerColor = common.dividerColor
    , actionTextColor = common.textColor2
    , actionPadding = "8px 12px"
    , headerDividerColor = common.dividerColor
    , headerTextColor = common.textColor2
    , headerPadding = "8px 12px"
    }


dark : Common -> Vars
dark common =
    { menuPadding = "4px"
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuBorderRadius = common.borderRadius
    , menuHeight = "calc(34px * 7.6)"
    , actionDividerColor = common.dividerColor
    , actionTextColor = common.textColor2
    , actionPadding = "8px 12px"
    , headerDividerColor = common.dividerColor
    , headerTextColor = common.textColor2
    , headerPadding = "8px 12px"
    }
