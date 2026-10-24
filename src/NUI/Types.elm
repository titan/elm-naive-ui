module NUI.Types exposing (Size(..), Kind(..), sizeClass, kindClass)

{-| The two enums every `NUI.*` component takes — `Size` is Naive UI's `size`
prop and `Kind` its `type` prop, ported as Elm custom types with the
component-class suffix each constructor maps to (`sizeClass` /
`kindClass`).

    -- `NUI.Button.view theme { defaults | kind = NUI.Button.Primary } …`
    -- is rendered with the class `n-button--primary-type` (kindClass)
    kindClass Primary --> "primary"

Both scales are driven per component through its `Options` record
(`{ defaults | size = Small }`); the returned class suffix combines with the
component's BEM block for the final `n-{block}--{suffix}-type` form.

@docs Size, Kind, sizeClass, kindClass

-}


{-| Naive UI size scale (`size` prop) — `sizeClass` maps it to the class
suffix: `Tiny → "tiny"`, `Small → "small"`, `Medium → "medium"`,
`Large → "large"`.
-}
type Size
    = Tiny
    | Small
    | Medium
    | Large


{-| The class suffix for a size — `sizeClass Small == "small"`; components
emit it as `"n-{block}--" ++ sizeClass size ++ "-type"`.
-}
sizeClass : Size -> String
sizeClass size =
    case size of
        Tiny ->
            "tiny"

        Small ->
            "small"

        Medium ->
            "medium"

        Large ->
            "large"


{-| Naive UI status / colour scale (its `type` prop).
-}
type Kind
    = Default
    | Primary
    | Info
    | Success
    | Warning
    | Error


{-| The class suffix for a kind — `kindClass Primary == "primary"`; components
emit it as `"n-{block}--" ++ kindClass kind ++ "-type"`, the class behind
Naive UI's coloured variants (`.n-button--primary-type` …).
-}
kindClass : Kind -> String
kindClass kind =
    case kind of
        Default ->
            "default"

        Primary ->
            "primary"

        Info ->
            "info"

        Success ->
            "success"

        Warning ->
            "warning"

        Error ->
            "error"
