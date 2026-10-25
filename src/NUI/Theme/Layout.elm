module NUI.Theme.Layout exposing (Vars, vars)

{-| Theme variables for **Layout** (upstream `src/Layout/styles/light.ts` & `dark.ts`, cssr
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
    , textColorInverted : String
    , color : String
    , colorEmbedded : String
    , headerColor : String
    , headerColorInverted : String
    , footerColor : String
    , footerColorInverted : String
    , headerBorderColor : String
    , headerBorderColorInverted : String
    , footerBorderColor : String
    , footerBorderColorInverted : String
    , siderBorderColor : String
    , siderBorderColorInverted : String
    , siderColor : String
    , siderColorInverted : String
    , siderToggleButtonBorder : String
    , siderToggleButtonColor : String
    , siderToggleButtonIconColor : String
    , siderToggleButtonIconColorInverted : String
    , siderToggleBarColor : String
    , siderToggleBarColorHover : String
    , invertScrollbar : String
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
    , textColorInverted = "#FFF"
    , color = common.bodyColor
    , colorEmbedded = common.actionColor
    , headerColor = common.cardColor
    , headerColorInverted = common.invertedColor
    , footerColor = common.actionColor
    , footerColorInverted = common.invertedColor
    , headerBorderColor = common.dividerColor
    , headerBorderColorInverted = common.invertedColor
    , footerBorderColor = common.dividerColor
    , footerBorderColorInverted = common.invertedColor
    , siderBorderColor = common.dividerColor
    , siderBorderColorInverted = common.invertedColor
    , siderColor = common.cardColor
    , siderColorInverted = common.invertedColor
    , siderToggleButtonBorder = "1px solid rgb(239, 239, 245)"
    , siderToggleButtonColor = common.baseColor
    , siderToggleButtonIconColor = common.textColor2
    , siderToggleButtonIconColorInverted = common.textColor2
    , siderToggleBarColor = "rgba(191, 191, 191, 1)"
    , siderToggleBarColorHover = "rgba(153, 153, 153, 1)"
    , invertScrollbar = "true"
    }


dark : Common -> Vars
dark common =
    { textColor = common.textColor2
    , textColorInverted = common.textColor2
    , color = common.bodyColor
    , colorEmbedded = common.bodyColor
    , headerColor = common.cardColor
    , headerColorInverted = common.cardColor
    , footerColor = common.cardColor
    , footerColorInverted = common.cardColor
    , headerBorderColor = common.dividerColor
    , headerBorderColorInverted = common.dividerColor
    , footerBorderColor = common.dividerColor
    , footerBorderColorInverted = common.dividerColor
    , siderBorderColor = common.dividerColor
    , siderBorderColorInverted = common.dividerColor
    , siderColor = common.cardColor
    , siderColorInverted = common.cardColor
    , siderToggleButtonBorder = "1px solid transparent"
    , siderToggleButtonColor = common.popoverColor
    , siderToggleButtonIconColor = common.textColor2
    , siderToggleButtonIconColorInverted = common.textColor2
    , siderToggleBarColor = "rgba(64, 64, 67, 1)"
    , siderToggleBarColorHover = "rgba(88, 88, 91, 1)"
    , invertScrollbar = "false"
    }
