module NUI.Theme.Empty exposing (Vars, vars)

{-| Theme variables for **Empty** (upstream `src/Empty/styles/light.ts` & `dark.ts`, cssr
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
    { iconSizeTiny : String
    , iconSizeSmall : String
    , iconSizeMedium : String
    , iconSizeLarge : String
    , iconSizeHuge : String
    , fontSizeTiny : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , textColor : String
    , iconColor : String
    , extraTextColor : String
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
    { iconSizeTiny = "28px"
    , iconSizeSmall = "34px"
    , iconSizeMedium = "40px"
    , iconSizeLarge = "46px"
    , iconSizeHuge = "52px"
    , fontSizeTiny = common.fontSizeTiny
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , fontSizeHuge = common.fontSizeHuge
    , textColor = common.textColorDisabled
    , iconColor = common.iconColor
    , extraTextColor = common.textColor2
    }


dark : Common -> Vars
dark common =
    { iconSizeTiny = "28px"
    , iconSizeSmall = "34px"
    , iconSizeMedium = "40px"
    , iconSizeLarge = "46px"
    , iconSizeHuge = "52px"
    , fontSizeTiny = common.fontSizeTiny
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , fontSizeHuge = common.fontSizeHuge
    , textColor = common.textColorDisabled
    , iconColor = common.iconColor
    , extraTextColor = common.textColor2
    }
