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
    pin to the box, overflow-hidden so their geometry stays inside it. Now a
    keyed column with the same footer/code toggle as `demoRow`.

-}

import DemoCode
import Element exposing (Element)
import Element.Font as Font
import ElmSyntax
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

                -- Demo-card footer bar + code toggle (see `footerBar` /
                -- `codeToggle`): one flex row, baseline-aligned, so the
                -- uppercase label and the toggle's chip sit on one
                -- typographic baseline in both toggle states; the toggle
                -- is a native <details> laid out as an end-aligned flex
                -- column, so the chip hugs the right edge while the
                -- expanded panel anchors to the footer's RIGHT edge —
                -- the one anchor that is identical on every card (a
                -- left anchor would jitter with each label's width).
                , ".sc-foot{width:100%;box-sizing:border-box;display:flex;align-items:baseline;gap:12px;padding:9px 16px;border-top:1px solid #efeff5}"
                , ".sc-foot-label{font-size:11px;color:#7c8087;letter-spacing:.6px;white-space:nowrap}"
                , ".sc-code{flex:1 1 auto;min-width:0;display:flex;flex-direction:column;align-items:flex-end;font-size:11px;color:#7c8087}"
                , ".sc-code>summary{list-style:none;cursor:pointer;user-select:none;display:inline-flex;align-items:center;gap:5px;padding:2px 8px;border:1px solid transparent;border-radius:3px;font-size:11px;letter-spacing:.4px;line-height:16px;color:inherit;transition:color .15s ease,border-color .15s ease,background-color .15s ease}"
                , ".sc-code>summary::-webkit-details-marker{display:none}"
                , ".sc-code>summary:hover{color:#18a058;background:#f6f8fa;border-color:#e3e3ea}"
                , ".sc-code[open]>summary{color:#18a058;background:#f0faf5;border-color:#d5e9de}"
                , ".sc-code>summary:focus-visible{outline:1px solid #18a058;outline-offset:2px}"
                , ".sc-code .sc-code-chev{flex:none;transition:transform .18s ease}"
                , ".sc-code[open] .sc-code-chev{transform:rotate(90deg)}"
                , ".sc-code>pre{max-width:min(780px,100%);margin:8px 0 2px;padding:12px 14px;background:#f6f8fa;border:1px solid #efeff5;border-left:2px solid rgba(24,160,88,.45);border-radius:4px;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:11.5px;line-height:1.65;color:#24292f;white-space:pre-wrap;word-break:break-word;overflow-wrap:anywhere}"
                , ".sc-code>pre .tok-com{color:#6a737d;font-style:italic}"
                , ".sc-code>pre .tok-str,.sc-code>pre .tok-chr{color:#0e8a54}"
                , ".sc-code>pre .tok-num{color:#9a6700}"
                , ".sc-code>pre .tok-kw,.sc-code>pre .tok-pun{color:#cf222e}"
                , ".sc-code>pre .tok-typ,.sc-code>pre .tok-fn{color:#8250df}"
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

The card's demo items are keyed (`demoRow "gen-017" "Label" …` — keys
inserted by tools/gen-demo-code.mjs): the footer carries a `<details>`
code toggle that expands the items' own Elm source, looked up in the
generated DemoCode dictionary. Pure CSS open/close — no model state, no
messages, so the toggle is inert to the page's update loop.

-}
demoRow : String -> String -> List (Element msg) -> Element msg
demoRow key label items =
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
        , footerBar key label
        ]


