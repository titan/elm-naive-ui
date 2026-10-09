module Showcase exposing
    ( capitalize
    , chip
    , chromeCss
    , chromeCssNode
    , codeHljs
    , darkTheme
    , demoBox
    , demoRow
    , fakeKatex
    , fakeKatexDisplay
    , fillWidth
    , purple
    , section
    , sectionId
    , starIcon
    , theme
    )

{-| Shared showcase chrome: the theme set, the docs-style section/demo scaffolding,
and the cross-family fixtures (a fake highlight.js, fake katex closures, a star
glyph) used by more than one section family. Used by the static page
(Main / Sections/_) and every Live/_ interactive family module, so live demos
read exactly like the static ones.

The page chrome itself (top bar, sticky sidebar, content column) lives in
Main.elm; this module owns the pieces every section shares:

  - `section` — a titled, anchor-addressable block (`sectionId` derives the id
    from the title; the sidebar nav and the scrollspy use the same derivation).
  - `demoRow` — one bordered "demo card" per labelled example group: the
    examples sit in a padded body that scrolls horizontally instead of
    stretching the page, the label is the card's footer bar.
  - `demoBox` — the bounded preview box for position:fixed/absolute demos
    (Affix, BackTop, anchor affix): relative + translated so fixed descendants
    pin to the box, overflow-hidden so their geometry stays inside it.

-}

import Element exposing (Element)
import Element.Font as Font
import Html
import Html.Attributes as HA
import NUI.Code as Code
import NUI.Tag as Tag
import NUI.Theme as Theme exposing (Theme)
import NUI.Typography as Typo
import Svg
import Svg.Attributes as SA



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


tagD : Tag.Options msg
tagD =
    Tag.defaults


{-| Chrome CSS: smooth anchor scrolling and the sticky-header offset for
section targets. Spliced next to `Css.element` in Main.
-}
chromeCss : Element msg
chromeCss =
    Element.html chromeCssNode


{-| The raw `<style>` node behind `chromeCss` — Main memoizes it with
`Html.Lazy.lazy` so the per-msg diff skips the constant text child.
-}
chromeCssNode : Html.Html msg
chromeCssNode =
    Html.node "style"
        []
        [ Html.text
            (String.join
                ""
                [ "html{scroll-behavior:smooth}"
                , ".sc-sec{scroll-margin-top:78px}"

                -- elm-ui's height-content class (`.s.e > .hc{height:
                -- auto}`, specificity 0,3,0, re-embedded in per-view
                -- style nodes) defeats the drawer container's
                -- top/bottom stretch inside the demo hosts (height:auto
                -- resolves 0); height:100% restores the upstream "fills
                -- its mount parent" semantics.
                , ".n-drawer-container{height:100% !important}"
                ]
            )
        ]


{-| Derives the anchor id of a section title — shared by `section` (the id
attribute) and the sidebar nav (the href), so the two can never drift.
-}
sectionId : String -> String
sectionId title =
    let
        step char acc =
            if Char.isAlphaNum char then
                acc ++ String.fromChar (Char.toLower char)

            else if String.isEmpty acc then
                acc

            else if String.endsWith "-" acc then
                acc

            else
                acc ++ "-"

        dashed =
            String.foldl step "" title
                |> (\s ->
                        if String.endsWith "-" s then
                            String.dropRight 1 s

                        else
                            s
                   )
    in
    "sec-" ++ dashed


{-| A titled, anchor-addressable block: heading, description, examples. The
description is held to a ~720px reading measure — the content column is
~1000px wide and full-measure paragraphs (Notification, Menu, Modal…) read
as a wall of text.
-}
section : String -> String -> List (Element msg) -> Element msg
section title desc examples =
    Element.column
        [ Element.spacing 16
        , Element.width Element.fill
        , Element.htmlAttribute (HA.id (sectionId title))
        , Element.htmlAttribute (HA.class "sc-sec")
        ]
        [ Typo.h3 theme typ [ Element.text title ]
        , Element.el
            [ Element.width (Element.maximum 720 Element.fill) ]
            (Typo.text theme { typ | depth = Just 3 } [ Element.text desc ])
        , Element.column [ Element.spacing 20, Element.width Element.fill ] examples
        ]


{-| A demo card: the examples in a padded body that scrolls horizontally when
intrinsic content outgrows the column (elm-ui rows never shrink below
min-content, so wide demos must be fenced here), with the label as the
footer bar.
-}
demoRow : String -> List (Element msg) -> Element msg
demoRow label items =
    Element.column
        [ Element.width Element.fill
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "border:1px solid #efeff5;border-radius:4px;background:#fff"
            )
        ]
        [ Element.wrappedRow
            [ Element.spacing 16
            , Element.width Element.fill
            , Element.htmlAttribute
                (HA.attribute
                    "style"
                    "overflow-x:auto;padding:20px"
                )
            ]
            items
        , footerBar label
        ]


footerBar : String -> Element msg
footerBar label =
    Element.el
        [ Element.width Element.fill
        , Element.paddingXY 16 9
        , Element.htmlAttribute
            (HA.attribute "style" "border-top:1px solid #efeff5")
        ]
        (Element.el
            [ Font.size 11
            , Font.color (Element.rgb255 0x7C 0x80 0x87)
            , Font.letterSpacing 0.6
            ]
            (Element.text (String.toUpper label))
        )


{-| The bounded preview box for fixed/absolute-position demos: `relative` +
`transform` makes it the containing block for `position: fixed` descendants,
`overflow: hidden` keeps their geometry inside the box.
-}
demoBox : Int -> Element msg -> Element msg
demoBox heightPx content =
    Element.el
        [ Element.width Element.fill
        , Element.height (Element.px heightPx)
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;transform:translate(0,0);overflow:hidden;border:1px solid #efeff5;border-radius:4px;background:#fafafc"
            )
        ]
        content


chip : String -> Element msg
chip label =
    Tag.view theme { tagD | bordered = False } [ Element.text label ]


{-| Stretches a content-sized component to the full width of its container.
elm-ui children don't inherit the parent's width (an `Element.column` root
like `NUI.Alert`'s shrink-wraps inside a flex parent), while a 1fr grid
track sizes the subtree to the column — how the upstream block-level
component behaves in the DOM.
-}
fillWidth : Element msg -> Element msg
fillWidth content =
    Element.el
        [ Element.width Element.fill
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "display:grid;grid-template-columns:minmax(0,1fr)"
            )
        ]
        content


capitalize : String -> String
capitalize s =
    String.toUpper (String.left 1 s) ++ String.dropLeft 1 s



-- CROSS-FAMILY FIXTURES (moved from Main.elm — used by 2+ section families)


{-| A small inline SVG glyph for the icon showcase (and the menu demos).
Built with `elm/svg` — `Svg.*` nodes carry the SVG namespace; the previous
`Html.node "svg"` fixture rendered in the HTML namespace, which browsers
draw as an unknown element (the icon spaces were reserved but blank).
-}
starIcon : Element msg
starIcon =
    Element.html
        (Svg.svg
            [ SA.viewBox "0 0 24 24"
            , HA.attribute "aria-hidden" "true"
            ]
            [ Svg.path
                [ SA.fill "currentColor"
                , SA.d "M12 2l2.9 6.3 6.9.8-5.1 4.7 1.4 6.8L12 17.3 5.9 20.6l1.4-6.8L2.2 9.1l6.9-.8z"
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
