module NUI.Theme.Statistic exposing (Vars, vars)

{-| Naive UI statistic theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { labelFontSize : String
    , labelFontWeight : String
    , valueFontWeight : String
    , valueFontSize : String
    , labelTextColor : String
    , valuePrefixTextColor : String
    , valueSuffixTextColor : String
    , valueTextColor : String
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
    { labelFontSize = common.fontSize
    , labelFontWeight = common.fontWeight
    , valueFontWeight = common.fontWeight
    , valueFontSize = "24px"
    , labelTextColor = common.textColor3
    , valuePrefixTextColor = common.textColor2
    , valueSuffixTextColor = common.textColor2
    , valueTextColor = common.textColor2
    }


dark : Common -> Vars
dark common =
    { labelFontSize = common.fontSize
    , labelFontWeight = common.fontWeight
    , valueFontWeight = common.fontWeight
    , valueFontSize = "24px"
    , labelTextColor = common.textColor3
    , valuePrefixTextColor = common.textColor2
    , valueSuffixTextColor = common.textColor2
    , valueTextColor = common.textColor2
    }
