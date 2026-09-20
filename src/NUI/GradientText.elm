module NUI.GradientText exposing
    ( Gradient(..)
    , Options
    , Type(..)
    , cssVarsFor
    , defaults
    , fromTo
    , view
    )

{-| Naive UI's `GradientText`, rebuilt on elm-ui.

    import NUI.GradientText exposing (defaults)

    NUI.GradientText.view theme
        { defaults | type_ = NUI.GradientText.Success }
        [ Element.text "Wonderful" ]

Upstream's `color` and `gradient` props are aliases for the same value; here they
are one field, `gradient`. The element carries the `.n-gradient-text` BEM classes
and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.GradientText as GradientTextTheme


{-| Naive UI's `type` (its `danger` value is an alias of `error`).
-}
type Type
    = Primary
    | Info
    | Success
    | Warning
    | Error


{-| The `color` / `gradient` prop. `Raw` is upstream's string form (any CSS
`background-image` value, e.g. `"linear-gradient(...)"`); `FromTo` is the object
form, serialised to `linear-gradient(<deg>deg, <from> 0%, <to> 100%)`.
-}
type Gradient
    = Raw String
    | FromTo { deg : String, from : String, to : String }


{-| The object form with `deg = 0`.
-}
fromTo : String -> String -> Gradient
fromTo from to =
    FromTo { deg = "0", from = from, to = to }


type alias Options msg =
    { type_ : Type
    , size : Maybe String
    , gradient : Maybe Gradient
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { type_ = Primary
    , size = Nothing
    , gradient = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.paragraph
        (I.classes
            [ "n-gradient-text"
            , "n-gradient-text--" ++ typeClass opts.type_ ++ "-type"
            ]
            :: I.cssVars (inlineStyles opts ++ cssVarsFor theme opts)
            :: opts.attributes
        )
        children


{-| The `--n-*` custom properties for these options, before the inline plain
properties are prepended (see `inlineStyles`). Exposed so the output can be
asserted directly.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            GradientTextTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-rotate", v.rotate )
    , ( "--n-color-start", colorStart opts.type_ v )
    , ( "--n-color-end", colorEnd opts.type_ v )
    , ( "--n-font-weight", v.fontWeight )
    ]


{-| Upstream's `style={{ fontSize, backgroundImage }}` — merged with the `--n-*`
vars into the single inline `style` attribute `view` emits (the library's
`key:value` convention, as in `NUI.Skeleton`).
-}
inlineStyles : Options msg -> List ( String, String )
inlineStyles opts =
    List.filterMap identity
        [ Maybe.map (\s -> ( "font-size", s )) opts.size
        , Maybe.map (\g -> ( "background-image", backgroundImage g )) opts.gradient
        ]


backgroundImage : Gradient -> String
backgroundImage g =
    case g of
        Raw s ->
            s

        FromTo { deg, from, to } ->
            "linear-gradient(" ++ deg ++ "deg, " ++ from ++ " 0%, " ++ to ++ " 100%)"


typeClass : Type -> String
typeClass t =
    case t of
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


{-| Naive UI's `createKey('colorStart', type)`.
-}
colorStart : Type -> GradientTextTheme.Vars -> String
colorStart t v =
    case t of
        Primary ->
            v.colorStartPrimary

        Info ->
            v.colorStartInfo

        Success ->
            v.colorStartSuccess

        Warning ->
            v.colorStartWarning

        Error ->
            v.colorStartError


colorEnd : Type -> GradientTextTheme.Vars -> String
colorEnd t v =
    case t of
        Primary ->
            v.colorEndPrimary

        Info ->
            v.colorEndInfo

        Success ->
            v.colorEndSuccess

        Warning ->
            v.colorEndWarning

        Error ->
            v.colorEndError
