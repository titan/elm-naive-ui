module NUI.Theme.InputNumber exposing (Vars, vars)

{-| Theme variables for **InputNumber** (upstream `src/input-number/styles/light.ts` & `dark.ts`, cssr
selfVars). Fields map 1:1 onto the component's `--n-*` custom properties
(kebab-case of the field name). `vars` resolves the light/dark palette from
`theme.mode` + `theme.common` — upstream's `self(common)`; override individual
fields to customise.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the InputNumber CSS consumes, as one record: the
disabled step-button icon colour (`iconColorDisabled` → `--n-icon-color-disabled`).
-}
type alias Vars =
    { iconColorDisabled : String
    }


{-| Resolve the InputNumber variables — the disabled step-button icon colour,
drawn from `theme.common.textColorDisabled` in both modes.
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
    { iconColorDisabled = common.textColorDisabled
    }


dark : Common -> Vars
dark common =
    { iconColorDisabled = common.textColorDisabled
    }
