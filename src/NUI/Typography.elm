module NUI.Typography exposing (FontAlign(..), Options, a, blockquote, defaults, h1, h2, h3, h4, h5, h6, hr, li, ol, p, text, ul)

{-| Naive UI's `Typography` component set, rebuilt on elm-ui.

    import NUI.Typography exposing (defaults)

Every element carries the same BEM classes and the same `--n-*` custom properties
Naive UI emits, so with `NUI.Css` in scope it renders using Naive UI's own CSS.

    NUI.Typography.h1 theme
        NUI.Typography.defaults
        [ Element.text "Wonderful" ]

    NUI.Typography.text theme
        { defaults | kind = T.Primary, strong = True }
        [ Element.text "primary and strong" ]

    NUI.Typography.ul theme
        NUI.Typography.defaults
        [ NUI.Typography.li [ Element.text "First" ]
        , NUI.Typography.li [ Element.text "Second" ]
        ]

One `Options` record covers the whole set (Naive UI threads the same theme props
through every typography component); each element only honours the fields its
Naive UI counterpart has, plus a few elm-side conveniences that Naive UI leaves to
its users (`size`, `align`, `fontWeight`, `href`).

Block-level elements (`h1`-`h6`, `p`, `blockquote`, `ul`, `ol`, `li`, `hr`) are
elm-ui paragraphs — block flow with wrapping inline children. `text` and `a` flow
inline when placed inside a paragraph.

@docs FontAlign, Options, a, blockquote, defaults, h1, h2, h3, h4, h5, h6, hr, li, ol, p, text, ul

-}

import Element exposing (Element)
import Element.Events as Events
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Typography as ThemeTypography
import NUI.Types as T exposing (Kind(..))



-- Options


{-| Text alignment for the `align` option (`text-align`).
-}
type FontAlign
    = AlignLeft
    | AlignCenter
    | AlignRight
    | AlignJustify


{-| The one options record the whole typography set shares (Naive UI threads
the same theme props through every component). `kind` / `depth` pick the theme
colour, `strong` / `italic` / `underline` / `delete` / `code` the text
modifiers, `prefixBar` / `alignText` the header / blockquote modifiers, and
`size` / `align` / `fontWeight` / `href` / `onPress` the elm-side conveniences
(see each element's doc).
-}
type alias Options msg =
    { kind : Kind
    , depth : Maybe Int
    , strong : Bool
    , italic : Bool
    , underline : Bool
    , delete : Bool
    , code : Bool
    , prefixBar : Bool
    , alignText : Bool
    , size : Maybe Int
    , align : Maybe FontAlign
    , fontWeight : Maybe String
    , href : Maybe String
    , onPress : Maybe msg
    }


{-| No modifiers at all — default kind, no depth, no conveniences.
-}
defaults : Options msg
defaults =
    { kind = T.Default
    , depth = Nothing
    , strong = False
    , italic = False
    , underline = False
    , delete = False
    , code = False
    , prefixBar = False
    , alignText = False
    , size = Nothing
    , align = Nothing
    , fontWeight = Nothing
    , href = Nothing
    , onPress = Nothing
    }



-- Text


{-| Naive UI's `Text` — `.n-text` on a flow element.

`kind` maps its `type` prop, `depth` (1-3) only applies to the `default` kind,
`strong` / `italic` / `underline` / `code` add the matching `n-text--*` class, and
`delete` strikes the text through (Naive UI renders a `<del>`; we cannot, so the
`text-decoration` is applied inline).

-}
text : Theme -> Options msg -> List (Element msg) -> Element msg
text theme opts children =
    let
        v =
            ThemeTypography.vars theme

        classes =
            List.concat
                [ [ "n-text" ]
                , I.classIf opts.code "n-text--code"
                , I.classIf opts.delete "n-text--delete"
                , I.classIf opts.strong "n-text--strong"
                , I.classIf opts.italic "n-text--italic"
                , I.classIf opts.underline "n-text--underline"
                ]
    in
    Element.paragraph
        [ I.classes classes
        , I.cssVars (textCssVars theme opts v ++ deleteStyles opts ++ convenienceStyles opts)
        ]
        children


textCssVars : Theme -> Options msg -> ThemeTypography.Vars -> List ( String, String )
textCssVars theme opts v =
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-text-color", textColorOf opts.kind opts.depth v )
    , ( "--n-font-weight-strong", theme.common.fontWeightStrong )
    , ( "--n-font-famliy-mono", theme.common.fontFamilyMono )
    , ( "--n-code-border-radius", v.codeBorderRadius )
    , ( "--n-code-text-color", v.codeTextColor )
    , ( "--n-code-color", v.codeColor )
    , ( "--n-code-border", v.codeBorder )
    ]


