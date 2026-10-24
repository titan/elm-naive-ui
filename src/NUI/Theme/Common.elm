module NUI.Theme.Common exposing (Common, light, dark)

{-| The **common (shared) theme variables** every `NUI.Theme.*` component theme
derives from — the Elm counterpart of Naive UI's `src/_styles/common/light.ts` &
`dark.ts`. This is the single palette of fonts, font sizes, border radii, easing
curves, base colours (primary/info/success/warning/error plus their hover,
pressed and \*-suppl variants), text/action/close colours and the three elevation
shadows.

Every component resolver (`NUI.Theme.<Component>.vars`) reads its values from a
`Common`, exactly like upstream's `self(common)` — so overriding one field here
restyles every component at once. `NUI.Theme.light` / `NUI.Theme.dark` ship these
same records bundled with a mode flag; prefer those unless you are building a
theme from scratch.

Values are extracted from Naive UI value-for-value; several fields (e.g.
`primaryColor`) additionally feed `NUI.Theme.setPrimary`, which re-derives the
whole palette from a custom brand colour the same way upstream's
`compositeThemeVariables` does.

@docs Common, light, dark

-}


{-| The shared variable record. Field names follow upstream's `commonVars` keys
in kebab-case → camelCase (e.g. `cubicBezierEaseInOut`, `borderRadiusSmall`,
`primaryColorHover`), each a ready-to-use CSS value string.
-}
type alias Common =
    { name : String
    , fontFamily : String
    , fontFamilyMono : String
    , fontWeight : String
    , fontWeightStrong : String
    , cubicBezierEaseInOut : String
    , cubicBezierEaseOut : String
    , cubicBezierEaseIn : String
    , borderRadius : String
    , borderRadiusSmall : String
    , fontSize : String
    , fontSizeMini : String
    , fontSizeTiny : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , fontSizeHuge : String
    , lineHeight : String
    , heightMini : String
    , heightTiny : String
    , heightSmall : String
    , heightMedium : String
    , heightLarge : String
    , heightHuge : String
    , baseColor : String
    , primaryColor : String
    , primaryColorHover : String
    , primaryColorPressed : String
    , primaryColorSuppl : String
    , infoColor : String
    , infoColorHover : String
    , infoColorPressed : String
    , infoColorSuppl : String
    , successColor : String
    , successColorHover : String
    , successColorPressed : String
    , successColorSuppl : String
    , warningColor : String
    , warningColorHover : String
    , warningColorPressed : String
    , warningColorSuppl : String
    , errorColor : String
    , errorColorHover : String
    , errorColorPressed : String
    , errorColorSuppl : String
    , textColorBase : String
    , textColor1 : String
    , textColor2 : String
    , textColor3 : String
    , textColorDisabled : String
    , placeholderColor : String
    , placeholderColorDisabled : String
    , iconColor : String
    , iconColorHover : String
    , iconColorPressed : String
    , iconColorDisabled : String
    , opacity1 : String
    , opacity2 : String
    , opacity3 : String
    , opacity4 : String
    , opacity5 : String
    , dividerColor : String
    , borderColor : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeColorHover : String
    , closeColorPressed : String
    , clearColor : String
    , clearColorHover : String
    , clearColorPressed : String
    , scrollbarColor : String
    , scrollbarColorHover : String
    , scrollbarWidth : String
    , scrollbarHeight : String
    , scrollbarBorderRadius : String
    , progressRailColor : String
    , railColor : String
    , popoverColor : String
    , tableColor : String
    , cardColor : String
    , modalColor : String
    , bodyColor : String
    , tagColor : String
    , avatarColor : String
    , invertedColor : String
    , inputColor : String
    , codeColor : String
    , tabColor : String
    , actionColor : String
    , tableHeaderColor : String
    , hoverColor : String
    , tableColorHover : String
    , tableColorStriped : String
    , pressedColor : String
    , opacityDisabled : String
    , inputColorDisabled : String
    , buttonColor2 : String
    , buttonColor2Hover : String
    , buttonColor2Pressed : String
    , boxShadow1 : String
    , boxShadow2 : String
    , boxShadow3 : String
    }


