module NUI.Theme.Thing exposing (Vars, vars)

{-| Theme variables for the **Thing** component — the Elm counterpart of Naive UI's
`src/Thing/styles/light.ts` & `dark.ts` cssr theme (selfVars). Thing renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`fontSize` → `--n-font-size`, `titleTextColor` → `--n-title-text-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Thing's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Thing CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`fontSize` → `--n-font-size`).

Collected by concern:

  - typography (sizes, weights, title & body text): `fontSize`, `titleTextColor`, `textColor`, `titleFontWeight`

-}
type alias Vars =
    { fontSize : String
    , titleTextColor : String
    , textColor : String
    , titleFontWeight : String
    }


{-| Resolve the Thing variables for a theme — upstream `self(common)`: Light and Dark
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
    { fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , titleFontWeight = common.fontWeightStrong
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , titleFontWeight = common.fontWeightStrong
    }
