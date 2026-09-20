module NUI.Affix exposing
    ( Options
    , Position(..)
    , defaults
    , view
    )

{-| Naive UI's `Affix`, rebuilt on elm-ui.

    import NUI.Affix exposing (defaults)

    NUI.Affix.view theme
        { defaults | affixed = True, top = Just 12 }
        [ NUI.Button.view theme NUI.Button.defaults [ Element.text "Sticky" ] ]

The element carries the `.n-affix` BEM classes, and `NUI.Css` ships Naive UI's
exact CSS.

**Runtime.** Upstream decides `affixed` (and the sticky `top` / `bottom`) from
`scroll` events on a listen target. This library is pure, so the caller owns that
state and passes it in: `affixed` toggles `.n-affix--affixed` (`.n-affix--absolute-positioned`
with `position = Absolute`), and `top` / `bottom` are emitted as inline offsets
only while affixed — exactly upstream's `mergedstyle`.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)


{-| Naive UI's `position` — how the affixed element is pinned.
-}
type Position
    = Fixed
    | Absolute


type alias Options msg =
    { affixed : Bool
    , position : Position
    , top : Maybe Int
    , bottom : Maybe Int
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { affixed = False
    , position = Fixed
    , top = Nothing
    , bottom = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ opts children =
    let
        offsetStyle =
            if opts.affixed then
                List.filterMap identity
                    [ Maybe.map (\n -> ( "top", String.fromInt n ++ "px" )) opts.top
                    , Maybe.map (\n -> ( "bottom", String.fromInt n ++ "px" )) opts.bottom
                    ]

            else
                []
    in
    Element.column
        (I.classes
            ("n-affix"
                :: I.classIf opts.affixed "n-affix--affixed"
                ++ I.classIf (opts.position == Absolute) "n-affix--absolute-positioned"
            )
            :: styleAttr offsetStyle
            ++ opts.attributes
        )
        children


{-| Upstream emits the `style` object only when it has entries; so do we (an empty
`style=""` would otherwise appear).
-}
styleAttr : List ( String, String ) -> List (Element.Attribute msg)
styleAttr pairs =
    if List.isEmpty pairs then
        []

    else
        [ I.cssVars pairs ]
