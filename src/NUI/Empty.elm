module NUI.Empty exposing
    ( Options
    , Size(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Empty`, rebuilt on elm-ui.

    import NUI.Empty exposing (defaults)

    NUI.Empty.view theme NUI.Empty.defaults []

    NUI.Empty.view theme
        { defaults
            | description = Just "Nothing here"
            , size = NUI.Empty.Huge
        }
        []

Children fill the description slot; when they are empty the `description`
option is rendered instead, falling back to Naive UI's localized default
("No Data").

The visual result is Naive UI's own: the element carries the `.n-empty` BEM
classes and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive
UI's exact CSS.

Empty also accepts a `huge` size, so it keeps its own `Size` instead of
`NUI.Types.Size` (and Naive UI renders no size class on the root — the size
only feeds `--n-icon-size` / `--n-font-size`).

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Empty as EmptyTheme
import Svg
import Svg.Attributes as SA


{-| Naive UI size scale; Empty supports `huge` in addition to the shared scale.
-}
type Size
    = Tiny
    | Small
    | Medium
    | Large
    | Huge


type alias Options msg =
    { description : Maybe String
    , showDescription : Bool
    , showIcon : Bool
    , size : Size
    , icon : Maybe (Element msg)
    , extra : Maybe (Element msg)
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { description = Nothing
    , showDescription = True
    , showIcon = True
    , size = Medium
    , icon = Nothing
    , extra = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        iconEl =
            if opts.showIcon then
                [ Element.el [ I.classes [ "n-empty__icon" ] ] (iconContent opts.icon) ]

            else
                []

        descriptionChildren =
            if List.isEmpty children then
                [ Element.text (localizedDescription opts.description) ]

            else
                children

        descriptionEl =
            if opts.showDescription then
                [ Element.paragraph
                    [ I.classes [ "n-empty__description" ], Element.spacing 0 ]
                    descriptionChildren
                ]

            else
                []

        extraEl =
            case opts.extra of
                Just e ->
                    [ Element.el [ I.classes [ "n-empty__extra" ] ] e ]

                Nothing ->
                    []
    in
    Element.column
        ([ I.classes [ "n-empty" ]
         , I.cssVars (cssVarsFor theme opts)
         ]
            ++ opts.attributes
        )
        (iconEl ++ descriptionEl ++ extraEl)


{-| A provided `icon` replaces the `n-base-icon` wrapper entirely (Naive UI's
`icon` slot takes the place of `NBaseIcon` inside `.n-empty__icon`); the
default icon is the `EmptyIcon` SVG wrapped in Naive UI's `<i class="n-base-icon">`.
-}
iconContent : Maybe (Element msg) -> Element msg
iconContent maybeIcon =
    case maybeIcon of
        Just custom ->
            custom

        Nothing ->
            Element.html
                (Html.i
                    [ HA.class "n-base-icon" ]
                    [ emptyIcon ]
                )


{-| Naive UI's `mergedDescription || localeRef.description`: the prop wins,
except that an empty string falls back to the locale default like JS
truthiness does.
-}
localizedDescription : Maybe String -> String
localizedDescription maybeDescription =
    case maybeDescription of
        Just d ->
            if String.isEmpty d then
                defaultDescription

            else
                d

        Nothing ->
            defaultDescription


{-| The enUS locale's `Empty.description`, Naive UI's default.
-}
defaultDescription : String
defaultDescription =
    "No Data"


{-| The raw `--n-*` custom properties an empty state with these options
attaches (before `NUI.Internal.renderVars` drops `initial`/empty values).
Exposed so the `--n-*` output can be asserted directly; `view` uses exactly
this. Sizes are Naive UI's `createKey('iconSize', size)` / `createKey('fontSize', size)`.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            EmptyTheme.vars theme
    in
    [ ( "--n-icon-size", iconSizeOf opts.size v )
    , ( "--n-font-size", fontSizeOf opts.size v )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-text-color", v.textColor )
    , ( "--n-icon-color", v.iconColor )
    , ( "--n-extra-text-color", v.extraTextColor )
    ]


iconSizeOf : Size -> EmptyTheme.Vars -> String
iconSizeOf size v =
    case size of
        Tiny ->
            v.iconSizeTiny

        Small ->
            v.iconSizeSmall

        Medium ->
            v.iconSizeMedium

        Large ->
            v.iconSizeLarge

        Huge ->
            v.iconSizeHuge


fontSizeOf : Size -> EmptyTheme.Vars -> String
fontSizeOf size v =
    case size of
        Tiny ->
            v.fontSizeTiny

        Small ->
            v.fontSizeSmall

        Medium ->
            v.fontSizeMedium

        Large ->
            v.fontSizeLarge

        Huge ->
            v.fontSizeHuge


{-| Naive UI's default `Empty` icon (`src/_internal/icons/Empty.tsx`): a
28×28 SVG with two `fill="currentColor"` paths. Sizing comes from the shipped
`.n-base-icon svg { height: 1em; width: 1em; }` rule, so no width/height
attributes are set — exactly as upstream.
-}
emptyIcon : Svg.Svg msg
emptyIcon =
    Svg.svg
        [ SA.viewBox "0 0 28 28"
        , SA.fill "none"
        ]
        [ Svg.path
            [ SA.d emptyIconPathCross
            , SA.fill "currentColor"
            ]
            []
        , Svg.path
            [ SA.d emptyIconPathBox
            , SA.fill "currentColor"
            ]
            []
        ]


{-| The crossed-out circle top-right of the box.
-}
emptyIconPathCross : String
emptyIconPathCross =
    "M26 7.5C26 11.0899 23.0899 14 19.5 14C15.9101 14 13 11.0899 13 7.5C13 3.91015 15.9101 1 19.5 1C23.0899 1 26 3.91015 26 7.5ZM16.8536 4.14645C16.6583 3.95118 16.3417 3.95118 16.1464 4.14645C15.9512 4.34171 15.9512 4.65829 16.1464 4.85355L18.7929 7.5L16.1464 10.1464C15.9512 10.3417 15.9512 10.6583 16.1464 10.8536C16.3417 11.0488 16.6583 11.0488 16.8536 10.8536L19.5 8.20711L22.1464 10.8536C22.3417 11.0488 22.6583 11.0488 22.8536 10.8536C23.0488 10.6583 23.0488 10.3417 22.8536 10.1464L20.2071 7.5L22.8536 4.85355C23.0488 4.65829 23.0488 4.34171 22.8536 4.14645C22.6583 3.95118 22.3417 3.95118 22.1464 4.14645L19.5 6.79289L16.8536 4.14645Z"


{-| The open box with the floating document.
-}
emptyIconPathBox : String
emptyIconPathBox =
    "M25 22.75V12.5991C24.5572 13.0765 24.053 13.4961 23.5 13.8454V16H17.5L17.3982 16.0068C17.0322 16.0565 16.75 16.3703 16.75 16.75C16.75 18.2688 15.5188 19.5 14 19.5C12.4812 19.5 11.25 18.2688 11.25 16.75L11.2432 16.6482C11.1935 16.2822 10.8797 16 10.5 16H4.5V7.25C4.5 6.2835 5.2835 5.5 6.25 5.5H12.2696C12.4146 4.97463 12.6153 4.47237 12.865 4H6.25C4.45507 4 3 5.45507 3 7.25V22.75C3 24.5449 4.45507 26 6.25 26H21.75C23.5449 26 25 24.5449 25 22.75ZM4.5 22.75V17.5H9.81597L9.85751 17.7041C10.2905 19.5919 11.9808 21 14 21L14.215 20.9947C16.2095 20.8953 17.842 19.4209 18.184 17.5H23.5V22.75C23.5 23.7165 22.7165 24.5 21.75 24.5H6.25C5.2835 24.5 4.5 23.7165 4.5 22.75Z"
