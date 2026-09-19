module NUI.Theme.List exposing (Vars, vars)

{-| Naive UI list theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


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
    , color = common.tableColor
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
