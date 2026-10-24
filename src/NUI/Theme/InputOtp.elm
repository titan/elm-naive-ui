module NUI.Theme.InputOtp exposing (Vars, vars)

{-| Theme variables for the **InputOtp** component — the Elm counterpart of Naive
UI's `src/input-otp/styles/light.ts` & `dark.ts` cssr theme (selfVars). InputOtp renders
with Naive UI's original CSS, so each record field here is emitted as one `--n-*`
custom property on the component root, using the upstream kebab-case mapping
(`inputWidthSmall` → `--n-input-width-small`, `gapMedium` → `--n-gap-medium`, …).

`vars` plays the role of upstream `self()`: it switches on `theme.mode`
(Light/Dark) and picks the size-tuned slot geometry. Pass the result to InputOtp's
`view`, or override individual fields to customise the look.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| All `--n-*` custom properties the InputOtp CSS consumes, as one record. Fields
map 1:1 onto the component's `--n-<kebab-case-field>` custom properties
(`inputWidthSmall` → `--n-input-width-small`). Two groups: the per-size digit
slot widths (`inputWidthSmall/Medium/Large`) and the per-size gaps between slots
(`gapSmall/Medium/Large`).
-}
type alias Vars =
    { inputWidthSmall : String
    , inputWidthMedium : String
    , inputWidthLarge : String
    , gapSmall : String
    , gapMedium : String
    , gapLarge : String
    }


{-| Resolve the InputOtp theme variables — upstream's `self()` counterpart.
Switches on `theme.mode`: both palettes pick the size-tuned slot geometry
(24/30/36px slots with 8px gaps); only derived colour channels would differ,
and InputOtp's slots carry none.
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
    { inputWidthSmall = "24px"
    , inputWidthMedium = "30px"
    , inputWidthLarge = "36px"
    , gapSmall = "8px"
    , gapMedium = "8px"
    , gapLarge = "8px"
    }


dark : Common -> Vars
dark common =
    { inputWidthSmall = "24px"
    , inputWidthMedium = "30px"
    , inputWidthLarge = "36px"
    , gapSmall = "8px"
    , gapMedium = "8px"
    , gapLarge = "8px"
    }
