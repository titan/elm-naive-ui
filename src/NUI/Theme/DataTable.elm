module NUI.Theme.DataTable exposing (Vars, vars)

{-| Theme variables for the **DataTable** component — the Elm counterpart of Naive UI's
`src/DataTable/styles/light.ts` & `dark.ts` cssr theme (selfVars). DataTable renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (`thPaddingSmall` → `--n-th-padding-small`, `thPaddingMedium` → `--n-th-padding-medium`, …).

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to DataTable's `view`, or override individual
fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the DataTable CSS consumes, as one record. Fields map
1:1 onto the component's `--n-<kebab-case-field>` custom properties (`thPaddingSmall` → `--n-th-padding-small`).
-}
type alias Vars =
    { thPaddingSmall : String
    , thPaddingMedium : String
    , thPaddingLarge : String
    , tdPaddingSmall : String
    , tdPaddingMedium : String
    , tdPaddingLarge : String
    , sorterSize : String
    , resizableContainerSize : String
    , resizableSize : String
    , filterSize : String
    , paginationMargin : String
    , emptyPadding : String
    , actionPadding : String
    , actionButtonMargin : String
    , actionDividerColor : String
    , lineHeight : String
    , borderRadius : String
    , fontSizeSmall : String
    , fontSizeMedium : String
    , fontSizeLarge : String
    , borderColor : String
    , tdColorHover : String
    , tdColorSorting : String
    , tdColorStriped : String
    , thColor : String
    , thColorHover : String
    , thColorSorting : String
    , tdColor : String
    , tdTextColor : String
    , thTextColor : String
    , thFontWeight : String
    , thButtonColorHover : String
    , thIconColor : String
    , thIconColorActive : String
    , borderColorModal : String
    , tdColorHoverModal : String
    , tdColorSortingModal : String
    , tdColorStripedModal : String
    , thColorModal : String
    , thColorHoverModal : String
    , thColorSortingModal : String
    , tdColorModal : String
    , borderColorPopover : String
    , tdColorHoverPopover : String
    , tdColorSortingPopover : String
    , tdColorStripedPopover : String
    , thColorPopover : String
    , thColorHoverPopover : String
    , thColorSortingPopover : String
    , tdColorPopover : String
    , boxShadowBefore : String
    , boxShadowAfter : String
    , loadingColor : String
    , loadingSize : String
    , opacityLoading : String
    }


