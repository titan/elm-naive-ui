module NUI.Theme.Anchor exposing (Vars, vars)

{-| Theme variables for the **Anchor** component — the Elm counterpart of Naive UI's
`src/Anchor/styles/light.ts` & `dark.ts` cssr theme (selfVars). Anchor renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`linkFontSize` → `--n-link-font-size`, `linkPadding` → `--n-link-padding`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Anchor's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Anchor CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`linkFontSize` → `--n-link-font-size`).
-}
type alias Vars =
    { linkFontSize : String
    , linkPadding : String
    , railWidth : String
    , borderRadius : String
    , railColor : String
    , railColorActive : String
    , linkColor : String
    , linkTextColor : String
    , linkTextColorHover : String
    , linkTextColorPressed : String
    , linkTextColorActive : String
    }


{-| Resolve the Anchor variables for a theme — upstream `self(common)`: Light and Dark
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
    { linkFontSize = "13px"
    , linkPadding = "0 0 0 16px"
    , railWidth = "4px"
    , borderRadius = common.borderRadius
    , railColor = common.railColor
    , railColorActive = common.primaryColor
    , linkColor = "rgba(24, 160, 88, 0.15)"
    , linkTextColor = common.textColor2
    , linkTextColorHover = common.primaryColorHover
    , linkTextColorPressed = common.primaryColorPressed
    , linkTextColorActive = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { linkFontSize = "13px"
    , linkPadding = "0 0 0 16px"
    , railWidth = "4px"
    , borderRadius = common.borderRadius
    , railColor = common.railColor
    , railColorActive = common.primaryColor
    , linkColor = "rgba(99, 226, 183, 0.15)"
    , linkTextColor = common.textColor2
    , linkTextColorHover = common.primaryColorHover
    , linkTextColorPressed = common.primaryColorPressed
    , linkTextColorActive = common.primaryColor
    }
