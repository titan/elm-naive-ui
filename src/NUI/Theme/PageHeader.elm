module NUI.Theme.PageHeader exposing (Vars, vars)

{-| Theme variables for the **PageHeader** component — the Elm counterpart of Naive UI's
`src/PageHeader/styles/light.ts` & `dark.ts` cssr theme (selfVars). PageHeader renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`titleFontSize` → `--n-title-font-size`, `backSize` → `--n-back-size`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to PageHeader's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the PageHeader CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`titleFontSize` → `--n-title-font-size`).

Collected by concern:

  - typography: `titleFontSize`, `titleFontWeight`, `fontSize`, `titleTextColor`, `subtitleTextColor`
  - back button: `backSize`, `backColor`, `backColorHover`, `backColorPressed`

-}
type alias Vars =
    { titleFontSize : String
    , backSize : String
    , titleFontWeight : String
    , fontSize : String
    , titleTextColor : String
    , backColor : String
    , backColorHover : String
    , backColorPressed : String
    , subtitleTextColor : String
    }


{-| Resolve the PageHeader variables for a theme — upstream `self(common)`: Light and Dark
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
    { titleFontSize = "18px"
    , backSize = "22px"
    , titleFontWeight = common.fontWeightStrong
    , fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , backColor = common.textColor2
    , backColorHover = common.primaryColorHover
    , backColorPressed = common.primaryColorPressed
    , subtitleTextColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { titleFontSize = "18px"
    , backSize = "22px"
    , titleFontWeight = common.fontWeightStrong
    , fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , backColor = common.textColor2
    , backColorHover = common.primaryColorHover
    , backColorPressed = common.primaryColorPressed
    , subtitleTextColor = common.textColor3
    }
