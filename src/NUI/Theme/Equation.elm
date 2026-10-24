module NUI.Theme.Equation exposing (Vars, vars)

{-| Theme variables for the **Equation** component — the Elm counterpart of Naive UI's
`src/Equation/styles/light.ts` & `dark.ts` cssr theme (selfVars). Equation renders with Naive UI's
original CSS, so each record field here is emitted as one `--n-*` custom property on the
component root, using the upstream kebab-case mapping (the record is empty — see below). Upstream's `Equation` selfVars is empty (the component ships no themed CSS of its own), so `Vars` is an empty record kept for API symmetry — see `NUI.Equation`.

`vars` plays the role of upstream `self(common)`: it switches on `theme.mode` (Light/Dark) and
derives every value from `theme.common` (see `NUI.Theme.Common`), reproducing Naive UI's light
and dark palettes value-for-value. Pass the result to Equation's `view`, or override individual
fields to customise the look.

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


{-| Resolve the Equation variables for a theme — upstream `self(common)`: Light and Dark
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
    {}


dark : Common -> Vars
dark common =
    {}