{-| Resolve the DataTable variables for a theme — upstream `self(common)`: Light and Dark
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
    { thPaddingSmall = "8px"
    , thPaddingMedium = "12px"
    , thPaddingLarge = "12px"
    , tdPaddingSmall = "8px"
    , tdPaddingMedium = "12px"
    , tdPaddingLarge = "12px"
    , sorterSize = "15px"
    , resizableContainerSize = "8px"
    , resizableSize = "2px"
    , filterSize = "15px"
    , paginationMargin = "12px 0 0 0"
    , emptyPadding = "48px 0"
    , actionPadding = "8px 12px"
    , actionButtonMargin = "0 8px 0 0"
    , actionDividerColor = common.dividerColor
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , borderColor = "rgba(239, 239, 245, 1)"
    , tdColorHover = "rgba(247, 247, 250, 1)"
    , tdColorSorting = "rgba(247, 247, 250, 1)"
    , tdColorStriped = "rgba(250, 250, 252, 1)"
    , thColor = "rgba(250, 250, 252, 1)"
    , thColorHover = "rgba(243, 243, 247, 1)"
    , thColorSorting = "rgba(243, 243, 247, 1)"
    , tdColor = common.cardColor
    , tdTextColor = common.textColor2
    , thTextColor = common.textColor1
    , thFontWeight = common.fontWeightStrong
    , thButtonColorHover = common.tableColorHover
    , thIconColor = common.iconColor
    , thIconColorActive = common.primaryColor
    , borderColorModal = "rgba(239, 239, 245, 1)"
    , tdColorHoverModal = "rgba(247, 247, 250, 1)"
    , tdColorSortingModal = "rgba(247, 247, 250, 1)"
    , tdColorStripedModal = "rgba(250, 250, 252, 1)"
    , thColorModal = "rgba(250, 250, 252, 1)"
    , thColorHoverModal = "rgba(243, 243, 247, 1)"
    , thColorSortingModal = "rgba(243, 243, 247, 1)"
    , tdColorModal = common.modalColor
    , borderColorPopover = "rgba(239, 239, 245, 1)"
    , tdColorHoverPopover = "rgba(247, 247, 250, 1)"
    , tdColorSortingPopover = "rgba(247, 247, 250, 1)"
    , tdColorStripedPopover = "rgba(250, 250, 252, 1)"
    , thColorPopover = "rgba(250, 250, 252, 1)"
    , thColorHoverPopover = "rgba(243, 243, 247, 1)"
    , thColorSortingPopover = "rgba(243, 243, 247, 1)"
    , tdColorPopover = common.popoverColor
    , boxShadowBefore = "inset -12px 0 8px -12px rgba(0, 0, 0, .18)"
    , boxShadowAfter = "inset 12px 0 8px -12px rgba(0, 0, 0, .18)"
    , loadingColor = common.primaryColor
    , loadingSize = common.heightSmall
    , opacityLoading = common.opacityDisabled
    }


dark : Common -> Vars
dark common =
    { thPaddingSmall = "8px"
    , thPaddingMedium = "12px"
    , thPaddingLarge = "12px"
    , tdPaddingSmall = "8px"
    , tdPaddingMedium = "12px"
    , tdPaddingLarge = "12px"
    , sorterSize = "15px"
    , resizableContainerSize = "8px"
    , resizableSize = "2px"
    , filterSize = "15px"
    , paginationMargin = "12px 0 0 0"
    , emptyPadding = "48px 0"
    , actionPadding = "8px 12px"
    , actionButtonMargin = "0 8px 0 0"
    , actionDividerColor = common.dividerColor
    , lineHeight = common.lineHeight
    , borderRadius = common.borderRadius
    , fontSizeSmall = common.fontSizeSmall
    , fontSizeMedium = common.fontSizeMedium
    , fontSizeLarge = common.fontSizeLarge
    , borderColor = "rgba(45, 45, 48, 1)"
    , tdColorHover = "rgba(38, 38, 42, 1)"
    , tdColorSorting = "rgba(38, 38, 42, 1)"
    , tdColorStriped = "rgba(36, 36, 39, 1)"
    , thColor = "rgba(38, 38, 42, 1)"
    , thColorHover = "rgba(51, 51, 55, 1)"
    , thColorSorting = "rgba(51, 51, 55, 1)"
    , tdColor = common.cardColor
    , tdTextColor = common.textColor2
    , thTextColor = common.textColor1
    , thFontWeight = common.fontWeightStrong
    , thButtonColorHover = common.tableColorHover
    , thIconColor = common.iconColor
    , thIconColorActive = common.primaryColor
    , borderColorModal = "rgba(63, 63, 68, 1)"
    , tdColorHoverModal = "rgba(57, 57, 62, 1)"
    , tdColorSortingModal = "rgba(57, 57, 62, 1)"
    , tdColorStripedModal = "rgba(55, 55, 60, 1)"
    , thColorModal = "rgba(57, 57, 62, 1)"
    , thColorHoverModal = "rgba(69, 69, 74, 1)"
    , thColorSortingModal = "rgba(69, 69, 74, 1)"
    , tdColorModal = common.modalColor
    , borderColorPopover = "rgba(88, 88, 94, 1)"
    , tdColorHoverPopover = "rgba(83, 83, 89, 1)"
    , tdColorSortingPopover = "rgba(83, 83, 89, 1)"
    , tdColorStripedPopover = "rgba(81, 81, 87, 1)"
    , thColorPopover = "rgba(83, 83, 89, 1)"
    , thColorHoverPopover = "rgba(93, 93, 99, 1)"
    , thColorSortingPopover = "rgba(93, 93, 99, 1)"
    , tdColorPopover = common.popoverColor
    , boxShadowBefore = "inset -12px 0 8px -12px rgba(0, 0, 0, .36)"
    , boxShadowAfter = "inset 12px 0 8px -12px rgba(0, 0, 0, .36)"
    , loadingColor = common.primaryColor
    , loadingSize = common.heightSmall
    , opacityLoading = common.opacityDisabled
    }
