module NUI.Affix exposing (Options, Position(..), defaults, view)

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

@docs Options, Position, defaults, view

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)


{-| Naive UI's `position` — how the affixed element is pinned.
-}
type Position
    = Fixed
    | Absolute


{-| The affix options. `affixed` is the caller-owned pinned state (upstream
derives it from `scroll` events on the listen target); `top` / `bottom` are
the sticky offsets, emitted as an inline style only while affixed; `position`
switches the pinning mode (`Absolute` adds `n-affix--absolute-positioned`).
-}
type alias Options msg =
    { affixed : Bool
    , position : Position
    , top : Maybe Int
    , bottom : Maybe Int
    , attributes : List (Element.Attribute msg)
    }


{-| Un-pinned defaults: `Fixed` positioning, no offsets, no extra attributes.
-}
defaults : Options msg
defaults =
    { affixed = False
    , position = Fixed
    , top = Nothing
    , bottom = Nothing
    , attributes = []
    }


{-| Render the affix wrapper around `children`. While `affixed` the element
carries `n-affix--affixed` (plus `n-affix--absolute-positioned` when
`position = Absolute`) and the `top` / `bottom` offsets as an inline style —
exactly upstream's `mergedstyle`; at rest it is a bare `n-affix` column
carrying `attributes`.
-}
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