{-| `type === 'default' ? textColor${depth}Depth : createKey('textColor', type)`.
-}
textColorOf : Kind -> Maybe Int -> ThemeTypography.Vars -> String
textColorOf kind depth v =
    case kind of
        T.Default ->
            case depth of
                Nothing ->
                    v.textColor

                Just d ->
                    if d <= 1 then
                        v.textColor1Depth

                    else if d == 2 then
                        v.textColor2Depth

                    else
                        v.textColor3Depth

        T.Primary ->
            v.textColorPrimary

        T.Info ->
            v.textColorInfo

        T.Success ->
            v.textColorSuccess

        T.Warning ->
            v.textColorWarning

        T.Error ->
            v.textColorError



-- Headers


type HeaderLevel
    = H1
    | H2
    | H3
    | H4
    | H5
    | H6


{-| Naive UI's `H1`-`H6` — `.n-h .n-h{level}`. `kind` selects the prefix-bar
colour, `prefixBar` adds `.n-h--prefix-bar`, `alignText` adds `.n-h--align-text`.
-}


{-| The level-1 heading — `.n-h .n-h1` (see `h1`'s group doc above).
-}
h1 : Theme -> Options msg -> List (Element msg) -> Element msg
h1 =
    header H1


{-| The level-2 heading — `.n-h .n-h2`.
-}
h2 : Theme -> Options msg -> List (Element msg) -> Element msg
h2 =
    header H2


{-| The level-3 heading — `.n-h .n-h3`.
-}
h3 : Theme -> Options msg -> List (Element msg) -> Element msg
h3 =
    header H3


{-| The level-4 heading — `.n-h .n-h4`.
-}
h4 : Theme -> Options msg -> List (Element msg) -> Element msg
h4 =
    header H4


{-| The level-5 heading — `.n-h .n-h5`.
-}
h5 : Theme -> Options msg -> List (Element msg) -> Element msg
h5 =
    header H5


{-| The level-6 heading — `.n-h .n-h6`.
-}
h6 : Theme -> Options msg -> List (Element msg) -> Element msg
h6 =
    header H6


header : HeaderLevel -> Theme -> Options msg -> List (Element msg) -> Element msg
header level theme opts children =
    let
        v =
            ThemeTypography.vars theme

        classes =
            List.concat
                [ [ "n-h", "n-h" ++ levelSuffix level ]
                , I.classIf opts.prefixBar "n-h--prefix-bar"
                , I.classIf opts.alignText "n-h--align-text"
                ]
    in
    Element.paragraph
        [ I.classes classes
        , I.cssVars (headerCssVars theme opts v level ++ blockDisplay ++ convenienceStyles opts)
        ]
        children


headerCssVars : Theme -> Options msg -> ThemeTypography.Vars -> HeaderLevel -> List ( String, String )
headerCssVars theme opts v level =
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", headerFontSize level v )
    , ( "--n-margin", headerMargin level v )
    , ( "--n-bar-color", headerBarColorOf opts.kind v )
    , ( "--n-bar-width", headerBarWidth level v )
    , ( "--n-font-weight", v.headerFontWeight )
    , ( "--n-text-color", v.headerTextColor )
    , ( "--n-prefix-width", headerPrefixWidth level v )
    ]


{-| `createKey('headerBarColor', type)` — `default` uses the bare name.
-}
headerBarColorOf : Kind -> ThemeTypography.Vars -> String
headerBarColorOf kind v =
    case kind of
        T.Default ->
            v.headerBarColor

        T.Primary ->
            v.headerBarColorPrimary

        T.Info ->
            v.headerBarColorInfo

        T.Success ->
            v.headerBarColorSuccess

        T.Warning ->
            v.headerBarColorWarning

        T.Error ->
            v.headerBarColorError


levelSuffix : HeaderLevel -> String
levelSuffix level =
    case level of
        H1 ->
            "1"

        H2 ->
            "2"

        H3 ->
            "3"

        H4 ->
            "4"

        H5 ->
            "5"

        H6 ->
            "6"


headerFontSize : HeaderLevel -> ThemeTypography.Vars -> String
headerFontSize level v =
    case level of
        H1 ->
            v.headerFontSize1

        H2 ->
            v.headerFontSize2

        H3 ->
            v.headerFontSize3

        H4 ->
            v.headerFontSize4

        H5 ->
            v.headerFontSize5

        H6 ->
            v.headerFontSize6


headerMargin : HeaderLevel -> ThemeTypography.Vars -> String
headerMargin level v =
    case level of
        H1 ->
            v.headerMargin1

        H2 ->
            v.headerMargin2

        H3 ->
            v.headerMargin3

        H4 ->
            v.headerMargin4

        H5 ->
            v.headerMargin5

        H6 ->
            v.headerMargin6


