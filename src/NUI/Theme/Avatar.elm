module NUI.Theme.Avatar exposing (Vars, vars)

{-| Theme variables for the **Avatar** component — the Elm counterpart of Naive UI's
`src/Avatar/styles/light.ts` & `dark.ts` cssr theme (selfVars). Avatar renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`borderRadius` → `--n-border-radius`, `fontSize` → `--n-font-size`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Avatar's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Avatar CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`borderRadius` → `--n-border-radius`).
-}
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


{-| Resolve the Avatar variables for a theme — upstream `self(common)`: Light and Dark
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
