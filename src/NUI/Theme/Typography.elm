module NUI.Theme.Typography exposing (Vars, vars)

{-| Theme variables for the **Typography** component — the Elm counterpart of Naive UI's
`src/Typography/styles/light.ts` & `dark.ts` cssr theme (selfVars). Typography renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`pMargin` → `--n-p-margin`, `liMargin` → `--n-li-margin`, …).
(Headers are the one exception: they consume the per-level `headerFontSize1`…`6` &
friends to emit `--n-font-size` etc. for each level.)

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Typography's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the Typography CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`pMargin` → `--n-p-margin`).

Collected by concern:

  - headers (scales 1–6 font sizes, margins, prefix & bar widths; weight, text & bar colors): `headerFontSize1`, `headerFontSize2`, `headerFontSize3`, `headerFontSize4`, `headerFontSize5`, `headerFontSize6`, `headerMargin1`, `headerMargin2`, `headerMargin3`, `headerMargin4`, `headerMargin5`, `headerMargin6`, `headerPrefixWidth1`, `headerPrefixWidth2`, `headerPrefixWidth3`, `headerPrefixWidth4`, `headerPrefixWidth5`, `headerPrefixWidth6`, `headerBarWidth1`, `headerBarWidth2`, `headerBarWidth3`, `headerBarWidth4`, `headerBarWidth5`, `headerBarWidth6`, `headerFontWeight`, `headerTextColor`, `headerBarColor`, `headerBarColorPrimary`, `headerBarColorInfo`, `headerBarColorError`, `headerBarColorWarning`, `headerBarColorSuccess`
  - paragraph/list/blockquote/anchor metrics & colors: `pMargin`, `liMargin`, `olPadding`, `ulPadding`, `aTextColor`, `blockquoteTextColor`, `blockquotePrefixColor`, `blockquoteLineHeight`, `blockquoteFontSize`, `codeBorderRadius`, `liTextColor`, `liLineHeight`, `liFontSize`, `hrColor`, `pTextColor`, `pTextColor1Depth`, `pTextColor2Depth`, `pTextColor3Depth`, `pLineHeight`, `pFontSize`
  - text color depths (1/2/3) & typed colors: `textColor`, `textColor1Depth`, `textColor2Depth`, `textColor3Depth`, `textColorPrimary`, `textColorInfo`, `textColorSuccess`, `textColorWarning`, `textColorError`
  - inline code look: `codeTextColor`, `codeColor`, `codeBorder`

-}
type alias Vars =
    { headerFontSize1 : String
    , headerFontSize2 : String
    , headerFontSize3 : String
    , headerFontSize4 : String
    , headerFontSize5 : String
    , headerFontSize6 : String
    , headerMargin1 : String
    , headerMargin2 : String
    , headerMargin3 : String
    , headerMargin4 : String
    , headerMargin5 : String
    , headerMargin6 : String
    , headerPrefixWidth1 : String
    , headerPrefixWidth2 : String
    , headerPrefixWidth3 : String
    , headerPrefixWidth4 : String
    , headerPrefixWidth5 : String
    , headerPrefixWidth6 : String
    , headerBarWidth1 : String
    , headerBarWidth2 : String
    , headerBarWidth3 : String
    , headerBarWidth4 : String
    , headerBarWidth5 : String
    , headerBarWidth6 : String
    , pMargin : String
    , liMargin : String
    , olPadding : String
    , ulPadding : String
    , aTextColor : String
    , blockquoteTextColor : String
    , blockquotePrefixColor : String
    , blockquoteLineHeight : String
    , blockquoteFontSize : String
    , codeBorderRadius : String
    , liTextColor : String
    , liLineHeight : String
    , liFontSize : String
    , hrColor : String
    , headerFontWeight : String
    , headerTextColor : String
    , pTextColor : String
    , pTextColor1Depth : String
    , pTextColor2Depth : String
    , pTextColor3Depth : String
    , pLineHeight : String
    , pFontSize : String
    , headerBarColor : String
    , headerBarColorPrimary : String
    , headerBarColorInfo : String
    , headerBarColorError : String
    , headerBarColorWarning : String
    , headerBarColorSuccess : String
    , textColor : String
    , textColor1Depth : String
    , textColor2Depth : String
    , textColor3Depth : String
    , textColorPrimary : String
    , textColorInfo : String
    , textColorSuccess : String
    , textColorWarning : String
    , textColorError : String
    , codeTextColor : String
    , codeColor : String
    , codeBorder : String
    }


