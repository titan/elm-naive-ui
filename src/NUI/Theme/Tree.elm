module NUI.Theme.Tree exposing (Vars, vars)

{-| Theme variables for the **Tree** component — the Elm counterpart of Naive UI's
`src/Tree/styles/light.ts` & `dark.ts` cssr theme (selfVars). Tree renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`fontSize` → `--n-font-size`, `lineHeight` → `--n-line-height`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Tree's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Tree CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`fontSize` → `--n-font-size`).

Collected by concern:

  - node chrome (font, line height, node height, padding, radius): `fontSize`, `lineHeight`, `nodeHeight`, `nodeWrapperPadding`, `nodeBorderRadius`
  - node surfaces & text (hover/pressed/active, disabled): `nodeColorHover`, `nodeColorPressed`, `nodeColorActive`, `nodeTextColor`, `nodeTextColorDisabled`
  - arrow & loading spinner: `arrowColor`, `loadingColor`
  - drop mark & indent line: `dropMarkColor`, `lineColor`

-}
type alias Vars =
    { fontSize : String
    , lineHeight : String
    , nodeHeight : String
    , nodeWrapperPadding : String
    , nodeBorderRadius : String
    , nodeColorHover : String
    , nodeColorPressed : String
    , nodeColorActive : String
    , arrowColor : String
    , nodeTextColor : String
    , nodeTextColorDisabled : String
    , loadingColor : String
    , dropMarkColor : String
    , lineColor : String
    }


{-| Resolve the Tree variables for a theme — upstream `self(common)`: Light and Dark
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
    , lineHeight = "1.5"
    , nodeHeight = "30px"
    , nodeWrapperPadding = "3px 0"
    , nodeBorderRadius = common.borderRadiusSmall
    , nodeColorHover = common.hoverColor
    , nodeColorPressed = common.pressedColor
    , nodeColorActive = "rgba(24, 160, 88, 0.1)"
    , arrowColor = common.textColor3
    , nodeTextColor = common.textColor2
    , nodeTextColorDisabled = common.textColorDisabled
    , loadingColor = common.primaryColor
    , dropMarkColor = common.primaryColor
    , lineColor = common.dividerColor
    }


dark : Common -> Vars
dark common =
    { fontSize = common.fontSize
    , lineHeight = "1.5"
    , nodeHeight = "30px"
    , nodeWrapperPadding = "3px 0"
    , nodeBorderRadius = common.borderRadiusSmall
    , nodeColorHover = common.hoverColor
    , nodeColorPressed = common.pressedColor
    , nodeColorActive = "rgba(99, 226, 183, 0.15)"
    , arrowColor = common.textColor3
    , nodeTextColor = common.textColor2
    , nodeTextColorDisabled = common.textColorDisabled
    , loadingColor = common.primaryColor
    , dropMarkColor = common.primaryColor
    , lineColor = common.dividerColor
    }
