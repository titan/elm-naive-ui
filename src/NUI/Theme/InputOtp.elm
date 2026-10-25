module NUI.Theme.InputOtp exposing (Vars, vars)

{-| Theme variables for **InputOtp** (upstream `src/input-otp/styles/light.ts` & `dark.ts`, cssr
selfVars). Fields map 1:1 onto the component's `--n-*` custom properties
(kebab-case of the field name). `vars` resolves the light/dark palette from
`theme.mode` + `theme.common` — upstream's `self(common)`; override individual
fields to customise.

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


{-| Resolve the InputOtp variables — the size-tuned slot geometry
(24/30/36px slots, 8px gaps); identical in both modes.
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
