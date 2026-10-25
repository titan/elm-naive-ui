module NUI.Theme.Statistic exposing (Vars, vars)

{-| Theme variables for **Statistic** (upstream `src/Statistic/styles/light.ts` & `dark.ts`, cssr
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
    { labelFontSize : String
    , labelFontWeight : String
    , valueFontWeight : String
    , valueFontSize : String
    , labelTextColor : String
    , valuePrefixTextColor : String
    , valueSuffixTextColor : String
    , valueTextColor : String
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
