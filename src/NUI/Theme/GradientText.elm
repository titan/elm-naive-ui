module NUI.Theme.GradientText exposing (Vars, vars)

{-| Theme variables for the **GradientText** component — the Elm counterpart of Naive UI's
`src/GradientText/styles/light.ts` & `dark.ts` cssr theme (selfVars). GradientText renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`fontWeight` → `--n-font-weight`, `rotate` → `--n-rotate`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to GradientText's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the GradientText CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`fontWeight` → `--n-font-weight`).
-}
type alias Vars =
    { fontWeight : String
    , rotate : String
    , colorStartPrimary : String
    , colorEndPrimary : String
    , colorStartInfo : String
    , colorEndInfo : String
    , colorStartWarning : String
    , colorEndWarning : String
    , colorStartError : String
    , colorEndError : String
    , colorStartSuccess : String
    , colorEndSuccess : String
    }


{-| Resolve the GradientText variables for a theme — upstream `self(common)`: Light and Dark
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
    { fontWeight = common.fontWeightStrong
    , rotate = "252deg"
    , colorStartPrimary = "rgba(24, 160, 88, 0.6)"
    , colorEndPrimary = common.primaryColor
    , colorStartInfo = "rgba(32, 128, 240, 0.6)"
    , colorEndInfo = common.infoColor
    , colorStartWarning = "rgba(240, 160, 32, 0.6)"
    , colorEndWarning = common.warningColor
    , colorStartError = "rgba(208, 48, 80, 0.6)"
    , colorEndError = common.errorColor
    , colorStartSuccess = "rgba(24, 160, 88, 0.6)"
    , colorEndSuccess = common.successColor
    }


dark : Common -> Vars
dark common =
    { fontWeight = common.fontWeightStrong
    , rotate = "252deg"
    , colorStartPrimary = common.primaryColor
    , colorEndPrimary = common.primaryColorSuppl
    , colorStartInfo = common.infoColor
    , colorEndInfo = common.infoColorSuppl
    , colorStartWarning = common.warningColor
    , colorEndWarning = common.warningColorSuppl
    , colorStartError = common.errorColor
    , colorEndError = common.errorColorSuppl
    , colorStartSuccess = common.successColor
    , colorEndSuccess = common.successColorSuppl
    }
