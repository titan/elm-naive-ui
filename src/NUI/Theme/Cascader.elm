module NUI.Theme.Cascader exposing (Vars, vars)

{-| Theme variables for **Cascader** (upstream `src/Cascader/styles/light.ts` & `dark.ts`, cssr
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
    { menuBorderRadius : String
    , menuColor : String
    , menuBoxShadow : String
    , menuDividerColor : String
    , menuHeight : String
    , optionArrowColor : String
    , optionHeight : String
    , optionFontSize : String
    , optionColorHover : String
    , optionTextColor : String
    , optionTextColorActive : String
    , optionTextColorDisabled : String
    , optionCheckMarkColor : String
    , loadingColor : String
    , columnWidth : String
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
    { menuBorderRadius = common.borderRadius
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuDividerColor = common.dividerColor
    , menuHeight = "calc(var(--n-option-height) * 6.6)"
    , optionArrowColor = common.textColor3
    , optionHeight = common.heightMedium
    , optionFontSize = common.fontSizeMedium
    , optionColorHover = common.hoverColor
    , optionTextColor = common.textColor2
    , optionTextColorActive = common.primaryColor
    , optionTextColorDisabled = common.textColorDisabled
    , optionCheckMarkColor = common.primaryColor
    , loadingColor = common.primaryColor
    , columnWidth = "180px"
    }


dark : Common -> Vars
dark common =
    { menuBorderRadius = common.borderRadius
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuDividerColor = common.dividerColor
    , menuHeight = "calc(var(--n-option-height) * 6.6)"
    , optionArrowColor = common.textColor3
    , optionHeight = common.heightMedium
    , optionFontSize = common.fontSizeMedium
    , optionColorHover = common.hoverColor
    , optionTextColor = common.textColor2
    , optionTextColorActive = common.primaryColor
    , optionTextColorDisabled = common.textColorDisabled
    , optionCheckMarkColor = common.primaryColor
    , loadingColor = common.primaryColor
    , columnWidth = "180px"
    }
