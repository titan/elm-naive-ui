module Showcase exposing (capitalize, chip, darkTheme, demoRow, purple, section, theme)

{-| Shared showcase chrome: the theme set and the section/demoRow scaffolding.
Used by the static page (Main) and every Live/\* interactive family module, so
live demos read exactly like the static ones.
-}

import Element exposing (Element)
import NUI.Divider as Divider
import NUI.Tag as Tag
import NUI.Theme as Theme exposing (Theme)
import NUI.Typography as Typo



-- THEMES


theme : Theme
theme =
    Theme.default


purple : Theme
purple =
    Theme.setPrimary "#7c3aed" theme


darkTheme : Theme
darkTheme =
    Theme.dark



-- CHROME


typ : Typo.Options msg
typ =
    Typo.defaults


divD : Divider.Options msg
divD =
    Divider.defaults


tagD : Tag.Options msg
tagD =
    Tag.defaults


{-| A titled block: heading, description, examples, then a divider.
-}
section : String -> String -> List (Element msg) -> Element msg
section title desc examples =
    Element.column [ Element.spacing 16, Element.width Element.fill ]
        [ Typo.h3 theme typ [ Element.text title ]
        , Typo.text theme { typ | depth = Just 3 } [ Element.text desc ]
        , Element.column [ Element.spacing 20, Element.width Element.fill ] examples
        , Divider.view theme divD []
        ]


{-| A labelled, wrapping row of examples.
-}
demoRow : String -> List (Element msg) -> Element msg
demoRow label items =
    Element.column [ Element.spacing 10, Element.width Element.fill ]
        [ Typo.text theme { typ | depth = Just 4, size = Just 12 } [ Element.text (String.toUpper label) ]
        , Element.wrappedRow [ Element.spacing 12 ] items
        ]


chip : String -> Element msg
chip label =
    Tag.view theme { tagD | bordered = False } [ Element.text label ]


capitalize : String -> String
capitalize s =
    String.toUpper (String.left 1 s) ++ String.dropLeft 1 s
