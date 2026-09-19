module NUI.FloatButton exposing
    ( Length(..)
    , Options
    , Position(..)
    , Shape(..)
    , Trigger(..)
    , Type(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `FloatButton`, rebuilt on elm-ui.

    NUI.FloatButton.view theme
        { NUI.FloatButton.defaults | type_ = NUI.FloatButton.Primary }
        [ Element.text "+" ]

    NUI.FloatButton.view theme
        { NUI.FloatButton.defaults | menuTrigger = Just NUI.FloatButton.Click }
        [ Element.text "+" ]

The element carries the `.n-float-button` BEM classes and Naive UI's `--n-*`
custom properties, and `NUI.Css` ships Naive UI's exact CSS.

**Runtime.** The floating position, size and side offsets are caller-owned (as in
Naive UI); `showMenu` is caller-owned too — the view emits the same classes and
inline style upstream computes, and reports opening/closing through
`onUpdateShowMenu` when `menuTrigger` is set. Upstream's group (`float-button-group`)
injection and the menu's click-propagation guard are not reproduced.

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.FloatButton as FloatButtonTheme


{-| The button's shape.
-}
type Shape
    = Circle
    | Square


{-| The button's colour type.
-}
type Type
    = Default
    | Primary


{-| The CSS `position` of the button.
-}
type Position
    = Relative
    | Absolute
    | Fixed


{-| How the menu opens (Naive UI's `menuTrigger`).
-}
type Trigger
    = Hover
    | Click


{-| A CSS length — a pixel count or a raw CSS length (`"50%"`).
-}
type Length
    = Px Int
    | Custom String


type alias Options msg =
    { shape : Shape
    , type_ : Type
    , position : Position
    , width : Length
    , height : Length
    , left : Maybe Length
    , right : Maybe Length
    , top : Maybe Length
    , bottom : Maybe Length
    , menuTrigger : Maybe Trigger
    , showMenu : Bool
    , description : Maybe (Element msg)
    , menu : List (Element msg)
    , onUpdateShowMenu : Maybe (Bool -> msg)
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { shape = Circle
    , type_ = Default
    , position = Fixed
    , width = Px 40
    , height = Px 40
    , left = Nothing
    , right = Nothing
    , top = Nothing
    , bottom = Nothing
    , menuTrigger = Nothing
    , showMenu = False
    , description = Nothing
    , menu = []
    , onUpdateShowMenu = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        classes =
            [ "n-float-button"
            , "n-float-button--" ++ shapeClass opts.shape ++ "-shape"
            , "n-float-button--" ++ typeClass opts.type_ ++ "-type"
            ]
                ++ I.classIf opts.showMenu "n-float-button--show-menu"

        descriptionNode =
            case opts.description of
                Just d ->
                    [ Element.el [ I.classes [ "n-float-button__description" ] ] d ]

                Nothing ->
                    []
    in
    Element.row
        ([ I.classes classes
         , I.cssVars (cssVarsFor theme opts ++ layoutStyle opts)
         , Element.htmlAttribute (HA.attribute "role" "button")
         ]
            ++ showMenuAttrs opts
            ++ opts.attributes
        )
        ([ Element.el
            [ I.classes [ "n-float-button__fill" ]
            , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
            ]
            Element.none
         , Element.row [ I.classes [ "n-float-button__body" ] ] (children ++ descriptionNode)
         ]
            ++ closeNode opts
            ++ menuNode opts
        )


{-| Upstream attaches `mouseenter` / `mouseleave` / `click` unconditionally and
gates them on `menuTrigger`; the pure view does the same with `showMenu`.
-}
showMenuAttrs : Options msg -> List (Element.Attribute msg)
showMenuAttrs opts =
    case ( opts.menuTrigger, opts.onUpdateShowMenu ) of
        ( Just Hover, Just toMsg ) ->
            Events.onMouseEnter (toMsg True)
                :: (if opts.showMenu then
                        [ Events.onMouseLeave (toMsg False) ]

                    else
                        []
                   )

        ( Just Click, Just toMsg ) ->
            [ Events.onClick (toMsg (not opts.showMenu)) ]

        _ ->
            []


closeNode : Options msg -> List (Element msg)
closeNode opts =
    case opts.menuTrigger of
        Just _ ->
            [ Element.row [ I.classes [ "n-float-button__close" ] ] [ closeIcon ] ]

        Nothing ->
            []


menuNode : Options msg -> List (Element msg)
menuNode opts =
    case opts.menuTrigger of
        Just _ ->
            [ Element.row
                [ I.classes [ "n-float-button__menu" ]
                , Element.htmlAttribute (HA.attribute "data-float-button-menu" "")
                ]
                opts.menu
            ]

        Nothing ->
            []


{-| The float button's `--n-*` custom properties (`type` selects the primary set).
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            FloatButtonTheme.vars theme

        primary =
            opts.type_ == Primary

        pick a b =
            if primary then
                a

            else
                b
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-box-shadow-hover", v.boxShadowHover )
    , ( "--n-box-shadow-pressed", v.boxShadowPressed )
    , ( "--n-color", pick v.colorPrimary v.color )
    , ( "--n-text-color", pick v.textColorPrimary v.textColor )
    , ( "--n-color-hover", pick v.colorPrimaryHover v.colorHover )
    , ( "--n-color-pressed", pick v.colorPrimaryPressed v.colorPressed )
    , ( "--n-border-radius-square", v.borderRadiusSquare )
    ]


{-| The inline layout properties (position, size and offsets) upstream sets
alongside the `--n-*` variables.
-}
layoutStyle : Options msg -> List ( String, String )
layoutStyle opts =
    List.filterMap identity
        [ Just ( "position", positionValue opts.position )
        , Just ( "width", formatLength opts.width )
        , Just ( "min-height", formatLength opts.height )
        , Maybe.map (\l -> ( "left", formatLength l )) opts.left
        , Maybe.map (\l -> ( "right", formatLength l )) opts.right
        , Maybe.map (\l -> ( "top", formatLength l )) opts.top
        , Maybe.map (\l -> ( "bottom", formatLength l )) opts.bottom
        ]


formatLength : Length -> String
formatLength length =
    case length of
        Px n ->
            if n == 0 then
                "0"

            else
                String.fromInt n ++ "px"

        Custom s ->
            -- Upstream's `formatLength`: a pure-number string gains a `px` unit
            -- (`"40"` -> `"40px"`); anything else passes through.
            if isPureNumber s then
                case String.toFloat s of
                    Just num ->
                        if num == 0 then
                            "0"

                        else
                            String.fromFloat num ++ "px"

                    Nothing ->
                        s

            else
                s


isPureNumber : String -> Bool
isPureNumber s =
    s /= "" && String.all (\c -> Char.isDigit c || c == '.') s


shapeClass : Shape -> String
shapeClass shape =
    case shape of
        Circle ->
            "circle"

        Square ->
            "square"


typeClass : Type -> String
typeClass type_ =
    case type_ of
        Default ->
            "default"

        Primary ->
            "primary"


positionValue : Position -> String
positionValue position =
    case position of
        Relative ->
            "relative"

        Absolute ->
            "absolute"

        Fixed ->
            "fixed"



-- ICON (Naive UI renders this through NBaseIcon: an `<i class="n-base-icon">`)


closeIcon : Element msg
closeIcon =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ closeSvg ])


closeSvg : Html.Html msg
closeSvg =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 12 12"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "aria-hidden" "true"
        ]
        [ Html.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Html.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Html.node "path" [ HA.attribute "d" closePath ] [] ]
            ]
        ]


closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91140884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91140884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,10.0488155 2.34170876,10.0488155 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 L2.14644661,2.14644661 L2.08859116,2.2156945 Z"