headerPrefixWidth : HeaderLevel -> ThemeTypography.Vars -> String
headerPrefixWidth level v =
    case level of
        H1 ->
            v.headerPrefixWidth1

        H2 ->
            v.headerPrefixWidth2

        H3 ->
            v.headerPrefixWidth3

        H4 ->
            v.headerPrefixWidth4

        H5 ->
            v.headerPrefixWidth5

        H6 ->
            v.headerPrefixWidth6


headerBarWidth : HeaderLevel -> ThemeTypography.Vars -> String
headerBarWidth level v =
    case level of
        H1 ->
            v.headerBarWidth1

        H2 ->
            v.headerBarWidth2

        H3 ->
            v.headerBarWidth3

        H4 ->
            v.headerBarWidth4

        H5 ->
            v.headerBarWidth5

        H6 ->
            v.headerBarWidth6



-- Paragraph


{-| Naive UI's `P` — `.n-p`. `depth` (1-3) selects `pTextColor{depth}Depth`.
-}
p : Theme -> Options msg -> List (Element msg) -> Element msg
p theme opts children =
    let
        v =
            ThemeTypography.vars theme
    in
    Element.paragraph
        [ I.classes [ "n-p" ]
        , I.cssVars (pCssVars theme opts v ++ blockDisplay ++ convenienceStyles opts)
        ]
        children


pCssVars : Theme -> Options msg -> ThemeTypography.Vars -> List ( String, String )
pCssVars theme opts v =
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", v.pFontSize )
    , ( "--n-line-height", v.pLineHeight )
    , ( "--n-margin", v.pMargin )
    , ( "--n-text-color", pTextColorOf opts.depth v )
    ]


{-| `depth === undefined ? pTextColor : pTextColor${depth || '1'}Depth`.
-}
pTextColorOf : Maybe Int -> ThemeTypography.Vars -> String
pTextColorOf depth v =
    case depth of
        Nothing ->
            v.pTextColor

        Just d ->
            if d <= 1 then
                v.pTextColor1Depth

            else if d == 2 then
                v.pTextColor2Depth

            else
                v.pTextColor3Depth



-- Anchor


{-| Naive UI's `A` — `.n-a`. With `href` a real anchor is rendered (via
`Element.link`); otherwise a styled element that still picks up `.n-a`'s
`cursor: pointer` look. `onPress` attaches a click handler and link semantics.
-}
a : Theme -> Options msg -> List (Element msg) -> Element msg
a theme opts children =
    let
        v =
            ThemeTypography.vars theme

        attrs =
            [ I.classes [ "n-a" ]
            , I.cssVars (aCssVars theme v ++ convenienceStyles opts)
            ]
                ++ linkAttrs opts

        body =
            Element.paragraph [] children
    in
    case opts.href of
        Just url ->
            Element.link attrs { url = url, label = body }

        Nothing ->
            Element.el attrs body


aCssVars : Theme -> ThemeTypography.Vars -> List ( String, String )
aCssVars theme v =
    [ ( "--n-text-color", v.aTextColor )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    ]


linkAttrs : Options msg -> List (Element.Attribute msg)
linkAttrs opts =
    case opts.onPress of
        Just msg ->
            [ Events.onClick msg
            , Element.htmlAttribute (HA.attribute "role" "link")
            , Element.htmlAttribute (HA.tabindex 0)
            ]

        Nothing ->
            []



-- Blockquote


{-| Naive UI's `Blockquote` — `.n-blockquote` (+ `--align-text`).
-}
blockquote : Theme -> Options msg -> List (Element msg) -> Element msg
blockquote theme opts children =
    let
        v =
            ThemeTypography.vars theme

        classes =
            List.concat
                [ [ "n-blockquote" ]
                , I.classIf opts.alignText "n-blockquote--align-text"
                ]
    in
    Element.paragraph
        [ I.classes classes
        , I.cssVars (blockquoteCssVars theme v ++ blockDisplay ++ convenienceStyles opts)
        ]
        children


blockquoteCssVars : Theme -> ThemeTypography.Vars -> List ( String, String )
blockquoteCssVars theme v =
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", v.blockquoteFontSize )
    , ( "--n-line-height", v.blockquoteLineHeight )
    , ( "--n-prefix-color", v.blockquotePrefixColor )
    , ( "--n-text-color", v.blockquoteTextColor )
    ]



-- Hr


{-| Naive UI's `Hr` — `.n-hr`, a plain themed separator.
-}
hr : Theme -> Element msg
hr theme =
    let
        v =
            ThemeTypography.vars theme
    in
    Element.el
        [ I.classes [ "n-hr" ]
        , I.cssVars (hrCssVars theme v ++ blockDisplay)
        ]
        Element.none


