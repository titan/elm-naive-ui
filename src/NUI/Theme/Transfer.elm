module NUI.Theme.Transfer exposing (Vars, vars)

{-| Theme variables for **Transfer** (upstream `src/Transfer/styles/light.ts` & `dark.ts`, cssr
selfVars). Fields map 1:1 onto the component's `--n-*` custom properties
(kebab-case of the field name). `vars` resolves the light/dark palette from
`theme.mode` + `theme.common` — upstream's `self(common)`; override individual
fields to customise.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties this component's CSS consumes, as one record.
-}
type alias Vars =
    { extraFontSizeSmall : String
    , extraFontSizeMedium : String
    , extraFontSizeLarge : String
    , titleFontSizeSmall : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , closeSize : String
    , closeIconSize : String
    , headerHeightSmall : String
    , headerHeightMedium : String
    , headerHeightLarge : String
    , itemHeightSmall : String
    , itemHeightMedium : String
    , itemHeightLarge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , borderRadius : String
    , dividerColor : String
    , borderColor : String
    , listColor : String
    , headerColor : String
    , titleTextColor : String
    , titleTextColorDisabled : String
    , extraTextColor : String
    , extraTextColorDisabled : String
    , itemTextColor : String
    , itemTextColorDisabled : String
    , itemColorPending : String
    , titleFontWeight : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    }


{-| Resolve this component's variables for a theme (see the module doc).
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
    { extraFontSizeSmall = "12px"
    , extraFontSizeMedium = "12px"
    , extraFontSizeLarge = "14px"
    , titleFontSizeSmall = "14px"
    , titleFontSizeMedium = "16px"
    , titleFontSizeLarge = "16px"
    , closeSize = "20px"
    , closeIconSize = "16px"
    , headerHeightSmall = "44px"
    , headerHeightMedium = "44px"
    , headerHeightLarge = "50px"
    , itemHeightSmall = common.heightMedium
    , itemHeightMedium = common.heightMedium
    , itemHeightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , borderRadius = common.borderRadius
    , dividerColor = common.borderColor
    , borderColor = common.borderColor
    , listColor = common.cardColor
    , headerColor = "rgba(250, 250, 252, 1)"
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , extraTextColor = common.textColor3
    , extraTextColorDisabled = common.textColorDisabled
    , itemTextColor = common.textColor2
    , itemTextColorDisabled = common.textColorDisabled
    , itemColorPending = common.hoverColor
    , titleFontWeight = common.fontWeight
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    }


dark : Common -> Vars
dark common =
    { extraFontSizeSmall = "12px"
    , extraFontSizeMedium = "12px"
    , extraFontSizeLarge = "14px"
    , titleFontSizeSmall = "14px"
    , titleFontSizeMedium = "16px"
    , titleFontSizeLarge = "16px"
    , closeSize = "20px"
    , closeIconSize = "16px"
    , headerHeightSmall = "44px"
    , headerHeightMedium = "44px"
    , headerHeightLarge = "50px"
    , itemHeightSmall = common.heightMedium
    , itemHeightMedium = common.heightMedium
    , itemHeightLarge = common.heightLarge
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , borderRadius = common.borderRadius
    , dividerColor = common.dividerColor
    , borderColor = "#0000"
    , listColor = common.inputColor
    , headerColor = common.tableHeaderColor
    , titleTextColor = common.textColor1
    , titleTextColorDisabled = common.textColorDisabled
    , extraTextColor = common.textColor3
    , extraTextColorDisabled = common.textColorDisabled
    , itemTextColor = common.textColor2
    , itemTextColorDisabled = common.textColorDisabled
    , itemColorPending = common.hoverColor
    , titleFontWeight = common.fontWeight
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    }
