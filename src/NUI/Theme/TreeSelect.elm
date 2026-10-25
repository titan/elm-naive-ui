module NUI.Theme.TreeSelect exposing (Vars, vars)

{-| Theme variables for the **TreeSelect** component — the Elm counterpart of Naive UI's
`src/TreeSelect/styles/light.ts` & `dark.ts` cssr theme (selfVars). TreeSelect renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`menuPadding` → `--n-menu-padding`, `menuColor` → `--n-menu-color`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to TreeSelect's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the TreeSelect CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`menuPadding` → `--n-menu-padding`).
-}
type alias Vars =
    { menuPadding : String
    , menuColor : String
    , menuBoxShadow : String
    , menuBorderRadius : String
    , menuHeight : String
    , actionDividerColor : String
    , actionTextColor : String
    , actionPadding : String
    , headerDividerColor : String
    , headerTextColor : String
    , headerPadding : String
    }


{-| Resolve the TreeSelect variables for a theme — upstream `self(common)`: Light and Dark
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
    { menuPadding = "4px"
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuBorderRadius = common.borderRadius
    , menuHeight = "calc(34px * 7.6)"
    , actionDividerColor = common.dividerColor
    , actionTextColor = common.textColor2
    , actionPadding = "8px 12px"
    , headerDividerColor = common.dividerColor
    , headerTextColor = common.textColor2
    , headerPadding = "8px 12px"
    }


dark : Common -> Vars
dark common =
    { menuPadding = "4px"
    , menuColor = common.popoverColor
    , menuBoxShadow = common.boxShadow2
    , menuBorderRadius = common.borderRadius
    , menuHeight = "calc(34px * 7.6)"
    , actionDividerColor = common.dividerColor
    , actionTextColor = common.textColor2
    , actionPadding = "8px 12px"
    , headerDividerColor = common.dividerColor
    , headerTextColor = common.textColor2
    , headerPadding = "8px 12px"
    }
