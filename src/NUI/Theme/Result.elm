module NUI.Theme.Result exposing (Vars, vars)

{-| Theme variables for **Result** (upstream `src/Result/styles/light.ts` & `dark.ts`, cssr
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
    { titleFontSizeSmall : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , titleFontSizeHuge : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , iconSizeSmall : String
    , iconSizeMedium : String
    , iconSizeLarge : String
    , iconSizeHuge : String
    , lineHeight : String
    , titleFontWeight : String
    , titleTextColor : String
    , textColor : String
    , iconColorError : String
    , iconColorSuccess : String
    , iconColorInfo : String
    , iconColorWarning : String
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
    { titleFontSizeSmall = "26px"
    , titleFontSizeMedium = "32px"
    , titleFontSizeLarge = "40px"
    , titleFontSizeHuge = "48px"
    , fontSizeSmall = "14px"
    , fontSizeMedium = "14px"
    , fontSizeLarge = "15px"
    , fontSizeHuge = "16px"
    , iconSizeSmall = "64px"
    , iconSizeMedium = "80px"
    , iconSizeLarge = "100px"
    , iconSizeHuge = "125px"
    , lineHeight = common.lineHeight
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , iconColorError = common.errorColor
    , iconColorSuccess = common.successColor
    , iconColorInfo = common.infoColor
    , iconColorWarning = common.warningColor
    }


dark : Common -> Vars
dark common =
    { titleFontSizeSmall = "26px"
    , titleFontSizeMedium = "32px"
    , titleFontSizeLarge = "40px"
    , titleFontSizeHuge = "48px"
    , fontSizeSmall = "14px"
    , fontSizeMedium = "14px"
    , fontSizeLarge = "15px"
    , fontSizeHuge = "16px"
    , iconSizeSmall = "64px"
    , iconSizeMedium = "80px"
    , iconSizeLarge = "100px"
    , iconSizeHuge = "125px"
    , lineHeight = common.lineHeight
    , titleFontWeight = common.fontWeightStrong
    , titleTextColor = common.textColor1
    , textColor = common.textColor2
    , iconColorError = common.errorColor
    , iconColorSuccess = common.successColor
    , iconColorInfo = common.infoColor
    , iconColorWarning = common.warningColor
    }