{-| The Light-mode common palette — upstream `commonLight`, i.e. the values
behind Naive UI's default (light) look.
-}
light : Common
light =
    { name = "common"
    , fontFamily = "v-sans, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif, \"Apple Color Emoji\", \"Segoe UI Emoji\", \"Segoe UI Symbol\""
    , fontFamilyMono = "v-mono, SFMono-Regular, Menlo, Consolas, Courier, monospace"
    , fontWeight = "400"
    , fontWeightStrong = "500"
    , cubicBezierEaseInOut = "cubic-bezier(.4, 0, .2, 1)"
    , cubicBezierEaseOut = "cubic-bezier(0, 0, .2, 1)"
    , cubicBezierEaseIn = "cubic-bezier(.4, 0, 1, 1)"
    , borderRadius = "3px"
    , borderRadiusSmall = "2px"
    , fontSize = "14px"
    , fontSizeMini = "12px"
    , fontSizeTiny = "12px"
    , fontSizeSmall = "14px"
    , fontSizeMedium = "14px"
    , fontSizeLarge = "15px"
    , fontSizeHuge = "16px"
    , lineHeight = "1.6"
    , heightMini = "16px"
    , heightTiny = "22px"
    , heightSmall = "28px"
    , heightMedium = "34px"
    , heightLarge = "40px"
    , heightHuge = "46px"
    , baseColor = "#FFF"
    , primaryColor = "#18a058"
    , primaryColorHover = "#36ad6a"
    , primaryColorPressed = "#0c7a43"
    , primaryColorSuppl = "#36ad6a"
    , infoColor = "#2080f0"
    , infoColorHover = "#4098fc"
    , infoColorPressed = "#1060c9"
    , infoColorSuppl = "#4098fc"
    , successColor = "#18a058"
    , successColorHover = "#36ad6a"
    , successColorPressed = "#0c7a43"
    , successColorSuppl = "#36ad6a"
    , warningColor = "#f0a020"
    , warningColorHover = "#fcb040"
    , warningColorPressed = "#c97c10"
    , warningColorSuppl = "#fcb040"
    , errorColor = "#d03050"
    , errorColorHover = "#de576d"
    , errorColorPressed = "#ab1f3f"
    , errorColorSuppl = "#de576d"
    , textColorBase = "#000"
    , textColor1 = "rgb(31, 34, 37)"
    , textColor2 = "rgb(51, 54, 57)"
    , textColor3 = "rgb(118, 124, 130)"
    , textColorDisabled = "rgba(194, 194, 194, 1)"
    , placeholderColor = "rgba(194, 194, 194, 1)"
    , placeholderColorDisabled = "rgba(209, 209, 209, 1)"
    , iconColor = "rgba(194, 194, 194, 1)"
    , iconColorHover = "rgba(146, 146, 146, 1)"
    , iconColorPressed = "rgba(175, 175, 175, 1)"
    , iconColorDisabled = "rgba(209, 209, 209, 1)"
    , opacity1 = "0.82"
    , opacity2 = "0.72"
    , opacity3 = "0.38"
    , opacity4 = "0.24"
    , opacity5 = "0.18"
    , dividerColor = "rgb(239, 239, 245)"
    , borderColor = "rgb(224, 224, 230)"
    , closeIconColor = "rgba(102, 102, 102, 1)"
    , closeIconColorHover = "rgba(102, 102, 102, 1)"
    , closeIconColorPressed = "rgba(102, 102, 102, 1)"
    , closeColorHover = "rgba(0, 0, 0, .09)"
    , closeColorPressed = "rgba(0, 0, 0, .13)"
    , clearColor = "rgba(194, 194, 194, 1)"
    , clearColorHover = "rgba(146, 146, 146, 1)"
    , clearColorPressed = "rgba(175, 175, 175, 1)"
    , scrollbarColor = "rgba(0, 0, 0, 0.25)"
    , scrollbarColorHover = "rgba(0, 0, 0, 0.4)"
    , scrollbarWidth = "5px"
    , scrollbarHeight = "5px"
    , scrollbarBorderRadius = "5px"
    , progressRailColor = "rgba(235, 235, 235, 1)"
    , railColor = "rgb(219, 219, 223)"
    , popoverColor = "#fff"
    , tableColor = "#fff"
    , cardColor = "#fff"
    , modalColor = "#fff"
    , bodyColor = "#fff"
    , tagColor = "#eee"
    , avatarColor = "rgba(204, 204, 204, 1)"
    , invertedColor = "rgb(0, 20, 40)"
    , inputColor = "rgba(255, 255, 255, 1)"
    , codeColor = "rgb(244, 244, 248)"
    , tabColor = "rgb(247, 247, 250)"
    , actionColor = "rgb(250, 250, 252)"
    , tableHeaderColor = "rgb(250, 250, 252)"
    , hoverColor = "rgb(243, 243, 245)"
    , tableColorHover = "rgba(0, 0, 100, 0.03)"
    , tableColorStriped = "rgba(0, 0, 100, 0.02)"
    , pressedColor = "rgb(237, 237, 239)"
    , opacityDisabled = "0.5"
    , inputColorDisabled = "rgb(250, 250, 252)"
    , buttonColor2 = "rgba(46, 51, 56, .05)"
    , buttonColor2Hover = "rgba(46, 51, 56, .09)"
    , buttonColor2Pressed = "rgba(46, 51, 56, .13)"
    , boxShadow1 = "0 1px 2px -2px rgba(0, 0, 0, .08), 0 3px 6px 0 rgba(0, 0, 0, .06), 0 5px 12px 4px rgba(0, 0, 0, .04)"
    , boxShadow2 = "0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)"
    , boxShadow3 = "0 6px 16px -9px rgba(0, 0, 0, .08), 0 9px 28px 0 rgba(0, 0, 0, .05), 0 12px 48px 16px rgba(0, 0, 0, .03)"
    }


