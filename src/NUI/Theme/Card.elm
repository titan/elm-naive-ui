module NUI.Theme.Card exposing (Vars, vars)

{-| Theme variables for **Card** (upstream `src/Card/styles/light.ts` & `dark.ts`, cssr
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
    { paddingSmall : String
    , paddingMedium : String
    , paddingLarge : String
    , paddingHuge : String
    , titleFontSizeSmall : String
    , titleFontSizeMedium : String
    , titleFontSizeLarge : String
    , titleFontSizeHuge : String
    , closeIconSize : String
    , closeSize : String
    , lineHeight : String
    , color : String
    , colorModal : String
    , colorPopover : String
    , colorTarget : String
    , colorEmbedded : String
    , colorEmbeddedModal : String
    , colorEmbeddedPopover : String
    , textColor : String
    , titleTextColor : String
    , borderColor : String
    , actionColor : String
    , titleFontWeight : String
    , closeColorHover : String
    , closeColorPressed : String
    , closeBorderRadius : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , boxShadow : String
    , borderRadius : String
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
    { paddingSmall = "12px 16px 12px"
    , paddingMedium = "19px 24px 20px"
    , paddingLarge = "23px 32px 24px"
    , paddingHuge = "27px 40px 28px"
    , titleFontSizeSmall = "16px"
    , titleFontSizeMedium = "18px"
    , titleFontSizeLarge = "18px"
    , titleFontSizeHuge = "18px"
    , closeIconSize = "18px"
    , closeSize = "22px"
    , lineHeight = common.lineHeight
    , color = common.cardColor
    , colorModal = common.modalColor
    , colorPopover = common.popoverColor
    , colorTarget = common.primaryColor
    , colorEmbedded = common.actionColor
    , colorEmbeddedModal = common.actionColor
    , colorEmbeddedPopover = common.actionColor
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , borderColor = common.dividerColor
    , actionColor = common.actionColor
    , titleFontWeight = common.fontWeightStrong
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSize
    , fontSizeHuge = common.fontSize
    , boxShadow = common.boxShadow1
    , borderRadius = common.borderRadius
    }


dark : Common -> Vars
dark common =
    { paddingSmall = "12px 16px 12px"
    , paddingMedium = "19px 24px 20px"
    , paddingLarge = "23px 32px 24px"
    , paddingHuge = "27px 40px 28px"
    , titleFontSizeSmall = "16px"
    , titleFontSizeMedium = "18px"
    , titleFontSizeLarge = "18px"
    , titleFontSizeHuge = "18px"
    , closeIconSize = "18px"
    , closeSize = "22px"
    , lineHeight = common.lineHeight
    , color = common.cardColor
    , colorModal = common.modalColor
    , colorPopover = common.popoverColor
    , colorTarget = common.primaryColor
    , colorEmbedded = common.cardColor
    , colorEmbeddedModal = common.modalColor
    , colorEmbeddedPopover = common.popoverColor
    , textColor = common.textColor2
    , titleTextColor = common.textColor1
    , borderColor = common.dividerColor
    , actionColor = common.actionColor
    , titleFontWeight = common.fontWeightStrong
    , closeColorHover = common.closeColorHover
    , closeColorPressed = common.closeColorPressed
    , closeBorderRadius = common.borderRadius
    , closeIconColor = common.closeIconColor
    , closeIconColorHover = common.closeIconColorHover
    , closeIconColorPressed = common.closeIconColorPressed
    , fontSizeSmall = common.fontSize
    , fontSizeMedium = common.fontSize
    , fontSizeLarge = common.fontSize
    , fontSizeHuge = common.fontSize
    , boxShadow = common.boxShadow1
    , borderRadius = common.borderRadius
    }