hrCssVars : Theme -> ThemeTypography.Vars -> List ( String, String )
hrCssVars theme v =
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-color", v.hrColor )
    ]



-- Lists


{-| Naive UI's `Ul` — `.n-ul` (+ `--align-text`).
-}
ul : Theme -> Options msg -> List (Element msg) -> Element msg
ul =
    list False


{-| Naive UI's `Ol` — `.n-ol` (+ `--align-text`).
-}
ol : Theme -> Options msg -> List (Element msg) -> Element msg
ol =
    list True


list : Bool -> Theme -> Options msg -> List (Element msg) -> Element msg
list ordered theme opts children =
    let
        v =
            ThemeTypography.vars theme

        base =
            if ordered then
                "n-ol"

            else
                "n-ul"

        classes =
            List.concat
                [ [ base ]
                , I.classIf opts.alignText (base ++ "--align-text")
                ]
    in
    Element.paragraph
        [ I.classes classes
        , I.cssVars (listCssVars theme v ++ uaListStyles ordered ++ convenienceStyles opts)
        ]
        children


listCssVars : Theme -> ThemeTypography.Vars -> List ( String, String )
listCssVars theme v =
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", v.liFontSize )
    , ( "--n-line-height", v.liLineHeight )
    , ( "--n-text-color", v.liTextColor )
    , ( "--n-li-margin", v.liMargin )
    , ( "--n-ol-padding", v.olPadding )
    , ( "--n-ul-padding", v.ulPadding )
    ]


{-| What a native `<ul>` / `<ol>` contributes and Naive UI relies on:
block display, inherited markers, and default block margins. Naive UI styles the
padding (via `--n-*-padding`) itself, markers and margins come from the browser.
-}
uaListStyles : Bool -> List ( String, String )
uaListStyles ordered =
    [ ( "display", "block" )
    , ( "list-style-type"
      , if ordered then
            "decimal"

        else
            "disc"
      )
    , ( "margin-top", "1em" )
    , ( "margin-bottom", "1em" )
    ]


{-| Naive UI's `Li` — a bare `<li>` (no classes, no vars of its own; the styles
come from the `.n-ul li` / `.n-ol li` rules and the vars defined by the
surrounding list). We emit the `n-li` class for parity and restate those
tag-selector rules inline, since our element is not an `<li>` tag.
-}
li : List (Element msg) -> Element msg
li children =
    Element.paragraph
        [ I.classes [ "n-li" ]
        , I.cssVars liStyles
        ]
        children


{-| The `.n-ul li` rule: `transition / line-height / margin / color`, plus the
`display: list-item` and marker a native `<li>` gets from the browser. The
`var(--n-*)` references resolve against the surrounding list's inline vars.
-}
liStyles : List ( String, String )
liStyles =
    [ ( "display", "list-item" )
    , ( "transition", "color .3s var(--n-bezier)" )
    , ( "line-height", "var(--n-line-height)" )
    , ( "margin", "var(--n-li-margin)" )
    , ( "margin-bottom", "0" )
    , ( "color", "var(--n-text-color)" )
    ]



-- Shared style helpers


{-| Keep block-level typography block-level even when nested inside an elm-ui
paragraph (whose `.s.p .s.p { display: inline }` rule would otherwise inline it —
native block tags can never end up inline inside text flow).
-}
blockDisplay : List ( String, String )
blockDisplay =
    [ ( "display", "block" )
    ]


{-| Naive UI's `<del>`: `text-decoration: line-through`. Skipped when
`n-text--underline` is set, mirroring the cascade where the author underline rule
replaces the `<del>`'s user-agent line-through.
-}
deleteStyles : Options msg -> List ( String, String )
deleteStyles opts =
    if opts.delete && not opts.underline then
        [ ( "text-decoration", "line-through" )
        ]

    else
        []


{-| Elm-side conveniences Naive UI does not offer as props: `size` (px),
`fontWeight` (any CSS value) and `align` (`text-align`). Emitted inline so they
win over both elm-ui helper classes and the scoped Naive UI rules.
-}
convenienceStyles : Options msg -> List ( String, String )
convenienceStyles opts =
    List.concat
        [ maybeStyle "font-size" (Maybe.map (\px -> String.fromInt px ++ "px") opts.size)
        , maybeStyle "font-weight" opts.fontWeight
        , maybeStyle "text-align" (Maybe.map alignCss opts.align)
        ]


maybeStyle : String -> Maybe String -> List ( String, String )
maybeStyle prop value =
    case value of
        Just v ->
            [ ( prop, v ) ]

        Nothing ->
            []


alignCss : FontAlign -> String
alignCss align =
    case align of
        AlignLeft ->
            "left"

        AlignCenter ->
            "center"

        AlignRight ->
            "right"

        AlignJustify ->
            "justify"
