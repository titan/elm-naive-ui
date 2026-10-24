module NUI.Rate exposing (Options, Size(..), cssVarsFor, defaults, view)

{-| Naive UI's `Rate`, rebuilt on elm-ui.

    import NUI.Rate exposing (defaults)

    NUI.Rate.view theme { defaults | value = Just 4 }

    NUI.Rate.view theme
        { defaults | allowHalf = True, value = Just 3.5 }

The element carries the `.n-rate` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

**Runtime.** Upstream tracks the hovered value internally (and derives a half
value from the pointer's `offsetX`); this library is pure, so the caller owns
the hovered value (`hoverValue`) and the selected value. Upstream's default slot
(one custom icon per index, receiving `{ index }`) is not modelled — the default
star icon is always rendered. `readonly` drops the item click handler, and
`onSelect` receives the derived value Naive UI reports (`index + 1`; the `+ 0.5`
half step depends on pointer geometry the caller owns). Naive UI's `clearable`
click-to-clear is the caller's decision inside `onSelect`.

@docs Options, Size, cssVarsFor, defaults, view

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Rate as RateTheme
import Svg


{-| The item size — Naive UI's `size` prop (`small | medium | large`, or a number
of pixels).
-}
type Size
    = Small
    | Medium
    | Large
    | Px Int


{-| The rate options — Naive UI's props plus the caller-owned hover state:
`count` stars, the selected `value`, the `hoverValue` (upstream's internal
`hoverIndex`; drives `--active` while hovering), `allowHalf`, `readonly`
(no click handlers), `size`, the `color` override for the active star,
`onSelect` (receiving `index + 1`), and `attributes`.
-}
type alias Options msg =
    { count : Int
    , value : Maybe Float
    , hoverValue : Maybe Float
    , allowHalf : Bool
    , readonly : Bool
    , size : Size
    , color : Maybe String
    , onSelect : Maybe (Float -> msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults: 5 stars, nothing selected or hovered, whole-star
steps, interactive `medium` stars, the theme's active color, no handler.
-}
defaults : Options msg
defaults =
    { count = 5
    , value = Nothing
    , hoverValue = Nothing
    , allowHalf = False
    , readonly = False
    , size = Medium
    , color = Nothing
    , onSelect = Nothing
    , attributes = []
    }


{-| The `n-rate` element — `count` star items (`.n-rate__item`, with an
overlaid `__half` star per item under `allowHalf`), each `--active` per
`itemActive` / `halfActive`, clickable (unless `readonly`) with
`onSelect (index + 1)`.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.row
        (I.classes ([ "n-rate" ] ++ I.classIf opts.readonly "n-rate--readonly")
            :: I.cssVars (cssVarsFor theme opts)
            :: opts.attributes
        )
        (List.range 0 (opts.count - 1) |> List.map (renderItem opts))


renderItem : Options msg -> Int -> Element msg
renderItem opts index =
    let
        halfNode =
            if opts.allowHalf then
                [ Element.row
                    [ I.classes
                        ([ "n-rate__half" ]
                            ++ I.classIf (halfActive opts index) "n-rate__half--active"
                        )
                    ]
                    [ starIcon ]
                ]

            else
                []
    in
    Element.row
        ([ I.classes
            ([ "n-rate__item" ]
                ++ I.classIf (itemActive opts index) "n-rate__item--active"
            )
         ]
            ++ selectAttrs opts index
        )
        (starIcon :: halfNode)


selectAttrs : Options msg -> Int -> List (Element.Attribute msg)
selectAttrs opts index =
    if opts.readonly then
        []

    else
        case opts.onSelect of
            Just toMsg ->
                [ Events.onClick (toMsg (toFloat (index + 1))) ]

            Nothing ->
                []


{-| `hoverIndex !== null ? index + 1 <= hoverIndex : index + 1 <= (value || 0)`.
-}
itemActive : Options msg -> Int -> Bool
itemActive opts index =
    case opts.hoverValue of
        Just hover ->
            toFloat (index + 1) <= hover

        Nothing ->
            toFloat (index + 1) <= Maybe.withDefault 0 opts.value


{-| `!active && hoverIndex !== null ? index + 0.5 <= hoverIndex : index + 0.5 <= (value || 0)`.
-}
halfActive : Options msg -> Int -> Bool
halfActive opts index =
    if not (itemActive opts index) && opts.hoverValue /= Nothing then
        toFloat index + 0.5 <= Maybe.withDefault 0 opts.hoverValue

    else
        toFloat index + 0.5 <= Maybe.withDefault 0 opts.value


{-| The rate's `--n-*` custom properties (`--n-item-color-active` is the `color`
option when given).
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            RateTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-item-color", v.itemColor )
    , ( "--n-item-color-active", Maybe.withDefault v.itemColorActive opts.color )
    , ( "--n-item-size", sizeValue opts.size v )
    ]


sizeValue : Size -> RateTheme.Vars -> String
sizeValue size v =
    case size of
        Small ->
            v.sizeSmall

        Medium ->
            v.sizeMedium

        Large ->
            v.sizeLarge

        Px n ->
            String.fromInt n ++ "px"



-- ICON (Naive UI renders this through NBaseIcon: an `<i class="n-base-icon">`)


starIcon : Element msg
starIcon =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ starSvg ])


starSvg : Html.Html msg
starSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 512 512" ]
        [ Svg.node "path" [ HA.attribute "d" starPath ] [] ]


starPath : String
starPath =
    "M394 480a16 16 0 01-9.39-3L256 383.76 127.39 477a16 16 0 01-24.55-18.08L153 310.35 23 221.2a16 16 0 019-29.2h160.38l48.4-148.95a16 16 0 0130.44 0l48.4 149H480a16 16 0 019.05 29.2L359 310.35l50.13 148.53A16 16 0 01394 480z"
