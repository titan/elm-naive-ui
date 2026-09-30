module NUI.Code exposing
    ( Hljs
    , Options
    , codeHtml
    , cssVarsFor
    , defaults
    , lineNumbers
    , mergedShowLineNumbers
    , view
    )

{-| Naive UI's `Code` (`n-code`), rebuilt as a pure renderer over a
caller-supplied highlight.js (`Hljs`).

    import NUI.Code as Code

    hljs : Code.Hljs
    hljs =
        { getLanguage = (== "javascript")
        , highlight = \code _ -> "<span class=\\"hljs-keyword\\">" ++ code ++ "</span>"
        }

    Code.view theme
        { Code.defaults | code = "const x = 1", language = Just "javascript", hljs = Just hljs }
        []

The visual result is Naive UI's own: the root carries the `.n-code` BEM classes
and Naive UI's 15 `--n-*` custom properties, and `NUI.Css` ships Naive UI's
exact CSS. Highlighting needs `highlight.js` injected — this port never ships
it; the caller passes the same two methods upstream consumes (`getLanguage`,
`highlight`).

**Raw-Html root (the `NUI.Highlight` / `NUI.Carousel` precedent).** Upstream's
root is a plain `<code>` whose children are inserted imperatively (`innerHTML` /
`textContent` / a `pre.__code__`); the port reproduces that DOM as ONE raw
`Html` tree, so `view` returns an `Element` only through `Element.html` and its
`attributes` field is a `List (Html.Attribute msg)` (an `Element.Attribute`
cannot attach to a raw node).

**⚠ `[D]` Raw HTML is parsed, not injected.** `Code.tsx` embeds the
highlighter's output with `el.innerHTML = html`; elm/html blocks that path — the
VirtualDom kernel remaps the `innerHTML` property key
(`_VirtualDom_noInnerHtmlOrFormAction`) and `setAttribute "innerHTML"` is a
no-op. The port instead runs the SAME resolved string through
`NUI.Internal.RawHtml.nodes`, a pure parser of the highlight.js / KaTeX output
shapes (its grammar and recovery semantics are docstringed there). Real
highlight.js output containing `<span class="hljs-…">` markup therefore renders
as elements, faithfully; the class / style / line-number structure stays
byte-faithful. (Recon-2 §5(b) claimed `HA.property "innerHTML"` works;
empirically it does not.)

**Static image of `setCode`.** Upstream writes the code content imperatively on
mount; there is no pure render path for it. `view` therefore emits the state
`setCode` would settle into (the decision tree of `Code.tsx:62-108`), which is
also what the DOM probes assert:

  - a caller `children` list (Log's slot path) short-circuits `setCode`
    (`Code.tsx:63`) — the line-numbers `<pre>` is rendered, then the children
    untouched;
  - otherwise `inline` puts the highlighted string as the `<code>` root's
    children (parsed — `[D]`), or the plain code as a text node
    (`textContent`);
  - the block form renders the line-numbers `<pre>` then a `pre.__code__`
    carrying the highlighted string (parsed — `[D]`) or the plain code as
    text (`textContent`).

**Caller-owned runtime.** The `uri` / `inline` / `wordWrap` / `showLineNumbers`
/ `internalFontSize` / `internalNoHighlight` props are all modelled exactly;
`internalFontSize` / `internalNoHighlight` exist only for `NUI.Log`'s embedding
(Log passes `Just fontSize` + `True`). `internalNoHighlight` makes the port skip
highlighting entirely (LogLine does its own per-line highlight).

**Divergences (`[D]`):**

  - `[D]` URI decode: upstream `window.decodeURIComponent(props.code)` THROWS on
    a malformed string (an uncaught crash). `Url.percentDecode` returns
    `Nothing`; the port falls back to the RAW string.
  - `[D]` `lineNumbers` runs over the RAW `props.code`, **not** the URI-decoded
    string (`Code.tsx:172-189` uses `props.code`; `setCode` decodes a local).
    This upstream quirk is kept.
  - `[D]` `themeClass` (the `useThemeClass` inline-theme handle) is never emitted
    (house-wide: the port has no `inlineThemeDisabled`).
  - `[D]` `codeHtml`'s "language" is `Maybe String`; upstream's
    `!(language && hljs.getLanguage(language))` treats an EMPTY string as "no
    language" (`Code.tsx:49-50`), so `Just ""` returns `Nothing` here too.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Internal.RawHtml as RawHtml
import NUI.Theme exposing (Theme)
import NUI.Theme.Code as CodeTheme
import Url


{-| The caller-supplied highlight.js surface (upstream `Hljs`): exactly the two
members `Code` consumes. `getLanguage` returns a truthy language or nothing —
the port only ever truth-tests it, so a `Bool` suffices. `highlight code
language` mirrors upstream `hljs.highlight(code, { language }).value` (note the
ARG ORDER: code first).
-}
type alias Hljs =
    { getLanguage : String -> Bool
    , highlight : String -> String -> String
    }


{-| The `n-code` options (`codeProps`, `Code.tsx:10-29`). `attributes` land on
the raw root `<code>`.
-}
type alias Options msg =
    { language : Maybe String
    , code : String
    , trim : Bool
    , hljs : Maybe Hljs
    , uri : Bool
    , inline : Bool
    , wordWrap : Bool
    , showLineNumbers : Bool
    , internalFontSize : Maybe Int
    , internalNoHighlight : Bool
    , attributes : List (Html.Attribute msg)
    }


{-| Upstream's prop defaults, byte-for-byte: `code = ""`, `trim = True` (⚠ Log's
`trim` is `False`), every `Maybe` `Nothing`, every `Bool` `False`.
-}
defaults : Options msg
defaults =
    { language = Nothing
    , code = ""
    , trim = True
    , hljs = Nothing
    , uri = False
    , inline = False
    , wordWrap = False
    , showLineNumbers = False
    , internalFontSize = Nothing
    , internalNoHighlight = False
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The `n-code` element (ONE raw `Html` tree) — the static image of `setCode`;
see the module notes. `children` is the caller's slot content (uploaded
untouched when present).
-}
view : Theme -> Options msg -> List (Html.Html msg) -> Element msg
view theme opts children =
    Element.html (rootNode theme opts children)


