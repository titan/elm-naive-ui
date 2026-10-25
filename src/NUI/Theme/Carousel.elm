module NUI.Theme.Carousel exposing (Vars, vars)

{-| Theme variables for the **Carousel** component — the Elm counterpart of Naive UI's
`src/Carousel/styles/light.ts` & `dark.ts` cssr theme (selfVars). Carousel renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`dotSize` → `--n-dot-size`, `dotColor` → `--n-dot-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Carousel's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Carousel CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`dotSize` → `--n-dot-size`).
-}
type alias Vars =
    { dotSize : String
    , dotColor : String
    , dotColorActive : String
    , dotColorFocus : String
    , dotLineWidth : String
    , dotLineWidthActive : String
    , arrowColor : String
    }


{-| Resolve the Carousel variables for a theme — upstream `self(common)`: Light and Dark
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
    { dotSize = "8px"
    , dotColor = "rgba(255, 255, 255, .3)"
    , dotColorActive = "rgba(255, 255, 255, 1)"
    , dotColorFocus = "rgba(255, 255, 255, .5)"
    , dotLineWidth = "16px"
    , dotLineWidthActive = "24px"
    , arrowColor = "#eee"
    }


dark : Common -> Vars
dark common =
    { dotSize = "8px"
    , dotColor = "rgba(255, 255, 255, .3)"
    , dotColorActive = "rgba(255, 255, 255, 1)"
    , dotColorFocus = "rgba(255, 255, 255, .5)"
    , dotLineWidth = "16px"
    , dotLineWidthActive = "24px"
    , arrowColor = "#eee"
    }
