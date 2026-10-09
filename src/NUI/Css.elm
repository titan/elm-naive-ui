module NUI.Css exposing
    ( css
    , element
    , elementNode
    , layout
    , rootAttribute
    )

{-| Ships Naive UI's stylesheet and the scope marker it relies on.

The CSS is generated from Naive UI's own cssr sources (see `tools/`) and embedded so
the package is self-contained — no separate `.css` import needed. Every rule is
scoped under `.nui-root`, so an ancestor element must carry the marker class.
`layout` (drop-in for `Element.layout`) sets it for you, and `element` renders the
stylesheet node.

    view model =
        NUI.Css.layout []
            (Element.column [ spacing 16 ]
                [ NUI.Css.element
                , NUI.Button.view theme NUI.Button.defaults [ Element.text "Hello" ]
                ]
            )

-}

import Element exposing (Attribute, Element)
import Html
import Html.Attributes as HA
import NUI.Css.Generated as Generated


{-| The full stylesheet as a string (for a `<link>`/inline `<style>` approach).
-}
css : String
css =
    Generated.all


{-| A `<style>` node. Include it once near the root of your app.
-}
element : Element msg
element =
    Element.html elementNode


{-| The raw `<style>` node behind `element` — for callers that memoize the
node themselves (e.g. `Html.Lazy.lazy`, so a per-msg diff skips the large
constant text child).
-}
elementNode : Html.Html msg
elementNode =
    Html.node "style" [] [ Html.text css ]


{-| The class the generated stylesheet is scoped under. Add it to (an ancestor of)
your components.
-}
rootAttribute : Attribute msg
rootAttribute =
    Element.htmlAttribute (HA.class "nui-root")


{-| Drop-in replacement for `Element.layout` that adds `rootAttribute`.
-}
layout : List (Attribute msg) -> Element msg -> Html.Html msg
layout attrs content =
    Element.layout (rootAttribute :: attrs) content
