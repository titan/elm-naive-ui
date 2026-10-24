module NUI.Theme.InputNumber exposing (Vars, vars)

{-| Theme variables for the **InputNumber** component — the Elm counterpart of
Naive UI's `src/input-number/styles/light.ts` & `dark.ts` cssr theme (selfVars).
InputNumber renders with Naive UI's original CSS, so the single record field here
is emitted as the `--n-icon-color-disabled` custom property on the component root
(upstream kebab-case mapping, `iconColorDisabled` → `--n-icon-color-disabled`).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode`
(Light/Dark) and derives the disabled step-button icon colour from
`theme.common.textColorDisabled` (see `NUI.Theme.Common`).

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


{-| Resolve the InputNumber theme variables — upstream's `self(common)`
counterpart. Switches on `theme.mode`; both palettes derive the disabled icon
colour from `theme.common.textColorDisabled` (identical in the stock palettes).
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
