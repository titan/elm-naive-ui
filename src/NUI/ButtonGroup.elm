module NUI.ButtonGroup exposing (Options, defaults, view)

{-| Naive UI's `ButtonGroup`, rebuilt on elm-ui.

    NUI.ButtonGroup.view theme
        NUI.ButtonGroup.defaults
        [ NUI.Button.view theme NUI.Button.defaults [ Element.text "Left" ]
        , NUI.Button.view theme NUI.Button.defaults [ Element.text "Right" ]
        ]

The group is Naive UI's own markup — `div.n-button-group` (`role="group"`) with
the `--vertical` / `--rtl` modifiers — so Naive UI's extracted CSS collapses the
adjacent buttons' borders and radii exactly as upstream.

Naive UI's group also _injects_ its `size` into the buttons it contains. That is
not modelled here: this library renders each `NUI.Button` independently, so every
button already carries its own `NUI.Button.Options.size`. Set the size on the
buttons directly.

@docs Options, defaults, view

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)


{-| The group options. `vertical` stacks the buttons (`--vertical`), `rtl`
mirrors the group (`--rtl`), `attributes` land on the `n-button-group` root.
Upstream's `size` injection is not modelled — set sizes on the buttons
themselves.
-}
type alias Options msg =
    { vertical : Bool
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults — horizontal, LTR, no extra attributes.
-}
defaults : Options msg
defaults =
    { vertical = False
    , rtl = False
    , attributes = []
    }


{-| The group container. The children are the buttons (any `Element msg`; the
extracted CSS targets `.n-button-group > .n-button`).
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ opts children =
    Element.row
        ([ I.classes
            ("n-button-group"
                :: I.classIf opts.rtl "n-button-group--rtl"
                ++ I.classIf opts.vertical "n-button-group--vertical"
            )
         , Element.htmlAttribute (HA.attribute "role" "group")
         ]
            ++ opts.attributes
        )
        children
