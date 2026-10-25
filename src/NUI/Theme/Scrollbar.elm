module NUI.Theme.Scrollbar exposing (Vars, vars)

{-| Theme variables for the **Scrollbar** component — the Elm counterpart of Naive UI's
`src/_internal/scrollbar/styles/light.ts` & `dark.ts` cssr theme (selfVars). Scrollbar renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`railInsetHorizontalBottom` → `--n-rail-inset-horizontal-bottom`, `railInsetHorizontalTop` → `--n-rail-inset-horizontal-top`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Scrollbar's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Scrollbar CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`railInsetHorizontalBottom` → `--n-rail-inset-horizontal-bottom`).
-}
type alias Vars =
    { railInsetHorizontalBottom : String
    , railInsetHorizontalTop : String
    , railInsetVerticalRight : String
    , railInsetVerticalLeft : String
    , railColor : String
    , height : String
    , width : String
    , borderRadius : String
    , color : String
    , colorHover : String
    }


{-| Resolve the Scrollbar variables for a theme — upstream `self(common)`: Light and Dark
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
    { railInsetHorizontalBottom = "auto 2px 4px 2px"
    , railInsetHorizontalTop = "4px 2px auto 2px"
    , railInsetVerticalRight = "2px 4px 2px auto"
    , railInsetVerticalLeft = "2px auto 2px 4px"
    , railColor = "transparent"
    , height = common.scrollbarHeight
    , width = common.scrollbarWidth
    , borderRadius = common.scrollbarBorderRadius
    , color = common.scrollbarColor
    , colorHover = common.scrollbarColorHover
    }


dark : Common -> Vars
dark common =
    { railInsetHorizontalBottom = "auto 2px 4px 2px"
    , railInsetHorizontalTop = "4px 2px auto 2px"
    , railInsetVerticalRight = "2px 4px 2px auto"
    , railInsetVerticalLeft = "2px auto 2px 4px"
    , railColor = "transparent"
    , height = common.scrollbarHeight
    , width = common.scrollbarWidth
    , borderRadius = common.scrollbarBorderRadius
    , color = common.scrollbarColor
    , colorHover = common.scrollbarColorHover
    }