{-| The card's footer bar: the uppercase label left, the code toggle
right, on one baseline. Rendered as one raw HTML block (styled entirely
by the `.sc-foot` rules in `chromeCssNode`) rather than an elm-ui row:
elm-ui's `alignRight` wrapper centers its content against the row's
full height, which would float the label down the panel when the toggle
opens — a plain flex row with `align-items:baseline` keeps both texts on
one typographic baseline in both states, and the 9/16 padding matches
the pre-toggle footer exactly. The `Element.el width fill` wrapper is
load-bearing: `Element.html` alone shrink-wraps to content, which would
clip the footer's border-top to the label's width instead of the card's.
-}
footerBar : String -> String -> Element msg
footerBar key label =
    Element.el
        [ Element.width Element.fill ]
        (Element.html
            (Html.div
                [ HA.class "sc-foot" ]
                [ Html.span
                    [ HA.class "sc-foot-label" ]
                    [ Html.text (String.toUpper label) ]
                , codeToggle key
                ]
            )
        )


{-| The footer's code toggle: a native `<details>` (pure CSS open/close —
no model state, no messages, inert to the page's update loop) whose
summary is a quiet chip — "</> Elm" plus a chevron that rotates on open
— and whose panel is the items' own Elm source, looked up in the
generated DemoCode dictionary and syntax-highlighted by the pure-Elm
tokenizer in `ElmSyntax` (no dependencies, no JavaScript — default runs
render as plain text nodes, classified runs as `tok-*` spans). The
panel is `white-space:pre-wrap` and capped at 780px, so wide lines wrap
instead of scrolling the page under the sticky top bar. Empty snippet
(unknown key) → no toggle at all. All styling lives in the `.sc-code`
rules in `chromeCssNode`.
-}
codeToggle : String -> Html.Html msg
codeToggle key =
    let
        code =
            DemoCode.get key
    in
    if String.isEmpty code then
        Html.text ""

    else
        Html.details
            [ HA.class "sc-code" ]
            [ Html.summary
                []
                [ Html.text "</> Elm"
                , chevronDown
                ]
            , Html.pre [] (List.map tokenNode (ElmSyntax.tokens code))
            ]


{-| One token as a DOM node: default runs (empty class) stay plain text,
classified runs become a `span.tok-*` whose text is a separate text
node. Text nodes are HTML-inert by construction — the browser escapes
at the `createTextNode` layer — so `&`, `<`, `>` and quotes render
literally with no string escaping in Elm (wrapping token text in an
Elm-side `&amp;`-style escaper would double-escape and visibly corrupt
the code).
-}
tokenNode : ElmSyntax.Token -> Html.Html msg
tokenNode t =
    if t.cls == "" then
        Html.text t.text

    else
        Html.span [ HA.class t.cls ] [ Html.text t.text ]


{-| The toggle's disclosure chevron — rotates 90° while open (CSS only,
`.sc-code[open] .sc-code-chev`). Text comes first in the summary so the
baseline the footer row aligns the label against is the text's own
baseline, not an SVG's synthesized bottom edge.
-}
chevronDown : Html.Html msg
chevronDown =
    Svg.svg
        [ SA.viewBox "0 0 16 16"
        , SA.width "9"
        , SA.height "9"
        , SA.class "sc-code-chev"
        , HA.attribute "aria-hidden" "true"
        ]
        [ Svg.path
            [ SA.fill "none"
            , SA.stroke "currentColor"
            , SA.strokeWidth "1.5"
            , SA.strokeLinecap "round"
            , SA.strokeLinejoin "round"
            , SA.d "M6 4l4 4-4 4"
            ]
            []
        ]


{-| The bounded preview box for fixed/absolute-position demos: `relative` +
`transform` makes it the containing block for `position: fixed` descendants,
`overflow: hidden` keeps their geometry inside the box. Keyed like `demoRow`,
with the code toggle in its footer.
-}
demoBox : String -> Int -> Element msg -> Element msg
demoBox key heightPx content =
    Element.column
        [ Element.width Element.fill
        , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;transform:translate(0,0);border:1px solid #efeff5;border-radius:4px;background:#fafafc"
            )
        ]
        [ Element.el
            [ Element.width Element.fill
            , Element.height (Element.px heightPx)
            , Element.htmlAttribute (HA.attribute "style" "overflow:hidden")
            ]
            content
        , footerBar key ""
        ]


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
