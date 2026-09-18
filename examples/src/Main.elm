module Main exposing (main)

import Element exposing (Element)
import Element.Background as Bg
import Element.Border as Border
import Element.Font as Font
import Html
import NUI.Button as Button
import NUI.Css as Css
import NUI.Theme as Theme exposing (Theme)
import NUI.Types as T


theme : Theme
theme =
    Theme.default


base : Button.Options msg
base =
    Button.defaults


main : Html.Html msg
main =
    Css.layout [] page


page : Element msg
page =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.padding 32
        , Element.spacing 24
        , Bg.color (Element.rgb 1 1 1)
        , Font.family [ Font.typeface "system-ui", Font.sansSerif ]
        , Font.size 14
        ]
        [ Css.element
        , heading "Button · sizes"
        , row (List.map sizeButton [ T.Tiny, T.Small, T.Medium, T.Large ])
        , heading "Button · types"
        , row
            (List.map
                (\k -> Button.view theme { base | kind = k } [ Element.text (kindLabel k) ])
                [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
            )
        , heading "Button · variants"
        , row
            [ Button.view theme { base | variant = Button.Secondary, kind = T.Primary } [ Element.text "Secondary" ]
            , Button.view theme { base | variant = Button.Tertiary, kind = T.Primary } [ Element.text "Tertiary" ]
            , Button.view theme { base | variant = Button.Quaternary, kind = T.Primary } [ Element.text "Quaternary" ]
            , Button.view theme { base | variant = Button.Text, kind = T.Primary } [ Element.text "Text" ]
            ]
        , heading "Button · shapes & states"
        , row
            [ Button.view theme { base | round = True } [ Element.text "Round" ]
            , Button.view theme { base | circle = True } [ Element.text "C" ]
            , Button.view theme { base | dashed = True } [ Element.text "Dashed" ]
            , Button.view theme { base | ghost = True, kind = T.Primary } [ Element.text "Ghost" ]
            , Button.view theme { base | disabled = True } [ Element.text "Disabled" ]
            , Button.view theme { base | loading = True } [ Element.text "Loading" ]
            ]
        , heading "Button · block"
        , Element.el [ Element.width (Element.px 320) ]
            (Button.view theme { base | block = True } [ Element.text "Block" ])
        ]


heading : String -> Element msg
heading t =
    Element.el [ Font.size 13, Font.color (Element.rgb 0.46 0.49 0.51) ] (Element.text t)


row : List (Element msg) -> Element msg
row =
    Element.row [ Element.spacing 12, Element.alignLeft ]


sizeButton : T.Size -> Element msg
sizeButton s =
    Button.view theme { base | size = s } [ Element.text (T.sizeClass s |> capitalize) ]


capitalize : String -> String
capitalize s =
    String.toUpper (String.left 1 s) ++ String.dropLeft 1 s


kindLabel : T.Kind -> String
kindLabel k =
    capitalize (T.kindClass k)
