module Showcase exposing (capitalize, chip, codeHljs, darkTheme, demoRow, fakeKatex, fakeKatexDisplay, purple, section, starIcon, theme)

{-| Shared showcase chrome: the theme set, the section/demoRow scaffolding,
and the cross-family fixtures (a fake highlight.js, fake katex closures, a
star glyph) used by more than one section family. Used by the static page
(Main / Sections/_) and every Live/_ interactive family module, so live
demos read exactly like the static ones.
-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Code as Code
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



-- CROSS-FAMILY FIXTURES (moved from Main.elm — used by 2+ section families)


{-| A small inline SVG glyph for the icon showcase (and the menu demos).
-}
starIcon : Element msg
starIcon =
    Element.html
        (Html.node "svg"
            [ HA.attribute "viewBox" "0 0 24 24"
            , HA.attribute "aria-hidden" "true"
            ]
            [ Html.node "path"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "d" "M12 2l2.9 6.3 6.9.8-5.1 4.7 1.4 6.8L12 17.3 5.9 20.6l1.4-6.8L2.2 9.1l6.9-.8z"
                ]
                []
            ]
        )


{-| A deterministic stand-in for highlight.js (the port never ships one): it
recognises two languages and wraps each input in one token span.
-}
codeHljs : Code.Hljs
codeHljs =
    let
        tokenClass lang =
            if lang == "elm" then
                "hljs-string"

            else
                "hljs-keyword"
    in
    { getLanguage = \lang -> List.member lang [ "javascript", "elm" ]
    , highlight = \code lang -> "<span class=\"" ++ tokenClass lang ++ "\">" ++ code ++ "</span>"
    }


{-| A deterministic stand-in for KaTeX's `renderToString` (inline shape).
-}
fakeKatex : String -> String
fakeKatex value =
    "<span class=\"katex\"><span class=\"katex-mathml\">" ++ value ++ "</span></span>"


{-| The `katex-display` shape (a block wrapper).
-}
fakeKatexDisplay : String -> String
fakeKatexDisplay value =
    "<div class=\"katex-display\">" ++ value ++ "</div>"
