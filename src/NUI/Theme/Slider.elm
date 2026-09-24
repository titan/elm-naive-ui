module NUI.Theme.Slider exposing (Vars, vars)

{-| Naive UI slider theme variables.
-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


type alias Vars =
    { railHeight : String
    , railWidthVertical : String
    , handleSize : String
    , dotHeight : String
    , dotWidth : String
    , dotBorderRadius : String
    , fontSize : String
    , markFontSize : String
    , railColor : String
    , railColorHover : String
    , fillColor : String
    , fillColorHover : String
    , opacityDisabled : String
    , handleColor : String
    , dotColor : String
    , dotColorModal : String
    , dotColorPopover : String
    , handleBoxShadow : String
    , handleBoxShadowHover : String
    , handleBoxShadowActive : String
    , handleBoxShadowFocus : String
    , indicatorColor : String
    , indicatorBoxShadow : String
    , indicatorTextColor : String
    , indicatorBorderRadius : String
    , dotBorder : String
    , dotBorderActive : String
    , dotBoxShadow : String
    }


vars : Theme -> Vars
vars theme =
    case theme.mode of
        Theme.Light ->
            light theme.common

        Theme.Dark ->
            dark theme.common


light : Common -> Vars
light common =
    { railHeight = "4px"
    , railWidthVertical = "4px"
    , handleSize = "18px"
    , dotHeight = "8px"
    , dotWidth = "8px"
    , dotBorderRadius = "4px"
    , fontSize = common.fontSize
    , markFontSize = common.fontSize
    , railColor = common.railColor
    , railColorHover = common.railColor
    , fillColor = common.primaryColor
    , fillColorHover = common.primaryColor
    , opacityDisabled = common.opacityDisabled
    , handleColor = "#FFF"
    , dotColor = common.cardColor
    , dotColorModal = common.modalColor
    , dotColorPopover = common.popoverColor
    , handleBoxShadow = "0 1px 4px 0 rgba(0, 0, 0, 0.3), inset 0 0 1px 0 rgba(0, 0, 0, 0.05)"
    , handleBoxShadowHover = "0 1px 4px 0 rgba(0, 0, 0, 0.3), inset 0 0 1px 0 rgba(0, 0, 0, 0.05)"
    , handleBoxShadowActive = "0 1px 4px 0 rgba(0, 0, 0, 0.3), inset 0 0 1px 0 rgba(0, 0, 0, 0.05)"
    , handleBoxShadowFocus = "0 1px 4px 0 rgba(0, 0, 0, 0.3), inset 0 0 1px 0 rgba(0, 0, 0, 0.05)"
    , indicatorColor = "rgba(0, 0, 0, .85)"
    , indicatorBoxShadow = "0 2px 8px 0 rgba(0, 0, 0, 0.12)"
    , indicatorTextColor = common.baseColor
    , indicatorBorderRadius = common.borderRadius
    , dotBorder = "2px solid rgb(219, 219, 223)"
    , dotBorderActive = "2px solid #18a058"
    , dotBoxShadow = ""
    }


dark : Common -> Vars
dark common =
    { railHeight = "4px"
    , railWidthVertical = "4px"
    , handleSize = "18px"
    , dotHeight = "8px"
    , dotWidth = "8px"
    , dotBorderRadius = "4px"
    , fontSize = common.fontSize
    , markFontSize = common.fontSize
    , railColor = common.railColor
    , railColorHover = common.railColor
    , fillColor = common.primaryColorSuppl
    , fillColorHover = common.primaryColorSuppl
    , opacityDisabled = common.opacityDisabled
    , handleColor = "#FFF"
    , dotColor = common.cardColor
    , dotColorModal = common.modalColor
    , dotColorPopover = common.popoverColor
    , handleBoxShadow = "0px 2px 4px 0 rgba(0, 0, 0, 0.4)"
    , handleBoxShadowHover = "0px 2px 4px 0 rgba(0, 0, 0, 0.4)"
    , handleBoxShadowActive = "0px 2px 4px 0 rgba(0, 0, 0, 0.4)"
    , handleBoxShadowFocus = "0px 2px 4px 0 rgba(0, 0, 0, 0.4)"
    , indicatorColor = common.popoverColor
    , indicatorBoxShadow = "0 2px 8px 0 rgba(0, 0, 0, 0.12)"
    , indicatorTextColor = common.textColor2
    , indicatorBorderRadius = common.borderRadius
    , dotBorder = "2px solid rgba(255, 255, 255, 0.2)"
    , dotBorderActive = "2px solid rgb(42, 148, 125)"
    , dotBoxShadow = ""
    }
