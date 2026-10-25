module NUI.Theme.Collapse exposing (Vars, vars)

{-| Theme variables for the **Collapse** component — the Elm counterpart of Naive UI's
`src/Collapse/styles/light.ts` & `dark.ts` cssr theme (selfVars). Collapse renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`titleFontSize` → `--n-title-font-size`, `titleFontWeight` → `--n-title-font-weight`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Collapse's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Collapse CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`titleFontSize` → `--n-title-font-size`).
-}
type alias Vars =
    { titleFontSize : String
    , titleFontWeight : String
    , dividerColor : String
    , titleTextColor : String
    , titleTextColorDisabled : String
    , fontSize : String
    , textColor : String
    , arrowColor : String
    , arrowColorDisabled : String
    , itemMargin : String
    , titlePadding : String
    }


{-| Resolve the Collapse variables for a theme — upstream `self(common)`: Light and Dark
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
    { titleFontSize = common.fontSize
    , titleFontWeight = common.fontWeight
    , dividerColor = common.dividerColor
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , fontSize = common.fontSize
    , textColor = common.textColor2
    , arrowColor = common.textColor2
    , arrowColorDisabled = common.textColorDisabled
    , itemMargin = "16px 0 0 0"
    , titlePadding = "16px 0 0 0"
    }


dark : Common -> Vars
dark common =
    { titleFontSize = common.fontSize
    , titleFontWeight = common.fontWeight
    , dividerColor = common.dividerColor
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , fontSize = common.fontSize
    , textColor = common.textColor2
    , arrowColor = common.textColor2
    , arrowColorDisabled = common.textColorDisabled
    , itemMargin = "16px 0 0 0"
    , titlePadding = "16px 0 0 0"
    }
