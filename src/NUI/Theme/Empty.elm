module NUI.Theme.Empty exposing (Vars, vars)

{-| Theme variables for the **Empty** component — the Elm counterpart of Naive UI's
`src/Empty/styles/light.ts` & `dark.ts` cssr theme (selfVars). Empty renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`iconSizeTiny` → `--n-icon-size-tiny`, `iconSizeSmall` → `--n-icon-size-small`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Empty's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Empty CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`iconSizeTiny` → `--n-icon-size-tiny`).
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


{-| Resolve the Empty variables for a theme — upstream `self(common)`: Light and Dark
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
