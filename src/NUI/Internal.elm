module NUI.Internal exposing (classIf, classes, cssVars)

{-| Small shared helpers used by every component.

Naive UI styles every component from two inputs:

1.  BEM class names on the element (`.n-button.n-button--primary`), which carry the
    static structure rules from `css/naive-ui.css`.
2.  `--n-*` CSS custom properties, which carry the themed values. Naive UI emits
    these as an inline `style` attribute; so do we.

Both are attached to elm-ui elements via `Element.htmlAttribute`.

-}

import Element exposing (Attribute)
import Html.Attributes as HA


{-| `classIf True "x" == [ "x" ]`, `classIf False "x" == []`. Compose a class list
with `List.concat`.
-}
classIf : Bool -> String -> List String
classIf cond c =
    if cond then
        [ c ]

    else
        []


classes : List String -> Attribute msg
classes =
    Element.htmlAttribute << HA.class << String.join " "


{-| Attach an inline `style` attribute built from `--n-*` custom properties.
`initial` values (Naive UI's "unset" marker) are dropped.
-}
cssVars : List ( String, String ) -> Attribute msg
cssVars vars =
    Element.htmlAttribute (HA.attribute "style" (renderVars vars))


renderVars : List ( String, String ) -> String
renderVars vars =
    vars
        |> List.filter (\( _, v ) -> v /= "initial" && not (String.isEmpty v))
        |> List.map (\( k, v ) -> k ++ ":" ++ v)
        |> String.join ";"
