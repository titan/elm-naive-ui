module NUI.Theme.Menu exposing (Vars, vars)

{-| Theme variables for the **Menu** component — the Elm counterpart of Naive UI's
`src/Menu/styles/light.ts` & `dark.ts` cssr theme (selfVars). Menu renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`borderRadius` → `--n-border-radius`, `color` → `--n-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Menu's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Menu CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`borderRadius` → `--n-border-radius`).
-}
type alias Vars =
    { borderRadius : String
    , color : String
    , groupTextColor : String
    , itemColorHover : String
    , itemColorActive : String
    , itemColorActiveHover : String
    , itemColorActiveCollapsed : String
    , itemTextColor : String
    , itemTextColorHover : String
    , itemTextColorActive : String
    , itemTextColorActiveHover : String
    , itemTextColorChildActive : String
    , itemTextColorChildActiveHover : String
    , itemTextColorHorizontal : String
    , itemTextColorHoverHorizontal : String
    , itemTextColorActiveHorizontal : String
    , itemTextColorActiveHoverHorizontal : String
    , itemTextColorChildActiveHorizontal : String
    , itemTextColorChildActiveHoverHorizontal : String
    , itemIconColor : String
    , itemIconColorHover : String
    , itemIconColorActive : String
    , itemIconColorActiveHover : String
    , itemIconColorChildActive : String
    , itemIconColorChildActiveHover : String
    , itemIconColorCollapsed : String
    , itemIconColorHorizontal : String
    , itemIconColorHoverHorizontal : String
    , itemIconColorActiveHorizontal : String
    , itemIconColorActiveHoverHorizontal : String
    , itemIconColorChildActiveHorizontal : String
    , itemIconColorChildActiveHoverHorizontal : String
    , itemHeight : String
    , arrowColor : String
    , arrowColorHover : String
    , arrowColorActive : String
    , arrowColorActiveHover : String
    , arrowColorChildActive : String
    , arrowColorChildActiveHover : String
    , colorInverted : String
    , borderColorHorizontal : String
    , fontSize : String
    , dividerColor : String
    , itemColorHoverInverted : String
    , itemColorActiveInverted : String
    , itemColorActiveHoverInverted : String
    , itemColorActiveCollapsedInverted : String
    , itemTextColorInverted : String
    , itemTextColorHoverInverted : String
    , itemTextColorChildActiveInverted : String
    , itemTextColorChildActiveHoverInverted : String
    , itemTextColorActiveInverted : String
    , itemTextColorActiveHoverInverted : String
    , itemTextColorHorizontalInverted : String
    , itemTextColorHoverHorizontalInverted : String
    , itemTextColorChildActiveHorizontalInverted : String
    , itemTextColorChildActiveHoverHorizontalInverted : String
    , itemTextColorActiveHorizontalInverted : String
    , itemTextColorActiveHoverHorizontalInverted : String
    , itemIconColorInverted : String
    , itemIconColorHoverInverted : String
    , itemIconColorActiveInverted : String
    , itemIconColorActiveHoverInverted : String
    , itemIconColorChildActiveInverted : String
    , itemIconColorChildActiveHoverInverted : String
    , itemIconColorCollapsedInverted : String
    , itemIconColorHorizontalInverted : String
    , itemIconColorHoverHorizontalInverted : String
    , itemIconColorActiveHorizontalInverted : String
    , itemIconColorActiveHoverHorizontalInverted : String
    , itemIconColorChildActiveHorizontalInverted : String
    , itemIconColorChildActiveHoverHorizontalInverted : String
    , arrowColorInverted : String
    , arrowColorHoverInverted : String
    , arrowColorActiveInverted : String
    , arrowColorActiveHoverInverted : String
    , arrowColorChildActiveInverted : String
    , arrowColorChildActiveHoverInverted : String
    , groupTextColorInverted : String
    }


{-| Resolve the Menu variables for a theme — upstream `self(common)`: Light and Dark
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
    { borderRadius = common.borderRadius
    , color = "#0000"
    , groupTextColor = common.textColor3
    , itemColorHover = common.hoverColor
    , itemColorActive = "rgba(24, 160, 88, 0.1)"
    , itemColorActiveHover = "rgba(24, 160, 88, 0.1)"
    , itemColorActiveCollapsed = "rgba(24, 160, 88, 0.1)"
    , itemTextColor = common.textColor2
    , itemTextColorHover = common.textColor2
    , itemTextColorActive = common.primaryColor
    , itemTextColorActiveHover = common.primaryColor
    , itemTextColorChildActive = common.primaryColor
    , itemTextColorChildActiveHover = common.primaryColor
    , itemTextColorHorizontal = common.textColor2
    , itemTextColorHoverHorizontal = common.primaryColorHover
    , itemTextColorActiveHorizontal = common.primaryColor
    , itemTextColorActiveHoverHorizontal = common.primaryColor
    , itemTextColorChildActiveHorizontal = common.primaryColor
    , itemTextColorChildActiveHoverHorizontal = common.primaryColor
    , itemIconColor = common.textColor1
    , itemIconColorHover = common.textColor1
    , itemIconColorActive = common.primaryColor
    , itemIconColorActiveHover = common.primaryColor
    , itemIconColorChildActive = common.primaryColor
    , itemIconColorChildActiveHover = common.primaryColor
    , itemIconColorCollapsed = common.textColor1
    , itemIconColorHorizontal = common.textColor1
    , itemIconColorHoverHorizontal = common.primaryColorHover
    , itemIconColorActiveHorizontal = common.primaryColor
    , itemIconColorActiveHoverHorizontal = common.primaryColor
    , itemIconColorChildActiveHorizontal = common.primaryColor
    , itemIconColorChildActiveHoverHorizontal = common.primaryColor
    , itemHeight = "42px"
    , arrowColor = common.textColor2
    , arrowColorHover = common.textColor2
    , arrowColorActive = common.primaryColor
    , arrowColorActiveHover = common.primaryColor
    , arrowColorChildActive = common.primaryColor
    , arrowColorChildActiveHover = common.primaryColor
    , colorInverted = "#0000"
    , borderColorHorizontal = "#0000"
    , fontSize = common.fontSize
    , dividerColor = common.dividerColor
    , itemColorHoverInverted = "#0000"
    , itemColorActiveInverted = "#18a058"
    , itemColorActiveHoverInverted = "#18a058"
    , itemColorActiveCollapsedInverted = "#18a058"
    , itemTextColorInverted = "#BBB"
    , itemTextColorHoverInverted = "#FFF"
    , itemTextColorChildActiveInverted = "#FFF"
    , itemTextColorChildActiveHoverInverted = "#FFF"
    , itemTextColorActiveInverted = "#FFF"
    , itemTextColorActiveHoverInverted = "#FFF"
    , itemTextColorHorizontalInverted = "#BBB"
    , itemTextColorHoverHorizontalInverted = "#FFF"
    , itemTextColorChildActiveHorizontalInverted = "#FFF"
    , itemTextColorChildActiveHoverHorizontalInverted = "#FFF"
    , itemTextColorActiveHorizontalInverted = "#FFF"
    , itemTextColorActiveHoverHorizontalInverted = "#FFF"
    , itemIconColorInverted = "#BBB"
    , itemIconColorHoverInverted = "#FFF"
    , itemIconColorActiveInverted = "#FFF"
    , itemIconColorActiveHoverInverted = "#FFF"
    , itemIconColorChildActiveInverted = "#FFF"
    , itemIconColorChildActiveHoverInverted = "#FFF"
    , itemIconColorCollapsedInverted = "#BBB"
    , itemIconColorHorizontalInverted = "#BBB"
    , itemIconColorHoverHorizontalInverted = "#FFF"
    , itemIconColorActiveHorizontalInverted = "#FFF"
    , itemIconColorActiveHoverHorizontalInverted = "#FFF"
    , itemIconColorChildActiveHorizontalInverted = "#FFF"
    , itemIconColorChildActiveHoverHorizontalInverted = "#FFF"
    , arrowColorInverted = "#BBB"
    , arrowColorHoverInverted = "#FFF"
    , arrowColorActiveInverted = "#FFF"
    , arrowColorActiveHoverInverted = "#FFF"
    , arrowColorChildActiveInverted = "#FFF"
    , arrowColorChildActiveHoverInverted = "#FFF"
    , groupTextColorInverted = "#AAA"
    }


dark : Common -> Vars
dark common =
    { borderRadius = common.borderRadius
    , color = "#0000"
    , groupTextColor = common.textColor3
    , itemColorHover = common.hoverColor
    , itemColorActive = "rgba(99, 226, 183, 0.15)"
    , itemColorActiveHover = "rgba(99, 226, 183, 0.15)"
    , itemColorActiveCollapsed = "rgba(99, 226, 183, 0.15)"
    , itemTextColor = common.textColor2
    , itemTextColorHover = common.textColor2
    , itemTextColorActive = common.primaryColor
    , itemTextColorActiveHover = common.primaryColor
    , itemTextColorChildActive = common.primaryColor
    , itemTextColorChildActiveHover = common.primaryColor
    , itemTextColorHorizontal = common.textColor2
    , itemTextColorHoverHorizontal = common.primaryColorHover
    , itemTextColorActiveHorizontal = common.primaryColor
    , itemTextColorActiveHoverHorizontal = common.primaryColor
    , itemTextColorChildActiveHorizontal = common.primaryColor
    , itemTextColorChildActiveHoverHorizontal = common.primaryColor
    , itemIconColor = common.textColor1
    , itemIconColorHover = common.textColor1
    , itemIconColorActive = common.primaryColor
    , itemIconColorActiveHover = common.primaryColor
    , itemIconColorChildActive = common.primaryColor
    , itemIconColorChildActiveHover = common.primaryColor
    , itemIconColorCollapsed = common.textColor1
    , itemIconColorHorizontal = common.textColor1
    , itemIconColorHoverHorizontal = common.primaryColorHover
    , itemIconColorActiveHorizontal = common.primaryColor
    , itemIconColorActiveHoverHorizontal = common.primaryColor
    , itemIconColorChildActiveHorizontal = common.primaryColor
    , itemIconColorChildActiveHoverHorizontal = common.primaryColor
    , itemHeight = "42px"
    , arrowColor = common.textColor2
    , arrowColorHover = common.textColor2
    , arrowColorActive = common.primaryColor
    , arrowColorActiveHover = common.primaryColor
    , arrowColorChildActive = common.primaryColor
    , arrowColorChildActiveHover = common.primaryColor
    , colorInverted = "#0000"
    , borderColorHorizontal = "#0000"
    , fontSize = common.fontSize
    , dividerColor = common.dividerColor
    , itemColorHoverInverted = "#0000"
    , itemColorActiveInverted = common.primaryColorSuppl
    , itemColorActiveHoverInverted = common.primaryColorSuppl
    , itemColorActiveCollapsedInverted = common.primaryColorSuppl
    , itemTextColorInverted = "#BBB"
    , itemTextColorHoverInverted = "#FFF"
    , itemTextColorChildActiveInverted = "#FFF"
    , itemTextColorChildActiveHoverInverted = "#FFF"
    , itemTextColorActiveInverted = "#FFF"
    , itemTextColorActiveHoverInverted = "#FFF"
    , itemTextColorHorizontalInverted = "#BBB"
    , itemTextColorHoverHorizontalInverted = "#FFF"
    , itemTextColorChildActiveHorizontalInverted = "#FFF"
    , itemTextColorChildActiveHoverHorizontalInverted = "#FFF"
    , itemTextColorActiveHorizontalInverted = "#FFF"
    , itemTextColorActiveHoverHorizontalInverted = "#FFF"
    , itemIconColorInverted = "#BBB"
    , itemIconColorHoverInverted = "#FFF"
    , itemIconColorActiveInverted = "#FFF"
    , itemIconColorActiveHoverInverted = "#FFF"
    , itemIconColorChildActiveInverted = "#FFF"
    , itemIconColorChildActiveHoverInverted = "#FFF"
    , itemIconColorCollapsedInverted = "#BBB"
    , itemIconColorHorizontalInverted = "#BBB"
    , itemIconColorHoverHorizontalInverted = "#FFF"
    , itemIconColorActiveHorizontalInverted = "#FFF"
    , itemIconColorActiveHoverHorizontalInverted = "#FFF"
    , itemIconColorChildActiveHorizontalInverted = "#FFF"
    , itemIconColorChildActiveHoverHorizontalInverted = "#FFF"
    , arrowColorInverted = "#BBB"
    , arrowColorHoverInverted = "#FFF"
    , arrowColorActiveInverted = "#FFF"
    , arrowColorActiveHoverInverted = "#FFF"
    , arrowColorChildActiveInverted = "#FFF"
    , arrowColorChildActiveHoverInverted = "#FFF"
    , groupTextColorInverted = "#AAA"
    }
