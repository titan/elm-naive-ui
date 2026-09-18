module NUI.Types exposing (Kind(..), Size(..), kindClass, sizeClass)

{-| Public enums shared by every component (Naive UI's `size` and `type`).
-}


{-| Naive UI size scale.
-}
type Size
    = Tiny
    | Small
    | Medium
    | Large


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
