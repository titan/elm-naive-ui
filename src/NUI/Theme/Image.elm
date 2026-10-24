module NUI.Theme.Image exposing (Vars, vars)

{-| Theme variables for the **Image** component — the Elm counterpart of Naive UI's
`src/Image/styles/light.ts` & `dark.ts` cssr theme (selfVars). Image renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`toolbarIconColor` → `--n-toolbar-icon-color`, `toolbarColor` → `--n-toolbar-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Image's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Image CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`toolbarIconColor` → `--n-toolbar-icon-color`).

Collected by concern:

  - preview toolbar chrome: `toolbarIconColor`, `toolbarColor`, `toolbarBoxShadow`, `toolbarBorderRadius`

-}
type alias Vars =
    { toolbarIconColor : String
    , toolbarColor : String
    , toolbarBoxShadow : String
    , toolbarBorderRadius : String
    }


{-| Resolve the Image variables for a theme — upstream `self(common)`: Light and Dark
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
    { toolbarIconColor = "rgba(255, 255, 255, .9)"
    , toolbarColor = "rgba(0, 0, 0, .35)"
    , toolbarBoxShadow = "none"
    , toolbarBorderRadius = "24px"
    }


dark : Common -> Vars
dark common =
    { toolbarIconColor = common.textColor2
    , toolbarColor = "rgba(0, 0, 0, .35)"
    , toolbarBoxShadow = "none"
    , toolbarBorderRadius = "24px"
    }
