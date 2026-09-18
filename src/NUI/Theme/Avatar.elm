module NUI.Theme.Avatar exposing (Vars, vars)


{-| Naive UI avatar theme variables.
-}


import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { borderRadius : String
    , fontSize : String
    , border : String
    , heightTiny : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , heightHuge : String
    , color : String
    , colorModal : String
    , colorPopover : String
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
    { borderRadius = common.borderRadius
    , fontSize = common.fontSize
    , border = "2px solid #fff"
    , heightTiny = common.heightTiny
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , heightHuge = common.heightHuge
    , color = "rgba(204, 204, 204, 1)"
    , colorModal = "rgba(204, 204, 204, 1)"
    , colorPopover = "rgba(204, 204, 204, 1)"
    }


dark : Common -> Vars
dark common =
    { borderRadius = common.borderRadius
    , fontSize = common.fontSize
    , border = "2px solid rgb(24, 24, 28)"
    , heightTiny = common.heightTiny
    , heightSmall = common.heightSmall
    , heightMedium = common.heightMedium
    , heightLarge = common.heightLarge
    , heightHuge = common.heightHuge
    , color = "rgba(66, 66, 69, 1)"
    , colorModal = "rgba(82, 82, 87, 1)"
    , colorPopover = "rgba(105, 105, 110, 1)"
    }
