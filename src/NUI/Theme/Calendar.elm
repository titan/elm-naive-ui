module NUI.Theme.Calendar exposing (Vars, vars)

{-| Theme variables for **Calendar** (upstream `src/Calendar/styles/light.ts` & `dark.ts`, cssr
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
    , borderRadius : String
    , borderColor : String
    , borderColorModal : String
    , borderColorPopover : String
    , textColor : String
    , titleFontWeight : String
    , titleTextColor : String
    , dayTextColor : String
    , fontSize : String
    , lineHeight : String
    , dateColorCurrent : String
    , dateTextColorCurrent : String
    , cellColorHover : String
    , cellColorHoverModal : String
    , cellColorHoverPopover : String
    , cellColor : String
    , cellColorModal : String
    , cellColorPopover : String
    , barColor : String
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
    { titleFontSize = "22px"
    , borderRadius = common.borderRadius
    , borderColor = "rgba(239, 239, 245, 1)"
    , borderColorModal = "rgba(239, 239, 245, 1)"
    , borderColorPopover = "rgba(239, 239, 245, 1)"
    , textColor = common.textColor2
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , dayTextColor = common.textColorDisabled
    , fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , dateColorCurrent = common.primaryColor
    , dateTextColorCurrent = common.baseColor
    , cellColorHover = "rgba(243, 243, 245, 1)"
    , cellColorHoverModal = "rgba(243, 243, 245, 1)"
    , cellColorHoverPopover = "rgba(243, 243, 245, 1)"
    , cellColor = common.cardColor
    , cellColorModal = common.modalColor
    , cellColorPopover = common.popoverColor
    , barColor = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { titleFontSize = "22px"
    , borderRadius = common.borderRadius
    , borderColor = "rgba(45, 45, 48, 1)"
    , borderColorModal = "rgba(63, 63, 68, 1)"
    , borderColorPopover = "rgba(88, 88, 94, 1)"
    , textColor = common.textColor2
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , dayTextColor = common.textColorDisabled
    , fontSize = common.fontSize
    , lineHeight = common.lineHeight
    , dateColorCurrent = common.primaryColor
    , dateTextColorCurrent = common.baseColor
    , cellColorHover = "rgba(45, 45, 48, 1)"
    , cellColorHoverModal = "rgba(63, 63, 68, 1)"
    , cellColorHoverPopover = "rgba(88, 88, 94, 1)"
    , cellColor = common.cardColor
    , cellColorModal = common.modalColor
    , cellColorPopover = common.popoverColor
    , barColor = common.primaryColor
    }