{-| The Dark-mode common palette — upstream `commonDark`: darker surfaces, the
`*-suppl` accent variants, and adjusted text/close colours.
-}
dark : Common
dark =
    { name = "common"
    , fontFamily = "v-sans, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif, \"Apple Color Emoji\", \"Segoe UI Emoji\", \"Segoe UI Symbol\""
    , fontFamilyMono = "v-mono, SFMono-Regular, Menlo, Consolas, Courier, monospace"
    , fontWeight = "400"
    , fontWeightStrong = "500"
    , cubicBezierEaseInOut = "cubic-bezier(.4, 0, .2, 1)"
    , cubicBezierEaseOut = "cubic-bezier(0, 0, .2, 1)"
    , cubicBezierEaseIn = "cubic-bezier(.4, 0, 1, 1)"
    , borderRadius = "3px"
    , borderRadiusSmall = "2px"
    , fontSize = "14px"
    , fontSizeMini = "12px"
    , fontSizeTiny = "12px"
    , fontSizeSmall = "14px"
    , fontSizeMedium = "14px"
    , fontSizeLarge = "15px"
    , fontSizeHuge = "16px"
    , lineHeight = "1.6"
    , heightMini = "16px"
    , heightTiny = "22px"
    , heightSmall = "28px"
    , heightMedium = "34px"
    , heightLarge = "40px"
    , heightHuge = "46px"
    , baseColor = "#000"
    , primaryColor = "#63e2b7"
    , primaryColorHover = "#7fe7c4"
    , primaryColorPressed = "#5acea7"
    , primaryColorSuppl = "rgb(42, 148, 125)"
    , infoColor = "#70c0e8"
    , infoColorHover = "#8acbec"
    , infoColorPressed = "#66afd3"
    , infoColorSuppl = "rgb(56, 137, 197)"
    , successColor = "#63e2b7"
    , successColorHover = "#7fe7c4"
    , successColorPressed = "#5acea7"
    , successColorSuppl = "rgb(42, 148, 125)"
    , warningColor = "#f2c97d"
    , warningColorHover = "#f5d599"
    , warningColorPressed = "#e6c260"
    , warningColorSuppl = "rgb(240, 138, 0)"
    , errorColor = "#e88080"
    , errorColorHover = "#e98b8b"
    , errorColorPressed = "#e57272"
    , errorColorSuppl = "rgb(208, 58, 82)"
    , textColorBase = "#fff"
    , textColor1 = "rgba(255, 255, 255, 0.9)"
    , textColor2 = "rgba(255, 255, 255, 0.82)"
    , textColor3 = "rgba(255, 255, 255, 0.52)"
    , textColorDisabled = "rgba(255, 255, 255, 0.38)"
    , placeholderColor = "rgba(255, 255, 255, 0.38)"
    , placeholderColorDisabled = "rgba(255, 255, 255, 0.28)"
    , iconColor = "rgba(255, 255, 255, 0.38)"
    , iconColorHover = "rgba(255, 255, 255, 0.475)"
    , iconColorPressed = "rgba(255, 255, 255, 0.30400000000000005)"
    , iconColorDisabled = "rgba(255, 255, 255, 0.28)"
    , opacity1 = "0.9"
    , opacity2 = "0.82"
    , opacity3 = "0.52"
    , opacity4 = "0.38"
    , opacity5 = "0.28"
    , dividerColor = "rgba(255, 255, 255, 0.09)"
    , borderColor = "rgba(255, 255, 255, 0.24)"
    , closeIconColor = "rgba(255, 255, 255, 0.52)"
    , closeIconColorHover = "rgba(255, 255, 255, 0.52)"
    , closeIconColorPressed = "rgba(255, 255, 255, 0.52)"
    , closeColorHover = "rgba(255, 255, 255, .12)"
    , closeColorPressed = "rgba(255, 255, 255, .08)"
    , clearColor = "rgba(255, 255, 255, 0.38)"
    , clearColorHover = "rgba(255, 255, 255, 0.48)"
    , clearColorPressed = "rgba(255, 255, 255, 0.3)"
    , scrollbarColor = "rgba(255, 255, 255, 0.2)"
    , scrollbarColorHover = "rgba(255, 255, 255, 0.3)"
    , scrollbarWidth = "5px"
    , scrollbarHeight = "5px"
    , scrollbarBorderRadius = "5px"
    , progressRailColor = "rgba(255, 255, 255, 0.12)"
    , railColor = "rgba(255, 255, 255, 0.2)"
    , popoverColor = "rgb(72, 72, 78)"
    , tableColor = "rgb(24, 24, 28)"
    , cardColor = "rgb(24, 24, 28)"
    , modalColor = "rgb(44, 44, 50)"
    , bodyColor = "rgb(16, 16, 20)"
    , tagColor = "rgba(51, 51, 51, 1)"
    , avatarColor = "rgba(255, 255, 255, 0.18)"
    , invertedColor = "#000"
    , inputColor = "rgba(255, 255, 255, 0.1)"
    , codeColor = "rgba(255, 255, 255, 0.12)"
    , tabColor = "rgba(255, 255, 255, 0.04)"
    , actionColor = "rgba(255, 255, 255, 0.06)"
    , tableHeaderColor = "rgba(255, 255, 255, 0.06)"
    , hoverColor = "rgba(255, 255, 255, 0.09)"
    , tableColorHover = "rgba(255, 255, 255, 0.06)"
    , tableColorStriped = "rgba(255, 255, 255, 0.05)"
    , pressedColor = "rgba(255, 255, 255, 0.05)"
    , opacityDisabled = "0.38"
    , inputColorDisabled = "rgba(255, 255, 255, 0.06)"
    , buttonColor2 = "rgba(255, 255, 255, .08)"
    , buttonColor2Hover = "rgba(255, 255, 255, .12)"
    , buttonColor2Pressed = "rgba(255, 255, 255, .08)"
    , boxShadow1 = "0 1px 2px -2px rgba(0, 0, 0, .24), 0 3px 6px 0 rgba(0, 0, 0, .18), 0 5px 12px 4px rgba(0, 0, 0, .12)"
    , boxShadow2 = "0 3px 6px -4px rgba(0, 0, 0, .24), 0 6px 12px 0 rgba(0, 0, 0, .16), 0 9px 18px 8px rgba(0, 0, 0, .10)"
    , boxShadow3 = "0 6px 16px -9px rgba(0, 0, 0, .08), 0 9px 28px 0 rgba(0, 0, 0, .05), 0 12px 48px 16px rgba(0, 0, 0, .03)"
    }
