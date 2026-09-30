module NUI.Theme.Log exposing (Vars, vars)

{-| Naive UI log theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { loaderFontSize : String
    , loaderTextColor : String
    , loaderColor : String
    , loaderBorder : String
    , loadingColor : String
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
    { loaderFontSize = common.fontSize
    , loaderTextColor = common.textColor2
    , loaderColor = common.modalColor
    , loaderBorder = "1px solid rgb(224, 224, 230)"
    , loadingColor = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { loaderFontSize = common.fontSize
    , loaderTextColor = common.textColor2
    , loaderColor = common.inputColor
    , loaderBorder = "1px solid #0000"
    , loadingColor = common.primaryColor
    }
