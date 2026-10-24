module NUI.Theme.Popconfirm exposing (Vars, vars)

{-| Theme variables for the **Popconfirm** component — the Elm counterpart of Naive UI's
`src/Popconfirm/styles/light.ts` & `dark.ts` cssr theme (selfVars). Popconfirm renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`iconSize` → `--n-icon-size`, `fontSize` → `--n-font-size`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Popconfirm's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Popconfirm CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`iconSize` → `--n-icon-size`).

Collected by concern:

  - typography & icon: `iconSize`, `fontSize`, `iconColor`

-}
type alias Vars =
    { iconSize : String
    , fontSize : String
    , iconColor : String
    }


{-| Resolve the Popconfirm variables for a theme — upstream `self(common)`: Light and Dark
modes each get their own palette, values drawn from `theme.common`.
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
    { iconSize = "22px"
    , fontSize = common.fontSize
    , iconColor = common.warningColor
    }


dark : Common -> Vars
dark common =
    { iconSize = "22px"
    , fontSize = common.fontSize
    , iconColor = common.warningColor
    }
