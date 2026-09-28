module NUI.Theme.TreeSelect exposing (Vars, vars)

{-| Naive UI tree-select theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


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
