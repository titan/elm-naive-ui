module NUI.Theme.Spin exposing (Vars, vars)

{-| Naive UI spin theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { fontSize : String
    , textColor : String
    , sizeTiny : String
    , sizeSmall : String
    , sizeMedium : String
    , sizeLarge : String
    , sizeHuge : String
    , color : String
    , opacitySpinning : String
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
    { fontSize = common.fontSize
    , textColor = common.primaryColor
    , sizeTiny = common.heightTiny
    , sizeSmall = common.heightSmall
    , sizeMedium = common.heightMedium
    , sizeLarge = common.heightLarge
    , sizeHuge = common.heightHuge
    , color = common.primaryColor
    , opacitySpinning = common.opacityDisabled
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , textColor = common.primaryColor
    , sizeTiny = common.heightTiny
    , sizeSmall = common.heightSmall
    , sizeMedium = common.heightMedium
    , sizeLarge = common.heightLarge
    , sizeHuge = common.heightHuge
    , color = common.primaryColor
    , opacitySpinning = common.opacityDisabled
    }
