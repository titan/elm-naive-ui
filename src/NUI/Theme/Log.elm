module NUI.Theme.Log exposing (Vars, vars)

{-| Theme variables for the **Log** component — the Elm counterpart of Naive UI's
`src/Log/styles/light.ts` & `dark.ts` cssr theme (selfVars). Log renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`loaderFontSize` → `--n-loader-font-size`, `loaderTextColor` → `--n-loader-text-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Log's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Log CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`loaderFontSize` → `--n-loader-font-size`).
-}
type alias Vars =
    { loaderFontSize : String
    , loaderTextColor : String
    , loaderColor : String
    , loaderBorder : String
    , loadingColor : String
    }


{-| Resolve the Log variables for a theme — upstream `self(common)`: Light and Dark
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
    { loaderFontSize = common.fontSize
    , loaderTextColor = common.textColor2
    , loaderColor = common.modalColor
    , loaderBorder = "1px solid rgb(224, 224, 230)"
    , loadingColor = common.primaryColor
    }


dark : Common -> Vars
dark common =
    { loaderFontSize = common.fontSize
    , loaderTextColor = common.textColor2
    , loaderColor = common.inputColor
    , loaderBorder = "1px solid #0000"
    , loadingColor = common.primaryColor
    }
