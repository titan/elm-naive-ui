module NUI.Theme.Equation exposing (Vars, vars)

{-| Theme variables for **Equation** (upstream `src/Equation/styles/light.ts` & `dark.ts`, cssr
selfVars). Fields map 1:1 onto the component's `--n-*` custom properties
(kebab-case of the field name). `vars` resolves the light/dark palette from
`theme.mode` + `theme.common` — upstream's `self(common)`; override individual
fields to customise.

@docs Vars, vars

-}

import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Common exposing (Common)


{-| The Equation theme record — empty because upstream's Equation selfVars
ships no themed CSS of its own; it exists only so the resolver shares the same
shape as every other `NUI.Theme.*` module.
-}
type alias Vars =
    {}


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
    {}


dark : Common -> Vars
dark common =
    {}
