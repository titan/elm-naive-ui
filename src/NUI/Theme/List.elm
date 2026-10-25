module NUI.Theme.List exposing (Vars, vars)

{-| Theme variables for **List** (upstream `src/List/styles/light.ts` & `dark.ts`, cssr
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
    , color : String
    , colorHover : String
    , colorModal : String
    , colorHoverModal : String
    , colorPopover : String
    , colorHoverPopover : String
    , borderColor : String
    , borderColorModal : String
    , borderColorPopover : String
    , borderRadius : String
    , fontSize : String
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
    , color = common.cardColor
    , colorHover = common.hoverColor
    , colorModal = common.modalColor
    , colorHoverModal = "rgba(243, 243, 245, 1)"
    , colorPopover = common.popoverColor
    , colorHoverPopover = "rgba(243, 243, 245, 1)"
    , borderColor = common.dividerColor
    , borderColorModal = "rgba(239, 239, 245, 1)"
    , borderColorPopover = "rgba(239, 239, 245, 1)"
    , borderRadius = common.borderRadius
    , fontSize = common.fontSize
    }


dark : Common -> Vars
dark common =
    { textColor = common.textColor2
    , color = common.cardColor
    , colorHover = common.hoverColor
    , colorModal = common.modalColor
    , colorHoverModal = "rgba(63, 63, 68, 1)"
    , colorPopover = common.popoverColor
    , colorHoverPopover = "rgba(88, 88, 94, 1)"
    , borderColor = common.dividerColor
    , borderColorModal = "rgba(63, 63, 68, 1)"
    , borderColorPopover = "rgba(88, 88, 94, 1)"
    , borderRadius = common.borderRadius
    , fontSize = common.fontSize
    }