{-| Resolve the Typography variables for a theme — upstream `self(common)`: Light and Dark
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
    { headerFontSize1 = "30px"
    , headerFontSize2 = "22px"
    , headerFontSize3 = "18px"
    , headerFontSize4 = "16px"
    , headerFontSize5 = "16px"
    , headerFontSize6 = "16px"
    , headerMargin1 = "28px 0 20px 0"
    , headerMargin2 = "28px 0 20px 0"
    , headerMargin3 = "28px 0 20px 0"
    , headerMargin4 = "28px 0 18px 0"
    , headerMargin5 = "28px 0 18px 0"
    , headerMargin6 = "28px 0 18px 0"
    , headerPrefixWidth1 = "16px"
    , headerPrefixWidth2 = "16px"
    , headerPrefixWidth3 = "12px"
    , headerPrefixWidth4 = "12px"
    , headerPrefixWidth5 = "12px"
    , headerPrefixWidth6 = "12px"
    , headerBarWidth1 = "4px"
    , headerBarWidth2 = "4px"
    , headerBarWidth3 = "3px"
    , headerBarWidth4 = "3px"
    , headerBarWidth5 = "3px"
    , headerBarWidth6 = "3px"
    , pMargin = "16px 0 16px 0"
    , liMargin = ".25em 0 0 0"
    , olPadding = "0 0 0 2em"
    , ulPadding = "0 0 0 2em"
    , aTextColor = common.primaryColor
    , blockquoteTextColor = common.textColor2
    , blockquotePrefixColor = common.borderColor
    , blockquoteLineHeight = common.lineHeight
    , blockquoteFontSize = common.fontSize
    , codeBorderRadius = common.borderRadiusSmall
    , liTextColor = common.textColor2
    , liLineHeight = common.lineHeight
    , liFontSize = common.fontSize
    , hrColor = common.dividerColor
    , headerFontWeight = common.fontWeightStrong
    , headerTextColor = common.textColor1
    , pTextColor = common.textColor2
    , pTextColor1Depth = common.textColor1
    , pTextColor2Depth = common.textColor2
    , pTextColor3Depth = common.textColor3
    , pLineHeight = common.lineHeight
    , pFontSize = common.fontSize
    , headerBarColor = common.primaryColor
    , headerBarColorPrimary = common.primaryColor
    , headerBarColorInfo = common.infoColor
    , headerBarColorError = common.errorColor
    , headerBarColorWarning = common.warningColor
    , headerBarColorSuccess = common.successColor
    , textColor = common.textColor2
    , textColor1Depth = common.textColor1
    , textColor2Depth = common.textColor2
    , textColor3Depth = common.textColor3
    , textColorPrimary = common.primaryColor
    , textColorInfo = common.infoColor
    , textColorSuccess = common.successColor
    , textColorWarning = common.warningColor
    , textColorError = common.errorColor
    , codeTextColor = common.textColor2
    , codeColor = common.codeColor
    , codeBorder = "1px solid #0000"
    }


dark : Common -> Vars
dark common =
    { headerFontSize1 = "30px"
    , headerFontSize2 = "22px"
    , headerFontSize3 = "18px"
    , headerFontSize4 = "16px"
    , headerFontSize5 = "16px"
    , headerFontSize6 = "16px"
    , headerMargin1 = "28px 0 20px 0"
    , headerMargin2 = "28px 0 20px 0"
    , headerMargin3 = "28px 0 20px 0"
    , headerMargin4 = "28px 0 18px 0"
    , headerMargin5 = "28px 0 18px 0"
    , headerMargin6 = "28px 0 18px 0"
    , headerPrefixWidth1 = "16px"
    , headerPrefixWidth2 = "16px"
    , headerPrefixWidth3 = "12px"
    , headerPrefixWidth4 = "12px"
    , headerPrefixWidth5 = "12px"
    , headerPrefixWidth6 = "12px"
    , headerBarWidth1 = "4px"
    , headerBarWidth2 = "4px"
    , headerBarWidth3 = "3px"
    , headerBarWidth4 = "3px"
    , headerBarWidth5 = "3px"
    , headerBarWidth6 = "3px"
    , pMargin = "16px 0 16px 0"
    , liMargin = ".25em 0 0 0"
    , olPadding = "0 0 0 2em"
    , ulPadding = "0 0 0 2em"
    , aTextColor = common.primaryColor
    , blockquoteTextColor = common.textColor2
    , blockquotePrefixColor = common.borderColor
    , blockquoteLineHeight = common.lineHeight
    , blockquoteFontSize = common.fontSize
    , codeBorderRadius = common.borderRadiusSmall
    , liTextColor = common.textColor2
    , liLineHeight = common.lineHeight
    , liFontSize = common.fontSize
    , hrColor = common.dividerColor
    , headerFontWeight = common.fontWeightStrong
    , headerTextColor = common.textColor1
    , pTextColor = common.textColor2
    , pTextColor1Depth = common.textColor1
    , pTextColor2Depth = common.textColor2
    , pTextColor3Depth = common.textColor3
    , pLineHeight = common.lineHeight
    , pFontSize = common.fontSize
    , headerBarColor = common.primaryColor
    , headerBarColorPrimary = common.primaryColor
    , headerBarColorInfo = common.infoColor
    , headerBarColorError = common.errorColor
    , headerBarColorWarning = common.warningColor
    , headerBarColorSuccess = common.successColor
    , textColor = common.textColor2
    , textColor1Depth = common.textColor1
    , textColor2Depth = common.textColor2
    , textColor3Depth = common.textColor3
    , textColorPrimary = common.primaryColor
    , textColorInfo = common.infoColor
    , textColorSuccess = common.successColor
    , textColorWarning = common.warningColor
    , textColorError = common.errorColor
    , codeTextColor = common.textColor2
    , codeColor = common.codeColor
    , codeBorder = "1px solid #0000"
    }
