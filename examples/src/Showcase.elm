module Showcase exposing
    ( Palette
    , capitalize
    , chip
    , chromeCss
    , chromeCssNode
    , codeHljs
    , darkTheme
    , demoBox
    , demoRow
    , demoRowUnfenced
    , fakeKatex
    , fakeKatexDisplay
    , fillWidth
    , paletteFor
    , purple
    , section
    , sectionId
    , starIcon
    )

{-| Shared showcase chrome: the docs-style section/demo scaffolding, and the
cross-family fixtures (a fake highlight.js, fake katex closures, a star
glyph) used by more than one section family. Used by the static page
(Main / Sections/_) and every Live/_ interactive family module, so live demos
read exactly like the static ones.

The page is theme-switchable (Light ⇄ Dark, toggled from Main's top bar):
every scaffold here takes the runtime `Theme` as its first argument, and the
chrome colours (card surfaces, borders, footer labels, the code panel and
its syntax tokens) come from `paletteFor`, so light mode renders exactly the
old hardcoded palette and dark mode restyles the same DOM. `darkTheme`
stays a fixed standalone specimen theme — the Overlay demos that
deliberately show dark specimens use it regardless of the page theme.

The page chrome itself (top bar, sticky sidebar, content column) lives in
Main.elm; this module owns the pieces every section shares:

  - `section` — a titled, anchor-addressable block (`sectionId` derives the id
    from the title; the sidebar nav and the scrollspy use the same derivation).
  - `demoRow` — one bordered "demo card" per labelled example group: the
    examples sit in a padded body that scrolls horizontally instead of
    stretching the page, the label is the card's footer bar. `demoRowUnfenced`
    is the same card without that horizontal fence — for demos whose floating
    chrome (the slider's value indicator, any inline popover seam) must escape
    the body box; CSS turns any non-visible overflow axis into a clipper, so
    a fenced body would cut them off.
  - `demoBox` — the bounded preview box for position:fixed/absolute demos
    (Affix, BackTop, anchor affix): relative + translated so fixed descendants
    pin to the box, overflow-hidden so their geometry stays inside it. Now a
    keyed column with the same footer/code toggle as `demoRow`.

-}

import DemoCode
import Element exposing (Element)
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


{-| Derives a purple-primary theme from whatever the page currently shows
(the General "Theme" section demos `setPrimary` with it).
-}
purple : Theme -> Theme
purple t =
    Theme.setPrimary "#7c3aed" t


{-| A fixed dark specimen theme for the demos that deliberately show dark
components (Overlay's Tooltip/Modal/Dialog specimens) whatever the page
theme is.
-}
darkTheme : Theme
darkTheme =
    Theme.dark



-- CHROME PALETTE (one Palette per mode; every chrome colour below comes from it)


type alias Palette =
    { bg : String
    , text : String
    , textMuted : String
    , textFaint : String
    , border : String
    , borderHover : String
    , borderOpen : String
    , surface : String
    , surfaceAlt : String
    , codeBg : String
    , codeText : String
    , activeBg : String
    , hoverBg : String
    , openBg : String
    , navIdle : String
    , accent : String
    , tokComment : String
    , tokString : String
    , tokNumber : String
    , tokKeyword : String
    , tokType : String
    }


paletteFor : Theme -> Palette
paletteFor t =
    case t.mode of
        Theme.Light ->
            lightPalette

        Theme.Dark ->
            darkPalette


{-| Light = the palette the chrome used to hardcode, byte for byte.
-}
lightPalette : Palette
lightPalette =
    { bg = "#fff"
    , text = "#333639"
    , textMuted = "#7c8087"
    , textFaint = "#909399"
    , border = "#efeff5"
    , borderHover = "#e3e3ea"
    , borderOpen = "#d5e9de"
    , surface = "#fff"
    , surfaceAlt = "#fafafc"
    , codeBg = "#f6f8fa"
    , codeText = "#24292f"
    , activeBg = "#f0faf5"
    , hoverBg = "#f6f8fa"
    , openBg = "#f0faf5"
    , navIdle = "#4c5056"
    , accent = "#18a058"
    , tokComment = "#6a737d"
    , tokString = "#0e8a54"
    , tokNumber = "#9a6700"
    , tokKeyword = "#cf222e"
    , tokType = "#8250df"
    }


{-| Dark = naive-ui's dark surfaces (rgb(16,16,20) body, rgb(24,24,28) cards,
mint #63e2b7 primary) with translucent-white text/borders so cards sit on the
page instead of floating.
-}
darkPalette : Palette
darkPalette =
    { bg = "rgb(16,16,20)"
    , text = "rgba(255,255,255,.82)"
    , textMuted = "rgba(255,255,255,.55)"
    , textFaint = "rgba(255,255,255,.38)"
    , border = "rgb(255,255,255,.09)"
    , borderHover = "rgb(255,255,255,.14)"
    , borderOpen = "rgba(99,226,183,.28)"
    , surface = "rgb(24,24,28)"
    , surfaceAlt = "rgb(44,44,50)"
    , codeBg = "rgb(32,32,36)"
    , codeText = "rgba(255,255,255,.82)"
    , activeBg = "rgba(99,226,183,.09)"
    , hoverBg = "rgba(255,255,255,.06)"
    , openBg = "rgba(99,226,183,.12)"
    , navIdle = "rgba(255,255,255,.62)"
    , accent = "#63e2b7"
    , tokComment = "rgba(255,255,255,.4)"
    , tokString = "#63e2b7"
    , tokNumber = "#f2c97d"
    , tokKeyword = "#e88080"
    , tokType = "#a78bfa"
    }


typ : Typo.Options msg
typ =
    Typo.defaults


tagD : Tag.Options msg
tagD =
    Tag.defaults


{-| Chrome CSS: smooth anchor scrolling and the sticky-header offset for
section targets. Spliced next to `Css.element` in Main.
-}
chromeCss : Theme -> Element msg
chromeCss t =
    Element.html (chromeCssNode t)


{-| The raw `<style>` node behind `chromeCss` — the same rule set Main embeds
(memoized on `model.themeMode` via `Html.Lazy.lazy`, so the per-msg diff
skips the constant text child until the theme flips), with every colour
interpolated from `paletteFor`. Selectors and non-colour declarations are
mode-independent.
-}
chromeCssNode : Theme -> Html.Html msg
chromeCssNode t =
    let
        p =
            paletteFor t
    in
    Html.node "style"
        []
        [ Html.text
            (String.join
                ""
                [ "html{scroll-behavior:smooth}"

                -- Anchor offset: 32px sticky bar + 14px headroom above
                -- the section box; the section's own top padding (see
                -- `section`) then puts the title at 110px, leaving the
                -- tail of the previous section's last card visible above
                -- it for orientation.
                , ".sc-sec{scroll-margin-top:46px}"

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
                -- expanded panel anchors to the footer's RIGHT edge — the one
                -- anchor that is identical on every card (a left anchor
                -- would jitter with each label's width).
                , ".sc-foot{width:100%;box-sizing:border-box;display:flex;align-items:baseline;gap:12px;padding:9px 16px;border-top:1px solid "
                    ++ p.border
                    ++ "}"
                , ".sc-foot-label{font-size:11px;color:"
                    ++ p.textMuted
                    ++ ";letter-spacing:.6px;white-space:nowrap}"
                , ".sc-code{flex:1 1 auto;min-width:0;display:flex;flex-direction:column;align-items:flex-end;font-size:11px;color:"
                    ++ p.textMuted
                    ++ "}"
                , ".sc-code>summary{list-style:none;cursor:pointer;user-select:none;display:inline-flex;align-items:center;gap:5px;padding:2px 8px;border:1px solid transparent;border-radius:3px;font-size:11px;letter-spacing:.4px;line-height:16px;color:inherit;transition:color .15s ease,border-color .15s ease,background-color .15s ease}"
                , ".sc-code>summary::-webkit-details-marker{display:none}"
                , ".sc-code>summary:hover{color:"
                    ++ p.accent
                    ++ ";background:"
                    ++ p.hoverBg
                    ++ ";border-color:"
                    ++ p.borderHover
                    ++ "}"
                , ".sc-code[open]>summary{color:"
                    ++ p.accent
                    ++ ";background:"
                    ++ p.openBg
                    ++ ";border-color:"
                    ++ p.borderOpen
                    ++ "}"
                , ".sc-code>summary:focus-visible{outline:1px solid "
                    ++ p.accent
                    ++ ";outline-offset:2px}"
                , ".sc-code .sc-code-chev{flex:none;transition:transform .18s ease}"
                , ".sc-code[open] .sc-code-chev{transform:rotate(90deg)}"
                , ".sc-code>pre{max-width:min(780px,100%);margin:8px 0 2px;padding:12px 14px;background:"
                    ++ p.codeBg
                    ++ ";border:1px solid "
                    ++ p.border
                    ++ ";border-left:2px solid rgba(24,160,88,.45);border-radius:4px;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:11.5px;line-height:1.65;color:"
                    ++ p.codeText
                    ++ ";white-space:pre-wrap;word-break:break-word;overflow-wrap:anywhere}"
                , ".sc-code>pre .tok-com{color:"
                    ++ p.tokComment
                    ++ ";font-style:italic}"
                , ".sc-code>pre .tok-str,.sc-code>pre .tok-chr{color:"
                    ++ p.tokString
                    ++ "}"
                , ".sc-code>pre .tok-num{color:"
                    ++ p.tokNumber
                    ++ "}"
                , ".sc-code>pre .tok-kw,.sc-code>pre .tok-pun{color:"
                    ++ p.tokKeyword
                    ++ "}"
                , ".sc-code>pre .tok-typ,.sc-code>pre .tok-fn{color:"
                    ++ p.tokType
                    ++ "}"
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
section : Theme -> String -> String -> List (Element msg) -> Element msg
section t title desc examples =
    Element.column
        [ Element.spacing 16
        , Element.width Element.fill

        -- Breathing room above the title: family sections stack in a
        -- spacing-0 column (Main.body / familyNode), so this inset IS the
        -- gap from the previous section's last demo card — the only
        -- external gap a section gets, and deliberately ~4x the internal
        -- 16/20px rhythm so a heading visibly belongs to what's below it.
        -- scroll-margin-top absorbs it on anchor jumps (`.sc-sec` in
        -- chromeCssNode).
        , Element.paddingEach { top = 64, bottom = 0, left = 0, right = 0 }
        , Element.htmlAttribute (HA.id (sectionId title))
        , Element.htmlAttribute (HA.class "sc-sec")
        ]
        [ Typo.h3 t typ [ Element.text title ]
        , Element.el
            [ Element.width (Element.maximum 720 Element.fill) ]
            (Typo.text t { typ | depth = Just 3 } [ Element.text desc ])
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
demoRow : Theme -> String -> String -> List (Element msg) -> Element msg
demoRow t key label items =
    demoCard t
        key
        label
        (Element.wrappedRow
            [ Element.spacing 16
            , Element.width Element.fill

            -- The horizontal fence: wide demos scroll inside the card
            -- instead of stretching the page. One non-visible overflow
            -- axis forces the other to `auto` (CSS overflow spec), so this
            -- row is a two-axis clipper — floating chrome that pokes above
            -- the body (the slider's value indicator) must use
            -- `demoRowUnfenced` instead.
            , Element.htmlAttribute
                (HA.attribute
                    "style"
                    "overflow-x:auto;padding:20px"
                )
            ]
            items
        )


{-| `demoRow` without the horizontal fence: the body is a plain padded
wrappedRow, so absolutely-positioned chrome anchored inside it (the
slider's value indicator pokes ~37px above the handle) renders unclipped.
Still page-safe: elm-ui rows wrap at min-content, and every demo routed
here stays narrower than the column.
-}
demoRowUnfenced : Theme -> String -> String -> List (Element msg) -> Element msg
demoRowUnfenced t key label items =
    demoCard t
        key
        label
        (Element.wrappedRow
            [ Element.spacing 16
            , Element.width Element.fill
            , Element.padding 20
            ]
            items
        )


{-| The shared demo-card shell: the bordered card box with the body on top
and the footer bar below.
-}
demoCard : Theme -> String -> String -> Element msg -> Element msg
demoCard t key label body =
    Element.column
        [ Element.width Element.fill
        , Element.htmlAttribute
            (HA.attribute
                "style"
                ("border:1px solid "
                    ++ (paletteFor t).border
                    ++ ";border-radius:4px;background:"
                    ++ (paletteFor t).surface
                )
            )
        ]
        [ body
        , footerBar t key label
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
footerBar : Theme -> String -> String -> Element msg
footerBar t key label =
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
demoBox : Theme -> String -> Int -> Element msg -> Element msg
demoBox t key heightPx content =
    Element.column
        [ Element.width Element.fill
        , Element.htmlAttribute
            (HA.attribute
                "style"
                ("position:relative;transform:translate(0,0);border:1px solid "
                    ++ (paletteFor t).border
                    ++ ";border-radius:4px;background:"
                    ++ (paletteFor t).surfaceAlt
                )
            )
        ]
        [ Element.el
            [ Element.width Element.fill
            , Element.height (Element.px heightPx)
            , Element.htmlAttribute (HA.attribute "style" "overflow:hidden")
            ]
            content
        , footerBar t key ""
        ]


chip : Theme -> String -> Element msg
chip t label =
    Tag.view t { tagD | bordered = False } [ Element.text label ]


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
