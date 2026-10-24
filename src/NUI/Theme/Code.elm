module NUI.Theme.Code exposing (Vars, vars)

{-| Theme variables for the **Code** component — the Elm counterpart of Naive UI's
`src/Code/styles/light.ts` & `dark.ts` cssr theme (selfVars). Code renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`textColor` → `--n-text-color`, `fontSize` → `--n-font-size`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Code's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Code CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`textColor` → `--n-text-color`).

Collected by concern:

  - base typography: `textColor`, `fontSize`, `fontWeightStrong`
  - syntax palette: `mono3`, `hue1`, `hue2`, `hue3`, `hue4`, `hue5`, `hue52`, `hue6`, `hue62`
  - gutter: `lineNumberTextColor`

-}
type alias Vars =
    { textColor : String
    , fontSize : String
    , fontWeightStrong : String
    , mono3 : String
    , hue1 : String
    , hue2 : String
    , hue3 : String
    , hue4 : String
    , hue5 : String
    , hue52 : String
    , hue6 : String
    , hue62 : String
    , lineNumberTextColor : String
    }


{-| Resolve the Code variables for a theme — upstream `self(common)`: Light and Dark
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
    { textColor = common.textColor2
    , fontSize = common.fontSize
    , fontWeightStrong = common.fontWeightStrong
    , mono3 = "#a0a1a7"
    , hue1 = "#0184bb"
    , hue2 = "#4078f2"
    , hue3 = "#a626a4"
    , hue4 = "#50a14f"
    , hue5 = "#e45649"
    , hue52 = "#c91243"
    , hue6 = "#986801"
    , hue62 = "#c18401"
    , lineNumberTextColor = common.textColor3
    }


dark : Common -> Vars
dark common =
    { textColor = common.textColor2
    , fontSize = common.fontSize
    , fontWeightStrong = common.fontWeightStrong
    , mono3 = "#5c6370"
    , hue1 = "#56b6c2"
    , hue2 = "#61aeee"
    , hue3 = "#c678dd"
    , hue4 = "#98c379"
    , hue5 = "#e06c75"
    , hue52 = "#be5046"
    , hue6 = "#d19a66"
    , hue62 = "#e6c07b"
    , lineNumberTextColor = common.textColor3
    }
