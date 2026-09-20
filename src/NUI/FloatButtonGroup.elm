module NUI.FloatButtonGroup exposing
    ( Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `FloatButtonGroup`, rebuilt on elm-ui.

    import NUI.FloatButtonGroup exposing (defaults)

    NUI.FloatButtonGroup.view theme
        defaults
        [ NUI.FloatButton.view theme NUI.FloatButton.defaults [ Element.text "1" ] ]

    NUI.FloatButtonGroup.view theme
        { defaults
            | shape = NUI.FloatButton.Square
            , right = Just (NUI.FloatButton.Px 40)
            , bottom = Just (NUI.FloatButton.Px 40)
        }
        [ NUI.FloatButton.view theme NUI.FloatButton.defaults [ Element.text "1" ] ]

The group is Naive UI's own markup — `div.n-float-button-group` (`role="group"`)
with the `--{shape}-shape` modifier, the `--n-*` custom properties, and the
inline `position` / `left` / `right` / `top` / `bottom` Naive UI merges into the
same `style` attribute.

**Shape is not injected.** Upstream `provide`s the group's `shape` so every
`NFloatButton` child follows it; `NUI.FloatButton` takes its own `shape`, so
pass the group's value to each button yourself.

**Root layout.** Upstream renders a plain block `div`: the square shape's
`display: flex; flex-direction: column` comes from the extracted stylesheet
(which out-specifies elm-ui's own classes), and the circle shape stacks its
buttons the way a block container would — an `Element.column` root reproduces
both.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.FloatButton as FloatButton
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.FloatButtonGroup as GroupTheme


type alias Options msg =
    { shape : FloatButton.Shape
    , position : FloatButton.Position
    , left : Maybe FloatButton.Length
    , right : Maybe FloatButton.Length
    , top : Maybe FloatButton.Length
    , bottom : Maybe FloatButton.Length
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { shape = FloatButton.Circle
    , position = FloatButton.Fixed
    , left = Nothing
    , right = Nothing
    , top = Nothing
    , bottom = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.column
        ([ I.classes
            [ "n-float-button-group"
            , "n-float-button-group--" ++ shapeClass opts.shape ++ "-shape"
            ]
         , I.cssVars (cssVarsFor theme ++ layoutStyle opts)
         , Element.htmlAttribute (HA.attribute "role" "group")
         ]
            ++ opts.attributes
        )
        children


{-| The group's `--n-*` custom properties (Naive UI's `cssVarsRef`, themed half);
none of them depend on the options. Exposed so the output can be asserted
directly; `view` uses exactly this.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            GroupTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-color", v.color )
    , ( "--n-button-border-color", v.buttonBorderColor )
    , ( "--n-border-radius-square", v.borderRadiusSquare )
    ]


{-| The inline layout declarations upstream merges into the same `style`
attribute: `position` always, an offset only when set — Naive UI's
`formatLength x || ''` renders nothing for an unset offset.
-}
layoutStyle : Options msg -> List ( String, String )
layoutStyle opts =
    ( "position", positionValue opts.position )
        :: List.filterMap identity
            [ Maybe.map (\l -> ( "left", formatLength l )) opts.left
            , Maybe.map (\l -> ( "right", formatLength l )) opts.right
            , Maybe.map (\l -> ( "top", formatLength l )) opts.top
            , Maybe.map (\l -> ( "bottom", formatLength l )) opts.bottom
            ]


{-| Mirrors `NUI.FloatButton`'s private `formatLength` (upstream's
`formatLength`): a pixel count becomes `"Npx"` (`0` stays bare), a pure-number
string gains a `px` unit, anything else passes through.
-}
formatLength : FloatButton.Length -> String
formatLength length =
    case length of
        FloatButton.Px n ->
            if n == 0 then
                "0"

            else
                String.fromInt n ++ "px"

        FloatButton.Custom s ->
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


shapeClass : FloatButton.Shape -> String
shapeClass shape =
    case shape of
        FloatButton.Circle ->
            "circle"

        FloatButton.Square ->
            "square"


positionValue : FloatButton.Position -> String
positionValue position =
    case position of
        FloatButton.Relative ->
            "relative"

        FloatButton.Absolute ->
            "absolute"

        FloatButton.Fixed ->
            "fixed"