rootNode : Theme -> Options msg -> List (Html.Html msg) -> Html.Html msg
rootNode theme opts children =
    let
        attrs =
            [ HA.class (String.join " " (classes opts))
            , HA.attribute "style" (I.renderVars (cssVarsFor theme opts))
            ]
                ++ opts.attributes
    in
    if List.isEmpty children then
        staticNode opts attrs

    else
        Html.node "code" attrs (lineNumbersPre opts ++ children)


{-| The no-slot branch of `setCode` (`Code.tsx:82-108`), as a static tree: the
resolved `code` (URI-decoded when `uri`), the highlight gates, then the
inline/block shape.
-}
staticNode : Options msg -> List (Html.Attribute msg) -> Html.Html msg
staticNode opts attrs =
    let
        code =
            if opts.uri then
                Maybe.withDefault opts.code (Url.percentDecode opts.code)

            else
                opts.code

        highlighted =
            -- `internalNoHighlight` swaps upstream's `hljsRef` for `{ value:
            -- undefined }` (Code.tsx:37), forcing the textContent path.
            if opts.internalNoHighlight then
                Nothing

            else
                codeHtml opts.hljs opts.language opts.trim code
    in
    if opts.inline then
        -- `[D]` upstream sets `codeEl.innerHTML = html` for the highlighted
        -- branch and `codeEl.textContent = code` for the plain one; the port
        -- parses ONLY the highlighted string (`NUI.Internal.RawHtml`), the
        -- plain branch is a text node. mergedShowLineNumbers is always False
        -- under `inline`, so there is no line-numbers pre to preserve.
        Html.node "code"
            attrs
            (case highlighted of
                Just h ->
                    RawHtml.nodes h

                Nothing ->
                    [ Html.text code ]
            )

    else
        Html.node "code" attrs (lineNumbersPre opts ++ [ codePre highlighted code ])


{-| `mergedShowLineNumbers ? <pre class="n-code__line-numbers">{lineNumbers}</pre> : null`
(`Code.tsx:206-211`).
-}
lineNumbersPre : Options msg -> List (Html.Html msg)
lineNumbersPre opts =
    if mergedShowLineNumbers opts then
        [ Html.node "pre"
            [ HA.class "n-code__line-numbers" ]
            [ Html.text (lineNumbers opts.code) ]
        ]

    else
        []


{-| The block-mode `pre.__code__` (`Code.tsx:90-97` / `103-108`): the
highlighted string parsed into real nodes when the gates passed, else the plain
code as a text node. `[D]` upstream sets `pre.innerHTML = html` for the
highlighted branch and `textContent = code` for the plain one; the port parses
only the highlighted string (`NUI.Internal.RawHtml`, recovery semantics
docstringed there).
-}
codePre : Maybe String -> String -> Html.Html msg
codePre highlighted code =
    Html.node "pre"
        [ HA.class "__code__" ]
        (case highlighted of
            Just h ->
                RawHtml.nodes h

            Nothing ->
                [ Html.text code ]
        )


{-| The root class list, in upstream order (`Code.tsx:200-205`): `n-code`, then
the two computed modifiers (`themeClass` is never emitted — `[D]`).
-}
classes : Options msg -> List String
classes opts =
    "n-code"
        :: (I.classIf opts.wordWrap "n-code--word-wrap"
                ++ I.classIf (mergedShowLineNumbers opts) "n-code--show-line-numbers"
           )



-- PURE MIRRORS -----------------------------------------------------------------


{-| `createCodeHtml` (`Code.tsx:41-56`): GATE 1 (no hljs) then GATE 2 (no /
unknown language), then `hljs.highlight(trim ? code.trim() : code, { language })`.
Returns `Nothing` where upstream returns `null`.
-}
codeHtml : Maybe Hljs -> Maybe String -> Bool -> String -> Maybe String
codeHtml hljs language trim code =
    case hljs of
        Nothing ->
            Nothing

        Just h ->
            case language of
                Just lang ->
                    -- `!(language && ...)`: an EMPTY string is "no language".
                    if String.isEmpty lang then
                        Nothing

                    else if h.getLanguage lang then
                        Just
                            (h.highlight
                                (if trim then
                                    String.trim code

                                 else
                                    code
                                )
                                lang
                            )

                    else
                        Nothing

                Nothing ->
                    Nothing


{-| The line-number gutter (`Code.tsx:172-189`): a post-increment push on every
`'\n'`, plus a final line when the last character was not a `'\n'`, joined with
`"\n"`. Runs over the RAW `props.code` (`[D]`).
-}
lineNumbers : String -> String
lineNumbers code =
    let
        ( number, numbers, lastIsLineWrap ) =
            List.foldl
                (\c ( n, acc, _ ) ->
                    if c == '\n' then
                        ( n + 1, acc ++ [ n ], True )

                    else
                        ( n, acc, False )
                )
                ( 1, [], False )
                (String.toList code)

        allNumbers =
            if lastIsLineWrap then
                numbers

            else
                numbers ++ [ number ]
    in
    String.join "\n" (List.map String.fromInt allNumbers)


{-| `mergedShowLineNumbers` (`Code.tsx:57-61`): `inline` / `wordWrap` force the
gutter off.
-}
mergedShowLineNumbers : Options msg -> Bool
mergedShowLineNumbers opts =
    if opts.inline || opts.wordWrap then
        False

    else
        opts.showLineNumbers


{-| The 15 `--n-*` custom properties the root attaches (`Code.tsx:119-157`),
EXACT emission order. `--n-font-size` is `internalFontSize ++ "px"` when set,
else the theme's `fontSize`. (`--n-line-number-color` appears in the cssr header
comment but is never emitted upstream — not ported.)
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            CodeTheme.vars theme
    in
    [ ( "--n-font-size", fontSizeValue opts v )
    , ( "--n-font-family", theme.common.fontFamilyMono )
    , ( "--n-font-weight-strong", v.fontWeightStrong )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-text-color", v.textColor )
    , ( "--n-mono-3", v.mono3 )
    , ( "--n-hue-1", v.hue1 )
    , ( "--n-hue-2", v.hue2 )
    , ( "--n-hue-3", v.hue3 )
    , ( "--n-hue-4", v.hue4 )
    , ( "--n-hue-5", v.hue5 )
    , ( "--n-hue-5-2", v.hue52 )
    , ( "--n-hue-6", v.hue6 )
    , ( "--n-hue-6-2", v.hue62 )
    , ( "--n-line-number-text-color", v.lineNumberTextColor )
    ]


fontSizeValue : Options msg -> CodeTheme.Vars -> String
fontSizeValue opts v =
    case opts.internalFontSize of
        -- `[oracle D1]` upstream `internalFontSize ? \`${internalFontSize}px\` :
        -- fontSize` is JS truthiness — `0` falls back to the theme size
        -- (reachable via `Log` `fontSize = 0`). Only exact `0` (and the
        -- impossible NaN); negatives are truthy.
        Just 0 ->
            v.fontSize

        Just n ->
            String.fromInt n ++ "px"

        Nothing ->
            v.fontSize
